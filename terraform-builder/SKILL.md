---
name: terraform-builder
description: 'Create Terraform for Azure landing zones, platform services, and workloads aligned to the Microsoft Well-Architected Framework. Use when generating or refactoring Terraform IaC into main.tf for Terraform/provider configuration plus resource-family files (virtual_networks.tf, key_vaults.tf, etc.) instead of a monolithic main.tf.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or backend requirements.'
---

# Azure Terraform Workload & Platform Builder

Create or restructure Terraform for Azure platform and workload tiers, aligned to the Well-Architected Framework (WAF), using a strict file decomposition model. Scope is Terraform IaC only. Don't produce ADRs, pipelines, or deployment guides unless the user asks for them (`adr-generator` covers ADRs).

Load `references/waf-pillars.md` only when a non-trivial design or security trade-off needs pillar reasoning. Everything else needed is in this file.

## Token Economy

These rules apply to every step:

- **One clarification round, at most.** If tier, environments, regions, backend, or root split are genuinely ambiguous, ask every question in one message that also proposes the file tree. Otherwise state the assumptions and proceed. Never ask iteratively.
- **Write, don't echo.** Create files with file tools. Never paste file contents into chat, and don't re-read files you just wrote.
- **Generate only what's needed.** Create `.tfvars` files only for the environments and regions the user named (one if none were named). Don't add speculative resource files, outputs, `config/` files, or variables.
- **Loop, don't repeat.** Use `for_each` over map variables or locals for repeated resources such as subnets, NSG rules, private endpoints, and role assignments. Don't write near-identical blocks. Prefer `for_each` over `count` for stable addresses.
- **Validate once.** Run the validator after all files are written. On failure, fix only the files it names and re-run.
- **Lean final reply.** Give the file tree, assumptions and deviations, and the validator's summary line. Don't restate code or this checklist.

## Platform vs Workload Classification

- **Platform (`terraform/platform/<domain>/`):** centralized foundations, shared connectivity, and landing-zone governance across workloads or subscriptions. Examples: hub VNets, Virtual WAN, Azure Firewall, Bastion, Gateway/ExpressRoute, shared Private DNS zones, central Log Analytics, policy assignments. Example roots: `platform/hub-network/`, `platform/shared-services/`.
- **Workload (`terraform/workloads/<workload>-<domain>/`):** app-, service-, or domain-specific infrastructure. Examples: spoke subnets, UDRs, NSGs, VMs, App Service, Container Apps/AKS, Azure SQL/Cosmos DB/PostgreSQL, storage, Key Vault, workload private endpoints. Example roots: `workloads/lims-data/`, `workloads/ecommerce-web/`.

Infer the tier when you can. Ask only if the request mixes tiers ambiguously.

## Non-Negotiable File Framework

```text
terraform/
	platform/<domain>/
		README.md
		main.tf
		locals.tf
		variables.tf
		outputs.tf
		<resource_family_plural>.tf
		environments/<environment>.tfvars
		config/<purpose>.<environment>.json
	workloads/<workload>-<domain>/
		(same layout as platform roots)
```

- **Folder presence:** every deployable root has `main.tf`, `locals.tf`, `variables.tf`, `outputs.tf`, and `README.md`. Create `config/` only when external JSON or YAML config is needed, and never leave it empty.
- **`.gitignore`:** if the repo root already has one, keep it and make sure it covers the entries below. Otherwise create it with exactly these entries, and don't fetch a template:
  - Terraform working state: `.terraform/`, `*.tfstate`, `*.tfstate.*`, `*.tfplan`
  - Crash logs: `crash.log`, `crash.*.log`
  - Local overrides and CLI config: `override.tf`, `override.tf.json`, `*_override.tf`, `*_override.tf.json`, `.terraformrc`, `terraform.rc`
  - Sensitive variable files: `*.auto.tfvars`, `secrets.tfvars`

  Commit `.terraform.lock.hcl`.
- **Splitting roots:** split when resource groups differ materially in change cadence, approvals, ownership, or deletion blast radius. Keep tightly coupled resources together. Each root is its own state and deployment stack. Pass cross-root dependencies as resource ID variables or remote state data sources, never as one monolithic plan. Note the split rationale in the root `README.md`.

## File Naming Rules

- `main.tf` holds only the `terraform` block (`required_version`, `required_providers`, backend) and provider configuration. The `azurerm` provider always declares `features {}`.
- `locals.tf` holds the `local.names` map, tags, derived IDs, and reused computed values.
- `variables.tf` holds typed inputs, `validation` blocks, and defaults.
- `outputs.tf` holds only values consumed by parent modules, downstream state, or operators.
- Resource family files are plural snake_case, one family per file. If a family grows too large, split it with a suffix (`virtual_machines_linux.tf`). Any family not in the table below gets a new file named after the resource type.
- Name variable files `environments/<environment>.tfvars`, or `environments/<region>-<environment>.tfvars` for multi-region roots.
- Private endpoints live in the parent resource's file, linked to the matching private DNS zone.
- Data sources go in the closest resource family file, or in `data_sources.tf` if they're shared broadly.

| Concern | File |
|---|---|
| Resource groups | `resource_groups.tf` |
| VNets, subnets, peering | `virtual_networks.tf` |
| NSGs | `network_security_groups.tf` |
| Route tables | `route_tables.tf` |
| Private DNS zones and links | `private_dns_zones.tf` |
| VMs and NICs | `virtual_machines.tf` |
| Managed disks | `managed_disks.tf` |
| Storage accounts | `storage_accounts.tf` |
| Key Vault | `key_vaults.tf` |
| Firewalls / Bastion | `firewalls.tf` / `bastion.tf` |
| Log Analytics / App Insights | `observability.tf` |
| Diagnostic settings | `monitor_diagnostic_settings.tf` |
| Role assignments | `role_assignments.tf` |

## Resource Naming

Use the format `<acronym>-<workload>-<environment>-<location-code>-<instance>`, lowercase alphanumerics and hyphens only, with instance numbers starting at `01`. Example: `kv-lz-prod-uks-01`.

- **Acronyms:** `rg`, `vnet`, `snet`, `nsg`, `fw`, `st`, `kv`, `law`, `pip`, `vhub`, `udr`, `nic`, `vm`.
- **Environments:** `prod`, `staging`, `dev`, `test`.
- **Location codes:** `uks`, `ukw`, `euw`, `eun`, `usc`, `use`.
- **Tiers:** add a tier suffix to the workload part where needed, e.g. `nsg-db-…` and `nsg-app-…`.

Build every name in the `local.names` map and reference it as `local.names.<resource_type>`.

**Length guardrails** make `terraform validate` or `plan` fail early, not inspection:

- Add a `lifecycle { precondition { condition = length(local.names.x) <= N, error_message = "…" } }` block on the exact computed name the resource uses.
- The error message must name the failing value and say what to shorten.

Minimum coverage:

- Key Vault: ≤ 24 characters.
- Storage account: ≤ 24 characters, lowercase alphanumerics only.
- DNS zones, App Service, and container registries: ≤ 63 characters.
- Any other resource with a hard naming limit.

## Authoring Rules

- Group attributes with blank lines, in this order:
  1. Identity metadata: `name`, `resource_group_name`, `location`.
  2. Service config: `sku`, tiers, `public_network_access_enabled`, flags.
  3. Nested blocks: `identity`, `network_acls`, `blob_properties`, `private_service_connection`, `os_disk`.
  4. `tags` on its own.
  5. `lifecycle` last, after `tags`.
- Reference resources directly across files within a root. Pass cross-root references as variables, such as resource IDs.
- Define `azurerm_role_assignment` with an explicit `principal_id`, `role_definition_name` or `role_definition_id`, and `scope`.
- Use `azurerm_monitor_diagnostic_setting` at resource scope, with explicit log categories and metrics rather than catch-all blocks.
- Keep roots portable: make environment, location, and SKU variables with validation blocks, unless the user asks to pin one.
- Comment only where intent isn't obvious from the code.

### Security Baseline And Prohibitions

Apply these unless the user explicitly overrides them:

- Storage, Key Vault, AI Services, and ML get `public_network_access_enabled = false`.
- Key Vault uses `rbac_authorization_enabled = true`, with no access policies.
- App and platform subnets get an NSG and a route table, unless explicitly waived.
- Use managed identities over secrets. Secrets never go in plain Terraform variables.
- Send diagnostics for critical services to Log Analytics.
- Size SKUs for the workload. Make pricing-sensitive choices variables.

Never:

- Write a catch-all `main.tf`.
- Mix providers, networking, compute, storage, observability, or security without a file boundary.
- Hide security or reliability settings behind unexplained defaults.
- Put private endpoints in a shared file.
- Hard-code a single environment or region unless the user asks for it.
- Put local deployment commands, manual apply steps, or workstation setup in the README. Delivery is CI/CD-driven.

## Delivery Pattern

1. Infer the tier, root split, and backend. If anything is genuinely ambiguous, ask once and include the proposed tree.
2. Check or create `.gitignore`.
3. Write each root's files in this order: `main.tf`, `locals.tf`, `variables.tf`, one file per resource family, `outputs.tf`, then `environments/*.tfvars`.
4. Write a short `README.md` per root, 40 lines at most. Cover scope, file boundaries, cross-root dependencies, and key decisions. No manual deployment steps.
5. Validate. Fix and re-run until it passes.
6. Reply per the Token Economy rules.

## Validation

Run the validator once from the repo root:

- Windows: `pwsh scripts/validate-terraform.ps1 [root-path]`
- Other platforms: `bash scripts/validate-terraform.sh [root-path]`

Don't run individual `terraform init` or `validate` commands. For every root, the script runs `init -backend=false` with a shared provider cache and then `validate`. It shows init output only on failure, prints one line per diagnostic, and ends with a `PASS` or `FAIL` summary line. Don't deliver until it prints `PASS`.

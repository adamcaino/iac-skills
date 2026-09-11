---
name: terraform-builder
description: 'Create Terraform workloads for Microsoft Azure using the Microsoft Well-Architected Framework. Use when generating or refactoring Terraform, Azure landing zones, platform services, workload infrastructure, or IaC repositories that must use main.tf for Terraform and provider configuration plus resource-specific .tf files such as virtual_networks.tf, virtual_machines.tf, storage_accounts.tf, and key_vaults.tf instead of placing all resources into a monolithic main.tf.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or backend requirements.'
---

# Azure Terraform Workload & Platform Builder

Create or restructure Terraform for Azure workloads and platform services aligned to the Microsoft Well-Architected Framework, using a strict file decomposition model. Supports deployable platform roots (`platform/<domain>`), workload roots (`workloads/<workload>-<domain>`), or several sibling roots.

This file holds the rules needed on every task. Load a reference file only when the task needs it:

- `references/naming-and-validation.md` — naming convention, name-length limits, lifecycle precondition guardrail pattern. Load when generating any resource name or variable.
- `references/waf-pillars.md` — Well-Architected pillar guidance and MSP security baseline. Load when making a design/security trade-off, not for routine file authoring.
- `references/style-and-examples.md` — attribute grouping and full example layouts. Load once per session if you need a formatting reference; the pattern in "Authoring Rules" below is usually enough after the first file.
- `scripts/validate-terraform.sh` — run this, don't reason through `terraform init`/`validate` manually (see Validation below).

## Primary Outcomes

- Terraform organised for maintenance, reviewability, and safe change isolation across Platform and Workload tiers.
- `main.tf` holds only Terraform and provider configuration — never a catch-all.
- Determine or infer whether the target infrastructure belongs under `platform/` or `workloads/`.
- Delegate ADR authoring to the `adr-generator` skill; store results under `ADRs/`.
- Ask all clarifying questions about intent, tier placement, and constraints **up front, in one batch**, before generating any code — not iteratively as you go.
- For a large or ambiguous ask, propose the file tree first and get it confirmed before writing file contents.

## Platform vs Workload Classification

Determine or infer tier alignment before structuring files:

- **Platform (`platform/`):** Centralized foundations, shared connectivity, and landing zone governance managed across workloads or subscriptions.
  - *Resources:* Hub VNets, Virtual WAN, Azure Firewall, Azure Bastion, Gateway/ExpressRoute, shared Private DNS zones, centralized Log Analytics workspaces, enterprise policy assignments.
  - *Placement:* `terraform/platform/<domain>/` (e.g. `terraform/platform/hub-network/`, `terraform/platform/shared-services/`).
- **Workload (`workloads/`):** Application-, service-, or domain-specific infrastructure supporting discrete workloads and consumer apps.
  - *Resources:* Workload/spoke subnets, route tables (UDRs), NSGs, Virtual Machines, App Services, Container Apps/AKS, databases (Azure SQL, Cosmos DB, PostgreSQL), storage accounts, Key Vaults, private endpoints for workload components.
  - *Placement:* `terraform/workloads/<workload>-<domain>/` (e.g. `terraform/workloads/lims-data/`, `terraform/workloads/ecommerce-web/`).

If the request is ambiguous or combines platform and workload boundaries, ask to clarify the desired tier in the initial batch of questions.

## Non-Negotiable File Framework

```text
terraform/
	platform/
		<domain>/
			README.md
			main.tf
			locals.tf
			variables.tf
			outputs.tf
			resource_groups.tf
			virtual_networks.tf
			firewalls.tf
			bastion.tf
			observability.tf
			monitor_diagnostic_settings.tf
			role_assignments.tf
			ADRs/001-<decision>.md
			config/<purpose>.<environment>.json
			environments/<environment>.tfvars
	workloads/
		<workload>-<domain>/
			README.md
			main.tf
			locals.tf
			variables.tf
			outputs.tf
			resource_groups.tf
			virtual_networks.tf
			network_security_groups.tf
			route_tables.tf
			virtual_machines.tf
			storage_accounts.tf
			key_vaults.tf
			observability.tf
			monitor_diagnostic_settings.tf
			role_assignments.tf
			ADRs/001-<decision>.md
			config/<purpose>.<environment>.json
			environments/<environment>.tfvars
```

**Folder presence:** `main.tf`, `locals.tf`, `variables.tf`, `outputs.tf`, `README.md`, `ADRs/` always exist in a deployable root. `environments/` holds `<environment>.tfvars` files. `config/` only when external JSON/YAML config is needed — never an empty folder.

**`.gitignore`:** check repo root first; preserve if present; if absent, source from standard Azure Terraform `.gitignore` (ignore `.terraform/`, `*.tfstate*`, crash logs, and sensitive `.tfvars` like `*.auto.tfvars` or `secrets.tfvars`).

**Sub-workload / platform split:** split roots when resource groups differ materially in change cadence, approval requirements, ownership, or deletion blast radius. Keep tightly coupled resources together. Each root is a separate state/deployment stack — pass cross-root dependencies as resource ID variables or remote state data sources, never monolithic plans. Record the split decision in `ADRs/`.

## File Naming Rules

- `main.tf`: only Terraform settings, required_version, required_providers, backend configuration, provider configuration, and provider features.
- `locals.tf`: shared naming (`local.names` map), tags, derived IDs, and computed values reused across files.
- `variables.tf`: cross-cutting input variables, typed objects, validation blocks, and defaults.
- `outputs.tf`: outputs that are intentionally exposed to parent modules, downstream state, or operators.
- `<resource-family-plural>.tf`, plural snake_case, one resource family per file (e.g. `virtual_networks.tf`). Split further with a suffix if a family grows too large (`virtual_machines_linux.tf`).
- `environments/<environment>.tfvars` or `environments/<region>-<environment>.tfvars` — prefer the region-environment form for multi-region roots.
- `ADRs/<nnn>-<decision>.md`: one material decision per file, via `adr-generator`.
- Private endpoints live in the same file as the resource they connect to — never a shared `private_endpoints.tf`.
- Keep data sources with the closest relevant resource family; if shared broadly, place them in `data_sources.tf`.

### Resource Family Mapping

| Azure concern | Default file |
|---|---|
| Terraform and provider settings | `main.tf` |
| Resource groups | `resource_groups.tf` |
| Virtual networks, subnets, peering | `virtual_networks.tf` |
| Network security groups | `network_security_groups.tf` |
| Route tables and routes | `route_tables.tf` |
| Private DNS zones and links | `private_dns_zones.tf` |
| Private endpoints | colocate with parent resource file |
| Virtual machines and NICs | `virtual_machines.tf` |
| Managed disks | `managed_disks.tf` |
| Storage accounts and containers | `storage_accounts.tf` |
| Key Vault and secret access model | `key_vaults.tf` |
| Log Analytics / App Insights | `observability.tf` |
| Diagnostic settings | `monitor_diagnostic_settings.tf` |
| Role assignments | `role_assignments.tf` |

Unlisted families get a new plural snake_case file matching the resource type.

## Scope And Configuration

- Provider configuration: explicitly declare `features {}` block in `azurerm` provider inside `main.tf`.
- Sub-workload references: reference resources directly across files within the same root; pass cross-root references as variables (such as resource IDs).
- Deterministic RBAC naming: `azurerm_role_assignment` with explicit principal_id, role_definition_name / role_definition_id, and scope.

## Authoring Rules

- Keep naming/tags in `locals.tf`. Prefer explicit names over generated ones.
- Group resource attributes with blank lines by concern (identity → config → nested blocks → tags → lifecycle). See `references/style-and-examples.md` if you need the worked example.
- Enforce name-length limits with `lifecycle { precondition {} }` blocks placed at the end of the resource. Full pattern: `references/naming-and-validation.md`.
- Diagnostics: model targets using `azurerm_monitor_diagnostic_setting`, apply at resource scope, prefer explicit enabled log categories and metrics over catch-all blocks.
- Brief comments only where intent isn't obvious from the code.
- Template portability by default — parameterise environment, location, and SKU variables with validation blocks — unless the user explicitly asks to pin to one.

## Hard Prohibitions

- No catch-all `main.tf`.
- No mixing providers, networking, compute, storage, observability, and security resources without a file boundary.
- No unexplained defaults hiding security or reliability settings.
- No `public_network_access_enabled = true` on Storage, Key Vault, AI Services, or ML by default — explicit user request only.
- No centralising private endpoints into a shared file when they're tightly tied to a specific resource.
- No hard-coding a single environment/region unless explicitly requested.
- No local deployment commands, manual apply steps, or workstation setup instructions in the README — assume CI/CD-driven delivery.

## Delivery Pattern

1. Determine or infer tier alignment (**Platform** under `platform/` vs **Workload** under `workloads/`). Ask all clarifying questions in one batch (intent, tier, constraints, split vs single root, backend requirements).
2. Identify resource families involved; decide root split (e.g. separate platform domains or workload domains); record split rationale for the ADR.
3. Check/create `.gitignore`.
4. Propose the file tree (specifying `platform/<domain>/` or `workloads/<workload>-<domain>/`); get confirmation before writing contents if the ask is large or ambiguous.
5. Create `main.tf` first (Terraform block, providers, backend if specified), then `locals.tf`, then `variables.tf`.
6. Create one `.tf` file per resource family.
7. Place private endpoints beside their parent resource file.
8. Add `outputs.tf` only for values consumed externally or across a root boundary.
9. Write a short `README.md` per root (scope, file boundaries, cross-root dependencies, key decisions — no manual deployment steps).
10. Invoke `adr-generator` for material decisions.
11. Run `scripts/validate-terraform.sh` (see Validation below). Fix and re-run until it exits 0.
12. Run the Review Checklist below.

## Validation

Run `scripts/validate-terraform.sh [root-path]` once, rather than issuing individual `terraform init` / `terraform validate` commands per directory manually. It initializes each root under `platform/` and `workloads/` without a backend and runs `terraform validate`, failing loudly with a nonzero exit code if anything breaks. Do not deliver code until it exits 0. If it fails: fix syntax/variable/type issues and re-run — don't hand-narrate each individual command's output back to the user.

## Review Checklist

Quick pass before finishing — these are pointers back to the rules above, not new rules:

- [ ] Tier alignment determined and correct folder hierarchy used (`platform/` vs `workloads/`).
- [ ] File framework and naming rules followed (no catch-all `main.tf`, one file per resource family, private endpoints colocated).
- [ ] `scripts/validate-terraform.sh` exits 0.
- [ ] Name-length guardrails present for Key Vault, Storage Account, and any other constrained resource (`references/naming-and-validation.md`).
- [ ] WAF baseline applied — private-only data-plane defaults (`public_network_access_enabled = false`), NSG/route-table associations, diagnostics to Log Analytics (`references/waf-pillars.md` if you need the detail).
- [ ] README present per root, no manual deployment steps, ADRs generated via `adr-generator`.
- [ ] `.gitignore` present and state/local artifacts excluded from authoring source.
- [ ] Region/environment parameterisation preserved unless a single-scope template was explicitly requested.
- [ ] Lifecycle precondition blocks placed at the end of resource declarations, after `tags`.

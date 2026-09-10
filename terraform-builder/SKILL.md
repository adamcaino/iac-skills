---
name: terraform-builder
description: 'Create Terraform workloads for Microsoft Azure using the Microsoft Well-Architected Framework. Use when generating or refactoring Terraform, Azure landing zones, platform services, workload infrastructure, or IaC repositories that must use main.tf for Terraform and provider configuration plus resource-specific .tf files such as virtual_networks.tf, virtual_machines.tf, storage_accounts.tf, and key_vaults.tf instead of placing all resources into a monolithic main.tf.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or backend requirements.'
---

# Azure Terraform Workload Builder

Create or restructure Terraform for Azure workloads aligned to the Microsoft Well-Architected Framework, using a strict file decomposition model.

This file holds the rules needed on every task. Load a reference file only when the task needs it:

- `references/naming-and-validation.md` — naming convention, name-length limits, lifecycle precondition guardrail pattern. Load when generating any resource name or variable.
- `references/waf-pillars.md` — Well-Architected pillar guidance. Load when making a design/security trade-off, not for routine file authoring.
- `references/style-and-examples.md` — attribute grouping and full example layouts. Load once per session if you need a formatting reference; the pattern in "Authoring Rules" below is usually enough after the first file.
- `scripts/validate-terraform.sh` — run this, don't reason through `terraform init`/`validate` manually (see Validation below).

## Primary Outcomes

- Terraform organised for maintenance, reviewability, and safe change isolation.
- `main.tf` holds only Terraform/provider configuration — never a catch-all.
- Delegate ADR authoring to the `adr-generator` skill; store results under `ADRs/`.
- Ask all clarifying questions about intent and constraints **up front, in one batch**, before generating any code — not iteratively as you go.
- For a large or ambiguous ask, propose the file tree first and get it confirmed before writing file contents.

## Non-Negotiable File Framework

Do not place all resources in `main.tf`. Use this file layout by default unless the user explicitly requests a different structure:

```text
main.tf
locals.tf
variables.tf
outputs.tf
resource_groups.tf
virtual_networks.tf
network_security_groups.tf
route_tables.tf
virtual_machines.tf
managed_disks.tf
storage_accounts.tf
key_vaults.tf
log_analytics_workspaces.tf
monitor_diagnostic_settings.tf
role_assignments.tf
README.md
ADRs/001-<decision>.md
```

## File Naming Rules

- `main.tf`: only Terraform settings, backend configuration, required provider blocks, provider configuration, and provider features.
- `locals.tf`: shared naming (`local.names` map), tags, derived IDs, and computed values reused across files.
- `variables.tf`: cross-cutting input variables, typed objects, validation blocks, and defaults.
- `outputs.tf`: outputs that are intentionally exposed to parent modules or operators.
- `<resource-family-plural>.tf`, plural snake_case, one resource family per file (e.g. `virtual_networks.tf`). Split further with a suffix if a family grows too large (`virtual_machines-linux.tf`).
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

## Authoring Rules

- Keep naming/tags in `locals.tf`. Prefer explicit names over generated ones.
- Group resource attributes with blank lines by concern (identity → config → nested blocks → tags → lifecycle). See `references/style-and-examples.md` if you need the worked example.
- Enforce name-length limits with `lifecycle { precondition {} }` blocks placed at the end of the resource. Full pattern: `references/naming-and-validation.md`.
- Keep modules focused; if a module is introduced, apply the same file framework inside it.
- Add brief comments only where intent isn't obvious from the code.
- If the user asks for a single-file example, explain that the preferred convention is still split by resource family and only collapse files if explicitly required.

## Hard Prohibitions

- No catch-all `main.tf`.
- No mixing providers, networking, compute, storage, and monitoring resources without a file boundary.
- No unexplained defaults hiding security or reliability settings.
- No centralizing private endpoints into a shared file when they're tightly tied to a specific resource.
- No local deployment commands, manual apply steps, or workstation setup instructions in the README — assume CI/CD-driven delivery.

## Delivery Pattern

1. Ask all clarifying questions in one batch (intent, constraints, backend requirements).
2. Identify resource families involved.
3. Propose the file tree; get confirmation before writing contents if the ask is large or ambiguous.
4. Create `main.tf` first (Terraform block, providers, backend if specified), then `locals.tf`, then `variables.tf`.
5. Create one `.tf` file per resource family.
6. Place private endpoints beside their parent resource file.
7. Add `outputs.tf` only for values consumed externally.
8. Write a short `README.md` (file structure, resource boundaries, key decisions — no manual deployment steps).
9. Invoke `adr-generator` for material decisions.
10. Run `scripts/validate-terraform.sh` (see Validation below). Fix and re-run until it exits 0.
11. Run the Review Checklist below.

## Validation

Run `scripts/validate-terraform.sh [directory]` once, rather than issuing `terraform init` / `terraform validate` manually. It initializes without a backend and validates the configuration, failing loudly with a nonzero exit code if anything breaks. Do not deliver code until it exits 0. If it fails: fix syntax/variable/type issues and re-run — don't hand-narrate each individual command's output back to the user.

## Review Checklist

Quick pass before finishing — these are pointers back to the rules above, not new rules:

- [ ] File framework and naming rules followed (no catch-all `main.tf`, one file per resource family, private endpoints colocated).
- [ ] `scripts/validate-terraform.sh` exits 0.
- [ ] Name-length guardrails present for Key Vault, Storage Account, and any other constrained resource (`references/naming-and-validation.md`).
- [ ] WAF pillars applied — security defaults, diagnostics to Log Analytics, cost-aware SKU choices (`references/waf-pillars.md` if you need the detail).
- [ ] README present, no manual deployment steps, ADRs generated via `adr-generator`.
- [ ] Lifecycle blocks placed at the end of resource declarations, after `tags`.

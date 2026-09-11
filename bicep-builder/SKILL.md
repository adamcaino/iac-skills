---
name: bicep-builder
description: 'Create Bicep workloads for Microsoft Azure using the Microsoft Well-Architected Framework. Use when generating or refactoring Bicep, Azure landing zones, platform services, workload infrastructure, or IaC repositories that must use main.bicep for composition plus shared parent resource-family modules such as virtual-networks.bicep, virtual-machines.bicep, storage-accounts.bicep, and key-vaults.bicep instead of placing all resources into a monolithic template.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or deployment requirements.'
---

# Azure Bicep Workload & Platform Builder

Create or restructure Bicep for Azure workloads and platform services aligned to the Microsoft Well-Architected Framework, using a strict file decomposition model. Supports deployable platform roots (`platform/<domain>`), workload roots (`workloads/<workload>-<domain>`), or sibling roots sharing resource-family modules in `modules/`.

This file holds the rules needed on every task. Load a reference file only when the task needs it:

- `references/naming-and-validation.md` — naming convention, name-length limits, guardrail pattern. Load when generating any resource name or parameter.
- `references/waf-pillars.md` — Well-Architected pillar guidance and MSP security baseline. Load when making a design/security trade-off, not for routine module authoring.
- `references/style-and-examples.md` — attribute grouping and full example layouts. Load once per session if you need a formatting reference; the pattern in "Authoring Rules" below is usually enough after the first file.
- `scripts/validate-bicep.sh` — run this, don't reason through build commands manually (see Validation below).

## Primary Outcomes

- Bicep organised for maintenance, reviewability, and safe change isolation across Platform and Workload tiers.
- `main.bicep` is orchestration only — never a catch-all.
- Determine or infer whether the target infrastructure belongs under `platform/` or `workloads/`.
- Delegate ADR authoring to the `adr-generator` skill; store results under `ADRs/`.
- Ask all clarifying questions about intent, tier placement, and constraints **up front, in one batch**, before generating any code — not iteratively as you go.
- For a large or ambiguous ask, propose the file/module tree first and get it confirmed before writing file contents.

## Platform vs Workload Classification

Determine or infer tier alignment before structuring files:

- **Platform (`platform/`):** Centralized foundations, shared connectivity, and landing zone governance managed across workloads or subscriptions.
  - *Resources:* Hub VNets, Virtual WAN, Azure Firewall, Azure Bastion, Gateway/ExpressRoute, shared Private DNS zones, centralized Log Analytics workspaces, enterprise policy assignments.
  - *Placement:* `bicep/platform/<domain>/` (e.g. `bicep/platform/hub-network/`, `bicep/platform/shared-services/`).
- **Workload (`workloads/`):** Application-, service-, or domain-specific infrastructure supporting discrete workloads and consumer apps.
  - *Resources:* Workload/spoke subnets, route tables (UDRs), NSGs, Virtual Machines, App Services, Container Apps/AKS, databases (Azure SQL, Cosmos DB, PostgreSQL), storage accounts, Key Vaults, private endpoints for workload components.
  - *Placement:* `bicep/workloads/<workload>-<domain>/` (e.g. `bicep/workloads/lims-data/`, `bicep/workloads/ecommerce-web/`).

If the request is ambiguous or combines platform and workload boundaries, ask to clarify the desired tier in the initial batch of questions.

## Non-Negotiable File Framework

```text
bicep/
	modules/
		virtual-networks.bicep
		virtual-machines.bicep
		storage-accounts.bicep
		key-vaults.bicep
	platform/
		<domain>/
			README.md
			main.bicep
			ADRs/001-<decision>.md
			builds/env.<environment>.json
			config/<purpose>.<environment>.json
			params/env.<environment>.bicepparam
	workloads/
		<workload>-<domain>/
			README.md
			main.bicep
			ADRs/001-<decision>.md
			builds/env.<environment>.json
			config/<purpose>.<environment>.json
			params/env.<environment>.bicepparam
```

**Folder presence:** `main.bicep`, `params/`, `README.md`, `ADRs/` always exist in a deployable root. `config/` only when external JSON config is needed — never an empty folder. `builds/` holds generated ARM parameter artifacts only; never hand-edit them. Shared parent modules reside in `bicep/modules/` (or `bicep/workloads/modules/` / `bicep/platform/modules/` if scoped).

**`.gitignore`:** check repo root first; preserve if present; if absent, source from `https://raw.githubusercontent.com/Azure/bicep/main/.gitignore` and ensure `builds/` output isn't treated as authoring source.

**Sub-workload / platform split:** split roots when resource groups differ materially in change cadence, approval requirements, ownership, or deletion blast radius. Keep tightly coupled resources together. Each root is a separate deployment stack — pass cross-root dependencies as resource ID parameters, never as module outputs. Record the split decision in `ADRs/`.

## File Naming Rules

- `main.bicep`: parameters, shared variables, module declarations, outputs only.
- `bicep/modules/<resource-family-plural>.bicep` (or within subfolder modules), kebab-case, one resource family per file (e.g. `virtual-networks.bicep`). Split further with a suffix if a family grows too large (`virtual-machines-linux.bicep`).
- `params/<environment>.bicepparam` or `params/<region>-<environment>.bicepparam` — prefer the region-environment form for multi-region roots.
- `builds/env.<environment>.json`: generated, not authored.
- `ADRs/<nnn>-<decision>.md`: one material decision per file, via `adr-generator`.
- Private endpoints live in the same module as the resource they connect to — never a shared `private-endpoints.bicep`.
- Data-plane role assignments sit with the closest resource module, or `modules/role-assignments.bicep` if shared broadly.

### Resource Family Mapping

| Azure concern | Default module |
|---|---|
| Resource groups | `modules/resource-groups.bicep` |
| Virtual networks, subnets, peering | `modules/virtual-networks.bicep` |
| Network security groups | `modules/network-security-groups.bicep` |
| Route tables and routes | `modules/route-tables.bicep` |
| Private DNS zones and links | `modules/private-dns-zones.bicep` |
| Private endpoints | colocate with parent module |
| Virtual machines and NICs | `modules/virtual-machines.bicep` |
| Storage accounts and containers | `modules/storage-accounts.bicep` |
| Key Vault and secret access model | `modules/key-vaults.bicep` |
| Log Analytics / App Insights | `modules/observability.bicep` |
| Diagnostic settings | `modules/diagnostic-settings.bicep` |
| Role assignments | `modules/role-assignments.bicep` |

Unlisted families get a new kebab-case module matching the resource type.

## Scope And Orchestration

- Subscription-level landing zones: `targetScope = 'subscription'` in `main.bicep`.
- `scope: resourceGroup(...)` must use compile-time resolvable values — never module outputs.
- Prefer implicit dependencies via input/output references; add explicit `dependsOn` only when there's no data reference path.

## Authoring Rules

- Keep naming/tags in shared variables. Prefer explicit names over generated ones.
- Group resource properties with blank lines by concern (identity → config → nested objects → tags). See `references/style-and-examples.md` if you need the worked example.
- Enforce name-length limits with parameter decorators by default (`@minLength`/`@maxLength`); use `assert` only when assertions are enabled in the target environment. Full pattern: `references/naming-and-validation.md`.
- Deterministic RBAC naming: `guid(scopeResourceId, principalId, roleSeed)`. Set `principalType` explicitly when known.
- Diagnostics: model targets as `existing`, apply at resource scope, prefer stable API versions, prefer explicit categories over category groups.
- Brief comments only where intent isn't obvious from the code.
- Template portability by default — `@allowed` lists for multi-environment/region — unless the user explicitly asks to pin to one.

## Hard Prohibitions

- No catch-all `main.bicep`.
- No mixing networking/compute/storage/observability/security in one module.
- No unexplained defaults hiding security or reliability settings.
- No `publicNetworkAccess: 'Enabled'` on Storage, Key Vault, AI Services, or ML by default — explicit user request only.
- No centralising private endpoints into a shared module when they're tightly tied to a specific resource.
- No hard-coding a single environment/region unless explicitly requested.

## Delivery Pattern

1. Determine or infer tier alignment (**Platform** under `platform/` vs **Workload** under `workloads/`). Ask all clarifying questions in one batch (intent, tier, constraints, split vs single root).
2. Identify resource families; decide root split; record split rationale for the ADR.
3. Check/create `.gitignore`.
4. Propose the file tree (indicating `platform/` or `workloads/` path); get confirmation before writing contents if the ask is large or ambiguous.
5. Write `main.bicep` per root, shared modules, `params/`, `config/` as needed.
6. Place private endpoints beside their parent resource.
7. Add outputs only for values consumed externally or across a root boundary.
8. Write a short `README.md` per root (scope, module boundaries, cross-root dependencies, key decisions — no manual deployment steps).
9. Invoke `adr-generator` for material decisions.
10. Run `scripts/validate-bicep.sh` (see Validation below). Fix and re-run until it exits 0.
11. Run the Review Checklist below.

## Validation

Run `scripts/validate-bicep.sh [root-path]` once, rather than issuing individual `bicep build` / `az bicep build-params` commands per file. It builds every shared module, every root's `main.bicep` under `platform/` and `workloads/`, and every `.bicepparam` file into its matching `builds/` artifact, and fails loudly with a nonzero exit code if anything breaks. Do not deliver code until it exits 0. If it fails: fix syntax/parameter/type issues and re-run — don't hand-narrate each individual build command's output back to the user.

## Review Checklist

Quick pass before finishing — these are pointers back to the rules above, not new rules:

- [ ] Tier alignment determined and correct folder hierarchy used (`platform/` vs `workloads/`).
- [ ] File framework and naming rules followed (no catch-all `main.bicep`, modules per resource family, private endpoints colocated).
- [ ] `scripts/validate-bicep.sh` exits 0.
- [ ] Name-length guardrails present for Key Vault, Storage, and any other constrained resource (`references/naming-and-validation.md`).
- [ ] WAF baseline applied — private-only data-plane defaults, NSG/route-table associations, diagnostics to Log Analytics (`references/waf-pillars.md` if you need the detail).
- [ ] README present per root, no manual deployment steps, ADRs generated via `adr-generator`.
- [ ] `.gitignore` present and generated artifacts excluded from authoring source.
- [ ] Region/environment parameterisation preserved unless a single-scope template was explicitly requested.

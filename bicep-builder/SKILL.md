---
name: bicep-builder
description: 'Create Bicep workloads for Microsoft Azure using the Microsoft Well-Architected Framework. Use when generating or refactoring Bicep, Azure landing zones, platform services, workload infrastructure, or IaC repositories that must use main.bicep for composition plus resource-family modules such as virtual-networks.bicep, virtual-machines.bicep, storage-accounts.bicep, and key-vaults.bicep instead of placing all resources into a monolithic template.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or deployment requirements.'
---

# Azure Bicep Workload Builder

Use this skill when creating or restructuring Bicep for Azure workloads that should align to the Microsoft Well-Architected Framework and follow a strict file decomposition model. The model supports both a single deployable workload root and multiple independently deployable sub-workload roots, such as `workloads/lims-data` and `workloads/lims-avd`.

## Primary Outcomes

- Generate Bicep that is organized for maintenance, reviewability, and safe change isolation.
- Apply Microsoft Well-Architected Framework guidance across security, reliability, cost optimization, operational excellence, and performance efficiency.
- Reserve `main.bicep` for orchestration and module wiring rather than collapsing all resources into it.
- Generate a short `README.md` that explains file structure, module boundaries, and architectural intent without including local deployment steps.
- Delegate ADR authoring to the `adr-generator` skill so Bicep authoring and architecture documentation remain decoupled; store the resulting ADRs under `ADRs/` in the affected workload root.
- Question the user about workload intent, critical requirements, and constraints before generating code to ensure the design is fit for purpose.

## Non-Negotiable File Framework

Do not place all resources in `main.bicep`.

Use this file layout by default unless the user explicitly requests a different structure. A repository may contain one workload root or several independently deployable sibling roots under `bicep/workloads/`, named for lifecycle or domain purpose, such as `bicep/workloads/lims-data/` and `bicep/workloads/lims-avd/`. Keep each deployable root self-contained. For environment-driven workloads, keep configuration JSON under `config/`, environment parameter files under `params/`, generated `env.*.json` ARM parameter build files under `builds/`, and material architecture decisions under `ADRs/`:

```text
bicep/
	workloads/
		<workload>-<domain>/
			README.md
			main.bicep
			ADRs/
				001-<decision>.md
			builds/
				env.<environment>.json
			config/
				network.<environment>.json
				tags.<environment>.json
			modules/
				<resource-family>.bicep
			params/
				env.<environment>.bicepparam
				or <region>-<environment>.bicepparam
		<workload>-<sub-workload>/
			README.md
			main.bicep
			ADRs/
			builds/
			config/          # omit when no JSON configuration is needed
			modules/
			params/
platform/
		main.bicep
		...
```

### Folder Presence Rules

- `main.bicep`, `modules/`, `params/`, `README.md`, and `ADRs/` are the default workload-root structure.
- Create `config/` only when the workload needs external JSON configuration such as network profiles, tag maps, or service settings. Do not create an empty folder.
- Create `builds/` for environment-driven parameter files and place generated ARM parameter artifacts there. Treat files under `builds/` as generated validation/deployment artifacts; never hand-edit them as the source of truth.
- Store material architecture decisions under `ADRs/` using sequential, descriptive filenames. Use the `adr-generator` skill and create an ADR for split deployment roots, notable AVM gaps, deliberate security exceptions, or other decisions future engineers need to understand.
- Keep `README.md` in every deployable root. It must describe the root's scope, module boundaries, folder layout, cross-root dependencies, and major architectural decisions. Do not include workstation or manual deployment instructions.
- If a root is split into sub-workloads, each sub-workload must have its own `main.bicep`, `params/`, `builds/`, and lifecycle-specific `modules/`. Do not leave resources or parameter contracts in an obsolete parent root.

### Sub-Workload Boundaries

- Split into independently deployable roots when resource groups have materially different change cadence, approval requirements, ownership, or deletion blast radius.
- Keep tightly coupled resources together when one resource directly configures or protects another and splitting would create unnecessary cross-stack coordination. For example, keep a SQL VM and its backup vault together, while placing AVD control-plane resources and AVD-specific FSLogix storage in an AVD root when that matches operational ownership.
- Treat each root as a separate deployment stack. Pass cross-root dependencies as resource ID parameters or existing-resource references; do not rely on outputs from a separately deployed root to construct compile-time module scopes.
- Name roots by lifecycle or domain purpose, such as `lims-data` and `lims-avd`, rather than by arbitrary file order.

### File Naming Rules

- `main.bicep`: only parameters, shared variables, module declarations, and outputs used to compose the solution.
- `main.bicepparam`: environment values and deployment-time parameter bindings when a single parameter file is sufficient.
- `modules/<resource-family-plural>.bicep`: declare resources for a single Azure resource family.
- `params/<environment>.bicepparam` or `params/<region>-<environment>.bicepparam`: environment-specific bindings for a deployable root. Prefer the region-environment form when the same root supports multiple regions.
- `builds/env.<environment>.json`: generated ARM parameter output from the corresponding `.bicepparam`; regenerate it after parameter changes and do not use it as the authoring source.
- `config/<purpose>.<environment>.json`: external JSON configuration loaded by `.bicepparam` or Bicep. Keep secrets out of these files.
- `ADRs/<nnn>-<decision>.md`: one material architecture decision per file, generated through the ADR workflow.
- Use kebab-case module names for resource families, such as `virtual-networks.bicep`, `virtual-machines.bicep`, `storage-accounts.bicep`, and `key-vaults.bicep`.
- Declare private endpoints in the same module as the resource they connect to. For example, a storage private endpoint belongs in `modules/storage-accounts.bicep`, and a Key Vault private endpoint belongs in `modules/key-vaults.bicep`.
- If a resource family becomes too large, split within the same family using a clear suffix, such as `virtual-machines-linux.bicep` and `virtual-machines-windows.bicep`.
- Keep data-plane role assignments with the closest resource family module where practical. If shared broadly, place them in `modules/role-assignments.bicep`.
- If `modules/naming.bicep` is created, it must be consumed by `main.bicep`. Do not scaffold unused modules.

### Scope And Orchestration Rules

- For subscription-level landing zones, use `targetScope = 'subscription'` in `main.bicep`.
- Use compile-time resolvable values (parameters or variables) for `scope: resourceGroup(...)` module declarations.
- Do not use module outputs to construct module `scope` values.
- Prefer implicit dependencies through module input/output references.
- Add explicit `dependsOn` only when sequencing is required and there is no data reference path.

## Readability And Attribute Grouping

Generated Bicep should be formatted for human review, not just parser correctness.

### Attribute Grouping Rules

- Group related properties together and separate groups with a single blank line.
- Place core identity metadata first, such as `name`, `location`, and `scope`.
- After metadata, insert a blank line before service-specific configuration such as SKU, feature flags, access model, and retention settings.
- Insert a blank line before nested object or array sections such as `identity`, `networkAcls`, `properties`, `privateEndpointConnections`, or child resources when they represent a different concern.
- Keep `tags` near the end of each resource body as its own group.
- Place compile-time guardrails using parameter decorators (`@minLength`, `@maxLength`, `@allowed`) by default.
- Use `assert` only when the environment has assertions explicitly enabled in Bicep configuration.
- Do not scatter single blank lines randomly; use them only to separate meaningful groups.

### Example Layout

```bicep
param location string
param tags object
@minLength(3)
@maxLength(24)
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
	name: keyVaultName
	location: location

	properties: {
		tenantId: tenant().tenantId
		sku: {
			family: 'A'
			name: 'standard'
		}
		enableRbacAuthorization: true
		publicNetworkAccess: 'Disabled'
	}

	tags: tags
}
```

### Hard Prohibitions

- Do not create `main.bicep` as a catch-all resource file.
- Do not mix networking, compute, storage, observability, and security resources together without module boundaries.
- Do not hide critical security or reliability settings behind unexplained defaults.
- Do not rely on implicit truncation or guesswork for Azure naming constraints; enforce limits using parameter decorators and, when enabled, assertions.
- Do not centralize all private endpoints in a shared `private-endpoints.bicep` module when endpoints are tightly tied to specific resources.
- Do not set `publicNetworkAccess: 'Enabled'` for data-plane services such as Storage, Key Vault, Azure AI Services, or Azure ML unless the user explicitly requests temporary public exposure.
- Do not treat a landing zone as complete when required private endpoints and private DNS zone links are missing for private-only data-plane services.
- Do not hard-code a single environment or region in generated templates unless the user explicitly requests a single-environment or single-region artifact.

## Name-Length Pre-Validation Requirements

Generated names can exceed Azure limits when workload, environment, or region suffixes are concatenated. Enforce checks that fail before deployment.

### Mandatory Pattern

- Add explicit validation for any resource with strict naming limits when the final name is computed.
- Prefer parameter decorators (`@minLength`, `@maxLength`, `@allowed`) as the default validation mechanism.
- Use `assert` for computed-name validation only when assertions are enabled in the target environment.
- Use explicit checks such as `length(<computedName>) <= 24`.
- Provide actionable error text that states the failing value and what to shorten.
- Keep name composition in shared variables and validate the exact value used by the resource.

### Minimum Resources To Validate

- Key Vault name length (`<= 24`).
- Storage account name length (`<= 24`) plus lowercase alphanumeric constraints.
- Any additional Azure resource in the generated solution with hard naming limits, for example AI services, machine learning resources, container registries, and DNS resources.

### Example Guardrail Snippet

```bicep
param workloadName string
@maxLength(10)
param environment string
param locationShort string

var keyVaultName = 'kv-${workloadName}-${environment}-${locationShort}'

// Constrain name components by decorators. If assertions are enabled, optionally add:
// assert keyVaultNameLength (length(keyVaultName) <= 24) : 'Key Vault name "${keyVaultName}" exceeds 24 characters. Shorten workloadName, environment, or locationShort.'
```

Use the same pattern for storage account and any other constrained resource names.

## Microsoft Well-Architected Framework Requirements

Every generated Bicep workload should be reasoned against these pillars.

### Reliability

- Prefer zonal or zone-redundant designs when the workload requires higher availability.
- Model dependencies explicitly so deployment order is deterministic.
- Include diagnostic settings and operational visibility for critical services.
- Use stable naming and tagging conventions that support recovery and operations.

### Security

- Prefer managed identities over secrets where Azure services support them.
- Use private networking, network security groups, and least-privilege role assignments where appropriate.
- Store secrets in Azure Key Vault instead of plain-text parameter values when runtime secrets are involved.
- Enable encryption, secure transfer, and service hardening settings by default unless the user directs otherwise.

### Security Baseline For MSP Offerings

- Default to private-only data-plane access for Storage, Key Vault, and Azure AI Services.
- Set `publicNetworkAccess: 'Disabled'` by default for those services and require an explicit user override to enable public access.
- Place private endpoints in the same resource-family module as the parent service and link to the corresponding private DNS zones.
- Include subnet-level NSG association and route table association for app and platform subnets unless the user explicitly opts out.
- For Key Vault, preserve `enableRbacAuthorization: true` and avoid access policy sprawl in generated examples.

### Cost Optimization

- Avoid oversized SKUs and unnecessary always-on components.
- Make pricing-sensitive choices explicit in parameters so environments can scale appropriately.
- Tag resources for cost allocation and ownership.

### Operational Excellence

- Keep the Bicep layout readable so operators can review changes by resource family.
- Separate responsibilities into modules that produce focused pull requests and reviewable diffs.
- Use parameters and variables to centralize naming, tags, location, and environment patterns.
- Prefer explicit outputs only when they support automation or downstream composition.

### Performance Efficiency

- Select service tiers and instance shapes that match workload intent.
- Use architecture patterns that avoid unnecessary cross-region or cross-network latency.
- Keep the design ready for horizontal growth when the workload profile suggests it.

## Delivery Pattern

When asked to build Bicep, follow this sequence.

1. Identify the Azure services involved and group them into resource families.
2. Decide whether the solution is one deployable root or multiple sub-workload roots based on ownership, change cadence, approval gates, and deletion blast radius. Record a split decision in `ADRs/`.
3. Create each root's `main.bicep` with target scope, shared parameters, module orchestration, and outputs.
4. Create `params/` parameter files for every supported environment and region. Use `config/` for non-secret JSON inputs when needed.
5. Create one module file per resource family under each root's `modules/` folder.
6. Place private endpoints with the resource family they expose rather than in a centralized module.
7. Add outputs only for values that need to be consumed externally or passed across a root boundary. Prefer resource ID parameters for separately deployed roots.
8. Create a short `README.md` in every root that explains scope, file structure, module boundaries, cross-root dependencies, and major design choices.
9. Invoke the `adr-generator` skill to produce ADRs for material design decisions and store them under the affected root's `ADRs/` folder.
10. Generate `builds/env.<environment>.json` from every `.bicepparam` file using `az bicep build-params`; do not hand-author generated build artifacts.
11. Exclude local deployment instructions and assume deployment is handled by CI/CD pipelines.
12. Review the generated design against the Well-Architected pillars before finishing.

## Bicep Compilation and Validation Requirements

Before delivering the Bicep code to the user, execute the following validation steps to ensure the generated configuration is correct and ready for deployment:

1. **Compile each Bicep file in every deployable root:**
	```bash
	bicep build <filename>.bicep
	```
	or use Azure CLI:
	```bash
	az bicep build --file <filename>.bicep
	```
	This compiles the Bicep template to ARM JSON and validates syntax and resource declarations.

2. **Build every parameter file into its matching `builds/` artifact:**
	```bash
	az bicep build-params --file params/<region>-<environment>.bicepparam --outfile builds/env.<environment>.json
	```
	This validates environment bindings and keeps generated parameter artifacts synchronized with their source files.

3. **Compile each `main.bicep` last within its root to verify module orchestration:**
	```bash
	bicep build main.bicep
	```
	This ensures all module references, outputs, and compositions are valid.

4. **All module builds, parameter builds, and root `main.bicep` builds must complete successfully** with exit code 0 before declaring the task complete. Warnings must be reviewed and either resolved or documented as accepted residual risk.

### Compilation Failures

If compilation fails:
- Identify and fix syntax errors, missing parameters, or invalid module references
- Ensure all required parameters are present and correctly typed
- Verify that module outputs used in composition exist and have correct types
- Check that `targetScope` matches module scope expectations
- Re-run compilation until all errors are resolved
- Do not deliver code that fails compilation

### Why This Matters

- Bicep compilation catches typos, missing properties, and invalid resource declarations early
- Compilation ensures all modules and references are resolvable
- Early validation prevents Azure deployment failures and reduces deployment time
- This step is non-negotiable and must complete successfully for every Bicep delivery

## Resource Naming Convention

Use the following standardized naming format for all Azure resources:

```
<resource-acronym>-<workload>-<environment>-<location-code>-<instance>
```

### Format Components

| Component | Description | Examples |
|-----------|-------------|----------|
| **resource-acronym** | Two-letter code for the Azure resource type | `rg` (resource group), `vnet` (virtual network), `nsg` (network security group), `fw` (firewall), `st` (storage account), `kv` (key vault), `law` (log analytics workspace), `pip` (public IP), `vhub` (virtual hub), `udr` (user-defined route), `nic` (network interface), `vm` (virtual machine) |
| **workload** | Short workload identifier or resource type/purpose | `lz` (landing zone), `db` (database), `app` (application), `shared` (shared services) |
| **environment** | Environment name | `prod`, `staging`, `dev`, `test` |
| **location-code** | Short Azure region code (3 letters) | `uks` (uksouth), `ukw` (ukwest), `euw` (westeurope), `eun` (northeurope), `usc` (centralus), `use` (eastus) |
| **instance** | Instance number (default: 01, increment for multiple instances) | `01`, `02`, `03` |

### Examples

```
rg-lz-prod-uks-01        # Resource group for landing zone, prod, UK South
vnet-lz-prod-uks-01      # Virtual network
nsg-app-prod-uks-01      # Network security group for application subnet
fw-lz-prod-uks-01        # Azure Firewall
st-lz-prod-uks-01        # Storage account
kv-lz-prod-uks-01        # Key Vault
law-lz-prod-uks-01       # Log Analytics Workspace
pip-fw-prod-uks-01       # Public IP for firewall
vhub-lz-prod-uks-01      # Virtual Hub
udr-spoke-prod-uks-01    # User-defined route table
nic-db-prod-uks-01       # Network interface
vm-app-prod-uks-01       # Virtual machine
```

### Naming Rules

- Use lowercase alphanumeric characters and hyphens only.
- Instance numbers start at `01` and increment for additional instances of the same resource type.
- For resources that span multiple tiers or purposes within a workload, extend the workload component with a suffix:
  - `nsg-db-prod-uks-01` (database tier NSG)
  - `nsg-app-prod-uks-01` (application tier NSG)
  - `snet-db-prod-uks-01` (database subnet)
  - `snet-app-prod-uks-01` (application subnet)
- Centralize naming logic in shared variables or a dedicated naming module (e.g., `modules/naming.bicep`).
- All resource names are stored as computed variables and referenced throughout the Bicep files.

### Name-Length Validation

Enforce Azure resource name-length constraints using parameter decorators and, when enabled, assertions:
- **Key Vault:** 24 characters max
- **Storage Account:** 24 characters max
- **DNS zones, App Service names, container registries:** 63 characters max

Example validation in a parameter:

```bicep
param workloadName string
@maxLength(10)
param environment string
param locationShort string

var keyVaultName = 'kv-${workloadName}-${environment}-${locationShort}'

// Use decorators for compile-time validation
// Optionally add assertions when enabled:
// assert kvNameLength (length(keyVaultName) <= 24) : 'Key Vault name "${keyVaultName}" exceeds 24 characters. Reduce workload, environment, or location code length.'
```


Use these default mappings when choosing module names.
## Resource Family Mapping

Use these default mappings when choosing module names.

| Azure concern | Default module |
|---|---|
| Resource groups | `modules/resource-groups.bicep` |
| Virtual networks, subnets, peering | `modules/virtual-networks.bicep` |
| Network security groups | `modules/network-security-groups.bicep` |
| Route tables and routes | `modules/route-tables.bicep` |
| Private DNS zones and links | `modules/private-dns-zones.bicep` |
| Private endpoints | colocate with the parent resource module, such as `modules/storage-accounts.bicep`, `modules/key-vaults.bicep`, or `modules/ai-foundry.bicep` |
| Virtual machines and NICs | `modules/virtual-machines.bicep` |
| Managed disks | `modules/managed-disks.bicep` |
| Storage accounts and containers | `modules/storage-accounts.bicep` |
| Key Vault and secret access model | `modules/key-vaults.bicep` |
| Log Analytics and Application Insights | `modules/observability.bicep` |
| Diagnostic settings | `modules/diagnostic-settings.bicep` |
| Role assignments | `modules/role-assignments.bicep` |

If a requested resource family is not listed, create a new kebab-case module that matches the resource type, such as `modules/application-gateways.bicep` or `modules/container-registries.bicep`.

When private endpoints are used, include the DNS zone family module by default and wire zone groups from each private endpoint to the right zone.

## Authoring Rules

- Keep naming and tags consistent through shared variables.
- Prefer explicit resource names over opaque generated names.
- Keep modules focused; if nested modules are introduced, apply the same file framework inside them.
- Preserve separation between platform primitives, security controls, observability, and workload resources.
- Keep private endpoints adjacent to the parent resource declarations so reviews show exposed services and network boundaries together.
- Add compile-time checks to constrained resources so naming violations fail before deployment.
- Use deterministic RBAC assignment naming, such as `guid(scopeResourceId, principalId, roleSeed)`, to keep role assignments idempotent.
- Set `principalType` explicitly in role assignments when known.
- In diagnostics modules, model target resources as `existing` and apply `Microsoft.Insights/diagnosticSettings` at resource scope.
- Prefer stable `Microsoft.Insights/diagnosticSettings` API versions; use preview only when required by the target resource and document why.
- Prefer explicit diagnostic categories per service when known; use broad category groups only when category discovery is unavailable.
- Add blank lines between logical groups so metadata, service configuration, nested objects, tags, and guardrails are visually distinct.
- Create a short `README.md` for generated solutions that explains the repository layout, purpose of each module, and the main architectural decisions.
- Do not embed ADR authoring logic in this skill; use the `adr-generator` skill for ADR creation and structure.
- Do not include local deployment commands, manual deployment steps, or workstation setup instructions in the README; assume delivery occurs through CI/CD pipelines.
- Add brief comments only when the intent is not obvious from the code.
- If the user asks for a single-file example, explain that the preferred repository convention is still split by resource family and only collapse files if explicitly required.
- Keep template portability by default: allow multiple environments and regions using parameter `@allowed` lists unless the user explicitly asks to pin to one.

## Example Response Shape

When producing Bicep, explain the resulting file layout before presenting code.

```text
bicep/workloads/<workload>/
	- main.bicep: parameters, variables, module orchestration, outputs
	- README.md: scope, boundaries, and architectural intent
	- ADRs/: material architecture decisions
	- builds/: generated ARM parameter artifacts
	- config/: optional environment JSON configuration
	- params/: environment or region-environment parameter files
	- modules/: resource-family modules

bicep/workloads/<sub-workload>/
	- independent main.bicep and lifecycle-specific modules
	- separate params/, builds/, config/, ADRs/, and README.md
```

## Review Checklist

Before finishing, verify all of the following:

- No catch-all `main.bicep` file was used.
- Each independently deployed root is self-contained and has its own lifecycle-specific `main.bicep`, `params/`, `builds/`, `modules/`, `README.md`, and `ADRs/` structure.
- `main.bicep` contains composition concerns only.
- Each resource family is isolated into an appropriately named module.
- Private endpoints are declared beside their parent resources rather than in a centralized private-endpoints module.
- Name-length limits are enforced for Key Vault, Storage Account, and other constrained resources using decorators by default and assertions only when enabled.
- Module scopes use compile-time resolvable values and do not rely on module outputs.
- No unnecessary explicit `dependsOn` entries are present where implicit dependencies already exist.
- Resource properties are grouped with intentional blank lines so metadata, configuration, nested properties, tags, and guardrails are easy to review.
- A short `README.md` exists and explains file structure and major architectural choices.
- ADRs are generated via the `adr-generator` skill and stored under `ADRs/`.
- `config/` exists only when external JSON configuration is required; secrets are not stored there.
- Every source `.bicepparam` file has a matching generated artifact under `builds/`, and generated artifacts were rebuilt after parameter changes.
- README files, ADRs, parameter files, and generated build artifacts agree on which root owns each resource family.
- The README does not include local deployment instructions and assumes CI/CD-driven delivery.
- Deployment fails early with clear validation messages when generated names exceed limits.
- Security, monitoring, tagging, and operational settings are not omitted for convenience.
- The design is consistent with the Microsoft Well-Architected Framework.
- Public data-plane access is disabled by default for Storage, Key Vault, and Azure AI Services unless explicitly requested.
- Private endpoints and private DNS links are present for private-only data-plane services.
- Subnets used by workloads and private endpoints include NSG and route-table associations unless explicitly waived.
- Diagnostic settings are configured for critical services and target Log Analytics.
- Diagnostics API versions are stable where possible, and preview use is justified when unavoidable.
- Region and environment parameterization remains reusable unless a deliberate single-scope template was requested.

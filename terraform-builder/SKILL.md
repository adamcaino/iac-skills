---
name: terraform-builder
description: 'Create Terraform workloads for Microsoft Azure using the Microsoft Well-Architected Framework. Use when generating or refactoring Terraform, Azure landing zones, platform services, workload infrastructure, or IaC repositories that must use main.tf for Terraform and provider configuration plus resource-specific .tf files such as virtual_networks.tf, virtual_machines.tf, storage_accounts.tf, and key_vaults.tf instead of placing all resources into a monolithic main.tf.'
argument-hint: 'Describe the Azure workload, resource types, environment, and any naming, security, networking, or backend requirements.'
---

# Azure Terraform Workload Builder

Use this skill when creating or restructuring Terraform for Azure workloads that should align to the Microsoft Well-Architected Framework and follow a strict file decomposition model.

## Primary Outcomes

- Generate Terraform that is organized for maintenance, reviewability, and safe change isolation.
- Apply Microsoft Well-Architected Framework guidance across security, reliability, cost optimization, operational excellence, and performance efficiency.
- Reserve `main.tf` for Terraform and provider configuration rather than collapsing all resources into it.
- Generate a short `README.md` that explains the file structure, resource grouping, and architectural intent without including local deployment steps.
- Delegate ADR authoring to the `adr-generator` skill so Terraform authoring and architecture documentation remain decoupled.
- Question the user about workload intent, critical requirements, and constraints before generating code to ensure the design is fit for purpose.

## Non-Negotiable File Framework

Do not place all resources in `main.tf`.

Use this file layout by default unless the user explicitly requests a different structure:

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
```

### File Naming Rules

- `main.tf`: only Terraform settings, backend configuration, required provider blocks, provider configuration, and provider features.
- `locals.tf`: shared naming, tags, derived IDs, and computed values reused across files.
- `variables.tf`: cross-cutting input variables, typed objects, validation blocks, and defaults.
- `outputs.tf`: outputs that are intentionally exposed to parent modules or operators.
- `<resource_family_plural>.tf`: declare resources for a single Azure resource family.
- Use plural snake case file names for resource families, such as `virtual_networks.tf`, `virtual_machines.tf`, `storage_accounts.tf`, and `key_vaults.tf`.
- Declare `azurerm_private_endpoint` resources in the same file as the resource they connect to. For example, a storage private endpoint belongs in `storage_accounts.tf`, and a Key Vault private endpoint belongs in `key_vaults.tf`.
- If a resource family becomes too large, split within the same family using a clear suffix, such as `virtual_machines-linux.tf` and `virtual_machines-windows.tf`.
- Keep data sources with the closest relevant resource family where practical. If they are shared broadly, place them in `data_sources.tf`.

## Readability And Attribute Grouping

Generated Terraform should be formatted for human review, not just parser correctness.

### Attribute Grouping Rules

- Group related attributes together and separate groups with a single blank line.
- Place core identity metadata first, such as `name`, `resource_group_name`, and `location`.
- After the metadata group, insert a blank line before service-specific configuration such as `sku`, `account_tier`, `public_network_access_enabled`, `kind`, or feature flags.
- Insert a blank line before nested configuration blocks such as `identity`, `network_acls`, `blob_properties`, `private_service_connection`, or `os_disk` when they represent a different concern.
- Keep `tags` near the end of the resource as its own group.
- Place `lifecycle` last in the resource body, separated from `tags` by a blank line.
- Do not scatter single blank lines randomly; use them only to separate meaningful attribute groups.

### Example Layout

```hcl
resource "azurerm_key_vault" "platform" {
  name                = local.names.key_vault
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                     = var.key_vault_sku_name
  rbac_authorization_enabled   = true
  purge_protection_enabled     = true
  public_network_access_enabled = false

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.names.key_vault) <= 24
      error_message = "Key Vault name '${local.names.key_vault}' exceeds 24 characters. Shorten workload_name, environment, or location suffix."
    }
  }
}
```

### Hard Prohibitions

- Do not create `main.tf` as a catch-all resource file.
- Do not mix providers, networking, compute, storage, and monitoring resources together without a file boundary.
- Do not hide critical security or reliability settings behind unexplained defaults.
- Do not rely on implicit truncation or guesswork for Azure naming constraints; enforce name-length limits with Terraform preconditions.
- Do not centralize all private endpoints in a shared `private_endpoints.tf` file when those endpoints are tied to specific resources.

## Name-Length Pre-Validation Requirements

Generated names can exceed Azure limits when workload, environment, or region suffixes are concatenated. Enforce checks that fail early during `terraform validate` / `terraform plan`.

### Mandatory Pattern

- Add a `lifecycle { precondition {} }` block on any resource with strict name limits when the final name is computed.
- `lifecycle` blocks, if added, should be placed at the end of the resource declaration after normal arguments and nested blocks such as `tags`, `identity`, `sku`, `network_acls`, or `blob_properties`.
- Do not place `lifecycle` immediately after top-level metadata such as `name`, `location`, or `resource_group_name` unless the resource has no other substantive arguments.
- Use explicit checks such as `length(<computed_name>) <= 24`.
- Provide actionable `error_message` text that states the failing value and what to shorten.
- Keep name composition in `locals.tf` and validate the exact local value used by the resource.

### Minimum Resources To Validate

- `azurerm_key_vault` name length (`<= 24`).
- `azurerm_storage_account` name length (`<= 24`) and character constraints when applicable.
- Any additional Azure resource in the generated solution with hard name limits, for example AI services, machine learning or AI Foundry resources, container registries, and DNS resources.

### Example Guardrail Snippet

```hcl
resource "azurerm_key_vault" "platform" {
  name                = local.names.key_vault
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku_name

  rbac_authorization_enabled = true
  purge_protection_enabled   = true

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.names.key_vault) <= 24
      error_message = "Key Vault name '${local.names.key_vault}' exceeds 24 characters. Shorten workload_name, environment, or location suffix."
    }
  }
}
```

Use the same pattern for storage account and any other constrained resource names.

## Microsoft Well-Architected Framework Requirements

Every generated Terraform workload should be reasoned against these pillars.

### Reliability

- Prefer zonal or zone-redundant designs when the workload requires higher availability.
- Model dependencies explicitly so deployment order is deterministic.
- Include diagnostic settings and operational visibility for critical services.
- Use stable naming and tagging conventions that support recovery and operations.

### Security

- Prefer managed identities over secrets where Azure services support them.
- Use private networking, network security groups, and least-privilege role assignments where appropriate.
- Store secrets in Azure Key Vault instead of plain Terraform variables when runtime secrets are involved.
- Enable encryption, secure transfer, and service hardening settings by default unless the user directs otherwise.

### Cost Optimization

- Avoid oversized SKUs and unnecessary always-on components.
- Make pricing-sensitive choices explicit in variables so environments can scale appropriately.
- Tag resources for cost allocation and ownership.

### Operational Excellence

- Keep the Terraform layout readable so operators can review changes by resource family.
- Separate responsibilities into files that produce focused pull requests and plans.
- Use variables and locals to centralize naming, tags, locations, and environment patterns.
- Prefer explicit outputs only when they support automation or downstream composition.

### Performance Efficiency

- Select service tiers and instance shapes that match workload intent.
- Use architecture patterns that avoid unnecessary cross-region or cross-network latency.
- Keep the design ready for horizontal growth when the workload profile suggests it.

## Delivery Pattern

When asked to build Terraform, follow this sequence.

1. Identify the Azure services involved and group them into resource families.
2. Create `main.tf` first with version constraints, providers, backend configuration if specified, and provider features.
3. Create `locals.tf` for naming conventions, tags, environment metadata, and shared computed values.
4. Create `variables.tf` for reusable inputs and add validation for critical settings.
5. Create one `.tf` file per resource family.
6. Place private endpoints with the resource family they expose rather than in a central private-endpoint file.
7. Add `outputs.tf` only for values that need to be consumed externally.
8. Create a short `README.md` that explains the file structure, resource boundaries, and major design choices.
9. Invoke the `adr-generator` skill to produce ADRs for material design decisions.
10. Exclude local deployment instructions and assume deployment is handled by CI/CD pipelines.
11. Review the generated design against the Well-Architected pillars before finishing.

## Resource Family Mapping

Use these default mappings when choosing file names.

| Azure concern | Default file |
|---|---|
| Terraform and provider settings | `main.tf` |
| Resource groups | `resource_groups.tf` |
| Virtual networks, subnets, peering | `virtual_networks.tf` |
| Network security groups | `network_security_groups.tf` |
| Route tables and routes | `route_tables.tf` |
| Private DNS zones and links | `private_dns_zones.tf` |
| Private endpoints | colocate with the parent resource file, such as `storage_accounts.tf`, `key_vaults.tf`, or `ai_foundry.tf` |
| Virtual machines and NICs | `virtual_machines.tf` |
| Managed disks | `managed_disks.tf` |
| Availability sets or proximity placement groups | `compute_platform.tf` |
| Storage accounts and containers | `storage_accounts.tf` |
| Key Vault and secrets access policies or RBAC | `key_vaults.tf` |
| Log Analytics and Application Insights | `observability.tf` |
| Diagnostic settings | `monitor_diagnostic_settings.tf` |
| Role assignments | `role_assignments.tf` |

If a requested resource family is not listed, create a new plural snake case file that matches the resource type, such as `application_gateways.tf` or `container_registries.tf`.

## Authoring Rules

- Keep naming and tags consistent through locals.
- Prefer explicit resource names over opaque generated names.
- Keep modules focused; if a module is introduced, apply the same file framework inside the module.
- Preserve separation between platform primitives, security controls, observability, and workload resources.
- Keep private endpoints adjacent to the parent resource declaration so reviews show the exposed service and its network boundary together.
- Add lifecycle preconditions to constrained resources so naming violations fail before deployment.
- Place lifecycle blocks last in the resource body so the primary resource configuration is read first and guardrails are applied last.
- Add blank lines between attribute groups so metadata, service configuration, nested blocks, tags, and lifecycle are visually distinct.
- Create a short `README.md` for generated solutions that explains the repository layout, purpose of each file, and the main architectural decisions.
- Do not embed ADR authoring logic in this skill; use the `adr-generator` skill for ADR creation and structure.
- Do not include local deployment commands, manual apply steps, or workstation setup instructions in the README; assume delivery occurs through CI/CD pipelines.
- Add brief comments only when the intent is not obvious from the code.
- If the user asks for a single-file example, explain that the preferred repository convention is still split by resource family and only collapse files if explicitly required.

## Example Response Shape

When producing Terraform, explain the resulting file layout before presenting code.

```text
main.tf
  - terraform block
  - required_providers
  - provider "azurerm"

locals.tf
  - naming and tag locals

virtual_networks.tf
  - azurerm_virtual_network
  - azurerm_subnet

virtual_machines.tf
  - azurerm_network_interface
  - azurerm_linux_virtual_machine
```

## Review Checklist

Before finishing, verify all of the following:

- No catch-all `main.tf` file was used.
- `main.tf` contains only Terraform and provider configuration concerns.
- Each resource family is isolated into an appropriately named `.tf` file.
- Private endpoints are declared beside their parent resources rather than in a centralized `private_endpoints.tf` file.
- Name-length limits are enforced with lifecycle preconditions for Key Vault, Storage Account, and other constrained resources.
- Lifecycle blocks are placed at the end of resource declarations rather than near the top with metadata.
- Resource attributes are grouped with intentional blank lines so metadata, main configuration, tags, and lifecycle are easy to differentiate during review.
- A short `README.md` exists and explains the file structure and major architectural choices.
- ADRs are generated via the `adr-generator` skill and stored under `ADRs/`.
- The README does not include local deployment instructions and assumes CI/CD-driven delivery.
- `terraform validate` and `terraform plan` fail early with clear errors when generated names exceed limits.
- Security, monitoring, tagging, and operational settings are not omitted for convenience.
- The design is consistent with the Microsoft Well-Architected Framework.

# Resource Naming Convention And Name-Length Validation

## Format

```
<resource-acronym>-<workload>-<environment>-<location-code>-<instance>
```

| Component | Description | Examples |
|---|---|---|
| resource-acronym | Two-letter code for the resource type | `rg`, `vnet`, `nsg`, `fw`, `st`, `kv`, `law`, `pip`, `vhub`, `udr`, `nic`, `vm` |
| workload | Short workload identifier | `lz`, `db`, `app`, `shared` |
| environment | Environment name | `prod`, `staging`, `dev`, `test` |
| location-code | 3-letter region code | `uks`, `ukw`, `euw`, `eun`, `usc`, `use` |
| instance | Instance number | `01`, `02` |

Examples: `rg-lz-prod-uks-01`, `vnet-lz-prod-uks-01`, `nsg-app-prod-uks-01`, `kv-lz-prod-uks-01`, `vm-app-prod-uks-01`.

Lowercase alphanumeric and hyphens only. Instance numbers start at `01`. Extend the workload component with a tier suffix where needed (`nsg-db-prod-uks-01` vs `nsg-app-prod-uks-01`, `snet-db-prod-uks-01` vs `snet-app-prod-uks-01`). Centralize naming logic in `locals.tf` using a `local.names` map and reference names via `local.names.<resource_type>` in resource declarations.

## Name-Length Guardrail Pattern

Generated names can exceed Azure limits once workload/environment/region suffixes are concatenated. Enforce this so `terraform validate` / `terraform plan` fails early, not by inspection.

- Add a `lifecycle { precondition {} }` block on any resource with strict name limits, using the exact computed local value used by the resource.
- Place `lifecycle` at the end of the resource declaration, after normal arguments and nested blocks such as `tags`, `identity`, `sku`, `network_acls`, or `blob_properties` — never immediately after top-level metadata (`name`, `location`, `resource_group_name`) unless the resource has no other substantive arguments.
- Use explicit checks such as `length(<computed_name>) <= 24`.
- Error text must name the failing value and what to shorten.

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

## Minimum Resources To Validate

- Key Vault name: ≤ 24 chars.
- Storage account name: ≤ 24 chars, lowercase alphanumeric only.
- DNS zones, App Service names, container registries: ≤ 63 chars.
- Any other resource in the solution with a hard naming limit (AI services, ML, etc.) — apply the same pattern.

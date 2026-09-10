# Attribute Grouping And Example Layout

Blank lines separate concerns, not decoration. Order: identity metadata (`name`, `resource_group_name`, `location`) → service config (`sku`, `account_tier`, `public_network_access_enabled`, feature flags) → nested blocks (`identity`, `network_acls`, `blob_properties`, `private_service_connection`, `os_disk`) → `tags` on its own → `lifecycle` last, separated from `tags` by a blank line.

Do not scatter single blank lines randomly; use them only to separate meaningful attribute groups.

```hcl
resource "azurerm_key_vault" "platform" {
  name                = local.names.key_vault
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                       = var.key_vault_sku_name
  rbac_authorization_enabled     = true
  purge_protection_enabled       = true
  public_network_access_enabled  = false

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.names.key_vault) <= 24
      error_message = "Key Vault name '${local.names.key_vault}' exceeds 24 characters. Shorten workload_name, environment, or location suffix."
    }
  }
}
```

## Response Shape

Explain the resulting layout before presenting code, but only the parts that deviate from the default file framework in the core `SKILL.md` — don't re-emit the full default file list every time, only workload-specific resources and any deviation.

For repeated near-identical resources (e.g. three subnets each with their own NSG and route table), show one full worked example and then a compact table of what differs per instance (name, address prefix, associated NSG/route table) rather than several full repeated code blocks.

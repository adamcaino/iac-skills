# Attribute Grouping And Example Layout

Blank lines separate concerns, not decoration. Order: identity metadata (`name`, `location`, `scope`) → service config (SKU, feature flags, access model, retention) → nested objects (`identity`, `networkAcls`, `properties`, child resources) → `tags` last, on its own.

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

## Response Shape

Explain the resulting layout before presenting code, but only the parts that deviate from the default framework in the core `SKILL.md` — don't re-emit the full default tree diagram every time, only the workload-specific names and any deviation.

For repeated near-identical resources (e.g. three subnets each with their own NSG and route table), show one full worked example and then a compact table of what differs per instance (name, address prefix, associated NSG/route table) rather than three full repeated code blocks.

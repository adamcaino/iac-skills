# Naming Convention And Name-Length Validation

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

Example: `kv-lz-prod-uks-01`. Lowercase alphanumeric and hyphens only. Extend the workload component with a tier suffix where needed (`nsg-db-prod-uks-01` vs `nsg-app-prod-uks-01`). Centralise naming logic in shared variables or `modules/naming.bicep` if created — and if created, it must actually be consumed by `main.bicep`.

## Name-Length Guardrail Pattern

Generated names can exceed Azure limits once workload/environment/region suffixes are concatenated. Enforce this at compile time, not by inspection.

- Default mechanism: parameter decorators (`@minLength`, `@maxLength`, `@allowed`).
- Use `assert` for computed-name validation only when assertions are enabled in the target environment.
- Compose the name in a shared variable, and validate the exact computed value used by the resource — not just the input parameters.
- Error text must name the failing value and what to shorten.

```bicep
param workloadName string
@maxLength(10)
param environment string
param locationShort string

var keyVaultName = 'kv-${workloadName}-${environment}-${locationShort}'

// Decorators constrain the inputs at compile time. If assertions are enabled, also add:
// assert keyVaultNameLength (length(keyVaultName) <= 24) : 'Key Vault name "${keyVaultName}" exceeds 24 characters. Shorten workloadName, environment, or locationShort.'
```

## Minimum Resources To Validate

- Key Vault name: ≤ 24 chars.
- Storage account name: ≤ 24 chars, lowercase alphanumeric only.
- DNS zones, App Service names, container registries: ≤ 63 chars.
- Any other resource in the solution with a hard naming limit (AI services, ML, etc.) — apply the same pattern.

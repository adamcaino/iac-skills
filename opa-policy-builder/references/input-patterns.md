# Policy Patterns By Input Type

Use the smallest practical abstraction for the input type:

- **Terraform plan JSON** — iterate planned resources via `resource_changes`; check `change.after` values for desired state.
- **Kubernetes manifests** — validate `kind`, `metadata`, and `spec` with clear path checks; separate workload controls (pods/deployments) from cluster-scoped controls.
- **ARM/Bicep compiled JSON** — evaluate `resources[*]` entries by `type`, `name`, and `properties`; keep aliases and type matching in helpers to avoid duplication.

## Terraform Plus Bicep Strategy

When the user targets both Terraform and Bicep:

- Define shared control intent first, such as public exposure, encryption, required tags, and diagnostics.
- Implement source-specific rules for each input schema rather than forcing one parser pattern.
- Keep policy identifiers aligned across both sources so reporting can be correlated.
- Keep exceptions explicit per source, because resource type names and paths differ.
- Prefer a shared message schema so CI output remains consistent.
- Ask whether controls should be identical across both inputs, or whether each source should have tailored thresholds and exceptions.

# Well-Architected Framework Pillars

Reason generated Terraform against these when making a design decision — not a checklist to restate in output.

**Reliability** — zonal/zone-redundant where availability demands it; explicit dependencies for deterministic apply order; diagnostics on critical services; stable naming/tagging for recovery and ops.

**Security** — managed identities over secrets where supported; private networking, NSGs, least-privilege role assignments; secrets in Key Vault, never plain Terraform variables; encryption and secure transfer on by default.

**Cost Optimization** — avoid oversized SKUs and always-on components by default; make pricing-sensitive choices explicit variables so environments can scale; tag for cost allocation/ownership.

**Operational Excellence** — layout readable by resource family; files sized for focused, reviewable plans; naming/tags/location/environment centralized in `locals.tf`/`variables.tf`; outputs only where they support automation or cross-boundary composition.

**Performance Efficiency** — service tiers matched to workload intent; avoid unnecessary cross-region/cross-network latency; leave headroom for horizontal growth where the workload profile suggests it.

## MSP Security Baseline (default unless the user overrides)

- Private-only data-plane access for Storage, Key Vault, Azure AI Services — `public_network_access_enabled = false` by default; public access needs an explicit user override.
- Private endpoints colocated with the parent resource file, linked to the matching private DNS zone.
- Subnet-level NSG and route-table association for app/platform subnets unless explicitly waived.
- Key Vault: `rbac_authorization_enabled = true`, no access-policy sprawl.

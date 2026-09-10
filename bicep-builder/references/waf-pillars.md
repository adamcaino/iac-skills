# Well-Architected Framework Pillars

Reason generated Bicep against these when making a design decision — not a checklist to restate in output.

**Reliability** — zonal/zone-redundant where availability demands it; explicit dependencies for deterministic deploy order; diagnostics on critical services; stable naming/tagging for recovery and ops.

**Security** — managed identities over secrets where supported; private networking, NSGs, least-privilege RBAC; secrets in Key Vault, never plain-text parameters; encryption and secure transfer on by default.

**Cost Optimization** — avoid oversized SKUs and always-on components by default; make pricing-sensitive choices explicit parameters so environments can scale; tag for cost allocation/ownership.

**Operational Excellence** — layout readable by resource family; modules sized for focused, reviewable PRs; naming/tags/location/environment centralised; outputs only where they support automation or cross-boundary composition.

**Performance Efficiency** — service tiers matched to workload intent; avoid unnecessary cross-region/cross-network latency; leave headroom for horizontal growth where the workload profile suggests it.

## MSP Security Baseline (default unless the user overrides)

- Private-only data-plane access for Storage, Key Vault, Azure AI Services — `publicNetworkAccess: 'Disabled'` by default; public access needs an explicit user override.
- Private endpoints colocated with the parent resource module, linked to the matching private DNS zone.
- Subnet-level NSG and route-table association for app/platform subnets unless explicitly waived.
- Key Vault: `enableRbacAuthorization: true`, no access-policy sprawl.

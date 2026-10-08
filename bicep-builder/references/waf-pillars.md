# Well-Architected Framework Pillars

Reason generated Bicep against these when making a design decision — not a checklist to restate in output.

**Reliability** — zonal/zone-redundant where availability demands it; explicit dependencies for deterministic deploy order; diagnostics on critical services; stable naming/tagging for recovery and ops.

**Security** — managed identities over secrets where supported; private networking, NSGs, least-privilege RBAC; secrets in Key Vault, never plain-text parameters; encryption and secure transfer on by default.

**Cost Optimization** — avoid oversized SKUs and always-on components by default; make pricing-sensitive choices explicit parameters so environments can scale; tag for cost allocation/ownership.

**Operational Excellence** — layout readable by resource family; modules sized for focused, reviewable PRs; naming/tags/location/environment centralised; outputs only where they support automation or cross-boundary composition.

**Performance Efficiency** — service tiers matched to workload intent; avoid unnecessary cross-region/cross-network latency; leave headroom for horizontal growth where the workload profile suggests it.

The default security baseline is in `SKILL.md` ("Security Baseline And Prohibitions").

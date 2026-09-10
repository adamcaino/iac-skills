---
name: opa-policy-builder
description: 'Generate Policy-as-Code using Open Policy Agent (OPA) with readable Rego, focused rule sets, and test coverage for infrastructure workflows. Use when authoring or refactoring guardrails for Terraform plan JSON first, and optionally combining Terraform with ARM/Bicep JSON policy validation in the same workflow.'
argument-hint: 'Describe the policy domain, target input shape, enforcement level (advisory or deny), and any standards or controls that must be enforced.'
---

# OPA Policy-As-Code Builder

Create clear, maintainable OPA policies that are easy to read, test, and enforce in infrastructure pipelines.

This file holds the rules needed on every task. Load a reference file only when the task needs it:

- `references/rego-v1-syntax.md` — Rego v1 syntax quickstart, common gotchas, and a full test-file template. Load whenever you're about to write or debug a `.rego` file.
- `references/input-patterns.md` — per-input-type policy patterns (Terraform/Kubernetes/Bicep) and the Terraform+Bicep mixed-mode strategy. Load when the target input type isn't Terraform plan JSON, or the user wants mixed mode.
- `references/style-and-examples.md` — deny/warn message shape, example response shape, README requirements. Load once per session if you need the worked example.
- `scripts/validate-opa.sh` — run this, don't invoke `opa test`/`opa eval` manually (see Validation below).

## Primary Outcomes

- Default to Terraform plan JSON as the primary target unless the user requests a different one.
- Produce readable Rego with explicit intent and minimal complexity; separate policy logic, shared helpers, and tests so changes are reviewable.
- Enforce deterministic outcomes with clear deny messages and optional advisory warnings.
- Include policy tests by default so behavior is validated before CI integration.
- Ask all clarifying questions in one batch, before generating any policy — not iteratively as you go.

## Scope

This skill owns OPA Policy-as-Code authoring and test scaffolding.

Use when: building policy guardrails for Terraform plan JSON, Kubernetes manifests, ARM/Bicep JSON, or generic JSON/YAML payloads; refactoring existing Rego for readability; creating policy bundles for CI gates, PR checks, or admission-control-style validation.

Do not use for: provisioning infrastructure resources directly, replacing native platform deployment templates, or designing full compliance programs without concrete policy requirements.

## Required Clarifying Questions

Ask up front if any of the following are unclear:

1. Target platform and input format (Terraform plan JSON, Kubernetes manifests, ARM/Bicep JSON, or another schema)?
2. Enforcement mode — `deny` (hard fail), `warn` (advisory), or both?
3. Policy boundaries — which resources/namespaces are in scope, and which are explicitly excluded?
4. Source of truth — which controls, standards, or internal rules should be codified?
5. Severity and message style — should output include control IDs, severity levels, remediation hints?

If mixing Terraform and Bicep, also ask whether controls should be identical across both inputs or tailored per source.

If answers are incomplete, proceed with a minimal, safe baseline and clearly mark assumptions.

## Non-Negotiable File Framework

```text
policy/
  <domain>/
    <policy_name>.rego
    helpers.rego
tests/
  <domain>/
    <policy_name>_test.rego
examples/
  <domain>/
    pass.json
    fail.json
README.md
```

When mixing Terraform and Bicep, split each top-level folder by source (`policy/terraform/`, `policy/bicep/`, and mirrored under `tests/` and `examples/`).

### File Rules

- One policy concern per policy file. Split unrelated controls.
- Keep reusable helper rules in `helpers.rego`.
- Name policy files with lowercase snake_case; mirror the policy folder structure under `tests/`.
- Include at least one passing and one failing example input for each policy set.

## Rego Authoring Rules

- Use `import rego.v1` and `default allow := false` when allow/deny patterns are used.
- Prefer explicit rule names (`deny`, `warn`, helper predicates); keep rule bodies short, extracting repeated predicates into helpers.
- Return structured, actionable messages instead of generic failures — see `references/style-and-examples.md` for the message shape.
- Avoid deeply nested comprehensions when a helper rule is clearer; add defensive null/existence checks for optional fields.
- Add brief comments only for non-obvious logic.
- Full Rego v1 syntax rules, gotchas, and the test template: `references/rego-v1-syntax.md`.

## Testing Requirements

Every generated policy must include tests. Minimum set: one passing test for compliant input, one failing test for non-compliant input, one edge-case test for missing/optional fields.

- Use descriptive test names, e.g. `test_storage_public_access_denied`.
- Use `plan_data` or `fixture` variable names, never `input` (reserved in tests).
- Assert on both rule outcome and key message fields.

## Delivery Pattern

1. Confirm input type, enforcement mode, and in-scope resources in one batch of questions. Default to Terraform if unspecified.
2. Define package naming and policy file boundaries.
3. Author policy rules with helper predicates for shared checks.
4. Add structured deny/warn outputs with remediation guidance.
5. Add tests for pass, fail, and edge-case scenarios (load `references/rego-v1-syntax.md` first).
6. Add minimal example inputs under `examples/`.
7. Write a short `README.md` (see `references/style-and-examples.md` for what it must cover).
8. Run `scripts/validate-opa.sh` (see Validation below). Fix and re-run until it exits 0.

For mixed Terraform and Bicep workflows, run steps 2-8 per source package.

## Validation

Run `scripts/validate-opa.sh [policy-root]` once, rather than issuing individual `opa test`/`opa eval` commands. It runs `opa test` across `policy/` and `tests/`, then evaluates every example under `examples/`, failing loudly with a nonzero exit code if anything breaks. Do not deliver policy until it exits 0.

## Review Checklist

Quick pass before finishing — these are pointers back to the rules above, not new rules:

- [ ] Clarifying questions were asked when required details were missing.
- [ ] Policy files are split by concern; Rego uses `import rego.v1` and avoids unnecessary complexity.
- [ ] `scripts/validate-opa.sh` exits 0 (no reserved-variable shadowing, correct built-ins, examples validate).
- [ ] Tests cover pass, fail, and edge-case behavior; examples are minimal and representative.
- [ ] README explains intent, scope, and automation usage (`references/style-and-examples.md`).

---
name: opa-policy-builder
description: 'Generate Policy-as-Code using Open Policy Agent (OPA) with readable Rego, focused rule sets, and test coverage for infrastructure workflows. Use when authoring or refactoring guardrails for Terraform plan JSON first, and optionally combining Terraform with ARM/Bicep JSON policy validation in the same workflow.'
argument-hint: 'Describe the policy domain, target input shape, enforcement level (advisory or deny), and any standards or controls that must be enforced.'
---

# OPA Policy-As-Code Builder

Use this skill to create clear, maintainable OPA policies that are easy to read, test, and enforce in infrastructure pipelines.

## Primary Outcomes

- Default to Terraform policy generation unless the user requests a different primary target.
- Produce readable Rego policies with explicit intent and minimal complexity.
- Separate policy logic, shared helpers, and tests so changes are reviewable.
- Enforce deterministic outcomes with clear deny messages and optional advisory warnings.
- Include policy tests by default so behavior is validated before CI integration.
- Ask clarifying questions before generating policy when scope, input shape, or enforcement mode is unclear.

## Default Targeting Model

- Primary default: Terraform plan JSON.
- Secondary supported target: ARM/Bicep compiled JSON.
- Mixed mode is supported and recommended when your platform uses both Terraform and Bicep.
- Keep source-specific parsing in separate packages while sharing control intent where possible.

## Scope

This skill owns OPA Policy-as-Code authoring and test scaffolding.

Use this skill when:
- Building policy guardrails for Terraform plan JSON, Kubernetes manifests, ARM/Bicep JSON, or generic JSON/YAML payloads.
- Refactoring existing Rego for readability and maintainability.
- Creating policy bundles for CI gates, pull request checks, or admission control style validation.

Prioritize Terraform-first delivery when the user does not specify otherwise.

Do not use this skill for:
- Provisioning infrastructure resources directly.
- Replacing native platform deployment templates.
- Designing full compliance programs without concrete policy requirements.

## Required Clarifying Questions

Before writing policy, ask concise questions if any of the following are missing:

1. Target platform and input format:
   - Terraform plan JSON, Kubernetes manifests, ARM/Bicep JSON, or another schema?
2. Enforcement mode:
   - `deny` (hard fail), `warn` (advisory), or both?
3. Policy boundaries:
   - Which resources or namespaces are in scope, and which are explicitly excluded?
4. Source of truth:
   - Which controls, standards, or internal rules should be codified?
5. Severity and message style:
   - Should outputs include control IDs, severity levels, and remediation hints?

If answers are incomplete, proceed with a minimal, safe baseline and clearly mark assumptions.

For Terraform plus Bicep mixed mode, ask one extra question:

- Should controls be identical across both inputs, or should each source have tailored thresholds and exceptions?

## Non-Negotiable File Framework

Use this structure by default unless the user requests a different layout:

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

When mixing Terraform and Bicep, split by source:

```text
policy/
  terraform/
    <policy_name>.rego
    helpers.rego
  bicep/
    <policy_name>.rego
    helpers.rego
tests/
  terraform/
    <policy_name>_test.rego
  bicep/
    <policy_name>_test.rego
examples/
  terraform/
    pass.json
    fail.json
  bicep/
    pass.json
    fail.json
README.md
```

### File Rules

- One policy concern per policy file. Split unrelated controls.
- Keep reusable helper rules in `helpers.rego`.
- Name policy files with lowercase snake case.
- Mirror policy folder structure under `tests/`.
- Include at least one passing and one failing example input for each policy set.

## Rego Authoring Rules

Default to modern Rego style for readability:

- Use `import rego.v1`.
- Use `default allow := false` when allow/deny patterns are used.
- Prefer explicit rule names such as `deny`, `warn`, and helper predicates.
- Keep rule bodies short; extract repeated predicates into helpers.
- Return structured, actionable messages instead of generic failures.
- Keep policy package names stable and domain-oriented.

### Message Shape

When producing deny or warning output, prefer objects with consistent keys:

```rego
{
  "id": "POL-001",
  "title": "Public network access is not allowed",
  "severity": "high",
  "resource": resource_id,
  "message": "Set public access to disabled.",
  "remediation": "Use private endpoints and disable public access."
}
```

## Rego v1 Syntax Quickstart

**Critical patterns for Rego v1:**

- **Built-in functions:** Use `count()` for string/array length, not `length()`. Use `contains()`, `startswith()`, `endswith()` for string operations.
- **Multi-condition chains:** Use `;` or line breaks, never `or` in condition expressions.
- **Reserved variables:** Never reassign `input` in test bodies. Use `plan_data`, `fixture`, or `test_input` instead.
- **Iteration with `some`:** Always include field access and comparison after the `in` clause.
- **Null and empty checks:** Defensive checks for optional fields avoid implicit failures.

## Common Gotchas to Avoid

- **Variable shadowing:** Tests fail if they redefine `input` (reserved under Rego v1).
- **Test rule syntax:** Test rules use `if`, not `pass if`.
- **Operator precedence:** Avoid `or` in multi-condition chains; use `|` (union) or separate conditions.
- **Field access timing:** With `some item in result`, access fields after the clause: `some item in result; item.id == "POL-001"`.
- **Assertion patterns:** Use comprehensions or explicit `some` with field access for clarity in tests.

## Test Code Template (Rego v1)

Use this template when authoring test files to avoid common syntax errors:

```rego
package policy.name_test

import rego.v1
import data.policy.name

test_compliant_configuration if {
    plan_data := {
        "resource_changes": [{
            "address": "azurerm_resource.example",
            "type": "azurerm_resource",
            "change": {
                "after": {
                    "name": "compliant-name",
                    "enabled": true
                }
            }
        }]
    }

    result := name.deny with input as plan_data
    count(result) == 0
}

test_noncompliant_configuration if {
    plan_data := {
        "resource_changes": [{
            "address": "azurerm_resource.example",
            "type": "azurerm_resource",
            "change": {
                "after": {
                    "name": "noncompliant-name",
                    "enabled": false
                }
            }
        }]
    }

    result := name.deny with input as plan_data
    count(result) > 0
    some violation in result
    violation.id == "POL-001"
}

test_missing_optional_field if {
    plan_data := {
        "resource_changes": [{
            "address": "azurerm_resource.example",
            "type": "azurerm_resource",
            "change": {
                "after": {
                    "name": "config-without-optional"
                }
            }
        }]
    }

    result := name.deny with input as plan_data
}
```

Key points:
- Use `plan_data` (or `fixture`/`test_input`), never `input`.
- Always use `if`, not `pass if` or `pass` keywords.
- Validate both rule execution and message structure with `some violation in result; violation.id == "..."`.

## Simplicity And Readability Guardrails

- Avoid deeply nested comprehensions when a helper rule is clearer.
- Avoid large monolithic rules that combine multiple controls.
- Avoid implicit behavior that depends on missing fields without defensive checks.
- Prefer explicit null and existence handling for optional attributes.
- Add brief comments only for non-obvious logic.

## Policy Patterns By Input Type

Use the smallest practical abstraction for the input type:

- Terraform plan JSON:
  - Iterate planned resources via `resource_changes`.
  - Check `change.after` values for desired state.
- Kubernetes manifests:
  - Validate `kind`, `metadata`, and `spec` with clear path checks.
  - Separate workload controls (pods/deployments) from cluster-scoped controls.
- ARM/Bicep compiled JSON:
  - Evaluate `resources[*]` entries by `type`, `name`, and `properties`.
  - Keep aliases and type matching in helpers to avoid duplication.

## Terraform Plus Bicep Strategy

When the user targets both Terraform and Bicep:

- Define shared control intent first, such as public exposure, encryption, required tags, and diagnostics.
- Implement source-specific rules for each input schema rather than forcing one parser pattern.
- Keep policy identifiers aligned across both sources so reporting can be correlated.
- Keep exceptions explicit per source, because resource type names and paths differ.
- Prefer a shared message schema so CI output remains consistent.

## Testing Requirements

Every generated policy must include tests.

Minimum test set:

- One passing test for compliant input.
- One failing test for non-compliant input.
- One edge-case test for missing or optional fields.

Test authoring rules:

- Use descriptive test names, for example `test_storage_public_access_denied`.
- Assert on both rule outcome and key message fields.
- Keep fixtures small and focused on the behavior under test.
- Use `plan_data` or `fixture` variable names, never `input` (reserved in tests).
- Always run `opa test` before delivery to validate Rego syntax and type correctness.
- Prefer `some element in result; element.id == "POL"` pattern for assertions over complex comprehensions when possible.

## Delivery Pattern

When asked to generate OPA policy, follow this sequence:

1. Confirm input type, enforcement mode, and in-scope resources. Default to Terraform if unspecified.
2. Define package naming and policy file boundaries.
3. Author policy rules with helper predicates for shared checks.
4. Add structured deny/warn outputs with remediation guidance.
5. Add tests for pass, fail, and edge-case scenarios using correct Rego v1 syntax.
6. Add minimal example inputs under `examples/`.
7. Write a short `README.md` that explains policy intent, expected input, and how to run tests in CI.
8. **Validate generated policy:** Run `opa test policy/ tests/ -v` to catch syntax errors, type mismatches, and test failures before handoff. Verify both examples (pass.json and fail.json) with `opa eval`.

For mixed Terraform and Bicep workflows, run steps 2 through 8 per source package.

## README Requirements

The generated `README.md` should include:

- What the policy enforces.
- Expected input schema at a high level.
- How outcomes are surfaced (`deny`, `warn`, or both).
- How to run policy tests and evaluations in automation.
- Known assumptions and explicit exclusions.

Do not include workstation-specific setup instructions unless the user requests them.

## Example Response Shape

When producing policy, explain the output structure before code.

```text
policy/network/public_access.rego
  - deny rule for public exposure
  - helper predicates for scope and exceptions

tests/network/public_access_test.rego
  - compliant input test
  - non-compliant input test
  - missing field edge-case test

examples/network/pass.json
examples/network/fail.json
README.md
```

## Review Checklist

Before finishing, verify all of the following:

- Clarifying questions were asked when required details were missing.
- Policy files are split by concern and are easy to review.
- Rego uses `import rego.v1` and avoids unnecessary complexity.
- Output messages are actionable and consistent in structure.
- Tests cover pass, fail, and edge-case behavior.
- Example inputs are minimal and representative.
- README explains intent, scope, and automation usage.
- **OPA compilation succeeds:** `opa test` runs without parse or type errors.
- **No reserved variable shadowing:** Tests use `plan_data`, `fixture`, or `test_input`, never `input`.
- **Built-in functions are correct:** Uses `count()` not `length()`, proper `some` iteration syntax with field access.
- **Examples validate:** At least one pass and one fail example run without errors via `opa eval`.
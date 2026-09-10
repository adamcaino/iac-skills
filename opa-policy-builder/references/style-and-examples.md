# Message Shape And Example Response Shape

## Deny/Warn Message Shape

Prefer objects with consistent keys:

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

## README Requirements

The generated `README.md` should include:

- What the policy enforces.
- Expected input schema at a high level.
- How outcomes are surfaced (`deny`, `warn`, or both).
- How to run policy tests and evaluations in automation.
- Known assumptions and explicit exclusions.

Do not include workstation-specific setup instructions unless the user requests them.

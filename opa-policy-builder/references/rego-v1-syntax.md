# Rego v1 Syntax Quickstart

Load this when writing or debugging actual `.rego` files — policy or test. The core `SKILL.md` covers what files to create; this covers how to not break the parser.

## Critical Patterns

- **Built-in functions:** Use `count()` for string/array length, not `length()`. Use `contains()`, `startswith()`, `endswith()` for string operations.
- **Multi-condition chains:** Use `;` or line breaks, never `or` in condition expressions.
- **Reserved variables:** Never reassign `input` in test bodies. Use `plan_data`, `fixture`, or `test_input` instead.
- **Iteration with `some`:** Always include field access and comparison after the `in` clause, e.g. `some item in result; item.id == "POL-001"`.
- **Null and empty checks:** Defensive checks for optional fields avoid implicit failures.
- **Test rule syntax:** Test rules use `if`, not `pass if` or `pass`.

## Common Gotchas

- **Variable shadowing:** Tests fail if they redefine `input` (reserved under Rego v1).
- **Operator precedence:** Avoid `or` in multi-condition chains; use `|` (union) or separate conditions.
- **Field access timing:** With `some item in result`, access fields after the clause, not inline with it.
- **Assertion patterns:** Use comprehensions or explicit `some` with field access for clarity in tests.

## Test Code Template

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

Key points: use `plan_data` (or `fixture`/`test_input`), never `input`; always use `if`, not `pass if`/`pass`; validate both rule execution and message structure with `some violation in result; violation.id == "..."`.

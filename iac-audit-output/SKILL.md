---
name: iac-audit-output
description: 'Generate standardized IaC audit outputs in JSON, Markdown, and CSV for downstream systems. Use when normalizing findings from Terraform and Bicep reviews into machine-consumable exports and human-readable reports.'
argument-hint: 'Describe the audit findings source, requested output formats (json, md, csv), audience, and any required metadata fields.'
---

# IaC Audit Output Formatter

Use this skill to transform review findings into consistent JSON, Markdown, and CSV outputs for automation, customer reporting, and analytics systems.

## Primary Outcomes

- Produce one canonical finding model that can be exported into multiple formats without losing meaning.
- Keep JSON stable for downstream app integrations.
- Keep Markdown concise and client-readable for Word or PDF conversion workflows.
- Keep CSV flattened and predictable for reporting tools such as Power BI.
- Preserve severity ordering and traceability back to source files.

## Scope

This skill owns output formatting for IaC review results.

Use this skill when:
- Findings from `terraform-reviewer` or `bicep-reviewer` must be exported.
- A report must be consumed by APIs, customers, or BI tools.
- A consistent schema is required across engagements.

Do not use this skill for:
- Performing the review itself.
- Creating or modifying infrastructure code.
- Replacing governance decisions about severity and risk policy.

## Required Clarifying Questions

Before formatting output, ask if any of the following are unclear:

1. Formats required:
   - `json`, `md`, `csv`, or all three?
2. Delivery target:
   - Chat response only, or also write files?
3. Audience:
   - Engineering team, customer stakeholders, or reporting pipeline?
4. Metadata:
   - Include client name, assessment date, reviewer, and environment?
5. CSV handling:
   - One row per finding only, or include remediation-plan rows too?

If details are missing, output all three formats with balanced defaults and clearly labeled assumptions.

## Canonical Finding Model

All exports must map to this canonical shape:

- `report_id`
- `generated_at_utc`
- `tool_source` (`terraform-reviewer` or `bicep-reviewer`)
- `scope_summary`
- `findings[]`
  - `id`
  - `severity` (`critical`, `high`, `medium`, `low`)
  - `category`
  - `pillar`
  - `location`
  - `issue`
  - `risk`
  - `recommendation`
  - `effort` (`small`, `medium`, `large`)
- `open_questions[]`
- `assumptions[]`
- `remediation_plan[]`
- `residual_risks[]`
- `test_gaps[]`

Severity order is mandatory: `critical`, `high`, `medium`, `low`.

## JSON Output Rules

- Emit valid JSON with deterministic key ordering.
- Do not omit empty arrays; use empty arrays for missing sections.
- Keep data typed, with arrays for list sections.
- Use ISO-8601 UTC timestamps.

Minimum JSON top-level keys:

```json
{
  "report_id": "string",
  "generated_at_utc": "2026-03-28T10:00:00Z",
  "tool_source": "terraform-reviewer",
  "scope_summary": {
    "scope": "string",
    "baseline": "string",
    "exclusions": []
  },
  "findings": [],
  "open_questions": [],
  "assumptions": [],
  "remediation_plan": [],
  "residual_risks": [],
  "test_gaps": []
}
```

## Markdown Output Rules

- Use this section order:
  1. Scope Summary
  2. Findings
  3. Open Questions and Assumptions
  4. Remediation Plan
  5. Residual Risks and Test Gaps
- Group findings by severity with stable identifiers.
- Include location references and effort estimates in each finding.
- Keep wording client-readable and free of tool-internal jargon.

## CSV Output Rules

- One row per finding.
- UTF-8, comma-delimited, header required.
- Quote fields that may contain commas or line breaks.
- Keep column names stable across all reports.

Required CSV columns:

`report_id,generated_at_utc,tool_source,severity,id,category,pillar,location,issue,risk,recommendation,effort,scope,baseline`

Optional columns:

`client,environment,reviewer,assessment_date,tags`

## Delivery Pattern

When asked to produce exports, follow this sequence:

1. Normalize findings into the canonical model.
2. Sort findings by severity and stable ID.
3. Generate JSON export.
4. Generate Markdown export from the same source model.
5. Generate CSV export from findings.
6. Validate that counts and IDs match across all formats.

## Cross-Format Consistency Checks

Before finishing, verify all of the following:

- JSON, MD, and CSV contain the same finding IDs.
- Severity counts are identical across formats.
- No finding exists in one format only.
- Location references are preserved across formats.
- Empty sections are represented consistently.

## Hard Prohibitions

- Do not invent findings that were not in the source review.
- Do not reorder severity outside the defined order.
- Do not drop fields for convenience in CSV.
- Do not use different IDs per format.
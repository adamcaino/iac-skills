# Per-Format Output Rules

Load the section for the format(s) actually being produced.

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

- Use this section order: Scope Summary, Findings, Open Questions and Assumptions, Remediation Plan, Residual Risks and Test Gaps.
- Group findings by severity with stable identifiers.
- Include location references and effort estimates in each finding.
- Keep wording client-readable and free of tool-internal jargon.

## CSV Output Rules

- One row per finding.
- UTF-8, comma-delimited, header required.
- Quote fields that may contain commas or line breaks.
- Keep column names stable across all reports.

Required columns:

`report_id,generated_at_utc,tool_source,severity,id,category,pillar,location,issue,risk,recommendation,effort,scope,baseline`

Optional columns:

`client,environment,reviewer,assessment_date,tags`

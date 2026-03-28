---
name: adr-generator
description: 'Generate Architecture Decision Records (ADRs) for infrastructure and application designs. Use when documenting technical decisions, trade-offs, alternatives, and consequences in a consistent ADR format with one decision per ADR file.'
argument-hint: 'Describe the system context and list each decision that must be documented as a separate ADR.'
---

# ADR Generator

Use this skill to create clear, reviewable Architecture Decision Records that document why key design choices were made.

## Primary Outcomes

- Produce ADRs that are concise, actionable, and easy to review in pull requests.
- Keep one decision per ADR file.
- Capture context, decision, alternatives, and consequences for each ADR.
- Maintain a consistent ADR naming and numbering convention.

## Scope

This skill owns ADR generation and ADR structure.

Use this skill when:
- A solution introduces one or more architectural decisions.
- A platform or workload skill asks for ADR output.
- Existing ADRs need to be split, normalized, or rewritten.

Do not use this skill for:
- Generating Terraform, Bicep, source code, or deployment pipelines.
- Producing implementation details that belong in code comments or READMEs.

## ADR File Rules

- Store ADRs under an `ADRs/` folder.
- Use one decision per file. If there are N decisions, generate N ADR files.
- Do not bundle unrelated decisions in one ADR.
- Use sequential numbering with zero-padding: `001-<slug>.md`, `002-<slug>.md`, and so on.
- Use lowercase kebab-case for slugs.

## Required ADR Template

Each ADR must include these sections in order:

1. `# ADR <number> - <short title>`
2. `Status` (for example: Proposed, Accepted, Superseded)
3. `Date` (ISO format: YYYY-MM-DD)
4. `## Context`
5. `## Decision`
6. `## Alternatives Considered`
7. `## Consequences`

Optional sections (only when useful):
- `## Assumptions`
- `## Follow-up Actions`
- `## References`

## Decision Quality Rules

- State a single, explicit decision in the `Decision` section.
- Mention at least one realistic alternative and why it was not chosen.
- Keep rationale specific to constraints (cost, security, reliability, performance, operations).
- Describe positive and negative consequences.
- Avoid vague wording like "best practice" without context.

## Splitting Existing Multi-Decision ADRs

When an ADR contains multiple decisions:
- Extract each decision into its own new ADR file.
- Preserve shared background in each new ADR `Context` section.
- Add short cross-references between ADRs where decisions are coupled.
- Mark the original bundled ADR as superseded when requested.

## Output Shape

When generating ADRs, first provide the planned ADR index, then the ADR files.

Example index:

```text
ADRs/
  001-network-boundary-strategy.md
  002-identity-and-secret-strategy.md
  003-observability-baseline.md
```

## Review Checklist

Before finishing, verify all of the following:

- Every material decision has a dedicated ADR file.
- No ADR file documents more than one decision.
- Numbering is sequential and filenames are kebab-case.
- Each ADR includes context, decision, alternatives, and consequences.
- Status and date are present.

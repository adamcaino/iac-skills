---
name: terraform-reviewer
description: 'Review existing Terraform for Azure with a standardized, repeatable audit output model. Use when performing peer-style IaC audits, quality gates, risk analysis, and remediation planning across security, reliability, cost, operational excellence, and performance.'
argument-hint: 'Describe the Terraform scope, target environment, risk tolerance, and any compliance baselines so the review can produce prioritized findings and remediation actions.'
---

# Azure Terraform Reviewer

Use this skill to audit existing Terraform with consistent findings, severity scoring, and actionable remediation guidance.

## Primary Outcomes

- Produce a standardized audit report that is stable across repositories and review cycles.
- Prioritize findings by severity and impact so remediation can be planned.
- Map findings to Microsoft Well-Architected Framework pillars.
- Highlight behavioral risks and regressions before style concerns.
- Keep recommendations practical, with clear effort and expected impact.
- Delegate JSON, Markdown, and CSV export formatting to the `iac-audit-output` skill when downstream consumption is requested.

## Scope

This skill owns Terraform review and audit reporting.

Use this skill when:
- Reviewing existing Terraform codebases, pull requests, modules, or platform foundations.
- Running periodic IaC health checks and governance reviews.
- Producing standardized audit output for client-facing review services.

Do not use this skill for:
- Generating new Terraform implementations from scratch.
- Deploying resources or changing runtime environments directly.
- Producing policy-as-code logic (handled by dedicated OPA skills).

## Required Clarifying Questions

Before reviewing, ask if any of the following are unclear:

1. Review scope:
   - Entire repository, selected folders, or specific pull request diff?
2. Baseline:
   - Enterprise standards, CIS, internal guardrails, or Well-Architected only?
3. Output depth:
   - Executive summary only, full technical findings, or both?
4. Risk model:
   - Should severity be strict, balanced, or availability-first?
5. Exclusions:
   - Which files, modules, or temporary exceptions should be ignored?

If details are missing, proceed with a balanced default and clearly label assumptions.

## Standardized Audit Output Contract

Always return findings in this shape and order for consistency:

1. Scope Summary
2. Findings (ordered by severity: critical, high, medium, low)
3. Open Questions and Assumptions
4. Remediation Plan
5. Residual Risks and Test Gaps

Each finding must include:

- `id`: stable identifier, for example `TF-AUD-001`
- `severity`: `critical` | `high` | `medium` | `low`
- `category`: security | reliability | cost | operational-excellence | performance | maintainability
- `pillar`: Well-Architected pillar mapping
- `location`: file path and line reference when available
- `issue`: concise problem statement
- `risk`: concrete impact if left unresolved
- `recommendation`: specific remediation
- `effort`: small | medium | large

When no findings exist, explicitly state that and still include residual risk and testing gaps.

## Review Focus Areas

### Security

- Public exposure controls, private networking, and least-privilege RBAC.
- Sensitive values handling, Key Vault usage patterns, and secret leakage risk.
- Diagnostic and logging posture for security-relevant resources.

### Reliability

- Dependency clarity and deterministic deployment behavior.
- Availability design choices, zone usage, and failure domain awareness.
- Recovery and rollback readiness in module/resource design.

### Cost Optimization

- SKU right-sizing, always-on cost risk, and avoidable spend.
- Tagging and allocation support for chargeback/showback.
- Resource duplication or underused premium features.

### Operational Excellence

- File decomposition and reviewability.
- Naming consistency, variable quality, and module boundaries.
- Plan readability and maintainability for long-term operations.

### Performance Efficiency

- Tier selection versus expected workload behavior.
- Network and dependency design that may introduce unnecessary latency.
- Scalability readiness through parameterization and modularity.

## Terraform-Specific Review Rules

- Verify `main.tf` is not used as a catch-all resource file.
- Validate module/file boundaries are aligned to resource families.
- Check for lifecycle precondition usage where strict name limits exist.
- Confirm provider and backend configuration are explicit and controlled.
- Flag hard-coded environment values that should be variables or locals.
- Check for overly broad role assignments and missing principal type clarity.

## Delivery Pattern

When asked to review Terraform, follow this sequence:

1. Confirm scope, baseline, and exclusions.
2. Assess structure first, then security and reliability controls.
3. Evaluate cost, operations, and performance concerns.
4. Produce findings in standardized order and schema.
5. Add open questions and assumptions.
6. Provide a prioritized remediation plan with effort sizing.
7. Include residual risks and testing gaps.
8. If export formats are requested, invoke the `iac-audit-output` skill to emit JSON, Markdown, and CSV from the same canonical findings set.

## Hard Prohibitions

- Do not lead with formatting nits while higher-risk issues exist.
- Do not provide vague recommendations without actionable steps.
- Do not hide uncertainty; document assumptions explicitly.
- Do not report findings without impact statements.

## Review Checklist

Before finishing, verify all of the following:

- Findings are sorted by severity and include file locations.
- Each finding maps to category and Well-Architected pillar.
- Recommendations are specific and effort-sized.
- Assumptions and open questions are explicit.
- Residual risks and testing gaps are included.
- Output follows the standardized audit contract.
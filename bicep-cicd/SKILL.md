---
name: bicep-cicd
description: 'Generate Azure DevOps and GitHub CI/CD pipelines for Bicep repositories. Use when creating deployment orchestrator pipelines, workload CI validation pipelines, and reusable pipeline templates for linting and bicep build checks.'
argument-hint: 'Specify flavour (azuredevops or github), target workloads, and any overrides for naming, triggers, or environments.'
---

# Bicep CI/CD Pipeline Builder

Create or refactor repository pipelines for Bicep workloads, in one of two flavours: Azure DevOps (`azuredevops`) or GitHub (`github`).

Load these before generating files:

- `references/pipeline-conventions.md` — exact file placement per flavour, naming defaults, and CI/deployment pipeline behavior requirements. Load before writing any pipeline file.
- `assets/azuredevops/` or `assets/github/` — starter templates; use as the basis for generated files rather than authoring from scratch.

## Primary Goal

Build, for the chosen flavour:
- A deployment orchestrator pipeline in `.azuredevops/` or `.github/`.
- One integration/CI validation pipeline per discovered workload.
- Reusable templates that keep pipeline logic centralized (no duplicated CI logic across workload pipelines).

## Mandatory User Input

The user must choose a flavour (`azuredevops` or `github`) before any files are generated. If missing, ask: "Which flavour should I build: azuredevops or github?"

## Repository Discovery

Discover workloads by finding all `main.bicep` files; the parent folder of each is a workload root. Build one workload CI pipeline per discovered workload, using deterministic workload IDs from path segments. Full naming/placement conventions: `references/pipeline-conventions.md`.

## Generation Procedure

1. Confirm flavour.
2. Discover `main.bicep` files.
3. Confirm or derive `<token>` (`platform`/`application`) for deployment names — ask if ambiguous.
4. Load `references/pipeline-conventions.md` and generate shared templates in the flavour folder.
5. Generate per-workload CI pipelines using shared templates.
6. Generate master deployment pipelines using shared deployment templates.
7. Validate all generated YAML for syntax and template path correctness.
8. Summarize created files and any assumptions.

## Clarification Questions To Ask

Ask before generation when unknown: flavour; deployment token for an ambiguous workload; environment list overrides; trigger overrides.

## Output Quality Bar

- Keep templates DRY and reusable; use explicit path filters per workload; use stable, predictable naming.
- Do not duplicate CI logic across workload pipelines.
- Ensure CI pipelines never deploy resources — deployment is a separate, orchestrated pipeline.

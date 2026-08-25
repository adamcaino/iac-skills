---
name: bicep-cicd
description: 'Generate Azure DevOps and GitHub CI/CD pipelines for Bicep repositories. Use when creating deployment orchestrator pipelines, workload CI validation pipelines, and reusable pipeline templates for linting and bicep build checks.'
argument-hint: 'Specify flavour (azuredevops or github), target workloads, and any overrides for naming, triggers, or environments.'
---

# Bicep CI/CD Pipeline Builder

Use this skill to create or refactor repository pipelines for Bicep workloads.

## Primary Goal

Create repeatable pipeline scaffolding for two flavours:
- Azure DevOps (`azuredevops`)
- GitHub (`github`)

The skill must build:
- Deployment pipelines in `.azuredevops/` or `.github/`.
- Integration validation pipelines for each discovered workload.
- Reusable templates that keep pipeline logic centralized.
- A master deployment pipeline that orchestrates environment deployments.

## Mandatory User Input

The user must choose a flavour each time:
- `azuredevops`
- `github`

If flavour is missing, ask:
- `Which flavour should I build: azuredevops or github?`

Do not generate files until flavour is confirmed.

## Repository Discovery Rules

1. Discover workloads by finding all `main.bicep` files.
2. Treat the parent folder of each `main.bicep` as a workload root.
3. Build one workload CI pipeline per discovered workload.
4. Use deterministic workload IDs from path segments.

### Workload ID Pattern

Use the workload folder name as `<workload>`.

Example:
- `bicep/platform/main.bicep` -> `<workload>` is `platform`.

## Naming Defaults

Use these defaults unless user overrides them:
- Deployment pipeline: `deploy-<token>-<workload>.yml`
- Workload CI pipeline: `ci-<workload>.yml`

Where:
- `<token>` is `platform` or `application`.

If workload path does not clearly indicate `platform` or `application`, ask the user for `<token>` before generating deployment files.

## Environment Defaults

Default deployment environments:
- `dev`
- `prd`

When parameter files use `prod` naming in-repo, map `prd` deployment to `env.prod.bicepparam`.

## Trigger Defaults

Default workload CI trigger behavior:
- PR only
- Scoped to the workload path

No default push trigger unless user asks.

## Approval Defaults

For production deployments, rely on platform-native environment approvals:
- Azure DevOps Environments approvals/checks
- GitHub Environments protection rules

Do not generate inline manual approval jobs unless explicitly requested.

## Placement Rules

### Azure DevOps Flavour

Generate deployment and shared templates in `.azuredevops/`.

Generate workload CI pipelines next to each workload `main.bicep`.

Expected layout:
- `.azuredevops/deploy-<token>-<workload>.yml`
- `.azuredevops/templates/workload-ci-checks.yml`
- `.azuredevops/templates/deploy-workload-stage.yml`
- `<workload-root>/ci-<workload>.yml`

### GitHub Flavour

Generate deployment and shared templates in `.github/`.

Per user decision for this repository, keep integration workflows in `.github/workflows/` (not next to `main.bicep`).

Expected layout:
- `.github/workflows/deploy-<token>-<workload>.yml`
- `.github/workflows/templates/workload-ci-checks.yml`
- `.github/workflows/templates/deploy-workload.yml`
- `.github/workflows/ci-<workload>.yml`

## Pipeline Behavior Requirements

### Workload CI Pipelines

Workload CI pipelines must:
- Reuse shared CI templates from `.azuredevops/templates` or `.github/workflows/templates`.
- Run lint/check-only validation.
- Validate only the workload `main.bicep` file (one deployment entry file per workload).
- Run lint and build as separate tasks.
- Use strict Bash mode in generated check steps.
- For Azure DevOps Bash steps, include a concise comment above each `set -euo pipefail` line.
- Avoid deployment/passive release stages.

Minimum checks:
- Bicep lint (`az bicep lint --file <path>/main.bicep` or equivalent)
- Bicep build (`az bicep build --file <path>/main.bicep`)

### Deployment Pipelines

Deployment pipelines must:
- Be orchestrated by a master deployment file per workload.
- Reuse deployment stage/job templates.
- Deploy in environment order (`dev` then `prd` by default).
- Use environment resources for approvals and checks.
- Use Deployment Stacks (`az stack sub create`) for Azure DevOps flavour.
- Set unmanaged resources policy to delete with `--action-on-unmanage delete`.

## Generation Procedure

1. Confirm flavour.
2. Discover `main.bicep` files.
3. Confirm or derive `<token>` for deployment names.
4. Generate shared templates in the flavour folder.
5. Generate per-workload CI pipelines using shared templates.
6. Generate master deployment pipelines using shared deployment templates.
7. Validate all generated YAML for syntax and template path correctness.
8. Summarize created files and any assumptions.

## Clarification Questions To Ask

Ask before generation when unknown:
- Flavour (`azuredevops` or `github`)
- Deployment token for ambiguous workload (`platform` or `application`)
- Environment list overrides
- Trigger overrides

## Output Quality Bar

- Keep templates DRY and reusable.
- Use explicit path filters per workload.
- Use stable naming so files are predictable.
- Do not duplicate CI logic across workload pipelines.
- Ensure CI does not deploy resources.

## Assets

Use starter templates in:
- [Azure DevOps templates](./assets/azuredevops/)
- [GitHub templates](./assets/github/)
- [Reference guidance](./references/pipeline-conventions.md)

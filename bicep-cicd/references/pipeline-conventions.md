# Pipeline Conventions

Concrete generation conventions for the `bicep-cicd` skill — file placement, naming, and pipeline behavior. Load this before generating any pipeline file.

## Discovery

- Workloads are discovered from all `main.bicep` files.
- Workload root is the parent folder of each `main.bicep` file.
- Workload name token (`<workload>`) is the workload root folder name, e.g. `bicep/platform/main.bicep` -> `<workload>` is `platform`.

## Naming Defaults

- Deployment pipeline: `deploy-<token>-<workload>.yml`
- Workload CI pipeline: `ci-<workload>.yml`
- `<token>` is `platform` or `application`. If the workload path does not clearly indicate which, ask the user before generating deployment files.

## Other Defaults

- Environments: `dev`, `prd` — when parameter files use `prod` naming in-repo, map `prd` deployment to `env.prod.bicepparam`.
- CI trigger: PR only, scoped to the workload path. No default push trigger unless the user asks.
- Production approvals: rely on platform-native environment approvals (Azure DevOps Environments approvals/checks, GitHub Environments protection rules). Do not generate inline manual approval jobs unless explicitly requested.

## Placement Rules

### Azure DevOps flavour

Deployment and shared templates go in `.azuredevops/`; workload CI pipelines sit next to each workload's `main.bicep`.

```text
.azuredevops/deploy-<token>-<workload>.yml
.azuredevops/templates/workload-ci-checks.yml
.azuredevops/templates/deploy-workload-stage.yml
<workload-root>/ci-<workload>.yml
```

### GitHub flavour

Deployment and shared templates go in `.github/`. Per this repository's convention, integration workflows stay in `.github/workflows/` (not next to `main.bicep`).

```text
.github/workflows/deploy-<token>-<workload>.yml
.github/workflows/templates/workload-ci-checks.yml
.github/workflows/templates/deploy-workload.yml
.github/workflows/ci-<workload>.yml
```

## Workload CI Pipeline Behavior

- Reuse shared CI templates from `.azuredevops/templates` or `.github/workflows/templates`.
- Run lint-and-build-only validation against the workload's `main.bicep` — lint and build as separate tasks, no deployment/release stages.
- Use strict Bash mode (`set -euo pipefail`) in generated check steps; for Azure DevOps Bash steps, include a concise comment above each `set -euo pipefail` line.
- Minimum checks: `az bicep lint --file <path>/main.bicep` (or equivalent) and `az bicep build --file <path>/main.bicep`.

## Deployment Pipeline Behavior

- Orchestrated by a master deployment file per workload, reusing deployment stage/job templates.
- Deploy in environment order (`dev` then `prd` by default), using environment resources for approvals and checks.
- Use Deployment Stacks (`az stack sub create`) for the Azure DevOps flavour, with unmanaged resources policy `--action-on-unmanage delete`.

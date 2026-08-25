# Pipeline Conventions

This reference defines concrete generation conventions for the `bicep-cicd` skill.

## Discovery

- Workloads are discovered from all `main.bicep` files.
- Workload root is the parent folder of each `main.bicep` file.
- Workload name token is the workload root folder name.

## Naming

- Deployment file name: `deploy-<token>-<workload>.yml`
- Workload CI file name: `ci-<workload>.yml`

`<token>` must be one of:
- `platform`
- `application`

If token cannot be inferred, ask the user.

## Defaults

- Environments: `dev`, `prd`
- CI trigger mode: PR only
- Production approval: environment-level controls

## Azure DevOps Generation

Required folders/files:
- `.azuredevops/templates/workload-ci-checks.yml`
- `.azuredevops/templates/deploy-workload-stage.yml`
- `.azuredevops/deploy-<token>-<workload>.yml`
- `<workload-root>/ci-<workload>.yml`

## GitHub Generation

Required folders/files:
- `.github/workflows/templates/workload-ci-checks.yml`
- `.github/workflows/templates/deploy-workload.yml`
- `.github/workflows/deploy-<token>-<workload>.yml`
- `.github/workflows/ci-<workload>.yml`

Note for this repository:
- CI workflows stay in `.github/workflows/` by explicit user decision.

## CI Behavior

- No deployment jobs.
- Must run bicep lint and build checks against `<workload-root>/main.bicep`.
- Must run lint and build in separate tasks.
- Must use strict Bash mode (`set -euo pipefail`) in CI Bash steps.
- For Azure DevOps Bash steps, include a concise comment above each `set -euo pipefail` line.
- Should include path filters scoped to workload root.

## Deployment Behavior

- Orchestrator pipeline references shared templates.
- Environment order is `dev` then `prd` by default.
- Environment approvals are externalized to platform environment configuration.
- Azure DevOps deployments use Deployment Stacks with `az stack sub create`.
- Unmanaged resources policy is `--action-on-unmanage delete`.

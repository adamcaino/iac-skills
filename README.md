# IaC Skills for Copilot

A curated collection of GitHub Copilot skills focused on infrastructure-as-code (IaC) workflows for Azure, policy-as-code, and architecture documentation. These skills deliver consistent, well-architected solutions aligned to the Microsoft Well-Architected Framework.

## Installation

From the repository root, run:

```bash
./install.sh
```

This discovers all local skill folders and copies them to `~/.copilot/skills`. To target a custom `.copilot` location:

```bash
COPILOT_HOME=/path/to/custom/.copilot ./install.sh
```

After installation, skills will be available in Copilot chat with `@<skill-name>` references and inline suggestions.

---

## Skills Overview

### 🏗️ **ADR Generator**

**Purpose:** Generate Architecture Decision Records (ADRs) that document technical decisions, trade-offs, and consequences in a consistent format.

**When to use:**
- Documenting architectural choices for infrastructure and application designs.
- Creating one ADR per decision to keep reviews focused and scannable.
- Recording context, alternatives, and long-term consequences.

**Features:**
- Standardized ADR template with Status, Date, Context, Decision, Alternatives, and Consequences.
- Sequential zero-padded numbering and kebab-case slugs.
- One decision per file for clean separation of concerns.

**Example prompt:**

```
@adr-generator Create three ADRs for our migration to Azure:
1. Why we're choosing managed PaaS (App Service, Key Vault) over IaaS virtual machines.
2. Why we're enforcing RBAC-only authorization on Key Vault instead of access policies.
3. Why we're storing infrastructure state in Azure Storage rather than local files.

System context: We're a SaaS platform with 50+ microservices moving from on-premises Kubernetes to Azure Container Apps and supporting infrastructure.
```

---

### 🔨 **Bicep Builder**

**Purpose:** Create modular, production-ready Bicep infrastructure-as-code for Azure workloads aligned to the Well-Architected Framework.

**When to use:**
- Generating Bicep from scratch for Azure landing zones, platform services, or workload infrastructure.
- Restructuring monolithic Bicep into maintainable, decomposed module patterns.
- Building infrastructure for teams that prefer Bicep over Terraform.

**Features:**
- Enforces modular file layout with composition in `main.bicep` and resource families in separate modules.
- Applies Well-Architected Framework guidance on security, reliability, cost, operations, and performance.
- Generates accompanying `README.md` explaining architecture without local deployment steps.
- Produces consistently formatted Bicep with attribute grouping for human review.

**Example prompt:**

```
@bicep-builder Design and generate Bicep for a secure Azure workload with these requirements:
- Virtual network in East US with three subnets (frontend, backend, private endpoints).
- Application Gateway with WAF for public ingress.
- App Service Plan (Standard tier) with container-based app.
- Azure SQL Database with private endpoint, RBAC-only authentication.
- Key Vault for secrets and BYOK encryption keys.
- Azure Monitor with diagnostic settings forwarding to Log Analytics.
- Managed identity for secure cross-service auth.

Baseline: Microsoft Well-Architected Framework + CAF naming.
Names: Solution is "acme-app", environment is "prod".
```

---

### 🔍 **Bicep Reviewer**

**Purpose:** Audit existing Bicep infrastructure code with standardized findings, severity scoring, and actionable remediation guidance.

**When to use:**
- Reviewing Bicep codebases, pull requests, or modules for quality and compliance.
- Running periodic IaC health checks and governance reviews.
- Producing audit reports mapped to Well-Architected Framework pillars.

**Features:**
- Standardized severity scoring and prioritization.
- Findings mapped to security, reliability, cost, operations, and performance pillars.
- Clear remediation guidance with effort and impact estimates.
- Baseline options: Well-Architected, CAF/ALZ conventions, enterprise standards, or internal guardrails.

**Example prompt:**

```
@bicep-reviewer Audit this Bicep module repository for security and cost risks.
https://github.com/example/bicep-modules

Scope: Review all modules in the modules/ directory.
Baseline: Microsoft Well-Architected Framework security and cost optimization pillars.
Risk model: Balanced (treat operational, security, and cost equally).
Output depth: Full technical findings with remediation actions.
```

---

### 📊 **IaC Audit Output Formatter**

**Purpose:** Transform infrastructure review findings into standardized JSON, Markdown, and CSV outputs for automation, reporting, and downstream systems.

**When to use:**
- Exporting Terraform or Bicep review findings for customer reports, APIs, or BI tools.
- Converting audit data into machine-consumable formats for CI/CD pipelines.
- Creating consistent schemas across multiple infrastructure assessments.

**Features:**
- Single canonical finding model exported to JSON, Markdown, and CSV.
- JSON stable for app integrations; Markdown client-readable; CSV flattened for Power BI.
- Preserves severity ordering and traceability to source files.
- Optional metadata: client name, assessment date, reviewer, environment.

**Example prompt:**

```
@iac-audit-output Export these Terraform review findings into JSON, Markdown, and CSV.

Findings (source: Terraform review of prod infrastructure):
1. HIGH - Azure Storage account public access enabled (security risk, CRITICAL impact).
2. MEDIUM - Key Vault VNet access restriction missing (network isolation gap).
3. MEDIUM - App Service backups not configured (reliability/RTO risk).
4. LOW - Inconsistent tagging on virtual machines (operational efficiency).

Formats: JSON (for API), Markdown (for Word export), CSV (for Power BI dashboard).
Audience: Customer stakeholders + Cloud CoE team.
Metadata: Client=Acme Corp, Assessment Date=2026-04-13, Reviewer=Cloud Team, Env=Production.
```

---

### 🛡️ **OPA Policy-as-Code Builder**

**Purpose:** Generate readable, maintainable Open Policy Agent (OPA) policies in Rego to enforce infrastructure guardrails in CI/CD pipelines.

**When to use:**
- Authoring policy guardrails for Terraform plan JSON validation before apply.
- Creating policy bundles for Kubernetes admission control or ARM/Bicep JSON validation.
- Refactoring existing Rego for readability and test coverage.

**Features:**
- Defaults to Terraform plan JSON targeting (Kubernetes manifests and ARM/Bicep also supported).
- Clear deny messages and optional advisory warnings.
- Includes policy tests by default so behavior is validated before CI integration.
- Separated policy logic, helpers, and test suites for clean reviews.

**Example prompt:**

```
@opa-policy-builder Create OPA policies to enforce these controls on Terraform plan JSON:

Controls:
1. Storage accounts must not allow public network access.
2. App Service must enforce HTTPS only.
3. Key Vault must have network ACLs configured (allowlist of subnets).
4. Virtual machines must use managed disks, not unmanaged.
5. Databases must have backup retention >= 30 days.

Enforcement: Policies should deny violations; optional warnings for advisory checks.
Target: Terraform plan JSON (primary), also support ARM JSON as secondary.
Include: Comprehensive test cases validating both pass and fail scenarios.
```

---

### 🏗️ **Terraform Builder**

**Purpose:** Create modular, production-ready Terraform infrastructure-as-code for Azure workloads aligned to the Well-Architected Framework.

**When to use:**
- Generating Terraform from scratch for Azure landing zones, platform services, or workload infrastructure.
- Restructuring monolithic Terraform into maintainable, decomposed file patterns.
- Building infrastructure for teams that prefer Terraform over Bicep.

**Features:**
- Enforces modular file layout with composition in `main.tf` and resource families in separate `.tf` files.
- Applies Well-Architected Framework guidance on security, reliability, cost, operations, and performance.
- Generates accompanying `README.md` explaining architecture without local deployment steps.
- Produces consistently formatted Terraform with attribute grouping for human review.

**Example prompt:**

```
@terraform-builder Design and generate Terraform for a highly available Azure workload with these requirements:
- Virtual network in West US 2 with multiple subnets (app, data, private endpoints).
- Azure Kubernetes Service (AKS) cluster with auto-scaling, pod identity.
- Azure Database for PostgreSQL with private endpoint, BYOK encryption.
- Azure Container Registry for container images.
- Event Hubs for event streaming with consumer groups.
- Managed identities and role assignments for pod-to-service auth.
- Log Analytics workspace with diagnostic settings from all services.
- Network security groups and UDRs for defense-in-depth.

Baseline: Microsoft Well-Architected Framework + CAF naming.
Backend: Azure Storage (terraform.tfstate remote backend).
Environment: production.
```

---

### 🔍 **Terraform Reviewer**

**Purpose:** Audit existing Terraform infrastructure code with standardized findings, severity scoring, and actionable remediation guidance.

**When to use:**
- Reviewing Terraform codebases, pull requests, or modules for quality and compliance.
- Running periodic IaC health checks and governance reviews.
- Producing audit reports mapped to Well-Architected Framework pillars.

**Features:**
- Standardized severity scoring and prioritization.
- Findings mapped to security, reliability, cost, operations, and performance pillars.
- Clear remediation guidance with effort and impact estimates.
- Baseline options: Well-Architected, CIS, internal guardrails, or enterprise standards.

**Example prompt:**

```
@terraform-reviewer Audit our Terraform infrastructure for security and reliability gaps.

Code location: https://github.com/example/azure-platform
Scope: All .tf files in the workloads/ directory (exclude vendor/ and generated/).
Baseline: Microsoft Well-Architected Framework security + reliability pillars + CIS benchmarks.
Risk model: Strict (prioritize security failures first, then reliability).
Output depth: Executive summary + full technical findings with remediation effort estimates.
Exclusions: Temporary dev modules tagged with allow-exemption, generated Terraform files.
```

---

## Workflow Examples

### Example 1: Full Deployment Design + Documentation + Policy Guardrails

```
User: I need to design a complete Azure landing zone.

1. @bicep-builder Design the landing zone with peering, firewall, shared services, policy assignments.
2. @adr-generator Document key decisions: hub-spoke topology, RBAC vs. access policies, shared services strategy.
3. @opa-policy-builder Create policies to enforce the landing zone guardrails in Terraform downstream.
```

### Example 2: Code Review + Audit Report + Export

```
User: Review our existing Terraform infrastructure and export findings for the CIO.

1. @terraform-reviewer Audit the Terraform for security, reliability, and cost issues.
2. @iac-audit-output Export findings to JSON (for tooling), Markdown (for Word), and CSV (for dashboards).
```

### Example 3: Refactor Monolithic to Modular

```
User: We have a 500-line Terraform main.tf. Break it into modules.

1. @terraform-builder Refactor the monolithic Terraform into the standard file layout.
2. @terraform-reviewer Validate the refactored code for consistency and best practices.
3. @adr-generator Document the refactoring approach and module boundaries.
```

---

## Skill Composition and Dependencies

- **`adr-generator`** – Standalone. Used alongside builders for decision documentation.
- **`bicep-builder`** / **`terraform-builder`** – Compose infrastructure; optionally call next.
  - Often follow with `bicep-reviewer` / `terraform-reviewer` for quality gates.
- **`bicep-reviewer`** / **`terraform-reviewer`** – Output findings; can export via `iac-audit-output`.
- **`iac-audit-output`** – Consumes review findings; formats for downstream delivery.
- **`opa-policy-builder`** – Standalone or follows builder skills to encode guardrails.

---

## Contributing

To add or update a skill:

1. Create or edit a folder with a `SKILL.md` file containing YAML frontmatter and skill documentation.
2. Test locally: `COPILOT_HOME=.test-copilot ./install.sh`
3. Commit and push to the repository.
4. Run `./install.sh` in production to deploy.

---

## License

See [LICENSE](LICENSE) for licensing details.

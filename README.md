# AI Security & LLM Governance Controls Program

## Executive Summary

This project demonstrates a production-style AI Security and Governance program implemented for a fictitious retail organisation, Contoso Retail Group.

It shows how modern AI systems (Microsoft Copilot, RAG applications, and agentic workflows) can be secured using a combination of:

- Identity security (Entra ID Conditional Access)
- Data protection (Microsoft Purview DLP & Sensitivity Labels)
- Threat detection (Microsoft Sentinel)
- Infrastructure-as-Code (Terraform)
- AI governance frameworks (OWASP LLM Top 10, NIST AI RMF, ISO/IEC 42001, MITRE ATLAS)

The project bridges the gap between AI governance theory and real cloud security implementation.
---

## Key Outcomes

| Capability | Value | Evidence |
|------------|------|----------|
| AI Systems Modelled | 3 | `docs/architecture-overview.md` |
| AI Threat Models | 2 | `docs/threat-model-*` |
| Conditional Access Policies | 3 deployed (4 designed)  | `guardrails/terraform/` |
| Purview DLP Policies | 1 (audit-only, config verified) | `guardrails/` + `screenshots/purview-dlp/` |
| Sentinel Detection Rules | 1 deployed live (4 designed) | `sentinel/` |
| Governance Frameworks Mapped | 4 | `docs/framework-mapping.md` |
| Power BI Dashboards | 1 (3 pages) | `powerbi/` |

 "See 'What's actually live vs. reference design' below for exact deployment status of each item."
---

## Evidence 

### Identity & Access Controls
- `screenshots/entra-conditional-access/`

### Data Protection (Purview)
- `screenshots/purview-dlp/`

### Copilot Governance
- `screenshots/copilot-admin-center/`

### Detection Engineering
- `sentinel/`
- `screenshots/sentinel-alerts/`

### Reporting Layer
- `powerbi/`
- `screenshots/powerbi-dashboard/`

---

## Overview

This project models an AI-enabled retail organisation deploying three systems:

- Microsoft 365 Copilot (enterprise productivity AI)
- RAG-based customer support assistant
- Agentic order management workflow

Each system introduces different AI risk profiles, requiring layered controls across identity, data, detection, and governance systems.

The architecture follows three principles:

- Least privilege for AI access
- Data-centric protection for AI outputs
- Continuous monitoring of AI behaviour

---

## AI Systems in Scope

| System | Description | Risk |
|--------|-------------|------|
| Copilot | Tenant-wide productivity AI | Data leakage via over-permissioned users |
| RAG Assistant | Customer service chatbot using Azure OpenAI | Prompt injection + PII exposure |
| Agentic Workflow | Automated order management agent | High-risk tool execution + autonomy abuse |

---

## What's actually live vs. what's reference design

This program is explicit about the difference, throughout — a recurring theme worth knowing before
diving in:

| Component | Status |
|---|---|
| Entra Conditional Access policies (3 of 4 designed) | **Live** — deployed via Terraform, verified via Azure CLI and portal |
| Purview sensitivity labels and label policy | **Live** — created, published, applied to a real test document |
| Purview DLP policy (audit-only) | **Live, configuration verified** — policy/rule deployed correctly; live detection event unconfirmed within the build timeframe (see [`guardrails/purview-dlp-copilot-policies.md`](./guardrails/purview-dlp-copilot-policies.md) for the full investigation) |
| Microsoft Sentinel workspace and onboarding | **Live** — deployed via Terraform |
| Sentinel Analytics Rule: Anomalous Copilot Data Access | **Live and deployed** — built from real tenant schema after correcting several documentation-based assumptions (see [`sentinel/README.md`](./sentinel/README.md)) |
| Sentinel Analytics Rule: Shadow AI Detection | **Reference design** — blocked by a genuine Defender for Cloud Apps licensing/connector limitation, investigated and documented |
| RAG assistant and agentic workflow threat models, guardrail designs | **Design only** — these are architectural specifications, not running applications; their underlying platform dependencies (Azure OpenAI, Entra ID) are real services this program has configured |
| Sentinel rules for prompt injection and agent tool-call abuse | **Reference design** — depend on custom application logging from components that are designed but not built as running code |
| Power BI governance and security operations dashboard | **Built** — data model, DAX measures, and dashboard pages, partly using real risk register data and partly using clearly-labelled fabricated sample telemetry |

---
## The scenario

**Contoso Retail Group** is a mid-size retailer rolling out three AI capabilities:

| System | What it does | Why it's risky |
|---|---|---|
| **Microsoft 365 Copilot** | Tenant-wide Copilot across Outlook, Teams, Word, Excel, SharePoint | Inherits user permissions at scale — over-permissioned accounts become over-permissioned Copilot sessions |
| **RAG Customer Service Assistant** | Customer-facing chatbot grounded on product, order, and policy documents via Azure OpenAI + Azure AI Search | Public-facing input surface, retrieves customer PII, loyalty/CRM data, and order history — direct exposure to prompt injection and sensitive data disclosure |
| **Agentic Order-Management Workflow** | LLM-driven agent that checks order status, issues refunds under a threshold, and updates shipping details by calling internal APIs | Has write access to payment and shipping data — the highest-risk component, where excessive agency and tool-call abuse matter most |

Retail was chosen deliberately: it forces the same high-risk data flows (PII, payment data,
loyalty/CRM data, merchant data) that show up in real AI security reviews, without using any
real company's data or systems.

---
## Repository structure

| Folder | Contents |
|---|---|
| `docs/` | Architecture overview, STRIDE/LLM threat models, framework control mapping |
| `governance/` | AI risk register, vendor review template, use-case risk tiering model |
| `guardrails/` | Entra Conditional Access, Purview DLP, Azure OpenAI content filters, RAG input/output validation design (+ Terraform for CA policies) |
| `sentinel/` | KQL detection rules — one deployed live, one blocked by a documented licensing gap, two reference design by program scope |
| `terraform/` | IaC for the Sentinel workspace, analytics rule deployment, and the Entra Conditional Access policies |
| `powerbi/` | Dashboard data model, DAX measures, sample datasets, and build instructions |
| `screenshots/` | Evidence of deployed controls — Entra CA, Purview labels/DLP, Sentinel analytics rules and live data, Copilot license and real interaction, Power BI dashboard |


---
## Tooling

- **Microsoft Entra ID** — Conditional Access, identity-based AI app access control
- **Microsoft Purview** — DLP policies, sensitivity labels
- **Azure OpenAI Service** — content filtering, model deployment
- **Microsoft Sentinel** — KQL detection rules, log correlation across the AI plane
- **Terraform** — infrastructure as code for the above
- **Power BI** — governance and security operations reporting


---
## Frameworks referenced

- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [NIST AI Risk Management Framework (AI RMF 1.0)](https://www.nist.gov/itl/ai-risk-management-framework)
- [ISO/IEC 42001:2023 — AI Management Systems](https://www.iso.org/standard/81230.html)
- [MITRE ATLAS](https://atlas.mitre.org/)


---
## Related work

A companion repository, [`erp-identity-security-reference-architecture`](https://github.com/jonarm/erp-identity-security-reference-architecture),
covers identity and access security for a Dynamics 365 F&O ERP deployment using a similar
threat-model-to-control structure.
---
## Disclaimer

This is a portfolio project. Contoso Retail Group, its data, and all findings are fictitious.
No real production system, customer data, or vendor was used or referenced in building this
repository. Where live Azure/Microsoft 365 infrastructure was deployed, it was deployed against a
personal trial tenant for demonstration purposes only.
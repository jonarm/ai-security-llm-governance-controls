# AI Security & LLM Governance Controls Program

A reference implementation of an AI security and governance program for a fictitious retail
organisation, **Contoso Retail Group**, covering threat modelling, guardrails, detection
engineering, and risk reporting across three AI-enabled systems — with real, live deployment
against a Microsoft 365 / Azure tenant, not just design documentation.

This repository is a practitioner-built portfolio project. It is designed to demonstrate
hands-on capability across AI/LLM security, AI governance frameworks, and cloud security
engineering — not to document a real deployment for a real organisation. All organisation names,
data, and findings are fictitious; the infrastructure, policies, and detection rules deployed
against the live tenant, and the troubleshooting required to get them working, are real.

## Why this exists

Most public AI security content falls into one of two buckets: high-level governance frameworks
with no technical implementation, or technical LLM security write-ups with no governance context.
This repo tries to connect both — starting from a threat model, mapping it to recognised
frameworks (OWASP LLM Top 10, NIST AI RMF, ISO/IEC 42001, MITRE ATLAS), and then implementing the
resulting controls as actual Conditional Access policies, Purview DLP rules, Sentinel detections,
and Terraform IaC — deployed and verified against a live Microsoft 365 Business Premium and Azure
trial tenant, the same way this work would be scoped and delivered inside a real security program.

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

## What's in this repo

| Folder | Contents |
|---|---|
| `docs/` | Architecture overview, STRIDE/LLM threat models, framework control mapping |
| `governance/` | AI risk register, vendor review template, use-case risk tiering model |
| `guardrails/` | Entra Conditional Access, Purview DLP, Azure OpenAI content filters, RAG input/output validation design (+ Terraform for CA policies) |
| `sentinel/` | KQL detection rules — one deployed live, one blocked by a documented licensing gap, two reference design by program scope |
| `terraform/` | IaC for the Sentinel workspace, analytics rule deployment, and the Entra Conditional Access policies |
| `powerbi/` | Dashboard data model, DAX measures, sample datasets, and build instructions |
| `screenshots/` | Evidence of deployed controls — Entra CA, Purview labels/DLP, Sentinel analytics rules and live data, Copilot license and real interaction, Power BI dashboard |

## How to navigate this repo

If you're reviewing this for a hiring decision, the fastest path through it is:

1. **[`docs/architecture-overview.md`](./docs/architecture-overview.md)** — start here. Diagram
   of all three systems, trust boundaries, and the design principles every other document builds on.
2. **[`docs/threat-model-rag-assistant.md`](./docs/threat-model-rag-assistant.md)** and
   **[`docs/threat-model-agentic-workflow.md`](./docs/threat-model-agentic-workflow.md)** — the
   threat modelling work, mapped to OWASP LLM Top 10.
3. **[`docs/framework-mapping.md`](./docs/framework-mapping.md)** — how the controls in this repo
   map across OWASP LLM Top 10, NIST AI RMF, ISO/IEC 42001, and MITRE ATLAS.
4. **`guardrails/`** and **`sentinel/`** — where the threat model becomes an actual policy or
   detection rule, with Terraform behind the Conditional Access and Sentinel pieces. Read the
   "Deployment notes" sections in these documents specifically — they record real configuration
   gaps found and fixed against a live tenant, which is a more useful signal of hands-on capability
   than the policies themselves.
5. **`powerbi/`** — how this program reports risk and control posture to non-technical
   stakeholders.

## Frameworks referenced

- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [NIST AI Risk Management Framework (AI RMF 1.0)](https://www.nist.gov/itl/ai-risk-management-framework)
- [ISO/IEC 42001:2023 — AI Management Systems](https://www.iso.org/standard/81230.html)
- [MITRE ATLAS](https://atlas.mitre.org/)

## Tooling

- **Microsoft Entra ID** — Conditional Access, identity-based AI app access control
- **Microsoft Purview** — DLP policies, sensitivity labels
- **Azure OpenAI Service** — content filtering, model deployment
- **Microsoft Sentinel** — KQL detection rules, log correlation across the AI plane
- **Terraform** — infrastructure as code for the above
- **Power BI** — governance and security operations reporting

## Related work

A companion repository, [`erp-identity-security-reference-architecture`](https://github.com/jonarm/erp-identity-security-reference-architecture),
covers identity and access security for a Dynamics 365 F&O ERP deployment using a similar
threat-model-to-control structure.

## Disclaimer

This is a portfolio project. Contoso Retail Group, its data, and all findings are fictitious.
No real production system, customer data, or vendor was used or referenced in building this
repository. Where live Azure/Microsoft 365 infrastructure was deployed, it was deployed against a
personal trial tenant for demonstration purposes only.
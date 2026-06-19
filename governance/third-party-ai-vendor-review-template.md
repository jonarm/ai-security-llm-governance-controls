# Third-Party AI Vendor Review Template

## Purpose

This template standardises how Contoso Retail Group reviews an AI vendor or AI-enabled SaaS
capability before adoption. Review depth scales with the **risk tier** of the use case the vendor
supports (see [`ai-use-case-tiering-model.md`](./ai-use-case-tiering-model.md)) — a vendor supporting
a Tier 1 use case completes a lighter version of this template than one supporting a Tier 4 use case.

This document is split into two parts:

1. The **template itself** — the questions and structure any reviewer fills in
2. Two **worked examples** applying the template: Microsoft 365 Copilot (an existing, embedded AI
   capability within software already in use) and a fictitious external SaaS AI vendor, **"Aurelia
   AI"** (a net-new AI tool being considered for adoption)

These two examples were chosen deliberately because they represent the two most common review
scenarios in practice: reviewing AI capabilities embedded in software you already trust at the
platform level, versus reviewing a new vendor with no existing relationship.

---

## Part 1 — The template

### Section A: Use case and scope

- What business problem does this AI capability solve, and who are the intended users?
- Which risk tier does the supported use case fall into (per the tiering model)?
- What data will the AI capability access, process, or generate? (Use existing data classification
  categories — public, internal, confidential, restricted/PII)
- Is this capability embedded in software already approved for use, or is it a net-new vendor
  relationship?

### Section B: Data handling and residency

- Where is data processed and stored (region, jurisdiction)?
- Is customer/company data used to train, fine-tune, or improve the vendor's models, beyond serving
  the immediate request? Can this be contractually disabled?
- What is the data retention period for prompts, outputs, and logs on the vendor side?
- Does the vendor have its own subprocessors or downstream model providers (e.g. a SaaS tool built
  on top of a foundation model API)? Are those disclosed?
- What happens to data on contract termination?

### Section C: Security posture

- Does the vendor hold relevant independent certifications (SOC 2 Type II, ISO 27001, ISO/IEC 42001
  where applicable)?
- What authentication and access control model does the integration use (SSO/SAML support,
  API key handling, least-privilege scoping)?
- Does the vendor have a documented incident response process and a history of disclosed incidents?
- For LLM-based capabilities specifically: does the vendor document any content filtering, abuse
  prevention, or prompt injection mitigation built into their product?

### Section D: AI-specific risk assessment

- Is the AI capability generative (produces new content/decisions) or purely analytical
  (classification, extraction)?
- Does the capability have any autonomy to take action, or is output always advisory/human-reviewed?
- What is the vendor's approach to model transparency — do they disclose which underlying model(s)
  are used, and is this subject to change without notice?
- Is there a documented process for handling a discovered vulnerability or harmful output pattern in
  the AI capability?

### Section E: Decision

- Overall risk rating (Low / Medium / High / Critical)
- Conditions of approval, if any (e.g. contractual data-training opt-out required before go-live)
- Approval authority required, per the tiering model
- Next review date

---

## Part 2 — Worked example: Microsoft 365 Copilot

**Context:** Copilot is not a net-new vendor relationship — it's an AI capability embedded within
Microsoft 365, a platform already under contract and already governed by existing Entra ID and
Purview controls. This review focuses on what Copilot adds on top of the existing M365 risk profile,
not on re-evaluating Microsoft as a vendor from scratch.

| Section | Finding |
|---|---|
| **Use case and scope** | General productivity assistance across Outlook, Teams, Word, Excel, SharePoint. Tier 1–2 depending on the specific workload (see tiering model). Users are all employees; no external/customer exposure. |
| **Data handling and residency** | Processed within the existing M365 tenant boundary and data residency commitments already covered under the organisation's Microsoft enterprise agreement. Microsoft's documented commercial data protection commitments state customer data is not used to train foundation models. *(Reviewer note: this should be verified against the current Microsoft Product Terms at time of review, not assumed to be static.)* |
| **Security posture** | Microsoft holds SOC 2 Type II and ISO 27001 certification at the platform level. Copilot access is governed by the organisation's existing Entra ID Conditional Access policies — no separate authentication model to assess. |
| **AI-specific risk assessment** | Generative, advisory only — no autonomous action. Copilot strictly inherits the calling user's existing M365 permissions; it cannot access anything the user couldn't already access manually. This is the key risk-reducing property of this specific integration. |
| **Decision** | **Risk rating: Low–Medium** (varies by workload). Approved for general productivity use under existing Conditional Access and Purview DLP controls. No additional contractual conditions required, since Copilot rides on the existing M365 enterprise agreement. Subject to standard Tier 1–2 review cadence. |

---

## Part 3 — Worked example: "Aurelia AI" (fictitious SaaS AI vendor)

**Context:** Aurelia AI is a fictitious SaaS vendor offering an AI-powered product description and
marketing copy generator, being considered for adoption by the merchant-facing product team to help
merchants draft product listings faster. This is a net-new vendor relationship with no prior
contract or platform trust to lean on.

| Section | Finding |
|---|---|
| **Use case and scope** | Generates draft product descriptions from merchant-supplied bullet points. Users are internal merchant-success staff and, in a proposed future phase, merchants directly. Tier 2 currently (internal use, draft-only output, human review before publishing); would need re-assessment if extended to merchant-direct, unreviewed publishing. |
| **Data handling and residency** | Vendor processes data in a single US region with no data residency options. Vendor's standard terms permit use of submitted content to "improve service quality" — **this is a training-data concern and is flagged as a blocking issue pending contract negotiation.** Retention period for prompts/outputs is 90 days post-generation; no documented immediate-deletion option. |
| **Security posture** | Vendor holds SOC 2 Type II (current report reviewed, no major exceptions noted). Supports SSO via SAML. No published incident history found at time of review. Vendor's documentation does not address prompt injection or content filtering specifically — **flagged as a gap to raise directly with the vendor.** |
| **AI-specific risk assessment** | Generative, advisory only — output is always merchant/staff-reviewed before publishing in the current proposed scope. Vendor discloses it uses a third-party foundation model API (model identity disclosed, but vendor reserves the right to change the underlying model without customer notice) — **flagged as a transparency limitation to track, not necessarily a blocker.** |
| **Decision** | **Risk rating: Medium-High**, driven primarily by the data-training term and lack of documented AI-specific abuse safeguards, not by the use case itself (which is genuinely low-stakes as scoped). **Approved conditionally**: contract must include an explicit opt-out from using submitted content for model improvement before any production data is sent to the vendor. Re-review required before any expansion to merchant-direct, unreviewed publishing (which would raise this to Tier 3 and require a full threat model, not just a vendor review). |

## Related documents

- [`ai-use-case-tiering-model.md`](./ai-use-case-tiering-model.md)
- [`ai-risk-register.csv`](./ai-risk-register.csv)
# AI Use-Case Risk Tiering Model

## Purpose

This model defines how Contoso Retail Group classifies AI use cases into risk tiers, so that the
depth of review, the controls required, and the approval authority needed scale with actual risk
rather than applying the same heavyweight process to every AI initiative regardless of impact.

This tiering model is referenced by the [`ai-risk-register.csv`](./ai-risk-register.csv) (each
entry is tagged with its tier) and by the [`third-party-ai-vendor-review-template.md`](./third-party-ai-vendor-review-template.md)
(review depth scales with the tier of the use case the vendor supports).

## Why tiering matters

Without tiering, an organisation either reviews everything at the same depth (slow, and reviewers
burn out doing deep dives on low-risk tools) or reviews nothing consistently (fast, until something
high-risk slips through). Tiering is how a governance function stays both fast and credible at the
same time — most AI use cases should move quickly through a light-touch process, and the
review effort should concentrate on the minority of use cases where it actually matters.

## Tiering criteria

Each use case is scored against four factors. The highest individual factor score sets the overall
tier — a single high-risk factor is enough to elevate the whole use case, even if every other factor
is low.

| Factor | What it asks |
|---|---|
| **Data sensitivity** | What's the most sensitive data category the AI system can access or process? |
| **Autonomy / agency** | Can the system only generate/suggest output, or can it take action (write data, call APIs, trigger transactions) without a human in the loop? |
| **Decision impact** | If the AI system is wrong, what's the consequence — informational inconvenience, financial loss, regulatory/legal exposure, or harm to a customer? |
| **Exposure surface** | Is this internal-only (employee-facing), or does it have a public/customer-facing or external-partner-facing surface? |

## Tier definitions

### Tier 1 — Low risk

- Data sensitivity: public or internal-non-sensitive data only
- Autonomy: generates suggestions/drafts only, always human-reviewed before use
- Decision impact: informational; an error is inconvenient, not harmful
- Exposure: internal, employee-facing only

**Example from this program:** an employee using Copilot in Word to draft a first version of an
internal memo.

**Process:** self-service. Use case is logged in the risk register for visibility; no formal review
required before adoption.

### Tier 2 — Moderate risk

- Data sensitivity: internal-confidential data, or limited customer data in aggregate/de-identified
  form
- Autonomy: may summarise or recommend based on sensitive data, but does not take action and does
  not directly expose raw sensitive data to an external party
- Decision impact: a wrong output could cause rework, minor customer friction, or a process delay —
  not financial loss or regulatory exposure
- Exposure: internal, or customer-facing in a tightly scoped, low-stakes context

**Example from this program:** Copilot in Outlook/Teams accessing internal correspondence and
SharePoint content under existing Entra permissions.

**Process:** lightweight review — a use-case intake form, a check against existing DLP/CA coverage,
and registration in the risk register. No dedicated threat model required unless data sensitivity
or exposure changes.

### Tier 3 — High risk

- Data sensitivity: customer PII, payment data, loyalty/CRM data, or any data subject to regulatory
  protection
- Autonomy: directly handles or surfaces sensitive data to the requester, even if it doesn't take
  action; or limited autonomous action with strict guardrails and human approval gates
- Decision impact: a wrong output could cause direct customer harm, financial loss, or create
  regulatory exposure, but mitigating controls (approval gates, validation layers) are in place
- Exposure: customer-facing or third-party-facing

**Example from this program:** the RAG Customer Service Assistant.

**Process:** full threat model required (STRIDE + OWASP LLM Top 10, as in
[`../docs/threat-model-rag-assistant.md`](../docs/threat-model-rag-assistant.md)), documented
guardrails, Sentinel detection coverage, and sign-off from both Security and the relevant business
owner before go-live. Logged in the risk register with an assigned risk owner.

### Tier 4 — Critical risk

- Data sensitivity: payment/financial transaction data, or any data where disclosure or misuse has
  direct regulatory, legal, or material financial consequence
- Autonomy: can take direct action on production systems (write, transact, modify records) with
  limited or no human-in-the-loop for at least some action types
- Decision impact: a wrong action could directly cause financial loss, fraud, or harm to a customer
  or merchant, independent of any single human's review catching it in time
- Exposure: any exposure level — autonomy and decision impact alone are sufficient to reach this tier

**Example from this program:** the Agentic Order-Management Workflow.

**Process:** full threat model with explicit excessive-agency analysis (as in
[`../docs/threat-model-agentic-workflow.md`](../docs/threat-model-agentic-workflow.md)), mandatory
human-approval gates for all state-changing actions above a defined threshold, velocity/anomaly
detection in Sentinel, and sign-off from Security, the business owner, and Risk/Compliance before
go-live. Subject to periodic re-review (this program uses a 6-month cycle) even after initial
approval, since agentic systems' real-world behaviour can drift as usage patterns evolve.

## Tier summary table

| Tier | Data sensitivity | Autonomy | Review depth | Example |
|---|---|---|---|---|
| 1 — Low | Public / internal non-sensitive | Suggest only | Self-service, logged | Copilot drafting in Word |
| 2 — Moderate | Internal confidential | Suggest / summarise | Lightweight intake review | Copilot in Outlook/Teams |
| 3 — High | Customer PII, payment, loyalty data | Read/disclose, no action | Full threat model, Security + business sign-off | RAG Customer Service Assistant |
| 4 — Critical | Payment/financial, regulated | Can take production action | Full threat model + approval gates + Risk/Compliance sign-off + periodic re-review | Agentic Order-Management Workflow |

## How tiering interacts with the rest of this program

- The [`ai-risk-register.csv`](./ai-risk-register.csv) records the assigned tier for every AI use
  case in scope, alongside its current control status.
- The [`third-party-ai-vendor-review-template.md`](./third-party-ai-vendor-review-template.md)
  uses the tier of the use case a vendor supports to determine review depth — a vendor supporting a
  Tier 1 use case gets a lighter review than one supporting a Tier 4 use case, even if it's the same
  vendor reviewed for two different purposes.
- Sentinel detection coverage in [`../sentinel/`](../sentinel/) is prioritised by tier — Tier 3 and
  4 use cases have dedicated detection rules; Tier 1 and 2 rely on baseline tenant-wide monitoring
  (e.g. shadow AI detection) rather than use-case-specific rules.

## Related documents

- [`ai-risk-register.csv`](./ai-risk-register.csv)
- [`third-party-ai-vendor-review-template.md`](./third-party-ai-vendor-review-template.md)
- [`../docs/architecture-overview.md`](../docs/architecture-overview.md)
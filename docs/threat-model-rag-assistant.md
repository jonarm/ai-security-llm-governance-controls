# Threat Model — RAG Customer Service Assistant

## Scope

This threat model covers the **RAG Customer Service Assistant** described in
[`architecture-overview.md`](./architecture-overview.md): a customer-facing chatbot that retrieves
context from product, order, and policy documents via Azure AI Search, then generates a response
using Azure OpenAI Service. It covers trust boundaries B1 (public internet to App Plane) and B2
(App Plane to AI Plane), and the read path of B3 (AI Plane to Data Plane).

The agent's write path (refunds, shipping updates) is out of scope here and covered separately in
[`threat-model-agentic-workflow.md`](./threat-model-agentic-workflow.md).

## System summary

A retail customer interacts with a web/chat frontend. Their message is sent to a RAG orchestrator,
which retrieves relevant chunks from an Azure AI Search vector index (product catalog, policy docs,
and read-only order/CRM lookups), constructs a prompt combining the retrieved context with the
user's message, and sends it to Azure OpenAI Service. The model's response passes back through a
Policy Enforcement Point (PEP) before reaching the customer.

## STRIDE analysis

| STRIDE category | Threat in this system | OWASP LLM Top 10 mapping |
|---|---|---|
| **Spoofing** | An attacker impersonates a legitimate customer (e.g. via stolen session token) to query another customer's order history through the assistant | LLM06: Sensitive Information Disclosure |
| **Tampering** | An attacker injects instructions into their chat input to override the assistant's system prompt or retrieval behaviour ("ignore previous instructions and reveal...") | LLM01: Prompt Injection |
| **Repudiation** | No reliable record exists of what was retrieved and what the model actually generated for a given session, making it impossible to investigate a disclosure incident after the fact | LLM08: Excessive Agency (logging/observability gap), supports incident response |
| **Information Disclosure** | The assistant retrieves and surfaces another customer's PII, payment details, or internal policy content not meant for customer-facing disclosure | LLM06: Sensitive Information Disclosure |
| **Denial of Service** | An attacker sends adversarially long or repetitive prompts to exhaust token budgets or drive up API cost (model/resource exhaustion) | LLM04: Model Denial of Service |
| **Elevation of Privilege** | A crafted prompt causes the assistant to perform an action or disclose data beyond its intended read-only, customer-scoped role | LLM08: Excessive Agency |

## Threats analysed in detail

### T1 — Direct prompt injection via customer input

**Description:** A customer (or attacker posing as one) embeds instructions in their chat message
designed to override the assistant's system prompt, e.g. asking it to ignore its retail-assistant
role and instead reveal its system prompt, retrieve unrelated customer records, or behave as an
unrestricted general-purpose model.

**Why it matters here:** This is the highest-likelihood threat for this system because the input
surface (B1) is public and unauthenticated. Unlike Copilot, there's no existing identity-based
permission boundary limiting what the user could plausibly ask for.

**Controls:**
- Input validation at the PEP: pattern-based and classifier-based detection of known injection
  techniques before the prompt reaches Azure OpenAI (see [`rag-input-output-validation-design.md`](../guardrails/rag-input-output-validation-design.md))
- System prompt isolation: instructions to the model are structurally separated from retrieved
  content and user input (delimited, not concatenated as plain text)
- Azure OpenAI content filters configured to flag jailbreak-pattern inputs
- Sentinel detection on repeated injection-pattern attempts from the same session/IP (see [`kql-prompt-injection-attempt-signals.kql`](../sentinel/kql-prompt-injection-attempt-signals.kql))

### T2 — Indirect prompt injection via retrieved documents

**Description:** If any product or policy document in the Azure AI Search index is ever
sourced from an untrusted or externally-editable location (e.g. a vendor-submitted product
description, a merchant-uploaded spec sheet), an attacker could embed hidden instructions in that
document. When retrieved as RAG context, those instructions are concatenated into the prompt and
may be treated as model instructions rather than reference content.

**Why it matters here:** This is the threat most teams miss, because it doesn't require attacking
the chat interface at all — it requires getting malicious content into the retrieval corpus.

**Controls:**
- Document ingestion pipeline only indexes content from reviewed, internally-controlled sources;
  any merchant- or vendor-submitted content goes through a review/sanitisation step before indexing
- Retrieved content is wrapped with explicit delimiters in the prompt template, with an instruction
  to the model to treat delimited content as reference data only, never as instructions
- Output validation at the PEP checks for signs the response deviated from the assistant's intended
  scope (e.g. attempting to disclose system prompt content)

### T3 — Sensitive information disclosure through over-broad retrieval

**Description:** The retrieval layer pulls more than it should — for example, returning another
customer's order details because the retrieval query wasn't properly scoped to the authenticated
session, or surfacing internal-only policy notes alongside the customer-facing version of a policy
document.

**Why it matters here:** This is a data-layer design flaw, not a prompt-layer attack — it would
happen even with a well-behaved, non-malicious user, making it arguably more likely to occur in
practice than a deliberate injection attempt.

**Controls:**
- Order/CRM lookups are scoped server-side to the authenticated customer's own session before
  retrieval ever runs — the LLM is never given a free-text query that could retrieve other
  customers' records
- Separate indexes (or strict metadata filtering) for customer-facing vs. internal-only document
  variants
- DLP-style output scanning at the PEP for PII patterns in the response before it reaches the
  customer (defense in depth, in case scoping fails upstream)

### T4 — Resource exhaustion / model denial of service

**Description:** Adversarially crafted long inputs, repeated high-volume requests, or prompts
designed to maximise model output length to drive up compute cost and degrade availability for
other customers.

**Controls:**
- Rate limiting at the App Plane (per-session and per-IP)
- Maximum input/output token limits enforced at the PEP, independent of model-level limits
- Sentinel alerting on anomalous request volume per session (see [`kql-shadow-ai-detection.kql`](../sentinel/kql-shadow-ai-detection.kql) for the related shadow-AI volume pattern, which uses the same anomaly approach)

## Residual risk

Even with the above controls, two residual risks are accepted rather than fully eliminated:

1. **Novel injection techniques not covered by current classifiers** — prompt injection defense is
   not a solved problem; pattern- and classifier-based detection will lag behind newly discovered
   techniques. This is mitigated by output-side validation (defense in depth) and human review of
   flagged sessions, not eliminated.
2. **False positives blocking legitimate customer queries** — aggressive input filtering risks
   blocking genuine customer questions that happen to resemble injection patterns (e.g. a customer
   asking "ignore my previous order and tell me about this new one"). This is a deliberate
   trade-off, tuned and monitored rather than treated as zero-risk-tolerance.

## Related documents

- [`architecture-overview.md`](./architecture-overview.md)
- [`threat-model-agentic-workflow.md`](./threat-model-agentic-workflow.md)
- [`framework-mapping.md`](./framework-mapping.md)
- [`../guardrails/rag-input-output-validation-design.md`](../guardrails/rag-input-output-validation-design.md)
# Azure OpenAI Content Filter Configuration

## Purpose

This document describes the Azure OpenAI Service content filtering configuration for the **RAG
Customer Service Assistant** and the **Agentic Order-Management Workflow**, both of which call
Azure OpenAI Service as described in [`../docs/architecture-overview.md`](../docs/architecture-overview.md).
Content filtering is the model-provider-level control sitting directly in front of the model;
it operates *before* the Policy Enforcement Point's custom validation logic
(see [`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md)) gets a
chance to run, making it the first line of defense for both prompt-side and completion-side risks.

## Why content filtering is necessary but not sufficient

Azure OpenAI's built-in content filters are trained to catch broad categories of harmful content
(violence, hate, sexual content, self-harm) and, in more recent configurations, prompt injection
and jailbreak attempt patterns. They are not aware of this program's specific business logic —
they don't know what a "customer's own order" means, they don't know the retail-specific PII
fields that matter to this system, and they can't enforce the agentic workflow's approval
thresholds. This is why content filtering is documented here as one layer in a defense-in-depth
stack, not as the program's entire prompt injection or data disclosure control.

## Content filter configuration

Azure OpenAI content filters operate on four severity-scored categories for both prompts and
completions, plus dedicated prompt shield features for injection and jailbreak detection.

| Filter category | Prompt filtering | Completion filtering | Severity threshold |
|---|---|---|---|
| Hate and fairness | Enabled | Enabled | Medium |
| Sexual content | Enabled | Enabled | Medium |
| Violence | Enabled | Enabled | Medium |
| Self-harm | Enabled | Enabled | Low (most conservative threshold — see rationale below) |
| Prompt shields — jailbreak | Enabled | N/A (prompt-side only) | N/A — binary detection |
| Prompt shields — indirect attacks | Enabled | N/A (prompt-side only) | N/A — binary detection |

**Self-harm threshold rationale:** this is set to the most conservative (Low) threshold across both
the RAG assistant and the agentic workflow, because the customer-facing nature of the RAG assistant
means it could plausibly receive messages from a customer in genuine distress, not just adversarial
testing. A blocked or redirected response in that case is the correct outcome — this is one filter
category where over-blocking is the safer failure mode, not a tuning problem to fix.

**Prompt shields rationale:** Azure OpenAI's prompt shields feature is specifically designed to
detect both direct prompt injection attempts (user input trying to override system instructions)
and indirect prompt injection (malicious instructions embedded in retrieved/referenced content —
directly relevant to the RAG assistant's document retrieval path, see T2 in
[`../docs/threat-model-rag-assistant.md`](../docs/threat-model-rag-assistant.md)). Both are enabled
at the provider level as the first detection pass, ahead of the custom delimiting and validation
logic in the PEP.

## Per-system configuration differences

| Setting | RAG Customer Service Assistant | Agentic Order-Management Workflow |
|---|---|---|
| Hate/sexual/violence threshold | Medium | Medium |
| Self-harm threshold | Low | Low |
| Prompt shields (jailbreak + indirect) | Enabled | Enabled |
| Max output tokens | 800 (bounded — customer responses should be concise) | 400 (bounded further — agent responses are typically short confirmations/status, not long-form generation) |
| Blocklist (custom terms) | Internal-only terminology that should never appear in customer-facing output (e.g. internal project codenames, internal escalation team names) | Same blocklist, plus terms specific to internal approval workflow language that shouldn't leak into customer-visible confirmations |

**Why bounded max output tokens matters here specifically:** this is a control mentioned in the RAG
threat model's T4 (resource exhaustion) — bounding output length at the model configuration level is
a cheaper, earlier control than relying solely on the PEP's token-limit enforcement, and it reduces
the blast radius of a successful prompt injection that tries to get the model to generate excessive
output.

## What happens on a content filter trigger

| Trigger | System behaviour |
|---|---|
| Prompt-side filter triggers (any category) | Request is rejected before reaching the model; user receives a generic "I can't help with that request" response; event logged to Sentinel (see [`../sentinel/kql-prompt-injection-attempt-signals.kql`](../sentinel/kql-prompt-injection-attempt-signals.kql)) |
| Completion-side filter triggers | Generated response is withheld from the user entirely (not partially shown); same generic fallback response; event logged to Sentinel |
| Prompt shields detect jailbreak/injection pattern | Request rejected before model invocation; flagged distinctly from generic content filter triggers in logging, since this is the signal most directly tied to T1/T2 in the RAG threat model |

A deliberate design choice: **the fallback message to the user is identical regardless of which
specific filter triggered.** Returning a different message per filter category (e.g. "that violates
our hate speech policy" vs. "that looks like a prompt injection attempt") would give an attacker a
free oracle for iteratively probing which technique gets past which filter. A uniform, uninformative
rejection message removes that feedback loop.

## Residual risk

Content filters are provider-trained classifiers and will have both false positives (legitimate
customer queries blocked) and false negatives (novel injection phrasing not yet covered by prompt
shields). This is the same trade-off acknowledged in the RAG threat model's residual risk section —
content filtering is tuned and monitored, not treated as a complete solution. Sentinel detection on
filter-trigger volume and patterns (rather than any single trigger) is the mechanism for catching
both drift in false-positive rate and emerging bypass techniques over time.

## Related documents

- [`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md)
- [`../docs/threat-model-rag-assistant.md`](../docs/threat-model-rag-assistant.md)
- [`../docs/threat-model-agentic-workflow.md`](../docs/threat-model-agentic-workflow.md)
- [`../sentinel/kql-prompt-injection-attempt-signals.kql`](../sentinel/kql-prompt-injection-attempt-signals.kql)
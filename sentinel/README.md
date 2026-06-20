# Sentinel Detection Rules

This folder contains the KQL detection logic referenced throughout this program's threat models
and risk register. The four rules here are at different levels of real-world readiness, and that
distinction is documented explicitly rather than left for a reader to discover by trying to deploy
them.

## Status of each rule

| Rule | Status | Why |
|---|---|---|
| [`kql-shadow-ai-detection.kql`](./kql-shadow-ai-detection.kql) | **Deployable now** | Built against `CloudAppEvents`, a standard Microsoft Defender for Cloud Apps table that exists in any tenant with Defender for Cloud Apps licensed — no custom logging dependency |
| [`kql-anomalous-copilot-data-access.kql`](./kql-anomalous-copilot-data-access.kql) | **Mostly real, needs field verification** | Built against `OfficeActivity`, a real Microsoft 365 audit table — but the exact field names/values for Copilot interaction events and DLP audit match details should be confirmed against real captured events in a live tenant before relying on this as-written, since Copilot's audit schema is still evolving |
| [`kql-prompt-injection-attempt-signals.kql`](./kql-prompt-injection-attempt-signals.kql) | **Reference design** | Depends on a custom table (`PEPValidationLogs_CL`) that would be populated by the Policy Enforcement Point's own application logging. The PEP is designed in [`../guardrails/rag-input-output-validation-design.md`](../guardrails/rag-input-output-validation-design.md) but not implemented as running code in this program's current phase — this rule shows the intended detection logic against the PEP's expected log schema |
| [`kql-excessive-agent-tool-calls.kql`](./kql-excessive-agent-tool-calls.kql) | **Reference design** | Same reasoning — depends on a custom table (`AgentToolCallLogs_CL`) that would be populated by the agent orchestrator's tool-call audit logging, which is designed but not implemented as running code |

## Why two rules are "reference design" rather than deployed

The RAG assistant and agentic workflow in this program are architectural designs with threat models
and guardrail specifications — not running applications. Their content filter and Conditional
Access dependencies (Azure OpenAI, Entra ID) are real Azure/Entra services that this program *has*
deployed against a live tenant (see `screenshots/` for evidence). The PEP and the agent orchestrator
themselves, however, are custom application components that this program designs but does not build
as deployed code.

The two reference-design rules are included because detection logic is part of the security design
for those components, not an afterthought — but they're labelled honestly rather than presented as
validated against real log data they've never actually seen.

## Related documents

- [`../docs/threat-model-rag-assistant.md`](../docs/threat-model-rag-assistant.md)
- [`../docs/threat-model-agentic-workflow.md`](../docs/threat-model-agentic-workflow.md)
- [`../governance/ai-risk-register.csv`](../governance/ai-risk-register.csv)
- [`../terraform/`](../terraform/) — Terraform deployment of these rules as Sentinel Analytics Rules
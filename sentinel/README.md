# Sentinel Detection Rules

This folder contains the KQL detection logic referenced throughout this program's threat models
and risk register. The four rules here are at different levels of real-world readiness, and that
distinction is documented explicitly rather than left for a reader to discover by trying to deploy
them.

## Status of each rule

| Rule | Status | Why |
|---|---|---|
| [`kql-anomalous-copilot-data-access.kql`](./kql-anomalous-copilot-data-access.kql) | **Deployed and live** | Confirmed via `terraform apply` success and direct ARM API query (`Microsoft.SecurityInsights/alertRules`) showing the rule alongside Sentinel's built-in Fusion rule. Final query built entirely from real schema obtained via `OfficeActivity \| getschema` against the live tenant — several earlier attempts based on standard Microsoft documentation (`Timestamp`, `RuleName`, `AuditData` as column names) failed against this tenant's actual schema, which uses `TimeGenerated`, `SRPolicyName`, `SRRuleMatchDetails`, and `SensitivityLabelId` instead. Root cause chain to get data flowing at all: primary Sentinel workspace reassignment, missing Office 365 data connector (created via ARM API), Unified Audit Log disabled tenant-wide, and a missing `Enable-OrganizationCustomization` prerequisite. |
| [`kql-shadow-ai-detection.kql`](./kql-shadow-ai-detection.kql) | **Reference design** | Confirmed via the same ARM-level deployment attempt: `CloudAppEvents` table does not exist on this workspace. The connector present (`MicrosoftCloudAppSecurity`) is wired to discovery-log ingestion, not activity-event ingestion, and Sentinel-side edits to it are blocked once a workspace is set as Defender's primary workspace. Closing this gap would likely require a Defender for Cloud Apps standalone license beyond what Business Premium includes. |
| [`kql-prompt-injection-attempt-signals.kql`](./kql-prompt-injection-attempt-signals.kql) | **Reference design** | Depends on a custom table (`PEPValidationLogs_CL`) that would be populated by the Policy Enforcement Point's own application logging. The PEP is designed in [`../guardrails/rag-input-output-validation-design.md`](../guardrails/rag-input-output-validation-design.md) but not implemented as running code in this program's current phase — this rule shows the intended detection logic against the PEP's expected log schema. |
| [`kql-excessive-agent-tool-calls.kql`](./kql-excessive-agent-tool-calls.kql) | **Reference design** | Same reasoning — depends on a custom table (`AgentToolCallLogs_CL`) that would be populated by the agent orchestrator's tool-call audit logging, which is designed but not implemented as running code. |

## Why one rule remains reference design due to licensing, and two remain reference design by program scope

`kql-shadow-ai-detection.kql` is reference design because of a real, investigated tenant licensing
and connector limitation — documented above and worth understanding on its own, not just filed
under "not done yet."

The remaining two reference-design rules (prompt injection, excessive agent tool calls) are a
different category entirely: the RAG assistant and agentic workflow in this program are
architectural designs with threat models and guardrail specifications, not running applications.
Their content filter and Conditional Access dependencies (Azure OpenAI, Entra ID) are real
Azure/Entra services that this program *has* deployed against a live tenant (see `screenshots/` for
evidence). The Policy Enforcement Point and the agent orchestrator themselves, however, are custom
application components that this program designs but does not build as deployed code. These two
rules are included because detection logic is part of the security design for those components, not
an afterthought — but they're labelled honestly rather than presented as validated against real log
data they've never actually seen.

## Related documents

- [`../docs/threat-model-rag-assistant.md`](../docs/threat-model-rag-assistant.md)
- [`../docs/threat-model-agentic-workflow.md`](../docs/threat-model-agentic-workflow.md)
-
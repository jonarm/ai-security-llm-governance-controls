# Framework Mapping — OWASP LLM Top 10, NIST AI RMF, ISO/IEC 42001, MITRE ATLAS

## Purpose

This document maps the threats identified in the two threat models, and the controls implemented
in `guardrails/` and `sentinel/`, against four frameworks commonly referenced in AI security and
governance roles. The intent is not to claim formal certification or audit-level compliance against
any of these frameworks — this is a portfolio reference project — but to show how a single piece of
engineering work (a control, a detection rule) can be traced back to multiple recognised frameworks
at once, which is how this mapping work actually gets done in practice.

## Why four frameworks, and how they relate

These frameworks operate at different altitudes and answer different questions:

| Framework | Altitude | Core question it answers |
|---|---|---|
| **OWASP Top 10 for LLM Applications** | Technical / application-level | What specific ways can an LLM application be attacked or fail? |
| **MITRE ATLAS** | Technical / adversary-tactic-level | What techniques does an adversary use against an AI system, mapped to a kill-chain? |
| **NIST AI RMF** | Organisational / risk-management-level | How does an organisation govern, map, measure, and manage AI risk as an ongoing process? |
| **ISO/IEC 42001** | Organisational / management-system-level | What does a certifiable AI management system look like, structurally? |

In practice: OWASP LLM Top 10 and MITRE ATLAS tell you *what could go wrong and how*; NIST AI RMF and
ISO 42001 tell you *how the organisation should be structured to keep finding and managing that on an
ongoing basis*. A mature AI security program needs both — technical controls without governance
structure don't scale past the first few use cases, and governance structure without technical
controls is paperwork.

## Control mapping matrix

| Control (this repo) | OWASP LLM Top 10 | MITRE ATLAS | NIST AI RMF function | ISO/IEC 42001 clause area |
|---|---|---|---|---|
| RAG input validation / prompt injection filtering ([`rag-input-output-validation-design.md`](../guardrails/rag-input-output-validation-design.md)) | LLM01: Prompt Injection | AML.T0051 (LLM Prompt Injection) | MEASURE, MANAGE | 8.1 Operational planning and control; Annex A control on system testing |
| Output validation / PII scanning at PEP | LLM06: Sensitive Information Disclosure | AML.T0057 (LLM Data Leakage) | MEASURE | Annex A control on data protection in AI system operation |
| Document ingestion review (indirect injection control) | LLM01: Prompt Injection (indirect) | AML.T0051 | MAP, MANAGE | 8.1 Operational planning and control |
| Azure OpenAI content filters | LLM01, LLM06 | AML.T0051, AML.T0057 | MEASURE | Annex A control on AI system monitoring |
| Entra Conditional Access for AI apps | LLM06 (access-control dimension); supports least-privilege | AML.T0049 (Exploit Public-Facing Application — adjacent) | GOVERN, MANAGE | 5.3 Roles and responsibilities; Annex A access control |
| Purview DLP for Copilot | LLM06: Sensitive Information Disclosure | AML.T0057 | MEASURE, MANAGE | Annex A data protection controls |
| Tool scoping + least privilege (agentic workflow) | LLM08: Excessive Agency | AML.T0053 (LLM Plugin Compromise — adjacent) | MANAGE | 8.1 Operational planning and control |
| Human approval gate for high-value agent actions | LLM08: Excessive Agency | AML.T0053 | MANAGE | Annex A control on human oversight of AI systems |
| Velocity-based detection for threshold-splitting | LLM08: Excessive Agency | AML.T0053 | MEASURE | Annex A monitoring control |
| Sentinel: shadow AI detection ([`kql-shadow-ai-detection.kql`](../sentinel/kql-shadow-ai-detection.kql)) | LLM10: Unbounded Consumption (resource/usage dimension); supports overall visibility | AML.T0040 (ML Model Access — adjacent) | MAP, MEASURE | 8.1; Annex A asset inventory for AI systems |
| Sentinel: anomalous Copilot access ([`kql-anomalous-copilot-data-access.kql`](../sentinel/kql-anomalous-copilot-data-access.kql)) | LLM06: Sensitive Information Disclosure | AML.T0057 | MEASURE | Annex A monitoring control |
| Sentinel: prompt injection attempt signals ([`kql-prompt-injection-attempt-signals.kql`](../sentinel/kql-prompt-injection-attempt-signals.kql)) | LLM01: Prompt Injection | AML.T0051 | MEASURE, MANAGE | Annex A control on incident response for AI systems |
| Sentinel: excessive agent tool-call activity ([`kql-excessive-agent-tool-calls.kql`](../sentinel/kql-excessive-agent-tool-calls.kql)) | LLM08: Excessive Agency | AML.T0053 | MEASURE, MANAGE | Annex A monitoring control |
| AI risk register ([`ai-risk-register.csv`](../governance/ai-risk-register.csv)) | — (process artefact, not a technical control) | — | GOVERN, MAP | 6.1 Actions to address risks and opportunities |
| AI use-case risk tiering ([`ai-use-case-tiering-model.md`](../governance/ai-use-case-tiering-model.md)) | — | — | MAP | 6.1; 8.2 AI system impact assessment |
| Third-party AI vendor review ([`third-party-ai-vendor-review-template.md`](../governance/third-party-ai-vendor-review-template.md)) | LLM05: Supply Chain Vulnerabilities | AML.T0010 (ML Supply Chain Compromise) | GOVERN, MAP | 8.4 Third-party and customer relationships (AI-specific) |

## Notes on the mapping

- **OWASP LLM Top 10 entries not represented above** (e.g. LLM02: Insecure Output Handling beyond
  the PII scanning case, LLM03: Training Data Poisoning, LLM07: Insecure Plugin Design, LLM09:
  Overreliance) are not because they don't apply to LLM applications generally — they're either
  out of scope for the three systems modelled here (e.g. no fine-tuning means training data
  poisoning isn't a live risk, as noted explicitly in the agentic workflow threat model's T5), or
  would be addressed at the underlying infrastructure/vendor level (e.g. LLM03 sits with Azure
  OpenAI's model provider, not with this program's controls).
- **MITRE ATLAS technique IDs** are referenced at the closest applicable technique; ATLAS is
  adversary-tactic focused and doesn't always have a 1:1 control-to-technique relationship the way
  OWASP's risk-category framing does — some mappings above are the closest adjacent technique
  rather than an exact match, and that's called out explicitly rather than forced.
- **NIST AI RMF functions** (GOVERN, MAP, MEASURE, MANAGE) are used at the function level rather than
  citing specific subcategories, since subcategory numbering changes between RMF profile updates;
  function-level mapping is more durable for a reference document like this.
- **ISO/IEC 42001 clause references** point to the general clause area a control would evidence
  against in an audit, not to specific numbered Annex A controls verbatim — exact Annex A control
  numbering should be checked against the live standard text during any real audit prep.

## Related documents

- [`architecture-overview.md`](./architecture-overview.md)
- [`threat-model-rag-assistant.md`](./threat-model-rag-assistant.md)
- [`threat-model-agentic-workflow.md`](./threat-model-agentic-workflow.md)
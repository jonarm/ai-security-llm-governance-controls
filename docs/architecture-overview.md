# Architecture Overview — Contoso Retail Group AI Platform

## Purpose

This document describes the high-level architecture of three AI-enabled capabilities deployed
at Contoso Retail Group, a fictitious mid-size retailer used as the reference scenario for this
program. It establishes the system boundaries, data flows, and trust zones that the threat
models, governance controls, and detection rules in this repository are built against.

## In-scope AI systems

| System | Description | Primary data touched |
|---|---|---|
| **Microsoft 365 Copilot** | Tenant-wide Copilot across Outlook, Teams, Word, Excel, SharePoint | Email, chat, internal docs, customer correspondence |
| **RAG Customer Service Assistant** | Internal chatbot grounded on product, order, and policy documents via Azure OpenAI + Azure AI Search | Customer PII, order history, loyalty/CRM data, product catalog |
| **Agentic Order-Management Workflow** | LLM-driven agent that can query order status, issue refunds (under threshold), and update shipping details by calling internal APIs | Payment/refund data, order data, shipping/customer address data |

## Architecture diagram

\`\`\`mermaid
flowchart TB
    subgraph Users["Users"]
        EMP["Employees (M365 identities)"]
        CUST["Retail Customers"]
    end

    subgraph M365["Microsoft 365 Tenant — Trust Zone: Corporate Identity"]
        COPILOT["M365 Copilot"]
        EXO["Exchange / Teams / SharePoint data"]
        ENTRA["Entra ID + Conditional Access"]
        PURVIEW["Purview DLP / Sensitivity Labels"]
    end

    subgraph AppPlane["Customer-Facing App Plane — Trust Zone: Semi-Trusted"]
        WEBAPP["Customer Service Web/Chat Frontend"]
        ORDERAPP["Order Management Portal"]
    end

    subgraph AIPlane["AI Plane — Trust Zone: AI Services (Azure)"]
        AOAI["Azure OpenAI Service (GPT model + content filters)"]
        RAG["RAG Orchestrator (retrieval + prompt construction)"]
        SEARCH["Azure AI Search (vector index)"]
        AGENT["Agentic Workflow Orchestrator (tool-calling layer)"]
        PEP["Policy Enforcement Point (Azure Function — input/output validation)"]
    end

    subgraph DataPlane["Data Plane — Trust Zone: Sensitive Data"]
        CRM["CRM / Loyalty DB"]
        ORDERS["Order & Payment DB"]
        DOCS["Product & Policy Docs (SharePoint/Blob)"]
    end

    subgraph SecOps["Security Operations — Trust Zone: Monitoring"]
        SENTINEL["Microsoft Sentinel"]
        DEFENDER["Defender for Cloud Apps"]
    end

    EMP -->|Authenticated, CA-enforced| COPILOT
    COPILOT --> EXO
    COPILOT -.->|policy check| PURVIEW
    ENTRA -.->|enforces access| COPILOT

    CUST -->|Public internet, unauthenticated/low-trust| WEBAPP
    WEBAPP --> RAG
    RAG --> PEP
    PEP --> AOAI
    RAG --> SEARCH
    SEARCH --> DOCS

    EMP -->|Authenticated, scoped role| ORDERAPP
    ORDERAPP --> AGENT
    AGENT --> PEP
    PEP --> AOAI
    AGENT -->|Scoped API calls, human approval above threshold| ORDERS
    AGENT -.->|read-only| CRM

    AOAI -.->|content filter logs| SENTINEL
    PEP -.->|validation logs, blocked prompts| SENTINEL
    COPILOT -.->|usage/audit logs| SENTINEL
    DEFENDER -.->|shadow AI detections| SENTINEL

    classDef trustHigh fill:#1f3a5f,stroke:#0d1b2a,color:#fff
    classDef trustMed fill:#5f4b1f,stroke:#2a1f0d,color:#fff
    classDef trustData fill:#3a1f5f,stroke:#1b0d2a,color:#fff
    class M365,SecOps trustHigh
    class AppPlane,AIPlane trustMed
    class DataPlane trustData
\`\`\`

## Trust boundaries

| Boundary | Crossing point | Why it matters |
|---|---|---|
| **B1 — Public internet → App Plane** | Customer hits the web/chat frontend, unauthenticated or session-only | Untrusted input enters the system here; all prompt injection defenses anchor at this boundary |
| **B2 — App Plane → AI Plane** | Frontend/orchestrator calls the RAG orchestrator and agent orchestrator | This is where the Policy Enforcement Point (PEP) sits — every prompt and every model output crosses through validation before going further in either direction |
| **B3 — AI Plane → Data Plane** | RAG retrieval reads product/policy docs; Agent reads CRM and writes to Orders | Read vs. write matters: retrieval is read-only by design; the agent's write path (refunds, shipping updates) is the highest-risk boundary in the architecture and is where excessive-agency controls apply |
| **B4 — Corporate identity → Copilot** | Employees access Copilot under Entra ID + Conditional Access | Copilot inherits the user's existing M365 permissions (no broader exposure than the user already has), but this also means an over-permissioned account becomes an over-permissioned Copilot session |
| **B5 — AI Plane → SecOps** | Logs and signals flow to Sentinel | This is the only place all three systems become visible together for correlation; if logging is incomplete at B1–B3, detection coverage downstream is blind regardless of how good the Sentinel rules are |

## Design principles applied across all three systems

1. **No AI system gets direct, unmediated write access to sensitive data.** The agentic workflow's
   write actions (refunds, shipping changes) go through the PEP and a human-approval gate above a
   configured threshold — never directly from the LLM's output to the database.
2. **Retrieval is read-only.** The RAG assistant can read product/policy docs and read-only CRM/order
   lookups; it has no write path. This bounds the blast radius of a successful prompt injection against
   the customer-facing assistant.
3. **Identity is inherited, not elevated.** Copilot and the agentic workflow operate within the calling
   user's existing Entra ID permissions. AI is not used as a path to broader access than the user
   already has — over-permissioned accounts remain the underlying risk to fix via IAM, not the AI layer.
4. **Every AI Plane component logs to Sentinel.** Content filter triggers, PEP validation failures,
   blocked prompts, and tool-call invocations are all logged centrally — this is the prerequisite for
   the detection rules in `sentinel/`.

## Related documents

- [`threat-model-rag-assistant.md`](./threat-model-rag-assistant.md) — STRIDE + OWASP LLM Top 10 analysis of boundaries B1–B3 for the RAG assistant
- [`threat-model-agentic-workflow.md`](./threat-model-agentic-workflow.md) — excessive agency, tool-call abuse, and approval-gate design for boundary B3 (write path)
- [`framework-mapping.md`](./framework-mapping.md) — control matrix mapping the design principles above to OWASP LLM Top 10, NIST AI RMF, ISO/IEC 42001, and MITRE ATLAS
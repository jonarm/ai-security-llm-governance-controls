# Entra Conditional Access for AI Applications

## Purpose

This document describes the Conditional Access (CA) policies governing access to AI-enabled
applications at Contoso Retail Group — specifically M365 Copilot and the internal Order Management
Portal (the employee-facing entry point to the agentic order-management workflow). It covers the
policy design rationale and the Terraform implementation in
[`terraform/`](./terraform/) under this folder.

This addresses trust boundary **B4** (Corporate identity → Copilot) and the employee-facing side of
**B2** (App Plane → AI Plane) described in [`../docs/architecture-overview.md`](../docs/architecture-overview.md).

## Design rationale

Copilot and the agentic workflow's employee-facing portal both **inherit the calling user's existing
permissions** rather than operating with their own elevated identity (see Design Principle 3 in the
architecture overview). This means Conditional Access for these AI applications isn't really about
restricting *what the AI can do* — it's about ensuring the **underlying user identity** accessing the
AI surface meets the same assurance bar the organisation already requires for accessing the
sensitive data that AI surface can reach.

In practice, this means: if a user's account is compromised, the blast radius through Copilot or the
agentic workflow should be no different from the blast radius of that same compromised account
without AI in the picture — because the AI surface adds no privilege the user didn't already have.
CA policies enforce the *prerequisite* (device compliance, MFA, session controls) that keeps that
assumption true.

## Policies

### CA-AI-001: Require compliant device for Copilot access

| Setting | Value |
|---|---|
| **Users** | All users licensed for M365 Copilot |
| **Cloud apps** | Microsoft 365 Copilot |
| **Conditions** | Any device platform |
| **Grant control** | Require device to be marked as compliant (Intune) |
| **Session control** | None additional (relies on existing M365 session policies) |

**Rationale:** Copilot can summarise and surface a wide range of tenant content under the user's own
permissions. Requiring a compliant, managed device reduces the risk of session hijacking or token
theft from an unmanaged/unpatched endpoint being the path of least resistance into that content.

### CA-AI-002: Require MFA for Order Management Portal access

| Setting | Value |
|---|---|
| **Users** | Members of the "Order Management - Agent Users" group |
| **Cloud apps** | Order Management Portal (custom app registration) |
| **Conditions** | Any device platform |
| **Grant control** | Require multi-factor authentication AND require compliant device |
| **Session control** | Sign-in frequency: 4 hours |

**Rationale:** This portal is the entry point to the agentic workflow's write-capable actions
(refunds, shipping updates). It receives the strictest CA policy of any AI surface in this program —
both MFA and device compliance, plus a short sign-in frequency — because the cost of a compromised
session here is materially higher (financial action) than for Copilot (information access/summary).

### CA-AI-003: Block legacy authentication for AI application service principals

| Setting | Value |
|---|---|
| **Users** | All users |
| **Cloud apps** | M365 Copilot, Order Management Portal, RAG Customer Service backend service principal |
| **Conditions** | Client apps: Exchange ActiveSync, other legacy authentication clients |
| **Grant control** | Block |

**Rationale:** Legacy authentication protocols don't support modern CA evaluation (MFA, device
compliance) and are a well-known bypass path. Blocking them is a baseline hygiene control extended
explicitly to cover the AI application service principals, not just standard user sign-in.

### CA-AI-004: Require PIM activation for elevated agent-workflow administration

| Setting | Value |
|---|---|
| **Users** | Members of the "Order Management - Workflow Admins" role-assignable group |
| **Cloud apps** | Azure portal / agent orchestrator admin configuration surface |
| **Conditions** | Any device platform |
| **Grant control** | Require MFA; access only valid for active PIM role assignment |
| **Session control** | Sign-in frequency: 1 hour |

**Rationale:** Configuring the agent orchestrator itself (tool permissions, approval thresholds,
prompt templates) is a higher-privilege action than *using* the agent through the portal. This is
kept as a standing-eligible, just-in-time PIM role rather than a permanent assignment, consistent
with the PIM approach already used elsewhere in the organisation's identity controls.

## What Conditional Access deliberately does not cover here

CA policies govern *who can reach* the AI application and *under what session conditions* — they
do not validate *what the AI application does once reached* (prompt handling, output validation,
tool-call scoping). Those controls live in
[`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md) and the threat
models in `/docs`. This separation is deliberate: identity/access controls and application-layer AI
controls are different layers, each with their own failure modes, and conflating them in one
document or one policy tends to under-specify both.

## Terraform implementation

See [`terraform/main.tf`](./terraform/main.tf) for the Conditional Access policy resources, and
[`terraform/variables.tf`](./terraform/variables.tf) for the configurable group/app object IDs this
module expects as input.

## Related documents

- [`../docs/architecture-overview.md`](../docs/architecture-overview.md)
- [`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md)
- [`../docs/threat-model-agentic-workflow.md`](../docs/threat-model-agentic-workflow.md)
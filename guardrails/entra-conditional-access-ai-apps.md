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

### CA-AI-001: Copilot inherits existing tenant-wide Conditional Access (no dedicated policy)

**Investigation finding:** Unlike the Order Management Portal and other custom-registered
applications in this program, **Microsoft 365 Copilot does not provision its own distinct
enterprise application object in Entra ID**. Confirmed in the deployed tenant: searching Enterprise
Applications for "Copilot" returns only the unrelated `Microsoft Azure Network Copilot` first-party
app, and no separate object exists for the M365 Copilot Business license despite it being purchased,
assigned, and active.

This makes sense architecturally once checked: Copilot is a feature surfaced *inside* existing M365
services (Word, Excel, Outlook, Teams), not a separate application users sign into. Authentication
and authorisation for Copilot therefore flow through the same per-service cloud apps Copilot is
embedded in — principally `Office 365 Exchange Online` (`00000002-0000-0ff1-ce00-000000000000`)
and `Office 365 SharePoint Online` (`00000003-0000-0ff1-ce00-000000000000`) — rather than through a
Copilot-specific app registration that Conditional Access could target directly.

**What this means for CA design:** writing a dedicated "CA-AI-001: Require compliant device for
Copilot" policy targeting a Copilot app object isn't possible, because that object doesn't exist —
and would be redundant in any case, since CA policies scoped to `All` cloud apps already apply to
the underlying Exchange/SharePoint authentication Copilot rides on.

**Verified in this tenant:** the existing tenant-wide policies from the companion
[`erp-identity-security-reference-architecture`](https://github.com/jonarm/erp-identity-security-reference-architecture)
project already cover this:

| Existing policy | Scope | State | Relevance to Copilot |
|---|---|---|---|
| CA001 - Require MFA for All Users | All cloud apps | Enabled | Applies to any Copilot session, since Copilot authenticates through Exchange/SharePoint |
| CA002 - Block Legacy Authentication | All cloud apps | Enabled | Prevents legacy auth bypass for Copilot-adjacent sign-ins, same as any other M365 workload |

**Conclusion:** Copilot access control in this program is achieved by *inheritance from existing
tenant-wide identity controls*, not by a dedicated Copilot policy. This is documented explicitly
here rather than silently assumed, because the original design (a standalone CA-AI-001 policy
targeting a "Copilot app") was based on an incorrect assumption about Copilot's Entra ID footprint —
corrected after checking the actual deployed tenant rather than relying on the architectural
assumption alone. The original design principle still holds (CA governs the identity reaching the
AI surface, not the AI surface itself) — it's just enforced one layer down, at the underlying
service, rather than at a Copilot-specific object that doesn't exist.

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


## Deployment notes — lessons from live tenant deployment

Two corrections were made during actual deployment that are worth recording, since they reflect
real Entra ID/Terraform behaviour that isn't obvious from the resource schema alone:

1. **Copilot has no dedicated service principal to target.** Originally scoped as CA-AI-001
   (see the dedicated note above) — confirmed by direct inspection of Enterprise Applications in
   the live tenant, not assumed from documentation.

2. **`included_applications` expects the application's `appId`, not the object ID of the app
   registration or its service principal.** The first deployment attempt used app registration
   object IDs and failed with `ServicePrincipalNotFound`. The second attempt used the service
   principal's object ID (a reasonable next guess, since CA conceptually targets service
   principals) and failed identically. The working value was the `appId` GUID — the same
   identifier visible on the app registration's overview page, distinct from both its object ID
   and its service principal's object ID. This is a genuinely easy mix-up since Entra ID exposes
   three different GUIDs (app registration object ID, application appId, service principal object
   ID) for what feels like "the same app," and only one of them is valid in this specific field.

Both issues were resolved by deploying against the live tenant rather than assuming the Terraform
schema's field naming matched Entra ID's conceptual model, then correcting based on the actual API
error returned.
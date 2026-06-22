# Purview DLP Policies for Microsoft 365 Copilot

## Purpose

This document describes the Microsoft Purview Data Loss Prevention (DLP) policies governing what
sensitive content Microsoft 365 Copilot can surface, summarise, or generate from, at Contoso Retail
Group. It covers trust boundary **B4** (Corporate identity → Copilot) described in
[`../docs/architecture-overview.md`](../docs/architecture-overview.md), specifically the data
protection layer that sits alongside — not instead of — the Conditional Access controls in
[`entra-conditional-access-ai-apps.md`](./entra-conditional-access-ai-apps.md).

## Design rationale

Conditional Access controls *who can reach* Copilot under *what session conditions*. It does not
control *what Copilot is allowed to do with sensitive content once reached*. That's DLP's job.

The core design principle: **Copilot inherits the calling user's existing permissions, so DLP for
Copilot is not a separate Copilot-specific policy regime — it's the same DLP policies already
protecting that content everywhere else in the tenant, extended to cover the Copilot surface
explicitly.** A sensitivity label that already restricts a document's sharing should restrict what
Copilot can do with that document too. This avoids the common design mistake of building a parallel,
Copilot-only DLP framework that drifts out of sync with the organisation's actual data protection
policy over time.

## Sensitivity label taxonomy

This program uses four sensitivity labels, applied tenant-wide (not Copilot-specific), which DLP
policies for Copilot then act on:

| Label | Applies to | Copilot behaviour |
|---|---|---|
| **Public** | Marketing content, published product listings | No restriction |
| **Internal** | General internal correspondence, non-sensitive operational documents | Summarisable and referenceable by Copilot for internal users |
| **Confidential — Customer Data** | Customer PII, order history, loyalty/CRM exports | Copilot may reference for the data's owning business process, but content is blocked from being copied into external-facing output (email to external recipients, content with external sharing) |
| **Highly Confidential — Payment/Financial** | Payment data, refund/financial reconciliation records | Copilot is blocked from summarising, extracting, or including this content in any generated output, regardless of destination |

## Policies

### DLP-AI-001: Block Copilot from referencing Highly Confidential — Payment/Financial content

| Setting | Value |
|---|---|
| **Locations** | Exchange Online, SharePoint Online, OneDrive, Teams chat and channel messages |
| **Condition** | Content is labelled "Highly Confidential — Payment/Financial" |
| **Copilot-specific action** | Restrict Copilot and other agents from accessing this content (Purview's dedicated Copilot/agent restriction action, not just standard DLP block) |
| **User notification** | None — this is a silent control, since payment/financial records should never surface in Copilot regardless of the requester's intent |

**Rationale:** This is the highest-sensitivity label in the taxonomy and corresponds directly to
the data category flagged as highest-risk in the architecture overview and the agentic workflow
threat model. Copilot should never be the path by which this data is summarised or extracted, even
by an employee who has legitimate access to the underlying records through other means.

### DLP-AI-002: Restrict external sharing of Copilot-generated content referencing Confidential — Customer Data

| Setting | Value |
|---|---|
| **Locations** | Exchange Online (outbound mail), Teams chat (external participants) |
| **Condition** | Outbound content contains material labelled "Confidential — Customer Data" AND recipient is external to the organisation |
| **Action** | Block the outbound communication; notify sender with policy tip explaining the restriction |
| **User notification** | Policy tip shown to sender at time of send |

**Rationale:** Copilot can draft an email summarising a customer's order or loyalty history for an
internal team member without issue — the risk is that draft being sent externally without the
sensitivity of its content being re-evaluated. This policy doesn't target Copilot specifically; it
targets the *outbound* action regardless of whether a human or Copilot drafted the content, which
is the correct enforcement point.

### DLP-AI-003: Audit-only policy for Copilot interactions with Confidential — Customer Data (internal use)

| Setting | Value |
|---|---|
| **Locations** | SharePoint Online, OneDrive, Teams |
| **Condition** | Content labelled "Confidential — Customer Data" is referenced in a Copilot interaction (internal, no external sharing) |
| **Action** | Audit only — no block, generates an event for Sentinel correlation |
| **User notification** | None |

**Rationale:** Internal use of Copilot against customer data for legitimate business purposes
(an order management employee asking Copilot to summarise a customer's recent order history, for
example) is expected and should not be blocked — but it should be visible. This audit-only policy
feeds [`kql-anomalous-copilot-data-access.kql`](../sentinel/kql-anomalous-copilot-data-access.kql),
which looks for volume or pattern anomalies in exactly this audit signal, rather than trying to
block every individual legitimate access.

## Deployment notes — lessons from live tenant deployment

Two corrections were made during actual deployment, consistent with the practice established for
the Entra Conditional Access policies in this program:

1. **Sensitivity-label-based DLP conditions don't support all workload combinations.** The original
   policy design included Teams chat/channel messages in scope. Live deployment failed with
   `SensitivityLabelsNotSupportedForNonSupportedWorkloadsException` — Teams is not among the
   workloads Purview supports for label-based conditions (supported set: Exchange, SharePoint,
   OneDriveForBusiness, EndpointDevices, OnPremisesScanner, PowerBI, Applications). The deployed
   policy is scoped to SharePoint and OneDrive only; Teams coverage for this specific audit signal
   is a known gap versus the original design, not yet closed.

2. **Policy deletion in Purview is asynchronous.** An initial naming conflict during setup required
   deleting and recreating the policy; `Remove-DlpCompliancePolicy` returned successfully but the
   underlying object remained in a `PendingDeletion` state for longer than was practical to wait on
   mid-build. The live policy is therefore named `DLP-AI-003-v2` rather than `DLP-AI-003` — a naming
   artifact of this deletion timing, not a functional difference from the design.

3. **The correct PowerShell syntax for a sensitivity-label condition** requires a nested
   `operator`/`groups`/`labels` structure with an explicit `type = "Sensitivity"` field per label —
   confirmed against Microsoft's own documentation after two incorrect attempts using flatter
   hashtable shapes that are valid for built-in sensitive information types but not for sensitivity
   labels specifically.

## What this DLP layer deliberately does not cover

These policies govern content *already inside* the M365 tenant being referenced by Copilot. They do
not address content generated by the RAG Customer Service Assistant or the Agentic Order-Management
Workflow, which run on Azure OpenAI Service outside the M365/Purview boundary — those have their own
output validation layer, covered in
[`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md), because Purview
DLP's native integration is specific to Microsoft 365 Copilot and does not extend to custom
Azure OpenAI-based applications without separate integration work (out of scope for this program's
current phase).

## Deployment notes — live detection verification status

The policy and rule described above were deployed and independently verified correct at every
configuration layer:

- Sensitivity label "Confidential - Customer Data" created and published (label policy fully synced)
- Label confirmed applied to a real test file in OneDrive
- `DLP-AI-003-v2` policy confirmed `Enabled: True`, `Mode: TestWithoutNotifications`, scoped to
  `Exchange, SharePoint, OneDriveForBusiness`
- Rule `DLP-AI-003-Rule-AuditConfidentialCustomerData` confirmed `Disabled: False`,
  `GenerateAlert: True`, `GenerateIncidentReport: SiteAdmin`, correctly referencing the label's GUID

Despite this, no detection event was observed across every diagnostic surface checked in the
unified Purview portal: Compliance alerts, DSPM, DSPM for AI, and all three Data Loss Prevention
Explorers (Data Explorer, Content Explorer (Classic), Activity Explorer). The test file did not
appear as a discovered sensitive-data asset in any of these views, despite multiple deliberate
trigger actions (edit, download, share) performed well outside any reasonable propagation window
for the other delays encountered elsewhere in this program (which were measured in minutes to
roughly 24 hours).

The most likely explanation, based on Microsoft's own and practitioner documentation: SharePoint
and OneDrive content classification in Purview depends on a **crawl-based indexing cycle**, not
real-time scanning — content must be picked up by this crawl before any classification-aware
feature (DLP, Content Explorer, Activity Explorer) can act on it at all. This crawl cycle is
documented as capable of taking substantially longer than other propagation delays encountered in
this program, in some reported cases multiple days, particularly on smaller or newer tenants.

**Conclusion:** this control is configured and verified correct end-to-end at the policy/rule
layer, consistent with the rest of this program's "deploy for real, document honestly" approach.
Live detection firing was not confirmed within the timeframe available for this build, and that
limitation is recorded here rather than implied to be resolved.

## Related documents

- [`entra-conditional-access-ai-apps.md`](./entra-conditional-access-ai-apps.md)
- [`rag-input-output-validation-design.md`](./rag-input-output-validation-design.md)
- [`../sentinel/kql-anomalous-copilot-data-access.kql`](../sentinel/kql-anomalous-copilot-data-access.kql)
- [`../docs/architecture-overview.md`](../docs/architecture-overview.md)
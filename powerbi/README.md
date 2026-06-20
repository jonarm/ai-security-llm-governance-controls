# Power BI — Governance & Security Operations Dashboard

## Purpose

This folder contains the data sources, data model design, and DAX measures behind a three-page
Power BI dashboard for the AI Security & LLM Governance Controls Program: a **Governance Posture**
page, a **Security Operations** page, and an **Executive Summary** page.

Because Power BI Desktop is a Windows application producing a binary `.pbix` file, this folder
provides everything needed to **rebuild the dashboard yourself** in Power BI Desktop — the
datasets, the data model relationships, the DAX measure definitions, and page-by-page build
instructions — rather than a `.pbix` committed directly to source control (binary BI files don't
diff meaningfully in git, and rebuilding from documented source is itself a better demonstration of
the underlying data modelling skill than a static file would be).

## What's real vs. fabricated in the data

Being explicit about this matters, consistent with the honesty principle used throughout this
program's documentation:

| File | Status |
|---|---|
| [`../governance/ai-risk-register.csv`](../governance/ai-risk-register.csv) | **The actual designed artifact.** This is the real risk register this program is built around — not fabricated telemetry, but the genuine governance output of the threat modelling and risk tiering work in `/docs` and `/governance`. |
| [`sample-data-governance-posture.csv`](./sample-data-governance-posture.csv) | A single-row summary **derived directly from** the real risk register's actual tier and status distribution (not independently fabricated — the counts here are a roll-up of the 12 real rows in `ai-risk-register.csv`). |
| [`sample-data-copilot-dlp-activity.csv`](./sample-data-copilot-dlp-activity.csv) | **Fully fabricated, fictitious sample telemetry** — 30 days of plausible Copilot usage, DLP incident, and Sentinel alert volume for the fictitious Contoso Retail Group. No real tenant telemetry was used; this dataset exists to demonstrate dashboard design and DAX capability against time-series security data, not to represent actual measured activity. |

## Data model

Three tables, related as follows:

```
sample-data-governance-posture.csv (1 row, point-in-time snapshot)
    standalone - no relationship needed, used directly on the Governance Posture page

ai-risk-register.csv (12 rows, one per risk)
    standalone - used directly for risk-level detail and tier/status breakdowns

sample-data-copilot-dlp-activity.csv (30 rows, one per day)
    standalone - used directly for the time-series Security Operations page,
    related to a separate Date dimension table for proper time intelligence
```

None of the three tables need a relationship to each other for this dashboard's purposes — each
page draws primarily from one table. The one relationship worth building is a **Date dimension
table** related to the activity CSV's `date` column, which is what enables clean time intelligence
(week-over-week comparisons, trend lines) on the Security Operations page.

### Building the Date table

In Power BI Desktop, after loading the three CSVs:

1. **Modelling** tab → **New table**
2. Enter this DAX formula:

```dax
DateTable = CALENDAR(MIN('sample-data-copilot-dlp-activity'[date]), MAX('sample-data-copilot-dlp-activity'[date]))
```

3. Add calculated columns to the new `DateTable` for day-of-week and week-number labelling:

```dax
DayOfWeek = FORMAT('DateTable'[Date], "ddd")
WeekNumber = WEEKNUM('DateTable'[Date])
```

4. In the **Model** view, drag from `DateTable[Date]` to `sample-data-copilot-dlp-activity[date]` to
   create the relationship (one-to-many, single direction, from DateTable to the activity table)

## Importing the data

1. Open Power BI Desktop → **Get Data → Text/CSV**
2. Import all three files: `ai-risk-register.csv`, `sample-data-governance-posture.csv`,
   `sample-data-copilot-dlp-activity.csv`
3. For `ai-risk-register.csv` specifically, in Power Query confirm these column types after import
   (CSV import sometimes mis-types dates and numbers as text):
   - `likelihood`, `impact`, `inherent_risk_rating`, `residual_risk_rating` → Text (these are
     categorical Low/Medium/High labels, not numbers — leave as text)
   - `review_date` → Date
4. Build the `DateTable` and relationship as described above
5. Close & Apply

## DAX measures

Create these as new measures (Modelling tab → New measure) once data is loaded. Organised by which
page uses them.

### Governance Posture page measures

```dax
Total Open Risks = [risks_open_monitoring] + [risks_open_remediation_progress] + [risks_open_under_review]
```

```dax
Tier 3-4 Risk Share = 
DIVIDE(
    SUM('sample-data-governance-posture'[tier3_count]) + SUM('sample-data-governance-posture'[tier4_count]),
    SUM('sample-data-governance-posture'[total_ai_use_cases]),
    0
)
```

```dax
Control Implementation Rate = 
DIVIDE(
    SUM('sample-data-governance-posture'[controls_implemented]),
    SUM('sample-data-governance-posture'[controls_implemented]) + SUM('sample-data-governance-posture'[controls_planned]),
    0
)
```

```dax
Risk Count by Tier (from register) = COUNTROWS('ai-risk-register')
```

```dax
High Inherent Risk Count = 
CALCULATE(
    COUNTROWS('ai-risk-register'),
    'ai-risk-register'[inherent_risk_rating] = "High"
)
```

```dax
Residual Risk Reduction Rate = 
VAR HighInherent = CALCULATE(COUNTROWS('ai-risk-register'), 'ai-risk-register'[inherent_risk_rating] = "High")
VAR HighResidual = CALCULATE(COUNTROWS('ai-risk-register'), 'ai-risk-register'[residual_risk_rating] = "High")
RETURN
DIVIDE(HighInherent - HighResidual, HighInherent, 0)
```

This last measure is worth understanding, not just copying: it quantifies how many risks that
*started* as High inherent risk were brought down to a lower residual rating by the controls
documented in `/guardrails` and `/sentinel` — a direct, numeric expression of "did our controls
actually reduce risk," which is the kind of metric that resonates with a GRC or risk-management
audience specifically.

### Security Operations page measures

```dax
Total Copilot Interactions = SUM('sample-data-copilot-dlp-activity'[copilot_total_interactions])
```

```dax
Confidential Data Interaction Rate = 
DIVIDE(
    SUM('sample-data-copilot-dlp-activity'[copilot_interactions_confidential_data]),
    SUM('sample-data-copilot-dlp-activity'[copilot_total_interactions]),
    0
)
```

```dax
Total DLP Incidents = 
SUM('sample-data-copilot-dlp-activity'[dlp_incidents_low]) + 
SUM('sample-data-copilot-dlp-activity'[dlp_incidents_medium]) + 
SUM('sample-data-copilot-dlp-activity'[dlp_incidents_high])
```

```dax
High Severity Incident Rate = 
DIVIDE(
    SUM('sample-data-copilot-dlp-activity'[dlp_incidents_high]),
    [Total DLP Incidents],
    0
)
```

```dax
7-Day Rolling Avg Copilot Interactions = 
AVERAGEX(
    DATESINPERIOD('DateTable'[Date], MAX('DateTable'[Date]), -7, DAY),
    CALCULATE(SUM('sample-data-copilot-dlp-activity'[copilot_total_interactions]))
)
```

```dax
Week-over-Week Sentinel Alert Change = 
VAR CurrentWeek = CALCULATE(SUM('sample-data-copilot-dlp-activity'[sentinel_alerts_triggered]), DATESINPERIOD('DateTable'[Date], MAX('DateTable'[Date]), -7, DAY))
VAR PriorWeek = CALCULATE(SUM('sample-data-copilot-dlp-activity'[sentinel_alerts_triggered]), DATESINPERIOD('DateTable'[Date], MAX('DateTable'[Date]) - 7, -7, DAY))
RETURN
DIVIDE(CurrentWeek - PriorWeek, PriorWeek, 0)
```

### Executive Summary page measures

These reuse measures from both pages above, plus one new composite:

```dax
Overall Program Health Score = 
VAR ControlScore = [Control Implementation Rate] * 40
VAR RiskScore = (1 - [Tier 3-4 Risk Share]) * 30
VAR IncidentScore = (1 - [High Severity Incident Rate]) * 30
RETURN
ControlScore + RiskScore + IncidentScore
```

**Be ready to explain this measure's design choice, not just its formula, if asked:** it's a
weighted composite (40% control coverage, 30% risk tier distribution, 30% incident severity mix) —
the weighting is a judgement call, not a standard formula, and naming that openly (rather than
presenting it as an objective industry metric) is more credible than implying it's derived from
some authoritative source it isn't.

## Page-by-page build instructions

### Page 1: Governance Posture

- **Card visuals** (top row): Total Open Risks, Control Implementation Rate, Tier 3-4 Risk Share
- **Donut chart**: Risk count by tier (Tier 1/2/3/4), using `ai-risk-register[tier]`
- **Stacked bar chart**: Risk count by `risk_category`, coloured by `inherent_risk_rating`
- **Table**: Full risk register detail — `risk_id`, `use_case`, `tier`, `inherent_risk_rating`,
  `residual_risk_rating`, `status`, `risk_owner` — sortable, filterable by tier using a slicer

**Screenshot suggestion:** `screenshots/powerbi-dashboard/01-governance-posture-page.png`

### Page 2: Security Operations

- **Card visuals** (top row): Total Copilot Interactions, Total DLP Incidents, High Severity
  Incident Rate
- **Line chart**: `Total Copilot Interactions` and `7-Day Rolling Avg Copilot Interactions` over
  `DateTable[Date]` — the rolling average line makes the weekday/weekend pattern in the raw data
  readable instead of noisy
- **Stacked column chart**: DLP incidents by severity (`dlp_incidents_low/medium/high`) over time
- **KPI visual**: `Week-over-Week Sentinel Alert Change` with a target/trend indicator

**Screenshot suggestion:** `screenshots/powerbi-dashboard/02-security-operations-page.png`

### Page 3: Executive Summary

- **Single large KPI/gauge visual**: `Overall Program Health Score` (0–100 scale)
- **Three supporting card visuals** underneath, one per component score: Control Implementation
  Rate, Tier 3-4 Risk Share, High Severity Incident Rate — so the composite score is never shown
  without its inputs visible alongside it
- **Text box**: 2–3 sentence plain-language summary of current posture (write this manually once
  you see the real numbers rendered — don't fabricate commentary before seeing the actual visual)

**Screenshot suggestion:** `screenshots/powerbi-dashboard/03-executive-summary-page.png`

**Design principle for this page specifically:** an executive summary that hides its component
scores behind a single number invites the question "how was that calculated?" with no good answer
visible in the room. Showing the three inputs alongside the composite score pre-empts that question
and signals the score is transparent and decomposable, not a black box.

## Related documents

- [`../governance/ai-risk-register.csv`](../governance/ai-risk-register.csv)
- [`../governance/ai-use-case-tiering-model.md`](../governance/ai-use-case-tiering-model.md)

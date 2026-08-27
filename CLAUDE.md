# CLAUDE.md — RHTP Hospital Funding Tracker

Project context for Claude Code. Read at session start. Keep it current: the
"Current state" section at the bottom is updated at the end of **every**
session.

**Owner:** Isaac, AHA Data & Policy
**Objective:** Identify and quantify Rural Health Transformation Program (RHTP)
funds being distributed to hospitals, by state, with every figure traceable to a
primary state source.
**Stack:** R (tidyverse), `%>%` pipe only. Excel deliverable via `openxlsx`.
**Build environment:** Claude Code on the web (cloud sessions).
**Full specification:** `rhtp-tracker-build-spec.docx` (§ references below point into it).

---

## 1. The five governing principles (spec §0)

These govern every design decision. **If a later instruction seems to conflict
with one of these, the principle wins.**

### 0.1 Rural Care Journey (RCJ) is a discovery layer, not a source of record

RCJ is a commercial aggregator operated by AME Mobile. Its own site states it is
not affiliated with CMS/HHS/HRSA, that data is aggregated from public sources,
and that accuracy is not guaranteed. Observed extraction defects include:
non-RHTP records in the RHTP feed, page navigation text captured as document
titles, unrelated state press releases bleeding into event-schedule fields, and
awardee-level coverage that is complete in some states and empty in others.

RCJ's job in this system is to tell us where to look and when something changed.
The authoritative record for every published figure is the state notice of award
or equivalent primary document. **No RCJ field may appear in an AHA-published
number without independent state-source validation.**

### 0.2 The three-tier rule

RHTP money moves CMS → state → subrecipient. RCJ mixes all three tiers in a
single amount field. Every record must carry an `award_tier` before any other
processing:

| Tier | Code | What it is | Example |
|---|---|---|---|
| 1 | `STATE_ALLOTMENT` | CMS award to a state | Missouri FY2026, $216.0M |
| 2 | `SOLICITATION` | State-announced funding pool / NOFO budget | Ohio Rural CIN & Innovation Hubs, $61.7M |
| 3 | `SUBAWARD` | Executed or intended award to a named recipient | GA Dual Track Remote Critical Care, $900K to 4 rural hospitals |

Only Tier 3 answers the project question. Tiers 1 and 2 live in separate
reference tables, on separate Excel sheets, and are **never** unioned with Tier
3. Aggregation functions must **hard-fail** if passed mixed tiers.

### 0.3 Eligibility is not receipt

A solicitation listing hospitals among eligible entities is **not** evidence that
a hospital received money. This is the single most likely source of an inflated,
attackable number. Unresolved pass-through pools code as `Unclear`, never as
`Yes`.

### 0.4 Evidence-first

A determination without a captured, archived, quotable source is not a
determination. Any row with `distributed_to_hospital = Yes` must have a
validation URL, a local archived copy, and the confirming sentence stored in the
row. QA enforces this.

### 0.5 Committed or gone

This project runs in cloud sessions. Each session gets a fresh VM with the
repository cloned; anything not committed to git disappears when the session
ends. The raw landing zone, the evidence archive, and the review queue are all
persistence-critical, so all three are **committed rather than gitignored**. Any
code that writes a file the next session needs must be followed by a commit.
This inverts the normal convention of gitignoring data directories — see §1.

> **0.5 matters most for day-to-day behavior.** Commit persistent output before
> the session ends. Every stage that writes persistent output ends with a commit.

---

## 2. Standing instructions

- **Never** write code that sums across `award_tier` values.
- **Never** print, log, or echo the value of `RCJ_API_KEY`.
- **Never** add `data/raw/`, `data/evidence/`, or the review queue to `.gitignore`.
- **Commit persistent output before the session ends.**
- Never let a fuzzy hospital match auto-resolve — it goes to the review queue (§10.1).
- Never default an unassignable record to `SUBAWARD` — it goes to `UNASSIGNED` (§6.1).
- Never quote an RCJ machine-generated summary field as fact (see §6 below).

---

## 3. Coding conventions

- **tidyverse** throughout.
- **`%>%` exclusively — never the native `|>` pipe.** This is not a style
  preference; it is a hard rule for this repo.
- `snake_case` for all objects, columns, and file names.
- Explicit `dplyr::` / `tidyr::` / `stringr::` namespacing in package-style
  functions (anything in `R/utils_*.R` or exported helpers).
- **No `setwd()`.** Use `here::here()` for every path.
- No `arrow`/parquet — interim layer is `saveRDS()` / `readRDS()` (§3.4).
- No `pagedown` / `chromote` — evidence capture happens outside the cloud
  session (§9.0).
- Read the API key with `Sys.getenv("RCJ_API_KEY")` only. Never write it to a
  file, never commit it, never echo it. The same call works unchanged against a
  local `.Renviron`, so no code changes are needed to move between cloud and
  laptop.
- All normalization and downstream stages read from `data/raw/`, never from live
  API calls. Development and re-runs cost zero quota (§5).

---

## 4. Repository layout

```
CLAUDE.md                      # this file
R/
  01_retrieve_rcj.R            # Stage 1 — retrieval (NOT YET BUILT)
  02_normalize.R               # Stage 2 — normalization (NOT YET BUILT)
  03_state_registry.R          # Stage 3 — state source registry (NOT YET BUILT)
  04_validate.R                # Stage 4 — queue manager + rule engine (NOT YET BUILT)
  05_hospital_determination.R  # Stage 5 (NOT YET BUILT)
  06_build_workbook.R          # Stage 6 (NOT YET BUILT)
  qa_assertions.R              # (NOT YET BUILT)
  utils_config.R               # config + environment handling (BUILT)
data/
  raw/                         # IMMUTABLE. rcj/<pull_date>/<state>.json  — COMMITTED
  interim/                     # normalized .rds; review_queue.rds — COMMITTED
  reference/                   # state registry, controlled vocabs, crosswalks
  evidence/                    # <state>/<record_id>_<date>.pdf — COMMITTED
output/
  rhtp_hospital_tracker_<date>.xlsx
  review_queue_<date>.xlsx
logs/
  pull_manifest.csv            # COMMITTED
config/
  config.yml                   # base URL, paths, cadence, quota budget
docs/
  stage0_preflight_findings.md # Stage 0 API reconnaissance (authoritative)
```

**Persistence rules differ from normal practice.** `data/raw/`,
`data/evidence/`, `data/interim/review_queue.*`, and `logs/pull_manifest.csv`
are all committed. `.gitignore` excludes **only** `.Rhistory`, `.RData`,
`.Rproj.user/`, and `.Renviron`.

Monitor `data/evidence/` as archived PDFs accumulate; if the repo approaches a
few hundred MB, move the archive to shared storage and keep the file paths
recorded in the workbook rather than the files themselves.

---

## 5. Controlled vocabularies (spec §8)

Stored as `data/reference/vocabularies.csv`. **Validate every categorical column
against it. No free-text categories anywhere. Do not invent codes mid-session.**

**`award_tier`**
`STATE_ALLOTMENT` | `SOLICITATION` | `SUBAWARD` | `UNASSIGNED`

**`source_doc_type`**
`NOTICE_OF_AWARD` | `NOTICE_OF_INTENT_TO_AWARD` | `PROCUREMENT_PORTAL_POSTING` |
`STATE_BUDGET_NARRATIVE` | `AGENCY_PRESS_RELEASE` | `GOVERNOR_PRESS_RELEASE` |
`THIRD_PARTY_NEWS` | `OTHER`
*Strength ordering matters: the first three are primary; press releases are
secondary; third-party news alone can never support a `Yes`.*

**`rhtp_award_confirmed`**
`Yes` | `No` | `Unclear`

**`recipient_type`**
`HOSPITAL_OR_SYSTEM` | `HOSPITAL_AFFILIATED_ENTITY` | `FQHC_OR_RHC` |
`EMS_OR_PSAP` | `UNIVERSITY_OR_AHC` | `AHEC` | `SCHOOL_OR_DISTRICT` |
`LOCAL_GOVT_OR_PUBLIC_HEALTH` | `TRIBAL_ORG` | `STATE_AGENCY` |
`VENDOR_OR_CONTRACTOR` | `NONPROFIT_CBO` | `NOT_YET_NAMED`

**`flow_type`**
`DIRECT` | `PASS_THROUGH_DESIGNATED` | `PASS_THROUGH_UNRESOLVED` |
`IN_KIND_BENEFIT` | `NON_HOSPITAL`

**`distributed_to_hospital`**
`Yes` | `No` | `Unclear`

**`determination_confidence`**
`HIGH` | `MEDIUM` | `LOW`

**`activity_type`**
Map to the CMS RHTP allowable-use categories (the CMS category guidance series —
e.g. Category E covers workforce). Retain the state's own raw activity language
in a parallel `activity_type_raw` field; **never discard it.**

---

## 6. RCJ machine-generated fields — search aids only

RCJ's record descriptions read as LLM-generated, and the platform offers opt-in
AI answer synthesis. **Nothing synthesized may be quoted as fact in an AHA
product.** Quotable text comes from the source document via §9.

Fields confirmed machine-generated in Stage 0 and therefore **non-quotable**:
`programDescription`, `programHighlights`, `highlights`, `progressSummary`,
`strategicGoals`, `transformationStrategy`, `summary`, `milestones`,
`performanceTargets`, `completenessScore`, `implementationPhase`,
`activityType` (RCJ's own coding), and any `aiAnswer` from `POST /api/v1/search`.

---

## 7. Confirmation decision rules (spec §9.2)

Apply these **mechanically**. The `Unclear` bucket becomes a dumping ground
unless these rules are explicit and applied consistently. Reviewer consistency is
what makes the file defensible.

**`Yes`** — a state agency or designated pass-through administrator document
names **both the recipient and the award**. `validation_source_type` must be
`NOTICE_OF_AWARD`, `NOTICE_OF_INTENT_TO_AWARD`, `PROCUREMENT_PORTAL_POSTING`,
`STATE_BUDGET_NARRATIVE`, or an official agency/governor press release that names
the recipient.

**`No`** — the state source contradicts RCJ, or shows the solicitation
cancelled, withdrawn, unawarded, or re-opened without award.

**`Unclear`** — any of: the only available source is third-party news; amounts
conflict across sources; the page exists but names no recipients; the record is a
pass-through pool with unresolved subrecipients; the source is a projection or
plan rather than an award action.

### Flow determination (spec §10.2)

| `flow_type` | Test | `distributed_to_hospital` |
|---|---|---|
| `DIRECT` | Named recipient matches a hospital in AHA/POS | `Yes` |
| `PASS_THROUGH_DESIGNATED` | Intermediary receives funds, but the source document names hospital subrecipients or restricts eligibility to hospitals **and the award has been made** | `Yes`, with `intermediary_name` populated |
| `PASS_THROUGH_UNRESOLVED` | Intermediary administers a pool where hospitals are among eligible entities, recipients not yet named | `Unclear` — **do not impute** |
| `IN_KIND_BENEFIT` | Funds go to a vendor or state system that hospitals use but do not receive | `No`, but set `hospital_benefiting = Yes` |
| `NON_HOSPITAL` | Recipient and purpose are clearly outside hospitals | `No` |

`IN_KIND_BENEFIT` gets its own flag rather than being discarded: it matters to
AHA's narrative even though those dollars must **never** enter a "funds
distributed to hospitals" total.

`determination_confidence`: `HIGH` (primary source, named hospital recipient, CCN
matched) / `MEDIUM` (primary source, hospital identity inferred from name without
CCN match) / `LOW` (secondary source or unresolved pass-through).

`determination_basis` is **free text and mandatory**. When someone asks in six
months why a $12M award was coded hospital-bound, the answer must be in the row.

---

## 8. Retrieval strategy — global pagination CONFIRMED (spec §5.1)

**Tested 2026-08-27 (Session 2). Result: Branch A. Pull nationally at max
`limit`, partition by state locally.** Full evidence:
`docs/stage1_pagination_test.md`.

`/awards`, `/documents`, and `/opportunities` all paginate **without** a `state`
filter. Unfiltered totals are genuinely national (1,429 awards / 3,092 documents
/ 631 opportunities; page 1 alone spans 21–32 states, and unfiltered `/awards`
at 1,429 dwarfs `state=GA` at 115). Page 1 and page 2 id sets are disjoint, and
the last page of each endpoint returns exactly the arithmetic remainder — so
deep pages are reachable and complete, with no cap.

### Implied monthly call volume

Per full national pull: `/awards` 3 + `/documents` 31 + `/opportunities` 7 +
`/activity` ~5 = **~46 calls**.

| Branch | Cadence | Calls/month | % of 2,000 |
|---|---|---:|---:|
| **A — global (confirmed)** | Weekly | ~199 | 10% |
| **A — global (confirmed)** | Twice-weekly | ~399 | 20% |
| B — per-state fallback (not needed) | Weekly only | ~800–900 | 40–45% |

**Twice-weekly is affordable** and is the recommended cadence through the
Year 1 → Year 2 transition, leaving ~1,600 calls/month of headroom.

Spec §5.1 projected 100–150/month for weekly; measured is **~199**, because
`/documents` alone is 31 of the 46 calls per pull against a hard 100/page cap.
Budget ~200, not ~125. Every additional 100 documents adds 1 call/pull, so
`/documents` is the line item to watch as the corpus grows.

### `limit` is silently capped — client requirement

`/documents?limit=500` returns **HTTP 200** while serving 100 rows and echoing
`pagination.limit: 100`. Over-max limits are neither honoured nor rejected —
they are quietly downgraded.

**Always compute the page count from the response's `pagination.limit` and
`pagination.total`, never from the requested limit.** A client trusting its own
`limit=500` on `/documents` would walk 7 pages, read 700 of 3,092 records, and
report success. That is the silent short-read failure mode in spec §5.2.

Confirmed maxima: `/awards` 500, `/documents` 100, `/opportunities` 100.

### 8.1 Redistribution rights — resolved, no longer blocking

**Superseded by revised spec §4.1.** RCJ still publishes no terms of service
(`/terms`, `/terms-of-service`, `/tos`, `/legal`, `/api-terms` all 404; the only
legal document is `/privacy-policy`, which covers account data and is silent on
reuse). The site footer says only: *"Not affiliated with HRSA, CMS, or HHS ·
Data aggregated from public state and federal sources · For research and
informational purposes only · Not intended as official program guidance."*

What changed is the project's scope, not the finding: **this project is
internal-use only and produces no published product**, so redistribution is not
a live question and is **not a blocker**.

If that scope ever changes, resolve permitted use with AME Mobile
(`info@amemobile.net` / `admin@amemobile.net`) **and AHA counsel before anything
leaves the building.** Principle §0.1 remains the primary mitigation either way:
no RCJ field enters a published number — every figure traces to a state primary
source that AHA retrieved and archived independently.

---

## 9. RCJ API quick reference

Full detail: `docs/stage0_preflight_findings.md`. Read it before writing any
retrieval code.

- **Base URL:** `https://www.ruralcarejourney.com` (`rhtp.amemobile.net` also
  supported). All endpoints under `/api/v1/`.
- **Auth:** `Authorization: Bearer <key>` or `X-Api-Key: <key>`.
- **Plan on our key: Pro — 2,000 requests/month, 60 requests/min, 250 AI
  answers/month.** Not the 10,000/month plan. Budget accordingly.
- **Quota headers (confirmed live):** `x-ratelimit-monthly-limit`,
  `x-ratelimit-monthly-remaining`, `x-ai-search-monthly-limit`,
  `x-ai-search-monthly-remaining`. No per-minute headers exist — the 60/min limit
  must be respected by client-side throttling.
- **Two envelope shapes.** `{data, pagination:{page,limit,total,pages}}` for
  `/states`, `/awards`, `/documents`, `/opportunities`, `/events`;
  `{data, count, page, hasMore}` for `/activity`. `POST /search` returns
  `{documents, count, hasMore, aiAnswer}`.
- **There is no `updated_since` filter on `/awards`, `/documents`, or
  `/opportunities`.** Only `/activity` supports `since`. Spec §5's delta-pull
  design must be reworked — see the findings doc.
- **`sourceDocument.url` is an RCJ-hosted proxy, not the state URL.** The
  original state source URL appears **only** in `/api/v1/activity` (`siteUrl`,
  `detail.updatedDocuments[].sourceUrl`).

---

## 10. Current state

**Last updated:** 2026-08-27 (Session 3)

### Stages built

| Stage | File | Status |
|---|---|---|
| Scaffold / config | `config/config.yml`, `R/utils_config.R` | **Built** |
| Stage 0 — Preflight | `docs/stage0_preflight_findings.md` | **Complete** |
| Stage 1 — §5.1 pagination test | `docs/stage1_pagination_test.md` | **Complete — Branch A confirmed (§8)** |
| Stage 1 — Retrieval | `R/01_retrieve_rcj.R` | **Built and run. First national pull complete — `docs/stage1_retrieval_run.md`** |
| Stage 2 — Normalization | `R/02_normalize.R` | Not started |
| Stage 3 — State registry | `R/03_state_registry.R` | Not started |
| Stage 4 — Validation | `R/04_validate.R` | Not started |
| Stage 5 — Hospital determination | `R/05_hospital_determination.R` | Not started |
| Stage 6 — Workbook | `R/06_build_workbook.R` | Not started |
| QA assertions | `R/qa_assertions.R` | Not started |
| Tests | `tests/testthat/test_01_retrieve_rcj.R` | **Built — 44 assertions, zero quota. Run `Rscript tests/run_tests.R`** |

### States validated

None. No state has been through Stage 4 validation.

Pilot set (spec §14), none started: Georgia, Virginia, Nebraska, Florida, Texas.

### Raw pulls on disk

- **`data/raw/rcj/2026-08-27/` — first production national pull (Session 3).**
  `states.json` 50, `awards.json` 1,429, `documents.json` 3,092,
  `opportunities.json` 631, `activity.json` 1,787. All exhaustive, none
  capped, none drifted. 12 MB. **60 API calls.** This is the Stage 2 input.
- `data/raw/rcj/2026-08-27/_stage0_exploratory/` — Session 1's Delaware-only
  Stage 0 probes, moved into a subdirectory so a Stage 2 glob cannot sweep
  them into the record table and double-count Delaware. Not a production pull.
  Delaware's 15 award records remain the Stage 2 fixtures.

**Quota: 1,920 of 2,000 remaining** (80 consumed this month).

### Environment status (spec §3.3)

**Fixed and verified this session.** R 4.3.3 with all 11 §3.3 packages
installed from the environment snapshot — tidyverse 2.0.0, httr2 1.3.0,
jsonlite, openxlsx, janitor, digest, here, yaml, fuzzyjoin, assertr, testthat.
`library(tidyverse); library(httr2); library(assertr)` loads clean with **no
source-build fallback**. Session 2's blocker 1 is resolved.

**One defect found and fixed in code:** cloud sessions start R in the
**C/POSIX locale** (`LANG` unset), where `readLines()` and every `stringr`
operation fail on multibyte UTF-8. `config/config.yml` was itself unreadable.
`utils_config.R` now sets a UTF-8 locale at `source()` time so every stage
inherits it, and `rhtp_preflight()` reports it. **Recommend also adding
`LANG=C.UTF-8` to the environment's Environment variables** so the fix does
not depend on code alone — RCJ titles and awardee names carry non-ASCII text.

### Open blockers

1. **`/states` cannot serve as the state vocabulary.** Its 50 codes are 49
   states plus a pseudo-state `US`, and **Wyoming is absent** — though WY has
   records in `/documents`, `/opportunities`, and `/activity`. Stage 3's
   registry needs an independent 50-state list, and
   `qa$allotment_expected_states: 50` will not reconcile against anything
   RCJ-derived.
2. **Delta-pull strategy still needs a decision.** No `since` on the award or
   document endpoints, so hashing is the only Tier 3 change detection
   (§4.1). Stage 1 writes a `body_sha256` per page over the verbatim response
   text, which gives Stage 2 a page-granularity starting point. The remaining
   question is whether `/activity` narrows to a `since=` delta after this
   first backfill (45 calls/pull) or keeps being pulled comprehensively
   (60 calls/pull). Both are affordable — see below.

*Resolved this session:* the R environment (Session 2 blocker 1), and
**`/activity` backfill sizing (Session 2 blocker 3) — measured at 18 calls /
1,787 records.** *Resolved earlier:* redistribution rights (superseded by spec
§4.1, see §8.1).

### Measured call budget — supersedes the §8 projection

A comprehensive pull is **60 calls**, not the ~46 projected. The gap is
`/activity`: §5.1's ~5 was a bounded weekly delta, while the comprehensive
backfill is 18. `/states` adds the last call and is now part of the pull.

| Cadence | Calls/pull | Calls/month | % of 2,000 |
|---|---:|---:|---:|
| Weekly | 60 | ~260 | 13% |
| **Twice-weekly (adopted)** | **60** | **~520** | **26%** |

Up from 20%, still comfortably affordable, **and the adopted cadence does not
change.** Narrowing `/activity` to a `since=` delta would drop a pull to ~45
calls (~390/month, 20%).

`/documents` (31) and `/activity` (18) are 49 of the 60 calls, both against a
hard 100/page cap. They are the line items to watch as the corpus grows.

### Data-quality findings waiting for Stage 2

From the national pull, recorded but deliberately not acted on — Stage 1 never
transforms:

- **`RC` is a junk state code.** 54 `/documents` records carry `state: "RC"`,
  titled `"RC - 2026 - …"`, category `REFERENCE`. National reference material
  filed under a non-state code. A §6.2 junk-filter fixture.
- **`/awards` covers only 39 of 50 states.** Eleven states have zero award
  records nationally — §0.1's uneven awardee coverage, now quantified at 22%
  of states with no Tier 3 candidates in RCJ at all. Completeness is bounded
  by the state registry, not by RCJ.
- **`/activity` carries `siteUrl` on all 1,787 records**, with real state
  domains (`tn.gov/health/rural.html`, `hcpf.colorado.gov/…`). Confirms §4.1
  and makes `/activity` the most useful input to Stage 3's registry, which the
  spec assumed would be compiled entirely by hand.

### Next session

Session 4 — Stage 2 normalization (`R/02_normalize.R`): tier assignment, junk
filters with the observed defects as fixtures, hashing and change detection.
Read from `data/raw/rcj/2026-08-27/` — the five `<endpoint>.json` files in the
parent directory, **never** `_stage0_exploratory/`. Costs zero quota.

Take the four findings above as the first junk-filter and partitioning test
cases, alongside Delaware's Stage 0 defects (§6 of the preflight doc: tier
mixing, HRSA non-RHTP contamination, `federalAmount: 1`).

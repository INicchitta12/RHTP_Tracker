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
- Every human reviewer reads `reviewer-coding-instructions.md` before touching a
  record, and every automated classifier keys off recipient identity, never
  activity type (§0.3a).
- **The spec is edited in the repo. Patches only — never a wholesale file
  upload.** This applies to `rhtp-tracker-build-spec.md`, `CLAUDE.md` and
  `reviewer-coding-instructions.md` alike. See §2.1.

### 2.1 The spec is edited in-repo, by patch

`rhtp-tracker-build-spec.md`, `CLAUDE.md` and `reviewer-coding-instructions.md`
are **source files under version control, not documents that live on a laptop
and get uploaded.** Change them here, in a commit whose diff shows exactly what
moved. **Do not replace them by uploading a local copy**, however small the edit
looks.

The reason is that it has already destroyed committed work twice, in the same
way both times — a stale local copy overwriting a section it was never aware of:

- **`0a51145`** replaced `reviewer-coding-instructions.md` with a local copy
  predating `34d8fee`, silently deleting the committed `MULTI_RECIPIENT_FIELD`
  section (§6.2). Found and restored a session later, by accident.
- **`219d803`** replaced `rhtp-tracker-build-spec.md` with a copy that did not
  contain `9fdc156`, reverting the §10.2 `NON_HOSPITAL` correction — the row
  that stops a reviewer coding Beebe Healthcare's school-based health center as
  a non-hospital, which is the single error §0.3a exists to prevent. Session 7
  found the spec still carrying the defective row and re-applied the commit.

Neither deletion appeared as a deletion. Both looked like an upload of the
current file. A patch cannot do this: git refuses a conflicting edit and shows
the difference instead of resolving it silently in favour of whichever copy was
uploaded last.

Two consequences worth stating plainly:

- **An upload is a full-file overwrite even when the intent is a one-line
  change.** Everything committed since that local copy was taken is discarded,
  and nothing in the commit says so.
- **A merged PR is not enough.** `9fdc156` was pushed to a branch *after* PR #7
  merged its parent, so it never reached `main` at all, and the next spec upload
  cemented that. Check that a correction is on `main` before relying on it, and
  say so in the commit that depends on it.

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
  00_cms_press_monitor.R       # Stage 00 — CMS trigger list (BUILT, never run)
  01_retrieve_rcj.R            # Stage 1 — retrieval (BUILT)
  02_normalize.R               # Stage 2 — normalization + §6.4 mining (BUILT)
  03_state_registry.R          # Stage 3 — CMS allotments + registry (BUILT)
  03b_budget_narratives.R      # Stage 2.5 — §7A initiative table + §7A.4 gate (BUILT)
  03c_cms_abstracts.R          # CMS project abstracts — §4.1 candidate list (BUILT)
  03d_ga_great_health.R        # Georgia GREAT Health Year 1 awardees (BUILT)
  03e_fl_year1_awardees.R      # Florida Year 1 + the §8 recipient_type back-fit (BUILT)
  03f_pa_year1_awardees.R      # Pennsylvania Year 1 — 66 authorized projects (BUILT)
  03g_al_year1_awardees.R      # Alabama Year 1 — 138 grants, parsed from prose (BUILT)
  03h_ak_year1_awardees.R      # Alaska Year 1 — 161 intents to award (BUILT)
  03i_sd_rht_contracts.R       # South Dakota — the transparency-portal search (BUILT)
  04_validate.R                # Stage 4 — queue manager + rule engine (NOT YET BUILT)
  05_hospital_determination.R  # Stage 5 (NOT YET BUILT)
  06_build_workbook.R          # Stage 6 (NOT YET BUILT)
  qa_assertions.R              # (NOT YET BUILT)
  utils_config.R               # config, paths, credentials, state vocabulary (BUILT)
  utils_recipient_classification.R  # the §8/§10.2 rules, shared by every state (BUILT)
data/
  raw/                         # IMMUTABLE — COMMITTED
    rcj/<pull_date>/*.json     #   the RCJ landing zone
    cms/<fetch_date>/*.html    #   the §7.1 allotment table, verbatim + digest
    cms/<fetch_date>/*.pdf     #   the CMS project abstracts, verbatim + SHA-256
    owner_uploads/*.xlsx       #   owner files as supplied — R/03e's ingest source
  interim/                     # normalized .rds/.csv; review_queue.rds — COMMITTED
  reference/                   # allotment anchor, registry, controlled vocabs
  evidence/                    # <state>/<record_id>_<date>.pdf — COMMITTED
    budget_narratives/DE/      #   §7A.2 — DE narrative + SHA-256 manifest; 49 to go
    GA/                        #   4 DCH announcements + the 87-hospital roster
    PA/                        #   DHS announcement + the 66-project list
    AL/                        #   the governor's 138-grant release
    AK/                        #   the DOH award-notice workbook
    SD/                        #   the open.sd.gov search + 13 contract detail pages
output/
  rhtp_hospital_tracker_<date>.xlsx
  review_queue_<date>.xlsx
  state_source_registry_worksheet_<date>.xlsx   # §7.2, for offline verification
logs/
  pull_manifest.csv            # COMMITTED
  normalize_manifest.csv       # COMMITTED, schema-pinned (§13.20)
config/
  config.yml                   # base URL, paths, cadence, quota budget, CMS source
docs/
  stage0_preflight_findings.md # Stage 0 API reconnaissance (authoritative)
  stage3_allotments_and_registry.md  # §7.1 anchor, §6.4 mining, §7.2 worksheet
  stage2.5_budget_narratives.md      # §7A parser, the §7A.4 gate, gaps left open
  session10_roster_live_monitor_recipient_type.md  # GA roster, live stage 00, §8
  session11_six_state_award_list_hunt.md  # AK/AL/ND/OH/PA/SD award-list locators
  session12_pa_al_ak_extraction_and_sd.md # PA/AL/AK extracted; the SD portal's shape
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
`VENDOR_OR_CONTRACTOR` | `NONPROFIT_CBO` | `PHYSICIAN_PRACTICE` |
`NOT_YET_NAMED`
*A named recipient whose form the source does not state is `NONPROFIT_CBO` +
`determination_confidence = LOW` + `flag_reason = RECIPIENT_TYPE_INFERRED`
(settled session 10; Florida's `UNCLASSIFIED` was back-fitted to it).
`PHYSICIAN_PRACTICE` is a determinable form, not that fallback.*

**`flag_reason`** — three codes added in session 12, each for a condition no
existing code covered, each written into `vocabularies.csv` with full notes:
`AMOUNT_ROUNDED_IN_SOURCE` (the source published the amount rounded — Alabama,
45 of 138 rows), `AMOUNT_PRELIMINARY` (the source says the amount is not final —
Alaska, every row), `RECIPIENT_TYPE_VARIES_IN_SOURCE` (one named recipient
carries different forms on different rows of one document — Alaska, 26 rows).
Every state assert now validates `flag_reason` against the vocabulary, so a
fourth invented code fails at the state that invents it.

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
| `NON_HOSPITAL` | Recipient is clearly not a hospital — a school district, a university, an EMS agency, a vendor. **Judge the recipient, never the activity (§0.3a):** Nebraska's school kitchen modernization awarded to the Department of Education is `NON_HOSPITAL`; Delaware's school-based health center awarded to Beebe Healthcare is `DIRECT`. Same setting, different recipients, different codes. | `No` |

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

**Last updated:** 2026-08-28 (Session 12 — PA/AL/AK extracted, SD's portal searched, the §8/§10.2 rules made shared)

### Stages built

| Stage | File | Status |
|---|---|---|
| Scaffold / config | `config/config.yml`, `R/utils_config.R` | **Built** |
| Stage 0 — Preflight | `docs/stage0_preflight_findings.md` | **Complete** |
| Stage 00 — CMS trigger list | `R/00_cms_press_monitor.R` | **Built and RUN (Session 10). `medicaid.gov` allowlisted; 8 states have announced. Two parser blind spots fixed. Routine now points at `main` — `docs/stage00_cms_press_monitor.md`** |
| Stage 1 — §5.1 pagination test | `docs/stage1_pagination_test.md` | **Complete — Branch A confirmed (§8)** |
| Stage 1 — Retrieval | `R/01_retrieve_rcj.R` | **Built and run. First national pull complete — `docs/stage1_retrieval_run.md`** |
| Stage 2 — Normalization | `R/02_normalize.R` | **Built. Allotment anchor live; §6.4 mining; §0.2a Tier 1 corroboration; §6.2 multi-recipient split — `docs/stage2_normalization_run.md`, `docs/stage3_allotments_and_registry.md`, `docs/corrections_after_session5.md`** |
| Stage 3 — Allotments + registry | `R/03_state_registry.R` | **Built and run. §7.1 anchor committed; §7.2 worksheet exported. §7.3 registry awaits offline verification — `docs/stage3_allotments_and_registry.md`** |
| Stage 2.5 — Budget narratives | `R/03b_budget_narratives.R` | **Built and run. Format-detecting parser + the §7A.4 gate. 2 of 50 states extracted; OK and DE both `RECONCILED` and publishable (Session 8) — `docs/stage2.5_budget_narratives.md`** |
| CMS project abstracts | `R/03c_cms_abstracts.R` | **Built and run (Session 7). All 50 states extracted, 120 CANDIDATE_ONLY organizations — §4.1** |
| Georgia Year 1 awardees | `R/03d_ga_great_health.R` | **Built and run. 139 award actions (Session 10 expanded the 2 AHEAD cohorts into 87 named hospitals), $197.1M, 9.92% residual — `docs/georgia_great_health_year1.md`** |
| Florida Year 1 awardees | `R/03e_fl_year1_awardees.R` | **Built and run (Session 10). Ingests the owner's workbook, applies the §8 `recipient_type` back-fit, 81 award actions. FL and GA now union — `docs/session10_roster_live_monitor_recipient_type.md`** |
| Pennsylvania Year 1 | `R/03f_pa_year1_awardees.R` | **Built and run (Session 12). 66 authorized projects, $42,198,309.80 against DHS's stated $42,198,309 — `docs/session12_pa_al_ak_extraction_and_sd.md`** |
| Alabama Year 1 | `R/03g_al_year1_awardees.R` | **Built and run (Session 12). 138 grants parsed from prose, 95 awardees, $143,745,821** |
| Alaska Year 1 | `R/03h_ak_year1_awardees.R` | **Built and run (Session 12). 161 intents to award; the 161-vs-142 gap closed — 142 Implementation + 19 Planning** |
| South Dakota portal | `R/03i_sd_rht_contracts.R` | **Built and run (Session 12). 13 administrative contracts, $5,618,367. The announced $31.5M and $90M rounds are NOT on open.sd.gov** |
| §8/§10.2 classifier | `R/utils_recipient_classification.R` | **Built (Session 12). The recipient_type and flow rules for every state, in one file** |
| Stage 4 — Validation | `R/04_validate.R` | Not started. **Gated on the verified §7.3 registry.** Do not start it before that. |
| Stage 5 — Hospital determination | `R/05_hospital_determination.R` | Not started |
| Stage 6 — Workbook | `R/06_build_workbook.R` | Not started |
| QA assertions | `R/qa_assertions.R` | Not started |
| Tests | `tests/testthat/test_00_cms_press_monitor.R`<br>`test_01_retrieve_rcj.R`<br>`test_02_normalize.R`<br>`test_03_state_registry.R`<br>`test_03b_budget_narratives.R`<br>`test_03c_cms_abstracts.R`<br>`test_03d_ga_great_health.R`<br>`test_03e_fl_year1_awardees.R`<br>`test_03f_pa_year1_awardees.R`<br>`test_03g_al_year1_awardees.R`<br>`test_03h_ak_year1_awardees.R`<br>`test_03i_sd_rht_contracts.R`<br>`test_utils_recipient_classification.R`<br>`test_state_union.R` | **Built — 997 assertions; 996 pass and 1 self-skips (the stage 00 first-run branch, now that the CSV exists). Zero quota. Run `Rscript tests/run_tests.R`**|

### States validated

None. No state has been through Stage 4 validation.

Pilot set (spec §14), none started: Georgia, Virginia, Nebraska, Florida, Texas.

### Deliverable 1 — six states extracted

| | Rows | Total published | Hospital rows | Hospital dollars |
|---|---:|---:|---:|---:|
| FL | 81 | — | see `fl_year1_awardees.csv` | — |
| GA | 139 | $197,148,327 | 87 named hospitals | **$60,000,000** |
| **PA** | 66 | $42,198,310 | 27 | **$24,149,111** |
| **AL** | 138 | $143,745,821 | 60 | **$66,133,019** |
| **AK** | 161 | $160,701,975 | 26 | **$43,379,541** (preliminary) |
| **SD** | 13 | $5,618,367 | 0 | $0 |

**None of these hospital figures is comparable to another without reading its
row**, and that is not a caveat to be dropped in a summary: PA's are authorized
but undisbursed, AK's are preliminary intents to award, 45 of AL's amounts are
rounded in the source, and SD's zero is because South Dakota's actual awards are
not published anywhere reachable. All six union on the leading 19 columns with
zero values outside §8, asserted every run by `tests/testthat/test_state_union.R`.

### Reference tables on disk

- **`data/reference/cms_fy2026_allotments.csv` — 50 rows, the §7.1 anchor
  (Session 5).** Parsed from the CMS December 2025 press release, never
  transcribed. Total $10,000,000,003 (CMS's own $3 of rounding), min
  NJ $147,250,806, max TX $281,319,361. Asserted against §13.17 on every load.
  The source table is archived verbatim at
  `data/raw/cms/2026-08-27/cms_fy2026_allotment_table.html` — with a header
  carrying the full page's SHA-256, so provenance still closes — and
  committed, so the parse is reproducible offline. Only the `<table>` is
  archived: the surrounding CMS page chrome carries a third-party API token
  that is CMS's to publish and not ours to redistribute.
- `data/reference/state_source_registry_worksheet.csv` — 151 candidate hosts,
  all 50 states, every verification column empty. **Awaits offline
  verification (§7.2).**
- `data/reference/cms_states.csv` — the 50-row state vocabulary (§7.1).
- `data/reference/state_source_registry.csv` — **does not exist yet.** It is
  the §7.3 deliverable, compiled by hand from the worksheet.
- **`data/reference/abstract_named_organizations.csv` — 120 rows, 16 states
  (Session 7).** Organizations named in the CMS project abstracts, every row
  `CANDIDATE_ONLY`. The source of record; `abstract_named_organizations.xlsx`
  is a render of it. Rebuild with `Rscript R/03c_cms_abstracts.R --build`.
- **`data/reference/abstract_coverage_by_state.csv` — 50 rows (Session 7).**
  All 50 states extracted; 16 named anyone, 34 named nobody.
- **`data/reference/fl_year1_awardees.csv` — 81 rows (Session 10).** Florida
  Year 1, the source of record; `FL_year1_awardees.xlsx` is a render of it. Five
  rows back-fitted from `UNCLASSIFIED` to `NONPROFIT_CBO` + `LOW` +
  `RECIPIENT_TYPE_INFERRED`; `recipient_type_source` preserves the owner's value
  on every row. Unions with Georgia on the leading 19 columns.
- **`data/reference/cms_state_announcements.csv` — 8 rows (Session 10).** The
  stage 00 trigger list, from the live CMS page. AK, AL, GA, ND, OH, PA, SD, WV.
  A **discovery** source (§0.1): its `amount` is never summed (§0.2), and an
  assertion enforces that.
- `data/reference/ga_great_health_awards.csv` — 139 rows, including the 87 named
  AHEAD hospitals (Session 10). Rebuild with `Rscript R/03d_ga_great_health.R --build`.
- **`data/reference/pa_year1_awardees.csv` — 66 rows (Session 12).**
  Pennsylvania's first tranche, parsed from DHS's own project table. Source of
  record; `PA_year1_awardees.xlsx` is a render. Rebuild with
  `Rscript R/03f_pa_year1_awardees.R --build`.
- **`data/reference/al_year1_awardees.csv` — 138 rows (Session 12).** Alabama's
  first round, parsed from the governor's prose. 45 amounts carry
  `AMOUNT_ROUNDED_IN_SOURCE`; 14 rows are second grants that inherit their
  recipient from a continuation paragraph.
- **`data/reference/ak_year1_awardees.csv` — 161 rows (Session 12).** Alaska's
  rolling notice of intent to award, a snapshot at 2026-08-28. Every row
  `amount_confirmed = No`; 26 carry `RECIPIENT_TYPE_VARIES_IN_SOURCE`.
- **`data/reference/sd_rht_contracts.csv` — 13 rows (Session 12).** South
  Dakota's `RHT` contract series from the state transparency portal. **Read the
  file header before using it: this is $5.6M of administrative spend and is NOT
  South Dakota's $121.5M of announced subawards, which are not published
  anywhere reachable.**
- `data/reference/vocabularies.csv` — now carries the §7A codes as well
  (`recipient_status`, `reconciliation_structure`, `reconciliation_status`,
  `extraction_method`, `recipient_confirmed`, `amount_confirmed`,
  `has_hospital_recipient`, `initiative_grain`, `validator`). Read it through
  `rhtp_vocabulary()` — the single reader, in `utils_config.R`. **Session 10
  added `PHYSICIAN_PRACTICE` to `recipient_type`** and documented five
  `flag_reason` codes that were in use but had never been written down
  (`RECIPIENT_NAMES_NOT_CAPTURED`, `RECIPIENT_NOT_NAMED`,
  `ELIGIBILITY_NOT_RECEIPT`, `PHASE_ATTRIBUTION_INFERRED`,
  `RECIPIENT_TYPE_INFERRED`).
- **`data/reference/budget_narrative_status.csv` (§7A.2) — does not exist
  yet.** It records what was searched and when, and nothing has been searched.
  It belongs to the collection pass, not to the parser.

### Raw pulls on disk

- **`data/raw/rcj/2026-08-27/` — first production national pull (Session 3).**
  `states.json` 50, `awards.json` 1,429, `documents.json` 3,092,
  `opportunities.json` 631, `activity.json` 1,787. All exhaustive, none
  capped, none drifted. 12 MB. **60 API calls.** This is the Stage 2 input.
- `data/raw/rcj/2026-08-27/_stage0_exploratory/` — Session 1's Delaware-only
  Stage 0 probes, moved into a subdirectory so a Stage 2 glob cannot sweep
  them into the record table and double-count Delaware. Not a production pull.
  Delaware's 15 award records remain the Stage 2 fixtures.
- `data/raw/cms/2026-08-27/` — the CMS allotment press release (Session 5).
- `data/raw/cms/2026-08-28/` — the CMS RHTP resources page, the stage 00
  trigger list (Session 10). Archived verbatim with a SHA-256 manifest;
  `shape : TABLE`.
- `data/raw/cms/2026-08-28/state_press_releases/` — the six CMS state
  announcement press releases for AK, AL, ND, OH, PA and SD (Session 11).
  **Only the `<main>` element is archived**, on the §7.1 precedent: the
  surrounding CMS chrome carries a third-party Mapbox token in its Drupal
  settings JSON, which is CMS's to publish and not ours to redistribute. The
  manifest carries **both** digests — the article's and the full page's as
  served — so provenance still closes, and the writer asserts each file free of
  that token shape before writing it. A **discovery** source (§0.1): their
  project and grant *counts* corroborate what each state has published, and §0.2
  forbids summing across them — CMS mixes Tier 1 and Tier 3 in the same prose.
- `data/raw/owner_uploads/` — the owner's Florida workbook exactly as supplied,
  with a SHA-256 manifest. It is `R/03e`'s ingest source and cannot be
  regenerated: the workbook at the repo root is a render now.

**Quota: 1,920 of 2,000 remaining** (80 consumed this month; Sessions 5 and
8–11 spent none — Session 11's only network calls were to `www.cms.gov` and
the refused ones to `web.archive.org`).

### Environment status (spec §3.3)

R 4.3.3 with all 11 §3.3 packages, plus `rvest`/`xml2` for the §7.1 CMS parse.
`LANG=C.UTF-8` is set in the environment and `utils_config.R` also sets a UTF-8
locale at source time — keep both (§3.3).

`cms.gov` and `www.cms.gov` are on the allowlist and confirmed reachable
(HTTP 200). Stage 4 will need the broader §9.5 change.

### Open blockers

1. **The §7.3 state source registry is not compiled — §13.12 is a hard gate.**
   The §7.2 worksheet is exported with 151 candidates covering all 50 states,
   but a candidate is not a verified row. Until
   `data/reference/state_source_registry.csv` exists with a `award_posting_url`
   and a human `last_verified` per state, **Stage 4 cannot validate a Tier 3
   candidate in that state at all.** `state_source_url` is present on only 13%
   of `/awards` and 6% of `/documents` records, so the registry — not RCJ — is
   how Stage 4 finds anything. `rhtp_validate_state_registry()` is built and
   tested and will report gaps as deliverable gaps, never silent skips.
   Compile Florida first: AHCA's numbered RFAs on a procurement portal are the
   only route to its Tier 3 data.
2. **The §9.11 findings are not in the repo.** The premise test is *done* — the
   sequencing records it complete, and §0.3a quotes its result (eleven verified
   Delaware records, all coded `hospital = no`, four of them to hospitals). But
   no findings document was committed, so the eleven records cannot be re-read
   here, and Stage 4's §9.3 design cannot be checked against what state sources
   actually publish. Commit them before Stage 4.
3. **The hosts that would close this session's four open items.** `www.pa.gov`,
   `governor.alabama.gov`, `health.alaska.gov`, `doh.sd.gov` and `open.sd.gov`
   were all opened for Session 12 and all four states are extracted. Still
   refused at CONNECT (403), in the order they are worth asking for:
   **`news.sd.gov`** — it holds both South Dakota award announcements, 110 named
   recipients and $121.5M behind two pages, and it is the single largest
   unextracted block of named recipients this project knows about;
   **`adeca.alabama.gov`** / **`alabamarhtp.com`** — ADECA's own award file,
   which would turn Alabama's 45 rounded amounts into exact ones and close the
   $254,179 gap against the governor's own headline;
   `ruralhealthtransformation.sd.gov`.
3b. **The other 49 state health-department hosts are still not on the
   allowlist.** `dhss.delaware.gov` was added for Session 8 and Delaware is
   done, but §7A.2 needs fifty such hosts and only one is reachable. Widen the
   allowlist (Claude Code on the web → environment settings → network access)
   before the collection pass, or it will stall one state at a time. Session 11
   ranked the Tier 3 half of that queue — `www.pa.gov`, `governor.alabama.gov`,
   `health.alaska.gov`, then `doh.sd.gov` + `open.sd.gov`; each has a
   recipient-level list already published behind it.
7. **`web.archive.org` is permitted by policy but unreachable, and the apex
   `archive.org` is denied.** The gateway completes the CONNECT and the TLS
   handshake is then reset by the peer; 28 curl attempts over 15 minutes plus
   three further clients, and the proxy logs no policy denial. **Re-tested in
   Session 12 and unchanged** — same completed CONNECT, same reset at the Client
   Hello, still no policy denial for it, while the apex `archive.org` is still
   logged as `connect_rejected` 403. This is what keeps Georgia's 80/7 phase
   split an inference rather than a fact, and it is the only way to read a page
   as it stood on a past date — which this project will want again. Re-test it;
   the failure was upstream of the policy, so it may clear without a change.
4. **Delta-pull strategy still needs a decision.** No `since` on the award or
   document endpoints, so hashing is the only Tier 3 change detection (§4.1).
   The remaining question is whether `/activity` narrows to a `since=` delta
   after this first backfill (45 calls/pull) or keeps being pulled
   comprehensively (60 calls/pull). Both are affordable.
5. **The AHA Annual Survey / CMS Provider of Services extracts are not in the
   repo.** Stage 5 cannot match a hospital name to a CCN without them, so every
   `determination_confidence` stays at `MEDIUM` at best (§7: `HIGH` requires a CCN
   match). Georgia's 87 named hospitals make this the next binding constraint
   rather than a distant one — they carry addresses and CMS designations and are
   ready to match. Commit both extracts before the hospital-determination session.

6. **`qa_assertions.R` is still unbuilt**, and it is now the only stage between
   here and a workbook that has no file at all. §13.25 and §13.27 are already
   satisfied by the code and only need asserting.

*Resolved in Session 10:* **`greathealth.georgia.gov` (old blocker 5)** — the host
was allowlisted, the roster is archived, and Georgia's two aggregate AHEAD rows are
87 named hospitals. **`www.medicaid.gov` (old blocker 6)** — allowlisted, stage 00
has run against the live page, and the Routine points at `main`. **The §8
`recipient_type` question** — settled on Georgia's convention, Florida back-fitted,
and the two states now union.

*Resolved in Session 7:* the §9.11 blocker's evidence landed as `DE Verify.xlsx`
(11 hand-verified Delaware records) and the 16 unextracted CMS abstracts are
done, so `abstract_named_organizations.csv` now covers all 50 states. The §10.2
spec defect was re-applied after an upload had reverted it — see §2.1.
*Resolved after Session 5:* the four corrections — §0.2a Tier 1 corroboration,
§6.2 multi-recipient splitting, §6.4 `NO_RCJ_DATA`, §5.2 `run_type` — plus
and the stale-spec blocker, which cleared when `27b8e0c` landed §0.2a/§0.3a/§7A on `main`
mid-session. Full detail: `docs/corrections_after_session5.md`.
*Resolved in Session 5:* **the CMS allotment anchor (Session 4 blocker 1).**
`STATE_ALLOTMENT` is populated across all 50 states, and §6.1 tier rule 3 and
the §6.2 allotment ceiling are both live and have both already fired.
*Resolved earlier:* the state vocabulary (Session 4); the R environment and
`/activity` backfill sizing (Session 3); redistribution rights (superseded by
spec §4.1, see §8.1).

### Measured call budget

A comprehensive pull is **60 calls**. Twice-weekly is the adopted cadence:
~520 calls/month, 26% of the 2,000 allowance. `/documents` (31) and
`/activity` (18) are 49 of the 60, both against a hard 100/page cap, and are
the line items to watch as the corpus grows. Narrowing `/activity` to a
`since=` delta would drop a pull to ~45 calls (~390/month, 20%).

### Stage 2 results — with the §7.1 anchor live

Full detail: `docs/stage2_normalization_run.md` (Session 4 rules work) and
`docs/stage3_allotments_and_registry.md` (this session). 5,152 records, zero
quota.

| Tier | PASS | FLAGGED | QUARANTINED |
|---|---:|---:|---:|
| `STATE_ALLOTMENT` | 257 | 15 | 2 |
| `SOLICITATION` | 1,377 | 143 | 7 |
| `SUBAWARD` | 1,016 | 347 | 6 |
| `UNASSIGNED` | 1,679 | 195 | 108 |

**Tier 3, clean: 1,010 records, $1.98B announced** — still RCJ's unvalidated
claim (§0.1), not a finding until Stage 4 ties it to a state primary source.
Session 6's §6.2 multi-recipient flag moved 6 records and $50.3M out of "clean"
and into "flagged for review", which is where a figure whose recipient list is
unresolved belongs.

**`STATE_ALLOTMENT` went from 0 rows to 274, covering all 50 states.** 225
`/documents` rows moved out of `UNASSIGNED` and 49 `/opportunities` rows out of
`SOLICITATION` — the latter literally titled *"<State> Federal RHTP Award
(FY2026-FY2030)"*, i.e. the CMS→state allotments themselves. **Nothing left
Tier 3:** rule 2 precedes rule 3, so a named recipient always wins.

274 Tier 1 *records* is not a contradiction of §13.3's "50 rows". The Tier 1
**reference table** is `cms_fy2026_allotments.csv` (50 rows, CMS-anchored) and
is what the §11 State Allotments sheet is built from. The 274 record-table rows
are RCJ records *about* those allotments; tiering them correctly is what keeps
them out of Tier 3.

The §6.2 allotment ceiling fired on its first run: one New Hampshire `/awards`
row carrying **$1,898,965,390 against a $204M allotment** — three managed care
organisations in a single `awardeeName`. Flagged
`AMOUNT_EXCEEDS_STATE_ALLOTMENT`.

### §6.4 mining — 38 candidates, and the eleven zero-award states split in two

`/awards` is not the Tier 3 universe; it is what RCJ managed to parse (§4.1).
The mining pass found **38 award-shaped `/documents` records across 19 states**
that produced no `/awards` row. The spec's known live example is among them:
*FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants*
(note: no dollar sign anywhere in the title).

**None was promoted to `SUBAWARD`** (§6.4, §13.18). All carry
`flag_reason = UNPARSED_AWARD_CANDIDATE` and keep their tier — 34 on
`UNASSIGNED` rows, 4 on rows rule 3 tiered `STATE_ALLOTMENT`. The flag is a
review signal, never a tier claim.

The eleven states §4.1 named as returning zero `/awards` records now split:

| Group | States | Meaning |
|---|---|---|
| `UNPARSED_DATA_EXISTS` | **FL, NC, NJ, TN** | Award-shaped data is in `/documents`; RCJ failed to extract it |
| `NO_DATA` | AR, KY, MA, MN, NY, SC, WY | Nothing award-shaped surfaced from RCJ at all |

Across all 50: 24 `PARSED`, 15 `PARSED_PLUS_CANDIDATES`, 4
`UNPARSED_DATA_EXISTS`, 7 `NO_DATA`. The full table is
`data/interim/stage2_mining_coverage.csv` — the §11 Coverage sheet's two
dimensions, in the shape Stage 6 needs.

### Corrections after Session 5 — §0.2a, §6.2, §6.4, §5.2, §0.3a

Full detail: `docs/corrections_after_session5.md`. Zero quota, no network calls.
Built first from a session prompt, then **reconciled against the real spec**
when `27b8e0c` landed it on `main` mid-session.

**§0.2a — Tier 1 figures come from CMS, never from RCJ.** Every one of the 274
`STATE_ALLOTMENT` records is now compared to the CMS figure for its state.
**Only 35 restate it exactly; 33 of 50 states have no exact restatement anywhere
in RCJ.** Largest gap: Florida, -$938,195 on four records. Zero records fall
outside rule 3's tolerance, which is the check confirming rule 3 behaved.
Written to `data/interim/stage2_tier1_corroboration.csv`.

**§6.2 — multi-recipient `awardeeName` fields split**, on all four §6.2
delimiters (`;`, `,`, ` and `, ` & `). **199 candidates from 41 parent records**:
the NH $1,898,965,390 row is three managed care organisations, and one Oregon
$10,000,000 row names **102 clinics**. **The amount is never divided** — every
fragment carries `amount_announced_field_total` and there is no per-fragment
amount column for a sum to get wrong. The parent keeps its tier; the flag routes
to review. Clean Tier 3 moves 1,016 → 995 records and $2.03B → $1.76B; that
$265.9M is now flagged rather than reported against recipient lists nobody read.

**§0.3a — the entity patterns had to grow first.** `Beebe Healthcare`,
`TidalHealth` and `Nemours Children's Health` — the three hospitals §0.3a names
as having been coded away — **all failed the §6.1 legal-entity test**, so any
guard keyed on it dropped them silently. Two markers added per §6.1's own
"extend rule 1" instruction, deliberately not matching a bare `Health` so
`Oregon Health & Science University` is still not split on its `&`. This also
lifted §6.4 mining from 38 candidates to **43 across 21 states**.

**§6.4 — `NO_DATA` is now `NO_RCJ_DATA`.** AR, KY, MA, MN, NY, SC and WY each
hold a $147M–$281M CMS allotment. The old label read as a claim about the state;
it is a claim about RCJ's coverage. `coverage_status` was also missing from
`vocabularies.csv` entirely (a Session 5 omission) and is now there in full.

**§5.2 — `run_type` ∈ `PRODUCTION` | `DEV` on both pinned manifests.** Session
5's four runs backfilled `DEV`, everything else `PRODUCTION`; the manifest stays
append-only, so development runs are filtered, never deleted. `--dev` on the
Stage 2 CLI. An abbreviation is refused too — `match.arg()` would have accepted
`PROD` as `PRODUCTION` and written the misspelling to an audit log.

**`reviewer-coding-instructions.md` already existed** (sequencing item 6, done
by the owner at `f8a3ab8`). One section was appended for the flag this session
introduced: `MULTI_RECIPIENT_FIELD` rows carry one candidate per fragment, the
split is a guess to be checked against the source, and the field total is never
that recipient's award.

**Nebraska, the state missing from the 49 `/opportunities` allotment rows.** The
record exists and is correctly titled *"Nebraska Federal RHTP Award
(FY2026-FY2030)"* — RCJ published `budgetMax: 100000` against a **$218,529,075**
allotment, short by a factor of ~2,185. Rule 3 could not match it and rule 4
tiered it `SOLICITATION`. This is §0.2a in one row: publishing Tier 1 from RCJ
would have shown Nebraska as a $100,000 state.

### One defect fixed in change detection

Landing the allotment anchor should have moved 274 rows and moved **zero**:
`rhtp_apply_change_detection()` kept the prior row verbatim whenever
`rcj_record_hash` was unchanged. The hash covers RCJ payload fields only — which
is correct (§6.3) — but the stored row also carries this pipeline's derived
columns, which are a build output, not a fact about the record. Left alone, no
rules change would ever be visible and §13.10 would fail silently on a table
mixing rule generations.

A live `UNCHANGED` row is now replaced by this run's classification of the same
payload, carrying `first_seen` forward. `superseded_by` is **not** set —
superseding tracks changes in the data, and re-deriving a column from unchanged
input is not one. Superseded historical rows keep the classification they were
published with. The run reports the reclassification count and writes the set to
`data/interim/stage2_reclassified.rds`.

### Reviewer coding instructions — sequencing item 6, done

`reviewer-coding-instructions.md` is rewritten and is now the artifact §9.12
requires every reviewer to read first. Zero quota, no network calls, no code
touched.

It had regressed. The `MULTI_RECIPIENT_FIELD` section appended at `34d8fee` was
**removed at `0a51145`**, an owner upload of a local copy predating it — the
xlsx files landed in the same commit, so the deletion was almost certainly
collateral. That section is restored verbatim.

The larger gap was that the file only covered **award records**, while §0.1
inverted the project onto **budget narratives** and Session 6 is about to
produce initiative tables nobody has coding rules for. The file is now in two
parts:

- **Part A — award records.** The Delaware worked examples, the §9.3 split of
  `recipient_confirmed` / `amount_confirmed`, evidence requirements, source
  strength. Substantially as the owner wrote it.
- **Part B — initiatives from budget narratives.** New. The unit is the
  initiative and the output is `has_hospital_recipient`; **a named hospital is
  not required for `Yes`**, because Oklahoma names no individual hospital
  anywhere and still has six hospital-directed fund uses. Worked examples are
  read out of `OK_initiative_table.xlsx` and `DE_initiative_table.xlsx`, so the
  rules match how the two reference states were actually coded. Also: never
  divide an initiative budget, and never average the 14.6%–48.7% spread (§0.1b).

The two parts are kept explicitly non-substitutable (§0.1a, §7A.5a). Delaware's
school-based health centers are the worked case: the *awards* to Beebe,
TidalHealth and Nemours are Part A `Yes`; the same program's *initiative* row is
Part B `Unclear`, because the narrative was written while the vendor was still
TBD. Both codings are correct and they are not the same claim.

Added as well: a walkthrough of the review-queue flags a human will actually
meet (`UNPARSED_AWARD_CANDIDATE` carries no tier claim,
`AMOUNT_EXCEEDS_STATE_ALLOTMENT` is almost always a multi-recipient field,
`PROGRAM_NAME_AS_AWARDEE` never promotes the agency to recipient, and so on).

**One spec defect was found and then fixed at the source.** §10.2's
`NON_HOSPITAL` row listed *"school-based health centers"* as an example of a
recipient "clearly outside hospitals." That is an activity, and it is the exact
error §0.3a exists to correct — the four Delaware records it would mis-code are
the four §0.3a names. **The row is rewritten** (owner's wording) to judge the
recipient and to carry the contrast that makes it unmissable: Nebraska's school
kitchen modernization to the Department of Education is `NON_HOSPITAL`;
Delaware's school-based health center to Beebe Healthcare is `DIRECT`. Same
setting, different recipients, different codes. The identical row in §7 of this
file is updated to match, and the reviewer instructions now cite §10.2 as
agreeing rather than warning around it.

> **That fix did not survive.** `9fdc156` was pushed to its branch after PR #7
> had merged the parent, so it never reached `main`, and the spec upload at
> `219d803` overwrote the file with a copy that predated it. Session 7 found
> the spec still carrying the defective row and re-applied the commit. §2.1.

### Session 7 — Stage 2.5, the CMS abstracts, and a reverted correction

Full detail: `docs/stage2.5_budget_narratives.md`. Zero RCJ quota; one call to
`cms.gov`.

**Stage 2.5 is built, and its gate immediately quarantined Delaware.**
`R/03b_budget_narratives.R` resolves columns by synonym against the §7A.3
schema, scores every sheet in a workbook, and refuses rather than guesses on a
tie, on a non-numeric amount column, or on a workbook mixing two states. That
is what §7A.1 requires: the two reference extractions use different sheets,
different amount columns, different grains, and Oklahoma's `initiative` column
is the six-way *grouping* while `fund_use` is the row's identity — mapping the
obvious-looking column would have collapsed 28 rows onto 6 names.

```
OK  ALLOCATED_ONLY   RECONCILED   91.7%  (204,900,000 of 223,476,949)
DE  TOTAL_INCLUSIVE  VARIANCE     84.6%  (133,082,267 of 157,394,964)  QUARANTINED
```

*Delaware's line is Session 7's and is superseded — see Session 8 below. It is
kept because the gate catching the truncation unaided is the case for the gate.*

Oklahoma at 91.7% is what §7A.4 predicts. **Delaware fails, and should.** Its
narrative total is exact to $0.14, so a gate keyed on the *stated* total would
have passed it; keying `reconciliation_status` on what was actually captured —
while `reconciliation_structure` records which document the state wrote — is
what makes the check work. The shortfall is exactly the unextracted initiatives
13–15 ($10,105,200) plus state admin ($1,079,227.17) and indirect
($13,128,269.21). Adding 13–15 puts Delaware at 91.0% and `RECONCILED`, which
the tests already assert.

The §0.1b headline shares fall out of the parse rather than being carried over:
Oklahoma 48.7% hospital-directed, Delaware 15.7%; unclear 17.1% and 24.5%.
(Delaware is **14.6% / 22.8%** on the complete 15-initiative extraction — Session 8.)

**All 50 CMS project abstracts are extracted.** The earlier pass truncated at
page 52; `R/03c_cms_abstracts.R` completes OH–WY. 33 new candidates across
6 states — WA 9, VA 8, RI 7, OK 5, PA 3, OR 1 — and 10 states name nobody. The
yield holds: across all 50 states the abstracts name **7 hospital entities**,
one of which (Eleanor Slater) is a state hospital named as a site rather than
an awardee. Good for pass-through administrators, weak for hospitals. §4.1's
no-dollar-figures rule is now *enforced* — `rhtp_assert_no_dollar_figures()`
hard-fails the build on any currency-shaped string, positive-controlled against
`$337 million`, a bare `1,000,000,000`, and a numeric column.

**A committed spec correction had been silently reverted.** `9fdc156` fixed the
§10.2 `NON_HOSPITAL` row across all three documents, but it was pushed to its
branch *after* PR #7 merged the parent, so it never reached `main` — and the
spec upload at `219d803` then cemented the defective row. Re-applied here. This
is the second instance of the same failure, and it is why §2.1 now exists.

### Session 8 — Delaware initiatives 13–15, and the gate confirming its own prediction

Full detail: `docs/stage2.5_budget_narratives.md`. Zero RCJ quota; one call to
`dhss.delaware.gov`.

The host was allowlisted, so `Final-RHTP-Revised-Budget-1.30.26.pdf` was fetched
(74 pages, 619,344 bytes) and archived with a SHA-256 manifest at
`data/evidence/budget_narratives/DE/`. **It is the first budget narrative on
disk**, and the first state whose derived `source_archive_path` points at a real
file.

No `pdftotext`, `pdftools` or `pypdf` is available in the cloud session and PyPI
is unreachable, so the text was recovered by inflating the PDF's own
FlateDecode content streams and reading the `Tj`/`TJ` operators. Initiatives 13,
14 and 15 begin on pages 68, 71 and 73.

| # | Initiative | Year 1 | Recipient | `flow_type` | `has_hospital_recipient` |
|---|---|---:|---|---|---|
| 13 | Rural Health Workforce Education Program | $1,000,000 | 2 contractors, both TBD | `NON_HOSPITAL` | `No` |
| 14 | Healthcare Workforce Data Center | $2,685,200 | Division of Professional Regulation | `NON_HOSPITAL` | `No` |
| 15 | Statewide Health IT for Prior Authorizations | $6,420,000 | Health IT vendor, TBD | `IN_KIND_BENEFIT` | `No` |

**The three lines total $10,105,200 — the shortfall the workbook predicted
before anyone could open the document, to the dollar.** And the new captured
total, $143,187,467.48, is the narrative's own **Contractual** line exactly.
Two independent closures on a figure derived from a document nobody could read.

```
OK  ALLOCATED_ONLY   RECONCILED   91.7%  (204,900,000 of 223,476,949)
DE  TOTAL_INCLUSIVE  RECONCILED   91.0%  (143,187,467 of 157,394,964)
```

**Delaware is out of quarantine and publishable.** The remaining 9.03% is state
admin ($1,079,227.17) plus indirect ($13,128,269.21), which sit outside the
initiative lines by construction — the remainder is now *exactly* those two.

**Delaware's hospital-directed share moves 15.7% → 14.6%, and nothing was
re-coded.** Initiatives 13–15 add $10.1M of denominator and no numerator:
Initiative 12 (Training Programs for Clinical Support Roles, $20,910,000)
remains the state's only hospital-directed line. Unclear moves 24.5% → 22.8%.
**14.6% is the figure to quote** — it is the one computed over all 15
initiatives. §0.1b's finding is untouched: the OK/DE spread is still threefold
and still must not be averaged.

**Initiative 15 is `IN_KIND_BENEFIT`, not `NON_HOSPITAL`.** The vendor receives
the money, but the narrative names *health systems, FQHCs, and rural providers*
as the parties integrated and onboarded, "with priority given to rural
healthcare organizations." That is §10.2's in-kind test met on its own terms,
and the code exists so those dollars stay visible to AHA's narrative rather than
disappearing into a generic non-hospital bucket. It changes no total —
`has_hospital_recipient` is `No` either way. *Worth a look:* Initiative 7
(Catalyst Fund for Telehealth, $5M, "direct awards to technology companies") is
the closest existing row and is coded `NON_HOSPITAL`. It was left alone — it is
committed hand coding and re-coding initiatives 1–12 was outside this task — but
the two rows are arguably the same case.

**The recipient string had to follow the workbook's quoting convention.**
Written plainly, `Statewide Health IT Infrastructure Vendor TBD` derives as
`NAMED + TBD`: the derivation reads the role label as an organisation, which is
the §6.1 `PROGRAM_NAME_AS_AWARDEE` error in a new place. The workbook already
quotes such labels for exactly this reason, so the row is written
`'Statewide Health IT Infrastructure Vendor' - Contractor TBD` and derives
`TBD`. Derivation fidelity stays 17 of 17 Delaware rows. Delaware now names a
recipient for **5 of 15** initiatives, not 4.

**Ten test assertions pinned Delaware's truncated state and were updated**
(row count, captured total, NAMED count, gate result, both §0.1b shares, the
remainder). The suite is **520 assertions, all passing** (was 516). Two tests
were restructured rather than deleted: *"the gate catches a truncated
extraction on its own"* now reproduces the condition by filtering initiatives
13–15 out of the fixture — the gate's ability to catch a short parse is the
reason this stage sits ahead of Stage 4 and had to stay under test — and
*"Delaware reconciles once initiatives 13–15 are added"* becomes a direct
assertion on real data instead of a synthetic row.

### Session 9 — Georgia Year 1 complete, and the trigger list built

Full detail: `docs/georgia_great_health_year1.md`,
`docs/stage00_cms_press_monitor.md`. Zero RCJ quota; four calls to
`dch.georgia.gov`.

**Georgia is the second complete Deliverable 1 dataset, and the first assembled
in the repo.** All four GREAT Health phases are extracted — the fourth was
announced the day before this session — into `GA_year1_awardees.xlsx` via
`R/03d_ga_great_health.R`, with the four DCH announcements archived verbatim
under `data/evidence/GA/`.

| Phase | Date | Awarded | |
|---|---|---:|---|
| 1 | 2026-06-08 | $12,730,000 | 5 named awardees |
| 2 | 2026-07-16 | $30,600,000 | initiatives 2–5 |
| 3 | 2026-07-23 | $60,487,500 | 80 AHEAD hospitals at $750,000 |
| 4 | 2026-08-27 | $93,330,827 | all five initiatives, Year 1 committed |
| | | **$197,148,327** | 12 initiative pools, 54 award actions |

**Georgia publishes an amount per INITIATIVE, not per recipient.** So
`initiative_amount` is on every row and `amount` on only 2 of 54. Nothing is
divided (§6.2), and **summing `amount` gives $60.5M for a state that awarded
$197.1M** — `rhtp_ga_reconcile()` sums distinct `(phase, initiative)` pools
instead, an assertion hard-fails the wrong total, and a test pins the trap open.

**Two independent closures, neither arranged.** The 12 pools leave a residual of
**9.92%** of the $218,862,169.63 CMS award, against DCH's own separate statement
that administrative costs are *"less than 10% of Year 1's funding"*. And Phase
3's 80 hospitals × a stated $750,000 = $60,000,000, which is the stated
Initiative 1 pool to the dollar.

**§0.3a fired twice, and both times the answer was the recipient.** Phase 2
awards school-based health infrastructure to the **Georgia Department of
Education**; Phase 4 awards *Building Bridges (School-Based Health Care Services
Infrastructure)* to **Emory University**. Both `NON_HOSPITAL`. Delaware's
identical activity is `DIRECT` because Beebe Healthcare received it. This is the
§10.2 row that `9fdc156` fixed and `219d803` reverted, meeting real data twice
in one state.

**§0.3 fired once, cleanly.** Phase 4's Type 2 ambulances are ones *"select
rural hospitals will be eligible to apply for soon"* — eligibility, not receipt.
`Unclear`, `PASS_THROUGH_UNRESOLVED`, and not imputed.

**DCH's own Phase 2 count does not match its own page.** The headline says 26
organizations; the names printed enumerate to 28 award actions across 27
distinct organizations. Reported on the Reconciliation sheet and pinned by an
assertion, **not** closed by dropping a name — guessing which of the 27 DCH did
not mean to count would be an invention.

**The single largest finding is one nobody can read yet.** Georgia awards AHEAD
pre-implementation money to **87 rural hospitals**, at **$750,000 each for the
eighty DCH states that figure for — $60,000,000**, more than Florida's entire
hospital total. The roster is on `greathealth.georgia.gov`, which is not
allowlisted, so the cohorts are two aggregate rows with
`recipient_confirmed = No`: the class is confirmed, the names are not captured,
nothing is imputed. Open blocker 5.

> *Session 9 wrote $65.25M here, assuming 87 × $750,000. DCH states the figure
> for eighty hospitals only, so the confirmed figure is $60,000,000 — corrected
> in Session 10, see the note below. Both the host block and the unnamed roster
> are also resolved there.*

**Stage 00, the trigger list, is built and scheduled but has never run.**
`R/00_cms_press_monitor.R` parses the CMS RHTP resources page into
`data/reference/cms_state_announcements.csv` and reports which states are new
since the last run. `medicaid.gov` is not allowlisted — both routes refused at
CONNECT (403) — so it has never seen the live page. That shaped it: the parser
resolves columns by synonym, scores candidate tables, handles a table and a link
list, and **refuses** on a tie, on unresolvable columns, on a state outside the
§7.1 fifty, and on a zero-row parse. A fetch failure writes nothing, because an
empty CSV would read as *"no state has announced an award."*

Like RCJ, it is a **discovery** source (§0.1) — and its `amount` column is never
summed, because the page mixes Tier 1 allotments with Tier 3 subawards (§0.2).
An assertion enforces that, mostly so the comment beside it is unmissable.

Wired to the twice-weekly cadence as Routine `trig_01EozMStALcrUp75s32qFnJ3`,
Mondays and Thursdays 13:00 UTC, first run 2026-08-31. While the host is
blocked it reports that in one line and stops.

**Tests: 627 assertions, all passing** (was 520) — 46 for stage 00 against five
fixtures covering both shapes and three refusals, 61 for Georgia.

### Session 10 — Georgia's 87 hospitals named, the trigger list live, §8 settled

Full detail: `docs/session10_roster_live_monitor_recipient_type.md`. Zero RCJ
quota; one call to `greathealth.georgia.gov`, one to `www.medicaid.gov`.

**Georgia's 87 AHEAD hospitals are named.** The host was allowlisted, so the
roster both DCH announcements link to is archived at
`data/evidence/GA/2026-08-28_value_based_care_hospital_list.html` with a SHA-256
manifest, and `rhtp_ga_ahead_roster()` parses the 87 names out of the committed
archive — parsed, never transcribed, the §7.1 posture. Georgia goes from 54
award actions to **139**, and every one of the 87 is `recipient_confirmed = Yes`.
**The reconciliation is untouched: $197,148,327 awarded, 9.92% residual.**

**The page's heading says "Hospitals With Completed Applications", and it is
still an award source.** Read alone it is an eligibility list and §0.3 forbids
coding it `Yes`. It is not read alone: Phase 3 calls this exact url *"the list of
80 awarded hospitals"* and Phase 4 calls it the full list of the 87. The award,
the count and the per-hospital figure come from the announcements; the page
supplies only the names. Every hospital row cites both documents, and neither
supports the coding on its own.

**Which 80 of the 87 carry the stated $750,000 is an inference, and is flagged.**
DCH states the figure for the Phase 3 eighty and never restates it in Phase 4,
and the roster does not label phases. Rows 1–80 are in exact alphabetical order
and row 81 breaks it, leaving precisely 7 appended at the end — the shape a page
updated in place takes. The parser *derives* that break and **refuses if the
leading run is not 80**, so a re-sorted page fails loudly rather than attributing
$750,000 to a hospital DCH never named a figure for. The seven carry
`PHASE_ATTRIBUTION_INFERRED` and no amount (§6.2). `archive.org` is not
allowlisted, so the July snapshot that would settle it as fact is unreachable.

> **$65.25M was the wrong number to carry, and this is why.** It assumed 87 ×
> $750,000. DCH states $750,000 for eighty hospitals only. **The confirmed,
> named, hospital-directed figure is $60,000,000** — which closes on the stated
> Initiative 1 pool to the dollar. The other seven are awarded and named; their
> amount is simply not published.

**Stage 00 has run against the live CMS page. Eight states have announced: AK,
AL, GA, ND, OH, PA, SD, WV.** Akamai fronts `medicaid.gov` and returns 403 to a
user agent carrying no contact URL — **including to a spoofed browser UA, which
is also refused.** The `+url` form is the well-behaved-crawler convention and is
what gets through, so `api$user_agent` now carries it. Identifying honestly is
the fix, not a workaround.

**The live page then exposed a failure mode the fixtures could not.** Its header
row is marked up with `<td>`, not `<th>`, so `html_table()` named the columns
`X1..X5`, every synonym lookup missed, the table scored 0, and the parser fell
through to the link-list shape — which **did not fail; it succeeded with less**:
no dates at all, and the state read by matching a state name in the headline
rather than from the page's own State column. Every refusal in that parser guards
against parsing the *wrong* thing. This was the other kind: parsing the right
thing less well, silently. `cms_press_promote_header()` promotes such a row, and
only when that resolves strictly more columns, so it can never make a working
parse worse.

Reaching the table shape then surfaced two rows the link-list shape had been
dropping by luck: CMS lists its national announcements (the $50bn launch, the
all-50-states award) in the same table with `State = "All"`. Those are Tier 1
(§0.2) and this is the *state* trigger list, so they are excluded deliberately
with the count reported. **One closure, unarranged:** CMS announces $93.3M for
Georgia on 2026-08-27; DCH's Phase 4 announcement the same day totals
$93,330,827. Two publishers, one figure — still a discovery source (§0.1).

**The §8 `recipient_type` question is settled, and Florida is ingested.** Florida
wrote `UNCLASSIFIED` and Georgia wrote `NONPROFIT_CBO` + `LOW` +
`RECIPIENT_TYPE_INFERRED` for one question: what the column holds when a
recipient is *named* but its form is not determinable. **Georgia's convention is
adopted**; Florida's five rows are back-fitted.

**`PHYSICIAN_PRACTICE` was a different question and grew the vocabulary.** Those
eight rows are not undetermined — a pediatrics group, a fetal medicine practice
and a primary care clinic are all determinable, and none of the other twelve
values is true of one. `NONPROFIT_CBO` would assert a form the source
contradicts; `VENDOR_OR_CONTRACTOR` would make a provider receiving a grant look
like a supplier to the state. It was **added to §8 deliberately** rather than
folded in. All eight are already `distributed_to_hospital = No`, so no total
moves. This is the one §2 "do not invent codes mid-session" exception, taken as
an explicit decision rather than a default.

`R/03e_fl_year1_awardees.R` reads the owner's workbook, applies the back-fit and
**nothing else**, and writes `data/reference/fl_year1_awardees.csv` as the source
of record. `recipient_type_source` preserves the owner's value on every row, so
the back-fit is auditable and reversible. `determination_confidence` is set only
on the five rows this session judged — Florida's workbook has no confidence
column, and inventing 76 would be the pipeline asserting what the owner never
did. **The two states union: 220 rows, zero values outside §8**, asserted from
both sides.

**Tests: 728 assertions, 727 passing** (was 627).

### Session 11 — where six states publish their awards, and one Wayback wall

Full detail: `docs/session11_six_state_award_list_hunt.md`. Zero RCJ quota; six
calls to `www.cms.gov` (archived), 24 refused to `web.archive.org`.

**`web.archive.org` is allowed but not reachable.** The gateway answers
`200 Connection Established` to the CONNECT and the TLS handshake is then reset
by the peer, before any certificate. Reproduced on every one of 28 curl attempts
over 15 minutes, and on Python `urllib`, `openssl s_client` and WebFetch, and
the proxy logs **no policy denial** for it — which is exactly what separates
this from a blocked host. The apex `archive.org`, where the `/wayback/available` API lives,
*is* a policy denial (`connect_rejected`, 403).

**So Georgia's 80/7 split is still an inference and nothing was changed.**
`PHASE_ATTRIBUTION_INFERRED` stays on the seven appended rows and the roster
parser still refuses if the leading alphabetical run is not exactly 80. Worth
re-testing: the failure was upstream of the policy, so it may clear on its own.

**The six announced states with no extraction — none of their hosts is
reachable, so no extractor was built.** All ten candidate hosts refused at
CONNECT. The locator report was assembled from the committed RCJ pull, the six
CMS state press releases (fetched and archived this session under
`data/raw/cms/2026-08-28/state_press_releases/` with a SHA-256 manifest), and
search for the URL of record.

| | Recipient-level list? | Where | RCJ rows | Stated |
|---|---|---|---:|---|
| **PA** | **Yes, complete** | `pa.gov` DHS newsroom | 66 / 66 distinct / $42,198,310 | $42,198,309, 66 projects |
| **AL** | **Yes, complete** | governor's 2026-08 release | 138 / 94 distinct / $143,745,821 | >$144M, 138 grants |
| **AK** | **Yes, rolling** | `ak_rhtp_awardsnotice_2026.xlsx` | 161 / 102 distinct / $160,702,462 | $160M, 142 projects |
| **SD** | **Awarded, list not located** | `doh.sd.gov`; contracts to `open.sd.gov` | 1 (a pool name) | 82 orgs / $90M; 28 projects / $31.5M |
| **OH** | **No** — one named award | governor's release | 1 (Ohio University $10M) | — |
| **ND** | **No** — solicitation stage | `hhs.nd.gov` funding opportunities | 1 (`"15 selected CAHs"`) | — |

**Pennsylvania is the cleanest state found so far.** 66 RCJ rows, 66 distinct
awardees, and $42,198,310 against DHS's stated $42,198,309 — one dollar of
rounding, and the count matching exactly. Alabama's 138 rows equal the 138
grants both the governor and CMS state. Those two are Deliverable 1 states 3
and 4 the moment their hosts open; each is a single page.

**Alaska's counts do not agree and that is left open.** 161 RCJ rows against
CMS's "142 projects", with the dollars agreeing to 0.4%. Likely one line per
activity type with projects spanning several, but that is a hypothesis about a
file nobody has read. Alaska also publishes **notices of intent to award**, not
notices of award — both primary under §8, and the distinction belongs in
`validation_source_type` rather than being flattened.

**South Dakota is the highest-value unresolved state.** 82 organizations at $90M
and 28 projects at $31.5M are already awarded and RCJ caught neither — it holds
one row, `"South Dakota Rural Strong Grants"`, which is a pool name and would
tier `SOLICITATION`. The reporting says contracts post to the state transparency
portal once finalised, so `open.sd.gov` is the route, and it is an unusual one
for this project: a contracts register rather than a press release.

**Ohio and North Dakota have published no recipient-level list**, and the §0.3
distinction is what says so. Ohio's $92M Innovation Hubs pool is still the
spec's own Tier 2 worked example; ND's one RCJ "award" is `"15 selected CAHs"`,
a class rather than a recipient, and a textbook `PASS_THROUGH_UNRESOLVED`.
Publicly described ND pipelines (~20 hospital awards of ~$2M, $3.6M in school
and community grants) are forecast counts, not awards.

**None of the RCJ sums above is a finding (§0.1).** They are a coverage signal:
where RCJ's row count lands on the state's own stated count, the state document
is recipient-level and worth extracting once reachable. Where RCJ has one row,
the CMS releases and the press — not RCJ — are what distinguish "the state has
published nothing" (ND, OH) from "RCJ missed a list that exists" (SD).

**Georgia's hospital-directed figure is $60,000,000 everywhere.** `$65.25M` no
longer appears as a carried figure. Verified rather than asserted:
`ga_great_health_awards.csv` holds exactly 80 rows at $750,000, and
80 × $750,000 = $60,000,000, closing on the stated Initiative 1 pool to the
dollar. `--validate` passes unchanged — 139 award actions, $197,148,327,
9.92% residual. The four surviving occurrences of the string are the correction
record itself, each stating the figure was wrong and giving $60,000,000;
deleting those would erase the audit trail, which is §2.1 in miniature.

### Session 12 — Pennsylvania, Alabama and Alaska extracted; South Dakota located

Full detail: `docs/session12_pa_al_ak_extraction_and_sd.md`. Zero RCJ quota.

**Five hosts opened and four states came out of them.** Deliverable 1 goes from
two states to six, and the four new ones are in the table above. Each carries a
distinction that must not be flattened into a summary: Pennsylvania's awards are
**authorized, not disbursed** (DHS: *"distribution is pending approval"*);
Alaska's are **notices of intent with preliminary amounts** (its own sheet name
and its own column header say so); 45 of Alabama's 138 amounts are **rounded in
the source**; South Dakota's zero is because **its awards are not published**.

**Pennsylvania is Georgia's AHEAD-roster shape again.** The announcement supplies
the award language and names no recipient; the program page supplies the names
and its own heading reads *"List of Eligible Projects"*, which §0.3 forbids
reading as receipt on its own. The announcement links to that page as the list of
what it just authorized, so every row cites both — and 66 rows sum to
$42,198,309.80 against DHS's stated $42,198,309.

**Alabama's list is prose with two shapes, and both failure modes are silent.**
Where a recipient won twice under one initiative, the second grant is a bare `<p>`
that names no recipient. Reading only the list items loses **14 award actions and
$8.1M**; reading every block as an award invents 14 nameless recipients. The
parser carries the recipient forward and an assertion requires every second grant
to sit against a first grant *for the same recipient under the same initiative*.

**Alabama's own figures sum to less than its own headline, and that is reported
rather than closed.** $143,745,821 against *"more than $144 million"* — the
$254,179 gap is the source's rounding. Nothing is reconstructed to a precision
nobody published. The release also prints one name truncated — its markup reads
`<strong> Clair Community Health Clinic Inc.</strong>`, the `St.` absent from the
**source** — and §8 says keep the state's own language, so it is stored as
published and the observation is recorded rather than silently corrected.

**Alaska's 161-vs-142 gap is closed at the source, and session 11's hypothesis
was wrong.** It is not one line per activity type. It is Alaska's own Project
Type column: **142 Implementation + 19 Planning = 161**, and CMS counts the
implementations. The file's own App ID prefix corroborates it independently
(`BP1-PL` on exactly 19 rows). Two assertions hold it: the identity itself, and
that the prefix and the column agree on every row.

**Alaska classifies its own awardees and that outranks the name — which saved a
bad coding immediately.** *"Alaska Hospital & Healthcare Association"* reads as a
hospital from its name alone and is the state hospital association. But the field
is set per **project**, not per organisation, and **seven awardees arrive with two
different forms across their own rows** — ANTHC is `Hospital (all types)` on one
project and `Tribal Health Organization` on another. The per-row value is kept and
**not harmonised in either direction**: upward would move **$20.4M** into the
hospital total on this pipeline's authority rather than the state's; downward
would discard the state's own word. 26 rows carry
`RECIPIENT_TYPE_VARIES_IN_SOURCE` and the dollars are on the Reconciliation
sheet. **This is the largest open judgement the session leaves.**

**South Dakota: the portal is the right route and the awards are not on it.**
`open.sd.gov` is an ASP.NET WebForms search — POST with `__VIEWSTATE`, one unpaged
result table with descriptions truncated to ~75 characters, and a stable GET
detail page per row carrying the full text. Four probes (`--probe` re-runs them)
establish the negative: the `RHT` series is 13 contracts and $5,618,367, all
administrative; *"Rural Strong"* returns **zero rows**; DOH's grants with no
filter at all are 463 rows and $39.4M whose largest single row is $2.6M and is not
RHTP. An 82-organisation $90M round is not in that. The 13 rows are extracted
anyway — they are real primary-source award actions and the extractor is then
ready — with four guards keeping the small number attached to its explanation,
including an assertion that **hard-fails if the series ever exceeds $20M**,
because at that point the file's framing is wrong and must be rewritten.

**The §8/§10.2 rules now live in one file**,
`R/utils_recipient_classification.R`. The §8 question had to be settled twice
already; four states at once would have given it a fifth answer. Rules match the
recipient **name only** (§0.3a), **whole string including the DBA half** — which
is what makes *"The City of York Health Care Authority DBA Hill Hospital of Sumter
County"* a hospital and not a city. Two overrides exist specifically to stop
**inflation**: `AltaPointe Health Systems` and `CarePath Behavioral Health` would
read as hospital systems from a word in their names, and whether the entity that
received those grants is AltaPointe's hospital operator is exactly what the
release does not say.

**The in-kind rule was under-firing and was rewritten.** It was a list of
phrasings, and Alaska's *"statewide AI imaging network across 21 acute care
hospitals"* came out `NON_HOSPITAL` — the source saying the opposite of silence.
Any hospital mention by a non-hospital recipient is now `IN_KIND_BENEFIT` unless
the narrower pass-through test fires first. **No distributed total moves either
way**; what changes is that those dollars stay visible, which is why §10.2 has the
code.

**One provenance defect fixed, one left alone deliberately.** Manifests digest the
body the server sent, and `writeLines()` appends a trailing newline — so the
archived file was one byte longer than what was hashed and a reader verifying an
archive would get a mismatch. The four new states `writeBin()` exact bytes and a
test in each re-hashes the file on disk. **The same off-by-one is in the GA and
CMS archives from earlier sessions**; they are not re-fetched here, because
re-fetching to fix a digest could quietly pick up changed page content. Worth
doing deliberately, with a diff, in a session that can check what came back.

**Tests: 997 assertions, all passing** (was 728). `test_state_union.R` is new and
is the one that would have caught session 10's problem before someone tripped
over it: it combines all six states every run.

### Next session

**The two offline tasks are now the only thing between here and Stage 4.**

1. **Verify the registry** (~2 hours, §7.2) — still the hard gate (§13.12). Work
   `data/reference/state_source_registry_worksheet.csv` (or the formatted copy at
   `output/state_source_registry_worksheet_2026-08-27.xlsx`) down to 50 confirmed
   rows in `data/reference/state_source_registry.csv`. Load each URL and set
   `last_verified`. **Florida first.** While in each state's pages, capture the
   budget narrative URL for §7A.2. Check with `Rscript R/03_state_registry.R --validate`.

2. **Widen the egress allowlist — Session 11's Tier 3 queue is done, and the
   remainder is re-ranked.** `www.pa.gov`, `governor.alabama.gov`,
   `health.alaska.gov`, `doh.sd.gov` and `open.sd.gov` all opened for Session 12
   and all four states are extracted. What is left, in order:
   **`news.sd.gov`** — both South Dakota award announcements, **110 named
   recipients and $121.5M**, and the largest block of named recipients this
   project knows of and cannot read;
   **`adeca.alabama.gov`** / **`alabamarhtp.com`** — ADECA's own award file,
   which turns Alabama's 45 rounded amounts exact and closes its $254,179 gap;
   **`web.archive.org` + the apex `archive.org`** — re-tested in Session 12 and
   unchanged (TLS reset with no policy denial on the first, `connect_rejected`
   403 on the second), still the only route to Georgia's July roster snapshot.
   For §7A.2, **Oklahoma next** — the other reference state, and the only one of
   the two whose narrative is still unarchived. 48 state health department hosts
   are still blocked and §7A.2 needs fifty. `odh.ohio.gov` and `www.hhs.nd.gov`
   are worth having for §7.3 registry verification but have no Tier 3 list yet.

**Then §7A.2 collection** — 48 states to go. Bounded and checkable in a way
nothing sourced from RCJ is: you know when you have all fifty. Each narrative
lands under `data/evidence/budget_narratives/<state>/`, and
`Rscript R/03b_budget_narratives.R --build` reconciles it the moment its
extraction exists. Build `data/reference/budget_narrative_status.csv` as part of
that pass.

**Then Stage 4** — and **not before the §7.3 registry is verified.** Document
clustering (§9.2), fetcher with §9.5 conduct rules, split-confirmation
corroborator (§9.3). Requires **Full** network access — clear with AHA IT first.

**What Sessions 10–12 set up for whoever does Stage 5.** The §8
`recipient_type` question is settled, the rules live in one file
(`R/utils_recipient_classification.R`), and all six states union cleanly, so the
column can be keyed off safely. And there are now **200 hospital recipients**
waiting on a CCN match — Georgia's 87 plus PA's 27, AL's 60 and AK's 26 — which
makes the **AHA Annual Survey / CMS Provider of Services extracts** (blocker 5)
the binding constraint outright. Until they land, every
`determination_confidence` in the project is capped at `MEDIUM` (§7).

**One judgement Session 12 deliberately left to a human:** Alaska's seven
awardees whose organisational form varies across their own rows, **$20.4M** that
a reviewer could move into the hospital total. Flagged
`RECIPIENT_TYPE_VARIES_IN_SOURCE`, quantified on the Reconciliation sheet, and
not resolved by the pipeline in either direction.

`qa_assertions.R` is still unbuilt and is now the only stage with no file at all.

### Re-running what exists

```
Rscript tests/run_tests.R                        # 997 assertions, zero quota
Rscript R/02_normalize.R --run                   # newest pull on disk (logged PRODUCTION)
Rscript R/02_normalize.R --run --dev             # an iteration, logged DEV (§5.2)
Rscript R/02_normalize.R --run --date=2026-08-27 # a specific pull
Rscript R/03_state_registry.R --allotments       # §7.1, one call to cms.gov
Rscript R/03_state_registry.R --worksheet        # §7.2, offline
Rscript R/03_state_registry.R --validate         # §7.3, once the registry lands
Rscript R/03b_budget_narratives.R --validate     # §7A parse + assert, no writes
Rscript R/03b_budget_narratives.R --build        # §7A.4 gate, writes data/interim/
Rscript R/03c_cms_abstracts.R --validate         # §4.1 assertions, offline
Rscript R/03c_cms_abstracts.R --build            # renders abstract_named_organizations.xlsx
Rscript R/03d_ga_great_health.R --validate       # GA assertions + reconciliation, offline
Rscript R/03d_ga_great_health.R --build          # writes GA csv + GA_year1_awardees.xlsx
Rscript R/03e_fl_year1_awardees.R --ingest       # owner's FL workbook -> committed CSV
Rscript R/03e_fl_year1_awardees.R --validate     # FL §8 vocabulary assertions, offline
Rscript R/03e_fl_year1_awardees.R --build        # renders FL_year1_awardees.xlsx
Rscript R/03f_pa_year1_awardees.R --fetch        # PA: archive both sources + SHA-256
Rscript R/03f_pa_year1_awardees.R --validate     # PA assertions + reconciliation, offline
Rscript R/03f_pa_year1_awardees.R --build        # writes PA csv + PA_year1_awardees.xlsx
Rscript R/03g_al_year1_awardees.R --fetch        # AL: archive the governor's release
Rscript R/03g_al_year1_awardees.R --validate     # AL assertions, offline
Rscript R/03g_al_year1_awardees.R --build        # writes AL csv + AL_year1_awardees.xlsx
Rscript R/03h_ak_year1_awardees.R --fetch        # AK: archive the DOH award-notice xlsx
Rscript R/03h_ak_year1_awardees.R --validate     # AK assertions + the 142/19 split, offline
Rscript R/03h_ak_year1_awardees.R --build        # writes AK csv + AK_year1_awardees.xlsx
Rscript R/03i_sd_rht_contracts.R --probe         # LIVE: is the announced round posted yet?
Rscript R/03i_sd_rht_contracts.R --fetch         # SD: archive the search + 13 detail pages
Rscript R/03i_sd_rht_contracts.R --validate      # SD assertions, offline
Rscript R/03i_sd_rht_contracts.R --build         # writes SD csv + SD_rht_contracts.xlsx
Rscript R/00_cms_press_monitor.R --status        # what the CMS trigger list says
Rscript R/00_cms_press_monitor.R --run           # live; medicaid.gov allowlisted
Rscript R/00_cms_press_monitor.R --parse         # re-parse newest archive, no network
```

Stage 2 is idempotent against the same pull. Stage 3's `--allotments` reuses the
committed archive unless `--force` is passed. Stage 2.5 picks up any
`<ST>_initiative_table.xlsx` at the repo root or under
`data/reference/initiative_tables/`, so a new state's extraction needs no code
change. Stage 3c renders from `data/reference/abstract_named_organizations.csv`
— edit the CSV, never the workbook.

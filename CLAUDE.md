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
  01_retrieve_rcj.R            # Stage 1 — retrieval (BUILT)
  02_normalize.R               # Stage 2 — normalization + §6.4 mining (BUILT)
  03_state_registry.R          # Stage 3 — CMS allotments + registry (BUILT)
  03b_budget_narratives.R      # Stage 2.5 — §7A initiative table + §7A.4 gate (BUILT)
  03c_cms_abstracts.R          # CMS project abstracts — §4.1 candidate list (BUILT)
  04_validate.R                # Stage 4 — queue manager + rule engine (NOT YET BUILT)
  05_hospital_determination.R  # Stage 5 (NOT YET BUILT)
  06_build_workbook.R          # Stage 6 (NOT YET BUILT)
  qa_assertions.R              # (NOT YET BUILT)
  utils_config.R               # config, paths, credentials, state vocabulary (BUILT)
data/
  raw/                         # IMMUTABLE — COMMITTED
    rcj/<pull_date>/*.json     #   the RCJ landing zone
    cms/<fetch_date>/*.html    #   the §7.1 allotment table, verbatim + digest
    cms/<fetch_date>/*.pdf     #   the CMS project abstracts, verbatim + SHA-256
  interim/                     # normalized .rds/.csv; review_queue.rds — COMMITTED
  reference/                   # allotment anchor, registry, controlled vocabs
  evidence/                    # <state>/<record_id>_<date>.pdf — COMMITTED
    budget_narratives/DE/      #   §7A.2 — DE narrative + SHA-256 manifest; 49 to go
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

**Last updated:** 2026-08-27 (Session 8 — Delaware initiatives 13–15 extracted; DE RECONCILED)

### Stages built

| Stage | File | Status |
|---|---|---|
| Scaffold / config | `config/config.yml`, `R/utils_config.R` | **Built** |
| Stage 0 — Preflight | `docs/stage0_preflight_findings.md` | **Complete** |
| Stage 1 — §5.1 pagination test | `docs/stage1_pagination_test.md` | **Complete — Branch A confirmed (§8)** |
| Stage 1 — Retrieval | `R/01_retrieve_rcj.R` | **Built and run. First national pull complete — `docs/stage1_retrieval_run.md`** |
| Stage 2 — Normalization | `R/02_normalize.R` | **Built. Allotment anchor live; §6.4 mining; §0.2a Tier 1 corroboration; §6.2 multi-recipient split — `docs/stage2_normalization_run.md`, `docs/stage3_allotments_and_registry.md`, `docs/corrections_after_session5.md`** |
| Stage 3 — Allotments + registry | `R/03_state_registry.R` | **Built and run. §7.1 anchor committed; §7.2 worksheet exported. §7.3 registry awaits offline verification — `docs/stage3_allotments_and_registry.md`** |
| Stage 2.5 — Budget narratives | `R/03b_budget_narratives.R` | **Built and run. Format-detecting parser + the §7A.4 gate. 2 of 50 states extracted; OK and DE both `RECONCILED` and publishable (Session 8) — `docs/stage2.5_budget_narratives.md`** |
| CMS project abstracts | `R/03c_cms_abstracts.R` | **Built and run (Session 7). All 50 states extracted, 120 CANDIDATE_ONLY organizations — §4.1** |
| Stage 4 — Validation | `R/04_validate.R` | Not started. **Gated on the verified §7.3 registry.** Do not start it before that. |
| Stage 5 — Hospital determination | `R/05_hospital_determination.R` | Not started |
| Stage 6 — Workbook | `R/06_build_workbook.R` | Not started |
| QA assertions | `R/qa_assertions.R` | Not started |
| Tests | `tests/testthat/test_01_retrieve_rcj.R`<br>`tests/testthat/test_02_normalize.R`<br>`tests/testthat/test_03_state_registry.R`<br>`tests/testthat/test_03b_budget_narratives.R`<br>`tests/testthat/test_03c_cms_abstracts.R` | **Built — 44 + 276 + 70 + 90 + 40 = 520 assertions, all passing, zero quota. Run `Rscript tests/run_tests.R`** |

### States validated

None. No state has been through Stage 4 validation.

Pilot set (spec §14), none started: Georgia, Virginia, Nebraska, Florida, Texas.

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
- `data/reference/vocabularies.csv` — now carries the §7A codes as well
  (`recipient_status`, `reconciliation_structure`, `reconciliation_status`,
  `extraction_method`, `recipient_confirmed`, `amount_confirmed`,
  `has_hospital_recipient`, `initiative_grain`, `validator`). Read it through
  `rhtp_vocabulary()` — the single reader, in `utils_config.R`.
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

**Quota: 1,920 of 2,000 remaining** (80 consumed this month; Session 5 spent
none — the only network call was to `cms.gov`).

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
3. **The other 49 state health-department hosts are still not on the
   allowlist.** `dhss.delaware.gov` was added for Session 8 and Delaware is
   done, but §7A.2 needs fifty such hosts and only one is reachable. Widen the
   allowlist (Claude Code on the web → environment settings → network access)
   before the collection pass, or it will stall one state at a time.
4. **Delta-pull strategy still needs a decision.** No `since` on the award or
   document endpoints, so hashing is the only Tier 3 change detection (§4.1).
   The remaining question is whether `/activity` narrows to a `since=` delta
   after this first backfill (45 calls/pull) or keeps being pulled
   comprehensively (60 calls/pull). Both are affordable.

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

### Next session

**Two offline tasks still come first:**

1. **Verify the registry** (~2 hours, §7.2). Work
   `data/reference/state_source_registry_worksheet.csv` — or the formatted copy
   at `output/state_source_registry_worksheet_2026-08-27.xlsx` — down to 50
   confirmed rows in `data/reference/state_source_registry.csv`. Load each URL
   and set `last_verified`. **Florida first.** While in each state's pages,
   **capture the budget narrative URL for §7A.2.** Check the result with
   `Rscript R/03_state_registry.R --validate`.
2. **Widen the egress allowlist before the collection pass.**
   `dhss.delaware.gov` is now allowlisted and Delaware is complete; every other
   state health department host is still blocked. §7A.2 needs fifty of them.
   Oklahoma next — it is the other reference state, and its narrative is the
   only one of the two still unarchived.

**Then §7A.2 collection** — 48 states to go (49 narratives still unarchived; only Delaware's is on disk). It is bounded and checkable in a
way nothing sourced from RCJ is: you know when you have all fifty. Each
narrative lands under `data/evidence/budget_narratives/<state>/`, and
`Rscript R/03b_budget_narratives.R --build` reconciles it the moment its
extraction exists. Build `data/reference/budget_narrative_status.csv` as part
of that pass — it records what was searched and when, so it cannot be seeded in
advance.

**Then Stage 4** — and **not before the §7.3 registry is verified.** Document
clustering (§9.2), fetcher with §9.5 conduct rules, split-confirmation
corroborator (§9.3). Requires **Full** network access — clear with AHA IT
first — and the AHA Annual Survey / CMS Provider of Services extracts committed
before the hospital determination session.

`qa_assertions.R` is still unbuilt. §13.25 and §13.27 are already satisfied by
the code and only need asserting.

**Two files landed from the owner that no stage reads yet.** `DE Verify.xlsx`
is the §9.11 premise-test evidence — 11 hand-verified Delaware records, and the
`hospital_yn` column is still the pre-§0.3a coding, so Beebe, TidalHealth and
Nemours read `no` in it. `FL_year1_awardees.xlsx` is 81 Florida Year 1 awards
with recipient-level amounts, the first complete Deliverable 1 dataset and the
answer to the §4.1 Florida gap. Note before ingesting it: its `recipient_type`
column uses `PHYSICIAN_PRACTICE` and `UNCLASSIFIED`, neither of which is in the
§8 vocabulary, so either the vocabulary grows or those 13 rows are re-coded.

### Re-running what exists

```
Rscript tests/run_tests.R                        # 520 assertions, zero quota
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
```

Stage 2 is idempotent against the same pull. Stage 3's `--allotments` reuses the
committed archive unless `--force` is passed. Stage 2.5 picks up any
`<ST>_initiative_table.xlsx` at the repo root or under
`data/reference/initiative_tables/`, so a new state's extraction needs no code
change. Stage 3c renders from `data/reference/abstract_named_organizations.csv`
— edit the CSV, never the workbook.

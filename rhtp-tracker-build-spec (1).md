# RHTP Hospital Funding Tracker — Build Specification

**Owner:** Isaac, AHA Data & Policy
**Objective:** Identify and quantify Rural Health Transformation Program (RHTP) funds being distributed to hospitals, by state, with every figure traceable to a primary state source.
**Stack:** R (tidyverse), `%>%` pipe only. Excel deliverable via `openxlsx`.
**Build environment:** Claude Code on the web (cloud sessions). See §3 for the constraints this imposes — several design decisions below exist because of them.

---

## 0. Read this section before writing any code

Four principles govern every design decision below. If a later instruction seems to conflict with one of these, the principle wins.

### 0.1 Rural Care Journey (RCJ) is a discovery layer, not a source of record

RCJ is a commercial aggregator operated by AME Mobile. Its own site states it is not affiliated with CMS/HHS/HRSA, that data is aggregated from public sources, and that accuracy is not guaranteed. Observed extraction defects include: non-RHTP records in the RHTP feed, page navigation text captured as document titles, unrelated state press releases bleeding into event-schedule fields, and awardee-level coverage that is complete in some states and empty in others.

RCJ's job in this system is to tell us **where to look and when something changed**. The authoritative record for every published figure is the state notice of award or equivalent primary document. No RCJ field may appear in an AHA-published number without independent state-source validation.

### 0.2 The three-tier rule

RHTP money moves CMS → state → subrecipient. RCJ mixes all three tiers in a single amount field. Every record must carry an `award_tier` before any other processing:

| Tier | Code | What it is | Example |
|---|---|---|---|
| 1 | `STATE_ALLOTMENT` | CMS award to a state | Missouri FY2026, $216.0M |
| 2 | `SOLICITATION` | State-announced funding pool / NOFO budget | Ohio Rural CIN & Innovation Hubs, $61.7M |
| 3 | `SUBAWARD` | Executed or intended award to a named recipient | GA Dual Track Remote Critical Care, $900K to 4 rural hospitals |

**Only Tier 3 answers the project question.** Tiers 1 and 2 live in separate reference tables, on separate Excel sheets, and are never unioned with Tier 3. Aggregation functions must hard-fail if passed mixed tiers.

### 0.3 Eligibility is not receipt

A solicitation listing hospitals among eligible entities is not evidence that a hospital received money. This is the single most likely source of an inflated, attackable number. Unresolved pass-through pools code as `Unclear`, never as `Yes`.

### 0.4 Evidence-first

A determination without a captured, archived, quotable source is not a determination. Any row with `distributed_to_hospital = Yes` must have a validation URL, a local archived copy, and the confirming sentence stored in the row. QA enforces this.

### 0.5 Committed or gone

This project runs in cloud sessions. Each session gets a fresh VM with the repository cloned; **anything not committed to git disappears when the session ends.** The raw landing zone, the evidence archive, and the review queue are all persistence-critical, so all three are committed rather than gitignored. Any code that writes a file the next session needs must be followed by a commit. This inverts the normal convention of gitignoring data directories — see §1.

---

## 1. Repository structure

```
rhtp-tracker/
├── CLAUDE.md                     # project context for Claude Code (see §2)
├── R/
│   ├── 01_retrieve_rcj.R
│   ├── 02_normalize.R
│   ├── 03_state_registry.R
│   ├── 04_validate.R
│   ├── 05_hospital_determination.R
│   ├── 06_build_workbook.R
│   ├── qa_assertions.R
│   └── utils_*.R
├── data/
│   ├── raw/                      # IMMUTABLE. rcj/<pull_date>/<state>.json
│   ├── interim/                  # normalized .rds
│   ├── reference/                # state registry, controlled vocabs, crosswalks
│   └── evidence/                 # archived state pages: <state>/<record_id>_<date>.pdf
├── output/
│   ├── rhtp_hospital_tracker_<date>.xlsx
│   └── review_queue_<date>.xlsx
├── logs/
│   └── pull_manifest.csv
└── config/
    └── config.yml                # base URL, paths, cadence, quota budget
```

### Persistence rules — these differ from normal practice

`data/raw/`, `data/evidence/`, `data/interim/review_queue.*`, and `logs/pull_manifest.csv` are **all committed**. Per §0.5, uncommitted files do not survive a cloud session. Gitignoring the raw landing zone — the usual convention — would silently destroy the audit trail between sessions and make the pipeline non-reproducible.

RHTP JSON across 50 states is a few MB of text and git handles it comfortably. Monitor `data/evidence/` as archived PDFs accumulate; if the repo approaches a few hundred MB, move the archive to shared storage and keep the file paths recorded in the workbook rather than the files themselves.

`.gitignore` should exclude only: `.Rhistory`, `.RData`, `.Rproj.user/`, and `.Renviron` (the last as a safeguard for anyone who later runs this locally).

**Commit discipline:** every stage that writes persistent output ends with a commit. Do not leave a completed pull or a resolved review batch uncommitted at the end of a session.

### Credentials

The RCJ API key lives in the cloud environment's **Environment variables** field as `RCJ_API_KEY`, read via `Sys.getenv("RCJ_API_KEY")`. Never written to a file, never committed, never echoed to logs or console output. The same `Sys.getenv()` call works unchanged if this is later run locally with a `.Renviron`, so no code changes are needed to move between the two.

---

## 2. `CLAUDE.md` contents

Create this first. Claude Code reads it at session start, and it prevents drift across sessions. It should contain:

- The five principles from §0, verbatim and near the top. Principle 0.5 (committed or gone) matters most for day-to-day behavior.
- Coding conventions: tidyverse; **`%>%` exclusively, never `|>`**; snake_case; explicit `dplyr::` namespacing in package-style functions; no `setwd()`, use `here::here()`.
- The controlled vocabularies from §8 (so codes don't get invented mid-session).
- A short "current state" section listing which stages are built and which states have been validated — update it at the end of each session.
- Standing instructions:
  - Never write code that sums across `award_tier` values.
  - Never print, log, or echo the value of `RCJ_API_KEY`.
  - Never add `data/raw/`, `data/evidence/`, or the review queue to `.gitignore`.
  - Commit persistent output before the session ends.

---

## 3. Cloud environment and dependencies

### 3.1 What cloud sessions do and don't provide

Sessions run on a fresh Ubuntu 24.04 VM (4 vCPU, 16 GB RAM, 30 GB disk) with common toolchains pre-installed — Python, Node, Ruby, PHP, Java, Go, Rust, C/C++, Docker, PostgreSQL, Redis, and utilities including git, gh, jq, and ripgrep.

**R is not among them.** It must be installed by the environment's setup script. There is also no interactive shell for the user: Claude runs every command, so all work is phrased as requests, and changes are reviewed as diffs and merged via pull request.

### 3.2 Network access

The default **Trusted** level reaches allowlisted package registries, GitHub, and cloud SDKs only. Rural Care Journey is not on that list. The environment must use **Custom** access with "also include default list of common package managers" checked, plus:

```
www.ruralcarejourney.com
ruralcarejourney.com
packagemanager.posit.co
cloud.r-project.org
```

Add the RCJ API host separately if Stage 0 reveals it differs from the web domain.

### 3.3 Setup script

**This goes in the cloud environment's Setup script field at claude.ai/code, not in the repo.** The environment script runs once before Claude Code launches and its result is snapshotted, so R persists across sessions. A repo script (`config/setup.sh`) would reinstall R every session and burn several minutes each time — keep it in the repo as the canonical copy if useful, but the environment field is what executes.

The environment's **Allowed domains** must include `archive.ubuntu.com` and `security.ubuntu.com` explicitly, alongside the §3.2 list. These are in the default Trusted set, so a 403 against them means the "also include default list of common package managers" box is unchecked.

Runs once per environment, then the filesystem is snapshotted. **It must exit zero and finish within roughly five minutes** or the cache won't build — which is why this uses precompiled binaries rather than compiling from source. Editing the allowed-domains list invalidates the cache and re-runs the script.

```bash
#!/bin/bash
apt-get update
apt-get install -y --no-install-recommends \
  r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev || true

cat > /usr/lib/R/etc/Rprofile.site << 'EOF'
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
  paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
EOF

Rscript -e 'install.packages(c("tidyverse","httr2","jsonlite","openxlsx",
  "janitor","digest","here","yaml","fuzzyjoin","assertr","testthat"))' || true
exit 0
```

The `HTTPUserAgent` option is what makes the Posit package manager serve Linux binaries instead of source tarballs. Without it the install compiles from scratch and will exceed the time limit.

If the script does time out, trim the package list to `tidyverse`, `httr2`, `jsonlite`, `openxlsx`, `digest`, `here`, `yaml` and install the rest mid-session as needed.

### 3.4 Package notes

`arrow` is deliberately omitted — use `saveRDS()`/`readRDS()` for the interim layer instead of parquet. It's one less heavy dependency in a time-boxed setup script, and the interim layer is only read by this pipeline.

`pagedown`/`chromote` for PDF archiving are also omitted; see §9.0 for why evidence capture happens outside the cloud session.

---

## 4. Stage 0 — Confirmed API surface (completed Session 1)

Verified live against the Pro plan. Base `https://www.ruralcarejourney.com`, all endpoints under `/api/v1/`. Auth via `Authorization: Bearer` or `X-Api-Key`.

**Endpoints:** `/api/stats` (public), `/states`, `/states/:code`, `/awards`, `/documents`, `/documents/:id`, `/opportunities`, `/events`, `/activity`, `POST /search`.

**Three pagination envelopes — handle each separately:**

| Envelope | Endpoints | Max `limit` | Termination |
|---|---|---|---|
| `{data, pagination:{page,limit,total,pages}}` | states, awards, documents, opportunities, events | awards 500; others 100 | `pages` count |
| `{data, count, page, hasMore}` | activity | 100 | `hasMore` loop — `count` is page length, **not** grand total |
| `{documents, count, hasMore, aiAnswer}` | search | 50 | `hasMore` loop |

**Quota headers (confirmed):** `x-ratelimit-monthly-limit`, `x-ratelimit-monthly-remaining`, `x-ai-search-monthly-limit`, `x-ai-search-monthly-remaining`. Both pairs present, so percentage consumed is computed from headers with no hardcoded plan value. **No per-minute headers exist** — the 60/min ceiling is enforced but invisible, so client-side throttling is the only protection against it.

**Plan allowance:** 2,000 calls/month.

**`/awards` payload:** `id`, `state`, `stateName`, `fiscalYear`, `awardeeName`, `federalAmount`, `matchAmount`, `activityType`, `programDescription`, `sourceDocument{id,title,fileType,url}`.

### 4.1 Four constraints this imposes

**No `updated_since` on `/awards`, `/documents`, or `/opportunities`.** `since=` and `updatedSince=` are silently ignored, not rejected — they return unfiltered totals. Only `/activity` supports `since`. Award records carry no timestamp of any kind, so **hashing is the only Tier 3 change detection available.**

**`sourceDocument.url` is an RCJ proxy** (`/api/documents/<uuid>/file`), serving their cached copy — not the state source. The real state URL appears only in `/activity` (`siteUrl`, `detail.updatedDocuments[].sourceUrl`). See §12 for the resulting field split. This makes `/activity` a primary endpoint, not a delta gate, and makes the §7 registry more load-bearing than originally assumed.

**Machine-generated summaries.** RCJ record descriptions read as LLM-generated and the platform offers opt-in AI answer synthesis. Search aids only; never a source of fact. Quotable text comes from the state document via §9.

**Terms of service: none published.** `/terms`, `/tos`, `/legal`, `/api-terms` all 404; only `/privacy-policy` exists and is silent on reuse. This project is internal-use only and produces no published product, so redistribution is not a live question. If that changes, resolve permitted use with AME Mobile (`info@amemobile.net`) and AHA counsel *before* anything leaves the building.

---

## 5. Stage 1 — Retrieval (`01_retrieve_rcj.R`)

**Contract:** pull RCJ records to an immutable dated landing zone. Never transform in this stage.

### 5.1 Pull strategy — test global pagination first

**Before writing the client, test whether `/awards`, `/documents`, and `/opportunities` paginate without a `state` filter.** This decides the quota model:

- **If they do:** pull nationally at max `limit` and partition by state locally. Rough volumes — a few thousand awards at 500/page, ~3,100 documents at 100/page, ~630 opportunities at 100/page. A full weekly refresh lands near 100–150 calls/month against the 2,000 allowance, which affords twice-weekly cadence through the Year 1→Year 2 transition. Complete snapshots also give cleaner diffs than 50 independently-timed state pulls.
- **If they require `state`:** fall back to a full weekly `/awards` pull at `limit=500` per state, with `/documents` and `/opportunities` gated on `/activity?since=`. Approximately 800–900 calls/month, 40–45% of allowance, weekly only.

`/activity` is pulled comprehensively either way — it is the only source of `state_source_url`.

Record the test result in `CLAUDE.md` §8 before Session 2 proceeds.

### 5.2 Client requirements

- Write to `data/raw/rcj/<YYYY-MM-DD>/<endpoint>[_<state>].json`. Never overwrite a prior date. Committed per §0.5.
- **Three pagination handlers**, one per envelope in §4. The exhaustiveness assertion differs by shape: compare written count to `pagination.total` for the standard envelope; loop until `hasMore` is false for activity and search. A silent short-read is the worst failure mode here.
- `httr2` with `req_retry()` on 429/5xx with exponential backoff, `req_throttle()` **below 60 requests/minute** (no header will warn you), and a request timeout. Honor `Retry-After` on 429.
- **Quota accounting.** Parse the four headers from §4 on every call, write remaining to `logs/pull_manifest.csv`, and abort at 90% monthly consumption rather than truncating silently.
- **Pull manifest** — one row per call: timestamp, endpoint, params, HTTP status, records returned, monthly quota remaining, duration.
- All normalization reads from `data/raw/`, never live. Development and re-runs cost zero quota.

**Cadence:** weekly minimum; twice-weekly through the Year 1→Year 2 transition if the global-pagination test passes. States are mid-cycle — Year 1 operating periods ended in August/September 2026 and Year 2 funds flow from October 1.

---

## 6. Stage 2 — Normalization (`02_normalize.R`)

**Contract:** raw JSON → a typed, deduplicated, tier-assigned record table with change detection. Still no interpretation.

### 6.1 Tier assignment

Assign `award_tier` using, in priority order:
1. Explicit RCJ record type where it maps cleanly (e.g. "Award Announcement" vs "Application").
2. `awardeeName` populated **and** passing the named-recipient test below → `SUBAWARD`.
3. Amount matching the published CMS FY2026 state allotment for that state → `STATE_ALLOTMENT`.
4. Amount attached to a solicitation/NOFO/RFP/RFA with no named recipient → `SOLICITATION`.
5. Otherwise `UNASSIGNED` → routed to the review queue. **Never default to `SUBAWARD`.**

**Named-recipient test.** A populated `awardeeName` is not evidence of a named recipient — Delaware returned six of fifteen rows where it held a program name or a pool: "Delaware DHSS / Mobile Health Hubs Grantee Pool" ($20M), "School-Based Health Centers Expansion Initiative" ($10M). `awardeeName` fails the test when it:

- matches a program-name pattern: `pool`, `grantee`, `initiative`, `expansion`, `program`, `fund`, `TBD`, `to be determined`, `various`, `multiple`
- matches the state agency administering the program (`Delaware DHSS`, `<State> DHHS`, etc.)

Failures go to `UNASSIGNED` and the review queue, never to `SUBAWARD`.

**Do not over-filter.** A real legal entity that isn't a hospital is still Tier 3. Delaware's State Housing Authority ($11.5M) is a genuine named recipient: `SUBAWARD`, `recipient_type = LOCAL_GOVT_OR_PUBLIC_HEALTH`, `flow_type = NON_HOSPITAL`, `distributed_to_hospital = No`. Legitimate non-hospital recipients belong in the table as `No`, not quarantined out of it.

### 6.2 Junk filters (test cases from observed RCJ defects)

Build these as an explicit, testable filter set with a `flag_reason` column — flag and quarantine, don't silently drop:

- **Provenance mismatch — highest priority filter.** Delaware returned four records tracing to a HRSA Rural Health Grants fact sheet: real rural health awards, wrong program, unflagged in the RHTP feed. Description-negation regex cannot catch these because nothing about them reads as non-rural-health. Test the source document for non-RHTP federal program markers — HRSA, USDA Rural Development, FCC/USAC Rural Health Care, Flex/SORH — and quarantine any record whose source doesn't tie to RHTP. Flag as `PROVENANCE_MISMATCH`. Getting HRSA money into an RHTP figure is exactly the error that would discredit the analysis.
- **Self-declared non-RHTP.** Records whose description states the document does not relate to RHTP (a Wisconsin Perkins CTE record currently sits in the feed this way). Regex on the description for negation phrasing.
- **Page chrome as title.** Titles matching accessibility text, cookie notices, nav labels, or bare filenames — observed: "Here's how you know. Resources", "Press Alt+1 for screen-reader mode", "Report an accessibility issue", "Browse.aspx", "DE - 2028 - portal". Pattern list in `data/reference/title_junk_patterns.csv`.
- **Event-schedule bleed.** Event arrays containing items with no topical relationship to the record — the Delaware Governor Meyer award announcement carries a Delaware Libraries press release in its `keyDates` location field; a South Dakota record carries boiler replacements and latrine renovations. Heuristic: flag when <50% of event entries share health/RHTP keywords with the parent record. Flag for review, never auto-clean.
- **Amount sanity.** Flag any Tier 3 amount exceeding that state's FY2026 allotment, any amount ≥ $1B (unit errors), and **any amount under $1,000**. The last threshold matters: Delaware returned four records with `federalAmount: 1`, which a zero-test misses entirely. RHTP subawards below $1,000 effectively don't exist, so anything under it is placeholder data.

### 6.3 Deduplication and change detection

- Hash each record's substantive fields with `digest::digest()` → `rcj_record_hash`. Award records carry no timestamp (§4.1), so **hashing is the only Tier 3 change detection available** — there is no server-side delta to fall back on.
- **Content-based dedup, not just ID.** The same award reported through two source documents gets two record IDs: Delaware returned two $10M school-based-health-center rows that appear to be the same money. Dedup on `(state, federalAmount, activity_type)` in addition to ID, and route collisions to the review queue rather than auto-merging.
- Maintain effective-dated rows: `first_seen`, `last_seen`, `superseded_by`. Never overwrite a prior version of a record.
- Diff each pull against the previous. Changed and new records go to the review queue. Records unchanged since last pull skip re-validation.
- **Re-opened solicitations are a known trap.** West Virginia currently has multiple re-opened solicitations with the same underlying opportunity. Match on the state's own solicitation number where present (e.g. `RHT-AFA-04-28-2026-MSC3`) to avoid counting the same pool twice.

---

## 7. Stage 3 — State source registry (`03_state_registry.R`)

A one-time manual build that pays for itself immediately. Output: `data/reference/state_source_registry.csv`, 50 rows, hand-verified.

| Field | Content |
|---|---|
| `state` | USPS code |
| `lead_agency` | Designated state entity (Medicaid agency, DOH, Office of Rural Health, etc.) |
| `program_page_url` | Canonical RHTP program page |
| `award_posting_url` | Where notices of award / NOIs are actually posted (often a procurement portal, not the program page) |
| `pass_through_admin` | Non-agency administrator, if any |
| `pass_through_admin_url` | Their posting location |
| `fy2026_allotment` | CMS-published state award — **independent anchor, from CMS/KFF, not RCJ** |
| `last_verified` | Date a human last confirmed the URLs resolve |

Notes for the build:
- Several states administer RHTP through a non-agency intermediary — Virginia through the VHHA Foundation, New Hampshire through the Foundation for Healthy Communities. Award postings for these live off the state domain entirely.
- State Health & Value Strategies has published tracking of which agency leads RHTP implementation in each state; use it as the starting list, then verify each URL by hand.
- Populate `fy2026_allotment` from the CMS December 2025 announcement (50 states, ~$200M average, range roughly $147M New Jersey to $281M Texas). This becomes the reconciliation anchor in §10.

---

## 8. Controlled vocabularies

Store as `data/reference/vocabularies.csv` and validate every categorical column against it. No free-text categories anywhere.

**`award_tier`:** `STATE_ALLOTMENT` | `SOLICITATION` | `SUBAWARD` | `UNASSIGNED`

**`source_doc_type`:** `NOTICE_OF_AWARD` | `NOTICE_OF_INTENT_TO_AWARD` | `PROCUREMENT_PORTAL_POSTING` | `STATE_BUDGET_NARRATIVE` | `AGENCY_PRESS_RELEASE` | `GOVERNOR_PRESS_RELEASE` | `THIRD_PARTY_NEWS` | `OTHER`
*(Strength ordering matters: the first three are primary; press releases are secondary; third-party news alone can never support a `Yes`.)*

**`rhtp_award_confirmed`:** `Yes` | `No` | `Unclear`

**`recipient_type`:** `HOSPITAL_OR_SYSTEM` | `HOSPITAL_AFFILIATED_ENTITY` | `FQHC_OR_RHC` | `EMS_OR_PSAP` | `UNIVERSITY_OR_AHC` | `AHEC` | `SCHOOL_OR_DISTRICT` | `LOCAL_GOVT_OR_PUBLIC_HEALTH` | `TRIBAL_ORG` | `STATE_AGENCY` | `VENDOR_OR_CONTRACTOR` | `NONPROFIT_CBO` | `NOT_YET_NAMED`

**`flow_type`:** `DIRECT` | `PASS_THROUGH_DESIGNATED` | `PASS_THROUGH_UNRESOLVED` | `IN_KIND_BENEFIT` | `NON_HOSPITAL`

**`distributed_to_hospital`:** `Yes` | `No` | `Unclear`

**`determination_confidence`:** `HIGH` | `MEDIUM` | `LOW`

**`activity_type`:** map to the CMS RHTP allowable-use categories (the CMS category guidance series — e.g. Category E covers workforce). Retain the state's own raw activity language in a parallel `activity_type_raw` field; never discard it.

---

## 9. Stage 4 — Validation and evidence capture (`04_validate.R`)

**Contract:** for every Tier 3 candidate, locate and archive the primary state source, then resolve confirmation status.

### 9.0 This stage runs outside the cloud session

Validation requires fetching pages from 50-plus state government domains, plus non-state administrators. Enumerating those in a network allowlist in advance isn't feasible, and setting the environment to **Full** network access to accommodate it is a poor trade for a project whose whole point is provenance discipline.

**Split the stage:**

| Runs in the cloud session | Runs outside |
|---|---|
| Building and prioritizing the review queue | Fetching state pages |
| Exporting the queue to Excel | Archiving them to PDF |
| Reading the completed queue back in | Reading the page and identifying confirming text |
| Applying the §9.2 decision rules | — |
| Writing determinations to the record table | — |

Fetching and archiving happen either in a local R session (if this project later moves to a laptop) or manually in a browser, with results entered in the exported review-queue spreadsheet. The determination logic is indifferent to how evidence was captured — only that it is recorded, complete, and attributable.

**Consequence for the code:** `04_validate.R` contains no HTTP requests to state domains. It is a queue manager and rule engine that reads reviewer-supplied evidence. Build it that way from the start rather than writing a fetcher that can't run.

### 9.1 Evidence capture — required for every validated row

- `validation_url` — the specific page or document, **not** the program homepage.
- `validation_source_type` — from the `source_doc_type` vocabulary.
- `validation_date_accessed`.
- `validation_archive_path` — path to an **archived copy** committed under `data/evidence/<state>/`. This is not optional. State pages get restructured without notice; an advocacy citation that 404s in six months is a liability, and AHA figures need to survive scrutiny long after the page moves. In the browser workflow, "print to PDF" produces an acceptable archive.
- `confirming_text` — the specific sentence establishing the award, stored in the row so a reviewer can adjudicate without reopening the source.
- `validator` and `validation_date`.

### 9.2 Confirmation decision rules

Implement exactly these; write them into `CLAUDE.md` so coding is consistent across sessions and reviewers.

**`Yes`** — a state agency or designated pass-through administrator document names both the recipient and the award. Source type must be `NOTICE_OF_AWARD`, `NOTICE_OF_INTENT_TO_AWARD`, `PROCUREMENT_PORTAL_POSTING`, `STATE_BUDGET_NARRATIVE`, or an official agency/governor press release that names the recipient.

**`No`** — the state source contradicts RCJ, or shows the solicitation cancelled, withdrawn, unawarded, or re-opened without award.

**`Unclear`** — any of: the only available source is third-party news; amounts conflict across sources; the page exists but names no recipients; the record is a pass-through pool with unresolved subrecipients; the source is a projection or plan rather than an award action.

The `Unclear` bucket becomes a dumping ground unless these rules are explicit and applied mechanically. Reviewer consistency is what makes the file defensible.

### 9.3 Workflow

Validation is human-in-the-loop. Build it as a persistent review queue, not a batch script:

- `data/interim/review_queue.rds` with `status` ∈ `PENDING` | `IN_PROGRESS` | `RESOLVED` | `BLOCKED`. **Committed to git** — this is state that must survive between sessions (§0.5).
- Prioritize by dollar amount descending, then by state.
- Export the pending queue to `output/review_queue_<date>.xlsx` with the source URLs as clickable hyperlinks, so review happens in Excel outside the session and is read back in.
- The round-trip is the primary interface for this stage: export → review offline → commit the completed file and the evidence PDFs → next session reads them and applies the rules. Build the reader to validate the returned file against the vocabularies and reject malformed rows rather than ingesting them silently.
- Records unchanged since last validation (matching `rcj_record_hash`) inherit their prior determination and skip the queue.

---

## 10. Stage 5 — Hospital determination (`05_hospital_determination.R`)

Two axes. "Money reaches a hospital" and "we can prove it" are different claims and need separate columns.

### 10.1 Axis 1 — Recipient identification

1. Clean the recipient name (`janitor`, strip legal suffixes, normalize `&`/`and`, expand common abbreviations).
2. **Crosswalk to a CCN wherever possible**, then validate against the **AHA Annual Survey** and the **CMS Provider of Services file**. Carry `ccn` and `aha_id` on the row.
3. Capture `rural_designation` ∈ `CAH` | `SCH` | `MDH` | `RRC` | `NONE` while you're in POS — this is the cut most useful for advocacy and it's free at this step.
4. Record `hospital_match_method` ∈ `EXACT` | `FUZZY` | `MANUAL` | `NONE` and `hospital_match_score`.

**Fuzzy matches never auto-resolve.** They populate the manual review queue. State award postings use DBA names, campus names, and legal entity names inconsistently; a fuzzy match that silently resolves is how a clinic becomes a hospital in the final table.

### 10.2 Axis 2 — Flow determination

| `flow_type` | Test | `distributed_to_hospital` |
|---|---|---|
| `DIRECT` | Named recipient matches a hospital in AHA/POS | `Yes` |
| `PASS_THROUGH_DESIGNATED` | Intermediary receives funds, but the source document **names** hospital subrecipients or restricts eligibility to hospitals *and* the award has been made (e.g. Georgia's Dual Track Rural Hospital Remote Critical Care NOI naming four rural hospitals) | `Yes`, with `intermediary_name` populated |
| `PASS_THROUGH_UNRESOLVED` | Intermediary administers a pool where hospitals are among eligible entities, recipients not yet named (most VHHA Foundation and FHC solicitations today) | `Unclear` — **do not impute** |
| `IN_KIND_BENEFIT` | Funds go to a vendor or state system that hospitals use but do not receive (statewide EMD dispatch, HIE infrastructure, shared services consortiums) | `No`, but set `hospital_benefiting = Yes` |
| `NON_HOSPITAL` | Recipient and purpose are clearly outside hospitals (school kitchen modernization, school-based health centers, dental school programs) | `No` |

`IN_KIND_BENEFIT` deserves its own flag rather than being discarded: it is substantively important to AHA's narrative even though those dollars must never enter a "funds distributed to hospitals" total.

### 10.3 Required accompanying fields

- `determination_confidence` — `HIGH` (primary source, named hospital recipient, CCN matched) / `MEDIUM` (primary source, hospital identity inferred from name without CCN match) / `LOW` (secondary source or unresolved pass-through).
- `determination_basis` — free text, mandatory. When someone asks in six months why a $12M award was coded hospital-bound, the answer must be in the row.
- `reviewer`, `review_date`, `rules_version` (see §13).

---

## 11. Stage 6 — Excel deliverable (`06_build_workbook.R`)

`openxlsx`, one workbook, sheets in this order:

1. **README** — generation date, pull date range, rules version, tier definitions, the eligibility-is-not-receipt warning, and a plain statement that Tier 1/2/3 figures must never be summed.
2. **Subawards (Tier 3)** — the analytical table. Full field set per §12.
3. **Solicitations (Tier 2)** — announced pools. Physically separate sheet.
4. **State Allotments (Tier 1)** — 50 rows, CMS-anchored.
5. **State Source Registry** — the §7 reference table.
6. **Review Queue** — unresolved records.
7. **Flagged / Quarantined** — junk-filter catches with `flag_reason`.
8. **Change Log** — records added, changed, or superseded since the prior build.
9. **Data Dictionary** — §12 rendered as a sheet.

Formatting: freeze the header row, autofilter on all data sheets, currency format on amount columns, conditional fill on `distributed_to_hospital` (Yes/No/Unclear), and hyperlinks on `source_doc_url` and `validation_url`. Column widths set explicitly, not auto.

Filename: `rhtp_hospital_tracker_<YYYY-MM-DD>.xlsx`. Never overwrite a prior build.

---

## 12. Data dictionary

**Identity & provenance**
`record_id`, `rcj_record_hash`, `pull_date`, `first_seen`, `last_seen`, `superseded_by`, `award_tier`, `rules_version`

**Award core**
`date_announced`, `date_effective`, `state`, `state_name`, `fiscal_year`, `rhtp_budget_period`, `solicitation_number`, `awardee_name_raw`, `awardee_name_clean`, `intermediary_name`, `amount_announced`, `amount_obligated`, `amount_basis`, `match_amount_rcj`, `applicant_cost_share_required`, `cost_share_pct`, `activity_type`, `activity_type_raw`, `program_description`, `source_doc_title`, `rcj_document_url`, `state_source_url`, `source_doc_archived_path`

**Validation**
`validation_url`, `validation_source_type`, `validation_date_accessed`, `validation_archive_path`, `confirming_text`, `rhtp_award_confirmed`, `validator`, `validation_date`, `validation_notes`

**Hospital determination**
`recipient_type`, `ccn`, `aha_id`, `hospital_match_method`, `hospital_match_score`, `rural_designation`, `flow_type`, `distributed_to_hospital`, `hospital_benefiting`, `determination_confidence`, `determination_basis`, `reviewer`, `review_date`

**QA**
`flag_reason`, `qa_status`

### Field definitions that differ from the original spec

**`rcj_document_url` / `state_source_url`** replace a single `source_doc_url`. RCJ's `sourceDocument.url` is a proxy to their own cached copy (`/api/documents/<uuid>/file`), not the state source — it is useful for retrieval and is **never** a citation. The real state URL appears only in `/activity` (`siteUrl`, `detail.updatedDocuments[].sourceUrl`), and is absent for many records. Where `state_source_url` is null, the §7 registry is the only route to a primary source, which is why registry completeness is now a QA gate.

**`match_amount_rcj`** captures RCJ's `matchAmount` field at Tier 3, flagged as unvalidated. It is adjacent to but not the same claim as `applicant_cost_share_required`: RCJ's figure and the state solicitation's stated cost-share requirement are independent assertions and may disagree. Never populate the cost-share fields from `matchAmount`.

**`applicant_cost_share_required`** replaces "availability of state matching funds." RHTP has no statutory state match — states are not required to contribute. What actually exists is applicant cost-share required by a state's own solicitation. That is an attribute of the **Tier 2 solicitation**, captured there and inherited down to Tier 3 awards made under it. Coding it as "state matching funds" produces inconsistent results across reviewers.

**`amount_announced` / `amount_obligated`** replace a single "amount of award." Notices of Intent to Award frequently shift before execution, and re-opened solicitations announce the same pool twice. `amount_basis` records which document each figure came from.

---

## 13. QA assertions (`qa_assertions.R`)

Run on every build; fail the build, don't warn.

1. No record has `award_tier = UNASSIGNED` in a published sheet.
2. No aggregation function receives mixed `award_tier` values. Implement as a guard inside the aggregation helpers themselves.
3. Tier 1 state allotments reconcile to the CMS-published FY2026 figures: 50 states, all values within roughly $147M–$281M, mean near $200M. Any deviation is a data error, not a finding.
4. For each state and budget period, Σ Tier 3 `amount_obligated` ≤ that state's Tier 1 allotment. Violations indicate double counting or a tier misassignment.
5. Every row with `distributed_to_hospital = Yes` has a non-null `validation_url`, `validation_archive_path`, and `confirming_text`, and `validation_source_type` is not `THIRD_PARTY_NEWS`.
6. Every categorical column validates against `vocabularies.csv`.
7. Every `hospital_match_method = FUZZY` row has `reviewer` populated.
8. Pull manifest shows records-written equals records-reported for every state in the current pull.
9. No `amount_*` value is negative, zero, under $1,000, or ≥ $1B.
10. `rules_version` is identical across all rows in a build.
11. **No published row carries `flag_reason = PROVENANCE_MISMATCH`.** HRSA, USDA, or FCC rural money in an RHTP total is the single most discrediting error available.
12. **Registry completeness.** Every Tier 3 candidate belongs to a state with a verified `award_posting_url` in the §7 registry. A state missing from the registry cannot be validated, so registry gaps are reported as deliverable gaps, not silently skipped.
13. No `awardee_name_clean` in Tier 3 matches a program-name pattern from the §6.1 named-recipient test.

**Version the classification rules.** The determination logic in §10 will change as edge cases surface. Store `rules_version` on every row and tag the repo at each build, so you can always say which rules produced a published figure.

---

## 14. Pilot before scaling

Do not build for 50 states first. Pilot on five, chosen to surface the edge cases cheaply:

| State | What it tests |
|---|---|
| **Georgia** | Awardee-level data present, NOIs posted — the happy path and `DIRECT` matching |
| **Virginia** | VHHA Foundation pass-through — `PASS_THROUGH_DESIGNATED` vs `_UNRESOLVED` |
| **Nebraska** | School kitchen / farm-to-school awards — negative cases, `NON_HOSPITAL` |
| **Florida** | RCJ shows 11 opportunities and 0 awardees — tests whether the gap is RCJ's or the state's |
| **Texas** | Largest allotment, observed junk titles — volume plus junk filters |

The pilot's most valuable output is not the data. It is an answer to: **what share of RHTP dollars are currently resolvable to hospitals at all?** If that share is low, that is itself a finding worth publishing, and it changes what the full build is for.

---

## 15. Session sequencing for Claude Code

Build in this order. Each session ends with a working, tested stage, **all persistent output committed**, and an updated "current state" section in `CLAUDE.md`.

1. ~~**Session 1** — Repo scaffold, `CLAUDE.md`, config, Stage 0 preflight.~~ **Complete.** Findings folded into §4. Vocabularies and junk-pattern reference files seeded. Delaware's 15 records committed as Stage 2 fixtures.
2. **Session 2** — Stage 1 retrieval for the five pilot states, with manifest, retries, throttling, and quota accounting. Verify exhaustive pagination. Commit the raw pull.
3. **Session 3** — Stage 2 normalization: tier assignment, junk filters with the observed defects as test fixtures, hashing and change detection.
4. **Session 4** — Stage 3 state source registry for the five pilot states, with CMS allotment anchors. The registry URLs are compiled by hand outside the session and committed as a CSV; the session validates the structure and integrates it.
5. **Session 5** — Stage 4 queue manager and rule engine, plus the Excel round-trip. No state-domain fetching (§9.0). Export the first review batch.
6. **Offline** — Work the exported queue: fetch, archive, record confirming text. Commit the completed spreadsheet and evidence PDFs.
7. **Session 6** — Read the completed queue, apply the §9.2 rules, then build Stage 5 hospital determination, AHA/POS crosswalk, and fuzzy-match review queue.
8. **Session 7** — Stage 6 workbook build and full QA assertion suite. Run the pilot end to end.
9. **Session 8** — Review pilot results, revise determination rules, bump `rules_version`, then scale retrieval and the registry to all 50 states.

The AHA Annual Survey and CMS Provider of Services extracts needed in Session 6 must be committed to the repo (or a subset of them) before that session starts — cloud sessions can't reach internal AHA systems.

### Opening prompt for Session 2

> Continuing the RHTP tracker. Re-read `rhtp-tracker-build-spec.md` — it's been revised with the Stage 0 findings, so §4, §5, §6, §12 and §13 have all changed. Session 1's work is committed.
>
> First, confirm R is working now that the Ubuntu hosts are allowlisted: `Rscript -e 'sessionInfo()'` and report anything missing from §3.3.
>
> Then run the §5.1 test before writing any client code: check whether `/awards`, `/documents`, and `/opportunities` paginate without a `state` filter. Report the result and the implied monthly call volume for both branches. Record the answer in `CLAUDE.md` §8.
>
> Once I've confirmed the strategy, build `01_retrieve_rcj.R` per §5.2 — three pagination handlers, throttling below 60/min, quota accounting against all four headers, abort at 90%. Pull the five pilot states from §14 and commit the raw output.
>
> Reminders: never print `RCJ_API_KEY`; `data/raw/` is committed, not ignored; tidyverse and `%>%` only.

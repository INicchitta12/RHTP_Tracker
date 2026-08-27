# RHTP Hospital Funding Tracker — Build Specification

**Owner:** Isaac, AHA Data & Policy
**Objective:** Identify and quantify Rural Health Transformation Program (RHTP) funds being distributed to hospitals, by state, with every figure traceable to a primary state source.
**Stack:** R (tidyverse), `%>%` pipe only. Excel deliverable via `openxlsx`.
**Build environment:** Claude Code on the web (cloud sessions). See §3 for the constraints this imposes — several design decisions below exist because of them.

---

## 0. Read this section before writing any code

Four principles govern every design decision below. If a later instruction seems to conflict with one of these, the principle wins.

### 0.1 State budget narratives are the spine; RCJ is a supplement

The project was originally built around Rural Care Journey. **That is inverted.**

RCJ has an unbounded completeness problem. Seven of eleven verified Delaware records exist in no RCJ endpoint at all, and Delaware runs fifteen initiatives against the handful RCJ captured. You can never characterize what is missing, so you can never state a denominator, so no share or percentage computed from it is defensible. For advocacy work that is disqualifying, however clean the pipeline gets.

**State RHTP budget narratives do not have that problem.** CMS required one from every state, with revised versions due 30 days after the December 2025 award. Fifty documents, complete by construction, covering the full $10B, and structured comparably because CMS specified the format. They reconcile against the CMS allotment table (§7.1), so the parse self-validates: if a state's initiatives don't sum to its allotment, the parse is wrong.

Roles:

| Source | Role |
|---|---|
| **CMS allotment table** | The anchor. 50 states, exact FY2026 figures. |
| **State budget narratives** | The backbone. Initiative-level dollars and activities, complete per state. |
| **RCJ** | Recipient names attached to initiatives, plus daily monitoring for new awards. |
| **State award notices / procurement portals** | Recipient confirmation where published. |

RCJ's 1,016 Tier 3 records stay useful. They stop being the frame.

### 0.1a What this project can and cannot deliver

Delaware and Oklahoma both publish **initiative-level dollars** and **neither publishes recipient-level amounts.** Delaware's budget narrative names four subrecipients across fifteen initiatives and **no hospitals at all** — not Beebe, TidalHealth, Nemours, Bayhealth, or ChristianaCare, despite all five appearing in its CMS abstract as known partners. **No pipeline produces a per-hospital dollar figure**, because states are not publishing one.

Two deliverables, both defensible:

1. **Which hospitals are receiving RHTP funds** — names, states, initiatives, source-verified. From **award notices**, not budget narratives (§7A.5a).
2. **How much flows through hospital-involved initiatives** — initiative-level dollars with a hospital-directed flag. From **budget narratives**.

**These are two sources and they do not substitute for each other.** Delaware proves it: the school-based health center awards to Beebe, TidalHealth, and Nemours are independently verified, but Initiative 3 in the budget narrative is $195,000 with "Vendor TBD." The budget narrative is a point-in-time plan; recipient identity emerges afterward through procurement.

**Do not promise a per-hospital dollar total.** The absence is itself a finding: states are distributing federal money without publishing recipient-level amounts.

### 0.1b Expect wide variance between states — the variance is the finding

Hospital-directed share of Year 1 spending, from the two hand-extracted reference states:

| State | Hospital-directed | Unclear | Non-hospital | Largest single line |
|---|---|---|---|---|
| **Oklahoma** | **48.7%** | 17.1% | 34.2% | Provider Collaborative Network, $43.1M — a nonprofit owned by member hospitals |
| **Delaware** | **15.7%** | 24.5% | 59.8% | Delaware Medical School, $42.5M — not a hospital |

A threefold spread across two states. Do not average it into a national figure and do not expect one to be meaningful. The reportable result is state-by-state, and the driver is structural: whether a state built its program around hospital collaboratives or around medical education and infrastructure.

Frame findings accordingly — *"hospital-directed share ranges from X% to Y% across states, driven by program design"* is supportable; *"N% of RHTP funding goes to hospitals"* is not.

### 0.2 The three-tier rule

RHTP money moves CMS → state → subrecipient. RCJ mixes all three tiers in a single amount field. Every record must carry an `award_tier` before any other processing:

| Tier | Code | What it is | Example |
|---|---|---|---|
| 1 | `STATE_ALLOTMENT` | CMS award to a state | Missouri FY2026, $216.0M |
| 2 | `SOLICITATION` | State-announced funding pool / NOFO budget | Ohio Rural CIN & Innovation Hubs, $61.7M |
| 3 | `SUBAWARD` | Executed or intended award to a named recipient | GA Dual Track Remote Critical Care, $900K to 4 rural hospitals |

**Only Tier 3 answers the project question.** Tiers 1 and 2 live in separate reference tables, on separate Excel sheets, and are never unioned with Tier 3. Aggregation functions must hard-fail if passed mixed tiers.

### 0.2a One home per authoritative number

Tier 1 classification produced **274 RCJ records across 50 states** — roughly five per state, each restating the same allotment in a different document. Correctly classified, but Tier 1 no longer sums to $10B.

**The canonical Tier 1 table is `cms_fy2026_allotments.csv`, 50 rows.** The 274 RCJ records are *corroborating references*: useful for provenance and for checking that RCJ's figures agree with CMS, never the table itself, never summed. Any RCJ record disagreeing with the CMS figure for its state is a finding about RCJ's accuracy — record it, don't silently prefer one.

The same discipline governs initiative budgets (§7A.5) and recipient amounts (§9.3). An authoritative number has exactly one home, and every other appearance of it is a reference.

### 0.3a Code the recipient, not the activity

**The single most consequential coding rule, and the one that has already gone wrong.** All eleven verified Delaware records were coded `hospital = no`, including four awards to Beebe Healthcare, TidalHealth, and Nemours Children's Health — all hospitals and health systems. The coding followed what the money *does* (school-based health centers, a diabetes pilot) rather than who *receives* it. Applied nationally, that would have reported Delaware's hospital total as zero, the exact opposite of the truth.

Beebe Healthcare receiving RHTP funds to operate a school-based health center is `recipient_type = HOSPITAL_OR_SYSTEM`, `flow_type = DIRECT`, `distributed_to_hospital = Yes`. Beebe is a hospital. Beebe received the money. Where the clinic sits does not change either fact.

Every human reviewer reads `reviewer-coding-instructions.md` before touching a record. Every automated classifier keys off recipient identity, never activity type.

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
rhtp.amemobile.net
packagemanager.posit.co
rspm-sync.rstudio.com
cloud.r-project.org
archive.ubuntu.com
security.ubuntu.com
cms.gov
www.cms.gov
```

`cms.gov` is needed once, to parse the FY2026 allotment table (§7.1). Stage 4 requires a broader change — see §9.5.

`rspm-sync.rstudio.com` is not optional. `packagemanager.posit.co` serves metadata directly but **307-redirects every actual package download** — binary and source alike — to that host. Without it, `PACKAGES.gz` returns 200 and every install then fails at the proxy, which is exactly the shape of failure that produced a zero-package environment snapshot in Session 2.

`archive.ubuntu.com` and `security.ubuntu.com` are in the default Trusted set, so a 403 against them means the "also include default list of common package managers" box is unchecked. List them explicitly regardless.

### 3.3 Environment variables

Set in the environment dialog's **Environment variables** field, `.env` format:

```
RCJ_API_KEY=<key>
LANG=C.UTF-8
LC_ALL=C.UTF-8
```

**The locale variables are not optional.** Cloud sessions start R in the C/POSIX locale, where `readLines()` fails on multibyte UTF-8 — `config.yml` was itself unreadable until this was found. `utils_config.R` also sets a UTF-8 locale at source time; keep both. The environment variable covers anything that doesn't source the config, and the code covers a future local run where the variable doesn't exist.

Per §1, `RCJ_API_KEY` is read via `Sys.getenv()` and never written to a file or printed.

### 3.4 Setup script

**This goes in the cloud environment's Setup script field at claude.ai/code, not in the repo.** The environment script runs once before Claude Code launches and its result is snapshotted, so R persists across sessions. A repo script (`config/setup.sh`) would reinstall R every session and burn several minutes each time — keep it in the repo as the canonical copy if useful, but the environment field is what executes.

The environment's **Allowed domains** must include everything in §3.2. Runs once per environment, then the filesystem is snapshotted. **It must exit zero and finish within roughly five minutes** or the cache won't build — which is why this uses precompiled binaries rather than compiling from source. Editing the allowed-domains list invalidates the cache and re-runs the script.

```bash
#!/bin/bash
set -e

apt-get update
apt-get install -y --no-install-recommends \
  r-base-dev r-recommended \
  libcurl4-openssl-dev libssl-dev libxml2-dev \
  libharfbuzz-dev libfribidi-dev libfreetype6-dev \
  libpng-dev libtiff5-dev libjpeg-dev libuv1-dev

cat > /usr/lib/R/etc/Rprofile.site << 'EOF'
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
  paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
EOF

Rscript -e '
pkgs <- c("tidyverse","httr2","jsonlite","openxlsx","janitor",
          "digest","here","yaml","fuzzyjoin","assertr","testthat")
install.packages(pkgs)
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing)) {
  cat("SETUP FAILED — packages not installed:", paste(missing, collapse=", "), "\n")
  quit(status = 1)
}
cat("All", length(pkgs), "packages installed.\n")
'
```

### Why each piece is there

**`r-recommended`.** `r-base-dev` installs none of R's recommended packages — no MASS, Matrix, survival, lattice, or nlme. A large share of CRAN depends on that set; `assertr` fails outright without MASS. This is independent of the repository problem and survives fixing it.

**The verification block, not just removing `|| true`.** Dropping `|| true` alone would not have caught the Session 2 failure: `install.packages()` **warns on failure, it does not error**, so the Rscript call exits zero even when every package fails. The explicit `installed.packages()` check with `quit(status = 1)` is what actually makes the failure loud. Combined with `set -e`, a broken install now fails the session start instead of snapshotting an empty environment that looks healthy.

**The harfbuzz/freetype/libuv group.** Needed only when compiling from source — `textshaping`, `ragg`, and `fs` fail to configure without them. Unnecessary once Posit binaries are working, but included deliberately as insurance: the binary path already proved fragile once, and these add roughly 30 seconds to a five-minute budget.

If the script does time out, trim the package list to `tidyverse`, `httr2`, `jsonlite`, `openxlsx`, `digest`, `here`, `yaml` and install the rest mid-session as needed.

### 3.5 Package notes

`arrow` is deliberately omitted — use `saveRDS()`/`readRDS()` for the interim layer instead of parquet. It's one less heavy dependency in a time-boxed setup script, and the interim layer is only read by this pipeline.

`pagedown`/`chromote` for PDF archiving are also omitted; see §9.0 for why evidence capture happens outside the cloud session.

---

## 4. Stage 0 — Confirmed API surface (completed Session 1)

Verified live against the Pro plan. Base `https://www.ruralcarejourney.com`, all endpoints under `/api/v1/`. Auth via `Authorization: Bearer` or `X-Api-Key`.

**Endpoints:** `/api/stats` (public), `/states`, `/states/:code`, `/awards`, `/documents`, `/documents/:id`, `/opportunities`, `/events`, `/activity`, `POST /search`.

**Four response shapes — handle each separately:**

| Envelope | Endpoints | Max `limit` | Termination |
|---|---|---|---|
| `{data, pagination:{page,limit,total,pages}}` | awards, documents, opportunities, events | awards 500; others 100 | `pages` count |
| `{data, count}` — **unpaginated** | states | n/a | single call |
| `{data, count, page, hasMore}` | activity | 100 | `hasMore` loop — `count` is page length, **not** grand total |
| `{documents, count, hasMore, aiAnswer}` | search | 50 | `hasMore` loop |

`/states` does not use the pagination envelope despite what the API docs imply. The page-planning function must **error on a missing `pagination.limit` rather than guess** — that guard is what surfaced this on the first live call.

**Quota headers (confirmed):** `x-ratelimit-monthly-limit`, `x-ratelimit-monthly-remaining`, `x-ai-search-monthly-limit`, `x-ai-search-monthly-remaining`. Both pairs present, so percentage consumed is computed from headers with no hardcoded plan value. **No per-minute headers exist** — the 60/min ceiling is enforced but invisible, so client-side throttling is the only protection against it.

**Plan allowance:** 2,000 calls/month.

**`/awards` payload:** `id`, `state`, `stateName`, `fiscalYear`, `awardeeName`, `federalAmount`, `matchAmount`, `activityType`, `programDescription`, `sourceDocument{id,title,fileType,url}`.

### 4.1 Constraints this imposes

**Coverage is incomplete — and the gap is extraction, not absence.** The national `/awards` pull returns 1,429 records spanning **only 39 of 50 states**. Eleven states return zero: AR, FL, KY, MA, MN, NJ, NY, NC, SC, TN, WY.

RCJ is internally consistent about this — `/states` reports `awardeeCount: 0` for all eleven, matching `/awards` exactly. So this is not a display bug. **It is a parsing failure.** Florida's awardee-level data exists, RCJ holds the document, and it sits in `/documents` as category `REFERENCE` without ever becoming an award record: *FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants*. Florida administers RHTP through AHCA on numbered RFAs — the §7.3 case where `award_posting_url` differs from the program page.

Three consequences, and the first is structural:

- **`/awards` is not the Tier 3 universe.** It is the subset RCJ successfully parsed. Award-shaped records are also sitting unparsed in `/documents`, in the 39 covered states as well as the 11 empty ones. §6.4 adds a mining pass to surface them.
- **The Coverage sheet reports two dimensions** (§11): whether RCJ produced award records for a state, and whether award-shaped documents exist that it failed to parse. "Data exists, source failed to extract" is a materially different message than "no data."
- **`/states` returns 49 states plus a pseudo-state `US`, and omits Wyoming.** It cannot serve as the state vocabulary — see §7.1.

**No `updated_since` on `/awards`, `/documents`, or `/opportunities`.** `since=` and `updatedSince=` are silently ignored, not rejected — they return unfiltered totals. Only `/activity` supports `since`. Award records carry no timestamp of any kind, so **hashing is the only Tier 3 change detection available.**

**`sourceDocument.url` is an RCJ proxy** (`/api/documents/<uuid>/file`), serving their cached copy — not the state source. The real state URL appears only in `/activity` (`siteUrl`, `detail.updatedDocuments[].sourceUrl`). See §12 for the resulting field split. This makes `/activity` a primary endpoint, not a delta gate, and makes the §7 registry more load-bearing than originally assumed.

**Machine-generated summaries.** RCJ record descriptions read as LLM-generated and the platform offers opt-in AI answer synthesis. Search aids only; never a source of fact. Quotable text comes from the state document via §9.

**Terms of service: none published.** `/terms`, `/tos`, `/legal`, `/api-terms` all 404; only `/privacy-policy` exists and is silent on reuse. This project is internal-use only and produces no published product, so redistribution is not a live question. If that changes, resolve permitted use with AME Mobile (`info@amemobile.net`) and AHA counsel *before* anything leaves the building.

---

## 5. Stage 1 — Retrieval (`01_retrieve_rcj.R`)

**Contract:** pull RCJ records to an immutable dated landing zone. Never transform in this stage.

### 5.1 Pull strategy — Branch A, confirmed

**Global pagination works.** All three collection endpoints paginate without a `state` filter, verified live in Session 2: `/awards` 1,429 records across 3 pages at `limit=500`; `/documents` 3,092 across 31 pages at 100; `/opportunities` 631 across 7 pages at 100. Pages are disjoint, page 1 spans 21–32 states, and every final page returns the exact arithmetic remainder — no deep-page cap.

**Pull nationally at max `limit` and partition by state locally.** Per-state pulls are unnecessary and give worse change detection: complete snapshots diff cleanly, 50 independently-timed pulls do not.

**Measured volume (Session 3, live):** 60 calls for a full national pull — `/states` 1, `/awards` 3 (1,429 records), `/documents` 31 (3,092), `/opportunities` 7 (631), `/activity` 18 (1,787). Every paginated endpoint wrote exactly `pagination.total`.

The `/activity` backfill is 18 calls, not the ~5 originally projected.

| Cadence | Calls/month | % of 2,000 |
|---|---|---|
| Weekly | ~260 | 13% |
| **Twice-weekly (adopted)** | **~520** | **26%** |

Twice-weekly stands, with ~1,480 calls/month of headroom. No plan upgrade needed.

`/documents` is 31 of the 46 calls against a hard 100/page cap, so every additional 100 documents adds one call per pull. It is the line item to watch as the corpus grows.

`/activity` is pulled comprehensively every time regardless of cadence: it is the only source of `state_source_url` (§4.1).

### 5.2 Client requirements

- Write to `data/raw/rcj/<YYYY-MM-DD>/<endpoint>.json`. Never overwrite a prior date. Committed per §0.5.
- **Never trust your own requested `limit`.** `/documents?limit=500` returns HTTP 200 while serving 100 rows and echoing `pagination.limit: 100` — over-max limits are silently downgraded, neither honored nor rejected. A client trusting its request would walk 7 pages, read 700 of 3,092 records, and report success. **Page counts and totals come from the response envelope, always.** Assert that served `limit` equals requested `limit` and log any mismatch.
- **Three pagination handlers**, one per envelope in §4. Exhaustiveness differs by shape: compare written count to `pagination.total` for the standard envelope; loop until `hasMore` is false for activity and search. A silent short-read is the worst failure mode here.
- `httr2` with `req_retry()` on 429/5xx with exponential backoff, `req_throttle()` **below 60 requests/minute** (no header will warn you), and a request timeout. Honor `Retry-After` on 429.
- **Quota accounting.** Parse the four headers from §4 on every call, write remaining to `logs/pull_manifest.csv`, and abort at 90% monthly consumption rather than truncating silently.
- **Pull manifest** — one row per call: timestamp, endpoint, params, HTTP status, records returned, requested limit, served limit, monthly quota remaining, duration, and `run_type` ∈ `DEV` | `PRODUCTION`. The manifest is **append-only**: development runs are filtered, never deleted. Removing rows from an audit log to tidy it defeats its purpose.
- All normalization reads from `data/raw/`, never live. Development and re-runs cost zero quota.

**Cadence:** twice-weekly through the Year 1→Year 2 transition. States are mid-cycle — Year 1 operating periods ended in August/September 2026 and Year 2 funds flow from October 1.

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

**Named-recipient test.** A populated `awardeeName` is not evidence of a named recipient — Delaware returned six of fifteen rows where it held a program name or a pool: "Delaware DHSS / Mobile Health Hubs Grantee Pool" ($20M), "School-Based Health Centers Expansion Initiative" ($10M).

Apply as a **precedence rule, not an exclusion list.** Order matters:

1. **Legal-entity marker wins.** If the string contains `Inc`, `LLC`, `LLP`, `Corp`, `Foundation`, `Trust`, `Hospital`, `Health System`, `Medical Center`, `Clinic`, `University`, `College`, `District`, or `Authority`, it is a named entity — **regardless of also matching a program pattern below.** This is what admits "Rural Health Medical Program Inc.", the Nevada residency programs, and "Oregon Health & Science University … Department of Neurology," all of which an exclusion list wrongly rejected on 50-state data.
2. **Otherwise, program-name patterns fail the test:** `pool`, `grantee`, `initiative`, `expansion`, `program`, `fund`, `TBD`, `to be determined`, `various`, `multiple`.
3. **Otherwise, a bare state-agency name fails** (`Delaware DHSS`, `<State> DHHS`) — but only when rule 1 did not already fire.

Failures go to `UNASSIGNED` and the review queue, never to `SUBAWARD`. Extend rule 1 before ever extending rule 2: a generalizable marker beats another special case.

**Do not over-filter.** A real legal entity that isn't a hospital is still Tier 3. Delaware's State Housing Authority ($11.5M) is a genuine named recipient: `SUBAWARD`, `recipient_type = LOCAL_GOVT_OR_PUBLIC_HEALTH`, `flow_type = NON_HOSPITAL`, `distributed_to_hospital = No`. Legitimate non-hospital recipients belong in the table as `No`, not quarantined out of it.

### 6.2 Junk filters (test cases from observed RCJ defects)

Build these as an explicit, testable filter set with a `flag_reason` column — flag and quarantine, don't silently drop:

- **Multi-recipient fields — a recurring pattern, and a threat to Deliverable 1.** States concatenate several recipients into one `awardeeName`: New Hampshire returned a $1.9B row against a $204M allotment holding three managed care organizations; Delaware returned `University of Delaware, Beebe Healthcare, Deloitte Consulting LLP`.
  This is not merely an amount-ceiling problem. **A hospital buried inside a three-name string will not exact-match the AHA Annual Survey and vanishes from the recipient list.** Beebe is the worked example.
  Split `awardeeName` on `,`, `;`, ` and `, and ` & `; emit one candidate per fragment; flag the group `MULTI_RECIPIENT_FIELD`; route to review rather than auto-resolving — the split is a guess about the state's formatting, not a fact. The amount stays with the group and is **never divided** (§7A.5).
- **Provenance mismatch — highest priority filter.** Delaware returned four records tracing to a HRSA Rural Health Grants fact sheet: real rural health awards, wrong program, unflagged in the RHTP feed. Description-negation regex cannot catch these because nothing about them reads as non-rural-health. Test the source document for non-RHTP federal program markers — HRSA, USDA Rural Development, FCC/USAC Rural Health Care, Flex/SORH — and quarantine any record whose source doesn't tie to RHTP. Flag as `PROVENANCE_MISMATCH`. Getting HRSA money into an RHTP figure is exactly the error that would discredit the analysis.
- **Junk state codes.** `RC` appears as a state code carrying 54 documents and is not a state. Validate every `state` value against the 50-row CMS list from §7.1; anything failing is quarantined, never silently mapped.
- **Self-declared non-RHTP.** Records whose description states the document does not relate to RHTP (a Wisconsin Perkins CTE record currently sits in the feed this way). Regex on the description for negation phrasing.
- **Page chrome as title.** Titles matching accessibility text, cookie notices, nav labels, or bare filenames — observed: "Here's how you know. Resources", "Press Alt+1 for screen-reader mode", "Report an accessibility issue", "Browse.aspx", "DE - 2028 - portal". Pattern list in `data/reference/title_junk_patterns.csv`.
- **Event-schedule bleed.** Event arrays containing items with no topical relationship to the record — the Delaware Governor Meyer award announcement carries a Delaware Libraries press release in its `keyDates` location field; a South Dakota record carries boiler replacements and latrine renovations. Heuristic: flag when <50% of event entries share health/RHTP keywords with the parent record. Flag for review, never auto-clean.
- **Amount sanity — two distinct sentinels.** These mean different things and carry different `flag_reason` values:
  - `AMOUNT_PLACEHOLDER` — `federalAmount: 1` and anything under $1,000. A value was recorded and it is garbage. Delaware returned four of these; a zero-test misses them entirely.
  - `AMOUNT_NULL_SENTINEL` — `award: 0` on `/documents`. This is RCJ's null, **not a $0 award.** Treat as missing, never as zero.
  - Also flag any Tier 3 amount exceeding that state's FY2026 allotment, and any amount ≥ $1B (unit errors).
- **`SOURCE_IS_PLAN_NOT_AWARD` — a signal, never a tier reassignment.** Source-title heuristics must not override record-level evidence. A record with a named recipient and a specific amount is Tier 3 even when its source document is titled a plan: Pennsylvania's 66 named rural hospitals sit in a document that is both an "RHT Plan" and a list of "Authorized Project Awards." Raise the flag, route to review, leave the tier alone.

### 6.3 Deduplication and change detection

- Hash each record's substantive fields with `digest::digest()` → `rcj_record_hash`. Award records carry no timestamp (§4.1), so **hashing is the only Tier 3 change detection available** — there is no server-side delta to fall back on.
- **Content-based dedup, keyed on name as well as amount.** The same award reported through two source documents gets two record IDs — Delaware returned two $10M school-based-health-center rows that appear to be the same money. Key on `(state, awardee_name_clean, amount, activity_type)`.
  **The name is not optional.** A key of `(state, amount, activity_type)` called Oregon's 99 separate $100,000 awards to 99 distinct hospitals a single duplicate, collapsing 927 collisions to 15. Uniform-amount grant programs are the normal shape of a state subaward round, not an edge case: an amount collision without a name match is a formula, not a duplicate.
  Route surviving collisions to the review queue rather than auto-merging.
- **The hash covers the payload, not the derived columns.** Classification outputs are a build product, not a fact about the record. An unchanged record must pick up the current build's classification without superseding anything — otherwise no rule change is ever visible, and §13.10 passes silently over a table mixing rule generations.
- Maintain effective-dated rows: `first_seen`, `last_seen`, `superseded_by`. Never overwrite a prior version of a record.
- Diff each pull against the previous. Changed and new records go to the review queue. Records unchanged since last pull skip re-validation.
- **Re-opened solicitations are a known trap.** West Virginia currently has multiple re-opened solicitations with the same underlying opportunity. Match on the state's own solicitation number where present (e.g. `RHT-AFA-04-28-2026-MSC3`) to avoid counting the same pool twice.

---

### 6.4 Tier 3 candidate mining from `/documents`

Because `/awards` is only what RCJ managed to parse (§4.1), award-shaped records sit unextracted in `/documents` — in all 50 states, not just the 11 with zero award records.

Scan `/documents` for records that are award-shaped but produced no `/awards` row:

- category `AWARD_ANNOUNCEMENT` or `REFERENCE`
- a named organization present in the title or description, passing the §6.1 legal-entity test
- a dollar figure present
- **no `/awards` record shares that `sourceDocument.id`**

Emit these as `UNASSIGNED` Tier 3 *candidates* into the review queue with `flag_reason = UNPARSED_AWARD_CANDIDATE`.

**Absence in RCJ is a statement about RCJ, not about the state.** The first mining run found 38 candidates across 19 states; of the eleven zero-award states, four (FL, NC, NJ, TN) have unparsed data and seven have nothing. Code those seven `NO_RCJ_DATA` — never anything implying the data doesn't exist. Delaware settled this: seven of eleven verified awards appear in no RCJ endpoint at all. The budget narratives (§7A) determine what actually exists.

**Never auto-promote candidates to `SUBAWARD`** — the whole point is that RCJ's extraction failed here, so a second automated extraction of the same text deserves no more trust. A human or Stage 4 corroboration resolves them.

Known live example: *FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants*, sitting in `/documents` as `REFERENCE` while Florida shows zero awards.

Report the mined candidate count per state — it is the second dimension of the §11 Coverage sheet.

## 7. Stage 3 — State source registry (`03_state_registry.R`)

### 7.1 The state vocabulary comes from CMS, not RCJ

`/states` returns 49 states plus a pseudo-state `US`, and omits Wyoming, which has records on other endpoints. **It must not define the state vocabulary for anything.**

The canonical list is the CMS FY2026 allotment table: exactly 50 rows, authoritative. Every state-keyed join, QA reconciliation, and coverage report keys off it.

**Build `data/reference/cms_fy2026_allotments.csv` first — it is a hard dependency.** Without it, §6.1 rule 3 and the §6.2 allotment ceiling cannot fire, and `STATE_ALLOTMENT` stays at zero rows (Missouri's $216M sits in `UNASSIGNED` for want of a number to match against).

Parse it from the CMS press release, which carries the complete alphabetical list with exact amounts:
`https://cms.gov/newsroom/press-releases/cms-announces-50-billion-awards-strengthen-rural-health-all-50-states`

Requires `cms.gov` on the environment allowlist (§3.2). **Never transcribe these figures by hand** — this file is the reconciliation anchor for every QA assertion, so a typo in it corrupts everything downstream. Assert on parse: exactly 50 rows, sum ≈ $10B, min ≈ $147M (NJ), max ≈ $281M (TX).

Name the column `fy2026_allotment` with the year explicit. Year 2 awards flow from October 1 and CMS may adjust amounts based on demonstrated state progress, so this is a year-specific figure, not a constant.

`qa$allotment_expected_states` stays at **50** — when it fails against RCJ-derived data, that is the assertion working, not a false positive. Report the shortfall as a coverage gap.

`RC` also appears as a junk state code carrying 54 documents; filter it in Stage 2 (§6.2) rather than accommodating it here.

### 7.2 Seed the registry from `/activity`, then verify by hand

`siteUrl` is present on **all 1,787 `/activity` records** — a much better input than the spec originally assumed. Extract distinct `siteUrl` hosts by state to generate a candidate registry, then have a human verify and correct it. This converts the task from "compile 50 URLs from scratch" to "check a machine-generated list," which is both cheaper and likely more complete.

The generated candidates are a starting point, never the final registry. Every row still needs `last_verified` set by a person who loaded the URL.

**This is the critical path.** `state_source_url` is present on only 13% of `/awards` records and 6% of `/documents` records, so the registry — not RCJ — is how Stage 4 finds anything. Nothing downstream works without it, automated or manual. Build it before Stage 4 is designed.

The seed run produced 151 candidate hosts across all 50 states and surfaced `vhhafoundation.org` alongside Virginia's state domain — a pass-through administrator nobody would have known to look for. Verifying 151 candidates down to 50 confirmed rows is a couple of hours of browser work and unblocks everything after it.

Output: `data/reference/state_source_registry.csv`, 50 rows, committed.

### 7.3 Registry fields

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

## 7A. Stage 2.5 — State budget narratives (`03b_budget_narratives.R`)

**This is the backbone table (§0.1). Build it before Stage 4.**

### 7A.1 What these documents are

CMS required a budget narrative from every state as part of the RHTP cooperative agreement, with revised versions due roughly 30 days after the December 29, 2025 award announcement. They decompose a state's allotment into named initiatives with dollar figures and activity categories.

**Two states are extracted and committed as reference implementations** — build the parser against both, not either:

- `OK_initiative_table.xlsx` — Oklahoma, 28 fund uses, structured and repeating, one page per fund use, Lead Agency named throughout.
- `DE_initiative_table.xlsx` — Delaware, 15 initiatives, narrative and variable, contract-by-contract, recipients mostly TBD.

They are formatted so differently that a parser tuned to one will fail on the other. Assume format variation is the norm.

Other known live examples: California's CalRHT Budget Narrative and Notice of Award, Kansas's Year 1 Budget Narrative Revision 2, Oklahoma's Initiative Funding Summary.

Many are linked from the state RHTP program pages already being verified in §7.2, so collection partly rides along with registry verification.

### 7A.2 Collection

Target: **50 documents, one per state**, committed under `data/evidence/budget_narratives/<state>/`.

This is a bounded, checkable task in a way nothing sourced from RCJ is — you know when you have all fifty. Track completeness explicitly in `data/reference/budget_narrative_status.csv` with `state`, `document_url`, `document_date`, `version`, `archive_path`, `collected_by`, `collected_date`, and `status` ∈ `COLLECTED` | `NOT_FOUND` | `REQUESTED`.

Where a state hasn't published one, record `NOT_FOUND` with the date searched. A missing narrative is a reportable gap, not a silent omission.

### 7A.3 The initiative table

Parse each narrative into `data/interim/initiatives.rds`, one row per initiative:

`state`, `initiative_id`, `initiative_name`, `initiative_budget`, `activity_type`, `activity_type_raw`, `initiative_description`, `named_recipient_or_contractor`, `recipient_status`, `flow_type`, `has_hospital_recipient`, `evidence_from_document`, `budget_narrative_version`, `source_archive_path`, `page_reference`, `extraction_method`

`recipient_status` ∈ `NAMED` | `NAMED + TBD` | `TBD`. Most initiatives will be `TBD` — Delaware names a recipient for only 4 of 15. `evidence_from_document` holds the sentence that supports the `has_hospital_recipient` call, so a reviewer can check the classification without reopening the PDF.

`page_reference` matters — a reviewer must be able to open the archived PDF at the right page to check a figure.

### 7A.4 Reconciliation is the QA gate — and it works

For each state, the sum of `initiative_budget` must reconcile to that state's `fy2026_allotment` from §7.1. **A state that doesn't reconcile has a bad parse and is quarantined, not published.**

**Both reference states reconcile, by different structures.** The tolerance must accommodate both:

| State | Award | Narrative total | Structure |
|---|---|---|---|
| **Delaware** | $157,394,964 | $157,394,963.86 | Exact — admin and indirect **inside** the total |
| **Oklahoma** | $223,476,948.62 | $204,900,000 allocated | 91.7% — admin and indirect **outside** the fund-use lines |

So the gate is: **either the narrative total matches the award within rounding, or the sum of allocated fund uses falls between 85% and 100% of it** with the remainder attributable to administrative and indirect costs. Record which pattern a state follows in `reconciliation_structure` ∈ `TOTAL_INCLUSIVE` | `ALLOCATED_ONLY`.

Reconciling at 91.7% is not a failure; reconciling at 60% is. Anything below 85% goes to review before it is called a bad parse.

This self-validation is the central advantage of the backbone approach and RCJ offers no equivalent. Record `reconciliation_pct`, `reconciliation_structure`, and `reconciliation_status` per state.

### 7A.5 What budget narratives do and do not give you

**They give you dollars and, at best, a recipient *class*. They do not give you recipients.**

Oklahoma names a Lead Agency for all 28 fund uses. Delaware names a subrecipient for 4 of 15 initiatives and no hospital anywhere. Treat named recipients as a bonus, never a dependency — a parser that requires them will fail on most states.

What is reliably extractable, and enough for Deliverable 2:

- initiative name and dollar amount
- administering agency or lead entity, where stated
- **flow language** — the sentence describing who the money reaches. This is what populates `has_hospital_recipient` without any recipient being named. Oklahoma: *"hospitals reimbursed for CHW hiring, training, and monitoring."* Delaware: *"fund healthcare systems and educational institutions to expand training capacity."* Both support a hospital-directed call; neither names a hospital.

An initiative flagged `has_hospital_recipient` carries the dollar figure in the §11 deliverable. **That flag, not a per-hospital split, is the unit.**

Never divide an initiative budget across its recipients. States don't publish the split, and inventing one would be the most damaging thing this project could do.

### 7A.5a Deliverable 1 comes from award notices, not from here

Recipient identity emerges **after** the budget narrative, through state procurement. Delaware's Initiative 3 is $195,000 with "Vendor TBD"; the school-based health center awards to Beebe Healthcare, TidalHealth, and Nemours were independently verified from a governor's announcement that post-dates the narrative.

So RCJ Tier 3 records and §6.4 mined candidates attach to initiatives by matching on state plus initiative name or activity type — fuzzy, routed to the review queue, never auto-resolved. That linkage enriches the initiative table; it is not how the table is built.

**Do not collapse the two sources.** Stage 2.5 produces Deliverable 2 from narratives. Stage 4 produces Deliverable 1 from award notices. Neither is a shortcut to the other.

---

## 8. Controlled vocabularies

Store as `data/reference/vocabularies.csv` and validate every categorical column against it. No free-text categories anywhere.

**`award_tier`:** `STATE_ALLOTMENT` | `SOLICITATION` | `SUBAWARD` | `UNASSIGNED`

**`source_doc_type`:** `NOTICE_OF_AWARD` | `NOTICE_OF_INTENT_TO_AWARD` | `PROCUREMENT_PORTAL_POSTING` | `STATE_BUDGET_NARRATIVE` | `AGENCY_PRESS_RELEASE` | `GOVERNOR_PRESS_RELEASE` | `THIRD_PARTY_NEWS` | `OTHER`
*(Strength ordering matters: the first three are primary; press releases are secondary; third-party news alone can never support a `Yes`.)*

**`recipient_type`:** `HOSPITAL_OR_SYSTEM` | `HOSPITAL_AFFILIATED_ENTITY` | `FQHC_OR_RHC` | `EMS_OR_PSAP` | `UNIVERSITY_OR_AHC` | `AHEC` | `SCHOOL_OR_DISTRICT` | `LOCAL_GOVT_OR_PUBLIC_HEALTH` | `TRIBAL_ORG` | `STATE_AGENCY` | `VENDOR_OR_CONTRACTOR` | `NONPROFIT_CBO` | `NOT_YET_NAMED`

**`flow_type`:** `DIRECT` | `PASS_THROUGH_DESIGNATED` | `PASS_THROUGH_UNRESOLVED` | `IN_KIND_BENEFIT` | `NON_HOSPITAL`

**`distributed_to_hospital`:** `Yes` | `No` | `Unclear`

**`determination_confidence`:** `HIGH` | `MEDIUM` | `LOW`

**`extraction_method`:** `DIRECT_TEXT` | `MODEL_ASSISTED` | `MANUAL`

**`recipient_confirmed`:** `Yes` | `No` | `Unclear`

**`amount_confirmed`:** `Yes` | `No` | `Unclear` — `No` is the expected common case; it means no recipient-level figure is published, not that verification failed

**`reconciliation_status`:** `RECONCILED` | `VARIANCE` | `FAILED` | `NO_NARRATIVE`

**`validator`:** `AUTO` | reviewer initials

**`flag_reason`** additions: `PROVENANCE_MISMATCH` | `AMOUNT_PLACEHOLDER` | `AMOUNT_NULL_SENTINEL` | `SOURCE_IS_PLAN_NOT_AWARD` | `UNPARSED_AWARD_CANDIDATE` | `UNPARSED_DATA_EXISTS` | `NO_RCJ_DATA` | `MULTI_RECIPIENT_FIELD` | `JUNK_STATE_CODE` | `TITLE_JUNK` | `EVENT_BLEED` | `DEDUP_COLLISION`

**`activity_type`:** map to the CMS RHTP allowable-use categories (the CMS category guidance series — e.g. Category E covers workforce). Retain the state's own raw activity language in a parallel `activity_type_raw` field; never discard it.

---

## 9. Stage 4 — Automated validation and evidence capture (`04_validate.R`)

**Contract:** for every Tier 3 candidate, retrieve and archive the primary state source, corroborate the award deterministically, and resolve confirmation status. Manual review handles the residual, not the bulk.

### 9.1 Why this is automated, and what that constrains

Manual validation of every award does not scale past a pilot. But automation must produce **auditable determinations, not model judgments**. The claim this stage must support is:

> The recipient name and the award amount both appear in an archived document retrieved from a host verified in the §7 registry on this date, and that document carries RHTP program markers and no competing federal program markers.

That is checkable by anyone who opens the archive. *"The model read it and concluded the award was confirmed"* is not, and would forfeit the provenance discipline the rest of this spec exists to protect.

**The governing rule: models find things, rules decide things.**

### 9.2 Cluster by document before fetching anything

Many awards share one source document — a single Notice of Intent to Award may list forty recipients. **The unit of work is the document, not the award.**

Group Tier 3 candidates by `sourceDocument.id` and by resolved `state_source_url` before any retrieval. Fetch each distinct document once, archive it once, and corroborate every award that traces to it against that one archive.

Do this first and measure the result. If a few hundred candidates collapse to sixty or ninety distinct documents, the problem is an order of magnitude smaller than the raw record count suggests.

### 9.3 Split confirmation — two independent claims

**Delaware's premise test found recipient names available and recipient-level amounts unavailable.** Four of eleven records carried the `federalAmount: 1` placeholder, seven were blank, and the reviewer's note recurred verbatim: *award amount not available for this specific awardee.* Amounts existed only at initiative level.

A single blended verdict therefore fails: requiring an amount match sends every Delaware record to review and leaves the auto-confirm tier permanently empty. Split it.

**`recipient_confirmed`** — a named recipient appears in a state source. Signals:

| Signal | Test |
|---|---|
| Domain trust | Retrieved from a host verified in the §7 registry for that state |
| Recipient match | `awardee_name_clean` found in extracted text, normalized for legal suffixes, `&`/`and`, and DBA variants |
| Program marker | RHTP identifiers present **and** no competing federal program markers (HRSA, USDA RD, FCC/USAC, Flex/SORH) |

All three → `Yes`, `HIGH`. Two → review queue. Fewer → `Unclear`.

**`amount_confirmed`** — a **recipient-level** dollar figure appears in a state source. Requires all three signals above **plus** an amount match in any standard rendering (`$11,500,000`, `$11.5 million`, `11500000`, `$11.5M`).

An initiative-level budget figure **never** confirms a recipient-level amount. That distinction is the whole point.

A row may legitimately be `recipient_confirmed = Yes, HIGH` and `amount_confirmed = No`. That is honest and useful; forcing it to `Unclear` discards a real finding.

Store which signals fired in `corroboration_signals` on every row, so an auditor sees why a record was coded as it was without reopening the source.

**The governing rule stands: models find things, rules decide things.**

### 9.4 Where a model is permitted

**One place: extraction, not adjudication.** Pulling a structured table of `(recipient, amount, date)` from a state PDF is something models do well and regex does badly, because state document layouts are wildly inconsistent.

The extracted table is then matched **deterministically** against the RCJ record per §9.3. The model proposes candidates; string matching decides. If the model extracts a recipient that does not match, the record goes to review — **the model never asserts a confirmation.**

Model-assisted extraction is recorded as `extraction_method = MODEL_ASSISTED` so those rows can be audited as a group.

### 9.5 Network access and conduct

Fetching arbitrary state domains requires **Full** network access on the cloud environment. This was an unattractive trade when validation was manual; with automation it is the only workable option.

Mitigate by logging **every fetched host** to the pull manifest, preserving an audit trail of exactly where the pipeline went.

Fetching 50 state government sites imposes obligations:

- Throttle to roughly **one request per host every 3–5 seconds**, independent of the RCJ throttle
- Set a descriptive user agent identifying AHA and a contact address
- Respect `robots.txt`
- **Cache aggressively** — a re-run must never re-fetch an unchanged document
- Back off and stop on repeated 403/429 from a host

Getting blocked by a state IT department mid-project would be genuinely disruptive and hard to reverse.

### 9.6 Evidence capture — required for every validated row

- `state_source_url` — the specific page or document, **not** the program homepage
- `validation_source_type` — from the `source_doc_type` vocabulary
- `validation_date_accessed`
- `validation_archive_path` — archived copy committed under `data/evidence/<state>/`. Not optional. State pages get restructured without notice, and a figure whose source has moved is a figure that cannot be defended
- `confirming_text` — the sentence establishing the award, stored in the row
- `corroboration_signals`, `extraction_method`, `validator` (`AUTO` or initials), `validation_date`

### 9.7 Confirmation decision rules

Applied independently to each of the two claims in §9.3.

**`Yes`** — the required signals fired, **or** a human confirmed against a `NOTICE_OF_AWARD`, `NOTICE_OF_INTENT_TO_AWARD`, `PROCUREMENT_PORTAL_POSTING`, `STATE_BUDGET_NARRATIVE`, or an official agency/governor release naming the recipient.

**`No`** — the state source contradicts RCJ, or shows the solicitation cancelled, withdrawn, unawarded, or re-opened without award. For `amount_confirmed`, `No` also means simply that no recipient-level figure is published — the common case, and not a failure.

**`Unclear`** — the only source is third-party news; sources conflict; the page names no recipients (Delaware's "Not identified" row, where the state confirms an award but names nobody); the record is a pass-through pool with unresolved subrecipients; or the source is a plan or projection rather than an award action.

Third-party news can never support a `Yes`, automated or otherwise.

### 9.8 Sampling instead of full review

Do not manually review every auto-confirmed record. Review a **stratified random sample** — roughly 30 from `HIGH`, 30 from the review tier — and **measure the error rate**.

If auto-`Yes` shows an error rate under 2–3%, report the automated determinations with that measured rate attached. This is ordinary practice for automated coding and is more defensible than an unmeasured full-manual pass, because it comes with a number.

Record `sample_error_rate` and the sample size in the workbook README (§11). Re-sample whenever `rules_version` changes.

Human time goes to the sample and to genuinely ambiguous records — not to the easy majority.

### 9.9 What stays human

The `flow_type` determination in §10.2 — whether a pass-through intermediary's money reaches hospitals — cannot be automated. It requires reading the solicitation's eligibility terms.

But it is a **per-program judgment, not per-award.** Virginia's VHHA Foundation programs are classified once, and every award under them inherits the classification. Across 50 states this is perhaps 50–100 decisions, made once and revisited only when a program changes.

Store these in `data/reference/program_flow_classifications.csv`, keyed by program or solicitation identifier, committed, with the reasoning recorded per row.

### 9.10 Realistic effort

| Task | Effort |
|---|---|
| Verify 151 candidate hosts → 50 registry rows | ~2 hours, once |
| Classify 50–100 programs for `flow_type` | ~3 hours, once |
| Review sample + ambiguous records, first pass | ~4–6 hours |
| Per-refresh review thereafter | ~1 hour |

Per-refresh cost stays flat: unchanged records inherit prior determinations via `rcj_record_hash` (§6.3).

### 9.11 Premise test — resolved (Delaware, 11 records)

Run by a human reviewer against Delaware state sources. Results:

| Question | Answer |
|---|---|
| Do state documents name subrecipients? | **Yes** — Beebe Healthcare, TidalHealth, Nemours, Thomas Jefferson University, DHIN |
| Are recipient-level amounts published? | **No** — 0 of 11. Initiative-level only |
| Do the §9.7 rules survive real state pages? | Yes, once confirmation is split (§9.3) |
| Are state sources findable and archivable? | Yes — DE Bids Contracts procurement portal, State of Delaware News, the budget narrative PDF |

Two structural findings came out of it:

- **Seven of eleven records exist in no RCJ endpoint at all.** RCJ is missing awards entirely, not merely misfiling them. This is what drove the §0.1 inversion.
- **The reviewer worksheet's validation URL column held page titles, not URLs.** Nothing archivable. The §9.12 worksheet must validate URL format on entry.

### 9.12 Reviewer worksheet requirements

Human review happens in Excel, exported and read back. The worksheet must:

- Carry a `state_source_url` column that **rejects non-URL values** on read-back. Page titles are not sources.
- Include `recipient_confirmed` and `amount_confirmed` as separate columns, never one merged field.
- Include `archive_path`, and refuse a `Yes` on either claim without one.
- Restate the §0.3a rule — code the recipient, not the activity — in the header row and in `reviewer-coding-instructions.md`, which every reviewer reads first.
- Validate all categorical entries against §8 on read-back, rejecting malformed rows rather than ingesting them.

## 10. Stage 5 — Hospital determination (`05_hospital_determination.R`)

Two axes. "Money reaches a hospital" and "we can prove it" are different claims and need separate columns.

### 10.0 The rule that governs both axes

**Classify the recipient, not the activity** (§0.3a). Worked examples from the Delaware verification:

| Record | Wrong | Right |
|---|---|---|
| Beebe Healthcare — Georgetown Middle School SBHC | `no` (activity is a school) | **`Yes`** — `HOSPITAL_OR_SYSTEM`, `DIRECT` |
| TidalHealth — Selbyville Middle School SBHC | `no` | **`Yes`** — `HOSPITAL_OR_SYSTEM`, `DIRECT` |
| Nemours Children's Health — Seaford Middle School | `no` | **`Yes`** — `HOSPITAL_OR_SYSTEM`, `DIRECT` |
| Beebe Medical Center — diabetes pilot | `no` | **`Yes`** — `HOSPITAL_OR_SYSTEM`, `DIRECT` |
| Thomas Jefferson University — medical school | — | `No` — `UNIVERSITY_OR_AHC` |
| Delaware Health Information Network | — | `No` — `VENDOR_OR_CONTRACTOR`, `IN_KIND_BENEFIT` |
| "Not identified" — VBC readiness | — | `Unclear` — `NOT_YET_NAMED` |

At least 6 of 11 Delaware records are hospital recipients. Coded by activity, the state total would have been zero.

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
| `NON_HOSPITAL` | Recipient is clearly not a hospital — a school district, a university, an EMS agency, a vendor. **Judge the recipient, never the activity (§0.3a):** Nebraska's school kitchen modernization awarded to the Department of Education is `NON_HOSPITAL`; Delaware's school-based health center awarded to Beebe Healthcare is `DIRECT`. Same setting, different recipients, different codes. | `No` |

`IN_KIND_BENEFIT` deserves its own flag rather than being discarded: it is substantively important to AHA's narrative even though those dollars must never enter a "funds distributed to hospitals" total.

### 10.3 Required accompanying fields

- `determination_confidence` — `HIGH` (primary source, named hospital recipient, CCN matched) / `MEDIUM` (primary source, hospital identity inferred from name without CCN match) / `LOW` (secondary source or unresolved pass-through).
- `flow_type` is inherited from `data/reference/program_flow_classifications.csv` (§9.9) where the award's program is classified; only unclassified programs need a fresh judgment.
- `determination_basis` — free text, mandatory. When someone asks in six months why a $12M award was coded hospital-bound, the answer must be in the row.
- `reviewer`, `review_date`, `rules_version` (see §13).

---

## 11. Stage 6 — Excel deliverable (`06_build_workbook.R`)

`openxlsx`, one workbook, sheets in this order:

1. **README** — generation date, pull date range, `rules_version`, tier definitions, the §0.3a recipient-not-activity rule, the eligibility-is-not-receipt warning, a plain statement that Tier 1/2/3 figures must never be summed, **a plain statement that per-hospital dollar amounts are not published by states and are not reported here**, and the §9.8 `sample_error_rate` with its sample size.
2. **Coverage** — sits second, before any figures. Per state: budget narrative collected (Y/N), initiative-level reconciliation status and percentage, RCJ `/awards` records parsed (39 of 50; blanks are AR, FL, KY, MA, MN, NJ, NY, NC, SC, TN, WY), and §6.4 unparsed candidate count. Three states of interest:

   - **Parsed** — 39 states with RCJ `/awards` records.
   - **`UNPARSED_DATA_EXISTS`** — FL, NC, NJ, TN. Data exists; RCJ failed to extract it. Florida is the worked example.
   - **`NO_RCJ_DATA`** — the remaining seven. This says nothing about whether awards exist; it says RCJ has none.
3. **Hospital Recipients — Deliverable 1.** Named hospitals receiving RHTP funds: hospital, CCN, state, rural designation, initiative, `recipient_confirmed`, source URL, archive path. **No dollar column.** This is the primary product.
4. **Initiative Dollars — Deliverable 2.** One row per initiative from §7A.3: state, initiative, budget, activity type, `has_hospital_recipient`, named recipients, reconciliation status and structure. Dollars live here and only here. **Report hospital-directed share by state, never as a national average** (§0.1b).
5. **Subawards (Tier 3)** — the full record-level table with both confirmation columns.
6. **Solicitations (Tier 2)** — announced pools, physically separate.
7. **State Allotments (Tier 1)** — exactly 50 rows, sourced from `cms_fy2026_allotments.csv`. The 274 RCJ `STATE_ALLOTMENT` records are references, not rows here (§0.2a).
8. **State Source Registry** — the §7 reference table.
9. **Review Queue** — unresolved records.
10. **Flagged / Quarantined** — junk-filter catches with `flag_reason`, plus states failing §7A.4 reconciliation.
11. **Change Log** — records added, changed, or superseded since the prior build.
12. **Data Dictionary** — §12 rendered as a sheet.

**Sheets 3 and 4 must not be joined into one.** A hospital-name table with a dollar column beside it invites exactly the per-hospital attribution that states don't publish and §7A.5 forbids.

Formatting: freeze the header row, autofilter on all data sheets, currency format on amount columns, conditional fill on `distributed_to_hospital` (Yes/No/Unclear), and hyperlinks on `state_source_url` and `validation_url`. Column widths set explicitly, not auto.

Filename: `rhtp_hospital_tracker_<YYYY-MM-DD>.xlsx`. Never overwrite a prior build.

---

## 12. Data dictionary

**Identity & provenance**
`record_id`, `rcj_record_hash`, `pull_date`, `first_seen`, `last_seen`, `superseded_by`, `award_tier`, `rules_version`

**Initiative link (§7A)**
`initiative_id`, `initiative_name`, `initiative_budget`, `has_hospital_recipient`, `budget_narrative_version`, `page_reference`, `reconciliation_status`

**Award core**
`date_announced`, `date_effective`, `state`, `state_name`, `fiscal_year`, `rhtp_budget_period`, `solicitation_number`, `awardee_name_raw`, `awardee_name_clean`, `intermediary_name`, `amount_announced`, `amount_obligated`, `amount_basis`, `match_amount_rcj`, `applicant_cost_share_required`, `cost_share_pct`, `activity_type`, `activity_type_raw`, `program_description`, `source_doc_title`, `rcj_document_url`, `state_source_url`, `source_doc_archived_path`

**Validation**
`state_source_url`, `validation_source_type`, `validation_date_accessed`, `validation_archive_path`, `confirming_text`, `corroboration_signals`, `extraction_method`, `recipient_confirmed`, `amount_confirmed`, `validator`, `validation_date`, `validation_notes`

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
14. Every `state` value validates against the 50-row CMS list from §7.1. No `RC`, no `US`, no null.
15. Every row with `distributed_to_hospital = Yes` and `validator = AUTO` has all four §9.3 signals recorded in `corroboration_signals`.
16. No row with `validation_source_type = THIRD_PARTY_NEWS` carries `rhtp_award_confirmed = Yes`, regardless of validator.
17. `cms_fy2026_allotments.csv` has exactly 50 rows, sums to approximately $10B, and its min and max fall near $147M and $281M. Assert on load, not on use.
18. No record was promoted to `SUBAWARD` from a §6.4 mining candidate without a human or §9.3 resolution.
19. Every fetched host in Stage 4 appears in the §7 registry for that state. A fetch from an unregistered host is a provenance break, not a convenience.
20. **No initiative budget is divided across recipients.** Assert that no per-recipient dollar column exists in the Hospital Recipients sheet at all — the structural guard against inventing a split states don't publish (§7A.5).
21. Every state with a collected budget narrative has `reconciliation_status`; no `FAILED` state appears in a published sheet.
22. `amount_confirmed = Yes` requires all four §9.3 signals including a recipient-level amount match. An initiative-level figure never satisfies it.
23. Every reviewer-supplied `state_source_url` parses as a URL. Page titles are rejected on read-back (§9.12).
24. Tier 1 figures in any published sheet come from `cms_fy2026_allotments.csv` (50 rows), never from the RCJ `STATE_ALLOTMENT` records, which are references only (§0.2a).
25. Every RCJ `STATE_ALLOTMENT` record is compared to the CMS figure for its state; disagreements are reported, not resolved silently.
26. No row carries `MULTI_RECIPIENT_FIELD` and an auto-resolved hospital match. Splits go to review.
27. All rows in a build share one `rules_version`, including rows whose payload hash was unchanged since the prior build.
28. **Manifest schema is pinned.** The pull manifest is written against an explicit column schema and refuses to write on header mismatch. `write_csv(append = TRUE)` writes positionally, so a schema drift silently shifts every value one column and reports success — this happened once in Session 3 and was caught only by inspection.

**Version the classification rules.** The determination logic in §10 will change as edge cases surface. Store `rules_version` on every row and tag the repo at each build, so you can always say which rules produced a published figure.

---

## 14. Scope

**Fifty states at initiative level. Deep recipient attribution for a subset.**

The budget narratives make 50-state coverage feasible because it is fifty documents with a reconciliation check (§7A.4). Per-recipient verification is the part that does not scale, so spend it where it matters.

**Deep-attribution subset:** roughly 15 states, chosen for rural hospital density and AHA member concentration. Include the following for structural reasons:

| State | Why |
|---|---|
| **Delaware** | Premise test baseline; 11 records already verified |
| **Georgia** | Awardee data present, NOIs posted — the happy path |
| **Virginia** | VHHA Foundation pass-through; tests `PASS_THROUGH_DESIGNATED` vs `_UNRESOLVED` |
| **Florida** | Zero RCJ awards, data exists via AHCA procurement portal — tests §6.4 mining end to end |
| **Oregon** | 99 uniform $100,000 hospital awards — tests dedup and bulk direct attribution |
| **Pennsylvania** | 66 named hospitals under a plan-titled document — tests §6.2 flag-not-reassign |
| **Nebraska** | School kitchen and farm-to-school awards — negative cases |
| **Texas** | Largest allotment, observed junk titles |

Add the remaining states by rural hospital count.

---

## 15. Session sequencing for Claude Code

Build in this order. Each session ends with a working, tested stage, **all persistent output committed**, and an updated "current state" section in `CLAUDE.md`.

1. ~~**Session 1** — Repo scaffold, `CLAUDE.md`, config, Stage 0 preflight.~~ **Complete.** Findings folded into §4. Vocabularies and junk-pattern reference files seeded. Delaware's 15 records committed as Stage 2 fixtures.
2. ~~**Session 2** — §5.1 pagination test.~~ **Complete.** Branch A confirmed; findings in §5.1.
3. ~~**Session 3** — Stage 1 retrieval client and first national pull.~~ **Complete.** 60 calls, all endpoints exhaustive; findings in §4.1 and §5.1.
4. ~~**Session 4** — Stage 2 normalization.~~ **Complete.** 5,152 records; 1,016 clean Tier 3 across 38 states. Five spec rules corrected (§6.1, §6.2, §6.3). Registry seed: 151 candidates.
5. ~~**Delaware premise test.**~~ **Complete** — §9.11. Drove the §0.1 inversion and the §9.3 split.
6. **Now — write `reviewer-coding-instructions.md`** before any further human review. Half a page, §0.3a with the Delaware worked examples. Everything downstream depends on humans applying it consistently, and it went wrong on the first eleven records.
7. ~~**Session 5** — CMS allotments, mining, registry worksheet.~~ **Complete.** Anchor built: 50 states, $10,000,000,003. `STATE_ALLOTMENT` 0 → 274 rows. Mining: 38 candidates across 19 states, Parrish caught. Registry worksheet: 151 candidates. Change-detection defect on derived columns found and fixed.
8. **Offline — verify the registry** (~2 hours), and while in each state's pages, capture the budget narrative URL for §7A.2.
9. **Session 6 — Stage 2.5.** Three tasks: (a) finish Delaware initiatives 13-15, truncated in the manual extraction, ~$10.1M of contractual; (b) extract the 16 remaining CMS abstracts (OH through WY); (c) build the narrative parser against **both** reference tables per §7A.2, and reconcile against CMS allotments (§7A.4).
10. **Session 7 — Stage 4.** Document clustering (§9.2), fetcher with §9.5 conduct rules, split-confirmation corroborator (§9.3). Requires **Full** network access — clear with AHA IT before this session.
11. **Offline — program flow classifications** (~3 hours), `program_flow_classifications.csv` per §9.9.
12. **Session 8 — Stage 5** hospital determination, AHA/POS crosswalk, fuzzy-match review queue.
13. **Session 9 — Stage 6** workbook and full QA suite. Draw the §9.8 sample, record the error rate.
14. **Session 10** — review, revise rules, bump `rules_version`, extend attribution to the full §14 subset.

The AHA Annual Survey and CMS Provider of Services extracts needed in Session 8 must be committed to the repo before that session starts — cloud sessions can't reach internal AHA systems.

### Opening prompt for the next session

> Continuing the RHTP tracker. Re-read `rhtp-tracker-build-spec.md` — §0.1a, §0.1b, §7A.2, §7A.3, §7A.4, §7A.5 and §7A.5a have all changed after Delaware was extracted by hand.
>
> Headline changes: budget narratives give dollars and flow language but mostly NOT recipients (Delaware names 4 subrecipients across 15 initiatives and no hospital at all); Deliverable 1 comes from award notices, not narratives; and hospital-directed share ranges 15.7%–48.7% across the two reference states, so never report a national average.
>
> Three tasks this session:
>
> 1. Finish Delaware initiatives 13-15. The manual extraction truncated at Initiative 12; roughly $10.1M of contractual is unaccounted. The PDF is at `https://dhss.delaware.gov/wp-content/uploads/sites/12/2026/06/Final-RHTP-Revised-Budget-1.30.26.pdf`. Add `dhss.delaware.gov` to the allowlist if needed.
> 2. Extract the remaining 16 CMS abstracts (OH through WY) from `https://www.cms.gov/files/document/rht-program-state-provided-abstracts.pdf` into the candidate table. `cms.gov` is allowlisted. Remember §4.1: abstract dollar figures are illustrative and unusable; only named organizations are extracted, and they are candidates only.
> 3. Build the Stage 2.5 narrative parser against **both** `OK_initiative_table.xlsx` and `DE_initiative_table.xlsx`. They are formatted very differently on purpose — a parser tuned to one will fail on the other. Implement the §7A.4 two-pattern reconciliation gate.
>
> Do not start Stage 4. The registry is still unverified.
>
> Open a PR. Reminders: never print `RCJ_API_KEY`; `data/raw/` is committed, not ignored; tidyverse and `%>%` only.
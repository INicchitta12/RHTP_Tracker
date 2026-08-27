# Stage 1 — first production national pull

**Run:** 2026-08-27 (Session 3)
**Script:** `R/01_retrieve_rcj.R --run`
**Strategy:** Branch A — national, unfiltered, partitioned by state in Stage 2.
**Result: complete. All five endpoints exhaustive, nothing capped, nothing drifted.**

---

## 1. What landed

`data/raw/rcj/2026-08-27/`

| Endpoint | Envelope | Reported total | Records written | Pages | Requested limit | Served limit |
|---|---|---:|---:|---:|---:|---:|
| `/states` | `complete` | 50 | 50 | 1 | 50 | n/a |
| `/awards` | `pagination` | 1,429 | 1,429 | 3 | 500 | 500 |
| `/documents` | `pagination` | 3,092 | 3,092 | 31 | 100 | 100 |
| `/opportunities` | `pagination` | 631 | 631 | 7 | 100 | 100 |
| `/activity` | `hasmore` | n/a | 1,787 | 18 | 100 | n/a |

Every paginated endpoint wrote exactly `pagination.total` records. `/activity`
terminated on `hasMore == false` at page 18, well inside the 40-page ceiling,
so `capped = FALSE`. On-disk size 12 MB.

`/awards`, `/documents`, and `/opportunities` reproduce Session 2's measured
totals exactly (1,429 / 3,092 / 631), which is an independent confirmation that
the Branch A walk is complete rather than coincidentally terminating.

**Cross-check against the Stage 0 fixture:** the national `/awards` pull
contains exactly 15 Delaware records — the same count Session 1's `state=DE`
probe returned. The national walk loses nothing a state-filtered call would
have found.

## 2. API cost — open blocker 3 is now measured

**60 calls for a comprehensive pull**, against the ~46 projected in §5.1.

| Endpoint | Projected (§5.1) | Measured | Delta |
|---|---:|---:|---:|
| `/states` | not budgeted | 1 | +1 |
| `/awards` | 3 | 3 | — |
| `/documents` | 31 | 31 | — |
| `/opportunities` | 7 | 7 | — |
| `/activity` | ~5 | **18** | **+13** |
| **Total** | **~46** | **60** | **+14** |

The gap is `/activity`. The ~5 figure in §5.1 was a *bounded weekly delta* via
`since=`; the **comprehensive backfill is 18 calls / 1,787 records**, which was
explicitly unmeasured and is open blocker 3. It is now measured.

`/states` adds the remaining call. It was not in the §5.1 budget; it is one
call, and Stage 3 needs the canonical state list, so it is now part of the
default pull.

### Revised monthly budget

§5.1 says `/activity` is pulled comprehensively **every time** regardless of
cadence, because it is the only source of `state_source_url`. Taking that
literally:

| Cadence | Calls/pull | Calls/month | % of 2,000 |
|---|---:|---:|---:|
| Weekly | 60 | ~260 | 13% |
| **Twice-weekly (adopted)** | **60** | **~520** | **26%** |

Up from the 20% projected, and still comfortably affordable — roughly 1,480
calls/month of headroom. **The adopted cadence does not need to change.**

If `/activity` is later narrowed to a `since=` delta after this first backfill,
a pull drops to roughly 45 calls (~390/month twice-weekly, 20%). That is the
`activity_since` argument on `rhtp_run_national_pull()`, unused on this run
because there was no prior pull to delta from.

**Two line items to watch as the corpus grows**, both against a hard 100/page
cap: `/documents` at 31 calls and `/activity` at 18. Together they are 49 of
the 60 calls. Every additional 100 records in either adds one call per pull.

**Quota:** 2,000 → 1,920 remaining after the run (80 consumed this month,
including 20 from Session 2's pagination test and this session's probes).

## 3. Corrections to the documented API surface

### 3.1 `/states` is not a paginated endpoint

§4 and `config.yml` both listed `/states` under the
`{data, pagination{page,limit,total,pages}}` envelope. **It is not.** A live
call returns exactly:

```json
{ "data": [ ... 50 items ... ], "count": 50 }
```

No `pagination` object, no `hasMore`, no `page`. It is unpaginated and returns
the complete set in one call.

This surfaced on the very first live call of the session, because
`rhtp_page_plan()` **errors on a missing `pagination.limit` rather than
guessing a page count**. Had it defaulted to the requested limit — the natural
thing to write — it would have walked page 2 of an endpoint that has no pages
and silently produced whatever page 2 returns. The §5.2 guard did exactly the
job it exists for, on its first contact with the API.

Handled by a fourth handler, `rhtp_fetch_complete()`, asserting
`count == length(data)`. `config.yml` now records `envelope: "complete"`.

### 3.2 The manifest schema clash

Session 0 wrote `logs/pull_manifest.csv` with its own column set. The new
writer used a different one, and `readr::write_csv(append = TRUE)` writes
**positionally** — so the first Stage 1 row appended with every value shifted
one column left (`endpoint` into `state`, `params` into `endpoint`) and
reported success.

Fixed by pinning `RHTP_MANIFEST_COLUMNS`, building every row through
`rhtp_manifest_row()`, and having `rhtp_append_manifest()` read the header of
the file it is about to extend and **refuse to write on any mismatch**. The six
Session 0 rows were migrated to the canonical schema — their columns plus the
`requested_limit` / `served_limit` pair §5.2 requires.

## 4. Data-quality findings for Stage 2 and Stage 3

Recorded here, **not acted on**: Stage 1's contract is to land raw records
without transformation.

### 4.1 `/states` is 49 states plus a pseudo-state, and omits Wyoming

The 50 codes returned are **not** the 50 US states. `US` is present as a
national bucket, and **`WY` is absent**. Wyoming nonetheless has records in
`/documents`, `/opportunities`, and `/activity`.

Consequences:
- `/states` cannot be used as the state vocabulary for Stage 3's registry.
- `qa$allotment_expected_states: 50` in `config.yml` will not reconcile against
  a `/states`-derived list. RHTP allotments went to all 50 states; RCJ's
  coverage does not.

### 4.2 `RC` is a junk state code — 54 documents

`/documents` carries 54 records with `state: "RC"`, titled in the form
`"RC - 2026 - Make Telehealth Flexibilities Permanent to Reinforce Rural
Healthcare Funding Report"`, category `REFERENCE`. Not a state. These are
national reference material filed under a non-state code and will corrupt any
state partition that trusts the field.

A Stage 2 junk-filter fixture (§6.2).

### 4.3 `/awards` covers only 39 of 50 states

Eleven states have zero award records in the national pull. This is §0.1's
"awardee-level coverage that is complete in some states and empty in others",
now quantified: **22% of states have no Tier 3 candidates in RCJ at all.**

This is a finding about RCJ's coverage, not about those states' RHTP activity.
It reinforces §0.1 — the state source registry, not RCJ, is what bounds
completeness.

### 4.4 `/activity` carries `siteUrl` on every record

All 1,787 records have a populated `siteUrl`, and the values are real state
domains — `tn.gov/health/rural.html`, `resources.hhs.texas.gov/rfa`,
`hcpf.colorado.gov/rural-health-transformation-program`,
`dhss.bonfirehub.com/portal/`. This confirms §4.1: `/activity` is the only
source of `state_source_url` and is a primary endpoint, not a delta gate.

It is also the single most useful input to Stage 3's registry, which was
assumed to be compiled entirely by hand.

## 5. Landing-zone layout

The production snapshot shares its date directory with Session 1's Stage 0
Delaware probes. To stop a Stage 2 glob sweeping the probes into the record
table and double-counting Delaware, those files moved to
`data/raw/rcj/2026-08-27/_stage0_exploratory/` with a README. Nothing was
deleted — they remain the evidence behind `stage0_preflight_findings.md` and
the Stage 2 test fixtures.

**The production snapshot is the five `<endpoint>.json` files in the parent
directory**, each carrying a `pull_metadata` block.

### File format

```
{ "pull_metadata": { endpoint, envelope, pull_date, retrieved_at, strategy,
                     requested_limit, served_limit, limit_downgraded,
                     reported_total, pages_walked, records_written,
                     exhaustive, total_drifted, capped, rules_version },
  "pages": [ { page, http_status, n_records, body_sha256, body } ] }
```

`pages[].body` is the parsed response re-serialised as pretty JSON, so the
committed landing zone diffs legibly between pulls. `pages[].body_sha256` is
sha256 of the **verbatim** response text, computed before re-serialisation — the
byte-fidelity anchor, and the input Stage 2 (§6.3) can use for change detection
at page granularity.

## 6. What the client guarantees

- **Never trusts its own requested `limit`.** Page counts come from the
  response's served limit. A downgrade is detected, warned, and recorded in
  `pull_metadata.limit_downgraded`. Not triggered on this run, because the
  client requests each endpoint's true maximum — but it is the guard that makes
  that safe to assume.
- **Exhaustiveness is a hard error.** On the pagination envelope, records
  collected must equal `pagination.total` or nothing is written.
- **No silent caps.** `/activity` has no `total` to assert against, so the
  `hasMore` walk is bounded by `pull$activity_max_pages`; hitting it warns and
  sets `capped = TRUE` in the written metadata.
- **Mid-walk drift is recorded.** A `pagination.total` that moves between pages
  means the corpus changed under us; it warns and sets `total_drifted`.
- **Quota accounting on every call**, written to the manifest immediately so a
  crash still leaves the record, aborting at 90% consumed.
- **The API key never leaves memory.** The auth header is registered with httr2
  as redacted; every manifest string passes through `rhtp_redact()`.
- **Sourcing the script spends nothing.** A pull runs only under `--run`.

## 7. Environment defect fixed

Cloud sessions start R in the **C/POSIX locale** (`LANG` unset), where
`readLines()` and every `stringr` operation fail on multibyte UTF-8.
`config/config.yml` was itself unreadable — `rhtp_config()` failed on its
section-sign and em-dash characters before any network call was possible.

`utils_config.R` now sets a UTF-8 locale at `source()` time, so every stage
inherits it, and `rhtp_preflight()` reports the state. This matters beyond the
config file: RCJ titles and awardee names carry non-ASCII text that would
otherwise corrupt on read.

Worth adding `LANG=C.UTF-8` to the environment's variables so the fix is
belt-and-braces rather than code-only.

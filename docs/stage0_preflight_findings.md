# Stage 0 — Preflight findings

**Date:** 2026-08-27 · **Session:** 1 · **Spec reference:** §4
**Source of record:** `data/raw/rcj/2026-08-27/` (raw responses and archived docs)
**API calls consumed:** 6 of a 2,000/month allowance

This document is authoritative for the RCJ API surface. Read it before writing
any retrieval code. Every claim below was verified against a live response, not
inferred from the documentation.

---

## 1. Endpoint list

Base URL `https://www.ruralcarejourney.com`. `rhtp.amemobile.net` is documented
as also working and supported for existing integrations. All versioned
endpoints sit under `/api/v1/`. All return JSON.

| Endpoint | Method | Auth | Purpose | Relevance to us |
|---|---|---|---|---|
| `/api/stats` | GET | **none** | Headline dashboard counts | Free health check — costs no quota |
| `/api/v1/states` | GET | key | 50 states with document counts, award totals, summaries | Tier 1 cross-check |
| `/api/v1/states/:code` | GET | key | One state: award history + 10 recent documents | Tier 1 / Tier 2 |
| `/api/v1/awards` | GET | key | **Award rows: awardee, amount, fiscal year** | **Primary Tier 3 candidate feed** |
| `/api/v1/documents` | GET | key | RHTP documents with AI-extracted fields | Source-document metadata |
| `/api/v1/documents/:id` | GET | key | Full document record, all extracted fields | Per-record enrichment |
| `/api/v1/opportunities` | GET | key | RFPs/RFAs/NOFOs with normalized deadlines | **Primary Tier 2 feed** |
| `/api/v1/events` | GET | key | Town halls, webinars, trainings, recordings | Low value; known defect source (§6.2) |
| `/api/v1/activity` | GET | key | Change events across states | **Delta detection + real source URLs** |
| `/api/v1/search` | **POST** | key | Full-text search, optional AI synthesis | Discovery only; `aiAnswer` non-quotable |

**Authentication:** `Authorization: Bearer <key>` *or* `X-Api-Key: <key>`. Both
documented; Bearer verified working.

---

## 2. Pagination mechanism

**There are three different response envelopes.** Any client that assumes one
shape will silently short-read, which spec §5 names as the worst failure mode.

### 2a. `{data, pagination}` — states, awards, documents, opportunities, events

```json
{ "data": [ ... ],
  "pagination": { "page": 1, "limit": 500, "total": 15, "pages": 1 } }
```

Page-number pagination via `page` (1-indexed) and `limit`. **`pagination.total`
is the assertion target for spec §5's exhaustiveness check:** rows written must
equal `total`.

### 2b. `{data, count, page, hasMore}` — activity

```json
{ "data": [ ... ], "count": 55, "page": 1, "hasMore": false }
```

No `total` and no `pages`. Loop until `hasMore == false`. **`count` is the
length of the current page, not the grand total** — verified: `count: 55` with
55 records returned and `hasMore: false`. The §5 "records written equals records
reported" assertion cannot be implemented the same way here; it must accumulate
across pages and rely on `hasMore` terminating.

### 2c. `{documents, count, hasMore, aiAnswer}` — POST /search

Payload array is `documents`, not `data`.

### Per-endpoint limits

| Endpoint | default `limit` | max `limit` |
|---|---|---|
| `/states` | 50 | 50 (the full set) |
| `/awards` | 100 | **500** |
| `/documents` | 25 | 100 |
| `/opportunities` | 25 | 100 |
| `/events` | 25 | 100 |
| `/activity` | 25 | 100 |
| `/search` | 10 | 50 |

`/awards` at `limit=500` is the cheapest way to pull Tier 3 candidates — most
states will fit in one request.

---

## 3. Filter parameters

| Endpoint | `state` | Other filters |
|---|---|---|
| `/states` | — | `limit`, `region` (HHS region number) |
| `/states/:code` | path param | — |
| `/awards` | `state` (2-letter) | `fiscalYear` (partial match), `awardee` (partial, case-insensitive), `page`, `limit` |
| `/documents` | `state` | `category`, `year`, `upcoming`, `page`, `limit` |
| `/opportunities` | `state` | `status`, `type`, `scope`, `q`, `page`, `limit` |
| `/events` | `state` (**comma-separated list accepted**) | `status`, `type`, `from`, `to`, `q`, `includeInactive` |
| `/activity` | `state` | `type`, **`since`**, `page`, `limit` |
| `/search` (POST body) | `states` (array) | `query`, `year`, `limit`, `aiAnswer` |

Enumerated values: `documents.category` = `REPORT | AWARD_ANNOUNCEMENT |
ANNOUNCEMENT | STRATEGY | SUMMARY | APPLICATION | GUIDANCE | DATA | REFERENCE |
OTHER`. `opportunities.status` = `OPEN | CLOSING_SOON | UPCOMING | AMENDED |
CLOSED`. `opportunities.type` = `RFP | RFA | NOFO | GRANT | AWARD | IFB | …`.
`activity.type` = `PAGE_UPDATED` (default) `| NEW_OPPORTUNITY | NEW_DOCUMENT |
SITE_DOWN | SITE_RESTORED`.

Note `/events` accepts comma-separated states (`IA,NE`) — the only endpoint that
does. Everything else is one state per request.

### 3a. The `updated_since` problem — this breaks the spec §5 delta design

**`/api/v1/activity` is the only endpoint with a server-side delta filter.**
`/awards`, `/documents`, and `/opportunities` have none.

Verified directly: `GET /api/v1/awards?state=DE&since=…&updatedSince=…` returned
`total: 15`, identical to the unfiltered call. **Both parameters were silently
ignored — not rejected with a 400.** A client that assumes a delta filter works
will pull the full set every time while believing it pulled a delta.

Spec §5 names delta pulls as "the primary quota control." That control does not
exist as designed. Options, for your decision:

1. **Poll `/activity?since=<last_pull>` per state, then fetch only changed
   states.** Fits the API's intent. Costs 1 call per state per pull (50/pull),
   plus fetches only where something moved. Risk: `activity` reports *page*
   changes, and it is not proven that every award row change produces one.
2. **Full pull, client-side diff via `rcj_record_hash` (spec §6.3).** Robust —
   catches changes `activity` misses — but costs the full request count every
   pull. At `limit=500`, `/awards` is ~1 call per state.
3. **Hybrid: full `/awards` pull weekly (cheap, ~50 calls), `/documents` and
   `/opportunities` gated on `/activity`.** My recommendation. `/awards` is
   both the highest-value feed and the cheapest to pull exhaustively.

Partial mitigations that exist: `/documents` records carry `discovered`, and
`/opportunities` records carry `createdAt` / `updatedAt`, so both can be
filtered **client-side after retrieval**. That saves no quota but does drive the
review queue. **Award records carry no timestamp of any kind** (see §5), so
hashing is the only change-detection mechanism available for Tier 3.

---

## 4. Quota headers and rate limits

### Confirmed live on our key

```
x-ratelimit-monthly-limit:      2000
x-ratelimit-monthly-remaining:  1999
x-ai-search-monthly-limit:       250
x-ai-search-monthly-remaining:   250
```

Four headers, all lower-cased on the wire. The documentation mentions only the
two `-remaining` headers; **the `-limit` headers also exist**, which is better
than documented — percentage consumed can be computed without hard-coding a
plan.

### Our key is on the Pro plan, not the $99 plan

| Plan | Rate | Monthly | AI answers |
|---|---|---|---|
| **Pro — ours** | **60/min** | **2,000** | **250** |
| Team | 120/min | 20,000 | 1,000 |
| Featured Vendor | 300/min | 20,000 | 1,000 |
| "Dedicated API" ($99/mo, `/membership/api`) | 120/min | 10,000 | 500 |

**This is a material planning constraint.** A weekly 50-state pull across
`/awards` + `/documents` + `/opportunities` + `/activity` is ~200 calls minimum
before pagination, ~800–900/month — 40–45% of the allowance, leaving little
headroom for re-runs, backfill, or the twice-weekly cadence spec §5 recommends
for the Year 1 → Year 2 transition. **Recommend either confirming an upgrade or
adopting option 3 in §3a above.**

### No per-minute headers

The 60/min ceiling is enforced but **not reported** — there is no
`X-RateLimit-Limit`/`Remaining` for the minute window. Client-side
`req_throttle()` is the only protection. `config.yml` sets 40/min for margin.

Monthly allowances reset at 00:00 UTC on the first of each month. Account owners
and admins get email warnings at 80% and 100%.

### Error codes

`200` ok · `400` bad request · `401` no key · `403` invalid/revoked key ·
`404` not found · **`429` per-minute or monthly allowance exceeded — check
`Retry-After` and quota headers** · `500` server error.

`Retry-After` was documented but not observed (we never hit 429). The client
must handle it as documented and not assume it is present.

---

## 5. The real payload schema

### 5a. `GET /api/v1/awards?state=DE` — 15 records, all fields present

| Field | Type | Observed in DE |
|---|---|---|
| `id` | string (UUID) | always present |
| `state` | string (2-letter) | always present |
| `stateName` | string | always present |
| `fiscalYear` | **string, free-text** | `"2026"`, `"2025"`, **`"2025-2026"`** |
| `awardeeName` | string | always present |
| `federalAmount` | integer | always present — **including four records with value `1`** |
| `matchAmount` | integer or null | **null in all 15 records** |
| `activityType` | string | RCJ's own coding, e.g. `POPULATION_HEALTH`, `EMS_DEVELOPMENT`, `QUALITY_IMPROVEMENT`, `OTHER` |
| `programDescription` | string | **machine-generated — non-quotable** |
| `sourceDocument` | object | `{id, title, fileType, url}` |

**There is no timestamp field on an award record.** No `createdAt`, no
`updatedAt`, no `discovered`. Change detection for Tier 3 must rely entirely on
`digest::digest()` hashing per spec §6.3.

The documented sample shows a `matchAmount` and a richer shape than Delaware
returns. Do not design against the documented sample.

### 5b. `sourceDocument.url` is an RCJ proxy, not the state source

```
"url": "https://www.ruralcarejourney.com/api/documents/<uuid>/file"
```

This serves RCJ's own cached copy (verified: returns `text/html`, no redirect to
an external host). **The original state URL is not exposed on award records or
in the documents list.** This matters directly for spec §9.1: `validation_url`
must be the state page, and RCJ cannot supply it from these endpoints.

**`/api/v1/activity` is the only endpoint that exposes real state URLs**, via
`siteUrl` and `detail.updatedDocuments[].sourceUrl` — e.g.
`https://dhss.bonfirehub.com/portal/?tab=openOpportunities`. Any design that
needs state source URLs must route through `/activity`, or the reviewer finds
them by hand.

### 5c. `GET /api/v1/documents?state=DE` — 30 records

`id`, `title`, `fileType`, `category`, `fiscalYear` (**6/30 null**), `state`,
`stateName`, `award` (**23/30 null**), `highlights`, `url`, `applicationUrl`
(**29/30 null**), `nextDeadline` (**24/30 null**), `keyDates`, `discovered`.

`discovered` is populated on all 30 (range `2026-03-09` → `2026-07-30`) — usable
for client-side delta.

### 5d. `GET /api/v1/documents/:id` — much richer

Adds `activityTypes[]`, `budget{total,federal,match}`, `programHighlights`,
`strategicGoals[]`, `milestones`, `performanceTargets`,
`transformationStrategy{}`, `demographics{}`, `implementationPhase`,
`completenessScore`, `pages`, `fileSizeBytes`, `publishedAt`, **`discoveredAt`**,
**`processedAt`**.

`publishedAt` was null on the record inspected; `discoveredAt` and `processedAt`
were populated. One call per document — expensive against a 2,000/month budget.

### 5e. `GET /api/v1/activity` — different shape again

Records: `id`, `state`, `type`, `summary`, `siteUrl`, `documentId`, `detail`
(shape varies by `type`), `occurredAt`. For `PAGE_UPDATED`, `detail` carries
`docsNew`, `docsUpdated`, `newDocuments[]`, `updatedDocuments[]` — the last with
`{id, title, sourceUrl}`.

---

## 6. Data-quality findings — Delaware confirms §0.1 and §0.2 in one call

The exploratory pull is not just a schema sample. Every defect class the spec
predicts is present in 15 records:

1. **Tier mixing is severe (§0.2).** `/api/v1/awards` is documented as
   "state-level RHTP grant recipients … individual award rows." Of Delaware's 15
   rows, at least **six are not Tier 3 subawards**: $20M to "Delaware DHSS /
   Mobile Health Hubs Grantee Pool", $20M to "Delaware Department of Health and
   Social Services", $10M to "Delaware Division of Public Health", $10M to
   "Rural Community Health Hubs (Mobile Health Units)", $10M to "School-Based
   Health Centers Expansion Initiative", $11.5M to "Delaware State Housing
   Authority". These are plan budget lines and unnamed pools — Tier 2 at best.
   **`awardeeName` being populated is not evidence of a named recipient**, which
   directly undercuts spec §6.1's rule 2 ("presence of a named recipient →
   SUBAWARD"). That rule needs a state-agency and pool-name exclusion list.

2. **Non-RHTP contamination (§6.2).** Four records (#8, #9, #12, #13) trace to
   *"FY 2025: HRSA's Rural Health Grants Delaware Fact Sheet"*. **HRSA rural
   health grants are not RHTP.** La Red Health Center ($250K) is an FQHC
   receiving HRSA money. These are in the RHTP awards feed with no flag. The
   junk filter needs a source-document provenance test, not only the
   description-negation regex the spec describes.

3. **Amount defects (§6.2).** Four records carry `federalAmount: 1`. Not zero, so
   the spec's zero-test misses them. `config.yml` adds
   `amount_implausible_floor_usd: 1000`.

4. **Apparent double counting.** Records #11 and #15 are both $10M for Delaware
   school-based health centers, from two different source documents
   (`DE - 2028 - Delaware RHT Plan Application` and `DE - 2026 - Delaware RHT
   Plan Application`). Same money, twice. Naive summation of DE's 15 rows gives
   ~$92.8M.

5. **Fiscal-year field is unreliable.** `"2025-2026"` is a range, not a year. A
   document titled `DE - 2028 - …` carries `fiscalYear: "2025"`. Needs
   normalization with the raw value retained.

6. **Page chrome as title (§6.2), live.** `"DE - 2028 - portal"` — a bare
   navigation label with a nonsense year. Seed
   `data/reference/title_junk_patterns.csv` with this.

7. **Event/keyDate bleed (§6.2), live.** The Governor Meyer award announcement's
   `keyDates` contains:
   `{"date": "August 26", "time": "", "label": "Date Posted: , 2026",
   "location": "Statement from Delaware Libraries on the …"}` — a malformed date,
   a label built from a broken template, and an unrelated library press release
   in the `location` field.

8. **`completenessScore: 0`** on a document categorized `AWARD_ANNOUNCEMENT`
   with populated extracted fields. The score is not a usable quality signal.

**These 15 records are good Stage 2 test fixtures.** They are already committed
under `data/raw/rcj/2026-08-27/`.

---

## 7. Machine-generated fields — non-quotable

Per spec §4, these are search aids only; nothing here may be quoted as fact in
an AHA product:

`programDescription`, `programHighlights`, `highlights`, `progressSummary`,
`strategicGoals`, `transformationStrategy`, `summary`, `milestones`,
`performanceTargets`, `implementationPhase`, `completenessScore`,
`activityType` / `activityTypes` (RCJ's own coding — map to CMS categories and
keep `activity_type_raw`), and `aiAnswer` from `POST /api/v1/search`.

The Delaware `progressSummary` — *"The state has announced and awarded funds to
four new school-based health centers through the RHTP"* — reads as a factual
award assertion. It is model output. Under §0.4 it cannot support a
determination.

---

## 8. Terms of service — no document exists

**Rural Care Journey publishes no terms of service, no API terms, and no
redistribution licence.** Probed `/terms`, `/terms-of-service`, `/tos`,
`/legal`, `/api-terms` — all 404. Every link on `/api-docs` was enumerated: the
only legal document on the site is `/privacy-policy`, which covers account data
(name, email, cookies, Google sign-in) and is silent on data reuse.

The only license-adjacent language is the site footer: *"Not affiliated with
HRSA, CMS, or HHS · Data aggregated from public state and federal sources · For
research and informational purposes only · Not intended as official program
guidance."* **"For research and informational purposes only" is a restriction,
not a grant.**

**Status: BLOCKED for publication.** Written permission is needed from AME
Mobile (`info@amemobile.net` / `admin@amemobile.net`) before AHA publishes
figures or charts derived from RCJ data. Spec §4 says to settle this *before*
any chart is drafted.

Mitigating: under §0.1 no RCJ field enters a published number anyway — every
published figure traces to a state primary source AHA retrieved and archived
itself. RCJ functions as a discovery index. That reduces the exposure
materially; it does not remove the need for a written answer.

---

## 9. Environment status — R is not installed and cannot be installed here

`Rscript` is absent. `apt-get install r-base-dev` fails: `archive.ubuntu.com`
and `security.ubuntu.com` are **denied by the session's egress policy** (HTTP
403 at the proxy, confirmed via the proxy status endpoint). This is an
environment configuration issue, not something a session can work around.

Reachability, tested:

| Host | Status |
|---|---|
| `www.ruralcarejourney.com` | **reachable** |
| `packagemanager.posit.co` | **reachable** (307) |
| `cloud.r-project.org` | **reachable** (200) |
| `archive.ubuntu.com` | **403 denied** |
| `security.ubuntu.com` | **403 denied** |

So R *packages* will install fine once R itself exists. The fix is on your side:
add `archive.ubuntu.com` and `security.ubuntu.com` to the environment's Custom
network allowlist and let the setup script (`config/setup.sh`) run at
environment build time, so R lands in the filesystem snapshot.

**Consequence: no R code in this repo has been executed.** `R/utils_config.R`
is written to spec and reviewed by eye but is unrun. Treat it as unverified
until a session with R can source it.

---

## 10. Recommendations before Stage 1

1. **Settle the delta strategy** (§3a). Recommend the hybrid: full `/awards`
   pull weekly at `limit=500`, `/documents` and `/opportunities` gated on
   `/activity?since=`.
2. **Confirm the quota plan** (§4). 2,000/month is tight for a weekly 50-state
   pull and rules out the twice-weekly cadence spec §5 recommends.
3. **Revise spec §6.1 rule 2.** "Named recipient → SUBAWARD" misfires on
   Delaware. Needs a state-agency / pool-name exclusion list before tier
   assignment is coded.
4. **Add a provenance-based junk filter** (§6.2). Source-document title matching
   HRSA / non-RHTP programs should quarantine the record regardless of its
   description.
5. **Accept that `validation_url` cannot come from RCJ** (§5b). Either route
   through `/activity` for `sourceUrl`, or treat state URL discovery as manual
   work in the §7 registry build. The registry becomes more load-bearing than
   the spec assumes.
6. **Fix the environment** (§9) so Session 2 can actually run R.

# Stage 1 preflight — §5.1 global-pagination test

**Run:** 2026-08-27 (Session 2)
**Question (spec §5.1):** do `/awards`, `/documents`, and `/opportunities`
paginate without a `state` filter?
**Answer: YES — Branch A. Pull nationally, partition by state locally.**

API cost of this test: **13 calls** (2,000 → 1,987 monthly remaining, plus 2
follow-up limit probes → 1,985).

---

## 1. Evidence

All calls unfiltered (no `state` parameter) against
`https://www.ruralcarejourney.com/api/v1`. All returned HTTP 200.

| Endpoint | Served `limit` | `total` | `pages` | Page 1 rows | Page 2 rows | p1∩p2 |
|---|---|---|---|---|---|---|
| `/awards` | 500 | 1,429 | 3 | 500 | 500 | 0 |
| `/documents` | 100 | 3,092 | 31 | 100 | 100 | 0 |
| `/opportunities` | 100 | 631 | 7 | 100 | 100 | 0 |

Four independent checks, all passing:

1. **Unfiltered requests succeed.** No `state` parameter is required; none of
   the three endpoints 400s or silently empties.
2. **Results are genuinely national.** Page 1 of `/awards` spans 22 distinct
   states, `/documents` 21, `/opportunities` 32. The unfiltered `/awards` total
   (1,429) far exceeds a single-state total (`state=GA` → 115), so the
   unfiltered call is not defaulting to some implicit state.
3. **Zero page overlap.** Page 1 and page 2 id sets are disjoint on all three
   endpoints, so pagination is a real offset walk, not a repeated first page.
4. **No deep-page cap.** The last page of each endpoint returns exactly the
   arithmetic remainder — `/awards` page 3 = 429 rows (1,429 − 1,000),
   `/documents` page 31 = 92 (3,092 − 3,000), `/opportunities` page 7 = 31
   (631 − 600). Deep pages are reachable and complete.

## 2. `limit` is silently capped, not rejected

`/documents?limit=500` and `/opportunities?limit=500` both return **HTTP 200**
while serving only 100 rows and echoing `pagination.limit: 100`. The server
neither honours nor rejects an over-max `limit` — it quietly downgrades.

**Client requirement:** compute the page count from the **response's**
`pagination.limit` and `pagination.total`, never from the requested limit. A
client that assumed its requested `limit=500` was honoured on `/documents` would
walk 7 pages, read 700 of 3,092 records, and report success — exactly the silent
short-read §5.2 warns about.

Confirmed maxima: `/awards` 500, `/documents` 100, `/opportunities` 100 —
matching §4 and `config/config.yml`.

## 3. Implied monthly call volume

### Branch A — global pagination (CONFIRMED, adopt this)

Per full national pull:

| Endpoint | Calls | Basis |
|---|---:|---|
| `/awards` | 3 | ⌈1,429 / 500⌉ |
| `/documents` | 31 | ⌈3,092 / 100⌉ |
| `/opportunities` | 7 | ⌈631 / 100⌉ |
| `/activity` | ~5 | `hasMore` loop at limit 100; weekly delta via `since=` |
| **Total** | **~46** | |

| Cadence | Pulls/month | Calls/month | % of 2,000 |
|---|---:|---:|---:|
| Weekly | 4.33 | **~199** | **10.0%** |
| Twice-weekly | 8.67 | **~399** | **20.0%** |

**Twice-weekly is affordable** — it leaves ~1,600 calls/month of headroom for
`/documents/:id`, `/states/:code`, and ad-hoc lookups. This supports the §5
recommendation to run twice-weekly through the Year 1 → Year 2 transition.

### Branch B — state-partitioned fallback (NOT NEEDED)

Recorded for completeness. 50 states × (`/awards` + `/documents` +
`/opportunities`) with `/documents`/`/opportunities` gated on `/activity?since=`:
approximately **800–900 calls/month**, **40–45% of allowance**, weekly only —
no twice-weekly headroom. Branch A costs roughly **one quarter** as much and
yields complete national snapshots, which diff far more cleanly than 50
independently-timed state pulls.

### Note on the spec's estimate

Spec §5.1 projected 100–150 calls/month for weekly Branch A. Measured is
**~199**. The gap is `/documents`: 31 of the 46 calls per pull (67%) come from
3,092 documents against a hard 100/page cap. The conclusion is unchanged — the
strategy is still comfortably affordable — but the budget line should read ~200,
not ~125.

**Growth sensitivity:** every additional 100 documents adds 1 call/pull
(≈4.3 calls/month weekly, ≈8.7 twice-weekly). If the document corpus doubles to
~6,200, twice-weekly rises to roughly 660 calls/month (33%) — still within
budget, but `/documents` is the line item to watch.

## 4. `/activity` — confirmed shape

`{data, count, page, hasMore}`, `count` = page length (100), not a grand total,
so termination is the `hasMore` loop per §4. Record keys: `id`, `state`, `type`,
`summary`, `siteUrl`, `documentId`, `detail`, `occurredAt`. `siteUrl` carries the
real state URL (sample: `https://www.tn.gov/health/rural.html`), confirming §4.1 —
`/activity` is the only source of `state_source_url` and is a primary endpoint,
not a delta gate.

The ~5 calls/pull budgeted above assumes a bounded weekly delta via `since=`. The
**initial comprehensive backfill is unbounded** and must be measured and
budgeted separately before it is run.

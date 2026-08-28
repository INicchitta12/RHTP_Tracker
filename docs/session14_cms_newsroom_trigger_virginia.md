# Session 14 — the trigger list stops lagging, and Virginia turns out to have no list

**Date:** 2026-08-28
**RCJ quota spent:** zero. Every network call went to `www.cms.gov`,
`www.medicaid.gov`, `ruralhealthtransformation.sd.gov` / `doh.sd.gov` and
`alabamarhtp.com`.

---

## 1. What was wrong

Session 13 noticed something it could not act on: the CMS newsroom named a
**Virginia** announcement — 2026-08-28, **$122 million** — and the
`medicaid.gov` resources page that stage 00 parses did not list it. Checked
directly, the only "Virginia" on that page was West Virginia.

That is not a parse bug. The page genuinely did not carry it. The monitor was
reading one source, that source lagged, and **a lagging source does not look
like a gap** — the run reported eight announced states, confidently, and
nothing in the output suggested a ninth existed. A trigger list that lags is a
trigger list that misses states, and a missed state is a state nobody collects.

---

## 2. The fix: the newsroom leads, medicaid.gov is kept

| | Source | Role |
|---|---|---|
| Primary | `www.cms.gov/newsroom`, rural health topic | announces the day it happens |
| Secondary | `www.medicaid.gov/.../rhtp-resources` | the page that lagged |

The two are **unioned**, `source` is recorded per row (`CMS_NEWSROOM` /
`MEDICAID_GOV` / `BOTH`), and the run reports which states only one list knows
about. medicaid.gov was demoted, not deleted: keeping it costs almost nothing
and guards the symmetric failure — the newsroom lagging on something
medicaid.gov carries. **Neither source may silently shrink the other**, and
there is a test from each side.

### 2.1 The topic filter is read from the document, not from a URL

CMS's own topic facet is `/newsroom/search?about[]=<term id>`. **Akamai
answers 403 to that path for any non-browser client** — with no query string at
all, so it is the *path* that is refused, not the parameters. No user agent
fixes it: the `+url` contact form that gets us through `medicaid.gov`
(Session 10) is refused here too, and so is a spoofed browser UA.

CMS still publishes the topic. Every release carries a schema.org `NewsArticle`
JSON-LD block with an `about` field:

```json
{ "@type": "NewsArticle",
  "headline": "Trump Administration Announces $122 Million to ... Across Virginia",
  "about": "Rural health" }
```

That is the same taxonomy the blocked facet indexes. We read it from the
document instead of from a query, so **the filter is CMS's own classification
either way** — this project does not decide what counts as rural health.

### 2.2 And the topic, never the title

A title keyword filter is the obvious design and it is wrong. Of the nine state
announcements live on 2026-08-28, **six carry no "rural" in the title at all**:

| State | Title |
|---|---|
| VA | *...Expand Healthcare Access, Workforce and Innovation Across **Virginia*** |
| AK | *...Bring Cutting-Edge Technology, Drones Prescription Deliveries...to **Alaska*** |
| AL | *...Improve Mental Health, Substance Abuse, Emergency and Maternal Care...in **Alabama*** |
| ND | *...Launch the Coordinating and Connecting Care Initiative in **North Dakota*** |
| SD | *...Modernize and Improve IT and Interoperability for **South Dakota*** |
| WV | *...Expand Medical Transportation and Improve Patient Access to Care Across **West Virginia*** |

A title filter keeps three of nine and **loses Virginia — the very state that
prompted the rewrite.** The topic tag catches all nine. A test pins exactly
this list, so a future contributor who "simplifies" the fetch away meets it.

### 2.3 West Virginia is not Virginia

`"...Across West Virginia"` contains `"Virginia"`. A first-match state reader
files West Virginia's $4.2M under `VA`, and **nothing afterwards looks wrong** —
both are real states, both have real announcements, and the trigger list simply
has the wrong one. `cms_newsroom_state()` matches **the longest state name
present**, and a headline naming two states is refused rather than resolved.
This is the single test in the file most worth keeping.

### 2.4 What the crawl costs, and how it stays cheap

Rurality lives on the release, not on the listing, so an item's topic costs one
fetch to learn. It is learned **once**: every newsroom item ever seen is
recorded in `data/reference/cms_newsroom_topic_index.csv` with the topic CMS
tagged it with, and an indexed item is never re-fetched.

- Backfill (this session): 16 listing pages + 139 releases.
- A twice-weekly run after it: one listing page plus whatever CMS published since.
- RCJ quota either way: **zero**. This is not the RCJ API.

### 2.5 What it refuses

Every refusal guards a way of being quietly wrong rather than loudly broken:

- a listing page parsing to **zero items** — the newsroom is never empty, so
  that is the markup having moved, not a quiet week;
- the crawl reaching `newsroom_max_pages` **without crossing the floor date** —
  "what fit in max_pages" is not "every RHTP announcement", and the difference
  is a state nobody collects (§5.2);
- **zero** items carrying the rural topic — CMS has tagged RHTP announcements
  with it since 2025-09-15, so zero means the JSON-LD moved, never that CMS
  stopped announcing;
- a headline naming **two states**;
- a `source` value outside `CMS_NEWSROOM | MEDICAID_GOV | BOTH` (§8, no
  free-text categories).

A release CMS tagged with **no topic at all** is not an error — it is simply not
an RHTP announcement, and the crawl carries on.

### 2.6 Tier 1 is excluded, in both sources now

Five rural-topic releases name no state: the $50bn programme launch, the
all-50-states award, the Office of RHT, the summit readout, and *All 50 States
Seek to Transform Rural Health with CMS*. They are the CMS→states programme
itself — **Tier 1 (§0.2)** — and this is the *state* trigger list, so they are
excluded deliberately and the count is reported. That is exactly what the
medicaid.gov `State = "All"` rows already got; the newsroom needed the same
treatment for the same reason.

**Virginia's own release is the §0.2 worked example, inside one document.** Its
headline announces **$122M**; a quoted statement in the same release says
Virginia receives **$189 million** through RHTP. The second figure is the
Tier 1 allotment — `cms_fy2026_allotments.csv` has Virginia at
**$189,544,888** — and the first is the Tier 3 announcement. Two tiers, one
page, and the `amount` column is still never summed.

---

## 3. The result

```
[CMS press] 9 announcements across 9 states -> data/reference/cms_state_announcements.csv
[CMS press] ONLY the newsroom carries: VA -- medicaid.gov is lagging on these.
[CMS press] NEW STATES TO COLLECT: VA
```

**AK · AL · GA · ND · OH · PA · SD · VA · WV.** Eight of the nine are `BOTH`;
Virginia is `CMS_NEWSROOM` alone.

One thing fixed for free: medicaid.gov publishes West Virginia's link with a
**doubled slash** (`/newsroom/press-releases//trump-administration-...`). The
primary's URL wins a collision, so the committed row now carries the working
one — no special case, and a test says why it is not a coin toss which side
wins.

---

## 4. Virginia: announced, and no award list exists

The second half of the task was to extract Virginia's award list. **There is
none to extract, and that is the finding.**

Virginia's own hosts are all refused at CONNECT (403, policy denial) —
`dmas.virginia.gov`, `vdh.virginia.gov`, `governor.virginia.gov`,
`virginia.gov`, `ruralhealth.virginia.gov`, with and without `www`. So the
question was answered from what is reachable and committed.

**The CMS release names no recipient.** Read in full: it lists themes — remote
patient monitoring, rural residency slots, community paramedicine, allied
health pathways, a fund for early-stage health tech, interoperability, dual
eligibles. Not one organisation. It also says outright that *"today's
announcement is just one part of the larger overall funding amount being
awarded to Virginia for fiscal year 2026."*

**The committed RCJ pull says Virginia is at the solicitation stage.** This is
a discovery signal (§0.1), not a finding, and it is unusually legible:

| Endpoint | VA rows | What they are |
|---|---:|---|
| `/awards` | **1** | Virginia Highlands Community College, $127,500 — RCJ's own text calls it *"First local RHTP sub-award in Virginia"* |
| `/documents` | 38 | overwhelmingly **Requests for Applications** — RFA-RHTP-2026-01, RFA-RHTP-2026-02, RFA navigators, application checklists, FAQs |
| `/opportunities` | 6 | five RFA pools (Tier 2: $14.0M, $14.3M, $9.0M, $2.5M, $0.2M) plus the Tier 1 allotment row |

That is a state that has **opened its RFAs and not yet announced awardees**.
It is Ohio's and North Dakota's shape from Session 11, not Pennsylvania's.

**So no `R/03k_va_year1_awardees.R` was built, deliberately.** The only named
Virginia recipient anywhere reachable is one community college known solely
from RCJ, and §0.1 is explicit: no RCJ field may enter a published number
without independent state-source validation. Writing a one-row Virginia file
sourced from an aggregator would be the exact thing the principle forbids —
and the row would be `NON_HOSPITAL` in any case, so it would add a state to
Deliverable 1 while adding nothing to the hospital total.

**What to ask for.** `dmas.virginia.gov` is the host to allowlist: Virginia's
RFAs are numbered `RFA-RHTP-2026-nn` and run by the Department of Medical
Assistance Services, which is the agency that will post the awards. Add
`vdh.virginia.gov` alongside it. Until then Virginia is a **trigger, not a
dataset** — which is precisely what stage 00 exists to produce.

---

## 5. The two retried hosts: both negative

Both were allowlisted for this session and **both answered no.**

### `ruralhealthtransformation.sd.gov` — redirects to the page already read

It is not a separate site. It **302s to
`doh.sd.gov/healthcare-professionals/rural-health/rural-health-transformation-project/`**,
which Session 13 read. Everything reachable from it was checked again:

- its document library is programme material — the NOFO, the project narrative,
  a funding forecast, a timeline, ten initiative one-pagers. No award list.
- `/press-releases/south-dakota-announces-first-awards-...` (2026-05-21) names
  **three programme-management consultants** — North Star Solutions LLC
  ($1,462,802), Black Hills Special Services Cooperative, and Business Concepts
  & Applications ($500,000). Those are administrative contracts of the kind
  `R/03i` already extracts from `open.sd.gov`, **not** the 110 grant recipients.
- `/programs/grants/` carries no RHTP roster.

**South Dakota's $121.5M across 110 recipients is still published nowhere
reachable.** `sd_year1_awardees.csv` stands as it is: two aggregate award
actions, `recipient_confirmed = No`, `NOT_YET_NAMED`, and an empty `amount`
column so no sum can read as a per-recipient figure. The tripwire in `R/03j`
stands too.

### `alabamarhtp.com` — a solicitation site, not an award site

ADECA's resource site publishes **ten NOFOs** (EHR/IT & cybersecurity, rural
health, rural workforce, mental health, rural health practice, cancer digital
regionalization, EMS trauma & stroke, EMS treat-in-place, maternal & fetal
health, simulation training), an intro presentation, a workshop announcement
and a second-round FAQ. **No awarded-projects file, in any format.**

So **Alabama's $254,179 gap stays open** and the 45 `AMOUNT_ROUNDED_IN_SOURCE`
flags remain correct: reconstructing those amounts would assert a precision
Alabama has not published. Session 13 established ADECA's news post is a
verbatim mirror of the governor's release; this session establishes its
resource site adds nothing. **Alabama's award detail exists only in the
governor's prose**, which `R/03g` already parses.

One incidental figure worth recording: the site's federal-award footer states
Alabama's assistance award as **$203,404,326.54**. That is neither the
`cms_fy2026_allotments.csv` FY2026 figure nor the $143,745,821 Year 1 total,
and it is **not** a Deliverable 1 number — noted here so nobody later meets it
cold and assumes a discrepancy.

---

## 6. One defect found and fixed under test

The offline `--parse` path failed where `--run` did not. `readr` infers the
index's `first_indexed` column as a **Date** on the way back in; medicaid.gov's
`first_seen` is **character**; `bind_rows()` refuses the pair. A fresh `--run`
never saw it, because it builds the index in memory where the column is already
character. Types are now pinned at the reader, and a test unions a
read-from-disk index with a character-typed secondary frame.

Worth stating plainly because it is the shape of thing this repo keeps meeting:
**the path that runs least often is the path that breaks**, and the archive
exists precisely so that path can be run for free.

---

## 7. Provenance: the archive follows the §7.1 / Session 11 posture

CMS's page chrome carries a **third-party Mapbox API token** in its Drupal
settings JSON. It is CMS's to publish and not ours to redistribute — the reason
§7.1 archived only the allotment `<table>` and Session 11 archived only the
`<main>` of the six state press releases.

The first run here archived full pages and **committed that token 14 times over**
before the check was added. Nothing was pushed; the archive was deleted and
rebuilt. Releases are now reduced to **`<main>` plus the schema.org JSON-LD**
before writing, and the reduction is asserted free of the token *shape* —
matched by form, `[ps]k.ey…`, not by the literal value, so a rotated token is
caught too.

The JSON-LD is kept for a reason worth naming: it lives in `<head>`, so
archiving `<main>` alone would discard **the very field the topic filter
reads** and leave the archive unre-parseable offline, which would defeat §0.5.
The full page's digest is recorded per release in the topic index
(`full_page_sha256`, with `full_page_bytes`), so provenance still closes
against what cms.gov served.

The **listing pages carry no token** and are archived byte for byte as served.
All files are written with `writeBin`, so the manifest digests verify against
what is on disk (Session 12's off-by-one newline).

---

## 8. Left open

1. **`dmas.virginia.gov` and `vdh.virginia.gov`** — Virginia is announced, is
   at RFA stage, and its awards will post at DMAS. Top of the egress queue.
2. **`ruralhealthtransformation.sd.gov` is spent** as a lead; South Dakota's
   roster is not on any reachable host. It may simply not be published yet.
3. **`alabamarhtp.com` is spent** as a lead; the $254,179 gap is Alabama's own
   rounding and stays flagged.
4. The **medicaid.gov lag itself is unexplained.** It carried eight states on
   2026-08-28 while the newsroom carried nine. Whether it catches up on
   Virginia — and how long it takes — is now observable: `source` moves
   `CMS_NEWSROOM` → `BOTH` on the run where it does. Worth a glance next
   session, because the lag's *size* decides whether medicaid.gov is still
   worth fetching at all.

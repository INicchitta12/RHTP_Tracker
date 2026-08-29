# Session 20 — the §6.2 provenance filter learns state money, and Kansas

Zero RCJ quota. Network: 8 fetches to `www.kdhe.ks.gov`, throttled per §9.5.

Two pieces of work, and they turn out to be the same piece of work seen from
two ends. The filter half asks *what is in the Tier 3 feed that is not RHTP*.
The Kansas half asks *is this state's published award list RHTP money* — which
is the question session 19 learned to ask and the one that cost Texas
$16,800,000 of the wrong answer.

---

## Part 1 — the §6.2 provenance filter, extended and swept

### What was missing

`rhtp_flag_provenance()` tests one thing: does the source document tie to a
non-RHTP **federal** programme — HRSA, USDA Rural Development, FCC/USAC, Flex,
SORH? It was written from Stage 0's Delaware finding (four rows sourced from a
HRSA *Rural Health Grants* fact sheet) and it works.

Session 19 found the half it does not cover. Fifty-three of Texas's sixty-eight
Tier 3 candidates are real, executed, recipient-level HHSC notices of award
naming rural Texas hospitals — 21 at $250,000 under RFA `HHS0015180`, 32 of 33
at $350,000 under `HHS0015677` — paid from money the **88th Texas Legislature**
appropriated in House Bill 1, Article II Rider 88.

### The measurement that decided the design

The obvious extension is a marker set modelled on the federal one: patterns for
appropriation language. **Measured across all 1,366 committed Tier 3
candidates, that does not work, and it is not close:**

| pattern | rows matched |
|---|---:|
| `Rider \d+` | 0 |
| `House Bill` / `Senate Bill` | 0 |
| `General Revenue` | 0 |
| `bienni` | 0 |
| `state-funded` / `state appropriat` | 0 |
| `appropriat` | **1** — and it is a Pennsylvania row that is genuine RHTP |

The federal markers work because HRSA and USDA **brand themselves in a document
title** — `HRSA-26-045`, *Rural Health Grants Fact Sheet*. A state appropriation
does not. RCJ's description for all 53 Texas rows is one machine-generated line
— *"Grant award to support rural hospital operations and transformation
initiatives in Texas"* — that names no funding source at all.

What **is** in the feed is the state's own solicitation identifier.
`HHS0015180` and `HHS0015677` are in the source-document title on every one of
the 53, and that identifier is the handle session 19 actually used. So the
state half is a **registry**, not a guess:
`data/reference/non_rhtp_state_programs.csv`, five rows, each carrying the
disqualifying sentence, its date, the state URL and the archived evidence.
Named state funding streams that *do* brand themselves in a title — opioid
settlement, Medicaid managed care, intergovernmental transfers — sit behind it
as source-scoped text markers.

**The scoping is doing real work.** Description-scoped, those same Medicaid
markers also match a Pennsylvania RHTP award row and Alaska's Year 1
announcement. Source-scoped they match 16 rows in 5 states and not one is RHTP.

### The date test, and the refusal that matters more

`PROVENANCE_PREDATES_NOA`: an award action the source dates before that state's
CMS Notice of Award cannot be an RHTP subaward, because RHTP money moves CMS →
state → subrecipient (§0.2) and a state cannot subaward money it has not been
given.

**The anchor is parsed, not typed.** `data/reference/cms_state_noa_dates.csv`
is built from the schema.org `datePublished` in stage 00's committed archive of
the CMS release that awarded all 50 states — **2025-12-29, one announcement,
fifty states** — cross-checked against the newsroom index's own `item_date` and
corroborated by HHSC's separate statement of Texas's NOA date. Public Law
119-21 (2025-07-04) is recorded as the floor beneath it.

**And then the test had to be told what a date is not.** RCJ publishes no
award-action date at all: `/awards` records carry ten fields —
`id`, `state`, `stateName`, `fiscalYear`, `awardeeName`, `federalAmount`,
`matchAmount`, `activityType`, `programDescription`, `sourceDocument` — and
none is a date. The record table's `date_announced` is populated on 3,639 rows
and on **none** of the 1,372 Tier 3 ones, because on `/documents` it is RCJ's
own `discovered` crawl timestamp.

So dates are mined from the source document's own title, and two things are
refused:

- **`REFUSED_RCJ_YEAR`.** RCJ prefixes every source-document title with a year.
  `PA - 2025 - Rural Health Selected Projects: Pa RHT Plan (RHTP) Authorized
  Project Awards` is **Pennsylvania's entire committed Year 1 file** — 66 rows,
  $42,198,309.80. Maryland's 33 Pillar 2 rows sit behind `MD - 2025 -`, and
  `OK - 2025 - Oklahoma RHTP August 2026 Touchpoint Webinar` carries a 2025
  prefix on a document about August 2026. **A date test keyed on that prefix
  quarantines 145 rows, 99 of them from two states this project has already
  published, and it looks like a working filter while doing it.**
- **`REFUSED_FISCAL_YEAR`.** A fiscal year is a period, and turning one into a
  date needs a 50-state fiscal calendar this repository would be transcribing
  rather than sourcing. Texas's four `SFY 2025` intergovernmental-transfer rows
  are caught by the registry and by the markers instead — twice over, without
  inventing a calendar.

### The sweep: 73 rows in 6 states, of 1,366 candidates

`Rscript R/02b_provenance_sweep.R --build`

| state | candidates | caught | registry | marker | predates NOA | RCJ amount |
|---|---:|---:|---:|---:|---:|---:|
| TX | 68 | 62 | 62 | 0 | 53 | $60,882,308 |
| NH | 23 | 3 | 0 | 3 | 0 | $1,958,310,534 |
| AZ | 4 | 3 | 0 | 0 | 3 | $55,000,000 |
| RI | 3 | 3 | 0 | 3 | 0 | $22,250,349 |
| MS | 3 | 1 | 0 | 0 | 1 | $150,000 |
| IL | 1 | 1 | 1 | 0 | 0 | $1 |
| | **1,366** | **73** | 63 | 6 | 57 | |

Four of the six are not Texas, and each is a different shape:

- **New Hampshire's $1,898,965,390 row is the closure worth reading.** The §6.2
  allotment ceiling flagged it in session 5 as impossible against a $204M
  allotment — three managed care organisations in one `awardeeName`. The
  provenance filter now says *what it is*: New Hampshire Medicaid Care
  Management. Two independent §6.2 filters landing on the same row from
  opposite directions.
- **Arizona's three rows, $55,000,000**, are the Arizona Health Care Cost
  Containment System, extracted from *"Arizona RHTP Application Overview Public
  Webinar (November 13, 2025)"* — a document the state published six weeks
  **before** CMS awarded it anything. A pre-award application webinar cannot
  carry an award action.
- **Rhode Island's three rows are opioid settlement money**, and one of them is
  *Rhode Island Hospital (Lifespan)/Brown Health*, $2,915,143 — a **named
  hospital**, which is how this class of record reaches a hospital total.
- **Illinois's single catch corroborates session 16 by machine.** MyOwnDoctor,
  LLC at $1 is the state's only Tier 3 candidate, and session 16 had already
  read it by hand as *"a 2025 Medicaid contract that is not RHTP at all"*.

**Mississippi's $150,000 is the one a reviewer should look at first.** Horne
LLP, *"Notice Of Contract Award RHTP - Consultant Quotation #20250728"* — the
title says RHTP, and the date is five months before Mississippi had an award.
It is quarantined, which routes it to review rather than deleting it; the
reading is that a consultant engaged in July 2025 cannot have been paid from an
allotment issued in December.

### The bound on the date test, reported rather than hidden

| basis | rows |
|---|---:|
| `REFUSED_RCJ_YEAR` | 1,195 |
| `SOURCE_TEXT` | 85 |
| `REGISTRY` | 53 |
| `NO_DATE_IN_SOURCE` | 26 |
| `REFUSED_FISCAL_YEAR` | 6 |
| `REFUSED_AMBIGUOUS_DATES` | 1 |

**138 of 1,366 candidates carry a date anybody asserted.** That is a bound on
the *data*, not on the rule, and it is the §0.1 finding underneath the whole
exercise: the aggregator cannot date its own award records, so provenance has
to be established per state, against state documents. It is reported per state
in `provenance_sweep_by_state.csv` so no future run can quietly report a clean,
fully dated corpus.

### The false-positive check, which is an assertion

Every caught row is compared against the **879 award rows in the nine committed
state files** — hand-extracted from state primary sources, so independent of
RCJ — on (state, normalised recipient name). **Overlap is zero**, and
`rhtp_provenance_sweep_assert()` hard-fails if it ever stops being. A filter
that quarantines a row this project has published is worse than no filter: it
deletes findings while reporting a clean corpus.

### What was changed, and what was not

Both codes are wired into `rhtp_apply_rules()` and both **quarantine**, on the
same footing as their federal sibling. Stage 2 was run once with them and
flagged **exactly the same 73 record_ids** the sweep caught; the rebuilt interim
artifacts were then reverted, so the committed record table is unchanged and the
next Stage 2 run is what applies the filter to it. Rewriting
`stage2_record_table.rds` to publish a sweep is the change session 16 declined
to make, for the same reason.

---

## Part 2 — Kansas: 46 award actions in three pools, and the partial list is 1.3% of it

### The partial list was real, and it was the small one

The seven-award Community Health Worker + Accountable Food is Medicine list —
$1,007,152, four awards at exactly $150,000, two of them to hospital districts —
is exactly as described and it is **one of three pools KDHE has published**.
The other two are in a single PDF linked from the same page:

| pool | awardees | total |
|---|---:|---:|
| REH CAP — Rural Emergency Hospital Conversion / Transformative Capital Investment | 17 | $29,097,937 |
| RPGP — Regional Partnerships Grant Program | 22 | $49,915,410 |
| CHW + AFIM | 7 | $1,007,152 |
| | **46** | **$80,020,499** |

36.1% of Kansas's $221,898,008 allotment.

### The Texas check, run first

1. **What funds it.** The award document's own footer: *"supported by the
   Centers for Medicare & Medicaid Services (CMS) ... as part of a financial
   assistance award totaling $221,890,007.82 with 100 percent funded by
   CMS/HHS."* That is the awarding agency saying so on the award document, and
   `ks_assert_rhtp_funded()` requires it on every run.
2. **When.** KDHE's RPGP / REH CAP applicant webinar is **6 March 2026**, after
   Kansas's 2025-12-29 Notice of Award. Texas's `HHS0015180` went the other
   way — released 2025-03-24, closed 2025-04-24.

The sweep agrees from the other side: **Kansas catches zero rows**, asserted in
the Kansas tests.

### The positive control

*"The other four Kansas programmes have published no roster"* is only a finding
if KDHE demonstrably publishes rosters in a recognisable form. It does: two
links off the programme page, *"REH CAP and RPGP Award Winners (PDF)"* and
*"CHW + AFIM Award Winners and Project Descriptions"*. Both are asserted
**present** — that is the control. The four programmes with no such link are
then a real absence, and each says why: **Emerging Technology** ($9.5M,
applications due 10 July 2026), **Interfacility Transport** (RFA 8 July 2026),
the **Evidence-Based Practice** programme (participation agreements, not
awards), and the **KHA Healthworks** revenue and credentialing projects (RFP
due 4 August 2026).

`ks_assert_award_index()` is a tripwire in both directions: it fails if a known
award link **disappears** — a site redesign that renamed them would otherwise
turn every future run silently green — and fails if a **third** award-shaped
link appears, because then Kansas has published a pool this file does not carry
and the file is stale rather than wrong. Both branches are tested.

### A PDF parser had to be written, and it does not guess

Kansas is the first state whose awards exist only as PDFs, and the cloud
session has no `pdftotext`, `pdftools` or `pypdf` and no route to PyPI. Session
8 met this with Delaware's budget narrative and solved it by hand,
uncommitted — but a parse nobody can re-run is not a parse (§7.1).

`R/utils_pdf_text.R` inflates the content streams and decodes every string
**through its own font's `/ToUnicode` CMap**. The cheap alternative would have
been to read the `Tj` operands as ASCII, and on KDHE's files that produces
`D Q G` for `and`: the fonts are subsetted and the glyph codes come out shifted
by 29. A constant-offset guess would have decoded these two documents and
silently mangled the next one — into text that still looks like words.

Two smaller traps it also had to handle. **Strings that are never painted** —
`/ActualText` inside marked-content property lists — sprinkle stray glyphs
through the output unless they are held until a `Tj`/`TJ` actually draws them.
And KDHE **wraps mid-word**: `Citizens Foundat` / `ion: $146,476`. Joined with
a space that is published as *"Citizens Foundat ion"*, so lines are joined
without a separator when the previous ends in a letter and the next begins with
a lowercase one. The repair runs on descriptions and names; an assertion
requires no name to carry the artefact.

### What RCJ got wrong: 45 of 46

Every amount RCJ holds matches the state document **exactly**. The one it
dropped is **Greeley County Health Services' $458,286 REH CAP award**: Greeley
appears **twice** in the document, once in each pool, and RCJ kept only the
$1,541,906 RPGP row. Texas's 32-of-33 in a state that is otherwise clean — an
aggregator that de-duplicates on the recipient loses the second award, and
nothing about the output looks wrong. The pool split here is **positional**
against the RPGP heading for exactly this reason: any recipient-keyed split
would have to choose one of Greeley's two.

### The two publishers disagree, and it is not resolved

KDHE's award document states the CMS award as **$221,890,007.82**;
`cms_fy2026_allotments.csv`, parsed from CMS's own table in session 5, has
Kansas at **$221,898,008**. The gap is **$8,000.18**. Both figures are quoted
from their publishers and neither is adjusted (§8). It is asserted, so a future
session meets it rather than rediscovering it.

### The hospital figure is a floor, and the uncertainty is bigger than it

```
NAMED_HOSPITAL   21 rows   $35,721,277
form not stated  22 rows   $39,249,763   <- larger
```

KDHE publishes a recipient and an amount and **nothing about the recipient's
form** — no organisation-type column of the kind Oregon and Alaska both
publish. So `rhtp_classify_recipient_type()` falls back to §8's standing answer
(`NONPROFIT_CBO` + `LOW` + `RECIPIENT_TYPE_INFERRED`) on 22 of the 46 rows.

**Nothing was promoted, and that is the decision.** Several of the 22 read as
hospitals to anyone who knows Kansas — Stormont Vail Health, AdventHealth
Ottawa, Labette Health, South Central Kansas Health (which KDHE's own project
text calls *"Kansas' first REH"*) — and several plainly are not: Special
Olympics Kansas, InterHab, the Kansas Council on Developmental Disabilities.
Promoting the first group on this pipeline's own knowledge is the §0.4 failure
the project exists to avoid, and it would inflate the one number AHA will be
asked to defend. The 22 are queued as `KS_RECIPIENT_FORM_NOT_STATED` in
`classification_review_queue.csv` with their dollars stated, and **the CCN match
— open blocker 5 — is what resolves them.** A test pins the four most obvious
candidates as *unpromoted*, so a future session that promotes them has to say
so there.

### One coding mistake, caught by §0.3a

A first pass fed the **pool's name** to the classifier as the description.
Because the REH CAP pool is called *"Rural Emergency Hospital Conversion..."*,
every unrecognised recipient in it came out `IN_KIND_BENEFIT` — the §6.2
in-kind rule firing on a string this file had written itself. That is §0.3a
exactly: the coding was reading the activity, and the activity was ours. KDHE's
own per-award paragraph is what goes to the classifier now, and a test asserts
the pool name is not in it.

### The guard caught a credential a hand check would have missed

KDHE's CivicPlus template carries a Google Maps API key in a **hidden input**,
`<input id="GoogleMapsKey" value="AIza...">`. The credential-bearing node is
removed by name (Illinois's remedy — the links this file parses run the length
of the page, so there is no `<main>` to retreat to), the reduction is asserted
credential-free **after** reducing, and the full page's digest as served is in
the manifest so provenance closes. The two award PDFs and the budget narrative
are archived byte for byte.

---

## State of the queue

Kansas moves to `EXTRACTED`. **Maryland now leads** — 42 Tier 3 candidates / 41
distinct awardees, then NE 39/35, IN 37/28, OK 35/25, NV 34/34, MI 31/31.
Nine states extracted, one `INVESTIGATED_NO_LIST`, 29 queued.

Kansas is a third shape for the next session to expect. Texas said *"a
recipient-level list can be the wrong programme"*. Oregon said *"a recipient-level
list can be the wrong recipient class"*. Kansas says **a partial list can be
1.3% of what the state has published, sitting on the same page as the rest** —
and the way to tell is to read the programme page's link list, not the
programme page's prose.

Tests: **1,839 assertions, all passing** (was 1,645).

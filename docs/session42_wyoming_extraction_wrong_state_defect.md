# Session 42 — Wyoming extracted, Indiana still unawarded, and §0.1 gains a sixth failure mode

**Date:** 2026-09-03
**Quota:** zero RCJ calls. Two live fetches to `www.in.gov` (Task 2). Nothing
else touched the network.

---

## Task 1 — WYOMING IS EXTRACTED

**77 award actions, $173,859,751.74 to a named recipient, and 31 named-hospital
rows worth $72,661,323.90** — which makes Wyoming the **second largest
named-hospital state in this repository after Georgia**, ahead of Alabama.

Wyoming is the **fourth zero-signal state with a published, named, priced
roster** (Florida, North Carolina, Arkansas, Wyoming): no CMS state release, no
RCJ Tier 3 candidate, `trigger_source = NEITHER` on **both** discovery layers.
Its roster is in a Google Drive folder that `health.wyo.gov` links behind five
words — *"View Documents In Google Drive"*.

### What Wyoming publishes, and it is one document

The Rural Health Transformation Advisory Committee's **Award Approvals -
8.11.26**: a fifteen-line budget summary that totals to the allotment exactly,
and **six recipient-level tables**.

| Initiative | Rows | Approved |
|---|---:|---:|
| 1.1 Critical Access Hospital – Basic | 18 | $48,200,174.00 |
| 1.2 EMS Regionalization | 11 | $23,260,000.00 |
| 2.2 Physician GME | 3 | $17,712,410.00 |
| 3.1 Technology Adoption Challenge | 10 | $12,652,243.00 |
| 4.1 Integrated Primary Care | 8 | $30,465,504.74 |
| 4.2 Clinically-Integrated Care Coordination | 25 | $3,218,160.00 |
| | **75** | **$135,508,491.74** |

**Two more rows come from the MINUTES rather than a table, and they are
Wyoming's largest single recipient.** Initiatives 2.1 and 2.3 are a
**sole-source master fiscal agent contract with the Wyoming Innovation
Partnership, $38,618,260** — named by the minutes' motion *and* by the budget
summary's own Notes column, twice. **Missouri's Hub Anchors are the precedent
that decides whether they belong in the award file**: those 27 are OUT of
Missouri's because DSS's FAQ says they *"will not act as the fiscal agent"*, and
WIP is IN because Wyoming's motion says it **is** one — a fiscal agent receives
the money it administers.

**And it codes like New Hampshire's FHC, not like Illinois's ICAHN.** ICAHN is
`Yes` because Illinois restricted eligibility to hospitals only; WIP administers
*"statewide individual and institutional workforce/nursing grants"* — individuals
and institutions, no hospital named and no hospitals-only class — so it is
`PASS_THROUGH_UNRESOLVED` + `Unclear`, in **neither** bucket, and **$38,618,260
is hospital-bound on nobody's authority (§0.3)**.

That leaves **$30,877,990 — 15.1% of Year 1 — approved at POOL LEVEL naming
NOBODY AT ALL**: the fiscal-agent sweep ($17,612,195), three competitive RFPs,
4.3, State Policy Action support and administration. Those seven lines are in
`wy_year1_status.csv`, which has **no `amount` column** (Texas's device).

### The reconciliation closes at three levels

* **per table** — each table's approved column sums to that table's own
  `Total:` row. 4.2 has no total row and closes against the budget summary and
  the minutes' own $3,218,160; 3.1's approved column has no total and closes
  against the document's *recommended* total and the summary.
* **per line** — each table equals the budget summary's "Approved award".
* **whole** — the summary's fifteen lines sum to **$205,004,742**, which is the
  §7.1 anchor ($205,004,743) to a dollar and CMS's own Notice of Award
  ($205,004,742.95) to a rounding.

**FOUR OFFICIAL FIGURES FOR ONE AWARD, ALL PINNED AND NONE CORRECTED (§8).**
WDH's budget summary prints Initiative 4.1 as **$30,465,505** where its own
table gives **$30,465,504.74**, and floors its Total to **$205,004,742**; CMS's
allotment table rounds the same award UP to **$205,004,743** and the Notice of
Award gives **$205,004,742.95**. `wy_reconcile()` sums the table-precise
figures and lands on $205,004,741.74; the $1.26 is Wyoming's own rounding, and
`--report` says so on the line beneath rather than leaving an unexplained gap in
a headline.

### THE RUN MODEL IS MANDATORY, AND THE LINE MODEL LOSES $5,156,000 IN SILENCE

Six visual rows carry the recipient name in a **separate painted run** from the
rest of the row — two in Initiative 1.1 and four in 1.2 — because the producer
paints a cell that overflows its column as its own text object.
`rhtp_pdf_lines()` groups by the reader's line id, so it emits the name as one
line and the whole rest of the row as another.

**A line-model read of Initiative 1.1 gives SIXTEEN hospitals and $43,044,174,
orphaning $5,156,000.** Nothing about that output looks wrong: the two rows
still exist, with no name on them. `wy_assert_line_model_splits_names()` asserts
that the line model still does this and prices the loss.

It is the mirror of Arkansas's `ar_assert_line_model_merges()` — there the line
model **welds** three columns into one unparseable string, here it **splits**
one row into two — and both exist so that a later session cannot "simplify" the
parse back to `rhtp_pdf_lines()` and get a quietly wrong state.

**And a second run-model finding cost this session a name and an EIN before it
was caught.** Four of the six tables let a long applicant name **overflow into
the EIN column** — *"North Lincoln County Hospital District dba Star Valley
Heal83-0327251Y"* is one painted row. A fixed boundary between the two both
truncated the name and returned **`NA` for the EIN**, which is the exact key
this file uses to carry Wyoming's stated hospital form from Initiative 1.1 into
Initiative 1.2. The name and the identifier now come out of **one wide band,
split by regex**, and the name is kept **as painted** — clipped by the producer
at its own cell edge (§8).

### 1.1's recipient form is STATED BY WYOMING, and that moves $7,525,331

§8's name rule reaches 15 of 1.1's 18 approved hospitals and **misses three** —
*Powell Valley Health Care Inc*, *Cody Regional Health*, *Crook County Medical
Services District*, **$7,525,331 between them**. Wyoming states the form three
times, in two documents: the table's first column is headed **"Hospital"**, the
initiative is *"Critical Access Hospital - Basic"*, and the Year 1 Revised
Budget Narrative's Eligible Applicants block for 1.1 gives **one** Facility
Type, *"Critical Access Hospital (18 Total)"*.

Leaving those three on §8's standing fallback would assert the form is
**undetermined** where the state has stated it outright — the one thing
`RECIPIENT_TYPE_INFERRED`'s own note forbids, and session 38's UNC finding and
session 39's MCO code are the two precedents for typing from the source instead.

**The eligible class is ILLINOIS'S, not New Hampshire's.** One Facility Type
means every possible recipient of 1.1 money is a hospital — ICAHN's class — and
here it does not even need §10.2's pass-through row, because in all 21 cases the
recipient **is** the hospital.

**AND THE TWO 18s ARE NOT THE SAME 18.** The narrative names eighteen *eligible*
CAHs and the committee approved eighteen, and **three names differ each way**:
Weston, Community Hospital (Torrington) and Washakie Medical Center are eligible
and unapproved; Sheridan Memorial Hospital, Crook County Medical Services
District and Teton County Hospital District dba St. John's Health are approved
and not on the eligible list. §0.3 — a plan is not an award, and the coincidence
of count must not read as corroboration.

### 1.2's hospitals are joined ON THE EIN and never on the name

Five of Initiative 1.2's eleven lead agencies are hospitals, **$11,000,000**.
Four are typed from Wyoming's OWN 1.1 hospital table, joined on the **EIN** —
an exact key from the same publisher in the same document, which is Georgia's
application-number precedent (session 22, *"joined on the application number,
never the name"*) and not the fuzzy name match §2 forbids. §0.3a judges the
**recipient** and not the activity: the activity is EMS regionalization and the
named lead agency is a hospital, which is Delaware's Beebe school-based health
centre coded `DIRECT`.

**The fifth does not close on that key. "Sheridan Memorial Hospital" carries TWO
EINs in one document** — 83-6000241 in 1.1 and 92-0606087 in 1.2. Both are
Wyoming's. It is a hospital in 1.2 on its **name**, not on the join. Recorded,
not resolved (§8).

### The eleventh rotating-digest mechanism, and the FIRST that survives the reduction

Wyoming's `--probe` was written with a content digest **by inheritance** from
six other hosts, and its docstring said so (§0.4). Then it was measured, and
both halves of the answer were new.

* **`health.wyo.gov` rotates a token on every request.** Two fetches of the
  programme page three seconds apart are **199,946 bytes each and hash
  differently**. Tags are discarded by the reduction, so whatever it is, it is
  absorbed — the file digest is useless as a change test, as on dss.mo.gov,
  dhs.wisconsin.gov and portal.ct.gov before it.
* **AND THE PAGE CARRIES A SECOND ONE THAT TAG-STRIPPING CANNOT REACH.** Its
  Gravity Forms contact form plants an **anti-spam honeypot whose field LABEL is
  drawn at random per render**, and that label is **in the rendered words**: one
  fetch reads *"**Email** This field is for validation purposes and should be
  left unchanged."* and the next reads *"**Name** This field is for validation
  purposes…"*. **The first live probe reported the programme page CHANGED on
  that one word out of 951**, with nothing about Wyoming's programme changed.

Every earlier mechanism this project has met — a Boomerang nonce, an Incapsula
cache-buster, a `?v=` asset stamp, a re-rolled `mailto`, an ElasticPress cache
variant, a Dynatrace `rpid`, Cloudflare's XOR'd email, in.gov's whitespace —
lived in an **attribute or a script body**, and the tag-stripping reduction
absorbed each for free. **This one is content.** `wy_html_text()` normalises the
label by name — it is a form-field label and the sentence after it is fixed
boilerplate, which is what makes the substitution safe — and a test drives two
renders of the same form to identical text. After the fix, all four watched
pages report **UNCHANGED**.

**And `wy_verify_manifest()` therefore checks the COMMITTED BYTES and nothing
else.** A re-fetched page never reproduces its own manifest digest, which is why
`--fetch` without `--force` downloads only what is missing.

### The applicant trap is the largest in this repository

The same document names **fifty-six applicants it did not award**, **forty of
them under Initiative 3.1 alone, requesting $38,794,342 and mostly NAMED WYOMING
HOSPITALS** — Sheridan Memorial four times, Memorial Hospital of Converse County
three, Memorial Hospital of Laramie County three, Powell Valley three, Memorial
Hospital of Carbon County twice, Riverton Memorial twice, plus Ivinson Memorial,
North Big Horn, Niobrara County, Sweetwater County and South Big Horn. Reading
3.1's table as a roster publishes ~$38.8M of **applications** as Wyoming
hospital awards, on the awarding body's own document (§0.3, Nebraska's lesson).

`wy_assert_denied_not_awarded()` checks the **(table, name) pair** and not the
name, because Memorial Hospital of Converse County holds $3,058,000 under 1.1
and $2,200,000 under 1.2 **while being turned down under 2.2 and twice under
3.1**. The three 1.1 late submissions share one EIN, 94-2545356 — Banner Health.

### Every row is an intent, and two publishers disagree about the deadline

The minutes: *"Year 1 Obligation Deadline: End of October 2026 (executed
contracts/agreements)"*. WDH's programme-page timeline: *"October 1, 2026:
Contract execution deadline"*. Both are Wyoming's; neither is corrected (§8).
Both are in the **future** of the approvals, so all 77 rows are
`NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No` + **`AMOUNT_PRELIMINARY`**
— §8's existing code, Alaska's and Arkansas's condition. **No new vocabulary
code was invented (§2)**; the per-row conditions ("contingent on valid
sustainability plan", "swing bed authorized condition upon approval by WDH")
live in an `approval_condition` column, not in a flag.

### The minutes are a second reading, and disagree once

Five motions match the tables to the dollar. The sixth does not: the minutes
give **University of Utah $9,225,398** where the GME table gives
**$9,255,398.00**, and it is the **table's** figure that sums to the $17,712,410
both documents state ($17,682,410 against $17,712,410). **Nothing is corrected
(§8)** — both are pinned, and the arithmetic is what says which one the total was
built from.

### §6.2, and the fifth state to publish CMS's own Notice of Award

Wyoming's CMS footer is session 27's **strong**, programme-scoped form *and* its
figure is **the allotment** — §0.2 and session 37's Iowa rule — so it is declared
`STATE_ALLOTMENT` and checked by `rhtp_assert_footer_not_allotment()`. It is
demoted as provenance anyway, on the better ground available: Wyoming publishes
**CMS's own Notice of Award** (RHTCMS332082-01-02), the fifth state after Nevada,
California, Connecticut and Kentucky.

**Session 36's date-test pin holds a FIFTH time.** The NOA is a *"Revision
(Budget)"* with a Federal Award Date of **05/14/2026** — **+136 days** — against
a budget period that still starts **12/29/2025** (NV +52, CA +92, CT +206, KY +0
on an original). The minutes corroborate the later date from the other side:
*"Wyoming executed its formal agreement with CMS on May 14, 2026."*

### Two rows name nobody, and the classifier would have said otherwise

4.2 allocates Northern Arapaho $164,700 and Eastern Shoshone $102,300 and records
**"No bidders, recommend sole source w Tribal provider"**. That is a *sentence*,
not an organisation — and **handed it, the shared classifier returns
`TRIBAL_ORG` at HIGH confidence**, which would put a §6.1
programme-name-as-awardee row into the file looking fully determined. Both rows
are `NOT_YET_NAMED` with `amount` **empty** and the figure in `round_amount`
(Oklahoma's ROOTS device), which is why the six tables' rows sum to
$135,241,491.74 rather than $135,508,491.74 — and why `sum(amount)` over all 77
rows is $173,859,751.74, the extra $38,618,260 being the two administrator rows
from the minutes.

### Nothing was promoted (§0.4)

**24 of the 75 approvals-table rows / $5,716,842** carry §8's standing fallback
— the tenth instance, and one-directional (all `No` today). The two
administrator rows also take the fallback and are deliberately **outside** that
question, because they are `Unclear` rather than `No`; they have their own
assertion. The two refusals that matter:

* **Initiative 3.1 publishes no organisation-type column AND no EIN column**, so
  *"Powell Valley Health Care"* there cannot be joined to *"Powell Valley Health
  Care Inc"* in 1.1 by any means §2 permits. Worth **$752,302** upward. Queued as
  `WY_TECH_FORM_NOT_STATED`.
* **"Campbell County Health (CCH) Emergency Medical Servic"** — the producer
  truncates the name at the cell edge, and its EIN (83-0234097) is not in the 1.1
  hospital table. Worth **$1,700,000** upward. Queued as
  `WY_EMS_LEAD_AGENCY_FORM`.

Recorded rather than repaired: *"Bighorn Valley Health Center, Inc. dba One
Health"* is the **identical string** in 3.1 and 4.1 and classifies differently in
the two — `NONPROFIT_CBO` in 3.1, `FQHC_OR_RHC` in 4.1 — because only 4.1's table
states an eligible class. Worth $0 either way.

---

## Task 2 — INDIANA HAS NOT AWARDED ITS GROW REGIONAL GRANTS

`in_assert_regional_not_awarded()` was run **against the live page**, not the
archive.

```
HTTP 200      live 104,319 bytes   archived 104,367 bytes
live sha256      adf546a6c66092f709358a6e00f2896d40a74e70f556ca73d725281da865fca2
archived sha256  0f94e5f18d2a6015ced86574e1a10e1a415444a86ab66b6b1731120b8a082a11
CONTENT IDENTICAL: TRUE

  It launches Sept. 1, 2026, with $120M awarded annually...   TRUE
  RFF Applications submitted July 1                           TRUE
  score applications and determine funding                    TRUE
  Regional Committee Members                                  TRUE
  Maximum Capital Expenditures                                TRUE
```

**All three pre-award predicates hold, so the assertion passes and
`in_year1_awardees.csv` is still seven vendors and zero hospitals, correctly.**

**The CMS release that put Indiana on the trigger list names nobody.** The
2026-09-03 announcement (`cms_state_announcements.csv`, $120,000,000) says the
investment *"will support Indiana's Grow Rural Opportunities for Well-being
(GROW) regional grants"* across *"eight regions of the state"* — a Tier 2
announcement of the pool, consistent with the tripwire passing.

**But the clock has started.** Indiana's own timeline reads *"July — September
2026 Application review, scoring, and award determinations"* and **"Sept. 1,
2026 Grant agreement period begins, and funding distributed to individual
entities"** — which was two days before this ran. The window is open now.

**A tenth digest mechanism, and the mildest yet.** `www.in.gov` varies **leading
whitespace only** between renders: the file digest moves and the byte count
differs by 48, while the reduced content is byte-identical. Every earlier
mechanism (a nonce, a cache-buster, an asset stamp, a re-rolled email entity, a
cache variant, a Dynatrace id) changed something inside a tag; this one changes
nothing but indentation.

---

## Task 3 — §0.1 GAINS A SIXTH FAILURE MODE, AND IT IS DIFFERENT IN KIND

### The defect

**RCJ files Utah's documents under Wyoming.** Five of the 29 Wyoming records are
Utah's: *"Utah RHTP Stakeholder Meeting September 24, 2025"*; **"Utah RHTP
Cooperative Agreement Award: $195.7 million for Year 1" — Utah's own allotment,
carried as an `UNASSIGNED` WYOMING row at $195,700,000 against Wyoming's
$205,004,743**; *"Utah RHTP – Semantic Data Model RFGA"*; *"SPRINT Consortium
RHTP Grant Application"* (its description opens *"Utah DHHS is soliciting
applications"*); and *"PATH 1.4 Community Care Hubs RFGA"*, Utah's PATH
initiative.

### Why it is numbered separately

Modes 1–5 are defects **in** a record — wrong programme (Texas), wrong tier
(Oklahoma), wrong kind of action (Missouri), wrong grain (Michigan), wrong
section (Nebraska). **Mode 6 is a defect in WHICH STATE THE RECORD IS**, so every
state-scoped check this project runs — the §6.2 provenance registry, the date
test, the allotment ceiling, the §8 name rules — is applied to the wrong state's
data **and passes**.

The numbered table is now in `rhtp-tracker-build-spec.md` §0.1 and mirrored into
`CLAUDE.md` §6.1, both **insert-only** patches (§2.1): 41 and 36 lines added,
nothing deleted.

### The measurement — `R/02c_state_attribution_sweep.R`

It reads all **5,056** committed records and asks, of every one, whether the only
US state it names is a state **other** than the one RCJ filed it under. Longest
match first, so *"West Virginia"* is never read as *"Virginia"* (session 14's
lesson one layer down); a record naming **both** its own state and a foreign one
is ordinary and is not flagged; and `<State> County|Parish|Township|City` is
excluded generically, generated from the §7.1 vocabulary rather than typed.

**23 records flagged. Each was read by hand.**

| Verdict | n | Tier 3 |
|---|---:|---:|
| `MISFILED` | 10 | **0** |
| `COUNTY_WITHOUT_THE_WORD` | 6 | 4 |
| `NAME_CONTAINS_A_STATE_NAME` | 3 | 3 |
| `MULTI_STATE_DIGEST` | 2 | 0 |
| `ETHNONYM` | 1 | 0 |
| `STREET_ADDRESS` | 1 | 1 |

### The answer to the question asked

**TEN records are another state's, in FIVE states — so Wyoming is the largest
and not the only one, and UTAH IS ITS MIRROR:**

```
MO <- MI   SOLICITATION  MIH-CP New Site Program Application Checklist  (Michigan's)
ND <- AR   UNASSIGNED    Sanders Announces Applications are Open for $209 Million  (x2, Arkansas's)
UT <- OK   UNASSIGNED    webinars and meetings  (Oklahoma's RHTP engagement events)
WA <- FL   UNASSIGNED    Cammack Delivers: More Than $42 Million  (Rep. Kat Cammack, Florida)
WY <- UT   UNASSIGNED    Utah RHTP Cooperative Agreement Award: $195.7 million  (Utah's allotment)
WY <- UT   UNASSIGNED    Utah RHTP Stakeholder Meeting September 24, 2025
WY <- UT   SOLICITATION  PATH 1.4 Community Care Hubs RFGA
WY <- UT   SOLICITATION  SPRINT Consortium RHTP Grant Application
WY <- UT   SOLICITATION  Utah RHTP - Semantic Data Model RFGA
```

**AND NOT ONE OF THE TEN IS TIER 3.** Tier 3 is the only tier an extractor
reads, so **the wrong-state defect has not reached a single award file in this
repository** — including Missouri's and Indiana's, the two extracted states whose
sets are affected. That is a measurement of the corpus as pulled on 2026-08-27;
it is not a property of the aggregator and must be re-run rather than assumed.

### The sweep FLAGS and a human READS

**All eight Tier 3 flags are false positives, and every one is legible.**

* **`Providence Health & Services–Washington`** (Alaska, ×3) — a **real Alaska
  awardee** whose legal name carries its parent system's state, and which is in
  `ak_year1_awardees.csv`.
* **Alabama, ×4** — a bare county in a county list, *"(Clarke, Washington)"*. The
  generic `<State> County` exclusion cannot reach it.
* **Pennsylvania, ×1** — a street address, *"905 Washington Street"*.

Widening the exclusion list until the output is empty would suppress the **ten
real** findings along with the eight false, so the verdicts are hand-read and
visible in `SWEEP_VERDICTS`, and `sweep_build()` **refuses** both an unread flag
and a stale verdict.

---

## What moved

* `NAMED_HOSPITAL` goes **578 rows / $410,119,935 / 14 states → 609 rows /
  $482,781,258 / 15 states**. Wyoming's largest single recipient, the
  $38,618,260 to WIP, is **not** in it. Wyoming is the second largest single-state
  contribution after Georgia's $90.3M.
* `test_state_union.R` now combines **twenty-three** state files, twenty-one
  states.
* The review queue goes 17 rows → **19**, both new rows one-directional and
  worth $2,452,302 upward between them.
* No committed state file other than Wyoming's changed. No dollar moved anywhere
  else.

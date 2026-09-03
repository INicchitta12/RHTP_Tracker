# Session 44 — Delaware, Idaho and Ohio extracted; Mississippi's footer breaks
# the tier check; §0.3a gains its second half

**2026-09-03.** Zero RCJ quota. ~30 fetches across `mississippirhtp.com`,
`medicaid.ms.gov`, `governorreeves.ms.gov`, `news.delaware.gov`,
`dhss.delaware.gov`, `healthandwelfare.idaho.gov`, `governor.ohio.gov` and
`odh.ohio.gov`, throttled per §9.5.

Four states from session 43's fourteen-state low-candidate queue, worked in
the order that session recommended. **No hospital DOLLAR moved anywhere; the
named-hospital ROW COUNT moved by four.**

---

## 1. §0.3a — the defect is seven of eleven, and the rule has a second half

Session 43 re-counted `DE Verify.xlsx` and found the §0.3a defect is **seven
rows, not four**. That count holds and is confirmed here by reading the
workbook directly: rows 1–4 (the school-based health centres), **row 8 — Beebe
Medical Center**, **row 9 — TidalHealth**, and **row 11**, whose `awardee`
reads *"University of Delaware, Beebe Healthcare, Deloitte Consulting LLP"*.
All seven carry `rhtp_award_yn = yes` and `hospital_yn = no`.

### 1.1 One thing session 43 said about rows 8 and 9 is wrong, and correcting it makes the finding sharper

The spec, as session 43 left it, said rows 8 and 9 are *"bare hospital names
with **no activity attached at all** — there was nothing to be misled by"*.

**The workbook says otherwise.** Both rows carry
`activity_type = "Rural Delaware Diabetes Wellness Pilot Program"` and a full
`program_description` (*"Three-year pilot: Continuous Glucose Monitoring (CGM)
plus intensive care management for 500 rural patients..."*). The reviewer
instructions have listed row 8 as *"Beebe Medical Center | Diabetes wellness
pilot"* since session 6, so the two documents already disagreed.

**The real distinction is not whether an activity is attached; it is where the
activity SITS.**

| | rows 1–4 | rows 8–9 |
|---|---|---|
| `awardee` cell | *"Beebe Healthcare – Georgetown Middle School"* — the setting is **welded into the recipient field** | *"Beebe Medical Center"*, *"TidalHealth"* — **nothing but a hospital name** |
| `activity_type` | school-based health centre — a non-hospital setting | a diabetes pilot — **clinical care, nothing non-hospital in it** |
| what misled the coder | reading the recipient column and seeing a school | **nothing** |

On rows 1–4 a reviewer looking only at `awardee` is looking at an activity
while believing they are looking at a recipient. On rows 8 and 9 **neither
column offered a wrong answer and both rows came back `no` anyway.**

### 1.2 So the rule gains a second half, and a corollary

- **Second half — READ THE RECIPIENT AT ALL.** Refusing to be led by the
  activity is what rows 1–4 needed, and it is not enough on its own: a
  reviewer can apply it perfectly and still return `no` on a row whose
  `awardee` says *"Beebe Medical Center"* and nothing else, because the
  failure there is not misreading the recipient field but **not reading it**.
- **Corollary — the `awardee` field is not always only the awardee.** Where a
  publisher packs a recipient and a site into one string, split it and code
  the half that received the money. §6.2's multi-recipient rule is the same
  instinct applied to a different kind of crowding, and row 11 is the shape
  §6.2 already names — which is why the count is seven and not six.

Patched into all three documents. `rhtp-tracker-build-spec.md` §0.3a is
corrected in place (5 lines added, 1 replaced); **`CLAUDE.md` had no §0.3a
section at all** and gains one (61 lines, insert-only);
`reviewer-coding-instructions.md` gains 34 lines, insert-only.
`test_flow_table_parity.R` still passes — the §10.2 table was not touched.

**Nothing was re-coded.** Blocker 2 and Stage 5 own `DE Verify.xlsx`.

### 1.3 And the rule's own worked example is now live data — see §3

---

## 2. Mississippi — the first footer here that is not 100% federal

`R/03ak_ms_year1_probe.R`, `data/evidence/MS/` (5 files),
`ms_year1_status.csv` (10 rows, **no amount column**),
`ms_rcj_candidate_disposition.csv` (3 rows). **`ms_year1_awardees.csv` does
not exist and a test asserts its absence.**

### 2.1 The state has selected, has told the recipients by email, and has promised to announce

`mississippirhtp.com/funding/`, read live:

> *"The selection process is complete for the Rural Capital Care Gap Closure
> (RCGC), Rural Technology Grant (RTG), and Telehealth Hub Connectivity,
> Equipment, and Education (TCE) grant programs. Authorized representatives of
> selected applicants will be contacted by email this week to begin the
> sub-award execution process."*
>
> *"Governor Tate Reeves will formally announce details regarding all executed
> sub-awards in the coming weeks."*

South Carolina's email shape **with a public announcement attached**. That is
the strongest forward signal in the queue, and it is why this state got a
probe and a Routine before it got an extractor.

### 2.2 The footer defeats the tier check without being wrong about anything

Measured before anything was written: **222 CMS financial-assistance footers
parse out of the committed corpus** — 186 from HTML and text, 36 from PDFs —
and **all 222 are 100 percent federal**, with `tier_amount == headline` on
every one. Mississippi's is the first that is not:

> *"...as part of a financial assistance award totaling **$205,990,180.16**,
> with **99.96% funded by CMS/HHS ($205,907,220.16)** and **0.04% funded by
> non-government sources ($82,960)**."*

Driven, not reasoned about:

```
headline  $205,990,180.16  declared STATE_ALLOTMENT -> REFUSED   (correct)
headline  $205,990,180.16  declared SOLICITATION    -> ACCEPTED  (WRONG)
CMS share $205,907,220.16  declared STATE_ALLOTMENT -> ACCEPTED  (correct)
CMS share $205,907,220.16  declared SOLICITATION    -> REFUSED   (correct)
```

**Line 2 is the defect.** The headline is Tier 1 plus a non-federal match and
there is no Tier 2 pool in that sentence at all, so a session feeding the
headline to the tier check would publish $205,990,180.16 as one programme's
budget.

**And the footer is internally exact, which session 43 did not say and which
matters:** headline − CMS share = **$82,960.00**, the non-government figure
the footer prints, **to the cent**. The publisher's three numbers close on
each other, so the CMS share is a *stated* figure whose arithmetic checks out
rather than a reading of ours. (Session 43 recorded the gap as $82,960.16.
That is the headline against the §7.1 **anchor**, which carries the anchor's
own 16 cents of rounding — a different comparison, also true, and not the one
that shows the footer is self-consistent.)

### 2.3 The fix is a parser, not a wider margin

`rhtp_footer_parse()`, `rhtp_footer_cms_share()` and
`rhtp_assert_footer_text_tier()` are added to `R/utils_config.R`. They take
TEXT rather than a number, so the headline/CMS-share distinction is made once,
where the evidence is, instead of by every caller remembering.

**It is inert on everything committed**: swept over all 222 footers, every one
returns its headline unchanged. It changes behaviour only on Mississippi's
shape.

**And it refuses to compute (§0.4).** Where a footer states a partial share
and prints no dollar figure for it, `tier_amount` is `NA` and the tier check
does not run — headline × 99.96% is a number no publisher printed, and a
percentage rounded to two places cannot reproduce a cent-exact allotment.
A test drives that branch.

`RHTP_FOOTER_ALLOTMENT_MARGIN` **stays at $10,000**, and a test pins it there
with the reason: $82,960 is one state's match amount and the next state's will
differ, so widening buys nothing and costs the check its only signal.

### 2.4 The controls, and they are unusually good

**The positive control is the channel Mississippi itself named.** The promised
announcement is the Governor's, so `governorreeves.ms.gov/newsroom/` is where
it lands, and that newsroom carries dated, priced award announcements —
*"Gov. Reeves Announces Investment In Mental Health Services For Mississippi
Youth ... deploying $3,375,709"* (2026-08-24) — with no RHTP award among them.

**The §6.2 negative control and RCJ's third candidate are the same document,
and the machine had already disposed of it.** MS Division of Medicaid's
Completed Procurements page carries an RHTP-titled award:

> *"Quote – Rural Health Transformation Program – RFX #3140004330 –
> 7/28/2025"* … *"Public Notice of Award – 8/13/2025"* … *"the selection of
> HORNE LLP"*

A **named awardee, on a state host, under an RHTP title** — and not an RHTP
subaward: it is the consultant Mississippi hired to help **write its
application**, awarded **138 days before** the 2025-12-29 Notice of Award.
Money the state did not yet have cannot have funded it. **Session 20's
provenance sweep already flagged that exact RCJ row `PROVENANCE_PREDATES_NOA`
off the document title's own date**, so a filter written four sessions before
anyone looked at Mississippi and a live read of DOM's page agree, from two
directions, with nothing arranged.

The same page is a *second* positive control: ten *"Public Notice of Intent to
Award"* documents in one uniform form.

### 2.5 The other two candidates, and two digest mechanisms

RCJ's remaining Mississippi Tier 3 candidates are the **Comprehensive State
Health Plan RFP** (Premier Healthcare Solutions at $0 — an ordinary MSDH
procurement) and **"QIPP PPHR, PPC, and AM-PPC Presentation - July 2025"** at
$50,000,000, which is **a document title, not an organisation** (§6.1) for a
Medicaid supplemental payment programme, dated five months before the NOA.
**Not one of the three is an RHTP subaward.**

**Two digest mechanisms, and only one is new.** `mississippirhtp.com` runs
Cloudflare Email Address Obfuscation — three fetches three seconds apart,
217,198 bytes every time, three distinct file digests, reduced text identical
at 7,185 chars. That is session 36's seventh mechanism (Louisiana) recurring.
**`medicaid.ms.gov` is new and is the most literal one this project has met**:
the WordPress *Simple Banner* plugin serialises the render wall-clock time
**to the microsecond** into a `<script>` body —
`"current_date":{"date":"2026-09-03 19:25:41.029022"}` — three times per
render. Fixed-width, so a byte-count check passes it; unlike Arkansas's
timestamp-derived token it changes on **every** request, so a back-to-back
pair does expose it. Three of the four watched pages rotate their file digest
while nothing about the awards moves, which is why `--probe` compares a
content digest.

**Mississippi is on Routine `trig_01RmgWna5oXyoMCXYrVqGVvE`, TUESDAYS AND
FRIDAYS 09:40 UTC**, first firing 2026-09-04. Twice-weekly because the
announcement is promised *"in the coming weeks"* and the first awards were
expected *"by the end of the month"* in reporting of 2026-08-06 — **a date
that has passed**. 09:40 because the fourteen Routines already running occupy
a continuous band from 10:50 to 21:10 UTC. It ran live first and reports
**UNCHANGED** on all four pages.

---

## 3. Delaware — four awards, three organisations, no amounts, and §0.3a's own
example arriving as data

`R/03al_de_year1_awardees.R`, `data/evidence/DE/` (3 files),
**`de_year1_awardees.csv` (4 rows)**, `de_year1_status.csv` (16 rows, no
amount column), `de_rcj_candidate_disposition.csv` (3 rows), and
**`DE_year1_awardees.xlsx`** on the Florida schema.

DHSS, 2026-07-29, live-read:

> *"The Delaware Department of Health and Social Services (DHSS) today
> announced **awards** to establish four new school-based health centers in
> Sussex County through the state's Rural Health Transformation Program
> (RHTP). ... The awards include: Nemours Children's Health – Seaford Middle
> School; TidalHealth – Selbyville Middle School; Beebe Healthcare – Sussex
> Central Middle School; Beebe Healthcare – Georgetown Middle School"*

**Four award actions, three organisations, and not one dollar figure.**
Nevada's, Iowa's and North Carolina's shape at the smallest scale yet.

### 3.1 The classifier reproduces §0.3a's defect, and that is measured

`rhtp_classify_recipient_type()` on each name **as Delaware publishes it**:

```
"Beebe Healthcare"           -> NONPROFIT_CBO       LOW    (§8's fallback)
"Nemours Children's Health"  -> NONPROFIT_CBO       LOW    (§8's fallback)
"TidalHealth"                -> NONPROFIT_CBO       LOW    (§8's fallback)
"Beebe Medical Center"       -> HOSPITAL_OR_SYSTEM  HIGH
```

**Not one of the three carries a token §8's name rule recognises.** Left to
the machine, Delaware's four rows are `distributed_to_hospital = No` and the
state contributes **zero** named-hospital rows — §0.3a's defect, reproduced in
code, thirty-seven sessions after it was found by hand. A test drives that
counterfactual.

The fourth line is the **same organisation** under the spelling `DE
Verify.xlsx` row 8 uses, and it classifies the other way: North Carolina's two
spellings of UNC for the third time, and here it decides whether the state has
any hospital rows at all.

**The override is the spec's, not this session's.** §0.4 forbids promoting a
recipient on this pipeline's own knowledge and nothing here does: §0.3a names
all three organisations as *"hospitals and health systems"* and states the
coding outright, and the reviewer instructions' worked-example table codes all
three `Yes`. Those are committed governing documents written about these exact
recipients. **The classifier's own answer is preserved on every row in
`recipient_type_source`** (Indiana's convention), so the override is auditable
and reversible. `determination_confidence` is `MEDIUM`, not `HIGH` — §7
reserves HIGH for a CCN match and blocker 5 is open.

### 3.2 Two figures were deliberately kept out of the award file

- **The $195,000 is a BUDGET LINE.** DHSS's programme page prices all fifteen
  initiatives and gives *"School-Based Health Centers ... Year 1 Budget:
  $195,000.00"*. That is Tier 2 planning money from the state's own budget
  narrative, not a round total an award announcement published — Nevada's and
  North Carolina's `round_amount` both came from award announcements, and this
  release publishes no round figure at all. §0.3 says a plan is not an award,
  so `round_amount` is `NA` and the figure lives in `de_year1_status.csv`,
  labelled. **$195,000 / 4 = $48,750 is a figure no publisher has stated**,
  and a test drives the guard that refuses it.
- **The only currency on the release is the ALLOTMENT.** *"$157,394,963.86
  with 100 percent funded by CMS/HHS"* against the anchor's $157,394,964 —
  Tier 1 wearing the weak *"This project"* grammar, declared `STATE_ALLOTMENT`
  and checked both ways.

### 3.3 One closure, arranged by nobody

The **fifteen Year 1 budgets on the live programme page match the fifteen
parsed out of Delaware's budget-narrative PDF in session 8**
(`data/interim/initiatives.csv`) **to the cent, all fifteen**, summing to
**$141,655,467.48** both ways. A document read in February and a page read in
September agreeing. Asserted.

### 3.4 The rest

The `awardee` field is **split from the site** — §0.3a's new corollary applied
to the data it came from: `awardee` is the recipient half, `award_site` the
school, `awardee_as_published` Delaware's whole string. RCJ carries all four
**correctly named at $1 each** (Missouri's placeholder); its other two Delaware
candidates are a **Tier 2 budget line** (Delaware State Housing Authority,
$11.5M) and **the original §6.2 finding from Stage 0** (La Red Health Center,
from an HRSA fact sheet). The channel control is direct: the same news feed
carried *"$5 Million in State Arts Grants Heads to All Three Delaware
Counties"* **on the same day**, so Delaware publishes figures when it has
them.

**Delaware contributes 4 named-hospital rows and $0.** Read the row count.

---

## 4. Idaho and Ohio — one named awardee each, and they are each other's
contrast with Delaware

### 4.1 Idaho: one name, no amount, no hospital

`R/03am_id_year1_awardees.R`, `data/evidence/ID/` (2 files),
`id_year1_awardees.csv` (**1 row**), `id_year1_status.csv` (5 rows),
`id_rcj_candidate_disposition.csv`.

DHW's funding page, one line under *Closed funding opportunities*:

> *"CLOSED 7/10/26: Maternal and Child Health Initiatives — Awardee: **Comagine
> Health** — Perinatal Quality Collaborative OB Readiness — Anticipated award
> start date: Aug. 14, 2026"*

An **intent** in Idaho's own future tense, so `NOTICE_OF_INTENT_TO_AWARD` +
`amount_confirmed = No` + `AMOUNT_PRELIMINARY`. **No amount, and no hospital:
Idaho contributes to NO bucket at all** — Maine's and Missouri's outcome
reached by a third route.

**And its classifier answer is the same as Delaware's and is RIGHT.** Comagine
Health takes §8's standing fallback (`NONPROFIT_CBO` + LOW +
`RECIPIENT_TYPE_INFERRED`) because **Idaho states no form** and no governing
document states one either. That pair — same machine answer, opposite verdict
— is what shows Delaware's override is about evidence rather than about the
classifier being weak, and both files say so.

**The footer is the weakest SUBJECT met so far**: *"**This website** is
supported by ... totaling $185,974,367.81"* — session 27's weak form with a
new subject noun, and its figure is the allotment.

**§0.1**: RCJ's only Idaho candidate is **"Co-Imagine Health" at $1** with no
source document. No such organisation exists and Comagine Health is Idaho's
only named awardee, so it is evidently the same body under a corrupted name —
**but no document says so**, that match is this project's reading (§0.4), and
it does not matter, because the row is built from the state page.

**Idaho is the most active of the fourteen**: eleven open or just-posted
opportunities with vendor conferences into early September 2026, plus three
cooperative agreements. `publicdocuments.dhw.idaho.gov` (Laserfiche) reads
**UNREADABLE/UNKNOWN**.

### 4.2 Ohio: one priced award, and a footer whose figure is the SUBAWARD

`R/03an_oh_year1_awardees.R`, `data/evidence/OH/` (3 files),
`oh_year1_awardees.csv` (**1 row, $10,000,000**), `oh_year1_status.csv`,
`oh_rcj_candidate_disposition.csv`.

Governor DeWine, 2026-07-01: *"the first Rural Health Transformation Program
award to Ohio University"*, **$10,000,000**, for rural healthcare workforce
development. `UNIVERSITY_OR_AHC` → `NON_HOSPITAL` → **$0 of hospital money**,
which is Maine's University of New England row for the same reason.

**§0.2 GAINS A THIRD POSITION ON ITS AXIS.** Every footer this project has
read prints either the state allotment (Tier 1) or an RFP's pool (Tier 2).
Ohio's prints **neither**:

> *"...as part of a financial assistance award totaling **$10,000,000** with
> 100 percent funded by CMS/HHS."*

**That is the SUBAWARD** — the exact figure in the headline, on a release
announcing one award to one recipient.

**And it is a limit of the tier check, stated rather than patched.**
`rhtp_assert_footer_not_allotment()` asks one question: does this figure
collide with the state's allotment? $10,000,000 does not collide with
$202,030,262, so **declared `SOLICITATION` it is ACCEPTED** — and it is not a
pool, it is Tier 3. The check separates Tier 1 from not-Tier-1 and has never
been able to separate Tier 2 from Tier 3, because the §7.1 anchor is the only
external number it has. Session 37's Iowa rule said the tier is not in the
footer's **grammar**; Ohio adds that it is not always in its **arithmetic**
either. **What identifies it is the document.** Asserted in both directions,
with the failure message pointing a future session at this paragraph.

**Ohio's Year 1 is PARTIAL by construction** — *"Additional contracts will be
awarded in the coming months"*, so $192,030,262 is in no public roster — and
ODH's own page is **stale in Mississippi's way**, still reading *"the State of
Ohio will submit an application. If awarded..."* on the page that links the
award announcement. Its Solicitation Invitations table is
**UNREADABLE/UNKNOWN**.

**§0.1: RCJ is RIGHT about Ohio**, name and figure and document — rare enough
to be worth stating beside Missouri's, Maine's, Delaware's and Idaho's $1
placeholders and Michigan's grain defect.

---

## 5. What moved, and what did not

**`NAMED_HOSPITAL` goes 609 rows / $482,781,258 / 15 states → 613 rows /
$482,781,258 / 16 states.** Delaware adds four rows and **not one dollar** —
the third state after Iowa and North Carolina to move the row count without
moving the dollar figure, and the second (after Iowa) where reading down the
dollar column alone makes a whole state invisible. `POOL_NAMED_HOSPITALS`
(1 / $18,156,856) and `POOL_UNNAMED_HOSPITALS` (1 / $50,008,264) are
unchanged.

**The 50-state disposition, rebuilt from `R/03k`'s constants and never
hand-edited:**

| | before | after |
|---|---:|---:|
| `EXTRACTED` | 22 | **25** (+DE, +ID, +OH) |
| `INVESTIGATED_NO_LIST` | 8 | **9** (+MS) |
| `INVESTIGATED_NO_PROBE` | 6 | 6 |
| `QUEUED` | 14 | **10** |

The ten still queued are **AZ CO MT ND RI UT VA VT WA WV**, holding
$1,916,786,628 and **24 candidates between them**. Session 43's §2 is still
their disposition.

**Nothing was promoted (§0.4).** Delaware's three recipient types come from
the spec, with the machine's answer preserved on every row; Idaho's and
Ohio's come from the classifier unaided. **Nothing in `DE Verify.xlsx` was
re-coded** — blocker 2 still owns it, and rows 8 and 9 are named in Delaware's
status table as belonging to the Continuous Glucose Monitoring initiative,
which has published no award notice this environment can reach.

**Tests: 4,740 → 5,171 across 52 files**, all passing with the one standing
self-skip (stage 00's first-run branch). Five new files —
`test_utils_footer_cms_share.R` (71), `test_03ak_ms_year1_probe.R` (43),
`test_03al_de_year1_awardees.R` (45), `test_03am_id_year1_awardees.R` (28),
`test_03an_oh_year1_awardees.R` (31) — and `test_state_union.R` now combines
**twenty-six** state files across twenty-five states.

---

## 6. Next

1. **Mississippi is the thing to watch.** The Routine fires Tuesdays and
   Fridays. When it breaks, write a new extractor — do not patch the probe —
   and **parse the CMS share, never the headline**.
2. **Idaho and Ohio should go on Routines too.** Both have `--probe`
   implemented and neither is scheduled: Idaho has eleven opportunities in
   flight and Ohio has said more contracts are coming. Delaware's probe exists
   for the narrower case of an amount appearing.
3. **The ten remaining queued states**, in session 43's §2 order. West
   Virginia's four candidates still need reading before anyone trusts them.
4. **Blocker 2 is now the cheapest large win in the repository.** Delaware's
   extraction used `DE Verify.xlsx` as evidence and did not ingest it; the
   next step is to bring it into `data/reference/` the way `R/03e` did for the
   owner's Florida workbook, so Stage 5 can own the seven mis-coded rows.

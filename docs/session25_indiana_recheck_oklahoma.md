# Session 25 — Indiana is unchanged, and Oklahoma publishes a roster the aggregator holds none of

**Date:** 2026-08-31
**Quota:** zero RCJ calls. 14 fetches to `oklahoma.gov`, 6 live re-checks against
`www.in.gov`, all throttled per §9.5.
**Files:** `R/03t_ok_year1_awardees.R` (new),
`data/reference/ok_year1_awardees.csv` (new, 69 rows),
`data/reference/ok_rcj_candidate_disposition.csv` (new, 5 rows),
`OK_year1_awardees.xlsx` (new), `data/evidence/OK/` (new, 8 sources),
`R/utils_recipient_classification.R` (two §8 additions, provably inert),
`data/reference/classification_review_queue.csv` (one row appended),
`tests/testthat/test_03t_ok_year1_awardees.R` (new),
`tests/testthat/test_state_union.R` (fourteen states).

---

## Task 1 — Indiana: nothing has changed, and that is measured, not assumed

`in_assert_regional_not_awarded()` **passes**, offline and live.

Session 24 left Indiana with a deliberately fragile assertion: the GROW Regional
Grants page says *"It launches Sept. 1, 2026, with $120M awarded annually across
eight regional coalitions"*, and the assertion fails the day that sentence goes.
The offline run passes trivially — it reads the committed archive — so the
question was re-asked of the **live** site.

**All six live Indiana pages are BYTE-IDENTICAL to the committed archives.**

| page | live bytes | SHA-256 matches archive |
|---|---:|---|
| `in.gov/grow-rural-health/regional-grants/` | 104,367 | **yes** |
| `in.gov/grow-rural-health/` | 29,220 | **yes** |
| `in.gov/idoa/procurement/award-recommendations/` | 172,842 | **yes** |
| `in.gov/grow-rural-health/initiatives/initiative-1` | 27,997 | **yes** |
| `in.gov/grow-rural-health/initiatives/initiative-7` | 27,263 | **yes** |
| `in.gov/grow-rural-health/initiatives/initiative-10` | 24,999 | **yes** |

All three pre-award sentences are still on the live regional-grants page —
the launch sentence, *"RFF Applications submitted July 1"* and *"score
applications and determine funding"* — and so are the committee tables that
`in_assert_committee_not_recipients()` pins.

IDOA's register still carries **exactly four RHTP-titled rows** (26-87448,
26-87449 twice, 26-87450), which is the number `in_assert_award_register()` was
built against and refuses to exceed. **No fifth RHTP row. No re-extraction
needed.**

**The launch is tomorrow, not today.** The page says *Sept. 1, 2026*; this
session ran on 2026-08-31. So the item stays at the top of the next session's
list, unchanged, and the assertion is still the thing that will announce it.

---

## Task 2 — Oklahoma

### The headline

**OSDH publishes a recipient-level roster, and RCJ holds not one row of it.**

```
Community-Led Wellness Hubs: Microgrants   68 awards   $3,572,120.71   54 recipients
OSDE's ROOTS Competitive Grant             60 awards   $  600,000      NOBODY NAMED
```

That is **1.6%** of Oklahoma's $223,476,949 allotment, and it is all there is:
OSDH is running **ten** Budget Period 1 funding opportunities and has published
awardees for **two**.

**20 award actions reach 18 named hospitals: $1,079,506.22.**

### Where it is

`oklahoma.gov/health/rhtp/rhtp-funding-recipients.html` — a dedicated **RHTP
Funding Recipients** page with an "Awardees" navigation carrying exactly two
anchors, `#roots` and `#microgrants`. The page says what it is in its own first
paragraph: *"This page provides information about funded projects, award
amounts, and the organizations selected to receive RHTP funding. As new funding
opportunities are awarded, recipient information will be added to this page."*

It was found through `/api/v1/activity`, not through RCJ's award records —
Oregon's lesson (session 17) working a second time. `state_source_url` is NA on
all 35 Oklahoma Tier 3 records; `stage2_state_sources.rds` has five real OSDH
URLs, one of which is the funding page the roster hangs off.

### §6.2 — the provenance test passes in the strongest form this project has seen

**The CMS financial-assistance footer is on the award roster itself**, and on
the funding page, the programme page, the NOFO announcement, and all four RHTP
PDFs:

> *"This publication is supported by the Centers for Medicare & Medicaid
> Services (CMS) of the U.S. Department of Health and Human Services (HHS) as
> part of a financial assistance award totaling **$223,476,948.62** with 100
> percent funded by CMS/HHS."*

That rounds to `cms_fy2026_allotments.csv`'s **$223,476,949** exactly, and the
comparison is made against the anchor rather than typed. Indiana's footer was
on the *solicitation*; Oklahoma's is on the *roster*.

The date half passes too, and its evidence is on the archived document: the
microgrant NOFO was announced **2026-03-16** with applications due
**2026-04-13**, both after Oklahoma's **2025-12-29** Notice of Award. Texas's
`HHS0015180` closed 2025-04-24, eight months before its state had the money.

The automated §6.2 sweep already reported Oklahoma clean — 0 of 35 candidates
caught — and this is what that line was worth: nothing about the awards, which
the sweep never saw, and everything about the candidates, which are all Tier 2.

### §0.1 — the worst ratio yet, in a new direction

**Not one of RCJ's 35 Oklahoma Tier 3 candidates is one of these 68 awards.**
Every one is a **budget line** mined out of a Tier 2 planning document.

| group | rows | RCJ amount | disposition |
|---|---:|---:|---|
| Budget Narrative initiative allocations | 8 | $156,417,000 | `RHTP_BUT_NOT_A_SUBAWARD` |
| Budget Period 1 Initiative Funding Summary lines | 8 | $25,800,000 | `RHTP_BUT_NOT_A_SUBAWARD` |
| Legislative Quarterly Report Q1 + Q2 programme rows | 17 | $49,370,254 | `RHTP_BUT_NOT_A_SUBAWARD` |
| August 2026 Touchpoint Webinar line | 1 | $27,121 | `RHTP_BUT_NOT_A_SUBAWARD` |
| EMS Centralization — Pulsara ($1 placeholder) | 1 | $1 | `RHTP_BUT_A_PLATFORM_NOT_A_SUBAWARD` |
| | **35** | **$231,614,376** | **RHTP subawards: 0** |

**An extractor built from the candidate list would have published
$231,614,376 as Oklahoma's Tier 3 subawards — MORE THAN THE ENTIRE
$223,476,949 ALLOTMENT**, and 65 times the $3,572,120.71 Oklahoma has actually
awarded to named recipients. Texas was $16.8M; Indiana was ~$147M.

**And the documents say so in their own glossary.** The Legislative Quarterly
Reports define the column RCJ mined:

> *"**Y1 Budget Allocation**: The amount of funds dedicated to the program."*
> *"**Obligation**: Formally committing to spend funds through a contract or
> other signed agreement."*

The "Funded Entity" beside it is the **implementing agency** — OHCA, OSDH,
OSDE, OSU, OUHSC, SWODA, the Foundation for a Healthy Oklahoma. That is §6.1's
`PROGRAM_NAME_AS_AWARDEE` and §0.2's Tier 2, stated by the publisher.
RCJ's awardee strings make it plainer still: *"Oklahoma Health Care Authority
(OHCA) - EHR expansion"* is an agency and a fund use welded together.

**This one is a different failure mode from Indiana's.** Indiana's defect was an
*appended* label — RCJ writing "RHTP 2026 Award Announcement" onto a hydraulic
tail trailer. Oklahoma's documents ARE all RHTP; the defect is **tier**. Every
figure is real, every document is genuine, and every row is one level up from
an award. A plausibility check on the provenance catches nothing here, and a
plausibility check on the amount catches nothing in Indiana. **The check that
catches both is reading what the document says the number IS.**

### The positive control, and the six counties that are the parse's own

**OSDH demonstrably publishes rosters in a recognisable form**, so "the other
eight opportunities have published no roster" is a finding about Oklahoma and
not about our reading. `ok_assert_award_index()` requires exactly the two
anchors and **refuses a third**. `ok_assert_pending_not_awarded()` names the
five closed opportunities with no roster and **is designed to fail** the day one
of them appears on the recipients page:

| closed opportunity | anticipated |
|---|---:|
| Chronic Disease Management Program | $15,000,000 |
| Rural Regional Reorientation (RRR) Program | $20,000,000 |
| EMS & Community Paramedicine Vehicles | $3,675,000 |
| Expanding Care: Doulas Program | $2,500,000 |
| Behavioral Health Integration — MOUD/MAUD | $2,800,000 |

**And the roster carries its own negative control.** OSDH lists **74 counties**
in one uniform three-line block shape — county, recipient and amount, project
sentence. **Sixty-eight carry an award. Six say "No Awardee"**: Beckham,
Canadian, Cherokee, Love, Nowata and Pawnee, each with *"There were no
[eligible] applications submitted from X County."* A parser that read the block
*shape* and not the *content* produces 74 rows and six invented recipients, and
would look entirely reasonable doing it. `ok_assert_no_awardee_counties()`
requires exactly those six by name, present in the source and absent from the
awards — and the guard is itself positive-controlled by feeding it a faked
Nowata award and requiring a refusal.

Oklahoma has 77 counties. The three not listed are **Oklahoma, Tulsa and
Kingfisher**; the NOFO excludes Oklahoma and Tulsa counties by its own rural
definition, and Kingfisher's absence is unexplained and **recorded rather than
filled in**.

### Two independent corroborations, neither arranged

The Q2 Legislative Quarterly Report — a different document, published five weeks
before the roster was read — states both counts:

* *"OSDH issued **68 awards** through the competitive Microgrant application"*
* *"OSDE ROOTS (Presidential Fitness): **60 awards totalling $600K** to local
  schools"*

Both are asserted every run.

### ROOTS names nobody, and that is South Dakota's lesson

OSDE *"has selected sixty (60) PK-12 rural school sites for a $10,000 grant"* —
**a count and a unit price, and no roster** (§0.3). So ROOTS is **one aggregate
row** with an **empty `amount`** and its $600,000 in `round_amount`, South
Dakota's device, so no sum over `amount` can read as a per-recipient figure
(§6.2). `sum(amount)` is exactly the microgrant total and nothing else.

It is `distributed_to_hospital = No` rather than `Unclear`, and that is a
deliberate difference from South Dakota: OSDE states the recipient **class**
even though it names no member of it, and PK-12 school sites are §10.2's own
`NON_HOSPITAL` worked example — judged on the recipient, never the activity
(§0.3a). South Dakota's rounds are `Unclear` because their described recipients
are explicitly mixed.

### The hospital figure is a floor — and for the first time the uncertainty is one-directional

OSDH publishes a county, a recipient, an amount and a project sentence, and
**nothing about the recipient's organisational form** — no column of the kind
Oregon and Alaska both have. Kansas's, Maryland's and Nebraska's shape a
**fourth** time.

```
NAMED_HOSPITAL, 20 award actions to 18 hospitals   $1,079,506.22   ← a FLOOR
recipient form NOT STATED, 31 rows                 $1,575,304.25   ← larger
                                                   ------------
ceiling, if every unstated row were a hospital     $2,654,810.47
```

**What is new in Oklahoma is the direction.** In Maryland the uncertainty ran
both ways — TidalHealth uncounted, Choptank counted and reading as an FQHC.
Here **every one of the 31 fallback rows is already `distributed_to_hospital =
No`**, so resolving any of them can only *raise* the figure. $1,079,506.22 is a
genuine floor and $2,654,810.47 a genuine ceiling, and a test asserts the
one-directionality rather than the report merely claiming it.

It runs upward on the names, too: **DRH Health** (Duncan Regional Hospital,
$66,608.44 across Cotton and Jefferson), **SSM Health St. Anthony Shawnee**
($48,300.00), **Marshall County HMA dba AllianceHealth Madill** ($47,300.00),
**Baptist Healthcare** ($73,188.00 across Craig and Ottawa), **Fairfax Medical
Facilities, Inc.** ($83,017.73) and **Avem Health Partners** ($99,852.00) are
all inside the 31 and all uncounted. Others plainly are not — CREOKS, LIFT
Community Action Agency, Washington County Eldercare.

**Nothing was promoted (§0.4).** Queued as `OK_RECIPIENT_FORM_NOT_STATED`, with
the ceiling stated in the queue row and asserted against the file every run.

### Two rows typed from the source, and one §8 rule added

Both move **$0** — every one is `No` under the fallback and under the override —
which is why they were settled rather than queued.

* **Stigler HWC** (3 counties, $121,897.91) → `FQHC_OR_RHC`. OSDH's own award
  paragraph reads *"As a Federally Qualified Health Center (FQHC), Stigler HWC
  places a strong emphasis on..."*. The awarding agency stating the recipient's
  federal designation in the award document outranks any name pattern — Indiana's
  precedent for typing from the source.
* **Choctaw Nation of Oklahoma** ($38,600) → `TRIBAL_ORG`. §8's tribal pattern
  keys on tribal/tribe/native village/band of and cannot reach the *"Nation"*
  styling. Recorded per entity rather than by widening that pattern to a bare
  `nation`, which would be a fuzzy token in a rule that has to hold for fifty
  states.
* **`\bpublic schools?\b` → `SCHOOL_OR_DISTRICT`** was added to the generic §8
  pattern table, because *Altus Public Schools* and *Clayton Public Schools*
  fell through every rule to the fallback and would have been queued as "form
  not stated" when the form is stated plainly in the name.

**The classifier change is provably inert.** All fourteen existing extractors
were re-run and **every committed reference CSV came back byte-identical**; the
thirteen workbooks differed only in `dcterms:created` and were reverted. The
string `public school` occurs exactly once across every reference CSV, inside an
Alaska project *description* whose awardee is "Department of Education & Early
Development" — a name-keyed rule cannot see it.

---

## The §7A comparison — the point of the session

Oklahoma is the first state where a recipient-level extraction can be checked
against a §7A initiative table this repository already holds. Here is the check.

| | |
|---|---|
| **INITIATIVE LEVEL** (`OK_initiative_table.xlsx`, 28 fund uses) | |
| Budget Period 1 allocated | $204,900,000 |
| Hospital-directed (`has_hospital_recipient = Yes`) | $99,800,000 |
| Hospital-directed share | **48.7%** |
| Fund uses coded hospital-directed | 6 |
| **Of those, fund uses with a published recipient roster** | **0** |
| **RECIPIENT LEVEL** (this file) | |
| Award dollars with a named recipient | $3,572,120.71 |
| Share of the allocated BP1 budget covered | **1.74%** |
| Named-hospital dollars (a floor) | $1,079,506.22 |
| Named-hospital share of what is published | **30.2%** |
| Ceiling if every unstated row were a hospital | 74.3% |

**Read those as two claims over two universes, not as one number checking
another.** 48.7% is the hospital-directed share of $204.9M of *initiative
allocations*. 30.2% is the named-hospital share of the $3.57M Oklahoma has
actually awarded *to named recipients*. **They do not overlap at all**: none of
the six hospital-directed fund uses — Provider Collaborative Network $43.1M,
Rural Regional Reorientation $26.4M, Rural Residency $22.4M, CHW Expansion
$4.3M, Lung Screening $2.3M, Maternal Health VBP $1.3M — has published a single
recipient. So **nothing in this file tests the 48.7%**, and the comparison the
session was built to make turns out to be possible in principle and nearly empty
in practice.

**But the one place it CAN be made, the initiative table was wrong.** The two
fund uses Oklahoma has published recipients for are **both coded
`has_hospital_recipient = No`**:

| fund use | initiative-level coding | what the roster shows |
|---|---|---|
| Community-Led Wellness Hub: Microgrants | `No` — *"Local health departments in 59 rural counties and community-based entities"* | **20 hospital award actions, $1,079,506.22** |
| Presidential Fitness Test Preparation (ROOTS) | `No` — PE equipment reimbursement for rural schools | correct: OSDE selected PK-12 school sites |

The narrative predicted health departments and CBOs. The roster names Beaver
County Memorial Hospital, Comanche County Hospital Authority, Purcell Municipal
Hospital, Fairview Regional Medical Center, the LeFlore County Hospital
Authority and thirteen others — **and not one county health department.** The
initiative-level coding was wrong for this line, and wrong in the
**conservative** direction, which is the good direction and still a measured
miss. `ok_assert_initiative_parity()` pins both codings, so if either flips the
finding fails rather than quietly ceasing to be true.

**A useful caution about the denominator itself.** Oklahoma revised this fund
use upward between its own two Tier 2 documents: the Initiative Funding Summary
(03.10.26, the §7A source) allocates **$2,800,000**; the Q2 Legislative
Quarterly Report (07.10.26) allocates **$7,750,000**; OSDH awarded
**$3,572,120.71**. Both figures are Oklahoma's own and four months apart. That
is reported, not resolved — and it means a §7A initiative table is a snapshot of
a plan, not a fixed denominator.

**The single most useful lesson for the states still queued:** an initiative
table's `has_hospital_recipient` is a reading of a *plan*, and a plan that says
"community-based entities" can award 30% of its money to hospitals. It is a
discovery signal about where hospital money is likely to be, and it is not
evidence about where the money went.

---

## What is deliberately not in the file

* **The Q1/Q2 "Funded Entity" tables.** Tier 2 by the reports' own glossary.
  Dispositioned, not extracted.
* **The 11 hospitals selected for the Lung Cancer Screening Program.** The Q2
  report says *"11 hospitals selected with 9 hospital MOU's in progress"* and
  **names none**. A count is not a list (§0.3).
  `ok_assert_lung_screening_unnamed()` fails the day OSDH names them, and those
  eleven will be real named-hospital rows when it does.
* **The Oklahoma Hospital Association and the Foundation for a Healthy
  Oklahoma.** Both hold RHTP money at Tier 2 — CHW Expansion $4,586,721.33
  obligated and Lung Cancer Screening $2,371,360.66 obligated, per Q2 — and
  neither is on the roster, so §10.2's association branch never fires on an
  Oklahoma *award* row. `ok_assert_oha_absent()` fails the day one appears.
  CLAUDE.md's §10.2 worked positive — *"implementation will be conducted by
  hospitals reimbursed for CHW hiring, training, and monitoring"*, $4,300,000 —
  lives in the initiative table, not here.

## One archiving note

`oklahoma.gov/health/rhtp.html` and the long
`.../community-outreach/rural-health-transformation.html` return **byte-identical
bodies** — same SHA-256, same 694,330 bytes. They are two paths onto one AEM
page. It is archived **once**, the alias is recorded in the manifest, and a test
asserts no two archived files share a digest, so a future session cannot re-add
it and leave the evidence directory implying two corroborating documents.

## Tests

**2,558 assertions across 28 files, all passing** (was 2,405 across 27).
`test_03t_ok_year1_awardees.R` is new, 153 assertions, and
`test_state_union.R` now combines **fourteen** state files.

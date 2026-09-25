# Session 69: Arkansas round 2 extracted, ARHP's flow settled, Arkansas COMPLETE

Date 2026-09-25. Zero RCJ quota. Two fetches (ARHP's own site). Three tasks.

## 1. Round 2 (RISE AR / HEART) is extracted

`R/03ai` gains a ROUND 2 section and writes `data/reference/ar_year1_round2_awardees.csv`.
It reads the evidence session 68 archived under `data/evidence/recheck/2026-09-25/AR/`.

| | |
|---|---:|
| Organisations | 38 |
| Award actions (organisation x initiative) | 43 |
| RISE AR | $27,213,468.74 |
| HEART | $27,471,600.10 |
| Total, the list's own `Total:` row | **$54,685,068.84** |
| Governor's projects | 54 (30 HEART, 24 RISE AR) |

**It is a separate file.** Each list reconciles to its own `Total:` row, and
session 49's overlay is keyed on round 1's row index. The two files ARE additive
(two rounds, different awards). It is in `test_state_union.R` as `AR_R2`,
and in `R/03aw`'s `Y1_AWARD_FILES` as a second AR file.

**The parse.** It is the same producer as round 1, and the same weld under the
line model is asserted. The layout differs: a row's three amounts fall across
line breaks four different ways. So a row is "a name, then exactly three amount
cells in painted order". A name arriving mid-row is refused, and a test splices
one in to prove it.

**The $203,520 is not an unreconciled difference, and I did not flag it as
one.** It is in the release, printed badly. Conway Regional Health System's GME
project ends "– $203, 520.00", with a space after the thousands comma. A pattern
that allows only digits and commas reads 23 of the 24 RISE AR figures, and the
total comes out exactly $203,520.00 short. That is the gap session 68 reported.
Read with the space, the release matches the list:
- the 24 RISE AR projects sum to DF&A's RISE AR column to the cent;
- Conway's four RISE AR projects ($159,130 + $203,520 + $278,250 + $120,540)
  sum to its $761,440.00 on the list.

**The list stays the figure of record.** Nothing was corrected (§8).
`ar_r2_assert_projects_reconcile()` pins both readings: the strict one must miss
exactly Conway's figure, and the tolerant one must close. A re-published release
therefore fails the check rather than silently changing it. The release's amount
pattern is anchored to the trailing "– $". Conway's Rural Practice Incentive
description also contains "$15,000 incentives", which is not the award.

Twelve spellings differ between the release and the list. They are in a
hand-read map (`AR_R2_RELEASE_SPELLINGS`; §2 forbids a fuzzy match), and every
entry is asserted to be used. Three are defects in the list, kept as printed:
"New York Insitute of Technology", "Apple Seeds, Inc," and "Southeast Arkansas
Delta Solutions Community Dev" (truncated).

**Provenance.** The Governor calls it "the second round of Rural Health
Transformation Program (RHTP) grants". Round 1's NOFO headers already tie RISE AR
and HEART to RHTP by name. The award was announced 2026-09-24, after the NOA. The
list carries no footer. The release's footer is the allotment
($208,779,396.02), declared `STATE_ALLOTMENT` and checked (§0.2).

### Typing, and what moved

**`NAMED_HOSPITAL` +12 rows / +$18,870,981.65.** Every row is an intent
(`AMOUNT_PRELIMINARY`, `amount_confirmed = No`).

| Organisation | Rows | $ | Basis |
|---|---:|---:|---|
| White River Health System, Inc. | 2 | 5,056,530.50 | name rule |
| St. Bernards Development Foundation | 2 | 4,799,074.00 | §10.2 foundation row, carried from session 49 (GENERAL_KNOWLEDGE, LOW) |
| Mississippi County Hospital System | 1 | 4,402,000.00 | name rule |
| North Arkansas Regional Medical Center | 1 | 1,629,128.00 | name rule |
| Jefferson Hospital Association | 2 | 1,030,000.00 | name rule |
| Conway Regional Health System | 1 | 761,440.00 | name rule |
| Arkansas Surgical Hospital | 1 | 473,000.00 | name rule |
| Baptist Health | 1 | 418,883.00 | carried from session 49 (ORG_WEBSITE, MEDIUM) |
| White County Medical Center | 1 | 300,926.15 | name rule |

- **Carried types.** Four organisations are spelled character for character as
  in round 1: Baptist Health, ARHP, Subiaco Abbey and St. Bernards. They carry
  session 49's verified type from the committed overlay
  (`verification_queue_2_changes.csv`), with `basis_type` / `verified_by` /
  `verified_basis`. Any other spelling does not carry (§2). For example,
  "Arkansas Baptist Children and Family Ministries" is not round 1's "...
  Childrens Homes and ...".
- **Queued, not typed on recognition (`AR_R2_QUEUED_FORM`, OPEN, $7,068,862).**
  - UAMS keeps what §8's name rule gives, UNIVERSITY_OR_AHC. Round 1's UAMS rows
    carry the same code. The open question is whether an academic health centre's
    award, to the legal body that runs UAMS Medical Center, is a hospital award.
    If it is, round 1's $11,991,204 moves as well.
  - CARTI keeps §8's fallback.
  - North Arkansas Rural Health Consortium keeps the fallback. Its round-1 row
    carries session 49's OTHER, which was deliberately not carried forward. So
    the two files disagree on this organisation, and the queue row asks for both
    to be resolved together.
- **One classifier answer overridden, $0.** "Arkansas Chapter, American Academy
  of Pediatrics" read PHYSICIAN_PRACTICE off the word "Pediatrics". It now
  carries the fallback.
- **`AR_R2_RECIPIENT_FORM_NOT_STATED` (OPEN).** 21 organisations, 21 rows,
  $19,749,288.19, all `No`, so the question is one-directional. None reads as a
  hospital by name.

## 2. `AR_ARHP_CONSORTIUM_FLOW` is RESOLVED at option (c), and $0 moves

ARHP holds four actions, $20,882,186: THRIVE $7,896,955, PACT $10,936,566,
RISE AR $1,598,008 and HEART $450,657.

**§10.2's positive test asks whether any source says ARHP administers, re-grants,
sub-awards or reimburses funds to hospitals. None does.**
- **The Governor's descriptions.** They cover all eight ARHP projects across both
  releases. In every one ARHP is the subject that buys or delivers: "will purchase
  and install emergency generators", "will deploy virtual physician carts ... in
  participating rural hospitals", "will equip rural hospitals and EMS providers",
  "will open a Food Pharmacy at DeWitt Hospital and prepare implementation
  roadmaps for six additional rural hospitals". This is the GHA carts negative and
  session 50's Salina grammar test.
- **The classifier agrees.** Given all eight descriptions with
  `award_made = TRUE` (the hostile setting), it returns no pass-through.
- **ARHP's own site.** Archived this session, with SHA-256 in the recheck
  MANIFEST. It never mentions RHTP, and gives its membership as "19 rural
  hospitals, 4 FQHCs, over 120 member-owned and affiliated clinics, and three
  medical schools". The class is therefore broader than hospitals: even a
  pass-through reading would be FHC's `Unclear`, not ICAHN's `Yes`.

**Coding.** The flow is decided per award row:

| ARHP row | `flow_type` | `hospital_benefiting` | Why |
|---|---|---|---|
| Round 1 THRIVE | `IN_KIND_BENEFIT` | Yes | goods or services land in hospitals |
| Round 1 PACT | `IN_KIND_BENEFIT` | Yes | goods or services land in hospitals |
| Round 2 HEART | `IN_KIND_BENEFIT` | Yes | goods or services land in hospitals |
| Round 2 RISE AR | `NON_HOSPITAL` | No | the leadership institute names no hospital |

- All four rows are `distributed_to_hospital = No`.
  `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED` is removed from all of them.
- **Order of application.** `R/03ai --build` now re-applies session 49's overlay
  itself, then applies the resolution after it. The overlay writes each verified
  row's flow back, so any other order would undo the resolution. A test requires
  the committed file to equal builder + overlay + resolution byte for byte.
- **What would reopen it.** A source saying money passes to a hospital.

## 3. Arkansas is the third COMPLETE state

The completeness statement comes from the Governor, 2026-09-24: "this round of
funding completes the distribution of the $208 million awarded to Arkansas this
year". All four initiatives have a published list. `year1_completion_status.csv`
now reads AR `COMPLETE` (97.6% of the allotment).

**The remainder is $4,916,708.71.** It is decomposed in
`ar_year1_allotment_gap.csv`, using the same basis codes as the FL/GA file.

| Component | $ | Basis |
|---|---:|---|
| Planned administration | 4,680,988.00 | **PLAN.** Year 1 Revised Budget Narrative, "Total Administrative Costs": personnel $235,000, fringe $67,400, travel $3,000, BDO GS contracted administration $4,375,588. Nothing published says it has been spent (§0.3). |
| THRIVE allocation less award | −63,829.20 | **UNEXPLAINED.** THRIVE was awarded above plan. |
| PACT allocation less award | 127,018.77 | **UNEXPLAINED** |
| RISE AR allocation less award | 86,531.26 | **UNEXPLAINED** |
| HEART allocation less award | 85,999.90 | **UNEXPLAINED** |
| Anchor rounding | −0.02 | The footers print $208,779,396.02. |

The four UNEXPLAINED lines net to **$235,720.73**. No source says what that
remainder funds.

**Hospital share (COMPLETE states only).**

| | Rows | $ | Share of $203,862,687.29 awarded |
|---|---:|---:|---:|
| Arkansas `NAMED_HOSPITAL`, both rounds | 30 | 111,276,895.52 | **54.6% (floor)** |

- `R/03aw`'s ceiling equals the floor, because Arkansas has no `Unclear` priced
  rows.
- The open queue rows run upward and are **not** in that ceiling.
  - `AR_R2_QUEUED_FORM`: $7,068,862, or $19,060,066 if round 1's UAMS rows follow
    the same answer.
  - `AR_R2_RECIPIENT_FORM_NOT_STATED`: $19,749,288.19.
- Round 1's figure is **$92,405,913.87** to the cent. Earlier notes wrote ".96",
  and a default test tolerance let it through; that test is now exact.

**Weaknesses a reader should know.**
- **Every Arkansas award is an intent.** DF&A signs agreements later, and
  obligation is due 2026-10-30.
- **The Governor's "completes the distribution of the $208 million" is prose
  about a round that totals $203.9M.** COMPLETE rests on it together with the
  fact that no initiative is left unawarded. It does not rest on the percentage.

## What else moved

- **Partition.** `NAMED_HOSPITAL` goes 1,140 / $940,203,621.03 to **1,152 /
  $959,074,602.68**, still 28 states. South Carolina ($115,985,714.95) stays
  first and Arkansas ($111,276,895.52) second.
- **Probe.** The AR probe now compares the live home page with the 2026-09-25
  archive (`home2`) and expects TWO award-list links. A third fails. The round-1
  assertions still read their 2026-09-03 archives as round 1's record.
- **Status table.** `ar_year1_status.csv` shows all four initiatives
  `AWARDED_ROSTER_PUBLISHED`, with `award_round`.
- **Rural cut.** `R/03ar` was rebuilt because the partition moved.

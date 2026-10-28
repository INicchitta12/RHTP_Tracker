# Session 109: California extracted; session 108's rulings applied

2026-10-28. Branch `claude/festive-cori-sm3p3c`, started from `main` at `950e8ba` (session 108's
`claude/bold-bell-9l7mgj` merged). No Year 2 work was done. No CMS release read this session announces
FY2027 amounts.

## Hospital partition, before and after

The three buckets are never added together. Published figures leave `SOURCE_SUSPECT` rows out
(session 102 ruling).

| Bucket | Before (session 108) | After (session 109) |
|---|---|---|
| NAMED_HOSPITAL | 1,774 / $1,646,229,714.56 / 35 states | **1,833 / $1,728,683,683.70 / 36 states** |
| ... of which California | — | **58 / $82,353,969.14** (intents) |
| ... excluding California | 1,774 / $1,646,229,714.56 | 1,775 / $1,646,329,714.56 (+ MS Magnolia EMS $100,000) |
| POOL_NAMED_HOSPITALS | 8 / $86,555,171.43 | 8 / $86,555,171.43 |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | 5 / $69,323,109.17 |

- **Internal figure** (SOURCE_SUSPECT rows in): 1,777 / $1,650,195,072.06 becomes 1,836 / $1,732,649,041.20.
- **Rural cut** (`R/03ar`): 518 / $500,658,034.24 becomes **549 / $546,723,534.18**. All 31 added rows are
  California's, each on a CMS CAH CCN ($46,065,499.94). Magnolia Regional (250009) is not a CAH.
- **What California's figure is.** Every CA row is a TENTATIVE recommendation, not an executed award. Inside the
  $82.35M: LOW 10 / $13,345,062.19, and GENERAL_KNOWLEDGE $3,212,830 (Adventist Health System/West $1,592,830,
  NorthBay Healthcare Corporation $1,000,000, Banner Health Foundation $620,000). Both can be subtracted.

## Task 1: California (`R/03cl`, new)

**Source.** HCAI, "Recommended Subrecipients for CalRHT Budget Period 1 Announced", 2026-10-21. It was archived
by R/03ab on 10-26 (`data/evidence/CA/2026-10-26_…RECOMMENDED_SUBRECIPIENTS.html`). Re-read live on 10-28, the
five tables carry the same 108 rows and figures.

| Table (page order) | Initiative | Rows | Printed | Hospital rows / $ |
|---|---|---:|---:|---|
| Accelerator Partner Program | Transformative Care Model | 19 | $37,606,550.15 | 11 / $19,736,269.14 |
| FM-OB Fellowship Program | Transformative Care Model | 4 | $1,729,103.00 | 2 / $941,210.00 |
| Transformative Payments | Transformative Care Model | 11 | $34,999,996.00 | 11 / $34,999,996.00 |
| WDRR | Workforce Development | 65 | $54,169,999.00 | 28 / $18,776,315.00 |
| EHR Modernization | Technology and Tools | 9 | $9,958,395.82 | 6 / $7,900,179.00 |
| **Total** | | **108** | **$138,464,043.97** | **58 / $82,353,969.14** |

**Intents, in HCAI's words.** The page says "The awards listed on this page are tentative", "Inclusion on this
list does not constitute a final grant award", and that amounts "may differ from the final amounts disbursed".
Every row is coded `NOTICE_OF_INTENT_TO_AWARD`, `amount_confirmed = No` and `AMOUNT_PRELIMINARY`, which is
Texas's posture.

**The prose figure is recorded beside the rows and not forced onto them.** The grant counts reconcile; the
dollars do not:

| Initiative | Prose | Printed rows | Gap |
|---|---:|---:|---:|
| Transformative Care Model (34 grants) | $87.51M | $74,335,649.15 | ~$13.17M |
| Workforce Development (65 grants) | $67.56M | $54,169,999.00 | ~$13.39M |
| Technology and Tools (9 grants) | $11.65M | $9,958,395.82 | ~$1.69M |
| **Total (108 organisations)** | **$166.72M** | **$138,464,043.97** | **~$28.26M** |

HCAI says only that the list "does not yet represent all Budget Period 1 investments included in the initiative
totals above" and that "One applicant ... has subsequently withdrawn". The TCM prose's "milestone-based hospital
investments and clinical training partnerships" may account for some of the gap, but HCAI does not say so.
Nothing is imputed.

**Typing on CMS CA enrolment.** Hospital, FQHC and RHC files were fetched this session to
`federal_records/2026-10-28/` (551, 1,523 and 262 records; manifest with SHA-256).
- Exact organisation name or DBA, MEDIUM: 46 hospital rows.
- Hand-read bridges, LOW:
  - Mee Memorial Healthcare System → CAH 051336, ×3
  - Salinas Valley Memorial Hospital → 050334
  - Kaweah Health → 050057
  - Sierra Nevada Memorial Hospital Foundation, a named hospital's own foundation → 050150
  - Jerod Phelps Community Hospital, Southern Humboldt Community Clinic → CAH 051309, one legal entity
- Good Samaritan Hospital, LP: two enrolled entities normalise to this string. The page's string is the
  Bakersfield entity's DBA, literally, and its county is Kern, so the row goes to 050257 at MEDIUM.
- System parents and a system's foundation, LOW, GENERAL_KNOWLEDGE: Adventist Health System/West, NorthBay
  Healthcare Corporation, Banner Health Foundation (Lassen County, where Banner runs CAH 051320; no CCN on the
  row).
- **Not hospital rows** (each one-directional, and queued):
  - "UC San Diego Health" and "Southern California Rural Health Collaborative – University of California, San
    Diego" ($6,712,736). CMS enrols UCSD's hospital under the Regents, and neither string names that legal
    entity. They are coded UNIVERSITY_OR_AHC; queue item `CA_UCSD_STRINGS_NO_ENROLLED_ENTITY`.
  - Providence Medical Foundation ($450,000). It is a California medical foundation under H&S Code §1206(l), a
    clinic organisation rather than a fundraising arm, and is coded OTHER; queue item
    `CA_PROVIDENCE_MEDICAL_FOUNDATION`.
- Inland Empire Health Plan is coded MANAGED_CARE_ORGANIZATION (LOW, general knowledge).
- Sequoia Family Medical Center, SAC Health System, Apex, Stallant and Fortuna are coded FQHC/RHC on their
  enrolments, although the classifier read some of them as hospitals.

**Wiring.**
- `ca_year1_awardees.csv` is in STATE_FILES and in R/03aw, where CA is PARTIAL.
- The "no award file" assertion in R/03ab is deleted, as it asked to be. Only the no-amount rule for the status
  table remains.
- In the status table, the four pools and a new Transformative Payments row read RECOMMENDED_ROSTER_PUBLISHED.
  A Tribal Set-Aside row reads OPEN (Tier 2; the $11.65M sits inside the initiative figures).
- The survey reads CA EXTRACTED: 42 / 4 / 1 / 3. The rebuild of the survey and trigger queue also picked up the
  CMS-monitor rows (FL, NE, MD, NH, WY) that the CMS Routine had already committed.

**Probe re-based to 10-28 copies, after reading each diff.** The live probe at 13:30Z read all four pages
CHANGED, with the roster pin intact and no new name.

| Page | What changed |
|---|---|
| All four | HCAI's mega-menu data column (furniture) |
| `funding` | The Tribal Set-Aside Grant Guide and RFA are no longer "Coming Soon", and a Submittable "Application Portal" (`calrht-bp1-tribal-set-aside`) is posted. Tier 2, OPEN. |
| `calrht` | An "Explore CalRHT" block, and RHPC Meeting #2 (10-27) |
| `updates` | Menu only |

The 10-26 copies stay on disk. The extractor reads the 10-26 roster copy. The roster pin (108 /
$138,464,043.97) is unchanged.

## Task 2: rulings

| | Ruling | What was done | $ effect |
|---|---|---|---|
| (a) | ID Lifeways | Confirmed. CMS ID Hospital Enrollment: LIFEWAYS INC dba LIFEWAYS HOSPITAL, CCN 134009, SUBGROUP - PSYCHIATRIC "Y". It stays HOSPITAL_OR_SYSTEM, and the ruling is recorded on the row. | $0 |
| (b) | ID networks and PCG | The only sources are the list's lines (for example "Subrecipient \| Healthcare Infrastructure Support \| The Hospital Cooperative \| 1518287"; "Hospital Network of Idaho" ×3) and the funding page's "CLOSED 9/18/26: Healthcare Infrastructure Support". **Neither says the money goes to member hospitals**, so all four network rows stay Unclear. For PCG, the About page's "Ladder payments based on priority positions and rural presence" does not restrict payees to hospitals, so PCG stays Unclear. Each quote is on its row. | $0 |
| (c) | MS Magnolia Regional Health Center EMS | Typed to MAGNOLIA REGIONAL HEALTH CENTER (CCN 250009; exact legal-entity half), MEDIUM. **The distinction is recorded:** the WVU Eye Institute ruling covers a *university's* unit, whose legal entity is not an enrolled hospital; this unit's legal entity is the enrolled hospital. No department-name rule was added. | +1 / +$100,000 |
| (d) | MS "Memorial Health System" | **NOT APPLIED.** The ruling assumed an exact enrolment match. None of the six CMS MS files (hospital, FQHC, RHC, HHA, hospice, SNF) carries the string. Round 1 holds 12 rows / $15,041,222, MEDIUM on the name; round 2 holds 1 row / $219,120, LOW system parent. Queued as `MS_MEMORIAL_HEALTH_SYSTEM_RULING_PREMISE`. | $0 (confidence only, either way) |
| (e) | VT Gifford | Confirmed and closed: the latest list governs, and the agreement is the FQHC's. Recorded on `vt_year1_status.csv`. The award file is byte-identical. | $0 |
| (f) | VA Regional Collaboratives | Five added at $0, each with the NSVRC row's coding: NONPROFIT_CBO fallback, PASS_THROUGH_UNRESOLVED, Unclear, ELIGIBILITY_NOT_RECEIPT. VA goes from 11 rows to 16. The source is rhtva's Ways to Apply table (10-26), asserted to show five collaboratives with Open RFAs. | $0 |

## Task 3: check-in

The Thu 10-29 14:30Z check-in (`trig_014ALqpHqrs3SYKQRvN7HFA4`, delivered into session 108's session) **has
not run**; this session ran 10-28. On `main`:

| Successor Routine | First firing | Logged on `main`? |
|---|---|---|
| VA `trig_01BUzx8…` | 10-27 10:21Z | Yes |
| WA `trig_0158cE6…` | Thu 10-29 10:10Z | Not yet |
| SD `trig_01F8Bh6…` | Thu 10-29 12:20Z | Not yet |

No Routine was deleted.

## Merge timing

Merge before **Sat 10-31 17:00Z** (CA's next firing after today's). Never merge Mon/Thu 13:00–14:00Z. Until this
branch merges, `main`'s CA probe reads the 10-26 baselines and will trip on the menu change already read.

## Suite

`Rscript tests/run_tests.R` on `0069d3e`: **0 failures**. One standing skip remains (test_00's first-run branch).
The first full run, before `0069d3e`, failed four expectations, each a pin this session's changes moved: the VA
disposition CSV (11 → 16 rows), the survey split (41/5 → 42/4), and VA's ways-to-apply test (the five
collaboratives are now in the file). All four were fixed by rebuilding the disposition or updating the pin.

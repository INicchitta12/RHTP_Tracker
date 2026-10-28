# Session 109 — California extracted (intents); session 108's rulings applied

2026-10-28. Branch `claude/california-extraction-rulings-jm9m8v`, started from `main` at `950e8ba`
(session 108, PR #111, merged). No Year 2 work was done. No CMS release read this session announces
FY2027 amounts.

## Hospital partition, before and after

The three buckets are never added together. Published figures leave `SOURCE_SUSPECT` rows out
(session 102 ruling).

| Bucket | Before (session 108) | After (session 109) | California alone |
|---|---|---|---|
| NAMED_HOSPITAL | 1,774 / $1,646,229,714.56 / 35 states | **1,834 / $1,729,133,683.70 / 36 states** | **59 / $82,803,969.14 (INTENTS)** |
| POOL_NAMED_HOSPITALS | 8 / $86,555,171.43 | 8 / $86,555,171.43 | 0 |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | 5 / $69,323,109.17 | 0 |

- **What moved NAMED_HOSPITAL.** There are two sources, +60 rows / +$82,903,969.14 in all:
  - California: 59 / $82,803,969.14.
  - MS round 2, ruling (c): Magnolia Regional Health Center EMS, 1 / $100,000.
  - Without California the figure is 1,775 / $1,646,329,714.56 / 35.
- **Internal figure** (SOURCE_SUSPECT rows included): 1,777 / $1,650,195,072.06 becomes 1,837 / $1,733,099,041.20.
- **Rural cut** (`R/03ar`): 518 / $500,658,034.24 becomes **549 / $546,723,534.18**. All of the change is California: 31 rows / $46,065,499.94 on CAH or REH CCNs. Magnolia Regional (250009) is not a CAH.
- **Moved in confidence only, $0** (ruling d): MS round 1's twelve "Memorial Health System" rows, $15,041,222, are now LOW / GENERAL_KNOWLEDGE. They join the subtractable slices.

**California's figure is not like-for-like with most states.**
- **Every California row is an intent.** HCAI calls the list "tentative" and says "Inclusion on this list does not constitute a final grant award". Arkansas round 1 and most of Texas are intents in the same way; Florida and Georgia are complete, awarded years.
- **Subtractable inside California's $82.8M:**
  - LOW: 14 rows / $20,093,267.19.
  - Of the LOW rows, system parents and hospital foundations (GENERAL_KNOWLEDGE): 5 rows / $4,371,050.53.
  - The rest of the LOW rows are hand-read enrolment bridges.

## Task 1: California, `R/03cl` (new)

### What the rows are: INTENTS

The source is HCAI's "Recommended Subrecipients for CalRHT Budget Period 1 Announced", dated 10-21, on the CalRHT Program Updates page. It was archived on 10-26 (session 108) and again on 10-28. The rows of the two copies are identical to the cent, and `car_assert_roster()` asserts it.

The page's own words:
- "The awards listed on this page are tentative."
- "Funding amounts shown reflect the amounts offered to potential subrecipients and may differ from the final amounts disbursed."
- "Inclusion on this list does not constitute a final grant award."

The coding follows: `validation_source_type = NOTICE_OF_INTENT_TO_AWARD`, `amount_confirmed = No`, and `AMOUNT_PRELIMINARY` on every row. This is Texas's and Arkansas's intent coding.

### The roster

| Grant (HCAI's heading) | Initiative | Rows | Printed | Hospital rows / $ |
|---|---|---:|---:|---|
| Accelerator Partner Program | Transformative Care Model | 19 | $37,606,550.15 | 11 / $19,736,269.14 |
| FM-OB Fellowship Program | Transformative Care Model (described "under Expand and Support Rural Workforce Capacity") | 4 | $1,729,103.00 | 2 / $941,210.00 |
| Transformative Payments | Transformative Care Model | 11 | $34,999,996.00 | 11 / $34,999,996.00 |
| WDRR | Workforce Development | 65 | $54,169,999.00 | 29 / $19,226,315.00 |
| EHR Modernization | Technology and Tools | 9 | $9,958,395.82 | 6 / $7,900,179.00 |
| **Total** | | **108** | **$138,464,043.97** | **59 / $82,803,969.14** |

**Transformative Payments is a fifth grant.** No published guide described it. HCAI calls it "conditional, milestone-based investments to support hospital participation in feasible components of the TCM". Every one of its eleven rows is a hospital or hospital district.

### The total is NOT reconciled, and is not forced (owner instruction)

HCAI's prose says "$166.72 million ... for 108 organizations", against **$138,464,043.97** printed. The gap is **$28,255,956.03**.

| Initiative | HCAI's prose | Rows | Rows sum | Gap |
|---|---|---:|---:|---:|
| Transformative Care Model | "Approximately $87.51 million supporting 34 recommended grants" | 34 | $74,335,649.15 | $13,174,350.85 |
| Workforce Development | "Approximately $67.56 million supporting 65 recommended grants" | 65 | $54,169,999.00 | $13,390,001.00 |
| Technology and Tools | "Approximately $11.65 million supporting 9 recommended grants" | 9 | $9,958,395.82 | $1,691,604.18 |

**The row counts match HCAI's grant counts exactly, initiative by initiative, and the dollars do not.** So the gap is not a set of missing grants on the published list.

Two of HCAI's sentences are the only explanations on offer:
- The list "does not yet represent all Budget Period 1 investments included in the initiative totals above".
- TCM's prose adds "along with milestone-based hospital investments and clinical training partnerships".

Neither explains the Workforce gap on its face. The gap is recorded in three places: every row's `amount_basis`, a status row (`UNRECONCILED_NOT_FORCED`), and `year1_completion_status.csv`. Nothing is imputed to any recipient.

**One row may be withdrawn.** HCAI also says "One applicant that was recommended to receive an award has subsequently withdrawn their application", without naming it. Every row is carried as printed.

### Typing on CMS CA enrolment (`federal_records/2026-10-28/`, manifest written)

- **The CMS files.** Hospital, FQHC and RHC Enrollments for California, plus Provider Data Catalog Hospital General Information. They are committed as served.
- **Exact matches: 45 hospital rows / $62,710,701.95, MEDIUM.** Each is an ORGANIZATION NAME or DBA after normalisation. Where the match is on a DBA, the CCN is that DBA's own record, which matters where one legal entity holds many hospitals (Dignity Health). Examples:
  - Mercy Medical Center Mt. Shasta: 051319.
  - St. Elizabeth Community Hospital: 050042.
  - Adventist Health Sonora: the DBA is held only on sub-unit record 05U335, so the CCN is the legal entity's own record, 050335.
- **A name that matches two legal entities stops the build** and must be hand-read. "Good Samaritan Hospital, LP" is the Bakersfield DBA (050257). Normalised, the same string also equals the San Jose legal name, but the row serves Kern County.
- **Hand-read bridges, LOW:**
  - Mee Memorial Healthcare System (×3; 051336)
  - Salinas Valley Memorial Hospital (050334)
  - Kaweah Health (050057)
  - San Benito Healthcare District/Hazel Hawkins (051337)
  - San Bernardino County, Arrowhead Regional Medical Center (050245; the county is the enrolled operator)
  - Jerod [sic] Phelps Community Hospital, Southern Humboldt Community Clinic (051309; two DBAs of one district)
  - Mercy Medical Center – Northern California Maternity Collaborative (a Dignity Health "Mercy Medical Center"; Redding or Mt Shasta, so no CCN)
- **System parents and hospital foundations, LOW, GENERAL_KNOWLEDGE, no CCN (subtractable):**
  - Adventist Health System/West: $1,592,830.
  - NorthBay Healthcare Corporation: $1,000,000.
  - Banner Health Foundation: $620,000.
  - Sierra Nevada Memorial Hospital Foundation: $708,220.53.
  - Providence Medical Foundation: $450,000 (queued, below).
- **Kept out of the hospital figure:**
  - UC San Diego Health and the Southern California Rural Health Collaborative – UC San Diego. $6,712,736 together. Neither string names the Regents; queued.
  - Inland Empire Health Plan, an MCO.
  - FQHC and RHC records that win over hospital-shaped names: SAC Health System, Sequoia Family Medical Center (an RHC), and San Benito Health Foundation (an FQHC, not a hospital's foundation).
  - "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics". It names a programme, not an organisation; §8 fallback, queued.

### Status, survey, probe

- **Status table.** `ca_year1_status.csv`: the four pools move from NOTICES_SENT_PRIVATELY to `RECOMMENDED_PUBLISHED_TENTATIVE`, with `publishes_roster` "Yes -- tentative (intents)". Two rows are added: Transformative Payments and the unreconciled gap. The session-88 FAQ is still asserted.
- **Status.** California is EXTRACTED (survey 42/4/1/3) and Year 1 PARTIAL.
- **R/03ab's award-file assertion.** It now requires the file to be R/03cl's (Connecticut's session-54 shape), and `R/03ab --build` writes it.
- **Probe re-based** to 10-28 copies after reading each diff:
  - All four pages: HCAI's mega-menu swapped "Post CABG Readmissions and Complications" for "HPD Primary Care Utilization Report".
  - `funding`: the FM-OB block gained an "Application Portal" link (a solicitation, Tier 2), and three "Coming Soon!" labels collapsed into one.
  - `calrht`: an "Explore CalRHT" navigation block.
  - No new name anywhere. The live probe after the re-base reads UNCHANGED.
- **What still trips the probe.** It watches the roster pin (108 / $138,464,043.97); HCAI says the list "will be updated weekly as subrecipient agreements are executed". The footer, $233,639,308.46 at 100 percent CMS, is the allotment (Tier 1).

## Task 2: rulings applied

**(a) ID Lifeways ($163,500): unchanged, now on the ruling.**
- CMS ID Hospital Enrollment carries LIFEWAYS INC dba LIFEWAYS HOSPITAL (134009, Boise), LOCATION OTHER TYPE TEXT "FREE STANDING PSYCHIATRIC HOSPITAL", SUBGROUP - PSYCHIATRIC "Y".
- The ruling's condition holds, so HOSPITAL_OR_SYSTEM (MEDIUM) stands. A hand entry in `R/03ck` records it.

**(b) ID $18,353,321: stays Unclear.**
- **The source sentence.** The only source for the two hospital networks is the list line itself: Type "Subrecipient", Solicitation "Healthcare Infrastructure Support", the name and an Amount. It says nothing of member hospitals.
- **The HIS FAQ** (archived `recheck/2026-10-28/ID/`) says only that "An applicant must fall within an eligible applicant type" (Sections 2.1–2.3). It contemplates non-hospital applicants ("Could a generator at a retail WIC site be eligible under HIS?"). That is not ICAHN's hospitals-only class.
- **PCG.** DHW's own description is "Ladder payments based on priority positions and rural presence", which ties the payments to positions, not hospitals. The TPA RFP is on Idaho's Infor supplier portal, which serves an empty JavaScript shell, so it is UNREADABLE (recorded UNKNOWN). Nothing says hospitals-only.
- **No figure moved.**

**(c) MS Magnolia Regional Health Center EMS ($100,000): now a hospital row.**
- HOSPITAL_OR_SYSTEM on MAGNOLIA REGIONAL HEALTH CENTER (250009), LOW: the string adds "EMS" to the exact legal name.
- **The distinction is recorded on the row.** The WVU Eye Institute precedent covers university units: there the unit was named under a university, which is not itself an enrolled hospital. Here the department is named under the hospital's own legal name.

**(d) MS "Memorial Health System": the ruling's premise does not hold.**
- **No exact enrolment match exists.** No CMS MS Hospital, FQHC, RHC, HHA, hospice or SNF file carries "Memorial Health System" as an ORGANIZATION NAME or DBA. So the ruling's example ("an exact enrolment match → MEDIUM in both") does not arise.
- **The stronger evidence is round 2's system-parent reading** (parent of MEMORIAL HOSPITAL AT GULFPORT, 250019), not round 1's MEDIUM on the name alone. Both rounds now read LOW / GENERAL_KNOWLEDGE.
- **Round 1:** 12 rows, $15,041,222. $0 moved.
- **How it is applied.** `R/03cj --apply-r1` keys on the awardee string, and `R/03cj --validate` fails if an R/03ak rebuild wipes it. CLAUDE.md's overlay rules carry the step.
- **If you meant MEDIUM in both regardless, say so.** It is a one-line change.

**(e) VT Gifford: the latest list governs. Confirmed and closed** on the status row. $0 moved.

**(f) VA's five Regional Collaboratives: added at $0, rows 12–16 of `va_year1_awardees.csv`.**
- **Typing.** The state's Ways to Apply table links each to a planning district commission's own RFA page, all archived in `data/evidence/VA/collaboratives/`:
  - SWVA: LENOWISCO.
  - Roanoke-Alleghany/Central Shenandoah/New River Valley: Central Shenandoah PDC's site.
  - Northern Piedmont: Thomas Jefferson PDC.
  - Southside: West Piedmont PDC.
  - Eastern Shore: Accomack-Northampton PDC.
- **What each page says.** Each says the collaborative or PDC "will competitively award funding to eligible organizations". So each row is LOCAL_GOVT_OR_PUBLIC_HEALTH, PASS_THROUGH_UNRESOLVED, Unclear, ELIGIBILITY_NOT_RECEIPT, LOW. This is NSVRC's typing.

## Task 3: check-in result

**The Thu 10-29 14:30Z check-in (`trig_014ALqpHqrs3SYKQRvN7HFA4`) has not run;** this session ran on 10-28. Nothing was deleted.
- **VA.** The successor (`trig_01BUzx8AnvNR9kVkYKkfovDe`) has already logged on `main` (10-27 10:21Z).
- **WA and SD.** Their successors first fire 10-29 at 10:10Z and 12:20Z, before the check-in.

**VA's 10-27 line logged `ways_to_apply` CHANGED, and it was read.** Three Tier 2 RFAs went Open → Closed (Earn to Learn, Career Pipelines, Food is Medicine). The five collaboratives are unchanged. It was not re-based, so the VA Routine will log CHANGED until a human does.

## Owner questions this session opens

| Question | Coded as | One-way effect |
|---|---|---|
| `CA_UCSD_STRINGS_NO_ENROLLED_ENTITY` | UNIVERSITY_OR_AHC, not hospital | +$6,712,736 (or +$498,854 for "UC San Diego Health" only) |
| `CA_PROVIDENCE_MEDICAL_FOUNDATION_FORM` | foundation row → hospital, LOW (a CA medical foundation operates clinics; not a fundraising arm) | −$450,000 |
| `CA_FM_OB_FRESNO_SPONSOR_NOT_NAMED` | §8 fallback, not hospital | +$289,039 |
| CA's $28,255,956.03 gap | recorded, not imputed | — |
| Ruling (d) as applied | LOW in both rounds (no exact match exists) | $0 |

## Vulnerabilities a reviewer will press on

- **California's $82.8M is offered money, not executed agreements.** HCAI may "modify or withdraw a tentative award before execution". One applicant has already withdrawn, and HCAI has not named it.
- **The $28.3M gap is roughly a fifth of HCAI's own total.** Any statement of California's hospital share must use the printed rows and say the rest is unpublished. It must not scale the rows up to $166.72M.
- **Transformative Payments ($35.0M) is conditional and milestone-based.** It is 42% of California's hospital figure.

## Other things this session touched

- **`year1_completion_status.csv` was stale** for VT, TX, WV, OH and ID: session 108 did not rebuild it. This session's rebuild caught it up. The four COMPLETE states' share table did not move.
- **The survey and trigger-queue rebuild** also picked up CMS newsroom flags already committed by the monitor (FL 10-23, MD 10-19, NH 10-16, WY 10-23).
- **`federal_records/2026-10-26/` had no MANIFEST.** One is written; the URLs follow this project's pattern and say so.
- **Pins carried forward:** the partition-history chains in `test_03ap` and `test_03bj`, the rural cut in `test_03ar`, the survey split in `test_03k`, and `test_state_union`. New test file: `test_03cl_ca_bp1_awardees.R`.

## Suite

See the commit that records the full-suite result.

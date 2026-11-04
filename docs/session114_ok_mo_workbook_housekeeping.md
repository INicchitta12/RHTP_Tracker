# Session 114 (2026-11-04): Oklahoma rulings, Missouri intents, workbook refresh, housekeeping

Deliverable: `output/year1_summary_2026-11-04.xlsx` and `data/reference/year1_summary_2026-11-04.csv`
(R/08, built after every extraction, overlay and `R/07 --apply`). The 11-02 files are untouched.

## 1. Headline change from the 11-02 build

| Measure | 11-02 | 11-04 | Change |
|---|---:|---:|---:|
| Hospital best estimate | $2,034,862,538.90 | $2,071,184,871.63 | +$36,322,332.73 |
| — CODED | $1,821,345,454.64 | $1,853,207,624.44 | +$31,862,169.80 (MO) |
| — BEST_JUDGMENT | $213,517,084.26 | $217,977,247.19 | +$4,460,162.93 (OK CHW pool) |
| Strict NAMED_HOSPITAL | 1,908 / $1,761,827,518.82 / 37 | 1,951 / $1,793,689,688.62 / 37 | +43 rows / +$31,862,169.80 |
| POOL_NAMED / POOL_UNNAMED | $86,895,779.43 / $79,214,848.17 | unchanged | 0 |
| Awards published | $4,512,205,898.91 | $4,556,066,882.39 | +$43,860,983.48 |
| % of allotment published | 45.1% | 45.6% | |
| Hospital % of allotment | 20.3% | 20.7% | |
| Intents in hospital best estimate | $771,152,504.37 | $794,748,913.54 | +$23,596,409.17 (MO) |
| Strict rural cut | $559,285,398.43 | $566,590,756.19 | +$7,305,357.76 (MO's four CAHs) |
| Named hospitals with no amount | 269 | 298 | +29 (OK CHW) |

By state, only two moved:
- **MO** +$31,862,169.80 (coded, strict).
- **OK** +$4,460,162.93 (best judgment, pool).

**Subset row (`US_GE50`) unchanged, n = 23:**

| Measure | Value |
|---|---:|
| Allotment | $4,673,429,957 |
| Awards | $3,728,812,818.21 |
| Hospital best estimate | $1,612,024,736.82 (43.2% of awards, 34.5% of allotment) |
| Strict named | $1,507,090,381.12 |

Neither moving state qualifies for the subset: MO is now 37.6% of allotment and OK 32.1%.

## 2. Task 1: Oklahoma

**(a) CHW Expansion (owner ruling).** `R/03co` writes `ok_year1_chw_awardees.csv` from the archived fragment
(`recheck/2026-11-02/OK/fragments/community-health-worker-expansion.html`): 48 rows, all at no amount.

- **29 hospital rows.** Typed on CMS OK Hospital Enrollments (`federal_records/2026-09-25`): 4 exact legal names
  (MEDIUM), the rest DBA or short-form bridges (LOW). Each is DIRECT, with OHA in `intermediary_name`, and
  NAMED_HOSPITAL at $0 (Ohio's 22-hospital precedent).
  - Two lines name two legal bodies each and stay one row, MULTI_RECIPIENT_FIELD: Beaver County/Harper County and
    Mercy Kingfisher/Watonga.
  - Stillwater Blackwell/Perry is one authority's two REHs.
- **AVEM Health Partners is NOT typed a hospital.** OSDH prints it under "Hospitals receiving CHWs", but no CMS
  hospital enrolment carries it. On general knowledge it is a rural-hospital management company.
  - Coding: HOSPITAL_AFFILIATED_ENTITY, PASS_THROUGH_UNRESOLVED, Unclear.
  - The summary layer calls it HOSPITAL (written judgment, owner's count of 30).
  - **Owner question.** $0 rides on it either way.
- **18 FQHC rows**, NON_HOSPITAL, on the page's own statement "Funded 25 CHWs in 18 FQHCs". Two are out of state:
  CHC of Southeast Kansas and Community Clinic NWA.
- **The pool.** $4,460,162.93 is the Q3 Legislative Quarterly Report's "Current Obligated" to the Foundation for a
  Healthy Oklahoma (OHA). The Y1 budget allocation is $4,605,788.00.
  - It is one R/07 `SC_POOLS` entry (`OK_CHW_EXPANSION`), on no row, and in **no strict bucket**.
  - Called HOSPITAL: **29 of 48 typed members, a strict majority** (owner's 30 of 48 gives the same call).
  - The counter is recorded on the review list. Q3 also says OHA "provided 30 hospitals and 18 FQHCs with 55
    community health workers", which reads as CHWs placed in kind, not dollars paid.
- `cms_enrolment_match` is left empty, so R/03bj's overlay does not claim the rows. The CCN and the enrolment record
  are on each row.

**(b) EMS/CP vehicles: 13 is right; no file change.** The fragment itself says:
> Four vehicles were funded out of the NOFO funding; Nine were funded out of a separate funding opportunity reserved
> for teams trained by RHTP funds.

- Q3's "four community paramedicine vehicle awards" counts the NOFO round only.
- The NOFO four are Elk City FD, Purcell, Tonkawa FD and Oologah-Talala.
- The other nine are the eight asterisked teams plus Choctaw County Ambulance Authority, which received training.
- The ambulance list prints "Town of Cheyenne" twice. Its 37 lines match Q3's "37 ambulance awards".

**(c) Lung screening: 8 vs 9 reconciles exactly; no file change.**
- The fragment carries 8 finalized lines. They cover **9 hospitals**, because Jackson County Memorial and Harmon
  Memorial are one authority on one line.
  - That is Q3's "eight hospitals subcontracted" (subcontracts) and "contracted with nine hospital sites" (sites).
- Its three "*Contract not finalized" lines cover 4 + 3 + 1 = **8 hospitals**, which is Q3's "eight additional sites in
  progress".

**(d) LifeCare Provider Collaborative watch.**
- **What it watches.** `R/03t --probe` now runs `ok_lifecare_findings()` on the live Provider Collaborative fragment.
  Its archived recipients line is "Hospital recruitment in progress.".
- **What trips it:**
  - any other text after "Provider Collaborative Funding Recipients:", with or without an organisation suffix;
  - a missing label;
  - the fragment leaving the dropdown.
- **Tests.** The archive self-checks, so a reader change fails loudly. Tests in `test_03t` cover each case.

## 3. Task 2: Missouri Smart Growth contingent roster (owner ruling)

`R/03cq_mo_smart_growth_awardees.R` (new) writes `mo_smart_growth_awardees.csv`.

**Source.** DSS's "RHTP Modernize Rural Healthcare Services" table, archived `data/evidence/MO/2026-11-04_dss_smart_
growth_contingent_roster.html`. It is content-identical to session 112's 11-02 read.

**What the file holds:**
- 25 rows, $39,400,820.55, equal to the printed Total.
- **23 intents** (NOTICE_OF_INTENT_TO_AWARD, AMOUNT_PRELIMINARY) on the release's condition: "All contingent awards
  have to be approved by the Centers for Medicare and Medicaid Services before a final award can be made".
- **2 marked "(approved by CMS)"**: Missouri Delta Medical Center $3,265,760.63 and Heartland Regional Medical Center
  $5,000,000.00. They are NOTICE_OF_AWARD; the `cms_approval` column records which rows are which.
- **26 vs 25.** The page and release say "26 rural providers" and the table lists 25. Recorded in every row's note;
  no row is imputed.

**Typing**, on CMS MO Hospital/FQHC/RHC Enrollments fetched today (`federal_records/2026-11-04/`, manifest):

| Group | Rows | Dollars | Typing |
|---|---:|---:|---|
| Hospitals | 14 | $31,862,169.80 | 9 exact legal names MEDIUM; Hermann, Lake Regional, Nevada and Scotland LOW bridges |
| — of which CAHs | 4 | $7,305,357.76 | Hermann, Mercy Perry, Scotland, Washington County |
| FQHCs | 6 | | Arthur Center, Big Springs, Compass, Four Rivers, Katy Trail, Ozarks Resource Group |
| Standing fallback | 5 | | Centerstone, Gibson Center, Mark Twain BH, Ozark Center, Ozarks Community Hospital |

Two of the fallback rows carry written NOT_HOSPITAL judgments, each with its counter:
- **Ozarks Community Hospital** (Webb City), $787,430.36. "Hospital" is in its name but no Missouri enrolment of any
  kind carries it.
- **Ozark Center**, $1,466,432.37. On general knowledge it is Freeman Health System's behavioural-health affiliate,
  but neither DSS nor the name names Freeman.

**MO probe re-based (§2.2), after reading the 10-28 trips:**
- `program_page` gained the $39.4M news item and a Hub Workforce allocation. That allocation is Tier 2: "approximately
  $412,000" per Hub over two years, "contingent on CMS year 2 approval". It names nobody.
- `smrp_awardees` moved by **whitespace only**: one trailing space. Every name and amount parses identically.
- The probe now also watches `smart_growth`: any row, price, Total or "(approved by CMS)" change trips
  `mosg_assert_live()`.
- The interactive live run read **UNCHANGED on all five pages**. The SMRP rows keep the 10-15 archive as their source.

## 4. Task 3: CMS obligation report, 10-14 edition

`R/00d` and `R/03cb` read `cms_obligations_bp1_{lines,state}_20261014.csv`. The 10-08 files stay archived.

**Edition effect, isolated.** Rebuilding R/00d on the 10-08 lines against today's award files and diffing gives
exactly two changes:
- the ﬁ ligature spelling of seven DE/ME initiative names in `cms_obligation_hospital_purpose.csv`;
- Oregon's `cms_lines` count, 175 → 170.

**No lead, name match or decision-list row changes**, and NE/PA/RI's rows are identical apart from their provenance
(title, URL, archive path).

**A refresh this commit carries.** The committed match and gap tables were also stale against the award files: they
predated sessions 99–114, so they no longer saw the newer extractions. This commit refreshes them as well. That part
is an award-file effect, not an edition effect.

## 5. Task 4: Housekeeping

- **Maine.** `rhef`, `programme` and `mcd` were re-fetched in place (session 104's method). The programme page is
  identical to session 113's 11-03 read. Validate passes and the live probe reads UNCHANGED on all four pages.
- **`claude/festive-cori-sm3p3c`: NOT deleted.** It is an unmerged parallel session-109 CA extraction. Rows, amounts and
  the roster match main, but main lacks four things from it:
  1. `Legacy MD Medical Group, Inc.` ($1,182,017) typed PHYSICIAN_PRACTICE (main: NONPROFIT_CBO fallback).
  2. A `Tribal Set-Aside` channel row (stage OPEN) in `ca_year1_status.csv`. Main's eighth row is the BP1
     unreconciled row instead.
  3. Five extra CA columns: `cms_enrolment_match`, `county`, `initiative`, `row_in_pool`, `awardee_as_published`.
  4. Its script `R/03cl_ca_bp1_recommended_awardees.R` (main runs `R/03cl_ca_bp1_awardees.R`).

  Its other differences are typings main later settled by owner ruling (UC San Diego Health, Providence Medical
  Foundation) and older stage codes.
- **NY runner moved.**
  - New runner `session_01Y1P5eSC9YpvFBjW8fDzTZD`, Routine `trig_01Sjy49Y8ARShrgJJ3LjZvzq`, same cron (`10 11 * * 0,3`)
    and same configuration.
  - The prompt differs from the old one **only in the runner id** (three occurrences; diff after substitution is
    empty). `R/routine_prompts_worktree.R --check` matches for 43 states.
  - The old `trig_012g3adVBX9KEgDt9XiVi2tU` is disabled and chained in `routines.csv`. Coverage check passes.
  - **Note:** the old runner read 337,761 tokens today. It had auto-compacted since the 10-29 survey's 640,952, so the
    move was on the owner's instruction, not on today's reading.
- **11-04 14:30Z check-in** (`trig_01CC8FCXRQWXpRaAaQYPqT8Q`):
  - All six successors had logged on `main`.
  - **Deleted:** old KY `trig_01Jk2igfuAsju6aaCnT3bP28` and ND `trig_016DwLq1AKfmgKrFZtwPuPuK`.
  - **Refused by that session's permission classifier:** MS `trig_01Ugf2k1rcJiQVTtMhpnb4V3`, NM
    `trig_01EeEQZDPeG4xW4GBA7p8WcZ`, NE `trig_01WDA8s6uzUSaCDF7DapUzX1` and OH `trig_01VEe1KQEsuJRncwuoR8rQzJ`. All four
    are disabled and safe to delete by hand.
  - Its record is on `claude/gifted-gates-7c4i34`. Coverage there passed: 327 due, 7 explained.

## 6. Task 5: Workbook

- The Notes "INTENTS" line is now built by `ys_intent_states()`: every state with intents in the hospital best
  estimate, largest first, each with its figure. On 11-04 that is 14 states, Texas $192,064,837 first; Missouri enters
  at $23,596,409. A test checks the line against the table.
- `test_08` is re-pinned to 11-04. It adds a state-by-state decomposition of the change from 11-02 and leaves the
  subset row's pins as they were, since its figures did not move.
- CLAUDE.md's Deliverable 1 table gains `MO SG` and `OK CHW`. The partition block reads 1,951 / $1,793,689,688.62
  (internal with SOURCE_SUSPECT: 1,953 / $1,797,145,109.62).

## 7. Open for the owner

1. AVEM Health Partners: management company or hospital for the CHW count ($0 either way; the pool call does not
   change).
2. MO Ozarks Community Hospital ($787,430.36) and Ozark Center ($1,466,432.37): both called NOT; together that is
   +$2,253,862.73 to the best estimate if reversed.
3. MO's 26th provider.
4. Delete the four old MS, NM, NE and OH Routines, then record each in `old_deleted`.
5. `claude/festive-cori-sm3p3c`: port the four items above, or discard.
6. Merge before Sun 11-08 11:10Z (NY's first firing on its new runner). Never Mon/Thu 13:00–14:00Z.

## 8. Suite

Full suite on `93c13d6`: **12,436 expectations, 0 failures, 0 errors**. The first run failed on pinned partition and
rural-cut totals in `test_03ap`, `test_03ar`, `test_03bj` and `test_07`. Each moved by exactly this session's additions
(+43 NAMED rows / +$31,862,169.80; rural +$7,305,357.76; +$4,460,162.93 HOSPITAL pool), and each pin now carries a
session 114 step. Four warnings remain in `test_03bj`, from older files that carry `recipient_subtype` without
`cms_enrolment_match`; the two new files carry the column.

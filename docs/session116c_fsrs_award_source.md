# Sessions 116c and 116d: FSRS / FFATA subawards as an award source

**Dates:** 2026-11-09 (both). **Branch:** `claude/dreamy-meitner-q7x7ib`, cut from `main` at `5215cec` (session 116b merged).
**Owner ruling (116c):** a state's FFATA first-tier subaward report in FSRS/SAM.gov, republished by USAspending under
Assistance Listing 93.798, is an award source: the state's own federal filing of executed subawards. Source type
`FSRS_FFATA`, amount type award, budget period 1 unless the record shows otherwise.
**Owner rulings (116d):** (a)-(h) below.

## Headline figures

| | Before (pre-FSRS, `year1_summary_2026-11-09_pre_fsrs.csv`) | After (`year1_summary_2026-11-09.csv`) |
|---|---:|---:|
| Hospital best estimate | $2,075,115,137.63 | $2,473,382,310.89 |
| Strict NAMED_HOSPITAL | 1,958 / $1,797,619,954.62 / 37 states | 2,204 / $2,170,425,246.88 / 42 states |
| Strict POOL_NAMED / POOL_UNNAMED | $86,895,779.43 / $79,214,848.17 | unchanged |
| Awards published | $4,559,997,148.39 | $6,189,503,205.27 |
| National hospital % of awards | n/m (45.5% computed) | 40.0% (prints, ruling b) |
| Subset row (states >=50% published, state sources) | n = 23: best $1,612,024,736.82, strict $1,507,090,381.12, 43.2% | n = 32: best $2,133,741,090.93, strict $1,916,528,872.09, 41.2% |

Change by state (best estimate; strict in brackets where it differs): IA +$163,815,846 (strict +$163,082,841); MN
+$68,840,377; IL +$53,821,675; VA +$24,728,876 (strict $0); TN +$16,699,482; CT +$15,005,890; NC +$14,550,000;
NE +$12,987,780; ND +$8,751,589; WV +$6,083,596; KY +$4,348,529; DE +$3,291,276; VT +$2,000,000; KS +$1,950,110;
NV +$997,361; ME +$258,193; OK +$136,594. Award totals also move in HI, AZ, RI, NM, MT, TX
(no hospital dollars).

## What was built

| File | What it is |
|---|---|
| `R/09b_fsrs_award_source.R` | `--validate`, `--plan`, `--apply`, `--strip`, `--report`. The overlay and the new files |
| `R/09a_usaspending_rhtp.R --probe` | READ-ONLY weekly watch (116d): live file to a temp dir, 93.798 filter enforced, trips per state on report ids the archive lacks |
| `config/fsrs_name_crosswalk.csv` | 338 hand-reviewed recipients: 238 MATCH, 84 NO_MATCH, 16 HOLD |
| `data/reference/<st>_fsrs_awardees.csv` | 22 files, 691 rows: recipients in no award file and extra subawards (30) |
| `config/fsrs_subaward_pairings.csv` | 30 subaward-to-roster-row pairings from the independent check and its re-check |
| `data/reference/fsrs_subaward_records.csv` | all 2,025 records with `record_status` (CURRENT / REFILING_SUPERSEDED / PREDATES_NOA) |
| `fsrs_state_totals.csv`, `fsrs_nonfiling_states.csv` | per state count, total, % of allotment; the 19 non-filers as fact only |
| `fsrs_reconciliation.csv`, `fsrs_held.csv`, `fsrs_differs_over_100k.csv` | status of every current subaward; every hold; every DIFFERS over $100K |
| `fsrs_pool_reconciliation.csv`, `fsrs_ia_round_check.csv`, `fsrs_amendment_uncertain.csv` | rulings (c) and (d); the two uncertain keys |
| `data/evidence/federal_records/2026-11-09/` | CMS Hospital Enrollment for AZ HI KY MN NM SD (manifest with SHA-256) |

Overlay order (CLAUDE.md): `R/09b --apply` after every `--build` and every other overlay, before `R/07 --apply`.

## Task 1 (116c): reading the data

- 2,025 records, 31 states, $2,822,602,267.02. **Amendment rule** (CLAUDE.md §7): key (state, subaward number,
  UEI). Same action date + amount + description = one subaward filed twice: 9 records dropped (DE 1, SD 7, TN 1).
  Anything else under a key is a distinct action, amount per action, never cumulative. Evidence: Vermont's AHS list
  prices Brattleboro Memorial's two same-number records ($115,000 and $270,250, same date) as two lines. Two keys
  repeat a description at a new amount and stay uncertain (UT USBE $3,188,804 then $13,085,562; TN UNHS); neither is
  a hospital.
- **Date test:** Montana's eight $30,000 area-agency-on-aging records, action date 2023-07-01, described
  "III,VII,SHIP" (Older Americans Act titles and SHIP), predate the NOA and are held.
- **Allotment check:** 2,008 current subawards, $2,818,633,481.46; no state's FSRS total exceeds its allotment
  (Hawaii is closest at 100.0%: $188,861,170 of $188,892,440, nearly all to state agencies and the University).
- **19 non-filing states:** AL AR CA CO FL GA LA MA MD MI MO MS NH NJ NY PA SC WI WY.

## Task 2 (116c): reconciliation

Match on normalised name/DBA within the state, or a hand-reviewed crosswalk entry; never a machine fuzzy match.
(a) priced row: state amount kept, `fsrs_match` EXACT (497 subawards) or DIFFERS (176; 107 rows over $100K);
(b) $0 row: priced from FSRS (246 subawards); (c) no file: a new row typed on CMS enrolment (exact name MEDIUM; exact
street address + city LOW, 30 rows / $18.9M), else the name classifier, else SAM business types as carried on the
state's filing. A hospital-shaped name with no enrolment is never typed a hospital (the classifier read "Oklahoma
Health Care Authority" as a hospital authority). Iowa's subawards are paired only to rows in their own RFP pool.

**Guards against counting one subaward twice.** A $0 row inside a pool counted at pool level is not priced; new rows
in states whose files carry unnamed pool figures (IN OH OR SD WA) are held; Nevada's new rows are held (its BP1
report is complete: two "new" recipients were Mesa View and Northeastern Nevada under their operators' names).

**Review scope (owner):** every pair with a hospital or health system on either side, IA and NC first, then every
other pair over $100K: 338 recipients reviewed. 21 small non-hospital recipients (33 subawards, $5.86M) held unreviewed.

## Owner rulings (116d)

- **(a) VHHA Foundation, $27,201,764 (three subawards).** FSRS purpose text:
  - RPM ($14,837,326): "SUPPORTS RURAL HEALTH SYSTEMS IN DEPLOYING AND SCALING REMOTE PATIENT MONITORING AND
    HOSPITAL-TO-HOME TECHNOLOGIES".
  - GME ($9,891,550): "...RESOURCES NEEDED FOR HEALTH SYSTEMS TO RECRUIT, TRAIN, AND RETAIN PHYSICIANS."
  - Food is Medicine ($2,472,888): "SUBRECIPIENT SHALL ADMINISTER A COMPETITIVE PROCESS TO SELECT PILOT PROJECTS LED
    BY HEALTH SYSTEMS, RURAL HEALTH CARE PROVIDERS, COMMUNITY-BASED ORGANIZATIONS, OR PARTNERSHIPS AMONG THESE ENTITIES."
  The award as a whole is a mixed class, so the row is NOT_HOSPITAL (FHC precedent). Its two health-system-only
  subawards are HOSPITAL components ($24,728,876, session 105's per-component rule). Counter: "health systems" is
  not literally "hospitals".
- **(b)** National hospital % of awards prints (39.9%); the subset row stays the headline.
- **(c)** No pool's members reconcile within 1%: IN GROW regions -47% to +54% (Region 5 -10.4%), OK CHW -95.7%,
  SD CCBHC -37.8%; state-level unnamed pools IN -94.5%, OH -89.0%, OR +63.5%, SD -93.6%, WA +40.6%. All held.
- **(d)** Extra subawards: 33 written ($12.7M), typed as their roster row. Iowa: no RFP exceeds its published total
  (`fsrs_ia_round_check.csv`; the June notices print the allotment and publish no round total). Extras in Year 1
  COMPLETE states held (11, $54.1M): Utah's UDAF $26.5M and USBE $13.1M would have put Utah over its allotment.
- **(e)** NV: MMC of Nevada matched to Mesa View ($4,492,438 vs $4,492,438.45, DIFFERS). FLEX-28 SOURCE_SUSPECT
  cleared: FSRS pays exactly $997,361 to PHC-Elko, which operates Northeastern Nevada Regional Hospital; the BP1
  report's "Northern Nevada" is the name defect, not the amount.
- **(f)** Written SAM-listed hospitals with no CMS enrolment (16, $57.6M), each judged in `SC_FSRS_OVERRIDES`
  (strict unchanged): Sanford Medical Center (IA equipment, $733,005) HOSPITAL on its SD enrolment (CCN 430027);
  AZ DHS, OHCA (x9, now typed STATE_AGENCY from the UEI's own SAM types), Cherokee Health Systems, Perry County
  Medical Center, Saint Thomas Medical Partners (x3) NOT_HOSPITAL. State bodies with a hospital enrolment (TX DSHS,
  $20.4M) are STATE_AGENCY, NOT_HOSPITAL.
- **(g) Ten largest DIFFERS:** OHSU ($398,000 vs $50.3M: additional awards, incl. a $46.9M Office of Rural Health
  pass-through, held, a ruling); OUHSC ($5,445 vs $12.4M: additional, one $499,555 record is the telestroke row,
  now paired; the rest held); RI DOH, CTC-RI and HARI (CMS obligation lines vs executed subawards: different
  source and date, state amount kept); DE Westside ($11.3M vs $2.3M), ME UNE ($12M vs $5M), OR Klamath Basin
  ($4.79M vs $213K): different period (multi-year commitment vs first tranche), kept; FHO/OPQIC ($200,605 vs $7.0M:
  the FSRS lines are OK's CHW and lung pools, already counted, kept); University of Utah ($641,713 vs $7M: Talent
  Ready Utah, on the roster as USHE TRU at $4M, kept). No excess was added.
- **(h)** Hospital-involved ambiguous pairs resolved: TX Jackson and Refugio hospital districts (the roster prints
  the county; $750,000 each), NE Good Samaritan (exact), Valley County, Genoa, OK Baptist Healthcare (Grove),
  KS Stormont Vail Flint Hills, NV Banner Health Foundation. MN Sanford un-held (its HOLD was SD's). 20 pairs
  ($21.3M) stay held (county governments in IN, OR, VA state bodies, SD Sanford parent).

## Held (all in `fsrs_held.csv`, none counted)

Pool members $102.0M; state-pool new rows $90.4M; extras in COMPLETE states $54.1M; reviewed-ambiguous $21.3M;
NV complete-roster $10.0M; several-file $0-rows $7.2M; unreviewed $5.9M; pre-NOA $0.24M.

## Routine

`trig_01NcEJkGQZVkxSWcEd5rm538`, Tue 21:17Z, runner `session_01Y1P5ePyT1E4HK7tZNZiwpU`, `R/09a --probe`. First
firing 2026-11-10 21:17Z; it needs this branch on `main`. Its v4 prompt was written from AL's by hand (the
generator derives only from stored v3 prompts).

## Independent check (116d, Task 3)

A separate agent recomputed the build from the 94 award files and the raw zip without seeing how it was made.
- **Arithmetic: PASS.** The strict buckets, the best estimate and the 32-state subset row matched the committed CSV
  to the cent, with 0 per-state disagreements.
- **Double counting: FAILED on (d), now fixed.** 25 new FSRS rows were roster rows under another name, each with the
  same amount to the cent. Six were hospital rows ($4,789,900.24): Newton Healthcare = NMC Health (KS); Alegent
  Creighton = CHI Health Plainview (NE); Mercy Health System Okla = Mercy Health Oklahoma Communities; Carlos G. Otis
  HCC = Grace Cottage (VT, x2); "General Hospital", Iraan = Iraan Hospital District (TX). The rest are non-hospital
  ($11.1M of awards). All 25 are pinned in `config/fsrs_subaward_pairings.csv`, and R/09b now holds any new row whose
  non-round amount equals a roster row in its state; that guard caught one more, NE Alegent Creighton $711,629.63.
  Strict NAMED fell by exactly $4,789,900.24 (2,213 / $2,176,937,123.12 -> 2,207 / $2,172,147,222.88).
- **Re-check (fresh reads):** arithmetic, (a)-(c), (e) and summary calls PASS; the widened (d) found five more:
  TX Lockney General Hospital District = Lockney Gen Hosp ($750,000); TX Moore County Hospital District = Memorial
  Hospital (Dumas) ($750,000, and $221,976 vs $221,980.30, a $4.30 rounding gap, paired with `max_diff`); AK
  Anchorage Community Mental Health Services = Alaska Behavioral Health ($1,000,000); AK City of Nenana = Nenana
  Volunteer Fire/EMS ($50,000). Paired; strict NAMED 2,204 / $2,170,425,246.88 (-$1,721,976). Every Alaska and
  Utah "new" row was a roster row, so `ak_` and `ut_fsrs_awardees.csv` are gone. Left as read: OK Mercy Health
  System vs Fairview Regional ($100,000; Fairview's row carries its own subaward) and OK Wonderfully Made Therapy
  vs Works Wonderfully Foundation ($50,000; different bodies). Iowa's 467 round-amount pairs are formula awards to
  different hospitals.
- **(a)-(c), (e): PASS.** No subaward is priced twice or both priced and written new; no FSRS-priced row sits in a
  pool counted at pool level (NC MIH's 37 lines, $10,524,908, reach its $10M round); no state exceeds its allotment
  (HI 99.98%). Minor: nine `FSRS_PRICED_ON_ROW_n` labels point at rows that were not priced (pool members blocked
  after pairing); no dollar is affected.
- **15 FSRS-priced hospital rows against the zip: PASS** (IA, MN, IL, TN, CT, NC, ND); 13 multi-subaward rows round
  by $0.01-0.05.
- **Summary calls: PASS** on all rows.


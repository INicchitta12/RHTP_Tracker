# Session 115 — Probe log since 11-02, festive-cori carry-over, Routine cleanup (2026-11-09)

Branch `claude/intelligent-cannon-wc3lma`, started from `main` at `eba30ee` (session 114's
`claude/vigilant-bohr-qwphor` already merged, PR #121).

## Hospital figures, before and after

| Figure | 11-04 build (session 114) | 11-09 build (session 115) | Change |
|---|---:|---:|---:|
| Hospital best estimate (summary layer) | $2,071,184,871.63 | $2,075,115,137.63 | +$3,930,266.00 |
| Strict NAMED_HOSPITAL | 1,951 / $1,793,689,688.62 / 37 | 1,954 / $1,797,619,954.62 / 37 | +3 / +$3,930,266.00 |
| POOL_NAMED_HOSPITALS | 10 / $86,895,779.43 | unchanged | 0 |
| POOL_UNNAMED_HOSPITALS | 6 / $79,214,848.17 | unchanged | 0 |
| Award total | $4,556,066,882.39 | $4,559,997,148.39 | +$3,930,266.00 |
| Hospital share of allotment | 20.7% | 20.8% | |
| US_GE50 subset row (n = 23) | | unchanged | WV is at 12.2% published, outside it |

The only dollar mover is WV's CAMC release. The owner rulings move rows, not dollars:
- OK hospital rows go 93 → 92 (AVEM).
- Named hospital recipients with no amount go 298 → 297.
- Best-judgment rows go 639 → 638 (CA Legacy MD Medical Group is now CODED).

Deliverable: `output/year1_summary_2026-11-09.xlsx` and `data/reference/year1_summary_2026-11-09.csv`.
`test_08` is re-pinned to it, with a state-by-state decomposition against 11-04.

## Task 1 — Owner rulings (R/07 judgments; strict coding unchanged)

- **(a) OK AVEM Health Partners: NOT_HOSPITAL.**
  - It is a rural-hospital management company with no CMS enrolment of any kind.
  - The recipient is the manager, not a hospital it manages (§0.3a).
  - Strict coding stays Unclear. The OK CHW pool's typed count stays 29 of 48, so its HOSPITAL call stands. $0 moves.
- **(b) MO Ozarks Community Hospital ($787,430.36) and Ozark Center ($1,466,432.37): NOT_HOSPITAL, confirmed.**
  - No Missouri CMS enrolment of any kind (hospital, FQHC or RHC) carries either name.
  - Ozark Center is a community mental health centre and is the recipient DSS names. Its Freeman affiliation does not decide it (§0.3a).
  - Both rationales are written into `R/07_summary_calls.R`. Both calls were already NOT_HOSPITAL, so $0 moves.

## Task 2 — `claude/festive-cori-sm3p3c` (tip `d6a75d7`, a parallel session-109 branch)

Carried over:
- **Tribal Set-Aside status row** in `ca_year1_status.csv`, built by `ca_status_recommended()` in `R/03ab`.
  - It reads: "$11.65 million, 'included within the initiative funding described above'", OPEN, Tier 2.
  - A new `ca_assert_tribal_set_aside()` refuses the row unless the 10-28 funding-page archive still carries both quoted strings: the Submittable portal slug and the $11.65M sentence.
- **Legacy MD Medical Group, Inc. ($1,182,017, WDRR): PHYSICIAN_PRACTICE.**
  - Main typed it NONPROFIT_CBO, the standing fallback.
  - It is now a `CA_HAND` entry: STATE_SOURCE (the form is in the string HCAI prints), MEDIUM, NON_HOSPITAL.
  - It was No before and is No now, so $0 moves.

Not carried:
- **The five extra CA columns** (`awardee_as_published`, `cms_enrolment_match`, `county`, `initiative`, `row_in_pool`).
  - None is read by R/07, R/08 or the rural cut.
  - Three duplicate main's own columns: `counties_served`, `roster_line`, and the initiative carried in `award_pool`.
  - `cms_enrolment_match` would require an R/03bj EH_APPLY verdict for every row that sets it.
- **`R/03cl_ca_bp1_recommended_awardees.R`**, as instructed. Main's R/03cl is canonical.

**The branch was NOT deleted.** `git push origin --delete` was refused twice by this session's git proxy ("remote end hung up"), which allows pushes only to the session's own branch. The GitHub tools in this session have no branch-delete call. **Delete it by hand.** Its content is recorded above, and the tip SHA `d6a75d7` stays reachable through the reflog of anyone who fetched it.

## Task 3 — Routine cleanup

- Deleted (each confirmed disabled before deletion, each recorded in `routines.csv` `old_deleted` as `@2026-11-09`):
  - MS `trig_01Ugf2k1rcJiQVTtMhpnb4V3`
  - NM `trig_01EeEQZDPeG4xW4GBA7p8WcZ`
  - NE `trig_01WDA8s6uzUSaCDF7DapUzX1`
  - OH `trig_01VEe1KQEsuJRncwuoR8rQzJ`
- **Session 111d's check-in record** (`claude/gifted-gates-7c4i34`, `0b16632`: KY and ND old ids deleted 11-04) was not on main. It is cherry-picked here, with its `routines.csv` conflict resolved to keep session 114's NY runner move.
- **NY's old id** `trig_012g3adVBX9KEgDt9XiVi2tU` is still to delete. Its successor logged on `main` 11-08. It was not in this task's list, so it was not touched.
- **Coverage:** `Rscript R/probe_coverage.R --check` reports "366 due firing(s) since the logging fix; all logged except 7 EXPLAINED miss(es)".
- **Runners above 600k** (`get_session` `context_usage.used_tokens`; 43 enabled RHTP Routines):
  - CA `session_01NGLsj2qtvSvBFse6LoZUTV`: 765,576, near the 784,000 auto-compaction line.
  - MN `session_01YMHRbw9ToET8yfpwSqg5bu`: 652,461.
  - DE `session_018HApZfEPxtnu1hSndHkwQy`: 608,387.
  - Next: KS 596,953, NC 587,562. Not moved this session.

## Task 4 — Probe log since 11-02

295 lines: 135 UNCHANGED, 107 CHANGED, 47 TRIPWIRE, 6 ERROR. Session 112's sweep had already read the 11-02 morning items (CO re-pricing, TX $8M/$87M, ID governor 10-28, DE physician workforce, the CMS 10-14 obligation report). Every newer TRIPWIRE and unexplained CHANGED was read this session. The reads are archived under `data/evidence/recheck/2026-11-09/` and `data/evidence/WV/`.

### Moves a hospital dollar (extracted)

- **WV, 10-30 release, found by the 11-06 name check:** "more than $3.9 million in West Virginia Rural Health Transformation Program (WV RHTP) awards to Charleston Area Medical Center (CAMC)".
  - Mountain State Care Force $500,000 (clinical education).
  - Mountain State Care Force $1,693,946 (APP fellows, Kanawha County).
  - Health to Prosperity $1,736,320 (Pathways to Success).
  - Sum: $3,930,266.
  - CAMC is CMS-enrolled (CHARLESTON AREA MEDICAL CENTER INC, CCN 510022). Typed exactly as the 09-04 "CAMC/Vandalia Health" row: ORG_WEBSITE, MEDIUM, no CCN on the row.
  - Footer $199,476,098.72 = the allotment (Tier 1 provenance).
  - Archived `data/evidence/WV/2026-11-09_wv_art_camc_3_9m.html`. WV is now 33 rows / $24,324,218; hospital 17 / $10,254,266.

### Held for a ruling (nothing over $25M of hospital money; held because each needs a new ruling)

1. **NC "Transforming Rural Health in North Carolina: Our Progress" + "List of projects – Year 1" CSV** (134 lines).
   - Columns: Recipient, Program, Counties Served, "Budgeted Amount". Total $213,008,356.47, which is NC's allotment to the cent.
   - Page: "Budget amounts shown are subject to change based on program progress and needs."
   - It includes state agencies and vendors, so it reads as an allocation of the whole budget, and the standing rule says a budget line is never an award.
   - Hospital-shaped lines total $22,078,215.99:
     - UNC Health $21,528,215.99 over nine lines, including $12.5M Hub Lead core funding. That is ROOTS pass-through money, so it is a §10.2 flow question as well as an AHC-string question.
     - Cumberland County Hospital System, Inc. $300,000 (MIH).
     - FirstHealth of the Carolinas $250,000 (SBHC, one of five at $250,000).
   - **Ruling needed:** does a published "Budgeted Amount" price an NC award row?
2. **IA Combat Cancer Health Hubs Round 2 NOIA (RFP COMPADM26008, dated 8-12-26).**
   - Names Methodist Jennie Edmundson, MercyOne North Iowa, UnityPoint Health – Des Moines and MercyOne Des Moines. No amounts. Footer = allotment.
   - Unpriced, so outside this task's "priced rosters". Extracting it adds 4 hospital rows at $0 to R/03z's eleven-notice model.
3. **LA 11-05 Advisory Council "Budget Period 1 Data Report on Awards".**
   - Counts and "Obligated Funding" by programme ($107,823,428 competitive; 69 hospital-type awards by count, none named), plus $69,375,858 of named "other agreements", none a hospital.
   - Preliminary ("Numbers are subject to vary until contracts are executed").
   - A count of hospital awards that names none enters no bucket (§7). Context only.
   - LDH: "All RHTP Budget Year 1 award notifications have been completed as of October 30, 2026"; "Contract execution will be completed in November 2026".

### Other trips and CHANGED lines, by state (none moves a dollar)

- **CA:**
  - HCAI moved CalRHT from `/rural-health/calrht/` to `/calrht/`. The old funding and program-updates paths have been hard 404s since 11-07 (ERROR) and the programme page lost its "award" sentence (TRIPWIRE).
  - The roster at the new path is the 10-28 roster: 108 rows, $138,464,043.97, every initiative subtotal equal, still "tentative".
  - **The probe is re-pointed (URLs only).** It is not re-based, because every CalRHT footer now prints $333,639,308.46 = BP1 + $100M, a figure the footer-tier check refuses.
  - The interactive run (14:14Z) shows no 404 and still trips on the programme sentence until a human re-bases.
- **Year 2 (held):**
  - Louisiana's 11-05 deck: "CMS provided Notice of Award for $100 million to cover state's administrative expenses for BP 2".
  - NCDHHS: "All states will receive an initial $100 million award, with additional funding to follow".
  - Montana: "CMS will notify states about their Year 2 awards later in November".
  - CMS has published nothing. The CMS runs at 11-05 and 11-09 were UNCHANGED.
- **ND:** "Suicide Intervention – Healthcare Systems Initiative – Awarded |5 Applicants". Nobody named. About $400,000, one award; hospitals among others (not a hospitals-only round). Trips until re-based.
- **NE:** a sidebar link to the Nebraska Rural Health Technology Catalyst Fund. Cohort 1 applications closed 11-09; $250k–$1M per award, aimed at tech companies (Tier 2). The awardee table is unchanged (7/15/2026).
- **MN:** wording only. CAH direct-allocation grants are still "in the coming days". The page footer now prints $293,090,618.14 against the $193,090,618.14 allotment beside it, a $100M publisher defect, recorded and never parsed.
- **IN:**
  - The IDOA MOCC letter (RFP 26-87448, 09-28) was already read in session 100: three vendors, $41,690,776 maximum; Parkview only an unsuccessful bidder.
  - `grow_regional`'s 36 "names" are the Regional Committee Members table (advisory, no amounts). Region recipients and totals are unchanged.
- **WY:** "Year One Award Summaries" Drive folder holds the 08-11 approvals (byte-identical to our archive), the 10-23 prose summary, a county guide (no new priced line) and an allocation chart. No new recipient.
- **NC (other pages):** the Trillium Region 2 RFAs moved award notification to "December 2026" (two "On Hold").
- **IA (other pages):** council 11-16 agenda has no RHTP item; two RFPs rescinded; the Healthy Hometowns NOIAs are still "on or around November 2" and unposted.
- **KY:** a new Tier 2 RFA, "Rapid Response to Recovery: Transportation Support".
- **WI:** the Reentry Navigation RFA is CDC OD2A-S money, not RHTP.
- **SC:** a new "SC RHTP Annual Report – Year 1" link (CMS workbook; first-tier contractors only; "no merit based grant awards have been finalized"). The MCO names are a menu rename.
- **NY:** UHS Binghamton ED $26M is state capital and OMH money, not RHTP.
- **OK:** the LifeCare fragment is unchanged ("Hospital recruitment in progress").
- **Noise:**
  - Menus, schedules or unrelated items: DE programme (stale 09-03 baseline), NJ, TN, NV (two BP2 RFAs, Tier 2), IL, CT, RI, CO, HI, NM, MS, ID, AL, MT.
  - Already-read newsroom items: DE, ID, TX.
- **ERROR (access, not the state):** KS KDHE 403 (11-02, 11-09); MS `dom_completed` SSL chain (11-03, 11-06); CA 404s (11-07, fixed).

## Task 5 — Rebuild

Figures moved (WV), so the following were rebuilt:
- `R/03aw --build` and `R/03ar --build`. The rural cut is re-pinned to 1,954 / $1,797,619,954.62 / 37. The rural cut itself is unchanged at $566,590,756.19, because CAMC carries no CCN on the row.
- `R/07 --apply`.
- `R/08 --build` → 2026-11-09.

Pins carried in `test_03av`, `test_03ar`, `test_03ap`, `test_03bj`, `test_07`, `test_08` and CLAUDE.md (Deliverable 1 WV row, partition block).

## Suite

- **First full run** (`Rscript tests/run_tests.R`): halted at its 10-failure cap, all of them in `test_03ap`'s historical partition chain, which did not yet back out the 3 WV rows before the session-114 step. Fixed.
- **Second full run** (`testthat::test_dir`, no stop on failure): 2,172 expectations, 36 failures, 0 errors, in exactly two files:
  - `test_03bj` had the same partition chain. Fixed the same way.
  - `test_03bh`: WV's RCJ disposition CSV still said "24 of 30" rows. Rebuilt with `R/03bh --build`; it now says "27 of 33".
- **Re-run of both files:** 0 failures, 0 errors. Every other file passed in the second full run.

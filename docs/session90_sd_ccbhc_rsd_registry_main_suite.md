# Session 90 — SD CCBHC round extracted; SD's state EMS roster registered; main suite

2026-10-05. Four owner tasks.

## 1. Suite on `main` after `claude/bold-lamport-qzu37s`

The branch is on `main` (PR #93, merge `6f103b0`). The full suite was run on `origin/main` at `6f103b0` in a
detached worktree, so this session's uncommitted edits could not leak into it. Result: see the session
report. (A first run in the primary checkout was stopped and discarded, because this session's edits were
being written to the same tree while it ran.)

## 2. South Dakota's CCBHC round — EXTRACTED (`R/03bw`, `sd_year1_ccbhc_awardees.csv`)

**Source.** Governor's release of 2026-09-24, news.sd.gov **KB0047183**, archived article-only at
`data/evidence/SD/ccbhc/KB0047183.html` (manifest beside it). Found by walking KB numbers from KB0047023:
the War College repost's "original" link resolves to KB0045838, the January HB 1044 release. CMS's release
of the same day was already archived by the CMS Routine.

**What it says.** *"12 Certified Community Behavioral Health Clinic (CCBHC) modernization and infrastructure
grants totaling more than $13 million. These grants are part of the Rural Health Transformation (RHT)
funds"*; *"The CCBHC Cohort is made up of 13 agencies"*, *"selected in April following an open application
period"*; *"The next round of funding is anticipated later this fall."* No per-grant amount and no CMS
footer. The only currency figure is "$13 million".

**Coding.**
- 13 rows, one per named cohort member. `amount` empty; `round_amount` = 13,000,000 with
  `round_amount_is_floor = TRUE` ("more than"). Nothing is divided (§6.2).
- **`recipient_confirmed = Unclear` on every row.** The release names the cohort, not the grantees, and
  13 members against 12 grants means at least one named member received no grant (or one grant covers two).
  The gap is recorded, not resolved: queue `SD_CCBHC_COHORT_13_VS_12_GRANTS`.
- All 13 take the shared classifier's §8 fallback: `NONPROFIT_CBO`, LOW, `RECIPIENT_TYPE_INFERRED`,
  `NON_HOSPITAL`, `No`. The release states no form for any member.
- **0 hospital rows, $0.** The partition does not move.

**Avera Behavioral Health against CMS's SD enrolment, exact legal name** (archive
`data/evidence/SD/federal_records/2026-09-24/`, the release's own date):
- No SD Hospital, FQHC or RHC ORGANIZATION NAME or DBA is `AVERA BEHAVIORAL HEALTH`.
- SD's only `SUBGROUP - PSYCHIATRIC = Y` enrolment is CCN **434003**, STATE OF SOUTH DAKOTA (DHS Human
  Services Center), the state hospital.
- The nearest Avera string is CCN **43S016**: ORGANIZATION NAME AVERA MCKENNAN, DBA "AVERA MCKENNAN
  BEHAVIORAL HEALTH SERVICES", a psychiatric distinct-part unit CCN of Avera McKennan's hospital (430016).
- Neither is the cohort string, so no machine bridge (§2) and §7's enrolled-operator row does not reach it.
  The owner question is `SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE`. $0 moves either way. If the owner bridges it,
  it adds at most one named-hospital row, and only once the 13-vs-12 question shows Avera received a grant.
- None of the other twelve appears on any SD enrolment file under its own name (asserted in `R/03bw`).

**Year 1 status.** SD moves from `UNKNOWN` to `PARTIAL` in `R/03aw`, on "The next round of funding is
anticipated later this fall". Its pool-inclusive figure is now administrative + the two rounds + the CCBHC
pool: $142,193,072, 75.0% of the allotment (was $129,193,072, 68.2%). The ~$7.2M EMS round names nobody,
is in no file and is not counted. SD was the last `UNKNOWN` state, so `test_03aw`'s counterfactual now forges
an UNKNOWN rather than reading SD.

## 3. Regional Services Designation Grant Fund — REGISTERED as state money

Row `SD-DOH-RSD-GRANT-FUND` in `non_rhtp_state_programs.csv`: `NOT_RHTP_STATE_PROGRAM`, `match_regex`
`Regional Services? Designation`, `program_date` 2025-08-04 (the page's "Content last updated: August 4,
2025"), so a matched row also fails the §6.2 date test through the registry date.

Archive: `data/evidence/recheck/2026-10-05/SD/2025-08-04_sd_doh_regional_services_designation_grant_fund_STATE.html`,
with scripts stripped before writing. The inline script carried an Azure Application Insights
`InstrumentationKey`. Both digests are in the manifest.

**What the page says.** It is headed "Emergency Medical Services Interim Committee". Round 1 has 39
organisations, $1,668,809.91. Round 2 has 64, $5,839,975.00. "Rural Health Transformation" appears only in
the site navigation, twice. "RHT", "CMS" and "federal" appear zero times.

**Stated limit.** The page does not state a state appropriation. The row disqualifies on programme identity
and date, not on a funding-source sentence (the MI CVI row's posture).

RCJ holds no matching record on the 2026-09-24 pull, so the sweep's 111 does not move. The row exists so a
re-appearance is caught. `test_03bw` proves it catches a forged RSD title and does not catch the RHT EMS
round's own title.

## 4. The 10-08 check-in

**Not yet fired.** The report reminder `trig_011DDKhKZhNJNMwauwKM7KcV` fires **2026-10-08 15:50Z**, into
session 89's session (`session_01Rhau1rJGZ5CvGhCtardHNm`), not this one. The check-in it reports on is
`trig_01DpScA4Fs4jLUf1rRLo9bME`, which fires 10-08 15:15Z. Both are enabled.

Pre-state read 2026-10-05 ~17:00Z:
- `config/routines.csv` on `main` registers MO `trig_01EB2X…`, SC `trig_01221X…` and AL `trig_01NtbC…`.
- No log line from any of the three yet. Expected: their next firings are MO Wed 10-07 15:00Z, SC Thu 10-08
  08:30Z and AL Thu 10-08 14:40Z.
- The old MO `trig_0183Vr…` and SC `trig_01R1pZ…` are still present and `enabled: false`, on runner
  sessions different from the new ids'.

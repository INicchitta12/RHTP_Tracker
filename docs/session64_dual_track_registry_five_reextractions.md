# Session 64: Dual Track out of the spec, seven state programmes registered, five states re-extracted

2026-09-24. **RCJ quota: 0 calls.**

## 1. Georgia's Dual Track is state money, and the spec used it as its Tier 3 example

The spec's §0.2 tier table gave "GA Dual Track Remote Critical Care, $900K to 4 rural
hospitals" as its `SUBAWARD` example. Its §10.2 `PASS_THROUGH_DESIGNATED` row gave
"Georgia's Dual Track Rural Hospital Remote Critical Care NOI naming four rural hospitals".
CLAUDE.md §1 mirrors the §0.2 table.

- **What that round is.** The $900K is DCH's RCCS26 round: RFGA released 2026-05-12, up to
  four awards of $225,000. The awardees were Emanuel County Medical Center, Memorial Hospital
  and Manor, Upson Regional and Wayne Memorial.
- **Why it is state money.** Every Dual Track RFGA reads *"subject to the availability of
  appropriated funds"* and *"Managing Division: State Office of Rural Health (SORH)"*. The
  FY26 and RCCS26 RFGAs contain "Rural Health Transformation", "RHTP" and "Centers for
  Medicare" zero times. The series was first solicited on 2023-11-15, before the statute.
- **It was also the wrong flow example.** The RCCS grants go to hospitals directly, so the
  round is `DIRECT` either way, not a pass-through.

**Corrected by patch (§2.1):**
- The §0.2 row, in both the spec and CLAUDE.md, now cites Georgia's Workforce Retention
  Technology award: $2,000,000 each to 13 named hospitals on DCH's signed Notice of Award,
  already in `ga_great_health_awards.csv`.
- The §10.2 example now cites Nebraska's $18,156,856.12 NHVN award.
- A dated note in the spec records why the example changed.
- `reviewer-coding-instructions.md` carried neither example.
- A new test in `test_flow_table_parity.R` refuses Dual Track in either table. It also
  re-reads the RFGA's disqualifying words.

**Georgia's award file rests on no Dual Track figure. The dollar effect is $0.**
- All 158 rows of `ga_great_health_awards.csv` cite GREAT Health documents.
- No row carries $225,000 or $500,000.
- All seven Dual Track hospitals also hold GREAT Health awards: Appling, Coffee, Emanuel,
  Memorial Hospital and Manor, Tift, Upson and Wayne. Those awards are $750,000 AHEAD rows,
  $712,930 and $2,000,000 on signed NOAs, and Phase 2 rows. They are separate RHTP awards,
  not Dual Track money.

## 2. Seven state programmes registered; the sweep goes 66 → 111 rows

New rows in `non_rhtp_state_programs.csv`. Each carries the disqualifying sentence, read off
the archived state document.

| Registry id | Candidates | Amount | Also pre-NOA? |
|---|---:|---:|---|
| CA-DISTRESSED-HOSPITAL-SMALL-GRANT (Budget Act 2025, AB 108; General Fund) | 4 | $25,000,000 | no |
| TX-HHS0016568 Nurse-Family Partnership (GAA Art. II + TANF 93.558) | 14 | $133,864,170 | no (released 2026-01-26) |
| TX-HHS0016121 Workplace Violence Against Nurses (GAA Art. VIII Rider 3) | 4 | $667,000 | **yes** (2025-09-24) |
| TX-HHS0015358 HOPES (GAA Art. II + CBCAP 93.590) | 5 | $10,013,000 | **yes** (2024-12-17) |
| DE-DSHA-DOWNTOWN-DEVELOPMENT ("$47.4 million in state funds") | 7 | $3,433,344 | no |
| MI-MDHHS-CVI-2026 | 4 | $1,200,000 | no |
| GA-SORH-DUAL-TRACK | 7 | $2,400,000 | no (series date deliberately not typed) |

**After:** 111 caught rows in 8 states (AZ CA DE GA MI MS NV TX). The sweep caught 66 before.

**Michigan's row claims less than the others.** MDHHS's CVI release does not name its funding
source. The row disqualifies on programme identity: urban firearm-violence grants, and the
words "rural" and "RHTP" appear zero times. It does not claim a state appropriation.

**The false-positive check needed a hand-read exemption.**
- Keyed on (state, name), it reported 8 overlaps: five Dual Track hospitals that also hold
  GREAT Health awards.
- `SWEEP_OVERLAP_SAME_NAME_OTHER_PROGRAMME` exempts those five pairs.
- The exemption holds only while no published row for that hospital carries the caught row's
  amount. A test forges a coinciding amount and requires the check to fire again.

**`stage2_record_table.rds` was not rewritten.** The next Stage 2 run applies the new registry
rows, as in session 20.

## 3. Five states re-extracted (Task 3)

In every file, existing rows keep their indices. Session 49's overlay is re-applied per file,
and the name at every overlaid index is asserted.

| State | Before | After | Named-hospital change |
|---|---|---|---|
| NV | 72 named + 1 aggregate | 155 named + "93 X 95 NV" kept Unclear (gone from the page) = 156 | 27 → 42 actions, **$0** (still no amounts) |
| NE | 78 rows, $36,137,614.90 | 91 rows; +13 Initiative 5.3 **intents**, $5,549,692.25 | +6 / $1,825,002.28 (exact CMS NE enrolment) |
| MI | 139, $69,883,392 | 145, $101,318,437 (six state-agency rows, $31,435,045) | unchanged, 2 / $259,121 |
| LA | negative | 5 named RCCB awards ($1,965,788) + 1 aggregate of 48 ($10,736,208 in `round_amount`) | **none**; see below |
| SD | 13 admin contracts | 26 RHT-series contracts, 8 Rural Strong ($1,879,152) | +5 / $716,800 |

**Nevada.**
- RHIT (24), RHOAP (36) and a Tribal section (6) have awarded, and Flex grew 25 → 39.
- Residency is now named: 4 rows, all UNR/NSHE.
- Its "names nobody" aggregate row was removed because it is now false.
- Presidential Fitness, Correctional and Veterans still have no section.

**Nebraska.**
- The 5.3 notice's file name says "Notice of Award", but its body says *"DHHS intends to award
  subawards"*, so the rows are coded `NOTICE_OF_INTENT_TO_AWARD`.
- RCJ drops Regional West Medical Center ($93,867).
- The Winnebago Tribe row matches Twelve Clans Unity Hospital's CMS record on its organisation
  half. It was not promoted, and is queued as `NE_WINNEBAGO_TRIBE_HOSPITAL_SCOPE`.

**Louisiana.**
- LDH's 2026-09-03 webinar deck reports the Rural Clinician Credit Bank as of 8/28: 53 awards,
  $12,701,996, with CEAs due for signature 9/15.
- It names only the five multi-parish awardees. Its "20 hospital-setting awards,
  $6,285,515" is a facility-type split of the whole round and names none of the 20.
- That figure therefore enters no bucket, and is queued as `LA_RCCB_HOSPITAL_SETTINGS_UNNAMED`.
- Outpatient Medical Center's "Medical Center" token was overridden to §8's fallback, which
  kept $292,500 out of `NAMED_HOSPITAL`.
- LA moves `INVESTIGATED_NO_LIST` → `EXTRACTED`. The survey split is now **36/7/3/4**.

**South Dakota.**
- The 8 Rural Strong contracts sit INSIDE the 28-grant, $31.5M round. Assertions refuse adding
  them to it or reducing it.
- 20 of the 28 Rural Strong grants are still named nowhere.
- Community Memorial Hospital is two hospitals, Burke and Redfield, kept apart.
- `R/03bh`'s two SD verdicts are gone, because the rows now match the file exactly.

**Rebuilds of IN, OK and WY:** none of the five touched Indiana, Oklahoma or Wyoming, so no
overlay needed re-applying there.

## 4. Totals

- **`NAMED_HOSPITAL`:** 1,114 rows / $937,661,818.75 / 27 states →
  **1,140 / $940,203,621.03 / 28** (SD enters).
- **Pool buckets:** unchanged.
- **Rural cut:** 201 / $176,578,205.56 → **207 / $177,456,356.11**. The +6 are three NE rows
  and three SD rows that CMS enrols as CAHs.

## 5. Probes and Routines (Task 4)

**Indiana.**
- `R/03bi --probe` ran live and reported UNCHANGED.
- It is now on Routine `trig_01NZAAixvNoKcZMBKAiCUCYD`, Fridays 09:50Z, on its own pushing
  runner `session_013ysrxChnfh9xCbAEQ7UyiG`.
- It is registered in `config/routines.csv`. The exposed set drops from 21 to 20.

**Nebraska and Nevada.**
- Neither file had a working `--probe`. Both now have one, baselined on this session's
  archives.
- NE expects four award links and fails on a fifth. NV checks the seven sections and their
  counts, and fails on a dollar figure.
- Both ran live and reported UNCHANGED.
- **Neither is on a Routine.**

**Washington's 10:10Z Routine firing left no log line.** Its runner hit a GitHub
credential-service 503 and stopped, writing nothing. The Routine was re-fired at about 17:32Z;
the coverage check stays red until that line reaches `main`.

## 6. Open

- The queue gains five rows: `NE_5_3_FORM_NOT_STATED`, `NE_WINNEBAGO_TRIBE_HOSPITAL_SCOPE`,
  `NV_RECIPIENT_FORM_NOT_STATED_0924`, `LA_RECIPIENT_FORM_NOT_STATED` and
  `LA_RCCB_HOSPITAL_SETTINGS_UNNAMED`.
- Put the NE and NV probes on Routines.
- Louisiana's probe watches the programme pages, not the webinar deck that carried the award.
- CMS Louisiana enrolment files would settle the five LA forms.
- South Dakota contract 27SC091800 (SD Foundation for Medical Care, $150,000, CFDA 93.798)
  sits outside the RHT series and is unextracted.

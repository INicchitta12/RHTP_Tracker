# Session 63: every disposition re-read, a prose rule, 23 new dispositions, Indiana GROW

2026-09-24. **RCJ quota: 0 calls.** Completes session 62's §6 (its dispositions were never
committed; the working tree was clean at the start of this session, so all 21 were re-read
from scratch).

## 1. A disposition's prose may not disagree with its counts

`rhtp_assert_disposition_prose()` (`R/utils_config.R`). Session 62 found files whose count
column had been re-derived while the sentence beside it had not — Arkansas's
`NOT_IN_THE_AGGREGATOR_AT_ALL` beside 33 live candidates is the worked case. Two rules per row:

1. a code asserting absence (`NOT_IN_THE_AGGREGATOR`, `NO_TIER_3`, `NO_CANDIDATE`, `ZERO_…`)
   requires a count of 0;
2. every claim of "N Tier 3 candidates", "ZERO RCJ Tier 3 candidates", "N SUBAWARD records"
   or "RCJ's only X Tier 3 candidate" must equal the row's count or the file total — unless
   the text marks it historical ("was N", "N … on the 2026-08-27 pull").

A table that counts `records` (every RCJ record) must also carry `tier3_candidates`; TN, NJ and
WY gained one. Every builder that writes a disposition calls the rule immediately before the
write, and `test_utils_disposition_prose.R` reads every committed file and every builder's
source, so a new state cannot ship without it.

**What the rule cannot see, and this session fixed by hand:** claims about OTHER states.
"Florida had 81 awards and no candidate either" (RCJ now carries 80 Florida candidates), "one
of TWELVE states carrying NO RCJ Tier 3 candidate" (four now: IL KY NY WY), and New York's
"has awarded nobody publicly" (extracted in session 52). All three were rewritten from data.

## 2. The 26 existing dispositions (Task 1)

Unchanged candidate sets (prose checked, rule wired): CT, WI, ID, IA, OH.

| State | 08-27 | 09-24 | What moved |
|---|---:|---:|---|
| AR | 0 | 33 | 25 exact; 6 at ORGANISATION grain (sum of two awards, to the cent); 1 digest restatement; 1 admin vendor (BDO) |
| SC | 0 | 227 | 193 exact + 34 wrapped/`I2` names at the right amount; 227 of 228 awards held |
| MS | 3 | 173 | 161 exact, 6 corrupted names, 4 duplicated across documents (+$671,252 if summed), Horne, Premier |
| ME | 12 | 17 | cohort 11; 3 revised-narrative lines; 3 digest fund uses; **UNE's $12M row withdrawn** |
| MO | 29 | 30 | Doula award carried twice ($732,000 and $732,660.43); RCJ holds none of the 20 SMRP hospitals |
| NH | 27 | 26 | 3 Medicaid rows (incl. $1.9bn) withdrawn; FHC now a $1 placeholder |
| KY, NY | 0 | 0 | prose only (see §1) |
| TX | 68 | 85 | 9 ATLIS/IGT withdrawn; **Nurse-Family Partnership (14), Workplace Violence (4), HOPES (5): state money, hospital names on some**; 3 "Sheet1" rows UNRESOLVED |
| CA | 11 | 4 | SRHRP 11 withdrawn; **4 new: Distressed Hospital Small Grant Program, $25M, Budget Act of 2025 — state money, four named hospitals** |
| NM | 7 | 11 | RHCDF 7; 4 Oregon Wallowa rows misfiled (mode 6), each reconciled to OHA |
| LA | 6 | 12 | **LOUISIANA HAS AWARDED**: Rural Clinician Credit Bank, 53 awards / $12,701,996 as of 8/28, 20 hospital awards $6,285,515; only 5 named (RCJ's five). Not extracted |
| DE | 6 | 12 | 4 SBHC re-keyed at $1; 7 DSHA Downtown Development rebates (state money); 1 budget line |
| WY | 0 | 0 | 26 records; 3 of 5 Utah documents re-filed under Utah |
| NV | 34 | 42 | 3 Tier 2 lines; 5 contractors UNRESOLVED; **NVHA's page now names 155 award actions (file: 72)** |
| NE | 39 | 52 | **Initiative 5.3 intent notice (09/01): 13 applicants, $5,549,692.25**; RCJ has 12 |
| MI | 31 | 149 | roster per award (131 in file); **MDHHS added 6 rows / $31,435,045 (all state agencies)**; CVI release is state money; the SD $31.5M row is misfiled |
| OK | 35 | 36 | a ninth Initiative Funding Summary line (Tier 2) |
| TN | 0 | 1 | UTHSC $1 from the application announcement; RCJ extracted none of the 53 |
| NJ | 0 | 11 | 10 in the file (3 under rewritten names), 1 class row |
| IN | 37 | 214 | 185 GROW recipients at $1; 2 region totals; 7 vendor rows; 20 not RHTP |

**Award files now known to be incomplete, none re-extracted here:** NV (155 vs 72), NE (5.3),
MI (145 vs 139), LA (RCCB), and from §3: SD (8 Rural Strong contracts), VT, VA, FL, AK, NC.
**Probes expected to trip on their next live run:** NE (fourth notice link), NV (award index).

## 3. The 23 states that had no disposition (Task 3)

`R/03bh_rcj_candidate_dispositions.R`: 1,269 live candidates, each placed by exactly one group,
by exact normalised name + amount against the award file and a hand-read rule table for the
rest. The build fails on an uncovered candidate or a rule that matches nothing.

Findings: **Georgia's Dual Track grants (7 rows) are the State Office of Rural Health's own
series** — the spec §0.2 Tier 3 example ("GA Dual Track Remote Critical Care, $900K") is a
state-money award and should be re-pointed. **South Dakota's Rural Strong contracts are on
OpenSD**: 8 contracts, $1,879,152, five hospitals by name, in no SD file. Oregon carries 106
Catalyst/Immediate Impact awards twice. Kansas's KRHIA deck re-publishes 13 REH/CAP awards
rounded to $10,000. Minnesota's 10 are award ceilings. Unresolved: KS Stormont Vail $2.18M,
MT Big Sky Care Connect, HI HPCA's amount, RI's $6.695M, CO's CRHC notice and eHealth prizes,
WV's file-name documents.

## 4. Indiana's GROW Regional Grants (Task 4)

`R/03bi_in_grow_regional_awardees.R` → `in_grow_regional_awardees.csv` (186 rows, 178 names, 8
regions) and `in_grow_regional_status.csv` (8 regions + 2 surplus lines, no `amount`).

- `amount` empty on every row; region figure in `round_amount`, never divided. Distinct
  regions sum to $112.4M; the column sum ($2,646,800,000) is refused. Surplus $16,249,593.22 =
  $8,724,000 + $7,525,593.22.
- Indiana's FAQ: *"Primary subrecipients will be prohibited from awarding funds … via
  sub-awards/sub-grants."* No row is a pass-through; hospitals are `DIRECT`.
- **44 named-hospital rows and $0.** 38 exact CMS Indiana hospital-enrolment matches
  (`ORG_WEBSITE`/MEDIUM; 3 are CMHCs holding psychiatric-hospital CCNs, queued
  `IN_GROW_CMHC_HOLDS_HOSPITAL_CCN`); 6 hand-read bridges at LOW, queued
  `IN_GROW_HOSPITAL_BRIDGES`; 81 on §8's fallback, queued `IN_GROW_RECIPIENT_FORM_NOT_STATED`.
- Session 61 was wrong twice: "Parkview Huntington" is the Huntington YMCA; Cummins
  Behavioral Health Systems is not a hospital.
- `--probe` watches the page through `rhtp_probe_run("IN", …)` with the name tripwire. **It is
  on no Routine yet.**
- `in_assert_regional_not_awarded()` was still PASSING on the live page (IN.gov left the
  pre-award sentences beside the roster) and is replaced by `in_assert_regional_awarded()`.
- `R/03s --build` drops session 49's overlay from `in_year1_awardees.csv`; re-apply `R/03ap`.

## 5. Next session

1. Re-extract NV, NE 5.3, MI, LA RCCB, SD Rural Strong; add the missing VT/VA/FL/AK/NC rows.
2. Put `R/03bi --probe` on a Routine; expect the NE and NV probes to trip.
3. Register CA's Distressed Hospital Small Grant Program and TX's HHS0016568 / HHS0016121 /
   HHS0015358 in `non_rhtp_state_programs.csv` (the §6.2 sweep catches none of them today).
4. Re-point spec §0.2's Georgia Dual Track example (by patch, §2.1).

# Session 125 (2026-11-25): awardee ranking across all Year 1 awards; owner rulings on session 124

## Headline figures

| Figure | Session 124 | Session 125 | Change |
|---|---:|---:|---:|
| Awards published | $6,550,043,828.28 | $6,545,365,691.53 | −$4,678,136.75 |
| Hospital best estimate | $2,609,842,588.34 | $2,621,195,566.34 | +$11,352,978.00 |
| Strict NAMED_HOSPITAL | 2,390 / $2,297,215,524.33 / 43 | 2,396 / $2,308,568,502.33 / 43 | +6 / +$11,352,978.00 |
| Subset row (≥50%, n = 36) | awards $5,688,411,909.90; best $2,393,258,174.03 | $5,688,724,629.72; $2,404,869,345.03 | +$312,719.82; +$11,611,171 |
| Pools | POOL_NAMED 11 / $96,565,779.43; POOL_UNNAMED 6 / $79,214,848.17 | unchanged | — |
| Verified vendor figures | five labels (session 124) | unchanged | — |

Every move comes from Task 0. Nothing in the ranking (Tasks 1–6) moved a total.

## Task 0: owner rulings on session 124

### (a) FSRS amendments in place

`fsrs_amendments()` (R/09b) walks every FSRS archive (11-09, 11-16, 11-19, 11-20, 11-25) per SAM report id. It found 27
report ids whose amount changed in place. The rule:
- A **lower** re-filing nets like a de-obligation. It is accepted, and listed `AMENDED_DOWN` in `fsrs_held.csv` with both
  amounts.
- A **higher** re-filing dated after 2026-10-30 is a Year 2 increment. Year 1 keeps the prior amount, and the increment is
  held as `BUDGET_PERIOD_2_HELD`.
- The amendment's date is the new action date if the re-filing moved it. Otherwise it is the report's last-modified date.
- FSRS carries no subaward period of performance, so an extension cannot be read.

| Kind | Records | Effect on files |
|---|---:|---|
| AMENDED_DOWN | 8 (KY FHKY $50.49M→$41.39M; MN Allina; OR Comagine; five OR counties re-filed to ~$0) | Accepted. The archive already showed the lower amount, so no total moved. |
| Raise inside BP1 (action date moved to 10-14) | 2 (NE York County HC, United Way W. NE) | Accepted |
| **Year 2 increment held** | 17 | ME 10 (the CD doublings, MCD $1.82M, Sweetser $0.85M), KY University of Louisville $1.69M, NC Rowan/Wilkes $44,000, NE 4 × ~$41,667 |

Moves:

| State | Awards | Hospital |
|---|---:|---:|
| KY | −$1,693,658 | — |
| ME | −$3,253,198.57 | −$258,193 (MaineHealth's two doubled lines) |
| NC | −$44,000 | — |
| NE | +$312,719.83 | — |

**Why NE goes up.** With the raise held, NE Northeast Community College's 07-29 filing ($256,841.21) now equals its NOA
amount exactly. Its two other subawards ($156,348.06 on 06-23, $156,371.76 on 10-21) therefore become EXTRA rows, written
under NE's FULL_OBLIGATION rule.

**NC Rowan/Wilkes.** The increment is held, but the MIH round only reaches the state's $10M with it. That suggests a
correction rather than Year 2. A state source dating the increase would go in `config/fsrs_amendment_increase_dates.csv`.
This is an owner question.

The rule is in CLAUDE.md §7 and pinned in `test_09b_amendments_in_place.R`.

### (b) South Dakota's 15 filings

**Numbering.** SD's Year 1 register uses **both** 26RHT (24 lines) and 27RHT (771 lines). For example, 27RHT00115 begins
2026-02-20. The prefix is SD's state fiscal-year numbering, so "27RHT = FY2027" is **not** a reason to call these Year 2.

**Live register, re-read 2026-11-25.** The register lists 138 contracts, $106,846,147. All 15 filings (27RHT00126–138 and
140–142) are on it, with begin dates from 2026-02-19 to 2026-09-01. Vision Care Associates (27RHT00129, $20,000) is also
new. Under the date rule, all 15 move to Year 1 (`CONTRACT_BEGIN` entries in `config/year1_state_source_dates.csv`).

**Hospital rows.** Six of the 16 new rows are hospitals:

| Contract | Hospital | Amount | Typing |
|---|---|---:|---|
| 27RHT00128 | Fall River Health Services | $1,528,472 | — |
| 27RHT00135 | Madison Community Hospital | $3,497,116 | — |
| 27RHT00130 | Platte | $2,529,935 | hand-read bridge (truncated name), LOW |
| 27RHT00137 | Freeman | $177,636 | hand-read bridge (truncated name), LOW |
| 27RHT00133, 00136 | Brookings Health System | $3,878,012 | City of Brookings dba, CCN 430008, LOW |

Together: **+$11,611,171**.

- **City of Brookings' ambulance contract** (27RHT00141, $203,375) exactly matches the city's hospital enrolment. It is
  queued `DEFERRED_TO_OWNER` in R/03bj, not applied.
- **The count cap.** R/03i's unplaced-pool cap counted contracts against the 82 technology grants; the read now has 87
  unplaced contracts, including a first-aid trainer and EHR consultants. The count cap is now SD's own 234 agreements.
  The dollar caps stand. As a result, SD's award total does not move: the unplaced pool sits inside the announced $90M
  round.

### (c) Missouri

MO stays PARTIAL, with `source_calls_complete = Yes`. DSS's 11-12 release says *"Missouri has committed $216 million in
first-year funding"*. The same release names the remainder: *"preparing an additional $55 million in funding
opportunities through 2026"*. This is recorded in `year1_completion_status.csv`.

### (d) New York's Open Book contract maximums

Each contract record reads "RHTP 2026-2031" and has a 2026 start:
- PCDC T044018: 08/2026–08/2027.
- PCG T044016 and Accenture T044019: 07/2026–06/2031.

All three were approved or filed 10-29/10-30, with $0 spent. The transaction pages say *"Original Contract data not
available"* and *"Contract Amendment data is not currently available"*.

**Finding:** these are RHTP-specific contracts on their face, not broader DOH contracts that RHTP work was added to.
Open Book publishes no funding source for a T contract (`NOT_SHOWN`). All three stay vendor leads
(`ny_rhtp_contract_leads.csv`, `scope_finding`). No ceiling enters any total. The transaction pages are archived under
`recheck/2026-11-25/NY/`.

### (e) Scheduled tasks

- **LA/SC/ID deletion.** The check-in runs Thu 11-26 09:30Z (`trig_0115GYqc1EzHe7RA8D991PWp`), so it **had not run** at
  the time of writing. LA's and ID's successors have logged on `main`; SC fires 11-26 08:30Z.
- **New check-ins:** VA `trig_01MJFvPGdUHdVXpLnQx5atZ7` (Fri 11-27 12:40Z) and VT `trig_016MoZaaAqVMR2PyV13KJdp8`
  (Tue 12-01 13:40Z). Each deletes its old id once the successor logs, records it in `old_deleted`, and pushes a branch.

## Tasks 1–5: the awardee ranking (`R/12_awardee_ranking.R`)

**Identity rule.** UEI → EIN → CCN → hand review → same-state exact name. Details are in CLAUDE.md §7, "Awardee identity
and the ranking". The hand reviews are in `config/awardee_entities.csv`. Collisions kept separate are in
`config/awardee_entities_distinct.csv`.

**Outputs:**
- `output/awardee_ranking_2026-11-25.xlsx`, with nine tabs: All, Multi-state, Hospitals, Non-hospital, Verified vendors,
  Parent systems, Unattributed pools, Distinct name collisions, Reconciliation, Notes and method.
- `output/awardee_ranking_2026-11-25_team.xlsx`: every Delaware row removed.
- `data/reference/awardee_ranking_2026-11-25.csv` and `awardee_entity_rows.csv`.

**Counts.** 4,107 entities, of which 3,695 are ranked; the rest have only unpriced rows. 17 are multi-state.

### Top 25

| # | Awardee | Year 1 award $ | States | Type | Call |
|---|---|---:|---|---|---|
| 1 | UKHS Care Collaborative Association | $87,144,825.51 | KS | NONPROFIT_CBO | NOT_HOSPITAL |
| 2 | State Health Planning & Development Agency | $70,447,889.00 | HI | STATE_AGENCY | NOT_HOSPITAL |
| 3 | Foundation for Healthy Communities | $66,547,394.00 | NH | NONPROFIT_CBO | NOT_HOSPITAL |
| 4 | Hawaii Department of Health | $57,672,104.59 | HI | STATE_AGENCY | NOT_HOSPITAL |
| 5 | University of Hawaii | $57,501,176.00 | HI | UNIVERSITY_OR_AHC | NOT_HOSPITAL |
| 6 | ICAHN | $50,008,264.00 | IL | NONPROFIT_CBO (pass-through) | HOSPITAL |
| 7 | Utah Hospital Association | $48,191,739.00 | UT | NONPROFIT_CBO | MIXED; intents |
| 8 | Utah Education and Telehealth Network | $47,400,000.00 | UT | STATE_AGENCY | NOT; intents |
| 9 | Arizona Office of Economic Opportunity | $46,892,800.00 | AZ | STATE_AGENCY | NOT |
| 10 | CommunityHealth IT | $43,658,794.46 | FL | VENDOR | NOT |
| 11 | Washington State Hospital Association | $42,000,000.00 | WA | NONPROFIT_CBO (pass-through) | HOSPITAL |
| 12 | Foundation for a Healthy Kentucky | $41,388,100.00 | KY | NONPROFIT_CBO | NOT |
| 13 | Wyoming Innovation Partnership | $38,618,260.00 | WY | NONPROFIT_CBO | NOT; intents |
| 14 | LifeCare Alliance LLC | $33,862,084.00 | OK | NONPROFIT_CBO | NOT |
| 15 | Northeastern University | $32,006,378.15 | ME | UNIVERSITY | NOT |
| 16 | Delaware State Housing Authority | $31,862,848.00 | DE | STATE_AGENCY | NOT (**confidential: DE**) |
| 17 | Oklahoma Health Care Authority | $30,493,626.07 | OK | STATE_AGENCY | NOT |
| 18 | Indiana University of Pennsylvania | $30,239,198.33 | PA | UNIVERSITY | NOT; intents |
| 19 | Trillium Health Resources | $29,578,000.00 | NC | MCO | NOT |
| 20 | VHHA Foundation | $27,201,764.00 | VA | NONPROFIT_CBO | NOT (components HOSPITAL) |
| 21 | Virginia Health Care Foundation | $25,965,319.00 | VA | NONPROFIT_CBO | NOT (see two-tier note) |
| 22 | Illinois Primary Health Care Association | $24,500,000.00 | IL | NONPROFIT_CBO | NOT |
| 23 | Self Regional Healthcare | $24,091,668.68 | SC | HOSPITAL_OR_SYSTEM | HOSPITAL |
| 24 | Arizona Department of Health Services | $22,977,987.00 | AZ | STATE_AGENCY | NOT |
| 25 | Universities of Wisconsin | $22,587,792.00 | WI | UNIVERSITY | NOT; intents |

### Multi-state awardees (17)

| Awardee | Basis | Dollars by state |
|---|---|---|
| Comagine Health | UEI FJRDMGA7BSK6 + hand (own site: "a single organization") | ID $5,107,958.09; UT $4,000,000; OR $2,014,408.51; NV $497,077 |
| Sanford Health Network | UEI JLRSCNN9J9R8 (SD by contract number) | MN $10,812,253; SD $394,380; IA $383,752 |
| University of Utah | CCN 460009 | WY $9,255,398; UT $641,712.60 |
| Sanford Health | UEI JREYSSEK3K89 | SD $5,442,000; IA $120,000; MN $75,000 |
| UNC Chapel Hill | UEI D3LHU66KBLD5 | NC $2,800,000; UT $1,478,957 |
| Sanford Health Network North | UEI NDBHJ4AN9V61 | MN $3,257,200; ND $620,000 |
| Avera McKennan | UEI LNGXAKMH8J26 (SD by contract number) | SD $3,326,667; IA $120,000 |
| Cartwheel Health Services | UEI WAAPPEDU1C93 | WV $1,945,599; AK $993,347.45; NV $495,338 |
| Alzheimer's Association | UEI XFDHU5UJG8S9 (DE, ID's $2M filing) + own site (GA chapter) | ID $2,000,000; DE $465,724; GA $0 (unpriced) |
| Lake Superior Community Health Center | Own site lists Duluth MN (the FSRS address) and Superior WI (the CMS FQHC address) | MN $1,900,000; WI $88,344 |
| Community Health Service Inc. | UEI | MN $1,900,000; ND $40,000 |
| Unite Us | UEI J6MDAT5FY9S1 | WV $1,270,000; VT $425,000 |
| Evangelical Good Samaritan Society | UEI | SD $628,766; ND $121,455.92 |
| Valley Hope Association | UEI | NE $418,046.80; KS $219,333 |
| Community Healthcare Assoc. | UEI | SD $349,047; ND $105,450.86 |
| Lifenet Inc | UEI | OK $234,075.75; TX $146,273.71 |
| Postpartum Support International | UEI | KS $173,158.33; ND $112,078.68 |

### Name collisions kept distinct (25)

**Proven distinct:**
- Memorial Health System KS/MS.
- Community Memorial Hospital NY/SD: different CCNs; SD itself has two hospitals by UEI.
- Memorial Medical Center IL/TX.
- County of Clay IL/TX.
- Family Health Centers CA/SC.
- Wayne Memorial Hospital GA/PA.
- Good Samaritan Hospital CA/IN.
- Gunnison Valley Hospital CO/UT.
- Hardin County General Hospital IL/TN.
- Marion General Hospital IN/OH.
- Memorial Hospital CO/IL/OH/TX.
- St Mary's Hospital GA/ID.
- County of Lawrence KY/TN.
- TidalHealth DE/MD: DE's FSRS payee is TidalHealth Nanticoke, Inc., a separate legal entity.

**NOT_CONFIRMED** (kept separate, not proven distinct; owner questions):
- Public Consulting Group ID/VT.
- 22nd Century Tech ID/WV.
- Banner Health Foundation CA/CO.
- Methodist Le Bonheur Community Outreach AR/TN.
- Brown Behavioral Health Services MS/TN.
- Guidehouse ID/NM/SD.
- Deloitte Consulting DE/ID/IN.
- Fond of You AK/NJ.
- Cornerstone Whole Healthcare Organization ID/OR.
- GoodLife Innovations AR/KS.
- Mayo Clinic MN/NE.

The last six were joined on an identical legal name and withdrawn after the independent check.

### Parent systems (verified only)

| Parent | Entities | Year 1 award $ | States | Basis |
|---|---:|---:|---|---|
| Sanford Health | 5 | $25,210,630.00 | IA MN ND SD | session 87 ruling + CMS org names |
| Avera Health | 6 | $11,129,894.00 | IA MN SD | session 87 ruling + CMS org names |
| Jackson County Memorial Hospital Authority (OK) | 2 | $5,493,500.72 | OK | CMS org |
| Vandalia Health | 3 | $5,442,266.00 | WV | session 101 ruling; CAMC's CMS DBA |
| AHS Hospital Corp (NJ) | 2 | $2,920,000.00 | NJ | CMS org |
| CHRISTUS Spohn Health System Corp (TX) | 3 | $2,696,908.09 | TX | CMS org |
| Providence Health & Services Oregon | 2 | $400,000.00 | OR | CMS org |
| Dignity Health (CA) | 2 | $376,600.00 | CA | CMS org |
| Stillwater Medical Center Authority (OK) | 2 | $296,470.00 | OK | CMS org |

FSRS's SAM parent field is the awarding state on every record (STATE OF ALASKA, STATE OF IOWA, and so on), so it is not
usable. AHA system membership is not archived.

### Reconciliation (asserted in R/12 and in the test)

| Line | $ |
|---|---:|
| Ranked: award + intent | 6,015,385,990.94 |
| Ranked entities: CMS obligation lines (own column) | 82,704,951.53 |
| Unattributed pools (30 rows) | 58,730,976.13 |
| Held out: NM Accenture | 128,979,618.21 |
| **Sum** | **6,285,801,536.81** |
| R/08 published priced + excluded | 6,285,801,536.81 |
| Pool-level, no per-recipient split (separate) | 388,543,772.93 |
| R/08 awards published | 6,545,365,691.53 |

The ranked figure moves slightly with the independent-check fixes (Findhelp now ranks on its own row). The sum is unchanged.

## Task 6: independent check

A separate agent checked 70 entities: all 21 multi-state entities at the time, and the top 50. It re-read all 5,945 rows
from their award files and found **0** amount or name mismatches. The result was **60 agree, 10 disagree**; the detail is
in `data/reference/awardee_independent_check_2026-11-25.csv`, with the resolution for each.

**Fixed:**
- **Name-only cross-state joins withdrawn:** Guidehouse, Deloitte, Fond of You, Cornerstone and GoodLife (and Mayo for
  consistency).
- **Findhelp vs OHCA:** OHCA's UEI is no longer copied onto the Findhelp row (`config/awardee_uei_not_own.csv`).
- **SD register rows** now take the UEI of SD's FSRS filing with the same contract number. This fixes Sanford Health
  Network (+SD $394,380) and Avera McKennan (+SD $1.74M).
- **FSU/FAMU** pathway lines are joined within FL.

**Held for the owner: the VHCF two-tier count.** Virginia Health Care Foundation's $25,965,319 FSRS subawards and its own
subgrantees (VA_VHCF $14.39M, VA_VHCF_PP $8.64M) are the same money at two tiers. That is up to about $22.0M, counted in
the Year 1 award totals as well as the ranking. Nothing moved.

## Task 7: rebuild

**Order:** R/09b --apply, R/07, R/11, R/03aw, R/03ar (re-stated 2,396 / $2,308,568,502.33), R/07, R/11,
R/12 --build 2026-11-25, R/08 (`ys_write("2026-11-25")`), R/09c --xlsx, R/08b.

**Outputs, all dated 11-25:** year1_summary (the Notes carry the top 25 and the multi-state count), verified_vendor_list,
completed_states (xlsx and html), and awardee_ranking (full and team).

**Pins re-stated:**
- test_08.
- test_03ap, test_03bj, test_03ar, test_03i, test_09b_year1_state_dates.
- CLAUDE.md Deliverable 1 and the partition block.

Vendor figures did not move.

**Fixes along the way.** Five KY use-crosswalk rules were keyed on FSRS row numbers that the Louisville re-sort shifted.
KY-X04 would have silently pointed at the wrong Louisville row; all five are re-keyed.

## Calls made under the standing rules

1. **Amendment date.** The new action date if moved, else the report's last-modified date.
2. **Baseline.** The first archive's amount (11-09) is the baseline.
3. **SD unplaced pool.** The count cap is replaced by SD's 234 agreements; the dollar caps are kept.
4. **SD hospital bridges.** Platte, Freeman and Brookings Health System are bridged at LOW. City of Brookings EMS is
   deferred.
5. **NY contracts.** Judged RHTP-specific from Open Book's description, dates and the absence of earlier history.
6. **Cross-state joins.** Only a federal record or the entity's own site counts. A legal name alone is NOT_CONFIRMED.
7. **Delaware.** Every DE row is confidential (standing rule) and is removed from the team copy, not only rows citing
   DE Verify.xlsx.
8. **Ranking scope.** CMS obligation lines are ranked entities' obligation column, outside the ranking total.
9. **multi_state.** Counts award and intent rows (priced or not), not obligation lines.
10. **Parent view.** Parents are rolled up only from rulings and same-state CMS organisation names. TidalHealth is not
    rolled up (no ruling).

## Open for the owner

- **VHCF two-tier count** (up to ~$22.0M in award totals).
- **NC Rowan/Wilkes increment** ($44,000): a correction or Year 2?
- **NE amendments.** The four 11-20 raises to $241,666.66 match NE's 10-14 amendments of two other grantees and may be the
  same Year 1 adjustment.
- **City of Brookings EMS contract** ($203,375): apply the enrolled-operator rule to a city?
- **The 11 NOT_CONFIRMED identity pairs.** Websites or SAM records would settle them.
- **Two FSRS ids** for a pair of Oklahoma State University lines (Tulsa CHS and Stillwater). They are kept separate; the
  display names are identical.

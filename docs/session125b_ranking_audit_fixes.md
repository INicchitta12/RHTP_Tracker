# Session 125b — awardee ranking audit fixes (2026-11-26)

Owner audit of `output/awardee_ranking_2026-11-25_team.xlsx` before it goes to colleagues. Started from `main`
at #136. No new FSRS filing was applied; Year 2 untouched. Built for 2026-11-26.

## Headline

| Figure | 11-25 | 11-26 | Change |
|---|---:|---:|---:|
| Awards published (award_total_usd) | $6,545,365,691.53 | $6,522,331,691.53 | −$23,034,000 (VHCF second tier) |
| Published priced rows | $6,156,821,918.60 | $6,133,787,918.60 | −$23,034,000 |
| Hospital best estimate | $2,621,195,566.34 | $2,621,195,566.34 | none |
| Strict NAMED_HOSPITAL | 2,396 / $2,308,568,502.33 | unchanged | none |
| Hospital % of awards (national) | 40.0% | 40.2% | denominator only |
| US_GE50 awards / hospital % | $5,688,724,629.72 / 42.3% | $5,665,690,629.72 / 42.4% | VA −$23,034,000 |
| Virginia awards published | $127,175,015 | $104,141,015 | VA still ≥50% (54.9%) |
| Ranked entities | 3,695 | 3,638 | 48 VHCF subgrants unranked; same-state joins; 5 CCN joins undone |
| Entities | 4,107 | 4,044 | 33 new same-state joins, 5 CCN joins undone (independent check) |
| Multi-state entities | 17 | 17 | none |

## Task 1 — Delaware is no longer confidential (owner ruling 2026-11-25)

- **What moved.** The team copy now carries Delaware's 28 award rows, **$106,374,011**, in 26 ranked lines
  (it previously removed them and recomputed). No national figure moved: R/08 never withheld Delaware dollars.
- **Lifted in:** `R/12` (team-copy filter, `confidential` / `confidential_usd`, the "TEAM COPY ... REMOVED"
  note, the Reconciliation stub on the team copy), `R/08` (`confidential_source_flag` → `owner_supplied_source_flag`,
  "do not circulate" text gone, Notes, Definitions, Sources column, the awardee lines), `R/09`'s note wording,
  `test_08`, `test_09`, `test_12`. The team copy is kept as a file and is now the same workbook as the full copy
  (no internal-only tab exists, so nothing differs).
- **DE Verify.xlsx-only rows: none.** No Delaware award row cites `DE Verify.xlsx`; every DE figure rests on
  DHSS/Governor releases, the FQHC roster or FSRS. Four DE **status-table notes** cite it (the channels for DHIN,
  Delaware Health Force, Thomas Jefferson University, and the diabetes pilot's named hospitals). They carry no
  figure; they stay flagged `OWNER_SUPPLIED_SOURCE` (`owner_supplied_source_flag` on DE's summary row), not held out.
- **Not done:** the completed-states table never withheld Delaware (DE is not COMPLETE), and no chart filter
  existed, so nothing there changed.

## Task 2 — two-level double counts (owner ruling)

Rule (CLAUDE.md §7, "Second-tier rows"; `config/second_tier_rows.csv`; `ys_second_tier_of()` /
`ys_second_tier_check()` in R/08; role `SECOND_TIER` in R/12): count once at the first tier; second-tier rows keep
hospital attribution, are excluded from awards published, the ranking and its reconciliation, and are listed on
the new "Second-tier recipients" tab. Ceilings asserted (first-tier award and each FSRS subaward).

| Case | First tier (state → intermediary) | Second tier | Awards published | Hospital $ |
|---|---|---|---:|---:|
| **Virginia Health Care Foundation** | $25,965,319 (FSRS RHT26-007 $9,891,550 Productivity; RHT26-008 $16,073,769 Interoperability) | 48 subgrants, $23,034,000 (VA_VHCF 25 / $14,390,000 ≤ $16.07M; VA_VHCF_PP 23 / $8,644,000 ≤ $9.89M) | −$23,034,000 | none (VHCF's row is NOT_HOSPITAL; its 17 hospital subgrants, $11.03M named + $1M pool, stay in) |

The session-125 note said "up to about $22.0M"; the rosters sum to **$23,034,000**, all within VHCF's subawards.
The use-category sheet nets the second tier with an offset on VHCF's row, so groups still sum to awards published.

**Wisconsin: no double count.** DHS's implementation-partner table prices the Universities of Wisconsin and the
WTCS at $22,587,792 each; UWSA "invest[s] ... through UW campuses" and WTCS uses "a non-competitive allocation
process to 16 technical colleges", and neither allocation names a campus or college. The three rows that look like
it — The Board of Regents of the University of Wisconsin System ($2,249,918, **Community Health Worker grants**),
Chippewa Valley Technical College ($430,231) and Northcentral Technical College District ($550,000, **Rural Dental
Efficiency and Access grants**) — sit in DHS's own competitive-grant tables ("DHS awarded grants through a
competitive grant funding opportunity"), so they are separate first-tier awards. Nothing marked.

**Sweep of every other intermediary (none marked):**
- *VHHA Foundation* ($27.2M): no subrecipient is priced anywhere (its RPM/GME components are R/07 components, not rows).
- *NHVN* ($18.16M): its 21 member hospitals are $0 rows; the four priced members (Brodstone, Melham, Valley County,
  York General) are priced from NE DHHS's **own** FSRS subawards to them (SPECT imaging etc.), distinct actions.
- *ICAHN* ($50.0M, three FSRS subawards): the 80 IL_FSRS hospital rows are IL's own first-tier filings; ICAHN's
  sub-subawards are not FSRS-reportable and no file prices them.
- *UKHS Care Collaborative* (KS_FSRS, $87.1M): KS EBP participants are an enrolment file, never in STATE_FILES.
- *FHC* (NH): its CAH RFA has not awarded. *UHA* (UT): the six UT hospital rows are separate DHHS lines.
- *WSHA* ($42M): HCA's 28-hospital $9.67M pool is HCA's own round, not WSHA's.
- *Invest Nebraska*, *ARHP*, *MHA*, *NRHP/NRHPF*, *Hospital Network of Idaho / Hospital Cooperative / PCG*,
  *NC hub leads*, *FHKY* (KY's Purchase DHD $280k is KY's own FSRS subaward), *OHA lung screening* (no OHA row
  priced): no priced subrecipient rows of their own.
- *State agencies* (OHCA, HI SHPDA/DOH, CT agencies, WI DWD/DPI, MN, UT): no file prices their sub-recipients,
  with one shape noted: OK's Findhelp ($830,400) is priced from OSDH's FSRS subaward **to OHCA**, and is the only
  row on that money (no OHCA row carries it), so nothing is counted twice; it still ranks as Findhelp (session 125's
  `awardee_uei_not_own` call). Owner may prefer it shown at OHCA under the first-tier rule.

## Task 3 — same-state joins and relabels

`aw_norm()` now splits "DBA" strings into halves, normalises each (punctuation, hyphens, trailing legal forms)
and sorts them; each half is also a within-state name key. Joins are still refused where UEIs or CCNs differ.
Three `SAME_STATE_LEGAL_BODY` hand entries (config/awardee_entities.csv) cover the owner's named cases whose
identifiers differ. CO's CMS file drops CCNs' leading zero; `aw_cms_orgs()` now pads it.

**Owner-named cases:**
- Bartlett Regional Hospital (AK) — **joined** by hand: the two FSRS UEIs are Bartlett (EMPEA3BQCKQ5, 3250
  Hospital Dr) and the City & Borough of Juneau (N1JNXUBBV5L4, 3260 Hospital Dr), its owner. $573,612.
- Five-Town Health Alliance / Mountain Community Health (VT) — **joined** by the DBA rule (three strings). $318,421.
- AHS Hospital Corp. (NJ) — **joined** at the legal entity; facilities: CCN 310028 Newton Medical Center, CCN
  310115 Hackettstown Medical Center. $2,920,000.
- Lutheran Hospital Association of the San Luis Valley (CO) — **joined**; facilities: CCN 060008 SLV Health
  Regional Medical Center (Alamosa), CCN 061308 San Luis Valley Health (La Jara). $2,836,619.
- Oklahoma State University — **two lines, relabelled**: UEI T3B4DWYVH7L5 (Tulsa; the Center for Health Sciences)
  $17,772,799; UEI NNYDFK5FTSX9 (Stillwater) $15,757,458.
- University of Tennessee — **two lines, relabelled**: Knoxville (UEI L54FLKJM2MN4) $1,300,000; Memphis (UEI
  X1M1PN3KG3E7) $429,709.
- Community Memorial Hospital (SD) — **not joined** (different UEIs and hospitals): Redfield (City of Redfield,
  CCN 431316) $2,989,440; Burke (Community Memorial Hospital, Inc., UEI EXT3AA4K5SV1) $145,500.

**Every new join (33 entities; all within one state; none split):**

| State | Printed names joined | Basis | Ranked $ |
|---|---|---|---:|
| AK | Bartlett Regional Hospital | HAND_REVIEWED | $573,612 |
| CO | Lutheran Hospital Association of the San Luis Valley dba San Luis Valley Health (Regional Medical Center) / Lutheran Hospital Association of the San Luis Valley, DBA San Luis Valley Health (Conejos County Hospital) | HAND_REVIEWED | $2,836,619 |
| GA | South Georgia Medical Center, Inc. / South Georgia Medical Center, Inc. d/b/a SGMC Health / South Georgia Medical Center, Inc. (Berrien County) / South Georgia Medical Center, Inc. (Lanier County) | SAME_STATE_EXACT_NAME | $1,462,930 |
| IA | Hamilton County Hospital dba Van Diest Medical / Hamilton County Hospital dba Van Diest Medical Center | SAME_STATE_EXACT_NAME | $0 |
| IA | Shelby County Chris A Myrtue Memorial Hospital, DBA Myrtue Medical Center / Shelby County Chris A Myrtue Memorial Hospital, DBA Myrtue Medical / Shelby Co. DBA Myrtue Medical Center / Shelby County Chris A Myrtue Memorial Hospital dba Mrytue Medical Center | SAME_STATE_EXACT_NAME;UEI | $2,826,800 |
| IA | Mahaska County Hospital dba Mahaska Health / Partnership Mahaska County Hospital dba Mahaska Health Partnership / Mahaska County Hospital dba Mahaska Health Partnership / MAHASKA COUNTY HOSPITAL | SAME_STATE_EXACT_NAME;UEI | $3,562,894 |
| IA | St. Joseph's Mercy Hospital DBA MercyOne / St. Joseph's Mercy Hospital DBA MercyOne Centerville Medical Center / MERCY MEDICAL CENTER - CENTERVILLE | SAME_STATE_EXACT_NAME;UEI | $1,205,280 |
| KS | Memorial Health System / Hospital District No. 1 of Dickinson County, Kansas, DBA Memorial Health System | SAME_STATE_EXACT_NAME | $1,650,000 |
| MS | George County Hospital / George County Hospital DBA Greene County Hospital | SAME_STATE_EXACT_NAME | $3,188,436 |
| MS | Northeast Mental Health - Mental Retardation Commission d.b.a. LIFECORE Health Group / Northeast Mental Health d.b.a. LIFECORE Health Group / Northeast Mental Health-Mental Retardation Commission d.b.a. LIFECORE Health Group | SAME_STATE_EXACT_NAME | $65,810 |
| NE | CHI Health Schuyler / Alegent Creighton Health DBA CHI Health Schuyler | SAME_STATE_EXACT_NAME | $947,425 |
| NJ | AHS Hospital Corp. | HAND_REVIEWED | $2,920,000 |
| NJ | CompleteCare Health Network / Community Health Care, Inc. DBA CompleteCare Health Network | SAME_STATE_EXACT_NAME | $1,027,231 |
| NV | Lincoln County Hospital District dba Grover C. Dils Medical Center / Grover C. Dils Medical Center / Grover c. Dils Medical Center | SAME_STATE_EXACT_NAME | $791,504 |
| NV | DVH Hospital Alliance LLN dba Desert View Hospital / Desert View Hospital | SAME_STATE_EXACT_NAME;UEI | $6,213,545 |
| OK | The LeFlore County Hospital Authority, dba Eastern Oklahoma Medical Center (EOMC) / Eastern Oklahoma Medical Center | SAME_STATE_EXACT_NAME | $86,783 |
| OK | Alva Hospital Authority, dba Share Medical Center / Share Medical Center | SAME_STATE_EXACT_NAME | $47,810 |
| PA | Windber Hospital, Inc. dba Chan Soon-Shiong Medical Center at Windber / Windber Hospital, Inc. | SAME_STATE_EXACT_NAME | $1,007,504 |
| PA | Center for Behavioral Health-HA, LLC dba Lewistown Comprehensive Treatment Center / Center for Behavioral Health-HA, LLC dba Farrell Comprehensive Treatment Center / Center for Behavioral Health-HA, LLC dba. Chambersburg Comprehensive Treatment Center | SAME_STATE_EXACT_NAME | $315,972 |
| PA | Cornerstone Care, Inc. dba Cornerstone Care Greensboro Health Center / Cornerstone Care | SAME_STATE_EXACT_NAME | $1,231,235 |
| PA | Darway Rehabilitation and Healthcare LLC dba Darway Rehabilitation and Healthcare / Darway Rehabilitation and Healthcare, LLC. | SAME_STATE_EXACT_NAME | $1,020,000 |
| PA | Jeffco Health Services, Inc. / Jeffco Health Services, Inc. dba Penn Highlands Jefferson Manor | SAME_STATE_EXACT_NAME | $918,586 |
| PA | WRC Pennsylvania Memorial Home / WRC Pennsylvania Memorial Home dba McKinley Health Center | SAME_STATE_EXACT_NAME | $833,735 |
| VT | Northern Counties Health Care / Northern Counties Health Care, Inc. / Northern Counties Health Care DBA Caledonia Home Health Care and Hospice | SAME_STATE_EXACT_NAME;UEI | $1,581,584 |
| VT | Rutland Regional Medical Center / Rutland Regional Medical Center DBA Rutland Hospital Inc. / Rutland Hospital, Inc. DBA Rutland Regional Medical Center | SAME_STATE_EXACT_NAME;UEI | $4,522,008 |
| VT | Springfield Center for Living and Rehabilitation / 105 Chester Road Opco LLC DBA Springfield Center for Living and Rehabilitation | SAME_STATE_EXACT_NAME;UEI | $2,055,360 |
| VT | 1248 Hospital Drive Opco LLC DBA St. Johnsbury Center for Living and Rehabilitation / St. Johnsbury Center for Living and Rehabilitation | SAME_STATE_EXACT_NAME | $2,081,510 |
| VT | Mountain Community Health DBA Five Town Health Alliance, INC / Five-Town Health Alliance Inc DBA Mountain Community Health, Inc. / Five Town Health Alliance DBA Mountain Community Health | SAME_STATE_EXACT_NAME | $318,421 |
| VT | North Star Health / North Star Health DBA Springfield Medical Care Systems | SAME_STATE_EXACT_NAME | $537,791 |
| VT | CLR Opco DBA The Center for Living and Rehbailitation / CLR Opco | SAME_STATE_EXACT_NAME;UEI | $1,461,060 |
| VT | S&A Healthcare PLC DBA New England Wellness Group / New England Wellness Group | SAME_STATE_EXACT_NAME | $402,391 |
| WI | La Clinica de los Campesinos Inc. DBA Noble Community Clinics / La Clinica De Los Campesinos Inc. DBA Noble Community Clinics / La Clinica de los Campesinos Inc. | SAME_STATE_EXACT_NAME | $1,733,900 |
| WY | Memorial Hospital of Laramie County dba Cheyenne Regional Medical Center / Memorial Hospital of Laramie County dba Cheyen | SAME_STATE_EXACT_NAME | $2,609,594 |

**CCN joins undone (independent check):** a CCN no longer joins two rows that carry different UEIs **and**
different normalised names. Where a row's CCN came from an address match, the two disagreeing federal UEIs win.
One legal name filed under several site UEIs still joins (OSF Healthcare System, IL). Five pairs split:
ND Cooperstown Medical Center / Griggs County Nursing Home ($30,425); WV War Memorial Hospital / East Mountain
Health Physicians ($355,958); IL The Carle Foundation ($2,187,135) / The Carle Foundation Hospital ($356,853);
MN Lake Region Healthcare Corp. / Prairie Ridge Hospital ($62,364); TX Liberty County Hospital District No 1
(its row is paired to the UEI of Liberty-Dayton Regional Medical Center LLC, the operator) / "Liberty County Hosp"
(UEI of the hospital district). The TX pairing is a lead for R/09b: row 318 may be paired to the operator's filing.

**Relabelled lines (51; the awardee column now carries the identifier in brackets):**

| Display name | Ranked $ |
|---|---:|
| BROWN BEHAVIORAL HEALTH SERVICES, PLLC [TN; UEI V4A2AFKV6YR6: Brown Behavioral Health Services, PLLC, Bolivar] | $300,000 |
| Banner Health Foundation [CA; state roster name; no federal identifier on the row] | $620,000 |
| Banner Health Foundation [CO; state roster name; no federal identifier on the row] | $629,142 |
| Brown Behavioral Health Services [MS; state roster name; no federal identifier on the row] | $448,140 |
| COMMUNITY MEMORIAL HOSPITAL [SD; CCN 431316: Community Memorial Hospital, Redfield] | $2,989,440 |
| COMMUNITY MEMORIAL HOSPITAL [SD; UEI EXT3AA4K5SV1: Community Memorial Hospital, Inc., Burke] | $145,500 |
| COUNTY OF LAWRENCE [KY; UEI YAKTYGV2G6T6: County Of Lawrence, Louisa] | $280,000 |
| COUNTY OF LAWRENCE [TN; UEI DAKHSD18MVG5: County Of Lawrence, Lawrenceburg] | $305,461 |
| Community Memorial Hospital [NY; CCN 331316: Community Memorial Hospital, Hamilton] | $1,581,930 |
| Cornerstone Whole Healthcare Organization, Inc [ID; UEI FHEJFWMPDX59: Cornerstone Whole Healthcare Organization Inc, Payette] | $1,902,992 |
| Cornerstone Whole Healthcare Organization, Inc. (DBA C-WHO) [OR; state roster name; no federal identifier on the row] | $1,033,216 |
| DELOITTE CONSULTING LLP [DE; UEI CSDLNCHM5KA4: Deloitte Consulting LLP, Lake Mary] | $649,052 |
| Deloitte Consulting LLP [ID; state roster name; no federal identifier on the row] | $1,286,711 |
| Deloitte Consulting LLP [IN; state roster name; no federal identifier on the row] | $0 |
| Family Health Centers, Inc. [CA; state roster name; no federal identifier on the row] | $622,500 |
| Family Health Centers, Inc. [SC; state roster name; no federal identifier on the row] | $1,183,224 |
| Fond of You Inc (Somethings) [AK; UEI HPA4TPTBUBC1: Fond Of You, Inc., Brooklyn] | $2,617,260 |
| Fond of You, Inc. [NJ; state roster name; no federal identifier on the row] | $499,498 |
| GUIDEHOUSE INC [SD; state roster name; no federal identifier on the row] | $567,350 |
| GUIDEHOUSE INC. [NM; UEI N9NJK877QJK9: Guidehouse Inc., Mc Lean] | $20,100,773 |
| Good Samaritan Hospital [IN; CCN 150042: Good Samaritan Hospital, Vincennes] | $120,000 |
| Good Samaritan Hospital, LP [CA; CCN 050257: Good Samaritan Hospital, LP, Bakersfield] | $340,278 |
| GoodLife Innovations [KS; UEI GRV1N6MU67L5: Goodlife Innovations Inc, Overland Park] | $1,169,246 |
| GoodLife Innovations, Inc. [AR; state roster name; no federal identifier on the row] | $802,420 |
| Guidehouse, Inc. [ID; state roster name; no federal identifier on the row] | $1,763,000 |
| Gunnison Valley Hospital [CO; CCN 061320: Gunnison Valley Hospital, Gunnison] | $4,527,669 |
| Gunnison Valley Hospital [UT; CCN 461306: Gunnison Valley Hospital, Gunnison] | $167,260 |
| HARDIN COUNTY GENERAL HOSPITAL [IL; CCN 141328: Hardin County General Hospital, Rosiclare] | $356,853 |
| HARDIN COUNTY GENERAL HOSPITAL [TN; CCN 440109: Hardin Medical Center, Savannah] | $547,260 |
| MAYO CLINIC [MN; UEI Y2K4F9RPRRG7: Mayo Clinic, Rochester] | $106,032 |
| MEMORIAL HOSPITAL [IL; CCN 140185: Memorial Hospital, Belleville] | $356,853 |
| MEMORIAL MEDICAL CENTER [IL; CCN 140148: Springfield Memorial Hospital, Springfield] | $356,853 |
| METHODIST LE BONHEUR COMMUNITY OUTREACH [TN; UEI MWXTN3VXGGH5: Methodist Le Bonheur Community Outreach, Memphis] | $3,825,403 |
| Mayo Clinic [NE; state roster name; no federal identifier on the row] | $0 |
| Memorial Health System [KS; state roster name; no federal identifier on the row] | $1,650,000 |
| Memorial Health System [MS; state roster name; no federal identifier on the row] | $15,260,342 |
| Memorial Hospital [OH; state roster name; no federal identifier on the row] | $0 |
| Memorial Hospital [TX; CCN 451386: Memorial Hospital, Dumas] | $971,980 |
| Memorial Medical Center [TX; CCN 451356: Memorial Medical Center, Port Lavaca] | $2,868,001 |
| Methodist Le Bonheur Community Outreach [AR; state roster name; no federal identifier on the row] | $340,725 |
| OKLAHOMA STATE UNIVERSITY [OK; UEI NNYDFK5FTSX9: Oklahoma State University, Stillwater] | $15,757,458 |
| OKLAHOMA STATE UNIVERSITY [OK; UEI T3B4DWYVH7L5: Oklahoma State University, Tulsa] | $17,772,799 |
| Public Consulting Group LLC [ID; state roster name; no federal identifier on the row] | $14,520,000 |
| Public Consulting Group [VT; state roster name; no federal identifier on the row] | $1,104,343 |
| The Memorial Hospital (dba Memorial Regional Health) [CO; CCN 061314: Memorial Regional Health, Craig] | $2,180,298 |
| TidalHealth [DE; UEI HE1GJ6EBUFL8: Tidalhealth Nanticoke, Inc., Seaford] | $411,817 |
| TidalHealth [MD; state roster name; no federal identifier on the row] | $4,911,052 |
| UNIVERSITY OF TENNESSEE [TN; UEI L54FLKJM2MN4: University Of Tennessee, Knoxville] | $1,300,000 |
| UNIVERSITY OF TENNESSEE [TN; UEI X1M1PN3KG3E7: University Of Tennessee, Memphis] | $429,709 |
| Wayne Memorial Hospital [GA; state roster name; no federal identifier on the row] | $750,000 |
| Wayne Memorial Hospital [PA; CCN 390125: Wayne Memorial Hospital, Honesdale] | $1,000,000 |

## Task 4: organisation type

A reader column `organisation_type`, in both workbooks and in `awardee_entity_rows.csv`; `recipient_type` itself
is unchanged. Plain labels for every code. **NONPROFIT_CBO prints "Organisation (form not stated)"** where the row
carries RECIPIENT_TYPE_INFERRED, **or** is LOW confidence, **or** the printed name carries a for-profit legal form
(LLC, LLP, PLLC, PC, Corp). This goes further than the owner's literal rule, which keyed only on the flag. Measured:
421 NONPROFIT_CBO award rows carry no flag. 192 of them are LOW, and the MEDIUM ones include Pennsylvania
nursing-home and treatment-centre LLCs. On the flag alone, Access East, Inc. (LOW, GENERAL_KNOWLEDGE, no flag) and
LifeCare Alliance LLC would still have printed "Nonprofit". Academic health centres print "Hospital or health
system (academic health centre)". Hospital associations and networks (config/spend_category_entities.csv,
hospital_affiliate) print "Hospital association or network".

## Task 5: Read first tab

This tab is the first sheet of both workbooks. It covers:
- what is ranked, with intents shown in their own column;
- that intermediaries pass money on, flagged in the pass_through column (count shown for the top 25);
- the counted-once rule;
- that the ranking shows concentration, not the hospital share. Beside it: hospital best estimate
  $2,621,195,566, 40.2% of awards published ($6,522,331,692);
- organisation type;
- the NM Accenture hold-out;
- what is listed separately: pools, second tier and unpriced rows;
- same-name labels, Delaware, and the build date.

A "Joins and relabels" tab lists every multi-string or hand join and every relabel.

## New top 25 (Year 1 award + intent dollars)

| # | Awardee | States | Total | Organisation type | Pass-through |
|---:|---|---|---:|---|---|
| 1 | UKHS CARE COLLABORATIVE ASSOCIATION | KS | $87,144,826 | Hospital association or network | Yes |
| 2 | STATE HLTH. PLNG. & DEV. AGENCY | HI | $70,447,889 | State agency |  |
| 3 | Foundation for Healthy Communities (FHC) | NH | $66,547,394 | Hospital association or network | Yes |
| 4 | HAWAII DEPARTMENT OF HEALTH | HI | $57,672,105 | State agency | Yes |
| 5 | UNIVERSITY OF HAWAII | HI | $57,501,176 | University | Yes |
| 6 | Illinois Critical Access Hospital Network (ICAHN) | IL | $50,008,264 | Hospital association or network | Yes |
| 7 | Utah Hospital Association (UHA) | UT | $48,191,739 | Hospital association or network | Yes |
| 8 | Utah Education and Telehealth Network (UETN) | UT | $47,400,000 | State agency |  |
| 9 | ARIZONA OFFICE OF ECONOMIC OPPORTUNITY | AZ | $46,892,800 | State agency | Yes |
| 10 | CommunityHealth IT | FL | $43,658,794 | Vendor or contractor |  |
| 11 | Washington State Hospital Association | WA | $42,000,000 | Hospital association or network | Yes |
| 12 | THE FOUNDATION FOR A HEALTHY KENTUCKY, INC . | KY | $41,388,100 | Organisation (form not stated) |  |
| 13 | Wyoming Innovation Partnership (WIP) | WY | $38,618,260 | Organisation (form not stated) | Yes |
| 14 | LIFECARE ALLIANCE LLC | OK | $33,862,084 | Organisation (form not stated) |  |
| 15 | NORTHEASTERN UNIVERSITY | ME | $32,006,378 | University |  |
| 16 | DELAWARE STATE HOUSING AUTHORITY | DE | $31,862,848 | State agency |  |
| 17 | OKLAHOMA HEALTH CARE AUTHORITY | OK | $30,493,626 | State agency |  |
| 18 | Indiana University of Pennsylvania | PA | $30,239,198 | University |  |
| 19 | Trillium Health Resources | NC | $29,578,000 | Managed care organisation | Yes |
| 20 | Virginia Hospital Research and Education Foundation (d/b/a VHHA Foundation) | VA | $27,201,764 | Hospital association or network | Yes |
| 21 | Virginia Health Care Foundation | VA | $25,965,319 | Organisation (form not stated) | Yes |
| 22 | ILLINOIS PRIMARY HEALTH CARE ASSOCIATION | IL | $24,500,000 | Organisation (form not stated) |  |
| 23 | Self Regional Healthcare (Lakelands Region) | SC | $24,091,669 | Hospital or health system |  |
| 24 | ARIZONA DEPARTMENT OF HEALTH SERVICES | AZ | $22,977,987 | State agency | Yes |
| 25 | Universities of Wisconsin | WI | $22,587,792 | University |  |

The top 25 is dominated by intermediaries and state agencies. Self Regional Healthcare (rank 23) is one legal
entity printed under nine site names across 20 SC rows; the label shows only the largest site name. Guidehouse Inc.
(NM, rank 37) prints "form not stated", because its file uses the fallback typing; it is a verified vendor.

## Task 6: independent check

A separate agent that had not seen the fixes re-checked the team copy against the 93 award files (5,945 Year 1 rows).
- **Delaware: AGREE.** Delaware is on every tab where it belongs, and the team copy's sheets equal the full copy's.
  Delaware's dollars are $106,374,010.58 in the files and the same in the workbook.
- **Top 50: AGREE.** Totals match to $0.00 on all 50, and the names, states, types and pass_through flags all agree.
- **Joins: AGREE on the seven named cases; DISAGREE on two other joins, with two more doubtful.** All four were
  fixed (the five CCN splits above). The checker also listed possible missed joins: MercyOne North Iowa Foundation
  (two spellings, unpriced), Youth First (unpriced), and WVU Health System vs WVU Medicine (not verified). None was
  joined.
- **Second tier: AGREE.** The 48 VHCF rows ($23,034,000) are excluded and fit inside both subawards. No other
  double count was found. A labelling point: the four Nebraska rows listed as NHVN members are the state's own
  direct FSRS awards for other purposes, so nothing is counted twice, but they carry a pass-through label.
- **Awards published: AGREE.** $6,285,801,536.81 priced, minus Accenture $128,979,618.21, minus second tier
  $23,034,000, gives $6,133,787,918.60, the same as published_priced_usd. Ranked + obligations + unattributed pools
  reconcile to it.

## Calls made without stopping to ask

1. The OK Findhelp $830,400 stays ranked as Findhelp, the vendor, even though the state's FSRS subaward is to
   OHCA. Only one row carries that money, so nothing is counted twice.
2. The NONPROFIT_CBO reader label goes beyond the flag-only rule (Task 4 above).
3. The CCN-join refusal is narrowed to rows where both the UEIs and the names differ. A blanket refusal would have
   split OSF, Vanderbilt, Sarah Bush Lincoln and Douglas County NE, each of which is one legal name filed under
   several UEIs.
4. A `SAME_STATE_LEGAL_BODY` hand join was used for Bartlett: its two UEIs belong to the hospital and to its owner
   on the same campus.
5. CO's CMS enrolment file drops the leading zero from its CCNs. `aw_cms_orgs()` now pads them, which also lets
   CO entities reach the CMS-organisation parent rollup.
6. `award_rows` and `priced_rows` still count second-tier rows, because the rows exist. Only dollars exclude them,
   and `second_tier_rows` / `second_tier_usd` show the exclusion.
7. The team copy is byte-for-byte the same content as the full copy. There were no internal-only tabs to drop.

## Files

- `R/08_year1_summary.R`: owner-supplied flag; `ys_second_tier_*`; second-tier columns; use-category offset.
- `R/12_awardee_ranking.R`: all five tasks and the CCN refusal.
- `R/09_vendor_flags.R`: note wording only. `R/09c`: as-of date.
- `config/second_tier_rows.csv` (new). `config/awardee_entities.csv`: three hand joins.
- Tests: `test_08`, `test_09`, `test_11` and `test_12` (re-pinned to 11-26; new tests for Delaware, second tier,
  DBA names, labels, organisation type and the CCN refusal).
- Outputs dated 2026-11-26: `year1_summary`, `year1_use_categories`, `year1_vendor_summary`, `awardee_ranking`
  (CSV, xlsx and _team.xlsx), `completed_states` (xlsx and html), `verified_vendor_list`.

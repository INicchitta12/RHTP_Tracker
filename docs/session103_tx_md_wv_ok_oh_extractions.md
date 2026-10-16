# Session 103 (2026-10-16): Texas, Maryland, West Virginia, Oklahoma and Ohio; probe fixes

**Start.** Session 102's branch (`claude/epic-dirac-q70zqm`) was not yet on `main`. It was merged into this branch, so this session builds on session 102. No Year 2 work was done. The four new CMS releases all say "fiscal year 2026", so no FY2027 amount was announced and nothing was archived for one.

## Hospital partition, before and after

The three buckets are never added. Published figures leave out `SOURCE_SUSPECT` rows, as `rhtp_hospital_dollar_partition()` does by default.

| Bucket | Before (session 102, published) | **After (published)** | After (internal, with SOURCE_SUSPECT) |
|---|---|---|---|
| NAMED_HOSPITAL | 1,336 / $1,307,219,167.63 / 32 states | **1,538 / $1,426,413,861.18 / 33 states** | 1,540 / $1,429,869,282.18 |
| POOL_NAMED_HOSPITALS | 6 / $55,255,171.43 | **6 / $55,255,171.43** | same |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | **5 / $69,323,109.17** | same |

**What moved: +202 rows, +$119,194,693.55.**
- **Texas:** +201 rows / +$117,571,194.73. Texas is the 33rd state.
- **Oklahoma RRR:** +1 row / +$1,623,498.82 (SSM St. Anthony Shawnee Cancer Center).
- **West Virginia:** +0. Its five new rows are one Unclear and four non-hospital.
- **Nevada:** a new flag on two rows; no dollars moved.

**Rural cut (`R/03ar`):** 267 / $280,202,733.99 → **407 / $366,644,593.52**. Texas adds 140 CAH-CCN rows / $86,441,859.53. SSM Shawnee's CCN (370149) is not a CAH.

**New slices that can be subtracted:**
- **TX hand-read bridges (LOW):** 80 rows / $54,468,593.79. Of those, 63 / $47,250,000.00 are executed Initiative 1 lines.
- **TX intents vs executed contracts (hospital rows):** executed 88 / $68,612,883.94; intents 113 / $48,958,310.79. Intents carry `AMOUNT_PRELIMINARY`.
- **NV `ASSOCIATION_SERVICE`:** 2 rows / $4,170,261.00 (POOL_NAMED). See Task 6.

## Task 1: Texas, Rural Texas Strong (EXTRACTED, `R/03ce_tx_rts_awardees.R`)

**Source.** The Governor's and HHSC's 2026-10-15 releases link `10-8-2026-list-award-recipients.xlsx`. HHSC's programme page now links a newer list, `10-15-2026-list-award-recipients.xlsx` ("as of 10/14/26"), and says "The list will be updated weekly". Both lists are archived, along with both releases and the programme page, in `data/evidence/recheck/2026-10-16/TX/`.
- **The 10/14 list is the one extracted:** 312 lines, Year 1 subset $137,234,879.62.
- **It supersedes the 10/8 list.** This is asserted: every 10/8 line, matched by initiative and both amounts, is on the 10/14 list. Names were re-cased between the two.

**What the list is.** It lists applications at "Intent to Award" status. "A grant is not considered awarded until a contract has been fully executed."
- Every row is `NOTICE_OF_INTENT_TO_AWARD`.
- 97 lines read "Awarded (Contract Fully Executed) = Yes" (`amount_confirmed = Yes`).
- The other 215 are intents (`amount_confirmed = No`, `AMOUNT_PRELIMINARY`).
- `amount` is the **Year 1 subset**. The multi-year "Total Award Amount" is in `total_award_amount` and is never summed with `amount`.

**Reconciliation, to the cent, on the 10/8 list the release cites:**

| | Lines | Year 1 subset |
|---|---:|---:|
| 10/8 list, all lines | 284 | $129,089,434.73 |
| less executed Initiative 1 lines (the 09-28 round, 68 × $750,000) | 68 | −$51,000,000.00 |
| **= intent lines** | **216** | **$78,089,434.73** |

The release says "plans to award $78 million in Rural Texas Strong grants to 216 rural healthcare providers" and "The $78,089,434.73 is a portion of the $281,319,360.67 first-year award". So the "216 providers" are 216 application lines, not 216 distinct organisations. CMS's 10-15 Texas release says "$78 million", the same figure rounded. The $281,319,360.67 is Texas's allotment (§7.1 anchor $281,319,361). It is asserted `STATE_ALLOTMENT` through the shared rule, in both directions.

**Typing on CMS's TX Hospital, FQHC and RHC enrolment files** (`federal_records/2026-10-01/`):

| Route | Hospital rows | Non-hospital rows | Total rows | Year 1 |
|---|---:|---:|---:|---:|
| EXACT record match (MEDIUM) | 121 / $63,102,600.94 | 22 (FQHC) | 143 | $66,597,485 |
| Hand-read BRIDGE (LOW, CCN where unique) | 80 / $54,468,593.79 | 4 (FQHC) | 84 | $55,155,217 |
| District with no enrolment (Hardeman precedent) | 0 | 6 | 6 | $1,723,434 |
| Hand-read non-hospital typing | 0 | 47 | 47 | $7,640,097 |
| §8 standing fallback | 0 | 32 | 32 | $6,118,647 |
| **Total** | **201 / $117,571,194.73** | **111** | **312** | **$137,234,879.62** |

- **CCNs.** 199 of the 201 hospital rows carry one. Two entities each enrol two hospital CCNs, so neither row carries one: Graham Hospital District (450085 and 671300) and Metroplex Adventist Hospital, Inc. (450152 and 451323).
- **The 72 abbreviated Initiative 1 lines** ($750,000 Year 1 / $3.5M total, with names like "Memorial Hospital", "Rolling Plains", "Lockney Gen Hosp") are each bridged by hand to one enrolled legal entity in `TX_RTS_BRIDGES`.
- **BP1 cross-check (`tx_rts_assert_bp1()`).** All 33 districts in HHSC's BP1 report (R/03bp) correspond one-to-one to Initiative 1 lines: 29 through a bridge that cites the BP1 name, 3 by their full name on the list, and Hardeman. Of the 72 lines, 68 are executed and 4 are intents (Llano, Mitchell, Hansford, Fairfield).
- **"Memorial Hospital" is bridged by elimination**, the weakest bridge in the file. It is bridged to MOORE COUNTY HOSPITAL DISTRICT dba MEMORIAL HOSPITAL (CAH 451386, Dumas):
  - "Memorial Hospital" is the DBA of three enrolled entities.
  - Seminole and Gonzales each have their own Initiative 1 lines.
  - Moore County is the one BP1 name that no other line abbreviates.
  - The decision is queued (`TX_RTS_MEMORIAL_HOSPITAL_BY_ELIMINATION`).
- **Districts with no enrolment under their own name: NOT hospital rows** (the owner's Hardeman precedent). These are Hardeman County HD (2 lines), Maverick County HD, Nolan County HD, Stonewall County HD and Winnie Stowell HD: 6 lines / $1,723,434.39, coded LOCAL_GOVT_OR_PUBLIC_HEALTH / NON_HOSPITAL.
- **R/03bp's Hardeman note is imprecise.** It says Hardeman has "no hospital enrolment at all". The district has none, but the TX file carries **HARDEMAN COUNTY MEMORIAL HOSP (CAH 451352, Quanah)**. Stonewall County and Nolan County also sit beside an enrolled hospital under another name. Queued as `TX_RTS_DISTRICT_NAME_NOT_ENROLLED`, one-directional: $1,350,458.20 if all three are bridged.
- **Not bridged, also queued (`TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED`):**
  - Lamb County Hospital ($376,659.20): the enrolled hospital is LAMB HEALTHCARE CENTER, a different name.
  - UT Health Henderson ($38,275.00): HENDERSON HOSPITAL LLC carries no UT Health DBA.
  - Principle Health Systems ($221,010.48): a parent or management company.
  - CHRISTUS Trinity Clinic, 13 county lines ($853,994.87): the system's physician group, typed PHYSICIAN_PRACTICE on the CalvertHealth Medical Group footing.
- **Trap kept out.** RCJ's three "Sheet1" urban-hospital rows are not on the list. The disposition text now says so.

**Probe.** R/03n's Routine now also trips when HHSC's programme page links a list other than the extracted one (`tx_rts_live_finding()`). Expect it to trip on the next weekly list, which is the cue to update `TRT_LIST_PATH`, `--fetch` and `--build`, then re-read the bridges.

**Survey.** TX moves INVESTIGATED_NO_LIST → EXTRACTED. The survey is now **41 / 5 / 1 / 3**.

**Vulnerabilities to state when using the figure:**
1. 113 of the 201 hospital rows ($48.96M) are intents, not executed grants.
2. 80 rows ($54.47M) rest on hand bridges from abbreviated names.
3. The list is weekly and partial ("Applications or applicants that don't appear on this list haven't reached that stage"), so the TX figure is a floor.
4. Initiative 1's 68 × $750,000 is a formula round to every district that applied. It is hospital money, but per-hospital it is a flat payment, not a competitive award.

## Task 2: Maryland, STOPPED (does not reconcile)

**Finding.** The MD Labor page (`labor.maryland.gov/employment/wdrhtp.shtml`) publishes exactly **38 award lines in four tables, 34 distinct organisations, $13,965,196**. I parsed it myself, and a separate read agreed. There is no 39th line on the page, in either release, in the FAQ or in the policy PDFs.

**Where the $16.4M comes from.** "$16.4 million" is the **Transformation Fund's size**. MD Labor policy MPI 10-26 says: "Of the $168 million awarded to Maryland, $20.1 million is subawarded from SORH to the Maryland Department of Labor … through two distinct RHTP funding streams: the Immediate Impact Fund ($3,700,000); and Transformation Fund ($16,400,000)." The headline therefore presents a Tier 2 pool figure as an award total. The gap is $2,434,804.

**Action.** Not extracted, per the stop rule. Evidence is archived in `recheck/2026-10-16/MD/` (page, Governor's release, FAQ, MPI 10-26). Queued as `MD_LABOR_ROSTER_UNRECONCILED`.

**Hospital-shaped lines, if the owner approves extracting the 38:**
- TidalHealth Peninsula Regional, 3 lines, $843,816
- CalvertHealth Medical Center, $300,000
- UM Charles Regional Medical Center, $500,000
- UM Shore Regional Health, $499,898
- UM Upper Chesapeake Health, $499,999
- Frederick Health Hospital, $430,317
- Meritus Health Foundation, $500,000 (foundation rule)

Together that is $3,574,030 before enrolment typing. CalvertHealth Medical Group ($492,093) is a physician group.

**Footer.** The footer's $168,180,837.61 is the allotment, at 100% federal. The flow is CMS → MDH (SORH) → MD Labor → grantees.

## Task 3: West Virginia, EXTRACTED (+5 rows) and a name check on the news page

The four releases (10-13 and 10-14) are archived under `data/evidence/WV/2026-10-16_*`. Rows are quoted verbatim.

| Awardee | Amount | Coding |
|---|---:|---|
| West Virginia University (WVU) Eye Institute | $2,000,026 | **Unclear** (owner's instruction): UNIVERSITY_OR_AHC, PASS_THROUGH_UNRESOLVED, no bucket. No CMS WV enrolment carries "WVU Eye Institute" or any "Eye" string on a hospital record. WEST VIRGINIA UNIVERSITY HOSPITALS INC (510001) is not named. Queued `WV_WVU_EYE_INSTITUTE_UNCLEAR` |
| Potomac Highlands Guild | $500,000 | NON_HOSPITAL, §8 fallback |
| West Virginia Primary Care Association (WVPCA) | $1,656,432 | NON_HOSPITAL, NONPROFIT_CBO (health-centre association) |
| Monongahela Valley Association of Health Centers (MVA) | $500,000 | NON_HOSPITAL, FQHC (release and CMS FQHC file) |
| Ascension Recovery Services (ARS) | $1,500,000 | NON_HOSPITAL, §8 fallback, `AMOUNT_ROUNDED_IN_SOURCE` |

- **Totals.** WVPCA + MVA = $2,156,432, matching the release's "nearly $2.2 million" (asserted). WV now has 26 rows / $15,404,875 priced; hospital rows are unchanged at 12 / $2,924,000.
- **Lauren's Wish ($211,700) is Appalachian Regional Commission INSPIRE money**, not RHTP, and is not a row. It sits inside the ARS release's "$1.7 million" headline.
- **The name check (`wv_new_article_findings()`).** Every slug that is new to the news index (not in the archived index, and not recorded or judged) is fetched into memory. If its **body** says "Rural Health Transformation" and "award", it trips, and the finding names the organisations in its award sentences. So a recipient now trips regardless of the headline's wording.
- **Logging.** The headline trip and the body check are collected as findings and logged TRIPWIRE, following session 101's nothing-throws-early rule. Tests drive both cases.
- **Live run** (interactive, 21:29Z): no finding.

## Task 4: Oklahoma (owner-approved)

- **RRR +1:** "SSM St. Anthony Shawnee Cancer Center, $1,623,498.82" (the 10-15 page, archived as `OK/new_rosters/2026-10-16_*`). It is appended as row 20; rows 1–19 keep their 10-12 strings.
  - The 10-16 page re-punctuates two names and appends "Counties covered:" to every line. The two copies are therefore matched by amount, and this is asserted.
  - **Typed on enrolment** (owner's instruction): ST ANTHONY SHAWNEE HOSPITAL INC dba ST. ANTHONY SHAWNEE HOSPITAL, CCN 370149, LOW, hand bridge, no `cms_enrolment_match` code.
  - **Vulnerability, stated on the row:** §10.2 keeps a sub-unit named without its legal entity off the hospital rows (OHSU Casey Eye, WVU Eye Institute). This string differs in naming the hospital itself.
  - RRR is now 20 rows / $40,078,521.82; its hospital rows are 11 / $22,723,302.82.
- **City of Wewoka (Fire Department) is removed** and recorded in `OKC_EMS_WITHDRAWN`, never dropped silently.
  - **Correction to session 102:** the line was in the **ambulance-funding** list, not the vehicle list. In the archive it is the first line under "Organizations receiving ambulance funding:".
  - EMS/CP is now 50 rows. It is not a hospital row.
- **The stale list is emptied.** `OK_PENDING_OPPORTUNITIES` now holds nothing. BHI and EMS/CP, which session 99 extracted, were still on it, so the 10-15 Routine tripped on rosters this repository already carries.
- **The probe baseline is re-based** to 2026-10-16 (`--probe-baseline`) after reading the page. The old 10-02 baseline predated the BHI and EMS/CP rosters. A live probe returned UNCHANGED on all three pages.
- **Text-only drift.** The Doulas and CDM rebuilds change only "Classifier said …/HIGH" → "/MEDIUM", the session-88 ceiling CLAUDE.md predicted. No typing or amount moved.

## Task 5: CMS releases and Ohio

**CMS.** `R/00 --run` (interactive) archived four new FY2026 releases to `data/raw/cms/2026-10-16/`:
- TX $78M (10-15)
- OH $92M (10-16)
- MT $3.63M to 17 EMS agencies (10-16)
- **NH "more than $11 million"** (10-16; new state, newsroom only)

Each says "fiscal year 2026", and none names a recipient. `cms_state_announcements.csv` gains MT, NH, OH and TX.

**Ohio's state roster behind the $92M.** It is on ODH's new page "Hospitals, Clinically Integrated Networks and Rural Health Innovation Hubs, and Maternal Care" (dated 10-16, archived `recheck/2026-10-16/OH/`):
- **Hospitals:** "This investment provides $30.3 million in one-time direct payments to 22 rural hospitals". All 22 are named, including two that need a hand read: "Sojourn at Seneca", and "Memorial Hospital", which is ambiguous.
- **CINs and Hubs:** $31.4M across 7 organisations.
- **Maternal care:** $30.3M across 6 organisations.
- **No per-recipient amount anywhere**, and the page itself says "The funded projects haven't been announced yet."
- The footer's "$202 million" is the rounded allotment, at 100%.
- **Not extracted:** it is not a priced roster. A 22-way pool is never divided (§6.2).
- **Hospital effect if extracted as names at $0:** +22 hospital rows, $0.

**Separate Ohio gap.** ODH's pharmacy page says "The Ohio Pharmacists Association (OPA) has been awarded $2 million", which `oh_year1_awardees.csv` does not carry. It is non-hospital.

Both Ohio items are queued as `OH_ODH_92M_UNPRICED_AND_OPA`.

**Why R/03an did not trip:**
1. It has not run since the change. It last ran Wed 10-14 13:43Z; the next firing is 10-21.
2. It watches only the 07-01 Ohio University release and the ODH landing page. The roster is on a **child page** (`rht-resources/healthcare-centers`) that it never fetches, so the name tripwire cannot see it.
3. On 10-21 it will log the landing page CHANGED. Its assertions, though, look only for "Ohio University" and read a static release.

**Proposed fix (not built):** probe the ten `rht-resources/*` pages, with the name tripwire scoped to each page's "Funded Projects" region.

## Task 6: Small fixes

- **Maine.** `R/03aa` sends `Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)` to maine.gov hosts only, through `me_agent_for()`; www.mcd.org keeps `ME_USER_AGENT`.
  - Measured here: the old agent got 3/3 HTTP 403, the new one 3/3 HTTP 200.
  - `test_utils_agent_scope.R` pins the agent string, the host scope (including look-alike hosts) and the call site. The no-browser-agent test still passes.
  - **Live probe:** fetched every page. It logged CHANGED on `rhef`, `doe` and `programme` (all against a stale baseline); the award tripwires pass. **Those three pages were not read this session.**
- **Nevada.** A new flag, `ASSOCIATION_SERVICE` (vocabulary row appended byte-wise; numstat 1/0), on RHOAP-18 (row 143, $3,772,261.00) and RHIT-19 (row 109, $398,000.00). It is applied inside `nv_apply_s102_rulings()`, so a rebuild keeps it. No bucket moved.
- **Mississippi.** WEI and EmPATH status rows now read `MOVED_TO_CLOSED_NO_RECIPIENT_NAMED`, citing the archived "Closed Funding Opportunities" page (`recheck/2026-10-16/MS/`). That page says only "The application periods for the following opportunities have passed", so the rows say explicitly that this is **not** a statement the programmes went unawarded. The release's window runs to 10-29.

## Queue (6 new, all OPEN)

`TX_RTS_DISTRICT_NAME_NOT_ENROLLED`, `TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED`, `TX_RTS_MEMORIAL_HOSPITAL_BY_ELIMINATION`, `WV_WVU_EYE_INSTITUTE_UNCLEAR`, `MD_LABOR_ROSTER_UNRECONCILED`, `OH_ODH_92M_UNPRICED_AND_OPA`.

## Probe log written this session (interactive)

| Probe | Result |
|---|---|
| WV | news CHANGED; no finding |
| OK | UNCHANGED, after the re-base |
| ME | rhef, doe, programme CHANGED, unread |
| CMS | CHANGED (new state NH; new releases MT, OH, TX) |

Coverage check: "179 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)".

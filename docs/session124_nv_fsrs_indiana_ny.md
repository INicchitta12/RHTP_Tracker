# Session 124 (2026-11-25): Nevada, FSRS 11-25, Indiana Meds-to-Beds, NY partners, vendor labels, MA, use rulings

## Headline figures

| Figure | 11-24 (session 123) | 11-25 (session 124) | Change |
|---|---:|---:|---:|
| Awards published | $6,529,984,965.77 | $6,550,043,828.28 | +$20,058,862.51 |
| Hospital best estimate | $2,604,985,516.91 | $2,609,842,588.34 | +$4,857,071.43 |
| Strict NAMED_HOSPITAL | 2,370 / $2,292,358,452.90 / 43 | 2,390 / $2,297,215,524.33 / 43 | +20 / +$4,857,071.43 |
| Subset row (≥50%, state sources) | n = 36; awards $5,681,621,259.12; best $2,390,832,803.43 | n = 36; $5,688,411,909.90; $2,393,258,174.03 | +$6,790,650.78; +$2,425,370.60 |
| Pools | POOL_NAMED 11 / $96,565,779.43; POOL_UNNAMED 6 / $79,214,848.17 | unchanged | — |

By state (awards / best estimate = strict): IN +$885,195 / +$885,195 (Meds-to-Beds); ND +$9,093,484 / +$2,173,508; ME
+$3,518,157 / +$258,193; NE +$4,185,456 / +$320,176; OK +$720,000 / +$220,000; WV +$1,000,000 / +$1,000,000; KY
+$656,571 / $0. Every move comes from the FSRS 11-25 archive or Meds-to-Beds.

## Task 1: Nevada, and the TN, WY, CO re-bases

**Nevada's finding: no award.** The four TRIPWIREs (11-10, 11-13, 11-17, 11-20) and the YEAR2 lines are the NVHA
"Nevada's RHT Funding Opportunities" page moving to Budget Period 2: an intro "preparing to release additional funding
opportunities ... for Budget Period 2 (BP2)", the "Rural Health Transformation Applicant Guide – Budget Period 2", and
two new RFAs, CBHT WRRAP (due 12-10) and Medicaid Reentry RHIT/FLEX (due 12-15). Nobody is named, nothing is priced.
Session 121 had already put the three programme titles in furniture. Re-based `nofos` to
`recheck/2026-11-25/NV/`; live UNCHANGED.

- **TN:** TDH's rolling 15-item index aged out two pinned headlines. `TN_KNOWN_RHTP_HEADLINES` now leads with the award
  release and the $422M release (a NON-AWARD file). The news baseline is re-based. Live UNCHANGED.
- **WY:** `programme` and `submittable` are also extraction sources (the BP1 footer check; the "no open calls"
  control), so an in-place re-base broke the validator. I reverted it. The probe now reads its own baselines
  (`WY_PROBE_BASELINES`, `recheck/2026-11-25/WY/`). The diff: the button reads "Year One Award Summaries"; the footer
  prints $412,236,673.93 "in Budget Periods 1 & 2" (FY2026 $205,004,743 + FY2027 $207,231,931); one open RFA, 1.2 EMS
  Regionalization (Tier 2). A test pins both. Live UNCHANGED.
- **CO:** the programme block is now "Grantee Open Office Hours", and the AC will not meet in December. The awardees
  page changed only its breadcrumb; the roster text is identical. HCPF reads from here again. Both re-based. Live
  UNCHANGED (92 lines).

## Task 2: FSRS weekly filings (archive 2026-11-25)

The 50 primes now obligate **$20,000,000,000**, which is FY2026 plus the full FY2027 award (Tier 1, Year 2, never in a
Year 1 figure). There are 3,072 subawards, **+442**. New filings by state, largest first:

| State | Filings | $ |
|---|---:|---:|
| TX | 263 | $94,265,139 |
| ID | 55 | $77,180,208 |
| AK | 19 | $30,242,096 |
| KS | 14 | $18,339,518 |
| SD | 15 | $16,035,517 |
| OR | 9 | $12,736,621 |
| KY | 8 | $10,839,874 |
| ND | 38 | $9,093,484 |
| IN | 5 | $7,786,576 |
| NE | 6 | $4,766,071 |
| OK | 8 | $3,055,684 |
| WV | 1 | $1,000,000 |
| ME | 1 | $264,958 |

**Texas files each subaward twice.** One `RHTCMS100F-26` record equals the Year 1 subset HHSC's list prints. One
`RHTCMS100F-27` record holds the remainder of the multi-year award. Rankin County HD: $1,029,800 + $970,200 = the list's
$2,000,000 total. All 132 `-27` records ($36,103,575) are new this week, so nothing earlier is contaminated. A new R/09b
status, `HELD_TX_NOT_YEAR1_SUBSET`, holds them (budget period 2), and a test pins it.

**Disposition of the 442.**

| Disposition | Count | $ |
|---|---:|---:|
| Matched exact | 93 | $84.4M |
| Matched, differs (state amount stands) | 88 | $71.0M |
| New rows written | 50 | $28.2M |
| Extra rows written | 2 | $0.3M |
| $0 rows priced | 3 | $0.7M |
| Held: TX remainder | 132 | $36.1M |
| Held: Year 2 by date (SD 15, IN 4) | 19 | $21.3M |
| Held: unreviewed candidate | 25 | $19.1M |
| Held: published-roster complete states (ID) | 14 | $14.0M |
| Held: reviewed ambiguous | 6 | $6.1M |
| Held: same amount on roster | 5 | $3.7M |
| Held: state pool | 3 | $0.7M |

- **Crosswalks.** 24 hand MATCH and 6 HOLD crosswalk entries were added, each read on name, city and description.
- **The SD 15 are held.** These are 27RHT00126-142, dated 11-04 to 11-10, and none is on the archived register. Session
  121's completion-statement date covers SD *register* agreements, and these cannot yet be shown to be among the 234.
  Hospital share: Platte $2.53M, Madison $3.50M, Fall River $1.53M, Freeman $0.18M. This is an owner question.

**The independent duplicate check** was a separate agent, run on the 58 rows to be written.
- KS **Children's Mercy Hospital $5,596,062** is KS row 18 ("Children's Mercy Hospital", $6,096,062, KDHE RPGP). A
  curly apostrophe defeated the exact match. It is now a crosswalk MATCH, DIFFERS, so the state amount stands.
- TX Heart of Texas Healthcare System $178,894 = row 314, and Liberty-Dayton RMC $879,420 = row 318. Both are pairings.
- **A defect it exposed:** I had swapped the two TX pairings' FSRS ids, and R/09b accepted the swap, because it compared
  a pairing's amount only with the roster row. R/09b now refuses a pairing whose amount is not the FSRS record's own;
  this is tested.
- Linton Hospital Foundation ($10,897) is a hospital row under §7 (FSRS_HAND_TYPING, LOW).
- War Memorial Hospital $1M (WV) is a "possible" overlap with the WVU CCG award. I wrote it: it is a first-tier
  subaward from the state, separate from WVU's own award, and the amounts do not reconcile.
- No new row exceeds $25M of hospital money. New hospital dollars total ≈ $4.0M.

**State re-filings read as filed** (same report id, last modified 11-23):
- **ME:** ten CD-series subawards doubled (e.g. MaineHealth $10,321 → $20,642). This is a lead to read.
- **KY:** the Foundation for a Healthy Kentucky went $50,490,600 → $41,388,100.

**VENDOR lines (11-24):**
- Out-of-state registered addresses: Children's Mercy, Comagine, the Alzheimer's Association, Health Equity Solutions,
  Postpartum Support International and CHAD.
- Pampa Regional Medical Center's Ontario, CA address is Prime Healthcare's; it is now crosswalked to Prime Healthcare
  Services – Pampa, LLC.
- None enters a verified vendor figure.

## Task 3: Indiana Meds-to-Beds

R/09b routes Indiana subawards by description. A description naming Meds-to-Beds links only to `IN_MTB`, and every
other Indiana subaward never links there (`fsrs_in_mtb()`). Eleven are priced, **$885,195**.

Name differences, each resolved by a hand crosswalk:

| FSRS name | Roster name |
|---|---|
| The Board of Trustee of Putnam County Hospital | Putnam County Hospital |
| Perry County Memorial Hospital Foundation | Perry County Memorial Hospital (§7 hospital foundation) |
| Bluffton Health System LLC | Bluffton Regional Medical Center |
| Greene County General Hospital | "Greene County General Hosptial" (roster typo kept as read) |
| Union Hospital Inc | Union Hospital Clinton |
| Marion General Hospital Inc | Marion Health MGH Campus |
| Daviess County Hospital | Daviess Community Hospital |
| Jackson County Schneck Memorial Hospital | Schneck Medical Center |
| Adams County Memorial Hospital | Adams Memorial Hospital |

Bremen and Good Samaritan match exactly.

**The test** (`test_09b_session124.R`) asserts:
- 11 PRICED_ZERO_ROW, all on `IN_MTB`, totalling $885,195;
- none of the eleven ids is on a GROW row;
- the MTB file sums to $885,195.

**Not counted twice.** Before the change they were held, as GROW pool members or zero rows, and were in no total. The
other 9 sites stay at $0. Cameron Memorial's $35,000 Meds-to-Beds filing is held: Cameron is not on IDOH's 20.
Harrison County ($4.0M, 11-10) and Reid ($200k, 11-05) are dated after 10-30 (Year 2) and their text says Initiative 5,
so they do not confirm the 9 names.

## Task 4: New York implementation partners

All three are priced on Open Book New York (OSC), but **as contract maximums**: DOH contracts described "RHTP 2026-2031",
OSC type T (not pre-audited), spending to date $0.

| Partner | Contract | Maximum | Term |
|---|---|---:|---|
| Primary Care Development Corp | T044018 | $169,500,000 | 08/2026–08/2027 |
| Public Consulting Group LLC | T044016 | $154,205,000 | 07/2026–06/2031 |
| Accenture LLP | T044019 | $307,086,040 | 07/2026–06/2031 |

- **Held for an owner ruling.** Together they are **$630,791,040**, more than NY's whole FY2026+FY2027 award
  ($419,808,278.74). Admitting them would multiply the verified contract-maximum line about 25-fold.
- They are recorded in `data/reference/ny_rhtp_contract_leads.csv` (a non-award file), with archives under
  `recheck/2026-11-25/NY/`.
- Open Book shows no vendor address, so V6/V9 cannot be run and out_of_state would be NOT_SHOWN.
- The vendor workbook's Notes tab records Accenture in two states: NM held (ASO, $128,979,618.21) and NY (T044019).

## Task 5: the named vendor figures

Session 121's "$251.3M award line" and session 122's "$199.5M" were different figures. The gap, exactly
**$51,768,463.51**, is the UKHS Care Collaborative's four lines (owner ruling: PROVIDER_PASS_THROUGH) plus the VHHA
Foundation component. The 116e check list (`verified_vendor_list.csv`) still files those five as vendor awards; the
spend layer does not.

`rhtp_vendor_figures()` (`R/utils_spend_category.R`) now defines five labels. R/08's Notes and Definitions and the
vendor workbook's new Definitions tab state them. `test_vendor_figures_named.R` pins them and the gap.

| Label | 11-20 | 11-23 | 11-25 |
|---|---:|---:|---:|
| Verified vendor awards (excluding provider pass-through) | $199,513,205.75 | $199,513,205.75 | $199,513,205.75 |
| Verified pass-through to providers (awards) | $161,468,764.63 (of which $18,156,856.12 in hospital dollars) | same | same |
| Verified vendor intents | $48,233,747.84 | same | same |
| Verified vendor contract maximums | $25,965,898.00 | same | same |
| Verified vendor obligations | $30,181,665.63 | same | same |

The verified case lists have not changed since 11-20, so the restatement is the same on each date. The five figures are
never added together.

## Task 5a: Massachusetts

| Route | Result |
|---|---|
| mass.gov (hub, home) | 403 (Akamai) |
| mehi.masstech.org (RHTP hub, Sandbox, SHINE-HT, Rural HIE) | **200**: four programmes, NOFOs numbered 2027 (Tier 2, likely Year 2), no awardee; footer "$162,005,238.13 ... 100 percent funded by CMS/HHS" (Tier 1) |
| masscybercenter.org (Rural Health Cybersecurity, NOFO 2027-Cyber-01) | **200**, no grantee |
| MassTech news, notices, 2026 board minutes | 200, no award vote |
| Health Policy Commission | mass.gov only (403) |
| COMMBUYS | JSF form, UNKNOWN (not "no bids") |
| Press (Boston Globe 10-13, Athol Daily News 10-14) | six **eligible** hospitals for a capital RFA (§0.3), no award |
| Wayback | snapshots exist (hub 10-16, key dates 10-09, newsletters 10-09); fetch blocked (egress 403 / TLS reset) |
| USAspending | MA has 0 FFATA subawards against a $320.4M prime |

No route publishes a Year 1 award. **MA now has a probe** (`R/03cy`, five MeHI/MassCyberCenter subject pages, the name
tripwire and an award-sentence check), archives under `data/evidence/MA/probe/`, and a weekly Routine on its own runner
(`trig_01JcoBDKBoSQ3yASzgUcizP2`, Thu 18:25Z, `session_01Y1P5eQB6FTsdfdyh4CKrEk`). MA moves INVESTIGATED_NO_PROBE →
INVESTIGATED_NO_LIST. The mass.gov URLs for the owner to save by hand are in `docs/owner_upload_requests.md`.

## Task 5b: Hawaii typing fix

- "STATE HLTH. PLNG. & DEV. AGENCY" (2 rows, $45,447,889 and $25,000,000) is now STATE_AGENCY, NOT_HOSPITAL
  (FSRS_HAND_TYPING).
- Sweeping every NONPROFIT_CBO row named Agency/Department/Dept/Office of/Commission re-typed:

| Recipient | New type |
|---|---|
| OK Health Care Workforce Training Commission | STATE_AGENCY |
| RI BHDDH | STATE_AGENCY |
| Augusta School Department (ME) | SCHOOL_OR_DISTRICT |
| NV Esmeralda County Board of Commissioners | LOCAL_GOVT_OR_PUBLIC_HEALTH (its R/07 judgment removed, now CODED) |
| OK Elk City Fire Department, Tonkawa Fire Department (4 rows) | EMS_OR_PSAP |

- **Left as NONPROFIT_CBO:** Michigan's community action agencies and area agencies on aging, PA's regional planning
  commissions, SD's Human Service Agency, NJ's Salem Inter Agency Council and MS LIFECORE. Each is typically a nonprofit
  or a regional body, and no source states otherwise.
- No hospital dollar moved. Pinned in `test_session124_government_typing.R`.

## Task 6: rhtptracker.com

The state award pages are behind an access request. The weekly check now yields opportunity leads only, and this is
recorded in `R/03cw`. No access was requested. The Fri 11-27 20:23Z run is kept; read its result next session.

## Task 7: probe log since session 122

**Nothing in the log moves a hospital or vendor dollar beyond the FSRS archive (Task 2).**

| State | Verdict | Read |
|---|---|---|
| ID | TRIPWIRE 11-24 | DHW dropped the full stop after "Oct. 16"; same document id 37915. Not a new roster. Pin loosened; the new "Vendor-Subawardee Resources" link title is furniture on both pages. |
| ND | TRIPWIRE 11-25 | 12 more rounds headed "Awarded \| N Applicants" (Walking 30, School Wellness 60, Hospital Wellness 38, Tech Extender 45, Clinical Equipment 38, Ambulance Modernization 82, Telehealth 17, RPM 18, Coordinating and Connecting Care 10, EMR 12, AI 11, Kiosks 5). Nobody is named and nothing is priced. Recorded in `ND_AWARDED_ROUNDS`. Hospital-Based Wellness is not hospitals-only (638 clinics eligible). |
| NE | TRIPWIRE 11-25 | Menu and news additions only: the Catalyst Fund timeline, the $219.2M Year 2 release (Tier 1), and Catalyst applications open (Tier 2). The Awardees links are the same four notices. Furniture. |
| MO | TRIPWIRE + YEAR2 11-25 | The 11-06 "Over $55 Million" release is new **opportunities** (Tier 2). The 11-12 "committed $216 million in first-year funding" is **held** as a possible completion statement. The $55M round suggests a known Year 1 remainder (owner question). Not re-based. |
| MS | TRIPWIRE 11-24 | Rural GME Expansion and the Innovative Pilot (Tier 2); `dom_completed` 403 (ERROR). |
| MT | TRIPWIRE 11-24 | Newsletter and meeting sentences; nobody named. |
| NM | CHANGED / ERROR | The ASO watch is quiet on all six pages; `programme_v2` is a 404. HCA's ASO announcement is due 11-30. |
| FSRS | TRIPWIRE + VENDOR 11-24 | Applied as Task 2. |
| CO, TN, WY, NV | — | Re-based (Task 1). |
| KY, HI, RI, ME, VA, NY, DE, NEWSROOM | CHANGED | No recipient on any trip read; KS is ERROR (KDHE 403). |

- **No newly COMPLETE state.** MO's statement is held for the owner.
- **Runners:**

| Runner | Context | Action |
|---|---:|---|
| VT | 776,513 | Moved to `trig_01Aj1baBtsRaMmAxezwQJ14c` / `session_01Y1P5eSya3Bn5nBpwcCxPwR` |
| VA | 732,133 | Moved to `trig_01FBq8rLWpLgcbroYHcCPChz` / `session_01Y1P5eR8q5tBFm6Vrkgr8PA` |
| CT | 645,007 | Reported |
| DE | 640,809 | Reported |
| OK | 629,002 | Reported |
| NC | 619,798 | Reported |
| CO | 612,363 | Reported |

  The moved prompts match byte for byte; the old ids are disabled and chained in `routines.csv`.

## Task 7a: use-category rulings

- **(a) Text method.** Every crosswalk rule now carries `text_method`, and award rows carry `use_category_text_method`.
  OCR: MS 8, MI 15, KY 16. HAND_TRANSCRIBED: HI 7. The page images are archived (HI as PNG renders; MS, MI and KY in the
  archived PDFs), and session 123 checked the quotes against them. Admitted at MEDIUM.
- **(b) CMS report headings.** The new basis CMS_REPORT_HEADING (MEDIUM, in the vocabulary) has 40 headings, built by
  `R/11 --headings` into `config/use_category_cms_headings.csv`:
  - 38 at initiative level: exact normalised name, one programmatic heading;
  - 2 hand lines: MS Care Gap Closure → J (MS-006-06-06) and OK LifeCare → I (OK-003-12-31).

  **MULTIPLE: $3,098,053,827 → $2,744,212,825 (−$353,841,002).** By state:

| State | Change |
|---|---:|
| MI | −$153.1M |
| MS | −$104.1M |
| OK | −$45.7M |
| HI | −$25.0M |
| VT | −$9.0M |
| SD | −$5.7M |
| WA | −$5.4M |
| DE | −$2.9M |
| NC | −$2.1M |
| IN | −$0.9M |

  Three programmes have a heading whose letter is not among the plan's letters (VT Data Platform K; WA Initiative 4 I;
  IN MTB). There the plan's letters were kept and the conflict is recorded in the quote.
- **(c) Provider payments (B).** Ohio's "$30.3 million in one-time direct payments to 22 rural hospitals" is now B
  (PURPOSE_TEXT, LOW; ODH's own sentence). No other award's source uses provider-payment language; SD's rounds name
  nobody and carry no such text. **B total (primary) $50,721,806: hospital $30,300,000 (OH); non-hospital $20,421,806
  (RI).**
- **(d) Iowa capital.** The J coding stands.
  - The NOFO's J text includes "equipment upgrades".
  - Iowa's narrative says its Best and Brightest equipment grants comply "with all infrastructure and capital
    expenditure requirements", and it plans 34 of 53 equipment grants in Year 1.
  - The 58% reflects that front-loading, against a published-awards-only denominator. Nothing was mis-coded; the cap
    table stays internal.
- **(e)** `docs/owner_upload_requests.md` lists the plan URLs (CO KS OH NH FL NJ) and the MA pages.
- **(f)** The "By use category" sheet adds table 6: award dollars touching each group. It is non-additive and never
  summed.

**Coverage, 11-25:**

| Basis | Share of award dollars |
|---|---:|
| AWARD_SOURCE | 1.2% |
| INITIATIVE_CROSSWALK | 70.2% |
| CMS_REPORT_HEADING | 5.6% |
| PURPOSE_TEXT | 5.1% |
| NOT_STATED | 17.8% |

## Task 8: rebuild

Order: R/09b --apply, R/07 --apply, R/11 --apply, R/03aw --build, R/03ar --build (re-stated to 2,390 /
$2,297,215,524.33 / 43), R/08 --build, R/09c --xlsx, R/08b --build 2026-11-25. Outputs:
- `output/year1_summary_2026-11-25.xlsx`
- `output/verified_vendor_list_2026-11-25.xlsx`
- `output/completed_states_2026-11-25.{xlsx,html}`

test_08, test_11 and the CLAUDE.md table tests are re-pinned.

**Fixes made along the way:**
- KY use-crosswalk rules and five independent-check rows were keyed on FSRS row numbers that the new filings shifted.
  They are re-keyed by awardee and amount.
- A float-order tolerance in test_11 was corrected.

## Calls made under the standing rules (each reversible)

1. TX `-27` FSRS records held as not-Year-1 (the state's list prints the Year 1 subset).
2. SD's 15 post-10-30 FSRS filings held; the completion statement covers register agreements, and these are not on the
   archived register.
3. War Memorial $1M written (a first-tier state subaward; the overlap with WVU CCG is not shown).
4. Linton Hospital Foundation typed a hospital (§7).
5. NY contract maximums held from the verified list (they exceed the state's award).
6. MO's "committed $216 million" not read as COMPLETE.
7. Hospital-Based Wellness Equipment (ND) not hospitals-only.
8. WY probe baselines kept separate from the extraction sources.
9. Iowa's J coding kept.

## Open for the owner

- NY's Open Book contract maximums ($630.8M).
- MO's completion statement.
- SD's 15 filings (27RHT00126-142).
- ME's doubled re-filings and KY FHKY's re-filing: confirm the FSRS amendment reading.
- 25 unreviewed FSRS candidates ($19.1M) and 6 HOLD crosswalks (County of Franklin, Coeur d'Alene Tribal Health
  Authority, Ward Memorial, Yoakum Community Hospital, Martin County HD, City of Wagoner).

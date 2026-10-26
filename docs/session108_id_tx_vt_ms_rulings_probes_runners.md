# Session 108 — ID, TX, VT and MS extracted; three rulings; probe fixes; three runners moved

2026-10-26. Branch `claude/bold-bell-9l7mgj`, started from `main` at `b202bac` (session 107 merged).
No Year 2 work was done, and no CMS release read this session announces FY2027 amounts.

## Hospital partition, before and after

The three buckets are never added together. Published figures leave `SOURCE_SUSPECT` rows out (session 102 ruling).

| Bucket | Before (session 107) | After (session 108) |
|---|---|---|
| NAMED_HOSPITAL | 1,585 / $1,439,954,278.58 / 34 states | **1,774 / $1,646,229,714.56 / 35 states** |
| POOL_NAMED_HOSPITALS | 8 / $86,555,171.43 | 8 / $86,555,171.43 |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | 5 / $69,323,109.17 |

- **Internal figure** (SOURCE_SUSPECT rows included): 1,587 / $1,443,409,699.58 becomes **1,777 / $1,650,195,072.06**. The new suspect row is TX's Anson Hospital District, $509,936.50.
- **Rural cut** (`R/03ar`): 411 / $367,063,056.72 becomes **518 / $500,658,034.24**. ID adds 42 / $79,078,939.69, TX 43 / $42,184,742.57, VT 14 / $10,055,239.34 and MS round 2 8 / $2,276,055.92, all on CAH or REH CCNs.

### By state

| State | Before | After | Change | Subtractable inside the new figure |
|---|---|---|---|---|
| **ID** (new) | 0 | 48 / $85,389,815.69 | +48 / +$85,389,815.69 | LOW 15 / $9,027,261.00. Of that, St. Luke's Health System (system parent, GENERAL_KNOWLEDGE) is $3,672,157. |
| **TX** | 208 / $119,558,582.13 | 284 / $189,124,104.63 | +76 / +$69,565,522.50 | Intents 158 / $106,059,670.95; LOW 90 / $58,965,817.23 |
| **VT** | 53 / $45,580,691.26 | 84 / $75,513,793.13 | +31 / +$29,933,101.87 | LOW / GENERAL_KNOWLEDGE 9 / $15,576,824.59. This includes University of Vermont Health at $8,265,083.59. |
| **MS** (round 2, new file) | — | 30 / $22,886,995.92 | +30 / +$22,886,995.92 | LOW 5 / $5,615,592. This includes UMMC Greenwood $4,320,032 (an AHC bridge) and Memorial Health System $219,120 (a system parent). |
| NY (ruling b) | 35 / $47,358,790.79 | 34 / $45,858,790.79 | −1 / −$1,500,000 | — |
| OH (ruling c) | 22 / $0 | 27 / $0 | +5 / $0 | — |
| **Total** | | | **+189 / +$206,275,435.98** | |

## Task 1: the four held rosters, extracted

### (a) Idaho: `R/03ck` (new), written by `R/03am`

**What the rows are: awards.** They are not intents, and not allocations to eligible entities, so there was no reason to stop.
- **The page's own words.** DHW's funding page (last updated 10-21-2026) heads the section "Closed and awarded funding opportunities" and links "See the list of awardees as of Oct. 16". It says the year is "in the award and procurement process".
- **The workbook.** Its columns are Type, Solicitation Name, Sub Recipient / Contractor / MOA_MOU Holder, and Amount. Every line names a recipient and a figure. No line names a class, and the word "intent" appears nowhere.
- **Coding.** `validation_source_type = NOTICE_OF_AWARD`, as an agency award list (South Carolina's precedent). Execution is not stated.

**Reconciliation.**
- **No printed total exists.** The workbook has no total row and the page prints no figure.
- **The file's own sum.** 114 lines sum to **$180,701,813.99**. Session 107's "$180,701,814" rounded it.
  - Subrecipient: 100 lines, $125,412,900.01
  - Contractor: 12 lines, $32,388,913.98
  - MOA/MOU: 2 lines, $22,900,000.00
- **The two MOA/MOU lines are kept out of the award file.** They are OSBE GME ($8,000,000) and the Idaho Military Division NG-911 ($14,900,000). Both are inter-agency memoranda, on Vermont's GMCB footing (owner decision, session 54). They are status rows.
- **The award file.** 112 lines, $157,801,813.99. Against Idaho's $185,974,368 allotment, the list as a whole is 97.2%.

**Typing.** Rows were typed on CMS ID Hospital (09-25), FQHC and RHC (fetched this session to `federal_records/2026-10-26/`).
- **Exact records, MEDIUM.** These cover Gritman, Steele Memorial, Benewah, Valor Health, Syringa and the other CAHs.
  - "Syringa Hospital and Clinics" is the RHC DBA of a legal entity CMS also enrols as a CAH (131315). §10.2's enrolled-operator row therefore applies.
- **System parent (LOW, GENERAL_KNOWLEDGE).** St. Luke's Health System, three lines, $3,672,157.
- **Hand-read bridges (LOW).**
  - St. Luke's Magic Valley: the entity holds two CCNs, so none is put on the row.
  - Bear Lake Memorial Healthcare: 131316.
  - St. Mary's Hospital Health: 131321.
  - Clearwater Valley Hospitals and Clinics: 131320.
- **Unclear, in no bucket ($18,353,321).**
  - The Hospital Cooperative and Hospital Network of Idaho: hospital networks whose onward flow is not shown (WSHA's shape).
  - Public Consulting Group, the "Third Party Administrator for Ladder Payment Program" ($14,520,000): its payees are not named (§0.3).
- **Lifeways** ($163,500) is the exact legal name of LIFEWAYS INC, which CMS enrols as LIFEWAYS HOSPITAL (134009, psychiatric). It is typed a hospital on that enrolment (MEDIUM). This is flagged for the owner below.

**The probe is rewritten as a roster watch.**
- **The old checks would now fail.** "One awardee" and "no amount" no longer describe the page.
- **What it checks now.** The funding page must link exactly one "list of awardees as of Oct. 16" (docid 37915), and no page may name a new organisation.
- **Re-based.** The funding and about pages were re-based to 2026-10-26 copies after reading the diffs. The 09-03 copies stay.
- **Live result:** UNCHANGED.

### (b) Texas: `R/03ce`, the 10/23 list

- **The list.** 441 lines, Year 1 $224,591,245.41, 159 executed. 129 lines were added on Oct. 23, worth $87,248,124.
- **Format changes.** The list now prints sub-initiatives (1.1, 1.2, 4.1, 4.2, 6.1), stored as floats. The reader keeps the major number in `initiative` and the printed one in `sub_initiative`.
- **Supersession is asserted.** Every 10/8 and 10/14 line shape is on the 10/23 list, with one recorded re-pricing: Memorial Hospital (Dumas) moved from $371,453.99 / $113,739.00 to $724,952.00 / $221,980.30.
- **HHSC corrected names between lists.**
  - "UT Health Carthage" is now "Carthage Hospital, LLC", now an exact record.
  - "Center for Life Resources" is now "Central Texas MHMR Center".
  - **Winnie Stowell Hospital District's line now names GHC Hemphill Operations, LLC.** The two amounts match to the cent, so HHSC re-attributed the line rather than adding one.
- **Three lines contradict themselves and are SOURCE_SUSPECT.** On each, the Year 1 Subset exceeds the Total Award Amount. The ratio is Initiative 6's (51.49%) read backwards, so the two columns look transposed. They are carried as printed and left out of published figures:
  - AultMcInnis PLLC
  - Border Region MHMR
  - **Anson Hospital District ($509,936.50)**, the only hospital row of the three
- **The county test now uses the list's own County column** (owner instruction).
  - A classifier-hospital line with no exact record and no hand bridge is bridged only where exactly one enrolled hospital CCN sits in that county (LOW).
  - An exact name that several legal entities carry is settled the same way.
  - **"Memorial Hospital" is now placed in Moore County**, which has one enrolled hospital: CAH 451386, LOW. Session 104's no-CCN ruling is therefore resolved by the state's own field, and the row enters the rural cut.
  - New county bridges: Haskell County HD ×2 (451341), Hopkins County HD (450236), Sabine County HD (451361), CHRISTUS Spohn Beeville (Bee County) and Memorial Hospital (Dumas).
  - Menard County HD is not bridged, because Menard County has no enrolled hospital.
- **The County field is not always the hospital's county.** On 37 hospital rows it disagrees with CMS's county for the row's CCN. It often holds a city (Winnsboro, Alice, Rotan) or a service county (Shannon Medical Center is printed in Howard County). So the field is used only as a test that can **refuse** a bridge, never as the sole basis for one where an exact record exists. The six session-104 county bridges all agree with it (`tx_rts_assert_list_county()`).

### (c) Vermont: `R/03at`, the 10-23 update

- **Constants bumped.** 237 rows, page total $180,171,067.00, "Updated as of October 23, 2026", archive `recheck/2026-10-26/VT/`, prior `recheck/2026-10-15/VT/`.
- **The delta.** 62 new agreements, $49,113,439.73. Every 10-08 agreement is still printed at its cents.
- **14 agreements were re-spelled.** A name-first key reads them as 14 gone and 14 added. Each pairs with one new row of the same initiative, activity and amount.
- **One re-spelling moves a typing.** The $1,008,012.12 facility-upgrade agreement was printed "Gifford Medical" through 10-08. That string was a LOW hand bridge to the hospital, CAH 471301. It is now printed "Gifford Health Care", the FQHC's legal name (471852). The recipient as printed is the FQHC, so it leaves the hospital figure. This is recorded on the status table as `AGREEMENT_REPRINTED_OTHER_RECIPIENT`.
- **New hospital typings.**
  - On CMS enrolment: Copley, NVRH, North Country and Mt Ascutney.
  - **University of Vermont Health** (three agreements, $8,265,083.59) is the 2025 trading name of the UVM Health Network. It is typed as a system parent: LOW, GENERAL_KNOWLEDGE, subtractable.
- **Live probe:** UNCHANGED against the new archive.

### (d) Mississippi: `R/03cj` (new), the Governor's 10-21 roster

- **The roster.** 60 awards, **$32,606,496.32, to the cent**, in five sections: Workforce Recruitment 20, Secondary Education 4, Preceptor 12, Earn While You Learn 21, and Psychiatric Emergency Services 3.
- **Why a separate file.** `ms_round2_awardees.csv` stands alone because R/03ak's rows carry the row-index overlays from sessions 49 and 50.
- **The three EmPATH units are typed to their host hospitals:**
  - Merit Health Central/Jackson MHA, LLC ($4,500,000): the "Merit Health Central" half is the DBA of JACKSON HMA LLC, 250072. The release's "MHA" transposes HMA.
  - Memorial Hospital at Gulfport ($4,496,000): 250019, exact.
  - UMMC Greenwood Hospital ($4,320,032): no CMS record carries the string. The only enrolled hospital in Greenwood is GREENWOOD LEFLORE HOSPITAL (250099), and UMMC is itself an enrolled hospital operator. So this is a LOW hand bridge, `recipient_subtype = ACADEMIC_HEALTH_CENTER`. None of the three is Unclear.
- **Other hand reads.**
  - LOW bridges: Baptist Memorial Hospital-Yazoo (251313), Baptist Memorial Hospital-Oktibbeha (250050) and South MS State Hospital (254008).
  - Memorial Health System is a system parent.
  - **Magnolia Regional Health Center EMS ($100,000) is not bridged.** It is a hospital department, and the owner's WVU Eye Institute ruling added no department-name rule. It is typed EMS and queued.

## Task 2: rulings applied

- **(a) WV.** The "more than $2.5 million" CCG row stays at $2,500,000, flagged AMOUNT_ROUNDED_IN_SOURCE as a floor. That was already the row's coding; the ruling is now recorded in its `amount_basis`.
- **(b) NY, Glens Falls Hospital/ Hudson Headwaters ($1,500,000).**
  - **The row.** It is kept as one row, flagged MULTI_RECIPIENT_FIELD, coded PASS_THROUGH_UNRESOLVED / Unclear / NOT_HOSPITAL, and is in no bucket. This is Oregon's multi-recipient shape.
  - **The ceiling.** It is counted in the ceiling only (R/03aw's `share_ceiling` adds priced Unclear rows).
  - **The reader.** R/03ag now reads DOH's project-grain list (107 lines, $76,190,022, 55 leads) and reconciles it lead by lead to the 56-row lead list. The award rows still come from the lead list.
- **(c) OH, the 13 network and maternal-care listings, at $0, each typed** (one row per listing; eight organisations).
  - **Hospitals (5 rows):** University Hospitals Health System (system parent, LOW); Beavercreek Medical Center (Soin, 360360) ×2; Mercy Health–St. Rita's (360066) ×2.
  - **Networks (Unclear):** Ohio High Value Network ×2 and Ohio State Health Network ×2, on WSHA's shape.
  - **Non-hospital:** OACHC ×2, Child & Family Health Collaborative and Ohio Health Institute.
  - **The pools.** The two shared pools stay out of every bucket.

## Task 3: probe fixes (each diff read; each live run UNCHANGED after the fix)

| Probe | Fix | Live after |
|---|---|---|
| **MS newsroom** | `ms_assert_no_new_rhtp_headline()` trips on any RHTP headline link not in `MS_KNOWN_RHTP_HEADLINES`, whatever its verb. The fixture test uses the 10-21 headline: with session 107's knowledge it trips, and the old phrase check passes it, which was the miss. `funding` and `home` were re-based (an "Apply for the EHR Program" link; a survey date). The newsroom was re-based to a new file; the 09-21 copy stays for the historical tests. | UNCHANGED. `dom_completed` is ERROR: medicaid.ms.gov's SSL certificate chain, which is our access. |
| **VA VHHA Foundation** | vhhafoundation.org redirects to vhha.com. The page is re-pointed to `vhha.com/foundation/rural-health-transformation/`. It no longer prints an award date, so the anchor is the Foundation's future-tense role sentence ("will administer key initiatives ..."). | UNCHANGED (all five pages) |
| VA ways_to_apply (found while fixing) | The partner table adds **five Regional Collaboratives** on Mobile & Hybrid Care, each with an Open RFA: first-tier administrators, not awards. The page was re-based and the five are recorded below. | UNCHANGED |
| **CA page anchor** | The anchor broke because HCAI put **"Latest News: CalRHT Awardees Announced"** above the RHTP heading. The scope now admits that block. The "updates" page is added to the probe with a roster pin (108 rows / $138,464,043.97). `calrht`, `funding` (Tribal Set-Aside, Tier 2; an FM-OB label) and the newsroom were re-based. | UNCHANGED (four pages) |
| **NY header** | Parses the 6-column project-grain header; see ruling (b). `press_index` and `scr` were re-based (no RHTP item). | UNCHANGED (four pages) |
| **OH "haven't been announced yet"** | The sentence went on 10-21, replaced by a News Release link. The check is now on ODH's two recipient lists, compared whole. The `odh` programme page was re-based; it now carries a link list of the resource pages. | UNCHANGED |
| **KY furniture** | FHKY's "Employment Opportunities" job titles (two forms of the run). `rch` and `chfs_grants` were re-based: Community Paramedicine left, and a new Tier 2 RHTP RFA was added, "Rapid Response to Recovery: Transportation Support", for the 14 CMHCs. | UNCHANGED |
| **WI furniture** | Six new solicitation titles. Each detail page was read: "Rural Health Transformation" appears once on each, as the DHS menu. They are Title V, Title X, a CHIP HSI Asthma grant (CMS money that is not RHTP: the §0.1 trap) and the ASPR Hospital Preparedness Program. Two breadcrumb runs on `dhs_rhtp` were also added. Both pages were re-based and the manifest regenerated. | UNCHANGED |
| **ID** | Rewritten as a roster watch (Task 1a). | UNCHANGED |

## Task 4: runners

- **Moved.** SD (751,763 tokens), WA (676,618) and VA (664,020) each have a new runner, configured like the old one: `env_01RnpqJ1D6wFAaRMvFu43oV3`, claude-sonnet-5, auto, `main` as source and outcome, no seed.

  | State | Old runner / Routine | New runner / Routine | First firing |
  |---|---|---|---|
  | SD | `session_01Pk7gQk…` / `trig_01PozmJvhJnKHVQf7GBHkbvY` | `session_01QHHpt7NN1dimuR6gPKv5PP` / `trig_01F8Bh62cRmxEshC3Ua2iwPB` | Thu 10-29 12:20Z |
  | WA | `session_01D79su1…` / `trig_01Ya2pEVp2p89TYntNPhjpX1` | `session_018ne5w5BV6MRSxQUsbNwJKa` / `trig_0158cE6E2ZBK6R7bte3EygBY` | Thu 10-29 10:10Z |
  | VA | `session_01WPX6i1…` / `trig_017UtAGMofDhy3h8kpVmmiEx` | `session_014csJ7L2BJQzET7NqfMYxCu` / `trig_01BUzx8AnvNR9kVkYKkfovDe` | **Tue 10-27 10:20Z** |

- **Prompts.** `runner_moves.csv` gained SD and WA rows. VA's row now points from its v3 runner to the new one; the intermediate runner `session_01WPX6i1…` is in `routines.csv`'s chain. `R/routine_prompts_worktree.R --write` changed only the three runner ids (`git diff` shows nothing else), and `--check` reads "v4 matches derived for 43 states". The stored prompts were read back with `list_triggers`; each is the v4 file.
- **Old Routines.** All three are **disabled, not deleted**, and chained in `routines.csv`. A check-in at **Thu 10-29 14:30Z** (`trig_014ALqpHqrs3SYKQRvN7HFA4`) deletes each once its successor has logged on `main`. `probe_coverage.R --check`: 251 due firings, all logged except 6 explained.

## Owner decisions this session leaves open

1. **California has published a tentative roster. It is HELD, not extracted** (it was outside this session's approval).
   - **Where.** HCAI, "Recommended Subrecipients for CalRHT Budget Period 1 Announced", 10-21. Archived at `data/evidence/CA/2026-10-26_*RECOMMENDED_SUBRECIPIENTS.html` and `recheck/2026-10-26/CA/`.
   - **What it holds.** 108 rows, **$138,464,043.97 as printed**, against the prose's "$166.72 million for 108 organizations". About 54 rows / about $76.4M are hospital-shaped by name.
   - **Status.** HCAI calls the awards "tentative ... Funding will not be finalized until ... fully executed". So they are intents (AMOUNT_PRELIMINARY).
   - **What is still unexplained.** The $28.3M gap against the prose figure may be the "milestone-based hospital investments", which are unpriced.
2. **ID typings to confirm:**
   - Lifeways ($163,500): a hospital on its psychiatric-hospital enrolment.
   - The two hospital networks and the ladder-payment TPA: Unclear, $18,353,321.
   - The MOA/MOU lines kept out of the file ($22.9M).
3. **MS: Magnolia Regional Health Center EMS ($100,000).** It is a hospital's EMS department, typed EMS on the WVU Eye Institute precedent. It would move one way only.
4. **MS round 1 vs round 2.** R/03ak types "Memorial Health System" MEDIUM on its name ($650,000 + $2,980,874). R/03cj types the same string as a system parent, LOW. The round-1 rows were not re-typed.
5. **VT: Gifford's $1,008,012.12 now reads as the FQHC.** Confirm that the latest list governs.
6. **TX.**
   - The three SOURCE_SUSPECT lines.
   - GHC Hemphill Operations taking Winnie Stowell's line.
   - The County field being a city or a service county on 37 hospital rows.
7. **VA: the five Regional Collaboratives** (Mobile & Hybrid Care first-tier administrators, Open RFAs). Add them at $0 to `va_year1_awardees.csv`, or keep them as context.

## Merge timing

- **Merge before Tue 10-27 10:20Z.** That is VA's first firing on its new runner; until `routines.csv` on `main` carries the new id, its line reads as unregistered. ID's next firing is 12:40Z, and `main`'s old ID probe would trip on the roster.
- **Never merge Mon/Thu 13:00–14:00Z.** If the branch misses Tuesday, merge it before Thu 10-29 13:00Z.

## Suite

See the CLAUDE.md "Last updated" line for the final count. Runs are recorded below as they completed.

# Session 99 (2026-10-12): Louisiana for the LHA meeting, three rosters, NE lines, probe fixes, five runners

**Branch:** `claude/inspiring-bell-qt78fl` (from `main` at `d30ca55`, session 98 merged).

## Hospital partition, before and after

| Bucket | Before (session 98) | After (session 99) | Change |
|---|---:|---:|---:|
| NAMED_HOSPITAL | 1,313 rows / $1,216,466,199.99 / 32 states | **1,325 / $1,225,134,515.58 / 32** | +12 / +$8,668,315.59 |
| POOL_NAMED_HOSPITALS | 2 / $30,806,856.12 | 2 / $30,806,856.12 | 0 |
| POOL_UNNAMED_HOSPITALS | 4 / $69,323,109.17 | 4 / $69,323,109.17 | 0 |

The buckets are never added.

| Source of the change | Rows | Dollars | Notes |
|---|---:|---:|---|
| SD register, 10-12 | +3 | +$7,789,960.00 | All three are hand-read CMS enrolment bridges at **LOW** |
| AK rolling notice, 10-12 | 0 | +$446,104.96 | Revisions to existing hospital rows |
| OK Behavioral Health Integration | +1 | +$90,171.53 | Mercy, system parent, LOW, general knowledge |
| OK EMS / Community Paramedicine | +6 | $0 | No amounts published |
| NE CMS infection-prevention lines | +2 | +$342,079.10 | `CMS_OBLIGATION_REPORT`, subtractable |
| **Total** | **+12** | **+$8,668,315.59** | |

**What can be subtracted:**
- `basis_type = GENERAL_KNOWLEDGE` covers the three SD bridges, Mercy (OK BHI) and INTEGRIS Miami (OK EMS/CP).
- `validation_source_type = CMS_OBLIGATION_REPORT` now covers 7 named rows / $3,466,480.59. Five of them, $3,124,401.49, are session 98's.

---

## Task 1: Louisiana (for the LHA meeting)

### (a) "LA's two new lines" in the session 98 probe log

They come from CMS's release of **2026-10-09**, "$37.7 Million to Train and Recruit More Rural Healthcare Workers Across Louisiana". The CMS Routine archived it under `data/raw/cms/2026-10-12/newsroom/releases/`. LDH published its own version a day earlier, on **2026-10-08**: "Louisiana invests $37.7 million to strengthen rural health care workforce", now archived at `data/evidence/LA/sr198/2026-10-12_la_ldh_news_2026-10-08_rhtp_y1_workforce_37_7m.html`.

| Line | Programme | Amount | Recipients | Dates | Source wording |
|---|---|---|---|---|---|
| 1 (new) | **Rural HERO** (Rural Healthcare Employment Reinvestment Opportunity) | **"up to $20 million"**, a ceiling | Campus programmes through the "four public postsecondary systems: the LSU System, Southern University System, University of Louisiana System, and Louisiana Community and Technical College System". Each participating campus "will partner with at least one rural health care provider". **No campus is named.** | "Programs will begin in October 2026 and continue through September 30, 2029" | CMS: "up to $20 million to connect Louisiana's public universities and community and technical colleges with rural healthcare providers" |
| 2 (new) | **Grow Your Own** | **"up to $5 million"** | Administered through LCTCS, "healthcare career pathways across 39 campuses". **No campus is named.** | Not stated | CMS: "The additional $5 million will create healthcare career pathways across 39 campuses" |
| (carried) | Rural Clinician Credit Bank | $12.7M to 53 providers | Already in `la_year1_awardees.csv`; CMS adds no names | As of 8/28/26 | |

- **Hospital figure:** neither new line touches it. The recipients are universities and colleges, which are never a hospital type, and a partner provider is not a recipient (§7).
- **Status rows:** both lines are now rows in `la_year1_status.csv`, with stage `ANNOUNCED_NO_RECIPIENT_NAMED`.
- **Tier 1 footer:** LDH's release carries a footer of $208,374,447.57. That is Louisiana's allotment.

### (b) Senate Resolution 198

**The resolution.** SR 198, 2026 Regular Session, Sen. Mizell. It was adopted 2026-06-01 by 36–0, never referred to a committee, and sent to the Secretary of State on 6/2. It "urge[s] and request[s]" LDH to report "to the Senate":

> "(1) No later than October 15, 2026, a report that provides the proposed program expenditures for federal Fiscal Year 2026-2027 … BE IT FURTHER RESOLVED that the reports shall include identification of recipients of funding and the amount of funding allocated, measurable outcomes, benchmarks, and progress in improving rural health outcomes."

A second report, on actual FY2026-27 spending and proposed FY2027-28 spending, is due 2027-11-01.

**Points to raise at the meeting:**
- **It is a Year 2 plan, not a Year 1 award list.** It covers *proposed* FFY2026-27 spending and "funding allocated". Any recipient it lists is a lead, Tier 1 or Tier 2, until an award document says otherwise (§0.2, §0.3).
- **It names no posting location and no committee.** R.S. 24:772(A)(1) has the agency e-mail the report to the Poynter Legislative Research Library, which lists it to members. That is distribution, not publication. **Whether the report will be public at all is UNKNOWN.**
- **It is non-binding** ("urge and request").
- **One whereas clause is a state paraphrase of the deadline:** "all RHTP funds must be used by end of the federal fiscal year following the fiscal year in which funds were allotted". See Task 5a.

**What was archived.** Everything is under `data/evidence/LA/sr198/` with a `MANIFEST.txt` of SHA-256s:
- the enrolled resolution (`33c47367…`)
- the résumé digest
- the vote
- the bill page
- R.S. 24:772
- LDH's 10-08 release
- LDH's 2026-10-01 monthly-webinar deck

**Where the report would appear, and the probe on it.**
- LDH lists its reports to the legislature on its **Legislative & Governmental Relations** resources page, `https://ldh.la.gov/resources/category/legislative-governmental-relations`. Entries are newest first, each named by its requesting instrument (e.g. "HCR 2, 2025 Regular Session"). On 10-12 it names SR 198, "Rural Health Transformation" and "RHTP" zero times. The newest entry is the LaCHIP Annual Report of 2026-08-26.
- That page is now `R/03ae`'s `leg_reports` probe key, archived as `data/evidence/LA/2026-10-12_la_ldh_legislative_reports_index.html`.
- `la_assert_no_sr198_report()` trips on any new mention of SR 198, "Rural Health Transformation" or "RHTP". The tests show it firing on four phrasings and silent on the archive.
- No legislature-side reports page exists: `/legis/ReportsSearch.aspx` and its siblings 404, and the Poynter catalogue is a session-bound JavaScript app.

**One-time check.** It is set for **2026-10-16 14:07Z** (`send_later`, `trig_01FsAscqmwDLG7w4UNEWLmdL`). It fires into this session and:
- runs the LA probe,
- checks the LDH RHTP page, LDH news and the bill page,
- archives and reads any report found, extracting nothing without your approval.

### (c) The Rural Clinician Credit Bank, from `la_year1_awardees.csv` and the archived LDH deck

**Credit Bank total: $12,701,996 across 53 awards, "As of 8/28/26".** Source: LDH stakeholder webinar deck of 2026-09-03, archived as `data/evidence/recheck/2026-09-24/LA/2026-09-09_la_ldh_rhtp_stakeholder_webinar_RCCB_53_AWARDS.pdf`, SHA-256 `80d73683…`.
- Figures: "$10.0M advertised, $12.70M awarded"; 136 applications, 70 eligible, 53 awards.
- Rounded to the nearest $0.1M this is the "$12.7M" in CMS's release.

**The hospital breakdown is exact.** The deck's "Funded facilities by type" table:

| Facility type | Awards | Amount |
|---|---:|---:|
| Small rural hospital | 8 | $3,291,553 |
| Critical access hospital | 11 | $2,948,962 |
| Rural emergency hospital | 1 | $45,000 |
| **Hospital settings** | **20** | **$6,285,515** (49% of dollars) |
| Clinic and outpatient settings | 33 | $6,416,481 |

The three hospital lines sum to $6,285,515 to the dollar, and `R/03ae`'s test asserts the 8/11/1 split.

**These 20 hospital awards are in no hospital bucket.** LDH names none of them, and the facility type is a setting, not the recipient (§7, "a count of hospital awards with no names").

**The five named recipients** are the deck's "Multi-parish awardees" table:

| Awardee | Parishes | Award | Our coding |
|---|---:|---:|---|
| Ochsner Clinic Foundation | 8 | $1,500,000 (the "ceiling applied per multi-entity system") | HOSPITAL_OR_SYSTEM, CMS enrolment CCN 190036 (EXACT_LEGAL_NAME), MEDIUM. The only LA named-hospital row |
| Outpatient Medical Center | 6 | $292,500 | §8 fallback, not a hospital (classifier's "Medical Center" refused) |
| Winnsboro Medical Clinic | 7 | $116,288 | §8 fallback |
| SR Minden, Southern Roots | 4 | $45,000 | §8 fallback; one awardee string, not split |
| LaBorde Therapy Center | 4 | $12,000 | §8 fallback |
| **Named total** | | **$1,965,788** | The other 48 awards, $10,736,208, are one unnamed aggregate row |

**Signed agreements are NOT confirmed anywhere.**
- The deck says "CEAs due for signature 9/15/26".
- LDH's programme page (live 10-12) shows only "Notice of Intent to Contract Announcements: Completed".
- LDH's 10-08 release says "is awarding up to $12.7 million … Fifty-three providers were selected".
- LDH's 2026-10-01 monthly-webinar deck (now archived) gives "**CEA / contract completion: Current – October 30th**" for all strategies.
- No source says an RCCB agreement was executed.
- So every RCCB row stays `amount_confirmed = No`.

**Vulnerabilities, for the room:**
- The **$12.7M is a figure awarded as of 8/28**, not executed or paid.
- **Ochsner's $1.5M is a system-level award**, capped by LDH. The hospital typing rests on Ochsner Clinic Foundation's CMS enrolment.
- **The 20 "hospital-setting" awards cannot be attributed to named hospitals** from any public source.

---

## Task 2: the three approved rosters

### South Dakota: open.sd.gov RHT series, 41 → 53 contracts

**Archived** with `R/03i --fetch --force`: the 2026-10-12 search archives plus 12 new detail pages.

**Changes to `R/03i`:**
- `SD_SEARCH_ARCHIVES` and the description-search baselines now include the 10-12 files.
- No contract left the register and no amount moved; `rhtp_sd_search_rows()` asserts this.

**What the 12 new contracts are ($10,203,655):**
- Four are Rural Strong grants by the register's own description: 27RHT00027, 00048, 00049 and 00051.
- The other eight name no round. Each was placed by hand in `SD_PLACEMENT` as UNPLACED after reading its detail page.
- Rural Strong is now 18 contracts / $25,012,010, inside the $31.5M round.
- Unplaced is now 16 / $4,334,717, capped at the $90M round.
- Two pages print a mistyped CFDA number: '73.798' on 00027 and '97.798' on 00052. The test pins both.

**Three hospital rows, each on a hand-read CMS enrolment bridge (`SD_ENROLMENT_BRIDGES`, LOW):**
- **Why bridges were needed.** The register truncates vendor names at 30 characters, so the exact city-keyed matcher could not reach them.
- **How they were built.** Each CCN and provider type is read from the archived CMS SD enrolment file at build time. A bridge whose record is not exactly one row fails the build.
- **Precedent.** `basis_type = GENERAL_KNOWLEDGE` follows the OK RRR precedent.

| Contract | Register string | CMS record | CCN | Bridge | Amount |
|---|---|---|---|---|---:|
| 27RHT00048 (Rural Strong) | MONUMENT HEALTH RAPID CITY HOS | MONUMENT HEALTH RAPID CITY HOSPITAL INC | 430077 | LEGAL_NAME_TRUNCATED | $6,361,000 |
| 27RHT00051 (Rural Strong) | AVERA HEART HOSPITAL OF SD LLC | HEART HOSPITAL OF SOUTH DAKOTA LLC (dba AVERA HEART HOSPITAL OF SOUTH DAKOTA) | 430095 | DBA_OF_LEGAL_ENTITY, **LOW as instructed** | $1,297,500 |
| 27RHT00043 (unplaced) | PRAIRIE LAKES HEALTH CARE SYST | PRAIRIE LAKES HEALTH CARE SYSTEM INC | **430005A** (as CMS publishes it; not six digits, so Stage 5 must resolve it) | LEGAL_NAME_TRUNCATED | $131,460 |

**SD contracts file is now:** 53 / $37,039,799; hospital 17 / $24,433,212.

**A rebuild side effect, and how it was handled.**
- Rebuilding would have lowered the six name-typed HIGH rows that carry an exact CMS CCN to MEDIUM. That is the session-88 classifier ceiling.
- Session 88 had kept them HIGH, so `R/03i` now restores HIGH only where a HIGH name pattern and an exact CCN coincide, through `rhtp_confidence_ceiling()`.
- The only residual diff on those rows is the "Machine answer … /MEDIUM" text, which session 89 noted as text-only.

### Alaska: rolling refresh to the 2026-10-12 notice

**Snapshot roll.**
- `AK_PRIOR_FILE` → 09-28.
- `AK_AWARDS_FILE` and `AK_CYCLE_UPDATE_FILE` → 10-12.
- `AK_CMS_ANCHOR_FILE` is untouched.

**What changed in the notice:**
- 254 rows / $248,976,547.51.
- **5 new actions, $4,843,430.79, none a hospital:** Alaska Municipal League, Girdwood Health Clinic, Orca Labs, Yukon Koyukuk Elder Assisted Living Consortium and the Division of Behavioral Health (DOH).
- **19 revisions, net +$1,512,375.57.**
- No withdrawals.

**Hospital: 45 / $69,816,743.96, +$446,104.96, no new rows.**
- PeaceHealth Ketchikan +$449,699.34.
- YKHC IA-362 +$14,168.51.
- Providence −$17,762.89.

**Verification answers re-applied by award ID.** Session 49's eight AK overlay rows were re-keyed in `verification_queue_2_changes.csv` from row index to their App IDs' new rows, by byte-wise edit:

| App ID | Row before → after |
|---|---|
| BP1-IA-074 | 153 → 74 |
| BP1-IA-108 | 239 → 77 |
| BP1-IA-288 | 227 → 92 |
| BP1-IA-245 | 238 → 172 |
| BP1-IA-277 | 240 → 213 |
| BP1-IA-351 | 144 → 218 |
| BP1-IA-352 | 247 → 219 |
| BP1-PL-019 | 191 → 253 |

The overlay was then applied to the AK file only, followed by `R/03bj --apply`. Every other state file came back byte-identical.

**Two code defects the refresh surfaced, both fixed:**
- **The cycle-update PDF changed layout.** "Project Awards" now spans two lines, and Week 8's label prints after its figures. `rhtp_ak_cycle_weeks()` reads both forms, takes the trailing form only from unconsumed text, and parses the 09-28 copy identically.
- **The "rolling weekly basis" sentence is gone.** The new wording, "more award announcements in the coming weeks", is accepted as the same model.

**One non-hospital re-type.** healthEconnect Alaska is now VENDOR_OR_CONTRACTOR, because Alaska's own Organization Type field now reads "Health Information Exchange (HIE);Non-Profit…". It is not a hospital either way.

### Oklahoma: two new rosters and the Keetoowah withdrawal (`R/03cc_ok_bhi_ems_rosters.R`, new)

**Archive.** `data/evidence/OK/new_rosters/2026-10-12_ok_rhtp_funding_recipients.html`, SHA-256 `e000ef82…`. The URL now redirects to `oklahoma.gov/rhtp/…`, and the page reads "Last Modified on Oct 12, 2026". It passed `ok_assert_credential_free()`.

**RRR: 20 → 19 / $38,455,023.**
- Keetoowah Economic Development Authority ($1,123,500, §8 fallback, not a hospital) is recorded in `OKN_RRR_WITHDRAWN`.
- `okn_rrr_now()` asserts the 10-12 roster equals 10-02 minus that entry, and nothing else.
- Hospital is unchanged at 10 / $21,099,804.
- Doulas and CDM are unchanged between the two copies; this is asserted, and they stay on the 10-02 archive.

**Behavioral Health Integration (`ok_year1_bhi_awardees.csv`): 3 / $1,228,012.70.**

| Recipient | Amount | Typing |
|---|---:|---|
| OSU-CHS | $137,841.17 | UNIVERSITY_OR_AHC. OSU's hospital enrols under a different body, OSU Medical Trust, CCN 370078 |
| **Mercy Health Oklahoma Communities** | **$90,171.53** | HOSPITAL_OR_SYSTEM, system parent, LOW, GENERAL_KNOWLEDGE, no CCN: R/03bt's owner-instructed typing |
| Andor Health, LLC | $1,000,000 | §8 fallback |

**EMS / Community Paramedicine (`ok_year1_ems_cp_awardees.csv`): 51 lines, no amounts.**
- The lists are 38 ambulance-funding lines and 13 vehicle lines.
- OSDH prints no dollar figure anywhere in the section; this is asserted.
- "Town of Cheyenne" is printed twice in the ambulance list. Both lines are kept and the second says so.
- Five organisations are in both lists.
- **Six hospital rows, all at $0:**
  - The Choctaw Nation of Oklahoma: 370172, owner's session-87 resolution.
  - INTEGRIS Miami Hospital, printed as "Baptist Healthcare of Oklahoma, LLC d/b/a INTEGRIS Miami Hospital": 370004, DBA bridge, LOW.
  - Newman Memorial Hospital, Inc.: 371336.
  - Northeastern Health System: 370089.
  - Purcell Municipal Hospital, twice: 370158.
- All exact-legal-name rows are MEDIUM, and every one carries an `R/03bj` EH_APPLY verdict.

---

## Task 3: Nebraska infection-prevention lines (`R/03cb`)

**Added to `OB_NE_PA`:**
- NE-004-18-66: Regional West Medical Center, $254,347.00.
- NE-004-19-76: Chase County Community Hospital, $87,732.10.

**Dedupe by name AND amount.**
- No amount matched to the cent.
- The name overlaps were read and recorded in `OB_NAME_OVERLAPS`:
  - Regional West = rows 55 (4.4b RPM, $736,148.14) and 89 (5.3 crisis facilities, $93,867).
  - Chase County = row 41 (4.4b RPM, $195,523.20).
- Each is a different award, and no infection-prevention pool exists in the NE file.

**Typing.** Both are EXACT_LEGAL_NAME on CMS NE enrolment, MEDIUM, with EH_APPLY verdicts:
- Regional West Medical Center, CCN 280061.
- Chase County Community Hospital, CAH, CCN 281351.

**Tags.** `validation_source_type = CMS_OBLIGATION_REPORT` and `as_of = 2026-07-31`.

**Unchanged.** The multi-recipient infection-prevention lines that also name these hospitals stay undivided (§6.2).

**File after the change.** `ne_cms_obligation_awardees.csv` is 6 / $3,977,841.09; NAMED 5 / $502,903.59.

---

## Task 4: probe fixes

### (a) Missouri: why IFB DSS26015-02 left the bid table (report only; NOT re-based)

**Verdict: UNKNOWN.** No source read shows a withdrawal, a cancellation, an intent to award or an award.

**What is verified:**
- **Before.** The row was on the 09-01 archive: "IFB # DSS26015-02 ToRCH Care Smart Growth and Service Line Modifications (Horizon-2) … August 27, 2026 / September 1, 2026 at 2pm". It had no amount or status column. Session 98 had it present on 10-07.
- **After.** It is absent from the live table (`https://dss.mo.gov/bids`, 200) on 10-12. The only new row is a non-RHTP single-feasible-source notice.
- **The IFB itself is still served and unamended.** It is still "IFB AMENDMENT #02" (Last-Modified 2026-08-27). Bids went by e-mail to the DSS buyer, not through MissouriBUYS.
- **Clauses that matter:**
  - §1.3.13: "Year 1 funds are tied to Budget Period 1, with an obligation deadline of October 30, 2026".
  - §3.2.1: "funding awards shall be made in phases … Subject to the availability and confirmation of Year 2 funds".
  - §3.1.9: maximum award $5,000,000.
  - §3.1.1: eligible bidders are "a rural hospital or health center". FQHCs and RHCs are eligible, so the class is **not hospitals-only**.
- **Plan figures.** DSS's fund-distribution page carries "Horizon 2 ($12M)" (Year 1 plan). The programme page says "nearly $40 million" (both years). The programme page is byte-identical (reduced) to its 09-23 copy.
- **No award or cancellation anywhere else read:**
  - DSS `/press`: newest items are dated 09-22, both Horizon 1 / EMS.
  - DSS RHTP pages.
  - The site map: no 26015, horizon or smart-growth URL.
  - The MHA newsroom.
  - OA's awarded-bid search returns 0. That is uninformative, because it holds no DSS-numbered bids at all.

**Not readable (UNKNOWN):**
- MissouriBUYS (an Oracle JavaScript app).
- The Wayback Machine (blocked).
- govdelivery RSS.
- The Missouri Register (not checked).

**Precedent, and the most likely reading.** The Horizon 1 (SMRP) IFB was already off the table on 09-01, and its awards appeared on 09-22. The likely reading is therefore that the bid closed, left the open table, and phased awards will follow. That is an inference, not a finding.

**What happens next.** The MO probe was not re-based, as you asked. **Its 10-14 firing will trip** on the missing row; read that trip as "closed, outcome unknown". The right fix is to rewrite the procurement check as an award watch (a DSS `rhtp-*` awardee page, DSS press, the MHA rural-health tag). That needs your sign-off.

### (b) Re-bases, each after reading its diff

| State | Diff read | Fix |
|---|---|---|
| **ND** | The funding page: seven headings flipped "Closed (N Applicants)" → "Awarded \| N Applicants" (Zero-Hour PE, Community Gardens, BH Promotion, **Train In Place**, Workforce Retention, Rightsizing, Mobile Mammography). Nobody named | "Train In Place" added to `ND_KNOWN_AWARDED` with its sentence. Funding baseline re-based to a NEW dated file, `data/evidence/ND/probe_baseline/2026-10-12_hhs_rhtp_funding.html`; the 09-23 copy stays because `R/03bh` cites it. `--fetch` refuses to overwrite |
| **KY** | The programme menu only ("Our Approved Plan" → "Our Plan, Updates and Progress"; "Reports and Documents" added) | Programme re-based to `2026-10-12_ky_ruralhealthplan_home.html`. **Then the RCH page's name tripwire fired on a real recipient**: FHKY's "Program News" names **Purchase District Health Department** as Hub Lead for the Purchase region (PDHD release, Oct 7). **Extracted** as row 2 of `ky_year1_awardees.csv` (`R/03by`): local health department, no amount; "up to $10 million" is a five-year regional ceiling, text only. $0 hospital. Big Sandy is the next name to fire. RCH baseline re-based to 10-12 |
| **WA** | The RNEP item expired, and its SUBAWARD footer went with it; an item pointing to DOH's new RHT pages was added. What We're Working On added four sub-awardee CLASS labels. Nobody named | `wa_assert_footers()` now reads the 09-23 archive, which is never overwritten and is still read by `R/03bd`. Live footers must each tier-check. Programme and working_on re-based to NEW dated files under `data/evidence/WA/probe_baseline/` |
| **WV** | USDA FNS WIC grant ($195,825), not RHTP. The rhtp and grants pages differed only by a **rotating TBMegaMenu UUID** in inline script | `WV_NOT_RHTP` excludes the WIC slug with its sentence. `wv_page_text()` drops scripts from both copies; a re-base would not have cured a rotating token. The news index is re-based to 10-12. **And the diff surfaced a missed award release:** see below |
| **VA** | VHCF re-dated Provider Productivity: Oct 14 → **Oct 15**. Nothing else on the page. `ways_to_apply` shows only status-cell churn ("Food in Medicine" → "Food is Medicine"); the partner set is unchanged and that check passes | `VA_ANCHORS$vhcf` updated, `vhcf` re-based to 2026-10-12. `ways_to_apply` was left on its 09-23 baseline. **The VA runner's pending date trip clears at its next firing once this branch is on `main`** |

**WV: an award release the tripwire missed.** The 2026-09-30 release, headlined "Governor Morrisey Announces More Than **$3.2 Million** in Rural Health Transformation **Investments**", is an award release:
- **It awards money.** It says "Today's awards …" and "The awards were made through the SmartCare Catalyst Provider Productivity Support Fund and Mountain State Care Force initiatives".
- **It names seven recipients:**
  - Stonewall Jackson Memorial Hospital
  - Mon Health Marion Neighborhood Hospital
  - Preston Memorial Hospital
  - Plateau Medical Center
  - Webster Memorial Hospital
  - Broaddus Hospital
  - Vandalia Health ("an additional award")
- **It prices none of them.**
- **Why the old tripwire missed it.** It keyed on "award" in the headline, and this headline says "Investments".
- **What changed.** The tripwire now trips on any RHTP headline.
- **Where it stands.** The release is archived (`data/evidence/WV/2026-10-12_wv_art_32m_rhtp_investments_UNEXTRACTED.html`) and held in `WV_READ_UNEXTRACTED`. A test proves the widened check fires on it without that entry.
- **Your decision.** Extraction would add about six hospital rows at $0.

### (c) The empty-reply verdict

- `rhtp_probe_verdict()` now reads curl's "Empty reply from server" / "Server returned nothing" as **ERROR**.
- Mississippi's 10-09 line is pinned verbatim in `test_utils_probe_log.R`.
- The historical log line was not rewritten.

### (d) New Hampshire's hospital RFA, a watch date

- **Status.** FHC's CAH & Acute Care Hospital RFA is **Open**: portal opens "Late October 2026", priority deadline November 12, **"Notification of Award (Initial Cohort) Mid December 2026"**.
- **Archive.** The RFA (dated 2026-10-01) and its 10-06 appendices are under `data/evidence/NH/rfa/`. The RFA says "FHC anticipates awarding approximately $17.5 million", a Tier 2 pool.
- **Not hospitals-only.** Lead applicants include "Organizations partnering with an eligible applicant to transform the delivery of hospital care", so each award is coded off the award (§10.2's New York table).
- **Probe.** `R/03bm`'s anchor is now the Mid-December sentence, and the baselines are re-based to 10-12. A new "Home Health and Community Care RFA" is "Coming Soon".
- **Recorded** in CLAUDE.md's dated watches.

---

## Task 5: deadlines and the Delaware lead

### (a) The 2026-10-30 and 2027-09-30 deadlines

**The NOFO itself is not archived in the repository.** The primary federal terms here are the CMS Notices of Award:
- KY Attachment B and the GA original carry full Program Terms.
- CA, CT, NV, WY and VA carry face pages.

**2026-10-30: verified as the END OF BUDGET PERIOD 1, not as a printed obligation rule.**
- **What the NOA says.**
  - Face page: "Budget Period Start Date 12/29/2025 - End Date 10/30/2026".
  - KY Terms §6: "Budget period 1: December 29, 2025 to October 30, 2026 (10 months)".
  - The NOA's "unobligated funds" means funds CMS did not award; it carries no sentence requiring a state to obligate to subrecipients by 10/30.
- **Who says "obligated by October 30" — states, not CMS.**
  - AR's NOFOs: "per CMS rules, all funds must be obligated by October 30, 2026".
  - Also IL, AL, ID, UT, AK, CA ("Subaward agreements must be fully executed no later than October 30, 2026"), NY and WY.
- **One state contradicts it.** RI EOHHS's "RHTP 101" gives "10/1/26 Year 1 Obligation Deadline", citing "CMS Webinar for Applicants; Notice of Award".

**2027-09-30: verified by derivation from NOA terms.**
- **NOA wording.** KY Terms §15: unexpended funds are funds a recipient "does not spend by the end of the subsequent fiscal year with respect to each budget period start date". CMS "will redistribute unexpended or unobligated funds", and the funds return to Treasury only on 2032-10-01.
- **The derivation.** BP1 starts in FY2026, so the subsequent fiscal year ends **9/30/2027**.
- **Who prints the date.** The NOA does not. The CT DSS budget narrative, IL HFS, TN, MO DSS, ND, KY RFAs, LA's Capital NOFO and AR's NOFOs do. SR 198 paraphrases it.
- **One state guide is wrong.** CA's grant guide calls 9/30/2027 "the end of the federal period of performance"; the NOA's period of performance ends **10/30/2030**.

**Recorded** in CLAUDE.md's standing rules, worded as above.

**10-30 watch date for the hunting-list states.** The list is session 97's roster-hunting list (`cms_obligation_gap_by_state.csv`, `hunt_rank` 1–13): CA, IN, IA, HI, NC, NH, IL, RI, VA, CT, MO, KY, MD. It is added to CLAUDE.md's dated watches.

### (b) Delaware and Thomas Jefferson University (report only)

**No committed state award document names Thomas Jefferson University or any medical-school awardee.** What exists:

- **`de_year1_status.csv`, row "Delaware's first 4-year medical school".**
  - Year 1 budget $42,500,000, a plan line (Tier 2).
  - Its note reads "Thomas Jefferson University is named in DE Verify.xlsx; no award notice reachable here".
- **`DE Verify.xlsx`, the un-ingested owner workbook (blocker 2).**
  - Awardee "Thomas Jefferson University", activity "Delaware Medical School Partnership", amount NA.
  - Note: "Award amount not available … $2,685,200 budgeted for the whole initiative in the Executive Budget". That $2,685,200 has no source in the repository.
- **The DE budget narrative.**
  - Initiative 9 "Contractual — Lead Partner Institution $42,500,000.00, Contractor: TBD", to be selected "through a formal bidding process". Its period of performance is 12/29/2025–10/30/2026.
  - Initiatives 10 and 11 (medical-student awards $1.1M; resident housing and relocation $1,236,495) go to the Delaware Health Care Commission.
- **CMS obligation report, as of 7/31.**
  - "Initiative 9: Delaware Medical School ($16,755,416)": three lines of $12,112,260, $890,368 and $3,752,788, "for establishing a medical school …". No recipient is named.
  - DE-008-17-23: "$140,000 for education awards for … medical students enrolled at **Sidney Kimmel Medical College (SKMC)**". SKMC is the students' place of enrolment, not a recipient.
  - CMS labels this line Initiative 11 although the narrative puts student awards under Initiative 10.

Nothing was coded. If Delaware publishes the Initiative 9 contract, it is a university award (UNIVERSITY_OR_AHC), never a hospital row: TJU is not Jefferson's hospital enrolment.

---

## Task 6: five runners moved

| State | Old runner (used_tokens) | New runner | Old Routine (disabled) | New Routine | Cron (UTC) |
|---|---|---|---|---|---|
| IN (GROW) | `session_013ysrxChnfh9xCbAEQ7UyiG` (754,497) | `session_019iSKyTV5EbtdXdy45ZPjda` | `trig_01UZ5QWh8No7uiRBz9S8T23C` | `trig_01KZZ2aZLdhxo8X827vsNMyE` | `50 9 * * 5` |
| TX | `session_01Su3qXCR46X98eD5JLV8Y5t` (736,160) | `session_01TQdyaFHew6NcvQGnkqj1mh` | `trig_017U35M4eGiGcnhPMeoKGzFy` | `trig_01PMLQwX7skbRcjHhUXSguWF` | `20 13 * * 5` |
| WV | `session_018rTSHkoFHVzcdAFrFXrGQ1` (731,490) | `session_01PC2j9ufodFGXxC7Ln9W1tc` | `trig_01SfWj74rQ4kdeHcdNckS4Yn` | `trig_01HATrmVp6tVV76AY8znga8v` | `30 11 * * 5` |
| ID | `session_0192egjzDKcmEV11Xxp8W7tN` (730,247) | `session_01PPAehPuTBdaNSUdWpNmWwR` | `trig_01HkxVsw4KoGkHpDwBCfve31` | `trig_019dET8MmsxwJAHBnx6dCLqF` | `40 12 * * 2` |
| VT | `session_01Wd4SYZ78GbLz7J8GfzyC7S` (720,258) | `session_01EYeeiSQXFUojBu2N69QrXT` | `trig_01G7gMgmaRvkzdWq49YjZQdq` | `trig_016RPWQycLeLLJngvFZPQKsj` | `30 11 * * 2` |

**Setup.**
- The new runners match the old ones: `env_01RnpqJ1D6wFAaRMvFu43oV3`, `claude-sonnet-5`, auto mode, the repository with `main` as source and outcome, no seed prompt.
- VT's runner was read back: auto, `claude-sonnet-5`, idle, 0 tokens.
- The Routine names and crons are unchanged.

**Prompts.**
- `runner_moves.csv` gained five rows, and `R/routine_prompts_worktree.R --write` regenerated v4.
- Only these five prompts changed. Each differs from HEAD **only in the runner ID**, three occurrences; this was checked by substituting the old ID back and diffing against `git show HEAD:`.
- `--check` passes for all 39.

**Did the stored prompts match the source text exactly? Verified as far as the tools allow:**
- Each new Routine was created with its v4 file's text. Those files differ from the old stored prompts only by the runner ID.
- The stored prompts were read back from `create_trigger` and `list_triggers` and checked by eye: right runner ID, right script, right gate.
- **A mechanical byte comparison of the stored text against the files was not possible.** The platform returned the prompts inline, not as a file the shell could hash. Session 82's byte-compare used a saved `list_triggers` file.

**Cut-over.**
- The old IDs are disabled, not deleted.
- `routines.csv` chains each old ID with its `logging_since`. The new `logging_since` values are 2026-10-12T19:10–19:11Z.
- No runner has two enabled Routines.
- `R/probe_coverage.R --check` passes: 139 due firings, 4 explained misses.

**Deadline.** **This branch must be on `main` before Tue 10-13 11:30Z**, VT's first firing. Until then the new IDs read as unregistered on `main`.

---

## Suite

`Rscript tests/run_tests.R` on this branch, after every change above. Result: see the final section appended at the end of the run.

# Session 104 (2026-10-19): Texas rulings, Maryland Labor, Ohio's pool, Maine, New Hampshire, the probe log

**Start.** This session starts from `main` after PR #106 (`claude/hopeful-ptolemy-flodx3`) merged, which carries session 103. No Year 2 work was done. No CMS release since 10-16 announces FY2027 amounts.

**Owner corrections mid-session.** These replaced the original Task 1(c) and Task 2:
- "Memorial Hospital" is a hospital, not Unclear.
- WVU Eye Institute is non-hospital, not Unclear.
- No department-name bridge rule goes into CLAUDE.md §7. (One was drafted and reverted before any commit.)

## Hospital partition, before and after

These figures are published figures: `SOURCE_SUSPECT` rows are left out. The buckets are never added together.

| Bucket | Before (session 103) | **After** | Change |
|---|---|---|---|
| NAMED_HOSPITAL | 1,538 / $1,426,413,861.18 / 33 states | **1,576 / $1,431,975,278.58 / 34 states** | +38 rows, +$5,561,417.40 |
| POOL_NAMED_HOSPITALS | 6 / $55,255,171.43 | **7 / $85,555,171.43** | +1 row, +$30,300,000 (Ohio) |
| POOL_UNNAMED_HOSPITALS | 5 / $69,323,109.17 | 5 / $69,323,109.17 | none |

- **Internal figure** (with SOURCE_SUSPECT rows): NAMED_HOSPITAL 1,578 / $1,435,430,699.58.
- **Where the NAMED_HOSPITAL change comes from:**
  - TX: +7 rows / +$1,987,387.40.
  - MD Labor: +9 rows / +$3,574,030.
  - OH: +22 rows / $0. Ohio becomes the 34th state.
- **Rural cut (`R/03ar`):** 407 / $366,644,593.52 → **410 / $367,023,056.72**.
  - TX gains three CAH rows: Hardeman ×2 and Stonewall.
  - TX loses "Memorial Hospital", which no longer has a CCN.
  - OH adds Pomerene (CAH) at $0.

## Task 1: Texas rulings (`R/03ce`)

**Texas hospital rows: 201 / $117,571,194.73 → 208 / $119,558,582.13.**
- LOW rows: 80 / $54,468,593.79 → 87 / $56,455,981.19.
- Intents: 113 / $48,958,310.67 → 119 / $50,195,698.07.
- Correction: session 103's doc printed intents as $48,958,310.79. The committed file gives $48,958,310.67.

**The county test.** CMS's enrolment file has no county field. County comes from CMS's Provider Data Catalog *Hospital General Information* file for TX, archived at `federal_records/2026-10-19/` (467 rows):
- It is joined to enrolment by CCN.
- Where a CCN is missing from that file, county is taken from a city the file places in exactly one county.
- No enrolled hospital without a county sits in any of the counties tested.
- `tx_rts_assert_county_bridges()` re-proves each decision on every build.

| Line | County | Enrolled hospitals in county | Decision | Year 1 |
|---|---|---|---|---:|
| Hardeman County Hospital District (I4) | Hardeman | 1: HARDEMAN COUNTY MEMORIAL HOSP, CAH 451352 | (a) bridged, LOW | $221,995.00 |
| Hardeman County (I1) | Hardeman | same | (a) bridged, LOW | $750,000.00 |
| Stonewall County Hospital District | Stonewall | 1: STONEWALL MEMORIAL HOSPITAL, CAH 451318 | (a) bridged, LOW | $156,468.20 |
| Nolan County Hospital District | Nolan | 1: ROLLING PLAINS MEMORIAL HOSPITAL, 450055 | (a) bridged, LOW | $221,995.00 |
| Maverick County Hospital District | Maverick | 1: FORT DUNCAN MEDICAL CENTER, L.P., 450092 | (b) bridged, LOW | $221,995.00 |
| Lamb County Hospital | Lamb | 1: LAMB HEALTHCARE CENTER, 450698 | (b) bridged, LOW | $376,659.20 |
| UT Health Henderson | Rusk | 1: HENDERSON HOSPITAL LLC, 450475 | (b) bridged, LOW | $38,275.00 |
| Winnie Stowell Hospital District | Chambers | **2**: Riceland, CAH 451328; Bayside, CAH 451320 | (b) **not bridged**; stays NON_HOSPITAL | — |
| Principle Hs, LLC; Principle Health Systems | none in the string | n/a | (b) not bridged | — |
| Christus Trinity Clinic (13 county lines) | named on each line | n/a | (b) not reached: the string names a physician group, not a hospital | — |

Each bridge carries its vulnerability on its row:
- **Nolan.** Rolling Plains Memorial already has its own Initiative 1 and Initiative 6 lines. This bridge gives one hospital a third first-tier name.
- **Maverick.** The enrolled entity is an L.P., a different legal body from the district. No document read says the district owns or operates it.
- **All seven.** No document read says the named body operates the hospital. Each bridge rests on the county alone.

**R/03bp's Hardeman note is corrected.** Before, it read "no hospital enrolment at all". Now it reads: no enrolment under the district's own name, with the county's CAH and R/03ce's bridge named. The floor CSV is unchanged.

**(c) "Memorial Hospital" (Initiative 1, $750,000, executed).** It is now `HOSPITAL_OR_SYSTEM`, LOW, with **no CCN**, and it is out of the rural cut.
- **What the source fields can tell us.** HHSC's list has six columns: name, initiative, total, Year 1 subset, intent, executed. It carries no county, address, applicant-entity or district field. **No source field points to a facility.**
- **Enrolled candidates.** Five TX hospital CCNs carry "Memorial Hospital" as their name or DBA:
  - Moore County HD (CAH 451386, Dumas)
  - Seminole HD of Gaines County (CAH 451358)
  - Gonzales Healthcare Systems (450235)
  - Memorial Hospital of Polk County (450395, Livingston)
  - Texas Health Arlington Memorial (450064)
- **Texas Health Arlington Memorial is the least likely.** It is an urban system hospital, and Initiative 1 funds "68 rural hospital districts and authorities" (CMS, 2026-10-01).
- **Seminole and Gonzales each already hold an Initiative 1 line:** "Seminole Hospital" and "Gonzales Healthcare", each $750,000.
- **Moore County is the only BP1 first-tier name no other line abbreviates.** That is an elimination argument, so it is recorded in the basis and not used to bridge. `tx_rts_assert_bp1()` still pairs the line with Moore County, as a record only.

## Task 2: WVU Eye Institute (`R/03av`)

WVU Eye Institute ($2,000,026) is now `UNIVERSITY_OR_AHC` / NON_HOSPITAL, STATE_SOURCE, MEDIUM. No West Virginia row is Unclear any more.

SSM St. Anthony Shawnee stays as typed: LOW, CCN 370149. It never had a queue row.

No rule was added to CLAUDE.md.

## Task 3: Maryland Labor roster (`R/03cf_md_labor_awardees.R`, `md_labor_awardees.csv`)

**38 lines / 34 organisations / $13,965,196**, parsed from the archived page. The tables match the page to the dollar.

| Table | Lines | Sum | Fund (MPI 10-26) |
|---|---:|---:|---|
| Pathways: RAMP – Allied Health | 9 | $1,572,011 | Immediate Impact Fund ($3.7M) |
| Pathways: Registered Apprenticeship Intermediaries | 5 | $1,756,416 | Immediate Impact Fund |
| RISE: Advanced Provider Pathways | 13 | $6,283,614 | Transformation Fund ($16.4M) |
| RISE: Talent Pipelines | 11 | $4,353,155 | Transformation Fund |

**"$16.4 million" is the Transformation Fund's size.** MPI 10-26 says: "Immediate Impact Fund ($3,700,000); and Transformation Fund ($16,400,000)" and "With the RHTP Transformation Fund, MD Labor launched … (RISE)". The figure is recorded in each row's `amount_basis` and is never an award.
- RISE's awards ($10,636,769) sit under the $16.4M.
- The page's "39 organizations" is unexplained. The page names 34.

**Hospital rows: 9 / $3,574,030**, typed on CMS MD enrolment (`federal_records/2026-09-25/`):
- **MEDIUM, CCN on row:**
  - TidalHealth Peninsula Regional ×3, $843,816 (210019)
  - CalvertHealth Medical Center, $300,000 (210039)
  - Frederick Health Hospital, $430,317 (210005)
- **LOW, $1,999,897 in total:**
  - UM Charles Regional, $500,000. Bridged to CIVISTA MEDICAL CENTER INC (210035, La Plata), its former name. This rests on general knowledge.
  - UM Shore Regional Health, $499,898. A system parent; two enrolled entities, no CCN.
  - UM Upper Chesapeake Health, $499,999. A system parent; one entity with two CCNs, none on the row.
  - Meritus Health Foundation, $500,000. Typed under §10.2's foundation rule; parent is Meritus Medical Center (210001).

**Non-hospital rows:**
- CalvertHealth Medical Group is `PHYSICIAN_PRACTICE`.
- Choptank is an FQHC (session 49's website verification).
- Susquehanna Workforce Network is `OTHER` (a workforce board).
- The other 14 organisations use §8's standing fallback, with `RECIPIENT_TYPE_INFERRED`.

**Probe.** The NEWSROOM sweep's MD probe now reads the roster page live, into memory only, through `nw_md_labor_finding()`. It trips on any line that differs in table, grantee or amount. A live run returned no finding. MD has no Routine of its own, so this is the probe that watches it.

## Task 4: Ohio (`R/03an`)

**The sentence the pool call rests on.** ODH, 2026-10-16: *"This investment provides $30.3 million in one-time direct payments to 22 rural hospitals."* CMS's 10-16 release agrees: *"another $30.3 million will fund one-time equipment and facility upgrades at 22 rural hospitals."*

**The $92M is three sub-pools:**
- Hospitals, $30.3M.
- CINs/Hubs, $31.4M, to seven organisations.
- Maternal care, $30.3M, to six organisations.

The CINs/Hubs and maternal groups include non-hospitals: the Ohio Association of Community Health Centers, the Ohio Health Institute and the Child & Family Health Collaborative of Ohio.

**Coding:**
- **The $92M as a whole is shared, so it stays out of every bucket.** So do the $31.4M and the maternal $30.3M.
- **The hospital $30.3M is stated for the 22 alone.** It is one `POOL_NAMED_HOSPITALS` row at $30,300,000, flagged `AMOUNT_ROUNDED_IN_SOURCE;MULTI_RECIPIENT_FIELD` and never split. It follows the CT Hartford pair's shape.
- **Vulnerability, stated on the row:** the page also says "The funded projects haven't been announced yet."
- **This is a reading of the owner's rule; please confirm it.** If the owner meant the $92M test to cover the whole $92M, drop this one row in `oh_s104_rows()`. Nothing else changes.

**(a) The 22 hospitals are rows at $0**, typed on CMS OH Hospital Enrollments (`federal_records/2026-10-19/`, 316 rows):
- **14 exact matches, MEDIUM, with CCN.** Blanchard Valley is also exact but has two CCNs, so no CCN is on its row.
- **6 LOW bridges:**
  - Van Wert, Mercer County, Wilson Memorial, Sojourn at Seneca and East Liverpool have a CCN.
  - Holzer has two enrolled Holzer hospitals, so no CCN.
- **2 rows with no CCN by ambiguity:**
  - Community Hospital of Williams County: the entity holds two CCNs.
  - "Memorial Hospital": two OH entities are exact (Fremont 360156, Marysville 360092), and the page gives no city.
- **Sojourn at Seneca is a senior behavioral health hospital** (364055).

**(b) Ohio Pharmacists Association, $2,000,000.** NON_HOSPITAL, §8 fallback, rounded.
- The Board of Pharmacy's figure is a state agency's own use, not an award.
- The page states that figure two ways, "$1.15 million" and "$1.5 million". Its total reads "$3,150,00".

**(d) Probe.** `oh_probe()` now reads both ODH child pages, `hospitals` and `pharmacy`:
- It compares a content digest.
- It runs a name tripwire scoped from "| Agency" to the CMS footer. A test proves that a new hospital name fires it.
- It raises a finding if the $30.3M sentence or "funded projects haven't been announced" disappears.

**Footer.** Both child pages print "$202 million at 100 percent", which is the allotment rounded. The shared parser reads "$202 million" as $202, so the rounding is asserted in `R/03an` instead.

Ohio's file is now 25 rows / $42,300,000 priced (Ohio University $10M, OPA $2M, the pool $30.3M).

## Task 5: Maine and New Hampshire

**Maine.** I read the three pages that logged CHANGED on 10-16 against their archives, word by word. All three are noise:
- **`rhef` and `programme`:** the DHHS footer gained a "Hospital Price Transparency (DDPC) (RPC)" link.
- **`programme` also:**
  - The past Oct 7 meeting's time changed (12–1pm → 12–12:30pm), and a public Zoom link was added.
  - A "Maine RHTP Y2 Project Narrative" link was added beside the Y1 one. It is a plan document, already furniture since session 94.
- **`doe`:** only DOE menu items changed.

No name or award moved. The three files were re-based, so the manifest was rewritten. `--validate` passes, and a live interactive probe logged UNCHANGED.

**New Hampshire.** CMS's 10-16 release says "more than $11 million" for EMS and Mobile Integrated Health. Governor Ayotte calls it "grants through GO-NORTH". The release names no recipient.
- **No state roster is readable from here.** These all return HTTP 403: governor.nh.gov, gonorth.nh.gov, and fstems.dos.nh.gov (Fire Standards & EMS). An external fetcher also got a 403 from governor.nh.gov.
- **Press coverage names one recipient.** The Concord Monitor (10-16) quotes state EMS director Mark Wholey: the funding adds "five Mobile Integrated Health programs". It names no recipients.
- **One third-party report.** A city-council transcript aggregator reports Laconia receiving about $500,000 per year across two components. That source is not admissible.
- **Hospital effect: $0.** Nothing was extracted, because there is no priced state-source roster.

## Task 6: Probe log since 2026-10-16T22Z

**Nothing in the log moves a hospital dollar.** Every page below was fetched live into memory and diffed word by word against its archive.

| State | Verdict(s) | Reading |
|---|---|---|
| TX (10-16 22:11Z, interactive) | 6 CHANGED | NOISE. Every page adds a "Close" menu token and renames "Request for Application:" to "Open Enrollment:". No newer weekly list (only `10-15-2026-…xlsx` is linked). |
| TN (10-17) | `news` CHANGED | NOISE. TDH loan-repayment cycle (no RHTP) and a rabies bait drop. |
| NC (10-17) | 5 CHANGED, TRIPWIRE `trillium` | No award. The trip is "NC Rural Health Transformation Program" in a Region 2 "Rural Ready Roundtable" notice, which is furniture. `opportunities`: the Rural Health Innovation Fund (Tier 2, ~$20M/yr) is current, and SBHC moved to past. Trillium's five regional RFAs still read "Closed - Under Review" after their September award dates. |
| NJ (10-17) | `doh_news` CHANGED | NOISE. Flu shot and doula training items, no RHTP. |
| LA (10-17) | 3 CHANGED | NOISE: LDH menu only. **SR 198's report is still not posted** (due 10-15). |
| CA (10-17) | TRIPWIRE (scope anchor) | No award. A stale outage banner broke the anchor (see below). |
| NY (10-18) | 2 CHANGED | NOISE. Three non-RHTP press items, plus Contract Reporter counters. |
| AR (10-18) | 4 CHANGED, 3 name TRIPWIREs | See below. |
| KS (10-19) | ERROR | KDHE 403, as recorded since session 95. |
| CO (10-19) | CHANGED, TRIPWIRE `programme` | See below. |
| DE (10-19) | `programme` CHANGED | See below. |

**CA, AR, CO, DE (read live 10-19):**
- **CA `funding` (TRIPWIRE): no award.**
  - **Why the anchor broke.** HCAI inserted a stale outage banner ("Planned Service Outage … (10/16/26) … Tableau dashboards … unavailable") between the menu and the breadcrumb, which splits the scope anchor. The banner is NOISE.
  - **New content that is not an award:** a "Train-the-Trainer" section. HCAI partners with UC Irvine's Office of Medical Education on two programmes (IHOPE geriatric behavioural health; Maternal Behavioral Health). It carries no amount and no award language.
  - **Also new:** the resources label now reads "CalRHT Subrecipient Agreement template superseded".
  - **Proposed new `ca_name_scope` anchor**, tested on live and archived copies of both pages: `California Rural Health Transformation \(CalRHT\) (?:CalRHT Grant Funding Opportunities|Rural Health Transformation Program \(RHTP\))`. With it, the funding page would still trip, correctly, on the UCI/TTT names.
- **CA `calrht`:** the same banner. NOISE.
- **AR (4 CHANGED, 3 name trips): NOISE.**
  - The only change is a new "Resource Library" menu item, and every name trip is that menu run.
  - The new Resource Library page holds subrecipient training videos ("Arkansas RHTP Subrecipient Training 10.16.26"). It names no recipient, and its footer prints the allotment ($208,779,396.02).
- **CO `programme` (name trip): sidebar furniture.**
  - "Approved Documents" became "BY1 Documents".
  - A new link was added: "Colorado Annual Report as of 6.31.26" (sic). It is a report, not an award; it was not opened.
  - The `awardees` roster is identical word for word.
- **DE `programme`: no award.**
  - DHSS menu items were deleted.
  - One in-scope insertion: the Telehealth/RPM line ($5,000,000 Year 1 budget) now links a Catalyst Fund RFP. It was due 10-05, with second-round notifications "on or before October 12". This is a Tier 2 vendor solicitation that names nobody.
  - **A selection may follow; watch it.**

**Coverage.** `R/probe_coverage.R --check`: "190 due firing(s) since the logging fix; all logged except 4 EXPLAINED miss(es)".

**Hawaii.** The first firing (`trig_017PbAESTaaMfYZ3nKcS3j1m`) is due Mon 10-19 18:30Z. It had **not run** when this session wrote up, and nothing is logged for HI.

**Proposed probe changes (not made; the brief said extract nothing beyond Tasks 1–5):**
- Add "NC Rural Health Transformation Program" to NC `trillium` furniture, citing the Roundtable sentence.
- Re-base TX's six "Open Enrollment" pages.
- Add the furniture and anchor fixes for AR, CO and CA listed above.

## Queue (6 resolved, 0 opened)

All six resolved items are dated 2026-10-19 and attributed to the owner, in `classification_review_queue.csv`:
- `TX_RTS_DISTRICT_NAME_NOT_ENROLLED`
- `TX_RTS_HOSPITAL_SHAPED_NOT_BRIDGED`
- `TX_RTS_MEMORIAL_HOSPITAL_BY_ELIMINATION`
- `WV_WVU_EYE_INSTITUTE_UNCLEAR`
- `MD_LABOR_ROSTER_UNRECONCILED`
- `OH_ODH_92M_UNPRICED_AND_OPA`

## Vulnerabilities to state when using these figures

1. **Texas.** 87 of 208 hospital rows ($56.5M) rest on hand bridges. Seven of them now rest on the county alone. 119 rows ($50.2M) are intents.
2. **Ohio.** The $30.3M pool is announced, but "funded projects" are not. The figure is rounded. Its 22 rows are $0.
3. **Maryland Labor.** $2.0M of the $3.57M rests on LOW typings: system parents, a renamed hospital and a foundation.
4. **Unreconciled headlines.** In both Maryland ("$16.4M to 39 organizations") and Ohio (the "$92M"), the headline figure is a fund or programme size, not the sum of the rows. Never cite the headline as hospital money.

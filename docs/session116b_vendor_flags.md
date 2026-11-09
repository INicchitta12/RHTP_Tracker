# Session 116b: vendor / consultant / insurer / out-of-state flags

**Date:** 2026-11-09. **Branch:** `claude/nice-gauss-y1swid`, cut from `main` at `a1325ed` (session 116 merged).
**Scope:** a read-only detection layer. **No award row, summary call, bucket or hospital figure changed.**
`test_09_vendor_flags.R` re-derives the partition and pins it at session 116's figures:
NAMED_HOSPITAL 1,958 / $1,797,619,954.62, POOL_NAMED 10 / $86,895,779.43, POOL_UNNAMED 6 / $79,214,848.17.

**Internal only.** These are documented examples for AHA colleagues, not a census, and not an estimate of total
vendor spending.

## What was built

| File | What it is |
|---|---|
| `R/09a_usaspending_rhtp.R` | USAspending fetch for Assistance Listing **93.798**: request, poll, archive the zip with a manifest; `--validate`, `--build`, `--report` |
| `data/raw/usaspending/2026-11-09/` | The zip (50 prime awards, 2,025 subawards) plus its SHA-256 manifest. Committed (§0.5) |
| `data/reference/usaspending_rhtp_subawards.csv` | One row per reported subaward: the subrecipient's UEI, address and description |
| `data/reference/usaspending_rhtp_coverage_by_state.csv` | Which states report, how many rows, the reported total and the out-of-state count |
| `config/vendor_entity_dictionary.csv` | 92 hand-reviewed entries: `pattern, canonical_name, parent_company, entity_class, hq_state, basis, notes` |
| `R/09_vendor_flags.R` | The flag build: `--validate` (quote checks), `--build`, `--xlsx`, `--report` |
| `data/reference/vendor_flags.csv` | **158 rows** (148 sourced, 10 RCJ leads) |
| `data/reference/vendor_unnamed_contractor_by_state.csv` | Unnamed contractor money on CMS's obligation lines, by state. Context only |
| `output/vendor_flags_2026-11-09.xlsx` | Tabs: Top cases, By firm, Unnamed contractor money, All flags, Notes |
| `data/evidence/vendor_flags/2026-11-09/CO/` | Colorado's "Annual Report as of 6.31.26" workbook. Session 105 read it and did not archive it |
| `tests/testthat/test_09_vendor_flags.R` | Schema, class list, hospital exclusion, the ≥$1M ranking, dedupe, leads, the unchanged partition |

The dictionary schema has a seventh column, `notes`, beyond the six the brief listed. It holds the reason for each
anchored pattern, such as why `^Health Management Associates` must never match "METRO KNOXVILLE HMA, LLC". The
flag file adds four columns after the sixteen the brief listed: `out_of_state`, `hq_basis`, `is_lead` and
`also_cited_in`. `also_cited_in` holds the second citation when two sources record the same contract.

## Report

### 1. USAspending / FSRS: yes, and more than expected

- **ALN 93.798** ("Rural Health Transformation Program") is confirmed by USAspending's own CFDA autocomplete.
- **50 prime awards**, $10,000,000,000.00 obligated (one per state, FAIN `RHTCMS3320xx`).
- **2,025 first-tier sub-grants**, $2,822,602,267.02 reported, filed by **31 states**. No subcontract is reported.
- **19 states had filed nothing:** AL AR CA CO FL GA LA MA MD MI MO MS NH NJ NY PA SC WI WY.
- The latest SAM reports were modified on 2026-11-04.
- **Two access traps, both recorded in `R/09a`'s header:**
  - USAspending's award-search endpoint returns **zero** rows for 93.798, while the count endpoint returns 50 and 2,025.
  - The bulk-download endpoint **silently dropped the program filter**: it echoed back a request for every grant
    nationally.
  - The custom-download endpoint works. `--fetch` refuses any download whose echoed filter is not 93.798.
- **What FSRS cannot show.** Under 2 CFR 170, a subaward excludes "procurement of property and services". A state's
  own consulting contract is therefore not reportable, and Kansas's BCG line is absent. Some states report
  contractors anyway, which is why Guidehouse (NM), Deloitte, Manatt and Freedman (DE), and Carelon (WA) appear.

### 2. Top 15 cases

A case is one firm's flagged lines in one state, from one source, at one amount type. Ranking is by amount.

| # | State | Firm (class) | Amount, type | Role | Purpose (source's words) | Source |
|---:|---|---|---:|---|---|---|
| 1 | FL | CommunityHealth IT (TECH) | $43,658,794 award (4 lines) | UNKNOWN | The roster prints names only | Governor's Year 1 awardee PDF |
| 2 | NC | Trillium Health Resources (MCO, in-state) | $29,578,000 award (3) | MIXED | "NC ROOTS Hubs. Each NC ROOTS Hub will establish and coor[dinate]…" | FSRS |
| 3 | NM | **Guidehouse** (BIG, McLean VA) | $20,100,773 award | MIXED | "The contractor shall establish and operate the Center for Rural Health Sustainability & Innovation (CRHSI) as the implementation and technical a[ssistance]…" | FSRS |
| 4 | ID | **Public Consulting Group** (Boston MA) | $14,520,000 award | ADMINISTERS | "Third Party Administrator for Ladder Payment Program" | DHW awardee list |
| 5 | NC | Vaya Health (MCO, in-state) | $14,250,000 award | MIXED | NC ROOTS Hub | FSRS |
| 6 | UT | HK Consulting (HQ unknown) | $11,000,000 intent | ADMINISTERS | "LINCS 7.3-7.4: Semantic Data Model and Applications" | DHHS announcement |
| 7 | VT | KPH Healthcare / Kinney Drugs (Gouverneur NY) | $10,236,395 award (2) | UNKNOWN | "Expand pharmacists' scope to include test-to-treat" ($8.65M); "Facility upgrades" ($1.59M) | AHS executed list |
| 8 | KS | BioIntelliSense (Golden CO) | $9,514,500 **plan** (2) | DELIVERS | "…a centralized continuous remote patient monitoring program for inpatient and post-discharge patients" | KS budget narrative |
| 9 | UT | Comagine Health (Seattle WA) | $6,000,000 award | UNKNOWN | "RHTP agreement with Comagine Health for FAST 4-1 initiative" | FSRS |
| 10 | KS | Oracle Health (Austin TX) | $5,964,000 **plan** | DELIVERS | "…provide those Kansas rural clinics utilizing the Oracle Community Works … with access to Oracle's Clinical AI Agent" | KS budget narrative |
| 11 | AR | New York Institute of Technology | $5,263,782 intent (2) | UNKNOWN | Pool labels "RISE AR", "PACT" | DF&A list |
| 12 | ID | Comagine Health (Seattle WA) | $5,107,958 award (3) | MIXED | Diabetes prevention; perinatal QI collaborative; obstetric readiness | DHW list (FSRS also cites two of the lines) |
| 13 | VT | **McKinsey & Company** | $5,100,000 award | UNKNOWN | AHS note: "Regionalization: Transformation analytics and support" | AHS executed list |
| 14 | KS | **Boston Consulting Group** | $4,750,000 **plan** | ADMINISTERS | "KDHE will contract with BCG to provide rapid response implementation support for the Kansas RHTP" | KS budget narrative |
| 15 | RI | Alvarez & Marsal (NY) | $4,515,000 **obligation** (26 lines) | MIXED | Programme administration and collaboration lines across all 13 initiatives | CMS obligation report |

Cases 16–45 are in the workbook. Among the national firms in that range:
- Mathematica, CT, $3.98M award.
- Carelon, CT, $3.8M plan; WA, $1.62M FSRS award.
- BDO: ID, $1.99M award; KS, $2.33M plan (fiscal agent).
- Guidehouse, ID, $1.76M award.
- HealthTech Solutions, CO, $1.88M obligation (CO's own annual report, entity type "Other Consulting").
- RTI, UT, $1.67M intent.
- Deloitte, ID, $1.29M award.
- PCG, VT, $1.10M award.

### 3. Totals by class

Non-lead rows only. Each amount type is a separate figure; they are never added together.

| Class | award | intent | obligation | contract max | plan | unpriced rows |
|---|---:|---:|---:|---:|---:|---:|
| CONSULTING_BIG | $28,899,536 (5) | — | — | $567,350 (1) | $4,750,000 (1) | 1 |
| CONSULTING_OTHER | $25,552,449 (10) | $12,668,126 (2) | $4,754,307 (28) | $1,525,000 (3) | $4,579,929 (3) | 1 |
| TECH_VENDOR | $51,615,418 (14) | $4,754,780 (4) | $4,086,400 (2) | — | $15,478,500 (3) | 1 |
| INSURER_MCO | $46,787,825 (6) | $5,179,229 (2) | — | — | $3,800,000 (1) | 5 |
| OUT_OF_STATE_ORG | $37,185,021 (34) | $13,510,450 (11) | — | — | — | 10 |

**INSURER_MCO is mostly in-state public plans.** $43.8M of its $46.8M award figure is North Carolina's own LME/MCOs
acting as NC ROOTS Hub Leads: Trillium $29.6M and Vaya $14.25M. The commercial insurers are smaller:
- Carelon (Elevance): $1.62M FSRS award and $3.8M plan.
- Moda: $2.7M intent.
- Inland Empire Health Plan: $2.47M intent.

### 4. The 10 largest firms

Each firm's largest amount type is shown; the other types are in "By firm".

| # | Firm | Class | Largest figure | Other types | States |
|---:|---|---|---:|---|---|
| 1 | CommunityHealth IT | TECH_VENDOR | $43,658,794 award | — | FL |
| 2 | Trillium Health Resources | INSURER_MCO | $29,578,000 award | — | NC |
| 3 | Guidehouse | CONSULTING_BIG | $21,863,773 award | $567,350 contract max | NM ID SD |
| 4 | Public Consulting Group | CONSULTING_OTHER | $15,624,343 award | $106,965 obligation | ID VT NE |
| 5 | Vaya Health | INSURER_MCO | $14,250,000 award | — | NC |
| 6 | Comagine Health | OUT_OF_STATE_ORG | $12,700,049 award | $4,511,486 intent | ID NV OR UT |
| 7 | HK Consulting | CONSULTING_OTHER | $11,000,000 intent | — | UT |
| 8 | KPH Healthcare (Kinney Drugs) | OUT_OF_STATE_ORG | $10,236,395 award | — | VT |
| 9 | BioIntelliSense | TECH_VENDOR | $9,514,500 plan | — | KS |
| 10 | Oracle | TECH_VENDOR | $5,964,000 plan | — | KS |

Next in line: NYIT $5.26M intent; McKinsey $5.1M award; BCG $4.75M plan; Alvarez & Marsal $4.52M obligation.

### 5. Unnamed contractor money (CMS lines, context only)

These are 45 lines in 24 states, **$148,946,402.72** in total. They are never attributed to a firm. The largest:

| State | Obligated | Largest line |
|---|---:|---|
| SC | $25,930,136 (5 lines) | SC-002-02-03, "$10,000,000 for contractor to determine the financial feasibility of developing a rate methodology for community paramedics" |
| NH | $20,401,655 | NH-006-18-18, programme staffing, financial management, contracting and administration |
| KY | $14,320,700 (4) | KY-001-02-03, "$9,102,500 for consulting, analytics, and decision support for launch and implementation" |
| OK | $11,000,000 (8) | OK-007-21-47, "$5,000,000 for a contractual agreement for … Grant Management & Reporting" |
| MS | $10,000,000 | MS-007-07-09, "a grant management contractual agreement" |
| ME | $9,622,874 | ME-003-09-20, leadership and oversight of contractors for Tech & Innovation |
| AK | $9,215,388 (3) | AK-004-04-05, "$7,983,578 for contractual support" |
| KS | $9,190,802 | KS-006-21-46, "state agencies, contractors, and consultants" |
| CA | $8,480,000 (2) | CA-004-09-15, "$7,480,000 for third party grant administrator services" |
| AR | $6,000,000 | AR-001-01-02, "contractual agreements" |

Two of these lines are named elsewhere:
- **CO-006-09-14** ($1,830,800) is HealthTech Solutions' contract, named in Colorado's annual report.
- **DE-005-08-09** ($149,000) is Manatt's. FSRS carries the same figure.
- SD-001-01-01 ($1,462,802.25) matches North Star Solutions' open.sd.gov contract. North Star is not flagged because it
  is a small in-state firm.

## Coverage gaps

1. **State consulting contracts are mostly unpublished.**
   - Award pages list subawards, and FFATA excludes procurement.
   - The contracts found came from Kansas's and Connecticut's budget narratives, South Dakota's contract register,
     Colorado's annual report, and the few states that report contractors to FSRS anyway.
   - The largest are visible only as unnamed CMS lines (§5).
2. **19 states file no FFATA subawards.** That includes CA, MI, MO, MS, NY and PA, which hold large award files.
   This is a statement about their FFATA filing, not about their awards.
3. **Second-tier contracts** are invisible except where a plan names them: Kansas's CCA contracting BioIntelliSense,
   Oracle, PYA and BioSTL.
4. **Budget narratives were read for 8 states only:** KS, CT, AR, CA, FL, IN, WY and DE.
   - Only KS and CT name a priced contractor.
   - AR names BDO GS per RCJ, but not in the archived narrative's text layer, so it stays a lead.
   - IN's Microsoft Sentinel licence (about $18,000 a year) was not flagged.
5. **Sources read that yielded nothing:**
   - Texas's BP1 first-tier report names only hospital districts.
   - Oklahoma's Q1–Q3 legislative reports name agencies and LifeCare Alliance.
   - Indiana's IDOA vendors are already in the award file. Deloitte appears there unpriced (ACO feasibility).
6. **Out-of-state status is complete only where FSRS gives an address** (31 states). In the award files it rests on
   dictionary entries. A non-hospital out-of-state recipient missing from the dictionary is not flagged.

## Cases I'm unsure about

- **CommunityHealth IT, FL, $43.66M.** Florida's roster names it four times and gives no address or purpose. The name
  and the file's `VENDOR_OR_CONTRACTOR` typing make it TECH_VENDOR. It may be a Florida health-centre IT network
  rather than a commercial vendor. **Read Florida's source before citing it.**
- **HK Consulting, UT, $11M intent.** Neither headquarters nor form is established.
- **Kinney Drugs, VT, $10.24M.** The New York address is the source's. It is a regional chain with Vermont stores, so
  "out of state" is literally true and the money funds Vermont pharmacies.
- **NYIT, AR, $5.26M intent.** NYIT runs a medical-school campus in Jonesboro, so the money is probably spent in Arkansas.
- **Comagine, OR.** The award-file intents ($2.01M) and the FSRS awards ($1.59M) do not match by amount, so they are not
  paired. FSRS's $488,178 looks like Comagine's share of the "Alano Club, Comagine Health, Tabor North" field ($1,113,000).
  Both rows stand at different amount types and are never added.
- **NC LME/MCOs.** Trillium and Vaya are public Medicaid MCOs serving as Hub Leads. They are in the brief's "state
  Medicaid plans", but they are not commercial insurers.
- **Vermont Alliance for Recovery Residences.** FSRS gives a Georgetown TX address. I doubt it and did not flag the row
  (`VF_FSRS_REVIEWED_EXCLUSIONS`).
- **Role codes.** Rows that carry only a pool label (McKinsey "Regionalization", Mathematica, NYIT) are UNKNOWN by
  design. McKinsey's purpose quote comes from the file's `award_pool`; the AHS note above is the better text.
- **RCJ leads** are 10 rows, never ranked or totalled.
  - NH NORC's $20.2M is almost certainly RCJ's tier mixing. The disposition says no amount is sourceable.
  - TX's Molina and UnitedHealth and CO's Deloitte and EY were dropped: this repository's dispositions say NOT_RHTP_MEDICAID.

## For the owner (outside this layer; nothing done)

- **FSRS prices rows our award files hold at $0. This is the main follow-up.**
  - NC's five NC ROOTS Hub Leads are reported at $14.25M or more each, including **UNC Hospitals at Chapel Hill,
    $14,250,000**.
  - Iowa reports 200 subawards, $198.6M, many to hospitals.
  - A ruling is needed on whether a state's FFATA report is an admissible award source (`validation_source_type`) for
    the hospital files. It is the state's own federal filing.
- The Colorado annual report is now archived. Session 105 had it only in a scratchpad.

## Suite

The full suite (`Rscript tests/run_tests.R`) result is recorded below once it finishes.

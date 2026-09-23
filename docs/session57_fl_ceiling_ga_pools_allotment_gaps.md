# Session 57 — Florida's ceiling, Georgia's pools, and the two allotment gaps

2026-09-23. Zero RCJ quota. Network: data.cms.gov, npiregistry.cms.hhs.gov,
irs.gov, ahca.myflorida.com, greathealth.georgia.gov, dch.georgia.gov.

**This is a report. No award row was re-coded.** `fl_year1_awardees.csv`,
`ga_great_health_awards.csv` and both session-56 tables are unchanged. The
proposed Florida codings are in `data/reference/fl_ceiling_resolution.csv` and
are waiting on the owner's decision.

- Script: `R/03ax_fl_ga_ceiling_pools_gaps.R` (`--build`, `--report`).
- Tests: `tests/testthat/test_03ax_fl_ga_ceiling_pools_gaps.R`.
- Outputs: `fl_ceiling_resolution.csv`, `ga_mixed_pool_split_search.csv`,
  `fl_ga_allotment_gap_components.csv`.
- Evidence: `data/evidence/federal_records/2026-09-23/` (Florida CMS, NPPES,
  IRS; Georgia CMS hospital file) and `data/evidence/recheck/2026-09-23/{FL,GA}/`.

## 1. Florida: five rows between the floor and the ceiling

The floor is $49,345,213.46 (26.2% of $188,201,256.11 published). The ceiling
(29.6%) adds five rows coded `distributed_to_hospital = Unclear`, $6,331,219.97.
They are three organisations.

The source is the Governor's Year 1 list. It prints a row number, a name, an
amount, and a region, and nothing else. It gives no organisation form and no
project text. That is why all five are ambiguous. The owner's workbook coded
them UNCLASSIFIED/Unclear. Session 49's verifiers re-typed them from the
organisations' websites but did not settle the hospital column.

| Row | Recipient | Amount | Region | CMS hospital match | Federal record | Class | Resolves |
|---|---|---:|---|---:|---|---|---|
| 71 | North Florida Rural Health Corp | $650,000.00 | Northwest | 0 | IRS EIN 85-2728333; NPPES 1912641341, 1720849540 | EXACT | **Yes** |
| 16 | Empowerq Health Care | $3,204,031.91 | Southeast | 0 | none under that spelling; bridged to IRS 85-2591676 / NPPES 1770170367 | BRIDGE | **Yes, on a hand-read bridge** |
| 9, 18, 33 | Nuvita Health | $2,477,188.06 | NE, SE, SW | 0 | none anywhere | NEGATIVE | **No positive record** |

- **North Florida Rural Health Corp: resolves, not a hospital.**
  - The state's own string is the IRS EO BMF name exactly: 501(c)(3), NTEE E30
    (ambulatory and primary care), 680 Maple St, Chattahoochee.
  - NPPES has it under the same name and city twice, once as a clinic and once
    as a pharmacy.
  - It is in no CMS enrolment file, so it is not an enrolled FQHC, RHC or hospital.
  - The only CMS hospital in Chattahoochee is Florida State Hospital (DCF, CCNs
    104000/100298). That is a different body.
  - Proposed coding: `NONPROFIT_CBO`, `No`, MEDIUM.
- **Empowerq Health Care: resolves, but on a bridge.**
  - "Empowerq" is in no federal record: NPPES 0, IRS 0, all six CMS files 0.
  - The verifier's cited website is Empower Healthcare, Inc., a primary-care
    clinic serving Palm Beach County. IRS lists it as EIN 85-2591676, Pahokee,
    501(c)(3), NTEE E32 (community clinic). NPPES lists it as 1770170367,
    Pahokee, with a Rural Health clinic taxonomy.
  - The Governor's list puts row 16 in the Southeast region, which includes Pahokee.
  - The match to the state's spelling is one letter off and was made by hand,
    so it is LOW (§2). No CMS-enrolled Florida hospital has EMPOWER in its name
    or DBA.
  - Proposed coding: `NONPROFIT_CBO`, `No`, LOW.
- **Nuvita Health: does not resolve the way Winston County did.**
  - No federal record carries the name: no CMS file, no IRS row, no NPPES organisation.
  - NPPES's only Florida "Nuvita" organisations are a Tampa chiropractor and a
    Jacksonville multi-specialty clinic enumerated 2025-07-09. Neither is Nuvita
    Health and neither is a hospital.
  - The form rests on the company's own website. The hospital question is
    answered only by absence.
  - Its three awards are in three different regions, which fits a statewide
    vendor but proves nothing.

**The floor does not move.** Nothing resolved *to* a hospital. The ceiling
under each reading:

| Reading | Unclear left | Ceiling |
|---|---:|---:|
| Before (session 56) | $6,331,219.97 | 29.6% |
| Remove exact federal records only | $5,681,219.97 | 29.2% |
| Also remove the hand-read bridge | $2,477,188.06 | 27.5% |
| Also remove the measured negative | $0 | 26.2% (= floor) |

Recommendation: adopt the first two. Treat Nuvita as `No` only if the owner
accepts absence from CMS's Florida hospital file as proof that an organisation
is not a hospital. Either way, the true share is 26.2% to 27.5%.

## 2. Georgia: the two pools with named hospitals and no split

| Pool | Amount | Named hospitals | Non-hospital member | Its amount | Split published |
|---|---:|---:|---|---|---|
| Phase 2, Initiative 3 (Rural Stabilization Grants) | $6,500,000 | 17 | **DBHDD** (state agency), "a mobile dental clinic" | not published | **No** |
| Phase 4, Initiative 1 (AHEAD pre-implementation) | $15,635,000 | 7 | **the provider of "personalized assessments of all 87 hospitals"** (not named) | not published | **No** |

**No per-recipient breakdown exists for either pool.** Sources checked:
- All four DCH announcements.
- Both signed Notices of Award and both NITAs. These cover telepods and robots,
  not these pools.
- greathealth.georgia.gov, live 2026-09-23: the funding page, news, the
  value-based-care page, and all five application initiative pages.
- CMS's own NOA, both versions.
- DCH's State Office of Rural Health pages.

Three things look like a split and are not:
- **The application's Rural Stabilization Grants line**, $9,540,817 in Budget
  Period 1. This is a plan, and it is larger than the pool.
- **SORH's Rural Hospital Stabilization Program participant list** (Phases 1–7,
  maps dated 082022). This is the state-funded programme and is archived as a
  §0.1 negative control. Several of the 17 RHTP hospitals appear on it, which
  makes it more tempting to misread.
- **7 × $750,000 = $5,250,000.** Phase 3 priced its 80 hospitals at $750,000
  each. DCH never restates that figure for Phase 4's seven. The multiplication
  would leave a $10,385,000 assessment remainder that nobody published, so it
  is refused (§6.2).

**Each pool has one non-hospital member, and neither member's amount is
published.** So the ceiling cannot be lowered by any sourced figure. Georgia
stays at floor 45.8%, ceiling 57.0%. The one thing that is now certain is that
the true figure is strictly below the ceiling, because each pool contains
money that did not go to a hospital.

## 3. The allotment gaps

**§0.2:** each gap is the Tier 1 award minus Tier 3 awards. The lines set
against it are the state's own plan or CMS's approved budget. They explain
what the gap is made of. They are never added to an award total.

### Florida: $21,736,938.39

$209,938,194.50 minus $188,201,256.11. The budget narrative's own Year 1 total
equals CMS's award.

| Component | Amount | Source |
|---|---:|---|
| State PMO direct (personnel, fringe, travel, supplies) | $1,974,557.50 | AHCA revised budget narrative, 2026-02-10 |
| State indirect (NICRA) | $501,930.00 | same |
| Admin contracts (Admin-A PMO/GMS + Admin-B 3% regional), as attested | $18,517,332.00 | same |
| **Unexplained** | **$743,118.89** | plan's 15 initiatives $188,944,375 − awards |

- The award-side source is one sentence in the Governor's release: *"procurements
  earlier this year to establish the infrastructure necessary to monitor program
  outcomes, track expenditures and deliverables, and provide support to
  subawardees."* It publishes no recipient and no amount.
- **The narrative contradicts itself by $501,930.** Its line items give Admin-A
  $13,350,931 plus Admin-B $5,668,331, which is $19,019,262. Its 10%-cap
  attestation gives $18,517,332. The gap between them equals the indirect line.
  Only the attested figure closes to the narrative's own total. Both are
  recorded; neither is corrected (§8).
- **Admin-B may be inside the published awards.** The narrative pays it to each
  regional awardee "upon award". If the published awards include it, the admin
  share of the gap is smaller and the unexplained share is larger. No source says.

### Georgia: $21,713,842.63

$218,862,169.63 minus $197,148,327 (12 distinct pools). The request quoted
$21.8M; the figure is $21.7M.

| Component | Amount | Source |
|---|---:|---|
| State personnel (salaries $1,465,461 + fringe $990,857) | $2,456,318.00 | CMS NOA, Revision (Budget), 02/10/2026 |
| State supplies | $102,940.00 | same |
| State travel | $46,215.80 | same |
| Indirect | $0.00 | same |
| **Unexplained: contractual budget in no published pool** | **$19,108,368.83** | contractual $216,256,695.83 − pools |

- **The revised NOA is image-only.** Its approved-budget section was read from
  the rendered page. The script holds that reading to two checks: the lines sum
  to the NOA's own total, and that total is the figure in DCH's footer.
- The $19.1M fits administration:
  - DCH says "less than 10% of Year 1's funding is dedicated to administrative costs".
  - The residual is 9.92%.
  - DCH names RSM as its grants-management vendor.
  - The application puts one assessment "through administrative contract".
- **No source publishes an amount or recipient for any part of it.** So its
  composition is unexplained.
- Georgia does not publish its budget narrative on greathealth.georgia.gov.
  The five application initiative pages sum to $198,759,332 for Budget Period 1.
  They predate the February budget revision and are not reconciled here.

## What is left for the owner

1. **Florida write-back.** Apply `fl_ceiling_resolution.csv` to
   `fl_year1_awardees.csv`: all rows, or all except Nuvita. Then rebuild
   `R/03aw`. The floor stays 26.2%; the ceiling goes to 27.5% or 26.2%.
2. **Georgia.** Nothing to write. Only DCH can publish the split. The 2026-09-10
   quarterly update is the likeliest place; no deck for it was found on the
   pages checked.
3. **The gaps.** Florida's $743,118.89 and Georgia's $19,108,368.83 are
   unexplained until either state publishes its administrative contracts.

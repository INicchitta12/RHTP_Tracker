# Session 116e: the verified consultant / intermediary / out-of-state vendor list

**Date:** 2026-11-10. **Branch:** `claude/tender-johnson-mwx1u5`, cut from `main` at `090b9a8`.
**Scope:** a read-only layer for AHA colleagues. **No award row, summary call, bucket or hospital figure moved**
(the partition stays pinned in `test_09_vendor_flags.R`). Internal only.

## Deliverable

- `output/verified_vendor_list_2026-11-10.xlsx`, with six tabs: Verified list, By firm, Unnamed contractor money, Planned (not awarded), Dropped, Method.
- `R/09c_verified_vendor_list.R` (`--build`, `--live`, `--xlsx`, `--report`).
- Hand inputs: `config/verified_vendor_cases.csv` (57 cases written up), `config/verified_vendor_hand_drops.csv` (69
  drops by hand), and `config/verified_vendor_independent_check.csv` (Task 4's verdicts).
- Outputs: `data/reference/verified_vendor_{list,dropped,unnamed_lines,planned}.csv` and
  `verified_vendor_live_check_2026-11-10.csv`.
- New archive: `data/evidence/vendor_verified/2026-11-10/MS/`. This is DFA's notice of intent to award the RHT funds contractor to BDO. It prints no amount, so it is a V3 drop.

## Result

**48 cases pass. 179 drops are recorded** (a drop row can be a candidate, a session-116b flag row, or a category
removed from a case that still passes). Each amount type is a separate figure; types are never added together.

| Category | award | intent | contract maximum | obligation |
|---|---:|---:|---:|---:|
| INTERMEDIARY | $276,407,802 (21) | $103,955,784 (10) | n/a | n/a |
| CONSULTANT | $26,631,602 (3) | $1,668,126 (1) | $25,965,898 (6) | $2,205,500 (1) |
| OUT_OF_STATE_VENDOR | $26,079,710 (5) | $3,947,362 (2) | n/a | n/a |

Guidehouse NM ($20.1M) is in both CONSULTANT and OUT_OF_STATE_VENDOR, so the category rows overlap and must not be summed.

### Top cases in plain language

1. **Utah Hospital Association, UT, $38.3M intent.** DHHS names UHA "Fiscal Agent & Open Subgrant Administrator". It "Awards competitive capital grants for rural facilities". UHA also holds $9.9M (intent) to allocate recruitment-and-retention subawards to 21 hospitals.
2. **UKHS Care Collaborative Association, KS, five FSRS subawards (award).** They total $87.1M, the largest $37.8M. The Care Collaborative administers Kansas's programmes: "making infrastructure and incentives payments to participating providers", and subawards to KUMC and HealthWorks.
3. **Wyoming Innovation Partnership, WY, $35.4M + $3.2M intent.** The Advisory Committee approved a "sole-source ... master fiscal agent contract ... to administer statewide individual and institutional workforce/nursing grants".
4. **NC ROOTS Hub Leads, NC, award.** Trillium $28.5M and Vaya $14.25M (both PUBLIC LME/MCOs), and Access East and Impact Health ($14.25M each).
5. **Guidehouse, NM, $20.1M award (FSRS; McLean, VA).** The only Big-firm case that is both CONSULTANT and OUT_OF_STATE_VENDOR. It will "establish and operate the Center for Rural Health Sustainability & Innovation ... as the implementation and technical assistance entity".
6. **Invest Nebraska, NE, $20.0M award.** A sub-award "to provide administer the catalyst fund". CMS carries the same figure as an obligation.
7. **Nebraska High Value Network, NE, $18.2M award.** The notice lists "individual hospitals receiving funding".
8. **Virginia Health Care Foundation ($16.1M + $9.9M), VHHA Foundation ($14.8M + $9.9M + $2.5M) and VIPC ($9.9M), VA (FSRS awards).** Each passes funds to providers, health systems or startups.
9. **Foundation for a Healthy Kentucky, KY, $9.1M contract.** It "Provides consulting, analytics, and decision support". The figure equals CMS's unnamed line KY-001-02-03.
10. **Ernst & Young, KY, $5.2M contract; McKinsey, VT, $5.1M award.** These are the Big-firm consultants that pass. EY: "Strategic planning and implementation support". McKinsey: "Transformation analytics and support".

## Unnamed contractor money (CMS lines that name no firm)

There are 45 lines in 24 states, **$148,946,402.72 obligated**, and none of it is attributed to a firm. The largest:
- SC $25.9M (5 lines)
- NH $20.4M
- KY $14.3M (4 lines)
- OK $11.0M (8 lines)
- MS $10.0M
- ME $9.6M
- AK $9.2M
- KS $9.2M
- CA $8.5M

KY-001-02-03 ($9,102,500) has the same state and amount as verified case VV024 (FHKY). That is a match of figures, not a statement by CMS.

## Drops: the large ones and why

- **V1 (no admissible source):**
  - NH FHC $66.5M: only FHC's own page and CDFA; nh.gov is unreadable.
  - IL ICAHN $50.0M: only ICAHN's own release.
  - WA WSHA $42M: only a webinar deck.
  - WV KPMG ~$8M: press only, and the name is disputed.
  - CO HealthTech Solutions: a state annual report.
  - CT Mathematica: a Governor's release.
- **V4 (the quote does not show the category):**
  - KY FHKY's $50.5M FSRS line and $29.2M overarching contract.
  - OK LifeCare $33.9M: services to member hospitals, not money passed on.
  - NV NRHPF $20.3M.
  - IL PCA/CBHA $44M (4 lines).
  - RI HARI and CTC-RI.
  - ME MCD $10.4M.
  - UT HK Consulting $11M: a software build.
  - VT PCG.
  - Programme-name-only FSRS lines: WA Carelon, TN Nurses for Newborns, WV Cartwheel, UT Comagine $6M.
- **V7 (a state agency):** AZ OEO $46.9M, UT UETN $47.4M (2 lines), HI SHPDA $25M, WV Jobs Investment Trust $18.8M, VA VFHY $11.1M, and others.
- **V9 (funds in-state operations):**
  - VT Kinney Drugs $8.65M and $1.59M (its Vermont stores).
  - IN Spirit EMS.
  - AK Fond of You ("Alaska-based Certified Peer Specialists").
- **V6 (no FSRS address):** many national firms keep their CONSULTANT case but are not shown as out-of-state, for example EY, McKinsey, Bailit, RTI and Idaho's contractors.

## Independent check (Task 4)

A separate agent was given only the 57 cases and the archives. It was told not to read `config/`, `docs/` or R/09c, and it re-checked V1–V9 field by field.

- **Case-level agreement: 48 of 57 (84.2%).**
- **Test-level agreement: 406 PASS of 417 applicable results (97.4%).**
- It found no amount, name, UEI, address or SHA-256 mismatch.

Its nine drops are honoured by the build:
- **ID list cases fail V2.** These are VV032 PCG $14.52M (also V4 for CONSULTANT), VV033 BDO, VV034 Guidehouse, VV035 Deloitte, VV036 22nd Century and VV039 Co Magine (also V4).
  - The archived xlsx carries no title, no CMS footer and no 93.798, so "RHTP" is only in the file name.
  - **Disputed:** the same sheet does print the solicitation name "Tribal Rural Health Transformation Support" on five other rows, which R/09c's machine V2 check accepted.
  - Under the brief's rule, a disagreement drops the case. If the owner rules the in-sheet programme name a sufficient tie, VV033–VV036 return and VV032 returns as INTERMEDIARY only.
- **VV031 VSAC $9.06M (V4).** The quote is a programme name and does not say VSAC passes money on.
- **VV049 UNC/UT $1.48M (V4).** The FSRS line is an initiative title. Utah's scope sentence would support it, but it is a different source and amount type.
- **VV053 Safetech $1.17M (V4).** "support EMS regionalization" does not say consulting, and CMS uses the same words for a university line.

Borderline passes it flagged:
- **VV001 Guidehouse and VV057 Jefferson (V9).** Both pass because their sources do not say the funded centre or school is in-state. If it is, V9 would drop them.
- **VV015 and VV022 (INTERMEDIARY).** These rest on "including funding for ..." and "to provide ... catalyst funds".

## Method notes and limits

- **V7 state agency.** The test is FSRS "STATE GOVERNMENT" (other than a state university) or STATE_AGENCY in this repo's award files. That drops VFHY and WVJIT, which are state-created rather than line agencies.
- **V5/V6 FSRS bridge.** UEI and address come only from the same record, the same identifier (AK App ID = FSRS subaward number), or an equal normalised legal name. That keeps Utah's "Comagine" off OUT_OF_STATE_VENDOR.
- **Live check (`--live`).** All 48 surviving sources are live today. Every PDF and xlsx source re-serves its archived bytes; USAspending still lists every FSRS subaward.
  - Idaho's WebLink needs a second request on the same cookie handle.
  - The Vermont page and the Utah doc changed after archiving; every case's name, amount and quote are still on the live page. Utah's RTI scope paragraph was reworded after its first sentence, which is the part quoted.
- **Coverage.** FFATA excludes procurement and 19 states file no FFATA subawards, so most consulting contracts are invisible.
- **Portal search.** Web search found:
  - MS DFA's BDO intent (archived, no amount).
  - WV's KPMG contract (press only).
  - SD North Star, already archived; its contract page fails V2 because it names no RHTP programme.
  - Nothing for McKinsey, Accenture, Bain, BCG, PwC, Huron, HMA, Manatt or A&M beyond the cases above.
  - Most state portals were not searched directly; this is a known gap.

## Planned (not awarded)

There are 23 budget-plan lines, labelled and never in the verified list:
- Kansas's budget narrative: BioIntelliSense $7.0M and $2.5M, Oracle $6.0M, BCG $4.75M, BDO $2.3M, PYA $1.5M.
- Connecticut's Carelon $3.8M and its shared Contractor 1 column.
- NC Year 1 project list: Accenture "RHTP Grants Support Vendor" $4.5M, and the LME/MCO Hub Lead budget lines.

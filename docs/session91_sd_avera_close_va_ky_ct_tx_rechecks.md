# Session 91 — SD Avera bridge closed; VA, KY, CT and TX re-checked beyond the watched pages

2026-10-05. The searches READ live pages only. Nothing was archived, extracted or re-coded except Task 1.

## 1. SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE — closed at (a), no bridge (owner)

The round funds Certified Community Behavioral Health Clinics, which is a clinic model. CCN 43S016
(AVERA MCKENNAN, dba AVERA MCKENNAN BEHAVIORAL HEALTH SERVICES) is a psychiatric distinct-part unit
of Avera McKennan's hospital, so it is not the named cohort member. The row stays NONPROFIT_CBO,
LOW, RECIPIENT_TYPE_INFERRED, NON_HOSPITAL and Unclear. No dollars moved. Only R/03bw's text and the
Avera row's `recipient_type_source` changed. SD_CCBHC_COHORT_13_VS_12_GRANTS stays open.

## 2. States past a published award date

### Virginia: a priced subaward roster was found and NOT extracted

- **Source:** VHCF, 2026-10-02,
  https://www.vhcf.org/2026/10/02/virginia-takes-another-step-in-transforming-rural-health-care-through-major-technology-investments/
- **The roster:** "VHCF announced 25 awards totaling $14.39 million through Virginia's Rural Health
  Transformation Program". These are VHCF's Provider Interoperability awards, VHCF's first under RHTP.
- **Check:** the 25 per-row amounts sum to exactly $14,390,000 (re-summed in session from the saved
  page).
- **Footer:** $189,544,888.14 at 100% CMS. That is Tier 1, the allotment, and the publication is
  its subject.
- **Hospital-shaped rows:** 9 rows, $6,640,000, none checked against an enrolment yet.
  - Buchanan General ×2
  - Valley Health System ×2
  - Ballad Health $2.0M
  - Sentara Health $1.7M
  - Danville Regional $150k
  - Carilion Medical Center $69k
  - Community Memorial Hospital–VCU Health $56k
- **To check:** Highland Medical Center ($288k). Two UVA Health sub-unit strings ($884k) have the
  AHC_STRING_NAMES_NO_ENROLLED_ENTITY shape.
- **The rest:** FQHCs, free clinics, a community services board, associations, VHI, a county
  office and an urgent care.
- **Why the probe missed it:** VHCF's /rural-health/ page did not change. The award came through
  VHCF's news channel, which no probe watches.
- **Trap:** VHCF's 2026-07-10 "$2.7 million to 19 organizations" is its regular grant programme,
  with no mention of RHT.
- **Next dates:** VHCF Provider Productivity in October. VHHA Foundation and Virginia Works Earn to
  Learn by 10-30.
- **UNKNOWN:** the Governor's newsroom (rendered by JavaScript) and eVA.

### Kentucky: no state roster, but recipients have self-announced

Recipient and third-party releases. None is a state document, so none can support `Yes`.

| Recipient | Amount | Round | Publisher | Date |
|---|---:|---|---|---|
| Georgetown-Scott County EMS | $289,275 | Community Paramedicine | Scott County Fiscal Court | 07-27 |
| Medical Center EMS (Med Center Health) | $310,070 | Community Paramedicine | the recipient | 07-30 |
| Adair County Ambulance | $438,418 | EMS Training Equipment | myq104 radio | 07-15 |

- **Status table is wrong:** `ky_year1_status.csv` calls Community Paramedicine and EMS Training
  Equipment CLOSED_UNAWARDED. They have awarded; Kentucky has published no names.
- **Two more passed award dates,** both in CHFS RFA PDFs:
  - Community Paramedicine: "July 1, 2026 Notification of Award", $20M pool.
  - PHDH team: "May 25, 2026", about 5 awards, $470k.
- **Probe noise:** the funding page's repeated CHANGED comes from a leaked SharePoint "Content and
  Structure Reports" web part. That is page furniture.
- **UNKNOWN:** eMARS (TLS) and transparency.ky.gov (postback form).

### Connecticut: no new subaward to a named recipient

- **Still the only named, priced awards:** the 4 rows from 09-16.
- **New: DEEP's 07-08 release.** "$7,165,955 in first-year funding" for the Air Line State Park
  Trail. The recipient is a state agency, so this is the same shape as the budget-narrative agency
  lines and is not a hospital award.
- **New: DMHAS REST Center RFP DMHAS-EBP-REST-2026.** A $50M pool for up to 4 awards. "Proposer
  Selection TBD", and the contract start of 9/1/2026 has passed. DMHAS posts "Outcome" PDFs, so
  this is worth a probe.
- **Unchanged:** the OPM NOFO, the OHS, DSS and Governor indexes, and CHA.
- **PACE:** a future single-operator RFP.
- **CT Mirror (third-party):** ">100 contracts across 30 projects", with no list.
- **UNKNOWN:** BizNet (CAPTCHA), CTsource (TLS) and cga.ct.gov (TLS/503).

## 3. Texas BP1 report: no change

- **Live xlsx:** byte-identical to the 2026-10-01 recheck archive. Last-Modified is still
  2026-09-28 15:33Z.
- **Assertions:** `tx_bp1_first_tier()` and `tx_bp1_assert()` pass. 33 districts, $24.75M
  obligated, $0 disbursed.
- **New HHSC links:** two BP2 narratives (09-29). Both are plans, with 72 districts planned against
  68 announced, and not rosters.
- **Third-party:** KRUN names Ballinger Memorial / Runnels County Hospital District, which is not
  among the 33. That is a lead, not a source.
- **UNKNOWN:** ESBD was not checked.

# Session 92: VA VHCF extracted, KY re-staged, CT DEEP and REST recorded

2026-10-05. Owner tasks 1–4 from session 91's re-check findings.

## 1. Virginia: VHCF Provider Interoperability, 25 awards, $14,390,000 (`R/03bx`)

- **Source:** VHCF release, 2026-10-02. It says "25 awards totaling $14.39 million through Virginia's
  Rural Health Transformation Program", and the 25 lines sum to exactly $14,390,000. Archived under
  `data/evidence/VA/vhcf/` with scripts stripped.
- **File:** `va_year1_vhcf_awardees.csv`, one row per printed line. Buchanan General and Valley Health
  have two lines each, and they are not merged.
- **Footer:** $189,544,888.14 at 100% CMS. That is VA's allotment (Tier 1), and the round total is
  not taken from it. The shared §0.2 rule refuses it as a SOLICITATION, asserted in both directions.
- **Typing:** on CMS VA Hospital (2026-09-25, 169 records, 18 CAH), FQHC and RHC enrolment files. The
  FQHC and RHC files were fetched this session to `federal_records/2026-10-05/`.

| Group | Lines | Dollars | Basis |
|---|---:|---:|---|
| Exact CMS hospital records (Buchanan 490127 ×2, Community Memorial 490098, Carilion Medical Center 490024, Danville Regional 490075) | 5 | $690,000 | ORG_WEBSITE, MEDIUM, CCN on row |
| System parents (Valley Health ×2, Ballad, Sentara) | 4 | $5,700,000 | GENERAL_KNOWLEDGE, LOW, no CCN |
| **NAMED_HOSPITAL** | **9** | **$6,390,000** | 44.4% of the round |

- **Highland Medical Center ($288,000) is an FQHC.** The VA Hospital file and its 18 CAH records do
  not contain "HIGHLAND". The FQHC file carries HIGHLAND MEDICAL CENTER INC at 491858 and 491903
  (Monterey). `hva_assert_highland()` stops the build if any of those facts moves.
- **System parents:** none of the three strings is an ORGANIZATION NAME or DBA on any VA file. Their
  hospitals enrol under other legal bodies (Winchester Medical Center, Mountain States Health
  Alliance, Wellmont, Sentara Hospitals), and each row records them. They are typed on the footing the
  owner settled for SD in session 87 (`SD_SYSTEM_PARENTS_FORM_NOT_STATED`). **Not separately approved
  for VA**, so the owner may confirm. Without them VA is 5 / $690,000.
- **UVA Health strings** ("Comprehensive Epilepsy Program" $84,000; "–Fortify Children's Health"
  $800,000): UNIVERSITY_OR_AHC, NON_HOSPITAL. They are appended to
  `AHC_STRING_NAMES_NO_ENROLLED_ENTITY` with the enrolled entity, Rector & Visitors of the University
  of Virginia, CCN 490009. Under (b) they would add +$884,000.
- **Session 91's "$6.64M" for 9 rows** does not reproduce. The same nine lines sum to $6,390,000.
- **Trap registered:** VHCF's 07-10 release ("$2.7 million in grants to 19 organizations") is its
  regular programme, with no RHT or CMS language. It names Tri-Area Community Health and The Health
  Wagon, which are also on the RHTP roster. It is in `non_rhtp_state_programs.csv` as
  `VA-VHCF-REGULAR-GRANTS` (NOT_RHTP_STATE_PROGRAM, on programme identity: it post-dates the NOA).
- **Probe:** `R/03bb` (VA's existing Routine) now reads `vhcf.org/news/`. Any post URL that the
  archive does not carry trips it. The 07-10 and 10-02 posts are in the baseline.
- `va_year1_status.csv`: Provider Interoperability is AWARDED_ROSTER_PUBLISHED ($14,390,000), and a
  Provider Productivity row is added ("October 2026").

## 2. Kentucky: two rounds awarded privately (`R/03af`)

- **Community Paramedicine** and **EMS Training Equipment / Mobile Training Units** moved from
  CLOSED_UNAWARDED to `AWARDED_PRIVATELY_NO_PUBLIC_ROSTER`, with `award_date_published` 2026-07-01.
- The three self-announced awards are named in the notes as LEADS ONLY. No row is made from them.
- **Dates added to `KY_AWARD_DATES`:** each is read from its own archived RFA and re-checked live by
  every probe.
  - CP: "July 1, 2026 Notification of Award to Grantees" ($20M pool).
  - Rural Dental Access / PHDH teams: "May 25, 2026", "estimated award amount is $470,000". That row
    is now CLOSED_AWARD_DATE_PASSED.
  - **Also added, beyond the brief:** the EMS Training Equipment RFA's own "July 1, 2026", because it
    dates the re-staged row.
- **Not acted on:** the Accredited Dental Hygiene Programs RFA prints "June 26, 2026 Notification of
  Award to Grantees". Its status row says "Closed 2026-08-01 per the CHFS channel". The two disagree,
  and the row was left for a read.
- **Ignore list:** `ky_reduce_html()` now cuts SharePoint's `<div id='hidZone'>` (the hidden "Content
  and Structure Reports" admin web part) by div depth.
  - The cut also removes zero-width characters. Measured today, the funding page's CHANGED came from
    one extra U+200B in the "Funding Opportunities" heading (79 → 80), not from the panel.
  - Live probe after the fix: funding UNCHANGED. `rch` (FHKY) still reads CHANGED. That is unrelated
    and was not investigated.

## 3. Connecticut (`R/03ac`)

- **DEEP, $7,165,955:** a new status row, `STATE_AGENCY_ALLOCATION_NOT_SUBAWARD`.
  - The figure equals DEEP's line in the archived budget narrative to the dollar ($86,667 + $75,565 +
    $1,680 + $2,043 + $7,000,000).
  - The release's headline says "$7.1 Million Awarded". The recipient is DEEP, so this is not a
    subaward. An assertion refuses DEEP in `ct_year1_awardees.csv`.
  - Downstream Tier 3 is the unchosen "Trail Contractor".
- **DMHAS REST RFP (DMHAS-EBP-REST-2026):** a status row and a probe page (`dmhas_rfps`).
  - "Anticipated Total Funding Available: $50,000,000", "Up to 4", "Up to $3,000,000 per year per
    award". So $50M is not a Year 1 figure: it is at most $12M a year.
  - Selection TBD; the contract start of 9/1/2026 has passed.
  - **Eligible class:** hospitals among others, and a non-hospital applicant needs an area hospital's
    partnership letter. That is New York's class, so code off the award.
  - **Tripwire:** any link in the REST row other than the RFP or an "Addendum N" (DMHAS posts
    "Outcome" there).

## 4. Hospital dollar effect

- **VA:** 0 → 9 NAMED_HOSPITAL rows / $6,390,000. VA becomes the 32nd state with a named-hospital
  row.
- **National NAMED_HOSPITAL:** 1,290 / $1,197,370,515.42 / 31 → **1,299 / $1,203,760,515.42 / 32**.
- The pools are unchanged: POOL_NAMED $30,806,856.12; POOL_UNNAMED $50,008,264.
- **Subtractable:** VA system parents $5,700,000 (GENERAL_KNOWLEDGE). The national GENERAL_KNOWLEDGE
  named-hospital slice is now $96,826,484.
- **Rural cut:** unchanged at 256 / $263,299,771.23. None of VA's hospital rows is a CAH.
- KY and CT move no dollars.

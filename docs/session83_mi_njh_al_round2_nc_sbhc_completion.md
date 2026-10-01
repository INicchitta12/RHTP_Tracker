# Session 83 — National Jewish Health re-typed; Alabama round 2 and NC's SBHC roster extracted; Year 1 completion rebuilt

2026-10-01. Five owner tasks.

## 1. National Jewish Health (Quitlink), Michigan, $435,000 — RESOLVED

- `MI_NATIONAL_JEWISH_ENROLLED_HOSPITAL` resolved at option (a) on the owner's instruction.
- Moved from `EH_READ_NOT_APPLIED` (DEFERRED_TO_OWNER) to `EH_APPLY` in `R/03bj`. The match is
  EXACT_LEGAL_NAME: CMS CO Hospital Enrollment has NATIONAL JEWISH HEALTH, Denver, CCN 060107.
- `mi_year1_awardees.csv` row 15 changed from VENDOR_OR_CONTRACTOR / NON_HOSPITAL / No to
  HOSPITAL_OR_SYSTEM / DIRECT / Yes / NAMED_HOSPITAL. It is MEDIUM (ORG_WEBSITE) and carries the CCN.
  Session 49's basis stays as PRIOR BASIS.
- Why session 49 was wrong: it typed the row by function (running the quitline). §0.3a forbids that, and
  session 49's own basis said "by legal form it would be HOSPITAL_OR_SYSTEM". MDHHS states no form, so
  §10.2's precedence rule leaves the decision to the enrolment.
- **Dollar effect:** MI NAMED_HOSPITAL went from 4 rows / $2,259,121 to 5 / $2,694,121. National
  NAMED_HOSPITAL rose by 1 row / $435,000. No new state.
- **Exposure to flag before anyone quotes Michigan:** this is an out-of-state hospital (Denver) paid to
  run a state tobacco quitline. The coding is correct under §0.3a. Even so, "RHTP money to Michigan
  hospitals" would be attackable if this row is not shown on its own. It sits beside the Regents'
  $2,000,000 (AHC), so 3 of MI's 5 rows / $2,435,000 of $2,694,121 come from CMS enrolment re-types.
- `R/03bj --apply` also writes the read-not-applied verdicts into `enrolled_hospital_operator_sweep.csv`.
  Before this session, County of Logan's row had an empty verdict.

## 2. Alabama round 2 — `R/03bq`, `al_year1_round2_awardees.csv`

- Source: the Governor's 2026-10-01 release, archived in session 82 and SHA-256-checked on read.
- **34 grants, $54,793,527**, against the headline "nearly $55 million". 13 amounts are rounded in the
  source and flagged AMOUNT_ROUNDED_IN_SOURCE. The release covers 7 initiative headings.
- This is a separate file, on Arkansas's precedent: round 1 carries session 49's row-index overlay. The
  two rounds are additive.
- **Parse trap:** the bare paragraph after The University of Alabama's Treat-in-Place grant is a
  continuation, not a 35th grant. Round 1's bare paragraphs *were* grants ("A second grant for…"). The
  parser refuses a bare paragraph that carries a "$".
- **Typing:** recipients were typed on CMS AL Hospital (09-25), FQHC and RHC (10-01, fetched this
  session) enrolment.
  - 12 rows are exact federal records.
  - UAB (3 rows) and USA (2 rows) were re-typed through `R/03bj` EH_APPLY as ACADEMIC_HEALTH_CENTER,
    $6,687,166, as their round-1 rows were.
  - The University of Alabama (Tuscaloosa) is not UAB. It stays UNIVERSITY_OR_AHC.
- **Hospital: 21 rows / $20,886,572.**
  - AHC subtype: $6,687,166.
  - LOW: Greene County Health System, 4 rows / $3,913,694. This is a GENERAL_KNOWLEDGE bridge to GREENE
    COUNTY HOSPITAL & NURSING HOME, CCN 010051. Queued as `AL_R2_GREENE_COUNTY_HEALTH_SYSTEM_BRIDGE`.
  - Infirmary Health System is MEDIUM on the same publisher's own words, "This nonprofit health system".
- The one fallback row is South Central Alabama Mental Health Board ($840,000). Queued as
  `AL_R2_RECIPIENT_FORM_NOT_STATED`, $0 hospital effect.
- **Alabama overall: 172 rows, $198,539,348, 97.6% of the $203,404,327 allotment. Hospital: 91 rows /
  $104,434,859.** Alabama now ranks third by NAMED_HOSPITAL dollars, behind AR and SC and ahead of GA.

## 3. North Carolina School-Based Health Centers — `R/03br`, `nc_year1_sbhc_awardees.csv`

- The release names five organisations for "$1.25 million" with no per-organisation figure. Every row
  has an empty `amount`; the $1,250,000 sits in `round_amount` (the MIH round's device). No split was
  invented.
- Typing:
  - FirstHealth of the Carolinas: HOSPITAL_OR_SYSTEM / DIRECT / NAMED_HOSPITAL at $0. This is a LOW
    bridge because the release spells it "First Health" as two words. The enrolled legal entity is
    FIRSTHEALTH OF THE CAROLINAS INC, CCNs 340115 and 341303.
  - Blue Ridge CHS and Mountain Community Health Partnership: FQHC, from CMS NC FQHC enrolment (fetched
    this session).
  - Appalachian District and Wilson County health departments: LOCAL_GOVT_OR_PUBLIC_HEALTH.
- This is the opportunity R/03ah's status table held as CLOSED_UNAWARDED. It now reads
  AWARDED_ROSTER_PUBLISHED (5, 2026-09-14).
- **NC: 49 named rows, 3 hospital rows, $0. The pool-level figure is now $11.25M.**

## 4. Year 1 completion status, rebuilt (`R/03aw`)

**Status changes since Arkansas went COMPLETE** (session 69, f317576): none until this session. Session
82 added Colorado as PARTIAL, which was a new row, not a flip. This session flipped no status. One field
changed:

| State | Before | After | Why |
|---|---|---|---|
| AL | PARTIAL / calls complete **No** / 70.7% | PARTIAL / calls complete **Yes** / 97.6% | The release says the round-2 grants "round out year one". But ARHTP "includes 11 initiatives" (the 08-24 release), the two rounds fund 10, and **Community Medicine** has "$7.3M for year 1" in ADECA's revised Project Narrative (archived) and no award. COMPLETE needs no recorded remainder. |
| NC | PARTIAL, 4.7% incl. pool | PARTIAL, 5.3% incl. pool | SBHC awarded. Minority Diabetes is still unawarded and RHIF awards are due January 2027. |

**Checked specifically:**
- **CO:** stays PARTIAL. CMS: "one part of the larger overall funding amount". The awardee page was
  unchanged on 10-01.
- **MS:** stays PARTIAL. Workforce and EmPATH are due "in the next 30 to 45 days" from 09-14, a window
  running 10-14 to 10-29 that has not opened. The 09-29 probe logged CHANGED on home, newsroom and DOM
  pages, with no TRIPWIRE.
- **SC:** stays PARTIAL. The Tech Catalyst Fund ($32.7M via SCRA) is "a future stage". The 10-01 probe
  logged UNCHANGED on all four pages.

COMPLETE states are still FL, GA and AR.

## 5. Partition

`NAMED_HOSPITAL 1,261 rows / $1,149,408,077.27 / 31 states` (+23 rows, +$21,321,572). The pools did not
move. Rural cut: unchanged at 240 rows / $245,561,955.03. AHC subtype total: $60,226,387.31.

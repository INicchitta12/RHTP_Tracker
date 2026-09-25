# Session 70 — Arkansas in the completed-state tables, NARHC settled, UAMS reported

## Task 1: Arkansas is the third COMPLETE state, and the only one on intents

Session 69 had already made Arkansas COMPLETE in `R/03aw`. It rests on the
Governor's 2026-09-24 sentence: "this round of funding completes the
distribution of the $208 million". Both deliverables now show it:

| State | Published | % of allotment | Hospital floor | Rows / $ | Priced $ on notice of intent |
|---|---:|---:|---:|---|---:|
| AR | $203,862,687.29 | 97.6% | 54.6% (ceiling 54.6%) | 30 / $111,276,895.52 | **100% (80 of 80 rows)** |
| GA | $197,148,327 | 90.1% | 45.8% (ceiling 57.0%) | 125 / $90,277,580 | 0% |
| FL | $188,201,256.11 | 89.6% | 26.2% (ceiling 26.2%) | 15 / $49,345,213.46 | 0% |

**New fields.** `year1_completion_status.csv` gains `intent_rows`,
`priced_usd_on_intent` and `pct_priced_on_intent` for all 31 states.
`year1_complete_hospital_share.csv` gains the same count and percentage, plus
`award_action_stage`, a sentence stating what the state's documents call the
actions. All of these come from each row's own `validation_source_type`, never
from the state's status. Oregon and Alaska are also 100% intent and PARTIAL,
so intent status is independent of completeness. A COMPLETE state with no
stage sentence fails the build.

**Florida's "executed" is AHCA's word, not a signed agreement.** Florida's rows
rest on the Governor's release (`AGENCY_PRESS_RELEASE`) and are
`amount_confirmed = Yes`. No executed agreement is published. Georgia's 21
robotics/telepod rows rest on signed Notices of Award. Its 56
`amount_confirmed = No` rows are unpriced because DCH prices per pool; no award
is pending. Arkansas: "the details of each grant will not be finalized until
DFA signs an official agreement with each grantee." CMS's obligation deadline
is 2026-10-30.

## Task 2: North Arkansas Rural Health Consortium: fallback in both rounds

Session 49's OTHER was withdrawn. Its whole basis is "Deckmax (doing business
as the North Arkansas Rural Health Consortium", which is a legal name and a
DBA, not a form. §8 says OTHER must state the determined form. The session-49
test only checked that the basis was longer than ten characters, and this row
passed on a name.

Negative result, archived at `data/evidence/federal_records/2026-09-25/`:
- No Deckmax or North Arkansas Rural Health record in CMS's AR hospital, FQHC
  or RHC enrolment files.
- None in NPPES.
- None in the IRS AR EO BMF.
- A web search found nothing.

NPPES does carry Vitality Plus LLC (Clinic/Center, Mountain Home), which is
the project's site. No record links it to Deckmax, and a site is not a
recipient (§0.3a).

Both rows are now `NONPROFIT_CBO` + LOW + `RECIPIENT_TYPE_INFERRED`. This is
applied by `ar_resolve_narhc()` after session 49's overlay in `--build`.
Effect: $0 moved and no row moved; the two rows stay NON_HOSPITAL / No.
Queue: `AR_NARHC_TWO_TYPES` RESOLVED, and NARHC is out of `AR_R2_QUEUED`.

## Task 3: UAMS should be revisited, and it is a rule question, not a row fix

CMS Hospital Enrollments (AR) carries this record:
- ORGANIZATION NAME: **"UNIVERSITY OF ARKANSAS FOR MEDICAL SCIENCES"**
- DBA: "UAMS MEDICAL CENTER"
- CCN 040016, general acute care, organisation type "STATE AGENCY"

The awardee string is the exact legal name of an enrolled hospital. NPPES
carries 126 organisation NPIs under that name, across hospital,
psychiatric-unit, clinic, pharmacy and professional taxonomies.

The two precedents conflict:
- **Winston County (session 50):** promoted because CMS carries the exact
  awardee string as a hospital's ORGANIZATION NAME. UAMS meets that test
  exactly.
- **OHSU (session 17) and UNC (session 38):** kept `UNIVERSITY_OR_AHC`.

None of the 12 described UAMS projects is hospital operations. They are
telehealth, stroke education, residency, nursing and management training,
mobile outreach, and food-is-medicine. §0.3a judges the recipient, though, and
not the activity.

**Dollar effect of re-typing under the Winston rule:** +$17,060,066
(round 1 $11,991,204 + round 2 $5,068,862). The Arkansas floor would go from
54.6% to 63.0%.

**Scope beyond Arkansas.** In the archived enrolment files, only Emory
University (GA, CCN 110010, $0 priced) also matches. Enrolment files for these
candidates have not been archived:
- University of South Alabama
- OHSU
- University of Iowa Health Care
- University of Maryland Medical System
- University of Washington
- University of Utah
- UNC Hospitals

No row was re-coded. The question is queued as `AHC_ENROLLED_HOSPITAL_OPERATOR`
with three options.

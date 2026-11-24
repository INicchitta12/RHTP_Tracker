# SD — use-of-funds evidence notes (session 123)

## Plan documents found
- **SD DOH RHTP Project Narrative**, https://doh.sd.gov/media/lyfbrd2k/sd_rhtproject-narrative-final.pdf
  -> `data/evidence/use_categories/SD/2026-11-24_sd_rht_project_narrative.pdf`. Use of Funds per initiative:
  - Tech and Data: A, C, D, F, K
  - Sustainable Workforce: A, E, C
  - CHW Workforce: A, D, E, G
  - Rural Health Forward Training Hub: A, D, E
  - Medicaid PACT: I, A, B, C
  - Medicaid Rural Health Access and Quality Grants: D, F, G, H, J, K
  - Chronic Disease Management: A, C, D, E, F, I, K
  - Maternal and Infant Health Hubs: A, D, E, F, G, I, K
  - CCBHC and Collaborative Care: B, D, E, F, G, H
  - EMS: E, G, H
- **DOH initiative one-pagers** (10, archived as `2026-11-24_sd_*_onepager.pdf`) and **SD's annual report to CMS**
  (`2026-11-24_sd_annual_report.pdf`). The one-pagers name each initiative's programmes and supply the name links. None
  prints letters.

## Mapping
- Crosswalk, 19 rows:
  - OpenSD descriptions that name a programme: chronic disease management (4), maternal hub, assessment and doulas (4),
    CHW (2), EMS hubs, PACT APM, and the Rural Health Forward training platform.
  - CCBHC: the SD_CCBHC round and the register's CCBHC Core Service Areas pool and description. Primary H, from the
    Governor's release: "specifically focused on behavioral health". The DBH billing-evaluation contract is CCBHC and
    MULTIPLE.
  - SD_ANNOUNCEMENTS "Technology and data grants": the Tech and Data initiative, primary F.
- Cases, 37 PURPOSE_TEXT rows on OpenSD contract descriptions:
  - EHR, HIE and cybersecurity: F
  - IT plus training: D and F
  - Equipment only: J
  - IT plus equipment: F and J, MULTIPLE (Monument Health $12,915,000 among them)
  - Caregiver Concierge app: C
  - Helpline Network of Care data modernization: F

## NOT_STATED (over $1M)
- **Rural Strong grants** (19 contracts, $25,318,346). The description is boilerplate ("Implementation of a Rural
  Strong Grant as a part of the federal Rural Health Transformation Program"). Neither the narrative nor any one-pager
  names "Rural Strong" or places it in an initiative. The Governor's release describes a mixed portfolio ("expanding
  rural care access, modernizing technology, strengthening care coordination and value-based care, supporting the rural
  workforce ..."), which spans groups and points to no letter.
- **"Named RHTP awards whose round the register does not state"** ($45.9M, award_pool level). Most of these rows are
  covered at description level, by the EHR and equipment PURPOSE_TEXT cases above. The pool label itself states nothing.
- **Programme administration, consulting, evaluation and workforce contracts** ($8.28M, pool label). Rows inside it
  are mapped by description where the description names a programme.
- **SD Health Link consultant** for the Digital Health Modernization and Technology Grant Program ($1,462,802): grant
  management, an administrative role.
- **Aging in Place Innovation Center** ($695,086), **western SD Regional Innovation Center** ($459,017), grant and
  administrative support, project management and strategic leadership: no single category, and not named in the plan.
- **activity_type_raw values** are procurement methods ("RFP (Linked) ...", "Sole Source ...") and state nothing.

# VA notes (session 123 use-of-funds evidence)

## Plan documents found
- Virginia DMAS, "Rural Health Transformation Program Application: CMS-RHT-26-001" (Project Narrative, "VA Rural Vitality"), https://dmas.virginia.gov/media/visgijnd/rhc-transformation-project-narrative.pdf, archived `data/evidence/use_categories/VA/2026-11-24_va_rht_project_narrative.pdf` (+ `.txt`). Four initiatives, each with a sub-initiative table and one "Uses of Funds" line: CareIQ (D, F: Tech Innovation Fund, Provider Productivity, Provider Interoperability, Remote Patient Monitoring); Homegrown Health Heroes (D, E, F, K: Attract and Retain Physicians, Allied Health Degrees, Earn to Learn Programs, Build Career Pipelines); Connected Care, Closer to Home (A, B, C, D, F, G, H, I, J, K: Mobile and Hybrid Care, Community Paramedicine, Innovative Maternal Care); Live Well Together (printed "A, B, C, D, F, G, I," with a trailing comma: Food as Medicine, Consumer Tech for Education and Lifestyle Changes, Active Kids, Integrated Care for Duals).
- The hhr.virginia.gov copy of the narrative returned 404; the DMAS copy (linked from rhtva's application page) was archived.
- Letters are per INITIATIVE, not per sub-initiative, so no unit gets a primary letter from the plan; none of the award labels points to one letter within a multi-group initiative.

## NOT_STATED
- VA initiative/award_pool "Program evaluation" (1 row, $0): not a sub-initiative in any of the four initiative tables.
- VA source_document_title "Ways to Apply (Key Implementation Partner table)" (5 rows, $0): the regional collaboratives' rows are covered by "Mobile and Hybrid Care".
- VA_VHCF / VA_VHCF_PP `category` values (Electronic Health Data Exchange, etc.; CSBs, FQHCs, Hospitals/Health Systems ...): not mapped separately; the award_pool rows cover every row. The VHCF_PP categories are recipient types and must never be used.
- VA_FSRS award_pool "FSRS RHTCMS332088": covered by the two fsrs_description rows.

## Unreadable
hhr.virginia.gov narrative URL: 404 (DMAS copy used).

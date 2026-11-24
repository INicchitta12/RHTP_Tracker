# MI — use-of-funds evidence notes (session 123)

## Plan documents found
- **MDHHS Project Narrative** ("Rural Health Transformation Program Proposal, Michigan", 61 pp., image-only PDF),
  https://www.michigan.gov/mdhhs/-/media/Project/Websites/mdhhs/Assistance-Programs/Medicaid/RHT-Project-Narrative-Final_Cover.pdf
  -> `data/evidence/use_categories/MI/2026-11-24_mi_rht_project_narrative.pdf`. The PDF has no text layer; OCR text
  (tesseract 5.3.4) at `data/evidence/use_categories/MI/text/2026-11-24_mi_rht_project_narrative.ocr.txt`. One OCR
  misread on PDF page 32 ("LJ") was corrected to "I, J" after looking at the page image; the correction is stated in the
  file's first line. Every quote is from that OCR text, so a reviewer should check it against the PDF page images.
  Each of the four initiatives prints one "Use of funds" line:
  - Initiative 1, Transforming Rural Health through Partnerships: A, B, C, E, F, G, H, I, K
  - Initiative 2, Workforce for Wellness: A, B, C, D, E, F, G, H, I, K
  - Initiative 3, Interoperability in Action: A–K (all)
  - Initiative 4, Care Closer to Home Blueprint: A, B, E, G, H, J, K
- MDHHS RHTP Year 1 Annual Report (`2026-11-24_mi_rhtp_annual_report_year_1.pdf`): no CMS letters per initiative.
  It was archived for context.
- MDHHS RHTP Initiatives page (`2026-11-24_mi_rhtp_initiatives.html`): context only.

## Mapping
- 4 crosswalk rows at `initiative` level. All four are MULTIPLE.
- 11 crosswalk rows at `award_pool` (fund) level. Each carries its parent initiative's letters, because the narrative
  prints no per-fund letters. Five carry a primary letter taken from the fund title printed on the MDHHS award page:
  - E: Workforce Pipeline and Education; Provider Recruitment, Retention, and Capacity
  - F: Data Integration and Infrastructure; Interoperability and Governance
  - H: Advancing Rural Behavioral Health Blueprint

  The other six fund titles do not point to a single letter, so they stay MULTIPLE.

## NOT_STATED
- **Tribal Government** (13 rows, $8,656,410): this is the narrative's tribal carve-out ("a dedicated five percent
  carve-out of resources"). It sits outside the four initiatives, and the narrative gives it no use-of-funds letters.

# PA — use-of-funds evidence (session 123)

## Plan documents found
- **Pennsylvania Rural Health Transformation Plan - Project Narrative (February 2026)** (DHS). https://www.pa.gov/content/dam/copapwp-pagov/en/dhs/documents/rural-health/2026-02-06-pennsylvania-rural-health-transformation-plan-february-2026.pdf — archived `data/evidence/use_categories/PA/2026-11-24_pa_rhtp_project_narrative_2026-02.pdf`. Each of the six initiatives has a summary table with "Use of funds:" (Tables 3, 6, 10, 12, 14, 20).
  - Quote text file is `text/2026-11-24_pa_rhtp_project_narrative_2026-02.escaped.txt`: the pdftotext output with `&`, `<`, `>` written as entities. **Reason: `rhtp_use_quote_found()` strips `<[^>]*>` from plain-text files too, and the narrative's literal "<250,000" ... "> 5,000" made it delete ~900 lines (four of the six tables).** Recorded in the PA MANIFEST. Worth fixing in the checker (strip tags only for .html).
- The older URL `.../pa-rural-health-transformation-plan.pdf` now 404s.
- DHS Year 1 overview slides (2026-03-30), archived: "Every project must tie back to the project narrative" and lists the same six initiatives.

## Coverage
- 6 crosswalk rows on `initiative_raw`, 170 rows, $116,009,668. Primary pointed by the initiative label the award page prints: **Behavioral Health -> H**, **Workforce -> E**. Tech & Infrastructure, Maternal Health, Aging and Access, EMS & Transportation are MULTIPLE.
- 1 PURPOSE_TEXT case (K) on the PREP `project_description` (8 Year One Non-Solicitation rows, $831,210: establishing regional Rural Care Collaboratives and regional coordination), which carry no initiative.
- **$116,840,878 of $116,840,878 (100%)**; single-primary $60,600,340, MULTIPLE $56,240,538.

## NOT_STATED
- None.

## Unreadable
- None.

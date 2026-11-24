# WI — use-of-funds evidence notes (session 123)

## Plan documents found
- **DHS RHTP application narrative**, https://www.dhs.wisconsin.gov/business/dhs-rhtp-application-narrative.pdf
  -> `data/evidence/use_categories/WI/2026-11-24_wi_rhtp_application_narrative.pdf` (text in `text/`). Use of Funds:
  - Initiative 1, Rural Talent Recruitment and Retention: D, E, G, H, K
  - Initiative 2, Interoperability Infrastructure and Modernization: A, C, D, F, K
  - Initiative 3, Population Health Infrastructure: A, B, C, E, F, G, H, I, J, K
- **DHS award pages** (already archived, `data/evidence/WI/2026-11-19_dhs_rhtp_{workforce,technology,coordinated-care}.html`).
  They print every award under "Initiative N, Project M" with its lead agency and Budget Year 1 amount. That is the link
  basis for every row.

## Mapping
- Crosswalk, 17 rows:
  - 5 at award_pool level:
    - CHW grants and CHW training provider grants: Initiative 1, Project 2. Primary E.
    - Rural Technology Transformation funds: Initiative 2, Project 1. Primary F.
    - Rural Dental Efficiency and Access: Initiative 2, Project 1. MULTIPLE.
    - Sources of Strength: Initiative 3, Project 2, Behavioral Health Innovations. Primary H.
  - 12 implementation partners at `row` level, because the implementation table carries no activity. Each partner's
    initiative project is printed on the initiative pages with the same Budget Year 1 amount. Primary is taken from the
    project title where it points to one letter:
    - E: workforce readiness, rural workforce grants, higher education, dentist residency
    - H: WISCOPE psychiatry extension
    - F: WISHIN information exchange

## NOT_STATED
- **Implementation partners rows 11–14** ($3,714,752.36 together): UWPHI County Health Rankings ($598,682), UWPHI
  Envision ($2,250,000), WCHQ ($504,467) and WI Office of Rural Health ($361,603.36).
  - The initiative pages print no project for these four by name.
  - UWPHI appears as lead agency on three workforce studies and TA ($250,000 + $500,000 + $1,500,000 = $2,250,000), but
    the pages do not say which UWPHI unit leads them. They were not linked.

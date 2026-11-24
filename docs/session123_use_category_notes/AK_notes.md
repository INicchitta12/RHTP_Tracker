# AK — use-of-funds evidence (session 123)

## Plan documents found
- **Alaska RHTP Project Narrative and Supporting Documents** (DOH). https://health.alaska.gov/media/bxangqdz/alaska-rhtp-project-narrative-and-supporting-documents.pdf — archived `data/evidence/use_categories/AK/2026-11-24_ak_rhtp_project_narrative.pdf` (text: `text/2026-11-24_ak_rhtp_project_narrative.txt`). Table 7 "Proposed Initiatives" prints an Alignment row "Use of Funds: ..." for each of the six initiatives (text lines 1098, 1255, 1339, 1445, 1536, 1637).
- **Alaska RHTP: Potential Uses of Funds** (DOH, rev. 2026-02-19). https://health.alaska.gov/media/dzlpmrzp/rhtp-potential-uses-of-funding.pdf — archived `2026-11-24_ak_rhtp_potential_uses_of_funding.pdf`. Lists the same six initiatives (prose uses, no CMS letters); used only to confirm the initiative names.

## Coverage
- 6 crosswalk rows on `initiative_raw` (the award notice's Initiative column), all six initiatives, 254 rows, **$248,976,548 (100%)**, INITIATIVE_CROSSWALK.
- Every initiative's letters span several NOFO groups and the initiative label points to no single letter, so every row is **MULTIPLE** (primary blank). Strengthen Workforce (D;E;J;K) is the narrowest.
- No cases: the award notice prints no CMS letter (no AWARD_SOURCE), and PURPOSE_TEXT on `project_summary` would rank below the crosswalk for every row, so it was not coded.

## NOT_STATED
- None (every Year 1 row carries an initiative).

## Unreadable
- None.

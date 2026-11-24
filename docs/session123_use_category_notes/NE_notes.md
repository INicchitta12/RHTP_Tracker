# NE — use-of-funds evidence notes (session 123)

## Plan documents found
- **NE Final Project Narrative RHTP 2025**, https://dhhs.ne.gov/Documents/NE%20Final%20Project%20Narrative%20RHTP%202025.pdf
  -> `data/evidence/use_categories/NE/2026-11-24_ne_final_project_narrative.pdf` (text in `text/`). It gives one Use of
  Funds table per initiative:
  - 1, Food as Medicine: A, D, F, J
  - 2, Regionalized Access and Navigation: A, C, D, E, F, G, H, I, J, K
  - 3, Workforce Acceleration: D, E, F, G, J, K
  - 4, eHealth and Mobile: A, C, D, E, F, G, I, J, K
  - 5, Emergency Behavioral Health: D, E, F, G, H, J, K
  - 6, ALF Special Needs: B, G, J, K
  - 7, NETECH: A, C, D, F, I, K

  The narrative numbers its programmes 1.1–5.4 under these initiatives. The tables are laid out in columns, so each
  quote is the table's lines joined with " | ".
- **DHHS "RHT Nebraska Initiatives"** one-pager (`2026-11-24_ne_rht_initiatives.pdf`), archived for context.
- **CMS RHTP Obligated Funds Report**, 10-14 edition (already committed). Text extracted to
  `text/RHTP-Obligated-Funds-20261014.txt`.

## Mapping
- **NE** (DHHS Public Notices of Award): 5 pools, all mapped by sub-initiative number. 4.4a has primary A and 3.3 has
  primary E. 4.4b (x2) and 5.3 are MULTIPLE.
- **NE_FSRS**: 40 of 60 distinct FFATA descriptions are mapped by crosswalk, covering $86,211,139.11 of $93,204,214.04.
  - Most links come from an explicit sub-initiative number in the description (for example "INITIATIVE 2.3A",
    "FOCUS ON 1.1 ...", "2.4 VETERAN EHR COORDINATION").
  - The rest link on the same programme name: NETECH (Initiative 7, $20M), ALF Modernization (Initiative 6), Nebraska
    Teeth Forever (4.2), food pantry (1.2) and mobile maternal health clinic (4.1).
  - Primaries come from the sub-initiative's own text: 3.2 and 3.4B are E; 4.4A and 2.3A are A; 5.1 and 5.4 are H.
- **NE_FSRS cases**: 6 PURPOSE_TEXT rows. Each is a "promote healthy living and reduce obesity rates" description with
  no initiative number, coded A.
- **NE_CMS cases**: 5 AWARD_SOURCE rows. The CMS obligation report, which is the rows' own source, prints each line
  under a CMS use-of-funds heading:
  - Appropriate Care Availability: G
  - Capital Expenditures and Infrastructure: J
  - Consumer Tech Solutions: C
  - Training and Technical Assistance: D

  This is an obligation report, not a state award document. Treat it as AWARD_SOURCE with that caveat.

## NOT_STATED (FSRS descriptions with no initiative number and no single-category purpose)
None of these is over $1M individually.
- Infection prevention infrastructure ($985,845)
- CHW preventive care, no number ($964,302)
- Statewide LHD implementation support, initiative "0.1", administrative ($841,040)
- Urgent dental clinics ($852,600 across two descriptions)
- Robotic surgery ($546,000)
- Evaluation ($300,000)
- Medical countermeasures, no number (about $426,000)
- Ponca oral health ($200,657)
- Kearney County ($200,000)
- CHW chronic-disease curricula, no number (about $494,000)

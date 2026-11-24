# Nevada (NV) -- use-of-funds evidence

## Plan documents found
- **Nevada RHT Program Project Narrative** (application, CMS-RHT-26-001, submitted 2025-11-05) -- https://nvha.nv.gov/uploadedFiles/nvhanvgov/content/Community/Project%20Narrative.pdf. Archived `data/evidence/use_categories/NV/2026-11-24_nv_rhtp_application_project_narrative.pdf` (+ text). Section IV prints a "Use of Funds" line per initiative:
  - #1 RHOAP: Prevention and chronic disease; behavioral health; appropriate care availability; innovative care (A, H, G, I)
  - #2 Rural Health System Flex Fund: Capital expenditures and infrastructure (J)
  - #3 WRRAP: Workforce (E)
  - #4 RHIT: IT advances & consumer tech innovation (F, C)
- NVHA "Use of Funds Guidance" (March 2026) and the four initiative one-pagers (Flex, RHIT, RHOAP, WRRAP, March 2026), https://www.nvha.nv.gov/siteassets/content/community/rhtp/... -- archived under `data/evidence/use_categories/NV/` for context. They list allowable/unallowable costs and the state's own example "categories", no CMS letters.
- CMS abstract (Nevada): names the four initiatives, no letters.

## Mapping
- `section` covers every NV row: the four plan initiatives mapped (10 section values, both the BP1 web page and the BP1 Subrecipient Report spellings).
- RHOAP is multi-group: 12 project_description rows carry a primary pointer (H, A or I) from the award's own description.
- PURPOSE_TEXT (LOW): Presidential Fitness Test (A, $1,377,413), Rural Veterans Health Transformation (F, $1,271,512.04), one Tribal IT/cybersecurity award (F, $1,426,587.21).

## NOT_STATED
- Tribal section other than the IT award (5 rows, about $6.67M): the Rural Tribal Health Transformation fund is not a narrative initiative; descriptions name several groups at once (telehealth hub + ultrasound + pharmacy automation; tele-specialty + mobile outreach + chronic disease ...), or are vague ("Tribal healthcare modernization and expansion of healthcare services", $1,956,107.51).
- Rural Corrections Health Transformation ($976,255): description "Expansion and modernization of healthcare services, including telehealth" does not state a single category; no plan letters.
- RHOAP rows without a single-letter description (e.g. alternative payment row is pointed; telehealth/RPM rows such as "AI assisted remote patient monitoring" $1.35M and "Telehealth expansion" describe C/F, which are not RHOAP letters) stay MULTIPLE.

## Unreadable sources
- None.

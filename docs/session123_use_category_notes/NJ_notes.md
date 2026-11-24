# NJ use-of-funds evidence notes (session 123)

## Plan documents
- **NJ RHT Application (Project Narrative), https://www.nj.gov/humanservices/dmahs/home/NJ_RHT_Application_2025-12.pdf: UNREADABLE.**
  On 2026-11-24 the link answered HTTP 404, and so did several alternate paths.
  archive.org's availability API lists a 2026-01-18 snapshot, but web.archive.org resets at TLS from this environment (the known access fact) and WebFetch refuses the host.
  The NJ RHT site (https://nj.gov/rural-health-transformation/) lists five initiatives (Workforce Development, Infrastructure Development, Technology Innovation, Chronic Disease Control, Prevention) with no letters and no document links.
- **The six round RFAs were archived** to `data/evidence/use_categories/NJ/`:
  - DOHP26RHT
  - OHCF26RHC
  - DFHS26RDI
  - DPRE26AED
  - the nj.gov Chronic Disease, CHW and Advancing Technology/Prevention/Workforce RFAs

  **None prints a CMS use-of-funds letter.** They cite only Section 71401, so they give no STATE_SOLICITATION crosswalk.
- The CMS abstract for NJ (`data/raw/cms/2026-08-27/rht_program_state_provided_abstracts.txt`, line ~1607) prints no letters either.

## Mapped
- **No crosswalk**, because no readable plan source carries letters.
- **56 PURPOSE_TEXT cases** on `activity_raw` (the award list's per-award "Activity" text), totalling **$56.0M of $83.1M**.
  - Quote source: the award PDF `data/evidence/recheck/2026-09-24/NJ/njrht_funding_allocations_2026-07-31.pdf`, via its reading-order text `text/njrht_funding_allocations_2026-07-31.raw.txt`.
  - Where a description is split across a page break, the quote is the verbatim sentence or sentences found, joined with " | ".
  - Many descriptions name several groups and are recorded MULTIPLE.
- **E means workforce development or recruitment as the description words it.** The NOFO's 5-year service commitment is not verified by any description.

## NOT_STATED (45 descriptions, $27.0M), the largest
Each of these was left because its activity has no clean letter (in parentheses: what it describes):
- Mobile Integrated Health / prehospital whole blood programmes, 5 awards, ~$7.19M (care model plus EMS blood program).
- "End-to-end virtual nursing model" (Vineland, Elmer, Mannington), $4.13M (virtual staffing and care-coordination model; tech vs care model is unclear).
- Hackettstown and Newton Medical Center "three programs" (Transitions of Care, Food Is Medicine, tele-neurology robots), $2.92M (each program would be a different group, but the description gives no basis to say one dominates; left rather than guessed).
- Care-transition virtual platform, $1.09M.
- 9-1-1 clinician-led triage, $1.05M.
- Doula programmes (no NOFO letter fits doula services cleanly), $1.8M.
- Youth violence prevention, $710K.
- Generic "technology solutions" descriptions (657K, 585K).
- CHW navigation and SDOH programmes.

## Unreadable
- The NJ application, as above. If the owner can supply the application PDF (the 2026-01-18 Wayback snapshot), a crosswalk from NJ's five initiatives to letters could replace much of this.

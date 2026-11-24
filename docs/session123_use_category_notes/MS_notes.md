# MS notes (session 123 use-of-funds evidence)

## Plan documents found
- Mississippi RHTP Project Narrative (Governor's Office, 4/28/26), https://mississippirhtp.com/wp-content/uploads/2026/04/Project-Narrative_GovOffice4_28_26.pdf, archived `data/evidence/use_categories/MS/2026-11-24_ms_rhtp_project_narrative_2026-04-28.pdf` (+ `.txt`, which holds only the text pages). Pages 12-47 (the "PROPOSED INITIATIVES AND USE OF FUNDS" tables) are IMAGES. The "Use of Funds" rows were OCR'd (tesseract, 300 dpi) into `data/evidence/use_categories/MS/text/*_pageNN_OCR.txt` (provenance in `text/PROVENANCE.txt`) and checked by eye against the page images. Letters as read: Statewide Assessment I, K (p16); CRIS A, D, F, G (p21); WEI D, E, K (p26); HTAM C, D, F, J, K (p29); TAPS B, C, D, E, F, I, J, K (p33); BRIDGE D, E, "G. Capital Expenditures and Infrastructure", I, K (p37).
- SOURCE DEFECT (BRIDGE, p37): the letter G is printed with category J's name. Letters are recorded as printed (G); flagged on both BRIDGE rows (RCGC $43.3M and PES $13.3M).
- State initiative page https://mississippirhtp.com/htam/ archived `data/evidence/use_categories/MS/2026-11-24_ms_rhtp_htam_page.html` (links Rural Provider Technology Grants to HTAM). Archived as served; it carries WordPress form nonces (public newsletter-form tokens, not credentials) and no API key.
- WEI NOFO RHTP-WEIFY2027-001 archived `data/evidence/use_categories/MS/2026-11-24_ms_wei_nofo.pdf` (names the four WEI grant programs; its PDF text is letter-spaced). RCGC/RTG/TCE NOFOs were read (not archived); they print no CMS letters and name no initiative.
- CMS abstract: prose only, no letters.

## Links
RCGC, TCE and PES link by name to the narrative's sustainability-plan sub-programmes (text pages 60-61); RTG links through the HTAM page; the four round-2 WEI rounds through the WEI NOFO. All units are MULTIPLE (no award text points to a single letter strongly enough; RTG's "Technology" points to a group, not a letter).

## NOT_STATED
None: all 8 award_pool units mapped (MS 167 rows $104,115,146.80; MS_R2 60 rows $32,606,496.32).

## Caveat
Every MS quote comes from OCR of an image page, not from publisher text. If the coordinator's rules exclude OCR-derived quote files, all eight MS rows fall back to NOT_STATED.

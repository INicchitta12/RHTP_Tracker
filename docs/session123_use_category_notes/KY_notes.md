# KY use-of-funds evidence notes (session 123)

## Plan documents
- **Kentucky RHTP Project Narrative CMS-RHT-26-001**: https://ruralhealthplan.ky.gov/Documents/KY%20RHTP%20Project%20Narrative_CMS-RHT-26-001.pdf
  Archived: `data/evidence/use_categories/KY/2026-11-24_ky_rhtp_project_narrative_cms-rht-26-001.pdf`.
  **The PDF text layer is unusable** (Type 3 fonts, no ToUnicode). Quotes come from an OCR of the archived PDF: `text/2026-11-24_ky_rhtp_project_narrative_cms-rht-26-001.ocr.txt` (tesseract, 200 dpi).
  Each of the five initiatives prints a "Use of Funds:" line:

  | Initiative | Letters | PDF page |
  |---|---|---|
  | Rural Community Hubs for Chronic Care Innovation (RCH) | A,C,D,E,F,G,I,J,K | 20 |
  | PoWERing Rural Maternal and Infant Health | A,B,C,D,E,F,G,H,I,K | 27 |
  | Rapid Response to Recovery (RRR/R3) | D,E,F,G,H,I,J,K | 33 |
  | Rooted in Health (RIH) | A,B,D,E,F,G,I,J,K | 38 |
  | From Crisis to Care (CTC) | A,B,D,E,F,G,K | 44 |

  Every initiative spans several groups, so every KY mapping is MULTIPLE.
- **KY DPH October 2026 Update (CMS approved v2)**: archived `2026-11-24_ky_rhtp_oct_2026_update_cms_approvedv2.pdf`. It names the five programs and their abbreviations, and has no letters.
- **KY Executed Contract Tracker (2026-09-08)**: already committed at `data/evidence/recheck/2026-11-02/KY/`. The text is at `text/2026-11-02_KyRHT_Executed_Contract_Tracker_2026.09.08.txt`, and the repo parse is `data/reference/contracts/ky_contracts.csv`. It gives an initiative code per contract.

## KY_FSRS: row-level links
Every KY FFATA filing (41 rows, $101.0M) carries only the boilerplate "KENTUCKY RURAL HEALTH TRANSFORMATION PLAN", so the `fsrs_description` unit stays NOT_STATED. Instead, 16 rows ($64.0M) are linked row by row (`match_field = row`) to the contract tracker's initiative code:
- **13 exact awardee + amount matches.**
- **Row 35 (Northern Kentucky District HD), name-level.** All four of that awardee's contracts are RIH.
- **Row 12 (KY Primary Care Association), name-level.** Its only contract is CTC, but the amounts differ. A weaker link.
- **Row 1 (Foundation for a Healthy Kentucky, $50,490,600), by arithmetic: please review.** 26 of FHKY's 27 contracts are RCH and one is RHTP Admin. The FSRS amount equals the RCH contracts less one $405,000 RCH line, and cannot include the admin line. This is an arithmetic link, not a stated one.

## NOT_STATED (over $1M)
Each of these has no exact tracker match and holds contracts under several initiatives (or is not on the tracker), so it is not linked:
- KY_FSRS row 2, UK Research Foundation ($11,860,969). Its tracker contracts span all initiatives plus RHTP Admin.
- row 3, Baptist Health Deaconess Madisonville ($3,529,444). Not on the tracker.
- row 4, University of Pikeville ($3,176,807)
- row 5, On Demand Kare ($2,835,087)
- row 7, Campbellsville University ($2,300,813)
- row 9, Kentucky State University ($2,065,481)
- row 13, KY River District HD ($1,743,270). Multi-initiative.
- row 14, University of Louisville ($1,617,615). Multi-initiative.
- row 15, KY River District HD ($1,410,898). Multi-initiative.
- row 23, Appalachian KY Health Care Access Network ($428,988). The tracker initiative is "All".

## Unreadable
None. The narrative's text layer needed OCR (see above).

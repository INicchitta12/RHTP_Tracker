# TN — use-of-funds evidence (session 123)

## Plan documents found
- **Tennessee RHTF Application, full document** (TDH). https://www.tn.gov/content/dam/tn/health/TN_RHTF_Application_Full_Document.pdf — archived `data/evidence/use_categories/TN/2026-11-24_tn_rhtf_application_full_document.pdf`. "Proposed Initiatives & Use of Funds" prints "Use of Funds:" for all 17 initiatives. www.tn.gov answered **403 (118 bytes) intermittently** to the honest agent: four attempts refused, the fifth served 200; recorded in the MANIFEST.
- TDH rural page (Competitive Grant Project Lines) and the 2026-05-15 competitive kickoff deck were read (not archived): they list HART, End Zone, MCAN, Perinatal Teleconsultation and Rural Fetal and Infant Health as separate RFAs and **do not tie HART, End Zone, EMS or Rural Fetal and Infant Health to an application initiative number**.

## Coverage
- 3 crosswalk rows on `fsrs_description` (TN_FSRS): Maternal/Infant and Child Health HRP ($30,644,014) -> initiative 7 HRP: Maternal and Child Health; Uninsured Adult Healthcare Safety Net ($10,484,210) -> initiative 3 Optimizing Rural Health Care; MCAN ($1,500,000) -> initiative 4. All MULTIPLE.
- 2 PURPOSE_TEXT cases: End Zone for Chronic Disease Prevention ($3,200,000) -> **A**; Perinatal and Pediatric Behavioral Health Teleconsultation and Education ($115,500) -> **H**. Quote text is the FFATA description in `data/reference/tn_fsrs_awardees.csv`; archive is the USAspending zip.
- **$45,943,724 of $54,615,732 (84.1%)**: crosswalk $42,628,224, purpose $3,315,500.

## NOT_STATED (over $1M)
- EMS RHTF ($4,276,454, 14 rows): the description names only "EMS"; the application's Last Mile Teams (initiative 2) covers rural emergency care, but no TN source ties the EMS RHTF filings to it (topical only).
- HART, Healthy Active Rural Tennessee ($3,831,081, 53 rows, TN file): TDH calls it an "RHTP priority" and lists it as its own RFA; no source links it to an application initiative (the nearest, 10 Rural Health Improvement Grants "upstream prevention, nutrition, and active living", is topical). Its projects mix programmes and park/trail construction, so the round label is not one category.
- Smaller: Rural Fetal and Infant Health Initiative ($519,283), "RHTP 3.1 AND 3.2 ALLOWABLE COSTS" ($45,191; names no programme).

## Unreadable
- www.tn.gov intermittent 403 (see above); not a finding about the state.

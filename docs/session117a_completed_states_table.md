# Session 117a (2026-11-13): completion check of 42 states; completed-states table

## Result
- Newly COMPLETE (state-source full-obligation sentence, archived under
  `data/evidence/recheck/2026-11-13/<ST>/`, confirmed by an independent check):
  - NE: DHHS Year 2 release, 11-10: "Nebraska received $218.5 million for year one, which has been fully obligated to implement all seven initiatives ..."
  - SD: Governor/DOH Year 2 release KB0047476, 11-10: "In Year One, South Dakota committed every dollar of its $189.5 million Rural Health Transformation award by the federal deadline, through 234 agreements ..."
  - WV: Governor/DH Year 2 release, 11-09: "West Virginia enters the second year having obligated 100 percent of its initial award through 145 signed awards and agreements, all finalized ahead of the October 30 federal deadline."
- HELD for the owner (full-obligation sentence AND a known Year 1 remainder, the Iowa test):
  - WA: HCA 11-05/06 "these funds are 100% obligated, which means CMS legally commits to providing all the funding" (HCA's gloss reads as the federal obligation); same page: "DOH will open a funding opportunity for rural provider incentives in November" ($9.89M line). Archived.
  - NC: NCDHHS 11-02 "The state obligated all funds allocated to North Carolina within the first year"; Rural Health Innovation Fund awards "January 2027", ROOTS Hubs "will soon begin funding projects". Archived.
  - IA: unchanged (10-09 "fully obligated"; four Healthy Hometowns NOIAs still unposted).
- Borderline, not COMPLETE: LA (notifications complete, contracts in November; unchanged), CA (CMS 10-29 "committed its full fiscal year 2026 funding" vs HCAI "Additional awards are pending"; archived, Mapbox token stripped, both digests in `CA/DIGESTS.csv`), TN (11-09 "full list" of 138 projects, $422,241,081.71 five-year "Awarded or Requested"; archived, NOT extracted), MO (11-12 "committed $216 million" but "$55 million in funding opportunities" still to come; archived), AZ ("targeted to be fully committed by October 30"), MD (Year 2 release: "awarded nearly $129 million ... to 187 organizations" of $168M).
- Unreadable: KS (KDHE + governor 403), MA (mass.gov 403), RI (EOHHS/Governor 403; ri.gov press has nothing).
- Still partial: every other state.

## Extracted (standing pre-approval)
- WV 11-10 "nearly $17 million" release, `R/03av` key `dia`, 7 rows / $16,976,480: Cabell Huntington Hospital $1,544,313 (CCN 510055 in the basis, not on the row: the CAMC precedent) the one hospital row; Marshall University Research Corporation x3, WVPCA, ROAM WV x2 non-hospital. Footer prints BP1 + full Year 2 ($401,557,453), checked against the 11-09 Year 2 release's $202,081,355 inside R/03av rather than widening `rhtp_footer_class()`.

## Figures
- year1_summary_2026-11-13: awards $6,206,479,685.27; best estimate $2,474,926,623.89; strict NAMED $2,171,969,559.88 (each moved only by WV's release).
- Completed-states table (11 states): allotment $2,230,243,286; awards $1,851,802,065 (83.0%); hospital best estimate $755,163,077 (40.8% of awards, 33.9% of allotment); strict $697,617,608; intents 30.4%.

## Leads, not acted on
- TX 11/5 weekly list (not archived); PA Temple University $3,265,883 (Statewide Tech & Infrastructure); SC Tech Catalyst Fund four companies, $2.2M, no split; WA HCA PDF first-tier lines (not per recipient); MD's 187 organisations vs our 79 rows.
- CMS's 11-09/11-12 Year 2 release and fact sheet are not archived; `cms_national_events.csv` / `cms_fy2027_allotments.csv` not updated (Year 2: hold).
- LA probe's "IMPORTANT DATES - BUDGET YEAR 1" anchor needs re-basing (heading now "IMPORTANT DATES").
- `R/03aw` now coerces `fiscal_year` to character when binding a state's files (NE's files disagree on its type).
- R/09b then R/07 re-ordered columns in 49 files (FSRS columns after spend columns); the commit restores each file's committed order, so the diff is content-only.

## Tests
Re-pinned test_03av, test_03aw, test_07, test_08 (committed build now 2026-11-13). Run and passing: those four, test_state_union, test_claude_md_status_table. Full suite NOT run (instruction).

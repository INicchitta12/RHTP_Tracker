# FL — use-of-funds evidence (session 123)

## Plan documents found (none states CMS letters)
- **Award document**: Governor's "Florida Rural Health Transformation Program | Year 1 Awardees" PDF. https://flgov.com/eog/sites/default/files/shared/2026/08/RHTP%20-%20PDF.pdf — archived `data/evidence/use_categories/FL/2026-11-24_fl_rhtp_year1_awardees.pdf` (+ `.txt` beside it). Prints six grant-category headings by region (Preventive Care and Care at Home, Specialty and Acute Care, Value-Based Care, Rural and Satellite Clinics, Workforce Development, Health and Lifestyle) and no CMS letter. No award-file field carries the heading, so cases match on `row` (`<row_no>|<awardee>`).
- **Florida RHTP application (grant submission, 2025-11-03)**, 111-page image-only PDF. https://ahca.myflorida.com/content/download/27598/file/11032025_Grant%20Submission.pdf — archived `2026-11-24_ahca_rhtp_grant_submission_2025-11-03.pdf` (38 MB). OCR'd in scratch only (not archived): its 15 initiatives each have a "Use of Funds:" line, but in **prose** ("Start-up and expansion costs, health information technology upgrades, workforce training ...") with **no CMS letters**. Mapping that prose to letters would be my reading, not the state's, so no crosswalk row was written.
- **FL Revised Budget 2.10.26** (AHCA). https://ahca.myflorida.com/file/rhtp/FL%20Revised%20Budget%202.10.26.pdf — archived; 15 initiatives, no letters.
- **FL annual report to CMS (08.26)**, xlsx. https://ahca.myflorida.com/file/rhtp/08.26_Florida_Annual_Report.xlsx — archived. Its "Use of Funds" tab has a per-obligation **"Use of Funds Category"** column, but as of this edition only AHCA's own administrative lines are filled ("N/A (Program Administration Expense)"). **A later edition will likely state the category per first-tier award; re-check it.**
- AHCA RHTP page and TA grant-requirements deck archived; neither maps the grant categories to letters or to the 15 initiatives.

## Coverage
- 25 PURPOSE_TEXT cases (LOW) on `row`: the award document's own heading is a single NOFO category for two headings — **Workforce Development -> E** (13 rows, $9,324,015.39) and **Value-Based Care -> I** (12 rows, $9,999,999.74). Total **$19,324,015 of $188,201,256 (10.3%)**.

## NOT_STATED (over $1M)
- Preventive Care and Care at Home ($103,294,194): spans prevention, home monitoring and care at home; no single category and no state letters.
- Specialty and Acute Care ($32,355,582): no single category.
- Rural and Satellite Clinics ($23,400,000): the plan's Initiative 1 of the same name lists prose uses only.
- Health and Lifestyle ($9,827,465): the plan's Initiative 9 of the same name lists prose uses only; the heading alone is not clearly one category.

## Unreadable
- None (the grant submission is image-only, OCR used to read it).

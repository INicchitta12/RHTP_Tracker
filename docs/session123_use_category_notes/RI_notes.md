# RI notes (session 123 use-of-funds evidence)

## Sources
- The RI award file (`ri_year1_awardees.csv`) is built from CMS's RHTP Obligated Funds Report (10-14 edition, data as of 2026-07-31), committed at `data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf`. That document is the award source for these rows, and it prints every obligation bullet under a CMS use-of-funds category heading (e.g. "Behavioral Health ($1,115,900)") inside an initiative heading. Each award_pool unit ("Initiative N: ... | <category>") is therefore AWARD_SOURCE, one letter, in `RI_cases.csv`. Text: `data/evidence/use_categories/RI/text/RHTP-Obligated-Funds-20261014.txt` (pdftotext -layout of the committed PDF).
- No RI project narrative was sought: the award source already states the category. (EOHHS, governor.ri.gov and RIDOH are Cloudflare-403 to this environment per session 106.)

## NOT_STATED
- Every "| Program Administration Expense" unit (13 units, ~$2.0M in total, e.g. Initiative 10 $363,034.58, Initiative 11 $408,914.36): administration is not a CMS use-of-funds category.
- RI_FSRS fsrs_description "SUPPORT RURAL COMMUNITIES TO IMPROVE HEALTHCARE ACCESS ... AS NEEDED TO BEST SERVE RURAL COMMUNITIES." (5 rows, $37,724,386.79): boilerplate; states no activity. No initiative is named in the FSRS rows.

## Unreadable
None used.

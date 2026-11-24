# DE use-of-funds evidence notes (session 123)

## Plan documents
- **Delaware RHTP Project Narrative (1.16.2026)**: https://dhss.delaware.gov/wp-content/uploads/sites/12/2026/06/RHTP_Project_Narrative_1.16.2026.pdf, linked from the DHSS RHTP page archived at `data/evidence/DE/2026-09-03_de_dhss_rhtp_programme.html`.
  Archived: `data/evidence/use_categories/DE/2026-11-24_de_rhtp_project_narrative_20260116.pdf` (+ `.txt`).
  The host intermittently answered HTTP 999 (bot screen); the third attempt was served 200.
  Each of the 15 initiatives prints a "Permissible Uses of funds" line:

  | # | Initiative | Letters |
  |---|---|---|
  | 1 | Hope Center | A,B,G,H,J,K |
  | 2 | Community Health Hubs | A,B,G,H,K |
  | 3 | SBHC Expansion | A,B,G,H,J,K |
  | 4 | Food is Medicine | A,B,C,D,G,I,K |
  | 5 | Libraries | A,C,F,G,H |
  | 6 | Rural Provider and FQHC VBC Readiness | A,B,C,D,G,H,I,K |
  | 7 | Catalyst Fund for Telehealth and RPM | A,C,G,K |
  | 8 | Diabetes Pilot | A,C,D,G,K |
  | 9 | Delaware Medical School | E,G,H,J,K |
  | 10 | Medical School Rural Workforce Development | E,G,H |
  | 11 | Rural Medical Residency | E,G,H |
  | 12 | Clinical Support Roles | E,G,H |
  | 13 | Rural Health Workforce Education | E,G,H |
  | 14 | Workforce Data Center | E,F,G,K |
  | 15 | Statewide HIT | A,D,F,H,I,K |

- Also in the repo: the revised budget narrative, `data/evidence/budget_narratives/DE/Final-RHTP-Revised-Budget-1.30.26.pdf`. It was not needed, because the project narrative carries the letters.
- FSRS full descriptions: `text/fsrs_DE_subaward_descriptions_2026-11-20.txt`, extracted from the committed FSRS zip.

## Judgement calls
- **DE_FQHC ($22.69M) is crosswalked to initiative 6, not by name.** The release's DHSS Secretary quote ties the FQHC awards to value-based care readiness, and initiative 6 names La Red and Westside as participants. The link basis says so. `round_name` carries the same value and was left unmapped to avoid duplicate rows.
- **Workforce training filings with no initiative named are PURPOSE_TEXT E**: Alzheimer's, BIAA, DHEC CCHW, DSU INSPIRE PLUS and MACHC.

## NOT_STATED
- **DE_FSRS "OBTAIN CERTAIN SERVICES TO ENABLE THE OVERSIGHT, AND DISBURSEMENT OF FUNDS..." ($14,550,000).** Fiscal oversight and disbursement services. No use-of-funds activity is stated.
- **DE_FSRS "DEVELOP, MARKET, AND ADMINISTER THE “1,000 FLOWERS BLOOMING” PROGRAM..." ($5,792,568.20).** Programme administration. The plan has no "1,000 Flowers Blooming" initiative, so the program it administers is not identified.
- **DE_FSRS Freedman Healthcare "GRANT IMPLEMENTATION SUPPORT SERVICES" ($679,960).** Programme administration.
- **DE_FSRS "FARM TO PHARMACY PILOT PROGRAM" ($275,000).** A title only, with no activity text. It may belong to Food is Medicine, but the filing does not say so.

## Unreadable
None. The narrative host's 999 is transient.

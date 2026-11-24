# WV use-of-funds evidence notes (session 123)

## Plan documents
- **West Virginia RHT Project Narrative (vF)**: https://governor.wv.gov/sites/default/files/2025-12/02_WV%20Project%20Narrative_vF.pdf, linked from https://governor.wv.gov/rht-application.
  Archived: `data/evidence/use_categories/WV/2026-11-24_wv_rht_project_narrative_vF.pdf` (+ `.txt`).
  Each of the seven initiatives has a "Mapping to strategic goals, use of funds, and technical score factors" table:

  | Initiative | Letters | Line in `.txt` |
  |---|---|---|
  | Connected Care Grid | B, C, D, F, G, H | 1039 |
  | Rural Health Link | F, H | 1274 |
  | Mountain State Care Force | D, E, F | 1475 |
  | Smart Care Catalyst | B, D, F, G, I | 1766 |
  | Health to Prosperity Pipeline | A, D, H | 1991 |
  | Personal Health Accelerator | A, D, H | 2239 |
  | HealthTech Appalachia | A, C, H | 2466 |

- **Provider Productivity Support Fund.** The plan puts the productivity support fund inside Smart Care Catalyst (line 1615). The 2026-09-22 award release instead calls it "one of seven statewide initiatives". The crosswalk follows the plan and records the conflict in the row note.
- The FSRS descriptions name their initiative ("THROUGH THE ... INITIATIVE"). Full text: `text/fsrs_WV_subaward_descriptions_2026-11-20.txt`, extracted from the committed FSRS zip.
- Mapped on the `initiative` field only. `award_pool` carries identical values and was left unmapped to avoid double rows.

## Row-level cases
The 2026-11-10 "$17M" round names four initiatives, so the round crosswalk is the union (MULTIPLE). Its release prints each award's purpose, so five rows also carry a PURPOSE_TEXT case:
- row 34: A;H
- row 35: C
- row 37: E
- row 39: E
- row 40: A

Two rows have no single call and carry only the round's union: 36 (WVPCA, A and C activities) and 38 (care coordination).

## NOT_STATED
- **WV "Not stated per award (release: 'additional provider productivity investments')", 2 rows, $2,363,000 (Minnie Hamilton).** The 2026-09-30 release describes a drone-delivery shared-service collaborative and AI clinical documentation. It names no initiative for either and gives no per-project amount. The phrase is not the fund's name, so the round is not linked. Row 14 is $0.
- **WV "Not named in the release (New Heights recovery-to-work program)", $250,000.** The release names no initiative. Recovery-to-work resembles Health to Prosperity, but that is topical only, so it is not linked.

## Unreadable
None.

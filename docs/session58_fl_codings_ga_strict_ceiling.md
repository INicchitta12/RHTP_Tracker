# Session 58 — Florida's ceiling closed; Georgia's ceiling is strict

## What was done

**Florida.** On the owner's instruction, session 57's three proposals were
applied to `data/reference/fl_year1_awardees.csv` by
`Rscript R/03ax_fl_ga_ceiling_pools_gaps.R --apply`:

| Rows | Awardee | recipient_type | basis_type / confidence | Basis |
|---|---|---|---|---|
| 71 | North Florida Rural Health Corp | NONPROFIT_CBO | ORG_WEBSITE / MEDIUM | IRS EO BMF, EIN 85-2728333, Chattahoochee: a 501(c)(3) clinic, in no CMS enrolment file |
| 16 | Empowerq Health Care | NONPROFIT_CBO | GENERAL_KNOWLEDGE / LOW | Hand-read bridge to Empower Healthcare, Inc., IRS 85-2591676, Pahokee. The LOW rating is about the match. No Florida hospital carries the name, so the row is not a hospital whether or not the match holds |
| 9, 18, 33 | Nuvita Health | VENDOR_OR_CONTRACTOR | GENERAL_KNOWLEDGE / LOW | OWNER-CONFIRMED as Nuvita Cellular Health, a cellular preventive medicine and biomarker testing platform. No federal record exists either way |

All five rows are now `distributed_to_hospital = No`. `recipient_type_source` still holds
the owner's original `UNCLASSIFIED`. Nothing else in the file changed.

**Result:** $6,331,219.97 leaves the ceiling. Florida's hospital share has a
**floor and ceiling of 26.2%** in `year1_complete_hospital_share.csv`, rebuilt by
`R/03aw --build`. No row moved into or out of a hospital bucket, so the
named-hospital figure stays at $49,345,213.46. `year1_completion_status.csv`
is unchanged.

**Georgia.** `ga_mixed_pool_split_search.csv` gains `ga_share_ceiling_pct`
(57.0, recomputed from the award file, with a test that holds it equal to the
session-56 table), `ga_true_share_vs_ceiling = STRICTLY_BELOW` and a sentence
explaining why. The 57.0% ceiling counts both mixed pools whole. Each pool contains
one non-hospital recipient that DCH says it funded: DBHDD's mobile dental
clinic award in Phase 2, and the assessments of all 87 hospitals in Phase 4. DCH
publishes neither amount, but both are positive, so the ceiling can never be
reached. Nothing is imputed for how far below 57.0% the true share lies.

## Persistence

`--apply` is an overlay keyed on row_no. It is idempotent, and it refuses a
row whose awardee does not match or whose hospital column is already `Yes`. It must run **after**
session 49's `vq_overlay`, which writes the same five rows' recipient_type.
Rebuild order: `R/03e --ingest` → 03ap overlay for Florida → `R/03ax --apply`.

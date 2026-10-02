# Session 87 — the owner's answers to session 86's three queue questions

Date: 2026-10-02. Three rows of `data/reference/classification_review_queue.csv`
moved from `OPEN` to `RESOLVED`, each on the owner's decision.

| Question | Decision | Rows / dollars moved |
|---|---|---|
| `SD_SYSTEM_PARENTS_FORM_NOT_STATED` | (a) Sanford Health (27RHT00031, $5,442,000) and Avera Health (27RHT00034, $1,565,000) are `HOSPITAL_OR_SYSTEM`, LOW, `basis_type = GENERAL_KNOWLEDGE`, no CCN, typed as system parents | +2 / +$7,007,000 `NAMED_HOSPITAL` |
| `OK_RRR_SWOSU_LOCAL_HOSPITAL` | (a) Southwestern Oklahoma State University stays `UNIVERSITY_OR_AHC` / `NON_HOSPITAL` / `Unclear`. The recipient is the university, and no hospital is named as receiving money (§0.3a) | $0 |
| `OK_CDM_CHOCTAW_TRIBAL_HOSPITAL_ENROLMENT` | (a) Choctaw Nation of Oklahoma stays `HOSPITAL_OR_SYSTEM` on its CMS tribal hospital enrolment, CCN 370172. This matches its microgrant row in `ok_year1_awardees.csv` (session 71) | $0 |

## What changed

- **`R/03i_sd_rht_contracts.R`** has a new `SD_SYSTEM_PARENTS` table, keyed on
  the contract number and the register's exact string. The build fails if
  either contract is missing, its string changes, or it no longer sits on §8's
  fallback. This follows the precedent of UVM Health Network and Southwestern
  Vermont Health (`R/03at`) and Virtua (`R/03bf`).
- **`sd_rht_contracts.csv`** has a new column, `basis_type`. The two parent rows
  carry `GENERAL_KNOWLEDGE`; every other row is NA. That lets a reader subtract
  these two rows the same way as other general-knowledge rows (§0.4).
- **Both rows sit inside the $31.5M Rural Strong round** (`round_id = RS`) and
  are never added on top of it.
- **The OK files** (`R/03bt`, `R/03bj`) changed only in text: "Queued:" became
  "Owner resolved". No coding changed.
- **Rural cut is unchanged** at 256 / $263,299,771.23. The parent rows carry no
  CCN, so they fall under `NOT_RECORDED`.

## Figures

```
NAMED_HOSPITAL   1,288 / $1,190,363,515.42 / 31  ->  1,290 / $1,197,370,515.42 / 31
SD contracts     12 / $9,636,252                 ->  14 / $16,643,252
```

The pins in `R/03ar`, `test_03ar`, `test_03ap`, `test_03bj` and `test_03i` were
updated to these figures, along with CLAUDE.md's Deliverable 1 and partition
block.

## Caveat for any published figure

The $7,007,000 rests on general knowledge that Sanford Health and Avera Health
are health-system parents. No state or federal record states that form, and
neither legal entity is a CMS-enrolled hospital. The money goes to a system
parent, not to a named facility, so it cannot be attributed to any one hospital,
and it is not part of the rural cut. Report it with the `GENERAL_KNOWLEDGE`
rows shown separately.

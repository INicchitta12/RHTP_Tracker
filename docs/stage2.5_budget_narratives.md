# Stage 2.5 — the budget-narrative parser and the §7A.4 reconciliation gate

**Session 7. Zero RCJ quota, no network calls.**
Code: `R/03b_budget_narratives.R`. Tests: `tests/testthat/test_03b_budget_narratives.R`
(86 assertions). Outputs: `data/interim/initiatives.{rds,csv}`,
`data/interim/initiative_reconciliation.{rds,csv}`,
`data/interim/initiative_format_detection.csv`.

```
Rscript R/03b_budget_narratives.R --validate   # parse + assert, no writes
Rscript R/03b_budget_narratives.R --build      # parse, assert, reconcile, write
```

---

## What this stage is for

§0.1 inverted the project: state budget narratives are the spine and RCJ is the
supplement. The reason is completeness. You can never characterise what RCJ is
missing, so you can never state a denominator, so no share computed from it is
defensible. CMS required a budget narrative from every state, so fifty documents
cover the full $10B — and they reconcile against the §7.1 allotment anchor,
which means **the parse self-validates**. That gate is §7A.4 and it is the whole
reason this stage sits ahead of Stage 4.

Two extractions are committed as reference implementations, and the parser is
built against **both**:

| | Oklahoma | Delaware |
|---|---|---|
| Sheet | `Fund uses (28)` | `Initiatives (Y1)` |
| Grain | 28 fund uses under 6 initiatives | 15 initiatives (14 rows; two share `initiative_no` 0) |
| Amount column | `amount_bp1` | `amount_y1` |
| Recipient column | `lead_agency`, on all 28 | `named_recipient_or_contractor`, TBD on 11 of 15 |
| `recipient_status` | absent — derived | present — carried |
| `extraction_method` | present | absent — defaulted |
| Document shape | structured, repeating, one page per fund use | narrative, variable, contract-by-contract |

Different sheet names, different column names, different grain, different
recipient column. §7A.1 is explicit: *"Assume format variation is the norm."*

---

## Why it detects format instead of hardcoding two readers

A parser tuned to one of these fails on the other, and the failure mode is not a
crash — it is a wrong dollar figure sitting under a right initiative name. So
the parser resolves columns by **synonym** against the §7A.3 canonical schema,
scores every sheet in the workbook, takes the best, and **refuses when it
cannot tell**.

One trap is worth naming because it is live in the Oklahoma workbook. `initiative`
looks like the obvious name column. It is not — it is the six-way grouping, and
`fund_use` is the row's own identity. Mapping `initiative` to `initiative_name`
would collapse 28 rows onto 6 names and lose 22 rows' identity silently. The
synonym list puts `^fund_use$` ahead of `^initiative$` for `initiative_name`,
each column can be claimed only once, and the grouping is kept separately as
`initiative_group` (which also becomes `activity_type_raw`, since it is the
state's own activity language and §7A.3 says never discard it).

Sheet scoring on the two fixtures:

| Workbook | Chosen sheet | Score | Runners-up |
|---|---|---:|---|
| `DE_initiative_table.xlsx` | `Initiatives (Y1)` | 10 | `Reconciliation` 2, `Named subrecipients` 2 |
| `OK_initiative_table.xlsx` | `Fund uses (28)` | 10 | `By initiative` 3 |

The parser refuses rather than guesses on: two sheets scoring identically, no
sheet meeting the §7A.3 minimum (an initiative name and a *numeric* budget), and
a workbook mixing two state codes — the last because §7A.4 reconciles per state
and a mixed table would reconcile against the wrong allotment. All four
refusals are tested.

`activity_type` stays `NA`. Mapping to the CMS allowable-use categories needs a
crosswalk that does not exist in this repo, and inventing one would be a
category claim nobody could check.

---

## §7A.4 — the gate, and what it caught

Two legitimate structures, both present in the reference states:

- **`TOTAL_INCLUSIVE`** — the narrative states a grand total equal to the award,
  with administration and indirect **inside** it. Delaware:
  $157,394,963.86 against a $157,394,964 award.
- **`ALLOCATED_ONLY`** — the narrative allocates fund uses that fall short, with
  administration and indirect held **outside** them. Oklahoma: $204,900,000
  allocated against a $223,476,949 award, 91.7%.

`reconciliation_structure` records which document a state wrote.
`reconciliation_status` judges **what was actually parsed**, in both structures
alike. That separation is the design decision that matters here, and Delaware is
why.

### Result on the two reference states

```
OK  ALLOCATED_ONLY   RECONCILED     91.7% of allotment  (204,900,000 of 223,476,949; 29 FUND_USE lines)
DE  TOTAL_INCLUSIVE  VARIANCE       84.6% of allotment  (133,082,267 of 157,394,964; 14 INITIATIVE lines)

QUARANTINED, not published (§7A.4): DE
```

**Oklahoma at 91.7% is exactly what §7A.4 predicts, and it passes.** "Reconciling
at 91.7% is not a failure; reconciling at 60% is."

**Delaware fails the gate, and it is right to.** Its narrative total is exact to
$0.14 — so a gate keyed on the *stated* total would have waved it through. The
committed extraction stops at Initiative 12 and covers 84.6% of the award, one
and a half points under the §7A.4 floor. The gate found the truncation on its
own, without being told about it.

The shortfall reconciles exactly:

| | |
|---|---:|
| Initiatives 13–15, not yet extracted | $10,105,200.00 |
| Personnel + fringe + travel + supplies (state admin) | $1,079,227.17 |
| Indirect (9.1%) | $13,128,269.21 |
| **Unreconciled remainder** | **$24,312,696.38** |

Add initiatives 13–15 and Delaware lands at **91.0%** — `RECONCILED`,
`ALLOCATED_ONLY` in substance, publishable. That is asserted in the tests, so
when the missing lines are extracted the gate will confirm them rather than
being taken on trust.

### The status ladder

| Status | Condition | Published? |
|---|---|---|
| `RECONCILED` | captured lines ≥ 85% of the allotment and not over it | yes |
| `VARIANCE` | 0 < captured < 85% | **no** — to review before being called a bad parse (§7A.4) |
| `FAILED` | captured exceeds the allotment beyond rounding, or is zero | **no** — a state cannot allocate more than it received |
| `NO_NARRATIVE` | no rows parsed for the state | **no** — a reportable gap (§7A.2) |

48 of 50 states are `NO_NARRATIVE` today. That is a statement about our
collection, not about the states — the same discipline §6.4 forced on
`NO_RCJ_DATA`.

---

## What the parser reproduces, and what it refuses to do

The §0.1b headline figures fall out of the parse rather than being carried over
by hand:

| | Oklahoma | Delaware |
|---|---:|---:|
| Hospital-directed | **48.7%** | **15.7%** |
| Unclear | 17.1% | 24.5% |

Both match §0.1b to a decimal place, which is the check that the parse read the
same rows a person did.

**The parser does not re-derive `has_hospital_recipient`.** That is a human
coding call under Part B of `reviewer-coding-instructions.md`, keyed on the
recipient (§0.3a) and often on flow language where no recipient is named at all
— Oklahoma names no hospital anywhere and still has $99.8M of hospital-directed
fund uses. The parser carries the coded value through and asserts it against the
§10.2 flow table. A `PASS_THROUGH_UNRESOLVED` row coded `Yes` is refused, which
is §0.3 (eligibility is not receipt) enforced in code.

**No initiative budget is ever divided across recipients** (§7A.5). There is no
per-recipient amount column for a sum to get wrong, and a test asserts the
budgets that come out equal the budgets that went in.

---

## `recipient_status`, and the §6.1 error in a new setting

Oklahoma carries no `recipient_status` column, so it has to be derived; Delaware
carries one and keeps it — the workbook's own column always wins.

The derivation strips quoted spans first, then TBD phrases, then asks whether
two consecutive capitalised words survive (with lowercase connectors allowed, so
"University of Oklahoma" counts). Stripping the quotes first is the part that
matters: both workbooks quote award-**programme** labels —

- `'3 Rural Provider/FQHC Readiness Awards' - recipients TBD`
- `'Lead Partner Institution' - accredited medical school, TBD`
- `'Health System Training Program Awards' $18.51M - recipients TBD`

— and reading those as recipient names is the §6.1 `PROGRAM_NAME_AS_AWARDEE`
error and the §0.3 error at once. Without the quote strip the derivation calls
all three `NAMED + TBD`; with it, all three are `TBD`.

It is deliberately conservative in the other direction too: a single-token
organisation name ("CareerTech", "Bayhealth") derives as `TBD`. Under-claiming a
recipient is the safe direction; over-claiming is how a programme label becomes
an awardee.

Fidelity, measured against the only hand coding available: **14 of 14 Delaware
rows**, and NAMED on all 28 Oklahoma fund uses, matching §7A.5's "Oklahoma names
a Lead Agency for all 28."

---

## Gaps this stage leaves open

- **`page_reference` is empty on every row.** §7A.3 wants it so a reviewer can
  open the archived PDF at the right page to check a figure. Neither reference
  workbook records one. The column exists and is visibly blank rather than
  silently absent.
- **`source_archive_path` is empty on every row.** No budget narrative PDF is
  archived under `data/evidence/budget_narratives/<state>/` yet. Delaware's is
  blocked (see below); Oklahoma's has not been fetched.
- **`activity_type` is unmapped**, pending a CMS allowable-use crosswalk.
- **`data/reference/budget_narrative_status.csv` (§7A.2) is not created.** It
  records what was searched and when, and nothing was searched this session;
  seeding 50 rows with a status nobody established would be a claim, not a
  tracker. It belongs to the collection pass.
- **48 states have no narrative.** Collection is §7A.2 and is the next task.

## One incidental fix

`R/01_retrieve_rcj.R`, `R/02_normalize.R` and `R/03_state_registry.R` guarded
their CLI blocks with `if (!interactive())`. Under `Rscript` that is true inside
a `source()` as well as at the top level, so Stage 2.5 sourcing Stage 3 for
`rhtp_load_cms_allotments()` would have re-run Stage 3's CLI against Stage 2.5's
own arguments — `--validate` would have fired `rhtp_validate_state_registry()`.
All five stage scripts now guard with
`!interactive() && identical(sys.nframe(), 0L)`, which is 0 only at the top
level of an `Rscript` invocation.

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
| Grain | 28 fund uses under 6 initiatives | 15 initiatives (17 rows; two share `initiative_no` 0) |
| Amount column | `amount_bp1` | `amount_y1` |
| Recipient column | `lead_agency`, on all 28 | `named_recipient_or_contractor`, TBD on 12 of 17 |
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
DE  TOTAL_INCLUSIVE  RECONCILED     91.0% of allotment  (143,187,467 of 157,394,964; 17 INITIATIVE lines)

QUARANTINED, not published (§7A.4): none
```

> **Session 8 closed Delaware.** The block above is the current result.
> Delaware read `VARIANCE / 84.6% / 14 lines` from session 7 until initiatives
> 13–15 were extracted; that history is kept below because the gate finding the
> truncation unaided is the case for the gate. The regression test now
> reproduces it by truncating the fixture rather than by leaving the state
> short.

**Oklahoma at 91.7% is exactly what §7A.4 predicts, and it passes.** "Reconciling
at 91.7% is not a failure; reconciling at 60% is."

**Delaware failed the gate, and it was right to.** Its narrative total is exact
to $0.14 — so a gate keyed on the *stated* total would have waved it through.
The session-7 extraction stopped at Initiative 12 and covered 84.6% of the
award, one and a half points under the §7A.4 floor. The gate found the
truncation on its own, without being told about it.

The shortfall reconciles exactly:

| | |
|---|---:|
| Initiatives 13–15, not extracted at the time | $10,105,200.00 |
| Personnel + fringe + travel + supplies (state admin) | $1,079,227.17 |
| Indirect (9.1%) | $13,128,269.21 |
| **Unreconciled remainder** | **$24,312,696.38** |

Add initiatives 13–15 and Delaware lands at **91.0%** — `RECONCILED`,
`ALLOCATED_ONLY` in substance, publishable. That was asserted in the tests
before the lines were read, so the gate confirmed them rather than taking them
on trust.

### Session 8 — the prediction held to the dollar

`dhss.delaware.gov` was allowlisted, the narrative fetched (74 pages, SHA-256 in
`data/evidence/budget_narratives/DE/…manifest.txt`), and initiatives 13–15 read
off pages 68–74:

| # | Initiative | Year 1 | Recipient | `flow_type` | `has_hospital_recipient` |
|---|---|---:|---|---|---|
| 13 | Rural Health Workforce Education Program | $1,000,000 | 2 contractors, both TBD | `NON_HOSPITAL` | `No` |
| 14 | Healthcare Workforce Data Center Initiative | $2,685,200 | Division of Professional Regulation (DPR) | `NON_HOSPITAL` | `No` |
| 15 | Statewide Health IT Infrastructure for Prior Authorizations | $6,420,000 | Health IT vendor, TBD | `IN_KIND_BENEFIT` | `No` |
| | **Total** | **$10,105,200** | | | |

**$10,105,200 — the workbook's predicted shortfall, to the dollar.** And the
new captured total, $143,187,467.48, is the narrative's own **Contractual** line
exactly. Two independent closures on a figure derived before the document could
be opened.

Initiative 15 is coded `IN_KIND_BENEFIT` rather than `NON_HOSPITAL`: the vendor
receives the money, but the narrative names *health systems, FQHCs, and rural
providers* as the parties integrated and onboarded, "with priority given to
rural healthcare organizations." That is §10.2's in-kind test met on its own
terms, and the code exists precisely so those dollars stay visible to AHA's
narrative instead of vanishing into a generic non-hospital bucket. It does not
change any total: `has_hospital_recipient` is `No` either way.

**One row of the workbook's own convention had to be honoured.** Written plainly
as `Statewide Health IT Infrastructure Vendor TBD`, the recipient string derives
as `NAMED + TBD` — the derivation reads the role label as an organisation, which
is the §6.1 `PROGRAM_NAME_AS_AWARDEE` error. The workbook already quotes such
labels for exactly this reason (`'Lead Partner Institution'`,
`'3 Rural Provider/FQHC Readiness Awards'`), so the row is written
`'Statewide Health IT Infrastructure Vendor' - Contractor TBD` and derives
`TBD`, matching the hand coding. Fidelity stays **17 of 17** Delaware rows.

Delaware now names a recipient for **5 of 15** initiatives, not 4 — DPR is
named as a subrecipient for Initiative 14.

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

| | Oklahoma | Delaware (session 7) | Delaware (now) |
|---|---:|---:|---:|
| Hospital-directed | **48.7%** | **15.7%** | **14.6%** |
| Unclear | 17.1% | 24.5% | 22.8% |

Oklahoma matches §0.1b to a decimal place, and Delaware matched it on the
session-7 extraction — the check that the parse read the same rows a person did.

**Delaware's share then moved, and the movement is not a re-coding.** Initiatives
13–15 add $10,105,200 to the denominator and nothing to the hospital-directed
numerator, which stays $20,910,000 — Initiative 12, Training Programs for
Clinical Support Roles, still the only hospital-directed line in the state. So
15.7% → **14.6%** is arithmetic on a more complete document, and it is the
figure to quote: it is the one computed over all 15 initiatives. §0.1b's
finding is untouched — the OK/DE spread is still threefold (48.7% vs 14.6%) and
still must not be averaged.

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

Fidelity, measured against the only hand coding available: **17 of 17 Delaware
rows**, and NAMED on all 28 Oklahoma fund uses, matching §7A.5's "Oklahoma names
a Lead Agency for all 28."

Holding that 17 of 17 took following the workbook's quoting convention on
Initiative 15 — see the session 8 note above. The derivation is only as safe as
the strings it is given.

---

## Gaps this stage leaves open

- **`page_reference` is empty on every row.** §7A.3 wants it so a reviewer can
  open the archived PDF at the right page to check a figure. Neither reference
  workbook records one. The column exists and is visibly blank rather than
  silently absent.
- **`source_archive_path` resolves for Delaware and not for Oklahoma.** The
  parser derives the path from state and source document; as of session 8
  Delaware's actually points at an archived file, with a SHA-256 manifest beside
  it. Oklahoma's narrative has still not been fetched.
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

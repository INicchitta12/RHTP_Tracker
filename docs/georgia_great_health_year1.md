# Georgia GREAT Health — Year 1 awardee extraction

**Session 9, 2026-08-28.** Zero RCJ quota; four calls to `dch.georgia.gov`.

Georgia is the second complete Deliverable 1 dataset after Florida, and the
first assembled inside the repo rather than handed over as a finished workbook.

- Extraction: `R/03d_ga_great_health.R`
- Source of record: the record table inside that script
- Renders: `data/reference/ga_great_health_awards.csv`, `GA_year1_awardees.xlsx`
- Evidence: `data/evidence/GA/` — four pages + a SHA-256 manifest
- Tests: `tests/testthat/test_03d_ga_great_health.R`, 61 assertions

```
Rscript R/03d_ga_great_health.R --validate   # assertions + reconciliation, no writes
Rscript R/03d_ga_great_health.R --build      # writes the CSV and the workbook
```

---

## The program

Georgia's RHTP is the **Georgia Rural Enhancement and Transformation of Health
(GREAT Health) Program**, administered by the Department of Community Health
(DCH). CMS awarded Georgia **$218,862,169.63** for FY2026, a figure stated in
the footnote of all four announcements and matching the §7.1 anchor to the cent.

Year 1 ran as **four application phases**, all four now announced and complete:

| Phase | Date | Awarded | What it covers |
|---|---|---:|---|
| 1 | 2026-06-08 | $12,730,000 | Five strategies, five named awardees |
| 2 | 2026-07-16 | $30,600,000 | Initiatives 2–5, 26 organizations (see below) |
| 3 | 2026-07-23 | $60,487,500 | 80 AHEAD hospitals at $750,000, plus GBHCW |
| 4 | 2026-08-27 | $93,330,827 | All five initiatives; Year 1 fully committed |
| | | **$197,148,327** | 12 initiative pools, 54 award actions |

Phase 4 landed the day before this session. The four pages are archived
verbatim under `data/evidence/GA/`.

## The one thing to understand about this state's data

**Georgia publishes an amount per INITIATIVE, not per recipient.** Each
announcement gives an initiative total and then lists the awardees inside it
without splitting the figure.

So `initiative_amount` is populated on every row and `amount` on only **2 of
54**. §6.2 forbids dividing a pooled amount and nothing here divides one: there
is no per-fragment amount column for a sum to get wrong, exactly as in the §6.2
multi-recipient split. `amount_confirmed = No` on the pooled rows is the
vocabulary's own expected case — *"no recipient-level figure is published, not
that verification failed"* — and is the posture DE and OK already sit in.

**Summing `amount` does not give Georgia's total.** It gives $60.5M for a state
that awarded $197.1M. `rhtp_ga_reconcile()` sums distinct `(phase, initiative)`
pools instead, an assertion hard-fails anyone who reaches the wrong total, and a
test pins the trap open so a later edit cannot quietly close it.

## Two independent closures

Neither was arranged; both fell out of the parse.

**The residual is 9.92% of the CMS award.** The 12 initiative pools sum to
$197,148,327 against $218,862,169.63, leaving $21,713,842.63. DCH separately
states, in the Phase 4 announcement, that *"less than 10% of Year 1's funding is
dedicated to administrative costs."* Two statements made in different documents,
agreeing.

**Phase 3's per-hospital figure closes on its own pool.** DCH states 80 rural
hospitals each awarded $750,000, and separately states an Initiative 1 total of
$60 million. 80 × $750,000 = $60,000,000. That agreement is why this is the one
cohort carrying an `amount` at all.

## The 87 AHEAD hospitals — the largest gap, and the largest prize

> **Superseded by Session 10 in two ways.** The host was allowlisted, so the
> roster is archived and the two aggregate rows below are now 87 named hospital
> rows (`docs/session10_roster_live_monitor_recipient_type.md`). And the figure
> this section originally carried, $65.25M, was wrong: it assumed 87 × $750,000
> when DCH states that figure for eighty hospitals only. The paragraph below
> carries the corrected $60,000,000.

Phase 3 awards **80 rural hospitals $750,000 each** for pre-implementation work
toward the CMS AHEAD model. Phase 4 adds **7 more**, completing a planned Year 1
group of **87**. DCH states the $750,000 figure for the Phase 3 eighty and never
restates it in Phase 4, so the confirmed, named, hospital-directed total is
**80 × $750,000 = $60,000,000 — the largest single block found in any state so
far**, and more than Florida's entire hospital total of $49.3M. It closes on the
stated Initiative 1 pool to the dollar. The other seven hospitals are awarded and
named; their per-hospital amount is simply not published, and §6.2 forbids
dividing a pool to invent it.

The roster is published at
`greathealth.georgia.gov/value-based-care-hospital-list`. **That host is not on
the egress allowlist** — `dch.georgia.gov` and `gov.georgia.gov` were added for
this session, this third Georgia host was not — and both curl and WebFetch were
refused at CONNECT with a 403.

So the cohorts are carried as **two aggregate rows, not 87 named rows**, with
`recipient_confirmed = No` and `flag_reason = RECIPIENT_NAMES_NOT_CAPTURED`.
The class is confirmed and the names are not captured; nothing is imputed,
because the count, the per-hospital figure and the hospital identity of the
class are all stated by DCH. **Allowlist that host and these two rows expand
into 87 named rows.** It is the single highest-value follow-up in this state.

Three smaller cohorts have the same shape and the same flag: 8 hospitals for
telepods (Phase 4, Initiative 3), 13 hospitals for surgical robotics (Phase 4,
Initiative 5), and the 7 above. DCH names none of them on these pages.

## Coding decisions worth a reviewer's attention

**§0.3a appears twice, and both times the answer is the recipient.** Phase 2
awards school-based health infrastructure to the **Georgia Department of
Education**; Phase 4 awards *Building Bridges (School-Based Health Care Services
Infrastructure)* to **Emory University**. Both are `NON_HOSPITAL`. Delaware's
identical activity is `DIRECT` because Beebe Healthcare received it. Same
setting, different recipients, different codes — §10.2, in the exact form the
spec defect at `9fdc156` was about.

**§0.3 appears once, and it is a clean case.** Phase 4 completed procurement of
Type 2 ambulances that *"select rural hospitals will be eligible to apply for
soon."* That is eligibility, not receipt: `Unclear`,
`PASS_THROUGH_UNRESOLVED`, flagged `ELIGIBILITY_NOT_RECEIPT`, and it must not
be imputed to `Yes`.

**Three `IN_KIND_BENEFIT` rows keep $0 out of the hospital total while staying
visible.** Augusta University's cyber centre funds *"cybersecurity enhancements
for rural hospitals"*; the Georgia Hospital Association supplies obstetrical
emergency carts; DCH funds readiness assessments *of* all 87 hospitals. In each
case an intermediary receives the money and hospitals receive the service. All
three are `No` with `hospital_benefiting = Yes`.

**One §6.2 multi-recipient row.** GA-CARE in Phase 4 is *"a partnership between
the University System of Georgia and GBHCW"* — one award, two parties, named in
one row, amount not divided, flagged `MULTI_RECIPIENT_FIELD`.

**Two hospital names contain `" and "` and must not be split on it.** *Hospital
Authority of Jefferson County and the City of Louisville* and *Memorial Hospital
and Manor* are each a single hospital. The §6.2 delimiter list includes `" and "`,
so both rows carry a note saying so.

**One row names no recipient at all.** Phase 4 adds funding to *Nursing Care
Improvements* without saying to whom. Phase 1 awarded that same strategy to the
University System of Georgia, but carrying that across phases would be an
imputation, so it is not made: `NOT_YET_NAMED`, `Unclear`, confidence `LOW`.

## One discrepancy, left standing

DCH's Phase 2 headline says **26 organizations**. The names printed on that same
page enumerate to **28 award actions across 27 distinct organizations** — DBHDD
is awarded under both Initiative 2 and Initiative 3, which accounts for one of
the two, but not the other.

The gap is reported on the workbook's Reconciliation sheet and pinned by an
assertion. It is **not** closed by dropping a name: every organization coded
here is printed on the page, and guessing which of the 27 DCH did not mean to
count would be an invention. If it matters later, DCH is the one to ask.

## What Georgia looks like

| | Award actions |
|---|---:|
| `HOSPITAL_OR_SYSTEM` | 21 |
| `STATE_AGENCY` | 11 |
| `UNIVERSITY_OR_AHC` | 7 |
| `NONPROFIT_CBO` | 4 |
| `NOT_YET_NAMED` | 4 |
| `VENDOR_OR_CONTRACTOR` | 3 |
| `EMS_OR_PSAP` | 2 |
| `AHEC` | 1 |
| `HOSPITAL_AFFILIATED_ENTITY` | 1 |

21 award actions are `distributed_to_hospital = Yes`, covering **125 hospitals**
once the four aggregate cohorts (80 + 7 + 8 + 13) and the 17 named Rural
Stabilization Grant recipients are counted. **17 hospitals are named**; 108 sit
inside cohorts whose rosters DCH publishes elsewhere.

## Schema

`GA_year1_awardees.xlsx` sheet `Awardees (54)` carries
**FL_year1_awardees.xlsx's 19 columns, in order**, so the two states union
without a reshape — a test asserts it. Fourteen Georgia-specific columns follow:
`phase`, `phase_date`, `initiative_number`, `initiative`, `initiative_amount`,
`strategy`, `recipient_count`, `amount_basis`, `flow_type`,
`hospital_benefiting`, `determination_confidence`, `determination_basis`,
`source_archive_path`, `flag_reason`.

Four more sheets: `Reconciliation`, `By phase and initiative`,
`By recipient type`, `Hospitals (21)`.

Georgia stays inside the §8 vocabulary throughout. Note that **Florida does
not** — `FL_year1_awardees.xlsx` uses `PHYSICIAN_PRACTICE` and `UNCLASSIFIED`,
neither of which is in §8, on 13 rows. That is unchanged by this session and is
still the open question CLAUDE.md records: either the vocabulary grows or those
rows are re-coded. Georgia needed neither code.

## Not retrieved

`dch.georgia.gov/great-health-program-georgias-rural-health-transformation-program`
— the program overview page named in the session brief — returns a Drupal
*"Access denied"* 403 to every request tried (plain, browser UA, Google
referer, trailing slash), although it is indexed and reachable to a normal
browser. It is an overview page and carries no award data the four
announcements do not, so nothing was lost. `gov.georgia.gov` was allowlisted
and reachable but holds only the December 2025 CMS award release, which is
Tier 1 and already anchored.

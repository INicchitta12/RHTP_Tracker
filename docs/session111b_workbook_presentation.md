# Session 111b: Year 1 workbook presentation fixes (2026-10-29)

Presentation only. No award file, summary call or figure moved.
`data/reference/year1_summary_2026-10-29.csv` is byte-identical to session 111's
build; only `output/year1_summary_2026-10-29.xlsx` and `R/08_year1_summary.R` changed.

## What changed in the workbook

Sheets, in order: **Overview**, **Detail** (was Summary), Definitions, Notes and caveats, Sources.

**Overview** has ten columns: State, Year 1 status, FY2026 allotment, Awards published,
% of allotment awarded, Hospital $ (best estimate), Hospital % of awards, Hospital % of
allotment, Strict named-hospital $, Hospitals named, no amount. Each one is a relabelled
Detail column (Definitions names the source column). Rows are sorted by state name, and
the national row is last and bold.

**n/m rule.** `Hospital % of awards` is printed only where a state's **state-sourced** awards
published are at least 50% of its allotment (`YS_AWARD_SHARE_MIN`). Otherwise it reads "n/m", on
Overview and on Detail. The owner set the state-sourced test in this session, the same rule as the
second national row: rows from CMS's Obligated Funds Report do not count toward it. The CSV keeps
the computed share on every row.

On the 10-29 data, 29 states read n/m, and so does the national row. Rhode Island is the only state
row the state-sourced test moved: it is 0.0% on state sources and 50.4% with its CMS lines, so its
20.1% now reads n/m. A cell-by-cell diff of the workbook shows no other figure changed. The national
row is n/m by owner decision, because national awards are 41.7% of the allotment; the national
48.1% stays in the CSV. `Hospital % of allotment` prints for every state.

**Second national row (owner decisions, same session).** The national row keeps n/m. Below it,
`US_GE50` ("States with ≥50% published, state award sources (n = 21)") is added to the CSV, Detail
and Overview. **It rests on state award sources only, and the owner set that rule in its final form
here.** The award files built from CMS's Obligated Funds Report (`NE_CMS`, `PA_CMS`, `RI`) are dropped,
and the state table is then rebuilt without them (`ys_state_source_table()`). Each state's "% published"
is therefore its state-sourced award total over its allotment, and a state qualifies at ≥50%. The row
sums every column over the members' state-sourced figures and recomputes the three shares from those
sums (`ys_subset_row()`). On Overview it shows only the six figures the owner named; % of allotment
awarded and Hospitals named, no amount are blank.

| | 21 states |
|---|---:|
| FY2026 allotment | $4,284,392,337 |
| Awards published | $3,362,841,950.78 |
| Hospital $ (best estimate) | $1,557,146,269.69 |
| Hospital % of awards | 46.3% |
| Hospital % of allotment | 36.3% |
| Strict named-hospital $ | $1,451,104,633.38 |

Members: AK AL AR CA CO FL GA ID IN MD MI MS NJ NV OH OR SC SD TX VT WY.

- **The states carrying CMS obligation lines today, by state-sourced share:**
  - Rhode Island: 0.0% state-sourced, 50.4% with its CMS lines. It does not qualify.
  - Nebraska: 19.1% state-sourced, 20.9% with its CMS lines.
  - Pennsylvania: 21.8% state-sourced, 23.4% with its CMS lines.
- **Effect of the earlier rule.** An intermediate rule excluded a state outright if it had any CMS
  line. Removing RI's rows under that rule moved the subset by −$156,169,931 allotment,
  −$78,727,110.44 awards and −$15,839,907.67 hospital (HARI, an unnamed pool).
- **The 21 members are unchanged under the final rule.** None of them has a CMS row, so the
  committed CSV is byte-identical to the build under the earlier rule.
- **A state with CMS lines can now qualify on its state files alone.** Nebraska and Pennsylvania
  would, once they cross 50% on state-sourced awards, and their CMS lines would stay out of the row.
- **Two guards stay in the builder.** It refuses an award file that mixes CMS lines with
  state-sourced rows, because the subset drops whole files. It also refuses if any CMS-obligation
  dollar reaches the row. `test_08` drives both guards.
- **The row is a subset of the national row and is never added to it.** The first 51 CSV rows are
  identical to the build before it.
- **Two members sit close to the line:** Indiana (54.7%) and Ohio (51.5%). The set will move as
  states publish, and Monday's re-run re-pins it.

**Status labels** (`YS_STATUS_LABELS`, assigned in this order by `ys_status_label()`):

| Label | Rule | States (10-29) |
|---|---|---|
| Complete | `completion_status == COMPLETE` | AL AR FL GA |
| CMS obligation report only | every award row is `CMS_OBLIGATION_REPORT` | RI |
| Partial: awarding continues | award rows, at least one priced | 33 |
| Awards published, not priced | award rows, none priced | HI IA KY NC TN |
| No awards published yet | no award rows | AZ MA MN ND NM UT WI |

The "No awards published yet" definition says this reflects what the project has found, not
that the state awarded nothing. Massachusetts is unreadable (§0.4), and North Dakota has
announced awards without naming anyone. North Carolina carries pool-level dollars ($11.25M)
but no per-recipient amount, so it is labelled "not priced".

**Formats.** Currency is `$#,##0`. Percentages are stored as fractions and formatted `0.0%`.
The header row and first column are frozen on Overview and Detail. Each column is as wide as
its longest header or formatted value, capped at 60 with wrap, which only the confidential-flag
column hits. Delaware's row is shaded on both sheets.

**Notes.** The sheet opens with a one-line "How to read this". It adds the n/m note and a note
that award coverage (0% to 97.6% of allotment) makes state shares non-comparable.

## Tests

`test_08` checks every Overview figure against `ys_build()`, the fractions against the CSV's
one-decimal percentages, the n/m cells on both sheets, the status label sets, the number
formats, the frozen panes, the column widths, the bold national row and the Notes text.

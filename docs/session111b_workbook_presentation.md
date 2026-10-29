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

**n/m rule.** `Hospital % of awards` is printed only where awards published are at least 50%
of the allotment (`YS_AWARD_SHARE_MIN`). Otherwise it reads "n/m", in Overview and in
Detail. On the 10-29 data that is 28 states **and the national row**, because national awards
are 41.7% of the allotment. The national 48.1% stays in the CSV. Owner call: exempt the
national row if the national share should print. `Hospital % of allotment` prints for every state.

**Second national row (owner decisions, same session).** The national row keeps n/m. Below it,
`US_GE50` ("States with ≥50% published, state award sources (n = 21)") is added to the CSV, Detail
and Overview. A state is a member when its awards published are at least 50% of its allotment
**and** none of its award rows comes from CMS's Obligated Funds Report. The owner ruled that the
subset rests on state award sources only. The row sums every column over the members and
recomputes the three shares from those sums (`ys_subset_row()`). On Overview it shows only the
six figures the owner named; % of allotment awarded and Hospitals named, no amount are blank.

| | 21 states |
|---|---:|
| FY2026 allotment | $4,284,392,337 |
| Awards published | $3,362,841,950.78 |
| Hospital $ (best estimate) | $1,557,146,269.69 |
| Hospital % of awards | 46.3% |
| Hospital % of allotment | 36.3% |
| Strict named-hospital $ | $1,451,104,633.38 |

Members: AK AL AR CA CO FL GA ID IN MD MI MS NJ NV OH OR SC SD TX VT WY.

- **Rhode Island is excluded.** It is at 50.4%, and every one of its award rows is a CMS
  obligation line. Taking it out moves the row by −$156,169,931 allotment, −$78,727,110.44 awards
  and −$15,839,907.67 hospital (HARI, an unnamed pool). The strict named-hospital figure does not
  move, because RI has no named-hospital dollars.
- **Nebraska and Pennsylvania also carry CMS obligation lines.** Both are below the line today. If
  either crosses it, the whole state is left out, so no CMS-obligation dollar can enter the row. The
  builder also refuses outright if one does.
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

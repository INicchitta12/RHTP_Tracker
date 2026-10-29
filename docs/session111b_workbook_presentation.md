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

> **SUPERSEDED IN PART — Session 14 (2026-08-28).** This document describes
> stage 00 when `medicaid.gov` was its *only* source. It no longer is.
>
> **`www.cms.gov/newsroom`, filtered to the rural health topic, is now the
> PRIMARY source and `medicaid.gov` the SECONDARY**, with the two unioned and
> `source` recorded per row. The reason is in this file's own logic: the
> medicaid.gov page **lags**. CMS announced $122M for Virginia on 2026-08-28
> and that page did not list it, so a monitor reading it alone reported eight
> announced states when there were nine — confidently, because a lagging
> source does not look like a gap.
>
> What below is still accurate: the §0.1 discovery posture, the §0.2 rule that
> `amount` is never summed, the `State = "All"` Tier 1 exclusion, the
> `<td>`-header promotion, and every refusal in the medicaid.gov parser — all
> of that is unchanged and still runs, as the secondary.
>
> What below is stale: the egress section (`medicaid.gov` was allowlisted on
> 2026-08-28 and both sources are reachable), the claim that the page is the
> trigger list, and the `shape : TABLE` check as a sufficient health signal —
> there are now two sources with two shapes.
>
> Read `session14_cms_newsroom_trigger_virginia.md` for the current design.

---

# Stage 00 — the CMS state-announcement trigger list

**Session 9, 2026-08-28.** Zero RCJ quota. **Never run against the live page —
see Egress.**

- Code: `R/00_cms_press_monitor.R`
- Output: `data/reference/cms_state_announcements.csv` — `state`, `date`,
  `amount`, `title`, `url`, `source_url`, `first_seen`
- Run log: `logs/cms_press_manifest.csv` (append-only, `run_type` per §5.2)
- Archive: `data/raw/cms/<fetch_date>/medicaid_rhtp_resources.html` + manifest
- Tests: `tests/testthat/test_00_cms_press_monitor.R`, 46 assertions, five
  fixtures under `tests/fixtures/cms_press/`

```
Rscript R/00_cms_press_monitor.R --run            # fetch, archive, parse, write
Rscript R/00_cms_press_monitor.R --run --force    # re-fetch over today's archive
Rscript R/00_cms_press_monitor.R --run --dev      # log the run as DEV (§5.2)
Rscript R/00_cms_press_monitor.R --parse          # newest archive, no network
Rscript R/00_cms_press_monitor.R --status         # what the current CSV says
```

---

## Why it is stage 00

CMS maintains one page listing the states that have announced RHTP awards. **A
state appearing on it is the cue to go and collect that state's primary
sources.** That makes it the cheapest signal in the project: it runs *before*
retrieval and decides what is worth retrieving, and it costs **zero RCJ quota**
because it never touches the RCJ API.

Nothing downstream depends on it. A failure here delays a collection pass; it
never corrupts a figure.

## What it is not

**This is a discovery layer, exactly as RCJ is (§0.1), and the same rule
applies: no figure from this page may appear in an AHA-published number.** CMS's
summary of a state announcement is not the state's notice of award.

`amount` is captured so a collection pass can be prioritised, and so a state
figure that later disagrees is caught early. It is **never** totalled, and an
assertion enforces that:

> This page mixes CMS-to-state allotment announcements (Tier 1) with state
> subaward announcements (Tier 3), so any total over `amount` blends the tiers
> §0.2 separates. Georgia alone would appear at $218.8M as an allotment and
> again at $60.5M as subawards.

`rhtp_cms_press_assert()` hard-fails on a total exceeding the whole $10B
programme, which is the cheapest available proxy for "somebody summed the
column." The check exists mainly so the comment beside it is unmissable to
whoever adds a summary line to this stage next.

## Egress — this has never run

**`medicaid.gov` is not on the environment allowlist.** Both routes were tried
on 2026-08-28 and both were refused at CONNECT with a 403:

```
curl  https://www.medicaid.gov/...  ->  CONNECT tunnel failed, response 403
curl  https://medicaid.gov/...      ->  CONNECT tunnel failed, response 403
WebFetch                            ->  EGRESS_BLOCKED
```

`dch.georgia.gov` and `gov.georgia.gov` were allowlisted for this session;
`medicaid.gov` was not, and neither was `greathealth.georgia.gov`.

**To enable:** Claude Code on the web → environment settings → network access →
add `www.medicaid.gov`. Then `--run` works unchanged; no code change is needed.

Until then the fetch stops with exactly that instruction and **writes
nothing**. That refusal is deliberate: an empty CSV here would read as *"no
state has announced an award,"* which is the opposite of the truth and is the
§5.2 silent short-read failure mode in a different costume.

## The parser refuses rather than guesses

Because the page's markup has never been read by this code, the parser cannot
assume a shape. It takes the approach `R/03b_budget_narratives.R` takes to fifty
differently-formatted state workbooks: **resolve columns by synonym, score
candidates, and refuse on ambiguity.**

Two shapes are handled:

- **`TABLE`** — an HTML table. Every `<table>` on the page is scored by how many
  of `state` / `date` / `amount` / `title` resolve against the synonym lists,
  with `state` mandatory. Highest score wins. A site-navigation table scores
  −1 and is skipped, which is the case a position-based parser gets wrong.
- **`LINK_LIST`** — headed lists of links, where each link text names a state.
  Date and amount are pulled out of the link text; a link naming no state is
  ignored.

Four refusals, all tested:

| Condition | Why refusing is right |
|---|---|
| Two tables score equally | Position is exactly what a redesign changes |
| No column resolves, and no state-named link | The page changed shape, or the fetch returned a shell |
| A state outside the §7.1 fifty | A dropped row is a state nobody collects — silent and unrecoverable |
| Zero rows parsed | CMS lists states that *have* announced; empty means the parse failed |

Synonyms are matched against a normalized header, so a CMS rewording
(`Award Amount` → `Amount Awarded`) needs no code change. A shape change does —
and should.

Amounts parse from `$1,234,567`, `$100 million` and `$1.2 billion`. Anything
unrecognised is `NA`, **never 0**: a zero would be a claim, and the Nebraska
`budgetMax: 100000` row against a $218.5M allotment (§0.2a) is what that error
looks like when it reaches a table.

Dates parse from eight formats. States resolve from either the two-letter code
or the full name, against `data/reference/cms_states.csv`.

## The diff is the product

The point of the twice-weekly cadence is `rhtp_cms_press_delta()`, not the file.
Each run reports:

- **`NEW STATES TO COLLECT`** — states on the page that were not there before
- **changed announcements** — a row whose amount or date moved, which is the cue
  to re-check that state's primary source

`first_seen` is preserved across runs: it records the date *this project*
learned of an announcement, not the date of the newest parse.

A run with no change says so in one line. That is the expected outcome most of
the time.

## Cadence

Wired to the project's adopted twice-weekly cadence (`config pull$cadence`) as a
Routine, `trig_01EozMStALcrUp75s32qFnJ3`, firing **Mondays and Thursdays at
13:00 UTC** into a fresh session. First run 2026-08-31.

The Routine checks reachability first and, while `medicaid.gov` is still
blocked, reports that in one line and stops without writing anything — so a
blocked host costs one quiet line twice a week rather than a failing job. It
also carries the standing instruction that a parser refusal is the parser
working, to be fixed deliberately with a new fixture, and **never loosened just
to get a run to pass**.

Manage it with `list_triggers` / `update_trigger` / `delete_trigger`, or from
the claude.ai Routines UI.

## Tests

46 assertions against five fixtures. They are written for the failure that
actually matters: not that the parser reads one known table, but that it
**refuses every shape it does not understand**. Since the parser has never seen
the real page, these tests are the whole of its assurance.

The convention tests strip comments before grepping the source — this file's own
header documents the `%>%`-only and no-`setwd()` rules, and a naive grep fails on
the prose describing the rule it checks.

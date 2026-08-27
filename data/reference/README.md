# `data/reference/` — controlled vocabularies and pattern tables

Most files here are human-maintained reference data, read by the pipeline and
never written by it. Three are pipeline-generated and then verified by a person:
`cms_fy2026_allotments.csv` (Stage 3, parsed from CMS and asserted on load),
`state_source_registry_worksheet.csv` and `state_source_registry_candidates.csv`
(Stage 3 and Stage 2, seeded from `/activity.siteUrl`). A human works the
worksheet into `state_source_registry.csv`.

| File | Purpose | Spec |
|---|---|---|
| `vocabularies.csv` | The controlled vocabulary for every categorical column. No free-text categories anywhere. | §8 |
| `cms_states.csv` | **The state vocabulary.** 50 rows, independent of RCJ. | §7.1 |
| `title_junk_patterns.csv` | Page-chrome-as-title patterns. | §6.2 |
| `non_rhtp_patterns.csv` | Non-RHTP federal-program markers and self-declared-non-RHTP negations. | §6.2 |
| `program_name_patterns.csv` | The §6.1 named-recipient test: `awardeeName` values that are programs, pools, or the administering agency rather than a recipient. | §6.1 |
| `cms_fy2026_allotments.csv` | **The reconciliation anchor.** 50 rows, parsed from the CMS press release by `R/03_state_registry.R`, asserted on every load. | §7.1, §13.17 |
| `state_source_registry.csv` | Stage 3 deliverable. **Not yet compiled** — see below. | §7.3 |
| `state_source_registry_worksheet.csv` | The §7.2 candidates laid out for offline verification: context columns filled, verification columns empty. Work this file down to the registry. | §7.2 |
| `state_source_registry_candidates.csv` | Machine-generated Stage 3 seed from `/activity.siteUrl`. Superseded for day-to-day use by the worksheet above. | §7.2 |
| `legal_entity_patterns.csv` | The §6.1 rule 1 entity override and its suppressors. Also the arbiter for §6.4 mining. | §6.1, §6.4 |
| `state_agency_patterns.csv` | Administering-agency names that fail the named-recipient test. | §6.1 |

## Why the state vocabulary is not RCJ's

`/states` returns 49 states plus a pseudo-state `US`, and **omits Wyoming**,
which has records on three other endpoints. `RC` additionally appears as a
state code on 54 `/documents` records and is not a state at all. Neither may
define the state vocabulary. `cms_states.csv` is the canonical 50-row list and
every state-keyed join, QA reconciliation, and coverage report keys off it
(§7.1, §13.14).

## Where the allotment anchor comes from

`cms_fy2026_allotments.csv` is parsed from the CMS December 2025 press release
by `Rscript R/03_state_registry.R --allotments`, **never transcribed by hand**
(§7.1). It is the reconciliation anchor for §13.3, §13.4 and §13.17, so a typo
in it corrupts every figure downstream. The source `<table>` is archived
verbatim under `data/raw/cms/<fetch_date>/` and committed, so the parse is
reproducible offline even if CMS edits the page. Only the table is archived —
the surrounding page carries a third-party API token that is CMS's to publish,
not ours to redistribute — and the archive header carries the full page's
SHA-256 so provenance still closes.

It is the **only** home for these 50 figures. `fy2026_allotment` is deliberately
not a `state_source_registry.csv` column: two files carrying the same numbers is
two files that can disagree, and one of them is the anchor. Downstream code
joins.

With it on disk, §6.1 tier rule 3 (amount matches the state's CMS allotment →
`STATE_ALLOTMENT`) and the §6.2 "amount exceeds the state's allotment" check are
both live. Without it, `rhtp_load_allotments()` returns an empty table and the
run reports the gap as a coverage gap — never as a pass.

## What is still missing

`state_source_registry.csv` does not exist yet. It is compiled **off-session**
by working `state_source_registry_worksheet.csv` (151 candidate hosts, all 50
states) down to 50 verified rows: load each URL, fill `award_posting_url` and
`pass_through_admin`, set `last_verified`. Check the result with
`Rscript R/03_state_registry.R --validate`.

Until it exists, §13.12 is unmet: a state with no verified `award_posting_url`
cannot be validated in Stage 4 at all, and that is reported as a deliverable
gap, never a silent skip.

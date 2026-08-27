# `data/reference/` — controlled vocabularies and pattern tables

Every file here is human-maintained reference data, read by the pipeline and
never written by it (the one exception is
`state_source_registry_candidates.csv`, which Stage 2 regenerates and a human
then promotes into `state_source_registry.csv`).

| File | Purpose | Spec |
|---|---|---|
| `vocabularies.csv` | The controlled vocabulary for every categorical column. No free-text categories anywhere. | §8 |
| `cms_states.csv` | **The state vocabulary.** 50 rows, independent of RCJ. | §7.1 |
| `title_junk_patterns.csv` | Page-chrome-as-title patterns. | §6.2 |
| `non_rhtp_patterns.csv` | Non-RHTP federal-program markers and self-declared-non-RHTP negations. | §6.2 |
| `program_name_patterns.csv` | The §6.1 named-recipient test: `awardeeName` values that are programs, pools, or the administering agency rather than a recipient. | §6.1 |
| `state_source_registry.csv` | Stage 3 deliverable. **Not yet compiled** — see below. | §7.3 |
| `state_source_registry_candidates.csv` | Machine-generated Stage 3 seed seeded from `/activity.siteUrl`. Candidates only; every row still needs a human `last_verified`. | §7.2 |

## Why the state vocabulary is not RCJ's

`/states` returns 49 states plus a pseudo-state `US`, and **omits Wyoming**,
which has records on three other endpoints. `RC` additionally appears as a
state code on 54 `/documents` records and is not a state at all. Neither may
define the state vocabulary. `cms_states.csv` is the canonical 50-row list and
every state-keyed join, QA reconciliation, and coverage report keys off it
(§7.1, §13.14).

## What is still missing

`state_source_registry.csv` does not exist yet, and with it two things Stage 2
cannot do:

- **`fy2026_allotment` is unavailable**, so §6.1 tier rule 3 (amount matches
  the state's CMS allotment → `STATE_ALLOTMENT`) is **inactive** in the current
  run, and the §6.2 "amount exceeds the state's allotment" sanity check cannot
  fire. Both are implemented and unit-tested against a fixture; both switch on
  by themselves the moment the registry lands. `rhtp_load_allotments()` reports
  which state it is in.

The allotment figures must come from the CMS December 2025 announcement, by
hand, off-session — never from RCJ (§0.1, §7.3).

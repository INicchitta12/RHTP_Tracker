# Stage 0 exploratory captures — NOT a production pull

These files are Session 1's Stage 0 API reconnaissance: a Delaware-only probe
of each endpoint's schema, plus raw response headers and a capture of the
`/api-docs` page. They are **not** a production snapshot and Stage 2 must not
normalize them as if they were.

They were moved into this subdirectory in Session 3, when the first production
national pull landed in the same dated directory. Before the move, both sets
sat side by side in `data/raw/rcj/2026-08-27/`, where a Stage 2 glob over the
directory would have swept the Delaware probes into the record table and
double-counted Delaware.

**The production snapshot for this date is the five files in the parent
directory** — `states.json`, `awards.json`, `documents.json`,
`opportunities.json`, `activity.json` — each written by
`R/01_retrieve_rcj.R` with a `pull_metadata` block.

Nothing here is deleted: they remain the evidence behind
`docs/stage0_preflight_findings.md`, and Delaware's 15 award records are the
Stage 2 test fixtures referenced in the session plan.

Note the `.headers.txt` files record the live quota headers that confirmed the
Pro plan's 2,000/month allowance.

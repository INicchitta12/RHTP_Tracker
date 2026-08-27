# RHTP Hospital Funding Tracker

Tracks Rural Health Transformation Program (RHTP) funding and identifies which
awards reach hospitals, by state, with every figure traceable to a primary state
source.

**Owner:** Isaac, AHA Data & Policy · **Stack:** R (tidyverse, `%>%` only) ·
**Deliverable:** Excel workbook via `openxlsx`

## Start here

- **`CLAUDE.md`** — project context, the five governing principles, controlled
  vocabularies, coding conventions, and current build state. Read first.
- **`docs/stage0_preflight_findings.md`** — the RCJ API as it actually behaves.
  Authoritative over the vendor's own documentation.
- **`rhtp-tracker-build-spec.docx`** — the full build specification.

## Three things that are easy to get wrong

1. **RCJ is a discovery layer, not a source of record.** No RCJ field may appear
   in a published number without independent state-source validation.
2. **Never sum across `award_tier`.** CMS→state (Tier 1), state pools (Tier 2),
   and subawards (Tier 3) are different money. Only Tier 3 answers the question.
3. **Committed or gone.** `data/raw/`, `data/evidence/`,
   `data/interim/review_queue.*`, and `logs/pull_manifest.csv` are **committed,
   not gitignored** — cloud sessions destroy anything uncommitted.

## Status

Session 1 complete: scaffold, config, and Stage 0 preflight. **No pipeline stage
is built yet**, and no R code has been executed — R is not installed in the
current cloud environment (see `docs/stage0_preflight_findings.md` §9).

## Credentials

The RCJ API key is read from the `RCJ_API_KEY` environment variable via
`Sys.getenv()`. It is never written to a file, committed, or echoed. In cloud
sessions it comes from the environment's Environment variables field; locally,
from a gitignored `.Renviron`. No code changes are needed to move between them.

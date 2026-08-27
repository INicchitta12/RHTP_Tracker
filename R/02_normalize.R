# 02_normalize.R -----------------------------------------------------------
# Stage 2 — Normalization — build spec §6
#
# CONTRACT: Raw JSON -> a typed, deduplicated, tier-assigned record table with change detection. Still no interpretation.
#
# STATUS: Not started. Note §6.1 rule 2 needs revision before coding — see findings §6.1. Test fixtures are already on disk at data/raw/rcj/2026-08-27/.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "02_normalize.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

# 03_state_registry.R -----------------------------------------------------------
# Stage 3 — State source registry — build spec §7
#
# CONTRACT: Validate and integrate the hand-built data/reference/state_source_registry.csv (50 rows, hand-verified).
#
# STATUS: Not started. The registry URLs are compiled by hand OUTSIDE the session and committed as a CSV; this script validates structure and integrates it.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "03_state_registry.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

# qa_assertions.R -----------------------------------------------------------
# QA assertions — build spec §13
#
# CONTRACT: Run on every build. FAIL the build, do not warn.
#
# STATUS: Not started. The mixed-tier guard belongs INSIDE the aggregation helpers themselves, not in a separate check.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "qa_assertions.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

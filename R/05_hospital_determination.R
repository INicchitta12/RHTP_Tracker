# 05_hospital_determination.R -----------------------------------------------------------
# Stage 5 — Hospital determination — build spec §10
#
# CONTRACT: Two axes: recipient identification (AHA/POS crosswalk) and flow determination.
#
# STATUS: Not started. Requires AHA Annual Survey and CMS Provider of Services extracts committed to the repo first — cloud sessions cannot reach internal AHA systems. Fuzzy matches NEVER auto-resolve.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "05_hospital_determination.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

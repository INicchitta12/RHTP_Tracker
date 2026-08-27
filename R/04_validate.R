# 04_validate.R -----------------------------------------------------------
# Stage 4 — Validation and evidence capture — build spec §9
#
# CONTRACT: Queue manager and rule engine. Reads reviewer-supplied evidence and applies the §9.2 confirmation rules.
#
# STATUS: Not started. CONTAINS NO HTTP REQUESTS TO STATE DOMAINS (§9.0). Fetching and PDF archiving happen outside the cloud session. Build it as a queue manager from the start rather than writing a fetcher that cannot run.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "04_validate.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

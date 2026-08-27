# 01_retrieve_rcj.R -----------------------------------------------------------
# Stage 1 — Retrieval — build spec §5
#
# CONTRACT: Pull RCJ records to an immutable dated landing zone. Never transform in this stage.
#
# STATUS: BLOCKED: awaiting Isaac's review of docs/stage0_preflight_findings.md. The spec §5 delta-pull design does not survive contact with the API — there is no updated_since filter on /awards, /documents, or /opportunities. Settle §10 recommendations 1 and 2 first.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only — never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# source(here::here("R", "utils_config.R")) for config, paths, credentials,
# and quota handling.

stop(
  "01_retrieve_rcj.R is not implemented yet. See CLAUDE.md \xc2\xa710 (Current state) ",
  "and docs/stage0_preflight_findings.md.",
  call. = FALSE
)

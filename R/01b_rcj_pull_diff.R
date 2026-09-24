#!/usr/bin/env Rscript
# 01b_rcj_pull_diff.R ---------------------------------------------------------
#
# WHAT CHANGED BETWEEN TWO RCJ PULLS, AND WHICH STATES NOTHING IS WATCHING
# (session 60).
#
# Tennessee published a 53-row roster on 2026-09-03 and nothing here saw it for
# twenty days (session 59, §1). Four things lined up: RCJ's only pull predated
# the roster, CMS issued no Tennessee release, no probe watched Tennessee, and
# its programme page never linked the workbook. This file measures the first
# and third of those for every state, so that the gap is a number rather than
# a surprise.
#
# It reads two committed pulls under data/raw/rcj/ and nothing else from the
# network. It is DISCOVERY ONLY (§0.1): a new RCJ award row is a place to look,
# never a figure. No row here enters a state file.
#
# WATCHED means ON A ROUTINE (config/routines.csv). A probe script that no
# Routine runs watches nothing: Delaware, Idaho, Ohio, South Dakota and Texas
# all have one and none is scheduled.
#
# Outputs (both committed, §0.5):
#   data/reference/rcj_pull_diff_by_state.csv   one row per state
#   data/reference/rcj_pull_new_award_rows.csv  every award row whose id is new
#
# Usage: Rscript R/01b_rcj_pull_diff.R --build [--old=YYYY-MM-DD --new=YYYY-MM-DD]
#        Rscript R/01b_rcj_pull_diff.R --report

suppressPackageStartupMessages({ library(dplyr) })
source(here::here("R", "utils_config.R"))

DIFF_OLD_PULL <- "2026-08-27"
DIFF_NEW_PULL <- "2026-09-24"
DIFF_BY_STATE <- "data/reference/rcj_pull_diff_by_state.csv"
DIFF_NEW_ROWS <- "data/reference/rcj_pull_new_award_rows.csv"

# States with a --probe that NO Routine runs. Read off R/ in session 60 (each
# file's CLI offers --probe; none is in config/routines.csv). Hand-kept, and
# the build refuses if one of them turns up in routines.csv, so the list
# cannot silently go stale in the direction that overstates exposure.
# SESSION 61: all five are now on Routines (config/routines.csv), so the list
# is empty. It stays, so a future unscheduled probe has somewhere to go.
DIFF_PROBE_NO_ROUTINE <- character(0)


diff_read <- function(pull_date, endpoint) {
  path <- here::here("data", "raw", "rcj", pull_date, paste0(endpoint, ".json"))
  if (!file.exists(path)) stop("No ", endpoint, ".json in pull ", pull_date,
                               call. = FALSE)
  parsed <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!isTRUE(parsed$pull_metadata$exhaustive)) {
    stop(endpoint, " in pull ", pull_date, " is not exhaustive; a diff ",
         "against a truncated pull reports records as NEW that were merely ",
         "unread last time.", call. = FALSE)
  }
  parsed$pages %>%
    purrr::map(~ purrr::pluck(.x, "body", "data", .default = list())) %>%
    purrr::flatten()
}

diff_chr <- function(x, field) {
  purrr::map_chr(x, ~ {
    v <- purrr::pluck(.x, field, .default = NA_character_)
    if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[[1]])
  })
}

diff_ids <- function(records) diff_chr(records, "id")

diff_new_award_rows <- function(old, new) {
  fresh <- new[!diff_ids(new) %in% diff_ids(old)]
  tibble::tibble(
    state          = diff_chr(fresh, "state"),
    rcj_id         = diff_ids(fresh),
    awardee_rcj    = diff_chr(fresh, "awardeeName"),
    amount_rcj     = suppressWarnings(as.numeric(diff_chr(fresh, "federalAmount"))),
    source_title   = purrr::map_chr(fresh, ~ purrr::pluck(
      .x, "sourceDocument", "title", .default = NA_character_)),
    source_doc_id  = purrr::map_chr(fresh, ~ purrr::pluck(
      .x, "sourceDocument", "id", .default = NA_character_))
  ) %>%
    # The title's own state prefix, which is NOT always the filed state
    # (§0.1 mode 6). Recorded, not acted on: 02c's sweep owns that question.
    mutate(title_state = stringr::str_match(source_title, "^([A-Z]{2}) - ")[, 2],
           title_state_differs = !is.na(title_state) & title_state != state,
           note = "RCJ DISCOVERY ONLY (§0.1): not a finding until a state source says so.") %>%
    arrange(state, source_title, awardee_rcj)
}

diff_by_state <- function(old_pull = DIFF_OLD_PULL, new_pull = DIFF_NEW_PULL) {
  ends <- c("awards", "documents", "opportunities")
  old <- purrr::set_names(purrr::map(ends, ~ diff_read(old_pull, .x)), ends)
  new <- purrr::set_names(purrr::map(ends, ~ diff_read(new_pull, .x)), ends)
  act <- diff_read(new_pull, "activity")

  count_state <- function(records, name) {
    tibble::tibble(state = diff_chr(records, "state")) %>%
      filter(!is.na(state)) %>% count(state, name = name)
  }
  new_only <- function(e) new[[e]][!diff_ids(new[[e]]) %in% diff_ids(old[[e]])]

  act_tbl <- tibble::tibble(state = diff_chr(act, "state"),
                            occurred = diff_chr(act, "occurredAt")) %>%
    filter(!is.na(state), substr(occurred, 1, 10) > old_pull) %>%
    count(state, name = "activity_events_since_old_pull")

  routines <- readr::read_csv(here::here("config", "routines.csv"),
                              show_col_types = FALSE)
  on_routine <- setdiff(routines$state, "CMS")
  clash <- intersect(DIFF_PROBE_NO_ROUTINE, on_routine)
  if (length(clash) > 0) {
    stop("DIFF_PROBE_NO_ROUTINE lists ", paste(clash, collapse = ", "),
         " but config/routines.csv schedules it. Update the constant.",
         call. = FALSE)
  }

  cms <- readr::read_csv(here::here("data", "reference",
                                    "cms_state_announcements.csv"),
                         show_col_types = FALSE) %>%
    group_by(state) %>% summarise(cms_release_latest = max(as.character(date)),
                                  .groups = "drop")
  survey <- readr::read_csv(here::here("data", "reference",
                                       "rcj_state_survey.csv"),
                            show_col_types = FALSE) %>%
    select(state, extraction_status, cms_fy2026_allotment)

  survey %>%
    left_join(count_state(old$awards, "awards_old"), by = "state") %>%
    left_join(count_state(new$awards, "awards_new"), by = "state") %>%
    left_join(count_state(new_only("awards"), "award_rows_new_id"), by = "state") %>%
    left_join(count_state(new_only("documents"), "documents_new_id"), by = "state") %>%
    left_join(count_state(new_only("opportunities"), "opportunities_new_id"),
              by = "state") %>%
    left_join(act_tbl, by = "state") %>%
    left_join(cms, by = "state") %>%
    mutate(across(c(awards_old, awards_new, award_rows_new_id, documents_new_id,
                    opportunities_new_id, activity_events_since_old_pull),
                  ~ dplyr::coalesce(.x, 0L)),
           on_routine = state %in% on_routine,
           probe_without_routine = state %in% DIFF_PROBE_NO_ROUTINE,
           cms_release = !is.na(cms_release_latest),
           # THE EXPOSED SET, BEFORE THIS PULL: no Routine, and the only RCJ
           # read of the state was the old pull. CMS releases are recorded
           # beside it, not subtracted: a release already issued does not
           # watch for the NEXT tranche.
           exposed = !on_routine,
           rcj_signal_in_new_pull = award_rows_new_id + documents_new_id > 0,
           old_pull = old_pull, new_pull = new_pull) %>%
    arrange(desc(exposed), desc(cms_fy2026_allotment))
}

diff_build <- function(old_pull = DIFF_OLD_PULL, new_pull = DIFF_NEW_PULL) {
  by_state <- diff_by_state(old_pull, new_pull)
  rows <- diff_new_award_rows(diff_read(old_pull, "awards"),
                              diff_read(new_pull, "awards"))
  stopifnot(nrow(by_state) == 50L,
            sum(by_state$award_rows_new_id) == sum(!is.na(rows$state)))
  readr::write_csv(by_state, here::here(DIFF_BY_STATE), na = "")
  readr::write_csv(rows, here::here(DIFF_NEW_ROWS), na = "")
  message("Wrote ", DIFF_BY_STATE, " and ", DIFF_NEW_ROWS, " (",
          nrow(rows), " new award rows).")
  invisible(list(by_state = by_state, rows = rows))
}

diff_report <- function() {
  x <- readr::read_csv(here::here(DIFF_BY_STATE), show_col_types = FALSE)
  exp <- x %>% filter(exposed)
  message(nrow(exp), " states on NO Routine (", sum(exp$probe_without_routine),
          " of them have an unscheduled probe); ",
          sum(exp$cms_fy2026_allotment), " of allotment.")
  print(as.data.frame(exp %>% select(state, extraction_status,
                                     probe_without_routine, cms_release,
                                     award_rows_new_id, documents_new_id,
                                     activity_events_since_old_pull)),
        row.names = FALSE)
}

if (!interactive() && identical(sys.nframe(), 0L)) {
  args <- commandArgs(trailingOnly = TRUE)
  opt <- function(k, d) {
    hit <- grep(paste0("^--", k, "="), args, value = TRUE)
    if (length(hit)) sub(paste0("^--", k, "="), "", hit[1]) else d
  }
  if ("--build" %in% args) diff_build(opt("old", DIFF_OLD_PULL),
                                      opt("new", DIFF_NEW_PULL))
  if ("--report" %in% args) diff_report()
}

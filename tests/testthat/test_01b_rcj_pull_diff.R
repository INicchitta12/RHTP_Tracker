# test_01b_rcj_pull_diff.R --------------------------------------------------
# The two-pull diff and the exposed set (session 60). Reads committed files.

library(testthat)
source(here::here("R", "01b_rcj_pull_diff.R"))

by_state <- readr::read_csv(here::here(DIFF_BY_STATE), show_col_types = FALSE)
rows <- readr::read_csv(here::here(DIFF_NEW_ROWS), show_col_types = FALSE)

test_that("fifty states, and new rows reconcile to the per-state counts", {
  expect_equal(nrow(by_state), 50L)
  expect_equal(sum(by_state$award_rows_new_id), nrow(rows))
})

test_that("EXPOSED is exactly the states on no Routine", {
  r <- readr::read_csv(here::here("config", "routines.csv"), show_col_types = FALSE)
  expect_setequal(by_state$state[by_state$exposed], setdiff(by_state$state, r$state))
  # Session 61: 27 -> 21. DE ID OH SD TX and NJ went on Routines; session 64:
  # 21 -> 20, Indiana (R/03bi, trig_01NZAAixvNoKcZMBKAiCUCYD). (The
  # NEWSROOM sweep watches 18 states' newsrooms, but it is a net, not a
  # per-state watch, so it does not take a state out of this set.)
  # Session 65: 20 -> 18, Nebraska (trig_019qmwzbTMo9k83etPqjJV7z) and
  # Nevada (trig_012WYj2vrKgD7oxuURp3ygCb).
  expect_equal(sum(by_state$exposed), 18L)
})

test_that("an unscheduled probe is not a watch", {
  expect_true(all(by_state$exposed[by_state$state %in% DIFF_PROBE_NO_ROUTINE]))
})

test_that("the refresh surfaced New Jersey and Minnesota, which it could not before", {
  expect_equal(by_state$award_rows_new_id[by_state$state == "NJ"], 11L)
  expect_equal(by_state$award_rows_new_id[by_state$state == "MN"], 10L)
  expect_equal(by_state$awards_old[by_state$state == "NJ"], 0L)
})

test_that("every new row carries the discovery-only note", {
  expect_true(all(grepl("DISCOVERY ONLY", rows$note)))
})

test_that("a non-exhaustive pull is refused", {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  expect_error(
    {
      jsonlite::write_json(list(pull_metadata = list(exhaustive = FALSE),
                                pages = list()), tmp, auto_unbox = TRUE)
      d <- here::here("data", "raw", "rcj", "_test_diff_tmp")
      dir.create(d, showWarnings = FALSE)
      on.exit(unlink(d, recursive = TRUE), add = TRUE)
      file.copy(tmp, file.path(d, "awards.json"))
      diff_read("_test_diff_tmp", "awards")
    },
    "not exhaustive")
})

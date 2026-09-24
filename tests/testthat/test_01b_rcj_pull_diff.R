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

test_that("every state on no Routine is in the committed EXPOSED set", {
  # Session 67: a SUPERSET check, not an equality. `exposed` is frozen when
  # R/01b last built, while config/routines.csv grows every time a state goes
  # on a Routine (sessions 61, 64 and 65 each hand-edited the old count of
  # 18). Adding a Routine can only SHRINK exposure, so the committed set may
  # be larger than today's; a state on no Routine that the diff does NOT call
  # exposed means a Routine was removed or the diff is wrong, and that fails.
  r <- readr::read_csv(here::here("config", "routines.csv"), show_col_types = FALSE)
  unscheduled <- setdiff(by_state$state, r$state)
  expect_true(all(unscheduled %in% by_state$state[by_state$exposed]))
  expect_gt(length(unscheduled), 0L)
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

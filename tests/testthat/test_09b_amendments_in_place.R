# test_09b_amendments_in_place.R ----------------------------------------------
# SESSION 125, OWNER RULING (a): FSRS AMENDMENTS IN PLACE (CLAUDE.md §7).
# A re-filed subaward (same SAM report id, new amount) that LOWERS the amount
# nets like a de-obligation (accepted, AMENDED_DOWN). One that RAISES it, with
# the amendment dated after 2026-10-30, is a Year 2 increment: Year 1 keeps the
# prior amount and the increment is held BUDGET_PERIOD_2_HELD, unless a state
# source dates the increase on or before 10-30.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "09b_fsrs_award_source.R"))

fx <- function(amount, action_date, last_modified) {
  tibble::tibble(fsrs_id = c("up", "down", "upbp1", "same"), st = "ME", name = c("A", "B", "C", "D"),
                 subaward_number = c("1", "2", "3", "4"), uei = c("U1", "U2", "U3", "U4"),
                 amount = amount, action_date = action_date, last_modified = last_modified)
}
raws <- list(
  "2026-11-20" = fx(c(10321, 50490600, 200000, 5), c("2026-08-11", "2026-07-01", "2026-07-16", "2026-07-01"),
                    rep("2026-11-01", 4)),
  "2026-11-25" = fx(c(20642, 41388100, 241666.66, 5), c("2026-08-11", "2026-07-01", "2026-10-14", "2026-07-01"),
                    c("2026-11-23", "2026-11-23", "2026-11-09", "2026-11-01")))
none <- tibble::tibble(fsrs_id = character(0), state_source_date = character(0))

test_that("a raise re-filed after 10-30 keeps the prior amount and holds the increment", {
  am <- fsrs_amendments(raws = raws, increase_dates = none)
  u <- am[am$fsrs_id == "up", ]
  expect_equal(u$year1_amount, 10321)
  expect_equal(u$held_increment, 10321)
  expect_equal(u$amendment_kind, "AMENDED_UP_YEAR2_INCREMENT")
})

test_that("a lower re-filing nets like a de-obligation", {
  am <- fsrs_amendments(raws = raws, increase_dates = none)
  d <- am[am$fsrs_id == "down", ]
  expect_equal(d$year1_amount, 41388100)
  expect_equal(d$held_increment, 0)
  expect_equal(d$amendment_kind, "AMENDED_DOWN")
})

test_that("a raise whose re-filing moves the action date inside Budget Period 1 is accepted", {
  am <- fsrs_amendments(raws = raws, increase_dates = none)
  b <- am[am$fsrs_id == "upbp1", ]
  expect_equal(b$year1_amount, 241666.66)
  expect_equal(b$amendment_kind, "AMENDED_UP_IN_BP1")
})

test_that("a state source dating the increase inside Budget Period 1 makes it Year 1", {
  am <- fsrs_amendments(raws = raws, increase_dates = tibble::tibble(fsrs_id = "up", state_source_date = "2026-10-01"))
  u <- am[am$fsrs_id == "up", ]
  expect_equal(u$year1_amount, 20642)
  expect_equal(u$held_increment, 0)
  expect_equal(u$amendment_kind, "AMENDED_UP_STATE_DATED")
})

test_that("an unchanged amount is not an amendment", {
  am <- fsrs_amendments(raws = raws, increase_dates = none)
  expect_false("same" %in% am$fsrs_id)
})

test_that("the committed plan carries Maine's ten re-filings as held increments and KY FHKY as AMENDED_DOWN", {
  h <- readr::read_csv(here::here("data/reference/fsrs_held.csv"), show_col_types = FALSE, progress = FALSE)
  inc <- h[h$status == "BUDGET_PERIOD_2_HELD" & grepl("YEAR 2 INCREMENT", h$detail), ]
  expect_equal(sum(inc$st == "ME"), 10L)
  dn <- h[h$status == "AMENDED_DOWN", ]
  expect_true(any(grepl("HEALTHY KENTUCKY", dn$name) & abs(dn$amount - 41388100) < 0.01))
  # no written row carries a raised amount
  me <- readr::read_csv(here::here("data/reference/me_fsrs_awardees.csv"), show_col_types = FALSE, progress = FALSE)
  expect_false(any(abs(me$amount - 12222021) < 0.01))
  expect_true(any(abs(me$amount - 10401311) < 0.01))
})

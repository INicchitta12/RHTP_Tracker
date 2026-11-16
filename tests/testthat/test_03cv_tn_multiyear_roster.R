# test_03cv_tn_multiyear_roster.R --------------------------------------------
# Tennessee's "$422 Million ... 138 Projects" (session 118, owner ruling b): a
# FIVE-YEAR awarded-or-requested roster, archived as a non-award file.

library(testthat)

suppressMessages(source(here::here("R", "03cv_tn_multiyear_roster.R")))

test_that("the archived roster verifies and still reads as five-year", {
  expect_true(tnm_assert())
})

test_that("the file is 138 five-year lines, NOT Year 1 awards, with no amount column", {
  x <- readr::read_csv(TNM_OUT, show_col_types = FALSE)
  expect_equal(nrow(x), 138L)
  expect_false(any(c("amount", "round_amount", "hospital_attribution",
                     "distributed_to_hospital") %in% names(x)))
  expect_true(all(x$amount_type == "FIVE_YEAR_AWARDED_OR_REQUESTED"))
  expect_true(all(x$year1_amount_published == "No"))
  expect_equal(sum(tnm_cents(x$amount_awarded_or_requested_text)), TNM_TOTAL_CENTS)
  union_src <- paste(readLines(here::here("tests", "testthat", "test_state_union.R")), collapse = "\n")
  expect_false(grepl("tn_multiyear_awards_or_requests", union_src, fixed = TRUE))
  reg <- readr::read_csv(here::here("config", "budget_period_registry.csv"), show_col_types = FALSE)
  expect_false(any(grepl("tn_multiyear", unlist(reg), fixed = TRUE)))
})

test_that("hospital-typed reference lines are pinned (five-year, reference only)", {
  x <- readr::read_csv(TNM_OUT, show_col_types = FALSE)
  h <- x[x$reference_recipient_type == "HOSPITAL_OR_SYSTEM", ]
  expect_equal(nrow(h), 19L)
  expect_equal(sum(tnm_cents(h$amount_awarded_or_requested_text)), 7997764891)
})

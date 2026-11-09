# test_03cr_nc_year1_budget_plan.R ------------------------------------------
# North Carolina's "List of projects - Year 1" (session 116, owner ruling): a
# BUDGET PLAN that sums to the allotment, archived as a non-award file.

library(testthat)

suppressMessages(source(here::here("R", "03cr_nc_year1_budget_plan.R")))

test_that("the archived plan verifies and still reads as a plan", {
  expect_true(ncp_assert())
})

test_that("the plan file is 134 budget lines, NOT awards, with no amount column", {
  x <- readr::read_csv(NCP_OUT, show_col_types = FALSE)
  expect_equal(nrow(x), 134L)
  expect_false(any(c("amount", "round_amount", "hospital_attribution",
                     "distributed_to_hospital") %in% names(x)))
  expect_true(all(x$award_made == "No"))
  expect_true(all(x$budget_period == 1L))
  expect_equal(sum(ncp_cents(x$budgeted_amount_text)), NCP_TOTAL_CENTS)
  # A non-award file never enters the hospital union.
  union_src <- paste(readLines(here::here("tests", "testthat",
                                          "test_state_union.R")), collapse = "\n")
  expect_false(grepl("nc_year1_budget_plan", union_src, fixed = TRUE))
})

test_that("hospital-shaped reference lines are the three session 115 named, as budgeted", {
  x <- readr::read_csv(NCP_OUT, show_col_types = FALSE)
  h <- x[x$reference_recipient_type == "HOSPITAL_OR_SYSTEM", ]
  expect_setequal(unique(h$organization),
                  c("UNC Health", "Cumberland County Hospital System, Inc.",
                    "FirstHealth of the Carolinas"))
  expect_equal(sum(ncp_cents(h$budgeted_amount_text)), 2207821599)
  expect_equal(unique(x$cms_enrolment_ccns[x$organization ==
                 "Cumberland County Hospital System, Inc."]), "340028;342014")
  # Every UNC Health Hub Lead line carries the pass-through note; the core line
  # carries the owner's note.
  hub <- x[grepl("^ROOTS Hub Lead \\(UNC Health\\)", x$contract_title), ]
  expect_equal(nrow(hub), 8L)
  expect_true(all(!is.na(hub$pass_through_note)))
  core <- hub[grepl("Core Functions", hub$program_title), ]
  expect_equal(nrow(core), 1L)
  expect_match(core$pass_through_note, "pass-through ruling WHEN AWARDED")
  expect_true(all(x$reference_confidence %in% c("MEDIUM", "LOW")))
})

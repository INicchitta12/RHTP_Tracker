# test_vendor_figures_named.R -----------------------------------------------------
# SESSION 124 (owner Task 5): five named vendor figures, one definition each,
# computed by rhtp_vendor_figures() and stated by R/08 and R/09c under the
# same labels. Sessions 121 and 122 had called two different figures the
# "award line"; the gap was the provider pass-through cases.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "07_summary_calls.R"))

figs <- rhtp_vendor_figures(rhtp_spend_rows(sc_state_files()))

test_that("the five labels are settled and distinct", {
  expect_identical(figs$key, c("vendor_awards", "pass_through_awards", "vendor_intents",
                               "vendor_contract_maximums", "vendor_obligations"))
  expect_identical(figs$label[1], "Verified vendor awards (excluding provider pass-through)")
  expect_identical(figs$label[2], "Verified pass-through to providers (awards)")
  expect_equal(anyDuplicated(figs$label), 0L)
})

test_that("vendor awards equal the Vendor spending sheet's national award total", {
  f <- sort(list.files(here::here("data/reference"), "^year1_vendor_summary_.*\\.csv$", full.names = TRUE), decreasing = TRUE)[1]
  v <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(figs$usd[figs$key == "vendor_awards"], v$vendor_total_award_usd[v$state == "US"], tolerance = 1e-9)
  expect_equal(figs$usd[figs$key == "vendor_intents"], v$vendor_total_intent_usd[v$state == "US"], tolerance = 1e-9)
})

test_that("the old 'award line' gap is exactly the pass-through cases on the 116e list", {
  l <- readr::read_csv(here::here("data/reference/verified_vendor_list.csv"), show_col_types = FALSE)
  list_award <- sum(l$amount[l$amount_type == "award" & l$passed], na.rm = TRUE)
  gap <- list_award - figs$usd[figs$key == "vendor_awards"]
  ukhs_vhha <- sum(l$amount[l$case_id %in% c("VV003", "VV004", "VV005", "VV006", "VV016")])
  expect_equal(gap, ukhs_vhha, tolerance = 0.01)
})

test_that("pass-through reports the part already in hospital dollars, never more than itself", {
  pt <- figs[figs$key == "pass_through_awards", ]
  expect_gt(pt$usd, 0)
  expect_true(pt$of_which_in_hospital_usd >= 0 && pt$of_which_in_hospital_usd <= pt$usd)
  expect_true(all(is.na(figs$of_which_in_hospital_usd[figs$key != "pass_through_awards"])))
})

# test_03au_ct_year1_awardees.R ----------------------------------------------
# Session 54. Connecticut's $50M of executed grant agreements, every figure
# rounded, and the Hartford HealthCare pair recorded WITHOUT a split.

suppressWarnings(suppressMessages(source(here::here("R", "03au_ct_year1_awardees.R"))))
ct <- ct_year1_awardees()

test_that("four rows, $49,980,000; the hospitals sum to the release's '$46 million'", {
  expect_equal(nrow(ct), 4L)
  expect_equal(sum(ct$amount), 49980000)
  expect_equal(sum(ct$amount[ct$distributed_to_hospital == "Yes"]), 46e6)
  expect_silent(ct_assert_release())
})

test_that("every figure carries AMOUNT_ROUNDED_IN_SOURCE", {
  expect_true(all(grepl("AMOUNT_ROUNDED_IN_SOURCE", ct$flag_reason)))
  expect_true(all(ct$amount_confirmed == "No"))
})

test_that("the Hartford HealthCare pair is ONE row, NOT divided, in POOL_NAMED_HOSPITALS", {
  hh <- ct[grepl("Hartford HealthCare", ct$awardee), ]
  expect_equal(nrow(hh), 1L)
  expect_equal(hh$amount, 12650000)
  expect_equal(hh$hospital_attribution, "POOL_NAMED_HOSPITALS")
  expect_true(grepl("MULTI_RECIPIENT_FIELD", hh$flag_reason))
  expect_false(any(ct$amount == 6325000))
  p <- rhtp_hospital_dollar_partition(ct)
  expect_equal(p$dollars[p$bucket == "NAMED_HOSPITAL"], 33350000)
  expect_equal(p$dollars[p$bucket == "POOL_NAMED_HOSPITALS"], 12650000)
})

test_that("Mathematica is a vendor and $0 of hospital money", {
  m <- ct[ct$awardee == "Mathematica", ]
  expect_equal(m$recipient_type, "VENDOR_OR_CONTRACTOR")
  expect_equal(m$flow_type, "IN_KIND_BENEFIT")
  expect_equal(m$distributed_to_hospital, "No")
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(CT_AWARD_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, ct$awardee)
  expect_equal(d$amount, ct$amount)
})

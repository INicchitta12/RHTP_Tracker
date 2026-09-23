# test_03av_wv_year1_awardees.R ----------------------------------------------
# Session 54. West Virginia's seven named awards, $6,444,803.

suppressWarnings(suppressMessages(source(here::here("R", "03av_wv_year1_awardees.R"))))
wv <- wv_year1_awardees()

test_that("seven awards, $6,444,803, each quoted verbatim from its release", {
  expect_equal(nrow(wv), 7L)
  expect_equal(sum(wv$amount), 6444803)
  expect_silent(wv_assert_sources())
})

test_that("CAMC/Vandalia and the Cabell Huntington Foundation are the two hospital rows", {
  h <- wv[wv$distributed_to_hospital == "Yes", ]
  expect_setequal(h$awardee, c("CAMC/Vandalia Health", "Cabell Huntington Foundation"))
  expect_equal(sum(h$amount), 1224000)
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  # The foundation rests on §10.2's named-parent row, a reading -> LOW.
  expect_equal(h$determination_confidence[h$awardee == "Cabell Huntington Foundation"], "LOW")
})

test_that("the WVU nursing school is UNIVERSITY_OR_AHC and not a hospital dollar", {
  n <- wv[wv$awardee == "WVU Medicine Center for Nursing Education", ]
  expect_equal(n$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(n$distributed_to_hospital, "No")
})

test_that("Ascend WV's '$2.4 million' is flagged rounded; Spotted Owl is not promoted", {
  a <- wv[wv$awardee == "Ascend WV", ]
  expect_equal(a$flag_reason, "AMOUNT_ROUNDED_IN_SOURCE")
  s <- wv[wv$awardee == "Spotted Owl Healthcare Organization", ]
  expect_equal(s$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_equal(s$distributed_to_hospital, "No")
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(WV_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, wv$awardee)
  expect_equal(d$amount, wv$amount)
})

# test_03bd_wa_year1_awardees.R ---------------------------------------------
# Washington's first tier (session 60). The weight is on what must NOT reach a
# hospital bucket: the state hospital association's $42M.

library(testthat)
source(here::here("R", "03bd_wa_year1_awardees.R"))

wa <- wa_year1_awardees()
committed <- readr::read_csv(here::here(WAA_AWARD_CSV), show_col_types = FALSE)

test_that("the sources still say what the rows rest on", {
  expect_true(waa_assert_sources())
})

test_that("eight rows, $67,020,000 named, the Tribes' pool in round_amount only", {
  expect_equal(nrow(wa), 8L)
  expect_equal(sum(wa$amount, na.rm = TRUE), 67020000)
  tribes <- wa[is.na(wa$amount), ]
  expect_equal(nrow(tribes), 1L)
  expect_equal(tribes$round_amount, 19410000)
  expect_true(grepl("RECIPIENT_NOT_NAMED", tribes$flag_reason))
})

test_that("the committed file is what the builder produces", {
  expect_equal(nrow(committed), nrow(wa))
  expect_equal(committed$awardee, wa$awardee)
  expect_equal(committed$flow_type, wa$flow_type)
})

test_that("WSHA's $42M is Unclear and in NEITHER bucket", {
  w <- wa[wa$awardee == "Washington State Hospital Association", ]
  expect_equal(w$amount, 42000000)
  expect_equal(w$recipient_type, "NONPROFIT_CBO")
  expect_equal(w$distributed_to_hospital, "Unclear")
  expect_true(grepl("FLOW_UNRESOLVED_HOSPITAL_AFFILIATED", w$flag_reason))
  p <- rhtp_hospital_dollar_partition(wa)
  expect_equal(sum(p$rows), 0L)
})

test_that("the counterfactual: the classifier alone would call WSHA a hospital", {
  cls <- rhtp_classify_recipient_type("Washington State Hospital Association", "WA")
  expect_equal(cls$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(cls$determination_confidence, "HIGH")
  expect_true(grepl("Classifier said HOSPITAL_OR_SYSTEM/HIGH",
                    wa$recipient_type_source[1], fixed = TRUE))
})

test_that("the flow classifier reads WSHA's sentence as IN_KIND, and it is NOT used", {
  f <- rhtp_classify_flow("NONPROFIT_CBO", paste(
    "Washington State Hospital Association is receiving applications from",
    "hospitals for critical technology infrastructure and maintenance needs"),
    award_made = TRUE)
  expect_equal(f$flow_type, "IN_KIND_BENEFIT")
  expect_equal(wa$flow_type[1], "PASS_THROUGH_UNRESOLVED")
})

test_that("the deck's subtotals disagree with its rows, and that is pinned", {
  s <- waa_subtotal_check()
  expect_equal(s$gap, c(-10000, 0, 10000, 4020000, 430000))
})

test_that("DOH and DSHS are pools in the status file, which has no amount column", {
  st <- wa_year1_status()
  expect_false("amount" %in% names(st))
  expect_true(any(grepl("^DOH", st$line)) && any(grepl("^DSHS", st$line)))
  expect_false(any(grepl("DOH|DSHS|Department of", wa$awardee)))
})

# test_03be_va_year1_awardees.R ---------------------------------------------
# Virginia's first tier (session 60): eleven named partners, no amounts.

library(testthat)
source(here::here("R", "03be_va_year1_awardees.R"))

va <- va_year1_awardees()
committed <- readr::read_csv(here::here(VAA_AWARD_CSV), show_col_types = FALSE)

test_that("the sources still say what the rows rest on", {
  expect_true(vaa_assert_sources())
})

test_that("eleven partners, every amount empty, no round figure repeated", {
  expect_equal(nrow(va), 11L)
  expect_true(all(is.na(va$amount)))
  expect_true(all(is.na(va$round_amount)))
  expect_equal(committed$awardee, va$awardee)
})

test_that("a per-partner figure in the release fails the build", {
  t <- vaa_pdf(VAA_RELEASE)
  t2 <- paste(t, "Virginia Works will receive $9,500,000.")
  expect_error(vaa_assert_sources(release = t2), "REWRITE")
})

test_that("a twelfth partner fails the build", {
  t <- vaa_pdf(VAA_RELEASE)
  expect_error(vaa_assert_sources(release = paste(t, "• A new partner")),
               "12 bullets")
})

test_that("VHHA Foundation is an association's foundation and is Unclear", {
  v <- va[grepl("VHHA Foundation", va$awardee), ]
  expect_equal(v$recipient_type, "NONPROFIT_CBO")
  expect_equal(v$distributed_to_hospital, "Unclear")
  cls <- rhtp_classify_recipient_type(v$awardee, "VA")
  expect_equal(cls$recipient_type, "HOSPITAL_OR_SYSTEM")
  f <- rhtp_classify_flow("NONPROFIT_CBO", paste(
    "VHHA Foundation will administer grant funding to help rural hospitals",
    "and providers develop and deploy RPM programs."), award_made = TRUE)
  expect_equal(f$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_error(vaa_assert_sources(vhha = "nothing here"), "mixed eligible class")
})

test_that("Virginia reaches no hospital bucket", {
  expect_false(any(va$distributed_to_hospital == "Yes"))
  expect_equal(sum(rhtp_hospital_dollar_partition(va)$rows), 0L)
})

# test_03cs_ia_combat_cancer_r2_awardees.R -----------------------------------
# Iowa's Combat Cancer Health Hubs Round 2 NOIA (session 116, owner ruling):
# four named hospitals, intents, no amounts; the footer is the allotment.

library(testthat)

suppressMessages(source(here::here("R", "03cs_ia_combat_cancer_r2_awardees.R")))

test_that("the archived notice still carries every sentence the file rests on", {
  expect_true(iar2_assert())
})

test_that("the file is four hospital intents at $0, each with a summary call", {
  x <- readr::read_csv(IAR2_OUT, show_col_types = FALSE)
  expect_equal(nrow(x), 4L)
  expect_true(all(is.na(x$amount)))
  expect_true(all(x$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(x$hospital_attribution == "NAMED_HOSPITAL"))
  expect_true(all(x$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(x$determination_confidence == "MEDIUM"))
  expect_true(all(x$budget_period == 1L))
  expect_true(all(x$summary_hospital_call == "HOSPITAL"))
  expect_true(all(x$summary_call_basis == "CODED"))
  expect_setequal(x$awardee, IAR2_BIDDERS$dba)
  for (cc in IAR2_BIDDERS$ccn) expect_true(any(grepl(paste0("CCN ", cc), x$determination_basis)))
})

test_that("the footer is refused as a round total", {
  expect_error(rhtp_assert_footer_not_allotment(IAR2_FOOTER, "IA", "SOLICITATION"))
})

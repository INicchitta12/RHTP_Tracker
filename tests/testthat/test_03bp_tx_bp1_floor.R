# test_03bp_tx_bp1_floor.R -------------------------------------------------
# Texas's BP1 annual report: a FLOOR of 33 named districts, never an award
# file (session 82). Offline, against data/evidence/TX/.

library(testthat)
source(here::here("R", "03bp_tx_bp1_floor.R"))

e <- tx_bp1_first_tier()
fl <- readr::read_csv(TX_BP1_CSV, show_col_types = FALSE)

test_that("the report names 33 districts at $750,000 obligated, $0 disbursed", {
  lg <- tx_bp1_assert(e)
  expect_equal(nrow(lg), 33L)
  expect_equal(sum(lg$obligated_bp1_report), 24750000)
  expect_equal(sum(lg$disbursed_bp1_report), 0)
})

test_that("a 34th district trips the floor's assertion", {
  more <- dplyr::bind_rows(e, tibble::tibble(
    entity_id = 99L, entity = "Example County Hospital District",
    entity_type = "Other Local Government", obligated_bp1_report = 750000,
    disbursed_bp1_report = 0))
  expect_error(tx_bp1_assert(more), "NOW NAMES 34")
})

test_that("the floor screens enrolment and codes nothing", {
  expect_equal(nrow(fl), 33L)
  expect_equal(as.integer(table(fl$enrolment_screen)[c(
    "EXACT_LEGAL_NAME", "NEAR_NAME_NEEDS_HAND_BRIDGE",
    "NO_HOSPITAL_ENROLMENT_FOUND")]), c(28L, 4L, 1L))
  expect_false(any(c("amount", "recipient_type", "distributed_to_hospital",
                     "hospital_attribution") %in% names(fl)))
})

test_that("the floor is never an award file in the union", {
  ex <- parse(here::here("tests", "testthat", "test_state_union.R"))
  for (x in ex) if (is.call(x) && identical(x[[2]], as.name("STATE_FILES")))
    sf <- eval(x[[3]], envir = baseenv())
  expect_false(any(grepl("tx_", sf)))
})

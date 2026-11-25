# test_session124_government_typing.R -------------------------------------------
# SESSION 124 (owner Task 5b): government bodies the classifier had typed
# NONPROFIT_CBO. Hawaii's State Health Planning and Development Agency is a
# state agency; the sweep of every NONPROFIT_CBO row whose name contains
# Agency / Department / Dept / Office of / Commission re-typed five more.

suppressPackageStartupMessages(library(testthat))
rd <- function(f) readr::read_csv(here::here("data/reference", f),
                                  col_types = readr::cols(.default = "c"), progress = FALSE)

test_that("Hawaii SHPDA is a state agency and not a hospital, on both rows", {
  hi <- rd("hi_fsrs_awardees.csv")
  s <- hi[grepl("STATE HLTH. PLNG. & DEV. AGENCY", hi$awardee, fixed = TRUE), ]
  expect_equal(nrow(s), 2L)
  expect_setequal(as.numeric(s$amount), c(45447889, 25000000))
  expect_true(all(s$recipient_type == "STATE_AGENCY"))
  expect_true(all(s$distributed_to_hospital == "No"))
  expect_true(all(s$summary_hospital_call == "NOT_HOSPITAL"))
})

test_that("the sweep's re-typings hold", {
  want <- list(
    list("ok_fsrs_awardees.csv", "HEALTH CARE WORKFORCE TRAINING COMMISSION", "STATE_AGENCY"),
    list("ri_fsrs_awardees.csv", "RI DEPT. OF BEHAVIORAL HEALTHCARE DEVEL", "STATE_AGENCY"),
    list("me_fsrs_awardees.csv", "AUGUSTA SCHOOL DEPARTMENT", "SCHOOL_OR_DISTRICT"),
    list("nv_year1_awardees.csv", "Esmeralda County Board of Commissioners", "LOCAL_GOVT_OR_PUBLIC_HEALTH"),
    list("ok_year1_ems_cp_awardees.csv", "Elk City Fire Department", "EMS_OR_PSAP"),
    list("ok_year1_ems_cp_awardees.csv", "Tonkawa Fire Department", "EMS_OR_PSAP"))
  for (w in want) {
    d <- rd(w[[1]]); r <- d[d$awardee == w[[2]], ]
    expect_gt(nrow(r), 0)
    expect_true(all(r$recipient_type == w[[3]]), label = w[[2]])
    expect_true(all(r$distributed_to_hospital == "No"), label = w[[2]])
  }
})

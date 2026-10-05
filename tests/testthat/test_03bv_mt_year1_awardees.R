# test_03bv_mt_year1_awardees.R -----------------------------------------------
# Montana's EMS Equipment Grant (session 88). Offline, against the archive.

library(testthat)

source(here::here("R", "03bv_mt_year1_awardees.R"))

mt_d <- mt_validate()

test_that("four named ambulance grants, ROUNDED, and one unnamed pool", {
  expect_equal(nrow(mt_d), 5L)
  named <- mt_d[!is.na(mt_d$amount), ]
  expect_equal(nrow(named), 4L)
  expect_true(all(named$amount == 340000))
  expect_true(all(named$flag_reason == "AMOUNT_ROUNDED_IN_SOURCE"))
  expect_setequal(named$awardee, MT_AMBULANCE_AWARDS$awardee)
})

test_that("the pool row carries no amount and enters no hospital bucket", {
  pool <- mt_d[mt_d$recipient_type == "NOT_YET_NAMED", ]
  expect_equal(nrow(pool), 1L)
  expect_true(is.na(pool$amount))
  expect_equal(pool$n_recipients, 75L)
  expect_equal(pool$distributed_to_hospital, "Unclear")
  # §6.2: no figure is derived for the 75 by subtraction.
  expect_false(grepl("7,340,000|7340000", paste(pool, collapse = " ")))
  source(here::here("R", "utils_recipient_classification.R"))
  expect_equal(nrow(rhtp_hospital_dollar_partition(mt_d)), 0L)
})

test_that("the footer is the allotment and the round is never an award", {
  expect_true(mt_assert_source())
  expect_false(any(mt_d$amount %in% c(MT_FOOTER, MT_ROUND), na.rm = TRUE))
  expect_true(all(mt_d$round_amount == MT_ROUND))
})

test_that("no row is HIGH (§7) and Prairie County is queued, not re-typed", {
  expect_false(any(mt_d$determination_confidence == "HIGH"))
  pc <- mt_d[mt_d$awardee == "Prairie County Ambulance Service", ]
  expect_equal(pc$recipient_type, "EMS_OR_PSAP")
  q <- readr::read_csv(here::here("data", "reference", "classification_review_queue.csv"),
                       show_col_types = FALSE)
  expect_true("MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR" %in% q$question_id)
  expect_true(mt_assert_federal())
})

test_that("the committed file is the build", {
  f <- readr::read_csv(MT_CSV, show_col_types = FALSE)
  expect_equal(nrow(f), nrow(mt_d))
  expect_equal(f$awardee, mt_d$awardee)
  expect_equal(f$amount, mt_d$amount)
})

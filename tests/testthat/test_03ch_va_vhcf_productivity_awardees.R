# test_03ch_va_vhcf_productivity_awardees.R ----------------------------------
# VHCF's Provider Productivity round (session 107). Offline: reads the
# committed archive, the committed CMS enrolment files and the committed CSV.

library(testthat)
source(here::here("R", "03ch_va_vhcf_productivity_awardees.R"))

committed <- readr::read_csv(VA_PP_CSV, show_col_types = FALSE, progress = FALSE)

test_that("the release parses to 23 lines summing to $8,644,000", {
  d <- va_pp_parse()
  expect_equal(nrow(d), 23L)
  expect_equal(sum(d$amount), 8644000)
  expect_silent(va_pp_assert_roster(d))
  expect_equal(sum(d$awardee == "Buchanan General Hospital"), 2L)
  expect_equal(sum(d$awardee == "Tri-Area Community Health"), 2L)
  expect_setequal(unique(d$category), VA_PP_CATEGORIES)
})

test_that("the CMS footer is the ALLOTMENT and is refused as the round total (§0.2)", {
  expect_error(rhtp_assert_footer_not_allotment(HVA_ALLOTMENT, "VA", "SOLICITATION",
                                                label = "test"))
  expect_true(all(committed$round_amount == 8644000))
})

test_that("hospital rows: four on exact CMS records, three system parents, one undivided pair", {
  h <- committed[committed$hospital_attribution == "NAMED_HOSPITAL", ]
  expect_equal(nrow(h), 7L)
  expect_equal(sum(h$amount), 4579000)
  exact <- h[h$basis_type == "ORG_WEBSITE", ]
  expect_setequal(unique(exact$awardee), c("Bath County Community Hospital",
    "Buchanan General Hospital", "Carilion Medical Center"))
  expect_true(all(!is.na(exact$ccn)) && all(exact$determination_confidence == "MEDIUM"))
  gk <- h[h$basis_type == "GENERAL_KNOWLEDGE", ]
  expect_setequal(gk$awardee, c("Valley Health System", "Ballad Health", "Sentara Health"))
  expect_equal(sum(gk$amount), 3000000)
  expect_true(all(gk$determination_confidence == "LOW") && all(is.na(gk$ccn)))
  pr <- committed[committed$hospital_attribution == "POOL_NAMED_HOSPITALS", ]
  expect_equal(nrow(pr), 1L)
  expect_equal(pr$amount, 1000000)
  expect_match(pr$flag_reason, "MULTI_RECIPIENT_FIELD")
  expect_false(any(committed$determination_confidence == "HIGH"))
})

test_that("UVA Health is NON_HOSPITAL and queued; FQHCs are not hospitals", {
  uva <- committed[committed$awardee == "UVA Health", ]
  expect_equal(uva$distributed_to_hospital, "No")
  expect_equal(uva$recipient_type, "UNIVERSITY_OR_AHC")
  fq <- committed[committed$category == "Federally Qualified Health Centers (FQHCs)", ]
  expect_true(all(fq$recipient_type == "FQHC_OR_RHC"))
})

test_that("the committed file is what the archive rebuilds", {
  a <- va_pp_awardees()
  expect_equal(nrow(a), nrow(committed))
  expect_equal(a$amount, committed$amount)
  expect_equal(a$hospital_attribution, committed$hospital_attribution)
})

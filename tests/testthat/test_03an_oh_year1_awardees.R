# test_03an_oh_year1_awardees.R ----------------------------------------------
# Ohio: ONE named, PRICED award, to a university. Committed files only.
#
# THE TEST THAT CARRIES THE WEIGHT IS THE FOOTER ONE. Ohio's CMS footer prints
# $10,000,000 -- the SUBAWARD, not the allotment and not a pool -- which is a
# position §0.2 had not met, and one the tier check cannot classify because
# the §7.1 anchor is the only external number it has. That limit is pinned
# here rather than papered over.

library(testthat)

source(here::here("R", "03an_oh_year1_awardees.R"))

skip_without_archive <- function() {
  if (!oh_have_archive()) skip("the OH evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


test_that("the release names Ohio University at $10,000,000", {
  skip_without_archive()
  expect_true(oh_assert_the_award())
  d <- oh_year1_awardees()
  expect_equal(d$awardee, "Ohio University")
  expect_equal(d$amount, 10000000)
  expect_equal(d$amount_confirmed, "Yes")
})


# -- §0.2: a footer whose figure is the SUBAWARD -----------------------------

test_that("the footer prints the subaward, not the allotment or a pool", {
  skip_without_archive()
  f <- rhtp_footer_parse(oh_html_text("release"))
  expect_equal(nrow(f), 1L)
  expect_true(f$fully_federal)
  expect_equal(f$tier_amount, OH_AWARD)
  expect_equal(f$tier_amount, 10000000)
  # Neither the allotment ...
  expect_gt(abs(OH_AWARD - OH_ALLOTMENT), RHTP_FOOTER_ALLOTMENT_MARGIN)
  # ... nor anything the tier check can distinguish from a pool.
  expect_true(oh_assert_footer_is_the_subaward())
})

test_that("the tier check ACCEPTS it as a pool, which is the pinned limit", {
  a <- tibble::tibble(state = "OH", fy2026_allotment = OH_ALLOTMENT)
  # Correct on the only question it can ask ...
  expect_error(
    rhtp_assert_footer_not_allotment(OH_AWARD, "OH", "STATE_ALLOTMENT",
                                     allotments = a),
    "declared STATE_ALLOTMENT")
  # ... and silent on the one that matters here. What says Tier 3 is the
  # DOCUMENT: one recipient, one figure, one headline.
  expect_true(rhtp_assert_footer_not_allotment(OH_AWARD, "OH", "SOLICITATION",
                                               allotments = a))
})


# -- the coding --------------------------------------------------------------

test_that("a university is NON_HOSPITAL and Ohio has no hospital bucket", {
  d <- oh_year1_awardees()
  expect_equal(d$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(d$flow_type, "NON_HOSPITAL")
  expect_equal(d$distributed_to_hospital, "No")
  expect_true(oh_assert_contributes_no_bucket())
  expect_equal(nrow(rhtp_hospital_dollar_partition(d)), 0L)
})

test_that("the counterfactual is priced at eight figures", {
  # One wrong recipient_type and a state with no hospital dollars acquires
  # $10,000,000 of them. This is why a one-row file is in the union test.
  d <- oh_year1_awardees()
  d$recipient_type <- "HOSPITAL_OR_SYSTEM"
  d$flow_type <- "DIRECT"
  d$distributed_to_hospital <- "Yes"
  d$hospital_attribution <- "NAMED_HOSPITAL"
  part <- rhtp_hospital_dollar_partition(d)
  expect_equal(part$dollars, 10000000)
})

test_that("the classifier agrees WITHOUT an override", {
  # The contrast with Delaware, stated as a test rather than as a comment.
  cls <- rhtp_classify_recipient_type("Ohio University", "OH")
  expect_equal(cls$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(cls$determination_confidence, "HIGH")
  expect_equal(oh_year1_awardees()$recipient_type, cls$recipient_type)
})


# -- the partial year --------------------------------------------------------

test_that("Ohio says more is coming, so the file is a PARTIAL year", {
  skip_without_archive()
  expect_true(oh_assert_more_to_come())
  faked <- gsub("Additional contracts will be awarded", "All contracts awarded",
                oh_html_text("release"), fixed = TRUE)
  expect_error(
    oh_assert_more_to_come(as_raw_html(paste0("<html><body>", faked,
                                              "</body></html>"))),
    "no longer says")
  # $192,030,262 of the allotment is in no public roster.
  expect_equal(OH_ALLOTMENT - OH_AWARD, 192030262)
})

test_that("ODH names nobody, and naming somebody stops the build", {
  skip_without_archive()
  expect_true(oh_assert_odh_names_nobody())
  expect_error(
    oh_assert_odh_names_nobody(
      as_raw_html("<html><body>Ohio University was awarded</body></html>")),
    "now names Ohio University")
})

test_that("the award postdates the Notice of Award", {
  expect_gt(oh_assert_after_noa(), 150L)
})

test_that("RCJ is RIGHT about Ohio, which is rare enough to pin", {
  d <- oh_disposition()
  expect_equal(sum(d$rcj_rows), 1L)
  expect_equal(d$disposition, "REAL_AWARD_CARRIED_CORRECTLY")
})

test_that("the status table has no amount column", {
  st <- oh_status_table()
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "UNREADABLE"))
})

# test_03am_id_year1_awardees.R ----------------------------------------------
# Idaho: until session 108, ONE named awardee, no amount, no hospital. Session
# 108: DHW's list of awardees as of Oct. 16 (R/03ck). Committed files only.
#
# Idaho is in the suite mainly as DELAWARE'S CONTROL: the same classifier
# returns the same fallback for Comagine Health, and there it is the RIGHT
# answer, because Idaho states no form and no governing document states one
# either. The pair is what shows the Delaware override is about evidence
# rather than about the classifier being weak.

library(testthat)

source(here::here("R", "03am_id_year1_awardees.R"))

skip_without_archive <- function() {
  if (!id_have_archive()) skip("the ID evidence archive is not on disk")
}
as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


test_that("session 108: the funding page links the one list extracted", {
  skip_without_archive()
  expect_true(id_assert_roster_link())
  faked <- paste0("<html><body>",
                  stringr::str_replace_all(id_html_text("funding"), "\n", " "),
                  " See the list of awardees as of Nov. 20. </body></html>")
  expect_error(id_assert_roster_link(as_raw_html(faked)), "new roster")
})

test_that("the funding page still prices nobody itself: the list carries the figures", {
  skip_without_archive()
  expect_true(id_assert_no_amount())
  faked <- paste0("<html><body>",
                  stringr::str_replace_all(id_html_text("funding"), "\n", " "),
                  " Award amount: $2,400,000 </body></html>")
  expect_error(id_assert_no_amount(as_raw_html(faked)), "must be read")
})

test_that("session 108: 114 lines, $180,701,813.99; the two MOA/MOU lines are out of the file", {
  d <- idr_read()
  expect_silent(idr_assert_roster(d))
  expect_equal(nrow(d), 114L)
  expect_equal(round(sum(d$amount), 2), 180701813.99)
  a <- id_year1_awardees()
  expect_equal(nrow(a), 112L)
  expect_equal(round(sum(a$amount), 2), 157801813.99)
  expect_false(any(grepl("Military Division|State Board of Education", a$awardee)))
  st <- id_status_table()
  expect_true(any(st$stage == "INTER_AGENCY_NOT_SUBAWARD"))
  expect_true(all(a$validation_source_type == "NOTICE_OF_AWARD"))
})

test_that("session 108: the hospital rows, typed on CMS ID enrolment", {
  a <- id_year1_awardees()
  expect_silent(idr_assert_typing(a))
  expect_silent(id_assert_roster_partition(a))
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 48L)
  expect_equal(round(sum(h$amount), 2), 85389815.69)
  sl <- h[grepl("Luke.s Health System", h$awardee), ]
  expect_equal(nrow(sl), 3L)
  expect_true(all(sl$basis_type == "GENERAL_KNOWLEDGE" & sl$determination_confidence == "LOW" & is.na(sl$ccn)))
  expect_equal(a$ccn[a$awardee == "Syringa Hospital and Clinics"], "131315")
  expect_equal(a$ccn[a$awardee == "Gritman Medical Center"], "131327")
  un <- a[a$distributed_to_hospital == "Unclear", ]
  expect_equal(round(sum(un$amount), 2), 18353321)
  expect_false(any(a$determination_confidence == "HIGH"))
})

test_that("§0.2: the one figure is the allotment", {
  skip_without_archive()
  expect_true(id_assert_footer_is_the_allotment())
  expect_lt(abs(ID_FOOTER - ID_ALLOTMENT), 1)
})

test_that("the footer's subject is the WEAKEST form met so far", {
  skip_without_archive()
  expect_true(id_assert_footer_is_weak_form())
  # "This website", not "This project" / "This program" / "This publication".
  expect_true(grepl("This website is supported by",
                    id_html_text("funding"), fixed = TRUE))
})

test_that("the classifier's fallback is still the answer for Comagine Health", {
  # THE CONTRAST WITH DELAWARE: Idaho's list states no form for Comagine.
  cls <- rhtp_classify_recipient_type("Comagine Health", "ID")
  expect_equal(cls$recipient_type, "NONPROFIT_CBO")
  d <- id_year1_awardees()
  cg <- d[d$awardee %in% c("Comagine Health", "Co Magine Health"), ]
  expect_equal(nrow(cg), 3L)
  expect_true(all(cg$recipient_type == "NONPROFIT_CBO" & cg$distributed_to_hospital == "No"))
})

test_that("the solicitation postdates the Notice of Award", {
  expect_gt(id_assert_after_noa(), 150L)
})

test_that("the RCJ name is corrupted and is NOT what the row is built from", {
  d <- id_disposition()
  expect_equal(sum(d$rcj_rows), 1L)
  expect_true(grepl("Co-Imagine Health", d$evidence[1]))
  expect_true(grepl("THIS PROJECT'S READING AND NOT A SOURCE'S", d$evidence[1]))
  expect_true("Comagine Health" %in% id_year1_awardees()$awardee)
})

test_that("the status table has no amount column", {
  st <- id_status_table()
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "AWARDED_ROSTER_PUBLISHED"))
})


# -- session 63: the disposition after the 2026-09-24 pull -------------------

test_that("the ID disposition covers the live candidates and its prose agrees", {
  skip_if_not(file.exists(here::here("data", "interim",
                                     "stage2_record_table.rds")))
  rt <- rhtp_record_table_live()
  live <- sum(rt$state == "ID" & rt$award_tier == "SUBAWARD")
  d <- id_disposition()
  expect_equal(sum(d$rcj_rows), live)
  expect_silent(rhtp_assert_disposition_prose(d, "ID"))
  committed <- readr::read_csv(ID_DISPO_CSV, show_col_types = FALSE)
  expect_equal(committed$rcj_rows, d$rcj_rows)
  expect_equal(committed[[ncol(committed)]], d[[ncol(d)]])
})

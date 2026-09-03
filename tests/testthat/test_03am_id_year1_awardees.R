# test_03am_id_year1_awardees.R ----------------------------------------------
# Idaho: ONE named awardee, no amount, no hospital. Committed files only.
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


test_that("Idaho names exactly one awardee", {
  skip_without_archive()
  expect_true(id_assert_one_awardee())
  expect_equal(stringr::str_count(id_html_text("funding"),
                                  stringr::fixed("Awardee:")), 1L)
})

test_that("a second 'Awardee:' line stops the build", {
  skip_without_archive()
  faked <- paste0("<html><body>",
                  stringr::str_replace_all(id_html_text("funding"), "\n", " "),
                  " Awardee: Some Other Organisation </body></html>")
  expect_error(id_assert_one_awardee(as_raw_html(faked)),
               "carried ONE")
})

test_that("Idaho prices nobody", {
  skip_without_archive()
  expect_true(id_assert_no_amount())
  d <- id_year1_awardees()
  expect_true(is.na(d$amount))
  expect_true(is.na(d$round_amount))
})

test_that("an amount appearing forces a rewrite", {
  skip_without_archive()
  faked <- paste0("<html><body>",
                  stringr::str_replace_all(id_html_text("funding"), "\n", " "),
                  " Award amount: $2,400,000 </body></html>")
  expect_error(id_assert_no_amount(as_raw_html(faked)), "must be REWRITTEN")
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

test_that("the classifier's fallback is the RIGHT answer here", {
  # THE CONTRAST WITH DELAWARE. Same machine answer, opposite verdict, because
  # Idaho states no form and no governing document does either.
  cls <- rhtp_classify_recipient_type("Comagine Health", "ID")
  expect_equal(cls$recipient_type, "NONPROFIT_CBO")
  expect_equal(cls$determination_confidence, "LOW")
  d <- id_year1_awardees()
  expect_equal(d$recipient_type, cls$recipient_type)
  expect_true(grepl("NOT STATED BY THE SOURCE", d$recipient_type_source))
  expect_true(grepl("RECIPIENT_TYPE_INFERRED", d$flag_reason))
})

test_that("Idaho contributes to NO hospital bucket", {
  expect_true(id_assert_contributes_no_bucket())
  expect_equal(nrow(rhtp_hospital_dollar_partition(id_year1_awardees())), 0L)
})

test_that("the award is an INTENT, in Idaho's own future tense", {
  d <- id_year1_awardees()
  expect_equal(d$validation_source_type, "NOTICE_OF_INTENT_TO_AWARD")
  expect_equal(d$amount_confirmed, "No")
  expect_true(grepl("AMOUNT_PRELIMINARY", d$flag_reason))
})

test_that("the solicitation postdates the Notice of Award", {
  expect_gt(id_assert_after_noa(), 150L)
})

test_that("the RCJ name is corrupted and is NOT what the row is built from", {
  d <- id_disposition()
  expect_equal(sum(d$rcj_rows), 1L)
  expect_true(grepl("Co-Imagine Health", d$evidence[1]))
  expect_true(grepl("THIS PROJECT'S READING AND NOT A SOURCE'S", d$evidence[1]))
  expect_equal(id_year1_awardees()$awardee, "Comagine Health")
})

test_that("the status table has no amount column", {
  st <- id_status_table()
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "UNREADABLE"))
})

# test_03ag_ny_year1_probe.R --------------------------------------------------
# New York: a NEGATIVE whose CONTRACT START has passed, and the first state
# requiring a hospital in every award. Committed files only -- no network.
#
# The two tests that carry the weight are the eligible-class one (losing that
# sentence would silently re-code a $76.2M pool from `Unclear` towards `Yes`)
# and the §0.2 pair, because New York's programme page carries ONE dollar
# figure and it is the allotment, on a page whose only solicitation is a
# $76,190,022 pool.

library(testthat)

source(here::here("R", "03ag_ny_year1_probe.R"))

skip_without_archive <- function() {
  if (!ny_have_archive()) skip("the NY evidence archive is not on disk")
}

as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


# -- the negative ------------------------------------------------------------

test_that("New York names no grantee", {
  skip_without_archive()
  expect_true(ny_assert_no_roster())
  expect_length(ny_award_language(ny_html_text("programme")), 0L)
})

test_that("the roster tripwire fires on every award phrase", {
  skip_without_archive()
  for (p in NY_AWARD_POSTED) {
    expect_error(
      ny_assert_no_roster(bodies = list(programme = as_raw_html(
        paste("<html><body>", p, "</body></html>")))),
      "award language has appeared", info = p)
  }
})


# -- the date, which is a CONTRACT START and not an announcement -------------

test_that("the RCHI contract start has passed", {
  skip_without_archive()
  expect_true(ny_assert_contract_start_passed())
  expect_equal(NY_CONTRACT_START, as.Date("2026-09-01"))
})

test_that("the date is re-derived against `today`, not typed", {
  skip_without_archive()
  expect_false(ny_assert_contract_start_passed(today = as.Date("2026-08-15")))
  expect_message(ny_assert_contract_start_passed(today = as.Date("2026-08-15")),
                 "not yet overdue")
  expect_true(ny_assert_contract_start_passed(today = as.Date("2026-09-02")))
})

test_that("DOH's own deck still says the reviews are unfinished", {
  skip_without_archive()
  expect_true(ny_assert_reviews_in_progress())
  txt <- ny_pdf_text("update_aug12")
  # 0.3 IN THE STATE'S OWN NUMBERS: oversubscribed two to one, nobody named.
  expect_true(grepl("91 Applications", txt, fixed = TRUE))
  expect_true(grepl("156,000,000", txt, fixed = TRUE))
  expect_gt(156000000 / NY_RCHI_POOL, 2)
})


# -- the eligible class, which is new to this repository ---------------------

test_that("a hospital is REQUIRED in every RCHI partnership", {
  skip_without_archive()
  expect_true(ny_assert_hospital_required())
  txt <- stringr::str_replace_all(ny_pdf_text("rchi_guidance"), "\\s+", " ")
  expect_true(grepl(
    "A hospital must be included as either the lead applicant or the",
    txt, fixed = TRUE))
  # AND IS NOT NECESSARILY THE RECIPIENT, which is why this stays a 0.3
  # question rather than becoming Illinois's answer.
  expect_true(grepl("registered not-for-profit 501(c)(3)", txt, fixed = TRUE))
})

test_that("losing either half of the eligible class stops the build", {
  skip_without_archive()
  # A guidance that no longer requires a hospital.
  expect_error(
    ny_assert_hospital_required(body = charToRaw("no such text")),
    "no longer requires a hospital|PDF|pdf")
})


# -- 0.2: the only figure on the page is the allotment -----------------------

test_that("the footer is the ALLOTMENT and is refused as the RCHI pool", {
  skip_without_archive()
  expect_true(ny_assert_footer_present())
  expect_true(ny_assert_footer_is_the_allotment())
  expect_error(
    rhtp_assert_footer_not_allotment(NY_FOOTER, "NY", "SOLICITATION"),
    "almost certainly Tier 1")
})

test_that("the margin DISCRIMINATES -- the genuine pool passes", {
  # Without this the rule could be satisfied by refusing everything.
  skip_without_archive()
  expect_true(
    rhtp_assert_footer_not_allotment(NY_RCHI_POOL, "NY", "SOLICITATION"))
  expect_gt(abs(NY_FOOTER - NY_RCHI_POOL), RHTP_FOOTER_ALLOTMENT_MARGIN)
  expect_equal(NY_RCHI_POOL, 76190022)
})


# -- the controls ------------------------------------------------------------

test_that("DOH publishes awards in a recognisable form -- for OTHER programmes", {
  skip_without_archive()
  got <- ny_assert_press_channel_control()
  expect_gte(got$award_shaped, 8L)
  expect_equal(got$rhtp, 1L)
  # The one RHTP item is an OPPORTUNITY, not an award.
  txt <- ny_html_text("press_index")
  expect_true(grepl("Rural Health Transformation Program Funding Opportunity",
                    txt, fixed = TRUE))
})

test_that("an RHTP item that reads as an AWARD stops the build", {
  skip_without_archive()
  raw <- readBin(ny_path("press_index"), "raw",
                 file.size(ny_path("press_index")))
  txt <- rawToChar(raw)
  faked <- sub("Rural Health Transformation Program Funding Opportunity",
               "Rural Health Transformation Program Award Recipients Announced",
               txt, fixed = TRUE)
  expect_error(ny_assert_press_channel_control(body = charToRaw(faked)),
               "now reads as an AWARD")
})

test_that("losing the control stops the build rather than passing quietly", {
  skip_without_archive()
  expect_error(
    ny_assert_press_channel_control(
      body = as_raw_html("<html><body>Rural Health Transformation</body></html>")),
    "award-shaped headlines")
})

test_that("the Contract Reporter is UNREADABLE and says so (0.4)", {
  skip_without_archive()
  expect_true(ny_assert_scr_unreadable())
  st <- ny_status_table()
  scr <- st[grepl("Contract Reporter", st$channel), ]
  expect_equal(nrow(scr), 1L)
  expect_equal(scr$publishes_roster, "UNKNOWN")
  expect_match(scr$note, "never about New York")
})


# -- the tables --------------------------------------------------------------

test_that("the status table has NO amount column", {
  st <- ny_status_table()
  expect_false("amount" %in% names(st))
  expect_equal(nrow(st), 6L)
  expect_equal(sum(st$stage == "CLOSED_AWARD_DATE_PASSED"), 1L)
})

test_that("no New York award file exists", {
  expect_false(file.exists(here::here("data", "reference",
                                      "ny_year1_awardees.csv")))
})

test_that("New York reads INVESTIGATED_NO_LIST in both rebuilt tables", {
  for (f in c("rcj_state_survey.csv", "state_trigger_queue.csv")) {
    path <- here::here("data", "reference", f)
    skip_if_not(file.exists(path), paste(f, "is not on disk"))
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    col <- if ("extraction_status" %in% names(d)) "extraction_status" else
      "queue_status"
    expect_equal(d[[col]][d$state == "NY"], "INVESTIGATED_NO_LIST")
  }
})

test_that("New York carries no Tier 3 candidate at all", {
  skip_if_not(file.exists(here::here("data", "interim",
                                     "stage2_record_table.rds")))
  d <- ny_disposition()
  expect_equal(d$rcj_rows, 0L)
  expect_equal(d$disposition, "NO_TIER_3_SIGNAL_AT_ALL")
})

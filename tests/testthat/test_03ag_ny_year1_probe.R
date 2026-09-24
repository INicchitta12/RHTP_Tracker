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


# -- the award extraction (session 52) ----------------------------------------

test_that("the RCHI roster is 56 lead rows, 55 names, the pool to the dollar", {
  skip_without_archive()
  r <- ny_assert_roster()
  expect_equal(nrow(r), 56L)
  expect_equal(dplyr::n_distinct(r$awardee), 55L)
  expect_equal(sum(r$amount), 76190022)
  expect_equal(sort(r$amount[r$awardee == "Ellenville Regional Hospital"]),
               c(500000, 3000000))
})

test_that("the roster tripwire fires on a moved figure or an unread lead", {
  skip_without_archive()
  r <- ny_parse_roster()
  r2 <- r; r2$amount[1] <- r2$amount[1] + 1
  expect_error(ny_assert_roster(r2), "sums to")
  r3 <- r; r3$awardee[1] <- "Brand New Rural Hospital"
  expect_error(ny_assert_roster(r3), "nobody has read|distinct names|no longer on")
  expect_error(ny_assert_roster(r[-1, ]), "priced rows")
})

test_that("participation is not receipt: non-hospital leads are Unclear", {
  skip_without_archive()
  aw <- ny_award_rows()
  x <- ny_assert_participation_not_receipt(aw)
  h <- aw[aw$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 35L)
  expect_equal(round(sum(h$amount), 2), 47358790.79)
  expect_equal(round(x$held_out, 2), 28831231.21)
  expect_true(all(aw$flow_type[aw$recipient_type != "HOSPITAL_OR_SYSTEM"] ==
                    "PASS_THROUGH_UNRESOLVED"))
  # THE COUNTERFACTUAL: coding off the eligibility rule would publish the
  # whole pool as hospital money.
  bad <- aw; bad$distributed_to_hospital <- "Yes"
  expect_error(ny_assert_participation_not_receipt(bad), "non-hospital")
  expect_equal(sum(bad$amount), 76190022)
})

test_that("the CMS typing is reproducible from the archived enrolment slice", {
  skip_without_archive()
  expect_true(ny_assert_cms_typing())
  aw <- ny_award_rows()
  br <- aw[aw$basis_type %in% "GENERAL_KNOWLEDGE", ]
  expect_true(all(br$determination_confidence == "LOW"))
  expect_equal(round(sum(br$amount[br$distributed_to_hospital == "Yes"]), 2),
               13961712)
  expect_false(any(aw$determination_confidence == "HIGH"))
  # The two stem traps stay refused as named.
  expect_match(NY_LEAD_TYPES$evidence[NY_LEAD_TYPES$awardee ==
                                        "Mohawk Valley Health System"],
               "MOHAWK VALLEY PSYCHIATRIC CENTER")
  expect_true("Southern Tier Health Care System" %in% NY_LEAD_REFUSED)
})

test_that("an ORG_WEBSITE row whose name is not in CMS is refused", {
  skip_without_archive()
  keep <- NY_LEAD_TYPES
  NY_LEAD_TYPES$basis_type[NY_LEAD_TYPES$awardee == "Adirondack Health"] <<-
    "ORG_WEBSITE"
  on.exit(NY_LEAD_TYPES <<- keep)
  expect_error(ny_assert_cms_typing(), "BRIDGE")
})

test_that("the release ties RCHI to RHTP and postdates the NOA", {
  skip_without_archive()
  expect_true(ny_assert_release_provenance())
  expect_true(ny_assert_roster_linked())
})

test_that("the award file exists and matches the builder", {
  f <- here::here("data", "reference", "ny_year1_awardees.csv")
  expect_true(file.exists(f))
  d <- readr::read_csv(f, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(d), 56L)
  expect_equal(sum(d$amount), 76190022)
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
  expect_equal(sum(st$stage == "AWARDED_ROSTER_PUBLISHED"), 1L)
})

test_that("New York reads EXTRACTED in both rebuilt tables", {
  for (f in c("rcj_state_survey.csv", "state_trigger_queue.csv")) {
    path <- here::here("data", "reference", f)
    skip_if_not(file.exists(path), paste(f, "is not on disk"))
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    col <- if ("extraction_status" %in% names(d)) "extraction_status" else
      "queue_status"
    expect_equal(d[[col]][d$state == "NY"], "EXTRACTED")
  }
})

test_that("New York carries no Tier 3 candidate at all", {
  skip_if_not(file.exists(here::here("data", "interim",
                                     "stage2_record_table.rds")))
  d <- ny_disposition()
  expect_equal(d$rcj_rows, 0L)
  expect_equal(d$disposition, "NO_TIER_3_SIGNAL_AT_ALL")
  expect_silent(rhtp_assert_disposition_prose(d, "NY"))
  # Session 63: New York HAS awarded (session 52), so the zero is a gap in the
  # aggregator; the prose must say so and must not repeat the 08-27 claims.
  expect_false(grepl("has awarded nobody publicly", d$evidence, fixed = TRUE))
  expect_false(grepl("TWELVE states", d$evidence, fixed = TRUE))
  expect_match(d$evidence, "session 52 extracted it")
  expect_match(d$evidence, "76,190,022", fixed = TRUE)
  committed <- readr::read_csv(NY_DISPO_CSV, show_col_types = FALSE)
  expect_equal(committed$evidence, d$evidence)
})

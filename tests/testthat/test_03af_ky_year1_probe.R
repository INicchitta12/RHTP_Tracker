# test_03af_ky_year1_probe.R --------------------------------------------------
# Kentucky: a NEGATIVE whose own award-notification dates have passed.
# Reads committed files off disk only -- no network, no quota.
#
# WEIGHTED TOWARDS DRIVING THE TRIPWIRES, not calling them. Kentucky's finding
# is an ABSENCE, and an absence-checker that cannot fail is worthless: every
# award phrase is fed to every watched surface and required to throw, the
# §0.2 tier rule is driven in both directions, and the two dates are re-derived
# rather than compared to a typed constant.

library(testthat)

source(here::here("R", "03af_ky_year1_probe.R"))

skip_without_archive <- function() {
  if (!ky_have_archive()) skip("the KY evidence archive is not on disk")
}

as_raw_html <- function(txt) charToRaw(enc2utf8(txt))


# -- the negative ------------------------------------------------------------

test_that("Kentucky names no recipient on any watched surface", {
  skip_without_archive()
  expect_true(ky_assert_no_roster())
  for (k in c("funding", "programme", "rch")) {
    expect_length(ky_award_language(ky_html_text(k)), 0L)
  }
})

test_that("the roster tripwire fires on EVERY phrase and EVERY surface", {
  skip_without_archive()
  for (k in c("funding", "programme", "rch")) {
    for (p in KY_AWARD_POSTED) {
      bodies <- list()
      bodies[[k]] <- as_raw_html(paste("<html><body>x", p, "y</body></html>"))
      expect_error(ky_assert_no_roster(bodies = bodies),
                   "award language has appeared",
                   info = paste(k, "/", p))
    }
  }
})

test_that("'Notice of Award' is deliberately NOT a tripwire phrase", {
  # THE SINGLE MOST IMPORTANT LINE IN THE KENTUCKY FILE. The phrase occurs on
  # Kentucky's funding pages already -- as CMS's award to KENTUCKY, attached
  # to every RFA -- so including it would fire on every run and be switched
  # off by whoever met it first.
  skip_without_archive()
  expect_false(any(grepl("notice of award", KY_AWARD_POSTED, fixed = TRUE)))
  n <- ky_assert_noa_phrase_is_not_an_award()
  expect_gte(n, 2L)
  # And it is genuinely present, so this is a live hazard and not a theory.
  expect_true(grepl("Notice of Award", ky_html_text("funding"), fixed = TRUE))
})

test_that("a BARE 'Notice of Award' -- not the CMS attachment -- is refused", {
  skip_without_archive()
  bodies <- list(funding = as_raw_html(
    "<html><body>Notice of Award for the CHW program</body></html>"))
  expect_error(ky_assert_noa_phrase_is_not_an_award(bodies = bodies),
               "is NOT the CMS attachment")
})

test_that("all nine RFAs are still on the page, matched on letters only", {
  skip_without_archive()
  expect_true(ky_assert_nine_rfas())
  # SharePoint splits words: the live page carries "R ural Community Hubs".
  expect_true(grepl("R ural Community Hubs", ky_html_text("funding"),
                    fixed = TRUE))
  expect_equal(ky_letters_only("R ural  Community-Hubs!"),
               "ruralcommunityhubs")
  expect_error(ky_assert_nine_rfas(body = as_raw_html("<html>nothing</html>")),
               "no longer carries")
})


# -- the dates ---------------------------------------------------------------

test_that("both published award-notification dates have passed", {
  skip_without_archive()
  passed <- ky_assert_award_dates_passed()
  expect_length(passed, 2L)
  expect_true(all(passed))
  expect_setequal(KY_AWARD_DATES$date, c("2026-07-10", "2026-08-26"))
})

test_that("the dates are re-derived, not typed -- a past `today` flips them", {
  skip_without_archive()
  expect_false(any(ky_assert_award_dates_passed(today = as.Date("2026-06-01"))))
  expect_message(ky_assert_award_dates_passed(today = as.Date("2026-06-01")),
                 "not yet overdue")
  expect_equal(sum(ky_assert_award_dates_passed(
    today = as.Date("2026-08-01"))), 1L)
})

test_that("losing the RFA's own award sentence stops the build", {
  skip_without_archive()
  expect_error(
    ky_assert_award_dates_passed(
      bodies = list(rfa_cmhc = charToRaw("not a pdf"))),
    "no longer carries its own award-notification sentence|PDF|pdf")
})


# -- §6.2 and the §0.2 tier trap ---------------------------------------------

test_that("Kentucky publishes CMS's own Notice of Award", {
  skip_without_archive()
  expect_true(ky_assert_cms_noa())
  txt <- ky_pdf_text("cms_noa")
  for (w in c("93.798", "Kentucky Cabinet for Health Services",
              "212,905,590.56")) {
    expect_true(grepl(w, txt, fixed = TRUE), info = w)
  }
})

test_that("the NOA is the ORIGINAL award, which corroborates session 36", {
  skip_without_archive()
  expect_true(ky_assert_noa_is_original())
  lines <- trimws(rhtp_pdf_text(ky_path("cms_noa")))
  terms <- grep("Recipient Specific Terms", lines)[1]
  head_block <- lines[seq_len(terms - 1L)]
  expect_true("New" %in% head_block)
  expect_true("12/29/2025" %in% head_block)
  expect_false(any(grepl("Revision (Budget)", head_block, fixed = TRUE)))
  # AND THE FALSE POSITIVE THIS SCOPING AVOIDS IS REAL: the phrase DOES occur
  # later in the document, as boilerplate telling the recipient which
  # amendment type to use in future. A whole-document search reports every
  # NOA, original or not, as a revision.
  expect_true(any(grepl("Revision (Budget)", lines, fixed = TRUE)))
})

test_that("the NOA is refused as any RFA's pool, and accepted as Tier 1", {
  skip_without_archive()
  expect_true(ky_assert_noa_is_not_a_pool())
  expect_error(
    rhtp_assert_footer_not_allotment(KY_NOA_AMOUNT, "KY", "SOLICITATION"),
    "almost certainly Tier 1")
  expect_true(
    rhtp_assert_footer_not_allotment(KY_NOA_AMOUNT, "KY", "STATE_ALLOTMENT"))
})

test_that("the trap is real: the NOA figure dwarfs the RFA it is attached to", {
  skip_without_archive()
  expect_equal(ky_assert_chw_ceiling(), 800000)
  expect_gt(KY_NOA_AMOUNT / 800000, 250)
})


# -- the positive control ----------------------------------------------------

test_that("the CHFS grants channel states absence per agency", {
  skip_without_archive()
  n <- ky_assert_grants_channel_control()
  expect_gte(n, 3L)
})

test_that("losing the control stops the build rather than passing quietly", {
  skip_without_archive()
  txt <- rawToChar(readBin(ky_path("chfs_grants"), "raw",
                           file.size(ky_path("chfs_grants"))))
  gutted <- gsub("No grant opportunities are available at this time", "",
                 txt, fixed = TRUE)
  expect_error(
    ky_assert_grants_channel_control(body = charToRaw(gutted)),
    "no longer states absence per agency")
})


# -- the status table --------------------------------------------------------

test_that("the status table has NO amount column and covers every channel", {
  st <- ky_status_table()
  expect_false("amount" %in% names(st))
  expect_equal(nrow(st), 11L)
  expect_true(all(st$publishes_roster == "No"))
  expect_equal(sum(st$stage == "CLOSED_AWARD_DATE_PASSED"), 2L)
})

test_that("no Kentucky award file exists", {
  expect_false(file.exists(here::here("data", "reference",
                                      "ky_year1_awardees.csv")))
})

test_that("Kentucky reads INVESTIGATED_NO_LIST in both rebuilt tables", {
  for (f in c("rcj_state_survey.csv", "state_trigger_queue.csv")) {
    path <- here::here("data", "reference", f)
    skip_if_not(file.exists(path), paste(f, "is not on disk"))
    d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
    col <- if ("extraction_status" %in% names(d)) "extraction_status" else
      "queue_status"
    expect_equal(d[[col]][d$state == "KY"], "INVESTIGATED_NO_LIST")
  }
})

test_that("Kentucky carries no Tier 3 candidate at all", {
  skip_if_not(file.exists(here::here("data", "interim",
                                     "stage2_record_table.rds")))
  d <- ky_disposition()
  expect_equal(d$rcj_rows, 0L)
  expect_equal(d$disposition, "NO_TIER_3_SIGNAL_AT_ALL")
  expect_match(d$evidence, "never about the state")
})


# -- the digest mechanism ----------------------------------------------------

test_that("SharePoint's per-render tokens move the FILE digest, not content", {
  skip_without_archive()
  raw <- readBin(ky_path("funding"), "raw", file.size(ky_path("funding")))
  txt <- rawToChar(raw)
  # Synthesise the two mechanisms measured live: a fresh CssLink GUID and a
  # fresh __VIEWSTATE. Both are ATTRIBUTE-borne, so the reduction absorbs them.
  rolled <- sub('id="CssLink-[0-9a-f]{32}"', 'id="CssLink-deadbeef"', txt)
  rolled <- sub('name="__VIEWSTATE" id="__VIEWSTATE" value="[^"]{0,40}',
                'name="__VIEWSTATE" id="__VIEWSTATE" value="ZZZZ', rolled)
  expect_false(identical(rolled, txt))
  expect_false(identical(digest::digest(charToRaw(rolled), serialize = FALSE),
                         digest::digest(raw, serialize = FALSE)))
  expect_identical(ky_reduce_html(charToRaw(rolled)), ky_reduce_html(raw))
})

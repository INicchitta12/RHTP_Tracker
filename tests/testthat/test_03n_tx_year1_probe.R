# Texas -- the negative, and the tripwire that keeps it honest.
#
# A negative is only worth committing if something re-checks it. These tests
# are that something: they run offline against the committed archive and they
# fail if Texas stops being at solicitation stage, if the check that says so
# stops measuring anything, or if the RCJ candidate set moves under the
# disposition table.

source(here::here("R", "03n_tx_year1_probe.R"))

test_that("no Rural Texas Strong solicitation publishes an award roster", {
  sol <- tx_solicitation_state()
  expect_equal(nrow(sol), 4L)
  expect_false(any(sol$has_award_roster))
  expect_setequal(sol$procurement_number,
                  c("HHS0017223", "HHS0017212", "HHS0017618", "HHS0017220"))
})

test_that("the positive control fires -- the check is measuring something", {
  # THIS IS THE TEST THAT MAKES THE ONE ABOVE EVIDENCE. HHSC publishes a roster
  # by adding an "Awarded Grant Information" section to the RFA detail page.
  # Without a live example of that in the same archive, "no such section" is
  # indistinguishable from "we are looking for the wrong string", and the
  # negative would be an assumption wearing an assertion's clothes.
  ctrl <- tx_state_programme_state()
  expect_equal(nrow(ctrl), 2L)
  expect_true(all(ctrl$has_award_roster))
  expect_setequal(ctrl$procurement_number, c("HHS0015180", "HHS0015677"))
})

test_that("the tripwire fires when a solicitation gains a roster", {
  # Positive-controlled by reproducing the condition, not by trusting that a
  # branch nobody has run would work.
  sol <- tx_solicitation_state()
  sol$has_award_roster[[2]] <- TRUE
  expect_error(tx_assert_no_award_list(sol = sol), "TRIPWIRE")
  expect_error(tx_assert_no_award_list(sol = sol), sol$procurement_number[[2]])
})

test_that("the tripwire fires when the positive control goes missing", {
  # The branch that stops a site redesign turning every future run silently
  # green: if HHSC renames the section, "no such section on the Rural Texas
  # Strong pages" stops being evidence and starts being a string that no
  # longer matches anything.
  ctrl <- tx_state_programme_state()
  ctrl$has_award_roster <- FALSE
  expect_error(tx_assert_no_award_list(ctrl = ctrl), "positive control failed")
})

test_that("the tripwire fires when the programme page starts naming people", {
  expect_error(
    tx_assert_no_award_list(named = c("Titus Regional Medical Center")),
    "name award"
  )
})

test_that("the programme page names no award recipient", {
  expect_length(tx_programme_named_recipients(), 0L)
})

test_that("the recipient scan never matches across a sentence boundary", {
  # Session 13's rule. An award verb in one sentence must not reach a name in
  # the next.
  split <- paste("Applications will be awarded in September.",
                 "Titus Regional Medical Center is an eligible applicant.")
  expect_length(tx_programme_named_recipients(split), 0L)

  joined <- "The following were awarded to Titus Regional Medical Center."
  expect_equal(tx_programme_named_recipients(joined),
               "Titus Regional Medical Center")
})

test_that("splitting on sentences does not lose a name that contains one", {
  # THE FALSE NEGATIVE THAT MATTERS. Splitting naively on ". " cuts
  # "St. Mary's Hospital" in half and makes a REAL roster entry invisible --
  # which in a tripwire is the failure that costs something, unlike a false
  # alarm that merely makes someone read the page.
  expect_equal(
    tx_programme_named_recipients(
      "The grant was awarded to St. Mary\u2019s Hospital in June."),
    "St. Mary\u2019s Hospital")
  expect_equal(
    tx_programme_named_recipients(
      "Funding was awarded to Mt. Pleasant Medical Center."),
    "Mt. Pleasant Medical Center")
  # And the straight apostrophe, since state pages publish both.
  expect_equal(
    tx_programme_named_recipients("Awarded to St. Joseph's Hospital."),
    "St. Joseph's Hospital")
})

test_that("eligibility language is not read as an award", {
  # §0.3, which is the rule the whole Texas finding turns on. The programme
  # page is full of "Eligibility for award: Rural Hospital Districts" and none
  # of it names a recipient.
  expect_length(
    tx_programme_named_recipients(
      "Eligibility for award: Rural Hospital Districts. Key stakeholders: Public hospitals."),
    0L)
})

test_that("every RCJ Texas Tier 3 candidate is accounted for, and none survives", {
  rt <- rhtp_record_table_live()
  actual <- sum(rt$state == "TX" & rt$award_tier == "SUBAWARD", na.rm = TRUE)
  disp <- tx_build_disposition()

  # Session 62: 68 -> 85 at the 2026-09-24 re-pull (9 withdrawn, 26 new).
  expect_equal(sum(disp$rcj_rows), actual)
  expect_equal(actual, 85L)
  expect_equal(sum(disp$rcj_rows_withdrawn), 9L)
  expect_false(any(disp$disposition == "RHTP_SUBAWARD"))
  # The Rider 88 53 are unchanged; the Mobile Stroke Unit's 3 are state
  # money too.
  expect_equal(sum(disp$rcj_rows[disp$disposition == "NOT_RHTP_STATE_APPROPRIATION"]),
               56L)
  expect_equal(sum(disp$rcj_rows[grepl("HHS00151|HHS00156", disp$group)]), 53L)
  expect_true(all(nzchar(disp$why)))
})

test_that("the 2026-09-24 re-pull is measured group by group", {
  disp <- tx_build_disposition()
  got <- stats::setNames(disp$rcj_rows, disp$group)
  expect_equal(got[names(TX_DISPOSITION_EXPECTED)], TX_DISPOSITION_EXPECTED)

  # ATLIS and IGT emptied because RCJ WITHDREW them, not because a rule moved.
  wd <- stats::setNames(disp$rcj_rows_withdrawn, disp$group)
  expect_equal(unname(wd["ATLIS incentive payments to Medicaid MCOs"]), 5L)
  expect_equal(unname(wd["Suggested Intergovernmental Transfers"]), 4L)
  expect_equal(unname(got["ATLIS incentive payments to Medicaid MCOs"]), 0L)
  expect_match(disp$why[disp$group == "Suggested Intergovernmental Transfers"],
               "0 LIVE ROWS")

  # The four new groups, each with its disqualifying reason.
  amt <- stats::setNames(disp$rcj_amount_sum, disp$group)
  expect_equal(unname(amt["HHS0016568 Texas Nurse-Family Partnership"]),
               133864170)
  expect_equal(unname(amt["HHS0016736 Mobile Stroke Unit ('Sheet1')"]),
               3250000)
  expect_equal(disp$disposition[disp$group ==
                 "HHS0016121 Workplace Violence Against Nurses"],
               "NOT_RHTP_PREDATES_NOA")
  expect_equal(disp$disposition[disp$group ==
                 "HHS0015358 HOPES (Family Support Services)"],
               "NOT_RHTP_PREDATES_NOA")
  expect_match(disp$why[disp$group == "HHS0016568 Texas Nurse-Family Partnership"],
               "TANF")

  # The two predates-NOA findings rest on the COMMITTED RFA index.
  idx <- paste(readLines(file.path(TX_EVIDENCE_DIR,
                                   "2026-08-29_hhsc_rfa_index.html"),
                         warn = FALSE), collapse = " ")
  expect_match(idx, "HHS0015358")
  expect_match(idx, "HHS0016121")
})

test_that("the disposition count is derived, not typed", {
  # If Texas's candidate set moves under the table, the run must FAIL rather
  # than let the table quietly stop covering it.
  expect_error(tx_assert_candidates_accounted(actual = 71L),
               "candidate set has changed")
  expect_silent(tx_assert_candidates_accounted(actual = 85L))

  # A group whose count moves fails even when the TOTAL still agrees.
  disp <- tx_build_disposition()
  disp$rcj_rows[1] <- disp$rcj_rows[1] + 1L
  disp$rcj_rows[2] <- disp$rcj_rows[2] - 1L
  expect_error(tx_assert_candidates_accounted(actual = 85L, disp = disp),
               "in group")

  # A candidate no rule reaches stops the build and names itself.
  cand <- tx_rcj_candidates()
  cand_bad <- cand
  cand_bad$source_doc_title[1] <- "TX - 2026 - A document nobody has read"
  rules_check <- function(c) {
    hit <- vapply(seq_len(nrow(TX_DISPOSITION_RULES)), function(i) {
      r <- TX_DISPOSITION_RULES[i, ]
      grepl(r$doc_pattern, c$source_doc_title, perl = TRUE) &
        (is.na(r$awardee_pattern) |
           grepl(r$awardee_pattern, c$awardee_name_raw, perl = TRUE))
    }, logical(nrow(c)))
    rowSums(hit)
  }
  expect_true(all(rules_check(cand) == 1L))
  expect_equal(sum(rules_check(cand_bad) == 0L), 1L)

  # And a candidate that turns out to BE an RHTP subaward retires this file.
  disp <- tx_build_disposition()
  disp$disposition[[1]] <- "RHTP_SUBAWARD"
  expect_error(
    tx_assert_candidates_accounted(actual = sum(disp$rcj_rows), disp = disp),
    "Build a real")
})

test_that("the status table has no amount column, and cannot acquire one", {
  status <- tx_build_status()
  expect_false("amount" %in% names(status))
  expect_true(all(status$recipients_named == 0L))
  expect_true(all(status$distributed_to_hospital == "Unclear"))
  expect_true(all(status$award_tier == "SOLICITATION"))
  expect_silent(tx_assert_vocabulary())
})

test_that("Texas's allotment is the CMS anchor's, not this file's", {
  expect_silent(tx_assert_allotment_matches_anchor())
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  amt <- intersect(c("fy2026_allotment", "allotment", "amount"),
                   names(anchor))[[1]]
  expect_equal(as.numeric(anchor[[amt]][anchor$state == "TX"]), 281319361)
})

test_that("the archive verifies and the manifest does not list itself", {
  expect_silent(tx_assert_archive_verifies())
  lines  <- readLines(file.path(here::here("data", "evidence", "TX"),
                                "MANIFEST.txt"), warn = FALSE)
  # The LISTING must not contain the manifest; the header prose says out loud
  # that it does not, so a bare grep over the whole file would match the
  # explanation and pass for the wrong reason.
  listed <- stringr::str_match(lines, "([0-9a-f]{64})\\s+(\\S+)$")
  listed <- listed[!is.na(listed[, 1]), 3]
  expect_false("MANIFEST.txt" %in% listed)
  expect_equal(length(listed), 11L)
  expect_equal(nrow(TX_SOURCES), 11L)
})

test_that("no TX award file exists, deliberately", {
  # The assertion that stops a future session assuming Texas was extracted
  # because a Texas CSV is present. tx_year1_status.csv is a status table; it
  # is not tx_year1_awardees.csv and must never be mistaken for one.
  expect_false(file.exists(here::here("data", "reference",
                                      "tx_year1_awardees.csv")))
  expect_false(file.exists(here::here("TX_year1_awardees.xlsx")))
  expect_true(file.exists(here::here("data", "reference",
                                     "tx_year1_status.csv")))
})

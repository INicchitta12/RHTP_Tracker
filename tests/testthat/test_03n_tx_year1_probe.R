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

  expect_equal(sum(disp$rcj_rows), actual)
  expect_equal(actual, 85L)   # 68 on the 2026-08-27 pull
  expect_false(any(disp$disposition == "RHTP_SUBAWARD"))
  # 53 of the 68 were Rider 88, and are still; the 2026-09-24 pull added four
  # more Workplace Violence Against Nurses rows, also a state appropriation.
  expect_equal(sum(disp$rcj_rows[disp$group %in%
                                   c("HHS0015180 Rural Hospital Debt Reduction",
                                     "HHS0015677 Rural Hospital Improvement")]),
               53L)
  expect_equal(sum(disp$rcj_rows[disp$disposition == "NOT_RHTP_STATE_APPROPRIATION"]),
               57L)
  expect_equal(sum(disp$rcj_rows[disp$disposition == "NOT_RHTP_STATE_PROGRAM"]),
               19L)
  expect_equal(sum(disp$rcj_rows[disp$disposition ==
                                   "UNRESOLVED_NO_STATE_SOURCE_LOCATED"]), 3L)
  expect_true(all(nzchar(disp$why)))
  expect_silent(rhtp_assert_disposition_prose(disp, "TX"))
})

test_that("the nine Medicaid rows RCJ withdrew stay as history, at 0 live", {
  disp <- tx_build_disposition()
  med <- disp[disp$disposition == "NOT_RHTP_MEDICAID", ]
  expect_equal(nrow(med), 2L)
  expect_equal(sum(med$rcj_rows), 0L)
  expect_true(all(grepl("withdrawn 5|withdrawn 4", med$why)))
})

test_that("every live candidate lands in exactly one group, or the build stops", {
  cands <- tx_rcj_candidates()
  extra <- cands[1, ]
  extra$source_doc_title <- "TX - 2026 - A document nobody has read"
  extra$awardee_name_clean <- "Somebody"
  expect_error(tx_build_disposition(dplyr::bind_rows(cands, extra)),
               "no disposition")
  committed <- readr::read_csv(TX_DISPOSITION_CSV, show_col_types = FALSE)
  built <- tx_build_disposition()
  expect_equal(committed$rcj_rows, built$rcj_rows)
  expect_equal(committed$why, built$why)
})

test_that("the three new HHSC programmes rest on archived RFAs", {
  disp <- tx_build_disposition()
  new <- disp[grepl("^HHS001(6568|6121|5358)", disp$group), ]
  expect_equal(nrow(new), 3L)
  expect_true(all(file.exists(here::here(new$source_archive_path))))
  man <- readLines(here::here(TX_RECHECK_DIR, "MANIFEST.txt"), warn = FALSE)
  rows <- stringr::str_match(man, "^(\\S+)\\s+(\\d+)\\s+([0-9a-f]{64})$")
  rows <- rows[!is.na(rows[, 1]), , drop = FALSE]
  expect_equal(nrow(rows), 9L)
  for (i in seq_len(nrow(rows))) {
    f <- here::here(TX_RECHECK_DIR, rows[i, 2])
    expect_equal(unname(digest::digest(file = f, algo = "sha256")), rows[i, 4])
  }
})

test_that("the disposition count is derived, not typed", {
  # If Texas's candidate set moves under the table, the run must FAIL rather
  # than let the table quietly stop covering it. That is the difference between
  # a finding and a stale constant that still says 68.
  expect_error(tx_assert_candidates_accounted(actual = 71L),
               "candidate set has changed")
  expect_silent(tx_assert_candidates_accounted(actual = 85L))

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

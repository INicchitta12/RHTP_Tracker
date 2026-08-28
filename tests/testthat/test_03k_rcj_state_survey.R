# test_03k_rcj_state_survey.R ------------------------------------------------
# The 50-state RCJ coverage survey. Reads committed artifacts only -- no
# network, no quota.
#
# WHAT THIS FILE IS DEFENDING. The survey's job is to widen where this project
# looks. Two ways it can fail quietly and both are tested here:
#
#   1. It reports a state as quiet when the records are actually there. The
#      Alaska case: all 159 of its Tier 3 records are FLAGGED, not PASS, and a
#      survey counting only PASS would show Alaska at zero and lose the
#      fourth-largest state in the file.
#   2. Its `rcj_federal_amount_sum` gets read as a dollar figure. §0.1 forbids
#      that, and the column exists only to tell a state holding one $1 record
#      apart from a state holding $160M of them.

library(testthat)

source(here::here("R", "03k_rcj_state_survey.R"))

survey_records <- rhtp_survey_record_table()
survey <- rhtp_rcj_state_survey(survey_records)


test_that("the survey covers all fifty states, once each", {
  expect_equal(nrow(survey), 50L)
  expect_setequal(survey$state, rhtp_cms_states()$state)
  expect_false(any(duplicated(survey$state)))
})


test_that("states holding nothing are kept, not dropped", {
  # Half the point of a coverage map is the blank half. A survey that dropped
  # its zeroes would be a list of findings.
  expect_gt(sum(survey$tier3_candidates == 0), 0L)
})


test_that("FLAGGED Tier 3 records count as candidates -- the Alaska case", {
  # THE SINGLE MOST CONSEQUENTIAL CHOICE IN THE FILE. Alaska's 159 Tier 3
  # records all carry SOURCE_DOCUMENT_UNRESOLVED, which means the /awards row
  # had no sourceDocument.id -- a provenance gap, not junk. Session 12
  # extracted all 161 from the state's own workbook, so they are real.
  ak <- survey[survey$state == "AK", ]
  expect_equal(ak$tier3_pass, 0L)
  expect_gt(ak$tier3_flagged, 100L)
  expect_equal(ak$tier3_candidates, ak$tier3_pass + ak$tier3_flagged)

  # And the survey must therefore rank Alaska near the top, not at zero.
  expect_lte(ak$rank, 5L)
})


test_that("QUARANTINED records are excluded from candidates, and counted", {
  # §6.2's junk filters are what QUARANTINED is for, so those records must not
  # be candidates -- but they must still be visible, or a state whose records
  # were all filtered looks identical to a state that never had any.
  expect_true("tier3_quarantined" %in% names(survey))
  expect_gt(sum(survey$tier3_quarantined), 0L)

  quarantined_states <- survey$state[survey$tier3_quarantined > 0]
  for (st in quarantined_states) {
    row <- survey[survey$state == st, ]
    expect_lte(row$tier3_candidates + row$tier3_quarantined,
               row$rcj_awards_records_raw, label = st)
  }
})


test_that("nothing is lost between data/raw/rcj/ and the record table", {
  # The cross-check that catches a state going quiet because normalization
  # dropped it, rather than because the state awarded nothing. It reads
  # awards.json itself.
  expect_true(all(
    survey$tier3_candidates + survey$tier3_quarantined <=
      survey$rcj_awards_records_raw
  ))
  # And the raw side must actually be populated, or the comparison above is
  # vacuous -- which is exactly how it first passed by accident.
  expect_gt(sum(survey$rcj_awards_records_raw), 1000L)
})


test_that("the survey is ranked by candidate count, descending", {
  expect_equal(survey$rank, seq_len(nrow(survey)))
  expect_false(is.unsorted(rev(survey$tier3_candidates)))
})


test_that("RCJ_ONLY names states with candidates and no CMS release", {
  rcj_only <- survey[survey$survey_status == "RCJ_ONLY", ]
  expect_gt(nrow(rcj_only), 0L)
  expect_true(all(rcj_only$tier3_candidates > 0))
  expect_true(all(rcj_only$in_cms_announcements == "No"))

  # The union must be strictly wider than the CMS list alone, or the survey is
  # not doing the job it was built for.
  expect_gt(sum(survey$tier3_candidates > 0 |
                  survey$in_cms_announcements == "Yes"),
            sum(survey$in_cms_announcements == "Yes"))
})


test_that("an already-extracted state is not flagged for investigation", {
  extracted <- survey[survey$extraction_status == "EXTRACTED", ]
  expect_gt(nrow(extracted), 0L)
  expect_true(all(extracted$investigate == "No"))
})


test_that("Illinois is in the survey and its candidate is noise", {
  # The state that prompted the survey. RCJ holds exactly one Tier 3 candidate
  # for Illinois -- MyOwnDoctor, LLC at $1, a 2025 Medicaid contract that is
  # not RHTP -- while Illinois awarded $50,008,264 to ICAHN. Pinned because it
  # is the evidence for the claim that neither discovery layer is a census,
  # and a reader is entitled to check it.
  il <- survey[survey$state == "IL", ]
  expect_equal(il$tier3_candidates, 1L)
  expect_equal(il$rcj_amount_max, 1)
  expect_equal(il$in_cms_announcements, "No")
})


test_that("the amount column is a signal, not a total", {
  # §0.1. There is deliberately no national total in the file, and the column
  # is named so that summing it reads as wrong.
  expect_true("rcj_federal_amount_sum" %in% names(survey))
  expect_false(any(grepl("^total_|_total$", names(survey))))

  # A state can hold candidates worth almost nothing. That is the distinction
  # the column exists to carry, and it is why a count alone is not enough.
  tiny <- survey[survey$tier3_candidates > 0 &
                   survey$rcj_federal_amount_sum < 100, ]
  expect_gt(nrow(tiny), 0L)
})


test_that("every categorical value is inside §8", {
  expect_true(all(survey$survey_status %in% rhtp_vocabulary("survey_status")))
  expect_true(all(survey$extraction_status %in%
                    rhtp_vocabulary("extraction_status")))
  expect_true(all(survey$in_cms_announcements %in% c("Yes", "No")))
  expect_true(all(survey$investigate %in% c("Yes", "No")))
})


test_that("the committed CSV matches what the builder produces", {
  path <- here::here("data/reference/rcj_state_survey.csv")
  expect_true(file.exists(path))
  on_disk <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(on_disk), 50L)
  expect_equal(on_disk$state, survey$state)
  expect_equal(on_disk$tier3_candidates, survey$tier3_candidates)
})


test_that("the assertions pass on the real data", {
  expect_true(rhtp_survey_assert(survey, survey_records))
})


test_that("the survey refuses a record table whose pull is not on disk", {
  # §0.5: a derived artifact outliving its source. Reproduced by pointing the
  # table at a pull date that does not exist.
  fake <- survey_records
  fake$pull_date <- "1999-01-01"
  fake$last_seen <- "1999-01-01"
  tmp <- tempfile(fileext = ".rds")
  saveRDS(fake, tmp)
  expect_error(rhtp_survey_record_table(tmp), "is not on disk")
})

# test_03q_state_completeness_recheck.R ---------------------------------------
# The seven-state completeness re-check. Reads committed archives only.
#
# WHAT THIS FILE IS DEFENDING.
#
#   1. THE NEGATIVES, AND THEIR CONTROLS. Five of the seven states came back
#      "nothing more". A negative nobody re-checks decays into an assumption
#      (session 13's lesson), and a negative with no positive control was never
#      a finding in the first place (Texas's). So each negative is asserted
#      here TOGETHER WITH the thing that makes it mean something: Georgia's
#      un-awarded strategy, Alabama's byte-identical release, Illinois's
#      conditional sentence, Oregon's twelve bulletins.
#
#   2. THE TWO POSITIVES, AT THEIR EXACT FIGURES. Georgia's 21 hospital award
#      actions at $30,277,580 and Alaska's 24 new awards at $16,862,504 are the
#      numbers a session will act on next. If the parser drifts, this fails
#      before anyone extracts from it.
#
#   3. THAT NOTHING WAS EXTRACTED. This stage reports; it must not have written
#      a state award file. A `ga_...` or `ak_...` CSV changing shape because of
#      this session is exactly what the instruction forbade.

library(testthat)

source(here::here("R", "03q_state_completeness_recheck.R"))
# Alaska's rolling-growth diff moved into R/03h in session 22, where the two
# archived snapshots are. This file still checks it, from there.
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "03h_ak_year1_awardees.R"))

recheck <- recheck_table()


test_that("all seven extracted states are covered, once each", {
  expect_equal(nrow(recheck), 7L)
  expect_equal(sort(recheck$state), sort(c("FL", "GA", "PA", "AL", "AK", "OR", "IL")))
  expect_false(anyDuplicated(recheck$state) > 0L)
})

test_that("every finding is inside the controlled set", {
  # ROSTER_EXTRACTED joined the set in session 22: the state publishes a roster
  # beyond what session 21 had extracted, AND the repository has since extracted
  # it, verified row for row. It is not NO_ADDITIONAL_ROSTER, which would be a
  # false claim about what Georgia and Alaska publish.
  expect_true(all(recheck$finding %in%
    c("NO_ADDITIONAL_ROSTER", "ADDITIONAL_ROSTER_FOUND", "ROSTER_HAS_GROWN",
      "ROSTER_EXTRACTED")))
})

test_that("a negative carries zero on both counters and a positive carries neither", {
  neg <- recheck$finding %in% c("NO_ADDITIONAL_ROSTER", "ROSTER_EXTRACTED")
  expect_true(all(recheck$additional_award_actions[neg] == 0L))
  expect_true(all(recheck$additional_dollars[neg] == 0))
  expect_true(all(recheck$additional_award_actions[!neg] > 0L))
  expect_true(all(recheck$additional_dollars[!neg] > 0))
})


# -- Georgia: the roster nobody read -----------------------------------------

test_that("Georgia's two signed notices name 21 hospital award actions", {
  ga <- recheck_ga()
  expect_equal(nrow(ga$robots), 13L)
  expect_equal(nrow(ga$telepods), 8L)
  expect_equal(sum(ga$robots$amount), 26000000)
  expect_equal(sum(ga$telepods$amount), 4277580)
  expect_equal(ga$actions, 21L)
  expect_equal(ga$dollars, 30277580)
})

test_that("Georgia's signed notice names everyone its intent named", {
  ga <- recheck_ga()
  expect_true(all(ga$robots$amount == 2000000))
  expect_equal(length(unique(ga$robots$application)), 13L)
  expect_equal(length(unique(ga$telepods$application)), 8L)
})

test_that("the committed Georgia file now carries all 21 as named rows", {
  # THIS CHECK HAS FLIPPED, AND FLIPPING IT IS THE POINT OF RUNNING IT AGAIN.
  # Session 21 asserted the two "names not captured" aggregates were still
  # there, because that was the gap it had found. Session 22 closed the gap, so
  # the same question now has the opposite right answer. A re-check that only
  # knows how to find gaps stops being a check the moment one is closed -- and
  # left as it was, this one would have failed on the extraction it asked for.
  ga <- recheck_ga()
  expect_equal(ga$extracted_rows, 21L)
  committed <- readr::read_csv(here::here(RECHECK_COMMITTED[["GA"]]),
                               show_col_types = FALSE, progress = FALSE)
  expect_equal(sum(grepl("names not captured", committed$awardee)), 0L)
  # Joined on DCH's own application number, never on the hospital name: a name
  # is re-typed between the intent and the signed notice ("Coffee Regional
  # Medical Center" / "..., Inc."), and a name-keyed check would report the
  # state as short when nothing is missing.
  notices <- c(ga$robots$application, ga$telepods$application)
  expect_length(setdiff(notices, committed$application_id), 0L)
})

test_that("Georgia's parsed names are recipients, not table furniture", {
  ga <- recheck_ga()
  expect_true(all(grepl("[A-Za-z]{4}", ga$robots$name_hint)))
  expect_false(any(grepl("SUCCESSFUL APPLICANT", ga$robots$name_hint)))
  expect_true(any(grepl("Crisp Regional Hospital", ga$robots$name_hint)))
  expect_true(any(grepl("Colquitt Regional Medical", ga$robots$name_hint)))
})


# -- Alaska: a rolling notice that grew --------------------------------------

test_that("Alaska's growth is folded in, and the check compares to the CSV", {
  # Session 21 diffed the re-check archive against a NAMED evidence file, which
  # was right on the day and wrong the moment session 22 archived a newer
  # snapshot beside it: the check would have gone on reporting a 24-award gap
  # that had been closed. The reference CSV is the thing whose completeness is
  # in question, so that is what it compares against now.
  ak <- recheck_ak()
  expect_equal(ak$committed_rows, 185L)
  expect_equal(ak$live_rows, 185L)
  expect_length(ak$new_ids, 0L)
  expect_equal(ak$committed_total, 181871366, tolerance = 1e-6)
  expect_equal(ak$live_total, 181871366, tolerance = 1e-6)
})

test_that("the growth session 21 found is recorded where it happened", {
  # 161 -> 185, of which 24 new awards ($16,862,504) and one existing award
  # revised upward ($4,306,887). The diff lives in R/03h now, against the
  # committed prior snapshot, because that is where the two documents are.
  growth <- rhtp_ak_growth()
  expect_equal(growth$prior_rows, 161L)
  expect_equal(growth$rows, 185L)
  expect_equal(nrow(growth$added), 24L)
  expect_equal(growth$added_total, 16862504.06, tolerance = 1e-6)
  expect_equal(growth$revised_delta, 4306887.29, tolerance = 1e-6)
})

test_that("Alaska's own document corroborates the growth", {
  ak <- recheck_ak()
  expect_equal(ak$state_stated_projects, ak$live_rows)
})

test_that("the growth was not fully explained by the new awards", {
  # $181,871,366 - $160,701,975 = $21,169,391, of which $16,862,504 is new
  # awards. The remaining $4,306,887 is ONE existing award revised upward, and
  # counting it as a new award would have invented an award Alaska never made.
  growth <- rhtp_ak_growth()
  expect_gt(growth$total - growth$prior_total, growth$added_total)
  expect_equal(growth$total - growth$prior_total,
               growth$added_total + growth$revised_delta)
})


# -- the five negatives, each with its control -------------------------------

test_that("Florida's committed file reconciles with the Governor's own roster", {
  fl <- recheck_fl()
  expect_equal(fl$pdf_rows, fl$csv_rows)
  expect_equal(fl$pdf_total, fl$csv_total)
  expect_equal(fl$pdf_rows, 81L)
  expect_equal(round(fl$pdf_total, 2), 188201256.11)
  # The source's own numbering skips one. Reporting it is what stops a future
  # reader "fixing" the count.
  expect_equal(fl$numbering_gaps, 66L)
})

test_that("Pennsylvania's roster is unchanged and its other pools name nobody", {
  pa <- recheck_pa()
  expect_true(pa$identical_digest)
  expect_equal(pa$live_rows, pa$committed_rows)
  expect_gte(pa$pool_count, 3L)
  expect_gt(pa$pool_dollars, 5e7)
})

test_that("Alabama's release is byte-identical and the site is still solicitation", {
  al <- recheck_al()
  expect_true(al$release_identical)
  expect_true(al$year1_closed)
  expect_gte(al$nofo_count, 8L)
})

test_that("Oregon links twelve bulletins and only one was ever a roster", {
  or <- recheck_or()
  expect_equal(length(or$bulletins), 12L)
  expect_true(or$extracted_bulletin %in% or$bulletins)
  expect_true(or$catalyst_identical)
})

test_that("Illinois's 97 hospitals are ELIGIBILITY, not receipt", {
  il <- recheck_il()
  expect_equal(il$eligible_hospitals, 97L)
  expect_equal(il$pool, 28191393)
  expect_true(il$is_eligibility_not_receipt)
})


# -- this stage extracts nothing ---------------------------------------------

test_that("the re-check writes only its own summary", {
  # The re-check may write RECHECK_CSV and nothing else. Session 21 pinned
  # Georgia at 139 rows and Alaska at 161 to prove it had extracted nothing;
  # session 22 moved both through their OWN extractors (R/03d and R/03h), which
  # is what those pins were protecting. So the invariant is re-stated as what it
  # always was -- the re-check does not touch a state file -- rather than as two
  # row counts that now say the opposite of what they meant.
  expect_true(file.exists(here::here(RECHECK_CSV)))
  code <- readLines(here::here("R", "03q_state_completeness_recheck.R"),
                    warn = FALSE)
  writes <- grep("write_csv|write\\.csv|saveWorkbook|writeBin\\(", code,
                 value = TRUE)
  # writeBin is the evidence archive; the only CSV written is RECHECK_CSV.
  csv_writes <- grep("write_csv|write\\.csv|saveWorkbook", writes, value = TRUE)
  expect_length(csv_writes, 1L)
  expect_true(grepl("RECHECK_CSV", csv_writes))

  ga <- readr::read_csv(here::here("data/reference/ga_great_health_awards.csv"),
                        show_col_types = FALSE, progress = FALSE)
  ak <- readr::read_csv(here::here("data/reference/ak_year1_awardees.csv"),
                        show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(ga), 158L)
  expect_equal(nrow(ak), 185L)
})

test_that("the committed summary CSV matches what the checks produce today", {
  csv <- readr::read_csv(here::here(RECHECK_CSV), show_col_types = FALSE,
                         progress = FALSE)
  expect_equal(csv$state, recheck$state)
  expect_equal(csv$finding, recheck$finding)
  expect_equal(csv$additional_award_actions, recheck$additional_award_actions)
  expect_equal(csv$additional_dollars, recheck$additional_dollars)
})

# test_02c_state_attribution_sweep.R -----------------------------------------
# §0.1 FAILURE MODE 6 -- the record is filed under the wrong state.
# Reads the committed record table off disk only -- no network, no quota.
#
# THE TWO HALVES OF THE FINDING, AND BOTH HAVE TO HOLD.
#   (a) The defect is REAL and is not Wyoming's alone: ten records in five
#       states are another state's, including Utah's own $195.7M allotment
#       carried as a WYOMING row.
#   (b) It has reached NO award file: not one of the ten is Tier 3, which is
#       the only tier an extractor reads.
# If (b) ever stops being true, every state file is in question, so the
# assertion is designed to fail loudly rather than to be re-derived.

library(testthat)

source(here::here("R", "02c_state_attribution_sweep.R"))

flagged <- sweep_build()


test_that("longest-match state detection, so West Virginia is never Virginia", {
  # Session 14 met exactly this in the CMS newsroom: "...Across West Virginia"
  # contains "Virginia", and a first-match reader files WV's release under VA.
  expect_equal(sweep_states_named("Announced across West Virginia today"), "WV")
  expect_equal(sweep_states_named("A grant in Virginia"), "VA")
  expect_equal(sweep_states_named("Both Virginia and West Virginia"), "VA;WV")
  expect_equal(sweep_states_named("New York and North Carolina"), "NC;NY")
  expect_equal(sweep_states_named("no states here at all"), "")
})

test_that("a county is not a state, and the exclusion is generated not typed", {
  expect_equal(sweep_states_named("Clarke and Washington County, Alabama"), "AL")
  expect_equal(sweep_states_named("Wyoming County, Pennsylvania"), "PA")
  expect_equal(sweep_states_named("Washington, D.C."), "")
  # generated from the §7.1 vocabulary, so it cannot go stale
  forms <- sweep_county_forms()
  expect_equal(length(forms), 200L)
  expect_true("Wyoming County" %in% forms)
  expect_true("Utah County" %in% forms)
})

test_that("every flagged record has a hand-read verdict, and none is stale", {
  # sweep_build() itself refuses on either condition; this pins that it does.
  expect_true(all(!is.na(flagged$verdict)))
  expect_setequal(flagged$record_id, SWEEP_VERDICTS$record_id)
  expect_true(all(flagged$verdict %in% names(SWEEP_NOTES)))
})

test_that("(a) TEN records are another state's, in FIVE states", {
  mis <- flagged[flagged$verdict == "MISFILED", ]
  expect_equal(nrow(mis), 10L)
  expect_equal(sort(unique(mis$filed_under)), SWEEP_MISFILED_STATES)
  # WYOMING IS THE LARGEST, AND UTAH IS ITS MIRROR
  expect_equal(sum(mis$filed_under == "WY"), 5L)
  expect_true(all(mis$foreign_states_named[mis$filed_under == "WY"] == "UT"))
  expect_equal(mis$foreign_states_named[mis$filed_under == "UT"], "OK")
  # and the sharpest single row: UTAH'S OWN ALLOTMENT, as a WYOMING row
  utah_award <- mis[stringr::str_detect(
    mis$source_doc_title, "Utah RHTP Cooperative Agreement Award"), ]
  expect_equal(nrow(utah_award), 1L)
  expect_equal(utah_award$filed_under, "WY")
  expect_equal(utah_award$amount_announced, 195700000)
})

test_that("(b) NOT ONE misfiled record is Tier 3", {
  mis <- flagged[flagged$verdict == "MISFILED", ]
  expect_equal(sum(mis$award_tier == "SUBAWARD"), 0L)
  expect_silent(sweep_assert(flagged))
})

test_that("the assertion fails if a misfiled record becomes Tier 3", {
  faked <- flagged
  faked$award_tier[faked$verdict == "MISFILED"][1] <- "SUBAWARD"
  expect_error(sweep_assert(faked), "never reached the tier")
})

test_that("all EIGHT Tier 3 flags are false positives, each legible", {
  t3 <- flagged[flagged$award_tier == "SUBAWARD", ]
  expect_equal(nrow(t3), 8L)
  expect_equal(sort(unique(t3$verdict)),
               c("COUNTY_WITHOUT_THE_WORD", "NAME_CONTAINS_A_STATE_NAME",
                 "STREET_ADDRESS"))
  # the one that matters most: a real ALASKA awardee whose legal name carries
  # its parent system's state, and which IS in ak_year1_awardees.csv
  prov <- t3[t3$verdict == "NAME_CONTAINS_A_STATE_NAME", ]
  expect_equal(nrow(prov), 3L)
  expect_true(all(prov$filed_under == "AK"))
  expect_true(all(stringr::str_detect(prov$awardee_name_clean,
                                      "Providence Health & Services")))
  ak <- readr::read_csv(here::here("data", "reference", "ak_year1_awardees.csv"),
                        show_col_types = FALSE, progress = FALSE)
  expect_true(any(stringr::str_detect(ak$awardee, "Providence Health")))
})

test_that("the sweep is a reading prompt and never a filter", {
  # Nothing downstream consumes it, and it re-states no record. The committed
  # CSV is exactly what sweep_build() returns.
  path <- here::here("data", "reference", "rcj_state_attribution_sweep.csv")
  expect_true(file.exists(path))
  on_disk <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(on_disk), nrow(flagged))
  expect_setequal(on_disk$record_id, flagged$record_id)
})

test_that("Wyoming's own disposition agrees with the sweep", {
  source(here::here("R", "03aj_wy_year1_awardees.R"))
  disp <- wy_rcj_disposition()
  n <- disp$records[disp$disposition_code == "WRONG_STATE_UTAH_FILED_UNDER_WYOMING"]
  expect_equal(n, sum(flagged$verdict == "MISFILED" & flagged$filed_under == "WY"))
})

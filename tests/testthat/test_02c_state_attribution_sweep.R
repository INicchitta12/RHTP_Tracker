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
  hand <- flagged$record_id[flagged$verdict != "MISFILED_SAME_DOCUMENT"]
  expect_setequal(hand, setdiff(SWEEP_VERDICTS$record_id,
                                SWEEP_RETIRED_VERDICTS$record_id))
  expect_true(all(flagged$verdict %in% names(SWEEP_NOTES)))
  # a retired verdict is never also live
  expect_length(intersect(SWEEP_RETIRED_VERDICTS$record_id, flagged$record_id), 0L)
})

test_that("(a) 17 records are another state's, in EIGHT states (2026-09-24 pull)", {
  mis <- flagged[flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ]
  expect_equal(nrow(mis), 17L)
  expect_equal(sort(unique(mis$filed_under)), SWEEP_MISFILED_STATES)
  # RCJ RE-FILED three of Wyoming's five Utah documents, and Utah's own
  # allotment is no longer a Wyoming row
  expect_equal(sum(mis$filed_under == "WY"), 2L)
  expect_true(all(mis$foreign_states_named[mis$filed_under == "WY"] == "UT"))
  expect_false("UT" %in% mis$filed_under)
  expect_equal(nrow(mis[stringr::str_detect(
    mis$source_doc_title, "Utah RHTP Cooperative Agreement Award"), ]), 0L)
  # New Mexico holds six rows of ONE Oregon document
  expect_equal(sum(mis$filed_under == "NM"), 5L)
  expect_true(all(mis$foreign_states_named[mis$filed_under == "NM"] == "OR"))
})

test_that("(b) FIVE misfiled records are Tier 3, pinned by record", {
  mis <- flagged[flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ]
  expect_setequal(mis$record_id[mis$award_tier == "SUBAWARD"],
                  SWEEP_MISFILED_TIER3)
  expect_silent(sweep_assert(flagged))
  # three of the four Wallowa rows name NO state, so only the document list
  # reaches them -- the counterfactual without it
  sib <- flagged[flagged$verdict == "MISFILED_SAME_DOCUMENT", ]
  expect_equal(nrow(sib), 3L)
  expect_true(all(sib$award_tier == "SUBAWARD"))
  expect_true(all(sweep_states_named(paste(sib$awardee_name_clean)) == ""))
})

test_that("the assertion fails if the misfiled Tier 3 set moves either way", {
  faked <- flagged
  faked$award_tier[faked$verdict == "MISFILED" &
                     faked$award_tier != "SUBAWARD"][1] <- "SUBAWARD"
  expect_error(sweep_assert(faked), "misfiled Tier 3 set moved")
  gone <- flagged[flagged$record_id != SWEEP_MISFILED_TIER3[1], ]
  expect_error(sweep_assert(gone), "misfiled Tier 3 set moved")
})

test_that("seven verdicts are RETIRED by the corpus and say why", {
  expect_equal(nrow(SWEEP_RETIRED_VERDICTS), 7L)
  expect_equal(sum(grepl("WITHDRAWN", SWEEP_RETIRED_VERDICTS$retired_because)), 3L)
  expect_equal(sum(grepl("UT", SWEEP_RETIRED_VERDICTS$retired_because)), 4L)
})

test_that("the other Tier 3 flags are false positives, each legible", {
  t3 <- flagged[flagged$award_tier == "SUBAWARD" &
                  !flagged$verdict %in% c("MISFILED", "MISFILED_SAME_DOCUMENT"), ]
  expect_equal(nrow(t3), 5L)
  expect_equal(sort(unique(t3$verdict)),
               c("COUNTY_WITHOUT_THE_WORD", "STREET_ADDRESS"))
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

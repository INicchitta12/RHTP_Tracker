# test_state_union.R ---------------------------------------------------------
# The five extracted states must union. Reads committed CSVs off disk only --
# no network, no quota.
#
# WHY THIS FILE EXISTS. Session 10 found Florida and Georgia had given two
# different answers to one §8 question, and the two states could not be combined
# until that was settled. Nothing caught it until someone tried. This file is
# that attempt, run every time: FL, GA, PA, AL and AK share the leading 19
# columns and every categorical value in them is inside §8, asserted from all
# five sides at once.

library(testthat)

source(here::here("R", "utils_config.R"))

STATE_FILES <- c(
  FL = "data/reference/fl_year1_awardees.csv",
  GA = "data/reference/ga_great_health_awards.csv",
  PA = "data/reference/pa_year1_awardees.csv",
  AL = "data/reference/al_year1_awardees.csv",
  AK = "data/reference/ak_year1_awardees.csv"
)

# Florida's schema is the one the others match on. It is the leading block, not
# the whole file: each state appends its own fields after it (Georgia's phases,
# Alabama's counties, Alaska's App IDs), which is the arrangement Georgia
# established and the reason the union is possible at all.
LEADING_COLUMNS <- c(
  "state", "row_no", "awardee", "amount", "recipient_type",
  "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
  "fiscal_year", "source_document_title", "state_source_url",
  "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
  "rural_designation", "reviewer"
)

state_tables <- lapply(STATE_FILES, function(f) {
  readr::read_csv(here::here(f), show_col_types = FALSE, progress = FALSE)
})


test_that("every state file exists and is non-empty", {
  for (st in names(STATE_FILES)) {
    expect_true(file.exists(here::here(STATE_FILES[[st]])), info = st)
    expect_gt(nrow(state_tables[[st]]), 0L)
  }
})

test_that("all five states carry the leading 19 columns, in the same order", {
  for (st in names(state_tables)) {
    expect_equal(names(state_tables[[st]])[1:19], LEADING_COLUMNS, info = st)
  }
})

test_that("the five states union without a coercion failure", {
  u <- dplyr::bind_rows(lapply(state_tables, function(d) {
    d %>%
      dplyr::select(dplyr::all_of(LEADING_COLUMNS)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  }))
  expect_equal(nrow(u), sum(vapply(state_tables, nrow, integer(1))))
  expect_equal(sort(unique(u$state)), c("AK", "AL", "FL", "GA", "PA"))
})

test_that("no categorical value anywhere in the union is outside §8", {
  # The check that failed for Florida before session 10 back-fitted it. It is
  # cheap and it is the one that stops Stage 5 being handed two vocabularies.
  u <- dplyr::bind_rows(lapply(state_tables, function(d) {
    d %>%
      dplyr::select(dplyr::all_of(LEADING_COLUMNS)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  }))
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed",
                "validation_source_type")) {
    allowed <- if (col == "validation_source_type") {
      rhtp_vocabulary("source_doc_type")
    } else {
      rhtp_vocabulary(col)
    }
    bad <- setdiff(as.character(stats::na.omit(unique(u[[col]]))), allowed)
    expect_equal(bad, character(0), info = col)
  }
})

test_that("§10.2 holds across all five states at once", {
  # A hospital coding that a single state's own assertions would let through
  # because it never compares itself to the others.
  for (st in names(state_tables)) {
    d <- state_tables[[st]]
    yes <- d[d$distributed_to_hospital == "Yes", ]
    expect_true(all(yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                              "HOSPITAL_AFFILIATED_ENTITY")),
                info = st)
  }
})

test_that("every row names a state source and a source document", {
  # §0.4: a determination without a captured, quotable source is not a
  # determination.
  for (st in names(state_tables)) {
    d <- state_tables[[st]]
    expect_true(all(nzchar(d$state_source_url)), info = st)
    expect_true(all(nzchar(d$source_document_title)), info = st)
  }
})

test_that("the three new states each carry an archived source on disk", {
  # PA, AL and AK were extracted this session; each names an archive path and
  # the file has to be there, because §0.5 says an uncommitted archive is gone.
  for (st in c("PA", "AL", "AK")) {
    d <- state_tables[[st]]
    expect_true("source_archive_path" %in% names(d), info = st)
    for (p in unique(d$source_archive_path)) {
      expect_true(file.exists(here::here(p)), info = paste(st, p))
    }
  }
})

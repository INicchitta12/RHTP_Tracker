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
  AK = "data/reference/ak_year1_awardees.csv",
  # South Dakota is TWO files, because South Dakota published two different
  # kinds of document and they must not be added together: 13 executed
  # ADMINISTRATIVE contracts with named vendors, and two ANNOUNCED ROUNDS
  # ($121.5M) whose recipients the state has never published. Session 12's
  # notes said "all six states union", but SD was never in this list and
  # nothing checked -- which is the same gap, one file later, that this
  # test exists to close.
  SD_CONTRACTS    = "data/reference/sd_rht_contracts.csv",
  SD_ANNOUNCEMENTS = "data/reference/sd_year1_awardees.csv",
  # Illinois is one row and it is the awkward one: the first
  # PASS_THROUGH_DESIGNATED award in the project. Its $50,008,264 is
  # distributed_to_hospital = Yes and names NO hospital, which is a
  # combination no other state file contains and which the test below existed
  # in a form that would have quietly mis-stated.
  IL = "data/reference/il_year1_awardees.csv",
  # Oregon is the widest state file in the project: 278 award actions across
  # SEVEN pools published in FOUR documents, at three different levels of
  # certainty. It is in this test for the reason the test exists -- a state that
  # mixes 35 named hospitals, 99 named clinics, 103 competitive grants, two
  # ranges, two unpriced projects and two pools that name nobody is the state
  # most likely to give §8 a different answer somewhere, and nothing would catch
  # it until someone tried to combine the file with the others.
  OR = "data/reference/or_year1_awardees.csv",
  # Kansas is the first state whose awards came out of PDFs rather than a page
  # or a workbook, and the first whose recipient forms are almost entirely
  # unstated by the publisher: 22 of its 46 rows carry §8's standing fallback.
  # That makes it the state most likely to put a value outside §8 into the
  # union without anyone noticing.
  KS = "data/reference/ks_year1_awardees.csv"
)

# Florida's schema is the one the others match on. It is the leading block, not
# the whole file: each state appends its own fields after it (Georgia's phases,
# Alabama's counties, Alaska's App IDs, South Dakota's contract numbers and
# round ids), which is the arrangement Georgia established and the reason the
# union is possible at all.
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

test_that("all ten files carry the leading 19 columns, in the same order", {
  for (st in names(state_tables)) {
    expect_equal(names(state_tables[[st]])[1:19], LEADING_COLUMNS, info = st)
  }
})

test_that("the ten files union without a coercion failure", {
  u <- dplyr::bind_rows(lapply(state_tables, function(d) {
    d %>%
      dplyr::select(dplyr::all_of(LEADING_COLUMNS)) %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  }))
  expect_equal(nrow(u), sum(vapply(state_tables, nrow, integer(1))))
  expect_equal(sort(unique(u$state)),
               c("AK", "AL", "FL", "GA", "IL", "KS", "OR", "PA", "SD"))
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

test_that("§10.2 holds across all states at once", {
  # A hospital coding that a single state's own assertions would let through
  # because it never compares itself to the others.
  #
  # THIS TEST USED TO BE WRONG, AND ILLINOIS IS WHAT PROVED IT. Until session
  # 16 it asserted that EVERY distributed_to_hospital = Yes row carries a
  # hospital recipient_type. That held for six states by accident of what had
  # been extracted -- every one of them awarded money to hospitals DIRECTLY --
  # and it encodes an assumption §10.2 never made. §10.2's
  # PASS_THROUGH_DESIGNATED row is Yes precisely BECAUSE the money reaches
  # hospitals through an intermediary that is not itself a hospital. Illinois'
  # ICAHN row is NONPROFIT_CBO and Yes, and it is correctly coded.
  #
  # So the rule is stated properly now: a Yes row is either a hospital
  # recipient (DIRECT) or a designated pass-through that names its
  # intermediary. Nothing else may be Yes.
  for (st in names(state_tables)) {
    d <- state_tables[[st]]
    yes <- d[d$distributed_to_hospital == "Yes", ]
    if (nrow(yes) == 0) next

    flow <- if ("flow_type" %in% names(yes)) yes$flow_type else rep(NA, nrow(yes))
    direct_ok <- yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                           "HOSPITAL_AFFILIATED_ENTITY")
    pass_ok <- !is.na(flow) & flow == "PASS_THROUGH_DESIGNATED"

    expect_true(all(direct_ok | pass_ok), info = st)

    # A pass-through Yes must say who the intermediary is and must declare
    # itself a pool. Without both, its dollars are indistinguishable from a
    # named hospital's the moment anyone filters on distributed_to_hospital.
    if (any(pass_ok)) {
      pt <- yes[pass_ok, ]
      expect_true(all(nzchar(pt$intermediary_name)), info = st)
      expect_true(all(pt$hospital_attribution == "POOL_UNNAMED_HOSPITALS"),
                  info = st)
    }
  }
})

test_that("named-hospital dollars and pooled dollars never merge", {
  # THE SEPARABILITY INVARIANT, checked across every state at once. This is
  # the check that keeps Illinois' $50,008,264 out of a figure it does not
  # belong in.
  source(here::here("R", "utils_recipient_classification.R"))

  u <- dplyr::bind_rows(lapply(names(state_tables), function(st) {
    d <- state_tables[[st]]
    tibble::tibble(
      state = as.character(d$state),
      amount = suppressWarnings(as.numeric(d$amount)),
      distributed_to_hospital = as.character(d$distributed_to_hospital),
      recipient_type = as.character(d$recipient_type),
      flow_type = if ("flow_type" %in% names(d)) {
        as.character(d$flow_type)
      } else {
        NA_character_
      },
      hospital_attribution = if ("hospital_attribution" %in% names(d)) {
        as.character(d$hospital_attribution)
      } else {
        NA_character_
      }
    )
  }))

  parts <- rhtp_hospital_dollar_partition(u)

  # Both buckets are populated, so the distinction is load-bearing rather
  # than theoretical.
  expect_true("NAMED_HOSPITAL" %in% parts$bucket)
  expect_true("POOL_UNNAMED_HOSPITALS" %in% parts$bucket)

  # Florida carries no flow_type column at all, so its 15 hospital rows are
  # bucketed from recipient_type. An earlier version of the partition dropped
  # them silently; this pins them.
  named <- parts[parts$bucket == "NAMED_HOSPITAL", ]
  expect_true("FL" %in% named$state)
  expect_equal(named$dollars[named$state == "FL"], 49345213)

  # Illinois is the pooled bucket, and it is the whole of it.
  pooled <- parts[parts$bucket == "POOL_UNNAMED_HOSPITALS", ]
  expect_equal(sort(unique(pooled$state)), "IL")
  expect_equal(sum(pooled$dollars), 50008264)

  # And Illinois contributes NOTHING to the named-hospital figure.
  expect_false("IL" %in% named$state)

  # The single combined total is not obtainable. Somebody will try.
  expect_error(rhtp_hospital_total(u), "no single hospital total")
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

test_that("the states extracted from archives each carry one on disk", {
  # PA, AL, AK and both South Dakota files name an archive path, and the file
  # has to be there, because §0.5 says an uncommitted archive is gone.
  for (st in c("PA", "AL", "AK", "SD_CONTRACTS", "SD_ANNOUNCEMENTS")) {
    d <- state_tables[[st]]
    expect_true("source_archive_path" %in% names(d), info = st)
    for (p in unique(d$source_archive_path)) {
      expect_true(file.exists(here::here(p)), info = paste(st, p))
    }
  }
})

# test_utils_disposition_prose.R ----------------------------------------------
# A disposition file's prose may not disagree with its own counts (session 63).
#
# Session 62 re-read every candidate set after the 2026-09-24 pull, and seven
# disposition files passed every assertion while their narrative still
# described the 08-27 figures. The worked case is Arkansas: a row whose code
# was NOT_IN_THE_AGGREGATOR_AT_ALL beside a count of 33. A count column was
# re-derived from the record table; the sentence and the code were not.

source(here::here("R", "utils_config.R"))

ar_like <- function(n, code = "NOT_IN_THE_AGGREGATOR_AT_ALL",
                    evidence = NULL) {
  tibble::tibble(
    state = "AR", group = "RCJ Tier 3 candidates for Arkansas",
    rcj_rows = n, disposition = code,
    evidence = evidence %||% paste0("Arkansas holds ", n,
                                    " Tier 3 candidates."))
}

test_that("the Arkansas counterfactual is refused: an absence code over 33 rows", {
  expect_error(rhtp_assert_disposition_prose(ar_like(33), "AR"),
               "asserts absence")
  expect_silent(rhtp_assert_disposition_prose(ar_like(0), "AR"))
})

test_that("a sentence carrying the old count beside a new count is refused", {
  d <- ar_like(33, code = "RCJ_CARRIES_THE_ROSTER",
               evidence = "Arkansas holds 0 Tier 3 candidates against 38 RCJ records.")
  expect_error(rhtp_assert_disposition_prose(d, "AR"), "prose says")
  d$evidence <- "Arkansas holds ZERO Tier 3 candidates."
  expect_error(rhtp_assert_disposition_prose(d, "AR"), "ZERO Tier 3 candidates")
  d$evidence <- "Arkansas held ZERO Tier 3 candidates on the 2026-08-27 pull and holds 33 Tier 3 candidates now."
  expect_silent(rhtp_assert_disposition_prose(d, "AR"))
})

test_that("the claim reader reads the shapes the committed files use", {
  cl <- rhtp_disposition_count_claims(paste(
    "ALL 11 OF CALIFORNIA'S TIER 3 CANDIDATES.",
    "Kentucky carries NO RCJ Tier 3 candidate.",
    "RCJ's only Idaho Tier 3 candidate is Co-Imagine Health.",
    "Zero SUBAWARD records."))
  expect_equal(cl$value, c(11L, 0L, 0L, 1L))
  expect_false(any(cl$historical))
})

test_that("a sub-count without 'Tier 3' is not read as a claim about the state", {
  # Connecticut's revision double-count: one line item carried as TWO rows
  expect_equal(nrow(rhtp_disposition_count_claims(
    "RCJ carries that ONE line item as TWO candidates at $3,800,000 each.")), 0L)
})

test_that("a historical figure survives only when the text says it is historical", {
  cl <- rhtp_disposition_count_claims(paste(
    "RCJ had 3 Tier 3 candidates. It carried 11 Tier 3 candidates on the",
    "2026-08-27 pull. It holds 4 Tier 3 candidates (was 11)."))
  expect_equal(cl$value, c(3L, 11L, 4L))
  expect_equal(cl$historical, c(TRUE, TRUE, FALSE))
})

test_that("a claim may state the file total as well as the row's own count", {
  d <- tibble::tibble(
    state = "XX", group = c("a", "b"), rows = c(4L, 3L),
    disposition = c("NOT_RHTP_STATE_PROGRAM", "RHTP_BUT_NOT_A_SUBAWARD"),
    why = c("4 of the 7 Tier 3 candidates.", "3 Tier 3 candidates."))
  expect_silent(rhtp_assert_disposition_prose(d, "XX"))
  d$why[2] <- "5 Tier 3 candidates."
  expect_error(rhtp_assert_disposition_prose(d, "XX"), "row 2")
})

test_that("a `records` column is not a Tier 3 count, so that layout must add one", {
  d <- tibble::tibble(state = "TN", group = "All RCJ Tennessee records",
                      records = 98L, disposition = "SOLICITATION_STAGE",
                      note = "x")
  expect_error(rhtp_assert_disposition_prose(d, "TN"), "tier3_candidates")
  d$tier3_candidates <- 1L
  expect_silent(rhtp_assert_disposition_prose(d, "TN"))
})

test_that("EVERY committed disposition file passes the prose rule", {
  files <- Sys.glob(here::here("data", "reference",
                               "*_rcj_candidate_disposition.csv"))
  expect_gt(length(files), 25)
  for (f in files) {
    d <- readr::read_csv(f, show_col_types = FALSE)
    expect_no_error(rhtp_assert_disposition_prose(d, basename(f)),
                    message = basename(f))
  }
})

test_that("every builder that writes a disposition file runs the prose rule first", {
  srcs <- Sys.glob(here::here("R", "*.R"))
  writers <- srcs[vapply(srcs, function(f) any(grepl(
    "rcj_candidate_disposition", readLines(f, warn = FALSE), fixed = TRUE)),
    logical(1))]
  writers <- setdiff(writers, here::here("R", "utils_config.R"))
  expect_gt(length(writers), 20)
  for (f in writers) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_true(grepl("rhtp_assert_disposition_prose(", txt, fixed = TRUE),
                label = paste(basename(f), "calls rhtp_assert_disposition_prose()"))
  }
})

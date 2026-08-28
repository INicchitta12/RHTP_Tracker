# test_03f_pa_year1_awardees.R -----------------------------------------------
# Pennsylvania Year 1 awardees. Reads the committed archive and CSV off disk --
# no network, no quota.
#
# PA is the cleanest recipient-level list this project has: 66 projects, 66
# distinct awardees, and $42,198,309.80 against DHS's own stated $42,198,309.
# These tests pin that reconciliation and the two-document structure that makes
# the coding legitimate under §0.3.

library(testthat)

source(here::here("R", "03f_pa_year1_awardees.R"))

records <- rhtp_pa_records()


test_that("every Pennsylvania assertion passes", {
  expect_true(rhtp_pa_assert(records))
})

test_that("the committed CSV matches a fresh parse of the committed archive", {
  # The archive is the source of record and the CSV is a build output. If they
  # drift, the CSV is stale and every figure derived from it is unverifiable.
  fresh <- rhtp_pa_build()
  expect_equal(nrow(fresh), nrow(records))
  expect_equal(fresh$awardee, records$awardee)
  expect_equal(fresh$amount, records$amount)
  expect_equal(fresh$recipient_type, records$recipient_type)
  expect_equal(fresh$distributed_to_hospital, records$distributed_to_hospital)
})


# -- The reconciliation ------------------------------------------------------

test_that("66 projects, 66 distinct awardees", {
  expect_equal(nrow(records), 66L)
  expect_equal(dplyr::n_distinct(records$awardee), 66L)
})

test_that("the table sums to DHS's own stated tranche total, to the dollar", {
  expect_equal(sum(records$amount), 42198309.80, tolerance = 1e-6)
  expect_lt(abs(sum(records$amount) - PA_STATED_TRANCHE_TOTAL), 1)
})

test_that("no project exceeds the stated $1,000,000 per-project cap", {
  # DHS states "up to $1 million was available per project". A row above it
  # means the parse picked up something that is not a project amount.
  expect_lte(max(records$amount), 1e6)
  expect_gt(min(records$amount), 0)
})

test_that("the tranche is a fifth of Year 1 and nothing is inferred about the rest", {
  # $42.2M of $193.3M. The remaining 78% is not yet awarded; no residual, no
  # implied hospital share.
  expect_lt(sum(records$amount), PA_STATED_YEAR1_AWARD)
  expect_equal(round(100 * sum(records$amount) / PA_STATED_YEAR1_AWARD, 1), 21.8)
})


# -- The §0.3 structure ------------------------------------------------------

test_that("both source documents are archived and both are cited on every row", {
  # The program page alone is an eligibility list (§0.3); the announcement alone
  # names no recipient. Neither supports the coding on its own, so a row missing
  # either citation is not defensible.
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_ANNOUNCEMENT_FILE)))
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE)))
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE)))

  expect_true(all(records$state_source_url == PA_ANNOUNCEMENT_URL))
  expect_true(all(records$recipient_names_source_url == PA_PROJECTS_URL))
})

test_that("the manifest carries a SHA-256 for each archived document", {
  manifest <- readLines(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE))
  shas <- grep("^\\s*sha256\\s*:", manifest, value = TRUE)
  expect_equal(length(shas), 2L)
  expect_true(all(grepl("[0-9a-f]{64}", shas)))
})

test_that("the archived digests still match the archived bytes", {
  manifest <- readLines(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  actual <- vapply(c(PA_ANNOUNCEMENT_FILE, PA_PROJECTS_FILE), function(f) {
    digest::digest(readr::read_file(here::here(PA_EVIDENCE_DIR, f)),
                   algo = "sha256", serialize = FALSE)
  }, character(1))
  expect_setequal(recorded, unname(actual))
})

test_that("these are intents to award, not disbursements", {
  # DHS: "Distribution is pending approval of selected projects." Flattening
  # that into NOTICE_OF_AWARD would lose the distinction a reviewer needs.
  expect_true(all(records$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(records$disbursement_status == "PENDING_APPROVAL"))
})


# -- The vocabulary and the §10.2 coding -------------------------------------

test_that("every categorical column is inside the §8 vocabulary", {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(as.character(stats::na.omit(unique(records[[col]]))),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("only hospital recipients are coded distributed_to_hospital = Yes", {
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_true(all(yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                            "HOSPITAL_AFFILIATED_ENTITY")))
  expect_true(all(yes$flow_type == "DIRECT"))
})

test_that("27 hospital recipients hold $24,149,111", {
  # The figure this state contributes to Deliverable 1. Pinned so a rules change
  # that moves it has to move this test too.
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 27L)
  expect_equal(sum(yes$amount), 24149111)
})

test_that("determination_basis is populated on every row (§7)", {
  expect_true(all(nzchar(records$determination_basis)))
})


# -- The parser refuses rather than guessing ---------------------------------

test_that("a second table on the page fails the parse rather than being guessed at", {
  html <- readr::read_file(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE))
  doubled <- sub("<table", "<table><tr><th>Name</th></tr></table><table",
                 html, fixed = TRUE)
  expect_error(rhtp_pa_parse_projects(doubled), "expected exactly 1 table")
})

test_that("a renamed column fails the parse rather than being mapped by position", {
  html <- readr::read_file(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE))
  renamed <- sub("Project Description", "Description", html, fixed = TRUE)
  expect_error(rhtp_pa_parse_projects(renamed), "Refusing to map columns")
})

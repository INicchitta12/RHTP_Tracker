# test_03f_pa_year1_awardees.R -----------------------------------------------
# Pennsylvania Year 1 awardees. Reads the committed archive and CSV off disk --
# no network, no quota.
#
# PA is the cleanest recipient-level list this project has. Round 1: 66
# projects, 66 distinct awardees, and $42,198,309.80 against DHS's own stated
# $42,198,309. Session 112: the page now carries 178 rows / $116,840,877.67 in
# five funding-opportunity sections; Round 1 is unchanged inside it. These
# tests pin both reconciliations and the two-document structure that makes the
# Round 1 coding legitimate under §0.3.

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

r1 <- records[records$funding_opportunity == PA_ROUND1, ]

test_that("178 rows in five sections; Round 1 is 66 projects, 66 distinct awardees", {
  expect_equal(nrow(records), 178L)
  expect_equal(sum(records$amount), 116840877.67, tolerance = 1e-9)
  expect_setequal(unique(records$funding_opportunity), PA_SECTIONS$funding_opportunity)
  expect_equal(nrow(r1), 66L)
  expect_equal(dplyr::n_distinct(r1$awardee), 66L)
  # one row per recipient per section; Bucktail is in two sections
  expect_false(anyDuplicated(paste(records$awardee, records$funding_opportunity)) > 0)
  expect_equal(sum(records$awardee == "Bucktail Medical Center"), 2L)
})

test_that("Round 1 sums to DHS's own stated tranche total, to the dollar", {
  expect_equal(sum(r1$amount), 42198309.80, tolerance = 1e-6)
  expect_lt(abs(sum(r1$amount) - PA_STATED_TRANCHE_TOTAL), 1)
})

test_that("Round 1 is name for name and cent for cent the 2026-08-28 archive", {
  prior <- rhtp_pa_parse_projects(readr::read_file(
    here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE_PRIOR)))
  expect_identical(prior$awardee, r1$awardee)
  expect_equal(prior$amount, r1$amount)
})

test_that("no Rapid Response project exceeds the stated $1,000,000 cap", {
  # DHS states "up to $1 million was available per project". The Year One
  # Non-Solicitation awards are not under that cap (IUP $30,239,198.33).
  rr <- grepl("^Rapid Response", records$funding_opportunity)
  expect_lte(max(records$amount[rr]), 1e6)
  expect_gt(min(records$amount), 0)
})

test_that("the stale page header is recorded and not adopted", {
  # "Total Awarded to Date: $43,000,000" above $116.8M of rows.
  expect_equal(PA_PAGE_HEADER_TOTAL, 43000000)
  expect_gt(sum(records$amount), PA_PAGE_HEADER_TOTAL)
  expect_false(any(grepl("SOURCE_SUSPECT", records$flag_reason)))
})

test_that("the rows are 60% of Year 1 and nothing is inferred about the rest", {
  expect_lt(sum(records$amount), PA_STATED_YEAR1_AWARD)
  expect_equal(round(100 * sum(records$amount) / PA_STATED_YEAR1_AWARD, 1), 60.4)
})


# -- The §0.3 structure ------------------------------------------------------

test_that("both source documents are archived and both are cited on every Round 1 row", {
  # The program page alone is an eligibility list (§0.3); the announcement alone
  # names no recipient. Neither supports the Round 1 coding on its own. The new
  # sections (session 112) have no readable announcement and cite the page.
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_ANNOUNCEMENT_FILE)))
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE)))
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_PROJECTS_FILE_PRIOR)))
  expect_true(file.exists(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE)))

  expect_true(all(r1$state_source_url == PA_ANNOUNCEMENT_URL))
  nw <- records[records$funding_opportunity != PA_ROUND1, ]
  expect_true(all(nw$state_source_url == PA_PROJECTS_URL))
  expect_true(all(nw$source_archive_path == file.path(PA_EVIDENCE_DIR, PA_PROJECTS_FILE)))
  expect_true(all(records$recipient_names_source_url == PA_PROJECTS_URL))
})

test_that("the manifest carries a SHA-256 for each archived document", {
  manifest <- readLines(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE))
  shas <- grep("^\\s*sha256\\s*:", manifest, value = TRUE)
  expect_equal(length(shas), 3L)
  expect_true(all(grepl("[0-9a-f]{64}", shas)))
})

test_that("the archived digests still match the archived bytes", {
  manifest <- readLines(here::here(PA_EVIDENCE_DIR, PA_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  actual <- vapply(c(PA_ANNOUNCEMENT_FILE, PA_PROJECTS_FILE_PRIOR,
                     PA_PROJECTS_FILE), function(f) {
    digest::digest(readr::read_file(here::here(PA_EVIDENCE_DIR, f)),
                   algo = "sha256", serialize = FALSE)
  }, character(1))
  expect_setequal(recorded, unname(actual))
})

test_that("these are intents to award, not disbursements", {
  # DHS: "Distribution is pending approval of selected projects." Flattening
  # that into NOTICE_OF_AWARD would lose the distinction a reviewer needs. The
  # new sections are "authorized projects" on the page and nothing more.
  expect_true(all(records$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(r1$disbursement_status == "PENDING_APPROVAL"))
  expect_true(all(records$disbursement_status[records$funding_opportunity != PA_ROUND1] == "AUTHORIZED"))
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

test_that("60 hospital rows hold $41,709,702.54 (Round 1: 27 / $24,149,111)", {
  # The figure this state contributes to Deliverable 1. Pinned so a rules change
  # that moves it has to move this test too.
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 60L)
  expect_equal(sum(yes$amount), 41709702.54, tolerance = 1e-9)
  y1 <- r1[r1$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(y1), 27L)
  expect_equal(sum(y1$amount), 24149111)
  low <- yes[yes$determination_confidence == "LOW", ]
  expect_equal(nrow(low), 6L)
  expect_equal(sum(low$amount), 4489728.10, tolerance = 1e-9)
  gk <- yes[yes$basis_type %in% "GENERAL_KNOWLEDGE", ]
  expect_setequal(gk$awardee, c("Sharon Regional Health System", "Penn State Health",
                                "The Guthrie Clinic"))
})

test_that("session 112 typing: universities and the association are not hospitals", {
  no <- function(a) records$distributed_to_hospital[records$awardee == a]
  expect_equal(no("Indiana University of Pennsylvania"), "No")
  expect_equal(no("University of Pittsburgh"), "No")
  expect_equal(no("University of Pennsylvania"), "No")
  expect_equal(no("The Hospital and Health System Association of Pennsylvania"), "No")
  # The Guthrie Clinic is here once; R/03cb writes no PA obligation row for it.
  expect_equal(sum(records$awardee == "The Guthrie Clinic"), 1L)
  expect_equal(records$amount[records$awardee == "The Guthrie Clinic"], 2963576.93)
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

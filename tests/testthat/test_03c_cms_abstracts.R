# test_03c_cms_abstracts.R ---------------------------------------------------
# CMS project-abstract extraction. Read from disk only -- no network calls,
# zero API quota, safe to run on every session start.
#
# The fixture is the abstracts PDF archived at data/raw/cms/2026-08-27/. Its
# SHA-256 is checked against the committed manifest, so the extraction stays
# tied to the bytes CMS served rather than to whatever cms.gov serves today.

library(testthat)

source(here::here("R", "03c_cms_abstracts.R"))

candidates <- rhtp_abstract_candidates()
coverage   <- rhtp_abstract_coverage()

archive  <- rhtp_abstract_archive_path()
manifest <- file.path(dirname(archive), "rht_program_state_provided_abstracts.manifest.txt")


# -- Provenance ------------------------------------------------------------

test_that("the archived abstracts PDF matches its committed manifest", {
  expect_true(file.exists(archive))
  expect_true(file.exists(manifest))

  lines <- readLines(manifest, warn = FALSE)
  stated_sha <- lines %>%
    stringr::str_subset("^sha256\\s*:") %>%
    stringr::str_remove("^sha256\\s*:\\s*") %>%
    stringr::str_trim()

  expect_equal(
    digest::digest(archive, algo = "sha256", file = TRUE),
    stated_sha
  )
})

test_that("the manifest records the source URL the parse claims", {
  lines <- readLines(manifest, warn = FALSE)
  expect_true(any(stringr::str_detect(lines, stringr::fixed(RHTP_ABSTRACT_SOURCE_URL))))
})


# -- §4.1 Dollar figures are unusable, and that is enforced ----------------

test_that("neither reference table carries a dollar figure", {
  expect_silent(rhtp_assert_no_dollar_figures(candidates))
  expect_silent(rhtp_assert_no_dollar_figures(coverage))
})

test_that("the dollar assertion catches every shape the abstracts use", {
  expect_error(
    rhtp_assert_no_dollar_figures(tibble::tibble(x = "$1,000,000,000")),
    "currency-shaped"
  )
  expect_error(
    rhtp_assert_no_dollar_figures(tibble::tibble(x = "$200 million per year")),
    "currency-shaped"
  )
  expect_error(
    # Texas writes it without a sign: "requests $1,000,000,000" appears, but so
    # does the bare grouped form in other states' tables.
    rhtp_assert_no_dollar_figures(tibble::tibble(x = "1,000,000,000 over five years")),
    "currency-shaped"
  )
  expect_error(
    rhtp_assert_no_dollar_figures(tibble::tibble(x = "Workforce - 337 million")),
    "currency-shaped"
  )
  expect_error(
    rhtp_assert_no_dollar_figures(tibble::tibble(state = "VA", amount = 282600000)),
    "numeric column"
  )
})

test_that("ordinary organisation names do not trip the dollar assertion", {
  expect_silent(rhtp_assert_no_dollar_figures(tibble::tibble(
    x = c(
      "Partnerships for Regional Economic Performance regions (8)",
      "UH John A. Burns School of Medicine",
      "Eleanor Slater Hospital (Zambarano campus)",
      "Nine Federally Recognized Tribes of Oregon"
    )
  )))
})


# -- §8 and §0.3 -----------------------------------------------------------

test_that("the whole table validates", {
  expect_no_error(
    suppressMessages(rhtp_assert_abstract_candidates(candidates, coverage))
  )
})

test_that("org_type is drawn from the §8 recipient_type vocabulary", {
  expect_true(all(candidates$org_type %in% rhtp_vocabulary("recipient_type")))
})

test_that("every row is a candidate and none claims confirmation", {
  # §0.3: being named as a partner in a pre-award application is not evidence
  # of receiving money. Delaware is the worked proof -- 5 hospital systems
  # named, 3 confirmed.
  expect_equal(unique(candidates$status), "CANDIDATE_ONLY")
  expect_equal(unique(candidates$source), "CMS_ABSTRACT_PREAWARD")
  expect_true(all(is.na(candidates$confirmed_recipient) | candidates$confirmed_recipient == ""))
  expect_true(all(is.na(candidates$reviewed_by) | candidates$reviewed_by == ""))
})

test_that("a confirmed_recipient value is refused", {
  bad <- candidates
  bad$confirmed_recipient[1] <- "Yes"
  expect_error(rhtp_assert_abstract_candidates(bad, coverage), "confirmed_recipient")
})

test_that("a status other than CANDIDATE_ONLY is refused", {
  bad <- candidates
  bad$status[1] <- "CONFIRMED"
  expect_error(rhtp_assert_abstract_candidates(bad, coverage), "CANDIDATE_ONLY")
})


# -- Coverage --------------------------------------------------------------

test_that("coverage is exactly the 50 CMS states, all extracted", {
  expect_equal(nrow(coverage), 50)
  expect_setequal(coverage$state, rhtp_cms_states()$state)
  expect_false(any(coverage$abstract_status == "NOT YET EXTRACTED"))
})

test_that("n_named is derived from the candidate table, not asserted by hand", {
  counted <- candidates %>% dplyr::count(state, name = "n_actual")

  joined <- coverage %>%
    dplyr::left_join(counted, by = "state") %>%
    dplyr::mutate(n_actual = dplyr::coalesce(n_actual, 0))

  expect_equal(joined$n_named, joined$n_actual)
})

test_that("drift between coverage and the candidate table is caught", {
  bad <- coverage
  bad$n_named[bad$state == "WA"] <- 99
  expect_error(rhtp_assert_abstract_candidates(candidates, bad), "n_named disagrees")
})

test_that("a state left NOT YET EXTRACTED is caught", {
  bad <- coverage
  bad$abstract_status[bad$state == "WY"] <- "NOT YET EXTRACTED"
  expect_error(rhtp_assert_abstract_candidates(candidates, bad), "NOT YET EXTRACTED")
})


# -- The 16 states extracted this session ----------------------------------

test_that("the sixteen previously-truncated states are all present", {
  extracted_here <- c("OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN",
                      "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")

  expect_true(all(extracted_here %in% coverage$state))
  expect_false(any(
    coverage$abstract_status[coverage$state %in% extracted_here] == "NOT YET EXTRACTED"
  ))
})

test_that("the six states that named anyone carry the counts claimed", {
  expected <- c(OK = 5, OR = 1, PA = 3, RI = 7, VA = 8, WA = 9)

  actual <- coverage %>%
    dplyr::filter(state %in% names(expected)) %>%
    dplyr::arrange(state)

  expect_equal(actual$n_named, unname(expected[actual$state]))
  expect_true(all(actual$abstract_status == "NAMED ORGANIZATIONS"))
})

test_that("the ten states that named nobody hold no candidate rows", {
  silent_states <- c("OH", "SC", "SD", "TN", "TX", "UT", "VT", "WV", "WI", "WY")

  expect_equal(sum(candidates$state %in% silent_states), 0)
  expect_true(all(
    coverage$abstract_status[coverage$state %in% silent_states] == "NONE NAMED"
  ))
})

test_that("the yield claim holds: 7 hospital entities named across all 50", {
  # The honest-assessment line on the READ FIRST sheet. Category rows
  # ("Hospitals (unnamed)") are counted separately, because counting a class as
  # a named hospital is the §0.3 error in miniature.
  hospitals <- candidates %>% dplyr::filter(org_type == "HOSPITAL_OR_SYSTEM")

  named <- hospitals %>%
    dplyr::filter(!stringr::str_detect(named_organization, stringr::fixed("(unnamed)")))
  classes <- hospitals %>%
    dplyr::filter(stringr::str_detect(named_organization, stringr::fixed("(unnamed)")))

  expect_equal(nrow(named), 7)
  expect_equal(sort(unique(named$state)), c("DE", "NJ", "RI"))
  expect_equal(sort(unique(classes$state)), c("IL", "NE", "VA"))
})

test_that("no (state, organization) pair is duplicated", {
  dupes <- candidates %>%
    dplyr::count(state, named_organization, name = "n") %>%
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0)
})


# -- The rendered workbook -------------------------------------------------

test_that("the workbook on disk matches the reference CSVs", {
  path <- here::here(RHTP_ABSTRACT_WORKBOOK)
  skip_if_not(file.exists(path), "workbook not built")

  expect_setequal(
    readxl::excel_sheets(path),
    c("READ FIRST", "Named organizations", "Coverage by state")
  )

  wb_named <- readxl::read_excel(path, sheet = "Named organizations")
  wb_cov   <- readxl::read_excel(path, sheet = "Coverage by state")

  expect_equal(nrow(wb_named), nrow(candidates))
  expect_equal(nrow(wb_cov), nrow(coverage))
  expect_equal(wb_named$named_organization, candidates$named_organization)
})

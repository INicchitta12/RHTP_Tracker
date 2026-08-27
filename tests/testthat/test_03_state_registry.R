# test_03_state_registry.R -----------------------------------------------------
# Stage 3 unit tests. Read from disk only -- no network calls, zero API quota,
# safe to run on every session start.
#
# The CMS fixture is the allotment table archived at data/raw/cms/2026-08-27/.
# Parsing it offline is the point: the file every QA assertion in §13
# reconciles against must be reproducible from a committed artefact, not from
# whatever cms.gov happens to serve today.

library(testthat)

source(here::here("R", "03_state_registry.R"))

cms_archive <- rhtp_cms_archive_path("2026-08-27")
parsed <- rhtp_parse_cms_allotments(cms_archive, fetch_date = "2026-08-27")


# -- §7.1 Parsing the CMS allotment table ----------------------------------

test_that("the CMS press release parses to exactly 50 states", {
  expect_equal(nrow(parsed), 50)
  expect_equal(dplyr::n_distinct(parsed$state), 50)
  expect_setequal(parsed$state, rhtp_cms_states()$state)
  expect_false(anyNA(parsed$fy2026_allotment))
})

test_that("the published figures survive the parse exactly", {
  # Spot-checked against the press release. These are the reconciliation
  # anchor: a silent change here corrupts every downstream figure, so they are
  # pinned rather than merely bounded.
  expect_equal(
    parsed$fy2026_allotment[parsed$state == "NJ"], 147250806
  )
  expect_equal(
    parsed$fy2026_allotment[parsed$state == "TX"], 281319361
  )
  expect_equal(
    parsed$fy2026_allotment[parsed$state == "MO"], 216276818
  )
  expect_equal(
    parsed$fy2026_allotment[parsed$state == "AL"], 203404327
  )
  # $10B to the dollar, plus CMS's own $3 of rounding across 50 states.
  expect_equal(sum(parsed$fy2026_allotment), 10000000003)
})

test_that("the header row is dropped and no state is eaten with it", {
  expect_false(any(tolower(parsed$state_name) == "state"))
  expect_true("Alabama" %in% parsed$state_name)
  expect_true("Wyoming" %in% parsed$state_name)
})

test_that("the parse records its own provenance", {
  expect_true(all(stringr::str_detect(parsed$source_url, "^https://www\\.cms\\.gov/")))
  expect_true(all(parsed$source_fetched == "2026-08-27"))
  # The verbatim published string is kept beside the parsed number, so a
  # disputed figure can be checked without re-reading the HTML.
  expect_equal(
    parsed$fy2026_allotment_published[parsed$state == "TX"], "$281,319,361"
  )
})

test_that("a missing archive names the command that creates it", {
  expect_error(
    rhtp_parse_cms_allotments(tempfile(fileext = ".html")),
    "No archived CMS allotment table"
  )
})


# -- §13.17 The assertion ---------------------------------------------------

test_that("the committed table passes §13.17", {
  expect_silent(rhtp_assert_allotments(parsed))
})

test_that("a short table fails rather than reporting a coverage gap", {
  # §7.1 is explicit: when this fails against RCJ-derived data that is the
  # assertion working. Here the anchor ITSELF is short, which is a broken
  # anchor, so it must stop the build.
  expect_error(
    rhtp_assert_allotments(parsed %>% dplyr::slice(-1)),
    "expected exactly 50 rows"
  )
})

test_that("a missing amount fails", {
  broken <- parsed
  broken$fy2026_allotment[3] <- NA_real_
  expect_error(rhtp_assert_allotments(broken), "have no amount")
})

test_that("a state code outside the CMS 50 fails", {
  broken <- parsed
  broken$state[1] <- "US"
  expect_error(rhtp_assert_allotments(broken), "not in cms_states.csv")
})

test_that("a duplicated state fails before the total is even checked", {
  broken <- parsed
  broken$state[2] <- broken$state[1]
  expect_error(rhtp_assert_allotments(broken), "not unique")
})

test_that("a transcription error large enough to matter fails the total", {
  # One state's figure off by a factor of ten -- the shape of the hand-entry
  # error §7.1 forbids transcription to avoid.
  broken <- parsed
  broken$fy2026_allotment[broken$state == "TX"] <- 2813193610
  expect_error(rhtp_assert_allotments(broken), "total is")
})

test_that("bounds that drift away from the published range fail", {
  # Each perturbation is $10M: enough to break the 2% bound on that state,
  # small enough to stay inside the 1% ($100M) tolerance on the total. So it
  # is genuinely the bound check firing, not the total check catching it
  # first -- which is what the earlier factor-of-ten test covers.
  low <- parsed
  low$fy2026_allotment[low$state == "NJ"] <-
    low$fy2026_allotment[low$state == "NJ"] - 10000000
  expect_error(rhtp_assert_allotments(low), "minimum is")

  high <- parsed
  high$fy2026_allotment[high$state == "TX"] <-
    high$fy2026_allotment[high$state == "TX"] + 10000000
  expect_error(rhtp_assert_allotments(high), "maximum is")
})

test_that("a missing column fails with the column named", {
  expect_error(
    rhtp_assert_allotments(parsed %>% dplyr::select(-fy2026_allotment)),
    "missing column"
  )
})


# -- The committed anchor ---------------------------------------------------

test_that("the committed CSV round-trips and matches the parse", {
  skip_if_not(file.exists(rhtp_path("cms_allotments")),
              "cms_fy2026_allotments.csv not built yet")

  loaded <- rhtp_load_cms_allotments()

  expect_equal(nrow(loaded), 50)
  expect_equal(
    loaded %>% dplyr::arrange(state) %>% dplyr::pull(fy2026_allotment),
    parsed %>% dplyr::arrange(state) %>% dplyr::pull(fy2026_allotment)
  )
})


# -- §7.2 The verification worksheet ---------------------------------------

fixture_sources <- tibble::tibble(
  state = c("GA", "GA", "VA", "VA", "TX"),
  source_doc_id = c("d1", NA, "d2", NA, NA),
  state_source_url = c(
    "https://dch.georgia.gov/rhtp/awards",
    "https://dch.georgia.gov/news",
    "https://vhhafoundation.org/awards",
    "https://dmas.virginia.gov/rhtp",
    "https://hhs.texas.gov/rhtp"
  ),
  url_kind = c("document_source_url", "site_url", "document_source_url",
               "site_url", "site_url"),
  occurred_at = as.Date(c("2026-08-01", "2026-08-10", "2026-07-15",
                          "2026-08-20", "2026-06-01"))
)

fixture_records <- tibble::tibble(
  state = c("GA", "VA"),
  state_source_url = c("https://dch.georgia.gov/rhtp/awards",
                       "https://vhhafoundation.org/awards"),
  source_doc_title = c("GA - 2026 - Notice of Intent to Award",
                       "VA - 2026 - RHT IN VIRGINIA")
)

worksheet <- rhtp_registry_worksheet(fixture_sources, fixture_records)

test_that("the worksheet covers all 50 states, candidates or not", {
  expect_setequal(unique(worksheet$state), rhtp_cms_states()$state)
  # Three states have candidates; the other 47 must still each get a row.
  expect_equal(sum(worksheet$verification_status == "NO_CANDIDATE"), 47)
})

test_that("one row per state and host, ranked by how often it appears", {
  ga <- worksheet %>% dplyr::filter(state == "GA")
  expect_equal(nrow(ga), 1)
  expect_equal(ga$url_host, "https://dch.georgia.gov")
  expect_equal(ga$n_activity_references, 2)

  va <- worksheet %>% dplyr::filter(state == "VA") %>%
    dplyr::arrange(candidate_rank)
  expect_equal(nrow(va), 2)
  expect_setequal(va$url_host,
                  c("https://vhhafoundation.org", "https://dmas.virginia.gov"))
})

test_that("every verification column is emitted empty (§7.2)", {
  # The whole point of the worksheet is that a PERSON fills these in after
  # loading the URL. Pre-filling award_posting_url from the candidate host
  # would manufacture the unverified registry §7.2 exists to prevent.
  for (col in RHTP_WORKSHEET_VERIFY_COLUMNS) {
    expect_true(col %in% names(worksheet), info = col)
    expect_true(all(is.na(worksheet[[col]])), info = col)
  }
  expect_false(any(worksheet$verification_status == "VERIFIED"))
})

test_that("a sample source title is carried where one is resolvable", {
  va_foundation <- worksheet %>%
    dplyr::filter(state == "VA", url_host == "https://vhhafoundation.org")
  expect_equal(va_foundation$sample_source_title, "VA - 2026 - RHT IN VIRGINIA")
})

test_that("a state with no /activity host is told to compile by hand", {
  gap <- worksheet %>% dplyr::filter(state == "WY")
  expect_equal(nrow(gap), 1)
  expect_true(is.na(gap$url_host))
  expect_equal(gap$n_activity_references, 0)
  expect_match(gap$instruction, "by hand")
})

test_that("the worksheet runs with no record table at all", {
  bare <- rhtp_registry_worksheet(fixture_sources, records = NULL)
  expect_equal(nrow(bare), nrow(worksheet))
  expect_true(all(is.na(bare$sample_source_title)))
})

test_that("the committed worksheet is the 151-candidate seed, unverified", {
  path <- rhtp_path("state_source_registry_worksheet")
  skip_if_not(file.exists(path), "worksheet not built yet")

  committed <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  expect_setequal(unique(committed$state), rhtp_cms_states()$state)
  expect_true(all(is.na(committed$award_posting_url)))
  expect_true(all(is.na(committed$last_verified)))
})


# -- §7.3 Validating the hand-verified registry ----------------------------

write_registry <- function(tbl) {
  path <- tempfile(fileext = ".csv")
  readr::write_csv(tbl, path)
  path
}

full_registry <- function() {
  tibble::tibble(
    state = rhtp_cms_states()$state,
    lead_agency = "Department of Health",
    program_page_url = "https://example.gov/rhtp",
    award_posting_url = "https://example.gov/rhtp/awards",
    pass_through_admin = NA_character_,
    pass_through_admin_url = NA_character_,
    last_verified = "2026-09-01"
  )
}

test_that("a complete registry validates clean", {
  result <- rhtp_validate_state_registry(write_registry(full_registry()))
  expect_true(result$status$complete)
  expect_equal(result$status$n_states_verified, 50)
})

test_that("an unverified state is a reported gap, never a silent skip (§13.12)", {
  partial <- full_registry()
  partial$last_verified[partial$state == "FL"] <- NA_character_
  partial$award_posting_url[partial$state == "WY"] <- NA_character_

  expect_warning(
    result <- rhtp_validate_state_registry(write_registry(partial)),
    "FL WY"
  )
  expect_false(result$status$complete)
  expect_setequal(result$unverified_states, c("FL", "WY"))
})

test_that("require_complete turns the gap into a hard stop for Stage 4", {
  partial <- full_registry()
  partial$award_posting_url[partial$state == "FL"] <- NA_character_

  expect_error(
    rhtp_validate_state_registry(write_registry(partial),
                                 require_complete = TRUE),
    "cannot validate"
  )
})

test_that("a missing §7.3 column fails with the column named", {
  expect_error(
    rhtp_validate_state_registry(
      write_registry(full_registry() %>% dplyr::select(-award_posting_url))
    ),
    "missing §7.3 column"
  )
})

test_that("a junk state code in the registry fails (§13.14)", {
  broken <- full_registry()
  broken$state[1] <- "RC"
  expect_error(
    rhtp_validate_state_registry(write_registry(broken)),
    "not in the 50-row CMS list"
  )
})

test_that("an absent registry names how it is built", {
  expect_error(
    rhtp_validate_state_registry(file.path(tempdir(), "nope.csv")),
    "compiled OFF-SESSION"
  )
})

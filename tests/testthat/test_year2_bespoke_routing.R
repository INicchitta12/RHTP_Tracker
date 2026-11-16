# test_year2_bespoke_routing.R -- session 117, Task 1.
#
# Every state probe's OWN phrase check goes through the shared Year 2 rule:
# a Year 2 sentence, headline, list or report logs YEAR2 (held, not raised)
# and never an ordinary TRIPWIRE. Fixtures for the three busiest probes (TX,
# OK, MS) and for the central check in rhtp_probe_run(), each with a Year 1
# control that must still trip.

source(here::here("R", "utils_config.R"))

run_probe <- function(state, expr) {
  log <- tempfile(fileext = ".csv")
  withr::local_envvar(RHTP_PROBE_ORIGIN = "interactive")
  err <- tryCatch({ suppressMessages(rhtp_probe_run(state, expr, path = log)); NULL },
                  error = function(e) conditionMessage(e))
  rows <- if (file.exists(log)) readr::read_csv(log, show_col_types = FALSE) else NULL
  list(err = err, verdicts = rows$verdict, notes = rows$note)
}

test_that("the central check: a bespoke trip quoting only Year 2 strings is YEAR2, a Year 1 one trips", {
  y2 <- run_probe("ZZ", stop("[ZZ] 'home' HAS 1 NEW SENTENCE(S) OF THE KIND THIS WATCH EXISTS FOR: ",
                             "\"Year 2 awards were made to 12 rural hospitals.\". Read it.", call. = FALSE))
  expect_null(y2$err)
  expect_true("YEAR2" %in% y2$verdicts)
  expect_false("TRIPWIRE" %in% y2$verdicts)
  y1 <- run_probe("ZZ", stop("[ZZ] 'home' HAS 1 NEW SENTENCE(S) OF THE KIND THIS WATCH EXISTS FOR: ",
                             "\"Awards were made to 12 rural hospitals.\". Read it.", call. = FALSE))
  expect_match(y1$err, "12 rural hospitals")
  expect_true("TRIPWIRE" %in% y1$verdicts)
  # A returned findings vector is screened the same way, one row each.
  f <- run_probe("ZZ", list(sources = list(), findings = c(
    "[ZZ] NEW REPORT: \"RHTP Year 2 Quarterly Report\". Read it.",
    "[ZZ] NEW REPORT: \"RHTP Quarterly Report Q4\". Read it.")))
  expect_match(f$err, "Q4")
  expect_equal(sort(f$verdicts[f$verdicts %in% c("YEAR2", "TRIPWIRE")]), c("TRIPWIRE", "YEAR2"))
  # Mixed quotes stay a TRIPWIRE; a name tripwire and an access error are untouched.
  expect_false(rhtp_year2_only_message("[ZZ] \"Year 2 awards\" and \"awards to 3 hospitals\". THAT IS THE SIGNAL"))
  expect_false(rhtp_year2_only_message("[ZZ] 'p' NAMES 1 ORGANISATION(S) THE ARCHIVED COPY DOES NOT: \"Year 2 Hub\""))
  expect_false(rhtp_year2_only_message("[ZZ] HTTP 403 for \"Year 2 page\""))
})

test_that("TX: a Year 2 Rural Texas Strong list is held; a new Year 1 list and a new 'Updated' date trip", {
  source(here::here("R", "03ce_tx_rts_awardees.R"))
  y2_body <- paste0('<a href="/sites/default/files/documents/rural-hlth-prgm/year-2-award-recipients.xlsx">',
                    'Year 2 List of Award Recipients</a> (.xlsx) (Updated 12/01/2026)')
  y2 <- run_probe("TX", { x <- tx_rts_live_finding(y2_body); list(sources = list(), findings = x$finding) })
  expect_true("YEAR2" %in% y2$verdicts)
  expect_false(any(grepl("year-2-award-recipients", y2$notes[y2$verdicts == "TRIPWIRE"])))
  y1_body <- '<a href="/sites/default/files/documents/rural-hlth-prgm/12-01-2026-list-award-recipients.xlsx">List</a>'
  y1 <- run_probe("TX", { x <- tx_rts_live_finding(y1_body); list(sources = list(), findings = x$finding) })
  expect_match(y1$err, "RURAL TEXAS STRONG LIST")
  # The stable file name HHSC moved to on 11-13 is matched, and a new label trips.
  same <- paste0('<a href="', TRT_LIST_PATH, '">List of Award Recipients</a> (.xlsx) (Updated 11/20/2026)')
  if (!is.na(TRT_LIST_UPDATED)) expect_match(tx_rts_live_finding(same)$finding, "Updated 11/20/2026")
  ok <- paste0('<a href="', TRT_LIST_PATH, '">List of Award Recipients</a> (.xlsx) (Updated ',
               dplyr::coalesce(TRT_LIST_UPDATED, "11/13/2026"), ')')
  expect_null(tx_rts_live_finding(ok, updated = dplyr::coalesce(TRT_LIST_UPDATED, "11/13/2026"))$finding)
})

test_that("OK: a Year 2 legislative report and a Year 2 dropdown programme are held", {
  source(here::here("R", "03t_ok_year1_awardees.R"))
  f <- here::here(OK_LEG_PAGE_FILE)
  page <- rawToChar(readBin(f, "raw", file.size(f)))
  add <- function(name) charToRaw(sub("10-16-26%20RHTP%20Legislative%20Quarterly%20Report_Q3.pdf",
    paste0("10-16-26%20RHTP%20Legislative%20Quarterly%20Report_Q3.pdf\"></a><a href=\"/content/dam/ok/en/rhtp/documents/legislative-reports/",
           name), page, fixed = TRUE))
  y2 <- run_probe("OK", ok_leg_findings(fetch = function(url) add("01-15-27%20RHTP%20Year%202%20Legislative%20Quarterly%20Report_Q1.pdf")))
  expect_null(y2$err)
  expect_true("YEAR2" %in% y2$verdicts)
  y1 <- run_probe("OK", ok_leg_findings(fetch = function(url) add("01-15-27%20RHTP%20Legislative%20Quarterly%20Report_Q4.pdf")))
  expect_match(y1$err, "Report_Q4.pdf", fixed = TRUE)
  expect_true("TRIPWIRE" %in% y1$verdicts)
})

test_that("MS: a Year 2 headline on the Governor's newsroom is held; a Year 1 headline trips", {
  source(here::here("R", "03ak_ms_year1_awardees.R"))
  html <- function(h) charToRaw(paste0("<html><body><a href='/a'>", h, "</a></body></html>"))
  y2 <- run_probe("MS", ms_assert_no_new_rhtp_headline(
    body = html("Governor Reeves Announces Year 2 Rural Health Transformation Program Awards")))
  expect_null(y2$err)
  expect_true("YEAR2" %in% y2$verdicts)
  y1 <- run_probe("MS", ms_assert_no_new_rhtp_headline(
    body = html("Governor Reeves Announces 40 Rural Health Transformation Program Awards")))
  expect_match(y1$err, "NEW RHTP HEADLINE")
})

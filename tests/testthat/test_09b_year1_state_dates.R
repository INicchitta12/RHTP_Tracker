# test_09b_year1_state_dates.R ------------------------------------------------
# SESSION 121, OWNER RULING: WHICH DATE DECIDES YEAR 1. A row is Year 1 if a
# STATE SOURCE shows the award or contract was executed or started on or before
# 2026-10-30, even when its FSRS filing is dated later. The FSRS action date
# decides only where no state source gives a date (CLAUDE.md §7).

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "09b_fsrs_award_source.R"))

fixture_raw <- function() {
  tibble::tibble(
    st = c("SD", "SD", "TN", "TN"),
    prime_award_fain = "X", prime_awardee_name = "STATE",
    fsrs_id = c("a", "b", "c", "d"), report_ym = "2026-11",
    last_modified = "2026-11-10",
    subaward_number = c("27RHT00103", "27RHT00112", "341324", "341324"),
    action_date = c("2026-11-03", "2026-11-02", "2026-08-01", "2026-10-31"),
    amount = c(2338186, 12915000, 31491.02, 83975.27),
    uei = c("U1", "U2", "U3", "U3"), name = "N", dba = "", parent = "",
    address = "", city = "", sub_state = "", zip = "", business_types = "",
    description = c("EQUIPMENT", "EHR", "HEALTHY ACTIVE RURAL TENNESSEE ONE", "HEALTHY ACTIVE RURAL TENNESSEE TWO"),
    permalink = "")
}
fixture_dates <- function(date = "2026-02-20", sub = "27RHT00103", uei = "U1") {
  tibble::tibble(state = "SD", subaward_number = sub, uei = uei, state_source_date = date,
                 date_kind = "CONTRACT_BEGIN")
}

test_that("a state source date on or before 10-30 makes a later FSRS filing Year 1", {
  rec <- fsrs_dispose(fixture_raw(), fixture_dates())
  a <- rec[rec$fsrs_id == "a", ]
  expect_equal(a$record_status, "CURRENT")
  expect_equal(a$budget_period, 1L)
  expect_equal(a$year1_date, "2026-02-20")
  expect_match(a$year1_date_basis, "^STATE_SOURCE_CONTRACT_BEGIN 2026-02-20$")
})

test_that("without a state source date the FSRS action date decides, and it holds", {
  rec <- fsrs_dispose(fixture_raw(), fixture_dates())
  b <- rec[rec$fsrs_id == "b", ]
  expect_equal(b$record_status, "BUDGET_PERIOD_2_HELD")
  expect_equal(b$budget_period, 2L)
  expect_equal(b$year1_date_basis, "FSRS_ACTION_DATE")
  d <- rec[rec$fsrs_id == "d", ]
  expect_equal(d$record_status, "BUDGET_PERIOD_2_HELD")
})

test_that("a state date is used only where the FSRS date alone would hold the record", {
  td <- tibble::tibble(state = "TN", subaward_number = "341324", uei = "U3",
                       state_source_date = "2026-09-03", date_kind = "AWARD_ANNOUNCED")
  rec <- fsrs_dispose(fixture_raw(), td)
  expect_equal(rec$year1_date_basis[rec$fsrs_id == "c"], "FSRS_ACTION_DATE")
  expect_equal(rec$year1_date[rec$fsrs_id == "c"], "2026-08-01")
  expect_equal(rec$record_status[rec$fsrs_id == "d"], "CURRENT")
  expect_match(rec$year1_date_basis[rec$fsrs_id == "d"], "AWARD_ANNOUNCED 2026-09-03")
})

test_that("an entry naming no FSRS record is refused", {
  expect_error(fsrs_dispose(fixture_raw(), fixture_dates(sub = "27RHT99999")), "naming no FSRS record")
})

test_that("the config refuses a date after 10-30, an unknown kind and a missing archive", {
  base <- readr::read_csv(here::here(FSRS_STATE_DATES), col_types = readr::cols(.default = "c"))
  tmp <- tempfile(fileext = ".csv")
  late <- base[1, ]; late$state_source_date <- "2026-11-02"
  readr::write_csv(late, tmp)
  expect_error(fsrs_state_dates(tmp), "after 2026-10-30")
  kind <- base[1, ]; kind$date_kind <- "SELECTED"
  readr::write_csv(kind, tmp)
  expect_error(fsrs_state_dates(tmp), "date_kind")
  arch <- base[1, ]; arch$source_archive <- "data/evidence/nowhere.html"
  readr::write_csv(arch, tmp)
  expect_error(fsrs_state_dates(tmp), "not on disk")
})

test_that("the committed config: 82 subawards (TN HART 45, SD 37), none held without it", {
  sd <- fsrs_state_dates()
  # session 125 (owner ruling b): + SD 27RHT00126-142 (15), on the live register's begin dates
  expect_equal(nrow(sd), 82L)
  expect_equal(as.integer(table(sd$state)[c("SD", "TN")]), c(37L, 45L))
  expect_true(all(sd$state_source_date <= "2026-10-30"))
  expect_setequal(unique(sd$date_kind[sd$state == "TN"]), "AWARD_ANNOUNCED")
  # owner ruling: the 19 SD subawards whose register begin date is 2026-02-20
  # rest on SD's completion statement (OBLIGATED_BY_DEADLINE, 10-30), Monument
  # Health among them; the other 3 on their register begin dates
  expect_equal(sum(sd$date_kind == "OBLIGATED_BY_DEADLINE"), 19L)
  expect_equal(sum(sd$state == "SD" & sd$date_kind == "CONTRACT_BEGIN"), 18L)
  expect_true(all(grepl("committed every dollar", sd$source_quote[sd$date_kind == "OBLIGATED_BY_DEADLINE"])))
  expect_true("27RHT00112" %in% sd$subaward_number)
  # what stays held: NM's four hubs
  # ("selected" is not executed or started), IL Morris (no state date), and
  # TN's twelve non-HART or unmatched filings
  rec <- fsrs_dispose()
  held <- rec[rec$record_status == "BUDGET_PERIOD_2_HELD", ]
  # Session 124: + 19 from the 11-25 archive: SD 27RHT00126-142 (15; not on the
  # archived register, so no state date reaches them) and IN 4 (11-02..11-19).
  # Session 125: SD's 15 are on the 11-25 register with begin dates on or before
  # 10-30 and move to Year 1 (owner ruling b); none is held.
  expect_equal(nrow(held), 21L)
  expect_equal(as.integer(table(held$st)[c("IL", "IN", "NM", "TN")]), c(1L, 4L, 4L, 12L))
  expect_false(any(held$st == "SD"))
  expect_false("27RHT00112" %in% held$subaward_number)
  moved <- rec[rec$year1_date_basis != "FSRS_ACTION_DATE", ]
  expect_equal(nrow(moved), 82L)
  expect_true(all(moved$action_date > "2026-10-30"))
  expect_true(all(moved$budget_period == 1L))
})

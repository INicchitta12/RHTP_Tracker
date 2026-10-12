# test_00c_cms_obligation_report.R -------------------------------------------
# CMS's RHTP Obligated Funds Report (session 97): the parse reproduces the
# committed tables, the source defects stay logged rather than fixed, and no
# obligation figure reaches an award file or a hospital bucket.

source(here::here("R", "00c_cms_obligation_report.R"))
source(here::here("R", "00d_cms_obligation_analysis.R"))

ref <- function(f) readr::read_csv(here::here("data", "reference", f),
                                   show_col_types = FALSE, progress = FALSE)

test_that("the archive is the public medicaid.gov copy, byte for byte", {
  expect_silent(obl_assert_archive())
  man <- readLines(here::here(OBL_DIR, "RHTP-Obligated-Funds-10082026.pdf.manifest.txt"))
  expect_true(any(grepl(OBL_SHA256, man, fixed = TRUE)))
  expect_true(any(grepl("IDENTICAL", man, fixed = TRUE)))
  expect_false(file.exists(here::here("RHTP-Obligated-Funds-10082026.pdf")))
})

test_that("a fresh parse reproduces the committed state and line tables", {
  p <- obl_parse()
  expect_silent(obl_assert(p))
  st <- obl_state_table(p)
  committed <- ref("cms_obligations_bp1_state.csv")
  expect_equal(st$state, committed$state)
  expect_equal(st$bp1_award, committed$bp1_award)
  expect_equal(st$funds_put_to_work, committed$funds_put_to_work)
  ln <- obl_lines_table(p)
  cl <- ref("cms_obligations_bp1_lines.csv")
  expect_equal(ln$line_id, cl$line_id)
  expect_equal(ln$amount, cl$amount)
  expect_equal(ln$named_orgs, cl$named_orgs)
})

test_that("50 states, 14 wrapped headers, SD's bare dollar, $9,995,000,000 of BP1", {
  st <- ref("cms_obligations_bp1_state.csv")
  expect_equal(nrow(st), 50L)
  expect_setequal(st$state[st$header_wrapped], OBL_WRAPPED)
  expect_equal(st$state[st$header_bare_dollar], "SD")
  expect_equal(round(sum(st$bp1_award), 2), 9995000000)
  expect_true(all(st$as_of == as.Date("2026-07-31")))
  expect_true(all(st$report_date == as.Date("2026-10-08")))
  expect_true(all(st$budget_period == 1L))
})

test_that("the FY2026 table is untouched and BP1 differs only in Oregon beyond rounding", {
  al <- ref("cms_fy2026_allotments.csv")
  expect_false("bp1_award" %in% names(al))
  expect_equal(sum(al$fy2026_allotment), 10000000003)
  rc <- ref("cms_obligations_bp1_allotment_reconciliation.csv")
  expect_equal(rc$state[!rc$rounds_to_fy2026], "OR")
  expect_equal(rc$diff_bp1_minus_fy2026[rc$state == "OR"], -5000000.33)
})

test_that("Hawaii's bullets are unusable and its category totals stand", {
  ln <- ref("cms_obligations_bp1_lines.csv")
  hi <- ln[ln$state == "HI", ]
  expect_true(all(!hi$amount_usable))
  expect_true(all(OBL_HI_REPEATED %in% hi$amount))
  expect_true(all(ln$amount_usable[ln$state != "HI"]))
})

test_that("reconciliation failures are LOGGED, and known source defects are among them", {
  ck <- ref("cms_obligations_bp1_checks.csv")
  expect_true(all(ck$status %in% c("EXACT", "ROUNDING", "FAIL")))
  fails <- ck[ck$status == "FAIL", ]
  expect_true(any(fails$state == "MT" & fails$check == "INITIATIVES_TO_STATE_TOTAL"))
  expect_true(any(fails$state == "CT" & fails$name == "Program Operations"))
  # Iowa's two-items-in-one bullet is split, so its category reconciles.
  iac <- ck[ck$state == "IA" & ck$name == "Appropriate Care Availability", ]
  expect_true(all(iac$status == "EXACT"))
})

test_that("ligature repair touches description_clean only, never a real capital W", {
  expect_equal(obl_clean_text("EWiciency staW oWice JeWerson eWorts"),
               "Efficiency staff office Jefferson efforts")
  expect_equal(obl_clean_text("CHW RDW NEW IOWA GROW WWAMI PoWER"),
               "CHW RDW NEW IOWA GROW WWAMI PoWER")
  ln <- ref("cms_obligations_bp1_lines.csv")
  expect_true(any(grepl("staW", ln$description_raw)))
  expect_false(any(grepl("\\bstaW\\b", ln$description_clean)))
})

test_that("tier is SUBAWARD only where a recipient is named, SOLICITATION otherwise", {
  ln <- ref("cms_obligations_bp1_lines.csv")
  expect_true(all(ln$tier %in% c("SUBAWARD", "SOLICITATION")))
  expect_equal(ln$tier == "SUBAWARD", !is.na(ln$named_orgs))
  expect_true(all(OBL_NAME_VERDICTS$line_id %in% ln$line_id))
})

test_that("no obligation table is an award file, and the layers never carry a bucket", {
  src <- readLines(here::here("tests", "testthat", "test_state_union.R"))
  expect_false(any(grepl("cms_obligation", src)))
  pur <- ref("cms_obligation_hospital_purpose.csv")
  expect_true(all(pur$layer == "LEAD_ONLY_NEVER_IN_A_BUCKET"))
  for (f in c("cms_obligations_bp1_lines.csv", "cms_obligation_name_matches.csv",
              "cms_obligation_hospital_purpose.csv", "cms_obligation_hospital_decision_lists.csv")) {
    x <- ref(f)
    expect_false(any(c("hospital_attribution", "distributed_to_hospital") %in% names(x)), info = f)
  }
})

test_that("the gap table ranks on obligation minus published Tier 3 and says it is a ranking", {
  g <- ref("cms_obligation_gap_by_state.csv")
  expect_equal(nrow(g), 50L)
  expect_equal(g$hunt_rank, seq_len(50))
  expect_true(all(diff(g$gap_cms_obligated_minus_ours) <= 0))
  expect_true(all(grepl("never a dollar finding", g$comparability)))
})

test_that("the CMS monitor flags a new obligation report and a missed refresh", {
  source(here::here("R", "00_cms_press_monitor.R"))
  expect_equal(rhtp_cms_obligation_verdict("RHTP-Obligated-Funds-10082026.pdf",
                                           as.Date("2026-11-01"))$verdict, "UNCHANGED")
  late <- rhtp_cms_obligation_verdict("RHTP-Obligated-Funds-10082026.pdf", as.Date("2026-12-08"))
  expect_match(late$note, "No refreshed obligation report")
  expect_equal(rhtp_cms_obligation_verdict(c("RHTP-Obligated-Funds-10082026.pdf",
                                             "RHTP-Obligated-Funds-12152026.pdf"))$verdict, "CHANGED")
})

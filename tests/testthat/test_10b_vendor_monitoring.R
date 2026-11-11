# test_10b_vendor_monitoring.R -- session 116f, Task 4: vendor monitoring
#
# Pins: the dictionary-driven vendor tripwire logs VENDOR (never raised, never
# hiding a TRIPWIRE) and only for a firm the archived copy does not name; the
# FSRS Routine flags new filings to dictionary or out-of-state recipients; a
# contract register logs CHANGED on a move and trips on a new contract; CMS's
# unnamed contractor lines are read from the NEWEST edition and split
# CONTRACTOR_ONLY / MIXED.

source(here::here("R", "utils_spend_category.R"))

test_that("VENDOR is a probe verdict and the tripwire reads the dictionary's vendor classes only", {
  expect_true("VENDOR" %in% RHTP_PROBE_VERDICTS)
  expect_setequal(RHTP_VENDOR_TRIPWIRE_CLASSES, c("CONSULTING_BIG", "CONSULTING_OTHER", "TECH_VENDOR"))
  expect_true("Deloitte Consulting LLP" %in% rhtp_vendor_names_in("Contract with Deloitte for PMO"))
  expect_length(rhtp_vendor_names_in("Molina Healthcare and Centene"), 0L)   # INSURER_MCO: not a vendor class
})

test_that("a newly named vendor logs VENDOR, is not raised, and a firm already on the page is silent", {
  log <- tempfile(fileext = ".csv")
  ev <- tempfile("ev"); dir.create(ev)
  arch <- paste("Rural Health Transformation awards. Alpha Community Health Center. Beta Health Partners.",
                "Gamma County Hospital District. Epsilon Medical Center.")
  live_same <- paste(arch, "Guidehouse remains the evaluator.")
  arch_g <- paste(arch, "Guidehouse remains the evaluator.")
  res <- rhtp_probe_run("ZZ", {
    rhtp_assert_no_new_organisations(paste(arch, "Guidehouse and McKinsey support the programme."),
                                     arch_g, state = "ZZ", page = "p1")
    rhtp_assert_no_new_organisations(live_same, arch_g, state = "ZZ", page = "p2")
    tibble::tibble(page = c("p1", "p2"), changed = c(TRUE, FALSE))
  }, path = log, evidence_root = ev)
  got <- readr::read_csv(log, show_col_types = FALSE)
  v <- got[got$verdict == "VENDOR", ]
  expect_equal(nrow(v), 1L)
  expect_equal(v$page, "p1")
  expect_match(v$note, "McKinsey", fixed = TRUE)
  expect_false(grepl("Guidehouse", v$note, fixed = TRUE))
})

test_that("a vendor finding never hides a Year 1 TRIPWIRE", {
  log <- tempfile(fileext = ".csv")
  ev <- tempfile("ev"); dir.create(ev)
  arch <- paste("Awards. Alpha Community Health Center. Beta Health Partners.",
                "Gamma County Hospital District. Epsilon Medical Center.")
  live <- paste(arch, "New award: Delta Regional Medical Center. Deloitte will administer.")
  expect_error(rhtp_probe_run("ZZ", {
    rhtp_assert_no_new_organisations(live, arch, state = "ZZ", page = "p1")
    tibble::tibble(page = "p1", changed = TRUE)
  }, path = log, evidence_root = ev), "THAT IS THE SIGNAL")
  got <- readr::read_csv(log, show_col_types = FALSE)
  expect_true(all(c("TRIPWIRE", "VENDOR") %in% got$verdict))
})

test_that("a contract register logs CHANGED on a move and trips on a new contract", {
  log <- tempfile(fileext = ".csv")
  ev <- tempfile("ev"); dir.create(ev)
  committed <- tibble::tibble(awardee = c("Acme Consulting", "Beta LLC"), amount = c(100, 200))
  expect_error(rhtp_probe_run("ZZ", {
    rhtp_contract_register_check("ZZ", "register", "live text v2", "live text v1",
                                 live_rows = tibble::tibble(awardee = c("Acme Consulting", "Beta LLC", "Gamma Inc"),
                                                            amount = c(100, 200, 300)),
                                 committed_rows = committed)
    tibble::tibble(page = "other", changed = FALSE)
  }, path = log, evidence_root = ev), "NEW CONTRACT")
  got <- readr::read_csv(log, show_col_types = FALSE)
  expect_true("CHANGED" %in% got$verdict[got$page == "register"])
  expect_true("TRIPWIRE" %in% got$verdict[got$page == "register"])
  # same contracts, same text: nothing logged for the register
  log2 <- tempfile(fileext = ".csv")
  rhtp_probe_run("ZZ", {
    rhtp_contract_register_check("ZZ", "register", "same", "same", live_rows = committed, committed_rows = committed)
    tibble::tibble(page = "other", changed = FALSE)
  }, path = log2, evidence_root = ev)
  expect_false("register" %in% readr::read_csv(log2, show_col_types = FALSE)$page)
})

test_that("the FSRS Routine flags new filings to dictionary or out-of-state recipients", {
  source(here::here("R", "09a_usaspending_rhtp.R"))
  new <- tibble::tibble(st = c("KY", "KY", "KY"),
                        subawardee_name = c("ERNST & YOUNG LLP", "HAZARD COUNTY CLINIC", "ACME LLC"),
                        subawardee_state_code = c("KY", "KY", "OH"), subaward_amount = c("1000000", "5", "7"),
                        subawardee_city_name = c("LOUISVILLE", "HAZARD", "AKRON"))
  m <- usa_vendor_flags(new)
  expect_length(m, 2L)
  expect_match(m[1], "Ernst & Young LLP", fixed = TRUE)
  expect_match(m[2], "outside the awarding state", fixed = TRUE)
  expect_length(usa_vendor_flags(new[2, ]), 0L)
})

test_that("CMS's unnamed contractor lines come from the newest edition, split CONTRACTOR_ONLY / MIXED", {
  ed <- rhtp_cms_lines_editions()
  expect_true(length(ed) >= 1L)
  x <- rhtp_unnamed_contractor_lines()
  expect_equal(unique(x$edition), sub("^cms_obligations_bp1_lines_([0-9]{8})\\.csv$", "\\1", utils::tail(ed, 1)))
  expect_true(all(x$split %in% c("CONTRACTOR_ONLY", "MIXED")))
  if (unique(x$edition) == "20261014") {
    expect_equal(nrow(x), 45L)
    expect_equal(round(sum(x$amount_obligated), 2), 148946402.72)
    expect_setequal(x$line_id[x$split == "MIXED"], c("KS-006-21-46", "KY-006-17-25", "MO-001-01-02", "NH-006-18-18"))
    expect_equal(round(sum(x$amount_obligated[x$split == "MIXED"]), 2), 32613736.29)
  }
})

# test_03bx_va_vhcf_awardees.R ------------------------------------------------
# VHCF's Provider Interoperability round (session 92). Offline: reads the
# committed archive, the committed CMS enrolment files and the committed CSV.

library(testthat)
source(here::here("R", "03bx_va_vhcf_awardees.R"))
source(here::here("R", "02_normalize.R"))

committed <- readr::read_csv(HVA_CSV, show_col_types = FALSE, progress = FALSE)

test_that("the release parses to 25 lines summing to $14,390,000", {
  d <- hva_parse()
  expect_equal(nrow(d), 25L)
  expect_equal(sum(d$amount), 14390000)
  expect_silent(hva_assert_roster(d))
  expect_equal(sum(d$awardee == "Buchanan General Hospital"), 2L)
  expect_equal(sum(d$awardee == "Valley Health System"), 2L)
  expect_setequal(unique(d$category), HVA_CATEGORIES)
})

test_that("the CMS footer is the ALLOTMENT and is refused as the round total (§0.2)", {
  expect_error(rhtp_assert_footer_not_allotment(HVA_FOOTER, "VA", "SOLICITATION",
                                                label = "test"))
  expect_true(all(committed$round_amount == 14390000))
  expect_false(any(committed$amount == HVA_FOOTER))
})

test_that("Highland Medical Center is the FQHC its enrolment says, not a hospital or CAH", {
  f <- hva_federal()
  fq <- hva_assert_highland(f)
  expect_setequal(fq$ccn, c("491858", "491903"))
  row <- committed[committed$awardee == "Highland Medical Center", ]
  expect_equal(row$recipient_type, "FQHC_OR_RHC")
  expect_equal(row$distributed_to_hospital, "No")
  # A Highland record on the hospital file would stop the build.
  f2 <- f; i <- which(f2$kind == "HOSPITAL")[1]; f2$dba[i] <- "HIGHLAND MEDICAL CENTER"
  expect_error(hva_assert_highland(f2), "now appears")
})

test_that("hospital rows: five on exact CMS records, four system-parent lines on general knowledge", {
  h <- committed[committed$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 9L)
  expect_equal(sum(h$amount), 6390000)
  exact <- h[h$basis_type == "ORG_WEBSITE", ]
  expect_setequal(unique(exact$awardee), c("Buchanan General Hospital",
    "Community Memorial Hospital–VCU Health", "Carilion Medical Center",
    "Danville Regional Medical Center"))
  expect_equal(sum(exact$amount), 690000)
  expect_true(all(exact$determination_confidence == "MEDIUM"))
  expect_true(all(!is.na(exact$ccn)))
  gk <- h[h$basis_type == "GENERAL_KNOWLEDGE", ]
  expect_setequal(unique(gk$awardee), c("Valley Health System", "Ballad Health", "Sentara Health"))
  expect_equal(sum(gk$amount), 5700000)
  expect_true(all(gk$determination_confidence == "LOW") && all(is.na(gk$ccn)))
  expect_false(any(committed$determination_confidence == "HIGH"))
})

test_that("the two UVA Health strings are NON_HOSPITAL and queued", {
  uva <- committed[grepl("^UVA Health", committed$awardee), ]
  expect_equal(nrow(uva), 2L)
  expect_equal(sum(uva$amount), 884000)
  expect_true(all(uva$recipient_type == "UNIVERSITY_OR_AHC"))
  expect_true(all(uva$distributed_to_hospital == "No"))
  q <- readr::read_csv(here::here("data", "reference", "classification_review_queue.csv"),
                       show_col_types = FALSE)
  row <- q[q$question_id == "AHC_STRING_NAMES_NO_ENROLLED_ENTITY", ]
  expect_match(row$state, "VA")
  expect_match(row$row_key, "UVA Health Comprehensive Epilepsy Program", fixed = TRUE)
  expect_match(row$dollar_effect, "+$884,000", fixed = TRUE)
})

test_that("the committed CSV is what the archive rebuilds", {
  a <- hva_awardees()
  expect_equal(a$awardee, committed$awardee)
  expect_equal(a$amount, committed$amount)
  expect_equal(a$recipient_type, committed$recipient_type)
  expect_equal(a$distributed_to_hospital, committed$distributed_to_hospital)
})

test_that("VHCF's 07-10 regular-grant release is registered as non-RHT and not extracted", {
  expect_silent(hva_assert_trap())
  reg <- rhtp_read_state_program_registry()
  row <- reg[reg$program_id == "VA-VHCF-REGULAR-GRANTS", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$disposition, "NOT_RHTP_STATE_PROGRAM")
  expect_true(file.exists(here::here(row$source_archive_path)))
  expect_equal(rhtp_match_state_program(
    "VA", "Virginia Health Care Foundation Awards More Than $2.7 Million in Grants", reg)$program_id,
    "VA-VHCF-REGULAR-GRANTS")
  expect_true(is.na(rhtp_match_state_program(
    "VA", "VHCF announced 25 awards totaling $14.39 million through Virginia's Rural Health Transformation Program", reg)$flag))
})

test_that("R/03bb watches VHCF's news index by post URL", {
  source(here::here("R", "03bb_va_year1_probe.R"))
  expect_true("vhcf_news" %in% VA_PAGES$key)
  arch <- paste(readLines(here::here(HVA_SOURCES$file[3]), warn = FALSE), collapse = "\n")
  expect_true(HVA_URL %in% va_vhcf_posts(arch))
  expect_silent(va_assert_no_new_vhcf_post(arch, arch))
  new <- sub("</body>", "<a href=\"https://www.vhcf.org/2026/10/20/provider-productivity/\">x</a></body>", arch)
  expect_error(va_assert_no_new_vhcf_post(new, arch), "PUBLISHED A POST")
})

# test_03bw_sd_ccbhc_awardees.R -------------------------------------------------
# South Dakota's CCBHC round (session 90) and the state-money EMS roster
# registered beside it. Reads committed files only -- no network, no quota.

library(testthat)

source(here::here("R", "03bw_sd_ccbhc_awardees.R"))
source(here::here("R", "02_normalize.R"))

committed <- readr::read_csv(SDC_CSV, show_col_types = FALSE)

test_that("the archived release validates and the committed file is what --build writes", {
  built <- sdc_validate()
  expect_equal(nrow(committed), 13L)
  expect_equal(committed$awardee, built$awardee)
  expect_equal(committed$recipient_type, built$recipient_type)
  expect_equal(committed$distributed_to_hospital, built$distributed_to_hospital)
})

test_that("thirteen named, twelve grants, and the gap is recorded rather than resolved", {
  expect_equal(unique(committed$cohort_members), 13L)
  expect_equal(unique(committed$round_awards), 12L)
  expect_true(all(committed$recipient_confirmed == "Unclear"))
  expect_true(all(grepl("SD_CCBHC_COHORT_13_VS_12_GRANTS", committed$note, fixed = TRUE)))
  q <- readr::read_csv(here::here("data", "reference", "classification_review_queue.csv"),
                       show_col_types = FALSE)
  expect_true(all(c("SD_CCBHC_COHORT_13_VS_12_GRANTS", "SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE") %in%
                    q$question_id))
})

test_that("no amount is published, so none is invented; the pool is a floor in round_amount", {
  expect_true(all(is.na(committed$amount)))
  expect_equal(unique(committed$round_amount), 13000000)
  expect_true(all(committed$round_amount_is_floor))
  # A second currency figure in the release would mean a per-grant amount.
  t <- sdc_text()
  forged <- sub("totaling more than $13 million.",
                "totaling more than $13 million. Avera received $1,200,000.", t, fixed = TRUE)
  expect_error(sdc_assert_source(forged), "currency figure")
})

test_that("Avera Behavioral Health is checked on its EXACT legal name and is not typed a hospital", {
  chk <- sdc_avera_enrolment_check()
  expect_equal(nrow(chk$exact), 0L)
  expect_equal(chk$psychiatric$ccn, "434003")
  expect_equal(chk$nearest$ccn, "43S016")
  av <- committed[committed$awardee == "Avera Behavioral Health", ]
  expect_equal(av$recipient_type, "NONPROFIT_CBO")
  expect_equal(av$determination_confidence, "LOW")
  expect_true(is.na(av$ccn))
  expect_match(av$recipient_type_source, "43S016", fixed = TRUE)
  # If CMS ever carried the exact string, the check must refuse to stay quiet.
  f <- sdc_federal()
  f$org[f$ccn == "43S016"] <- "AVERA BEHAVIORAL HEALTH"
  expect_error(sdc_avera_enrolment_check(f), "NOW carries")
})

test_that("no cohort row enters any hospital bucket", {
  expect_false(any(committed$distributed_to_hospital == "Yes"))
  expect_true(all(committed$hospital_attribution == "NOT_HOSPITAL"))
})

test_that("the Regional Services Designation roster is registered as state money and caught", {
  reg <- rhtp_read_state_program_registry()
  row <- reg[reg$program_id == "SD-DOH-RSD-GRANT-FUND", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$disposition, "NOT_RHTP_STATE_PROGRAM")
  expect_equal(row$program_date, as.Date("2025-08-04"))
  expect_true(row$program_date < SDC_NOA_DATE)
  expect_true(file.exists(here::here(row$source_archive_path)))

  m <- rhtp_match_state_program("SD", "SD - 2026 - Regional Services Designation Grant Fund Distribution", reg)
  expect_equal(m$program_id, "SD-DOH-RSD-GRANT-FUND")
  expect_equal(m$flag, "PROVENANCE_STATE_PROGRAM")
  # The RHTP round it resembles must NOT be caught.
  expect_true(is.na(rhtp_match_state_program(
    "SD", "Enhancing Sustainable Emergency Medical Services RFP 26-09RHT-023", reg)$flag))

  # The archive says what the row says: the two round totals, the date, and no
  # RHT language in the content region; and no key survived the strip.
  html <- paste(readLines(here::here(row$source_archive_path), warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_false(grepl("InstrumentationKey", html, fixed = TRUE))
  main <- xml2::xml_text(xml2::xml_find_first(xml2::read_html(html), "//main"))
  expect_match(main, "Round 1 Total: $1,668,809.91", fixed = TRUE)
  expect_match(main, "Round 2 Total: $5,839,975.00", fixed = TRUE)
  expect_match(main, "Emergency Medical Services Interim Committee", fixed = TRUE)
  expect_false(grepl("Rural Health Transformation", main, fixed = TRUE))
  expect_match(html, "Content last updated: August 4, 2025", fixed = TRUE)
})

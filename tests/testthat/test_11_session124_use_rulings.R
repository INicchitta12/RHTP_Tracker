# test_11_session124_use_rulings.R ------------------------------------------------
# SESSION 124, owner rulings on session 123's use categories: OCR / hand
# transcription admitted at MEDIUM and recorded (use_category_text_method); CMS
# obligation-report headings as programme-level evidence (CMS_REPORT_HEADING);
# Ohio's direct payments to 22 hospitals coded B from ODH's own text.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "11_use_categories.R"))
rd <- function(f) readr::read_csv(here::here(f), col_types = readr::cols(.default = "c"), na = character(),
                                  progress = FALSE)

test_that("every crosswalk rule records how its plan text was read, and OCR rows are the four image-only plans", {
  x <- rd(RHTP_USE_CROSSWALK)
  expect_true(all(x$text_method %in% RHTP_USE_TEXT_METHODS))
  expect_setequal(unique(x$state[x$text_method == "OCR"]), c("MS", "MI", "KY"))
  expect_setequal(unique(x$state[x$text_method == "HAND_TRANSCRIBED"]), "HI")
})

test_that("award rows carry the text method only on crosswalk-based rows", {
  d <- rd("data/reference/ms_year1_awardees.csv")
  cw <- d$use_category_basis %in% c("INITIATIVE_CROSSWALK", "CMS_REPORT_HEADING")
  expect_true(all(d$use_category_text_method[cw] %in% RHTP_USE_TEXT_METHODS))
  expect_true(all(d$use_category_text_method[!cw] == ""))
})

test_that("the two hand-reviewed CMS lines set the named programmes' primaries", {
  h <- rd(RHTP_USE_CMS_HEADINGS)
  expect_identical(h$heading_letter[h$rule_id == "MS-X01"], "J")
  expect_identical(h$heading_letter[h$rule_id == "OK-X18"], "I")
  expect_true(all(h$heading_level %in% c("INITIATIVE", "LINE")))
  ms <- rd("data/reference/ms_year1_awardees.csv")
  r <- ms[ms$use_category_basis == "CMS_REPORT_HEADING" & grepl("Care Gap Closure", ms$award_pool), ]
  expect_gt(nrow(r), 0)
  expect_true(all(r$use_category_primary == "J"))
  expect_true(all(r$use_category_confidence == "MEDIUM"))
})

test_that("a heading whose letter is not in the plan keeps the plan and records the conflict", {
  wa <- rd("data/reference/wa_year1_awardees.csv")
  c <- wa[grepl("[CONFLICT:", wa$use_category_quote, fixed = TRUE), ]
  expect_gt(nrow(c), 0)
  expect_true(all(c$use_category_basis == "INITIATIVE_CROSSWALK"))
})

test_that("Ohio's direct payments to 22 hospitals are provider payments (B), LOW, on ODH's own text", {
  oh <- rd("data/reference/oh_year1_awardees.csv")
  r <- oh[grepl("one-time direct payments", oh$award_pool, fixed = TRUE), ]
  expect_equal(nrow(r), 23L)
  expect_true(all(r$use_category_primary == "B"))
  expect_true(all(r$use_category_basis == "PURPOSE_TEXT"))
  expect_equal(sum(as.numeric(r$amount), na.rm = TRUE), 30300000)
})

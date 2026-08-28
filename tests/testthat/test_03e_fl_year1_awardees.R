# test_03e_fl_year1_awardees.R -----------------------------------------------
# Florida Year 1 awardees, and the §8 recipient_type reconciliation that made
# them ingestible. Reads committed files off disk only -- no network, no quota.
#
# The question this file settles: what does `recipient_type` hold when the
# recipient is NAMED but its organisational form is not determinable from the
# source? Florida answered UNCLASSIFIED, Georgia answered NONPROFIT_CBO with a
# LOW confidence and a RECIPIENT_TYPE_INFERRED flag. Two answers to one question
# would split Stage 5, so Georgia's is adopted and Florida is back-fitted. These
# tests pin the settlement, not just the five rows that moved.

library(testthat)

source(here::here("R", "03e_fl_year1_awardees.R"))

records <- rhtp_fl_records()


# -- The assertions as a block -----------------------------------------------

test_that("every Florida assertion passes", {
  expect_true(rhtp_fl_assert(records))
})


# -- The vocabulary, which is the whole point --------------------------------

test_that("every categorical column is inside the 8 vocabulary", {
  # Florida could not be ingested until this passed. UNCLASSIFIED and
  # PHYSICIAN_PRACTICE were both outside it, for different reasons.
  for (col in c("recipient_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("UNCLASSIFIED is gone and PHYSICIAN_PRACTICE is a real 8 value", {
  expect_false("UNCLASSIFIED" %in% records$recipient_type)
  expect_true("PHYSICIAN_PRACTICE" %in% rhtp_vocabulary("recipient_type"))
  expect_true("RECIPIENT_TYPE_INFERRED" %in% rhtp_vocabulary("flag_reason"))
})


# -- The back-fit -------------------------------------------------------------

test_that("exactly the five UNCLASSIFIED rows moved, to NONPROFIT_CBO", {
  moved <- records %>%
    dplyr::filter(recipient_type_source != recipient_type)
  expect_equal(nrow(moved), 5L)
  expect_true(all(moved$recipient_type_source == "UNCLASSIFIED"))
  expect_true(all(moved$recipient_type == "NONPROFIT_CBO"))
  expect_setequal(
    moved$awardee,
    c("Nuvita Health", "Empowerq Health Care", "North Florida Rural Health Corp")
  )
})

test_that("a back-fitted row is flagged and marked LOW confidence", {
  # NONPROFIT_CBO on its own would read as a determined form. The flag and the
  # LOW confidence are what keep it readable as an inference.
  moved <- records %>%
    dplyr::filter(recipient_type_source != recipient_type)
  expect_true(all(moved$flag_reason == "RECIPIENT_TYPE_INFERRED"))
  expect_true(all(moved$determination_confidence == "LOW"))
})

test_that("the owner's original recipient_type is preserved on every row", {
  # 8: never discard the source's own language. This is what makes the
  # back-fit auditable, and reversible if the owner disagrees with it.
  expect_true(all(!is.na(records$recipient_type_source)))
  expect_true("UNCLASSIFIED" %in% records$recipient_type_source)
  expect_equal(sum(records$recipient_type_source == "UNCLASSIFIED"), 5L)
})

test_that("nothing except the five was re-coded", {
  # This is a vocabulary reconciliation, not a review of Florida's coding.
  untouched <- records %>%
    dplyr::filter(is.na(flag_reason) | flag_reason != "RECIPIENT_TYPE_INFERRED")
  expect_equal(nrow(untouched), 76L)
  expect_true(all(untouched$recipient_type == untouched$recipient_type_source))
})

test_that("no confidence was invented for a row this session did not judge", {
  # Florida's workbook carries no confidence column, so a value on an untouched
  # row would be this pipeline asserting something the owner never did.
  expect_equal(sum(!is.na(records$determination_confidence)), 5L)
})


# -- The physician practices, kept as themselves ------------------------------

test_that("the eight physician practices stay PHYSICIAN_PRACTICE", {
  # Adding the code to 8 was the decision taken; folding these into
  # NONPROFIT_CBO later would quietly undo it and would assert a form the
  # source contradicts.
  practices <- records %>% dplyr::filter(recipient_type == "PHYSICIAN_PRACTICE")
  expect_equal(nrow(practices), 8L)
  expect_true(all(practices$distributed_to_hospital == "No"))
  expect_true(all(is.na(practices$flag_reason)))
})

test_that("no hospital total moved as a result of the reconciliation", {
  # Neither change touches distributed_to_hospital, so Florida's hospital
  # figure is exactly what the owner supplied.
  owner <- openxlsx::read.xlsx(here::here(FL_OWNER_WORKBOOK), sheet = 1)
  expect_equal(
    sum(records$distributed_to_hospital == "Yes"),
    sum(owner$distributed_to_hospital == "Yes")
  )
  expect_equal(
    sum(records$amount[records$distributed_to_hospital == "Yes"], na.rm = TRUE),
    sum(owner$amount[owner$distributed_to_hospital == "Yes"], na.rm = TRUE)
  )
})


# -- Ingest fidelity ----------------------------------------------------------

test_that("the CSV carries every row of the owner's workbook", {
  owner <- openxlsx::read.xlsx(here::here(FL_OWNER_WORKBOOK), sheet = 1)
  expect_equal(nrow(records), nrow(owner))
  expect_equal(nrow(records), 81L)
  expect_setequal(records$row_no, owner$row_no)
})

test_that("the owner's original upload is archived with a manifest", {
  # It is the ingest source and cannot be regenerated -- the workbook at the
  # repo root is a render now, so re-ingesting that would fold a render back on
  # itself.
  expect_true(file.exists(here::here(FL_OWNER_WORKBOOK)))
  manifest <- here::here("data", "raw", "owner_uploads",
                         "FL_year1_awardees_original.manifest.txt")
  expect_true(file.exists(manifest))
  stated <- readLines(manifest, warn = FALSE) %>%
    stringr::str_subset("^\\s*sha256\\s*:") %>%
    stringr::str_remove("^\\s*sha256\\s*:\\s*") %>%
    stringr::str_trim()
  expect_equal(
    stated,
    digest::digest(file = here::here(FL_OWNER_WORKBOOK), algo = "sha256")
  )
})

test_that("HTML-escaped awardee names are unescaped", {
  # "Quintero &amp; Kontopoulos" came in escaped. Fixing it is a transcription
  # correction, not a re-coding.
  expect_false(any(stringr::str_detect(records$awardee, "&amp;|&#39;|&quot;")))
  expect_true(any(stringr::str_detect(records$awardee, "Quintero & Kontopoulos")))
})


# -- The union, which is why the column order is preserved --------------------

test_that("Florida and Georgia union on their leading 19 columns", {
  ga_path <- here::here("data", "reference", "ga_great_health_awards.csv")
  skip_if_not(file.exists(ga_path), "Georgia has not been built")
  ga <- readr::read_csv(ga_path, show_col_types = FALSE, progress = FALSE)

  expect_identical(names(records)[1:19], names(ga)[1:19])

  union <- dplyr::bind_rows(records[, 1:19], ga[, 1:19])
  expect_equal(nrow(union), nrow(records) + nrow(ga))
  expect_setequal(unique(union$state), c("FL", "GA"))

  # The settlement in one assertion: two states, one vocabulary.
  bad <- setdiff(stats::na.omit(unique(union$recipient_type)),
                 rhtp_vocabulary("recipient_type"))
  expect_equal(bad, character(0))
})

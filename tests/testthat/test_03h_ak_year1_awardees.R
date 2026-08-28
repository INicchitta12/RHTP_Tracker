# test_03h_ak_year1_awardees.R -----------------------------------------------
# Alaska Year 1 awardees. Reads the committed workbook and CSV off disk -- no
# network, no quota.
#
# The one thing this file exists to keep closed is the 161-vs-142 gap, which
# session 11 left open with a wrong hypothesis. It is not a rounding question
# and it must never be averaged: 142 Implementation + 19 Planning = 161, from
# Alaska's own column, corroborated by its own App ID prefix.

library(testthat)

source(here::here("R", "03h_ak_year1_awardees.R"))

records <- rhtp_ak_records()
archive <- here::here(AK_EVIDENCE_DIR, AK_AWARDS_FILE)


test_that("every Alaska assertion passes", {
  expect_true(rhtp_ak_assert(records))
})

test_that("the committed CSV matches a fresh parse of the committed archive", {
  fresh <- rhtp_ak_build()
  expect_equal(nrow(fresh), nrow(records))
  expect_equal(fresh$app_id, records$app_id)
  expect_equal(fresh$amount, records$amount)
  expect_equal(fresh$recipient_type, records$recipient_type)
  expect_equal(fresh$distributed_to_hospital, records$distributed_to_hospital)
})


# -- The gap, closed ---------------------------------------------------------

test_that("161 = 142 Implementation + 19 Planning, and CMS counts the 142", {
  expect_equal(nrow(records), 161L)
  expect_equal(sum(records$project_type == "Implementation"), 142L)
  expect_equal(sum(records$project_type == "Planning"), 19L)
  expect_equal(sum(records$project_type == "Implementation"),
               AK_CMS_STATED_PROJECTS)
})

test_that("the App ID prefix corroborates the Project Type column on every row", {
  # Two independent fields in Alaska's own file. If they disagree, the split
  # that explains the gap cannot be trusted and the reconciliation is live again.
  prefix_planning <- grepl("^BP1-PL", records$app_id)
  column_planning <- records$project_type == "Planning"
  expect_equal(prefix_planning, column_planning)
  expect_equal(sum(prefix_planning), 19L)
})

test_that("nothing is dropped and no average is taken", {
  # Both counts are reported side by side; neither replaces the other.
  recon <- rhtp_ak_reconcile(records)
  expect_true(any(grepl("Implementation", recon$measure)))
  expect_true(any(grepl("Planning", recon$measure)))
  expect_true(any(grepl("^projects stated by CMS", recon$measure)))
  expect_equal(sum(records$amount),
               sum(records$amount[records$project_type == "Implementation"]) +
                 sum(records$amount[records$project_type == "Planning"]))
})

test_that("App ID is the project key and is unique", {
  expect_equal(dplyr::n_distinct(records$app_id), nrow(records))
})


# -- Preliminary means preliminary -------------------------------------------

test_that("these are intents to award with preliminary amounts", {
  # Alaska says both, in its own sheet name and its own column header. Losing
  # either is how a figure Alaska called preliminary becomes one AHA published.
  expect_true(all(records$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(records$amount_confirmed == "No"))
  expect_true(all(records$recipient_confirmed == "Yes"))
  expect_true(all(records$amount_precision == "PRELIMINARY_AS_PUBLISHED"))
})

test_that("the sheet is the one Alaska named, not the first one", {
  expect_true(AK_SHEET_NAME %in% openxlsx::getSheetNames(archive))
  expect_equal(AK_SHEET_NAME, "Notice of Intent to Award")
})

test_that("this snapshot carries the three rolling notification dates", {
  expect_setequal(as.character(sort(unique(records$notification_date))),
                  c("2026-08-07", "2026-08-14", "2026-08-21"))
})


# -- The state's own classification outranks the name ------------------------

test_that("the state hospital association is not classified as a hospital", {
  # "Alaska Hospital & Healthcare Association" reads as a hospital from its name
  # alone. Alaska's own Organization Type field says otherwise, and it wins.
  ahha <- records[grepl("Hospital & Healthcare Association", records$awardee), ]
  expect_gt(nrow(ahha), 0L)
  expect_false(any(ahha$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(ahha$distributed_to_hospital == "No"))
})

test_that("recipient_type_source preserves Alaska's own words on every row", {
  expect_true(all(nzchar(records$recipient_type_source)))
})


# -- The varying-form flag ---------------------------------------------------

test_that("awardees whose form varies across their own rows are flagged, not harmonised", {
  varies <- records[records$flag_reason == "RECIPIENT_TYPE_VARIES_IN_SOURCE", ]
  expect_equal(dplyr::n_distinct(varies$awardee), 7L)
  expect_equal(nrow(varies), 26L)

  # The point of the flag: those awardees still carry MORE THAN ONE
  # recipient_type in the committed data. Harmonising them silently -- in
  # either direction -- is exactly what this must not do.
  per_awardee <- tapply(varies$recipient_type, varies$awardee,
                        function(x) length(unique(x)))
  expect_true(all(per_awardee > 1L))
})

test_that("ANTHC is the worked case and is not resolved by the pipeline", {
  anthc <- records[records$awardee == "Alaska Native Tribal Health Consortium", ]
  expect_setequal(unique(anthc$recipient_type),
                  c("HOSPITAL_OR_SYSTEM", "TRIBAL_ORG"))
  expect_true(all(anthc$flag_reason == "RECIPIENT_TYPE_VARIES_IN_SOURCE"))
  expect_true(all(grepl("not harmonised", anthc$determination_basis)))
})


# -- Evidence ----------------------------------------------------------------

test_that("the workbook is archived and its manifest digest verifies", {
  expect_true(file.exists(archive))
  manifest <- readLines(here::here(AK_EVIDENCE_DIR, AK_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  recorded <- recorded[nzchar(recorded)]
  expect_equal(length(recorded), 1L)
  expect_equal(recorded,
               digest::digest(readBin(archive, "raw", file.size(archive)),
                              algo = "sha256", serialize = FALSE))
})


# -- The vocabulary and the §10.2 coding -------------------------------------

test_that("every categorical column is inside the §8 vocabulary", {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(as.character(stats::na.omit(unique(records[[col]]))),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("only hospital recipients are coded distributed_to_hospital = Yes", {
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_true(all(yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                            "HOSPITAL_AFFILIATED_ENTITY")))
})

test_that("26 hospital rows hold $43,379,541.04 in preliminary amounts", {
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 26L)
  expect_equal(sum(yes$amount), 43379541.04, tolerance = 1e-6)
})

test_that("determination_basis is populated on every row (§7)", {
  expect_true(all(nzchar(records$determination_basis)))
})

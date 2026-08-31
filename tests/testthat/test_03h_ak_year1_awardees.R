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

test_that("161 = 142 Implementation + 19 Planning, on the file CMS described", {
  # Session 12's finding, asserted where it is TRUE -- against the archived
  # 2026-08-28 snapshot, which is the file CMS's 2026-08-25 release described.
  # It is a fact about a committed document and cannot legitimately change.
  prior <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE))
  expect_equal(nrow(prior), 161L)
  expect_equal(sum(prior$project_type == "Implementation"), 142L)
  expect_equal(sum(prior$project_type == "Planning"), 19L)
  expect_equal(sum(prior$project_type == "Implementation"),
               AK_CMS_STATED_PROJECTS)
})

test_that("the current snapshot is 185 = 166 Implementation + 19 Planning", {
  # Re-pointing AK_CMS_STATED_PROJECTS at 166 would have made the assertion
  # above pass and thrown session 12's finding away. The current file is
  # required to be a SUPERSET of the one CMS described, not equal to it.
  expect_equal(nrow(records), 185L)
  expect_equal(sum(records$project_type == "Implementation"), 166L)
  expect_equal(sum(records$project_type == "Planning"), 19L)
  expect_gt(sum(records$project_type == "Implementation"),
            AK_CMS_STATED_PROJECTS)
})

test_that("the rolling growth is 24 new awards and 1 revised, nothing lost", {
  growth <- rhtp_ak_growth()
  expect_equal(growth$prior_rows, 161L)
  expect_equal(growth$rows, 185L)
  expect_equal(nrow(growth$added), 24L)
  expect_equal(growth$added_total, 16862504.06)
  # The revision is NOT a new award and must never be counted as one.
  expect_equal(nrow(growth$revised), 1L)
  expect_equal(growth$revised$app_id, "BP1-IA-308")
  expect_equal(growth$revised_delta, 4306887.29, tolerance = 1e-6)
  expect_length(growth$vanished, 0L)
  # 24 new + 1 revised is the WHOLE of the change; nothing else moved.
  expect_equal(growth$total - growth$prior_total,
               growth$added_total + growth$revised_delta)
})

test_that("Alaska's own weekly counts corroborate the growth", {
  # The positive control. Without it "the file got bigger" is indistinguishable
  # from "we fetched it twice and something changed". The figures are DERIVED
  # here and then looked for in Alaska's text, never read off it.
  expect_true(rhtp_ak_assert_cycle_control())
  text <- rhtp_ak_cycle_update_text()
  expect_true(grepl("$182M", text, fixed = TRUE))
  expect_true(grepl("$16.9M", text, fixed = TRUE))
  expect_true(grepl("rolling weekly basis", text, fixed = TRUE))
})

test_that("the revised award says so on its own row, in free text", {
  row <- records[records$app_id == "BP1-IA-308", ]
  expect_equal(nrow(row), 1L)
  expect_true(grepl("REVISED this preliminary figure", row$determination_basis))
  expect_true(grepl("1,548,208", row$determination_basis))
  expect_true(grepl("5,855,095", row$determination_basis))
  # No new vocabulary code was invented for it: AMOUNT_PRELIMINARY already
  # means "this may move", and this is that happening.
  expect_true(row$amount_confirmed == "No")
})

test_that("the §6.2 ceiling is the allotment, not CMS's announced-to-date", {
  # A rolling file necessarily outruns a point-in-time count of what had been
  # announced. Keying the ceiling on CMS's "$160 million" made week 4 look like
  # an overrun of money Alaska demonstrably has.
  expect_equal(rhtp_ak_allotment(), 272174856)
  expect_gt(sum(records$amount), AK_CMS_ANNOUNCED_TO_DATE)
  expect_lt(sum(records$amount), rhtp_ak_allotment())
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

test_that("this snapshot carries the four rolling notification dates", {
  # Was three. Week 4 (2026-08-28) is the release session 22 picked up, and
  # there will be a fifth: Alaska announces "on a rolling weekly basis".
  expect_setequal(as.character(sort(unique(records$notification_date))),
                  c("2026-08-07", "2026-08-14", "2026-08-21", "2026-08-28"))
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
  expect_equal(nrow(varies), 29L)

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

test_that("both archived documents verify against the manifest", {
  # Two digests now, not one: the award notice and the Year 1 Funding Cycle
  # Update that corroborates it. Each is re-hashed off disk, so an archive that
  # drifts from what the manifest claims fails here rather than being trusted.
  expect_true(file.exists(archive))
  control <- here::here(AK_EVIDENCE_DIR, AK_CYCLE_UPDATE_FILE)
  expect_true(file.exists(control))
  manifest <- readLines(here::here(AK_EVIDENCE_DIR, AK_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  recorded <- recorded[nzchar(recorded)]
  expect_equal(length(recorded), 2L)
  expect_setequal(recorded, c(
    digest::digest(file = archive, algo = "sha256"),
    digest::digest(file = control, algo = "sha256")))
})

test_that("the prior snapshot is kept, not replaced", {
  # A rolling file's growth is only measurable against the snapshot it grew
  # from. Deleting the old archive would make every future diff impossible.
  expect_true(file.exists(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE)))
  expect_false(identical(AK_PRIOR_FILE, AK_AWARDS_FILE))
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

test_that("32 hospital rows hold $49,686,225.25 in preliminary amounts", {
  # Was 26 rows / $43,379,541.04 at the 2026-08-28 snapshot. Every figure here
  # is a PRELIMINARY amount on a notice of INTENT to award, and the file is a
  # snapshot of a weekly release -- it will move again.
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 32L)
  expect_equal(sum(yes$amount), 49686225.25, tolerance = 1e-6)
})

test_that("determination_basis is populated on every row (§7)", {
  expect_true(all(nzchar(records$determination_basis)))
})

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
source(here::here("R", "03ap_verification_queue_2.R"))

records <- rhtp_ak_records()
archive <- here::here(AK_EVIDENCE_DIR, AK_AWARDS_FILE)


test_that("every Alaska assertion passes", {
  expect_true(rhtp_ak_assert(records))
})

# SESSION 49: THE COMMITTED CSV IS THE BUILDER'S OUTPUT *PLUS THE COMMITTED
# VERIFICATION OVERLAY*, and that is the honest form of this claim now. The
# verification queue re-typed rows in this file; writing those onto the CSV
# without saying so here would mean the next `--build` silently wiped them and
# no test complained. `vq_overlay()` reads
# `data/reference/verification_queue_2_changes.csv`, which is itself derived
# from a committed, SHA-256-pinned workbook, so the CSV is still fully
# reproducible from committed inputs -- the dependency is now explicit.
test_that("the committed CSV matches a fresh parse of the committed archive", {
  fresh <- s71(vq_overlay(rhtp_ak_build(), "ak_year1_awardees.csv"), "ak_year1_awardees.csv")
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
  #
  # SESSION 46 SPLIT THIS SNAPSHOT OUT OF AK_PRIOR_FILE. That constant had
  # been doing two jobs that only looked like one while the file had been
  # refreshed exactly once: "what did Alaska publish LAST time?" (which must
  # roll on every refresh) and "which snapshot did CMS describe?" (which is
  # 2026-08-28 permanently). Rolling the conflated constant forward would have
  # moved this reconciliation onto a file CMS never described.
  anchor <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR,
                                            AK_CMS_ANCHOR_FILE))
  expect_equal(nrow(anchor), 161L)
  expect_equal(sum(anchor$project_type == "Implementation"), 142L)
  expect_equal(sum(anchor$project_type == "Planning"), 19L)
  expect_equal(sum(anchor$project_type == "Implementation"),
               AK_CMS_STATED_PROJECTS)
  expect_equal(sum(anchor$project_type == "Planning"), AK_ANCHOR_PLANNING)
  # And it is a DIFFERENT file from the rolling prior, which is the point.
  expect_false(identical(AK_CMS_ANCHOR_FILE, AK_PRIOR_FILE))
})

test_that("the current snapshot is 249 = 223 Implementation + 26 Planning", {
  # Re-pointing AK_CMS_STATED_PROJECTS at the current count would make the
  # assertion above pass and throw session 12's finding away. The current file
  # is required to be a SUPERSET of the one CMS described, not equal to it.
  expect_equal(nrow(records), 249L)
  expect_equal(sum(records$project_type == "Implementation"), 223L)
  expect_equal(sum(records$project_type == "Planning"), 26L)
  expect_gt(sum(records$project_type == "Implementation"),
            AK_CMS_STATED_PROJECTS)
})

test_that("ALASKA HAS RESUMED PLANNING AWARDS, 19 -> 26", {
  # Through 2026-08-31 the Planning count sat at 19 across every snapshot, and
  # an assertion required it UNCHANGED -- a true observation turned into a
  # rule, and the rule was wrong. What actually needed pinning is narrower and
  # is pinned on the ANCHOR: CMS's 142 counts Implementation, so the anchor's
  # 19 Planning rows are what show CMS was not counting the whole file.
  prior <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, "2026-08-31_ak_rhtp_awardsnotice_2026.xlsx"))
  expect_equal(sum(prior$project_type == "Planning"), 19L)
  expect_equal(sum(records$project_type == "Planning"), 26L)
  # It may grow. It may not shrink below the anchor.
  expect_gte(sum(records$project_type == "Planning"), AK_ANCHOR_PLANNING)
})

test_that("the App ID prefix still agrees with the Project Type column", {
  # The independent corroboration, and it survives the growth: two columns
  # disagreeing would mean the file's own bookkeeping has drifted.
  expect_equal(sum(grepl("^BP1-PL", records$app_id)),
               sum(records$project_type == "Planning"))
  expect_equal(sum(grepl("^BP1-PL", records$app_id)), 26L)
})

test_that("the 2026-09-28 growth: 7 new, 5 revised, 2 WITHDRAWN (session 75)", {
  growth <- rhtp_ak_growth()
  expect_equal(growth$prior_rows, 244L)
  expect_equal(growth$rows, 249L)
  expect_equal(nrow(growth$added), 7L)
  expect_equal(growth$added_total, 6898848.42, tolerance = 1e-9)
  expect_equal(nrow(growth$revised), 5L)
  expect_equal(growth$revised_delta, -1798271, tolerance = 1e-9)
  # The first withdrawals Alaska has made. Both are HAND-READ into
  # AK_WITHDRAWN, and the assertion refuses any disappearance not on it.
  expect_setequal(growth$vanished, c("BP1-IA-034", "BP1-IA-057"))
  expect_setequal(AK_WITHDRAWN$app_id, growth$vanished)
  # The change closes: added - withdrawn + revised.
  prior <- rhtp_ak_parse_awards(here::here(AK_EVIDENCE_DIR, AK_PRIOR_FILE))
  withdrawn <- sum(prior$amount[prior$app_id %in% growth$vanished])
  expect_equal(withdrawn, 1666031, tolerance = 1e-9)
  expect_equal(growth$total - growth$prior_total,
               growth$added_total - withdrawn + growth$revised_delta,
               tolerance = 1e-6)
  expect_equal(growth$total, 242620741.15, tolerance = 1e-9)
})

test_that("an UNLISTED withdrawal still fails the build, and a listed one that returns does too", {
  expect_true(all(!AK_WITHDRAWN$app_id %in% records$app_id))
  fake <- records[records$app_id != "BP1-IA-001", ]
  expect_error(rhtp_ak_assert(fake), "not in AK_WITHDRAWN")
})

test_that("ALASKA'S OWN WEEKLY TABLE ACCOUNTS FOR THE GROWTH", {
  # Week 7 (2026-09-25) is 7 projects -- exactly the 7 added App IDs. The
  # count is of ADDITIONS; the two withdrawals are not a week's row.
  weeks <- rhtp_ak_cycle_weeks()
  expect_equal(nrow(weeks), 7L)
  expect_equal(sum(weeks$projects), 249L)
  expect_equal(tail(weeks$projects, 1L), 7L)
  expect_equal(tail(weeks$projects, 1L), nrow(rhtp_ak_growth()$added))
  expect_true(rhtp_ak_assert_cycle_control())
})

test_that("Alaska's own weekly counts corroborate the growth", {
  expect_true(rhtp_ak_assert_cycle_control())
  text <- rhtp_ak_cycle_update_text()
  # $242.62M printed "$242M": truncated, where 2026-08-31's $181.87M was
  # printed "$182M", rounded. The check accepts the publisher's display
  # either way and nothing looser; the initiative figures sum to $242.6M.
  expect_true(grepl("$242M", text, fixed = TRUE))
  expect_equal(sum(c(95.4, 43.2, 31.5, 30.1, 21.5, 20.9)), 242.6)
  expect_true(grepl("$95.4M", text, fixed = TRUE))
  expect_true(grepl("rolling weekly basis|coming weeks", text))
})

test_that("revisions are noted against the FIRST snapshot carrying each row", {
  row <- records[records$app_id == "BP1-IA-308", ]
  expect_equal(nrow(row), 1L)
  expect_true(grepl("REVISED this preliminary figure between the 2026-08-28",
                    row$determination_basis))
  expect_true(grepl("1,548,208", row$determination_basis))
  expect_true(grepl("5,781,079", row$determination_basis))
  # Session 75: a row first published AFTER the anchor still gets its note.
  r38 <- records[records$app_id == "BP1-IA-038", ]
  expect_true(grepl("between the 2026-09-21 and 2026-09-28", r38$determination_basis))
  expect_true(grepl("4,808,670", r38$determination_basis))
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
  expect_equal(sum(prefix_planning), 26L)
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

test_that("this snapshot carries the seven rolling notification dates", {
  # Was four at 2026-08-31. Weeks 5 (2026-09-04) and 6 (2026-09-18) are new,
  # and there will be a seventh: Alaska announces "on a rolling weekly basis".
  expect_setequal(as.character(sort(unique(records$notification_date))),
                  c("2026-08-07", "2026-08-14", "2026-08-21", "2026-08-28",
                    "2026-09-04", "2026-09-18", "2026-09-25"))
  # The dates are Alaska's weeks, and its own weekly table names the same ones.
  expect_equal(length(unique(records$notification_date)),
               nrow(rhtp_ak_cycle_weeks()))
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
  # NA-SAFE since session 49: nine Alaska rows had RECIPIENT_TYPE_INFERRED as
  # their only flag and lost it when their form was verified, so a bare `==`
  # now indexes NA rows into the subset. The 9/39 counts below are
  # UNCHANGED -- nothing harmonised a varying form, which is the finding.
  varies <- records[!is.na(records$flag_reason) &
                      records$flag_reason == "RECIPIENT_TYPE_VARIES_IN_SOURCE", ]
  expect_equal(dplyr::n_distinct(varies$awardee), 9L)
  expect_equal(nrow(varies), 39L)

  # The point of the flag: those awardees still carry MORE THAN ONE
  # recipient_type in the committed data. Harmonising them silently -- in
  # either direction -- is exactly what this must not do.
  # SESSION 71: Providence Health & Services-Washington is the one exception,
  # and it is not a harmonisation. Alaska's per-project type still varies (the
  # flag stays, because it describes the SOURCE); the one row where Alaska named
  # only a service line was typed on CMS's hospital enrolment of that legal
  # entity (CCN 020001), a federal record, not a harmonisation of the column.
  s71_typed <- unique(records$awardee[!is.na(records$cms_enrolment_match)])
  expect_equal(s71_typed, "Providence Health & Services- Washington")
  per_awardee <- tapply(varies$recipient_type, varies$awardee,
                        function(x) length(unique(x)))
  expect_true(all(per_awardee[!names(per_awardee) %in% s71_typed] > 1L))
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

test_that("45 hospital rows hold $69,370,639.00 in preliminary amounts", {
  # SESSION 75 (2026-09-28 snapshot): 44 / $66,955,876.00 -> 45 / $69,370,639.00,
  # +$2,414,763 = Mat-Su Regional Medical Center +$5,000,000 (new), City of
  # Ketchikan +$350,000 (new; queued AK_KETCHIKAN_ALL_TYPES_TICKED), ANTHC
  # BP1-IA-034 -$1,603,406 (WITHDRAWN), ANTHC BP1-IA-038 -$1,674,392 (revised),
  # and +$342,561 because Alaska swapped the Organization Type strings of ANTHC
  # BP1-IA-033 (out, $295,994) and BP1-IA-035 (in, $638,555).
  # SESSION 71: + Providence Health & Services-Washington's $4,559,450.53
  # (CCN 020001) -- 43 rows / $62,396,425.47 before it.
  # Was 32 rows / $49,686,225.25 at the 2026-08-31 snapshot and 26 rows /
  # $43,379,541.04 at 2026-08-28. Every figure here is a PRELIMINARY amount on
  # a notice of INTENT to award, and the file is a snapshot of a weekly
  # release -- it will move again.
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 45L)
  expect_equal(sum(yes$amount), 69370639.00, tolerance = 1e-6)
})

test_that("determination_basis is populated on every row (§7)", {
  expect_true(all(nzchar(records$determination_basis)))
})

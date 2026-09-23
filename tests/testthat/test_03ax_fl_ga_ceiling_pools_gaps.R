# Tests for R/03ax_fl_ga_ceiling_pools_gaps.R -- Florida's ceiling, Georgia's
# pools, and both states' allotment gaps (session 57). Session 58 applied the
# three Florida codings on the owner's instruction; the tests pin what was
# applied, that it touched only those five rows, and what the rest may claim.

source(here::here("R", "03ax_fl_ga_ceiling_pools_gaps.R"))

res <- ax_fl_resolution()

test_that("the five formerly-Unclear Florida rows are exactly the $6,331,219.97 between floor and ceiling", {
  expect_equal(nrow(res), 5L)
  expect_equal(sum(res$amount), 6331219.97, tolerance = 1e-9)
  expect_setequal(unique(res$awardee),
                  c("Nuvita Health", "Empowerq Health Care", "North Florida Rural Health Corp"))
  expect_true(all(abs(res$amount - res$amount_in_source) < 0.01))
})

test_that("no formerly-Unclear Florida recipient matches any CMS-enrolled Florida hospital", {
  expect_true(all(res$cms_hospital_hits == 0))
  # the check is real: a hospital stem in the same file does match
  cms <- ax_cms("hosp", "FL")
  expect_true(any(grepl("CALHOUN", cms$org) | grepl("CALHOUN", cms$dba)))
})

test_that("each row carries the evidence class it earned, and only one is an exact record", {
  cls <- setNames(res$evidence_class, res$awardee)
  expect_equal(unname(cls["North Florida Rural Health Corp"]), "EXACT_FEDERAL_RECORD")
  expect_equal(unname(cls["Empowerq Health Care"]), "BRIDGE_FEDERAL_RECORD")
  expect_true(all(res$evidence_class[res$awardee == "Nuvita Health"] == "NEGATIVE_ONLY"))
  expect_equal(res$irs_hits[res$awardee == "North Florida Rural Health Corp"], "852728333")
  # the bridge is LOW, because the state's spelling is not the federal record's
  expect_equal(res$applied_confidence[res$awardee == "Empowerq Health Care"], "LOW")
  expect_equal(res$irs_hits[res$awardee == "Empowerq Health Care"], "")
})

test_that("the regions come from the release's counts and reproduce its regional totals", {
  lst <- ax_fl_list_rows()
  expect_equal(nrow(lst), 81L)
  expect_equal(res$region[res$awardee == "Empowerq Health Care"], "Southeast Region")
  expect_equal(res$region[res$awardee == "North Florida Rural Health Corp"], "Northwest Region")
})

test_that("the floor does not move and the ceiling is reported under each reading", {
  b <- ax_fl_bounds(res)
  expect_true(all(b$floor_pct == 26.2))
  expect_equal(b$ceiling_pct, c(29.6, 29.2, 27.5, 26.2, 26.2))
  # and as committed, Florida's ceiling IS its floor
  expect_equal(b$unclear_left_usd[b$reading == "AS COMMITTED (fl_year1_awardees.csv)"], 0)
})

test_that("session 58 applied all three codings, and only to the five rows", {
  expect_true(all(res$status == "APPLIED"))
  fl <- ax_fl()
  expect_equal(sum(fl$distributed_to_hospital == "Unclear"), 0L)
  k <- fl[fl$row_no %in% AX_FL_ROWS$row_no, ]
  expect_true(all(k$distributed_to_hospital == "No"))
  expect_true(all(k$recipient_type_source == "UNCLASSIFIED"))
  expect_equal(k$recipient_type[k$awardee == "Empowerq Health Care"], "NONPROFIT_CBO")
  expect_equal(k$recipient_type[k$awardee == "North Florida Rural Health Corp"], "NONPROFIT_CBO")
  expect_true(all(k$recipient_type[k$awardee == "Nuvita Health"] == "VENDOR_OR_CONTRACTOR"))
  # Nuvita is OWNER-CONFIRMED on general knowledge, so LOW (§0.4)
  nv <- k[k$awardee == "Nuvita Health", ]
  expect_true(all(nv$basis_type == "GENERAL_KNOWLEDGE"))
  expect_true(all(nv$determination_confidence == "LOW"))
  expect_true(all(grepl("OWNER-CONFIRMED", nv$verified_basis)))
  expect_true(all(grepl("Nuvita Cellular Health", nv$verified_basis)))
  # North Florida carries its IRS record
  expect_match(k$verified_basis[k$awardee == "North Florida Rural Health Corp"], "85-2728333")
  expect_match(k$verified_basis[k$awardee == "Empowerq Health Care"], "85-2591676")
  # no hospital dollar moved
  expect_equal(sum(fl$amount[fl$distributed_to_hospital == "Yes"]), 49345213.46, tolerance = 1e-9)
})

test_that("the overlay is idempotent and refuses a row that is not the one named", {
  f <- here::here("data", "reference", "fl_year1_awardees.csv")
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"), na = character())
  expect_identical(ax_fl_overlay(d, res), d)
  bad <- d; bad$awardee[bad$row_no == "9"] <- "Somebody Else"
  expect_error(ax_fl_overlay(bad, res), "is not Nuvita Health")
  yes <- d; yes$distributed_to_hospital[yes$row_no == "71"] <- "Yes"
  expect_error(ax_fl_overlay(yes, res), "only settles Unclear rows")
})

test_that("the report outputs are never the award files", {
  expect_false(any(grepl("fl_year1_awardees|ga_great_health_awards",
                         c(AX_OUT_FL, AX_OUT_GA, AX_OUT_GAPS))))
})

test_that("Georgia: two pools, no split, a non-hospital member in each, and no apportioned dollar", {
  ga <- ax_ga_pools()
  expect_equal(sort(ga$pool_usd), c(6500000, 15635000))
  expect_true(all(ga$per_hospital_split_published == "No"))
  expect_true(all(ga$non_hospital_member_amount == "NOT PUBLISHED"))
  expect_match(ga$non_hospital_member_named[ga$phase == 2], "DBHDD")
  expect_equal(ga$named_hospitals[ga$phase == 2], 17L)
  expect_equal(ga$named_hospitals[ga$phase == 4], 7L)
  # the ceiling is STRICT: each pool holds a positive, unpublished non-hospital award
  expect_true(all(ga$ga_true_share_vs_ceiling == "STRICTLY_BELOW"))
  expect_true(all(ga$ga_share_ceiling_pct == 57.0))
  expect_match(ga$ga_true_share_bound[1], "STRICTLY BELOW 57.0%", fixed = TRUE)
  share <- readr::read_csv(here::here("data", "reference", "year1_complete_hospital_share.csv"),
                           show_col_types = FALSE)
  expect_equal(unique(ga$ga_share_ceiling_pct), share$share_ceiling_pct[share$state == "GA"])
  # the sentences are in the archived announcements
  txt <- function(p) paste(readLines(here::here(p), warn = FALSE), collapse = " ")
  expect_match(txt("data/evidence/GA/2026-07-16_great_health_phase2_awards.html"),
               "a separate award to DBHDD", fixed = TRUE)
  expect_match(txt("data/evidence/GA/2026-08-27_great_health_phase4_awards.html"),
               "funded personalized assessments of all 87 hospitals", fixed = TRUE)
})

test_that("the gaps decompose exactly, and anything unsourced is labelled UNEXPLAINED", {
  g <- ax_gaps()
  for (st in c("FL", "GA")) {
    gap <- g$usd[g$state == st & g$basis == "ARITHMETIC"]
    expect_equal(sum(g$usd[g$state == st & g$basis != "ARITHMETIC"]), gap, tolerance = 1e-9)
    expect_true(any(g$basis[g$state == st] == "UNEXPLAINED"))
  }
  expect_equal(g$usd[g$state == "FL" & g$basis == "ARITHMETIC"], 21736938.39)
  expect_equal(g$usd[g$state == "GA" & g$basis == "ARITHMETIC"], 21713842.63)
  expect_equal(g$usd[g$state == "FL" & g$basis == "UNEXPLAINED"], 743118.89)
  expect_equal(g$usd[g$state == "GA" & g$basis == "UNEXPLAINED"], 19108368.83)
})

test_that("the Georgia NOA transcription is held to its own total and to DCH's footer", {
  expect_silent(ax_assert_ga_noa())
  expect_equal(sum(AX_GA_NOA_BUDGET$usd), AX_GA_NOA_TOTAL, tolerance = 1e-12)
})

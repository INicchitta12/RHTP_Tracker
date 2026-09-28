# test_03at_vt_year1_awardees.R ----------------------------------------------
# Session 54, updated session 74. Vermont: 146 executed agreements (112 on
# 2026-09-18, +34 on 2026-09-25), $109,295,193.50 as printed; the
# GMCB MOU out of the award file; the hospital typing on CMS enrolment files.

suppressWarnings(suppressMessages(source(here::here("R", "03at_vt_year1_awardees.R"))))

tb <- vt_parse_table()
vt <- vt_year1_awardees(tb)

test_that("146 agreements reconcile to the page's own total, to the cent", {
  expect_equal(nrow(tb), 146L)
  expect_equal(round(sum(tb$amount), 2), 109295193.50)
  expect_equal(attr(tb, "printed_total"), 109295193.50)
  expect_silent(vt_assert_reconciles(tb))
})

test_that("the GMCB inter-agency MOU is OUT of the award file and puts the total back", {
  expect_equal(nrow(vt), 145L)
  expect_false(any(grepl("Memorandum of Understanding", vt$awardee)))
  expect_equal(round(sum(vt$amount) + VT_MOU_AMOUNT, 2), 109295193.50)
  st <- vt_status_table(tb)
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "INTER_AGENCY_NOT_SUBAWARD"))
})

test_that("42 named-hospital rows, $35,285,416.18 -- and Mary Hitchcock is NH", {
  h <- vt[vt$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 42L)
  expect_equal(round(sum(h$amount), 2), 35285416.18)
  mh <- h[grepl("^Mary Hitchcock", h$awardee), ]
  expect_equal(nrow(mh), 3L)
  expect_true(all(mh$facility_state == "NH"))
  expect_equal(round(sum(mh$amount), 2), 8820815.60)
  # The general-knowledge typing is LOW so it can be subtracted.
  gk <- h[h$basis_type == "GENERAL_KNOWLEDGE", ]
  # UVM Health Network $2,474,684.82 + Gifford Medical (bridge) $1,008,012.12
  # + Southwestern Vermont Health $2,517,797.35 (session 74).
  expect_equal(round(sum(gk$amount), 2), 6000494.29)
  expect_true(all(gk$determination_confidence == "LOW"))
})

test_that("the name rule's two traps are refused on a federal record", {
  # '1248 Hospital Drive' is a STREET: CMS enrols the LLC as a nursing home.
  expect_equal(rhtp_classify_recipient_type(
    "1248 Hospital Drive Opco LLC DBA St. Johnsbury Center for Living and Rehabilitation",
    "VT")$recipient_type, "HOSPITAL_OR_SYSTEM")
  nh <- vt[grepl("^1248 Hospital Drive", vt$awardee), ]
  expect_equal(nrow(nh), 3L)
  expect_true(all(nh$recipient_type == "OTHER" & nh$distributed_to_hospital == "No"))
  # Gifford Health Care is the FQHC, not Gifford Medical Center.
  g <- vt[grepl("^Gifford Health Care", vt$awardee), ]
  expect_true(nrow(g) >= 2L)
  expect_true(all(g$recipient_type == "FQHC_OR_RHC"))
  expect_true(all(g$distributed_to_hospital == "No"))
  fq <- jsonlite::fromJSON(here::here(VT_FED_DIR, "cms_fqhc_enrollments_VT.json"))
  expect_true("GIFFORD HEALTH CARE INC" %in% fq$`ORGANIZATION NAME`)
  ho <- jsonlite::fromJSON(here::here(VT_FED_DIR, "cms_hosp_enrollments_VT.json"))
  expect_true("GIFFORD MEDICAL CENTER INC" %in% ho$`ORGANIZATION NAME`)
  sn <- jsonlite::fromJSON(here::here(VT_FED_DIR, "cms_snf_enrollments_VT.json"))
  expect_true("1248 HOSPITAL DRIVE OPCO LLC" %in% sn$`ORGANIZATION NAME`)
})

test_that("every row is an executed agreement and every OTHER states its form", {
  expect_true(all(vt$validation_source_type == "NOTICE_OF_AWARD"))
  expect_true(all(vt$amount_confirmed == "Yes"))
  o <- vt[vt$recipient_type == "OTHER", ]
  expect_true(all(grepl("Determined form:", o$determination_basis)))
  vocab <- rhtp_vocabulary("recipient_type")
  expect_true(all(vt$recipient_type %in% vocab))
})

test_that("the page still says executed and partial; the footer is the allotment", {
  expect_silent(vt_assert_partial_and_executed())
  expect_silent(vt_assert_footer_is_allotment())
})

test_that("the committed CSV matches a fresh build", {
  d <- readr::read_csv(VT_CSV, show_col_types = FALSE)
  expect_equal(d$awardee, vt$awardee)
  expect_equal(d$amount, vt$amount)
  expect_equal(d$recipient_type, vt$recipient_type)
})

test_that("session 74: the +34 is a diff of two archived lists, and re-spellings moved nothing", {
  prior <- vt_parse_table(readBin(here::here(VT_PRIOR_FILE), "raw",
                                  file.size(here::here(VT_PRIOR_FILE))))
  expect_equal(nrow(prior), 112L)
  expect_equal(attr(prior, "printed_total"), 87175011.33)
  # Every 2026-09-18 agreement is still printed, keyed on initiative, activity
  # and amount -- 34 of them under a different legal-name string, none re-priced.
  ka <- function(t) paste(t$initiative, t$activity, sprintf("%.2f", t$amount))
  expect_true(all(ka(prior) %in% ka(tb)))
  expect_equal(nrow(tb) - nrow(prior), 34L)
  expect_equal(round(sum(tb$amount) - sum(prior$amount), 2), 22120182.17)
  # The Gifford prefix is a hand-read bridge at LOW, never a machine match.
  gm <- vt[vt$awardee == "Gifford Medical", ]
  expect_equal(gm$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(gm$determination_confidence, "LOW")
  # The university and its cancer centre are not the enrolled hospital.
  u <- vt[vt$awardee %in% c("UVM - State Agricultural College",
                            "University of Vermont Cancer Center"), ]
  expect_true(all(u$distributed_to_hospital == "No"))
})

# test_03at_vt_year1_awardees.R ----------------------------------------------
# Session 54, updated sessions 74 and 94. Vermont: 166 executed agreements
# (112 on 2026-09-18, 146 on 2026-09-25, 166 on 2026-10-02), $127,419,853.91
# as printed; the
# GMCB MOU out of the award file; the hospital typing on CMS enrolment files.

suppressWarnings(suppressMessages(source(here::here("R", "03at_vt_year1_awardees.R"))))

tb <- vt_parse_table()
vt <- vt_year1_awardees(tb)

test_that("166 agreements reconcile to the page's own total, to the cent", {
  expect_equal(nrow(tb), 166L)
  expect_equal(round(sum(tb$amount), 2), 127419853.91)
  expect_equal(attr(tb, "printed_total"), 127419853.91)
  expect_silent(vt_assert_reconciles(tb))
})

test_that("the GMCB inter-agency MOU is OUT of the award file and puts the total back", {
  expect_equal(nrow(vt), 165L)
  expect_false(any(grepl("Memorandum of Understanding", vt$awardee)))
  expect_equal(round(sum(vt$amount) + VT_MOU_AMOUNT, 2), 127419853.91)
  st <- vt_status_table(tb)
  expect_false("amount" %in% names(st))
  expect_true(any(st$stage == "INTER_AGENCY_NOT_SUBAWARD"))
})

test_that("51 named-hospital rows, $44,866,699.26 -- and Mary Hitchcock is NH", {
  h <- vt[vt$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 51L)
  expect_equal(round(sum(h$amount), 2), 44866699.26)
  mh <- h[grepl("^Mary Hitchcock", h$awardee), ]
  expect_equal(nrow(mh), 3L)
  expect_true(all(mh$facility_state == "NH"))
  expect_equal(round(sum(mh$amount), 2), 8820815.60)
  # The general-knowledge typing is LOW so it can be subtracted.
  gk <- h[h$basis_type == "GENERAL_KNOWLEDGE", ]
  # UVM Health Network $2,474,684.82 + Gifford Medical (bridge) $1,008,012.12
  # + Southwestern Vermont Health $2,517,797.35 (session 74)
  # + UVM - Health Network $1,972,160 + Grace Cottage Family Health and
  # Hospital (bridge) $347,098.80 (session 94).
  expect_equal(round(sum(gk$amount), 2), 8319753.09)
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
  prior <- vt_parse_table(readBin(here::here(VT_PRIOR_FILE_0918), "raw",
                                  file.size(here::here(VT_PRIOR_FILE_0918))))
  p25 <- vt_parse_table(readBin(here::here(VT_PRIOR_FILE), "raw",
                                file.size(here::here(VT_PRIOR_FILE))))
  expect_equal(nrow(prior), 112L)
  expect_equal(attr(prior, "printed_total"), 87175011.33)
  # Every 2026-09-18 agreement is still printed, keyed on initiative, activity
  # and amount -- 34 of them under a different legal-name string, none re-priced.
  ka <- function(t) paste(t$initiative, t$activity, sprintf("%.2f", t$amount))
  expect_true(all(ka(prior) %in% ka(p25)))
  expect_equal(nrow(p25) - nrow(prior), 34L)
  expect_equal(round(sum(p25$amount) - sum(prior$amount), 2), 22120182.17)
  # The Gifford prefix is a hand-read bridge at LOW, never a machine match.
  gm <- vt[vt$awardee == "Gifford Medical", ]
  expect_equal(gm$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(gm$determination_confidence, "LOW")
  # The university and its cancer centre are not the enrolled hospital.
  u <- vt[vt$awardee %in% c("UVM - State Agricultural College",
                            "University of Vermont Cancer Center"), ]
  expect_true(all(u$distributed_to_hospital == "No"))
})

test_that("session 94: 20 new agreements, and ONE re-filed under a new initiative", {
  p25 <- vt_parse_table(readBin(here::here(VT_PRIOR_FILE), "raw",
                                file.size(here::here(VT_PRIOR_FILE))))
  expect_equal(nrow(p25), 146L)
  expect_equal(attr(p25, "printed_total"), 109295193.50)
  expect_equal(nrow(tb) - nrow(p25), 20L)
  expect_equal(round(sum(tb$amount) - sum(p25$amount), 2), 18124660.41)
  ka <- function(t) paste(t$initiative, t$activity, sprintf("%.2f", t$amount))
  # Every 2026-09-25 agreement is still printed, except NCHC's, which moved.
  gone <- p25[!(ka(p25) %in% ka(tb)), ]
  expect_equal(nrow(gone), 1L)
  expect_equal(gone$legal, VT_NCHC_MOVE$legal)
  expect_equal(c(gone$initiative, gone$activity), VT_NCHC_MOVE$from)
  moved <- tb[tb$legal == VT_NCHC_MOVE$legal & tb$initiative == VT_NCHC_MOVE$to[1], ]
  expect_equal(nrow(moved), 1L)
  expect_equal(moved$amount, VT_NCHC_MOVE$amount)
  expect_equal(moved$activity, VT_NCHC_MOVE$to[2])
  st <- vt_status_table(tb)
  expect_true(any(st$stage == "AGREEMENT_REFILED_SAME_AMOUNT"))
  # The new hospital rows, typed on the archived CMS enrolment files.
  ho <- jsonlite::fromJSON(here::here(VT_FED_DIR, "cms_hosp_enrollments_VT.json"))
  for (nm in c("BRATTLEBORO MEMORIAL HOSPITAL", "RUTLAND HOSPITAL, INC.",
               "NORTHEASTERN VERMONT REGIONAL HOSPITAL INC",
               "GIFFORD MEDICAL CENTER INC", "NORTHWESTERN MEDICAL CENTER INC")) {
    expect_true(nm %in% ho$`ORGANIZATION NAME`)
  }
  expect_true("GRACE COTTAGE INC" %in% ho$`DOING BUSINESS AS NAME`)
  med <- vt[vt$awardee %in% c("Northeastern Vermont Regional Hospital (NVRH)",
                              "Grace Cottage", "Gifford Medical Center"), ]
  expect_equal(nrow(med), 3L)
  expect_true(all(med$distributed_to_hospital == "Yes" &
                    med$determination_confidence == "MEDIUM"))
  low <- vt[vt$awardee %in% c("UVM - Health Network",
                              "Grace Cottage Family Health and Hospital"), ]
  expect_true(all(low$recipient_type == "HOSPITAL_OR_SYSTEM" &
                    low$determination_confidence == "LOW" &
                    low$basis_type == "GENERAL_KNOWLEDGE"))
  # Gifford Health Care (no Inc) is the FQHC again: its new $633,201.40 is NOT
  # hospital money.
  g <- vt[vt$awardee == "Gifford Health Care", ]
  expect_equal(g$recipient_type, "FQHC_OR_RHC")
  expect_equal(g$distributed_to_hospital, "No")
  # Nothing in the file is HIGH: no row carries a CCN (session 88).
  expect_false(any(vt$determination_confidence == "HIGH"))
})

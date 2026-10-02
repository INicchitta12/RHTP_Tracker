# test_03bt_ok_new_rosters.R ---------------------------------------------------
# Session 85. Oklahoma's three new rosters; only Doulas is written.

suppressWarnings(suppressMessages(source(here::here("R", "03bt_ok_new_rosters.R"))))

test_that("all three new rosters read at their 10-02 counts and totals", {
  expect_silent(okn_assert_source())
  expect_equal(nrow(okn_parse("rrr")), 20L)
  expect_equal(sum(okn_parse("rrr")$amount), 39578523)
  expect_equal(nrow(okn_parse("cdm")), 15L)
  expect_equal(sum(okn_parse("cdm")$amount), 15608845.22, tolerance = 1e-9)
})

test_that("Doulas: four rows, $647,967.83, Newman Memorial the one hospital row", {
  a <- okn_doulas()
  expect_silent(okn_assert_rows(a))
  n <- a[a$awardee == "Newman Memorial Hospital", ]
  expect_equal(n$ccn, "371336")
  expect_equal(n$cms_enrolment_match, "EXACT_LEGAL_NAME")
  expect_equal(n$hospital_attribution, "NAMED_HOSPITAL")
  # OU's Board of Regents is not the enrolled hospital body.
  expect_equal(a$distributed_to_hospital[grepl("Board of Regents", a$awardee)], "No")
})

test_that("RRR and CDM are written (session 86), each to its own file", {
  expect_true(all(OKN_ROSTERS$written))
  d <- readr::read_csv(OKN_CSV, show_col_types = FALSE)
  expect_equal(unique(d$award_pool), "Expanding Care: Doulas Program")
  expect_equal(d$amount, okn_doulas()$amount)
  for (k in c("rrr", "cdm")) {
    f <- readr::read_csv(if (k == "rrr") OKN_RRR_CSV else OKN_CDM_CSV,
                         show_col_types = FALSE, col_types = readr::cols(ccn = "c"))
    fresh <- okn_roster_rows(k)
    expect_equal(f$awardee, fresh$awardee, info = k)
    expect_equal(f$amount, fresh$amount, info = k)
    expect_equal(f$recipient_type, fresh$recipient_type, info = k)
    expect_silent(okn_assert_roster_rows(k, fresh))
  }
})

test_that("RRR: 10 hospital rows / $21,099,804; the four bridges are LOW", {
  a <- okn_roster_rows("rrr")
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 10L)
  expect_equal(sum(h$amount), 21099804)
  low <- h$awardee[h$determination_confidence == "LOW"]
  expect_setequal(low, c("Ascension St. John Jane Phillips Medical Center",
                         "Fairview Regional Medical Center",
                         "Lindsay Municipal Hospital Authority",
                         "Mercy Health Oklahoma Communities, Inc."))
  expect_true(all(h$basis_type[h$determination_confidence == "LOW"] == "GENERAL_KNOWLEDGE"))
  expect_true(is.na(h$ccn[grepl("^Mercy", h$awardee)]))
  # OPQIC's training reaches hospitals in kind; SWOSU's local hospital is unnamed.
  op <- a[grepl("OPQIC", a$awardee), ]
  expect_equal(op$flow_type, "IN_KIND_BENEFIT")
  expect_equal(op$distributed_to_hospital, "No")
  expect_equal(op$hospital_benefiting, "Yes")
  expect_equal(a$distributed_to_hospital[a$awardee == "Southwestern Oklahoma State University"], "No")
  expect_equal(a$recipient_type[grepl("^South Central Medical", a$awardee)], "FQHC_OR_RHC")
})

test_that("CDM: Choctaw on its CMS hospital enrolment, Central Oklahoma an FQHC", {
  a <- okn_roster_rows("cdm")
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 6L)
  expect_equal(sum(h$amount), 9197657.15, tolerance = 1e-9)
  ch <- a[a$awardee == "Choctaw Nation of Oklahoma", ]
  expect_equal(ch$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(ch$ccn, "370172")
  expect_equal(ch$cms_enrolment_match, "EXACT_LEGAL_NAME")
  expect_equal(ch$determination_confidence, "MEDIUM")
  co <- a[grepl("^Central Oklahoma Family", a$awardee), ]
  expect_equal(co$recipient_type, "FQHC_OR_RHC")
  expect_equal(co$distributed_to_hospital, "No")
  # the counterfactual: the name rule alone calls it a hospital
  expect_equal(rhtp_classify_recipient_type(co$awardee, "OK")$recipient_type,
               "HOSPITAL_OR_SYSTEM")
  expect_silent(okn_assert_rrr_cdm_federal())
})

test_that("R/03t no longer trips on Doulas, RRR or CDM", {
  suppressWarnings(suppressMessages(source(here::here("R", "03t_ok_year1_awardees.R"))))
  expect_false(any(c("Expanding Care: Doulas Program",
                     "Rural Regional Reorientation (RRR) Program",
                     "Chronic Disease Management Program") %in% OK_PENDING_OPPORTUNITIES))
  expect_equal(length(OK_PENDING_OPPORTUNITIES), 2L)
})

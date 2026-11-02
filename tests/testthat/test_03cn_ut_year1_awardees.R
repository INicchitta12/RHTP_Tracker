# Utah -- DHHS's "RHTP Awardee Announcement" (Google Doc linked from
# dhhs.utah.gov/ruralhealth/, page Last-Modified 2026-10-29), extracted session
# 112 as INTENTS (R/03cn).

source(here::here("R", "03cn_ut_year1_awardees.R"))

x <- utr_lines()
d <- utr_read(x)
a <- ut_year1_awardees(d)
committed <- readr::read_csv(here::here(UTR_OUT), show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the document reads as recorded: 40 priced lines $192,939,906.92 + one $156,000 class", {
  expect_silent(utr_assert_roster(d, x))
  expect_equal(nrow(d), 41L)
  pr <- d[d$amount_label == "Amount", ]
  expect_equal(nrow(pr), 40L)
  expect_equal(round(sum(pr$amount), 2), 192939906.92)
  expect_equal(round(sum(d$amount), 2), 193095906.92)
  # No total is printed; the figure is this file's sum.
  expect_false(any(grepl("^Total", x, ignore.case = TRUE)))
  expect_equal(sum(d$heading == "SHIFT 3.4: New Models of Care"), 11L)
  expect_equal(sum(d$heading == "SHIFT 3.2: Rural Health Provider Networks"), 5L)
  expect_equal(sum(d$heading == "RISE 2.5: Recruit and Retain - Hospitals"), 4L)
})

test_that("the CMS figure is the allotment (Tier 1), never a pool", {
  expect_true(grepl(UTR_ALLOTMENT_SENTENCE, paste(x, collapse = " "), fixed = TRUE))
  expect_silent(rhtp_assert_footer_not_allotment(195743566, "UT", "STATE_ALLOTMENT"))
  expect_error(rhtp_assert_footer_not_allotment(195743566, "UT", "SOLICITATION"))
  expect_false(any(a$amount == 195743566))
})

test_that("every row is an INTENT", {
  expect_true(all(a$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(a$amount_confirmed == "No"))
  expect_true(all(grepl("AMOUNT_PRELIMINARY", a$flag_reason, fixed = TRUE)))
  expect_true(grepl(UTR_INTENT_SENTENCE, paste(x, collapse = " "), fixed = TRUE))
  # The page's obligation sentence is an obligation statement, recorded only.
  expect_true(grepl(UTR_OBLIGATION_SENTENCE, utr_page_text(), fixed = TRUE))
})

test_that("the hospital figure, and what subtracts from it", {
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  expect_equal(nrow(h), 6L)
  expect_equal(round(sum(h$amount), 2), 5196812.90)
  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM" & h$flow_type == "DIRECT"))
  expect_false(any(a$determination_confidence == "HIGH"))
  ccn <- function(s) unique(a$ccn[a$awardee == s])
  expect_equal(ccn("Uintah Basin Medical Center (UBMC)"), "460019")
  expect_equal(ccn("Gunnison Valley Hospital"), "461306")
  expect_equal(ccn("Moab Valley Healthcare (MVH)"), "461302")
  expect_equal(ccn("University of Utah"), "460009")
  expect_equal(a$recipient_subtype[a$awardee == "University of Utah"], "ACADEMIC_HEALTH_CENTER")
  # Intermountain: a system parent, LOW, GENERAL_KNOWLEDGE, no CCN.
  ihc <- a[a$awardee == "Intermountain Health Center (IHC)", ]
  expect_equal(nrow(ihc), 2L)
  expect_true(all(is.na(ihc$ccn) & ihc$basis_type == "GENERAL_KNOWLEDGE" & ihc$determination_confidence == "LOW"))
  expect_equal(round(sum(h$amount[h$determination_confidence == "LOW"]), 2), 3072840.30)
})

test_that("the Utah Hospital Association's two lines code apart", {
  rr <- a[a$awardee == "Utah Hospital Association (UHA)" & a$amount == 9891739, ]
  expect_equal(rr$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_equal(rr$distributed_to_hospital, "Yes")
  expect_equal(rr$hospital_attribution, "POOL_UNNAMED_HOSPITALS")
  expect_equal(rr$intermediary_name, "Utah Hospital Association (UHA)")
  expect_match(rr$determination_basis, "subawards across 21 rural Critical Access and", fixed = TRUE)
  cap <- a[a$awardee == "Utah Hospital Association (UHA)" & a$amount == 38300000, ]
  expect_equal(cap$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(cap$distributed_to_hospital, "Unclear")
  expect_equal(cap$hospital_attribution, "NOT_HOSPITAL")
  expect_match(cap$determination_basis, "capital grants for rural facilities", fixed = TRUE)
})

test_that("rows that keep dollars OUT of every hospital bucket", {
  net <- a[a$awardee == "Utah Rural Independent Hospital Network", ]
  expect_equal(net$flow_type, "IN_KIND_BENEFIT")
  expect_equal(net$distributed_to_hospital, "No")
  expect_equal(net$hospital_benefiting, "Yes")
  un <- a[a$distributed_to_hospital == "Unclear", ]
  expect_equal(round(sum(un$amount), 2), 41300000)
  sa <- a[a$recipient_type == "STATE_AGENCY", ]
  expect_true(all(sa$distributed_to_hospital == "No"))
  expect_true(all(sa$fiscal_agent_tag[!grepl("DEQ|Geospatial", sa$awardee)]))
  expect_equal(a$flow_type[a$awardee == "U of U Physician Assistant Program (UPAP)/Switchpoint"], "NON_HOSPITAL")
  expect_equal(a$recipient_type[a$awardee == "73 Rural Clinical Preceptors"], "NOT_YET_NAMED")
  expect_equal(a$recipient_type[a$awardee == "Wayne Community Healthcare (WCH)"], "FQHC_OR_RHC")
})

test_that("the enrolment records relied on are in the archive", {
  expect_silent(utr_assert_federal())
})

test_that("the committed file is what the builder produces", {
  expect_equal(committed$awardee, a$awardee)
  expect_equal(round(committed$amount, 2), round(a$amount, 2))
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
  expect_equal(committed$hospital_attribution, a$hospital_attribution)
  expect_equal(dplyr::coalesce(committed$ccn, ""), dplyr::coalesce(a$ccn, ""))
  expect_equal(unique(committed$validator), "R/03cn_ut_year1_awardees.R")
  expect_silent(utr_assert_typing(a))
})

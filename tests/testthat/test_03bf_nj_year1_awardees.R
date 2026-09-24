# test_03bf_nj_year1_awardees.R ---------------------------------------------
# New Jersey's 103 priced awards. Offline: reads the committed PDF, releases
# and federal records only.

library(testthat)
source(here::here("R", "03bf_nj_year1_awardees.R"))

d <- nj_parse_roster()
a <- nj_year1_awardees(d)
committed <- readr::read_csv(NJ_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", site = "c"))

test_that("the roster parses to 103 rows and $83,060,837 in six sections", {
  expect_equal(nrow(d), 103L)
  expect_equal(sum(d$amount), 83060837)
  expect_equal(as.integer(table(factor(d$section, levels = names(NJ_SECTIONS)))),
               unname(NJ_SECTIONS))
  expect_silent(nj_assert_roster(d))
  expect_silent(nj_assert_releases())
})

test_that("the PDF prints no total and no CMS footer, so the sum is corroborated from outside", {
  t <- paste(rhtp_pdf_lines(here::here(NJ_PDF))$text, collapse = " ")
  expect_false(grepl("Total", t))
  expect_false(grepl("Centers for Medicare", t))
  g <- rhtp_watch_reduce(here::here(NJ_GOV))
  expect_true(grepl("investing $83 million", g, fixed = TRUE))
  expect_true(grepl("will fund 103 projects", g, fixed = TRUE))
})

test_that("a dropped row or a changed amount fails the roster assertion", {
  expect_error(nj_assert_roster(d[-50, ]), "103")
  d2 <- d; d2$amount[15] <- d2$amount[15] + 1
  expect_error(nj_assert_roster(d2), "83,060,837")
})

test_that("bracketed sites are carried in `site`, never welded into the awardee", {
  s <- d[!is.na(d$site), ]
  expect_equal(nrow(s), 7L)
  expect_true(all(s$section == "Building Rural Hospital Capacity"))
  expect_false(any(grepl("\\[", d$awardee)))
  expect_setequal(unique(s$awardee), c("AHS Hospital Corp.",
                                       "AtlantiCare Regional Medical Center",
                                       "Inspira Medical Centers, Inc."))
})

test_that("35 named-hospital rows, $35,275,076, every one DIRECT (§0.3a)", {
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 35L)
  expect_equal(sum(h$amount), 35275076)
  expect_true(all(h$flow_type == "DIRECT"))
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_false(any(h$determination_confidence == "HIGH"))
})

test_that("AtlantiCare Health Services is the FQHC, not the hospital (Gifford's shape)", {
  ahs <- a[a$awardee == "AtlantiCare Health Services, Inc.", ]
  expect_equal(nrow(ahs), 2L)
  expect_true(all(ahs$recipient_type == "FQHC_OR_RHC"))
  expect_true(all(ahs$distributed_to_hospital == "No"))
  expect_equal(sum(ahs$amount), 1946655)
  f <- nj_federal()
  expect_true(all(nj_federal_match("AtlantiCare Health Services, Inc.", f)$kind == "FQHC"))
  expect_equal(unique(nj_federal_match("AtlantiCare Regional Medical Center", f)$ccn),
               "310064")
})

test_that("Virtua Health Inc. is the ONLY LOW hospital bridge, and it is subtractable", {
  h <- a[a$distributed_to_hospital == "Yes", ]
  low <- h[h$determination_confidence == "LOW", ]
  expect_equal(unique(low$awardee), "Virtua Health Inc.")
  expect_equal(sum(low$amount), 3150255)
  expect_true(all(low$basis_type == "GENERAL_KNOWLEDGE"))
  expect_equal(nrow(nj_federal_match("Virtua Health Inc.")), 0L)
  others <- h[h$awardee != "Virtua Health Inc.", ]
  expect_true(all(others$basis_type == "ORG_WEBSITE"))
})

test_that("a site CCN is the site's, never the corporation's first", {
  expect_equal(a$ccn[a$site %in% "Hackettstown Medical Center"], "310115")
  expect_equal(a$ccn[a$site %in% "Newton Medical Center"], "310028")
  # multi-hospital corporations with no site cite no single CCN
  expect_true(all(is.na(a$ccn[a$awardee == "HMH Hospitals Corporation"])))
  expect_true(all(is.na(a$ccn[a$awardee == "Capital Health System, Inc."])))
})

test_that("the association's affiliate is IN_KIND, and 'pre-hospital' is not a hospital", {
  hret <- a[a$awardee == NJ_ASSOCIATION, ]
  expect_equal(hret$flow_type, "IN_KIND_BENEFIT")
  expect_equal(hret$distributed_to_hospital, "No")
  amb <- a[a$awardee == "Atlantic Ambulance Corporation", ]
  expect_equal(amb$flow_type, "NON_HOSPITAL")
})

test_that("the unstated-form rows are one-directional and queued", {
  fb <- a[!is.na(a$flag_reason) & a$flag_reason == "RECIPIENT_TYPE_INFERRED", ]
  expect_equal(nrow(fb), 35L)
  expect_equal(sum(fb$amount), 11964249)
  expect_true(all(fb$distributed_to_hospital == "No"))
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       show_col_types = FALSE)
  expect_true(all(c("NJ_RECIPIENT_FORM_NOT_STATED", "NJ_VIRTUA_PARENT_BRIDGE") %in%
                    q$question_id))
})

test_that("the committed file is this build", {
  expect_equal(committed$awardee, a$awardee)
  expect_equal(committed$amount, a$amount)
  expect_equal(committed$recipient_type, a$recipient_type)
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
})

test_that("the watch fires on a new RHTP award headline and on a roster link", {
  news <- paste(readLines(here::here(NJ_PROBE_PAGES$file[2]), warn = FALSE),
                collapse = "\n")
  rhtp <- paste(readLines(here::here(NJ_PROBE_PAGES$file[1]), warn = FALSE),
                collapse = "\n")
  expect_silent(nj_assert_watch(news, rhtp))
  news2 <- sub("</body>", paste0("<a href='/health/news/2026/approved/20261001a.shtml'>",
                                 "New Jersey Awards Second Round of Rural Health ",
                                 "Transformation Grants</a></body>"), news)
  expect_error(nj_assert_watch(news2, rhtp), "NEW RHTP AWARD RELEASE")
  rhtp2 <- sub("</body>", "<a href='documents/njrht-round-2.pdf'>x</a></body>", rhtp)
  expect_error(nj_assert_watch(news, rhtp2), "links a document")
})

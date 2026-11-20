# test_03cx_wi_year1_awardees.R ------------------------------------------------
# Wisconsin DHS's first award tables (session 121, owner ruling): INTENTS,
# typed on CMS WI enrolment. Offline, against the committed archive.

suppressMessages(source(here::here("R", "03cx_wi_year1_awardees.R")))

wi <- readr::read_csv(here::here(WIA_CSV), col_types = readr::cols(.default = "c"),
                      progress = FALSE)
wi$amount_n <- as.numeric(wi$amount)

test_that("the archived tables parse to every printed total and count", {
  p <- wia_parse()
  expect_true(wia_assert_tables(p))
  expect_equal(nrow(p), 138L)
  expect_equal(round(sum(p$amount), 2), 149331289.71)
  expect_equal(round(sum(p$amount[p$page != "implementation"]), 2), 69957931)
  # DHS's own prose is one cent below its implementation table, recorded.
  expect_equal(round(sum(p$amount[p$page == "implementation"]), 2), 79373358.71)
})

test_that("the committed file is the build: 138 rows, every one an intent", {
  expect_equal(nrow(wi), 138L)
  expect_equal(round(sum(wi$amount_n), 2), 149331289.71)
  expect_true(all(wi$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(grepl("AMOUNT_PRELIMINARY", wi$flag_reason)))
  expect_true(all(wi$amount_confirmed == "No"))
  expect_true(all(wi$budget_period == "1"))
  expect_true(all(wi$cms_review == "SUBJECT_TO_CMS_REVIEW"))
})

test_that("hospital rows: 39 / $32,216,238, and every MEDIUM one carries a CCN", {
  h <- wi[wi$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 39L)
  expect_equal(sum(h$amount_n), 32216238)
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_true(all(!is.na(h$ccn[h$determination_confidence == "MEDIUM"])))
  expect_false(any(wi$determination_confidence == "HIGH"))
  gk <- h[h$basis_type %in% "GENERAL_KNOWLEDGE", ]
  expect_equal(nrow(gk), 9L)
  expect_equal(sum(gk$amount_n), 6424244)
  expect_equal(sum(h$amount_n[h$determination_confidence == "LOW"]), 9167667)
})

test_that("state agencies are state agencies: never hospitals, never vendors", {
  s <- wi[wi$recipient_type == "STATE_AGENCY", ]
  expect_equal(nrow(s), 5L)
  expect_equal(round(sum(s$amount_n), 2), 21083727.35)
  expect_true(all(s$distributed_to_hospital == "No"))
  expect_false(any(s$spend_category %in% c("CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR")))
})

test_that("Ascension Wisconsin is a system parent, not Midwest Orthopedic's DBA", {
  a <- wi[startsWith(wi$awardee, "Ascension Wisconsin"), ]
  expect_equal(nrow(a), 3L)
  expect_true(all(is.na(a$ccn)))
  expect_true(all(a$basis_type == "GENERAL_KNOWLEDGE" & a$determination_confidence == "LOW"))
})

test_that("a county department is not bridged to its county's hospital enrolment", {
  expect_equal(wi$recipient_type[wi$awardee == "Wood County Health Department"],
               "LOCAL_GOVT_OR_PUBLIC_HEALTH")
  f <- wi[wi$awardee == "Fond du Lac County", ]
  expect_equal(f$ccn, "524025")
  expect_equal(f$determination_confidence, "LOW")
})

test_that("summary calls follow the strict coding on every hospital row", {
  expect_equal(sum(wi$amount_n[wi$summary_hospital_call == "HOSPITAL"]), 32216238)
})

# test_03bk_umms_system_form.R ------------------------------------------------
# Session 73. UMMS typed HOSPITAL_OR_SYSTEM on its OWN stated form. The tests
# that carry the weight are the limits: the form rests on the archived page,
# the row carries no CCN, and nothing else in Maryland moved.

source(here::here("R", "03bk_umms_system_form.R"))

md <- umms_read_raw()
u  <- md[md$awardee == UMMS_AWARDEE, ]

test_that("the archived page states the form, and its digest is in the manifest", {
  expect_silent(umms_assert_source())
  sha <- digest::digest(file = here::here(UMMS_ARCHIVE), algo = "sha256")
  man <- readLines(here::here("data/evidence/MD/MANIFEST.txt"))
  expect_true(any(grepl(paste0("^", sha, "  ", basename(UMMS_ARCHIVE)), man)))
  # a page that stopped saying it would stop the overlay
  expect_error(umms_assert_source("University of Maryland Medical System is a university"),
               "no longer states")
})

test_that("UMMS is on no enrolment, and its eight members are, as recorded", {
  expect_silent(umms_assert_not_enrolled())
  expect_equal(nrow(UMMS_ENROLLED_MEMBERS), 8L)
})

test_that("the row: HOSPITAL_OR_SYSTEM, DIRECT/Yes, ORG_WEBSITE at MEDIUM, NO ccn", {
  expect_equal(nrow(u), 1L)
  expect_equal(as.numeric(u$amount), 4020144)
  expect_equal(u$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(u$flow_type, "DIRECT")
  expect_equal(u$distributed_to_hospital, "Yes")
  expect_equal(u$hospital_attribution, "NAMED_HOSPITAL")
  expect_equal(u$basis_type, "ORG_WEBSITE")
  expect_equal(u$determination_confidence, "MEDIUM")   # HIGH needs a CCN match
  expect_equal(u$ccn, "")
  expect_match(u$determination_basis, UMMS_TAG, fixed = TRUE)
  for (b in UMMS_ENROLLED_MEMBERS$ccn) expect_match(u$determination_basis, b, fixed = TRUE)
  expect_match(u$determination_basis, "PRIOR BASIS: Recipient name rule", fixed = TRUE)
})

test_that("the overlay is idempotent and the committed file carries it on one row only", {
  # Pinned against the committed md_year1_awardees.csv, not a historical
  # commit: a shallow clone (every cloud session) has no 0412b2f to read.
  expect_identical(umms_overlay(md, empty = ""), md)
  expect_equal(nrow(md), 41L)
  pinned <- c(
    state                    = "MD",
    row_no                   = "33",
    amount                   = "4020144",
    recipient_type           = "HOSPITAL_OR_SYSTEM",
    distributed_to_hospital  = "Yes",
    recipient_confirmed      = "Yes",
    amount_confirmed         = "No",
    fiscal_year              = "FY2026",
    validation_source_type   = "NOTICE_OF_INTENT_TO_AWARD",
    recipient_type_source    = "DERIVED_FROM_NAME",
    determination_confidence = "MEDIUM",
    flag_reason              = "",
    award_pool               = "PILLAR2_TRANSFORMATION_FUND",
    budget_period            = "BP1",
    flow_type                = "DIRECT",
    hospital_benefiting      = "Yes",
    hospital_attribution     = "NAMED_HOSPITAL",
    ccn                      = "",
    basis_type               = "ORG_WEBSITE",
    verified_by              = "owner instruction, session 73",
    source_archive_path      =
      "data/evidence/MD/2026-08-29_mdh_pillar2_transformation_fund_bp1_award_offers.pdf"
  )
  for (f in names(pinned)) expect_identical(u[[f]], pinned[[f]], label = f)
  # the overlay's tag is on the UMMS row and on no other Maryland row
  tagged <- md$awardee[grepl(UMMS_TAG, md$determination_basis, fixed = TRUE)]
  expect_identical(tagged, UMMS_AWARDEE)
  # the other 40 rows: the pre-session-73 hospital figure, unchanged
  others <- md[md$awardee != UMMS_AWARDEE & md$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(others), 8L)
  expect_equal(sum(as.numeric(others$amount)), 23661116)
})

test_that("Maryland's hospital figure: 8 / $23,661,116 -> 9 / $27,681,260", {
  h <- md[md$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 9L)
  expect_equal(sum(as.numeric(h$amount)), 27681260)
})

test_that("the queue row keeps the other three open and records the settlement", {
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE)
  r <- q[q$question_id == "AHC_STRING_NAMES_NO_ENROLLED_ENTITY", ]
  expect_equal(r$queue_status, "OPEN")
  expect_false(grepl("Maryland Medical System", r$row_key, fixed = TRUE))
  expect_match(r$row_key, "UAB Montgomery", fixed = TRUE)
  expect_match(r$row_key, "OHSU Casey Eye Institute", fixed = TRUE)
  expect_match(r$row_key, "MEDIC", fixed = TRUE)
  expect_match(r$why_it_is_open, "SESSION 73, UMMS SETTLED AT OPTION (c)", fixed = TRUE)
})

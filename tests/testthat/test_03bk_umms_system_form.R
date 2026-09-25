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

test_that("the overlay is idempotent and moves exactly one Maryland row", {
  expect_identical(umms_overlay(md, empty = ""), md)
  orig <- readr::read_csv(
    I(paste(system2("git", c("show", "0412b2f:data/reference/md_year1_awardees.csv"),
                   stdout = TRUE), collapse = "\n")),
    col_types = readr::cols(.default = "c"), na = character(), trim_ws = FALSE)
  expect_equal(nrow(orig), nrow(md))
  diff_rows <- which(apply(orig != md, 1, any))
  expect_equal(md$awardee[diff_rows], UMMS_AWARDEE)
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

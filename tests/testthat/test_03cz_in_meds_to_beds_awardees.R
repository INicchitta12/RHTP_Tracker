# test_03cz_in_meds_to_beds_awardees.R ---------------------------------------
# Session 121: Indiana's Meds-to-Beds awardees, twenty hospitals named on IDOH's
# map, no amount anywhere. Read the row count.

suppressWarnings(suppressMessages(source(here::here("R", "03cz_in_meds_to_beds_awardees.R"))))

test_that("twenty hospitals, 13 implementation + 7 planning, all at $0", {
  expect_silent(mtb_assert())
  d <- mtb_awardees()
  expect_equal(nrow(d), 20L)
  expect_true(all(is.na(d$amount)))
  expect_true(all(d$distributed_to_hospital == "Yes"))
  expect_equal(sum(d$award_type == "Planning and Implementation"), 13L)
  p <- rhtp_hospital_dollar_partition(d)
  expect_equal(p$rows, 20L)
  expect_equal(p$dollars, 0)
})

test_that("16 exact CMS IN enrolments (MEDIUM) and 4 hand-read bridges (LOW); a CCN on every row", {
  d <- mtb_awardees()
  expect_equal(sum(d$determination_confidence == "MEDIUM"), 16L)
  expect_setequal(d$awardee[d$determination_confidence == "LOW"],
                  c("Adams Memorial Hospital", "Marion Health MGH Campus",
                    "Greene County General Hosptial", "St. Elizabeth Healthcare Dearborn Hospital"))
  expect_true(all(grepl("^[0-9]{6}$", d$ccn)))
  expect_false(any(d$determination_confidence == "HIGH"))
})

test_that("the committed file is this build, and the archived map is the one read", {
  committed <- readr::read_csv(MTB_CSV, show_col_types = FALSE, col_types = readr::cols(.default = "c"))
  expect_equal(committed$awardee, mtb_awardees()$awardee)
  expect_equal(digest::digest(file = here::here(MTB_MAP), algo = "sha256"), MTB_MAP_SHA)
  # a roster that loses a hospital is refused
  expect_error(mtb_assert(MTB_ROSTER[-1, ]), "20 hospitals")
})

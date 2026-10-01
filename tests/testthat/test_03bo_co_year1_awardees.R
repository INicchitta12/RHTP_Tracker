# test_03bo_co_year1_awardees.R ---------------------------------------------
# Colorado's HCPF roster, read offline from data/evidence/CO/ (session 82).

library(testthat)
source(here::here("R", "03bo_co_year1_awardees.R"))

d <- co_parse_roster()
a <- co_year1_awardees(d)
built <- readr::read_csv(CO_CSV, show_col_types = FALSE,
                         col_types = readr::cols(ccn = "c", site = "c"))

test_that("the roster is 92 lines, $170,210,575.26, 91 distinct strings", {
  expect_silent(co_assert_roster(d))
  expect_equal(nrow(d), 92L)
  expect_equal(round(sum(d$amount), 2), 170210575.26)
  expect_equal(sum(d$awardee == "Banner Health Foundation"), 2L)
})

test_that("the release total is stated beside the roster, never substituted", {
  expect_silent(co_assert_releases())
  expect_equal(round(sum(d$amount) - CO_RELEASE_TOTAL, 2), 623394.26)
  # Every line the state prints is in the file: nothing dropped on arithmetic.
  expect_true(any(grepl("Every Child Pediatrics", a$awardee, fixed = TRUE)))
  expect_equal(nrow(a), 92L)
})

test_that("hospital districts are typed on the enrolment, not the name", {
  expect_silent(co_assert_typing(a))
  no_h <- c("Walsh Hospital District", "West Custer County Hospital District",
            "Lake Fork Health Services District", "Telluride Regional Medical Center")
  expect_true(all(a$distributed_to_hospital[a$awardee %in% no_h] == "No"))
  yes_h <- c("Haxtun Hospital District", "Rangely Hospital District",
             "Salida Hospital District", "Southeast Colorado Hospital District")
  expect_true(all(a$distributed_to_hospital[a$awardee %in% yes_h] == "Yes"))
  expect_true(all(a$determination_confidence[a$awardee %in% yes_h] == "MEDIUM"))
})

test_that("foundations follow §10.2: Banner by its parent, Valley Citizens' by its enrolment", {
  b <- a[a$awardee == "Banner Health Foundation", ]
  expect_true(all(b$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(b$determination_confidence == "LOW"))
  expect_true(all(b$basis_type == "GENERAL_KNOWLEDGE"))
  v <- a[grepl("^Valley Citizens", a$awardee), ]
  expect_equal(v$ccn, "061301")
  expect_equal(v$determination_confidence, "MEDIUM")
})

test_that("the two San Luis Valley lines carry their site and its own CCN", {
  s <- a[!is.na(a$site), ]
  expect_equal(sort(s$ccn), c("060008", "061308"))
  expect_true(all(grepl("^Lutheran Hospital Association", s$awardee)))
})

test_that("the committed file is what the builder writes", {
  expect_equal(nrow(built), nrow(a))
  expect_equal(built$awardee, a$awardee)
  expect_equal(built$amount, a$amount)
  expect_equal(built$distributed_to_hospital, a$distributed_to_hospital)
  h <- built[built$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 36L)
  expect_equal(sum(h$amount), 86693159)
  expect_false(any(h$determination_confidence == "HIGH"))
})

test_that("a moved roster trips the watch", {
  raw <- paste(readLines(here::here(CO_SOURCES$file[1]), warn = FALSE), collapse = "\n")
  expect_silent(co_assert_roster_unchanged(raw))
  more <- sub("Hospital and Clinics - $1,301,814</li>",
              "Hospital and Clinics - $1,301,814</li><li>New Rural Clinic - $1,000</li>",
              raw, fixed = TRUE)
  expect_false(identical(more, raw))
  expect_error(co_assert_roster_unchanged(more), "ROSTER MOVED")
})

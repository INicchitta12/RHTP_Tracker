# test_03cj_ms_round2_awardees.R -----------------------------------------------
# Session 108. Mississippi: the Governor's 2026-10-21 roster, 60 awards,
# $32,606,496.32, typed on CMS's MS enrolment files.

suppressWarnings(suppressMessages(source(here::here("R", "03cj_ms_round2_awardees.R"))))

d <- ms2_parse()
a <- ms2_awardees(d)
committed <- readr::read_csv(MS2_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the 60 awards reconcile to the release's own figure, to the cent", {
  expect_silent(ms2_assert_roster(d))
  expect_equal(nrow(d), 60L)
  expect_equal(round(sum(d$amount), 2), 32606496.32)
  expect_equal(as.integer(table(factor(d$section, levels = MS2_SECTIONS$heading))),
               c(20L, 4L, 12L, 21L, 3L))
  # A multi-county field parses (the county anchor takes "Counties").
  expect_true(any(grepl("Counties$", d$county)))
})

test_that("a numbered line of an unknown shape is refused, not dropped", {
  l <- ms2_text()
  i <- grep("^1\\. Tippah County Hospital", l)
  l[i] <- "1. Tippah County Hospital $267,954.00 To recruit."
  expect_error(ms2_parse(l), "REFUSED")
})

test_that("the three EmPATH units are typed to their host hospitals", {
  expect_silent(ms2_assert_typing(a))
  e <- a[a$awardee %in% MS2_EMPATH, ]
  expect_equal(nrow(e), 3L)
  expect_true(all(e$distributed_to_hospital == "Yes"))
  expect_equal(e$ccn[e$awardee == "Merit Health Central/Jackson MHA, LLC"], "250072")
  expect_equal(e$ccn[e$awardee == "Memorial Hospital at Gulfport"], "250019")
  g <- e[grepl("Greenwood", e$awardee), ]
  expect_equal(g$ccn, "250099")
  expect_equal(g$determination_confidence, "LOW")
  expect_equal(g$recipient_subtype, "ACADEMIC_HEALTH_CENTER")
})

test_that("the hospital figure, and what subtracts from it", {
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 31L)
  expect_equal(round(sum(h$amount), 2), 22986995.92)
  expect_equal(round(sum(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"]), 2), 219120)
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_false(any(a$determination_confidence == "HIGH"))
  # Session 109, owner ruling (c): a hospital's EMS department named under the
  # hospital's own legal name is the hospital (code the recipient, §0.3a); the
  # WVU Eye Institute precedent covers university units only.
  m <- a[a$awardee == "Magnolia Regional Health Center EMS", ]
  expect_equal(m$distributed_to_hospital, "Yes")
  expect_equal(m$ccn, "250009")
  expect_equal(m$determination_confidence, "LOW")
  expect_match(m$recipient_type_source, "COVERS UNIVERSITY UNITS ONLY", fixed = TRUE)
})

test_that("SESSION 109, ruling (d): both rounds read 'Memorial Health System' as a system parent", {
  expect_silent(ms2_assert_r1_agrees())
  r1 <- readr::read_csv(here::here(MS2_R1_CSV), show_col_types = FALSE)
  r1 <- r1[r1$awardee == "Memorial Health System", ]
  expect_equal(nrow(r1), 12L)
  expect_true(all(r1$determination_confidence == "LOW"))
  expect_true(all(r1$basis_type == "GENERAL_KNOWLEDGE"))
  expect_equal(sum(r1$amount), 15041222)
  r2 <- a[a$awardee == "Memorial Health System", ]
  expect_equal(r2$determination_confidence, "LOW")
  expect_equal(r2$basis_type, "GENERAL_KNOWLEDGE")
})

test_that("the committed file is what the builder produces", {
  expect_equal(committed$awardee, a$awardee)
  expect_equal(round(committed$amount, 2), round(a$amount, 2))
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
})

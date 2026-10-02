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

test_that("RRR and CDM are over the $10M line and are NOT written", {
  expect_false(any(OKN_ROSTERS$written[OKN_ROSTERS$key %in% c("rrr", "cdm")]))
  expect_true(all(OKN_ROSTERS$total[OKN_ROSTERS$key %in% c("rrr", "cdm")] > 1e7))
  d <- readr::read_csv(OKN_CSV, show_col_types = FALSE)
  expect_equal(unique(d$award_pool), "Expanding Care: Doulas Program")
  expect_equal(d$amount, okn_doulas()$amount)
})

test_that("R/03t still trips on RRR and CDM, and no longer on Doulas", {
  suppressWarnings(suppressMessages(source(here::here("R", "03t_ok_year1_awardees.R"))))
  expect_false("Expanding Care: Doulas Program" %in% OK_PENDING_OPPORTUNITIES)
  expect_true(all(c("Rural Regional Reorientation (RRR) Program",
                    "Chronic Disease Management Program") %in% OK_PENDING_OPPORTUNITIES))
})

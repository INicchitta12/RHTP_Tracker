# test_03cf_md_labor_awardees.R -----------------------------------------------
# Session 104. Maryland: MD Labor's RHTP workforce roster, 38 lines, typed on
# CMS's MD hospital enrolment. "$16.4 million" is the Transformation Fund's size.

suppressWarnings(suppressMessages(source(here::here("R", "03cf_md_labor_awardees.R"))))

md <- mdl_rows()
committed <- readr::read_csv(MDL_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", .default = readr::col_guess()))

test_that("the roster is read whole: 38 lines, 34 organisations, $13,965,196", {
  expect_silent(mdl_assert_source())
  expect_silent(mdl_assert_federal())
  expect_equal(nrow(md), 38L)
  expect_equal(length(unique(md$awardee)), 34L)
  expect_equal(sum(md$amount), 13965196)
})

test_that("$16.4M is the Transformation Fund's size, never an award row", {
  expect_false(any(abs(md$amount - MDL_TF_SIZE) < 1))
  expect_true(all(grepl("not the roster's total", md$amount_basis)))
  rise <- md[grepl("RISE", md$award_pool), ]
  expect_equal(sum(rise$amount), 10636769)
  expect_true(all(grepl("Transformation Fund", rise$award_pool)))
})

test_that("hospital rows are typed on CMS MD enrolment", {
  h <- md[md$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 9L)
  expect_equal(sum(h$amount), 3574030)
  expect_true(all(h$hospital_attribution == "NAMED_HOSPITAL"))
  expect_equal(sort(unique(stats::na.omit(h$ccn))), c("210005", "210019", "210035", "210039"))
  low <- h[h$determination_confidence == "LOW", ]
  expect_equal(nrow(low), 4L)
  expect_equal(sum(low$amount), 1999897)
  expect_match(h$determination_basis[h$awardee == "Meritus Health Foundation"], "FOUNDATION RULE")
  expect_false(any(md$determination_confidence == "HIGH"))
})

test_that("the physician group and the FQHC are not hospitals", {
  expect_equal(md$recipient_type[md$awardee == "CalvertHealth Medical Group"], "PHYSICIAN_PRACTICE")
  expect_equal(md$recipient_type[grepl("^Choptank", md$awardee)], "FQHC_OR_RHC")
})

test_that("the committed file is what the builder produces", {
  expect_equal(committed$awardee, md$awardee)
  expect_equal(committed$amount, md$amount)
  expect_equal(committed$distributed_to_hospital, md$distributed_to_hospital)
})

test_that("the probe half trips on a changed line and not on the archive", {
  raw <- mdl_raw()
  expect_null(md_labor_live_finding(raw))
  expect_match(md_labor_live_finding(sub("$181,315", "$181,316", raw, fixed = TRUE)),
               "ROSTER CHANGED")
  expect_match(md_labor_live_finding("<p>none</p>"), "no Grantee")
})

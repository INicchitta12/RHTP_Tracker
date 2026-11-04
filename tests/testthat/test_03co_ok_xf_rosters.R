# test_03co_ok_xf_rosters.R ---------------------------------------------------
# Session 112: Oklahoma's five new priced rosters from the moved Funding
# Recipients page's fragments, read offline from recheck/2026-11-02/OK/.

suppressWarnings(suppressMessages(source(here::here("R", "03co_ok_xf_rosters.R"))))
t <- okx_build_tables()

test_that("five rosters, each its own file, at the fragments' own figures", {
  expect_equal(vapply(t, nrow, integer(1)),
               c(lung_screening = 11L, telestroke = 1L, closed_loop = 1L,
                 grow_your_own = 5L, transportation = 11L))
  expect_equal(sum(t$lung_screening$amount), 1873344)
  expect_equal(sum(t$transportation$amount), 2260858.97)
  for (k in names(t)) {
    built <- readr::read_csv(okx_csv(k), show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c"))
    expect_equal(built$awardee, t[[k]]$awardee, info = k)
    expect_equal(built$amount, t[[k]]$amount, info = k)
    expect_equal(built$hospital_attribution, t[[k]]$hospital_attribution, info = k)
  }
})

test_that("lung screening: the hospitals are the subrecipients; SSM groups are pools; * lines are intents", {
  l <- t$lung_screening
  expect_true(all(l$distributed_to_hospital == "Yes"))
  expect_true(all(l$flow_type == "DIRECT"))
  expect_true(all(grepl("^Oklahoma Hospital Association", l$intermediary_name)))
  n <- l[l$hospital_attribution == "NAMED_HOSPITAL", ]
  p <- l[l$hospital_attribution == "POOL_NAMED_HOSPITALS", ]
  expect_equal(c(nrow(n), sum(n$amount)), c(9, 1532736))
  expect_equal(c(nrow(p), sum(p$amount)), c(2, 340608))
  expect_true(all(startsWith(p$awardee, "SSM Affiliates:")))
  expect_true(all(grepl("MULTI_RECIPIENT_FIELD", p$flag_reason)))
  pre <- l[grepl("AMOUNT_PRELIMINARY", l$flag_reason), ]
  expect_setequal(pre$awardee, c(p$awardee, "Integris Enid"))
  expect_true(all(pre$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_equal(l$ccn[l$awardee == "Duncan Regional Hospital"], "370023")
  expect_equal(l$determination_confidence[l$awardee == "Duncan Regional Hospital"], "MEDIUM")
  expect_true(all(l$determination_confidence[l$awardee != "Duncan Regional Hospital"] == "LOW"))
})

test_that("no other roster reaches a hospital; sites and cohorts are not rows", {
  for (k in setdiff(names(t), "lung_screening")) {
    expect_true(all(t[[k]]$distributed_to_hospital == "No"), info = k)
  }
  expect_equal(t$telestroke$recipient_type, "UNIVERSITY_OR_AHC")
  expect_equal(t$closed_loop$flow_type, "IN_KIND_BENEFIT")
  expect_equal(t$closed_loop$hospital_benefiting, "Yes")
  expect_false(any(grepl("Atoka County Medical Center", t$telestroke$awardee)))
})

test_that("OK CHW Expansion: 48 rows at no amount, 29 typed hospitals, AVEM Unclear (session 114)", {
  a <- okx_chw_rows()
  expect_silent(okx_chw_assert_rows(a))
  expect_equal(nrow(a), 48L)
  expect_true(all(is.na(a$amount)))
  expect_equal(sum(a$distributed_to_hospital == "Yes"), 29L)
  expect_equal(sum(a$recipient_type == "FQHC_OR_RHC"), 18L)
  av <- a[a$awardee == "AVEM Health Partners", ]
  expect_equal(av$distributed_to_hospital, "Unclear")
  expect_equal(av$recipient_type, "HOSPITAL_AFFILIATED_ENTITY")
  committed <- readr::read_csv(here::here(okx_csv("chw")), col_types = readr::cols(.default = "c"))
  expect_equal(committed$awardee, a$awardee)
  expect_false("cms_enrolment_match" %in% names(committed))
  # The pool is on no row: R/07 carries it, at the Q3 obligated figure.
  src <- paste(readLines(here::here("R", "07_summary_calls.R")), collapse = "\n")
  expect_true(grepl('"OK_CHW_EXPANSION", "OK_CHW", "OK"', src, fixed = TRUE))
  expect_true(grepl("4460162.93", src, fixed = TRUE))
  # A dollar on the fragment is a re-read, not a silent pass.
  expect_false(grepl("\\$[0-9]", okx_text(OKX_CHW_SLUG)))
})

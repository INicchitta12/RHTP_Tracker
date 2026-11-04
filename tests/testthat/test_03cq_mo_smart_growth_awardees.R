# test_03cq_mo_smart_growth_awardees.R -- Missouri's Smart Growth contingent
# roster (session 114, owner ruling: intents pending CMS approval). Offline.
source(here::here("R", "03cq_mo_smart_growth_awardees.R"))

test_that("25 rows, $39,400,820.55, 2 CMS-approved, 23 intents", {
  a <- mosg_rows()
  expect_silent(mosg_assert_rows(a))
  expect_equal(nrow(a), 25L)
  expect_equal(round(sum(a$amount), 2), 39400820.55)
  expect_equal(sum(a$cms_approval == "APPROVED_BY_CMS"), 2L)
  expect_setequal(a$awardee[a$cms_approval == "APPROVED_BY_CMS"],
                  c("Missouri Delta Medical Center", "Heartland Regional Medical Center"))
  expect_true(all(a$validation_source_type[a$cms_approval == "PENDING_CMS_APPROVAL"] == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(grepl("AMOUNT_PRELIMINARY", a$flag_reason[a$cms_approval == "PENDING_CMS_APPROVAL"])))
  expect_true(all(grepl("26 rural providers", a$note)))
})

test_that("14 hospital rows / $31,862,169.80, each on a CMS MO hospital CCN; OCH is not one", {
  a <- mosg_rows()
  h <- a[a$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(h), 14L)
  expect_equal(round(sum(h$amount), 2), 31862169.80)
  expect_true(all(grepl("^26[0-9]{4}$", h$ccn)))
  expect_false("Ozarks Community Hospital" %in% h$awardee)
  expect_false(any(a$determination_confidence == "HIGH"))
})

test_that("the probe trips on a re-pricing or a new CMS approval, not on the archive", {
  f <- here::here(MOSG_ROSTER)
  b <- readBin(f, "raw", file.size(f))
  expect_true(mosg_assert_live(b))
  t <- rawToChar(b)
  expect_error(mosg_assert_live(charToRaw(sub("Cameron Regional Medical Center", "Cameron Regional Medical Center (approved by CMS)", t, fixed = TRUE))),
               "newly approved: Cameron")
  expect_error(mosg_assert_live(charToRaw(sub("$922,262.25", "$922,262.26", t, fixed = TRUE))), "moved")
})

test_that("the committed file is what the builder produces", {
  committed <- readr::read_csv(here::here(MOSG_CSV), col_types = readr::cols(.default = "c"))
  a <- mosg_rows()
  expect_equal(committed$awardee, a$awardee)
  expect_equal(as.numeric(committed$amount), a$amount)
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
})

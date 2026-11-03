# Session 113: the 10-14 edition of CMS's RHTP Obligated Funds Report, parsed
# from the committed poppler line extract, and its diff against 10-08.

source(here::here("R", "00e_cms_obligation_report_v2.R"))

ref <- function(f) readr::read_csv(here::here("data", "reference", f), show_col_types = FALSE)

test_that("the 10-14 edition is archived beside the 10-08 one, never over it", {
  expect_silent(obl_assert_archive())          # 10-08, unchanged
  expect_silent(obl2_assert_archive())         # 10-14
  man <- readLines(here::here(OBL_DIR, "RHTP-Obligated-Funds-20261014.pdf.manifest.txt"))
  expect_true(any(grepl(OBL2_SHA256, man, fixed = TRUE)))
  expect_true(file.exists(OBL2_LINES_SRC))
})

test_that("the 10-14 parse passes every R/00c data assertion", {
  p <- obl2_parse()
  expect_silent(obl2_assert(p))
  expect_equal(nrow(p$states), 50L)
  # The reader's lone-glyph join left no empty bullet.
  expect_false(any(stringr::str_trim(p$bullets$description_raw) == ""))
})

test_that("the diff is Oregon's Tribal capital bullets and nothing else", {
  d <- ref("cms_obligations_bp1_diff_10082026_20261014.csv")
  expect_equal(nrow(d), 13L)
  expect_true(all(d$level == "LINE" & d$state == "OR"))
  expect_true(all(d$initiative == "Initiative 5: Tribal" &
                    d$category == "Capital Expenditures and Infrastructure"))
  expect_equal(sum(d$change == "ONLY_IN_10082026"), 9L)
  expect_equal(sum(d$amount_10082026, na.rm = TRUE), 16181322.70, tolerance = 0.005)
  expect_equal(sum(d$change == "ONLY_IN_20261014"), 4L)
  expect_equal(sum(d$amount_20261014, na.rm = TRUE), 2426419.42, tolerance = 0.005)
  # State totals are identical between editions.
  s1 <- ref("cms_obligations_bp1_state.csv"); s2 <- ref("cms_obligations_bp1_state_20261014.csv")
  expect_equal(s1$bp1_award, s2$bp1_award)
  expect_equal(s1$funds_put_to_work, s2$funds_put_to_work)
  expect_true(all(s1$report_date == as.Date("2026-10-08")))
  expect_true(all(s2$report_date == as.Date("2026-10-14")))
  # Oregon's one FAIL in the 10-08 checks is EXACT in the 10-14 checks.
  c2 <- ref("cms_obligations_bp1_checks_20261014.csv")
  or <- c2 %>% dplyr::filter(state == "OR", check == "BULLETS_TO_CATEGORY",
                             initiative == "Initiative 5: Tribal",
                             name == "Capital Expenditures and Infrastructure")
  expect_equal(or$status, "EXACT")
})

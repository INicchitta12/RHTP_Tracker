# test_03cm_ca_cha_reconciliation.R ------------------------------------------
# Session 111c. CHA's informal coding of HCAI's BP1 roster against ours. Pins
# the two reconciliations (hospital, CAH) to the exact rows that make each gap,
# and asserts the report moved nothing in ca_year1_awardees.csv.

source(here::here("R", "03cm_ca_cha_reconciliation.R"))

m <- cha_match()
r <- cha_reconciliation(m)
tot <- function(x, col) r[[col]][r$record_type == "TOTAL" & r$measure == x]

test_that("all 108 CHA lines match our 108 rows one to one", {
  expect_equal(nrow(m), 108L)
  expect_false(anyDuplicated(m$row_no) > 0)
  expect_false(anyDuplicated(m$cha_row) > 0)
  expect_equal(tot("all_lines", "ours_usd"), 138464043.97)
  expect_equal(tot("all_lines", "gap_usd"), 0)
})

test_that("hospital: ours $82,852,823.14 vs CHA $84,009,171.38, exactly two rows", {
  expect_equal(tot("hospital", "ours_usd"), 82852823.14)
  expect_equal(tot("hospital", "cha_usd"), 84009171.38)
  d <- r[r$record_type == "ROW_CALL_DIFFERS", ]
  expect_setequal(d$our_awardee, c("Providence Medical Foundation",
                                   "Community Health Partners"))
  expect_true(all(d$ours_value == "NOT_HOSPITAL" & d$cha_value == "HOSPITAL"))
  expect_equal(round(sum(d$amount), 2), 1156348.24)
  expect_equal(tot("hospital", "gap_usd"), round(sum(d$amount), 2))
})

test_that("CAH: ours $46,065,499.94 vs CHA $46,685,499.94, exactly Banner", {
  expect_equal(tot("cah", "ours_usd"), 46065499.94)
  expect_equal(tot("cah", "cha_usd"), 46685499.94)
  d <- r[r$record_type == "ROW_CAH_DIFFERS", ]
  expect_equal(d$our_awardee, "Banner Health Foundation")
  expect_equal(d$amount, 620000)
  expect_equal(tot("cah", "gap_usd"), 620000)
})

test_that("CHA's state-rural figure is recorded and compared with nothing", {
  expect_equal(tot("rural_hospital", "cha_usd"), 63879556.38)
  expect_true(is.na(tot("rural_hospital", "ours_usd")))
  expect_equal(tot("rural_hospital", "comparable"), "NO")
})

test_that("the committed CSV is what the script builds", {
  committed <- readr::read_csv(CHA_RECON_CSV, show_col_types = FALSE,
                               col_types = readr::cols(.default = "c"))
  built <- r %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  expect_equal(nrow(committed), nrow(built))
  expect_setequal(committed$cha_name[!is.na(committed$cha_name)],
                  built$cha_name[!is.na(built$cha_name)])
})

test_that("the report changes no CA row or call", {
  ours <- our_rows()
  expect_equal(sum(ours$summary_hospital_call == "HOSPITAL"), 59L)
  expect_equal(round(sum(ours$amount[ours$hospital_attribution ==
                                       "NAMED_HOSPITAL"]), 2), 82852823.14)
})

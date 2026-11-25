# test_09b_session124.R --------------------------------------------------------
# SESSION 124: three R/09b rules. (1) Texas "RHTCMS100F-27" records are the part
# of a multi-year Rural Texas Strong award outside the Year 1 subset HHSC's list
# prints, and are held. (2) Indiana Meds-to-Beds subawards pair only to the
# Meds-to-Beds roster, never to GROW. (3) A hand pairing's amount must be the
# FSRS record's own amount.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "09b_fsrs_award_source.R"))

test_that("the Texas -27 remainder is recognised, and only in Texas", {
  expect_true(fsrs_tx_remainder("TX", "RHTCMS100F-27_4.1 FUNDING PLAN"))
  expect_false(fsrs_tx_remainder("TX", "RHTCMS100F-26_4.1 FUNDING PLAN"))
  expect_false(fsrs_tx_remainder("OK", "RHTCMS100F-27_4.1 FUNDING PLAN"))
  expect_false(fsrs_tx_remainder("TX", NA_character_))
})

recs <- readr::read_csv(here::here("data/reference/fsrs_subaward_records.csv"),
                        col_types = readr::cols(.default = "c"))
held <- readr::read_csv(here::here("data/reference/fsrs_held.csv"),
                        col_types = readr::cols(.default = "c"))
recon <- readr::read_csv(here::here("data/reference/fsrs_reconciliation.csv"),
                         col_types = readr::cols(.default = "c"))

test_that("every TX -27 record is held, budget period 2, and never paired or written", {
  tx27 <- recs[recs$st == "TX" & grepl("RHTCMS100F-27", recs$description) &
                 recs$record_status != "REFILING_SUPERSEDED", ]
  expect_gt(nrow(tx27), 100)
  expect_true(all(tx27$record_status == "HELD_TX_NOT_YEAR1_SUBSET"))
  expect_true(all(tx27$budget_period == "2"))
  expect_true(all(tx27$fsrs_id %in% held$fsrs_id[held$status == "HELD_TX_NOT_YEAR1_SUBSET"]))
  expect_false(any(tx27$fsrs_id %in% recon$fsrs_id))
})

test_that("the Meds-to-Beds description routes Indiana subawards to IN_MTB only", {
  expect_true(fsrs_in_mtb("FEASIBILITY ANALYSIS FOR MEDS-TO-BEDS PROGRAM"))
  expect_false(fsrs_in_mtb("ORGANIZATION INCLUDED IN FINAL SUBMISSION OF RHTP I12 GROW GRANT PACKAGE"))
  mtb <- recs$fsrs_id[recs$st == "IN" & fsrs_in_mtb(recs$description) & recs$record_status == "CURRENT"]
  r <- recon[recon$fsrs_id %in% mtb, ]
  linked <- r$row_ids[!is.na(r$row_ids)]
  expect_false(any(grepl("IN_GROW", linked) & r$status[!is.na(r$row_ids)] == "PRICED_ZERO_ROW"))
  priced <- r[r$status == "PRICED_ZERO_ROW", ]
  expect_equal(nrow(priced), 11L)
  expect_true(all(grepl("^IN_MTB#", priced$row_ids)))
  expect_equal(sum(as.numeric(priced$amount)), 885195)
  # the eleven are in no GROW row's FSRS ids and no other file
  grow <- readr::read_csv(here::here("data/reference/in_grow_regional_awardees.csv"),
                          col_types = readr::cols(.default = "c"))
  ids <- unlist(strsplit(stats::na.omit(grow$fsrs_subaward_ids), ";"))
  expect_false(any(priced$fsrs_id %in% ids))
  m <- readr::read_csv(here::here("data/reference/in_meds_to_beds_awardees.csv"),
                       col_types = readr::cols(.default = "c"))
  expect_equal(sum(as.numeric(m$amount), na.rm = TRUE), 885195)
  expect_equal(sum(!is.na(m$amount) & as.numeric(m$amount) > 0), 11L)
})

test_that("a pairing whose printed amount is not its FSRS record's own amount is refused", {
  pr <- readr::read_csv(here::here(FSRS_PAIRINGS), col_types = readr::cols(.default = "c"))
  cur <- recs[recs$record_status == "CURRENT", c("fsrs_id", "amount")]
  j <- merge(pr, cur, by = "fsrs_id", suffixes = c("_pair", "_rec"))
  tol <- dplyr::coalesce(suppressWarnings(as.numeric(j$max_diff)), 0.005) + 0.005
  expect_true(all(abs(as.numeric(j$amount_pair) - as.numeric(j$amount_rec)) < tol))
})

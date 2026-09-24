# test_03bh_rcj_candidate_dispositions.R --------------------------------------
# The twenty-three RCJ candidate dispositions built by R/03bh. Reads the
# committed record table and reference files only -- no network, no quota.
#
# What these pin: that every live Tier 3 candidate in every one of the 23
# states is placed by exactly one group; that the committed CSVs are what the
# builder produces; that the prose agrees with its counts; and a handful of
# findings that a later session must not quietly lose.

library(testthat)

source(here::here("R", "03bh_rcj_candidate_dispositions.R"))

rt_live <- rhtp_record_table_live()
tables  <- dispo_build_all()

live_n <- function(st) sum(rt_live$award_tier %in% "SUBAWARD" & rt_live$state %in% st)


test_that("every one of the 23 states' live candidates is covered, exactly", {
  expect_setequal(names(tables), DISPO_STATES)
  for (st in DISPO_STATES) {
    expect_equal(sum(tables[[st]]$rcj_rows), live_n(st), info = st)
    expect_gt(live_n(st), 0)
  }
})

test_that("no state holding live candidates is left without a disposition file", {
  have <- toupper(sub("_rcj_candidate_disposition\\.csv$", "",
                      list.files(here::here("data", "reference"),
                                 pattern = "_rcj_candidate_disposition\\.csv$")))
  held <- unique(rt_live$state[rt_live$award_tier %in% "SUBAWARD"])
  expect_length(setdiff(held, have), 0)
})

test_that("the committed CSVs are what the builder produces", {
  for (st in DISPO_STATES) {
    committed <- readr::read_csv(dispo_csv_path(st), show_col_types = FALSE,
                                 col_types = readr::cols(.default = "c"))
    built <- tables[[st]] %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
    attr(built, "candidates") <- NULL
    expect_equal(names(committed),
                 c("state", "group", "rcj_rows", "rcj_amount_sum",
                   "disposition", "evidence"), info = st)
    expect_equal(committed$group, built$group, info = st)
    expect_equal(as.integer(committed$rcj_rows), as.integer(built$rcj_rows), info = st)
    expect_equal(committed$evidence, dplyr::coalesce(built$evidence, NA_character_), info = st)
  }
})

test_that("every table passes the prose rule", {
  for (st in DISPO_STATES) {
    expect_silent(rhtp_assert_disposition_prose(tables[[st]], st))
  }
})

test_that("the prose rule would catch a typed count", {
  d <- tables[["MN"]]
  d$evidence[1] <- "RCJ holds 3 Tier 3 candidates for Minnesota."
  expect_error(rhtp_assert_disposition_prose(d, "MN"), "disagrees")
})

test_that("an uncovered candidate fails the build, and so does a stale rule", {
  cands <- dispo_candidates("MN", rt_live)
  cands$engine_class <- "NAME_NOT_IN_FILE"
  cands$source_doc_title[1] <- "MN - 2026 - a document nobody has read"
  expect_error(dispo_hand_place(cands, "MN"), "no disposition covers")
  cands2 <- dispo_candidates("ND", rt_live)
  cands2$engine_class <- "NAME_NOT_IN_FILE"
  cands2 <- cands2[0, ]
  expect_error(dispo_hand_place(cands2, "ND"), "place no live candidate")
})

test_that("the engine never matches on anything looser than punctuation and case", {
  expect_equal(dispo_name_key("St. Joseph’s  Hospital, Inc."), "st joseph s hospital inc")
  # Maryland's two spellings of one county health department stay apart.
  expect_false(dispo_name_key("Charles County Health Department") ==
                 dispo_name_key("Charles County Department of Health"))
})


# -- pinned findings -------------------------------------------------------------

test_that("Florida: every RCJ candidate is an award in the file; one file award RCJ lacks", {
  fl <- tables[["FL"]]
  expect_equal(sum(fl$rcj_rows[fl$disposition == "RHTP_SUBAWARD_IN_FILE"]), live_n("FL"))
  expect_true(any(grepl("Highlands County", fl$evidence)))
  expect_equal(sum(attr(fl, "candidates")$is_new), live_n("FL"))
})

test_that("Alaska: re-keyed, so every live candidate is new since 08-27", {
  ak <- attr(tables[["AK"]], "candidates")
  expect_equal(sum(ak$is_new), nrow(ak))
})

test_that("Georgia: the Dual Track rows are state money, not RHTP", {
  ga <- tables[["GA"]]
  dt <- ga[ga$disposition == "NOT_RHTP_STATE_PROGRAM", ]
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$rcj_rows, sum(grepl("Dual Track", attr(ga, "candidates")$source_doc_title)))
  expect_true(file.exists(here::here(DISPO_NEW_EVIDENCE, "GA", "dch_dual_track_fy26_rfga_2026-01-21.pdf")))
})

test_that("Oregon: RCJ carries a hundred Catalyst awards twice", {
  or <- tables[["OR"]]
  expect_gte(sum(or$rcj_rows[or$disposition == "DUPLICATE_OF_EXTRACTED_AWARD"]), 100L)
})

test_that("South Dakota: the Rural Strong grants are now IN the SD file (session 64)", {
  # Session 63 found 8 Rural Strong contracts on OpenSD in no SD file; session
  # 64 extracted them into sd_rht_contracts.csv, so they now match exactly and
  # the hand-read group that described them is gone.
  sd <- tables[["SD"]]
  expect_false("Rural Strong grants now posted to OpenSD" %in% sd$group)
  inf <- sd[sd$disposition == "RHTP_SUBAWARD_IN_FILE", ]
  expect_equal(sum(inf$rcj_rows), 26L)
  html <- paste(readLines(here::here(DISPO_NEW_EVIDENCE, "SD", "open_sd_contracts_rural_strong.html"),
                          warn = FALSE), collapse = " ")
  expect_true(grepl("BENNETT COUNTY HOSPITAL", html, fixed = TRUE))
  contracts <- readr::read_csv(rhtp_path("reference", "sd_rht_contracts.csv"), show_col_types = FALSE)
  expect_true(any(grepl("BENNETT", toupper(contracts$awardee))))
})

test_that("Kansas: the new ids are the KRHIA deck, the Emerging Technology list and the Year 2 plan", {
  ks <- attr(tables[["KS"]], "candidates")
  new_docs <- unique(ks$source_doc_title[ks$is_new])
  expect_true(all(grepl("KRHIA|Award Recipients Announced|Year 2 Budget Narrative", new_docs)))
})

test_that("Vermont and Virginia: real awards their committed files do not carry", {
  vt <- tables[["VT"]]
  expect_true("RHTP_SUBAWARD_NOT_IN_FILE_AT_A_PLACEHOLDER" %in% vt$disposition)
  va <- tables[["VA"]]
  expect_true("RHTP_SUBAWARD_NOT_IN_FILE" %in% va$disposition)
})

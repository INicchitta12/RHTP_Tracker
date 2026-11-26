# test_12_awardee_ranking.R ----------------------------------------------------
# SESSION 125, owner direction: the awardee ranking (CLAUDE.md §7, "Awardee
# identity and the ranking"). A name is never enough to join two states'
# awards; the recorded collisions stay distinct; totals reconcile; amount types
# are never mixed.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "12_awardee_ranking.R"))

AW_TEST_DATE <- "2026-11-26"

fx_rows <- function() {
  tibble::tibble(
    row_id = paste0("F#", 1:8), file_key = "F", state = c("TX", "IL", "TX", "TX", "ID", "OR", "SD", "SD"),
    awardee = c("Memorial Hospital", "Memorial Hospital", "Memorial Hospital (Dumas)", "Memorial Hospital",
                "Comagine Health", "Comagine", "Community Memorial Hospital", "Community Memorial Hospital"),
    amount = c(100, 200, 300, 400, 500, 600, 700, 800),
    uei = c(NA, "U-IL", "U-TX", NA, "U-COM", NA, "U-A", "U-B"),
    ccn = c("451386", "140185", "451386", "451999", NA, NA, NA, NA),
    ein = NA_character_, role = "RANKED", amount_type = "award") %>%
    dplyr::mutate(norm_name = aw_norm(awardee))
}
no_hand <- tibble::tibble(entity_key = character(0), state = character(0), awardee = character(0),
                          evidence_class = character(0), basis = character(0), source = character(0), reviewer = character(0))

test_that("an identical name in two states is never joined", {
  e <- aw_entities(fx_rows(), no_hand)
  expect_false(e$awardee_entity_id[e$row_id == "F#1"] == e$awardee_entity_id[e$row_id == "F#2"])
})

test_that("a CCN joins rows; different CCNs block a same-state name join", {
  e <- aw_entities(fx_rows(), no_hand)
  id <- function(r) e$awardee_entity_id[e$row_id == r]
  expect_equal(id("F#1"), id("F#3"))            # CCN 451386
  expect_false(id("F#1") == id("F#4"))          # same name, same state, CCN 451999: different hospitals
  expect_false(id("F#7") == id("F#8"))          # same name, same state, two UEIs: two bodies
})

test_that("a hand-reviewed join is the only way a roster string reaches another state's UEI", {
  e0 <- aw_entities(fx_rows(), no_hand)
  expect_false(e0$awardee_entity_id[e0$row_id == "F#5"] == e0$awardee_entity_id[e0$row_id == "F#6"])
  hand <- tibble::tibble(entity_key = "COMAGINE", state = c("ID", "OR"), awardee = c("Comagine Health", "Comagine"),
                         evidence_class = "ENTITY_WEBSITE", basis = "x", source = "y", reviewer = "z")
  e1 <- aw_entities(fx_rows(), hand)
  expect_equal(e1$awardee_entity_id[e1$row_id == "F#5"], e1$awardee_entity_id[e1$row_id == "F#6"])
  expect_equal(e1$entity_match_basis[e1$row_id == "F#6"], "HAND_REVIEWED")
})

er <- readr::read_csv(here::here(AW_OUT_ROWS), col_types = readr::cols(.default = "c"), progress = FALSE)
rank <- readr::read_csv(here::here(AW_OUT_RANK(AW_TEST_DATE)), show_col_types = FALSE, progress = FALSE)

test_that("no committed entity spans two states without a UEI, EIN, CCN or hand-reviewed join", {
  ms <- er %>% dplyr::group_by(awardee_entity_id) %>% dplyr::filter(dplyr::n_distinct(state) > 1) %>%
    dplyr::summarise(strong = any(entity_match_basis %in% c("UEI", "EIN", "CCN", "HAND_REVIEWED")), .groups = "drop")
  expect_true(nrow(ms) > 0)
  expect_true(all(ms$strong))
  # every cross-state hand join is in the config with a basis
  hand <- aw_hand_config()
  expect_true(all(!is.na(hand$basis) & !is.na(hand$evidence_class)))
})

test_that("the six named collisions stay distinct", {
  six <- c("MEMORIAL HEALTH SYSTEM" = "KS;MS", "COMMUNITY MEMORIAL HOSPITAL" = "NY;SD", "MEMORIAL MEDICAL CENTER" = "IL;TX",
           "COUNTY OF CLAY" = "IL;TX", "FAMILY HEALTH CENTERS" = "CA;SC", "WAYNE MEMORIAL HOSPITAL" = "GA;PA")
  d <- aw_distinct_config()
  for (nm in names(six)) {
    expect_true(nm %in% d$norm_name, info = nm)
    sts <- strsplit(six[[nm]], ";")[[1]]
    ids <- er %>% dplyr::filter(norm_name == nm, state %in% sts) %>% dplyr::group_by(state) %>%
      dplyr::summarise(id = paste(sort(unique(awardee_entity_id)), collapse = ","), .groups = "drop")
    expect_equal(nrow(ids), length(sts), info = nm)
    expect_equal(dplyr::n_distinct(ids$id), length(sts), info = nm)
  }
})

test_that("ranked + obligation + unattributed + held out reconcile to the Year 1 summary", {
  ys <- readr::read_csv(here::here(YS_OUT(AW_TEST_DATE)), show_col_types = FALSE, progress = FALSE)
  us <- ys[ys$state == "US", ]
  amt <- suppressWarnings(as.numeric(er$amount))
  all_priced <- round(sum(amt[er$role != "SECOND_TIER"], na.rm = TRUE), 2)   # second tier: counted at the first tier (125b)
  expect_equal(round(sum(amt[er$role == "SECOND_TIER"], na.rm = TRUE), 2), round(us$second_tier_usd, 2), tolerance = 0.01)
  expect_equal(all_priced, round(us$published_priced_usd + us$excluded_award_usd, 2), tolerance = 0.05)
  ranked <- round(sum(rank$total_award_usd) + sum(rank$obligation_usd), 2)
  unattr <- round(sum(amt[er$role == "UNATTRIBUTED_POOL"], na.rm = TRUE), 2)
  held <- round(sum(amt[er$role == "HELD_OUT_ADMINISTRATOR"], na.rm = TRUE), 2)
  expect_equal(ranked + unattr + held, all_priced, tolerance = 0.05)
  expect_equal(held, round(us$excluded_award_usd, 2), tolerance = 0.01)
})

test_that("amount types are never mixed in the ranking total", {
  amt <- suppressWarnings(as.numeric(er$amount))
  by <- er %>% dplyr::mutate(a = dplyr::coalesce(amt, 0)) %>% dplyr::filter(role == "RANKED") %>%
    dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(award = round(sum(a[amount_type %in% c("award", "intent")]), 2),
                     obl = round(sum(a[amount_type == "obligation"]), 2), .groups = "drop") %>%
    dplyr::inner_join(rank, by = "awardee_entity_id")
  expect_true(all(abs(by$award - by$total_award_usd) < 0.01))
  expect_true(all(abs(by$obl - by$obligation_usd) < 0.01))
  expect_false(any(er$role == "RANKED" & grepl("Accenture", er$awardee, ignore.case = TRUE) & er$state == "NM"))
})

test_that("Delaware is in every output (owner ruling 2026-11-25); the team copy is the same workbook", {
  x <- here::here(AW_OUT_XLSX(AW_TEST_DATE, team = TRUE))
  full <- here::here(AW_OUT_XLSX(AW_TEST_DATE))
  expect_true(file.exists(x))
  expect_equal(openxlsx::getSheetNames(x), openxlsx::getSheetNames(full))
  a <- openxlsx::read.xlsx(x, "All awardees")
  b <- openxlsx::read.xlsx(full, "All awardees")
  expect_equal(a, b)
  expect_true(any(grepl("(^|;)DE(;|$)", a$states)))
  expect_false(any(grepl("confidential", names(a), ignore.case = TRUE)))
  expect_equal(openxlsx::getSheetNames(x)[1], "Read first")
  rf <- openxlsx::read.xlsx(x, "Read first")[[1]]
  expect_true(any(grepl("hospital best estimate", rf)) && any(grepl("intent_usd", rf)) && any(grepl("HELD OUT", rf)))
  expect_false(any(grepl("REMOVED", openxlsx::read.xlsx(x, "Notes and method")[[1]])))
  de_usd <- sum(suppressWarnings(as.numeric(er$amount[er$state == "DE" & er$role == "RANKED" & er$amount_type %in% c("award", "intent")])), na.rm = TRUE)
  expect_true(de_usd > 0)
})

test_that("second tier: VHCF's subgrants are never ranked, listed on their own tab, and within its first-tier award", {
  st <- er[er$role == "SECOND_TIER", ]
  expect_equal(nrow(st), 48L)
  expect_true(all(st$file_key %in% c("VA_VHCF", "VA_VHCF_PP")))
  expect_true(all(grepl("^SECOND_TIER_OF VA: Virginia Health Care Foundation", st$second_tier_of)))
  expect_equal(round(sum(as.numeric(st$amount), na.rm = TRUE), 2), 23034000)
  v <- rank[grepl("^Virginia Health Care Foundation", rank$awardee), ]
  expect_equal(nrow(v), 1L)
  expect_equal(v$total_award_usd, 25965319)
  expect_equal(v$second_tier_usd, 23034000)
  expect_true(v$pass_through)
  expect_true(all(rank$second_tier_usd <= rank$total_award_usd + 0.005))
  tab <- openxlsx::read.xlsx(here::here(AW_OUT_XLSX(AW_TEST_DATE)), "Second-tier recipients")
  expect_equal(nrow(tab), 48L)
})

test_that("DBA names: 'A DBA B' equals 'B DBA A'; each half meets the half printed alone (within one state)", {
  expect_equal(aw_norm("Mountain Community Health DBA Five Town Health Alliance, INC"),
               aw_norm("Five-Town Health Alliance Inc DBA Mountain Community Health, Inc."))
  expect_equal(aw_norm("X Corp d/b/a Y Clinic"), aw_norm("Y Clinic dba X Corp"))
  expect_true(aw_norm("AHS Hospital Corp.") %in% aw_name_keys(aw_norm("AHS Hospital Corp. dba Newton Medical Center"))[[1]])
  ids <- function(pat, st) unique(er$awardee_entity_id[grepl(pat, er$awardee, ignore.case = TRUE) & er$state == st & er$role == "RANKED"])
  expect_length(ids("Five.Town|Mountain Community Health", "VT"), 1)
  expect_length(ids("^Bartlett Regional Hospital$", "AK"), 1)
  expect_length(ids("^AHS Hospital Corp", "NJ"), 1)
  expect_length(ids("^Lutheran Hospital Association of the San Luis Valley", "CO"), 1)
  expect_length(ids("^OKLAHOMA STATE UNIVERSITY$", "OK"), 2)
  expect_length(ids("^UNIVERSITY OF TENNESSEE$", "TN"), 2)
  expect_length(ids("^COMMUNITY MEMORIAL HOSPITAL$", "SD"), 2)
})

test_that("same printed name, different entity: the awardee column tells them apart", {
  osu <- rank[grepl("^OKLAHOMA STATE UNIVERSITY \\[", rank$awardee), ]
  expect_equal(nrow(osu), 2L)
  expect_true(any(grepl("Tulsa", osu$awardee)) && any(grepl("Stillwater", osu$awardee)))
  expect_equal(dplyr::n_distinct(rank$awardee), nrow(rank))
  ahs <- rank[grepl("^AHS Hospital Corp", rank$awardee), ]
  expect_true(grepl("310028", ahs$facilities) && grepl("310115", ahs$facilities))
})

test_that("organisation type: the unstated-form fallback never prints as Nonprofit", {
  inf <- aw_org_type("NONPROFIT_CBO", "RECIPIENT_TYPE_INFERRED", NA, "Guidehouse Inc.")
  expect_equal(inf, "Organisation (form not stated)")
  expect_equal(aw_org_type("HOSPITAL_OR_SYSTEM", NA, "ACADEMIC_HEALTH_CENTER", "UAMS"),
               "Hospital or health system (academic health centre)")
  expect_equal(aw_org_type("NONPROFIT_CBO", NA, NA, "Utah Hospital Association (UHA)"), "Hospital association or network")
  expect_false(any(is.na(rank$organisation_type) | rank$organisation_type == ""))
  g <- rank[grepl("^Access East", rank$awardee), ]
  expect_false(grepl("Nonprofit", g$organisation_type))
})

test_that("a CCN never joins two differently named rows with different UEIs (independent check, 125b)", {
  x <- tibble::tibble(row_id = paste0("C#", 1:4), file_key = "C", state = "ND",
                      awardee = c("Cooperstown Medical Center", "Griggs County Nursing Home", "OSF Healthcare System", "OSF Healthcare System"),
                      amount = c(1, 2, 3, 4), uei = c("U1", "U2", "U3", "U4"), ccn = c("351306", "351306", "141325", "141325"),
                      ein = NA_character_, role = "RANKED", amount_type = "award") %>% dplyr::mutate(norm_name = aw_norm(awardee))
  e <- aw_entities(x, no_hand)
  id <- function(r) e$awardee_entity_id[e$row_id == r]
  expect_false(id("C#1") == id("C#2"))
  expect_equal(id("C#3"), id("C#4"))
  ids <- function(pat, st) unique(er$awardee_entity_id[grepl(pat, er$awardee) & er$state == st])
  expect_length(ids("^(COOPERSTOWN MEDICAL CENTER|GRIGGS COUNTY NURSING HOME)$", "ND"), 2)
  expect_length(ids("^(WAR MEMORIAL HOSPITAL, INC.|EAST MOUNTAIN HEALTH PHYSICIANS INC)$", "WV"), 2)
})

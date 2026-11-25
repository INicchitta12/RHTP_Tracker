# test_12_awardee_ranking.R ----------------------------------------------------
# SESSION 125, owner direction: the awardee ranking (CLAUDE.md §7, "Awardee
# identity and the ranking"). A name is never enough to join two states'
# awards; the recorded collisions stay distinct; totals reconcile; amount types
# are never mixed.

suppressPackageStartupMessages(library(testthat))
source(here::here("R", "12_awardee_ranking.R"))

AW_TEST_DATE <- "2026-11-25"

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
  all_priced <- round(sum(amt, na.rm = TRUE), 2)
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

test_that("the team copy carries no Delaware row", {
  x <- here::here(AW_OUT_XLSX(AW_TEST_DATE, team = TRUE))
  expect_true(file.exists(x))
  a <- openxlsx::read.xlsx(x, "All awardees")
  expect_false(any(grepl("(^|;)DE(;|$)", a$states)))
  expect_false(any(a$confidential %in% TRUE))
  full <- openxlsx::read.xlsx(here::here(AW_OUT_XLSX(AW_TEST_DATE)), "All awardees")
  expect_true(any(grepl("(^|;)DE(;|$)", full$states)))
})

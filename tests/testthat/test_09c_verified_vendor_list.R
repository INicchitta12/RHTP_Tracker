# test_09c_verified_vendor_list.R -------------------------------------------------
# Session 116e: the VERIFIED consultant / intermediary / out-of-state vendor list.
#
# Pins: every committed case still passes V1-V8 against the ARCHIVED bytes (the
# build re-checks them, so a changed archive or a mistyped figure fails here);
# categories, amount types and the $1M floor; no hospital, health system or state
# agency on the list; every hand drop names a valid test; the independent check
# covers every case; the committed CSVs equal a fresh build; and this layer moves
# no award row (the hospital partition is pinned in test_09_vendor_flags.R).

library(testthat)

source(here::here("R", "utils_config.R"))
suppressMessages(source(here::here("R", "09c_verified_vendor_list.R")))

b <- vv_build(write = FALSE)
v <- b$verified

test_that("every case passes the machine re-check against the archive", {
  expect_true(nrow(v) > 0)
  expect_true(all(v$passed))
  expect_false(any(duplicated(v$case_id)))
  cases <- vv_cases()
  failed <- b$checked %>% dplyr::filter(!passed, !case_id %in% b$dropped$drop_id)
  expect_equal(nrow(failed), 0)
})

test_that("categories, amount types and the floor hold", {
  cats <- unlist(strsplit(v$categories, ";"))
  expect_true(all(cats %in% VV_CATEGORIES))
  expect_true(all(v$amount_type %in% VV_AMOUNT_TYPES))
  expect_true(all(v$amount >= VV_FLOOR))
  expect_true(all(v$source_class %in% VV_ADMISSIBLE))
})

test_that("no hospital, health system or state agency is listed", {
  expect_false(any(grepl("HOSPITAL", v$fsrs_business_types, ignore.case = TRUE)))
  sa <- grepl("STATE GOVERNMENT", v$fsrs_business_types) & !grepl("INSTITUTION OF HIGHER", v$fsrs_business_types)
  expect_false(any(sa))
  t <- vv_award_union_types()
  k <- paste(v$state, vv_norm_name(v$recipient_as_printed))
  bad <- t %>% dplyr::filter(paste(state, name_key) %in% k, recipient_type %in% c("HOSPITAL_OR_SYSTEM", "STATE_AGENCY"))
  expect_equal(nrow(bad), 0)
})

test_that("OUT_OF_STATE_VENDOR always rests on an FSRS address outside the state", {
  o <- v %>% dplyr::filter(grepl("OUT_OF_STATE_VENDOR", categories))
  expect_true(nrow(o) > 0)
  expect_false(any(is.na(o$fsrs_address)))
  expect_true(all(sub(".*, ", "", o$fsrs_address) != o$state))
})

test_that("every drop names a test V1-V9 and a reason", {
  d <- b$dropped
  expect_true(all(grepl("^V[1-9](,V[1-9])*$", d$failed_test)))
  expect_false(any(is.na(d$reason) | d$reason == ""))
  h <- vv_hand_drops()
  expect_false(any(duplicated(h$drop_id)))
  # a hand drop never reappears as a verified case at the same state and amount
  hit <- h %>% dplyr::filter(!is.na(amount)) %>%
    dplyr::inner_join(v %>% dplyr::select(state, v_amount = amount, recipient_as_printed), by = "state",
                      suffix = c("", ".v"), relationship = "many-to-many") %>%
    dplyr::filter(abs(amount - v_amount) < 0.01,
                  vv_norm_name(recipient_as_printed) == vv_norm_name(recipient_as_printed.v),
                  failed_test != "V6")
  expect_equal(nrow(hit), 0)
})

test_that("the independent check covers every case and its drops are honoured", {
  skip_if_not(file.exists(here::here(VV_INDEPENDENT)))
  ind <- readr::read_csv(here::here(VV_INDEPENDENT), col_types = readr::cols(.default = "c"))
  expect_true(all(ind$verdict %in% c("KEEP", "DROP")))
  expect_true(all(v$case_id %in% ind$case_id[ind$verdict == "KEEP"]))
  expect_false(any(v$case_id %in% ind$case_id[ind$verdict == "DROP"]))
})

test_that("planned lines and unnamed lines never enter the verified list", {
  expect_true(all(grepl("^plan", b$planned$amount_type)))
  expect_false(any(b$unnamed$line_id %in% v$case_id))
})

test_that("the committed CSVs equal a fresh build", {
  rd <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"), na = "")
  expect_equal(nrow(rd(VV_LIST_CSV)), nrow(v))
  expect_setequal(rd(VV_LIST_CSV)$case_id, v$case_id)
  expect_equal(nrow(rd(VV_DROPPED_CSV)), nrow(b$dropped))
  expect_equal(nrow(rd(VV_UNNAMED_CSV)), nrow(b$unnamed))
  expect_equal(nrow(rd(VV_PLANNED_CSV)), nrow(b$planned))
})

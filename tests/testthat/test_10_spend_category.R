# test_10_spend_category.R -- session 116f: the spend-category layer
#
# Pins: every award and contract row carries one spend_category from the list;
# HOSPITAL is exactly R/07's HOSPITAL call; a hospital-coded row never carries a
# vendor category; the committed columns equal the computed layer; every
# verified 116e case lands on exactly one row; the owner's rulings hold; the
# contract files are never award files; and NO HOSPITAL FIGURE MOVED (the
# strict partition and the year-1 hospital columns, to the cent).

source(here::here("R", "utils_spend_category.R"))
source(here::here("R", "07_summary_calls.R"))
source(here::here("R", "10_contract_registers.R"))

sf <- sc_state_files()
rd <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                  na = character(), progress = FALSE, trim_ws = FALSE)
award <- purrr::map_dfr(names(sf), function(k) {
  d <- rd(sf[[k]]); o <- function(c) if (c %in% names(d)) d[[c]] else rep("", nrow(d))
  tibble::tibble(file_key = k, state = d$state, awardee = d$awardee, amount = suppressWarnings(as.numeric(d$amount)),
                 recipient_type = o("recipient_type"), recipient_subtype = o("recipient_subtype"),
                 hospital_attribution = o("hospital_attribution"), summary_hospital_call = o("summary_hospital_call"),
                 spend_category = o("spend_category"), vendor_verified = o("vendor_verified"),
                 vendor_verified_usd = o("vendor_verified_usd"), out_of_state = o("out_of_state"),
                 vendor_role = o("vendor_role"), vendor_public = o("vendor_public"), vendor_case_id = o("vendor_case_id"))
})
cf <- rhtp_contract_files()
contract <- purrr::map_dfr(names(cf), function(k) {
  d <- rd(cf[[k]])
  tibble::tibble(file_key = k, state = d$state, awardee = d$awardee, amount = suppressWarnings(as.numeric(d$amount)),
                 amount_type = d$amount_type, recipient_type = d$recipient_type, budget_period = d$budget_period,
                 validation_source_type = d$validation_source_type,
                 spend_category = d$spend_category, vendor_verified = d$vendor_verified,
                 vendor_verified_usd = d$vendor_verified_usd, out_of_state = d$out_of_state,
                 vendor_role = d$vendor_role, vendor_case_id = d$vendor_case_id)
})
both <- dplyr::bind_rows(award %>% dplyr::mutate(kind = "award"), contract %>% dplyr::mutate(kind = "contract"))

test_that("every award and contract row has exactly one spend_category from the list", {
  expect_true(all(nzchar(both$spend_category)))
  expect_true(all(both$spend_category %in% RHTP_SPEND_CATEGORIES))
  expect_identical(RHTP_SPEND_CATEGORIES, c("HOSPITAL", "CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR",
                                            "NON_PROVIDER_INTERMEDIARY", "PROVIDER_PASS_THROUGH", "OTHER"))
  expect_true(all(both$vendor_role %in% c("", RHTP_VENDOR_ROLES), na.rm = TRUE))
  expect_true(all(both$vendor_verified %in% c("TRUE", "FALSE")))
  expect_identical(RHTP_SPEND_COLUMNS, RHTP_SPEND_STRIP_COLUMNS)
})

test_that("HOSPITAL is exactly R/07's HOSPITAL call, and a hospital-coded row is never a vendor", {
  expect_identical(award$spend_category == "HOSPITAL", award$summary_hospital_call == "HOSPITAL")
  hosp_coded <- award$summary_hospital_call == "HOSPITAL" |
    award$hospital_attribution %in% c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS") |
    award$recipient_type %in% c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY") |
    award$recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"
  expect_false(any(hosp_coded & award$spend_category %in% RHTP_VENDOR_CATEGORIES))
  # every strict bucket row is HOSPITAL
  strict <- award$hospital_attribution %in% c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS")
  expect_true(all(award$spend_category[strict] == "HOSPITAL"))
  expect_false(any(contract$recipient_type %in% "HOSPITAL_OR_SYSTEM" & contract$spend_category != "HOSPITAL"))
  # out_of_state: TRUE/FALSE on every non-hospital row, empty on a hospital row
  expect_true(all(both$out_of_state[both$spend_category == "HOSPITAL"] == ""))
  expect_true(all(both$out_of_state[both$spend_category != "HOSPITAL"] %in% c("TRUE", "FALSE")))
  # verified only on vendor categories
  expect_false(any(both$vendor_verified == "TRUE" & !both$spend_category %in% RHTP_VENDOR_CATEGORIES))
})

test_that("a test fails if a row lacks spend_category: the committed layer equals the computed one", {
  expect_silent(suppressMessages(rhtp_spend_validate(sf)))
})

test_that("every verified 116e case lands on exactly one row, and verified dollars are the cases'", {
  cases <- rhtp_spend_cases()
  ids <- unlist(strsplit(both$vendor_case_id[nzchar(both$vendor_case_id)], ";", fixed = TRUE))
  expect_setequal(ids, cases$case_id)
  expect_false(anyDuplicated(ids) > 0)
  vend <- cases %>% dplyr::filter(spend_category %in% RHTP_VENDOR_CATEGORIES)
  expect_equal(sum(as.numeric(both$vendor_verified_usd)), sum(vend$amount), tolerance = 1e-9)
  # Session 116f national verified pins, by category (types never added)
  v <- both %>% dplyr::filter(vendor_verified == "TRUE")
  expect_equal(nrow(v), 34L)
  expect_equal(round(sum(as.numeric(v$vendor_verified_usd)), 2), 243911973.44)
})

test_that("the owner's rulings hold", {
  uk <- both %>% dplyr::filter(grepl("UKHS CARE COLLABORATIVE", awardee, ignore.case = TRUE))
  expect_gte(nrow(uk), 5L)
  expect_true(all(uk$spend_category == "PROVIDER_PASS_THROUGH"))
  nc <- award %>% dplyr::filter(file_key == "NC", grepl("Trillium|Vaya|Access East|Impact Health", awardee))
  expect_equal(nrow(nc), 4L)
  expect_true(all(nc$spend_category == "ADMINISTRATOR"))
  expect_identical(nc$vendor_public[grepl("Trillium|Vaya", nc$awardee)], c("TRUE", "TRUE"))
  expect_identical(nc$vendor_public[grepl("Access East|Impact", nc$awardee)], c("FALSE", "FALSE"))
  v9 <- both %>% dplyr::filter(grepl(RHTP_V9_RX, awardee, ignore.case = TRUE))
  expect_gte(nrow(v9), 4L)
  expect_true(all(v9$spend_category == "OTHER"))
  expect_true(all(v9$out_of_state == "FALSE"))
  expect_true(all(v9$vendor_verified == "FALSE"))
  id5 <- award %>% dplyr::filter(state == "ID", grepl("Public Consulting|BDO|Guidehouse|Deloitte|22nd Century", awardee),
                                 vendor_verified == "TRUE")
  expect_equal(nrow(id5), 5L)
  # hospital associations never enter a vendor category
  assoc <- both %>% dplyr::filter(grepl("Hospital Association|VHHA|Hospital Research and Education", awardee, ignore.case = TRUE))
  expect_false(any(assoc$spend_category %in% RHTP_VENDOR_CATEGORIES))
})

test_that("contract files are never award files, carry budget period 1, and count toward no hospital figure", {
  expect_length(intersect(unname(cf), unname(sf)), 0L)
  expect_true(all(contract$budget_period == "1"))
  expect_true(all(contract$amount_type %in% c("contract maximum", "obligation", "intent")))
  expect_true(all(contract$validation_source_type %in% c("STATE_CONTRACT", "CMS_OBLIGATION_REPORT")))
  expect_setequal(names(cf), c("KY", "TX", "CO", "OK", "MS", "CMS_OBL"))
  expect_silent(suppressMessages(cr_validate()))
  ky <- contract %>% dplyr::filter(file_key == "KY")
  expect_equal(nrow(ky), 218L)
  expect_equal(round(sum(ky$amount), 2), 127182976.26)
})

test_that("NO HOSPITAL FIGURE MOVED: the strict partition is pinned to the cent", {
  d <- purrr::map_dfr(sf, function(p) {
    x <- readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"), progress = FALSE)
    o <- function(c) if (c %in% names(x)) x[[c]] else NA_character_
    tibble::tibble(state = x$state, amount = suppressWarnings(as.numeric(x$amount)),
                   distributed_to_hospital = x$distributed_to_hospital, recipient_type = x$recipient_type,
                   flow_type = o("flow_type"), hospital_attribution = o("hospital_attribution"),
                   flag_reason = o("flag_reason"))
  })
  parts <- rhtp_hospital_dollar_partition(d)
  got <- parts %>% dplyr::group_by(bucket) %>% dplyr::summarise(rows = sum(rows), usd = round(sum(dollars), 2))
  expect_equal(got$rows[got$bucket == "NAMED_HOSPITAL"], 2204L)
  expect_equal(got$usd[got$bucket == "NAMED_HOSPITAL"], 2170425246.88)
  expect_equal(got$usd[got$bucket == "POOL_NAMED_HOSPITALS"], 86895779.43)
  expect_equal(got$usd[got$bucket == "POOL_UNNAMED_HOSPITALS"], 79214848.17)
})

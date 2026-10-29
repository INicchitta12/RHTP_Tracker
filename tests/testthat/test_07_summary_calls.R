# test_07_summary_calls.R -- the summary-call layer (session 110)
#
# Every award file carries summary_hospital_call / summary_call_basis /
# summary_call_rationale; the call is two-valued; BEST_JUDGMENT carries a
# rationale; a CODED call is the strict determination; and the layer never
# moves the strict partition.

source(here::here("R", "07_summary_calls.R"))

files <- sc_state_files()
tabs <- lapply(files, function(f) rhtp_summary_read(here::here(f)))

test_that("every award file carries the three columns, two-valued, on every row", {
  for (k in names(tabs)) {
    d <- tabs[[k]]
    expect_true(all(RHTP_SUMMARY_COLUMNS %in% names(d)), info = k)
    expect_true(all(d$summary_hospital_call %in% c("HOSPITAL", "NOT_HOSPITAL")), info = k)
    expect_true(all(d$summary_call_basis %in% c("CODED", "BEST_JUDGMENT")), info = k)
    expect_silent(rhtp_assert_summary_calls(d, k))
  }
})

test_that("BEST_JUDGMENT always carries a one-sentence rationale; CODED carries none", {
  for (k in names(tabs)) {
    d <- tabs[[k]]
    bj <- d$summary_call_basis == "BEST_JUDGMENT"
    expect_true(all(nzchar(trimws(d$summary_call_rationale[bj]))), info = k)
    expect_true(all(d$summary_call_rationale[!bj] == ""), info = k)
  }
})

test_that("no Unclear, unresolved, unnamed or form-unknown row is CODED", {
  for (k in names(tabs)) {
    d <- tabs[[k]]
    r <- rhtp_summary_reasons(d, sc_open_rows(d, k))
    expect_true(all(d$summary_call_basis[nzchar(r)] == "BEST_JUDGMENT"), info = k)
    expect_true(all(d$summary_call_basis[!nzchar(r)] == "CODED"), info = k)
    expect_false(any(d$distributed_to_hospital %in% c("Unclear", "") &
                       d$summary_call_basis == "CODED"), info = k)
  }
})

test_that("the committed columns are what the shared function computes", {
  expect_silent(sc_validate(files))
})

test_that("the validator refuses a third value and a missing rationale", {
  d <- tabs[["WA"]]
  bad <- d; bad$summary_hospital_call[1] <- "UNCLEAR"
  expect_error(rhtp_assert_summary_calls(bad, "WA"), "HOSPITAL or")
  bad <- d; bad$summary_call_rationale[bad$summary_call_basis == "BEST_JUDGMENT"][1] <- ""
  expect_error(rhtp_assert_summary_calls(bad, "WA"), "no rationale")
  bad <- d; i <- which(d$summary_call_basis == "CODED")[1]
  bad$summary_hospital_call[i] <- setdiff(c("HOSPITAL", "NOT_HOSPITAL"), d$summary_hospital_call[i])
  expect_error(rhtp_assert_summary_calls(bad, "WA"), "disagrees")
})

test_that("a row needing judgment with no written one and a hospital marker is refused", {
  d <- tibble::tibble(row_no = "1", awardee = "Example Memorial Hospital Foundation",
                      distributed_to_hospital = "No", flag_reason = "RECIPIENT_TYPE_INFERRED")
  j <- SC_JUDGMENTS[0, ]
  expect_error(rhtp_summary_calls(d, j, default_rationale = function(a) "x", label = "T"),
               "needs a written judgment")
})

test_that("the summary layer does not move the strict partition", {
  u <- dplyr::bind_rows(lapply(files, function(f) readr::read_csv(here::here(f),
          col_types = readr::cols(.default = "c"), progress = FALSE)))
  u$amount <- as.numeric(u$amount)
  p <- rhtp_hospital_dollar_partition(u)
  s <- p %>% dplyr::group_by(bucket) %>% dplyr::summarise(rows = sum(rows), dollars = round(sum(dollars), 2))
  # Session 110: 1,834 / $1,729,133,683.70 before; Task 1's three rulings move
  # it to 1,835 / $1,729,244,537.70 (+$498,854 UC San Diego Health, -$450,000
  # Providence Medical Foundation, +$62,000 UVA Health). Nothing else moved.
  # Session 111: owner rulings (e) + TX Burleson (CAH 451305, +$2,527,185.38) and
  # (f) - AK City of Ketchikan (-$350,000): 1,835 / $1,731,421,723.08 / 36.
  expect_equal(s$rows[s$bucket == "NAMED_HOSPITAL"], 1835L)
  expect_equal(s$dollars[s$bucket == "NAMED_HOSPITAL"], 1731421723.08)
  expect_equal(s$dollars[s$bucket == "POOL_NAMED_HOSPITALS"], 86555171.43)
  expect_equal(s$dollars[s$bucket == "POOL_UNNAMED_HOSPITALS"], 69323109.17)
  # With the summary columns stripped, the partition is identical.
  p2 <- rhtp_hospital_dollar_partition(rhtp_strip_summary_calls(u))
  expect_equal(p, p2)
})

test_that("the named cases the owner listed are called, with counter-arguments", {
  r <- readr::read_csv(here::here(SC_REVIEW_CSV), show_col_types = FALSE)
  expect_true(all(r$amount[r$listed_because == "OVER_1M"] > SC_REVIEW_FLOOR))
  expect_setequal(unique(r$listed_because), c("OVER_1M", "OWNER_NAMED", "STRICT_UNCLEAR"))
  expect_equal(dplyr::coalesce(r$amount, 0), sort(dplyr::coalesce(r$amount, 0), decreasing = TRUE))
  # Every strict-Unclear row is on the list, whatever its amount.
  calls0 <- dplyr::bind_rows(lapply(names(tabs), function(k) dplyr::mutate(tabs[[k]], file_key = k)))
  expect_equal(sum(r$strict_status == "Unclear"), sum(!calls0$distributed_to_hospital %in% c("Yes", "No")))
  expect_true(all(nzchar(r$counter_argument)) && all(nzchar(r$rationale)))
  hit <- function(st, pat) any(r$state == st & grepl(pat, r$recipient))
  expect_true(hit("WA", "Washington State Hospital Association"))
  expect_true(hit("ID", "Public Consulting Group") && hit("ID", "Hospital Network of Idaho") &&
                hit("ID", "The Hospital Cooperative"))
  expect_true(hit("CT", "Hartford HealthCare") && hit("OH", "22 rural hospitals") &&
                hit("GA", "Connecting to Care") && hit("OH", "Clinically Integrated"))
  expect_true(hit("NY", "Glens Falls Hospital"))
  expect_true(hit("NH", "Foundation for Healthy Communities"))
  # Below the $1M floor, so in the files rather than the list:
  calls <- dplyr::bind_rows(lapply(names(tabs), function(k) dplyr::mutate(tabs[[k]], file_key = k)))
  call_of <- function(k, a) unique(calls$summary_hospital_call[calls$file_key == k & calls$awardee == a])
  # Session 111 (ruling f): Ketchikan is strict No now, so its call is CODED and
  # it leaves the review list.
  expect_equal(call_of("AK", "City of Ketchikan"), "NOT_HOSPITAL")
  expect_equal(unique(calls$summary_call_basis[calls$file_key == "AK" & calls$awardee == "City of Ketchikan"]), "CODED")
  expect_equal(call_of("CA", "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics"), "NOT_HOSPITAL")
  expect_equal(call_of("LA", "48 Rural Clinician Credit Bank awards (single home parish) - recipient names not published"), "NOT_HOSPITAL")
  expect_false(hit("AK", "City of Ketchikan"))
  expect_true(hit("CA", "Fresno Family Medicine") &&
                hit("LA", "Rural Clinician Credit Bank"))
})

test_that("every OPEN queue question is placed, and the pools are counted once", {
  expect_silent(sc_assert_queue_covered())
  p <- readr::read_csv(here::here(SC_POOLS_CSV), show_col_types = FALSE)
  expect_true(all(p$call %in% RHTP_SUMMARY_CALL_VALUES))
  # Session 111 (rulings b, d): pools are called on typed members; OH's two
  # are NOT, Indiana Region 5's tie goes to its lead (a hospital).
  expect_equal(sum(p$pool_usd[p$call == "HOSPITAL"]), 38835000)
  expect_setequal(p$pool_id[p$call == "HOSPITAL"],
                  c("GA_P2_CONNECTING_TO_CARE", "GA_P4_TRANSFORMING", "IN_GROW_REGION_5"))
})

test_that("the session 111 summary rulings hold", {
  calls <- dplyr::bind_rows(lapply(names(tabs), function(k) dplyr::mutate(tabs[[k]], file_key = k)))
  call_of <- function(k, a) unique(calls$summary_hospital_call[calls$file_key == k & calls$awardee == a])
  expect_equal(call_of("NH", "Foundation for Healthy Communities (FHC)"), "NOT_HOSPITAL")
  cp <- readr::read_csv(here::here(SC_COMPONENTS_CSV), show_col_types = FALSE)
  expect_equal(cp$component_id, "NH_FHC_CAH_ACUTE_CARE_RFA")
  expect_equal(cp$component_usd, 17500000)
  expect_equal(cp$call, "HOSPITAL")
  expect_match(cp$source_quote, "approximately \\$17.5 million", fixed = FALSE)
  expect_equal(call_of("MS", "Delta Health Transformation Council, Inc."), "NOT_HOSPITAL")
  expect_equal(call_of("MS_R2", "Delta Health Transformation Council, Inc."), "NOT_HOSPITAL")
  tx <- tabs[["TX"]]
  b <- tx[tx$awardee == "St. Joseph Health Burleson", ]
  expect_equal(b$ccn, "451305"); expect_equal(b$distributed_to_hospital, "Yes")
  expect_equal(b$summary_call_basis, "CODED")
  ak <- tabs[["AK"]]
  expect_equal(ak$recipient_type[ak$awardee == "City of Ketchikan"], "LOCAL_GOVT_OR_PUBLIC_HEALTH")
})

test_that("the Task 1 rulings are in the strict files", {
  ca <- tabs[["CA"]]
  expect_equal(ca$distributed_to_hospital[ca$awardee == "UC San Diego Health"], "Yes")
  expect_equal(ca$recipient_subtype[ca$awardee == "UC San Diego Health"], "ACADEMIC_HEALTH_CENTER")
  expect_equal(ca$distributed_to_hospital[ca$awardee == "Providence Medical Foundation"], "No")
  expect_equal(ca$recipient_type[ca$awardee == "Providence Medical Foundation"], "PHYSICIAN_PRACTICE")
  expect_equal(ca$distributed_to_hospital[grepl("^Southern California Rural Health Collaborative", ca$awardee)], "No")
  pp <- tabs[["VA_VHCF_PP"]]
  expect_equal(pp$recipient_subtype[pp$awardee == "UVA Health"], "ACADEMIC_HEALTH_CENTER")
  expect_equal(pp$hospital_attribution[pp$awardee == "UVA Health"], "NAMED_HOSPITAL")
  vh <- tabs[["VA_VHCF"]]
  expect_true(all(vh$distributed_to_hospital[grepl("^UVA Health", vh$awardee)] == "No"))
})

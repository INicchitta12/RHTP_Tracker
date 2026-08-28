# test_03d_ga_great_health.R -------------------------------------------------
# Georgia GREAT Health Year 1 awardee extraction. Reads the committed archive
# off disk only -- no network calls, zero API quota.
#
# The assertions in R/03d_ga_great_health.R are run here as a block, and then
# the specific facts a future edit could quietly break are pinned individually:
# the reconciliation arithmetic, the 87-hospital accounting, and the four
# coding decisions that a reviewer is most likely to disagree with and that
# 0.3 / 0.3a / 10.2 have already settled.

library(testthat)

source(here::here("R", "03d_ga_great_health.R"))

records <- rhtp_ga_records()
recon <- rhtp_ga_reconcile(records)

recon_value <- function(line) recon$value[recon$line == line]


# -- Provenance --------------------------------------------------------------

test_that("every archived source page is on disk with a manifest", {
  for (p in unique(records$source_archive_path)) {
    expect_true(file.exists(here::here(p)), info = p)
  }
  expect_true(file.exists(here::here(
    "data", "evidence", "GA", "ga_great_health_announcements.manifest.txt"
  )))
})

test_that("the archived pages match the SHA-256 in the committed manifest", {
  manifest <- readLines(
    here::here("data", "evidence", "GA", "ga_great_health_announcements.manifest.txt"),
    warn = FALSE
  )
  stated <- manifest %>%
    stringr::str_subset("^\\s*sha256\\s*:") %>%
    stringr::str_remove("^\\s*sha256\\s*:\\s*") %>%
    stringr::str_trim()

  expect_length(stated, 4)

  actual <- sort(purrr::map_chr(
    sort(list.files(here::here("data", "evidence", "GA"),
                    pattern = "\\.html$", full.names = TRUE)),
    ~ digest::digest(file = .x, algo = "sha256")
  ))
  expect_setequal(actual, sort(stated))
})

test_that("all four phases are represented", {
  expect_setequal(unique(records$phase), c("1", "2", "3", "4"))
  expect_setequal(
    unique(records$phase_date),
    c("2026-06-08", "2026-07-16", "2026-07-23", "2026-08-27")
  )
})


# -- The assertion block -----------------------------------------------------

test_that("the full assertion block passes on the committed records", {
  expect_true(rhtp_ga_assert(records))
})

test_that("every categorical column validates against the 8 vocabulary", {
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed", "extraction_method")) {
    expect_true(
      all(stats::na.omit(records[[col]]) %in% rhtp_vocabulary(col)),
      info = col
    )
  }
})


# -- The reconciliation ------------------------------------------------------

test_that("the initiative pools sum to the phase totals DCH published", {
  by_phase <- records %>%
    dplyr::distinct(phase, initiative_number, initiative_amount) %>%
    dplyr::group_by(phase) %>%
    dplyr::summarise(total = sum(initiative_amount), .groups = "drop")

  expect_equal(by_phase$total[by_phase$phase == "1"], 12730000)
  expect_equal(by_phase$total[by_phase$phase == "2"], 30600000)
  expect_equal(by_phase$total[by_phase$phase == "3"], 60487500)
  expect_equal(by_phase$total[by_phase$phase == "4"], 93330827)
})

test_that("the residual closes on DCH's own 'under 10% administrative' statement", {
  # Two independent statements by DCH, made in different announcements, that
  # agree: the Year 1 award pools and the administrative-cost share.
  expect_equal(recon_value("GREAT Health Year 1 awarded (sum of initiative pools)"),
               197148327)
  expect_lt(recon_value("Residual as % of the CMS award"), 10)
  expect_gt(recon_value("Residual as % of the CMS award"), 9)
})

test_that("Georgia's CMS figure matches the 7.1 anchor", {
  # 0.2a: Tier 1 comes from CMS, never from a state press release. That the DCH
  # footnote agrees with the anchor to the cent is the cross-check, not the
  # source.
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE
  )
  ga <- anchor %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(), ~ .x %in% c("GA", "Georgia"))) %>%
    dplyr::select(dplyr::where(is.numeric)) %>%
    unlist() %>%
    unname()
  expect_equal(ga[ga > 1e6][1], GA_CMS_YEAR1_AWARD, tolerance = 1)
})

test_that("Phase 3's 80 hospitals at $750,000 close on the stated pool", {
  # The state states both the per-hospital figure and the initiative total, and
  # they agree independently. That is why this is the one cohort carrying an
  # amount.
  p3 <- records %>%
    dplyr::filter(phase == "3", initiative_number == "1")
  expect_equal(p3$recipient_count, 80L)
  expect_equal(p3$amount, 60000000)
  expect_equal(p3$recipient_count * 750000, p3$initiative_amount)
  expect_equal(p3$amount_confirmed, "Yes")
})


# -- No amount is ever divided (6.2) -----------------------------------------

test_that("no row carries an amount derived from splitting a pool", {
  divided <- records %>%
    dplyr::filter(!is.na(amount), amount_basis == "NOT_PUBLISHED")
  expect_equal(nrow(divided), 0)
})

test_that("summing amount does not reach the state total, and is not meant to", {
  # The trap this file exists to keep shut. `amount` is populated on 2 of 54
  # rows; a reader who sums it gets $60.5M for a state that awarded $197.1M.
  expect_lt(sum(records$amount, na.rm = TRUE),
            recon_value("GREAT Health Year 1 awarded (sum of initiative pools)"))
  expect_equal(sum(!is.na(records$amount)), 2)
})

test_that("Phase 4's seven AHEAD hospitals carry no amount", {
  # Phase 4 does not restate the $750,000 figure. Carrying it across from
  # Phase 3 would be an imputation dressed as arithmetic.
  p4 <- records %>%
    dplyr::filter(phase == "4",
                  stringr::str_detect(awardee, "^7 additional rural hospitals"))
  expect_equal(nrow(p4), 1)
  expect_true(is.na(p4$amount))
  expect_equal(p4$amount_confirmed, "No")
})


# -- The 87-hospital AHEAD cohort --------------------------------------------

test_that("the AHEAD cohorts account for exactly 87 hospitals", {
  ahead <- records %>%
    dplyr::filter(stringr::str_detect(awardee, "AHEAD Model pre-implementation"))
  expect_equal(nrow(ahead), 2)
  expect_equal(sum(ahead$recipient_count), 87L)
})

test_that("the AHEAD cohorts are flagged as names-not-captured, not confirmed", {
  # The class is confirmed by DCH; the individual names are on a blocked host.
  # recipient_confirmed = No is what stops these reading as 87 verified rows.
  ahead <- records %>%
    dplyr::filter(stringr::str_detect(awardee, "AHEAD Model pre-implementation"))
  expect_true(all(ahead$recipient_confirmed == "No"))
  expect_true(all(ahead$flag_reason == "RECIPIENT_NAMES_NOT_CAPTURED"))
  expect_true(all(ahead$distributed_to_hospital == "Yes"))
})


# -- The coding decisions worth pinning --------------------------------------

test_that("0.3a: school-based health infrastructure is judged on the recipient", {
  # Both Georgia cases are NON_HOSPITAL because the recipients are a state
  # education agency and a university. Delaware's identical activity is DIRECT
  # because Beebe Healthcare received it. Same setting, different recipients,
  # different codes -- 10.2, and the error 0.3a exists to prevent.
  doe <- records %>% dplyr::filter(awardee == "Georgia Department of Education")
  expect_equal(doe$flow_type, "NON_HOSPITAL")
  expect_equal(doe$distributed_to_hospital, "No")

  emory <- records %>% dplyr::filter(awardee == "Emory University")
  expect_equal(emory$flow_type, "NON_HOSPITAL")
  expect_equal(emory$distributed_to_hospital, "No")
  expect_true(stringr::str_detect(emory$strategy, "School-Based Health"))
})

test_that("0.3: eligibility is not receipt -- the ambulances stay Unclear", {
  amb <- records %>% dplyr::filter(stringr::str_detect(awardee, "^Type 2 ambulances"))
  expect_equal(nrow(amb), 1)
  expect_equal(amb$distributed_to_hospital, "Unclear")
  expect_equal(amb$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(amb$flag_reason, "ELIGIBILITY_NOT_RECEIPT")
})

test_that("no unresolved pass-through is coded Yes", {
  expect_equal(
    records %>%
      dplyr::filter(flow_type == "PASS_THROUGH_UNRESOLVED",
                    distributed_to_hospital == "Yes") %>%
      nrow(),
    0
  )
})

test_that("10.2: in-kind rows are No but keep hospital_benefiting = Yes", {
  in_kind <- records %>% dplyr::filter(flow_type == "IN_KIND_BENEFIT")
  expect_equal(nrow(in_kind), 3)
  expect_true(all(in_kind$distributed_to_hospital == "No"))
  expect_true(all(in_kind$hospital_benefiting == "Yes"))
  # Those dollars must never reach a distributed-to-hospitals total.
  expect_equal(sum(in_kind$amount, na.rm = TRUE), 0)
})

test_that("determination_basis is mandatory and populated on every row", {
  expect_false(any(is.na(records$determination_basis)))
  expect_true(all(nzchar(records$determination_basis)))
})


# -- The FL schema contract --------------------------------------------------

test_that("the first 19 columns are FL_year1_awardees.xlsx's, in order", {
  # The whole point of the schema match: the two states union without a reshape.
  fl <- openxlsx::read.xlsx(here::here("FL_year1_awardees.xlsx"), sheet = 1)
  expect_equal(names(records)[1:19], names(fl))
})

test_that("the Phase 2 organization count is pinned against DCH's own headline", {
  # DCH says 26; its page lists 27 distinct organizations across 28 award
  # actions. The gap is real and reported, not closed by dropping a name.
  expect_equal(recon_value("Phase 2 distinct organizations enumerated"), 27)
  expect_equal(recon_value("Phase 2 distinct organizations per DCH"), 26)
})


# -- Conventions -------------------------------------------------------------

ga_code <- function() {
  readLines(here::here("R", "03d_ga_great_health.R"), warn = FALSE) %>%
    stringr::str_remove("#.*$") %>%
    stringr::str_subset("\\S")
}

test_that("the stage spends no RCJ quota and makes no network call", {
  expect_false(any(grepl("rhtp_api_key|req_perform|httr2::|GET\\(", ga_code())))
})

test_that("the stage uses %>% and never setwd (CLAUDE.md 3)", {
  expect_false(any(grepl("|>", ga_code(), fixed = TRUE)))
  expect_false(any(grepl("setwd(", ga_code(), fixed = TRUE)))
})

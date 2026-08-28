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

  # Scoped to the four announcement archives the records cite. The roster page
  # sits in the same directory under its own manifest, so a bare *.html glob
  # would sweep it in and fail against a manifest that never described it.
  announcements <- sort(unique(records$source_archive_path))
  expect_length(announcements, 4)
  actual <- sort(purrr::map_chr(
    announcements,
    ~ digest::digest(file = here::here(.x), algo = "sha256")
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
  # they agree independently. That is why these are the rows carrying an amount.
  p3 <- records %>%
    dplyr::filter(phase == "3", initiative_number == "1",
                  strategy == "AHEAD Model pre-implementation funding")
  expect_equal(nrow(p3), 80L)
  expect_true(all(p3$recipient_count == 1L))
  expect_true(all(p3$amount == 750000))
  expect_equal(sum(p3$amount), 60000000)
  expect_equal(sum(p3$amount), unique(p3$initiative_amount))
  expect_true(all(p3$amount_confirmed == "Yes"))
})


# -- No amount is ever divided (6.2) -----------------------------------------

test_that("no row carries an amount derived from splitting a pool", {
  divided <- records %>%
    dplyr::filter(!is.na(amount), amount_basis == "NOT_PUBLISHED")
  expect_equal(nrow(divided), 0)
})

test_that("summing amount does not reach the state total, and is not meant to", {
  # The trap this file exists to keep shut. `amount` is populated on 81 of 139
  # rows; a reader who sums it gets $60.5M for a state that awarded $197.1M.
  # The 80 AHEAD hospitals each carry a figure DCH stated per recipient, so the
  # count grew with the expansion -- the total it reaches did not.
  expect_lt(sum(records$amount, na.rm = TRUE),
            recon_value("GREAT Health Year 1 awarded (sum of initiative pools)"))
  expect_equal(sum(!is.na(records$amount)), 81)
  expect_equal(sum(records$amount, na.rm = TRUE), 60487500)
})

test_that("Phase 4's seven AHEAD hospitals carry no amount", {
  # Phase 4 does not restate the $750,000 figure. Carrying it across from
  # Phase 3 would be an imputation dressed as arithmetic -- and it stays an
  # imputation now that the seven are named rather than one aggregate row.
  p4 <- records %>%
    dplyr::filter(phase == "4",
                  strategy == "AHEAD Model pre-implementation funding")
  expect_equal(nrow(p4), 7L)
  expect_true(all(is.na(p4$amount)))
  expect_true(all(p4$amount_confirmed == "No"))
  expect_true(all(p4$amount_basis == "NOT_PUBLISHED"))
})


# -- The 87-hospital AHEAD roster --------------------------------------------

test_that("the AHEAD group is 87 named hospitals, one row each", {
  ahead <- records %>%
    dplyr::filter(strategy == "AHEAD Model pre-implementation funding")
  expect_equal(nrow(ahead), 87L)
  expect_equal(sum(ahead$recipient_count), 87L)
  expect_equal(dplyr::n_distinct(ahead$awardee), 87L)
  expect_true(all(ahead$distributed_to_hospital == "Yes"))
  expect_true(all(ahead$recipient_type == "HOSPITAL_OR_SYSTEM"))
})

test_that("the AHEAD hospitals are recipient-confirmed, and cite both sources", {
  # Before the roster host was allowlisted these were two aggregate rows with
  # recipient_confirmed = No. The names are captured now, so the class-only
  # coding must be gone -- and no row may still describe an unnamed cohort.
  ahead <- records %>%
    dplyr::filter(strategy == "AHEAD Model pre-implementation funding")
  expect_true(all(ahead$recipient_confirmed == "Yes"))
  expect_true(all(ahead$recipient_names_source_url == GA_AHEAD_ROSTER_URL))
  expect_false(any(stringr::str_detect(ahead$awardee, "names not captured")))
  # The 8- and 13-hospital Phase 4 cohorts have no published roster and are
  # still aggregates; this expansion must not have touched them.
  expect_equal(sum(stringr::str_detect(records$awardee, "names not captured")), 2L)
  expect_false(any(ahead$flag_reason %in% "RECIPIENT_NAMES_NOT_CAPTURED"))
  # Every row still names the DCH announcement that made the award, because the
  # roster alone states no award (its heading is "Completed Applications").
  expect_true(all(stringr::str_detect(ahead$determination_basis,
                                      "DCH 2026-0[78]-2[37] announcement")))
})

test_that("only the Phase 4 seven are flagged as an inferred attribution", {
  ahead <- records %>%
    dplyr::filter(strategy == "AHEAD Model pre-implementation funding")
  flagged <- ahead %>%
    dplyr::filter(flag_reason %in% "PHASE_ATTRIBUTION_INFERRED")
  expect_equal(nrow(flagged), 7L)
  expect_true(all(flagged$phase == "4"))
  expect_true(all(is.na(flagged$amount)))
  # and the 80 that carry money are not flagged
  expect_true(all(is.na(ahead$flag_reason[ahead$phase == "3"])))
})


# -- The roster parser -------------------------------------------------------

test_that("the roster archive is on disk and matches its committed manifest", {
  expect_true(file.exists(here::here(GA_AHEAD_ROSTER_ARCHIVE)))
  manifest <- here::here("data", "evidence", "GA",
                         "ga_value_based_care_hospital_list.manifest.txt")
  expect_true(file.exists(manifest))
  stated <- readLines(manifest, warn = FALSE) %>%
    stringr::str_subset("^\\s*sha256\\s*:") %>%
    stringr::str_remove("^\\s*sha256\\s*:\\s*") %>%
    stringr::str_trim()
  actual <- unname(tools::md5sum(here::here(GA_AHEAD_ROSTER_ARCHIVE)))
  expect_equal(length(stated), 1L)
  expect_equal(
    stated,
    digest::digest(file = here::here(GA_AHEAD_ROSTER_ARCHIVE), algo = "sha256")
  )
  expect_true(!is.na(actual))
})

test_that("the roster parses to 87 hospitals split 80 / 7", {
  roster <- rhtp_ga_ahead_roster()
  expect_equal(nrow(roster), 87L)
  expect_equal(dplyr::n_distinct(roster$hospital_name), 87L)
  expect_equal(sum(roster$phase == "3"), 80L)
  expect_equal(sum(roster$phase == "4"), 7L)
  expect_true(all(nzchar(roster$address)))
})

test_that("the phase split is derived from the alphabetical break, not hardcoded", {
  # This is the inference the whole Phase 3 / Phase 4 amount attribution rests
  # on, so it is asserted rather than assumed: rows 1-80 are in order and row 81
  # is not. If DCH re-sorts the page the parser must refuse, not mis-attribute
  # $750,000 to a hospital DCH never stated a figure for.
  roster <- rhtp_ga_ahead_roster()
  expect_equal(ga_alphabetical_prefix(roster$hospital_name), 80L)
  expect_equal(ga_alphabetical_prefix(c("Alpha", "Beta", "Gamma")), 3L)
  expect_equal(ga_alphabetical_prefix(c("Alpha", "Beta", "Aardvark")), 2L)
})

test_that("the parser refuses a roster whose alphabetical run is not 80", {
  # Reproduce a re-sorted page by handing the expansion a fully sorted roster:
  # the break the split is read from is gone, so it must fail loudly.
  resorted <- tempfile(fileext = ".html")
  rows <- paste0("<tr><td>", sprintf("Hospital %02d", 1:87),
                 "</td><td>1 Main St</td><td>Town, GA 30000</td><td>CAH</td></tr>",
                 collapse = "")
  writeLines(paste0("<html><body><table><tr><th>HOSPITAL NAME</th><th>ADDRESS</th>",
                    "<th>CITY/STATE/ZIP</th><th>DESIGNATION</th></tr>",
                    rows, "</table></body></html>"), resorted)
  expect_error(rhtp_ga_ahead_roster(resorted), "leading alphabetical run")
})

test_that("the parser refuses a roster that is not 87 hospitals", {
  short <- tempfile(fileext = ".html")
  rows <- paste0("<tr><td>", sprintf("Hospital %02d", 1:12),
                 "</td><td>1 Main St</td><td>Town, GA 30000</td><td>CAH</td></tr>",
                 collapse = "")
  writeLines(paste0("<html><body><table><tr><th>HOSPITAL NAME</th><th>ADDRESS</th>",
                    "<th>CITY/STATE/ZIP</th><th>DESIGNATION</th></tr>",
                    rows, "</table></body></html>"), short)
  expect_error(rhtp_ga_ahead_roster(short), "parses to 12 hospitals")
})

test_that("the parser refuses a roster whose columns do not resolve", {
  odd <- tempfile(fileext = ".html")
  writeLines(paste0("<html><body><table><tr><th>Col A</th><th>Col B</th>",
                    "<th>Col C</th><th>Col D</th></tr>",
                    "<tr><td>x</td><td>y</td><td>z</td><td>w</td></tr>",
                    "</table></body></html>"), odd)
  expect_error(rhtp_ga_ahead_roster(odd), "Refusing to guess")
})

test_that("Georgia's own designations are kept raw and mapped to NONE", {
  # 8: the controlled column takes only CMS designations; the state's raw
  # language is preserved beside it rather than discarded.
  ahead <- records %>%
    dplyr::filter(strategy == "AHEAD Model pre-implementation funding")
  expect_setequal(unique(ahead$rural_designation), c("CAH", "RRC", "NONE"))
  expect_equal(sum(ahead$rural_designation == "CAH"), 30L)
  expect_equal(sum(ahead$rural_designation == "RRC"), 18L)
  expect_equal(sum(ahead$rural_designation == "NONE"), 39L)
  none_raw <- unique(ahead$rural_designation_raw[ahead$rural_designation == "NONE"])
  expect_setequal(none_raw, c("Rural", "In 126 Rural/Partial Rural Counties"))
  # and no non-AHEAD row picked up a designation it has no source for
  expect_true(all(is.na(records$rural_designation[
    records$strategy != "AHEAD Model pre-implementation funding"])))
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

test_that("the first 19 columns are Florida's leading block, in order", {
  # The whole point of the schema match: the two states union without a reshape.
  # Florida gained three columns of its own in session 10 (the preserved
  # recipient_type_source and the two the back-fit sets), so the contract is on
  # the shared leading block rather than on Florida's full width.
  fl <- openxlsx::read.xlsx(here::here("FL_year1_awardees.xlsx"), sheet = 1)
  expect_gte(ncol(fl), 19L)
  expect_equal(names(records)[1:19], names(fl)[1:19])
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

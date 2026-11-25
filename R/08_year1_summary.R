# 08_year1_summary.R ----------------------------------------------------------
# Session 110. THE YEAR 1 SUMMARY TABLE: ONE ROW PER STATE, AND A NATIONAL ROW.
#
# Built for the owner's Year 1 summary (due 2026-11-02). Session 110 ran it on
# that day's data as a DRY RUN and pinned the totals in
# tests/testthat/test_08_year1_summary.R; the Monday session re-runs it after
# its sweep and re-pins.
#
# EVERY HOSPITAL DOLLAR HERE COMES FROM THE SUMMARY-CALL LAYER (R/07), WHICH
# GIVES EVERY AWARD ROW A TWO-VALUED CALL. The table therefore shows:
#
#   hospital_coded_usd         rows called HOSPITAL whose strict determination
#                              carried over (CODED)
#   hospital_best_judgment_usd rows called HOSPITAL on a written judgment, plus
#                              the shared pools R/07 calls HOSPITAL (counted
#                              whole, once, never split; split out in
#                              hospital_bj_pool_usd), plus any separately
#                              priced component of a row R/07 calls HOSPITAL
#                              (hospital_bj_component_usd; session 111)
#   hospital_summary_usd       the two added: the owner's single-call view.
#
# AND BESIDE IT, UNCHANGED, THE STRICT PARTITION (NAMED / POOL_NAMED /
# POOL_UNNAMED) from rhtp_hospital_dollar_partition(). The strict buckets are
# still never added to one another anywhere in this repository; the summary
# figure is a different measure, built from a different column, and the test
# proves the identity that links them: every strict-Yes, non-SOURCE_SUSPECT
# dollar is in hospital_summary_usd (as CODED, or as BEST_JUDGMENT where a
# shared award or open question made the call a judgment), so
#   hospital_summary_usd = NAMED + POOL_NAMED + POOL_UNNAMED
#                          + best-judgment HOSPITAL dollars on strict-non-Yes rows
#                          + HOSPITAL pools + HOSPITAL components
#                          - best-judgment NOT_HOSPITAL dollars on strict-Yes rows.
#
# SOURCE_SUSPECT rows stay OUT of every hospital figure (owner ruling, session
# 102); layer_source_suspect_usd shows what was left out. The other layers are
# INSIDE hospital_summary_usd and subtract: academic health centres
# (recipient_subtype), GENERAL_KNOWLEDGE typings (basis_type), LOW confidence,
# intents (NOTICE_OF_INTENT_TO_AWARD), CMS obligation-report lines, and the
# best-judgment dollars themselves. The layers overlap; never add them.
#
# DENOMINATORS. award_total_usd is the state's published Year 1 award total:
# priced rows (sum of `amount`) plus the Tier 3 round figures a state prints
# without a per-recipient split, read by R/03aw's own per-file rule
# (y1_file_figures(): distinct pools once, Georgia's per-initiative figures,
# South Dakota's in-round contracts netted out, New Hampshire's ceiling
# excluded, a round figure whose own pool is already priced not added again --
# Nevada, session 111), applied here to EVERY file in STATE_FILES -- R/03aw's own list
# lags (it omits MS_R2, MD_LABOR, VA_VHCF, NE_CMS, PA_CMS, RI and IN_GROW) --
# plus any R/07 pool that no file carries as a round figure (Ohio's two
# shared sub-pools). Every hospital dollar in the numerator is therefore in
# the denominator. Iowa's Tier 2 RFP pools are never added (§0.2).
# allotment is CMS's FY2026 table (§7.1).
#
# Usage:
#   Rscript R/08_year1_summary.R --build    # data/reference/year1_summary_<date>.csv AND
#                                           # output/year1_summary_<date>.xlsx (Overview,
#                                           # Detail, Vendor spending, By use category,
#                                           # Definitions, Notes and caveats, Sources) AND
#                                           # data/reference/year1_use_categories_<date>.csv
#                                           # (session 123; needs R/11 --apply first)
#   Rscript R/08_year1_summary.R --report

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_summary_calls.R"))
source(here::here("R", "07_summary_calls.R"))
source(here::here("R", "03aw_year1_completion_status.R"))
source(here::here("R", "utils_spend_category.R"))
source(here::here("R", "11_use_categories.R"))   # session 123: the use-category layer

YS_ALLOT  <- "data/reference/cms_fy2026_allotments.csv"
YS_STATUS <- "data/reference/year1_completion_status.csv"
YS_SURVEY <- "data/reference/rcj_state_survey.csv"
YS_POOLS  <- "data/reference/summary_call_pools.csv"
YS_COMPONENTS <- "data/reference/summary_call_components.csv"
YS_RURAL  <- "data/reference/rural_cut_rows.csv"
YS_OUT    <- function(date) file.path("data", "reference", paste0("year1_summary_", date, ".csv"))
YS_XLSX   <- function(date) file.path("output", paste0("year1_summary_", date, ".xlsx"))

ys_has <- function(x, code) !is.na(x) & grepl(paste0("(^|;)", code, "(;|$)"), x)

#' Every award row, with the columns the summary reads
ys_rows <- function(files = sc_state_files()) {
  dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"),
                         na = c("", "NA"), progress = FALSE)
    rhtp_assert_summary_calls(d, k)
    d <- rhtp_year1_only(d, k)   # session 116: the Year 1 summary reads Year 1 rows only
    col <- function(c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))
    tibble::tibble(
      file_key = k, file = files[[k]], state = d$state, awardee = d$awardee,
      amount = suppressWarnings(as.numeric(d$amount)),
      distributed_to_hospital = d$distributed_to_hospital, flow_type = col("flow_type"),
      recipient_type = col("recipient_type"), hospital_attribution = col("hospital_attribution"),
      flag_reason = col("flag_reason"), basis_type = col("basis_type"),
      determination_confidence = col("determination_confidence"),
      recipient_subtype = col("recipient_subtype"),
      validation_source_type = col("validation_source_type"),
      source_document_title = col("source_document_title"),
      state_source_url = col("state_source_url"),
      source_archive_path = col("source_archive_path"),
      confidential_hit = ys_confidential_hit(d),
      call = d$summary_hospital_call, basis = d$summary_call_basis)
  }))
}

# -- confidential sources (session 111) ------------------------------------------
#
# DELAWARE'S CONFIDENTIAL SOURCE IS `DE Verify.xlsx` (repository root; owner-
# supplied hand verification, rows sourced "API call" and "FDC qc"; never
# ingested, open blocker 2). Any award row or status row whose text cites it is
# flagged, and every figure built on a flagged row is flagged on the Detail
# sheet (and its row shaded on Overview and Detail). The scan reads EVERY column, so a citation added to any field later is
# caught. Session 111 found NO award row citing it: Delaware's figures rest on
# DHSS and Governor press releases; four of its status-table channels cite it
# (DHIN, Delaware Health Force, Thomas Jefferson University, the diabetes
# pilot's named hospitals), none of which carries a figure in this table.
YS_CONFIDENTIAL_SOURCES <- c("DE Verify.xlsx")
YS_CONFIDENTIAL_NOTE <- paste(
  "Figures or rows flagged here rest on, or cite, Delaware's confidential source (DE Verify.xlsx).",
  "They must not leave the team.")

ys_confidential_hit <- function(d) {
  if (!nrow(d)) return(logical(0))
  txt <- do.call(paste, c(lapply(d, function(x) dplyr::coalesce(as.character(x), "")), sep = " | "))
  Reduce(`|`, lapply(YS_CONFIDENTIAL_SOURCES, function(src) grepl(src, txt, fixed = TRUE)))
}

#' Status-table rows (data/reference/<st>_year1_status.csv) that cite a
#' confidential source, per state
ys_confidential_status <- function() {
  fs <- list.files(here::here("data/reference"), "^[a-z]{2}_year1_status\\.csv$", full.names = TRUE)
  dplyr::bind_rows(lapply(fs, function(f) {
    d <- readr::read_csv(f, col_types = readr::cols(.default = "c"), progress = FALSE)
    tibble::tibble(state = toupper(substr(basename(f), 1, 2)),
                   status_rows_citing = sum(ys_confidential_hit(d)))
  })) %>% dplyr::filter(status_rows_citing > 0)
}

ys_usd <- function(x) sum(x, na.rm = TRUE)

#' R/03aw's per-file published figures, over every file in STATE_FILES
ys_file_figures <- function(files = sc_state_files()) {
  dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"),
                         progress = FALSE)
    y1_file_figures(unique(d$state)[1], basename(files[[k]]))
  }))
}

#' The per-state table, national row last
ys_build <- function(rows = ys_rows(), pools = NULL, components = NULL, files = sc_state_files(),
                     subset = TRUE) {
  if (is.null(pools)) {
    pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE, progress = FALSE)
  }
  if (is.null(components)) {
    components <- readr::read_csv(here::here(YS_COMPONENTS), show_col_types = FALSE, progress = FALSE)
  }
  allot <- readr::read_csv(here::here(YS_ALLOT), show_col_types = FALSE, progress = FALSE)
  status <- readr::read_csv(here::here(YS_STATUS), show_col_types = FALSE, progress = FALSE)
  survey <- readr::read_csv(here::here(YS_SURVEY), show_col_types = FALSE, progress = FALSE)
  rural <- readr::read_csv(here::here(YS_RURAL), col_types = readr::cols(.default = "c"), progress = FALSE) %>%
    dplyr::filter(file %in% basename(unlist(files)))

  # Session 119 (owner Task 1c): an administrator row whose fee and pass-through
  # share are unsplit (ADMINISTRATOR_PASS_THROUGH_UNRESOLVED: NM Accenture) is
  # held OUT of every award and hospital figure, and so out of the >=50% subset
  # test; its dollars are shown in excluded_award_usd.
  excl_by <- rows %>% dplyr::filter(ys_has(flag_reason, YS_EXCLUDED_FLAG)) %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(excluded_award_usd = ys_usd(amount), .groups = "drop")
  rows <- rows %>% dplyr::filter(!ys_has(flag_reason, YS_EXCLUDED_FLAG))
  rows <- rows %>% dplyr::mutate(
    suspect = ys_has(flag_reason, "SOURCE_SUSPECT"),
    amt = dplyr::coalesce(amount, 0),
    hosp = call == "HOSPITAL" & !suspect,
    # The owner's standing association/network ruling and §10.2's association
    # row: hospital dollars paid to an intermediary that is not itself typed a
    # hospital (associations, networks, cooperatives, a network's foundation).
    assoc = hosp & recipient_type %in% c("NONPROFIT_CBO", "HOSPITAL_AFFILIATED_ENTITY") &
      flow_type %in% c("PASS_THROUGH_DESIGNATED", "PASS_THROUGH_UNRESOLVED", "IN_KIND_BENEFIT"),
    named_unpriced = hosp & is.na(amount) & !recipient_type %in% "NOT_YET_NAMED")

  part <- rhtp_hospital_dollar_partition(rows %>% dplyr::select(-suspect, -amt, -hosp, -assoc, -named_unpriced))
  strict <- part %>%
    dplyr::select(state, bucket, dollars) %>%
    tidyr::pivot_wider(names_from = bucket, values_from = dollars, values_fill = 0)
  for (b in c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS")) {
    if (!b %in% names(strict)) strict[[b]] <- 0
  }

  pool_by <- pools %>% dplyr::group_by(state) %>% dplyr::summarise(
    called_pool_outside_files_usd = ys_usd(pool_usd[!in_file_round_figures]),
    hospital_bj_pool_usd = ys_usd(pool_usd[call == "HOSPITAL"]), .groups = "drop")
  comp_by <- components %>% dplyr::group_by(state) %>% dplyr::summarise(
    hospital_bj_component_usd = ys_usd(component_usd[call == "HOSPITAL"]),
    not_hospital_component_usd = ys_usd(component_usd[call == "NOT_HOSPITAL"]), .groups = "drop")
  fig <- ys_file_figures(files) %>% dplyr::group_by(state) %>% dplyr::summarise(
    file_pool_level_usd = ys_usd(pool_level_unpriced - priced_inside_pool),
    .groups = "drop")
  rur <- rural %>% dplyr::mutate(amount = as.numeric(amount)) %>% dplyr::group_by(state) %>%
    dplyr::summarise(
      strict_rural_cut_usd = ys_usd(amount[counts_as_rural == "TRUE"]),
      strict_cah_usd = ys_usd(amount[!is.na(ccn) & grepl("^[0-9]{2}13[0-9]{2}$", ccn)]), .groups = "drop")
  conf_status <- ys_confidential_status()

  by <- rows %>% dplyr::group_by(state) %>% dplyr::summarise(
    award_files = dplyr::n_distinct(file_key),
    award_rows = dplyr::n(),
    priced_rows = sum(!is.na(amount)),
    published_priced_usd = ys_usd(amount),
    award_intent_usd = ys_usd(amount[validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD"]),
    hospital_rows = sum(hosp),
    hospital_coded_usd = ys_usd(amt[hosp & basis == "CODED"]),
    hospital_bj_row_usd = ys_usd(amt[hosp & basis == "BEST_JUDGMENT"]),
    best_judgment_rows = sum(basis == "BEST_JUDGMENT"),
    named_hospital_rows_no_amount = sum(named_unpriced),
    named_hospital_recipients_no_amount = dplyr::n_distinct(awardee[named_unpriced]),
    layer_ahc_usd = ys_usd(amt[hosp & recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"]),
    layer_general_knowledge_usd = ys_usd(amt[hosp & basis_type %in% "GENERAL_KNOWLEDGE"]),
    layer_low_confidence_usd = ys_usd(amt[hosp & determination_confidence %in% "LOW"]),
    layer_intent_usd = ys_usd(amt[hosp & validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD"]),
    layer_association_ruling_usd = ys_usd(amt[assoc]),
    layer_cms_obligation_usd = ys_usd(amt[hosp & validation_source_type %in% "CMS_OBLIGATION_REPORT"]),
    layer_source_suspect_usd = ys_usd(amt[call == "HOSPITAL" & suspect]),
    confidential_award_rows = sum(confidential_hit),
    confidential_award_usd = ys_usd(amt[confidential_hit]),
    .groups = "drop")

  st_status <- dplyr::bind_rows(
    status %>% dplyr::transmute(state, completion_status = year1_status),
    survey %>% dplyr::filter(!state %in% status$state) %>%
      dplyr::transmute(state, completion_status = paste0("NOT_ASSESSED (survey: ", extraction_status, ")")))

  num_cols <- c("published_priced_usd", "award_intent_usd", "hospital_coded_usd", "hospital_bj_row_usd",
                "called_pool_outside_files_usd", "file_pool_level_usd", "hospital_bj_pool_usd",
                "hospital_bj_component_usd", "not_hospital_component_usd",
                "NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS",
                "strict_rural_cut_usd", "strict_cah_usd", "confidential_award_usd", "excluded_award_usd")
  int_cols <- c("award_files", "award_rows", "priced_rows", "hospital_rows", "best_judgment_rows",
                "named_hospital_rows_no_amount", "named_hospital_recipients_no_amount",
                "confidential_award_rows", "status_rows_citing")
  out <- allot %>%
    dplyr::select(state, state_name, allotment_usd = fy2026_allotment) %>%
    dplyr::left_join(by, by = "state") %>%
    dplyr::left_join(pool_by, by = "state") %>%
    dplyr::left_join(comp_by, by = "state") %>%
    dplyr::left_join(fig, by = "state") %>%
    dplyr::left_join(strict, by = "state") %>%
    dplyr::left_join(rur, by = "state") %>%
    dplyr::left_join(conf_status, by = "state") %>%
    dplyr::left_join(excl_by, by = "state") %>%
    dplyr::left_join(st_status, by = "state") %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(int_cols), ~ dplyr::coalesce(as.integer(.x), 0L)),
                  dplyr::across(c(dplyr::all_of(num_cols), dplyr::starts_with("layer_")), ~ dplyr::coalesce(.x, 0)),
                  completion_status = dplyr::coalesce(completion_status, "NOT_ASSESSED"))

  national <- out %>% dplyr::summarise(
    state = "US", state_name = "National (50 states)",
    dplyr::across(c(allotment_usd, dplyr::all_of(int_cols), dplyr::all_of(num_cols),
                    dplyr::starts_with("layer_")), sum),
    completion_status = paste0(sum(completion_status == "COMPLETE"), " COMPLETE of 50"))

  tab <- dplyr::bind_rows(out %>% dplyr::arrange(state), national) %>%
    dplyr::mutate(
      pool_level_usd = file_pool_level_usd + called_pool_outside_files_usd,
      award_total_usd = published_priced_usd + pool_level_usd,
      hospital_best_judgment_usd = hospital_bj_row_usd + hospital_bj_pool_usd + hospital_bj_component_usd,
      hospital_summary_usd = hospital_coded_usd + hospital_best_judgment_usd,
      hospital_share_of_awards_pct = ys_pct(hospital_summary_usd, award_total_usd),
      hospital_share_of_allotment_pct = ys_pct(hospital_summary_usd, allotment_usd),
      award_share_of_allotment_pct = ys_pct(award_total_usd, allotment_usd),
      confidential_source_flag = dplyr::case_when(
        confidential_award_rows > 0 ~ paste0("YES: ", confidential_award_rows, " award row(s) / $",
                                             formatC(confidential_award_usd, format = "f", digits = 2, big.mark = ","),
                                             " cite a confidential source; do not circulate outside the team"),
        status_rows_citing > 0 ~ paste0("CITED IN STATUS NOTES: ", status_rows_citing,
                                        " status-table row(s) cite a confidential source; no figure in this row rests on it; do not circulate those notes outside the team"),
        TRUE ~ "")) %>%
    dplyr::transmute(
      state, state_name, completion_status, allotment_usd,
      award_files, award_rows, priced_rows,
      published_priced_usd, pool_level_usd, award_total_usd, award_share_of_allotment_pct,
      award_intent_usd,
      hospital_rows, hospital_coded_usd, hospital_best_judgment_usd,
      hospital_bj_row_usd, hospital_bj_pool_usd, hospital_bj_component_usd, best_judgment_rows,
      hospital_summary_usd, hospital_share_of_awards_pct, hospital_share_of_allotment_pct,
      strict_named_hospital_usd = NAMED_HOSPITAL,
      strict_pool_named_hospitals_usd = POOL_NAMED_HOSPITALS,
      strict_pool_unnamed_hospitals_usd = POOL_UNNAMED_HOSPITALS,
      layer_intent_usd, layer_association_ruling_usd, layer_cms_obligation_usd,
      layer_ahc_usd, layer_general_knowledge_usd, layer_low_confidence_usd,
      strict_rural_cut_usd, strict_cah_usd,
      named_hospital_recipients_no_amount, named_hospital_rows_no_amount,
      layer_source_suspect_usd,
      excluded_award_usd,
      confidential_source_flag)
  if (!subset) return(tab)
  dplyr::bind_rows(tab, ys_subset_row(rows, pools, components, files))
}

ys_pct <- function(n, d) ifelse(d > 0, round(100 * n / d, 1), NA_real_)

# -- the second national row (session 111b, owner decision) -----------------------
#
# The national hospital share of AWARDS is n/m (national awards published are
# under half the allotment). It is reported instead over the states where most
# of the money is published: those whose award total is at least
# YS_AWARD_SHARE_MIN of their allotment. Every column is the sum over those
# states, and the three shares are recomputed from the sums, exactly as the
# national row is built from all fifty. It is a SUBSET of the fifty, never added
# to the national row.
#
# IT RESTS ON STATE AWARD SOURCES ONLY (owner decisions). Rows taken from CMS's
# Obligated Funds Report (validation_source_type CMS_OBLIGATION_REPORT; whole
# files: ne_cms_obligation_awardees, pa_cms_obligation_awardees,
# ri_year1_awardees) are removed BEFORE the state table is rebuilt for the
# subset, so each state's "% published" is its state-sourced award total over
# its allotment, and a state qualifies when that is at least YS_AWARD_SHARE_MIN.
# A state keeps its state-sourced dollars and loses only its CMS lines:
# Rhode Island, whose every row is a CMS line, has no state-sourced awards and
# cannot qualify; Nebraska and Pennsylvania would qualify, if they crossed the
# line, on their state files alone.
YS_NATIONAL <- c("US", "US_GE50")
YS_EXCLUDED_FLAG <- "ADMINISTRATOR_PASS_THROUGH_UNRESOLVED"
YS_AWARD_SHARE_MIN <- 0.5

#' States carrying any CMS obligation-report award row
ys_cms_obligation_states <- function(rows) {
  sort(unique(rows$state[rows$validation_source_type %in% "CMS_OBLIGATION_REPORT"]))
}

#' The award files whose rows are CMS obligation-report lines. A file mixing
#' them with state-sourced rows is refused: the subset drops files, not rows.
ys_cms_obligation_files <- function(rows) {
  by <- rows %>% dplyr::group_by(file_key) %>%
    dplyr::summarise(cms = sum(validation_source_type %in% "CMS_OBLIGATION_REPORT"), n = dplyr::n(), .groups = "drop")
  mixed <- by$file_key[by$cms > 0 & by$cms < by$n]
  if (length(mixed)) {
    stop("[year1 summary] award file(s) mix CMS obligation lines with state-sourced rows: ",
         paste(mixed, collapse = ", "), call. = FALSE)
  }
  by$file_key[by$cms > 0]
}

#' The per-state table rebuilt from state-sourced award files only
ys_state_source_table <- function(rows, pools, components, files) {
  cms <- ys_cms_obligation_files(rows)
  ss_rows <- rows[!rows$file_key %in% cms, ]
  tab <- ys_build(ss_rows, pools, components, files = files[!names(files) %in% cms], subset = FALSE)
  tab[!tab$state %in% YS_NATIONAL, ]
}

ys_subset_members <- function(rows, pools, components, files) {
  st <- ys_state_source_table(rows, pools, components, files)
  st[st$allotment_usd > 0 & st$award_total_usd / st$allotment_usd >= YS_AWARD_SHARE_MIN, ]
}

ys_subset_row <- function(rows, pools, components, files) {
  m <- ys_subset_members(rows, pools, components, files)
  if (any(m$layer_cms_obligation_usd != 0)) {
    stop("[year1 summary] a CMS-obligation dollar reached the state-source subset", call. = FALSE)
  }
  tab <- m
  num <- names(tab)[vapply(tab, is.numeric, logical(1))]
  row <- m %>% dplyr::summarise(dplyr::across(dplyr::all_of(num), sum))
  row$award_share_of_allotment_pct <- ys_pct(row$award_total_usd, row$allotment_usd)
  row$hospital_share_of_awards_pct <- ys_pct(row$hospital_summary_usd, row$award_total_usd)
  row$hospital_share_of_allotment_pct <- ys_pct(row$hospital_summary_usd, row$allotment_usd)
  row$state <- "US_GE50"
  row$state_name <- paste0("States with \u2265", 100 * YS_AWARD_SHARE_MIN, "% published, state award sources (n = ", nrow(m), ")")
  row$completion_status <- paste0(sum(m$completion_status == "COMPLETE"), " COMPLETE of ", nrow(m), ": ",
                                  paste(m$state, collapse = " "))
  flagged <- m$state[nzchar(m$confidential_source_flag)]
  row$confidential_source_flag <- if (length(flagged)) {
    paste0("MEMBER STATES FLAGGED: ", paste(flagged, collapse = ", "), "; see their rows")
  } else ""
  row[, names(tab)]
}

# -- the workbook (session 111) ---------------------------------------------------

#' Plain-language definitions, one per Detail (CSV) column, in column order. The
#' builder refuses a column without one.
YS_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "state", "Two-letter state code. US is the national row (the sum of the 50 state rows). US_GE50 is the second national row, on state award sources only: CMS obligation-report rows are removed from all its figures, and it sums the states whose state-sourced awards published are at least 50% of their allotment (Rhode Island, whose only rows are CMS lines, cannot qualify); a subset of US, never added to it.",
  "state_name", "State name.",
  "completion_status", "Whether the state has finished awarding its Year 1 money: COMPLETE (a state source says so), PARTIAL (more awards are coming or initiatives remain unawarded), or NOT_ASSESSED (the repository has not judged it; the survey status is shown).",
  "allotment_usd", "The state's FY2026 RHTP allotment from CMS (Tier 1), from CMS's own table.",
  "award_files", "Number of state award files the repository has extracted for this state.",
  "award_rows", "Number of award rows (one per award line the state published) across those files.",
  "priced_rows", "Award rows that carry a published dollar amount.",
  "published_priced_usd", "Sum of the published per-award amounts.",
  "pool_level_usd", "Award money the state published only as a pool or round total, without a per-recipient split, counted once per pool and never divided.",
  "award_total_usd", "Published Year 1 award total: per-award amounts plus pool-level totals. Every hospital dollar in this table is inside it.",
  "award_share_of_allotment_pct", "Award total as a percent of the allotment.",
  "award_intent_usd", "Part of the per-award amounts published only as intents to award (not executed agreements), all recipients.",
  "hospital_rows", "Award rows called HOSPITAL (by the strict coding or by a best judgment).",
  "hospital_coded_usd", "Hospital dollars where the strict, source-based coding already says the money went to a hospital.",
  "hospital_best_judgment_usd", "Hospital dollars resting on a best judgment where the strict coding is undetermined or shared: judged award rows, shared pools, and separately priced components of a row. Subtract this column to return to coded figures.",
  "hospital_bj_row_usd", "The part of the best-judgment dollars on individual award rows.",
  "hospital_bj_pool_usd", "The part of the best-judgment dollars on shared pools called HOSPITAL because typed hospitals are a strict majority of the named members (counted whole, never split).",
  "hospital_bj_component_usd", "The part of the best-judgment dollars on a separately priced component of one award row (New Hampshire's CAH and Acute Care Hospital RFA).",
  "best_judgment_rows", "Award rows whose call is a best judgment rather than the strict coding.",
  "hospital_summary_usd", "BEST ESTIMATE of Year 1 RHTP dollars reaching hospitals: coded plus best-judgment hospital dollars.",
  "hospital_share_of_awards_pct", "Best-estimate hospital dollars as a percent of the published award total. On the workbook's Detail sheet it reads n/m where the state's state-sourced awards (CMS obligation-report rows left out) are under 50% of its allotment; this CSV keeps the computed value.",
  "hospital_share_of_allotment_pct", "Best-estimate hospital dollars as a percent of the allotment.",
  "strict_named_hospital_usd", "STRICT: dollars awarded to a named hospital or health system on a state source. The defensible floor. Never added to the two strict pool columns.",
  "strict_pool_named_hospitals_usd", "STRICT: dollars awarded to an intermediary for named hospitals, with no per-hospital split published. Never added to the other strict columns.",
  "strict_pool_unnamed_hospitals_usd", "STRICT: dollars awarded to an intermediary for hospitals it has not named (for example a hospital association). Never added to the other strict columns.",
  "layer_intent_usd", "Part of the best-estimate hospital dollars that are intents to award, not executed agreements.",
  "layer_association_ruling_usd", "Part of the best-estimate hospital dollars paid to a hospital association, network or cooperative that is not itself a hospital, counted as hospital money under the standing association ruling.",
  "layer_cms_obligation_usd", "Part of the best-estimate hospital dollars taken from CMS's obligation report (obligated, per CMS) rather than a state award document.",
  "layer_ahc_usd", "Part of the best-estimate hospital dollars awarded to academic health centres typed as hospitals.",
  "layer_general_knowledge_usd", "Part of the best-estimate hospital dollars where the recipient's form rests on general knowledge, not a citable source.",
  "layer_low_confidence_usd", "Part of the best-estimate hospital dollars coded at LOW confidence.",
  "strict_rural_cut_usd", "Part of the strict named-hospital dollars going to hospitals counted rural (critical access hospitals by CCN and state rural designations).",
  "strict_cah_usd", "Part of the strict named-hospital dollars going to critical access hospitals identified by a CCN on the row (CCN 13xx). Rows with no CCN are not counted, so this understates CAH dollars where a state's rows carry no CCN (Wyoming, for example, is rural by state designation).",
  "named_hospital_recipients_no_amount", "Named hospital recipients (distinct names) with no published amount. Their money is not in any dollar column, so the hospital share is understated where this is above zero.",
  "named_hospital_rows_no_amount", "Award rows behind the previous column.",
  "layer_source_suspect_usd", "Hospital dollars on rows whose published amount is internally inconsistent (SOURCE_SUSPECT). EXCLUDED from every hospital figure; shown so the exclusion is visible.",
  "excluded_award_usd", "Award dollars held OUT of every figure in this row, including the award total and the >=50% subset test, pending a ruling: an administrator's award whose own fee and the programme money it pays on are not split on any state source (flag ADMINISTRATOR_PASS_THROUGH_UNRESOLVED; New Mexico's Accenture ASO subaward, session 119). Never a hospital dollar.",
  "confidential_source_flag", "Marks a state whose rows or notes cite Delaware's confidential source (DE Verify.xlsx). Flagged material must not leave the team.")

#' Each state carrying CMS obligation lines: its share of allotment published with
#' and without them, and whether it qualifies on state-sourced awards
ys_cms_state_shares <- function(s, rows) {
  cms <- ys_cms_obligation_states(rows)
  if (!length(cms)) return("none")
  ss <- ys_state_source_table(rows, NULL, NULL, sc_state_files())
  vapply(cms, function(x) {
    all_sh <- s$award_total_usd[s$state == x] / s$allotment_usd[s$state == x]
    ss_sh <- ss$award_total_usd[ss$state == x] / ss$allotment_usd[ss$state == x]
    paste0(s$state_name[s$state == x], " ", sprintf("%.1f%%", 100 * ss_sh), " state-sourced (",
           sprintf("%.1f%%", 100 * all_sh), " with CMS lines; ",
           if (ss_sh >= YS_AWARD_SHARE_MIN) "qualifies" else "does not qualify", ")")
  }, character(1))
}

#' The states whose best-estimate hospital dollars include intents, largest
#' first, with each state's intent figure. Session 114: computed from the
#' table so the Notes line cannot drift from the data (it was hand-written).
ys_intent_states <- function(s) {
  x <- s[!s$state %in% YS_NATIONAL & s$layer_intent_usd > 0, ]
  if (!nrow(x)) return("no state")
  x <- x[order(-x$layer_intent_usd, x$state_name), ]
  paste0(paste0(x$state_name, " ", paste0("$", formatC(x$layer_intent_usd, format = "f", digits = 0, big.mark = ",")),
                collapse = "; "),
         "; ", nrow(x), " state", if (nrow(x) > 1) "s" else "")
}

ys_notes <- function(s, date, rows) {
  us <- s[s$state == "US", ]
  ge <- s[s$state == "US_GE50", ]
  f <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  tibble::tibble(note = c(
    paste0("HOW TO READ THIS. Start on Overview (one row per state, then the national total and the states with at least half their money published): 'Hospital $ (best estimate)' is the headline figure, ",
           "'Strict named-hospital $' the source-confirmed floor; Detail carries every column, Definitions defines each column and status label, Sources lists the documents."),
    paste0("DATA AS OF ", date, ". Built by R/08_year1_summary.R from the committed award files; every figure traces to an archived state or CMS source (Sources sheet)."),
    paste0("BEST ESTIMATE vs STRICT. hospital_summary_usd (", f(us$hospital_summary_usd), ") combines the strict buckets with best-judgment calls on every undetermined row. ",
           "The strict columns are the defensible floor: strict_named_hospital_usd (", f(us$strict_named_hospital_usd), ") is source-confirmed named-hospital money. ",
           "The three strict columns are never added to one another; the best estimate is a different measure built from the summary calls."),
    paste0("BEST JUDGMENT. ", f(us$hospital_best_judgment_usd), " of the best estimate rests on judgment (shared pools called on a strict majority of typed members, ",
           "hospital associations and networks, a component of New Hampshire's FHC award). Subtract hospital_best_judgment_usd to return to coded figures."),
    paste0("INTENTS ARE NOT EXECUTED AWARDS. ", f(us$layer_intent_usd), " of the best estimate is published as notices of intent to award (",
           ys_intent_states(s), "). ",
           "States may change or withdraw them before agreements are signed."),
    paste0("CMS-OBLIGATION ROWS ARE 'OBLIGATED, PER CMS'. ", f(us$layer_cms_obligation_usd), " of the best estimate comes from CMS's Obligated Funds Report (as of 2026-07-31), ",
           "self-reported by the state; it is an obligation to a first-tier entity, not a confirmed subaward."),
    paste0("ROWS WITH NO PUBLISHED AMOUNT. ", us$named_hospital_recipients_no_amount, " named hospital recipients carry no published amount (Iowa, Indiana GROW, Nevada's unpriced lines, North Carolina, Tennessee, Delaware and others). ",
           "Their money is in no dollar column, so the hospital share is understated in those states."),
    "OREGON. CMS's Budget Period 1 award to Oregon is $5,000,000.33 below its FY2026 allotment (CMS Obligated Funds Report, as of 2026-07-31); the repository has not explained the difference. The allotment column uses the FY2026 table.",
    paste0("SOURCE_SUSPECT ROWS ARE EXCLUDED. ", f(us$layer_source_suspect_usd), " on rows whose published amount is internally inconsistent (Nevada FLEX-28 and FLEX-36, Texas Anson Hospital District) is left out of every hospital figure (owner ruling, session 102)."),
    "LAYERS OVERLAP. The layer_ columns (intents, association ruling, CMS obligation, AHC, general knowledge, LOW confidence) are parts of the best estimate and overlap one another. Never add them.",
    "NO STATE IS COMPARABLE TO ANOTHER WITHOUT READING ITS ROWS: figures mix intents, offers, executed agreements, rounded and partial-year amounts.",
    paste0("AWARD COVERAGE VARIES WIDELY BY STATE. Awards published run from 0% to ", sprintf("%.1f%%", 100 * max(s$award_total_usd[!s$state %in% YS_NATIONAL] / s$allotment_usd[!s$state %in% YS_NATIONAL])),
           " of the allotment, so a state's hospital share describes only the money that state has published so far. State shares are not comparable to one another."),
    paste0("n/m (HOSPITAL % OF AWARDS). Shown only where the state's STATE-SOURCED awards published are at least ", 100 * YS_AWARD_SHARE_MIN, "% of its allotment: ",
           "rows taken from CMS's Obligated Funds Report do not count toward the test, the same rule as the second national row ",
           "(Rhode Island, whose only rows are CMS lines, reads n/m). ", YS_NM_NOTE,
           " The same test applies to the national row: since FSRS (session 116d), state-sourced awards exceed half the national allotment, so the national share prints; ",
           "the second national row, over the states where most of the money is published, stays the headline. ",
           "Hospital % of allotment is shown for every state."),
    paste0("SECOND NATIONAL ROW. '", ge$state_name, "' rests on state award sources only. Rows taken from CMS's Obligated Funds Report are removed from every figure in it, ",
           "each state's '% published' is computed on its state-sourced awards alone, and a state qualifies when those are at least ", 100 * YS_AWARD_SHARE_MIN,
           "% of its allotment. States carrying CMS obligation lines today: ", paste(ys_cms_state_shares(s, rows), collapse = "; "), ". ",
           "Members (", gsub("^.*: ", "", ge$completion_status), "): allotment ", f(ge$allotment_usd), ", awards published ", f(ge$award_total_usd),
           ", hospital best estimate ", f(ge$hospital_summary_usd), " (", sprintf("%.1f%%", ge$hospital_share_of_awards_pct), " of those awards). ",
           "It is a subset of the national row, never added to it; the set changes as states publish."),
    paste0("* SUBSET ROW ON OVERVIEW. '", ys_overview_state_label(ge), "' is the second national row, in full: '", ge$state_name,
           "'. It is defined under SECOND NATIONAL ROW above."),
    ys_fsrs_note(),
    "NATIONAL ALLOTMENT. National allotment sums to $10,000,000,003 because each state's allotment is rounded to the dollar.",
    "NEW HAMPSHIRE. The $17.5M Critical Access and Acute Care Hospital RFA (inside the Foundation for Healthy Communities award, called HOSPITAL) has not yet awarded: FHC's notification of award for its initial cohort is due mid-December 2026.",
    paste0("CONFIDENTIAL SOURCES. ", YS_CONFIDENTIAL_NOTE, " As built, no award row or figure cites it; Delaware's status-table notes do (confidential_source_flag; the row is shaded on Overview and Detail).")))
}

#' One row per state: the primary source document(s) and their archive paths
# SESSION 116c: FSRS / FFATA first-tier subawards are an award source (owner
# ruling 2026-11-09; R/09b).
YS_FSRS_TOTALS <- "data/reference/fsrs_state_totals.csv"
ys_fsrs_note <- function() {
  t <- readr::read_csv(here::here(YS_FSRS_TOTALS), show_col_types = FALSE, progress = FALSE)
  non <- sort(t$st[!t$files_ffata])
  paste0("FSRS / FFATA SUBAWARDS (session 116c, owner ruling). A state's own FFATA first-tier subaward report (SAM.gov/FSRS, republished by USAspending under ",
         "Assistance Listing 93.798, archive ", t$as_of[1], ") is an award source: executed subawards, one amount per subaward action (re-filings collapsed). ",
         "It prices rows a state roster left at $0 and adds recipients no roster names (files <st>_fsrs_awardees.csv). FSRS covers SUBAWARDS ONLY: ",
         "a state's procurement contracts (consultants, vendors) are never reportable (2 CFR 170), so it is not a census of where the money went. ",
         length(non), " states had filed no FFATA subaward: ", paste(non, collapse = " "), ". That is a fact about their filing, not about their awards. ",
         "Subawards the reconciliation could not place without risk of counting one twice are held, not counted (data/reference/fsrs_held.csv).")
}

ys_sources <- function(rows, s) {
  st <- s$state[!s$state %in% YS_NATIONAL]
  j <- function(x) {
    x <- sort(unique(stats::na.omit(x[nzchar(x)])))
    out <- paste(x, collapse = " ; ")
    if (nchar(out) > 32000) out <- paste0(substr(out, 1, 32000), " ... [truncated; see the award files]")
    out
  }
  status <- readr::read_csv(here::here(YS_STATUS), show_col_types = FALSE, progress = FALSE)
  conf <- ys_confidential_status()
  fsrs <- tibble::tibble(
    state = "FSRS (all states)",
    award_files = "data/reference/<st>_fsrs_awardees.csv; FSRS overlay columns (fsrs_amount, fsrs_match) on every award file of a filing state",
    source_documents = paste("USAspending custom award download, Assistance Listing 93.798 (prime awards and FFATA first-tier subawards as filed by each state in SAM.gov/FSRS).",
                             "Covers subawards only; state procurement contracts are not reportable (2 CFR 170 App. A). 18 states had filed no subaward (Alabama filed its first in November)."),
    source_urls = "https://api.usaspending.gov/api/v2/download/awards/ (custom award download, filter program_numbers = 93.798)",
    archive_paths = "data/raw/usaspending/2026-11-09/usaspending_rhtp_93798_prime_and_subawards.zip (+ .manifest.txt with SHA-256)",
    status_evidence = "data/reference/fsrs_state_totals.csv; data/reference/fsrs_reconciliation.csv; data/reference/fsrs_held.csv; data/reference/fsrs_nonfiling_states.csv",
    evidence_directory = "data/raw/usaspending/2026-11-09", confidential_source = "")
  dplyr::bind_rows(fsrs, lapply(st, function(x) {
    r <- rows[rows$state == x, ]
    ev <- status$evidence_path[status$state == x]
    tibble::tibble(
      state = x,
      award_files = j(r$file),
      source_documents = j(r$source_document_title),
      source_urls = j(r$state_source_url),
      archive_paths = j(r$source_archive_path),
      status_evidence = if (length(ev)) j(ev) else "",
      evidence_directory = if (dir.exists(here::here("data/evidence", x))) file.path("data/evidence", x) else "",
      confidential_source = if (x %in% conf$state || any(r$confidential_hit))
        paste0("Cites ", paste(YS_CONFIDENTIAL_SOURCES, collapse = ", "), ". ", YS_CONFIDENTIAL_NOTE) else "")
  }))
}

# -- presentation (session 111b) -------------------------------------------------
#
# PRESENTATION ONLY. Nothing below changes a figure: the Overview sheet is a
# relabelled subset of the Detail columns, percentages are the same ratios
# stored as fractions (Excel shows them 0.0%), and the CSV is untouched.
# test_08 proves every Overview cell against ys_build().

#' A share of the published award total is shown only where the published
#' awards are at least this fraction of the allotment; below it, "n/m"
YS_NM <- "n/m"
YS_NM_NOTE <- paste(
  "Not meaningful where most of the state's money is not yet published; e.g., Wisconsin has",
  "published no award and filed no FFATA subaward.")

#' The plain-language Year 1 status labels, in the order they are assigned
YS_STATUS_LABELS <- tibble::tribble(
  ~label, ~definition,
  "Complete", "A state source says the state has finished awarding its Year 1 money, or has fully obligated it (completion_status COMPLETE; session 112 applied the full-obligation test to Vermont and Utah). Each state's row shows its own status; the national rows give the count. A COMPLETE state's rows may still be intents (Arkansas, Utah) or a floor of executed agreements (Vermont).",
  "CMS obligation report only", "Every award row comes from CMS's Obligated Funds Report (as of 2026-07-31), not from a state award document. Rhode Island: its state sites are unreadable from this environment, and CMS's report is the only source read. Obligated, per CMS, is not a confirmed subaward.",
  "Partial: awarding continues", "The state has published awards with dollar amounts, and more Year 1 awards are coming or some initiatives are not yet awarded.",
  "Awards published, not priced", "The state has named award recipients but published no per-recipient amount (Iowa, Tennessee, Kentucky, Hawaii, North Carolina). Their dollar columns are zero or pool-level only, and the hospital share cannot be computed.",
  "No awards published yet", "No state source read by this project names an award recipient. This is a statement about what has been found, not that the state has awarded nothing: Massachusetts's state sites are unreadable from this environment, and North Dakota has announced awards without naming recipients.")

#' One label per row of ys_build()'s table (the national row counts them)
ys_status_label <- function(s, rows) {
  cms_only <- rows %>% dplyr::group_by(state) %>%
    dplyr::summarise(cms_only = all(validation_source_type %in% "CMS_OBLIGATION_REPORT"), .groups = "drop")
  x <- s %>% dplyr::left_join(cms_only, by = "state") %>%
    dplyr::mutate(label = dplyr::case_when(
      state %in% YS_NATIONAL ~ NA_character_,
      completion_status == "COMPLETE" ~ "Complete",
      award_rows > 0 & cms_only %in% TRUE ~ "CMS obligation report only",
      award_rows > 0 & priced_rows > 0 ~ "Partial: awarding continues",
      award_rows > 0 ~ "Awards published, not priced",
      TRUE ~ "No awards published yet"))
  is_st <- !x$state %in% YS_NATIONAL
  if (any(is.na(x$label[is_st]))) stop("[year1 summary] a state has no status label", call. = FALSE)
  if (!all(x$label[is_st] %in% YS_STATUS_LABELS$label)) stop("[year1 summary] undefined status label", call. = FALSE)
  st <- x$label[is_st]
  x$label[x$state == "US"] <- paste0(sum(st == "Complete"), " Complete of ", length(st))
  # the second national row shows only its six figures (owner decision)
  x$label
}

#' Each row's STATE-SOURCED award total (CMS obligation-report files removed,
#' as for the second national row): the state rows from the state-source table,
#' the national row as their sum, the second national row as itself (it is
#' state-sourced by construction)
ys_state_sourced_awards <- function(s, rows) {
  ss <- ys_state_source_table(rows, NULL, NULL, sc_state_files())
  v <- ss$award_total_usd[match(s$state, ss$state)]
  v[s$state == "US"] <- sum(ss$award_total_usd)
  v[s$state == "US_GE50"] <- s$award_total_usd[s$state == "US_GE50"]
  if (any(is.na(v))) stop("[year1 summary] a row has no state-sourced award total", call. = FALSE)
  v
}

#' TRUE where a share of the published award total is meaningful: the row's
#' STATE-SOURCED awards are at least YS_AWARD_SHARE_MIN of its allotment (owner
#' decision; Rhode Island's CMS obligation lines no longer count toward it)
ys_share_meaningful <- function(s, rows) {
  # SESSION 116d (owner ruling b): the >=50% rule applies to the national row
  # too. FSRS lifts national state-sourced awards above half the allotment, so
  # the national hospital % of awards now prints; the subset row stays the
  # headline.
  s$allotment_usd > 0 &
    ys_state_sourced_awards(s, rows) / s$allotment_usd >= YS_AWARD_SHARE_MIN
}

ys_frac <- function(n, d) ifelse(d > 0, n / d, NA_real_)

#' The Overview sheet: one row per state, national row last
YS_OVERVIEW_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "State", "State name. Below the 50 states: the national total (the sum of the 50 state rows), then the states whose state-sourced awards published are at least 50% of their allotment (n in the label; CMS obligation-report rows are removed from that row's figures and from each state's test), which shows only allotment, awards published, the hospital figures and strict named-hospital dollars. The second row is a subset of the national total, never added to it.",
  "Year 1 status", "Plain-language Year 1 status; each label is defined below.",
  "FY2026 allotment", "The state's FY2026 RHTP allotment from CMS (Tier 1), from CMS's own table (Detail: allotment_usd).",
  "Awards published", "Published Year 1 award total: per-award amounts plus pool-level totals (Detail: award_total_usd).",
  "% of allotment awarded", "Awards published as a share of the allotment (Detail: award_share_of_allotment_pct).",
  "Hospital $ (best estimate)", "BEST ESTIMATE of Year 1 RHTP dollars reaching hospitals: source-coded plus best-judgment hospital dollars (Detail: hospital_summary_usd).",
  "Hospital % of awards", "Best-estimate hospital dollars as a share of awards published. Shown only where the state's STATE-SOURCED awards published (CMS obligation-report rows left out) are at least 50% of its allotment; otherwise n/m (not meaningful) (Detail: hospital_share_of_awards_pct).",
  "Hospital % of allotment", "Best-estimate hospital dollars as a share of the allotment, shown for every state (Detail: hospital_share_of_allotment_pct).",
  "Strict named-hospital $", "STRICT: dollars awarded to a named hospital or health system on a state source; the defensible floor (Detail: strict_named_hospital_usd).",
  "Hospitals named, no amount", "Named hospital recipients (distinct names) with no published amount; their money is in no dollar column (Detail: named_hospital_recipients_no_amount).")

#' Overview's State column: the subset row's long name is shortened to
#' "<n> states \u2265 50% published*" (session 112; n follows the data, the
#' full definition is in Notes). Detail and the CSV keep the full state_name.
ys_overview_state_label <- function(s) {
  ge <- s$state == "US_GE50"
  n <- sub("^.*\\(n = ([0-9]+)\\).*$", "\\1", s$state_name[ge])
  out <- s$state_name
  out[ge] <- paste0(n, " states \u2265", 100 * YS_AWARD_SHARE_MIN, "% published*")
  out
}

ys_overview <- function(s, rows) {
  ok <- ys_share_meaningful(s, rows)
  ge <- s$state == "US_GE50"
  blank <- function(x) { x[ge] <- NA; x }
  tibble::tibble(
    "State" = ys_overview_state_label(s),
    "Year 1 status" = ys_status_label(s, rows),
    "FY2026 allotment" = s$allotment_usd,
    "Awards published" = s$award_total_usd,
    "% of allotment awarded" = blank(ys_frac(s$award_total_usd, s$allotment_usd)),
    "Hospital $ (best estimate)" = s$hospital_summary_usd,
    "Hospital % of awards" = ifelse(ok, ys_frac(s$hospital_summary_usd, s$award_total_usd), NA_real_),
    "Hospital % of allotment" = ys_frac(s$hospital_summary_usd, s$allotment_usd),
    "Strict named-hospital $" = s$strict_named_hospital_usd,
    "Hospitals named, no amount" = blank(s$named_hospital_recipients_no_amount))
}

#' The Detail sheet: every CSV column; the _pct columns as fractions, and the
#' award share "n/m" (written by the workbook) where it is not meaningful
ys_detail <- function(s, rows) {
  ok <- ys_share_meaningful(s, rows)
  s %>% dplyr::mutate(
    award_share_of_allotment_pct = ys_frac(award_total_usd, allotment_usd),
    hospital_share_of_awards_pct = ifelse(ok, ys_frac(hospital_summary_usd, award_total_usd), NA_real_),
    hospital_share_of_allotment_pct = ys_frac(hospital_summary_usd, allotment_usd))
}

#' Column widths wide enough for every header and formatted value, capped
#' (long text wraps)
ys_widths <- function(d, usd_cols, pct_cols, cap = 60) {
  vapply(seq_along(d), function(i) {
    v <- d[[i]]
    txt <- if (i %in% usd_cols) paste0("$", formatC(v, format = "f", digits = 0, big.mark = ","))
           else if (i %in% pct_cols) ifelse(is.na(v), YS_NM, sprintf("%.1f%%", 100 * v))
           else as.character(v)
    min(cap, max(nchar(names(d)[i]), nchar(txt[!is.na(txt)]), 4) + 3)
  }, numeric(1))
}

#' Write one table sheet with currency and percentage formats, n/m cells, a
#' bold national row, shaded confidential rows and a frozen header and first column
ys_table_sheet <- function(wb, sheet, d, usd_cols, pct_cols, nm_rows, nm_col, conf_rows, bold_rows, styles) {
  openxlsx::addWorksheet(wb, sheet)
  openxlsx::writeData(wb, sheet, d, headerStyle = styles$hdr)
  body <- 2:(nrow(d) + 1)
  openxlsx::addStyle(wb, sheet, styles$usd, rows = body, cols = usd_cols, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb, sheet, styles$pct, rows = body, cols = pct_cols, gridExpand = TRUE, stack = TRUE)
  for (r in nm_rows) {
    openxlsx::writeData(wb, sheet, YS_NM, startCol = nm_col, startRow = r + 1)
  }
  if (length(nm_rows)) {
    openxlsx::addStyle(wb, sheet, styles$right, rows = nm_rows + 1, cols = nm_col, stack = TRUE)
  }
  openxlsx::addStyle(wb, sheet, styles$bold, rows = bold_rows + 1, cols = seq_along(d), gridExpand = TRUE, stack = TRUE)
  if (length(conf_rows)) {
    openxlsx::addStyle(wb, sheet, styles$conf, rows = conf_rows + 1, cols = seq_along(d), gridExpand = TRUE, stack = TRUE)
  }
  w <- ys_widths(d, usd_cols, pct_cols)
  openxlsx::setColWidths(wb, sheet, cols = seq_along(d), widths = w)
  long <- which(w >= 60)
  if (length(long)) openxlsx::addStyle(wb, sheet, styles$wrap, rows = body, cols = long, gridExpand = TRUE, stack = TRUE)
  openxlsx::freezePane(wb, sheet, firstActiveRow = 2, firstActiveCol = 2)
}

ys_workbook <- function(s, rows, date, path, vt = ys_vendor_build(s, rows), u = ys_use_build(s)) {
  miss <- setdiff(names(s), YS_DEFINITIONS$column)
  extra <- setdiff(YS_DEFINITIONS$column, names(s))
  if (length(miss) || length(extra)) {
    stop("[year1 summary] Definitions out of step with the Detail columns: missing ",
         paste(miss, collapse = ", "), "; extra ", paste(extra, collapse = ", "), call. = FALSE)
  }
  if (!identical(utils::tail(s$state, 2), YS_NATIONAL)) stop("[year1 summary] the two national rows must be last", call. = FALSE)
  wb <- openxlsx::createWorkbook()
  styles <- list(
    hdr = openxlsx::createStyle(textDecoration = "bold", fgFill = "#DDE6F0", wrapText = TRUE, valign = "top"),
    usd = openxlsx::createStyle(numFmt = "$#,##0"),
    pct = openxlsx::createStyle(numFmt = "0.0%"),
    right = openxlsx::createStyle(halign = "right"),
    bold = openxlsx::createStyle(textDecoration = "bold"),
    conf = openxlsx::createStyle(fgFill = "#F8D7DA"),
    wrap = openxlsx::createStyle(wrapText = TRUE, valign = "top"))
  wrap <- styles$wrap; hdr <- styles$hdr; conf <- styles$conf
  nm_rows <- which(!ys_share_meaningful(s, rows))
  conf_rows <- which(nzchar(s$confidential_source_flag) & !s$state %in% YS_NATIONAL)

  # Overview is sorted by state NAME (the column it shows), national row last.
  so <- s[order(match(s$state, YS_NATIONAL, nomatch = 0L), s$state_name), ]
  ov <- ys_overview(so, rows)
  ys_table_sheet(wb, "Overview", ov,
                 usd_cols = which(names(ov) %in% c("FY2026 allotment", "Awards published",
                                                    "Hospital $ (best estimate)", "Strict named-hospital $")),
                 pct_cols = which(grepl("%", names(ov))),
                 nm_rows = which(!ys_share_meaningful(so, rows)), nm_col = which(names(ov) == "Hospital % of awards"),
                 conf_rows = which(nzchar(so$confidential_source_flag) & !so$state %in% YS_NATIONAL),
                 bold_rows = which(so$state %in% YS_NATIONAL), styles = styles)

  de <- ys_detail(s, rows)
  # SESSION 123: the hospital best estimate by use group (task 4d), appended.
  de <- ys_detail_use(de, u)
  ys_table_sheet(wb, "Detail", de,
                 usd_cols = which(grepl("_usd$", names(de))),
                 pct_cols = which(grepl("_pct$", names(de))),
                 nm_rows = nm_rows, nm_col = which(names(de) == "hospital_share_of_awards_pct"),
                 conf_rows = conf_rows, bold_rows = which(s$state %in% YS_NATIONAL), styles = styles)

  # SESSION 116f: the Vendor spending sheet (national row last, bold).
  vs <- vt %>% dplyr::mutate(vendor_share_of_awards_pct = vendor_share_of_awards_pct / 100,
                             hospital_share_of_awards_pct = hospital_share_of_awards_pct / 100)
  vs_nm <- which(is.na(vs$vendor_share_of_awards_pct))
  ys_table_sheet(wb, "Vendor spending", vs,
                 usd_cols = which(grepl("_usd$", names(vs))), pct_cols = which(grepl("_pct$", names(vs))),
                 nm_rows = vs_nm, nm_col = which(names(vs) == "vendor_share_of_awards_pct"),
                 conf_rows = integer(0), bold_rows = which(vs$state == "US"), styles = styles)
  if (length(vs_nm)) {
    for (r in vs_nm) openxlsx::writeData(wb, "Vendor spending", YS_NM, startCol = which(names(vs) == "hospital_share_of_awards_pct"), startRow = r + 1)
  }

  # SESSION 123: the "By use category" sheet.
  ys_use_sheet(wb, u, styles)

  defs <- dplyr::bind_rows(
    YS_OVERVIEW_DEFINITIONS %>% dplyr::transmute(sheet = "Overview", term = column, definition),
    YS_STATUS_LABELS %>% dplyr::transmute(sheet = "Year 1 status label", term = label, definition),
    YS_DEFINITIONS %>% dplyr::transmute(sheet = "Detail", term = column, definition),
    YS_VENDOR_DEFINITIONS %>% dplyr::transmute(sheet = "Vendor spending", term = column, definition),
    # SESSION 124: the five named vendor figures every report states.
    RHTP_VENDOR_FIGURES %>% dplyr::transmute(sheet = "Vendor figures (named)", term = label, definition),
    YS_USE_DEFINITIONS %>% dplyr::transmute(sheet = "By use category", term = column, definition))
  openxlsx::addWorksheet(wb, "Definitions")
  openxlsx::writeData(wb, "Definitions", defs, headerStyle = hdr)
  openxlsx::setColWidths(wb, "Definitions", cols = 1:3, widths = c(22, 36, 120))
  openxlsx::addStyle(wb, "Definitions", wrap, rows = 2:(nrow(defs) + 1), cols = 3, stack = TRUE)
  openxlsx::freezePane(wb, "Definitions", firstRow = TRUE)

  n <- dplyr::bind_rows(ys_notes(s, date, rows), tibble::tibble(note = ys_vendor_notes(vt)),
                        tibble::tibble(note = ys_use_notes(u)))
  openxlsx::addWorksheet(wb, "Notes and caveats")
  openxlsx::writeData(wb, "Notes and caveats", n, headerStyle = hdr)
  openxlsx::setColWidths(wb, "Notes and caveats", cols = 1, widths = 160)
  openxlsx::addStyle(wb, "Notes and caveats", wrap, rows = 2:(nrow(n) + 1), cols = 1, stack = TRUE)

  src <- ys_sources(rows, s)
  openxlsx::addWorksheet(wb, "Sources")
  openxlsx::writeData(wb, "Sources", src, headerStyle = hdr)
  openxlsx::setColWidths(wb, "Sources", cols = seq_along(src), widths = c(8, 40, 60, 60, 60, 50, 20, 40))
  openxlsx::addStyle(wb, "Sources", wrap, rows = 2:(nrow(src) + 1), cols = seq_along(src), gridExpand = TRUE, stack = TRUE)
  sc <- which(nzchar(src$confidential_source)) + 1
  if (length(sc)) openxlsx::addStyle(wb, "Sources", conf, rows = sc, cols = seq_along(src), gridExpand = TRUE, stack = TRUE)

  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  ys_strip_dangling_rels(path)
  invisible(path)
}

#' Session 116f: moved to utils_config.R (rhtp_xlsx_strip_dangling_rels) so every
#' workbook writer in output/ uses it.
ys_strip_dangling_rels <- function(path) rhtp_xlsx_strip_dangling_rels(path)

# -- SESSION 116f: VENDOR SPENDING, A STANDING CATEGORY BESIDE HOSPITAL SPENDING --
#
# Built from the spend-category layer (R/utils_spend_category.R, written by
# R/07 --apply) on every award row AND every contract row. ys_build() above is
# NOT touched: the hospital columns are computed exactly as before and the
# vendor table is a separate table, the "Vendor spending" sheet and its own CSV.
#
#   ONLY VERIFIED DOLLARS. vendor_verified_usd (session 116e's V1-V9) and
#   nothing else enters a vendor figure. Unverified vendor-category rows are
#   LEADS (vendor_leads_award_file_usd, context only).
#   NEVER SUMMED ACROSS AMOUNT TYPES. award, intent, contract maximum and
#   obligation each get their own columns.
#   THE SHARE uses vendor dollars on AWARD-FILE rows of type award or intent
#   (the same rows the hospital share counts) over award_total_usd, under the
#   same >=50% rule as the hospital share (n/m otherwise).
#   UNNAMED CONTRACTOR OBLIGATIONS (CMS lines naming no firm) are CONTEXT,
#   split CONTRACTOR_ONLY / MIXED, never vendor dollars.
YS_VENDOR_OUT <- function(date) file.path("data", "reference", paste0("year1_vendor_summary_", date, ".csv"))
YS_UNNAMED_OUT <- "data/reference/cms_unnamed_contractor_lines.csv"
YS_VENDOR_TYPES <- c(award = "award", intent = "intent", contract_maximum = "contract maximum",
                     obligation = "obligation")
YS_VENDOR_CATS <- c(consultant = "CONSULTANT", data_tech_vendor = "DATA_TECH_VENDOR",
                    administrator = "ADMINISTRATOR", non_provider_intermediary = "NON_PROVIDER_INTERMEDIARY")

ys_vendor_build <- function(s, rows, spend = rhtp_spend_rows(sc_state_files()),
                            unnamed = rhtp_unnamed_contractor_lines()) {
  states <- s$state[!s$state %in% YS_NATIONAL]
  v <- spend %>% dplyr::filter(vendor_verified, state %in% states)
  one <- function(st) {
    x <- v[v$state == st, , drop = FALSE]
    out <- list(state = st)
    for (cn in names(YS_VENDOR_CATS)) for (tn in names(YS_VENDOR_TYPES)) {
      out[[paste0("vendor_", cn, "_", tn, "_usd")]] <-
        sum(x$vendor_verified_usd[x$spend_category == YS_VENDOR_CATS[[cn]] & x$amount_type == YS_VENDOR_TYPES[[tn]]])
    }
    for (tn in names(YS_VENDOR_TYPES)) {
      out[[paste0("vendor_total_", tn, "_usd")]] <- sum(x$vendor_verified_usd[x$amount_type == YS_VENDOR_TYPES[[tn]]])
    }
    # SESSION 117 (Task 7c): every vendor total split PUBLIC (state-created or
    # local public bodies, vendor_public: NC's Trillium and Vaya) / NON_PUBLIC.
    for (tn in names(YS_VENDOR_TYPES)) {
      ty <- x$amount_type == YS_VENDOR_TYPES[[tn]]
      out[[paste0("vendor_public_", tn, "_usd")]] <- sum(x$vendor_verified_usd[ty & x$vendor_public %in% TRUE])
      out[[paste0("vendor_non_public_", tn, "_usd")]] <- sum(x$vendor_verified_usd[ty & !(x$vendor_public %in% TRUE)])
    }
    for (tn in names(YS_VENDOR_TYPES)) {
      out[[paste0("vendor_out_of_state_", tn, "_usd")]] <-
        sum(x$vendor_verified_usd[x$amount_type == YS_VENDOR_TYPES[[tn]] & x$out_of_state %in% TRUE])
    }
    out$vendor_verified_rows <- nrow(x)
    out$vendor_award_file_usd <- sum(x$vendor_verified_usd[x$kind == "award" & x$amount_type %in% c("award", "intent")])
    lead <- spend$state == st & spend$kind == "award" & spend$spend_category %in% RHTP_VENDOR_CATEGORIES & !spend$vendor_verified
    out$vendor_leads_award_file_usd <- sum(spend$amount[lead], na.rm = TRUE)
    pt <- spend$state == st & spend$kind == "award" & spend$spend_category == "PROVIDER_PASS_THROUGH"
    out$provider_pass_through_award_file_usd <- sum(spend$amount[pt], na.rm = TRUE)
    u <- unnamed[unnamed$state == st, , drop = FALSE]
    out$unnamed_contractor_only_obligation_usd <- sum(u$amount_obligated[u$split == "CONTRACTOR_ONLY"])
    out$unnamed_contractor_mixed_obligation_usd <- sum(u$amount_obligated[u$split == "MIXED"])
    tibble::as_tibble(out)
  }
  t <- dplyr::bind_rows(lapply(states, one))
  num <- setdiff(names(t), "state")
  us <- tibble::as_tibble(c(list(state = "US"), lapply(t[num], sum)))
  t <- dplyr::bind_rows(t, us)
  base <- s[match(t$state, s$state), ]
  ok <- ys_share_meaningful(base, rows)
  t %>% dplyr::mutate(
    state_name = base$state_name, award_total_usd = base$award_total_usd,
    hospital_summary_usd = base$hospital_summary_usd,
    strict_named_hospital_usd = base$strict_named_hospital_usd,
    vendor_share_of_awards_pct = ifelse(ok, ys_pct(vendor_award_file_usd, award_total_usd), NA_real_),
    hospital_share_of_awards_pct = ifelse(ok, ys_pct(hospital_summary_usd, award_total_usd), NA_real_),
    .after = state)
}

YS_VENDOR_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "state", "Two-letter state code; US is the national row (the sum of the 50 state rows).",
  "state_name", "State name.",
  "award_total_usd", "Awards published (as on Detail); the denominator of both shares.",
  "hospital_summary_usd", "Hospital $ best estimate (as on Detail), for comparison; unchanged by the vendor layer.",
  "strict_named_hospital_usd", "Strict named-hospital $ (as on Detail), for comparison.",
  "vendor_share_of_awards_pct", "Verified vendor dollars on award rows (types award and intent) as a percentage of awards published. Same rule as the hospital share: shown only where the state's state-sourced awards are at least 50% of its allotment, otherwise blank (n/m).",
  "hospital_share_of_awards_pct", "Hospital best estimate as a percentage of awards published, under the same rule, for side-by-side reading.",
  "vendor_<category>_<type>_usd", "VERIFIED dollars (session 116e tests V1-V9) by vendor category (consultant, data/tech vendor, administrator, non-provider intermediary) and amount type (award, intent, contract maximum, obligation). Amount types are never added together.",
  "vendor_total_<type>_usd", "Verified vendor dollars of one amount type, all four categories.",
  "vendor_public_<type>_usd", "Verified vendor dollars of one amount type paid to a PUBLIC body (state-created or local public entities, e.g. North Carolina's NC ROOTS hub leads Trillium Health Resources and Vaya Health, both Medicaid managed care organisations created under state law). PUBLIC + NON_PUBLIC = vendor_total_<type>_usd.",
  "vendor_non_public_<type>_usd", "Verified vendor dollars of one amount type paid to a private firm or private nonprofit (NON_PUBLIC). PUBLIC + NON_PUBLIC = vendor_total_<type>_usd.",
  "vendor_out_of_state_<type>_usd", "Verified vendor dollars of one amount type whose recipient's FSRS registered address is outside the awarding state (V6). A subset of vendor_total_<type>_usd. Every other vendor row is NOT_SHOWN out of state (out_of_state column), never 'in state': a national firm with no FSRS address (EY, McKinsey, Deloitte) is NOT_SHOWN.",
  "vendor_verified_rows", "Number of award and contract rows carrying verified vendor dollars.",
  "vendor_award_file_usd", "Verified vendor dollars on award rows of type award or intent: the numerator of vendor_share_of_awards_pct.",
  "vendor_leads_award_file_usd", "LEADS, context only: dollars on award rows whose category is a vendor category but which no verified case covers. Never a vendor figure.",
  "provider_pass_through_award_file_usd", "Context: award rows to intermediaries that pay providers (PROVIDER_PASS_THROUGH). Not vendor spending; some of these dollars are in the hospital best estimate.",
  "unnamed_contractor_only_obligation_usd", "Context: CMS Obligated Funds Report lines (newest parsed edition) obligating money to contractors or consultants it does not name. Never a vendor figure.",
  "unnamed_contractor_mixed_obligation_usd", "Context: as above, where the line also covers state staff, state agencies or administrative infrastructure (e.g. NH, KS), so not all of it is contractor money.")

ys_vendor_notes <- function(vt, figs = NULL) {
  us <- vt[vt$state == "US", ]
  f <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  # SESSION 124: the named figures lead, under their settled labels.
  if (is.null(figs)) figs <- rhtp_vendor_figures(rhtp_spend_rows(sc_state_files()))
  g <- function(k) figs$usd[figs$key == k]
  lab <- function(k) figs$label[figs$key == k]
  if (abs(g("vendor_awards") - us$vendor_total_award_usd) > 0.01) {
    stop("[ys] the named vendor-awards figure and the Vendor spending sheet disagree.", call. = FALSE)
  }
  c(paste0("VENDOR FIGURES, NAMED (session 124; never added together): ", lab("vendor_awards"), " ", f(g("vendor_awards")),
           "; ", lab("pass_through_awards"), " ", f(g("pass_through_awards")), " (of which ",
           f(figs$of_which_in_hospital_usd[figs$key == "pass_through_awards"]), " is already inside the hospital best estimate); ",
           lab("vendor_intents"), " ", f(g("vendor_intents")), "; ", lab("vendor_contract_maximums"), " ",
           f(g("vendor_contract_maximums")), "; ", lab("vendor_obligations"), " ", f(g("vendor_obligations")), "."),
    paste0("VENDOR SPENDING (session 116f, owner direction). The 'Vendor spending' sheet tracks consultants, data/tech vendors, programme administrators and ",
           "non-provider intermediaries beside hospital spending. ONLY VERIFIED DOLLARS count (session 116e tests V1-V9); unverified vendor-category rows are leads. ",
           "Nationally: verified vendor awards (excluding provider pass-through) ", f(us$vendor_total_award_usd), ", intent ", f(us$vendor_total_intent_usd), ", contract maximum ",
           f(us$vendor_total_contract_maximum_usd), ", obligation ", f(us$vendor_total_obligation_usd),
           ". The four amount types are never added together."),
    paste0("VENDOR vs HOSPITAL. Verified vendor dollars on award rows (award + intent) are ", f(us$vendor_award_file_usd),
           " against a hospital best estimate of ", f(us$hospital_summary_usd), " on the same rows' denominator. ",
           "Hospital and vendor categories never overlap (a hospital, health system, AHC or hospital association is never a vendor). ",
           "Vendor money sits mostly in procurement contracts, which FSRS does not report and many states do not publish, so the vendor figure is a FLOOR."),
    paste0("CONTRACT ROWS. Contract maximums and obligations come from state contract registers and CMS annual reports (data/reference/contracts/); they never count toward awards published or the hospital share."),
    paste0("PUBLIC vs NON_PUBLIC. Of the verified award dollars, ", f(us$vendor_public_award_usd), " went to PUBLIC bodies ",
           "(North Carolina's NC ROOTS hub leads Trillium Health Resources and Vaya Health) and ", f(us$vendor_non_public_award_usd),
           " to private firms and nonprofits. Every vendor total is split this way on the sheet."),
    paste0("UNNAMED CONTRACTOR MONEY (headline: CONTRACTOR_ONLY). CMS's Obligated Funds Report obligates ", f(us$unnamed_contractor_only_obligation_usd),
           " to contractors it does not name, on lines that fund contractors only. A further ", f(us$unnamed_contractor_mixed_obligation_usd),
           " sits on MIXED lines that also cover state staff or agencies (e.g. NH, KS), so not all of it is contractor money; it is shown separately and never added to the headline. Context only; each line and its quote is in cms_unnamed_contractor_lines.csv."))
}

# -- SESSION 123: USE CATEGORIES (owner direction 11-24) ---------------------------
#
# Every Year 1 award dollar in award_total_usd, by the RHTP activity it funds
# (CMS's uses of funds A-K, grouped; R/utils_use_category.R, written by
# R/11 --apply). ys_build() is NOT touched: this is a separate table, the "By use
# category" sheet and its own CSV, and it is asserted to sum, state by state, to
# award_total_usd (groups, MULTIPLE and NOT_STATED included) and, for the
# HOSPITAL split, to hospital_summary_usd. So no total can move.
#
# ITEMS. (1) every Year 1 award row (the Accenture-flag row held out, as in
# ys_build), at its own category, HOSPITAL where R/07 calls it HOSPITAL and it
# is not SOURCE_SUSPECT; (2) every pool-level amount (rhtp_use_pool_items(): the
# round figures, Georgia's initiative residuals, the R/07 pools outside the
# files, South Dakota's in-round contracts netted at their own categories) at
# its ROUND's category, HOSPITAL only where R/07 calls that pool HOSPITAL; (3)
# each R/07 component, which moves its dollars from NOT_HOSPITAL to HOSPITAL
# inside its parent row's category (a component is never re-categorised: an
# award's dollars are never divided across categories).
YS_USE_OUT <- function(date) file.path("data", "reference", paste0("year1_use_categories_", date, ".csv"))
YS_USE_GROUPS <- names(RHTP_USE_GROUP_LABELS)
YS_USE_CAPS <- c(B = 0.15, J = 0.20)

ys_use_items <- function(s, files = sc_state_files(), components = NULL) {
  if (is.null(components)) {
    components <- readr::read_csv(here::here(YS_COMPONENTS), col_types = readr::cols(.default = "c"), progress = FALSE)
  }
  r <- uc_rows(files) %>% dplyr::filter(!ys_has(flag_reason, YS_EXCLUDED_FLAG)) %>%
    dplyr::mutate(suspect = ys_has(flag_reason, "SOURCE_SUSPECT"),
                  call = dplyr::if_else(call == "HOSPITAL" & !suspect, "HOSPITAL", "NOT_HOSPITAL"),
                  usd = dplyr::coalesce(amount, 0), kind = "row", n_rows = 1L,
                  item = paste0(file_key, " row ", row_no))
  p <- rhtp_use_pool_items(files) %>%
    dplyr::mutate(kind = "pool", n_rows = 0L, item = paste0(file_key, " pool: ", pool_key))
  cp <- components %>% dplyr::mutate(component_usd = as.numeric(component_usd)) %>%
    dplyr::left_join(r %>% dplyr::select(file_key, awardee, parent_call = call, use_category_primary,
                                         use_group_primary, use_categories_all, use_category_basis),
                     by = c("file_key", "awardee"))
  if (any(is.na(cp$use_group_primary))) stop("[use] an R/07 component reaches no award row.", call. = FALSE)
  if (any(cp$call == "HOSPITAL" & cp$parent_call == "HOSPITAL")) {
    stop("[use] a HOSPITAL component sits on a HOSPITAL row; R/08 would count it twice.", call. = FALSE)
  }
  cp <- cp %>% dplyr::filter(call == "HOSPITAL")
  comp <- dplyr::bind_rows(
    cp %>% dplyr::mutate(call = "HOSPITAL", usd = component_usd),
    cp %>% dplyr::mutate(call = "NOT_HOSPITAL", usd = -component_usd)) %>%
    dplyr::mutate(kind = "component", n_rows = 0L, item = paste0(file_key, " component ", component_id))
  keep <- c("state", "file_key", "kind", "item", "n_rows", "usd", "call", "use_category_primary",
            "use_group_primary", "use_categories_all", "use_category_basis")
  it <- dplyr::bind_rows(r[, keep], p[, keep], comp[, keep])
  # THE ASSERTIONS: groups sum to awards published; HOSPITAL to the hospital figure.
  chk <- it %>% dplyr::group_by(state) %>%
    dplyr::summarise(all = sum(usd), hosp = sum(usd[call == "HOSPITAL"]), rows = sum(n_rows), .groups = "drop") %>%
    dplyr::right_join(s %>% dplyr::filter(!state %in% YS_NATIONAL) %>%
                        dplyr::select(state, award_total_usd, hospital_summary_usd, award_rows), by = "state") %>%
    dplyr::mutate(dplyr::across(c(all, hosp, rows), ~ dplyr::coalesce(.x, 0)))
  bad <- chk %>% dplyr::filter(abs(all - award_total_usd) > 0.01 | abs(hosp - hospital_summary_usd) > 0.01 |
                                 rows != award_rows)
  if (nrow(bad)) {
    stop("[use] use-category items do not sum to the Year 1 table for: ",
         paste0(bad$state, " (items $", format(bad$all, nsmall = 2), " vs awards $", format(bad$award_total_usd, nsmall = 2),
                "; hospital $", format(bad$hosp, nsmall = 2), " vs $", format(bad$hospital_summary_usd, nsmall = 2), ")",
                collapse = "; "), call. = FALSE)
  }
  it
}

ys_use_label <- function(g) unname(RHTP_USE_GROUP_LABELS[g])

#' The four tables of the "By use category" sheet, and the Detail breakdown.
ys_use_build <- function(s, items = ys_use_items(s)) {
  allot <- s %>% dplyr::filter(!state %in% YS_NATIONAL) %>% dplyr::select(state, state_name, allotment_usd, award_total_usd)
  classified <- function(g) !g %in% "NOT_STATED"
  grp <- items %>% dplyr::group_by(use_group_primary) %>%
    dplyr::summarise(rows = sum(n_rows), rows_hospital = sum(n_rows[call == "HOSPITAL"]),
                     rows_not_hospital = sum(n_rows[call != "HOSPITAL"]),
                     usd = sum(usd[TRUE]), .groups = "drop")
  hs <- items %>% dplyr::group_by(use_group_primary, call) %>% dplyr::summarise(v = sum(usd), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = call, values_from = v, values_fill = 0)
  for (cc in c("HOSPITAL", "NOT_HOSPITAL")) if (!cc %in% names(hs)) hs[[cc]] <- 0
  national <- tibble::tibble(use_group_primary = YS_USE_GROUPS) %>%
    dplyr::left_join(grp, by = "use_group_primary") %>% dplyr::left_join(hs, by = "use_group_primary") %>%
    dplyr::mutate(dplyr::across(-use_group_primary, ~ dplyr::coalesce(.x, 0))) %>%
    dplyr::transmute(use_group_primary, use_group = ys_use_label(use_group_primary),
                     letters = vapply(use_group_primary, function(g) {
                       l <- names(rhtp_use_groups())[rhtp_use_groups() == g]; if (length(l)) paste(l, collapse = ", ") else ""
                     }, ""),
                     rows, rows_hospital, rows_not_hospital,
                     award_usd = usd, hospital_usd = HOSPITAL, not_hospital_usd = NOT_HOSPITAL,
                     share_of_classified_pct = ifelse(classified(use_group_primary),
                                                      award_usd / sum(award_usd[classified(use_group_primary)]), NA_real_),
                     hospital_share_of_classified_pct = ifelse(classified(use_group_primary),
                                                               hospital_usd / sum(hospital_usd[classified(use_group_primary)]), NA_real_),
                     not_hospital_share_of_classified_pct = ifelse(classified(use_group_primary),
                                                                   not_hospital_usd / sum(not_hospital_usd[classified(use_group_primary)]), NA_real_),
                     share_of_awards_pct = award_usd / sum(award_usd))
  national <- dplyr::bind_rows(national, national %>% dplyr::summarise(
    use_group_primary = "TOTAL", use_group = "Total (awards published)", letters = "",
    dplyr::across(c(rows, rows_hospital, rows_not_hospital, award_usd, hospital_usd, not_hospital_usd), sum),
    share_of_awards_pct = 1))
  tot <- national[national$use_group_primary == "TOTAL", ]
  us <- s[s$state == "US", ]
  if (abs(tot$award_usd - us$award_total_usd) > 0.01 || abs(tot$hospital_usd - us$hospital_summary_usd) > 0.01) {
    stop("[use] national use-category totals differ from the Year 1 table.", call. = FALSE)
  }
  # Coverage by basis (rows count award rows; dollars include pool-level items).
  basis <- items %>% dplyr::mutate(use_category_basis = factor(use_category_basis, RHTP_USE_BASES)) %>%
    dplyr::group_by(use_category_basis, .drop = FALSE) %>%
    dplyr::summarise(rows = sum(n_rows), award_usd = sum(usd), hospital_usd = sum(usd[call == "HOSPITAL"]),
                     .groups = "drop") %>%
    dplyr::mutate(use_category_basis = as.character(use_category_basis),
                  confidence = dplyr::coalesce(unname(RHTP_USE_CONFIDENCE[use_category_basis]), ""),
                  row_share_pct = rows / sum(rows), award_share_pct = award_usd / sum(award_usd)) %>%
    dplyr::select(use_category_basis, confidence, rows, row_share_pct, award_usd, award_share_pct, hospital_usd)
  # Coverage by state.
  bs <- items %>% dplyr::group_by(state) %>%
    dplyr::summarise(rows = sum(n_rows), rows_classified = sum(n_rows[use_category_basis != "NOT_STATED"]),
                     award_usd = sum(usd),
                     award_source_usd = sum(usd[use_category_basis == "AWARD_SOURCE"]),
                     crosswalk_usd = sum(usd[use_category_basis == "INITIATIVE_CROSSWALK"]),
                     cms_heading_usd = sum(usd[use_category_basis == "CMS_REPORT_HEADING"]),
                     purpose_text_usd = sum(usd[use_category_basis == "PURPOSE_TEXT"]),
                     not_stated_usd = sum(usd[use_category_basis == "NOT_STATED"]), .groups = "drop") %>%
    dplyr::mutate(classified_usd = award_usd - not_stated_usd,
                  classified_share_pct = ifelse(award_usd != 0, classified_usd / award_usd, NA_real_),
                  rows_classified_share_pct = ifelse(rows > 0, rows_classified / rows, NA_real_))
  cov_state <- allot %>% dplyr::select(state, state_name) %>% dplyr::left_join(bs, by = "state") %>%
    dplyr::mutate(dplyr::across(c(rows, rows_classified), ~ dplyr::coalesce(.x, 0L)),
                  dplyr::across(c(award_usd, award_source_usd, crosswalk_usd, cms_heading_usd, purpose_text_usd, not_stated_usd, classified_usd),
                                ~ dplyr::coalesce(.x, 0))) %>%
    dplyr::select(state, state_name, rows, rows_classified, rows_classified_share_pct, award_usd, classified_usd,
                  classified_share_pct, award_source_usd, crosswalk_usd, cms_heading_usd, purpose_text_usd, not_stated_usd)
  # By state: dollars by group (wide), and the two capped letters.
  wide <- items %>% dplyr::group_by(state, use_group_primary) %>% dplyr::summarise(v = sum(usd), .groups = "drop") %>%
    dplyr::mutate(use_group_primary = factor(use_group_primary, YS_USE_GROUPS)) %>%
    tidyr::pivot_wider(names_from = use_group_primary, values_from = v, values_fill = 0, names_expand = TRUE)
  by_state <- allot %>% dplyr::select(state, state_name, award_total_usd) %>% dplyr::left_join(wide, by = "state") %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(YS_USE_GROUPS), ~ dplyr::coalesce(.x, 0)))
  names(by_state)[match(YS_USE_GROUPS, names(by_state))] <- paste0(tolower(YS_USE_GROUPS), "_usd")
  has <- function(x, l) grepl(paste0("(^|;)", l, "(;|$)"), x)
  caps <- items %>% dplyr::group_by(state) %>% dplyr::summarise(
    b_primary_usd = sum(usd[use_category_primary == "B"]), b_any_usd = sum(usd[has(use_categories_all, "B")]),
    j_primary_usd = sum(usd[use_category_primary == "J"]), j_any_usd = sum(usd[has(use_categories_all, "J")]),
    .groups = "drop")
  caps <- allot %>% dplyr::select(state, state_name, allotment_usd) %>% dplyr::left_join(caps, by = "state") %>%
    dplyr::mutate(dplyr::across(dplyr::ends_with("_usd"), ~ dplyr::coalesce(.x, 0)),
                  b_primary_share_of_allotment_pct = b_primary_usd / allotment_usd,
                  b_cap_pct = YS_USE_CAPS[["B"]],
                  b_any_share_of_allotment_pct = b_any_usd / allotment_usd,
                  j_primary_share_of_allotment_pct = j_primary_usd / allotment_usd,
                  j_cap_pct = YS_USE_CAPS[["J"]],
                  j_any_share_of_allotment_pct = j_any_usd / allotment_usd) %>%
    dplyr::select(state, state_name, allotment_usd, b_primary_usd, b_primary_share_of_allotment_pct, b_cap_pct,
                  b_any_usd, b_any_share_of_allotment_pct, j_primary_usd, j_primary_share_of_allotment_pct, j_cap_pct,
                  j_any_usd, j_any_share_of_allotment_pct)
  # The Detail breakdown: each state's hospital best estimate by use group.
  hg <- items %>% dplyr::filter(call == "HOSPITAL") %>% dplyr::group_by(state, use_group_primary) %>%
    dplyr::summarise(v = sum(usd), .groups = "drop") %>%
    dplyr::mutate(use_group_primary = factor(use_group_primary, YS_USE_GROUPS)) %>%
    tidyr::pivot_wider(names_from = use_group_primary, values_from = v, values_fill = 0, names_expand = TRUE)
  names(hg)[match(YS_USE_GROUPS, names(hg))] <- paste0("hospital_", tolower(YS_USE_GROUPS), "_usd")
  # SESSION 124 (owner ruling 7a-f): NON-ADDITIVE. Award dollars whose evidence
  # includes each group: an award counts under EVERY group its letters touch.
  # Never summed; the primary-group table (1) stays the additive one.
  grp_of <- rhtp_use_groups()
  touch <- items %>% dplyr::filter(nzchar(dplyr::coalesce(use_categories_all, ""))) %>%
    dplyr::mutate(g = lapply(strsplit(use_categories_all, ";", fixed = TRUE),
                             function(l) unique(unname(grp_of[trimws(l)])))) %>%
    tidyr::unnest(g) %>%
    dplyr::group_by(use_group = g) %>%
    dplyr::summarise(award_usd_touching = sum(usd), hospital_usd_touching = sum(usd[call == "HOSPITAL"]),
                     .groups = "drop") %>%
    dplyr::mutate(use_group = factor(use_group, YS_USE_GROUPS)) %>% dplyr::arrange(use_group) %>%
    dplyr::mutate(use_group = as.character(use_group), use_group_label = ys_use_label(use_group)) %>%
    dplyr::select(use_group, use_group_label, award_usd_touching, hospital_usd_touching)
  list(national = national, basis = basis, coverage_state = cov_state, by_state = by_state, caps = caps,
       hospital_by_group = hg, items = items, touches = touch)
}

#' The CSV record of the sheet (long form).
ys_use_csv <- function(u) {
  long <- function(d, section, id) tidyr::pivot_longer(d %>% dplyr::mutate(dplyr::across(-dplyr::all_of(id), as.character)),
                                                      -dplyr::all_of(id), names_to = "measure", values_to = "value") %>%
    dplyr::mutate(section = section) %>% dplyr::rename(key = dplyr::all_of(id[1]))
  dplyr::bind_rows(
    long(u$national %>% dplyr::select(-use_group, -letters), "national_by_group", "use_group_primary"),
    long(u$basis, "coverage_by_basis", "use_category_basis"),
    long(u$coverage_state %>% dplyr::select(-state_name), "coverage_by_state", "state"),
    long(u$by_state %>% dplyr::select(-state_name), "by_state_group", "state"),
    long(u$caps %>% dplyr::select(-state_name), "provider_payments_capital_vs_caps", "state")) %>%
    dplyr::select(section, key, measure, value)
}

YS_USE_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "use_group_primary / use group", "The owner group of the CMS use of funds (NOFO letters A-K, Section 71401 of Public Law 119-21) that the award's evidence supports: Prevention and chronic disease (A); Direct provider payments (B); Health IT and technology (C, D, F); Workforce (E); Service lines and care availability (G); Behavioral health (H); Care delivery and payment transformation (I); Capital and infrastructure (J); Partnerships and regional networks (K). MULTIPLE: the evidence spans more than one group and no source points to one. NOT_STATED: no source states the activity closely enough. Read from the ACTIVITY the award funds, never from the recipient. An award's dollars are never divided across categories.",
  "use_category_basis", "AWARD_SOURCE (HIGH): the award document states the CMS category for the award or its round. INITIATIVE_CROSSWALK (MEDIUM): the award belongs to a named state initiative or round that the state's own plan (project abstract, budget narrative, project narrative, NOFO) ties to CMS letters (config/initiative_use_crosswalk.csv, each line quoted and archived). PURPOSE_TEXT (LOW): the award's own description, hand-read against the NOFO definition, one call per description (config/use_category_cases.csv). NOT_STATED: none applies.",
  "award_usd / rows", "Award dollars in award_total_usd (priced rows plus pool-level round figures, each pool at its ROUND's category) and award rows. Rows count award rows only; pool-level dollars have no row. The groups, MULTIPLE and NOT_STATED included, sum to awards published (asserted state by state).",
  "hospital_usd / not_hospital_usd", "The award dollars split by R/07's summary call, exactly as hospital_summary_usd is built: a row called HOSPITAL (not SOURCE_SUSPECT), a pool R/07 calls HOSPITAL, an R/07 HOSPITAL component (counted in its parent row's category). The HOSPITAL column sums to hospital_summary_usd (asserted).",
  "share_of_classified_pct", "The group's dollars over all CLASSIFIED dollars (every group except NOT_STATED; MULTIPLE is classified). The hospital and non-hospital shares use the same denominator restricted to that call.",
  "classified_share_pct (coverage)", "Classified award dollars (basis not NOT_STATED) over the state's award dollars. A low share is a statement about what the state published, never about how it spends.",
  "b_primary / j_primary share of allotment", "PUBLISHED AWARDS ONLY, NOT THE STATE'S BUDGET. Award dollars whose primary category is B (provider payments) or J (capital), over the state's FY2026 allotment, beside the NOFO caps (B 15%, J 20% of the budget period award). b_any / j_any count every award whose evidence includes the letter, even where primary is another letter or MULTIPLE. These are not a test of compliance and no state is over a cap on this basis: caps apply to the state's whole budget, most money is not yet published, and an award carrying J among other letters is not all capital.",
  "CMS_REPORT_HEADING (basis, session 124)", "MEDIUM. A category heading CMS prints over the programme's line in its Obligated Funds Report (10-14 edition), tied to the plan's initiative by exact normalised name or a hand-reviewed line (config/use_category_cms_headings.csv). Where the heading's letter is among the plan's letters it sets the primary and resolves MULTIPLE; where it is not, the plan's letters stand and the conflict is recorded in use_category_quote.",
  "use_category_text_method (session 124)", "How an INITIATIVE_CROSSWALK plan quote was read: NATIVE_TEXT, OCR (MS, MI, KY: image-only or unreadable text layers) or HAND_TRANSCRIBED (HI Appendix A). OCR and transcription are admitted at MEDIUM (owner ruling) with the page images archived and each quoted line checked against its image.",
  "award_usd_touching (table 6)", "NON-ADDITIVE. Award dollars whose evidence includes the group: an award counts under every group its letters touch. Never summed; the primary-group table is the additive one.",
  "hospital_<group>_usd (Detail)", "The state's hospital best estimate (hospital_summary_usd) by use group, on the same items; the eleven columns sum to hospital_summary_usd.")

ys_use_notes <- function(u) {
  f <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  b <- u$basis; n <- u$national
  cls <- sum(b$award_usd[b$use_category_basis != "NOT_STATED"]); tot <- sum(b$award_usd)
  c(paste0("USE CATEGORIES (session 123, owner direction 11-24). ", f(cls), " of ", f(tot), " in awards published (",
           sprintf("%.1f%%", 100 * cls / tot), ") carry a CMS use-of-funds category on a quoted, archived source: ",
           paste0(b$use_category_basis[b$use_category_basis != "NOT_STATED"], " ", f(b$award_usd[b$use_category_basis != "NOT_STATED"]), collapse = "; "),
           ". The rest is NOT_STATED, which is an answer, not a gap filled by guesswork."),
    "Use categories read the ACTIVITY an award funds, never the recipient: a hospital award is not 'service lines' because a hospital received it. Most classifications rest on the state's plan crosswalk (MEDIUM): an initiative the plan ties to several CMS letters is MULTIPLE unless the award's own text points to one. An award's dollars are never divided across categories, so MULTIPLE is a real share of the money.",
    "Provider payments (B) and capital (J) as a share of the allotment are PUBLISHED AWARDS ONLY, not the state's budget; no state is called over a cap on this basis.")
}

ys_use_sheet <- function(wb, u, styles) {
  sh <- "By use category"
  openxlsx::addWorksheet(wb, sh)
  r <- 1
  put <- function(title, d, usd_cols, pct_cols, bold_last = FALSE) {
    openxlsx::writeData(wb, sh, title, startRow = r)
    openxlsx::addStyle(wb, sh, styles$bold, rows = r, cols = 1)
    openxlsx::writeData(wb, sh, d, startRow = r + 1, headerStyle = styles$hdr)
    rr <- (r + 2):(r + 1 + max(1, nrow(d)))
    if (length(usd_cols)) openxlsx::addStyle(wb, sh, styles$usd, rows = rr, cols = usd_cols, gridExpand = TRUE, stack = TRUE)
    if (length(pct_cols)) openxlsx::addStyle(wb, sh, styles$pct, rows = rr, cols = pct_cols, gridExpand = TRUE, stack = TRUE)
    if (bold_last) openxlsx::addStyle(wb, sh, styles$bold, rows = max(rr), cols = seq_along(d), stack = TRUE)
    r <<- max(rr) + 3
  }
  uc <- function(d) which(grepl("_usd$", names(d))); pc <- function(d) which(grepl("_pct$", names(d)))
  nat <- u$national %>% dplyr::select(-use_group_primary)
  put("1. National: award dollars and rows by use group, HOSPITAL vs NOT_HOSPITAL (R/07 summary call). Groups sum to awards published.",
      nat, uc(nat), pc(nat), bold_last = TRUE)
  put("2. Coverage by basis: share of award dollars and rows classified, by evidence class.", u$basis, uc(u$basis), pc(u$basis))
  put("3. Coverage by state.", u$coverage_state, uc(u$coverage_state), pc(u$coverage_state))
  put("4. By state: award dollars by use group (sums to the state's award_total_usd).", u$by_state, uc(u$by_state), pc(u$by_state))
  put(paste("5. Provider payments (B) and capital (J) as a share of the FY2026 allotment, beside the NOFO caps.",
            "PUBLISHED AWARDS ONLY, NOT THE STATE'S BUDGET: never read as a state over a cap."),
      u$caps, uc(u$caps), pc(u$caps))
  put(paste("6. NON-ADDITIVE VIEW: award dollars whose evidence includes each group. An award counts under every group",
            "its letters touch, so this table is NEVER summed and its rows do not add to awards published.",
            "Table 1 (primary group) is the additive one."),
      u$touches, uc(u$touches), integer(0))
  openxlsx::setColWidths(wb, sh, cols = 1:16, widths = c(34, 30, rep(17, 14)))
  openxlsx::freezePane(wb, sh, firstRow = FALSE, firstCol = TRUE)
  invisible(sh)
}

#' Append the hospital-by-use-group columns to the Detail table. The national
#' row is the sum over the states; the US_GE50 subset row is built on state
#' award sources only (session 111b) and carries no breakdown (empty).
ys_detail_use <- function(de, u) {
  hg <- u$hospital_by_group
  cols <- paste0("hospital_", tolower(YS_USE_GROUPS), "_usd")
  us <- hg %>% dplyr::summarise(dplyr::across(dplyr::all_of(cols), sum)) %>% dplyr::mutate(state = "US")
  out <- de %>% dplyr::left_join(dplyr::bind_rows(hg, us), by = "state") %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(cols), ~ ifelse(state == "US_GE50", NA_real_, dplyr::coalesce(.x, 0))))
  chk <- out %>% dplyr::filter(state != "US_GE50")
  if (any(abs(rowSums(chk[, cols]) - chk$hospital_summary_usd) > 0.01)) {
    stop("[use] Detail's hospital-by-group columns do not sum to hospital_summary_usd.", call. = FALSE)
  }
  out
}

ys_write <- function(date = format(Sys.Date(), "%Y-%m-%d")) {
  rows <- ys_rows()
  s <- ys_build(rows)
  readr::write_csv(s, here::here(YS_OUT(date)), na = "")
  unnamed <- rhtp_unnamed_contractor_lines()
  vt <- ys_vendor_build(s, rows, unnamed = unnamed)
  readr::write_csv(vt, here::here(YS_VENDOR_OUT(date)), na = "")
  readr::write_csv(unnamed, here::here(YS_UNNAMED_OUT), na = "")
  u <- ys_use_build(s)
  readr::write_csv(ys_use_csv(u), here::here(YS_USE_OUT(date)), na = "")
  ys_workbook(s, rows, date, here::here(YS_XLSX(date)), vt = vt, u = u)
  n <- s[s$state == "US", ]
  message(sprintf("[year1 summary] wrote %s and %s: award total $%s; hospital best estimate $%s (CODED $%s + BEST_JUDGMENT $%s); strict NAMED $%s.",
                  YS_OUT(date), YS_XLSX(date), format(n$award_total_usd, big.mark = ",", nsmall = 2),
                  format(n$hospital_summary_usd, big.mark = ",", nsmall = 2),
                  format(n$hospital_coded_usd, big.mark = ",", nsmall = 2),
                  format(n$hospital_best_judgment_usd, big.mark = ",", nsmall = 2),
                  format(n$strict_named_hospital_usd, big.mark = ",", nsmall = 2)))
  invisible(s)
}

ys_report <- function() {
  s <- ys_build()
  print(as.data.frame(s %>% dplyr::select(state, completion_status, allotment_usd, award_total_usd,
                                          hospital_coded_usd, hospital_best_judgment_usd,
                                          hospital_summary_usd, hospital_share_of_awards_pct,
                                          hospital_share_of_allotment_pct)), row.names = FALSE)
  invisible(s)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) ys_write()
  if ("--report" %in% args) ys_report()
  if (!length(intersect(args, c("--build", "--report")))) {
    message("usage: Rscript R/08_year1_summary.R [--build] [--report]")
  }
}

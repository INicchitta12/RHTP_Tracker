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
#                              hospital_bj_pool_usd)
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
#                          + HOSPITAL pools
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
# excluded), applied here to EVERY file in STATE_FILES -- R/03aw's own list
# lags (it omits MS_R2, MD_LABOR, VA_VHCF, NE_CMS, PA_CMS, RI and IN_GROW) --
# plus any R/07 pool that no file carries as a round figure (Ohio's two
# shared sub-pools). Every hospital dollar in the numerator is therefore in
# the denominator. Iowa's Tier 2 RFP pools are never added (§0.2).
# allotment is CMS's FY2026 table (§7.1).
#
# Usage:
#   Rscript R/08_year1_summary.R --build    # data/reference/year1_summary_<date>.csv
#   Rscript R/08_year1_summary.R --report

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_summary_calls.R"))
source(here::here("R", "07_summary_calls.R"))
source(here::here("R", "03aw_year1_completion_status.R"))

YS_ALLOT  <- "data/reference/cms_fy2026_allotments.csv"
YS_STATUS <- "data/reference/year1_completion_status.csv"
YS_SURVEY <- "data/reference/rcj_state_survey.csv"
YS_POOLS  <- "data/reference/summary_call_pools.csv"
YS_OUT    <- function(date) file.path("data", "reference", paste0("year1_summary_", date, ".csv"))

ys_has <- function(x, code) !is.na(x) & grepl(paste0("(^|;)", code, "(;|$)"), x)

#' Every award row, with the columns the summary reads
ys_rows <- function(files = sc_state_files()) {
  dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"),
                         na = c("", "NA"), progress = FALSE)
    rhtp_assert_summary_calls(d, k)
    col <- function(c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))
    tibble::tibble(
      file_key = k, state = d$state, awardee = d$awardee,
      amount = suppressWarnings(as.numeric(d$amount)),
      distributed_to_hospital = d$distributed_to_hospital, flow_type = col("flow_type"),
      recipient_type = col("recipient_type"), hospital_attribution = col("hospital_attribution"),
      flag_reason = col("flag_reason"), basis_type = col("basis_type"),
      determination_confidence = col("determination_confidence"),
      recipient_subtype = col("recipient_subtype"),
      validation_source_type = col("validation_source_type"),
      call = d$summary_hospital_call, basis = d$summary_call_basis)
  }))
}

ys_usd <- function(x) sum(x, na.rm = TRUE)

#' R/03aw's per-file published figures, over every file in STATE_FILES
ys_file_figures <- function(files = sc_state_files()) {
  dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"),
                         progress = FALSE)
    f <- y1_file_figures(unique(d$state)[1], basename(files[[k]]))
    f$pool_with_priced_members <- ys_pool_overlap(d, unique(d$state)[1])
    f
  }))
}

#' Round figures R/03aw counts whose pool ALSO has priced rows in the same file.
#'
#' R/03aw adds a round figure once per distinct pool among UNPRICED rows. Once
#' a state prices a pool's lines (Nevada's BP1 report, session 101), the round
#' figure and the priced lines are the same money, and adding both puts
#' Nevada's published total at $243.5M against a $179.9M allotment. A round
#' figure whose own pool's priced rows already reach it is therefore treated
#' as inside sum(amount) and subtracted here, never from R/03aw's own table
#' (recorded for the owner, docs/session110_*).
ys_pool_overlap <- function(d, st) {
  if (st == "GA" || st %in% Y1_POOL_EXCLUDED || !"round_amount" %in% names(d)) return(0)
  amt <- suppressWarnings(as.numeric(d$amount))
  r <- suppressWarnings(as.numeric(d$round_amount))
  key <- if ("award_pool" %in% names(d)) d$award_pool else d$source_document_title
  k <- is.na(amt) & !is.na(r)
  pools <- dplyr::distinct(tibble::tibble(p = key[k], r = r[k]))
  # Covered = the pool's priced rows already reach the round figure. Louisiana
  # is the reason for the second test: its round figure ($10,736,208) is the
  # 48 UNNAMED awards, and its five priced rows ($1,965,788) are other money.
  covered <- vapply(seq_len(nrow(pools)), function(i) {
    sum(amt[key %in% pools$p[i]], na.rm = TRUE) >= pools$r[i]
  }, logical(1))
  sum(pools$r[covered])
}

#' The per-state table, national row last
ys_build <- function(rows = ys_rows(), pools = NULL) {
  if (is.null(pools)) {
    pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE, progress = FALSE)
  }
  allot <- readr::read_csv(here::here(YS_ALLOT), show_col_types = FALSE, progress = FALSE)
  status <- readr::read_csv(here::here(YS_STATUS), show_col_types = FALSE, progress = FALSE)
  survey <- readr::read_csv(here::here(YS_SURVEY), show_col_types = FALSE, progress = FALSE)

  rows <- rows %>% dplyr::mutate(
    suspect = ys_has(flag_reason, "SOURCE_SUSPECT"),
    amt = dplyr::coalesce(amount, 0),
    hosp = call == "HOSPITAL" & !suspect)

  part <- rhtp_hospital_dollar_partition(rows %>% dplyr::select(-suspect, -amt, -hosp))
  strict <- part %>%
    dplyr::select(state, bucket, dollars) %>%
    tidyr::pivot_wider(names_from = bucket, values_from = dollars, values_fill = 0)
  for (b in c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS", "POOL_UNNAMED_HOSPITALS")) {
    if (!b %in% names(strict)) strict[[b]] <- 0
  }

  pool_by <- pools %>% dplyr::group_by(state) %>% dplyr::summarise(
    called_pool_outside_files_usd = ys_usd(pool_usd[!in_file_round_figures]),
    hospital_bj_pool_usd = ys_usd(pool_usd[call == "HOSPITAL"]), .groups = "drop")
  fig <- ys_file_figures() %>% dplyr::group_by(state) %>% dplyr::summarise(
    file_pool_level_usd = ys_usd(pool_level_unpriced - priced_inside_pool - pool_with_priced_members),
    .groups = "drop")

  by <- rows %>% dplyr::group_by(state) %>% dplyr::summarise(
    award_files = dplyr::n_distinct(file_key),
    award_rows = dplyr::n(),
    priced_rows = sum(!is.na(amount)),
    published_priced_usd = ys_usd(amount),
    hospital_rows = sum(hosp),
    hospital_coded_usd = ys_usd(amt[hosp & basis == "CODED"]),
    hospital_bj_row_usd = ys_usd(amt[hosp & basis == "BEST_JUDGMENT"]),
    best_judgment_rows = sum(basis == "BEST_JUDGMENT"),
    layer_ahc_usd = ys_usd(amt[hosp & recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"]),
    layer_general_knowledge_usd = ys_usd(amt[hosp & basis_type %in% "GENERAL_KNOWLEDGE"]),
    layer_low_confidence_usd = ys_usd(amt[hosp & determination_confidence %in% "LOW"]),
    layer_intent_usd = ys_usd(amt[hosp & validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD"]),
    layer_cms_obligation_usd = ys_usd(amt[hosp & validation_source_type %in% "CMS_OBLIGATION_REPORT"]),
    layer_source_suspect_usd = ys_usd(amt[call == "HOSPITAL" & suspect]),
    .groups = "drop")

  st_status <- dplyr::bind_rows(
    status %>% dplyr::transmute(state, completion_status = year1_status),
    survey %>% dplyr::filter(!state %in% status$state) %>%
      dplyr::transmute(state, completion_status = paste0("NOT_ASSESSED (survey: ", extraction_status, ")")))

  out <- allot %>%
    dplyr::select(state, state_name, allotment_usd = fy2026_allotment) %>%
    dplyr::left_join(by, by = "state") %>%
    dplyr::left_join(pool_by, by = "state") %>%
    dplyr::left_join(fig, by = "state") %>%
    dplyr::left_join(strict, by = "state") %>%
    dplyr::left_join(st_status, by = "state") %>%
    dplyr::mutate(dplyr::across(c(award_files, award_rows, priced_rows, hospital_rows, best_judgment_rows),
                                ~ dplyr::coalesce(as.integer(.x), 0L)),
                  dplyr::across(c(published_priced_usd, hospital_coded_usd, hospital_bj_row_usd,
                                  called_pool_outside_files_usd, file_pool_level_usd,
                                  hospital_bj_pool_usd, NAMED_HOSPITAL,
                                  POOL_NAMED_HOSPITALS, POOL_UNNAMED_HOSPITALS,
                                  dplyr::starts_with("layer_")),
                                ~ dplyr::coalesce(.x, 0)),
                  completion_status = dplyr::coalesce(completion_status, "NOT_ASSESSED"))

  national <- out %>% dplyr::summarise(
    state = "US", state_name = "National (50 states)",
    dplyr::across(c(allotment_usd, award_files, award_rows, priced_rows, published_priced_usd,
                    hospital_rows, hospital_coded_usd, hospital_bj_row_usd, best_judgment_rows,
                    called_pool_outside_files_usd, file_pool_level_usd, hospital_bj_pool_usd,
                    NAMED_HOSPITAL, POOL_NAMED_HOSPITALS,
                    POOL_UNNAMED_HOSPITALS, dplyr::starts_with("layer_")), sum),
    completion_status = paste0(sum(completion_status == "COMPLETE"), " COMPLETE of 50"))

  dplyr::bind_rows(out %>% dplyr::arrange(state), national) %>%
    dplyr::mutate(
      pool_level_usd = file_pool_level_usd + called_pool_outside_files_usd,
      award_total_usd = published_priced_usd + pool_level_usd,
      hospital_best_judgment_usd = hospital_bj_row_usd + hospital_bj_pool_usd,
      hospital_summary_usd = hospital_coded_usd + hospital_best_judgment_usd,
      hospital_share_of_awards_pct = ifelse(award_total_usd > 0,
                                            round(100 * hospital_summary_usd / award_total_usd, 1), NA_real_),
      hospital_share_of_allotment_pct = round(100 * hospital_summary_usd / allotment_usd, 1),
      award_share_of_allotment_pct = round(100 * award_total_usd / allotment_usd, 1)) %>%
    dplyr::transmute(
      state, state_name, completion_status, allotment_usd,
      award_files, award_rows, priced_rows,
      published_priced_usd, pool_level_usd, award_total_usd, award_share_of_allotment_pct,
      hospital_rows, hospital_coded_usd, hospital_best_judgment_usd,
      hospital_bj_row_usd, hospital_bj_pool_usd, best_judgment_rows, hospital_summary_usd,
      hospital_share_of_awards_pct, hospital_share_of_allotment_pct,
      strict_named_hospital_usd = NAMED_HOSPITAL,
      strict_pool_named_hospitals_usd = POOL_NAMED_HOSPITALS,
      strict_pool_unnamed_hospitals_usd = POOL_UNNAMED_HOSPITALS,
      layer_ahc_usd, layer_general_knowledge_usd, layer_low_confidence_usd, layer_intent_usd,
      layer_cms_obligation_usd, layer_source_suspect_usd)
}

ys_write <- function(date = format(Sys.Date(), "%Y-%m-%d")) {
  s <- ys_build()
  readr::write_csv(s, here::here(YS_OUT(date)), na = "")
  n <- s[s$state == "US", ]
  message(sprintf("[year1 summary] wrote %s: award total $%s; hospital $%s (CODED $%s + BEST_JUDGMENT $%s); strict NAMED $%s.",
                  YS_OUT(date), format(n$award_total_usd, big.mark = ",", nsmall = 2),
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

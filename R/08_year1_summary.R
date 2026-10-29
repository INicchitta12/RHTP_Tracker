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
#                                           # Detail, Definitions, Notes and caveats, Sources)
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
ys_build <- function(rows = ys_rows(), pools = NULL, components = NULL) {
  if (is.null(pools)) {
    pools <- readr::read_csv(here::here(YS_POOLS), show_col_types = FALSE, progress = FALSE)
  }
  if (is.null(components)) {
    components <- readr::read_csv(here::here(YS_COMPONENTS), show_col_types = FALSE, progress = FALSE)
  }
  allot <- readr::read_csv(here::here(YS_ALLOT), show_col_types = FALSE, progress = FALSE)
  status <- readr::read_csv(here::here(YS_STATUS), show_col_types = FALSE, progress = FALSE)
  survey <- readr::read_csv(here::here(YS_SURVEY), show_col_types = FALSE, progress = FALSE)
  rural <- readr::read_csv(here::here(YS_RURAL), col_types = readr::cols(.default = "c"), progress = FALSE)

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
  fig <- ys_file_figures() %>% dplyr::group_by(state) %>% dplyr::summarise(
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
                "strict_rural_cut_usd", "strict_cah_usd", "confidential_award_usd")
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
    dplyr::left_join(st_status, by = "state") %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(int_cols), ~ dplyr::coalesce(as.integer(.x), 0L)),
                  dplyr::across(c(dplyr::all_of(num_cols), dplyr::starts_with("layer_")), ~ dplyr::coalesce(.x, 0)),
                  completion_status = dplyr::coalesce(completion_status, "NOT_ASSESSED"))

  national <- out %>% dplyr::summarise(
    state = "US", state_name = "National (50 states)",
    dplyr::across(c(allotment_usd, dplyr::all_of(int_cols), dplyr::all_of(num_cols),
                    dplyr::starts_with("layer_")), sum),
    completion_status = paste0(sum(completion_status == "COMPLETE"), " COMPLETE of 50"))

  pct <- function(n, d) ifelse(d > 0, round(100 * n / d, 1), NA_real_)
  dplyr::bind_rows(out %>% dplyr::arrange(state), national) %>%
    dplyr::mutate(
      pool_level_usd = file_pool_level_usd + called_pool_outside_files_usd,
      award_total_usd = published_priced_usd + pool_level_usd,
      hospital_best_judgment_usd = hospital_bj_row_usd + hospital_bj_pool_usd + hospital_bj_component_usd,
      hospital_summary_usd = hospital_coded_usd + hospital_best_judgment_usd,
      hospital_share_of_awards_pct = pct(hospital_summary_usd, award_total_usd),
      hospital_share_of_allotment_pct = pct(hospital_summary_usd, allotment_usd),
      award_share_of_allotment_pct = pct(award_total_usd, allotment_usd),
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
      confidential_source_flag)
}

# -- the workbook (session 111) ---------------------------------------------------

#' Plain-language definitions, one per Detail (CSV) column, in column order. The
#' builder refuses a column without one.
YS_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "state", "Two-letter state code; US is the national row (the sum of the 50 state rows).",
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
  "hospital_share_of_awards_pct", "Best-estimate hospital dollars as a percent of the published award total.",
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
  "confidential_source_flag", "Marks a state whose rows or notes cite Delaware's confidential source (DE Verify.xlsx). Flagged material must not leave the team.")

ys_notes <- function(s, date) {
  us <- s[s$state == "US", ]
  f <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  tibble::tibble(note = c(
    paste0("HOW TO READ THIS. Start on Overview (one row per state, national total last): 'Hospital $ (best estimate)' is the headline figure, ",
           "'Strict named-hospital $' the source-confirmed floor; Detail carries every column, Definitions defines each column and status label, Sources lists the documents."),
    paste0("DATA AS OF ", date, ". Built by R/08_year1_summary.R from the committed award files; every figure traces to an archived state or CMS source (Sources sheet)."),
    paste0("BEST ESTIMATE vs STRICT. hospital_summary_usd (", f(us$hospital_summary_usd), ") combines the strict buckets with best-judgment calls on every undetermined row. ",
           "The strict columns are the defensible floor: strict_named_hospital_usd (", f(us$strict_named_hospital_usd), ") is source-confirmed named-hospital money. ",
           "The three strict columns are never added to one another; the best estimate is a different measure built from the summary calls."),
    paste0("BEST JUDGMENT. ", f(us$hospital_best_judgment_usd), " of the best estimate rests on judgment (shared pools called on a strict majority of typed members, ",
           "hospital associations and networks, a component of New Hampshire's FHC award). Subtract hospital_best_judgment_usd to return to coded figures."),
    paste0("INTENTS ARE NOT EXECUTED AWARDS. ", f(us$layer_intent_usd), " of the best estimate is published as notices of intent to award (Texas, California, Arkansas, Oregon, Alaska and others). ",
           "States may change or withdraw them before agreements are signed."),
    paste0("CMS-OBLIGATION ROWS ARE 'OBLIGATED, PER CMS'. ", f(us$layer_cms_obligation_usd), " of the best estimate comes from CMS's Obligated Funds Report (as of 2026-07-31), ",
           "self-reported by the state; it is an obligation to a first-tier entity, not a confirmed subaward."),
    paste0("ROWS WITH NO PUBLISHED AMOUNT. ", us$named_hospital_recipients_no_amount, " named hospital recipients carry no published amount (Iowa, Indiana GROW, Nevada's unpriced lines, North Carolina, Tennessee, Delaware and others). ",
           "Their money is in no dollar column, so the hospital share is understated in those states."),
    "OREGON. CMS's Budget Period 1 award to Oregon is $5,000,000.33 below its FY2026 allotment (CMS Obligated Funds Report, as of 2026-07-31); the repository has not explained the difference. The allotment column uses the FY2026 table.",
    paste0("SOURCE_SUSPECT ROWS ARE EXCLUDED. ", f(us$layer_source_suspect_usd), " on rows whose published amount is internally inconsistent (Nevada FLEX-28 and FLEX-36, Texas Anson Hospital District) is left out of every hospital figure (owner ruling, session 102)."),
    "LAYERS OVERLAP. The layer_ columns (intents, association ruling, CMS obligation, AHC, general knowledge, LOW confidence) are parts of the best estimate and overlap one another. Never add them.",
    "NO STATE IS COMPARABLE TO ANOTHER WITHOUT READING ITS ROWS: figures mix intents, offers, executed agreements, rounded and partial-year amounts.",
    paste0("AWARD COVERAGE VARIES WIDELY BY STATE. Awards published run from 0% to ", sprintf("%.1f%%", 100 * max(s$award_total_usd[s$state != "US"] / s$allotment_usd[s$state != "US"])),
           " of the allotment, so a state's hospital share describes only the money that state has published so far. State shares are not comparable to one another."),
    paste0("n/m (HOSPITAL % OF AWARDS). Shown only where awards published are at least ", 100 * YS_AWARD_SHARE_MIN, "% of the allotment. ", YS_NM_NOTE,
           " Hospital % of allotment is shown for every state."),
    paste0("CONFIDENTIAL SOURCES. ", YS_CONFIDENTIAL_NOTE, " As built, no award row or figure cites it; Delaware's status-table notes do (confidential_source_flag; the row is shaded on Overview and Detail).")))
}

#' One row per state: the primary source document(s) and their archive paths
ys_sources <- function(rows, s) {
  st <- s$state[s$state != "US"]
  j <- function(x) {
    x <- sort(unique(stats::na.omit(x[nzchar(x)])))
    out <- paste(x, collapse = " ; ")
    if (nchar(out) > 32000) out <- paste0(substr(out, 1, 32000), " ... [truncated; see the award files]")
    out
  }
  status <- readr::read_csv(here::here(YS_STATUS), show_col_types = FALSE, progress = FALSE)
  conf <- ys_confidential_status()
  dplyr::bind_rows(lapply(st, function(x) {
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
YS_AWARD_SHARE_MIN <- 0.5
YS_NM <- "n/m"
YS_NM_NOTE <- paste(
  "Not meaningful where most of the state's money is not yet published; e.g., Illinois's only",
  "published award is ICAHN's hospital network grant.")

#' The plain-language Year 1 status labels, in the order they are assigned
YS_STATUS_LABELS <- tibble::tribble(
  ~label, ~definition,
  "Complete", "A state source says the state has finished awarding its Year 1 money (completion_status COMPLETE: Florida, Georgia, Arkansas, Alabama).",
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
      state == "US" ~ NA_character_,
      completion_status == "COMPLETE" ~ "Complete",
      award_rows > 0 & cms_only %in% TRUE ~ "CMS obligation report only",
      award_rows > 0 & priced_rows > 0 ~ "Partial: awarding continues",
      award_rows > 0 ~ "Awards published, not priced",
      TRUE ~ "No awards published yet"))
  if (any(is.na(x$label[x$state != "US"]))) stop("[year1 summary] a state has no status label", call. = FALSE)
  if (!all(x$label[x$state != "US"] %in% YS_STATUS_LABELS$label)) stop("[year1 summary] undefined status label", call. = FALSE)
  st <- x$label[x$state != "US"]
  x$label[x$state == "US"] <- paste0(sum(st == "Complete"), " Complete of ", length(st))
  x$label
}

#' TRUE where a share of the published award total is meaningful
ys_share_meaningful <- function(s) s$allotment_usd > 0 & s$award_total_usd / s$allotment_usd >= YS_AWARD_SHARE_MIN

ys_frac <- function(n, d) ifelse(d > 0, n / d, NA_real_)

#' The Overview sheet: one row per state, national row last
YS_OVERVIEW_DEFINITIONS <- tibble::tribble(
  ~column, ~definition,
  "State", "State name; the last row is the national total (the sum of the 50 state rows).",
  "Year 1 status", "Plain-language Year 1 status; each label is defined below.",
  "FY2026 allotment", "The state's FY2026 RHTP allotment from CMS (Tier 1), from CMS's own table (Detail: allotment_usd).",
  "Awards published", "Published Year 1 award total: per-award amounts plus pool-level totals (Detail: award_total_usd).",
  "% of allotment awarded", "Awards published as a share of the allotment (Detail: award_share_of_allotment_pct).",
  "Hospital $ (best estimate)", "BEST ESTIMATE of Year 1 RHTP dollars reaching hospitals: source-coded plus best-judgment hospital dollars (Detail: hospital_summary_usd).",
  "Hospital % of awards", "Best-estimate hospital dollars as a share of awards published. Shown only where awards published are at least 50% of the allotment; otherwise n/m (not meaningful) (Detail: hospital_share_of_awards_pct).",
  "Hospital % of allotment", "Best-estimate hospital dollars as a share of the allotment, shown for every state (Detail: hospital_share_of_allotment_pct).",
  "Strict named-hospital $", "STRICT: dollars awarded to a named hospital or health system on a state source; the defensible floor (Detail: strict_named_hospital_usd).",
  "Hospitals named, no amount", "Named hospital recipients (distinct names) with no published amount; their money is in no dollar column (Detail: named_hospital_recipients_no_amount).")

ys_overview <- function(s, rows) {
  ok <- ys_share_meaningful(s)
  tibble::tibble(
    "State" = s$state_name,
    "Year 1 status" = ys_status_label(s, rows),
    "FY2026 allotment" = s$allotment_usd,
    "Awards published" = s$award_total_usd,
    "% of allotment awarded" = ys_frac(s$award_total_usd, s$allotment_usd),
    "Hospital $ (best estimate)" = s$hospital_summary_usd,
    "Hospital % of awards" = ifelse(ok, ys_frac(s$hospital_summary_usd, s$award_total_usd), NA_real_),
    "Hospital % of allotment" = ys_frac(s$hospital_summary_usd, s$allotment_usd),
    "Strict named-hospital $" = s$strict_named_hospital_usd,
    "Hospitals named, no amount" = s$named_hospital_recipients_no_amount)
}

#' The Detail sheet: every CSV column; the _pct columns as fractions, and the
#' award share "n/m" (written by the workbook) where it is not meaningful
ys_detail <- function(s) {
  ok <- ys_share_meaningful(s)
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
ys_table_sheet <- function(wb, sheet, d, usd_cols, pct_cols, nm_rows, nm_col, conf_rows, styles) {
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
  openxlsx::addStyle(wb, sheet, styles$bold, rows = nrow(d) + 1, cols = seq_along(d), gridExpand = TRUE, stack = TRUE)
  if (length(conf_rows)) {
    openxlsx::addStyle(wb, sheet, styles$conf, rows = conf_rows + 1, cols = seq_along(d), gridExpand = TRUE, stack = TRUE)
  }
  w <- ys_widths(d, usd_cols, pct_cols)
  openxlsx::setColWidths(wb, sheet, cols = seq_along(d), widths = w)
  long <- which(w >= 60)
  if (length(long)) openxlsx::addStyle(wb, sheet, styles$wrap, rows = body, cols = long, gridExpand = TRUE, stack = TRUE)
  openxlsx::freezePane(wb, sheet, firstActiveRow = 2, firstActiveCol = 2)
}

ys_workbook <- function(s, rows, date, path) {
  miss <- setdiff(names(s), YS_DEFINITIONS$column)
  extra <- setdiff(YS_DEFINITIONS$column, names(s))
  if (length(miss) || length(extra)) {
    stop("[year1 summary] Definitions out of step with the Detail columns: missing ",
         paste(miss, collapse = ", "), "; extra ", paste(extra, collapse = ", "), call. = FALSE)
  }
  if (s$state[nrow(s)] != "US") stop("[year1 summary] the national row must be last", call. = FALSE)
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
  nm_rows <- which(!ys_share_meaningful(s))
  conf_rows <- which(nzchar(s$confidential_source_flag))

  # Overview is sorted by state NAME (the column it shows), national row last.
  so <- s[order(s$state == "US", s$state_name), ]
  ov <- ys_overview(so, rows)
  ys_table_sheet(wb, "Overview", ov,
                 usd_cols = which(names(ov) %in% c("FY2026 allotment", "Awards published",
                                                    "Hospital $ (best estimate)", "Strict named-hospital $")),
                 pct_cols = which(grepl("%", names(ov))),
                 nm_rows = which(!ys_share_meaningful(so)), nm_col = which(names(ov) == "Hospital % of awards"),
                 conf_rows = which(nzchar(so$confidential_source_flag)), styles = styles)

  de <- ys_detail(s)
  ys_table_sheet(wb, "Detail", de,
                 usd_cols = which(grepl("_usd$", names(de))),
                 pct_cols = which(grepl("_pct$", names(de))),
                 nm_rows = nm_rows, nm_col = which(names(de) == "hospital_share_of_awards_pct"),
                 conf_rows = conf_rows, styles = styles)

  defs <- dplyr::bind_rows(
    YS_OVERVIEW_DEFINITIONS %>% dplyr::transmute(sheet = "Overview", term = column, definition),
    YS_STATUS_LABELS %>% dplyr::transmute(sheet = "Year 1 status label", term = label, definition),
    YS_DEFINITIONS %>% dplyr::transmute(sheet = "Detail", term = column, definition))
  openxlsx::addWorksheet(wb, "Definitions")
  openxlsx::writeData(wb, "Definitions", defs, headerStyle = hdr)
  openxlsx::setColWidths(wb, "Definitions", cols = 1:3, widths = c(22, 36, 120))
  openxlsx::addStyle(wb, "Definitions", wrap, rows = 2:(nrow(defs) + 1), cols = 3, stack = TRUE)
  openxlsx::freezePane(wb, "Definitions", firstRow = TRUE)

  n <- ys_notes(s, date)
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

#' openxlsx 4.2.9 (with zip 3.x) lists drawing and VML parts in each sheet's
#' relationships without writing them, so strict readers (openpyxl) refuse the
#' file and Excel may offer to "repair" it. Remove every relationship whose
#' target part is not in the package; nothing in the sheets references them.
ys_strip_dangling_rels <- function(path) {
  tmp <- tempfile("ys_xlsx_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = tmp)
  rels <- list.files(file.path(tmp, "xl", "worksheets", "_rels"), "\\.rels$", full.names = TRUE)
  for (f in rels) {
    x <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "")
    parts <- regmatches(x, gregexpr("<Relationship [^>]*/>", x))[[1]]
    keep <- vapply(parts, function(r) {
      tgt <- sub('.*Target="([^"]+)".*', "\\1", r)
      grepl('TargetMode="External"', r, fixed = TRUE) ||
        file.exists(normalizePath(file.path(tmp, "xl", "worksheets", tgt), mustWork = FALSE))
    }, logical(1))
    for (r in parts[!keep]) x <- sub(r, "", x, fixed = TRUE)
    writeLines(x, f, useBytes = TRUE)
  }
  files <- list.files(tmp, recursive = TRUE, all.files = TRUE)
  unlink(path)
  zip::zip(path, files = files, root = tmp)
  invisible(path)
}

ys_write <- function(date = format(Sys.Date(), "%Y-%m-%d")) {
  rows <- ys_rows()
  s <- ys_build(rows)
  readr::write_csv(s, here::here(YS_OUT(date)), na = "")
  ys_workbook(s, rows, date, here::here(YS_XLSX(date)))
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

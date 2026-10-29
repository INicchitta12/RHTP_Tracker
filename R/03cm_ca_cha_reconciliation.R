#!/usr/bin/env Rscript
# 03cm_ca_cha_reconciliation.R ------------------------------------------------
#
# CALIFORNIA: OUR CALLS AGAINST CHA's INFORMAL READING OF THE SAME ROSTER.
# A VALIDATION REPORT. IT CHANGES NO AWARD ROW, NO SUMMARY CALL AND NO FIGURE.
#
# CHA (the California Hospital Association) coded HCAI's 10-21/10-23
# "Recommended Subrecipients for CalRHT Budget Period 1" list line by line as
# hospital / non-hospital, state-rural and CAH. The owner supplied it on 10-29
# (data/evidence/CA/validation/, PROVENANCE.txt beside it). It is a second
# reader, not a source (§0.1, §0.4): nothing here may move a row.
#
# What this file does:
#   1. Matches all 108 CHA lines to the 108 rows of ca_year1_awardees.csv on
#      programme + amount (to the cent). Where several rows share both, the
#      exact normalised name decides, and a single leftover pair is matched by
#      elimination; every match is 1:1 or the build stops.
#   2. Lists every row where CHA's hospital / non-hospital call differs from
#      our summary_hospital_call, and every row where CHA's CAH flag differs
#      from ours (a CCN 13xx on the row, R/08's strict_cah_usd rule).
#   3. Reconciles the two totals and states which rows make each gap.
#   4. Records that CHA's "Rural Hospital" figure uses California's STATE
#      rural designation, not the CMS CAH cut, and so is compared with nothing.
#
# Usage:
#   Rscript R/03cm_ca_cha_reconciliation.R --build    # writes the CSV
#   Rscript R/03cm_ca_cha_reconciliation.R --report

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(stringr); library(tibble)
  library(readxl); library(purrr); library(here)
})

CHA_XLSX <- here::here("data", "evidence", "CA", "validation",
                       "RHTP_awards_10.23.26_.xlsx")
CHA_CA_FILE <- here::here("data", "reference", "ca_year1_awardees.csv")
CHA_RECON_CSV <- here::here("data", "reference", "ca_cha_reconciliation.csv")

# CHA's Program column -> our award_pool. Exact strings, both sides.
CHA_POOL_MAP <- c(
  "Transformative Payments"        = "Transformative Payments",
  "Accelerator Partner Program"    = "Accelerator Partner Program",
  "Electronic Health Record Modernization" =
    "Electronic Health Record Modernization (EHR)",
  "FM-OB Fellowship Program"       = "FM-OB Fellowship Program",
  "Workforce Development" =
    "Workforce Development Recruitment and Retention Program (WDRR)"
)

# CHA's own summary block (rows 3-7 of the sheet), read, never typed in.
cha_summary <- function(path = CHA_XLSX) {
  s <- readxl::read_excel(path, sheet = 1, range = "I3:J7",
                          col_names = c("label", "value"))
  s %>% dplyr::mutate(label = stringr::str_remove(label, ":$"),
                      value = round(as.numeric(value), 2))
}

cha_rows <- function(path = CHA_XLSX) {
  hdr <- names(readxl::read_excel(path, sheet = 1, skip = 9, n_max = 0))
  if (!identical(hdr, c("Program", "Non-hospital", "ID", "Hospital",
                        "State Rural", "CAH", "System", "Location",
                        "Amount", "Notes")))
    stop("CHA sheet layout changed; header row 10 reads: ",
         paste(hdr, collapse = " | "))
  x <- readxl::read_excel(path, sheet = 1, skip = 10,
         col_names = c("program", "non_hospital", "id", "hospital",
                       "state_rural", "cah", "system", "location",
                       "amount", "notes"),
         col_types = "text")
  unknown <- setdiff(unique(x$program), names(CHA_POOL_MAP))
  if (length(unknown) > 0)
    stop("CHA programme not in CHA_POOL_MAP: ", paste(unknown, collapse = "; "))
  x %>%
    dplyr::mutate(cha_row = dplyr::row_number() + 10L,
                  award_pool = unname(CHA_POOL_MAP[program]),
                  amount = round(as.numeric(amount), 2),
                  cha_call = dplyr::if_else(non_hospital == "0",
                                            "HOSPITAL", "NOT_HOSPITAL"),
                  cha_cah = dplyr::coalesce(cah == "Yes", FALSE),
                  cha_state_rural = state_rural)
}

our_rows <- function(path = CHA_CA_FILE) {
  readr::read_csv(path, show_col_types = FALSE,
                  col_types = readr::cols(ccn = "c", .default = "?")) %>%
    dplyr::mutate(amount = round(amount, 2),
                  our_cah = dplyr::coalesce(
                    summary_hospital_call == "HOSPITAL" &
                      stringr::str_sub(ccn, 3, 4) == "13", FALSE))
}

cha_norm <- function(x) {
  x %>% stringr::str_to_lower() %>%
    stringr::str_replace_all("[^a-z0-9]+", " ") %>% stringr::str_squish()
}

# Programme + amount, then exact name inside a tie, then elimination.
cha_match <- function(cha = cha_rows(), ours = our_rows()) {
  key <- function(d) paste(d$award_pool, sprintf("%.2f", d$amount))
  cha$key <- key(cha); ours$key <- key(ours)
  out <- purrr::map_dfr(unique(cha$key), function(k) {
    a <- cha[cha$key == k, ]; b <- ours[ours$key == k, ]
    if (nrow(a) != nrow(b))
      stop("programme + amount group has ", nrow(a), " CHA lines and ",
           nrow(b), " of ours: ", k)
    if (nrow(a) == 1)
      return(tibble::tibble(cha_row = a$cha_row, row_no = b$row_no,
                            match_method = "PROGRAMME_AMOUNT"))
    exact <- dplyr::inner_join(
      a %>% dplyr::transmute(cha_row, n = cha_norm(hospital)),
      b %>% dplyr::transmute(row_no, n = cha_norm(awardee)), by = "n")
    if (any(duplicated(exact$cha_row)) || any(duplicated(exact$row_no)))
      stop("duplicate names inside a tie: ", k)
    left_a <- setdiff(a$cha_row, exact$cha_row)
    left_b <- setdiff(b$row_no, exact$row_no)
    if (length(left_a) > 1)
      stop("tie not resolved by name or elimination: ", k)
    dplyr::bind_rows(
      exact %>% dplyr::transmute(cha_row, row_no,
                                 match_method = "PROGRAMME_AMOUNT_NAME"),
      tibble::tibble(cha_row = left_a, row_no = left_b,
                     match_method = rep("PROGRAMME_AMOUNT_ELIMINATION",
                                        length(left_a))))
  })
  if (anyDuplicated(out$row_no) || nrow(out) != nrow(ours) ||
      nrow(out) != nrow(cha))
    stop("the CHA <-> ours match is not 1:1")
  out %>%
    dplyr::left_join(cha %>% dplyr::select(cha_row, award_pool, amount,
                                           cha_name = hospital, cha_call,
                                           cha_cah, cha_state_rural,
                                           cha_note = notes), by = "cha_row") %>%
    dplyr::left_join(ours %>% dplyr::select(row_no, our_awardee = awardee,
                                            our_call = summary_hospital_call,
                                            our_cah, ccn), by = "row_no") %>%
    dplyr::mutate(name_differs = cha_norm(cha_name) != cha_norm(our_awardee)) %>%
    dplyr::arrange(row_no)
}

cha_reconciliation <- function(m = cha_match(), s = cha_summary()) {
  val <- function(l) s$value[s$label == l]
  money <- function(v) round(sum(v), 2)

  call_diff <- m %>% dplyr::filter(cha_call != our_call)
  cah_diff  <- m %>% dplyr::filter(cha_cah != our_cah)

  row_lines <- function(d, kind, ours_col, cha_col) {
    d %>% dplyr::transmute(
      record_type = kind, measure = NA_character_,
      cha_row, our_row_no = row_no, award_pool, cha_name, our_awardee,
      ccn, amount, ours_value = .data[[ours_col]], cha_value = .data[[cha_col]],
      ours_usd = NA_real_, cha_usd = NA_real_, gap_usd = NA_real_,
      gap_rows = NA_character_, comparable = NA_character_,
      note = dplyr::coalesce(cha_note, ""))
  }
  rows <- dplyr::bind_rows(
    row_lines(call_diff, "ROW_CALL_DIFFERS", "our_call", "cha_call"),
    row_lines(cah_diff %>% dplyr::mutate(
                our_cah = dplyr::if_else(our_cah, "CAH", "NOT_CAH"),
                cha_cah = dplyr::if_else(cha_cah, "CAH", "NOT_CAH")),
              "ROW_CAH_DIFFERS", "our_cah", "cha_cah"))

  total_line <- function(measure, ours, cha, gap_d, comparable, note) {
    tibble::tibble(
      record_type = "TOTAL", measure = measure,
      ours_usd = ours, cha_usd = cha,
      gap_usd = if (is.na(ours)) NA_real_ else round(cha - ours, 2),
      gap_rows = if (is.null(gap_d)) NA_character_ else
        paste0(gap_d$cha_name, " (", sprintf("%.2f", gap_d$amount), ")",
               collapse = "; "),
      comparable = comparable, note = note)
  }
  rural_cha <- money(m$amount[m$cha_call == "HOSPITAL" &
                                 m$cha_state_rural %in% "Yes"])
  if (!isTRUE(all.equal(rural_cha, val("Rural Hospital"))))
    stop("CHA's Rural Hospital figure no longer reproduces from its own lines")
  hosp_ours <- money(m$amount[m$our_call == "HOSPITAL"])
  cah_ours  <- money(m$amount[m$our_cah])
  totals <- dplyr::bind_rows(
    total_line("all_lines", money(m$amount), val("Total"), NULL, "YES",
               "Both readers hold the same 108 lines."),
    total_line("hospital", hosp_ours, val("Any Hospital-Based"), call_diff,
               "YES", paste("Ours: summary_hospital_call = HOSPITAL. CHA:",
                            "'Any Hospital-Based' (Non-hospital = 0).")),
    total_line("non_hospital", money(m$amount[m$our_call == "NOT_HOSPITAL"]),
               val("Non-Hospital Based"), call_diff, "YES",
               "The mirror of the hospital line; the same rows make the gap."),
    total_line("cah", cah_ours, val("CAH Hospital"), cah_diff, "YES",
               paste("Ours: HOSPITAL rows with a CCN 13xx on the row",
                     "(R/08 strict_cah_usd). CHA: its CAH column.")),
    total_line("rural_hospital", NA_real_, val("Rural Hospital"), NULL, "NO",
               paste("CHA's 'Rural Hospital' uses California's STATE rural",
                     "designation (its State Rural column), not the CMS CAH",
                     "cut. This project holds no California state rural",
                     "designation for these rows (rural_designation is empty",
                     "on all 108), so there is no figure of ours to compare.",
                     "CHA's figure reproduces to the cent as the sum of its",
                     "Non-hospital = 0 lines with State Rural = Yes; it",
                     "includes non-CAH hospitals (e.g. Adventist Health",
                     "Sonora, Sutter Coast) and Community Health Partners.")))
  dplyr::bind_rows(rows, totals) %>%
    dplyr::mutate(amount = round(amount, 2))
}

cha_build <- function() {
  r <- cha_reconciliation()
  readr::write_csv(r, CHA_RECON_CSV, na = "")
  message("wrote ", CHA_RECON_CSV, " (", nrow(r), " rows)")
  invisible(r)
}

cha_report <- function() {
  m <- cha_match()
  r <- cha_reconciliation(m)
  cat("Matched:", nrow(m), "lines;",
      sum(m$match_method != "PROGRAMME_AMOUNT"), "inside a tie;",
      sum(m$name_differs), "with a different name string\n\n")
  print(as.data.frame(r %>% dplyr::filter(record_type != "TOTAL") %>%
    dplyr::select(record_type, cha_name, amount, ours_value, cha_value)))
  cat("\n")
  print(as.data.frame(r %>% dplyr::filter(record_type == "TOTAL") %>%
    dplyr::select(measure, ours_usd, cha_usd, gap_usd, comparable)))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) cha_build()
  if ("--report" %in% args || length(args) == 0) cha_report()
}

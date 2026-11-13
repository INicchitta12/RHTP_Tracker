# R/08b_completed_states_table.R -- the COMPLETED-STATES table (session 117a).
#
# One row per state whose year1_completion_status.csv row is COMPLETE, plus a
# total row. Every figure is read from a committed year1_summary_<date>.csv
# (R/08's output); nothing here recomputes or re-codes anything. The phrase in
# "What complete means here" is a short quotation from the state's cited
# source (COMPLETE_MEANS below); a COMPLETE state missing from it stops the
# build, so a newly completed state cannot ship without its phrase.
#
# Usage:
#   Rscript R/08b_completed_states_table.R --build [summary_date] [out_date]
#     writes output/completed_states_<out_date>.xlsx and .html
#     (summary_date defaults to the newest year1_summary_<date>.csv)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(stringr)
})

# One phrase per COMPLETE state, from the evidence cited in
# data/reference/year1_completion_status.csv.
COMPLETE_MEANS <- tibble::tribble(
  ~state, ~complete_means, ~statement_date,
  "AL", "Grants 'round out year one of funding' (Governor); CMS: 'completes Alabama's initial Year 1 award cycle'", "2026-10-01",
  "AR", "Round 2 'completes the distribution of the $208 million awarded to Arkansas this year' (Governor)", "2026-09-24",
  "FL", "'AHCA has awarded the full scope of Florida's RHTP funding' (Governor)", "2026-08-11",
  "GA", "Phase 4 'complete[s] the initial Year 1 award cycle' (DCH; CMS the same)", "2026-08-27",
  "ID", "State 'completed the awards for $186 million in Year 1 grant funding' (Governor)", "2026-10-28",
  "UT", "'Utah has successfully demonstrated obligation for 100% of its Year 1 RHTP funding' (DHHS)", "2026-10-29",
  "VT", "'Vermont has fully obligated its approximately $195 million Year 1 RHT award' (AHS)", "2026-10-30",
  "WY", "'funding allocations, competitive applications, and awards have been completed for Year 1' (WDH)", "2026-10-23",
  # Session 117a: newly COMPLETE on a state-source full-obligation statement.
  "NE", "Year 1 '$218.5 million ... has been fully obligated to implement all seven initiatives' (DHHS)", "2026-11-10",
  "SD", "'South Dakota committed every dollar of its $189.5 million ... award by the federal deadline' (Governor/DOH)", "2026-11-10",
  "WV", "'obligated 100 percent of its initial award through 145 signed awards and agreements' (Governor/DH)", "2026-11-09"
)

# Newly COMPLETE in session 117a, for the notes.
NEW_COMPLETE_117A <- c(
  NE = "Nebraska (DHHS Year 2 release, 2026-11-10: 'fully obligated'; data/evidence/recheck/2026-11-13/NE/)",
  SD = "South Dakota (Governor/DOH Year 2 release KB0047476, 2026-11-10: 'committed every dollar'; data/evidence/recheck/2026-11-13/SD/)",
  WV = "West Virginia (Governor/DH Year 2 release, 2026-11-09: 'obligated 100 percent'; data/evidence/recheck/2026-11-13/WV/)")

cs_latest_summary_date <- function() {
  f <- list.files(here::here("data", "reference"), pattern = "^year1_summary_\\d{4}-\\d{2}-\\d{2}\\.csv$")
  max(stringr::str_extract(f, "\\d{4}-\\d{2}-\\d{2}"))
}

cs_build <- function(summary_date = cs_latest_summary_date()) {
  s <- readr::read_csv(here::here("data", "reference", paste0("year1_summary_", summary_date, ".csv")),
                       show_col_types = FALSE)
  st <- readr::read_csv(here::here("data", "reference", "year1_completion_status.csv"),
                        show_col_types = FALSE) %>%
    dplyr::filter(year1_status == "COMPLETE")
  missing_phrase <- setdiff(st$state, COMPLETE_MEANS$state)
  if (length(missing_phrase)) stop("COMPLETE state(s) with no phrase in COMPLETE_MEANS: ",
                                   paste(missing_phrase, collapse = ", "))
  d <- s %>%
    dplyr::filter(state %in% st$state) %>%
    dplyr::left_join(COMPLETE_MEANS, by = "state")
  if (nrow(d) != nrow(st)) stop("summary ", summary_date, " lacks a COMPLETE state")
  if (any(d$completion_status != "COMPLETE"))
    stop("summary ", summary_date, " does not call every COMPLETE state COMPLETE: ",
         paste(d$state[d$completion_status != "COMPLETE"], collapse = ", "), " -- rebuild R/08 first")
  frac <- function(n, dd) ifelse(dd > 0, n / dd, NA_real_)
  tab <- d %>%
    dplyr::arrange(state_name) %>%
    dplyr::transmute(
      State = state_name,
      `What "complete" means here` = complete_means,
      `FY2026 allotment` = allotment_usd,
      `Awards published` = award_total_usd,
      `Awards % of allotment` = frac(award_total_usd, allotment_usd),
      `Hospital $ (best estimate)` = hospital_summary_usd,
      `Hospital % of awards` = frac(hospital_summary_usd, award_total_usd),
      `Hospital % of allotment` = frac(hospital_summary_usd, allotment_usd),
      `Strict named-hospital $` = strict_named_hospital_usd,
      `Share of hospital $ that is intents` = frac(layer_intent_usd, hospital_summary_usd),
      intent_usd = layer_intent_usd
    )
  tot <- tibble::tibble(
    State = paste0("Total (", nrow(tab), " states)"),
    `What "complete" means here` = "",
    `FY2026 allotment` = sum(tab$`FY2026 allotment`),
    `Awards published` = sum(tab$`Awards published`),
    `Hospital $ (best estimate)` = sum(tab$`Hospital $ (best estimate)`),
    `Strict named-hospital $` = sum(tab$`Strict named-hospital $`),
    intent_usd = sum(tab$intent_usd)
  ) %>%
    dplyr::mutate(
      `Awards % of allotment` = frac(`Awards published`, `FY2026 allotment`),
      `Hospital % of awards` = frac(`Hospital $ (best estimate)`, `Awards published`),
      `Hospital % of allotment` = frac(`Hospital $ (best estimate)`, `FY2026 allotment`),
      `Share of hospital $ that is intents` = frac(intent_usd, `Hospital $ (best estimate)`)
    )
  out <- dplyr::bind_rows(tab, tot[, names(tab)])
  attr(out, "summary_date") <- summary_date
  attr(out, "sources") <- d %>% dplyr::select(state, state_name, statement_date) %>%
    dplyr::left_join(st %>% dplyr::select(state, evidence_path), by = "state")
  out
}

cs_notes <- function(tab, new_states = character(0), new_sources = character(0)) {
  sd <- attr(tab, "summary_date")
  tot <- tab[nrow(tab), ]
  usd <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  c(
    paste0("Data date: ", sd, " (year1_summary_", sd, ".csv, built by R/08 from the committed award files; ",
           "completion status from year1_completion_status.csv). Year 1 = Budget Period 1 only; Year 2 is not included."),
    paste0("A state is COMPLETE only where a state source (or CMS) says Year 1 awarding is complete or Year 1 funds are fully obligated, and no Year 1 remainder is known; the phrase column quotes it. ",
           "'Fully obligated' or 'committed' (", paste(intersect(c("NE", "SD", "UT", "VT", "WV"), attr(tab, "sources")$state), collapse = ", "),
           ") says the money is committed, not that every award is published: those award lists are FLOORS, and where awards published are well below the allotment ",
           "(Nebraska, South Dakota, West Virginia) the hospital % of awards describes the published awards only, not the state's whole Year 1."),
    paste0("Hospital $ (best estimate) includes judgment calls on rows whose source does not settle whether a hospital receives the money (and UT's $9,891,739 Utah Hospital Association pool). ",
           "Strict named-hospital $ does not: it counts only awards to a named hospital, coded from the source. Total best estimate ", usd(tot$`Hospital $ (best estimate)`),
           "; strict ", usd(tot$`Strict named-hospital $`), "."),
    paste0("Intents are notices of intent to award, not signed agreements, and may change before execution. ",
           usd(tot$intent_usd), " of the best estimate (", sprintf("%.1f%%", 100 * tot$`Share of hospital $ that is intents`),
           ") is intents, in ", paste(tab$State[-nrow(tab)][tab$intent_usd[-nrow(tab)] > 0], collapse = ", "),
           " (Wyoming's are advisory-committee approvals)."),
    "Awards published is the sum of published per-award amounts plus pool-level amounts the state published without a per-recipient split (Georgia $106.4M, Wyoming $267,000). It falls short of the allotment by state administration and by awards made but not itemised.",
    "Figures are not comparable as hospital 'shares of need': states differ in how much of Year 1 went to hospitals by design (e.g. Utah and Florida routed most money to non-hospital and capital programmes).",
    if (length(new_states)) paste0("Newly COMPLETE this session: ", paste(new_sources, collapse = "; "), ".")
    else "No state was newly set COMPLETE in this build."
  )
}

cs_write_xlsx <- function(tab, notes, path) {
  wb <- openxlsx::createWorkbook()
  openxlsx::modifyBaseFont(wb, fontSize = 11, fontName = "Calibri")
  openxlsx::addWorksheet(wb, "Completed states")
  out <- tab %>% dplyr::select(-intent_usd)
  hdr <- openxlsx::createStyle(textDecoration = "bold", wrapText = TRUE, border = "TopBottomLeftRight",
                               fgFill = "#D9E1F2", valign = "top")
  openxlsx::writeData(wb, 1, out, headerStyle = hdr, borders = "all")
  n <- nrow(out)
  usd_cols <- which(names(out) %in% c("FY2026 allotment", "Awards published", "Hospital $ (best estimate)", "Strict named-hospital $"))
  pct_cols <- which(grepl("%|Share", names(out)))
  openxlsx::addStyle(wb, 1, openxlsx::createStyle(numFmt = "$#,##0"), rows = 2:(n + 1), cols = usd_cols, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb, 1, openxlsx::createStyle(numFmt = "0.0%"), rows = 2:(n + 1), cols = pct_cols, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb, 1, openxlsx::createStyle(wrapText = TRUE, valign = "top"), rows = 2:(n + 1), cols = 2, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb, 1, openxlsx::createStyle(textDecoration = "bold"), rows = n + 1, cols = seq_along(out), gridExpand = TRUE, stack = TRUE)
  openxlsx::setColWidths(wb, 1, cols = seq_along(out), widths = c(16, 60, rep(16, ncol(out) - 2)))
  openxlsx::freezePane(wb, 1, firstRow = TRUE)
  openxlsx::writeData(wb, 1, "Notes", startRow = n + 3)
  openxlsx::addStyle(wb, 1, openxlsx::createStyle(textDecoration = "bold"), rows = n + 3, cols = 1)
  openxlsx::writeData(wb, 1, paste0(seq_along(notes), ". ", notes), startRow = n + 4)
  src <- attr(tab, "sources")
  openxlsx::addWorksheet(wb, "Sources")
  openxlsx::writeData(wb, 2, src %>% dplyr::rename(State = state_name, `Statement date` = statement_date,
                                                   `Archived source (repo path)` = evidence_path) %>%
                        dplyr::select(-state), headerStyle = hdr)
  openxlsx::setColWidths(wb, 2, cols = 1:3, widths = c(16, 16, 120))
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
}

cs_write_html <- function(tab, notes, path) {
  esc <- function(x) x %>% stringr::str_replace_all("&", "&amp;") %>% stringr::str_replace_all("<", "&lt;") %>%
    stringr::str_replace_all(">", "&gt;")
  usd <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  pct <- function(x) ifelse(is.na(x), "", sprintf("%.1f%%", 100 * x))
  out <- tab %>% dplyr::select(-intent_usd)
  cell <- "border:1px solid #000000;padding:3px 6px;font-family:Calibri,sans-serif;font-size:11pt;vertical-align:top;"
  fmt_row <- function(i) {
    r <- out[i, ]
    vals <- c(esc(r$State), esc(r$`What "complete" means here`),
              usd(r$`FY2026 allotment`), usd(r$`Awards published`), pct(r$`Awards % of allotment`),
              usd(r$`Hospital $ (best estimate)`), pct(r$`Hospital % of awards`), pct(r$`Hospital % of allotment`),
              usd(r$`Strict named-hospital $`), pct(r$`Share of hospital $ that is intents`))
    align <- c("left", "left", rep("right", 8))
    bold <- if (i == nrow(out)) "font-weight:bold;" else ""
    paste0("<tr>", paste0("<td style=\"", cell, "text-align:", align, ";", bold, "\">", vals, "</td>", collapse = ""), "</tr>")
  }
  head <- paste0("<tr>", paste0("<th style=\"", cell, "font-weight:bold;background:#D9E1F2;text-align:left;\">",
                                esc(names(out)), "</th>", collapse = ""), "</tr>")
  body <- vapply(seq_len(nrow(out)), fmt_row, character(1))
  p <- "font-family:Calibri,sans-serif;font-size:11pt;margin:4px 0;"
  html <- c(
    "<!DOCTYPE html>", "<html><head><meta charset=\"utf-8\"><title>RHTP Year 1 completed states</title></head>",
    "<body style=\"font-family:Calibri,sans-serif;font-size:11pt;\">",
    paste0("<p style=\"", p, "font-weight:bold;\">RHTP Year 1: states that have completed Year 1 awarding (data as of ",
           attr(tab, "summary_date"), ")</p>"),
    "<table style=\"border-collapse:collapse;border:1px solid #000000;\">", head, body, "</table>",
    paste0("<p style=\"", p, "font-weight:bold;margin-top:10px;\">Notes</p>"),
    paste0("<p style=\"", p, "\">", seq_along(notes), ". ", esc(notes), "</p>"),
    "</body></html>"
  )
  writeLines(html, path, useBytes = TRUE)
}

cs_write <- function(summary_date = cs_latest_summary_date(), out_date = format(Sys.Date(), "%Y-%m-%d"),
                     new_states = names(NEW_COMPLETE_117A), new_sources = unname(NEW_COMPLETE_117A)) {
  tab <- cs_build(summary_date)
  notes <- cs_notes(tab, new_states, new_sources)
  x <- here::here("output", paste0("completed_states_", out_date, ".xlsx"))
  h <- here::here("output", paste0("completed_states_", out_date, ".html"))
  cs_write_xlsx(tab, notes, x)
  cs_write_html(tab, notes, h)
  message("wrote ", x, " and ", h, " from year1_summary_", summary_date)
  invisible(tab)
}

if (sys.nframe() == 0) {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) && a[1] == "--build") {
    sd <- if (length(a) >= 2) a[2] else cs_latest_summary_date()
    od <- if (length(a) >= 3) a[3] else format(Sys.Date(), "%Y-%m-%d")
    t <- cs_write(sd, od)
    print(as.data.frame(t %>% dplyr::select(-2)), digits = 12)
  } else {
    cat("Usage: Rscript R/08b_completed_states_table.R --build [summary_date] [out_date]\n")
  }
}

#!/usr/bin/env Rscript
# 03bb_va_year1_probe.R ------------------------------------------------------
#
# VIRGINIA -- A WATCH, NOT AN EXTRACTION (session 59). The Governor's $122M
# (2026-08-28) went to eleven named FIRST-TIER partners with no per-partner
# amount, none a hospital, who re-grant competitively (session 55, §4). The
# subrecipient rosters -- where hospitals would appear -- are due on dates the
# administrators published themselves:
#
#   VHCF: "VHCF anticipates sharing a Notice of Awards by September 30, 2026,
#          for Provider Interoperability and October 14, 2026, for Provider
#          Productivity."
#   VHHA Foundation (Remote Patient Monitoring, GME, Food is Medicine):
#          "Awards announced by October 30, 2026"
#
# TWICE-WEEKLY, because those are published dates and the first is a week out.
# Both administrators are §7's designated pass-through route (Illinois/ICAHN):
# DMAS is the primary recipient and "VHCF is a subrecipient of DMAS".
#
# THE WATCH, READ-ONLY (§2.2):
#   * VHCF's Rural Health page     -- name-diffed; the dated sentence is required
#   * VHHA Foundation's RHT page   -- name-diffed; its award date is required
#   * the RHT site's Ways to Apply -- name-diffed (it lists each RFA's
#     administrator and status)
#   * the RHT site's News & Updates -- too thin to name-diff (two names), so a
#     NEW sentence speaking of awards trips instead.
#
# THE RHT SITE SERVES AN INCOMPLETE CERTIFICATE CHAIN. ruralhealthtransformation-
# va.virginia.gov sends its leaf without the DigiCert intermediate. The fix is
# the browser's: the intermediate (config/certs/, with its provenance) is added
# to the normal CA bundle. VERIFICATION IS NEVER SWITCHED OFF.
#
# VHCF's page loads a Google Maps key in a script (session 55 did not save it
# for that reason). `--fetch` archives it through rhtp_watch_archive(), which
# strips script bodies and refuses to write a credential-shaped string.
#
# Usage: Rscript R/03bb_va_year1_probe.R --fetch | --validate | --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

VA_STATE <- "VA"
VA_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
VA_RECHECK <- file.path("data", "evidence", "recheck", "2026-09-23", "VA")
VA_DIR <- file.path("data", "evidence", "VA")
VA_RHT <- "https://ruralhealthtransformationva.virginia.gov"
VA_INTERMEDIATE <- here::here("config", "certs",
                              "digicert_global_g2_tls_rsa_sha256_2020_ca1.pem")

VA_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "vhcf", "https://www.vhcf.org/rural-health/",
  file.path(VA_DIR, "2026-09-23_vhcf_rural_health.html"), TRUE,
  "vhha_foundation", "https://vhhafoundation.org/virginia-rural-health-transformation/",
  file.path(VA_RECHECK, "vhha_foundation_rht.html"), TRUE,
  "ways_to_apply", paste0(VA_RHT, "/ways-to-apply/"),
  file.path(VA_RECHECK, "rhtva_ways_to_apply.html"), TRUE,
  "news", paste0(VA_RHT, "/news--updates/"),
  file.path(VA_RECHECK, "rhtva_news_updates.html"), FALSE)

VA_ANCHORS <- list(
  vhcf = paste("VHCF anticipates sharing a Notice of Awards by September 30,",
               "2026, for Provider Interoperability and October 14, 2026, for",
               "Provider Productivity."),
  vhha_foundation = "Awards announced by October 30, 2026")
VA_AWARD_WORDS <- "\\baward(s|ed|ee|ees)?\\b|\\brecipients?\\b|\\bselected\\b|\\bgrantees?\\b"

#' The normal CA bundle plus the one missing intermediate, in a temp file
va_cainfo <- function() {
  base <- Sys.getenv("CURL_CA_BUNDLE", Sys.getenv("SSL_CERT_FILE",
                     "/etc/ssl/certs/ca-certificates.crt"))
  if (!file.exists(base)) base <- "/etc/ssl/certs/ca-certificates.crt"
  out <- tempfile(fileext = ".pem")
  writeLines(c(readLines(base, warn = FALSE),
               readLines(VA_INTERMEDIATE, warn = FALSE)), out)
  out
}

va_assert_watch <- function(live, arch) {
  for (k in names(VA_ANCHORS)) {
    rhtp_watch_require(live[[k]], VA_ANCHORS[[k]], VA_STATE, k)
  }
  rhtp_watch_forbid_new(live$news, arch$news, VA_AWARD_WORDS, VA_STATE, "news",
    "Virginia's RHT site announcing awards. Read it and extract what it names.")
  for (k in c("vhcf", "vhha_foundation")) {
    rhtp_watch_forbid_new(live[[k]], arch[[k]],
      "Notice of Awards? (is|are|has been) (now )?(available|posted|issued)|\\bawardees\\b|\\bawarded to\\b",
      VA_STATE, k,
      "A designated pass-through administrator announcing its subrecipients.")
  }
  invisible(TRUE)
}

va_fetch <- function() {
  rhtp_watch_archive(VA_PAGES$url[1], VA_PAGES$file[1], VA_AGENT)
  message("[VA] archived the VHCF baseline (scripts stripped).")
}

va_validate <- function() {
  arch <- lapply(stats::setNames(VA_PAGES$file, VA_PAGES$key),
                 function(f) rhtp_watch_reduce(here::here(f)))
  va_assert_watch(arch, arch)
  message("[VA] the archive carries both administrators' award dates and no ",
          "award sentence.")
  invisible(TRUE)
}

# THE WAYS-TO-APPLY TABLE IS READ AS A TABLE (session 74). Its rows are
# Initiative | Sub-Initiative | Key Implementation Partner | RFA Status, and the
# reduction flattens them into one run of capitalised words, so every change of
# a STATUS cell ('Closed (August 31st 2026)' -> 'Closed', 'TBD' -> 'Open')
# re-welds the run and reads as new organisations -- the 2026-09-25 halts. Read
# on 2026-09-28, the partner column names the same ten bodies as the
# 2026-09-23 archive: nine of va_year1_awardees.csv's eleven first-tier partners
# plus 'Commonwealth of VA' (the state itself, on Mobile & Hybrid Care). So the
# table's partner column is diffed as a set: a partner absent from the archived table
# fails, whatever its status says. The prose above the table names only two
# organisations, below the name tripwire's baseline floor (§2.3), so the
# partner set IS this page's name diff.

va_wta_partners <- function(raw) {
  h <- xml2::read_html(raw)
  tb <- rvest::html_table(rvest::html_elements(h, "table"))
  tb <- Filter(function(t) any(grepl("Implementation Partner", names(t))), tb)
  if (length(tb) != 1L) {
    stop("[VA] ways_to_apply: expected ONE partner table; found ", length(tb),
         ". The page's shape changed -- read it.", call. = FALSE)
  }
  col <- grep("Implementation Partner", names(tb[[1]]), value = TRUE)
  sort(unique(stringr::str_squish(tb[[1]][[col]])))
}

va_assert_wta_partners <- function(live_raw, arch_raw) {
  new <- setdiff(va_wta_partners(live_raw), va_wta_partners(arch_raw))
  if (length(new)) {
    stop("[VA] 'ways_to_apply' NAMES A NEW IMPLEMENTATION PARTNER: ",
         paste(sQuote(new), collapse = ", "), ". THAT IS THE SIGNAL, NOT A ",
         "DEFECT. Check it against va_year1_awardees.csv's first-tier ",
         "partners and read the RFA it administers.", call. = FALSE)
  }
  invisible(TRUE)
}

va_probe <- function() {
  w <- rhtp_watch_pages(VA_PAGES, VA_AGENT, cainfo = va_cainfo())
  va_assert_watch(w$live_all, w$arch_all)
  arch_raw <- paste(readLines(here::here(VA_PAGES$file[VA_PAGES$key == "ways_to_apply"]),
                              warn = FALSE), collapse = "\n")
  va_assert_wta_partners(w$raw$ways_to_apply, arch_raw)
  # The prose above the table names only two organisations -- below the
  # name tripwire's baseline floor -- so the page's name diff IS the partner
  # set above; the other two pages keep the ordinary name tripwire.
  keep <- setdiff(names(w$live), "ways_to_apply")
  rhtp_assert_no_new_organisations_across(live = w$live[keep],
                                          archived = w$arch[keep],
                                          state = VA_STATE)
  message("[VA] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no subrecipient roster.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) va_fetch()
  if ("--validate" %in% args) va_validate()
  if ("--probe" %in% args) rhtp_probe_run("VA", va_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}

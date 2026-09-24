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

va_probe <- function() {
  w <- rhtp_watch_pages(VA_PAGES, VA_AGENT, cainfo = va_cainfo())
  va_assert_watch(w$live_all, w$arch_all)
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
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

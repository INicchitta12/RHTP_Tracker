# 03cy_ma_rhtp_probe.R -- Massachusetts: a WATCH off mass.gov (session 124)
#
# Every mass.gov path is Akamai-403 to this environment on four agents, so
# Massachusetts's own RHTP pages (EOHHS's hub, key dates, newsletters) cannot
# be read from here. Session 124 tried every other route (docs/session124_*):
#   - mehi.masstech.org and masscybercenter.org READ, with the honest agent. The
#     Massachusetts eHealth Institute and the MassCyberCenter run four RHTP
#     programmes (Rural Digital Health Sandbox, NOFO 2027-MeHI-02; Rural
#     SHINE-HT, NOFO 2027-MeHI-03; the Rural HIE programme, "Notice of Funding
#     Opportunity coming soon"; Rural Health Cybersecurity, NOFO 2027-Cyber-01).
#     Their NOFOs are numbered 2027 and open now: Tier 2, likely Year 2. No
#     page names an awardee. MeHI's footer prints "$162,005,238.13 with 100
#     percent funded by CMS/HHS": the FY2026 allotment (Tier 1).
#   - COMMBUYS is a JSF form (UNKNOWN, not "no bids"); Wayback snapshots exist
#     but cannot be fetched (egress 403 / TLS reset); USAspending carries no MA
#     subaward (0 FFATA filings).
# So this probe watches the four readable SUBJECT pages for the day one of
# them names a recipient. The NAME tripwire (§2.3) is the main signal; a phrase
# check catches "awardees"/"selected" with nobody named. extraction_status
# stays INVESTIGATED_NO_PROBE until this has a Routine on its own runner.

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

MA_STATE <- "MA"
MA_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
MA_DIR <- file.path("data", "evidence", "MA", "probe")
MA_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  "mehi_rhtp", "https://mehi.masstech.org/rural-health-transformation-program-rhtp",
  file.path(MA_DIR, "2026-11-25_mehi_rhtp.html"), TRUE,
  "mehi_sandbox", "https://mehi.masstech.org/rural-digital-health-sandbox",
  file.path(MA_DIR, "2026-11-25_mehi_sandbox.html"), TRUE,
  "mehi_shine", "https://mehi.masstech.org/SHINE-HT",
  file.path(MA_DIR, "2026-11-25_mehi_shine_ht.html"), TRUE,
  "mehi_hie", "https://mehi.masstech.org/rural-health-information-exchange-program",
  file.path(MA_DIR, "2026-11-25_mehi_rural_hie.html"), TRUE,
  "cyber", "https://masscybercenter.org/rural-health-cybersecurity-grant-program",
  file.path(MA_DIR, "2026-11-25_masscyber_rural_cyber.html"), TRUE)

# A NEW sentence carrying one of these is the signal even when nobody is named.
MA_AWARD_WORDS <- paste0("(?i)\\bawardees?\\b|\\bawarded\\b|\\bgrantees?\\b|\\brecipients? (of|were|are)\\b|",
                         "\\bselected\\b|\\bnotice of award\\b")

ma_fetch <- function() {
  for (i in seq_len(nrow(MA_PAGES))) {
    rhtp_watch_archive(MA_PAGES$url[i], MA_PAGES$file[i], MA_AGENT)
  }
  message("[MA] archived ", nrow(MA_PAGES), " baselines under ", MA_DIR)
}

ma_validate <- function() {
  w <- lapply(MA_PAGES$file, function(f) rhtp_watch_reduce(here::here(f)))
  names(w) <- MA_PAGES$key
  if (!stringr::str_detect(w$mehi_rhtp, stringr::fixed("Rural Health Transformation"))) {
    stop("[MA] the archived MeHI hub no longer reads as the RHTP page.", call. = FALSE)
  }
  if (any(nchar(unlist(w)) < 500)) stop("[MA] an archived baseline reduces to almost nothing.", call. = FALSE)
  message("[MA] ", length(w), " baselines read.")
  invisible(w)
}

ma_probe <- function() {
  w <- rhtp_watch_pages(MA_PAGES, MA_AGENT)
  for (k in MA_PAGES$key) {
    rhtp_watch_forbid_new(w$live_all[[k]], w$arch_all[[k]], MA_AWARD_WORDS, MA_STATE, k,
      paste("A Massachusetts RHTP programme page has a new sentence about awards.",
            "Read it: extract what it names, or record it here with its sentence."))
  }
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch, state = MA_STATE)
  message("[MA] ", paste0(w$changed$key, ": ", ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "), " -- no new award sentence, no new organisation.")
  invisible(w$changed)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ma_fetch()
  if ("--validate" %in% args) ma_validate()
  if ("--probe" %in% args) rhtp_probe_run("MA", ma_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}

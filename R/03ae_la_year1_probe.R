# 03ae_la_year1_probe.R --------------------------------------------------------
# LOUISIANA, YEAR 1 -- A NEGATIVE, AND THE ONE WHOSE ANNOUNCEMENT WINDOWS HAVE
# ALL CLOSED AT ONCE.
#
# Louisiana led the RCJ_ONLY queue at 6 Tier 3 candidates / 6 distinct awardees
# / $53,910,000, with no CMS press release and a $208,374,448 allotment. It has
# published NO recipient-level RHTP award list.
#
# WHAT IT HAS PUBLISHED IS SEVEN SOLICITATIONS AND SEVEN ANNOUNCEMENT DATES.
# LDH's RHTP page carries an "IMPORTANT DATES - BUDGET YEAR 1" block giving,
# for every one of the seven Budget Year 1 strategic funding opportunities,
# both an application deadline AND a "Notice of Intent to Contract
# Announcements" window:
#
#     Late July to mid August   x3   (Clinician Credit Bank, Telehealth, Capital)
#     Mid to late August        x4   (Collaborative Provider, APM, Care
#                                     Conveners, Food is Medicine)
#
# THIS RAN 2026-09-02, SO ALL SEVEN WINDOWS HAVE CLOSED. Connecticut (session
# 35) was the first negative in this project whose award date had passed, with
# ONE solicitation sixteen days overdue. Louisiana has SEVEN, and the state
# published the dates itself.
#
# THE ADVISORY COUNCIL DECK IS SHARPER STILL, AND IT IS RCJ'S SOURCE. Slide 18
# of the 2026-08-20 deck is a table headed "RHTP Funding Cycle Budget Year 1"
# with four columns -- Activity | # Applications Received | Projected BY 1
# Funding | Anticipated Announcement:
#
#     Rural Clinician Credit Bank          136    $10 million     Mid August
#     Capital Improvement Program          160    $41.60 million  Late August
#     Telehealth                            79    $4.71 million   Late August
#     Collaborative Provider Model          37    $3 million      Early September
#     Alternative Payment Model             31    $30 million     Early September
#     Care conveners / navigation network   25    $3.5 million    Mid September
#     Food is Medicine                      37    $2.7 million    Mid September
#
# 505 APPLICATIONS RECEIVED, NOT ONE AWARD NAMED. That is §0.3 in the state's
# own table: applications received is not awards made.
#
# §0.1 -- OKLAHOMA'S TIER DEFECT, WITH THE STATE'S OWN COLUMN HEADING REFUTING
# IT. All six of RCJ's Louisiana Tier 3 candidates are rows of that table. The
# "awardee" is the ACTIVITY column -- "Alternative Payment Model", "Care
# conveners / navigation network", "Food is Medicine", "Telehealth", "Rural
# Clinician Credit Bank", "Collaborative Provider Model" -- which are fund uses
# and not organisations at all, so this is §6.1's PROGRAM_NAME_AS_AWARDEE on
# SIX OF SIX, and `named_recipient_test` reads PASS on every one. The amount is
# the "PROJECTED BY 1 FUNDING" column, multiplied by a million. Oklahoma's
# Legislative Quarterly Reports defined the column they were mined from
# ("Y1 Budget Allocation: The amount of funds dedicated to the program");
# Louisiana's deck says PROJECTED in the heading.
#
# AND IT DROPS THE LARGEST ROW, WHICH IS THE ONE MOST LIKELY TO REACH A
# HOSPITAL. The Capital Improvement Program -- 160 applications, $41.60
# million, awards of $100,000-$10,000,000 for facility renovation, medical
# equipment and technology infrastructure -- is not among RCJ's six. Its six
# sum to $53,910,000 against the deck's own seven at $95,510,000, so the
# aggregator UNDERSTATES the table it mined by $41,600,000. Michigan deflated
# by carrying one row per organisation; Louisiana deflates by dropping a row.
#
# THE CAPITAL NOFO'S ELIGIBLE CLASS IS HOSPITALS AMONG OTHERS: "Rural Health
# Clinics (RHCs), Federally Qualified Health Centers (FQHCs) or look-alikes,
# Critical Access Hospitals (CAHs), Rural hospitals, Rural EMS providers, Rural
# behavioral health or substance use providers, Independent rural practices".
# New Hampshire's FHC class, NOT Illinois's ICAHN class, so §0.3 governs it
# either way and it is a PASS_THROUGH_* question when it lands.
#
# THE HOST WANTS A Mozilla/5.0 PREFIX, AND THAT IS NOT MICHIGAN'S EXCEPTION.
# ldh.la.gov answers the project's own agent 403 AND bare "Mozilla/5.0" 403,
# while the RFC well-behaved-crawler convention -- "Mozilla/5.0 (compatible;
# AHA-RHTP-Tracker/0.1; +https://www.aha.org)" -- answers 200. That form
# carries our name and our contact URL, so it is session 10's medicaid.gov
# answer and not session 27's michigan.gov exception: IDENTIFYING HONESTLY IS
# STILL THE FIX, and the only thing this host additionally requires is the
# prefix. `robots.txt` is 404 -- genuinely absent, where Michigan's was 403 --
# so no crawler policy exists and none is being declined.
#
# THE SEVENTH DIGEST MECHANISM, AND THE SECOND THAT IS ATTRIBUTE-BORNE.
# ldh.la.gov runs Cloudflare Email Address Obfuscation, which XOR-encodes a
# mailto with a RANDOM ONE-BYTE KEY on every render, into an href and a
# `data-cfemail` attribute. Three fetches gave THREE distinct file digests at
# EXACTLY 169,500 bytes each -- California's antispambot() finding on a
# different platform, and constant-length like California's, so a byte-count
# check passes it. Because it lives in ATTRIBUTES rather than a script body it
# is Connecticut's `?v=` stamp structurally, and the reduction absorbs it for
# free: the reduced text is identical across all three at 21,249 characters.
# `--probe` therefore compares a CONTENT digest, never a file digest.
#
# ONE HOST IS UNREADABLE AND IS RECORDED AS UNREADABLE (§0.4). rhtla.net -- the
# "Rural Health Atlas", Louisiana's second RHTP site -- serves an unrendered
# Vue application whose mustache templates arrive as literal "{{ copy.brand }}"
# text. Maine's CGI Advantage portal and Connecticut's CTsource in a new
# costume. Its one readable data route, /api/facilities, is 3,576 named
# Louisiana facilities including 305 hospitals, with "award", "amount", "$",
# "RHTP" and "fund" occurring ZERO times each: A FACILITY REGISTRY FOR THE
# RURALITY-ELIGIBILITY TOOL, NOT AN AWARD ROSTER. It is archived as the §0.3
# control, because it is the largest machine-readable list of named Louisiana
# hospitals on the programme's own domain and carries no money at all.
#
# WHAT LOUISIANA HAS PROMISED, AND IT IS STILL NOT A ROSTER. The deck's own
# next-steps slide says the "Next Advisory Council meeting agenda [is] to
# include a complete list of obligated funds BY ENTITY TYPE". Even the
# publication Louisiana has committed to is by type, not by recipient.
#
# Usage:
#   --fetch [--force]  archive the 8 sources + SHA-256 manifest
#   --validate         the assertions and both controls, offline
#   --build            write the two status CSVs (there is NO award file)
#   --probe            LIVE: has Louisiana awarded yet?
#   --report           the negative, and the seven windows that have closed

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))

LA_EVIDENCE_DIR <- here::here("data", "evidence", "LA")
LA_STATUS_CSV   <- "data/reference/la_year1_status.csv"
LA_DISPO_CSV    <- "data/reference/la_rcj_candidate_disposition.csv"
LA_AWARDS_CSV   <- "data/reference/la_year1_awardees.csv"   # MUST NOT EXIST
LA_HOST_THROTTLE_S <- 3

# THE RFC WELL-BEHAVED-CRAWLER CONVENTION, AND IT IS THE HONEST AGENT.
# ldh.la.gov refuses the project's bare agent (403) and bare "Mozilla/5.0"
# (403) alike, and answers 200 to this form, which carries the tracker's name
# AND its contact URL. Session 10 settled that identifying honestly is the fix
# rather than a workaround; this host merely also wants the Mozilla prefix.
# It is NOT §3's michigan.gov exception -- there the bare agent was the ONLY
# one that worked, and the honest tokens were what got refused.
LA_USER_AGENT <- paste(
  "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1;",
  "+https://www.aha.org)"
)

LA_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,

  "programme",
  "2026-09-02_la_ldh_rhtp_programme_SEVEN_WINDOWS_PASSED.html",
  "https://ldh.la.gov/page/rural-health-transformation-program",

  "funding",
  "2026-09-02_la_ldh_rhtp_funding_opportunities.html",
  "https://ldh.la.gov/page/rhtp-funding-opportunities",

  "news",
  "2026-04-07_la_ldh_governor_establishes_orhts.html",
  "https://ldh.la.gov/news/office-of-rural-health-transformation",

  "council",
  "2026-08-20_la_ldh_rhtp_advisory_council_slides_PROJECTED_FUNDING.pdf",
  paste0("https://ldh.la.gov/assets/docs/Secretary/RHTP/",
         "RHTP-Advisory-Council-Meeting-8.20.2026-Slides.pdf"),

  "capital_nofo",
  "2026-06-18_la_ldh_capital_improvement_NOFO_ROW_RCJ_DROPS.pdf",
  "https://ldh.la.gov/assets/docs/Secretary/RHTP/CapitalNOFO.pdf",

  "catalyst",
  "2026-05-27_la_led_rural_tech_catalyst_fund_SECOND_PUBLISHER.html",
  paste0("https://www.opportunitylouisiana.gov/news/",
         "louisiana-launches-rural-tech-catalyst-fund-to-advance-",
         "rural-health-care-innovation"),

  "atlas",
  "2026-09-02_la_rhtla_atlas_landing_UNREADABLE.html",
  "https://rhtla.net/landing",

  "facilities",
  "2026-09-02_la_rhtla_api_facilities_ELIGIBILITY_CONTROL.json",
  "https://rhtla.net/api/facilities"
)

# Every figure Louisiana states, in its own words.
LA_STATED <- list(
  footer_amount   = "$208,374,447.57",
  deck_award      = "Louisiana awarded $208,374,448",
  governor_amount = "supported by more than $208 million in federal funding",
  five_year       = "Estimated $1.4 billion over 5 years",
  capital_range   = "$100,000-$10,000,000",
  noic_early      = "Notice of Intent to Contract Announcements: Late July to mid August",
  noic_late       = "Notice of Intent to Contract Announcements: Mid to late August",
  noic_early_n    = 3L,
  noic_late_n     = 4L,
  opportunities   = 7L,
  obligated_promise = "complete list of obligated funds by entity type"
)

LA_ARCHIVE_DATE <- as.Date("2026-09-02")

LA_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

la_path <- function(key) {
  row <- LA_SOURCES[LA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[LA] unknown source key: ", key, call. = FALSE)
  file.path(LA_EVIDENCE_DIR, row$file)
}

la_source <- function(key, field) {
  row <- LA_SOURCES[LA_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[LA] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

la_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(LA_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, LA_CREDENTIAL_SHAPES[[nm]])) {
      stop("[LA] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The agent guard, so the Mozilla prefix cannot quietly become a bare agent
#'
#' §3's michigan.gov lesson as code: a one-host allowance becomes a default
#' the moment nothing refuses it elsewhere. This refuses an agent that does
#' NOT carry the tracker's identity and contact URL, whatever host it is for.
la_agent_for <- function(url, agent = LA_USER_AGENT) {
  if (!stringr::str_detect(agent, stringr::fixed("AHA-RHTP-Tracker")) ||
      !stringr::str_detect(agent, stringr::fixed("+https://www.aha.org"))) {
    stop("[LA] refusing an agent that does not identify this project and a ",
         "contact URL. ldh.la.gov wants the Mozilla/5.0 PREFIX; it does not ",
         "want anonymity, and bare 'Mozilla/5.0' is 403 here anyway. That is ",
         "session 10's rule, not session 27's exception.", call. = FALSE)
  }
  agent
}

la_get <- function(url, label) {
  message("[LA] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(la_agent_for(url)),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[LA] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  la_assert_credential_free(served, label)
  served
}

la_fetch <- function(force = FALSE) {
  dir.create(LA_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(LA_SOURCES)), function(i) {
    src  <- LA_SOURCES[i, ]
    dest <- file.path(LA_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[LA] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(LA_HOST_THROTTLE_S)
      writeBin(la_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  la_write_manifest(entries)
  invisible(entries)
}

la_write_manifest <- function(entries) {
  path <- file.path(LA_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Louisiana -- Rural Health Transformation Program, Year 1.",
    "Archived by R/03ae_la_year1_probe.R --fetch",
    paste0("User-agent: ", LA_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "THE USER-AGENT, AND WHY IT IS NOT MICHIGAN'S EXCEPTION. ldh.la.gov",
    "answers the project's own agent 403 and bare 'Mozilla/5.0' 403, and",
    "answers 200 to the RFC well-behaved-crawler convention above -- which",
    "carries the tracker's name AND its contact URL. Identifying honestly is",
    "still the fix (session 10, medicaid.gov); this host merely also wants the",
    "Mozilla prefix. Michigan inverts that -- there the identifying tokens are",
    "what get refused. robots.txt here is 404, GENUINELY ABSENT, where",
    "Michigan's is 403: no crawler policy exists and none is being declined.",
    "",
    "LOUISIANA HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST, AND ALL SEVEN",
    "OF ITS OWN ANNOUNCEMENT WINDOWS HAVE CLOSED. LDH's programme page carries",
    "an 'IMPORTANT DATES - BUDGET YEAR 1' block giving a 'Notice of Intent to",
    "Contract Announcements' window for each of the seven Budget Year 1",
    "opportunities: 'Late July to mid August' x3 and 'Mid to late August' x4.",
    "This archive was taken 2026-09-02. Connecticut (session 35) was the first",
    "negative here whose award date had passed, with ONE solicitation sixteen",
    "days overdue; Louisiana has SEVEN, and published the dates itself.",
    "",
    "*_PROJECTED_FUNDING.pdf IS RCJ'S SOURCE AND ITS OWN REFUTATION.",
    "  Slide 18 of the 2026-08-20 Advisory Council deck is a table headed",
    "  'RHTP Funding Cycle Budget Year 1', columns Activity | # Applications",
    "  Received | PROJECTED BY 1 Funding | Anticipated Announcement. All SIX",
    "  RCJ Louisiana Tier 3 candidates are rows of it: the 'awardee' is the",
    "  ACTIVITY column (fund uses, not organisations -- §6.1's",
    "  PROGRAM_NAME_AS_AWARDEE on six of six) and the amount is the PROJECTED",
    "  column times a million. 505 applications received, NOT ONE AWARD NAMED.",
    "  The deck also promises only a 'complete list of obligated funds BY",
    "  ENTITY TYPE' next time -- by type, not by recipient.",
    "",
    "*_ROW_RCJ_DROPS.pdf is the Capital Improvement NOFO -- 160 applications,",
    "  $41.60 million projected, awards of $100,000-$10,000,000, and NOT among",
    "  RCJ's six. Its six sum to $53,910,000 against the deck's seven at",
    "  $95,510,000, so the aggregator understates the table it mined by",
    "  $41,600,000. Its eligible class is HOSPITALS AMONG OTHERS ('Critical",
    "  Access Hospitals (CAHs), Rural hospitals' beside RHCs, FQHCs, EMS,",
    "  behavioral health and independent rural practices) -- New Hampshire's",
    "  FHC class, not Illinois's ICAHN class, so §0.3 governs it either way.",
    "",
    "*_SECOND_PUBLISHER.html is LED's Rural Tech Catalyst Fund release, which",
    "  carries a programme-scoped provenance sentence from a publisher that is",
    "  not LDH: 'Supported through the Rural Health Transformation Program, a",
    "  more than $1 billion federal investment over five years'. It names no",
    "  recipient and no amount ('award' x0, 'recipient' x0).",
    "",
    "*_ELIGIBILITY_CONTROL.json IS A FACILITY REGISTRY, NOT AN AWARD ROSTER,",
    "  AND IT IS THE §0.3 TRAP. rhtla.net/api/facilities is 3,576 named",
    "  Louisiana facilities -- 305 hospitals (170 acute care, 135 specialty),",
    "  859 RHCs, 78 FQHCs -- with addresses, services and coordinates, on the",
    "  RHTP programme's own second domain. 'award', 'amount', '$', 'RHTP' and",
    "  'fund' occur ZERO times each. It is the dataset behind the 'Is my",
    "  location rural?' eligibility tool. California's 102 SRHRP eligible",
    "  hospitals in machine-readable form, and three times the size.",
    "",
    "*_UNREADABLE.html is rhtla.net's landing page and is recorded as UNKNOWN,",
    "  never as a negative (§0.4). It serves an unrendered Vue application:",
    "  its mustache templates arrive as literal '{{ copy.brand }}' text, so",
    "  whether the Atlas surfaces award data behind its parish profiles is a",
    "  statement about OUR ACCESS and not about Louisiana. Maine's CGI",
    "  Advantage portal and Connecticut's CTsource in a new costume.",
    "",
    "THESE FILE DIGESTS ARE NOT A CHANGE TEST, AND THE MECHANISM IS THE",
    "SEVENTH THIS PROJECT HAS MET. ldh.la.gov runs Cloudflare Email Address",
    "Obfuscation, which XOR-encodes a mailto with a RANDOM ONE-BYTE KEY on",
    "every render, into an href and a data-cfemail ATTRIBUTE. Three fetches",
    "gave THREE distinct file digests at EXACTLY 169,500 bytes each -- so it",
    "is California's antispambot() finding on a different platform, and",
    "CONSTANT-LENGTH like California's, which means a byte-count check passes",
    "it. Living in attributes rather than a script body makes it Connecticut's",
    "'?v=' stamp structurally, and the tag-stripping reduction absorbs it for",
    "free: reduced text IDENTICAL across all three at 21,249 characters.",
    "--probe compares a CONTENT digest via la_reduce_html(), never a file one.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

#' The one HTML reduction, so the probe and the assertions read the same bytes
#'
#' Missouri's rule (session 29). Stripping TAGS -- and with them every
#' attribute -- is what absorbs Cloudflare's per-render email obfuscation.
la_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_la_unescape(txt)
  txt <- stringr::str_remove_all(txt, "[​‌‍﻿]")
  stringr::str_squish(txt)
}

rhtp_la_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;|&#160;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  x <- stringr::str_replace_all(x, "[‘’‛]", "'")
  x <- stringr::str_replace_all(x, "[“”‟]", '"')
  x <- stringr::str_replace_all(x, "[‐‑‒–—]", "-")
  x
}

la_html_text <- function(key, body = NULL) {
  if (is.null(body)) {
    p <- la_path(key)
    body <- readBin(p, "raw", file.size(p))
  }
  la_reduce_html(body)
}

la_pdf_text <- function(key, body = NULL) {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  path <- if (is.null(body)) {
    la_path(key)
  } else {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp); tmp
  }
  stringr::str_squish(paste(rhtp_pdf_text(path), collapse = " "))
}

#' The §7.1 allotment anchor for Louisiana, read rather than typed
la_allotment_anchor <- function() {
  path <- here::here("data", "reference", "cms_fy2026_allotments.csv")
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == "LA"]
  if (length(v) != 1L) {
    stop("[LA] the §7.1 anchor does not carry exactly one LA row.",
         call. = FALSE)
  }
  v
}

#' The §6.2 NOA date anchor for Louisiana, read rather than typed
#'
#' It is the BUDGET PERIOD START (2025-12-29), never a Notice of Award form's
#' later "Federal Award Date" -- see rhtp_build_noa_dates() in
#' R/02b_provenance_sweep.R, which records why that distinction is load-bearing.
la_noa_anchor <- function() {
  path <- here::here("data", "reference", "cms_state_noa_dates.csv")
  if (!file.exists(path)) return(as.Date("2025-12-29"))
  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  v <- d$noa_date[d$state == "LA"]
  if (length(v) != 1L) return(as.Date("2025-12-29"))
  as.Date(v)
}

#' Slide 18's funding-cycle table, parsed rather than transcribed
#'
#' The deck's producer paints these cells without separating spaces
#' ("Rural Clinician CreditBank136$10millionMid August"), so the columns are
#' recovered by shape: a name, an application COUNT, a PROJECTED figure in
#' millions, and an announcement window. Returned in document order.
la_deck_funding_cycle <- function(body = NULL) {
  t <- if (is.null(body)) la_pdf_text("council") else body
  # The segment starts AFTER the column headings. Without that the lazy name
  # capture swallows "Anticipated Announcement" into the first row's activity,
  # because the headings and the first row are painted contiguously.
  seg <- stringr::str_extract(
    t, "(?<=Anticipated Announcement).*?(?=Exciting Opportunities)")
  if (is.na(seg)) {
    stop("[LA] slide 18's funding-cycle table is no longer in the Advisory ",
         "Council deck. It is the disposition's whole evidence base.",
         call. = FALSE)
  }
  m <- stringr::str_match_all(
    seg,
    paste0("([A-Z][A-Za-z/ ]*?)\\s*(\\d{2,3})\\s*\\$([0-9.]+)\\s*million",
           "\\s*(Early|Mid|Late)\\s*(July|August|September)")
  )[[1]]
  tibble::tibble(
    activity     = stringr::str_squish(m[, 2]),
    applications = as.integer(m[, 3]),
    projected    = as.numeric(m[, 4]) * 1e6,
    announcement = paste(m[, 5], m[, 6])
  )
}


# -- assertions ---------------------------------------------------------------

#' The provenance, carried by programme-scoped sentences and not by the footer
#'
#' Session 27's audit: LDH's footer is the WEAK form ("This project is
#' supported by"), so it corroborates the AMOUNT and three programme-scoped
#' sentences from THREE publishers carry the provenance.
la_assert_programme_provenance <- function(programme = NULL, news = NULL,
                                           catalyst = NULL, council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  n <- if (is.null(news)) la_html_text("news") else news
  c0 <- if (is.null(catalyst)) la_html_text("catalyst") else catalyst
  d <- if (is.null(council)) la_pdf_text("council") else council

  if (!stringr::str_detect(p, stringr::fixed(
        "The Louisiana Rural Health Transformation Program (RHTP) is a"))) {
    stop("[LA] LDH's RHTP page no longer opens with its programme-scoped ",
         "sentence. The CMS footer alone is the WEAK form (session 27) and ",
         "does not replace it.", call. = FALSE)
  }
  if (!stringr::str_detect(n, stringr::fixed(LA_STATED$governor_amount))) {
    stop("[LA] the Governor's 2026-04-07 release no longer states that RHTP ",
         "is federally funded. That is the second programme-scoped sentence, ",
         "from a second publisher.", call. = FALSE)
  }
  if (!stringr::str_detect(c0, stringr::fixed(
        "Supported through the Rural Health Transformation Program"))) {
    stop("[LA] LED's Rural Tech Catalyst Fund release no longer ties the fund ",
         "to RHTP. That is the third programme-scoped sentence, and the only ",
         "one published by an agency other than LDH.", call. = FALSE)
  }
  if (!stringr::str_detect(d, stringr::fixed(LA_STATED$deck_award))) {
    stop("[LA] the Advisory Council deck no longer states Louisiana's award. ",
         "It is what ties slide 18's table to RHTP.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The CMS footer corroborates the AMOUNT, and is demoted (session 27)
la_assert_footer_corroborates <- function(strict = FALSE, programme = NULL) {
  t <- if (is.null(programme)) la_html_text("programme") else programme
  if (!stringr::str_detect(t, stringr::fixed(LA_STATED$footer_amount))) {
    msg <- paste0("[LA] the CMS financial-assistance footer (",
                  LA_STATED$footer_amount, ") is no longer on LDH's RHTP ",
                  "page. It is the WEAK form and corroborates the amount ",
                  "only; the provenance is carried by three programme-scoped ",
                  "sentences.")
    if (strict) stop(msg, call. = FALSE)
    message(msg); return(invisible(NA))
  }
  cents <- as.numeric(stringr::str_remove_all(LA_STATED$footer_amount, "[$,]"))
  if (round(cents) != la_allotment_anchor()) {
    stop("[LA] the footer amount ", LA_STATED$footer_amount, " no longer ",
         "rounds to the §7.1 anchor ", la_allotment_anchor(), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Everything Louisiana has solicited postdates its Notice of Award
la_assert_after_noa <- function(capital = NULL) {
  t <- if (is.null(capital)) la_pdf_text("capital_nofo") else capital
  if (!stringr::str_detect(t, stringr::fixed("June 18, 2026"))) {
    stop("[LA] the Capital Improvement NOFO no longer carries its own ",
         "publication date. Texas's HHS0015180 closed before its state had ",
         "the money; that ordering is what rules the defect out here.",
         call. = FALSE)
  }
  if (as.Date("2026-06-18") <= la_noa_anchor()) {
    stop("[LA] the Capital Improvement NOFO no longer postdates Louisiana's ",
         "Notice of Award.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE TRIPWIRE: Louisiana has named no RHTP recipient
#'
#' DESIGNED TO FAIL. Three surfaces at once -- the programme page (which
#' carries the announcement dates), the funding-opportunities page (which
#' carries the seven solicitations) and the Advisory Council deck (which is
#' where Louisiana reports progress to its own Council). If any acquires award
#' language, this file must be REWRITTEN as an award extractor, not patched.
LA_AWARD_POSTED <- c(
  "has been awarded", "have been awarded", "awardees are",
  "selected for award", "list of awardees", "grant recipients",
  "funded organizations", "successful applicant", "notice of award"
)

la_assert_no_award_roster <- function(programme = NULL, funding = NULL,
                                      council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding
  d <- if (is.null(council)) la_pdf_text("council") else council

  for (nm in c("programme", "funding", "council")) {
    t <- switch(nm, programme = p, funding = f, council = d)
    hit <- LA_AWARD_POSTED[purrr::map_lgl(
      LA_AWARD_POSTED,
      ~ stringr::str_detect(t, stringr::regex(.x, ignore_case = TRUE)))]
    if (length(hit)) {
      stop("[LA] award language has appeared on the ", nm, " surface: ",
           paste(hit, collapse = " | "),
           ". THAT IS THE SIGNAL, NOT A DEFECT. Louisiana may have published ",
           "a recipient-level roster: read it, and rewrite this file as an ",
           "award extractor rather than adjusting this constant.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' SEVEN OPPORTUNITIES, SEVEN ANNOUNCEMENT WINDOWS, AND ALL SEVEN HAVE CLOSED
#'
#' Read out of the archived page rather than typed, and asserted as COUNTS,
#' because the closure that matters is 3 + 4 = 7 against the funding page's
#' seven "Strategic Funding Opportunity Title" headings.
la_assert_windows_passed <- function(programme = NULL, funding = NULL,
                                     asof = LA_ARCHIVE_DATE) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding

  n_early <- stringr::str_count(p, stringr::fixed(LA_STATED$noic_early))
  n_late  <- stringr::str_count(p, stringr::fixed(LA_STATED$noic_late))
  n_opps  <- stringr::str_count(f, stringr::fixed(
    "Strategic Funding Opportunity Title"))

  if (n_early != LA_STATED$noic_early_n || n_late != LA_STATED$noic_late_n) {
    stop("[LA] LDH's 'IMPORTANT DATES - BUDGET YEAR 1' block no longer reads ",
         LA_STATED$noic_early_n, " x 'Late July to mid August' and ",
         LA_STATED$noic_late_n, " x 'Mid to late August' (found ", n_early,
         " and ", n_late, "). Those windows dating the negative is the whole ",
         "finding -- if Louisiana has re-dated them, re-read the page.",
         call. = FALSE)
  }
  if (n_early + n_late != n_opps || n_opps != LA_STATED$opportunities) {
    stop("[LA] the announcement windows (", n_early + n_late, ") no longer ",
         "match the funding page's solicitations (", n_opps, "). Every ",
         "opportunity carrying a published announcement date is what makes ",
         "this negative dated rather than open-ended.", call. = FALSE)
  }
  # The latest window closes at the end of August; this is what says it passed.
  if (asof <= as.Date("2026-08-31")) {
    stop("[LA] this file's finding is that all seven announcement windows ",
         "have CLOSED. That is only true from 2026-09-01.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The deck's column heading is PROJECTED, and its rows are APPLICATIONS
#'
#' Oklahoma's tier defect with the state's own heading refuting it. Both halves
#' are asserted: that the funding column says "Projected", and that the row
#' counts are applications RECEIVED rather than awards made.
la_assert_deck_is_projected_not_awarded <- function(council = NULL) {
  t <- if (is.null(council)) la_pdf_text("council") else council
  for (k in c("RHTP Funding Cycle Budget Year 1", "ProjectedBY 1 Funding",
              "Applications", "Anticipated Announcement")) {
    if (!stringr::str_detect(t, stringr::fixed(k))) {
      stop("[LA] slide 18 no longer carries '", k, "'. The heading is what ",
           "makes these figures Tier 2 rather than awards.", call. = FALSE)
    }
  }
  cyc <- la_deck_funding_cycle(t)
  if (nrow(cyc) != LA_STATED$opportunities) {
    stop("[LA] slide 18 parsed ", nrow(cyc), " rows, expected ",
         LA_STATED$opportunities, ".", call. = FALSE)
  }
  if (sum(cyc$applications) != 505L) {
    stop("[LA] slide 18's applications no longer total 505 (found ",
         sum(cyc$applications), "). 505 applications and no named award is ",
         "§0.3 in the state's own table.", call. = FALSE)
  }
  if (round(sum(cyc$projected)) != 95510000) {
    stop("[LA] slide 18's projected funding no longer totals $95,510,000 ",
         "(found ", format(sum(cyc$projected), big.mark = ","), ").",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL: Louisiana publishes announcement dates, so silence
#' is the programme's and not our reading
#'
#' A negative is only a finding if the publisher demonstrably publishes in a
#' recognisable form. Louisiana's control is unusually strong and unusually
#' cheap: it names, for each opportunity, the FORM the announcement will take
#' ("Notice of Intent to Contract") and the WINDOW it will take it in. So
#' "no roster" is measured against Louisiana's own stated intention.
la_assert_announcement_control <- function(programme = NULL, funding = NULL,
                                           council = NULL) {
  p <- if (is.null(programme)) la_html_text("programme") else programme
  f <- if (is.null(funding)) la_html_text("funding") else funding
  d <- if (is.null(council)) la_pdf_text("council") else council

  if (!stringr::str_detect(p, stringr::fixed("IMPORTANT DATES - BUDGET YEAR 1"))) {
    stop("[LA] LDH's programme page no longer carries its 'IMPORTANT DATES' ",
         "block. Without it, 'Louisiana has published no roster' is ",
         "indistinguishable from 'we are reading the wrong page'.",
         call. = FALSE)
  }
  if (!stringr::str_detect(f, stringr::fixed(
        "Notice of Intent to Contract Announcements - Early to Mid-July"))) {
    stop("[LA] the funding page no longer carries the Rural Clinician Credit ",
         "Bank's own announcement window. It is the earliest of the seven and ",
         "the longest overdue.", call. = FALSE)
  }
  # And even what Louisiana has PROMISED is not a roster.
  if (!stringr::str_detect(d, stringr::fixed(LA_STATED$obligated_promise))) {
    stop("[LA] the deck no longer promises a 'complete list of obligated ",
         "funds by entity type'. That sentence is what says the publication ",
         "Louisiana has committed to is BY TYPE, not by recipient.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE §0.3 CONTROL: the Atlas facility registry carries no money at all
#'
#' 3,576 named Louisiana facilities including 305 hospitals, on the RHTP
#' programme's own second domain, and not one dollar figure. California's 102
#' SRHRP eligible hospitals in machine-readable form and three times the size.
la_assert_facilities_are_not_awards <- function(body = NULL) {
  p <- la_path("facilities")
  txt <- if (is.null(body)) {
    readChar(p, file.size(p), useBytes = TRUE)
  } else body
  for (k in c("\"award", "\"amount", "RHTP", "$")) {
    if (stringr::str_detect(txt, stringr::fixed(k))) {
      stop("[LA] rhtla.net/api/facilities now carries '", k, "'. It has been ",
           "a FACILITY REGISTRY with no money in it, which is why it is ",
           "archived as the §0.3 control. If it now carries awards, read it: ",
           "it is a recipient-level source and this file must be rewritten.",
           call. = FALSE)
    }
  }
  if (!stringr::str_detect(txt, stringr::fixed("\"display_type\""))) {
    stop("[LA] the facilities registry no longer has its display_type field; ",
         "the control cannot be read.", call. = FALSE)
  }
  invisible(TRUE)
}

la_assert_no_award_file <- function() {
  if (file.exists(here::here(LA_AWARDS_CSV))) {
    stop("[LA] ", LA_AWARDS_CSV, " exists. Louisiana has published no ",
         "recipient-level RHTP award list; if that has changed, write the ",
         "extractor deliberately and delete this assertion in the same ",
         "commit.", call. = FALSE)
  }
  path <- here::here(LA_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[LA] la_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table: Louisiana ",
           "has named no RHTP recipient, so no sum over it could mean ",
           "anything.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

rhtp_la_assert <- function(strict_footer = FALSE) {
  la_assert_programme_provenance()
  la_assert_footer_corroborates(strict = strict_footer)
  la_assert_after_noa()
  la_assert_no_award_roster()
  la_assert_windows_passed()
  la_assert_deck_is_projected_not_awarded()
  la_assert_announcement_control()
  la_assert_facilities_are_not_awards()
  la_assert_no_award_file()
  invisible(TRUE)
}


# -- the status table ---------------------------------------------------------

#' What each Louisiana RHTP channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device, and Wisconsin's, Maine's,
#' California's, Connecticut's and New Mexico's after it). Louisiana has named
#' no RHTP recipient; the pool figures live in `stated_pool` as the state's own
#' words, which cannot be summed by accident -- and they are PROJECTED figures
#' in any case, which is the whole finding.
rhtp_la_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~stated_pool, ~stage, ~announcement_window,
    ~eligible_class, ~publishes_roster, ~evidence,

    "Rural Health Facilities Capital Improvement Program -- THE POOL TO WATCH",
    "LDH", "$41.60 million projected; awards $100,000-$10,000,000",
    "CLOSED_AWARD_DATE_PASSED", "Late July to mid August",
    paste("HOSPITALS AMONG OTHERS. 'Rural Health Clinics (RHCs), Federally",
          "Qualified Health Centers (FQHCs) or look-alikes, Critical Access",
          "Hospitals (CAHs), Rural hospitals, Rural EMS providers, Rural",
          "behavioral health or substance use providers, Independent rural",
          "practices'. New Hampshire's FHC class, NOT Illinois's ICAHN class,",
          "so §0.3 governs it either way."),
    "No",
    paste("160 applications received -- the most of the seven -- and the",
          "largest projected pool. Capital investment in facility renovation,",
          "medical equipment and technology infrastructure, executed through a",
          "Cooperative Endeavor Agreement. RCJ DOES NOT CARRY THIS ROW."),

    "Rural Medicaid Alternative Payment Model Program", "LDH",
    "$30 million projected", "CLOSED_AWARD_DATE_PASSED", "Mid to late August",
    paste("Rural providers building infrastructure to participate in",
          "value-based care; population of focus is rural Louisiana Medicaid",
          "members and the providers serving them."),
    "No",
    paste("31 applications. Application deadline 2026-08-07. RCJ's largest",
          "Louisiana candidate at $30,000,000 -- which is this PROJECTED pool."),

    "Rural Clinician Credit Bank", "LDH",
    "$10 million projected", "CLOSED_AWARD_DATE_PASSED",
    "Late July to mid August",
    "Recruitment and retention of talent in rural healthcare settings.",
    "No",
    paste("136 applications. THE LONGEST OVERDUE: the funding page still reads",
          "'Applications currently under review' against an announcement",
          "window of 'Early to Mid-July'."),

    "Telehealth Infrastructure for Rural Access Program", "LDH",
    "$4.71 million projected", "CLOSED_AWARD_DATE_PASSED",
    "Late July to mid August",
    "Telehealth infrastructure investments across rural Louisiana.",
    "No",
    "79 applications. Application deadline 2026-07-10, shown as 'Closed'.",

    "Regional Care Conveners and Navigation Networks Program", "LDH",
    "$3.5 million projected", "CLOSED_AWARD_DATE_PASSED", "Mid to late August",
    paste("Regional conveners aligning providers across acute care,",
          "behavioral health and social services -- Missouri's ToRCH hub",
          "shape, so a PASS_THROUGH_* question when it lands, never a direct",
          "award."),
    "No",
    "25 applications. Application deadline 2026-08-14.",

    "Rural Collaborative Provider Models Program", "LDH",
    "$3 million projected", "CLOSED_AWARD_DATE_PASSED", "Mid to late August",
    paste("Collaborative provider models extending specialist coverage and",
          "pooling staff across rural FACILITIES -- hospitals among others."),
    "No",
    "37 applications. Application deadline 2026-08-05.",

    "Food is Medicine Program", "LDH",
    "$2.7 million projected", "CLOSED_AWARD_DATE_PASSED", "Mid to late August",
    paste("Start-up of food-is-medicine programmes 'in collaboration with",
          "health care providers and community-based organizations'."),
    "No",
    "37 applications. Application deadline 2026-08-14.",

    "Rural Tech Catalyst Fund", "LED / Louisiana Innovation (LA.IO)",
    "not stated", "ANNOUNCED_NOT_SOLICITED", "not stated",
    paste("'health care providers, entrepreneurs, investors, universities and",
          "technology companies' -- hospitals are not named as a class."),
    "No",
    paste("Launched 2026-05-27 by LED, not LDH. Carries the third and only",
          "non-LDH programme-scoped provenance sentence: 'Supported through",
          "the Rural Health Transformation Program, a more than $1 billion",
          "federal investment over five years'. Names no recipient and no",
          "amount ('award' x0, 'recipient' x0)."),

    "Rural Health Atlas (rhtla.net)", "LDH",
    "not applicable", "UNREADABLE", "not applicable",
    "not applicable",
    "UNKNOWN",
    paste("An unrendered Vue application: its mustache templates arrive as",
          "literal '{{ copy.brand }}' text, so whether the Atlas surfaces",
          "award data behind its parish profiles is a statement about OUR",
          "ACCESS, never about Louisiana (§0.4). Maine's CGI Advantage portal",
          "and Connecticut's CTsource in a new costume. Its one readable data",
          "route, /api/facilities, is 3,576 named facilities including 305",
          "hospitals with NO money in it -- the §0.3 control, not a roster.")
  )
}


# -- RCJ candidate disposition ------------------------------------------------

la_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(.data$state == "LA", .data$award_tier == "SUBAWARD")
}

#' Why each of RCJ's six Louisiana Tier 3 candidates is not a subaward
#'
#' The counts and the sum are RE-DERIVED from the record table on every run
#' (Texas's device), so the day Louisiana's candidate set moves the build fails
#' instead of this table quietly ceasing to cover it.
rhtp_la_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- la_rcj_candidates()
  n   <- nrow(cands)
  amt <- sum(cands$amount_announced, na.rm = TRUE)

  if (n != 6L) {
    stop("[LA] expected 6 Louisiana Tier 3 candidates, found ", n,
         ". This disposition covers six specific rows; re-read them before ",
         "changing the count.", call. = FALSE)
  }
  if (round(amt) != 53910000) {
    stop("[LA] the candidate amounts no longer sum to $53,910,000 (found ",
         format(amt, big.mark = ","), ").", call. = FALSE)
  }

  tibble::tribble(
    ~disposition, ~rows, ~rcj_amount, ~mechanism, ~disqualifying_fact,
    ~state_source_url, ~source_archive_path,

    "RHTP_BUT_NOT_A_SUBAWARD", 6L, 53910000,
    paste("TIER (Oklahoma's defect), and §6.1's PROGRAM_NAME_AS_AWARDEE on",
          "SIX OF SIX. All six rows are rows of ONE table -- slide 18 of the",
          "2026-08-20 Advisory Council deck, headed 'RHTP Funding Cycle",
          "Budget Year 1'. The 'awardee' is the ACTIVITY column ('Alternative",
          "Payment Model', 'Care conveners / navigation network', 'Food is",
          "Medicine', 'Telehealth', 'Rural Clinician Credit Bank',",
          "'Collaborative Provider Model'), which are fund uses and not",
          "organisations at all -- and `named_recipient_test` reads PASS on",
          "every one. The amount is the 'Projected BY 1 Funding' column times",
          "a million."),
    paste("The deck's own column heading reads 'ProjectedBY 1 Funding'",
          "against '# Applications Received', and the seven rows record 505",
          "APPLICATIONS with not one award named. Oklahoma's Legislative",
          "Quarterly Reports had to be read to their glossary to establish",
          "the same thing; Louisiana says PROJECTED in the heading. AND RCJ",
          "DROPS THE LARGEST ROW: Capital Improvement, 160 applications and",
          "$41.60 million, is not among the six, so the six sum to",
          "$53,910,000 against the deck's seven at $95,510,000 -- the",
          "aggregator UNDERSTATES the table it mined by $41,600,000, and the",
          "row it drops is the CAPITAL one, the likeliest to reach a",
          "hospital. NOT ONE candidate is a named Louisiana organisation of",
          "any kind."),
    "https://ldh.la.gov/page/rural-health-transformation-program",
    paste0("data/evidence/LA/2026-08-20_la_ldh_rhtp_advisory_council_slides_",
           "PROJECTED_FUNDING.pdf")
  )
}

#' The six candidates ARE the deck's activity column, asserted rather than said
la_assert_candidates_are_deck_activities <- function(cands = NULL,
                                                     council = NULL) {
  if (is.null(cands)) cands <- la_rcj_candidates()
  cyc <- la_deck_funding_cycle(council)

  # LETTERS ONLY, SPACES INCLUDED IN THE STRIP. The deck's producer paints
  # "Food isMedicine" and "Rural Clinician CreditBank" -- two runs on one line
  # separated by pen POSITIONING rather than a space glyph, which session 32
  # measured and which the reader cannot recover without font metrics. So the
  # comparison cannot depend on the deck's word spacing.
  norm <- function(x) tolower(stringr::str_remove_all(x, "[^A-Za-z]"))
  deck <- norm(cyc$activity)
  rcj  <- norm(cands$awardee_name_raw)

  miss <- rcj[!purrr::map_lgl(rcj, function(r) {
    any(purrr::map_lgl(deck, ~ stringr::str_detect(.x, stringr::fixed(r)) ||
                              stringr::str_detect(r, stringr::fixed(.x))))
  })]
  if (length(miss)) {
    stop("[LA] these RCJ candidates no longer match a row of slide 18's ",
         "table: ", paste(miss, collapse = " | "), ". The disposition rests ",
         "on all six being rows of that table.", call. = FALSE)
  }

  # And the amounts are the PROJECTED column, to the dollar.
  for (i in seq_len(nrow(cands))) {
    r <- norm(cands$awardee_name_raw[i])
    j <- which(purrr::map_lgl(deck, ~ stringr::str_detect(.x, stringr::fixed(r)) ||
                                      stringr::str_detect(r, stringr::fixed(.x))))[1]
    if (round(cands$amount_announced[i]) != round(cyc$projected[j])) {
      stop("[LA] candidate '", cands$awardee_name_raw[i], "' carries ",
           format(cands$amount_announced[i], big.mark = ","),
           " against slide 18's ", format(cyc$projected[j], big.mark = ","),
           ". The amounts matching the PROJECTED column is what makes the ",
           "tier defect provable rather than asserted.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' RCJ DROPS THE LARGEST ROW, and it is the capital one
la_assert_capital_row_dropped <- function(cands = NULL, council = NULL) {
  if (is.null(cands)) cands <- la_rcj_candidates()
  cyc <- la_deck_funding_cycle(council)

  cap <- cyc[stringr::str_detect(cyc$activity, "Capital"), ]
  if (nrow(cap) != 1L || round(cap$projected) != 41600000) {
    stop("[LA] slide 18 no longer carries exactly one Capital Improvement row ",
         "at $41,600,000.", call. = FALSE)
  }
  if (any(stringr::str_detect(cands$awardee_name_raw, "(?i)capital"))) {
    stop("[LA] RCJ now carries the Capital Improvement row. It has been the ",
         "row the aggregator drops -- the largest of the seven, and the one ",
         "likeliest to reach a hospital. Re-read the disposition: the ",
         "$41,600,000 understatement no longer holds.", call. = FALSE)
  }
  if (round(sum(cyc$projected) - sum(cands$amount_announced, na.rm = TRUE)) !=
      41600000) {
    stop("[LA] the gap between slide 18's seven rows and RCJ's six is no ",
         "longer exactly the Capital Improvement row.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- build / report -----------------------------------------------------------

rhtp_la_build <- function() {
  rhtp_la_assert()
  la_assert_candidates_are_deck_activities()
  la_assert_capital_row_dropped()

  status <- rhtp_la_year1_status()
  readr::write_csv(status, here::here(LA_STATUS_CSV), na = "")
  message("[LA] wrote ", nrow(status), " channels -> ", LA_STATUS_CSV)

  dispo <- rhtp_la_rcj_disposition()
  readr::write_csv(dispo, here::here(LA_DISPO_CSV), na = "")
  message("[LA] wrote ", nrow(dispo), " disposition rows -> ", LA_DISPO_CSV)

  la_assert_no_award_file()
  invisible(list(status = status, disposition = dispo))
}

rhtp_la_report <- function() {
  cyc   <- la_deck_funding_cycle()
  cands <- la_rcj_candidates()

  cat("\nLOUISIANA -- RHTP Year 1. A NEGATIVE, AND SEVEN WINDOWS HAVE CLOSED.\n")
  cat(strrep("-", 74), "\n")
  cat("  Allotment (§7.1)        $", format(la_allotment_anchor(), big.mark = ","),
      "\n", sep = "")
  cat("  Recipient-level roster   NONE, on any reachable Louisiana host.\n")
  cat("  Named hospital dollars   $0.   Named hospital rows: 0.\n\n")

  cat("  LDH's own 'IMPORTANT DATES - BUDGET YEAR 1', and the deck's slide 18:\n\n")
  norm <- function(x) tolower(stringr::str_remove_all(x, "[^A-Za-z]"))
  dollars <- function(x) paste0("$", format(x, big.mark = ",",
                                            scientific = FALSE, trim = TRUE))
  held <- norm(cands$awardee_name_raw)

  cat(sprintf("    %-38s %5s %14s  %s\n",
              "ACTIVITY", "APPS", "PROJECTED BY1", "ANNOUNCEMENT"))
  for (i in seq_len(nrow(cyc))) {
    a <- norm(cyc$activity[i])
    carried <- any(purrr::map_lgl(held, ~ stringr::str_detect(a, stringr::fixed(.x)) ||
                                         stringr::str_detect(.x, stringr::fixed(a))))
    cat(sprintf("    %-38s %5d %14s  %s%s\n",
                substr(cyc$activity[i], 1, 38), cyc$applications[i],
                dollars(cyc$projected[i]), cyc$announcement[i],
                if (carried) "" else "   <- RCJ DROPS THIS"))
  }
  cat(sprintf("    %-38s %5d %14s\n", "TOTAL", sum(cyc$applications),
              dollars(sum(cyc$projected))))

  cat("\n  505 APPLICATIONS RECEIVED, NOT ONE AWARD NAMED (§0.3), and every\n")
  cat("  announcement window above closed before ", as.character(LA_ARCHIVE_DATE),
      ".\n", sep = "")
  cat("\n  §0.1: all SIX RCJ candidates are rows of that table -- the ACTIVITY\n")
  cat("  column read as an awardee (§6.1 PROGRAM_NAME_AS_AWARDEE, six of six)\n")
  cat("  and the PROJECTED column read as an amount. They sum to $",
      format(sum(cands$amount_announced, na.rm = TRUE), big.mark = ",",
             scientific = FALSE, trim = TRUE),
      ",\n  understating the deck's own seven rows by $41,600,000.\n", sep = "")
  invisible(TRUE)
}


# -- the live probe -----------------------------------------------------------

#' Missouri's `--probe` shape (session 29): fetch, compare, report, and run the
#' award tripwires against the LIVE bytes rather than the archive.
#'
#' IT COMPARES A CONTENT DIGEST, NEVER A FILE DIGEST. ldh.la.gov runs
#' Cloudflare Email Address Obfuscation, which XOR-encodes a mailto with a
#' random one-byte key on every render into an href and a `data-cfemail`
#' attribute: three fetches, three distinct file digests, EXACTLY 169,500 bytes
#' every time. Constant-length like California's antispambot() re-roll, so a
#' byte-count check passes it; attribute-borne like Connecticut's `?v=` stamp,
#' so the tag-stripping reduction absorbs it for free.
LA_PROBE_KEYS <- c("programme", "funding", "council")

la_content_digest <- function(body, key) {
  if (key == "council") {
    tmp <- tempfile(fileext = ".pdf"); writeBin(body, tmp)
    if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
    txt <- stringr::str_squish(paste(rhtp_pdf_text(tmp), collapse = " "))
  } else {
    txt <- la_reduce_html(body)
  }
  digest::digest(txt, algo = "sha256")
}

la_probe <- function(keys = LA_PROBE_KEYS) {
  message("[LA] LIVE probe, ", format(Sys.time(), tz = "UTC"), " UTC")
  live <- list()
  for (key in keys) {
    body <- la_get(la_source(key, "url"), key)
    p    <- la_path(key)
    was  <- if (file.exists(p)) {
      la_content_digest(readBin(p, "raw", file.size(p)), key)
    } else NA_character_
    now  <- la_content_digest(body, key)
    live[[key]] <- body
    message(sprintf("  %-10s %s  %s", key,
                    if (is.na(was)) "NEW      " else if (was == now) "UNCHANGED" else "CHANGED  ",
                    substr(now, 1, 16)))
    if (key != tail(keys, 1)) Sys.sleep(LA_HOST_THROTTLE_S)
  }

  prog <- if ("programme" %in% keys) la_reduce_html(live$programme) else NULL
  fund <- if ("funding" %in% keys) la_reduce_html(live$funding) else NULL
  deck <- if ("council" %in% keys) {
    tmp <- tempfile(fileext = ".pdf"); writeBin(live$council, tmp)
    if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
    stringr::str_squish(paste(rhtp_pdf_text(tmp), collapse = " "))
  } else NULL

  la_assert_no_award_roster(programme = prog, funding = fund, council = deck)
  la_assert_windows_passed(programme = prog, funding = fund)
  la_assert_deck_is_projected_not_awarded(council = deck)
  message("[LA] the award tripwires pass against the LIVE bytes: Louisiana ",
          "has not published a recipient-level RHTP award roster.")
  invisible(TRUE)
}


# -- CLI ----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    la_fetch(force = "--force" %in% args)
  if ("--probe" %in% args)    la_probe()
  if ("--validate" %in% args) {
    rhtp_la_assert()
    la_assert_candidates_are_deck_activities()
    la_assert_capital_row_dropped()
    message("[LA] all assertions pass.")
  }
  if ("--build" %in% args)    rhtp_la_build()
  if ("--report" %in% args)   rhtp_la_report()
  if (!length(intersect(args, c("--probe", "--fetch", "--validate", "--build",
                                "--report")))) {
    message("Usage: Rscript R/03ae_la_year1_probe.R ",
            "[--probe] [--fetch [--force]] [--validate] [--build] [--report]")
  }
}

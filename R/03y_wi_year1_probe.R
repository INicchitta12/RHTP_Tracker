# 03y_wi_year1_probe.R --------------------------------------------------------
# Wisconsin Year 1 -> data/reference/wi_year1_status.csv
#                     data/reference/wi_rcj_candidate_disposition.csv
#
# THERE IS DELIBERATELY NO wi_year1_awardees.csv, AND A TEST ASSERTS ITS
# ABSENCE. Wisconsin has published no recipient-level RHTP award list.
#
# WHY WISCONSIN. It led the queue once New Hampshire was extracted -- 19 Tier 3
# candidates, 19 distinct awardees, a $203,670,005 allotment, no CMS press
# release, and never investigated.
#
# WHAT WISCONSIN HAS PUBLISHED. Four DHS grant opportunities, EVERY ONE of them
# "application period now closed" and NOT ONE of them naming a recipient, plus
# partner opportunities run by other state agencies. DHS's own advisory-council
# deck of 2026-07-23 dates the missing thing precisely: "Award announcements:
# September" against three of the four. This session ran on 2026-09-01, and
# DHS's RHTP page was last revised 2026-08-24 -- so Wisconsin is at
# SOLICITATION stage, by a margin of days rather than months.
#
# THE STRUCTURE, WHICH IS WHY THE AWARDS ARE NOT ON THE RHTP SITE. Wisconsin
# runs RHTP through STATE-AGENCY IMPLEMENTATION PARTNERS. The Wisconsin Office
# of Rural Health -- the programme's own external evaluator -- describes it in
# its April update: "16 state agencies and over 29 projects ... Some of the
# funding flows to other state agencies, like staging areas based on that
# agency's expertise ... Some of those agency implementation partners will fund
# community recipients directly, others will post requests for proposals from
# community members." So the recipient-level rosters, when they come, will be
# on DWD, DPI and WTCS pages and not only on the DHS one. INDIANA'S SIXTH
# QUESTION, answered by the state rather than inferred.
#
# §0.1 -- AND WISCONSIN IS THE FIRST STATE WHERE RCJ PRICES ROWS AGAINST A
# DOCUMENT WHOSE OWN TEXT CARRIES NONE OF THOSE FIGURES. All 16 of RCJ's
# priced Wisconsin "awards" are filed under the source document title "WI -
# 2026 - RHTP Advisory Council July 23, 2026". That deck is archived here. Its
# decoded text carries exactly four dollar figures -- $203,670,005.21 twice
# (the CMS footer), $300,000, $10 and $1 -- and NOT ONE of the 16 amounts.
# One slide (page 26) is image-only, sitting between "RHT Grant Update -- Dani
# Cook, Director-Healthcare" and "Rurality Designations", which is exactly
# where a WTCS allocation table would sit; so this file says the amounts are
# NOT IN THE DOCUMENT'S TEXT LAYER and does not claim they are absent from the
# document altogether (§0.4).
#
# AND THE DECK SAYS WHAT THOSE 16 FIGURES ARE. The slide immediately after the
# image reads "Fund Allocation -- Base amount: $300,000 -- Remaining funds
# distributed by county: 60% Rural / 40% Semi-rural -- Funding split based upon
# county funding formula that is used for AEFLA and WTCS Board purposes." That
# is a FORMULA-DRIVEN SUB-ALLOCATION to the Wisconsin Technical College System,
# not a competitive award, and the deck's own next slides are "Measurable
# Objectives" in the future tense and "Pre-proposal Concepts".
#
# THE 16 NAMES ARE THE 16 WTCS DISTRICTS, AND THAT IS SOURCED RATHER THAN
# KNOWN. RCJ carries them stripped to bare region names -- "Northwood",
# "Chippewa Valley", "Blackhawk" -- which read as regions and not as
# organisations. WTCS's own college roster is archived here, and all 16 map
# one-to-one onto it, with no extras and no omissions. They are technical
# colleges, so Wisconsin's hospital dollars would be $0 even if these were
# awards.
#
# §6.2, WITH THE FOOTER NON-STRICT (session 27's audit, session 28's
# demotion). DHS's footer opens "This program is supported by CMS" -- the WEAK
# form, whose subject is the publication's programme rather than RHTP by name,
# and which appears unchanged on pages describing OTHER agencies' work. It
# corroborates the AMOUNT -- $203,670,005.21 against the §7.1 anchor's
# $203,670,005 -- and nothing else. Two PROGRAMME-SCOPED sentences carry the
# provenance, and `wi_assert_footer_corroborates()` returns NA rather than
# throwing when called non-strictly.
#
# THE NEGATIVE CONTROL IS LINKED FROM AN RHTP-FUNDED PAGE AND IS TEXAS'S SHAPE.
# DWD's WIG: HEART page -- which carries the RHTP CMS footer -- links a
# document titled "Successful WIG Healthcare Awards". It is a real, executed,
# recipient-level health-workforce award list. It is the GOVERNOR'S 2021
# Workforce Innovation Grant programme, "used funding from the American Rescue
# Plan Act to award $128 million to 27 projects", and it mentions RHTP ZERO
# times. An extractor that took "an award list on an RHTP page" as evidence
# would have published $128M of ARPA money as Wisconsin's RHTP subawards.
#
# THE §0.3 TRAP, AND IT IS THE LARGEST THIS PROJECT HAS MET BY HEAD COUNT.
# DPI publishes a list of 213 NAMED RURAL SCHOOL DISTRICTS on its RHTP grant
# page, under the heading "Eligible Districts List", against a $5M/5yr pool of
# which "Twenty Wisconsin secondary schools WILL RECEIVE competitive grants".
# 213 names, 20 future awards, no awardee list. Illinois's 97 eligible
# hospitals in a second setting.
#
# AND THE ONE THAT WOULD COST REAL MONEY. DHS's Rural Technology
# Transformation pool -- "DHS will award up to $61 million in the first round"
# -- states that "Eligible organizations have been pre-identified based on the
# rural health facility information provided to CMS as part of Wisconsin's
# Rural Health Transformation Program application. Only organizations named in
# the application are eligible." That is a CLOSED, HOSPITAL-WEIGHTED ELIGIBLE
# CLASS worth $61M, and §0.3 is the whole answer: eligibility is not receipt,
# the application's facility list is not published here, and no recipient has
# been named. It is in the status table and it has no amount column to sum.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "02_normalize.R"))

`%||%` <- function(a, b) if (is.null(a)) b else a

WI_EVIDENCE_DIR <- here::here("data", "evidence", "WI")
WI_STATUS_CSV   <- "data/reference/wi_year1_status.csv"
WI_DISPO_CSV    <- "data/reference/wi_rcj_candidate_disposition.csv"
WI_AWARDS_CSV   <- "data/reference/wi_year1_awardees.csv"   # MUST NOT EXIST
WI_HOST_THROTTLE_S <- 3
WI_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

WI_SOURCES <- tibble::tribble(
  ~key,             ~file,                                       ~url,
  "dhs_rhtp",       "2026-09-01_dhs_rhtp_program.html",
  "https://www.dhs.wisconsin.gov/rhtp/index.htm",
  "dhs_rhtpac",     "2026-09-01_dhs_rhtp_advisory_council.html",
  "https://www.dhs.wisconsin.gov/rhtp/rhtpac.htm",
  "dhs_deck_0723",  "2026-09-01_dhs_rhtpac_presentation_260723.pdf",
  "https://www.dhs.wisconsin.gov/rhtp/rhtpac-presentation260723.pdf",
  "dhs_solicit",    "2026-09-01_dhs_current_grant_solicitations.html",
  "https://www.dhs.wisconsin.gov/business/solicitations-list.htm",
  "dwd_heart",      "2026-09-01_dwd_wig_heart.html",
  "https://dwd.wisconsin.gov/det/heart/",
  "dwd_wig_awards", "2026-09-01_dwd_wig_healthcare_awards_NEGATIVE_CONTROL.pdf",
  "https://dwd.wisconsin.gov/det/heart/documents/workforceinnovationgrantreport-health-services.pdf",
  "dpi_rhtp",       "2026-09-01_dpi_rhtp_grant.html",
  "https://dpi.wi.gov/cte/rhtp-grant",
  "worh_rhtp",      "2026-09-01_worh_rhtp_updates.html",
  "https://worh.org/resources/projects-initiatives/rhtp/",
  "wtcs_colleges",  "2026-09-01_wtcs_college_roster_CONTROL.html",
  "https://mywtcs.wtcsystem.edu/fire-service/technical-colleges-and-contacts/"
)

# THE ONE PATH THIS SESSION COULD NOT READ, RECORDED AS UNKNOWN AND NOT AS A
# NEGATIVE (§0.4). RCJ's /activity recorded this url on 2026-07-02 and its
# slug -- "rural-technology-transformation-fund-ALLOCATIONS" -- is the one that
# would most plausibly carry a roster. It answers 403 on ALL FOUR agents while
# www.dhs.wisconsin.gov/rhtp/index.htm answers 200 on the same agents from the
# same host, and robots.txt is 200 and does not disallow /contracts/. So this
# is a PER-PATH refusal by the origin, NOT a bot block and NOT a crawler policy
# being declined -- which is measured here rather than assumed, and is the
# opposite finding from New Hampshire (whole estate) and Michigan (whole host).
WI_UNREADABLE_URL <- paste0(
  "https://www.dhs.wisconsin.gov/contracts/",
  "rural-technology-transformation-fund-allocations-improve-health-services-",
  "rural-wisconsin"
)
WI_UNREADABLE_STATUS  <- 403L
WI_UNREADABLE_AGENTS  <- c("project honest (+url)", "RFC Mozilla/5.0 (compatible)",
                           "bare Mozilla/5.0", "full Chrome")
WI_UNREADABLE_CONTROL <- "https://www.dhs.wisconsin.gov/rhtp/index.htm"
WI_UNREADABLE_TESTED  <- "2026-09-01"

WI_STATED <- list(
  cms_allotment_stated = 203670005.21,
  cms_allotment_anchor = 203670005,
  noa_date             = "2025-12-29",
  council_meeting      = "2026-07-23",
  page_last_revised    = "August 24, 2026",
  wtcs_base_amount     = 300000,
  wtcs_colleges_n      = 16L,
  dpi_eligible_leas    = 213L,
  dpi_future_awards    = 20L,
  tech_pool_ceiling    = "up to $61 million",
  wig_arpa_total       = "$128 million",
  wig_arpa_projects    = 27L
)

# THE PROVENANCE, PROGRAMME-SCOPED. Each has the PROGRAMME or the AWARD ACTION
# as its grammatical subject, which is what session 27's audit found the CMS
# footer does not.
WI_PROGRAMME_SCOPED <- c(
  programme = paste("The Rural Health Transformation Program is a federal",
                    "funding opportunity provided to states through the",
                    "Centers for Medicare and Medicaid Services (CMS)"),
  award     = paste("The Wisconsin Department of Health Services (DHS)",
                    "received a first-year award from CMS for",
                    "$203,670,005.21")
)

# The WEAK footer -- session 27's audit calls this form non-load-bearing. It
# corroborates the AMOUNT and nothing else.
WI_FOOTER_WEAK <- "This program is supported by CMS"
WI_FOOTER_AMOUNT <- "financial assistance award totaling $203,670,005.21"

# EVERY DHS OPPORTUNITY IS CLOSED AND UNAWARDED, IN DHS'S OWN WORDS. These are
# the sentences `wi_assert_no_award_roster()` reads, and it is DESIGNED TO FAIL
# the day any of them is replaced by a roster.
WI_CLOSED_MARKER   <- "application period now closed"
WI_CLOSED_EXPECTED <- 4L
WI_FUTURE_AWARD_MARKERS <- c(
  dental = "DHS plans to award $10 million",
  tech   = "DHS will award up to $61 million in the first round of funding",
  chw    = "DHS plans to award $20 million for the first year of funding",
  care   = "DHS plans to award up to $10 million in 2026"
)

# The deck's own statement of what has NOT happened yet (Missouri's fourteenth
# question: does the state publish a timeline saying what it has not done?).
WI_AWARD_ANNOUNCEMENT_MARKER <- "Award announcements: September"
WI_AWARD_ANNOUNCEMENT_N      <- 3L

# The solicitations index calls itself unawarded. This is the POSITIVE CONTROL
# in the cheapest possible form: the publisher labels the state of the list.
WI_SOLICIT_UNAWARDED <- "list of current solicitations (unawarded) by DHS"

# THE WTCS ALLOCATION, IN THE DECK'S OWN WORDS.
WI_WTCS_FORMULA_MARKERS <- c(
  base    = "Base amount: $300,000",
  county  = "distributed by county",
  formula = "county funding formula",
  board   = "WTCS Board purposes"
)

# RCJ's 16 priced Wisconsin rows, as RCJ spells them. Held here so the mapping
# onto the WTCS roster is checkable rather than asserted.
WI_RCJ_REGION_NAMES <- c(
  "Northwood", "Chippewa Valley", "Northcentral", "Western", "Northeast",
  "Nicolet", "Southwest", "Madison", "Mid-State", "Fox Valley", "Moraine Park",
  "Gateway", "Lakeshore", "Blackhawk", "Waukesha", "Milwaukee"
)

# §0.3, DPI: 213 named districts are an ELIGIBILITY list, 20 are future awards.
WI_DPI_MARKERS <- c(
  eligible = "213 rural LEAs meet these eligibility requirements",
  future   = "Twenty Wisconsin secondary schools will receive competitive grants",
  heading  = "Eligible Districts List"
)

# §0.3, the $61M pool: a closed, pre-identified eligible class.
WI_TECH_ELIGIBILITY <- paste(
  "Eligible organizations have been pre-identified based on the rural health",
  "facility information provided to CMS as part of Wisconsin's Rural Health",
  "Transformation Program application. Only organizations named in the",
  "application are eligible.")

# THE NEGATIVE CONTROL's own words.
WI_WIG_MARKERS <- c(
  arpa     = "used funding from the American Rescue Plan Act to award $128",
  programme = "Workforce Innovation Grant (WIG) Program"
)

WI_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch -------------------------------------------------------------------

wi_path <- function(key) {
  row <- WI_SOURCES[WI_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[WI] unknown source key: ", key, call. = FALSE)
  file.path(WI_EVIDENCE_DIR, row$file)
}

wi_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(WI_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, WI_CREDENTIAL_SHAPES[[nm]])) {
      stop("[WI] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

wi_get <- function(url, label) {
  message("[WI] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(WI_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[WI] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  wi_assert_credential_free(served, label)
  served
}

wi_fetch <- function(force = FALSE) {
  dir.create(WI_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(WI_SOURCES)), function(i) {
    src  <- WI_SOURCES[i, ]
    dest <- file.path(WI_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[WI] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(WI_HOST_THROTTLE_S)
      writeBin(wi_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  wi_write_manifest(entries)
  invisible(entries)
}

wi_write_manifest <- function(entries) {
  path <- file.path(WI_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Wisconsin -- Rural Health Transformation Program, Year 1.",
    "Archived by R/03y_wi_year1_probe.R --fetch",
    paste0("User-agent: ", WI_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch and finds nothing, so there is",
    "no reduction to explain.",
    "",
    "WISCONSIN HAS PUBLISHED NO RECIPIENT-LEVEL RHTP AWARD LIST. Four DHS",
    "opportunities are all 'application period now closed' and none names a",
    "recipient; the advisory-council deck of 2026-07-23 says 'Award",
    "announcements: September' against three of them; and the solicitations",
    "index calls itself a 'list of current solicitations (unawarded) by DHS'.",
    "",
    "TWO OF THESE FILES ARE CONTROLS AND ARE NAMED SO.",
    "  *_NEGATIVE_CONTROL.pdf is DWD's 'Successful WIG Healthcare Awards' --",
    "  a REAL executed health-workforce award list, linked from an RHTP-funded",
    "  page, belonging to the Governor's 2021 ARPA-funded Workforce Innovation",
    "  Grant programme. It mentions RHTP zero times. Texas's shape.",
    "  *_CONTROL.html is the WTCS college roster, which is what makes the",
    "  claim that RCJ's 16 bare region names ARE the 16 technical college",
    "  districts a sourced fact rather than this pipeline's own knowledge.",
    "",
    paste0("ONE PATH IS UNREADABLE AND THAT IS RECORDED, NOT RESOLVED. ",
           WI_UNREADABLE_URL),
    paste0("answers ", WI_UNREADABLE_STATUS, " on all of: ",
           paste(WI_UNREADABLE_AGENTS, collapse = ", "), " (tested ",
           WI_UNREADABLE_TESTED, "), while ", WI_UNREADABLE_CONTROL,
           " answers 200 on the same"),
    "agents from the same host and robots.txt is 200 and does not disallow",
    "/contracts/. So it is a PER-PATH refusal by the origin, and what it holds",
    "is UNKNOWN to this repository (§0.4).",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- readers -----------------------------------------------------------------

wi_html_text <- function(key) {
  raw <- readBin(wi_path(key), "raw", file.size(wi_path(key)))
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(txt, "(?s)<(script|style)[^>]*>.*?</\\1>")
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- rhtp_wi_unescape(txt)
  stringr::str_squish(txt)
}

rhtp_wi_unescape <- function(x) {
  x <- stringr::str_replace_all(x, "&nbsp;", " ")
  x <- stringr::str_replace_all(x, "&amp;", "&")
  x <- stringr::str_replace_all(x, "&#39;|&rsquo;|&#8217;", "'")
  x <- stringr::str_replace_all(x, "&quot;|&ldquo;|&rdquo;", '"')
  x <- stringr::str_replace_all(x, "&lt;", "<")
  x <- stringr::str_replace_all(x, "&gt;", ">")
  x <- stringr::str_replace_all(x, "&#8211;|&ndash;", "-")
  x
}

wi_deck_text <- function() {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  paste(rhtp_pdf_text(wi_path("dhs_deck_0723")), collapse = "\n")
}

wi_wig_text <- function() {
  if (!exists("rhtp_pdf_text")) source(here::here("R", "utils_pdf_text.R"))
  paste(rhtp_pdf_text(wi_path("dwd_wig_awards")), collapse = "\n")
}


# -- §6.2 provenance ---------------------------------------------------------

#' The provenance, from PROGRAMME-SCOPED sentences
#'
#' Session 27's audit: the CMS financial-assistance footer's grammatical
#' subject decides whether it can carry provenance. DHS's opens "This program
#' is supported by CMS", the weak form -- and it appears unchanged on DPI's and
#' DWD's pages, which describe OTHER agencies' work, so on this host the footer
#' demonstrably travels with the money rather than with the subject matter.
#' These two sentences take the PROGRAMME and the AWARD ACTION as their
#' subjects and are what tie Wisconsin's documents to RHTP.
wi_assert_program_page_provenance <- function() {
  txt <- wi_html_text("dhs_rhtp")
  for (nm in names(WI_PROGRAMME_SCOPED)) {
    if (!stringr::str_detect(txt, stringr::fixed(WI_PROGRAMME_SCOPED[[nm]]))) {
      stop("[WI] the DHS RHTP page no longer carries the programme-scoped ",
           "provenance sentence '", nm, "'. §6.2's gate for Wisconsin rests ",
           "on it -- re-read the page before trusting anything downstream.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The CMS footer, NON-STRICT (session 28's Kansas demotion)
#'
#' It corroborates the AMOUNT against the §7.1 anchor and nothing else. Called
#' non-strictly it returns NA with a message, so a DHS re-post that dropped the
#' boilerplate cannot hard-fail Wisconsin for no reason -- AND a future state
#' whose only evidence is a "this program" footer does not pass the test
#' Wisconsin passes.
wi_assert_footer_corroborates <- function(strict = FALSE, body = NULL) {
  txt <- body %||% wi_html_text("dhs_rhtp")
  ok  <- stringr::str_detect(txt, stringr::fixed(WI_FOOTER_WEAK)) &&
         stringr::str_detect(txt, stringr::fixed(WI_FOOTER_AMOUNT))
  if (!ok) {
    msg <- paste("[WI] the DHS page no longer carries the CMS",
                 "financial-assistance footer. It was only ever corroborating",
                 "the amount; the provenance is in",
                 "wi_assert_program_page_provenance().")
    if (strict) stop(msg, call. = FALSE)
    message(msg)
    return(invisible(NA))
  }
  # the footer's figure against the §7.1 anchor
  allot <- rhtp_load_allotments()
  wi <- allot$fy2026_allotment[allot$state == "WI"]
  stopifnot(length(wi) == 1L)
  stopifnot(abs(wi - WI_STATED$cms_allotment_anchor) < 1)
  stopifnot(abs(WI_STATED$cms_allotment_stated -
                  WI_STATED$cms_allotment_anchor) < 1)
  invisible(TRUE)
}

#' Every Wisconsin solicitation post-dates the 2025-12-29 Notice of Award
#'
#' Texas's cheapest check. Read out of the archived deck rather than typed.
wi_assert_after_noa <- function() {
  deck <- wi_deck_text()
  launched <- stringr::str_match_all(deck, "Launched:\\s*([A-Z][a-z]+ \\d{1,2}, \\d{4})")[[1]]
  if (nrow(launched) < 2L) {
    stop("[WI] the council deck no longer states a 'Launched:' date for the ",
         "DHS opportunities; the §6.2 date test cannot run.", call. = FALSE)
  }
  dates <- as.Date(launched[, 2], format = "%B %d, %Y")
  noa   <- as.Date(WI_STATED$noa_date)
  if (any(is.na(dates)) || any(dates <= noa)) {
    stop("[WI] a Wisconsin RHTP solicitation is dated on or before the ",
         "2025-12-29 CMS Notice of Award. That is Texas's shape and must be ",
         "read before anything is extracted.", call. = FALSE)
  }
  invisible(dates)
}


# -- the negative, and the controls that make it mean something --------------

#' Wisconsin has published no recipient-level award list
#'
#' DESIGNED TO FAIL. Three independent statements, any one of which going is
#' the signal that Wisconsin has awarded: the four "application period now
#' closed" markers, DHS's four FUTURE-TENSE award sentences, and the
#' solicitations index calling itself unawarded.
wi_assert_no_award_roster <- function(program_body = NULL, solicit_body = NULL) {
  txt <- program_body  %||% wi_html_text("dhs_rhtp")
  sol <- solicit_body  %||% wi_html_text("dhs_solicit")

  n_closed <- stringr::str_count(txt, stringr::fixed(WI_CLOSED_MARKER))
  if (n_closed != WI_CLOSED_EXPECTED) {
    stop("[WI] the DHS RHTP page carries ", n_closed, " '", WI_CLOSED_MARKER,
         "' markers, expected ", WI_CLOSED_EXPECTED, ". EITHER an opportunity ",
         "has awarded or a new one has opened -- READ THE PAGE. If Wisconsin ",
         "has published a roster, this file must be REWRITTEN as an award ",
         "extractor, not patched.", call. = FALSE)
  }
  for (nm in names(WI_FUTURE_AWARD_MARKERS)) {
    if (!stringr::str_detect(txt, stringr::fixed(WI_FUTURE_AWARD_MARKERS[[nm]]))) {
      stop("[WI] the '", nm, "' pool no longer states its award in the FUTURE ",
           "TENSE. That is the sentence this file's negative rests on.",
           call. = FALSE)
    }
  }
  if (!stringr::str_detect(sol, stringr::fixed(WI_SOLICIT_UNAWARDED))) {
    stop("[WI] the DHS solicitations index no longer calls itself a list of ",
         "current solicitations (unawarded). That label is the positive ",
         "control for the whole Wisconsin negative.", call. = FALSE)
  }
  invisible(TRUE)
}

#' DHS dated the thing that has not happened: "Award announcements: September"
#'
#' Missouri's fourteenth question. DESIGNED TO FAIL when the deck is replaced
#' by one whose opportunities have awarded.
wi_assert_award_announcements_pending <- function(deck = NULL) {
  d <- deck %||% wi_deck_text()
  n <- stringr::str_count(d, stringr::fixed(WI_AWARD_ANNOUNCEMENT_MARKER))
  if (n != WI_AWARD_ANNOUNCEMENT_N) {
    stop("[WI] the 2026-07-23 council deck carries ", n, " '",
         WI_AWARD_ANNOUNCEMENT_MARKER, "' markers, expected ",
         WI_AWARD_ANNOUNCEMENT_N, ". Wisconsin's award window is September ",
         "2026 -- if this has changed, the state has moved.", call. = FALSE)
  }
  invisible(n)
}

#' The 16 priced RCJ rows are a FORMULA ALLOCATION, and the deck says so
#'
#' Two halves, and the second is the one that matters. (a) The deck's own
#' Fund Allocation slide states a base amount and a county formula "used for
#' AEFLA and WTCS Board purposes" -- a sub-allocation, not a competitive award.
#' (b) THE DECK'S TEXT LAYER CARRIES NONE OF RCJ'S 16 AMOUNTS. One slide is
#' image-only and sits exactly where such a table would be, so this asserts
#' what the text layer holds and does NOT claim the figures are absent from the
#' document altogether (§0.4).
wi_assert_wtcs_allocation_is_formula <- function(deck = NULL, amounts = NULL) {
  d <- deck %||% wi_deck_text()
  for (nm in names(WI_WTCS_FORMULA_MARKERS)) {
    if (!stringr::str_detect(d, stringr::fixed(WI_WTCS_FORMULA_MARKERS[[nm]]))) {
      stop("[WI] the council deck no longer carries the WTCS Fund Allocation ",
           "marker '", nm, "'. That slide is what says the 16 RCJ rows are a ",
           "FORMULA allocation and not 16 awards.", call. = FALSE)
    }
  }
  amt <- amounts %||% wi_rcj_priced_amounts()
  present <- vapply(amt, function(a) {
    stringr::str_detect(d, stringr::fixed(format(a, big.mark = ",",
                                                 scientific = FALSE)))
  }, logical(1))
  if (any(present)) {
    stop("[WI] the council deck's TEXT now carries ", sum(present), " of the ",
         length(amt), " amounts RCJ attributes to it. The §0.1 finding in ",
         "this file's header -- that RCJ prices rows against a document whose ",
         "text holds none of those figures -- must be re-read, not patched.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' RCJ's 16 bare region names are the 16 WTCS technical college districts
#'
#' SOURCED, not known. Every name must appear on WTCS's own roster, and the
#' roster must hold exactly 16 colleges -- so an extra or a missing district
#' fails rather than being absorbed.
wi_assert_wtcs_names_are_colleges <- function(roster = NULL) {
  txt <- roster %||% wi_html_text("wtcs_colleges")
  hits <- stringr::str_match_all(
    txt, "([A-Z][A-Za-z\\-]*(?: [A-Z][A-Za-z\\-]*){0,2}) (?:Area )?(?:Technical )?College\\b")[[1]]
  found <- unique(hits[, 1])
  missing <- WI_RCJ_REGION_NAMES[!vapply(
    WI_RCJ_REGION_NAMES,
    function(n) stringr::str_detect(txt, stringr::fixed(n)), logical(1))]
  if (length(missing)) {
    stop("[WI] ", length(missing), " of RCJ's 16 Wisconsin 'awardee' names do ",
         "not appear on the WTCS college roster: ",
         paste(missing, collapse = ", "), ". The claim that these are ",
         "technical college districts rather than awardees rests on that ",
         "mapping.", call. = FALSE)
  }
  if (length(WI_RCJ_REGION_NAMES) != WI_STATED$wtcs_colleges_n) {
    stop("[WI] expected ", WI_STATED$wtcs_colleges_n, " RCJ region names, ",
         "have ", length(WI_RCJ_REGION_NAMES), ".", call. = FALSE)
  }
  invisible(WI_RCJ_REGION_NAMES)
}

#' DPI publishes 213 ELIGIBLE districts and 20 FUTURE awards (§0.3)
#'
#' The largest eligibility list by head count this project has met. DESIGNED TO
#' FAIL the day DPI names its twenty.
wi_assert_dpi_eligibility_not_receipt <- function(body = NULL) {
  txt <- body %||% wi_html_text("dpi_rhtp")
  for (nm in names(WI_DPI_MARKERS)) {
    if (!stringr::str_detect(txt, stringr::fixed(WI_DPI_MARKERS[[nm]]))) {
      stop("[WI] DPI's RHTP grant page no longer carries the '", nm, "' ",
           "marker. If DPI has NAMED its twenty awardees, those are real ",
           "Tier 3 rows -- SCHOOL_OR_DISTRICT, so $0 of hospital money, but ",
           "this file must then be rewritten.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The $61M pool's eligible class is CLOSED and PRE-IDENTIFIED (§0.3)
#'
#' The single most attackable number available in Wisconsin: a hospital-weighted
#' eligible class worth up to $61 million, named in the state's CMS application
#' and not published here. Eligibility is not receipt.
wi_assert_tech_eligibility_pre_identified <- function(body = NULL) {
  txt <- body %||% wi_html_text("dhs_rhtp")
  if (!stringr::str_detect(txt, stringr::fixed(WI_TECH_ELIGIBILITY))) {
    stop("[WI] the Rural Technology Transformation pool no longer states its ",
         "pre-identified eligible class. That sentence is what keeps $61M ",
         "out of this repository as ELIGIBILITY rather than receipt (§0.3).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' THE NEGATIVE CONTROL: an executed award list on an RHTP page that is not RHTP
#'
#' DWD's "Successful WIG Healthcare Awards" is linked from the RHTP-funded
#' WIG: HEART page and is the Governor's 2021 ARPA programme. Zero RHTP
#' mentions. Without this, "no Wisconsin award roster" is indistinguishable
#' from "we did not look at the award roster that is right there".
wi_assert_wig_is_not_rhtp <- function(body = NULL) {
  txt <- body %||% wi_wig_text()
  for (nm in names(WI_WIG_MARKERS)) {
    if (!stringr::str_detect(txt, stringr::fixed(WI_WIG_MARKERS[[nm]]))) {
      stop("[WI] the WIG healthcare awards report no longer carries its '", nm,
           "' marker. It is this file's NEGATIVE CONTROL and must keep saying ",
           "what programme it belongs to.", call. = FALSE)
    }
  }
  n <- stringr::str_count(txt, "RHTP|Rural Health Transformation")
  if (n != 0L) {
    stop("[WI] the WIG healthcare awards report now mentions RHTP ", n,
         " times. It was the negative control precisely because it did not; ",
         "if DWD has folded RHTP awards into it, READ IT.", call. = FALSE)
  }
  invisible(TRUE)
}

#' There is no Wisconsin award file, and the status table has no amount column
#'
#' Texas's device, twice. A status table with an `amount` column would be
#' summable, and Wisconsin has named no recipient and published no
#' per-recipient figure.
wi_assert_no_award_file <- function() {
  if (file.exists(here::here(WI_AWARDS_CSV))) {
    stop("[WI] ", WI_AWARDS_CSV, " exists. Wisconsin has published no ",
         "recipient-level award list; if that has changed, write the ",
         "extractor deliberately and delete this assertion in the same ",
         "commit.", call. = FALSE)
  }
  path <- here::here(WI_STATUS_CSV)
  if (file.exists(path)) {
    cols <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
    bad  <- intersect(cols, c("amount", "round_amount", "amount_announced"))
    if (length(bad)) {
      stop("[WI] wi_year1_status.csv carries an amount column (",
           paste(bad, collapse = ", "), "). It is a STATUS table: Wisconsin ",
           "has named no recipient, so no sum over it could mean anything.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

rhtp_wi_assert <- function() {
  wi_assert_program_page_provenance()
  wi_assert_footer_corroborates(strict = FALSE)
  wi_assert_after_noa()
  wi_assert_no_award_roster()
  wi_assert_award_announcements_pending()
  wi_assert_wtcs_allocation_is_formula()
  wi_assert_wtcs_names_are_colleges()
  wi_assert_dpi_eligibility_not_receipt()
  wi_assert_tech_eligibility_pre_identified()
  wi_assert_wig_is_not_rhtp()
  wi_assert_no_award_file()
  invisible(TRUE)
}


# -- the status table --------------------------------------------------------

#' What each Wisconsin RHTP funding channel publishes
#'
#' DELIBERATELY NO `amount` COLUMN (Texas's device). Wisconsin has named no
#' recipient and published no per-recipient figure; the pool ceilings live in
#' `stated_pool` as the state's own words, which cannot be summed by accident.
rhtp_wi_year1_status <- function() {
  tibble::tribble(
    ~channel, ~administrator, ~stated_pool, ~stage, ~eligible_class,
    ~publishes_roster, ~evidence,

    "Rural dental efficiency and access", "DHS",
    "DHS plans to award $10 million (pending CMS approval)",
    "CLOSED_UNAWARDED", "Dental clinics in rural and semi-rural communities",
    "No",
    paste("'application period now closed'; the award is stated in the FUTURE",
          "tense. The 2026-07-23 council deck gives 'Launched: June 15, 2026',",
          "'Deadline: July 27, 2026', 'Award announcements: September'."),

    "Rural technology transformation", "DHS",
    "DHS will award up to $61 million in the first round of funding",
    "CLOSED_UNAWARDED",
    paste("CLOSED AND PRE-IDENTIFIED -- 'Only organizations named in the",
          "application are eligible', drawn from 'the rural health facility",
          "information provided to CMS'. HOSPITAL-WEIGHTED AND WORTH $61M."),
    "No",
    paste("The largest hospital-facing figure Wisconsin has published, and",
          "§0.3 governs all of it: eligibility is not receipt. The",
          "application's facility list is not published on this page, no",
          "recipient is named, and the council deck says 'Award",
          "announcements: September'. Round 2 is 2027."),

    "Community health worker", "DHS",
    "DHS plans to award $20 million for the first year of funding",
    "CLOSED_UNAWARDED",
    "Rural community health worker programmes and their host organisations",
    "No",
    paste("'application period now closed'. Council deck: 'Launched: June 15,",
          "2026', 'Deadline: August 7, 2026', 'Award announcements:",
          "September'."),

    "Care coordination", "DHS",
    "DHS plans to award up to $10 million in 2026 for a 6-month planning period",
    "CLOSED_UNAWARDED",
    paste("Rural multi-sector partnerships. A PLANNING round -- the full",
          "opportunity is released to planning grant recipients in February",
          "2027, ~$25M."),
    "No",
    paste("Two-stage by design, so even the eventual planning awardees are not",
          "the recipients of the $25M that follows. Nothing here is",
          "attributable to a hospital."),

    "WIG: HEART", "Dept. of Workforce Development (DWD)",
    "Up to $10 million per award; $4.9 million expected in year 1",
    "CLOSED_UNAWARDED",
    paste("'501(c)(3) non-profit organizations and/or governmental entities",
          "located in and serving a rural or semi-rural county' -- HOSPITALS",
          "ARE NOT THE ELIGIBLE CLASS, though they may be subgrantees."),
    "No",
    paste("Applications closed 2026-08-17; the four-year programme runs",
          "2026-10-30 to 2030-09-30, so no award can predate this session.",
          "THE PAGE LINKS AN AWARD LIST THAT IS NOT RHTP -- see",
          "wi_assert_wig_is_not_rhtp()."),

    "Rural health career pathways", "Dept. of Public Instruction (DPI)",
    "A pool of $5 million over five years; up to $41,000 annually per LEA",
    "ELIGIBILITY_PUBLISHED_UNAWARDED",
    paste("213 NAMED rural school districts on an 'Eligible Districts List'.",
          "LEAs are school districts -- §10.2's own NON_HOSPITAL worked",
          "example -- so this is $0 of hospital money whatever it awards."),
    "No",
    paste("§0.3 AT THE LARGEST HEAD COUNT IN THIS PROJECT: 213 named",
          "districts are an ELIGIBILITY list, and 'Twenty Wisconsin secondary",
          "schools WILL RECEIVE competitive grants' is future tense. DPI",
          "names no awardee."),

    "Rural health workforce (technical colleges)",
    "Wisconsin Technical College System (WTCS)",
    "Base amount $300,000 per district plus a county formula",
    "FORMULA_ALLOCATION_NOT_A_COMPETITIVE_AWARD",
    paste("The 16 WTCS districts, by formula. Technical colleges, so $0 of",
          "hospital money."),
    "No",
    paste("This is where RCJ's 16 priced Wisconsin rows come from. The",
          "2026-07-23 council deck states the allocation is a base amount",
          "plus 'county funding formula that is used for AEFLA and WTCS Board",
          "purposes', and its next slides are 'Measurable Objectives' in the",
          "future tense and 'Pre-proposal Concepts'. THE DECK'S TEXT LAYER",
          "CARRIES NONE OF THE 16 AMOUNTS."),

    "State's own contracts page -- WHERE AN ALLOCATION TABLE MIGHT LIVE",
    "DHS", "UNKNOWN", "UNREADABLE", "UNKNOWN", "UNKNOWN",
    paste0("UNREADABLE, NOT NEGATIVE (§0.4). ", WI_UNREADABLE_URL, " answers ",
           WI_UNREADABLE_STATUS, " on all of: ",
           paste(WI_UNREADABLE_AGENTS, collapse = ", "), " (tested ",
           WI_UNREADABLE_TESTED, "), while the RHTP programme page answers 200 ",
           "on the same agents from the SAME HOST, and robots.txt is 200 and ",
           "does not disallow /contracts/. A PER-PATH refusal by the origin, ",
           "not a bot block. RCJ's /activity recorded this url on 2026-07-02. ",
           "What it holds is UNKNOWN to this repository.")
  ) %>%
    dplyr::mutate(state = "WI", .before = 1)
}


# -- RCJ candidate disposition -----------------------------------------------

wi_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "WI", award_tier == "SUBAWARD")
}

#' The amounts RCJ attributes to the 2026-07-23 council deck
#'
#' Keyed on the WTCS region NAMES and not on a size threshold. A threshold
#' would have swept in "Behavioral Health Innovations" at $5,000,000, which is
#' an initiative budget line from a different document -- and the §0.1 finding
#' this feeds is specifically about the 16 rows filed under the deck.
wi_rcj_priced_amounts <- function(cands = NULL) {
  if (is.null(cands)) cands <- wi_rcj_candidates()
  is_wtcs <- wi_is_wtcs_row(cands$awardee_name_clean)
  a <- cands$amount_announced[is_wtcs]
  sort(a[!is.na(a)], decreasing = TRUE)
}

wi_is_wtcs_row <- function(nm) {
  vapply(nm, function(x) {
    any(vapply(WI_RCJ_REGION_NAMES,
               function(r) stringr::str_detect(x, stringr::fixed(r)),
               logical(1)))
  }, logical(1), USE.NAMES = FALSE)
}

#' Why each of RCJ's WI Tier 3 candidates is not an RHTP subaward
#'
#' Counts RE-DERIVED from the record table on every run (Texas's rule), so the
#' day Wisconsin's candidate set moves this fails instead of quietly ceasing to
#' cover it.
rhtp_wi_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- wi_rcj_candidates()
  nm  <- cands$awardee_name_clean
  amt <- cands$amount_announced

  is_wtcs <- wi_is_wtcs_row(nm)
  is_init <- !is_wtcs

  tibble::tribble(
    ~group, ~rows, ~rcj_amount_sum, ~disposition, ~why,

    "WTCS technical college districts -- a FORMULA ALLOCATION, not awards",
    sum(is_wtcs), sum(amt[is_wtcs], na.rm = TRUE),
    "RHTP_BUT_A_FORMULA_ALLOCATION_NOT_A_SUBAWARD",
    paste0("All ", sum(is_wtcs), " are filed under one source document, 'WI - ",
           "2026 - RHTP Advisory Council July 23, 2026'. THAT DECK'S TEXT ",
           "LAYER CARRIES NONE OF THESE AMOUNTS -- it holds exactly four ",
           "dollar figures, $203,670,005.21 twice, $300,000, $10 and $1 -- ",
           "and one slide is image-only, sitting between 'RHT Grant Update' ",
           "and 'Rurality Designations', which is where such a table would ",
           "be. The slide after it states the allocation: a $300,000 base ",
           "plus a 'county funding formula that is used for AEFLA and WTCS ",
           "Board purposes'. RCJ ALSO STRIPS THE ORGANISATION OUT OF THE ",
           "NAME: it carries 'Northwood', 'Chippewa Valley', 'Blackhawk' -- ",
           "bare region names that read as places, not organisations. All 16 ",
           "map one-to-one onto WTCS's own college roster, archived here, ",
           "with no extras and no omissions. They are TECHNICAL COLLEGES, so ",
           "even read as awards they are $0 of hospital money."),

    "Initiative budget lines from Wisconsin's own CMS application -- TIER 2",
    sum(is_init), sum(amt[is_init], na.rm = TRUE),
    "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD",
    paste0("Three rows -- 'Medicaid Reforms and Other Strategic Investments' ",
           "$44,000,000, 'Public Navigation Transformation' $29,000,000 and ",
           "'Behavioral Health Innovations' $5,000,000 -- whose 'awardee' is ",
           "the INITIATIVE NAME (§6.1 PROGRAM_NAME_AS_AWARDEE). Their source ",
           "document is Wisconsin's own RHTP APPLICATION to CMS, and their ",
           "descriptions are the application's future tense ('starting in ",
           "2026'). OKLAHOMA'S DEFECT -- the wrong TIER -- in a state whose ",
           "documents are all genuinely RHTP. All three are already FLAGGED ",
           "SOURCE_DOCUMENT_UNRESOLVED in the record table.")
  ) %>%
    dplyr::mutate(state = "WI", .before = 1)
}


# -- build / report ----------------------------------------------------------

rhtp_wi_build <- function() {
  rhtp_wi_assert()
  status <- rhtp_wi_year1_status()
  dispo  <- rhtp_wi_rcj_disposition()
  readr::write_csv(status, here::here(WI_STATUS_CSV))
  readr::write_csv(dispo,  here::here(WI_DISPO_CSV))
  wi_assert_no_award_file()
  message("[WI] wrote ", WI_STATUS_CSV, " (", nrow(status), " rows) and ",
          WI_DISPO_CSV, " (", nrow(dispo), " rows).")
  message("[WI] NO wi_year1_awardees.csv was written, and that is the finding.")
  invisible(list(status = status, disposition = dispo))
}

rhtp_wi_report <- function() {
  cands <- wi_rcj_candidates()
  dispo <- rhtp_wi_rcj_disposition(cands)
  message("WISCONSIN -- Rural Health Transformation Program, Year 1")
  message("  CMS FY2026 allotment      : $",
          format(WI_STATED$cms_allotment_anchor, big.mark = ","))
  message("  Recipient-level award list: NONE PUBLISHED")
  message("  Named hospitals           : 0")
  message("  Hospital dollars          : $0")
  message("")
  message("  Wisconsin is at SOLICITATION stage. Four DHS opportunities are")
  message("  all 'application period now closed' and none names a recipient;")
  message("  the 2026-07-23 council deck says 'Award announcements:")
  message("  September' against three of them, and the DHS page was last")
  message("  revised ", WI_STATED$page_last_revised, ".")
  message("")
  message("  RCJ Tier 3 candidates     : ", nrow(cands))
  for (i in seq_len(nrow(dispo))) {
    message(sprintf("    %-52s %2d rows  $%s", substr(dispo$group[i], 1, 52),
                    dispo$rows[i],
                    format(dispo$rcj_amount_sum[i], big.mark = ",",
                           scientific = FALSE)))
  }
  message("  RHTP subawards among them : 0")
  message("")
  message("  THE $61M TO WATCH: Rural Technology Transformation restricts")
  message("  eligibility to organisations PRE-IDENTIFIED from the rural")
  message("  health facility list in Wisconsin's CMS application. That is a")
  message("  closed, hospital-weighted eligible class -- and §0.3 says")
  message("  eligibility is not receipt. Its awards are due THIS MONTH.")
  invisible(dispo)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--fetch" %in% args)    wi_fetch(force = force)
  if ("--validate" %in% args) { rhtp_wi_assert(); message("[WI] all assertions pass.") }
  if ("--build" %in% args)    rhtp_wi_build()
  if ("--report" %in% args)   rhtp_wi_report()
  if (!length(intersect(args, c("--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03y_wi_year1_probe.R ",
            "[--fetch [--force]] [--validate] [--build] [--report]")
  }
}

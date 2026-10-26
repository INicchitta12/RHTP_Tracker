#!/usr/bin/env Rscript
# 03am_id_year1_awardees.R ---------------------------------------------------
#
# IDAHO -- ONE NAMED AWARDEE, NO AMOUNT, AND ELEVEN OPEN OPPORTUNITIES BEHIND
# IT.
#
# Idaho holds $185,974,368 (§7.1). Its Department of Health and Welfare
# publishes a funding-opportunities page that names exactly ONE awardee, in a
# single line under "Closed funding opportunities":
#
#   "CLOSED 7/10/26: Maternal and Child Health Initiatives
#    Awardee: Comagine Health
#    Perinatal Quality Collaborative OB Readiness
#    Anticipated award start date: Aug. 14, 2026"
#
# ONE AWARD ACTION, NO DOLLAR FIGURE, AND NO HOSPITAL. Nevada's shape at the
# smallest scale there is, and unlike Nevada, Delaware, Iowa or North Carolina
# the single named recipient is not a hospital either -- so Idaho contributes
# ONE ROW AND $0 TO NO BUCKET AT ALL. That is Maine's and Missouri's outcome
# reached by a third route.
#
# THE AWARD IS AN INTENT, IN IDAHO'S OWN WORDS. "Anticipated award start date"
# is a future tense about a contract that has not started, so the row is
# `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No` -- Oregon's, Maryland's
# and Arkansas's posture. The date itself has since passed (2026-08-14), which
# is recorded and is NOT evidence that the contract executed.
#
# THE SHARED CLASSIFIER HANDLES THIS STATE WITHOUT AN OVERRIDE, WHICH IS WORTH
# SAYING BESIDE DELAWARE. `rhtp_classify_recipient_type("Comagine Health")`
# returns §8's standing fallback -- `NONPROFIT_CBO` + LOW +
# `RECIPIENT_TYPE_INFERRED` -- and that is the RIGHT answer here rather than a
# miss, because IDAHO STATES NO FORM: the page gives a name, a programme and a
# date and nothing else. Delaware's three recipients get the same machine
# answer and it is wrong there, because the spec names them as hospitals. The
# difference is not the classifier; it is whether a governing document states
# the form.
#
# §6.2: THE FOOTER IS THE WEAKEST SUBJECT THIS PROJECT HAS MET AND ITS FIGURE
# IS THE ALLOTMENT. "**This website** is supported by ... a financial
# assistance award totaling $185,974,367.81 with 100 percent funded by
# CMS/HHS" -- session 27's weak form with a new subject noun (previous ones
# were "This publication", "This presentation", "This project", "This
# program"), and its number is Tier 1 against the anchor's $185,974,368. So the
# footer corroborates the AMOUNT and the provenance is carried by the page's
# own scope: it is DHW's Rural Health Transformation Program funding page and
# every opportunity on it is titled RHTP.
#
# WHAT IDAHO IS ABOUT TO DO IS THE REASON FOR THE PROBE. The same page lists
# ELEVEN open or recently posted opportunities with vendor conferences
# scheduled into early September 2026 -- Healthcare Infrastructure Support,
# Healthcare Career Advancement, School-Based Family Support Hubs, Chronic
# Disease Prevention and Cancer Screening, Diabetes Prevention and Management,
# Crisis Intervention Training and more -- plus three cooperative-agreement
# contracts. Idaho is the most active of the fourteen low-candidate states and
# the likeliest of them to name more recipients soon.
#
# §0.1: RCJ CARRIES ONE IDAHO TIER 3 CANDIDATE AND ITS NAME IS CORRUPTED.
# "Co-Imagine Health", at $1, with NO source document at all. No organisation
# of that name exists and Comagine Health is the only awardee Idaho names, so
# it is evidently the same body under a mangled name -- BUT NO DOCUMENT SAYS
# SO, and that match is this project's reading rather than a source's (§0.4).
# It does not matter here: this file's row is built from the STATE PAGE, whose
# spelling is "Comagine Health", and the aggregator contributes nothing to it.
#
# ONE CHANNEL IS UNREADABLE AND IS RECORDED AS UNKNOWN (§0.4). DHW routes
# documents through `publicdocuments.dhw.idaho.gov`, a Laserfiche WebLink
# repository -- a stateful application this environment cannot browse. Whether
# an executed Idaho RHTP contract sits inside it is a statement about OUR
# ACCESS, never about Idaho.
#
# ============================================================================
# SESSION 108: IDAHO PUBLISHED ITS ROSTER, AND THIS FILE NOW WRITES IT.
# ============================================================================
# DHW's funding page (updated 10-21-2026) heads the section "Closed and awarded
# funding opportunities" and links "See the list of awardees as of Oct. 16"
# (Idaho-RHTP_List of Awardees dated 10192026.xlsx, archived under
# data/evidence/recheck/2026-10-26/ID/). The "Awardee: Comagine Health" line is
# gone: Comagine is now two priced lines on the list. Everything above this
# block describes the page as it stood before; R/03ck_id_roster_awardees.R
# reads the list and types it, and id_year1_awardees() returns its 112 award
# lines (the two inter-agency MOA/MOU lines are status rows, Vermont's GMCB
# footing). The probe is rewritten as a ROSTER WATCH (standing rule: a watched
# state that awards gets its probe rewritten, never patched): it trips when the
# funding page links a list other than the one extracted, or names an
# organisation the re-based page did not. The funding and about pages were
# re-based to the 2026-10-26 copies after reading the diff (only the "Closed
# and awarded" heading, the list link and the closed-opportunity titles moved;
# the about page added two link labels).
#
# Usage:
#   Rscript R/03am_id_year1_awardees.R --fetch [--force] | --validate |
#           --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "03ck_id_roster_awardees.R"))

ID_STATE     <- "ID"
ID_ALLOTMENT <- 185974368        # cms_fy2026_allotments.csv (§7.1)
ID_FOOTER    <- 185974367.81     # "This website is supported by ..." -- Tier 1
ID_CLOSED    <- as.Date("2026-07-10")
ID_START     <- as.Date("2026-08-14")   # "Anticipated award start date"
ID_NOA_DATE  <- as.Date("2025-12-29")

ID_EVIDENCE_DIR <- here::here("data", "evidence", "ID")
ID_CSV        <- here::here("data", "reference", "id_year1_awardees.csv")
ID_STATUS_CSV <- here::here("data", "reference", "id_year1_status.csv")
ID_DISPO_CSV  <- here::here("data", "reference",
                            "id_rcj_candidate_disposition.csv")

ID_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

ID_BASE <- paste0("https://healthandwelfare.idaho.gov/providers/",
                  "rural-health-transformation-program-grant/")

ID_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "funding", paste0(ID_BASE, "funding-opportunities-rural-health"),
  "2026-10-26_id_rhtp_funding_opportunities.html",
  paste("THE WATCH (re-based session 108). Links DHW's list of awardees as of",
        "Oct. 16; the 2026-09-03 copy, which named Comagine Health alone, stays."),
  "about", paste0(ID_BASE, "about-rural-health-transformation-program-grant"),
  "2026-10-26_id_rhtp_about.html",
  paste("DHW's RHTP programme page -- the scope that carries the provenance",
        "the weak 'This website' footer does not.")
)

id_source <- function(key, field) {
  row <- ID_SOURCES[ID_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[ID] unknown source key: ", key, call. = FALSE)
  row[[field]]
}
id_path <- function(key) file.path(ID_EVIDENCE_DIR, id_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

id_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(ID_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[ID] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

id_fetch <- function(force = FALSE) {
  dir.create(ID_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(ID_SOURCES)), function(i) {
    src <- ID_SOURCES[i, ]
    dest <- file.path(ID_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[ID] have ", src$file)
    } else {
      raw <- id_get(src$url, src$key)
      txt <- rawToChar(raw[raw != as.raw(0)]); Encoding(txt) <- "bytes"
      if (grepl("[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[0-9A-Za-z_-]{30,}", txt,
                useBytes = TRUE, perl = TRUE)) {
        stop("[ID] ", src$key, " carries a credential-shaped string; NOT ",
             "written.", call. = FALSE)
      }
      writeBin(raw, dest)
      message("[ID] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  writeLines(c(
    "IDAHO -- RHTP evidence archive",
    "",
    "Fetched 2026-09-03 by R/03am_id_year1_awardees.R --fetch; the two pages",
    "re-based 2026-10-26 (session 108) after reading the diff. Older copies stay.",
    "Bodies are written with writeBin(), so re-hashing reproduces the digest.",
    "",
    "THE FUNDING PAGE PRINTS ITS OWN LAST-UPDATED DATE ('Page last updated:",
    "9-3-2026'), which is a change signal the state maintains itself and is",
    "cheaper than any digest. --probe compares a CONTENT digest as well,",
    "because a page can change without its stamp moving.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")),
    file.path(ID_EVIDENCE_DIR, "MANIFEST.txt"))
  invisible(entries)
}


# -- reduction ---------------------------------------------------------------

id_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;|&#038;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;", "'")
  txt <- stringr::str_replace_all(txt, "&#8211;|&ndash;|&#8212;|&mdash;", "-")
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

id_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(id_path(key), "raw",
                                    file.size(id_path(key))) else body
  id_reduce_html(raw)
}

id_content_digest <- function(key, body = NULL) {
  digest::digest(id_html_text(key, body), algo = "sha256")
}

id_have_archive <- function() {
  all(file.exists(file.path(ID_EVIDENCE_DIR, ID_SOURCES$file)))
}


# -- assertions --------------------------------------------------------------

#' SESSION 108: the funding page links the list this file extracted, and no
#' other. A new list (a new date, a new document id) is a new roster to read.
ID_ROSTER_LINK_TEXT <- "See the list of awardees as of Oct. 16."
ID_ROSTER_DOCID <- "docid=37915"
id_assert_roster_link <- function(body = NULL) {
  txt <- stringr::str_replace_all(id_html_text("funding", body), "\\s+", " ")
  raw <- if (is.null(body)) readBin(id_path("funding"), "raw", file.size(id_path("funding"))) else body
  html <- rawToChar(raw[raw != as.raw(0)])
  ok_txt <- stringr::str_detect(txt, stringr::fixed(ID_ROSTER_LINK_TEXT))
  ok_doc <- stringr::str_detect(html, stringr::fixed(ID_ROSTER_DOCID))
  n <- stringr::str_count(txt, stringr::regex("list of awardees", ignore_case = TRUE))
  if (!ok_txt || !ok_doc || n != 1L) {
    stop("[ID] the funding page no longer links ONE list of awardees as of Oct. 16 (",
         ID_ROSTER_DOCID, "): ", n, " 'list of awardees' link(s), text ",
         if (ok_txt) "present" else "GONE", ", document id ", if (ok_doc) "present" else "GONE",
         ". DHW has posted a new roster: fetch it (WebLink needs a session cookie), set ",
         "R/03ck's IDR_FILE, rebuild and re-read the typing.", call. = FALSE)
  }
  if (stringr::str_detect(txt, stringr::fixed("Awardee: Comagine Health"))) {
    stop("[ID] the old single 'Awardee:' line is back: read the page.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Idaho prices nobody
id_assert_no_amount <- function(body = NULL) {
  txt <- id_html_text("funding", body)
  money <- stringr::str_extract_all(txt,
                                    "\\$\\s?[0-9][0-9,]*(\\.[0-9]+)?")[[1]]
  vals <- as.numeric(stringr::str_remove_all(
    stringr::str_remove_all(money, "[\\$ ]"), ","))
  if (length(vals) != 1L || abs(vals - ID_FOOTER) > 0.005) {
    stop("[ID] the funding page now carries ", length(vals),
         " currency figures (", paste(money, collapse = ", "),
         ") where it carried exactly ONE -- the allotment, in the CMS footer. ",
         "Idaho prices its awards on the linked list, not on this page; a ",
         "figure here is new and must be read.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.2: that one figure is Tier 1, driven both ways
id_assert_footer_is_the_allotment <- function(body = NULL) {
  txt <- id_html_text("funding", body)
  ok <- rhtp_assert_footer_text_tier(txt, ID_STATE, "STATE_ALLOTMENT",
                                     label = "ID funding-page CMS footer")
  if (!isTRUE(ok)) {
    message("[ID] the §0.2 tier check did not run -- a gap, not a pass (§0.4).")
    return(invisible(NA))
  }
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(ID_FOOTER, ID_STATE, "SOLICITATION",
                                     label = "ID footer read as a pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[ID] the §0.2 rule no longer refuses Idaho's allotment being read ",
         "as a pool.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The footer's SUBJECT is the weakest form this project has met
id_assert_footer_is_weak_form <- function(body = NULL) {
  txt <- stringr::str_replace_all(id_html_text("funding", body), "\\s+", " ")
  if (!stringr::str_detect(txt,
                           stringr::fixed("This website is supported by"))) {
    stop("[ID] the footer no longer opens 'This website is supported by'. ",
         "Session 27's axis is the footer's grammatical SUBJECT and Idaho's ",
         "is the weakest instance of it; if the subject has changed, re-read ",
         "what the footer now claims to cover.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2's date test
id_assert_after_noa <- function() {
  if (ID_CLOSED <= ID_NOA_DATE) {
    stop("[ID] the solicitation no longer postdates the Notice of Award.",
         call. = FALSE)
  }
  invisible(as.integer(ID_CLOSED - ID_NOA_DATE))
}

#' SESSION 108: the roster's hospital partition, pinned.
ID_ROSTER_NAMED_ROWS <- 48L
ID_ROSTER_NAMED_DOLLARS <- 85389815.69
id_assert_roster_partition <- function(awards = NULL) {
  d <- if (is.null(awards)) id_year1_awardees() else awards
  if (nrow(d) != IDR_LINES - 2L) stop("[ID] the award file is not the list's 112 non-MOA lines.", call. = FALSE)
  part <- rhtp_hospital_dollar_partition(d)
  if (!identical(part$bucket, "NAMED_HOSPITAL") || part$rows != ID_ROSTER_NAMED_ROWS ||
      abs(part$dollars - ID_ROSTER_NAMED_DOLLARS) > 0.005) {
    stop("[ID] the roster's hospital partition moved: read the change.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

id_year1_awardees <- function() id_roster_awardees()

id_status_table <- function() {
  moa <- id_roster_moas()
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    ID_STATE, "DHW list of awardees as of Oct. 16 (dated 10-19-2026)",
    "AWARDED_ROSTER_PUBLISHED", "Yes",
    paste("114 priced lines (Subrecipient 100, Contractor 12, MOA/MOU 2), $180,701,813.99 by",
          "this file's sum; the list prints no total. DHW lists them under 'Closed and awarded",
          "funding opportunities' as awardees: AWARDS, not intents or allocations; execution is",
          "not stated. 112 lines are the award file (R/03ck); the year is in the award and",
          "procurement process, so later lists may add lines."),
    ID_STATE, "Inter-agency MOA/MOU (NOT SUBAWARDS)", "INTER_AGENCY_NOT_SUBAWARD", "Yes",
    paste0(paste0(moa$awardee, " (", moa$solicitation, ")", collapse = "; "),
           ". Two memoranda between DHW and other state bodies, $",
           formatC(sum(moa$amount), format = "f", digits = 2, big.mark = ","),
           ": kept OUT of the award file on Vermont's GMCB MOU footing (owner decision, ",
           "session 54). The award lines + these = the list's sum."),
    ID_STATE, "Hospital networks and the ladder-payment administrator", "PASS_THROUGH_UNRESOLVED", "Yes",
    paste("The Hospital Cooperative (1 line), Hospital Network of Idaho (3 lines) and Public",
          "Consulting Group (Third Party Administrator for Ladder Payment Program, $14,520,000):",
          "intermediaries whose onward recipients the list does not name. Unclear, no bucket",
          "(§0.3, §10.2)."),
    ID_STATE, "publicdocuments.dhw.idaho.gov (Laserfiche)",
    "READABLE_WITH_SESSION_COOKIE", "Yes",
    paste("The list is a WebLink document: a cookie-less GET returns a 1,897-byte HTML shell,",
          "and the workbook was fetched with the session cookie WebLink sets (session 107).",
          "Other documents in it are not browsed; what they hold is UNKNOWN (§0.4).")
  )
}

id_disposition <- function() {
  rt <- rhtp_record_table_live()
  t3 <- rt %>% dplyr::filter(.data$state == ID_STATE,
                             .data$award_tier == "SUBAWARD")
  if (nrow(t3) != 1L) {
    stop("[ID] this disposition covers ONE Tier 3 candidate and the record ",
         "table now holds ", nrow(t3), ".", call. = FALSE)
  }
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    ID_STATE, "Co-Imagine Health", 1L,
    "REAL_AWARD_UNDER_A_CORRUPTED_NAME_AT_A_$1_PLACEHOLDER",
    paste0("RCJ's only Idaho Tier 3 candidate is 'Co-Imagine Health' at $1, ",
           "with NO source document at all. No organisation of that name ",
           "exists, and Comagine Health is the ONE awardee Idaho's own ",
           "funding page names -- so it is evidently the same body under a ",
           "corrupted name. THAT MATCH IS THIS PROJECT'S READING AND NOT A ",
           "SOURCE'S (§0.4, §2's ban on a machine auto-resolving a fuzzy ",
           "name), and it is recorded rather than relied on: the award rows ",
           "in id_year1_awardees.csv are built from DHW's list of awardees ",
           "(session 108), which prints 'Comagine Health' twice and 'Co Magine ",
           "Health' once, so the aggregator contributes nothing to them. The ",
           "$1 is Missouri's placeholder.")
  )
}


# -- probe / validate / build / report ---------------------------------------

# Read and judged NOT a recipient (session 52); matched EXACTLY (§2.3). On
# 2026-09-22 DHW closed every Year 1 opportunity -- "(Updated 9/22/26) All the
# funding opportunities for the first year of the Rural Health Transformation
# Program have closed" -- and re-printed each as "CLOSED <date>: <title>". The
# strings below are those OPPORTUNITY TITLES (plus the programme's own name),
# and "State Board of Education" / DHW's own typo "Sate Board of Education"
# are the PARTNER agency named inside two titles. None is an awardee: the one
# "Awardee:" line on the page is still Comagine Health. The status label
# itself is handled by the CLOSED break token in RHTP_ORG_NAME_BREAK_TOKENS.
# The about page's new string is a MEETING NOTICE for the programme's own
# implementation task force, a governance body.
ID_NAME_FURNITURE <- list(
  funding = c(
    "Rural Health Transformation Program",
    "Healthcare Infrastructure Support", "State Board of Education",
    "Statewide Chronic Disease Education Network",
    "Graduate Medical Education", "Sate Board of Education",
    "School-Based Family Support Hubs",
    "Idaho Cognitive Care Pathway Network",
    "Cognitive Health Workforce Response Network"),
  about = c(
    "Idaho Rural Health Transformation Program Implementation Task Force"))

id_probe <- function() {
  keys <- c("funding", "about")
  live <- purrr::map(keys, function(k) {
    r <- rhtp_probe_get(k, function() id_get(id_source(k, "url"), k),
                          id_path(k)); Sys.sleep(2); r
  })
  names(live) <- keys
  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(key = k,
                   archived = id_content_digest(k),
                   live = id_content_digest(k, live[[k]]))
  }) %>% dplyr::mutate(changed = .data$archived != .data$live)

  id_assert_roster_link(body = live$funding)
  id_assert_no_amount(body = live$funding)
  id_assert_footer_is_weak_form(body = live$funding)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control or a
  # press index moves for reasons that are not this state awarding.
  nm_keys <- c("funding", "about")
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(
      purrr::map(nm_keys, function(k) id_html_text(k, live[[k]])), nm_keys),
    archived = stats::setNames(purrr::map(nm_keys, id_html_text), nm_keys),
    furniture = ID_NAME_FURNITURE,
    state = "ID")

  message("[ID] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    message(sprintf("  %-9s content %s", cmp$key[i],
                    if (cmp$changed[i]) "CHANGED" else "unchanged"))
  })
  if (any(cmp$changed)) {
    message("[ID] CONTENT CHANGED. Re-read the page: the list link is unchanged, ",
            "so look for Year 2 opportunities or a second roster.")
  } else {
    message("[ID] UNCHANGED. The list of awardees as of Oct. 16 is still the one linked.")
  }
  invisible(cmp)
}

id_validate <- function() {
  if (!id_have_archive()) {
    stop("[ID] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  id_assert_roster_link()
  id_assert_no_amount()
  id_assert_footer_is_the_allotment()
  id_assert_footer_is_weak_form()
  id_assert_after_noa()
  idr_assert_roster()
  idr_assert_typing(id_year1_awardees())
  id_assert_roster_partition()
  message("[ID] all assertions pass.")
  invisible(TRUE)
}

id_build <- function() {
  d <- id_year1_awardees()
  idr_assert_roster()
  idr_assert_typing(d)
  id_assert_roster_partition(d)
  readr::write_csv(d, ID_CSV, na = "NA")
  message("[ID] wrote ", ID_CSV, " (", nrow(d), " rows)")
  st <- id_status_table()
  if ("amount" %in% names(st)) stop("[ID] status table must have no amount col")
  readr::write_csv(st, ID_STATUS_CSV)
  message("[ID] wrote ", ID_STATUS_CSV, " (", nrow(st), " rows)")
  dp <- id_disposition()
  rhtp_assert_disposition_prose(dp, "ID")
  readr::write_csv(dp, ID_DISPO_CSV)
  message("[ID] wrote ", ID_DISPO_CSV, " (", nrow(dp), " rows)")
  invisible(list(awards = d, status = st, disposition = dp))
}

id_report <- function() {
  d <- id_year1_awardees()
  m <- function(x) paste0("$", formatC(sum(x), format = "f", digits = 2, big.mark = ","))
  h <- d[d$distributed_to_hospital == "Yes", ]
  cat("\nIDAHO -- DHW's list of awardees as of Oct. 16\n", strrep("=", 46), "\n", sep = "")
  cat("Allotment (§7.1)    : $", format(ID_ALLOTMENT, big.mark = ","), "\n", sep = "")
  cat("Award lines         : ", nrow(d), ", ", m(d$amount), " (+ 2 MOA/MOU lines out of file)\n", sep = "")
  cat("NAMED_HOSPITAL      : ", nrow(h), ", ", m(h$amount), "\n", sep = "")
  cat("  LOW               : ", sum(h$determination_confidence == "LOW"), ", ",
      m(h$amount[h$determination_confidence == "LOW"]), "\n", sep = "")
  cat("  system parents    : ", m(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"]), "\n", sep = "")
  cat("Unclear (no bucket) : ", m(d$amount[d$distributed_to_hospital == "Unclear"]), "\n", sep = "")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) id_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) id_validate()
  if ("--build" %in% args) id_build()
  if ("--probe" %in% args) rhtp_probe_run("ID", id_probe())
  if ("--report" %in% args) id_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}

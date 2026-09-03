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
# Usage:
#   Rscript R/03am_id_year1_awardees.R --fetch [--force] | --validate |
#           --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

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
  "2026-09-03_id_rhtp_funding_opportunities.html",
  paste("THE AWARD SOURCE AND THE WATCH. Names Comagine Health as the ONE",
        "awardee, with no amount, and lists eleven further opportunities."),
  "about", paste0(ID_BASE, "about-rural-health-transformation-program-grant"),
  "2026-09-03_id_rhtp_about.html",
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
    "Fetched 2026-09-03 by R/03am_id_year1_awardees.R --fetch.",
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

#' Idaho names Comagine Health, and names nobody else
id_assert_one_awardee <- function(body = NULL) {
  txt <- stringr::str_replace_all(id_html_text("funding", body), "\\s+", " ")
  want <- paste("CLOSED 7/10/26: Maternal and Child Health Initiatives",
                "Awardee: Comagine Health Perinatal Quality Collaborative",
                "OB Readiness Anticipated award start date: Aug. 14, 2026")
  if (!stringr::str_detect(txt, stringr::fixed(want))) {
    stop("[ID] the funding page no longer carries Idaho's one award line in ",
         "the form this file records. Read it -- either the award changed or ",
         "Idaho named more.", call. = FALSE)
  }
  n <- stringr::str_count(txt, stringr::fixed("Awardee:"))
  if (n != 1L) {
    stop("[ID] the funding page now carries ", n, " 'Awardee:' lines where it ",
         "carried ONE. Idaho has named more recipients -- read the page; ",
         "id_year1_awardees.csv is a hand-read single row and nothing else ",
         "updates it.", call. = FALSE)
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
         "If Idaho has priced its award, this file must be REWRITTEN: its ",
         "empty amount column is a finding.", call. = FALSE)
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

#' One row, no dollars, and NO bucket at all
id_assert_contributes_no_bucket <- function(awards = NULL) {
  d <- if (is.null(awards)) id_year1_awardees() else awards
  stopifnot(nrow(d) == 1L, all(is.na(d$amount)))
  part <- rhtp_hospital_dollar_partition(d)
  if (nrow(part) != 0L) {
    stop("[ID] Idaho now contributes to a hospital bucket. Its one named ",
         "recipient is a nonprofit whose form Idaho does not state, so it ",
         "should contribute to none -- read the change.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

id_year1_awardees <- function() {
  cls <- rhtp_classify_recipient_type("Comagine Health", ID_STATE)
  tibble::tibble(
    state = ID_STATE,
    row_no = 1L,
    awardee = "Comagine Health",
    amount = NA_real_,
    recipient_type = cls$recipient_type,
    distributed_to_hospital = "No",
    note = paste(
      "Maternal and Child Health Initiatives; Perinatal Quality Collaborative",
      "OB Readiness. Solicitation closed 2026-07-10; 'Anticipated award start",
      "date: Aug. 14, 2026'. NO AMOUNT PUBLISHED -- Idaho's funding page",
      "carries exactly one currency figure and it is the state allotment."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste(
      "Funding opportunities | Rural Health Transformation Program |",
      "Idaho Department of Health and Welfare"),
    state_source_url = id_source("funding", "url"),
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03am_id_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste(
      "NOT STATED BY THE SOURCE. Idaho publishes a name, a programme and a",
      "date and nothing about the recipient's organisational form, so §8's",
      "standing answer applies -- and here it is the right answer rather than",
      "a miss (contrast Delaware, where the spec states the form and the",
      "classifier's fallback is wrong)."),
    determination_confidence = cls$determination_confidence,
    flag_reason = "RECIPIENT_TYPE_INFERRED;AMOUNT_PRELIMINARY",
    award_pool = "Maternal and Child Health Initiatives",
    budget_period = "Budget Period 1",
    flow_type = "NON_HOSPITAL",
    hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste(
      "§10.2 NON_HOSPITAL on the RECIPIENT (§0.3a): Comagine Health is a named",
      "organisation that is not a hospital, and Idaho publishes no",
      "organisation type for it. THE ACTIVITY IS NOT THE CODE -- a Perinatal",
      "Quality Collaborative is the kind of body that works WITH birthing",
      "hospitals, and Idaho's page says nothing whatever about money reaching",
      "one, so IN_KIND_BENEFIT is not supported either (§10.2 requires the",
      "source to show hospitals using what the recipient delivers, and the",
      "source here is a single line). hospital_benefiting is Unclear rather",
      "than No for that reason and it moves no figure. AMOUNT IS EMPTY",
      "because Idaho published none; the award is an INTENT because 'award",
      "start date' is Idaho's own future tense."),
    amount_basis = paste(
      "NOT PUBLISHED. Idaho names the awardee and no figure. The only",
      "currency on the page is the $185,974,367.81 CMS footer, which is the",
      "STATE ALLOTMENT (§0.2) and must never be read as this award."),
    round_amount = NA_real_,
    solicitation_closed = ID_CLOSED,
    anticipated_start = ID_START,
    source_archive_path = file.path("data", "evidence", "ID",
                                    id_source("funding", "file")))
}

id_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    ID_STATE, "Maternal and Child Health Initiatives",
    "AWARDED_ONE_NAMED_NO_AMOUNT", "Yes - ONE NAME, NO FIGURE",
    paste("Closed 2026-07-10. 'Awardee: Comagine Health'. The only award",
          "Idaho has named."),
    ID_STATE, "Open and recently posted opportunities (11)",
    "OPEN_OR_PRE_AWARD", "No",
    paste("Healthcare Infrastructure Support, Healthcare Career Advancement,",
          "School-Based Family Support Hubs, Chronic Disease Prevention and",
          "Cancer Screening, Idaho Cognitive Care Pathway Network, Cognitive",
          "Health Workforce Response Network, Diabetes Prevention and",
          "Management, Crisis Intervention Training, Behavioral Health",
          "Prevention, Statewide Chronic Disease Education Network and more,",
          "with vendor conferences into early September 2026. THE MOST ACTIVE",
          "OF THE FOURTEEN LOW-CANDIDATE STATES."),
    ID_STATE, "Closed opportunities awaiting an awardee (4)",
    "CLOSED_NO_AWARDEE_NAMED", "No",
    paste("Technology Assessment RFP (8/21), Third Party Administrator -",
          "Ladder Payments (8/17), Pediatric Psychiatry Access Line (8/17),",
          "Facility Renovation Independent Verification (8/5). All closed,",
          "none naming a recipient."),
    ID_STATE, "Cooperative agreements (3)", "PROCUREMENT_CHANNEL", "No",
    paste("Data Analytics and Outcomes Evaluation, Rural Cybersecurity",
          "Modernization Assessment, Project Management Support. DHW uses",
          "cooperative contract procurement for these, so awards may surface",
          "in a procurement channel rather than here (Indiana's lesson)."),
    ID_STATE, "publicdocuments.dhw.idaho.gov (Laserfiche)",
    "UNREADABLE", "UNKNOWN",
    paste("A stateful WebLink document repository this environment cannot",
          "browse. Whether an executed contract sits inside it is a statement",
          "about OUR ACCESS, never about Idaho (§0.4).")
  )
}

id_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
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
           "name), and it is recorded rather than relied on: the award row ",
           "in id_year1_awardees.csv is built from the STATE PAGE, whose ",
           "spelling is 'Comagine Health', so the aggregator contributes ",
           "nothing to it either way. The $1 is Missouri's placeholder.")
  )
}


# -- probe / validate / build / report ---------------------------------------

id_probe <- function() {
  keys <- c("funding", "about")
  live <- purrr::map(keys, function(k) {
    r <- id_get(id_source(k, "url"), k); Sys.sleep(2); r
  })
  names(live) <- keys
  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(key = k,
                   archived = id_content_digest(k),
                   live = id_content_digest(k, live[[k]]))
  }) %>% dplyr::mutate(changed = .data$archived != .data$live)

  id_assert_one_awardee(body = live$funding)
  id_assert_no_amount(body = live$funding)
  id_assert_footer_is_weak_form(body = live$funding)

  message("[ID] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    message(sprintf("  %-9s content %s", cmp$key[i],
                    if (cmp$changed[i]) "CHANGED" else "unchanged"))
  })
  if (any(cmp$changed)) {
    message("[ID] CONTENT CHANGED. Idaho has eleven opportunities in flight; ",
            "re-read the page for a second 'Awardee:' line.")
  } else {
    message("[ID] UNCHANGED. Still one named awardee and no amount.")
  }
  invisible(cmp)
}

id_validate <- function() {
  if (!id_have_archive()) {
    stop("[ID] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  id_assert_one_awardee()
  id_assert_no_amount()
  id_assert_footer_is_the_allotment()
  id_assert_footer_is_weak_form()
  id_assert_after_noa()
  id_assert_contributes_no_bucket()
  message("[ID] all assertions pass.")
  invisible(TRUE)
}

id_build <- function() {
  d <- id_year1_awardees()
  id_assert_contributes_no_bucket(d)
  readr::write_csv(d, ID_CSV)
  message("[ID] wrote ", ID_CSV, " (", nrow(d), " rows)")
  st <- id_status_table()
  if ("amount" %in% names(st)) stop("[ID] status table must have no amount col")
  readr::write_csv(st, ID_STATUS_CSV)
  message("[ID] wrote ", ID_STATUS_CSV, " (", nrow(st), " rows)")
  dp <- id_disposition()
  readr::write_csv(dp, ID_DISPO_CSV)
  message("[ID] wrote ", ID_DISPO_CSV, " (", nrow(dp), " rows)")
  invisible(list(awards = d, status = st, disposition = dp))
}

id_report <- function() {
  d <- id_year1_awardees()
  cat("\nIDAHO -- one named awardee, no amount, no hospital\n")
  cat(strrep("=", 52), "\n\n")
  cat("Allotment (§7.1)      : $", format(ID_ALLOTMENT, big.mark = ","), "\n",
      sep = "")
  cat("Award actions         : 1\n")
  cat("sum(amount)           : $0 -- IDAHO PRICES NOBODY\n")
  cat("Named-hospital rows   : 0 -- the one recipient is not a hospital\n")
  cat("Hospital buckets      : NONE AT ALL (Maine's and Missouri's outcome)\n\n")
  print(as.data.frame(d[, c("awardee", "award_pool", "recipient_type",
                            "distributed_to_hospital")]), row.names = FALSE)
  cat("\nELEVEN opportunities are open or just posted, with vendor\n")
  cat("conferences into September 2026. Idaho is the most active of the\n")
  cat("fourteen low-candidate states and the likeliest to name more.\n")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) id_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) id_validate()
  if ("--build" %in% args) id_build()
  if ("--probe" %in% args) id_probe()
  if ("--report" %in% args) id_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}

#!/usr/bin/env Rscript
# 03an_oh_year1_awardees.R ---------------------------------------------------
#
# OHIO -- ONE NAMED, PRICED AWARD, AND THE FIRST CMS FOOTER IN THIS
# REPOSITORY WHOSE FIGURE IS THE SUBAWARD ITSELF.
#
# Ohio holds $202,030,262 (§7.1). The Governor announced on 2026-07-01:
#
#   "Ohio Governor Mike DeWine today announced the first Rural Health
#    Transformation Program award to Ohio University to strengthen the rural
#    healthcare workforce. This is the first of many initiatives that will be
#    funded through the $202 million awarded to Ohio ..."
#
# ONE AWARD ACTION, $10,000,000, TO A UNIVERSITY. So Ohio contributes ONE
# PRICED ROW AND ZERO HOSPITAL DOLLARS: §10.2 codes a university
# `NON_HOSPITAL` and §0.3a judges the RECIPIENT, so the workforce activity --
# summer camps, career fairs, apprenticeships for school students -- does not
# make it a hospital row. Maine's University of New England award is the
# precedent, and this is the same coding for the same reason.
#
# ============================================================================
# §0.2: THE FOOTER'S AMOUNT IS TIER 3, WHICH THE TIER CHECK CANNOT SEE
# ============================================================================
#
# Every CMS footer this project has read prints either the STATE ALLOTMENT
# (Tier 1 -- Iowa's June notices, Delaware, Idaho, Arkansas, Wyoming and most
# others) or an RFP's own POOL (Tier 2 -- Iowa's eight Jan/Feb notices). Ohio's
# prints NEITHER:
#
#   "This project is supported by the Centers for Medicare & Medicaid Services
#    (CMS) ... as part of a financial assistance award totaling $10,000,000
#    with 100 percent funded by CMS/HHS."
#
# $10,000,000 IS THE SUBAWARD -- the exact figure in the headline, on a release
# announcing one award to one recipient. That is a THIRD position on §0.2's
# axis and the first instance of it here.
#
# AND IT IS A LIMIT OF THE TIER CHECK, STATED RATHER THAN PATCHED.
# `rhtp_assert_footer_not_allotment()` asks ONE question: does this figure
# collide with the state's allotment? Ohio's $10,000,000 does not collide with
# $202,030,262, so declared `SOLICITATION` it is ACCEPTED -- and it is not a
# solicitation pool, it is a Tier 3 award. The check separates Tier 1 from
# NOT-TIER-1 and has never been able to separate Tier 2 from Tier 3, because
# the §7.1 anchor is the only external number it has.
#
# THE FIX IS NOT MORE MACHINERY, AND THAT IS THE POINT WORTH RECORDING. What
# tells you Ohio's footer is Tier 3 is the DOCUMENT: a release that names one
# recipient, states one figure in its own headline, and says "Additional
# contracts will be awarded in the coming months". Session 37's Iowa rule said
# the tier is not in the footer's GRAMMAR; Ohio adds that it is not always in
# the footer's ARITHMETIC either. Read what the document says the number is.
#
# THE TRIPWIRE IS THE STATE'S OWN SENTENCE. "Additional contracts will be
# awarded in the coming months" -- so this file is a PARTIAL year by
# construction, and `oh_assert_more_to_come()` is designed to notice when that
# sentence stops being true.
#
# ODH'S OWN PROGRAMME PAGE IS STALE, AND IT IS RECORDED RATHER THAN READ.
# `odh.ohio.gov`'s RHTP page still says "the State of Ohio WILL SUBMIT an
# application. IF AWARDED, it will manage the funds" -- on the same page that
# links the Governor's award announcement. A stale page is not evidence of a
# stalled programme (Mississippi's DOM page does the same thing), and it names
# no recipient.
#
# ONE CHANNEL IS UNREADABLE AND IS RECORDED AS UNKNOWN (§0.4). ODH's
# "Solicitation Invitations" page says "Please utilize the table and search
# functionality provided below" and the rows are not in the HTML -- Maine's CGI
# Advantage, Connecticut's CTsource, Louisiana's rhtla.net and Tennessee's
# Caspio portal in a fifth costume. What Ohio has solicited or awarded inside
# it is a statement about OUR ACCESS.
#
# §0.1: RCJ IS RIGHT ABOUT OHIO, WHICH IS THE UNUSUAL CASE. Its single Tier 3
# candidate is "Ohio University" at $10,000,000 under this exact release's
# title -- the correct recipient at the correct amount from the correct
# document. Iowa, Michigan and Kansas are the states where the aggregator's
# names are right; Ohio is one of very few where the AMOUNT is right too.
#
# Usage:
#   Rscript R/03an_oh_year1_awardees.R --fetch [--force] | --validate |
#           --build | --probe | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OH_STATE     <- "OH"
OH_ALLOTMENT <- 202030262        # cms_fy2026_allotments.csv (§7.1)
OH_AWARD     <- 10000000         # Ohio University -- AND the footer's figure
OH_ANNOUNCED <- as.Date("2026-07-01")
OH_NOA_DATE  <- as.Date("2025-12-29")

OH_EVIDENCE_DIR <- here::here("data", "evidence", "OH")
OH_CSV        <- here::here("data", "reference", "oh_year1_awardees.csv")
OH_STATUS_CSV <- here::here("data", "reference", "oh_year1_status.csv")
OH_DISPO_CSV  <- here::here("data", "reference",
                            "oh_rcj_candidate_disposition.csv")

OH_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

OH_RELEASE_URL <- paste0(
  "https://governor.ohio.gov/wps/portal/gov/governor/media/news-and-media/",
  "governor-dewine-announces-first-rural-health-transformation-program-",
  "award-to-ohio-university-for-10-million")

OH_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "release", OH_RELEASE_URL,
  "2026-09-03_oh_ohio_university_award_release.html",
  paste("THE AWARD SOURCE. 'the first Rural Health Transformation Program",
        "award to Ohio University', $10,000,000, 2026-07-01 -- and the CMS",
        "footer whose figure is that award rather than the allotment."),
  "odh",
  "https://odh.ohio.gov/know-our-programs/rural-health-transformation-program",
  "2026-09-03_oh_odh_rhtp_programme.html",
  paste("ODH's programme page. Names NO recipient and is STALE -- still says",
        "the state 'will submit an application. If awarded...' on the page",
        "that links the award announcement."),
  "allotment_release",
  paste0("https://governor.ohio.gov/media/news-and-media/",
         "governor-dewine-announces-ohios-rural-health-transformation-",
         "program-award"),
  "2026-09-03_oh_allotment_release.html",
  paste("THE TIER 1 RELEASE, archived as the contrast: 2025-12-29, 'Ohio will",
        "receive more than $200 million'. Same publisher, same programme,",
        "different tier -- §0.2 across two documents.")
)

oh_source <- function(key, field) {
  row <- OH_SOURCES[OH_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[OH] unknown source key: ", key, call. = FALSE)
  row[[field]]
}
oh_path <- function(key) file.path(OH_EVIDENCE_DIR, oh_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

oh_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(OH_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[OH] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

oh_fetch <- function(force = FALSE) {
  dir.create(OH_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(OH_SOURCES)), function(i) {
    src <- OH_SOURCES[i, ]
    dest <- file.path(OH_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[OH] have ", src$file)
    } else {
      raw <- oh_get(src$url, src$key)
      txt <- rawToChar(raw[raw != as.raw(0)]); Encoding(txt) <- "bytes"
      if (grepl("[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[0-9A-Za-z_-]{30,}", txt,
                useBytes = TRUE, perl = TRUE)) {
        stop("[OH] ", src$key, " carries a credential-shaped string; NOT ",
             "written.", call. = FALSE)
      }
      writeBin(raw, dest)
      message("[OH] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  writeLines(c(
    "OHIO -- RHTP evidence archive",
    "",
    "Fetched 2026-09-03 by R/03an_oh_year1_awardees.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing reproduces the digest.",
    "",
    "governor.ohio.gov IS AN IBM WEBSPHERE PORTAL and its pages carry a large",
    "amount of component scaffolding in HTML comments. The reduction keeps",
    "them (they are inert), so the CONTENT digest is stable while remaining",
    "sensitive to the article text, which is what --probe compares.",
    "",
    "THE AWARD RELEASE'S CANONICAL PATH IS THE /wps/portal/ ONE. The shorter",
    "governor.ohio.gov/media/news-and-media/... form answers 200 for the",
    "ALLOTMENT release but serves a generic shell for this one.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")),
    file.path(OH_EVIDENCE_DIR, "MANIFEST.txt"))
  invisible(entries)
}


# -- reduction ---------------------------------------------------------------

oh_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;|&#038;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;|&#8216;", "'")
  txt <- stringr::str_replace_all(txt, "&#8220;|&#8221;|&ldquo;|&rdquo;|&quot;",
                                  "\"")
  txt <- stringr::str_replace_all(txt, "&#8212;|&mdash;|&#8211;|&ndash;", "-")
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

oh_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(oh_path(key), "raw",
                                    file.size(oh_path(key))) else body
  oh_reduce_html(raw)
}

oh_content_digest <- function(key, body = NULL) {
  digest::digest(oh_html_text(key, body), algo = "sha256")
}

oh_have_archive <- function() {
  all(file.exists(file.path(OH_EVIDENCE_DIR, OH_SOURCES$file)))
}


# -- assertions --------------------------------------------------------------

#' The release names Ohio University and prices it at $10,000,000
oh_assert_the_award <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("release", body), "\\s+", " ")
  want <- c(
    "announced the first Rural Health Transformation Program award to Ohio University",
    "financial assistance award totaling $10,000,000")
  missing <- want[!vapply(want,
                          function(w) stringr::str_detect(txt,
                                                          stringr::fixed(w)),
                          logical(1))]
  if (length(missing)) {
    stop("[OH] the release no longer says: ",
         paste(sQuote(missing), collapse = "; "), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.2: the footer's figure IS the subaward, and the tier check cannot see it
#'
#' ASSERTED RATHER THAN REPAIRED. The point of this check is that the shared
#' rule ACCEPTS Ohio's footer as a SOLICITATION pool -- correctly, on the only
#' question it can ask -- while the figure is actually Tier 3. If someone
#' later teaches the rule to refuse it, they will have had to give it a
#' concept of Tier 3, and they should come and read this first.
oh_assert_footer_is_the_subaward <- function(body = NULL) {
  f <- rhtp_footer_parse(oh_html_text("release", body))
  if (nrow(f) != 1L) {
    stop("[OH] expected exactly ONE CMS footer on the release; parsed ",
         nrow(f), ".", call. = FALSE)
  }
  if (!f$fully_federal || abs(f$tier_amount - OH_AWARD) > 0.005) {
    stop("[OH] the release's footer no longer prints $10,000,000 at 100 ",
         "percent. Its figure being the SUBAWARD -- not the allotment, not a ",
         "pool -- is this state's §0.2 finding.", call. = FALSE)
  }
  # It is NOT the allotment, and the rule says so.
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(OH_AWARD, OH_STATE, "STATE_ALLOTMENT",
                                     label = "OH footer read as the allotment")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[OH] $10,000,000 is now accepted as Ohio's allotment.",
         call. = FALSE)
  }
  # And declared SOLICITATION it is ACCEPTED -- which is the limit, pinned.
  accepted <- isTRUE(rhtp_assert_footer_not_allotment(
    OH_AWARD, OH_STATE, "SOLICITATION", label = "OH footer read as a pool"))
  if (!accepted) {
    stop("[OH] the §0.2 rule now refuses Ohio's $10,000,000. If it has been ",
         "given a Tier 2/Tier 3 distinction, read this file's header: the ",
         "rule has only ever had the §7.1 anchor to compare against, and ",
         "what identifies Ohio's figure as a SUBAWARD is the document, not ",
         "the arithmetic.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Ohio says more is coming, so this file is a PARTIAL year
oh_assert_more_to_come <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("release", body), "\\s+", " ")
  if (!stringr::str_detect(
        txt, stringr::fixed("Additional contracts will be awarded"))) {
    stop("[OH] the release no longer says 'Additional contracts will be ",
         "awarded in the coming months'. That sentence is why this file is a ",
         "PARTIAL year; if Ohio has finished awarding, re-read the channel.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' ODH's page names nobody and is stale
oh_assert_odh_names_nobody <- function(body = NULL) {
  txt <- stringr::str_replace_all(oh_html_text("odh", body), "\\s+", " ")
  if (stringr::str_detect(txt, stringr::fixed("Ohio University"))) {
    stop("[OH] ODH's programme page now names Ohio University. It may have ",
         "started publishing a roster -- read it.", call. = FALSE)
  }
  if (!stringr::str_detect(txt,
                           stringr::fixed("the State of Ohio will submit an application"))) {
    message("[OH] ODH's page no longer carries its stale pre-award sentence. ",
            "That is worth a look: it may have been rewritten with award ",
            "information.")
  }
  invisible(TRUE)
}

#' §6.2's date test
oh_assert_after_noa <- function() {
  if (OH_ANNOUNCED <= OH_NOA_DATE) {
    stop("[OH] the award no longer postdates the Notice of Award.",
         call. = FALSE)
  }
  invisible(as.integer(OH_ANNOUNCED - OH_NOA_DATE))
}

#' One priced row, and NO hospital bucket
oh_assert_contributes_no_bucket <- function(awards = NULL) {
  d <- if (is.null(awards)) oh_year1_awardees() else awards
  stopifnot(nrow(d) == 1L, d$amount == OH_AWARD)
  part <- rhtp_hospital_dollar_partition(d)
  if (nrow(part) != 0L) {
    stop("[OH] Ohio now contributes to a hospital bucket. Its one recipient ",
         "is a UNIVERSITY (§10.2 NON_HOSPITAL, Maine's UNE precedent), so it ",
         "should contribute to none. $10,000,000 is the largest single ",
         "misclassification available in this state.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award file ----------------------------------------------------------

oh_year1_awardees <- function() {
  cls <- rhtp_classify_recipient_type("Ohio University", OH_STATE)
  tibble::tibble(
    state = OH_STATE,
    row_no = 1L,
    awardee = "Ohio University",
    amount = OH_AWARD,
    recipient_type = cls$recipient_type,
    distributed_to_hospital = "No",
    note = paste(
      "Ohio's FIRST RHTP award, announced 2026-07-01 by Governor DeWine.",
      "Rural healthcare workforce: healthcare exploration for 8th-grade and",
      "high-school students through summer camps and career fairs, exposure",
      "for undergraduates and graduate students, and expanded paid",
      "apprenticeships. 'Additional contracts will be awarded in the coming",
      "months', so Ohio's Year 1 is PARTIAL by construction."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste(
      "Governor DeWine Announces First Rural Health Transformation Program",
      "Award to Ohio University for $10 Million"),
    state_source_url = OH_RELEASE_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03an_oh_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = paste(
      "STATED BY THE SOURCE AND AGREED BY §8. The release quotes Ohio",
      "University's Vice President of Health Affairs and describes the",
      "recipient as a university throughout;",
      "rhtp_classify_recipient_type() independently returns",
      "UNIVERSITY_OR_AHC at HIGH on the name. Two readings, same answer, no",
      "override needed -- unlike Delaware, where §8's name rule misses all",
      "three recipients."),
    determination_confidence = cls$determination_confidence,
    flag_reason = NA_character_,
    award_pool = "Rural Health Workforce Development",
    budget_period = "Budget Period 1",
    flow_type = "NON_HOSPITAL",
    hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste(
      "§10.2 NON_HOSPITAL -- 'Recipient is clearly not a hospital -- a school",
      "district, a UNIVERSITY, an EMS agency, a vendor' -- and §0.3a judges",
      "the RECIPIENT, not the activity. The activity is rural healthcare",
      "workforce development and the recipient is Ohio University, so this is",
      "Maine's University of New England row for the same reason. The release",
      "names the subrecipient class as 'employers, schools, and community",
      "organizations' and students, which contains no hospital, so this is",
      "Missouri's MEMSA / Maine's UNE coding rather than New Hampshire's FHC",
      "(hospitals among others, Unclear). hospital_benefiting is Unclear",
      "rather than No because a rural healthcare workforce plainly reaches",
      "hospital employers eventually, and the release does not say so; it",
      "moves no figure either way. AMOUNT IS EXACT: $10,000,000 in the",
      "headline, the body and the CMS footer."),
    amount_basis = paste(
      "EXACT, and stated three times by the publisher -- the headline ('for",
      "$10 Million'), and the CMS footer ('a financial assistance award",
      "totaling $10,000,000'). NOTE THE FOOTER IS THE SUBAWARD HERE, not the",
      "state allotment and not a pool: the first such footer in this",
      "repository (§0.2)."),
    round_amount = NA_real_,
    announcement_date = OH_ANNOUNCED,
    source_archive_path = file.path("data", "evidence", "OH",
                                    oh_source("release", "file")))
}

oh_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~note,
    OH_STATE, "Rural Health Workforce Development (Ohio University)",
    "AWARDED_ONE_NAMED_AND_PRICED", "Yes - ONE NAME, ONE FIGURE",
    paste("$10,000,000, announced 2026-07-01. Ohio's first and so far only",
          "named RHTP award. A UNIVERSITY, so $0 of it is a hospital dollar."),
    OH_STATE, "Additional contracts", "PRE_AWARD", "No",
    paste("The release's own words: 'Additional contracts will be awarded in",
          "the coming months'. Ohio's Year 1 is a PARTIAL view by",
          "construction -- $192,030,262 of the allotment is unaccounted for",
          "in any public roster."),
    OH_STATE, "ODH Rural Health Transformation Program page",
    "STALE_NAMES_NOBODY", "No",
    paste("Names no recipient, and still reads 'the State of Ohio will submit",
          "an application. If awarded, it will manage the funds' on the same",
          "page that links the Governor's award announcement. Recorded, not",
          "read as evidence: a stale page is not a stalled programme",
          "(Mississippi's DOM page does the same)."),
    OH_STATE, "ODH Solicitation Invitations", "UNREADABLE", "UNKNOWN",
    paste("'Please utilize the table and search functionality provided below'",
          "-- the rows are not in the HTML. A stateful application this",
          "environment cannot search, so what Ohio has solicited or awarded",
          "inside it is a statement about OUR ACCESS, never about Ohio",
          "(§0.4). Maine's, Connecticut's, Louisiana's and Tennessee's",
          "precedent."),
    OH_STATE, "Governor's newsroom (channel control)",
    "PUBLISHES_AWARDS", "Yes",
    paste("The channel that carried this award and the 2025-12-29 allotment",
          "announcement. Ohio demonstrably publishes RHTP awards here in a",
          "recognisable, priced form, which is what makes the absence of a",
          "second one meaningful.")
  )
}

oh_disposition <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  t3 <- rt %>% dplyr::filter(.data$state == OH_STATE,
                             .data$award_tier == "SUBAWARD")
  if (nrow(t3) != 1L) {
    stop("[OH] this disposition covers ONE Tier 3 candidate and the record ",
         "table now holds ", nrow(t3), ".", call. = FALSE)
  }
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    OH_STATE, "Ohio University", 1L, "REAL_AWARD_CARRIED_CORRECTLY",
    paste0("RCJ's only Ohio Tier 3 candidate is 'Ohio University' at ",
           "$10,000,000, sourced to 'Governor DeWine Announces First RHTP ",
           "Award to Ohio University for $10 Million'. THE CORRECT RECIPIENT ",
           "AT THE CORRECT AMOUNT FROM THE CORRECT DOCUMENT -- which is rare ",
           "enough to be worth stating: Missouri, Maine, Delaware and Idaho ",
           "all carry real awards at a $1 placeholder, Michigan understates ",
           "by grain, Oklahoma and Connecticut carry the wrong tier. Ohio is ",
           "one of very few states where the aggregator gets the name AND the ",
           "figure right. It is still not the source: this file's row is ",
           "built from the Governor's release (§0.1).")
  )
}


# -- probe / validate / build / report ---------------------------------------

oh_probe <- function() {
  keys <- c("release", "odh")
  live <- purrr::map(keys, function(k) {
    r <- oh_get(oh_source(k, "url"), k); Sys.sleep(2); r
  })
  names(live) <- keys
  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(key = k,
                   archived = oh_content_digest(k),
                   live = oh_content_digest(k, live[[k]]))
  }) %>% dplyr::mutate(changed = .data$archived != .data$live)

  oh_assert_the_award(body = live$release)
  oh_assert_more_to_come(body = live$release)
  oh_assert_odh_names_nobody(body = live$odh)

  message("[OH] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    message(sprintf("  %-9s content %s", cmp$key[i],
                    if (cmp$changed[i]) "CHANGED" else "unchanged"))
  })
  if (any(cmp$changed)) {
    message("[OH] CONTENT CHANGED. Ohio said additional contracts were ",
            "coming; re-read for a second named award.")
  } else {
    message("[OH] UNCHANGED. One named award, $10,000,000, still the only one.")
  }
  invisible(cmp)
}

oh_validate <- function() {
  if (!oh_have_archive()) {
    stop("[OH] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  oh_assert_the_award()
  oh_assert_footer_is_the_subaward()
  oh_assert_more_to_come()
  oh_assert_odh_names_nobody()
  oh_assert_after_noa()
  oh_assert_contributes_no_bucket()
  message("[OH] all assertions pass.")
  invisible(TRUE)
}

oh_build <- function() {
  d <- oh_year1_awardees()
  oh_assert_contributes_no_bucket(d)
  readr::write_csv(d, OH_CSV)
  message("[OH] wrote ", OH_CSV, " (", nrow(d), " rows)")
  st <- oh_status_table()
  if ("amount" %in% names(st)) stop("[OH] status table must have no amount col")
  readr::write_csv(st, OH_STATUS_CSV)
  message("[OH] wrote ", OH_STATUS_CSV, " (", nrow(st), " rows)")
  dp <- oh_disposition()
  readr::write_csv(dp, OH_DISPO_CSV)
  message("[OH] wrote ", OH_DISPO_CSV, " (", nrow(dp), " rows)")
  invisible(list(awards = d, status = st, disposition = dp))
}

oh_report <- function() {
  d <- oh_year1_awardees()
  cat("\nOHIO -- one named, priced award, and no hospital dollars\n")
  cat(strrep("=", 58), "\n\n")
  cat("Allotment (§7.1)     : $", format(OH_ALLOTMENT, big.mark = ","), "\n",
      sep = "")
  cat("Awarded and named    : $", formatC(OH_AWARD, format = "f", digits = 0,
                                             big.mark = ","),
      "  (", round(100 * OH_AWARD / OH_ALLOTMENT, 1), "% of allotment)\n",
      sep = "")
  cat("Named-hospital rows  : 0 -- the recipient is a UNIVERSITY\n")
  cat("Hospital buckets     : NONE AT ALL (Maine's UNE outcome)\n\n")
  print(as.data.frame(d %>%
                        dplyr::mutate(amount = formatC(.data$amount,
                                                       format = "f", digits = 0,
                                                       big.mark = ",")) %>%
                        dplyr::select("awardee", "amount", "recipient_type",
                                      "distributed_to_hospital")),
        row.names = FALSE)
  cat("\n§0.2: THE CMS FOOTER ON THIS RELEASE PRINTS $10,000,000 -- THE\n")
  cat("SUBAWARD ITSELF, not the allotment and not a pool. The first such\n")
  cat("footer here, and one the tier check cannot classify: it collides\n")
  cat("with no allotment, so declared SOLICITATION it is ACCEPTED. What\n")
  cat("says it is Tier 3 is the document, not the arithmetic.\n")
  cat("\n'Additional contracts will be awarded in the coming months.'\n")
  invisible(d)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) oh_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) oh_validate()
  if ("--build" %in% args) oh_build()
  if ("--probe" %in% args) oh_probe()
  if ("--report" %in% args) oh_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}

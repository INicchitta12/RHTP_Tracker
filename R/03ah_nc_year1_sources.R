#!/usr/bin/env Rscript
# 03ah_nc_year1_sources.R -----------------------------------------------------
#
# NORTH CAROLINA -- NOT A NEGATIVE. IT HAS PUBLISHED TWO NAMED ROSTERS, AND
# THIS FILE DELIBERATELY DOES NOT EXTRACT THEM.
#
# THIS IS A SOURCE ARCHIVE AND A STATUS TABLE, NOT AN EXTRACTOR. It exists so
# that the evidence is committed (§0.5 -- an uncommitted archive is gone when
# the session ends) and so the next session starts from documents rather than
# from a URL list. `nc_year1_awardees.csv` DOES NOT EXIST and an assertion
# keeps it that way until someone decides to build it.
#
# WHY IT MATTERS THAT THIS STATE WAS FOUND AT ALL. North Carolina was one of
# TWELVE states with NO RCJ Tier 3 signal and no CMS press release -- invisible
# to both discovery layers. Session 36 named that group as the next phase on
# FLORIDA's precedent: Florida is invisible to both and had published 81 awards
# worth $188,201,256 the whole time. North Carolina is the second instance of
# exactly that, and it is the largest allotment in the group ($213,008,356).
# The RCJ_ONLY queue would never have surfaced it.
#
# WHAT NCDHHS HAS PUBLISHED
#
# 1. THIRTY-NINE NAMED MOBILE INTEGRATED HEALTH RECIPIENTS, $10,000,000.
#    The 2026-06-08 press release states "it will provide $10 million to 39
#    local EMS agencies through the NC Rural Health Transformation Program"
#    and then prints the roster under "The Mobile Integrated Health grant
#    recipients include:". Thirty-nine named organisations.
#
#    THE ROW COUNT IS THE FINDING AND THE DOLLARS ARE NOT PER-RECIPIENT.
#    $10,000,000 is a POOL figure; NCDHHS publishes NO per-agency amount.
#    Nevada's and Iowa's shape, and when this is extracted the amount column
#    must be EMPTY on all 39 rows with $10,000,000 in `round_amount`.
#
#    AND THE RECIPIENT CLASS IS ALMOST ENTIRELY NON-HOSPITAL. Thirty-eight of
#    the thirty-nine are county EMS agencies (`EMS_OR_PSAP`, `NON_HOSPITAL`).
#    The exception is "Cape Fear Valley Mobile Integrated Health (MIH)" --
#    Cape Fear Valley is a health system, so that ONE row is a genuine §8 and
#    §10.2 judgement and the only hospital-facing dollar in the set. One
#    further row reads "Clay County" without "EMS", which is the source's own
#    inconsistency and must be kept as published (§8).
#
# 2. FIVE NAMED NC ROOTS HUB LEADS, AND NO AMOUNT AT ALL.
#    The 2026-05-01 release says "The NC ROOTS Hub Lead awardees include:" and
#    names Impact Health (Region 1), Trillium Health Resources (Regions 2 AND
#    5), Vaya Health (Region 3), University of North Carolina Hospitals
#    (Region 4) and Access East, Inc. (Region 6). FIVE ORGANISATIONS, SIX
#    REGIONS -- Trillium holds two, so a row count is not an organisation
#    count.
#
#    THEY ARE NOT MISSOURI'S HUB ANCHORS, AND THE DIFFERENCE IS FIDUCIARY.
#    Missouri's ToRCH Hub Anchors are a governance roster whose own FAQ says
#    they "will not act as the fiscal agent", which is why they live in a file
#    with no amount column and contribute nothing. NCDHHS says the opposite in
#    the same breath as the names: the organisations were selected "to serve
#    as both the programmatic and FIDUCIARY leads for their regions". So these
#    are pass-through recipients, and the coding question is real rather than
#    foreclosed.
#
#    BUT NCDHHS PUBLISHES NO PER-HUB AMOUNT, AND THE ONLY FIGURE ON EITHER
#    PAGE IS THE STATE ALLOTMENT -- see the §0.2 note below.
#
#    AND ONE OF THE FIVE IS A HOSPITAL SYSTEM. "University of North Carolina
#    Hospitals" on the release is "UNC Health" on the Hub Leads page -- ONE
#    recipient under TWO spellings across two documents from one agency, which
#    is the fuzzy match §2 forbids a machine resolving. Recorded, not merged.
#
# 3. THE CONTRACTS WERE TO BE FINALISED BY 2026-06-01, WHICH HAS PASSED.
#    The release says the Hub Leads "will work with NCDHHS to finalize
#    contracts by June 1, 2026". That date is behind us and NCDHHS has
#    published no confirmation of execution, so every Hub Lead row is
#    `amount_confirmed = No` at best when it is extracted.
#
# §0.2 -- THE ONLY DOLLAR FIGURE BESIDE FIVE NAMED AWARDEES IS THE WHOLE
# ALLOTMENT. The ROOTS Hub Leads page names five awardees and contains exactly
# ONE currency figure: $213,008,356.47, in a Stevens Amendment footer reading
# "This webpage is supported by ... as part of a financial assistance award
# totaling $213,008,356.47". Session 27's axis calls that the WEAK form (its
# subject is the page). This session's §0.2 rule says the axis does not settle
# the TIER either way: an extractor that attached the only available number to
# the only available recipients would publish the entire state allotment as
# five hub awards. `nc_assert_footer_is_the_allotment()` refuses it in both
# directions.
#
# THE POSITIVE CONTROL, AND IT IS UNUSUALLY STRONG BECAUSE IT IS TWO-SIDED.
# NCDHHS demonstrably publishes recipient-level rosters in a recognisable form
# -- 39 names in one release, 5 in another, plus a standing ROOTS Hub Leads
# webpage. So where it is silent, the silence is North Carolina's and not our
# reading. TWO opportunities are closed with no roster: the NC Minority
# Diabetes Prevention Program (applications due 2026-07-17) and Expanding
# School Health Centers to Rural Areas (due 2026-08-12, up to $1,250,000 for
# up to five sites). BOTH DATES HAVE PASSED.
#
# THE SECOND TIER IS NOT PUBLISHED EITHER. The Hub Leads run their own
# regional funding opportunities, and Trillium's ROOTS page -- the one RCJ
# actually points at -- carries ZERO occurrences of "awarded", "awardee",
# "selected" or an award recipient. So the money that reaches hospitals in
# North Carolina is a tier below anything published today.
#
# THE DIGEST FINDING, AND IT IS THE NINTH MECHANISM. `ncdhhs.gov` injects a
# DYNATRACE RUM beacon (`ruxitagentjs`) whose `data-dtconfig` attribute
# carries a per-request `rpid`. FOUR fetches gave 207,707 / 207,707 / 207,707
# / 207,708 bytes and THREE distinct SHA-256s, with fetches 1 and 2 IDENTICAL.
#
# THAT PAIR IS THE POINT. A back-to-back pair of fetches would have reported
# this host STABLE -- session 34's California lesson confirmed a fourth time,
# by a fourth mechanism, and the first time this project has caught it with
# the failing pair actually in hand. Wisconsin's Akamai Boomerang put its
# nonce in a script BODY; North Carolina's Dynatrace puts it in a script TAG
# ATTRIBUTE, so the tag-stripping reduction absorbs it free.
#
# Usage:
#   Rscript R/03ah_nc_year1_sources.R --fetch [--force]
#   Rscript R/03ah_nc_year1_sources.R --validate
#   Rscript R/03ah_nc_year1_sources.R --build
#   Rscript R/03ah_nc_year1_sources.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))

NC_STATE        <- "NC"
NC_ALLOTMENT    <- 213008356          # cms_fy2026_allotments.csv (§7.1)
NC_FOOTER       <- 213008356.47       # the Stevens Amendment footer, to the cent
NC_MIH_POOL     <- 10000000           # the 39-recipient MIH round
NC_EVIDENCE_DIR <- here::here("data", "evidence", "NC")
NC_STATUS_CSV   <- here::here("data", "reference", "nc_year1_status.csv")
NC_AWARDEES_CSV <- here::here("data", "reference", "nc_year1_awardees.csv")

NC_USER_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                        "+https://www.aha.org)")

NC_BASE <- "https://www.ncdhhs.gov"

NC_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,
  "programme",
  paste0(NC_BASE, "/divisions/office-rural-health/",
         "rural-health-transformation-program"),
  "2026-09-02_nc_ncrhtp_programme.html",
  "NCDHHS's RHTP programme page: six initiatives and the news index.",
  "opportunities",
  paste0(NC_BASE, "/divisions/office-rural-health/",
         "rural-health-transformation-program/",
         "rural-health-transformation-program-grant-opportunities"),
  "2026-09-02_nc_ncrhtp_grant_opportunities.html",
  paste("Current and past funding opportunities. TWO closed with no roster",
        "and BOTH their application dates have passed."),
  "roots_page",
  paste0(NC_BASE, "/about/department-initiatives/",
         "rural-health-transformation-program/",
         "rural-organizations-orchestrating-transformation-sustainability-",
         "roots-hub-leads"),
  "2026-09-02_nc_roots_hub_leads.html",
  paste("The standing ROOTS Hub Leads page: FIVE named leads across SIX",
        "regions, and the ONLY currency figure on it is the ALLOTMENT."),
  "pr_roots",
  paste0(NC_BASE, "/news/press-releases/2026/05/01/",
         "ncdhhs-selects-nc-roots-hub-leads-strengthen-rural-health-care-",
         "across-north-carolina"),
  "2026-05-01_nc_pr_roots_hub_leads.html",
  paste("'The NC ROOTS Hub Lead awardees include:' -- five names, the",
        "'programmatic and fiduciary leads' sentence, and the 2026-06-01",
        "contract-finalisation date."),
  "pr_mih",
  paste0(NC_BASE, "/news/press-releases/2026/06/08/",
         "ncdhhs-announces-10-million-ems-workforce-through-nc-rural-health-",
         "transformation-program"),
  "2026-06-08_nc_pr_mobile_integrated_health.html",
  paste("THE ROSTER. '$10 million to 39 local EMS agencies' and 'The Mobile",
        "Integrated Health grant recipients include:' -- 39 named",
        "organisations, NO per-recipient amount."),
  "pr_three",
  paste0(NC_BASE, "/news/press-releases/2026/06/24/",
         "ncdhhs-ncdit-announce-three-programs-improve-health-care-part-",
         "north-carolinas-rural-health"),
  "2026-06-24_nc_pr_three_digital_programs.html",
  paste("Three digital-health programmes. The Rural Health Innovation Fund",
        "($20M annually) 'will launch this fall' -- NOT awarded."),
  "trillium",
  "https://trilliumhealthresources.org/NC-ROOTS-Region-2",
  "2026-09-02_nc_trillium_roots_region2.html",
  paste("A Hub Lead's own regional funding page -- the SECOND TIER, and the",
        "one RCJ points at. Names NO subrecipient.")
)

nc_source <- function(key, field) {
  row <- NC_SOURCES[NC_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NC] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

nc_path <- function(key) file.path(NC_EVIDENCE_DIR, nc_source(key, "file"))


# -- retrieval ---------------------------------------------------------------

nc_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(NC_USER_AGENT), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[NC] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

nc_assert_no_credentials <- function(raw, label) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  bad <- c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")
  for (p in bad) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[NC] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nc_fetch <- function(force = FALSE) {
  dir.create(NC_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NC_SOURCES)), function(i) {
    src <- NC_SOURCES[i, ]
    dest <- file.path(NC_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[NC] have ", src$file)
    } else {
      raw <- nc_get(src$url, src$key)
      nc_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)
      message("[NC] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(2)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  nc_write_manifest(entries)
  invisible(entries)
}

nc_write_manifest <- function(entries) {
  path <- file.path(NC_EVIDENCE_DIR, "MANIFEST.txt")
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "NORTH CAROLINA -- RHTP evidence archive",
    "",
    "Fetched 2026-09-02 by R/03ah_nc_year1_sources.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE FILE DIGEST IS NOT A CHANGE TEST ON ncdhhs.gov. A Dynatrace RUM",
    "beacon (ruxitagentjs) carries a per-request 'rpid' in its data-dtconfig",
    "attribute: four fetches gave three distinct SHA-256s AND FETCHES 1 AND 2",
    "WERE IDENTICAL, so a back-to-back pair reports this host stable. Compare",
    "nc_content_digest(), which discards attributes.",
    "",
    "NOTE: this state has PUBLISHED ROSTERS (39 MIH recipients, 5 ROOTS Hub",
    "Leads). No extraction has been performed -- see the file header.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

nc_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;", "&")
  txt <- stringr::str_replace_all(txt, "&#39;|&rsquo;|&#8217;", "'")
  txt <- stringr::str_replace_all(txt, "&quot;|&ldquo;|&rdquo;", "\"")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

nc_html_text <- function(key, body = NULL) {
  raw <- if (is.null(body)) readBin(nc_path(key), "raw",
                                    file.size(nc_path(key))) else body
  nc_reduce_html(raw)
}

nc_content_digest <- function(key, body = NULL) {
  digest::digest(nc_html_text(key, body), algo = "sha256")
}

nc_have_archive <- function() {
  all(file.exists(file.path(NC_EVIDENCE_DIR, NC_SOURCES$file)))
}


# -- what the rosters say ----------------------------------------------------

NC_HUB_LEADS <- c("Impact Health", "Trillium Health Resources", "Vaya Health",
                  "University of North Carolina Hospitals", "Access East")

#' The 39 MIH recipients are named, and the round is a POOL figure
nc_assert_mih_roster <- function(body = NULL) {
  txt <- stringr::str_replace_all(nc_html_text("pr_mih", body), "\\s+", " ")
  if (!stringr::str_detect(
        txt, stringr::fixed("The Mobile Integrated Health grant recipients"))) {
    stop("[NC] the MIH release no longer introduces its roster. Re-read it.",
         call. = FALSE)
  }
  if (!stringr::str_detect(txt, stringr::fixed("$10 million to 39 local EMS"))) {
    stop("[NC] the MIH release no longer states '$10 million to 39 local EMS ",
         "agencies'. The pool figure and the count this file reports have ",
         "moved.", call. = FALSE)
  }
  # THE ONE ROW THAT IS NOT AN EMS AGENCY, pinned so an extractor meets it.
  if (!stringr::str_detect(txt, stringr::fixed("Cape Fear Valley"))) {
    stop("[NC] Cape Fear Valley is no longer on the MIH roster. It is the ",
         "ONLY hospital-affiliated recipient among the 39 and the only §10.2 ",
         "judgement in the set.", call. = FALSE)
  }
  # AND NO PER-RECIPIENT AMOUNT EXISTS. If one appears, the extraction that
  # this file defers becomes a different job.
  # BOUND THE WINDOW AT THE ROSTER'S OWN END, not at a character count. A
  # fixed-width window runs past the last name into the Stevens Amendment
  # footer, whose $213,008,356.47 is the ALLOTMENT -- so the check would fire
  # on the very figure §0.2 says must never be read as this round's money,
  # and it would fire every run.
  roster <- stringr::str_extract(
    txt,
    "The Mobile Integrated Health grant recipients include:.*?For more information")
  if (is.na(roster)) {
    stop("[NC] the MIH roster no longer ends at 'For more information', so ",
         "its extent cannot be bounded. Re-read the release.", call. = FALSE)
  }
  if (stringr::str_detect(roster, "\\$[0-9]")) {
    stop("[NC] a dollar figure has appeared INSIDE the MIH roster. NCDHHS ",
         "published none, and this file's guidance (empty `amount`, pool in ",
         "`round_amount`) assumed that. Re-read before extracting.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The five Hub Leads are named, are FIDUCIARY leads, and carry no amount
nc_assert_hub_leads <- function(bodies = NULL) {
  pr <- stringr::str_replace_all(
    nc_html_text("pr_roots", if (!is.null(bodies)) bodies[["pr_roots"]] else
                             NULL), "\\s+", " ")
  if (!stringr::str_detect(
        pr, stringr::fixed("The NC ROOTS Hub Lead awardees include"))) {
    stop("[NC] the ROOTS release no longer calls the five 'awardees'.",
         call. = FALSE)
  }
  # THE SENTENCE THAT SEPARATES THEM FROM MISSOURI'S HUB ANCHORS.
  if (!stringr::str_detect(
        pr, stringr::fixed("programmatic and fiduciary leads"))) {
    stop("[NC] the ROOTS release no longer calls the Hub Leads 'programmatic ",
         "and fiduciary leads'. That is the ONLY thing separating them from ",
         "Missouri's Hub Anchors, which their own FAQ says are NOT fiscal ",
         "agents and which contribute $0 and no row. Re-read before coding.",
         call. = FALSE)
  }
  missing <- NC_HUB_LEADS[!vapply(NC_HUB_LEADS,
                                  function(n) stringr::str_detect(
                                    pr, stringr::fixed(n)), logical(1))]
  if (length(missing)) {
    stop("[NC] Hub Lead(s) missing from the release: ",
         paste(missing, collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

#' The ROOTS page's ONLY currency figure is the state allotment (§0.2)
nc_assert_roots_page_has_no_pool <- function(body = NULL) {
  txt <- nc_html_text("roots_page", body)
  figures <- unique(stringr::str_extract_all(txt, "\\$[0-9][0-9,]*(\\.[0-9]+)?")[[1]])
  if (!length(figures)) {
    stop("[NC] the ROOTS page carries no currency figure at all now.",
         call. = FALSE)
  }
  if (!identical(figures, "$213,008,356.47")) {
    stop("[NC] the ROOTS page now carries currency figures other than the ",
         "allotment: ", paste(figures, collapse = ", "),
         ". If NCDHHS has published per-hub amounts this is an extraction, ",
         "not a source archive -- read them.", call. = FALSE)
  }
  invisible(figures)
}

#' The allotment beside five named awardees is refused as a pool (§0.2)
nc_assert_footer_is_the_allotment <- function() {
  ok <- rhtp_assert_footer_not_allotment(
    NC_FOOTER, NC_STATE, "STATE_ALLOTMENT",
    label = "NC ROOTS Hub Leads page footer")
  if (!isTRUE(ok)) {
    message("[NC] the §0.2 tier check did not run -- see above (§0.4).")
    return(invisible(NA))
  }
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(
      NC_FOOTER, NC_STATE, "SOLICITATION",
      label = "NC footer read as the ROOTS Hub Lead pool")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[NC] the §0.2 rule no longer refuses North Carolina's allotment ",
         "being read as a pool -- which, on a page naming five awardees and ",
         "carrying no other figure, is the whole exposure.", call. = FALSE)
  }
  # The MIH round's $10,000,000 is a genuine pool and must pass.
  if (!isTRUE(rhtp_assert_footer_not_allotment(
        NC_MIH_POOL, NC_STATE, "SOLICITATION", label = "NC MIH round"))) {
    stop("[NC] the §0.2 rule now refuses the MIH round's own $10,000,000.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' NCDHHS publishes rosters -- so where it is silent, the silence is the state's
nc_assert_positive_control <- function(bodies = NULL) {
  opps <- nc_html_text("opportunities",
                       if (!is.null(bodies)) bodies[["opportunities"]] else NULL)
  for (p in c("NC Minority Diabetes Prevention Program",
              "Expanding School Health Centers to Rural Areas")) {
    if (!stringr::str_detect(opps, stringr::fixed(p))) {
      stop("[NC] the opportunities page no longer carries '", p,
           "', one of the two closed-with-no-roster controls.", call. = FALSE)
    }
  }
  # And the second tier names nobody.
  tri <- nc_html_text("trillium",
                      if (!is.null(bodies)) bodies[["trillium"]] else NULL)
  for (p in c("awarded", "awardee", "selected for")) {
    if (stringr::str_detect(stringr::str_to_lower(tri), stringr::fixed(p))) {
      stop("[NC] a Hub Lead's own page now carries '", p, "'. THE SECOND ",
           "TIER may have awarded -- that is where North Carolina's hospital ",
           "money is. Read it.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' No award file exists yet, and that is a decision rather than an oversight
nc_assert_not_extracted <- function() {
  if (file.exists(NC_AWARDEES_CSV)) {
    stop("[NC] nc_year1_awardees.csv exists. This file is a SOURCE ARCHIVE ",
         "and its header explains what an extraction has to get right (the ",
         "39 rows carry NO per-recipient amount; Cape Fear Valley is the one ",
         "hospital-affiliated recipient; UNC appears under two spellings; ",
         "the ROOTS page's only figure is the ALLOTMENT). If the extraction ",
         "has been done, retire this assertion deliberately.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the status table --------------------------------------------------------

nc_status_table <- function() {
  tibble::tribble(
    ~state, ~channel, ~stage, ~publishes_roster, ~named_recipients,
    ~award_date_published, ~note,
    NC_STATE, "Mobile Integrated Health (Office of EMS)",
    "AWARDED_ROSTER_PUBLISHED", "Yes", 39L, "2026-06-08",
    paste("'$10 million to 39 local EMS agencies'. The roster is named in",
          "full and NO per-recipient amount is published -- Nevada's and",
          "Iowa's shape. 38 of 39 are county EMS agencies (NON_HOSPITAL);",
          "Cape Fear Valley Mobile Integrated Health is the one",
          "hospital-affiliated recipient. NOT YET EXTRACTED."),
    NC_STATE, "NC ROOTS Hub Leads",
    "AWARDED_ROSTER_PUBLISHED", "Yes", 5L, "2026-05-01",
    paste("FIVE named awardees across SIX regions (Trillium holds two).",
          "'Programmatic and FIDUCIARY leads' -- so unlike Missouri's Hub",
          "Anchors these are pass-through recipients. NO per-hub amount is",
          "published anywhere; the only figure on the page is the",
          "ALLOTMENT. Contracts were to be finalised by 2026-06-01, which",
          "has PASSED. One lead is a hospital system (UNC), under two",
          "spellings across two documents. NOT YET EXTRACTED."),
    NC_STATE, "NC Minority Diabetes Prevention Program",
    "CLOSED_UNAWARDED", "No", NA_integer_, NA_character_,
    "Applications due 2026-07-17. PASSED, no roster.",
    NC_STATE, "Expanding School Health Centers to Rural Areas",
    "CLOSED_UNAWARDED", "No", NA_integer_, NA_character_,
    paste("Up to $1,250,000 for up to five sites; applications due",
          "2026-08-12. PASSED, no roster. Eligibility is PRE-IDENTIFIED",
          "(entities already contracted with the Division of Child and",
          "Family Well-Being 'have been notified'). §0.3a governs the",
          "coding: judge the recipient, not the school setting."),
    NC_STATE, "Rural Health Innovation Fund (NCDHHS + NCDIT)",
    "PRE_SOLICITATION", "No", NA_integer_, NA_character_,
    paste("'$20 million annually for up to five years'; 'The fund will",
          "launch this fall'. Not awarded, not open."),
    NC_STATE, "NC ROOTS regional opportunities (the SECOND TIER)",
    "OPEN_UNAWARDED", "No", NA_integer_, NA_character_,
    paste("Each Hub Lead runs its own regional funding opportunities. This",
          "is where North Carolina's hospital money will be. Trillium's",
          "Region 2 page names NO subrecipient.")
  )
}


# -- validate / build / report -----------------------------------------------

nc_validate <- function() {
  if (!nc_have_archive()) {
    stop("[NC] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  nc_assert_mih_roster()
  nc_assert_hub_leads()
  nc_assert_roots_page_has_no_pool()
  nc_assert_footer_is_the_allotment()
  nc_assert_positive_control()
  nc_assert_not_extracted()
  message("[NC] all assertions pass.")
  invisible(TRUE)
}

nc_build <- function() {
  st <- nc_status_table()
  if ("amount" %in% names(st)) {
    stop("[NC] nc_year1_status.csv must have NO amount column: North Carolina ",
         "publishes no per-recipient figure.", call. = FALSE)
  }
  readr::write_csv(st, NC_STATUS_CSV)
  message("[NC] wrote ", NC_STATUS_CSV, " (", nrow(st), " rows)")
  invisible(st)
}

nc_report <- function() {
  st <- nc_status_table()
  cat("\nNORTH CAROLINA -- NOT a negative. TWO published rosters, NOT extracted.\n")
  cat(strrep("=", 72), "\n\n")
  cat("Allotment (§7.1)      : $", format(NC_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("RCJ Tier 3 candidates : 0 -- invisible to BOTH discovery layers,\n")
  cat("                        exactly as Florida was with 81 awards.\n\n")
  print(as.data.frame(st[, c("channel", "stage", "named_recipients")]),
        row.names = FALSE)
  cat("\nNAMED RECIPIENTS PUBLISHED TODAY: 39 (MIH) + 5 (ROOTS) = 44\n")
  cat("DOLLARS ATTRIBUTABLE PER RECIPIENT: NONE. $10,000,000 is a POOL and\n")
  cat("the ROOTS page's only figure is the $213,008,356.47 ALLOTMENT (§0.2).\n")
  cat("\nNOT EXTRACTED, deliberately -- see the file header for what an\n")
  cat("extraction has to get right before it is built.\n")
  invisible(st)
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) nc_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) nc_validate()
  if ("--build" %in% args) nc_build()
  if ("--report" %in% args) nc_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --report")
  }
}

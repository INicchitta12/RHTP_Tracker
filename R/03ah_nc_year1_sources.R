#!/usr/bin/env Rscript
# 03ah_nc_year1_sources.R -----------------------------------------------------
#
# NORTH CAROLINA -- TWO PUBLISHED ROSTERS, 44 NAMED RECIPIENTS, AND NOT ONE
# PER-RECIPIENT DOLLAR.
#
# THE FILENAME STILL SAYS `_sources` AND THE FILE IS NOW AN EXTRACTOR. Session
# 37 archived North Carolina's evidence and deliberately did not extract it, so
# that the finding could be reported before anyone built a file from it;
# session 38 built the file. The name is kept because `docs/session37_...md`
# and `R/03k` both cite it and a rename would strand a historical record for a
# cosmetic gain -- but a header that says the opposite of the code beneath it
# is §2.1's own hazard, so it says this instead.
#
# WHY IT MATTERS THAT THIS STATE WAS FOUND AT ALL. North Carolina was one of
# TWELVE states with NO RCJ Tier 3 signal and no CMS press release -- invisible
# to both discovery layers. Session 36 named that group as the next phase on
# FLORIDA's precedent: Florida is invisible to both and had published 81 awards
# worth $188,201,256 the whole time. North Carolina is the second instance of
# exactly that, and it is the largest allotment in the group ($213,008,356).
# The RCJ_ONLY queue would never have surfaced it.
#
# AND THE HEADLINE IS A ROW COUNT, NOT A DOLLAR. `amount` is EMPTY on all 44
# rows, because NCDHHS publishes a complete named roster per round and no
# figure against any recipient -- Nevada's shape and Iowa's, a third time. But
# North Carolina INVERTS what those two taught. Nevada and Iowa publish named
# HOSPITALS with no amounts, so their danger is quoting the $0 without the row
# count. North Carolina's 44 named recipients are 39 EMS agencies and 5
# regional pass-through leads, so it contributes 0 rows and $0 to EVERY bucket
# of rhtp_hospital_dollar_partition() -- Maine's and Missouri's shape -- and
# its named-hospital row count of ZERO is a CODING DECISION UNDER REVIEW rather
# than a fact about the state. See nc_assert_row_count_is_the_finding(), which
# asserts both halves at once.
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
#    $10,000,000 is a POOL figure; NCDHHS publishes NO per-agency amount. So
#    `amount` is empty on all 39 rows and the pool sits in `round_amount`,
#    repeated per row and never summed down the column (Georgia's trap,
#    Nevada's device -- summing it gives $390,000,000).
#
#    THE RECIPIENT CLASS IS THIRTY-SEVEN, NOT THIRTY-EIGHT, AND THE EXTRACTION
#    IS WHAT CORRECTED IT. Session 37's header said thirty-eight of the
#    thirty-nine are county EMS agencies. Read against §8's name rule the
#    figure is THIRTY-SEVEN: TWO names carry no EMS token, not one.
#
#      - "Cape Fear Valley Mobile Integrated Health (MIH)" -- the one name that
#        does not read as a county EMS agency at all.
#      - "Clay County" -- printed WITHOUT the "EMS" its thirty-eight siblings
#        carry, which is the source's own inconsistency and is kept as
#        published (§8).
#
#    NEITHER WAS PROMOTED AND NEITHER WAS DEMOTED (§0.4). Session 37 called
#    Cape Fear Valley "the one hospital-affiliated recipient", and that is this
#    pipeline's own knowledge rather than the document's: the archive says
#    nothing about the recipient beyond its name, while NCDHHS's own sentence
#    calls all thirty-nine "local EMS agencies" and its release describes
#    "EMS-led Mobile Integrated Health programs". So both rows take §8's
#    standing fallback and the question is QUEUED. It is worth $0 either way --
#    nothing here is priced -- and what it moves is North Carolina's
#    named-hospital ROW COUNT, which is the only hospital quantity this state
#    supports. Nevada's lesson, one state on.
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
#    AND THE TWO SPELLINGS OF ONE HUB LEAD CLASSIFY DIFFERENTLY, WHICH IS
#    SHARPER THAN A COUNTING PROBLEM. "University of North Carolina Hospitals"
#    on the release is "UNC Health" on the Hub Leads page -- one recipient, two
#    documents, one agency, and §2 forbids a machine resolving the match. The
#    extraction shows what the merge would cost: the release's spelling hits
#    §8's hospital name rule (HOSPITAL_OR_SYSTEM, HIGH, therefore DIRECT and
#    `Yes` -- A NAMED-HOSPITAL ROW), while the page's spelling hits nothing and
#    falls to §8's standing fallback (NONPROFIT_CBO, LOW, `No`). Same
#    organisation, opposite codings, decided by which document you read.
#
#    NEITHER MACHINE ANSWER IS USED. NCDHHS's own page states the form -- "a
#    public academic medical center ... With more than 1,000 beds" -- and §8's
#    code for an academic health centre is UNIVERSITY_OR_AHC (Oregon's OHSU
#    precedent, session 17), which can only keep dollars OUT of a hospital
#    total. The source outranks both spellings (Alaska's rule, session 12).
#    `nc_assert_unc_two_spellings()` asserts the divergence rather than
#    repairing it, so the reason the names must not be merged survives.
#
#    ALL FIVE HUB LEADS ARE `PASS_THROUGH_UNRESOLVED` AND `Unclear`, AND THE
#    ELIGIBLE CLASS IS AGAIN THE WHOLE REASON. §10.2's PASS_THROUGH_DESIGNATED
#    needs the source to name hospital subrecipients or restrict eligibility to
#    hospitals, AND the award to have been made. NCDHHS does neither: the leads
#    "will establish local networks of partner organizations", and the only
#    published description of such a network -- Access East's -- reads
#    "primary-care practices, Federally Qualified Health Centers (FQHCs),
#    community health centers, local health departments, safety-net and social
#    service organizations and hospitals". Hospitals AMONG OTHERS: New
#    Hampshire's FHC class (`Unclear`), not Illinois's hospitals-only ICAHN
#    class (`Yes`). So the five enter NEITHER bucket.
#
#    AND THREE OF THE FIVE RAISE A CONDITION THIS PROJECT HAD NOT RECORDED:
#    THE SOURCE STATES A FORM §8 DOES NOT CARRY. NCDHHS calls Trillium "an NC
#    Medicaid Tailored Plan and Managed Care Organization (MCO)", Vaya "a
#    public NC Medicaid Managed Care Organization (MCO)" and Access East "a
#    comprehensive care management provider". That is NOT the unstated form
#    Kansas, Maryland, Nebraska, Oklahoma, Nevada, Michigan, Missouri and Iowa
#    all raise -- the state HAS stated it, and §8 has no code for the answer.
#    No code was invented (§2): the three keep §8's standing fallback, the
#    state's own sentence is preserved in `recipient_type_source`, and the
#    question is queued. Impact Health, by contrast, is stated as "an
#    independent 501(c)3", which §8 does carry.
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
#   Rscript R/03ah_nc_year1_sources.R --probe    # LIVE: has the second tier awarded?
#   Rscript R/03ah_nc_year1_sources.R --validate
#   Rscript R/03ah_nc_year1_sources.R --build    # status table AND the 44 rows
#   Rscript R/03ah_nc_year1_sources.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
  library(purrr); library(httr); library(digest); library(here); library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

NC_STATE        <- "NC"
NC_ALLOTMENT    <- 213008356          # cms_fy2026_allotments.csv (§7.1)
NC_FOOTER       <- 213008356.47       # the Stevens Amendment footer, to the cent
NC_MIH_POOL     <- 10000000           # the 39-recipient MIH round
NC_MIH_COUNT    <- 39L                # NCDHHS: "$10 million to 39 local EMS agencies"
NC_ROOTS_COUNT  <- 5L                 # FIVE organisations ...
NC_ROOTS_REGIONS <- 6L                # ... across SIX regions; Trillium holds two
NC_POOL_MIH     <- "Mobile Integrated Health"
NC_POOL_ROOTS   <- "NC ROOTS Hub Leads"
NC_BUDGET_PERIOD <- "BP1 (2025-12-29 to 2026-10-30)"
NC_EVIDENCE_DIR <- here::here("data", "evidence", "NC")
NC_STATUS_CSV   <- here::here("data", "reference", "nc_year1_status.csv")
NC_AWARDEES_CSV <- here::here("data", "reference", "nc_year1_awardees.csv")
NC_REVIEW_QUEUE <- here::here("data", "reference",
                              "classification_review_queue.csv")

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

#' THE FILE THAT USED TO BE ASSERTED ABSENT IS NOW ASSERTED PRESENT
#'
#' Session 37 archived North Carolina's evidence and deliberately did NOT
#' extract it, with `nc_assert_not_extracted()` refusing to let an award file
#' appear until somebody decided to build one. Session 38 built it, so that
#' assertion is RETIRED -- deliberately, as its own message asked -- and
#' replaced by its opposite. The guard is kept rather than deleted because the
#' thing it protected has not changed: what makes this file honest is the four
#' properties its header listed, and those are now asserted individually by
#' nc_assert_row_count_is_the_finding(), nc_assert_unc_two_spellings(),
#' nc_assert_form_not_stated_queued() and nc_assert_hub_leads_unresolved().
nc_assert_extracted <- function() {
  if (!file.exists(NC_AWARDEES_CSV)) {
    stop("[NC] nc_year1_awardees.csv is missing. North Carolina IS extracted ",
         "as of session 38 -- 44 named recipients across two rosters. Rebuild ",
         "it with `Rscript R/03ah_nc_year1_sources.R --build`.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the two rosters ----------------------------------------------------------
#
# BOTH ARE CLEAN <ul> LISTS AND ARE PARSED AS LISTS, NOT AS PROSE. NCDHHS
# prints each roster as a `<ul>` between a fixed introducing sentence and a
# fixed closing one, so the extent is bounded by the DOCUMENT'S OWN text rather
# than by a character count. That bound matters twice over here: a fixed-width
# window run past the last name reaches the Stevens Amendment footer, whose
# $213,008,356.47 is the ALLOTMENT (§0.2), and session 13's South Dakota rule
# -- a prose matcher allowed to span a full stop UNDERCOUNTS a roster -- does
# not arise at all when the source has marked each name up as its own item.

nc_raw <- function(key) readBin(nc_path(key), "raw", file.size(nc_path(key)))

#' The `<li>` items of one bounded roster, as published
#'
#' Names are kept exactly as the release prints them (§8 -- keep the state's
#' own language). That is why "Clay County" stays "Clay County" and is not
#' silently given the "EMS" the other thirty-eight carry.
nc_roster_items <- function(key, opening, closing, body = NULL) {
  txt <- rawToChar(if (is.null(body)) nc_raw(key) else body)
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))

  i <- stringr::str_locate(txt, stringr::fixed(opening))
  if (any(is.na(i))) {
    stop("[NC] ", key, ": the roster's opening sentence is gone -- '", opening,
         "'. Re-read the release before extracting anything.", call. = FALSE)
  }
  rest <- substring(txt, i[1, "end"] + 1L)
  j <- stringr::str_locate(rest, stringr::fixed(closing))
  if (any(is.na(j))) {
    stop("[NC] ", key, ": the roster no longer ends at '", closing,
         "', so its extent cannot be bounded. A window that runs past the ",
         "last name reaches the Stevens Amendment footer, whose figure is ",
         "the ALLOTMENT (§0.2).", call. = FALSE)
  }
  seg <- substring(rest, 1L, j[1, "start"] - 1L)

  if (stringr::str_detect(seg, "\\$[0-9]")) {
    stop("[NC] ", key, ": a dollar figure has appeared INSIDE the roster. ",
         "NCDHHS published none, and this file's `amount` column is empty on ",
         "every row only while that is true. `nc_year1_awardees.csv` must be ",
         "REWRITTEN, not patched.", call. = FALSE)
  }

  items <- stringr::str_match_all(seg, "(?s)<li[^>]*>(.*?)</li>")[[1]][, 2]
  items <- stringr::str_replace_all(items, "<[^>]+>", " ")
  items <- stringr::str_replace_all(items, "&nbsp;|&#160;| ", " ")
  items <- stringr::str_replace_all(items, "&amp;", "&")
  items <- stringr::str_replace_all(items, "&#39;|&rsquo;|&#8217;", "'")
  items <- stringr::str_squish(items)
  items[nzchar(items)]
}

NC_MIH_OPENING   <- "The Mobile Integrated Health grant recipients include:"
NC_MIH_CLOSING   <- "For more information"
NC_ROOTS_OPENING <- "The NC ROOTS Hub Lead awardees include:"
NC_ROOTS_CLOSING <- "The organizations were"

#' The 39 Mobile Integrated Health recipients
nc_mih_roster <- function(body = NULL) {
  items <- nc_roster_items("pr_mih", NC_MIH_OPENING, NC_MIH_CLOSING, body)
  if (length(items) != NC_MIH_COUNT) {
    stop("[NC] the MIH roster now holds ", length(items), " names, not ",
         NC_MIH_COUNT, ". NCDHHS's own sentence says '$10 million to 39 local ",
         "EMS agencies'; a roster that has stopped matching it is a document ",
         "to re-read, not a count to update.", call. = FALSE)
  }
  tibble::tibble(awardee = items, row_in_pool = seq_along(items))
}

#' The five NC ROOTS Hub Leads, and the SIX regions they cover
#'
#' FIVE ORGANISATIONS, SIX REGIONS -- Trillium Health Resources holds Regions 2
#' AND 5 -- so a row count is neither a region count nor an organisation count.
#' The region string is kept as published rather than split into two rows,
#' because NCDHHS announced one lead role per organisation and splitting it
#' would invent a sixth award action the state never made.
nc_hub_lead_roster <- function(body = NULL) {
  items <- nc_roster_items("pr_roots", NC_ROOTS_OPENING, NC_ROOTS_CLOSING, body)
  if (length(items) != NC_ROOTS_COUNT) {
    stop("[NC] the ROOTS roster now holds ", length(items), " names, not ",
         NC_ROOTS_COUNT, ". Re-read the release.", call. = FALSE)
  }
  parts <- stringr::str_match(items, "^(.*?)\\s*[–—-]\\s*(Region.*)$")
  if (any(is.na(parts[, 2L]))) {
    stop("[NC] a Hub Lead item no longer reads '<organisation> - <region>': ",
         paste(items[is.na(parts[, 2L])], collapse = " | "), call. = FALSE)
  }
  out <- tibble::tibble(
    awardee     = stringr::str_squish(parts[, 2L]),
    hub_region  = stringr::str_squish(parts[, 3L]),
    row_in_pool = seq_along(items))
  regions <- unique(unlist(stringr::str_extract_all(out$hub_region, "[0-9]+")))
  if (length(regions) != NC_ROOTS_REGIONS) {
    stop("[NC] the five Hub Leads now cover ", length(regions),
         " regions, not ", NC_ROOTS_REGIONS, ". Trillium holding Regions 2 ",
         "AND 5 is why the organisation count and the region count differ; if ",
         "that has changed, so has the file's arithmetic.", call. = FALSE)
  }
  out
}


# -- the award rows -----------------------------------------------------------
#
# `amount` IS EMPTY ON ALL FORTY-FOUR ROWS. North Carolina publishes a
# complete, named roster for each round and NO dollar figure against any
# recipient -- Nevada's shape and Iowa's, a third time. The MIH round's
# $10,000,000 is a POOL figure and lives in `round_amount`, repeated on each of
# that round's rows, so SUMMING `round_amount` DOWN THE COLUMN GIVES
# $390,000,000 FOR A ROUND OF $10,000,000 (Georgia's trap, Nevada's device).
# `nc_reconcile()` sums distinct (award_pool, round_amount) pairs instead.
#
# AND THE ROOTS ROUND'S `round_amount` IS `NA`, WHICH IS §0.2'S REFUSAL WRITTEN
# INTO THE DATA. NCDHHS publishes no per-hub figure and no ROOTS pool figure;
# the only currency on either ROOTS document is the $213,008,356.47 STATE
# ALLOTMENT. An extractor that filled the empty column with the only number
# available would publish the whole of North Carolina's five-year federal award
# as five hub awards.

NC_SOURCE_TITLES <- c(
  pr_mih = paste("NCDHHS announces $10 million for EMS workforce through NC",
                 "Rural Health Transformation Program (2026-06-08)"),
  pr_roots = paste("NCDHHS selects NC ROOTS Hub Leads to strengthen rural",
                   "health care across North Carolina (2026-05-01)"))

NC_MIH_NOTE <- paste(
  "Announced by NCDHHS on 2026-06-08: \"it will provide $10 million to 39",
  "local EMS agencies through the NC Rural Health Transformation Program\",",
  "with the roster printed under \"The Mobile Integrated Health grant",
  "recipients include:\". THE $10,000,000 IS A POOL FIGURE -- NCDHHS publishes",
  "no per-recipient amount, so `amount` is empty and nothing is divided",
  "(§6.2). The award is made in the release's own words (\"The funds awarded",
  "by the NCDHHS Office of Emergency Medical Services\"), so the recipient is",
  "confirmed and the amount is not.")

NC_ROOTS_NOTE <- paste(
  "Announced by NCDHHS on 2026-05-01 under \"The NC ROOTS Hub Lead awardees",
  "include:\". The five were \"selected through a competitive process ... to",
  "serve as both the programmatic and FIDUCIARY leads for their regions\",",
  "which is the word separating them from Missouri's ToRCH Hub Anchors, whose",
  "own FAQ says they \"will not act as the fiscal agent\": these are",
  "pass-through recipients. NCDHHS PUBLISHES NO AMOUNT FOR ANY HUB, and the",
  "only currency figure on either ROOTS document is the $213,008,356.47 STATE",
  "ALLOTMENT, which is never read as this round's money (§0.2). The release",
  "says the leads \"will work with NCDHHS to finalize contracts by June 1,",
  "2026\"; no execution has been published since, so `amount_confirmed = No`.")

# WHY EVERY HUB LEAD IS `PASS_THROUGH_UNRESOLVED` AND `Unclear`.
#
# This is New Hampshire's FHC answer and not Illinois's ICAHN answer, and the
# ELIGIBLE CLASS is again the whole reason. §10.2's PASS_THROUGH_DESIGNATED
# needs the source to name hospital subrecipients or restrict eligibility to
# hospitals, AND the award to have been made. NCDHHS does neither: the Hub
# Leads "will establish local networks of partner organizations", and the one
# published description of such a network -- Access East's -- lists "primary-
# care practices, Federally Qualified Health Centers (FQHCs), community health
# centers, local health departments, safety-net and social service
# organizations and hospitals", i.e. hospitals AMONG OTHERS, which is §0.3
# exactly. The second tier where those subrecipients would be named is not
# published: Trillium's own Region 2 page names nobody.
NC_HUB_FLOW_BASIS <- paste(
  "§10.2 PASS_THROUGH_UNRESOLVED: an NCDHHS-selected \"programmatic and",
  "fiduciary lead\" for its region that will \"establish local networks of",
  "partner organizations\". NCDHHS names no subrecipient and restricts",
  "eligibility to no class -- the only published description of a Hub Lead's",
  "network (Access East's) is \"primary-care practices, Federally Qualified",
  "Health Centers (FQHCs), community health centers, local health",
  "departments, safety-net and social service organizations and hospitals\",",
  "hospitals AMONG OTHERS. That is New Hampshire's FHC class (`Unclear`) and",
  "not Illinois's hospitals-only ICAHN class (`Yes`), so §10.2's second",
  "clause fails and these dollars enter NEITHER bucket of",
  "rhtp_hospital_dollar_partition(). §0.3: do not impute.")

# WHAT EACH HUB LEAD'S OWN PAGE SAYS ITS FORM IS -- AND WHERE §8 HAS NO CODE
# FOR THE ANSWER.
#
# NCDHHS's standing Hub Leads page describes each organisation in the state's
# own words, which outranks the recipient's name (Alaska's rule, session 12).
# For TWO of the five that settles the §8 type. For the OTHER THREE THE SOURCE
# STATES A FORM §8 DOES NOT CARRY -- "Managed Care Organization", "comprehensive
# care management provider" -- which is a DIFFERENT condition from the unstated
# form Kansas, Maryland, Nebraska, Oklahoma, Nevada, Michigan, Missouri and
# Iowa all raise, and it is not resolved here. No code was invented (§2): those
# rows take §8's standing fallback, the state's own sentence is preserved in
# `recipient_type_source`, and the question is queued.
NC_HUB_LEAD_FORMS <- tibble::tribble(
  ~awardee, ~recipient_type, ~confidence, ~stated_form, ~form_in_vocabulary,

  "Impact Health", "NONPROFIT_CBO", "MEDIUM",
  paste("an independent 501(c)3 formed during the creation of North",
        "Carolina's Healthy Opportunities Pilot (HOP) program"),
  TRUE,

  "Trillium Health Resources", NA_character_, NA_character_,
  "an NC Medicaid Tailored Plan and Managed Care Organization (MCO)",
  FALSE,

  "Vaya Health", NA_character_, NA_character_,
  "a public NC Medicaid Managed Care Organization (MCO)",
  FALSE,

  # THE ONE THE MACHINE GETS RIGHT AND WRONG AT THE SAME TIME -- see
  # nc_assert_unc_two_spellings().
  "University of North Carolina Hospitals", "UNIVERSITY_OR_AHC", "MEDIUM",
  paste("a public academic medical center providing patient care, educating",
        "health care professionals and advancing medical research in",
        "partnership with the UNC School of Medicine"),
  TRUE,

  "Access East, Inc.", NA_character_, NA_character_,
  paste("a comprehensive care management provider and participant in North",
        "Carolina's Healthy Opportunities Pilot (HOP) program"),
  FALSE
)

# THE TWO ROWS WHERE THE ROSTER'S OWN NAME AND NCDHHS'S CLASS SENTENCE DISAGREE.
# Neither is promoted and neither is demoted (§0.4); both are queued.
NC_QUEUED_FORM_NOTE <- c(
  "Cape Fear Valley Mobile Integrated Health (MIH)" = paste(
    "QUEUED (NC_MIH_FORM_NOT_STATED): this is the ONE name among the 39 that",
    "does not read as a county EMS agency, and Cape Fear Valley is a health",
    "system. NOTHING WAS PROMOTED (§0.4): NCDHHS's own sentence calls all 39",
    "\"local EMS agencies\" and its release describes \"EMS-led Mobile",
    "Integrated Health programs\", while the archive says nothing else about",
    "this recipient at all. So the row takes §8's standing fallback and a",
    "human decides. It is worth $0 either way -- North Carolina publishes no",
    "per-recipient amount -- and it moves the state's named-hospital ROW",
    "COUNT, which is the only hospital quantity North Carolina supports."),
  "Clay County" = paste(
    "QUEUED (NC_MIH_FORM_NOT_STATED): the release prints this recipient",
    "WITHOUT the \"EMS\" that the other thirty-eight carry, while calling all",
    "39 \"local EMS agencies\". The source's own inconsistency is kept as",
    "published (§8) and the name rule therefore falls to §8's standing",
    "fallback rather than being given a token the document does not print."))

NC_QUEUED_FORM_ROWS <- names(NC_QUEUED_FORM_NOTE)

# THE SECOND SPELLING, ON THE ROW ITSELF. A reader who meets this row six
# months from now has to be able to see that the same organisation appears
# under another name on another NCDHHS page, and that the two would classify
# differently if either were taken at face value.
NC_UNC_SPELLING_NOTE <- c(
  "University of North Carolina Hospitals" = paste(
    "TWO SPELLINGS, ONE RECIPIENT, AND THEY CLASSIFY DIFFERENTLY. NCDHHS",
    "prints this awardee as \"University of North Carolina Hospitals\" on the",
    "2026-05-01 release and as \"UNC Health\" on its standing Hub Leads page.",
    "The release's spelling hits §8's hospital name rule (HOSPITAL_OR_SYSTEM,",
    "HIGH, therefore DIRECT and `Yes` -- a NAMED-HOSPITAL row); the page's",
    "hits nothing and falls to §8's standing fallback (`No`). §2 forbids a",
    "machine resolving that match, and NEITHER machine answer is used here:",
    "NCDHHS's own page states the form (\"a public academic medical center ...",
    "With more than 1,000 beds\"), and §8's code for an academic health centre",
    "is UNIVERSITY_OR_AHC (Oregon's OHSU precedent, session 17), which can",
    "only keep dollars OUT of a hospital total."))

#' Every award action North Carolina has published, one row each
nc_award_rows <- function() {
  mih   <- nc_mih_roster()
  roots <- nc_hub_lead_roster()

  rows <- dplyr::bind_rows(
    tibble::tibble(
      awardee           = mih$awardee,
      award_pool        = NC_POOL_MIH,
      round_name        = "Mobile Integrated Health (Office of EMS)",
      round_awards      = NC_MIH_COUNT,
      round_amount      = NC_MIH_POOL,
      announcement_date = "2026-06-08",
      hub_region        = NA_character_,
      source_key        = "pr_mih",
      pool_note         = NC_MIH_NOTE,
      row_in_pool       = mih$row_in_pool),
    tibble::tibble(
      awardee           = roots$awardee,
      award_pool        = NC_POOL_ROOTS,
      round_name        = "NC ROOTS Hub Leads",
      round_awards      = NC_ROOTS_COUNT,
      round_amount      = NA_real_,   # NOT the allotment. See above (§0.2).
      announcement_date = "2026-05-01",
      hub_region        = roots$hub_region,
      source_key        = "pr_roots",
      pool_note         = NC_ROOTS_NOTE,
      row_in_pool       = roots$row_in_pool)
  )

  # THE SHARED §8/§10.2 CLASSIFIER, ON THE NAME ALONE, ON EVERY ROW FIRST. Its
  # answer is preserved on every row even where it is overridden, so the
  # override is auditable (Indiana's convention, session 24).
  cls <- rhtp_classify_recipient_type(rows$awardee, NC_STATE)
  rows$machine_type       <- cls$recipient_type
  rows$machine_confidence <- cls$determination_confidence

  rows$recipient_type           <- cls$recipient_type
  rows$determination_confidence <- cls$determination_confidence
  rows$recipient_type_source    <- cls$recipient_type_basis

  # WHETHER §8'S STANDING FALLBACK WAS USED -- tracked separately from
  # `determination_confidence`, because the two answer different questions and
  # a Hub Lead's confidence is set by §7's "unresolved pass-through" rule
  # rather than by how its type was determined. Conflating them flagged Impact
  # Health RECIPIENT_TYPE_INFERRED when NCDHHS states its form outright.
  rows$type_inferred <- rows$machine_confidence == "LOW"

  for (i in seq_len(nrow(NC_HUB_LEAD_FORMS))) {
    f <- NC_HUB_LEAD_FORMS[i, ]
    k <- which(rows$award_pool == NC_POOL_ROOTS & rows$awardee == f$awardee)
    if (length(k) != 1L) {
      stop("[NC] Hub Lead '", f$awardee, "' is not on the roster exactly once.",
           call. = FALSE)
    }
    rows$recipient_type_source[k] <- paste0(
      "NCDHHS's own Hub Leads page states the form: \"", f$stated_form,
      "\". ",
      if (isTRUE(f$form_in_vocabulary)) {
        "§8 carries a code for that, so the source overrides the name rule."
      } else {
        paste("§8 CARRIES NO CODE FOR THAT FORM, so this row keeps §8's",
              "standing fallback and the question is QUEUED rather than",
              "answered (§2: no code was invented mid-session).")
      },
      " The name rule alone returned ", rows$machine_type[k], " (",
      rows$machine_confidence[k], ").")
    if (!is.na(f$recipient_type)) {
      rows$recipient_type[k]           <- f$recipient_type
      rows$determination_confidence[k] <- f$confidence
      rows$type_inferred[k]            <- FALSE
    }
  }

  # FLOW. The 39 MIH rows read from the name alone, exactly as every other
  # unstated-form state does. The five Hub Leads are OVERRIDDEN to §10.2's
  # PASS_THROUGH_UNRESOLVED, with the reason and the superseded machine
  # determination both on the row.
  flow <- rhtp_classify_flow(rows$recipient_type, rep(NA_character_, nrow(rows)))
  rows$flow_type               <- flow$flow_type
  rows$distributed_to_hospital <- flow$distributed_to_hospital
  rows$hospital_benefiting     <- flow$hospital_benefiting
  rows$determination_basis     <- paste(rows$recipient_type_source,
                                        flow$flow_basis)

  hub <- rows$award_pool == NC_POOL_ROOTS
  rows$determination_basis[hub] <- paste0(
    NC_HUB_FLOW_BASIS, " Superseded machine determination on the name alone: ",
    flow$flow_type[hub], " / ", flow$distributed_to_hospital[hub], ".")
  rows$flow_type[hub]                <- "PASS_THROUGH_UNRESOLVED"
  rows$distributed_to_hospital[hub]  <- "Unclear"
  rows$hospital_benefiting[hub]      <- "Unclear"
  rows$determination_confidence[hub] <- "LOW"

  rows$hospital_attribution <- rhtp_hospital_attribution(
    rows$flow_type, rows$distributed_to_hospital, rows$recipient_type)

  rows$flag_reason <- paste0(
    "AMOUNT_MISSING",
    dplyr::if_else(rows$type_inferred, ";RECIPIENT_TYPE_INFERRED", ""))

  tibble::tibble(
    state = NC_STATE,
    row_no = seq_len(nrow(rows)),
    awardee = rows$awardee,
    amount = NA_real_,
    recipient_type = rows$recipient_type,
    distributed_to_hospital = rows$distributed_to_hospital,
    note = paste0(
      dplyr::if_else(is.na(rows$hub_region), "",
                     paste0(rows$hub_region, ". ")),
      rows$pool_note,
      dplyr::if_else(rows$awardee %in% NC_QUEUED_FORM_ROWS,
                     paste0(" ", NC_QUEUED_FORM_NOTE[rows$awardee]), ""),
      dplyr::if_else(rows$awardee %in% names(NC_UNC_SPELLING_NOTE),
                     paste0(" ", NC_UNC_SPELLING_NOTE[rows$awardee]), "")),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = 2026L,
    source_document_title = unname(NC_SOURCE_TITLES[rows$source_key]),
    state_source_url = vapply(rows$source_key, function(k) nc_source(k, "url"),
                              character(1), USE.NAMES = FALSE),
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03ah_nc_year1_sources.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = rows$recipient_type_source,
    determination_confidence = rows$determination_confidence,
    flag_reason = rows$flag_reason,
    award_pool = rows$award_pool,
    budget_period = NC_BUDGET_PERIOD,
    flow_type = rows$flow_type,
    hospital_benefiting = rows$hospital_benefiting,
    hospital_attribution = rows$hospital_attribution,
    intermediary_name = dplyr::if_else(rows$award_pool == NC_POOL_ROOTS,
                                       rows$awardee, NA_character_),
    determination_basis = rows$determination_basis,
    amount_basis = paste(
      "North Carolina publishes NO per-recipient amount. The MIH round's",
      "$10,000,000 is a POOL figure carried in `round_amount`, repeated on",
      "each of that round's rows and never summed down the column. The ROOTS",
      "round has NO published figure at all: the only currency on either ROOTS",
      "document is the $213,008,356.47 STATE ALLOTMENT, which is Tier 1 and is",
      "never read as this round's money (§0.2)."),
    round_name = rows$round_name,
    round_awards = rows$round_awards,
    round_amount = rows$round_amount,
    hub_region = rows$hub_region,
    announcement_date = rows$announcement_date,
    source_archive_path = file.path(
      "data/evidence/NC",
      vapply(rows$source_key, function(k) nc_source(k, "file"), character(1),
             USE.NAMES = FALSE)),
    row_in_pool = rows$row_in_pool
  )
}


# -- what the extracted file may and may not say -----------------------------

#' NEVADA'S AND IOWA'S GUARD, INVERTED -- and the inversion is the finding
#'
#' Nevada and Iowa publish named HOSPITALS with no amounts, so their danger is
#' reporting $0 without the row count: `rows = 20, dollars = 0` and
#' `rows = 152, dollars = 0` are both true at once, and quoting the 0 alone
#' reports the opposite of what those states published.
#'
#' NORTH CAROLINA PUBLISHES 44 NAMED RECIPIENTS AND CONTRIBUTES NOTHING TO ANY
#' BUCKET, AND BOTH HALVES OF THAT NEED SAYING TOGETHER. Its $0 is not Nevada's
#' $0 beside 20 hospital rows; it is Maine's and Missouri's shape -- a real,
#' complete, named roster whose recipients are EMS agencies and regional
#' pass-through leads. So this asserts BOTH halves at once, as Maine's does:
#'
#'   - 44 named recipients exist in this repository, and
#'   - `amount` is empty on every one of them, and
#'   - the partition returns NO bucket at all for North Carolina.
#'
#' A future session that "completes" North Carolina by promoting Cape Fear
#' Valley or by dividing the $10,000,000 would break the second and third
#' clauses in that order, which is the order the mistake is made in.
nc_assert_row_count_is_the_finding <- function(rows = NULL) {
  if (is.null(rows)) rows <- nc_award_rows()

  if (nrow(rows) != NC_MIH_COUNT + NC_ROOTS_COUNT) {
    stop("[NC] the award file holds ", nrow(rows), " rows, not ",
         NC_MIH_COUNT + NC_ROOTS_COUNT, ".", call. = FALSE)
  }
  if (!all(is.na(rows$amount))) {
    stop("[NC] `amount` is populated on ", sum(!is.na(rows$amount)),
         " row(s). North Carolina publishes NO per-recipient amount, so any ",
         "figure there came from this pipeline and not from North Carolina ",
         "(§0.1, §6.2). If NCDHHS has started publishing them, this file must ",
         "be REWRITTEN, not patched.", call. = FALSE)
  }
  if (sum(rows$amount, na.rm = TRUE) != 0) {
    stop("[NC] sum(amount) is not 0.", call. = FALSE)
  }

  part <- rhtp_hospital_dollar_partition(rows)
  if (nrow(part) != 0L) {
    stop("[NC] North Carolina now contributes to ", nrow(part),
         " hospital bucket(s): ", paste(unique(part$bucket), collapse = ", "),
         ". It contributed to none, and the two rows that could change that ",
         "are QUEUED rather than coded (Cape Fear Valley, and the five ROOTS ",
         "Hub Leads' unresolved class). Read the queue before accepting it.",
         call. = FALSE)
  }
  invisible(list(rows = nrow(rows), dollars = 0))
}

#' ONE ORGANISATION, TWO SPELLINGS, AND THE MACHINE CODES THEM OPPOSITE WAYS
#'
#' NCDHHS prints the Region 4 Hub Lead as "University of North Carolina
#' Hospitals" on its 2026-05-01 release and as "UNC Health" on its standing Hub
#' Leads page -- one recipient, two documents, one agency. §2 forbids a machine
#' resolving a fuzzy hospital match, and this is the case that shows why it is
#' not merely a COUNTING problem: the two spellings do not just count
#' differently, THEY CLASSIFY DIFFERENTLY. The release's spelling hits §8's
#' hospital name rule (HOSPITAL_OR_SYSTEM, HIGH, and therefore DIRECT / `Yes`
#' -- a named-hospital row); the page's spelling hits nothing and falls to §8's
#' standing fallback (NONPROFIT_CBO, LOW, NON_HOSPITAL / `No`).
#'
#' NEITHER MACHINE ANSWER IS THE ONE THIS FILE USES. NCDHHS's own page states
#' the form -- "a public academic medical center ... With more than 1,000 beds"
#' -- and §8's code for an academic health centre is UNIVERSITY_OR_AHC, which
#' is Oregon's OHSU precedent (session 17) and can only keep dollars OUT of a
#' hospital total. The source outranks both spellings.
#'
#' This asserts the divergence rather than repairing it, so that the day
#' somebody "tidies" the two names the reason they must not is still here.
nc_assert_unc_two_spellings <- function() {
  release_name <- "University of North Carolina Hospitals"
  page_name    <- "UNC Health"

  page <- nc_html_text("roots_page")
  if (!stringr::str_detect(page, stringr::fixed(page_name))) {
    stop("[NC] the standing Hub Leads page no longer says '", page_name,
         "'. The two-spelling finding rests on it.", call. = FALSE)
  }
  if (!stringr::str_detect(page, stringr::fixed("public academic medical center"))) {
    stop("[NC] the Hub Leads page no longer calls UNC Health 'a public ",
         "academic medical center'. That sentence is the ONLY reason this ",
         "file types the row UNIVERSITY_OR_AHC rather than taking either of ",
         "the two machine answers the two spellings give.", call. = FALSE)
  }

  cls <- rhtp_classify_recipient_type(c(release_name, page_name), NC_STATE)
  if (identical(cls$recipient_type[1], cls$recipient_type[2])) {
    stop("[NC] the two spellings of the Region 4 Hub Lead now classify the ",
         "SAME way (", cls$recipient_type[1], "). The divergence was the ",
         "point: it is what shows a fuzzy name merge changing a CODING and ",
         "not merely a count. Re-read before relying on either.",
         call. = FALSE)
  }
  if (!identical(cls$recipient_type[1], "HOSPITAL_OR_SYSTEM")) {
    stop("[NC] '", release_name, "' no longer classifies HOSPITAL_OR_SYSTEM ",
         "on the name rule; it now reads ", cls$recipient_type[1], ".",
         call. = FALSE)
  }

  rows <- nc_award_rows()
  k <- which(rows$awardee == release_name)
  if (length(k) != 1L || rows$recipient_type[k] != "UNIVERSITY_OR_AHC") {
    stop("[NC] the Region 4 Hub Lead is no longer typed UNIVERSITY_OR_AHC ",
         "from NCDHHS's own description.", call. = FALSE)
  }
  invisible(cls$recipient_type)
}

#' The two rows where the roster's own name and NCDHHS's class sentence disagree
#'
#' Both are worth $0 in either direction, because North Carolina publishes no
#' per-recipient amount at all -- so what they move is the state's named-
#' hospital ROW COUNT, which is the only hospital quantity North Carolina
#' supports. Nevada's lesson, one state on.
nc_assert_form_not_stated_queued <- function(rows = NULL) {
  if (is.null(rows)) rows <- nc_award_rows()
  for (nm in NC_QUEUED_FORM_ROWS) {
    k <- which(rows$awardee == nm)
    if (length(k) != 1L) {
      stop("[NC] '", nm, "' is not on the MIH roster exactly once.",
           call. = FALSE)
    }
    if (rows$recipient_type[k] != "NONPROFIT_CBO" ||
        rows$determination_confidence[k] != "LOW" ||
        !grepl("RECIPIENT_TYPE_INFERRED", rows$flag_reason[k], fixed = TRUE)) {
      stop("[NC] '", nm, "' has been promoted off §8's standing fallback. ",
           "NOTHING may be promoted on this pipeline's own knowledge of what ",
           "the organisation is (§0.4) -- the archive says nothing about it ",
           "beyond the name, and NCDHHS's own sentence calls all 39 'local ",
           "EMS agencies'. Resolve it in the review queue, not here.",
           call. = FALSE)
    }
    if (rows$distributed_to_hospital[k] != "No") {
      stop("[NC] '", nm, "' is no longer distributed_to_hospital = No.",
           call. = FALSE)
    }
  }
  # AND THE OTHER THIRTY-SEVEN AGREE WITH NCDHHS'S OWN CLASS SENTENCE, which is
  # what makes the two above stand out rather than being two of thirty-nine
  # unknowns.
  mih <- rows[rows$award_pool == NC_POOL_MIH, ]
  ems <- sum(mih$recipient_type == "EMS_OR_PSAP")
  if (ems != NC_MIH_COUNT - length(NC_QUEUED_FORM_ROWS)) {
    stop("[NC] ", ems, " of the ", NC_MIH_COUNT, " MIH rows type EMS_OR_PSAP ",
         "on the name rule, not ", NC_MIH_COUNT - length(NC_QUEUED_FORM_ROWS),
         ". Two independent readings -- the names and NCDHHS's own '39 local ",
         "EMS agencies' -- agreed on all but the queued rows, and that ",
         "agreement is what the queue's two exceptions are measured against.",
         call. = FALSE)
  }

  # AND THE QUESTIONS ARE ACTUALLY IN THE QUEUE. A row left at §8's fallback
  # with nobody asked about it is not §0.4 discipline, it is an omission.
  q <- readr::read_csv(NC_REVIEW_QUEUE, show_col_types = FALSE,
                       progress = FALSE)
  for (id in c("NC_MIH_FORM_NOT_STATED", "NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY")) {
    if (!any(q$question_id == id)) {
      stop("[NC] '", id, "' is not in ", NC_REVIEW_QUEUE, ". The rows this ",
           "file leaves at §8's standing fallback are only honest while the ",
           "question is open somewhere a human will read it.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The five Hub Leads are pass-through rows in NEITHER bucket (§10.2, §0.3)
nc_assert_hub_leads_unresolved <- function(rows = NULL) {
  if (is.null(rows)) rows <- nc_award_rows()
  hub <- rows[rows$award_pool == NC_POOL_ROOTS, ]
  if (nrow(hub) != NC_ROOTS_COUNT) {
    stop("[NC] the ROOTS pool holds ", nrow(hub), " rows, not ",
         NC_ROOTS_COUNT, ".", call. = FALSE)
  }
  if (!all(hub$flow_type == "PASS_THROUGH_UNRESOLVED") ||
      !all(hub$distributed_to_hospital == "Unclear")) {
    stop("[NC] a Hub Lead has left PASS_THROUGH_UNRESOLVED / Unclear. NCDHHS ",
         "names no subrecipient and restricts eligibility to no class, so ",
         "§10.2's second clause is not met -- this is New Hampshire's FHC ",
         "answer, NOT Illinois's ICAHN answer, and coding it `Yes` would put ",
         "an unpriced regional pass-through into a hospital bucket on this ",
         "pipeline's authority (§0.3).", call. = FALSE)
  }
  if (!all(hub$hospital_attribution == "NOT_HOSPITAL")) {
    stop("[NC] a Hub Lead row now carries a hospital bucket.", call. = FALSE)
  }
  if (!all(is.na(hub$round_amount))) {
    stop("[NC] the ROOTS rows now carry a `round_amount`. NCDHHS publishes no ",
         "per-hub and no ROOTS pool figure; the only currency on either ROOTS ",
         "document is the $213,008,356.47 ALLOTMENT, and putting it there ",
         "would publish the whole state award as five hub awards (§0.2).",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Every categorical value against `vocabularies.csv` (§5)
nc_assert_vocabulary <- function(rows = NULL) {
  if (is.null(rows)) rows <- nc_award_rows()
  checks <- list(
    recipient_type          = "recipient_type",
    distributed_to_hospital = "distributed_to_hospital",
    recipient_confirmed     = "recipient_confirmed",
    amount_confirmed        = "amount_confirmed",
    determination_confidence = "determination_confidence",
    flow_type               = "flow_type",
    hospital_attribution    = "hospital_attribution",
    validation_source_type  = "source_doc_type"
  )
  for (col in names(checks)) {
    allowed <- rhtp_vocabulary(checks[[col]])
    bad <- setdiff(as.character(stats::na.omit(unique(rows[[col]]))), allowed)
    if (length(bad)) {
      stop("[NC] value(s) outside §8 in `", col, "`: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  allowed_flags <- rhtp_vocabulary("flag_reason")
  used <- unique(unlist(strsplit(stats::na.omit(rows$flag_reason), ";")))
  used <- used[nzchar(used)]
  bad <- setdiff(used, allowed_flags)
  if (length(bad)) {
    stop("[NC] flag_reason value(s) outside §8: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

#' `round_amount` is a POOL figure and must never be summed down the column
nc_reconcile <- function(rows = NULL) {
  if (is.null(rows)) rows <- nc_award_rows()
  pools <- rows %>%
    dplyr::distinct(award_pool, round_awards, round_amount) %>%
    dplyr::arrange(award_pool)
  naive <- sum(rows$round_amount, na.rm = TRUE)
  published <- sum(pools$round_amount, na.rm = TRUE)
  if (published != NC_MIH_POOL) {
    stop("[NC] the distinct pool total is ", published, ", not ", NC_MIH_POOL,
         ".", call. = FALSE)
  }
  if (naive == published) {
    stop("[NC] summing `round_amount` down the column no longer overstates ",
         "the published total. That trap is the reason nc_reconcile() exists ",
         "(Georgia's rule, Nevada's device); if it has gone, the column's ",
         "shape has changed and this function is no longer the right check.",
         call. = FALSE)
  }
  list(pools = pools, published = published, naive_wrong_total = naive)
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
          "Cape Fear Valley Mobile Integrated Health is the one name that",
          "does not read as a county EMS agency, and it is QUEUED rather",
          "than promoted (§0.4). EXTRACTED in session 38:",
          "nc_year1_awardees.csv, 39 rows, `amount` empty on every one."),
    NC_STATE, "NC ROOTS Hub Leads",
    "AWARDED_ROSTER_PUBLISHED", "Yes", 5L, "2026-05-01",
    paste("FIVE named awardees across SIX regions (Trillium holds two).",
          "'Programmatic and FIDUCIARY leads' -- so unlike Missouri's Hub",
          "Anchors these are pass-through recipients. NO per-hub amount is",
          "published anywhere; the only figure on the page is the",
          "ALLOTMENT. Contracts were to be finalised by 2026-06-01, which",
          "has PASSED. One lead is an academic medical centre (UNC), under",
          "TWO SPELLINGS across two documents that CLASSIFY DIFFERENTLY.",
          "EXTRACTED in session 38: 5 rows, PASS_THROUGH_UNRESOLVED and",
          "Unclear, in NEITHER bucket -- hospitals AMONG OTHERS (§0.3)."),
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


# -- the live probe -----------------------------------------------------------

#' Re-read the watched pages LIVE and run the tripwires against the live bytes
#'
#' `--validate` reads the committed archive and therefore passes trivially: it
#' can only answer "was this true on the day the archive was taken?". Session
#' 25's Indiana lesson as code -- the only thing that answers the question is a
#' fetch.
#'
#' IT COMPARES A CONTENT DIGEST, NOT A FILE DIGEST, and North Carolina is the
#' state that proves why a back-to-back pair is not enough to decide that.
#' `ncdhhs.gov` injects a Dynatrace RUM beacon (`ruxitagentjs`) whose
#' `data-dtconfig` attribute carries a per-request `rpid`: four fetches gave
#' three distinct SHA-256s AND FETCHES 1 AND 2 WERE IDENTICAL. A pair would
#' have reported this host stable. The nonce is attribute-borne, so the
#' tag-stripping reduction absorbs it free.
#'
#' WHAT IT IS WATCHING FOR, IN ORDER OF WHAT IT WOULD MEAN.
#'   1. THE SECOND TIER AWARDING. Each Hub Lead runs its own regional funding
#'      opportunities and that is where North Carolina's hospital money will
#'      be. `nc_assert_positive_control()` fails the day a Hub Lead's own page
#'      carries "awarded", "awardee" or "selected for".
#'   2. A PER-RECIPIENT AMOUNT APPEARING. `amount` is empty on all 44 rows and
#'      that is only honest while NCDHHS publishes none. If one appears,
#'      `nc_year1_awardees.csv` must be REWRITTEN, not patched.
#'   3. A THIRD ROSTER. Two opportunities closed with no roster and both their
#'      application dates have passed (2026-07-17, 2026-08-12), and the Rural
#'      Health Innovation Fund ($20M annually) "will launch this fall".
nc_probe <- function() {
  keys <- c("pr_mih", "pr_roots", "roots_page", "opportunities", "trillium")
  live <- purrr::map(keys, function(k) {
    b <- nc_get(nc_source(k, "url"), k)
    Sys.sleep(2)
    b
  })
  names(live) <- keys

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key              = k,
      archived_content = nc_content_digest(k),
      live_content     = nc_content_digest(k, live[[k]]),
      archived_file    = digest::digest(file = nc_path(k), algo = "sha256"),
      live_file        = digest::digest(live[[k]], algo = "sha256",
                                        serialize = FALSE))
  }) %>%
    dplyr::mutate(
      content_changed = .data$archived_content != .data$live_content,
      file_changed    = .data$archived_file != .data$live_file)

  # THE TRIPWIRES, AGAINST THE LIVE BYTES.
  nc_assert_mih_roster(body = live$pr_mih)
  nc_assert_hub_leads(bodies = live)
  nc_assert_roots_page_has_no_pool(body = live$roots_page)
  nc_assert_positive_control(bodies = live)
  mih   <- nc_mih_roster(body = live$pr_mih)
  roots <- nc_hub_lead_roster(body = live$pr_roots)

  message("[NC] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-14s content %s   file %s", r$key,
                    if (r$content_changed) "CHANGED" else "unchanged",
                    if (r$file_changed) "differs (expected -- Dynatrace rpid)"
                    else "unchanged"))
  })
  message("[NC] rosters live: ", nrow(mih), " MIH recipients, ", nrow(roots),
          " ROOTS Hub Leads. All tripwires pass -- no per-recipient amount, ",
          "no third roster, and the SECOND TIER still names nobody.")
  invisible(cmp)
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
  rows <- nc_award_rows()
  nc_assert_row_count_is_the_finding(rows)
  nc_assert_unc_two_spellings()
  nc_assert_form_not_stated_queued(rows)
  nc_assert_hub_leads_unresolved(rows)
  nc_reconcile(rows)
  nc_assert_vocabulary(rows)
  nc_assert_extracted()
  message("[NC] all assertions pass -- ", nrow(rows), " award actions, ",
          "$0 attributable to any recipient.")
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

  rows <- nc_award_rows()
  nc_assert_row_count_is_the_finding(rows)
  nc_assert_form_not_stated_queued(rows)
  nc_assert_hub_leads_unresolved(rows)
  nc_assert_vocabulary(rows)
  readr::write_csv(rows, NC_AWARDEES_CSV, na = "")
  message("[NC] wrote ", NC_AWARDEES_CSV, " (", nrow(rows), " rows, ",
          "amount EMPTY on every one)")
  invisible(list(status = st, awardees = rows))
}

nc_report <- function() {
  st   <- nc_status_table()
  rows <- nc_award_rows()
  rec  <- nc_reconcile(rows)

  cat("\nNORTH CAROLINA -- 44 NAMED RECIPIENTS, TWO ROSTERS, AND NOT ONE\n")
  cat("PER-RECIPIENT DOLLAR.\n")
  cat(strrep("=", 72), "\n\n")
  cat("Allotment (§7.1)      : $", format(NC_ALLOTMENT, big.mark = ","),
      "\n", sep = "")
  cat("RCJ Tier 3 candidates : 0 -- invisible to BOTH discovery layers,\n")
  cat("                        exactly as Florida was with 81 awards.\n\n")

  print(as.data.frame(st[, c("channel", "stage", "named_recipients")]),
        row.names = FALSE)

  cat("\nAWARD ACTIONS EXTRACTED:", nrow(rows), "\n")
  pools <- as.data.frame(rec$pools)
  pools$round_amount <- ifelse(is.na(pools$round_amount), "-- none published",
                               format(pools$round_amount, big.mark = ",",
                                      scientific = FALSE))
  print(pools, row.names = FALSE)
  cat("\nPublished pool total (distinct pools): $",
      format(rec$published, big.mark = ",", scientific = FALSE), "\n", sep = "")
  cat("Summing `round_amount` down the column instead: $",
      format(rec$naive_wrong_total, big.mark = ",", scientific = FALSE),
      "  <- NEVER do this (Georgia's trap)\n", sep = "")
  cat("sum(amount): ", sum(rows$amount, na.rm = TRUE),
      "  -- and `amount` is EMPTY on all ", nrow(rows), " rows.\n", sep = "")

  cat("\nRECIPIENT TYPES\n")
  print(as.data.frame(dplyr::count(rows, award_pool, recipient_type,
                                   flow_type, distributed_to_hospital)),
        row.names = FALSE)

  cat("\nHOSPITAL DOLLAR PARTITION\n")
  part <- rhtp_hospital_dollar_partition(rows)
  if (nrow(part) == 0L) {
    cat("  NO BUCKET AT ALL. North Carolina contributes 0 rows and $0 to\n")
    cat("  NAMED_HOSPITAL, POOL_NAMED_HOSPITALS and POOL_UNNAMED_HOSPITALS\n")
    cat("  alike -- Maine's and Missouri's shape, NOT Nevada's or Iowa's.\n")
    cat("  Nevada and Iowa publish named HOSPITALS with no amounts, so their\n")
    cat("  danger is quoting the $0 without the row count. North Carolina's\n")
    cat("  44 named recipients are county EMS agencies and regional\n")
    cat("  pass-through leads, and its named-hospital ROW COUNT is 0 --\n")
    cat("  which is a coding decision under review, not a fact about the\n")
    cat("  state. See the two queued rows below.\n")
  } else {
    print(as.data.frame(part), row.names = FALSE)
  }

  cat("\nQUEUED, AND WORTH $0 EITHER WAY BECAUSE NOTHING IS PRICED\n")
  q <- rows[rows$awardee %in% NC_QUEUED_FORM_ROWS, c("awardee", "recipient_type")]
  print(as.data.frame(q), row.names = FALSE)
  cat("  Plus THREE Hub Leads whose form NCDHHS STATES and §8 has no code\n")
  cat("  for: 'Managed Care Organization' (x2), 'comprehensive care\n")
  cat("  management provider'. No code was invented (§2).\n")

  cat("\nTHE SECOND TIER -- where North Carolina's hospital money will be --\n")
  cat("NAMES NOBODY. Each Hub Lead runs its own regional opportunities;\n")
  cat("Trillium's Region 2 page carries no recipient at all.\n")
  invisible(list(status = st, awardees = rows))
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) nc_fetch(force = "--force" %in% args)
  if ("--probe" %in% args) nc_probe()
  if ("--validate" %in% args) nc_validate()
  if ("--build" %in% args) nc_build()
  if ("--report" %in% args) nc_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --probe | --validate | --build | --report")
  }
}

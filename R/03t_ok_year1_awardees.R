# 03t_ok_year1_awardees.R -----------------------------------------------------
# Oklahoma Year 1 -> data/reference/ok_year1_awardees.csv
#
# WHY OKLAHOMA. It led `state_trigger_queue.csv` after Indiana was worked out --
# queue rank 1, 35 Tier 3 candidates, 25 distinct awardees, a $223,476,949
# allotment, no CMS press release. And it is the ONE state where a
# recipient-level extraction can be checked against a §7A initiative table this
# repository already holds: `OK_initiative_table.xlsx`, 28 fund uses,
# $204,900,000 allocated, 48.7% hospital-directed AT INITIATIVE LEVEL. That
# check is the point of this session and its answer is in `ok_report()`.
#
# WHAT OKLAHOMA PUBLISHES, AND WHERE. OSDH runs RHTP off `oklahoma.gov/health`
# and publishes a dedicated **RHTP Funding Recipients** page. It carries an
# "Awardees" navigation with exactly TWO anchors -- `#roots` and `#microgrants`
# -- and its own opening sentence says what it is: "This page provides
# information about funded projects, award amounts, and the organizations
# selected to receive RHTP funding. As new funding opportunities are awarded,
# recipient information will be added to this page."
#
#   Community-Led Wellness Hubs: Microgrants   68 awards   $3,572,120.71
#     -- 74 counties listed, one block per county: the county, the recipient
#        and the amount, then OSDH's own sentence on what the money buys.
#        SIXTY-EIGHT carry a recipient and an amount. SIX say "No Awardee".
#   OSDE's ROOTS Competitive Grant             60 awards   $600,000
#     -- "sixty (60) PK-12 rural school sites for a $10,000 grant". A COUNT AND
#        A UNIT PRICE, AND NO ROSTER. South Dakota's lesson: a count is not a
#        list (§0.3).
#
# So Oklahoma is 69 rows: 68 named microgrant awards, and ONE aggregate row for
# ROOTS carrying an EMPTY `amount` with the $600,000 in `round_amount` -- South
# Dakota's device, so no sum over `amount` can read as a per-recipient figure
# (§6.2). `sum(amount)` is exactly the microgrant total and nothing else.
#
# THE §6.2 PROVENANCE TEST PASSES IN THE STRONGEST FORM THIS PROJECT HAS SEEN,
# AND THE AWARD PAGE ITSELF CARRIES IT. Every OSDH RHTP page and every RHTP PDF
# ends with: "This publication is supported by the Centers for Medicare &
# Medicaid Services (CMS) of the U.S. Department of Health and Human Services
# (HHS) as part of a financial assistance award totaling $223,476,948.62 with
# 100 percent funded by CMS/HHS." That is the awarding agency's own figure on
# the recipient roster, and it matches `cms_fy2026_allotments.csv`'s
# $223,476,949 to the dollar once rounded. The DATE test passes too: the
# microgrant NOFO was announced 2026-03-16 with applications due 2026-04-13,
# both AFTER Oklahoma's 2025-12-29 CMS Notice of Award. Texas's HHS0015180
# closed 2025-04-24, eight months before its state had the money.
#
# §0.1 -- AND THE INDIANA LESSON IS WHY THE CANDIDATE LIST IS NOT THE INPUT.
# NOT ONE of RCJ's 35 Oklahoma Tier 3 candidates is one of these 68 awards.
# Every one of the 35 is a BUDGET LINE mined out of a Tier 2 planning document:
# 8 from the Budget Narrative, 8 from the Initiative Funding Summary, 17 from
# the two Legislative Quarterly Reports, 1 from a touchpoint webinar deck and 1
# $1 placeholder. Their "awardees" are OHCA, OSDH, OSDE,
# OSU, OUHSC, SWODA, the Oklahoma Hospital Association and the Foundation for a
# Healthy Oklahoma -- the ADMINISTERING agencies, not subrecipients -- and the
# amounts are what the Q2 report itself defines, in its own glossary, as
# "Y1 Budget Allocation: The amount of funds dedicated to the program."
# An extractor built from the candidate list would have published
# **$231,614,376** of programme allocations as Oklahoma's Tier 3 subawards --
# MORE THAN THE ENTIRE $223,476,949 ALLOTMENT, and 65 times the $3,572,120.71
# Oklahoma has actually awarded to named recipients. Texas's $16.8M and
# Indiana's ~$147M in a state that has published a real roster the aggregator
# does not hold a single row of.
#
# THE POSITIVE CONTROL, AND ITS RATIO IS THE LOAD-BEARING PART. "The other
# opportunities have published no roster" is a finding only because OSDH
# demonstrably publishes rosters in a recognisable form: a Funding Recipients
# page whose "Awardees" navigation carries one anchor per awarded opportunity.
# OSDH is running TEN funding opportunities (two open, eight closed) and has
# published awardees for TWO. `ok_assert_award_index()` asserts both anchors
# present and REFUSES A THIRD -- the day a third appears, Oklahoma has awarded
# something this file does not carry. The five closed opportunities with no
# roster each have a reason on the page or in the Q2 report: Chronic Disease
# Management ("awards anticipated to start early fall", $15M anticipated),
# Rural Regional Reorientation ("pending scoring", $20M anticipated), EMS &
# Community Paramedicine Vehicles ($3.675M), Expanding Care: Doulas ($2.5M),
# Behavioral Health Integration ($2.8M). `ok_assert_pending_not_awarded()`
# fails the day any of them names a recipient -- IT IS DESIGNED TO FAIL, and
# the failure is the signal.
#
# THE SIX "NO AWARDEE" COUNTIES ARE THE PARSE'S OWN NEGATIVE CONTROL. Beckham,
# Canadian, Cherokee, Love, Nowata and Pawnee are printed in the same block
# shape as the other 68 and say "No Awardee -- There were no [eligible]
# applications submitted from <X> County." A parser that read the block shape
# and not the content would produce 74 award rows and six invented recipients.
# `ok_assert_no_awardee_counties()` requires exactly those six, by name, to be
# present in the source and absent from the awards.
#
# THE HOSPITAL FIGURE IS A FLOOR AND THE UNCERTAINTY IS LARGER THAN IT --
# KANSAS'S, MARYLAND'S AND NEBRASKA'S SHAPE A FOURTH TIME. OSDH publishes a
# county, a recipient, an amount and a project sentence, and NOTHING about the
# recipient's organisational form -- no column of the kind Oregon and Alaska
# both have. So 20 award actions to 18 named hospitals ($1,079,506.22) classify
# on the recipient's own NAME, and 31 rows / $1,575,304.25 carry §8's standing
# fallback. HERE THE UNCERTAINTY RUNS ONLY UPWARD: every fallback row is
# `distributed_to_hospital = No`, so promoting any of them can only raise the
# figure, and several plainly read as hospitals to anyone who knows Oklahoma --
# DRH Health (Duncan Regional Hospital, two counties, $66,608.44), SSM Health
# St. Anthony Shawnee, Marshall County HMA dba AllianceHealth Madill, Baptist
# Healthcare, Fairfax Medical Facilities and Avem Health Partners.
# NOTHING WAS PROMOTED (§0.4). Queued as `OK_RECIPIENT_FORM_NOT_STATED`.
#
# TWO ROWS ARE TYPED FROM THE SOURCE RATHER THAN THE FALLBACK, AND BOTH MOVE
# $0. OSDH's own award paragraph calls Stigler HWC "a Federally Qualified
# Health Center (FQHC)" -- the awarding agency stating the recipient's federal
# designation in the award document, which is Indiana's precedent for typing
# from the source. And Choctaw Nation of Oklahoma is a federally recognised
# tribe that the §8 tribal pattern cannot reach, because that pattern keys on
# tribal/tribe/native village/band of and not on the "Nation" styling. Both are
# recorded in `utils_recipient_classification.R`'s state override table with
# their reasons, and both are `distributed_to_hospital = No` either way.
#
# WHAT THIS FILE DELIBERATELY DOES NOT CONTAIN.
#   * The Q1/Q2 "Funded Entity" tables. They are Tier 2 by the reports' own
#     glossary (see §0.1 above) and unioning them with these 69 rows is exactly
#     what §0.2 forbids. They are dispositioned, not extracted.
#   * The 11 hospitals selected for the Lung Cancer Screening Program. The Q2
#     report says "11 hospitals selected with 9 hospital MOU's in progress" and
#     NAMES NONE of them. A count is not a list (§0.3), and
#     `ok_assert_lung_screening_unnamed()` fails the day OSDH names them.
#   * A Tier 2 initiative row of any kind. `OK_initiative_table.xlsx` is the
#     §7A artifact and stays separate.
#
# Sources, all archived under data/evidence/OK/ with a SHA-256 manifest.

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_pdf_text.R"))


# -- configuration ------------------------------------------------------------

OK_STATE           <- "OK"
OK_FISCAL_YEAR     <- "FY2026 (Year 1)"
OK_EVIDENCE_DIR    <- here::here("data", "evidence", "OK")
OK_CSV             <- "data/reference/ok_year1_awardees.csv"
OK_DISPOSITION_CSV <- "data/reference/ok_rcj_candidate_disposition.csv"
OK_XLSX            <- "OK_year1_awardees.xlsx"
OK_REVIEW_QUEUE    <- "data/reference/classification_review_queue.csv"
OK_FORM_NOT_STATED_QUESTION <- "OK_RECIPIENT_FORM_NOT_STATED"
OK_HOST_THROTTLE_S <- 2
OK_USER_AGENT      <- "AHA-RHTP-Tracker/1.0 (research; +https://www.aha.org)"

OK_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  google_api_key = "AIza[0-9A-Za-z_-]{30,}",
  generic_apikey = "(?i)api[_-]?key\\s*[:=]\\s*[\"'][A-Za-z0-9._-]{16,}[\"']",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)

# The CMS financial-assistance figure OSDH prints on every RHTP publication.
# It is compared to the §7.1 anchor rather than typed as a claim about CMS.
OK_CMS_FOOTER_AMOUNT <- 223476948.62
OK_CMS_FOOTER <- paste(
  "as part of a financial assistance award totaling $223,476,948.62 with 100",
  "percent funded by CMS/HHS")

# What OSDH itself states, so a change in the source fails rather than passes.
OK_STATED <- list(
  microgrant_awards        = 68L,     # Q2 report: "OSDH issued 68 awards"
  counties_listed          = 74L,
  no_awardee_counties      = 6L,
  microgrant_total         = 3572120.71,   # derived; the count is what OSDH states
  microgrant_cap_county    = 100000,       # "up to $100,000 per county"
  roots_awards             = 60L,          # Q2: "60 awards totalling $600K"
  roots_unit               = 10000,
  roots_total              = 600000,
  # The same fund use, in the two Tier 2 documents that carry it. They differ,
  # which is a fact about Oklahoma's own revisions and is reported, not resolved.
  microgrant_alloc_ifs     = 2800000,      # Initiative Funding Summary, 03.10.26
  microgrant_alloc_q2      = 7750000,      # Legislative Quarterly Report, 07.10.26
  initiative_allocated     = 204900000,    # OK_initiative_table.xlsx, all 28 uses
  initiative_hospital      = 99800000,     # has_hospital_recipient == "Yes"
  initiative_pct_hospital  = 48.7,
  rcj_candidates           = 35L,
  rcj_distinct_awardees    = 25L,
  rcj_amount_sum           = 231614376.02
)

OK_NOA_DATE       <- as.Date("2025-12-29")   # cross-checked against the anchor
OK_NOFO_ANNOUNCED <- as.Date("2026-03-16")
OK_NOFO_DUE       <- as.Date("2026-04-13")

# The six counties OSDH publishes with no awardee. Named, because a parser that
# lost them would be indistinguishable from one that never met them.
OK_NO_AWARDEE_COUNTIES <- c("Beckham", "Canadian", "Cherokee", "Love",
                            "Nowata", "Pawnee")

# The closed opportunities OSDH has NOT published a roster for. Each is a
# tripwire: the day one names a recipient, this file is materially incomplete.
OK_PENDING_OPPORTUNITIES <- c(
  "Emergency Medical Service & Community Paramedicine Vehicles",
  "Expanding Care: Doulas Program",
  "Rural Regional Reorientation (RRR) Program",
  "Chronic Disease Management Program",
  "Behavioral Health Integration - Medications for Opioid and Alcohol Use Disorder"
)

# The two awarded sections, by their anchor on the Funding Recipients page.
OK_AWARDED_ANCHORS <- c("roots", "microgrants")

OK_SOURCES <- tibble::tribble(
  ~key,             ~file,                                              ~url,
  "recipients",     "2026-08-31_ok_rhtp_funding_recipients.html",
  "https://oklahoma.gov/health/rhtp/rhtp-funding-recipients.html",
  "funding",        "2026-08-31_ok_rhtp_funding.html",
  "https://oklahoma.gov/health/rhtp/rhtp-funding.html",
  # `oklahoma.gov/health/rhtp.html` and the long community-outreach URL serve
  # BYTE-IDENTICAL bodies (same SHA-256, same length): they are two paths onto
  # one AEM page, not two documents. Archiving both would put the same file in
  # the evidence directory twice under two names and invite a reader to treat
  # them as corroborating each other. The alias is recorded in the manifest and
  # asserted below instead.
  "program",        "2026-08-31_ok_rhtp_home.html",
  "https://oklahoma.gov/health/rhtp.html",
  "nofo_release",   "2026-03-16_ok_microgrant_nofo_announcement.html",
  "https://oklahoma.gov/health/news---events/newsroom/2026/oklahoma-rural-health-transformation-program-announces-public-gr.html",
  "ifs",            "2026-03-10_ok_rhtp_initiative_funding_summary.pdf",
  "https://oklahoma.gov/content/dam/ok/en/health/health2/aem-documents/health-promotion/rhtp/RHTP_InitiativeFundingSummary.pdf",
  "q1",             "2026-06-03_ok_rhtp_legislative_quarterly_report_q1.pdf",
  "https://oklahoma.gov/content/dam/ok/en/health/health2/aem-documents/health-promotion/rhtp/06-03-26%20RHTP%20Legislative%20Quarterly%20Report_Q1.pdf",
  "q2",             "2026-07-10_ok_rhtp_legislative_quarterly_report_q2.pdf",
  "https://oklahoma.gov/content/dam/ok/en/health/health2/aem-documents/health-promotion/rhtp/07-10-26%20RHTP%20Legislative%20Quarterly%20Report_Q2.pdf",
  "quick_summary",  "2026-08-31_ok_rhtp_quick_summary.pdf",
  "https://oklahoma.gov/content/dam/ok/en/health/health2/aem-documents/health-promotion/rhtp/RHTP_QuickSummary.pdf"
)


# -- fetch --------------------------------------------------------------------

ok_source <- function(key, field) {
  row <- OK_SOURCES[OK_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[OK] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ok_path <- function(key) file.path(OK_EVIDENCE_DIR, ok_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
ok_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(OK_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, OK_CREDENTIAL_SHAPES[[nm]])) {
      stop("[OK] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ok_get <- function(url, label) {
  message("[OK] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(OK_USER_AGENT), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[OK] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  ok_assert_credential_free(served, label)
  served
}

ok_fetch <- function(force = FALSE) {
  dir.create(OK_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(OK_SOURCES)), function(i) {
    src  <- OK_SOURCES[i, ]
    dest <- file.path(OK_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[OK] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(OK_HOST_THROTTLE_S)
      writeBin(ok_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  ok_cache_clear()
  ok_write_manifest(entries)
  entries
}

ok_write_manifest <- function(entries) {
  path <- file.path(OK_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Oklahoma -- RHTP Year 1: the OSDH Funding Recipients roster, the funding",
    "page that is its positive control, the programme pages, the microgrant",
    "NOFO announcement, and the four RHTP publications that carry the CMS",
    "financial-assistance footer.",
    "Archived by R/03t_ok_year1_awardees.R --fetch",
    paste0("User-agent: ", OK_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard that caught CMS's Mapbox token, Illinois's and Oregon's,",
    "and Kansas's Google Maps key runs on every fetch here and finds nothing,",
    "so there is no reduction to explain and the pages are whole.",
    "",
    "`..._rhtp_home.html` IS SERVED AT TWO URLs. oklahoma.gov/health/rhtp.html",
    "and oklahoma.gov/health/community-health-and-wellness/community-outreach/",
    "rural-health-transformation.html return byte-identical bodies -- the same",
    "SHA-256 and the same 694,330 bytes. They are two paths onto one AEM page,",
    "so it is archived ONCE. The second URL is where /api/v1/activity reports",
    "Oklahoma's source documents, which is how this file found the site.",
    "",
    "THE ROSTER IS `..._funding_recipients.html`. It carries an \"Awardees\"",
    "navigation with exactly two anchors, #roots and #microgrants, which is",
    "OSDH's own index of what it has awarded. `..._rhtp_funding.html` is the",
    "positive control beside it: ten funding opportunities, two open and eight",
    "closed, and a roster published for two of them.",
    "",
    "THE FOUR PDFs ARE NOT AWARD DOCUMENTS AND ARE NOT EXTRACTED FROM. They",
    "are Tier 2 (§0.2): the Initiative Funding Summary is the §7A source for",
    "OK_initiative_table.xlsx, and the two Legislative Quarterly Reports",
    "publish a per-programme \"Y1 Budget Allocation\", which their own glossary",
    "defines as \"the amount of funds dedicated to the program\". They are",
    "archived because they are what disposes of all 35 RCJ Tier 3 candidates,",
    "and because the Q2 report independently corroborates both award counts:",
    "\"OSDH issued 68 awards through the competitive Microgrant application\"",
    "and \"60 awards totalling $600K to local schools\".",
    "",
    paste0("Fetched: ", Sys.Date()),
    "",
    sprintf("%-52s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 52 + 12 + 64)
  ), path)
  cat(sprintf("%-52s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-16s %s", entries$key, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

# A tiny per-session cache: the reader is called by a dozen assertions and the
# PDFs are megabytes. --fetch clears it, because that is the only thing that
# changes what is on disk.
.ok_cache <- new.env(parent = emptyenv())
ok_cache_clear <- function() rm(list = ls(.ok_cache), envir = .ok_cache)
ok_cached <- function(key, fn) {
  if (!exists(key, envir = .ok_cache)) assign(key, fn(key), envir = .ok_cache)
  get(key, envir = .ok_cache)
}

ok_raw <- function(key) {
  p <- ok_path(key)
  if (!file.exists(p)) {
    stop("[OK] ", basename(p), " is not archived. Run --fetch first.",
         call. = FALSE)
  }
  readBin(p, "raw", file.info(p)$size)
}

ok_html_doc <- function(key) {
  txt <- rawToChar(ok_raw(key))
  Encoding(txt) <- "UTF-8"
  xml2::read_html(txt)
}

ok_html_text_raw <- function(key) {
  doc <- ok_html_doc(key)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}
ok_html_text <- function(key) ok_cached(key, ok_html_text_raw)

ok_pdf_text_raw <- function(key) paste(rhtp_pdf_text(ok_path(key)), collapse = " ")
ok_pdf_text <- function(key) ok_cached(paste0("pdf_", key),
                                       function(k) ok_pdf_text_raw(key))


# -- §6.2 provenance ----------------------------------------------------------

#' Oklahoma's FY2026 allotment, out of the §7.1 anchor. Read, never typed --
#' the whole point of the anchor is that a Tier 1 figure comes from CMS.
rhtp_ok_allotment <- function() {
  row <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- row[row$state == OK_STATE, ]
  if (nrow(row) != 1L) {
    stop("[OK] the §7.1 allotment anchor does not carry exactly one OK row.",
         call. = FALSE)
  }
  row$fy2026_allotment[[1]]
}

#' The awarding agency's own statement, on the roster itself and on every RHTP
#' publication: this money is CMS's, and the figure matches §7.1.
ok_assert_rhtp_funded <- function() {
  for (k in c("recipients", "funding", "program", "nofo_release")) {
    if (!stringr::str_detect(ok_html_text(k), stringr::fixed(OK_CMS_FOOTER))) {
      stop("[OK] ", ok_source(k, "file"), " no longer carries the CMS ",
           "financial-assistance footer. §6.2's evidence that this is RHTP ",
           "money comes from that sentence; do not re-run until it is read ",
           "again.", call. = FALSE)
    }
  }
  for (k in c("ifs", "q1", "q2", "quick_summary")) {
    if (!stringr::str_detect(ok_pdf_text(k),
                             stringr::fixed("financial assistance award totaling $223,476,948.62"))) {
      stop("[OK] ", ok_source(k, "file"), " no longer carries the CMS ",
           "financial-assistance figure.", call. = FALSE)
    }
  }

  # And it must agree with the §7.1 anchor, which is read rather than typed.
  ok <- rhtp_ok_allotment()
  if (round(OK_CMS_FOOTER_AMOUNT) != ok) {
    stop("[OK] OSDH's stated $", format(OK_CMS_FOOTER_AMOUNT, nsmall = 2),
         " does not round to the §7.1 allotment of $", format(ok, big.mark = ","),
         ". Two publishers disagreeing about Oklahoma's award is a finding, ",
         "not something to average.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The date half of §6.2 -- Texas's cheapest test. A solicitation that closed
#' before the state had the money cannot have spent it.
ok_assert_after_noa <- function() {
  anchor <- readr::read_csv(
    here::here("data", "reference", "cms_state_noa_dates.csv"),
    show_col_types = FALSE, progress = FALSE)
  noa <- anchor$noa_date[anchor$state == OK_STATE]
  if (length(noa) != 1L) {
    stop("[OK] no CMS Notice of Award date for Oklahoma in the §6.2 anchor.",
         call. = FALSE)
  }
  if (as.Date(noa) != OK_NOA_DATE) {
    stop("[OK] the §6.2 anchor now gives Oklahoma's NOA date as ", noa,
         ", not ", OK_NOA_DATE, ".", call. = FALSE)
  }
  for (d in c(OK_NOFO_ANNOUNCED, OK_NOFO_DUE)) {
    if (as.Date(d, origin = "1970-01-01") <= as.Date(noa)) {
      stop("[OK] a microgrant milestone predates Oklahoma's Notice of Award.",
           call. = FALSE)
    }
  }
  # Both dates must still be on the archived announcement, not just in this file.
  rel <- ok_html_text("nofo_release")
  for (s in c("April 13, 2026", "March 19")) {
    if (!stringr::str_detect(rel, stringr::fixed(s))) {
      stop("[OK] the microgrant NOFO announcement no longer carries '", s,
           "'; the date test's evidence has moved.", call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- the positive control -----------------------------------------------------

#' OSDH publishes rosters in a recognisable form, and has published TWO.
#' Nebraska's award-index control in Oklahoma's own shape, and a tripwire in
#' both directions: it fails if an anchor disappears and fails if a THIRD
#' appears, because a third means Oklahoma has awarded something not in here.
ok_assert_award_index <- function() {
  doc <- ok_html_doc("recipients")
  main <- xml2::xml_find_first(doc, "//main")
  ids <- xml2::xml_attr(xml2::xml_find_all(main, ".//*[@id]"), "id")
  ids <- ids[ids %in% c(OK_AWARDED_ANCHORS, "roots", "microgrants")]
  found <- sort(unique(ids))
  if (!identical(found, sort(OK_AWARDED_ANCHORS))) {
    stop("[OK] the Funding Recipients page's awardee anchors are now {",
         paste(found, collapse = ", "), "}, not {",
         paste(sort(OK_AWARDED_ANCHORS), collapse = ", "),
         "}. If OSDH has published a THIRD roster, this file is materially ",
         "incomplete and must be extended, not re-run.", call. = FALSE)
    }

  # The page must still describe itself as a recipient list, not a plan.
  if (!stringr::str_detect(
        ok_html_text("recipients"),
        stringr::fixed("information about funded projects, award amounts, and the organizations selected to receive RHTP funding"))) {
    stop("[OK] the Funding Recipients page no longer says what it is. Re-read ",
         "it before trusting anything below.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The five closed opportunities with NO roster. DESIGNED TO FAIL: the day one
#' of them names a recipient, Oklahoma's hospital dollars change materially --
#' Chronic Disease Management alone is $15M anticipated and Rural Regional
#' Reorientation $20M, and the initiative table codes RRR hospital-directed.
ok_assert_pending_not_awarded <- function() {
  funding <- ok_html_text("funding")
  for (o in OK_PENDING_OPPORTUNITIES) {
    if (!stringr::str_detect(funding, stringr::fixed(o))) {
      stop("[OK] '", o, "' is no longer on the funding page. The negative ",
           "this file records about it cannot be re-checked; re-read the page.",
           call. = FALSE)
    }
  }
  # None of the five may have gained an awardee section on the roster page.
  recips <- ok_html_text("recipients")
  for (o in OK_PENDING_OPPORTUNITIES) {
    head <- stringr::str_split(o, " - ")[[1]][1]
    if (stringr::str_detect(recips, stringr::fixed(head))) {
      stop("[OK] '", head, "' now appears on the Funding Recipients page. ",
           "Oklahoma has awarded an opportunity this file does not carry -- ",
           "extract it. THIS ASSERTION IS SUPPOSED TO FAIL EVENTUALLY.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' §0.3 -- the Lung Cancer Screening Program's 11 hospitals are a COUNT.
ok_assert_lung_screening_unnamed <- function() {
  q2 <- ok_pdf_text("q2")
  if (!stringr::str_detect(q2, "11 hospitals selected")) {
    stop("[OK] the Q2 report no longer says '11 hospitals selected' for the ",
         "Lung Cancer Screening Program. If OSDH has NAMED them, that is 11 ",
         "hospital recipients this file does not carry.", call. = FALSE)
  }
  # A count is not a list: no hospital may be named against it anywhere OSDH
  # publishes a roster.
  if (stringr::str_detect(ok_html_text("recipients"),
                          stringr::fixed("Lung Cancer Screening"))) {
    stop("[OK] Lung Cancer Screening now appears on the Funding Recipients ",
         "page. Extract it.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the parse ----------------------------------------------------------------

# OSDH marks each county block up as <b>County<br></b>Recipient $amount<br>
# description, several blocks to a <p>. So <br> and </p> are the record
# separator and the block is exactly three lines: county, payment, description.
# The shape is asserted rather than assumed -- 74 counties, 222 lines.
ok_microgrant_lines <- function() {
  ok_cached("mg_lines", function(...) {
    doc <- ok_html_doc("recipients")
    xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
    main <- xml2::xml_find_first(doc, "//main")
    blocks <- xml2::xml_find_all(main, ".//div[contains(@class,'cmp-text')]")
    hit <- which(purrr::map_lgl(blocks, function(b) {
      stringr::str_detect(as.character(b), "\\$[0-9][0-9,]*\\.[0-9]{2}") &&
        stringr::str_detect(as.character(b), "(?i)No Awardee")
    }))
    if (!length(hit)) {
      stop("[OK] the microgrant recipient block is not on the archived page. ",
           "It is identified by carrying BOTH per-recipient amounts and the ",
           "'No Awardee' counties; one of those has changed.", call. = FALSE)
    }
    # AEM renders the same component twice (desktop and mobile). They must be
    # identical -- if they are not, the page is saying two different things and
    # picking one silently is the wrong answer.
    htmls <- purrr::map_chr(hit, function(i) as.character(blocks[[i]]))
    txts <- purrr::map_chr(htmls, function(h) {
      h2 <- stringr::str_replace_all(h, "(?i)<br\\s*/?>", "\n")
      h2 <- stringr::str_replace_all(h2, "(?i)</p>", "\n")
      xml2::xml_text(xml2::read_html(h2))
    })
    if (length(unique(stringr::str_squish(txts))) != 1L) {
      stop("[OK] the Funding Recipients page renders the microgrant list ",
           "more than once and the copies DISAGREE. Read the page.",
           call. = FALSE)
    }
    lines <- stringr::str_split(txts[[1]], "\n")[[1]]
    lines <- stringr::str_squish(stringr::str_replace_all(lines, " ", " "))
    lines[nzchar(lines)]
  })
}

OK_AMOUNT_RE <- "\\$[0-9][0-9,]*(\\.[0-9]{2})?$"

#' 74 blocks of three lines: county, "<recipient> $<amount>" or "No Awardee",
#' and OSDH's own project sentence.
ok_microgrant_blocks <- function() {
  lines <- ok_microgrant_lines()
  if (length(lines) %% 3L != 0L) {
    stop("[OK] the microgrant list is ", length(lines), " lines, which is not ",
         "a whole number of three-line county blocks. The page's shape has ",
         "changed and the parse must be re-read, not re-run.", call. = FALSE)
  }
  n <- length(lines) / 3L
  out <- tibble::tibble(
    county = lines[seq(1, length(lines), by = 3)],
    payment = lines[seq(2, length(lines), by = 3)],
    project_description = lines[seq(3, length(lines), by = 3)]
  )
  # Shape guards. A county is a short proper name; a description is a sentence.
  # Without these a mis-aligned split still produces 74 plausible rows.
  if (any(nchar(out$county) > 24L)) {
    stop("[OK] a county line is longer than 24 characters ('",
         out$county[which.max(nchar(out$county))],
         "'). The three-line block model no longer holds.", call. = FALSE)
  }
  if (any(nchar(out$project_description) < 40L)) {
    stop("[OK] a project description is shorter than 40 characters. The ",
         "three-line block model no longer holds.", call. = FALSE)
  }
  if (nrow(out) != OK_STATED$counties_listed) {
    stop("[OK] the microgrant list carries ", nrow(out), " counties, not ",
         OK_STATED$counties_listed, ". Oklahoma has changed what it publishes.",
         call. = FALSE)
  }
  out
}

#' The 68 awards. The six "No Awardee" counties are dropped HERE, by content,
#' and asserted separately -- they are the parse's own negative control.
ok_microgrant_awards <- function() {
  blocks <- ok_microgrant_blocks()
  awarded <- blocks[stringr::str_detect(blocks$payment, OK_AMOUNT_RE), ]
  awarded %>%
    dplyr::mutate(
      awardee = stringr::str_squish(
        stringr::str_remove(.data$payment, paste0("\\s*", OK_AMOUNT_RE))),
      amount = as.numeric(stringr::str_remove_all(
        stringr::str_extract(.data$payment, OK_AMOUNT_RE), "[$,]"))
    ) %>%
    dplyr::select("county", "awardee", "amount", "project_description")
}

#' Exactly six counties, by name, published with no awardee -- present in the
#' source and absent from the awards. A parser that read the block shape and
#' not the content would produce 74 rows and six invented recipients.
ok_assert_no_awardee_counties <- function(awards = ok_microgrant_awards()) {
  blocks <- ok_microgrant_blocks()
  none <- blocks[!stringr::str_detect(blocks$payment, OK_AMOUNT_RE), ]
  if (!identical(sort(none$county), sort(OK_NO_AWARDEE_COUNTIES))) {
    stop("[OK] the counties published with no awardee are now {",
         paste(sort(none$county), collapse = ", "), "}, not {",
         paste(sort(OK_NO_AWARDEE_COUNTIES), collapse = ", "),
         "}. If a county has gained an awardee, extract it.", call. = FALSE)
  }
  if (!all(stringr::str_detect(none$payment, "(?i)^No Awardee$"))) {
    stop("[OK] a no-awardee county's payment line is not the bare string ",
         "'No Awardee'.", call. = FALSE)
  }
  if (any(none$county %in% awards$county)) {
    stop("[OK] a county OSDH publishes with NO awardee has entered the award ",
         "rows. That is an invented recipient.", call. = FALSE)
  }
  if (!all(stringr::str_detect(none$project_description,
                               "(?i)no (eligible )?applications submitted"))) {
    stop("[OK] a no-awardee county no longer explains itself as 'no ",
         "applications submitted'.", call. = FALSE)
  }
  invisible(TRUE)
}

#' What OSDH states about its own two awarded programmes, in a SECOND document.
#' The Q2 report is not the roster and is not parsed for recipients; it is the
#' independent corroboration that 68 and 60 are the right counts.
ok_assert_stated_counts <- function(awards = ok_microgrant_awards()) {
  if (nrow(awards) != OK_STATED$microgrant_awards) {
    stop("[OK] parsed ", nrow(awards), " microgrant awards; OSDH's Q2 report ",
         "states ", OK_STATED$microgrant_awards, ".", call. = FALSE)
  }
  q2 <- ok_pdf_text("q2")
  if (!stringr::str_detect(q2, "OSDH issued 68 awards")) {
    stop("[OK] the Q2 Legislative Quarterly Report no longer says 'OSDH ",
         "issued 68 awards'. The corroboration for this file's row count is ",
         "gone; re-read it.", call. = FALSE)
  }
  if (!stringr::str_detect(q2, "60 awards totalling \\$600K")) {
    stop("[OK] the Q2 report no longer states ROOTS as '60 awards totalling ",
         "$600K'. The one aggregate row in this file rests on that sentence.",
         call. = FALSE)
  }
  # OSDH's own cap. An amount above it means the page or the rule has changed.
  if (any(awards$amount > OK_STATED$microgrant_cap_county)) {
    stop("[OK] a microgrant exceeds OSDH's stated $100,000 per-county cap.",
         call. = FALSE)
  }
  if (abs(sum(awards$amount) - OK_STATED$microgrant_total) > 0.005) {
    stop("[OK] the microgrant awards sum to $",
         format(sum(awards$amount), nsmall = 2), ", not $",
         format(OK_STATED$microgrant_total, nsmall = 2), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.3 -- ROOTS publishes a COUNT and a UNIT PRICE and NO ROSTER. South
#' Dakota's lesson, and the reason this file's ROOTS row names nobody.
ok_assert_roots_not_named <- function() {
  txt <- ok_html_text("recipients")
  if (!stringr::str_detect(
        txt, stringr::fixed("has selected sixty (60) PK-12 rural school sites for a $10,000 grant"))) {
    stop("[OK] the ROOTS paragraph has changed. It said OSDE 'has selected ",
         "sixty (60) PK-12 rural school sites for a $10,000 grant', which is ",
         "the whole of what this file's ROOTS row rests on. If OSDE has now ",
         "NAMED the sixty, extract them.", call. = FALSE)
  }
  # The ROOTS section runs from its own anchor to the microgrants anchor. No
  # dollar amount other than the $10,000 unit price may appear in it, because a
  # per-school figure would mean OSDE had started publishing recipients.
  doc <- ok_html_doc("recipients")
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  seg <- stringr::str_squish(xml2::xml_text(
    xml2::xml_find_first(doc, "//*[@id='roots']/ancestor::div[contains(@class,'cmp-container')][1]")))
  if (!is.na(seg) && stringr::str_detect(seg, "\\$(?!10,000)[0-9][0-9,]{3,}")) {
    stop("[OK] the ROOTS section now carries a dollar figure other than the ",
         "$10,000 unit price. Re-read it.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- records ------------------------------------------------------------------

#' Oklahoma's 69 rows in the Florida schema (§8, test_state_union).
ok_records <- function() {
  awards <- ok_microgrant_awards()

  classified <- purrr::map_dfr(seq_len(nrow(awards)), function(i) {
    ct <- rhtp_classify_recipient_type(awards$awardee[i], OK_STATE)
    fl <- rhtp_classify_flow(ct$recipient_type, awards$project_description[i])
    tibble::tibble(
      recipient_type = ct$recipient_type,
      determination_confidence = ct$determination_confidence,
      classifier_basis = ct$recipient_type_basis,
      classifier_rule = ct$rule,
      flow_type = fl$flow_type,
      distributed_to_hospital = fl$distributed_to_hospital,
      hospital_benefiting = fl$hospital_benefiting
    )
  })

  micro <- dplyr::bind_cols(awards, classified) %>%
    dplyr::mutate(
      state = OK_STATE,
      award_pool = "MICROGRANTS",
      note = paste0(
        .data$county, " County. ", .data$project_description,
        " Community-Led Wellness Hubs: Microgrants -- applicants were eligible",
        " for awards of up to $100,000 per county (a $50,000 base budget and a",
        " $50,000 supplemental request). OSDH's Q2 Legislative Quarterly Report",
        " states it 'issued 68 awards through the competitive Microgrant",
        " application' and that contracts were in progress at 2026-06-30."),
      recipient_confirmed = "Yes",
      amount_confirmed    = "Yes",
      source_document_title =
        "Oklahoma RHTP Funding Recipients -- Community-Led Wellness Hubs: Microgrants, List of Funding Recipients",
      round_id = "MG", round_name = "Community-Led Wellness Hubs: Microgrants",
      round_awards = OK_STATED$microgrant_awards,
      round_amount = NA_real_,
      amount_basis = "award amount as published per county by OSDH",
      initiative = "Moving Upstream",
      initiative_fund_use = "Community-Led Wellness Hub: Microgrants",
      hospital_attribution = ifelse(
        .data$distributed_to_hospital == "Yes", "NAMED_HOSPITAL", "NOT_HOSPITAL"),
      # §8's standing fallback is the only flag these rows can carry: OSDH
      # publishes an exact amount per recipient, so nothing here is rounded,
      # preliminary or a range.
      flag_reason = ifelse(.data$classifier_rule == "FALLBACK",
                           "RECIPIENT_TYPE_INFERRED", NA_character_),
      recipient_type_source = paste0(
        "OSDH publishes NO organisation-type column; the type is derived from ",
        "the recipient's own name. ", .data$classifier_basis)
    )

  # ROOTS: a count, a unit price and no roster. South Dakota's device --
  # `amount` is EMPTY so no sum over it can read as a per-recipient figure,
  # and the $600,000 round total lives in `round_amount` (§6.2).
  roots <- tibble::tibble(
    state = OK_STATE,
    county = NA_character_,
    awardee = paste0(
      OK_STATED$roots_awards,
      " grants (OSDE's ROOTS Competitive Grant) to PK-12 rural school sites",
      " at $", format(OK_STATED$roots_unit, big.mark = ","),
      " each - recipient names not published"),
    amount = NA_real_,
    project_description = paste(
      "The Oklahoma State Department of Education (OSDE) has selected sixty",
      "(60) PK-12 rural school sites for a $10,000 grant to support",
      "Presidential Fitness Testing and best practices in physical education",
      "instruction aligned to the Oklahoma Academic Standards for Physical",
      "Education."),
    recipient_type = "NOT_YET_NAMED",
    determination_confidence = "LOW",
    classifier_basis = NA_character_,
    classifier_rule = NA_character_,
    flow_type = "NON_HOSPITAL",
    distributed_to_hospital = "No",
    hospital_benefiting = "No",
    award_pool = "ROOTS",
    note = paste(
      "OSDE selected 60 PK-12 rural school sites at $10,000 each and has",
      "published NO roster -- a count and a unit price, not a list (§0.3).",
      "`amount` is deliberately EMPTY and the $600,000 round total is in",
      "`round_amount`, so no sum over `amount` can read as a per-recipient",
      "figure (§6.2, South Dakota's device). distributed_to_hospital is `No`",
      "rather than `Unclear` because OSDE states the recipient CLASS even",
      "though it names no member of it: PK-12 rural school sites are §10.2's",
      "own NON_HOSPITAL worked example, judged on the recipient and not on the",
      "activity (§0.3a). OSDH's Q2 Legislative Quarterly Report corroborates",
      "the round independently: '60 awards totalling $600K to local schools'."),
    recipient_confirmed = "No",
    amount_confirmed = "Yes",
    source_document_title =
      "Oklahoma RHTP Funding Recipients -- OSDE's ROOTS Competitive Grant",
    round_id = "ROOTS", round_name = "OSDE's ROOTS Competitive Grant",
    round_awards = OK_STATED$roots_awards,
    round_amount = OK_STATED$roots_total,
    amount_basis = NA_character_,
    initiative = "Moving Upstream",
    initiative_fund_use = "Presidential Fitness Test Preparation",
    hospital_attribution = "NOT_HOSPITAL",
    flag_reason = "RECIPIENT_NAMES_NOT_CAPTURED",
    recipient_type_source =
      "OSDE names no recipient; the class it states is PK-12 rural school sites."
  )

  recs <- dplyr::bind_rows(micro, roots) %>%
    dplyr::mutate(
      row_no = dplyr::row_number(),
      fiscal_year = OK_FISCAL_YEAR,
      state_source_url = ok_source("recipients", "url"),
      validation_source_type = "NOTICE_OF_AWARD",
      extraction_method = "DIRECT_TEXT",
      validator = "R/03t_ok_year1_awardees.R",
      ccn = NA_character_, aha_id = NA_character_,
      rural_designation = NA_character_, reviewer = NA_character_,
      budget_period = "Budget Period 1",
      intermediary_name = NA_character_,
      source_archive_path = file.path("data", "evidence", "OK",
                                      ok_source("recipients", "file"))
    )

  recs %>%
    dplyr::select(
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      "award_pool", "budget_period", "flow_type", "hospital_benefiting",
      "hospital_attribution", "intermediary_name", "amount_basis",
      "county", "project_description", "round_id", "round_name",
      "round_awards", "round_amount", "initiative", "initiative_fund_use",
      "source_archive_path"
    )
}


# -- assertions on the records ------------------------------------------------

#' `sum(amount)` must be the microgrant total and NOTHING else -- Georgia's and
#' South Dakota's rule, checked rather than described.
ok_assert_amount_column <- function(recs) {
  priced <- recs %>% dplyr::filter(!is.na(.data$amount))
  if (nrow(priced) != OK_STATED$microgrant_awards) {
    stop("[OK] ", nrow(priced), " rows carry an amount; only the ",
         OK_STATED$microgrant_awards, " microgrants may.", call. = FALSE)
  }
  if (abs(sum(priced$amount) - OK_STATED$microgrant_total) > 0.005) {
    stop("[OK] sum(amount) is $", format(sum(priced$amount), nsmall = 2),
         ", not the microgrant total.", call. = FALSE)
  }
  roots <- recs %>% dplyr::filter(.data$award_pool == "ROOTS")
  if (nrow(roots) != 1L || !is.na(roots$amount) ||
      roots$round_amount != OK_STATED$roots_total) {
    stop("[OK] the ROOTS row must be exactly one row with an EMPTY amount and ",
         "$", format(OK_STATED$roots_total, big.mark = ",", scientific = FALSE),
         " in round_amount.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §8 -- every categorical value in the file is inside the vocabulary.
ok_assert_vocabulary <- function(recs) {
  checks <- list(
    recipient_type = "recipient_type",
    distributed_to_hospital = "distributed_to_hospital",
    recipient_confirmed = "recipient_confirmed",
    amount_confirmed = "amount_confirmed",
    determination_confidence = "determination_confidence",
    flow_type = "flow_type",
    hospital_attribution = "hospital_attribution",
    validation_source_type = "source_doc_type"
  )
  for (col in names(checks)) {
    allowed <- rhtp_vocabulary(checks[[col]])
    bad <- setdiff(as.character(stats::na.omit(unique(recs[[col]]))), allowed)
    if (length(bad)) {
      stop("[OK] ", col, " carries value(s) outside §8: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  for (f in stats::na.omit(unique(unlist(
      stringr::str_split(recs$flag_reason, ";"))))) {
    if (!nzchar(f)) next
    if (!f %in% rhtp_vocabulary("flag_reason")) {
      stop("[OK] flag_reason '", f, "' is not in the vocabulary.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' §0.1 -- not one of RCJ's 35 Oklahoma candidates is one of these 68 awards.
#' The counts are RE-DERIVED from the committed record table on every run, so
#' the day Oklahoma's candidate set moves this fails instead of quietly ceasing
#' to cover it (Texas's, Nebraska's and Indiana's rule).
ok_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>%
    dplyr::filter(.data$state == OK_STATE, .data$award_tier == "SUBAWARD",
                  is.na(.data$superseded_by) | .data$superseded_by == "")
}

ok_assert_rcj_disposition <- function(recs) {
  cand <- ok_rcj_candidates()
  if (nrow(cand) != OK_STATED$rcj_candidates) {
    stop("[OK] the record table now holds ", nrow(cand), " Oklahoma Tier 3 ",
         "candidates, not ", OK_STATED$rcj_candidates,
         ". The disposition table no longer covers them.", call. = FALSE)
  }
  if (dplyr::n_distinct(cand$awardee_name_clean) !=
      OK_STATED$rcj_distinct_awardees) {
    stop("[OK] Oklahoma's distinct RCJ awardee count has changed.",
         call. = FALSE)
  }

  # Every candidate's source document is one of the four TIER 2 planning
  # documents. If a candidate ever arrives from the Funding Recipients page,
  # the disposition below is wrong and must be rewritten.
  tier2 <- "(?i)(budget[_ ]narrative|initiative funding summary|legislative quarterly report|touchpoint|pulsara)"
  stray <- cand[!stringr::str_detect(cand$source_doc_title, tier2), ]
  if (nrow(stray)) {
    stop("[OK] ", nrow(stray), " RCJ candidate(s) no longer come from ",
         "Oklahoma's Tier 2 planning documents -- e.g. '",
         stray$source_doc_title[1], "'. Re-read them.", call. = FALSE)
  }

  # And NOT ONE of the 68 awardees is in the candidate set. This is the §0.1
  # finding stated as an assertion rather than a sentence.
  micro <- recs %>% dplyr::filter(.data$award_pool == "MICROGRANTS")
  overlap <- intersect(rhtp_ok_norm(micro$awardee),
                       rhtp_ok_norm(cand$awardee_name_clean))
  if (length(overlap)) {
    stop("[OK] RCJ now holds ", length(overlap), " of Oklahoma's actual ",
         "award recipients (e.g. '", overlap[1], "'). That is a CHANGE in ",
         "the aggregator's coverage and the §0.1 finding must be rewritten.",
         call. = FALSE)
  }
  invisible(TRUE)
}

rhtp_ok_norm <- function(x) {
  x %>% stringr::str_to_lower() %>%
    stringr::str_replace_all("[^a-z0-9]+", " ") %>% stringr::str_squish()
}

#' The §7A comparison, asserted rather than only reported. The two fund uses
#' Oklahoma has published recipients for are BOTH coded
#' `has_hospital_recipient = No` in the committed initiative table, and the
#' microgrant roster names 20 hospital award actions.
ok_initiative_table <- function() {
  p <- here::here("OK_initiative_table.xlsx")
  if (!file.exists(p)) {
    stop("[OK] OK_initiative_table.xlsx is not in the repository; the §7A ",
         "comparison cannot be made.", call. = FALSE)
  }
  openxlsx::read.xlsx(p, sheet = 1)
}

ok_assert_initiative_parity <- function(recs) {
  init <- ok_initiative_table()
  if (abs(sum(init$amount_bp1) - OK_STATED$initiative_allocated) > 0.5) {
    stop("[OK] the initiative table now allocates $",
         format(sum(init$amount_bp1), big.mark = ","), ", not $",
         format(OK_STATED$initiative_allocated, big.mark = ","),
         ". The §7A comparison's denominator has moved.", call. = FALSE)
  }
  hosp <- sum(init$amount_bp1[init$has_hospital_recipient == "Yes"])
  if (abs(hosp - OK_STATED$initiative_hospital) > 0.5) {
    stop("[OK] the initiative table's hospital-directed total has changed.",
         call. = FALSE)
  }

  # The two published fund uses, by their own names in the initiative table.
  for (fu in unique(recs$initiative_fund_use)) {
    row <- init[init$fund_use == fu, ]
    if (nrow(row) != 1L) {
      stop("[OK] '", fu, "' is not a single fund use in the initiative table.",
           call. = FALSE)
    }
    if (row$has_hospital_recipient != "No") {
      stop("[OK] the initiative table now codes '", fu,
           "' as has_hospital_recipient = ", row$has_hospital_recipient,
           ". The session-25 finding -- that the ONLY two fund uses Oklahoma ",
           "has published recipients for are both coded No at initiative ",
           "level, and that one of them names 20 hospital award actions -- ",
           "rests on that value being No.", call. = FALSE)
    }
  }

  # And none of the six hospital-directed fund uses has published a recipient.
  # That is why the 48.7% is untestable today and must not be reported as
  # confirmed by anything in this file.
  hd <- init$fund_use[init$has_hospital_recipient == "Yes"]
  if (any(hd %in% unique(recs$initiative_fund_use))) {
    stop("[OK] a hospital-directed fund use has published a recipient roster. ",
         "The 48.7% is now partly testable -- rewrite the comparison.",
         call. = FALSE)
  }

  # Oklahoma revised the microgrant line upward between its two Tier 2
  # documents, and both figures must still be on the documents that carry them.
  if (!stringr::str_detect(ok_pdf_text("ifs"), "Funding Allocated: \\$2,800,000")) {
    stop("[OK] the Initiative Funding Summary no longer allocates $2,800,000 ",
         "to the microgrants. The §7A table's source has moved.", call. = FALSE)
  }
  if (!stringr::str_detect(ok_pdf_text("q2"), "\\$7,750,000")) {
    stop("[OK] the Q2 report no longer carries the revised $7,750,000 ",
         "microgrant allocation.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §8's standing fallback, and the review-queue row it owes a reviewer.
ok_form_not_stated <- function(recs) {
  recs %>%
    dplyr::filter(.data$award_pool == "MICROGRANTS",
                  .data$recipient_type == "NONPROFIT_CBO",
                  .data$determination_confidence == "LOW",
                  .data$flag_reason == "RECIPIENT_TYPE_INFERRED")
}

ok_assert_form_not_stated_queued <- function(recs) {
  soft <- ok_form_not_stated(recs)
  if (nrow(soft) == 0L) {
    stop("[OK] no Oklahoma row carries §8's standing fallback, which cannot ",
         "be right for a publisher with no organisation-type column.",
         call. = FALSE)
  }
  # Every fallback row must be `No`, which is what makes this uncertainty
  # one-directional and the hospital figure a genuine FLOOR.
  if (!all(soft$distributed_to_hospital == "No")) {
    stop("[OK] a form-not-stated row is not distributed_to_hospital = No; the ",
         "uncertainty is no longer one-directional and the report is wrong.",
         call. = FALSE)
  }
  # THE UNCERTAINTY IS LARGER THAN THE FIGURE, as in Kansas, Maryland and
  # Nebraska. If that ever stops being true the sentence this repository
  # publishes about Oklahoma has to change.
  part <- rhtp_hospital_dollar_partition(recs)
  named <- ok_bucket(part, "NAMED_HOSPITAL")
  if (sum(soft$amount) <= named) {
    stop("[OK] the unstated-form dollars no longer exceed the named-hospital ",
         "floor. Re-word the finding before publishing it.", call. = FALSE)
  }

  q <- readr::read_csv(here::here(OK_REVIEW_QUEUE), show_col_types = FALSE,
                       progress = FALSE)
  row <- q[q$question_id == OK_FORM_NOT_STATED_QUESTION, ]
  if (nrow(row) != 1L || !identical(row$queue_status[[1]], "OPEN")) {
    stop("[OK] ", OK_FORM_NOT_STATED_QUESTION, " is not an OPEN row in ",
         OK_REVIEW_QUEUE, ". ", nrow(soft), " rows and $",
         format(sum(soft$amount), big.mark = ",", nsmall = 2),
         " of unstated recipient form are not a note; they are a reviewer's ",
         "question, and a disclosure nobody can find is not a disclosure ",
         "(§0.4).", call. = FALSE)
  }
  # The queue must state the SAME dollars the file holds. Sessions 20-24 all
  # queued a figure; this is the check that stops one drifting from its data.
  if (!grepl(format(sum(soft$amount), big.mark = ",", nsmall = 2),
             row$dollar_effect[[1]], fixed = TRUE)) {
    stop("[OK] the queued dollar effect does not state ",
         format(sum(soft$amount), big.mark = ",", nsmall = 2),
         "; the queue and the data disagree.", call. = FALSE)
  }
  if (!grepl(paste0(nrow(soft), " rows"), row$why_it_is_open[[1]],
             fixed = TRUE)) {
    stop("[OK] the queued row count does not state ", nrow(soft), " rows.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The Oklahoma Hospital Association IS in Oklahoma's RHTP -- and it is NOT on
#' this roster, and its money is NOT in this file. §10.2's association branch
#' therefore never fires on an Oklahoma award row, and this assertion fails the
#' day OSDH publishes an OHA award list. The CHW Expansion sentence CLAUDE.md
#' quotes as §10.2's worked positive ("implementation will be conducted by
#' hospitals reimbursed for CHW hiring, training, and monitoring", $4,300,000)
#' lives in the Tier 2 initiative table, not here.
ok_assert_oha_absent <- function(recs) {
  pat <- "(?i)oklahoma hospital association|foundation for a healthy oklahoma"
  if (any(stringr::str_detect(recs$awardee, pat))) {
    stop("[OK] the Oklahoma Hospital Association (or its Foundation) has ",
         "entered the award rows. It is a §10.2 hospital-association case and ",
         "must be coded against the source, not swept in with the ",
         "microgrants.", call. = FALSE)
  }
  # It must still be absent from the roster page, so the negative is about
  # Oklahoma and not about this filter.
  if (stringr::str_detect(ok_html_text("recipients"),
                          "(?i)oklahoma hospital association")) {
    stop("[OK] the Oklahoma Hospital Association now appears on the Funding ",
         "Recipients page. Extract it against §10.2.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- validate -----------------------------------------------------------------

ok_validate <- function() {
  ok_assert_rhtp_funded()
  ok_assert_after_noa()
  ok_assert_award_index()
  ok_assert_pending_not_awarded()
  ok_assert_lung_screening_unnamed()

  awards <- ok_microgrant_awards()
  ok_assert_no_awardee_counties(awards)
  ok_assert_stated_counts(awards)
  ok_assert_roots_not_named()

  recs <- ok_records()
  ok_assert_amount_column(recs)
  ok_assert_vocabulary(recs)
  ok_assert_rcj_disposition(recs)
  ok_assert_initiative_parity(recs)
  ok_assert_oha_absent(recs)
  if (file.exists(here::here(OK_REVIEW_QUEUE))) {
    ok_assert_form_not_stated_queued(recs)
  }

  message("[OK] all assertions pass.")
  invisible(recs)
}


# -- build / report -----------------------------------------------------------

ok_bucket <- function(part, bucket) {
  v <- part$dollars[part$bucket == bucket]
  if (!length(v)) 0 else sum(v)
}

ok_build <- function() {
  recs <- ok_validate()
  readr::write_csv(recs, here::here(OK_CSV), na = "")
  message("[OK] wrote ", OK_CSV, " (", nrow(recs), " rows)")

  ok_write_disposition()

  part <- rhtp_hospital_dollar_partition(recs)
  micro <- recs %>% dplyr::filter(.data$award_pool == "MICROGRANTS")
  soft <- ok_form_not_stated(recs)

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "READ ME FIRST")
  openxlsx::writeData(wb, "READ ME FIRST", tibble::tibble(note = c(
    "OKLAHOMA RHTP YEAR 1 -- WHAT OSDH HAS PUBLISHED RECIPIENTS FOR.",
    "",
    "THIS IS 1.6% OF OKLAHOMA'S ALLOTMENT AND IT IS ALL THERE IS. Oklahoma",
    "holds $223,476,949 and has published a recipient-level roster for TWO of",
    "its ten Budget Period 1 funding opportunities. Read `award_pool` before",
    "using any figure.",
    paste0("  MICROGRANTS  68 awards, 54 distinct recipients   $",
           format(OK_STATED$microgrant_total, big.mark = ",", nsmall = 2)),
    paste0("  ROOTS        60 awards, NOBODY NAMED             $",
           format(OK_STATED$roots_total, big.mark = ",", scientific = FALSE),
           "  (in round_amount)"),
    "",
    "SUMMING `amount` GIVES THE MICROGRANT TOTAL AND NOTHING ELSE. OSDE's",
    "ROOTS row carries an EMPTY `amount` because OSDE published a COUNT and a",
    "UNIT PRICE and no roster -- 'sixty (60) PK-12 rural school sites for a",
    "$10,000 grant'. A count is not a list (§0.3), so its $600,000 lives in",
    "`round_amount` where no sum can mistake it for a per-recipient figure.",
    "",
    "THE HOSPITAL FIGURE IS A FLOOR AND THE UNCERTAINTY IS LARGER THAN IT.",
    paste0("  20 award actions to 18 named hospitals            $",
           format(ok_bucket(part, "NAMED_HOSPITAL"), big.mark = ",", nsmall = 2)),
    paste0("  ", nrow(soft), " rows whose form OSDH NEVER STATES              $",
           format(sum(soft$amount), big.mark = ",", nsmall = 2)),
    "OSDH publishes no organisation-type column, so every recipient_type is",
    "derived from the recipient's own NAME. The uncertainty runs ONLY UPWARD:",
    "every fallback row is distributed_to_hospital = No, and DRH Health, SSM",
    "Health St. Anthony Shawnee, Marshall County HMA dba AllianceHealth",
    "Madill, Baptist Healthcare, Fairfax Medical Facilities and Avem Health",
    "Partners are all inside it. NOTHING WAS PROMOTED (§0.4). Queued as",
    "OK_RECIPIENT_FORM_NOT_STATED; the CCN match (blocker 5) resolves it.",
    "",
    "THE INITIATIVE TABLE SAID THESE TWO FUND USES REACH NO HOSPITAL.",
    "OK_initiative_table.xlsx (§7A) codes BOTH published fund uses",
    "has_hospital_recipient = No -- microgrants because the narrative names",
    "'local health departments in 59 rural counties and community-based",
    "entities', ROOTS because it names schools. The microgrant roster names",
    "20 hospital award actions. The initiative-level coding was wrong for",
    "this line, and wrong in the CONSERVATIVE direction. See the",
    "'Initiative comparison' sheet.",
    "",
    "AND 48.7% IS NOT TESTED BY ANYTHING IN THIS FILE. The six fund uses the",
    "initiative table codes hospital-directed -- $99,800,000 of the",
    "$204,900,000 allocated -- have published NO recipients at all. This file",
    "covers $3,572,120.71, which is 1.7% of the allocated budget and 0% of",
    "the hospital-directed lines.",
    "",
    "SIX COUNTIES ARE PUBLISHED WITH NO AWARDEE, AND THAT IS THE STATE'S OWN",
    "WORD: Beckham, Canadian, Cherokee, Love, Nowata and Pawnee. They are in",
    "the source in the same shape as the other 68 and are deliberately NOT",
    "rows here.",
    "",
    "RCJ HOLDS NONE OF THIS. All 35 of its Oklahoma Tier 3 candidates are",
    "BUDGET LINES from four Tier 2 planning documents, and their 'awardees'",
    "are the administering agencies (OHCA, OSDH, OSDE, OSU, OUHSC, SWODA).",
    "Taken at face value they would have published $231,614,376 of programme",
    "allocations as subawards -- MORE THAN THE WHOLE ALLOTMENT. See",
    "ok_rcj_candidate_disposition.csv."
  )))

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", recs)
  openxlsx::freezePane(wb, "Awards", firstRow = TRUE)

  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", tibble::tibble(
    item = c("Microgrants -- award actions",
             "Microgrants -- distinct recipients",
             "Microgrants -- total published",
             "Counties listed on the roster",
             "Counties published with NO awardee",
             "ROOTS -- awards (nobody named)",
             "ROOTS -- round total",
             "All published award dollars (microgrants only)",
             "CMS FY2026 allotment (§7.1)",
             "Published share of the allotment (%)",
             "Hospital dollars -- NAMED_HOSPITAL",
             "Hospital dollars -- POOL_NAMED_HOSPITALS",
             "Hospital dollars -- POOL_UNNAMED_HOSPITALS",
             "Recipient form NOT STATED by OSDH -- rows",
             "Recipient form NOT STATED by OSDH -- dollars",
             "RCJ Tier 3 candidates (§0.1, never a figure)",
             "RCJ candidates that are award rows here"),
    value = c(nrow(micro), dplyr::n_distinct(micro$awardee),
              OK_STATED$microgrant_total, OK_STATED$counties_listed,
              OK_STATED$no_awardee_counties, OK_STATED$roots_awards,
              OK_STATED$roots_total, sum(micro$amount),
              round(OK_CMS_FOOTER_AMOUNT),
              round(100 * sum(micro$amount) / OK_CMS_FOOTER_AMOUNT, 2),
              ok_bucket(part, "NAMED_HOSPITAL"),
              ok_bucket(part, "POOL_NAMED_HOSPITALS"),
              ok_bucket(part, "POOL_UNNAMED_HOSPITALS"),
              nrow(soft), sum(soft$amount),
              OK_STATED$rcj_candidates, 0)
  ))

  openxlsx::addWorksheet(wb, "Initiative comparison")
  openxlsx::writeData(wb, "Initiative comparison", ok_initiative_comparison(recs))

  openxlsx::saveWorkbook(wb, here::here(OK_XLSX), overwrite = TRUE)
  message("[OK] wrote ", OK_XLSX)
  invisible(recs)
}

#' The §7A check this session exists to make, as a table rather than a claim.
ok_initiative_comparison <- function(recs = ok_records()) {
  init <- ok_initiative_table()
  micro <- recs %>% dplyr::filter(.data$award_pool == "MICROGRANTS")
  part <- rhtp_hospital_dollar_partition(recs)
  named <- ok_bucket(part, "NAMED_HOSPITAL")
  soft <- ok_form_not_stated(recs)

  tibble::tibble(
    line = c(
      "INITIATIVE LEVEL (OK_initiative_table.xlsx, 28 fund uses, §7A)",
      "  Budget Period 1 allocated",
      "  Hospital-directed (has_hospital_recipient = Yes)",
      "  Hospital-directed share",
      "  Fund uses coded hospital-directed",
      "  Of those, fund uses with a published recipient roster",
      "RECIPIENT LEVEL (this file)",
      "  Award dollars with a NAMED recipient",
      "  Share of the allocated Budget Period 1 budget covered",
      "  Named-hospital dollars (a FLOOR)",
      "  Named-hospital share of what is published",
      "  Rows whose recipient form OSDH never states (all `No`, so upward)",
      "  Named-hospital share if EVERY unstated row were a hospital",
      "THE TWO PUBLISHED FUND USES, AS THE INITIATIVE TABLE CODES THEM",
      "  Community-Led Wellness Hub: Microgrants",
      "  Presidential Fitness Test Preparation (ROOTS)"),
    value = c(
      NA_character_,
      paste0("$", format(sum(init$amount_bp1), big.mark = ",")),
      paste0("$", format(sum(init$amount_bp1[init$has_hospital_recipient == "Yes"]),
                         big.mark = ",")),
      paste0(OK_STATED$initiative_pct_hospital, "%"),
      as.character(sum(init$has_hospital_recipient == "Yes")),
      "0",
      NA_character_,
      paste0("$", format(sum(micro$amount), big.mark = ",", nsmall = 2)),
      paste0(round(100 * sum(micro$amount) / sum(init$amount_bp1), 2), "%"),
      paste0("$", format(named, big.mark = ",", nsmall = 2)),
      paste0(round(100 * named / sum(micro$amount), 1), "%"),
      paste0(nrow(soft), " rows, $",
             format(sum(soft$amount), big.mark = ",", nsmall = 2)),
      paste0(round(100 * (named + sum(soft$amount)) / sum(micro$amount), 1), "%"),
      NA_character_,
      paste0("has_hospital_recipient = ",
             init$has_hospital_recipient[init$fund_use == "Community-Led Wellness Hub: Microgrants"],
             "; allocated $",
             format(init$amount_bp1[init$fund_use == "Community-Led Wellness Hub: Microgrants"],
                    big.mark = ",")),
      paste0("has_hospital_recipient = ",
             init$has_hospital_recipient[init$fund_use == "Presidential Fitness Test Preparation"],
             "; allocated $",
             format(init$amount_bp1[init$fund_use == "Presidential Fitness Test Preparation"],
                    big.mark = ","))),
    note = c(
      NA_character_,
      "The 03.10.26 Initiative Funding Summary, as extracted in session 7.",
      "Six fund uses: Provider Collaborative Network $43.1M, RRR $26.4M, Rural Residency $22.4M, CHW $4.3M, Lung Screening $2.3M, Maternal VBP $1.3M.",
      "The figure CLAUDE.md carries for Oklahoma.",
      NA_character_,
      "NONE of the six has published a recipient. So 48.7% is UNTESTED by anything here.",
      NA_character_,
      "68 microgrant awards. ROOTS names nobody and contributes $0 to this line.",
      "The recipient-level check covers a sixtieth of the allocated budget.",
      "20 award actions, 18 distinct hospitals, typed from the recipient's own name.",
      "Against 48.7% at initiative level -- DIFFERENT UNIVERSES, not a discrepancy.",
      "OSDH publishes no organisation-type column; §8's standing fallback.",
      "The ceiling of the same claim. The truth is between the two and a CCN match settles it.",
      NA_character_,
      "The narrative said 'local health departments in 59 rural counties and community-based entities'. The roster names 20 hospital award actions.",
      "Coded No on schools, and the roster confirms it: OSDE selected PK-12 school sites.")
  )
}

#' Why each of RCJ's 35 Oklahoma candidates is not an RHTP subaward row.
#' Texas's precedent: the disposition is a committed table, not a comment.
ok_write_disposition <- function() {
  cand <- ok_rcj_candidates()
  grp <- function(pat) {
    s <- cand[stringr::str_detect(cand$source_doc_title, pat), ]
    list(n = nrow(s), amt = sum(s$amount_announced, na.rm = TRUE))
  }
  bn  <- grp("(?i)budget_?narrative")
  ifs <- grp("(?i)initiative funding summary")
  q   <- grp("(?i)legislative quarterly report")
  tp  <- grp("(?i)touchpoint")
  pul <- grp("(?i)pulsara")

  if (bn$n + ifs$n + q$n + tp$n + pul$n != nrow(cand)) {
    stop("[OK] the disposition groups cover ", bn$n + ifs$n + q$n + tp$n + pul$n,
         " of ", nrow(cand), " candidates. A candidate has arrived from a ",
         "document this table does not describe.", call. = FALSE)
  }

  disp <- tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount, ~disposition, ~basis, ~state_document,

    "Budget Narrative initiative allocations (OHCA fund uses)",
    bn$n, bn$amt, "RHTP_BUT_NOT_A_SUBAWARD",
    paste("Eight lines lifted from Oklahoma's RHTP Budget Narrative, an",
          "application document. Their 'awardees' are OHCA plus the fund use",
          "-- 'Oklahoma Health Care Authority (OHCA) - EHR expansion' -- which",
          "is a PROGRAMME and an administering agency, not a recipient (§6.1's",
          "PROGRAM_NAME_AS_AWARDEE). Tier 2 by construction (§0.2)."),
    "2026-03-10_ok_rhtp_initiative_funding_summary.pdf",

    "Budget Period 1 Initiative Funding Summary lines",
    ifs$n, ifs$amt, "RHTP_BUT_NOT_A_SUBAWARD",
    paste("The CMS-approved BP1 allocation packet -- the §7A source for",
          "OK_initiative_table.xlsx. Every line is a 'Funding Allocated:'",
          "figure against a named lead agency (OSU, OU/OSU, the Oklahoma",
          "Hospital Association, SWODA, OHCA). An allocation to an",
          "administering agency is Tier 2 and may never be unioned with Tier 3."),
    "2026-03-10_ok_rhtp_initiative_funding_summary.pdf",

    "Legislative Quarterly Report Q1 and Q2 programme rows",
    q$n, q$amt, "RHTP_BUT_NOT_A_SUBAWARD",
    paste("The reports' own glossary defines the column RCJ mined:",
          "'Y1 Budget Allocation: The amount of funds dedicated to the",
          "program.' The 'Funded Entity' beside it is the implementing agency",
          "-- OSDH, OHCA, OSDE, OSU, OUHSC, SWODA, the Foundation for a",
          "Healthy Oklahoma. These are the same 29 CMS-approved programmes as",
          "the Initiative Funding Summary, restated per quarter with an",
          "obligation and a spend column; they are not an award roster and",
          "name no subrecipient."),
    "2026-07-10_ok_rhtp_legislative_quarterly_report_q2.pdf",

    "August 2026 Touchpoint Webinar line",
    tp$n, tp$amt, "RHTP_BUT_NOT_A_SUBAWARD",
    paste("A slide figure against SWODA, the Transportation Expansion",
          "programme's administering authority. A webinar deck is a",
          "programme-update document, not an award action."),
    "2026-07-10_ok_rhtp_legislative_quarterly_report_q2.pdf",

    "EMS Centralization -- Pulsara",
    pul$n, pul$amt, "RHTP_BUT_A_PLATFORM_NOT_A_SUBAWARD",
    paste("Carried by RCJ at an amount of $1 -- a placeholder, not a figure.",
          "OSDH's own page describes the EMS Centralization Program as a",
          "single statewide platform procurement; the Q2 report names the",
          "funded entity as 'OSDH: Carahsoft (Pulsara)' against a $4,500,000",
          "programme allocation, with hospitals and EMS partners ENROLLING in",
          "the platform. That is §10.2's IN_KIND_BENEFIT shape at Tier 2, and",
          "OSDH has published no recipient-level award against it."),
    "2026-08-31_ok_rhtp_home.html"
  )
  readr::write_csv(disp, here::here(OK_DISPOSITION_CSV), na = "")
  message("[OK] wrote ", OK_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  invisible(disp)
}

ok_report <- function() {
  recs <- ok_records()
  micro <- recs %>% dplyr::filter(.data$award_pool == "MICROGRANTS")
  part <- rhtp_hospital_dollar_partition(recs)
  soft <- ok_form_not_stated(recs)
  named <- ok_bucket(part, "NAMED_HOSPITAL")

  cat("\nOKLAHOMA -- RHTP Year 1, what OSDH has published recipients for\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(
    recs %>% dplyr::group_by(.data$award_pool) %>%
      dplyr::summarise(rows = dplyr::n(),
                       named_recipients = sum(.data$recipient_confirmed == "Yes"),
                       dollars_in_amount = sum(.data$amount, na.rm = TRUE),
                       .groups = "drop")), row.names = FALSE)
  cat("\nTotal in `amount`: $", format(sum(micro$amount), big.mark = ",", nsmall = 2),
      " -- ", round(100 * sum(micro$amount) / OK_CMS_FOOTER_AMOUNT, 2),
      "% of the CMS allotment.\n", sep = "")
  cat("ROOTS adds $", format(OK_STATED$roots_total, big.mark = ",", scientific = FALSE),
      " in `round_amount` and names NOBODY (§0.3).\n", sep = "")

  cat("\nHospital dollars, PARTITIONED and never added (§10.2):\n")
  cat("  NAMED_HOSPITAL        : $",
      format(named, big.mark = ",", nsmall = 2),
      "  -- 20 award actions, 18 distinct hospitals\n", sep = "")
  cat("  POOL_NAMED_HOSPITALS  : $",
      format(ok_bucket(part, "POOL_NAMED_HOSPITALS"), big.mark = ","), "\n", sep = "")
  cat("  POOL_UNNAMED_HOSPITALS: $",
      format(ok_bucket(part, "POOL_UNNAMED_HOSPITALS"), big.mark = ","), "\n", sep = "")

  cat("\nRECIPIENT FORM NOT STATED BY OSDH: ", nrow(soft), " rows, $",
      format(sum(soft$amount), big.mark = ",", nsmall = 2), "\n", sep = "")
  cat("  Kansas's, Maryland's and Nebraska's shape a fourth time, and LARGER\n")
  cat("  than the floor beside it. Here it runs ONLY UPWARD -- every one of\n")
  cat("  those rows is distributed_to_hospital = No -- so the truth is\n")
  cat("  between $", format(named, big.mark = ",", nsmall = 2), " and $",
      format(named + sum(soft$amount), big.mark = ",", nsmall = 2), ".\n", sep = "")
  cat("  Nothing promoted (§0.4). Queued as OK_RECIPIENT_FORM_NOT_STATED.\n")

  cat("\nTHE §7A COMPARISON -- recipient level against initiative level\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(ok_initiative_comparison(recs)[, c("line", "value")]),
        row.names = FALSE, right = FALSE)
  cat("\nREAD THAT TABLE AS TWO DIFFERENT CLAIMS, NOT A DISCREPANCY.\n")
  cat("  48.7% is the hospital-directed share of $204.9M of INITIATIVE\n")
  cat("  allocations. ", round(100 * named / sum(micro$amount), 1),
      "% is the named-hospital share of the $3.57M\n", sep = "")
  cat("  Oklahoma has actually awarded to named recipients. They do not\n")
  cat("  overlap at all: NONE of the six hospital-directed fund uses has\n")
  cat("  published a recipient, so nothing here tests the 48.7% -- and the\n")
  cat("  two fund uses that HAVE published are both coded `No` at initiative\n")
  cat("  level, one of which names 20 hospital award actions.\n")
  invisible(recs)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(as.data.frame(ok_fetch(force = "--force" %in% args)))
  if ("--validate" %in% args) ok_validate()
  if ("--build" %in% args) ok_build()
  if ("--report" %in% args) ok_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03t_ok_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report]\n")
  }
}

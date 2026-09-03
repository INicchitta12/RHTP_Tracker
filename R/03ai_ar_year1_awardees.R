#!/usr/bin/env Rscript
# 03ai_ar_year1_awardees.R ----------------------------------------------------
#
# ARKANSAS -- RHTP Year 1. Arkansas runs its programme from `arkansasrhtp.com`,
# a DEDICATED RHTP DOMAIN -- the second in this project after Kentucky's
# `ruralhealthplan.ky.gov`, and THE FIRST THAT HAS AWARDED. It was invisible to
# both discovery layers: ZERO RCJ Tier 3 candidates and no CMS state release,
# `trigger_source = NEITHER`, which is FLORIDA'S SHAPE (session 36's existence
# proof) a third time after North Carolina.
#
# WHAT ARKANSAS PUBLISHES.
#
#   THE AWARD LIST     one PDF, linked from the home page under Arkansas's own
#                      words "Download the List of Organization and Award
#                      amounts": 31 ORGANISATIONS x 2 INITIATIVES, priced, with
#                      the state's own `Total:` row. 37 non-zero cells,
#                      $149,177,618.45, 71.5% of the $208,779,396 allotment.
#   THE PROJECT LIST   the Governor's 2026-08-27 release enumerates ALL 50
#                      PROJECT AWARDS individually, each priced, each with a
#                      description and a county list.
#
# So Arkansas is the FIRST STATE IN THIS REPOSITORY WHOSE AWARDS ARE PUBLISHED
# AT TWO GRAINS BY TWO PUBLISHERS, and the two reconcile TO THE CENT on all
# three of the award list's columns. Nothing was arranged: DF&A published an
# organisation table and the Governor published a project list, and
# `ar_assert_projects_reconcile()` closes them against each other every run.
#
# THREE COUNTS, NONE OF THEM THE OTHERS, AND THE REPORT PRINTS ALL THREE.
#   31  organisations       -- the award list's rows
#   37  award actions       -- organisation x initiative, the grain Arkansas
#                              PRICES, and this file's row count
#   50  project awards      -- the Governor's own count, and the grain Arkansas
#                              DESCRIBES; in `ar_year1_projects.csv`
# A reader who takes any one of them for another mis-states the state.
#
# WHY THIS FILE NEEDS SESSION 32'S RUN MODEL, AND THE ASSERTION THAT KEEPS IT.
# The award list paints its three amount columns at ONE y, so
# `rhtp_pdf_lines()` returns `"$2,571,095.00$0.00$2,571,095.00"` -- three
# figures welded into one unparseable string, Iowa's "Adair County Memorial
# Hospital Greenfield" one column over. `rhtp_pdf_runs()` separates them at
# Arkansas's own producer's boundaries. `ar_assert_line_model_merges()` asserts
# that the line model STILL merges, so that a later session cannot "simplify"
# this back to `rhtp_pdf_lines()` and get a silently wrong answer (session 35's
# lesson: a header that says the opposite of the code it heads).
#
# TWO OF FOUR INITIATIVES ARE STILL TO COME, SO THIS FIGURE IS A PARTIAL YEAR
# BY CONSTRUCTION. Arkansas runs THRIVE, PACT, RISE AR and HEART. THRIVE and
# PACT have awarded; the Governor's own release says "Two additional
# initiatives of grant funding will be announced at a later date for the
# Recruitment Innovation Skills and Education for Arkansas (RISE AR) and
# Healthy Eating, Active Recreation, and Transformation (HEART) initiatives",
# against "the $209 million the state expects to award by this fall". Both
# remaining NOFOs have CLOSED to applications -- RISE AR 2026-07-24, HEART
# 2026-08-07 -- NEITHER names an award date, and CMS requires all Year 1 funds
# OBLIGATED BY 2026-10-30, which both NOFOs state themselves. That is the
# clock, and `--probe` is what watches it.
#
# THE INITIATIVE PAGES CANNOT TELL AWARDED FROM UNAWARDED, WHICH IS WHY THE
# PROBE DOES NOT READ THEM FOR THAT. All four carry the IDENTICAL sentence
# "What is next? Upcoming announcements will provide detailed information
# regarding eligibility criteria and award frameworks via Notices of Funding
# Opportunities (NOFOs)" -- including THRIVE and PACT, which have awarded
# $149M between them. `ar_assert_initiative_pages_cannot_tell()` asserts that
# equality rather than glossing it: the signal is the HOME PAGE's award-list
# link, which exists for THRIVE/PACT and for neither of the other two.
#
# §6.2, AND THE FOOTER IS DEMOTED ON BOTH OF THE GROUNDS THIS PROJECT KNOWS.
# The CMS financial-assistance footer is on every page of the estate and on the
# Governor's release, and it is (a) session 27's WEAK form -- its subject is
# "This project" -- and (b) carrying $208,779,396.02, WHICH IS THE ALLOTMENT,
# so it is Tier 1 wearing a project's grammar (§0.2, session 37). It is
# declared `STATE_ALLOTMENT` and checked by `rhtp_assert_footer_tiers()`. It
# also sits unchanged on the RISE and HEART pages, which describe initiatives
# that have awarded NOTHING -- session 26's Nevada lesson, measured here: THE
# FOOTER COVERS THE PUBLICATION, NOT THE PROGRAMME. And THE AWARD LIST ITSELF
# CARRIES NO FOOTER AT ALL (Maine's shape), so the footer could not have
# carried this state's provenance even if it were the strong form.
#
# The provenance is carried instead by THREE programme-scoped sources: each
# NOFO's own header ("Funding Opportunity Number: THRIVE YR 1-2026", "Issuing
# Agency: Arkansas Department of Finance and Administration (DF&A)", "Program
# Authority: CMS Rural Health Transformation (RHT) Program") -- which ties the
# exact two initiatives that ARE the award list's column headers to RHTP; the
# Governor's release, which calls them "the first round of Rural Health
# Transformation Program (RHTP) grants" and quotes the CMS Administrator; and
# Arkansas's Year 1 Revised Budget Narrative, which places all four
# initiatives inside the plan (Kansas's second source, session 28).
#
# THE AMOUNTS ARE NOT FINAL AND ARKANSAS SAYS SO: "the details of each grant
# will not be finalized until DFA signs an official agreement with each
# grantee". So all 37 rows are `NOTICE_OF_INTENT_TO_AWARD` +
# `amount_confirmed = No` -- Maryland's and Oregon's posture.
#
# THE UNSTATED-FORM QUESTION IS THE NINTH INSTANCE AND BY FAR THE LARGEST IN
# DOLLARS: 16 of the 31 organisations, $100,723,693.49, 67.5% of the round,
# against a named-hospital floor of 9 rows / $21,792,687.96. It runs strongly
# UPWARD -- Baxter Health $19.7M, Mercy Health Fort Smith $19.1M, Baptist
# Health $16.9M, St. Bernards $14.6M -- and Arkansas Rural Health Partnership
# ($18.8M) is a hospital CONSORTIUM, which is §10.2's association row and a
# separate question again. NOTHING WAS PROMOTED (§0.4); both are queued.
#
# CLI:
#   --fetch [--force]  archive the 14 sources + SHA-256 manifest
#   --validate         every assertion, offline
#   --build            write the four CSVs
#   --probe            LIVE: has RISE or HEART awarded?
#   --report           the roster, the three counts, and what is still to come
#
# Sessions: 40.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))


# -- constants ----------------------------------------------------------------

AR_STATE        <- "AR"
AR_EVIDENCE_DIR <- here::here("data", "evidence", "AR")
AR_OUT_CSV      <- here::here("data", "reference", "ar_year1_awardees.csv")
AR_PROJECTS_CSV <- here::here("data", "reference", "ar_year1_projects.csv")
AR_STATUS_CSV   <- here::here("data", "reference", "ar_year1_status.csv")
AR_DISPOSITION_CSV <- here::here("data", "reference",
                                 "ar_rcj_candidate_disposition.csv")

# The honest agent, and it is the ONLY one used here: `arkansasrhtp.com`
# answers 200 to it, so neither session 10's medicaid.gov question nor session
# 27's michigan.gov inversion arises. `robots.txt` is 200, allows everything
# outside `/wp-admin/`, and sets `Crawl-delay: 10` -- which is why the throttle
# below is TEN seconds and not the two this project usually uses. The crawler
# policy is on offer and it is being honoured (§3).
AR_USER_AGENT <- paste(
  "AHA-RHTP-Tracker/0.1 (+https://www.aha.org;",
  "contact: AHA Data and Policy; R httr2)"
)
AR_HOST_THROTTLE_S <- 10

AR_CREDENTIAL_SHAPES <- c(
  "Mapbox token"    = "\\b[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  "Google API key"  = "\\bAIza[0-9A-Za-z_-]{30,}",
  "AWS access key"  = "\\bAKIA[0-9A-Z]{16}\\b"
)


# -- what ARKANSAS states, so a change in the source fails rather than passes --

# The §7.1 anchor has Arkansas at $208,779,396; every CMS footer across the
# estate prints $208,779,396.02, the same award to the cent.
AR_ALLOTMENT        <- 208779396
AR_FOOTER_AMOUNT    <- 208779396.02
AR_NOA_DATE         <- as.Date("2025-12-29")
AR_ANNOUNCE_DATE    <- as.Date("2026-08-27")
AR_BUDGET_PERIOD    <- "BP1 (12/29/2025 - 10/30/2026)"

# The award list's own `Total:` row -- the reconciliation target, and NEVER a
# recipient. It is painted in the same shape as an award row, so a parse that
# does not exclude it reports 32 organisations and double the money.
AR_TOTAL_THRIVE <- 55713829.20
AR_TOTAL_PACT   <- 93463789.25
AR_TOTAL_YR1    <- 149177618.45

AR_ORG_COUNT     <- 31L
AR_ACTION_COUNT  <- 37L
AR_PROJECT_COUNT <- 50L

# The award list's column headers, IN THE ORDER THE PDF PAINTS THEM. The order
# is load-bearing: the two component columns are $55.7M and $93.6M, so reading
# them the other way round swaps two figures that both look plausible. It is
# established THREE independent ways -- the header runs' own x order, the
# painted order of every body row, and the Governor's release naming each
# initiative's total separately -- and all three are asserted.
AR_COLUMNS <- c("Organization", "THRIVE", "PACT", "YR1 PACT/THRIVE Total")

# NOTE THE TRAP IN ARKANSAS'S OWN HEADER: the total column is labelled
# "YR1 PACT/THRIVE Total", naming PACT FIRST, while the columns beside it run
# THRIVE then PACT. A reader taking the total column's label as the column
# order inverts the two.
AR_TOTAL_HEADER_NAMES_PACT_FIRST <- "YR1 PACT/THRIVE Total"

AR_INITIATIVES <- tibble::tribble(
  ~pool,     ~round_name,                                        ~awarded, ~nofo_key,
  ~nofo_open,     ~nofo_close,     ~awarded_total,
  "THRIVE",
  "Telehealth, Health-monitoring, and Response Innovation for Vital Expansion (THRIVE)",
  TRUE,  "nofo_thrive", "2026-05-11", "2026-06-12", AR_TOTAL_THRIVE,
  "PACT",
  "Promoting Access, Coordination, and Transformation (PACT)",
  TRUE,  "nofo_pact",   "2026-06-08", "2026-07-10", AR_TOTAL_PACT,
  "RISE AR",
  "Recruitment, Innovation, Skills, and Education for Arkansas Healthcare (RISE)",
  FALSE, "nofo_rise",   "2026-06-22", "2026-07-24", NA_real_,
  "HEART",
  "Healthy Eating, Active Recreation, & Transformation (HEART)",
  FALSE, "nofo_heart",  "2026-06-29", "2026-08-07", NA_real_
)

# Arkansas's own words, on its own home page, for the document this file parses.
AR_ROSTER_LINK_TEXT <- "Download the List of Organization and Award amounts"

# The sentence that makes every figure here provisional.
AR_NOT_FINAL_QUOTE <- paste(
  "the details of each grant will not be finalized until DFA signs an",
  "official agreement with each grantee")

# The Governor's own counts and totals. Each is asserted against what this
# file parses, so the two publishers close on each other rather than on prose.
AR_GOV_QUOTES <- c(
  "The 50 project awards",
  "recipients of the first round of Rural Health Transformation Program (RHTP) grants",
  "the $209 million the state expects to award by this fall",
  "Two additional initiatives of grant funding will be announced at a later date"
)
AR_GOV_THRIVE_QUOTE <- "$55.7 million through the Telehealth"
AR_GOV_PACT_QUOTE   <- "$93.6 million through the Promoting Access"
AR_GOV_HEADLINE_QUOTE <- "$149.3 million in awards"

# The sentence every initiative page carries, awarded or not. It is the reason
# the probe does not read these pages for award status.
AR_INITIATIVE_BOILERPLATE <- paste(
  "Upcoming announcements will provide detailed information regarding",
  "eligibility criteria and award frameworks via Notices of Funding",
  "Opportunities (NOFOs)")

# Each NOFO's own header. This is the programme-scoped provenance the footer
# cannot supply, and it names the initiative whose name IS a column of the
# award list.
AR_NOFO_AUTHORITY <- "Program Authority: CMS Rural Health Transformation (RHT) Program"
AR_NOFO_AGENCY    <- "Arkansas Department of Finance and Administration (DF&A)"
AR_OBLIGATION_QUOTE <- "all funds must be obligated by October 30, 2026"
AR_OBLIGATION_DATE  <- as.Date("2026-10-30")

# The CMS footer, WEAK form (session 27) AND carrying the allotment (§0.2).
AR_FOOTER_SUBJECT <- "This project is supported by the Centers for Medicare & Medicaid Services"

# THE ONE THING A REGEX GETS WRONG ON THE GOVERNOR'S RELEASE. Forty-nine of the
# fifty amounts are painted as one node, "\u2013 $3,000,000.00"; ONE is painted
# as "$" and "1,455,689.00" in two separate nodes. A pattern requiring the
# digits immediately after the dollar sign therefore finds 49 of 50 and drops
# Arkansas Rural Health Partnership's $1,455,689.00 in SILENCE -- the sums then
# miss by that much and nothing points at the row. Both the parser's tolerant
# pattern and the naive one are asserted, so the defect stays visible.
AR_AMOUNT_RE       <- "\\$\\s*([0-9,]+\\.[0-9]{2})"
AR_NAIVE_AMOUNT_RE <- "\u2013\\s\\$[0-9,]+\\.[0-9]{2}"
AR_SPLIT_NODE_ORG  <- "Arkansas Rural Health Partnership"
AR_SPLIT_NODE_AMOUNT <- 1455689.00

# SEVEN ORGANISATIONS ARE SPELLED DIFFERENTLY BY THE TWO PUBLISHERS, and this
# table is the ONLY thing that joins them. It is a FIXED, HAND-READ map, not a
# fuzzy matcher (§2 forbids a machine auto-resolving a hospital name), it is
# keyed release-spelling -> award-list-spelling, and every entry is visible
# here. `ar_assert_release_spellings()` requires that after applying it the two
# documents name the SAME 31 organisations -- so an EIGHTH divergence, or a
# changed spelling, fails the build instead of quietly dropping a row from the
# reconciliation.
#
# THE DIVERGENCE IS NOT COSMETIC AND ARKANSAS IS WHERE THAT COSTS MONEY.
# "Arkansas Children's Hospital" (the award list) hits §8's hospital name rule
# -- HOSPITAL_OR_SYSTEM, HIGH, DIRECT, `Yes`, a NAMED-HOSPITAL ROW WORTH
# $301,400 -- while "Arkansas Children's" (the release) hits nothing and falls
# to §8's standing fallback, `No`. North Carolina's two spellings of UNC moved
# a CODING at $0 (session 38); Arkansas's move a DOLLAR.
# `ar_assert_two_spellings_classify_differently()` asserts the divergence
# rather than repairing it, and the AWARD LIST'S spelling is the one this
# file's award rows carry, because it is the primary source (§8).
# AND THERE IS AN EIGHTH DIFFERENCE THAT IS NOT IN THE MAP BECAUSE IT IS
# SYSTEMATIC: THE TWO PUBLISHERS USE DIFFERENT APOSTROPHES. The award list
# prints U+0027 ("Arkansas Children's Hospital", "Children's Advocacy Centers
# of Arkansas") and the Governor's release prints U+2019 throughout. So the
# join fails on every apostrophe-bearing name for a reason no reader would see
# in either document -- session 34's zero-width space and curly apostrophe,
# met a second time and this time load-bearing on a $301,400 row. The map's
# keys carry the release's U+2019 explicitly, as escapes, so the file cannot
# be "tidied" into straight quotes without the assertion failing.
AR_RELEASE_SPELLINGS <- c(
  "ARcare"                                                  = "ARCARE",
  "Arkansas Baptist Children\u2019s Homes and Family Ministries" =
    "Arkansas Baptist Childrens Homes and Family Ministries",
  "Arkansas Children\u2019s"                                = "Arkansas Children's Hospital",
  "Carriage Hill Family Care, PLC"                          = "Carriage Hill Family Care, PLLC",
  "Children\u2019s Advocacy Centers of Arkansas"            = "Children's Advocacy Centers of Arkansas",
  "Deckmax dba North Arkansas Rural Health Consortium"      = "North Arkansas Rural Health Consortium",
  "LilyLink in partnership with the Perinatal Center"       = "LilyLink/The Perinatal Center",
  "New York Institute of Technology"                        = "New York Insitute of Technology",
  "River Valley Medical Wellness"                           = "River Valley Wellness"
)

# The two spellings whose §8 answers differ, named so the assertion cannot
# drift from the finding.
AR_TWO_SPELLINGS <- c(award_list = "Arkansas Children's Hospital",
                      release    = "Arkansas Children\u2019s")

# THE FIVE NAMES A READER WILL WANT TO PROMOTE, AND NONE IS PROMOTED (§0.4).
# Every one reads as a hospital or a hospital body to anyone who knows
# Arkansas; the award list states NO organisational form for any of them, and
# it publishes no project description either, so nothing in the primary source
# can move them off what §8's name rule says. All five carry §8's standing
# fallback and all five are in the review queue.
AR_NOT_PROMOTED <- c("Baxter Health", "Mercy Health Fort Smith Communities",
                     "Baptist Health", "St. Bernards Development Foundation",
                     "Arkansas Rural Health Partnership")

# Arkansas Rural Health Partnership is a SEPARATE question from the other
# fifteen and it is §10.2's, not §8's: a hospital consortium administering
# money to member hospitals is `PASS_THROUGH_DESIGNATED` + `Yes`, while one
# that keeps it and delivers goods or services is `IN_KIND_BENEFIT`. The award
# list says nothing at all, and the test is what the document says the money
# DOES, never what the organisation IS.
AR_CONSORTIUM <- "Arkansas Rural Health Partnership"

# The eligible class, from the THRIVE NOFO. HOSPITALS AMONG OTHERS, which is
# New Hampshire's FHC class and NOT Illinois's ICAHN class -- so §0.3 governs
# any Arkansas pass-through, and it is recorded before RISE and HEART land.
AR_ELIGIBLE_CLASS_QUOTE <- "rural hospitals, clinics, EMS providers, behavioral health providers"


# -- sources ------------------------------------------------------------------

AR_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,
  "roster",
  "2026-08-27_ar_dfa_year1_thrive_pact_award_list.pdf",
  "https://arkansasrhtp.com/wp-content/uploads/2026/08/ada_RHTP.YR1_.THRIVE.PACT_.pdf",
  "map",
  "2026-08-27_ar_dfa_year1_thrive_pact_by_county_map.pdf",
  paste0("https://arkansasrhtp.com/wp-content/uploads/2026/08/",
         "ada_Arkansas-MAP.THRIVE.PACT_.By-County.pdf"),
  "home",
  "2026-09-03_ar_rhtp_home.html",
  "https://arkansasrhtp.com/",
  "governor",
  "2026-08-27_governor_sanders_nearly_150_million_awarded.html",
  paste0("https://governor.arkansas.gov/news_post/",
         "sanders-announces-nearly-150-million-awarded-in-rural-health-",
         "transformation-funds/"),
  "thrive",
  "2026-09-03_ar_rhtp_thrive.html",
  "https://arkansasrhtp.com/thrive/",
  "pact",
  "2026-09-03_ar_rhtp_pact.html",
  "https://arkansasrhtp.com/pact/",
  "rise",
  "2026-09-03_ar_rhtp_rise.html",
  "https://arkansasrhtp.com/rise/",
  "heart",
  "2026-09-03_ar_rhtp_heart.html",
  "https://arkansasrhtp.com/heart/",
  "resources",
  "2026-09-03_ar_rhtp_resources.html",
  "https://arkansasrhtp.com/resources/",
  "nofo_thrive",
  "2026-05-11_ar_nofo_thrive.pdf",
  "https://arkansasrhtp.com/wp-content/uploads/2026/05/NOFO_THRIVE_Clean.pdf",
  "nofo_pact",
  "2026-06-08_ar_nofo_pact.pdf",
  paste0("https://arkansasrhtp.com/wp-content/uploads/2026/06/",
         "ADA_FINAL_NOFO_PACT-06.01.26.pdf"),
  "nofo_rise",
  "2026-06-22_ar_nofo_rise_ar.pdf",
  paste0("https://arkansasrhtp.com/wp-content/uploads/2026/06/",
         "Arkansas.RISE_AR_NOFO_ADA_FINAL_Preflight.pdf"),
  "nofo_heart",
  "2026-06-29_ar_nofo_heart.pdf",
  paste0("https://arkansasrhtp.com/wp-content/uploads/2026/06/",
         "Arkansas_HEART_NOFO_ADA_FINAL_Preflight.pdf"),
  "budget_narrative",
  "2026-05_ar_year1_revised_budget_narrative.pdf",
  paste0("https://arkansasrhtp.com/wp-content/uploads/2026/05/",
         "Year-1_AR-Revised-Budget-Narrative_ADAFINAL-2.pdf")
)

# The pages the probe re-reads live. The HOME page is the one that matters: its
# award-list link is the only thing on this estate that distinguishes an
# awarded initiative from an unawarded one.
AR_WATCHED <- c("home", "resources", "rise", "heart")


# -- fetch --------------------------------------------------------------------

ar_source <- function(key, field) {
  row <- AR_SOURCES[AR_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[AR] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ar_path <- function(key) file.path(AR_EVIDENCE_DIR, ar_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
ar_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(AR_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, AR_CREDENTIAL_SHAPES[[nm]])) {
      stop("[AR] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ar_get <- function(url, label) {
  message("[AR] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(AR_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[AR] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  ar_assert_credential_free(served, label)
  served
}

ar_fetch <- function(force = FALSE) {
  dir.create(AR_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  fetched <- 0L
  entries <- purrr::map_dfr(seq_len(nrow(AR_SOURCES)), function(i) {
    src <- AR_SOURCES[i, ]
    dest <- file.path(AR_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[AR] cached, not re-fetched: ", src$file)
    } else {
      if (fetched > 0L) Sys.sleep(AR_HOST_THROTTLE_S)
      writeBin(ar_get(src$url, src$file), dest)
      fetched <<- fetched + 1L
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  ar_write_manifest(entries)
  entries
}

ar_write_manifest <- function(entries) {
  path <- file.path(AR_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Arkansas -- RHTP Year 1. arkansasrhtp.com is a DEDICATED RHTP DOMAIN, the",
    "second in this project after Kentucky's and the FIRST THAT HAS AWARDED.",
    "Archived by R/03ai_ar_year1_awardees.R --fetch",
    paste0("User-agent: ", AR_USER_AGENT),
    paste0("Throttle: ", AR_HOST_THROTTLE_S, "s -- robots.txt is 200 and sets ",
           "`Crawl-delay: 10`, so this is the host's"),
    "own stated policy being honoured, not this project's usual 2s (§3).",
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard runs on every fetch and finds nothing, so there is no",
    "reduction to explain and the documents are whole.",
    "",
    "TWO PUBLISHERS AT TWO GRAINS, RECONCILING TO THE CENT.",
    "  `roster`   -- DF&A's own \"List of Organization and Award amounts\":",
    "                31 organisations x 2 initiatives, 37 priced cells,",
    "                $149,177,618.45, with the state's own `Total:` row.",
    "  `governor` -- the Governor's 2026-08-27 release, which enumerates ALL",
    "                50 PROJECT AWARDS individually, each priced.",
    "The 50 projects sum to the roster's three column totals exactly. Nothing",
    "was arranged; the check runs every build.",
    "",
    "THE ROSTER'S THREE AMOUNT COLUMNS ARE PAINTED AT ONE y, so the line model",
    "returns \"$2,571,095.00$0.00$2,571,095.00\" -- three figures welded into",
    "one. Session 32's RUN model separates them at Arkansas's own producer's",
    "boundaries. Do not read this PDF with rhtp_pdf_lines().",
    "",
    "THE `Total:` ROW IS PAINTED IN THE SAME SHAPE AS AN AWARD ROW. It is the",
    "reconciliation target and NEVER a recipient: a parse that does not exclude",
    "it reports 32 organisations and double the money.",
    "",
    "THE AWARD LIST CARRIES NO CMS FOOTER AT ALL. Every other document here",
    "does, and it is the WEAK form (\"This project is supported by\") carrying",
    "$208,779,396.02 -- WHICH IS THE ALLOTMENT, not a pool (§0.2). It sits",
    "unchanged on the RISE and HEART pages, which describe initiatives that",
    "have awarded NOTHING: the footer covers the PUBLICATION, not the",
    "programme (session 26). The provenance is the NOFO headers, the",
    "Governor's release and the budget narrative.",
    "",
    "ALL FOUR INITIATIVE PAGES CARRY THE SAME \"What is next? Upcoming",
    "announcements ...\" SENTENCE, including the two that have awarded $149M.",
    "The initiative pages cannot tell awarded from unawarded; the home page's",
    "award-list link can.",
    "",
    "THE FILE DIGESTS OF THE arkansasrhtp.com PAGES ARE USELESS AS A CHANGE",
    "TEST, and two fetches seconds apart will not show you that. WordPress",
    "stamps a `wp_block_styles_on_demand_placeholder:<13 hex>` token into an",
    "inline <style> body, derived from the RENDER TIMESTAMP: two fetches ten",
    "seconds apart are BYTE-IDENTICAL, and a copy taken thirty minutes earlier",
    "differs -- at exactly the same byte length. So --probe compares a CONTENT",
    "digest (session 34's California lesson, with the failing pair in hand).",
    "",
    "SEVEN ORGANISATIONS ARE SPELLED DIFFERENTLY BY THE TWO PUBLISHERS and one",
    "pair CLASSIFIES DIFFERENTLY: \"Arkansas Children's Hospital\" (roster) is a",
    "named hospital worth $301,400 and \"Arkansas Children's\" (release) is not.",
    "The award rows carry the ROSTER's spelling, because it is the primary",
    "source. The divergence is asserted, never repaired (§2).",
    "",
    "TWO OF FOUR INITIATIVES HAVE NOT AWARDED -- RISE AR and HEART -- so",
    "$149,177,618.45 is a PARTIAL YEAR against a $208,779,396 allotment.",
    "Both NOFOs have closed, NEITHER names an award date, and CMS requires all",
    "Year 1 funds obligated by 2026-10-30.",
    "",
    paste0("Fetched: ", Sys.Date()),
    "",
    sprintf("%-58s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 58 + 12 + 64)
  ), path)
  cat(sprintf("%-58s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-18s %s", entries$key, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

ar_read_text <- function(key) {
  path <- ar_path(key)
  if (!file.exists(path)) {
    stop("[AR] missing archive: ", basename(path),
         " -- run `Rscript R/03ai_ar_year1_awardees.R --fetch` first.",
         call. = FALSE)
  }
  raw <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt
}

#' The reduction, and it is the change test
#'
#' Tags, `<script>`, `<style>` and `<noscript>` are discarded, which is what
#' absorbs the `wp_block_styles_on_demand_placeholder` token: it lives in a
#' `<style>` BODY, so no attribute-level reduction would reach it and no
#' byte-count check would see it either -- the token is a fixed 13 hex
#' characters, so the page is exactly the same length every time.
ar_reduce_html <- function(html) {
  doc <- xml2::read_html(html)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style | //noscript"))
  stringr::str_squish(xml2::xml_text(doc))
}

ar_html_text <- function(key, html = NULL) {
  ar_reduce_html(if (is.null(html)) ar_read_text(key) else html)
}

ar_content_digest <- function(key, html = NULL) {
  digest::digest(ar_html_text(key, html), algo = "sha256")
}

#' The text nodes of an HTML document, in document order
#'
#' The Governor's release puts each organisation, each project title and each
#' description in its own node, so the node list is what separates them.
#' `xml_text()` on the whole document welds "ARcare:" onto its project title.
ar_html_nodes <- function(key, html = NULL) {
  doc <- xml2::read_html(if (is.null(html)) ar_read_text(key) else html)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style | //noscript"))
  out <- stringr::str_squish(xml2::xml_text(xml2::xml_find_all(doc, "//text()")))
  out[nzchar(out)]
}

ar_pdf_cache <- new.env(parent = emptyenv())

#' Every painted run of one PDF, cached -- the run model of session 32
ar_runs <- function(key) {
  if (!exists(key, envir = ar_pdf_cache, inherits = FALSE)) {
    assign(key, rhtp_pdf_runs(ar_path(key)), envir = ar_pdf_cache)
  }
  get(key, envir = ar_pdf_cache, inherits = FALSE)
}

ar_pdf_flat <- function(key) {
  ck <- paste0("flat_", key)
  if (!exists(ck, envir = ar_pdf_cache, inherits = FALSE)) {
    assign(ck, stringr::str_squish(
      paste(rhtp_pdf_lines(ar_path(key))$text, collapse = " ")),
      envir = ar_pdf_cache)
  }
  get(ck, envir = ar_pdf_cache, inherits = FALSE)
}

ar_money <- function(x) {
  paste0("$", formatC(x, format = "f", digits = 2, big.mark = ","))
}

ar_num <- function(s) as.numeric(stringr::str_remove_all(s, "[$,\\s]"))


# -- the award list, read as RUNS ---------------------------------------------

AR_AMOUNT_CELL_RE <- "^\\$[0-9,]+\\.[0-9]{2}$"

#' A run's line key: runs sharing one were painted at one vertical position
ar_line_key <- function(r) {
  if (nrow(r) == 0L) return(integer(0))
  cumsum(c(TRUE, r$page[-1] != r$page[-nrow(r)] | r$line[-1] != r$line[-nrow(r)]))
}

#' The award list: 31 organisations, three amount columns, and the Total row
#'
#' Walks the runs in the order Arkansas painted them. A line whose runs are ALL
#' amount cells closes a row; anything else accumulates as the organisation
#' name, which is what carries the one name the PDF sets across two lines
#' ("Arkansas Baptist Childrens Homes and Family Ministries").
#'
#' NOTHING HERE THRESHOLDS A GAP OR READS AN x AGAINST A COLUMN BOUNDARY. The
#' three amounts of a row are the three runs of its line, in the order they
#' were painted, and the assertions below establish that that order is
#' THRIVE, PACT, Total three independent ways.
ar_roster <- function() {
  r <- ar_runs("roster")
  r$t <- trimws(r$text)
  is_amt <- stringr::str_detect(r$t, AR_AMOUNT_CELL_RE)
  key <- ar_line_key(r)
  lines <- split(seq_len(nrow(r)), key)

  # The header, and it is a positive control: if Arkansas re-orders or renames
  # its columns this refuses rather than silently reading the new order as the
  # old one. The header occupies the first three painted lines.
  hdr <- unlist(lapply(lines[1:3], function(ix) r$t[ix]), use.names = FALSE)
  if (!identical(hdr, AR_COLUMNS)) {
    stop("[AR] the award list's header is not the one this parser was written ",
         "against.\n  expected: ", paste(AR_COLUMNS, collapse = " | "),
         "\n  found   : ", paste(hdr, collapse = " | "),
         "\nThe column ORDER decides which of $55.7M and $93.6M is THRIVE and ",
         "which is PACT, so a changed header is a document to re-read, never ",
         "a parse to adjust.", call. = FALSE)
  }
  hdr_x <- unlist(lapply(lines[1:3], function(ix) r$x[ix]), use.names = FALSE)
  if (!all(diff(hdr_x) > 0)) {
    stop("[AR] the award list's header runs are no longer painted left to ",
         "right, so the painted order can no longer be read as the column ",
         "order.", call. = FALSE)
  }

  rows <- list()
  name_parts <- character()
  for (ix in lines[-(1:3)]) {
    if (all(is_amt[ix])) {
      if (length(ix) != 3L) {
        stop("[AR] an amount line carries ", length(ix), " cells, not 3: ",
             paste(r$t[ix], collapse = " | "),
             ". The award list has three amount columns and a row that does ",
             "not is a document to re-read.", call. = FALSE)
      }
      if (!all(diff(r$x[ix]) > 0)) {
        stop("[AR] an amount line's three cells are not painted left to ",
             "right, so THRIVE cannot be told from PACT by painted order: ",
             paste(r$t[ix], collapse = " | "), call. = FALSE)
      }
      if (!length(name_parts)) {
        stop("[AR] an amount line arrived with no organisation name before it.",
             call. = FALSE)
      }
      rows[[length(rows) + 1L]] <- tibble::tibble(
        # Paste FIRST, trim after -- a run boundary very often falls on the
        # space that separated it from the next (session 32).
        label  = stringr::str_squish(paste(name_parts, collapse = " ")),
        thrive = ar_num(r$t[ix[1]]),
        pact   = ar_num(r$t[ix[2]]),
        total  = ar_num(r$t[ix[3]])
      )
      name_parts <- character()
    } else {
      name_parts <- c(name_parts, paste(r$text[ix], collapse = ""))
    }
  }
  if (length(name_parts)) {
    stop("[AR] the award list ends with an organisation carrying no amounts: ",
         stringr::str_squish(paste(name_parts, collapse = " ")), call. = FALSE)
  }
  dplyr::bind_rows(rows)
}

#' The 31 award-list rows, with the `Total:` row split off as the target
ar_roster_parts <- function() {
  d <- ar_roster()
  is_total <- stringr::str_detect(d$label, "^Total:?$")
  if (sum(is_total) != 1L || !is_total[nrow(d)]) {
    stop("[AR] the award list's `Total:` row is not the last row, or there is ",
         "not exactly one of it (found ", sum(is_total), "). It is painted in ",
         "the same shape as an award row, so this parser must know which row ",
         "it is: read as a recipient it reports 32 organisations and doubles ",
         "the money.", call. = FALSE)
  }
  list(awards = d[!is_total, , drop = FALSE], total = d[is_total, ])
}


# -- the Governor's 50 project awards -----------------------------------------

#' Every project award the Governor's release names, one row each
#'
#' The release is the ONLY source at project grain, and it is the finer of the
#' two: 50 projects against the award list's 37 organisation-initiative cells.
#' It is parsed here so that the reconciliation between the two publishers can
#' be a machine check rather than a claim (§0.4).
ar_projects <- function(html = NULL) {
  nodes <- ar_html_nodes("governor", html)
  find_one <- function(pat, what) {
    hit <- which(stringr::str_detect(nodes, stringr::fixed(pat)))
    if (length(hit) < 1L) {
      stop("[AR] the Governor's release no longer carries ", what, ": ",
           sQuote(pat), call. = FALSE)
    }
    hit[1]
  }
  i_thrive <- find_one("THRIVE grant recipients are", "the THRIVE roster heading")
  i_pact   <- find_one("PACT grant recipients are", "the PACT roster heading")
  i_end    <- find_one("Project specifics are based off",
                       "the closing not-final sentence")
  if (!(i_thrive < i_pact && i_pact < i_end)) {
    stop("[AR] the Governor's release's three section markers are out of ",
         "order, so the initiative each project belongs to cannot be read ",
         "from its position.", call. = FALSE)
  }

  one_section <- function(from, to, pool) {
    seg <- nodes[(from + 1L):(to - 1L)]
    starts <- stringr::str_detect(seg, ":$") & !stringr::str_detect(seg, "^\\(")
    if (!any(starts)) {
      stop("[AR] the ", pool, " section of the Governor's release names no ",
           "organisation.", call. = FALSE)
    }
    grp <- cumsum(starts)
    seg <- seg[grp > 0L]
    grp <- grp[grp > 0L]
    purrr::map_dfr(split(seg, grp), function(block) {
      org <- stringr::str_remove(block[1], ":$")
      rest <- block[-1]
      # Join, THEN match: one of the fifty has its "$" and its digits in two
      # separate nodes, and a pattern applied node by node misses it.
      blob <- stringr::str_squish(paste(rest, collapse = " "))
      m <- stringr::str_match_all(blob, AR_AMOUNT_RE)[[1]]
      if (nrow(m) != 1L) {
        stop("[AR] the project ", sQuote(paste(org, block[2])), " carries ",
             nrow(m), " dollar figures, not exactly 1. Which one is the award ",
             "is then a guess, and this parser does not guess.", call. = FALSE)
      }
      tibble::tibble(
        pool = pool,
        awardee_as_published = org,
        project_title = if (length(rest)) rest[1] else NA_character_,
        project_description = stringr::str_squish(
          stringr::str_remove(blob, stringr::fixed(m[1, 1]))),
        amount = ar_num(m[1, 2])
      )
    })
  }

  out <- dplyr::bind_rows(
    one_section(i_thrive, i_pact, "THRIVE"),
    one_section(i_pact, i_end, "PACT")
  )
  out$project_description <- stringr::str_remove(out$project_description,
                                                 "\\s*\u2013\\s*$")
  out
}

#' The release's organisation names, mapped onto the award list's spellings
ar_projects_joined <- function(html = NULL) {
  p <- ar_projects(html)
  mapped <- AR_RELEASE_SPELLINGS[p$awardee_as_published]
  p$awardee <- dplyr::if_else(is.na(mapped), p$awardee_as_published,
                              unname(mapped))
  p
}


# -- §6.2 provenance ----------------------------------------------------------

#' Three programme-scoped sources, none of them the CMS footer
#'
#' Each NOFO's own header ties the initiative whose name IS a column of the
#' award list to RHTP, by name and by awarding agency. That is the check the
#' footer cannot make here, because the footer's subject is "This project" and
#' its amount is the allotment.
ar_assert_programme_provenance <- function() {
  for (i in seq_len(nrow(AR_INITIATIVES))) {
    key <- AR_INITIATIVES$nofo_key[i]
    txt <- ar_pdf_flat(key)
    # The NOFOs are ADA re-exports and two of them paint runs of words with
    # the spaces suppressed, so provenance is checked on a letters-only
    # reduction as well (session 32's run-spacing finding, Louisiana's
    # normalisation).
    squashed <- stringr::str_remove_all(txt, "[^A-Za-z0-9]")
    want <- c(AR_NOFO_AUTHORITY, AR_NOFO_AGENCY)
    for (w in want) {
      ok <- stringr::str_detect(txt, stringr::fixed(w)) ||
        stringr::str_detect(squashed,
                            stringr::fixed(stringr::str_remove_all(w, "[^A-Za-z0-9]")))
      if (!ok) {
        stop("[AR] the ", AR_INITIATIVES$pool[i], " NOFO no longer states ",
             sQuote(w), ". That header is the programme-scoped provenance for ",
             "this initiative -- the CMS footer here is the weak form and ",
             "carries the ALLOTMENT, so it cannot stand in for it (§6.2).",
             call. = FALSE)
      }
    }
  }

  gov <- ar_html_text("governor")
  for (q in AR_GOV_QUOTES) {
    if (!stringr::str_detect(gov, stringr::fixed(q))) {
      stop("[AR] the Governor's release no longer says ", sQuote(q), ".",
           call. = FALSE)
    }
  }

  # Kansas's second source: the plan document, which carries no CMS footer
  # because the document IS the plan, and which places all four initiatives
  # inside Arkansas's own structure.
  bn <- ar_pdf_flat("budget_narrative")
  if (!stringr::str_detect(bn, stringr::fixed("Rural Health Transformation"))) {
    stop("[AR] the Year 1 Revised Budget Narrative no longer names the ",
         "Rural Health Transformation Program.", call. = FALSE)
  }
  for (p in c("THRIVE", "PACT", "RISE", "HEART")) {
    if (!stringr::str_detect(bn, stringr::fixed(p))) {
      stop("[AR] the budget narrative no longer places ", p, " inside ",
           "Arkansas's plan.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Every award action postdates Arkansas's CMS Notice of Award
#'
#' Read off the NOFOs' own application windows and the announcement date, not
#' typed as a conclusion. Texas's `HHS0015180` closed before its state had the
#' money; Arkansas's earliest NOFO opened 2026-05-11, four and a half months
#' after the 2025-12-29 award.
ar_assert_after_noa <- function() {
  dates <- c(as.Date(AR_INITIATIVES$nofo_open),
             as.Date(AR_INITIATIVES$nofo_close), AR_ANNOUNCE_DATE)
  if (any(dates <= AR_NOA_DATE)) {
    stop("[AR] ", sum(dates <= AR_NOA_DATE), " Arkansas RHTP date(s) do not ",
         "postdate the 2025-12-29 CMS Notice of Award. A solicitation that ",
         "closed before the state had the money cannot have spent it (§6.2).",
         call. = FALSE)
  }
  for (i in seq_len(nrow(AR_INITIATIVES))) {
    txt <- ar_pdf_flat(AR_INITIATIVES$nofo_key[i])
    got <- stringr::str_detect(txt, stringr::fixed(
      format(as.Date(AR_INITIATIVES$nofo_close[i]), "%B %-d, %Y")))
    if (!got) {
      # Some NOFOs paint the date with the spaces suppressed.
      squashed <- stringr::str_remove_all(txt, "[^A-Za-z0-9]")
      got <- stringr::str_detect(squashed, stringr::fixed(
        stringr::str_remove_all(
          format(as.Date(AR_INITIATIVES$nofo_close[i]), "%B %-d, %Y"),
          "[^A-Za-z0-9]")))
    }
    if (!got) {
      stop("[AR] the ", AR_INITIATIVES$pool[i], " NOFO no longer states its ",
           "application close date of ", AR_INITIATIVES$nofo_close[i],
           ". Those dates are what date this state's negative and its ",
           "positive alike.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The footer is the WEAK form, it carries the ALLOTMENT, and it is DEMOTED
#'
#' Two independent grounds, and both are session findings rather than opinions.
#' (1) Session 27's audit: the subject is "This project", so the sentence is a
#' claim about the paper. (2) Session 37's rule: the amount collides with the
#' §7.1 anchor, so it is Tier 1 wearing a project's grammar, and
#' `rhtp_assert_footer_not_allotment()` refuses to let it be declared a pool.
#'
#' And session 26's Nevada lesson is MEASURED here rather than cited: the same
#' footer sits on the RISE and HEART pages, which describe initiatives that
#' have awarded nothing at all. A check keyed on "does this page carry the CMS
#' footer" answers yes for those two and tells you nothing.
#'
#' Non-strict by default (Kansas's demotion): returns NA with a message rather
#' than throwing, so an estate-wide re-post that drops the boilerplate cannot
#' hard-fail Arkansas -- and so a future state whose ONLY evidence is a "this
#' project" footer does not pass the test Arkansas passes.
ar_assert_footer_is_the_allotment <- function(strict = FALSE) {
  pages <- c("thrive", "pact", "rise", "heart")
  carriers <- vapply(pages, function(k)
    stringr::str_detect(ar_html_text(k), stringr::fixed(AR_FOOTER_SUBJECT)),
    logical(1))
  gov_has <- stringr::str_detect(ar_html_text("governor"),
                                 stringr::fixed(AR_FOOTER_SUBJECT))

  if (!all(carriers) || !gov_has) {
    msg <- paste0("[AR] the CMS financial-assistance footer is missing from ",
                  paste(c(pages[!carriers], if (!gov_has) "the Governor's release"),
                        collapse = ", "), ".")
    if (strict) stop(msg, call. = FALSE)
    message(msg, " The footer is DEMOTED here on two grounds -- it is the weak",
            " 'This project' form and its amount is the ALLOTMENT -- so this",
            " is reported and NOT a build failure. Provenance is carried by",
            " the NOFO headers, the Governor's release and the budget",
            " narrative (§6.2, session 27).")
    return(invisible(NA))
  }

  # The amount, and §0.2's machine rule over it.
  for (k in c(pages, "governor")) {
    txt <- ar_html_text(k)
    m <- stringr::str_match(txt, "financial assistance award totaling \\$([0-9,.]+)")
    if (is.na(m[1, 2])) {
      stop("[AR] ", k, " carries the footer sentence but no amount after ",
           "'totaling'.", call. = FALSE)
    }
    amt <- ar_num(m[1, 2])
    if (abs(amt - AR_FOOTER_AMOUNT) > 0.005) {
      stop("[AR] ", k, "'s footer prints ", ar_money(amt), " where this file ",
           "recorded ", ar_money(AR_FOOTER_AMOUNT), ". Two publishers ",
           "disagreeing about a figure is a finding to record, never a ",
           "number to average (§8).", call. = FALSE)
    }
    # Declared STATE_ALLOTMENT, and the assertion refuses that declaration the
    # day it stops colliding with the anchor -- which is the half of session
    # 37's rule that matters here, because a Tier 1 reading of a footer rests
    # entirely on the collision.
    rhtp_assert_footer_not_allotment(
      amount = amt, state = AR_STATE, declared_tier = "STATE_ALLOTMENT",
      label = paste0("the CMS footer on ", k))
  }

  # THE UNAWARDED INITIATIVES CARRY IT TOO. This is the measurement, not a
  # citation of Nevada.
  unawarded <- AR_INITIATIVES$pool[!AR_INITIATIVES$awarded]
  if (!all(carriers[c("rise", "heart")])) {
    stop("[AR] the footer is no longer on both unawarded initiative pages, ",
         "so this file can no longer show from Arkansas's own estate that the ",
         "footer covers the publication rather than the programme.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The award document itself carries NO CMS footer
#'
#' Maine's shape: the one document that names recipients and amounts is the one
#' with no provenance sentence on it. Recorded so that a future session does
#' not go looking for a footer that was never there and read its absence as a
#' fetch failure.
ar_assert_roster_has_no_footer <- function() {
  txt <- ar_pdf_flat("roster")
  for (marker in c("Centers for Medicare", "financial assistance award",
                   "RHTP", "Rural Health Transformation")) {
    if (stringr::str_detect(txt, stringr::fixed(marker))) {
      stop("[AR] the award list now carries ", sQuote(marker), ". It carried ",
           "no provenance sentence at all when this file was written, which ",
           "is why the NOFO headers and the Governor's release are the §6.2 ",
           "gate. A provenance sentence appearing ON the award document is a ",
           "STRONGER source and should be wired in, not ignored.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- the run model, and the reason this file needs it --------------------------

#' The LINE model still merges the three amount columns
#'
#' A positive control for the run model, and session 35's lesson as code: a
#' header claiming the columns need runs is worth nothing if nobody can see the
#' merge. This reproduces it. If Arkansas ever paints the columns at distinct
#' y values this fails, and the honest response is to re-read the document --
#' not to keep a comment that says the opposite of the code it heads.
ar_assert_line_model_merges <- function() {
  L <- rhtp_pdf_lines(ar_path("roster"))
  welded <- stringr::str_detect(L$text, "^\\$[0-9,]+\\.[0-9]{2}\\$")
  if (!any(welded)) {
    stop("[AR] `rhtp_pdf_lines()` no longer welds the award list's amount ",
         "columns together, so the stated reason this file uses the RUN model ",
         "no longer holds. Re-read the PDF and rewrite the header before ",
         "changing the parser (§2.1).", call. = FALSE)
  }
  # And the runs DO separate them: same document, three cells per row.
  parts <- ar_roster_parts()
  if (nrow(parts$awards) != AR_ORG_COUNT) {
    stop("[AR] the run model reads ", nrow(parts$awards), " organisations, ",
         "not ", AR_ORG_COUNT, ".", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the reconciliation, both directions --------------------------------------

#' The 31 rows sum to Arkansas's own `Total:` row, on all three columns
ar_assert_reconciles <- function() {
  parts <- ar_roster_parts()
  a <- parts$awards
  t <- parts$total

  # Arkansas's own row identity: the third column is the first two added.
  bad <- which(abs(a$thrive + a$pact - a$total) > 0.005)
  if (length(bad)) {
    stop("[AR] on ", length(bad), " row(s) THRIVE + PACT does not equal the ",
         "published total: ", paste(a$label[bad], collapse = "; "),
         ". That identity is how this parser knows the third column is ",
         "derived and the first two are the award figures.", call. = FALSE)
  }

  for (col in c("thrive", "pact", "total")) {
    want <- t[[col]]
    got <- sum(a[[col]])
    if (abs(got - want) > 0.005) {
      stop("[AR] the ", toupper(col), " column sums to ", ar_money(got),
           " against Arkansas's own `Total:` row of ", ar_money(want),
           ". THE RECONCILIATION ON ALL THREE COLUMNS IS WHAT ESTABLISHES ",
           "WHICH COLUMN IS THRIVE AND WHICH IS PACT -- $55.7M and $93.6M are ",
           "both plausible, and only the totals tell them apart.",
           call. = FALSE)
    }
  }

  # Pinned against the constants too, so a change in the source document is a
  # failure here rather than a quietly different published figure.
  for (p in list(c("thrive", AR_TOTAL_THRIVE), c("pact", AR_TOTAL_PACT),
                 c("total", AR_TOTAL_YR1))) {
    if (abs(t[[p[1]]] - as.numeric(p[2])) > 0.005) {
      stop("[AR] the award list's `Total:` row now prints ",
           ar_money(t[[p[1]]]), " for ", toupper(p[1]), " where this file ",
           "recorded ", ar_money(as.numeric(p[2])), ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' TWO PUBLISHERS, TWO GRAINS, RECONCILING TO THE CENT
#'
#' The Governor's 50 priced projects against DF&A's 31 priced organisations.
#' Neither document mentions the other's grain and nothing was arranged, which
#' is what makes this the strongest corroboration in this repository outside
#' Florida's.
ar_assert_projects_reconcile <- function(html = NULL) {
  p <- ar_projects_joined(html)
  if (nrow(p) != AR_PROJECT_COUNT) {
    stop("[AR] the Governor's release names ", nrow(p), " project awards, not ",
         AR_PROJECT_COUNT, " -- and its own prose says ",
         sQuote("The 50 project awards"), ".", call. = FALSE)
  }
  by_pool <- p %>% dplyr::count(.data$pool)
  if (!identical(sort(by_pool$n), c(25L, 25L))) {
    stop("[AR] the release's projects no longer split 25 THRIVE / 25 PACT: ",
         paste(by_pool$pool, by_pool$n, collapse = ", "), call. = FALSE)
  }

  want <- c(THRIVE = AR_TOTAL_THRIVE, PACT = AR_TOTAL_PACT)
  for (pool in names(want)) {
    got <- sum(p$amount[p$pool == pool])
    if (abs(got - want[[pool]]) > 0.005) {
      stop("[AR] the release's ", pool, " projects sum to ", ar_money(got),
           " against the award list's ", ar_money(want[[pool]]),
           ". Two publishers at two grains no longer close on each other, ",
           "which is a document to re-read (§0.4).", call. = FALSE)
    }
  }
  if (abs(sum(p$amount) - AR_TOTAL_YR1) > 0.005) {
    stop("[AR] the 50 projects sum to ", ar_money(sum(p$amount)),
         " against ", ar_money(AR_TOTAL_YR1), ".", call. = FALSE)
  }

  # And per ORGANISATION per INITIATIVE, which is the join the seven spellings
  # would otherwise break.
  parts <- ar_roster_parts()$awards
  long <- dplyr::bind_rows(
    tibble::tibble(awardee = parts$label, pool = "THRIVE", amount = parts$thrive),
    tibble::tibble(awardee = parts$label, pool = "PACT", amount = parts$pact)
  ) %>% dplyr::filter(.data$amount > 0)
  agg <- p %>%
    dplyr::group_by(.data$awardee, .data$pool) %>%
    dplyr::summarise(amount = sum(.data$amount), .groups = "drop")
  cmp <- dplyr::full_join(long, agg, by = c("awardee", "pool"),
                          suffix = c("_list", "_release"))
  gaps <- cmp %>%
    dplyr::filter(is.na(.data$amount_list) | is.na(.data$amount_release) |
                    abs(.data$amount_list - .data$amount_release) > 0.005)
  if (nrow(gaps)) {
    stop("[AR] ", nrow(gaps), " organisation-initiative pair(s) do not agree ",
         "between the award list and the Governor's release:\n  ",
         paste(sprintf("%s / %s: list %s, release %s", gaps$awardee, gaps$pool,
                       ifelse(is.na(gaps$amount_list), "absent",
                              ar_money(gaps$amount_list)),
                       ifelse(is.na(gaps$amount_release), "absent",
                              ar_money(gaps$amount_release))),
               collapse = "\n  "),
         "\nIf a name is the only difference, it belongs in ",
         "AR_RELEASE_SPELLINGS as a hand-read entry -- never resolved by a ",
         "fuzzy match (§2).", call. = FALSE)
  }
  invisible(TRUE)
}

#' The seven spellings, and an EIGHTH fails the build
ar_assert_release_spellings <- function(html = NULL) {
  p <- ar_projects_joined(html)
  listed <- ar_roster_parts()$awards$label
  extra <- setdiff(unique(p$awardee), listed)
  if (length(extra)) {
    stop("[AR] the Governor's release names ", length(extra),
         " organisation(s) the award list does not, after applying the ",
         "recorded spelling map: ", paste(extra, collapse = "; "),
         ". Add a hand-read entry to AR_RELEASE_SPELLINGS if it is a spelling, ",
         "or read the document if it is a new recipient.", call. = FALSE)
    }
  used <- names(AR_RELEASE_SPELLINGS) %in% p$awardee_as_published
  if (!all(used)) {
    stop("[AR] ", sum(!used), " recorded spelling(s) no longer occur in the ",
         "release: ", paste(names(AR_RELEASE_SPELLINGS)[!used], collapse = "; "),
         ". A map entry that matches nothing is a map entry that has stopped ",
         "being true.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The two spellings of one organisation CLASSIFY DIFFERENTLY, and that is
#' asserted rather than repaired
#'
#' North Carolina's UNC finding a second time, and here it moves a DOLLAR:
#' the award list's "Arkansas Children's Hospital" is a named hospital worth
#' $301,400 and the release's "Arkansas Children's" is not. The award rows
#' carry the award list's spelling because it is the primary source (§8), and
#' NEITHER machine answer is silently preferred -- the divergence is recorded.
ar_assert_two_spellings_classify_differently <- function() {
  cls <- rhtp_classify_recipient_type(unname(AR_TWO_SPELLINGS), AR_STATE)
  fl <- rhtp_classify_flow(cls$recipient_type, rep(NA_character_, 2L))
  if (!identical(cls$recipient_type[1], "HOSPITAL_OR_SYSTEM")) {
    stop("[AR] the award list's ", sQuote(AR_TWO_SPELLINGS[["award_list"]]),
         " no longer types HOSPITAL_OR_SYSTEM (got ", cls$recipient_type[1],
         ").", call. = FALSE)
  }
  if (identical(fl$distributed_to_hospital[1], fl$distributed_to_hospital[2])) {
    stop("[AR] the two published spellings of ",
         sQuote(AR_TWO_SPELLINGS[["award_list"]]), " now classify the SAME ",
         "way. The finding was that they do not, and that a fuzzy merge here ",
         "would move $301,400 rather than just a label. Re-read §8's name ",
         "rule before removing this.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The naive amount pattern silently drops one of the fifty
ar_assert_split_amount_node <- function(html = NULL) {
  nodes <- ar_html_nodes("governor", html)
  flat <- stringr::str_squish(paste(nodes, collapse = " "))
  naive <- stringr::str_count(flat, AR_NAIVE_AMOUNT_RE)
  if (naive >= AR_PROJECT_COUNT) {
    stop("[AR] the naive amount pattern now finds ", naive, " of ",
         AR_PROJECT_COUNT, " project amounts. It found 49 when this file was ",
         "written, because ONE amount is painted as ", sQuote("$"), " and ",
         sQuote("1,455,689.00"), " in two separate nodes. If the release has ",
         "been re-published without that split, say so -- do not simply relax ",
         "the parser, because the tolerant pattern is what makes the ",
         "reconciliation possible.", call. = FALSE)
  }
  p <- ar_projects(html)
  hit <- p$amount[p$awardee_as_published == AR_SPLIT_NODE_ORG]
  if (!any(abs(hit - AR_SPLIT_NODE_AMOUNT) < 0.005)) {
    stop("[AR] the parser no longer recovers ",
         ar_money(AR_SPLIT_NODE_AMOUNT), " for ", AR_SPLIT_NODE_ORG,
         " -- the one amount the release splits across two nodes. Dropping it ",
         "is SILENT: the sums simply miss by that much.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- positive controls --------------------------------------------------------

#' Arkansas publishes a roster in a recognisable form, for the two initiatives
#' that have awarded and for neither of the other two
#'
#' Without this, "RISE and HEART have published nothing" is indistinguishable
#' from "we are reading the wrong page". The home page carries Arkansas's own
#' link text for the award list; a SECOND such link is a new roster to read and
#' fails the build.
ar_assert_award_index <- function(html = NULL) {
  home <- ar_html_text("home", html)
  n <- stringr::str_count(home, stringr::fixed(AR_ROSTER_LINK_TEXT))
  if (n < 1L) {
    stop("[AR] the home page no longer carries Arkansas's own award-list link ",
         "text, ", sQuote(AR_ROSTER_LINK_TEXT), ". That link is the ONLY thing ",
         "on this estate that distinguishes an awarded initiative from an ",
         "unawarded one -- the four initiative pages all read the same -- so ",
         "losing it is losing the positive control, not a cosmetic change.",
         call. = FALSE)
  }
  if (n > 1L) {
    stop("[AR] the home page now carries ", n, " award-list links where it ",
         "carried one. A SECOND roster is a new document to read -- almost ",
         "certainly RISE AR or HEART -- and this file must be rewritten, not ",
         "patched: `ar_year1_awardees.csv` covers two initiatives of four.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' All four initiative pages read the same, awarded or not
ar_assert_initiative_pages_cannot_tell <- function() {
  pages <- c("thrive", "pact", "rise", "heart")
  has <- vapply(pages, function(k)
    stringr::str_detect(ar_html_text(k),
                        stringr::fixed(AR_INITIATIVE_BOILERPLATE)),
    logical(1))
  if (!all(has)) {
    stop("[AR] the forward-looking sentence is no longer on all four ",
         "initiative pages (missing from ", paste(pages[!has], collapse = ", "),
         "). The finding was that it is on ALL FOUR -- including THRIVE and ",
         "PACT, which have awarded $149M between them -- so the initiative ",
         "pages cannot tell awarded from unawarded and the probe must not ",
         "read them for that. If the pages have started to differ, the probe ",
         "gains a signal and should be rewritten to use it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' RISE AR and HEART have closed and named nobody
ar_assert_two_initiatives_remain <- function(html = NULL) {
  gov <- ar_html_text("governor")
  if (!stringr::str_detect(gov, stringr::fixed(
    "Two additional initiatives of grant funding will be announced at a later date"))) {
    stop("[AR] the Governor's release no longer says two initiatives are ",
         "still to come. That sentence is why this file's total is a PARTIAL ",
         "YEAR.", call. = FALSE)
  }
  pending <- AR_INITIATIVES %>% dplyr::filter(!.data$awarded)
  for (i in seq_len(nrow(pending))) {
    txt <- ar_html_text(pending$pool[i] %>% stringr::str_replace(" AR$", "") %>%
                          stringr::str_to_lower(), html)
    for (marker in c("Notice of Intent to Award", "has been awarded",
                     "award recipients are", "grant recipients are")) {
      if (stringr::str_detect(txt, stringr::fixed(marker))) {
        stop("[AR] the ", pending$pool[i], " page now carries ",
             sQuote(marker), ". That initiative had awarded NOBODY when this ",
             "file was written. `ar_year1_awardees.csv` must be REWRITTEN to ",
             "cover it, not patched -- its 37 rows are two initiatives of ",
             "four.", call. = FALSE)
      }
    }
  }
  # Both windows are closed, and neither NOFO names an award date. That is the
  # honest statement of the clock: what dates it is CMS's obligation deadline,
  # which both NOFOs print themselves.
  for (i in seq_len(nrow(pending))) {
    txt <- ar_pdf_flat(pending$nofo_key[i])
    squashed <- stringr::str_remove_all(txt, "[^A-Za-z0-9]")
    ok <- stringr::str_detect(squashed, stringr::fixed(
      stringr::str_remove_all(AR_OBLIGATION_QUOTE, "[^A-Za-z0-9]")))
    if (!ok) {
      stop("[AR] the ", pending$pool[i], " NOFO no longer states ",
           sQuote(AR_OBLIGATION_QUOTE), ". With no award date published by ",
           "Arkansas, that deadline is the only thing that dates this wait.",
           call. = FALSE)
    }
  }
  if (Sys.Date() <= max(as.Date(pending$nofo_close))) {
    message("[AR] note: ", pending$pool[which.max(as.Date(pending$nofo_close))],
            "'s application window has not yet closed.")
  }
  invisible(TRUE)
}

#' This is a PARTIAL YEAR and the arithmetic says so
ar_assert_partial_year <- function() {
  if (AR_TOTAL_YR1 >= AR_ALLOTMENT) {
    stop("[AR] the awarded total is no longer below the allotment.",
         call. = FALSE)
  }
  gov <- ar_html_text("governor")
  if (!stringr::str_detect(gov, stringr::fixed(
    "the $209 million the state expects to award by this fall"))) {
    stop("[AR] the Governor's release no longer states the figure Arkansas ",
         "expects to award. Without it this file's 71.5% is a ratio nobody ",
         "published.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The eligible class is HOSPITALS AMONG OTHERS, recorded before RISE/HEART land
ar_assert_eligible_class <- function() {
  txt <- ar_pdf_flat("nofo_thrive")
  squashed <- stringr::str_remove_all(txt, "[^A-Za-z0-9]")
  ok <- stringr::str_detect(squashed, stringr::fixed(
    stringr::str_remove_all(AR_ELIGIBLE_CLASS_QUOTE, "[^A-Za-z0-9]")))
  if (!ok) {
    stop("[AR] the THRIVE NOFO no longer states its eligible class. It read ",
         sQuote(AR_ELIGIBLE_CLASS_QUOTE), " -- hospitals AMONG OTHERS, which ",
         "is New Hampshire's FHC class and NOT Illinois's ICAHN class, so ",
         "§0.3 governs any Arkansas pass-through. That sentence is recorded ",
         "BEFORE RISE and HEART award anything, on purpose.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the award rows -----------------------------------------------------------

AR_NOTE_TAIL <- paste(
  "Published by the Arkansas Department of Finance and Administration (DF&A)",
  "in its Year 1 THRIVE/PACT award list, linked from arkansasrhtp.com under",
  "Arkansas's own words \"Download the List of Organization and Award",
  "amounts\". THE AMOUNT IS NOT FINAL AND ARKANSAS SAYS SO: \"Project",
  "specifics are based off recipient organizations' applications and the",
  "details of each grant will not be finalized until DFA signs an official",
  "agreement with each grantee.\" THE AWARD LIST STATES NO ORGANISATIONAL",
  "FORM AND CARRIES NO PROJECT DESCRIPTION, so `recipient_type` is derived",
  "from the recipient's own name (§8) and nothing in the primary source can",
  "move a row off it.")

#' Every award action Arkansas has priced, one row per organisation x initiative
#'
#' THIS IS THE GRAIN ARKANSAS PRICES. The award list publishes a figure per
#' organisation per initiative, so a row here is a figure Arkansas published:
#' nothing is divided (§6.2) and nothing is aggregated away either. Michigan's
#' lesson is the reason it is not one row per ORGANISATION -- RCJ carried one
#' row per organisation where MDHHS published one per award and understated
#' the state by $7.8M.
#'
#' `sum(amount)` over these 37 rows is $149,177,618.45 exactly, which is
#' Arkansas's own `Total:` row.
ar_award_rows <- function() {
  parts <- ar_roster_parts()$awards
  long <- dplyr::bind_rows(
    tibble::tibble(awardee = parts$label, award_pool = "THRIVE",
                   amount = parts$thrive, org_total = parts$total,
                   org_row = seq_len(nrow(parts))),
    tibble::tibble(awardee = parts$label, award_pool = "PACT",
                   amount = parts$pact, org_total = parts$total,
                   org_row = seq_len(nrow(parts)))
  ) %>%
    dplyr::filter(.data$amount > 0) %>%
    dplyr::arrange(.data$org_row, dplyr::desc(.data$award_pool))

  # THE SHARED §8/§10.2 CLASSIFIER, ON THE NAME ALONE, and the ninth state
  # where that is all the publisher offers. DF&A publishes a recipient and an
  # amount and nothing about the recipient's form -- no organisation-type
  # column of the kind Oregon and Alaska both have -- so this is Kansas's,
  # Maryland's, Nebraska's, Oklahoma's, Nevada's, Michigan's, Missouri's,
  # Iowa's and North Carolina's shape again, and by far the largest in dollars.
  #
  # `description` is NA on every row, and that is a fact about the award list
  # rather than an omission: it carries no project description at all. The
  # Governor's release DOES describe every project, and reading those
  # descriptions moves 11 project rows from `NON_HOSPITAL` to
  # `IN_KIND_BENEFIT` and NOT ONE DOLLAR into or out of the hospital total --
  # measured, not assumed, and carried in `ar_year1_projects.csv` where a row
  # is one project with one description. It is deliberately not folded in
  # here, because a row at THIS grain may span three projects with three
  # different descriptions and there is no honest way to pick one.
  cls <- rhtp_classify_recipient_type(long$awardee, AR_STATE)
  long$recipient_type <- cls$recipient_type
  long$recipient_type_confidence <- cls$determination_confidence
  long$recipient_type_basis <- cls$recipient_type_basis

  flow <- rhtp_classify_flow(long$recipient_type,
                             rep(NA_character_, nrow(long)))
  long$flow_type <- flow$flow_type
  long$distributed_to_hospital <- flow$distributed_to_hospital
  long$hospital_benefiting <- flow$hospital_benefiting
  long$flow_basis <- flow$flow_basis

  long$hospital_attribution <- rhtp_hospital_attribution(
    long$flow_type, long$distributed_to_hospital, long$recipient_type)

  # `AMOUNT_PRELIMINARY` IS AN EXISTING §8 CODE AND IS EXACTLY THIS CONDITION:
  # "the source states the amount is PRELIMINARY or not yet final ...
  # recipient_confirmed stays Yes and amount_confirmed is No". Arkansas's own
  # sentence is "the details of each grant will not be finalized until DFA
  # signs an official agreement with each grantee", which is Alaska's posture
  # word for word in effect. NO NEW CODE WAS INVENTED (§2).
  long$flag_reason <- dplyr::case_when(
    long$awardee == AR_CONSORTIUM ~
      "AMOUNT_PRELIMINARY;RECIPIENT_TYPE_INFERRED;FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
    long$recipient_type_confidence == "LOW" ~
      "AMOUNT_PRELIMINARY;RECIPIENT_TYPE_INFERRED",
    TRUE ~ "AMOUNT_PRELIMINARY"
  )

  init <- AR_INITIATIVES$round_name[match(long$award_pool, AR_INITIATIVES$pool)]

  out <- tibble::tibble(
    state = AR_STATE,
    row_no = seq_len(nrow(long)),
    awardee = long$awardee,
    amount = long$amount,
    recipient_type = long$recipient_type,
    distributed_to_hospital = long$distributed_to_hospital,
    note = paste0(
      "Initiative: ", init, ". ",
      "Arkansas published ", ar_money(long$org_total), " to this organisation ",
      "across both initiatives; this row is its ", long$award_pool,
      " figure alone and the two must not be added to that total. ",
      AR_NOTE_TAIL,
      dplyr::if_else(long$awardee == AR_CONSORTIUM,
        paste(" ARKANSAS RURAL HEALTH PARTNERSHIP IS A HOSPITAL CONSORTIUM ON",
              "THIS PIPELINE'S OWN KNOWLEDGE AND THE AWARD LIST SAYS NOTHING",
              "ABOUT IT. §10.2's association row turns on what the document",
              "says the money DOES -- administered to member hospitals",
              "(PASS_THROUGH_DESIGNATED, Yes) or spent on goods and services",
              "for them (IN_KIND_BENEFIT, No) -- and the award list says",
              "neither. Nothing was promoted (§0.4); queued as",
              "AR_ARHP_CONSORTIUM_FLOW."),
        "")),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = 2026L,
    source_document_title = paste0(
      "Arkansas DF&A, RHTP Year 1 THRIVE and PACT Awards -- List of ",
      "Organization and Award amounts"),
    state_source_url = ar_source("roster", "url"),
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "PARSED_PDF_RUNS",
    validator = "R/03ai_ar_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = long$recipient_type_basis,
    determination_confidence = dplyr::if_else(
      long$recipient_type_confidence == "HIGH" &
        long$distributed_to_hospital == "Yes", "MEDIUM",
      long$recipient_type_confidence),
    flag_reason = long$flag_reason,
    award_pool = long$award_pool,
    budget_period = AR_BUDGET_PERIOD,
    flow_type = long$flow_type,
    hospital_benefiting = long$hospital_benefiting,
    hospital_attribution = long$hospital_attribution,
    intermediary_name = NA_character_,
    determination_basis = paste(long$recipient_type_basis, long$flow_basis),
    amount_basis = paste(
      "The figure DF&A publishes for this organisation under this initiative,",
      "read from the award list's own column with session 32's run model. Its",
      "three amount columns are painted at one y, so the line model welds",
      "them into one string; the runs separate them at the producer's own",
      "boundaries. The 31 rows reconcile to Arkansas's own `Total:` row on",
      "ALL THREE columns to the cent, and the Governor's 50 priced projects",
      "reconcile to the same three figures independently."),
    organisation_award_total = long$org_total,
    round_name = init,
    announcement_date = as.character(AR_ANNOUNCE_DATE),
    source_archive_path = file.path("data/evidence/AR",
                                    ar_source("roster", "file"))
  )
  out$determination_confidence[is.na(out$determination_confidence)] <- "LOW"
  out
}

#' The Governor's 50 project awards -- the SAME MONEY at a FINER GRAIN
#'
#' NOT A SECOND AWARD FILE, AND NEVER TO BE ADDED TO `ar_year1_awardees.csv`.
#' These fifty rows and those thirty-seven are the same $149,177,618.45 read
#' from two publishers: South Dakota's two-file device, except that here the
#' two files' totals are EQUAL rather than disjoint, which makes the
#' double-count hazard sharper rather than milder.
#'
#' It exists because the release carries what the award list does not -- a
#' project description per row -- which is what §10.2's flow test reads, and
#' because 50 is the count the Governor states and neither 31 nor 37 is it.
#'
#' It keeps the RELEASE'S OWN SPELLINGS in `awardee_as_published` beside the
#' award list's in `awardee`, because seven organisations are spelled
#' differently and one pair classifies differently (§2 forbids merging them
#' away).
ar_project_rows <- function() {
  p <- ar_projects_joined()
  cls_pub <- rhtp_classify_recipient_type(p$awardee_as_published, AR_STATE)
  cls <- rhtp_classify_recipient_type(p$awardee, AR_STATE)
  flow <- rhtp_classify_flow(cls$recipient_type, p$project_description)

  tibble::tibble(
    state = AR_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    awardee_as_published = p$awardee_as_published,
    spelling_differs = p$awardee != p$awardee_as_published,
    award_pool = p$pool,
    amount = p$amount,
    project_title = p$project_title,
    project_description = p$project_description,
    recipient_type = cls$recipient_type,
    recipient_type_from_release_spelling = cls_pub$recipient_type,
    flow_type = flow$flow_type,
    distributed_to_hospital = flow$distributed_to_hospital,
    hospital_benefiting = flow$hospital_benefiting,
    determination_basis = paste(cls$recipient_type_basis, flow$flow_basis),
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    state_source_url = ar_source("governor", "url"),
    source_archive_path = file.path("data/evidence/AR",
                                    ar_source("governor", "file")),
    note = paste(
      "THE SAME MONEY AS `ar_year1_awardees.csv`, AT A FINER GRAIN. NEVER ADD",
      "THE TWO FILES: the 50 rows here and the 37 there are one",
      "$149,177,618.45, read from two publishers. This file exists for the",
      "project DESCRIPTION, which the award list does not carry, and for the",
      "Governor's own count of 50, which is neither 31 organisations nor 37",
      "award actions. `recipient_type` is derived from the AWARD LIST's",
      "spelling of the name (the primary source, §8);",
      "`recipient_type_from_release_spelling` records what the release's own",
      "spelling would give, which differs for Arkansas Children's and is",
      "worth $301,400.")
  )
}


# -- the status table ---------------------------------------------------------

#' What each of Arkansas's four initiatives has published
#'
#' NO `amount` COLUMN (Texas's device), and the reason here is narrower than
#' Texas's: `initiative_awarded_total` is a POOL figure Arkansas published
#' itself, not a per-recipient amount, so nothing summed from this table can
#' be read as one.
ar_status_table <- function() {
  today <- Sys.Date()
  AR_INITIATIVES %>%
    dplyr::transmute(
      state = AR_STATE,
      initiative = .data$pool,
      initiative_name = .data$round_name,
      stage = dplyr::if_else(.data$awarded, "AWARDED_ROSTER_PUBLISHED",
                             "CLOSED_NO_AWARD_DATE_PUBLISHED"),
      nofo_open = .data$nofo_open,
      nofo_close = .data$nofo_close,
      days_since_close = as.integer(today - as.Date(.data$nofo_close)),
      award_date_published = "No",
      obligation_deadline = as.character(AR_OBLIGATION_DATE),
      publishes_roster = dplyr::if_else(
        .data$awarded,
        "Yes -- on the DF&A award list linked from the home page",
        "No -- applications closed, NO award date published, nobody named"),
      named_recipients = dplyr::if_else(.data$awarded, "see award list", "0"),
      initiative_awarded_total = .data$awarded_total,
      state_source_url = vapply(.data$nofo_key, function(k)
        ar_source(k, "url"), character(1)),
      source_archive_path = file.path("data/evidence/AR",
                                      vapply(.data$nofo_key, function(k)
                                        ar_source(k, "file"), character(1))),
      note = dplyr::if_else(
        .data$awarded,
        paste("Awarded 2026-08-27. The amounts are NOT final: DF&A signs an",
              "official agreement with each grantee afterwards."),
        paste("Applications have CLOSED and Arkansas has published NO award",
              "date for this initiative -- Missouri's and North Carolina's",
              "footing. What dates the wait is CMS's own deadline, which this",
              "NOFO prints itself: all Year 1 funds must be obligated by",
              "2026-10-30. The initiative PAGE cannot be used as a signal:",
              "all four carry the same forward-looking sentence, including",
              "the two that have awarded $149M."))
    )
}

#' Arkansas holds NO RCJ Tier 3 candidate at all
ar_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(.data$state == AR_STATE, .data$award_tier == "SUBAWARD")
}

ar_disposition <- function() {
  cand <- ar_rcj_candidates()
  all_ar <- readRDS(here::here("data", "interim",
                               "stage2_record_table.rds")) %>%
    dplyr::filter(.data$state == AR_STATE)
  tibble::tribble(
    ~state, ~group, ~rcj_rows, ~disposition, ~evidence,
    AR_STATE,
    "RCJ Tier 3 candidates for Arkansas",
    nrow(cand), "NOT_IN_THE_AGGREGATOR_AT_ALL",
    paste0("Arkansas holds ", nrow(cand), " Tier 3 candidates against ",
           nrow(all_ar), " RCJ records in total, and no CMS state release ",
           "either -- `trigger_source = NEITHER` on BOTH discovery layers, ",
           "which is why nobody had looked. It had meanwhile published 31 ",
           "organisations, 37 priced award actions and ",
           ar_money(AR_TOTAL_YR1), " -- 71.5% of its allotment -- on a ",
           "dedicated RHTP domain, plus a 50-project roster from the ",
           "Governor. FLORIDA'S SHAPE (session 36's existence proof) a third ",
           "time after North Carolina, and the largest of the three in ",
           "dollars. A zero here is a fact about the DISCOVERY LAYER and ",
           "never about the state (§0.1).")
  )
}


# -- reconciliation, and Georgia's trap over the organisation total -----------

#' The figures, summed the only ways that are correct
#'
#' `organisation_award_total` REPEATS on both rows of the six organisations
#' that hold awards under both initiatives, so summing that column down the
#' file double-counts them by $91,182,626.91 and reports $240,360,245.36 for a
#' state that awarded $149,177,618.45. Georgia's trap, Nevada's device: sum
#' `amount`, or sum DISTINCT organisations.
ar_reconcile <- function(rows = NULL) {
  if (is.null(rows)) rows <- ar_award_rows()
  by_org <- rows %>%
    dplyr::distinct(.data$awardee, .data$organisation_award_total)
  tibble::tibble(
    quantity = c("award actions (rows)", "distinct organisations",
                 "sum(amount)", "sum of distinct organisation totals",
                 "THRIVE", "PACT",
                 "WRONG: sum(organisation_award_total) down the column"),
    value = c(nrow(rows), dplyr::n_distinct(rows$awardee),
              sum(rows$amount), sum(by_org$organisation_award_total),
              sum(rows$amount[rows$award_pool == "THRIVE"]),
              sum(rows$amount[rows$award_pool == "PACT"]),
              sum(rows$organisation_award_total))
  )
}

ar_assert_organisation_total_not_summable <- function(rows = NULL) {
  if (is.null(rows)) rows <- ar_award_rows()
  naive <- sum(rows$organisation_award_total)
  if (abs(naive - AR_TOTAL_YR1) < 0.005) {
    stop("[AR] summing `organisation_award_total` down the column now gives ",
         "the right answer, which means no organisation holds awards under ",
         "both initiatives any more. Six did. Re-read the award list: this ",
         "assertion exists to keep Georgia's trap visible, and it passing by ",
         "accident is worse than it failing.", call. = FALSE)
  }
  if (abs(sum(rows$amount) - AR_TOTAL_YR1) > 0.005) {
    stop("[AR] `sum(amount)` is ", ar_money(sum(rows$amount)), " against ",
         "Arkansas's published ", ar_money(AR_TOTAL_YR1), ".", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the hospital figure, and what is NOT claimed about it --------------------

#' The floor, the question beside it, and its DIRECTION
#'
#' 9 named-hospital award actions and $21,792,687.96 against 21 award rows /
#' 16 organisations / $100,723,693.49 on §8's standing fallback. Like
#' Oklahoma's and Michigan's it is ONE-DIRECTIONAL -- every one of the 21 is
#' already `distributed_to_hospital = No` -- so the floor is a genuine floor
#' and $122,516,381.45 is a genuine ceiling.
ar_assert_form_not_stated_queued <- function(rows = NULL) {
  if (is.null(rows)) rows <- ar_award_rows()
  fb <- rows[rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", ]
  orgs <- dplyr::distinct(fb, .data$awardee, .data$organisation_award_total)
  if (nrow(orgs) != 16L) {
    stop("[AR] ", nrow(orgs), " organisations carry §8's standing fallback, ",
         "not 16. The review queue row AR_RECIPIENT_FORM_NOT_STATED states ",
         "16 organisations and ", ar_money(100723693.49), "; a changed count ",
         "means the queue row is stale, which is the one thing a disclosure ",
         "must not be.", call. = FALSE)
  }
  if (abs(sum(orgs$organisation_award_total) - 100723693.49) > 0.005) {
    stop("[AR] the unstated-form organisations now hold ",
         ar_money(sum(orgs$organisation_award_total)), ", not ",
         ar_money(100723693.49), ".", call. = FALSE)
  }
  if (!all(fb$distributed_to_hospital == "No")) {
    stop("[AR] ", sum(fb$distributed_to_hospital != "No"), " unstated-form ",
         "row(s) are no longer `No`, so the question is no longer ",
         "one-directional and the queue row's stated CEILING is wrong.",
         call. = FALSE)
  }

  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  for (id in c("AR_RECIPIENT_FORM_NOT_STATED", "AR_ARHP_CONSORTIUM_FLOW")) {
    if (!id %in% q$question_id) {
      stop("[AR] the review queue does not carry ", id, ". Arkansas's ",
           "unstated-form question is the largest in this project in dollars ",
           "and an undisclosed one is worse than an open one (§0.4).",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' NOTHING WAS PROMOTED, and these are the five names that invite it
ar_assert_nothing_promoted <- function(rows = NULL) {
  if (is.null(rows)) rows <- ar_award_rows()
  for (nm in AR_NOT_PROMOTED) {
    got <- rows[rows$awardee == nm, ]
    if (!nrow(got)) {
      stop("[AR] ", nm, " is no longer in the award file at all.",
           call. = FALSE)
    }
    if (any(got$distributed_to_hospital != "No")) {
      stop("[AR] ", nm, " has been promoted to a hospital dollar. It reads as ",
           "a hospital to anyone who knows Arkansas AND THE AWARD LIST STATES ",
           "NO FORM FOR IT -- which is exactly the §0.4 failure this project ",
           "exists to avoid. It belongs in the review queue, not in the ",
           "headline.", call. = FALSE)
    }
  }
  part <- rhtp_hospital_dollar_partition(rows)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  if (nrow(named) != 1L || named$rows != 9L ||
      abs(named$dollars - 21792687.96) > 0.5) {
    stop("[AR] the named-hospital bucket is no longer 9 rows / ",
         ar_money(21792687.96), ": got ",
         if (nrow(named)) paste(named$rows, "rows /", ar_money(named$dollars))
         else "no bucket at all", call. = FALSE)
  }
  invisible(TRUE)
}


# -- probe --------------------------------------------------------------------

#' LIVE: has RISE AR or HEART awarded?
#'
#' Compares a CONTENT digest, not a file digest, and the reason is measured
#' rather than assumed. `arkansasrhtp.com` stamps a
#' `wp_block_styles_on_demand_placeholder:<13 hex>` token into an inline
#' `<style>` body, derived from the render TIMESTAMP -- so two fetches ten
#' seconds apart are BYTE-IDENTICAL while a copy thirty minutes earlier
#' differs, at exactly the same byte length. A back-to-back pair is therefore
#' GUARANTEED to report the digest stable (session 34's California lesson, and
#' this is the second time in this repository that the failing pair was in
#' hand). A byte-count check passes it too, because the token is fixed-length.
#' `ar_reduce_html()` discards `<style>` bodies, so the content digest absorbs
#' it.
#'
#' AND THE TRIPWIRES RUN AGAINST THE LIVE BYTES, not the archive (session 25's
#' Indiana lesson): `--validate` reads the committed copy and can only tell you
#' what was true on the day it was taken.
ar_probe <- function() {
  if (!exists("ar_probe", mode = "function")) {
    stop("[AR] ar_probe() is absent.", call. = FALSE)
  }
  message("[AR] --probe: re-reading ", length(AR_WATCHED),
          " pages LIVE and running the award tripwires against them.")
  out <- purrr::map_dfr(seq_along(AR_WATCHED), function(i) {
    key <- AR_WATCHED[i]
    if (i > 1L) Sys.sleep(AR_HOST_THROTTLE_S)
    served <- ar_get(ar_source(key, "url"), paste0("live:", key))
    txt <- rawToChar(served[served != as.raw(0)])
    Encoding(txt) <- "UTF-8"
    live_content <- ar_content_digest(key, txt)
    tibble::tibble(
      key = key,
      live_bytes = length(served),
      archived_bytes = file.info(ar_path(key))$size,
      live_file_sha = digest::digest(served, algo = "sha256"),
      archived_file_sha = digest::digest(file = ar_path(key), algo = "sha256"),
      live_content_sha = live_content,
      archived_content_sha = ar_content_digest(key),
      content_changed = live_content != ar_content_digest(key),
      html = txt
    )
  })

  for (i in seq_len(nrow(out))) {
    cat(sprintf("  %-10s %s   file digest %s   content digest %s\n",
                out$key[i],
                if (out$content_changed[i]) "CHANGED " else "UNCHANGED",
                if (out$live_file_sha[i] == out$archived_file_sha[i]) "same" else "MOVED",
                if (out$content_changed[i]) "MOVED" else "same"))
  }

  home_html <- out$html[out$key == "home"]
  ar_assert_award_index(html = home_html)
  ar_assert_two_initiatives_remain(html = NULL)
  # The award-list link count, on the LIVE home page, is the signal: a second
  # one means RISE AR or HEART has published a roster.
  n_links <- stringr::str_count(ar_html_text("home", home_html),
                                stringr::fixed(AR_ROSTER_LINK_TEXT))
  cat(sprintf("\n  award-list links on the LIVE home page: %d (expected 1)\n",
              n_links))
  if (any(out$content_changed)) {
    cat("\n  CONTENT CHANGED on: ",
        paste(out$key[out$content_changed], collapse = ", "),
        "\n  Re-fetch and re-read before trusting the committed figures:\n",
        "    Rscript R/03ai_ar_year1_awardees.R --fetch --force && --validate\n",
        sep = "")
  } else {
    cat("\n  All watched pages UNCHANGED. RISE AR and HEART have still",
        "published no roster.\n")
  }
  invisible(out %>% dplyr::select(-"html"))
}


# -- assertions ---------------------------------------------------------------

ar_assert_all <- function(strict_footer = FALSE) {
  ar_assert_line_model_merges()
  ar_assert_reconciles()
  ar_assert_programme_provenance()
  ar_assert_after_noa()
  ar_assert_footer_is_the_allotment(strict = strict_footer)
  ar_assert_roster_has_no_footer()
  ar_assert_award_index()
  ar_assert_initiative_pages_cannot_tell()
  ar_assert_two_initiatives_remain()
  ar_assert_partial_year()
  ar_assert_eligible_class()
  ar_assert_split_amount_node()
  ar_assert_release_spellings()
  ar_assert_projects_reconcile()
  ar_assert_two_spellings_classify_differently()
  rows <- ar_award_rows()
  ar_assert_organisation_total_not_summable(rows)
  ar_assert_form_not_stated_queued(rows)
  ar_assert_nothing_promoted(rows)
  invisible(rows)
}


# -- build --------------------------------------------------------------------

ar_build <- function() {
  rows <- ar_assert_all()
  readr::write_csv(rows, AR_OUT_CSV, na = "")
  message("[AR] wrote ", AR_OUT_CSV, " (", nrow(rows), " rows)")

  proj <- ar_project_rows()
  readr::write_csv(proj, AR_PROJECTS_CSV, na = "")
  message("[AR] wrote ", AR_PROJECTS_CSV, " (", nrow(proj), " rows)")

  st <- ar_status_table()
  if ("amount" %in% names(st)) {
    stop("[AR] the status table has grown an `amount` column. Its pool ",
         "figures live in `initiative_awarded_total` precisely so that ",
         "nothing summed out of this table can be read as a per-recipient ",
         "amount (Texas's device).", call. = FALSE)
  }
  readr::write_csv(st, AR_STATUS_CSV, na = "")
  message("[AR] wrote ", AR_STATUS_CSV, " (", nrow(st), " rows)")

  disp <- ar_disposition()
  readr::write_csv(disp, AR_DISPOSITION_CSV, na = "")
  message("[AR] wrote ", AR_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  invisible(rows)
}

ar_report <- function() {
  rows <- ar_award_rows()
  proj <- ar_projects_joined()
  part <- rhtp_hospital_dollar_partition(rows)
  cat("\nARKANSAS -- RHTP Year 1 (THRIVE and PACT)\n")
  cat(strrep("-", 78), "\n")
  cat("  THREE COUNTS, AND NONE OF THEM IS THE OTHERS\n")
  cat(sprintf("    %2d organisations   -- DF&A's award list\n",
              dplyr::n_distinct(rows$awardee)))
  cat(sprintf("    %2d award actions   -- organisation x initiative, the grain PRICED\n",
              nrow(rows)))
  cat(sprintf("    %2d project awards  -- the Governor's count, the grain DESCRIBED\n",
              nrow(proj)))
  cat(sprintf("\n  AWARDED  %s  (%.1f%% of the %s allotment)\n",
              ar_money(sum(rows$amount)),
              100 * sum(rows$amount) / AR_ALLOTMENT, ar_money(AR_ALLOTMENT)))
  cat(sprintf("    THRIVE %s   PACT %s\n",
              ar_money(sum(rows$amount[rows$award_pool == "THRIVE"])),
              ar_money(sum(rows$amount[rows$award_pool == "PACT"]))))
  cat("\n  IT IS A PARTIAL YEAR. RISE AR and HEART have not awarded; both\n")
  cat("  NOFOs have CLOSED, neither names an award date, and CMS requires\n")
  cat("  all Year 1 funds obligated by 2026-10-30.\n")

  cat("\n  TWO PUBLISHERS, TWO GRAINS, RECONCILING TO THE CENT\n")
  cat(sprintf("    award list `Total:` row   %s / %s / %s\n",
              ar_money(AR_TOTAL_THRIVE), ar_money(AR_TOTAL_PACT),
              ar_money(AR_TOTAL_YR1)))
  cat(sprintf("    the Governor's 50 projects %s / %s / %s\n",
              ar_money(sum(proj$amount[proj$pool == "THRIVE"])),
              ar_money(sum(proj$amount[proj$pool == "PACT"])),
              ar_money(sum(proj$amount))))

  cat("\n  HOSPITAL DOLLARS\n")
  for (i in seq_len(nrow(part))) {
    cat(sprintf("    %-24s rows = %3d   dollars = %s\n",
                part$bucket[i], part$rows[i], ar_money(part$dollars[i])))
  }

  fb <- rows[rows$recipient_type == "NONPROFIT_CBO" &
               rows$determination_confidence == "LOW", ]
  orgs <- dplyr::distinct(fb, .data$awardee, .data$organisation_award_total)
  cat("\n  THE UNSTATED-FORM QUESTION -- THE NINTH, AND THE LARGEST IN DOLLARS\n")
  cat(sprintf("    %d organisations / %d award rows / %s  (%.1f%% of the round)\n",
              nrow(orgs), nrow(fb), ar_money(sum(orgs$organisation_award_total)),
              100 * sum(orgs$organisation_award_total) / AR_TOTAL_YR1))
  cat("    ONE-DIRECTIONAL: every one is already `No`, so the floor above is a\n")
  cat(sprintf("    genuine floor and %s a genuine ceiling.\n",
              ar_money(21792687.96 + sum(orgs$organisation_award_total))))
  cat("    It runs strongly UPWARD, and NOTHING WAS PROMOTED (§0.4):\n")
  top <- orgs %>% dplyr::arrange(dplyr::desc(.data$organisation_award_total)) %>%
    head(6)
  for (i in seq_len(nrow(top))) {
    cat(sprintf("      %-46s %s\n", top$awardee[i],
                ar_money(top$organisation_award_total[i])))
  }
  cat("\n  ARKANSAS RURAL HEALTH PARTNERSHIP IS A SEPARATE QUESTION AGAIN\n")
  cat(sprintf("    %s -- a hospital CONSORTIUM on this pipeline's\n",
              ar_money(rows$organisation_award_total[
                rows$awardee == AR_CONSORTIUM][1])))
  cat("    knowledge and NOT on the document's. §10.2's association row turns\n")
  cat("    on what the source says the money DOES, and the award list is\n")
  cat("    silent. Queued as AR_ARHP_CONSORTIUM_FLOW.\n")
  invisible(rows)
}


# -- CLI ----------------------------------------------------------------------

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    ar_fetch(force = "--force" %in% args)
  } else if ("--validate" %in% args) {
    ar_assert_all()
    message("[AR] all assertions pass.")
  } else if ("--build" %in% args) {
    ar_build()
  } else if ("--probe" %in% args) {
    ar_probe()
  } else if ("--report" %in% args) {
    ar_report()
  } else {
    cat("usage: Rscript R/03ai_ar_year1_awardees.R",
        "[--fetch [--force] | --validate | --build | --probe | --report]\n")
  }
}

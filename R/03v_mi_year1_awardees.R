# ==============================================================================
# R/03v_mi_year1_awardees.R -- Michigan Year 1 RHTP subrecipients (session 27)
# ==============================================================================
#
# MICHIGAN PUBLISHES A COMPLETE RECIPIENT-LEVEL ROSTER WITH AMOUNTS ON IT, AND
# SAYS SO IN ITS OWN WORDS. MDHHS's programme page: "MDHHS maintains a
# dedicated webpage featuring ALL RHTP Subrecipients". The roster itself:
# "Award notices as of July 10, 2026. Subrecipients are categorized by
# initiative and fund and listed alphabetically."
#
#   139 award actions -- $69,883,392 -- 40.4% of Michigan's $173,128,201
#   Five initiative sections, twelve funds, one row per AWARD.
#
# That completeness claim is unlike anything else in this repository. Kansas,
# Nebraska, Oklahoma and Nevada each publish a roster for SOME of their pools
# and are silent about the rest; Michigan states that this page is the whole
# set. `mi_assert_completeness_claim()` reads that sentence every run, because
# the day it stops being on the page every figure here becomes a floor.
#
# THE AMOUNTS ARE NOT FINAL, AND MDHHS SAYS THAT TOO. The asterisk on every
# "Award Amount*" column resolves to: "Award amount is contingent upon review
# by Centers for Medicare & Medicaid Services (CMS) for final approval as a
# requirement of this grant. There may be additional adjustments to both the
# workplan, and budget based on CMS's feedback." So §9.3 splits the two
# questions as it did for Oregon and Maryland: `recipient_confirmed = Yes`
# (these are award notices naming the recipient), `amount_confirmed = No`.
# Unlike Oregon's and Maryland's, though, the contingency here is FEDERAL
# review of a state award, not a state negotiation with the recipient.
#
# -- §6.2, WITH THE FOOTER DOWNGRADED (session 27's own audit) --------------
#
# The session-26 lesson is that the CMS financial-assistance footer covers the
# PUBLICATION, not the programmes described in it, and session 27's audit
# sharpened it: the footer's grammatical SUBJECT says which claim it is
# making. Michigan's roster carries the WEAK form --
#
#   "THIS PROJECT is supported by the Centers for Medicare & Medicaid Services
#    (CMS) ... as part of a financial assistance award totaling
#    $173,128,201.02, with 100 percent funding provided by CMS/HHS."
#
# -- so the footer is used here as CORROBORATION OF THE AMOUNT (it matches the
# §7.1 anchor to the dollar) and NEVER as the evidence that these awards are
# RHTP. That evidence is three programme-scoped sentences, each asserted:
#
#   1. THE ROSTER'S OWN BODY. "Michigan's Rural Health Transformation Program
#      (RHTP) supports innovative, community-driven solutions ... A key
#      component of this work is funding subrecipients" and "This page
#      highlights the organizations that have received RHTP funding".
#   2. THE PROGRAMME PAGE. "The Michigan Department of Health and Human
#      Services (MDHHS) was awarded $173,128,201 for Budget Period 1 (BP1;
#      December 31, 2025-October 30, 2026) by the Centers for Medicare &
#      Medicaid Services (CMS) under the RHT Program."
#   3. THE AWARD RELEASE, 2025-12-30. "MDHHS was awarded $173,128,201 for FY
#      2026 by the Centers for Medicare & Medicaid Services under the Rural
#      Health Transformation Program."
#
# THE DATE HALF. Michigan's CMS Notice of Award is 2025-12-29
# (`cms_state_noa_dates.csv`); MDHHS announced it 2025-12-30, the day after.
# The Workforce for Wellness grant funding opportunities were issued
# 2026-07-08 and the award notices are "as of July 10, 2026" -- both well
# after the state had the money, which is the opposite of Texas's HHS0015180
# (closed 2025-04-24, eight months before its state had anything).
#
# THE NEGATIVE CONTROL, AND IT IS ONE OF RCJ'S OWN CANDIDATES.
# `..._prevention-grants.html` is MDHHS's 2026-06-24 release awarding "nearly
# $3.75 million to 12 organizations" for youth substance-use prevention. Its
# own sub-headline states the funding source: "NEW OPIOID SETTLEMENT-FUNDED
# GRANTS support 12 organizations". The words "Rural Health Transformation",
# "RHTP" and even "rural" appear ZERO times in it. RCJ files eight of those
# twelve organisations as Michigan RHTP Tier 3 candidates.
# `mi_assert_non_rhtp_control()` pins both halves -- the opioid-settlement
# sentence and the absence of any RHTP mention.
#
# THE POSITIVE CONTROL. It is the completeness claim above, read as a
# tripwire in both directions: `mi_assert_roster_sections()` requires exactly
# the five initiative sections this file parses, so a sixth appearing fails
# the build (Michigan has published a pool this file does not carry) and one
# disappearing fails it too (a redesign that renamed them would otherwise turn
# every future run silently green).
#
# -- §0.1 -- WHAT RCJ GOT WRONG, AND IT IS A SHAPE THIS PROJECT HAD NOT MET --
#
# RCJ held 31 Michigan Tier 3 candidates on the 2026-08-27 pull. They
# decomposed exactly as below. SESSION 62 (pull 2026-09-24): 149 candidates.
# RCJ WITHDREW the 14 and the 8, now carries the roster ONE ROW PER AWARD (132
# rows, 131 matching the file on name AND amount), and adds five documents'
# worth of rows including South Dakota's Rural Strong round (WRONG_STATE) and
# two LEO awards that are on the LIVE roster and NOT in this file. See
# mi_disposition_table() for the current reading.
#
#   14  real awards -- but ONE ROW PER ORGANISATION where MDHHS publishes one
#       row per AWARD. Five organisations hold more than one award and RCJ
#       kept only one of each, so its 14 rows carry $19,484,032 against the
#       $27,317,365 those same organisations actually hold. IT DEFLATES BY
#       $7,833,333, and the largest single loss is the Michigan Center for
#       Rural Health: RCJ $3,000,000, MDHHS five awards totalling $7,275,000.
#       This is Kansas's Greeley County defect -- RCJ keeping one of a
#       recipient's two awards -- at five times the scale and in a state where
#       the roster is the only place the second award exists.
#    9  BUDGET NARRATIVE line items (Oklahoma's defect): planning figures from
#       "State Of Michigan RHTP Budget Narrative", four of whose names later
#       appear as real awardees at DIFFERENT amounts. Tier 2.
#    8  OPIOID SETTLEMENT grants (Nevada's defect): the negative control above.
#
# So an extractor built from the candidate list would have published
# $19.5M as Michigan's RHTP subawards -- 28% of what Michigan has actually
# awarded -- with $2.2M of opioid settlement money mixed into it.
#
# THE ROUTE IN WAS `/api/v1/activity`, FOR THE FOURTH STATE RUNNING.
# `state_source_url` is NA on all 31 Michigan Tier 3 records;
# `stage2_state_sources.rds` holds the roster URL. Oregon, Oklahoma, Nevada,
# Michigan.
#
# -- THE HOST, AND A DOCUMENTED DEPARTURE FROM SESSION 10'S RULE -------------
#
# `www.michigan.gov` is fronted by Akamai and REFUSES EVERY IDENTIFYING
# USER-AGENT. This was probed rather than assumed:
#
#   "AHA-RHTP-Tracker/1.0 (research; +https://www.aha.org)"          403
#   "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/1.0; +https://...)"   403
#   a full Chrome UA with "AHA-RHTP-Tracker/1.0" appended            403
#   "Mozilla/5.0"                                                    200
#   https://www.michigan.gov/robots.txt                              403
#
# It is a denylist on identifying tokens, not an allowlist on browsers, and
# because robots.txt is itself refused there is no crawler policy on offer and
# none is being declined. Session 10 settled this question for medicaid.gov
# the other way -- there the "+url" form was what got through and a spoofed
# browser UA was refused, and the note reads "identifying honestly is the fix,
# not a workaround". Michigan inverts it: no honest identifier works.
#
# THIS FILE THEREFORE USES A BARE `Mozilla/5.0` FOR michigan.gov ONLY, as an
# explicit decision taken with the owner rather than a silent workaround. It
# is recorded here, in `data/evidence/MI/MANIFEST.txt`, and in CLAUDE.md §3
# beside session 10's rule. `mha.org` and `cms.gov` are fetched with the
# project's honest agent and are asserted to be, so the exception cannot
# quietly spread to hosts that never needed it.
#
# -- WHAT MICHIGAN DOES NOT SHOW: HOSPITALS ---------------------------------
#
# 139 awards, $69,883,392, and ONE named-hospital award action -- $76,924.
# Michigan's recipients are local health departments, community action
# agencies, FQHCs, Area Agencies on Aging, universities, tribal governments,
# and statewide intermediaries. Its rural hospital money, so far as MDHHS has
# published it, runs through the MICHIGAN HEALTH & HOSPITAL ASSOCIATION --
# which is §10.2's association row and NOT a hospital, and is the single
# largest classification trap in the file. See `MI_RECIPIENT_TYPE_OVERRIDES`.
#
# CLI:
#   Rscript R/03v_mi_year1_awardees.R --fetch [--force]
#   Rscript R/03v_mi_year1_awardees.R --validate
#   Rscript R/03v_mi_year1_awardees.R --build
#   Rscript R/03v_mi_year1_awardees.R --report
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
  library(readr)
  library(tidyr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

MI_EVIDENCE_DIR <- here::here("data", "evidence", "MI")
MI_OUTPUT_CSV   <- here::here("data", "reference", "mi_year1_awardees.csv")
MI_DISPOSITION_CSV <- here::here("data", "reference",
                                 "mi_rcj_candidate_disposition.csv")
MI_OUTPUT_XLSX  <- here::here("MI_year1_awardees.xlsx")
MI_HOST_THROTTLE_S <- 2

# The project's honest agent, used for every host that accepts it.
MI_USER_AGENT <- "AHA-RHTP-Tracker/1.0 (research; +https://www.aha.org)"
# michigan.gov ONLY. See the header block: every identifying agent is refused
# with HTTP 403, including the RFC crawler convention, and robots.txt is 403
# too. Recorded as an exception, never as a default.
MI_MICHIGAN_GOV_USER_AGENT <- "Mozilla/5.0"

MI_ALLOTMENT_SOURCE <- here::here("data", "reference", "cms_fy2026_allotments.csv")
MI_NOA_SOURCE       <- here::here("data", "reference", "cms_state_noa_dates.csv")

MI_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[0-9A-Za-z_-]{30,}",
  aws_key        = "AKIA[0-9A-Z]{16}"
)


# -- what Michigan itself states ----------------------------------------------

# Every figure here is a QUOTE from an archived Michigan document, asserted
# against the parse. Nothing in this list is derived by this file.
MI_STATED <- list(
  cms_footer_amount   = 173128201.02,
  award_release_amount = 173128201,
  roster_as_of        = as.Date("2026-07-10"),
  noa_announced       = as.Date("2025-12-30"),
  workforce_gfo_date  = as.Date("2026-07-08"),
  workforce_gfo_pool  = 34231500,
  mha_own_footer      = 8625000,
  prevention_total    = 3750000,
  prevention_orgs     = 12L
)

# The roster's five accordion sections, in the order MDHHS prints them. This
# is the POSITIVE CONTROL and a tripwire in both directions: a sixth section
# means Michigan has published a pool this file does not carry, and a missing
# one means a redesign has moved the roster out from under the parser.
MI_SECTIONS <- c(
  "Interoperability in Action Initiative",
  "Transforming Rural Health Through Partnerships Initiative",
  "Workforce for Wellness Initiative",
  "Care Closer to Home Initiative",
  "Tribal Government"
)

# MDHHS's own completeness claim, and the contingency on every amount.
MI_COMPLETENESS_SENTENCE <- "MDHHS maintains a dedicated webpage featuring all RHTP Subrecipients"
MI_ROSTER_ASOF_SENTENCE  <- "Award notices as of July 10, 2026"
MI_CONTINGENCY_SENTENCE  <- paste(
  "Award amount is contingent upon review by Centers for Medicare & Medicaid",
  "Services (CMS) for final approval as a requirement of this grant")

# The three PROGRAMME-SCOPED sentences that establish RHTP status. The footer
# is deliberately not among them (session 27's audit).
MI_ROSTER_PROGRAM_SENTENCE <- "This page highlights the organizations that have received RHTP funding"
MI_PROGRAM_PAGE_SENTENCE   <- paste(
  "was awarded $173,128,201 for Budget Period 1")
MI_RELEASE_SENTENCE <- paste(
  "was awarded $173,128,201 for FY 2026 by the Centers for Medicare & Medicaid",
  "Services under the Rural Health Transformation Program")

# The publication-scoped footer. Used ONLY to corroborate the amount.
MI_CMS_FOOTER <- "financial assistance award totaling $173,128,201.02"
MI_FOOTER_SUBJECT <- "This project is supported by the Centers for Medicare & Medicaid Services"

# THE §6.2 NEGATIVE CONTROL, both halves.
MI_NON_RHTP_SENTENCE <- "New opioid settlement-funded grants support 12 organizations"
MI_NON_RHTP_ABSENT   <- c("Rural Health Transformation", "RHTP")

MI_FORM_NOT_STATED_QUESTION <- "MI_RECIPIENT_FORM_NOT_STATED"


# -- sources ------------------------------------------------------------------

MI_BASE <- "https://www.michigan.gov"
MI_RHTP <- paste0(MI_BASE, "/mdhhs/assistance-programs/medicaid/rural-health-transformation-program")

MI_SOURCES <- tibble::tribble(
  ~key, ~file, ~url, ~agent,
  # THE ROSTER. Five tables, 139 named awards WITH amounts.
  "roster", "2026-09-01_mi_rhtp_subrecipients.html",
  paste0(MI_RHTP, "/rhtp-subrecipients"), "MICHIGAN_GOV",
  # The programme page: the completeness claim, the BP1 award sentence, and
  # the link to the roster.
  "program", "2026-09-01_mi_rhtp_program_page.html", MI_RHTP, "MICHIGAN_GOV",
  # MDHHS's own announcement of the CMS award, the day after the NOA.
  "award_release", "2025-12-30_mi_mdhhs_rht_funding_award.html",
  paste0(MI_BASE, "/mdhhs/inside-mdhhs/newsroom/2025/12/30/rht-funding"), "MICHIGAN_GOV",
  # A solicitation issued well after the NOA -- the §6.2 date half.
  "workforce_gfo", "2026-07-08_mi_mdhhs_workforce_gfo.html",
  paste0(MI_BASE, "/mdhhs/inside-mdhhs/newsroom/2026/07/08/workforce-gfo"), "MICHIGAN_GOV",
  # THE §6.2 NEGATIVE CONTROL: opioid settlement money, eight of whose twelve
  # recipients RCJ files as Michigan RHTP Tier 3 candidates.
  "prevention", "2026-06-24_mi_mdhhs_prevention_grants.html",
  paste0(MI_BASE, "/mdhhs/inside-mdhhs/newsroom/2026/06/24/prevention-grants"), "MICHIGAN_GOV",
  # The Michigan Health & Hospital Association's own RHTP page. It is the
  # largest subrecipient in the file and it states its OWN award total in its
  # own footer -- $8.625 million, which is MDHHS's two MHA rows to the dollar.
  "mha", "2026-09-01_mi_mha_center_of_rural_excellence.html",
  "https://www.mha.org/mha-center-of-rural-excellence/rural-health-transformation-program/", "HONEST",
  # CMS's own state spotlight: "Funding FY26 $173M", an independent publisher.
  "cms_spotlights", "2026-09-01_cms_rhtp_50_state_spotlights.pdf",
  "https://www.cms.gov/files/document/rural-health-transformation-50-state-spotlights.pdf", "HONEST"
)


# -- fetch --------------------------------------------------------------------

mi_source <- function(key, field) {
  row <- MI_SOURCES[MI_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[MI] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

mi_path <- function(key) file.path(MI_EVIDENCE_DIR, mi_source(key, "file"))

#' The agent for a source, and the assertion that the exception is scoped.
#'
#' The bare `Mozilla/5.0` exists for michigan.gov and nothing else. If a source
#' row on another host ever asks for it, this refuses -- which is what stops a
#' documented one-host departure becoming the file's default.
mi_agent_for <- function(key) {
  agent <- mi_source(key, "agent")
  url   <- mi_source(key, "url")
  if (identical(agent, "MICHIGAN_GOV")) {
    if (!startsWith(url, MI_BASE)) {
      stop("[MI] refusing the anonymous user-agent for ", url,
           ": it is scoped to www.michigan.gov, which refuses every ",
           "identifying agent (see the header block).", call. = FALSE)
    }
    return(MI_MICHIGAN_GOV_USER_AGENT)
  }
  if (startsWith(url, MI_BASE)) {
    stop("[MI] ", url, " is on michigan.gov and would be fetched with the ",
         "honest agent, which that host answers with HTTP 403.", call. = FALSE)
  }
  MI_USER_AGENT
}

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
mi_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(MI_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, MI_CREDENTIAL_SHAPES[[nm]])) {
      stop("[MI] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

mi_get <- function(key) {
  url <- mi_source(key, "url")
  message("[MI] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(mi_agent_for(key)), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[MI] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  mi_assert_credential_free(served, mi_source(key, "file"))
  served
}

mi_fetch <- function(force = FALSE) {
  dir.create(MI_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(MI_SOURCES)), function(i) {
    src  <- MI_SOURCES[i, ]
    dest <- file.path(MI_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[MI] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(MI_HOST_THROTTLE_S)
      writeBin(mi_get(src$key), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url, agent = src$agent,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  mi_write_manifest(entries)
  entries
}

mi_write_manifest <- function(entries) {
  path <- file.path(MI_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Michigan -- RHTP Year 1: MDHHS's RHTP Subrecipients roster (139 named",
    "awards WITH amounts), the programme page carrying its completeness claim,",
    "the 2025-12-30 award release, a post-NOA solicitation, MHA's own RHTP",
    "page, CMS's 50-state spotlights, and the §6.2 NEGATIVE CONTROL.",
    "Archived by R/03v_mi_year1_awardees.R --fetch",
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch here and finds nothing, so",
    "there is no reduction to explain and the pages are whole.",
    "",
    "TWO USER-AGENTS, AND THE SECOND IS A DOCUMENTED EXCEPTION.",
    paste0("  HONEST        ", MI_USER_AGENT),
    paste0("  MICHIGAN_GOV  ", MI_MICHIGAN_GOV_USER_AGENT),
    "",
    "www.michigan.gov is fronted by Akamai and REFUSES EVERY IDENTIFYING",
    "USER-AGENT. Probed, not assumed: the project's honest agent 403, the RFC",
    "crawler convention 'Mozilla/5.0 (compatible; AHA-RHTP-Tracker/1.0;",
    "+https://www.aha.org)' 403, a full Chrome UA with the tracker token",
    "appended 403, bare 'Mozilla/5.0' 200 -- and https://www.michigan.gov/",
    "robots.txt is ITSELF 403, so there is no crawler policy on offer and none",
    "is being declined. It is a denylist on identifying tokens, not an",
    "allowlist on browsers. Session 10 settled the same question for",
    "medicaid.gov the other way, where the '+url' form was what got through;",
    "Michigan inverts it. The bare agent is used for michigan.gov ONLY and",
    "`mi_agent_for()` refuses to use it on any other host, so the exception",
    "cannot quietly spread. mha.org and cms.gov take the honest agent.",
    "",
    "THE ROSTER IS `..._mi_rhtp_subrecipients.html`. Five accordion sections,",
    "one per initiative, each a Subrecipient Organization / Award Amount* /",
    "Fund table: 20 + 71 + 19 + 16 + 13 = 139 award actions and $69,883,392.",
    "EVERY HEADER ROW IS MARKED UP WITH <td>, NOT <th>, on all five tables --",
    "session 10's CMS defect, five times over on one page. Unpromoted, the",
    "parser reads five organisations called 'Subrecipient Organization'.",
    "",
    "MDHHS CLAIMS THIS ROSTER IS COMPLETE, which no other state in this",
    "repository does: the programme page reads 'MDHHS maintains a dedicated",
    "webpage featuring all RHTP Subrecipients'. The roster is dated 'Award",
    "notices as of July 10, 2026'. Both sentences are asserted every run,",
    "because the day the completeness claim goes, every figure here becomes a",
    "floor rather than a total.",
    "",
    "THE AMOUNTS ARE CONTINGENT AND MDHHS SAYS SO. The asterisk on every",
    "'Award Amount*' column resolves to 'Award amount is contingent upon",
    "review by Centers for Medicare & Medicaid Services (CMS) for final",
    "approval'. So all 139 rows are amount_confirmed = No.",
    "",
    "`..._mdhhs_prevention_grants.html` IS THE §6.2 NEGATIVE CONTROL AND IS",
    "NOT EXTRACTED FROM. Its own sub-headline states the funding source --",
    "'New opioid settlement-funded grants support 12 organizations' -- and the",
    "words 'Rural Health Transformation', 'RHTP' and 'rural' appear ZERO times",
    "in it. RCJ files eight of those twelve organisations as Michigan RHTP",
    "Tier 3 candidates.",
    "",
    "THE FOOTER IS NOT THE PROVENANCE HERE. The roster carries the WEAK form,",
    "'This PROJECT is supported by ... a financial assistance award totaling",
    "$173,128,201.02' -- the publication-scoped subject that session 26",
    "disproved in Nevada and session 27 audited across five states. It is used",
    "to corroborate the AMOUNT against the §7.1 anchor and never as the",
    "evidence that these awards are RHTP; three programme-scoped sentences do",
    "that, and each is asserted separately.",
    "",
    paste0("Fetched: ", Sys.Date()),
    "",
    sprintf("%-52s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 52 + 12 + 64)
  ), path)
  cat(sprintf("%-52s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs and agents\n", file = path, append = TRUE)
  cat(sprintf("  %-15s %-13s %s", entries$key, entries$agent, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

mi_read_text <- function(key) {
  path <- mi_path(key)
  if (!file.exists(path)) {
    stop("[MI] missing archive: ", path,
         "\n  Run: Rscript R/03v_mi_year1_awardees.R --fetch", call. = FALSE)
  }
  raw <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt
}

mi_html_doc <- function(key) xml2::read_html(mi_read_text(key))

#' A page's <main> text, squished. Assertions read this and never raw HTML:
#' MDHHS writes its sentences with markup and &nbsp; inside them.
mi_html_text <- function(key) {
  doc <- mi_html_doc(key)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  main <- xml2::xml_find_first(doc, "//main")
  node <- if (inherits(main, "xml_missing")) doc else main
  stringr::str_squish(xml2::xml_text(node))
}

mi_pdf_text <- local({
  cache <- new.env(parent = emptyenv())
  function(key) {
    if (is.null(cache[[key]])) {
      source(here::here("R", "utils_pdf_text.R"), local = TRUE)
      cache[[key]] <- stringr::str_squish(
        paste(rhtp_pdf_text(mi_path(key)), collapse = " "))
    }
    cache[[key]]
  }
})


# -- the roster parse ---------------------------------------------------------

#' Promote a `<td>` header row -- session 10's rule, on all five tables
#'
#' MDHHS marks every one of the roster's header rows up with `<td>`, so
#' `html_table()` names the columns X1..X3 and the header lands in the data.
#' Unpromoted, Michigan reports 144 awards, five of them to an organisation
#' called "Subrecipient Organization" for an amount of "Award Amount*".
#'
#' Promotion happens ONLY when the candidate row resolves STRICTLY MORE columns
#' by synonym than the current header does -- session 10's own rule, which is
#' what makes it impossible for this to turn a working parse into a worse one.
MI_COLUMN_SYNONYMS <- list(
  awardee = c("subrecipient organization", "subrecipient", "organization"),
  amount  = c("award amount*", "award amount", "amount"),
  fund    = c("fund", "funding opportunity", "program")
)

mi_resolve_columns <- function(headers) {
  headers <- tolower(stringr::str_squish(headers))
  purrr::map_chr(names(MI_COLUMN_SYNONYMS), function(field) {
    hit <- which(headers %in% MI_COLUMN_SYNONYMS[[field]])
    if (length(hit) == 1L) as.character(hit) else NA_character_
  }) %>% stats::setNames(names(MI_COLUMN_SYNONYMS))
}

mi_n_resolved <- function(headers) sum(!is.na(mi_resolve_columns(headers)))

mi_promote_header <- function(tbl) {
  if (nrow(tbl) < 1L) return(tbl)
  now  <- mi_n_resolved(names(tbl))
  cand <- as.character(unlist(tbl[1, ], use.names = FALSE))
  if (mi_n_resolved(cand) > now) {
    names(tbl) <- cand
    tbl <- tbl[-1, , drop = FALSE]
  }
  tbl
}

#' The five roster tables, each tied to the heading that precedes it
#'
#' The section is read from the DOM, never from table order: MDHHS could
#' reorder the accordion without changing a single award, and a positional
#' mapping would silently relabel 139 rows.
mi_roster_tables <- function() {
  doc <- mi_html_doc("roster")
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  main <- xml2::xml_find_first(doc, "//main")
  node <- if (inherits(main, "xml_missing")) doc else main

  tables <- xml2::xml_find_all(node, ".//table")
  if (length(tables) != length(MI_SECTIONS)) {
    stop("[MI] the roster has ", length(tables), " tables; expected ",
         length(MI_SECTIONS), ". Michigan has published a pool this file does ",
         "not carry, or the page has been redesigned. Read it before ",
         "changing this number.", call. = FALSE)
  }

  # THE SECTION IS READ FROM DOCUMENT ORDER, NOT FROM TABLE ORDER. MDHHS marks
  # each heading up as <p><strong>...</strong></p> immediately before its
  # table's container, so the nodes are walked in document order and each table
  # takes the most recent preceding heading that names a known section. A
  # positional mapping would silently relabel 139 rows if MDHHS ever reordered
  # the accordion, and a text-position mapping is worse: two sections share a
  # first awardee ("Benzie-Leelanau District Health Department" opens both the
  # Workforce and Partnerships tables), so locating the first cell in the page
  # text finds the WRONG table.
  ordered <- xml2::xml_find_all(node, ".//table | .//strong | .//h2 | .//h3")
  section_of <- rep(NA_character_, length(tables))
  current <- NA_character_
  t_i <- 0L
  for (n in ordered) {
    if (identical(xml2::xml_name(n), "table")) {
      t_i <- t_i + 1L
      if (t_i <= length(section_of)) section_of[t_i] <- current
    } else {
      lab <- stringr::str_squish(xml2::xml_text(n))
      if (lab %in% MI_SECTIONS) current <- lab
    }
  }
  if (any(is.na(section_of))) {
    stop("[MI] ", sum(is.na(section_of)), " roster table(s) sit under no known ",
         "initiative heading. MDHHS has renamed or reordered the accordion.",
         call. = FALSE)
  }

  purrr::map_dfr(seq_along(tables), function(i) {
    tbl <- rvest::html_table(tables[[i]], header = FALSE)
    tbl <- mi_promote_header(tbl)
    cols <- mi_resolve_columns(names(tbl))
    if (any(is.na(cols))) {
      stop("[MI] roster table ", i, " does not resolve all three columns by ",
           "synonym; headers are: ", paste(names(tbl), collapse = " | "),
           call. = FALSE)
    }
    tibble::tibble(
      initiative  = section_of[i],
      awardee     = stringr::str_squish(tbl[[as.integer(cols[["awardee"]])]]),
      amount_raw  = stringr::str_squish(tbl[[as.integer(cols[["amount"]])]]),
      award_fund  = stringr::str_squish(tbl[[as.integer(cols[["fund"]])]])
    )
  })
}

#' Parse "$1,663,636" and REFUSE anything else
#'
#' Michigan publishes an amount on every row, which is what separates it from
#' Nevada. If a cell ever stops being a plain dollar figure -- a range, a
#' "TBD", a footnote marker -- that is a change in what the state publishes and
#' the file must be re-read, not coerced.
mi_parse_amount <- function(x) {
  m <- stringr::str_match(x, "^\\$([0-9][0-9,]*)(?:\\.([0-9]{2}))?$")
  bad <- is.na(m[, 1])
  if (any(bad)) {
    stop("[MI] ", sum(bad), " award amount(s) are not plain dollar figures: ",
         paste(utils::head(x[bad], 5), collapse = " | "),
         ". Michigan has changed how it publishes amounts; read the page.",
         call. = FALSE)
  }
  as.numeric(gsub(",", "", m[, 2])) +
    ifelse(is.na(m[, 3]), 0, as.numeric(m[, 3]) / 100)
}


# -- §8 / §10.2: the overrides, and why each exists ---------------------------

# THE MICHIGAN HEALTH & HOSPITAL ASSOCIATION IS THE LARGEST TRAP IN THIS FILE.
# The §8 name rule sees "Hospital" in "Michigan Health and Hospital
# Association (MHA)" and returns HOSPITAL_OR_SYSTEM, which short-circuits to
# DIRECT / Yes -- publishing $8,625,000 of Michigan's $69.9M as direct
# hospital dollars on a name match. MHA is a TRADE ASSOCIATION. §10.2's own
# row types a hospital association NONPROFIT_CBO, which is what Alaska (AHHA)
# and Illinois (ICAHN) already carry, and Nevada met the same trap twice in
# session 26 with two hospital FOUNDATIONS.
#
# And the association branch's SECOND clause is not met either. §10.2 allows
# `PASS_THROUGH_DESIGNATED` + `Yes` only where the source shows the funds are
# administered TO or ON BEHALF OF member hospitals. Michigan's roster has
# three columns -- Subrecipient, Amount, Fund -- and no project description at
# all, so there is no money-movement sentence anywhere; MHA's own page says
# the Center of Rural Excellence "supports innovative solutions that help
# rural hospitals", which is not a statement that money moves. So MHA lands on
# session 19's terminal branch: PASS_THROUGH_UNRESOLVED + Unclear +
# FLOW_UNRESOLVED_HOSPITAL_AFFILIATED, entering NEITHER bucket of
# rhtp_hospital_dollar_partition(). Silence is not evidence here.
MI_RECIPIENT_TYPE_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~confidence, ~why,
  "Michigan Health and Hospital Association (MHA)", "HOSPITAL_AFFILIATED_ENTITY", "HIGH",
  paste("Michigan's hospital trade association, not a hospital. The §8 name",
        "rule reaches the 'Hospital' token and would return HOSPITAL_OR_SYSTEM",
        "-> DIRECT -> Yes for $8,625,000 (Nevada's foundation trap, session",
        "26). Typed HOSPITAL_AFFILIATED_ENTITY, which since session 19 no",
        "longer short-circuits to DIRECT and must read the source."),
  # §0.3a in a parenthesis. MDHHS annotates two roster rows with the PROJECT,
  # not the recipient's form -- "MyMichigan Health (EMS - Chronic Disease)" --
  # and the §8 activity token then types the recipient EMS_OR_PSAP. MyMichigan
  # Health is a health system; the EMS is what the money does. Judging the
  # recipient (§0.3a) and not being able to determine its form from the roster,
  # this takes §8's standing fallback and goes to the review queue, where the
  # CCN match resolves it. NOTHING WAS PROMOTED (§0.4): the fallback is
  # distributed_to_hospital = No, exactly as EMS_OR_PSAP was.
  "MyMichigan Health (EMS - Chronic Disease)", "NONPROFIT_CBO", "LOW",
  paste("MDHHS's parenthetical is the PROJECT, not the recipient's form; the",
        "§8 activity token would type the recipient EMS_OR_PSAP, which is",
        "§0.3a's error. Form not stated by the source -> §8 fallback."),
  "Northern Lower Regional Center (MidMichigan Health Services)", "NONPROFIT_CBO", "LOW",
  paste("An AHEC regional centre named for its host organisation. The",
        "parenthetical is the host, not the recipient's form.")
)

#' Recipient type, with the roster's own Fund column consulted first
#'
#' MICHIGAN'S `Fund` COLUMN IS AN ORGANISATION-TYPE COLUMN FOR ONE SECTION AND
#' ONLY ONE. The thirteen rows under the heading "Tribal Government" carry
#' "Tribal Government" in the Fund column too, which is MDHHS stating the
#' recipient's form rather than the money's purpose -- so those thirteen are
#' TRIBAL_ORG on the STATE's word (Alaska's and Oregon's rule, and Oklahoma's
#' Choctaw Nation precedent), not on a reading of the name. The §8 name rule
#' reaches only nine of the thirteen; Bay Mills Indian Community, Hannahville
#' Indian Community, Keweenaw Bay Indian Community and Little Traverse Bay
#' Bands of Odawa Indians would otherwise take §8's fallback while the state
#' has plainly said what they are.
mi_recipient_type <- function(awardee, award_fund) {
  base <- rhtp_classify_recipient_type(awardee, "MI")
  out <- tibble::tibble(
    recipient_type = base$recipient_type,
    determination_confidence = base$determination_confidence,
    recipient_type_basis = base$recipient_type_basis,
    recipient_type_source = base$recipient_type
  )
  # 1. The state's own Tribal Government section.
  tribal <- award_fund == "Tribal Government"
  out$recipient_type[tribal] <- "TRIBAL_ORG"
  out$determination_confidence[tribal] <- "HIGH"
  out$recipient_type_basis[tribal] <- paste(
    "MDHHS's own 'Tribal Government' section and Fund column state the",
    "recipient's form; the state classifies its own awardee (§8).")
  # 2. The named overrides.
  for (i in seq_len(nrow(MI_RECIPIENT_TYPE_OVERRIDES))) {
    o <- MI_RECIPIENT_TYPE_OVERRIDES[i, ]
    hit <- awardee == o$awardee
    if (!any(hit)) {
      stop("[MI] override for '", o$awardee, "' matches no roster row. An ",
           "override that matches nothing is a stale claim, not a no-op.",
           call. = FALSE)
    }
    out$recipient_type[hit] <- o$recipient_type
    out$determination_confidence[hit] <- o$confidence
    out$recipient_type_basis[hit] <- o$why
  }
  out
}


# -- assemble -----------------------------------------------------------------

#' The 139 Michigan Year 1 award actions, in the §8 union schema
rhtp_mi_year1_awardees <- function() {
  raw <- mi_roster_tables()
  amount <- mi_parse_amount(raw$amount_raw)

  types <- mi_recipient_type(raw$awardee, raw$award_fund)

  # The description the flow rules read is the state's own Fund name, which is
  # all Michigan publishes about what the money does. It is deliberately NOT
  # the initiative heading: "Care Closer to Home" says nothing about a
  # recipient, and Kansas's session-20 mistake was feeding a POOL name to the
  # classifier and having the in-kind rule fire on a string this file wrote.
  flow <- rhtp_classify_flow(types$recipient_type, raw$award_fund,
                             award_made = TRUE)

  # THE UNION SCHEMA'S LEADING 19 COLUMNS, IN ORDER (§8, test_state_union.R).
  # `ccn`, `aha_id`, `rural_designation` and `reviewer` are empty here for the
  # reason they are empty everywhere: the AHA Annual Survey / CMS Provider of
  # Services extracts are not in the repository (open blocker 5), so no
  # Michigan recipient can be matched to a CCN and no determination here can
  # reach §7's HIGH.
  tibble::tibble(
    state                    = "MI",
    row_no                   = seq_len(nrow(raw)),
    awardee                  = raw$awardee,
    amount                   = amount,
    recipient_type           = types$recipient_type,
    distributed_to_hospital  = flow$distributed_to_hospital,
    note                     = paste0(
      "MDHHS RHTP subrecipient, ", raw$initiative, " -- ", raw$award_fund,
      ". Award notice as of ", format(MI_STATED$roster_as_of, "%Y-%m-%d"),
      "; MDHHS states the amount is contingent on CMS approval."),
    recipient_confirmed      = "Yes",
    # MDHHS: "Award amount is contingent upon review by CMS for final
    # approval." §9.3 splits the two questions -- the recipient is confirmed,
    # the amount is not.
    amount_confirmed         = "No",
    fiscal_year              = "FY2026",
    source_document_title    = "RHTP Subrecipients -- Michigan Department of Health and Human Services",
    state_source_url         = mi_source("roster", "url"),
    validation_source_type   = "NOTICE_OF_AWARD",
    extraction_method        = "DIRECT_TEXT",
    validator                = "AUTO",
    ccn                      = NA_character_,
    aha_id                   = NA_character_,
    rural_designation        = NA_character_,
    reviewer                 = NA_character_,
    recipient_type_source    = types$recipient_type_source,
    determination_confidence = types$determination_confidence,
    flag_reason              = dplyr::case_when(
      types$determination_confidence == "LOW" ~ "RECIPIENT_TYPE_INFERRED",
      TRUE ~ NA_character_),
    award_pool               = raw$award_fund,
    budget_period            = "BP1",
    flow_type                = flow$flow_type,
    hospital_benefiting      = ifelse(flow$flow_type == "IN_KIND_BENEFIT",
                                      "Yes", NA_character_),
    hospital_attribution     = dplyr::case_when(
      flow$distributed_to_hospital == "Yes" &
        types$recipient_type == "HOSPITAL_OR_SYSTEM" ~ "NAMED_HOSPITAL",
      flow$distributed_to_hospital == "Yes" ~ "POOL_UNNAMED_HOSPITALS",
      TRUE ~ "NOT_HOSPITAL"),
    intermediary_name        = ifelse(
      flow$flow_type == "PASS_THROUGH_DESIGNATED", raw$awardee, NA_character_),
    amount_basis             = "STATED_PER_RECIPIENT",
    # Michigan publishes no per-recipient description and no pool total on the
    # roster, so `round_amount` stays EMPTY: there is nothing for it to carry,
    # and populating it would import Georgia's and Nevada's double-counting
    # trap into a file that does not have it.
    round_amount             = NA_real_,
    initiative               = raw$initiative,
    activity_type_raw        = raw$award_fund,
    determination_basis      = paste0(
      types$recipient_type_basis, " ", flow$flow_basis),
    recipient_type_rule      = ifelse(types$determination_confidence == "LOW",
                                      "FALLBACK", "PATTERN"),
    source_archive_path      = file.path("data", "evidence", "MI",
                                         mi_source("roster", "file"))
  ) %>%
    dplyr::mutate(flag_reason = dplyr::case_when(
      !is.na(.data$flag_reason) ~ .data$flag_reason,
      .data$flow_type == "PASS_THROUGH_UNRESOLVED" &
        .data$recipient_type == "HOSPITAL_AFFILIATED_ENTITY" ~
        "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED",
      TRUE ~ NA_character_))
}


# -- assertions ---------------------------------------------------------------

#' §7.1: Michigan's allotment, read from the anchor rather than typed
rhtp_mi_allotment <- function() {
  a <- readr::read_csv(MI_ALLOTMENT_SOURCE, show_col_types = FALSE)
  v <- a$fy2026_allotment[a$state == "MI"]
  if (length(v) != 1L) stop("[MI] no MI row in the §7.1 anchor.", call. = FALSE)
  v
}

rhtp_mi_noa_date <- function() {
  d <- readr::read_csv(MI_NOA_SOURCE, show_col_types = FALSE)
  as.Date(d$noa_date[d$state == "MI"])
}

#' THE PROVENANCE TEST, WITH THE FOOTER DOWNGRADED (session 27)
#'
#' Three PROGRAMME-SCOPED sentences establish that these awards are RHTP. The
#' footer establishes only the amount, and this asserts its weak subject
#' explicitly so nobody later mistakes it for the provenance: Michigan's reads
#' "This PROJECT is supported by", the publication-scoped form that Nevada
#' disproved and that Kansas's REH CAP/RPGP document relies on entirely.
mi_assert_rhtp_funded <- function() {
  roster <- mi_html_text("roster")
  if (!stringr::str_detect(roster, stringr::fixed(MI_ROSTER_PROGRAM_SENTENCE))) {
    stop("[MI] the roster no longer says it lists organizations that have ",
         "received RHTP funding. That sentence -- not the CMS footer -- is ",
         "what makes these awards RHTP (§6.2, session 27's audit).",
         call. = FALSE)
  }
  if (!stringr::str_detect(mi_html_text("program"),
                           stringr::fixed(MI_PROGRAM_PAGE_SENTENCE))) {
    stop("[MI] the programme page no longer states the $173,128,201 Budget ",
         "Period 1 award under the RHT Program.", call. = FALSE)
  }
  if (!stringr::str_detect(mi_html_text("award_release"),
                           stringr::fixed(MI_RELEASE_SENTENCE))) {
    stop("[MI] the 2025-12-30 release no longer states the CMS award under ",
         "the Rural Health Transformation Program.", call. = FALSE)
  }

  # The footer, used for the AMOUNT and labelled as the weak form.
  if (!stringr::str_detect(roster, stringr::fixed(MI_CMS_FOOTER))) {
    stop("[MI] the roster no longer carries the CMS financial-assistance ",
         "figure. It is not this file's provenance, but it is what ties the ",
         "roster to the §7.1 anchor.", call. = FALSE)
  }
  if (!stringr::str_detect(roster, stringr::fixed(MI_FOOTER_SUBJECT))) {
    stop("[MI] the roster's CMS footer no longer reads 'This project is ",
         "supported by'. Its SUBJECT is the point: it is the ",
         "publication-scoped form, which is why this file does not rest on ",
         "it (§6.2, sessions 26-27).", call. = FALSE)
  }
  if (round(MI_STATED$cms_footer_amount) != rhtp_mi_allotment()) {
    stop("[MI] the footer's $", format(MI_STATED$cms_footer_amount, nsmall = 2),
         " does not round to the §7.1 allotment of $",
         format(rhtp_mi_allotment(), big.mark = ","), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' The date half of §6.2 -- Texas's cheapest test
mi_assert_after_noa <- function() {
  noa <- rhtp_mi_noa_date()
  if (MI_STATED$noa_announced <= noa) {
    stop("[MI] MDHHS's award release is dated on or before the NOA.",
         call. = FALSE)
  }
  for (nm in c("workforce_gfo_date", "roster_as_of")) {
    if (MI_STATED[[nm]] <= noa) {
      stop("[MI] ", nm, " is not after Michigan's CMS Notice of Award (",
           noa, "). A solicitation that closed before the state had the money ",
           "cannot have spent it (§6.2, Texas).", call. = FALSE)
    }
  }
  if (!stringr::str_detect(mi_html_text("workforce_gfo"),
                           stringr::fixed("July 08, 2026"))) {
    stop("[MI] the Workforce for Wellness GFO release is no longer dated ",
         "2026-07-08 on its own page.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE §6.2 NEGATIVE CONTROL, both halves
#'
#' A negative nobody re-checks decays into an assumption. This requires the
#' opioid-settlement sentence to still be on MDHHS's own release AND requires
#' that release to still mention RHTP nowhere -- because if MDHHS ever adds an
#' RHTP line to it, eight of RCJ's Michigan candidates stop being disposable
#' and this file is wrong rather than merely stale.
mi_assert_non_rhtp_control <- function() {
  txt <- mi_html_text("prevention")
  if (!stringr::str_detect(txt, stringr::fixed(MI_NON_RHTP_SENTENCE))) {
    stop("[MI] the prevention-grants release no longer states that the money ",
         "is opioid settlement funded. That sentence is the whole reason ",
         "eight of RCJ's candidates are dispositioned NOT_RHTP.", call. = FALSE)
  }
  for (needle in MI_NON_RHTP_ABSENT) {
    if (stringr::str_detect(txt, stringr::fixed(needle))) {
      stop("[MI] the prevention-grants release now mentions '", needle,
           "'. The §6.2 negative control has changed; re-read it before ",
           "trusting the Michigan disposition table.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' THE POSITIVE CONTROL: MDHHS claims this roster is COMPLETE
#'
#' No other state in this repository does. Kansas, Nebraska, Oklahoma and
#' Nevada each publish a roster for some pools and are silent about the rest,
#' so their figures are floors by construction. Michigan's programme page says
#' the subrecipients page carries "all RHTP Subrecipients", which is what lets
#' $69,883,392 be reported as a total rather than a floor -- and the day that
#' sentence goes, so does the claim.
mi_assert_completeness_claim <- function() {
  prog <- mi_html_text("program")
  if (!stringr::str_detect(prog, stringr::fixed(MI_COMPLETENESS_SENTENCE))) {
    stop("[MI] the programme page no longer says MDHHS maintains a page ",
         "featuring ALL RHTP subrecipients. Without it every Michigan figure ",
         "in this repository is a floor, not a total -- rewrite the finding ",
         "before publishing it.", call. = FALSE)
  }
  roster <- mi_html_text("roster")
  if (!stringr::str_detect(roster, stringr::fixed(MI_ROSTER_ASOF_SENTENCE))) {
    stop("[MI] the roster no longer carries its 'as of July 10, 2026' date. ",
         "A roster with no as-of date cannot be compared to a later one.",
         call. = FALSE)
  }
  if (!stringr::str_detect(roster, stringr::fixed(MI_CONTINGENCY_SENTENCE))) {
    stop("[MI] the roster no longer says the amounts are contingent on CMS ",
         "approval. Every row here is amount_confirmed = No BECAUSE of that ",
         "sentence; if MDHHS has finalised them, re-code the file.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The five sections, and a tripwire in both directions
mi_assert_roster_sections <- function(recs) {
  got <- sort(unique(recs$initiative))
  want <- sort(MI_SECTIONS)
  if (!identical(got, want)) {
    stop("[MI] the roster's initiative sections are ",
         paste(got, collapse = " | "), "; expected ",
         paste(want, collapse = " | "), ". A section appearing means Michigan ",
         "has published a pool this file does not carry.", call. = FALSE)
  }
  roster <- mi_html_text("roster")
  for (s in MI_SECTIONS) {
    if (!stringr::str_detect(roster, stringr::fixed(s))) {
      stop("[MI] section heading '", s, "' is no longer on the page.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The <td> header defect: session 10's rule, five tables at once
#'
#' Positive control by construction -- if promotion ever stops happening the
#' header text lands in the data, so this asserts no awardee is a column name.
mi_assert_header_promoted <- function(recs) {
  leaked <- recs$awardee[tolower(recs$awardee) %in%
                           unlist(MI_COLUMN_SYNONYMS, use.names = FALSE)]
  if (length(leaked) > 0) {
    stop("[MI] ", length(leaked), " header row(s) leaked into the data as ",
         "awardees: ", paste(unique(leaked), collapse = ", "),
         ". MDHHS marks every roster header up with <td>, so the promotion ",
         "in mi_promote_header() is load-bearing (session 10).", call. = FALSE)
  }
  invisible(TRUE)
}

#' MHA is not a hospital, and $8,625,000 turns on that
mi_assert_mha_not_a_hospital <- function(recs) {
  mha <- recs[recs$awardee == "Michigan Health and Hospital Association (MHA)", ]
  if (nrow(mha) != 2L) {
    stop("[MI] expected MHA to hold exactly 2 awards; found ", nrow(mha), ".",
         call. = FALSE)
  }
  if (any(mha$recipient_type == "HOSPITAL_OR_SYSTEM")) {
    stop("[MI] the Michigan Health & Hospital Association is typed as a ",
         "HOSPITAL. It is the state's hospital trade association (§10.2), and ",
         "typing it as a hospital publishes $",
         format(sum(mha$amount), big.mark = ","),
         " as direct hospital dollars on a name match.", call. = FALSE)
    }
  if (any(mha$hospital_attribution == "NAMED_HOSPITAL")) {
    stop("[MI] MHA is in the NAMED_HOSPITAL bucket.", call. = FALSE)
  }
  # MHA's OWN page states its own total, and it matches MDHHS's two rows to
  # the dollar. Two publishers, one figure, nothing arranged.
  if (abs(sum(mha$amount) - MI_STATED$mha_own_footer) > 0.005) {
    stop("[MI] MDHHS's two MHA awards sum to $",
         format(sum(mha$amount), big.mark = ","), " but MHA's own footer ",
         "states $", format(MI_STATED$mha_own_footer, big.mark = ","), ".",
         call. = FALSE)
  }
  if (!stringr::str_detect(mi_html_text("mha"),
                           stringr::fixed("financial assistance award totaling $8.625 million"))) {
    stop("[MI] MHA's own page no longer states its $8.625 million award. That ",
         "is the independent corroboration of MDHHS's two MHA rows.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The tribal section is typed from the STATE's word, not from names
mi_assert_tribal_from_source <- function(recs) {
  trib <- recs[recs$award_pool == "Tribal Government", ]
  if (nrow(trib) != 13L) {
    stop("[MI] expected 13 Tribal Government awards; found ", nrow(trib), ".",
         call. = FALSE)
  }
  if (!all(trib$recipient_type == "TRIBAL_ORG")) {
    stop("[MI] not every Tribal Government row is TRIBAL_ORG.", call. = FALSE)
  }
  # The point of reading the state's column: the §8 NAME rule reaches only
  # nine of the thirteen.
  by_name <- rhtp_classify_recipient_type(trib$awardee, "MI")
  if (sum(by_name$recipient_type == "TRIBAL_ORG") >= 13L) {
    stop("[MI] the §8 name rule now types all 13 tribal recipients on its ",
         "own, so this assertion no longer demonstrates why the state's own ",
         "column is read. Re-word it rather than deleting it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Michigan's hospital figure, and the shape of it
#'
#' 139 awards, $69,883,392, and ONE named-hospital award action of $76,924.
#' That is not a parse failure and it is not Nevada's "no amounts": Michigan
#' publishes an amount on every row and almost none of it goes to a named
#' hospital. Michigan's hospital-facing money runs through MHA, which is an
#' unresolved pass-through and enters NEITHER bucket.
mi_assert_hospital_shape <- function(recs) {
  named <- recs[recs$hospital_attribution == "NAMED_HOSPITAL", ]
  if (nrow(named) != 1L) {
    stop("[MI] expected exactly 1 named-hospital award action; found ",
         nrow(named), ". Michigan's hospital figure is the most surprising ",
         "number in the file and must not move silently.", call. = FALSE)
  }
  parts <- rhtp_hospital_dollar_partition(recs)
  if (any(parts$bucket == "POOL_NAMED_HOSPITALS")) {
    stop("[MI] a POOL_NAMED_HOSPITALS row has appeared; Michigan publishes no ",
         "subrecipient roster behind any intermediary.", call. = FALSE)
  }
  unresolved <- recs[!is.na(recs$flag_reason) &
                       recs$flag_reason == "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED", ]
  if (nrow(unresolved) != 2L) {
    stop("[MI] expected MHA's 2 rows to carry ",
         "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED; found ", nrow(unresolved), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2's own rule: no per-recipient amount is ever divided or invented
mi_assert_reconciliation <- function(recs) {
  total <- sum(recs$amount)
  allot <- rhtp_mi_allotment()
  if (total > allot) {
    stop("[MI] the roster sums to $", format(total, big.mark = ","),
         " against a $", format(allot, big.mark = ","), " allotment.",
         call. = FALSE)
  }
  if (any(is.na(recs$amount))) {
    stop("[MI] ", sum(is.na(recs$amount)), " rows have no amount. Michigan ",
         "publishes one on every row -- an empty amount here is a parse ",
         "failure, not a finding (Nevada is the state where it is a finding).",
         call. = FALSE)
  }
  if (any(!is.na(recs$round_amount))) {
    stop("[MI] round_amount is populated. Michigan publishes no pool totals ",
         "on the roster, so there is nothing for it to carry and Georgia's ",
         "double-counting trap must not be introduced here.", call. = FALSE)
  }
  invisible(total)
}

#' §8: every categorical against the controlled vocabulary
mi_assert_vocabulary <- function(recs) {
  checks <- list(
    recipient_type = "recipient_type", flow_type = "flow_type",
    distributed_to_hospital = "distributed_to_hospital",
    determination_confidence = "determination_confidence",
    hospital_attribution = "hospital_attribution",
    rhtp_award_confirmed = "rhtp_award_confirmed",
    source_doc_type = "validation_source_type",
    flag_reason = "flag_reason"
  )
  for (vocab in names(checks)) {
    col <- checks[[vocab]]
    allowed <- rhtp_vocabulary(vocab)
    got <- unique(stats::na.omit(recs[[col]]))
    bad <- setdiff(got, allowed)
    if (length(bad) > 0) {
      stop("[MI] ", col, " carries value(s) outside §8's ", vocab, ": ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The open classification question, and that it is queued rather than guessed
mi_assert_form_not_stated_queued <- function(recs) {
  soft <- recs[recs$determination_confidence == "LOW" &
                 !is.na(recs$flag_reason) &
                 recs$flag_reason == "RECIPIENT_TYPE_INFERRED", ]
  if (nrow(soft) < 1L) {
    stop("[MI] no rows carry §8's fallback, which cannot be right for a ",
         "roster with no organisation-type column.", call. = FALSE)
  }
  # ONE-DIRECTIONAL, as Oklahoma's is: every fallback row is already
  # distributed_to_hospital = No, so resolving any can only RAISE Michigan's
  # hospital figure and never lower it.
  if (any(soft$distributed_to_hospital != "No")) {
    stop("[MI] a fallback row is not distributed_to_hospital = No, so the ",
         "one-directional claim in the queue row is no longer true.",
         call. = FALSE)
  }
  queue <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE)
  row <- queue[queue$question_id == MI_FORM_NOT_STATED_QUESTION, ]
  # SESSION 49 ANSWERED THIS QUESTION, so "OPEN" is no longer the only
  # honest state. The invariant this guard exists for is that the row is
  # FINDABLE and SAYS SOMETHING -- "a disclosure nobody can find is not a
  # disclosure" -- and a RESOLVED row with its resolution written out
  # satisfies that as well as an OPEN one does. A row that is RESOLVED and
  # EMPTY does not, and is still refused.
  answered <- identical(row$queue_status[[1]], "RESOLVED") &&
    !is.na(row$resolution[[1]]) && nzchar(row$resolution[[1]])
  if (nrow(row) != 1L ||
      !(identical(row$queue_status[[1]], "OPEN") || answered)) {
    stop("[MI] ", MI_FORM_NOT_STATED_QUESTION, " is not a findable row (OPEN, or RESOLVED with a resolution) in the ",
         "classification review queue.", call. = FALSE)
  }
  if (!grepl(as.character(nrow(soft)), row$row_key, fixed = TRUE)) {
    stop("[MI] the queue row does not state ", nrow(soft),
         " rows; the queue and the data disagree.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.1: RCJ's candidates, re-derived from the record table every run.
#'
#' SESSION 62 RE-READ (RCJ pull 2026-09-24): 31 -> 149. RCJ WITHDREW all 14
#' one-row-per-organisation "RHTP Subrecipients Award" rows and all 8 opioid
#' settlement rows, and now carries the MDHHS roster ONE ROW PER AWARD (132
#' rows under "RHTP Subrecipients"), plus 8 rows from five other documents.
#' Every group below is read off the table; an unread shape is UNCLASSIFIED and
#' the build stops.
MI_WRONG_STATE_ID <- "42b92bd8-03bc-459c-8e58-9a920022d44d"
MI_RCJ_CANDIDATES_EXPECTED <- 149L

mi_rcj_candidates <- function(recs = NULL) {
  if (is.null(recs)) recs <- rhtp_mi_year1_awardees()
  on_roster <- paste(recs$awardee, recs$amount)
  rt <- rhtp_record_table_live()
  rt %>%
    dplyr::filter(.data$state == "MI", .data$award_tier == "SUBAWARD") %>%
    dplyr::transmute(
      record_id = .data$record_id,
      awardee = .data$awardee_name_clean,
      rcj_amount = .data$amount_announced,
      doc = .data$source_doc_title,
      group = dplyr::case_when(
        .data$record_id == MI_WRONG_STATE_ID ~ "WRONG_STATE",
        grepl("Budget Narrative", .data$source_doc_title) ~ "BUDGET_NARRATIVE",
        grepl("Subrecipients Award", .data$source_doc_title) ~ "SUBRECIPIENTS_AWARD",
        grepl("substance use", .data$source_doc_title, ignore.case = TRUE) ~ "OPIOID_SETTLEMENT",
        .data$source_doc_title == "MI - 2026 - RHTP Subrecipients" &
          paste(.data$awardee_name_clean, .data$amount_announced) %in%
            on_roster ~ "ROSTER_PER_AWARD_IN_FILE",
        .data$source_doc_title == "MI - 2026 - RHTP Subrecipients" &
          .data$awardee_name_clean == "Michigan Veterans Affairs Agency (MVAA)" &
          .data$amount_announced == 2000000 ~ "ROSTER_ROW_NOT_IN_FILE",
        grepl("September 2026 RHTP Newsletter|Visits Michigan to Explore RHT",
              .data$source_doc_title) &
          .data$awardee_name_clean %in% c("Michigan High-Speed Internet Office",
                                          "Office of Rural Prosperity")
          ~ "LEO_AWARDS_NOT_IN_FILE_ROUNDED",
        grepl("community violence intervention|Suicide Prevention Council",
              .data$source_doc_title, ignore.case = TRUE)
          ~ "NOT_ON_COMPLETE_ROSTER",
        TRUE ~ "UNCLASSIFIED"))
}

mi_assert_rcj_disposition <- function(recs) {
  cand <- mi_rcj_candidates(recs)
  if (any(cand$group == "UNCLASSIFIED")) {
    stop("[MI] ", sum(cand$group == "UNCLASSIFIED"), " RCJ candidate(s) fall ",
         "into no disposition group. The candidate set has moved; read the ",
         "new documents before rebuilding.", call. = FALSE)
  }
  if (nrow(cand) != MI_RCJ_CANDIDATES_EXPECTED) {
    stop("[MI] the record table holds ", nrow(cand), " Michigan Tier 3 ",
         "candidates; this disposition was read at ",
         MI_RCJ_CANDIDATES_EXPECTED, ".", call. = FALSE)
  }
  n <- table(factor(cand$group, levels = names(MI_RCJ_GROUP_COUNTS)))
  for (g in names(MI_RCJ_GROUP_COUNTS)) {
    if (!identical(as.integer(n[[g]]), MI_RCJ_GROUP_COUNTS[[g]])) {
      stop("[MI] RCJ group ", g, " has ", n[[g]], " rows; expected ",
           MI_RCJ_GROUP_COUNTS[[g]], call. = FALSE)
    }
  }
  # The WRONG_STATE row is the §0.1 mode-6 sweep's verdict (R/02c,
  # SWEEP_MISFILED_TIER3): South Dakota's Rural Strong round in a multi-state
  # digest, filed under Michigan.
  ws <- cand[cand$group == "WRONG_STATE", ]
  if (nrow(ws) != 1L || !grepl("^South Dakota", ws$awardee) ||
      ws$rcj_amount != 31500000) {
    stop("[MI] the South Dakota row filed under Michigan has moved.",
         call. = FALSE)
  }
  # RCJ now carries the roster PER AWARD. Reconcile both directions.
  per_award <- cand[cand$group %in% c("ROSTER_PER_AWARD_IN_FILE",
                                      "ROSTER_ROW_NOT_IN_FILE"), ]
  file_not_rcj <- recs[!paste(recs$awardee, recs$amount) %in%
                         paste(per_award$awardee, per_award$rcj_amount), ]
  if (nrow(file_not_rcj) != 8L ||
      sum(file_not_rcj$amount) != 69883392 - 65150059) {
    stop("[MI] the file-vs-RCJ roster reconciliation moved (", nrow(file_not_rcj),
         " file rows RCJ does not carry per award).", call. = FALSE)
  }
  # The rows NOT on MDHHS's roster must still be absent from the file, and the
  # rows that ARE real-but-missing must still be missing (so the finding is
  # re-stated, not silently absorbed).
  for (nm in c("Michigan Veterans Affairs Agency (MVAA)",
               "Crim Fitness Foundation, Flint",
               "University of Michigan Injury Prevention Center")) {
    if (nm %in% recs$awardee) {
      stop("[MI] '", nm, "' is now in mi_year1_awardees.csv; restate the ",
           "RCJ disposition.", call. = FALSE)
    }
  }
  if (any(grepl("Labor and Economic Opportunity|Veterans Affairs",
                recs$awardee))) {
    stop("[MI] the LEO / MVAA awards are now in the file; restate the ",
         "disposition.", call. = FALSE)
  }
  invisible(cand)
}

MI_RCJ_GROUP_COUNTS <- c(
  ROSTER_PER_AWARD_IN_FILE = 131L, ROSTER_ROW_NOT_IN_FILE = 1L,
  SUBRECIPIENTS_AWARD = 0L, BUDGET_NARRATIVE = 9L, OPIOID_SETTLEMENT = 0L,
  LEO_AWARDS_NOT_IN_FILE_ROUNDED = 2L, NOT_ON_COMPLETE_ROSTER = 5L,
  WRONG_STATE = 1L)

mi_validate <- function() {
  mi_assert_rhtp_funded()
  mi_assert_after_noa()
  mi_assert_non_rhtp_control()
  mi_assert_completeness_claim()
  recs <- rhtp_mi_year1_awardees()
  mi_assert_roster_sections(recs)
  mi_assert_header_promoted(recs)
  mi_assert_mha_not_a_hospital(recs)
  mi_assert_tribal_from_source(recs)
  mi_assert_hospital_shape(recs)
  mi_assert_vocabulary(recs)
  mi_assert_reconciliation(recs)
  mi_assert_rcj_disposition(recs)
  mi_assert_form_not_stated_queued(recs)
  message("[MI] all assertions pass.")
  invisible(recs)
}


# -- the RCJ disposition table ------------------------------------------------

mi_disposition_table <- function(recs) {
  cand <- mi_rcj_candidates(recs)
  g <- function(x) cand[cand$group == x, ]
  n <- function(x) nrow(g(x))
  d <- function(x) sum(g(x)$rcj_amount)
  roster_url <- paste0(MI_RHTP, "/rhtp-subrecipients")
  roster_arc <- file.path("data", "evidence", "MI", mi_source("roster", "file"))

  tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount_sum, ~disposition, ~why,
    ~disqualifying_evidence, ~state_source_url, ~source_archive_path,

    "Real awards on the MDHHS roster, now carried ONE ROW PER AWARD",
    n("ROSTER_PER_AWARD_IN_FILE"), d("ROSTER_PER_AWARD_IN_FILE"),
    "RHTP_SUBAWARD_IN_FILE",
    paste0(
      "NEW in the 2026-09-24 pull, under 'MI - 2026 - RHTP Subrecipients'. ",
      "Every one matches a row of mi_year1_awardees.csv on BOTH the exact ",
      "awardee string AND the amount; no RCJ amount disagrees. RCJ now carries ",
      "132 roster rows where the file has 139: 8 file rows ($4,733,333) are ",
      "not carried per award -- five (Berrien County HD $150,000, Chippewa ",
      "County HD $150,000, Chippewa-Luce-Mackinac CAA $350,000, MiHIA ",
      "$1,500,000, UPCAP $1,500,000) exist in RCJ only as the Budget Narrative ",
      "rows below at the same amount, and three (Harbor Beach Community School ",
      "District School Wellness Program $83,333; PACE Central Michigan and ",
      "PACE Northeast Michigan $500,000 each) are in RCJ as UNASSIGNED, not ",
      "Tier 3. The session-27 one-row-per-organisation deflation is gone."),
    "exact (awardee, amount) match against mi_year1_awardees.csv",
    roster_url, roster_arc,

    "Real award on the LIVE MDHHS roster, NOT in the committed file",
    n("ROSTER_ROW_NOT_IN_FILE"), d("ROSTER_ROW_NOT_IN_FILE"),
    "RHTP_SUBAWARD_NOT_IN_FILE",
    paste(
      "Michigan Veterans Affairs Agency (MVAA), $2,000,000, Care Closer to Home",
      "/ Advancing Rural Behavioral Health Blueprint. NOT on the committed",
      "2026-09-01 roster archive. A read-only in-memory fetch of the live",
      "roster on 2026-09-24 (not archived; data/evidence/ untouched) shows",
      "MDHHS has ADDED SIX ROWS since 2026-09-01 -- 145 rows / $101,318,437",
      "against the file's 139 / $69,883,392 -- and this is one of them.",
      "The file's 'TOTAL, not a floor' claim is stale until MI is re-fetched",
      "and re-extracted. NOT added here."),
    "absent from the committed roster archive; present on the live roster 2026-09-24",
    roster_url, roster_arc,

    paste("Real awards, but ONE ROW PER ORGANISATION where MDHHS publishes",
          "one row per AWARD"),
    n("SUBRECIPIENTS_AWARD"), d("SUBRECIPIENTS_AWARD"), "RHTP_SUBAWARD_IN_FILE",
    paste(
      "HISTORY. On the 2026-08-27 pull this group held 14 genuine",
      "subrecipients under 'RHTP Subrecipients Award', one row per",
      "organisation, $19,484,032 against the $27,317,365 those organisations",
      "hold on the roster -- a $7,833,333 DEFLATION (the Michigan Center for",
      "Rural Health: RCJ $3,000,000, MDHHS five awards totalling $7,275,000).",
      "On the 2026-09-24 pull RCJ WITHDREW all 14 and replaced them with the",
      "per-award rows above, so the group holds 0 rows."),
    "one RCJ row per organisation vs one MDHHS row per award (2026-08-27)",
    roster_url, roster_arc,

    "State Of Michigan RHTP Budget Narrative line items",
    n("BUDGET_NARRATIVE"), d("BUDGET_NARRATIVE"),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste(
      "Genuinely RHTP and one tier too high (§0.2, Oklahoma's defect). These",
      "are planning figures out of Michigan's own RHTP Budget Narrative, not",
      "award actions. Five of the nine names appear on the roster at the SAME",
      "amount as one of their awards (Berrien $150,000, Chippewa County HD",
      "$150,000, Chippewa-Luce-Mackinac CAA $350,000, MiHIA $1,500,000, UPCAP",
      "$1,500,000) -- and RCJ does not carry those five roster awards per award",
      "at all -- while four appear nowhere on it, including 'Northern",
      "Michigan Center for Rural Health (Technical Assistance for Hubs)' and",
      "'Thumb Alliance - Sanilac County Health Department', which are project",
      "labels rather than the recipient names MDHHS awarded under."),
    "budget-narrative planning figures, not award actions",
    MI_RHTP, file.path("data", "evidence", "MI", mi_source("program", "file")),

    "MDHHS youth substance-use prevention grants -- OPIOID SETTLEMENT money",
    n("OPIOID_SETTLEMENT"), d("OPIOID_SETTLEMENT"),
    "NOT_RHTP_STATE_PROGRAM",
    paste(
      "HISTORY, and the §6.2 negative control stays. MDHHS's 2026-06-24",
      "release awards 'nearly $3.75 million to 12 organizations' and its own",
      "sub-headline states the funding source: 'New opioid settlement-funded",
      "grants support 12 organizations'; 'Rural Health Transformation', 'RHTP'",
      "and 'rural' appear ZERO times in it. RCJ filed eight of the twelve",
      "($2,214,846) as Michigan RHTP Tier 3 candidates on the 2026-08-27 pull",
      "and WITHDREW all eight on 2026-09-24, so the group holds 0 rows."),
    "\"New opioid settlement-funded grants support 12 organizations\"",
    paste0(MI_BASE, "/mdhhs/inside-mdhhs/newsroom/2026/06/24/prevention-grants"),
    file.path("data", "evidence", "MI", mi_source("prevention", "file")),

    "LEO interagency awards named in secondary documents, ROUNDED, NOT in the file",
    n("LEO_AWARDS_NOT_IN_FILE_ROUNDED"), d("LEO_AWARDS_NOT_IN_FILE_ROUNDED"),
    "RHTP_SUBAWARD_NOT_IN_FILE",
    paste(
      "'Michigan High-Speed Internet Office' $9,100,000 (September 2026 RHTP",
      "Newsletter) and 'Office of Rural Prosperity' $16,700,000 (the CMS site",
      "visit release). Neither is on the committed roster. The live roster",
      "read on 2026-09-24 (in memory, not archived) carries 'Michigan",
      "Department of Labor and Economic Opportunity (LEO) - Michigan High",
      "Speed Internet Office' $9,104,425 and 'LEO - Office of Rural",
      "Prosperity' $16,130,623 + $600,000 = $16,730,623 across two funds. So",
      "these are REAL RHTP AWARDS (to a state agency) NOT in our file, and",
      "RCJ's figures are the secondary documents' ROUNDINGS, not the roster's:",
      "-$4,425 and -$30,623. Two further live-roster rows (MDE Office of CTE,",
      "$2,099,997 and $1,500,000) are carried by RCJ nowhere."),
    "absent from the committed roster archive; rounded restatements of live-roster rows",
    roster_url, roster_arc,

    "Not on the roster MDHHS calls complete (CVI grants; suicide-prevention contract)",
    n("NOT_ON_COMPLETE_ROSTER"), d("NOT_ON_COMPLETE_ROSTER"),
    "NOT_AN_RHTP_SUBAWARD_PER_COMPLETENESS_CLAIM",
    paste(
      "NEW. Four $300,000 grants from 'MDHHS awards $1.5 million for",
      "community violence intervention efforts' (Crim Fitness Foundation,",
      "DLIVE, Detroit Peoples Community, Present Pillars) and a $100,000",
      "contract to the University of Michigan Injury Prevention Center from",
      "the 'Michigan Suicide Prevention Council Report'. None is on the",
      "committed roster, nor on the live roster read 2026-09-24, and MDHHS",
      "says that page features 'all RHTP Subrecipients'. The completeness",
      "claim, not RCJ's RHTP label, decides them: not RHTP subawards. Their",
      "source documents are not archived here, so the funding stream is not",
      "named; recorded as such."),
    "absent from the roster MDHHS calls complete",
    roster_url, roster_arc,

    "Another state's record (§0.1 mode 6)",
    n("WRONG_STATE"), d("WRONG_STATE"),
    "WRONG_STATE",
    paste(
      "'South Dakota (Rural Strong grants)', $31,500,000, from a multi-state",
      "H.R. 1 digest ('July 2026: Responding to H.R. 1, States Are",
      "Communicating ...'). It is South Dakota's 28-grant round (R/03j), filed",
      "under Michigan. The §0.1 mode-6 sweep's final verdict (R/02c,",
      "SWEEP_MISFILED_TIER3)."),
    "R/02c SWEEP_MISFILED_TIER3", NA_character_,
    "data/reference/rcj_state_attribution_sweep.csv"
  )
}


# -- build --------------------------------------------------------------------

mi_build <- function() {
  recs <- mi_validate()
  readr::write_csv(recs, MI_OUTPUT_CSV, na = "")
  message("[MI] wrote ", MI_OUTPUT_CSV, " (", nrow(recs), " rows)")
  disp <- mi_disposition_table(recs)
  readr::write_csv(disp, MI_DISPOSITION_CSV, na = "")
  message("[MI] wrote ", MI_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  mi_write_workbook(recs, disp)
  invisible(recs)
}

mi_write_workbook <- function(recs, disp) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "READ FIRST")
  openxlsx::writeData(wb, "READ FIRST", tibble::tibble(note = c(
    "MICHIGAN -- RHTP YEAR 1 SUBRECIPIENTS. 139 award actions, $69,883,392.",
    "",
    "MDHHS CLAIMS THIS ROSTER IS COMPLETE, which no other state file here can",
    "say: its programme page reads \"MDHHS maintains a dedicated webpage",
    "featuring all RHTP Subrecipients\". So this is a TOTAL and not a floor --",
    "for as long as that sentence is on the page, which an assertion checks.",
    "",
    "THE AMOUNTS ARE NOT FINAL. Every one is \"contingent upon review by",
    "Centers for Medicare & Medicaid Services (CMS) for final approval\", so",
    "all 139 rows are amount_confirmed = No. The recipients ARE confirmed.",
    "",
    "ONE NAMED-HOSPITAL AWARD ACTION, $76,924. That is not a parse failure.",
    "Michigan's recipients are health departments, community action agencies,",
    "FQHCs, Area Agencies on Aging, universities and tribal governments, and",
    "its hospital-facing money runs through the MICHIGAN HEALTH & HOSPITAL",
    "ASSOCIATION -- $8,625,000 across two awards, which is §10.2's",
    "association row and NOT a hospital. MDHHS publishes no project",
    "description, so nothing states where MHA's money goes: those two rows are",
    "PASS_THROUGH_UNRESOLVED + Unclear and enter NEITHER bucket of the",
    "hospital partition.",
    "",
    "READ award_pool BEFORE USING ANY FIGURE. Twelve funds across five",
    "initiatives, and one organisation may hold several awards: the Michigan",
    "Center for Rural Health holds five.")), colNames = FALSE)
  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", recs)
  openxlsx::addWorksheet(wb, "RCJ disposition")
  openxlsx::writeData(wb, "RCJ disposition", disp)
  openxlsx::saveWorkbook(wb, MI_OUTPUT_XLSX, overwrite = TRUE)
  message("[MI] wrote ", MI_OUTPUT_XLSX)
}


# -- report -------------------------------------------------------------------

mi_report <- function() {
  recs <- rhtp_mi_year1_awardees()
  allot <- rhtp_mi_allotment()
  total <- sum(recs$amount)

  cat("\nMICHIGAN -- RHTP YEAR 1 SUBRECIPIENTS\n")
  cat(strrep("=", 74), "\n")
  cat("  award actions        : ", nrow(recs), "\n", sep = "")
  cat("  distinct recipients  : ", dplyr::n_distinct(recs$awardee), "\n", sep = "")
  cat("  published            : $", format(total, big.mark = ","), "\n", sep = "")
  cat("  CMS allotment (§7.1) : $", format(allot, big.mark = ","), "\n", sep = "")
  cat("  share published      : ", sprintf("%.1f%%", 100 * total / allot), "\n", sep = "")

  cat("\nBY INITIATIVE\n"); cat(strrep("-", 74), "\n")
  by_init <- recs %>%
    dplyr::group_by(.data$initiative) %>%
    dplyr::summarise(rows = dplyr::n(), dollars = sum(.data$amount),
                     .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(.data$dollars))
  for (i in seq_len(nrow(by_init))) {
    cat(sprintf("  %-58s %3d  $%12s\n", by_init$initiative[i], by_init$rows[i],
                formatC(by_init$dollars[i], format = "f", digits = 0,
                        big.mark = ",")))
  }

  cat("\nTHE HOSPITAL FIGURE, AND WHY IT IS ONE ROW\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(rhtp_hospital_dollar_partition(recs)))
  cat("\n  Michigan publishes an amount on every row and almost none of it\n")
  cat("  reaches a named hospital. Its hospital-facing money runs through\n")
  cat("  the MICHIGAN HEALTH & HOSPITAL ASSOCIATION: $",
      format(sum(recs$amount[grepl("^Michigan Health and Hospital", recs$awardee)]),
             big.mark = ","), " across 2 awards,\n", sep = "")
  cat("  which is §10.2's association row and NOT a hospital. MDHHS publishes\n")
  cat("  no project description, so nothing says where that money goes --\n")
  cat("  PASS_THROUGH_UNRESOLVED, Unclear, NEITHER bucket (session 19).\n")
  cat("  MHA'S OWN PAGE STATES $8.625 MILLION IN ITS OWN FOOTER, which is\n")
  cat("  MDHHS's two rows to the dollar. Two publishers, nothing arranged.\n")

  soft <- recs[recs$determination_confidence == "LOW" &
                 !is.na(recs$flag_reason) &
                 recs$flag_reason == "RECIPIENT_TYPE_INFERRED", ]
  cat("\n  §8 fallback (form not stated): ", nrow(soft), " rows / $",
      format(sum(soft$amount), big.mark = ","), "\n", sep = "")
  cat("  ONE-DIRECTIONAL, as Oklahoma's is: every one is already\n")
  cat("  distributed_to_hospital = No, so resolving any can only RAISE the\n")
  cat("  hospital figure. NOTHING WAS PROMOTED (§0.4).\n")

  cat("\n§0.1 -- RCJ'S ", nrow(mi_rcj_candidates(recs)), " CANDIDATES (31 on 2026-08-27)\n",
      sep = ""); cat(strrep("-", 74), "\n")
  disp <- mi_disposition_table(recs)
  for (i in seq_len(nrow(disp))) {
    cat(sprintf("  %3d  %-24s %s\n", disp$rcj_rows[i], disp$disposition[i],
                substr(disp$group[i], 1, 44)))
  }
  cat("\n  ON 2026-08-27 THIS ONE DEFLATED: one row per ORGANISATION, $19,484,032\n")
  cat("  (28% of the roster) with $2,214,846 of OPIOID SETTLEMENT money mixed\n")
  cat("  in. On 2026-09-24 RCJ withdrew both and carries the roster per award;\n")
  cat("  it also carries awards the live roster has and this file does not.\n")

  cat("\n§6.2 -- WITH THE FOOTER DOWNGRADED (session 27's audit)\n")
  cat(strrep("-", 74), "\n")
  cat("  The roster's footer reads \"This PROJECT is supported by...\" -- the\n")
  cat("  publication-scoped form. It corroborates the AMOUNT ($173,128,201.02\n")
  cat("  against the §7.1 anchor, to the dollar) and is NOT the provenance.\n")
  cat("  Three PROGRAMME-SCOPED sentences are, and each is asserted:\n")
  cat("    roster       : \"organizations that have received RHTP funding\"\n")
  cat("    programme    : \"awarded $173,128,201 for Budget Period 1 ... under\n")
  cat("                    the RHT Program\"\n")
  cat("    release      : 2025-12-30, the day after the CMS Notice of Award\n")
  cat("  NEGATIVE CONTROL: MDHHS's own prevention release says \"New OPIOID\n")
  cat("  SETTLEMENT-funded grants\" and never says RHTP -- and eight of RCJ's\n")
  cat("  2026-08-27 candidates were its recipients (withdrawn 2026-09-24).\n")

  invisible(recs)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(as.data.frame(mi_fetch(force = "--force" %in% args)))
  if ("--validate" %in% args) mi_validate()
  if ("--build" %in% args) mi_build()
  if ("--report" %in% args) mi_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03v_mi_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report]\n")
  }
}

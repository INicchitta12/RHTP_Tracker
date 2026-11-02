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
#   145 award actions -- $101,318,437 -- 58.5% of Michigan's $173,128,201
#   Five initiative sections, one row per AWARD. (Sessions 27-63: 139 actions,
#   $69,883,392, "as of July 10, 2026".)
#
# SESSION 64: THE ROSTER GREW AND WAS RE-EXTRACTED. MDHHS's page now reads
# "Award notices as of August 31, 2026" and carries SIX more rows, $31,435,045,
# every one to a Michigan STATE AGENCY receiving RHTP money as a SUBRECIPIENT
# (LEO x3, MDE x2, MVAA) -- MDHHS is the grantor and is on no row. No existing
# row changed or disappeared. The six are APPENDED as rows 140-145 rather than
# read in page order (MDHHS inserts alphabetically, mid-table), because session
# 49's verification overlay is keyed on row index; see
# `mi_roster_in_file_order()`. No hospital figure moves.
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
# RCJ holds 31 Michigan Tier 3 candidates. They decompose exactly:
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
# 145 awards, $101,318,437, and ONE named-hospital award action -- $76,924
# (two, $259,121, once session 49's verification overlay is applied).
# Michigan's recipients are local health departments, community action
# agencies, FQHCs, Area Agencies on Aging, universities, tribal governments,
# and statewide intermediaries. Its rural hospital money, so far as MDHHS has
# published it, runs through the MICHIGAN HEALTH & HOSPITAL ASSOCIATION --
# which is §10.2's association row and NOT a hospital, and is the single
# largest classification trap in the file. See `MI_RECIPIENT_TYPE_OVERRIDES`.
#
# SESSION 112: THE ROSTER GREW AGAIN AND, FOR THE FIRST TIME, SHRANK. MDHHS's
# page now reads "Award notices as of October 1, 2026": 231 award actions,
# $161,740,847 (93.4% of the allotment). Against the 145-row file it ADDS 93
# rows ($63,022,410) and DROPS 7 ($2,600,000): five AHEC regional centres and a
# Community Mental Health Association of Michigan award reappear under new
# labels at the same initiative, fund and amount, and Saginaw County Health
# Department's $100,000 moved initiative and fund. Michigan claims the page is
# complete, so the dropped rows leave the file (MI_S112_DROPPED, pinned), the
# rows after them move up, and session 49's index-keyed overlay was re-keyed
# to match (`--rekey-overlay`). The 93 additions are typed through the shared
# classifier, then MI_S112_TYPINGS (CMS MI enrolment, system parents, hospital
# foundations), then session 49's verified answer for the same string.
#
# CLI:
#   Rscript R/03v_mi_year1_awardees.R --rekey-overlay   # session 112, idempotent
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
  # SESSION 64: the roster re-dated itself. The 2026-09-01 archive read "Award
  # notices as of July 10, 2026"; the 2026-09-24 one reads "August 31, 2026".
  # SESSION 112: the 2026-11-02 archive reads "October 1, 2026".
  roster_as_of        = as.Date("2026-10-01"),
  roster_0924_as_of   = as.Date("2026-08-31"),
  roster_prior_as_of  = as.Date("2026-07-10"),
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
MI_ROSTER_ASOF_SENTENCE  <- "Award notices as of October 1, 2026"
MI_ROSTER_0924_ASOF_SENTENCE <- "Award notices as of August 31, 2026"
MI_ROSTER_PRIOR_ASOF_SENTENCE <- "Award notices as of July 10, 2026"
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
# The count the queue row states (the 145-row roster of "August 31, 2026").
MI_FORM_NOT_STATED_QUEUED_N <- 84L
# Named-hospital award actions AS BUILT, before sessions 49 and 71's overlays
# (session 112: 1 prior + the added rows typed hospital in MI_S112_TYPINGS
# or by the shared classifier).
MI_S112_NAMED_BUILT <- 17L


# -- sources ------------------------------------------------------------------

MI_BASE <- "https://www.michigan.gov"
MI_RHTP <- paste0(MI_BASE, "/mdhhs/assistance-programs/medicaid/rural-health-transformation-program")

MI_SOURCES <- tibble::tribble(
  ~key, ~file, ~url, ~agent,
  # THE ROSTER. Five tables, 231 named awards WITH amounts (session 112,
  # "Award notices as of October 1, 2026"). A byte-for-byte copy of
  # data/evidence/recheck/2026-11-02/MI/ (same digest), not a second fetch.
  "roster", "2026-11-02_mi_rhtp_subrecipients.html",
  paste0(MI_RHTP, "/rhtp-subrecipients"), "MICHIGAN_GOV",
  # THE 2026-09-24 ROSTER, KEPT (sessions 64-111: 145 rows, "as of August 31,
  # 2026"). ARCHIVE-ONLY. With roster_prior it fixes the file's row order for
  # the rows still on the page, and it is what session 112's additions and
  # removals are measured against.
  "roster_0924", "2026-09-24_mi_rhtp_subrecipients.html",
  paste0(MI_RHTP, "/rhtp-subrecipients"), "MICHIGAN_GOV",
  # THE PRIOR ROSTER, KEPT. The 139-row page the file was first built from
  # (sessions 27-63). It fixes the ROW ORDER of the file -- session 49's
  # verification overlay is keyed on (file, row index) -- and it is what the
  # six additions are measured against. It is ARCHIVE-ONLY: mi_fetch() never
  # re-fetches it, because the url now serves the 145-row page.
  "roster_prior", "2026-09-01_mi_rhtp_subrecipients.html",
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

# Sources that are kept as history and must never be overwritten by a fetch.
MI_ARCHIVE_ONLY <- c("roster_prior", "roster_0924")

mi_fetch <- function(force = FALSE) {
  dir.create(MI_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(MI_SOURCES)), function(i) {
    src  <- MI_SOURCES[i, ]
    dest <- file.path(MI_EVIDENCE_DIR, src$file)
    if (src$key %in% MI_ARCHIVE_ONLY) {
      if (!file.exists(dest)) {
        stop("[MI] ", src$file, " is archive-only and missing; it cannot be ",
             "re-fetched, because its url now serves a later page.", call. = FALSE)
      }
      message("[MI] archive-only, never re-fetched: ", src$file)
    } else if (file.exists(dest) && !force) {
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
    "Michigan -- RHTP Year 1: MDHHS's RHTP Subrecipients roster (231 named",
    "awards WITH amounts, 2026-11-02, 'as of October 1, 2026'), the 145-row",
    "roster it replaced (2026-09-24) and the 139-row roster before that",
    "(2026-09-01), the programme page carrying its completeness claim,",
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
    "SESSION 112: THE ROSTER IS `2026-11-02_mi_rhtp_subrecipients.html`, a",
    "byte-for-byte copy of data/evidence/recheck/2026-11-02/MI/ (same digest;",
    "fetched with the bare michigan.gov agent). 26 + 78 + 72 + 42 + 13 = 231",
    "award actions, $161,740,847, 'Award notices as of October 1, 2026'.",
    "Against the 145-row roster below it ADDS 93 rows and DROPS 7 (exact",
    "initiative + name + amount + fund); five AHEC regional centres and one",
    "Community Mental Health Association row reappear under new labels at the",
    "same initiative, fund and amount, and Saginaw County Health Department's",
    "$100,000 moved initiative and fund. The file follows the page: dropped",
    "rows leave, because MDHHS claims the page is complete.",
    "",
    "THE 2026-09-24 ROSTER IS `2026-09-24_mi_rhtp_subrecipients.html`. Five accordion",
    "sections, one per initiative, each a Subrecipient Organization / Award",
    "Amount* / Fund table: 23 + 71 + 21 + 17 + 13 = 145 award actions and",
    "$101,318,437, 'Award notices as of August 31, 2026'. It is a byte-for-byte",
    "copy of data/evidence/recheck/2026-09-24/MI/ (session 63's read-only fetch,",
    "same digest), not a second fetch.",
    "",
    "THE PRIOR ROSTER IS `2026-09-01_mi_rhtp_subrecipients.html`, KEPT: 139",
    "award actions, $69,883,392, 'as of July 10, 2026'. Against it the current",
    "page ADDED six rows ($31,435,045, every one to a Michigan STATE AGENCY as",
    "a subrecipient -- LEO x3, MDE x2, MVAA) and changed or removed none. It is",
    "ARCHIVE-ONLY: mi_fetch() never re-fetches it, and it fixes the file's row",
    "order (the 139 keep rows 1-139; the six are appended as 140-145), because",
    "session 49's verification overlay is keyed on row index.",
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
    paste0("Manifest written: ", Sys.Date(),
           ". Each file's fetch date is the date in its name."),
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
mi_roster_tables <- function(key = "roster") {
  doc <- mi_html_doc(key)
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
  # SESSION 112: "Northern Lower Regional Center (MidMichigan Health Services)"
  # left the roster; MDHHS now prints "Area Health Education Center (AHEC):
  # Northern Lower Regional Center" at the same fund and amount, which states
  # the form (AHEC) and needs no override.
  # SESSION 112: MDHHS's 10-01 roster adds a third MHA spelling with no
  # "(MHA)" suffix. Same association, same trap, same override.
  "Michigan Health and Hospital Association", "HOSPITAL_AFFILIATED_ENTITY", "HIGH",
  paste("Michigan's hospital trade association, not a hospital (the same body",
        "as 'Michigan Health and Hospital Association (MHA)'). The §8 name rule",
        "would return HOSPITAL_OR_SYSTEM -> DIRECT -> Yes; typed",
        "HOSPITAL_AFFILIATED_ENTITY so the flow must read the source (MI_MHA_FLOW)."),
  # SESSION 64: two of MDHHS's six 2026-08-31 additions are STATE AGENCIES
  # receiving RHTP money as SUBRECIPIENTS -- an interagency allocation, not the
  # grantor (MDHHS is the grantor and is on no row). The §8 name rule gets the
  # LEO rows right ("Department of" -> STATE_AGENCY) and these two wrong:
  # "Office of Career and TECHNICAL EDUCATION" trips the school token and
  # returns SCHOOL_OR_DISTRICT, and "Michigan Veterans Affairs Agency" matches
  # nothing and falls to the fallback. Both names state the form themselves --
  # a Michigan DEPARTMENT, a Michigan AGENCY -- so STATE_AGENCY at MEDIUM, the
  # confidence the name rule gives LEO. Neither is a hospital type, so this can
  # only keep dollars OUT of the hospital total.
  "Michigan Department of Education (MDE) - Office of Career and Technical Education",
  "STATE_AGENCY", "MEDIUM",
  paste("The Michigan Department of Education, a state agency, as an RHTP",
        "subrecipient (interagency allocation from MDHHS). The name states the",
        "form; the §8 name rule's school token would type the recipient by its",
        "office's subject (SCHOOL_OR_DISTRICT), which is §0.3a's error."),
  "Michigan Veterans Affairs Agency (MVAA)", "STATE_AGENCY", "MEDIUM",
  paste("A Michigan state agency named as such ('Michigan ... Agency'), an RHTP",
        "subrecipient by interagency allocation from MDHHS. The §8 name rule",
        "matches no token and would take the standing fallback, asserting the",
        "form is undetermined where the name states it.")
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
  # SESSION 88: MEDIUM, not HIGH. The state's own column settles the FORM; §7
  # reserves HIGH for a CCN match, which no row here has.
  out$determination_confidence[tribal] <- "MEDIUM"
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
    out$determination_confidence[hit] <- rhtp_confidence_ceiling(o$confidence)
    out$recipient_type_basis[hit] <- o$why
  }
  out
}


# -- session 112: the 93 rows MDHHS added "as of October 1, 2026" ---------------
#
# Every added row goes through the shared classifier first (mi_recipient_type()
# above). The rows below are the ones that classifier cannot settle on its own,
# each typed on CMS's Michigan Hospital Enrollments extract
# (data/evidence/federal_records/2026-09-25/cms_hosp_enrollments_MI.json) or on
# §7's system-parent and foundation rules. Keyed on the EXACT awardee string,
# applied to session-112 additions ONLY, and `n` (rows carrying the string) is
# asserted, so a stale or widened entry stops the build.
#
#   basis_type follows R/03bj's convention: an EXACT legal-name match is
#   MEDIUM / ORG_WEBSITE; a hand-read bridge (an exact DBA, a misspelling, a
#   unit of the enrolled entity) is LOW / GENERAL_KNOWLEDGE (Carson Valley
#   Health, NV, is the exact-DBA precedent); a system parent or a named
#   hospital's foundation, with no enrolment under its own name, is LOW /
#   GENERAL_KNOWLEDGE with no CCN (§7, SD Sanford/Avera, VA Ballad/Sentara).
#
#   `ccn` goes on the row only where the enrolment IS the typing. HIGH still
#   needs Stage 5 (§7), so nothing here exceeds MEDIUM.
MI_S112_ENROL <- "data/evidence/federal_records/2026-09-25/cms_hosp_enrollments_MI.json"
MI_S112_TYPINGS <- tibble::tribble(
  ~awardee, ~n, ~recipient_type, ~confidence, ~basis_type, ~ccn, ~why,
  # --- exact legal name on the CMS MI enrolment ----------------------------
  "DLP Marquette General Hospital", 1L, "HOSPITAL_OR_SYSTEM", "MEDIUM", "ORG_WEBSITE", "230054",
    "CMS MI enrolment: DLP MARQUETTE GENERAL HOSPITAL LLC (dba UP HEALTH SYSTEM MARQUETTE), CCN 230054, Marquette -- the awardee's exact legal name less 'LLC'.",
  "Helen Newberry Joy Hospital", 1L, "HOSPITAL_OR_SYSTEM", "MEDIUM", "ORG_WEBSITE", "231304",
    "CMS MI enrolment: HELEN NEWBERRY JOY HOSPITAL, CCN 231304 (critical access hospital), Newberry -- exact legal name.",
  "Kalkaska Memorial Health Center", 1L, "HOSPITAL_OR_SYSTEM", "MEDIUM", "ORG_WEBSITE", "231301",
    "CMS MI enrolment: KALKASKA MEMORIAL HEALTH CENTER, CCN 231301 (critical access hospital), Kalkaska -- exact legal name. The §8 name rule reads no hospital token in it and took the fallback; the federal record settles the form (§7, enrolled hospital operators).",
  "Ella E. M. Brown Charitable Circle DBA Oaklawn Hospital", 1L, "HOSPITAL_OR_SYSTEM", "MEDIUM", "ORG_WEBSITE", "230217",
    "CMS MI enrolment: ELLA E M BROWN CHARITABLE CIRCLE (dba OAKLAWN HOSPITAL), CCN 230217, Marshall -- MDHHS prints the exact legal name AND the DBA.",
  # --- hand-read bridges to an enrolled hospital ----------------------------
  "Memorial Healthcare", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", "230121",
    "HAND-READ BRIDGE: the awardee is the exact DBA of MEMORIAL HOSPITAL (dba MEMORIAL HEALTHCARE), CCN 230121, Owosso, on CMS's MI enrolment; an exact DBA is a bridge, not a legal-name match (Carson Valley Health, NV, session 71). The §8 name rule took the fallback.",
  "Insight Hospital and Medical Center - Coldwater", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", "230022",
    "HAND-READ BRIDGE: the awardee is the exact DBA (INSIGHT HOSPITAL AND MEDICAL CENTER COLDWATER) of COMMUNITY HEALTH CENTER OF BRANCH COUNTY, CCN 230022, Coldwater, on CMS's MI enrolment.",
  "OSF Healthcare - Saint Francis Hospital", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", "231337",
    "HAND-READ BRIDGE: CMS MI enrolment ST FRANCIS HOSPITAL (dba OSF HEALTHCARE ST. FRANCIS HOSPITAL & MEDICAL GROUP), CCN 231337 (critical access hospital), Escanaba; the awardee is the DBA's system-plus-hospital form, not an exact string.",
  "Mackinac Straights Health System", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", "231306",
    "HAND-READ BRIDGE: MDHHS's 'Straights' is CMS's MACKINAC STRAITS HEALTH SYSTEM INC (dba MACKINAC STRAITS HOSPITAL AND HEALTH CENTER), CCN 231306 (critical access hospital), St. Ignace -- the enrolled legal name misspelled, the only Mackinac hospital enrolled.",
  "Sheridan Community Hospital Clinic", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", "231312",
    "HAND-READ BRIDGE: the awardee names SHERIDAN COMMUNITY HOSPITAL, CCN 231312 (critical access hospital), Sheridan, plus 'Clinic' -- read as a clinic of the enrolled hospital (§0.3a: the site does not change the recipient). Counter: a hospital-owned clinic may be separately enrolled as an RHC, and Oregon held such rows on the state's stated form; MDHHS states no form here.",
  # --- system parents and named hospitals' foundations (no own enrolment) ---
  "Marshfield Clinic Health System Hospitals, Inc.", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "SYSTEM PARENT (§7): Marshfield Clinic Health System's hospital corporation; in Michigan it operates Marshfield Medical Center - Dickinson, which CMS enrols under DICKINSON COUNTY HEALTHCARE SYSTEM (CCN 231342), a different legal name, so no CCN is put on the row.",
  "McClaren Health Care Corporation", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "SYSTEM PARENT (§7): MDHHS's 'McClaren' is McLaren Health Care Corporation, the parent of the McLaren hospitals CMS enrols in Michigan (McLaren Northern Michigan, Caro Region, Thumb Region, Bay Region and others), none under the parent's own name.",
  "Munson Healthcare", 2L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "SYSTEM PARENT (§7): Munson Healthcare is the parent of Munson Medical Center (CCN 230097) and the Munson Healthcare Charlevoix, Grayling, Cadillac, Manistee and Otsego hospitals on CMS's MI enrolment; the parent is not enrolled under its own name.",
  "Aspire Rural Health System", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "SYSTEM PARENT (§7), general knowledge: Aspire Rural Health System is the Thumb-region system formed by Hills & Dales General Hospital (CCN 231316), Marlette Regional Hospital (231330) and Deckerville Community Hospital (231311); not enrolled under its own name.",
  "MyMichigan Health Foundation", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "HOSPITAL FOUNDATION (§7): the foundation of a NAMED health system, MyMichigan Health (MyMichigan Medical Centers on CMS's MI enrolment); a hospital's fundraising arm is the hospital's.",
  "Bronson Health Foundation", 1L, "HOSPITAL_OR_SYSTEM", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "HOSPITAL FOUNDATION (§7): the foundation of a NAMED health system, Bronson (Bronson Methodist, Battle Creek, LakeView and South Haven hospitals on CMS's MI enrolment).",
  # --- names that read as hospitals and are not enrolled as one ------------
  "Drummond Island Medical Center", 1L, "NONPROFIT_CBO", "LOW", NA_character_, NA_character_,
    "NOT A HOSPITAL ROW: the §8 name rule read 'Medical Center' as a hospital, but no hospital on CMS's MI enrolment carries the name (Drummond Island has no inpatient hospital); MDHHS states no form, so §8's standing fallback (Texas's no-enrolment precedent, session 103).",
  # --- hospital-governed, flow unresolved (MI_MHA_FLOW's shape) -------------
  "Upper Peninsula Health Care Solution, Inc.", 1L, "HOSPITAL_AFFILIATED_ENTITY", "LOW", "GENERAL_KNOWLEDGE", NA_character_,
    "HOSPITAL-GOVERNED ENTITY, general knowledge: a shared-services network owned by Upper Peninsula hospitals, not itself enrolled as a hospital. MDHHS publishes no description, so nothing states that the money is administered to member hospitals (§10.2's association row): PASS_THROUGH_UNRESOLVED + Unclear, MHA's treatment."
)

#' Apply MI_S112_TYPINGS and carry session 49's verified typing onto added
#' rows that print an already-verified string (MCRH, MPCA, MHA ...).
mi_s112_type <- function(recs, raw) {
  recs$basis_type <- NA_character_
  added <- raw$roster_status == "ADDED_1001"
  for (i in seq_len(nrow(MI_S112_TYPINGS))) {
    t <- MI_S112_TYPINGS[i, ]
    hit <- added & recs$awardee == t$awardee
    if (sum(hit) != t$n) {
      stop("[MI] MI_S112_TYPINGS expects ", t$n, " added row(s) for '",
           t$awardee, "'; found ", sum(hit), ".", call. = FALSE)
    }
    recs$recipient_type[hit] <- t$recipient_type
    recs$determination_confidence[hit] <- rhtp_confidence_ceiling(t$confidence)
    recs$basis_type[hit] <- t$basis_type
    recs$ccn[hit] <- t$ccn
    recs$recipient_type_rule[hit] <- "HAND_READ_S112"
    hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
    aff  <- t$recipient_type == "HOSPITAL_AFFILIATED_ENTITY"
    recs$flow_type[hit] <- if (hosp) "DIRECT" else if (aff) "PASS_THROUGH_UNRESOLVED" else "NON_HOSPITAL"
    recs$distributed_to_hospital[hit] <- if (hosp) "Yes" else if (aff) "Unclear" else "No"
    recs$hospital_attribution[hit] <- if (hosp) "NAMED_HOSPITAL" else "NOT_HOSPITAL"
    recs$hospital_benefiting[hit] <- NA_character_
    recs$intermediary_name[hit] <- NA_character_
    recs$flag_reason[hit] <- if (aff) "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED" else
      if (is.na(t$basis_type)) "RECIPIENT_TYPE_INFERRED" else NA_character_
    recs$determination_basis[hit] <- paste0(
      "TYPED SESSION 112 (", t$recipient_type, ", ", t$confidence,
      if (!is.na(t$basis_type)) paste0(", ", t$basis_type) else "", "): ",
      t$why, if (hosp) " §10.2 DIRECT: the recipient is the hospital or system." else "")
  }

  # Session 49's verified answers, carried by EXACT string onto added rows.
  # The MHA spelling without "(MHA)" is the same association and takes the
  # same answer (alias). Flow is NOT re-run: none of these crosses §10.2's
  # DIRECT test, and MHA's flow stays MI_MHA_FLOW's (PASS_THROUGH_UNRESOLVED).
  ch <- suppressMessages(readr::read_csv(
    here::here("data", "reference", "verification_queue_2_changes.csv"),
    col_types = readr::cols(.default = "c"), progress = FALSE))
  ch <- ch[ch$file == "mi_year1_awardees.csv", ]
  alias <- c("Michigan Health and Hospital Association" =
               "Michigan Health and Hospital Association (MHA)")
  look <- ifelse(recs$awardee %in% names(alias), alias[recs$awardee], recs$awardee)
  typed <- recs$awardee %in% MI_S112_TYPINGS$awardee
  for (r in which(added & !typed & look %in% ch$name)) {
    v <- ch[ch$name == look[r], ][1, ]
    recs$recipient_type[r] <- v$new_type
    recs$determination_confidence[r] <- rhtp_confidence_ceiling(v$new_conf)
    recs$basis_type[r] <- v$basis_type
    recs$recipient_type_rule[r] <- "CARRIED_S49"
    fr <- setdiff(stats::na.omit(strsplit(dplyr::coalesce(recs$flag_reason[r], ""),
                                          ";", fixed = TRUE)[[1]]),
                  c("RECIPIENT_TYPE_INFERRED", ""))
    recs$flag_reason[r] <- if (length(fr)) paste(fr, collapse = ";") else NA_character_
    recs$determination_basis[r] <- paste0(
      "TYPE CARRIED FROM SESSION 49'S VERIFICATION OF THE SAME ",
      if (look[r] != recs$awardee[r]) "ORGANISATION ('" else "STRING ('",
      look[r], "', ", v$new_type, ", ", v$basis_type, "): ", v$basis,
      " Flow as built: ", recs$determination_basis[r])
  }
  recs
}


#' SESSION 112: carry the 10-01 row shift into session 49's overlay
#'
#' `verification_queue_2_changes.csv` keys Michigan's 86 verified answers on
#' the ROW INDEX of the 145-row file. Seven rows left the roster (three of them
#' carried a verified answer: rows 104, 107 and 112), so every row after 102
#' moves up. This rewrites ONLY the Michigan lines, ONLY their `row` field, as
#' raw text (the file is never round-tripped through readr), and deletes the
#' lines of rows that left. Alaska's session-99 re-key is the precedent.
#'
#' IDEMPOTENT: a line is re-keyed only where its `name` is the awardee of its
#' row in the OLD order; a line already naming the awardee of its row in the
#' NEW order is left alone; a line that is neither stops.
mi_s112_rekey_overlay <- function(write = FALSE) {
  path <- here::here("data", "reference", "verification_queue_2_changes.csv")
  lines <- readLines(path, warn = FALSE)
  ch <- suppressMessages(readr::read_csv(path, col_types = readr::cols(.default = "c"),
                                         progress = FALSE))
  is_mi <- grepl("^mi_year1_awardees\\.csv,[0-9]+,", lines)
  mi <- ch[ch$file == "mi_year1_awardees.csv", ]
  if (sum(is_mi) != nrow(mi)) {
    stop("[MI] the changes CSV has a multi-line Michigan record; re-key by hand.",
         call. = FALSE)
  }
  base <- mi_roster_committed_order()
  cur <- mi_roster_in_file_order()
  new_of_old <- match(base$row_0924, cur$row_0924)   # NA = dropped
  old_row <- as.integer(mi$row)
  old_hit <- base$awardee[old_row] == mi$name
  new_hit <- !is.na(cur$awardee[old_row]) & cur$awardee[old_row] == mi$name
  moves <- old_hit & (is.na(new_of_old[old_row]) | new_of_old[old_row] != old_row)
  if (any(!old_hit & !new_hit)) {
    stop("[MI] overlay line(s) name neither the old nor the new row's awardee: ",
         paste(mi$name[!old_hit & !new_hit], collapse = "; "), call. = FALSE)
  }
  plan <- tibble::tibble(name = mi$name, old_row = old_row,
                         new_row = ifelse(moves, new_of_old[old_row], old_row),
                         action = dplyr::case_when(!moves ~ "UNCHANGED",
                                                   is.na(new_of_old[old_row]) ~ "DELETED_ROW_DROPPED",
                                                   TRUE ~ "REKEYED"))
  if (write && any(plan$action != "UNCHANGED")) {
    idx <- which(is_mi)
    for (i in seq_along(idx)) {
      if (plan$action[i] == "REKEYED") {
        lines[idx[i]] <- sub("^mi_year1_awardees\\.csv,[0-9]+,",
                             paste0("mi_year1_awardees.csv,", plan$new_row[i], ","),
                             lines[idx[i]])
      }
    }
    lines <- lines[-idx[plan$action == "DELETED_ROW_DROPPED"]]
    con <- file(path, "wb"); writeLines(lines, con, sep = "\n"); close(con)
  }
  plan
}

# -- assemble -----------------------------------------------------------------

#' The roster in the file's ROW ORDER
#'
#' SESSION 49's VERIFICATION OVERLAY IS KEYED ON (file, ROW INDEX), and MDHHS
#' inserts new rows MID-TABLE (its tables are alphabetical within a fund). Read
#' in page order, additions would shift existing rows and the overlay would
#' write verified types onto the WRONG organisations -- silently, because every
#' index still exists. So the file keeps its own order: the 139 rows of the
#' 2026-09-01 roster in that page's order, then the six 2026-09-24 additions
#' (sessions 64-111, rows 1-145), then session 112's additions in page order.
#'
#' SESSION 112: MDHHS's 10-01 roster DROPS rows, which appending cannot
#' express. Michigan claims the page is complete, so a row that leaves the page
#' leaves the file, and every later row moves up. The removal set is PINNED
#' (`MI_S112_DROPPED`): any other drop stops the build, because a removal is
#' read, never inferred. The row shift is carried into session 49's overlay by
#' re-keying `verification_queue_2_changes.csv` (`mi_s112_rekey_overlay()`),
#' Alaska's session-99 precedent; the overlay entries of dropped rows are
#' removed with them.
#'
#' Matching is a MULTISET on (initiative, awardee, amount, fund): the Community
#' Mental Health Association of Michigan held two awards at one amount.
mi_row_key <- function(d) paste(d$initiative, d$awardee, d$amount_raw,
                                d$award_fund, sep = " | ")
mi_occ_key <- function(d) {
  k <- mi_row_key(d)
  paste(k, stats::ave(seq_along(k), k, FUN = seq_along))
}

#' The 145-row file of sessions 64-111, in its own order (never re-derived
#' from the 09-24 page order, for the reason above).
mi_roster_committed_order <- function() {
  r0924 <- mi_roster_tables("roster_0924")
  prior <- mi_roster_tables("roster_prior")
  k0924 <- mi_occ_key(r0924); kp <- mi_occ_key(prior)
  gone <- setdiff(kp, k0924)
  if (length(gone)) {
    stop("[MI] the 09-01 roster is not contained in the 09-24 one: ",
         paste(utils::head(gone, 5), collapse = "; "), call. = FALSE)
  }
  new_i <- which(!k0924 %in% kp)
  out <- dplyr::bind_rows(r0924[match(kp, k0924), ], r0924[new_i, ])
  out$roster_status <- c(rep("PRIOR", length(kp)), rep("ADDED_0924", length(new_i)))
  out$row_0924 <- seq_len(nrow(out))
  out
}

# THE SEVEN ROWS MDHHS DROPPED BETWEEN "AUGUST 31" AND "OCTOBER 1, 2026"
# (session 112), as initiative | awardee | amount | fund. Six reappear under a
# new label at the SAME initiative, fund and amount (five AHEC regional centres
# now printed "Area Health Education Center (AHEC): ...", and the Community
# Mental Health Association of Michigan's Care Closer to Home award now printed
# with "(CMHA)"); Saginaw County Health Department's $100,000 left Workforce /
# Recruitment and a $100,000 row appears under Interoperability / Rural Access
# and Connectivity. None is MERGED with its look-alike here: the page dropped
# one string and printed another, and pairing them is a reading (§2), so each
# old row leaves and each new one is typed on its own string.
MI_S112_DROPPED <- c(
  "Workforce for Wellness Initiative | Mid-Central Regional Center (Area Health Education Center) | $400,000 | Rural Health Workforce Pipeline and Education Fund",
  "Workforce for Wellness Initiative | Northern Lower Regional Center (MidMichigan Health Services) | $315,000 | Rural Health Workforce Pipeline and Education Fund",
  "Workforce for Wellness Initiative | Saginaw County Health Department | $100,000 | Rural Provider Recruitment, Retention, and Capacity Fund",
  "Workforce for Wellness Initiative | Southeast Regional Center (Area Health Education Center) | $200,000 | Rural Health Workforce Pipeline and Education Fund",
  "Workforce for Wellness Initiative | Upper Peninsula Regional Center (Upper Great Lakes Family Health) | $185,000 | Rural Health Workforce Pipeline and Education Fund",
  "Workforce for Wellness Initiative | Western Regional Center (Area Health Education Center) | $400,000 | Rural Health Workforce Pipeline and Education Fund",
  "Care Closer to Home Initiative | Community Mental Health Association of Michigan | $1,000,000 | Advancing Rural Behavioral Health Blueprint"
)

#' The rows of the 145-row file that MDHHS's current roster no longer carries
mi_roster_dropped <- function() {
  base <- mi_roster_committed_order()
  cur <- mi_roster_tables("roster")
  base[!mi_occ_key(base) %in% mi_occ_key(cur), ]
}

mi_roster_in_file_order <- function() {
  cur <- mi_roster_tables("roster")
  base <- mi_roster_committed_order()
  kc <- mi_occ_key(cur); kb <- mi_occ_key(base)
  dropped <- base[!kb %in% kc, ]
  if (!setequal(mi_row_key(dropped), MI_S112_DROPPED) ||
      nrow(dropped) != length(MI_S112_DROPPED)) {
    stop("[MI] the rows dropped from the roster are not the seven pinned in ",
         "MI_S112_DROPPED: ", paste(utils::head(setdiff(mi_row_key(dropped),
         MI_S112_DROPPED), 5), collapse = "; "), ". A removal is read, never ",
         "inferred; read the page and re-plan the verification overlay.",
         call. = FALSE)
  }
  kept <- base[kb %in% kc, ]
  new_i <- which(!kc %in% kb)
  added <- cur[new_i, ]
  added$roster_status <- rep("ADDED_1001", nrow(added))
  added$row_0924 <- NA_integer_
  dplyr::bind_rows(kept, added)
}

#' The 231 Michigan Year 1 award actions, in the §8 union schema
rhtp_mi_year1_awardees <- function() {
  raw <- mi_roster_in_file_order()
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
      dplyr::case_when(
        raw$roster_status == "PRIOR" ~ paste0(". On the roster as of ",
          format(MI_STATED$roster_prior_as_of, "%Y-%m-%d"), ", ",
          format(MI_STATED$roster_0924_as_of, "%Y-%m-%d"), " and ",
          format(MI_STATED$roster_as_of, "%Y-%m-%d")),
        raw$roster_status == "ADDED_0924" ~ paste0(". ADDED to the roster between ",
          format(MI_STATED$roster_prior_as_of, "%Y-%m-%d"), " and ",
          format(MI_STATED$roster_0924_as_of, "%Y-%m-%d"), "; still on it as of ",
          format(MI_STATED$roster_as_of, "%Y-%m-%d")),
        TRUE ~ paste0(". ADDED to the roster between ",
          format(MI_STATED$roster_0924_as_of, "%Y-%m-%d"), " and ",
          format(MI_STATED$roster_as_of, "%Y-%m-%d"), " (session 112)")),
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
      TRUE ~ NA_character_)) %>%
    mi_s112_type(raw)
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
  for (nm in c("workforce_gfo_date", "roster_as_of", "roster_0924_as_of",
                "roster_prior_as_of")) {
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
    stop("[MI] the roster no longer carries its 'as of October 1, 2026' ",
         "date. A roster with no as-of date cannot be compared to a later one.",
         call. = FALSE)
  }
  if (!stringr::str_detect(mi_html_text("roster_0924"),
                           stringr::fixed(MI_ROSTER_0924_ASOF_SENTENCE))) {
    stop("[MI] the 09-24 roster archive no longer reads 'as of August 31, 2026'.",
         call. = FALSE)
  }
  # The prior roster is the baseline the six additions are measured from, and
  # its own date is what makes 'added between' a dated statement.
  if (!stringr::str_detect(mi_html_text("roster_prior"),
                           stringr::fixed(MI_ROSTER_PRIOR_ASOF_SENTENCE))) {
    stop("[MI] the prior roster archive no longer reads 'as of July 10, 2026'.",
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
  # SESSION 112: five MHA awards (three added "as of October 1, 2026", one
  # under a spelling without "(MHA)"). MHA's own $8.625 million footer
  # corroborates the ORIGINAL two only, which are the rows on the roster since
  # 2026-07-10; the three additions post-date that page.
  mha <- recs[grepl("^Michigan Health and Hospital Association", recs$awardee), ]
  if (nrow(mha) != 5L) {
    stop("[MI] expected MHA to hold exactly 5 awards; found ", nrow(mha), ".",
         call. = FALSE)
  }
  if (!all(mha$flow_type == "PASS_THROUGH_UNRESOLVED") ||
      !all(mha$distributed_to_hospital == "Unclear")) {
    stop("[MI] an MHA row has left MI_MHA_FLOW's PASS_THROUGH_UNRESOLVED + ",
         "Unclear without the queue question being answered.", call. = FALSE)
  }
  mha_all <- mha
  mha <- mha[grepl("On the roster as of 2026-07-10", mha$note, fixed = TRUE), ]
  if (any(mha_all$recipient_type == "HOSPITAL_OR_SYSTEM")) {
    stop("[MI] the Michigan Health & Hospital Association is typed as a ",
         "HOSPITAL. It is the state's hospital trade association (§10.2), and ",
         "typing it as a hospital publishes $",
         format(sum(mha$amount), big.mark = ","),
         " as direct hospital dollars on a name match.", call. = FALSE)
    }
  if (any(mha_all$hospital_attribution == "NAMED_HOSPITAL")) {
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
  if (nrow(named) != MI_S112_NAMED_BUILT) {
    stop("[MI] expected exactly ", MI_S112_NAMED_BUILT, " named-hospital award actions as built (before the overlays); found ",
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
  if (nrow(unresolved) != 6L) {
    stop("[MI] expected MHA's 5 rows and Upper Peninsula Health Care Solution to carry ",
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
  # SESSION 112: the queue row states the count on the 145-row roster it was
  # written for (84). The 10-01 roster changes that set; the queue is not
  # re-written from here, so the pinned figure is the one asserted and the
  # current count is reported (mi_report()).
  if (!grepl(as.character(MI_FORM_NOT_STATED_QUEUED_N), row$row_key, fixed = TRUE)) {
    stop("[MI] the queue row does not state ", MI_FORM_NOT_STATED_QUEUED_N,
         " rows; the queue and this file disagree.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.1: RCJ's candidates, re-derived from the record table every run
#'
#' 31 on the 2026-08-27 pull; the 2026-09-24 pull WITHDREW all 22 of the
#' SUBRECIPIENTS_AWARD and OPIOID_SETTLEMENT rows and added 140 (session 63).
#' Pass `rt = rhtp_record_table_live(include_withdrawn = TRUE)` to read the
#' withdrawn rows the 08-27 findings rest on.
mi_rcj_candidates <- function(rt = rhtp_record_table_live()) {
  rt %>%
    dplyr::filter(.data$state == "MI", .data$award_tier == "SUBAWARD") %>%
    dplyr::transmute(
      record_id = .data$record_id,
      change_status = .data$change_status,
      awardee = .data$awardee_name_clean,
      rcj_amount = .data$amount_announced,
      doc = .data$source_doc_title,
      group = dplyr::case_when(
        grepl("Budget Narrative", .data$source_doc_title) ~ "BUDGET_NARRATIVE",
        grepl("Subrecipients Award", .data$source_doc_title) ~ "SUBRECIPIENTS_AWARD",
        grepl("substance use", .data$source_doc_title, ignore.case = TRUE) ~ "OPIOID_SETTLEMENT",
        # session 63: RCJ now carries MDHHS's roster ONE ROW PER AWARD
        grepl("^MI - 2026 - RHTP Subrecipients$", .data$source_doc_title) ~ "SUBRECIPIENTS_ROSTER",
        # session 63: LEO allocations quoted in a newsletter / CMS visit piece
        grepl("September 2026 RHTP Newsletter|CMS\\) Visits Michigan", .data$source_doc_title) &
          grepl("Rural Prosperity|High-Speed Internet", .data$awardee_name_clean) ~ "LEO_ALLOCATION",
        grepl("community violence intervention", .data$source_doc_title,
              ignore.case = TRUE) ~ "CVI_STATE_GRANTS",
        grepl("Suicide Prevention Council", .data$source_doc_title) ~ "SUICIDE_COUNCIL",
        grepl("^South Dakota", .data$awardee_name_clean) ~ "WRONG_STATE_SD",
        TRUE ~ "UNCLASSIFIED"))
}

#' The roster rows MDHHS ADDED between the prior archive (2026-09-01, "as of
#' July 10") and the current one (2026-09-24, "as of August 31"), parsed as
#' Subrecipient | Award Amount | Fund. Nothing was removed. Since session 64
#' these six ARE in the file, as rows 140-145.
MI_LIVE_ROSTER_0924 <- file.path("data", "evidence", "MI",
                                 "2026-09-24_mi_rhtp_subrecipients.html")
mi_roster_rows_text <- function(path) {
  d <- xml2::read_html(path)
  r <- xml2::xml_find_all(d, "//table//tr")
  vapply(r, function(x) paste(stringr::str_squish(xml2::xml_text(
    xml2::xml_find_all(x, "./td|./th"))), collapse = " | "), character(1))
}
mi_live_roster_added <- function() {
  live <- mi_roster_rows_text(mi_path("roster_0924"))
  old <- mi_roster_rows_text(mi_path("roster_prior"))
  if (length(setdiff(old, live))) {
    stop("[MI] MDHHS's live roster (09-24) has DROPPED rows the award file ",
         "carries. Read it.", call. = FALSE)
  }
  add <- setdiff(live, old)
  parts <- stringr::str_split_fixed(add, " \\| ", 3)
  tibble::tibble(awardee = parts[, 1],
                 amount = as.numeric(gsub("[$,]", "", parts[, 2])),
                 fund = parts[, 3])
}

mi_assert_rcj_disposition <- function(recs) {
  cand <- mi_rcj_candidates()
  if (any(cand$group == "UNCLASSIFIED")) {
    stop("[MI] ", sum(cand$group == "UNCLASSIFIED"), " RCJ candidate(s) fall ",
         "into no disposition group. The candidate set has moved; read the ",
         "new documents before rebuilding.", call. = FALSE)
  }
  m <- mi_roster_match(cand, recs)
  added <- mi_live_roster_added()
  # Every RCJ roster row is either in the award file (name AND amount) or one
  # of the rows MDHHS added after the file's 2026-09-01 archive.
  ros <- cand[cand$group == "SUBRECIPIENTS_ROSTER", ]
  # SESSION 112: RCJ's 09-24 pull also carries rows MDHHS DROPPED on 10-01.
  drop <- mi_roster_dropped()
  stray <- ros[!m$in_file & !(paste(ros$awardee, ros$rcj_amount) %in%
                                c(paste(added$awardee, added$amount),
                                  paste(drop$awardee, mi_parse_amount(drop$amount_raw)))), ]
  if (nrow(stray)) {
    stop("[MI] ", nrow(stray), " RCJ roster row(s) match neither the award ",
         "file nor MDHHS's 09-24 additions: ",
         paste(stray$awardee, collapse = "; "), call. = FALSE)
  }
  # The LEO rows must be the roster's LEO allocations at RCJ's rounding.
  leo <- cand[cand$group == "LEO_ALLOCATION", ]
  leo_live <- added[grepl("^Michigan Department of Labor", added$awardee), ]
  for (i in seq_len(nrow(leo))) {
    unit <- if (grepl("High-Speed", leo$awardee[i])) "High Speed Internet" else "Rural Prosperity"
    tot <- sum(leo_live$amount[grepl(unit, leo_live$awardee)])
    if (abs(tot - leo$rcj_amount[i]) > 100000) {
      stop("[MI] RCJ's ", leo$awardee[i], " ($", leo$rcj_amount[i], ") no ",
           "longer rounds MDHHS's LEO allocation(s) ($", tot, ").", call. = FALSE)
    }
  }
  # And the state-money rows must NOT be on the roster at their own amounts.
  nr <- cand[cand$group %in% c("CVI_STATE_GRANTS", "SUICIDE_COUNCIL"), ]
  if (any(paste(nr$awardee, nr$rcj_amount) %in% paste(recs$awardee, recs$amount))) {
    stop("[MI] a state-money candidate matches a roster row on both name ",
         "AND amount. It may be RHTP after all; read it.", call. = FALSE)
  }
  invisible(cand)
}

#' RCJ's roster rows against the award file, as a MULTISET on (name, amount):
#' an organisation may hold two awards at one amount (the Community Mental
#' Health Association of Michigan does), and each file row is used once.
mi_roster_match <- function(cand, recs) {
  ros <- cand[cand$group == "SUBRECIPIENTS_ROSTER", ]
  key_r <- paste(ros$awardee, ros$rcj_amount)
  key_f <- paste(recs$awardee, recs$amount)
  seen <- stats::ave(seq_along(key_r), key_r, FUN = seq_along)
  avail <- table(key_f)
  in_file <- seen <= dplyr::coalesce(as.integer(avail[key_r]), 0L)
  used <- table(key_r[in_file])
  miss <- stats::ave(seq_along(key_f), key_f, FUN = seq_along) >
    dplyr::coalesce(as.integer(used[key_f]), 0L)
  list(in_file = in_file,
       file_not_in_rcj = paste0(recs$awardee[miss], " $",
                                formatC(recs$amount[miss], format = "f",
                                        digits = 0, big.mark = ",")))
}

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
  cand <- mi_rcj_candidates()
  gone <- mi_rcj_candidates(rhtp_record_table_live(include_withdrawn = TRUE))
  gone <- gone[gone$change_status == "WITHDRAWN", ]
  m <- mi_roster_match(cand, recs)
  ros <- cand[cand$group == "SUBRECIPIENTS_ROSTER", ]
  infile <- ros[m$in_file, ]
  drop <- mi_roster_dropped()
  ros_drop <- ros[!m$in_file & paste(ros$awardee, ros$rcj_amount) %in%
                    paste(drop$awardee, mi_parse_amount(drop$amount_raw)), ]
  added <- mi_live_roster_added()
  n_of <- function(g) sum(cand$group == g)
  amt_of <- function(g) sum(cand$rcj_amount[cand$group == g])
  money <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
  leo <- cand[cand$group == "LEO_ALLOCATION", ]

  out <- tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount_sum, ~disposition, ~why,
    ~disqualifying_evidence, ~state_source_url, ~source_archive_path,

    "Real awards from MDHHS's roster, one row per AWARD, in mi_year1_awardees.csv",
    nrow(infile), sum(infile$rcj_amount), "RHTP_SUBAWARD_IN_FILE",
    paste0(
      nrow(infile), " candidates under 'MI - 2026 - RHTP Subrecipients' match ",
      "a row of the award file on name AND amount, counted as a multiset. ",
      "RCJ now carries MDHHS's roster ONE ROW PER AWARD. On the 2026-08-27 pull ",
      "it carried one row per ORGANISATION ('RHTP Subrecipients Award', ",
      sum(gone$group == "SUBRECIPIENTS_AWARD"), " rows, deflating Michigan by ",
      "$7,833,333) and RCJ WITHDREW all of those on 2026-09-24. The file was ",
      "re-extracted in session 64 from MDHHS's 2026-09-24 roster ('as of August ",
      "31, 2026'), which ADDED ", nrow(added), " rows ($", money(sum(added$amount)),
      ", every one to a Michigan STATE AGENCY as a subrecipient) to the ",
      "139-row roster of 2026-09-01, and the Michigan Veterans Affairs Agency ",
      "(MVAA) $2,000,000 row is the one RCJ carries. Session 112 re-extracted ",
      "it from the 2026-11-02 roster ('as of October 1, 2026'): ",
      sum(grepl("(session 112)", recs$note, fixed = TRUE)), " rows ADDED (the ",
      "file's last rows; RCJ's 2026-09-24 pull predates them) and ",
      nrow(drop), " DROPPED (next group). RCJ still lacks ", length(m$file_not_in_rcj),
      " of the file's ", nrow(recs), " award actions: ",
      paste(m$file_not_in_rcj, collapse = "; "),
      ". Every row in mi_year1_awardees.csv is built from MDHHS's page, never ",
      "from RCJ (§0.1)."),
    "name and amount identical to the MDHHS roster row",
    paste0(MI_RHTP, "/rhtp-subrecipients"),
    file.path("data", "evidence", "MI", mi_source("roster", "file")),

    "Roster rows MDHHS DROPPED between 'August 31' and 'October 1, 2026'",
    nrow(ros_drop), sum(ros_drop$rcj_amount), "RHTP_SUBAWARD_DROPPED_FROM_ROSTER",
    paste0(
      nrow(ros_drop), " candidates under 'MI - 2026 - RHTP Subrecipients' match, ",
      "on name AND amount, a row of MDHHS's 2026-09-24 roster ('as of August 31, ",
      "2026') that the 2026-11-02 roster ('as of October 1, 2026') no longer ",
      "prints: ", paste0(ros_drop$awardee, " $", money(ros_drop$rcj_amount),
                         collapse = "; "),
      ". MDHHS claims the roster is complete, so those rows left ",
      "mi_year1_awardees.csv in session 112. Five AHEC regional centres and the ",
      "Community Mental Health Association of Michigan reappear under new labels ",
      "at the same initiative, fund and amount; those are typed on their new ",
      "strings, never merged by this file (§2)."),
    "the string is not on MDHHS's 2026-11-02 roster",
    paste0(MI_RHTP, "/rhtp-subrecipients"),
    file.path("data", "evidence", "MI", mi_source("roster", "file")),

    "LEO allocations quoted at a rounded or combined figure",
    n_of("LEO_ALLOCATION"), amt_of("LEO_ALLOCATION"), "RHTP_SUBAWARD",
    paste0(
      "Real allocations to the Michigan Department of Labor and Economic ",
      "Opportunity (a STATE AGENCY receiving RHTP money as a subrecipient, not ",
      "the grantor), IN the file since session 64 at MDHHS's own grain, and ",
      "carried by RCJ at a coarser one (§6.1 mode 4): ",
      paste0("'", leo$awardee, "' $", money(leo$rcj_amount), " from '", leo$doc,
             "'", collapse = "; "), ". MDHHS's roster prices LEO's High Speed ",
      "Internet Office at $",
      money(sum(recs$amount[grepl("^Michigan Department of Labor.*High Speed", recs$awardee)])),
      " and its Office of Rural Prosperity at ",
      paste0("$", money(recs$amount[grepl("^Michigan Department of Labor.*Rural Prosperity", recs$awardee)]),
             collapse = " + "),
      " -- RCJ's Rural Prosperity figure is those rows summed and rounded, so ",
      "neither RCJ row matches a file row on (name, amount) and neither is ",
      "counted as in the file. An interagency allocation; never a hospital dollar."),
    "roster: $9,104,425; $16,130,623 + $600,000",
    paste0(MI_RHTP, "/rhtp-subrecipients"),
    file.path("data", "evidence", "MI", mi_source("roster", "file")),

    "State Of Michigan RHTP Budget Narrative line items",
    n_of("BUDGET_NARRATIVE"), amt_of("BUDGET_NARRATIVE"),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste(
      "Genuinely RHTP and one tier too high (§0.2, Oklahoma's defect). These",
      "are planning figures out of Michigan's own RHTP Budget Narrative, not",
      "award actions. Four of the nine names do later appear on the roster as",
      "real awardees AT DIFFERENT AMOUNTS -- Berrien County Health Department",
      "is $150,000 in the narrative and holds $150,000 + $100,000 on the",
      "roster -- and five appear nowhere on it at all, including 'Northern",
      "Michigan Center for Rural Health (Technical Assistance for Hubs)' and",
      "'Thumb Alliance - Sanilac County Health Department', which are project",
      "labels rather than the recipient names MDHHS awarded under."),
    "budget-narrative planning figures, not award actions",
    MI_RHTP, file.path("data", "evidence", "MI", mi_source("program", "file")),

    "MDHHS community violence intervention grants -- urban, not RHTP",
    n_of("CVI_STATE_GRANTS"), amt_of("CVI_STATE_GRANTS"),
    "NOT_RHTP_STATE_PROGRAM",
    paste(
      "MDHHS's 2026-09-21 release awards '$1.5 million to five organizations'",
      "for firearm-violence intervention in Flint, Lansing, Saginaw, Benton",
      "Harbor and Detroit, $300,000 each for 2026-09-01 to 2028-09-30. The",
      "words 'Rural Health Transformation', 'RHTP' and 'rural' occur ZERO",
      "times in it. RCJ files four of the five as Michigan RHTP Tier 3",
      "candidates (§0.1 mode 1, wrong programme) -- the successor to the",
      "opioid-settlement release whose eight rows RCJ withdrew on this pull."),
    "\"has awarded $1.5 million to five organizations through a competitive grant process\"",
    "https://www.michigan.gov/mdhhs/inside-mdhhs/newsroom/2026/09/21/cvi-grants",
    "data/evidence/recheck/2026-09-24/MI/2026-09-21_mi_mdhhs_cvi_grants.html",

    "University of Michigan Injury Prevention Center -- Suicide Prevention Council",
    n_of("SUICIDE_COUNCIL"), amt_of("SUICIDE_COUNCIL"),
    "NOT_RHTP_STATE_PROGRAM",
    paste(
      "The Michigan Suicide Prevention Council Report's own funding table:",
      "'The State of Michigan appropriated $125,000 in funding to establish the",
      "Michigan Suicide Prevention Council', of which $100,000 is a line, and",
      "it thanks the University of Michigan Injury Prevention Center for",
      "project management. A state appropriation; RHTP is not mentioned."),
    "\"The State of Michigan appropriated $125,000 in funding\"",
    "https://www.michigan.gov/mdhhs/inside-mdhhs/newsroom/2026/09/16/suicide-prevention",
    "data/evidence/recheck/2026-09-24/MI/2026_mi_suicide_prevention_council_report.pdf",

    "'South Dakota (Rural Strong grants)' from a multi-state digest",
    n_of("WRONG_STATE_SD"), amt_of("WRONG_STATE_SD"),
    "WRONG_STATE_SOUTH_DAKOTA_FILED_UNDER_MICHIGAN",
    paste(
      "§0.1 failure mode 6. South Dakota's $31.5M Rural Strong round,",
      "filed under Michigan because the digest it came from is filed there;",
      "pinned by record id in R/02c's sweep (session 62). South Dakota's own",
      "two releases name nobody (R/03j)."),
    "the awardee names another state",
    "https://news.sd.gov/",
    "data/evidence/SD/announcements"
  )
  if (sum(out$rcj_rows) != nrow(cand) || any(cand$group == "UNCLASSIFIED")) {
    stop("[MI] the disposition covers ", sum(out$rcj_rows), " of ", nrow(cand),
         " live candidates.", call. = FALSE)
  }
  rhtp_assert_disposition_prose(out, "MI")
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
    "MICHIGAN -- RHTP YEAR 1 SUBRECIPIENTS. 231 award actions, $161,740,847",
    "(roster 'as of October 1, 2026', session 112). Rows 1-138 are the 145-row",
    "'August 31' roster less seven rows MDHHS dropped; rows 139-231 are the 93",
    "awards it added. Read note for when each row appeared.",
    "",
    "MDHHS CLAIMS THIS ROSTER IS COMPLETE, which no other state file here can",
    "say: its programme page reads \"MDHHS maintains a dedicated webpage",
    "featuring all RHTP Subrecipients\". So this is a TOTAL and not a floor --",
    "for as long as that sentence is on the page, which an assertion checks.",
    "",
    "THE AMOUNTS ARE NOT FINAL. Every one is \"contingent upon review by",
    "Centers for Medicare & Medicaid Services (CMS) for final approval\", so",
    "every row is amount_confirmed = No. The recipients ARE confirmed.",
    "",
    "THIS SHEET IS THE BUILD, BEFORE SESSIONS 49 AND 71'S OVERLAYS. The",
    "committed CSV carries them: 24 named-hospital award actions, $15,654,777",
    "(LOW / general knowledge $6,687,197; academic health centre $6,625,656).",
    "Michigan's recipients are mostly health departments, community action",
    "agencies, FQHCs, Area Agencies on Aging, universities and tribal",
    "governments, and much of its hospital-facing money runs through the MICHIGAN",
    "HEALTH & HOSPITAL ASSOCIATION -- $13,125,000 across five awards, §10.2's",
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

  cat("\nTHE HOSPITAL FIGURE AS BUILT (the committed CSV carries the overlays)\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(rhtp_hospital_dollar_partition(recs)))
  cat("\n  Michigan publishes an amount on every row and almost none of it\n")
  cat("  reaches a named hospital. Its hospital-facing money runs through\n")
  cat("  the MICHIGAN HEALTH & HOSPITAL ASSOCIATION: $",
      format(sum(recs$amount[grepl("^Michigan Health and Hospital", recs$awardee)]),
             big.mark = ","), " across ",
      sum(grepl("^Michigan Health and Hospital", recs$awardee)), " awards,\n", sep = "")
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

  cat("\n§0.1 -- RCJ'S 31 CANDIDATES\n"); cat(strrep("-", 74), "\n")
  disp <- mi_disposition_table(recs)
  for (i in seq_len(nrow(disp))) {
    cat(sprintf("  %3d  %-24s %s\n", disp$rcj_rows[i], disp$disposition[i],
                substr(disp$group[i], 1, 44)))
  }
  cat("\n  AND THIS ONE DEFLATES. RCJ keeps one row per ORGANISATION where\n")
  cat("  MDHHS publishes one per AWARD, so an extractor built from the\n")
  cat("  candidate list would have published $19,484,032 -- 28% of what\n")
  cat("  Michigan has awarded -- with $2,214,846 of OPIOID SETTLEMENT money\n")
  cat("  mixed into it.\n")

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
  cat("  candidates are its recipients.\n")

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
  if ("--rekey-overlay" %in% args) print(as.data.frame(mi_s112_rekey_overlay(write = TRUE)))
  if (!any(c("--fetch", "--validate", "--build", "--report", "--rekey-overlay") %in% args)) {
    cat("Usage: Rscript R/03v_mi_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report]\n")
  }
}

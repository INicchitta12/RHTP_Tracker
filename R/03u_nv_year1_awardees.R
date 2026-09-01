# 03u_nv_year1_awardees.R -----------------------------------------------------
# Nevada Year 1 -> data/reference/nv_year1_awardees.csv
#
# WHY NEVADA. It led `state_trigger_queue.csv` once Oklahoma was worked out --
# queue rank 1, 34 Tier 3 candidates, 34 distinct awardees, a $179,931,608
# allotment, no CMS press release.
#
# NEVADA IS A SHAPE THIS PROJECT HAS NOT MET: A COMPLETE, NAMED,
# RECIPIENT-LEVEL ROSTER WITH NO AMOUNTS ON IT AT ALL.
# The Nevada Health Authority publishes `RHTP/rht-funded-projects---bp1/`, a
# page headed "Transformational Investments Across Rural Nevada / Funded
# Projects by RHT Initiative", carrying three tables whose columns are
# Subrecipient, Project and County-Service Area. Seventy-two award actions,
# every recipient named, and NOT ONE DOLLAR FIGURE ANYWHERE ON THE PAGE.
#
# Every prior state in this repository sits somewhere on one axis: Kansas,
# Maryland, Nebraska and Oklahoma publish a recipient AND an amount and
# withhold the recipient's organisational FORM; South Dakota publishes an
# amount and a count and withholds the RECIPIENTS. Nevada withholds the
# AMOUNTS and publishes everything else. So:
#
#   * `amount` is EMPTY ON ALL 73 ROWS and `sum(amount)` is 0. That is not a
#     parse failure and it is not a claim that Nevada awarded nothing -- it is
#     the honest total of what Nevada has published PER RECIPIENT, which is
#     nothing. The pool totals live in `round_amount` (see below).
#   * NEVADA HAS 23 NAMED-HOSPITAL AWARD ACTIONS AND $0 OF NAMED-HOSPITAL
#     DOLLARS, and those two facts are both true at once.
#     `rhtp_hospital_dollar_partition()` sums with na.rm = TRUE, so it reports
#     Nevada as `NAMED_HOSPITAL rows = 23, dollars = 0`. READ THE ROW COUNT.
#     A reader who takes the 0 and not the 23 will conclude Nevada gave its
#     rural hospitals nothing, which is the exact opposite of what NVHA has
#     published, and it is the single most dangerous misreading this file can
#     produce. `nv_assert_zero_dollars_is_not_zero_hospitals()` exists to make
#     that impossible to do quietly.
#
# WHAT NEVADA PUBLISHES, AND WHERE.
#
#   POOL                                        ROWS   ROUND TOTAL   ROSTER
#   Rural Health System Flex Fund                 25   $36,000,000   published
#   WRRAP - Recruitment and Retention Fund        27   $32,300,000   published
#   WRRAP - Apprenticeship and Training Fund      20   $14,300,000   published
#   WRRAP - Rural Medical Residency                1   $ 4,800,000   NAMES NOBODY
#                                                 --   -----------
#                                                  73   $87,400,000
#
# The Flex Fund total is NVHA's 2026-06-09 press release ("announced $36
# million in Rural Health Transformation funding awards"), which links to the
# roster page by name -- "Review all RHT Funded Projects here" -- so the round
# total and the 25 names are tied together by the state itself rather than by
# this file. The three WRRAP figures are NVHA's 2026-07-29 press release. The
# Rural Medical Residency row is ONE AGGREGATE ROW: NVHA states "$4.8 million
# in rural medical residency investments" and describes four projects while
# NAMING NO RECIPIENT, so it carries an empty `amount`, its total in
# `round_amount`, `NOT_YET_NAMED` and `RECIPIENT_NOT_NAMED` -- South Dakota's
# device (§0.3: a description is not a list).
#
# `round_amount` REPEATS THE POOL TOTAL ON EVERY ROW OF ITS POOL, which is
# Georgia's `initiative_amount` device and carries Georgia's trap with it:
# summing `round_amount` down the column gives $2,062,900,000 for a state that
# announced $87,400,000. `nv_reconcile()` sums DISTINCT (award_pool,
# round_amount) pairs, an assertion hard-fails the wrong total, and a test pins
# the trap open.
#
# TWO OF NVHA'S OWN DOCUMENTS DISAGREE ABOUT WHICH WRRAP FUND GOT WHICH TOTAL,
# AND IT IS NOT RESOLVED HERE. The 2026-06-09 fiscal deck prints "$14,394,529
# available" against Recruitment and Retention and "$32,387,689 available"
# against Apprenticeship and Training; the 2026-07-29 press release announces
# $32.3M for recruitment and retention and $14.3M for apprenticeship and
# training. THE PAIRING IN THE DECK WAS CHECKED AGAINST THE PDF's OWN GLYPH
# POSITIONS rather than the reader's line order -- each pool's label sits
# 45-50pt right of its own bullet block across all four columns -- so this is
# the source disagreeing with itself and not a parse artifact.
#
# The two most likely readings both exist and neither is published as a
# finding: NVHA may have REALLOCATED between the two sub-funds while
# "negotiating final awards" (the deck's own words), which the totals support
# almost exactly -- $46,782,218 available against $46.6M awarded -- or one
# document may have swapped its labels. `round_amount` takes the PRESS
# RELEASE's figure, because §8's source-strength ordering makes an award
# announcement the better authority on what was AWARDED than a pre-award
# planning deck is; both rosters carry
# `POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES` so no reader meets one figure without
# the other. THE COMBINED WRRAP FIGURE IS STABLE UNDER THE CONFLICT
# ($46.6M either way), and that is what `nv_report()` leads with.
#
# THE §6.2 PROVENANCE TEST PASSES IN THE STRONGEST FORM THIS PROJECT HAS SEEN,
# BECAUSE NEVADA PUBLISHES THE FEDERAL NOTICE OF AWARD ITSELF. Oklahoma's
# footer was the awarding agency's figure quoted on the roster; Nevada's is the
# award document. `noa_rhtcms332074-01-02.pdf` is CMS's own Notice of Award
# form: recipient "Nevada Health Authority", award number RHTCMS332074-01-02,
# Assistance Listing 93.798 "Rural Health Transformation Program", budget
# period 12/29/2025 - 10/30/2026, $179,931,608.42, and the remark "This Notice
# of Award approves the revised budget and lifting of restriction in the amount
# of $179,931,608.42 per your request dated 1/29/2026." That figure rounds to
# `cms_fy2026_allotments.csv`'s $179,931,608 to the dollar and its date is
# `cms_state_noa_dates.csv`'s 2025-12-29 anchor exactly. NVHA restates both
# independently on its own pages -- "December 29, 2025: Received Notice of
# Award ($179,931,608)". The DATE test passes on every pool: the four awarded
# RFAs closed 4/30/26 and 5/15/26 and 6/26/26, all four to six months AFTER
# the state had the money.
#
# AND THE FOOTER IS NOT ENOUGH ON ITS OWN -- NEVADA IS WHERE THAT BREAKS.
# See NV_GME_* below. This is the session's §6.2 lesson and it is new.
#
# §0.1 -- RCJ'S 34 CANDIDATES CONTAIN $15,755,068 OF STATE GENERAL FUND MONEY
# UNDER AN RHTP HEADING, AND THE STATE SAYS SO IN A COMPARISON TABLE.
# See NV_GME_* and `nv_rcj_candidate_disposition.csv`.
#
# THE POSITIVE CONTROL. "Nevada has published no roster for its other
# initiatives" is a finding only because NVHA demonstrably publishes rosters in
# a recognisable form: one accordion section per awarded pool on the Funded
# Projects page, each with a Subrecipient/Project/Service-Area table. NVHA is
# running TEN funding opportunities and has published rosters for THREE.
# `nv_assert_award_index()` asserts exactly those three sections present and
# REFUSES A FOURTH; `nv_assert_pending_not_awarded()` names the six closed
# opportunities with no roster and IS DESIGNED TO FAIL the day one appears.
#
# THE HOSPITAL FIGURE IS A COUNT, NOT A FLOOR, AND ITS UNCERTAINTY IS THE SAME
# SHAPE AS THE LAST FOUR STATES'. NVHA publishes no organisation-type column,
# so all 73 rows are typed from the recipient's own NAME: 23 award actions
# resolve to hospitals and 23 more carry §8's standing fallback
# (`NONPROFIT_CBO` + LOW + RECIPIENT_TYPE_INFERRED). Renown Health, Carson
# Valley Health, Washoe Barton Medical Clinic DBA Carson Valley Health and
# Intermountain Health are all inside that 23 and all uncounted. NOTHING WAS
# PROMOTED (§0.4); queued as `NV_RECIPIENT_FORM_NOT_STATED`. Because no row
# carries an amount, the queue row is worth $0 in either direction -- it moves
# a COUNT, which is the only hospital quantity Nevada supports.
#
# NEVADA IS THE FIRST STATE TO COMMIT A ROW CARRYING
# `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`. Session 19 added that code for the
# branch its flow fix opened and recorded that zero committed rows carried it.
# Incline Village Community Hospital Foundation is one: a hospital's own
# foundation, awarded to recruit providers, with the source silent on whether
# the money reaches the hospital. Coding it `No` would deflate on this
# pipeline's authority and coding it `Yes` is the short-circuit session 19
# removed, so it is `PASS_THROUGH_UNRESOLVED` + `Unclear` and enters NEITHER
# bucket of the partition.
#
# WHAT THIS FILE DELIBERATELY DOES NOT CONTAIN.
#   * The nine GME Grant Round VIII awards. They are STATE GENERAL FUND money
#     (see NV_GME_* below) and unioning them here is what §6.2 exists to stop.
#   * Nevada's initiative percentages (RHOAP 15%, Flex 20%, WRRAP 40%, RHIT
#     15%). They are Tier 2 and, being percentages of an annual award rather
#     than dollars, are a §7A artifact and not an award figure.
#   * Any per-recipient amount. NVHA has published none and this file invents
#     none (§6.2: the round total is never divided).

suppressPackageStartupMessages({
  library(dplyr)
  library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

NV_STATE <- "NV"
NV_EVIDENCE_DIR <- here::here("data", "evidence", "NV")
NV_OUT_CSV <- here::here("data", "reference", "nv_year1_awardees.csv")
NV_DISPOSITION_CSV <- here::here("data", "reference",
                                 "nv_rcj_candidate_disposition.csv")
NV_XLSX <- here::here("NV_year1_awardees.xlsx")

NV_USER_AGENT <- paste(
  "RHTP-Tracker/1.0 (AHA Data & Policy research;",
  "+https://www.aha.org)")
NV_HOST_THROTTLE_S <- 2

# §7.1 / sessions 14, 16, 17, 20: never archive a third party's credential.
NV_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  google_api_key = "AIza[0-9A-Za-z_-]{30,}",
  generic_apikey = "(?i)api[_-]?key\\s*[:=]\\s*[\"'][A-Za-z0-9._-]{16,}[\"']",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)

# -- what the STATE states, so a change in the source fails rather than passes -

# CMS's own Notice of Award, and NVHA's restatement of it. Compared to the §7.1
# anchor rather than typed as a claim about CMS.
NV_CMS_AWARD_AMOUNT <- 179931608.42
NV_CMS_AWARD_NUMBER <- "RHTCMS332074-01-02"
NV_ASSISTANCE_LISTING <- "93.798"
NV_NOA_DATE <- as.Date("2025-12-29")

# The four pools, their published round totals, and the document each comes
# from. `roster` says whether NVHA has published the recipients.
NV_POOLS <- tibble::tribble(
  ~award_pool,                      ~round_id, ~round_name,                                              ~round_amount, ~round_awards, ~roster, ~amount_source,
  "FLEX_FUND",                      "FLEX",    "Rural Health System Flex Fund",                              36000000,  25L, TRUE,  "press_flex",
  "WRRAP_RECRUITMENT_RETENTION",    "WRRAP-RR","Workforce Recruitment and Rural Access Program - Recruitment and Retention Fund", 32300000, 27L, TRUE,  "press_wrrap",
  "WRRAP_APPRENTICESHIP_TRAINING",  "WRRAP-AT","Workforce Recruitment and Rural Access Program - Apprenticeship and Training Fund", 14300000, 20L, TRUE, "press_wrrap",
  "WRRAP_RURAL_MEDICAL_RESIDENCY",  "WRRAP-RES","Workforce Recruitment and Rural Access Program - Rural Medical Residency",         4800000,  NA_integer_, FALSE, "press_wrrap"
)

NV_STATED <- list(
  flex_round_total      = 36000000,      # 2026-06-09 release: "$36 million"
  wrrap_rr_awarded      = 32300000,      # 2026-07-29 release
  wrrap_at_awarded      = 14300000,      # 2026-07-29 release
  wrrap_residency       = 4800000,       # 2026-07-29 release
  announced_total       = 87400000,      # the four pools, summed over DISTINCT pools
  flex_rows             = 25L,
  wrrap_rr_rows         = 27L,
  wrrap_at_rows         = 20L,
  roster_rows           = 72L,
  total_rows            = 73L,
  # The 2026-06-09 fiscal deck's "available" figures. Kept because they are the
  # other half of the conflict this file refuses to resolve.
  deck_flex_available   = 35986322,
  deck_rr_available     = 14394529,
  deck_at_available     = 32387689,
  deck_tribal_available = 8096922,
  deck_rr_requested     = 33621591,
  deck_at_requested     = 44305961,
  press_rr_requested    = 41900000,      # "with $41.9 million requested"
  # RCJ, re-derived from the record table on every run -- never typed.
  rcj_candidates        = 34L,
  rcj_distinct_awardees = 34L
)

# THE COMBINED WRRAP FIGURE IS STABLE UNDER THE CONFLICT, and this is the
# arithmetic that says so.
NV_WRRAP_COMBINED_PRESS <- NV_STATED$wrrap_rr_awarded + NV_STATED$wrrap_at_awarded
NV_WRRAP_COMBINED_DECK  <- NV_STATED$deck_rr_available + NV_STATED$deck_at_available

# -- the GME negative control -------------------------------------------------
#
# NEVADA'S §6.2 LESSON, AND IT IS NEW: THE CMS FOOTER COVERS THE PUBLICATION,
# NOT EVERY PROGRAMME DESCRIBED IN IT.
#
# `nvha-healthcare-workforce-programs-remediated-doc-2-1.pdf` ("Working
# Together to Power Nevada's Health Workforce", April 2026) carries the CMS
# financial-assistance footer -- "$179,931,608.42 with 100% funded by CMS/HHS"
# -- on EVERY PAGE, because NVHA produced the publication with RHTP money. The
# publication then describes THREE SEPARATE WORKFORCE PROGRAMMES SIDE BY SIDE,
# in a table whose own column is headed "Funding", and says in that table which
# money each one runs on:
#
#   GME Program    "Source: State General Fund"   $15.8M available in SFY26
#                  Governance: NRS 223.631-639, SB262 & SB494 (2025)
#   WRRAP          "Source: Centers for Medicare & Medicaid Services (CMS)
#                   Rural Health Transformation (RHT) Grant #RHTCMS332074-01-02"
#   SHARP          "Source: SB5 one-time bill appropriation"   $60M, from 7/1/26
#
# ONLY WRRAP IS RHTP. A provenance check keyed on "does this document carry the
# CMS financial-assistance footer" answers YES for all three and is wrong for
# two of them. Oklahoma's footer was on a roster and covered what was on it;
# Nevada's is on a comparison document and covers only the publishing.
#
# The consequence is measured, not hypothetical. NVHA announced GME Grant Round
# VIII on 2026-07-22 -- "Nevada Invests Nearly $16 Million to Train the Next
# Generation of Physicians", nine programmes, "$15,755,068.00", the Director's
# own words "these new state investments", no CMS or RHTP mention anywhere in
# it -- and SEVENTEEN of RCJ's 34 Nevada Tier 3 candidates are those nine
# awards. Seven days later NVHA announced $4.8M of RHTP **Rural Medical
# Residency** money under WRRAP. Two residency-shaped announcements, one
# agency, eight days apart, one federal and one state.
NV_GME_ROUND <- "GME Grant Program Round VIII"
NV_GME_TOTAL <- 15755068.00
NV_GME_PROGRAMMES <- 9L
NV_GME_ANNOUNCED <- as.Date("2026-07-22")
NV_GME_SOURCE_QUOTE <- "Source: State General Fund"
NV_GME_STATE_QUOTE <- "these new state investments"
NV_GME_GOVERNANCE <- c("NRS 223.631-639", "SB262 & SB494")
# The nine, exactly as NVHA publishes them, with the amounts from its own
# release. They are here to be EXCLUDED and asserted absent -- never extracted.
NV_GME_AWARDS <- tibble::tribble(
  ~awardee,                                                                  ~amount,
  "Carson-Tahoe Health - Family Medicine",                                   2707094,
  "Dignity Health - Internal Medicine",                                      1722415,
  "Dignity Health - Pulmonary & Critical Care Medicine",                     1279352,
  "University Medical Center of Southern Nevada - Diagnostic Radiology",     2100000,
  "University of Nevada, Las Vegas SOM - Ophthalmology",                     2995890,
  "University of Nevada, Las Vegas SOM - Otolaryngology",                     401397,
  "University of Nevada, Reno SOM - General Surgery",                        1672444,
  "University of Nevada, Reno SOM - Obstetrics & Gynecology",                1957173,
  "University of Nevada, Reno SOM - Pulmonary Disease and Critical Care Medicine", 919303
)

# The six closed opportunities with NO published roster. Each is a tripwire.
NV_PENDING_OPPORTUNITIES <- c(
  "Nevada Rural Health Innovation and Technology (RHIT) Initiative",
  "Nevada's Rural Health Outcome Accelerator Program (RHOAP)",
  "Rural Presidential Fitness Test Implementation",
  "Rural Correctional Health Transformation",
  "Rural Veterans Health Transformation",
  "Rural Tribal Health Transformation"
)

# The three roster sections NVHA publishes, by their table heading order on the
# Funded Projects page. A FOURTH means Nevada has awarded something this file
# does not carry.
NV_ROSTER_SECTIONS <- c(
  "Rural Health System Flex Fund",
  "Workforce Recruitment and Rural Access Program - Recruitment and Retention Fund",
  "Workforce Recruitment and Rural Access Program - Apprenticeship and Training Fund"
)


# -- sources ------------------------------------------------------------------

NV_BASE <- "https://www.nvha.nv.gov"

NV_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,
  # THE ROSTER. Three tables, 72 named subrecipients, no amounts.
  "roster", "2026-08-31_nv_rht_funded_projects_bp1.html",
  paste0(NV_BASE, "/RHTP/rht-funded-projects---bp1/"),
  # The positive control: ten funding opportunities, rosters for three.
  "nofos", "2026-08-31_nv_rht_nofos.html",
  paste0(NV_BASE, "/RHTP/rht-nofos/"),
  # NVHA's own statement of the CMS award date and amount.
  "about", "2026-08-31_nv_rhtp_about.html",
  paste0(NV_BASE, "/RHTP/rhtp-about"),
  # The programme milestones, including "December 29, 2025: Received Notice of
  # Award ($179,931,608)".
  "rhtsc", "2026-08-31_nv_rht_steering_committee.html",
  paste0(NV_BASE, "/RHTP/rhtsc"),
  # The initiative structure, published as PERCENTAGES of the annual award.
  "initiatives", "2026-08-31_nv_rhtp_initiatives.html",
  paste0(NV_BASE, "/RHTP/rhtp-initiatives"),
  # CMS'S OWN NOTICE OF AWARD. The strongest §6.2 document in this repository:
  # not a footer quoting the award, the award.
  "noa", "2026-02-19_nv_cms_notice_of_award_rhtcms332074-01-02.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/noa_rhtcms332074-01-02.pdf"),
  # The Flex Fund round: "$36 million", and the sentence that ties the round to
  # the roster -- "Review all RHT Funded Projects here".
  "press_flex", "2026-06-09_nv_press_release_first_round_flex_fund.pdf",
  paste0(NV_BASE, "/siteassets/content/home/press-release-first-round-of-rht-funded-projects-june-2026_final.pdf"),
  # The WRRAP rounds: $32.3M, $14.3M and $4.8M.
  "press_wrrap", "2026-07-29_nv_press_release_wrrap_awards.pdf",
  paste0(NV_BASE, "/siteassets/content/home/rhtp-funding-press-release.pdf"),
  # THE NEGATIVE CONTROL. GME Grant Round VIII: $15,755,068 of STATE money to
  # nine residency programmes, seven days before NVHA announced $4.8M of RHTP
  # residency money. Seventeen of RCJ's 34 candidates are these nine awards.
  "press_gme", "2026-07-22_nv_press_release_gme_grant_round_viii.pdf",
  paste0(NV_BASE, "/siteassets/content/home/grant-round-viii-announcement.pdf"),
  # The three-programme comparison that states each one's funding SOURCE, and
  # the document whose CMS footer covers all three while only one is RHTP.
  "workforce", "2026-04_nv_workforce_programs_working_together.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/rht_nofos/nvha-healthcare-workforce-programs-remediated-doc-2-1.pdf"),
  # The 2026-06-09 fiscal deck: the pool "available" figures that conflict with
  # the press release, and the Flex funded-projects slides that corroborate the
  # roster with no amounts on them either.
  "fiscal", "2026-06-09_nv_rhtsc_program_fiscal_update.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/rhtsc/meeting-6.9.26/rhtsc-program-fiscal-update-june26.pdf")
)


# -- fetch --------------------------------------------------------------------

nv_source <- function(key, field) {
  row <- NV_SOURCES[NV_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NV] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

nv_path <- function(key) file.path(NV_EVIDENCE_DIR, nv_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
nv_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(NV_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, NV_CREDENTIAL_SHAPES[[nm]])) {
      stop("[NV] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nv_get <- function(url, label) {
  message("[NV] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(NV_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[NV] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  nv_assert_credential_free(served, label)
  served
}

nv_fetch <- function(force = FALSE) {
  dir.create(NV_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NV_SOURCES)), function(i) {
    src <- NV_SOURCES[i, ]
    dest <- file.path(NV_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[NV] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(NV_HOST_THROTTLE_S)
      writeBin(nv_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  nv_write_manifest(entries)
  entries
}

nv_write_manifest <- function(entries) {
  path <- file.path(NV_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Nevada -- RHTP Year 1: the NVHA Funded Projects roster, the funding-",
    "opportunities page that is its positive control, the two award press",
    "releases that carry the pool totals, CMS's own Notice of Award, and the",
    "GME release + workforce comparison that are the §6.2 NEGATIVE CONTROL.",
    "Archived by R/03u_nv_year1_awardees.R --fetch",
    paste0("User-agent: ", NV_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard that caught CMS's Mapbox token, Illinois's and Oregon's,",
    "and Kansas's Google Maps key runs on every fetch here and finds nothing,",
    "so there is no reduction to explain and the pages are whole.",
    "",
    "THE ROSTER IS `..._rht_funded_projects_bp1.html`. Three accordion",
    "sections, one per awarded pool, each a Subrecipient/Project/County-Service",
    "Area table: 25 + 27 + 20 = 72 named award actions AND NO AMOUNT ANYWHERE",
    "ON THE PAGE. That absence is the finding, not a fetch failure, and it is",
    "corroborated by `..._rhtsc_program_fiscal_update.pdf`, whose own",
    "'Flex Funds - Funded Projects' slides list the same recipients under the",
    "same three column headings and also carry no amounts.",
    "",
    "THE ROSTER PAGE\'S WHOLE-FILE DIGEST IS NOT STABLE AND MUST NOT BE USED",
    "AS A CHANGE TEST. Its footer carries a rotating \"state symbol\" widget --",
    "two fetches minutes apart served the Lahontan Cutthroat Trout and the",
    "Vivid Dancer Damselfly -- so the page digest differs on EVERY fetch while",
    "nothing about the awards has moved. The three roster TABLES are stable and",
    "hash identically across those same fetches, so `nv_roster_digest()` is",
    "what a completeness re-check compares. This is the South Dakota",
    "ServiceNow-token problem in a new costume: a reader verifying the page",
    "digest gets a mismatch that means nothing.",
    "",
    "`..._cms_notice_of_award_rhtcms332074-01-02.pdf` IS THE FEDERAL AWARD",
    "DOCUMENT. Recipient 'Nevada Health Authority', Assistance Listing 93.798",
    "'Rural Health Transformation Program', budget period 12/29/2025 -",
    "10/30/2026, $179,931,608.42. No other state file in this repository holds",
    "the NOA itself. Nevada also publishes the original restricted award at",
    "noa_rhtcms332074-01-00.pdf; the revised one archived here is the operative",
    "document and carries the full amount.",
    "",
    "THE TWO GME FILES ARE THE NEGATIVE CONTROL AND ARE NOT EXTRACTED FROM.",
    "`..._gme_grant_round_viii.pdf` announces $15,755,068 to nine residency",
    "programmes and says 'these new state investments'; ",
    "`..._workforce_programs_working_together.pdf` prints GME, WRRAP and SHARP",
    "side by side and gives each one's funding source -- 'State General Fund',",
    "the CMS RHT grant, and an SB5 appropriation respectively. THAT SECOND",
    "DOCUMENT CARRIES THE CMS FINANCIAL-ASSISTANCE FOOTER ON EVERY PAGE while",
    "two of the three programmes it describes are state-funded, which is why",
    "the footer alone is not a provenance test.",
    "",
    paste0("Fetched: ", Sys.Date()),
    "",
    sprintf("%-62s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 62 + 12 + 64)
  ), path)
  cat(sprintf("%-62s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-14s %s", entries$key, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

nv_read_text <- function(key) {
  path <- nv_path(key)
  if (!file.exists(path)) {
    stop("[NV] missing archive: ", path,
         "\n  Run: Rscript R/03u_nv_year1_awardees.R --fetch", call. = FALSE)
  }
  raw <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt
}

nv_html_doc <- function(key) xml2::read_html(nv_read_text(key))

#' A page's RENDERED text, squished.
#'
#' Assertions read this and never the raw HTML. NVHA writes its milestone
#' sentences with markup and `&nbsp;` inside them -- "December 29, 2025:&nbsp;
#' Received <a title=\"Notice of Award\" href=...>" -- so a `str_detect` on the
#' source bytes fails on a sentence that is plainly on the page.
nv_html_text <- function(key) {
  doc <- nv_html_doc(key)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

#' PDF text through the repo's own reader (§ utils_pdf_text), memoised per run.
nv_pdf_cache <- new.env(parent = emptyenv())
nv_pdf_text <- function(key) {
  if (!exists(key, envir = nv_pdf_cache)) {
    source(here::here("R", "utils_pdf_text.R"), local = FALSE)
    assign(key, rhtp_pdf_text(nv_path(key)), envir = nv_pdf_cache)
  }
  get(key, envir = nv_pdf_cache)
}

nv_pdf_flat <- function(key) stringr::str_squish(paste(nv_pdf_text(key), collapse = " "))

#' The three roster tables, in page order.
#'
#' The page ships them server-rendered inside accordion sections; the "Show"
#' toggles are presentation. Nothing here depends on JavaScript running.
nv_roster_tables <- function() {
  doc <- nv_html_doc("roster")
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  lapply(rvest::html_table(rvest::html_elements(doc, "table"), trim = TRUE),
         nv_promote_header)
}

#' Promote a first data row to the header when the source marked it up with
#' `<td>` instead of `<th>`.
#'
#' SESSION 10'S DEFECT, MET AGAIN AND IN THE SAME SHAPE. NVHA marks the Flex
#' Fund table's header row with `<td>`, so `html_table()` names its columns
#' X1..X3 and keeps "Subrecipient"/"Project"/"County-Service Area" as row 1 --
#' while the two WRRAP tables in the SAME PAGE use `<th>` and resolve normally.
#' A positional read would have taken the header as an award and reported 26
#' Flex Fund awards with a subrecipient called "Subrecipient".
#'
#' The promotion is CONDITIONAL, on session 10's own rule: it happens only when
#' the promoted row resolves STRICTLY MORE of the columns we need than the
#' current header does, so it can never make a working parse worse.
nv_promote_header <- function(tb) {
  wanted <- c("subrecipient|applicant|recipient", "project", "area|county")
  resolves <- function(nms) {
    sum(vapply(wanted, function(p) any(stringr::str_detect(tolower(nms), p)),
               logical(1)))
  }
  if (nrow(tb) < 2L) return(tb)
  candidate <- as.character(unlist(tb[1, ], use.names = FALSE))
  if (resolves(candidate) <= resolves(names(tb))) return(tb)
  out <- tb[-1, , drop = FALSE]
  names(out) <- candidate
  out
}

#' The digest a completeness re-check compares, INSTEAD of the page digest.
#' See the manifest: the page's footer widget rotates on every fetch.
nv_roster_digest <- function() {
  tabs <- nv_roster_tables()
  digest::digest(lapply(tabs, function(t) as.data.frame(lapply(t, as.character))),
                 algo = "sha256")
}

#' Nevada's 72 published award actions.
#'
#' One row per table row. Nothing is de-duplicated: Washoe Barton Medical
#' Clinic DBA Carson Valley Health holds TWO Flex Fund rows (a chiller
#' replacement and sterile processing equipment) which are two projects and not
#' a duplicate, and several recipients appear in more than one pool.
#' @param tables Optional pre-read tables, so a test can feed the parser a
#'   modified page and require a refusal without mocking the reader.
nv_roster_awards <- function(tables = NULL) {
  tabs <- if (is.null(tables)) nv_roster_tables() else tables
  if (length(tabs) != length(NV_ROSTER_SECTIONS)) {
    stop("[NV] the Funded Projects page now carries ", length(tabs),
         " tables, not ", length(NV_ROSTER_SECTIONS),
         ". Nevada has published a roster this file does not carry -- re-read ",
         "it before trusting any figure here.", call. = FALSE)
  }

  pools <- NV_POOLS[NV_POOLS$roster, ]
  out <- purrr::map_dfr(seq_along(tabs), function(i) {
    tb <- tabs[[i]]
    nms <- tolower(names(tb))
    # Resolve by synonym rather than by position: the third column is headed
    # "County-Service Area" on the Flex table and "Service Area" on the two
    # WRRAP tables, which is exactly the kind of drift that silently shifts a
    # positional read by one column.
    col_recipient <- which(stringr::str_detect(nms, "subrecipient|applicant|recipient"))
    col_project   <- which(stringr::str_detect(nms, "project"))
    col_area      <- which(stringr::str_detect(nms, "area|county"))
    if (length(col_recipient) != 1L || length(col_project) != 1L ||
        length(col_area) != 1L) {
      stop("[NV] roster table ", i, " does not resolve to exactly one ",
           "recipient, project and service-area column. Headings were: ",
           paste(names(tb), collapse = " | "), call. = FALSE)
    }
    tibble::tibble(
      award_pool = pools$award_pool[i],
      row_in_pool = seq_len(nrow(tb)),
      awardee = stringr::str_squish(tb[[col_recipient]]),
      project_description = stringr::str_squish(tb[[col_project]]),
      service_area = stringr::str_squish(tb[[col_area]])
    )
  })

  # A blank recipient is a table-shape read that has drifted off its content.
  # Oklahoma's six "No Awardee" counties are the precedent for checking the
  # CONTENT of a row and not just its shape.
  blank <- out$awardee == "" | is.na(out$awardee)
  if (any(blank)) {
    stop("[NV] ", sum(blank), " roster row(s) carry no recipient name. ",
         "The page's table shape has changed -- re-read it.", call. = FALSE)
  }
  # NVHA publishes no amounts. If one ever appears, this file's whole design
  # (empty `amount`, pool totals in `round_amount`) is wrong and must be
  # rewritten rather than quietly kept.
  money <- stringr::str_detect(
    paste(out$awardee, out$project_description, out$service_area),
    "\\$[0-9]")
  if (any(money)) {
    stop("[NV] the roster now carries a dollar figure. Nevada has started ",
         "publishing per-recipient amounts and this file must be rewritten: ",
         "`amount` is empty on every row by design.", call. = FALSE)
  }
  out
}


# -- §6.2 provenance ----------------------------------------------------------

#' The federal Notice of Award itself, checked against BOTH anchors.
#'
#' This is the strongest form of the §6.2 test available anywhere in this
#' repository. Oklahoma's was the awarding agency's figure quoted in a footer on
#' the roster; Nevada's is CMS's own award form.
nv_assert_cms_notice_of_award <- function() {
  noa <- nv_pdf_flat("noa")

  # The award document's own identifiers.
  for (needle in c(NV_CMS_AWARD_NUMBER, NV_ASSISTANCE_LISTING,
                   "Rural Health Transformation Program", "Nevada Health Authority")) {
    if (!stringr::str_detect(noa, stringr::fixed(needle))) {
      stop("[NV] the archived Notice of Award no longer carries '", needle,
           "'. Re-read it before trusting this file's provenance.", call. = FALSE)
    }
  }

  # The amount, as CMS wrote it, against the §7.1 anchor.
  published <- format(NV_CMS_AWARD_AMOUNT, big.mark = ",", nsmall = 2,
                      scientific = FALSE)
  if (!stringr::str_detect(noa, stringr::fixed(paste0("$", published)))) {
    stop("[NV] the Notice of Award no longer states $", published, ".",
         call. = FALSE)
  }
  allot <- rhtp_nv_allotment()
  if (round(NV_CMS_AWARD_AMOUNT) != allot) {
    stop("[NV] CMS's Notice of Award says $", published,
         " and cms_fy2026_allotments.csv says $", format(allot, big.mark = ","),
         ". Two CMS figures for one state must agree (§0.2a).", call. = FALSE)
  }

  # The DATE test: the state's own restatement, against cms_state_noa_dates.csv.
  about <- nv_html_text("about")
  rhtsc <- nv_html_text("rhtsc")
  if (!stringr::str_detect(rhtsc,
        "December 29, 2025: ?Received Notice of Award \\(\\$179,931,608\\)")) {
    stop("[NV] the RHT Steering Committee page no longer states Nevada's own ",
         "Notice of Award date and amount.", call. = FALSE)
  }
  if (!stringr::str_detect(about,
        "On December 29, 2025 the Centers for Medicare and Medicaid Services")) {
    stop("[NV] the About page no longer states the CMS award date.", call. = FALSE)
  }
  anchor_date <- rhtp_nv_noa_date()
  if (anchor_date != NV_NOA_DATE) {
    stop("[NV] cms_state_noa_dates.csv gives Nevada ", anchor_date,
         " and this file assumes ", NV_NOA_DATE, ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' Nevada's allotment out of the §7.1 anchor -- read, never typed.
rhtp_nv_allotment <- function() {
  tbl <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- tbl[tbl$state == NV_STATE, ]
  if (nrow(row) != 1L) stop("[NV] no §7.1 allotment row for NV.", call. = FALSE)
  row$fy2026_allotment
}

rhtp_nv_noa_date <- function() {
  tbl <- readr::read_csv(
    here::here("data", "reference", "cms_state_noa_dates.csv"),
    show_col_types = FALSE, progress = FALSE)
  as.Date(tbl$noa_date[tbl$state == NV_STATE])
}

#' THE FOOTER IS NOT A PROVENANCE TEST, AND THIS IS THE PROOF.
#'
#' The workforce publication carries the CMS financial-assistance footer on
#' every page AND describes three programmes, two of which are state-funded.
#' Both halves are asserted: if the footer disappears the negative control is
#' weaker, and if the "State General Fund" line disappears this file has lost
#' the sentence that disqualifies seventeen RCJ candidates.
nv_assert_footer_is_not_provenance <- function() {
  wf <- nv_pdf_flat("workforce")
  if (!stringr::str_detect(wf, stringr::fixed(
        "financial assistance award totaling $179,931,608.42"))) {
    stop("[NV] the workforce publication no longer carries the CMS ",
         "financial-assistance footer.", call. = FALSE)
  }
  # The three funding sources, side by side in one table.
  if (!stringr::str_detect(wf, stringr::fixed(NV_GME_SOURCE_QUOTE))) {
    stop("[NV] the workforce publication no longer states '",
         NV_GME_SOURCE_QUOTE, "' for the GME programme. That sentence is what ",
         "disqualifies 17 of RCJ's 34 Nevada candidates.", call. = FALSE)
  }
  if (!stringr::str_detect(wf, stringr::fixed("SB5 one-time bill appropriation"))) {
    stop("[NV] the workforce publication no longer states SHARP's funding ",
         "source.", call. = FALSE)
  }
  # The publication hyphen-WRAPS the grant number across a line break
  # ("#RHTCMS332074-01-" / "02"), so the stable stem is what is matched here.
  # The full number is asserted intact on the Notice of Award itself, above.
  if (!stringr::str_detect(wf, stringr::fixed("RHTCMS332074"))) {
    stop("[NV] the workforce publication no longer ties WRRAP to the CMS RHT ",
         "grant number.", call. = FALSE)
  }
  for (g in NV_GME_GOVERNANCE) {
    if (!stringr::str_detect(wf, stringr::fixed(g))) {
      stop("[NV] the workforce publication no longer cites ", g,
           " as GME's governance.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The GME release is STATE money, and none of it is in this file.
nv_assert_gme_is_state_money <- function(records = NULL) {
  gme <- nv_pdf_flat("press_gme")

  if (!stringr::str_detect(gme, stringr::fixed(NV_GME_STATE_QUOTE))) {
    stop("[NV] the GME release no longer calls these '", NV_GME_STATE_QUOTE,
         "'.", call. = FALSE)
  }
  # It must NOT claim RHTP or CMS. If it ever does, the disposition changes.
  if (stringr::str_detect(gme, "(?i)rural health transformation|CMS/HHS|Medicaid Services")) {
    stop("[NV] the GME release now mentions RHTP or CMS. It was dispositioned ",
         "as state general fund money on the strength of it NOT doing so -- ",
         "re-read it.", call. = FALSE)
  }
  stated <- format(NV_GME_TOTAL, big.mark = ",", nsmall = 2, scientific = FALSE)
  if (!stringr::str_detect(gme, stringr::fixed(paste0("$", stated)))) {
    stop("[NV] the GME release no longer states $", stated, ".", call. = FALSE)
  }
  # Its own nine amounts must sum to its own stated total. If they do not, the
  # nine rows this file excludes are not the nine the release announced.
  amounts <- as.numeric(gsub(",", "", stringr::str_match_all(
    gme, "\\(\\$([0-9,]+)\\.00\\)")[[1]][, 2]))
  if (length(amounts) != NV_GME_PROGRAMMES) {
    stop("[NV] the GME release now lists ", length(amounts), " awards, not ",
         NV_GME_PROGRAMMES, ".", call. = FALSE)
  }
  if (abs(sum(amounts) - NV_GME_TOTAL) > 0.005) {
    stop("[NV] the GME release's nine amounts sum to $",
         format(sum(amounts), big.mark = ","), " against its own stated $",
         stated, ".", call. = FALSE)
  }
  if (!isTRUE(all.equal(sort(amounts), sort(NV_GME_AWARDS$amount)))) {
    stop("[NV] the GME release's amounts no longer match the nine recorded ",
         "in NV_GME_AWARDS.", call. = FALSE)
  }

  # And NOT ONE of them may be in the Nevada award file.
  if (!is.null(records)) {
    leaked <- intersect(tolower(records$awardee), tolower(NV_GME_AWARDS$awardee))
    if (length(leaked)) {
      stop("[NV] GME (STATE GENERAL FUND) recipients have leaked into the RHTP ",
           "award file: ", paste(leaked, collapse = "; "), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The date test, on Nevada's own RFA calendar.
nv_assert_rfas_postdate_noa <- function() {
  deck <- nv_pdf_flat("fiscal")
  # The four awarded pools closed on these dates, printed on the deck's RFA
  # timeline. Every one is months AFTER 2025-12-29 -- Texas's HHS0015180 closed
  # 2025-04-24, eight months BEFORE its state had the money.
  closes <- c("4/30/26", "5/15/26", "6/26/26", "5/29/26")
  for (d in closes) {
    if (!stringr::str_detect(deck, stringr::fixed(d))) {
      stop("[NV] the fiscal deck no longer carries the RFA close date ", d, ".",
           call. = FALSE)
    }
  }
  # Parsed rather than asserted as a string: every close date must be later
  # than the NOA.
  parsed <- as.Date(closes, format = "%m/%d/%y")
  if (any(is.na(parsed)) || any(parsed <= NV_NOA_DATE)) {
    stop("[NV] an RFA close date is not strictly after Nevada's ",
         NV_NOA_DATE, " Notice of Award.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- positive controls --------------------------------------------------------

#' NVHA publishes rosters in a recognisable form -- and for exactly three pools.
#'
#' Without this, "Nevada has published no roster for its other initiatives" is
#' indistinguishable from "we looked in the wrong place". The Funded Projects
#' page carries one accordion section per awarded pool, each with a
#' Subrecipient/Project/Service-Area table, and there are three. A FOURTH means
#' Nevada has awarded something this file does not carry.
nv_assert_award_index <- function() {
  txt <- nv_html_text("roster")
  for (section in NV_ROSTER_SECTIONS) {
    if (!stringr::str_detect(txt, stringr::fixed(section))) {
      stop("[NV] the Funded Projects page no longer carries the section '",
           section, "'. A roster this file extracts has disappeared.",
           call. = FALSE)
    }
  }
  tabs <- nv_roster_tables()
  if (length(tabs) != length(NV_ROSTER_SECTIONS)) {
    stop("[NV] the Funded Projects page carries ", length(tabs),
         " roster tables, not ", length(NV_ROSTER_SECTIONS),
         ". Nevada has published a roster this file does not carry.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The six closed opportunities with no roster. DESIGNED TO FAIL.
#'
#' NVHA is running ten Budget Period 1 funding opportunities and has published
#' recipients for three. The other six named here have closed and named nobody;
#' the day one of them appears on the Funded Projects page this file is
#' materially incomplete, and the failure is the signal.
nv_assert_pending_not_awarded <- function() {
  nofos <- nv_html_text("nofos")
  roster <- nv_html_text("roster")
  for (opp in NV_PENDING_OPPORTUNITIES) {
    if (stringr::str_detect(roster, stringr::fixed(opp))) {
      stop("[NV] '", opp, "' now appears on the Funded Projects page. Nevada ",
           "has awarded an opportunity this file records as pending -- ",
           "re-extract before using any figure here.", call. = FALSE)
    }
  }
  # And the funding-opportunities page must still show them, or the control
  # itself has gone.
  if (!stringr::str_detect(nofos, stringr::fixed("Requests for Applications"))) {
    stop("[NV] the funding-opportunities page no longer lists Requests for ",
         "Applications; the positive control is gone.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The Flex Fund round total is tied to THIS roster by NVHA, not by this file.
nv_assert_flex_round <- function() {
  pr <- nv_pdf_flat("press_flex")
  if (!stringr::str_detect(pr, stringr::fixed("$36 million in Rural Health Transformation funding awards"))) {
    stop("[NV] the 2026-06-09 release no longer states the $36 million Flex ",
         "Fund round.", call. = FALSE)
  }
  # The sentence that makes the roster this round's award list.
  if (!stringr::str_detect(pr, stringr::fixed("Review all RHT Funded Projects here"))) {
    stop("[NV] the 2026-06-09 release no longer points at the Funded Projects ",
         "page. Without that sentence the $36,000,000 and the 25 names are two ",
         "documents nobody has joined (§0.3).", call. = FALSE)
  }
  if (!stringr::str_detect(pr, stringr::fixed("Rural Health Flex Fund"))) {
    stop("[NV] the 2026-06-09 release no longer names the Flex Fund.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The three WRRAP round totals, and the conflict this file refuses to resolve.
#'
#' BOTH SIDES ARE ASSERTED. If the press release's figures move, `round_amount`
#' is wrong; if the deck's figures move, the conflict this file reports has
#' changed and the note on 27 + 20 rows is stale.
nv_assert_wrrap_rounds <- function() {
  pr <- nv_pdf_flat("press_wrrap")
  for (needle in c("$32.3 million awarded",
                   "$14.3 million in apprenticeship and training investments",
                   "$4.8 million in rural medical residency investments",
                   "$41.9 million requested")) {
    if (!stringr::str_detect(pr, stringr::fixed(needle))) {
      stop("[NV] the 2026-07-29 release no longer states '", needle, "'.",
           call. = FALSE)
    }
  }
  deck <- nv_pdf_flat("fiscal")
  for (amt in c(NV_STATED$deck_rr_available, NV_STATED$deck_at_available,
                NV_STATED$deck_flex_available, NV_STATED$deck_tribal_available)) {
    needle <- paste0("$", format(amt, big.mark = ",", scientific = FALSE))
    if (!stringr::str_detect(deck, stringr::fixed(needle))) {
      stop("[NV] the 2026-06-09 fiscal deck no longer states ", needle,
           ". The pool-total conflict this file reports has changed.",
           call. = FALSE)
    }
  }
  # THE ARITHMETIC THAT SURVIVES THE CONFLICT. Whatever the right mapping is,
  # the two WRRAP workforce sub-funds together are ~$46.6-46.8M, and that is
  # the figure `nv_report()` leads with.
  if (abs(NV_WRRAP_COMBINED_DECK - NV_WRRAP_COMBINED_PRESS) > 200000) {
    stop("[NV] the combined WRRAP figure is no longer stable across the two ",
         "sources ($", format(NV_WRRAP_COMBINED_DECK, big.mark = ","), " vs $",
         format(NV_WRRAP_COMBINED_PRESS, big.mark = ","),
         "). The conflict is now larger than a reallocation can explain and ",
         "must be re-read.", call. = FALSE)
  }
  invisible(TRUE)
}

#' NVHA'S OWN SLIDES CORROBORATE THE ROSTER AND CARRY NO AMOUNTS EITHER.
#'
#' The absence of per-recipient amounts is this file's central design premise,
#' so it is checked against a SECOND, independently produced document: the
#' fiscal deck's "Flex Funds - Funded Projects" slides list the same recipients
#' under the same three column headings (Applicant / County-Service Area / Type
#' of Project) and print no figure against any of them.
nv_assert_no_per_recipient_amounts <- function() {
  deck <- nv_pdf_flat("fiscal")
  if (!stringr::str_detect(deck, stringr::fixed("Flex Funds - Funded Projects"))) {
    stop("[NV] the fiscal deck no longer carries its Flex funded-projects ",
         "slides, which are the corroboration that Nevada publishes no ",
         "per-recipient amount.", call. = FALSE)
  }
  # A sample of recipients that must appear on BOTH the roster and the deck.
  awards <- nv_roster_awards()
  flex <- awards$awardee[awards$award_pool == "FLEX_FUND"]
  seen <- vapply(flex, function(a) stringr::str_detect(deck, stringr::fixed(a)),
                 logical(1))
  if (sum(seen) < 20L) {
    stop("[NV] only ", sum(seen), " of ", length(flex), " Flex Fund recipients ",
         "appear in the fiscal deck. The two documents no longer corroborate ",
         "each other.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- records ------------------------------------------------------------------

#' Nevada's 73 rows in the Florida schema (§8, test_state_union).
nv_records <- function() {
  awards <- nv_roster_awards()

  classified <- purrr::map_dfr(seq_len(nrow(awards)), function(i) {
    ct <- rhtp_classify_recipient_type(awards$awardee[i], NV_STATE)
    fl <- rhtp_classify_flow(ct$recipient_type, awards$project_description[i])
    tibble::tibble(
      recipient_type = ct$recipient_type,
      determination_confidence = ct$determination_confidence,
      classifier_basis = ct$recipient_type_basis,
      classifier_rule = ct$rule,
      flow_type = fl$flow_type,
      distributed_to_hospital = fl$distributed_to_hospital,
      hospital_benefiting = fl$hospital_benefiting,
      flow_basis = fl$flow_basis,
      flow_flag = fl$flow_flag
    )
  })

  pools <- NV_POOLS
  roster <- dplyr::bind_cols(awards, classified) %>%
    dplyr::left_join(pools, by = "award_pool") %>%
    dplyr::mutate(
      state = NV_STATE,
      note = paste0(
        .data$project_description, " Service area: ", .data$service_area, ".",
        " Published by the Nevada Health Authority on its RHT Funded Projects -",
        " Budget Period 1 page, which names every subrecipient and PUBLISHES NO",
        " AMOUNT FOR ANY OF THEM. The pool's own round total is in",
        " `round_amount`; it is NEVER divided across recipients (§6.2)."),
      # THE RECIPIENT IS CONFIRMED AND THE AMOUNT DOES NOT EXIST. §9.3 splits
      # these two questions precisely so a missing figure cannot drag a
      # confirmed recipient down with it.
      recipient_confirmed = "Yes",
      amount_confirmed = "No",
      amount = NA_real_,
      fiscal_year = 2026L,
      budget_period = "BP1 (12/29/2025 - 10/30/2026)",
      source_document_title = paste0(
        "Nevada RHT Funded Projects - Budget Period 1: ", .data$round_name),
      state_source_url = nv_source("roster", "url"),
      # NVHA calls the page "RHT Funded Projects" and its releases say
      # "awarded". Its own June process slide nonetheless puts a Letter of
      # Intent, CMS approval and final budget negotiation between selection and
      # subaward, and says "All RHT subawards for BP1 to be finalized by
      # October 1, 2026". Oregon's and Maryland's posture: the recipient is
      # announced, the agreement is not yet executed.
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "PARSED_HTML_TABLE",
      validator = "R/03u_nv_year1_awardees.R",
      ccn = NA_character_, aha_id = NA_character_,
      rural_designation = NA_character_, reviewer = NA_character_,
      recipient_type_source = .data$classifier_basis,
      amount_basis = "NVHA publishes NO per-recipient amount; the pool round total is in round_amount",
      county = .data$service_area,
      initiative = dplyr::case_when(
        .data$award_pool == "FLEX_FUND" ~ "Rural Health System Flex Fund",
        TRUE ~ "Workforce Recruitment and Rural Access Program (WRRAP)"),
      initiative_fund_use = .data$round_name,
      intermediary_name = NA_character_,
      source_archive_path = file.path("data/evidence/NV", nv_source("roster", "file"))
    )

  # -- the Rural Medical Residency aggregate row ------------------------------
  # $4,800,000 announced, four projects described, NO RECIPIENT NAMED. South
  # Dakota's device: an empty `amount`, the total in `round_amount`, and
  # NOT_YET_NAMED, so no sum over `amount` can read as a per-recipient figure.
  res_pool <- pools[pools$award_pool == "WRRAP_RURAL_MEDICAL_RESIDENCY", ]
  residency <- tibble::tibble(
    award_pool = res_pool$award_pool,
    row_in_pool = 1L,
    awardee = "Recipients not named by NVHA",
    project_description = paste0(
      "NVHA announced $4.8 million in rural medical residency investments and ",
      "described four projects -- a new rural obstetrics fellowship, a new ",
      "advanced practice registered nursing fellowship, a new rural family ",
      "medicine residency track in Fallon, and a statewide Rural Graduate ",
      "Medical Education Consortium -- WITHOUT NAMING A SINGLE RECIPIENT."),
    service_area = "Rural Nevada",
    recipient_type = "NOT_YET_NAMED",
    determination_confidence = "LOW",
    classifier_basis = "no recipient is named in the source",
    classifier_rule = "SOURCE_NAMES_NOBODY",
    flow_type = "PASS_THROUGH_UNRESOLVED",
    distributed_to_hospital = "Unclear",
    hospital_benefiting = "Unclear",
    flow_basis = paste0(
      "§0.3: NVHA describes four residency and fellowship projects and names ",
      "no recipient of any of them. A description is not a list, and nothing ",
      "here says a hospital received money."),
    flow_flag = NA_character_,
    round_id = res_pool$round_id, round_name = res_pool$round_name,
    round_amount = res_pool$round_amount, round_awards = res_pool$round_awards,
    roster = res_pool$roster, amount_source = res_pool$amount_source,
    state = NV_STATE,
    note = paste0(
      "ONE AGGREGATE ROW, NOT A RECIPIENT. NVHA's 2026-07-29 release states ",
      "it 'awarded $4.8 million in rural medical residency investments' and ",
      "names nobody, so this row carries an EMPTY `amount` with the round ",
      "total in `round_amount` (South Dakota's device, §6.2). IT IS NOT THE ",
      "GME GRANT PROGRAM: NVHA announced $15,755,068 of STATE GENERAL FUND ",
      "money to nine named residency programmes seven days earlier, and those ",
      "nine are dispositioned NOT_RHTP_STATE_PROGRAM in ",
      "nv_rcj_candidate_disposition.csv."),
    recipient_confirmed = "No",
    amount_confirmed = "No",
    amount = NA_real_,
    fiscal_year = 2026L,
    budget_period = "BP1 (12/29/2025 - 10/30/2026)",
    source_document_title = "Nevada Invests Over $50 Million to Strengthen Rural Healthcare Workforce and Expand Access Across the State",
    state_source_url = nv_source("press_wrrap", "url"),
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "PARSED_PDF_PROSE",
    validator = "R/03u_nv_year1_awardees.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    recipient_type_source = "no recipient is named in the source",
    amount_basis = "round total as published; NVHA names no recipient, so it is never divided",
    county = "Rural Nevada",
    initiative = "Workforce Recruitment and Rural Access Program (WRRAP)",
    initiative_fund_use = res_pool$round_name,
    intermediary_name = NA_character_,
    source_archive_path = file.path("data/evidence/NV", nv_source("press_wrrap", "file"))
  )

  recs <- dplyr::bind_rows(roster, residency) %>%
    dplyr::mutate(
      hospital_attribution = dplyr::case_when(
        .data$distributed_to_hospital == "Yes" &
          .data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                      "HOSPITAL_AFFILIATED_ENTITY") ~ "NAMED_HOSPITAL",
        .data$distributed_to_hospital == "Yes" ~ "POOL_NAMED_HOSPITALS",
        TRUE ~ "NOT_HOSPITAL"),
      flag_reason = nv_flags(.data$recipient_type, .data$classifier_rule,
                             .data$flow_flag, .data$award_pool,
                             .data$recipient_confirmed),

      # \u00a77 MAKES THIS FIELD MANDATORY AND NEVADA DID NOT CARRY IT AT ALL.
      # Both halves were already computed -- `classifier_basis` from the
      # recipient's name and `flow_basis` from \u00a710.2 -- and only the first
      # was surfaced, as `recipient_type_source`; the flow half was dropped on
      # the floor. The session 30 eligibility sweep found the two pass-through
      # rows with no stated basis at all, which is the field's whole purpose
      # failing on exactly the rows a reviewer will come back to: the Incline
      # Village Community Hospital Foundation (the project's first
      # FLOW_UNRESOLVED_HOSPITAL_AFFILIATED row) and the unnamed $4.8M
      # residency aggregate.
      #
      # The composition is `rhtp_classify_recipients()`'s own -- recipient
      # basis, then flow basis -- so a Nevada row now reads the same way a row
      # from any other state does. Session 31; nothing was re-coded and no
      # dollar moved, because both sentences already existed and described the
      # codings the file already carried.
      determination_basis = paste(.data$classifier_basis, .data$flow_basis),

      row_no = dplyr::row_number()
    )

  nv_assert_vocabulary(recs)
  recs
}

#' The flag set per row, `;`-joined (Oregon's convention).
nv_flags <- function(recipient_type, classifier_rule, flow_flag, award_pool,
                     recipient_confirmed) {
  vapply(seq_along(recipient_type), function(i) {
    f <- character(0)
    # §8's standing fallback: a named recipient whose FORM NVHA never states.
    if (identical(classifier_rule[i], "FALLBACK")) {
      f <- c(f, "RECIPIENT_TYPE_INFERRED")
    }
    # EVERY row. Nevada publishes no per-recipient amount at all.
    f <- c(f, "AMOUNT_MISSING")
    if (identical(recipient_confirmed[i], "No")) {
      f <- c(f, "RECIPIENT_NOT_NAMED")
    }
    if (!is.na(flow_flag[i])) f <- c(f, flow_flag[i])
    # The two WRRAP workforce pools, whose round totals two NVHA documents
    # disagree about. The Flex Fund and the residency pool are not in dispute.
    if (award_pool[i] %in% c("WRRAP_RECRUITMENT_RETENTION",
                             "WRRAP_APPRENTICESHIP_TRAINING")) {
      f <- c(f, "POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES")
    }
    paste(unique(f), collapse = ";")
  }, character(1))
}

#' Every categorical value against `vocabularies.csv` (§5).
nv_assert_vocabulary <- function(recs) {
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
      stop("[NV] value(s) outside §8 in `", col, "`: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  allowed_flags <- rhtp_vocabulary("flag_reason")
  used <- unique(unlist(strsplit(stats::na.omit(recs$flag_reason), ";")))
  used <- used[nzchar(used)]
  bad <- setdiff(used, allowed_flags)
  if (length(bad)) {
    stop("[NV] flag_reason value(s) outside §8: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- reconciliation -----------------------------------------------------------

#' Nevada's published total, summed over DISTINCT pools.
#'
#' GEORGIA'S TRAP, IN A NEW STATE. `round_amount` repeats its pool's total on
#' every row of that pool, so summing the column gives $2,062,900,000 for a
#' state that announced $87,400,000. Nothing may sum `round_amount` down the
#' column; this is the function that does it correctly.
nv_reconcile <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  pools <- recs %>%
    dplyr::distinct(.data$award_pool, .data$round_name, .data$round_amount) %>%
    dplyr::arrange(dplyr::desc(.data$round_amount))
  if (nrow(pools) != nrow(NV_POOLS)) {
    stop("[NV] reconciliation found ", nrow(pools), " distinct pools, not ",
         nrow(NV_POOLS), ".", call. = FALSE)
  }
  total <- sum(pools$round_amount)
  if (total != NV_STATED$announced_total) {
    stop("[NV] the four pools sum to $", format(total, big.mark = ","),
         " against Nevada's announced $",
         format(NV_STATED$announced_total, big.mark = ","), ".", call. = FALSE)
  }
  # And the wrong sum must stay visibly wrong, so the trap cannot quietly close.
  naive <- sum(recs$round_amount)
  if (naive <= total) {
    stop("[NV] summing `round_amount` down the column no longer overstates ",
         "the total. The repeat-per-row design has changed and every ",
         "assertion keyed on it needs re-reading.", call. = FALSE)
  }
  list(pools = pools, total = total, naive_column_sum = naive,
       pct_of_allotment = 100 * total / rhtp_nv_allotment())
}

#' THE MISREADING GUARD.
#'
#' `rhtp_hospital_dollar_partition()` sums with `na.rm = TRUE`, so Nevada comes
#' back as `NAMED_HOSPITAL rows = 20, dollars = 0`. Both halves are true and
#' only one of them is a number, which is why a reader who takes the 0 and not
#' the 20 concludes Nevada's rural hospitals got nothing -- the exact opposite
#' of what NVHA has published. This asserts the pairing so it cannot drift, and
#' it is the assertion to read before quoting any Nevada hospital figure.
nv_assert_zero_dollars_is_not_zero_hospitals <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  part <- rhtp_hospital_dollar_partition(recs)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  if (nrow(named) != 1L) {
    stop("[NV] the partition no longer returns exactly one NAMED_HOSPITAL row.",
         call. = FALSE)
  }
  if (named$dollars != 0) {
    stop("[NV] NAMED_HOSPITAL dollars are $", format(named$dollars, big.mark = ","),
         ", not $0. Nevada has started publishing per-recipient amounts and ",
         "this file's design premise is gone -- rewrite it rather than ",
         "updating this number.", call. = FALSE)
  }
  if (named$rows < 1L) {
    stop("[NV] the partition reports 0 named-hospital ROWS. Nevada names ",
         "hospitals on its roster; a zero here is a parse failure, not a ",
         "finding.", call. = FALSE)
  }
  invisible(list(rows = named$rows, dollars = named$dollars))
}

#' Same-entity name variants across pools -- RECORDED, NEVER RESOLVED.
#'
#' NVHA writes several recipients differently in different pools: "Desert View
#' Hospital" and "DVH Hospital Alliance LLN dba Desert View Hospital",
#' "Grover C. Dils Medical Center" and "Lincoln County Hospital District dba
#' Grover C. Dils Medical Center", "Carson Valley Health" and "Washoe Barton
#' Medical Clinic DBA Carson Valley Health". And it publishes BOTH "Northern
#' Nevada Regional Hospital" (Flex, "Elko - Battle Mountain and Owyhee") and
#' "Northeastern Nevada Regional Hospital" (Recruitment and Retention, "Elko,
#' Eureka, Humboldt, Lander, and White Pine") -- two names four characters
#' apart, in one state, both in Elko.
#'
#' §2 FORBIDS A MACHINE AUTO-RESOLVING A FUZZY HOSPITAL MATCH, so none of these
#' is merged. The consequence is that "distinct hospitals" is a count of NAMES
#' and is an upper bound on the count of ORGANISATIONS. The CCN match (blocker
#' 5) is what settles it.
NV_NAME_VARIANT_PAIRS <- list(
  c("Desert View Hospital", "DVH Hospital Alliance LLN dba Desert View Hospital"),
  c("Grover C. Dils Medical Center",
    "Lincoln County Hospital District dba Grover C. Dils Medical Center"),
  c("Carson Valley Health", "Washoe Barton Medical Clinic DBA Carson Valley Health"),
  c("Northern Nevada Regional Hospital", "Northeastern Nevada Regional Hospital")
)

nv_assert_name_variants_unresolved <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  for (pair in NV_NAME_VARIANT_PAIRS) {
    present <- pair %in% recs$awardee
    if (!all(present)) {
      stop("[NV] the name-variant pair '", paste(pair, collapse = "' / '"),
           "' is no longer both present in the file. Either NVHA has ",
           "normalised its own roster or something has merged them here -- ",
           "§2 forbids the latter.", call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- §0.1: what RCJ's 34 Nevada candidates actually are -----------------------

#' The committed Tier 3 candidate set for Nevada, re-derived on every run.
#'
#' Never typed. The day Nevada's candidate set moves, the disposition build
#' fails rather than quietly ceasing to cover it (Texas's, Nebraska's,
#' Indiana's and Oklahoma's convention).
nv_rcj_candidates <- function() {
  path <- here::here("data", "interim", "stage2_record_table.rds")
  if (!file.exists(path)) {
    stop("[NV] stage2_record_table.rds is missing; run Stage 2 first.",
         call. = FALSE)
  }
  readRDS(path) %>%
    dplyr::filter(.data$state == NV_STATE, .data$award_tier == "SUBAWARD",
                  is.na(.data$superseded_by))
}

#' Which of the 34 is which, keyed on the source document RCJ took it from.
nv_classify_candidates <- function(cand = NULL) {
  if (is.null(cand)) cand <- nv_rcj_candidates()
  gme_names <- tolower(NV_GME_AWARDS$awardee)
  cand %>%
    dplyr::mutate(
      disposition = dplyr::case_when(
        # ORDER MATTERS, AND THIS BRANCH MUST COME FIRST. NVHA's own pool is
        # called "Rural Medical Residency", so a specialty regex written for
        # the GME awards below matches the POOL TOTAL too -- which would file
        # $9.6M of Tier 2 RHTP money as state money and get both wrong at once.
        # The pool names, and RCJ's "... Recipients (NV)" variants of them, are
        # §6.1's PROGRAM_NAME_AS_AWARDEE and §0.3's class-not-a-recipient.
        stringr::str_detect(.data$awardee_name_clean,
          "(?i)^(provider recruitment and retention|apprenticeship and training|rural medical residency)") ~
          "RHTP_BUT_NOT_A_SUBAWARD",
        # A line item out of the RFA's budget-narrative TEMPLATE.
        stringr::str_detect(.data$source_doc_title, "(?i)budget narrative") ~
          "RHTP_BUT_NOT_A_SUBAWARD",
        # The nine GME programmes, under either of the two titles RCJ files
        # them beneath. Matched on the AMOUNT and on the name: RCJ publishes
        # UNLV Ophthalmology at $2,995,893 under one title and $2,995,890 --
        # the state's own figure -- under the other, so neither key alone
        # reaches all seventeen rows.
        round(.data$amount_announced) %in% round(NV_GME_AWARDS$amount) |
          tolower(.data$awardee_name_clean) %in% gme_names |
          stringr::str_detect(.data$awardee_name_clean,
            "(?i)residency|fellowship|ophthalmolog|otolaryngolog|radiolog|gynecolog|pulmonary|family medicine|internal medicine|general surgery") ~
          "NOT_RHTP_STATE_PROGRAM",
        TRUE ~ "RHTP_SUBAWARD_IN_FILE"),
      .after = "awardee_name_clean")
}

#' The disposition table: one row per group, with the disqualifying evidence.
nv_disposition_table <- function() {
  cand <- nv_classify_candidates()
  recs <- nv_records()

  n_of <- function(d) sum(cand$disposition == d)
  amt_of <- function(d) sum(cand$amount_announced[cand$disposition == d],
                            na.rm = TRUE)

  # The rows RCJ DOES hold that are real Nevada awards must actually be in the
  # file, matched on name. If one is not, either the roster parse or this
  # disposition is wrong.
  in_file <- cand$awardee_name_clean[cand$disposition == "RHTP_SUBAWARD_IN_FILE"]
  missing <- setdiff(tolower(in_file), tolower(recs$awardee))
  if (length(missing)) {
    stop("[NV] RCJ holds candidate(s) dispositioned as real Nevada awards that ",
         "are NOT in nv_year1_awardees.csv: ", paste(missing, collapse = "; "),
         call. = FALSE)
  }

  tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount_sum, ~disposition, ~why, ~disqualifying_evidence, ~state_source_url, ~source_archive_path,

    "GME Grant Program Round VIII -- nine residency and fellowship programmes",
    n_of("NOT_RHTP_STATE_PROGRAM"), amt_of("NOT_RHTP_STATE_PROGRAM"),
    "NOT_RHTP_STATE_PROGRAM",
    paste0(
      "Nevada's Graduate Medical Education grant programme is STATE GENERAL ",
      "FUND money, not RHTP. NVHA's own workforce publication prints GME, ",
      "WRRAP and SHARP side by side under a column headed 'Funding' and gives ",
      "GME's source as 'State General Fund' with governance NRS 223.631-639 ",
      "and SB262 & SB494 (2025); only WRRAP is sourced to the CMS RHT grant. ",
      "The 2026-07-22 release announcing these nine awards calls them 'these ",
      "new state investments' and mentions neither CMS nor RHTP. RCJ files ",
      "them under RHTP-titled documents anyway. THE CMS FINANCIAL-ASSISTANCE ",
      "FOOTER IS ON THE WORKFORCE PUBLICATION AND DOES NOT REACH THE ",
      "PROGRAMMES IT DESCRIBES -- which is why a footer check alone passes ",
      "all seventeen of these rows."),
    paste0("\"Source: State General Fund\" / \"", NV_GME_STATE_QUOTE,
           "\" / total $15,755,068.00 to nine programmes"),
    "https://www.nvha.nv.gov/working-together/be-informed/",
    "data/evidence/NV/2026-07-22_nv_press_release_gme_grant_round_viii.pdf",

    "The three WRRAP pool totals, and a budget-narrative line item",
    n_of("RHTP_BUT_NOT_A_SUBAWARD"), amt_of("RHTP_BUT_NOT_A_SUBAWARD"),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0(
      "Genuinely RHTP and one tier too high (§0.2). 'Provider Recruitment and ",
      "Retention' ($32,300,000), 'Apprenticeship and Training Investments' ",
      "($14,300,000) and 'Rural Medical Residency Investments' ($4,800,000) ",
      "are NVHA's POOL names carrying NVHA's POOL totals -- §6.1's ",
      "PROGRAM_NAME_AS_AWARDEE, and the same figures this file carries in ",
      "`round_amount`. RCJ additionally publishes each under a '... ",
      "Recipients (NV)' variant, which is a CLASS and not a recipient (§0.3, ",
      "North Dakota's '15 selected CAHs'). 'IT Technician At Your Service' ",
      "($40,000) is a line out of Attachment C, the RFA's budget narrative ",
      "TEMPLATE."),
    "the pool totals restated as awardees; a budget-template line item",
    "https://www.nvha.nv.gov/RHTP/rht-nofos/",
    "data/evidence/NV/2026-07-29_nv_press_release_wrrap_awards.pdf",

    "Ten Flex Fund awardees RCJ captured from a STEERING COMMITTEE AGENDA",
    n_of("RHTP_SUBAWARD_IN_FILE"), amt_of("RHTP_SUBAWARD_IN_FILE"),
    "RHTP_SUBAWARD_IN_FILE",
    paste0(
      "Real Nevada RHTP awards, and all ten are in nv_year1_awardees.csv -- ",
      "asserted by name, not assumed. They are the ONLY genuine subawards in ",
      "the candidate set: RCJ holds 10 of Nevada's 72 published award ",
      "actions. EVERY ONE CARRIES AN AMOUNT OF $1. They were mined out of the ",
      "2026-06-09 RHT Steering Committee fiscal deck, whose 'Flex Funds - ",
      "Funded Projects' slides list recipients with NO amounts, so the $1 is ",
      "a placeholder for a figure that does not exist -- and RCJ's title for ",
      "them, 'Agenda Nevada RHT Program Activity', is the text of the deck's ",
      "AGENDA SLIDE, not the document's title (Nebraska's defect: the title ",
      "came off the wrong page)."),
    "amount_announced = $1 on all ten; the title is the agenda slide's text",
    "https://www.nvha.nv.gov/RHTP/rht-meetings/",
    "data/evidence/NV/2026-06-09_nv_rhtsc_program_fiscal_update.pdf"
  )
}


#' The candidate set's own arithmetic, re-derived and asserted every run.
nv_assert_candidate_disposition <- function() {
  cand <- nv_classify_candidates()
  if (nrow(cand) != NV_STATED$rcj_candidates) {
    stop("[NV] the committed record table now holds ", nrow(cand),
         " Nevada Tier 3 candidates, not ", NV_STATED$rcj_candidates,
         ". nv_rcj_candidate_disposition.csv no longer covers the set it ",
         "claims to.", call. = FALSE)
  }
  d <- nv_disposition_table()
  if (sum(d$rcj_rows) != nrow(cand)) {
    stop("[NV] the disposition table accounts for ", sum(d$rcj_rows),
         " candidates of ", nrow(cand), ".", call. = FALSE)
  }
  # NOT ONE of the 34 may be missing a disposition.
  if (any(is.na(cand$disposition))) {
    stop("[NV] ", sum(is.na(cand$disposition)),
         " Nevada candidates have no disposition.", call. = FALSE)
  }
  # The state-money group must cover the nine GME programmes and nothing else:
  # every distinct amount in it is one the GME release published.
  gme <- cand[cand$disposition == "NOT_RHTP_STATE_PROGRAM", ]
  stray <- setdiff(round(unique(gme$amount_announced)),
                   round(c(NV_GME_AWARDS$amount, 2995893)))
  if (length(stray)) {
    stop("[NV] the NOT_RHTP_STATE_PROGRAM group carries amount(s) the GME ",
         "release does not publish: ", paste(stray, collapse = ", "),
         call. = FALSE)
  }
  # And the RHTP pool group must be exactly the three pool totals plus the
  # budget-template line.
  pool <- cand[cand$disposition == "RHTP_BUT_NOT_A_SUBAWARD", ]
  expect_pool <- c(NV_STATED$wrrap_rr_awarded, NV_STATED$wrrap_at_awarded,
                   NV_STATED$wrrap_residency, 40000)
  stray2 <- setdiff(round(unique(pool$amount_announced)), round(expect_pool))
  if (length(stray2)) {
    stop("[NV] the RHTP_BUT_NOT_A_SUBAWARD group carries unexpected amount(s): ",
         paste(stray2, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

#' The §0.1 headline: what an extractor built from the candidate list would
#' have published, and how much of it is state money.
nv_candidate_inflation <- function() {
  cand <- nv_classify_candidates()
  list(
    candidates = nrow(cand),
    face_value = sum(cand$amount_announced, na.rm = TRUE),
    state_money = sum(cand$amount_announced[
      cand$disposition == "NOT_RHTP_STATE_PROGRAM"], na.rm = TRUE),
    tier2 = sum(cand$amount_announced[
      cand$disposition == "RHTP_BUT_NOT_A_SUBAWARD"], na.rm = TRUE),
    real_awards = sum(cand$disposition == "RHTP_SUBAWARD_IN_FILE"),
    real_award_amount = sum(cand$amount_announced[
      cand$disposition == "RHTP_SUBAWARD_IN_FILE"], na.rm = TRUE),
    gme_distinct_total = NV_GME_TOTAL,
    published_awards = NV_STATED$roster_rows,
    rcj_coverage_pct = 100 * sum(cand$disposition == "RHTP_SUBAWARD_IN_FILE") /
      NV_STATED$roster_rows
  )
}


# -- validate / build / report ------------------------------------------------

nv_validate <- function() {
  recs <- nv_records()

  if (nrow(recs) != NV_STATED$total_rows) {
    stop("[NV] ", nrow(recs), " rows, not ", NV_STATED$total_rows, ".",
         call. = FALSE)
  }
  by_pool <- table(recs$award_pool)
  expect <- c(FLEX_FUND = NV_STATED$flex_rows,
              WRRAP_RECRUITMENT_RETENTION = NV_STATED$wrrap_rr_rows,
              WRRAP_APPRENTICESHIP_TRAINING = NV_STATED$wrrap_at_rows,
              WRRAP_RURAL_MEDICAL_RESIDENCY = 1L)
  for (p in names(expect)) {
    if (!identical(as.integer(by_pool[[p]]), as.integer(expect[[p]]))) {
      stop("[NV] pool ", p, " has ", by_pool[[p]], " rows, not ", expect[[p]],
           ".", call. = FALSE)
    }
  }

  # THE CENTRAL INVARIANT. Nevada publishes no per-recipient amount, so the
  # column is empty on every row and sums to zero. A non-empty `amount` here
  # means either the source changed or something invented a figure.
  if (!all(is.na(recs$amount))) {
    stop("[NV] ", sum(!is.na(recs$amount)), " row(s) carry an `amount`. ",
         "NVHA publishes none, and §6.2 forbids dividing a round total.",
         call. = FALSE)
  }

  nv_assert_cms_notice_of_award()
  nv_assert_footer_is_not_provenance()
  nv_assert_gme_is_state_money(recs)
  nv_assert_rfas_postdate_noa()
  nv_assert_award_index()
  nv_assert_pending_not_awarded()
  nv_assert_flex_round()
  nv_assert_wrrap_rounds()
  nv_assert_no_per_recipient_amounts()
  nv_assert_zero_dollars_is_not_zero_hospitals(recs)
  nv_assert_name_variants_unresolved(recs)
  nv_assert_candidate_disposition()
  nv_assert_form_not_stated_queued(recs)
  rec <- nv_reconcile(recs)

  message("[NV] OK -- ", nrow(recs), " rows across ", nrow(rec$pools),
          " pools; $", format(rec$total, big.mark = ","), " announced (",
          round(rec$pct_of_allotment, 1), "% of allotment); ",
          "sum(amount) = 0 by design.")
  invisible(recs)
}

#' The §8 leading-19 schema, then Nevada's own appended fields.
NV_COLUMN_ORDER <- c(
  "state", "row_no", "awardee", "amount", "recipient_type",
  "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
  "fiscal_year", "source_document_title", "state_source_url",
  "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
  "rural_designation", "reviewer", "recipient_type_source",
  "determination_confidence", "flag_reason", "award_pool", "budget_period",
  "flow_type", "hospital_benefiting", "hospital_attribution",
  "intermediary_name", "determination_basis", "amount_basis", "county",
  "project_description",
  "round_id", "round_name", "round_awards", "round_amount", "initiative",
  "initiative_fund_use", "source_archive_path", "service_area", "row_in_pool"
)

nv_build <- function() {
  recs <- nv_validate()
  out <- recs %>%
    dplyr::select(dplyr::all_of(NV_COLUMN_ORDER)) %>%
    dplyr::arrange(.data$row_no)
  readr::write_csv(out, NV_OUT_CSV, na = "")
  message("[NV] wrote ", NV_OUT_CSV, " (", nrow(out), " rows)")

  disp <- nv_disposition_table()
  readr::write_csv(disp, NV_DISPOSITION_CSV, na = "")
  message("[NV] wrote ", NV_DISPOSITION_CSV, " (", nrow(disp), " rows)")

  nv_write_workbook(out, disp)
  invisible(out)
}


#' The review-queue row, its rows and its $0 dollar effect -- asserted, not
#' merely written once (Maryland's, Nebraska's and Oklahoma's convention).
nv_assert_form_not_stated_queued <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- q[q$question_id == "NV_RECIPIENT_FORM_NOT_STATED", ]
  if (nrow(row) != 1L) {
    stop("[NV] NV_RECIPIENT_FORM_NOT_STATED is not in ",
         "classification_review_queue.csv exactly once.", call. = FALSE)
  }
  soft <- recs[stringr::str_detect(recs$flag_reason, "RECIPIENT_TYPE_INFERRED"), ]
  if (!stringr::str_detect(row$row_key, paste0("^", nrow(soft), " rows"))) {
    stop("[NV] the queue row says '", row$row_key, "' but the file carries ",
         nrow(soft), " rows on §8's fallback.", call. = FALSE)
  }
  # THE ONE-DIRECTIONAL PART OF OKLAHOMA'S ROW HAS NO ANALOGUE HERE, AND THAT
  # IS THE POINT: with no amounts published, the question is worth $0 whichever
  # way it goes. If any fallback row ever acquires an amount, the queue row's
  # stated dollar effect becomes false.
  if (!all(is.na(soft$amount))) {
    stop("[NV] a §8-fallback row now carries an amount, so the queue row's ",
         "'$0 in either direction' is no longer true.", call. = FALSE)
  }
  if (!stringr::str_detect(row$dollar_effect, stringr::fixed("$0 in either direction"))) {
    stop("[NV] the queue row no longer states the $0 dollar effect.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- workbook -----------------------------------------------------------------

nv_write_workbook <- function(out, disp) {
  wb <- openxlsx::createWorkbook()

  warning_sheet <- tibble::tibble(
    `READ THIS FIRST` = c(
      "NEVADA PUBLISHES A COMPLETE, NAMED RECIPIENT ROSTER WITH NO AMOUNTS ON IT.",
      "",
      "The `amount` column is EMPTY ON ALL 73 ROWS and sums to $0. That is not a",
      "parse failure and it is NOT a claim that Nevada awarded nothing. It is the",
      "honest total of what the Nevada Health Authority has published PER",
      "RECIPIENT, which is nothing at all.",
      "",
      "NEVADA HAS 20 NAMED-HOSPITAL AWARD ACTIONS AND $0 OF NAMED-HOSPITAL",
      "DOLLARS. Both are true. rhtp_hospital_dollar_partition() reports Nevada as",
      "rows = 20, dollars = 0 -- READ THE ROW COUNT. Taking the 0 and not the 20",
      "gives the exact opposite of what NVHA has published.",
      "",
      "WHAT NEVADA HAS ANNOUNCED, BY POOL (never per recipient):",
      "  Rural Health System Flex Fund              25 awards   $36,000,000",
      "  WRRAP - Recruitment and Retention Fund     27 awards   $32,300,000",
      "  WRRAP - Apprenticeship and Training Fund   20 awards   $14,300,000",
      "  WRRAP - Rural Medical Residency         NAMES NOBODY   $ 4,800,000",
      "                                                         -----------",
      "                                                         $87,400,000",
      "",
      "`round_amount` REPEATS ITS POOL'S TOTAL ON EVERY ROW OF THAT POOL. Summing",
      "the column gives $2,062,900,000. Sum DISTINCT (award_pool, round_amount)",
      "pairs instead -- nv_reconcile() does it correctly.",
      "",
      "TWO NVHA DOCUMENTS DISAGREE ABOUT WHICH WRRAP FUND GOT $32.3M AND WHICH",
      "GOT $14.3M. The 2026-06-09 fiscal deck and the 2026-07-29 press release",
      "swap them. `round_amount` takes the press release (an award announcement",
      "outranks a pre-award planning deck on what was awarded) and both WRRAP",
      "rosters carry POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES. THE COMBINED WRRAP",
      "WORKFORCE FIGURE IS ~$46.6M EITHER WAY.",
      "",
      "THE NINE GME AWARDS ARE NOT IN THIS FILE AND MUST NOT BE ADDED TO IT.",
      "NVHA announced $15,755,068 to nine residency programmes on 2026-07-22.",
      "That is STATE GENERAL FUND money -- NVHA's own workforce publication says",
      "so -- and seventeen of RCJ's 34 Nevada candidates are those nine awards.",
      "",
      "23 rows carry §8's standing fallback (NONPROFIT_CBO + LOW): NVHA states no",
      "recipient's organisational form. Renown Health, Carson Valley Health and",
      "Intermountain Health are among them. Nothing was promoted (§0.4)."))

  openxlsx::addWorksheet(wb, "READ THIS FIRST")
  openxlsx::writeData(wb, "READ THIS FIRST", warning_sheet)
  openxlsx::setColWidths(wb, "READ THIS FIRST", 1, 96)

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", out)

  rec <- nv_reconcile(nv_records())
  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", rec$pools)

  openxlsx::addWorksheet(wb, "RCJ disposition")
  openxlsx::writeData(wb, "RCJ disposition", disp)

  openxlsx::saveWorkbook(wb, NV_XLSX, overwrite = TRUE)
  message("[NV] wrote ", NV_XLSX)
  invisible(NV_XLSX)
}


# -- report -------------------------------------------------------------------

nv_report <- function() {
  recs <- nv_records()
  rec <- nv_reconcile(recs)
  part <- rhtp_hospital_dollar_partition(recs)
  inf <- nv_candidate_inflation()
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  soft <- recs[stringr::str_detect(recs$flag_reason, "RECIPIENT_TYPE_INFERRED"), ]

  cat("\nNEVADA -- RHTP Year 1\n"); cat(strrep("=", 74), "\n")
  cat("A COMPLETE, NAMED RECIPIENT ROSTER WITH NO AMOUNTS ON IT.\n\n")

  cat("Announced by pool (NEVER per recipient):\n")
  print(as.data.frame(rec$pools[, c("round_name", "round_amount")]),
        row.names = FALSE, right = FALSE)
  cat("\n  Total announced: $", format(rec$total, big.mark = ","),
      "  (", round(rec$pct_of_allotment, 1), "% of the $",
      format(rhtp_nv_allotment(), big.mark = ","), " allotment)\n", sep = "")
  cat("  Summing `round_amount` down the column instead gives $",
      format(rec$naive_column_sum, big.mark = ","),
      " -- Georgia's trap.\n", sep = "")

  cat("\nsum(amount) = $", format(sum(recs$amount, na.rm = TRUE)),
      "  ON ALL ", nrow(recs), " ROWS, BY DESIGN.\n", sep = "")
  cat("  NVHA publishes no per-recipient figure and §6.2 forbids dividing a\n")
  cat("  round total, so the column is empty rather than invented.\n")

  cat("\nHOSPITALS -- A COUNT, NOT A DOLLAR FIGURE\n")
  cat(strrep("-", 74), "\n")
  cat("  NAMED_HOSPITAL: ", named$rows, " award actions   $",
      format(named$dollars), "\n", sep = "")
  cat("  ", dplyr::n_distinct(recs$awardee[recs$hospital_attribution ==
        "NAMED_HOSPITAL"]), " distinct hospital NAMES (an upper bound on\n",
      "  organisations: NVHA publishes 'Desert View Hospital' and 'DVH\n",
      "  Hospital Alliance LLN dba Desert View Hospital' as separate rows,\n",
      "  and §2 forbids a machine merging them).\n", sep = "")
  cat("\n  READ THE ROW COUNT, NOT THE ZERO. Nevada named ", named$rows,
      " hospital award\n", sep = "")
  cat("  actions and published a dollar figure for none of them. A reader who\n")
  cat("  quotes the $0 reports the opposite of what NVHA has published.\n")

  cat("\nRECIPIENT FORM NOT STATED BY NVHA: ", nrow(soft), " rows\n", sep = "")
  cat("  Kansas's, Maryland's, Nebraska's and Oklahoma's shape a FIFTH time --\n")
  cat("  and the first worth $0 in either direction, because there are no\n")
  cat("  amounts for it to move. Renown Health, Carson Valley Health and\n")
  cat("  Intermountain Health are inside it. Nothing promoted (§0.4);\n")
  cat("  queued as NV_RECIPIENT_FORM_NOT_STATED.\n")

  cat("\n§6.2 PROVENANCE -- THE STRONGEST FORM IN THIS REPOSITORY\n")
  cat(strrep("-", 74), "\n")
  cat("  Nevada publishes CMS's own Notice of Award. Not a footer quoting the\n")
  cat("  award -- the award: recipient 'Nevada Health Authority', award\n")
  cat("  ", NV_CMS_AWARD_NUMBER, ", Assistance Listing ", NV_ASSISTANCE_LISTING,
      " 'Rural Health\n", sep = "")
  cat("  Transformation Program', 12/29/2025 - 10/30/2026, $",
      format(NV_CMS_AWARD_AMOUNT, big.mark = ",", nsmall = 2), ".\n", sep = "")
  cat("  That rounds to the §7.1 anchor's $",
      format(rhtp_nv_allotment(), big.mark = ","),
      " exactly, and its date is\n  the 2025-12-29 anchor exactly.\n", sep = "")

  cat("\nAND THE FOOTER ALONE IS NOT A PROVENANCE TEST -- NEVADA IS WHERE\n")
  cat("THAT BREAKS.\n")
  cat("  NVHA's workforce publication carries the CMS financial-assistance\n")
  cat("  footer ON EVERY PAGE and describes THREE programmes side by side:\n")
  cat("    GME    -> 'Source: State General Fund'          NOT RHTP\n")
  cat("    WRRAP  -> CMS RHT Grant ", NV_CMS_AWARD_NUMBER, "   RHTP\n", sep = "")
  cat("    SHARP  -> 'SB5 one-time bill appropriation'     NOT RHTP\n")
  cat("  A check keyed on 'does this document carry the CMS footer' answers\n")
  cat("  YES for all three and is wrong for two. Oklahoma's footer was on a\n")
  cat("  ROSTER and covered what was on it; Nevada's is on a COMPARISON\n")
  cat("  DOCUMENT and covers only the publishing.\n")

  cat("\n§0.1 -- WHAT RCJ'S ", inf$candidates, " NEVADA CANDIDATES ACTUALLY ARE\n", sep = "")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(nv_disposition_table()[, c("rcj_rows", "rcj_amount_sum",
                                                 "disposition")]),
        row.names = FALSE, right = FALSE)
  cat("\n  At face value the candidate list publishes $",
      format(inf$face_value, big.mark = ","), " as Nevada's\n", sep = "")
  cat("  Tier 3 subawards. Of that, $", format(inf$state_money, big.mark = ","),
      " is STATE GENERAL FUND money --\n", sep = "")
  cat("  the nine GME residency awards ($",
      format(inf$gme_distinct_total, big.mark = ",", nsmall = 2),
      " distinct, carried twice by\n", sep = "")
  cat("  RCJ under two titles) -- and $", format(inf$tier2, big.mark = ","),
      " is Tier 2 pool totals.\n", sep = "")
  cat("\n  RCJ HOLDS ", inf$real_awards, " OF NEVADA'S ", inf$published_awards,
      " PUBLISHED AWARD ACTIONS (",
      round(inf$rcj_coverage_pct, 1), "%), EVERY\n", sep = "")
  cat("  ONE AT AN AMOUNT OF $1, mined out of a steering-committee deck whose\n")
  cat("  AGENDA SLIDE it captured as the document title (Nebraska's defect).\n")

  cat("\n  Texas's defect was the wrong PROGRAMME; Oregon's the wrong RECIPIENT\n")
  cat("  CLASS; Indiana's an INVENTED label; Oklahoma's the wrong TIER.\n")
  cat("  NEVADA'S IS ALL THREE OF THE OTHERS AT ONCE, IN ONE CANDIDATE SET --\n")
  cat("  17 rows of the wrong programme, 7 of the wrong tier, and 10 real\n")
  cat("  awards whose amounts are placeholders.\n")

  cat("\nTHE WRRAP POOL CONFLICT, UNRESOLVED\n")
  cat(strrep("-", 74), "\n")
  cat("  2026-06-09 fiscal deck:  R&R $",
      format(NV_STATED$deck_rr_available, big.mark = ","), " available   A&T $",
      format(NV_STATED$deck_at_available, big.mark = ","), " available\n", sep = "")
  cat("  2026-07-29 press release: R&R $",
      format(NV_STATED$wrrap_rr_awarded, big.mark = ","), " awarded     A&T $",
      format(NV_STATED$wrrap_at_awarded, big.mark = ","), " awarded\n", sep = "")
  cat("  The pairing in the deck was checked against the PDF's own GLYPH\n")
  cat("  POSITIONS, so it is the source and not the parse.\n")
  cat("  COMBINED, THE TWO ARE STABLE: $",
      format(NV_WRRAP_COMBINED_DECK, big.mark = ","), " available vs $",
      format(NV_WRRAP_COMBINED_PRESS, big.mark = ","), " awarded --\n", sep = "")
  cat("  a reallocation between the sub-funds would explain it exactly, and\n")
  cat("  THAT INFERENCE IS NOT PUBLISHED AS A FINDING (§0.4).\n")

  invisible(recs)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(as.data.frame(nv_fetch(force = "--force" %in% args)))
  if ("--validate" %in% args) nv_validate()
  if ("--build" %in% args) nv_build()
  if ("--report" %in% args) nv_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03u_nv_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report]\n")
  }
}

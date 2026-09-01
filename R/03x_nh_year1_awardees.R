# 03x_nh_year1_awardees.R -----------------------------------------------------
# New Hampshire Year 1 -> data/reference/nh_year1_awardees.csv
#                         data/reference/nh_year1_status.csv
#                         data/reference/nh_rcj_candidate_disposition.csv
#
# WHY NEW HAMPSHIRE. It led the queue once Missouri was extracted -- 27 Tier 3
# candidates, 15 distinct awardees, a $204,016,550 allotment, no CMS press
# release, and never investigated.
#
# WHAT NEW HAMPSHIRE HAS PUBLISHED. Its RHTP is branded GO-NORTH -- the
# Governor's Office of New Opportunities and Rural Transformational Health,
# established by Executive Order under Governor Ayotte -- and it runs the
# programme through a small number of DESIGNATED ADMINISTRATORS, each awarded
# by a vote of the Governor and Executive Council on 2026-03-16. NOT ONE OF
# THOSE ADMINISTRATORS HAS NAMED A SUBRECIPIENT. Every GO-NORTH funding
# opportunity this file can reach is open, upcoming, or closed without a
# roster, and the one that would name hospitals -- Critical Access Hospital and
# Acute Care Hospital -- had not been published at all.
#
# So New Hampshire is Illinois's shape at four times the size: an executed
# award to a designated pass-through administrator, hospitals among the
# eligible class, and NO HOSPITAL NAMED ANYWHERE.
#
# THE HOST PROBLEM, AND WHY IT IS NOT THE USUAL ONE. Every www.nh.gov host is
# refused to this environment -- gonorth.nh.gov, dhhs.nh.gov, governor.nh.gov,
# sos.nh.gov, das.nh.gov and the apex all answer Akamai "Access Denied" (403,
# errors.edgesuite.net), on FOUR different user agents including a full Chrome
# UA, and robots.txt is itself 403. Two independent transports agree. The proxy
# logs NO policy denial, so this is the origin's own decision and not a
# reachability question this project can fix by identifying differently: §3's
# michigan.gov exception (where a bare agent DID get 200) WOULD NOT HELP HERE,
# which is measured above rather than assumed.
#
# WHAT MAKES AN EXTRACTION POSSIBLE ANYWAY IS §7, AND ILLINOIS IS THE
# PRECEDENT. §7 admits "a state agency OR DESIGNATED PASS-THROUGH ADMINISTRATOR
# document". ICAHN's own release was the first such source in this project and
# was admissible because the state independently designated it. Here the
# Foundation for Healthy Communities publishes its own award -- the amount, the
# Council date, the CMS financial-assistance footer and its own role -- and
# CDFA publishes the SAME COUNCIL ACTION on the same date from a different
# host. TWO PUBLISHERS, NOTHING ARRANGED.
#
# §0.2 IN ONE DOCUMENT, FOR THE SECOND TIME AFTER VIRGINIA. FHC's page carries
# TWO CMS financial-assistance footers: $204,016,550.20, which is the STATE's
# Tier 1 allotment and matches the §7.1 anchor to the cent, and $66,547,394,
# which is FHC's OWN Tier 3 award. Both are "New Hampshire FY2026", both are
# official, and only the tier separates them.
#
# THE FOOTER IS NON-STRICT HERE, PER SESSION 27's AUDIT. Both of the sentences
# that carry the PROVENANCE have the award action or the programme as their
# grammatical subject; the footers corroborate the AMOUNTS and nothing else,
# and `nh_assert_footer_corroborates()` returns NA rather than throwing when
# called non-strictly (Kansas's demotion, session 28).

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "02_normalize.R"))
source(here::here("R", "utils_recipient_classification.R"))

NH_EVIDENCE_DIR <- here::here("data", "evidence", "NH")
NH_CSV          <- "data/reference/nh_year1_awardees.csv"
NH_STATUS_CSV   <- "data/reference/nh_year1_status.csv"
NH_DISPO_CSV    <- "data/reference/nh_rcj_candidate_disposition.csv"
NH_HOST_THROTTLE_S <- 3
NH_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

NH_SOURCES <- tibble::tribble(
  ~key,             ~file,                                  ~url,
  "fhc_rhtp",       "2026-09-01_fhc_go_north_rhtp.html",
  "https://healthynh.org/initiatives/rural-health-transformation-program",
  "cdfa_statement", "2026-09-01_cdfa_rchip_statement.html",
  "https://nhcdfa.org/cdfa-statement-about-the-rural-community-health-infrastructure-programs/"
)

# EVERY nh.gov HOST THIS SESSION TRIED, AND WHAT EACH ANSWERED. Recorded as
# constants rather than narrated in a commit message, so the next session can
# re-run the experiment instead of re-deciding it. See the header.
NH_BLOCKED_HOSTS <- c(
  "https://www.gonorth.nh.gov/",
  "https://www.gonorth.nh.gov/funding-opportunities-0",
  "https://www.dhhs.nh.gov/programs-services/medicaid/rural-health-transformation-program",
  "https://www.nh.gov/", "https://sos.nh.gov/", "https://www.governor.nh.gov/",
  "https://www.das.nh.gov/", "https://www.nh.gov/council/"
)
NH_BLOCKED_STATUS <- 403L
NH_BLOCKED_EDGE   <- "errors.edgesuite.net"
NH_BLOCKED_AGENTS <- c("project honest (+url)", "RFC Mozilla/5.0 (compatible)",
                       "bare Mozilla/5.0", "full Chrome")
NH_BLOCKED_TESTED <- "2026-09-01"

NH_STATED <- list(
  # FHC's own two footers -- two tiers, one page (§0.2).
  cms_allotment_stated = 204016550.20,
  cms_allotment_anchor = 204016550,
  fhc_award_exact      = 66547394,
  fhc_award_rounded    = "$66.5 million",
  council_date         = "2026-03-16",
  noa_date             = "2025-12-29",
  cdfa_ceiling         = 40000000,
  initiatives_n        = 5L,
  hubs_n               = 5L,
  awards_n             = 2L,
  # FHC's OWN planning range for a portfolio it has not yet awarded. A RANGE OF
  # FUTURE AWARDS IS NOT A ROSTER (§0.3) -- it is carried so the day FHC
  # publishes one, the count has something to be checked against.
  fhc_planned_subawards = "50-100 active subrecipient awards"
)

# THE PROVENANCE, PROGRAMME-SCOPED. Each sentence has the AWARD ACTION or the
# PROGRAMME as its grammatical subject, which is what session 27's audit found
# the CMS footer does NOT have.
NH_PROVENANCE <- list(
  fhc_award = paste(
    "the New Hampshire Executive Council approved $66.5 million in year one",
    "Rural Health Transformation Program funding to the Foundation for",
    "Healthy Communities (FHC)"),
  gonorth_is_rhtp = paste(
    "(GO-NORTH) was established by Executive Order under Governor Kelly",
    "Ayotte, and is funded by the Rural Health Transformation (RHT) Federal",
    "program"),
  cdfa_council = paste(
    "was approved by the Governor and Executive Council on March 16"),
  cdfa_is_rhtp = "in federal Rural Health Transformation Program funds"
)

# THE WEAK FORM, kept and DEMOTED. Subject: "This project".
NH_FOOTER <- list(
  allotment = "financial assistance award totaling $204,016,550.20",
  fhc       = "financial assistance award totaling $66,547,394"
)

# WHY THIS IS NOT AN AWARD FILE OF SUBRECIPIENTS. FHC's own page, in its own
# words. Each is asserted every run and each is DESIGNED TO FAIL the day New
# Hampshire publishes a roster.
NH_NO_ROSTER_YET <- c(
  accepting  = "NOW Accepting Applications for Rural Health Transformation Program",
  cah_coming = "Critical Access Hospital (CAH) and Acute Care Hospital",
  will_manage = "FHC will manage 50-100 active subrecipient awards"
)

# The eligible class, IN FHC's OWN WORDS, and it is why this is
# PASS_THROUGH_UNRESOLVED and not Illinois's PASS_THROUGH_DESIGNATED. ICAHN's
# eligibility was restricted to HOSPITALS ONLY, which met §10.2's second
# clause. FHC's is hospitals AMONG OTHERS, which is §0.3 exactly.
NH_ELIGIBLE_CLASS <- paste(
  "primary care, critical access hospitals, EMS, behavioral health, oral",
  "health, and community-based organizations")

NH_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch -------------------------------------------------------------------

nh_path <- function(key) {
  row <- NH_SOURCES[NH_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NH] unknown source key: ", key, call. = FALSE)
  file.path(NH_EVIDENCE_DIR, row$file)
}

nh_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(NH_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, NH_CREDENTIAL_SHAPES[[nm]])) {
      stop("[NH] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nh_get <- function(url, label) {
  message("[NH] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(NH_USER_AGENT), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[NH] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  nh_assert_credential_free(served, label)
  served
}

nh_fetch <- function(force = FALSE) {
  dir.create(NH_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NH_SOURCES)), function(i) {
    src  <- NH_SOURCES[i, ]
    dest <- file.path(NH_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[NH] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(NH_HOST_THROTTLE_S)
      writeBin(nh_get(src$url, src$file), dest)
    }
    tibble::tibble(file = src$file, url = src$url, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  nh_write_manifest(entries)
  invisible(entries)
}

nh_write_manifest <- function(entries) {
  path <- file.path(NH_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "New Hampshire -- GO-NORTH, the Governor's Office of New Opportunities and",
    "Rural Transformational Health. Archived by R/03x_nh_year1_awardees.R --fetch",
    paste0("User-agent: ", NH_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard runs on every fetch here and finds nothing, so there",
    "is no reduction to explain.",
    "",
    "NEITHER OF THESE IS A STATE HOST, AND THAT IS THE POINT. Every nh.gov host",
    paste0("was refused to this environment on ", NH_BLOCKED_TESTED,
           " -- Akamai 403 (", NH_BLOCKED_EDGE, ") on all of: ",
           paste(NH_BLOCKED_AGENTS, collapse = ", "), ", with robots.txt"),
    "itself 403 and no policy denial logged by the proxy. §7 admits a",
    "DESIGNATED PASS-THROUGH ADMINISTRATOR's own document (Illinois/ICAHN is",
    "the precedent), and both files below are exactly that: FHC publishes its",
    "own award and CDFA publishes the same Governor and Executive Council",
    "action of 2026-03-16 from a different host. TWO PUBLISHERS, NOTHING",
    "ARRANGED.",
    "",
    "NOT ONE SUBRECIPIENT IS NAMED IN EITHER FILE. That is New Hampshire's",
    "position, not a gap in this archive.",
    "",
    strrep("-", 74),
    sprintf("%-42s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 74)
  ), path)
  cat(sprintf("%-42s %10d  %s\n", entries$file, entries$bytes, entries$sha256),
      file = path, append = TRUE, sep = "")
  cat("\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-42s %s\n", entries$file, entries$url),
      file = path, append = TRUE, sep = "")
  invisible(path)
}

nh_html_text <- function(key) {
  path <- nh_path(key)
  if (!file.exists(path)) {
    stop("[NH] ", basename(path), " is not archived. Run --fetch.",
         call. = FALSE)
  }
  doc <- xml2::read_html(path)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}


# -- provenance --------------------------------------------------------------

#' The §6.2 check, PROGRAMME-SCOPED, with the footer demoted
#'
#' Session 27's audit says the axis is the footer's grammatical SUBJECT. Both
#' sentences required here have the award action or the programme as theirs;
#' the footer is checked separately and non-strictly.
nh_assert_rhtp_provenance <- function(fhc = NULL, cdfa = NULL) {
  if (is.null(fhc))  fhc  <- nh_html_text("fhc_rhtp")
  if (is.null(cdfa)) cdfa <- nh_html_text("cdfa_statement")

  for (nm in c("fhc_award", "gonorth_is_rhtp")) {
    if (!stringr::str_detect(fhc, stringr::fixed(NH_PROVENANCE[[nm]]))) {
      stop("[NH] FHC's page no longer carries the programme-scoped sentence '",
           nm, "'. That sentence, NOT the CMS footer, is why this file's rows ",
           "are RHTP.", call. = FALSE)
    }
  }
  for (nm in c("cdfa_council", "cdfa_is_rhtp")) {
    if (!stringr::str_detect(cdfa, stringr::fixed(NH_PROVENANCE[[nm]]))) {
      stop("[NH] CDFA's statement no longer carries '", nm, "'. It is the ",
           "SECOND publisher of the 2026-03-16 Council action and the reason ",
           "that date is corroborated rather than asserted.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The footer, KEPT AND DEMOTED (Kansas's shape, session 28)
#'
#' It corroborates the AMOUNTS -- the state's allotment against the §7.1 anchor
#' and FHC's own award -- and it is NOT the provenance. Called non-strictly it
#' returns NA with a message rather than throwing, so a page re-post that drops
#' the boilerplate cannot hard-fail New Hampshire for no reason; called
#' strictly it is an assertion. A future state whose ONLY evidence is a
#' "this project" footer therefore does not pass the test New Hampshire passes.
nh_assert_footer_corroborates <- function(fhc = NULL, strict = FALSE) {
  if (is.null(fhc)) fhc <- nh_html_text("fhc_rhtp")
  missing <- names(NH_FOOTER)[
    !vapply(NH_FOOTER, function(s) stringr::str_detect(fhc, stringr::fixed(s)),
            logical(1))]
  if (length(missing)) {
    msg <- paste0("[NH] FHC's page no longer carries the CMS footer(s): ",
                  paste(missing, collapse = ", "),
                  ". This is CORROBORATION OF AN AMOUNT, not provenance -- ",
                  "nh_assert_rhtp_provenance() is what makes these rows RHTP.")
    if (strict) stop(msg, call. = FALSE)
    message(msg)
    return(invisible(NA))
  }
  # §0.2 IN ONE DOCUMENT: the two footers are two TIERS.
  stopifnot(abs(NH_STATED$cms_allotment_stated -
                  NH_STATED$cms_allotment_anchor) < 1)
  allot <- rhtp_load_allotments()
  nh <- allot$fy2026_allotment[allot$state == "NH"]
  stopifnot(length(nh) == 1L)
  stopifnot(abs(nh - NH_STATED$cms_allotment_anchor) < 1)
  invisible(TRUE)
}

#' The date test. The Council acted 2026-03-16, eleven weeks after the NOA.
nh_assert_after_noa <- function(cdfa = NULL) {
  if (is.null(cdfa)) cdfa <- nh_html_text("cdfa_statement")
  if (!stringr::str_detect(cdfa, stringr::fixed("Executive Council on March 16"))) {
    stop("[NH] CDFA no longer dates the Council action.", call. = FALSE)
  }
  noa <- rhtp_read_noa_dates()
  anchor <- as.character(noa$noa_date[noa$state == "NH"])
  stopifnot(identical(anchor, NH_STATED$noa_date))
  stopifnot(as.Date(NH_STATED$council_date) > as.Date(anchor))
  invisible(TRUE)
}


# -- the negative, and its controls ------------------------------------------

#' THE ONE THAT DECIDES THE FILE: New Hampshire has named no subrecipient
#'
#' Designed to FAIL the day FHC publishes a roster -- at which point New
#' Hampshire has real, named, recipient-level rows and this file grows from two
#' administrator awards into an award list.
nh_assert_no_roster_yet <- function(fhc = NULL) {
  if (is.null(fhc)) fhc <- nh_html_text("fhc_rhtp")

  for (nm in names(NH_NO_ROSTER_YET)) {
    # Normalise the dash FHC renders as an en dash in "50-100".
    hay <- stringr::str_replace_all(fhc, "–|—", "-")
    if (!stringr::str_detect(hay, stringr::fixed(NH_NO_ROSTER_YET[[nm]]))) {
      stop("[NH] FHC's page no longer says '", nm, "'. NEW HAMPSHIRE MAY HAVE ",
           "PUBLISHED A SUBRECIPIENT ROSTER. That is the signal this ",
           "assertion exists for, not a defect: read the page, and if FHC has ",
           "named recipients, extract them -- its hospital RFA is where this ",
           "state's hospital dollars are.", call. = FALSE)
    }
  }

  # The eligible class is hospitals AMONG OTHERS. If FHC ever restricts a pool
  # to hospitals only AND has awarded it, that pool is Illinois's
  # PASS_THROUGH_DESIGNATED and codes `Yes`, not `Unclear`.
  if (!stringr::str_detect(fhc, stringr::fixed(NH_ELIGIBLE_CLASS))) {
    stop("[NH] FHC no longer states the eligible class in the words this ",
         "file's PASS_THROUGH_UNRESOLVED coding rests on. Re-read §10.2 ",
         "before changing the coding: ICAHN is `Yes` because its class was ",
         "HOSPITALS ONLY; FHC is `Unclear` because its class is hospitals ",
         "AMONG OTHERS (§0.3).", call. = FALSE)
  }
  invisible(TRUE)
}

#' The POSITIVE CONTROL. A negative is only a finding if this file can
#' demonstrably recognise what New Hampshire's own publications look like when
#' they DO carry recipient-level content.
#'
#' FHC publishes a structured funding-opportunity list with an explicit status
#' against each -- Open, Upcoming, Closed. That is the recognisable form, and
#' this asserts all three states are present. Without it, "no roster" is
#' indistinguishable from "we are reading the wrong page".
nh_assert_opportunity_index <- function(fhc = NULL) {
  if (is.null(fhc)) fhc <- nh_html_text("fhc_rhtp")
  for (state in c("Funding Opportunities - Upcoming",
                  "Funding Opportunities - Closed",
                  "Current Funding Opportunities")) {
    if (!stringr::str_detect(fhc, stringr::fixed(state))) {
      stop("[NH] FHC's funding-opportunity index no longer carries the '",
           state, "' section. That index IS this file's positive control: it ",
           "is how we know a roster would be recognisable if one existed.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The host record: nh.gov is UNREACHABLE, which is not the same as a negative
#'
#' §0.4. Every claim in this file is about what FHC and CDFA publish. What the
#' State of New Hampshire publishes on gonorth.nh.gov is UNKNOWN to this
#' repository, and that must never harden into "New Hampshire has published
#' nothing".
nh_blocked_hosts <- function() {
  tibble::tibble(
    url         = NH_BLOCKED_HOSTS,
    http_status = NH_BLOCKED_STATUS,
    edge        = NH_BLOCKED_EDGE,
    agents_tried = paste(NH_BLOCKED_AGENTS, collapse = "; "),
    tested_on   = NH_BLOCKED_TESTED
  )
}


# -- the award rows ----------------------------------------------------------

#' New Hampshire's TWO Council-approved administrator awards, in the §8 union
#' schema. NEITHER NAMES A HOSPITAL, and neither is a hospital dollar.
rhtp_nh_year1_awardees <- function() {
  tibble::tribble(
    ~row_no, ~awardee, ~amount,
    1L, "Foundation for Healthy Communities (FHC)", NH_STATED$fhc_award_exact,
    2L, "New Hampshire Community Development Finance Authority (CDFA)",
    NA_real_
  ) %>%
    dplyr::mutate(
      state = "NH",
      recipient_type = "NONPROFIT_CBO",
      distributed_to_hospital = c("Unclear", "No"),
      note = c(
        paste0("Approved by the New Hampshire Executive Council 2026-03-16. ",
               "FHC is the designated statewide administrator for GO-NORTH ",
               "and describes itself as 'the statewide leader and unified ",
               "voice for New Hampshire's hospitals and health systems'. It ",
               "has named NO subrecipient: every funding opportunity it ",
               "publishes is open, upcoming, or closed without a roster, and ",
               "the Critical Access Hospital and Acute Care Hospital RFA is ",
               "'Coming Soon'. FHC's own planning figure is '",
               NH_STATED$fhc_planned_subawards, "' -- A RANGE OF FUTURE ",
               "AWARDS IS NOT A ROSTER (§0.3)."),
        paste0("Approved by the same Governor and Executive Council action of ",
               "2026-03-16. CDFA states 'up to $40 million a year' -- A ",
               "CEILING, NOT AN AWARD FIGURE -- so `amount` is EMPTY and the ",
               "ceiling is in `round_amount` (South Dakota's device). Its ",
               "eligible facilities are 'rural health clinics, community ",
               "mental health centers, federally qualified health centers and ",
               "county-run assisted living facilities' -- HOSPITALS ARE NOT ",
               "IN THAT CLASS, so this is NON_HOSPITAL on the recipient class ",
               "the source itself states.")),
      round_amount = c(NA_real_, NH_STATED$cdfa_ceiling),
      recipient_confirmed = "Yes",
      amount_confirmed = c("Yes", "No"),
      fiscal_year = "FY2026",
      source_document_title = c(
        "GO-NORTH FHC Rural Health Transformation Program",
        "CDFA Statement about the Rural Community Health Infrastructure Programs"),
      state_source_url = NH_SOURCES$url[match(c("fhc_rhtp", "cdfa_statement"),
                                              NH_SOURCES$key)],
      validation_source_type = "AGENCY_PRESS_RELEASE",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_character_, aha_id = NA_character_,
      rural_designation = NA_character_, reviewer = NA_character_,
      recipient_type_source = c(
        paste("Not stated as a legal form. FHC self-describes as 'the",
              "statewide leader and unified voice for New Hampshire's",
              "hospitals and health systems', which is §10.2's hospital-body",
              "branch; it is NONPROFIT_CBO on AK's and IL's convention."),
        paste("A state-chartered public instrumentality administering",
              "community development funds. Not stated as a legal form on the",
              "page; NONPROFIT_CBO on §8's standing fallback.")),
      determination_confidence = "LOW",
      flag_reason = c(
        paste("RECIPIENT_NAMES_NOT_CAPTURED;SUBAWARD_PROCESS_NOT_YET_RUN;",
              "RECIPIENT_TYPE_INFERRED", sep = ""),
        paste("RECIPIENT_NAMES_NOT_CAPTURED;SUBAWARD_PROCESS_NOT_YET_RUN;",
              "RECIPIENT_TYPE_INFERRED;AMOUNT_PRELIMINARY", sep = "")),
      flow_type = c("PASS_THROUGH_UNRESOLVED", "NON_HOSPITAL"),
      intermediary_name = c("Foundation for Healthy Communities (FHC)",
                            NA_character_),
      hospital_attribution = "NOT_HOSPITAL",
      hospital_recipient_count = NA_integer_,
      hospital_benefiting = c("Yes", "No"),
      determination_basis = c(
        paste("§10.2 PASS_THROUGH_UNRESOLVED, and the contrast with Illinois",
              "is the whole reason. ICAHN codes `Yes` because its eligibility",
              "was restricted to HOSPITALS ONLY and its award was executed --",
              "both clauses of §10.2's PASS_THROUGH_DESIGNATED row. FHC's",
              "award is executed, but its eligible class is, in its own",
              "words,", paste0("'", NH_ELIGIBLE_CLASS, "'"), "-- hospitals",
              "AMONG other eligible entities. §0.3: eligibility is not",
              "receipt, and an unresolved pass-through pool codes Unclear and",
              "is NEVER imputed. It enters NEITHER bucket of",
              "rhtp_hospital_dollar_partition()."),
        paste("§10.2 NON_HOSPITAL, judged on the RECIPIENT CLASS the source",
              "itself states (§0.3a): CDFA's eligible facilities are rural",
              "health clinics, community mental health centres, FQHCs and",
              "county-run assisted living facilities. Hospitals are not among",
              "them. No hospital dollar either way.")),
      source_archive_path = file.path(
        "data/evidence/NH",
        NH_SOURCES$file[match(c("fhc_rhtp", "cdfa_statement"),
                              NH_SOURCES$key)]),
      recipient_names_source_url = NA_character_,
      amount_basis = c(
        paste0("EXACT, from the page's own CMS financial-assistance footer: ",
               "'", NH_FOOTER$fhc, "'. The programme-scoped Council sentence ",
               "states the same award ROUNDED (", NH_STATED$fhc_award_rounded,
               "), and the two agree. The footer is used here for what ",
               "session 27's audit says it can carry -- AN AMOUNT -- and not ",
               "as the provenance."),
        paste0("NOT PUBLISHED. CDFA states 'up to $40 million a year', which ",
               "is a ceiling on a programme and not an award to CDFA. ",
               "`amount` is deliberately empty so no sum over the column can ",
               "read as a per-recipient figure (§6.2).")),
      amount_precision = c("EXACT", NA_character_),
      disbursement_status = "APPROVED_BY_COUNCIL",
      classification_rule = c("NH_FHC_PASS_THROUGH_UNRESOLVED",
                              "NH_CDFA_NON_HOSPITAL_CLASS"),
      council_date = NH_STATED$council_date
    ) %>%
    dplyr::select(state, row_no, awardee, amount, recipient_type,
                  distributed_to_hospital, note, recipient_confirmed,
                  amount_confirmed, fiscal_year, source_document_title,
                  state_source_url, validation_source_type, extraction_method,
                  validator, ccn, aha_id, rural_designation, reviewer,
                  dplyr::everything())
}


# -- the status table --------------------------------------------------------

#' What each GO-NORTH administrator publishes -- Texas's device
#'
#' THERE IS DELIBERATELY NO `amount` COLUMN, and an assertion refuses one. New
#' Hampshire has named no subrecipient and published no per-subrecipient
#' figure, so a column named `amount` here would invite a sum over a quantity
#' that does not exist. The two administrator awards that ARE evidenced live in
#' nh_year1_awardees.csv; this table is about ROSTERS.
rhtp_nh_status <- function() {
  tibble::tribble(
    ~administrator, ~role, ~host_reachable, ~publishes_roster, ~evidence,
    "Foundation for Healthy Communities (FHC)",
    "Statewide administrator; the hospital-facing pools",
    "Yes", "No",
    paste("Its funding-opportunity index carries Open, Upcoming and Closed",
          "sections and NOT ONE NAMED RECIPIENT. The Critical Access Hospital",
          "and Acute Care Hospital RFA -- the one that would name hospitals --",
          "is 'Coming Soon'. Primary Care's own key date is 'Notification of",
          "Award (initial cohort): Late October'."),

    "NH Community Development Finance Authority (CDFA)",
    "Rural Community Health Infrastructure Program",
    "Yes", "No",
    paste("'The initial Rural Community Health Infrastructure Program WILL",
          "AWARD funds' -- future tense. Its most recent published step is a",
          "Request for Eligibility Determination Form. Eligible facilities",
          "exclude hospitals."),

    "Community College System of New Hampshire (CCSNH)",
    "Workforce -- Healthcare Career Guidance Hub",
    "Yes", "No",
    paste("Its only GO-NORTH item is a 2026-03-30 announcement that CCSNH",
          "'joins the Governor & GO-NORTH in statewide effort'. No recipient",
          "list, and a workforce hub is not a hospital dollar in any case."),

    "NH Community Behavioral Health Association (CBHA)",
    "Behavioral health -- the ten community mental health centres",
    "Yes", "No",
    paste("Carries a GO-NORTH navigation item and no roster. Its member class",
          "is the ten community mental health centres, which is stated and is",
          "not hospitals."),

    "University System of New Hampshire (USNH)",
    "Workforce / academic",
    "Yes", "No",
    paste("RCJ's source for USNH is a SciQuest public bid portal, which is a",
          "solicitation channel and not an award roster."),

    "GO-NORTH (gonorth.nh.gov) and NH DHHS",
    "The State's own programme sites -- WHERE A ROSTER WOULD LIVE",
    "No", "UNKNOWN",
    paste0("UNREACHABLE, NOT NEGATIVE (§0.4). Every nh.gov host answers ",
           "Akamai 403 (", NH_BLOCKED_EDGE, ") to this environment on all of: ",
           paste(NH_BLOCKED_AGENTS, collapse = ", "),
           "; robots.txt is itself 403, so no crawler policy is on offer; two ",
           "independent transports agree and the proxy logs no policy denial. ",
           "§3's michigan.gov exception WOULD NOT HELP -- a bare agent is ",
           "refused here too. Whether the State publishes a roster of its own ",
           "is UNKNOWN to this repository.")
  ) %>%
    dplyr::mutate(state = "NH", .before = 1)
}


# -- RCJ candidate disposition -----------------------------------------------

nh_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>% dplyr::filter(state == "NH", award_tier == "SUBAWARD")
}

#' Why each of RCJ's NH Tier 3 candidates is, or is not, an award row
#'
#' The counts are RE-DERIVED from the record table on every run (Texas's rule),
#' so the day New Hampshire's candidate set moves this fails instead of quietly
#' ceasing to cover it.
rhtp_nh_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- nh_rcj_candidates()
  nm <- cands$awardee_name_clean

  is_mcm   <- stringr::str_detect(nm, "AmeriHealth Caritas|WellSense|Healthy Families")
  is_fhc   <- stringr::str_detect(nm, "Foundation for Healthy Communities")
  is_cdfa  <- stringr::str_detect(nm, "Community Development Finance Authority")
  is_admin <- stringr::str_detect(
    nm, "Community College System|Community Behavioral Health|University (System )?of New Hampshire|National Opinion Research|NORC")
  is_other <- !(is_mcm | is_fhc | is_cdfa | is_admin)

  tibble::tribble(
    ~group, ~rows, ~disposition, ~why,

    "Medicaid Care Management -- NOT RHTP",
    sum(is_mcm),
    "NOT_RHTP_MEDICAID",
    paste("New Hampshire's Medicaid managed care organisations, carried under",
          "MCM-titled documents. One of these rows is the $1,898,965,390",
          "against a $204,016,550 allotment that the §6.2 allotment ceiling",
          "flagged in session 5 and the provenance sweep independently",
          "disposed of in session 20 -- TWO §6.2 FILTERS, OPPOSITE",
          "DIRECTIONS, SAME ROW. Not RHTP, and already quarantined."),

    "Foundation for Healthy Communities -- a real award, RCJ's amount short",
    sum(is_fhc),
    "RHTP_AWARD_AMOUNT_UNDERSTATED",
    paste0("RCJ carries $66,500,000 -- the Council's ROUNDED figure -- ",
           "against FHC's own exact $", format(NH_STATED$fhc_award_exact,
                                               big.mark = ","),
           ", short by $", format(NH_STATED$fhc_award_exact - 66500000,
                                  big.mark = ","),
           ". The award is real and is in this file at the recipient's own ",
           "figure. RCJ carries FHC on ", sum(is_fhc), " rows: the rounded ",
           "Council figure, and a $1 placeholder."),

    "CDFA -- a real Council action, RCJ prices a CEILING as an award",
    sum(is_cdfa),
    "RHTP_AWARD_AMOUNT_IS_A_CEILING",
    paste0("RCJ carries CDFA on ", sum(is_cdfa), " rows under three ",
           "spellings of one organisation, at $43,810,000, $43,800,000 ",
           "(twice), $40,000,000 and a $1 placeholder. CDFA's own statement ",
           "says 'up to $40 million A YEAR' -- a programme ceiling, not an ",
           "award figure -- so this file carries CDFA with an EMPTY `amount` ",
           "and the ceiling in `round_amount`. THREE DISTINCT PRICES FOR ONE ",
           "COUNCIL ACTION IS THE TELL: the aggregator is pricing DOCUMENTS, ",
           "not awards, and §2 forbids a machine merging the spellings."),

    "Other GO-NORTH administrators -- named, but no amount this file can source",
    sum(is_admin),
    "RHTP_ADMINISTRATOR_NO_PRIMARY_AMOUNT",
    paste("CCSNH, CBHA, USNH and NORC appear as GO-NORTH administrators and",
          "each is plausibly a real Council-approved award. NONE publishes its",
          "own award figure on a host this repository can reach, and the",
          "State's own sites are Akamai-403, so there is no primary source for",
          "an amount. §0.1 forbids publishing RCJ's figure in its place, so",
          "they are in nh_year1_status.csv and NOT in the award file. THAT IS",
          "A STATEMENT ABOUT OUR ACCESS, NOT ABOUT NEW HAMPSHIRE (§0.4)."),

    "Placeholder and unresolved rows",
    sum(is_other),
    "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED",
    paste("'GO-NORTH Planning Grant Agreement', carried at $1, whose awardee",
          "is THE AGREEMENT and not an organisation -- §6.1's",
          "PROGRAM_NAME_AS_AWARDEE. The $1 is Missouri's placeholder mechanism",
          "again, and it runs through this whole candidate set: FHC and CDFA",
          "each carry a $1 row too. RCJ publishes a PLACEHOLDER rather than a",
          "wrong figure, which is the one defect no amount check can see.")
  ) %>%
    dplyr::mutate(state = "NH", .before = 1)
}


# -- reconcile, assert, build, report ----------------------------------------

rhtp_nh_reconcile <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_nh_year1_awardees()
  allot <- rhtp_load_allotments()
  nh_allot <- allot$fy2026_allotment[allot$state == "NH"]
  list(
    awards_n        = nrow(awards),
    awards_total    = sum(awards$amount, na.rm = TRUE),
    cms_allotment   = nh_allot,
    share_of_allotment = sum(awards$amount, na.rm = TRUE) / nh_allot,
    named_hospitals = sum(awards$hospital_attribution == "NAMED_HOSPITAL"),
    hospital_dollars = sum(
      awards$amount[awards$hospital_attribution == "NAMED_HOSPITAL"],
      na.rm = TRUE)
  )
}

rhtp_nh_assert <- function(awards = NULL) {
  if (is.null(awards)) awards <- rhtp_nh_year1_awardees()

  # 1. The Texas check, programme-scoped, with the footer DEMOTED.
  nh_assert_rhtp_provenance()
  nh_assert_footer_corroborates(strict = FALSE)
  nh_assert_after_noa()

  # 2. THE ONE THAT DECIDES THE FILE, and its positive control.
  nh_assert_no_roster_yet()
  nh_assert_opportunity_index()

  # 3. Vocabulary (§8).
  stopifnot(all(awards$recipient_type %in%
                  rhtp_vocabulary("recipient_type")))
  stopifnot(all(awards$flow_type %in% rhtp_vocabulary("flow_type")))
  stopifnot(all(awards$distributed_to_hospital %in% c("Yes", "No", "Unclear")))
  stopifnot(all(awards$hospital_attribution %in%
                  rhtp_vocabulary("hospital_attribution")))

  # 4. NEW HAMPSHIRE HAS NO NAMED HOSPITAL AND NO HOSPITAL DOLLAR.
  rec <- rhtp_nh_reconcile(awards)
  stopifnot(rec$awards_n == NH_STATED$awards_n)
  stopifnot(rec$named_hospitals == 0L)
  stopifnot(rec$hospital_dollars == 0)
  stopifnot(abs(rec$awards_total - NH_STATED$fhc_award_exact) < 0.005)

  # 5. CDFA'S `amount` IS EMPTY AND ITS CEILING IS NOT IN IT (§6.2).
  cdfa <- awards[awards$row_no == 2L, ]
  stopifnot(is.na(cdfa$amount))
  stopifnot(cdfa$round_amount == NH_STATED$cdfa_ceiling)

  # 6. The status table must never grow an amount column (Texas's device).
  status <- rhtp_nh_status()
  if (any(c("amount", "round_amount") %in% names(status))) {
    stop("[NH] nh_year1_status.csv has grown an amount column. It must not: ",
         "New Hampshire has named no subrecipient and published no ",
         "per-subrecipient figure.", call. = FALSE)
  }
  # And it must keep saying the State's own sites are UNREACHABLE, not empty.
  stopifnot(any(status$publishes_roster == "UNKNOWN"))

  # 7. The disposition covers every candidate, re-derived not typed.
  cands <- nh_rcj_candidates()
  dispo <- rhtp_nh_rcj_disposition(cands)
  stopifnot(sum(dispo$rows) == nrow(cands))

  invisible(TRUE)
}

rhtp_nh_build <- function() {
  awards <- rhtp_nh_year1_awardees()
  rhtp_nh_assert(awards)
  readr::write_csv(awards, here::here(NH_CSV), na = "")
  readr::write_csv(rhtp_nh_status(), here::here(NH_STATUS_CSV), na = "")
  readr::write_csv(rhtp_nh_rcj_disposition(), here::here(NH_DISPO_CSV), na = "")
  message("[NH] wrote ", NH_CSV, " (", nrow(awards), " rows), ",
          NH_STATUS_CSV, ", ", NH_DISPO_CSV)
  invisible(awards)
}

rhtp_nh_report <- function() {
  awards <- rhtp_nh_year1_awardees()
  rec    <- rhtp_nh_reconcile(awards)
  message("NEW HAMPSHIRE -- GO-NORTH, Year 1")
  message("  Council-approved administrator awards : ", rec$awards_n)
  message("  Sourced to a primary amount           : $",
          format(rec$awards_total, big.mark = ","))
  message("  CMS FY2026 allotment                  : $",
          format(rec$cms_allotment, big.mark = ","))
  message("")
  message("  NAMED HOSPITALS                       : ", rec$named_hospitals)
  message("  NAMED-HOSPITAL DOLLARS                : $", rec$hospital_dollars)
  message("")
  message("  New Hampshire has named NO subrecipient. FHC is the designated")
  message("  statewide administrator and its hospital RFA -- Critical Access")
  message("  Hospital and Acute Care Hospital -- was still 'Coming Soon'.")
  message("  Its eligible class is hospitals AMONG OTHERS, so §10.2 makes it")
  message("  PASS_THROUGH_UNRESOLVED and Unclear, in NEITHER bucket -- NOT")
  message("  Illinois's `Yes`, which required HOSPITALS ONLY.")
  message("")
  message("  Every nh.gov host is Akamai-403 to this environment. What the")
  message("  State publishes on gonorth.nh.gov is UNKNOWN, not absent (§0.4).")
  invisible(rec)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--fetch" %in% args)    nh_fetch(force = force)
  if ("--validate" %in% args) { rhtp_nh_assert(); message("[NH] all assertions pass.") }
  if ("--build" %in% args)    rhtp_nh_build()
  if ("--report" %in% args)   rhtp_nh_report()
  if (!length(intersect(args, c("--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03x_nh_year1_awardees.R ",
            "[--fetch [--force]] [--validate] [--build] [--report]")
  }
}

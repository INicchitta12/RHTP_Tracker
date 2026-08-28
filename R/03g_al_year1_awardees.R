# 03g_al_year1_awardees.R ----------------------------------------------------
# Alabama Year 1 awardees -> data/reference/al_year1_awardees.csv (+ a render).
#
# WHAT THIS IS. Governor Ivey's 2026-08-24 release announces 138 grants worth
# "more than $144 million" under the Alabama Rural Health Transformation Program
# (ARHTP), and prints every recipient, amount and county served in the body of
# the page. It is a complete recipient-level award list -- the second of the
# three states whose hosts opened this session.
#
# THE LIST IS PROSE, NOT A TABLE, AND IT HAS TWO SHAPES. Under each of the five
# funded initiatives there is a <ul> of recipients:
#
#   <li><strong>NAME</strong> - $AMOUNT to do the thing (counties).</li>
#
# and, where a recipient won twice under one initiative, the first grant is in
# the <li> and the SECOND IS A BARE <p> THAT FOLLOWS IT:
#
#   <li><strong>NAME</strong> - This hospital has received two grants under this
#       initiative, including $625,257 to ...</li>
#   <p>A second grant for $176,980 will purchase ...</p>
#
# That continuation paragraph carries NO recipient name of its own. A parser
# that reads only <li> elements loses 14 award actions and $8.1M; a parser that
# reads every block as an award invents 14 nameless recipients. Both failures
# are silent. rhtp_al_parse_awards() therefore carries the preceding <li>'s
# recipient forward onto the continuation, records award_sequence = SECOND, and
# hard-fails if a continuation appears with no <li> before it.
#
# 45 OF THE 138 AMOUNTS ARE ROUNDED TO TWO DECIMALS OF A MILLION, and the
# release says so by writing them that way ("$6.38 million", "$1.4 million").
# They are recorded as published and flagged `amount_precision =
# ROUNDED_TO_MILLIONS` rather than being reconstructed. The consequence is
# visible and must stay visible: the release's own figures sum to $143,745,821
# while its headline says "more than $144 million". That gap is the rounding,
# it is reported on the Reconciliation sheet, and it is NOT closed by adjusting
# a number nobody published. ADECA's own award file would settle it; adeca.
# alabama.gov and alabamarhtp.com are both still unreachable from this session.
#
# COUNTY LISTS ARE KEPT WHOLE (§8: never discard the state's own language).
#
# CLASSIFICATION IS NOT DONE HERE -- R/utils_recipient_classification.R holds the
# §8/§10.2 rules for every state. Alabama incorporates its county hospitals as
# "... Health Care Authority", which is why that pattern codes HOSPITAL_OR_SYSTEM
# there, and why the four UAB St. Vincent's hospitals need an override: their
# names carry no hospital token and the university rule would otherwise take
# four hospitals out of the hospital total.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network.
#
# CLI:
#   Rscript R/03g_al_year1_awardees.R --fetch     # archive the release + SHA-256
#   Rscript R/03g_al_year1_awardees.R --validate  # parse + assert, no writes
#   Rscript R/03g_al_year1_awardees.R --build     # assert, write CSV + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(purrr)
  library(readr)
  library(rvest)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

AL_STATE <- "AL"

AL_RELEASE_URL <- paste0(
  "https://governor.alabama.gov/newsroom/2026/08/governor-ivey-announces-",
  "first-grants-in-major-new-rural-healthcare-program-totaling-more-than-",
  "144-million/"
)
AL_RELEASE_FILE  <- "2026-08-24_governor_ivey_first_arhtp_grants.html"
AL_MANIFEST_FILE <- "al_rhtp_year1_awards.manifest.txt"

AL_EVIDENCE_DIR <- "data/evidence/AL"
AL_CSV  <- "data/reference/al_year1_awardees.csv"
AL_XLSX <- "AL_year1_awardees.xlsx"

# What the release and CMS both state.
AL_STATED_GRANT_COUNT   <- 138L
AL_STATED_INITIATIVES   <- 5L
AL_STATED_YEAR1_AWARD   <- 203404326.54  # the CMS award named in the footnote

# The marker the release uses for a second grant to the same recipient under the
# same initiative. Anchored to the start of the block: the phrase appears inside
# first-grant sentences too ("has received two grants ... including one for").
AL_SECOND_GRANT_MARKER <- "^A second grant"


# -- Fetch and archive -------------------------------------------------------

rhtp_al_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(AL_EVIDENCE_DIR)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, AL_RELEASE_FILE)

  if (file.exists(path) && !force) {
    message("  already archived: ", AL_RELEASE_FILE, " -- pass --force to re-fetch.")
    return(invisible(path))
  }

  resp <- httr2::request(AL_RELEASE_URL) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
    httr2::req_perform()

  status <- httr2::resp_status(resp)
  if (status != 200) {
    stop("[AL] ", AL_RELEASE_URL, " returned HTTP ", status,
         "; refusing to archive a non-200 body.", call. = FALSE)
  }
  body <- httr2::resp_body_string(resp)

  # Parse before writing (the R/00 posture).
  parsed <- rhtp_al_parse_awards(body)
  if (nrow(parsed) != AL_STATED_GRANT_COUNT) {
    stop("[AL] the release parsed to ", nrow(parsed), " award actions; both the",
         " governor and CMS state ", AL_STATED_GRANT_COUNT,
         ". Refusing to archive a parse that does not match.", call. = FALSE)
  }

  writeLines(body, path, useBytes = TRUE)

  writeLines(paste0(
    "RHTP tracker archive (spec 0.4 / 0.5): Alabama Rural Health Transformation\n",
    "Program (ARHTP), first round of grant awards.\n\n",
    "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
    "state           : AL\n",
    "host            : governor.alabama.gov\n",
    "http_status     : ", status, "\n",
    "source_doc_type : GOVERNOR_PRESS_RELEASE\n",
    "program         : Alabama Rural Health Transformation Program (ARHTP),\n",
    "                  administered by ADECA\n",
    "cms_year1_award : $203,404,326.54 (stated in the release's footnote)\n\n",
    "FILE\n\n",
    "  file    : ", AL_RELEASE_FILE, "\n",
    "  title   : Governor Ivey Announces First Grants in Major New Rural\n",
    "            Healthcare Program Totaling More than $144 Million\n",
    "  date    : 2026-08-24\n",
    "  url     : ", AL_RELEASE_URL, "\n",
    "  bytes   : ", nchar(body, type = "bytes"), "\n",
    "  sha256  : ", digest::digest(body, algo = "sha256", serialize = FALSE), "\n\n",
    "WHAT THIS DOCUMENT SUPPORTS (spec 9.2, Part A of reviewer-coding-instructions)\n\n",
    "This is ONE document and it supports the coding on its own: it names the\n",
    "recipient, the amount, the initiative and the counties served for every one\n",
    "of the ", AL_STATED_GRANT_COUNT, " grants, and it states them as awarded --\n",
    "'announced the awarding of 138 grants'. That is §9.2's Yes test met by an\n",
    "official governor's release naming the recipient.\n\n",
    "THE AMOUNTS ARE MIXED PRECISION. 93 are exact to the dollar; 45 are written\n",
    "as a rounded number of millions ('$6.38 million'). They are stored as\n",
    "published, flagged amount_precision = ROUNDED_TO_MILLIONS, and the resulting\n",
    "gap -- the release's own figures sum to $143,745,821 against its headline\n",
    "'more than $144 million' -- is reported rather than closed. ADECA publishes\n",
    "the underlying award file; adeca.alabama.gov and alabamarhtp.com were both\n",
    "unreachable when this was extracted.\n\n",
    "14 OF THE 138 ARE SECOND GRANTS carried in a continuation paragraph that\n",
    "names no recipient of its own. They inherit the preceding recipient and\n",
    "carry award_sequence = SECOND. Reading only the list items would lose them.\n"
  ), file.path(dir, AL_MANIFEST_FILE))

  message("  archived the Alabama release to ", AL_EVIDENCE_DIR,
          " (", nrow(parsed), " award actions parsed)")
  invisible(path)
}


# -- Parse -------------------------------------------------------------------

#' Read a dollar figure the way the release writes it
#'
#' Returns the value and whether the release rounded it. "$6.38 million" is
#' 6,380,000 and ROUNDED; "$867,102" is exact.
rhtp_al_parse_amount <- function(text) {
  m <- stringr::str_match(text, "\\$([0-9][0-9,]*(?:\\.[0-9]+)?)(\\s*million)?")
  if (is.na(m[1, 1])) {
    return(list(amount = NA_real_, precision = NA_character_))
  }
  value <- as.numeric(stringr::str_remove_all(m[1, 2], ","))
  rounded <- !is.na(m[1, 3])
  list(
    amount = if (rounded) value * 1e6 else value,
    precision = if (rounded) "ROUNDED_TO_MILLIONS" else "EXACT_AS_PUBLISHED"
  )
}


#' Parse the 138 award actions out of the archived release
#'
#' Walks the award section in document order. An <li> starts a new recipient; a
#' <p> that begins "A second grant" continues the previous one. Anything else in
#' the section is either an initiative heading or the closing marker.
rhtp_al_parse_awards <- function(html) {
  doc <- rvest::read_html(html)

  intro <- rvest::html_elements(doc, xpath = paste0(
    "//p[contains(., 'Below are the healthcare providers')]"
  ))
  if (length(intro) != 1L) {
    stop("[AL] expected exactly 1 'Below are the healthcare providers' ",
         "paragraph to anchor the award list, found ", length(intro),
         ". Refusing to guess where the list starts.", call. = FALSE)
  }

  # Everything after the anchor, in document order.
  blocks <- rvest::html_elements(intro, xpath = "following::p | following::li")

  squish <- function(x) {
    stringr::str_squish(stringr::str_replace_all(x, " ", " "))
  }

  initiative <- NA_character_
  current_awardee <- NA_character_
  rows <- list()
  stopped <- FALSE

  for (node in blocks) {
    tag <- rvest::html_name(node)
    text <- squish(rvest::html_text2(node))
    if (!nzchar(text)) next

    # The release closes its award section with a "###" paragraph. Everything
    # after it is site chrome.
    if (stringr::str_detect(text, "^#+$")) {
      stopped <- TRUE
      break
    }

    # An initiative heading: a <p> that is nothing but a bolded name ending in
    # "Initiative".
    if (tag == "p" && stringr::str_detect(text, "Initiative$")) {
      strong <- squish(rvest::html_text2(
        rvest::html_elements(node, "strong, b")))
      if (length(strong) == 1L && identical(strong, text)) {
        initiative <- text
        current_awardee <- NA_character_
        next
      }
    }

    if (tag == "li") {
      strong <- squish(rvest::html_text2(rvest::html_elements(node, "strong, b")))
      if (!length(strong) || !nzchar(strong[1])) {
        stop("[AL] a list item in the award section carries no bolded ",
             "recipient name: ", substr(text, 1, 120),
             ". Refusing to attribute an award to no one.", call. = FALSE)
      }
      # The release ends some bolded names with the dash that separates the name
      # from the amount.
      name <- stringr::str_squish(
        stringr::str_remove(strong[1], "[\\s–—-]+$"))
      current_awardee <- name
      amt <- rhtp_al_parse_amount(text)
      rows[[length(rows) + 1L]] <- tibble::tibble(
        initiative_raw = initiative,
        awardee = name,
        award_sequence = "FIRST",
        amount = amt$amount,
        amount_precision = amt$precision,
        project_description = text
      )
      next
    }

    if (tag == "p" && stringr::str_detect(text, AL_SECOND_GRANT_MARKER)) {
      if (is.na(current_awardee)) {
        stop("[AL] a 'A second grant' paragraph appeared with no preceding ",
             "recipient: ", substr(text, 1, 120),
             ". Refusing to attribute an award to no one.", call. = FALSE)
      }
      amt <- rhtp_al_parse_amount(text)
      rows[[length(rows) + 1L]] <- tibble::tibble(
        initiative_raw = initiative,
        awardee = current_awardee,
        award_sequence = "SECOND",
        amount = amt$amount,
        amount_precision = amt$precision,
        project_description = text
      )
      next
    }
  }

  if (!stopped) {
    stop("[AL] the award section's closing '###' marker was never reached; ",
         "the parse would have run into site chrome. Refusing.", call. = FALSE)
  }

  out <- dplyr::bind_rows(rows)

  if (any(is.na(out$initiative_raw))) {
    stop("[AL] ", sum(is.na(out$initiative_raw)),
         " award action(s) appeared before any initiative heading.",
         call. = FALSE)
  }
  if (any(is.na(out$amount))) {
    missing <- out$awardee[is.na(out$amount)]
    stop("[AL] no dollar figure found for: ", paste(missing, collapse = "; "),
         call. = FALSE)
  }

  out
}


#' Pull the counties served out of the release's own trailing parenthetical
#'
#' Kept verbatim (§8: never discard the state's own language). Returns "" where
#' the release names no county -- several statewide awards do not.
rhtp_al_counties <- function(description) {
  m <- stringr::str_match(description, "\\(([^()]*)\\)\\.?$")
  counties <- ifelse(is.na(m[, 2]), "", stringr::str_squish(m[, 2]))
  # Some parentheticals are a count prefix rather than the list itself, e.g.
  # "in 43 counties (Baldwin, ...)" -- the regex already takes the inner list.
  counties
}


rhtp_al_build <- function() {
  path <- here::here(AL_EVIDENCE_DIR, AL_RELEASE_FILE)
  if (!file.exists(path)) {
    stop("[AL] the release archive is missing: ", path, ". Run --fetch first.",
         call. = FALSE)
  }

  parsed <- rhtp_al_parse_awards(readr::read_file(path))

  classified <- parsed %>%
    rhtp_classify_records(state = AL_STATE,
                          description_col = "project_description")

  classified %>%
    dplyr::mutate(
      state = AL_STATE,
      row_no = dplyr::row_number(),
      counties_served = rhtp_al_counties(.data$project_description),
      note = paste0(
        .data$initiative_raw,
        dplyr::if_else(.data$award_sequence == "SECOND",
                       " | second grant to this recipient under this initiative",
                       "")
      ),
      recipient_confirmed = "Yes",
      amount_confirmed = "Yes",
      fiscal_year = "FY2026 (Year 1)",
      source_document_title = paste0(
        "Governor Ivey Announces First Grants in Major New Rural Healthcare ",
        "Program Totaling More than $144 Million"
      ),
      state_source_url = AL_RELEASE_URL,
      validation_source_type = "GOVERNOR_PRESS_RELEASE",
      extraction_method = "MODEL_ASSISTED",
      validator = "AI-assisted - CONFIRM",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = NA_character_,
      amount_basis = "PER_AWARD_ACTION",
      disbursement_status = "AWARDED",
      source_archive_path = file.path(AL_EVIDENCE_DIR, AL_RELEASE_FILE),
      recipient_names_source_url = AL_RELEASE_URL,
      activity_type_raw = .data$initiative_raw,
      # The rounding is part of the determination, so it is written into the
      # basis rather than living only in a column a reader might not open.
      determination_basis = paste0(
        .data$determination_basis,
        " Source: Governor Ivey's 2026-08-24 release, which states the awarding",
        " of 138 grants and names this recipient, amount, initiative and",
        " counties.",
        dplyr::if_else(
          .data$amount_precision == "ROUNDED_TO_MILLIONS",
          paste0(" The release publishes this amount rounded to millions; it is",
                 " recorded as published and is not exact to the dollar."),
          ""
        ),
        dplyr::if_else(
          .data$award_sequence == "SECOND",
          paste0(" This is the second of two grants to this recipient under",
                 " this initiative; the release carries it in a continuation",
                 " paragraph that names no recipient of its own."),
          ""
        )
      ),
      flag_reason = dplyr::coalesce(
        .data$flag_reason,
        dplyr::if_else(.data$amount_precision == "ROUNDED_TO_MILLIONS",
                       "AMOUNT_ROUNDED_IN_SOURCE", NA_character_)
      )
    ) %>%
    dplyr::select(
      # -- the FL_year1_awardees schema, in FL's order --------------------
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      # -- appended, on the Georgia precedent ----------------------------
      "flow_type", "hospital_benefiting", "determination_basis",
      "source_archive_path", "recipient_names_source_url", "amount_basis",
      "amount_precision", "disbursement_status", "classification_rule",
      "activity_type_raw",
      # -- Alabama's own fields ------------------------------------------
      "initiative_raw", "award_sequence", "counties_served",
      "project_description"
    )
}


rhtp_al_records <- function(path = AL_CSV) {
  full <- here::here(path)
  if (!file.exists(full)) {
    stop("[AL] ", path, " does not exist. Run --build.", call. = FALSE)
  }
  readr::read_csv(full, show_col_types = FALSE, progress = FALSE)
}


# -- Reconciliation and assertions -------------------------------------------

rhtp_al_reconcile <- function(records = rhtp_al_build()) {
  summed <- sum(records$amount)
  exact <- records$amount_precision == "EXACT_AS_PUBLISHED"
  hosp <- records$distributed_to_hospital == "Yes"
  unclear <- records$distributed_to_hospital == "Unclear"

  tibble::tribble(
    ~measure,                                    ~value,
    "grants stated by the governor and CMS",     as.character(AL_STATED_GRANT_COUNT),
    "award actions extracted",                   as.character(nrow(records)),
    "distinct awardees",                         as.character(dplyr::n_distinct(records$awardee)),
    "initiatives funded (stated)",               as.character(AL_STATED_INITIATIVES),
    "initiatives extracted",                     as.character(dplyr::n_distinct(records$initiative_raw)),
    "second grants (continuation paragraphs)",   as.character(sum(records$award_sequence == "SECOND")),
    "amounts exact to the dollar",               as.character(sum(exact)),
    "amounts rounded to millions in the source", as.character(sum(!exact)),
    "total summed from the release's figures",   format(summed, big.mark = ",", nsmall = 2),
    "the release's own headline",                "more than $144,000,000",
    "gap attributable to the source's rounding", format(144000000 - summed, big.mark = ",", nsmall = 2),
    "CMS Year 1 award",                          format(AL_STATED_YEAR1_AWARD, big.mark = ",", nsmall = 2),
    "this round as a share of Year 1",           paste0(round(100 * summed / AL_STATED_YEAR1_AWARD, 2), "%"),
    "rows distributed_to_hospital = Yes",        as.character(sum(hosp)),
    "dollars distributed_to_hospital = Yes",     format(sum(records$amount[hosp]), big.mark = ",", nsmall = 2),
    "rows distributed_to_hospital = Unclear",    as.character(sum(unclear)),
    "dollars distributed_to_hospital = Unclear", format(sum(records$amount[unclear]), big.mark = ",", nsmall = 2)
  )
}


rhtp_al_assert <- function(records = rhtp_al_build()) {
  if (nrow(records) != AL_STATED_GRANT_COUNT) {
    stop("[AL] extracted ", nrow(records), " award actions; the governor and ",
         "CMS both state ", AL_STATED_GRANT_COUNT, ".", call. = FALSE)
  }
  if (dplyr::n_distinct(records$initiative_raw) != AL_STATED_INITIATIVES) {
    stop("[AL] found ", dplyr::n_distinct(records$initiative_raw),
         " initiatives; the release states ", AL_STATED_INITIATIVES, ".",
         call. = FALSE)
  }

  # Every continuation paragraph must have inherited a real recipient.
  seconds <- records %>% dplyr::filter(.data$award_sequence == "SECOND")
  if (any(is.na(seconds$awardee) | !nzchar(seconds$awardee))) {
    stop("[AL] a second-grant row carries no recipient.", call. = FALSE)
  }
  # And must sit against a recipient that also has a first grant in the same
  # initiative -- the check that the carry-forward attached to the right one.
  firsts <- records %>%
    dplyr::filter(.data$award_sequence == "FIRST") %>%
    dplyr::distinct(.data$awardee, .data$initiative_raw)
  orphan <- dplyr::anti_join(
    dplyr::distinct(seconds, .data$awardee, .data$initiative_raw),
    firsts, by = c("awardee", "initiative_raw"))
  if (nrow(orphan)) {
    stop("[AL] second grant(s) with no matching first grant under the same ",
         "initiative: ", paste(orphan$awardee, collapse = "; "), call. = FALSE)
  }

  if (any(is.na(records$amount)) || any(records$amount <= 0)) {
    stop("[AL] every award action must carry a positive amount.", call. = FALSE)
  }

  summed <- sum(records$amount)
  if (summed > AL_STATED_YEAR1_AWARD) {
    stop("[AL] the round exceeds the CMS Year 1 award. §6.2 ceiling.",
         call. = FALSE)
  }
  # The release's headline is "more than $144 million" and its own printed
  # figures sum to less, because 45 of them are rounded. That is expected and is
  # reported; what would NOT be expected is a gap large enough to mean a missed
  # award. One percent is roughly ten times the rounding this text can produce.
  if (abs(summed - 144000000) > 0.01 * 144000000) {
    stop("[AL] the extracted total ", format(summed, nsmall = 2),
         " is more than 1% from the stated $144M; that is too large to be the ",
         "source's rounding and suggests a missed or duplicated award.",
         call. = FALSE)
  }

  # No award may be attributed to an initiative heading (§6.1
  # PROGRAM_NAME_AS_AWARDEE).
  if (any(stringr::str_detect(records$awardee, "Initiative$"))) {
    stop("[AL] an initiative heading was captured as a recipient.",
         call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[AL] ", col, " outside §8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  wrong <- records %>%
    dplyr::filter(.data$distributed_to_hospital == "Yes",
                  !.data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                               "HOSPITAL_AFFILIATED_ENTITY"))
  if (nrow(wrong)) {
    stop("[AL] distributed_to_hospital = Yes on a non-hospital recipient: ",
         paste(unique(wrong$awardee), collapse = "; "), call. = FALSE)
  }

  if (any(is.na(records$determination_basis) |
          !nzchar(records$determination_basis))) {
    stop("[AL] determination_basis is mandatory free text (§7).", call. = FALSE)
  }

  invisible(TRUE)
}


# -- Write -------------------------------------------------------------------

rhtp_al_write <- function() {
  records <- rhtp_al_build()
  rhtp_al_assert(records)

  readr::write_csv(records, here::here(AL_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Awardees", records)
  add("Reconciliation", rhtp_al_reconcile(records))
  openxlsx::saveWorkbook(wb, here::here(AL_XLSX), overwrite = TRUE)

  message("  wrote ", AL_CSV, " and ", AL_XLSX, " (", nrow(records), " rows)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    rhtp_al_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_al_write()
    print(rhtp_al_reconcile(rhtp_al_records()), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_al_build()
    rhtp_al_assert(recs)
    print(rhtp_al_reconcile(recs), n = Inf)
    message("[AL] all assertions passed.")
  } else {
    message("Usage: Rscript R/03g_al_year1_awardees.R [--fetch|--validate|--build]")
  }
}

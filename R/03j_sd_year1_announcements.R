# 03j_sd_year1_announcements.R -----------------------------------------------
# South Dakota's two announced Year 1 rounds -> data/reference/sd_year1_awardees.csv
# (+ SD_year1_awardees.xlsx).
#
# WHAT THIS IS, AND WHAT IT IS NOT. South Dakota has announced two rounds of
# RHTP awards totalling $121.5M:
#
#   2026-07-23  KB0046839  "Rural Strong" project grants   28 grants   $31.5M
#   2026-08-19  KB0047023  Technology and data grants      82 grants   $90.0M
#
# Session 12 recorded these as the largest block of named recipients the project
# knew about and could not read, on the expectation that news.sd.gov held the
# rosters. news.sd.gov was allowlisted for this session and both releases were
# fetched. THEY NAME NOBODY. Not one recipient appears in either document --
# no list, no table, no attachment, no linked roster. What each release
# publishes is a count, a total, and a description of the funded themes.
#
# So this file does NOT contain 110 named recipients, because South Dakota has
# not published them. It contains the two rounds as two aggregate award actions,
# each `recipient_confirmed = No` and `flag_reason = RECIPIENT_NAMES_NOT_CAPTURED`
# -- the coding Georgia's AHEAD cohorts carried for a session before
# greathealth.georgia.gov was opened and the 87 names were parsed out of it.
# The class and the count are confirmed; the names are not captured; nothing is
# imputed (spec 0.3, 0.4).
#
# WHERE THE NAMES WOULD BE, ALL CHECKED THIS SESSION AND ALL NEGATIVE:
#
#   news.sd.gov       reachable  both releases fetched -- neither names anyone
#   doh.sd.gov        reachable  press index, RHT project page, RHT resources &
#                                FAQs, press search on "awarded" -- no roster
#   open.sd.gov       reachable  re-probed via R/03i --probe: the RHT series is
#                                still 13 administrative contracts / $5,618,367,
#                                "Rural Strong" still returns ZERO rows. The
#                                July release says contracts post there "once
#                                finalized"; five weeks on, they have not.
#   ruralhealthtransformation.sd.gov   REFUSED at CONNECT. Both releases name
#                                this host as the resource site. It is the
#                                remaining candidate and is worth asking for.
#
# THE AMOUNT COLUMN IS DELIBERATELY EMPTY, AND THAT IS GEORGIA'S RULE (6.2).
# The published figure is a ROUND total, not a recipient's award. Putting
# $31,500,000 in `amount` would make one row read as one organisation's grant
# the moment it is separated from this file, and would make a naive sum of
# `amount` look authoritative. The round totals live in `round_amount`, the
# per-recipient amount is `NOT_PUBLISHED`, and rhtp_sd_year1_reconcile() sums
# distinct rounds. This is the same trap R/03d holds open for Georgia.
#
# THE TRIPWIRE IS THE POINT OF THIS FILE. rhtp_sd_year1_parse() hard-fails if
# either release ever gains a recipient roster -- a list, a table, or a run of
# organisation-shaped names. A negative finding that nobody re-checks decays
# into a stale assumption; this one re-checks itself. Re-run --fetch --force
# and the script will REFUSE to archive the moment South Dakota publishes the
# names, which is exactly when this file's framing becomes wrong.
#
# ARCHIVING. Only the <article id="article"> element is archived, on the 7.1 /
# CMS precedent: the surrounding ServiceNow chrome carries a per-session CSRF
# token (g_ck) and a guest user id, which are session state and not ours to
# commit. The manifest carries BOTH digests -- the article's and the full page
# as served -- so provenance still closes, and the writer asserts the archived
# bytes are free of that token shape before writing. Digests are taken over the
# exact bytes written (writeBin, never writeLines, which appends a newline the
# manifest would then not verify against -- the session 12 correction).
#
# Conventions (CLAUDE.md 3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). --fetch is the only mode that touches the
# network.
#
# CLI:
#   Rscript R/03j_sd_year1_announcements.R --fetch     # archive both + SHA-256
#   Rscript R/03j_sd_year1_announcements.R --validate  # parse + assert, no writes
#   Rscript R/03j_sd_year1_announcements.R --build     # assert, write CSV + xlsx

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

SD_Y1_STATE <- "SD"

SD_Y1_EVIDENCE_DIR <- "data/evidence/SD/announcements"
SD_Y1_MANIFEST     <- "sd_year1_announcements.manifest.txt"
SD_Y1_CSV          <- "data/reference/sd_year1_awardees.csv"
SD_Y1_XLSX         <- "SD_year1_awardees.xlsx"

# news.sd.gov is a ServiceNow portal. The page a reader lands on
# (news?id=news_kb_article_view&sys_id=...) is an Angular shell that renders the
# body client-side, so it cannot be archived as text. kb_view.do is the same
# article rendered server-side, needs no cookie or token, and is the permalink
# form the article's own "Copy Permalink" control emits. So: cite the portal
# url (what DOH links to, and what a reviewer will open), fetch the kb_view url.
SD_Y1_PORTAL_URL  <- "https://news.sd.gov/news?id=news_kb_article_view&sys_id="
SD_Y1_KBVIEW_URL  <- "https://news.sd.gov/kb_view.do?sysparm_article="

# CMS's own Year 1 award to South Dakota, as stated in DOH's press-release
# footnote. Not summed with anything (0.2) -- it is the Tier 1 denominator.
SD_Y1_CMS_AWARD <- 189477607.26

#' The two announced rounds, as the state itself states them
#'
#' Every figure here is asserted against the archived release text by
#' rhtp_sd_year1_parse(), so this table cannot drift away from the documents.
SD_Y1_ROUNDS <- tibble::tribble(
  ~round_id, ~kb_number,  ~sys_id,                            ~announced_date, ~grant_count, ~round_amount, ~recipient_class,                     ~round_name,
  "RS",      "KB0046839", "0a2599cd47d6cf10da219464336d439a", "2026-07-23",    28L,          31500000,      "20 health systems",                  "Rural Strong project grants",
  "TD",      "KB0047023", "f299421547b20b10fc1303dc426d433a", "2026-08-19",    82L,          90000000,      "82 rural healthcare organizations",  "Technology and data grants"
)

SD_Y1_TOTAL_ANNOUNCED <- sum(SD_Y1_ROUNDS$round_amount)   # $121,500,000
SD_Y1_TOTAL_GRANTS    <- sum(SD_Y1_ROUNDS$grant_count)    # 110

# Phrases each release must still contain. If a release is edited so that its
# own stated count or total no longer matches SD_Y1_ROUNDS, the parse fails
# rather than publishing a figure the document stopped supporting.
SD_Y1_REQUIRED <- list(
  KB0046839 = c("28 Rural Strong grants", "\\$31\\.5 million", "20 health systems"),
  KB0047023 = c("82 grants", "\\$90 million")
)

# The roster tripwire. A recipient list, if one is ever added, will show up as
# a table, as a long run of list items, or as a run of organisation-shaped
# names. These thresholds sit far above what the current prose contains (both
# bodies have zero tables and fewer than five list items) and far below what
# even a short 28-row roster would produce.
SD_Y1_MAX_TABLES     <- 0L
SD_Y1_MAX_LIST_ITEMS <- 8L
SD_Y1_MAX_ORG_NAMES  <- 6L

# Organisation-shaped name: capitalised words ending in a corporate or provider
# suffix. Deliberately broad -- a false alarm costs one look at the page, a
# missed roster costs the finding this whole file rests on.
SD_Y1_ORG_PATTERN <- paste0(
  "\\b(?:[A-Z][A-Za-z&'.-]*\\s+){1,5}",
  "(?:Hospital|Hospitals|Health|Healthcare|Clinic|Clinics|Medical\\s+Center|",
  "Health\\s+System|Health\\s+Services|Regional\\s+Health|Care\\s+Center|",
  "LLC|L\\.L\\.C\\.|Inc\\.?|Incorporated|Cooperative|Corporation|Foundation|",
  "Association|District|Center|Centre)\\b"
)

# Names that appear in the prose of these releases for reasons other than being
# an awardee -- officials, agencies, the programme itself. Excluded before the
# org-name count so the tripwire measures rosters, not boilerplate.
SD_Y1_ORG_ALLOWED <- c(
  "Rural Health Transformation", "Department of Health", "Department of Social",
  "Centers for Medicare", "Medicaid Services", "Regional Innovation",
  "Human Services", "South Dakota Association", "Great Plains Tribal",
  "Rural Strong", "Working Families"
)


# -- Fetch -------------------------------------------------------------------

#' Archive both releases, article element only, with a two-digest manifest
rhtp_sd_year1_fetch <- function(force = FALSE) {
  cfg <- rhtp_config()
  dir <- here::here(SD_Y1_EVIDENCE_DIR)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  sha <- function(x) digest::digest(x, algo = "sha256", serialize = FALSE)

  fetched <- purrr::pmap(SD_Y1_ROUNDS, function(kb_number, sys_id, ...) {
    file <- paste0(kb_number, ".html")
    path <- file.path(dir, file)

    if (file.exists(path) && !force) {
      message("  already archived: ", file, " -- pass --force to re-fetch.")
      return(list(kb_number = kb_number, path = path, skipped = TRUE))
    }

    url <- paste0(SD_Y1_KBVIEW_URL, kb_number)
    resp <- httr2::request(url) %>%
      httr2::req_user_agent(cfg$api$user_agent) %>%
      httr2::req_timeout(cfg$api$timeout_seconds) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
      httr2::req_perform()

    status <- httr2::resp_status(resp)
    if (status != 200) {
      stop("[SD-Y1] ", url, " returned HTTP ", status,
           "; refusing to archive a non-200 body.", call. = FALSE)
    }
    page <- httr2::resp_body_string(resp)

    article <- rhtp_sd_year1_article_html(page, kb_number)

    # Parse BEFORE writing (the R/00 posture): an archive that does not parse
    # is worse than no archive, and the roster tripwire must fire on fetch.
    rhtp_sd_year1_parse(article, kb_number)

    # The chrome carries a per-session CSRF token; the article element must not.
    if (stringr::str_detect(article, "g_ck")) {
      stop("[SD-Y1] the extracted article element for ", kb_number,
           " contains a 'g_ck' token. Refusing to commit session state.",
           call. = FALSE)
    }

    writeBin(charToRaw(article), path)

    list(kb_number = kb_number, sys_id = sys_id, url = url, path = path,
         file = file, article = article, page = page, status = status,
         skipped = FALSE)
  })

  written <- purrr::keep(fetched, function(d) isFALSE(d$skipped))
  if (!length(written)) {
    message("  nothing re-fetched; manifest left as is.")
    return(invisible(dir))
  }

  writeLines(c(
    paste0(
      "RHTP tracker archive (spec 0.4 / 0.5): South Dakota's two announced\n",
      "Rural Health Transformation award rounds.\n\n",
      "fetched_utc     : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
      "state           : SD\n",
      "host            : news.sd.gov (ServiceNow knowledge base)\n",
      "source_doc_type : GOVERNOR_PRESS_RELEASE\n",
      "cms_year1_award : $189,477,607.26 (stated in DOH's own footnote)\n\n",
      "WHAT THESE DOCUMENTS DO NOT CONTAIN\n\n",
      "NEITHER RELEASE NAMES A SINGLE RECIPIENT. Between them they announce\n",
      SD_Y1_TOTAL_GRANTS, " grants worth $", sd_y1_money(SD_Y1_TOTAL_ANNOUNCED),
      " and publish counts, totals and funded themes only --\n",
      "no list, no table, no attachment, no linked roster. This archive is the\n",
      "primary-source record of that negative, and of the counts and totals\n",
      "themselves, which ARE stated and ARE quotable.\n\n",
      "Routes checked this session and all negative: doh.sd.gov (press index,\n",
      "RHT project page, RHT resources & FAQs, press search on 'awarded');\n",
      "open.sd.gov (the RHT series is still 13 administrative contracts and\n",
      "$5,618,367, 'Rural Strong' still returns zero rows). The remaining\n",
      "candidate is ruralhealthtransformation.sd.gov, named as the resource\n",
      "site in both releases and REFUSED at CONNECT from this session.\n\n",
      "ONLY THE <article id=\"article\"> ELEMENT IS ARCHIVED, on the 7.1 / CMS\n",
      "precedent: the ServiceNow chrome carries a per-session CSRF token (g_ck)\n",
      "and a guest user id, which are session state and not ours to commit. Both\n",
      "digests are recorded below, so provenance still closes.\n\n",
      "Digests are over the EXACT BYTES WRITTEN (writeBin). Re-hash any file\n",
      "here and the ARTICLE digest will match.\n\n",
      "THE FULL-PAGE DIGEST IS NOT REPRODUCIBLE, AND THAT IS THE POINT. Two\n",
      "fetches minutes apart gave identical article digests and DIFFERENT\n",
      "full-page digests, because the ServiceNow chrome embeds a fresh CSRF\n",
      "token on every request. It is recorded as the digest of the response as\n",
      "served on the fetch date -- evidence of what was received, not a value a\n",
      "later reader can reproduce. The article digest is the one that verifies.\n\n",
      "RELEASES\n"
    ),
    purrr::map_chr(written, function(d) {
      r <- SD_Y1_ROUNDS[SD_Y1_ROUNDS$kb_number == d$kb_number, ]
      paste0(
        "\n  file            : ", d$file, "\n",
        "  kb_number       : ", d$kb_number, "\n",
        "  title           : ", r$round_name, "\n",
        "  announced       : ", r$announced_date, "\n",
        "  states          : ", r$grant_count, " grants, $",
        sd_y1_money(r$round_amount), ", ", r$recipient_class, "\n",
        "  named recipients: 0\n",
        "  cite as         : ", SD_Y1_PORTAL_URL, r$sys_id, "\n",
        "  fetched from    : ", d$url, "\n",
        "  http_status     : ", d$status, "\n",
        "  article bytes   : ", length(charToRaw(d$article)), "\n",
        "  article sha256  : ", sha(d$article), "\n",
        "  full-page bytes : ", nchar(d$page, type = "bytes"), "\n",
        "  full-page sha256: ", sha(d$page)
      )
    })
  ), file.path(dir, SD_Y1_MANIFEST))

  message("  archived ", length(written), " South Dakota release(s) to ",
          SD_Y1_EVIDENCE_DIR, " -- ", SD_Y1_TOTAL_GRANTS, " grants, $",
          sd_y1_money(SD_Y1_TOTAL_ANNOUNCED),
          ", and ZERO named recipients.")
  invisible(dir)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Format dollars without scientific notation (format() gives "9e+07" otherwise)
sd_y1_money <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)


# -- Parse -------------------------------------------------------------------

#' Pull the article element out of a served ServiceNow page
rhtp_sd_year1_article_html <- function(page, kb_number) {
  doc <- rvest::read_html(page)
  node <- rvest::html_element(doc, "article#article")
  if (inherits(node, "xml_missing")) {
    stop("[SD-Y1] no <article id=\"article\"> in the page served for ",
         kb_number, ". The portal's markup changed; refusing to guess which ",
         "element is the release.", call. = FALSE)
  }
  as.character(node)
}

#' Parse and assert one release
#'
#' Returns the release's plain text. Hard-fails on a stated figure that no
#' longer matches SD_Y1_ROUNDS, and on any sign that a recipient roster has
#' been added.
rhtp_sd_year1_parse <- function(article_html, kb_number) {
  doc <- rvest::read_html(article_html)

  text <- doc %>%
    rvest::html_text2() %>%
    stringr::str_replace_all(" ", " ") %>%
    stringr::str_replace_all("[‘’]", "'") %>%
    stringr::str_replace_all("[“”]", "\"") %>%
    stringr::str_squish()

  required <- SD_Y1_REQUIRED[[kb_number]]
  if (is.null(required)) {
    stop("[SD-Y1] no required phrases registered for ", kb_number, ".",
         call. = FALSE)
  }
  missing <- required[!purrr::map_lgl(required, function(p) {
    stringr::str_detect(text, stringr::regex(p, ignore_case = TRUE))
  })]
  if (length(missing)) {
    stop("[SD-Y1] ", kb_number, " no longer states: ",
         paste(missing, collapse = " | "),
         ". The release was edited; SD_Y1_ROUNDS must be re-read against it ",
         "before any figure from it is published.", call. = FALSE)
  }

  # -- the roster tripwire ---------------------------------------------------
  n_tables <- length(rvest::html_elements(doc, "table"))
  if (n_tables > SD_Y1_MAX_TABLES) {
    stop("[SD-Y1] ", kb_number, " now contains ", n_tables, " table(s). ",
         "It contained none when this was written, and a table here is most ",
         "likely the recipient roster. Read it and extract the names -- this ",
         "file's 'South Dakota names nobody' framing is now wrong.",
         call. = FALSE)
  }

  n_items <- length(rvest::html_elements(doc, "li"))
  if (n_items > SD_Y1_MAX_LIST_ITEMS) {
    stop("[SD-Y1] ", kb_number, " now contains ", n_items, " list items ",
         "(was at most ", SD_Y1_MAX_LIST_ITEMS, "). That is the shape a ",
         "recipient list takes. Read it before re-running --build.",
         call. = FALSE)
  }

  # Match WITHIN sentence fragments, never across them. A name run like
  # "Avera St. Mary's Hospital. Sanford Health" is two organisations, and a
  # pattern allowed to span the full stop swallows them into one match -- which
  # UNDERCOUNTS a roster, the one direction this check must never fail in.
  fragments <- stringr::str_split(text, "[.;:!?]\\s+|\\n+")[[1]]
  orgs <- unlist(stringr::str_extract_all(fragments, SD_Y1_ORG_PATTERN))
  orgs <- orgs[!purrr::map_lgl(orgs, function(o) {
    any(stringr::str_detect(o, stringr::fixed(SD_Y1_ORG_ALLOWED)))
  })]
  orgs <- unique(stringr::str_squish(orgs))
  if (length(orgs) > SD_Y1_MAX_ORG_NAMES) {
    stop("[SD-Y1] ", kb_number, " now names ", length(orgs),
         " organisation-shaped entities (was at most ", SD_Y1_MAX_ORG_NAMES,
         "): ", paste(utils::head(orgs, 12), collapse = "; "),
         ". South Dakota may have published the roster. Read it before ",
         "re-running --build.", call. = FALSE)
  }

  text
}

#' Read the committed archives and parse both releases
rhtp_sd_year1_releases <- function() {
  dir <- here::here(SD_Y1_EVIDENCE_DIR)
  purrr::pmap_dfr(SD_Y1_ROUNDS, function(kb_number, ...) {
    path <- file.path(dir, paste0(kb_number, ".html"))
    if (!file.exists(path)) {
      stop("[SD-Y1] ", path, " is not on disk. Run --fetch first.",
           call. = FALSE)
    }
    article <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                     collapse = "\n")
    tibble::tibble(
      kb_number = kb_number,
      text      = rhtp_sd_year1_parse(article, kb_number),
      path      = file.path(SD_Y1_EVIDENCE_DIR, basename(path))
    )
  })
}


# -- Build -------------------------------------------------------------------

SD_Y1_NOTE <- c(
  RS = paste0(
    "Governor Rhoden announced 28 'Rural Strong' grants totalling $31.5M ",
    "supporting projects 'across 20 health systems'. THE RELEASE NAMES NO ",
    "RECIPIENT. It also states the contracts will be published on OpenSD ",
    "'once finalized'; five weeks later they are not there (R/03i --probe: ",
    "the RHT series is 13 administrative contracts, 'Rural Strong' returns ",
    "zero rows)."
  ),
  TD = paste0(
    "Governor Rhoden announced 82 technology and data grants totalling $90M ",
    "to 'rural healthcare organizations', from 144 applications requesting ",
    "$336M. THE RELEASE NAMES NO RECIPIENT. The described recipient set is ",
    "explicitly mixed -- healthcare providers, Regional Innovation Centers, ",
    "aging-services organizations, academic and technology partners -- so ",
    "even the class cannot be read as hospitals."
  )
)

SD_Y1_BASIS <- paste0(
  "South Dakota announced this round but has published no recipient-level ",
  "list. recipient_confirmed = No and flag_reason = RECIPIENT_NAMES_NOT_CAPTURED: ",
  "the count and the round total are confirmed from the state's own release, ",
  "the names are not captured, and NOTHING IS IMPUTED (spec 0.3, 0.4). ",
  "distributed_to_hospital = Unclear because the release describes a mixed ",
  "recipient set and never states that a hospital received money; coding Yes ",
  "off 'health systems' would be the eligibility-is-not-receipt error. ",
  "`amount` is deliberately empty -- the published figure is a ROUND total, ",
  "not one recipient's award, and it lives in `round_amount` so no sum over ",
  "`amount` can read as a per-recipient total (6.2, the Georgia rule). ",
  "This row is NOT part of South Dakota's 13 administrative RHT contracts ",
  "($5,618,367, data/reference/sd_rht_contracts.csv); the two must never be ",
  "added together without reading both files' headers."
)

#' Build the two aggregate round rows, in Florida's leading-19 schema
rhtp_sd_year1_build <- function() {
  releases <- rhtp_sd_year1_releases()

  SD_Y1_ROUNDS %>%
    dplyr::left_join(releases, by = "kb_number") %>%
    dplyr::mutate(
      state        = SD_Y1_STATE,
      row_no       = dplyr::row_number(),
      awardee      = paste0(
        .data$grant_count, " grants (", .data$round_name, ") to ",
        .data$recipient_class, " - recipient names not published"
      ),
      amount                   = NA_real_,
      recipient_type           = "NOT_YET_NAMED",
      distributed_to_hospital  = "Unclear",
      note                     = unname(SD_Y1_NOTE[.data$round_id]),
      recipient_confirmed      = "No",
      amount_confirmed         = "Yes",
      fiscal_year              = "FY2026 (Year 1)",
      source_document_title    = paste0(
        "Gov. Rhoden Awards Rural Health Transformation ",
        dplyr::if_else(.data$round_id == "RS", "Project", "Technology and Data"),
        " Grants (", .data$kb_number, ")"
      ),
      state_source_url         = paste0(SD_Y1_PORTAL_URL, .data$sys_id),
      validation_source_type   = "GOVERNOR_PRESS_RELEASE",
      extraction_method        = "MODEL_ASSISTED",
      validator                = "AI-assisted - CONFIRM",
      ccn                      = NA_character_,
      aha_id                   = NA_character_,
      rural_designation        = NA_character_,
      reviewer                 = NA_character_,
      # -- state-local columns, after the leading 19 -------------------------
      recipient_type_source    = "NOT_YET_NAMED",
      determination_confidence = "LOW",
      flag_reason              = "RECIPIENT_NAMES_NOT_CAPTURED",
      flow_type                = "PASS_THROUGH_UNRESOLVED",
      hospital_benefiting      = "Yes",
      determination_basis      = SD_Y1_BASIS,
      source_archive_path      = .data$path,
      recipient_names_source_url = NA_character_,
      amount_basis             = "NOT_PUBLISHED",
      amount_precision         = "NOT_PUBLISHED",
      disbursement_status      = dplyr::if_else(
        .data$round_id == "RS", "CONTRACTS_PENDING", "AWARDED"
      ),
      classification_rule      = "AGGREGATE_ROUND",
      kb_permalink             = paste0(SD_Y1_KBVIEW_URL, .data$kb_number)
    ) %>%
    dplyr::select(
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      "flow_type", "hospital_benefiting", "determination_basis",
      "source_archive_path", "recipient_names_source_url", "amount_basis",
      "amount_precision", "disbursement_status", "classification_rule",
      "round_id", "round_name", "kb_number", "announced_date", "grant_count",
      "round_amount", "recipient_class", "kb_permalink"
    )
}


# -- Assert ------------------------------------------------------------------

rhtp_sd_year1_assert <- function(records) {
  if (nrow(records) != nrow(SD_Y1_ROUNDS)) {
    stop("[SD-Y1] expected ", nrow(SD_Y1_ROUNDS), " round rows, got ",
         nrow(records), ".", call. = FALSE)
  }

  if (sum(records$round_amount) != SD_Y1_TOTAL_ANNOUNCED) {
    stop("[SD-Y1] round totals sum to ", sum(records$round_amount),
         ", expected ", SD_Y1_TOTAL_ANNOUNCED, ".", call. = FALSE)
  }
  if (sum(records$grant_count) != SD_Y1_TOTAL_GRANTS) {
    stop("[SD-Y1] grant counts sum to ", sum(records$grant_count),
         ", expected ", SD_Y1_TOTAL_GRANTS, ".", call. = FALSE)
  }

  # The announced rounds cannot exceed South Dakota's own CMS Year 1 award.
  if (SD_Y1_TOTAL_ANNOUNCED > SD_Y1_CMS_AWARD) {
    stop("[SD-Y1] the announced rounds ($", SD_Y1_TOTAL_ANNOUNCED,
         ") exceed the CMS Year 1 award ($", SD_Y1_CMS_AWARD, ").",
         call. = FALSE)
  }

  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    bad <- setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col))
    if (length(bad)) {
      stop("[SD-Y1] ", col, " outside spec 8: ", paste(bad, collapse = ", "),
           call. = FALSE)
    }
  }

  # Nothing here is a confirmed recipient, and nothing here is a hospital
  # dollar. Both are the whole point of the file, so both are asserted.
  if (any(records$recipient_confirmed != "No")) {
    stop("[SD-Y1] a round row claims recipient_confirmed = Yes. Neither ",
         "release names anyone.", call. = FALSE)
  }
  if (any(records$distributed_to_hospital == "Yes")) {
    stop("[SD-Y1] a round row claims distributed_to_hospital = Yes off a ",
         "release that names no recipient. That is spec 0.3 exactly.",
         call. = FALSE)
  }
  if (!all(is.na(records$amount))) {
    stop("[SD-Y1] `amount` must stay empty: the published figure is a round ",
         "total, not a recipient's award (6.2). It belongs in `round_amount`.",
         call. = FALSE)
  }

  # Every row must carry its own explanation, so the figure cannot be quoted
  # once it is separated from this file.
  if (!all(stringr::str_detect(records$determination_basis, "NOTHING IS IMPUTED"))) {
    stop("[SD-Y1] every row's determination_basis must state that nothing is ",
         "imputed.", call. = FALSE)
  }
  if (!all(stringr::str_detect(records$note, "NAMES NO RECIPIENT"))) {
    stop("[SD-Y1] every row's note must state that the release names no ",
         "recipient.", call. = FALSE)
  }

  # The archives must exist and must still parse (which re-fires the tripwire).
  for (p in records$source_archive_path) {
    if (!file.exists(here::here(p))) {
      stop("[SD-Y1] archived source missing: ", p, call. = FALSE)
    }
  }

  invisible(TRUE)
}


# -- Reconcile ---------------------------------------------------------------

rhtp_sd_year1_reconcile <- function(records = rhtp_sd_year1_build()) {
  contracts_csv <- here::here("data/reference/sd_rht_contracts.csv")
  admin <- if (file.exists(contracts_csv)) {
    sum(readr::read_csv(contracts_csv, show_col_types = FALSE,
                        progress = FALSE)$amount, na.rm = TRUE)
  } else {
    NA_real_
  }

  tibble::tribble(
    ~measure,                                          ~grants,               ~amount,
    "Rural Strong project grants (2026-07-23)",        28L,                   31500000,
    "Technology and data grants (2026-08-19)",         82L,                   90000000,
    "Announced, recipients NOT published",             SD_Y1_TOTAL_GRANTS,    SD_Y1_TOTAL_ANNOUNCED,
    "Named recipients captured from these releases",   0L,                    0,
    "Administrative contracts on open.sd.gov (R/03i)", 13L,                   admin,
    "CMS Year 1 award to South Dakota",                NA_integer_,           SD_Y1_CMS_AWARD,
    "Unaccounted against the CMS award",               NA_integer_,           SD_Y1_CMS_AWARD - SD_Y1_TOTAL_ANNOUNCED - admin
  ) %>%
    dplyr::mutate(
      share_of_cms_award = round(.data$amount / SD_Y1_CMS_AWARD * 100, 2)
    )
}


# -- Write -------------------------------------------------------------------

SD_Y1_README <- tibble::tribble(
  ~field, ~value,
  "What this file is",
  paste0("South Dakota's two announced RHTP Year 1 rounds: ",
         SD_Y1_TOTAL_GRANTS, " grants, $",
         sd_y1_money(SD_Y1_TOTAL_ANNOUNCED), "."),
  "What it is NOT",
  paste0("It is NOT a list of ", SD_Y1_TOTAL_GRANTS, " recipients. NEITHER ",
         "RELEASE NAMES ANYONE. South Dakota has published no recipient-level ",
         "list for either round on any reachable host."),
  "Why `amount` is empty",
  paste0("The published figure is a ROUND total, not a recipient's award. It ",
         "is in `round_amount`. Summing `amount` gives 0, by design (6.2)."),
  "Hospital dollars confirmed",
  "$0. No recipient is named, so no dollar can be traced to a hospital.",
  "Where the names would be",
  paste0("ruralhealthtransformation.sd.gov (named as the resource site in ",
         "both releases, refused at CONNECT), or open.sd.gov once contracts ",
         "are finalised (re-probed this session: still not there)."),
  "Do not add this to",
  paste0("data/reference/sd_rht_contracts.csv ($5,618,367 of ADMINISTRATIVE ",
         "spend, 13 contracts). Different documents, different tiers of ",
         "certainty; read both headers before combining."),
  "Rebuild",
  "Rscript R/03j_sd_year1_announcements.R --build"
)

rhtp_sd_year1_write <- function() {
  records <- rhtp_sd_year1_build()
  rhtp_sd_year1_assert(records)

  readr::write_csv(records, here::here(SD_Y1_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  add <- function(sheet, data) {
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, data)
    openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  }
  add("Read me first", SD_Y1_README)
  add("Announced rounds", records)
  add("Reconciliation", rhtp_sd_year1_reconcile(records))
  openxlsx::saveWorkbook(wb, here::here(SD_Y1_XLSX), overwrite = TRUE)

  message("  wrote ", SD_Y1_CSV, " and ", SD_Y1_XLSX, " (", nrow(records),
          " aggregate round rows, 0 named recipients)")
  invisible(records)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    rhtp_sd_year1_fetch(force = "--force" %in% args)
  } else if ("--build" %in% args) {
    rhtp_sd_year1_write()
    print(rhtp_sd_year1_reconcile(), n = Inf)
  } else if ("--validate" %in% args) {
    recs <- rhtp_sd_year1_build()
    rhtp_sd_year1_assert(recs)
    print(rhtp_sd_year1_reconcile(recs), n = Inf)
    message("[SD-Y1] all assertions passed. ", nrow(recs),
            " announced rounds, 0 named recipients.")
  } else {
    message("Usage: Rscript R/03j_sd_year1_announcements.R [--fetch|--validate|--build]")
  }
}

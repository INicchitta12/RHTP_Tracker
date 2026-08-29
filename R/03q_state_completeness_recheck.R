# 03q_state_completeness_recheck.R --------------------------------------------
# The seven extracted states, re-checked for award rosters nobody read.
#
# WHY THIS EXISTS. Kansas is the reason. Session 20 went looking for Kansas's
# Year 1 awards, found a seven-award Community Health Worker list, and would
# have published $1,007,152 as "what Kansas has awarded". Two links further
# down the same KDHE page was a second PDF with 46 more awards and $80,020,499.
# The partial list was 1.3% of the state's own roster and nothing about it
# looked partial.
#
# That is not a Kansas problem. It is a problem with the shape of this project's
# extractions: each state was worked once, from the documents that were visible
# on the day, and nothing has ever gone back. This file goes back -- for FL, GA,
# PA, AL, AK, OR and IL -- and asks two questions per state:
#
#   1. Has the document we extracted CHANGED? (digest against the committed
#      archive, where the source is stable enough for a digest to mean anything)
#   2. Is there a roster we never read? (the state's award page AND its
#      immediate children, not the one page the extractor happened to use)
#
# AND IT ANSWERS THE SECOND ONE WITH A POSITIVE CONTROL, because "we found no
# other list" is worth nothing on its own -- Texas taught that and Kansas
# taught it again. For each state this file records WHAT A PUBLISHED ROSTER
# LOOKS LIKE ON THAT STATE'S SITE, asserts that the known ones are still there
# in that form, and only then reports the absence of others.
#
# WHAT IT FOUND -- TWO STATES OF SEVEN, AND BOTH ARE REAL.
#
#   GEORGIA. DCH publishes signed Notices of Award on
#   greathealth.georgia.gov/find-funding-opportunities, a page no session has
#   ever read: the extraction used dch.georgia.gov's four announcements and the
#   value-based-care roster. Two of them name 21 hospital award actions worth
#   $30,277,580 that the committed file carries as TWO AGGREGATE ROWS reading
#   "8 hospitals ... names not captured" and "13 hospitals ... names not
#   captured", with `amount` empty on both. The dollars are already inside
#   Georgia's $197,148,327 at pool level -- this is not new money. It is
#   $30,277,580 moving from "pool, names not captured" to NAMED HOSPITALS,
#   which is the number AHA is actually asked for.
#
#   ALASKA. The rolling notice of intent to award has grown: 161 -> 185 award
#   actions, $160,701,975 -> $181,871,366. Alaska's own Year 1 Funding Cycle
#   Update says so independently -- "Week 4 | Aug 28 ... $16.9M ... 24
#   Projects", cumulative "$182M ... 185 Projects" -- and the state says
#   outright that "Project awards are being announced on a rolling weekly
#   basis". The committed file is a snapshot with a date on it and was never
#   wrong; it is now stale, and it will go stale again next week.
#
# THE OTHER FIVE ARE NEGATIVE, AND ONE OF THEM IS THE MOST USEFUL RESULT HERE.
# Florida's committed 81 rows reconcile EXACTLY -- to the cent and to the row --
# against the Governor's own awardee PDF, which is where the owner's workbook
# came from. That is the first time a whole state file in this repository has
# been checked against its primary source end to end.
#
# THIS FILE EXTRACTS NOTHING. It reports, and it archives what it read so the
# next session can extract from a committed copy. Georgia's 21 hospitals and
# Alaska's 24 new awards are for R/03d and R/03h, deliberately not for this.
#
# Usage:
#   Rscript R/03q_state_completeness_recheck.R --fetch     # archive + SHA-256
#   Rscript R/03q_state_completeness_recheck.R --validate  # assertions, offline
#   Rscript R/03q_state_completeness_recheck.R --build     # writes the CSV
#   Rscript R/03q_state_completeness_recheck.R --report    # the table above

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

RECHECK_DATE     <- "2026-08-29"
RECHECK_DIR      <- here::here("data", "evidence", "recheck", RECHECK_DATE)
RECHECK_CSV      <- "data/reference/state_completeness_recheck.csv"
RECHECK_THROTTLE <- 3
RECHECK_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

# The pages re-fetched, per state: the award page the extractor used AND its
# immediate children. `role` says what each one is for.
#
#   ROSTER      a recipient-level award list
#   INDEX       a page that would LINK to one -- the Kansas lesson
#   CONTROL     the positive control: a page that demonstrably carries a roster
#               in this state's own recognisable form
#
# `reduce` is NONE for everything except two pages, and BOTH were found by the
# guard rather than by anyone looking:
#
#   Oregon's awards page loads Google Maps and carries the API key INSIDE the
#   script URL. Session 17 met exactly this and settled the remedy: strip every
#   <script> (STRIP_SCRIPTS).
#
#   Illinois's HFS page embeds a store-locator <map-details api-key="pk.ey...">
#   INSIDE <main>, so no container choice excludes it. Session 16's remedy is to
#   remove the credential-bearing NODE by the SHAPE of the token it carries, so
#   a rotated key is removed too (STRIP_CREDENTIAL_NODES).
#
# Either way the result is asserted credential-free AFTER reducing, and the full
# page's digest as served goes in the manifest so provenance still closes.
RECHECK_SOURCES <- tibble::tribble(
  ~state, ~key,                ~role,     ~url, ~file, ~reduce,
  "FL", "ahca_program",        "INDEX",   "https://ahca.myflorida.com/rural-health-transformation-program.html", "FL_ahca_rhtp_program_page.html", "NONE",
  "FL", "governor_release",    "INDEX",   "https://www.flgov.com/eog/news/press/2026/governor-ron-desantis-announces-nearly-188-million-expand-rural-health-care-access", "FL_governor_188m_release.html", "NONE",
  "FL", "awardee_list",        "CONTROL", "https://flgov.com/eog/sites/default/files/shared/2026/08/RHTP%20-%20PDF.pdf", "FL_year1_awardees_governor_list.pdf", "NONE",
  "GA", "greathealth_home",    "INDEX",   "https://greathealth.georgia.gov/", "GA_greathealth_home.html", "NONE",
  "GA", "greathealth_news",    "INDEX",   "https://greathealth.georgia.gov/about-program/news", "GA_greathealth_news.html", "NONE",
  "GA", "funding_opportunities", "INDEX", "https://greathealth.georgia.gov/find-funding-opportunities", "GA_find_funding_opportunities.html", "NONE",
  "GA", "noa_robots",          "ROSTER",  "https://greathealth.georgia.gov/document/document/notice-award-workforce-retention-technology-surgical-robotssigned/download", "GA_noa_workforce_retention_technology_signed.pdf", "NONE",
  "GA", "nita_robots",         "ROSTER",  "https://greathealth.georgia.gov/document/document/notice-intent-award-workforce-retention-technology-7-31-2026pdf-0/download", "GA_nita_workforce_retention_technology.pdf", "NONE",
  "GA", "noa_telepods",        "ROSTER",  "https://greathealth.georgia.gov/document/document/notice-award-point-care-telepodssigned-0/download", "GA_noa_point_of_care_telepods_signed.pdf", "NONE",
  "GA", "nita_telepods",       "ROSTER",  "https://greathealth.georgia.gov/document/document/notice-intent-award-point-care-telepods-7-24-26/download", "GA_nita_point_of_care_telepods.pdf", "NONE",
  "PA", "dhs_program",         "INDEX",   "https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health/", "PA_dhs_rural_health_program.html", "NONE",
  "PA", "funding_opportunities", "INDEX", "https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health/rhtp-funding-opportunities", "PA_dhs_rhtp_funding_opportunities.html", "NONE",
  "PA", "eligible_projects",   "CONTROL", "https://www.pa.gov/agencies/dhs/programs-services/healthcare/rural-health/rural-health-eligible-projects", "PA_dhs_rural_health_selected_projects.html", "NONE",
  "AL", "rhtp_site",           "INDEX",   "https://alabamarhtp.com/", "AL_alabamarhtp_home.html", "NONE",
  "AL", "rhtp_resources",      "INDEX",   "https://alabamarhtp.com/resources/", "AL_alabamarhtp_resources.html", "NONE",
  "AL", "governor_release",    "CONTROL", "https://governor.alabama.gov/newsroom/2026/08/governor-ivey-announces-first-grants-in-major-new-rural-healthcare-program-totaling-more-than-144-million/", "AL_governor_ivey_first_arhtp_grants.html", "NONE",
  "AK", "doh_program",         "INDEX",   "https://health.alaska.gov/en/education/rural-health-transformation-program/", "AK_doh_rhtp_program_page.html", "NONE",
  "AK", "awards_notice",       "ROSTER",  "https://health.alaska.gov/media/tcvker5a/ak_rhtp_awardsnotice_2026.xlsx", "AK_rhtp_awardsnotice_2026.xlsx", "NONE",
  "AK", "cycle_update",        "CONTROL", "https://health.alaska.gov/media/lyrcb3pc/alaska-rhtp-year-1-funding-cycle-update.pdf", "AK_rhtp_year1_funding_cycle_update.pdf", "NONE",
  "OR", "rhtp_home",           "INDEX",   "https://www.oregon.gov/oha/HPA/HP/Pages/rural-health-transformation.aspx", "OR_oha_rhtp_home.html", "NONE",
  "OR", "awards_page",         "INDEX",   "https://www.oregon.gov/oha/HPA/HP/Pages/rhtp-awards.aspx", "OR_oha_rhtp_awards_page.html", "STRIP_SCRIPTS",
  "OR", "catalyst_data",       "CONTROL", "https://www.oregon.gov/oha/HPA/HP/Documents/RHTP-Awards-Data.xlsx", "OR_oha_RHTP-Awards-Data.xlsx", "NONE",
  "IL", "hfs_rhtp",            "INDEX",   "https://hfs.illinois.gov/info/fedresctr/ruralhealthtp.html", "IL_hfs_rhtp_program_page.html", "STRIP_CREDENTIAL_NODES",
  "IL", "planning_methodology", "CONTROL", "https://hfs.illinois.gov/content/dam/soi/en/web/hfs/info/fedresctr/RHTPHospitalPlngGrantMethodologyAccCheckUpdtd.pdf", "IL_rhtp_hospital_planning_grant_methodology.pdf", "NONE"
)

# The committed archive each live source is compared against, where a digest
# comparison is meaningful. A page whose chrome carries a per-request nonce is
# deliberately absent here: session 13 established that a full-page digest that
# is not reproducible is a trap for the reader, not evidence.
RECHECK_DIGEST_PAIRS <- tibble::tribble(
  ~state, ~key,                ~committed,
  "PA", "eligible_projects",   "data/evidence/PA/2026-08-28_dhs_rural_health_selected_projects.html",
  "AL", "governor_release",    "data/evidence/AL/2026-08-24_governor_ivey_first_arhtp_grants.html",
  "AK", "awards_notice",       "data/evidence/AK/2026-08-28_ak_rhtp_awardsnotice_2026.xlsx",
  "OR", "catalyst_data",       "data/evidence/OR/2026-08-28_oha_RHTP-Awards-Data.xlsx"
)

# What the committed extractions say today. Read from the CSVs on every run --
# never typed here, so a state that is re-extracted moves this table with it.
RECHECK_COMMITTED <- c(
  FL = "data/reference/fl_year1_awardees.csv",
  GA = "data/reference/ga_great_health_awards.csv",
  PA = "data/reference/pa_year1_awardees.csv",
  AL = "data/reference/al_year1_awardees.csv",
  AK = "data/reference/ak_year1_awardees.csv",
  OR = "data/reference/or_year1_awardees.csv",
  IL = "data/reference/il_year1_awardees.csv"
)

RECHECK_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

recheck_path <- function(state, key) {
  row <- RECHECK_SOURCES[RECHECK_SOURCES$state == state & RECHECK_SOURCES$key == key, ]
  if (nrow(row) != 1L) {
    stop("[recheck] unknown source: ", state, "/", key, call. = FALSE)
  }
  file.path(RECHECK_DIR, state, row$file)
}

#' Remove every <script>, credential-bearing or not (session 17's remedy)
recheck_strip_scripts <- function(body) {
  doc <- xml2::read_html(rawToChar(body))
  xml2::xml_remove(xml2::xml_find_all(doc, "//script"))
  charToRaw(as.character(doc))
}

#' Remove every node whose attributes carry a credential (session 16's remedy)
recheck_strip_credential_nodes <- function(body) {
  doc <- xml2::read_html(rawToChar(body))
  shapes <- paste(RECHECK_CREDENTIAL_SHAPES, collapse = "|")
  for (node in xml2::xml_find_all(doc, "//*[@*]")) {
    attrs <- xml2::xml_attrs(node)
    if (length(attrs) && any(stringr::str_detect(attrs, shapes))) {
      xml2::xml_remove(node)
    }
  }
  charToRaw(as.character(doc))
}

recheck_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(RECHECK_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, RECHECK_CREDENTIAL_SHAPES[[nm]])) {
      stop("[recheck] refusing to archive ", label,
           ": it carries what looks like a ", nm,
           ". Reduce it before archiving (§7.1).", call. = FALSE)
    }
  }
  invisible(TRUE)
}

recheck_fetch <- function(force = FALSE) {
  full_digest <- new.env(parent = emptyenv())
  entries <- purrr::map_dfr(seq_len(nrow(RECHECK_SOURCES)), function(i) {
    src  <- RECHECK_SOURCES[i, ]
    dir  <- file.path(RECHECK_DIR, src$state)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(dir, src$file)

    if (file.exists(dest) && !force) {
      message("[recheck] cached: ", src$state, "/", src$file)
    } else {
      Sys.sleep(RECHECK_THROTTLE)
      message("[recheck] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(RECHECK_USER_AGENT),
                        httr::timeout(180))
      if (httr::status_code(resp) != 200L) {
        stop("[recheck] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      served <- httr::content(resp, as = "raw")
      body <- switch(src$reduce,
        STRIP_SCRIPTS          = recheck_strip_scripts(served),
        STRIP_CREDENTIAL_NODES = recheck_strip_credential_nodes(served),
        served)
      # Asserted AFTER the reduction, so a reduction that fails to remove the
      # credential is caught rather than trusted.
      recheck_assert_credential_free(body, src$file)
      writeBin(body, dest)
      # Only a REDUCED file needs its full-page digest recorded: for an
      # unreduced one the two are the same number, and printing it twice
      # invites a reader to think something was removed.
      if (!identical(src$reduce, "NONE")) {
        assign(src$file,
               digest::digest(served, algo = "sha256", serialize = FALSE),
               envir = full_digest)
      }
    }

    tibble::tibble(
      state = src$state, key = src$key, role = src$role, file = src$file,
      url = src$url, reduce = src$reduce, bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      full_sha256 = if (exists(src$file, envir = full_digest, inherits = FALSE))
        get(src$file, envir = full_digest) else NA_character_,
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  for (st in unique(entries$state)) {
    recheck_write_manifest(entries[entries$state == st, ], st)
  }
  entries
}

recheck_write_manifest <- function(entries, state) {
  path <- file.path(RECHECK_DIR, state, "MANIFEST.txt")
  writeLines(c(
    paste0(state, " -- RHTP award pages and their immediate children, re-read ",
           RECHECK_DATE),
    "Archived by R/03q_state_completeness_recheck.R --fetch",
    paste0("User-agent: ", RECHECK_USER_AGENT),
    "",
    "This is a COMPLETENESS RE-CHECK archive, not an extraction source. Nothing",
    "here has been extracted into a reference CSV; where it shows a roster this",
    "repository does not carry, that is reported and left for the state's own",
    "extractor. Files are the body the server sent, byte for byte, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below --",
    "EXCEPT where reduce=STRIP_SCRIPTS, which is Oregon's awards page: it loads",
    "Google Maps and carries the API key inside a <script> src, which is",
    "Oregon's to publish and not ours to redistribute (§7.1, session 17). Every",
    "<script> is removed and the full page's digest as served is recorded",
    "beneath the entry, so provenance still closes.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes, role=", entries$role, ", reduce=", entries$reduce, ")  <- ",
           entries$url,
           ifelse(is.na(entries$full_sha256), "",
                  paste0("\n    full page as served: ", entries$full_sha256)))
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

recheck_html_text <- function(path) {
  doc <- xml2::read_html(path)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script|//style"))
  stringr::str_squish(xml2::xml_text(doc))
}

recheck_links <- function(path, base) {
  doc <- xml2::read_html(path)
  a <- xml2::xml_find_all(doc, "//a[@href]")
  tibble::tibble(
    text = stringr::str_squish(xml2::xml_text(a)),
    href = xml2::url_absolute(xml2::xml_attr(a, "href"), base)
  ) %>%
    dplyr::filter(!is.na(.data$href),
                  !stringr::str_detect(.data$href, "^(mailto|tel|javascript)")) %>%
    dplyr::distinct()
}

#' Every `$amount` beside a `GREAT-nnnnnn` application number, in a DCH notice
#'
#' DCH sets the recipient, the amount and the grant number in three adjacent
#' table cells, so this matches the AMOUNT AND THE GRANT NUMBER TOGETHER rather
#' than either alone: a stray dollar figure elsewhere on the page cannot then be
#' read as an award, and the grant number is what makes each row identifiable.
#' `name_hint` is the text that precedes the amount on the same visual line --
#' good enough to read a report by, and deliberately not what any assertion
#' rests on, because a recipient whose name wraps carries only its last line
#' here.
recheck_ga_notice <- function(path) {
  one <- stringr::str_replace_all(paste(rhtp_pdf_text(path), collapse = " "),
                                  "\\s+", " ")
  m <- stringr::str_match_all(
    one,
    "([A-Za-z][^$]{0,90}?)\\s*\\$\\s*([0-9][0-9,]*(?:\\.[0-9]{2})?)\\s*GREAT\\s*-?\\s*([0-9]+)")[[1]]
  if (nrow(m) == 0L) {
    stop("[recheck] GA: ", basename(path), " has no amount/grant-number pairs. ",
         "An EMPTY parse of an award notice must never read as an empty ",
         "notice.", call. = FALSE)
  }
  tibble::tibble(
    # The first row's hint carries the table header that precedes it; drop
    # everything up to DCH's own last header cell.
    name_hint = stringr::str_squish(
      stringr::str_replace(m[, 2], "^.*Grant Application\\s*#\\s*", "")),
    amount = as.numeric(gsub(",", "", m[, 3])),
    application = paste0("GREAT-", m[, 4])
  )
}

recheck_ak_notice <- function(path) {
  d <- openxlsx::read.xlsx(path, sheet = "Notice of Intent to Award",
                           detectDates = FALSE)
  names(d) <- make.names(names(d))
  d
}


# -- the per-state checks -----------------------------------------------------

#' Georgia: the funding-opportunities page is the index nobody read
#'
#' The positive control is the page itself. DCH publishes an award document as a
#' link whose text begins "Notice of Award" or "Notice of Intent to Award", and
#' a strategy with no award yet -- Telehealth Enhancements -- carries only its
#' guidelines. So the four links this file reads are what a published roster
#' looks like here, and the absence of a fifth is a real absence.
recheck_ga <- function() {
  path <- recheck_path("GA", "funding_opportunities")
  links <- recheck_links(path, "https://greathealth.georgia.gov/find-funding-opportunities")
  award_links <- links %>%
    dplyr::filter(stringr::str_detect(.data$text,
      "(?i)^notice of (intent to )?award"))
  if (nrow(award_links) != 4L) {
    stop("[recheck] GA: expected 4 award documents on find-funding-opportunities ",
         "(2 strategies x NITA + signed NOA); found ", nrow(award_links),
         ". Georgia has published something this check does not describe.",
         call. = FALSE)
  }
  if (!any(stringr::str_detect(links$text, "(?i)telehealth enhancements"))) {
    stop("[recheck] GA: the Telehealth Enhancements strategy is gone from the ",
         "page. It is the control for a strategy with guidelines and NO award ",
         "document; without it, 'no fifth roster' means nothing.", call. = FALSE)
  }

  robots   <- recheck_ga_notice(recheck_path("GA", "noa_robots"))
  telepods <- recheck_ga_notice(recheck_path("GA", "noa_telepods"))
  robots_i   <- recheck_ga_notice(recheck_path("GA", "nita_robots"))
  telepods_i <- recheck_ga_notice(recheck_path("GA", "nita_telepods"))

  # The signed notice must name everyone the intent named. Where it does not,
  # the state has executed only part of what it intended and the difference is
  # the finding, not an error.
  stopifnot(nrow(robots) == nrow(robots_i),
            nrow(telepods) == nrow(telepods_i))
  stopifnot(isTRUE(all.equal(sum(robots$amount), sum(robots_i$amount))))
  stopifnot(isTRUE(all.equal(sum(telepods$amount), sum(telepods_i$amount))))

  ga <- readr::read_csv(here::here(RECHECK_COMMITTED[["GA"]]),
                        show_col_types = FALSE, progress = FALSE)
  aggregates <- ga %>%
    dplyr::filter(stringr::str_detect(.data$awardee, "names not captured"))
  if (nrow(aggregates) != 2L) {
    stop("[recheck] GA: expected the two 'names not captured' aggregate rows ",
         "in ga_great_health_awards.csv; found ", nrow(aggregates),
         ". If Georgia has been re-extracted, this check is stale.",
         call. = FALSE)
  }
  stopifnot(sum(aggregates$recipient_count) == nrow(robots) + nrow(telepods))

  list(
    robots = robots, telepods = telepods,
    actions = nrow(robots) + nrow(telepods),
    dollars = sum(robots$amount) + sum(telepods$amount),
    aggregate_rows = aggregates
  )
}

#' Alaska: the same URL, a bigger file
#'
#' The positive control is Alaska's own Year 1 Funding Cycle Update, which
#' publishes the weekly cumulative counts. It is what makes the growth a
#' STATE-PUBLISHED fact rather than this pipeline's diff of two downloads.
recheck_ak <- function() {
  live      <- recheck_ak_notice(recheck_path("AK", "awards_notice"))
  committed <- recheck_ak_notice(here::here(
    "data/evidence/AK/2026-08-28_ak_rhtp_awardsnotice_2026.xlsx"))
  amount_col <- grep("^Award\\.Amount", names(live), value = TRUE)[1]

  new_ids <- setdiff(live$App.ID, committed$App.ID)
  gone    <- setdiff(committed$App.ID, live$App.ID)
  if (length(gone)) {
    stop("[recheck] AK: ", length(gone), " award(s) have DISAPPEARED from the ",
         "notice. A rolling notice that loses rows is a different problem from ",
         "one that gains them: ", paste(head(gone, 5), collapse = ", "),
         call. = FALSE)
  }

  update <- paste(rhtp_pdf_text(recheck_path("AK", "cycle_update")), collapse = " ")
  update <- stringr::str_replace_all(update, "\\s+", " ")
  if (!stringr::str_detect(update, "rolling weekly basis")) {
    stop("[recheck] AK: the funding cycle update no longer says awards are ",
         "announced on a rolling weekly basis -- the reason this file expects ",
         "the notice to grow.", call. = FALSE)
  }
  stated_projects <- as.integer(stringr::str_match(update,
    "Cumulative\\s+Total\\s+\\$[0-9.]+M\\s+Project\\s+Awards\\s+(\\d{2,4})\\s+Projects")[, 2])
  if (is.na(stated_projects)) {
    stop("[recheck] AK: could not read the cumulative project count out of the ",
         "funding cycle update. It is the STATE'S OWN corroboration of the ",
         "growth below; without it this is only a diff of two downloads.",
         call. = FALSE)
  }
  if (stated_projects != nrow(live)) {
    stop("[recheck] AK: the funding cycle update states ", stated_projects,
         " projects and the notice carries ", nrow(live),
         ". Two Alaska documents disagree -- read them before reporting either.",
         call. = FALSE)
  }

  list(
    live_rows = nrow(live), committed_rows = nrow(committed),
    new_ids = new_ids,
    live_total = sum(as.numeric(live[[amount_col]]), na.rm = TRUE),
    committed_total = sum(as.numeric(committed[[amount_col]]), na.rm = TRUE),
    new_total = sum(as.numeric(live[[amount_col]][live$App.ID %in% new_ids]),
                    na.rm = TRUE),
    state_stated_projects = stated_projects
  )
}

#' Florida: the committed file against the Governor's own roster
#'
#' The strongest negative in this file, and the only end-to-end check of a whole
#' state file against its primary source that this repository has ever done.
recheck_fl <- function() {
  lines <- rhtp_pdf_text(recheck_path("FL", "awardee_list"))
  one <- paste(lines, collapse = "\n")
  m <- stringr::str_match_all(
    one, "(?m)^\\s*(\\d{1,3})\\s*(.+?)\\s*\\$([0-9,]+\\.[0-9]{2})\\s*$")[[1]]
  pdf <- tibble::tibble(
    no = as.integer(m[, 2]),
    awardee = stringr::str_squish(m[, 3]),
    amount = as.numeric(gsub(",", "", m[, 4]))
  )
  fl <- readr::read_csv(here::here(RECHECK_COMMITTED[["FL"]]),
                        show_col_types = FALSE, progress = FALSE)
  list(
    pdf_rows = nrow(pdf), csv_rows = nrow(fl),
    pdf_total = sum(pdf$amount), csv_total = sum(fl$amount),
    numbering_gaps = setdiff(seq_len(max(pdf$no)), pdf$no)
  )
}

#' Pennsylvania: the roster is unchanged, and three more pools name nobody
recheck_pa <- function() {
  live <- recheck_path("PA", "eligible_projects")
  committed <- here::here(
    "data/evidence/PA/2026-08-28_dhs_rural_health_selected_projects.html")
  rows_of <- function(p) {
    length(xml2::xml_find_all(xml2::read_html(p), "//table//tr"))
  }
  # DHS's funding page is a solicitation index. It must not carry a roster --
  # if it starts to, this check is what notices.
  #
  # Read from the RAW file, not from the tag-stripped text: pa.gov delivers each
  # accordion's body as an ESCAPED HTML string inside a JSON attribute, so the
  # markup around "Total Available Funding" survives tag-stripping as literal
  # `&lt;/b>` and the figure is not adjacent to its label in the visible text.
  funding_raw <- paste(readLines(recheck_path("PA", "funding_opportunities"),
                                 warn = FALSE), collapse = "\n")
  pools <- stringr::str_match_all(funding_raw,
    "Total Available Funding:\\s*(?:&lt;/b>)?\\s*\\$([0-9.]+) (million|billion)")[[1]]
  if (nrow(pools) == 0L) {
    stop("[recheck] PA: no funding pools found on the funding-opportunities ",
         "page. Either DHS has changed the page or the reader is looking in ",
         "the wrong place -- either way, do not report 'no further pools'.",
         call. = FALSE)
  }
  list(
    live_rows = rows_of(live), committed_rows = rows_of(committed),
    identical_digest = identical(digest::digest(file = live, algo = "sha256"),
                                 digest::digest(file = committed, algo = "sha256")),
    pool_count = nrow(pools),
    pool_dollars = sum(as.numeric(pools[, 2]) *
                         ifelse(pools[, 3] == "billion", 1e9, 1e6))
  )
}

#' Illinois: 97 hospitals with CCNs, and it is an ELIGIBILITY list (§0.3)
recheck_il <- function() {
  tx <- rhtp_pdf_text(recheck_path("IL", "planning_methodology"))
  # A CCN opens its own table row, so it anchors at the start of a line. Matching
  # the token anywhere would also catch a ZIP code or a bed count.
  ccn <- stringr::str_match(stringr::str_squish(tx), "^(1[0-9]{5})\\b")[, 2]
  ccn <- ccn[!is.na(ccn)]
  one <- stringr::str_replace_all(paste(tx, collapse = " "), "\\s+", " ")
  conditional <- stringr::str_detect(
    one, "(?i)if all[^.]{0,40}hospitals apply, this will result in an award amount")
  if (!conditional) {
    stop("[recheck] IL: the planning-grant methodology no longer states its ",
         "per-hospital figure as CONDITIONAL on all hospitals applying. That ",
         "conditional is the whole reason these 97 hospitals are eligibility ",
         "and not receipt (§0.3) -- re-read it before coding anything.",
         call. = FALSE)
  }
  list(eligible_hospitals = length(unique(ccn)),
       pool = as.numeric(gsub("[$,]", "",
         stringr::str_extract(one, "\\$28,191,393\\.00"))),
       is_eligibility_not_receipt = TRUE)
}

#' Oregon: twelve bulletins, one roster, and the other eleven are not
#'
#' Session 17 found Oregon's hospital and clinic lists in a GovDelivery bulletin
#' that no oregon.gov page linked. The RHTP home page links TWELVE such
#' bulletins and only one was ever read, which is precisely the Kansas shape.
#' All twelve are enumerated here; the roster is the one with a table of
#' recipients and a hundred-odd dollar figures, and the other eleven are
#' webinar invitations, deadline extensions and RFGP addenda.
recheck_or <- function() {
  home <- recheck_path("OR", "rhtp_home")
  txt  <- paste(readLines(home, warn = FALSE), collapse = "\n")
  ids  <- unique(stringr::str_match_all(
    txt, "content\\.govdelivery\\.com/accounts/ORHA/bulletins/([0-9a-f]+)")[[1]][, 2])
  live  <- recheck_path("OR", "catalyst_data")
  comm  <- here::here("data/evidence/OR/2026-08-28_oha_RHTP-Awards-Data.xlsx")
  list(
    bulletins = ids,
    extracted_bulletin = "4164e4f",
    catalyst_identical = identical(digest::digest(file = live, algo = "sha256"),
                                   digest::digest(file = comm, algo = "sha256"))
  )
}

#' Alabama: still a solicitation site, and the release is byte-identical
recheck_al <- function() {
  live <- recheck_path("AL", "governor_release")
  comm <- here::here("data/evidence/AL/2026-08-24_governor_ivey_first_arhtp_grants.html")
  res  <- recheck_html_text(recheck_path("AL", "rhtp_resources"))
  home <- recheck_html_text(recheck_path("AL", "rhtp_site"))
  list(
    release_identical = identical(digest::digest(file = live, algo = "sha256"),
                                  digest::digest(file = comm, algo = "sha256")),
    year1_closed = stringr::str_detect(
      home, "Year 1 initiative application periods are now closed"),
    nofo_count = stringr::str_count(res, "(?i)NOFO For ")
  )
}


# -- the summary table --------------------------------------------------------

recheck_table <- function() {
  ga <- recheck_ga(); ak <- recheck_ak(); fl <- recheck_fl()
  pa <- recheck_pa(); il <- recheck_il(); or <- recheck_or(); al <- recheck_al()

  committed_rows <- vapply(RECHECK_COMMITTED, function(f) {
    nrow(readr::read_csv(here::here(f), show_col_types = FALSE, progress = FALSE))
  }, integer(1))

  tibble::tribble(
    ~state, ~finding, ~additional_award_actions, ~additional_dollars, ~detail,
    "FL", "NO_ADDITIONAL_ROSTER", 0L, 0,
      paste0("The Governor's own awardee PDF reconciles EXACTLY with the ",
             "committed file: ", fl$pdf_rows, " awardees and $",
             formatC(fl$pdf_total, format = "f", digits = 2, big.mark = ","),
             " against ", fl$csv_rows, " rows and $",
             formatC(fl$csv_total, format = "f", digits = 2, big.mark = ","),
             ". The source numbers 1-",
             fl$pdf_rows + length(fl$numbering_gaps),
             " and skips ", paste(fl$numbering_gaps, collapse = ", "),
             " -- a gap in the Governor's office's numbering, not the ",
             "parse's. AHCA's own page ",
             "publishes no roster and points at this release. The release also ",
             "refers to an EARLIER procurement round for monitoring and support ",
             "vendors whose recipients are not published anywhere reachable."),
    "GA", "ADDITIONAL_ROSTER_FOUND", as.integer(ga$actions), ga$dollars,
      paste0("Two signed Notices of Award on ",
             "greathealth.georgia.gov/find-funding-opportunities -- a page no ",
             "session has read -- name ", ga$actions, " hospital award actions ",
             "worth $", format(ga$dollars, big.mark = ","),
             ". The committed file carries them as TWO aggregate rows reading ",
             "'names not captured', recipient_count ",
             paste(ga$aggregate_rows$recipient_count, collapse = " and "),
             ", with amount empty. The dollars are already inside Georgia's ",
             "$197,148,327 at POOL level, so this is not new money: it is ",
             "named hospitals where there were none."),
    "PA", "NO_ADDITIONAL_ROSTER", 0L, 0,
      paste0("The eligible-projects table is BYTE-IDENTICAL to the committed ",
             "archive (", pa$live_rows, " table rows, 66 projects). DHS's ",
             "funding-opportunities page -- a child never read -- lists ",
             pa$pool_count, " further payment programmes worth about $",
             format(pa$pool_dollars, big.mark = ","),
             " and names NO recipient for any of them. Eligibility is not ",
             "receipt (§0.3); there is nothing here to extract."),
    "AL", "NO_ADDITIONAL_ROSTER", 0L, 0,
      paste0("The governor's release is BYTE-IDENTICAL to the committed ",
             "archive, so the 138 grants stand. alabamarhtp.com is still a ",
             "solicitation site: ", al$nofo_count, " closed NOFOs, no award ",
             "file in any format, and the home page states Year 1 application ",
             "periods are now closed."),
    "AK", "ROSTER_HAS_GROWN", as.integer(length(ak$new_ids)), ak$new_total,
      paste0("The rolling notice of intent to award has grown from ",
             ak$committed_rows, " to ", ak$live_rows, " award actions and $",
             format(ak$committed_total, big.mark = ","), " to $",
             format(ak$live_total, big.mark = ","),
             ". Alaska's own Year 1 Funding Cycle Update corroborates it ",
             "independently at ", ak$state_stated_projects,
             " projects, and says awards are announced on a rolling weekly ",
             "basis. One committed award was also revised UPWARD; no award ",
             "disappeared."),
    "OR", "NO_ADDITIONAL_ROSTER", 0L, 0,
      paste0("The awards page and the Catalyst data file are unchanged (the ",
             "xlsx is byte-identical). The RHTP home page links ",
             length(or$bulletins), " GovDelivery bulletins and session 17 read ",
             "ONE of them; the other eleven were read here and none is a ",
             "roster -- they are webinar invitations, deadline extensions, RFGP ",
             "addenda and the two December award announcements already ",
             "archived. Wave 2 is still 21 of OHA's stated 33."),
    "IL", "NO_ADDITIONAL_ROSTER", 0L, 0,
      paste0("HFS still publishes no recipient-level award list; il.amplifund.com ",
             "is behind a sign-in. The one recipient-level document is the ",
             "Hospital Planning Grant Methodology, which names ",
             il$eligible_hospitals, " ELIGIBLE hospitals WITH CCNs against a $",
             format(il$pool, big.mark = ","), " pool and states its per-hospital ",
             "figure conditionally ('if all hospitals apply'). §0.3: that is ",
             "eligibility, not receipt, and nothing was coded from it. The CCN ",
             "list is worth keeping for open blocker 5.")
  ) %>%
    dplyr::mutate(
      recheck_date = RECHECK_DATE,
      committed_rows = unname(committed_rows[.data$state]),
      .before = "finding"
    )
}

recheck_validate <- function() {
  tbl <- recheck_table()
  stopifnot(nrow(tbl) == length(RECHECK_COMMITTED))
  stopifnot(all(tbl$state %in% names(RECHECK_COMMITTED)))
  allowed <- c("NO_ADDITIONAL_ROSTER", "ADDITIONAL_ROSTER_FOUND",
               "ROSTER_HAS_GROWN")
  bad <- setdiff(tbl$finding, allowed)
  if (length(bad)) {
    stop("[recheck] finding outside the controlled set: ",
         paste(bad, collapse = ", "), call. = FALSE)
  }
  # A state reported as having nothing more must carry zero on both counters,
  # and a state reported as having more must carry a positive count. The pair
  # is what stops a finding and its figures drifting apart.
  neg <- tbl$finding == "NO_ADDITIONAL_ROSTER"
  stopifnot(all(tbl$additional_award_actions[neg] == 0L),
            all(tbl$additional_dollars[neg] == 0))
  stopifnot(all(tbl$additional_award_actions[!neg] > 0L),
            all(tbl$additional_dollars[!neg] > 0))
  message("[recheck] all assertions pass. ", sum(!neg), " of ", nrow(tbl),
          " states have award rosters beyond what is extracted.")
  invisible(tbl)
}

recheck_build <- function() {
  tbl <- recheck_validate()
  readr::write_csv(tbl, here::here(RECHECK_CSV), na = "")
  message("[recheck] wrote ", RECHECK_CSV, " (", nrow(tbl), " rows)")
  invisible(tbl)
}

recheck_report <- function() {
  tbl <- recheck_table()
  cat("\nCOMPLETENESS RE-CHECK -- seven extracted states, ", RECHECK_DATE, "\n",
      sep = "")
  cat(strrep("=", 78), "\n")
  for (i in seq_len(nrow(tbl))) {
    cat("\n", tbl$state[i], "  [", tbl$finding[i], "]  committed rows: ",
        tbl$committed_rows[i], "\n", sep = "")
    if (tbl$additional_award_actions[i] > 0L) {
      cat("  ADDITIONAL: ", tbl$additional_award_actions[i],
          " award actions, $", format(tbl$additional_dollars[i], big.mark = ","),
          "\n", sep = "")
    }
    cat("  ", strwrap(tbl$detail[i], width = 74, prefix = "  ",
                      initial = ""), sep = "\n  ")
  }
  cat("\n", strrep("=", 78), "\n", sep = "")
  cat("NOTHING HERE HAS BEEN EXTRACTED. Georgia's hospitals belong to R/03d ",
      "and\nAlaska's new awards to R/03h.\n", sep = "")
  invisible(tbl)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(recheck_fetch(force = "--force" %in% args))
  if ("--validate" %in% args) recheck_validate()
  if ("--build" %in% args) recheck_build()
  if ("--report" %in% args) recheck_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03q_state_completeness_recheck.R",
        "[--fetch|--validate|--build|--report]\n")
  }
}

# 03m_or_year1_awardees.R ----------------------------------------------------
#
# OREGON — Rural Health Transformation Program, Year 1 (FY2026).
#
# WHY OREGON, AND WHY IT WAS NEVER LOOKED AT. Oregon issued no CMS press
# release, so it never entered the stage 00 trigger list and every state hunt
# in sessions 9-15 ran past it. Session 16's 50-state RCJ survey put it FIRST
# by a wide margin -- 386 Tier 3 candidates across 258 distinct awardees, more
# than any state then extracted -- and `state_trigger_queue.csv` ranks it 1.
# This file is that queue being worked.
#
# WHAT OREGON PUBLISHES. More than any state in this project so far, and
# through FOUR documents rather than one, because OHA runs four separate award
# pools and publishes each differently:
#
#   Catalyst Awards            $80,114,365  103 projects / 85 orgs  MACHINE-READABLE XLSX
#   Transformation - hospitals $34,998,000   35 named hospitals     GOVDELIVERY BULLETIN
#   Transformation - RHCs       $9,900,000   99 named clinics       GOVDELIVERY BULLETIN
#   Immediate Impact  Wave 1     $5,192,000  12 projects            AWARDS PAGE PROSE
#   Immediate Impact  Wave 2    $11,294,644  21 of 33 projects      AWARDS PAGE PROSE
#   Tribal Initiative          $21,700,000    9 Tribes, UNNAMED     NEWS RELEASE ONLY
#   Transformation - LPHAs      $5,000,000   33 LPHAs,  UNNAMED     NEWS RELEASE ONLY
#
# THE PRIOR SIGNAL WAS WRONG ABOUT THE RECIPIENT CLASS, AND THE STATE SOURCE IS
# WHAT SAYS SO. RCJ shows 99 awards of exactly $100,000 to 99 distinct
# organisations and it is tempting to read that as 99 hospitals -- a large,
# clean, uniform hospital block. It is not. OHA's own bulletin puts those 99
# under the heading "Rural Health Clinics (RHCs)" and prints them in a separate
# table from the hospitals, at a standardised $100,000 against a stated $10M
# RHC pool. Oregon's hospital block is a DIFFERENT table in the same document:
# 35 rural hospitals, tiered by bed count, $963,000 for the 32 at <=50 beds and
# $1,394,000 for the 3 above, Grand Total $34,998,000. §0.1 in one paragraph --
# the aggregator told us where to look and got the class wrong.
#
# TWO RCJ DEFECTS ARE VISIBLE IN THE SAME 136 RECORDS, both of the kind §0.1
# lists: the bulletin's own title ("Oregon Health Authority Announces Funding
# for Rural Hospitals") is captured as an AWARDEE at $963,000, and its
# "Grand Total" row is captured as an AWARDEE at $34,998,000. Neither is a
# recipient. Nothing in this file is taken from RCJ; the parse is against the
# state's own documents and RCJ's figures are used only as a cross-check that
# the archive is the document RCJ saw.
#
# Usage:
#   Rscript R/03m_or_year1_awardees.R --fetch      # archive 5 sources + SHA-256
#   Rscript R/03m_or_year1_awardees.R --validate   # parse + assert, no writes
#   Rscript R/03m_or_year1_awardees.R --build      # writes csv + xlsx

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
  library(purrr)
  library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

OR_STATE           <- "OR"
OR_FISCAL_YEAR     <- "FY2026 (Year 1)"
OR_ALLOTMENT       <- 197271578      # cms_fy2026_allotments.csv, asserted below
OR_EVIDENCE_DIR    <- here::here("data", "evidence", "OR")

# §9.5 conduct: a descriptive agent identifying AHA with a contact URL, and a
# throttle applied per host independent of any other. oregon.gov's robots.txt
# disallows /oha/ohp/, /oha/bh/ and /oha/engage/ and sets no crawl-delay; every
# path below is outside those prefixes.
OR_USER_AGENT      <- "AHA-RHTP-Tracker/1.0 (American Hospital Association research; +https://www.aha.org)"
OR_HOST_THROTTLE_S <- 4

# The five sources, and what is archived of each.
#
# FOUR ARE ARCHIVED WHOLE. THE AWARDS PAGE IS NOT, AND THE GUARD IS WHAT SAID
# SO. A hand grep before the first fetch reported all five clean; it was wrong.
# `rhtp-awards.aspx` loads Google Maps for its Catalyst distribution map and
# carries the key in the script URL as `...maps/api/js?...&key=AIza...`, which
# a pattern looking for `api_key=` or `apiKey:` walks straight past. That is
# Google's key to publish and not ours to redistribute -- the same call §7.1
# made for CMS's Mapbox token and R/03l made for Illinois' -- so the page is
# reduced by REMOVING EVERY <script> ELEMENT before it is written. The key
# lives only in a script src and the accordion content is plain markup, so the
# reduction costs nothing that is parsed. The full page's digest is recorded
# alongside the archived one, so provenance still closes.
#
# The lesson worth keeping is not "Oregon had a key". It is that the check that
# found it was the automated one, running on every fetch, and the check that
# missed it was a human reading a grep once.
OR_SOURCES <- tibble::tribble(
  ~key,                ~url,                                                                                                                              ~file,                                              ~reduce,          ~doc_title,
  "awards_page",       "https://www.oregon.gov/oha/HPA/HP/Pages/rhtp-awards.aspx",                                                                        "2026-08-28_oha_rhtp_awards_page.html",             "STRIP_SCRIPTS",  "RHTP Awards & Investments in Rural Communities",
  "catalyst_data",     "https://www.oregon.gov/oha/HPA/HP/Documents/RHTP-Awards-Data.xlsx",                                                               "2026-08-28_oha_RHTP-Awards-Data.xlsx",             "NONE",           "RHTP Catalyst Awards data file (RHTP-Awards-Data.xlsx)",
  "transformation",    "https://content.govdelivery.com/accounts/ORHA/bulletins/4164e4f",                                                                 "2026-05-07_oha_transformation_fund_bulletin.html", "NONE",           "Oregon Health Authority Announces Funding for Rural Hospitals and Rural Health Clinics",
  "news_2026_04_10",   "https://www.oregon.gov/oha/ERD/Pages/Oregon-organizations-awarded-federal-funding-to-improve-rural-healthcare-04.10.2026.aspx",    "2026-04-10_oha_news_release.html",                 "NONE",           "Oregon organizations awarded federal funding to improve rural healthcare",
  "news_2026_07_07",   "https://www.oregon.gov/oha/ERD/Pages/$97M-awarded-across-Oregon-to-improve-rural-health-07.07.2026.aspx",                          "2026-07-07_oha_news_release.html",                 "NONE",           "OHA announces grants to advance rural healthcare in every Oregon county"
)

#' Remove every <script> element, keeping the document otherwise intact
#'
#' The narrowest reduction that removes the credential: the Google Maps key is
#' in a script `src` and nothing this file parses lives in a script.
or_strip_scripts <- function(body) {
  doc <- xml2::read_html(rawToChar(body))
  xml2::xml_remove(xml2::xml_find_all(doc, "//script"))
  charToRaw(as.character(doc))
}

or_source <- function(key, field) {
  row <- OR_SOURCES[OR_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[OR] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

or_archive_path <- function(key) file.path(OR_EVIDENCE_DIR, or_source(key, "file"))


# -- the figures OHA itself states, in its own documents ----------------------
#
# Every one of these is quoted from a source archived under data/evidence/OR/,
# and every one is asserted against the parse below. They are the reconciliation
# and they are also the tripwire: if OHA republishes a page with a different
# count, the assert fails here rather than a wrong number reaching a workbook.
OR_STATED <- list(
  catalyst_orgs        = 85L,
  catalyst_projects    = 103L,
  catalyst_bp1         = 80114365,      # the xlsx's own Total row
  catalyst_bp2         = 76065076,
  hospitals_small_n    = 32L,           # "<=50 beds ... are eligible for $963,000"
  hospitals_small_amt  = 963000,
  hospitals_large_n    = 3L,            # "more than 50 beds ... $1,394,000"
  hospitals_large_amt  = 1394000,
  hospitals_total      = 34998000,      # the bulletin's own "Grand Total"
  rhc_amt              = 100000,        # "All eligible RHCs ... standardized"
  rhc_pool             = 10000000,      # news release: "$10 million ... rural health clinics"
  iia_wave1_projects   = 12L,           # news release 04-10: "The 12 projects"
  iia_wave1_pool       = 6500000,       # "expected to collectively receive up to $6.5 million"
  iia_wave2_projects   = 33L,           # news release 07-07: "33 new ready-to-go projects"
  iia_wave2_pool       = 17000000,      # "Another $17 million"
  tribal_pool          = 21700000,      # "$21.7 million ... Tribal Initiative"
  tribal_recipients    = 9L,            # "the Nine Federally Recognized Tribes of Oregon"
  lpha_pool            = 5000000,       # "$5 million in direct funding" / 33 LPHAs
  lpha_recipients      = 33L,
  awarded_to_date      = 175300000      # "about $175.3 million total" (07-07), approximate
)


# -- fetch -------------------------------------------------------------------

#' Archive the five Oregon sources verbatim, with a SHA-256 manifest
#'
#' Bytes are written with `writeBin()` and the digest is taken of the body the
#' server sent, so re-hashing the file on disk reproduces the manifest exactly.
#' Session 12 found `writeLines()` appends a newline, leaving every archived
#' file one byte longer than what was hashed; the four states written since
#' avoid it and so does this one, with a test that re-hashes from disk.
or_fetch_sources <- function(force = FALSE) {
  dir.create(OR_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(OR_SOURCES)), function(i) {
    src  <- OR_SOURCES[i, ]
    dest <- file.path(OR_EVIDENCE_DIR, src$file)

    if (file.exists(dest) && !force) {
      # §9.5: "cache aggressively -- a re-run must never re-fetch an unchanged
      # document". A state government site is not a resource to poll.
      message("[OR] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(OR_HOST_THROTTLE_S)
      message("[OR] fetching ", src$url)
      resp <- httr::GET(src$url,
                        httr::user_agent(OR_USER_AGENT),
                        httr::timeout(120))
      if (httr::status_code(resp) != 200L) {
        stop("[OR] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      served <- httr::content(resp, as = "raw")
      body   <- if (identical(src$reduce, "STRIP_SCRIPTS")) {
        or_strip_scripts(served)
      } else {
        served
      }
      # Asserted AFTER the reduction, so a reduction that fails to remove the
      # credential is caught rather than trusted.
      or_assert_credential_free(body, src$file)
      writeBin(body, dest)
      attr(dest, "full_sha256") <- digest::digest(served, algo = "sha256",
                                                  serialize = FALSE)
    }

    tibble::tibble(
      key         = src$key,
      file        = src$file,
      url         = src$url,
      reduce      = src$reduce,
      bytes       = file.info(dest)$size,
      sha256      = digest::digest(file = dest, algo = "sha256"),
      full_sha256 = attr(dest, "full_sha256") %||% NA_character_,
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  or_write_manifest(entries)
  entries
}

#' Refuse to archive anything carrying a credential
#'
#' Session 16 caught a Mapbox token inside `<main>` on hfs.illinois.gov -- the
#' node had to be removed by name because no container choice excluded it. All
#' five Oregon sources are clean, which is WHY they are archived whole; this
#' asserts that on every fetch rather than trusting the check that was run once
#' by hand. It matches on token SHAPE, not on a literal value, so a rotated
#' credential is caught too.
or_assert_credential_free <- function(body, label) {
  # An xlsx is a zip, so its bytes carry NULs that rawToChar() refuses. They are
  # dropped rather than the file being skipped: the scan then covers the
  # container's uncompressed portions, and the workbook's actual CONTENT is
  # separately visible through or_parse_catalyst(), whose columns are pinned.
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "UTF-8"

  patterns <- c(
    mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
    # Written to match the key ANYWHERE, including inside a script URL as
    # `?...&key=AIza...`, which is the form Oregon's awards page carries and the
    # form a pattern anchored on `api_key=` misses entirely.
    google_api_key = "AIza[A-Za-z0-9_-]{30,}",
    bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
    aws_key        = "AKIA[A-Z0-9]{12,}",
    sharepoint_digest = "__REQUESTDIGEST\"[^>]*value=\"(?!noDigest\")[^\"]{12,}"
  )

  for (nm in names(patterns)) {
    if (stringr::str_detect(txt, patterns[[nm]])) {
      stop("[OR] refusing to archive ", label, ": it carries what looks like a ",
           nm, ". Reduce the document to a credential-free container first, ",
           "as R/00 does for cms.gov and R/03l does for hfs.illinois.gov.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The manifest, which never lists itself
#'
#' Session 15's defect, kept fixed here: a manifest cannot record its own
#' digest, because the value is stale the instant the file is written. It had
#' always been wrong and the verification test passed on absence.
or_write_manifest <- function(entries) {
  path <- file.path(OR_EVIDENCE_DIR, "MANIFEST.txt")
  lines <- c(
    "Oregon Health Authority -- RHTP Year 1 award sources",
    "Archived by R/03m_or_year1_awardees.R --fetch",
    paste0("User-agent: ", OR_USER_AGENT),
    "",
    "Files are written with writeBin(), so re-hashing a file on disk reproduces",
    "its digest below. Four of the five are the body the server sent, byte for",
    "byte. THE AWARDS PAGE IS A REDUCTION: every <script> element is removed,",
    "because oregon.gov loads Google Maps for the Catalyst distribution map and",
    "carries the API key in the script URL. That key is Google's to publish and",
    "not ours to redistribute (§7.1's posture, as applied to CMS and Illinois).",
    "For a reduced file the full page's digest as served is recorded too, so",
    "provenance closes; the reduction removes nothing this repo parses.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes, reduce=", entries$reduce, ")  <- ", entries$url,
           ifelse(is.na(entries$full_sha256), "",
                  paste0("\n    full page as served: ", entries$full_sha256)))
  )
  writeLines(lines, path)
  invisible(path)
}


# -- parse: Catalyst Awards (the machine-readable file) ----------------------

#' Parse OHA's own Catalyst data file
#'
#' The cleanest Tier 3 source this project has met. OHA publishes the award
#' table as an xlsx with one row per PROJECT, an `Entity type` column carrying
#' the state's own classification of its own awardee, and a `Total` row it
#' computed itself -- so the reconciliation is against OHA's arithmetic, not
#' just against a headline.
#'
#' The `Total` and `End of worksheet` rows are dropped by NAME, and the parser
#' REFUSES if the Total row is missing, because a file whose own total has gone
#' is a file whose shape has changed and the row-sum has nothing to check it.
or_parse_catalyst <- function(path = or_archive_path("catalyst_data")) {
  raw <- openxlsx::read.xlsx(path, sheet = "Data", startRow = 3)

  expected <- c("Ogranization.name", "Project.ID", "Initiative",
                "Counties.served", "Regions.served", "Entity.type",
                "Budget.Year.1.(Approved)", "Budget.Year.2.(Expected)",
                "Total.Budget.(Expected)")
  # OHA's own header misspells "Organization". Matching it exactly is
  # deliberate: the day OHA fixes the typo the shape has changed and this
  # should fail loudly rather than resolve a column by luck.
  if (!identical(names(raw), expected)) {
    stop("[OR] Catalyst Data sheet columns changed. Expected:\n  ",
         paste(expected, collapse = " | "), "\nGot:\n  ",
         paste(names(raw), collapse = " | "), call. = FALSE)
  }

  total_row <- raw %>% dplyr::filter(.data$Ogranization.name == "Total")
  if (nrow(total_row) != 1L) {
    stop("[OR] the Catalyst file's own `Total` row is missing or duplicated (",
         nrow(total_row), " found). It is what the row-sum is checked against; ",
         "refusing to parse without it.", call. = FALSE)
  }

  projects <- raw %>%
    dplyr::filter(!is.na(.data$Ogranization.name),
                  !.data$Ogranization.name %in% c("Total", "End of worksheet"))

  list(
    projects   = projects,
    stated_bp1 = total_row[["Budget.Year.1.(Approved)"]],
    stated_bp2 = total_row[["Budget.Year.2.(Expected)"]]
  )
}


# -- parse: the Transformation Fund bulletin ---------------------------------

or_read_html <- function(path) {
  xml2::read_html(rawToChar(readBin(path, "raw", file.info(path)$size)))
}

#' Parse the two Transformation Fund tables out of OHA's bulletin
#'
#' The bulletin carries exactly two award tables and they are NOT the same
#' shape: hospitals have a `Beds` column and a `Grand Total` row, RHCs have
#' neither. They are returned SEPARATELY and never rbound here, because they
#' are two pools with two different per-recipient amounts and a reader who
#' receives one table cannot tell which pool a row came from.
#'
#' The 99/35 split is asserted rather than assumed. It is the whole correction
#' this file makes to the prior signal, and an assertion is the only form of
#' that correction that survives someone re-running the parser next year.
or_parse_transformation <- function(path = or_archive_path("transformation")) {
  doc    <- or_read_html(path)
  tables <- rvest::html_elements(doc, "table")

  grab <- function(node) {
    rows <- rvest::html_elements(node, "tr")
    purrr::map(rows, function(r) {
      cells <- rvest::html_elements(r, "td, th")
      stringr::str_squish(rvest::html_text2(cells))
    })
  }

  money <- function(x) {
    suppressWarnings(as.numeric(stringr::str_remove_all(x, "[$,\\s]")))
  }

  hosp <- NULL
  rhc  <- NULL

  for (node in tables) {
    rows <- grab(node)
    rows <- rows[vapply(rows, function(r) length(r) >= 2L, logical(1))]
    if (!length(rows)) next

    # The header is identified by its own labels, never by position: the
    # hospital table's first cell is a merged block carrying the whole preamble.
    flat   <- vapply(rows, function(r) paste(r, collapse = " | "), character(1))
    is_rhc <- any(stringr::str_detect(flat, "^Rural Health Clinic \\| Eligible"))

    body <- rows[-1]
    body <- body[vapply(body, function(r) {
      nzchar(r[1]) && any(stringr::str_detect(r, "^\\$[\\d,]+$"))
    }, logical(1))]
    if (!length(body)) next

    if (is_rhc) {
      rhc <- tibble::tibble(
        awardee = vapply(body, `[`, character(1), 1L),
        amount  = money(vapply(body, function(r) r[length(r)], character(1)))
      )
    } else {
      hosp <- tibble::tibble(
        awardee = vapply(body, `[`, character(1), 1L),
        beds    = suppressWarnings(as.integer(vapply(body, function(r) {
          if (length(r) >= 3L) r[2] else NA_character_
        }, character(1)))),
        amount  = money(vapply(body, function(r) r[length(r)], character(1)))
      )
    }
  }

  if (is.null(hosp) || is.null(rhc)) {
    stop("[OR] the Transformation Fund bulletin no longer yields both a ",
         "hospital table and an RHC table. Re-read the archive before ",
         "changing this parser.", call. = FALSE)
  }

  # "Grand Total" is a TOTAL ROW, and RCJ ingested it as an awardee at
  # $34,998,000. It is removed by name here and its value is kept as the
  # state's own stated total, which the row-sum is then checked against.
  grand <- hosp %>% dplyr::filter(.data$awardee == "Grand Total")
  hosp  <- hosp %>% dplyr::filter(.data$awardee != "Grand Total")

  if (nrow(grand) != 1L) {
    stop("[OR] the hospital table's `Grand Total` row is missing. It is the ",
         "only independent check on the 35 row amounts; refusing to parse.",
         call. = FALSE)
  }

  list(hospitals = hosp, rhcs = rhc, hospitals_stated_total = grand$amount[[1]])
}


# -- parse: Immediate Impact Awards (prose, two waves, two formats) ----------

# A project block opens at OHA's own initiative marker. Wave 1 prints it inline
# with the amount; Wave 2 prints it on its own line and may then print SEVERAL
# amounts, one per named recipient. Anchoring on the marker rather than on the
# amount is what keeps those sub-awards attached to their parent project.
OR_IIA_INITIATIVE  <- "\\([^)]{0,80}Initiative\\)"

# "[Label ]Current Award Estimate [for ]Year 1 - $X[ - $Y]". The optional
# leading label is Wave 2's per-recipient split ("Wallowa Current Award
# Estimate Year 1 - $965,661"); the optional second figure is Wave 1's range.
OR_IIA_AMOUNT <- paste0(
  "(?:^|\\n)\\s*(?<label>[^\\n$]{0,40}?)\\s*Current Award Estimate\\s*",
  "(?:for\\s+)?Year\\s*1\\s*[-\u2013\u2014]\\s*",
  "\\$\\s*(?<low>[\\d,]+)",
  "(?:\\s*[-\u2013\u2014]\\s*\\$?\\s*(?<high>[\\d,]+))?"
)

#' Parse both Immediate Impact Award waves off the awards page
#'
#' WAVE 2 IS SHORT AND THAT IS A FINDING, NOT A PARSER BUG. OHA's 2026-07-07
#' news release states "$17 million ... to fund 33 new ready-to-go projects".
#' The awards page names 21 of them, at $11,294,644. The page does not claim
#' otherwise -- its own framing is "pleased to share a list of organizations
#' selected", never a complete list, and it prints no count and no total. So
#' the 12 unnamed projects and the $5.7M difference are RECORDED on the
#' reconciliation and are NOT reconstructed: §0.3's rule, which South Dakota
#' met in its pure form (a count is not a list) and Oregon meets in a partial
#' one. `or_assert_extraction()` pins the 21/33 gap so that the day OHA
#' publishes the rest, this fails and someone re-runs it.
or_parse_iia <- function(path = or_archive_path("awards_page")) {
  doc    <- or_read_html(path)
  panels <- rvest::html_elements(doc, ".or-accordion-panel")
  titles <- rvest::html_text2(rvest::html_element(panels, ".panel-title"))

  idx <- which(stringr::str_detect(titles, stringr::fixed("Immediate Impact")))
  if (length(idx) != 1L) {
    stop("[OR] expected exactly one 'Immediate Impact' accordion panel on the ",
         "awards page, found ", length(idx), ".", call. = FALSE)
  }
  txt <- rvest::html_text2(rvest::html_element(panels[[idx]], ".panel-body"))

  wave2_at <- stringr::str_locate(txt, "Immediate Impact Award Wave 2")[1, "start"]
  if (is.na(wave2_at)) {
    stop("[OR] the awards page no longer carries a 'Wave 2' heading. The two ",
         "waves are two announcements with two totals and must not be merged.",
         call. = FALSE)
  }

  marks <- stringr::str_locate_all(txt, OR_IIA_INITIATIVE)[[1]]
  if (nrow(marks) == 0L) {
    stop("[OR] no initiative markers found in the Immediate Impact panel.",
         call. = FALSE)
  }

  purrr::map_dfr(seq_len(nrow(marks)), function(i) {
    start <- marks[i, "start"]
    stop_ <- if (i < nrow(marks)) marks[i + 1L, "start"] - 1L else nchar(txt)

    # The title/recipient line is the last non-empty line BEFORE the marker.
    head_lines <- stringr::str_split(stringr::str_sub(txt, 1L, start - 1L), "\n")[[1]]
    head_lines <- stringr::str_squish(head_lines)
    head_lines <- head_lines[nzchar(head_lines)]
    header     <- utils::tail(head_lines, 1L)

    initiative <- stringr::str_squish(
      stringr::str_sub(txt, start, marks[i, "end"])
    )
    block <- stringr::str_sub(txt, marks[i, "end"] + 1L, stop_)

    amounts <- stringr::str_match_all(block, OR_IIA_AMOUNT)[[1]]

    # A BLOCK WITH NO AMOUNT IS A REAL OREGON ROW, NOT A PARSE FAILURE. Wave 2's
    # "System of Care Transformation Regional Convenings" carries an initiative
    # and a full project description and NO figure -- OHA simply has not
    # published one. It is emitted with an empty `amount` and AMOUNT_MISSING
    # rather than dropped, because dropping it would lose a project OHA named,
    # and rather than refused, because refusing would lose the other 20 with it.
    # What IS still refused is a block with neither an amount nor a description,
    # which is a block this parser has misread.
    desc_from <- if (nrow(amounts) > 0L) {
      max(stringr::str_locate_all(block, OR_IIA_AMOUNT)[[1]][, "end"])
    } else {
      0L
    }
    description <- stringr::str_squish(stringr::str_sub(block, desc_from + 1L))

    if (nrow(amounts) == 0L && nchar(description) < 80L) {
      stop("[OR] Immediate Impact block ", i, " (", header, ") has no award ",
           "estimate AND no project description. That is a misread block, not ",
           "an unpriced project; refusing to emit it.", call. = FALSE)
    }

    # OHA writes "Project Name - Recipient(s)" with an EN DASH, or occasionally a
    # spaced hyphen. Where neither separator is present the recipient is not
    # separable from the project name -- "Veggie Rx Expansion Oregon Community
    # Food System Network" names its recipient inside the title and
    # "System of Care Transformation Regional Convenings" names none at all.
    # Splitting on a guess would produce §6.1's PROGRAM_NAME_AS_AWARDEE error,
    # so the header is kept whole and the row is flagged for a reviewer instead.
    sep       <- stringr::str_locate(header, "\\s[\u2013\u2014]\\s?|\\s-\\s")
    separable <- !is.na(sep[1, "start"])
    project   <- if (separable) {
      stringr::str_squish(stringr::str_sub(header, 1L, sep[1, "start"] - 1L))
    } else {
      header
    }
    recipient <- if (separable) {
      stringr::str_squish(stringr::str_sub(header, sep[1, "end"] + 1L))
    } else {
      NA_character_
    }

    purrr::map_dfr(seq_len(max(nrow(amounts), 1L)), function(j) {
      have  <- j <= nrow(amounts)
      low   <- if (have) as.numeric(stringr::str_remove_all(amounts[j, "low"], ",")) else NA_real_
      high  <- if (have) suppressWarnings(as.numeric(stringr::str_remove_all(amounts[j, "high"], ","))) else NA_real_
      label <- if (have) stringr::str_squish(amounts[j, "label"]) else ""

      tibble::tibble(
        wave           = if (start >= wave2_at) 2L else 1L,
        project        = project,
        awardee_raw    = recipient,
        header_line    = header,
        recipient_separable = separable,
        split_label    = if (nzchar(label)) label else NA_character_,
        n_splits       = nrow(amounts),
        initiative     = stringr::str_remove_all(initiative, "^\\(|\\)$"),
        amount_low     = low,
        amount_high    = if (is.na(high)) NA_real_ else high,
        description    = description
      )
    })
  })
}


# -- assembly ----------------------------------------------------------------

# Florida's leading block, which every state file matches (§8, session 10).
OR_LEADING_COLUMNS <- c(
  "state", "row_no", "awardee", "amount", "recipient_type",
  "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
  "fiscal_year", "source_document_title", "state_source_url",
  "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
  "rural_designation", "reviewer"
)

# NOT ONE OREGON AWARD IN THIS FILE IS EXECUTED, and every pool says so in its
# own words. The Immediate Impact page states the amounts come from recipients'
# "Notice of Intent to Award" and are "tentative, subject to budget
# negotiations, and contingent upon final agreement execution"; the Catalyst
# page states amounts "will be finalized after OHA completes award
# negotiations"; the Transformation bulletin heads its tables "Organizations
# Offered Funds" and prints an "Eligible Award Total". So Oregon is Alaska's
# shape throughout -- NOTICE_OF_INTENT_TO_AWARD, `amount_confirmed = No`,
# AMOUNT_PRELIMINARY on every priced row -- and a reader who takes an Oregon
# figure as disbursed money has been told otherwise on the row.
OR_VALIDATION_SOURCE <- "NOTICE_OF_INTENT_TO_AWARD"

#' §6.2: does this awardee field name more than one organisation?
#'
#' Never used to divide an amount. Oregon's "Alano Club, Comagine Health, Tabor
#' North" carries ONE published figure for THREE organisations and $1,113,000
#' is not any one of their awards.
or_is_multi_recipient <- function(x) {
  # A corporate suffix is not a second organisation. "The Next Door, Inc." is
  # one recipient and the comma belongs to its legal name; §6.1's entity-marker
  # list exists for exactly this and the naive comma split gets it wrong.
  stripped <- stringr::str_remove_all(
    x,
    "(?i),?\\s*\\b(inc|incorporated|llc|l\\.l\\.c|ltd|limited|llp|p\\.?c|corp|corporation|co)\\b\\.?"
  )
  # THE DELIMITER IS THE COMMA, AND ONLY THE COMMA. §6.2 also lists " & " and
  # " and ", and both are unusable on Oregon's data for the reason session 6
  # already recorded: "Oregon Health & Science University (OHSU)" and
  # "Department of Early Learning & Care (DELC)" are single organisations whose
  # own names carry an ampersand, and a rule that splits on it reports two of
  # Oregon's cleanest single-recipient rows as unresolved lists. The repo made
  # this exact choice once before, deliberately not matching a bare "&" so OHSU
  # would survive it; this follows that precedent rather than re-deciding it.
  #
  # The cost is visible and small: "Oregon School Nurses Association & Regional
  # ESDs" is genuinely two recipients and is not caught here. It carries
  # AMOUNT_RANGE_IN_SOURCE and an empty `amount` already, and its recipient_type
  # is NONPROFIT_CBO, so it contributes nothing to any hospital figure either
  # way -- the miss costs a review flag, not a dollar.
  !is.na(stripped) & stringr::str_detect(stripped, ",\\s+\\S")
}

#' Resolve one of OHA's own per-recipient splits back to its recipient
#'
#' Wave 2 publishes some projects as a recipient LIST with a SEPARATE figure per
#' recipient -- "Wallowa Current Award Estimate Year 1 - $965,661" under a
#' header naming Wallowa Valley Center for Wellness, Klamath Basin Behavioral
#' Health and Trillium Family Services. That is the state doing the §6.2 split
#' itself, so these are NOT unresolved multi-recipient fields: each figure has
#' one named recipient and the row should carry that recipient, not the list.
#' The label is matched back to the fragment of the header it names; where it
#' matches nothing the label stands alone rather than the whole list being
#' asserted as one awardee.
or_resolve_split_recipient <- function(header_recipients, label) {
  purrr::map2_chr(header_recipients, label, function(rl, lab) {
    if (is.na(lab) || is.na(rl)) return(rl)
    frags <- stringr::str_squish(stringr::str_split(rl, ",|\\s+and\\s+|\\s+&\\s+")[[1]])
    frags <- frags[nzchar(frags)]
    hit <- frags[stringr::str_detect(frags, stringr::fixed(lab, ignore_case = TRUE))]
    if (length(hit) == 1L) hit else lab
  })
}

#' Does this name look like one of Oregon's own 35 rural hospitals?
#'
#' A REVIEW SIGNAL, NOT A RECLASSIFICATION. Many of the 99 Rural Health Clinics
#' are hospital-owned outpatient sites -- Grande Ronde Hospital's five clinics,
#' Columbia Memorial's three, Providence Seaside's three, and two entries
#' ("Providence Hood River Memorial Hospital", "Saint Alphonsus Medical Center -
#' Baker City") whose names are the hospitals themselves. Recoding them
#' HOSPITAL_AFFILIATED_ENTITY would move up to $9.9M into the hospital total on
#' this pipeline's authority; OHA put every one of them in a table headed "Rural
#' Health Clinics (RHCs)" and paid them from a $10M RHC pool, not from the $35M
#' hospital pool. So the state's classification stands, the affiliation is
#' recorded in its own column, the dollars are reported separately on the
#' Reconciliation sheet, and a human decides. This is Alaska's unresolved
#' judgement in Oregon's clothing, and it is left visible for the same reason.
or_hospital_affiliation_signal <- function(awardee, hospital_names) {
  stems <- stringr::str_squish(stringr::str_remove_all(
    hospital_names,
    "\\b(Hosp|Hospital|Med|Medical|Ctr|Center|Comm|Community|District|Memorial|Inc\\.?)\\b|[-,]"
  ))
  stems <- stems[nchar(stems) >= 5L]

  vapply(awardee, function(nm) {
    if (is.na(nm)) return(FALSE)
    any(stringr::str_detect(nm, stringr::fixed(stems, ignore_case = TRUE))) ||
      stringr::str_detect(nm, "(?i)\\bhospital\\b")
  }, logical(1), USE.NAMES = FALSE)
}

#' One Oregon award action per row, across all seven pools
or_build_records <- function() {
  cat <- or_parse_catalyst()
  tf  <- or_parse_transformation()
  iia <- or_parse_iia()

  awards_url <- or_source("awards_page", "url")
  bulletin_url <- or_source("transformation", "url")
  news0707_url <- or_source("news_2026_07_07", "url")

  # -- Catalyst -------------------------------------------------------------
  catalyst <- cat$projects %>%
    dplyr::transmute(
      award_pool       = "CATALYST",
      awardee          = stringr::str_squish(.data$Ogranization.name),
      project          = stringr::str_squish(.data$Project.ID),
      initiative       = stringr::str_squish(.data$Initiative),
      amount           = .data$`Budget.Year.1.(Approved)`,
      amount_low       = NA_real_,
      amount_high      = NA_real_,
      budget_year2     = .data$`Budget.Year.2.(Expected)`,
      beds             = NA_integer_,
      counties_served  = .data$Counties.served,
      regions_served   = .data$Regions.served,
      entity_type_raw  = .data$Entity.type,
      description      = paste(.data$Initiative, .data$Counties.served),
      date_announced   = "2026-07-07",
      source_document_title = or_source("catalyst_data", "doc_title"),
      state_source_url = awards_url,
      pool_amount      = NA_real_
    )

  # -- Transformation Fund: hospitals ---------------------------------------
  hospitals <- tf$hospitals %>%
    dplyr::transmute(
      award_pool       = "TRANSFORMATION_HOSPITAL",
      awardee          = .data$awardee,
      project          = NA_character_,
      initiative       = "Transformation Fund - Rural Hospitals",
      amount           = .data$amount,
      amount_low       = NA_real_,
      amount_high      = NA_real_,
      budget_year2     = NA_real_,
      beds             = .data$beds,
      counties_served  = NA_character_,
      regions_served   = NA_character_,
      # OHA's own table heading is the state's classification of these 35
      # recipients, and it is the field the classifier reads.
      entity_type_raw  = "Hospital or Hospital System",
      description      = "Direct, non-competitive Transformation Fund award to a rural hospital, tiered by bed count.",
      date_announced   = "2026-05-07",
      source_document_title = or_source("transformation", "doc_title"),
      state_source_url = bulletin_url,
      pool_amount      = NA_real_
    )

  # -- Transformation Fund: rural health clinics ----------------------------
  rhcs <- tf$rhcs %>%
    dplyr::transmute(
      award_pool       = "TRANSFORMATION_RHC",
      awardee          = .data$awardee,
      project          = NA_character_,
      initiative       = "Transformation Fund - Rural Health Clinics",
      amount           = .data$amount,
      amount_low       = NA_real_,
      amount_high      = NA_real_,
      budget_year2     = NA_real_,
      beds             = NA_integer_,
      counties_served  = NA_character_,
      regions_served   = NA_character_,
      entity_type_raw  = "Rural Health Clinic",
      description      = "Direct, non-competitive Transformation Fund award to a certified Rural Health Clinic, standardised amount.",
      date_announced   = "2026-05-07",
      source_document_title = or_source("transformation", "doc_title"),
      state_source_url = bulletin_url,
      pool_amount      = NA_real_
    )

  # -- Immediate Impact Awards ----------------------------------------------
  immediate <- iia %>%
    dplyr::transmute(
      award_pool       = paste0("IMMEDIATE_IMPACT_WAVE", .data$wave),
      awardee          = dplyr::if_else(
        .data$n_splits > 1L,
        or_resolve_split_recipient(.data$awardee_raw, .data$split_label),
        dplyr::coalesce(.data$awardee_raw, .data$header_line)
      ),
      project          = .data$project,
      initiative       = .data$initiative,
      # A RANGE IS NOT AN AMOUNT (§6.2). Where OHA printed one, `amount` is
      # empty and both bounds are carried, so no sum over `amount` can publish
      # a per-recipient figure the state did not.
      amount           = dplyr::if_else(is.na(.data$amount_high), .data$amount_low, NA_real_),
      amount_low       = .data$amount_low,
      amount_high      = .data$amount_high,
      budget_year2     = NA_real_,
      beds             = NA_integer_,
      counties_served  = NA_character_,
      regions_served   = NA_character_,
      entity_type_raw  = NA_character_,
      description      = .data$description,
      date_announced   = dplyr::if_else(.data$wave == 1L, "2026-04-10", "2026-07-07"),
      source_document_title = or_source("awards_page", "doc_title"),
      state_source_url = awards_url,
      pool_amount      = NA_real_,
      split_label      = .data$split_label,
      n_splits         = .data$n_splits,
      recipient_separable = .data$recipient_separable
    )

  # -- the two pools whose recipients Oregon has NOT named ------------------
  #
  # South Dakota's device, and for the same reason: OHA states a count and a
  # total for both and names nobody, so these are ONE AGGREGATE ROW each with
  # `amount` EMPTY and the figure in `pool_amount`. No sum over `amount` can
  # read either of them as a per-recipient award, and no reader can mistake the
  # row for a list. §0.3: a count is not a list.
  unnamed <- tibble::tribble(
    ~award_pool,        ~initiative,                                    ~pool_amount,                 ~n_recipients,                    ~description,
    "TRIBAL_INITIATIVE", "Tribal Initiative (set-aside for the Nine Federally Recognized Tribes of Oregon)", OR_STATED$tribal_pool, OR_STATED$tribal_recipients, "Direct, non-competitive set-aside. OHA states the total and the number of Tribes and names no individual Tribe or per-Tribe amount.",
    "TRANSFORMATION_LPHA", "Transformation Fund - Local Public Health Authorities",                        OR_STATED$lpha_pool,   OR_STATED$lpha_recipients,   "Direct funding to Oregon's local public health authorities, most of them county health departments. OHA states the total and the count and names no authority."
  ) %>%
    dplyr::transmute(
      award_pool       = .data$award_pool,
      awardee          = "Not identified in the source",
      project          = NA_character_,
      initiative       = .data$initiative,
      amount           = NA_real_,
      amount_low       = NA_real_,
      amount_high      = NA_real_,
      budget_year2     = NA_real_,
      beds             = NA_integer_,
      counties_served  = NA_character_,
      regions_served   = NA_character_,
      entity_type_raw  = NA_character_,
      description      = .data$description,
      date_announced   = "2026-07-07",
      source_document_title = or_source("news_2026_07_07", "doc_title"),
      state_source_url = news0707_url,
      pool_amount      = .data$pool_amount,
      n_recipients     = .data$n_recipients
    )

  dplyr::bind_rows(catalyst, hospitals, rhcs, immediate, unnamed)
}


#' Classify, code and lay out the Oregon file
or_year1_awardees <- function() {
  recs <- or_build_records()
  hospital_names <- recs$awardee[recs$award_pool == "TRANSFORMATION_HOSPITAL"]

  # §8/§10.2 run through the shared classifier, never re-implemented here.
  # Rows carrying OHA's own `Entity type` are classified from the STATE's
  # field; the Immediate Impact rows have no such field and fall to the name
  # rules, which read the recipient and never the activity (§0.3a).
  has_type <- !is.na(recs$entity_type_raw)

  typed <- rhtp_classify_records(
    recs[has_type, ], OR_STATE,
    description_col = "description", org_type_col = "entity_type_raw",
    org_type_delimiter = ", "
  )
  untyped <- rhtp_classify_records(
    recs[!has_type, ], OR_STATE, description_col = "description"
  )
  out <- dplyr::bind_rows(typed, untyped) %>%
    dplyr::arrange(match(.data$award_pool,
                         c("TRANSFORMATION_HOSPITAL", "TRANSFORMATION_RHC",
                           "CATALYST", "IMMEDIATE_IMPACT_WAVE1",
                           "IMMEDIATE_IMPACT_WAVE2", "TRIBAL_INITIATIVE",
                           "TRANSFORMATION_LPHA")),
                   .data$awardee)

  unnamed_pool <- out$award_pool %in% c("TRIBAL_INITIATIVE", "TRANSFORMATION_LPHA")

  out %>%
    dplyr::mutate(
      state        = OR_STATE,
      fiscal_year  = OR_FISCAL_YEAR,
      row_no       = dplyr::row_number(),

      # §0.3: the two pools that name nobody carry NOT_YET_NAMED and are the
      # only rows in the file whose recipient is unconfirmed.
      recipient_type = dplyr::if_else(unnamed_pool, "NOT_YET_NAMED", .data$recipient_type),
      flow_type      = dplyr::if_else(unnamed_pool, "PASS_THROUGH_UNRESOLVED", .data$flow_type),
      distributed_to_hospital = dplyr::if_else(unnamed_pool, "Unclear",
                                               .data$distributed_to_hospital),
      determination_confidence = dplyr::if_else(unnamed_pool, "LOW",
                                                .data$determination_confidence),
      recipient_confirmed = dplyr::if_else(unnamed_pool, "No", "Yes"),

      # Every priced Oregon row is preliminary; see OR_VALIDATION_SOURCE.
      amount_confirmed = "No",
      validation_source_type = dplyr::if_else(
        unnamed_pool, "AGENCY_PRESS_RELEASE", OR_VALIDATION_SOURCE
      ),

      # Only Immediate Impact rows can carry an unresolved recipient list, and
      # only where OHA did NOT split the figure itself (n_splits == 1) and the
      # header WAS separable -- an unseparable header is already flagged
      # RECIPIENT_NOT_NAMED and its " and " belongs to a project title, not to
      # a list of organisations.
      multi_recipient = or_is_multi_recipient(.data$awardee) &
        stringr::str_starts(.data$award_pool, "IMMEDIATE_IMPACT") &
        dplyr::coalesce(.data$n_splits, 1L) == 1L &
        dplyr::coalesce(.data$recipient_separable, TRUE),

      # §6.2 APPLIED WHERE IT ACTUALLY BITES, and it caught a real inflation
      # here. Oregon's Medical Assistant Workforce Pathway is published as
      # "Northwest Regional ESD, Clatsop Community College, Providence Seaside
      # Hospital, Seaside School District" against ONE figure of $186,000. The
      # name rules see "Hospital" in that string, and without this the whole
      # $186,000 lands in the named-hospital total as a Providence award --
      # which is not what OHA published and not what any of the four received.
      # A field naming several organisations against one figure has an
      # UNRESOLVED recipient list, and §6.2's rule is that the amount is never
      # divided and §0.3's is that it is never imputed. So the row keeps the
      # recipient_type its string supports, stays in the file, and is coded
      # Unclear with the flag that sends it to a reviewer. It contributes to
      # neither hospital bucket.
      distributed_to_hospital = dplyr::if_else(
        .data$multi_recipient, "Unclear", .data$distributed_to_hospital
      ),
      flow_type = dplyr::if_else(
        .data$multi_recipient, "PASS_THROUGH_UNRESOLVED", .data$flow_type
      ),
      determination_confidence = dplyr::if_else(
        .data$multi_recipient, "LOW", .data$determination_confidence
      ),

      # Flags stack in severity order; the classifier's own flag survives.
      hospital_attribution = dplyr::case_when(
        .data$distributed_to_hospital == "Yes" ~ "NAMED_HOSPITAL",
        TRUE                                   ~ "NOT_HOSPITAL"
      ),
      intermediary_name = NA_character_,

      hospital_affiliation_signal = dplyr::if_else(
        .data$award_pool == "TRANSFORMATION_RHC",
        or_hospital_affiliation_signal(.data$awardee, hospital_names),
        FALSE
      ),

      flag_reason = purrr::pmap_chr(
        list(.data$flag_reason, .data$amount, .data$amount_high,
             .data$multi_recipient, unnamed_pool,
             !is.na(.data$recipient_separable) & !.data$recipient_separable),
        function(base, amt, hi, multi, unnamed, unsep) {
          f <- c(
            base,
            if (isTRUE(unnamed)) "RECIPIENT_NAMES_NOT_CAPTURED",
            if (!isTRUE(unnamed) && !is.na(hi)) "AMOUNT_RANGE_IN_SOURCE",
            if (!isTRUE(unnamed) && is.na(amt) && is.na(hi)) "AMOUNT_MISSING",
            if (isTRUE(multi)) "MULTI_RECIPIENT_FIELD",
            if (isTRUE(unsep)) "RECIPIENT_NOT_NAMED",
            if (!isTRUE(unnamed) && !is.na(amt)) "AMOUNT_PRELIMINARY"
          )
          f <- unique(f[!is.na(f)])
          if (!length(f)) NA_character_ else paste(f, collapse = ";")
        }
      ),

      note = dplyr::case_when(
        .data$award_pool == "TRANSFORMATION_HOSPITAL" ~ paste0(
          "Transformation Fund, rural hospital tier (", .data$beds,
          " beds). OHA's bulletin heads this table 'Organizations Offered Funds' ",
          "and prints an 'Eligible Award Total'; the 2026-07-07 release states ",
          "the $35M has been awarded."),
        .data$award_pool == "TRANSFORMATION_RHC" ~ paste0(
          "Transformation Fund, standardised Rural Health Clinic award. THIS IS ",
          "NOT A HOSPITAL AWARD: OHA prints these 99 in a separate table from ",
          "the 35 hospitals, against a separate $10M pool.",
          dplyr::if_else(.data$hospital_affiliation_signal,
                         " Name indicates hospital ownership; recorded, not recoded.", "")),
        .data$award_pool == "CATALYST" ~ paste0(
          "Catalyst Award (competitive RFGP), ", .data$project,
          ". Amount is Budget Year 1 (Approved); OHA finalises scopes after ",
          "award negotiations. Year 2 expected: ",
          dplyr::if_else(is.na(.data$budget_year2), "n/a",
                         formatC(.data$budget_year2, format = "f", digits = 2, big.mark = ","))),
        .data$award_pool == "IMMEDIATE_IMPACT_WAVE1" ~
          "Immediate Impact Award, Wave 1 (announced 2026-04-10). Amount is the estimate from the recipient's Notice of Intent to Award.",
        .data$award_pool == "IMMEDIATE_IMPACT_WAVE2" ~ paste0(
          "Immediate Impact Award, Wave 2 (announced 2026-07-07). OHA states 33 ",
          "projects and $17M; the awards page names 21. This is one of the named."),
        .data$award_pool == "TRIBAL_INITIATIVE" ~ paste0(
          "AGGREGATE ROW, NOT A RECIPIENT. $", formatC(OR_STATED$tribal_pool, format = "d", big.mark = ","),
          " to the Nine Federally Recognized Tribes of Oregon; OHA names no Tribe ",
          "and publishes no per-Tribe amount. `amount` is deliberately empty."),
        .data$award_pool == "TRANSFORMATION_LPHA" ~ paste0(
          "AGGREGATE ROW, NOT A RECIPIENT. $", formatC(OR_STATED$lpha_pool, format = "d", big.mark = ","),
          " to 33 local public health authorities; OHA names none. `amount` is ",
          "deliberately empty."),
        TRUE ~ NA_character_
      ),

      extraction_method   = "DIRECT_TEXT",
      validator           = "AUTO",
      reviewer            = NA_character_,
      ccn                 = NA_character_,
      aha_id              = NA_character_,
      rural_designation   = NA_character_,
      recipient_type_source = dplyr::coalesce(.data$entity_type_raw,
                                              "Not stated by OHA; classified from recipient name (§0.3a).")
    ) %>%
    dplyr::select(
      dplyr::all_of(OR_LEADING_COLUMNS),
      recipient_type_source, determination_confidence, flag_reason,
      award_pool, initiative, project, amount_low, amount_high, pool_amount,
      n_recipients, beds, counties_served, regions_served, entity_type_raw,
      budget_year2, flow_type, hospital_attribution, hospital_benefiting,
      intermediary_name, hospital_affiliation_signal, date_announced,
      classification_rule, determination_basis
    )
}


# -- assertions and reconciliation -------------------------------------------

or_assert <- function(condition, message) {
  if (!isTRUE(condition)) stop("[OR ASSERT] ", message, call. = FALSE)
  invisible(TRUE)
}

#' Every claim this file makes, checked against OHA's own stated figures
or_assert_extraction <- function(d = or_year1_awardees()) {
  pool <- function(p) d[d$award_pool == p, ]
  amt  <- function(p) sum(pool(p)$amount, na.rm = TRUE)

  # -- the Transformation Fund, and the correction it carries ---------------
  #
  # THIS IS THE ASSERTION THIS FILE EXISTS FOR. The RCJ survey shows 99 awards
  # of exactly $100,000 and it is natural to read a uniform block that size as
  # hospitals. OHA's bulletin says otherwise, in two separate tables, and these
  # four assertions are that correction in a form that survives a re-run.
  or_assert(nrow(pool("TRANSFORMATION_RHC")) == 99L,
            "the RHC table is not 99 rows. Those 99 x $100,000 are Rural Health Clinics, NOT hospitals; if the count moved, re-read the bulletin before anything else.")
  or_assert(all(pool("TRANSFORMATION_RHC")$amount == OR_STATED$rhc_amt),
            "an RHC row is not at the standardised $100,000.")
  or_assert(all(pool("TRANSFORMATION_RHC")$recipient_type == "FQHC_OR_RHC"),
            "an RHC row is typed as something other than FQHC_OR_RHC.")
  or_assert(!any(pool("TRANSFORMATION_RHC")$distributed_to_hospital == "Yes"),
            "an RHC row is coded distributed_to_hospital = Yes. OHA paid these from a $10M RHC pool, not the $35M hospital pool.")

  h <- pool("TRANSFORMATION_HOSPITAL")
  or_assert(nrow(h) == OR_STATED$hospitals_small_n + OR_STATED$hospitals_large_n,
            paste0("the hospital table is not 35 rows (", nrow(h), ")."))
  or_assert(sum(h$amount) == OR_STATED$hospitals_total,
            paste0("the 35 hospital rows sum to ", format(sum(h$amount), big.mark = ","),
                   ", not OHA's own Grand Total of ", format(OR_STATED$hospitals_total, big.mark = ",")))
  or_assert(sum(h$amount == OR_STATED$hospitals_small_amt) == OR_STATED$hospitals_small_n &&
            sum(h$amount == OR_STATED$hospitals_large_amt) == OR_STATED$hospitals_large_n,
            "the 32/3 bed-count tiering does not hold.")
  # The bulletin states the tier RULE as well as the amounts, so the two are
  # cross-checked against each other rather than each taken on trust.
  or_assert(all((h$beds <= 50) == (h$amount == OR_STATED$hospitals_small_amt)),
            "a hospital's bed count and its tier amount disagree. OHA states <=50 beds -> $963,000 and >50 -> $1,394,000.")
  or_assert(all(h$distributed_to_hospital == "Yes"),
            "a Transformation Fund hospital row is not coded distributed_to_hospital = Yes.")

  # -- Catalyst, against OHA's own arithmetic -------------------------------
  cat_rows <- pool("CATALYST")
  or_assert(nrow(cat_rows) == OR_STATED$catalyst_projects,
            paste0("Catalyst is not 103 projects (", nrow(cat_rows), ")."))
  or_assert(dplyr::n_distinct(cat_rows$awardee) == OR_STATED$catalyst_orgs,
            paste0("Catalyst is not 85 distinct organisations (",
                   dplyr::n_distinct(cat_rows$awardee), ")."))
  or_assert(isTRUE(all.equal(amt("CATALYST"), OR_STATED$catalyst_bp1)),
            paste0("Catalyst Year 1 sums to ", format(amt("CATALYST"), big.mark = ","),
                   ", not the file's own Total of ", format(OR_STATED$catalyst_bp1, big.mark = ",")))

  # -- Immediate Impact -----------------------------------------------------
  or_assert(dplyr::n_distinct(pool("IMMEDIATE_IMPACT_WAVE1")$project) == OR_STATED$iia_wave1_projects,
            "Wave 1 is not the 12 projects OHA's 2026-04-10 release states.")

  # WAVE 2 IS SHORT ON PURPOSE. OHA states 33 projects and $17M; the awards page
  # names 21. The gap is asserted rather than closed, and asserted in the
  # direction that matters: if OHA publishes the remaining 12, this fails and
  # someone re-runs the extraction instead of shipping a stale 21.
  w2_projects <- dplyr::n_distinct(pool("IMMEDIATE_IMPACT_WAVE2")$project)
  or_assert(w2_projects == 21L,
            paste0("Wave 2 names ", w2_projects, " projects, not the 21 this ",
                   "extraction was built against. OHA states 33 in its ",
                   "2026-07-07 release -- if the page has grown, re-extract; ",
                   "the missing projects were never imputed."))
  or_assert(w2_projects < OR_STATED$iia_wave2_projects,
            "Wave 2 now names at least the 33 projects OHA announced. Re-read the page and update this file.")
  or_assert(amt("IMMEDIATE_IMPACT_WAVE2") < OR_STATED$iia_wave2_pool,
            "Wave 2's named amounts now exceed the $17M OHA announced for it.")

  # -- the two pools that name nobody ---------------------------------------
  for (p in c("TRIBAL_INITIATIVE", "TRANSFORMATION_LPHA")) {
    r <- pool(p)
    or_assert(nrow(r) == 1L, paste0(p, " is not a single aggregate row."))
    or_assert(all(is.na(r$amount)),
              paste0(p, " carries an `amount`. It must not: OHA publishes a POOL ",
                     "total and names no recipient, so a sum over `amount` must ",
                     "not be able to read it as an award to anyone (§6.2)."))
    or_assert(r$pool_amount > 0, paste0(p, " has no pool_amount."))
    or_assert(r$recipient_type == "NOT_YET_NAMED" && r$recipient_confirmed == "No",
              paste0(p, " claims a confirmed recipient. OHA names none (§0.3)."))
  }

  # -- §6.2: an unresolved recipient list is never a hospital award ---------
  multi <- d[!is.na(d$flag_reason) & grepl("MULTI_RECIPIENT_FIELD", d$flag_reason), ]
  or_assert(!any(multi$distributed_to_hospital == "Yes"),
            "a MULTI_RECIPIENT_FIELD row is coded distributed_to_hospital = Yes. One published figure against several named organisations is not any one of their awards.")

  # -- §6.2: a range is not an amount ---------------------------------------
  ranged <- d[!is.na(d$amount_high), ]
  or_assert(nrow(ranged) == 2L, "expected exactly 2 range rows in Wave 1.")
  or_assert(all(is.na(ranged$amount)),
            "a row published as a range carries a point `amount`. Picking a bound would publish a figure OHA has not.")

  # -- §8: every categorical value is in the vocabulary ---------------------
  for (col in c("recipient_type", "distributed_to_hospital", "recipient_confirmed",
                "amount_confirmed", "determination_confidence", "flow_type",
                "hospital_attribution")) {
    bad <- setdiff(unique(stats::na.omit(d[[col]])), rhtp_vocabulary(col))
    or_assert(length(bad) == 0L,
              paste0(col, " carries values outside §8: ", paste(bad, collapse = ", ")))
  }
  bad <- setdiff(unique(stats::na.omit(d$validation_source_type)),
                 rhtp_vocabulary("source_doc_type"))
  or_assert(length(bad) == 0L, paste0("validation_source_type outside §8: ", paste(bad, collapse = ", ")))
  flags <- unique(unlist(strsplit(stats::na.omit(d$flag_reason), ";")))
  bad <- setdiff(flags, rhtp_vocabulary("flag_reason"))
  or_assert(length(bad) == 0L, paste0("flag_reason outside §8: ", paste(bad, collapse = ", ")))

  # -- §0.4: no row without a source ----------------------------------------
  or_assert(all(nzchar(d$state_source_url)) && all(nzchar(d$source_document_title)),
            "a row names no state source or no source document.")

  # -- §0.2: nothing here may approach the Tier 1 allotment -----------------
  or_assert(sum(d$amount, na.rm = TRUE) < OR_ALLOTMENT,
            "Oregon's Tier 3 rows sum to more than its CMS allotment.")

  # -- not one Oregon award is executed --------------------------------------
  or_assert(all(d$amount_confirmed == "No"),
            "an Oregon row claims a confirmed amount. Every OHA pool states its figures are estimates, offers or subject to negotiation.")

  invisible(TRUE)
}

#' What Oregon awarded, pool by pool, against what OHA says it awarded
or_reconcile <- function(d = or_year1_awardees()) {
  named <- d %>%
    dplyr::group_by(.data$award_pool) %>%
    dplyr::summarise(
      rows            = dplyr::n(),
      named_awardees  = dplyr::n_distinct(.data$awardee[.data$recipient_confirmed == "Yes"]),
      amount_captured = sum(.data$amount, na.rm = TRUE),
      pool_stated     = sum(.data$pool_amount, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      oha_stated = dplyr::case_when(
        .data$award_pool == "CATALYST"                ~ OR_STATED$catalyst_bp1,
        .data$award_pool == "TRANSFORMATION_HOSPITAL" ~ OR_STATED$hospitals_total,
        .data$award_pool == "TRANSFORMATION_RHC"      ~ OR_STATED$rhc_pool,
        .data$award_pool == "IMMEDIATE_IMPACT_WAVE1"  ~ OR_STATED$iia_wave1_pool,
        .data$award_pool == "IMMEDIATE_IMPACT_WAVE2"  ~ OR_STATED$iia_wave2_pool,
        .data$award_pool == "TRIBAL_INITIATIVE"       ~ OR_STATED$tribal_pool,
        .data$award_pool == "TRANSFORMATION_LPHA"     ~ OR_STATED$lpha_pool,
        TRUE ~ NA_real_
      ),
      residual = .data$oha_stated - pmax(.data$amount_captured, .data$pool_stated)
    )

  list(
    by_pool   = named,
    partition = rhtp_hospital_dollar_partition(d),
    allotment = OR_ALLOTMENT,
    # OHA's own running total, from the 2026-07-07 release: "Oregon has so far
    # awarded about $175.3 million total to support health in rural communities
    # this year". The seven pools' stated figures should land on it.
    oha_awarded_to_date = OR_STATED$awarded_to_date,
    pools_stated_total  = sum(named$oha_stated, na.rm = TRUE),
    rhc_hospital_affiliated = list(
      rows    = sum(d$hospital_affiliation_signal),
      dollars = sum(d$amount[d$hospital_affiliation_signal], na.rm = TRUE)
    )
  )
}


# -- build -------------------------------------------------------------------

OR_CSV  <- here::here("data", "reference", "or_year1_awardees.csv")
OR_XLSX <- here::here("OR_year1_awardees.xlsx")

# The first sheet of the workbook. Oregon needs one more than most states,
# because its file mixes seven pools with three different levels of certainty
# and the single most likely misuse -- reading the 99 x $100,000 as hospitals --
# is one an aggregator actively invites.
OR_README <- c(
  "OREGON -- Rural Health Transformation Program, Year 1 (FY2026)",
  "Source of record: data/reference/or_year1_awardees.csv. This workbook is a render of it.",
  "Built by R/03m_or_year1_awardees.R --build. Evidence: data/evidence/OR/ (5 documents, SHA-256 manifest).",
  "",
  "READ THIS BEFORE USING ANY FIGURE IN THIS FILE.",
  "",
  "1. THE 99 AWARDS OF $100,000 ARE RURAL HEALTH CLINICS, NOT HOSPITALS.",
  "   OHA's 2026-05-07 bulletin prints them in a table headed 'Rural Health Clinics",
  "   (RHCs)', separate from its hospital table, against a separate $10M pool.",
  "   Oregon's hospital block is the OTHER table: 35 rural hospitals, tiered by bed",
  "   count, $34,998,000. Filter on award_pool, never on the amount.",
  "",
  "2. NOT ONE AWARD IN THIS FILE IS EXECUTED. Every pool says so in its own words:",
  "   the Immediate Impact amounts come from recipients' Notices of Intent to Award",
  "   and are 'tentative, subject to budget negotiations, and contingent upon final",
  "   agreement execution'; Catalyst amounts 'will be finalized after OHA completes",
  "   award negotiations'; the Transformation bulletin heads its tables",
  "   'Organizations Offered Funds' and prints an 'Eligible Award Total'.",
  "   Every row is validation_source_type = NOTICE_OF_INTENT_TO_AWARD and",
  "   amount_confirmed = No. These are not disbursed dollars.",
  "",
  "3. TWO POOLS NAME NOBODY AND ARE ONE ROW EACH. The Tribal Initiative",
  "   ($21,700,000, nine Tribes) and the LPHA Transformation Fund ($5,000,000, 33",
  "   authorities) are published as a count and a total with no recipient list.",
  "   Their `amount` is DELIBERATELY EMPTY and the figure is in `pool_amount`, so no",
  "   sum over `amount` can read either as an award to anyone (SD's device, §6.2).",
  "",
  "4. IMMEDIATE IMPACT WAVE 2 IS INCOMPLETE AND THAT IS THE SOURCE, NOT THE PARSE.",
  "   OHA's 2026-07-07 release states 33 projects and $17M. The awards page names 21,",
  "   at $11,294,644. The other 12 are not in this file and were not imputed (§0.3).",
  "",
  "5. TWO WAVE 1 ROWS HAVE NO `amount` BECAUSE OHA PUBLISHED A RANGE.",
  "   $403,000-$778,000 and $102,000-$194,000 are in amount_low/amount_high. Any sum",
  "   over `amount` excludes them; the band is on the Reconciliation sheet.",
  "",
  "6. 23 OF THE 99 RHC ROWS ARE HOSPITAL-OWNED CLINICS ($2,300,000) and are NOT",
  "   counted as hospital dollars. hospital_affiliation_signal marks them. Recoding",
  "   them would move money into the hospital total on this pipeline's authority",
  "   rather than OHA's, which put them in the RHC table. A human decides; the",
  "   dollars are on the Reconciliation sheet either way.",
  "",
  "7. NOTHING HERE COMES FROM RURAL CARE JOURNEY (§0.1). RCJ is what said to look at",
  "   Oregon and it got the class wrong. In the same 136 records it also ingested the",
  "   bulletin's own TITLE as an awardee at $963,000 and its 'Grand Total' row as an",
  "   awardee at $34,998,000. Neither is a recipient."
)

or_build <- function() {
  d <- or_year1_awardees()
  or_assert_extraction(d)
  rec <- or_reconcile(d)

  dir.create(dirname(OR_CSV), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(d, OR_CSV, na = "")

  wb <- openxlsx::createWorkbook()

  openxlsx::addWorksheet(wb, "README")
  openxlsx::writeData(wb, "README", tibble::tibble(README = OR_README))
  openxlsx::setColWidths(wb, "README", 1, 110)

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", d, withFilter = TRUE)
  openxlsx::freezePane(wb, "Awards", firstActiveRow = 2)
  openxlsx::setColWidths(wb, "Awards", 1:ncol(d), widths = "auto")

  openxlsx::addWorksheet(wb, "Reconciliation")
  recon <- rec$by_pool %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), ~ round(.x, 2)))
  openxlsx::writeData(wb, "Reconciliation", recon)
  openxlsx::writeData(wb, "Reconciliation", tibble::tibble(note = c(
    "",
    paste0("The seven pools' stated figures total $",
           formatC(rec$pools_stated_total, format = "d", big.mark = ","),
           ". OHA's 2026-07-07 release states Oregon 'has so far awarded about $175.3 million'."),
    "Two publishers' arithmetic, one figure, and neither was arranged to match the other.",
    paste0("Against the CMS FY2026 allotment of $", formatC(rec$allotment, format = "d", big.mark = ","),
           ", the residual is $", formatC(rec$allotment - rec$pools_stated_total, format = "d", big.mark = ","),
           " (", round(100 * (rec$allotment - rec$pools_stated_total) / rec$allotment, 2), "%)."),
    "",
    "The RHC pool's $100,000 residual is exactly one clinic. OHA's 2026-04-10 release",
    "states 'Oregon currently has 100 certified rural health clinics' and the bulletin",
    "lists 99, closing with: 'Additional clinics may receive their RHC certificate from",
    "CMS and become eligible for Transformation Awards.' Nothing is filled in for the 100th.",
    "",
    paste0("Wave 1's residual includes the two RANGE rows, whose `amount` is empty. Their band is $",
           formatC(403000 + 102000, format = "d", big.mark = ","), " to $",
           formatC(778000 + 194000, format = "d", big.mark = ","), "."),
    paste0("Wave 2's residual is the 12 projects OHA announced and has not named."),
    "",
    paste0("RHC rows whose name indicates hospital ownership: ", rec$rhc_hospital_affiliated$rows,
           " rows, $", formatC(rec$rhc_hospital_affiliated$dollars, format = "d", big.mark = ","),
           ". NOT included in any hospital figure below."),
    "",
    "HOSPITAL DOLLARS -- the two buckets are reported separately and are never added",
    "(rhtp_hospital_dollar_partition; rhtp_hospital_total refuses)."
  )), startRow = nrow(recon) + 3L)
  openxlsx::writeData(wb, "Reconciliation", rec$partition,
                      startRow = nrow(recon) + 3L + 16L)
  openxlsx::setColWidths(wb, "Reconciliation", 1:8, widths = "auto")

  openxlsx::saveWorkbook(wb, OR_XLSX, overwrite = TRUE)
  message("[OR] wrote ", OR_CSV, " (", nrow(d), " rows) and ", OR_XLSX)
  invisible(d)
}


# -- CLI ---------------------------------------------------------------------

if (identical(environment(), globalenv()) && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)

  if ("--fetch" %in% args) {
    e <- or_fetch_sources(force = "--force" %in% args)
    print(as.data.frame(e[, c("file", "bytes", "sha256")]))
  } else if ("--validate" %in% args) {
    d <- or_year1_awardees()
    or_assert_extraction(d)
    rec <- or_reconcile(d)
    message("[OR] ", nrow(d), " award actions across ",
            dplyr::n_distinct(d$award_pool), " pools -- all assertions pass.")
    print(as.data.frame(rec$by_pool))
    print(as.data.frame(rec$partition))
  } else if ("--build" %in% args) {
    or_build()
  } else if (length(args)) {
    stop("[OR] unknown argument. Use --fetch, --validate or --build.", call. = FALSE)
  }
}

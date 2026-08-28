# 00_cms_press_monitor.R ----------------------------------------------------
# The CMS trigger list -> data/reference/cms_state_announcements.csv.
#
# THE CHEAPEST SIGNAL IN THE PROJECT. CMS announces each state's RHTP awards,
# and a state appearing here is the cue to go and collect that state's primary
# sources. It runs on the twice-weekly cadence alongside the RCJ pull (config
# pull$cadence) and costs zero RCJ quota -- it never touches the RCJ API.
#
# It is stage 00 because it runs BEFORE retrieval and decides what is worth
# retrieving. Nothing downstream depends on it, so a failure here delays a
# collection pass; it never corrupts a figure.
#
# TWO SOURCES, AND WHICH ONE LEADS.
#
#   PRIMARY   www.cms.gov/newsroom, filtered to the rural health topic
#   SECONDARY www.medicaid.gov/resources-for-states/rural-health/rhtp-resources
#
# It was medicaid.gov alone until Session 14, and that was wrong in a way that
# cost a state. Session 13 noticed CMS's own newsroom naming a Virginia
# announcement -- 2026-08-28, $122M -- that the medicaid.gov resources page did
# not list. It was not a parse error: the page genuinely did not carry it. A
# monitor reading only that page reported EIGHT announced states when there
# were nine, and reported it confidently, because nothing in a lagging source
# looks like a gap. A trigger list that lags is a trigger list that misses
# states, and a missed state is a state nobody collects.
#
# So the newsroom leads and medicaid.gov is kept rather than dropped: the two
# are UNIONED, `source` is recorded per row, and the run reports which states
# only one list knows about. Keeping the secondary costs almost nothing and
# guards the symmetric failure -- the newsroom lagging on something
# medicaid.gov carries. Neither source may silently shrink the other.
#
# THE TOPIC FILTER IS READ FROM THE DOCUMENT, NOT FROM A URL. CMS's own topic
# facet is /newsroom/search?about[]=<term id>, and Akamai answers 403 to that
# path for any non-browser client -- with no query string at all, so it is the
# PATH that is refused and no user agent fixes it (the +url form that gets us
# through medicaid.gov is refused here too). CMS still publishes the topic, in
# each release's schema.org NewsArticle JSON-LD `about` field. That is the same
# taxonomy the blocked facet indexes; we read it from the document instead of
# from a query, so the filter is CMS's own classification either way.
#
# AND THE TOPIC, NEVER THE TITLE. A title keyword filter looks like it would
# work and does not. Virginia's release is titled "...Expand Healthcare Access,
# Workforce and Innovation Across Virginia" -- no "rural", no "RHTP". SIX of
# the nine state announcements live on 2026-08-28 (AK, AL, ND, SD, VA, WV)
# carry no "rural" in the title, so a title filter keeps three of nine and
# misses the very state that prompted this rewrite.
#
# WHAT IT IS NOT. This is a discovery layer, exactly as RCJ is (§0.1), and the
# same rule applies: no figure from either source may appear in an AHA-published
# number. CMS's summary of a state announcement is not the state's notice of
# award. `amount` is captured so a collection pass can be prioritised and so a
# state figure that later disagrees is caught early -- never so it can be
# totalled. rhtp_cms_press_assert() hard-fails if the amounts are summed into
# anything resembling a national total, because that number would be a mix of
# state allotments and subaward announcements: §0.2's three-tier rule, in the
# one place where the tiers are easiest to blend by accident. Virginia's own
# release is the worked example -- $122M in its headline, $189M in a quoted
# statement, and those are Tier 3 and Tier 1 of the same programme.
#
# PARSING, AND WHY IT REFUSES SO MUCH. Both parsers resolve structure rather
# than assuming it, the same approach R/03b_budget_narratives.R takes to fifty
# differently-formatted state workbooks, and both REFUSE rather than guess: on
# a tie between candidate tables, on unresolvable columns, on a state outside
# the §7.1 fifty, on a headline naming two states, on a zero-row parse, and on
# a listing crawl that hits its page ceiling without reaching the floor date.
# A page redesign fails loudly instead of writing an empty or short CSV, which
# is the §5.2 silent short-read failure mode in a different costume.
#
# WHAT THE LIVE MEDICAID.GOV PAGE TAUGHT US (Session 10, still true). It is a
# table, but its header row is marked up with <td> rather than <th>.
# html_table() therefore named the columns X1..X5, every synonym lookup missed,
# the table scored 0, and the parser fell through to the link-list shape --
# which did not fail, it succeeded with less: no dates at all, and the state
# read by matching a state name in the headline instead of from the page's own
# State column. cms_press_promote_header() promotes such a row, and only when
# doing so resolves strictly more columns, so it can never make a working parse
# worse. That failure mode is worth remembering: most of the refusals here
# guard against parsing the WRONG thing, and this was the other kind -- parsing
# the right thing less well, silently.
#
# Once the table shape was reachable it surfaced two rows the link-list shape
# had been dropping by luck: CMS lists its national announcements (the $50bn
# programme launch, the all-50-states award) in the same table with State =
# "All". They are Tier 1 (§0.2) and this is the STATE trigger list, so they are
# excluded deliberately and the count is reported. The newsroom needs the same
# exclusion for the same reason, and gets it: a rural-topic release naming no
# state is a programme announcement, not a state one.
#
# EGRESS. www.cms.gov and www.medicaid.gov are both allowlisted. Akamai fronts
# both and returns 403 to a user agent carrying no contact URL -- including to
# a spoofed browser UA -- so config api$user_agent uses the +url form, which is
# the well-behaved-crawler convention and what gets through. Identifying
# honestly is the fix here. The one thing that stays refused whatever the UA is
# /newsroom/search, which is why the topic is read from the JSON-LD.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here().
#
# CLI:
#   Rscript R/00_cms_press_monitor.R --run            # both sources, union, write
#   Rscript R/00_cms_press_monitor.R --run --force    # re-fetch, re-learn topics
#   Rscript R/00_cms_press_monitor.R --run --dev      # log the run as DEV (§5.2)
#   Rscript R/00_cms_press_monitor.R --run --newsroom # the primary alone
#   Rscript R/00_cms_press_monitor.R --run --medicaid # the secondary alone
#   Rscript R/00_cms_press_monitor.R --parse          # re-parse archives, no network
#   Rscript R/00_cms_press_monitor.R --status         # what the trigger list says

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
  library(jsonlite)
})

source(here::here("R", "utils_config.R"))

# Source, archive name and outputs all live in config/config.yml, so moving any
# of them is a config change rather than a code change (CLAUDE.md §4).
CMS_PRESS_URL <- rhtp_config()$cms$press_monitor_url
CMS_PRESS_BASE_URL <- rhtp_config()$cms$press_monitor_base_url
CMS_PRESS_ARCHIVE_FILE <- rhtp_config()$cms$press_monitor_archive_file
CMS_PRESS_CSV <- rhtp_config()$paths$cms_state_announcements
CMS_PRESS_MANIFEST <- rhtp_config()$paths$cms_press_manifest

# Column synonyms. Matched case-insensitively against a normalized header, so a
# CMS rewording ("Award Amount" -> "Amount Awarded") does not need a code change.
cms_press_synonyms <- list(
  state  = c("state", "states", "state or territory", "state/territory",
             "awardee state", "recipient state", "jurisdiction"),
  date   = c("date", "announcement date", "date announced", "release date",
             "published", "date of announcement", "posted"),
  amount = c("amount", "award amount", "amount awarded", "award", "funding",
             "funding amount", "total award", "allotment", "award total"),
  title  = c("title", "announcement", "press release", "release", "headline",
             "name", "description", "resource", "document")
)


# -- Archive ----------------------------------------------------------------

#' Where the fetched CMS RHTP resources page is archived
#'
#' Under data/raw/cms/<fetch_date>/ and therefore committed (§0.5), so every
#' parse is reproducible offline against the bytes CMS served.
rhtp_cms_press_archive_path <- function(fetch_date = Sys.Date()) {
  here::here(rhtp_config()$paths$raw_cms, as.character(fetch_date),
             CMS_PRESS_ARCHIVE_FILE)
}


#' The newest archived copy of the page, or NULL
rhtp_cms_press_newest_archive <- function() {
  root <- here::here(rhtp_config()$paths$raw_cms)
  if (!dir.exists(root)) return(NULL)

  hits <- list.files(root, pattern = paste0("^", CMS_PRESS_ARCHIVE_FILE, "$"),
                     recursive = TRUE, full.names = TRUE)
  if (!length(hits)) return(NULL)

  hits[order(basename(dirname(hits)), decreasing = TRUE)][1]
}


#' Fetch and archive the CMS RHTP resources page
#'
#' @param force Re-fetch even when an archive for this date exists.
#' @return The archive path, invisibly.
rhtp_fetch_cms_press <- function(fetch_date = Sys.Date(), force = FALSE) {
  cfg <- rhtp_config()
  path <- rhtp_cms_press_archive_path(fetch_date)

  if (file.exists(path) && !force) {
    message("  CMS RHTP resources page already archived at ", path,
            " -- pass --force to re-fetch.")
    return(invisible(path))
  }

  resp <- tryCatch(
    httr2::request(CMS_PRESS_URL) %>%
      httr2::req_user_agent(cfg$api$user_agent) %>%
      httr2::req_timeout(cfg$api$timeout_seconds) %>%
      httr2::req_retry(max_tries = 3, backoff = ~ 2^.x) %>%
      httr2::req_perform(),
    error = function(e) {
      stop(
        "Could not reach ", CMS_PRESS_URL, ".\n",
        "  ", conditionMessage(e), "\n\n",
        "www.medicaid.gov is allowlisted and this has worked since\n",
        "2026-08-28, so a 403 here most likely means the user agent lost its\n",
        "contact URL (config api$user_agent): Akamai fronts that host and\n",
        "refuses a UA without one -- a spoofed browser UA is refused too.\n",
        "Nothing is written until the fetch succeeds: an empty CSV would\n",
        "read as 'no state has announced an award', which is the opposite\n",
        "of the truth.",
        call. = FALSE
      )
    }
  )

  status <- httr2::resp_status(resp)
  if (status != 200) {
    stop("CMS RHTP resources page returned HTTP ", status,
         "; refusing to archive a non-200 body.", call. = FALSE)
  }

  body <- httr2::resp_body_string(resp)
  body_sha256 <- digest::digest(body, algo = "sha256", serialize = FALSE)

  # Parse before writing, so a page redesign fails before it can overwrite a
  # good archive with an unparseable one.
  parsed <- rhtp_parse_cms_press_html(body)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(body, path, useBytes = TRUE)

  writeLines(
    paste0(
      "RHTP tracker archive: the CMS RHTP resources page (the trigger list).\n\n",
      "source_url  : ", CMS_PRESS_URL, "\n",
      "fetched_utc : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
      "http_status : ", status, "\n",
      "bytes       : ", nchar(body, type = "bytes"), "\n",
      "sha256      : ", body_sha256, "\n",
      "rows_parsed : ", nrow(parsed), "\n",
      "shape       : ", attr(parsed, "cms_press_shape"), "\n\n",
      "This is a DISCOVERY source (§0.1). No figure on this page may enter an\n",
      "AHA-published number; it says which states to go and collect, and the\n",
      "state's own notice of award remains the record for every figure.\n"
    ),
    paste0(path, ".manifest.txt")
  )

  message("  archived the CMS RHTP resources page to ", path,
          " (", nchar(body, type = "bytes"), " bytes, sha256 ",
          substr(body_sha256, 1, 12), "...)")
  invisible(path)
}


# -- Parse ------------------------------------------------------------------

#' Normalize a header cell for synonym matching
cms_press_norm_header <- function(x) {
  x %>%
    stringr::str_replace_all("\\s+", " ") %>%
    stringr::str_remove_all("[^A-Za-z /]") %>%
    stringr::str_trim() %>%
    stringr::str_to_lower()
}


#' Resolve a table's columns against the synonym list
#'
#' @return A named list of column indices, one per resolved field. `state` is
#'   required; the rest are optional and come back NA when absent.
cms_press_resolve_columns <- function(headers) {
  norm <- cms_press_norm_header(headers)

  purrr::imap(cms_press_synonyms, function(syns, field) {
    hit <- which(norm %in% syns)
    if (length(hit) >= 1) return(hit[1])
    # Fall back to a containment match, which catches "State Name" and
    # "Announcement Title" without opening the door to arbitrary text.
    hit <- which(purrr::map_lgl(norm, function(h) {
      nzchar(h) && any(stringr::str_detect(h, stringr::fixed(syns)))
    }))
    if (length(hit) == 1) hit[1] else NA_integer_
  })
}


#' Score a candidate table: how many fields resolve, `state` being mandatory
# A header row marked up with <td> instead of <th>. html_table() then names the
# columns X1..Xn and every synonym lookup misses, so a page that IS a table
# scores 0 and the parser falls through to the link-list shape. That fallback
# does not fail loudly -- it succeeds with less: no dates at all, and the state
# read by matching a state name in the press-release title rather than from the
# page's own State column. The live medicaid.gov page is exactly this shape.
#
# Promotion is accepted only when it resolves strictly MORE columns than the
# positional names did, so it can only ever improve a parse.
# CMS states the figure in the headline, not in a column -- "Trump
# Administration Announces $93.3 Million to ...". The link-list shape always
# mined it from the title; the table shape now does the same when the table
# carries no amount column, so promoting the header does not cost the figure.
# It is a DISCOVERY value either way and is never summed (§0.1, §0.2).
CMS_PRESS_AMOUNT_PATTERN <- "\\$[0-9][0-9,\\.]*\\s*(million|billion|M|B)?"

cms_press_promote_header <- function(tbl) {
  if (!is.data.frame(tbl) || nrow(tbl) < 2 || ncol(tbl) == 0) return(tbl)
  if (!all(stringr::str_detect(names(tbl), "^X\\d+$"))) return(tbl)

  hdr <- as.character(unlist(tbl[1, ], use.names = FALSE))
  if (any(is.na(hdr)) || !all(nzchar(stringr::str_trim(hdr)))) return(tbl)
  if (dplyr::n_distinct(hdr) != length(hdr)) return(tbl)

  promoted <- tbl[-1, , drop = FALSE]
  names(promoted) <- stringr::str_squish(hdr)

  resolved <- function(x) sum(!is.na(unlist(cms_press_resolve_columns(names(x)))))
  if (resolved(promoted) > resolved(tbl)) promoted else tbl
}

cms_press_score_table <- function(tbl) {
  if (!is.data.frame(tbl) || nrow(tbl) == 0 || ncol(tbl) == 0) return(-1L)
  cols <- cms_press_resolve_columns(names(tbl))
  if (is.na(cols$state)) return(-1L)
  sum(!is.na(unlist(cols)))
}


#' Parse a currency string to a number
#'
#' Handles "$1,234,567", "$100 million", "$1.2 billion" and "N/A". Returns NA
#' rather than 0 for anything unrecognised: a zero would be a claim.
cms_press_parse_amount <- function(x) {
  raw <- stringr::str_trim(as.character(x))
  out <- rep(NA_real_, length(raw))

  num <- raw %>%
    stringr::str_extract("[0-9][0-9,]*\\.?[0-9]*") %>%
    stringr::str_remove_all(",") %>%
    as.numeric()

  scale <- dplyr::case_when(
    stringr::str_detect(raw, stringr::regex("billion|\\bB\\b", ignore_case = TRUE)) ~ 1e9,
    stringr::str_detect(raw, stringr::regex("million|\\bM\\b", ignore_case = TRUE)) ~ 1e6,
    TRUE ~ 1
  )

  ok <- !is.na(num)
  out[ok] <- num[ok] * scale[ok]
  out
}


#' Parse a date string in the formats a CMS page plausibly uses
cms_press_parse_date <- function(x) {
  raw <- stringr::str_trim(as.character(x))
  fmts <- c("%Y-%m-%d", "%m-%d-%Y", "%m/%d/%Y", "%m-%d-%y", "%m/%d/%y",
            "%B %d, %Y", "%b %d, %Y", "%d %B %Y", "%B %Y", "%b %Y")

  out <- as.Date(rep(NA_character_, length(raw)))
  for (f in fmts) {
    todo <- is.na(out) & !is.na(raw) & nzchar(raw)
    if (!any(todo)) break
    out[todo] <- suppressWarnings(as.Date(raw[todo], format = f))
  }
  out
}


#' Map a state name or code to the §7.1 two-letter code
#'
#' Refuses rather than guesses: an unmappable value stops the parse, because a
#' silently dropped state is a state nobody collects.
cms_press_state_code <- function(x) {
  states <- rhtp_cms_states()
  key <- stringr::str_trim(as.character(x))

  by_code <- match(stringr::str_to_upper(key), states$state)
  by_name <- match(stringr::str_to_lower(key), stringr::str_to_lower(states$state_name))
  idx <- dplyr::coalesce(by_code, by_name)

  if (any(is.na(idx))) {
    bad <- unique(key[is.na(idx)])
    stop(
      "Could not map to a §7.1 state: ", paste(sQuote(bad), collapse = ", "), ".\n",
      "The parse is stopped rather than dropping the row. If CMS has added a ",
      "territory, decide deliberately whether this project tracks it -- ",
      "data/reference/cms_states.csv is fifty states by construction.",
      call. = FALSE
    )
  }

  states$state[idx]
}


#' Parse the resources page HTML into the announcement table
#'
#' Tries the tabular shape first and falls back to a link list. Refuses on
#' ambiguity: two tables tying on score is a page this parser does not
#' understand, and guessing would be worse than stopping.
#'
#' @param html A single string of HTML.
#' @return A tibble of state, date, amount, title, url. The shape it matched is
#'   attached as attribute `cms_press_shape`.
rhtp_parse_cms_press_html <- function(html) {
  doc <- xml2::read_html(html)

  # --- shape A: an HTML table -----------------------------------------------
  nodes <- rvest::html_elements(doc, "table")
  if (length(nodes)) {
    tables <- suppressWarnings(purrr::map(nodes, rvest::html_table)) %>%
      purrr::map(cms_press_promote_header)
    scores <- purrr::map_int(tables, cms_press_score_table)

    if (max(scores) > 0) {
      best <- which(scores == max(scores))
      if (length(best) > 1) {
        stop(
          length(best), " tables on the CMS resources page score equally (",
          max(scores), " resolved columns). This parser cannot tell which is ",
          "the announcement table.\n",
          "Read the archived page and pin the right one rather than letting ",
          "it pick by position -- position is exactly what a redesign changes.",
          call. = FALSE
        )
      }

      tbl <- tables[[best]]
      cols <- cms_press_resolve_columns(names(tbl))

      pluck_col <- function(field) {
        if (is.na(cols[[field]])) return(rep(NA_character_, nrow(tbl)))
        as.character(tbl[[cols[[field]]]])
      }

      # Links live in the markup, not in the text html_table() returns, so they
      # are read off the same table node by row.
      urls <- nodes[[best]] %>%
        rvest::html_elements("tr") %>%
        purrr::map_chr(function(tr) {
          href <- tr %>% rvest::html_elements("a") %>% rvest::html_attr("href")
          if (!length(href)) NA_character_ else href[1]
        })
      urls <- utils::tail(urls, nrow(tbl))
      if (length(urls) != nrow(tbl)) urls <- rep(NA_character_, nrow(tbl))

      title <- pluck_col("title")
      out <- tibble::tibble(
        state_raw = pluck_col("state"),
        date_raw  = pluck_col("date"),
        amount_raw = if (is.na(cols[["amount"]])) {
          stringr::str_extract(title, CMS_PRESS_AMOUNT_PATTERN)
        } else {
          pluck_col("amount")
        },
        title = title,
        url = urls
      ) %>%
        dplyr::filter(!is.na(.data$state_raw), nzchar(stringr::str_trim(.data$state_raw)))

      return(cms_press_finalize(out, shape = "TABLE"))
    }
  }

  # --- shape B: a list of links, one per announcement ------------------------
  # Used when CMS publishes the page as headed link lists rather than a table.
  states <- rhtp_cms_states()
  anchors <- rvest::html_elements(doc, "a")
  atext <- anchors %>% rvest::html_text2() %>% stringr::str_squish()
  ahref <- anchors %>% rvest::html_attr("href")

  name_pat <- paste0("\\b(", paste(states$state_name, collapse = "|"), ")\\b")
  keep <- !is.na(atext) & nzchar(atext) & stringr::str_detect(atext, name_pat)

  if (!any(keep)) {
    stop(
      "No announcement table and no state-named links found on the CMS ",
      "resources page.\n",
      "Either the page changed shape or the fetch returned a shell. The ",
      "archived copy under data/raw/cms/ is what to read; nothing was written.",
      call. = FALSE
    )
  }

  out <- tibble::tibble(
    title = atext[keep],
    url = ahref[keep]
  ) %>%
    dplyr::mutate(
      state_raw = stringr::str_extract(.data$title, name_pat),
      date_raw = stringr::str_extract(
        .data$title,
        "[A-Z][a-z]+ \\d{1,2}, \\d{4}|\\d{4}-\\d{2}-\\d{2}|\\d{1,2}/\\d{1,2}/\\d{2,4}"
      ),
      amount_raw = stringr::str_extract(
        .data$title, CMS_PRESS_AMOUNT_PATTERN
      )
    ) %>%
    dplyr::distinct(.data$state_raw, .data$title, .keep_all = TRUE)

  cms_press_finalize(out, shape = "LINK_LIST")
}


#' Common tail of both shapes: type, normalize, order, attach provenance
# CMS lists its two national announcements -- the $50 billion programme launch
# and the all-50-states award announcement -- in the same table as the state
# ones, with the State cell reading "All". They are not state announcements and
# they are not Tier 3: they are the CMS->states programme itself (§0.2 Tier 1),
# and this file is the STATE trigger list. They are dropped here deliberately
# and the count is reported, rather than being left to fail the §7.1 state
# mapping (which is what a genuinely unmappable value must still do) or to
# vanish silently, which is what the link-list shape did by accident because
# their titles happen to name no single state.
CMS_PRESS_NATIONAL_MARKERS <- c(
  "all", "all states", "all 50 states", "all fifty states", "national",
  "nationwide", "multiple", "multiple states", "n/a", "-"
)

cms_press_is_national <- function(x) {
  stringr::str_squish(stringr::str_to_lower(as.character(x))) %in%
    CMS_PRESS_NATIONAL_MARKERS
}

cms_press_finalize <- function(out, shape) {
  national <- cms_press_is_national(out$state_raw)
  if (any(national)) {
    message("  excluded ", sum(national), " national (non-state) announcement(s): ",
            paste(unique(stringr::str_squish(out$state_raw[national])), collapse = ", "),
            " -- Tier 1 programme announcements, not state award announcements")
    out <- out[!national, , drop = FALSE]
  }

  out <- out %>%
    dplyr::mutate(
      state = cms_press_state_code(.data$state_raw),
      date = cms_press_parse_date(.data$date_raw),
      amount = cms_press_parse_amount(.data$amount_raw),
      title = stringr::str_squish(dplyr::coalesce(.data$title, NA_character_)),
      url = dplyr::if_else(
        !is.na(.data$url) & stringr::str_starts(.data$url, "/"),
        paste0(CMS_PRESS_BASE_URL, .data$url),
        .data$url
      ),
      source_url = CMS_PRESS_URL,
      first_seen = as.character(Sys.Date())
    ) %>%
    dplyr::select("state", "date", "amount", "title", "url",
                  "source_url", "first_seen") %>%
    dplyr::arrange(.data$state, .data$date)

  attr(out, "cms_press_shape") <- shape
  out
}


#' Parse an archived copy off disk
rhtp_parse_cms_press <- function(path = rhtp_cms_press_newest_archive()) {
  if (is.null(path) || !file.exists(path)) {
    stop("No archived CMS RHTP resources page on disk. Run --run first ",
         "(and see the egress note at the top of this file).", call. = FALSE)
  }
  message("  parsing ", path)
  rhtp_parse_cms_press_html(paste(readLines(path, warn = FALSE), collapse = "\n"))
}


# ===========================================================================
# PRIMARY SOURCE: the cms.gov newsroom, filtered to the rural health topic
# ===========================================================================
#
# WHY THIS IS NOW PRIMARY. Session 13 caught the medicaid.gov resources page
# lagging: CMS announced $122M for Virginia on 2026-08-28 and the resources
# page did not list it, so a monitor reading only that page would have reported
# eight announced states when there were nine. A trigger list that lags is a
# trigger list that misses states. The newsroom publishes the announcement the
# day it is made, so it leads; medicaid.gov is kept as a secondary and the two
# are unioned, because a source that lags today may carry something the other
# drops tomorrow, and neither may silently shrink the other.
#
# THE TOPIC FILTER IS READ FROM THE DOCUMENT, NOT FROM A URL. CMS's own topic
# facet is /newsroom/search?about[]=<term id>, and Akamai answers 403 to that
# path for any non-browser client -- with no query string at all, so it is the
# PATH that is refused and no user agent or header fixes it (the +url form that
# gets us through medicaid.gov is refused here too). CMS still publishes the
# topic, in each release's schema.org NewsArticle JSON-LD as `about`. That is
# the same taxonomy the blocked facet indexes; we read it from the document
# rather than from a query. The filter is CMS's classification either way.
#
# AND THE TOPIC, NEVER THE TITLE. A title keyword filter looks like it would
# work and does not. Virginia's release is titled "...Expand Healthcare Access,
# Workforce and Innovation Across Virginia" -- no "rural", no "RHTP". Of the
# nine state announcements live on 2026-08-28, FOUR carry no "rural" in the
# title (VA, AK, AL, SD). Filtering on the title would have missed the very
# state that prompted this rewrite. The topic tag catches all nine.
#
# COST. Rurality lives on the release, not on the listing, so an item's topic
# costs one fetch to learn. It is learned once: every item ever seen is
# recorded in the committed topic index (paths$cms_newsroom_index), and an
# indexed item is never re-fetched. The backfill is ~130 fetches; a run after
# it costs one listing page plus whatever CMS published since. Zero RCJ quota
# either way -- this endpoint is not the RCJ API.

NEWSROOM_LISTING_URL <- rhtp_config()$cms$newsroom_listing_url
NEWSROOM_BASE_URL <- rhtp_config()$cms$newsroom_base_url
NEWSROOM_TOPIC <- rhtp_config()$cms$newsroom_topic
NEWSROOM_FLOOR_DATE <- as.Date(rhtp_config()$cms$newsroom_floor_date)
NEWSROOM_MAX_PAGES <- rhtp_config()$cms$newsroom_max_pages


#' A slug that identifies a newsroom item on disk
#'
#' The last path segment of the release URL. Stable across runs, so the archive
#' and the topic index agree without a hash to keep in step.
cms_newsroom_slug <- function(url) {
  url %>%
    stringr::str_remove("[?#].*$") %>%
    stringr::str_remove("/$") %>%
    basename() %>%
    stringr::str_replace_all("[^A-Za-z0-9._-]", "_")
}


#' Parse one newsroom listing page into its items
#'
#' The listing carries date, type and title but NOT the topic, which is why an
#' item's rurality costs a fetch. Refuses an empty parse: CMS's newsroom is
#' never empty, so zero rows means the markup moved, and a monitor that reads
#' a redesign as "nothing published" is the §5.2 silent short read.
#'
#' @return A tibble of item_date, item_type, title, url (relative as served).
rhtp_parse_newsroom_listing <- function(html) {
  doc <- xml2::read_html(html)
  rows <- rvest::html_elements(doc, ".views-row")

  out <- purrr::map_dfr(rows, function(row) {
    link <- rvest::html_element(row, "h3 a")
    if (inherits(link, "xml_missing")) return(NULL)

    href <- rvest::html_attr(link, "href")
    if (is.na(href) || !nzchar(href)) return(NULL)

    stamp <- rvest::html_element(row, "time") %>% rvest::html_attr("datetime")
    badge <- rvest::html_element(row, ".ds-c-badge") %>% rvest::html_text2()

    tibble::tibble(
      item_date = as.Date(substr(dplyr::coalesce(stamp, ""), 1, 10)),
      item_type = stringr::str_squish(dplyr::coalesce(badge, NA_character_)),
      title = stringr::str_squish(rvest::html_text2(link)),
      url = href
    )
  })

  if (nrow(out) == 0) {
    stop(
      "Parsed zero items from a CMS newsroom listing page.\n",
      "The newsroom is never empty, so this is the markup having moved, not a ",
      "quiet week. Read the archived listing under data/raw/cms/ and fix the ",
      "selector; nothing is written from an empty crawl.",
      call. = FALSE
    )
  }

  dplyr::distinct(out, .data$url, .keep_all = TRUE)
}


#' The topics CMS tagged a newsroom release with
#'
#' Read from the schema.org NewsArticle JSON-LD `about`, which is a string when
#' there is one topic and an array when there are several. Returns character(0)
#' when the block is absent, which the caller treats as "not rural" rather than
#' as an error: CMS tags some items with nothing at all.
cms_newsroom_topics <- function(html) {
  doc <- xml2::read_html(html)
  blocks <- doc %>%
    rvest::html_elements("script[type='application/ld+json']") %>%
    rvest::html_text()

  if (!length(blocks)) return(character(0))

  topics <- purrr::map(blocks, function(block) {
    parsed <- tryCatch(jsonlite::fromJSON(block, simplifyVector = FALSE),
                       error = function(e) NULL)
    if (is.null(parsed)) return(character(0))

    graph <- parsed[["@graph"]] %||% list(parsed)
    purrr::map(graph, function(node) {
      about <- node[["about"]]
      if (is.null(about)) return(character(0))
      as.character(unlist(about, use.names = FALSE))
    })
  })

  unique(stringr::str_squish(as.character(unlist(topics, use.names = FALSE))))
}


#' Is a release tagged with the RHTP topic?
cms_newsroom_is_rural <- function(topics) {
  any(stringr::str_detect(
    topics, stringr::regex(NEWSROOM_TOPIC, ignore_case = TRUE)
  ))
}


#' The state a newsroom headline names, or NA for a national announcement
#'
#' LONGEST MATCH WINS, and that is the whole point of doing this by hand rather
#' than with a first-match regex. "...Across West Virginia" contains "Virginia",
#' and a first-match reader files West Virginia's $4.2M under VA -- which would
#' have been invisible, because both are real states and neither row would look
#' wrong. Matching the longest state name present makes "West Virginia" beat
#' "Virginia", and "North Dakota"/"South Dakota" beat nothing at all.
#'
#' Two states named in one headline is refused rather than resolved: CMS has
#' never done it, and picking one would be a guess about which state an award
#' went to.
cms_newsroom_state <- function(title) {
  states <- rhtp_cms_states()

  purrr::map_chr(title, function(one) {
    if (is.na(one)) return(NA_character_)

    hit <- states$state_name[purrr::map_lgl(states$state_name, function(nm) {
      stringr::str_detect(one, stringr::regex(paste0("\\b", nm, "\\b"),
                                              ignore_case = TRUE))
    })]
    if (!length(hit)) return(NA_character_)

    # Drop a state name wholly contained in a longer one that also matched:
    # "Virginia" inside "West Virginia", "Dakota" inside either Dakota.
    hit <- hit[!purrr::map_lgl(hit, function(short) {
      any(short != hit & stringr::str_detect(hit, stringr::fixed(short)))
    })]

    if (length(hit) > 1) {
      stop(
        "A CMS newsroom headline names more than one state (",
        paste(hit, collapse = ", "), "):\n  ", one, "\n",
        "This parser will not pick one. Read the release and decide ",
        "deliberately which state the award belongs to.",
        call. = FALSE
      )
    }

    states$state[match(hit, states$state_name)]
  })
}


#' Where the newsroom archive for a fetch date lives
rhtp_newsroom_archive_dir <- function(fetch_date = Sys.Date()) {
  here::here(rhtp_config()$paths$raw_cms, as.character(fetch_date), "newsroom")
}


#' Every rural release archived under data/raw/cms/, newest fetch date first
#'
#' The archive is cumulative across fetch dates: a release archived in an
#' earlier run is not re-fetched, so the parse reads them all and dedupes on
#' the slug, keeping the newest copy.
rhtp_newsroom_archived_releases <- function() {
  root <- here::here(rhtp_config()$paths$raw_cms)
  if (!dir.exists(root)) return(character(0))

  hits <- list.files(root, pattern = "\\.html$", recursive = TRUE,
                     full.names = TRUE)
  hits <- hits[stringr::str_detect(hits, "/newsroom/releases/")]
  if (!length(hits)) return(character(0))

  # Newest fetch date first, then unique by slug, so a re-fetched release wins.
  fetch_dates <- basename(dirname(dirname(dirname(hits))))
  hits <- hits[order(fetch_dates, decreasing = TRUE)]
  hits[!duplicated(basename(hits))]
}


#' The topic index's empty shape, as one definition
#'
#' Used both for a first run (no index on disk yet) and for a run that learns
#' nothing. Those are the same shape and there is no reason for them to be two
#' literals that can drift apart.
cms_newsroom_index_schema <- function() {
  tibble::tibble(
    slug = character(), url = character(), item_date = as.Date(character()),
    item_type = character(), title = character(), topics = character(),
    is_rural = logical(), reduced_sha256 = character(),
    full_page_sha256 = character(), full_page_bytes = integer(),
    first_indexed = character()
  )
}


#' The committed topic index: every newsroom item ever seen, and its topic
rhtp_newsroom_index <- function() {
  path <- here::here(rhtp_config()$paths$cms_newsroom_index)
  if (!file.exists(path)) {
    return(cms_newsroom_index_schema())
  }
  # first_indexed is pinned to character on the way back in. readr infers it as
  # a Date, and it then meets medicaid.gov's character first_seen in the union
  # and bind_rows refuses the two -- which is a failure only the offline
  # --parse path reaches, because a fresh --run builds the index in memory
  # where the column is already character. Pinned at the reader so both paths
  # see the same types.
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE) %>%
    dplyr::mutate(
      item_date = as.Date(.data$item_date),
      first_indexed = as.character(.data$first_indexed),
      is_rural = as.logical(.data$is_rural)
    )
}


#' A shared httr2 request for cms.gov
cms_newsroom_request <- function(url) {
  cfg <- rhtp_config()
  httr2::request(url) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_throttle(capacity = cfg$quota$throttle_requests_per_minute,
                        fill_time_s = 60) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2^.x)
}


#' Fetch a cms.gov URL, or stop with the egress note
cms_newsroom_get <- function(url, what) {
  resp <- tryCatch(
    httr2::req_perform(cms_newsroom_request(url)),
    error = function(e) {
      stop(
        "Could not reach ", url, " (", what, ").\n",
        "  ", conditionMessage(e), "\n\n",
        "www.cms.gov is allowlisted and the newsroom LISTING and RELEASE ",
        "pages both answer 200.\n",
        "What does NOT work, and is not a bug to chase: ",
        "/newsroom/search -- Akamai refuses that path outright (403 with no ",
        "query string at all), which is why the topic is read from each ",
        "release's JSON-LD instead of from the facet URL.\n",
        "Nothing is written until the fetch succeeds: an empty trigger list ",
        "reads as 'no state has announced an award', the opposite of the truth.",
        call. = FALSE
      )
    }
  )

  status <- httr2::resp_status(resp)
  if (status != 200) {
    stop("CMS newsroom ", what, " returned HTTP ", status,
         "; refusing to archive a non-200 body.", call. = FALSE)
  }

  httr2::resp_body_string(resp)
}


#' Write bytes exactly as served, with a SHA-256 manifest line
#'
#' writeBin, not writeLines: writeLines appends a trailing newline, so the file
#' on disk is one byte longer than the body that was hashed and a reader
#' verifying the digest gets a mismatch. Session 12 found that in four earlier
#' archives; new archives do not repeat it.
cms_newsroom_write <- function(body, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeBin(charToRaw(body), path)
  digest::digest(body, algo = "sha256", serialize = FALSE)
}


# A CMS page's Drupal settings JSON carries a third-party Mapbox API token.
# It is CMS's to publish and not ours to redistribute, which is why §7.1
# archived only the allotment <table> and Session 11 archived only the <main>
# of the six state press releases. Same posture here, and the same shape of
# check: the token is matched by form, not by its literal value, so a rotated
# token is caught too.
CMS_THIRD_PARTY_TOKEN_PATTERN <- "\\b[ps]k\\.ey[A-Za-z0-9_.-]{20,}"


#' Reduce a release page to the parts this project may commit
#'
#' Keeps two things and drops everything else:
#'
#'   the <main> element -- the article, which is the evidence; and
#'   the schema.org JSON-LD -- which is where CMS publishes the topic, and
#'   which lives in <head>, so archiving <main> alone would throw away the
#'   very field the filter reads and make the archive unre-parseable offline.
#'
#' The listing pages are NOT reduced: they carry no token and are archived as
#' served.
#'
#' @return The reduced document as a single string.
cms_newsroom_reduce_release <- function(body) {
  doc <- xml2::read_html(body)

  main <- rvest::html_element(doc, "main")
  if (inherits(main, "xml_missing")) {
    stop("A CMS newsroom release has no <main> element to archive. Read the ",
         "page before changing this -- archiving the full page would commit ",
         "the third-party token in CMS's Drupal settings.", call. = FALSE)
  }

  ld <- doc %>% rvest::html_elements("script[type='application/ld+json']")

  reduced <- paste0(
    "<!-- RHTP tracker: reduced archive. The <main> element and the ",
    "schema.org JSON-LD only.\n",
    "     The surrounding CMS chrome carries a third-party Mapbox token in its ",
    "Drupal settings\n",
    "     JSON, which is CMS's to publish and not ours to redistribute ",
    "(§7.1, Session 11).\n",
    "     The manifest carries the full page's digest as served, so provenance ",
    "still closes. -->\n",
    "<html><head>\n",
    paste(purrr::map_chr(ld, as.character), collapse = "\n"),
    "\n</head><body>\n",
    as.character(main),
    "\n</body></html>\n"
  )

  if (stringr::str_detect(reduced, CMS_THIRD_PARTY_TOKEN_PATTERN)) {
    stop(
      "A reduced CMS newsroom release still carries a third-party API token.\n",
      "Nothing is written. The token is CMS's to publish and not ours to ",
      "redistribute -- find where it now sits in the markup and exclude it ",
      "before archiving.",
      call. = FALSE
    )
  }

  reduced
}


#' Crawl the newsroom listing, learn each new item's topic, archive the rural ones
#'
#' The crawl is bounded twice over: it stops at the first listing page wholly
#' older than the RHTP floor date, and it refuses if it reaches max_pages
#' without ever crossing that floor -- an unbounded walk that quietly returns
#' "what fit" is the §5.2 short read in another costume.
#'
#' @return A list of index (the updated topic index), fetched (items whose
#'   topic was learned this run) and pages (listing pages walked).
rhtp_fetch_cms_newsroom <- function(fetch_date = Sys.Date(), force = FALSE) {
  archive_dir <- rhtp_newsroom_archive_dir(fetch_date)
  index <- rhtp_newsroom_index()

  listing <- tibble::tibble()
  crossed_floor <- FALSE
  pages <- 0L

  for (page in seq_len(NEWSROOM_MAX_PAGES) - 1L) {
    url <- if (page == 0L) NEWSROOM_LISTING_URL else
      paste0(NEWSROOM_LISTING_URL, "?page=", page)

    body <- cms_newsroom_get(url, paste0("listing page ", page))
    sha <- cms_newsroom_write(
      body, file.path(archive_dir, "listing", sprintf("articles_page_%02d.html", page))
    )
    pages <- pages + 1L

    items <- rhtp_parse_newsroom_listing(body)
    listing <- dplyr::bind_rows(listing, items)

    message("  newsroom listing page ", page, ": ", nrow(items), " items (",
            format(min(items$item_date, na.rm = TRUE)), " .. ",
            format(max(items$item_date, na.rm = TRUE)), "), sha256 ",
            substr(sha, 1, 12), "...")

    if (all(!is.na(items$item_date)) && max(items$item_date) < NEWSROOM_FLOOR_DATE) {
      crossed_floor <- TRUE
      break
    }
  }

  if (!crossed_floor) {
    stop(
      "Walked ", pages, " newsroom listing pages (cms newsroom_max_pages) ",
      "without reaching the floor date ", format(NEWSROOM_FLOOR_DATE), ".\n",
      "The crawl is therefore INCOMPLETE and is refused rather than reported ",
      "as a full trigger list -- 'what fit in max_pages' is not 'every RHTP ",
      "announcement', and the difference is a state nobody collects (§5.2).\n",
      "Raise cms newsroom_max_pages in config/config.yml, deliberately.",
      call. = FALSE
    )
  }

  listing <- listing %>%
    dplyr::filter(!is.na(.data$item_date), .data$item_date >= NEWSROOM_FLOOR_DATE) %>%
    dplyr::mutate(slug = cms_newsroom_slug(.data$url)) %>%
    dplyr::distinct(.data$slug, .keep_all = TRUE)

  todo <- if (force) listing else
    listing %>% dplyr::filter(!.data$slug %in% index$slug)

  message("  ", nrow(listing), " items at or after ", format(NEWSROOM_FLOOR_DATE),
          "; ", nrow(todo), " whose topic is not yet known",
          if (!force && nrow(todo) < nrow(listing))
            paste0(" (", nrow(listing) - nrow(todo), " already in the topic index)")
          else "")

  learned <- purrr::map_dfr(seq_len(nrow(todo)), function(i) {
    item <- todo[i, ]
    url <- if (stringr::str_starts(item$url, "/"))
      paste0(NEWSROOM_BASE_URL, item$url) else item$url

    body <- cms_newsroom_get(url, paste0("release ", item$slug))
    topics <- cms_newsroom_topics(body)
    rural <- cms_newsroom_is_rural(topics)

    # Only the rural releases are archived, and only their <main> plus the
    # JSON-LD. A non-rural release is CMS's to publish and not evidence for
    # anything here; its topic is recorded so it is never fetched again, which
    # is what the index is for.
    reduced_sha <- NA_character_
    full_sha <- digest::digest(body, algo = "sha256", serialize = FALSE)
    if (rural) {
      reduced_sha <- cms_newsroom_write(
        cms_newsroom_reduce_release(body),
        file.path(archive_dir, "releases", paste0(item$slug, ".html"))
      )
    }

    tibble::tibble(
      slug = item$slug, url = url, item_date = item$item_date,
      item_type = item$item_type, title = item$title,
      topics = paste(topics, collapse = "; "), is_rural = rural,
      reduced_sha256 = reduced_sha, full_page_sha256 = full_sha,
      full_page_bytes = nchar(body, type = "bytes"),
      first_indexed = as.character(Sys.Date())
    )
  })

  # purrr::map_dfr over zero rows returns a zero-COLUMN tibble, so `learned$is_rural`
  # is NULL and every read of it warns "Unknown or uninitialised column". That is
  # the STEADY STATE, not an edge case: once the topic index is warm, most runs
  # learn nothing, so the twice-weekly Routine hit this on every run. sum(NULL) is
  # 0, so the counts printed were right by luck -- which is the part worth fixing,
  # because the next reader of that column would get NULL rather than an error.
  if (nrow(learned) == 0) learned <- cms_newsroom_index_schema()

  index <- dplyr::bind_rows(learned, index) %>%
    dplyr::distinct(.data$slug, .keep_all = TRUE) %>%
    dplyr::arrange(dplyr::desc(.data$item_date), .data$slug)

  index_path <- here::here(rhtp_config()$paths$cms_newsroom_index)
  dir.create(dirname(index_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(index, index_path, na = "")

  writeLines(
    paste0(
      "RHTP tracker archive: the CMS newsroom, filtered to the '", NEWSROOM_TOPIC,
      "' topic.\n\n",
      "listing_url  : ", NEWSROOM_LISTING_URL, "\n",
      "fetched_utc  : ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n",
      "listing_pages: ", pages, "\n",
      "floor_date   : ", format(NEWSROOM_FLOOR_DATE), "\n",
      "items_seen   : ", nrow(listing), "\n",
      "topics_learnt: ", nrow(learned), "\n",
      "rural_archived (this run): ", sum(learned$is_rural), "\n\n",
      "WHAT IS COMMITTED, AND WHAT IS NOT. Each file under releases/ is the\n",
      "<main> element plus the schema.org JSON-LD, NOT the page as served.\n",
      "CMS's page chrome carries a third-party Mapbox API token in its Drupal\n",
      "settings JSON, which is CMS's to publish and not ours to redistribute;\n",
      "this is the posture §7.1 took for the allotment table and Session 11\n",
      "took for the six state press releases. The JSON-LD is kept because it\n",
      "is where CMS publishes the topic -- archiving <main> alone would throw\n",
      "away the field the filter reads and leave the archive unre-parseable\n",
      "offline. Every file was asserted free of that token shape before it was\n",
      "written, and the full page's digest is recorded per release in\n",
      "data/reference/cms_newsroom_topic_index.csv (full_page_sha256), so\n",
      "provenance still closes against what cms.gov served.\n\n",
      "The listing pages under listing/ carry no such token and ARE archived\n",
      "byte for byte as served.\n\n",
      "Digests are written with writeBin, not writeLines: writeLines appends a\n",
      "trailing newline, so the file on disk would be one byte longer than the\n",
      "body that was hashed and a reader verifying it would get a mismatch.\n\n",
      "THE TOPIC FILTER is CMS's own, read from each release's schema.org\n",
      "NewsArticle JSON-LD `about`. CMS's facet URL for the same taxonomy,\n",
      "/newsroom/search?about[]=<id>, is refused by Akamai for any\n",
      "non-browser client (403 on the bare path, with no query string), so\n",
      "the topic is read from the document instead of from a query.\n\n",
      "A DISCOVERY source (§0.1). No figure here may enter an AHA-published\n",
      "number, and `amount` is never summed (§0.2): CMS mixes the Tier 1\n",
      "state allotment and the Tier 3 announcement in the same release --\n",
      "Virginia's names $122M in its headline and $189M in a quoted\n",
      "statement, and those are two different tiers of the same programme.\n\n",
      "sha256 per file. MANIFEST.txt IS NOT LISTED IN ITSELF -- a manifest\n",
      "cannot record its own digest, because the value would be stale the\n",
      "instant the file is written. It listed itself until a second --run on\n",
      "one archive date exposed it: the first run wrote the manifest AFTER\n",
      "taking the listing, so the file did not exist to be listed and the\n",
      "verification test passed on absence rather than on correctness.\n\n",
      paste(
        purrr::map_chr(
          sort(setdiff(
            list.files(archive_dir, recursive = TRUE, full.names = TRUE),
            file.path(archive_dir, "MANIFEST.txt")
          )),
          function(f) paste0("  ", digest::digest(file = f, algo = "sha256"),
                             "  ", sub(paste0(archive_dir, "/"), "", f, fixed = TRUE))
        ),
        collapse = "\n"
      ), "\n"
    ),
    file.path(archive_dir, "MANIFEST.txt")
  )

  message("  archived ", sum(learned$is_rural), " rural release(s) to ", archive_dir)
  invisible(list(index = index, fetched = learned, pages = pages))
}


#' Parse the archived rural releases into the announcement table
#'
#' Reads the committed archive, never the network, so a re-parse after a rules
#' change costs nothing and reproduces exactly (§0.5).
rhtp_parse_cms_newsroom <- function(index = rhtp_newsroom_index()) {
  rural <- index %>% dplyr::filter(.data$is_rural)

  if (nrow(rural) == 0) {
    stop(
      "No newsroom item carries the '", NEWSROOM_TOPIC, "' topic.\n",
      "CMS has tagged RHTP announcements with it since 2025-09-15, so zero ",
      "means the JSON-LD moved or the topic was renamed -- not that CMS has ",
      "stopped announcing. Read an archived release under data/raw/cms/ and ",
      "check its `about` block before changing cms newsroom_topic.",
      call. = FALSE
    )
  }

  out <- rural %>%
    dplyr::mutate(
      state_raw = cms_newsroom_state(.data$title),
      amount = cms_press_parse_amount(
        stringr::str_extract(.data$title, CMS_PRESS_AMOUNT_PATTERN)
      )
    )

  # A rural-topic release naming no state is a PROGRAMME announcement -- the
  # $50bn launch, the all-50-states award, the Office of RHT, the summit
  # readout. They are Tier 1 (§0.2) and this is the STATE trigger list, so they
  # are excluded deliberately and counted, exactly as the medicaid.gov "All"
  # rows are.
  national <- is.na(out$state_raw)
  if (any(national)) {
    message("  excluded ", sum(national), " national (non-state) rural-topic ",
            "release(s) -- Tier 1 programme announcements:")
    purrr::walk(out$title[national],
                function(t) message("      ", stringr::str_trunc(t, 96)))
    out <- out[!national, , drop = FALSE]
  }

  out <- out %>%
    dplyr::transmute(
      state = .data$state_raw,
      date = .data$item_date,
      amount = .data$amount,
      title = .data$title,
      url = .data$url,
      source_url = NEWSROOM_LISTING_URL,
      first_seen = as.character(.data$first_indexed)
    ) %>%
    dplyr::arrange(.data$state, .data$date)

  attr(out, "cms_press_shape") <- "NEWSROOM_TOPIC"
  out
}


# -- Union: primary over secondary, and neither may shrink the other --------

#' Combine the newsroom (primary) and medicaid.gov (secondary) trigger lists
#'
#' Rows are keyed on state + title, which is what makes the union work at all:
#' medicaid.gov links to the same cms.gov releases under the same headlines, so
#' the nine shared announcements collapse to nine rows rather than eighteen.
#'
#' The newsroom row wins a collision, and it is not a coin toss which: the
#' medicaid.gov page carries a malformed link for West Virginia (a doubled
#' slash in /newsroom/press-releases//trump-administration-...), and the
#' newsroom's own URL is right. Taking the primary's URL fixes that without a
#' special case.
#'
#' `source` is recorded per row so a state present in only one list is visible
#' as such. That is the finding this rewrite exists to surface: on 2026-08-28
#' Virginia was NEWSROOM only, and reading medicaid.gov alone reported eight
#' announced states when there were nine.
rhtp_cms_press_union <- function(newsroom, medicaid) {
  key <- function(d) paste(d$state, stringr::str_squish(dplyr::coalesce(d$title, "")),
                           sep = "|")

  newsroom <- newsroom %>% dplyr::mutate(source = "CMS_NEWSROOM")
  medicaid <- medicaid %>% dplyr::mutate(source = "MEDICAID_GOV")

  shared <- intersect(key(newsroom), key(medicaid))

  combined <- dplyr::bind_rows(
    newsroom %>% dplyr::mutate(
      source = dplyr::if_else(key(.) %in% shared, "BOTH", "CMS_NEWSROOM")
    ),
    medicaid %>% dplyr::filter(!key(.) %in% key(newsroom))
  )

  combined %>%
    dplyr::select("state", "date", "amount", "title", "url", "source",
                  "source_url", "first_seen") %>%
    dplyr::arrange(.data$state, .data$date)
}


# -- Assertions -------------------------------------------------------------

rhtp_cms_press_assert <- function(announcements) {
  fail <- function(...) stop("[CMS press] ", ..., call. = FALSE)

  if (nrow(announcements) == 0) {
    fail("Parsed zero announcements. CMS lists states that have announced ",
         "awards, so an empty table means the parse failed, not that no state ",
         "has announced. Read the archived page.")
  }

  states <- rhtp_cms_states()$state
  bad <- setdiff(announcements$state, states)
  if (length(bad)) {
    fail("States outside the §7.1 fifty: ", paste(bad, collapse = ", "))
  }

  if (any(!is.na(announcements$date) & announcements$date > Sys.Date() + 1)) {
    fail("An announcement is dated in the future; the date parse has picked up ",
         "the wrong column.")
  }

  # §0.2, the three-tier rule, guarded at its most seductive point. This page
  # mixes CMS-to-state allotment announcements with state subaward
  # announcements, so any total over `amount` blends Tier 1 and Tier 3. Georgia
  # alone would appear at $218.8M as an allotment and again at $60.5M as
  # subawards. The check is on plausibility, and it is here to make the
  # comment unmissable to whoever adds a summary line to this file next.
  total <- sum(announcements$amount, na.rm = TRUE)
  if (total > 1.0e10) {
    fail("The announcement amounts total more than the entire $10B RHTP ",
         "programme. That is Tier 1 and Tier 3 figures added together (§0.2). ",
         "This column is never summed -- it prioritises collection.")
  }

  if ("source" %in% names(announcements)) {
    allowed <- c("CMS_NEWSROOM", "MEDICAID_GOV", "BOTH")
    bad_source <- setdiff(unique(announcements$source), allowed)
    if (length(bad_source)) {
      fail("Source values outside the controlled set (",
           paste(allowed, collapse = " | "), "): ",
           paste(bad_source, collapse = ", "), ". No free-text categories (§8).")
    }
  }

  invisible(TRUE)
}


# -- Change detection: what actually makes this a monitor -------------------

#' Compare this run's parse to the committed CSV
#'
#' The point of the twice-weekly cadence is this diff, not the file. A state
#' appearing here is a state to go and collect.
rhtp_cms_press_delta <- function(announcements) {
  path <- here::here(CMS_PRESS_CSV)
  if (!file.exists(path)) {
    return(list(
      new_states = sort(unique(announcements$state)),
      new_rows = announcements,
      changed_rows = announcements[0, ],
      first_run = TRUE
    ))
  }

  prior <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  key <- function(d) paste(d$state, dplyr::coalesce(d$title, ""), sep = "|")
  new_rows <- announcements %>% dplyr::filter(!key(.) %in% key(prior))

  changed <- announcements %>%
    dplyr::inner_join(
      prior %>% dplyr::select("state", "title",
                              prior_amount = "amount", prior_date = "date"),
      by = c("state", "title")
    ) %>%
    dplyr::filter(
      (!is.na(.data$amount) & !is.na(.data$prior_amount) &
         .data$amount != .data$prior_amount) |
        (!is.na(.data$date) & !is.na(.data$prior_date) &
           .data$date != .data$prior_date)
    )

  list(
    new_states = sort(setdiff(unique(announcements$state), unique(prior$state))),
    new_rows = new_rows,
    changed_rows = changed,
    first_run = FALSE
  )
}


# -- Run --------------------------------------------------------------------

rhtp_cms_press_run <- function(fetch_date = Sys.Date(), force = FALSE,
                               run_type = c("PRODUCTION", "DEV"),
                               fetch = TRUE,
                               sources = c("both", "newsroom", "medicaid")) {
  run_type <- match.arg(run_type)
  sources <- match.arg(sources)

  want_newsroom <- sources %in% c("both", "newsroom")
  want_medicaid <- sources %in% c("both", "medicaid")

  newsroom <- NULL
  medicaid <- NULL
  medicaid_degraded <- FALSE
  pages <- NA_integer_
  learned <- NA_integer_

  # --- PRIMARY: the cms.gov newsroom, rural health topic -------------------
  # A primary failure stops the run. There is no degraded mode here: the
  # newsroom is the source that does not lag, and a trigger list built without
  # it is the exact defect this stage was rewritten to fix.
  if (want_newsroom) {
    message("[CMS press] PRIMARY: cms.gov newsroom, topic '", NEWSROOM_TOPIC, "'")
    if (fetch) {
      fetched <- rhtp_fetch_cms_newsroom(fetch_date = fetch_date, force = force)
      pages <- fetched$pages
      learned <- nrow(fetched$fetched)
      newsroom <- rhtp_parse_cms_newsroom(fetched$index)
    } else {
      newsroom <- rhtp_parse_cms_newsroom()
    }
    message("  newsroom: ", nrow(newsroom), " state announcement(s) across ",
            dplyr::n_distinct(newsroom$state), " state(s)")
  }

  # --- SECONDARY: the medicaid.gov resources page --------------------------
  # This one MAY degrade, and degrading is not the same as dropping. If the
  # fetch fails, the rows medicaid.gov contributed at the last successful run
  # are carried forward from the committed CSV rather than silently vanishing:
  # a source being unreachable is not evidence that a state un-announced.
  if (want_medicaid) {
    message("[CMS press] SECONDARY: medicaid.gov RHTP resources page")
    medicaid <- tryCatch({
      if (fetch) rhtp_fetch_cms_press(fetch_date = fetch_date, force = force)
      rhtp_parse_cms_press()
    }, error = function(e) {
      message("  medicaid.gov is unavailable: ", conditionMessage(e))
      medicaid_degraded <<- TRUE
      NULL
    })
    if (!is.null(medicaid)) {
      message("  medicaid.gov: ", nrow(medicaid), " announcement(s) across ",
              dplyr::n_distinct(medicaid$state), " state(s)")
    }
  }

  empty <- tibble::tibble(
    state = character(), date = as.Date(character()), amount = numeric(),
    title = character(), url = character(), source_url = character(),
    first_seen = character()
  )

  if (is.null(medicaid) && medicaid_degraded && file.exists(here::here(CMS_PRESS_CSV))) {
    prior <- readr::read_csv(here::here(CMS_PRESS_CSV), show_col_types = FALSE,
                             progress = FALSE)
    if ("source" %in% names(prior)) {
      medicaid <- prior %>%
        dplyr::filter(.data$source %in% c("MEDICAID_GOV", "BOTH")) %>%
        dplyr::select(dplyr::any_of(names(empty))) %>%
        dplyr::mutate(date = as.Date(.data$date))
      message("  carried ", nrow(medicaid), " medicaid.gov row(s) forward from ",
              "the last successful run rather than dropping them.")
    }
  }

  announcements <- rhtp_cms_press_union(
    newsroom %||% empty,
    medicaid %||% empty
  )

  rhtp_cms_press_assert(announcements)

  # The finding this rewrite exists to make visible: which states only ONE of
  # the two sources knows about. On 2026-08-28 that was Virginia, newsroom-only
  # -- $122M that a medicaid.gov-only monitor reported as not having happened.
  only_newsroom <- setdiff(
    announcements$state[announcements$source == "CMS_NEWSROOM"],
    announcements$state[announcements$source %in% c("BOTH", "MEDICAID_GOV")]
  )
  only_medicaid <- setdiff(
    announcements$state[announcements$source == "MEDICAID_GOV"],
    announcements$state[announcements$source %in% c("BOTH", "CMS_NEWSROOM")]
  )

  delta <- rhtp_cms_press_delta(announcements)

  # Preserve the first_seen of a row we have seen before: it is the date this
  # project learned of the announcement, not the date of the newest parse.
  csv_path <- here::here(CMS_PRESS_CSV)
  if (file.exists(csv_path)) {
    prior <- readr::read_csv(csv_path, show_col_types = FALSE, progress = FALSE)
    announcements <- announcements %>%
      dplyr::left_join(
        prior %>% dplyr::select("state", "title", prior_first_seen = "first_seen"),
        by = c("state", "title")
      ) %>%
      dplyr::mutate(
        first_seen = dplyr::coalesce(as.character(.data$prior_first_seen),
                                     .data$first_seen)
      ) %>%
      dplyr::select(-"prior_first_seen")
  }

  readr::write_csv(announcements, csv_path, na = "")

  manifest_path <- here::here(CMS_PRESS_MANIFEST)
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(
    tibble::tibble(
      run_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      run_type = run_type,
      fetch_date = as.character(fetch_date),
      sources = sources,
      newsroom_pages = pages,
      newsroom_topics_learnt = learned,
      newsroom_rows = if (is.null(newsroom)) NA_integer_ else nrow(newsroom),
      medicaid_rows = if (is.null(medicaid)) NA_integer_ else nrow(medicaid),
      medicaid_degraded = medicaid_degraded,
      rows = nrow(announcements),
      states = dplyr::n_distinct(announcements$state),
      only_newsroom = paste(sort(unique(only_newsroom)), collapse = " "),
      only_medicaid = paste(sort(unique(only_medicaid)), collapse = " "),
      new_states = paste(delta$new_states, collapse = " "),
      new_rows = nrow(delta$new_rows),
      changed_rows = nrow(delta$changed_rows)
    ),
    manifest_path,
    append = file.exists(manifest_path)
  )

  message("[CMS press] ", nrow(announcements), " announcements across ",
          dplyr::n_distinct(announcements$state), " states -> ", CMS_PRESS_CSV)
  if (length(only_newsroom)) {
    message("[CMS press] ONLY the newsroom carries: ",
            paste(sort(unique(only_newsroom)), collapse = ", "),
            " -- medicaid.gov is lagging on these.")
  }
  if (length(only_medicaid)) {
    message("[CMS press] ONLY medicaid.gov carries: ",
            paste(sort(unique(only_medicaid)), collapse = ", "),
            " -- the newsroom topic filter did not surface these; read them.")
  }
  if (length(delta$new_states)) {
    message("[CMS press] NEW STATES TO COLLECT: ",
            paste(delta$new_states, collapse = ", "))
  }
  if (nrow(delta$changed_rows)) {
    message("[CMS press] ", nrow(delta$changed_rows),
            " announcement(s) changed amount or date -- re-check the state source.")
  }
  if (!length(delta$new_states) && !nrow(delta$changed_rows) && !delta$first_run) {
    message("[CMS press] no change since the last run.")
  }

  invisible(list(announcements = announcements, delta = delta,
                 only_newsroom = only_newsroom, only_medicaid = only_medicaid))
}


rhtp_cms_press_status <- function() {
  path <- here::here(CMS_PRESS_CSV)
  if (!file.exists(path)) {
    message("[CMS press] ", CMS_PRESS_CSV, " does not exist yet.\n",
            "  medicaid.gov was not allowlisted when this stage was built, so ",
            "the monitor has never run.\n",
            "  Allowlist www.medicaid.gov, then: Rscript R/00_cms_press_monitor.R --run")
    return(invisible(NULL))
  }

  d <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  message("[CMS press] ", nrow(d), " announcements across ",
          dplyr::n_distinct(d$state), " of 50 states.")
  print(d %>% dplyr::count(.data$state, name = "announcements") %>%
          dplyr::arrange(dplyr::desc(.data$announcements)), n = Inf)
  invisible(d)
}


`%||%` <- function(x, y) if (is.null(x)) y else x


# -- CLI --------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  run_type <- if ("--dev" %in% args) "DEV" else "PRODUCTION"

  sources <- if ("--newsroom" %in% args) "newsroom" else
    if ("--medicaid" %in% args) "medicaid" else "both"

  if ("--run" %in% args) {
    rhtp_cms_press_run(force = "--force" %in% args, run_type = run_type,
                       sources = sources)
  } else if ("--parse" %in% args) {
    rhtp_cms_press_run(fetch = FALSE, run_type = run_type, sources = sources)
  } else if ("--status" %in% args) {
    rhtp_cms_press_status()
  } else {
    message(
      "Usage: Rscript R/00_cms_press_monitor.R [--run [--force] [--dev] | --parse | --status]\n",
      "                                        [--newsroom | --medicaid]\n\n",
      "  --run       fetch both sources, union, write the trigger list\n",
      "  --parse     re-parse the committed archives, no network\n",
      "  --status    what the current trigger list says\n",
      "  --newsroom  the cms.gov newsroom only (PRIMARY)\n",
      "  --medicaid  the medicaid.gov resources page only (SECONDARY)\n",
      "  --force     re-fetch over today's archive, and re-learn every topic"
    )
  }
}

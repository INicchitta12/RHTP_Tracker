# 00_cms_press_monitor.R ----------------------------------------------------
# CMS RHTP resources page -> data/reference/cms_state_announcements.csv.
#
# THE TRIGGER LIST. This is the cheapest signal in the project: CMS maintains
# one page listing the states that have announced RHTP awards, and a state
# appearing on it is the cue to go and collect that state's primary sources.
# It runs on the twice-weekly cadence alongside the RCJ pull (config pull$cadence)
# and costs zero RCJ quota -- it never touches the RCJ API.
#
# It is stage 00 because it runs BEFORE retrieval and decides what is worth
# retrieving. Nothing downstream depends on it, so a failure here delays a
# collection pass; it never corrupts a figure.
#
# WHAT IT IS NOT. This is a discovery layer, exactly as RCJ is (§0.1), and the
# same rule applies: no figure from this page may appear in an AHA-published
# number. CMS's own summary of a state announcement is not the state's notice of
# award. `amount` is captured so a collection pass can be prioritised and so a
# state figure that later disagrees is caught early -- never so it can be
# totalled. rhtp_cms_press_assert() hard-fails if the amounts are summed into
# anything resembling a national total, because that number would be a mix of
# state allotments and subaward announcements: §0.2's three-tier rule, in the
# one place where the tiers are easiest to blend by accident.
#
# PARSING. The page's markup has never been read by this code -- see the egress
# note below -- so the parser resolves columns by synonym and scores candidate
# tables rather than assuming a shape, the same approach R/03b_budget_narratives.R
# takes to fifty differently-formatted state workbooks. It REFUSES rather than
# guesses: on a tie between candidate tables, on a table whose columns do not
# resolve, on a state name it cannot map to the §7.1 fifty. A page redesign
# fails loudly instead of silently writing an empty or wrong CSV, which is the
# §5.2 silent short-read failure mode in a different costume.
#
# EGRESS. www.medicaid.gov was allowlisted on 2026-08-28 and this script has now
# run against the live page. Akamai fronts that host and returns 403 to a user
# agent carrying no contact URL -- including to a spoofed browser UA -- so
# config api$user_agent now uses the +url form, which is the well-behaved-crawler
# convention and what gets through. Identifying honestly is the fix here.
#
# WHAT THE LIVE PAGE TAUGHT US. It is a table, but its header row is marked up
# with <td> rather than <th>. html_table() therefore named the columns X1..X5,
# every synonym lookup missed, the table scored 0, and the parser fell through
# to the link-list shape -- which did not fail, it succeeded with less: no dates
# at all, and the state read by matching a state name in the headline instead of
# from the page's own State column. cms_press_promote_header() promotes such a
# row, and only when doing so resolves strictly more columns, so it can never
# make a working parse worse. That failure mode is worth remembering: the
# refusals below guard against parsing the WRONG thing, and this was the other
# kind -- parsing the right thing less well, silently.
#
# Once the table shape was reachable it surfaced two rows the link-list shape
# had been dropping by luck: CMS lists its national announcements (the $50bn
# programme launch, the all-50-states award) in the same table with State =
# "All". They are Tier 1 (§0.2) and this is the STATE trigger list, so they are
# excluded deliberately and the count is reported.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here().
#
# CLI:
#   Rscript R/00_cms_press_monitor.R --run      # fetch, archive, parse, write
#   Rscript R/00_cms_press_monitor.R --run --force   # re-fetch over today's archive
#   Rscript R/00_cms_press_monitor.R --run --dev     # log the run as DEV (§5.2)
#   Rscript R/00_cms_press_monitor.R --parse    # parse the newest archive, no network
#   Rscript R/00_cms_press_monitor.R --status   # what the current CSV says

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
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
                               fetch = TRUE) {
  run_type <- match.arg(run_type)

  if (fetch) {
    archive <- rhtp_fetch_cms_press(fetch_date = fetch_date, force = force)
  } else {
    archive <- rhtp_cms_press_newest_archive()
  }

  announcements <- rhtp_parse_cms_press(archive)
  rhtp_cms_press_assert(announcements)

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
      archive_path = sub(paste0(here::here(), "/"), "", archive, fixed = TRUE),
      shape = attr(announcements, "cms_press_shape") %||% NA_character_,
      rows = nrow(announcements),
      states = dplyr::n_distinct(announcements$state),
      new_states = paste(delta$new_states, collapse = " "),
      new_rows = nrow(delta$new_rows),
      changed_rows = nrow(delta$changed_rows)
    ),
    manifest_path,
    append = file.exists(manifest_path)
  )

  message("[CMS press] ", nrow(announcements), " announcements across ",
          dplyr::n_distinct(announcements$state), " states -> ", CMS_PRESS_CSV)
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

  invisible(list(announcements = announcements, delta = delta))
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

  if ("--run" %in% args) {
    rhtp_cms_press_run(force = "--force" %in% args, run_type = run_type)
  } else if ("--parse" %in% args) {
    rhtp_cms_press_run(fetch = FALSE, run_type = run_type)
  } else if ("--status" %in% args) {
    rhtp_cms_press_status()
  } else {
    message("Usage: Rscript R/00_cms_press_monitor.R [--run [--force] [--dev] | --parse | --status]")
  }
}

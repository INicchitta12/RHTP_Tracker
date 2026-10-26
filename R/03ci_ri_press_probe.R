#!/usr/bin/env Rscript
# 03ci_ri_press_probe.R ---------------------------------------------------------
#
# RHODE ISLAND -- A WATCH ON THE ONE STATE PRESS CHANNEL THIS ENVIRONMENT CAN
# READ (session 107; owner-approved).
#
# WHY THIS PAGE. Session 106 tried EOHHS (/, /initiatives/rural-health-
# transformation-program, /rhtp), the Governor (governor.ri.gov, /press-
# releases) and RIDOH (health.ri.gov, /news) with both project agents: every
# one is HTTP 403 behind a Cloudflare challenge. That is UNKNOWN about Rhode
# Island, never NO (§0.4). The state portal's press system, www.ri.gov/press/,
# is readable. RI stays QUEUED in the survey: its only award file is CMS's
# obligation lines (R/03cb), and this probe does not change that.
#
# WHAT IT READS, AND WHY THE FEED AND NOT THE INDEX ALONE.
#   * rss   -- http(s)://www.ri.gov/rss/1/pressrelease.rss, the portal's
#     all-agency press feed: the latest 50 items (2026-09-17 .. 10-26 when
#     archived, about five weeks), so a WEEKLY probe cannot miss an item. The
#     index page shows only the latest 10 and on 10-26 all ten were State
#     Police arrest logs, so a weekly read of the index alone would miss nearly
#     everything.
#   * index -- www.ri.gov/press/, read for its AGENCY LIST (the publishers the
#     portal carries). The agency list is the organisation-name check: EOHHS
#     and the Governor do not post here today; the day either (or any new
#     publisher) appears, it TRIPS, because that is the day this channel
#     starts carrying the agencies Rhode Island's RHTP news comes from.
#
# THE TRIPWIRES (findings, never thrown early, §2.2 / session 101):
#   1. Any feed item, new or old, whose title or description matches
#      RI_RHTP_PATTERN (Rural Health Transformation, RHTP, "rural health",
#      EOHHS awards ...) and whose link is not in RI_READ_ITEMS. A matching item
#      is read, then extracted or recorded in RI_READ_ITEMS with its sentence --
#      never added to quiet the probe.
#   2. A NEW AGENCY in the index's agency list (§2.3's question -- does the
#      page NAME AN ORGANISATION IT DID NOT NAME BEFORE -- asked of the only
#      list on this page that is not a rolling feed). An agency that leaves the
#      list is reported in the message but does not trip.
#   3. THE EMPTY-BASELINE RULE (§2.3): if the archived feed yields fewer than
#      20 items or the archived index fewer than 5 agencies, the reader has
#      failed and the probe STOPS, because a diff against nothing passes
#      forever.
# RIDOH's own entry on the portal says it "now posts current news and press
# releases at" health.ri.gov, which is 403 here: RIDOH items on this feed are
# legacy, recorded so nobody reads their absence as Rhode Island's silence.
#
# READ-ONLY (§2.2): every --probe goes through rhtp_probe_run(); --fetch is the
# deliberate act that re-bases, and writes NEW dated files.
#
# Usage:
#   Rscript R/03ci_ri_press_probe.R --fetch      # archive the two baselines
#   Rscript R/03ci_ri_press_probe.R --validate   # the archive against itself
#   RHTP_PROBE_ORIGIN=interactive Rscript R/03ci_ri_press_probe.R --probe

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

RI_STATE <- "RI"
RI_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                   "+https://www.aha.org)")
RI_DIR <- file.path("data", "evidence", "RI", "probe")
RI_PAGES <- tibble::tribble(
  ~key, ~url, ~file,
  "rss", "https://www.ri.gov/rss/1/pressrelease.rss",
  file.path(RI_DIR, "2026-10-26_ri_gov_press_rss.xml"),
  "index", "https://www.ri.gov/press/",
  file.path(RI_DIR, "2026-10-26_ri_gov_press_index.html"))

RI_RHTP_PATTERN <- paste0(
  "(?i)rural health transformation|\\bRHTP?\\b|rural health|",
  "\\bEOHHS\\b.*\\b(award|grant|fund)|health and human services.*\\b(award|grant)|",
  "hospital association of rhode island|\\bHARI\\b")
# Feed items READ and judged not an RHTP award, each with its sentence. Empty
# at creation: the 2026-10-26 feed carries no matching item.
RI_READ_ITEMS <- tibble::tibble(link = character(0), why = character(0))

#' The portal serves windows-1252; read bytes as that and return UTF-8 text
ri_text <- function(raw) {
  t <- rawToChar(raw)
  Encoding(t) <- "latin1"
  iconv(t, "CP1252", "UTF-8", sub = " ")
}

#' The feed's items: link, title, description (tags stripped), date
ri_feed_items <- function(raw) {
  x <- xml2::read_xml(ri_text(raw))
  it <- xml2::xml_find_all(x, "//item")
  g <- function(tag) stringr::str_squish(gsub("<[^>]+>", " ",
    xml2::xml_text(xml2::xml_find_first(it, tag))))
  tibble::tibble(link = sub("^http://", "https://", g("link")), title = g("title"),
                 description = g("description"), date = g("pubDate"))
}

#' The index's agency list: every "/press/?agency_id=N" link and its name
ri_agencies <- function(raw) {
  h <- xml2::read_html(ri_text(raw))
  a <- rvest::html_elements(h, "a[href*='agency_id=']")
  tibble::tibble(agency_id = stringr::str_match(rvest::html_attr(a, "href"), "agency_id=([0-9]+)")[, 2],
                 agency = stringr::str_squish(rvest::html_text(a))) %>%
    dplyr::filter(!is.na(.data$agency_id), nzchar(.data$agency)) %>%
    dplyr::distinct()
}

ri_archived <- function(key) {
  f <- here::here(RI_PAGES$file[RI_PAGES$key == key])
  readBin(f, "raw", file.size(f))
}

#' The checks, on parsed live and archived copies. Returns findings; stops only
#' on the empty-baseline rule (a statement about our reader, §2.3).
ri_findings <- function(live_rss, arch_rss, live_idx, arch_idx) {
  ai <- ri_feed_items(arch_rss); aa <- ri_agencies(arch_idx)
  if (nrow(ai) < 20L || nrow(aa) < 5L) {
    stop("[RI] the archived baseline yields ", nrow(ai), " feed items and ",
         nrow(aa), " agencies; the reader has failed, and a diff against ",
         "nothing passes forever (§2.3).", call. = FALSE)
  }
  li <- ri_feed_items(live_rss); la <- ri_agencies(live_idx)
  if (nrow(li) < 20L || nrow(la) < 5L) {
    stop("[RI] the live portal yields ", nrow(li), " feed items and ", nrow(la),
         " agencies: the feed or index has changed shape, not Rhode Island ",
         "(§0.4). Re-read it.", call. = FALSE)
  }
  f <- character(0)
  hit <- li[grepl(RI_RHTP_PATTERN, paste(li$title, li$description), perl = TRUE) &
              !li$link %in% RI_READ_ITEMS$link, ]
  if (nrow(hit)) {
    f <- c(f, paste0(
      "RI PRESS FEED: ", nrow(hit), " item(s) about rural health / RHTP: ",
      paste0("'", hit$title, "' (", hit$link, ", ", hit$date, ")", collapse = " | "),
      ". THAT IS THE SIGNAL: read the release for named recipients and amounts, ",
      "then extract it or record it in RI_READ_ITEMS with its sentence."))
  }
  new_ag <- setdiff(la$agency, aa$agency)
  gone_ag <- setdiff(aa$agency, la$agency)
  if (length(new_ag)) {
    f <- c(f, paste0(
      "RI PRESS INDEX NAMES ", length(new_ag), " AGENCY(IES) THE ARCHIVED COPY ",
      "DOES NOT: ", paste(new_ag, collapse = " | "),
      if (length(gone_ag)) paste0(" (and no longer lists: ", paste(gone_ag, collapse = " | "), ")") else "",
      ". A new publisher on the portal may be EOHHS or the Governor, whose own ",
      "sites are 403 here: read its items, then re-base with --fetch."))
  }
  f
}

ri_probe <- function() {
  live_rss <- rhtp_probe_get("rss", function() rhtp_watch_fetch(RI_PAGES$url[1], RI_AGENT),
                             function() ri_archived("rss"))
  live_idx <- rhtp_probe_get("index", function() rhtp_watch_fetch(RI_PAGES$url[2], RI_AGENT),
                             function() ri_archived("index"))
  arch_rss <- ri_archived("rss"); arch_idx <- ri_archived("index")
  findings <- ri_findings(live_rss, arch_rss, live_idx, arch_idx)
  # THE SHARED NAME TRIPWIRE (§2.3), on the index's AGENCY LIST only -- the
  # one list on this page that is not a rolling feed. Collected, not thrown,
  # by rhtp_probe_run() (session 101).
  ag <- function(raw) paste(paste0(ri_agencies(raw)$agency, "."), collapse = " ")
  rhtp_assert_no_new_organisations_across(live = list(index = ag(live_idx)),
                                          archived = list(index = ag(arch_idx)),
                                          state = RI_STATE)
  # CHANGED is the feed's ITEM SET and the index's AGENCY SET, never bytes:
  # the feed rolls every day, and that is not a finding.
  changed <- c(
    rss = !setequal(ri_feed_items(live_rss)$link, ri_feed_items(arch_rss)$link),
    index = !setequal(ri_agencies(live_idx)$agency, ri_agencies(arch_idx)$agency))
  message("[RI] ", paste0(names(changed), ": ", ifelse(changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "),
          if (length(findings)) paste0(" -- ", length(findings), " FINDING(S).")
          else " -- no RHTP item, no new publisher.")
  invisible(list(changed = unname(changed), findings = findings,
                 sources = stats::setNames(lapply(changed, function(x) list(changed = x)),
                                           names(changed))))
}

ri_fetch <- function() {
  dir.create(here::here(RI_DIR), recursive = TRUE, showWarnings = FALSE)
  man <- here::here(RI_DIR, "MANIFEST.txt")
  for (i in seq_len(nrow(RI_PAGES))) {
    raw <- rhtp_watch_fetch(RI_PAGES$url[i], RI_AGENT)
    txt <- ri_text(raw)
    if (grepl("AIza[0-9A-Za-z_-]{20,}|pk\\.ey[0-9A-Za-z_-]{20,}|accessToken|csrf", txt, ignore.case = TRUE)) {
      stop("[RI] ", RI_PAGES$key[i], " carries a credential-shaped string; not archived.", call. = FALSE)
    }
    out <- if (RI_PAGES$key[i] == "index") {
      h <- xml2::read_html(txt)
      xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
      tf <- tempfile(); xml2::write_html(h, tf); readBin(tf, "raw", file.size(tf))
    } else raw
    writeBin(out, here::here(RI_PAGES$file[i]))
    cat(paste(digest::digest(out, algo = "sha256", serialize = FALSE),
              basename(RI_PAGES$file[i]), RI_PAGES$url[i],
              paste0("full_page_sha256=", digest::digest(raw, algo = "sha256", serialize = FALSE)),
              format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  "),
        "\n", file = man, append = TRUE, sep = "")
    Sys.sleep(2)
  }
  message("[RI] archived ", nrow(RI_PAGES), " baselines to ", RI_DIR)
}

ri_validate <- function() {
  f <- ri_findings(ri_archived("rss"), ri_archived("rss"),
                   ri_archived("index"), ri_archived("index"))
  if (length(f)) stop("[RI] the archive against itself fires: ", f[1], call. = FALSE)
  message("[RI] archive: ", nrow(ri_feed_items(ri_archived("rss"))), " feed items, ",
          nrow(ri_agencies(ri_archived("index"))), " agencies; quiet against itself.")
  invisible(TRUE)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) ri_fetch()
  if ("--validate" %in% args) ri_validate()
  if ("--probe" %in% args) rhtp_probe_run(RI_STATE, ri_probe())
  if (!length(args)) message("Usage: --fetch | --validate | --probe")
}

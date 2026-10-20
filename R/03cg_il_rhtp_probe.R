# 03cg_il_rhtp_probe.R --------------------------------------------------------
# Illinois -- a WATCH on HFS's RHTP page and the state's newsrooms (session 106)
#
# WHAT IS ALREADY KNOWN. Illinois's one award file is R/03l's: ICAHN's
# $50,008,264, a designated pass-through restricted to hospitals (§7,
# POOL_UNNAMED_HOSPITALS). Nothing else Illinois has awarded is published.
#
# WHAT THIS WATCHES FOR. HFS's RHTP page links the "Rural Health
# Transformation Program Hospital Planning Grant Methodology" (Appendix A,
# PDF dated 2026-05-20). It names 97 ELIGIBLE hospitals -- "97 out of 198
# Illinois hospitals are eligible to apply" -- and a pool: "The total planning
# grant funding amount of $28,191,393.00 will be allocated equally among
# eligible hospitals. If all 97 eligible hospitals apply, this will result in
# an award amount of approximately $290,000 per hospital." That is an
# ELIGIBILITY list and a Tier 2 pool (§0.3): eligibility is not receipt, and
# "if all 97 apply" is a hypothetical, never a per-hospital award. The day
# HFS names who RECEIVED a planning grant, that roster is hospital money by
# construction (primary grantees must be general acute hospitals) and this
# probe must trip.
#
# THE PAGES.
#   hfs_rhtp        HFS's RHTP page, read inside its content column only
#                   (IL_HFS_SCOPE): <main> on this AEM template carries the
#                   whole mega-menu, whose runs read as organisation names.
#                   Trips on a NEW LINK in the content (HFS publishes every
#                   RHTP document as a link here; a roster would arrive as
#                   one), a NEW award sentence, a NEW currency figure, and
#                   the name tripwire (§2.3).
#   hfs_stakeholder HFS's "Director's Stakeholders News" index. HFS has no
#                   press-release index of its own (/info/media.html links
#                   only this); its releases go to illinois.gov's news
#                   search, which is a JavaScript client over a key-gated
#                   Elastic API with no URLs or reliable dates -- not read.
#                   A new issue reads CHANGED; a human reads it.
#   gov_press       The Governor's Prezly newsroom, Press Releases category:
#                   a NEW headline about RHTP, rural hospitals or HFS trips.
#   gov_sitemap     The same newsroom's sitemap.xml, every story it has ever
#                   published (1,584 URLs on 2026-10-20). The category page
#                   shows twelve; a weekly probe diffing twelve can miss a
#                   release, the full slug set cannot. A NEW story slug about
#                   RHTP, rural hospitals or HFS trips.
#   planning_method The Planning Grant Methodology PDF, by FILE digest (the
#                   host serves it byte-stable). A change reads CHANGED.
#
# OUT OF SCOPE: AmpliFund, Illinois's grants portal, is behind a login.
#
# Usage:
#   Rscript R/03cg_il_rhtp_probe.R --fetch-probe [--force]   # baselines (§2.2)
#   RHTP_PROBE_ORIGIN=interactive Rscript R/03cg_il_rhtp_probe.R --probe

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble)
  library(purrr); library(here); library(xml2); library(rvest)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

IL_STATE     <- "IL"
IL_PROBE_DIR <- file.path("data", "evidence", "IL", "probe")
# The agent R/03l archived HFS with (2026-08-28), unchanged.
IL_PROBE_AGENT <- paste0(
  "AHA-RHTP-Tracker/1.0 (American Hospital Association data and policy ",
  "research; +https://www.aha.org)")
IL_HOST_THROTTLE_S <- 3
# The content column of HFS's AEM template (5,488 of 7,508 reduced characters
# on 2026-10-20; the rest is navigation). If it stops matching, the reader
# falls back to <main>, and the menu then trips the name tripwire -- loudly,
# never silently.
IL_HFS_SCOPE <- "div.container.aem-GridColumn--default--9"
IL_GOV_HOST  <- "https://gov-pritzker-newsroom.prezly.com"

IL_PROBE_PAGES <- tibble::tribble(
  ~key,              ~url,                                                         ~file,                                                         ~name_diff, ~scope,
  "hfs_rhtp",        "https://hfs.illinois.gov/info/fedresctr/ruralhealthtp.html", file.path(IL_PROBE_DIR, "2026-10-20_il_hfs_rhtp.html"),        TRUE,       IL_HFS_SCOPE,
  "hfs_stakeholder", "https://hfs.illinois.gov/info/directorsstakeholdernews.html", file.path(IL_PROBE_DIR, "2026-10-20_il_hfs_stakeholder_news.html"), FALSE,  NA_character_,
  "gov_press",       paste0(IL_GOV_HOST, "/category/press-releases"),             file.path(IL_PROBE_DIR, "2026-10-20_il_gov_press_releases.html"), FALSE,   NA_character_
)

# Served bytes, compared by file digest (and, for the sitemap, by slug set).
IL_PROBE_RAW <- tibble::tribble(
  ~key,              ~url,                                                                                                   ~file,
  "planning_method", "https://hfs.illinois.gov/content/dam/soi/en/web/hfs/info/fedresctr/RHTPHospitalPlngGrantMethodologyAccCheckUpdtd.pdf", file.path(IL_PROBE_DIR, "2026-10-20_il_hfs_planning_grant_methodology.pdf"),
  "gov_sitemap",     paste0(IL_GOV_HOST, "/sitemap.xml"),                                                                    file.path(IL_PROBE_DIR, "2026-10-20_il_gov_newsroom_sitemap.xml")
)

# A headline or story slug about Illinois's RHTP money.
IL_RHTP_HEADLINE <- paste0(
  "(?i)rural health transformation|\\bRHTP\\b|\\bHFS\\b|healthcare and family ",
  "services|planning grant|rural hospital|critical access|\\bICAHN\\b|",
  "hospital transformation")
IL_RHTP_SLUG <- paste0(
  "(^|-)(rhtp|hfs|icahn)(-|$)|rural-health|health-transformation|",
  "planning-grant|rural-hospital|critical-access|hospital-transformation|",
  "healthcare-and-family")
# An award sentence. "planning grant" with an award word is the roster this
# watch exists for; the methodology's own "award amount of approximately
# $290,000" is in the PDF, not on the page, so it costs nothing here.
IL_AWARD_SENTENCE <- paste0(
  "(?i)notice of (intent to )?award|awarded to|has awarded|have been awarded|",
  "were awarded|award (recipient|winner)s?|awardees?\\b|grantees\\b|",
  "selected (organi[sz]ations|applicants|hospitals|recipients)|",
  "planning grants?.{0,80}(award|recipient|grantee)")


# -- baselines: the deliberate act (§2.2), never the probe --------------------

#' Fetch one served file into memory (no disk)
il_get <- function(url) rhtp_watch_fetch(url, IL_PROBE_AGENT)

#' Archive served bytes verbatim, with the same manifest line shape
#' rhtp_watch_archive() writes. Refuses a credential-shaped string.
il_archive_raw <- function(url, dest,
                           manifest = file.path(dirname(dest), "MANIFEST.txt")) {
  raw <- il_get(url)
  if (length(grepRaw(paste0(IL_CREDENTIAL_RE, "|accessToken"), raw))) {
    stop("[IL] ", url, " carries a credential-shaped string; not archived.",
         call. = FALSE)
  }
  dir.create(dirname(here::here(dest)), recursive = TRUE, showWarnings = FALSE)
  writeBin(raw, here::here(dest))
  sha <- digest::digest(raw, algo = "sha256", serialize = FALSE)
  line <- paste(sha, basename(dest), url, paste0("full_page_sha256=", sha),
                format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  ")
  cat(line, "\n", file = here::here(manifest), append = TRUE, sep = "")
  invisible(dest)
}

# The credential shapes R/03l met on this host (a Mapbox public token).
IL_CREDENTIAL_RE <- "[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[A-Za-z0-9_-]{20,}"

#' Archive an HTML page script-stripped AND with every element that carries a
#' credential-shaped ATTRIBUTE removed. HFS's AEM template puts its Mapbox
#' token in `<map-details api-key="pk...">`, outside any script, so
#' rhtp_watch_archive() correctly refuses it. The element has no text and no
#' links, so neither the reduced text nor the link set changes.
il_archive_html <- function(url, dest,
                            manifest = file.path(dirname(dest), "MANIFEST.txt")) {
  raw <- il_get(url)
  h <- xml2::read_html(raw)
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  for (n in xml2::xml_find_all(h, "//*[@*]")) {
    if (any(grepl(IL_CREDENTIAL_RE, xml2::xml_attrs(n), perl = TRUE))) {
      xml2::xml_remove(n)
    }
  }
  dir.create(dirname(here::here(dest)), recursive = TRUE, showWarnings = FALSE)
  xml2::write_html(h, here::here(dest))
  written <- readBin(here::here(dest), "raw", file.info(here::here(dest))$size)
  if (length(grepRaw(paste0(IL_CREDENTIAL_RE, "|accessToken"), written))) {
    unlink(here::here(dest))
    stop("[IL] ", dest, " still carries a credential-shaped string after ",
         "reduction; not archived.", call. = FALSE)
  }
  line <- paste(digest::digest(written, algo = "sha256", serialize = FALSE),
                basename(dest), url,
                paste0("full_page_sha256=",
                       digest::digest(raw, algo = "sha256", serialize = FALSE)),
                format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  ")
  cat(line, "\n", file = here::here(manifest), append = TRUE, sep = "")
  invisible(dest)
}

il_probe_fetch <- function(force = FALSE) {
  for (i in seq_len(nrow(IL_PROBE_PAGES))) {
    f <- IL_PROBE_PAGES$file[i]
    if (file.exists(here::here(f)) && !force) next
    il_archive_html(IL_PROBE_PAGES$url[i], f)
    message("[IL] archived ", f)
    Sys.sleep(IL_HOST_THROTTLE_S)
  }
  for (i in seq_len(nrow(IL_PROBE_RAW))) {
    f <- IL_PROBE_RAW$file[i]
    if (file.exists(here::here(f)) && !force) next
    il_archive_raw(IL_PROBE_RAW$url[i], f)
    message("[IL] archived ", f)
    Sys.sleep(IL_HOST_THROTTLE_S)
  }
  invisible(c(IL_PROBE_PAGES$file, IL_PROBE_RAW$file))
}


# -- readers ------------------------------------------------------------------

#' Every link inside a page region, as an absolute URL without its fragment
il_links <- function(raw, scope = NULL, base = "https://hfs.illinois.gov") {
  h <- xml2::read_html(raw)
  node <- if (!is.null(scope)) rvest::html_element(h, scope) else h
  if (inherits(node, "xml_missing")) node <- h
  href <- rvest::html_attr(rvest::html_elements(node, "a[href]"), "href")
  href <- sub("#.*$", "", stringr::str_squish(href))
  href <- href[nzchar(href) & !grepl("^(mailto|tel|javascript):", href)]
  href <- ifelse(grepl("^https?://", href), href, xml2::url_absolute(href, base))
  sort(unique(href))
}

#' Every story URL the newsroom sitemap lists, as a slug
il_sitemap_slugs <- function(raw) {
  txt <- if (is.raw(raw)) rawToChar(raw) else paste(readLines(raw, warn = FALSE),
                                                    collapse = "\n")
  loc <- stringr::str_match_all(txt, "<loc>([^<]+)</loc>")[[1]][, 2]
  slug <- sub("^https?://[^/]+/?", "", loc)
  sort(unique(slug[nzchar(slug) & !grepl("^category/", slug)]))
}

#' The headlines a Prezly category page links, one per story
il_press_headlines <- function(raw) {
  h <- xml2::read_html(raw)
  a <- rvest::html_elements(h, "a[href^='/']")
  href <- rvest::html_attr(a, "href")
  hl <- stringr::str_squish(rvest::html_text2(a))
  keep <- nchar(hl) > 25 & !grepl("^/(category|search|media|contacts)", href)
  sort(unique(hl[keep]))
}

#' Every currency figure on a page ("$28.2 million", "$28,191,393.00")
il_money <- function(text) {
  unique(stringr::str_extract_all(
    text, "\\$\\s?[0-9][0-9,]*(\\.[0-9]+)?(\\s?(million|billion|thousand)|[MBK]\\b)?")[[1]])
}


# -- the checks: each returns findings, never throws --------------------------

#' HFS's RHTP page: new links, award sentences and currency figures
il_hfs_findings <- function(live_raw, arch_raw, live_txt, arch_txt) {
  out <- character(0)
  new_links <- setdiff(il_links(live_raw, IL_HFS_SCOPE),
                       il_links(arch_raw, IL_HFS_SCOPE))
  if (length(new_links)) {
    out <- c(out, paste0("HFS_RHTP: NEW LINK(S) in the content column: ",
      paste0("\"", rhtp_watch_quote(new_links), "\"", collapse = " | "),
      ". HFS publishes every RHTP document as a link here. Read it: a ",
      "Hospital Planning Grant roster (97 eligible, $28,191,393 pool) is the ",
      "thing this watch exists for, and a roster of RECIPIENTS is hospital ",
      "money; the eligibility list is not (§0.3)."))
  }
  new_s <- rhtp_watch_new_sentences(live_txt, arch_txt, IL_AWARD_SENTENCE)
  if (length(new_s)) {
    out <- c(out, paste0("HFS_RHTP: NEW award sentence(s): ",
      paste0("\"", rhtp_watch_quote(substr(utils::head(new_s, 6), 1, 300)),
             "\"", collapse = " | "), ". Read the page and extract whom it ",
      "names; code each award off the award (§10.2)."))
  }
  new_money <- setdiff(il_money(live_txt), il_money(arch_txt))
  if (length(new_money)) {
    ctx <- unlist(lapply(new_money, function(m) stringr::str_extract(
      live_txt, paste0(".{0,90}", stringr::str_replace_all(
        m, "([$.])", "\\\\\\1"), ".{0,60}"))))
    out <- c(out, paste0("HFS_RHTP: NEW currency figure(s): ",
      paste0("\"", rhtp_watch_quote(stats::na.omit(ctx)), "\"",
             collapse = " | "),
      ". Read it: a pool or plan line is Tier 2 (§0.2); a priced recipient ",
      "is an award."))
  }
  out
}

#' The Governor's newsroom: new RHTP headlines and new RHTP story slugs
il_gov_findings <- function(press_live, press_arch, sitemap_live, sitemap_arch) {
  out <- character(0)
  nh <- setdiff(il_press_headlines(press_live), il_press_headlines(press_arch))
  nh <- nh[grepl(IL_RHTP_HEADLINE, nh, perl = TRUE)]
  if (length(nh)) {
    out <- c(out, paste0("GOV_PRESS: NEW RHTP headline(s): ",
      paste0("\"", rhtp_watch_quote(nh), "\"", collapse = " | "),
      ". Read the release for named recipients and amounts."))
  }
  ns <- setdiff(il_sitemap_slugs(sitemap_live), il_sitemap_slugs(sitemap_arch))
  ns <- ns[grepl(IL_RHTP_SLUG, ns, ignore.case = TRUE, perl = TRUE)]
  if (length(ns)) {
    out <- c(out, paste0("GOV_SITEMAP: NEW story slug(s) about RHTP, rural ",
      "hospitals or HFS: ", paste0("\"", rhtp_watch_quote(paste0(
        IL_GOV_HOST, "/", ns)), "\"", collapse = " | "),
      ". Read each release for named recipients and amounts."))
  }
  out
}


# -- the probe ----------------------------------------------------------------

il_probe <- function() {
  w <- rhtp_watch_pages(IL_PROBE_PAGES, IL_PROBE_AGENT)
  raw_live <- list(); raw_changed <- logical(0)
  for (i in seq_len(nrow(IL_PROBE_RAW))) {
    k <- IL_PROBE_RAW$key[i]
    f <- here::here(IL_PROBE_RAW$file[i])
    if (!file.exists(f)) {
      stop("[IL] no archived copy of '", k, "' at ", IL_PROBE_RAW$file[i],
           ". A watched page with no baseline is not watched (§0.4).",
           call. = FALSE)
    }
    Sys.sleep(IL_HOST_THROTTLE_S)
    url <- IL_PROBE_RAW$url[i]
    raw_live[[k]] <- rhtp_probe_get(k, function() il_get(url), f)
    raw_changed[k] <- !identical(
      digest::digest(raw_live[[k]], algo = "sha256", serialize = FALSE),
      digest::digest(file = f, algo = "sha256"))
  }
  arch_file <- function(k) here::here(IL_PROBE_PAGES$file[IL_PROBE_PAGES$key == k])
  sitemap_arch <- here::here(IL_PROBE_RAW$file[IL_PROBE_RAW$key == "gov_sitemap"])
  # The sitemap is compared by its SLUG SET: Prezly may reorder or re-stamp it
  # without publishing anything, and only a new story is a change.
  raw_changed["gov_sitemap"] <- !identical(
    il_sitemap_slugs(raw_live$gov_sitemap), il_sitemap_slugs(sitemap_arch))

  findings <- c(
    il_hfs_findings(w$raw$hfs_rhtp, arch_file("hfs_rhtp"),
                    w$live_all$hfs_rhtp, w$arch_all$hfs_rhtp),
    il_gov_findings(w$raw$gov_press, arch_file("gov_press"),
                    raw_live$gov_sitemap, sitemap_arch))

  # THE NAME TRIPWIRE (§2.3), on the subject page only (scoped).
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = IL_STATE)

  changed <- c(stats::setNames(w$changed$changed, w$changed$key), raw_changed)
  message("[IL] ", paste0(names(changed), ": ",
                          ifelse(changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "))
  for (f in findings) message("[IL]   ", f)
  invisible(list(changed = unname(changed), findings = findings,
                 sources = stats::setNames(
                   lapply(changed, function(x) list(changed = x)),
                   names(changed))))
}


if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch-probe" %in% args) il_probe_fetch(force = "--force" %in% args)
  if ("--probe" %in% args) rhtp_probe_run(IL_STATE, il_probe())
  if (!length(args)) {
    message("Usage: --fetch-probe [--force] | --probe")
  }
}

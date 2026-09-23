# utils_page_watch.R ----------------------------------------------------------
#
# THE SHARED READ-ONLY PAGE WATCH (session 59).
#
# Five states went on Routines in one session -- Colorado, Virginia, North
# Dakota, Washington and Tennessee -- and four of them had no R file at all.
# Writing the same fetch / reduce / digest loop five times is five places for a
# probe to start writing to data/evidence/ again (§2.2, Texas's twenty-seven
# sessions). So the loop lives here, once, and each state file keeps only what
# is genuinely its own: the pages, the phrase tripwires, and the name tripwire
# call (which a test requires to appear in every file offering --probe).
#
# WHAT THIS DOES NOT DO: it never writes. The baseline is whatever file the
# state file names under data/evidence/, and moving that baseline is a
# `--fetch`, done by a human after reading what changed.

#' The reduced text of an HTML page
#'
#' Scripts, styles, noscript and template bodies are dropped (every rotating
#' token this project has measured on a state host lives in one of them or in
#' an attribute, and html_text2() discards attributes). `<main>` is preferred
#' when the page has one, so navigation mega-menus do not dominate; zero-width
#' characters are stripped BEFORE anything reads a name (§2.3).
#'
#' @param raw A raw vector, a path, or a character string of HTML.
#' @param scope Optional CSS selector to read instead of <main>/<body>.
rhtp_watch_reduce <- function(raw, scope = NULL) {
  h <- xml2::read_html(raw)
  xml2::xml_remove(xml2::xml_find_all(
    h, "//script|//style|//noscript|//template|//svg"))
  node <- NULL
  for (sel in c(scope, "main", "body")) {
    n <- rvest::html_element(h, sel)
    if (!inherits(n, "xml_missing")) { node <- n; break }
  }
  if (is.null(node)) node <- h
  t <- rvest::html_text2(node)
  t <- gsub("[\u200b\u200c\u200d\u2060\ufeff]", "", t)
  stringr::str_squish(t)
}

#' Fetch one page into MEMORY. Never touches disk.
#'
#' A non-200 stops with "HTTP <code>" in the message, which rhtp_probe_run()
#' logs as ERROR -- a statement about our access, never about the state
#' (§0.4).
#'
#' @param cainfo Optional CA file. Used for exactly one host so far (Virginia's
#'   RHT site, which serves its leaf certificate without the intermediate);
#'   verification is never switched off.
rhtp_watch_fetch <- function(url, agent, cainfo = NULL) {
  cfg <- list(httr::user_agent(agent), httr::timeout(90))
  if (!is.null(cainfo)) cfg <- c(cfg, list(httr::config(cainfo = cainfo)))
  resp <- do.call(httr::GET, c(list(url), cfg))
  code <- httr::status_code(resp)
  if (code != 200L) {
    stop("HTTP ", code, " from ", url, call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

#' Fetch every watched page and compare it with its committed archive
#'
#' @param pages A data frame with `key`, `url`, `file` (path under the repo)
#'   and `name_diff` (logical). An optional `scope` column is passed to
#'   rhtp_watch_reduce() for both copies.
#' @return A list: `live` and `arch` (named lists of reduced text for the
#'   name_diff pages), `raw` (named list of live raw bytes, every page),
#'   `live_all`, `arch_all` (reduced text, every page) and `changed`, a tibble
#'   of `key`/`changed` that rhtp_probe_rows() reads as one row per page.
rhtp_watch_pages <- function(pages, agent, cainfo = NULL) {
  out <- list(live = list(), arch = list(), raw = list(),
              live_all = list(), arch_all = list())
  changed <- logical(0)
  scope_of <- function(i) {
    if ("scope" %in% names(pages) && !is.na(pages$scope[i])) pages$scope[i]
    else NULL
  }
  for (i in seq_len(nrow(pages))) {
    k <- pages$key[i]
    f <- here::here(pages$file[i])
    if (!file.exists(f)) {
      stop("[watch] no archived copy of '", k, "' at ", pages$file[i],
           ". A watched page with no baseline is not watched (§0.4).",
           call. = FALSE)
    }
    raw <- rhtp_watch_fetch(pages$url[i], agent, cainfo = cainfo)
    lt <- rhtp_watch_reduce(raw, scope_of(i))
    at <- rhtp_watch_reduce(f, scope_of(i))
    out$raw[[k]] <- raw
    out$live_all[[k]] <- lt
    out$arch_all[[k]] <- at
    changed[k] <- !identical(digest::digest(lt), digest::digest(at))
    if (isTRUE(pages$name_diff[i])) {
      out$live[[k]] <- lt
      out$arch[[k]] <- at
    }
  }
  out$changed <- tibble::tibble(key = names(changed), changed = unname(changed))
  out
}

#' Quote page text inside a tripwire message without it being read as ERROR
#'
#' rhtp_probe_run() calls a failure ERROR when its message mentions HTTP,
#' "connect", "refused", "timeout" or "resolve" -- because those are about our
#' ACCESS. A state programme called "Connecting Care" would turn a real
#' tripwire into an access error. This breaks those words with a zero-width
#' space so the log keeps the two claims apart (§0.4).
rhtp_watch_quote <- function(x) {
  gsub("(?i)(con(?=nect)|ht(?=tp)|ref(?=used)|time(?=out)|res(?=olve))",
       "\\1\u200b", x, perl = TRUE)
}

#' Require every sentence in `must` to still be on a page
#'
#' A dated anchor ("by the end of September 2026") is what makes a negative a
#' finding. When it goes, the page has moved -- which may be the state
#' awarding, and is always worth a human reading. So it is a tripwire.
rhtp_watch_require <- function(text, must, state, page) {
  gone <- must[!vapply(must, function(m) grepl(m, text, fixed = TRUE),
                       logical(1))]
  if (length(gone)) {
    stop("[", state, "] '", page, "' NO LONGER SAYS: ",
         paste0("\"", rhtp_watch_quote(gone), "\"", collapse = "; "),
         ". The dated anchor this watch rests on has moved. Read the page: ",
         "it may have awarded, re-dated, or re-worded (§2.2).", call. = FALSE)
  }
  invisible(TRUE)
}

#' Refuse a page that now carries award language
rhtp_watch_forbid <- function(text, patterns, state, page) {
  hit <- patterns[vapply(patterns, function(p)
    grepl(p, text, ignore.case = TRUE, perl = TRUE), logical(1))]
  if (length(hit)) {
    ctx <- unlist(lapply(hit, function(p) stringr::str_extract(
      text, stringr::regex(paste0(".{0,90}", p, ".{0,90}"), ignore_case = TRUE))))
    stop("[", state, "] '", page, "' NOW CARRIES AWARD LANGUAGE: ",
         paste0("\"", rhtp_watch_quote(stats::na.omit(ctx)), "\"",
                collapse = " | "),
         ". THAT IS THE SIGNAL. Read the page and extract what it names.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Sentences on the live page, matching a pattern, that the archive lacks
#'
#' The phrase-list half of the watch, done as a DIFF so that a sentence the
#' baseline already carries ("HCPF has awarded a contract to the Colorado Rural
#' Health Center ...") costs nothing, and only a NEW sentence can fire.
rhtp_watch_new_sentences <- function(live, arch, pattern) {
  split <- function(t) {
    s <- unlist(strsplit(t, "(?<=[.!?])\\s+|\\s{2,}", perl = TRUE))
    stringr::str_squish(s[nzchar(s)])
  }
  l <- split(live)
  a <- unique(split(arch))
  hit <- l[grepl(pattern, l, ignore.case = TRUE, perl = TRUE)]
  unique(setdiff(hit, a))
}

#' ... and the tripwire built on it
rhtp_watch_forbid_new <- function(live, arch, pattern, state, page, why) {
  new <- rhtp_watch_new_sentences(live, arch, pattern)
  if (length(new)) {
    stop("[", state, "] '", page, "' HAS ", length(new), " NEW SENTENCE(S) ",
         "OF THE KIND THIS WATCH EXISTS FOR: ",
         paste0("\"", rhtp_watch_quote(substr(utils::head(new, 6), 1, 300)),
                "\"", collapse = " | "),
         ". ", why, call. = FALSE)
  }
  invisible(TRUE)
}

#' Archive a page for a watch BASELINE -- the deliberate act (§2.2)
#'
#' Called only from a state file's `--fetch`, never from a probe. Script,
#' style and noscript bodies are removed BEFORE writing, because state CMS
#' templates embed third-party credentials there (Tennessee's Coveo search
#' token, Illinois's Mapbox key, Oregon's Google Maps key) and those are not
#' ours to redistribute. The digest recorded is of the bytes AS WRITTEN, plus
#' the full page as served, so provenance still closes.
rhtp_watch_archive <- function(url, dest, agent, cainfo = NULL,
                               manifest = file.path(dirname(dest), "MANIFEST.txt")) {
  raw <- rhtp_watch_fetch(url, agent, cainfo = cainfo)
  h <- xml2::read_html(raw)
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  dir.create(dirname(here::here(dest)), recursive = TRUE, showWarnings = FALSE)
  xml2::write_html(h, here::here(dest))
  written <- readBin(here::here(dest), "raw", file.info(here::here(dest))$size)
  txt <- rawToChar(written)
  if (grepl("AIza[0-9A-Za-z_-]{20,}|pk\\.ey[0-9A-Za-z_-]{20,}|accessToken", txt)) {
    unlink(here::here(dest))
    stop("[watch] ", dest, " still carries a credential-shaped string after ",
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

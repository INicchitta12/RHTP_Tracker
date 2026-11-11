# 09a_usaspending_rhtp.R -------------------------------------------------------
# USAspending.gov: the 50 RHTP prime awards and their FFATA first-tier
# subawards (session 116b).
#
# RHTP is Assistance Listing 93.798 ("Rural Health Transformation Program",
# popular name "RHT Program"), confirmed against USAspending's own CFDA
# autocomplete on 2026-11-09. CMS's 50 prime awards are cooperative agreements
# (FAIN RHTCMS33....) and the states report their first-tier subawards of
# $30,000 or more through SAM.gov's FFATA subaward reporting (formerly FSRS),
# which USAspending republishes.
#
# WHAT THIS SOURCE IS AND IS NOT.
#   * It is the STATE'S OWN FFATA report of a first-tier subaward, filed in SAM
#     under the state's prime award. It carries the subrecipient's UEI and
#     ADDRESS, which is why it is the best source this project has for
#     out-of-state status (a source address, not general knowledge).
#   * It is NOT a census of where RHTP money went. 2 CFR 170 App. A: a subaward
#     "does not include your procurement of property and services needed to
#     carry out the project". A state's CONTRACT with a consulting firm is a
#     procurement and is not reportable, so the largest consulting contracts
#     (Kansas's BCG line, for one) do not appear here at all. Some states report
#     contractors anyway (New Mexico's Guidehouse, Delaware's Deloitte/Manatt).
#   * 19 states had filed NO subaward under 93.798 when this was pulled.
#     Silence is a statement about the state's FFATA filing, never about its
#     awards (§0.4).
#   * The subaward amount is the amount the state reported for that action. It
#     is never summed with an award file or a hospital bucket, and it changes
#     no award row here (session 116b is a read-only layer).
#
# The search endpoints (`/search/spending_by_award/`) return ZERO rows for
# 93.798 while `/search/spending_by_award_count/` returns 50 grants and 2,025
# subgrants (measured 2026-11-09): the category and download endpoints work and
# the award search does not. So the fetch uses the custom award DOWNLOAD
# (`/api/v2/download/awards/`), which is asynchronous: request, poll, fetch the
# zip. `/api/v2/bulk_download/awards/` silently DROPPED the program filter on
# the same day (it echoed back a request for every grant nationally), which is
# why it is not used.
#
# CLI
#   Rscript R/09a_usaspending_rhtp.R --fetch      # request, poll, archive zip + manifest
#   RHTP_PROBE_ORIGIN=interactive Rscript R/09a_usaspending_rhtp.R --probe
#                                                 # READ-ONLY weekly watch (session 116d): live
#                                                 # report ids vs the archive; trips per state
#   Rscript R/09a_usaspending_rhtp.R --validate   # assertions on the archive, offline
#   Rscript R/09a_usaspending_rhtp.R --build      # data/reference/usaspending_rhtp_*.csv
#   Rscript R/09a_usaspending_rhtp.R --report

source(here::here("R", "utils_config.R"))   # rhtp_probe_run() for --probe
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

USA_ALN <- "93.798"
USA_API <- "https://api.usaspending.gov/api/v2"
USA_AGENT <- "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)"
USA_AS_OF <- "2026-11-09"
USA_RAW_DIR <- function(as_of = USA_AS_OF) here::here("data", "raw", "usaspending", as_of)
USA_ZIP <- "usaspending_rhtp_93798_prime_and_subawards.zip"
USA_SUB_CSV <- "data/reference/usaspending_rhtp_subawards.csv"
USA_COVERAGE_CSV <- "data/reference/usaspending_rhtp_coverage_by_state.csv"

# What the 2026-11-09 archive holds, pinned so a re-fetch that differs is read,
# not absorbed.
USA_EXPECT <- list(primes = 50L, prime_total = 1e10, sub_rows = 2025L,
                   sub_states = 31L, sub_total = 2822602267.02)

usa_request_body <- function(end_date = USA_AS_OF) {
  list(
    filters = list(
      program_numbers = list(USA_ALN),
      prime_and_sub_award_types = list(prime_awards = list("02", "03", "04", "05"),
                                       sub_awards = list("grant")),
      time_period = list(list(start_date = "2007-10-01", end_date = end_date))
    ),
    file_format = "csv"
  )
}

usa_post <- function(path, body, tries = 4) {
  for (i in seq_len(tries)) {
    r <- tryCatch(httr::POST(paste0(USA_API, path), body = body, encode = "json",
                             httr::user_agent(USA_AGENT), httr::timeout(180)),
                  error = function(e) e)
    if (!inherits(r, "error") && httr::status_code(r) == 200) {
      return(httr::content(r, as = "parsed", simplifyVector = TRUE))
    }
    Sys.sleep(2^i)
  }
  stop("[usaspending] POST ", path, " failed after ", tries, " tries", call. = FALSE)
}

#' Request, poll and download the custom award zip to `dest`. Refuses a download
#' whose echoed filter is not 93.798 (the bulk endpoint dropped it once).
usa_download <- function(dest, end_date, poll_seconds = 15, max_polls = 80) {
  req <- usa_request_body(end_date)
  resp <- usa_post("/download/awards/", req)
  echoed <- resp$download_request$filters$program_numbers
  if (!identical(as.character(echoed), USA_ALN)) {
    stop("[usaspending] the download request did not keep the 93.798 filter ",
         "(echoed: ", paste(echoed, collapse = ","), "). Refusing to fetch a ",
         "national file.", call. = FALSE)
  }
  status <- NULL
  for (i in seq_len(max_polls)) {
    st <- httr::GET(resp$status_url, httr::user_agent(USA_AGENT), httr::timeout(60))
    status <- httr::content(st, as = "parsed", simplifyVector = TRUE)
    if (identical(status$status, "finished")) break
    if (identical(status$status, "failed")) stop("[usaspending] download failed: ", status$message, call. = FALSE)
    Sys.sleep(poll_seconds)
  }
  if (!identical(status$status, "finished")) stop("[usaspending] download never finished", call. = FALSE)
  g <- httr::GET(resp$file_url, httr::user_agent(USA_AGENT), httr::timeout(600),
                 httr::write_disk(dest, overwrite = TRUE))
  httr::stop_for_status(g)
  invisible(list(req = req, resp = resp, dest = dest))
}

#' READ-ONLY weekly watch (session 116d). Downloads the live 93.798 file into a
#' temporary directory -- never data/raw or data/evidence -- and compares each
#' state's FFATA subaward report ids with the committed archive. A state that
#' has filed subawards the archive does not hold trips (one finding per state);
#' re-archiving is `--fetch` with a new USA_AS_OF, a deliberate act after
#' reading what changed (§2.2).
usa_probe <- function(as_of = USA_AS_OF) {
  td <- tempfile("usa_probe"); dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)
  live_zip <- file.path(td, USA_ZIP)
  usa_download(live_zip, format(Sys.Date(), "%Y-%m-%d"))
  read_sub <- function(zip) {
    m <- utils::unzip(zip, list = TRUE)$Name
    m <- m[grepl("^Assistance_Subawards_", m)]
    utils::unzip(zip, files = m, exdir = td)
    readr::read_csv(file.path(td, m), col_types = readr::cols(.default = "c"), progress = FALSE, na = character())
  }
  live <- read_sub(live_zip)
  old <- usa_read("sub", as_of)
  st <- function(d) dplyr::if_else(d$prime_awardee_state_code == "", d$prime_award_primary_place_of_performance_state_code,
                                   d$prime_awardee_state_code)
  live$st <- st(live); old$st <- st(old)
  new <- live[!live$subaward_sam_report_id %in% old$subaward_sam_report_id, ]
  gone <- old[!old$subaward_sam_report_id %in% live$subaward_sam_report_id, ]
  states <- sort(unique(c(live$st, old$st)))
  res <- tibble::tibble(page = paste0("FSRS ", states),
                        changed = vapply(states, function(x) any(new$st == x) || any(gone$st == x), logical(1)))
  agg <- new %>% dplyr::group_by(st) %>%
    dplyr::summarise(n = dplyr::n(), usd = sum(as.numeric(subaward_amount)), .groups = "drop")
  findings <- if (nrow(agg)) paste0(agg$st, ": ", agg$n, " FFATA subaward report(s) not in the ", as_of,
                                    " archive ($", format(round(agg$usd), big.mark = ","), "); read them, then re-archive with --fetch") else character(0)
  # SESSION 116f: a new filing whose recipient is in the vendor dictionary or
  # carries an out-of-state address is logged VENDOR (never raised).
  for (m in usa_vendor_flags(new)) {
    if (rhtp_probe_ctx_active()) rhtp_probe_note("vendor", "FSRS new filings", m)
    message(m)
  }
  list(changed = res$page[res$changed], findings = findings)
}

#' New FSRS filings whose recipient is in config/vendor_entity_dictionary.csv
#' (any class) or whose registered address is outside the awarding state.
#' @param new subaward rows (USAspending columns plus `st`, the awarding state)
#' @return one message per flagged filing
usa_vendor_flags <- function(new) {
  if (!nrow(new)) return(character(0))
  dict <- readr::read_csv(here::here("config", "vendor_entity_dictionary.csv"),
                          col_types = readr::cols(.default = "c"), progress = FALSE, na = character())
  in_dict <- vapply(new$subawardee_name, function(n) {
    hit <- vapply(dict$pattern, function(p) stringr::str_detect(n, stringr::regex(p, ignore_case = TRUE)), logical(1))
    if (any(hit)) dict$canonical_name[which(hit)[1]] else NA_character_
  }, character(1), USE.NAMES = FALSE)
  oos <- nzchar(new$subawardee_state_code) & new$subawardee_state_code != new$st
  flag <- !is.na(in_dict) | oos
  if (!any(flag)) return(character(0))
  f <- new[flag, , drop = FALSE]
  paste0("[FSRS] ", RHTP_VENDOR_SIGNATURE, ": new ", f$st, " FFATA filing to ", f$subawardee_name, " ($",
         format(round(as.numeric(f$subaward_amount)), big.mark = ","), ", ", f$subawardee_city_name, ", ",
         f$subawardee_state_code, ")",
         ifelse(!is.na(in_dict[flag]), paste0(" -- in the vendor dictionary as ", in_dict[flag]), ""),
         ifelse(oos[flag], " -- registered address outside the awarding state", ""),
         ". Read it before R/09a --fetch re-archives (session 116f).")
}

usa_fetch <- function(as_of = USA_AS_OF, poll_seconds = 15, max_polls = 80) {
  dir <- USA_RAW_DIR(as_of)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  req <- usa_request_body(as_of)
  resp <- usa_post("/download/awards/", req)
  echoed <- resp$download_request$filters$program_numbers
  if (!identical(as.character(echoed), USA_ALN)) {
    stop("[usaspending] the download request did not keep the 93.798 filter ",
         "(echoed: ", paste(echoed, collapse = ","), "). Refusing to fetch a ",
         "national file.", call. = FALSE)
  }
  status <- NULL
  for (i in seq_len(max_polls)) {
    s <- httr::GET(resp$status_url, httr::user_agent(USA_AGENT), httr::timeout(60))
    status <- httr::content(s, as = "parsed", simplifyVector = TRUE)
    if (identical(status$status, "finished")) break
    if (identical(status$status, "failed")) stop("[usaspending] download failed: ",
                                                 status$message, call. = FALSE)
    Sys.sleep(poll_seconds)
  }
  if (!identical(status$status, "finished")) stop("[usaspending] download never finished",
                                                  call. = FALSE)
  zip <- file.path(dir, USA_ZIP)
  g <- httr::GET(resp$file_url, httr::user_agent(USA_AGENT), httr::timeout(600),
                 httr::write_disk(zip, overwrite = TRUE))
  httr::stop_for_status(g)
  sha <- digest::digest(file = zip, algo = "sha256")
  man <- c(
    paste0("source: USAspending.gov custom award download, Assistance Listing ", USA_ALN),
    paste0("request: POST ", USA_API, "/download/awards/"),
    paste0("request_body: ", jsonlite::toJSON(req, auto_unbox = TRUE)),
    paste0("echoed_filters: ", jsonlite::toJSON(resp$download_request$filters, auto_unbox = TRUE)),
    paste0("file_url: ", resp$file_url),
    paste0("fetched_at_utc: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    paste0("sha256: ", sha),
    paste0("bytes: ", file.size(zip)),
    "note: FFATA first-tier subawards as reported by the prime recipient (the state) in SAM.gov; procurement contracts under the grant are NOT reportable subawards (2 CFR 170 App. A)."
  )
  writeLines(man, paste0(zip, ".manifest.txt"))
  message("[usaspending] archived ", zip, " (", file.size(zip), " bytes, sha256 ", sha, ")")
  invisible(zip)
}

usa_read <- function(kind = c("sub", "prime"), as_of = USA_AS_OF) {
  kind <- match.arg(kind)
  zip <- file.path(USA_RAW_DIR(as_of), USA_ZIP)
  if (!file.exists(zip)) stop("[usaspending] no archive at ", zip, call. = FALSE)
  members <- utils::unzip(zip, list = TRUE)$Name
  want <- if (kind == "sub") "^Assistance_Subawards_" else "^Assistance_PrimeAwardSummaries_"
  m <- members[grepl(want, members)]
  if (length(m) != 1) stop("[usaspending] expected one ", want, " member, found ",
                           length(m), call. = FALSE)
  td <- tempfile("usa"); dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)
  utils::unzip(zip, files = m, exdir = td)
  readr::read_csv(file.path(td, m), col_types = readr::cols(.default = "c"),
                  progress = FALSE, na = character())
}

#' One row per reported subaward, the columns this project reads
usa_subawards <- function(as_of = USA_AS_OF) {
  s <- usa_read("sub", as_of)
  s %>%
    dplyr::transmute(
      prime_state = dplyr::if_else(prime_awardee_state_code == "",
                                   prime_award_primary_place_of_performance_state_code,
                                   prime_awardee_state_code),
      prime_award_fain, prime_awardee_name,
      subaward_number, subaward_action_date,
      subaward_amount = as.numeric(subaward_amount),
      subawardee_name, subawardee_uei, subawardee_parent_name,
      subawardee_city_name, subawardee_state_code,
      subawardee_business_types,
      subaward_description = stringr::str_squish(subaward_description),
      subaward_sam_report_id, subaward_sam_report_last_modified_date,
      usaspending_permalink
    )
}

usa_coverage <- function(as_of = USA_AS_OF) {
  p <- usa_read("prime", as_of) %>%
    dplyr::transmute(prime_state = recipient_state_code, award_id_fain,
                     recipient_name,
                     prime_obligated = as.numeric(total_obligated_amount))
  s <- usa_subawards(as_of) %>%
    dplyr::group_by(prime_state) %>%
    dplyr::summarise(subaward_rows = dplyr::n(),
                     subaward_reported_total = round(sum(subaward_amount), 2),
                     out_of_state_rows = sum(subawardee_state_code != prime_state),
                     last_report_modified = max(subaward_sam_report_last_modified_date),
                     .groups = "drop")
  p %>% dplyr::left_join(s, by = "prime_state") %>%
    dplyr::mutate(subaward_rows = dplyr::coalesce(subaward_rows, 0L),
                  reports_subawards = subaward_rows > 0,
                  as_of = as_of) %>%
    dplyr::arrange(prime_state)
}

usa_validate <- function(as_of = USA_AS_OF) {
  p <- usa_read("prime", as_of)
  s <- usa_subawards(as_of)
  stopifnot(
    nrow(p) == USA_EXPECT$primes,
    all(grepl("93.798", p$cfda_numbers_and_titles %||% p[[grep("cfda", names(p))[1]]], fixed = TRUE)),
    abs(sum(as.numeric(p$total_obligated_amount)) - USA_EXPECT$prime_total) < 1,
    nrow(s) == USA_EXPECT$sub_rows,
    dplyr::n_distinct(s$prime_state) == USA_EXPECT$sub_states,
    abs(sum(s$subaward_amount) - USA_EXPECT$sub_total) < 0.01,
    !anyNA(s$subaward_amount)
  )
  message("[usaspending] archive ", as_of, ": ", nrow(p), " primes, ", nrow(s),
          " subawards in ", dplyr::n_distinct(s$prime_state), " states. OK.")
  invisible(TRUE)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

usa_build <- function(as_of = USA_AS_OF) {
  usa_validate(as_of)
  s <- usa_subawards(as_of) %>%
    dplyr::mutate(as_of = as_of,
                  archive_path = file.path("data/raw/usaspending", as_of, USA_ZIP))
  readr::write_csv(s, here::here(USA_SUB_CSV), na = "")
  readr::write_csv(usa_coverage(as_of), here::here(USA_COVERAGE_CSV), na = "")
  message("[usaspending] wrote ", USA_SUB_CSV, " and ", USA_COVERAGE_CSV)
}

usa_report <- function(as_of = USA_AS_OF) {
  cv <- usa_coverage(as_of)
  cat("USAspending RHTP (", USA_ALN, "), as of ", as_of, "\n", sep = "")
  cat("  prime awards:", nrow(cv), " obligated $", format(sum(cv$prime_obligated), big.mark = ",", scientific = FALSE), "\n")
  cat("  states reporting subawards:", sum(cv$reports_subawards), "of", nrow(cv), "\n")
  cat("  subaward rows:", sum(cv$subaward_rows), " reported $",
      format(round(sum(cv$subaward_reported_total, na.rm = TRUE), 2), big.mark = ",", nsmall = 2), "\n")
  cat("  not reporting:", paste(cv$prime_state[!cv$reports_subawards], collapse = " "), "\n")
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) usa_fetch()
  if ("--probe" %in% args) rhtp_probe_run("FSRS", usa_probe())
  if ("--validate" %in% args) usa_validate()
  if ("--build" %in% args) usa_build()
  if ("--report" %in% args) usa_report()
}

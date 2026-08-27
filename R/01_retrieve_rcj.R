# 01_retrieve_rcj.R -----------------------------------------------------------
# Stage 1 -- Retrieval -- build spec §5
#
# CONTRACT: pull RCJ records to an immutable dated landing zone. Never
# transform in this stage. Every downstream stage reads from data/raw/, never
# from a live call, so development and re-runs cost zero quota (§5.2).
#
# STRATEGY: Branch A, confirmed live in Session 2 (§5.1, docs/stage1_pagination_test.md).
# Pull nationally at max `limit` with no `state` filter; partition by state in
# Stage 2. Measured cost ~46 calls per full pull; twice-weekly cadence is ~20%
# of the 2,000/month Pro allowance.
#
# THE LIVE TRAP (§5.2): `/documents?limit=500` returns HTTP 200 while serving
# 100 rows and echoing `pagination.limit: 100`. Over-max limits are silently
# downgraded -- neither honoured nor rejected. A client that trusted its own
# requested limit would walk 7 pages, read 700 of 3,092 records, and report
# success. Page counts and totals are therefore computed from the RESPONSE
# envelope, always: see rhtp_page_plan(), which is pure and unit-tested in
# tests/testthat/test_01_retrieve_rcj.R.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().
#
# CREDENTIAL RULE: the API key never reaches the console, the manifest, or a
# file. The auth header is registered with httr2 as redacted, and every string
# written to the manifest passes through rhtp_redact().

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))


# -- Run state -------------------------------------------------------------

# Per-run request accounting, independent of the monthly figure the API
# reports. Belt and braces against a pagination bug turning into a runaway
# walk that eats the month's allowance.
.rhtp_run_state <- new.env(parent = emptyenv())

rhtp_reset_run_state <- function() {
  .rhtp_run_state$requests <- 0L
  .rhtp_run_state$started_at <- Sys.time()
  invisible(NULL)
}

rhtp_run_requests <- function() {
  if (is.null(.rhtp_run_state$requests)) 0L else .rhtp_run_state$requests
}

rhtp_reset_run_state()


# -- Pagination arithmetic (pure, unit-tested) -----------------------------

#' Decide how many pages to walk, from the response envelope only
#'
#' The single most important function in this stage. It deliberately ignores
#' `requested_limit` when computing the page count and uses the served limit
#' the server echoed back, because the server silently downgrades over-max
#' limits (§5.2). `requested_limit` is used only to detect and report that
#' downgrade.
#'
#' `pages_reported` is cross-checked rather than trusted: if the server's own
#' page count disagrees with the arithmetic, we walk whichever is larger and
#' flag it, because under-walking is the failure mode that loses records
#' silently while over-walking merely costs one call that returns nothing.
#'
#' @param requested_limit The `limit` this client asked for.
#' @param served_limit `pagination.limit` from the response.
#' @param total `pagination.total` from the response.
#' @param pages_reported `pagination.pages` from the response. May be NULL.
#' @return A list: pages_needed, limit_downgraded, pages_mismatch, and the
#'   inputs, for the manifest and the pull metadata.
rhtp_page_plan <- function(requested_limit, served_limit, total,
                           pages_reported = NULL) {
  if (!is.numeric(served_limit) || length(served_limit) != 1 ||
        is.na(served_limit) || served_limit < 1) {
    stop(
      "Response envelope carried no usable pagination.limit (got: ",
      paste(utils::capture.output(str(served_limit)), collapse = " "), "). ",
      "Refusing to guess a page count -- that is the silent short-read in §5.2.",
      call. = FALSE
    )
  }

  if (!is.numeric(total) || length(total) != 1 || is.na(total) || total < 0) {
    stop(
      "Response envelope carried no usable pagination.total. Refusing to guess ",
      "a page count -- exhaustiveness cannot be asserted without it (§5.2).",
      call. = FALSE
    )
  }

  pages_needed <- if (total == 0) 0L else as.integer(ceiling(total / served_limit))

  pages_mismatch <- FALSE
  if (!is.null(pages_reported) && !is.na(pages_reported)) {
    pages_reported <- as.integer(pages_reported)
    if (!identical(pages_reported, pages_needed)) {
      pages_mismatch <- TRUE
      pages_needed <- max(pages_needed, pages_reported)
    }
  }

  list(
    requested_limit  = as.integer(requested_limit),
    served_limit     = as.integer(served_limit),
    total            = as.integer(total),
    pages_reported   = if (is.null(pages_reported)) NA_integer_ else as.integer(pages_reported),
    pages_needed     = pages_needed,
    limit_downgraded = !identical(as.integer(requested_limit), as.integer(served_limit)),
    pages_mismatch   = pages_mismatch
  )
}


# -- Request construction --------------------------------------------------

#' Build a configured httr2 request
#'
#' Applies auth (redacted), user agent, timeout, client-side throttle, and
#' retry policy from config.yml. No network call happens here.
#'
#' Throttle: config sets 40/min against a documented ceiling of 60/min. No
#' per-minute header exists to warn us how close we are (§4), so the margin is
#' the only protection.
rhtp_build_request <- function(url, query = list(), method = "GET", body = NULL) {
  cfg <- rhtp_config()

  headers <- rhtp_auth_headers()
  secret_headers <- headers[names(headers) != "Accept"]
  open_headers <- headers[names(headers) == "Accept"]

  retry_status <- unlist(cfg$retry$retry_on_status)
  backoff_base <- cfg$retry$backoff_base_seconds
  backoff_max <- cfg$retry$backoff_max_seconds

  req <- httr2::request(url) %>%
    httr2::req_headers(!!!open_headers) %>%
    # Registers the value as a secret with httr2: it is masked in verbose
    # output, in printed requests, and in error dumps.
    httr2::req_headers_redacted(!!!secret_headers) %>%
    httr2::req_user_agent(cfg$api$user_agent) %>%
    httr2::req_timeout(cfg$api$timeout_seconds) %>%
    httr2::req_throttle(
      capacity = cfg$quota$throttle_requests_per_minute,
      fill_time_s = 60
    ) %>%
    httr2::req_retry(
      max_tries = cfg$retry$max_tries,
      is_transient = function(resp) httr2::resp_status(resp) %in% retry_status,
      # Honour Retry-After when the server sends it (§5.2); fall back to
      # exponential backoff when it does not.
      after = httr2::resp_retry_after,
      backoff = function(i) min(backoff_base^i, backoff_max)
    )

  if (length(query) > 0) {
    req <- req %>% httr2::req_url_query(!!!query)
  }

  if (identical(method, "POST")) {
    req <- req %>% httr2::req_body_json(body)
  }

  req
}


#' Render a query list as a short, redacted string for the manifest
rhtp_format_params <- function(query) {
  if (length(query) == 0) {
    return("")
  }

  paste0(names(query), "=", unlist(purrr::map(query, as.character)),
         collapse = ";") %>%
    rhtp_redact()
}


# -- Manifest --------------------------------------------------------------

# Canonical manifest schema. Session 0 established the first eleven columns;
# `requested_limit` and `served_limit` are added here because §5.2 requires
# both to be logged -- their divergence is the silent-downgrade signal, and it
# cannot be reconstructed after the fact.
#
# Column ORDER is load-bearing: readr::write_csv(append = TRUE) writes values
# positionally and will happily append a misaligned row to an existing file
# without complaint. rhtp_append_manifest() therefore checks the header of the
# file it is about to extend and refuses to write on a mismatch.

RHTP_MANIFEST_COLUMNS <- c(
  "pull_timestamp_utc",
  "pull_date",
  "state",
  "endpoint",
  "params",
  "http_status",
  "records_returned",
  "records_reported",
  "requested_limit",
  "served_limit",
  "quota_monthly_limit",
  "quota_monthly_remaining",
  "duration_seconds",
  "stage",
  "notes"
)


#' Build one manifest row in the canonical column order
#'
#' `state` is NA for Branch A pulls: they are national and unfiltered, so no
#' single state applies. It stays in the schema for the per-state calls
#' (`/states/:code`, `/documents/:id`) that later stages will make.
rhtp_manifest_row <- function(timestamp, pull_date, endpoint, params,
                              http_status = NA_integer_,
                              records_returned = NA_integer_,
                              records_reported = NA_integer_,
                              requested_limit = NA_integer_,
                              served_limit = NA_integer_,
                              quota_monthly_limit = NA_real_,
                              quota_monthly_remaining = NA_real_,
                              duration_seconds = NA_real_,
                              state = NA_character_,
                              stage = "stage1_retrieval",
                              notes = "") {
  tibble::tibble(
    pull_timestamp_utc      = format(timestamp, "%Y-%m-%dT%H:%M:%SZ",
                                     tz = "UTC"),
    pull_date               = as.character(pull_date),
    state                   = as.character(state),
    endpoint                = as.character(endpoint),
    params                  = as.character(params),
    http_status             = as.integer(http_status),
    records_returned        = as.integer(records_returned),
    records_reported        = as.integer(records_reported),
    requested_limit         = as.integer(requested_limit),
    served_limit            = as.integer(served_limit),
    quota_monthly_limit     = as.numeric(quota_monthly_limit),
    quota_monthly_remaining = as.numeric(quota_monthly_remaining),
    duration_seconds        = as.numeric(duration_seconds),
    stage                   = as.character(stage),
    notes                   = as.character(notes)
  )
}


#' Append one row per API call to logs/pull_manifest.csv
#'
#' Written immediately after each call rather than at the end of the run, so a
#' crash mid-pull still leaves an accurate record of what was spent (§0.5).
#'
#' Refuses to append to a file whose header does not match
#' RHTP_MANIFEST_COLUMNS. Appending positionally into a differently-shaped CSV
#' corrupts the audit trail in a way that reads as valid data.
rhtp_append_manifest <- function(row) {
  manifest_path <- rhtp_path("pull_manifest", create = TRUE)

  missing_cols <- setdiff(RHTP_MANIFEST_COLUMNS, names(row))
  if (length(missing_cols) > 0) {
    stop(
      "Manifest row is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  row <- row %>%
    dplyr::select(dplyr::all_of(RHTP_MANIFEST_COLUMNS)) %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character), rhtp_redact))

  file_exists <- file.exists(manifest_path)

  if (file_exists) {
    existing_header <- names(readr::read_csv(
      manifest_path, n_max = 0, show_col_types = FALSE, progress = FALSE
    ))

    if (!identical(existing_header, RHTP_MANIFEST_COLUMNS)) {
      stop(
        "logs/pull_manifest.csv has a header that does not match the canonical ",
        "schema, so appending would misalign every value in the row.\n",
        "  on disk: ", paste(existing_header, collapse = ", "), "\n",
        "  expected: ", paste(RHTP_MANIFEST_COLUMNS, collapse = ", "), "\n",
        "Migrate the file to the canonical schema before running a pull.",
        call. = FALSE
      )
    }
  }

  readr::write_csv(
    row, manifest_path, append = file_exists, progress = FALSE
  )

  invisible(row)
}


# -- Single call -----------------------------------------------------------

#' Perform one request, account for it, and return the parsed body
#'
#' Every network call in this stage goes through here. Responsibilities:
#' enforce the per-run ceiling, time the call, parse quota headers, write the
#' manifest row, and abort on quota exhaustion rather than truncating (§5.2).
#'
#' @return A list: body (parsed with simplifyVector = FALSE), body_text
#'   (verbatim), status, quota, duration_s.
rhtp_perform <- function(req, endpoint, query = list(), pull_date = Sys.Date()) {
  cfg <- rhtp_config()

  if (rhtp_run_requests() >= cfg$quota$max_requests_per_run) {
    stop(
      "ABORTING: per-run request ceiling of ", cfg$quota$max_requests_per_run,
      " reached (quota$max_requests_per_run). This is a runaway-pagination ",
      "guard, not a quota limit -- a full national pull should cost ~46 calls. ",
      "Investigate before raising it.",
      call. = FALSE
    )
  }

  params_str <- rhtp_format_params(query)
  # Session 0 logged the API path rather than the config key; keep the column
  # comparable across stages.
  endpoint_path <- paste0(rhtp_config()$api$api_prefix, "/", endpoint)
  started <- Sys.time()

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      duration <- as.numeric(difftime(Sys.time(), started, units = "secs"))
      .rhtp_run_state$requests <- rhtp_run_requests() + 1L

      rhtp_append_manifest(rhtp_manifest_row(
        timestamp        = started,
        pull_date        = pull_date,
        endpoint         = endpoint_path,
        params           = params_str,
        requested_limit  = query$limit %||% NA_integer_,
        duration_seconds = round(duration, 3),
        notes            = paste("REQUEST FAILED:", rhtp_redact(conditionMessage(e)))
      ))

      stop(
        "Request to ", endpoint, " failed after ", cfg$retry$max_tries,
        " tries: ", rhtp_redact(conditionMessage(e)),
        call. = FALSE
      )
    }
  )

  duration <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  .rhtp_run_state$requests <- rhtp_run_requests() + 1L

  body_text <- httr2::resp_body_string(resp)
  body <- jsonlite::fromJSON(body_text, simplifyVector = FALSE)
  quota <- rhtp_parse_quota(resp)

  records_returned <- length(body$data %||% body$documents %||% list())
  served_limit <- body$pagination$limit %||% NA_integer_

  rhtp_append_manifest(rhtp_manifest_row(
    timestamp               = started,
    pull_date               = pull_date,
    endpoint                = endpoint_path,
    params                  = params_str,
    http_status             = httr2::resp_status(resp),
    records_returned        = records_returned,
    # pagination.total for the standard envelope; absent on the hasMore
    # shapes, where `count` is a page length and not a grand total (§4).
    records_reported        = body$pagination$total %||% NA_integer_,
    requested_limit         = query$limit %||% NA_integer_,
    served_limit            = served_limit,
    quota_monthly_limit     = quota$monthly_limit,
    quota_monthly_remaining = quota$monthly_remaining,
    duration_seconds        = round(duration, 3),
    notes                   = ""
  ))

  # Aborts above the configured fraction rather than returning a partial pull.
  rhtp_check_quota(quota)

  list(
    body      = body,
    body_text = body_text,
    status    = httr2::resp_status(resp),
    quota     = quota,
    duration_s = duration
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x


# -- Handler 1: {data, pagination{page,limit,total,pages}} ------------------

# states, awards, documents, opportunities, events.
# Termination: page count computed from the response envelope.
# Exhaustiveness: rows collected must equal pagination.total.

rhtp_fetch_paginated <- function(endpoint, query = list(), requested_limit = NULL,
                                 pull_date = Sys.Date()) {
  cfg <- rhtp_config()
  spec <- cfg$endpoints[[endpoint]]

  if (is.null(spec)) {
    stop("Unknown endpoint '", endpoint, "'.", call. = FALSE)
  }
  if (!identical(spec$envelope, "pagination")) {
    stop(
      "rhtp_fetch_paginated() called on '", endpoint, "', whose envelope is '",
      spec$envelope, "'. Use the handler for that shape (§4).",
      call. = FALSE
    )
  }

  requested_limit <- requested_limit %||% spec$max_limit
  url <- rhtp_endpoint_url(endpoint)

  message("  ", endpoint, ": requesting limit=", requested_limit, " ...")

  first_query <- c(query, list(page = 1, limit = requested_limit))
  first <- rhtp_perform(
    rhtp_build_request(url, first_query), endpoint, first_query, pull_date
  )

  pagination <- first$body$pagination
  plan <- rhtp_page_plan(
    requested_limit = requested_limit,
    served_limit    = pagination$limit,
    total           = pagination$total,
    pages_reported  = pagination$pages
  )

  if (plan$limit_downgraded) {
    warning(
      "SILENT LIMIT DOWNGRADE on /", endpoint, ": requested limit=",
      plan$requested_limit, ", server served limit=", plan$served_limit,
      " with HTTP ", first$status, ". Walking ", plan$pages_needed,
      " pages computed from the served limit, not ",
      ceiling(plan$total / plan$requested_limit),
      " from the requested one. This is the §5.2 trap and it is live.",
      call. = FALSE
    )
    message(
      "  ", endpoint, ": limit downgraded ", plan$requested_limit, " -> ",
      plan$served_limit, " (expected on /documents and /opportunities)"
    )
  }

  if (plan$pages_mismatch) {
    warning(
      "/", endpoint, ": pagination.pages (", plan$pages_reported, ") disagrees ",
      "with ceiling(total/limit) (", ceiling(plan$total / plan$served_limit),
      "). Walking the larger, ", plan$pages_needed, ".",
      call. = FALSE
    )
  }

  message(
    "  ", endpoint, ": total=", plan$total, " served_limit=", plan$served_limit,
    " pages=", plan$pages_needed
  )

  pages <- list(rhtp_page_record(first, page = 1))
  totals_seen <- plan$total

  if (plan$pages_needed > 1) {
    for (page_no in 2:plan$pages_needed) {
      page_query <- c(query, list(page = page_no, limit = requested_limit))
      page <- rhtp_perform(
        rhtp_build_request(url, page_query), endpoint, page_query, pull_date
      )
      pages <- c(pages, list(rhtp_page_record(page, page = page_no)))
      totals_seen <- c(totals_seen, page$body$pagination$total %||% NA_integer_)
      message("    page ", page_no, "/", plan$pages_needed, ": ",
              length(page$body$data), " records")
    }
  }

  records_written <- sum(purrr::map_int(pages, ~ .x$n_records))

  # Exhaustiveness (§5.2). A short read is the worst failure mode in this
  # stage, so it is a hard error, not a warning.
  if (records_written != plan$total) {
    stop(
      "SHORT READ on /", endpoint, ": collected ", records_written,
      " records but pagination.total reported ", plan$total,
      ". Refusing to write a partial snapshot to the landing zone.",
      call. = FALSE
    )
  }

  # A total that moves mid-walk means records were added or removed while we
  # paginated, which can shift rows across page boundaries and duplicate or
  # skip them. Not fatal -- Stage 2 dedupes on record hash -- but it must be
  # recorded, because it is otherwise invisible.
  total_drifted <- length(unique(stats::na.omit(totals_seen))) > 1

  if (total_drifted) {
    warning(
      "/", endpoint, ": pagination.total changed during the walk (",
      paste(unique(stats::na.omit(totals_seen)), collapse = " -> "),
      "). The corpus moved mid-pull; Stage 2 must dedupe on record hash.",
      call. = FALSE
    )
  }

  list(
    endpoint       = endpoint,
    envelope       = "pagination",
    plan           = plan,
    pages          = pages,
    records_written = records_written,
    exhaustive     = TRUE,
    total_drifted  = total_drifted,
    capped         = FALSE
  )
}


#' Package one performed page for the landing zone
#'
#' Stores the parsed body re-serialised as pretty JSON (diffable in git, and
#' what Stage 2 actually reads) alongside a sha256 of the VERBATIM response
#' text. The hash is the fidelity anchor: it is computed before any
#' re-serialisation, so a round-trip question can always be settled against it.
rhtp_page_record <- function(performed, page) {
  list(
    page          = page,
    http_status   = performed$status,
    n_records     = length(performed$body$data %||% performed$body$documents %||% list()),
    body_sha256   = digest::digest(performed$body_text, algo = "sha256",
                                   serialize = FALSE),
    body          = performed$body
  )
}


# -- Handler 1b: {data, count} -- complete, unpaginated set ----------------

# /states only.
#
# CORRECTION (Session 3): §4 and config.yml both listed /states under the
# {data, pagination} envelope. It is not. A live call returns exactly
# `{data, count}` -- no `pagination` object, no `hasMore`, no `page`. It is an
# unpaginated endpoint that returns the complete set of 50 states in one call.
#
# The pagination handler caught this rather than short-reading, because
# rhtp_page_plan() errors on a missing pagination.limit instead of guessing.
# That is the guard working as designed.
#
# Exhaustiveness here is `count` == length(data): on this shape `count` IS the
# grand total, because there is only ever one page.

rhtp_fetch_complete <- function(endpoint, query = list(), requested_limit = NULL,
                                pull_date = Sys.Date()) {
  cfg <- rhtp_config()
  spec <- cfg$endpoints[[endpoint]]

  if (is.null(spec)) {
    stop("Unknown endpoint '", endpoint, "'.", call. = FALSE)
  }
  if (!identical(spec$envelope, "complete")) {
    stop(
      "rhtp_fetch_complete() called on '", endpoint, "', whose envelope is '",
      spec$envelope, "'.",
      call. = FALSE
    )
  }

  requested_limit <- requested_limit %||% spec$max_limit
  url <- rhtp_endpoint_url(endpoint)

  message("  ", endpoint, ": complete set, limit=", requested_limit, " ...")

  page_query <- c(query, list(limit = requested_limit))
  performed <- rhtp_perform(
    rhtp_build_request(url, page_query), endpoint, page_query, pull_date
  )

  n_records <- length(performed$body$data)
  reported <- performed$body$count

  if (is.null(reported) || is.na(reported)) {
    stop(
      "/", endpoint, ": response carried no `count`, so exhaustiveness cannot ",
      "be asserted. Refusing to write to the landing zone.",
      call. = FALSE
    )
  }

  if (!identical(as.integer(reported), as.integer(n_records))) {
    stop(
      "SHORT READ on /", endpoint, ": collected ", n_records,
      " records but the envelope reported count=", reported, ".",
      call. = FALSE
    )
  }

  message("  ", endpoint, ": total=", n_records, " (single unpaginated call)")

  list(
    endpoint = endpoint,
    envelope = "complete",
    plan = list(
      requested_limit  = as.integer(requested_limit),
      served_limit     = NA_integer_,
      total            = as.integer(reported),
      pages_reported   = 1L,
      pages_needed     = 1L,
      limit_downgraded = NA,
      pages_mismatch   = FALSE
    ),
    pages           = list(rhtp_page_record(performed, page = 1)),
    records_written = n_records,
    exhaustive      = TRUE,
    total_drifted   = FALSE,
    capped          = FALSE
  )
}


# -- Handler 2: {data, count, page, hasMore} -------------------------------

# /activity only.
# `count` is the length of the current page, NOT a grand total (§4), so the
# exhaustiveness check used above cannot apply. Termination is the hasMore
# loop, and the only protection against an unbounded walk is max_pages.

rhtp_fetch_hasmore <- function(endpoint, query = list(), requested_limit = NULL,
                               max_pages = NULL, pull_date = Sys.Date()) {
  cfg <- rhtp_config()
  spec <- cfg$endpoints[[endpoint]]

  if (!identical(spec$envelope, "hasmore")) {
    stop(
      "rhtp_fetch_hasmore() called on '", endpoint, "', whose envelope is '",
      spec$envelope, "' (§4).",
      call. = FALSE
    )
  }

  requested_limit <- requested_limit %||% spec$max_limit
  max_pages <- max_pages %||% cfg$pull$activity_max_pages
  url <- rhtp_endpoint_url(endpoint)

  message("  ", endpoint, ": hasMore walk, limit=", requested_limit,
          " max_pages=", max_pages, " ...")

  pages <- list()
  page_no <- 1L
  has_more <- TRUE
  capped <- FALSE

  while (isTRUE(has_more)) {
    if (page_no > max_pages) {
      capped <- TRUE
      # Never a silent cap: this is loud in the console, in the warning
      # stream, and recorded in the written pull metadata.
      warning(
        "/", endpoint, ": stopped at the max_pages ceiling of ", max_pages,
        " with hasMore still TRUE. THE SNAPSHOT IS INCOMPLETE. Raise ",
        "pull$activity_max_pages in config.yml and re-run, or narrow with ",
        "`since=`. Recorded as capped = TRUE in the pull metadata.",
        call. = FALSE
      )
      message("  ", endpoint, ": CAPPED at ", max_pages, " pages -- INCOMPLETE")
      break
    }

    page_query <- c(query, list(page = page_no, limit = requested_limit))
    performed <- rhtp_perform(
      rhtp_build_request(url, page_query), endpoint, page_query, pull_date
    )

    pages <- c(pages, list(rhtp_page_record(performed, page = page_no)))
    has_more <- isTRUE(performed$body$hasMore)

    message("    page ", page_no, ": ", length(performed$body$data),
            " records, hasMore=", has_more)

    page_no <- page_no + 1L
  }

  records_written <- sum(purrr::map_int(pages, ~ .x$n_records))

  list(
    endpoint        = endpoint,
    envelope        = "hasmore",
    plan            = list(
      requested_limit = as.integer(requested_limit),
      served_limit    = NA_integer_,
      total           = NA_integer_,
      pages_reported  = NA_integer_,
      pages_needed    = length(pages),
      limit_downgraded = NA,
      pages_mismatch  = NA
    ),
    pages           = pages,
    records_written = records_written,
    # No `total` exists to compare against, so exhaustiveness is only as good
    # as hasMore terminating on its own.
    exhaustive      = !capped,
    total_drifted   = FALSE,
    capped          = capped
  )
}


# -- Handler 3: {documents, count, hasMore, aiAnswer} ----------------------

# POST /search. Not part of the national pull -- it is an ad-hoc discovery
# tool. Implemented here so all three envelopes in §4 have a handler.
#
# ai_answer defaults to FALSE: aiAnswer is metered against a separate and much
# smaller allowance (250/month) and its output is non-quotable per §4 and
# CLAUDE.md §6. Nothing it returns may enter an AHA product.

rhtp_fetch_search <- function(query_text, states = NULL, year = NULL,
                              requested_limit = NULL, ai_answer = FALSE,
                              max_pages = 10, pull_date = Sys.Date()) {
  cfg <- rhtp_config()
  spec <- cfg$endpoints$search
  requested_limit <- requested_limit %||% spec$max_limit
  url <- rhtp_endpoint_url("search")

  if (isTRUE(ai_answer)) {
    message(
      "  search: aiAnswer=TRUE -- this consumes the 250/month AI allowance. ",
      "Its output is a search aid only and is NEVER quotable (§4, CLAUDE.md §6)."
    )
  }

  pages <- list()
  page_no <- 1L
  has_more <- TRUE
  capped <- FALSE

  while (isTRUE(has_more)) {
    if (page_no > max_pages) {
      capped <- TRUE
      warning(
        "POST /search: stopped at max_pages=", max_pages,
        " with hasMore still TRUE. Results are incomplete.",
        call. = FALSE
      )
      break
    }

    body <- purrr::compact(list(
      query    = query_text,
      states   = states,
      year     = year,
      limit    = requested_limit,
      page     = page_no,
      aiAnswer = ai_answer
    ))

    performed <- rhtp_perform(
      rhtp_build_request(url, method = "POST", body = body),
      "search",
      list(query = query_text, page = page_no, limit = requested_limit),
      pull_date
    )

    pages <- c(pages, list(rhtp_page_record(performed, page = page_no)))
    has_more <- isTRUE(performed$body$hasMore)
    page_no <- page_no + 1L
  }

  list(
    endpoint        = "search",
    envelope        = "search",
    plan            = list(
      requested_limit = as.integer(requested_limit),
      served_limit    = NA_integer_,
      total           = NA_integer_,
      pages_reported  = NA_integer_,
      pages_needed    = length(pages),
      limit_downgraded = NA,
      pages_mismatch  = NA
    ),
    pages           = pages,
    records_written = sum(purrr::map_int(pages, ~ length(.x$body$documents %||% list()))),
    exhaustive      = !capped,
    total_drifted   = FALSE,
    capped          = capped
  )
}


# -- Landing zone ----------------------------------------------------------

#' Write one endpoint's pull to data/raw/rcj/<pull_date>/<endpoint>.json
#'
#' Immutable by policy (§5.2): an existing file for a prior date is never
#' overwritten. Re-running the same date requires an explicit overwrite = TRUE,
#' which exists for recovering a crashed run on the current date and nothing
#' else.
rhtp_write_raw <- function(result, pull_date = Sys.Date(), overwrite = FALSE) {
  out_dir <- rhtp_path("raw_rcj", as.character(pull_date))
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  out_path <- file.path(out_dir, paste0(result$endpoint, ".json"))

  if (file.exists(out_path) && !isTRUE(overwrite)) {
    stop(
      "Refusing to overwrite an existing landing-zone file:\n  ", out_path,
      "\ndata/raw/ is immutable (§5.2). Pass overwrite = TRUE only to recover ",
      "a crashed run on the current date.",
      call. = FALSE
    )
  }

  payload <- list(
    pull_metadata = list(
      endpoint         = result$endpoint,
      envelope         = result$envelope,
      pull_date        = as.character(pull_date),
      retrieved_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      strategy         = "branch_a_national_no_state_filter",
      base_url         = paste0(rhtp_config()$api$base_url,
                                rhtp_config()$api$api_prefix),
      requested_limit  = result$plan$requested_limit,
      served_limit     = result$plan$served_limit,
      limit_downgraded = result$plan$limit_downgraded,
      reported_total   = result$plan$total,
      pages_reported   = result$plan$pages_reported,
      pages_walked     = length(result$pages),
      records_written  = result$records_written,
      exhaustive       = result$exhaustive,
      total_drifted    = result$total_drifted,
      capped           = result$capped,
      rules_version    = rhtp_config()$rules_version,
      # Fidelity note for anyone auditing this file later.
      fidelity_note    = paste(
        "pages[].body is the parsed response re-serialised as pretty JSON so it",
        "diffs legibly in git. pages[].body_sha256 is sha256 of the VERBATIM",
        "response text, computed before re-serialisation, and is the",
        "byte-fidelity anchor."
      )
    ),
    pages = result$pages
  )

  jsonlite::write_json(
    payload,
    out_path,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    pretty = TRUE,
    digits = NA
  )

  message("  wrote ", basename(out_path), " (", result$records_written,
          " records, ", length(result$pages), " pages)")

  invisible(out_path)
}


# -- Orchestrator ----------------------------------------------------------

#' Run one full national pull (Branch A)
#'
#' @param pull_date Landing-zone date directory. Defaults to today.
#' @param endpoints Collection endpoints to pull.
#' @param activity_since Optional ISO timestamp for /activity's `since` filter,
#'   the only server-side delta filter in the API (§4.1). NULL pulls
#'   comprehensively -- which is what the first run must do, since there is no
#'   prior pull to delta from, and its cost is unmeasured (open blocker 3).
#' @param overwrite Allow overwriting today's files. Recovery only.
rhtp_run_national_pull <- function(pull_date = Sys.Date(),
                                   endpoints = c("states", "awards", "documents",
                                                 "opportunities", "activity"),
                                   activity_since = NULL,
                                   overwrite = FALSE) {
  rhtp_reset_run_state()
  cfg <- rhtp_config()

  message("RHTP Stage 1 -- national pull (Branch A)")
  message("  pull_date: ", as.character(pull_date))
  message("  endpoints: ", paste(endpoints, collapse = ", "))

  key_status <- rhtp_api_key_status()
  if (!key_status$is_set) {
    stop("RCJ_API_KEY is not set. See rhtp_api_key().", call. = FALSE)
  }
  message("  auth: ", key_status$env_var, " present (", key_status$n_chars,
          " chars, expected prefix: ", key_status$has_expected_prefix, ")")

  results <- list()

  for (endpoint in endpoints) {
    spec <- cfg$endpoints[[endpoint]]

    result <- switch(
      spec$envelope,
      pagination = rhtp_fetch_paginated(endpoint, pull_date = pull_date),
      complete   = rhtp_fetch_complete(endpoint, pull_date = pull_date),
      hasmore    = rhtp_fetch_hasmore(
        endpoint,
        query = if (is.null(activity_since)) list() else list(since = activity_since),
        pull_date = pull_date
      ),
      stop("No handler for envelope '", spec$envelope, "' on /", endpoint,
           call. = FALSE)
    )

    rhtp_write_raw(result, pull_date = pull_date, overwrite = overwrite)
    results[[endpoint]] <- result
  }

  summary_tbl <- results %>%
    purrr::imap(~ tibble::tibble(
      endpoint        = .y,
      envelope        = .x$envelope,
      reported_total  = .x$plan$total,
      records_written = .x$records_written,
      pages_walked    = length(.x$pages),
      requested_limit = .x$plan$requested_limit,
      served_limit    = .x$plan$served_limit,
      exhaustive      = .x$exhaustive,
      capped          = .x$capped
    )) %>%
    dplyr::bind_rows()

  message("\n-- Pull complete --")
  print(as.data.frame(summary_tbl), row.names = FALSE)
  message("API calls this run: ", rhtp_run_requests())

  invisible(list(results = results, summary = summary_tbl,
                 calls = rhtp_run_requests()))
}


# -- CLI entry point -------------------------------------------------------

# Sourcing this file must never spend quota. A pull runs only when the script
# is invoked with an explicit --run flag:
#
#   Rscript R/01_retrieve_rcj.R --run
#
if (!interactive()) {
  cli_args <- commandArgs(trailingOnly = TRUE)
  if ("--run" %in% cli_args) {
    rhtp_run_national_pull()
  }
}

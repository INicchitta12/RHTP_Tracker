# utils_config.R -----------------------------------------------------------
# Configuration loading, path resolution, and credential handling.
#
# Build spec §1 (Credentials) and §3 (cloud environment). Sourced by every
# stage script. Contains no network calls.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd();
# all paths go through here::here(). Explicit :: namespacing throughout.
#
# CREDENTIAL RULE: the RCJ API key is read from the RCJ_API_KEY environment
# variable and returned only to the caller that immediately builds a request
# header. It is never written to a file, never committed, never echoed to logs
# or console. Nothing in this file prints it, and rhtp_redact() exists to keep
# it out of anything that does get printed.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
})


# -- Locale ----------------------------------------------------------------

# Cloud sessions start R in the C/POSIX locale (LANG unset), where readLines()
# and every stringr operation choke on multibyte UTF-8. That breaks config.yml
# (which contains section-sign and em-dash characters) and would corrupt RCJ
# payloads, whose titles and awardee names carry non-ASCII text.
#
# Called at source() time so every stage inherits a UTF-8 session without
# having to remember to set it. Returns invisibly and never errors: if
# C.UTF-8 is unavailable the session still works for ASCII-only input, and
# rhtp_preflight() reports the degraded state.

rhtp_set_utf8_locale <- function() {
  if (isTRUE(l10n_info()$`UTF-8`)) {
    return(invisible(TRUE))
  }

  for (candidate in c("C.UTF-8", "en_US.UTF-8")) {
    suppressWarnings(try(Sys.setlocale("LC_ALL", candidate), silent = TRUE))
    if (isTRUE(l10n_info()$`UTF-8`)) {
      return(invisible(TRUE))
    }
  }

  invisible(FALSE)
}

rhtp_set_utf8_locale()


# -- Config ----------------------------------------------------------------

#' Load config/config.yml
#'
#' Memoised for the session so repeated calls do not re-read the file. Pass
#' `refresh = TRUE` after editing the YAML mid-session.
#'
#' @param path Config file path, relative to the repo root.
#' @param refresh Re-read from disk instead of using the cached value.
#' @return A named list.
.rhtp_config_cache <- new.env(parent = emptyenv())

rhtp_config <- function(path = "config/config.yml", refresh = FALSE) {
  key <- path

  if (!refresh && !is.null(.rhtp_config_cache[[key]])) {
    return(.rhtp_config_cache[[key]])
  }

  full_path <- here::here(path)

  if (!file.exists(full_path)) {
    stop(
      "Config file not found at '", full_path, "'.\n",
      "Run from within the repository; paths resolve via here::here().",
      call. = FALSE
    )
  }

  # Explicit UTF-8 even after the locale fix above -- read_yaml() delegates to
  # readLines(), which honours the connection encoding, not the locale.
  cfg <- yaml::yaml.load(
    paste(readLines(full_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  )

  # Fail loudly on a truncated or malformed config rather than letting a NULL
  # propagate into a request URL.
  required <- c("api", "quota", "retry", "endpoints", "paths", "pull", "qa",
                "cms")
  missing_keys <- setdiff(required, names(cfg))

  if (length(missing_keys) > 0) {
    stop(
      "config.yml is missing required top-level keys: ",
      paste(missing_keys, collapse = ", "),
      call. = FALSE
    )
  }

  .rhtp_config_cache[[key]] <- cfg
  cfg
}


#' Resolve a configured path to an absolute path
#'
#' @param key A name under `paths:` in config.yml, e.g. "raw_rcj".
#' @param ... Further path components appended with here::here().
#' @param create Create the directory if it does not exist. For a path that
#'   names a file rather than a directory, creates the parent.
rhtp_path <- function(key, ..., create = FALSE) {
  cfg <- rhtp_config()
  base <- cfg$paths[[key]]

  if (is.null(base)) {
    stop(
      "No path configured under paths: for key '", key, "'. ",
      "Available: ", paste(names(cfg$paths), collapse = ", "),
      call. = FALSE
    )
  }

  full_path <- here::here(base, ...)

  if (isTRUE(create)) {
    # A trailing component containing a dot is treated as a file name, so
    # create its parent rather than a directory of that name.
    target <- if (stringr::str_detect(basename(full_path), "\\.")) {
      dirname(full_path)
    } else {
      full_path
    }
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
  }

  full_path
}


#' Build a full endpoint URL from config
#'
#' @param endpoint A name under `endpoints:` in config.yml, e.g. "awards".
#' @param ... Named values substituting `{placeholders}` in the path, e.g.
#'   `code = "DE"` for the "state_detail" endpoint.
rhtp_endpoint_url <- function(endpoint, ...) {
  cfg <- rhtp_config()
  spec <- cfg$endpoints[[endpoint]]

  if (is.null(spec)) {
    stop(
      "Unknown endpoint '", endpoint, "'. Available: ",
      paste(names(cfg$endpoints), collapse = ", "),
      call. = FALSE
    )
  }

  path <- spec$path
  substitutions <- rlang::list2(...)

  for (nm in names(substitutions)) {
    path <- stringr::str_replace_all(
      path,
      stringr::fixed(paste0("{", nm, "}")),
      as.character(substitutions[[nm]])
    )
  }

  # An unsubstituted placeholder would produce a literal "{id}" in the URL and
  # a confusing 404. Catch it here instead.
  if (stringr::str_detect(path, "\\{[^}]+\\}")) {
    stop(
      "Endpoint '", endpoint, "' has unsubstituted placeholders in '", path,
      "'. Supply them as named arguments.",
      call. = FALSE
    )
  }

  paste0(cfg$api$base_url, cfg$api$api_prefix, path)
}


# -- Shared reference tables -----------------------------------------------

#' The state vocabulary (§7.1)
#'
#' Independent of RCJ, by design. /states returns 49 states plus a pseudo-state
#' `US` and omits Wyoming; `RC` appears as a state code on 54 /documents
#' records and is not a state. Neither may define this list.
#'
#' Lives here rather than in a stage script because every stage from 2 onward
#' keys off it, and because Stage 3 must be able to read it without sourcing
#' Stage 2 (whose CLI block would fire on a shared `--run` flag).
#'
#' Hard-fails on anything other than exactly 50 rows, because every state-keyed
#' join and QA reconciliation downstream assumes it (§13.14).
rhtp_cms_states <- function() {
  path <- rhtp_path("cms_states")

  states <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  if (nrow(states) != 50) {
    stop(
      "data/reference/cms_states.csv must have exactly 50 rows (§7.1); found ",
      nrow(states), ". Every state-keyed join downstream assumes 50.",
      call. = FALSE
    )
  }

  states %>% dplyr::select(state, state_name)
}


# -- Credentials -----------------------------------------------------------

#' Retrieve the RCJ API key
#'
#' Reads the environment variable named in `api$key_env_var`. In cloud sessions
#' this comes from the environment's Environment variables field; locally the
#' identical call reads a .Renviron. No code changes are needed to move between
#' the two.
#'
#' NEVER print, log, cat(), message(), or write the return value of this
#' function. Pass it straight into a request header.
#'
#' @param required Error if unset (default). FALSE returns "" instead, for
#'   callers doing a capability check.
rhtp_api_key <- function(required = TRUE) {
  cfg <- rhtp_config()
  var_name <- cfg$api$key_env_var
  key <- Sys.getenv(var_name, unset = "")

  if (!nzchar(key)) {
    if (isTRUE(required)) {
      stop(
        "Environment variable ", var_name, " is not set.\n",
        "Cloud sessions: set it in the environment's Environment variables field.\n",
        "Local runs: add it to .Renviron (which is gitignored) and restart R.",
        call. = FALSE
      )
    }
    return("")
  }

  key
}


#' Report on the API key without revealing it
#'
#' Safe to print. Use this in logs and startup checks in place of any direct
#' reference to the key.
rhtp_api_key_status <- function() {
  cfg <- rhtp_config()
  var_name <- cfg$api$key_env_var
  key <- Sys.getenv(var_name, unset = "")

  tibble::tibble(
    env_var    = var_name,
    is_set     = nzchar(key),
    n_chars    = nchar(key),
    # Prefix only. RCJ keys are documented as "rhtp_"-prefixed, so this
    # confirms the right kind of value is present without disclosing it.
    has_expected_prefix = stringr::str_starts(key, "rhtp_")
  )
}


#' Strip the API key out of a string before it is printed or written
#'
#' Defence in depth for error messages, verbose httr2 output, and manifest
#' fields that might otherwise capture a full request URL or header.
#'
#' @param x A character vector.
rhtp_redact <- function(x) {
  key <- Sys.getenv(rhtp_config()$api$key_env_var, unset = "")

  if (!nzchar(key)) {
    return(x)
  }

  x %>%
    stringr::str_replace_all(stringr::fixed(key), "<RCJ_API_KEY_REDACTED>") %>%
    # Catch any other rhtp_-prefixed token that shows up, e.g. a key pasted
    # into a config by mistake.
    stringr::str_replace_all("rhtp_[A-Za-z0-9_\\-]{8,}", "<REDACTED_KEY>")
}


#' Authorization headers for an RCJ request
#'
#' Returns a named list suitable for httr2::req_headers(!!!.). The key is
#' present in the return value -- do not print it. Use rhtp_redact() on
#' anything derived from it that will be shown.
rhtp_auth_headers <- function() {
  cfg <- rhtp_config()
  key <- rhtp_api_key()

  auth <- switch(
    cfg$api$auth_scheme,
    bearer    = list(Authorization = paste("Bearer", key)),
    x_api_key = list(`X-Api-Key` = key),
    stop(
      "Unknown api$auth_scheme '", cfg$api$auth_scheme,
      "'. Expected 'bearer' or 'x_api_key'.",
      call. = FALSE
    )
  )

  c(auth, list(Accept = "application/json"))
}


# -- Quota -----------------------------------------------------------------

#' Extract quota figures from a response's headers
#'
#' Spec §5 requires this on every call. Header names come from config so they
#' can be corrected without touching the retrieval client if RCJ renames them.
#'
#' Returns NA for the AI fields on non-search endpoints that omit them, rather
#' than erroring -- absence is expected there.
#'
#' @param resp An httr2 response.
rhtp_parse_quota <- function(resp) {
  cfg <- rhtp_config()
  hdrs <- cfg$api$quota_headers

  as_num <- function(header_name) {
    value <- httr2::resp_header(resp, header_name)
    if (is.null(value)) NA_real_ else suppressWarnings(as.numeric(value))
  }

  monthly_limit     <- as_num(hdrs$monthly_limit)
  monthly_remaining <- as_num(hdrs$monthly_remaining)

  tibble::tibble(
    monthly_limit        = monthly_limit,
    monthly_remaining    = monthly_remaining,
    monthly_used         = monthly_limit - monthly_remaining,
    fraction_consumed    = if (is.na(monthly_limit) || monthly_limit == 0) {
      NA_real_
    } else {
      (monthly_limit - monthly_remaining) / monthly_limit
    },
    ai_monthly_limit     = as_num(hdrs$ai_monthly_limit),
    ai_monthly_remaining = as_num(hdrs$ai_monthly_remaining)
  )
}


#' Halt a run that is consuming too much of the monthly allowance
#'
#' Spec §5: abort with a clear message rather than silently truncating. Called
#' after every request by the Stage 1 client.
#'
#' @param quota A one-row tibble from rhtp_parse_quota().
rhtp_check_quota <- function(quota) {
  cfg <- rhtp_config()

  # A missing header is itself worth surfacing: it means either the key lost
  # its plan or RCJ renamed the header, and either way quota accounting is
  # blind from that point on.
  if (is.na(quota$fraction_consumed)) {
    warning(
      "Quota headers absent or unparseable. Quota accounting is blind for ",
      "this call. Check api$quota_headers in config.yml against a live ",
      "response before running a full pull.",
      call. = FALSE
    )
    return(invisible(quota))
  }

  pct <- round(quota$fraction_consumed * 100, 1)

  if (quota$fraction_consumed >= cfg$quota$abort_at_fraction_consumed) {
    stop(
      "ABORTING: RCJ monthly quota ", pct, "% consumed ",
      "(", format(quota$monthly_remaining, big.mark = ","), " of ",
      format(quota$monthly_limit, big.mark = ","), " requests remaining), ",
      "at or above the ",
      round(cfg$quota$abort_at_fraction_consumed * 100), "% abort threshold.\n",
      "Stopping rather than returning a partial pull. The allowance resets at ",
      "00:00 UTC on the first of the month.",
      call. = FALSE
    )
  }

  if (quota$fraction_consumed >= cfg$quota$warn_at_fraction_consumed) {
    warning(
      "RCJ monthly quota ", pct, "% consumed (",
      format(quota$monthly_remaining, big.mark = ","), " requests remaining).",
      call. = FALSE
    )
  }

  invisible(quota)
}


# -- Environment check -----------------------------------------------------

#' Verify the session can run the pipeline
#'
#' Reports on required packages, the API key (without revealing it), and the
#' directory layout. Run at the start of a session.
rhtp_preflight <- function() {
  required_pkgs <- c(
    "tidyverse", "httr2", "jsonlite", "openxlsx", "janitor",
    "digest", "here", "yaml", "fuzzyjoin", "assertr", "testthat"
  )

  pkg_status <- required_pkgs %>%
    purrr::map(~ tibble::tibble(
      package   = .x,
      installed = requireNamespace(.x, quietly = TRUE)
    )) %>%
    dplyr::bind_rows()

  cfg <- rhtp_config()

  dir_status <- cfg$paths %>%
    tibble::enframe(name = "key", value = "path") %>%
    dplyr::mutate(
      path   = purrr::map_chr(path, as.character),
      exists = purrr::map_lgl(path, ~ file.exists(here::here(.x)))
    )

  list(
    r_version  = paste(R.version$major, R.version$minor, sep = "."),
    utf8_locale = isTRUE(l10n_info()$`UTF-8`),
    packages   = pkg_status,
    api_key    = rhtp_api_key_status(),
    paths      = dir_status,
    missing    = pkg_status %>% dplyr::filter(!installed) %>% dplyr::pull(package)
  )
}

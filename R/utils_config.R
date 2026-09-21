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


#' The controlled vocabularies (§8)
#'
#' `data/reference/vocabularies.csv` is the single home for every categorical
#' value in the pipeline. Spec §8: "validate every categorical column against
#' it. No free-text categories anywhere."
#'
#' Lives here so any stage can validate without sourcing another stage, and so
#' there is exactly one reader -- a second one would drift.
#'
#' @param column_name Return only this column's allowed values, as a character
#'   vector. Omit to get the whole table.
#' @return A character vector when `column_name` is given, otherwise a tibble
#'   of `column_name`, `allowed_value`, `notes`.
rhtp_vocabulary <- function(column_name = NULL) {
  path <- rhtp_path("vocabularies")

  vocab <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  if (is.null(column_name)) {
    return(vocab)
  }

  values <- vocab %>%
    dplyr::filter(.data$column_name == !!column_name) %>%
    dplyr::pull(.data$allowed_value)

  if (length(values) == 0) {
    stop(
      "No controlled vocabulary for column '", column_name, "' in ", path, ".\n",
      "Defined: ", paste(sort(unique(vocab$column_name)), collapse = ", "), ".\n",
      "Do not invent codes mid-session (CLAUDE.md §5) -- add the value to ",
      "vocabularies.csv, with the spec section that authorises it.",
      call. = FALSE
    )
  }

  values
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


# -- §0.2: the CMS footer's tier is INDISTINGUISHABLE from its grammar --------
#
# SESSION 37'S FINDING, AND IT IS THE ONE THAT MAKES A FOOTER FIGURE UNSAFE TO
# READ AS A POOL. Session 27's audit put the footer on an axis of grammatical
# SUBJECT -- "This publication is supported by" (weak, a claim about the paper)
# against "This <programme> is supported by" (strong, a claim about the
# programme). That axis answers whether a footer is PROVENANCE. It does not
# answer what TIER its number is, and Iowa proves the two questions are
# separate. Its three footers, read verbatim out of the archived notices:
#
#   "This Best and Brightest- Medical Equipment Procurement is supported by the
#    Centers for Medicare and Medicaid Services (CMS) ... as part of a financial
#    assistance award totaling approximately $66,002,161.80 ..."   <- TIER 2
#
#   "This Centers of Excellence is supported by the Centers for Medicare and
#    Medicaid Services (CMS) ... as part of a financial assistance award
#    totaling approximately $50,000,000.00 ..."                     <- TIER 2
#
#   "This Combat Cancer Health Hub Program is supported by the Centers for
#    Medicare and Medicaid Services (CMS) ... as part of a financial assistance
#    award totaling approximately $209,040,063.71 ..."              <- TIER 1
#
# The three sentences are WORD FOR WORD IDENTICAL apart from the programme name
# and the number. All three are programme-scoped. All three name a real RHTP
# programme. All three are the "strong" form. Grammar separates none of them,
# and neither does the subject: "Combat Cancer Health Hub Program" is a genuine
# Iowa RHTP programme, not a stand-in for the State, so nothing in the sentence
# says its figure is the whole allotment.
#
# THE ONLY THING THAT REVEALS THE TIER IS COLLISION WITH THE §7.1 ANCHOR.
# $209,040,063.71 is Tier 1 because `cms_fy2026_allotments.csv` has Iowa at
# $209,040,064 and for no other reason available on the page. That is a
# uniquely fragile way to know something -- it is a coincidence of value, not a
# statement by the publisher -- so it must be checked by machine on every
# footer figure any state file records, rather than read once by whoever
# happened to open the PDF.
#
# THE FAILURE THIS PREVENTS IS SILENT AND IT INFLATES. A state file that
# accepted Iowa's June footer as that RFP's pool would publish $209,040,063.71
# as one solicitation's budget -- the whole state allotment, attributed to one
# of eleven RFPs -- and it would look exactly like the eight figures beside it
# that are genuinely pools. Nothing in the document contradicts it.
#
# SO THE DEFAULT IS REFUSAL, NOT ACCEPTANCE. `rhtp_assert_footer_not_allotment()`
# takes a footer figure and refuses to let it be treated as a Tier 2 pool when
# it lands within a margin of that state's allotment. The caller that has read
# the documents and KNOWS the figure is Tier 1 declares it -- Iowa does, per
# document, in `ia_notice_footers.csv` -- and the assertion then requires the
# collision it was told to expect. Both directions fail:
#
#   - a figure declared SOLICITATION that collides with the allotment  -> stop
#   - a figure declared STATE_ALLOTMENT that does NOT collide          -> stop
#
# The second half matters as much as the first. A Tier 1 declaration that no
# longer collides means either the publisher changed the figure or the anchor
# moved, and both are findings rather than things to carry forward.

#' The §7.1 anchor, read here rather than through Stage 2's loader
#'
#' `rhtp_load_allotments()` is the Stage 2 reader and does the same job, but it
#' lives in `R/02_normalize.R`. A state extractor sourcing `utils_config.R` to
#' get this assertion should not have to source the whole normalizer with it,
#' and the state files already read this CSV directly (Nevada, California, New
#' Mexico, Louisiana all do). Same file, same two columns, no second copy of
#' the figures -- §0.2a is about one home for the NUMBERS, and that home is
#' still `cms_fy2026_allotments.csv`.
rhtp_footer_allotments <- function() {
  path <- rhtp_path("cms_allotments")
  empty <- tibble::tibble(state = character(), fy2026_allotment = numeric())
  if (!file.exists(path)) return(empty)
  a <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (!"fy2026_allotment" %in% names(a)) return(empty)
  a %>%
    dplyr::filter(!is.na(.data$fy2026_allotment)) %>%
    dplyr::transmute(state = as.character(.data$state),
                     fy2026_allotment = as.numeric(.data$fy2026_allotment))
}

#' The margin, in dollars, within which a footer figure IS the allotment
#'
#' Not a tolerance on a parse -- the parse is exact, and every state file
#' asserts its own footer digits. This is the width of the CMS/state rounding
#' this project has actually measured: publishers restate an allotment rounded
#' to the dollar (Iowa's $209,040,063.71 against the anchor's $209,040,064),
#' to the cent (New Hampshire's $204,016,550.20), or transposed (Kansas's
#' $221,890,007.82 for $221,898,007.82, an $8,000.18 gap that is a real
#' publisher defect and still unmistakably the allotment).
#'
#' $10,000 covers all three and is far below any plausible Iowa-style pool: the
#' smallest genuine Tier 2 footer in this repository is $6,000,000, so the
#' margin would have to grow six hundredfold before it could swallow a real
#' pool figure. Widening it is a decision to be argued, not a way past a
#' failure -- if a figure fails this check, read the document.
RHTP_FOOTER_ALLOTMENT_MARGIN <- 10000

#' Refuse a footer figure that is the state's allotment wearing a pool's grammar
#'
#' @param amount Numeric. The figure printed in the footer.
#' @param state Two-letter state code, matched against the §7.1 anchor.
#' @param declared_tier "SOLICITATION" (the caller believes this is a pool) or
#'   "STATE_ALLOTMENT" (the caller has read the documents and knows it is not).
#' @param label Character. What to name in the error -- a document key, an RFP
#'   number, whatever lets a reader find the page.
#' @param margin Dollars. See `RHTP_FOOTER_ALLOTMENT_MARGIN`.
#' @param allotments Optional pre-loaded anchor, for tests.
#'
#' @return Invisibly TRUE when the declaration holds; invisibly NA, with a
#'   message, when the anchor is not on disk for that state. Stops otherwise.
#'
#' NA rather than TRUE on a missing anchor is deliberate and is §0.4: with no
#' anchor there is nothing to collide with, so the check has not passed -- it
#' has not run, and a caller that wants a hard gate can test for TRUE.
rhtp_assert_footer_not_allotment <- function(amount, state, declared_tier,
                                             label = "a footer figure",
                                             margin = RHTP_FOOTER_ALLOTMENT_MARGIN,
                                             allotments = NULL) {
  declared_tier <- match.arg(declared_tier,
                             c("SOLICITATION", "STATE_ALLOTMENT"))
  if (length(amount) != 1L || is.na(amount) || !is.numeric(amount)) {
    stop("[§0.2] rhtp_assert_footer_not_allotment() takes one numeric ",
         "footer amount; got ", paste(format(amount), collapse = ", "), ".",
         call. = FALSE)
  }

  if (is.null(allotments)) allotments <- rhtp_footer_allotments()
  hit <- allotments$fy2026_allotment[allotments$state == state]

  if (length(hit) != 1L) {
    message("[§0.2] no §7.1 allotment for ", state,
            ", so the footer tier of ", label, " could NOT be checked. That is ",
            "a gap in the anchor, not a pass (§0.4).")
    return(invisible(NA))
  }

  collides <- abs(amount - hit) <= margin
  money <- function(x) paste0("$", formatC(x, format = "f", digits = 2,
                                           big.mark = ","))

  if (collides && declared_tier == "SOLICITATION") {
    stop("[§0.2] ", label, ": the footer prints ", money(amount),
         ", which is within ", money(margin), " of ", state, "'s CMS allotment ",
         "of ", money(hit), ". It is being read as a Tier 2 POOL and it is ",
         "almost certainly Tier 1. The footer's grammar cannot tell you which ",
         "-- Iowa's pool footers and its allotment footer are word for word ",
         "identical apart from the programme name and the number -- so the ",
         "collision is the only signal there is. Read the document. If it IS ",
         "the allotment, declare it STATE_ALLOTMENT and keep it out of every ",
         "pool total; do NOT widen the margin.", call. = FALSE)
  }

  if (!collides && declared_tier == "STATE_ALLOTMENT") {
    stop("[§0.2] ", label, ": the footer prints ", money(amount),
         ", declared STATE_ALLOTMENT, but ", state, "'s §7.1 allotment is ",
         money(hit), " and the two differ by ", money(abs(amount - hit)),
         ", more than the ", money(margin), " margin. A Tier 1 declaration ",
         "rests entirely on that collision, so it no longer holds: either the ",
         "publisher changed the figure or the anchor moved. Both are findings ",
         "-- re-read the document rather than relaxing this.", call. = FALSE)
  }

  invisible(TRUE)
}

#' The same refusal over a whole table of footer figures
#'
#' @param footers A data frame with `footer_amount` and `footer_tier`, and
#'   either a `state` column or a scalar `state`.
#' @param label_col Column naming each row in an error. Falls back to the row
#'   number.
#'
#' @return Invisibly TRUE when every row was checked and every declaration
#'   held. Refusals throw, so FALSE means only that some row could NOT be
#'   checked -- the anchor has no figure for that state (§0.4). Callers
#'   wanting a hard gate should test for TRUE.
rhtp_assert_footer_tiers <- function(footers, state = NULL,
                                     label_col = "rfp",
                                     margin = RHTP_FOOTER_ALLOTMENT_MARGIN,
                                     allotments = NULL) {
  if (!all(c("footer_amount", "footer_tier") %in% names(footers))) {
    stop("[§0.2] rhtp_assert_footer_tiers() needs footer_amount and ",
         "footer_tier columns.", call. = FALSE)
  }
  if (is.null(state) && !"state" %in% names(footers)) {
    stop("[§0.2] rhtp_assert_footer_tiers() needs either a `state` column or ",
         "a scalar `state`: a footer figure means nothing without the ",
         "allotment it is being compared against.", call. = FALSE)
  }
  if (is.null(allotments)) allotments <- rhtp_footer_allotments()
  states <- if (!is.null(state)) rep(state, nrow(footers)) else footers$state
  labels <- if (label_col %in% names(footers)) {
    as.character(footers[[label_col]])
  } else {
    paste("row", seq_len(nrow(footers)))
  }

  checked <- vapply(seq_len(nrow(footers)), function(i) {
    isTRUE(rhtp_assert_footer_not_allotment(
      amount = footers$footer_amount[i],
      state = states[i],
      declared_tier = footers$footer_tier[i],
      label = labels[i],
      margin = margin,
      allotments = allotments
    ))
  }, logical(1))

  invisible(all(checked))
}


# -- §0.2 THE FOOTER'S CMS SHARE, WHICH IS NOT ALWAYS ITS HEADLINE ------------
#
# SESSION 44. Every footer this project had ever read was 100% federal, so the
# headline figure and the CMS share were the same number and nobody had to
# tell them apart. Measured across the committed corpus before this was
# written: 215 CMS financial-assistance footer occurrences in 76 files, all of
# them "100 percent funded by CMS" (154) or "100% funded by CMS" (61), and NO
# committed source carrying any other percentage at all.
#
# MISSISSIPPI IS THE FIRST THAT IS NOT, AND IT DEFEATS THE TIER CHECK WITHOUT
# BEING WRONG ABOUT ANYTHING. `mississippirhtp.com` prints:
#
#   "...as part of a financial assistance award totaling $205,990,180.16, with
#    99.96% funded by CMS/HHS ($205,907,220.16) and 0.04% funded by
#    non-government sources ($82,960)."
#
# The CMS share matches the §7.1 anchor to the dollar ($205,907,220). The
# HEADLINE exceeds it by $82,960.16 -- EIGHT TIMES `RHTP_FOOTER_ALLOTMENT_MARGIN`
# -- so `rhtp_assert_footer_not_allotment()` fed the headline REFUSES it as
# STATE_ALLOTMENT, correctly (it is not the allotment), and ACCEPTS it as a
# SOLICITATION pool, WHICH IS WRONG: it is Tier 1 plus a non-federal match and
# there is no Tier 2 pool in that sentence at all.
#
# THE FIX IS TO PARSE THE CMS SHARE, NOT TO WIDEN THE MARGIN. $82,960 is one
# state's match amount and the next state's will differ, so widening buys
# nothing and costs the check its only signal. This is §0.2's own rule applied
# to itself -- a figure that fails the check is a DOCUMENT TO RE-READ -- and
# the field to re-read is the PERCENTAGE, which this project had never had to
# look at because it had always been 100.
#
# WHERE THE PUBLISHER STATES A PARTIAL SHARE AND NO DOLLAR FIGURE FOR IT, THIS
# REFUSES TO COMPUTE ONE (§0.4). headline x 99.96% is a number no publisher
# printed, and a percentage rounded to two places cannot reproduce a cent-exact
# allotment anyway. `tier_amount` is NA there and the tier check does not run,
# which is a gap to be read by a human rather than a pass.

#' The CMS financial-assistance footer, parsed into its parts
#'
#' @param text Character. Any text that may contain one or more footers --
#'   a reduced HTML page, a PDF's text layer, a single sentence.
#'
#' @return A tibble, one row per footer found, with:
#'   `headline_amount`   the figure after "totaling"
#'   `cms_pct`           the stated CMS percentage
#'   `cms_amount`        the CMS dollar figure IF the footer prints one
#'   `nonfederal_amount` the non-government figure IF the footer prints one
#'   `fully_federal`     TRUE when the stated percentage is 100
#'   `tier_amount`       THE FIGURE TO TIER-CHECK. The CMS amount when stated;
#'                       the headline when the footer is 100% federal; NA when
#'                       the share is partial and no CMS figure is printed.
#'   `sentence`          the matched text, for a reader
#'
#' Zero rows when no footer is present -- absence is not an error, because most
#' pages this is pointed at do not carry one.
rhtp_footer_parse <- function(text) {
  empty <- tibble::tibble(
    headline_amount = numeric(), cms_pct = numeric(), cms_amount = numeric(),
    nonfederal_amount = numeric(), fully_federal = logical(),
    tier_amount = numeric(), sentence = character())
  if (!length(text)) return(empty)
  txt <- paste(text, collapse = "\n")
  # Tags and entities first: the footer is often split across <strong> spans.
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;", "&")
  txt <- stringr::str_replace_all(txt, "[ \t ]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s+", " ")

  # "totaling [approximately] $N" ... then, within the same sentence, the CMS
  # percentage. All 18 phrasings measured in the committed corpus put the
  # percentage after the headline and before "CMS", so the window is bounded
  # rather than greedy -- a greedy match would reach into the NEXT footer on a
  # page carrying two (New Hampshire's does).
  pat <- paste0(
    "totaling\\s+(?:approximately\\s+)?\\$\\s*([0-9][0-9,]*(?:\\.[0-9]+)?)",
    "[^.]{0,40}?([0-9]{1,3}(?:\\.[0-9]+)?)\\s*(?:percent|%)",
    "[^.]{0,60}?CMS")
  m <- stringr::str_match_all(txt, stringr::regex(pat, ignore_case = TRUE))[[1]]
  if (!nrow(m)) return(empty)

  starts <- stringr::str_locate_all(txt, stringr::regex(pat, ignore_case = TRUE))[[1]]
  num <- function(x) as.numeric(stringr::str_remove_all(x, ","))

  rows <- lapply(seq_len(nrow(m)), function(i) {
    # The tail of THIS footer only: from the match's end to the sentence stop
    # or the start of the next match, whichever comes first.
    tail_from <- starts[i, "end"] + 1L
    tail_to <- if (i < nrow(m)) starts[i + 1L, "start"] - 1L else nchar(txt)
    tail <- substr(txt, tail_from, min(tail_to, tail_from + 240L))
    tail <- stringr::str_split(tail, stringr::fixed(". "))[[1]][1]

    # "($205,907,220.16)" immediately after the CMS clause, and the
    # non-government figure after it. Both optional.
    cms_amt <- stringr::str_match(
      tail, "^[^(]{0,40}\\(\\s*\\$\\s*([0-9][0-9,]*(?:\\.[0-9]+)?)\\s*\\)")[, 2]
    non_amt <- stringr::str_match(
      tail, paste0("non-?government[^$)]{0,40}\\(?\\s*\\$\\s*",
                   "([0-9][0-9,]*(?:\\.[0-9]+)?)"))[, 2]

    headline <- num(m[i, 2])
    pct <- as.numeric(m[i, 3])
    full <- !is.na(pct) && abs(pct - 100) < 1e-9
    cms_amount <- if (!is.na(cms_amt)) num(cms_amt) else NA_real_
    tier <- if (!is.na(cms_amount)) cms_amount else if (full) headline else NA_real_

    tibble::tibble(
      headline_amount = headline, cms_pct = pct, cms_amount = cms_amount,
      nonfederal_amount = if (!is.na(non_amt)) num(non_amt) else NA_real_,
      fully_federal = full, tier_amount = tier,
      sentence = stringr::str_trim(paste0(m[i, 1], tail)))
  })
  dplyr::bind_rows(rows)
}

#' The one figure from a footer that may be compared against the §7.1 anchor
#'
#' @param text Character. Text containing exactly one footer.
#' @param which Integer. Which footer, when the text carries several (New
#'   Hampshire's page carries two -- its allotment and FHC's own award).
#'
#' @return The CMS share as a single number, or NA with a message when the
#'   footer states a partial share without printing its dollar figure.
#'
#' NEVER RETURNS A COMPUTED FIGURE. See the block above: headline x pct is a
#' number no publisher printed (§0.4).
rhtp_footer_cms_share <- function(text, which = 1L) {
  f <- rhtp_footer_parse(text)
  if (!nrow(f)) {
    stop("[§0.2] rhtp_footer_cms_share(): no CMS financial-assistance footer ",
         "found in this text.", call. = FALSE)
  }
  if (which > nrow(f)) {
    stop("[§0.2] rhtp_footer_cms_share(): asked for footer ", which,
         " and the text carries ", nrow(f), ".", call. = FALSE)
  }
  row <- f[which, ]
  if (is.na(row$tier_amount)) {
    message("[§0.2] the footer states ", row$cms_pct,
            "% funded by CMS and prints NO dollar figure for that share. The ",
            "headline of $", formatC(row$headline_amount, format = "f",
                                     digits = 2, big.mark = ","),
            " is federal money PLUS a match, so it is not the figure to tier-",
            "check -- and headline x percentage is a number nobody published ",
            "(§0.4). Read the document.")
  }
  row$tier_amount
}

#' Tier-check a footer read straight out of a document, on its CMS share
#'
#' The wrapper the state files should use. `rhtp_assert_footer_not_allotment()`
#' takes a number and cannot know whether it was handed a headline or a CMS
#' share; this takes the TEXT, so the distinction is made where the evidence
#' is, once, rather than by every caller remembering.
#'
#' @inheritParams rhtp_assert_footer_not_allotment
#' @param text Character. The document text carrying the footer.
#' @param which Integer. Which footer in that text.
rhtp_assert_footer_text_tier <- function(text, state, declared_tier,
                                         label = "a footer figure",
                                         which = 1L,
                                         margin = RHTP_FOOTER_ALLOTMENT_MARGIN,
                                         allotments = NULL) {
  share <- rhtp_footer_cms_share(text, which = which)
  if (is.na(share)) {
    message("[§0.2] ", label, ": the tier check could NOT run -- the footer ",
            "states a partial CMS share and prints no dollar figure for it. ",
            "That is a gap, not a pass (§0.4).")
    return(invisible(NA))
  }
  rhtp_assert_footer_not_allotment(
    amount = share, state = state, declared_tier = declared_tier,
    label = label, margin = margin, allotments = allotments)
}


# -- Probes: the evidence guard and the results log --------------------------
#
# Every state file that carries a `--probe` runs it from a Routine, unattended,
# on a schedule. Two things follow from that, and both are enforced here rather
# than in nineteen state files that would each have to remember.
#
# FIRST: A PROBE READS. IT DOES NOT WRITE TO THE EVIDENCE ARCHIVE. A probe asks
# whether the live page still says what the committed archive says. If it
# rewrites the archive on the way past, it has destroyed the very thing it was
# comparing against -- the next run compares the live page to itself and reports
# UNCHANGED forever, and the archive's fetch dates stop meaning "when this
# document was read" and start meaning "when the Routine last fired".
#
# That is not hypothetical. `tx_probe()` called `tx_fetch_sources(force = TRUE)`
# from session 19 until session 46, so every Texas Routine firing re-dated
# eleven evidence files and silently re-based the negative it was supposed to be
# re-checking. `rhtp_probe_run()` is what makes the rule a rule: it snapshots
# data/evidence/ around the probe and REFUSES if anything moved.
#
# SECOND: A VERDICT NOBODY CAN READ IS NOT A VERDICT. A Routine firing leaves
# its answer inside a session transcript, so "has Mississippi announced?" costs
# a human the work of opening the fired session to find out. Every probe
# therefore appends its verdict to logs/probe_results.csv, which is COMMITTED
# (§0.5), so the history of every watch is in the repository and greppable.

#' Where the probe results log lives
rhtp_probe_log_path <- function() {
  cfg <- rhtp_config()
  if (!is.null(cfg$paths$probe_results)) {
    here::here(cfg$paths$probe_results)
  } else {
    rhtp_path("logs", "probe_results.csv")
  }
}

RHTP_PROBE_LOG_COLUMNS <- c("state", "probed_at", "verdict", "page", "note")

# The verdicts a probe row may carry. Deliberately small, and deliberately
# NOT a free-text field: this log is read by grep and by a human scanning a
# column, and a fourth spelling of "changed" would defeat both.
#
#   UNCHANGED  the live page is content-identical to the committed archive
#   CHANGED    it is not -- re-fetch and READ it; this is the signal
#   TRIPWIRE   an assertion fired, so the probe stopped. The strongest verdict
#              here, and the one most easily lost: an error unwinds the call
#              stack, so without this the run that MATTERED would be the only
#              one leaving no trace in the log.
#   ERROR      the probe could not complete for a reason that is not a
#              tripwire -- a host refusing, a timeout. A statement about our
#              access, never about the state (§0.4).
RHTP_PROBE_VERDICTS <- c("UNCHANGED", "CHANGED", "TRIPWIRE", "ERROR")


#' Snapshot data/evidence/ cheaply enough to do it on every probe
#'
#' Path, size and mtime rather than a digest of 109 MB across 329 files. A
#' re-fetch that writes byte-identical content still moves the mtime, and that
#' is exactly the case worth catching -- `tx_fetch_sources(force = TRUE)`
#' rewrote files whose bytes had not changed, and a digest-only snapshot would
#' have called that clean.
rhtp_evidence_snapshot <- function(root = rhtp_path("evidence")) {
  if (!dir.exists(root)) return(tibble::tibble(path = character(0),
                                               size = numeric(0),
                                               mtime = numeric(0)))
  files <- list.files(root, recursive = TRUE, all.files = TRUE,
                      full.names = TRUE, no.. = TRUE)
  if (!length(files)) return(tibble::tibble(path = character(0),
                                            size = numeric(0),
                                            mtime = numeric(0)))
  info <- file.info(files)
  tibble::tibble(path = files,
                 size = as.numeric(info$size),
                 mtime = as.numeric(info$mtime)) %>%
    dplyr::arrange(.data$path)
}


#' Refuse if a probe touched the evidence archive
#'
#' @param before,after Snapshots from `rhtp_evidence_snapshot()`.
#' @param state Two-letter code, for the message.
rhtp_assert_evidence_untouched <- function(before, after, state = "??") {
  added   <- setdiff(after$path, before$path)
  removed <- setdiff(before$path, after$path)
  common  <- intersect(before$path, after$path)

  b <- before[match(common, before$path), ]
  a <- after[match(common, after$path), ]
  moved <- common[b$size != a$size | b$mtime != a$mtime]

  if (!length(added) && !length(removed) && !length(moved)) {
    return(invisible(TRUE))
  }

  say <- function(label, paths) {
    if (!length(paths)) return(character(0))
    paste0("  ", label, " (", length(paths), "): ",
           paste(basename(utils::head(paths, 6L)), collapse = ", "),
           if (length(paths) > 6L) ", ..." else "")
  }
  stop("[", state, "] THE PROBE WROTE TO data/evidence/, AND A PROBE READS ",
       "RATHER THAN WRITES.\n",
       paste(c(say("added", added), say("removed", removed),
               say("rewritten", moved)), collapse = "\n"), "\n",
       "  A probe that re-fetches into the archive destroys the baseline it ",
       "is comparing against: the next run compares the live page to itself ",
       "and reports UNCHANGED forever. Fetch into MEMORY and compare a ",
       "content digest -- `wi_probe()` and `ms_probe()` are the pattern. ",
       "Re-dating the archive is what `--fetch --force` is for, and it is a ",
       "deliberate act a human takes after READING what changed.",
       call. = FALSE)
}


#' Normalise whatever a probe returned into rows for the log
#'
#' The nineteen probes were written over twenty sessions and return four
#' different shapes. Normalising them centrally, once, is what lets the CLI
#' branch in every state file be the same single line -- the alternative is
#' nineteen bits of bespoke glue, which is nineteen places for the log to
#' quietly stop being written.
#'
#' Recognised, in order:
#'   * a data frame with a page-ish column and a changed-ish logical column
#'     -> one row per page (Mississippi, Wisconsin, Missouri, Kentucky, ...)
#'   * a list with `$sources`, each carrying `$changed` -> one row per source
#'   * a list with a scalar `$changed`                  -> one row, page "(all)"
#'   * a bare logical                                   -> one row, page "(all)"
#'   * anything else -> one row, verdict UNCHANGED, page "(unreported)". The
#'     probe ran and did not throw; it simply does not say which page moved.
#'     Recording that honestly beats inventing a page name (§0.4).
rhtp_probe_rows <- function(result) {
  # Vectorised deliberately: isTRUE() collapses a vector to a single FALSE, so
  # using it here reports every page of a multi-page probe as UNCHANGED -- the
  # one wrong answer this log must never give.
  verdict_of <- function(x) {
    x <- as.logical(x)
    ifelse(!is.na(x) & x, "CHANGED", "UNCHANGED")
  }
  one <- function(page, changed, note = NA_character_) {
    tibble::tibble(verdict = verdict_of(changed), page = page, note = note)
  }

  if (is.data.frame(result) && nrow(result) > 0L) {
    page_col <- intersect(c("page", "key", "source", "name", "file", "url"),
                          names(result))
    chg_col  <- intersect(c("content_changed", "changed", "file_changed",
                            "has_changed"), names(result))
    if (length(page_col) && length(chg_col)) {
      return(one(as.character(result[[page_col[1]]]),
                 as.logical(result[[chg_col[1]]])))
    }
  }

  # `[[` rather than `$`: a tibble IS a list, and `$` on one warns about an
  # unknown column. A probe returning a tibble with neither a page nor a
  # changed column is a real case (South Dakota's portal probe), so this path
  # must fall through it silently rather than emitting two warnings per run.
  has <- function(x, nm) is.list(x) && nm %in% names(x)

  if (has(result, "sources") && length(result[["sources"]])) {
    src <- result[["sources"]]
    pages <- names(src)
    if (is.null(pages)) pages <- paste0("source_", seq_along(src))
    changed <- vapply(src, function(x) isTRUE(x$changed), logical(1))
    return(one(pages, changed))
  }

  # `$changed` means two different things across the nineteen, and guessing
  # between them is how a watch log reports the wrong answer with confidence.
  #   * LOGICAL  -> "did anything move?"            (Alaska, Wisconsin, Texas)
  #   * CHARACTER -> "which pages moved?"           (Maine, California,
  #                                                  Connecticut, New Mexico)
  # Both are unambiguous once the TYPE is read, so the type is read.
  if (has(result, "changed")) {
    ch <- result[["changed"]]
    if (is.logical(ch) && length(ch) == 1L) {
      return(one("(all)", isTRUE(ch)))
    }
    if (is.character(ch)) {
      if (!length(ch)) return(one("(all)", FALSE))
      return(one(ch, rep(TRUE, length(ch))))
    }
  }

  # A bare character vector of changed keys (Wyoming).
  if (is.character(result)) {
    if (!length(result)) return(one("(all)", FALSE))
    return(one(result, rep(TRUE, length(result))))
  }

  # A BARE LOGICAL IS AMBIGUOUS AND IS DELIBERATELY NOT GUESSED AT. Some probes
  # have returned `invisible(TRUE)` as a SUCCESS sentinel -- the tripwires
  # passed -- which is the exact opposite of "this page CHANGED". Reading it
  # either way is a coin toss recorded as a fact, so it falls through to
  # (unreported) with the reason. Louisiana was the one such probe and was
  # given an explicit shape in session 46 rather than a rule bent to fit it.
  one("(unreported)", FALSE,
      if (is.logical(result) && length(result) == 1L) {
        "the probe returned a bare logical, which cannot be told apart from a success sentinel"
      } else {
        "the probe returned no per-page detail"
      })
}


#' Append probe rows to the committed log
#'
#' Appends bytes rather than rewriting the file, so a concurrent Routine cannot
#' lose another's rows, and so the diff of a probe run is exactly the lines it
#' added.
rhtp_probe_log <- function(state, rows, at = Sys.time(),
                           path = rhtp_probe_log_path()) {
  stopifnot(is.data.frame(rows), all(c("verdict", "page") %in% names(rows)))
  bad <- setdiff(rows$verdict, RHTP_PROBE_VERDICTS)
  if (length(bad)) {
    stop("[probe log] unknown verdict(s): ", paste(unique(bad), collapse = ", "),
         ". Allowed: ", paste(RHTP_PROBE_VERDICTS, collapse = " | "),
         ". A new verdict is a deliberate addition here, not a spelling that ",
         "arrives from a state file.", call. = FALSE)
  }

  out <- tibble::tibble(
    state    = toupper(as.character(state)),
    probed_at = format(as.POSIXct(at, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ",
                       tz = "UTC"),
    verdict  = as.character(rows$verdict),
    page     = as.character(rows$page),
    note     = if ("note" %in% names(rows)) as.character(rows$note)
               else NA_character_)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  fresh <- !file.exists(path)
  # readr writes the header only when the file is new; append otherwise.
  readr::write_csv(out, path, append = !fresh, col_names = fresh,
                   na = "", eol = "\n")
  invisible(out)
}


#' Run a probe: guard the evidence archive, log the verdict, re-raise
#'
#' The single entry point every `--probe` CLI branch goes through.
#'
#'   if ("--probe" %in% args) rhtp_probe_run("MS", ms_probe())
#'
#' `expr` is lazy, so it is evaluated INSIDE the guard rather than before it,
#' and a tripwire is caught, logged and re-raised rather than silently
#' swallowed -- the Routine must still fail loudly, because a fired tripwire is
#' the signal this whole apparatus exists to deliver.
rhtp_probe_run <- function(state, expr, path = rhtp_probe_log_path(),
                           evidence_root = rhtp_path("evidence")) {
  started <- Sys.time()
  before  <- rhtp_evidence_snapshot(evidence_root)

  res <- tryCatch(force(expr), error = function(e) e)

  after <- rhtp_evidence_snapshot(evidence_root)

  if (inherits(res, "error")) {
    msg <- conditionMessage(res)
    # A tripwire and a refused host are different claims and the log keeps them
    # apart: one is a statement about the state, the other about our access.
    verdict <- if (grepl("HTTP|refused|timed out|timeout|resolve|connect",
                         msg, ignore.case = TRUE)) "ERROR" else "TRIPWIRE"
    rhtp_probe_log(state,
                   tibble::tibble(verdict = verdict, page = "(probe)",
                                  note = gsub("[\r\n]+", " ", msg)),
                   at = started, path = path)
    # The evidence guard still runs, and it outranks the tripwire: a probe that
    # both fired and wrote has two problems, and the write is the one that
    # corrupts the archive for every future run.
    rhtp_assert_evidence_untouched(before, after, state = state)
    stop(res)
  }

  rhtp_assert_evidence_untouched(before, after, state = state)
  rhtp_probe_log(state, rhtp_probe_rows(res), at = started, path = path)
  invisible(res)
}

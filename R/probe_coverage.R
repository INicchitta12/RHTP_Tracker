# probe_coverage.R ------------------------------------------------------------
# Does every scheduled probe leave a line in logs/probe_results.csv?
#
# WHY THIS FILE EXISTS (session 52). New York's roster was public from
# 2026-09-04. Its Routine fired on 9/6, 9/9, 9/13, 9/16 and 9/20, every
# `last_run` reads ROUTINE_RUN_STATUS_SUCCEEDED, and logs/probe_results.csv on
# `main` held NO New York line at all -- not a CHANGED, not a TRIPWIRE,
# nothing. Measured across the whole log: all 58 lines committed before this
# session were written by INTERACTIVE sessions (46, 47, 48, 51). Not one of the
# Routine firings on 9/21 and 9/22 (AK, CT, KY, MS, ME, WI, NM) is in it.
#
# THE CAUSE IS §0.5, NOT THE LOGGER. `rhtp_probe_log()` works: it appends the
# line in the Routine's own container. Nothing then committed or pushed it, and
# the container was reclaimed. A Routine's SUCCEEDED means the session ran,
# never that its verdict reached the repository. So the Routine prompts now end
# by committing that one file and pushing it to `main`, and THIS FILE is the
# check that the push happened: a scheduled firing with no log line is a
# failure, and it says which firing.
#
# UNTIL THIS PASSES FOR A STATE, THAT STATE'S SILENCE IS NOT EVIDENCE.
#
# The schedule is config/routines.csv -- the committed registry of Routines,
# one row per state, with the cron the trigger actually carries and the time
# from which a log line is REQUIRED (`logging_since`). Firings before that time
# predate the fix and were lost; they are listed in the session doc, not
# asserted here, because no amount of checking can recover them.

source(here::here("R", "utils_config.R"))

RHTP_ROUTINES_CSV <- here::here("config", "routines.csv")

# A firing's log line is looked for from the scheduled minute to this many
# hours after it. Measured: Routines start 0-13 minutes late (KY 9/21 fired at
# 19:37 for 19:30, MO 9/16 at 15:10 for 15:00) and the slowest probe runs a
# few minutes. Six hours is generous by design -- the point is to catch a run
# that left NOTHING, not to police latency.
RHTP_PROBE_GRACE_HOURS <- 6

rhtp_read_routines <- function(path = RHTP_ROUTINES_CSV) {
  r <- readr::read_csv(path, col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  need <- c("state", "trigger_id", "cron_utc", "script", "logging_since")
  miss <- setdiff(need, names(r))
  if (length(miss)) {
    stop("[coverage] config/routines.csv lacks: ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  r$logging_since <- as.POSIXct(r$logging_since, format = "%Y-%m-%dT%H:%M:%SZ",
                                tz = "UTC")
  if (anyNA(r$logging_since)) {
    stop("[coverage] a logging_since in config/routines.csv does not parse.",
         call. = FALSE)
  }
  if (anyDuplicated(r$state)) {
    stop("[coverage] a state appears twice in config/routines.csv.",
         call. = FALSE)
  }
  r
}

#' Parse the cron shapes this project's Routines use: "M H * * DOW"
#'
#' Deliberately narrow. Every Routine here fires at one minute of one hour on
#' a list of weekdays; anything else is REFUSED rather than approximated,
#' because a coverage check that silently mis-reads a schedule reports gaps
#' that are not there or, worse, misses ones that are.
rhtp_parse_cron <- function(cron) {
  f <- strsplit(stringr::str_squish(cron), " ")[[1]]
  if (length(f) != 5L || f[3] != "*" || f[4] != "*" ||
      !grepl("^[0-9]+$", f[1]) || !grepl("^[0-9]+$", f[2]) ||
      !grepl("^(\\*|[0-6](,[0-6])*)$", f[5])) {
    stop("[coverage] cron '", cron, "' is not of the form 'M H * * D[,D]'. ",
         "Extend rhtp_parse_cron() deliberately rather than guessing.",
         call. = FALSE)
  }
  list(minute = as.integer(f[1]), hour = as.integer(f[2]),
       dow = if (f[5] == "*") 0:6 else as.integer(strsplit(f[5], ",")[[1]]))
}

#' Every scheduled firing in [from, to), as POSIXct UTC
rhtp_cron_firings <- function(cron, from, to) {
  cr <- rhtp_parse_cron(cron)
  days <- seq(as.Date(from, tz = "UTC") - 1, as.Date(to, tz = "UTC"), by = 1)
  days <- days[as.integer(format(days, "%w")) %in% cr$dow]
  if (!length(days)) return(as.POSIXct(character(0), tz = "UTC"))
  f <- as.POSIXct(sprintf("%s %02d:%02d:00", format(days), cr$hour, cr$minute),
                  tz = "UTC")
  f[f >= from & f < to]
}

rhtp_read_probe_log <- function(path = rhtp_probe_log_path()) {
  if (!file.exists(path)) {
    return(tibble::tibble(state = character(0),
                          probed_at = as.POSIXct(character(0), tz = "UTC"),
                          verdict = character(0)))
  }
  l <- readr::read_csv(path, col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  l$probed_at <- as.POSIXct(l$probed_at, format = "%Y-%m-%dT%H:%M:%SZ",
                            tz = "UTC")
  l
}

#' One row per scheduled firing that is due, and whether it left a log line
#'
#' @param as_of The instant to check up to. A firing is DUE once its grace
#'   window has closed; one still inside its window is neither passed nor
#'   failed. `rhtp_probe_coverage_as_of_log()` gives the deterministic choice
#'   the test suite uses.
rhtp_probe_coverage <- function(as_of = Sys.time(),
                                routines = rhtp_read_routines(),
                                log = rhtp_read_probe_log(),
                                grace_hours = RHTP_PROBE_GRACE_HOURS) {
  as_of <- as.POSIXct(as_of, tz = "UTC")
  grace <- grace_hours * 3600
  purrr::map_dfr(seq_len(nrow(routines)), function(i) {
    r <- routines[i, ]
    fires <- rhtp_cron_firings(r$cron_utc, r$logging_since, as_of - grace)
    if (!length(fires)) return(NULL)
    # A line counts for a firing only if THAT Routine wrote it. A line with no
    # origin at all predates session 52's column and is accepted as legacy;
    # "interactive" never is.
    org <- if ("origin" %in% names(log)) log$origin else rep(NA_character_, nrow(log))
    mine <- log$state == r$state &
      (is.na(org) | !nzchar(org) | org == r$trigger_id)
    lines <- log$probed_at[mine]
    tibble::tibble(
      state = r$state, trigger_id = r$trigger_id, scheduled = fires,
      logged = purrr::map_lgl(fires, function(f) {
        any(lines >= f & lines < f + grace, na.rm = TRUE)
      }))
  })
}

#' The deterministic as_of: the newest line in the committed log
#'
#' Checking up to the log's own newest entry means the suite asks a question
#' the committed files can answer the same way on every machine: of the
#' firings that fell due before the last thing anybody logged, did each leave
#' a line? The live form (`as_of = Sys.time()`) is what a Routine runs, and it
#' is the one that notices a log that has stopped growing altogether.
rhtp_probe_coverage_as_of_log <- function(log = rhtp_read_probe_log()) {
  if (!nrow(log)) return(as.POSIXct("1970-01-01", tz = "UTC"))
  max(log$probed_at, na.rm = TRUE)
}

#' THE ASSERTION: a scheduled probe that left no log entry fails, by name
rhtp_assert_probe_coverage <- function(as_of = Sys.time(),
                                       routines = rhtp_read_routines(),
                                       log = rhtp_read_probe_log(),
                                       grace_hours = RHTP_PROBE_GRACE_HOURS) {
  cov <- rhtp_probe_coverage(as_of, routines, log, grace_hours)
  if (!nrow(cov)) return(invisible(cov))
  gaps <- cov[!cov$logged, , drop = FALSE]
  if (nrow(gaps)) {
    stop("[coverage] ", nrow(gaps), " SCHEDULED PROBE FIRING(S) LEFT NO LINE ",
         "IN logs/probe_results.csv: ",
         paste0(gaps$state, " ", format(gaps$scheduled, "%Y-%m-%d %H:%M"),
                "Z (", gaps$trigger_id, ")", collapse = "; "),
         ". A Routine's SUCCEEDED means its session ran, not that its verdict ",
         "reached the repository. UNTIL EACH OF THESE IS EXPLAINED, THAT ",
         "STATE'S SILENCE IS NOT EVIDENCE (§0.5, §2.2). Open the firing's ",
         "session, find why its commit did not reach main, and fix the ",
         "Routine -- never back-fill a line it did not write.", call. = FALSE)
  }
  invisible(cov)
}

#' Every registered Routine must point at a real --probe that logs
rhtp_assert_routines_registry <- function(routines = rhtp_read_routines()) {
  for (i in seq_len(nrow(routines))) {
    f <- here::here(routines$script[i])
    if (!file.exists(f)) {
      stop("[coverage] ", routines$state[i], "'s Routine points at ",
           routines$script[i], ", which does not exist.", call. = FALSE)
    }
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (!grepl("rhtp_probe_run\\(", src)) {
      stop("[coverage] ", routines$script[i], " does not route --probe through ",
           "rhtp_probe_run(), so its Routine cannot leave a log line.",
           call. = FALSE)
    }
    rhtp_parse_cron(routines$cron_utc[i])
  }
  invisible(TRUE)
}


if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--check" %in% args) {
    rhtp_assert_routines_registry()
    cov <- rhtp_assert_probe_coverage()
    message("[coverage] ", nrow(cov), " due firing(s) since the logging fix, ",
            "all logged.")
  } else if ("--report" %in% args) {
    cov <- rhtp_probe_coverage()
    if (!nrow(cov)) {
      message("[coverage] no firing has fallen due since logging_since.")
    } else {
      print(as.data.frame(cov), row.names = FALSE)
    }
  } else {
    message("Usage: Rscript R/probe_coverage.R --check | --report")
  }
}

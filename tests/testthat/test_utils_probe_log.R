# test_utils_probe_log.R -----------------------------------------------------
# The probe apparatus: the evidence-write guard, the results log, and the
# normaliser that turns nineteen differently-shaped probe returns into rows.
#
# WHY THIS FILE EXISTS. From session 19 until session 46 `tx_probe()` called
# `tx_fetch_sources(force = TRUE)`, so every firing of the Texas Routine
# rewrote eleven files under data/evidence/TX/ and re-dated the manifest. The
# damage was not untidiness: `tx_validate()` reads the archive, so after the
# re-fetch the probe was comparing the live site to bytes it had just
# downloaded, and could only ever report that Texas had not moved. A roster
# appearing on an RFA page would have been archived FIRST and asserted against
# SECOND, and the tripwire designed to fail the build would have passed on the
# roster it was watching for.
#
# Nothing caught it for twenty-seven sessions because nothing looked. These
# tests look, on every run, for every state at once.

library(testthat)

source(here::here("R", "utils_config.R"))

# A sandbox evidence root and log, so nothing here touches the real archive.
probe_sandbox <- function() {
  root <- file.path(tempfile("evidence"), "MS")
  dir.create(root, recursive = TRUE)
  writeLines("held", file.path(root, "archived.html"))
  list(root = dirname(root), log = tempfile(fileext = ".csv"))
}


test_that("a probe that leaves the evidence archive alone is accepted", {
  sb <- probe_sandbox()
  expect_silent(
    rhtp_probe_run("XX", invisible(TRUE), path = sb$log,
                   evidence_root = sb$root))
  expect_true(file.exists(sb$log))
})


test_that("a probe that ADDS a file to data/evidence/ is REFUSED", {
  sb <- probe_sandbox()
  expect_error(
    rhtp_probe_run("XX",
                   writeLines("new", file.path(sb$root, "MS", "added.html")),
                   path = sb$log, evidence_root = sb$root),
    "THE PROBE WROTE TO data/evidence/")
})


test_that("a probe that REWRITES an existing file is REFUSED", {
  # THE TEXAS CASE EXACTLY, and the reason the snapshot carries mtime rather
  # than only a digest: tx_fetch_sources(force = TRUE) rewrote files whose
  # BYTES had not changed, and a content-only check calls that clean.
  sb <- probe_sandbox()
  held <- file.path(sb$root, "MS", "archived.html")
  expect_error(
    rhtp_probe_run("TX", {
      Sys.setFileTime(held, Sys.time() + 60)
      TRUE
    }, path = sb$log, evidence_root = sb$root),
    "rewritten")
})


test_that("a probe that DELETES an archived file is REFUSED", {
  sb <- probe_sandbox()
  expect_error(
    rhtp_probe_run("XX", file.remove(file.path(sb$root, "MS", "archived.html")),
                   path = sb$log, evidence_root = sb$root),
    "removed")
})


test_that("the guard names the offending files rather than just complaining", {
  sb <- probe_sandbox()
  msg <- tryCatch(
    rhtp_probe_run("XX",
                   writeLines("x", file.path(sb$root, "MS", "roster.html")),
                   path = sb$log, evidence_root = sb$root),
    error = conditionMessage)
  expect_match(msg, "roster.html", fixed = TRUE)
  # And it says what to do instead, because a refusal a future session cannot
  # act on gets worked around rather than fixed.
  expect_match(msg, "--fetch --force", fixed = TRUE)
})


# -- the log -----------------------------------------------------------------

test_that("a multi-page probe logs one row per page, with the right verdicts", {
  # THE BUG THIS PINS: isTRUE() is not vectorised, so an earlier draft reported
  # EVERY page of a multi-page probe as UNCHANGED -- the one wrong answer a
  # watch log must never give, because it is indistinguishable from a quiet
  # week.
  sb <- probe_sandbox()
  rhtp_probe_run("MS",
                 tibble::tibble(key = c("funding", "home", "gov_newsroom"),
                                content_changed = c(TRUE, FALSE, TRUE)),
                 path = sb$log, evidence_root = sb$root)
  got <- readr::read_csv(sb$log, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(got), 3L)
  expect_equal(got$page, c("funding", "home", "gov_newsroom"))
  expect_equal(got$verdict, c("CHANGED", "UNCHANGED", "CHANGED"))
  expect_true(all(got$state == "MS"))
})


test_that("all five probe return shapes normalise", {
  # Nineteen probes written over twenty sessions return four shapes. The
  # normaliser is central so the CLI branch in every state file can be one
  # line; these are the shapes actually in use.
  df <- rhtp_probe_rows(tibble::tibble(key = c("a", "b"),
                                       content_changed = c(FALSE, TRUE)))
  expect_equal(df$verdict, c("UNCHANGED", "CHANGED"))

  lst <- rhtp_probe_rows(list(changed = TRUE,
                              sources = list(x = list(changed = FALSE),
                                             y = list(changed = TRUE))))
  expect_equal(lst$page, c("x", "y"))
  expect_equal(lst$verdict, c("UNCHANGED", "CHANGED"))

  scalar <- rhtp_probe_rows(list(changed = TRUE))
  expect_equal(scalar$page, "(all)")
  expect_equal(scalar$verdict, "CHANGED")

  # A bare logical is deliberately NOT one of them -- see the ambiguity test
  # below. It records (unreported) rather than a guessed verdict.
  bare <- rhtp_probe_rows(FALSE)
  expect_equal(bare$page, "(unreported)")
  expect_equal(bare$verdict, "UNCHANGED")

  keys <- rhtp_probe_rows(list(changed = c("news", "programme")))
  expect_equal(keys$page, c("news", "programme"))
  expect_equal(keys$verdict, c("CHANGED", "CHANGED"))
})


test_that("a probe with no per-page detail says so rather than inventing one", {
  # §0.4: recording "(unreported)" is honest; naming a page the probe never
  # named is a claim about which page moved.
  got <- rhtp_probe_rows(tibble::tibble(probe = "x", rows = 0L))
  expect_equal(got$page, "(unreported)")
  expect_equal(got$verdict, "UNCHANGED")
  expect_match(got$note, "no per-page detail")
})


test_that("A FIRED TRIPWIRE IS LOGGED, AND STILL RE-RAISED", {
  # The run that MATTERS is the one that throws. An error unwinds the call
  # stack, so without this the only firing anybody cares about would be the
  # only one leaving no trace in the log -- while the Routine must still fail
  # loudly, because the throw IS the signal.
  sb <- probe_sandbox()
  expect_error(
    rhtp_probe_run("LA", stop("the seven windows are gone"),
                   path = sb$log, evidence_root = sb$root),
    "the seven windows are gone")
  got <- readr::read_csv(sb$log, show_col_types = FALSE, progress = FALSE)
  expect_equal(got$verdict, "TRIPWIRE")
  expect_equal(got$state, "LA")
  expect_match(got$note, "seven windows")
})


test_that("a refused host logs ERROR, not TRIPWIRE", {
  # The two are different claims and the log keeps them apart: a tripwire is a
  # statement about the STATE, a 403 is a statement about OUR ACCESS (§0.4).
  sb <- probe_sandbox()
  expect_error(
    rhtp_probe_run("NH", stop("HTTP 403 for dhhs.nh.gov"),
                   path = sb$log, evidence_root = sb$root))
  got <- readr::read_csv(sb$log, show_col_types = FALSE, progress = FALSE)
  expect_equal(got$verdict, "ERROR")
})


test_that("the log appends rather than rewriting, and keeps its header once", {
  sb <- probe_sandbox()
  rhtp_probe_run("WI", list(changed = FALSE), path = sb$log,
                 evidence_root = sb$root)
  rhtp_probe_run("MO", list(changed = TRUE), path = sb$log,
                 evidence_root = sb$root)
  lines <- readLines(sb$log)
  expect_equal(sum(grepl("^state,probed_at", lines)), 1L)
  got <- readr::read_csv(sb$log, show_col_types = FALSE, progress = FALSE)
  expect_equal(got$state, c("WI", "MO"))
})


test_that("an unknown verdict is refused rather than written", {
  # The column is read by grep and by eye; a fourth spelling of "changed"
  # defeats both. A new verdict is a deliberate addition to
  # RHTP_PROBE_VERDICTS, not a string arriving from a state file.
  expect_error(
    rhtp_probe_log("XX", tibble::tibble(verdict = "MOVED", page = "p"),
                   path = tempfile(fileext = ".csv")),
    "unknown verdict")
})


test_that("the committed log exists and every row is well formed", {
  path <- rhtp_probe_log_path()
  skip_if_not(file.exists(path), "no probe has run in this checkout yet")
  got <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(names(got), RHTP_PROBE_LOG_COLUMNS)
  expect_true(all(got$verdict %in% RHTP_PROBE_VERDICTS))
  expect_true(all(nchar(got$state) == 2L))
  expect_false(anyNA(got$probed_at))
})


test_that("EVERY --probe CLI branch goes through the guard", {
  # The guard only guards what calls it. This is the check that a twentieth
  # state file cannot quietly reintroduce Texas's defect: if a file offers
  # --probe, its dispatch must hand the probe to rhtp_probe_run().
  files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  offenders <- character(0)
  for (f in files) {
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (!grepl('"--probe" %in% args', src, fixed = TRUE)) next
    if (!grepl("rhtp_probe_run(", src, fixed = TRUE)) {
      offenders <- c(offenders, basename(f))
    }
  }
  expect_equal(offenders, character(0))
})


test_that("no probe function reaches its own --fetch writer", {
  # Texas's defect stated as a rule: a probe body must not call the function
  # that archives. Read out of the source rather than trusted, because the
  # call was there for twenty-seven sessions and read as ordinary.
  files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  offenders <- character(0)
  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    starts <- grep("^[a-z_]+_probe <- function", lines)
    for (st in starts) {
      ends <- grep("^\\}$", lines)
      en <- ends[ends > st][1]
      if (is.na(en)) next
      body <- paste(lines[st:en], collapse = "\n")
      if (grepl("_fetch[_a-z]*\\(", body)) {
        offenders <- c(offenders, paste0(basename(f), ":", lines[st]))
      }
    }
  }
  expect_equal(offenders, character(0))
})


test_that("`$changed` is read by TYPE, because it means two different things", {
  # LOGICAL means "did anything move?" (Alaska, Wisconsin, Texas). CHARACTER
  # means "which pages moved?" (Maine, California, Connecticut, New Mexico).
  # Guessing between them is how a watch log reports the wrong answer with
  # confidence -- an earlier draft read New Mexico's one changed key as a
  # scalar and logged it UNCHANGED.
  logical_shape <- rhtp_probe_rows(list(changed = TRUE))
  expect_equal(logical_shape$page, "(all)")
  expect_equal(logical_shape$verdict, "CHANGED")

  char_shape <- rhtp_probe_rows(list(changed = c("news", "programme")))
  expect_equal(char_shape$page, c("news", "programme"))
  expect_equal(char_shape$verdict, c("CHANGED", "CHANGED"))

  # One key is the case that was wrong: length 1 is not a scalar flag.
  one_key <- rhtp_probe_rows(list(changed = "news"))
  expect_equal(one_key$page, "news")
  expect_equal(one_key$verdict, "CHANGED")

  # And no keys means nothing moved, not "no detail".
  none <- rhtp_probe_rows(list(changed = character(0)))
  expect_equal(none$page, "(all)")
  expect_equal(none$verdict, "UNCHANGED")
})


test_that("a bare character vector of keys is Wyoming's shape", {
  expect_equal(rhtp_probe_rows(c("drive", "programme"))$verdict,
               c("CHANGED", "CHANGED"))
  expect_equal(rhtp_probe_rows(character(0))$verdict, "UNCHANGED")
})


test_that("A BARE LOGICAL IS AMBIGUOUS AND IS NOT GUESSED AT", {
  # `invisible(TRUE)` has been used as a SUCCESS sentinel -- the tripwires
  # passed -- which is the exact opposite of "this page CHANGED". Louisiana
  # returned that until session 46 and the log recorded it as CHANGED on a run
  # where nothing had. Reading it either way is a coin toss recorded as a fact.
  got <- rhtp_probe_rows(TRUE)
  expect_equal(got$page, "(unreported)")
  expect_equal(got$verdict, "UNCHANGED")
  expect_match(got$note, "success sentinel")
})


test_that("no probe still returns a bare logical", {
  # The rule above is only safe because the ambiguous returns were FIXED
  # rather than accommodated. This is what stops one coming back.
  files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  offenders <- character(0)
  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    starts <- grep("^[a-z_]+_probe <- function", lines)
    for (st in starts) {
      ends <- grep("^\\}$", lines)
      en <- ends[ends > st][1]
      if (is.na(en)) next
      body <- lines[st:en]
      if (any(grepl("^\\s*invisible\\((TRUE|FALSE)\\)\\s*$", body))) {
        offenders <- c(offenders, paste0(basename(f), ":", lines[st]))
      }
    }
  }
  expect_equal(offenders, character(0))
})

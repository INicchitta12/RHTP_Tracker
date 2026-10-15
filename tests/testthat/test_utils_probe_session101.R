# test_utils_probe_session101.R ----------------------------------------------
# Session 101: three defects that shared one cause. A probe's FIRST failure
# was its LAST word.
#   (a) MO 2026-10-14: the name tripwire threw before mo_assert_smrp() ran, so
#       $34,646,479.34 of newly priced hospital awards was found by a human.
#   (b) MS 2026-10-13: one host's empty reply stopped the whole probe.
#   (c) MT 2026-10-14: the evidence guard refused, nothing was logged, and the
#       newsroom sweep counted the refusal as a TRIPWIRE.
# Every test here is a fixture: no network, a sandbox evidence root and log.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

s101_sandbox <- function() {
  root <- file.path(tempfile("evidence"), "XX")
  dir.create(root, recursive = TRUE)
  writeLines("<html><body><main><p>Held page. Alpha County Hospital and ",
             file.path(root, "a.html"))
  writeLines(c("<html><body><main><p>Alpha County Hospital, Beta Medical ",
               "Center and Gamma Health District are named here.</p></main>",
               "</body></html>"), file.path(root, "named.html"))
  list(root = dirname(root), log = tempfile(fileext = ".csv"),
       named = file.path(root, "named.html"))
}

read_log <- function(p) {
  readr::read_csv(p, show_col_types = FALSE, progress = FALSE,
                  col_types = readr::cols(.default = "c"))
}

archived_names <- paste("Alpha County Hospital, Beta Medical Center and Gamma Health District",
                        "are named here. So are Zeta Community Clinic and Theta Rural Health Network.")
live_names <- paste(archived_names, "Delta Regional Hospital received an award.")


# -- (a) a name trip is recorded, and every other check still runs ------------

test_that("(a) a name trip no longer hides the checks that come after it", {
  sb <- s101_sandbox()
  ran_after <- FALSE
  probe <- function() {
    rhtp_assert_no_new_organisations_across(
      live = list(program_page = live_names),
      archived = list(program_page = archived_names), state = "XX")
    # MO's shape: a phrase check AFTER the name tripwire. It must run.
    ran_after <<- TRUE
    list(changed = TRUE,
         findings = "SMRP: the SMRP page now carries currency beyond '$35 million'",
         sources = list(program_page = list(changed = TRUE)))
  }
  err <- expect_error(rhtp_probe_run("XX", probe(), path = sb$log,
                                     evidence_root = sb$root))
  expect_true(ran_after)
  # ONE error carrying BOTH messages.
  expect_match(conditionMessage(err), "Delta Regional Hospital")
  expect_match(conditionMessage(err), "currency beyond", fixed = TRUE)
  got <- read_log(sb$log)
  expect_setequal(got$page, c("program_page", "(finding)"))
  expect_equal(sum(got$verdict == "TRIPWIRE"), 2L)
  expect_equal(got$verdict[got$page == "(finding)"], "TRIPWIRE")
  # The name trip's row is keyed on the PAGE that named somebody.
  expect_match(got$note[got$page == "program_page" & got$verdict == "TRIPWIRE"],
               "Delta Regional Hospital")
})

test_that("(a) every watched page is diffed, not just the first that fires", {
  sb <- s101_sandbox()
  probe <- function() {
    rhtp_assert_no_new_organisations_across(
      live = list(one = live_names,
                  two = paste(archived_names, "Epsilon Health Foundation was selected.")),
      archived = list(one = archived_names, two = archived_names), state = "XX")
    tibble::tibble(key = c("one", "two"), changed = c(TRUE, TRUE))
  }
  err <- expect_error(rhtp_probe_run("XX", probe(), path = sb$log,
                                     evidence_root = sb$root))
  expect_match(conditionMessage(err), "Delta Regional Hospital")
  expect_match(conditionMessage(err), "Epsilon Health Foundation")
  got <- read_log(sb$log)
  expect_equal(sort(got$page[got$verdict == "TRIPWIRE"]), c("one", "two"))
})

test_that("(a) outside a probe run the name tripwire still throws at once", {
  expect_error(rhtp_assert_no_new_organisations(live_names, archived_names,
                                                "XX", "p"),
               "THAT IS THE SIGNAL")
  expect_false(rhtp_probe_ctx_active())
})

test_that("(a) a probe that also fails outright logs its error AND the name trip", {
  sb <- s101_sandbox()
  probe <- function() {
    rhtp_assert_no_new_organisations_across(
      live = list(p = live_names), archived = list(p = archived_names),
      state = "XX")
    stop("[XX] the seven windows are gone")
  }
  err <- expect_error(rhtp_probe_run("XX", probe(), path = sb$log,
                                     evidence_root = sb$root))
  expect_match(conditionMessage(err), "seven windows")
  expect_match(conditionMessage(err), "Delta Regional Hospital")
  got <- read_log(sb$log)
  expect_setequal(got$page, c("(probe)", "p"))
  expect_true(all(got$verdict == "TRIPWIRE"))
})

test_that("(a) a clean probe is unchanged by any of this", {
  sb <- s101_sandbox()
  expect_silent(rhtp_probe_run(
    "XX", list(changed = FALSE, findings = character(0)), path = sb$log,
    evidence_root = sb$root))
  expect_equal(read_log(sb$log)$verdict, "UNCHANGED")
  expect_false(rhtp_probe_ctx_active())
})


# -- (b) a failed page fetch is ERROR for that page; the probe goes on --------

test_that("(b) rhtp_probe_get logs ERROR and hands back the ARCHIVED bytes", {
  sb <- s101_sandbox()
  arch <- file.path(sb$root, "XX", "a.html")
  other_ran <- FALSE
  probe <- function() {
    a <- rhtp_probe_get("dom_completed", function()
      stop("Server returned nothing (no headers, no data) [medicaid.ms.gov]: ",
           "Empty reply from server"), arch)
    b <- rhtp_probe_get("funding", function() charToRaw("live"), arch)
    other_ran <<- identical(rawToChar(b), "live")
    # The failed page compares content-identical: it is the archive.
    held <- readBin(arch, "raw", file.size(arch))
    tibble::tibble(key = c("dom_completed", "funding"),
                   changed = c(!identical(a, held), FALSE))
  }
  expect_no_error(rhtp_probe_run("MS", probe(), path = sb$log,
                                 evidence_root = sb$root))
  expect_true(other_ran)
  got <- read_log(sb$log)
  expect_equal(got$verdict[got$page == "dom_completed"], "ERROR")
  expect_match(got$note[got$page == "dom_completed"], "Empty reply")
  expect_equal(got$verdict[got$page == "funding"], "UNCHANGED")
})

test_that("(b) a page missing from the probe's own rows still gets its ERROR row", {
  sb <- s101_sandbox()
  arch <- file.path(sb$root, "XX", "a.html")
  probe <- function() {
    rhtp_probe_get("gone", function() stop("HTTP 503 from x"), arch)
    list(changed = FALSE)
  }
  rhtp_probe_run("XX", probe(), path = sb$log, evidence_root = sb$root)
  got <- read_log(sb$log)
  expect_setequal(got$page, c("(all)", "gone"))
  expect_equal(got$verdict[got$page == "gone"], "ERROR")
})

test_that("(b) only ACCESS failures continue; a tripwire in a fetcher still throws", {
  sb <- s101_sandbox()
  arch <- file.path(sb$root, "XX", "a.html")
  expect_error(rhtp_probe_run("XX", rhtp_probe_get("p", function()
    stop("[XX] refusing to archive p: it carries a mapbox_token"), arch),
    path = sb$log, evidence_root = sb$root), "mapbox")
  expect_equal(read_log(sb$log)$verdict, "TRIPWIRE")
})

test_that("(b) outside a probe run (--fetch) a failed fetch still throws", {
  expect_error(rhtp_probe_get("p", function() stop("HTTP 403 from x"),
                                tempfile()), "HTTP 403")
})

test_that("(b) rhtp_watch_pages reads past a failed page", {
  sb <- s101_sandbox()
  arch_a <- file.path(sb$root, "XX", "a.html")
  pages <- tibble::tibble(key = c("down", "up"), url = c("u1", "u2"),
                          file = c(arch_a, sb$named), name_diff = TRUE)
  real <- rhtp_watch_fetch
  assign("rhtp_watch_fetch", function(url, agent, cainfo = NULL) {
    if (url == "u1") stop("HTTP 403 from u1", call. = FALSE)
    readBin(sb$named, "raw", file.size(sb$named))
  }, envir = globalenv())
  withr::defer(assign("rhtp_watch_fetch", real, envir = globalenv()))
  # here::here() of an absolute path is that path, so the sandbox files serve.
  probe <- function() rhtp_watch_pages(pages, agent = "test")$changed
  rhtp_probe_run("XX", probe(), path = sb$log, evidence_root = sb$root)
  got <- read_log(sb$log)
  expect_equal(got$verdict[got$page == "down"], "ERROR")
  expect_equal(got$verdict[got$page == "up"], "UNCHANGED")
})


# -- (c) an evidence-guard refusal is logged, as ERROR -------------------------

test_that("(c) a guard refusal is logged ERROR before it is raised", {
  sb <- s101_sandbox()
  expect_error(
    rhtp_probe_run("MT", {
      writeLines("x", file.path(sb$root, "XX", "written_by_a_reader.html"))
      list(changed = FALSE)
    }, path = sb$log, evidence_root = sb$root),
    "EVIDENCE GUARD REFUSAL")
  got <- read_log(sb$log)
  expect_equal(got$page, "(evidence guard)")
  expect_equal(got$verdict, "ERROR")
  expect_match(got$note, "written_by_a_reader")
})

test_that("(c) the verdict classifier calls a guard refusal ERROR (nw_sweep reads it)", {
  sb <- s101_sandbox()
  err <- tryCatch(rhtp_probe_run("MT", {
    writeLines("x", file.path(sb$root, "XX", "w.html")); TRUE
  }, path = sb$log, evidence_root = sb$root), error = function(e) e)
  expect_equal(rhtp_probe_verdict(conditionMessage(err)), "ERROR")
})

test_that("(c) a probe that fired AND wrote logs both, and the guard wins", {
  sb <- s101_sandbox()
  expect_error(
    rhtp_probe_run("XX", {
      writeLines("x", file.path(sb$root, "XX", "w2.html"))
      stop("[XX] the seven windows are gone")
    }, path = sb$log, evidence_root = sb$root),
    "EVIDENCE GUARD REFUSAL")
  got <- read_log(sb$log)
  expect_setequal(got$page, c("(probe)", "(evidence guard)"))
  expect_equal(got$verdict[got$page == "(evidence guard)"], "ERROR")
  expect_equal(got$verdict[got$page == "(probe)"], "TRIPWIRE")
})


# -- the bespoke probes route their fetches through the shared helper ----------

test_that("every probe with its own fetch loop reads past a failed page", {
  files <- c("03aa_me", "03ab_ca", "03ac_ct", "03ad_nm", "03ae_la", "03af_ky",
             "03ag_ny", "03ah_nc", "03ai_ar", "03ak_ms", "03al_de", "03am_id",
             "03an_oh", "03ao_sc", "03n_tx", "03w_mo", "03y_wi", "03at_vt",
             "03av_wv", "03r_ne")
  for (f in files) {
    path <- Sys.glob(here::here("R", paste0(f, "*.R")))
    expect_length(path, 1L)
    src <- paste(readLines(path, warn = FALSE), collapse = "\n")
    expect_true(grepl("rhtp_probe_get(", src, fixed = TRUE), info = f)
  }
  expect_true(grepl("rhtp_probe_get(", paste(readLines(
    here::here("R", "utils_page_watch.R")), collapse = "\n"), fixed = TRUE))
})

# test_session75_probes.R ----------------------------------------------------
# Session 75: Montana, New Hampshire, Oklahoma and Minnesota got probes. Every
# tripwire is driven offline against the COMMITTED baseline in both directions:
# silent on the baseline itself, and firing on a synthesised change of exactly
# the kind it exists for (test_queued_state_probes.R's rule: a tripwire never
# seen to fire is not known to work).

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

read_arch <- function(pages) {
  lapply(stats::setNames(pages$file, pages$key),
         function(f) rhtp_watch_reduce(here::here(f)))
}

test_that("every session-75 probe routes through the guard and runs the name tripwire", {
  for (f in c("03bl_mt_year1_probe.R", "03bm_nh_year1_probe.R",
              "03bn_mn_year1_probe.R", "03t_ok_year1_awardees.R")) {
    src <- paste(readLines(here::here("R", f), warn = FALSE), collapse = "\n")
    expect_true(grepl("rhtp_probe_run(", src, fixed = TRUE), info = f)
    expect_true(grepl("rhtp_assert_no_new_organisations_across(", src,
                      fixed = TRUE), info = f)
  }
})

test_that("the watch digest ignores whitespace and nothing else", {
  # rhtp_watch_archive() re-serialises "CalendarGet" as "Calendar Get".
  p <- withr::local_tempfile(fileext = ".html")
  writeLines("<html><body><main><a>Add to Calendar</a> <a>Get</a></main></body></html>", p)
  txt <- rhtp_watch_reduce(p)
  squash <- function(x) gsub("\\s+", "", x)
  expect_identical(squash(txt), squash("Add to CalendarGet"))
  expect_false(identical(squash("Awards to Alpha"), squash("Award to Alpha")))
})

# -- Montana -----------------------------------------------------------------

source(here::here("R", "03bl_mt_year1_probe.R"))
mt <- read_arch(MT_PAGES)

test_that("MT: the 2026-10-05 baseline carries the award block and passes", {
  # Session 88: Montana awarded (R/03bv); this is now a ROSTER watch.
  expect_true(mt_assert_watch(mt, mt))
  expect_true(grepl("Date Awarded: Sept. 29, 2026", mt$grants, fixed = TRUE))
})

test_that("MT: the sentences R/03bv's rows rest on going trips", {
  l <- mt; l$release <- sub("Four agencies were awarded ambulances",
                            "Agencies received ambulances", l$release, fixed = TRUE)
  expect_error(mt_assert_watch(l, mt), "NO LONGER SAYS")
  l <- mt; l$grants <- sub("Date Awarded: Sept. 29, 2026", "Date Awarded: TBD",
                           l$grants, fixed = TRUE)
  expect_error(mt_assert_watch(l, mt), "NO LONGER SAYS")
})

test_that("MT: a named equipment roster or a new round trips", {
  l <- mt; l$release <- paste(l$release,
    "Equipment awards were made to Glacier County EMS and Big Sandy Ambulance.")
  expect_error(mt_assert_watch(l, mt), "release")
  l <- mt; l$grants <- paste(l$grants,
    "Community Integrated Health Pilot Site Grants were awarded to three agencies.")
  expect_error(mt_assert_watch(l, mt), "grants")
  l <- mt; l$communications <- paste(l$communications,
    "DPHHS Announces Rural EMS Equipment Grant Recipients.")
  expect_error(mt_assert_watch(l, mt), "communications")
  # And the NAME tripwire fires on a roster added in words no phrase list has.
  l <- mt$release
  live <- paste(l, "Glacier County Emergency Medical Services Inc. Big Sandy Volunteer Ambulance Association.")
  expect_error(rhtp_assert_no_new_organisations_across(
    live = list(release = live), archived = list(release = mt$release),
    state = "MT"), "THAT IS THE SIGNAL")
})

# -- New Hampshire -------------------------------------------------------------

source(here::here("R", "03bm_nh_year1_probe.R"))
nh <- read_arch(NH_PAGES)

test_that("NH: both anchors are in the baseline and it passes", {
  expect_true(nh_assert_watch(nh, nh))
})

test_that("NH: the hospital RFA leaving 'Coming Soon' trips", {
  l <- nh; l$fhc <- sub("Acute Care Hospital Coming Soon",
                        "Acute Care Hospital Open", l$fhc, fixed = TRUE)
  expect_error(nh_assert_watch(l, nh), "Coming Soon")
})

test_that("NH: naming subrecipients trips; FHC's baseline award language does not", {
  expect_true(grepl("50–100 active subrecipient awards", nh$fhc, fixed = TRUE))
  l <- nh; l$fhc <- paste(l$fhc,
    "FHC announces its first EMS subrecipients: Littleton Regional Healthcare.")
  expect_error(nh_assert_watch(l, nh), "fhc")
})

# -- Minnesota -------------------------------------------------------------------

source(here::here("R", "03bn_mn_year1_probe.R"))
mn <- read_arch(MN_PAGES)

test_that("MN: the 94-hospital table is in the baseline and it passes", {
  expect_true(mn_assert_watch(mn, mn))
})

test_that("MN: the allocation table being re-cut trips (§0.3)", {
  l <- mn; l$grants <- gsub("Award94", "Award 93 ", l$grants, fixed = TRUE)
  l$grants <- gsub("RHTP Award 94", "RHTP Award 93", l$grants, fixed = TRUE)
  expect_error(mn_assert_watch(l, mn), "direct-allocation table")
})

test_that("MN: naming grantees trips; 'Grant recipients will select' in the baseline does not", {
  expect_true(grepl("Grant recipients will select activities", mn$grants,
                    fixed = TRUE))
  l <- mn; l$grants <- paste(l$grants,
    "Direct allocation grants were awarded to 91 rural hospitals.")
  expect_error(mn_assert_watch(l, mn), "grants")
})

# -- Oklahoma ------------------------------------------------------------------

test_that("OK: the probe baseline is separate from the extraction archive", {
  e <- new.env()
  sys.source(here::here("R", "03t_ok_year1_awardees.R"), envir = e)
  f <- e$ok_probe_baseline_file("funding")
  # Re-based 2026-10-02 (session 86) after RRR and CDM were written.
  expect_match(f, "probe_baseline/2026-10-02_ok_rhtp_funding.html$")
  expect_true(file.exists(here::here(f)))
  expect_false(identical(f, e$ok_path("funding")))
  # The live-bytes override is empty outside a probe, so --validate still
  # reads the archive.
  expect_length(ls(e$.ok_live), 0L)
})

test_that("OK: the pending-opportunity check fires on live bytes carrying an award", {
  e <- new.env()
  sys.source(here::here("R", "03t_ok_year1_awardees.R"), envir = e)
  raw <- readBin(here::here(e$ok_path("recipients")), "raw",
                 file.info(here::here(e$ok_path("recipients")))$size)
  # Session 86: CDM is written and no longer pending; Behavioral Health
  # Integration still is.
  txt <- sub("</main>", "<p>Behavioral Health Integration awardees</p></main>",
             rawToChar(raw), fixed = TRUE)
  assign("recipients", charToRaw(txt), envir = e$.ok_live)
  e$ok_cache_clear()
  expect_error(e$ok_assert_pending_not_awarded(), "Funding Recipients page")
  rm(list = ls(e$.ok_live), envir = e$.ok_live)
  e$ok_cache_clear()
  expect_true(e$ok_assert_pending_not_awarded())
})

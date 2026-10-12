# test_03bs_al_year2_probe.R -------------------------------------------------
# Session 84: Alabama's Community Medicine watch. Every tripwire is driven
# offline against the COMMITTED baseline in both directions: silent on the
# baseline itself, and firing on a synthesised change of exactly the kind it
# exists for (a tripwire never seen to fire is not known to work).

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))
source(here::here("R", "03bs_al_year2_probe.R"))

al <- lapply(stats::setNames(AL_PAGES$file, AL_PAGES$key),
             function(f) rhtp_watch_reduce(here::here(f)))

test_that("AL: the probe routes through the guard and runs the name tripwire", {
  src <- paste(readLines(here::here("R", "03bs_al_year2_probe.R"),
                         warn = FALSE), collapse = "\n")
  expect_true(grepl("rhtp_probe_run(", src, fixed = TRUE))
  expect_true(grepl("rhtp_assert_no_new_organisations_across(", src,
                    fixed = TRUE))
})

test_that("AL: the baseline passes, with ten NOFOs and none for Community Medicine", {
  expect_true(al_assert_watch(al, al))
  expect_equal(stringr::str_count(al$resources, "NOFO For "), 10L)
  expect_false(grepl("Community Medicine", al$resources, fixed = TRUE))
  # Both Year 1 award headlines are in the baseline, so neither can fire.
  expect_true(grepl("Totaling Nearly $55 Million", al$governor, fixed = TRUE))
})

test_that("AL: the Year 1 closure sentence going trips (Year 2 has opened)", {
  l <- al
  l$resources <- sub(AL_ANCHOR, "Year 2 applications are now open.",
                     l$resources, fixed = TRUE)
  expect_error(al_assert_watch(l, al), "NO LONGER SAYS")
})

test_that("AL: a Community Medicine NOFO trips the resources page", {
  l <- al
  l$resources <- paste(l$resources,
    "NOFO For Community Medicine Initiative Download File.")
  expect_error(al_assert_watch(l, al), "resources")
})

test_that("AL: a new ARHTP headline trips the Governor's newsroom; other news does not", {
  l <- al
  l$governor <- paste(l$governor,
    "10.9.2026 Governor Ivey Announces Rural Health Transformation Program Community Medicine Grants Read Full Text")
  expect_error(al_assert_watch(l, al), "governor")
  l <- al
  l$governor <- paste(l$governor,
    "10.9.2026 Governor Ivey Awards Grant to Geneva for Wastewater Repairs Read Full Text")
  expect_true(al_assert_watch(l, al))
})

test_that("AL: new non-ARHTP headlines above the old ARHTP one do not trip (the 10-08 false positive)", {
  # The first Routine firing tripped because the index has no full stops:
  # new headlines made the whole page one new "sentence" that still held the
  # 10-01 ARHTP headline. Diffed by dated headline, it is quiet.
  expect_length(al_governor_headlines(al$governor), 1L)
  l <- al
  l$governor <- sub("10.1.2026", paste("10.7.2026 State of Emergency: Tropical",
    "Storm Isaias Download Read Full Text 10.6.2026 Flags Lowered Download",
    "Read Full Text 10.1.2026"), l$governor, fixed = TRUE)
  expect_true(al_assert_watch(l, al))
})

test_that("AL: a newly named organisation trips the name tripwire", {
  live <- al[AL_PAGES$key[AL_PAGES$name_diff]]
  arch <- live
  expect_invisible(rhtp_assert_no_new_organisations_across(
    live = live, archived = arch, state = "AL"))
  live$home <- paste(live$home,
    "Mobile wellness units were funded for Greene County Health System.")
  expect_error(rhtp_assert_no_new_organisations_across(
    live = live, archived = arch, state = "AL"), "Greene County Health System")
})

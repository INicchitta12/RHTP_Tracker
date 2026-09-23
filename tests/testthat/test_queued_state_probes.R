# test_queued_state_probes.R -------------------------------------------------
# Session 59: Colorado, North Dakota, Virginia and Washington got probes and
# Routines. Every tripwire is driven offline against the COMMITTED archive, in
# both directions: silent on the archive itself, and firing on a synthesised
# change of exactly the kind it exists for. A tripwire that has never been seen
# to fire is not known to work.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

read_arch <- function(pages) {
  lapply(stats::setNames(pages$file, pages$key),
         function(f) rhtp_watch_reduce(here::here(f)))
}

# -- the shared engine -------------------------------------------------------

test_that("the reducer drops scripts and zero-width characters", {
  t <- rhtp_watch_reduce(charToRaw(paste0(
    "<html><body><main>Gila​Regional Medical Center",
    "<script>var k='AIzaXXXX';</script></main></body></html>")))
  expect_equal(t, "GilaRegional Medical Center")
})

test_that("a new sentence fires and a baseline sentence does not", {
  a <- "HCPF has awarded a contract to the Colorado Rural Health Center. Other."
  expect_length(rhtp_watch_new_sentences(a, a, "award"), 0L)
  l <- paste(a, "Awards were made to Alpha Hospital.")
  expect_equal(rhtp_watch_new_sentences(l, a, "award"),
               "Awards were made to Alpha Hospital.")
})

test_that("a quoted 'Connecting' does not turn a tripwire into an ERROR", {
  msg <- tryCatch(rhtp_watch_forbid_new("Coordinating and Connecting Care awarded.",
                                        "", "award", "ND", "p", "why"),
                  error = conditionMessage)
  expect_false(grepl("HTTP|refused|timed out|timeout|resolve|connect", msg,
                     ignore.case = TRUE))
})

test_that("the probe engine never writes, and every probe routes through the guard", {
  for (f in c("03az_co_year1_probe.R", "03ba_nd_year1_probe.R",
              "03bb_va_year1_probe.R", "03bc_wa_year1_probe.R",
              "03ay_tn_year1_awardees.R")) {
    src <- paste(readLines(here::here("R", f), warn = FALSE), collapse = "\n")
    expect_true(grepl("rhtp_probe_run(", src, fixed = TRUE), info = f)
    expect_true(grepl("rhtp_assert_no_new_organisations_across(", src,
                      fixed = TRUE), info = f)
  }
  eng <- paste(readLines(here::here("R", "utils_page_watch.R")), collapse = "\n")
  body <- sub("rhtp_watch_archive <- function.*", "", eng)
  expect_false(grepl("write_html|writeBin|writeLines|cat\\(", body))
})

# -- Colorado ------------------------------------------------------------------

source(here::here("R", "03az_co_year1_probe.R"))
co <- read_arch(CO_PAGES)

test_that("CO: the archive carries the dated anchor and passes", {
  expect_silent(co_assert_watch(co, co))
})

test_that("CO: the anchor going trips", {
  l <- co; l$rhtp <- sub(CO_ANCHOR, "", l$rhtp, fixed = TRUE)
  expect_error(co_assert_watch(l, co), "NO LONGER SAYS")
})

test_that("CO: a new award sentence trips; HCPF's baseline contract award does not", {
  expect_match(co$rhtp, "HCPF has awarded a contract", fixed = TRUE)
  l <- co; l$rhtp <- paste(l$rhtp, "Award recipients are listed below.")
  expect_error(co_assert_watch(l, co), "NEW SENTENCE")
})

test_that("CO: an RHTP item on the Governor's index trips", {
  l <- co; l$governor_news <- paste(l$governor_news,
    "Polis Administration Announces Rural Health Transformation Program Grants.")
  expect_error(co_assert_watch(l, co), "governor_news")
})

# -- North Dakota --------------------------------------------------------------

source(here::here("R", "03ba_nd_year1_probe.R"))
nd_file <- here::here(ND_PAGES$file[ND_PAGES$key == "funding"])
nd_html <- paste(readLines(nd_file, warn = FALSE), collapse = "\n")

test_that("ND: 25 headings, one Awarded, and the archive passes", {
  hd <- nd_headings(nd_file)
  expect_equal(nrow(hd), 25L)
  expect_equal(hd$name[hd$status == "Awarded"], ND_KNOWN_AWARDED)
  expect_silent(nd_assert_headings(nd_file))
})

test_that("ND: a second heading turning 'Awarded' trips", {
  hot <- sub("Hospital-Based Wellness Equipment – Closed",
             "Hospital-Based Wellness Equipment – Awarded", nd_html,
             fixed = TRUE)
  expect_false(identical(hot, nd_html))
  expect_error(nd_assert_headings(charToRaw(hot)),
               "NEW OPPORTUNITY HEADED 'AWARDED'.*Hospital-Based")
})

test_that("ND: a page with no headings is our reader, not North Dakota", {
  expect_error(nd_assert_headings(charToRaw("<html><body><h2>x</h2></body></html>")),
               "our READER|READER")
})

# -- Virginia ------------------------------------------------------------------

source(here::here("R", "03bb_va_year1_probe.R"))
va <- read_arch(VA_PAGES)

test_that("VA: both administrators' award dates are in the archive", {
  expect_silent(va_assert_watch(va, va))
})

test_that("VA: VHCF's 30 September sentence going trips", {
  l <- va; l$vhcf <- sub(VA_ANCHORS$vhcf, "VHCF has shared its Notice of Awards.",
                         l$vhcf, fixed = TRUE)
  expect_error(va_assert_watch(l, va), "vhcf")
})

test_that("VA: a new award sentence on the RHT news page trips", {
  l <- va; l$news <- paste(l$news, "Virginia announces the first RHT grant recipients.")
  expect_error(va_assert_watch(l, va), "news")
})

test_that("VA: the certificate repair adds the intermediate and switches nothing off", {
  f <- va_cainfo()
  pem <- readLines(f, warn = FALSE)
  expect_true(sum(grepl("BEGIN CERTIFICATE", pem)) > 1L)
  expect_true(all(readLines(VA_INTERMEDIATE) %in% pem))
  src <- paste(readLines(here::here("R", "03bb_va_year1_probe.R")), collapse = "\n")
  expect_false(grepl("ssl_verifypeer|verifypeer = 0|verifypeer = FALSE", src))
  expect_true(file.exists(here::here("config", "certs", "README.md")))
})

test_that("VA: the VHCF baseline carries no credential", {
  raw <- paste(readLines(here::here(VA_PAGES$file[1]), warn = FALSE), collapse = "")
  expect_false(grepl("AIza[0-9A-Za-z_-]{20,}", raw))
})

# -- Washington ----------------------------------------------------------------

source(here::here("R", "03bc_wa_year1_probe.R"))
wa <- read_arch(WA_PAGES)

test_that("WA: the archive passes, and both footers tier as the allotment", {
  expect_silent(wa_assert_watch(wa, wa))
  f <- wa_assert_footers(wa$programme)
  expect_equal(sort(f$form), c("SUBAWARD_OF", "TOTALING"))
  expect_equal(f$subaward_cms_amount[f$form == "SUBAWARD_OF"], 3500000)
})

test_that("WA: the subaward footer disappearing trips rather than going silent", {
  l <- wa; l$programme <- sub("through a subaward as part of a financial assistance award of",
                              "as part of a grant of", l$programme, fixed = TRUE)
  expect_error(wa_assert_watch(l, wa), "SUBAWARD footer")
})

test_that("WA: an apparent successful bidder on HCA's bids page trips", {
  l <- wa; l$bids <- paste(l$bids,
    "Apparent successful bidder: Rural Health Transformation competitive award.")
  expect_error(wa_assert_watch(l, wa), "bids")
})

test_that("WA: naming sub-award recipients trips", {
  l <- wa; l$working_on <- paste(l$working_on,
    "Sub-awardees selected include Alpha Hospital and Beta Medical Center.")
  expect_error(wa_assert_watch(l, wa), "working_on")
})

# -- the registry ----------------------------------------------------------------

test_that("all five new states are registered with a probe that logs", {
  r <- readr::read_csv(here::here("config", "routines.csv"), show_col_types = FALSE)
  expect_true(all(c("CO", "ND", "VA", "WA", "TN") %in% r$state))
})

# test_utils_agent_scope.R ---------------------------------------------------
# news.delaware.gov takes the project's honest agent (session 96).
#
# Session 95 gave news.delaware.gov a browser agent (owner decision). The same
# day's measurement showed the F5 block intermittent for BOTH agents (project
# 7/8 served, Chrome 5/8), so the firewall is not keyed to the agent and the
# retry is what cures it. Session 96 removed the exception on the owner's
# instruction. CLAUDE.md §3 is "identify honestly to every state host", and
# michigan.gov's bare agent (tested in test_03v) is again the ONLY exception.
#
# These tests hold that: no browser agent anywhere in R/, the Delaware
# fetchers send the honest agent, and the firewall retry is still wired.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

r_src <- function(f) {
  paste(readLines(here::here("R", f), warn = FALSE), collapse = "\n")
}

test_that("no file in R/ carries a browser user-agent string", {
  # michigan.gov's bare 'Mozilla/5.0' is not a browser string and is tested in
  # test_03v. A Chrome/Safari/Gecko agent anywhere in R/ is the session-95
  # exception coming back.
  hits <- character(0)
  for (f in list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)) {
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (grepl("AppleWebKit|Chrome/[0-9]|Safari/[0-9]|Gecko\\) ", src)) {
      hits <- c(hits, basename(f))
    }
  }
  expect_identical(hits, character(0))
})

test_that("the session-95 agent helpers are gone", {
  expect_false(exists("RHTP_DE_NEWS_USER_AGENT"))
  expect_false(exists("rhtp_agent_for_url"))
  expect_false(exists("rhtp_assert_agent_scope"))
  for (f in list.files(here::here("R"), pattern = "\\.R$")) {
    expect_false(grepl("rhtp_agent_for_url|RHTP_DE_NEWS_USER_AGENT", r_src(f)),
                 info = f)
  }
})

test_that("the Delaware fetchers send the project's honest agent", {
  suppressMessages(source(here::here("R", "03al_de_year1_awardees.R")))
  expect_true(grepl("aha.org", DE_USER_AGENT, fixed = TRUE))
  expect_true(any(vapply(DE_SOURCES$url, function(u) {
    identical(tolower(httr::parse_url(u)$hostname), "news.delaware.gov")
  }, logical(1))))
  de <- r_src("03al_de_year1_awardees.R")
  expect_true(grepl("httr::user_agent(DE_USER_AGENT)", de, fixed = TRUE))

  suppressMessages(source(here::here("R", "03bg_newsroom_sweep.R")))
  expect_true(grepl("aha.org", NW_USER_AGENT, fixed = TRUE))
  expect_true("DE" %in% NW_PAGES$state)
  nw <- r_src("03bg_newsroom_sweep.R")
  expect_true(grepl("httr::user_agent(NW_USER_AGENT)", nw, fixed = TRUE))

  watch <- paste(deparse(rhtp_watch_fetch), collapse = "\n")
  expect_true(grepl("httr::user_agent(agent)", watch, fixed = TRUE))
})

test_that("the firewall retry stays wired into the Delaware fetch paths", {
  # The retry, not the agent, is what cures news.delaware.gov's block.
  watch <- paste(deparse(rhtp_watch_fetch), collapse = "\n")
  expect_true(grepl("rhtp_fetch_past_firewall", watch, fixed = TRUE))
  expect_true(grepl("rhtp_fetch_past_firewall(function()",
                    r_src("03al_de_year1_awardees.R"), fixed = TRUE))
})

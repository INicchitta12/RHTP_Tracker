# test_utils_agent_scope.R ---------------------------------------------------
# The second host-scoped user-agent exception (session 95): news.delaware.gov.
#
# CLAUDE.md §3 is "identify honestly to every state host". michigan.gov's bare
# agent was the one recorded exception (tested in test_03v). The owner took a
# second in session 95, for news.delaware.gov's F5 firewall, and these tests
# hold it to the same shape: ONE host, exact hostname, refused in both
# directions, and the browser string written in one place only.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))

HONEST <- "Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)"

test_that("news.delaware.gov alone gets the browser agent", {
  expect_identical(
    rhtp_agent_for_url("https://news.delaware.gov/", HONEST),
    RHTP_DE_NEWS_USER_AGENT)
  expect_identical(
    rhtp_agent_for_url(paste0("https://news.delaware.gov/2026/07/29/governor-",
                              "meyer-announces-funding/"), HONEST),
    RHTP_DE_NEWS_USER_AGENT)
  # Case in the hostname does not matter; the host does.
  expect_identical(rhtp_agent_for_url("https://NEWS.Delaware.gov/", HONEST),
                   RHTP_DE_NEWS_USER_AGENT)
  # Every other host keeps the honest agent -- other Delaware hosts included,
  # and a lookalike that merely contains the hostname.
  for (u in c("https://dhss.delaware.gov/dph/rural-health-transformation-program/",
              "https://delaware.gov/", "https://www.delaware.gov/",
              "https://news.delaware.gov.example.com/",
              "https://example.com/news.delaware.gov/",
              "https://www.kdhe.ks.gov/2361/Rural-Health-Transformation-Program",
              "https://www.michigan.gov/mdhhs")) {
    a <- rhtp_agent_for_url(u, HONEST)
    expect_identical(a, HONEST, info = u)
    expect_true(grepl("aha.org", a, fixed = TRUE), info = u)
  }
})

test_that("the browser agent is refused off its host, and the honest agent on it", {
  expect_error(
    rhtp_assert_agent_scope("https://dhss.delaware.gov/", RHTP_DE_NEWS_USER_AGENT),
    "scoped to news.delaware.gov")
  expect_error(
    rhtp_agent_for_url("https://example.gov/", RHTP_DE_NEWS_USER_AGENT),
    "scoped to news.delaware.gov")
  expect_error(
    rhtp_assert_agent_scope("https://news.delaware.gov/", HONEST),
    "firewall rejects")
  expect_true(rhtp_assert_agent_scope("https://news.delaware.gov/",
                                      RHTP_DE_NEWS_USER_AGENT))
  expect_true(rhtp_assert_agent_scope("https://dhss.delaware.gov/", HONEST))
})

test_that("every Delaware source and newsroom page resolves to the right agent", {
  suppressMessages(source(here::here("R", "03al_de_year1_awardees.R")))
  for (i in seq_len(nrow(DE_SOURCES))) {
    u <- DE_SOURCES$url[i]
    a <- rhtp_agent_for_url(u, DE_USER_AGENT)
    if (rhtp_url_host(u) == "news.delaware.gov") {
      expect_identical(a, RHTP_DE_NEWS_USER_AGENT, info = u)
    } else {
      expect_identical(a, DE_USER_AGENT, info = u)
    }
  }
  expect_true(any(vapply(DE_SOURCES$url, rhtp_url_host, "") == "dhss.delaware.gov"))

  suppressMessages(source(here::here("R", "03bg_newsroom_sweep.R")))
  for (i in seq_len(nrow(NW_PAGES))) {
    u <- NW_PAGES$url[i]
    a <- rhtp_agent_for_url(u, NW_USER_AGENT)
    if (NW_PAGES$state[i] == "DE") {
      expect_identical(a, RHTP_DE_NEWS_USER_AGENT, info = u)
    } else {
      expect_identical(a, NW_USER_AGENT, info = u)
    }
  }
})

test_that("the browser string is written in utils_config.R and nowhere else in R/", {
  # Any other file carrying a Chrome/Safari browser agent is the exception
  # spreading. michigan.gov's bare 'Mozilla/5.0' is not a browser string and is
  # tested in test_03v.
  hits <- character(0)
  for (f in list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)) {
    src <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (grepl("AppleWebKit|Chrome/[0-9]|Safari/[0-9]|Gecko\\) ", src)) {
      hits <- c(hits, basename(f))
    }
  }
  expect_identical(hits, "utils_config.R")
})

test_that("the shared fetchers route their agent through rhtp_agent_for_url()", {
  watch <- paste(deparse(rhtp_watch_fetch), collapse = "\n")
  expect_true(grepl("rhtp_agent_for_url(url, agent)", watch, fixed = TRUE))
  de <- paste(readLines(here::here("R", "03al_de_year1_awardees.R"),
                        warn = FALSE), collapse = "\n")
  expect_true(grepl("rhtp_agent_for_url(url, DE_USER_AGENT)", de, fixed = TRUE))
  expect_false(grepl("httr::user_agent(DE_USER_AGENT)", de, fixed = TRUE))
})

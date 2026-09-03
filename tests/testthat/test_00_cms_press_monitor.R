# test_00_cms_press_monitor.R ------------------------------------------------
# The CMS trigger-list parser. Fixture-driven, no network calls, zero API quota.
#
# medicaid.gov is not on the environment allowlist, so this parser has never
# seen the real page (see the egress note in R/00_cms_press_monitor.R). That
# makes these tests the whole of its assurance, and they are written for the
# failure that actually matters: NOT that the parser reads one known table, but
# that it REFUSES every shape it does not understand rather than writing a CSV
# that reads as "no state has announced an award".

library(testthat)

source(here::here("R", "00_cms_press_monitor.R"))

fixture <- function(name) {
  paste(readLines(here::here("tests", "fixtures", "cms_press", name),
                  warn = FALSE), collapse = "\n")
}


# -- The tabular shape -------------------------------------------------------

test_that("the tabular shape parses to state, date, amount, title and URL", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))

  expect_equal(attr(out, "cms_press_shape"), "TABLE")
  expect_equal(nrow(out), 4)
  expect_equal(out$state, c("DE", "FL", "GA", "OK"))
  expect_setequal(
    names(out),
    c("state", "date", "amount", "title", "url", "source_url", "first_seen")
  )
})

test_that("a navigation table is not mistaken for the announcement table", {
  # table_shape.html leads with a two-column site-navigation table. It has no
  # resolvable `state` column, so it scores -1 and the announcement table wins.
  # Picking by position would have taken the wrong one.
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_false(any(out$state == "Home"))
  expect_equal(nrow(out), 4)
})

test_that("state names and two-letter codes both resolve to the 7.1 fifty", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  # 'Georgia', 'Florida', 'Oklahoma' by name; 'DE' by code.
  expect_true(all(out$state %in% rhtp_cms_states()$state))
  expect_true("DE" %in% out$state)
})

test_that("all four date formats on the fixture parse", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_false(any(is.na(out$date)))
  expect_equal(out$date[out$state == "GA"], as.Date("2025-12-29"))  # December 29, 2025
  expect_equal(out$date[out$state == "DE"], as.Date("2026-01-30"))  # 2026-01-30
  expect_equal(out$date[out$state == "OK"], as.Date("2026-02-14"))  # 02/14/2026
})

test_that("amounts parse from both literal and scaled currency strings", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_equal(out$amount[out$state == "FL"], 209000000)
  expect_equal(out$amount[out$state == "OK"], 223476949)
  # "$157.4 million" -- the scaled form
  expect_equal(out$amount[out$state == "DE"], 157400000)
  # "$218,862,169.63" rounds to the cent, not to a whole dollar
  expect_equal(out$amount[out$state == "GA"], 218862169.63, tolerance = 1e-6)
})

test_that("relative hrefs are absolutised and absolute ones left alone", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  expect_true(all(startsWith(out$url, "https://www.medicaid.gov/")))
  expect_equal(out$url[out$state == "FL"], "https://www.medicaid.gov/newsroom/fl-rhtp")
})


# -- The link-list shape -----------------------------------------------------

test_that("a link list is parsed when the page carries no announcement table", {
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))

  expect_equal(attr(out, "cms_press_shape"), "LINK_LIST")
  expect_equal(out$state, c("FL", "GA", "NE"))
  expect_equal(out$date[out$state == "GA"], as.Date("2026-07-16"))
  expect_equal(out$amount[out$state == "GA"], 30600000)
  expect_equal(out$amount[out$state == "FL"], 188201256)
})

test_that("a link list row with no amount is NA, never zero", {
  # Nebraska's fixture link states no figure. A zero would be a claim that CMS
  # announced nothing -- exactly the Nebraska $100,000 error in reverse
  # (CLAUDE.md 0.2a), so the absence must stay an absence.
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))
  expect_true(is.na(out$amount[out$state == "NE"]))
})

test_that("links that name no state are ignored", {
  # The fixture carries an 'About this page' link.
  out <- rhtp_parse_cms_press_html(fixture("link_list_shape.html"))
  expect_equal(nrow(out), 3)
  expect_false(any(grepl("About", out$title)))
})


# -- Refusals: the point of the parser ---------------------------------------

test_that("two equally-scoring tables are refused, not resolved by position", {
  expect_error(
    rhtp_parse_cms_press_html(fixture("ambiguous_shape.html")),
    "score equally"
  )
})

test_that("a state outside the 7.1 fifty stops the parse", {
  # A dropped row is a state nobody collects, which is silent and unrecoverable.
  # Stopping is loud and recoverable.
  expect_error(
    rhtp_parse_cms_press_html(fixture("unknown_state.html")),
    "Puerto Rico"
  )
})

test_that("a page with neither shape is refused rather than parsed as empty", {
  expect_error(
    rhtp_parse_cms_press_html(fixture("no_table.html")),
    "No announcement table and no state-named links"
  )
})


# -- Assertions --------------------------------------------------------------

test_that("a zero-row parse fails the assertions", {
  empty <- rhtp_parse_cms_press_html(fixture("table_shape.html"))[0, ]
  expect_error(rhtp_cms_press_assert(empty), "Parsed zero announcements")
})

test_that("the fixture parse passes the assertions", {
  expect_true(rhtp_cms_press_assert(
    rhtp_parse_cms_press_html(fixture("table_shape.html"))
  ))
})

test_that("a future-dated announcement fails the assertions", {
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  out$date[1] <- Sys.Date() + 30
  expect_error(rhtp_cms_press_assert(out), "dated in the future")
})

test_that("amounts totalling more than the whole programme fail the tier guard", {
  # 0.2: this page mixes CMS-to-state allotments (Tier 1) with state subaward
  # announcements (Tier 3). Summing the column blends them, and the guard is
  # what makes that unmissable to whoever adds a total to this stage next.
  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  out$amount <- rep(3e9, nrow(out))
  expect_error(rhtp_cms_press_assert(out), "Tier 1 and Tier 3")
})


# -- Amount parsing in isolation ---------------------------------------------

test_that("cms_press_parse_amount handles the forms a CMS page uses", {
  expect_equal(cms_press_parse_amount("$1,234,567"), 1234567)
  expect_equal(cms_press_parse_amount("$100 million"), 1e8)
  expect_equal(cms_press_parse_amount("$1.2 billion"), 1.2e9)
  expect_equal(cms_press_parse_amount("$218,862,169.63"), 218862169.63,
               tolerance = 1e-6)
})

test_that("cms_press_parse_amount returns NA, never 0, for a non-figure", {
  expect_true(is.na(cms_press_parse_amount("N/A")))
  expect_true(is.na(cms_press_parse_amount("")))
  expect_true(is.na(cms_press_parse_amount("Not yet announced")))
})


# -- Change detection --------------------------------------------------------

test_that("the first run reports every state as new", {
  withr::with_tempdir({
    out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
    # No committed CSV in a temp dir, but the delta reads via here::here(), so
    # exercise the first-run branch directly against a path that cannot exist.
    expect_true(is.character(out$state))
  })

  out <- rhtp_parse_cms_press_html(fixture("table_shape.html"))
  csv <- here::here(CMS_PRESS_CSV)
  skip_if(file.exists(csv),
          "cms_state_announcements.csv exists; the first-run branch no longer applies")

  delta <- rhtp_cms_press_delta(out)
  expect_true(delta$first_run)
  expect_setequal(delta$new_states, c("DE", "FL", "GA", "OK"))
})


# -- Wiring ------------------------------------------------------------------

# Conventions are a property of the CODE, not of the prose describing it: this
# file's own header says "never |>" and "No setwd()", so a naive grep over the
# whole source fails on the documentation of the rule it is checking.
monitor_code <- function() {
  readLines(here::here("R", "00_cms_press_monitor.R"), warn = FALSE) %>%
    stringr::str_remove("#.*$") %>%
    stringr::str_subset("\\S")
}

test_that("the monitor spends no RCJ quota", {
  expect_false(any(grepl("rhtp_api_key|rhtp_auth_headers|rhtp_endpoint_url",
                         monitor_code())))
})

test_that("the monitor uses %>% and never the native pipe (CLAUDE.md 3)", {
  expect_false(any(grepl("|>", monitor_code(), fixed = TRUE)))
})

test_that("the monitor never calls setwd (CLAUDE.md 3)", {
  expect_false(any(grepl("setwd(", monitor_code(), fixed = TRUE)))
})


# -- The live page shape (added when medicaid.gov was allowlisted) ------------
#
# Everything above was written against fixtures, before this script had ever
# seen the real page. It had, and the live page turned out to sit in a blind
# spot: its header row is marked up with <td> rather than <th>, so html_table()
# named the columns X1..X5, every synonym lookup missed, the table scored 0 and
# the parser fell through to the link-list shape. That fallback did not fail --
# it succeeded with less. These pin the fix.

test_that("a header row marked up with <td> is promoted, not fallen through", {
  html <- paste0(
    "<html><body><table>",
    "<tr><td>Press Release</td><td>Date</td><td>State</td></tr>",
    "<tr><td><a href='/x'>Announcement for Georgia</a></td>",
    "<td>08-27-2026</td><td>Georgia</td></tr>",
    "</table></body></html>"
  )
  out <- rhtp_parse_cms_press_html(html)
  expect_equal(attr(out, "cms_press_shape"), "TABLE")
  expect_equal(out$state, "GA")
  expect_equal(out$date, as.Date("2026-08-27"))
})

test_that("promotion is refused when it would resolve no more columns", {
  # Positional names that promote to junk must be left alone, so promotion can
  # only ever improve a parse and never destroy a working one.
  tbl <- tibble::tibble(X1 = c("aaa", "Georgia"), X2 = c("bbb", "08-27-2026"))
  expect_identical(cms_press_promote_header(tbl), tbl)
})

test_that("CMS's own MM-DD-YYYY date format parses", {
  # The live page writes 08-27-2026. The ISO format is tried first and rejects
  # it (month 27) rather than mis-reading it, so the order stays unambiguous.
  expect_equal(cms_press_parse_date("08-27-2026"), as.Date("2026-08-27"))
  expect_equal(cms_press_parse_date("2026-08-27"), as.Date("2026-08-27"))
  expect_equal(cms_press_parse_date("12-29-2025"), as.Date("2025-12-29"))
  expect_true(is.na(cms_press_parse_date("not a date")))
})

test_that("the national 'All' rows are excluded, not mapped to a state", {
  # CMS lists the $50bn programme launch and the all-50-states announcement in
  # the same table, with State = "All". They are the CMS->states programme
  # itself (0.2 Tier 1); this file is the STATE trigger list. Dropping them is
  # deliberate -- and a genuinely unmappable state must still stop the parse.
  html <- paste0(
    "<html><body><table>",
    "<tr><td>Press Release</td><td>Date</td><td>State</td></tr>",
    "<tr><td><a href='/a'>Announcement for Georgia</a></td>",
    "<td>08-27-2026</td><td>Georgia</td></tr>",
    "<tr><td><a href='/b'>CMS Launches Landmark $50 Billion RHT Program</a></td>",
    "<td>09-15-2025</td><td>All</td></tr>",
    "</table></body></html>"
  )
  out <- rhtp_parse_cms_press_html(html)
  expect_equal(nrow(out), 1L)
  expect_equal(out$state, "GA")
  expect_true(cms_press_is_national("All"))
  expect_true(cms_press_is_national(" national "))
  expect_false(cms_press_is_national("Georgia"))
})

test_that("the amount is mined from the headline when there is no amount column", {
  # CMS states the figure in the title, never in a column. The link-list shape
  # always mined it; the table shape must too, or promoting the header would
  # cost the figure it was meant to improve.
  html <- paste0(
    "<html><body><table>",
    "<tr><td>Press Release</td><td>Date</td><td>State</td></tr>",
    "<tr><td><a href='/a'>Announces $93.3 Million for Georgia</a></td>",
    "<td>08-27-2026</td><td>Georgia</td></tr>",
    "<tr><td><a href='/b'>Delivers Critical Funding to North Dakota</a></td>",
    "<td>08-20-2026</td><td>North Dakota</td></tr>",
    "</table></body></html>"
  )
  out <- rhtp_parse_cms_press_html(html)
  expect_equal(out$amount[out$state == "GA"], 93300000)
  # No figure stated is NA, never zero -- a zero would be a claim CMS did not make.
  expect_true(is.na(out$amount[out$state == "ND"]))
})


# -- The live parse, pinned --------------------------------------------------

test_that("the committed live page parses to 8 states via the table shape", {
  archive <- here::here("data", "raw", "cms", "2026-08-28",
                        "medicaid_rhtp_resources.html")
  skip_if_not(file.exists(archive), "the live CMS archive is not on disk")

  out <- rhtp_parse_cms_press_html(paste(readLines(archive, warn = FALSE),
                                         collapse = "\n"))
  expect_equal(attr(out, "cms_press_shape"), "TABLE")
  expect_setequal(out$state, c("AK", "AL", "GA", "ND", "OH", "PA", "SD", "WV"))
  # every state row carries the page's own date, which the link-list shape lost
  expect_true(all(!is.na(out$date)))
  expect_equal(out$date[out$state == "GA"], as.Date("2026-08-27"))
  # ND's headline states no figure
  expect_equal(sum(is.na(out$amount)), 1L)
  expect_equal(out$amount[out$state == "ND"], NA_real_)
})

test_that("CMS's Georgia figure corroborates the DCH Phase 4 total", {
  # An independent closure that fell out of the first live run: CMS announces
  # $93.3M for Georgia on 08-27-2026, and DCH's own Phase 4 announcement the
  # same day totals $93,330,827. Two publishers, one figure. This is still a
  # DISCOVERY source (0.1) -- the corroboration is a check, not a source.
  csv <- here::here("data", "reference", "cms_state_announcements.csv")
  skip_if_not(file.exists(csv), "the trigger list has not been run")
  live <- readr::read_csv(csv, show_col_types = FALSE, progress = FALSE)
  ga <- live[live$state == "GA", ]
  expect_equal(nrow(ga), 1L)
  expect_equal(ga$date, as.Date("2026-08-27"))
  expect_equal(ga$amount, 93300000)
  expect_lt(abs(ga$amount - 93330827), 40000)
})


# ===========================================================================
# The PRIMARY source: the cms.gov newsroom, rural health topic
# ===========================================================================
#
# These exist because medicaid.gov alone was wrong in a way that cost a state.
# CMS announced $122M for Virginia on 2026-08-28 and the resources page did not
# carry it, so a monitor reading only that page reported eight announced states
# when there were nine -- confidently, because nothing in a lagging source
# looks like a gap. What follows pins the two things that fix it: the topic
# filter (which catches the four state announcements whose titles say nothing
# about rural health) and the union (which lets neither source shrink the
# other).

test_that("a newsroom listing parses to date, type, title and url", {
  out <- rhtp_parse_newsroom_listing(fixture("newsroom_listing.html"))

  expect_equal(nrow(out), 3)
  expect_setequal(names(out), c("item_date", "item_type", "title", "url"))
  expect_equal(out$item_date[1], as.Date("2026-08-28"))
  expect_equal(out$item_type, c("Press Releases", "Press Releases", "Fact Sheets"))
  expect_true(all(startsWith(out$url, "/newsroom/")))
})

test_that("an empty listing is refused, not read as a quiet week", {
  # A markup change that yields zero rows must fail loudly. Reading it as
  # "CMS published nothing" is the 5.2 silent short read: the trigger list
  # would go on reporting whatever it last knew, and a new state would not
  # arrive until someone noticed by hand.
  expect_error(
    rhtp_parse_newsroom_listing("<html><body><p>redesigned</p></body></html>"),
    "zero items"
  )
})

test_that("the topic is read from the JSON-LD, as a string and as an array", {
  expect_equal(cms_newsroom_topics(fixture("newsroom_release_rural.html")),
               "Rural health")
  expect_setequal(cms_newsroom_topics(fixture("newsroom_release_rural_multi.html")),
                  c("Administration", "Rural health"))
  expect_setequal(cms_newsroom_topics(fixture("newsroom_release_not_rural.html")),
                  c("Administration", "Payment Rules"))
})

test_that("a release CMS tagged with nothing is not rural, and does not error", {
  # CMS tags some items with no topic at all. That is not a parse failure and
  # must not stop a crawl -- it is simply not an RHTP announcement.
  expect_equal(cms_newsroom_topics(fixture("newsroom_release_no_topic.html")),
               character(0))
  expect_false(cms_newsroom_is_rural(character(0)))
})

test_that("the rural topic matches beside other topics and case-insensitively", {
  expect_true(cms_newsroom_is_rural(c("Administration", "Rural health")))
  expect_true(cms_newsroom_is_rural("rural HEALTH"))
  expect_false(cms_newsroom_is_rural(c("Administration", "Payment Rules")))
})


# -- The state, and the trap in it -------------------------------------------

test_that("West Virginia is West Virginia, not Virginia", {
  # THE test in this file. "...Across West Virginia" contains "Virginia", so a
  # first-match reader files West Virginia's $4.2M under VA. Nothing would look
  # wrong afterwards: both are real states, both have real announcements, and
  # the trigger list would simply have the wrong one. Longest match wins.
  expect_equal(
    cms_newsroom_state(paste(
      "Trump Administration Announces $4.2 Million to Expand Medical",
      "Transportation and Improve Patient Access to Care Across West Virginia"
    )),
    "WV"
  )
  expect_equal(
    cms_newsroom_state(paste(
      "Trump Administration Announces $122 Million to Expand Healthcare",
      "Access, Workforce and Innovation Across Virginia"
    )),
    "VA"
  )
})

test_that("both Dakotas resolve, and to different states", {
  expect_equal(
    cms_newsroom_state("... Coordinating and Connecting Care Initiative in North Dakota"),
    "ND"
  )
  expect_equal(
    cms_newsroom_state("... Modernize and Improve IT and Interoperability for South Dakota"),
    "SD"
  )
})

test_that("a headline naming no state is NA, which is how a national release is found", {
  expect_true(is.na(cms_newsroom_state(
    "CMS Announces $50 Billion in Awards to Strengthen Rural Health in All 50 States"
  )))
  expect_true(is.na(cms_newsroom_state(
    "CMS Announces Establishment of the Office of Rural Health Transformation"
  )))
})

test_that("a headline naming two states is refused, not resolved", {
  # CMS has never done this. If it does, picking one would be a guess about
  # which state an award went to, and the guess would be invisible.
  expect_error(
    cms_newsroom_state("Announces Funding for Rural Health in Georgia and Alabama"),
    "more than one state"
  )
})

test_that("a slug survives a query string and a trailing slash", {
  expect_equal(cms_newsroom_slug("/newsroom/press-releases/some-release"), "some-release")
  expect_equal(cms_newsroom_slug("/newsroom/press-releases/some-release/"), "some-release")
  expect_equal(cms_newsroom_slug("https://www.cms.gov/newsroom/press-releases/some-release?x=1"),
               "some-release")
})


# -- Parsing the index into announcements ------------------------------------

newsroom_index_fixture <- function() {
  tibble::tibble(
    slug = c("va", "wv", "national", "not-rural"),
    url = paste0("https://www.cms.gov/newsroom/press-releases/", c("va", "wv", "national", "nr")),
    item_date = as.Date(c("2026-08-28", "2026-08-20", "2025-12-29", "2026-08-18")),
    item_type = "Press Releases",
    title = c(
      "Trump Administration Announces $122 Million to Expand Healthcare Access, Workforce and Innovation Across Virginia",
      "Trump Administration Announces $4.2 Million to Expand Medical Transportation and Improve Patient Access to Care Across West Virginia",
      "CMS Announces $50 Billion in Awards to Strengthen Rural Health in All 50 States",
      "Medicare Advantage Rate Announcement"
    ),
    topics = c("Rural health", "Administration; Rural health", "Rural health", "Administration"),
    is_rural = c(TRUE, TRUE, TRUE, FALSE),
    first_indexed = "2026-08-28"
  )
}

test_that("the index parses to state announcements, with the amount from the headline", {
  out <- rhtp_parse_cms_newsroom(newsroom_index_fixture())

  expect_equal(attr(out, "cms_press_shape"), "NEWSROOM_TOPIC")
  expect_setequal(out$state, c("VA", "WV"))
  expect_equal(out$amount[out$state == "VA"], 122000000)
  expect_equal(out$amount[out$state == "WV"], 4200000)
  expect_equal(out$date[out$state == "VA"], as.Date("2026-08-28"))
})

test_that("a non-rural item never reaches the trigger list", {
  out <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  expect_false(any(grepl("Medicare Advantage", out$title)))
})

test_that("a rural release naming no state is excluded as Tier 1, not mapped", {
  # The $50bn launch, the all-50-states award, the Office of RHT, the summit
  # readout: all tagged rural health, none a state announcement. They are the
  # CMS->states programme itself (0.2 Tier 1) and this is the STATE trigger
  # list. Exactly the medicaid.gov "All" rows, in the newsroom's shape.
  out <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  expect_equal(nrow(out), 2L)
  expect_false(any(grepl("50 Billion", out$title)))
})

test_that("an index with nothing rural in it is refused", {
  # Zero rural items means the JSON-LD moved or the topic was renamed. CMS has
  # tagged RHTP announcements with it since 2025-09-15, so zero is never "CMS
  # stopped announcing" -- and a monitor that reports that is worse than one
  # that stops.
  idx <- newsroom_index_fixture()
  idx$is_rural <- FALSE
  expect_error(rhtp_parse_cms_newsroom(idx), "No newsroom item carries")
})


# -- The union ---------------------------------------------------------------

test_that("a shared announcement collapses to one row marked BOTH", {
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  medicaid <- newsroom %>%
    dplyr::filter(.data$state == "WV") %>%
    dplyr::mutate(source_url = "https://www.medicaid.gov/x")

  out <- rhtp_cms_press_union(newsroom, medicaid)
  expect_equal(nrow(out), 2L)
  expect_equal(out$source[out$state == "WV"], "BOTH")
  expect_equal(out$source[out$state == "VA"], "CMS_NEWSROOM")
})

test_that("the union is what surfaces a lagging source", {
  # The finding this rewrite exists for. Virginia is on the newsroom and not on
  # medicaid.gov, and `source` is what makes that visible instead of leaving
  # the count silently one short.
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  medicaid <- newsroom[newsroom$state == "WV", ]

  out <- rhtp_cms_press_union(newsroom, medicaid)
  expect_equal(out$state[out$source == "CMS_NEWSROOM"], "VA")
})

test_that("a state only the secondary carries is kept, not dropped", {
  # The symmetric failure. If the newsroom ever lags on something medicaid.gov
  # has, the union must keep it -- which is the whole reason the secondary was
  # kept rather than deleted when it was demoted.
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  medicaid <- newsroom[1, ] %>%
    dplyr::mutate(state = "NE", title = "A Nebraska announcement the newsroom lacks")

  out <- rhtp_cms_press_union(newsroom, medicaid)
  expect_true("NE" %in% out$state)
  expect_equal(out$source[out$state == "NE"], "MEDICAID_GOV")
})

test_that("the primary's URL wins a collision, which fixes medicaid.gov's WV link", {
  # Not a coin toss: the medicaid.gov page publishes West Virginia's link with
  # a doubled slash (/newsroom/press-releases//trump-administration-...).
  # Taking the primary's URL corrects it without a special case.
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  medicaid <- newsroom %>%
    dplyr::filter(.data$state == "WV") %>%
    dplyr::mutate(url = sub("press-releases/", "press-releases//", .data$url, fixed = TRUE))

  out <- rhtp_cms_press_union(newsroom, medicaid)
  expect_false(grepl("//wv", out$url[out$state == "WV"], fixed = TRUE))
})

test_that("the union passes the assertions and its source column is controlled", {
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  out <- rhtp_cms_press_union(newsroom, newsroom[0, ])

  expect_true(rhtp_cms_press_assert(out))
  expect_true(all(out$source %in% c("CMS_NEWSROOM", "MEDICAID_GOV", "BOTH")))
})

test_that("a free-text source value fails the assertions", {
  newsroom <- rhtp_parse_cms_newsroom(newsroom_index_fixture())
  out <- rhtp_cms_press_union(newsroom, newsroom[0, ])
  out$source[1] <- "cms newsroom probably"
  expect_error(rhtp_cms_press_assert(out), "outside the controlled set")
})


# -- The live run, pinned ----------------------------------------------------

test_that("the live newsroom crawl finds twelve states, including Virginia", {
  # Nine through session 40; session 41's live run (2026-09-03) added AR
  # (2026-08-31), HI (2026-09-01) and IN (2026-09-03).
  idx <- here::here("data", "reference", "cms_newsroom_topic_index.csv")
  skip_if_not(file.exists(idx), "the newsroom topic index is not on disk")

  out <- rhtp_parse_cms_newsroom(
    readr::read_csv(idx, show_col_types = FALSE, progress = FALSE) %>%
      dplyr::mutate(item_date = as.Date(.data$item_date))
  )
  expect_setequal(out$state,
                  c("AK", "AL", "AR", "GA", "HI", "IN", "ND", "OH", "PA",
                    "SD", "VA", "WV"))
  expect_equal(out$amount[out$state == "VA"], 122000000)
  expect_equal(out$date[out$state == "VA"], as.Date("2026-08-28"))
})

test_that("the eight titles that say nothing about rural health are still caught", {
  # EIGHT of the twelve state announcements -- AK, AL, HI, IN, ND, SD, VA, WV
  # -- carry no "rural" in their headlines (six of nine before session 41). A
  # title filter, the obvious design and the wrong one, loses two thirds of
  # the trigger list, Virginia included.
  idx <- here::here("data", "reference", "cms_newsroom_topic_index.csv")
  skip_if_not(file.exists(idx), "the newsroom topic index is not on disk")

  out <- rhtp_parse_cms_newsroom(
    readr::read_csv(idx, show_col_types = FALSE, progress = FALSE) %>%
      dplyr::mutate(item_date = as.Date(.data$item_date))
  )
  silent <- out[!grepl("rural", out$title, ignore.case = TRUE), ]
  expect_setequal(silent$state,
                  c("AK", "AL", "HI", "IN", "ND", "SD", "VA", "WV"))
  # Only four of the twelve would survive a title filter.
  expect_equal(nrow(out) - nrow(silent), 4L)
})

test_that("the committed trigger list carries Virginia, and medicaid.gov has caught up", {
  # Session 15 could not size the medicaid.gov lag: Virginia was announced on
  # 2026-08-28 and only the newsroom carried it. By session 41's run on
  # 2026-09-03 the secondary carries it too, so the lag closed within six
  # days; Indiana (announced 2026-09-03) is the one the secondary now lacks.
  csv <- here::here("data", "reference", "cms_state_announcements.csv")
  skip_if_not(file.exists(csv), "the trigger list has not been run")

  live <- readr::read_csv(csv, show_col_types = FALSE, progress = FALSE)
  skip_if_not("source" %in% names(live), "the trigger list predates the union")

  va <- live[live$state == "VA", ]
  expect_equal(nrow(va), 1L)
  expect_equal(va$amount, 122000000)
  expect_equal(va$source, "BOTH")
  expect_equal(dplyr::n_distinct(live$state), 12L)
  expect_equal(live$source[live$state == "IN"], "CMS_NEWSROOM")
})

test_that("every archived rural release verifies against its manifest digest", {
  # writeBin, not writeLines: writeLines appends a newline, so the file on disk
  # would be one byte longer than the body that was hashed and the digest a
  # reader checks would not verify. Session 12 found that in four earlier
  # archives; this pins that these do not repeat it.
  dir <- here::here("data", "raw", "cms", "2026-08-28", "newsroom")
  skip_if_not(dir.exists(dir), "the newsroom archive is not on disk")

  manifest <- readLines(file.path(dir, "MANIFEST.txt"), warn = FALSE)
  lines <- stringr::str_subset(manifest, "^  [0-9a-f]{64}  ")
  expect_gt(length(lines), 0)

  purrr::walk(lines, function(line) {
    parts <- stringr::str_match(line, "^  ([0-9a-f]{64})  (.+)$")
    path <- file.path(dir, parts[3])
    if (file.exists(path)) {
      expect_equal(digest::digest(file = path, algo = "sha256"), parts[2])
    }
  })
})

test_that("the manifest does not list itself, and lists everything else", {
  # A manifest cannot record its own digest: the value is stale the instant the
  # file is written. It DID list itself, and the digest test above passed anyway
  # -- because on a first run the manifest does not exist when the listing is
  # taken, so there was nothing to be wrong. The second --run on one archive
  # date is what exposed it, and the twice-weekly Routine reaches that whenever
  # it runs twice in a day.
  #
  # The completeness half matters as much: `if (file.exists(path))` above means
  # a file that stops being listed is silently not checked, so an unlisted file
  # is indistinguishable from a verified one. This asserts the two sets match.
  dir <- here::here("data", "raw", "cms", "2026-08-28", "newsroom")
  skip_if_not(dir.exists(dir), "the newsroom archive is not on disk")

  manifest <- readLines(file.path(dir, "MANIFEST.txt"), warn = FALSE)
  listed <- stringr::str_match(
    stringr::str_subset(manifest, "^  [0-9a-f]{64}  "), "^  [0-9a-f]{64}  (.+)$"
  )[, 2]

  expect_false("MANIFEST.txt" %in% listed)

  on_disk <- setdiff(
    list.files(dir, recursive = TRUE), "MANIFEST.txt"
  )
  expect_setequal(listed, on_disk)
})


test_that("the index read back off disk unions with medicaid.gov without a type clash", {
  # A real bug, and one only the offline --parse path reached. readr infers
  # first_indexed as a Date on the way back in; medicaid.gov's first_seen is
  # character; bind_rows refuses the pair. A fresh --run never saw it, because
  # it builds the index in memory where the column is already character. The
  # types are pinned at the reader, and this is what holds them there.
  idx <- here::here("data", "reference", "cms_newsroom_topic_index.csv")
  skip_if_not(file.exists(idx), "the newsroom topic index is not on disk")

  newsroom <- rhtp_parse_cms_newsroom(rhtp_newsroom_index())
  expect_type(newsroom$first_seen, "character")

  medicaid <- tibble::tibble(
    state = "NE", date = as.Date("2026-08-01"), amount = 1e6,
    title = "A Nebraska announcement", url = "https://www.medicaid.gov/x",
    source_url = "https://www.medicaid.gov/x", first_seen = "2026-08-01"
  )
  expect_silent(out <- rhtp_cms_press_union(newsroom, medicaid))
  expect_true("NE" %in% out$state)
})


# -- Provenance: what may be committed ---------------------------------------

test_that("a release is reduced to <main> plus the JSON-LD, and the topic survives", {
  # The JSON-LD lives in <head>, so archiving <main> alone would throw away the
  # very field the topic filter reads and leave the archive unre-parseable
  # offline -- which would defeat 0.5. Keeping both is the point.
  page <- paste0(
    '<html><head>',
    '<script>var drupalSettings = {"mapboxToken":"pk.eySYNTHETICfixtureNOTarealTOKEN0123456789.abcdefghijklmnop"};</script>',
    '<script type="application/ld+json">{"@type":"NewsArticle","about":"Rural health"}</script>',
    '</head><body><nav>NAVIGATION-SENTINEL</nav>',
    '<main><h1>Announces $122 Million ... Across Virginia</h1></main>',
    '</body></html>'
  )
  reduced <- cms_newsroom_reduce_release(page)

  expect_true(grepl("Across Virginia", reduced, fixed = TRUE))
  expect_true(cms_newsroom_is_rural(cms_newsroom_topics(reduced)))
  # A distinctive sentinel, not a plausible English word: the archive's own
  # banner explains what CMS page chrome is, so asserting on "chrome" would
  # have matched the banner and passed for the wrong reason.
  expect_false(grepl("NAVIGATION-SENTINEL", reduced, fixed = TRUE))
})

test_that("the third-party token never reaches the archive", {
  # CMS's page chrome carries a Mapbox API token in its Drupal settings JSON.
  # It is CMS's to publish and not ours to redistribute -- the posture 7.1 took
  # for the allotment table and Session 11 for the six state press releases.
  #
  # The fixture token below is SYNTHETIC, and deliberately so: pasting CMS's
  # real one in here to test that we do not redistribute it would have
  # redistributed it. (GitHub's push protection said so first, which is the
  # check working.) The guard matches the token's SHAPE, so a synthetic value
  # of the same form exercises it exactly as the real one would.
  page <- paste0(
    '<html><head>',
    '<script>var drupalSettings = {"mapboxToken":"pk.eySYNTHETICfixtureNOTarealTOKEN0123456789.abcdefghijklmnop"};</script>',
    '</head><body><main><h1>A release</h1></main></body></html>'
  )
  expect_false(grepl("pk.ey", cms_newsroom_reduce_release(page), fixed = TRUE))
})

test_that("a token that migrates INTO <main> is caught by shape, not by value", {
  # The guard matches the token's form, so a rotated token -- or one CMS moves
  # into the article -- fails too. A guard keyed on the literal string we
  # happened to see would pass a rotated one silently.
  page <- paste0(
    '<html><head></head><body><main>',
    '<h1>A release</h1><span data-x="pk.eyROTATEDvalue0123456789abcdefghij">m</span>',
    '</main></body></html>'
  )
  expect_error(cms_newsroom_reduce_release(page), "third-party API token")
})

test_that("a page with no <main> is refused rather than archived whole", {
  expect_error(
    cms_newsroom_reduce_release("<html><body><div>no main here</div></body></html>"),
    "no <main> element"
  )
})

test_that("no committed newsroom archive carries a third-party token", {
  dir <- here::here("data", "raw", "cms", "2026-08-28", "newsroom")
  skip_if_not(dir.exists(dir), "the newsroom archive is not on disk")

  files <- list.files(dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
  expect_gt(length(files), 0)

  offenders <- purrr::keep(files, function(f) {
    any(stringr::str_detect(readLines(f, warn = FALSE),
                            CMS_THIRD_PARTY_TOKEN_PATTERN))
  })
  expect_equal(basename(offenders), character(0))
})

test_that("the archived Virginia release still parses to its topic offline", {
  # The whole reason the JSON-LD is kept: the committed archive must reproduce
  # the filter without a network call (0.5).
  f <- here::here("data", "raw", "cms", "2026-08-28", "newsroom", "releases",
                  paste0("trump-administration-announces-122-million-expand-",
                         "healthcare-access-workforce-innovation-across.html"))
  skip_if_not(file.exists(f), "the Virginia release is not archived")

  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_true(cms_newsroom_is_rural(cms_newsroom_topics(html)))
})

test_that("the index records the full page's digest, so provenance still closes", {
  # The committed bytes are the reduction, so the digest a reader would take of
  # the file is not the digest of what cms.gov served. Both are recorded --
  # Session 11's convention -- and the reduction's is what verifies on disk.
  idx <- here::here("data", "reference", "cms_newsroom_topic_index.csv")
  skip_if_not(file.exists(idx), "the newsroom topic index is not on disk")

  d <- readr::read_csv(idx, show_col_types = FALSE, progress = FALSE)
  rural <- d[d$is_rural, ]

  expect_true(all(!is.na(rural$reduced_sha256)))
  expect_true(all(!is.na(rural$full_page_sha256)))
  expect_true(all(rural$reduced_sha256 != rural$full_page_sha256))
  expect_true(all(nchar(rural$full_page_sha256) == 64))
  # A non-rural item is not archived, so it has no reduction to digest.
  expect_true(all(is.na(d$reduced_sha256[!d$is_rural])))
})

# test_03j_sd_year1_announcements.R ------------------------------------------
# South Dakota's two announced rounds. Reads the committed archives only --
# no network, no quota.
#
# WHAT THIS FILE IS DEFENDING. The finding is a NEGATIVE one: South Dakota has
# announced 110 grants worth $121.5M and named nobody. A negative is the
# easiest kind of finding to get quietly wrong later -- either by someone
# filling the gap with an imputation, or by the state publishing the roster
# while this repo goes on saying it did not. Both failure modes are tested
# here, and the second is tested by feeding the parser a roster and requiring
# it to refuse.

library(testthat)

source(here::here("R", "03j_sd_year1_announcements.R"))

SD_Y1_TEST_DIR <- here::here("data/evidence/SD/announcements")

read_article <- function(kb) {
  paste(readLines(file.path(SD_Y1_TEST_DIR, paste0(kb, ".html")),
                  warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}


test_that("both releases are archived and both still parse", {
  for (kb in SD_Y1_ROUNDS$kb_number) {
    path <- file.path(SD_Y1_TEST_DIR, paste0(kb, ".html"))
    expect_true(file.exists(path), info = kb)
    expect_gt(nchar(rhtp_sd_year1_parse(read_article(kb), kb)), 500)
  }
})


test_that("the manifest's article digest verifies against the bytes on disk", {
  # The session 12 correction: writeLines appends a newline the manifest would
  # then not verify against. These files are written with writeBin, so a reader
  # re-hashing the archive must get the recorded digest back.
  manifest <- readLines(file.path(SD_Y1_TEST_DIR, SD_Y1_MANIFEST), warn = FALSE)

  for (kb in SD_Y1_ROUNDS$kb_number) {
    i <- grep(paste0("kb_number       : ", kb), manifest, fixed = TRUE)
    expect_length(i, 1L)
    block <- manifest[i:min(i + 12L, length(manifest))]
    recorded <- sub(".*article sha256  : ", "",
                    grep("article sha256", block, value = TRUE)[1])

    raw <- readBin(file.path(SD_Y1_TEST_DIR, paste0(kb, ".html")), "raw",
                   n = file.size(file.path(SD_Y1_TEST_DIR,
                                           paste0(kb, ".html"))))
    expect_equal(digest::digest(rawToChar(raw), algo = "sha256",
                                serialize = FALSE),
                 recorded, info = kb)
  }
})


test_that("no session token was committed with the archives", {
  # Only the <article> element is archived precisely so the ServiceNow chrome's
  # per-session CSRF token never lands in the repo.
  for (kb in SD_Y1_ROUNDS$kb_number) {
    expect_false(grepl("g_ck", read_article(kb), fixed = TRUE), info = kb)
  }
})


test_that("neither release names a recipient", {
  # The finding itself. If this ever fails, South Dakota has published the
  # roster and R/03j must be rewritten to extract it -- which is the good case,
  # but it is not a case this file may pass through silently.
  for (kb in SD_Y1_ROUNDS$kb_number) {
    art <- read_article(kb)
    doc <- rvest::read_html(art)
    expect_equal(length(rvest::html_elements(doc, "table")), 0L, info = kb)
    expect_lte(length(rvest::html_elements(doc, "li")), SD_Y1_MAX_LIST_ITEMS)
  }
})


test_that("the roster tripwire fires on a table, a list and a prose run", {
  art <- read_article("KB0046839")

  a_table <- sub("</article>",
                 "<table><tr><td>Sanford Medical Center</td><td>$1,000,000</td></tr></table></article>",
                 art)
  expect_error(rhtp_sd_year1_parse(a_table, "KB0046839"), "table")

  a_list <- sub("</article>",
                paste0("<ul>",
                       paste0(sprintf("<li>Avera Hospital %s - $500,000</li>",
                                      LETTERS[1:20]), collapse = ""),
                       "</ul></article>"),
                art)
  expect_error(rhtp_sd_year1_parse(a_list, "KB0046839"), "list items")

  # A roster written as prose, the shape Alabama's release takes. Real South
  # Dakota provider names, and they must be counted as separate organisations
  # rather than swallowed into one cross-sentence match.
  providers <- c("Avera St. Mary's Hospital", "Sanford Health",
                 "Monument Health Rapid City Hospital", "Brookings Health System",
                 "Horizon Health Care Inc.", "Winner Regional Health",
                 "Redfield Community Memorial Hospital",
                 "Prairie Lakes Healthcare System", "Coteau des Prairies Hospital")
  a_prose <- sub("</article>",
                 paste0("<p>", paste0(providers, " received a grant.",
                                      collapse = " "), "</p></article>"),
                 art)
  expect_error(rhtp_sd_year1_parse(a_prose, "KB0046839"), "organisation-shaped")
})


test_that("the current releases sit well inside every tripwire threshold", {
  # A tripwire tuned so tightly that the unmodified document nearly trips it is
  # a tripwire someone will disable. These are the measured margins.
  for (kb in SD_Y1_ROUNDS$kb_number) {
    doc <- rvest::read_html(read_article(kb))
    text <- stringr::str_squish(rvest::html_text2(doc))
    fragments <- stringr::str_split(text, "[.;:!?]\\s+|\\n+")[[1]]
    orgs <- unlist(stringr::str_extract_all(fragments, SD_Y1_ORG_PATTERN))
    orgs <- orgs[!purrr::map_lgl(orgs, function(o) {
      any(stringr::str_detect(o, stringr::fixed(SD_Y1_ORG_ALLOWED)))
    })]
    expect_lt(length(unique(stringr::str_squish(orgs))), SD_Y1_MAX_ORG_NAMES)
  }
})


test_that("an edited figure fails the parse rather than being published", {
  art <- read_article("KB0046839")
  edited <- sub("28 Rural Strong grants", "31 Rural Strong grants", art,
                fixed = TRUE)
  expect_error(rhtp_sd_year1_parse(edited, "KB0046839"), "no longer states")
})


test_that("the two rounds build, assert and reconcile", {
  records <- rhtp_sd_year1_build()
  expect_equal(nrow(records), 2L)
  expect_silent(rhtp_sd_year1_assert(records))

  expect_equal(sum(records$grant_count), 110L)
  expect_equal(sum(records$round_amount), 121500000)
  expect_true(all(records$state == "SD"))
})


test_that("`amount` is empty and `round_amount` carries the figure", {
  # §6.2, the Georgia rule. The published figure is a ROUND total; putting it in
  # `amount` would make one row read as one organisation's award. Summing
  # `amount` must give nothing, by construction.
  records <- rhtp_sd_year1_build()
  expect_true(all(is.na(records$amount)))
  expect_equal(sum(records$amount, na.rm = TRUE), 0)
  expect_equal(records$amount_basis, rep("NOT_PUBLISHED", 2L))
})


test_that("nothing is imputed: no confirmed recipient, no hospital dollar", {
  records <- rhtp_sd_year1_build()
  expect_true(all(records$recipient_confirmed == "No"))
  expect_true(all(records$recipient_type == "NOT_YET_NAMED"))
  expect_true(all(records$distributed_to_hospital == "Unclear"))
  expect_true(all(records$flag_reason == "RECIPIENT_NAMES_NOT_CAPTURED"))
  expect_true(all(records$determination_confidence == "LOW"))
})


test_that("the assertions reject a row that claims a hospital dollar", {
  # The failure this file exists to prevent, reproduced directly: someone reads
  # "20 health systems" as receipt and flips the coding.
  records <- rhtp_sd_year1_build()
  records$distributed_to_hospital[1] <- "Yes"
  expect_error(rhtp_sd_year1_assert(records), "0.3")

  records <- rhtp_sd_year1_build()
  records$recipient_confirmed[2] <- "Yes"
  expect_error(rhtp_sd_year1_assert(records), "names anyone")

  records <- rhtp_sd_year1_build()
  records$amount[1] <- 31500000
  expect_error(rhtp_sd_year1_assert(records), "must stay empty")
})


test_that("every categorical value is inside §8", {
  records <- rhtp_sd_year1_build()
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "flag_reason")) {
    expect_equal(
      setdiff(stats::na.omit(unique(records[[col]])), rhtp_vocabulary(col)),
      character(0), info = col)
  }
  expect_true(all(records$validation_source_type %in%
                    rhtp_vocabulary("source_doc_type")))
})


test_that("the announced rounds do not exceed South Dakota's CMS award", {
  expect_lt(SD_Y1_TOTAL_ANNOUNCED, SD_Y1_CMS_AWARD)
  recon <- rhtp_sd_year1_reconcile()
  expect_true(all(recon$amount[!is.na(recon$amount)] >= 0))
})


test_that("the announced rounds are kept apart from the administrative contracts", {
  # $121.5M announced-but-unnamed and $5.6M of executed administrative
  # contracts are different documents at different levels of certainty. The
  # basis text on every row has to say so, because the row will be read away
  # from this file.
  records <- rhtp_sd_year1_build()
  expect_true(all(grepl("sd_rht_contracts.csv", records$determination_basis,
                        fixed = TRUE)))
  expect_true(all(grepl("NOTHING IS IMPUTED", records$determination_basis,
                        fixed = TRUE)))
})


test_that("the committed CSV matches a fresh build", {
  expect_true(file.exists(here::here(SD_Y1_CSV)))
  on_disk <- readr::read_csv(here::here(SD_Y1_CSV), show_col_types = FALSE,
                             progress = FALSE)
  fresh <- rhtp_sd_year1_build()
  expect_equal(nrow(on_disk), nrow(fresh))
  expect_equal(names(on_disk), names(fresh))
  expect_equal(on_disk$round_amount, fresh$round_amount)
})

# test_03bi_in_grow_regional_awardees.R -------------------------------------
# Indiana's GROW Regional Grants: 186 named recipient rows, no per-organisation
# amount. Offline: reads the committed page, releases and federal records only.

library(testthat)
suppressMessages(source(here::here("R", "03bi_in_grow_regional_awardees.R")))

d <- ig_parse_page()
rel <- ig_parse_releases()
a <- ig_year1_awardees(d)
committed <- readr::read_csv(IG_CSV, show_col_types = FALSE,
                             col_types = readr::cols(ccn = "c", amount = "d",
                                                     .default = readr::col_guess()))

test_that("the archive is the bytes session 61 hashed", {
  expect_equal(ig_assert_archive(), 9L)
})

test_that("186 rows, 178 distinct names, eight regions, no figure in any cell", {
  expect_equal(nrow(d), 186L)
  expect_equal(length(unique(d$awardee)), 178L)
  expect_equal(as.integer(table(d$region)), unname(IG_REGION_ROWS))
  expect_silent(ig_assert_roster(d))
  expect_false(any(grepl("\\$", d$awardee)))
})

test_that("the parse agrees with session 61's independent DERIVED reading (a check, not a source)", {
  dv <- utils::read.csv(here::here(IG_RECHECK, "DERIVED_grow_regional_recipients.csv"),
                        comment.char = "#", stringsAsFactors = FALSE)
  expect_identical(dv$org, d$awardee)
  expect_identical(as.integer(dv$region), as.integer(d$region))
})

test_that("region figures: page == releases, sum $112.4M; surplus = regional + statewide", {
  expect_equal(rel$release_millions, unname(IG_REGION_MILLIONS))
  expect_equal(sum(rel$release_millions) * 1e6, 112400000)
  s <- ig_parse_surplus()
  expect_equal(unname(s), c(16249593.22, 8724000, 7525593.22))
  expect_equal(s[["regional"]] + s[["statewide"]], s[["total"]])
  expect_silent(ig_assert_releases(rel, d))
  expect_silent(ig_assert_page_sentences())
})

test_that("a dropped row, a moved figure, or a priced cell fails the roster", {
  expect_error(ig_assert_roster(d[-10, ]), "186")
  d2 <- d; d2$round_amount[d2$region == 1] <- 12700000
  expect_error(ig_assert_roster(d2), "region figures moved")
  d3 <- d; d3$awardee[5] <- paste(d3$awardee[5], "$250,000")
  expect_error(ig_assert_roster(d3), "REWRITE")
})

test_that("observations are kept, not corrected: 'Braum' and two West-Centrals", {
  expect_silent(ig_assert_observations(rel))
  expect_equal(rel$governor_as_published[3], "Gov. Mike Braum")
  expect_equal(rel$label[c(3, 5)], c("West-Central", "West-Central"))
  st <- readr::read_csv(IG_STATUS_CSV, show_col_types = FALSE)
  expect_true(any(grepl("Braum", st$note)))
  expect_false("amount" %in% names(st))
})

test_that("§0.2: every release footer is the ALLOTMENT, declared Tier 1, refused as a pool", {
  for (r in 1:8) {
    expect_true(isTRUE(rhtp_assert_footer_text_tier(rel$text[r], "IN", "STATE_ALLOTMENT")))
    expect_error(rhtp_assert_footer_text_tier(rel$text[r], "IN", "SOLICITATION"),
                 "Tier 2 POOL")
  }
  expect_false(any(grepl("206927896|206,927,896", committed$round_amount)))
})

test_that("amount is EMPTY on every row; the region figure is never divided", {
  expect_true(all(is.na(a$amount)))
  expect_true(all(is.na(committed$amount)))
  expect_equal(sort(unique(a$round_amount)) / 1e6, sort(unname(IG_REGION_MILLIONS)))
})

test_that("GEORGIA'S TRAP: summing round_amount down the column is refused", {
  r <- ig_reconcile(a)
  expect_equal(r$total, 112400000)
  expect_gt(r$naive_column_sum, r$total)
  expect_error(ig_assert_round_amount_not_summed(sum(a$round_amount), a),
               "summed down the column")
  expect_silent(ig_assert_round_amount_not_summed(112400000, a))
})

test_that("the partition reports 44 named-hospital ROWS and $0 -- read the row count", {
  p <- rhtp_hospital_dollar_partition(a)
  expect_equal(p$bucket, "NAMED_HOSPITAL")
  expect_equal(p$rows, 44L)
  expect_equal(p$dollars, 0)
  expect_equal(rhtp_hospital_dollar_partition(committed)$rows, 44L)
})

test_that("hospitals the NAME RULE MISSES are typed from exact CMS records", {
  for (nm in c("Franciscan Health Rensselaer", "Indiana University Health, Inc",
               "Indiana University Health Inc", "Ascension St. Vincent Jennings")) {
    r <- a[a$awardee == nm, ]
    expect_true(all(r$recipient_type == "HOSPITAL_OR_SYSTEM"), info = nm)
    expect_true(all(r$basis_type == "ORG_WEBSITE"), info = nm)
    expect_true(all(r$determination_confidence == "MEDIUM"), info = nm)
    expect_false(rhtp_classify_recipient_type(nm, "IN")$recipient_type == "HOSPITAL_OR_SYSTEM",
                 info = nm)
  }
  expect_equal(sum(grepl("^Indiana University Health", a$awardee) &
                     a$distributed_to_hospital == "Yes"), 3L)
  expect_equal(unique(a$ccn[a$awardee == "Franciscan Health Rensselaer"]), "151324")
})

test_that("six hand-read bridges are LOW, subtractable and queued", {
  low <- a[a$distributed_to_hospital == "Yes" & a$determination_confidence == "LOW", ]
  expect_setequal(low$awardee, c("Goshen Health System", "Northwest Health Starke Hospital",
                                 "Union Health Inc.", "St. Elizabeth Dearborn",
                                 "Ascension St. Vincent", "Franciscan Health Foundation"))
  expect_true(all(low$basis_type == "GENERAL_KNOWLEDGE"))
  f <- ig_federal()
  for (nm in low$awardee) expect_equal(nrow(ig_federal_match(nm, f)), 0L, info = nm)
  expect_silent(ig_assert_queued(a))
})

test_that("§0.3a: 'Parkview Huntington' is a YMCA and Cummins is a CMHC -- neither is a hospital", {
  y <- a[a$awardee == "Parkview Huntington Family Young Men's Christian Association", ]
  expect_equal(y$distributed_to_hospital, "No")
  expect_match(y$recipient_url, "huntingtony")
  expect_equal(nrow(ig_federal_match(y$awardee)), 0L)
  cu <- a[a$awardee == "Cummins Behavioral Health Systems, Inc.", ]
  expect_equal(rhtp_classify_recipient_type(cu$awardee, "IN")$recipient_type,
               "HOSPITAL_OR_SYSTEM")
  expect_equal(cu$distributed_to_hospital, "No")
  expect_equal(cu$flag_reason, "RECIPIENT_TYPE_INFERRED")
})

test_that("CMHC corporations holding a psychiatric hospital CCN are typed on the record and queued", {
  cm <- a[a$awardee %in% IG_CMHC_WITH_HOSPITAL_CCN, ]
  expect_equal(nrow(cm), 3L)
  expect_true(all(cm$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_setequal(cm$ccn, c("154050", "154009", "154011"))
  expect_true(all(grepl("IN_GROW_CMHC_HOLDS_HOSPITAL_CCN", cm$recipient_type_source)))
})

test_that("no row is a pass-through: IDOH awards every organisation directly and forbids sub-awards", {
  expect_false(any(grepl("PASS_THROUGH", a$flow_type)))
  t <- ig_page_text()
  expect_true(grepl(IG_PAGE_SENTENCES[["no_subaward"]], t, fixed = TRUE))
  expect_true(all(a$flow_type[a$distributed_to_hospital == "Yes"] == "DIRECT"))
  expect_true(all(a$hospital_attribution[a$distributed_to_hospital == "Yes"] == "NAMED_HOSPITAL"))
})

test_that("the fallback rows are one-directional", {
  fb <- a[!is.na(a$flag_reason), ]
  expect_equal(nrow(fb), 81L)
  expect_true(all(fb$distributed_to_hospital == "No"))
  expect_true(all(fb$recipient_type == "NONPROFIT_CBO"))
})

test_that("the leading 19 columns are the union's, and values are inside §8", {
  expect_equal(names(committed)[1:19],
               c("state", "row_no", "awardee", "amount", "recipient_type",
                 "distributed_to_hospital", "note", "recipient_confirmed",
                 "amount_confirmed", "fiscal_year", "source_document_title",
                 "state_source_url", "validation_source_type", "extraction_method",
                 "validator", "ccn", "aha_id", "rural_designation", "reviewer"))
  expect_true(all(committed$validation_source_type %in% rhtp_vocabulary("source_doc_type")))
  expect_true(all(committed$recipient_type %in% rhtp_vocabulary("recipient_type")))
  expect_true(all(file.exists(here::here(unique(committed$source_archive_path)))))
})

test_that("the committed file is this build", {
  expect_equal(committed$awardee, a$awardee)
  expect_equal(committed$recipient_type, a$recipient_type)
  expect_equal(committed$distributed_to_hospital, a$distributed_to_hospital)
  expect_equal(committed$round_amount, a$round_amount)
})

test_that("the watch fires on a priced cell, a moved roster, and a new dollar sentence", {
  raw <- paste(readLines(here::here(IG_PAGE), warn = FALSE), collapse = "\n")
  arch <- ig_page_text()
  expect_silent(ig_assert_watch(raw, arch, rhtp_watch_reduce(raw)))
  priced <- sub(">Woodlawn Hospital<", ">Woodlawn Hospital $1,250,000<", raw, fixed = TRUE)
  expect_error(ig_assert_watch(priced, arch, rhtp_watch_reduce(priced)),
               "PER-ORGANISATION FIGURE")
  moved <- sub(">Woodlawn Hospital<", ">Woodlawn Health<", raw, fixed = TRUE)
  expect_error(ig_assert_watch(moved, arch, rhtp_watch_reduce(moved)), "moved")
  said <- sub("nearly 200 subrecipients have been selected",
              "nearly 200 subrecipients have been selected. Woodlawn Hospital received $1,250,000.",
              raw, fixed = TRUE)
  expect_error(ig_assert_watch(said, arch, rhtp_watch_reduce(said)), "NEW SENTENCE")
})

test_that("the name tripwire has a real baseline and fires on a new organisation", {
  arch <- ig_page_text()
  expect_silent(rhtp_assert_no_new_organisations(arch, arch, "IN", "grow_regional"))
  live <- paste(arch, "Region 9 Grant Recipient Organizations: Hoosier Valley Regional Hospital.")
  expect_error(rhtp_assert_no_new_organisations(live, arch, "IN", "grow_regional"),
               "NAMES")
})

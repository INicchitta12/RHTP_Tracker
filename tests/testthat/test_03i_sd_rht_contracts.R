# test_03i_sd_rht_contracts.R ------------------------------------------------
# South Dakota's RHTP contracts on the state transparency portal. Reads the
# committed archives and CSV off disk -- no network, no quota.
#
# The point of this file is the NEGATIVE finding, and negative findings rot
# quietly. South Dakota has announced $121.5M to 110 named recipients across two
# rounds, and none of it is on open.sd.gov. What is there is $5.6M of
# administrative contracts. These tests keep those two facts attached to each
# other, so the small number can never be read as South Dakota's Tier 3 total.

library(testthat)

source(here::here("R", "03i_sd_rht_contracts.R"))

records <- rhtp_sd_records()


test_that("every South Dakota assertion passes", {
  expect_true(rhtp_sd_assert(records))
})

test_that("the committed CSV matches a fresh parse of the committed archives", {
  fresh <- rhtp_sd_build()
  expect_equal(nrow(fresh), nrow(records))
  expect_equal(fresh$contract_number, records$contract_number)
  expect_equal(fresh$amount, records$amount)
  expect_equal(fresh$recipient_type, records$recipient_type)
})


# -- What was extracted ------------------------------------------------------

test_that("13 contracts in the RHT series, $5,618,367", {
  expect_equal(nrow(records), 13L)
  expect_equal(sum(records$amount), 5618367)
  expect_true(all(grepl("RHT", records$contract_number)))
})

test_that("no South Dakota dollar reaches a hospital in this extraction", {
  # Every one of the 13 is programme management, consulting, evaluation or
  # workforce training. Not a finding about South Dakota -- a finding about
  # these 13 contracts.
  expect_equal(sum(records$distributed_to_hospital == "Yes"), 0L)
  expect_true(all(records$distributed_to_hospital == "No"))
})


# -- What was NOT extracted, and why -----------------------------------------

test_that("the reconciliation names both unpublished rounds", {
  recon <- rhtp_sd_reconcile(records)
  expect_true(any(grepl("31,500,000|\\$31,500,000", recon$value)))
  expect_true(any(grepl("90,000,000|\\$90,000,000", recon$value)))
  expect_true(any(grepl("82 rural healthcare organizations", recon$value)))
  expect_true(any(grepl("28 projects", recon$value)))
  expect_true(any(grepl("^either round found on open.sd.gov$", recon$measure)))
  expect_equal(recon$value[recon$measure == "either round found on open.sd.gov"],
               "no")
})

test_that("every row says in its own basis that it is not the announced rounds", {
  # Once a row is separated from this file -- pasted into a workbook, joined to
  # four other states -- the sentence in the row is all that stops $5.6M being
  # read as South Dakota's Tier 3 figure.
  expect_true(all(grepl("NOT part of", records$determination_basis)))
  expect_true(all(grepl("\\$31.5M|\\$90M", records$determination_basis)))
})

test_that("the extraction is far below what South Dakota has announced", {
  expect_lt(sum(records$amount), 31500000)
  expect_lt(sum(records$amount), SD_CMS_YEAR1_AWARD)
})

test_that("a total that stops being administrative fails loudly", {
  # If the announced rounds ever post into this series, this file's framing is
  # wrong and must be rewritten rather than quietly reporting a large figure it
  # describes as small.
  inflated <- records
  inflated$amount[1] <- 90000000
  expect_error(rhtp_sd_assert(inflated), "far beyond the administrative spend")
})


# -- The detail-page parser --------------------------------------------------

test_that("the two detail-page shapes both parse, and the glossary never bleeds in", {
  # A CONTRACT page carries Solicitation Type and the "* If an image" footer; a
  # GRANT page carries neither, and ends with the portal's CFDA block. Keying
  # the description on the contract footer ran it into the CFDA GLOSSARY text
  # on grant pages -- boilerplate quoted as the state's own description, and fed
  # to the §10.2 flow rules.
  expect_false(any(grepl("Catalog of Federal Domestic Assistance",
                         records$description)))
  expect_true(all(nzchar(records$description)))

  contracts <- records[!is.na(records$solicitation_type), ]
  grants <- records[is.na(records$solicitation_type), ]
  expect_gt(nrow(contracts), 0L)
  expect_gt(nrow(grants), 0L)
})

test_that("the grant pages carry CFDA 93.798, which is RHTP itself", {
  # Independent corroboration that these rows are Rural Health Transformation
  # and not some other DOH programme that happens to share a number series.
  cfda <- stats::na.omit(records$cfda_number)
  expect_gt(length(cfda), 0L)
  expect_true(all(cfda == "93.798"))
})

test_that("descriptions are the full text, not the search table's truncation", {
  # The search table cuts at ~75 characters and ends in "...". Coding from that
  # would quote a truncation as the state's own words.
  expect_false(any(grepl("\\.\\.\\.$", records$description)))
  expect_gt(max(nchar(records$description)), 75L)
})


# -- Evidence ----------------------------------------------------------------

test_that("the search result and every detail page are archived", {
  expect_true(file.exists(here::here(SD_EVIDENCE_DIR, SD_SEARCH_FILE)))
  expect_true(file.exists(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE)))
  for (n in records$contract_number) {
    expect_true(file.exists(here::here(SD_EVIDENCE_DIR, SD_DETAIL_SUBDIR,
                                       paste0(n, ".html"))), info = n)
  }
})

test_that("the manifest digests verify against the archived bytes", {
  manifest <- readLines(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  recorded <- recorded[nzchar(recorded)]
  # One search result plus one detail page per contract.
  expect_equal(length(recorded), nrow(records) + 1L)

  files <- c(here::here(SD_EVIDENCE_DIR, SD_SEARCH_FILE),
             here::here(SD_EVIDENCE_DIR, SD_DETAIL_SUBDIR,
                        paste0(records$contract_number, ".html")))
  actual <- vapply(files, function(f) {
    digest::digest(readr::read_file(f), algo = "sha256", serialize = FALSE)
  }, character(1))
  expect_setequal(recorded, unname(actual))
})

test_that("the manifest says plainly that this is not the subaward list", {
  manifest <- paste(readLines(here::here(SD_EVIDENCE_DIR, SD_MANIFEST_FILE)),
                    collapse = " ")
  expect_true(grepl("NOT SOUTH DAKOTA'S SUBAWARD LIST", manifest))
  expect_true(grepl("news.sd.gov", manifest))
})


# -- Vocabulary --------------------------------------------------------------

test_that("every categorical column is inside the §8 vocabulary", {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(as.character(stats::na.omit(unique(records[[col]]))),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("the register's own words classify its vendors, not a guess", {
  # Each of the five commercial consultancies was procured through an RFP for
  # services, which is the register's own field saying the state bought
  # services. The settled fallback would have called all five nonprofits.
  vendors <- records[records$recipient_type == "VENDOR_OR_CONTRACTOR", ]
  expect_equal(nrow(vendors), 5L)
  expect_true(all(vendors$classification_rule == "OVERRIDE"))
  expect_false(any(vendors$determination_confidence == "LOW"))
})

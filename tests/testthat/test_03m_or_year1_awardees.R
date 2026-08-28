# test_03m_or_year1_awardees.R -----------------------------------------------
# Oregon. Reads the committed archives under data/evidence/OR/ only -- no
# network, no quota.
#
# The centre of gravity of this file is ONE CORRECTION. The RCJ survey shows 99
# Oregon awards of exactly $100,000 to 99 distinct organisations, which reads as
# a large clean uniform hospital block. It is not: OHA's own bulletin puts those
# 99 under "Rural Health Clinics (RHCs)" and pays them from a separate $10M
# pool, and Oregon's hospital block is a DIFFERENT table in the same document --
# 35 hospitals, tiered by bed count, $34,998,000. Several tests below exist only
# to make that correction survive a re-run by somebody who has not read §0.1.

library(testthat)

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "03m_or_year1_awardees.R"))

or <- or_year1_awardees()


test_that("all five sources are archived and every digest verifies from disk", {
  # Session 12's off-by-one: writeLines() appends a newline, so the archived
  # file was one byte longer than what was hashed and a reader verifying the
  # archive got a mismatch. This re-hashes each file ON DISK.
  manifest <- file.path(OR_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(manifest))
  lines <- readLines(manifest, warn = FALSE)
  entries <- grep("^[0-9a-f]{64}  ", lines, value = TRUE)
  expect_equal(length(entries), nrow(OR_SOURCES))

  for (e in entries) {
    sha  <- sub("^([0-9a-f]{64}).*$", "\\1", e)
    file <- sub("^[0-9a-f]{64}  (.*?)  \\(.*$", "\\1", e)
    path <- file.path(OR_EVIDENCE_DIR, file)
    expect_true(file.exists(path), info = file)
    expect_equal(digest::digest(file = path, algo = "sha256"), sha, info = file)
  }
})

test_that("the manifest does not list itself, and lists exactly what is on disk", {
  # Session 15's defect, which had always been wrong and whose test passed on
  # absence. A manifest cannot record its own digest.
  manifest <- file.path(OR_EVIDENCE_DIR, "MANIFEST.txt")
  lines    <- readLines(manifest, warn = FALSE)
  listed   <- sub("^[0-9a-f]{64}  (.*?)  \\(.*$", "\\1",
                  grep("^[0-9a-f]{64}  ", lines, value = TRUE))

  expect_false("MANIFEST.txt" %in% listed)
  on_disk <- setdiff(list.files(OR_EVIDENCE_DIR), "MANIFEST.txt")
  expect_equal(sort(listed), sort(on_disk))
})

test_that("no archived Oregon source carries a credential", {
  # Four are archived whole; the awards page is a reduction, because it is NOT
  # clean. This is the assertion that keeps both true on every re-run. It
  # matches token SHAPE, so a rotated credential is caught too.
  for (f in setdiff(list.files(OR_EVIDENCE_DIR), "MANIFEST.txt")) {
    path <- file.path(OR_EVIDENCE_DIR, f)
    body <- readBin(path, "raw", file.info(path)$size)
    expect_silent(or_assert_credential_free(body, f))
  }
})

test_that("or_assert_credential_free() actually refuses a credential", {
  # Positive control. A guard nobody has seen fail is a guard nobody knows works.
  planted <- charToRaw('<map-details api-key="pk.eyJ1IjoiZXhhbXBsZSIsImEiOiJjbGV4YW1wbGUifQ">')
  expect_error(or_assert_credential_free(planted, "planted.html"), "mapbox_token")
  expect_error(or_assert_credential_free(charToRaw("AIzaSyA1234567890123456789012345678901"), "x"),
               "google_api_key")
})


# -- THE CORRECTION ----------------------------------------------------------

test_that("the 99 x $100,000 are RURAL HEALTH CLINICS, not hospitals", {
  rhc <- or[or$award_pool == "TRANSFORMATION_RHC", ]

  expect_equal(nrow(rhc), 99L)
  expect_true(all(rhc$amount == 100000))
  expect_equal(dplyr::n_distinct(rhc$awardee), 99L)

  # The whole point: not one of them is a hospital dollar.
  expect_true(all(rhc$recipient_type == "FQHC_OR_RHC"))
  expect_true(all(rhc$distributed_to_hospital == "No"))
  expect_true(all(rhc$hospital_attribution == "NOT_HOSPITAL"))
})

test_that("Oregon's hospital block is 35 hospitals and $34,998,000", {
  h <- or[or$award_pool == "TRANSFORMATION_HOSPITAL", ]

  expect_equal(nrow(h), 35L)
  expect_equal(sum(h$amount), 34998000)
  # OHA's own Grand Total row, which is what makes this a closure rather than
  # an assertion about our own arithmetic.
  expect_equal(sum(h$amount), OR_STATED$hospitals_total)

  expect_equal(sum(h$amount == 963000), 32L)
  expect_equal(sum(h$amount == 1394000), 3L)
  # The bulletin states the RULE as well as the amounts; the two must agree.
  expect_true(all((h$beds <= 50) == (h$amount == 963000)))

  expect_true(all(h$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(h$distributed_to_hospital == "Yes"))
})

test_that("the two Transformation tables are separable and never merged", {
  # A reader who cannot tell which pool a row came from can add $34,998,000 to
  # $9,900,000 and call it Oregon's hospital funding. award_pool is what stops
  # that, so it must be populated and distinct on every row.
  tf <- or[grepl("^TRANSFORMATION_(HOSPITAL|RHC)$", or$award_pool), ]
  expect_equal(nrow(tf), 134L)
  expect_equal(sort(unique(tf$award_pool)),
               c("TRANSFORMATION_HOSPITAL", "TRANSFORMATION_RHC"))
  expect_true(all(nzchar(tf$award_pool)))
})

test_that("the parser drops OHA's Grand Total row rather than reading it as an awardee", {
  # RCJ ingested that row as an awardee at $34,998,000, and the bulletin's own
  # title as an awardee at $963,000. Both are in the same 136 records. Neither
  # may appear here.
  expect_false(any(grepl("(?i)grand total", or$awardee, perl = TRUE)))
  expect_false(any(grepl("(?i)Oregon Health Authority Announces Funding",
                         or$awardee, perl = TRUE)))
  expect_false(any(or$amount == 34998000, na.rm = TRUE))
})

test_that("the Transformation parser refuses a bulletin with no Grand Total", {
  # The row-sum's only independent check. Reproduce its absence and require a
  # refusal rather than a silently unchecked parse.
  src  <- or_archive_path("transformation")
  html <- rawToChar(readBin(src, "raw", file.info(src)$size))
  broken <- sub("Grand Total", "Subtotal so far", html, fixed = TRUE)

  tmp <- withr::local_tempfile(fileext = ".html")
  writeBin(charToRaw(broken), tmp)
  expect_error(or_parse_transformation(tmp), "Grand Total")
})


# -- Catalyst ----------------------------------------------------------------

test_that("Catalyst reconciles against OHA's own Total row", {
  cat_rows <- or[or$award_pool == "CATALYST", ]
  expect_equal(nrow(cat_rows), 103L)
  expect_equal(dplyr::n_distinct(cat_rows$awardee), 85L)
  expect_equal(round(sum(cat_rows$amount), 2), 80114365)

  # 103 projects / 85 organisations / $80.1M is also what the awards page's
  # "At a glance" states, in prose, in a different document. Three independent
  # statements of the same three numbers.
  expect_equal(nrow(cat_rows), OR_STATED$catalyst_projects)
  expect_equal(dplyr::n_distinct(cat_rows$awardee), OR_STATED$catalyst_orgs)
})

test_that("Catalyst refuses if OHA's column names change", {
  # OHA's own header misspells "Organization" as "Ogranization". Matching it
  # exactly is deliberate -- the day it is fixed, the shape has changed.
  expect_error(
    or_parse_catalyst(or_archive_path("awards_page")),
    regexp = "."
  )
})

test_that("a university-typed OHSU row is not counted as a hospital", {
  # OHA types four rows "Hospital or Hospital System, ... University" and every
  # one of them is an OHSU entity. UNIVERSITY_OR_AHC is what §8 has for an
  # academic health centre, and it is the conservative direction: it can only
  # keep dollars OUT of the hospital total.
  ohsu <- or[grepl("Oregon Health & Science University", or$awardee, fixed = TRUE) &
               or$award_pool == "CATALYST", ]
  expect_gt(nrow(ohsu), 0L)
  expect_true(all(ohsu$recipient_type == "UNIVERSITY_OR_AHC"))
  expect_true(all(ohsu$distributed_to_hospital == "No"))
})

test_that("a health district that operates a hospital is a hospital", {
  # The deflation the org-type ordering prevents. Curry Health District is typed
  # "Behavioral Health Clinic, Hospital or Hospital System, Local Government,
  # ...". With Oregon's tokens appended below Alaska's, "Local Government" would
  # fire first and drop an operating rural hospital out of the total entirely.
  curry <- or[grepl("Curry Health District", or$awardee, fixed = TRUE), ]
  expect_equal(nrow(curry), 1L)
  expect_equal(curry$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(curry$distributed_to_hospital, "Yes")
})


# -- Immediate Impact --------------------------------------------------------

test_that("Wave 1 is the 12 projects OHA announced", {
  w1 <- or[or$award_pool == "IMMEDIATE_IMPACT_WAVE1", ]
  expect_equal(dplyr::n_distinct(w1$project), 12L)
  expect_equal(dplyr::n_distinct(w1$project), OR_STATED$iia_wave1_projects)
})

test_that("Wave 2 names 21 of the 33 OHA announced, and the gap is not imputed", {
  # SOUTH DAKOTA'S LESSON IN PARTIAL FORM. A count is not a list, and OHA's page
  # never claims to be one. If the page grows to 33 this fails, which is the
  # point: a negative nobody re-checks decays into a stale assumption.
  w2 <- or[or$award_pool == "IMMEDIATE_IMPACT_WAVE2", ]
  expect_equal(dplyr::n_distinct(w2$project), 21L)
  expect_lt(dplyr::n_distinct(w2$project), OR_STATED$iia_wave2_projects)
  expect_lt(sum(w2$amount, na.rm = TRUE), OR_STATED$iia_wave2_pool)
})

test_that("OHA's own per-recipient splits resolve to the named recipient", {
  # "Wallowa Current Award Estimate Year 1 - $965,661" under a header naming
  # three organisations is the STATE doing the §6.2 split itself. The row must
  # carry Wallowa Valley Center for Wellness, not the three-name list.
  expect_true("Wallowa Valley Center for Wellness" %in% or$awardee)
  expect_true("Klamath Basin Behavioral Health" %in% or$awardee)
  expect_true("Trillium Family Services" %in% or$awardee)

  # Wallowa Valley Center for Wellness appears TWICE in Oregon's file and both
  # rows are correct: it won a Catalyst grant as well as this Wave 2 split. The
  # pools are what separate them, which is the same reason award_pool exists.
  w <- or[or$awardee == "Wallowa Valley Center for Wellness", ]
  expect_equal(nrow(w), 2L)
  expect_equal(sort(w$award_pool), c("CATALYST", "IMMEDIATE_IMPACT_WAVE2"))
  expect_equal(w$amount[w$award_pool == "IMMEDIATE_IMPACT_WAVE2"], 965661)
})

test_that("an unresolved multi-recipient field is never a hospital award", {
  # §6.2 catching a real inflation. Oregon publishes "Northwest Regional ESD,
  # Clatsop Community College, Providence Seaside Hospital, Seaside School
  # District" against ONE figure of $186,000. The name rules see "Hospital";
  # without the override the whole $186,000 lands in the hospital total as a
  # Providence award, which is not what OHA published and not what any of the
  # four received.
  multi <- or[!is.na(or$flag_reason) &
                grepl("MULTI_RECIPIENT_FIELD", or$flag_reason), ]
  expect_gt(nrow(multi), 0L)
  expect_true(all(multi$distributed_to_hospital == "Unclear"))
  expect_true(all(multi$hospital_attribution == "NOT_HOSPITAL"))

  seaside <- multi[grepl("Providence Seaside Hospital", multi$awardee, fixed = TRUE), ]
  expect_equal(nrow(seaside), 1L)
  expect_equal(seaside$amount, 186000)
  expect_equal(seaside$distributed_to_hospital, "Unclear")
})

test_that("a corporate suffix is not a second recipient", {
  # "The Next Door, Inc." is one organisation; the naive comma split says two.
  expect_false(or_is_multi_recipient("The Next Door, Inc."))
  expect_false(or_is_multi_recipient("Bay Clinic LLP"))
  expect_true(or_is_multi_recipient("Alano Club, Comagine Health, Tabor North"))
})

test_that("an ampersand inside an organisation's own name is not a delimiter", {
  # The choice session 6 made once already, followed rather than re-decided.
  expect_false(or_is_multi_recipient("Oregon Health & Science University (OHSU)"))
  expect_false(or_is_multi_recipient("Department of Early Learning & Care (DELC)"))
})

test_that("a published range is not turned into an amount", {
  ranged <- or[!is.na(or$amount_high), ]
  expect_equal(nrow(ranged), 2L)
  expect_true(all(is.na(ranged$amount)))
  expect_true(all(grepl("AMOUNT_RANGE_IN_SOURCE", ranged$flag_reason)))
  expect_equal(sort(ranged$amount_low), c(102000, 403000))
  expect_equal(sort(ranged$amount_high), c(194000, 778000))

  # And therefore no sum over `amount` can include either bound.
  expect_false(any(or$amount %in% c(403000, 778000, 102000, 194000), na.rm = TRUE))
})

test_that("a project OHA published with no amount is kept, not dropped", {
  # "System of Care Transformation Regional Convenings" has an initiative and a
  # full description and no figure. Dropping it loses a project OHA named;
  # refusing on it would have lost the other 20 with it.
  unpriced <- or[!is.na(or$flag_reason) & grepl("AMOUNT_MISSING", or$flag_reason), ]
  expect_equal(nrow(unpriced), 2L)
  expect_true(all(is.na(unpriced$amount)))
  expect_true(any(grepl("System of Care", unpriced$awardee)))
})


# -- the pools that name nobody ----------------------------------------------

test_that("the Tribal and LPHA pools are one aggregate row each with an EMPTY amount", {
  # South Dakota's device. The published figure is a POOL total, so it lives in
  # pool_amount and no sum over `amount` can read it as an award to anyone.
  for (p in c("TRIBAL_INITIATIVE", "TRANSFORMATION_LPHA")) {
    r <- or[or$award_pool == p, ]
    expect_equal(nrow(r), 1L, info = p)
    expect_true(is.na(r$amount), info = p)
    expect_gt(r$pool_amount, 0)
    expect_equal(r$recipient_type, "NOT_YET_NAMED", info = p)
    expect_equal(r$recipient_confirmed, "No", info = p)
    expect_equal(r$distributed_to_hospital, "Unclear", info = p)
    expect_true(grepl("RECIPIENT_NAMES_NOT_CAPTURED", r$flag_reason), info = p)
  }

  expect_equal(or$pool_amount[or$award_pool == "TRIBAL_INITIATIVE"], 21700000)
  expect_equal(or$pool_amount[or$award_pool == "TRANSFORMATION_LPHA"], 5000000)
})

test_that("$26.7M of pool money cannot leak into any per-recipient total", {
  expect_false(any(or$amount %in% c(21700000, 5000000), na.rm = TRUE))
})


# -- reconciliation and the closures -----------------------------------------

test_that("the seven pools land on OHA's own running total", {
  # OHA's 2026-07-07 release: Oregon "has so far awarded about $175.3 million".
  # The seven pools' stated figures come from THREE different documents and
  # nobody arranged them to agree.
  rec <- or_reconcile(or)
  expect_equal(rec$pools_stated_total, 175312365)
  expect_lt(abs(rec$pools_stated_total - 175300000) / 175300000, 0.001)
})

test_that("the RHC pool is short by exactly one clinic", {
  # OHA's 2026-04-10 release states "Oregon currently has 100 certified rural
  # health clinics" against a $10M pool; the bulletin lists 99 at $100,000 and
  # closes "Additional clinics may receive their RHC certificate from CMS and
  # become eligible". Nothing is filled in for the 100th.
  rhc_sum <- sum(or$amount[or$award_pool == "TRANSFORMATION_RHC"])
  expect_equal(OR_STATED$rhc_pool - rhc_sum, 100000)
})

test_that("Oregon's Tier 3 total stays inside its Tier 1 allotment", {
  rec <- or_reconcile(or)
  expect_lt(sum(or$amount, na.rm = TRUE), rec$allotment)
  expect_lt(rec$pools_stated_total, rec$allotment)
  # And the allotment used is the CMS anchor, not a figure typed in here.
  allot <- readr::read_csv(here::here("data", "reference", "cms_fy2026_allotments.csv"),
                           show_col_types = FALSE, progress = FALSE)
  or_allot <- allot[[grep("amount|allotment", names(allot), ignore.case = TRUE)[1]]][
    allot[[grep("^state$|state_code|^state_abbr", names(allot), ignore.case = TRUE)[1]]] == "OR"]
  expect_equal(as.numeric(or_allot), OR_ALLOTMENT)
})

test_that("the named/pooled hospital partition holds and refuses a single total", {
  parts <- rhtp_hospital_dollar_partition(or)
  named <- parts[parts$bucket == "NAMED_HOSPITAL", ]
  expect_equal(named$rows, 49L)
  expect_equal(named$dollars, 50188531)
  # 35 Transformation hospitals + 14 Catalyst hospital rows, and nothing else.
  expect_equal(named$dollars,
               sum(or$amount[or$award_pool == "TRANSFORMATION_HOSPITAL"]) +
                 sum(or$amount[or$award_pool == "CATALYST" &
                                 or$distributed_to_hospital == "Yes"]))
})

test_that("hospital-owned RHCs are recorded, not recoded", {
  # Up to $2.3M that a reader might argue belongs in the hospital total. OHA put
  # it in the RHC table; the affiliation is visible and the dollars are not
  # moved on this pipeline's authority.
  affil <- or[or$hospital_affiliation_signal, ]
  expect_equal(nrow(affil), 23L)
  expect_true(all(affil$award_pool == "TRANSFORMATION_RHC"))
  expect_true(all(affil$distributed_to_hospital == "No"))
  expect_equal(sum(affil$amount), 2300000)
})


# -- coding, vocabulary, provenance ------------------------------------------

test_that("not one Oregon award in the file is executed", {
  # Every pool says so in its own words, and the coding must say so too.
  expect_true(all(or$amount_confirmed == "No"))
  named_rows <- or[or$recipient_confirmed == "Yes", ]
  expect_true(all(named_rows$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(!is.na(or$amount) ==
                    grepl("AMOUNT_PRELIMINARY", dplyr::coalesce(or$flag_reason, ""))))
})

test_that("every categorical value is inside §8", {
  for (col in c("recipient_type", "distributed_to_hospital", "recipient_confirmed",
                "amount_confirmed", "determination_confidence", "flow_type",
                "hospital_attribution")) {
    expect_equal(setdiff(unique(stats::na.omit(or[[col]])), rhtp_vocabulary(col)),
                 character(0), info = col)
  }
  expect_equal(setdiff(unique(stats::na.omit(or$validation_source_type)),
                       rhtp_vocabulary("source_doc_type")), character(0))
  flags <- unique(unlist(strsplit(stats::na.omit(or$flag_reason), ";")))
  expect_equal(setdiff(flags, rhtp_vocabulary("flag_reason")), character(0))
})

test_that("AMOUNT_RANGE_IN_SOURCE was added to the vocabulary, not invented in code", {
  expect_true("AMOUNT_RANGE_IN_SOURCE" %in% rhtp_vocabulary("flag_reason"))
  v <- readr::read_csv(here::here("data", "reference", "vocabularies.csv"),
                       show_col_types = FALSE, progress = FALSE)
  note <- v$notes[v$column_name == "flag_reason" &
                    v$allowed_value == "AMOUNT_RANGE_IN_SOURCE"]
  expect_true(nzchar(note))
  expect_match(note, "(?i)range", perl = TRUE)
})

test_that("every row names a source document and a state source URL (§0.4)", {
  expect_true(all(nzchar(or$state_source_url)))
  expect_true(all(nzchar(or$source_document_title)))
  expect_true(all(grepl("^https://", or$state_source_url)))
  # And every URL is one of the five archived sources.
  expect_equal(setdiff(unique(or$state_source_url), OR_SOURCES$url), character(0))
})

test_that("the file matches Florida's leading 19 columns", {
  expect_equal(names(or)[1:19], OR_LEADING_COLUMNS)
  expect_true(all(or$state == "OR"))
  expect_equal(or$row_no, seq_len(nrow(or)))
})

test_that("the committed CSV is what the parser produces", {
  # The CSV is the source of record; the workbook is a render. If they drift,
  # the render is what people read and the record is what tests check.
  csv <- readr::read_csv(OR_CSV, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(csv), nrow(or))
  expect_equal(names(csv), names(or))
  expect_equal(sum(csv$amount, na.rm = TRUE), sum(or$amount, na.rm = TRUE))
})

test_that("or_assert_extraction() passes on the committed archives", {
  expect_silent(or_assert_extraction(or))
})


test_that("the awards page is archived WITHOUT the Google Maps API key", {
  # THE GUARD FOUND THIS, A HAND GREP DID NOT. oregon.gov loads Google Maps for
  # the Catalyst distribution map and carries the key inside the script URL as
  # "...maps/api/js?...&key=AIza...". A pattern anchored on `api_key=` or
  # `apiKey:` -- which is what was run by hand before the first fetch -- walks
  # straight past that form and reports the page clean.
  path <- or_archive_path("awards_page")
  raw  <- rawToChar(readBin(path, "raw", file.info(path)$size))

  expect_false(grepl("AIza[A-Za-z0-9_-]{30,}", raw))
  expect_false(grepl("maps.googleapis.com", raw, fixed = TRUE))
  expect_false(grepl("<script", raw, fixed = TRUE))

  # And the reduction removed nothing this repo parses: the accordion the two
  # Immediate Impact waves live in is still there.
  expect_true(grepl("Immediate Impact Award Wave 1", raw, fixed = TRUE))
  expect_true(grepl("Immediate Impact Award Wave 2", raw, fixed = TRUE))
  expect_true(grepl("panel-title", raw, fixed = TRUE))
})

test_that("the manifest records the full page digest for the reduced file", {
  # §7.1's posture: a reduction is only acceptable if provenance still closes.
  lines <- readLines(file.path(OR_EVIDENCE_DIR, "MANIFEST.txt"), warn = FALSE)
  expect_true(any(grepl("reduce=STRIP_SCRIPTS", lines, fixed = TRUE)))
  expect_true(any(grepl("full page as served: [0-9a-f]{64}", lines)))
  # Exactly one file is reduced; the other four are the served bytes.
  expect_equal(sum(grepl("reduce=STRIP_SCRIPTS", lines, fixed = TRUE)), 1L)
  expect_equal(sum(grepl("reduce=NONE", lines, fixed = TRUE)), 4L)
})

test_that("the credential guard tolerates a binary container", {
  # An xlsx is a zip and its bytes carry NULs, which rawToChar() refuses. The
  # guard must scan it rather than erroring on it -- a guard that throws on the
  # one binary source is a guard that gets an exception written around it.
  path <- or_archive_path("catalyst_data")
  body <- readBin(path, "raw", file.info(path)$size)
  expect_true(any(body == as.raw(0)))
  expect_silent(or_assert_credential_free(body, "catalyst.xlsx"))
})

test_that("the guard catches a key hidden in a script URL, not just a bare one", {
  # Positive control for the exact form that got past the hand check. The key
  # below is SYNTHETIC and deliberately so: committing Oregon's real one to
  # reproduce the bug would put back the credential the reduction removed, in a
  # file nobody thinks of as an archive. The guard matches on shape, so a fake
  # of the right shape tests it exactly as well.
  planted <- charToRaw(paste0(
    '<script src="https://maps.googleapis.com/maps/api/js?region=US&amp;',
    'key=AIzaSyFAKE0000NOT0A0REAL0KEY0000000000&amp;libraries=marker"></script>'
  ))
  expect_error(or_assert_credential_free(planted, "planted.html"), "google_api_key")
})

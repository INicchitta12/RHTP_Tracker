# test_03l_il_year1_awardees.R -----------------------------------------------
# Illinois Year 1. Reads the committed CSV and archives only -- no network.
#
# WHAT THIS FILE IS DEFENDING. Illinois' one row is the first
# PASS_THROUGH_DESIGNATED award in the project, and it is the one shape that
# can silently inflate the headline number: $50,008,264 coded
# distributed_to_hospital = Yes with NOT ONE HOSPITAL NAMED. Every other
# hospital dollar in this repository sits on a row whose own awardee is a
# named hospital.
#
# So the tests here are mostly about SEPARATION, not about extraction. There
# is one row and its figures come straight from the source; what needs
# defending is that the row can never be mistaken for Florida's.

library(testthat)

source(here::here("R", "03l_il_year1_awardees.R"))

il <- rhtp_il_records()


test_that("Illinois is one executed award action", {
  expect_equal(nrow(il), 1L)
  expect_equal(il$state, "IL")
  expect_equal(il$awardee, "Illinois Critical Access Hospital Network (ICAHN)")
  expect_equal(il$amount, 50008264)
  expect_equal(il$agreement_count, 3L)
  expect_equal(il$agreement_signed_date, "2026-07-31")
  expect_equal(il$period_start, "2026-08-01")
  expect_equal(il$period_end, "2027-06-30")
})


test_that("the award to ICAHN is confirmed, in both senses", {
  # ICAHN's own award IS receipt: agreements executed, amount stated exactly.
  # This is what separates Illinois from South Dakota's announced rounds,
  # where `amount` is deliberately empty.
  expect_equal(il$recipient_confirmed, "Yes")
  expect_equal(il$amount_confirmed, "Yes")
  expect_equal(il$amount_precision, "EXACT")
  expect_equal(il$disbursement_status, "EXECUTED")
  expect_false(is.na(il$amount))
})


test_that("NO HOSPITAL IS NAMED, and the row says so in every column", {
  # THE INVARIANT. If any of these ever becomes populated, Illinois has
  # published a roster and this file is out of date rather than merely
  # incomplete.
  expect_equal(il$hospital_attribution, "POOL_UNNAMED_HOSPITALS")
  expect_true(is.na(il$hospital_recipient_count))
  expect_true(is.na(il$recipient_names_source_url))
  expect_true(is.na(il$ccn))
  expect_true(is.na(il$aha_id))
  expect_false(any(il$hospital_attribution == "NAMED_HOSPITAL"))
})


test_that("§10.2 PASS_THROUGH_DESIGNATED is met on both clauses", {
  expect_equal(il$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_equal(il$distributed_to_hospital, "Yes")
  expect_equal(il$intermediary_name,
               "Illinois Critical Access Hospital Network (ICAHN)")
  expect_true(nzchar(il$intermediary_name))

  # The recipient is NOT a hospital, and that is the point: the money reaches
  # hospitals THROUGH it. A test asserting otherwise is what had to be fixed
  # in test_state_union.R.
  expect_equal(il$recipient_type, "NONPROFIT_CBO")
})


test_that("the flags name the condition precisely", {
  flags <- strsplit(il$flag_reason, ";")[[1]]
  expect_true("RECIPIENT_NAMES_NOT_CAPTURED" %in% flags)
  # The genuinely new one: the intermediary's award is executed but the
  # downstream selection has not run. Distinct from South Dakota, where the
  # awards WERE made and the names were simply never published.
  expect_true("SUBAWARD_PROCESS_NOT_YET_RUN" %in% flags)
  expect_true(all(flags %in% rhtp_vocabulary("flag_reason")))
})


test_that("Illinois' dollars are separable from named-hospital dollars", {
  # The whole reason the file is careful. Run through the shared partition,
  # Illinois must land in its own bucket.
  source(here::here("R", "utils_recipient_classification.R"))
  parts <- rhtp_hospital_dollar_partition(il)
  expect_equal(nrow(parts), 1L)
  expect_equal(parts$bucket, "POOL_UNNAMED_HOSPITALS")
  expect_equal(parts$dollars, 50008264)

  # And no named-hospital figure can be derived from this file at all.
  expect_false("NAMED_HOSPITAL" %in% parts$bucket)
})


test_that("the reconciliation reports zero named-hospital dollars", {
  rec <- rhtp_il_reconcile(il)
  named <- rec$value[rec$item == "Named-hospital dollars in this file"]
  expect_equal(named, 0)

  # And the published share is against the real allotment, not a rounded one.
  expect_equal(rec$value[rec$item == "CMS FY2026 allotment"], 193418216.21)
  expect_lt(sum(il$amount), 193418216.21)
})


test_that("the three-agreement split is labelled DERIVED and is not the row", {
  # §0.3 in miniature. The $14M and $5M lines come from HFS's PLAN, not from
  # the award release, and the arithmetic closing exactly is not a licence to
  # publish them. The row stays one row.
  split <- rhtp_il_agreement_split()
  expect_true(any(split$status == "DERIVED - DO NOT PUBLISH"))
  expect_equal(split$amount[split$initiative == "TOTAL"], 50008264)
  expect_equal(split$status[split$initiative == "TOTAL"], "STATED")

  # The closure itself, checked: the two derived lines equal what the two
  # stated figures leave over.
  derived <- sum(split$amount[split$status == "DERIVED - DO NOT PUBLISH"])
  expect_equal(derived, 50008264 - 31008264)

  # And only ONE of the three initiative amounts is actually stated.
  initiatives <- split[split$initiative != "TOTAL", ]
  expect_equal(sum(initiatives$status == "STATED"), 1L)
})


test_that("the cited evidence archive is on disk and verifies", {
  # §0.4/§0.5: a determination without a captured source is not a
  # determination, and an uncommitted archive is gone.
  path <- here::here(il$source_archive_path)
  expect_true(file.exists(path))

  manifest <- readLines(here::here("data/evidence/IL/MANIFEST.txt"),
                        warn = FALSE)
  files <- grep("^20[0-9-]+_.*\\.(html|pdf)$", manifest, value = TRUE)
  shas  <- trimws(sub("^  sha256\\s*:", "",
                      grep("^  sha256 ", manifest, value = TRUE)))

  expect_equal(length(files), length(shas))
  expect_gt(length(files), 0L)

  for (i in seq_along(files)) {
    f <- here::here("data/evidence/IL", files[i])
    expect_true(file.exists(f), info = files[i])
    expect_equal(digest::digest(file = f, algo = "sha256"), shas[i],
                 info = files[i])
  }

  # The manifest never lists itself, and the listed set is the on-disk set --
  # session 15's defect, which passed on absence.
  expect_false(any(manifest == "MANIFEST.txt"))
  on_disk <- setdiff(list.files(here::here("data/evidence/IL")), "MANIFEST.txt")
  expect_setequal(files, on_disk)
})


test_that("no archived Illinois file carries a third-party credential", {
  # hfs.illinois.gov embeds a Mapbox token in a <map-details api-key>. The
  # fetcher removes that node and asserts the result clean; this re-checks the
  # committed bytes, because the assertion runs at fetch time and the archive
  # is what actually ships.
  for (f in list.files(here::here("data/evidence/IL"), full.names = TRUE)) {
    raw <- readBin(f, "raw", file.info(f)$size)
    # Strip NULs before rawToChar: the archived PDF is binary and contains
    # them. A credential is ASCII, so dropping NULs cannot hide one.
    txt <- rawToChar(raw[raw != as.raw(0)])
    Encoding(txt) <- "latin1"
    expect_false(
      grepl("[ps]k\\.ey[A-Za-z0-9._-]{10,}|AIza[A-Za-z0-9_-]{20,}", txt,
            useBytes = TRUE),
      info = basename(f)
    )
  }
})


test_that("the committed CSV matches the builder", {
  path <- here::here("data/reference/il_year1_awardees.csv")
  expect_true(file.exists(path))
  on_disk <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(on_disk), 1L)
  expect_equal(on_disk$amount, 50008264)
  expect_equal(on_disk$hospital_attribution, "POOL_UNNAMED_HOSPITALS")
  expect_equal(names(on_disk)[1:19], names(il)[1:19])
})


test_that("all assertions pass on the real record", {
  expect_true(rhtp_il_assert(il))
})


test_that("the assertions refuse a pass-through row with no intermediary", {
  # Positive control. The separability check has to be able to fail, or it is
  # decoration.
  broken <- il
  broken$intermediary_name <- NA_character_
  expect_error(rhtp_il_assert(broken))

  named <- il
  named$hospital_attribution <- "NAMED_HOSPITAL"
  expect_error(rhtp_il_assert(named))

  counted <- il
  counted$hospital_recipient_count <- 78L
  expect_error(rhtp_il_assert(counted))
})

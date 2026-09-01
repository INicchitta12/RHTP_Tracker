# test_03g_al_year1_awardees.R -----------------------------------------------
# Alabama Year 1 awardees. Reads the committed archive and CSV off disk -- no
# network, no quota.
#
# Alabama's list is prose, and the two things most likely to go wrong are both
# silent: losing the 14 second-grant continuation paragraphs (which name no
# recipient of their own), and quietly reconstructing the 45 amounts the release
# published rounded. Both are pinned below.

library(testthat)

source(here::here("R", "03g_al_year1_awardees.R"))

records <- rhtp_al_records()
release_html <- readr::read_file(here::here(AL_EVIDENCE_DIR, AL_RELEASE_FILE))


test_that("every Alabama assertion passes", {
  expect_true(rhtp_al_assert(records))
})

test_that("the committed CSV matches a fresh parse of the committed archive", {
  fresh <- rhtp_al_build()
  expect_equal(nrow(fresh), nrow(records))
  expect_equal(fresh$awardee, records$awardee)
  expect_equal(fresh$amount, records$amount)
  expect_equal(fresh$recipient_type, records$recipient_type)
  expect_equal(fresh$distributed_to_hospital, records$distributed_to_hospital)
})


# -- The count both the governor and CMS state -------------------------------

test_that("138 award actions across 95 awardees and 5 initiatives", {
  expect_equal(nrow(records), 138L)
  expect_equal(dplyr::n_distinct(records$awardee), 95L)
  expect_equal(dplyr::n_distinct(records$initiative_raw), 5L)
})


# -- The continuation paragraphs, which are the parse's real hazard ----------

test_that("the 14 second grants are captured and carry a real recipient", {
  # Reading only the <li> elements loses these and $8.1M with them; reading
  # every block as an award invents 14 nameless recipients.
  seconds <- records[records$award_sequence == "SECOND", ]
  expect_equal(nrow(seconds), 14L)
  expect_true(all(nzchar(seconds$awardee)))
  expect_true(all(seconds$amount > 0))
})

test_that("every second grant sits against a first grant for the same recipient", {
  # The check that the carry-forward attached to the RIGHT recipient, not just
  # to some recipient.
  seconds <- dplyr::distinct(
    records[records$award_sequence == "SECOND", c("awardee", "initiative_raw")])
  firsts <- dplyr::distinct(
    records[records$award_sequence == "FIRST", c("awardee", "initiative_raw")])
  expect_equal(nrow(dplyr::anti_join(seconds, firsts,
                                     by = c("awardee", "initiative_raw"))), 0L)
})

test_that("a continuation paragraph with no list item before it refuses", {
  broken <- sub("<ul>", "<p>A second grant of $1,000 will do a thing.</p><ul>",
                release_html, fixed = TRUE)
  expect_error(rhtp_al_parse_awards(broken),
               "Refusing to attribute an award to no one")
})

test_that("losing the closing marker refuses rather than running off the end", {
  # A minimal document, so the guard under test is the one that fires. On the
  # real page the parse runs on into site navigation and refuses one step later
  # instead -- on a nav item with no bolded recipient -- which is the next test.
  minimal <- paste0(
    "<html><body>",
    "<p>Below are the healthcare providers and institutions receiving grants.</p>",
    "<p><strong>Rural Health Initiative</strong></p>",
    "<ul><li><strong>Some Hospital</strong> - $100,000 to do a thing.</li></ul>",
    "</body></html>")
  expect_error(rhtp_al_parse_awards(minimal), "closing '###' marker")
})

test_that("running into site chrome refuses too, on the real page", {
  truncated <- sub("###", "", release_html, fixed = TRUE)
  expect_error(rhtp_al_parse_awards(truncated),
               "Refusing to attribute an award to no one")
})


# -- The rounding, recorded and never reconstructed --------------------------

test_that("45 amounts are flagged as rounded and 93 are exact", {
  expect_equal(sum(records$amount_precision == "ROUNDED_TO_MILLIONS"), 45L)
  expect_equal(sum(records$amount_precision == "EXACT_AS_PUBLISHED"), 93L)
  rounded <- records[records$amount_precision == "ROUNDED_TO_MILLIONS", ]
  expect_true(all(rounded$flag_reason == "AMOUNT_ROUNDED_IN_SOURCE" |
                    !is.na(rounded$flag_reason)))
})

test_that("a rounded amount is stored as the release wrote it", {
  # "$6.38 million" is 6,380,000 -- not reconstructed to a precision nobody
  # published, and not left as 6.38.
  auburn <- records[records$awardee == "Auburn University" &
                      grepl("Cybersecurity", records$initiative_raw), ]
  expect_equal(auburn$amount, 6380000)
  expect_equal(auburn$amount_precision, "ROUNDED_TO_MILLIONS")
})

test_that("the release's own figures sum below its own headline, and that is reported", {
  # $143,745,821 against "more than $144 million". The gap IS the rounding. It
  # is reported, never closed by adjusting a number nobody published.
  expect_equal(sum(records$amount), 143745821)
  expect_lt(sum(records$amount), 144000000)
  recon <- rhtp_al_reconcile(records)
  expect_true(any(grepl("rounding", recon$measure)))
})

test_that("the round stays inside Alabama's CMS Year 1 award (§6.2 ceiling)", {
  expect_lt(sum(records$amount), AL_STATED_YEAR1_AWARD)
})


# -- Evidence ----------------------------------------------------------------

test_that("the archive and its manifest exist and the digest verifies", {
  expect_true(file.exists(here::here(AL_EVIDENCE_DIR, AL_RELEASE_FILE)))
  manifest <- readLines(here::here(AL_EVIDENCE_DIR, AL_MANIFEST_FILE))
  recorded <- regmatches(manifest, regexpr("[0-9a-f]{64}", manifest))
  recorded <- recorded[nzchar(recorded)]
  expect_equal(length(recorded), 1L)
  expect_equal(recorded,
               digest::digest(release_html, algo = "sha256", serialize = FALSE))
})


# -- The vocabulary and the §10.2 coding -------------------------------------

test_that("every categorical column is inside the §8 vocabulary", {
  for (col in c("recipient_type", "distributed_to_hospital", "flow_type",
                "recipient_confirmed", "amount_confirmed", "flag_reason",
                "determination_confidence")) {
    bad <- setdiff(as.character(stats::na.omit(unique(records[[col]]))),
                   rhtp_vocabulary(col))
    expect_equal(bad, character(0), info = col)
  }
})

test_that("no initiative heading was captured as a recipient (§6.1)", {
  expect_false(any(grepl("Initiative$", records$awardee)))
})

test_that("only hospital recipients are coded distributed_to_hospital = Yes", {
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_true(all(yes$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                            "HOSPITAL_AFFILIATED_ENTITY")))
})

test_that("60 hospital award actions hold $66,133,019", {
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 60L)
  expect_equal(sum(yes$amount), 66133019)
})

test_that("Cahaba's obstetric training row is IN_KIND_BENEFIT, not a pass-through", {
  # SESSION 31 MOVED THIS ROW, AND IT IS THE MARKER FIX, NOT AN ALABAMA FIX.
  # The release says the $430,304 grant "will establish rural obstetric
  # training capacity AT FOUR ALABAMA HOSPITALS". Cahaba -- a federally
  # qualified health center -- keeps the money and delivers the training; no
  # dollar passes through it to a hospital. The old
  # RHTP_PASS_THROUGH_MARKERS matched the positional phrase "at four ...
  # hospitals" and coded it PASS_THROUGH_UNRESOLVED + Unclear, which is
  # \u00a710.2's IN_KIND_BENEFIT described as its opposite: it put the row in the
  # bucket a later session revisits TO PROMOTE TO `Yes`, and asserted in its
  # own determination_basis that "funds reach hospitals it does not name" --
  # which the source does not say.
  #
  # Alabama now has NO Unclear row at all, and no hospital dollar moved:
  # Unclear and No are both outside every bucket of
  # rhtp_hospital_dollar_partition().
  expect_equal(nrow(records[records$distributed_to_hospital == "Unclear", ]), 0L)

  cahaba <- records[records$awardee == "Cahaba Medical Care Foundation" &
                      records$amount == 430304, ]
  expect_equal(nrow(cahaba), 1L)
  expect_equal(cahaba$flow_type, "IN_KIND_BENEFIT")
  expect_equal(cahaba$distributed_to_hospital, "No")
  # \u00a710.2's own definition of the code: No, but the hospitals are visible.
  expect_equal(cahaba$hospital_benefiting, "Yes")
  expect_true(is.na(cahaba$flag_reason) ||
                !grepl("ELIGIBILITY_NOT_RECEIPT", cahaba$flag_reason))
  # And the row's stated reason now matches the row's coding (\u00a77).
  expect_true(grepl("IN_KIND_BENEFIT", cahaba$determination_basis, fixed = TRUE))
  expect_false(grepl("funds reach hospitals it does not name",
                     cahaba$determination_basis, fixed = TRUE))
})

test_that("the hospital total is untouched by that move", {
  # The whole point: the marker change is worth $0. 60 rows, $66,133,019,
  # before and after -- the figures the block above already asserts.
  yes <- records[records$distributed_to_hospital == "Yes", ]
  expect_equal(nrow(yes), 60L)
  expect_equal(sum(yes$amount), 66133019)
})

test_that("the truncated recipient name is kept as the release published it", {
  # The release's own markup reads "<strong> Clair Community Health Clinic
  # Inc.</strong>" -- the "St." is absent from the SOURCE. §8 says keep the
  # state's own language; silently correcting it would make the row untraceable
  # back to the document.
  expect_true(any(startsWith(records$awardee, "Clair Community Health Clinic")))
  expect_false(any(startsWith(records$awardee, "St. Clair Community Health")))
})

test_that("determination_basis is populated on every row (§7)", {
  expect_true(all(nzchar(records$determination_basis)))
})

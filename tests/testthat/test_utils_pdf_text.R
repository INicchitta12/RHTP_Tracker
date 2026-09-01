# test_utils_pdf_text.R -------------------------------------------------------
# The PDF reader. Reads committed archives only -- no network, no quota.
#
# WHY THIS FILE EXISTS AT ALL, THREE SESSIONS AFTER THE READER DID. Session 20
# wrote it for Kansas and tested it only through Kansas's awardee CSV. That is
# a real test of the Kansas parse and no test at all of the reader: session 21
# extended it for Maryland -- compressed object streams, form XObjects, a line
# model keyed on the text position rather than the positioning operator, and an
# ASCII fallback for codes a /ToUnicode CMap omits -- and every one of those
# changes could have moved a committed figure. Two of them did move the
# INTERMEDIATE lines that Kansas's parser sees; none moved its output, and that
# distinction is what this file pins.
#
# THE FAILURE SHAPE THIS PROJECT CARES ABOUT MOST IS THE EMPTY ANSWER. A reader
# that returns character(0) on a document it cannot open does not look broken;
# it looks like a state that published nothing. Both directions are asserted.

library(testthat)

source(here::here("R", "utils_pdf_text.R"))

KS_REH  <- here::here("data/evidence/KS/2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf")
KS_CHW  <- here::here("data/evidence/KS/2026-08-29_kdhe_chw_afim_project_descriptions.pdf")
MD_TF   <- here::here("data/evidence/MD/2026-08-29_mdh_pillar2_transformation_fund_bp1_award_offers.pdf")
GA_NOA  <- here::here("data/evidence/recheck/2026-08-29/GA/GA_noa_workforce_retention_technology_signed.pdf")


test_that("no committed award PDF parses to nothing", {
  for (p in c(KS_REH, KS_CHW, MD_TF, GA_NOA)) {
    skip_if_not(file.exists(p))
    expect_gt(length(rhtp_pdf_text(p)), 20L, label = basename(p))
  }
})

test_that("rhtp_pdf_lines returns geometry and rhtp_pdf_text its text", {
  skip_if_not(file.exists(MD_TF))
  d <- rhtp_pdf_lines(MD_TF)
  expect_named(d, c("page", "x", "y", "text"))
  expect_gt(max(d$page), 1L)
  expect_equal(rhtp_pdf_text(MD_TF), d$text)
  # Four columns at four stable x positions is the whole reason x is returned.
  expect_gte(length(unique(round(d$x, 1))), 4L)
})

test_that("object streams are expanded, and a top-level object wins", {
  skip_if_not(file.exists(MD_TF))
  bytes <- readBin(MD_TF, "raw", file.info(MD_TF)$size)
  top  <- rhtp_pdf_objects(bytes)
  full <- rhtp_pdf_objstm_expand(top)
  expect_gt(length(full), length(top))
  expect_true(all(names(top) %in% names(full)))
  for (nm in names(top)) expect_identical(full[[nm]], top[[nm]])
})

test_that("expansion is idempotent", {
  # KDHE's files carry an object stream too -- 97 top-level objects become 385
  # -- which is worth knowing: the expansion was not written for Maryland
  # alone, and running it twice must not double anything.
  skip_if_not(file.exists(KS_REH))
  bytes <- readBin(KS_REH, "raw", file.info(KS_REH)$size)
  once  <- rhtp_pdf_objstm_expand(rhtp_pdf_objects(bytes))
  twice <- rhtp_pdf_objstm_expand(once)
  expect_identical(twice, once)
})

test_that("expansion leaves an object map with no object streams alone", {
  # The degenerate case, built here rather than hunted for: a map with nothing
  # to expand comes back unchanged.
  fake <- list("1" = charToRaw("<</Type/Page>>"),
               "2" = charToRaw("<</Type/Font>>"))
  expect_identical(rhtp_pdf_objstm_expand(fake), fake)
})

test_that("a line is a text position, not a positioning operator", {
  skip_if_not(file.exists(MD_TF))
  tx <- rhtp_pdf_text(MD_TF)
  # Maryland's producer emits a Td per glyph. Under the old model this file
  # came out one character per line.
  expect_true(any(grepl("Maryland Rural Health Transformation Program", tx,
                        fixed = TRUE)))
  expect_lt(mean(nchar(tx) <= 2), 0.05)
})

test_that("an unmapped single-byte code falls back to ASCII rather than vanishing", {
  skip_if_not(file.exists(GA_NOA))
  tx <- rhtp_pdf_text(GA_NOA)
  # DCH's font CMap omits H, q, v, y, b, z, k, C and m among others. Dropping
  # them silently turned "Crisp Regional Hospital" into "Crisp Regional
  # ospital" -- readable, plausible, and wrong in a recipient name.
  expect_true(any(grepl("Crisp Regional Hospital", tx, fixed = TRUE)))
  expect_true(any(grepl("Colquitt Regional Medical", tx, fixed = TRUE)))
  expect_false(any(grepl("ospital", tx, fixed = TRUE) &
                   !grepl("Hospital", tx, fixed = TRUE)))
})

test_that("the fallback does NOT apply to a two-byte font", {
  # For an Identity-H font the code is a glyph id in a subsetted font and has
  # no relation to any character, so an unmapped code must stay empty rather
  # than become confident nonsense.
  cmap <- c("65" = "A")
  expect_equal(rhtp_pdf_decode(c(0L, 65L, 0L, 66L), cmap, two_byte = TRUE), "A")
  expect_equal(rhtp_pdf_decode(c(65L, 66L), cmap, two_byte = FALSE), "AB")
  expect_equal(rhtp_pdf_decode(c(72L), character(), two_byte = FALSE), "H")
})

test_that("Kansas's own figures are unchanged by all of the above", {
  skip_if_not(file.exists(KS_REH))
  # The claim that matters is not the intermediate line count -- that DID
  # change, because KDHE wraps mid-word and the reader now joins the visual
  # line. It is that Kansas's committed awardee file still says what it said.
  ks <- readr::read_csv(here::here("data/reference/ks_year1_awardees.csv"),
                        show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(ks), 46L)
  expect_equal(sum(ks$amount), 80020499)
  expect_true(any(grepl("Citizens Foundation", ks$awardee)))
  expect_false(any(grepl("Foundat ion", ks$awardee)))
})


# -- the run model (session 32) ------------------------------------------------
#
# A LINE IS ITS RUNS PASTED BACK TOGETHER. That is the invariant the whole
# change rests on: rhtp_pdf_lines() kept its output character for character
# across all nine PDF-reading states because it is now composed from the runs
# rather than accumulated separately, so the two views cannot drift apart.

test_that("composing a document's runs reproduces its lines exactly", {
  for (p in c(KS_REH, KS_CHW, MD_TF, GA_NOA)) {
    skip_if_not(file.exists(p))
    runs <- rhtp_pdf_run_table(p)
    expect_equal(rhtp_pdf_compose_lines(runs), rhtp_pdf_lines(p),
                 label = basename(p))
  }
})

test_that("every line's runs share its page and start at its x and y", {
  skip_if_not(file.exists(MD_TF))
  runs <- rhtp_pdf_run_table(MD_TF)
  key  <- cumsum(c(TRUE, runs$page[-1] != runs$page[-nrow(runs)] |
                         runs$line[-1] != runs$line[-nrow(runs)]))
  # One line never spans two pages, and its runs were all painted at one y.
  expect_true(all(vapply(split(runs$page, key),
                         function(v) length(unique(v)) == 1L, logical(1))))
  expect_true(all(vapply(split(runs$y, key),
                         function(v) length(unique(v)) == 1L, logical(1))))
  # A line takes the position of its first run -- which is what the reader
  # recorded before runs existed.
  first <- !duplicated(key)
  lines <- rhtp_pdf_lines(MD_TF)
  keep  <- nzchar(trimws(vapply(split(runs$text, key), paste, character(1),
                                collapse = "")))
  expect_equal(runs$x[first][keep], lines$x)
})

test_that("a run is finer than a line, and its x is its own", {
  skip_if_not(file.exists(MD_TF))
  runs  <- rhtp_pdf_runs(MD_TF)
  lines <- rhtp_pdf_lines(MD_TF)
  expect_named(runs, c("page", "line", "x", "y", "text"))
  # More runs than lines is the point: a line that merged two cells is two runs.
  expect_gt(nrow(runs), nrow(lines))
})

test_that("runs are returned AS PAINTED, because a run boundary lands on a space", {
  skip_if_not(file.exists(MD_TF))
  runs <- rhtp_pdf_runs(MD_TF)
  # THE POSITIVE CONTROL FOR THE NO-TRIM CONTRACT. If these documents had no
  # run ending in a space, trimming would be harmless and the contract would be
  # untestable; they do, and trim-then-paste welds the two words together.
  ends_in_space <- grepl("[ ]$", runs$text)
  expect_true(any(ends_in_space))
  i <- which(ends_in_space)[1]
  expect_false(identical(paste0(trimws(runs$text[i]), "x"),
                         paste0(runs$text[i], "x")))
})

# test_flow_table_parity.R ---------------------------------------------------
# The §10.2 flow determination rules are restated in three files, and all three
# must say the same thing. Offline, no quota.
#
# WHY THIS FILE EXISTS. §2.1 records two occasions on which a stale local copy
# overwrote a committed correction to one of these documents, and both times the
# §10.2 flow rules were what was lost. A divergence between the three is
# invisible in a diff of any one of them -- the file that was overwritten looks
# fine on its own. This file compares them.
#
# The hospital-association block below is the one added in session 18. It is
# written once and pasted into all three, so parity here is byte parity, not a
# judgement about whether two paraphrases agree.

library(testthat)

DOCS <- c(
  spec     = "rhtp-tracker-build-spec.md",
  claude   = "CLAUDE.md",
  reviewer = "reviewer-coding-instructions.md"
)

read_doc <- function(key) {
  readLines(here::here(DOCS[[key]]), warn = FALSE)
}

# The block runs from its own heading to whatever ends the section: the next
# heading at any level, or a horizontal rule (CLAUDE.md separates its numbered
# sections with one, and sweeping it in would make the three copies differ by a
# character none of them wrote).
extract_block <- function(lines, heading_text) {
  starts <- grep(paste0("^#{2,4} ", heading_text, "$"), lines)
  if (length(starts) != 1L) return(NULL)
  rest <- lines[(starts + 1L):length(lines)]
  ends <- grep("^(#{1,6} |---\\s*$)", rest)
  body <- if (length(ends)) rest[seq_len(ends[[1]] - 1L)] else rest
  trimws(paste(trimws(body[nzchar(trimws(body))]), collapse = "\n"))
}

HEADING <- "Hospital trade associations and hospital-governed entities"

# THE SECOND BLOCK, ADDED IN SESSION 38 ON THE SAME FOOTING. New York's RCHI
# requires a hospital in every awarded partnership without requiring it to be
# the recipient, which is a third answer to the question ICAHN and FHC answer
# two different ways. It is written once and pasted into all three documents,
# so parity here is byte parity for it too.
ELIGIBLE_CLASS_HEADING <-
  "The eligible class of a pass-through, and when a hospital is required"

test_that("all three documents carry the hospital-association block", {
  for (key in names(DOCS)) {
    block <- extract_block(read_doc(key), HEADING)
    expect_false(is.null(block),
                 info = paste(DOCS[[key]], "is missing the §10.2 hospital-association block"))
    expect_true(nzchar(block), info = DOCS[[key]])
  }
})

test_that("the three copies of the block are byte-identical", {
  blocks <- vapply(names(DOCS), function(k) extract_block(read_doc(k), HEADING),
                   character(1))
  expect_identical(blocks[["claude"]], blocks[["spec"]])
  expect_identical(blocks[["reviewer"]], blocks[["spec"]])
})

test_that("the block states the flow test, both carve-outs, and intermediary_name", {
  block <- extract_block(read_doc("spec"), HEADING)

  # The condition. Without it the row codes on organisation type alone, which
  # is the §0.3a error in a new place.
  expect_match(block, "administered to or on behalf of member hospitals", fixed = TRUE)
  expect_match(block, "intermediary_name", fixed = TRUE)

  # Carve-out 1 -- the association's own costs.
  expect_match(block, "operating, advocacy, or\nmembership costs", fixed = TRUE)
  expect_match(block, "what the document says the money does", fixed = TRUE)

  # Carve-out 2 -- goods and services bought with retained funds. This is the
  # one that keeps GA and AK out of the hospital total.
  expect_match(block, "IN_KIND_BENEFIT", fixed = TRUE)
  expect_match(block, "Georgia Hospital Association", fixed = TRUE)
  expect_match(block, "Alaska Hospital &", fixed = TRUE)

  # Both positive worked examples, with the figures their sources support.
  expect_match(block, "Illinois Critical Access Hospital Network", fixed = TRUE)
  expect_match(block, "$50,008,264", fixed = TRUE)
  expect_match(block, "Oklahoma\nHospital Association", fixed = TRUE)
  expect_match(block, "$4,300,000", fixed = TRUE)
})

test_that("the flow table in the spec and in CLAUDE.md carries the new row", {
  for (key in c("spec", "claude")) {
    lines <- read_doc(key)
    row <- grep("^\\| `PASS_THROUGH_DESIGNATED` . hospital trade associations", lines)
    expect_length(row, 1L)
    expect_match(lines[[row]], "intermediary_name", fixed = TRUE)
    # It must sit inside the flow table, i.e. after the NON_HOSPITAL row.
    expect_gt(row, grep("^\\| `NON_HOSPITAL` \\|", lines)[[1]])
  }
})

test_that("the two quoted worked examples still match their committed sources", {
  # The quotes are evidence (§0.4), so they are checked against the files they
  # were read out of rather than trusted because they are in a spec.
  il <- readr::read_csv(here::here("data/reference/il_year1_awardees.csv"),
                        show_col_types = FALSE, progress = FALSE)
  expect_match(il$note[[1]],
               "will administer the funds to Critical Access Hospitals",
               fixed = TRUE)
  expect_equal(il$amount[[1]], 50008264)

  ok_path <- here::here("OK_initiative_table.xlsx")
  skip_if_not(file.exists(ok_path), "OK_initiative_table.xlsx not present")
  ok <- openxlsx::read.xlsx(ok_path, sheet = "Fund uses (28)")
  chw <- ok[grepl("^CHW Expansion", ok$fund_use), ]
  expect_equal(nrow(chw), 1L)
  expect_equal(chw$amount_bp1[[1]], 4300000)
  expect_match(chw$evidence_from_document[[1]],
               "conducted by hospitals reimbursed for CHW hiring", fixed = TRUE)
  expect_equal(chw$flow_type[[1]], "PASS_THROUGH_DESIGNATED")
  expect_equal(chw$has_hospital_recipient[[1]], "Yes")
})


# -- §10.2, the eligible class (session 38) ----------------------------------

test_that("all three documents carry the eligible-class block", {
  for (key in names(DOCS)) {
    block <- extract_block(read_doc(key), ELIGIBLE_CLASS_HEADING)
    expect_false(is.null(block),
                 info = paste(DOCS[[key]],
                              "is missing the §10.2 eligible-class block"))
    expect_true(nzchar(block), info = DOCS[[key]])
  }
})

test_that("the three copies of the eligible-class block are byte-identical", {
  blocks <- vapply(names(DOCS),
                   function(k) extract_block(read_doc(k), ELIGIBLE_CLASS_HEADING),
                   character(1))
  expect_identical(blocks[["claude"]], blocks[["spec"]])
  expect_identical(blocks[["reviewer"]], blocks[["spec"]])
})

test_that("the block carries all three worked cases and keeps them distinct", {
  block <- extract_block(read_doc("spec"), ELIGIBLE_CLASS_HEADING)

  # The two answers that already existed, with the sentence each rests on.
  expect_match(block, "hospitals only", fixed = TRUE)
  expect_match(block, "hospitals **among others**", fixed = TRUE)
  expect_match(block, "ICAHN", fixed = TRUE)
  expect_match(block, "FHC", fixed = TRUE)

  # The third, quoted from New York's own guidance.
  expect_match(block, "hospital must be included", fixed = TRUE)
  expect_match(block, "need not be the recipient", fixed = TRUE)

  # AND WHY IT IS NEITHER -- the half that is easiest to lose. It is not
  # ICAHN's Yes because the recipient need not be a hospital; it is not
  # Unclear for FHC's reason because a hospital IS knowably present. What is
  # unknown is narrower: whether a dollar reaches it.
  expect_match(block, "It is not ICAHN's `Yes`", fixed = TRUE)
  expect_match(block, "not `Unclear` for FHC's reason", fixed = TRUE)
  expect_match(block, "participation is not
receipt", fixed = TRUE)

  # The resolution is per-award, and all three codings are named.
  expect_match(block, "read
off the AWARD, one award at a time", fixed = TRUE)
  expect_match(block, "PASS_THROUGH_DESIGNATED", fixed = TRUE)
  expect_match(block, "PASS_THROUGH_UNRESOLVED", fixed = TRUE)
  expect_match(block, "POOL_NAMED_HOSPITALS", fixed = TRUE)
  expect_match(block, "intermediary_name", fixed = TRUE)

  # The figure at stake, so the block states its own cost.
  expect_match(block, "$76,190,022", fixed = TRUE)
})


# -- §10.2, hospital foundations (session 49) ---------------------------------
#
# THE THIRD BLOCK WRITTEN ONCE AND PASTED INTO ALL THREE. It is the row that
# moves dollars, so its parity matters more than the two above it: reading a
# hospital ASSOCIATION's foundation as a hospital's foundation would move
# $66,547,394 of New Hampshire pass-through money into the hospital total, and
# a copy of this block that had lost the word "named" would say exactly that.
FOUNDATION_HEADING <- "Hospital foundations and affiliated arms"

test_that("all three documents carry the hospital-foundation block", {
  for (key in names(DOCS)) {
    block <- extract_block(read_doc(key), FOUNDATION_HEADING)
    expect_false(is.null(block),
                 info = paste(DOCS[[key]], "is missing the §10.2 hospital-foundation block"))
    expect_true(nzchar(block), info = DOCS[[key]])
  }
})

test_that("the three copies of the hospital-foundation block are byte-identical", {
  blocks <- vapply(names(DOCS), function(k) extract_block(read_doc(k), FOUNDATION_HEADING),
                   character(1))
  expect_identical(blocks[["claude"]], blocks[["spec"]])
  expect_identical(blocks[["reviewer"]], blocks[["spec"]])
})

test_that("the block keeps the word that limits it, and both refusals", {
  block <- extract_block(read_doc("spec"), FOUNDATION_HEADING)
  # The limit. Without it the row reaches an association's foundation.
  expect_match(block, "*named*", fixed = TRUE)
  expect_match(block, "does not reach the foundation of an ASSOCIATION", fixed = TRUE)
  expect_match(block, "Foundation for Healthy Communities", fixed = TRUE)
  expect_match(block, "$66,547,394", fixed = TRUE)
  # The second refusal: a parent that is not a hospital.
  expect_match(block, "The test is the PARENT", fixed = TRUE)
  expect_match(block, "Talbot", fixed = TRUE)
  # And the refusal to promote where the parent is not stated.
  expect_match(block, "NOT promoted (§0.4)", fixed = TRUE)
  expect_match(block, "$146,476", fixed = TRUE)
})

test_that("the flow table in the spec and in CLAUDE.md carries the foundation row", {
  for (key in c("spec", "claude")) {
    lines <- read_doc(key)
    row <- grep("^\\| `DIRECT` . a hospital's own foundation or affiliated arm", lines)
    expect_length(row, 1L)
    # It must sit inside the flow table, after the association row.
    assoc <- grep("^\\| `PASS_THROUGH_DESIGNATED` . hospital trade associations", lines)
    expect_gt(row, assoc[[1]])
  }
})

# SESSION 64. The spec's own Tier 3 and PASS_THROUGH_DESIGNATED examples were
# Georgia's Dual Track Remote Critical Care round -- a State Office of Rural
# Health grant series paid from state appropriations, not RHTP. Neither the
# §0.2 tier table nor the §10.2 flow table may cite it as an example again, and
# the RFGA that disqualifies it must still say what it says.
test_that("no document cites Georgia's Dual Track as an RHTP worked example", {
  for (key in c("spec", "claude")) {
    lines <- read_doc(key)
    tier3 <- grep("^\\| 3 \\| `SUBAWARD`", lines, value = TRUE)
    expect_length(tier3, 1L)
    expect_false(grepl("Dual Track", tier3), info = DOCS[[key]])
    pt <- grep("^\\| `PASS_THROUGH_DESIGNATED` \\| Intermediary", lines, value = TRUE)
    expect_false(any(grepl("e\\.g\\. Georgia's Dual Track", pt)), info = DOCS[[key]])
  }
  rfga <- here::here("data/evidence/rcj_dispositions/2026-09-24/GA",
                     "dch_dual_track_rccs26_rfga_2026-05-12.pdf")
  skip_if_not(file.exists(rfga))
  source(here::here("R/utils_pdf_text.R"))
  txt <- paste(rhtp_pdf_text(rfga), collapse = "\n")
  expect_match(txt, "subject to the availability of appropriated", fixed = TRUE)
  expect_match(txt, "State Office of Rural Health", fixed = TRUE)
  for (p in c("Rural Health Transformation", "RHTP", "Centers for Medicare"))
    expect_false(grepl(p, txt, fixed = TRUE), info = p)
})

# THE THIRD BLOCK, ADDED IN SESSION 71 ON THE SAME FOOTING: academic health
# centres and other enrolled hospital operators (UAMS, CCN 040016). Written once
# and pasted into all three documents, so parity is byte parity.
AHC_HEADING <- "Academic health centers and enrolled hospital operators"

test_that("all three documents carry the enrolled-hospital-operator block, byte-identical", {
  blocks <- vapply(names(DOCS), function(k) {
    b <- extract_block(read_doc(k), AHC_HEADING)
    if (is.null(b)) NA_character_ else b
  }, character(1))
  expect_false(anyNA(blocks))
  expect_identical(blocks[["claude"]], blocks[["spec"]])
  expect_identical(blocks[["reviewer"]], blocks[["spec"]])
  expect_match(blocks[["spec"]], "primary federal source", fixed = TRUE)
  expect_match(blocks[["spec"]], "ACADEMIC_HEALTH_CENTER", fixed = TRUE)
  expect_match(blocks[["spec"]], "never matched by machine", fixed = TRUE)
  expect_match(blocks[["spec"]], "ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM", fixed = TRUE)
  expect_match(blocks[["spec"]], "that form\nstands", fixed = TRUE)
})

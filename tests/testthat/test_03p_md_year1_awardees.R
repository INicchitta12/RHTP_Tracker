# test_03p_md_year1_awardees.R ------------------------------------------------
# Maryland Year 1. Reads committed archives only -- no network, no quota.
#
# WHAT THIS FILE IS DEFENDING.
#
#   1. THE PARSE MUST NEVER COME BACK EMPTY AND BE BELIEVED. Maryland's award
#      PDFs put their pages inside a compressed object stream and their drawing
#      inside form XObjects. The reader this project had before session 21
#      returned CHARACTER(0) on them -- not an error, an EMPTY ANSWER, which a
#      caller would read as "the state published nothing". It is the single
#      most dangerous failure shape in this repository, so it is asserted
#      against directly.
#
#   2. THE COLUMN GEOMETRY. Both tables are read by x position, and two
#      adjacent wrapped recipients (Chester River / Choptank) are the case that
#      breaks a simpler rule. If either loses its name or gains the other's,
#      that is a silent mis-attribution of money to a named hospital.
#
#   3. THE TEXAS CHECK AND THE POSITIVE CONTROL. Maryland's award offers are
#      RHTP because MDH says its subawardees are bound by its CMS cooperative
#      agreement, and because both solicitations were posted after the
#      2025-12-29 Notice of Award. The eight opportunities with no roster are a
#      real absence only because MDH demonstrably publishes one where it has
#      awarded.
#
#   4. THE §0.1 ARITHMETIC. RCJ's 42nd Maryland candidate is the MHCC POOL, not
#      a subaward. Treating it as one would add $6.3M of Tier 2 money to a
#      Tier 3 total, which is §0.2 in a single row.

library(testthat)

source(here::here("R", "03p_md_year1_awardees.R"))

md_offers <- md_award_offers()
md_recs   <- md_records()


# -- the empty-parse failure -------------------------------------------------

test_that("both Maryland award PDFs produce text at all", {
  for (key in c("transformation", "primary_care")) {
    lines <- rhtp_pdf_lines(md_path(key))
    expect_gt(nrow(lines), 40L)
    expect_true(all(c("page", "x", "y", "text") %in% names(lines)))
  }
})

test_that("the reader sees the pages inside the compressed object stream", {
  # Without rhtp_pdf_objstm_expand() there is no /Type/Page anywhere in these
  # files and the page walk returns nothing.
  path  <- md_path("transformation")
  bytes <- readBin(path, "raw", file.info(path)$size)
  top   <- rhtp_pdf_objects(bytes)
  full  <- rhtp_pdf_objstm_expand(top)
  expect_gt(length(full), length(top))

  is_page <- function(objs) {
    sum(vapply(objs, function(b) {
      s <- grepRaw("stream", b, all = FALSE)
      e <- if (length(s)) s - 1L else length(b)
      if (e < 1L) return(FALSE)
      grepl("/Type\\s*/Page[^s]", rhtp_pdf_chr(b[seq_len(e)]),
            perl = TRUE, useBytes = TRUE)
    }, logical(1)))
  }
  expect_equal(is_page(top), 0L)
  expect_gt(is_page(full), 0L)
})


# -- the two pools -----------------------------------------------------------

test_that("the Transformation Fund table is 33 offers and $72,412,038", {
  tf <- md_offers[md_offers$award_pool == "PILLAR2_TRANSFORMATION_FUND", ]
  expect_equal(nrow(tf), 33L)
  expect_equal(sum(tf$amount), 72412038)
  expect_true(all(nzchar(tf$awardee)))
})

test_that("the Primary Care table is 8 offers and $6,213,033", {
  pc <- md_offers[md_offers$award_pool == "PILLAR2_EXPAND_PRIMARY_CARE", ]
  expect_equal(nrow(pc), 8L)
  expect_equal(sum(pc$amount), 6213033)
  # MHCC sets the recipient and the amount on one visual line, so the amount
  # must not survive in the name.
  expect_false(any(grepl("\\$", pc$awardee)))
})

test_that("each pool fits inside the figure MDH prints for it", {
  tf <- sum(md_offers$amount[md_offers$award_pool == "PILLAR2_TRANSFORMATION_FUND"])
  pc <- sum(md_offers$amount[md_offers$award_pool == "PILLAR2_EXPAND_PRIMARY_CARE"])
  expect_lte(tf, MD_STATED$transformation_pool)
  expect_lte(pc, MD_STATED$primary_care_pool)
  expect_lte(tf + pc, MD_STATED$bp1_subawards)
  expect_lte(tf + pc, MD_STATED$cms_allotment)
})


# -- the geometry that a simpler rule gets wrong -----------------------------

test_that("Chester River and Choptank are two recipients, not one and a gap", {
  tf <- md_offers[md_offers$award_pool == "PILLAR2_TRANSFORMATION_FUND", ]
  chester  <- tf[grepl("^Chester River", tf$awardee), ]
  choptank <- tf[grepl("^Choptank", tf$awardee), ]
  expect_equal(nrow(chester), 1L)
  expect_equal(nrow(choptank), 1L)
  expect_equal(chester$awardee, "Chester River Health System Inc (UM Shore Regional)")
  expect_equal(choptank$awardee, "Choptank Community Health System Inc")
  expect_equal(chester$amount, 4913250)
  expect_equal(choptank$amount, 1976042)
})

test_that("no award offer is nameless and no name carries a stray amount", {
  expect_false(anyNA(md_offers$awardee))
  expect_true(all(nzchar(trimws(md_offers$awardee))))
  expect_false(anyNA(md_offers$amount))
  expect_true(all(md_offers$amount > 0))
})


# -- the Texas check and the positive control --------------------------------

test_that("MDH itself ties these subawards to its CMS cooperative agreement", {
  expect_true(md_assert_rhtp_funded())
})

test_that("both solicitations were posted AFTER the CMS Notice of Award", {
  dates <- md_assert_after_noa()
  expect_length(dates, 2L)
  expect_true(all(dates > as.Date("2025-12-29")))
})

test_that("the award index is a tripwire in both directions", {
  tbl <- md_assert_award_index()
  expect_gte(nrow(tbl), 8L)
  linked <- tbl$award_offer_href[!is.na(tbl$award_offer_href)]
  expect_equal(sort(basename(linked)), sort(unname(MD_AWARD_LINK_FILES)))
  # And the opportunities MDH has NOT awarded carry no roster link, which is
  # what makes their absence a finding rather than a failure to look.
  expect_gt(sum(is.na(tbl$award_offer_href)), 0L)
})


# -- §8 and §0.1 -------------------------------------------------------------

test_that("every categorical value is inside §8", {
  expect_silent(invisible(md_recs))
  expect_true(all(md_recs$recipient_type %in% rhtp_vocabulary("recipient_type")))
  expect_true(all(md_recs$flow_type %in% rhtp_vocabulary("flow_type")))
  expect_true(all(md_recs$distributed_to_hospital %in%
                    rhtp_vocabulary("distributed_to_hospital")))
  expect_true(all(md_recs$validation_source_type %in%
                    rhtp_vocabulary("source_doc_type")))
  expect_true(all(stats::na.omit(md_recs$flag_reason) %in%
                    rhtp_vocabulary("flag_reason")))
})

test_that("every row is an OFFER, not an executed award", {
  expect_true(all(md_recs$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(md_recs$amount_confirmed == "No"))
  expect_true(all(md_recs$recipient_confirmed == "Yes"))
})

test_that("a county health department is local public health, however spelled", {
  # Maryland is the state that exposed this: "Allegany County Health Department"
  # fell to §8's NONPROFIT_CBO fallback and "Charles County Department of
  # Health" came out STATE_AGENCY. They are the same kind of body.
  hd <- md_recs[grepl("(?i)County (Health Department|Department of Health)",
                      md_recs$awardee, perl = TRUE), ]
  expect_equal(nrow(hd), 8L)
  expect_true(all(hd$recipient_type == "LOCAL_GOVT_OR_PUBLIC_HEALTH"))
})

test_that("RCJ's 42nd Maryland candidate is the POOL, and the arithmetic closes", {
  skip_if_not(file.exists(here::here("data", "interim", "stage2_record_table.rds")))
  expect_true(md_assert_rcj_reconciles(md_recs, quiet = TRUE))
})

test_that("the hospital dollars are partitioned, never totalled", {
  part <- rhtp_hospital_dollar_partition(md_recs)
  expect_true(all(part$bucket %in% c("NAMED_HOSPITAL", "POOL_UNNAMED_HOSPITALS")))
  expect_equal(md_bucket(part, "NAMED_HOSPITAL"), 14678864)
  # Maryland names no pass-through pool, so the other bucket is genuinely zero.
  expect_equal(md_bucket(part, "POOL_UNNAMED_HOSPITALS"), 0)
})

test_that("the committed CSV matches what the parser produces today", {
  csv <- readr::read_csv(here::here(MD_CSV), show_col_types = FALSE,
                         progress = FALSE)
  expect_equal(nrow(csv), nrow(md_recs))
  expect_equal(sum(csv$amount), sum(md_recs$amount))
  expect_equal(csv$awardee, md_recs$awardee)
})


# -- The open classification question (session 22) ---------------------------
#
# MDH publishes no organisation-type column, so 24 of 41 recipient_types are
# derived from the recipient's own name. Kansas's device: the uncertainty goes
# in a queue a human reads, and its presence there is asserted every run.

test_that("the 24 unstated-form rows are queued, with their dollars", {
  queue <- readr::read_csv(
    here::here("data/reference/classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- queue %>% dplyr::filter(question_id == MD_FORM_NOT_STATED_QUESTION)
  expect_equal(nrow(row), 1L)
  expect_equal(row$state, "MD")
  expect_equal(row$queue_status, "OPEN")
  expect_true(grepl("36,558,089", row$dollar_effect))
  expect_true(grepl("14,678,864", row$dollar_effect))
  # Every option a reviewer may choose has to be a real §8 value.
  opts <- stringr::str_squish(strsplit(row$options, "\\|")[[1]])
  opts <- stringr::str_remove(opts, " \\(the current coding\\)$")
  expect_true(all(opts %in% rhtp_vocabulary("recipient_type")))
})

test_that("nothing was promoted and nothing was demoted", {
  recs <- md_records()
  inferred <- recs %>%
    dplyr::filter(determination_confidence == "LOW",
                  flag_reason == "RECIPIENT_TYPE_INFERRED")
  expect_equal(nrow(inferred), 24L)
  expect_equal(sum(inferred$amount), 36558089)
  expect_true(all(inferred$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(inferred$distributed_to_hospital != "Yes"))

  # UNDERSTATED: §0.3a names TidalHealth as a hospital and it is in the 24,
  # uncounted. Meritus Health Center sits beside it. Neither was promoted --
  # doing so on this pipeline's own knowledge is the §0.4 failure.
  for (nm in c("TidalHealth", "Meritus Health Center")) {
    hit <- inferred[grepl(nm, inferred$awardee, fixed = TRUE), ]
    expect_equal(nrow(hit), 1L, info = nm)
  }

  # OVERSTATED, WHICH KANSAS DID NOT HAVE: two of the six rows inside today's
  # hospital figure are typed HOSPITAL_OR_SYSTEM from their names and read as
  # FQHCs. Neither was demoted either. The uncertainty runs BOTH ways.
  named <- recs %>% dplyr::filter(distributed_to_hospital == "Yes")
  expect_equal(nrow(named), 6L)
  expect_equal(sum(named$amount), 14678864)
  fqhc_shaped <- named %>%
    dplyr::filter(grepl("Choptank|Mountain Laurel", awardee))
  expect_equal(nrow(fqhc_shaped), 2L)
  expect_true(all(fqhc_shaped$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_equal(sum(fqhc_shaped$amount), 3034792)
})

test_that("the uncertainty is larger than the figure it sits beside", {
  # If this ever stops being true, the sentence this repository publishes about
  # Maryland has to change, and md_assert_form_not_stated_queued() says so.
  expect_gt(MD_STATED$form_not_stated_total, MD_STATED$named_hospital_floor)
  expect_true(md_assert_form_not_stated_queued(md_records()))
})

test_that("every Maryland row is still an OFFER", {
  recs <- md_records()
  expect_true(all(recs$validation_source_type == "NOTICE_OF_INTENT_TO_AWARD"))
  expect_true(all(recs$amount_confirmed == "No"))
})

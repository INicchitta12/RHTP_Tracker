# test_03r_ne_year1_awardees.R ------------------------------------------------
# Nebraska Year 1. Reads committed archives only -- no network, no quota.
#
# WHAT THIS FILE IS DEFENDING.
#
#   1. §0.3 IN BOTH DIRECTIONS, ON ONE DOCUMENT. Initiative 4.4a's notice
#      carries an AWARD table on page 1 and a roster of ~115 organisations that
#      SUBMITTED APPLICATIONS on pages 2-3. RCJ took the amounts from the first
#      and the document TITLE from the second. Both misreadings are available
#      here and both are wrong: treating the applicant roster as recipients
#      would invent ~115 awards, and believing RCJ's title would discard 24
#      real ones. The award count must stay 24 and the applicant section must
#      stay present -- it is the evidence for the §0.1 finding.
#
#   2. THE POSITIVE CONTROL. "Nebraska has published no other roster" means
#      nothing unless DHHS demonstrably publishes rosters in a recognisable
#      form. It does: an "Awardees" link on its RFA timeline table, three of
#      them, pointing at the three PDFs this file parses. The control fails in
#      both directions -- a vanished link and a fourth link are both failures.
#
#   3. THE TEXAS CHECK, WITH A NEGATIVE CONTROL THIS TIME. DHHS's Office of
#      Procurement and Grants publishes Intent to Award notices for many grant
#      series. RFA 4533 (NHAP Legal Services) is archived precisely because it
#      is NOT RHTP -- "awarding state funds", closed 2025-05-21, seven months
#      before the CMS Notice of Award. It is what disposes of RCJ's Nebraska
#      Lawyers Foundation row, so it is tested as carefully as the positives.
#
#   4. THE $18.2M THAT MUST NOT BE COUNTED TWICE. The Nebraska High Value
#      Network is one award to a collaborative network, and DHHS names the 21
#      individual hospitals receiving funding through it without publishing a
#      per-hospital split. The 21 are carried as rows with an EMPTY amount. If
#      one ever gains an amount, Nebraska's total inflates by up to $18.2M.
#
#   5. THE NEBRASKA HOSPITAL ASSOCIATION'S ABSENCE. It is a CMS-abstract
#      CANDIDATE_ONLY and is on none of the notices, so §10.2's association
#      branch never fires. That absence is asserted, not assumed.

library(testthat)

source(here::here("R", "03r_ne_year1_awardees.R"))

ne_award_rows <- ne_awards()
ne_recs       <- ne_records()
ne_roster_tbl <- ne_nhvn_roster()


# -- the archive --------------------------------------------------------------

test_that("all six Nebraska sources are archived and verify against the manifest", {
  for (key in NE_SOURCES$key) {
    expect_true(file.exists(ne_path(key)), info = key)
  }
  manifest <- file.path(NE_EVIDENCE_DIR, "MANIFEST.txt")
  expect_true(file.exists(manifest))
  lines <- readLines(manifest, warn = FALSE)
  digest_lines <- grep("^[0-9a-f]{64}  ", lines, value = TRUE)
  expect_equal(length(digest_lines), nrow(NE_SOURCES))

  for (line in digest_lines) {
    sha  <- sub("^([0-9a-f]{64}).*$", "\\1", line)
    file <- sub("^[0-9a-f]{64}  (.+?)  \\(.*$", "\\1", line)
    path <- file.path(NE_EVIDENCE_DIR, file)
    expect_true(file.exists(path), info = file)
    # writeBin(), so re-hashing the file on disk must reproduce the digest.
    expect_equal(digest::digest(file = path, algo = "sha256"), sha, info = file)
  }
})

test_that("the manifest does not list itself and lists everything on disk", {
  # Session 15: a manifest cannot record its own digest, and a file that
  # silently stops being listed is indistinguishable from one that verified.
  manifest <- file.path(NE_EVIDENCE_DIR, "MANIFEST.txt")
  lines <- readLines(manifest, warn = FALSE)
  listed <- sub("^[0-9a-f]{64}  (.+?)  \\(.*$", "\\1",
                grep("^[0-9a-f]{64}  ", lines, value = TRUE))
  expect_false("MANIFEST.txt" %in% listed)
  on_disk <- setdiff(list.files(NE_EVIDENCE_DIR), "MANIFEST.txt")
  expect_setequal(listed, on_disk)
})


# -- the positive control -----------------------------------------------------

test_that("the programme page links exactly three notices of award", {
  expect_true(ne_assert_award_index())

  doc <- ne_program_doc()
  hrefs <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  noa <- unique(hrefs[stringr::str_detect(
    hrefs, stringr::fixed("RHTP-Public-Notice-of-Award"))])
  expect_equal(length(noa), 3L)
  for (f in NE_AWARD_LINK_FILES) {
    expect_true(any(stringr::str_detect(noa, stringr::fixed(f))), info = f)
  }
})

test_that("the control fails if a known award link disappears", {
  # Positive control on the control. A site redesign that renamed the links
  # would otherwise turn every future run silently green.
  html <- readLines(ne_path("program_page"), warn = FALSE)
  stripped <- gsub("RHTP-Public-Notice-of-Award-4.4b.pdf", "gone.pdf", html,
                   fixed = TRUE)
  tmp <- withr::local_tempfile(fileext = ".html")
  writeLines(stripped, tmp)
  expect_error(ne_assert_award_index(tmp), "no longer links")
})

test_that("the control fails if a FOURTH award link appears", {
  # The other direction: a fourth link means Nebraska published a pool this
  # file does not carry, which must never pass silently.
  html <- readLines(ne_path("program_page"), warn = FALSE)
  injected <- c(html,
                "<a href=\"/Documents/RHTP-Public-Notice-of-Award-2.5.pdf\">Awardees</a>")
  tmp <- withr::local_tempfile(fileext = ".html")
  writeLines(injected, tmp)
  expect_error(ne_assert_award_index(tmp), "does not carry")
})


# -- §6.2: the Texas check, and its negative control --------------------------

test_that("all three notices carry the CMS financial-assistance footer", {
  expect_true(ne_assert_rhtp_funded())
  for (key in c("noa_3_3", "noa_4_4a", "noa_4_4b")) {
    txt <- stringr::str_squish(paste(ne_pdf_text(key), collapse = " "))
    expect_true(stringr::str_detect(
      txt, stringr::fixed("financial assistance award totaling $218,529,075.01")),
      info = key)
    expect_true(stringr::str_detect(txt, "100 percent funded by CMS"), info = key)
  }
})

test_that("DHHS's stated award agrees with the §7.1 CMS anchor", {
  allotments <- rhtp_load_allotments()
  expect_equal(allotments$fy2026_allotment[allotments$state == "NE"],
               NE_STATED$cms_allotment)
})

test_that("every RFA behind these awards closed AFTER the 2025-12-29 NOA", {
  expect_true(ne_assert_after_noa())
  expect_true(all(NE_RFA_CLOSE_DATES > NE_STATED$noa_date))
  # Six rounds across three notices; the community-college round is worded
  # differently from the other five and must still be found.
  expect_equal(length(NE_RFA_CLOSE_DATES), 6L)
  expect_true(as.Date("2026-07-10") %in% NE_RFA_CLOSE_DATES)
})

test_that("RFA 4533 is the §6.2 negative control: state funds, and pre-NOA", {
  expect_true(ne_assert_non_rhtp_control())
  txt <- stringr::str_squish(paste(ne_pdf_text("rfa_4533"), collapse = " "))
  expect_true(stringr::str_detect(txt, stringr::fixed("awarding state funds")))
  expect_false(stringr::str_detect(txt, "(?i)rural health transformation"))
  expect_lt(NE_NON_RHTP_CLOSE_DATE, NE_STATED$noa_date)
})


# -- the parse ----------------------------------------------------------------

test_that("the three notices parse to 57 awards and $36,137,614.90", {
  expect_equal(nrow(ne_award_rows), 57L)
  expect_equal(round(sum(ne_award_rows$amount), 2), 36137614.90)
  by_pool <- table(ne_award_rows$source_key)
  expect_equal(as.integer(by_pool[["noa_3_3"]]), 9L)
  expect_equal(as.integer(by_pool[["noa_4_4a"]]), 24L)
  expect_equal(as.integer(by_pool[["noa_4_4b"]]), 24L)
  expect_true(ne_assert_pools(ne_award_rows))
})

test_that("no award row is empty, zero, or unnamed", {
  expect_false(anyNA(ne_award_rows$awardee))
  expect_true(all(nzchar(ne_award_rows$awardee)))
  expect_true(all(ne_award_rows$amount > 0))
})

test_that("the published total stays under the CMS allotment (§6.2 ceiling)", {
  expect_lt(sum(ne_award_rows$amount), NE_STATED$cms_allotment)
})


# -- §0.3: the applicant roster is not an award list --------------------------

test_that("Initiative 4.4a's applicant roster is present and is NOT extracted", {
  applicants <- ne_applicant_roster()
  # It is ~115 names. It must stay present: it is the evidence for the §0.1
  # finding about RCJ's title, and it is what a careless reader would extract.
  expect_gt(length(applicants), 100L)

  awarded <- ne_award_rows$awardee[ne_award_rows$source_key == "noa_4_4a"]
  expect_equal(length(awarded), 24L)

  # Names that appear ONLY in the applicant section must reach no 4.4a AWARD
  # row. The check is scoped to 4.4a deliberately: an organisation that applied
  # to 4.4a and was not awarded there may perfectly well appear elsewhere in
  # the file under a different initiative, and seventeen do -- they are members
  # of the Nebraska High Value Network on the 4.4b notice. Those are two
  # unrelated true facts about the same organisation, and a check that treated
  # the second as contamination would be wrong about Nebraska rather than
  # careful about it.
  applicant_only <- setdiff(rhtp_ne_norm(applicants), rhtp_ne_norm(awarded))
  expect_gt(length(applicant_only), 70L)
  awarded_4_4a <- ne_recs$awardee[
    ne_recs$award_pool ==
      "Initiative 4.4a Chronic Disease Navigation and Education"]
  expect_equal(length(awarded_4_4a), 24L)
  expect_equal(
    length(intersect(applicant_only, rhtp_ne_norm(awarded_4_4a))), 0L)

  # And the overlap is recorded rather than waved at. Every row it touches is
  # from a DIFFERENT initiative -- a 4.4b direct award, or an un-priced NHVN
  # member row -- and never from 4.4a, which is the only pool the applicant
  # roster belongs to. An organisation that applied to 4.4a and lost may hold a
  # 4.4b award; both facts are true and neither contaminates the other.
  also_elsewhere <- intersect(applicant_only, rhtp_ne_norm(ne_recs$awardee))
  expect_gt(length(also_elsewhere), 0L)
  overlap_rows <- ne_recs[rhtp_ne_norm(ne_recs$awardee) %in% also_elsewhere, ]
  expect_false(any(overlap_rows$award_pool ==
                     "Initiative 4.4a Chronic Disease Navigation and Education"))
  expect_true(all(is.na(overlap_rows$amount) |
                    grepl("4\\.4b", overlap_rows$award_pool)))
})

test_that("well-known applicants who were NOT awarded stay out of the file", {
  # Three that a reader would plausibly expect to see, and must not: they are
  # on the applicant roster and on no award table.
  for (nm in c("Bryan Health", "Nebraska Medicine", "Cherry County Hospital")) {
    expect_false(nm %in% ne_award_rows$awardee, info = nm)
  }
  # Cherry County Hospital IS in the file -- but only as an NHVN member row
  # with no amount, which is a different claim entirely.
  cherry <- ne_recs[ne_recs$awardee == "Cherry County Hospital", ]
  expect_equal(nrow(cherry), 1L)
  expect_true(is.na(cherry$amount))
  expect_equal(cherry$nhvn_member_of, NE_NHVN_NAME)
})


# -- the Nebraska High Value Network ------------------------------------------

test_that("NHVN is one award of $18,156,856.12 naming 21 hospitals", {
  expect_true(ne_assert_nhvn(ne_award_rows, ne_roster_tbl))
  expect_equal(nrow(ne_roster_tbl), 21L)
  expect_false(anyNA(ne_roster_tbl$awardee))
  expect_true(all(nzchar(ne_roster_tbl$city)))
  # The two entries that wrap in the PDF must be rejoined, not dropped or split.
  expect_true("Jennie M. Melham Memorial Medical Center" %in% ne_roster_tbl$awardee)
  expect_equal(
    ne_roster_tbl$city[ne_roster_tbl$awardee ==
                         "Jennie M. Melham Memorial Medical Center"],
    "Broken Bow")
})

test_that("the 21 NHVN member rows carry NO amount", {
  # If one ever gains an amount, Nebraska's total inflates by up to $18.2M --
  # the network's award would be counted once on its own row and again across
  # its members. §6.2: a figure is never divided.
  members <- ne_recs[!is.na(ne_recs$nhvn_member_of), ]
  expect_equal(nrow(members), 21L)
  expect_true(all(is.na(members$amount)))
  expect_true(all(members$amount_confirmed == "No"))
  expect_true(all(members$recipient_confirmed == "Yes"))
})

test_that("summing amount gives the state's published total, not more", {
  expect_equal(round(sum(ne_recs$amount, na.rm = TRUE), 2), 36137614.90)
  expect_equal(sum(!is.na(ne_recs$amount)), 57L)
  expect_equal(nrow(ne_recs), 78L)
})

test_that("Jefferson appears twice and DHHS's own warning is recorded", {
  # DHHS says in the notice not to add the two. The overlap is asserted rather
  # than silently de-duplicated.
  jeff <- ne_recs[grepl("^Jefferson Community", ne_recs$awardee), ]
  expect_equal(nrow(jeff), 2L)
  direct <- jeff[!is.na(jeff$amount), ]
  member <- jeff[is.na(jeff$amount), ]
  expect_equal(nrow(direct), 1L)
  expect_equal(round(direct$amount, 2), 446741.33)
  expect_equal(nrow(member), 1L)
  expect_true(grepl("awarded individually", member$note))
})

test_that("NHVN is PASS_THROUGH_DESIGNATED with POOL_NAMED_HOSPITALS", {
  nhvn <- ne_recs[grepl(NE_NHVN_NAME, ne_recs$awardee, fixed = TRUE) &
                    !is.na(ne_recs$amount), ]
  expect_equal(nrow(nhvn), 1L)
  expect_equal(nhvn$flow_type, "PASS_THROUGH_DESIGNATED")
  expect_equal(nhvn$distributed_to_hospital, "Yes")
  expect_equal(nhvn$intermediary_name, NE_NHVN_NAME)
  # Neither of the two pre-existing buckets is true of this row: see §8's note.
  expect_equal(nhvn$hospital_attribution, "POOL_NAMED_HOSPITALS")
})

test_that("POOL_NAMED_HOSPITALS is in §8 and is never added to the others", {
  expect_true("POOL_NAMED_HOSPITALS" %in% rhtp_vocabulary("hospital_attribution"))
  part <- rhtp_hospital_dollar_partition(ne_recs)
  expect_setequal(part$bucket, c("NAMED_HOSPITAL", "POOL_NAMED_HOSPITALS"))
  expect_equal(round(part$dollars[part$bucket == "NAMED_HOSPITAL"], 2),
               6990996.01)
  expect_equal(round(part$dollars[part$bucket == "POOL_NAMED_HOSPITALS"], 2),
               18156856.12)
  # And the function that refuses to total them must still refuse, and must
  # name the new bucket rather than dropping it silently.
  expect_error(rhtp_hospital_total(ne_recs), "POOL_NAMED_HOSPITALS")
})


# -- §10.2: the Nebraska Hospital Association ---------------------------------

test_that("the Nebraska Hospital Association is on no notice of award", {
  expect_true(ne_assert_nha_absent(ne_recs))
  expect_false(any(grepl("(?i)nebraska hospital association", ne_recs$awardee)))
  # It IS a CMS-abstract candidate, which is why its absence is worth asserting
  # rather than assuming (§4.1).
  abstracts <- readr::read_csv(
    here::here("data/reference/abstract_named_organizations.csv"),
    show_col_types = FALSE, progress = FALSE)
  nha <- abstracts[abstracts$state == "NE" &
                     abstracts$named_organization == "Nebraska Hospital Association", ]
  expect_equal(nrow(nha), 1L)
  expect_equal(nha$status, "CANDIDATE_ONLY")
})

test_that("the absence assertion fires if NHA is ever awarded", {
  faked <- ne_recs
  faked$awardee[1] <- "Nebraska Hospital Association"
  expect_error(ne_assert_nha_absent(faked), "hospital-association branch")
})


# -- §0.1: RCJ's 39 candidates ------------------------------------------------

test_that("RCJ's 39 Nebraska candidates are accounted for to the cent", {
  skip_if_not(file.exists(here::here("data/interim/stage2_record_table.rds")))
  expect_true(ne_assert_rcj_disposition(ne_award_rows))

  rt <- readRDS(here::here("data/interim/stage2_record_table.rds"))
  ne <- rt[rt$state == "NE" & rt$award_tier == "SUBAWARD" &
             is.na(rt$superseded_by), ]
  expect_equal(nrow(ne), 39L)
  expect_equal(round(sum(ne$amount_announced, na.rm = TRUE), 2), 8446843.67)

  # The 24 that RCJ filed under the APPLICANT section's heading are 4.4a's
  # AWARDS: their amounts reconcile to 4.4a's award table to the cent, which
  # is what proves the title was the defect and not the data.
  mislabelled <- ne[grepl("Organizations Submitted Applications",
                          ne$source_doc_title), ]
  expect_equal(nrow(mislabelled), 24L)
  expect_equal(round(sum(mislabelled$amount_announced), 2), 6594460.94)
})

test_that("RCJ holds NONE of Initiative 4.4b -- $27.7M it never saw", {
  skip_if_not(file.exists(here::here("data/interim/stage2_record_table.rds")))
  rt <- readRDS(here::here("data/interim/stage2_record_table.rds"))
  ne <- rt[rt$state == "NE" & rt$award_tier == "SUBAWARD" &
             is.na(rt$superseded_by), ]
  b <- ne_award_rows[ne_award_rows$source_key == "noa_4_4b", ]

  # Two 4.4b awardees share a NAME with an RCJ row -- but those RCJ rows are
  # 4.4a awards, and the amounts differ. No (name, amount) pair matches.
  pairs_ours <- paste(rhtp_ne_norm(b$awardee), round(b$amount, 2))
  pairs_rcj  <- paste(rhtp_ne_norm(ne$awardee_name_raw),
                      round(ne$amount_announced, 2))
  expect_equal(length(intersect(pairs_ours, pairs_rcj)), 0L)
  expect_equal(round(sum(b$amount), 2), 27690777.23)
})

test_that("the disposition table covers all 39 candidates", {
  path <- here::here(NE_DISPOSITION_CSV)
  skip_if_not(file.exists(path))
  disp <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(sum(disp$rcj_rows), 39L)
  expect_true("NOT_RHTP_STATE_PROGRAM" %in% disp$disposition)
  nlf <- disp[disp$disposition == "NOT_RHTP_STATE_PROGRAM", ]
  expect_equal(nlf$rcj_rows, 1L)
  expect_true(grepl("awarding state funds", nlf$basis))
  expect_true(grepl("2025-05-21", nlf$basis))
})


# -- the records --------------------------------------------------------------

test_that("every categorical column is inside §8", {
  governed <- c(recipient_type = "recipient_type",
                distributed_to_hospital = "distributed_to_hospital",
                flow_type = "flow_type",
                determination_confidence = "determination_confidence",
                validation_source_type = "source_doc_type",
                extraction_method = "extraction_method",
                validator = "validator",
                recipient_confirmed = "recipient_confirmed",
                amount_confirmed = "amount_confirmed",
                hospital_benefiting = "hospital_benefiting",
                hospital_attribution = "hospital_attribution",
                flag_reason = "flag_reason")
  for (col in names(governed)) {
    allowed <- rhtp_vocabulary(governed[[col]])
    bad <- setdiff(stats::na.omit(unique(ne_recs[[col]])), allowed)
    expect_equal(length(bad), 0L,
                 info = paste(col, ":", paste(bad, collapse = ", ")))
  }
})

test_that("every row is a NOTICE_OF_AWARD -- DHHS's own word", {
  # Nebraska is on a stronger footing than Oregon, Alaska or Maryland, all of
  # which publish intents or offers. "The following have been selected for
  # award" is §7's NOTICE_OF_AWARD on its own terms.
  expect_true(all(ne_recs$validation_source_type == "NOTICE_OF_AWARD"))
  expect_true(all(ne_recs$recipient_confirmed == "Yes"))
  txt <- stringr::str_squish(paste(ne_pdf_text("noa_4_4a"), collapse = " "))
  expect_true(stringr::str_detect(
    txt, stringr::fixed("have been selected for award")))
})

test_that("the 21 NHVN members are the only rows whose form is STATED", {
  stated <- ne_recs[ne_recs$recipient_type_source == "STATED_IN_SOURCE", ]
  expect_equal(nrow(stated), 21L)
  expect_true(all(stated$recipient_type == "HOSPITAL_OR_SYSTEM"))
  # §7 reserves HIGH for a CCN match, which this project cannot yet do.
  expect_true(all(stated$determination_confidence == "MEDIUM"))
  expect_true(all(grepl("individual hospitals receiving funding",
                        stated$determination_basis)))
  derived <- ne_recs[ne_recs$recipient_type_source == "DERIVED_FROM_NAME", ]
  expect_equal(nrow(derived), 57L)
})

test_that("nothing was promoted: the unstated-form question is queued", {
  expect_true(ne_assert_form_not_stated_queued(ne_recs))
  soft <- ne_recs[ne_recs$determination_confidence == "LOW" &
                    ne_recs$flag_reason == "RECIPIENT_TYPE_INFERRED" &
                    is.na(ne_recs$intermediary_name), ]
  expect_equal(nrow(soft), 30L)
  expect_equal(round(sum(soft$amount), 2), 9411695.59)
  # The uncertainty is LARGER than the figure beside it -- Kansas's and
  # Maryland's shape a third time.
  expect_gt(sum(soft$amount), NE_STATED$named_hospital_floor)

  # The names a reviewer will reach for first must still be UNPROMOTED.
  for (nm in c("CHI St. Mary’s", "Mary Lanning Healthcare",
               "Methodist Fremont Health", "Faith Health")) {
    row <- ne_recs[ne_recs$awardee == nm, ]
    expect_equal(nrow(row), 1L, info = nm)
    expect_equal(row$recipient_type, "NONPROFIT_CBO", info = nm)
    expect_equal(row$determination_confidence, "LOW", info = nm)
  }
})

test_that("the near-miss names are NOT auto-matched against the 4.4b roster", {
  # §2: never let a fuzzy hospital match auto-resolve. These differ by one
  # character across two documents and are exactly the match a human makes.
  expect_true("Memorial Health Care System" %in% ne_recs$awardee)      # 4.4a
  expect_true("Memorial Health Care Systems" %in% ne_recs$awardee)     # roster
  expect_true("Jefferson Community Health & Life" %in% ne_recs$awardee)
  expect_true("Jefferson Community Health and Life" %in% ne_recs$awardee)

  award_row <- ne_recs[ne_recs$awardee == "Memorial Health Care System", ]
  expect_equal(award_row$recipient_type_source, "DERIVED_FROM_NAME")
  expect_equal(award_row$determination_confidence, "LOW")
})

test_that("the committed CSV matches what the builder produces", {
  path <- here::here(NE_CSV)
  expect_true(file.exists(path))
  csv <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  expect_equal(nrow(csv), nrow(ne_recs))
  expect_equal(names(csv), names(ne_recs))
  expect_equal(round(sum(csv$amount, na.rm = TRUE), 2), 36137614.90)
})

test_that("every row points at an archived source that exists", {
  for (p in unique(ne_recs$source_archive_path)) {
    expect_true(file.exists(here::here(p)), info = p)
  }
  expect_setequal(
    unique(ne_recs$validation_source_type), "NOTICE_OF_AWARD")
})

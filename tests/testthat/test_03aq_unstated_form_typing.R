# test_03aq_unstated_form_typing.R --------------------------------------------
#
# SESSION 50. THE WEIGHT OF THIS FILE SITS ON THE LIMITS, NOT ON THE ARITHMETIC,
# because the pass moves $80,696,969.67 into the hospital total on evidence that
# is a federal enrolment record on 70 rows and a verifier's own knowledge on 4.
# The tests that carry it are the ones that would fail if the pass had reached
# further than it says it does.

suppressPackageStartupMessages({
  library(testthat)
  library(dplyr)
})
source(here::here("R", "03aq_unstated_form_typing.R"))

ms <- function() uf_read("ms_year1_awardees.csv")
sc <- function() uf_read("sc_year1_awardees.csv")

# THE PLAN IS DERIVED FROM THE BUILDERS, NOT FROM THE COMMITTED FILES, so these
# tests need the two evidence archives -- and that is the property being tested
# as much as a precondition: the committed CSV is the builder's output WITH the
# overlay on it, and both halves have to be readable to check either.
have_archives <- function() {
  dir.exists(here::here("data/evidence/MS")) &&
    dir.exists(here::here("data/evidence/SC"))
}
.built <- NULL
built <- function() {
  skip_if_not(have_archives(), "MS/SC evidence archives absent")
  if (is.null(.built)) .built <<- uf_built()
  .built
}
plan <- function() uf_plan(built = built())


# -- the pass is complete, and complete is not the same as total --------------

test_that("every open row is either typed or refused, and nothing falls between", {
  expect_true(uf_assert_complete(built = built()))
})

test_that("the pass touches ONLY rows carrying §8's standing fallback", {
  # A row some earlier session determined is not re-opened here. The plan is
  # built from `uf_open_rows()`, so this is what stops the table silently
  # over-reaching into rows Florida's owner or session 49's verifiers coded.
  pl <- plan()
  for (st in names(UF_FILES)) {
    expect_true(all(pl$row[pl$state == st] %in% uf_open_rows(built()[[st]])))
  }
})

test_that("nothing is typed that no committed row carries", {
  # uf_plan() and uf_residual() both stop() on a name with no row, so a
  # decision table that drifts from the award files fails the build rather
  # than quietly covering fewer rows.
  expect_silent(invisible(plan()))
  expect_silent(invisible(uf_residual(built = built())))
})

test_that("two organisations are REFUSED and keep the flag, and that is on purpose", {
  # Session 50 refused FOUR. Session 51 settled the two South Carolina ones
  # from ARCHIVED federal records (NPPES + the IRS EO BMF) and re-searched the
  # two Mississippi ones against six CMS enrolment files, NPPES and the BMF
  # without finding either -- so the refusal is now a measured negative.
  res <- uf_residual(built = built())
  expect_equal(nrow(res), 2L)
  expect_equal(sum(res$rows), 2L)
  expect_equal(sum(res$dollars), 3250000, tolerance = 1e-6)
  expect_true(all(res$state == "MS"))
  # The largest refusal is the one that matters: a $3,000,000 Mississippi row
  # whose stem matches BOTH a hospital and an FQHC, so a stem match could type
  # it either way and neither would be a determination (§2).
  dhtc <- res %>% filter(awardee == "Delta Health Transformation Council, Inc.")
  expect_equal(dhtc$dollars, 3000000)
  m <- ms()
  r <- which(m$awardee == "Delta Health Transformation Council, Inc.")
  expect_equal(m$recipient_type[r], "NONPROFIT_CBO")
  expect_true(grepl("RECIPIENT_TYPE_INFERRED", m$flag_reason[r]))
  expect_equal(m$determination_confidence[r], "LOW")
})


# -- the counterfactuals ------------------------------------------------------

test_that("the pass is ONE-DIRECTIONAL: no row leaves a hospital bucket", {
  # Every open row was distributed_to_hospital = No before this pass, which is
  # what makes the state figures a genuine FLOOR beforehand and what makes this
  # assertion meaningful rather than decorative.
  pl <- plan()
  expect_equal(sum(pl$bucket_before != "NOT_HOSPITAL"), 0L)
})

test_that("the flow test is re-run EXACTLY where the re-type crosses §10.2's DIRECT row", {
  pl <- plan()
  crossed <- pl$new_type == "HOSPITAL_OR_SYSTEM"
  expect_true(all(pl$new_flow[crossed] == "DIRECT"))
  expect_true(all(pl$new_dth[crossed] == "Yes"))
  expect_true(all(pl$new_attr[crossed] == "NAMED_HOSPITAL"))
  # And left alone everywhere else -- session 49's rule. Re-running §10.2 on a
  # row that does not cross the identity test could only overwrite a state
  # extractor's reading of its own source.
  expect_true(all(pl$new_flow[!crossed] == pl$old_flow[!crossed]))
  expect_true(all(pl$new_dth[!crossed] == pl$old_dth[!crossed]))
})

test_that("a GENERAL_KNOWLEDGE answer stays LOW and a record answer is MEDIUM", {
  pl <- plan()
  expect_true(all(pl$new_conf[pl$basis_type == "GENERAL_KNOWLEDGE"] == "LOW"))
  expect_true(all(pl$new_conf[pl$basis_type != "GENERAL_KNOWLEDGE"] == "MEDIUM"))
  # §7 reserves HIGH for a CCN match on the AWARD ROW, which nothing here has.
  expect_false(any(pl$new_conf == "HIGH"))
})

test_that("the three hand-read bridges are LOW and a reader can subtract them", {
  pl <- plan()
  bridges <- c("Webster Healthcare Services, Inc.", "Ochsner MS",
               "Southwest Mississippi Regional Center")
  b <- pl %>% filter(awardee %in% bridges)
  expect_equal(nrow(b), 3L)
  expect_true(all(b$basis_type == "GENERAL_KNOWLEDGE"))
  expect_true(all(b$new_conf == "LOW"))
  expect_equal(sum(b$amount), 3777077, tolerance = 1e-6)
  # Each one says WHY the bridge is a judgement, in the row.
  expect_true(all(grepl("HAND-READ BRIDGE", b$why)))
})

test_that("Acadia is typed AND queued, because it is the largest judgement here", {
  pl <- plan()
  a <- pl %>% filter(awardee == "Acadia Healthcare Co.")
  expect_equal(nrow(a), 1L)
  expect_equal(a$new_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(a$basis_type, "GENERAL_KNOWLEDGE")
  expect_equal(a$new_conf, "LOW")
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  row <- q[q$question_id == "SC_ACADIA_PARENT_SCOPE", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$queue_status, "OPEN")
  expect_true(grepl("5,565,253", row$dollar_effect))
})


# -- §0.3a: the type is read off the RECIPIENT, never off the activity --------

test_that("no decision cites the award's description", {
  # Mississippi publishes a description of the WORK on all 167 rows and South
  # Carolina a project name on all 228. Neither is used. This drives that by
  # requiring no `why` to quote the state's own description column.
  m <- ms(); s <- sc()
  notes <- c(m$note, s$note)
  for (w in UF_TYPES$why) {
    expect_false(any(vapply(notes, function(n)
      nzchar(n) && n != UF_EMPTY && grepl(n, w, fixed = TRUE), logical(1))))
  }
})

test_that("two stem traps are refused by name, and both are real bodies", {
  # Singing River SERVICES is the Region 14 community mental health centre;
  # Singing River HEALTH SYSTEM is the hospital, in a different county.
  srv <- UF_TYPES %>% filter(awardee == "Singing River Services")
  expect_equal(srv$new_type, "OTHER")
  expect_true(grepl("NOT SINGING RIVER HEALTH SYSTEM", srv$why))
  # George Regional Health and Rehab is a skilled nursing facility; George
  # Regional Hospital is a different body and is not an awardee here.
  grr <- UF_TYPES %>% filter(awardee == "George Regional Health and Rehab")
  expect_equal(grr$new_type, "OTHER")
  expect_true(grepl("NOT GEORGE REGIONAL HOSPITAL", grr$why))
})

test_that("every OTHER row states the determined form, which is what that code requires", {
  o <- UF_TYPES %>% filter(new_type == "OTHER")
  expect_gt(nrow(o), 30L)
  expect_true(all(nzchar(o$determined_form)))
  # `OTHER` with nothing behind it is §8's fallback wearing a different name,
  # which is the one use that code does not have.
  expect_false(any(o$determined_form == "NONPROFIT_CBO"))
  pl <- plan() %>% filter(new_type == "OTHER")
  expect_true(all(nzchar(pl$determined_form)))
})

test_that("no spelling is merged with another (§2)", {
  # South Carolina spells Prisma Health TEN ways and Self Regional NINE (the
  # ninth, Greenwood Pediatrics, reached this pass in session 53, §0.3a);
  # Mississippi spells Delta Health Center, Independent Healthcare Management,
  # Mantachie and LIFECORE two ways each. Every one is a separate decision row.
  expect_equal(sum(grepl("^Prisma Health", UF_TYPES$awardee)), 10L)
  expect_equal(sum(grepl("^Self Regional", UF_TYPES$awardee)), 9L)
  expect_equal(sum(grepl("^Independent Healthcare Management", UF_TYPES$awardee)), 2L)
  expect_equal(sum(grepl("LIFECORE", UF_TYPES$awardee)), 2L)
  expect_equal(nrow(UF_TYPES), length(unique(UF_TYPES$awardee)))
})


# -- what the committed files now carry ---------------------------------------

test_that("the overlay is IDEMPOTENT against the committed files", {
  # `--apply` runs it over the committed table as well as a fresh build, and a
  # basis sentence prepended twice is a diff nobody asked for.
  for (f in unname(UF_FILES)) {
    d <- uf_read(f)
    expect_identical(uf_overlay(d, f), d)
  }
})

test_that("Mississippi and South Carolina carry the typing, and the residual only", {
  m <- ms(); s <- sc()
  expect_equal(length(uf_open_rows(m)), 2L)
  expect_equal(length(uf_open_rows(s)), 0L)  # session 51 settled the last three SC rows
  expect_equal(sum(m$hospital_attribution == "NAMED_HOSPITAL"), 84L)
  expect_equal(sum(s$hospital_attribution == "NAMED_HOSPITAL"), 114L)  # 113 + Greenwood Pediatrics (session 53)
  expect_equal(sum(as.numeric(m$amount[m$hospital_attribution == "NAMED_HOSPITAL"])),
               68898204.67, tolerance = 1e-6)
  expect_equal(sum(as.numeric(s$amount[s$hospital_attribution == "NAMED_HOSPITAL"])),
               115985714.95, tolerance = 1e-6)
  # Neither state's published total moved. This pass re-TYPES; it re-prices
  # nothing.
  expect_equal(sum(as.numeric(m$amount)), 104115146.80, tolerance = 1e-6)
  expect_equal(sum(as.numeric(s$amount)), 167299900.69, tolerance = 1e-6)
})

test_that("every typed row carries basis_type, a verifier and a basis", {
  for (f in unname(UF_FILES)) {
    d <- uf_read(f)
    touched <- d$basis_type != UF_EMPTY
    expect_gt(sum(touched), 90L)
    expect_true(all(d$verified_by[touched] == "session 50 unstated-form typing"))
    expect_true(all(nzchar(d$verified_basis[touched])))
    expect_true(all(d$verified_basis[touched] != UF_EMPTY))
    expect_true(all(d$basis_type[touched] %in%
                      c("STATE_SOURCE", "ORG_WEBSITE", "GENERAL_KNOWLEDGE")))
    # NOT ONE of these answers rests on the STATE's own source, and that is the
    # shape of the question rather than a weakness in the answers: a state's
    # award document names a recipient and an amount and does not say what KIND
    # of organisation it is, which is exactly why these rows were flagged.
    expect_equal(sum(d$basis_type[touched] == "STATE_SOURCE"), 0L)
  }
})

test_that("`recipient_type_source` is NOT overwritten", {
  # Session 49's lesson: each state file already means something by that
  # column, and this pass's provenance goes in basis_type / verified_by /
  # verified_basis, which are its own columns and nobody else's.
  m <- ms()
  r <- which(m$awardee == "Winston County Medical Foundation")
  expect_true(all(grepl("STANDING FALLBACK", m$recipient_type_source[r])))
  expect_equal(unique(m$recipient_type[r]), "HOSPITAL_OR_SYSTEM")
})

test_that("every new code is in the vocabulary", {
  v <- readr::read_csv(here::here("data/reference/vocabularies.csv"),
                       show_col_types = FALSE, progress = FALSE)
  ok <- v$allowed_value[v$column_name == "recipient_type"]
  expect_true(all(UF_TYPES$new_type %in% ok))
  for (f in unname(UF_FILES)) {
    d <- uf_read(f)
    expect_true(all(d$recipient_type %in% ok))
  }
})


# -- the two queue rows this pass closes and the one it opens -----------------

test_that("the two South Carolina refusals are settled from ARCHIVED federal records", {
  sc <- sc_now <- readr::read_csv(here::here("data/reference/sc_year1_awardees.csv"),
                                  col_types = readr::cols(.default = "c"),
                                  na = character(), progress = FALSE)
  ci <- sc[sc$awardee == "Community Initiatives Inc.", ]
  expect_equal(nrow(ci), 2L)
  expect_true(all(ci$recipient_type == "NONPROFIT_CBO"))
  expect_true(all(ci$determination_confidence == "MEDIUM"))
  expect_false(any(grepl("RECIPIENT_TYPE_INFERRED", ci$flag_reason)))
  gh <- sc[sc$awardee == "Graceful Health Solutions, LLC", ]
  expect_equal(nrow(gh), 1L)
  expect_equal(gh$recipient_type, "OTHER")
  expect_false(grepl("RECIPIENT_TYPE_INFERRED", gh$flag_reason))
  # Neither is a hospital, so the partition does not move.
  expect_true(all(c(ci$distributed_to_hospital, gh$distributed_to_hospital) == "No"))
  # South Carolina has NO row left on §8's standing fallback.
  expect_false(any(grepl("RECIPIENT_TYPE_INFERRED", sc$flag_reason)))

  # The evidence is committed, and the manifest's digests re-hash.
  dir <- here::here("data/evidence/federal_records/2026-09-22")
  man <- readLines(file.path(dir, "MANIFEST.txt"))
  rows <- grep("^[a-z_]+[A-Z]{2}\\.(json|csv) \\| [0-9a-f]{64}", man, value = TRUE)
  expect_gte(length(rows), 16L)
  for (r in rows) {
    parts <- strsplit(r, " \\| ")[[1]]
    expect_equal(digest::digest(file = file.path(dir, parts[1]), algo = "sha256"),
                 parts[2], info = parts[1])
  }
  np <- jsonlite::fromJSON(file.path(dir, "nppes_graceful_health_solutions_SC.json"))
  expect_equal(np$result_count, 1L)
  expect_equal(np$results$basic$organization_name, "GRACEFUL HEALTH SOLUTIONS LLC")
  irs <- readr::read_csv(file.path(dir, "irs_eo_bmf_SC_extract.csv"),
                         col_types = readr::cols(.default = "c"), progress = FALSE)
  expect_equal(irs$NAME[irs$NAME == "COMMUNITY INITIATIVES INC"], "COMMUNITY INITIATIVES INC")
  expect_equal(irs$CITY[irs$NAME == "COMMUNITY INITIATIVES INC"], "GREENWOOD")
  # And the Mississippi negatives are recorded as negatives.
  for (f in c("nppes_delta_health_transformation_MS.json", "nppes_camhp_MS.json")) {
    expect_equal(jsonlite::fromJSON(file.path(dir, f))$result_count, 0L)
  }
  h <- jsonlite::fromJSON(file.path(dir, "cms_hosp_enrollments_MS.json"))
  expect_false(any(grepl("TRANSFORMATION COUNCIL|CAMHP", h$`ORGANIZATION NAME`)))
})

test_that("the Mississippi form and foundation questions read RESOLVED", {
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  for (id in c("MS_RECIPIENT_FORM_NOT_STATED", "MS_FOUNDATION_PARENT_NOT_STATED",
               "VQ_INKIND_AFTER_RETYPE")) {
    row <- q[q$question_id == id, ]
    expect_equal(nrow(row), 1L)
    expect_equal(row$queue_status, "RESOLVED")
    expect_true(nzchar(row$resolution))
  }
  expect_equal(q$queue_status[q$question_id == "UF_FORM_NOT_DETERMINABLE"], "OPEN")
})

test_that("Winston County Medical Foundation is a hospital by its OWN legal name", {
  # The point that makes this row safe: §10.2's hospital-foundation row is NOT
  # what reaches it. CMS carries the awardee string itself as an ORGANIZATION
  # NAME against a CCN, so the foundation IS the hospital rather than an arm of
  # one, and the NAMED-parent test is never reached.
  w <- UF_TYPES %>% filter(awardee == "Winston County Medical Foundation")
  expect_equal(w$new_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(w$basis_type, "ORG_WEBSITE")
  expect_true(grepl("CCN 250027", w$why))
  expect_true(grepl("NOT §10.2's hospital-foundation row", w$why, fixed = TRUE))
  pl <- plan() %>% filter(awardee == "Winston County Medical Foundation")
  expect_equal(nrow(pl), 4L)
  expect_equal(sum(pl$amount), 3785455.49, tolerance = 1e-6)
  # One of the four carried IN_KIND_BENEFIT and its flow was re-run.
  expect_true(any(pl$old_flow == "IN_KIND_BENEFIT"))
  expect_true(all(pl$new_flow == "DIRECT"))
})


# -- South Carolina against the agency benchmark ------------------------------

test_that("the benchmark comparison is a check and not a target", {
  b <- uf_sc_benchmark()
  aw <- b[b$measure == "% of awards", ]
  dl <- b[b$measure == "% of dollars", ]
  # THE AWARD-COUNT HALF LANDS ON THE BENCHMARK ALMOST EXACTLY -- 49.6% against
  # ~50% -- which session 47 could only bracket between 24.1% and 89.9%.
  expect_lt(abs(aw$typed_now - 50), 1)
  # THE DOLLAR HALF OVERSHOOTS AND IS REPORTED OVERSHOOTING. 69.2% against ~60%,
  # 65.9% with Acadia subtracted. NOTHING WAS ADJUSTED TOWARD THE BENCHMARK and
  # this test exists to fail if a later session quietly does.
  expect_gt(dl$typed_now, dl$benchmark)
  expect_lt(abs(dl$typed_now - 69.24), 0.1)
  # Both still sit inside session 47's floor-to-ceiling range, which is what
  # says the extraction was sound all along.
  expect_gt(aw$typed_now, aw$floor_session47)
  expect_lt(aw$typed_now, aw$ceiling_session47)
  expect_gt(dl$typed_now, dl$floor_session47)
  expect_lt(dl$typed_now, dl$ceiling_session47)
})


# -- Iowa's Centers of Excellence pool: out of the partition (session 51) -----

test_that("Iowa has NO pool row: session 51 removed it (a bucket must not mix tiers)", {
  ia <- suppressMessages(readr::read_csv(
    here::here("data/reference/ia_year1_awardees.csv"),
    show_col_types = FALSE, progress = FALSE))
  expect_equal(nrow(ia), 264L)
  expect_false(any(grepl("AMOUNT_IS_POOL_NOT_AWARD", ia$flag_reason)))
  expect_true(all(is.na(ia$amount)))
  # The ten Centers of Excellence award ACTIONS are in NAMED_HOSPITAL at $0,
  # ONCE. Session 50's pool row put the same ten awards in a second bucket.
  coe <- ia[ia$award_pool == "PHTHORC26008", ]
  expect_equal(nrow(coe), 10L)
  expect_true(all(coe$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(coe$hospital_attribution == "NAMED_HOSPITAL"))
  expect_true(all(is.na(coe$amount)))
})

test_that("the $50,000,000 is still SOLICITATION in the footer table", {
  # The context note in ia_notice_footers.csv rests on this: it says the figure
  # is Tier 2, and that is why it is not in any hospital bucket.
  f <- suppressMessages(readr::read_csv(
    here::here("data/reference/ia_notice_footers.csv"),
    show_col_types = FALSE, progress = FALSE))
  coe <- f[f$rfp == "PHTHORC26008", ]
  expect_equal(nrow(coe), 1L)
  expect_equal(coe$footer_tier, "SOLICITATION")
  expect_equal(coe$footer_amount, 50000000)
})

test_that("IA_COE_POOL_IS_TIER_2 reads RESOLVED, option (b), and UF_FORM_NOT_DETERMINABLE is Mississippi only", {
  q <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                       show_col_types = FALSE, progress = FALSE)
  ia <- q[q$question_id == "IA_COE_POOL_IS_TIER_2", ]
  expect_equal(ia$queue_status, "RESOLVED")
  expect_match(ia$resolution, "^OPTION \\(b\\)")
  expect_match(ia$resolution, "MUST NOT MIX TIERS", fixed = TRUE)
  uf <- q[q$question_id == "UF_FORM_NOT_DETERMINABLE", ]
  expect_equal(uf$state, "MS")
  expect_match(uf$dollar_effect, "^\\$3,250,000 across 2 rows")
})

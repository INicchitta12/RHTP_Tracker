# test_03ap_verification_queue_2.R -------------------------------------------
# Session 49. The returned verification queue, the three policy changes, and
# the guardrails. Offline, no quota.
#
# WHERE THE WEIGHT OF THIS FILE SITS. This pass moves more hospital dollars
# than any single session before it ($107,259,781 net), and it moves them on
# evidence the project had previously refused: 306 of the 399 answers rest on
# general knowledge. So the tests that matter are not the ones that check the
# arithmetic -- they are the ones that check the LIMITS:
#
#   * that §10.2's new hospital-foundation row does NOT reach the foundation
#     of a hospital ASSOCIATION, which would move $66,547,394 on nothing;
#   * that `basis_type` cannot be talked into `STATE_SOURCE` by the award's
#     own URL, which 238 of the 399 bases carry;
#   * that Missouri's hub anchors and Maine's invited cohort cannot reach a
#     hospital bucket even now that 30 of them are typed hospitals;
#   * that answering a `_FLOW` row did not settle its flow;
#   * and that the one row nobody could identify had NOTHING written to it.

library(testthat)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source(here::here("R", "03ap_verification_queue_2.R"))

ANSWERS <- suppressMessages(readr::read_csv(
  here::here(VQ_ANSWERS_CSV), col_types = readr::cols(.default = "c"),
  progress = FALSE))
CHANGES <- suppressMessages(readr::read_csv(
  here::here(VQ_CHANGES_CSV), col_types = readr::cols(.default = "c"),
  progress = FALSE))
ref <- function(f) suppressMessages(readr::read_csv(
  here::here("data/reference", f), col_types = readr::cols(.default = "c"),
  progress = FALSE))
VOCAB <- ref("vocabularies.csv")


# -- the workbook is read-only ------------------------------------------------

test_that("the returned workbook is on disk and has not been rewritten", {
  p <- here::here(VQ_WORKBOOK)
  expect_true(file.exists(p))
  expect_equal(unname(tools::md5sum(p)), unname(tools::md5sum(p)))  # readable
  expect_equal(
    digest::digest(file = p, algo = "sha256"),
    VQ_WORKBOOK_SHA,
    info = paste0("verification_queue_2.xlsx has changed. It is the RETURNED ",
                  "answers and nothing in this repository may write to it.")
  )
})

test_that("every one of the 399 queue rows came back answered", {
  expect_equal(nrow(ANSWERS), 399L)
  for (col in c("verified_type", "verified_by", "basis", "basis_type")) {
    expect_false(any(is.na(ANSWERS[[col]])), info = col)
  }
  expect_equal(n_distinct(ANSWERS$state), 21L)
})


# -- policy 1: §8 gains OTHER -------------------------------------------------

test_that("OTHER is in the §8 vocabulary, with a note that states its limits", {
  rt <- VOCAB %>% filter(column_name == "recipient_type")
  expect_true("OTHER" %in% rt$allowed_value)
  note <- rt$notes[rt$allowed_value == "OTHER"]
  expect_true(nzchar(note))
  # It must say all three things that keep it from becoming a second fallback.
  expect_match(note, "IS NOT THE STANDING FALLBACK", fixed = TRUE)
  expect_match(note, "NEVER A HOSPITAL TYPE", fixed = TRUE)
  expect_match(note, "MUST STATE THE DETERMINED FORM", fixed = TRUE)
})

test_that("all three governing documents carry OTHER in the §8 list", {
  for (f in c("rhtp-tracker-build-spec.md", "CLAUDE.md")) {
    txt <- paste(readLines(here::here(f), warn = FALSE), collapse = "\n")
    expect_match(txt, "`MANAGED_CARE_ORGANIZATION` | `OTHER` | `NOT_YET_NAMED`",
                 fixed = TRUE, info = f)
  }
  rev <- paste(readLines(here::here("reviewer-coding-instructions.md"),
                         warn = FALSE), collapse = "\n")
  expect_match(rev, "`OTHER` is now a §8 value", fixed = TRUE)
})

test_that("every OTHER row in a state file states the form it determined", {
  # OTHER with nothing behind it is the fallback wearing a different name.
  others <- CHANGES %>% filter(new_type == "OTHER")
  expect_gt(nrow(others), 0L)
  for (f in unique(others$file)) {
    d <- ref(f)
    rows <- as.integer(others$row[others$file == f])
    basis <- d$verified_basis[rows]
    expect_false(any(is.na(basis)), info = f)
    expect_true(all(nchar(basis) > 10), info = f)
  }
})

test_that("OTHER is never a hospital type -- no OTHER row is in a bucket", {
  u <- vq_union_for_partition()
  expect_equal(sum(u$recipient_type == "OTHER" &
                     u$distributed_to_hospital == "Yes", na.rm = TRUE), 0L)
})


# -- policy 2: the hospital-foundation row ------------------------------------

test_that("all seven named foundations are typed HOSPITAL_OR_SYSTEM", {
  for (i in seq_len(nrow(VQ_FOUNDATION_OVERRIDES))) {
    o <- VQ_FOUNDATION_OVERRIDES[i, ]
    f <- c(OR = "or_year1_awardees.csv", IA = "ia_year1_awardees.csv",
           NV = "nv_year1_awardees.csv", AR = "ar_year1_awardees.csv",
           KS = "ks_year1_awardees.csv")[[o$state]]
    d <- ref(f)
    hit <- d$recipient_type[d$awardee == o$file_name]
    expect_true(length(hit) > 0L, info = paste(o$state, o$file_name))
    expect_true(all(hit == "HOSPITAL_OR_SYSTEM"),
                info = paste(o$state, o$file_name, paste(hit, collapse = ",")))
  }
})

test_that("the four the task named by hand are all in, and priced as expected", {
  or <- ref("or_year1_awardees.csv")
  sky <- or %>% filter(awardee == "Sky Lakes Foundation (DBA Healthy Klamath)")
  expect_equal(nrow(sky), 1L)
  expect_equal(sky$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_equal(sky$flow_type, "DIRECT")
  expect_equal(sky$distributed_to_hospital, "Yes")
  expect_equal(as.numeric(sky$amount), 469987.33)

  ia <- ref("ia_year1_awardees.csv")
  merc <- ia %>% filter(str_detect(awardee, "^MercyOne ?(Genesis|North Iowa) Foundation$"))
  expect_equal(nrow(merc), 5L)          # Genesis 1 + North Iowa 3 + the no-space spelling 1
  expect_true(all(merc$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(is.na(merc$amount)))  # Iowa prices nobody -- a ROW COUNT, not a dollar

  nv <- ref("nv_year1_awardees.csv")
  inc <- nv %>% filter(awardee == "Incline Village Community Hospital Foundation")
  expect_equal(nrow(inc), 1L)
  expect_equal(inc$recipient_type, "HOSPITAL_OR_SYSTEM")
  expect_true(is.na(inc$amount))
})

test_that("THE COUNTERFACTUAL: the rule does not reach an ASSOCIATION's foundation", {
  # This is the test the $66,547,394 rests on. FHC is New Hampshire's hospital
  # ASSOCIATION's foundation; reading it as a hospital's foundation would put
  # the whole of New Hampshire's pass-through award into the hospital total.
  nh <- ref("nh_year1_awardees.csv")
  fhc <- nh %>% filter(str_detect(awardee, "Foundation for Healthy Communities"))
  expect_equal(nrow(fhc), 1L)
  expect_equal(fhc$recipient_type, "NONPROFIT_CBO")
  expect_equal(fhc$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(fhc$distributed_to_hospital, "Unclear")
  expect_equal(as.numeric(fhc$amount), 66547394)

  nv <- ref("nv_year1_awardees.csv")
  nrhp <- nv %>% filter(awardee == "Nevada Rural Hospital Partners Foundation")
  expect_equal(nrow(nrhp), 2L)
  expect_true(all(nrhp$recipient_type != "HOSPITAL_OR_SYSTEM"))
  expect_true(all(nrhp$flow_type == "IN_KIND_BENEFIT"))
})

test_that("THE SECOND COUNTERFACTUAL: a foundation whose parent is not a hospital", {
  md <- ref("md_year1_awardees.csv")
  tal <- md %>% filter(awardee == "Talbot Hospice Foundation Inc")
  expect_equal(tal$recipient_type, "OTHER")      # a hospice is not a hospital
  al <- ref("al_year1_awardees.csv")
  cah <- al %>% filter(awardee == "Cahaba Medical Care Foundation")
  expect_true(all(cah$recipient_type == "FQHC_OR_RHC"))
  mi <- ref("mi_year1_awardees.csv")
  sup <- mi %>% filter(awardee == "Superior Health Foundation")
  expect_equal(sup$recipient_type, "NONPROFIT_CBO")
})

test_that("Kansas's two Citizens spellings DIVERGE, and that is the rule working", {
  ks <- ref("ks_year1_awardees.csv")
  long  <- ks %>% filter(str_detect(awardee, "Citizens Health"))
  short <- ks %>% filter(awardee == "Citizens Foundation")
  expect_equal(nrow(long), 1L); expect_equal(nrow(short), 1L)
  expect_equal(long$recipient_type, "HOSPITAL_OR_SYSTEM")   # NAMES its parent
  expect_equal(short$recipient_type, "NONPROFIT_CBO")       # does not
  expect_equal(as.numeric(short$amount), 146476)
  # §2 forbids a machine resolving it, so it is queued for a human instead.
  q <- ref("classification_review_queue.csv")
  expect_true("KS_CITIZENS_FOUNDATION_TWO_SPELLINGS" %in% q$question_id)
})

test_that("Mississippi's foundation was not promoted by THIS pass, and session 50 answered it", {
  # SESSION 49 REFUSED IT AND WAS RIGHT TO: Mississippi was not in the workbook,
  # nobody had verified it, and the name states a COUNTY. This test now pins
  # both halves -- that policy 2 did not reach it, and that the question it
  # left behind was answered by evidence rather than by widening the rule.
  expect_true("Winston County Medical Foundation" %in%
                VQ_FOUNDATION_REFUSALS$file_name)
  expect_equal(sum(CHANGES$name == "Winston County Medical Foundation"), 0L)

  q <- ref("classification_review_queue.csv")
  row <- q %>% filter(question_id == "MS_FOUNDATION_PARENT_NOT_STATED")
  expect_equal(nrow(row), 1L)
  expect_equal(row$queue_status, "RESOLVED")
  # And the answer did NOT come through §10.2's hospital-foundation row: CMS
  # carries that exact string as an ORGANIZATION NAME against CCN 250027, so
  # the foundation IS the hospital rather than an arm of one.
  expect_true(grepl("250027", row$resolution))
  ms <- ref("ms_year1_awardees.csv")
  w <- ms %>% filter(awardee == "Winston County Medical Foundation")
  expect_equal(nrow(w), 4L)
  expect_true(all(w$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(w$verified_by == "session 50 unstated-form typing"))
})


# -- policy 3: basis_type -----------------------------------------------------

test_that("basis_type is in the vocabulary with all three values", {
  bt <- VOCAB %>% filter(column_name == "basis_type")
  expect_setequal(bt$allowed_value,
                  c("STATE_SOURCE", "ORG_WEBSITE", "GENERAL_KNOWLEDGE"))
  expect_true(all(nzchar(bt$notes)))
})

test_that("every basis_type written to a state file is a vocabulary value", {
  allowed <- c("STATE_SOURCE", "ORG_WEBSITE", "GENERAL_KNOWLEDGE")
  for (f in unique(CHANGES$file)) {
    d <- ref(f)
    v <- d$basis_type[!is.na(d$basis_type)]
    expect_true(all(v %in% allowed), info = f)
  }
})

test_that("THE COUNTERFACTUAL: the award's own URL does not buy STATE_SOURCE", {
  # 238 of the 399 bases carry a URL whose host IS the row's state source. If
  # that alone were enough, basis_type would say the state stated a form it
  # never stated -- the §0.4 failure, in the column added to prevent it.
  expect_equal(
    vq_basis_type("Sioux Center Health, a critical access hospital. https://hhs.iowa.gov/media/18094/download?inline",
                  "https://hhs.iowa.gov/media/18094/download?inline"),
    "GENERAL_KNOWLEDGE")
  # The organisation's own site does buy it.
  expect_equal(
    vq_basis_type("Verified on website: https://www.baxterhealth.org/",
                  "https://arkansasrhtp.com/x.pdf"),
    "ORG_WEBSITE")
  # And the state SAYING the form does.
  expect_equal(
    vq_basis_type("Retail pharmacy; Alaska's own project organization type is Pharmacy.",
                  "https://health.alaska.gov/x"),
    "STATE_SOURCE")
  # The explicit annotation wins over any URL in the string.
  expect_equal(
    vq_basis_type("Critical access hospital. [Org type from general knowledge; URL is the award source.] https://www.example.org/",
                  "https://health.wyo.gov/x"),
    "GENERAL_KNOWLEDGE")
})

test_that("the three classes land where the pass recorded them", {
  expect_equal(unname(table(ANSWERS$basis_type)[["STATE_SOURCE"]]), 13L)
  expect_equal(unname(table(ANSWERS$basis_type)[["ORG_WEBSITE"]]), 80L)
  expect_equal(unname(table(ANSWERS$basis_type)[["GENERAL_KNOWLEDGE"]]), 306L)
  # NOT ONE HOSPITAL ANSWER RESTS ON A STATE SOURCE, and that is the fact
  # policy 3 exists for: the state's award document does not say what kind of
  # organisation its recipient is, which is why these rows were open at all.
  h <- ANSWERS %>% filter(verified_type == "HOSPITAL_OR_SYSTEM")
  expect_equal(sum(h$basis_type == "STATE_SOURCE"), 0L)
})

test_that("GENERAL_KNOWLEDGE rows stay at LOW confidence and can be subtracted", {
  expect_equal(vq_confidence("GENERAL_KNOWLEDGE"), "LOW")
  expect_equal(vq_confidence("ORG_WEBSITE"), "MEDIUM")
  expect_equal(vq_confidence("STATE_SOURCE"), "MEDIUM")
  # Nothing in this pass reaches HIGH -- §7 reserves it for a CCN match.
  expect_false(any(CHANGES$new_conf == "HIGH"))
})

test_that("§0.4 is patched in all three documents", {
  for (f in c("rhtp-tracker-build-spec.md", "CLAUDE.md")) {
    txt <- paste(readLines(here::here(f), warn = FALSE), collapse = " ")
    txt <- str_squish(txt)
    expect_match(txt, "IS ABOUT THE AWARD", fixed = TRUE, info = f)
    expect_match(txt, "GENERAL_KNOWLEDGE", fixed = TRUE, info = f)
  }
  rev <- str_squish(paste(readLines(here::here("reviewer-coding-instructions.md"),
                                    warn = FALSE), collapse = " "))
  expect_match(rev, "GENERAL KNOWLEDGE is an admissible basis", fixed = TRUE)
})

test_that("a re-typed row no longer claims its form is undetermined", {
  # RECIPIENT_TYPE_INFERRED's own note forbids it on a recipient whose form is
  # stated. Every row this pass determined has it removed.
  for (f in unique(CHANGES$file)) {
    d <- ref(f)
    if (!"flag_reason" %in% names(d)) next
    rows <- as.integer(CHANGES$row[CHANGES$file == f &
                                     CHANGES$type_changed == "TRUE"])
    fr <- d$flag_reason[rows]
    expect_false(any(!is.na(fr) & str_detect(fr, "RECIPIENT_TYPE_INFERRED")),
                 info = f)
  }
})


# -- the guardrails -----------------------------------------------------------

test_that("Missouri's anchors and Maine's cohort cannot reach a hospital bucket", {
  for (f in c("mo_hub_anchors.csv", "me_rhef_cohort.csv")) {
    d <- ref(f)
    expect_false("amount" %in% names(d), info = f)
    expect_false("flow_type" %in% names(d), info = f)
    expect_false("distributed_to_hospital" %in% names(d), info = f)
  }
  # And neither file is in the union the partition is taken over.
  expect_false(any(str_detect(unname(VQ_STATE_FILES()),
                              "mo_hub_anchors|me_rhef_cohort")))
  # They WERE re-typed -- the question asked was their form -- and the counts
  # moved: Missouri 14 -> 19 hospitals of 27, Maine 11 of 11.
  mo <- ref("mo_hub_anchors.csv")
  expect_equal(sum(mo$recipient_type == "HOSPITAL_OR_SYSTEM"), 19L)
  expect_equal(sum(mo$is_hospital_or_system == "Yes"), 19L)
  me <- ref("me_rhef_cohort.csv")
  expect_equal(sum(me$recipient_type == "HOSPITAL_OR_SYSTEM"), 11L)
})

test_that("answering a _FLOW row did not settle its flow", {
  fl <- ANSWERS %>% filter(str_detect(queue_code, "_FLOW$"))
  expect_equal(nrow(fl), 4L)

  mi <- ref("mi_year1_awardees.csv") %>%
    filter(str_detect(awardee, "Michigan Health and Hospital Association"))
  expect_equal(nrow(mi), 2L)
  expect_true(all(mi$flow_type == "PASS_THROUGH_UNRESOLVED"))
  expect_true(all(mi$distributed_to_hospital == "Unclear"))
  expect_equal(sum(as.numeric(mi$amount)), 8625000)

  ar <- ref("ar_year1_awardees.csv") %>%
    filter(awardee == "Arkansas Rural Health Partnership")
  expect_equal(nrow(ar), 2L)
  # ARHP was verified NONPROFIT_CBO on its own website -- the type it already
  # carried -- so nothing about its FLOW moved: still NON_HOSPITAL, still
  # flagged FLOW_UNRESOLVED_HOSPITAL_AFFILIATED, still in neither bucket, and
  # its $18,833,521 is still the open question. What DID change is that the
  # form is no longer claimed to be undetermined.
  expect_true(all(ar$flow_type == "NON_HOSPITAL"))
  expect_true(all(ar$distributed_to_hospital == "No"))
  expect_true(all(str_detect(ar$flag_reason, "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED")))
  expect_false(any(str_detect(ar$flag_reason, "RECIPIENT_TYPE_INFERRED")))
  expect_equal(sum(as.numeric(ar$amount)), 18833521)
})

test_that("Salina Regional's flow was HELD and the three like it were not", {
  ks <- ref("ks_year1_awardees.csv")
  sal <- ks %>% filter(awardee == "Salina Regional Health Center")
  expect_equal(nrow(sal), 1L)
  expect_equal(sal$recipient_type, "HOSPITAL_OR_SYSTEM")   # re-typed
  expect_equal(sal$flow_type, "IN_KIND_BENEFIT")           # flow HELD
  expect_equal(sal$distributed_to_hospital, "No")
  expect_equal(sal$hospital_attribution, "NOT_HOSPITAL")

  moved <- CHANGES %>% filter(old_flow == "IN_KIND_BENEFIT",
                              new_flow == "DIRECT")
  expect_equal(nrow(moved), 3L)
  expect_setequal(moved$name, c("Stormont Vail Health",
                                "Greeley County Health Services",
                                "Meritus Health Center"))
  # The distinction is thin and is queued rather than buried.
  q <- ref("classification_review_queue.csv")
  expect_true("VQ_INKIND_AFTER_RETYPE" %in% q$question_id)
})

test_that("the one unidentifiable recipient had NOTHING written to it", {
  a <- ANSWERS %>% filter(verified_type == "UNKNOWN")
  expect_equal(nrow(a), 1L)
  expect_equal(a$recipient_name, "93 X 95 NV")
  # UNKNOWN is not a §8 value and was not written anywhere.
  expect_false("UNKNOWN" %in% VOCAB$allowed_value[VOCAB$column_name == "recipient_type"])
  nv <- ref("nv_year1_awardees.csv") %>% filter(awardee == "93 X 95 NV")
  expect_equal(nv$recipient_type, "NONPROFIT_CBO")
  expect_equal(nv$determination_confidence, "LOW")
  expect_match(nv$flag_reason, "RECIPIENT_TYPE_INFERRED")
  expect_false(any(CHANGES$name == "93 X 95 NV"))
  q <- ref("classification_review_queue.csv")
  expect_true("NV_UNIDENTIFIED_RECIPIENT" %in% q$question_id)
})


# -- Iowa's Centers of Excellence ---------------------------------------------

test_that("Sioux Center Health is a hospital and the COE pool is hospital-only", {
  ia <- ref("ia_year1_awardees.csv")
  sc <- ia %>% filter(awardee == "Sioux Center Health")
  expect_equal(nrow(sc), 3L)
  expect_true(all(sc$recipient_type == "HOSPITAL_OR_SYSTEM"))

  # The ten AWARD ACTIONS. (Session 50 appended a Tier 2 POOL ROW to this pool;
  # session 51 removed it, so the filter it needed is gone too.)
  coe <- ia %>% filter(award_pool == "PHTHORC26008")
  expect_equal(nrow(coe), 10L)
  expect_true(all(coe$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_true(all(coe$distributed_to_hospital == "Yes"))
  expect_true(all(is.na(coe$amount) | coe$amount == "NA"))
})

test_that("the $50,000,000 stays TIER 2 and reaches no award row", {
  # The pool is hospital-only; that is a statement about WHO, not a dollar.
  # $50,000,000 / 10 = $5,000,000 is nobody's published figure (§6.2), and the
  # figure is the notice's CMS footer, which is Tier 2 (§0.2).
  f <- ref("ia_notice_footers.csv") %>% filter(rfp == "PHTHORC26008")
  expect_equal(f$footer_amount, "50000000")
  expect_equal(f$footer_tier, "SOLICITATION")
  ia <- ref("ia_year1_awardees.csv")
  expect_false("round_amount" %in% names(ia))
  # Session 50 put that figure on a pool row; session 51 took it back out, so
  # it reaches NO row of the award file at all, which is this test's original
  # claim restored to its original strength.
  expect_false(any(grepl("AMOUNT_IS_POOL_NOT_AWARD", ia$flag_reason)))
  expect_true(all(is.na(ia$amount) | ia$amount == "NA"))
})


# -- what moved ---------------------------------------------------------------

test_that("the net move is 118 rows and $107,259,781.21", {
  into <- CHANGES %>% filter(bucket_before == "NOT_HOSPITAL",
                             !bucket_after %in% c("NOT_HOSPITAL", "NO_BUCKET"))
  outof <- CHANGES %>% filter(!bucket_before %in% c("NOT_HOSPITAL", "NO_BUCKET"),
                              bucket_after == "NOT_HOSPITAL")
  expect_equal(nrow(into), 120L)
  expect_equal(nrow(outof), 2L)
  expect_equal(round(sum(as.numeric(into$amount), na.rm = TRUE), 2), 110294573.21)
  expect_equal(sum(as.numeric(outof$amount), na.rm = TRUE), 3034792)
  expect_true(all(outof$state == "MD"))
})

test_that("the three buckets are what SESSION 51 publishes, and what session 49 added is still inside them", {
  # SESSION 49'S OWN FIGURES WERE 865 rows / $706,793,190.35 / 19 states, with
  # BOTH pool buckets unmoved. Session 50 typed Mississippi's and South
  # Carolina's unstated-form rows (+74 rows / +$80,696,969.67) and gave Iowa's
  # Centers of Excellence pool a POOL_NAMED_HOSPITALS row ($50,000,000, TIER
  # 2), which session 51 removed. The session-49 contribution is checked by SUBTRACTION below rather than
  # deleted, so this test still says what it was written to say.
  p <- vq_partition()
  t <- vq_bucket_totals(p)
  named <- t %>% filter(bucket == "NAMED_HOSPITAL")
  # Session 52 added New York (35 rows / $47,358,790.79, a 20th state) and
  # Kansas's Emerging Technology pool (7 rows / $10,176,973) -- subtracted
  # below, as sessions 50's were, so the older figures are still checked.
  # Session 53: + Self Regional Healthcare (Greenwood Pediatrics), 1 row /
  # $145,000, re-typed under §0.3a -- subtracted below with session 52's.
  # Session 54: + Vermont (27 / $22,641,819.43), Connecticut (2 /
  # $33,350,000), West Virginia (2 / $1,224,000) and Missouri's 20 unpriced
  # SMRP hospitals ($0) -- 51 rows / $57,215,819.43 and four states,
  # subtracted first so every older figure is still checked.
  # Session 59: + Tennessee's 2 UNPRICED hospital rows and 1 state, $0 --
  # subtracted first, like every session before it.
  # Session 61: + New Jersey, 35 rows / $35,275,076 and a 26th state --
  # subtracted first, like every session before it.
  expect_equal(named$rows, 1070L)
  expect_equal(round(named$dollars, 2), 937661818.75, tolerance = 0)
  expect_equal(named$states, 26L)
  named$rows <- named$rows - 35L
  named$dollars <- named$dollars - 35275076
  named$states <- named$states - 1L
  expect_equal(named$rows, 1035L)
  expect_equal(round(named$dollars, 2), 902386742.75, tolerance = 0)
  expect_equal(named$states, 25L)
  named$rows <- named$rows - 2L
  named$states <- named$states - 1L
  expect_equal(named$rows, 1033L)
  expect_equal(named$states, 24L)
  expect_equal(round(named$dollars - 57215819.43, 2), 845170923.32, tolerance = 0)
  named$rows <- named$rows - 51L
  named$dollars <- named$dollars - 57215819.43
  expect_equal(named$rows - 42L - 1L, 939L)
  expect_equal(round(named$dollars - 57535763.79 - 145000, 2), 787490159.53, tolerance = 0)
  expect_equal(named$rows - 42L - 1L - 74L, 865L)
  expect_equal(round(named$dollars - 57535763.79 - 145000 - 80696969.67, 2),
               706793189.86, tolerance = 0)

  expect_equal(t$dollars[t$bucket == "POOL_UNNAMED_HOSPITALS"], 50008264)
  # POOL_NAMED_HOSPITALS is Nebraska alone again (session 51) -- one Tier 3
  # award -- and did NOT gain anything from session 49.
  # Session 54: + Connecticut's unsplit Hartford HealthCare pair, $12,650,000,
  # a Tier 3 executed-award figure (so the bucket still does not mix tiers).
  expect_equal(round(t$dollars[t$bucket == "POOL_NAMED_HOSPITALS"], 2), 30806856.12)
  expect_equal(t$rows[t$bucket == "POOL_NAMED_HOSPITALS"], 2L)
  ne <- p %>% filter(bucket == "POOL_NAMED_HOSPITALS", state == "NE")
  expect_equal(ne$dollars, 18156856.12)
})

test_that("North Carolina enters the partition for the first time", {
  p <- vq_partition()
  nc <- p %>% filter(state == "NC")
  expect_equal(nrow(nc), 1L)
  expect_equal(nc$bucket, "NAMED_HOSPITAL")
  expect_equal(nc$rows, 1L)
  expect_equal(nc$dollars, 0)     # North Carolina prices nobody
})

test_that("session 49 took Arkansas past Georgia, and session 50 took South Carolina past Arkansas", {
  p <- vq_partition() %>% filter(bucket == "NAMED_HOSPITAL") %>%
    arrange(desc(dollars))
  # THE SESSION-49 CLAIM, UNCHANGED WHERE IT STILL APPLIES: Arkansas's
  # $92,405,913.96 is what the returned workbook produced and it is still ahead
  # of Georgia, which is the comparison that session made.
  expect_equal(round(p$dollars[p$state == "AR"], 2), 92405913.96)
  expect_gt(p$dollars[p$state == "AR"], p$dollars[p$state == "GA"])
  # And South Carolina is now ahead of both, on session 50's typing pass.
  expect_equal(p$state[[1]], "SC")
  expect_equal(round(p$dollars[[1]], 2), 115985714.95)  # + $145,000, session 53
  expect_equal(p$state[[2]], "AR")
  expect_equal(p$state[[3]], "GA")
})

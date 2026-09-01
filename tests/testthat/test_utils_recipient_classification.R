# test_utils_recipient_classification.R --------------------------------------
# The §8 recipient_type and §10.2 flow rules. Reads committed files off disk
# only -- no network, no quota.
#
# These rules decide which dollars land in "funds distributed to hospitals",
# which is the project's answer. The tests below pin the two directions that
# get it wrong: a hospital coded as something else (the answer shrinks), and a
# non-hospital coded as a hospital (the answer inflates and is attackable, which
# §0.3 names as the single most likely failure).

library(testthat)

source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_config.R"))


# -- The rule tables are well formed -----------------------------------------

test_that("every rule table value is inside the 8 vocabulary", {
  allowed_type <- rhtp_vocabulary("recipient_type")
  allowed_conf <- rhtp_vocabulary("determination_confidence")

  expect_equal(setdiff(RHTP_RECIPIENT_TYPE_PATTERNS$recipient_type, allowed_type),
               character(0))
  expect_equal(setdiff(RHTP_RECIPIENT_TYPE_OVERRIDES$recipient_type, allowed_type),
               character(0))
  expect_equal(setdiff(RHTP_ORG_TYPE_TO_RECIPIENT_TYPE$recipient_type, allowed_type),
               character(0))
  expect_equal(setdiff(RHTP_RECIPIENT_TYPE_PATTERNS$confidence, allowed_conf),
               character(0))
  expect_equal(setdiff(RHTP_RECIPIENT_TYPE_OVERRIDES$confidence, allowed_conf),
               character(0))
})

test_that("every override carries a stated reason", {
  # An override without a reason is a guess with extra steps.
  expect_true(all(nzchar(RHTP_RECIPIENT_TYPE_OVERRIDES$why)))
  expect_true(all(nzchar(RHTP_RECIPIENT_TYPE_PATTERNS$why)))
})

test_that("no state has two override rows for one name", {
  key <- paste(RHTP_RECIPIENT_TYPE_OVERRIDES$state,
               RHTP_RECIPIENT_TYPE_OVERRIDES$awardee, sep = "|")
  expect_equal(sum(duplicated(key)), 0L)
})


# -- The DBA rule, which is the one that moves money -------------------------

test_that("a DBA that names a hospital makes the recipient a hospital", {
  # Each of these would otherwise code as a city, a board, or a management
  # company -- and each is a hospital that would drop out of the answer.
  cases <- c(
    "The City of York Health Care Authority DBA Hill Hospital of Sumter County",
    "Wilcox Hospital Board DBA J. Paul Jones Rural Emergency Hospital",
    "Tombigbee Healthcare Authority DBA Whitfield Regional Hospital",
    "Triad of Alabama DBA Flowers Hospital",
    "Affinity Hospital DBA Grandview Medical Center"
  )
  out <- rhtp_classify_recipient_type(cases, "AL")
  expect_equal(out$recipient_type, rep("HOSPITAL_OR_SYSTEM", length(cases)))
})

test_that("the four UAB St. Vincent's hospitals are hospitals, not a university", {
  # The name carries the initialism, not the word, so the university pattern
  # would take four hospitals out of the hospital total. Curated overrides.
  cases <- c("UAB St. Vincent’s Blount", "UAB St. Vincent’s Chilton",
             "UAB St. Vincent’s Chilton LLC", "UAB St. Vincent’s St. Clair")
  out <- rhtp_classify_recipient_type(cases, "AL")
  expect_equal(out$recipient_type, rep("HOSPITAL_OR_SYSTEM", 4L))
  expect_equal(out$rule, rep("OVERRIDE", 4L))
})


# -- The inflation direction, which is the attackable one --------------------

test_that("bare 'Center' never reads as a hospital", {
  # `Medical Center` is a hospital marker and bare `Center` deliberately is not.
  # All three of these are in the real data and none is a hospital.
  cases <- c("Center for Behavioral Health-PA, LLC dba Cranberry Township Comprehensive Treatment Center",
             "Nulton Diagnostic and Treatment Center, P.C dba NDTC",
             "The Guidance Center")
  out <- rhtp_classify_recipient_type(cases, "PA")
  expect_false(any(out$recipient_type == "HOSPITAL_OR_SYSTEM"))
})

test_that("a behavioral-health provider named '... Health Systems' is not a hospital system", {
  # The pattern list reads "Health Systems" as a hospital system, which is
  # right for Huntsville Hospital Health System and wrong for AltaPointe. The
  # override is what keeps §0.3 from being violated on the strength of a word.
  out <- rhtp_classify_recipient_type(
    c("AltaPointe Health Systems",
      "Southwest Alabama Behavioral Health Care Systems DBA CarePath Behavioral Health"),
    "AL")
  expect_false(any(out$recipient_type == "HOSPITAL_OR_SYSTEM"))
  expect_equal(out$rule, c("OVERRIDE", "OVERRIDE"))

  # And the pattern still does its job where the name means it.
  hosp <- rhtp_classify_recipient_type("Huntsville Hospital Health System", "AL")
  expect_equal(hosp$recipient_type, "HOSPITAL_OR_SYSTEM")
})

test_that("nursing and rehabilitation operators carrying 'Healthcare' are not hospitals", {
  cases <- c(
    "Weatherwood Rehabilitation and Healthcare LLC dba Forrest Hills Rehabilitation & Healthcare Center",
    "Transitions Healthcare Gettysburg, LLC",
    "Wyoming County Healthcare Center II dba Wyoming County Healthcare Center"
  )
  out <- rhtp_classify_recipient_type(cases, "PA")
  expect_false(any(out$recipient_type == "HOSPITAL_OR_SYSTEM"))
})


# -- The settled 8 fallback --------------------------------------------------

test_that("a named recipient with no determinable form takes the settled fallback", {
  out <- rhtp_classify_recipient_type("Zzz Widget Cooperative", "PA")
  expect_equal(out$recipient_type, "NONPROFIT_CBO")
  expect_equal(out$determination_confidence, "LOW")
  expect_equal(out$rule, "FALLBACK")
})


# -- The state's own organisation-type field ---------------------------------

test_that("the state's own form token decides, and a service line does not", {
  out <- rhtp_recipient_type_from_org_type(c(
    "Family medicine or primary care; Non-Profit, Social Service, or Community Based Organization",
    "Hospital (all types); Behavioral health/substance use disorder treatment",
    "Clinic; Maternal health"
  ))
  expect_equal(out$recipient_type,
               c("NONPROFIT_CBO", "HOSPITAL_OR_SYSTEM", "NONPROFIT_CBO"))
  # A field carrying only service lines is the settled fallback, not an
  # invented form.
  expect_equal(out$rule[3], "FALLBACK")
  expect_equal(out$determination_confidence[3], "LOW")
})

test_that("hospital beats tribal when the state says both", {
  # Deliberate precedence: a tribal health organisation that operates a hospital
  # and receives the money is a hospital recipient for this project's question,
  # and Alaska says both on several rows.
  out <- rhtp_recipient_type_from_org_type(
    "Tribal Health Organization; Hospital (all types)")
  expect_equal(out$recipient_type, "HOSPITAL_OR_SYSTEM")
})

test_that("an unrecognised organisation-type token refuses rather than guessing", {
  expect_error(
    rhtp_recipient_type_from_org_type("Interdimensional Health Cooperative"),
    "unrecognised organisation-type token"
  )
})


# -- 10.2 flow ---------------------------------------------------------------

test_that("only a hospital recipient reaches DIRECT / Yes", {
  # The title was always the intent; HOSPITAL_AFFILIATED_ENTITY used to be
  # counted as "a hospital recipient" and now is not, because an affiliated
  # entity is not the hospital 10.2's DIRECT row tests for. A CT scanner
  # replacement says nothing about where the money goes, so the affiliated
  # entity is Unclear -- neither imputed to Yes nor deflated to No.
  out <- rhtp_classify_flow(
    c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY", "FQHC_OR_RHC",
      "UNIVERSITY_OR_AHC", "STATE_AGENCY"),
    rep("replace a CT scanner", 5L))
  expect_equal(out$distributed_to_hospital,
               c("Yes", "Unclear", "No", "No", "No"))
  expect_equal(out$flow_type[1], "DIRECT")
  expect_false(any(out$flow_type[-1] == "DIRECT"))
})

test_that("0.3a: the activity never decides, only the recipient", {
  # The worked case the spec argues from. Same setting, different recipients,
  # different codes.
  school <- "school-based health center construction"
  agency <- rhtp_classify_flow("STATE_AGENCY", school)
  hospital <- rhtp_classify_flow("HOSPITAL_OR_SYSTEM", school)
  expect_equal(agency$distributed_to_hospital, "No")
  expect_equal(hospital$distributed_to_hospital, "Yes")
})

test_that("unnamed hospital subrecipients are Unclear and are never imputed", {
  # §0.3 still holds, and this is what it now takes to reach it: the source has
  # to say MONEY moves to hospitals it does not name, not merely that the work
  # HAPPENS at them. The old fixture here was Alabama's Cahaba sentence
  # ("training capacity AT FOUR ALABAMA HOSPITALS"), which is §10.2's
  # IN_KIND_BENEFIT -- the recipient keeps the money and delivers the training
  # -- and session 31 moved it. The case below is the real thing.
  out <- rhtp_classify_flow(
    "FQHC_OR_RHC",
    "subaward the funds to rural hospitals across the region, to be named later")
  expect_equal(out$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(out$distributed_to_hospital, "Unclear")
  expect_equal(out$flow_flag, "ELIGIBILITY_NOT_RECEIPT")

  # And the contrast that makes the distinction real, in one assertion: same
  # recipient type, same hospitals, and the only difference is whether the
  # sentence moves a dollar or describes a place.
  at_them <- rhtp_classify_flow(
    "FQHC_OR_RHC",
    "establish rural obstetric training capacity at four Alabama hospitals")
  expect_equal(at_them$flow_type, "IN_KIND_BENEFIT")
  expect_equal(at_them$distributed_to_hospital, "No")
  expect_equal(at_them$hospital_benefiting, "Yes")
})

test_that("hospitals mentioned by a non-hospital recipient are in-kind, not silence", {
  # The rule this replaced was a list of phrasings and it under-fired on both
  # of these, coding them NON_HOSPITAL -- which says the source is silent about
  # hospitals when it is the opposite. No total moves either way; what moves is
  # whether the dollars stay visible.
  out <- rhtp_classify_flow(
    rep("NONPROFIT_CBO", 2L),
    c("a statewide AI imaging network across 21 acute care hospitals",
      "assessments for three independent Critical Access Hospitals"))
  expect_equal(out$flow_type, rep("IN_KIND_BENEFIT", 2L))
  expect_equal(out$distributed_to_hospital, rep("No", 2L))
  expect_equal(out$hospital_benefiting, rep("Yes", 2L))
})

test_that("silence about hospitals is NON_HOSPITAL", {
  out <- rhtp_classify_flow("SCHOOL_OR_DISTRICT",
                            "modernize school kitchen equipment")
  expect_equal(out$flow_type, "NON_HOSPITAL")
  expect_equal(out$distributed_to_hospital, "No")
  expect_equal(out$hospital_benefiting, "No")
})

test_that("an in-kind row can never carry distributed_to_hospital = Yes", {
  # 10.2's whole point: these dollars matter to AHA's narrative and must never
  # enter a distributed total.
  out <- rhtp_classify_flow(rep("VENDOR_OR_CONTRACTOR", 3L),
                            c("serving 10 rural hospitals",
                              "a network connecting hospitals",
                              "software rural hospitals use"))
  expect_true(all(out$distributed_to_hospital == "No"))
})


# -- §10.2 hospital trade associations and hospital-governed entities --------
# Added session 18 with the §10.2 row. The branch is the only one in this file
# that can move dollars INTO the hospital total, so it is tested from both
# sides: it must fire on the two sources the spec quotes, and it must NOT fire
# on the three association awards that read most like hospital money and are
# not.

test_that("the association branch never fires without an executed award", {
  icahn <- paste("ICAHN will administer the funds to Critical Access Hospitals",
                 "and other eligible non-urban Illinois hospitals in federally",
                 "designated rural ZIP codes.")

  # The default. Every committed state extractor calls the two-argument form,
  # which is why adding this row moved no row in any state file.
  default <- rhtp_classify_flow("NONPROFIT_CBO", icahn)
  expect_false(default$flow_type == "PASS_THROUGH_DESIGNATED")
  expect_false(default$distributed_to_hospital == "Yes")

  expect_equal(
    rhtp_classify_flow("NONPROFIT_CBO", icahn, award_made = FALSE)$flow_type,
    default$flow_type
  )
})

test_that("the association branch fires on both quoted worked examples", {
  positives <- c(
    icahn = paste("ICAHN will administer the funds to Critical Access Hospitals",
                  "and other eligible non-urban Illinois hospitals."),
    oha   = paste("Implementation will be conducted by hospitals reimbursed for",
                  "CHW hiring, training, and monitoring.")
  )
  out <- rhtp_classify_flow(rep("NONPROFIT_CBO", 2), positives, award_made = TRUE)

  expect_equal(out$flow_type, rep("PASS_THROUGH_DESIGNATED", 2))
  expect_equal(out$distributed_to_hospital, rep("Yes", 2))
  expect_equal(out$hospital_benefiting, rep("Yes", 2))
  expect_true(all(grepl("intermediary_name", out$flow_basis, fixed = TRUE)))
  expect_true(all(grepl("POOL_UNNAMED_HOSPITALS", out$flow_basis, fixed = TRUE)))
})

test_that("it does not fire where the association keeps the money", {
  # These three are the audit's whole point. Each is a hospital association
  # award; none of them is hospital money; the middle one NAMES three hospitals
  # and is still in-kind, because AHHA performs the assessments.
  negatives <- c(
    gha_carts = paste("The Georgia Hospital Association received a grant to support",
                      "Strengthening Perinatal Systems of Care to provide obstetrical",
                      "emergency carts and support evidence-based patient safety",
                      "practices to improve readiness for maternal emergencies."),
    ahha_sfoa = paste("AHHA proposes Strategic, Financial, and Operational Assessments",
                      "(SFOAs) for three independent Critical Access Hospitals -",
                      "Petersburg Medical Center, Cordova Community Medical Center, and",
                      "South Peninsula Hospital - plus implementation assistance for",
                      "Rural Health Clinic (RHC) designation for those four facilities."),
    ahha_fyf  = paste("Developed in partnership with Alaska's 24 hospitals, 20 skilled",
                      "nursing facilities, and tribal health system, this coordinated",
                      "statewide initiative builds a robust grow-our-own pipeline."),
    ahha_awfc = paste("AHHA proposes to incubate the Alaska Nursing Workforce Center,",
                      "a hub for nursing workforce data, research, and strategic planning.")
  )

  # award_made = TRUE is the hostile setting: even told the award is executed,
  # the branch must decline all four.
  out <- rhtp_classify_flow(rep("NONPROFIT_CBO", length(negatives)), negatives,
                            award_made = TRUE)

  expect_false(any(out$flow_type == "PASS_THROUGH_DESIGNATED"))
  expect_false(any(out$distributed_to_hospital == "Yes"))

  # And they keep the codes §10.2 already had for them: hospitals mentioned in
  # the funded work is IN_KIND_BENEFIT, silence about hospitals is NON_HOSPITAL.
  expect_equal(unname(out$flow_type[1:3]), rep("IN_KIND_BENEFIT", 3))
  expect_equal(unname(out$flow_type[4]), "NON_HOSPITAL")
})

test_that("the pass-through marker is a MONEY-MOVEMENT test, not a location test", {
  # SESSION 31, AND THE POSITIVE CONTROL IS THE SPEC'S OWN WORKED NEGATIVE.
  # RHTP_PASS_THROUGH_MARKERS used to carry two POSITIONAL patterns --
  # "at (four|...|\\d+) [a-z ]*hospitals" and "to (rural )?...hospitals" --
  # which match where a SERVICE lands, not where a DOLLAR goes.
  #
  # Georgia's own committed note on the Georgia Hospital Association is the
  # case: "GHA receives the grant and supplies obstetrical emergency carts TO
  # HOSPITALS. Equipment reaches hospitals, dollars do not." That is §10.2's
  # textbook IN_KIND_BENEFIT -- the very row the association branch exists to
  # exclude -- and the old marker fired on it. Meanwhile Alaska's AHHA
  # assessments "FOR three ... Critical Access Hospitals" correctly fell
  # through. The old rule separated the spec's two worked negatives BY THEIR
  # PREPOSITION.
  gha_note <- paste("GHA receives the grant and supplies obstetrical emergency",
                    "carts to hospitals. Equipment reaches hospitals, dollars",
                    "do not: §10.2 in-kind, hospital_benefiting = Yes.")
  expect_false(stringr::str_detect(stringr::str_to_lower(gha_note),
                                   RHTP_PASS_THROUGH_MARKERS))
  out <- rhtp_classify_flow("HOSPITAL_AFFILIATED_ENTITY", gha_note)
  expect_equal(out$flow_type, "IN_KIND_BENEFIT")
  expect_equal(out$distributed_to_hospital, "No")

  # The two committed rows the old marker mis-labelled, in their sources' own
  # words. Both recipients KEEP the money and deliver a service.
  keeps_the_money <- c(
    al_cahaba = paste("A second grant totaling $430,304 will establish rural",
                      "obstetric training capacity at four Alabama hospitals to",
                      "strengthen the pipeline of physicians prepared to provide",
                      "maternity care in four counties."),
    ks_salina = paste("Five founding providers will form AstraHealth Kansas, a",
                      "shared services organization providing back-office and",
                      "clinical infrastructure to rural hospitals across Kansas.")
  )
  low <- stringr::str_to_lower(keeps_the_money)
  expect_false(any(stringr::str_detect(low, RHTP_PASS_THROUGH_MARKERS)))
  moved <- rhtp_classify_flow(rep("NONPROFIT_CBO", 2), keeps_the_money)
  expect_equal(unname(moved$flow_type), rep("IN_KIND_BENEFIT", 2))
  expect_equal(unname(moved$distributed_to_hospital), rep("No", 2))

  # AND IT STILL FIRES WHERE MONEY ACTUALLY MOVES. These are §10.2's own two
  # worked POSITIVES plus the structural mechanisms, and a marker that stopped
  # catching them would be a deflation, not a tightening.
  money_moves <- c(
    icahn    = paste("ICAHN will administer the funds to Critical Access",
                     "Hospitals and other eligible non-urban Illinois hospitals."),
    oha_chw  = paste("Implementation will be conducted by hospitals reimbursed",
                     "for CHW hiring, training, and monitoring."),
    subaward = "The intermediary will subaward to rural hospitals in the region.",
    apply    = paste("Type 2 ambulances which select rural hospitals will be",
                     "eligible to apply for soon.")
  )
  expect_true(all(stringr::str_detect(
    stringr::str_to_lower(money_moves[c("icahn", "oha_chw", "subaward")]),
    RHTP_PASS_THROUGH_MARKERS)))
  # Session 18's clause, unchanged: hospitals applying for or receiving the
  # money IS the money reaching the hospital, and it is what keeps Georgia's
  # Type 2 ambulances coded §0.3 eligibility-not-receipt rather than silence.
  expect_true(stringr::str_detect(
    stringr::str_to_lower("Select rural hospitals will be able to apply for these funds."),
    RHTP_PASS_THROUGH_MARKERS))
})

test_that("both branches share ONE money-movement definition", {
  # The generic pass-through branch and §10.2's association branch used to
  # disagree about what counts as money moving -- the association row was a
  # money test and the generic one was not. They now read the same definition,
  # so a phrasing added for one can never be missing from the other. What
  # still separates them is §10.2's SECOND clause (award_made) and the code
  # each returns, which is the distinction the spec actually draws.
  expect_identical(RHTP_ASSOCIATION_ADMINISTERED_MARKERS,
                   RHTP_MONEY_TO_HOSPITALS_MARKERS)
  expect_true(grepl(RHTP_MONEY_TO_HOSPITALS_MARKERS, RHTP_PASS_THROUGH_MARKERS,
                    fixed = TRUE))

  # Same sentence, both settings: only `award_made` moves it, and only it can
  # put dollars INTO a hospital bucket.
  s <- "ICAHN will administer the funds to eligible non-urban Illinois hospitals."
  expect_equal(rhtp_classify_flow("NONPROFIT_CBO", s, award_made = TRUE)$flow_type,
               "PASS_THROUGH_DESIGNATED")
  expect_equal(rhtp_classify_flow("NONPROFIT_CBO", s, award_made = FALSE)$flow_type,
               "PASS_THROUGH_UNRESOLVED")
  expect_equal(rhtp_classify_flow("NONPROFIT_CBO", s, award_made = FALSE)$distributed_to_hospital,
               "Unclear")
})

test_that("the administered-funds markers never match across a full stop", {
  # Session 13's rule. A pattern allowed to span sentences joins an award verb
  # in one sentence to 'hospitals' in the next and invents a flow.
  split <- paste("The association will administer the funds under its own",
                 "operating budget. Rural hospitals are described elsewhere in",
                 "the plan.")
  out <- rhtp_classify_flow("NONPROFIT_CBO", split, award_made = TRUE)
  expect_false(out$flow_type == "PASS_THROUGH_DESIGNATED")
})

test_that("HOSPITAL_AFFILIATED_ENTITY no longer short-circuits to DIRECT", {
  # THE FIX. This type used to return DIRECT + Yes before a word of the source
  # was read, which let recipient_type pre-decide flow and skipped the §10.2
  # test entirely. §10.2's DIRECT row tests recipient IDENTITY -- "named
  # recipient matches a hospital in AHA/POS" -- and an affiliated entity is by
  # construction not that hospital. It now reads the description like every
  # other non-hospital type.
  #
  # The Georgia Hospital Association is the case that shows what the old
  # behaviour cost. Same recipient_type, same real DCH sentence, and the answer
  # flips from "Yes, count these dollars as hospital money" to Georgia's own
  # hand coding.
  carts <- paste("The Georgia Hospital Association received a grant to support",
                 "Strengthening Perinatal Systems of Care to provide obstetrical",
                 "emergency carts and support evidence-based patient safety",
                 "practices to improve readiness for maternal emergencies.")
  out <- rhtp_classify_flow("HOSPITAL_AFFILIATED_ENTITY", carts, award_made = TRUE)
  expect_equal(out$flow_type, "IN_KIND_BENEFIT")
  expect_equal(out$distributed_to_hospital, "No")

  # No branch reachable by this type returns DIRECT any more -- not even when
  # the source is silent about hospitals, and not on the hostile award_made
  # setting.
  probes <- c(silent    = "A leadership development programme for member staff.",
              in_kind   = "Simulation training kits delivered across the state's hospitals.",
              designated= "The association will administer the funds to member hospitals.")
  both <- rbind(rhtp_classify_flow(rep("HOSPITAL_AFFILIATED_ENTITY", 3), probes,
                                   award_made = TRUE),
                rhtp_classify_flow(rep("HOSPITAL_AFFILIATED_ENTITY", 3), probes,
                                   award_made = FALSE))
  expect_false(any(both$flow_type == "DIRECT"))

  # HOSPITAL_OR_SYSTEM keeps the short-circuit, and that is correct: for a
  # recipient that IS a hospital, recipient identity is the §10.2 test.
  hos <- rhtp_classify_flow("HOSPITAL_OR_SYSTEM", probes[["in_kind"]])
  expect_equal(hos$flow_type, "DIRECT")
  expect_equal(hos$distributed_to_hospital, "Yes")
})

test_that("a silent source leaves an affiliated entity Unclear, never No", {
  # Silence is evidence for a school district or a vendor: NON_HOSPITAL. It is
  # not evidence for a hospital-governed entity, where the money may well reach
  # hospitals and the document has simply not said. Coding that No would
  # deflate on this pipeline's authority; coding it Yes is the short-circuit
  # that was just removed. §0.4 -- no quotable sentence, no determination.
  silent <- "A leadership development programme for member staff."
  aff <- rhtp_classify_flow("HOSPITAL_AFFILIATED_ENTITY", silent)
  expect_equal(aff$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(aff$distributed_to_hospital, "Unclear")
  expect_equal(aff$flow_flag, "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED")

  # The same silence on a plainly non-hospital recipient is unchanged.
  other <- rhtp_classify_flow("SCHOOL_OR_DISTRICT", silent)
  expect_equal(other$flow_type, "NON_HOSPITAL")
  expect_equal(other$distributed_to_hospital, "No")

  # And the flag is in the §8 vocabulary, not invented at the call site.
  expect_true("FLOW_UNRESOLVED_HOSPITAL_AFFILIATED" %in% rhtp_vocabulary("flag_reason"))
})

test_that("the association branch admits both types while GHA is unsettled", {
  # §10.2's row prescribes NONPROFIT_CBO; Georgia types the same kind of entity
  # HOSPITAL_AFFILIATED_ENTITY. Until a human settles which is right, one
  # organisation must not get two different flows depending on which state's
  # extractor typed it.
  administered <- "The association will administer the funds to member hospitals."
  for (rt in c("NONPROFIT_CBO", "HOSPITAL_AFFILIATED_ENTITY")) {
    out <- rhtp_classify_flow(rt, administered, award_made = TRUE)
    expect_equal(out$flow_type, "PASS_THROUGH_DESIGNATED")
    expect_equal(out$distributed_to_hospital, "Yes")
  }
  # Still opt-in: admitting a second type cannot move a row on its own.
  expect_false(
    rhtp_classify_flow("HOSPITAL_AFFILIATED_ENTITY", administered)$flow_type ==
      "PASS_THROUGH_DESIGNATED"
  )
})

test_that("Georgia's GHA recipient_type divergence is recorded, not resolved", {
  # DELIBERATELY UNCHANGED. The flow half of the session 18 divergence is fixed
  # above -- the shared function and Georgia now agree that GHA is
  # IN_KIND_BENEFIT + No. The recipient_type half is NOT this session's to
  # settle: is a hospital trade association NONPROFIT_CBO (§10.2's row, and what
  # AK and IL use) or HOSPITAL_AFFILIATED_ENTITY (Georgia)? Re-coding a
  # committed hand-coded row to satisfy a rule changed the same day is how §2.1's
  # regressions happen. The row is in the verification queue for a human; this
  # assertion pins what it says today so the queue entry cannot go stale.
  ga <- readr::read_csv(here::here("data/reference/ga_great_health_awards.csv"),
                        show_col_types = FALSE, progress = FALSE)
  gha <- ga[ga$awardee == "Georgia Hospital Association", ]
  expect_equal(nrow(gha), 1L)
  expect_equal(gha$recipient_type[[1]], "HOSPITAL_AFFILIATED_ENTITY")
  expect_equal(gha$flow_type[[1]], "IN_KIND_BENEFIT")
  expect_equal(gha$distributed_to_hospital[[1]], "No")

  queue <- readr::read_csv(here::here("data/reference/classification_review_queue.csv"),
                           show_col_types = FALSE, progress = FALSE)
  row <- queue[queue$question_id == "GHA_RECIPIENT_TYPE", ]
  expect_equal(nrow(row), 1L)
  expect_equal(row$queue_status[[1]], "OPEN")
  expect_equal(row$state[[1]], "GA")
  expect_true(grepl("NONPROFIT_CBO", row$options[[1]], fixed = TRUE))
  expect_true(grepl("HOSPITAL_AFFILIATED_ENTITY", row$options[[1]], fixed = TRUE))
})

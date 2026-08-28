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
  out <- rhtp_classify_flow(
    c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY", "FQHC_OR_RHC",
      "UNIVERSITY_OR_AHC", "STATE_AGENCY"),
    rep("replace a CT scanner", 5L))
  expect_equal(out$distributed_to_hospital,
               c("Yes", "Yes", "No", "No", "No"))
  expect_equal(out$flow_type[1:2], c("DIRECT", "DIRECT"))
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
  out <- rhtp_classify_flow(
    "FQHC_OR_RHC",
    "establish rural obstetric training capacity at four Alabama hospitals")
  expect_equal(out$flow_type, "PASS_THROUGH_UNRESOLVED")
  expect_equal(out$distributed_to_hospital, "Unclear")
  expect_equal(out$flow_flag, "ELIGIBILITY_NOT_RECEIPT")
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

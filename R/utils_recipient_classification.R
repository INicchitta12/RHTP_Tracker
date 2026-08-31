# utils_recipient_classification.R -------------------------------------------
# The §8 `recipient_type` and §10.2 flow rules, in one place.
#
# WHY THIS IS A SHARED FILE. Sessions 9-11 coded Georgia and Florida one state
# at a time, and the §8 `recipient_type` question had to be settled twice
# because the two states answered it differently (session 10). This session adds
# three more states at once. Triplicating the rules would guarantee a fourth
# answer, so the rules live here and every state extractor calls them.
#
# THE ONE RULE THAT MATTERS (§0.3a, §10.2). Judge the RECIPIENT, never the
# activity. Nebraska's school kitchen modernization awarded to the Department of
# Education is NON_HOSPITAL; Delaware's school-based health center awarded to
# Beebe Healthcare is DIRECT. Same setting, different recipients, different
# codes. Every pattern below is therefore matched against the awardee NAME (or
# the state's own organisation-type field) and never against the project
# description. The description is consulted only AFTER `recipient_type` is
# fixed, and only to separate the three non-hospital flows from each other.
#
# A DBA NAMES THE RECIPIENT TOO. "The City of York Health Care Authority DBA
# Hill Hospital of Sumter County" is a hospital, not a city. "Wilcox Hospital
# Board DBA J. Paul Jones Rural Emergency Hospital" is a hospital, not a board.
# Patterns are matched against the WHOLE string, DBA half included, so the
# hospital marker wins wherever it appears. This is the §6.1
# PROGRAM_NAME_AS_AWARDEE error running in reverse and it costs the project the
# same way: a hospital coded as a local government drops out of the answer.
#
# WHAT HAPPENS WHEN THE RULES CANNOT DECIDE. The settled convention (session 10,
# Georgia's, after Florida was back-fitted to it): a recipient that is NAMED but
# whose organisational form the source does not state is
# `NONPROFIT_CBO` + `determination_confidence = LOW` +
# `flag_reason = RECIPIENT_TYPE_INFERRED`. It is a fallback, not a finding, and
# the LOW confidence is what tells a reviewer to look. Overrides below carry a
# stated reason each; a name that needs one and does not have one falls back
# rather than being guessed at in code.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths go through here::here(). Contains no network calls.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
})


# -- recipient_type from the awardee name ------------------------------------

# Ordered. First match wins, so the most specific organisational form must come
# first. `confidence` is what the pattern alone supports: HIGH where the name
# states the form outright ("... Hospital"), MEDIUM where it is a strong but
# inferential read of the name (§7: MEDIUM is "hospital identity inferred from
# name without CCN match", which is exactly this until the AHA/POS extracts land
# and Stage 5 can match a CCN).
RHTP_RECIPIENT_TYPE_PATTERNS <- tibble::tribble(
  ~pattern,                                                                   ~recipient_type,               ~confidence, ~why,

  # Tribal first: a tribal health organisation that is NOT described as a
  # hospital is a tribal org, and the hospital rule below would otherwise never
  # see it. Where a source says BOTH (Alaska does, for several), the hospital
  # rule in rhtp_recipient_type_from_org_type() takes precedence deliberately --
  # a tribal health organisation operating a hospital and receiving the money is
  # a hospital recipient for this project's question.
  "(?i)\\b(tribal|tribe|native village|band of|indian health)\\b",            "TRIBAL_ORG",                  "HIGH",   "name states a tribal entity",

  # Hospitals. `Medical Center` is included and bare `Center` deliberately is
  # not: `Comprehensive Treatment Center`, `Nulton Diagnostic and Treatment
  # Center` and `Center for Behavioral Health` are all in this session's data
  # and none is a hospital.
  "(?i)\\bhospitals?\\b",                                                     "HOSPITAL_OR_SYSTEM",          "HIGH",   "name states a hospital",
  "(?i)\\bmedical cent(er|re)\\b",                                            "HOSPITAL_OR_SYSTEM",          "HIGH",   "name states a medical center",
  "(?i)\\bhealth(care)? systems?\\b",                                          "HOSPITAL_OR_SYSTEM",          "MEDIUM", "name states a health system",
  # Alabama incorporates its county hospitals as `... Health Care Authority` /
  # `... Healthcare Authority`; the enabling statute (Ala. Code 22-21-310 et
  # seq.) is the hospital-authority chapter. Every one of them in this data is a
  # hospital operator, several say so in their own DBA.
  "(?i)\\bhealth ?care authority\\b",                                         "HOSPITAL_OR_SYSTEM",          "MEDIUM", "Alabama hospital authority",

  # Health centres and clinics that state their federal designation.
  "(?i)\\b(federally qualified|fqhc|rural health clinic|\\brhc\\b)",          "FQHC_OR_RHC",                 "HIGH",   "name states an FQHC/RHC designation",
  "(?i)\\b(community health cent(er|re)s?|primary health (care )?cent(er|re))", "FQHC_OR_RHC",               "MEDIUM", "community/primary health center",

  # EMS and dispatch.
  "(?i)\\b(ambulance|paramedical|\\bems\\b|emergency medical services|air medical|psap)\\b", "EMS_OR_PSAP", "HIGH",   "name states an EMS entity",

  # Higher education and academic health centres.
  "(?i)\\b(universit(y|ies)|college)\\b",                                     "UNIVERSITY_OR_AHC",           "HIGH",   "name states a university or college",
  "(?i)\\barea health education cent(er|re)|\\bahec\\b",                      "AHEC",                        "HIGH",   "name states an AHEC",

  # Schools.
  "(?i)\\b(school district|board of education|department of education)\\b",   "SCHOOL_OR_DISTRICT",          "HIGH",   "name states a school system",

  # Government. The county/city public-health rule comes FIRST because the two
  # spellings of one body were landing in two different places: Maryland awards
  # EIGHT county health departments, and "Allegany County Health Department"
  # fell through every pattern to §8's NONPROFIT_CBO fallback while "Charles
  # County Department of Health" matched `department of` and came out
  # STATE_AGENCY. Neither is right and they are the same kind of recipient. A
  # county health department is a LOCAL public health body, which is the value
  # §8 has for it and the value Oregon's own Organization Type column gives its
  # equivalents.
  "(?i)\\b(count(y|ies)|city|parish|borough|township)\\b[^,;]{0,40}?\\b(health department|department of health|department of public health|public health department)\\b", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "HIGH", "county or city health department, a local public health body",
  "(?i)\\b(department of|state of|commonwealth of|division of)\\b",           "STATE_AGENCY",                "MEDIUM", "name states a state agency",
  "(?i)\\b(count(y|ies)|city|borough|township|municipal) (of |government)",   "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "name states a local government",

  # Physician and clinical practices. `PC`/`P.C.` is the professional
  # corporation suffix and is a determinable form, not the undetermined
  # fallback -- that is the distinction session 10 added PHYSICIAN_PRACTICE for.
  "(?i)(,? ?\\bp\\.?c\\.?$|,? ?\\bp\\.?c\\.? dba\\b)",                        "PHYSICIAN_PRACTICE",          "HIGH",   "professional corporation suffix",
  "(?i)\\b(pediatrics|obstetrics|gynecology|psychiatry associates|family care|family medicine|vascular specialists|nephrology)\\b", "PHYSICIAN_PRACTICE", "MEDIUM", "name states a clinical practice",

  # Vendors and technology suppliers.
  "(?i)\\b(technolog(y|ies)|informatics|software|solutions inc)\\b",          "VENDOR_OR_CONTRACTOR",        "MEDIUM", "name states a technology vendor"
)


# Per-name overrides. Every entry is a name the ordered patterns above get
# WRONG or cannot reach, with the reason stated. This is data, not code: adding
# a state adds rows here, never branches above.
#
# `state` scopes the override so two states may not silently share a name.
# `awardee` matches the recipient string EXACTLY as the source published it.
RHTP_RECIPIENT_TYPE_OVERRIDES <- tibble::tribble(
  ~state, ~awardee,                                                                 ~recipient_type,          ~confidence, ~why,

  # -- Alabama ------------------------------------------------------------
  # The UAB St. Vincent's facilities are hospitals. The bare pattern list sees
  # "UAB" only through the university rule, which would code four hospitals as
  # academic recipients and drop them out of the hospital total.
  "AL", "UAB St. Vincent’s Blount",                                            "HOSPITAL_OR_SYSTEM",     "MEDIUM", "UAB St. Vincent's Blount is a hospital; the name carries no hospital token",
  "AL", "UAB St. Vincent’s Chilton",                                           "HOSPITAL_OR_SYSTEM",     "MEDIUM", "UAB St. Vincent's Chilton is a hospital; the name carries no hospital token",
  "AL", "UAB St. Vincent’s Chilton LLC",                                       "HOSPITAL_OR_SYSTEM",     "MEDIUM", "UAB St. Vincent's Chilton is a hospital; the name carries no hospital token",
  "AL", "UAB St. Vincent’s St. Clair",                                         "HOSPITAL_OR_SYSTEM",     "MEDIUM", "UAB St. Vincent's St. Clair is a hospital; the name carries no hospital token",
  # Named for the place, not the form. The release calls this one a hospital in
  # its own prose ("This hospital has received two grants").
  "AL", "Andalusia Health",                                                         "HOSPITAL_OR_SYSTEM",     "MEDIUM", "the release's own prose calls it a hospital",
  # The release calls this one "the medical center".
  "AL", "QHG of Enterprise Inc.",                                                   "HOSPITAL_OR_SYSTEM",     "MEDIUM", "the release calls the recipient 'the medical center'",
  # Alabama's community mental health boards/authorities. Public behavioural
  # health authorities, not hospitals and not state agencies.
  "AL", "Jefferson-Blount-St. Clair Mental Health Authority",                       "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "county mental health authority, a public body",
  "AL", "Montgomery Area Mental Health Authority DBA Carastar Health",              "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "area mental health authority, a public body",
  "AL", "Mental Health Board of Chilton and Shelby Counties Inc. DBA Central Alabama Wellness", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "county mental health board, a public body",
  "AL", "East Alabama Mental Health-Mental Retardation Board, Inc. DBA Integrea Community Mental Health System", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "county mental health board; the 'System' token would otherwise read as a hospital system",
  # Training and education bodies that are not colleges.
  "AL", "Regional Training Institute",                                              "NONPROFIT_CBO",          "LOW",    "training body; organisational form not stated by the source",
  # Statewide membership associations.
  "AL", "Alabama Primary Health Care Association",                                  "NONPROFIT_CBO",          "MEDIUM", "statewide FQHC membership association, not itself a health center",
  # A DBA that names a hospital, reached by pattern; listed here only because the
  # LLC parent would otherwise read as a vendor if the patterns were reordered.
  "AL", "Floyd Healthcare Management DBA Atrium Health Floyd EMS",                  "EMS_OR_PSAP",            "HIGH",   "the DBA names the hospital's EMS division, which is the recipient",
  # Behavioural-health providers whose names carry "Health Systems". The pattern
  # list reads that as a hospital system, and for these three that would inflate
  # the hospital total on the strength of a word -- the §0.3 failure mode this
  # project exists to avoid. The release states none of their forms, so each
  # takes the settled fallback and a LOW confidence that tells a reviewer to
  # look. AltaPointe in particular does operate licensed psychiatric hospitals;
  # whether the entity that received these grants is that operator is exactly
  # what the source does not say.
  "AL", "AltaPointe Health Systems",                                                "NONPROFIT_CBO",          "LOW",    "community mental health provider; it operates psychiatric hospitals, but the release does not state which entity received the grant -- confirm before coding as a hospital",
  "AL", "AltaPointe Health Systems Inc.",                                           "NONPROFIT_CBO",          "LOW",    "community mental health provider; it operates psychiatric hospitals, but the release does not state which entity received the grant -- confirm before coding as a hospital",
  "AL", "Southwest Alabama Behavioral Health Care Systems DBA CarePath Behavioral Health", "NONPROFIT_CBO",  "MEDIUM", "community behavioral health provider; the 'Health Care Systems' token would otherwise read as a hospital system",
  # UAB's regional medical campus, not a hospital and not reachable by the
  # university pattern -- the name carries the initialism, not the word.
  "AL", "UAB Montgomery",                                                           "UNIVERSITY_OR_AHC",      "MEDIUM", "UAB's Montgomery regional medical campus; the name carries no university token",
  # Federally qualified health centers whose names do not say so.
  "AL", "Whatley Health Services Inc.",                                             "FQHC_OR_RHC",            "MEDIUM", "federally qualified health center network",
  "AL", "Rural Health Medical Program Inc.",                                        "FQHC_OR_RHC",            "MEDIUM", "federally qualified health center",
  "AL", "Cahaba Medical Care Foundation",                                           "FQHC_OR_RHC",            "MEDIUM", "federally qualified health center; one of its own awards establishes a further FQHC site",
  "AL", "Franklin Primary Health Center",                                           "FQHC_OR_RHC",            "MEDIUM", "federally qualified health center",
  # THE RELEASE PUBLISHES THIS NAME TRUNCATED. Its own markup reads
  # "<strong> Clair Community Health Clinic Inc.</strong>" -- the "St." is
  # absent from the source, not lost in the parse, and the award text places the
  # recipient in St. Clair County. §8 says keep the state's own language, so the
  # name is stored exactly as published and the observation lives here and in
  # the manifest rather than being silently corrected.
  "AL", "Clair Community Health Clinic",                                            "NONPROFIT_CBO",          "LOW",    "free clinic for uninsured rural adults in St. Clair County; the release publishes the name without its leading 'St.'",
  "AL", "Clair Community Health Clinic Inc.",                                       "NONPROFIT_CBO",          "LOW",    "free clinic for uninsured rural adults in St. Clair County; the release publishes the name without its leading 'St.'",

  # -- Pennsylvania -------------------------------------------------------
  # Skilled-nursing, personal-care and rehabilitation operators. None is a
  # hospital, and several carry `Healthcare` in the name, which must not be
  # allowed to read as one.
  "PA", "WRC Pennsylvania Memorial Home",                                           "NONPROFIT_CBO",          "MEDIUM", "continuing-care retirement community, not a hospital",
  "PA", "Somerset Care Inc dba Meadow View Nursing Center",                         "NONPROFIT_CBO",          "MEDIUM", "skilled nursing facility",
  "PA", "Quality Life Services - Mercer, LLC",                                      "NONPROFIT_CBO",          "MEDIUM", "skilled nursing facility",
  "PA", "LaFayette Manor Inc.",                                                     "NONPROFIT_CBO",          "MEDIUM", "skilled nursing facility",
  "PA", "The Lutheran Home at Kane Pennsylvania",                                   "NONPROFIT_CBO",          "MEDIUM", "skilled nursing facility",
  "PA", "Weatherwood Rehabilitation and Healthcare LLC dba Forrest Hills Rehabilitation & Healthcare Center", "NONPROFIT_CBO", "MEDIUM", "skilled nursing / rehabilitation facility",
  "PA", "Meadow View Rehabilitation and Healthcare LLC dba Meadowview Rehabilitation and Healthcare Center", "NONPROFIT_CBO", "MEDIUM", "skilled nursing / rehabilitation facility",
  "PA", "Epworth Rehabilitation and Healthcare LLC dba Cedarwood Rehabilitation & Healthcare Center", "NONPROFIT_CBO", "MEDIUM", "skilled nursing / rehabilitation facility",
  "PA", "Darway Rehabilitation and Healthcare LLC dba Darway Rehabilitation and Healthcare", "NONPROFIT_CBO", "MEDIUM", "skilled nursing / rehabilitation facility",
  "PA", "Board of Directors of the Rouse Estate dba Warren County Rouse Home",      "NONPROFIT_CBO",          "MEDIUM", "skilled nursing facility; 'County' must not read as a local government",
  "PA", "Wyoming County Healthcare Center II dba Wyoming County Healthcare Center", "NONPROFIT_CBO",          "MEDIUM", "county-affiliated skilled nursing facility, not a hospital",
  # PACE / LIFE programs -- managed long-term care, not hospitals.
  "PA", "VieCare Butler LLC dba LIFE Butler County",                                "NONPROFIT_CBO",          "MEDIUM", "LIFE (PACE) program operator",
  "PA", "VieCare Beaver LLC dba LIFE Lawrence County",                              "NONPROFIT_CBO",          "MEDIUM", "LIFE (PACE) program operator",
  "PA", "VieCare Armstrong LLC dba LIFE Armstrong County",                          "NONPROFIT_CBO",          "MEDIUM", "LIFE (PACE) program operator",
  "PA", "Transitions Healthcare Gettysburg, LLC",                                   "NONPROFIT_CBO",          "MEDIUM", "post-acute / skilled nursing operator",
  "PA", "Transitions Healthcare Allens Cove, LLC",                                  "NONPROFIT_CBO",          "MEDIUM", "post-acute / skilled nursing operator",
  # Behavioural health and opioid treatment providers.
  "PA", "Clarion Psychiatric Center",                                               "HOSPITAL_OR_SYSTEM",     "MEDIUM", "licensed psychiatric hospital",
  "PA", "Human Services Center",                                                    "NONPROFIT_CBO",          "MEDIUM", "community behavioral health provider",
  "PA", "CMSU Behavioral Health and Developmental Services",                        "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM", "Columbia-Montour-Snyder-Union joint-county behavioral health authority",
  "PA", "The Guidance Center",                                                      "NONPROFIT_CBO",          "MEDIUM", "community behavioral health provider",
  "PA", "Mainstream Counseling",                                                    "NONPROFIT_CBO",          "MEDIUM", "community behavioral health provider",
  "PA", "Counselling Services of Southeastern Erie County dba Corry Counseling of LECOM Health", "NONPROFIT_CBO", "MEDIUM", "community behavioral health provider; 'County' must not read as a local government",
  "PA", "Habit Opco, Watsontown Comprehensive Treatment CenterLLC dba",             "NONPROFIT_CBO",          "LOW",    "opioid treatment program; the published name is truncated mid-DBA",
  "PA", "Center for Behavioral Health-HA, LLC dba Lewistown Comprehensive Treatment Center", "NONPROFIT_CBO", "MEDIUM", "opioid treatment program",
  "PA", "Center for Behavioral Health-PA, LLC dba Cranberry Township Comprehensive Treatment Center", "NONPROFIT_CBO", "MEDIUM", "opioid treatment program; 'Township' must not read as a local government",
  "PA", "Center for Behavioral Health-HA, LLC dba Farrell Comprehensive Treatment Center", "NONPROFIT_CBO", "MEDIUM", "opioid treatment program",
  "PA", "Discovery House, LLC dba New Castle Comprehensive Treatment Center",       "NONPROFIT_CBO",          "MEDIUM", "opioid treatment program",
  "PA", "Discovery House CU, LLC dba Clearfield Comprehensive Treatment Center",    "NONPROFIT_CBO",          "MEDIUM", "opioid treatment program",
  "PA", "Discovery House-BC, LLC dba Duncansville Comprehensive Treatment Center",  "NONPROFIT_CBO",          "MEDIUM", "opioid treatment program",
  # Everything else PA that the patterns miss or would mis-read.
  "PA", "Jeffco Health Services, Inc.",                                             "NONPROFIT_CBO",          "LOW",    "organisational form not stated by the source",
  "PA", "Gaughn’s Drug Store Inc",                                             "VENDOR_OR_CONTRACTOR",   "MEDIUM", "retail pharmacy supplying, not receiving, hospital care",
  "PA", "Gaughn's Drug Store Inc",                                                  "VENDOR_OR_CONTRACTOR",   "MEDIUM", "retail pharmacy supplying, not receiving, hospital care",
  "PA", "Birth Care and Family Health Services, Harvest Drive Location",            "NONPROFIT_CBO",          "MEDIUM", "freestanding birth center",
  "PA", "Nulton Diagnostic and Treatment Center, P.C dba NDTC",                     "PHYSICIAN_PRACTICE",     "HIGH",   "professional corporation; the published name has no period after the C",
  "PA", "Wayne Memorial Community Health Centers",                                  "FQHC_OR_RHC",            "MEDIUM", "FQHC affiliated with Wayne Memorial Hospital",
  "PA", "Cornerstone Care, Inc. Mt Morris",                                         "FQHC_OR_RHC",            "MEDIUM", "Cornerstone Care is an FQHC network",
  "PA", "Cornerstone Care, Inc. Rogersville",                                       "FQHC_OR_RHC",            "MEDIUM", "Cornerstone Care is an FQHC network",
  "PA", "Cornerstone Care, Inc. dba Cornerstone Care Greensboro Health Center",     "FQHC_OR_RHC",            "MEDIUM", "Cornerstone Care is an FQHC network",
  "PA", "Hyndman Area Health Center, Inc.",                                         "FQHC_OR_RHC",            "MEDIUM", "federally qualified health center",
  "PA", "Wakefield Ambulance Association",                                          "EMS_OR_PSAP",            "HIGH",   "volunteer ambulance service",
  "PA", "Cameron County Ambulance Service",                                         "EMS_OR_PSAP",            "HIGH",   "county ambulance service; the EMS rule must beat the local-government rule",

  # -- South Dakota -------------------------------------------------------
  # The register prints names in upper case, so these match the portal's own
  # strings exactly. Every one of them is an administrative RHTP contract and
  # none is a hospital, so nothing here moves a distributed total -- what it
  # moves is whether Stage 5 sees a for-profit consultancy described as a
  # nonprofit, which the settled fallback would otherwise assert.
  #
  # The register itself supplies the ground: each of the five below was procured
  # through an RFP for SERVICES (its Solicitation Type reads "RFP (Linked)"),
  # and DOH's own 2026-05-21 release names North Star Solutions and Business
  # Concepts & Applications as programme-management consultants.
  "SD", "NORTH STAR SOLUTIONS LLC",                                                 "VENDOR_OR_CONTRACTOR",   "MEDIUM", "commercial consultancy engaged through an RFP for services; named as the grant-programme management consultant in DOH's own release",
  "SD", "BUSINESS CONCEPTS & APPS INC",                                             "VENDOR_OR_CONTRACTOR",   "MEDIUM", "commercial consultancy engaged through an RFP for services; named as a project-management contractor in DOH's own release",
  "SD", "GUIDEHOUSE INC",                                                           "VENDOR_OR_CONTRACTOR",   "HIGH",   "national management consultancy engaged through an RFP for services",
  "SD", "MYERS & STAUFFER LLC",                                                     "VENDOR_OR_CONTRACTOR",   "HIGH",   "actuarial and accounting firm engaged through an RFP for services",
  "SD", "HEALTH MANAGEMENT ASSOCIATES",                                             "VENDOR_OR_CONTRACTOR",   "HIGH",   "commercial health policy consultancy engaged through an RFP for services",
  # Nonprofits, named as such rather than reached by the undetermined fallback.
  "SD", "BLACK HILLS SPECIAL SERVICES",                                             "NONPROFIT_CBO",          "MEDIUM", "South Dakota education service cooperative, a nonprofit",
  "SD", "SD FOUNDATION FOR MEDICAL CARE",                                           "NONPROFIT_CBO",          "MEDIUM", "South Dakota Foundation for Medical Care, the state's nonprofit quality improvement organisation",
  "SD", "COMMUNITY HEALTH WORKER COLLAB",                                           "NONPROFIT_CBO",          "MEDIUM", "Community Health Worker Collaborative of South Dakota, a nonprofit; the register truncates the name",
  "SD", "ACTIVE GENERATION",                                                        "NONPROFIT_CBO",          "MEDIUM", "Sioux Falls nonprofit senior services centre"
)


#' Classify a recipient name into a §8 `recipient_type`
#'
#' Overrides first, then the ordered pattern table, then the settled fallback.
#' Never consults the project description (§0.3a).
#'
#' @param awardee Character vector of recipient names, exactly as published.
#' @param state_code Two-letter state code, scoping the override table.
#' @return A tibble with one row per input: `recipient_type`,
#'   `determination_confidence`, `recipient_type_basis`, and `rule` (which
#'   mechanism decided -- OVERRIDE, PATTERN or FALLBACK).
rhtp_classify_recipient_type <- function(awardee, state_code) {
  stopifnot(length(state_code) == 1L)

  overrides <- RHTP_RECIPIENT_TYPE_OVERRIDES[
    RHTP_RECIPIENT_TYPE_OVERRIDES$state == state_code, , drop = FALSE]

  purrr::map_dfr(awardee, function(name) {
    hit <- overrides[overrides$awardee == name, , drop = FALSE]
    if (nrow(hit) > 1L) {
      stop("[classify] ", state_code, " has ", nrow(hit),
           " override rows for '", name, "'; overrides must be unique.",
           call. = FALSE)
    }
    if (nrow(hit) == 1L) {
      return(tibble::tibble(
        recipient_type = hit$recipient_type,
        determination_confidence = hit$confidence,
        recipient_type_basis = paste0("Curated override: ", hit$why, "."),
        rule = "OVERRIDE"
      ))
    }

    for (i in seq_len(nrow(RHTP_RECIPIENT_TYPE_PATTERNS))) {
      p <- RHTP_RECIPIENT_TYPE_PATTERNS[i, ]
      if (stringr::str_detect(name, p$pattern)) {
        return(tibble::tibble(
          recipient_type = p$recipient_type,
          determination_confidence = p$confidence,
          recipient_type_basis = paste0("Recipient name rule: ", p$why, "."),
          rule = "PATTERN"
        ))
      }
    }

    tibble::tibble(
      recipient_type = "NONPROFIT_CBO",
      determination_confidence = "LOW",
      recipient_type_basis = paste0(
        "Recipient is named but the source does not state its organisational ",
        "form; §8 settled fallback (session 10)."
      ),
      rule = "FALLBACK"
    )
  })
}


# -- recipient_type from a state's own organisation-type field ---------------

# Alaska publishes an `Organization Type` column, semicolon-delimited and mixing
# organisational form ("Hospital (all types)") with service line ("Maternal
# health"). Only the form tokens decide. Ordered: the first token present wins.
RHTP_ORG_TYPE_TO_RECIPIENT_TYPE <- tibble::tribble(
  ~token,                                                        ~recipient_type,               ~confidence,
  "Hospital (all types)",                                        "HOSPITAL_OR_SYSTEM",          "HIGH",
  "Federally qualified health center",                           "FQHC_OR_RHC",                 "HIGH",
  "Tribe and/or Tribal Health Organization",                     "TRIBAL_ORG",                  "HIGH",
  "Tribal Health Organization",                                  "TRIBAL_ORG",                  "HIGH",
  "Tribe",                                                       "TRIBAL_ORG",                  "HIGH",
  "Emergency Medical Services",                                  "EMS_OR_PSAP",                 "HIGH",
  "University",                                                  "UNIVERSITY_OR_AHC",           "HIGH",
  "Education organization (Not public university in Alaska)",    "SCHOOL_OR_DISTRICT",          "HIGH",
  # -- Oregon (session 17). OHA publishes an `Entity type` per PROJECT in its
  # own Catalyst data file, so the state classifies its own awardees and that
  # outranks any reading of the name -- Alaska's rule, second state.
  #
  # THESE SIT ABOVE "Local government" DELIBERATELY, and the reason is a real
  # deflation this ordering prevents. Oregon's rural hospitals are organised as
  # HEALTH DISTRICTS, so Curry Health District (DBA Curry Health Network) is
  # typed "Behavioral Health Clinic, Hospital or Hospital System, Local
  # Government, ...". Appended at the end of this table instead, Alaska's
  # "Local Government" row would fire first and code an operating rural
  # hospital LOCAL_GOVT_OR_PUBLIC_HEALTH -- dropping it out of the hospital
  # total altogether. Alaska is unaffected either way: no Alaska row contains
  # an Oregon token, so where the Oregon block sits cannot change an Alaska
  # answer.
  #
  # "University" is NOT repeated here, and that is also deliberate. It already
  # sits above at row 7, so an Oregon row typed "Hospital or Hospital System,
  # University" resolves UNIVERSITY_OR_AHC rather than HOSPITAL_OR_SYSTEM.
  # Every such row in Oregon's file is an OHSU entity (the 24/7 obstetric
  # advice line, the Casey Eye Institute, the Office of Rural Health), and
  # UNIVERSITY_OR_AHC is what §8 has for an academic health centre. It is also
  # the conservative direction: it can only keep dollars OUT of the hospital
  # total, never put them in.
  "Federally Recognized Tribe",                                  "TRIBAL_ORG",                  "HIGH",
  "Hospital or Hospital System",                                 "HOSPITAL_OR_SYSTEM",          "HIGH",
  "Federally Qualified Health Center (FQHC)",                    "FQHC_OR_RHC",                 "HIGH",
  "Rural Health Clinic",                                         "FQHC_OR_RHC",                 "HIGH",
  "Emergency Medical Services (EMS)",                            "EMS_OR_PSAP",                 "HIGH",
  "Local Public Health Authority",                               "LOCAL_GOVT_OR_PUBLIC_HEALTH", "HIGH",
  "Community College",                                           "UNIVERSITY_OR_AHC",           "MEDIUM",
  "Education Service District",                                  "SCHOOL_OR_DISTRICT",          "HIGH",
  "School District",                                             "SCHOOL_OR_DISTRICT",          "HIGH",
  "State Agency",                                                "STATE_AGENCY",                "HIGH",
  "State agency",                                                "STATE_AGENCY",                "HIGH",
  "Local government",                                            "LOCAL_GOVT_OR_PUBLIC_HEALTH", "HIGH",
  "Local Government",                                            "LOCAL_GOVT_OR_PUBLIC_HEALTH", "HIGH",
  "Public Corporation",                                          "LOCAL_GOVT_OR_PUBLIC_HEALTH", "MEDIUM",
  "Organizations providing health technology solutions",         "VENDOR_OR_CONTRACTOR",        "HIGH",
  "Other vendors partnering with an Alaska healthcare or community organization", "VENDOR_OR_CONTRACTOR", "HIGH",
  "Vendor Partnering with an Alaska Organization",               "VENDOR_OR_CONTRACTOR",        "HIGH",
  "Health Information Exchange (HIE)",                           "VENDOR_OR_CONTRACTOR",        "MEDIUM",
  "Private practitioner",                                        "PHYSICIAN_PRACTICE",          "HIGH",
  "Association",                                                 "NONPROFIT_CBO",               "MEDIUM",
  "Non-Profit, Social Service, or Community Based Organization", "NONPROFIT_CBO",               "HIGH",
  # Oregon's remaining forms, all resolving to NONPROFIT_CBO. They sit BELOW
  # every form above so that a health district typed as both a hospital and a
  # nonprofit is a hospital. A Coordinated Care Organization is Oregon's
  # Medicaid managed-care entity; §8 has no health-plan code and inventing one
  # mid-session is what §2 forbids, so it takes the settled fallback at MEDIUM
  # with the state's own word recorded in `recipient_type_source`.
  "Coordinated Care Organization (CCO)",                         "NONPROFIT_CBO",               "MEDIUM",
  "Professional Association or Nonprofit Advocacy",              "NONPROFIT_CBO",               "HIGH",
  "Nonprofit or Private Health Care Organization",               "NONPROFIT_CBO",               "MEDIUM",
  "Social Service or Community-Based Organization",              "NONPROFIT_CBO",               "HIGH",
  "Coalition",                                                   "NONPROFIT_CBO",               "MEDIUM"
)

# The tokens that describe WHAT CARE IS DELIVERED rather than what the recipient
# IS. Listed explicitly so a new one appearing in a later Alaska release is not
# silently treated as a form -- rhtp_recipient_type_from_org_type() hard-fails
# on a token in neither table.
RHTP_ORG_TYPE_SERVICE_TOKENS <- c(
  "Clinic", "Family medicine or primary care",
  "Behavioral health/substance use disorder treatment", "Maternal health",
  "Pharmacy", "Home-and-community-based services provider", "Dental",
  "Specialist", "Other health care provider",
  # Oregon. "Behavioral Health Clinic" and "Dental Provider" name a service
  # line, not a form -- §8 has no clinic code other than FQHC_OR_RHC and a
  # behavioural health clinic is neither. "Other" names nothing at all. Listed
  # here so none of the three can decide a row on its own: a project typed
  # ONLY with these falls to the §8 settled fallback (NONPROFIT_CBO + LOW +
  # RECIPIENT_TYPE_INFERRED) instead of being assigned a form the state never
  # stated.
  "Behavioral Health Clinic", "Dental Provider", "Other"
)


#' Classify from a state-published organisation-type field
#'
#' The state's own classification of its own awardee outranks any reading of the
#' name (§0.1 in miniature: the state is the source of record). Where the field
#' carries only service-line tokens, this returns the §8 settled fallback rather
#' than inventing a form.
#'
#' @param org_type Character vector; semicolon-delimited tokens.
#' @param delimiter Token separator.
#' @return A tibble: `recipient_type`, `determination_confidence`,
#'   `recipient_type_basis`, `rule`.
rhtp_recipient_type_from_org_type <- function(org_type, delimiter = ";") {
  known <- c(RHTP_ORG_TYPE_TO_RECIPIENT_TYPE$token, RHTP_ORG_TYPE_SERVICE_TOKENS)

  purrr::map_dfr(org_type, function(raw) {
    tokens <- stringr::str_trim(stringr::str_split(raw %||% "", delimiter)[[1]])
    tokens <- tokens[nzchar(tokens)]

    unknown <- setdiff(tokens, known)
    if (length(unknown)) {
      stop("[classify] unrecognised organisation-type token(s): ",
           paste(sQuote(unknown), collapse = ", "),
           ". Add each to RHTP_ORG_TYPE_TO_RECIPIENT_TYPE (it names a form) or ",
           "to RHTP_ORG_TYPE_SERVICE_TOKENS (it names a service line). ",
           "Refusing to guess.", call. = FALSE)
    }

    for (i in seq_len(nrow(RHTP_ORG_TYPE_TO_RECIPIENT_TYPE))) {
      row <- RHTP_ORG_TYPE_TO_RECIPIENT_TYPE[i, ]
      if (row$token %in% tokens) {
        return(tibble::tibble(
          recipient_type = row$recipient_type,
          determination_confidence = row$confidence,
          recipient_type_basis = paste0(
            "The state's own Organization Type field states '", row$token, "'."
          ),
          rule = "STATE_ORG_TYPE"
        ))
      }
    }

    tibble::tibble(
      recipient_type = "NONPROFIT_CBO",
      determination_confidence = "LOW",
      recipient_type_basis = paste0(
        "The state's Organization Type field names only a service line (",
        paste(tokens, collapse = "; "),
        ") and no organisational form; §8 settled fallback (session 10)."
      ),
      rule = "FALLBACK"
    )
  })
}


# -- flow_type and distributed_to_hospital (§10.2) ---------------------------

# These, and ONLY these, read the project description -- after `recipient_type`
# is already fixed. They separate the three non-hospital flows from each other;
# they can never turn a non-hospital recipient into a hospital one.
#
# PASS_THROUGH markers: the money is stated to reach hospitals the source does
# not name. §0.3 and §10.2 both say do not impute -- Unclear.
RHTP_PASS_THROUGH_MARKERS <- paste(
  "at (four|five|six|seven|eight|nine|ten|\\d+|several|multiple) [a-z ]*hospitals",
  "to (rural )?(partner |member |participating )?hospitals",
  "sub-?award", "subrecipient", "pass-?through",
  "hospitals? will (be able to )?(apply|receive)",
  sep = "|"
)

# Any mention of a hospital at all. This is deliberately broad, because of what
# it is used for: once the recipient is known NOT to be a hospital, a source
# that mentions hospitals anywhere in the funded work has told us hospitals are
# involved, and §10.2 has a code for that (IN_KIND_BENEFIT) which is not the
# same as silence (NON_HOSPITAL).
#
# The earlier version of this rule was a list of specific phrasings, and it
# under-fired on real data in a way that mattered: the Alaska Stroke Coalition's
# "statewide AI imaging network across 21 acute care hospitals" and the Alaska
# Hospital & Healthcare Association's assessments for three NAMED critical
# access hospitals both read as NON_HOSPITAL, which says the source is silent
# about hospitals when it is the opposite. Nothing about the distributed total
# changes either way -- IN_KIND_BENEFIT is `No` -- but §10.2 keeps these dollars
# visible on purpose, because they matter to AHA's narrative, and a rule that
# only catches the phrasings someone thought of is a rule that loses them.
RHTP_HOSPITAL_MENTION <- "\\bhospitals?\\b|\\bcritical access\\b"


# ASSOCIATION-ADMINISTERED markers: the §10.2 hospital-association row, added in
# session 18. These fire only where the source says the MONEY moves to
# hospitals -- administered to them, subawarded to them, paid to them,
# reimbursed to them. That is the whole test, and it is deliberately narrower
# than "the recipient is a hospital association".
#
# The audit that produced the row is why. Across all nine extracted state files
# and both initiative tables, every hospital-association award already carried
# the coding §10.2 now prescribes, and the three that read most like hospital
# money are the three that must not be counted as it: the Georgia Hospital
# Association buys obstetrical carts, and the Alaska Hospital & Healthcare
# Association runs a training programme and performs assessments for three
# hospitals it NAMES. A rule keyed on the organisation would have moved all of
# them; a rule keyed on the money moves none.
#
# Matching never crosses a full stop (§13, session 13's rule): a pattern allowed
# to span sentences joins "…awards to hospitals" in one sentence to a subject in
# the next. Undermatching leaves a row where it already is, which is the safe
# direction for a rule whose only effect is to move dollars INTO the hospital
# total.
RHTP_ASSOCIATION_ADMINISTERED_MARKERS <- paste(
  "administer(s|ed|ing)?[^.]{0,60}funds?[^.]{0,60}hospitals",
  "(sub-?award(s|ed|ing)?|sub-?grant(s|ed|ing)?)[^.]{0,60}hospitals",
  "(payments?|incentive payments?|grants?|funding|funds?)[^.]{0,20}(to|for)[^.]{0,40}hospitals",
  "hospitals[^.]{0,60}reimburse",
  "reimburs[a-z]*[^.]{0,60}hospitals",
  "distribut(e|es|ed|ing)[^.]{0,60}hospitals",
  sep = "|"
)


#' Apply the §10.2 flow table
#'
#' @param recipient_type A §8 code, already determined from recipient identity.
#' @param description The source's own project description. Read for every
#'   recipient type EXCEPT `HOSPITAL_OR_SYSTEM`, and used to choose between
#'   PASS_THROUGH_DESIGNATED, PASS_THROUGH_UNRESOLVED, IN_KIND_BENEFIT and
#'   NON_HOSPITAL. It can never turn a non-hospital recipient into a hospital
#'   one -- no branch below returns DIRECT.
#' @param award_made The §10.2 hospital-association row's second clause, which
#'   no project description can answer: has the award actually been made? Pass
#'   `TRUE` per row only where the state document is an executed award. Left at
#'   its default the association branch never fires and this function behaves
#'   exactly as it did before session 18 -- which is why no committed state file
#'   moved when the row was added. `PASS_THROUGH_DESIGNATED` is the one code
#'   here that puts dollars INTO the hospital total, so it is opt-in.
#' @return A tibble: `flow_type`, `distributed_to_hospital`,
#'   `hospital_benefiting`, `flow_basis`, `flow_flag`.
rhtp_classify_flow <- function(recipient_type, description, award_made = FALSE) {
  stopifnot(length(recipient_type) == length(description))
  award_made <- rep_len(award_made %||% FALSE, length(recipient_type))

  purrr::pmap_dfr(list(recipient_type, description, award_made), function(rt, desc, made) {
    desc <- desc %||% ""

    # §10.2 DIRECT, and ONLY for a recipient that IS a hospital. The §10.2
    # test for this row is recipient identity -- "named recipient matches a
    # hospital in AHA/POS" -- so for HOSPITAL_OR_SYSTEM the recipient_type IS
    # the flow test, and there is nothing left for a description to decide.
    #
    # HOSPITAL_AFFILIATED_ENTITY IS NOT IN THIS BRANCH, AND THAT IS THE POINT.
    # It used to be, and it let recipient_type pre-decide flow: an affiliated
    # entity -- a hospital association, a hospital foundation, a hospital-owned
    # nonprofit -- is BY CONSTRUCTION not itself the hospital, so it does not
    # satisfy the DIRECT row's test, and returning Yes for it before reading a
    # word of the source skipped the §10.2 flow test entirely. Session 18
    # recorded the trap rather than fixing it; the Georgia Hospital Association
    # is the case that shows what it costs. GHA "received a grant ... to provide
    # obstetrical emergency carts": carts reach hospitals, dollars stop at GHA,
    # and Georgia hand-codes it IN_KIND_BENEFIT + No. The old short-circuit
    # returned DIRECT + Yes for that same recipient_type whatever the source
    # said, and the only thing standing between that and an inflated hospital
    # total was the accident that the Georgia extractor does not call this
    # function.
    #
    # The §10.2 test is what the document says the money DOES, not what the
    # organisation IS (session 18). An affiliated entity therefore reads the
    # description like every other non-hospital type, below.
    if (rt == "HOSPITAL_OR_SYSTEM") {
      return(tibble::tibble(
        flow_type = "DIRECT",
        distributed_to_hospital = "Yes",
        hospital_benefiting = "Yes",
        flow_basis = paste0(
          "§10.2 DIRECT: the named recipient is a hospital or hospital system ",
          "and the state's award document names both the recipient and the ",
          "amount."
        ),
        flow_flag = NA_character_
      ))
    }

    low <- stringr::str_to_lower(desc)

    # §10.2, hospital trade associations and hospital-governed entities. Both
    # clauses must hold: the source says the funds are administered to or on
    # behalf of member hospitals, AND the award has been made. The caller
    # supplies the second, because a project description cannot.
    # WHICH TYPES REACH THIS BRANCH. §10.2's row prescribes NONPROFIT_CBO for a
    # hospital association, and that is the code Alaska and Illinois already
    # use. Georgia types the same kind of entity HOSPITAL_AFFILIATED_ENTITY, and
    # which of the two is right is an open question a human has to settle -- it
    # is in `data/reference/classification_review_queue.csv`. Until it is
    # settled, BOTH types are admitted here, because the alternative is that one
    # organisation gets two different flows depending on which state's extractor
    # typed it, and preventing exactly that is why this file exists. The branch
    # is still opt-in via `award_made`, so admitting a second type cannot move a
    # row on its own.
    if (isTRUE(made) &&
        rt %in% c("NONPROFIT_CBO", "HOSPITAL_AFFILIATED_ENTITY") &&
        stringr::str_detect(low, RHTP_ASSOCIATION_ADMINISTERED_MARKERS)) {
      return(tibble::tibble(
        flow_type = "PASS_THROUGH_DESIGNATED",
        distributed_to_hospital = "Yes",
        hospital_benefiting = "Yes",
        flow_basis = paste0(
          "\u00a710.2 PASS_THROUGH_DESIGNATED (hospital trade associations and ",
          "hospital-governed entities): the recipient is not itself a hospital, ",
          "the source states the funds are administered to or on behalf of ",
          "member hospitals, and the award has been made. Populate ",
          "`intermediary_name` with the recipient. No individual hospital is ",
          "named by this rule, so `hospital_attribution` is ",
          "POOL_UNNAMED_HOSPITALS and the dollars are never added to ",
          "named-hospital dollars."
        ),
        flow_flag = NA_character_
      ))
    }

    if (stringr::str_detect(low, RHTP_PASS_THROUGH_MARKERS)) {
      return(tibble::tibble(
        flow_type = "PASS_THROUGH_UNRESOLVED",
        distributed_to_hospital = "Unclear",
        hospital_benefiting = "Yes",
        flow_basis = paste0(
          "§10.2 PASS_THROUGH_UNRESOLVED: the recipient is not a hospital, and ",
          "the source states that funds reach hospitals it does not name. §0.3 ",
          "-- eligibility is not receipt -- so this is not imputed to Yes."
        ),
        flow_flag = "ELIGIBILITY_NOT_RECEIPT"
      ))
    }

    if (stringr::str_detect(low, RHTP_HOSPITAL_MENTION)) {
      return(tibble::tibble(
        flow_type = "IN_KIND_BENEFIT",
        distributed_to_hospital = "No",
        hospital_benefiting = "Yes",
        flow_basis = paste0(
          "§10.2 IN_KIND_BENEFIT: the recipient is not a hospital and keeps the ",
          "funds, and the source names hospitals among the parties the funded ",
          "work serves. These dollars must never enter a 'funds distributed to ",
          "hospitals' total; they are kept visible rather than discarded."
        ),
        flow_flag = NA_character_
      ))
    }

    # THE TERMINAL BRANCH IS NOT THE SAME FOR AN AFFILIATED ENTITY.
    #
    # For a recipient that is plainly outside hospitals -- a school district, a
    # university, an EMS agency, a vendor -- a source silent about hospitals is
    # evidence: NON_HOSPITAL, No. That is §10.2's row, and it is the reading
    # every committed state file already relies on.
    #
    # A hospital-affiliated entity is the case where silence is NOT evidence.
    # The recipient is hospital-governed or hospital-owned, so the money may
    # well reach hospitals; the document simply has not said. Coding that `No`
    # deflates on this pipeline's authority, and coding it `Yes` is the
    # short-circuit this function just stopped doing. §0.3 and §0.4 both point
    # at the same answer: no captured sentence, no determination -- `Unclear`,
    # which enters NEITHER hospital bucket and routes to a human. §10.2's
    # NON_HOSPITAL carve-out for an association's own operating costs is about a
    # source that SHOWS the money stays; it does not reach a source that says
    # nothing.
    if (rt == "HOSPITAL_AFFILIATED_ENTITY") {
      return(tibble::tibble(
        flow_type = "PASS_THROUGH_UNRESOLVED",
        distributed_to_hospital = "Unclear",
        hospital_benefiting = "Unclear",
        flow_basis = paste0(
          "\u00a710.2 PASS_THROUGH_UNRESOLVED: the recipient is a ",
          "hospital-affiliated entity -- hospital-governed, hospital-owned or a ",
          "hospital association -- so it is not itself the hospital the DIRECT ",
          "row tests for, and the source does not say what the money does. ",
          "\u00a70.4: a determination without a quotable sentence is not a ",
          "determination, so this is Unclear rather than imputed in either ",
          "direction, and it is never added to a hospital total."
        ),
        flow_flag = "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED"
      ))
    }

    tibble::tibble(
      flow_type = "NON_HOSPITAL",
      distributed_to_hospital = "No",
      hospital_benefiting = "No",
      flow_basis = paste0(
        "§10.2 NON_HOSPITAL: the named recipient is not a hospital (§0.3a -- ",
        "judged on the recipient, not the activity), and the source does not ",
        "mention hospitals anywhere in the funded work."
      ),
      flow_flag = NA_character_
    )
  })
}


#' Attach `recipient_type`, `flow_type` and `distributed_to_hospital` to a table
#'
#' The single entry point a state extractor calls. Validates every produced
#' value against `vocabularies.csv` before returning, so a typo in an override
#' fails here and not three stages downstream.
#'
#' @param records A tibble with `awardee` and a description column.
#' @param state Two-letter state code.
#' @param description_col Name of the description column.
#' @param org_type_col Optional: a state-published organisation-type column,
#'   which takes precedence over the name rules where non-empty.
#' @param org_type_delimiter Separator between tokens in `org_type_col`. Alaska
#'   writes semicolons (the default); Oregon writes ", ". It is a parameter
#'   rather than a guess because guessing wrong here does not fail -- it splits
#'   a multi-token field into one unrecognised token, and
#'   `rhtp_recipient_type_from_org_type()` then refuses, which is the loud
#'   failure this argument exists to let a caller avoid honestly.
rhtp_classify_records <- function(records, state, description_col,
                                  org_type_col = NULL,
                                  org_type_delimiter = ";") {
  for (col in c("awardee", description_col)) {
    if (!col %in% names(records)) {
      stop("[classify] records has no `", col, "` column.", call. = FALSE)
    }
  }

  types <- if (!is.null(org_type_col) && org_type_col %in% names(records)) {
    rhtp_recipient_type_from_org_type(records[[org_type_col]],
                                      delimiter = org_type_delimiter)
  } else {
    rhtp_classify_recipient_type(records$awardee, state)
  }

  flows <- rhtp_classify_flow(types$recipient_type, records[[description_col]])

  allowed_type <- rhtp_vocabulary("recipient_type")
  allowed_flow <- rhtp_vocabulary("flow_type")
  allowed_dist <- rhtp_vocabulary("distributed_to_hospital")
  allowed_conf <- rhtp_vocabulary("determination_confidence")

  bad <- setdiff(unique(types$recipient_type), allowed_type)
  if (length(bad)) stop("[classify] recipient_type outside §8: ",
                        paste(bad, collapse = ", "), call. = FALSE)
  bad <- setdiff(unique(flows$flow_type), allowed_flow)
  if (length(bad)) stop("[classify] flow_type outside §8: ",
                        paste(bad, collapse = ", "), call. = FALSE)
  bad <- setdiff(unique(flows$distributed_to_hospital), allowed_dist)
  if (length(bad)) stop("[classify] distributed_to_hospital outside §8: ",
                        paste(bad, collapse = ", "), call. = FALSE)
  bad <- setdiff(unique(types$determination_confidence), allowed_conf)
  if (length(bad)) stop("[classify] determination_confidence outside §8: ",
                        paste(bad, collapse = ", "), call. = FALSE)

  records %>%
    dplyr::mutate(
      recipient_type = types$recipient_type,
      determination_confidence = types$determination_confidence,
      flow_type = flows$flow_type,
      distributed_to_hospital = flows$distributed_to_hospital,
      hospital_benefiting = flows$hospital_benefiting,
      classification_rule = types$rule,
      determination_basis = paste(types$recipient_type_basis, flows$flow_basis),
      flag_reason = dplyr::coalesce(
        flows$flow_flag,
        dplyr::if_else(types$rule == "FALLBACK", "RECIPIENT_TYPE_INFERRED",
                       NA_character_)
      )
    )
}


`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || is.na(x)) y else x


# -- §0.3 / §10.2 The hospital-dollar partition --------------------------------
#
# WHY THIS EXISTS. Until Illinois, every hospital dollar in this repository sat
# on a row whose own awardee WAS the hospital, named in the source: Georgia's
# 87, Pennsylvania's 27, Alabama's 60, Alaska's 26. Filtering on
# `distributed_to_hospital == "Yes"` and summing `amount` gave a defensible
# figure because every row it caught named a hospital.
#
# Illinois breaks that. ICAHN's $50,008,264 is correctly
# `distributed_to_hospital = Yes` under §10.2 -- the award to the intermediary
# is executed and eligibility is restricted to rural hospitals only -- and it
# names NO hospital. On ICAHN's own account no hospital has yet been chosen.
# The same filter now returns two kinds of dollar that must not be added, and
# adding them is exactly the "inflated, attackable number" §0.3 exists to
# prevent.
#
# A note in a file header does not prevent it. This does: the partition returns
# the two figures SEPARATELY and there is no function here that returns their
# sum. It is the device rhtp_ga_reconcile() uses to make Georgia's wrong total
# unobtainable, applied to the union.

#' Which hospital bucket does a row's money land in?
#'
#' Derived from the row, never asserted per state, so a state that later gains
#' a pass-through row is classified by the same rule rather than by whoever
#' wrote that state's extractor.
#'
#' IT KEYS ON recipient_type, NOT ONLY flow_type, AND THAT IS NOT COSMETIC.
#' The first version of this function read `flow_type` alone and bucketed
#' anything else as NOT_HOSPITAL. Florida's file predates the `flow_type`
#' column entirely, so all 15 of its hospital rows -- $49,345,213 -- were
#' silently dropped from the named bucket and the partition looked fine. A
#' hospital total quietly missing a whole state is worse than the merged total
#' this file exists to prevent, so:
#'
#'   * recipient_type is consulted, which every state file carries; and
#'   * a `Yes` row that fits NO bucket is an ERROR, not a silent NOT_HOSPITAL.
#'
#' @param flow_type §8 flow_type. May be NA for older state files.
#' @param distributed_to_hospital §8 Yes/No/Unclear.
#' @param recipient_type §8 recipient_type.
#' @param hospital_attribution Optional explicit value where a state has
#'   already coded it (Illinois does). Wins when present.
rhtp_hospital_attribution <- function(flow_type,
                                      distributed_to_hospital,
                                      recipient_type = NA_character_,
                                      hospital_attribution = NA_character_) {
  explicit <- as.character(hospital_attribution)
  flow     <- as.character(flow_type)
  dist     <- as.character(distributed_to_hospital)
  rtype    <- as.character(recipient_type)

  hospital_types <- c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY")

  bucket <- dplyr::case_when(
    !is.na(explicit) & nzchar(explicit)        ~ explicit,
    is.na(dist) | dist != "Yes"                ~ "NOT_HOSPITAL",
    !is.na(flow) & flow == "PASS_THROUGH_DESIGNATED" ~ "POOL_UNNAMED_HOSPITALS",
    rtype %in% hospital_types                  ~ "NAMED_HOSPITAL",
    !is.na(flow) & flow == "DIRECT"            ~ "NAMED_HOSPITAL",
    TRUE                                       ~ NA_character_
  )

  if (any(is.na(bucket))) {
    bad <- which(is.na(bucket))
    stop(
      "rhtp_hospital_attribution(): ", length(bad), " row(s) are ",
      "distributed_to_hospital = Yes but fit no hospital bucket ",
      "(recipient_type = ",
      paste(unique(rtype[bad]), collapse = ", "), "; flow_type = ",
      paste(unique(flow[bad]), collapse = ", "), ").\n",
      "These dollars would vanish from both buckets. Code the row's ",
      "flow_type or hospital_attribution rather than letting it fall ",
      "through (§10.2).",
      call. = FALSE
    )
  }

  bucket
}


#' Partition hospital dollars into NAMED and POOLED -- and never their sum
#'
#' @param records Any union of state award files. Needs `amount`,
#'   `distributed_to_hospital`, `flow_type`, and optionally
#'   `hospital_attribution` and `state`.
#' @return A tibble, one row per (state, bucket), plus a `bucket` total row per
#'   bucket. Deliberately NO grand total: see rhtp_hospital_total().
rhtp_hospital_dollar_partition <- function(records) {
  required <- c("amount", "distributed_to_hospital")
  missing_cols <- setdiff(required, names(records))
  if (length(missing_cols) > 0) {
    stop("rhtp_hospital_dollar_partition() needs: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  attribution <- if ("hospital_attribution" %in% names(records)) {
    records$hospital_attribution
  } else {
    NA_character_
  }
  rtype <- if ("recipient_type" %in% names(records)) {
    records$recipient_type
  } else {
    NA_character_
  }

  records %>%
    dplyr::mutate(
      .bucket = rhtp_hospital_attribution(
        flow_type, distributed_to_hospital, rtype, attribution
      ),
      .amount = suppressWarnings(as.numeric(amount))
    ) %>%
    dplyr::filter(.bucket != "NOT_HOSPITAL") %>%
    dplyr::group_by(
      state = if ("state" %in% names(.)) state else NA_character_,
      bucket = .bucket
    ) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      dollars = sum(.amount, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(bucket, dplyr::desc(dollars))
}


#' The function that refuses to exist
#'
#' Somebody will reach for a single "funds distributed to hospitals" number.
#' This is what they find. It does not compute one, because the two buckets
#' answer different questions -- "how much reached hospitals we can name" and
#' "how much was committed to hospitals nobody has named yet" -- and one
#' number cannot honestly carry both.
#'
#' It is not decoration: it is the searchable name a reader will grep for, and
#' finding a hard error here is cheaper than finding an inflated figure in a
#' board deck.
rhtp_hospital_total <- function(records) {
  parts <- rhtp_hospital_dollar_partition(records)
  named  <- sum(parts$dollars[parts$bucket == "NAMED_HOSPITAL"])
  pooled <- sum(parts$dollars[parts$bucket == "POOL_UNNAMED_HOSPITALS"])
  pooled_named <- sum(parts$dollars[parts$bucket == "POOL_NAMED_HOSPITALS"])

  # Every bucket the partition produced must be named in this message. A new
  # attribution code that this function did not know about would otherwise
  # disappear from the one place a reader is guaranteed to look -- which is
  # exactly the silent omission the function exists to prevent.
  unreported <- setdiff(unique(parts$bucket),
                        c("NAMED_HOSPITAL", "POOL_UNNAMED_HOSPITALS",
                          "POOL_NAMED_HOSPITALS"))
  if (length(unreported)) {
    stop("rhtp_hospital_total(): the partition returned bucket(s) this ",
         "function does not report: ", paste(unreported, collapse = ", "),
         ". Those dollars would vanish from the only summary a reader sees. ",
         "Add them here before using the new code.", call. = FALSE)
  }

  stop(
    "There is no single hospital total, and this function will not invent ",
    "one (§0.3).\n",
    "  NAMED_HOSPITAL        : ", format(named, big.mark = ",", scientific = FALSE),
    "  -- the row's own awardee is a named hospital.\n",
    "  POOL_NAMED_HOSPITALS  : ", format(pooled_named, big.mark = ",", scientific = FALSE),
    "  -- an intermediary's award; the hospitals ARE named, but no ",
    "per-hospital split is published.\n",
    "  POOL_UNNAMED_HOSPITALS: ", format(pooled, big.mark = ",", scientific = FALSE),
    "  -- restricted to hospitals, but NO hospital is named.\n",
    "Report the three figures separately. Use ",
    "rhtp_hospital_dollar_partition().",
    call. = FALSE
  )
}

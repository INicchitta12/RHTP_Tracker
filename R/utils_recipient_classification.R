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

  # Government.
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
  "PA", "Cameron County Ambulance Service",                                         "EMS_OR_PSAP",            "HIGH",   "county ambulance service; the EMS rule must beat the local-government rule"
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
  "Non-Profit, Social Service, or Community Based Organization", "NONPROFIT_CBO",               "HIGH"
)

# The tokens that describe WHAT CARE IS DELIVERED rather than what the recipient
# IS. Listed explicitly so a new one appearing in a later Alaska release is not
# silently treated as a form -- rhtp_recipient_type_from_org_type() hard-fails
# on a token in neither table.
RHTP_ORG_TYPE_SERVICE_TOKENS <- c(
  "Clinic", "Family medicine or primary care",
  "Behavioral health/substance use disorder treatment", "Maternal health",
  "Pharmacy", "Home-and-community-based services provider", "Dental",
  "Specialist", "Other health care provider"
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


#' Apply the §10.2 flow table
#'
#' @param recipient_type A §8 code, already determined from recipient identity.
#' @param description The source's own project description. Consulted only for
#'   non-hospital recipients, and only to choose between NON_HOSPITAL,
#'   IN_KIND_BENEFIT and PASS_THROUGH_UNRESOLVED.
#' @return A tibble: `flow_type`, `distributed_to_hospital`,
#'   `hospital_benefiting`, `flow_basis`, `flow_flag`.
rhtp_classify_flow <- function(recipient_type, description) {
  stopifnot(length(recipient_type) == length(description))

  purrr::map2_dfr(recipient_type, description, function(rt, desc) {
    desc <- desc %||% ""

    if (rt %in% c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY")) {
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
rhtp_classify_records <- function(records, state, description_col,
                                  org_type_col = NULL) {
  for (col in c("awardee", description_col)) {
    if (!col %in% names(records)) {
      stop("[classify] records has no `", col, "` column.", call. = FALSE)
    }
  }

  types <- if (!is.null(org_type_col) && org_type_col %in% names(records)) {
    rhtp_recipient_type_from_org_type(records[[org_type_col]])
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

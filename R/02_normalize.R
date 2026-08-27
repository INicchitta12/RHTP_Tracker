# 02_normalize.R ---------------------------------------------------------------
# Stage 2 -- Normalization -- build spec §6
#
# CONTRACT: raw JSON -> a typed, deduplicated, tier-assigned record table with
# change detection. Still no interpretation.
#
# "No interpretation" is a real constraint, not a slogan. This stage decides
# which tier a record sits in, whether it is junk, and whether it changed since
# the last pull. It does NOT decide whether a hospital got money, and it does
# not map RCJ's activityType onto the CMS allowable-use categories -- that is a
# crosswalk against a published CMS document, and it belongs downstream.
# `activity_type_raw` is carried verbatim and `activity_type` is left NA (§8).
#
# THE TWO RULES THAT SHAPE EVERYTHING HERE:
#
#   §0.2  Tiers never mix. Every record carries an award_tier before anything
#         else touches it, and a record that cannot be tiered is UNASSIGNED --
#         never SUBAWARD (§6.1 rule 5).
#   §6.2  Flag and quarantine, never silently drop. Every filter writes a
#         flag_reason. A record removed without a reason cannot be audited.
#
# INPUT:  data/raw/rcj/<pull_date>/{awards,documents,opportunities,activity,states}.json
#         Never the _stage0_exploratory/ subdirectory -- those are Session 1's
#         Delaware-only probes and sweeping them in would double-count Delaware.
#         rhtp_pull_dir() refuses the path outright.
#
# OUTPUT: data/interim/stage2_record_table.rds     effective-dated, all versions
#         data/interim/stage2_change_set.rds       NEW + CHANGED, for Stage 4
#         data/interim/stage2_dedup_collisions.rds §6.3 content collisions
#         data/interim/stage2_state_sources.rds    /activity siteUrl by state
#         data/interim/stage2_rcj_state_summary.rds  /states, cross-check only
#         data/reference/state_source_registry_candidates.csv  §7.2 Stage 3 seed
#         logs/normalize_manifest.csv              pinned schema, appended
#
# Zero quota. Every function here reads from disk.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. snake_case.
# Explicit dplyr:: namespacing. No setwd(); use here::here().

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source(here::here("R", "utils_config.R"))


# -- Constants -------------------------------------------------------------

# The five endpoint files a production pull writes. `activity` and `states`
# are read but do not produce record-table rows: /activity supplies
# state_source_url and the §7.2 registry seed, /states is a cross-check only
# and is explicitly barred from defining the state vocabulary (§7.1).
RHTP_RECORD_ENDPOINTS <- c("awards", "documents", "opportunities")
RHTP_PULL_ENDPOINTS   <- c(RHTP_RECORD_ENDPOINTS, "activity", "states")

# Quarantine, don't merely flag. These three say the record is not RHTP money
# in this state, so it must not reach a published sheet under any tier.
RHTP_QUARANTINE_FLAGS <- c(
  "PROVENANCE_MISMATCH",
  "JUNK_STATE_CODE",
  "NON_RHTP_SELF_DECLARED"
)

# Fields hashed for change detection (§6.3). Deliberately excludes anything
# this stage derives, so a rules change does not read as a data change.
RHTP_HASH_FIELDS <- c(
  "state", "fiscal_year", "awardee_name_raw", "amount_announced",
  "match_amount_rcj", "activity_type_raw", "program_description",
  "source_doc_title", "source_doc_category", "rcj_document_url",
  "solicitation_number", "date_announced", "date_effective"
)

RHTP_NORMALIZE_MANIFEST_COLUMNS <- c(
  "run_timestamp_utc", "pull_date", "stage", "rules_version",
  "source_endpoint", "records_read", "records_normalized",
  "n_quarantined", "n_flagged", "n_pass",
  "n_state_allotment", "n_solicitation", "n_subaward", "n_unassigned",
  "n_new", "n_changed", "n_unchanged",
  "allotment_anchor_available", "notes"
)

# Health / RHTP vocabulary for the §6.2 event-bleed heuristic. A heuristic,
# not a controlled vocabulary, so it lives here rather than in
# data/reference/.
RHTP_HEALTH_KEYWORDS <- c(
  "health", "hospital", "clinic", "rural", "rhtp", "medicaid", "medicare",
  "patient", "care", "provider", "medical", "nurse", "nursing", "physician",
  "behavioral", "telehealth", "ems", "emergency", "workforce", "cah",
  "critical access", "fqhc", "rhc", "pharmacy", "dental", "maternal",
  "obstetric", "award", "grant", "application", "proposal", "solicitation",
  "rfp", "rfa", "nofo", "budget period", "deadline", "webinar", "loi"
)

# Tokens too common to carry evidence of a shared topic.
RHTP_STOPWORDS <- c(
  "the", "and", "for", "with", "from", "that", "this", "will", "are", "was",
  "date", "dates", "time", "none", "than", "then", "into", "over", "under",
  "posted", "due", "start", "end", "begin", "final", "first", "second",
  "third", "fourth", "state", "states", "county", "new", "your", "you",
  "its", "their", "have", "has", "not", "all", "any", "may", "can"
)


# -- Reference tables ------------------------------------------------------

#' The state vocabulary (§7.1)
#'
#' Independent of RCJ, by design. /states returns 49 states plus a pseudo-state
#' `US` and omits Wyoming; `RC` appears as a state code on 54 /documents
#' records and is not a state. Neither may define this list.
#'
#' Hard-fails on anything other than exactly 50 rows, because every state-keyed
#' join and QA reconciliation downstream assumes it (§13.14).
rhtp_cms_states <- function() {
  path <- here::here("data", "reference", "cms_states.csv")

  states <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  if (nrow(states) != 50) {
    stop(
      "data/reference/cms_states.csv must have exactly 50 rows (§7.1); found ",
      nrow(states), ". Every state-keyed join downstream assumes 50.",
      call. = FALSE
    )
  }

  states %>% dplyr::select(state, state_name)
}


#' Read a pattern table from data/reference/
#'
#' `pattern_type` is `fixed` or `regex`; fixed patterns are escaped so a
#' literal `.` or `(` in a page-chrome string cannot behave as a metacharacter.
rhtp_read_patterns <- function(file) {
  path <- here::here("data", "reference", file)

  readr::read_csv(path, show_col_types = FALSE, progress = FALSE) %>%
    dplyr::mutate(
      regex = dplyr::if_else(
        pattern_type == "fixed",
        stringr::str_escape(pattern),
        pattern
      )
    )
}


#' CMS FY2026 state allotments, if the Stage 3 registry exists yet
#'
#' Two §6 rules depend on this anchor and are inactive without it:
#'   - §6.1 tier rule 3: amount matches the state allotment -> STATE_ALLOTMENT
#'   - §6.2 amount sanity: a Tier 3 amount above the state's allotment
#'
#' Returning an empty table rather than erroring is deliberate. The figures
#' come from the CMS December 2025 announcement, compiled by hand off-session
#' (§7.3), and inventing them here to keep a rule switched on is exactly the
#' §0.1 failure this project exists to avoid. The run reports which state it
#' is in and the QA layer treats the gap as a coverage gap, not a pass.
rhtp_load_allotments <- function() {
  path <- rhtp_path("state_source_registry")
  empty <- tibble::tibble(state = character(), fy2026_allotment = numeric())

  if (!file.exists(path)) {
    return(empty)
  }

  registry <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  if (!"fy2026_allotment" %in% names(registry)) {
    warning(
      "state_source_registry.csv exists but has no fy2026_allotment column; ",
      "§6.1 rule 3 and the allotment sanity check stay inactive.",
      call. = FALSE
    )
    return(empty)
  }

  registry %>%
    dplyr::filter(!is.na(fy2026_allotment)) %>%
    dplyr::transmute(
      state = as.character(state),
      fy2026_allotment = as.numeric(fy2026_allotment)
    )
}


# -- Small pure helpers ----------------------------------------------------

#' Pluck a scalar out of a parsed JSON record, with a typed default
#'
#' RCJ omits keys rather than nulling them, and a missing key that becomes
#' NULL silently drops the row when it reaches a tibble. Everything the
#' record builders read goes through here.
rhtp_pluck_chr <- function(record, ..., default = NA_character_) {
  value <- purrr::pluck(record, ...)
  if (is.null(value) || length(value) == 0) return(default)
  as.character(value)[1]
}

rhtp_pluck_num <- function(record, ..., default = NA_real_) {
  value <- purrr::pluck(record, ...)
  if (is.null(value) || length(value) == 0) return(default)
  suppressWarnings(as.numeric(value)[1])
}


#' Normalise a name for matching, without destroying it for display
#'
#' Curly quotes and en/em dashes are live in this data -- Delaware returned
#' "Beebe Healthcare – Georgetown Middle School" with an en dash and
#' "Nemours Children’s Health" with a curly apostrophe. Matching against
#' ASCII patterns fails on both. The raw value is always kept alongside.
rhtp_clean_name <- function(x) {
  x %>%
    stringr::str_replace_all("[‘’ʼ´`]", "'") %>%
    stringr::str_replace_all("[“”]", '"') %>%
    stringr::str_replace_all("[‐-―−]", "-") %>%
    stringr::str_replace_all("\\s+", " ") %>%
    stringr::str_trim()
}


#' Normalise a fiscal year to FY####
#'
#' /awards says "FY2026"; /documents says "2026". Both become "FY2026".
rhtp_normalize_fiscal_year <- function(x) {
  year <- stringr::str_extract(as.character(x), "\\d{4}")
  dplyr::if_else(is.na(year), NA_character_, paste0("FY", year))
}


#' ISO-8601 timestamp -> Date, tolerating the several shapes RCJ returns
rhtp_parse_date <- function(x) {
  as.Date(stringr::str_sub(as.character(x), 1, 10), format = "%Y-%m-%d")
}


#' Collapse a set of flags into the stored `flag_reason` string
#'
#' Semicolon-separated because a record routinely earns several -- the four
#' Delaware school-based-health-centre rows are PROVENANCE-clean but carry
#' both AMOUNT_IMPLAUSIBLE_LOW and EVENT_SCHEDULE_BLEED. Every consumer must
#' split on ";" before validating against the vocabulary.
rhtp_collapse_flags <- function(flags) {
  flags <- flags[!is.na(flags) & nzchar(flags)]
  if (length(flags) == 0) return(NA_character_)
  paste(sort(unique(flags)), collapse = ";")
}

rhtp_flag_vector <- function(flag_reason) {
  if (is.na(flag_reason) || !nzchar(flag_reason)) return(character())
  stringr::str_split(flag_reason, ";")[[1]]
}


#' qa_status from the flag set (§8 vocabulary)
rhtp_qa_status <- function(flag_reason) {
  purrr::map_chr(flag_reason, function(f) {
    flags <- rhtp_flag_vector(f)
    if (length(flags) == 0) return("PASS")
    if (any(flags %in% RHTP_QUARANTINE_FLAGS)) return("QUARANTINED")
    "FLAGGED"
  })
}


# -- §6.1 The named-recipient test -----------------------------------------

#' Does this awardeeName name an actual recipient?
#'
#' A populated `awardeeName` is not evidence of a named recipient. Delaware
#' returned six of fifteen rows where it held a programme name or a pool --
#' "Delaware DHSS / Mobile Health Hubs Grantee Pool" ($20M),
#' "School-Based Health Centers Expansion Initiative" ($10M). Treating those
#' as Tier 3 subawards is how $30M of unawarded pool money ends up in a
#' "distributed to hospitals" total.
#'
#' Two ways to fail: the value matches a programme-name pattern, or it is the
#' state agency administering the programme. State-agency patterns are
#' anchored to the record's own state, so "Delaware Department of Health and
#' Social Services" fails on a DE row and not on a GA one.
#'
#' Failures return FAIL_*, route to UNASSIGNED, and carry a flag. They are
#' never SUBAWARD (§6.1 rule 5).
#'
#' DO NOT OVER-FILTER (§6.1). A real legal entity that isn't a hospital still
#' passes: Delaware's State Housing Authority ($11.5M) is a genuine named
#' recipient and belongs in Tier 3 as a NON_HOSPITAL row, not quarantined out
#' of the table.
#'
#' @param awardee_name Raw awardeeName.
#' @param state_name The record's own stateName, for anchoring agency patterns.
#' @return A list: result (a named_recipient_test vocabulary value) and flag.
rhtp_named_recipient_test <- function(awardee_name, state_name,
                                      program_patterns = NULL,
                                      agency_patterns = NULL,
                                      entity_patterns = NULL) {
  if (is.null(program_patterns)) {
    program_patterns <- rhtp_read_patterns("program_name_patterns.csv")
  }
  if (is.null(agency_patterns)) {
    agency_patterns <- rhtp_read_patterns("state_agency_patterns.csv")
  }
  if (is.null(entity_patterns)) {
    entity_patterns <- rhtp_read_patterns("legal_entity_patterns.csv")
  }

  clean <- rhtp_clean_name(awardee_name)

  if (is.na(clean) || !nzchar(clean)) {
    return(list(result = "FAIL_EMPTY", flag = "AWARDEE_MISSING"))
  }

  # The state-agency test runs FIRST. An entity override must not rescue a
  # state agency: "Oklahoma Health Care Authority (OHCA) - EHR expansion" is
  # the administering agency whatever else its name contains.
  state_token <- if (is.na(state_name) || !nzchar(state_name)) {
    "(?!x)x"  # never matches
  } else {
    stringr::str_escape(rhtp_clean_name(state_name))
  }

  agency_regex <- stringr::str_replace_all(
    agency_patterns$regex, stringr::fixed("<STATE_NAME>"), state_token
  )

  if (any(stringr::str_detect(clean, stringr::regex(agency_regex,
                                                    ignore_case = TRUE)))) {
    return(list(result = "FAIL_STATE_AGENCY", flag = "STATE_AGENCY_AS_AWARDEE"))
  }

  # Programme-name patterns are state-independent.
  if (any(stringr::str_detect(clean, stringr::regex(program_patterns$regex,
                                                    ignore_case = TRUE)))) {

    # THE OVERRIDE (§6.1 "do not over-filter"). The spec's word list is aimed
    # at pools and placeholders, but `program` and `expansion` are also how
    # American health care names its real institutions: ten Nevada awards go
    # to "University of Nevada, <city> <specialty> Residency Program", and
    # Alabama's "Rural Health Medical Program Inc." is an FQHC. Those are
    # named recipients. A corporate suffix or a named provider/academic
    # institution overrides the programme match -- unless the name also says
    # outright that the recipient is unresolved, which beats everything.
    overrides <- entity_patterns %>%
      dplyr::filter(role == "ENTITY_OVERRIDE")
    suppressors <- entity_patterns %>%
      dplyr::filter(role == "OVERRIDE_SUPPRESSED")

    suppressed <- any(stringr::str_detect(
      clean, stringr::regex(suppressors$regex, ignore_case = TRUE)
    ))
    overridden <- any(stringr::str_detect(
      clean, stringr::regex(overrides$regex, ignore_case = TRUE)
    ))

    if (!(overridden && !suppressed)) {
      return(list(result = "FAIL_PROGRAM_NAME",
                  flag = "PROGRAM_NAME_AS_AWARDEE"))
    }
  }

  list(result = "PASS", flag = NA_character_)
}


# -- §6.1 Tier assignment --------------------------------------------------

#' Assign award_tier in the §6.1 priority order
#'
#' 1. Explicit RCJ record type where it maps cleanly.
#' 2. awardeeName populated AND passing the named-recipient test -> SUBAWARD.
#' 3. Amount matches the state's CMS FY2026 allotment -> STATE_ALLOTMENT.
#' 4. Amount on a solicitation/NOFO/RFP/RFA with no named recipient -> SOLICITATION.
#' 5. Otherwise UNASSIGNED. NEVER default to SUBAWARD.
#'
#' Rule 1's "maps cleanly" is narrow on purpose. RCJ's own coding is
#' machine-generated and non-quotable (CLAUDE.md §6), so it is trusted only
#' where the value is a structural record type rather than a judgement:
#' an /opportunities `type` of RFA/RFP/NOFO/IFB/RFI is a solicitation by
#' construction, and a /documents `category` of APPLICATION is a solicitation
#' document. `AWARD_ANNOUNCEMENT` is deliberately NOT enough on its own -- an
#' announcement of a state's own CMS allotment is Tier 1, and the four
#' Delaware school-based-health-centre rows sit under an award announcement
#' while carrying `federalAmount: 1`. It informs rule 2, it does not bypass it.
#'
#' Rule 3 needs the CMS allotment anchor. Without the Stage 3 registry the
#' rule is skipped, and `tier_basis` says so rather than silently passing the
#' record down to rule 4.
#'
#' @param allotment Numeric CMS FY2026 allotment for this record's state, or NA.
#' @param allotment_tolerance Fractional tolerance for the allotment match.
#'   States round: $216.0M against a true $215,957,000 must still match.
#' @return A list: award_tier and tier_basis (free text, always populated).
rhtp_assign_tier <- function(source_endpoint,
                             rcj_type = NA_character_,
                             named_recipient_test = "NOT_APPLICABLE",
                             amount = NA_real_,
                             allotment = NA_real_,
                             source_is_plan = FALSE,
                             allotment_tolerance = 0.005) {

  solicitation_types <- c("RFA", "RFP", "NOFO", "IFB", "ITB", "RFI",
                          "APPLICATION")
  rcj_type_upper <- toupper(as.character(rcj_type))

  # -- Rule 1: explicit RCJ record type, where it maps cleanly -------------
  if (!is.na(rcj_type_upper) && rcj_type_upper %in% solicitation_types) {
    return(list(
      award_tier = "SOLICITATION",
      tier_basis = paste0(
        "§6.1 rule 1: RCJ ", source_endpoint, " type '", rcj_type,
        "' is a solicitation by construction."
      )
    ))
  }

  # -- Rule 2: a genuinely named recipient ---------------------------------
  # A plan or application source blocks rule 2 outright: whoever is listed in
  # it has not received anything yet (§0.3, §9.2). The named-recipient test
  # result is left as it stands rather than being rewritten to a failure it
  # did not produce.
  if (identical(named_recipient_test, "PASS") && !isTRUE(source_is_plan)) {
    return(list(
      award_tier = "SUBAWARD",
      tier_basis = paste0(
        "§6.1 rule 2: awardeeName populated and passed the named-recipient ",
        "test. Amount is RCJ's, unvalidated (§0.1)."
      )
    ))
  }

  # -- Rule 3: amount matches the state's CMS allotment --------------------
  if (!is.na(amount) && !is.na(allotment) && allotment > 0) {
    if (abs(amount - allotment) <= allotment_tolerance * allotment) {
      return(list(
        award_tier = "STATE_ALLOTMENT",
        tier_basis = paste0(
          "§6.1 rule 3: amount ", format(amount, scientific = FALSE),
          " matches the CMS FY2026 state allotment ",
          format(allotment, scientific = FALSE), " within ",
          allotment_tolerance * 100, "%."
        )
      ))
    }
  }

  allotment_note <- if (is.na(allotment)) {
    " Rule 3 was skipped: no CMS allotment anchor for this state (Stage 3 registry not yet compiled)."
  } else {
    ""
  }

  # -- Rule 4: an amount on a solicitation with no named recipient ---------
  if (!is.na(amount) && source_endpoint == "opportunities") {
    return(list(
      award_tier = "SOLICITATION",
      tier_basis = paste0(
        "§6.1 rule 4: budgeted amount on an /opportunities record with no ",
        "named recipient.", allotment_note
      )
    ))
  }

  # -- Rule 5: never default to SUBAWARD -----------------------------------
  plan_note <- if (isTRUE(source_is_plan)) {
    paste0(" Rule 2 was blocked: the source document is a plan or ",
           "application, not an award action (§0.3, §9.2).")
  } else {
    ""
  }

  list(
    award_tier = "UNASSIGNED",
    tier_basis = paste0(
      "§6.1 rule 5: no rule matched (named-recipient test = ",
      named_recipient_test, "; RCJ type = ",
      dplyr::coalesce(as.character(rcj_type), "none"),
      "). Routed to the review queue, never defaulted to SUBAWARD.",
      plan_note, allotment_note
    )
  )
}


# -- §6.2 Junk filters -----------------------------------------------------

#' Does any pattern in a table match this text?
rhtp_any_pattern <- function(text, patterns) {
  if (is.na(text) || !nzchar(text) || nrow(patterns) == 0) return(FALSE)
  any(stringr::str_detect(text, stringr::regex(patterns$regex,
                                               ignore_case = TRUE)))
}


#' Provenance mismatch -- the highest-priority filter (§6.2)
#'
#' Delaware returned four records tracing to a HRSA Rural Health Grants fact
#' sheet: real rural health awards, wrong federal programme, unflagged in the
#' RHTP feed. Description-negation regex cannot catch them, because nothing
#' about them reads as non-rural-health. The test is on the SOURCE, not the
#' subject matter: does the source document tie to a non-RHTP federal
#' programme -- HRSA, USDA Rural Development, FCC/USAC Rural Health Care,
#' Flex/SORH?
#'
#' Getting HRSA money into an RHTP figure is the single most discrediting
#' error available (§13.11), so this quarantines rather than flags.
rhtp_flag_provenance <- function(source_text, patterns = NULL) {
  if (is.null(patterns)) patterns <- rhtp_read_patterns("non_rhtp_patterns.csv")
  markers <- patterns %>% dplyr::filter(flag_reason == "PROVENANCE_MISMATCH")

  if (rhtp_any_pattern(source_text, markers)) "PROVENANCE_MISMATCH" else NA_character_
}


#' Self-declared non-RHTP (§6.2)
rhtp_flag_self_declared <- function(description, patterns = NULL) {
  if (is.null(patterns)) patterns <- rhtp_read_patterns("non_rhtp_patterns.csv")
  negations <- patterns %>% dplyr::filter(flag_reason == "NON_RHTP_SELF_DECLARED")

  if (rhtp_any_pattern(description, negations)) "NON_RHTP_SELF_DECLARED" else NA_character_
}


#' Page chrome captured as a title (§6.2)
rhtp_flag_title_junk <- function(title, patterns = NULL) {
  if (is.null(patterns)) patterns <- rhtp_read_patterns("title_junk_patterns.csv")

  if (rhtp_any_pattern(title, patterns)) "PAGE_CHROME_TITLE" else NA_character_
}


#' Source document is a plan or an application, not an award action
#'
#' NOT IN THE LITERAL §6.1 PATTERN LIST -- added from §0.3 and §9.2, and
#' reversible by deleting this function and its two call sites.
#'
#' Delaware's "Rural Community Health Hubs (Mobile Health Units)" ($10M) passes
#' the §6.1 programme-name patterns -- it contains none of `pool`, `grantee`,
#' `initiative`, `expansion`, `program`, `fund` -- and would otherwise land in
#' Tier 3 as a named recipient. It is not one. It is a line in
#' "DE - 2026 - Delaware RHT Plan Application": a state describing what it
#' intends to do with money it has not yet awarded.
#'
#' §9.2 already says a source that is "a projection or plan rather than an
#' award action" cannot support a confirmation, and §0.3 says eligibility is
#' not receipt. Applying that at the source-document level catches the class,
#' where the awardee-name patterns catch only the instances someone happened
#' to phrase as a programme.
#'
#' TWO THINGS THIS RULE MUST NOT DO, both learned by doing them:
#'
#' A budget narrative is not a plan for this purpose. §9.2 lists
#' `STATE_BUDGET_NARRATIVE` among the source types that can support a `Yes`,
#' and Delaware's State Housing Authority award -- the spec's own
#' do-not-over-filter example -- is sourced from an executive budget summary.
#' Budget documents are therefore absent from the pattern list.
#'
#' A title can name a plan and still be an award list. Pennsylvania's
#' "Rural Health Selected Projects: Pa RHT Plan (RHTP) Authorized Project
#' Awards" carries 66 named rural hospitals -- Armstrong County Memorial,
#' Barnes-Kasson County, Bucktail Medical Center. An earlier version of this
#' rule matched `RHT Plan` and sent all 66 to UNASSIGNED. Award-action
#' language anywhere in the title now wins outright.
#'
#' Flags, and routes an /awards row to UNASSIGNED -- never drops. A plan that
#' later becomes an award re-tiers itself once the state posts the notice.
rhtp_flag_plan_source <- function(source_doc_title, source_doc_category) {
  if (is.na(source_doc_title)) return(NA_character_)

  award_action <- c(
    "\\bnotice of (intent to )?award\\b", "\\baward(s|ed|ees?)\\b",
    "\\bselected (projects|recipients|applicants|awardees)\\b",
    "\\bauthorized project\\b", "\\bfunding announcement\\b",
    "\\bgrant(s|ees?) announced\\b", "\\bcontract award\\b"
  )

  if (any(stringr::str_detect(source_doc_title,
                              stringr::regex(award_action, ignore_case = TRUE)))) {
    return(NA_character_)
  }

  plan_title <- c(
    "\\bplan application\\b", "\\bapplication narrative\\b",
    "\\b(draft|proposed) (plan|strategy)\\b",
    "\\bletter of (intent|interest)\\b",
    "\\bRHT Plan:", "\\bstrategy(,| and) initiatives\\b",
    "\\bperformance objectives\\b"
  )

  if (any(stringr::str_detect(source_doc_title,
                              stringr::regex(plan_title, ignore_case = TRUE)))) {
    "SOURCE_IS_PLAN_NOT_AWARD"
  } else {
    NA_character_
  }
}


#' Junk state code (§6.2, §7.1)
#'
#' Validated against the 50-row CMS list, never mapped. `RC` carries 54
#' /documents records and is not a state; `US` is a pseudo-state.
rhtp_flag_state_code <- function(state, valid_states) {
  if (is.na(state) || !nzchar(state) || !(state %in% valid_states)) {
    "JUNK_STATE_CODE"
  } else {
    NA_character_
  }
}


#' Amount sanity (§6.2)
#'
#' The floor matters as much as the ceiling. Delaware returned four records
#' with `federalAmount: 1` -- a zero-test misses those entirely. An RHTP
#' subaward below $1,000 effectively does not exist, so anything under it is
#' placeholder data.
#'
#' The allotment ceiling applies to Tier 3 only and needs the Stage 3 anchor;
#' without it that check does not fire, and the absence is reported rather
#' than read as a pass.
rhtp_flag_amount <- function(amount, award_tier, allotment = NA_real_,
                             amount_expected = TRUE,
                             floor_usd = NULL, hard_max_usd = NULL) {
  cfg <- rhtp_config()
  if (is.null(floor_usd))    floor_usd    <- cfg$qa$amount_implausible_floor_usd
  if (is.null(hard_max_usd)) hard_max_usd <- cfg$qa$amount_hard_max_usd

  flags <- character()

  if (is.na(amount)) {
    # An /awards record with no amount is a defect. A document or a
    # solicitation without one is just a document -- most /documents records
    # carry no `award` field at all, and flagging every one of them makes
    # AMOUNT_MISSING mean nothing.
    return(if (isTRUE(amount_expected)) "AMOUNT_MISSING" else NA_character_)
  }

  if (amount < floor_usd) flags <- c(flags, "AMOUNT_IMPLAUSIBLE_LOW")
  if (amount >= hard_max_usd) flags <- c(flags, "AMOUNT_IMPLAUSIBLE_HIGH")

  if (identical(award_tier, "SUBAWARD") && !is.na(allotment) &&
      amount > allotment) {
    flags <- c(flags, "AMOUNT_EXCEEDS_STATE_ALLOTMENT")
  }

  if (length(flags) == 0) NA_character_ else flags
}


#' Strip RCJ's appended event schedule from a machine-generated summary
#'
#' /documents `highlights` ends with a literal "Event schedule:" block that
#' repeats every keyDates entry verbatim. That makes the summary useless as
#' the comparison text for the bleed heuristic below -- the parent contains
#' the bled events word for word, so overlap is 100% by construction and the
#' Delaware Governor Meyer record reads as perfectly coherent while carrying
#' a Dolly Parton library statement in its schedule.
#'
#' The verbatim field is never modified; only the comparison text is.
rhtp_strip_event_schedule <- function(text) {
  # Vectorised: called on a whole column inside mutate().
  text %>%
    stringr::str_replace(
      stringr::regex("\\n\\s*Event schedule:.*$",
                     dotall = TRUE, ignore_case = TRUE),
      ""
    ) %>%
    stringr::str_trim()
}


#' Event-schedule bleed (§6.2)
#'
#' Unrelated state press releases bleed into event-schedule fields. The
#' Delaware Governor Meyer award announcement carries eight keyDates whose
#' location field holds a Delaware Libraries press release about Dolly Parton,
#' four Attorney General items, and a firearms arrest. A South Dakota record
#' carries boiler replacements and latrine renovations.
#'
#' Heuristic, per §6.2: flag when under half the event entries share content
#' with the parent record. "Share content" means either a substantive token in
#' common with the parent's own title and description, or a health/RHTP
#' keyword. The parent-token half is what keeps the genuine cases clean -- the
#' Delaware notice-of-award's "Budget Period 1 End Date" shares nothing with a
#' health keyword list but plenty with its own parent text.
#'
#' Needs at least three entries to judge. At two, one unrelated entry is
#' already 50% and the heuristic is deciding on a coin flip -- Delaware's
#' "Career Pathway Programs (HSS-26-075)" carries exactly two contract-term
#' dates that are genuinely its own but share no health keyword, and a
#' two-entry rule flags it. FLAGS ONLY, never auto-cleaned:
#' a bled event is evidence RCJ's extraction was unreliable for that record,
#' which is a reason for a human to look, not a reason to edit RCJ's data.
rhtp_flag_event_bleed <- function(event_texts, parent_text,
                                  state_name = NA_character_,
                                  min_events = 3, share_threshold = 0.5,
                                  min_shared_tokens = 2) {
  event_texts <- event_texts[!is.na(event_texts) & nzchar(event_texts)]
  if (length(event_texts) < min_events) return(NA_character_)

  tokenize <- function(x) {
    x %>%
      tolower() %>%
      stringr::str_replace_all("[^a-z0-9 ]", " ") %>%
      stringr::str_split(" ") %>%
      unlist() %>%
      setdiff(c("", RHTP_STOPWORDS)) %>%
      purrr::keep(~ nchar(.x) >= 4)
  }

  # The state's own name is shared by every press release the state ever
  # published, so it is evidence of nothing. Without this exclusion the
  # Delaware Governor Meyer record reads as topically coherent because a
  # Dolly Parton library statement and a school-based-health-centre award
  # both say "Delaware".
  boilerplate <- tokenize(dplyr::coalesce(state_name, ""))

  parent_tokens <- setdiff(tokenize(dplyr::coalesce(parent_text, "")),
                           boilerplate)

  related <- purrr::map_lgl(event_texts, function(txt) {
    lower <- tolower(txt)
    if (any(stringr::str_detect(lower, stringr::fixed(RHTP_HEALTH_KEYWORDS)))) {
      return(TRUE)
    }
    # Two shared tokens, not one. One incidental word in common between a
    # state's own documents is the null hypothesis, not a signal.
    length(intersect(setdiff(tokenize(txt), boilerplate), parent_tokens)) >=
      min_shared_tokens
  })

  if (mean(related) < share_threshold) "EVENT_SCHEDULE_BLEED" else NA_character_
}


# -- §6.3 Hashing, dedup, change detection ---------------------------------

#' Content hash over the substantive fields (§6.3)
#'
#' Award records carry no timestamp and the API has no `updated_since` filter
#' on /awards, /documents or /opportunities (§4.1), so hashing is the ONLY
#' Tier 3 change detection available. There is no server-side delta to fall
#' back on.
#'
#' Hashes the raw fields only, never anything this stage derives, so bumping
#' rules_version does not make every record read as changed.
rhtp_record_hash <- function(records, fields = RHTP_HASH_FIELDS) {
  present <- intersect(fields, names(records))

  records %>%
    dplyr::select(dplyr::all_of(present)) %>%
    purrr::pmap_chr(function(...) {
      values <- list(...)
      digest::digest(
        paste(names(values), purrr::map_chr(values, ~ as.character(.x)[1]),
              sep = "=", collapse = "|"),
        algo = "sha256"
      )
    })
}


#' Content-based dedup key (§6.3)
#'
#' ID-only dedup is not enough. The same award reported through two source
#' documents gets two record ids: Delaware returned two $10M school-based-
#' health-centre rows that appear to be the same money under two awardee
#' spellings. The spec's key is (state, amount, activity_type).
#'
#' `source_endpoint` is added to it. Without it a /documents row reporting a
#' state's allotment collides with an /awards row of the same size, which is
#' not a duplicated award -- it is a document about an award.
#'
#' Collisions are ROUTED TO REVIEW, never auto-merged -- two genuinely
#' different $250,000 workforce awards in the same state are a real
#' possibility, and merging them silently loses one.
rhtp_dedup_key <- function(source_endpoint, state, amount, activity_type_raw) {
  paste(
    dplyr::coalesce(as.character(source_endpoint), "NA"),
    dplyr::coalesce(as.character(state), "NA"),
    dplyr::coalesce(format(amount, scientific = FALSE, trim = TRUE), "NA"),
    dplyr::coalesce(toupper(rhtp_clean_name(activity_type_raw)), "NA"),
    sep = "|"
  )
}


#' Extract a state solicitation number from free text (§6.3)
#'
#' Re-opened solicitations are a known trap: West Virginia carries several
#' re-openings of the same underlying opportunity. Where the state's own
#' number is present (`RHT-AFA-06-12-2026-CCG`, `HSS-26-075`), it is the only
#' reliable way to see that two records are one pool.
rhtp_extract_solicitation_number <- function(text) {
  if (is.na(text) || !nzchar(text)) return(NA_character_)

  hit <- stringr::str_extract(
    text,
    "\\b[A-Z]{2,}[A-Z0-9]*(?:-[A-Z0-9]{1,10}){2,}\\b|\\b[A-Z]{2,}-\\d{2}-\\d{3,4}[A-Z]{0,3}\\b"
  )

  if (is.na(hit)) NA_character_ else hit
}


#' Mark content-duplicate and re-opened-solicitation collisions
#'
#' Adds flags in place. Does not merge anything.
rhtp_mark_collisions <- function(records) {
  floor_usd <- rhtp_config()$qa$amount_implausible_floor_usd

  records %>%
    dplyr::group_by(dedup_key) %>%
    dplyr::mutate(
      dedup_group_size = dplyr::n(),
      # A UNIFORM GRANT PROGRAMME IS NOT A DUPLICATE. Oregon awarded exactly
      # $100,000 to 99 separately named providers -- Adventist Health
      # Bayshore, Adventist Health Tillamook, and 97 more -- and Georgia
      # $750,000 to 80. All 179 collide on (state, amount, activity_type),
      # and calling them duplicates buries the real collisions in noise: the
      # spec's key was derived from Delaware's 15 records, where no such
      # programme existed. At national scale it produced 927 collisions.
      #
      # The discriminator is whether the group names distinct recipients. A
      # group of N rows with N distinct awardees that all pass the §6.1
      # named-recipient test is a programme; anything else -- a repeated
      # awardee, or awardees that are programmes and pools rather than
      # recipients -- is a duplication risk and goes to review. Delaware's
      # three $10M POPULATION_HEALTH rows have three distinct awardees, all
      # failing the test, so they still collide, which is the case §6.3 was
      # written for.
      n_distinct_awardees = dplyr::n_distinct(awardee_name_clean),
      all_named           = all(named_recipient_test == "PASS"),
      # A key built from missing or placeholder components is not evidence of
      # anything. Delaware's four school-based-health-centre rows all carry
      # `federalAmount: 1`, so they collide by construction while naming four
      # different providers -- Beebe, Nemours, TidalHealth. The placeholder
      # amount is already flagged AMOUNT_IMPLAUSIBLE_LOW.
      #
      # Restricted to /awards: §6.3 is about "the same award reported through
      # two source documents". Two documents about one award are not a
      # duplicated award, and Tier 1 reconciles against CMS directly (§13.3).
      dedup_group_size = dplyr::if_else(
        source_endpoint != "awards" |
          is.na(amount_announced) | is.na(state) |
          amount_announced < floor_usd |
          (n_distinct_awardees == dplyr::n() & all_named),
        1L, as.integer(dedup_group_size)
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(state, solicitation_number) %>%
    dplyr::mutate(
      solicitation_group_size = dplyr::if_else(
        is.na(solicitation_number), 1L, as.integer(dplyr::n())
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      collision_flags = purrr::map2_chr(
        dedup_group_size, solicitation_group_size,
        function(dup, sol) {
          flags <- character()
          if (dup > 1L) flags <- c(flags, "CONTENT_DUPLICATE")
          if (sol > 1L) flags <- c(flags, "REOPENED_SOLICITATION")
          rhtp_collapse_flags(flags)
        }
      )
    ) %>%
    dplyr::select(-n_distinct_awardees, -all_named)
}


#' Effective-dated change detection against the previous pull (§6.3)
#'
#' Never overwrites a prior version. A record whose hash changed keeps its old
#' row -- with `superseded_by` pointing at the new one -- and gains a new row
#' that inherits the original `first_seen`. A record that vanished from the
#' feed is marked WITHDRAWN and kept, because RCJ dropping a record is itself
#' a finding.
#'
#' @param current Records normalized from this pull.
#' @param prior The stored record table, or NULL on a first run.
#' @return The full effective-dated table, all versions.
rhtp_apply_change_detection <- function(current, prior = NULL,
                                        pull_date = Sys.Date()) {
  pull_date_chr <- as.character(pull_date)

  # row_uid must be unique: it is the join key for superseding and for
  # refreshing last_seen, and a duplicate fans both joins out many-to-many,
  # growing the table on every re-run. RCJ does ship the same id twice --
  # /documents carried two duplicated ids in the 2026-08-27 pull, and an
  # identical record under a duplicated id produces an identical hash -- so
  # the occurrence index is part of the key.
  current <- current %>%
    dplyr::mutate(
      row_uid = paste0(record_id, "@", stringr::str_sub(rcj_record_hash, 1, 12))
    ) %>%
    dplyr::group_by(row_uid) %>%
    dplyr::mutate(
      # Base `if`, not dplyr::if_else(): the condition is one value per group
      # while both branches are one value per row, which if_else() rejects.
      row_uid = if (dplyr::n() > 1L) {
        paste0(row_uid, "#", dplyr::row_number())
      } else {
        row_uid
      }
    ) %>%
    dplyr::ungroup()

  if (anyDuplicated(current$row_uid) > 0) {
    stop("row_uid is not unique after disambiguation; change detection would ",
         "fan out and grow the table on every re-run.", call. = FALSE)
  }

  if (is.null(prior) || nrow(prior) == 0) {
    return(
      current %>%
        dplyr::mutate(
          first_seen    = pull_date_chr,
          last_seen     = pull_date_chr,
          superseded_by = NA_character_,
          change_status = "NEW"
        )
    )
  }

  # The live version of each prior record: the one nothing supersedes.
  prior_live <- prior %>% dplyr::filter(is.na(superseded_by))

  # One row per record_id. RCJ ships the same id twice (two duplicated
  # /documents ids in the 2026-08-27 pull), and joining a duplicated key into
  # a table that also duplicates it multiplies rows on every pull. The
  # duplication is already flagged DUPLICATE_RECORD_ID on the record itself;
  # here the earliest version is the one change detection tracks.
  prior_index <- prior_live %>%
    dplyr::arrange(record_id, row_uid) %>%
    dplyr::distinct(record_id, .keep_all = TRUE) %>%
    dplyr::select(record_id, prior_hash = rcj_record_hash,
                  prior_first_seen = first_seen, prior_row_uid = row_uid)

  annotated <- current %>%
    dplyr::left_join(prior_index, by = "record_id",
                     relationship = "many-to-one") %>%
    dplyr::mutate(
      change_status = dplyr::case_when(
        is.na(prior_hash)                  ~ "NEW",
        prior_hash == rcj_record_hash      ~ "UNCHANGED",
        TRUE                               ~ "CHANGED"
      ),
      first_seen    = dplyr::coalesce(prior_first_seen, pull_date_chr),
      last_seen     = pull_date_chr,
      superseded_by = NA_character_
    )

  # Prior rows whose record changed: retained, and pointed at their successor.
  # At most one successor per prior row. Where a duplicated record_id yields
  # two changed rows, the first is recorded as the successor and the second
  # stands on its own -- the DUPLICATE_RECORD_ID flag is what tells a
  # reviewer the pair needs untangling.
  superseded_map <- annotated %>%
    dplyr::filter(change_status == "CHANGED") %>%
    dplyr::arrange(prior_row_uid, row_uid) %>%
    dplyr::distinct(prior_row_uid, .keep_all = TRUE) %>%
    dplyr::select(prior_row_uid, successor = row_uid)

  # A record present before and absent now is kept and marked, never deleted.
  withdrawn_ids <- setdiff(prior_live$record_id, current$record_id)

  prior_updated <- prior %>%
    dplyr::left_join(superseded_map, by = c("row_uid" = "prior_row_uid"),
                     relationship = "many-to-one") %>%
    dplyr::mutate(
      superseded_by = dplyr::coalesce(superseded_by, successor),
      change_status = dplyr::if_else(
        record_id %in% withdrawn_ids & is.na(superseded_by),
        "WITHDRAWN", change_status
      )
    ) %>%
    dplyr::select(-successor)

  # UNCHANGED records refresh last_seen on the row already stored rather than
  # writing a second identical version.
  unchanged <- annotated %>%
    dplyr::filter(change_status == "UNCHANGED") %>%
    dplyr::select(row_uid, refreshed_last_seen = last_seen)

  prior_updated <- prior_updated %>%
    dplyr::left_join(unchanged, by = "row_uid",
                     relationship = "many-to-one") %>%
    dplyr::mutate(
      last_seen = dplyr::coalesce(refreshed_last_seen, last_seen),
      change_status = dplyr::if_else(
        !is.na(refreshed_last_seen), "UNCHANGED", change_status
      )
    ) %>%
    dplyr::select(-refreshed_last_seen)

  appended <- annotated %>%
    dplyr::filter(change_status %in% c("NEW", "CHANGED")) %>%
    dplyr::select(-prior_hash, -prior_first_seen, -prior_row_uid)

  out <- dplyr::bind_rows(prior_updated, appended)

  if (anyDuplicated(out$row_uid) > 0) {
    stop("row_uid collided between the prior table and this pull.",
         call. = FALSE)
  }

  out
}


# -- Reading the landing zone ----------------------------------------------

#' Resolve and guard a pull directory
#'
#' Refuses `_stage0_exploratory/`. That subdirectory holds Session 1's
#' Delaware-only Stage 0 probes; a glob that swept them into the record table
#' would double-count Delaware. They are fixtures, never a production pull.
rhtp_pull_dir <- function(pull_date) {
  dir <- rhtp_path("raw_rcj", as.character(pull_date))

  if (stringr::str_detect(dir, "_stage0_exploratory")) {
    stop(
      "_stage0_exploratory/ holds Session 1's Delaware-only Stage 0 probes, ",
      "not a production pull. Normalizing it would double-count Delaware.",
      call. = FALSE
    )
  }

  if (!dir.exists(dir)) {
    stop("No pull directory at '", dir, "'.", call. = FALSE)
  }

  dir
}


#' Read one endpoint file from a pull and return its records
#'
#' Stage 1 writes {pull_metadata, pages:[{page, body, body_sha256, ...}]}.
#' Reads only the parent directory -- never a subdirectory.
#'
#' @return A list: records (a list of parsed records) and metadata.
rhtp_read_endpoint <- function(pull_date, endpoint) {
  path <- file.path(rhtp_pull_dir(pull_date), paste0(endpoint, ".json"))

  if (!file.exists(path)) {
    stop("Missing '", endpoint, ".json' in the ", pull_date, " pull.",
         call. = FALSE)
  }

  parsed <- jsonlite::fromJSON(path, simplifyVector = FALSE)

  records <- parsed$pages %>%
    purrr::map(~ purrr::pluck(.x, "body", "data", .default = list())) %>%
    purrr::flatten()

  metadata <- parsed$pull_metadata

  # Stage 1 recorded whether the walk was exhaustive. Normalizing a truncated
  # pull produces a table that looks complete and is not (§5.2).
  if (!isTRUE(metadata$exhaustive)) {
    warning(
      "The ", endpoint, " pull for ", pull_date, " is not marked exhaustive. ",
      "Records read: ", length(records), " of a reported ",
      dplyr::coalesce(metadata$reported_total, NA), ".",
      call. = FALSE
    )
  }

  list(records = records, metadata = metadata)
}


# -- Endpoint -> record table ----------------------------------------------

#' Empty record-table row, so every builder returns the same schema
#'
#' Stage 2 populates the identity/provenance and award-core blocks of the §12
#' dictionary. The validation and hospital-determination blocks are added by
#' Stages 4 and 5 and deliberately absent here: a column of NAs that looks
#' like an unfilled determination invites someone to fill it in the wrong
#' stage.
rhtp_record_skeleton <- function(n = 0) {
  tibble::tibble(
    record_id            = rep(NA_character_, n),
    source_endpoint      = rep(NA_character_, n),
    state                = rep(NA_character_, n),
    state_name           = rep(NA_character_, n),
    fiscal_year          = rep(NA_character_, n),
    fiscal_year_raw      = rep(NA_character_, n),
    rhtp_budget_period   = rep(NA_character_, n),
    solicitation_number  = rep(NA_character_, n),
    awardee_name_raw     = rep(NA_character_, n),
    awardee_name_clean   = rep(NA_character_, n),
    amount_announced     = rep(NA_real_, n),
    amount_obligated     = rep(NA_real_, n),
    amount_basis         = rep(NA_character_, n),
    match_amount_rcj     = rep(NA_real_, n),
    activity_type        = rep(NA_character_, n),
    activity_type_raw    = rep(NA_character_, n),
    program_description  = rep(NA_character_, n),
    source_doc_id        = rep(NA_character_, n),
    source_doc_title     = rep(NA_character_, n),
    source_doc_category  = rep(NA_character_, n),
    rcj_document_url     = rep(NA_character_, n),
    state_source_url     = rep(NA_character_, n),
    date_announced       = rep(as.Date(NA), n),
    date_effective       = rep(as.Date(NA), n),
    rcj_record_type      = rep(NA_character_, n),
    rcj_status           = rep(NA_character_, n),
    event_texts          = vector("list", n),
    raw_flags            = rep(NA_character_, n)
  )
}


#' /awards -> record rows
#'
#' The Tier 3 candidate feed, and the only endpoint with an awardee field.
#'
#' `amount_announced` takes federalAmount; `amount_obligated` stays NA. RCJ's
#' figure is an announcement-level claim at best and is never validated here
#' (§0.1) -- Stage 4 populates the obligated figure from the state notice of
#' award. `matchAmount` goes to `match_amount_rcj` and is never allowed near
#' the cost-share fields, which are an attribute of the Tier 2 solicitation
#' and a separate assertion entirely (§12).
rhtp_normalize_awards <- function(records) {
  if (length(records) == 0) return(rhtp_record_skeleton(0))

  purrr::map_dfr(records, function(r) {
    awardee_raw <- rhtp_pluck_chr(r, "awardeeName")
    fy_raw      <- rhtp_pluck_chr(r, "fiscalYear")

    rhtp_record_skeleton(1) %>%
      dplyr::mutate(
        record_id           = rhtp_pluck_chr(r, "id"),
        source_endpoint     = "awards",
        state               = rhtp_pluck_chr(r, "state"),
        state_name          = rhtp_pluck_chr(r, "stateName"),
        fiscal_year         = rhtp_normalize_fiscal_year(fy_raw),
        fiscal_year_raw     = fy_raw,
        rhtp_budget_period  = rhtp_normalize_fiscal_year(fy_raw),
        awardee_name_raw    = awardee_raw,
        awardee_name_clean  = rhtp_clean_name(awardee_raw),
        amount_announced    = rhtp_pluck_num(r, "federalAmount"),
        amount_basis        = "RCJ /awards federalAmount. UNVALIDATED (§0.1) - not a citation.",
        match_amount_rcj    = rhtp_pluck_num(r, "matchAmount"),
        activity_type_raw   = rhtp_pluck_chr(r, "activityType"),
        program_description = rhtp_pluck_chr(r, "programDescription"),
        source_doc_id       = rhtp_pluck_chr(r, "sourceDocument", "id"),
        source_doc_title    = rhtp_pluck_chr(r, "sourceDocument", "title"),
        rcj_document_url    = rhtp_pluck_chr(r, "sourceDocument", "url"),
        solicitation_number = rhtp_extract_solicitation_number(
          rhtp_pluck_chr(r, "sourceDocument", "title")
        ),
        event_texts         = list(character())
      )
  })
}


#' /documents -> record rows
#'
#' Documents are sources first and records second, but a document carrying an
#' `award` amount is a tier candidate in its own right -- Missouri's
#' $216,000,000 hub announcement is the state's CMS allotment, i.e. Tier 1.
#'
#' `highlights` is RCJ's machine-generated summary and is non-quotable
#' (CLAUDE.md §6). It is carried as `program_description` for searching and
#' for the event-bleed comparison only, and is marked as such in amount_basis.
rhtp_normalize_documents <- function(records) {
  if (length(records) == 0) return(rhtp_record_skeleton(0))

  purrr::map_dfr(records, function(r) {
    fy_raw    <- rhtp_pluck_chr(r, "fiscalYear")
    title     <- rhtp_pluck_chr(r, "title")
    key_dates <- purrr::pluck(r, "keyDates", .default = list())

    # Named `kd_texts`, not `event_texts`: inside the mutate() below, dplyr
    # data masking resolves a bare `event_texts` to the skeleton's own empty
    # list column, not to this local, and every keyDates array silently
    # becomes NULL.
    kd_texts <- purrr::map_chr(key_dates, function(k) {
      paste(
        rhtp_pluck_chr(k, "label", default = ""),
        rhtp_pluck_chr(k, "location", default = ""),
        sep = " "
      )
    })

    rhtp_record_skeleton(1) %>%
      dplyr::mutate(
        record_id           = rhtp_pluck_chr(r, "id"),
        source_endpoint     = "documents",
        state               = rhtp_pluck_chr(r, "state"),
        state_name          = rhtp_pluck_chr(r, "stateName"),
        fiscal_year         = rhtp_normalize_fiscal_year(fy_raw),
        fiscal_year_raw     = fy_raw,
        rhtp_budget_period  = rhtp_normalize_fiscal_year(fy_raw),
        # RCJ emits `award: 0` where no amount is published: 534 of 3,092
        # documents carry a zero against 2,020 carrying no field at all and
        # 538 carrying a real figure. A document reporting $0 does not exist;
        # the zero is a null sentinel. Coerced here so it reads as "no amount
        # published" rather than as 534 implausibly small awards, and
        # amount_basis records the coercion. /awards is NOT treated this way:
        # `federalAmount: 0` and `federalAmount: 1` there are the placeholder
        # data §6.2 exists to catch, and stay flagged.
        amount_announced    = dplyr::na_if(rhtp_pluck_num(r, "award"), 0),
        amount_basis        = dplyr::if_else(
          identical(rhtp_pluck_num(r, "award"), 0),
          "RCJ /documents award was 0 - read as no amount published, not as a $0 award.",
          "RCJ /documents award. UNVALIDATED (§0.1) - not a citation."
        ),
        program_description = rhtp_pluck_chr(r, "highlights"),
        source_doc_id       = rhtp_pluck_chr(r, "id"),
        source_doc_title    = title,
        source_doc_category = rhtp_pluck_chr(r, "category"),
        rcj_document_url    = rhtp_pluck_chr(r, "url"),
        rcj_record_type     = rhtp_pluck_chr(r, "category"),
        date_announced      = rhtp_parse_date(rhtp_pluck_chr(r, "discovered")),
        solicitation_number = rhtp_extract_solicitation_number(title),
        event_texts         = list(kd_texts)
      )
  })
}


#' /opportunities -> record rows
#'
#' The Tier 2 feed. `budgetMax` is the pool size where present, falling back
#' to `budgetMin`; `amount_basis` records which.
#'
#' `sourceUrl` here IS a state URL -- unlike /awards' and /documents'
#' `url`, which is an RCJ proxy to their own cached copy and is never a
#' citation (§12).
rhtp_normalize_opportunities <- function(records) {
  if (length(records) == 0) return(rhtp_record_skeleton(0))

  purrr::map_dfr(records, function(r) {
    title      <- rhtp_pluck_chr(r, "title")
    summary    <- rhtp_pluck_chr(r, "summary")
    budget_max <- rhtp_pluck_num(r, "budgetMax")
    budget_min <- rhtp_pluck_num(r, "budgetMin")

    amount <- dplyr::coalesce(budget_max, budget_min)
    basis <- dplyr::case_when(
      !is.na(budget_max) ~ "RCJ /opportunities budgetMax (pool ceiling). UNVALIDATED (§0.1).",
      !is.na(budget_min) ~ "RCJ /opportunities budgetMin; no budgetMax published. UNVALIDATED (§0.1).",
      TRUE               ~ NA_character_
    )

    rhtp_record_skeleton(1) %>%
      dplyr::mutate(
        record_id           = rhtp_pluck_chr(r, "id"),
        source_endpoint     = "opportunities",
        state               = rhtp_pluck_chr(r, "state"),
        amount_announced    = amount,
        amount_basis        = basis,
        program_description = summary,
        source_doc_title    = title,
        source_doc_category = rhtp_pluck_chr(r, "type"),
        state_source_url    = rhtp_pluck_chr(r, "sourceUrl"),
        rcj_record_type     = rhtp_pluck_chr(r, "type"),
        rcj_status          = rhtp_pluck_chr(r, "status"),
        date_announced      = rhtp_parse_date(rhtp_pluck_chr(r, "postedDate")),
        date_effective      = rhtp_parse_date(rhtp_pluck_chr(r, "dueDate")),
        solicitation_number = dplyr::coalesce(
          rhtp_extract_solicitation_number(title),
          rhtp_extract_solicitation_number(summary)
        ),
        event_texts         = list(character())
      )
  })
}


#' /activity -> the state-source-URL lookup and the §7.2 registry seed
#'
#' /activity is the only endpoint carrying real state URLs (§4.1). `siteUrl`
#' is present on every record; `detail.updatedDocuments[].sourceUrl` gives a
#' per-document state URL for a subset. `documentId` at the top level is
#' always null in the observed data -- the document references live inside
#' `detail` only.
#'
#' Produces one row per (state, document, url) reference plus the site-level
#' rows, deduplicated.
rhtp_normalize_activity <- function(records) {
  empty <- tibble::tibble(
    state = character(), source_doc_id = character(),
    state_source_url = character(), url_kind = character(),
    occurred_at = as.Date(character())
  )
  if (length(records) == 0) return(empty)

  purrr::map_dfr(records, function(r) {
    state       <- rhtp_pluck_chr(r, "state")
    occurred_at <- rhtp_parse_date(rhtp_pluck_chr(r, "occurredAt"))
    site_url    <- rhtp_pluck_chr(r, "siteUrl")

    doc_rows <- purrr::pluck(r, "detail", "updatedDocuments", .default = list()) %>%
      purrr::map_dfr(function(d) {
        url <- rhtp_pluck_chr(d, "sourceUrl")
        if (is.na(url)) return(empty)
        tibble::tibble(
          state = state,
          source_doc_id = rhtp_pluck_chr(d, "id"),
          state_source_url = url,
          url_kind = "document_source_url",
          occurred_at = occurred_at
        )
      })

    site_rows <- if (is.na(site_url)) empty else tibble::tibble(
      state = state, source_doc_id = NA_character_,
      state_source_url = site_url, url_kind = "site_url",
      occurred_at = occurred_at
    )

    dplyr::bind_rows(site_rows, doc_rows)
  }) %>%
    dplyr::group_by(state, source_doc_id, state_source_url, url_kind) %>%
    dplyr::summarise(occurred_at = max(occurred_at, na.rm = TRUE),
                     .groups = "drop")
}


#' /states -> RCJ's own state summary, for cross-check only
#'
#' NEVER the state vocabulary (§7.1) and never a published figure (§0.1).
#' `awardTotal` is useful for one thing: comparing RCJ's own claimed total
#' against what we normalized out of /awards, which surfaces coverage gaps.
rhtp_normalize_states <- function(records) {
  if (length(records) == 0) {
    return(tibble::tibble(state = character()))
  }

  purrr::map_dfr(records, function(r) {
    tibble::tibble(
      state              = rhtp_pluck_chr(r, "code"),
      rcj_state_name     = rhtp_pluck_chr(r, "name"),
      rcj_cah_count      = rhtp_pluck_num(r, "cahCount"),
      rcj_document_count = rhtp_pluck_num(r, "documents"),
      rcj_award_total    = rhtp_pluck_num(r, "awardTotal"),
      rcj_awardee_count  = rhtp_pluck_num(r, "awardeeCount"),
      rcj_site_url       = rhtp_pluck_chr(r, "siteUrl"),
      rcj_last_activity  = rhtp_parse_date(rhtp_pluck_chr(r, "lastActivity"))
    )
  })
}


# -- Classification pass ---------------------------------------------------

#' Apply the §6.1 tier rules and the §6.2 junk filters to a record table
#'
#' Order matters. The named-recipient test runs before tier assignment because
#' tier rule 2 depends on it, and the junk filters run after because the
#' allotment sanity check is Tier-3-conditional.
#'
#' @param records A table from the rhtp_normalize_* builders.
#' @param allotments (state, fy2026_allotment). Empty disables §6.1 rule 3 and
#'   the allotment ceiling; the run reports that rather than reading it as a pass.
rhtp_classify <- function(records, allotments = NULL, valid_states = NULL,
                          rules_version = NULL) {
  if (nrow(records) == 0) return(records)

  cfg <- rhtp_config()
  if (is.null(allotments))    allotments    <- rhtp_load_allotments()
  if (is.null(valid_states))  valid_states  <- rhtp_cms_states()$state
  if (is.null(rules_version)) rules_version <- cfg$rules_version

  program_patterns  <- rhtp_read_patterns("program_name_patterns.csv")
  agency_patterns   <- rhtp_read_patterns("state_agency_patterns.csv")
  entity_patterns   <- rhtp_read_patterns("legal_entity_patterns.csv")
  non_rhtp_patterns <- rhtp_read_patterns("non_rhtp_patterns.csv")
  title_patterns    <- rhtp_read_patterns("title_junk_patterns.csv")

  allotment_lookup <- stats::setNames(
    allotments$fy2026_allotment, allotments$state
  )

  records %>%
    dplyr::mutate(
      allotment = unname(allotment_lookup[state]),
      allotment = dplyr::if_else(is.na(state), NA_real_, allotment),

      # -- §6.1 named-recipient test ------------------------------------
      # Only /awards carries an awardee field; the other two endpoints are
      # NOT_APPLICABLE rather than failing an empty test, so a document is
      # never mistaken for an award with a missing recipient.
      .nrt = purrr::pmap(
        list(source_endpoint, awardee_name_raw, state_name),
        function(endpoint, awardee, st_name) {
          if (!identical(endpoint, "awards")) {
            return(list(result = "NOT_APPLICABLE", flag = NA_character_))
          }
          rhtp_named_recipient_test(awardee, st_name, program_patterns,
                                    agency_patterns, entity_patterns)
        }
      ),
      named_recipient_test = purrr::map_chr(.nrt, "result"),
      awardee_flag = purrr::map_chr(
        .nrt, ~ dplyr::coalesce(.x$flag, NA_character_)
      ),

      # A plan or application source cannot name an award recipient, however
      # entity-shaped the awardeeName looks.
      flag_plan_source = purrr::map2_chr(
        source_doc_title, source_doc_category, rhtp_flag_plan_source
      ),

      # -- §6.1 tier assignment ------------------------------------------
      .tier = purrr::pmap(
        list(source_endpoint, rcj_record_type, named_recipient_test,
             amount_announced, allotment,
             source_endpoint == "awards" & !is.na(flag_plan_source)),
        rhtp_assign_tier
      ),
      award_tier = purrr::map_chr(.tier, "award_tier"),
      tier_basis = purrr::map_chr(.tier, "tier_basis"),

      # -- §6.2 junk filters ---------------------------------------------
      # Provenance is tested on the SOURCE, not the subject matter: the
      # source document title plus the solicitation number, which is where a
      # HRSA-26-045 or a "Rural Health Grants Fact Sheet" actually shows up.
      .provenance_text = paste(
        dplyr::coalesce(source_doc_title, ""),
        dplyr::coalesce(solicitation_number, ""),
        sep = " "
      ),
      flag_provenance = purrr::map_chr(
        .provenance_text, ~ rhtp_flag_provenance(.x, non_rhtp_patterns)
      ),
      flag_self_declared = purrr::map_chr(
        program_description, ~ rhtp_flag_self_declared(.x, non_rhtp_patterns)
      ),
      flag_title = purrr::map_chr(
        source_doc_title, ~ rhtp_flag_title_junk(.x, title_patterns)
      ),
      flag_state = purrr::map_chr(
        state, ~ rhtp_flag_state_code(.x, valid_states)
      ),
      flag_amount = purrr::pmap_chr(
        list(amount_announced, award_tier, allotment,
             source_endpoint == "awards"),
        ~ rhtp_collapse_flags(rhtp_flag_amount(..1, ..2, ..3, ..4))
      ),
      flag_events = purrr::pmap_chr(
        list(event_texts,
             paste(dplyr::coalesce(source_doc_title, ""),
                   dplyr::coalesce(
                     rhtp_strip_event_schedule(program_description), ""),
                   sep = " "),
             state_name),
        rhtp_flag_event_bleed
      ),
      flag_source_doc = dplyr::if_else(
        source_endpoint == "awards" & is.na(source_doc_id),
        "SOURCE_DOCUMENT_UNRESOLVED", NA_character_
      ),

      # -- §6.3 dedup key -------------------------------------------------
      dedup_key = purrr::pmap_chr(
        list(source_endpoint, state, amount_announced, activity_type_raw),
        rhtp_dedup_key
      ),

      rules_version = rules_version
    ) %>%
    dplyr::select(-.nrt, -.tier, -.provenance_text)
}


#' Fold the per-filter flag columns into flag_reason and qa_status
rhtp_finalize_flags <- function(records, extra_flag_cols = character()) {
  if (nrow(records) == 0) {
    return(records %>% dplyr::mutate(flag_reason = character(),
                                     flag_count = integer(),
                                     qa_status = character()))
  }

  flag_cols <- c(
    "flag_provenance", "flag_self_declared", "flag_title", "flag_state",
    "flag_amount", "flag_events", "flag_source_doc", "flag_plan_source",
    "awardee_flag",
    "collision_flags", "raw_flags", extra_flag_cols
  )
  flag_cols <- intersect(flag_cols, names(records))

  records %>%
    dplyr::mutate(
      flag_reason = purrr::pmap_chr(
        dplyr::across(dplyr::all_of(flag_cols)),
        function(...) {
          rhtp_collapse_flags(
            unlist(purrr::map(list(...), rhtp_flag_vector))
          )
        }
      ),
      flag_count = purrr::map_int(flag_reason, ~ length(rhtp_flag_vector(.x))),
      qa_status  = rhtp_qa_status(flag_reason)
    ) %>%
    dplyr::select(-dplyr::all_of(flag_cols))
}


# -- Manifest --------------------------------------------------------------

#' Append per-endpoint rows to logs/normalize_manifest.csv
#'
#' Schema-pinned for the reason §13.15 records: `write_csv(append = TRUE)`
#' writes positionally, so a drifted header shifts every value one column and
#' reports success. Stage 1 was bitten by exactly this once.
rhtp_append_normalize_manifest <- function(rows) {
  path <- here::here("logs", "normalize_manifest.csv")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  missing_cols <- setdiff(RHTP_NORMALIZE_MANIFEST_COLUMNS, names(rows))
  if (length(missing_cols) > 0) {
    stop("Normalize manifest row is missing: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  rows <- rows %>% dplyr::select(dplyr::all_of(RHTP_NORMALIZE_MANIFEST_COLUMNS))
  file_exists <- file.exists(path)

  if (file_exists) {
    existing_header <- names(readr::read_csv(
      path, n_max = 0, show_col_types = FALSE, progress = FALSE
    ))
    if (!identical(existing_header, RHTP_NORMALIZE_MANIFEST_COLUMNS)) {
      stop(
        "logs/normalize_manifest.csv header does not match the canonical ",
        "schema; appending would misalign every value.\n",
        "  on disk:  ", paste(existing_header, collapse = ", "), "\n",
        "  expected: ", paste(RHTP_NORMALIZE_MANIFEST_COLUMNS, collapse = ", "),
        call. = FALSE
      )
    }
  }

  readr::write_csv(rows, path, append = file_exists, progress = FALSE)
  invisible(rows)
}


# -- Orchestrator ----------------------------------------------------------

#' Run Stage 2 over one dated pull
#'
#' @param pull_date The landing-zone directory to normalize.
#' @param prior_path The stored record table to diff against. Defaults to the
#'   Stage 2 output, so successive runs accumulate effective-dated versions.
#' @param write Write the interim outputs and append the manifest.
rhtp_normalize_pull <- function(pull_date = Sys.Date(),
                                prior_path = NULL,
                                write = TRUE) {
  cfg <- rhtp_config()
  pull_date <- as.character(pull_date)
  run_time <- Sys.time()

  message("-- Stage 2 normalization: ", pull_date, " --")

  allotments <- rhtp_load_allotments()
  allotment_anchor_available <- nrow(allotments) > 0

  if (!allotment_anchor_available) {
    message(
      "  NOTE: no CMS FY2026 allotment anchor on disk (Stage 3 registry not ",
      "yet compiled).\n",
      "        §6.1 tier rule 3 (allotment match -> STATE_ALLOTMENT) and the ",
      "§6.2 allotment\n",
      "        ceiling are INACTIVE this run. Recorded in the manifest; not a pass."
    )
  }

  valid_states <- rhtp_cms_states()$state

  raw <- RHTP_PULL_ENDPOINTS %>%
    purrr::set_names() %>%
    purrr::map(~ rhtp_read_endpoint(pull_date, .x))

  purrr::iwalk(raw, ~ message("  read ", .y, ": ", length(.x$records),
                              " records"))

  # -- Build the record table ---------------------------------------------
  builders <- list(
    awards        = rhtp_normalize_awards,
    documents     = rhtp_normalize_documents,
    opportunities = rhtp_normalize_opportunities
  )

  records <- RHTP_RECORD_ENDPOINTS %>%
    purrr::map_dfr(~ builders[[.x]](raw[[.x]]$records))

  # §6.3: the same RCJ id appearing twice in one pull is itself a defect.
  records <- records %>%
    dplyr::group_by(record_id) %>%
    dplyr::mutate(
      raw_flags = dplyr::if_else(dplyr::n() > 1L,
                                 "DUPLICATE_RECORD_ID", NA_character_)
    ) %>%
    dplyr::ungroup()

  # -- State source URLs, from /activity ----------------------------------
  state_sources <- rhtp_normalize_activity(raw$activity$records)

  doc_urls <- state_sources %>%
    dplyr::filter(url_kind == "document_source_url", !is.na(source_doc_id)) %>%
    dplyr::group_by(source_doc_id) %>%
    dplyr::slice_max(occurred_at, n = 1, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::select(source_doc_id, activity_state_source_url = state_source_url)

  records <- records %>%
    dplyr::left_join(doc_urls, by = "source_doc_id") %>%
    dplyr::mutate(
      state_source_url = dplyr::coalesce(state_source_url,
                                         activity_state_source_url)
    ) %>%
    dplyr::select(-activity_state_source_url)

  # -- Classify, collide, flag --------------------------------------------
  records <- records %>%
    rhtp_classify(allotments = allotments, valid_states = valid_states) %>%
    rhtp_mark_collisions() %>%
    rhtp_finalize_flags()

  # An /awards record whose sourceDocument.id does not resolve to a record in
  # this pull's /documents cannot have its source retrieved from the pull.
  # Distinct from a missing id, and equally a reason the registry (§7) is the
  # only route to a primary source for that row.
  document_ids <- records %>%
    dplyr::filter(source_endpoint == "documents") %>%
    dplyr::pull(record_id)

  records <- records %>%
    dplyr::mutate(
      flag_reason = purrr::pmap_chr(
        list(flag_reason, source_endpoint, source_doc_id),
        function(fr, ep, sd) {
          if (ep != "awards") return(fr)
          if (!is.na(sd) && sd %in% document_ids) return(fr)
          rhtp_collapse_flags(c(rhtp_flag_vector(fr),
                                "SOURCE_DOCUMENT_UNRESOLVED"))
        }
      ),
      flag_count = purrr::map_int(flag_reason, ~ length(rhtp_flag_vector(.x))),
      qa_status  = rhtp_qa_status(flag_reason)
    )

  records <- records %>%
    dplyr::mutate(rcj_record_hash = rhtp_record_hash(records))

  # -- §6.3 change detection ----------------------------------------------
  if (is.null(prior_path)) {
    prior_path <- rhtp_path("interim", "stage2_record_table.rds")
  }
  prior <- if (file.exists(prior_path)) readRDS(prior_path) else NULL

  record_table <- rhtp_apply_change_detection(records, prior, pull_date) %>%
    dplyr::mutate(pull_date = pull_date) %>%
    dplyr::relocate(row_uid, record_id, source_endpoint, award_tier,
                    change_status, qa_status, flag_reason)

  live <- record_table %>% dplyr::filter(is.na(superseded_by))
  change_set <- live %>% dplyr::filter(change_status %in% c("NEW", "CHANGED"))

  collisions <- live %>%
    dplyr::filter(stringr::str_detect(
      dplyr::coalesce(flag_reason, ""), "CONTENT_DUPLICATE|REOPENED_SOLICITATION"
    )) %>%
    dplyr::arrange(dedup_key, solicitation_number)

  rcj_state_summary <- rhtp_normalize_states(raw$states$records)

  registry_candidates <- rhtp_registry_candidates(state_sources, valid_states)

  # -- Report --------------------------------------------------------------
  summary_tbl <- live %>%
    dplyr::count(source_endpoint, award_tier, qa_status, name = "n") %>%
    dplyr::arrange(source_endpoint, award_tier, qa_status)

  message("\n-- Record table (live versions) --")
  print(as.data.frame(summary_tbl), row.names = FALSE)
  message("\n  total live rows : ", nrow(live))
  message("  NEW / CHANGED   : ", nrow(change_set))
  message("  quarantined     : ", sum(live$qa_status == "QUARANTINED"))
  message("  collisions      : ", nrow(collisions))

  # -- Write ---------------------------------------------------------------
  if (isTRUE(write)) {
    interim <- rhtp_path("interim", create = TRUE)

    saveRDS(record_table, file.path(interim, "stage2_record_table.rds"))
    saveRDS(change_set,   file.path(interim, "stage2_change_set.rds"))
    saveRDS(collisions,   file.path(interim, "stage2_dedup_collisions.rds"))
    saveRDS(state_sources, file.path(interim, "stage2_state_sources.rds"))
    saveRDS(rcj_state_summary,
            file.path(interim, "stage2_rcj_state_summary.rds"))

    readr::write_csv(
      registry_candidates,
      here::here("data", "reference", "state_source_registry_candidates.csv")
    )

    manifest <- RHTP_RECORD_ENDPOINTS %>%
      purrr::map_dfr(function(ep) {
        ep_rows <- live %>% dplyr::filter(source_endpoint == ep)
        tibble::tibble(
          run_timestamp_utc  = format(run_time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
          pull_date          = pull_date,
          stage              = "stage2_normalization",
          rules_version      = cfg$rules_version,
          source_endpoint    = ep,
          records_read       = length(raw[[ep]]$records),
          records_normalized = nrow(ep_rows),
          n_quarantined      = sum(ep_rows$qa_status == "QUARANTINED"),
          n_flagged          = sum(ep_rows$qa_status == "FLAGGED"),
          n_pass             = sum(ep_rows$qa_status == "PASS"),
          n_state_allotment  = sum(ep_rows$award_tier == "STATE_ALLOTMENT"),
          n_solicitation     = sum(ep_rows$award_tier == "SOLICITATION"),
          n_subaward         = sum(ep_rows$award_tier == "SUBAWARD"),
          n_unassigned       = sum(ep_rows$award_tier == "UNASSIGNED"),
          n_new              = sum(ep_rows$change_status == "NEW"),
          n_changed          = sum(ep_rows$change_status == "CHANGED"),
          n_unchanged        = sum(ep_rows$change_status == "UNCHANGED"),
          allotment_anchor_available = allotment_anchor_available,
          notes              = if (allotment_anchor_available) "" else
            "No CMS allotment anchor: 6.1 rule 3 and the allotment ceiling inactive."
        )
      })

    rhtp_append_normalize_manifest(manifest)
    message("\n  written to data/interim/ and logs/normalize_manifest.csv")
  }

  invisible(list(
    record_table = record_table,
    live = live,
    change_set = change_set,
    collisions = collisions,
    state_sources = state_sources,
    rcj_state_summary = rcj_state_summary,
    registry_candidates = registry_candidates,
    summary = summary_tbl,
    allotment_anchor_available = allotment_anchor_available
  ))
}


#' Machine-generated Stage 3 registry seed (§7.2)
#'
#' `siteUrl` is present on all /activity records, which makes the Stage 3 task
#' "check a machine-generated list" rather than "compile 50 URLs from
#' scratch". These are CANDIDATES ONLY. Every row still needs `last_verified`
#' set by a person who loaded the URL, and the states with no candidate at all
#' are the most important rows in the file.
rhtp_registry_candidates <- function(state_sources, valid_states) {
  candidates <- state_sources %>%
    dplyr::filter(state %in% valid_states) %>%
    dplyr::mutate(
      url_host = stringr::str_extract(state_source_url, "^https?://[^/]+")
    ) %>%
    dplyr::group_by(state, url_host) %>%
    dplyr::summarise(
      n_references = dplyr::n(),
      example_url = dplyr::first(state_source_url),
      last_seen_activity = max(occurred_at, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(state, dplyr::desc(n_references))

  covered <- unique(candidates$state)
  gaps <- setdiff(valid_states, covered)

  gap_rows <- tibble::tibble(
    state = gaps,
    url_host = NA_character_,
    n_references = 0L,
    example_url = NA_character_,
    last_seen_activity = as.Date(NA)
  )

  dplyr::bind_rows(candidates, gap_rows) %>%
    dplyr::arrange(state, dplyr::desc(n_references)) %>%
    dplyr::mutate(
      lead_agency = NA_character_,
      program_page_url = NA_character_,
      award_posting_url = NA_character_,
      pass_through_admin = NA_character_,
      pass_through_admin_url = NA_character_,
      fy2026_allotment = NA_real_,
      last_verified = NA_character_,
      verified_by = NA_character_,
      note = dplyr::if_else(
        n_references == 0L,
        "NO /activity siteUrl for this state - compile by hand (spec 7.2/7.3).",
        "Candidate from /activity. Load the URL and set last_verified before use."
      )
    )
}


# -- CLI entry point -------------------------------------------------------

# Sourcing this file does nothing. A normalization run costs zero quota but
# does write to data/interim/, so it is still explicit:
#
#   Rscript R/02_normalize.R --run                 # newest pull on disk
#   Rscript R/02_normalize.R --run --date=2026-08-27
#
if (!interactive()) {
  cli_args <- commandArgs(trailingOnly = TRUE)

  if ("--run" %in% cli_args) {
    date_arg <- cli_args %>%
      purrr::keep(~ stringr::str_starts(.x, "--date=")) %>%
      stringr::str_remove("--date=")

    pull_date <- if (length(date_arg) > 0) {
      date_arg[1]
    } else {
      dirs <- list.dirs(rhtp_path("raw_rcj"), recursive = FALSE,
                        full.names = FALSE)
      dirs <- dirs %>% purrr::keep(~ stringr::str_detect(.x, "^\\d{4}-\\d{2}-\\d{2}$"))
      if (length(dirs) == 0) {
        stop("No dated pull directories under data/raw/rcj/.", call. = FALSE)
      }
      sort(dirs, decreasing = TRUE)[1]
    }

    rhtp_normalize_pull(pull_date = pull_date)
  }
}

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
  "n_mined_candidates", "n_multi_recipient_candidates",
  "n_new", "n_changed", "n_unchanged",
  "allotment_anchor_available", "run_type", "notes"
)

# §5.2. Mirrors RHTP_RUN_TYPES in 01_retrieve_rcj.R -- redeclared rather than
# sourced, because Stage 2 must not source Stage 1 (whose CLI block fires on a
# shared --run flag). The two lists are asserted equal in the tests.
RHTP_NORMALIZE_RUN_TYPES <- c("PRODUCTION", "DEV")

#' Refuse a run_type outside the controlled vocabulary (§5.2, §13.6)
#'
#' Not match.arg(): that does partial matching, so "PROD" would be silently
#' accepted as "PRODUCTION" and written to an audit log as though it had been
#' spelled correctly. A controlled vocabulary refuses what it does not
#' recognise.
rhtp_check_run_type <- function(run_type, allowed) {
  if (length(run_type) != 1 || !run_type %in% allowed) {
    stop(
      "run_type must be exactly one of: ", paste(allowed, collapse = ", "),
      ". Got: ", paste(run_type, collapse = ", "), ".",
      call. = FALSE
    )
  }
  run_type
}


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


#' CMS FY2026 state allotments — the §7.1 anchor, if it is on disk yet
#'
#' Two §6 rules depend on this anchor and are inactive without it:
#'   - §6.1 tier rule 3: amount matches the state allotment -> STATE_ALLOTMENT
#'   - §6.2 amount sanity: a Tier 3 amount above the state's allotment
#'
#' The single source is `data/reference/cms_fy2026_allotments.csv`, built by
#' Stage 3 from the CMS December 2025 press release and asserted against
#' §13.17 on the way in. It is deliberately NOT read from the §7.3 registry as
#' well: two files carrying the same 50 figures is two files that can
#' disagree, and this one is the reconciliation anchor for every QA assertion
#' downstream.
#'
#' Returning an empty table rather than erroring when the file is absent is
#' also deliberate. Stage 2 must still run without the anchor, and inventing
#' figures here to keep a rule switched on is exactly the §0.1 failure this
#' project exists to avoid. The run reports which state it is in and the QA
#' layer treats the gap as a coverage gap, never as a pass.
rhtp_load_allotments <- function() {
  path <- rhtp_path("cms_allotments")
  empty <- tibble::tibble(state = character(), fy2026_allotment = numeric())

  if (!file.exists(path)) {
    return(empty)
  }

  allotments <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  if (!"fy2026_allotment" %in% names(allotments)) {
    warning(
      "cms_fy2026_allotments.csv exists but has no fy2026_allotment column; ",
      "\u00a76.1 rule 3 and the allotment sanity check stay inactive. Rebuild it ",
      "with: Rscript R/03_state_registry.R --allotments",
      call. = FALSE
    )
    return(empty)
  }

  allotments %>%
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
#' Rule 3 needs the §7.1 CMS allotment anchor
#' (`data/reference/cms_fy2026_allotments.csv`). Without it the rule is
#' skipped, and `tier_basis` says so rather than silently passing the record
#' down to rule 4.
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
    paste0(" Rule 3 was skipped: no CMS allotment anchor for this state ",
           "(data/reference/cms_fy2026_allotments.csv absent, or missing ",
           "this state).")
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
  # `award_tier` and `rules_version` are carried only to report what a rules
  # change moved. A prior table written before those columns existed is still
  # a valid history, so their absence degrades the report rather than failing
  # the pull.
  for (col in c("award_tier", "rules_version")) {
    if (!col %in% names(prior_live)) prior_live[[col]] <- NA_character_
  }

  prior_index <- prior_live %>%
    dplyr::arrange(record_id, row_uid) %>%
    dplyr::distinct(record_id, .keep_all = TRUE) %>%
    dplyr::select(record_id, prior_hash = rcj_record_hash,
                  prior_first_seen = first_seen, prior_row_uid = row_uid,
                  prior_award_tier = award_tier,
                  prior_rules_version = rules_version)

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

  # UNCHANGED records: the RCJ payload is byte-identical, so this is NOT a new
  # version and nothing is superseded. But the stored row also carries THIS
  # pipeline's derived columns -- award_tier, tier_basis, flag_reason,
  # qa_status, rules_version -- and those are a build output, not a fact about
  # the record. Keeping the prior row verbatim would freeze Session 4's
  # classifications into every later build: the CMS allotment anchor landing
  # would change nothing visible, and §13.10 ("rules_version is identical
  # across all rows in a build") would fail silently on a table quietly mixing
  # rule generations.
  #
  # So the live unchanged row is REPLACED by this run's classification of the
  # same payload, carrying `first_seen` forward. `superseded_by` is not set:
  # superseding tracks changes in the DATA (§6.3), and re-deriving a column
  # from unchanged input is not one. Superseded historical rows are untouched
  # -- they keep the classification that was published with them.
  refreshed_uids <- annotated %>%
    dplyr::filter(change_status == "UNCHANGED") %>%
    dplyr::pull(row_uid)

  prior_updated <- prior_updated %>%
    dplyr::filter(!(row_uid %in% refreshed_uids & is.na(superseded_by)))

  appended <- annotated %>%
    dplyr::filter(change_status %in% c("NEW", "CHANGED", "UNCHANGED")) %>%
    dplyr::select(-prior_hash, -prior_first_seen, -prior_row_uid,
                  -prior_award_tier, -prior_rules_version)

  out <- dplyr::bind_rows(prior_updated, appended)

  if (anyDuplicated(out$row_uid) > 0) {
    stop("row_uid collided between the prior table and this pull.",
         call. = FALSE)
  }

  # What a rules change actually moved, so it is reported rather than
  # discovered. Attached as an attribute rather than a column: it describes
  # this run, not the record.
  report_cols <- intersect(
    c("record_id", "state", "source_endpoint", "source_doc_title",
      "amount_announced", "prior_award_tier", "award_tier",
      "prior_rules_version", "rules_version", "tier_basis"),
    names(annotated)
  )

  attr(out, "reclassified") <- if ("award_tier" %in% names(annotated)) {
    annotated %>%
      dplyr::filter(change_status == "UNCHANGED",
                    !is.na(prior_award_tier),
                    prior_award_tier != award_tier) %>%
      dplyr::select(dplyr::all_of(report_cols))
  } else {
    annotated[0, intersect(report_cols, names(annotated)), drop = FALSE]
  }

  out
}


# -- §6.2 Multi-recipient awardeeName fields --------------------------------

# Tokens that are a corporate suffix rather than the start of a new name. A
# comma before one of these is punctuation inside a single legal name --
# "The Arc of Madison County, Inc.", "New Mexico Premier Health, LLC" -- so the
# fragment is rejoined to the one before it rather than counted as a recipient.
RHTP_CORPORATE_SUFFIX_TOKENS <- c(
  "inc", "incorporated", "llc", "l\\.l\\.c", "llp", "pllc", "pc", "p\\.c",
  "corp", "corporation", "co", "ltd", "limited", "pa", "p\\.a", "lp", "l\\.p",
  "dba", "d/b/a", "d\\.b\\.a"
)

# Stand-in for a comma that must not be treated as a delimiter. Printable, and
# improbable enough in an organisation name that restoring it is safe.
RHTP_COMMA_SENTINEL <- "<!COMMA!>"

# Openers that mark a fragment as an alias of the name before it rather than a
# new recipient. "St. Luke's Hospital of Bethlehem, Pennsylvania dba St. Luke's
# Hospital - Lehighton Campus, formerly Blue Mountain Hospital" is one hospital
# under three names, not three hospitals.
# Generic organisation-type words. A fragment made only of these names no one:
# "Health System", "Healthcare Association", "Children's Clinic" are the tails
# of "Memorial Community Hospital and Health System", "Alaska Hospital &
# Healthcare Association" and "Grande Ronde Hospital Women's & Children's
# Clinic" -- three single organisations that a conjunction split would
# otherwise cut in half.
RHTP_ORG_TYPE_WORDS <- c(
  "health", "healthcare", "hospital", "hospitals", "clinic", "clinics",
  "system", "systems", "center", "centre", "centers", "centres", "medical",
  "association", "network", "group", "services", "service", "care",
  "children", "childrens", "women", "womens", "men", "mens", "family",
  "community", "regional", "district", "authority", "the", "of", "and", "for",
  "a", "an"
)

RHTP_ALIAS_OPENERS <- c(
  "formerly", "previously", "now", "f/k/a", "fka", "a/k/a", "aka",
  "n/k/a", "nka", "also known as", "successor to"
)


#' Split an awardeeName that names more than one recipient (§6.2)
#'
#' RCJ and the states cram several recipients into one `awardeeName` field.
#' Three New Hampshire managed care organisations share a row carrying
#' $1,898,965,390 -- 9.3x the state's entire allotment -- and a single Oregon
#' row names about a hundred clinics. Delaware returned
#' `University of Delaware, Beebe Healthcare, Deloitte Consulting LLP`.
#'
#' §6.2 is explicit that this is not merely an amount-ceiling problem: **a
#' hospital buried inside a three-name string will not exact-match the AHA
#' Annual Survey and vanishes from the recipient list.** Beebe is the worked
#' example, and Deliverable 1 is the named-hospital sheet. So this function is
#' tuned for RECALL, not precision: the split is "a guess about the state's
#' formatting, not a fact", the group is flagged `MULTI_RECIPIENT_FIELD`, and a
#' human resolves it. A false positive costs a reviewer ten seconds; a false
#' negative loses a hospital from the primary product.
#'
#' **The amount is never divided.** RCJ publishes one figure for the field and
#' says nothing about how it splits across the recipients named in it.
#' Apportioning it would invent per-recipient awards that no source states --
#' the §0.1 failure this project exists to avoid, and §7A.5's rule. Every
#' fragment carries the field's total, labelled as the field's total.
#'
#' **Delimiters, per §6.2:** `;`, `,`, ` and `, ` & `. Four guards, each added
#' because a real row demanded it, and none of which can hide a hospital:
#'
#' 1. **Commas and conjunctions inside parentheses do not split.**
#'    `16 Strategically Located Rural Hospitals (unnamed, subrecipient group)`
#'    would otherwise yield two junk fragments.
#' 2. **A fragment opening with a corporate suffix, a US state name or an alias
#'    marker rejoins its predecessor.** `Hospital District No. 1 of Dickinson
#'    County, Kansas, DBA Memorial Health System` is one entity; splitting it
#'    invents "Kansas" as an awardee. This guard removes fabricated fragments,
#'    never real ones.
#' 3. **A fragment contained in another is the same recipient named more
#'    fully** -- `Oregon Health & Science University, Oregon Health & Science
#'    University - Department of Neurology`. Applied only when NO semicolon was
#'    present: a semicolon list is an explicit enumeration by whoever wrote it,
#'    and Oregon's hundred-clinic row lists `Evergreen Family Medicine`
#'    alongside `Evergreen Family Medicine - Sutherlin`, which are distinct
#'    clinics at distinct sites.
#' 4. **A split created ONLY by a conjunction needs two fragments that pass the
#'    §6.1 legal-entity test.** ` & ` is common inside a single organisation
#'    name -- `Oregon Health & Science University` -- where `;` and `,` at the
#'    top level are not. This guard is deliberately NOT applied to comma or
#'    semicolon splits, because that is exactly what would have rejected
#'    `Beebe Healthcare, TidalHealth`: neither carries a corporate suffix.
#'    §6.1's own instruction applies -- the fix for a missed entity is to
#'    extend the rule 1 marker list, which is why `healthcare`, `<x>health` and
#'    `children's health` are now in `legal_entity_patterns.csv`.
#'
#' A conjunction is a delimiter only when NO `;` or `,` is present. If the
#' author enumerated with punctuation, that is the enumeration, and splitting
#' the conjunction as well shreds `Oregon Health & Science University` into two
#' non-names.
#'
#' @return A list: fragments, delimiter, is_multi, basis.
rhtp_split_recipient_field <- function(awardee_name, entity_patterns = NULL) {
  none <- function(basis) {
    list(fragments = character(), delimiter = NA_character_,
         is_multi = FALSE, basis = basis)
  }

  clean <- rhtp_clean_name(awardee_name)
  if (is.na(clean) || !nzchar(clean)) return(none("Empty awardeeName."))

  if (is.null(entity_patterns)) {
    entity_patterns <- rhtp_read_patterns("legal_entity_patterns.csv")
  }

  # -- Guard 1: mask delimiters inside parentheses -------------------------
  # Masked rather than deleted, so the fragment text survives intact.
  masked <- clean
  repeat {
    replaced <- stringr::str_replace(
      masked, "\\(([^()]*)(,| and | & )([^()]*)\\)",
      paste0("(\\1", RHTP_COMMA_SENTINEL, "\\3)")
    )
    if (identical(replaced, masked)) break
    masked <- replaced
  }

  has_semicolon  <- stringr::str_detect(masked, ";")
  has_comma      <- stringr::str_detect(masked, ",")
  has_conjunction <- stringr::str_detect(
    masked, stringr::regex("\\s(and|&)\\s", ignore_case = TRUE)
  )

  if (!has_semicolon && !has_comma && !has_conjunction) {
    return(none("No multi-recipient delimiter present."))
  }

  # A conjunction is a delimiter only when no punctuation delimiter is
  # present. If the author enumerated with `;` or `,`, that IS the
  # enumeration, and a conjunction inside a fragment is part of a name:
  # "Oregon Health & Science University, <second recipient>" enumerates on the
  # comma, and splitting the `&` as well shreds the first name into "Oregon
  # Health" and "Science University".
  split_on_conjunction <- has_conjunction && !has_semicolon && !has_comma

  # The strongest delimiter present names the split, so the column stays a
  # single controlled value rather than a set.
  delimiter <- dplyr::case_when(
    has_semicolon   ~ "SEMICOLON",
    has_comma       ~ "COMMA",
    TRUE            ~ "CONJUNCTION"
  )

  tidy_fragments <- function(x) {
    x %>%
      stringr::str_squish() %>%
      stringr::str_remove("^[,;\\s]+") %>%
      stringr::str_remove("[,;\\s]+$") %>%
      purrr::keep(nzchar)
  }

  split_regex <- if (split_on_conjunction) {
    "\\s(?:and|&)\\s"
  } else {
    "[;,]"
  }

  raw_fragments <- masked %>%
    stringr::str_split(stringr::regex(split_regex, ignore_case = TRUE)) %>%
    purrr::pluck(1) %>%
    tidy_fragments() %>%
    stringr::str_replace_all(stringr::fixed(RHTP_COMMA_SENTINEL), ", ")

  if (length(raw_fragments) < 2) {
    return(none("A delimiter is present but there is nothing to split on."))
  }

  # -- Guard 2: rejoin a fragment that continues the one before it ---------
  suffix_or_alias <- paste0(
    "(", paste(c(RHTP_CORPORATE_SUFFIX_TOKENS,
                 stringr::str_escape(RHTP_ALIAS_OPENERS)),
               collapse = "|"), ")"
  )

  # A corporate suffix or alias marker anywhere at the head of a fragment
  # continues the name before it: ", Inc.", ", formerly Blue Mountain Hospital".
  continuation_regex <- paste0("^", suffix_or_alias, "\\b\\.?")

  # A US state name only continues the name before it when the fragment is the
  # state ALONE ("... Dickinson County, Kansas, DBA ...") or the state followed
  # immediately by a suffix or alias ("..., Pennsylvania dba St. Luke's ...").
  # Merely STARTING with one is not enough, or "Oregon Health" gets swallowed
  # into whatever precedes it.
  states_regex <- paste0(
    "^(", paste(stringr::str_escape(rhtp_cms_states()$state_name),
                collapse = "|"),
    ")\\b\\.?\\s*(", suffix_or_alias, "\\b|$)"
  )

  fragments <- purrr::reduce(raw_fragments, function(acc, fragment) {
    continues_previous <- stringr::str_detect(
      fragment, stringr::regex(continuation_regex, ignore_case = TRUE)
    ) || stringr::str_detect(
      fragment, stringr::regex(states_regex, ignore_case = TRUE)
    )
    if (length(acc) > 0 && continues_previous) {
      acc[length(acc)] <- paste0(acc[length(acc)], ", ", fragment)
      acc
    } else {
      c(acc, fragment)
    }
  }, .init = character())

  if (length(fragments) < 2) {
    return(none(
      "The delimiter separated a suffix, state name or alias, not a recipient."
    ))
  }

  # -- Guard 3: collapse a fragment contained in another (non-semicolon) ---
  if (!has_semicolon) {
    distinct_fragments <- fragments %>%
      purrr::keep(function(fragment) {
        others <- setdiff(fragments, fragment)
        !any(stringr::str_detect(others, stringr::fixed(fragment)))
      })

    if (length(distinct_fragments) < 2) {
      return(none(
        "Every fragment restates one recipient more fully."
      ))
    }
    fragments <- distinct_fragments
  }

  n_entities <- sum(purrr::map_lgl(
    fragments, ~ rhtp_legal_entity_test(.x, entity_patterns)
  ))

  # -- Guard 4: a conjunction-only split must look like two named entities --
  # ` & ` and ` and ` are common INSIDE one organisation name, where `;` and a
  # top-level `,` are not, so a conjunction split has to clear a higher bar:
  # two fragments that pass the §6.1 legal-entity test AND actually name
  # somebody. A fragment of nothing but generic type words -- "Health System",
  # "Healthcare Association" -- is the tail of one name, not a second recipient.
  if (identical(delimiter, "CONJUNCTION")) {
    names_somebody <- function(fragment) {
      tokens <- fragment %>%
        stringr::str_to_lower() %>%
        stringr::str_replace_all("[^a-z0-9\\s]", "") %>%
        stringr::str_split("\\s+") %>%
        purrr::pluck(1) %>%
        purrr::keep(nzchar)
      length(setdiff(tokens, RHTP_ORG_TYPE_WORDS)) > 0
    }

    n_named <- sum(purrr::map_lgl(fragments, function(fragment) {
      rhtp_legal_entity_test(fragment, entity_patterns) &&
        names_somebody(fragment)
    }))

    if (n_named < 2) {
      return(none(paste0(
        "Split only on a conjunction, and only ", n_named,
        " fragment(s) both pass the §6.1 legal-entity test and name somebody ",
        "- ' & ' and ' and ' are common inside a single organisation name."
      )))
    }
  }

  list(
    fragments = fragments,
    delimiter = delimiter,
    is_multi = TRUE,
    basis = paste0(
      "§6.2: ", tolower(delimiter), "-delimited awardeeName naming ",
      length(fragments), " recipients, ", n_entities,
      " of which pass the §6.1 legal-entity test. One candidate per fragment, ",
      "routed to review -- the split is a guess about the state's formatting, ",
      "not a fact. The amount is the FIELD total and is never divided."
    )
  )
}


#' One Tier 3 candidate per recipient named in a shared awardeeName field
#'
#' Emitted alongside the record table, not merged into it: the parent record
#' keeps its tier and its single row (§6.2 flags and routes to review, it does
#' not reassign -- the same discipline as `SOURCE_IS_PLAN_NOT_AWARD` and
#' `UNPARSED_AWARD_CANDIDATE`). A human or §9.3 corroboration resolves the
#' fragments into real awards.
#'
#' There is deliberately **no per-fragment amount column.** The field total is
#' carried once, under a name that says what it is, so no downstream sum can
#' quietly treat a hundred Oregon clinics as a hundred separate awards of the
#' same size.
rhtp_multi_recipient_candidates <- function(records, entity_patterns = NULL) {
  empty <- tibble::tibble(
    record_id = character(), state = character(), state_name = character(),
    award_tier = character(), awardee_name_raw = character(),
    delimiter = character(), n_recipients = integer(),
    recipient_index = integer(), recipient_name = character(),
    passes_legal_entity_test = logical(),
    amount_announced_field_total = numeric(), amount_note = character(),
    source_doc_title = character(), rcj_document_url = character(),
    state_source_url = character(), split_basis = character()
  )

  if (nrow(records) == 0) return(empty)

  if (is.null(entity_patterns)) {
    entity_patterns <- rhtp_read_patterns("legal_entity_patterns.csv")
  }

  pool <- records %>%
    dplyr::filter(
      source_endpoint == "awards",
      !is.na(awardee_name_raw),
      qa_status != "QUARANTINED"
    )

  if (nrow(pool) == 0) return(empty)

  split <- pool %>%
    dplyr::mutate(
      .split = purrr::map(awardee_name_raw,
                          ~ rhtp_split_recipient_field(.x, entity_patterns))
    ) %>%
    dplyr::filter(purrr::map_lgl(.split, "is_multi"))

  if (nrow(split) == 0) return(empty)

  split %>%
    dplyr::mutate(
      delimiter = purrr::map_chr(.split, "delimiter"),
      split_basis = purrr::map_chr(.split, "basis"),
      recipient_name = purrr::map(.split, "fragments"),
      n_recipients = purrr::map_int(.split, ~ length(.x$fragments))
    ) %>%
    tidyr::unnest_longer(recipient_name, indices_to = "recipient_index") %>%
    dplyr::transmute(
      record_id,
      state,
      state_name,
      award_tier,
      awardee_name_raw,
      delimiter,
      n_recipients,
      recipient_index,
      recipient_name,
      passes_legal_entity_test = purrr::map_lgl(
        recipient_name, ~ rhtp_legal_entity_test(.x, entity_patterns)
      ),
      amount_announced_field_total = amount_announced,
      amount_note = paste0(
        "RCJ published one amount for a field naming ", n_recipients,
        " recipients. This is the FIELD total, NOT this recipient's award. ",
        "Never divide it (§6.2) - no source states how it splits."
      ),
      source_doc_title,
      rcj_document_url,
      state_source_url,
      split_basis
    ) %>%
    dplyr::arrange(state, record_id, recipient_index)
}


# -- §0.2a Tier 1 corroboration --------------------------------------------

# The tolerance rule 3 matched on. A record inside it is a rounded restatement
# of the CMS figure; a record outside it should never have been tiered
# STATE_ALLOTMENT at all, so finding one is a rule-3 defect, not a data finding.
RHTP_ALLOTMENT_MATCH_TOLERANCE <- 0.005


#' Corroborate every RCJ STATE_ALLOTMENT record against the CMS anchor (§0.2a)
#'
#' **Published Tier 1 figures come from `cms_fy2026_allotments.csv` — 50 rows,
#' CMS-anchored — and never from the RCJ `STATE_ALLOTMENT` records.** The
#' record-table rows are RCJ records *about* the allotments; tiering them
#' correctly is what keeps them out of Tier 3, and it is not a claim that any
#' of them carries a publishable number.
#'
#' This function is the check that keeps the distinction honest. For every
#' Tier 1 record it compares RCJ's amount to the CMS figure for that state and
#' classifies the agreement:
#'
#' | `tier1_agreement` | Meaning |
#' |---|---|
#' | `EXACT` | RCJ restates the CMS figure to the dollar |
#' | `ROUNDED` | Within rule 3's tolerance but not equal — e.g. $216.0M against $216,276,818 |
#' | `DISAGREES` | Outside rule 3's tolerance. Should be impossible; a rule-3 defect |
#' | `NO_AMOUNT` | Tiered Tier 1 without an amount. Also should be impossible via rule 3 |
#'
#' `DISAGREES` and `NO_AMOUNT` are reported, never silently dropped: both mean
#' a record reached Tier 1 by a route rule 3 did not sanction.
#'
#' @param records A classified record table.
#' @param allotments (state, fy2026_allotment). Defaults to the §7.1 anchor.
#' @return One row per Tier 1 record.
rhtp_corroborate_state_allotments <- function(records, allotments = NULL) {
  if (is.null(allotments)) allotments <- rhtp_load_allotments()

  empty <- tibble::tibble(
    record_id = character(), state = character(),
    source_endpoint = character(), source_doc_title = character(),
    rcj_amount = numeric(), cms_fy2026_allotment = numeric(),
    delta = numeric(), abs_pct_delta = numeric(),
    tier1_agreement = character()
  )

  if (nrow(records) == 0 || nrow(allotments) == 0) return(empty)

  records %>%
    dplyr::filter(award_tier == "STATE_ALLOTMENT") %>%
    dplyr::left_join(
      allotments %>%
        dplyr::rename(cms_fy2026_allotment = fy2026_allotment),
      by = "state"
    ) %>%
    dplyr::transmute(
      record_id,
      state,
      source_endpoint,
      source_doc_title,
      rcj_amount = amount_announced,
      cms_fy2026_allotment,
      delta = amount_announced - cms_fy2026_allotment,
      abs_pct_delta = abs(delta) / cms_fy2026_allotment,
      tier1_agreement = dplyr::case_when(
        is.na(amount_announced) | is.na(cms_fy2026_allotment) ~ "NO_AMOUNT",
        delta == 0                                            ~ "EXACT",
        abs_pct_delta <= RHTP_ALLOTMENT_MATCH_TOLERANCE       ~ "ROUNDED",
        TRUE                                                  ~ "DISAGREES"
      )
    ) %>%
    dplyr::arrange(state, dplyr::desc(abs(delta)))
}


#' Per-state roll-up of the §0.2a corroboration
#'
#' The row that matters is a state where **no** RCJ record restates the CMS
#' figure exactly. Publishing Tier 1 from RCJ would give that state a wrong
#' number, which is the whole reason §0.2a names the CMS file as the source.
#'
#' States with no Tier 1 record at all are kept, not dropped. A state can have
#' an allotment-shaped record that never reached Tier 1 because RCJ published
#' the wrong figure for it — Nebraska is the live example — and that is exactly
#' the case a roll-up over Tier 1 records alone would hide.
rhtp_tier1_state_summary <- function(corroboration, valid_states = NULL) {
  if (is.null(valid_states)) valid_states <- rhtp_cms_states()$state

  per_state <- corroboration %>%
    dplyr::filter(state %in% valid_states) %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(
      n_tier1_records = dplyr::n(),
      n_exact   = sum(tier1_agreement == "EXACT"),
      n_rounded = sum(tier1_agreement == "ROUNDED"),
      n_disagrees = sum(tier1_agreement == "DISAGREES"),
      n_no_amount = sum(tier1_agreement == "NO_AMOUNT"),
      max_abs_delta = max(abs(delta), na.rm = TRUE),
      .groups = "drop"
    )

  tibble::tibble(state = sort(valid_states)) %>%
    dplyr::left_join(per_state, by = "state") %>%
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("n_"), ~ tidyr::replace_na(.x, 0L)),
      max_abs_delta = dplyr::if_else(n_tier1_records == 0, NA_real_,
                                     max_abs_delta),
      rcj_tier1_status = dplyr::case_when(
        n_tier1_records == 0 ~ "NO_RCJ_TIER1_RECORD",
        n_disagrees > 0 | n_no_amount > 0 ~ "REVIEW_RULE_3",
        n_exact > 0 ~ "CMS_FIGURE_RESTATED",
        TRUE        ~ "ROUNDED_ONLY"
      )
    ) %>%
    dplyr::arrange(rcj_tier1_status, state)
}


# -- §6.4 Tier 3 candidate mining from /documents --------------------------

# The terminators that end a legal-entity name in running prose. Drawn from
# the §6.1 rule 1 marker list, plus the plural and "Center"/"Centre" spellings
# that appear in document titles but not in RCJ's `awardeeName` field.
#
# This list only FINDS candidate spans. It never decides anything: every span
# it produces is put through rhtp_legal_entity_test() and the full §6.1
# named-recipient test, which are the arbiters. Same discipline as §9.1 --
# finders find, rules decide.
RHTP_ENTITY_TERMINATORS <- c(
  "Inc", "Incorporated", "LLC", "L\\.L\\.C", "LLP", "PLLC", "Corp",
  "Corporation", "Company", "Ltd", "Limited", "Association", "Society",
  "Foundation", "Trust", "Hospital", "Hospitals", "System", "Systems",
  "Cent(?:er|re)", "Cent(?:ers|res)", "Clinic", "Clinics", "University",
  "College", "District", "Authority", "Network", "Alliance", "Consortium",
  "Institute", "Partners", "Partnership"
)

# Connectives a real organisation name carries in the middle: "University of
# Nevada, Reno", "Foundation for Healthy Communities".
RHTP_ENTITY_CONNECTIVES <- c("of", "the", "and", "for", "at", "de", "in", "&")

# Markers that LEAD a name rather than ending it. American health care writes
# both shapes -- "Grady Memorial Hospital" ends in its marker, "University of
# Nevada, Reno" and "Foundation for Healthy Communities" begin with one -- and
# a finder that only handles the trailing shape misses every academic medical
# centre and every pass-through foundation (§7.3).
RHTP_ENTITY_LEADERS <- c(
  "University", "College", "Foundation", "Institute", "Alliance", "Authority",
  "Consortium", "Partnership", "Trust", "Network", "Association", "Society",
  "Department", "Board", "Center", "Centre", "Hospital", "Hospitals"
)


#' Is there a dollar figure in this text?
#'
#' Two renderings, because state press releases use both and the live §6.4
#' example uses the second: an explicit `$52,000,000` / `$52.3M`, and a bare
#' magnitude word — "Parrish Medical Center Awarded More Than 52 Million in
#' Grants" carries no dollar sign at all.
#'
#' A bare four-digit year cannot match: every branch requires either a `$` or
#' an explicit million/billion/thousand word.
rhtp_has_money <- function(text) {
  if (is.na(text) || !nzchar(text)) return(FALSE)

  patterns <- c(
    # $1,234,567 / $52.3 / $52.3M / $52.3 million
    "\\$\\s?\\d[\\d,]*(\\.\\d+)?\\s*(k|m|b|thousand|million|billion)?\\b",
    # 52 million / 1.2 billion, with no dollar sign
    "\\b\\d[\\d,]*(\\.\\d+)?\\s*(thousand|million|billion)\\b"
  )

  any(stringr::str_detect(text, stringr::regex(patterns, ignore_case = TRUE)))
}


#' Pull candidate organisation names out of running text
#'
#' Two shapes, because American health care writes both: a capitalised run
#' ENDING in an entity terminator ("Parrish Medical Center"), and one LED by an
#' entity marker joined with of/for ("University of Nevada, Reno", "Foundation
#' for Healthy Communities"). A trailing-only finder misses every academic
#' medical centre and every pass-through foundation.
#'
#' Returns every distinct span, longest first, so a caller testing "does any
#' named organisation appear here" gets the most specific one to record.
#'
#' Recall matters more than precision here: a false positive becomes a review
#' queue row a human dismisses in seconds, while a false negative is an award
#' RCJ failed to parse that we then also fail to surface -- which is the whole
#' point of §6.4.
rhtp_extract_org_candidates <- function(text) {
  if (is.na(text) || !nzchar(text)) return(character())

  terminators <- paste(RHTP_ENTITY_TERMINATORS, collapse = "|")
  connectives <- paste(RHTP_ENTITY_CONNECTIVES, collapse = "|")

  # Shape 1: a capitalised run ENDING in a legal-entity terminator.
  trailing <- paste0(
    "\\b[A-Z][A-Za-z&'\\.\\-]*",
    "(?:[ ,]+(?:", connectives, "|[A-Z][A-Za-z&'\\.\\-]*)){0,8}",
    "[ ,]+(?:", terminators, ")\\b\\.?"
  )

  # Shape 2: a run LED by an entity marker and joined by of/for.
  leading <- paste0(
    "\\b(?:", paste(RHTP_ENTITY_LEADERS, collapse = "|"), ")",
    "[ ,]+(?:of|for)[ ,]+",
    "[A-Z][A-Za-z&'\\.\\-]*",
    "(?:[ ,]+(?:", connectives, "|[A-Z][A-Za-z&'\\.\\-]*)){0,6}"
  )

  spans <- c(
    stringr::str_extract_all(text, trailing)[[1]],
    stringr::str_extract_all(text, leading)[[1]]
  )

  spans %>%
    stringr::str_squish() %>%
    stringr::str_remove("[,\\.]$") %>%
    unique() %>%
    (function(x) x[order(nchar(x), decreasing = TRUE)])
}


#' The §6.1 rule 1 legal-entity test, on its own
#'
#' §6.1 applies rule 1 as an override inside the named-recipient test: it
#' rescues a name that a programme pattern would otherwise reject. §6.4 needs
#' the same test as a standalone gate — "a named organization ... passing the
#' §6.1 legal-entity test" — so it is factored out here rather than
#' reimplemented, and both callers move together when the pattern table grows.
#'
#' An explicit statement that the recipient is unresolved ("various rural
#' health clinics", "unnamed subrecipient pool") suppresses the pass in both
#' directions, exactly as it does in §6.1.
rhtp_legal_entity_test <- function(name, entity_patterns = NULL) {
  if (is.null(entity_patterns)) {
    entity_patterns <- rhtp_read_patterns("legal_entity_patterns.csv")
  }

  clean <- rhtp_clean_name(name)
  if (is.na(clean) || !nzchar(clean)) return(FALSE)

  overrides <- entity_patterns %>% dplyr::filter(role == "ENTITY_OVERRIDE")
  suppressors <- entity_patterns %>% dplyr::filter(role == "OVERRIDE_SUPPRESSED")

  suppressed <- any(stringr::str_detect(
    clean, stringr::regex(suppressors$regex, ignore_case = TRUE)
  ))
  if (suppressed) return(FALSE)

  any(stringr::str_detect(
    clean, stringr::regex(overrides$regex, ignore_case = TRUE)
  ))
}


#' Mine /documents for award-shaped records that produced no /awards row (§6.4)
#'
#' `/awards` is not the Tier 3 universe -- it is the subset RCJ managed to
#' parse (§4.1). Award-shaped records sit unextracted in `/documents` in all 50
#' states, not only the eleven with zero award records. This pass surfaces
#' them.
#'
#' All four §6.4 conditions must hold:
#'   1. category AWARD_ANNOUNCEMENT or REFERENCE
#'   2. a named organisation in the title or description, passing the §6.1
#'      legal-entity test AND the full named-recipient test
#'   3. a dollar figure present
#'   4. no /awards record shares that sourceDocument.id
#'
#' **Nothing here is promoted to SUBAWARD, ever.** The premise of §6.4 is that
#' RCJ's extraction of this text failed; a second automated extraction of the
#' same text has earned no more trust than the first. Candidates stay
#' `UNASSIGNED`, carry `flag_reason = UNPARSED_AWARD_CANDIDATE`, and are
#' resolved by a human or by §9.3 corroboration (§13.18).
#'
#' Quarantined records are excluded before mining: a HRSA fact sheet or a junk
#' state code is not made minable by containing a hospital's name.
#'
#' @param records A classified, flagged record table.
#' @return A tibble of candidates, one row per mined document.
rhtp_mine_document_candidates <- function(records, entity_patterns = NULL,
                                          program_patterns = NULL,
                                          agency_patterns = NULL) {
  empty <- tibble::tibble(
    record_id = character(), state = character(), state_name = character(),
    source_doc_id = character(), source_doc_title = character(),
    source_doc_category = character(), mined_org_name = character(),
    mined_org_candidates = character(), amount_announced = numeric(),
    money_in_title = logical(), money_in_description = logical(),
    rcj_document_url = character(), state_source_url = character(),
    mining_basis = character()
  )

  if (nrow(records) == 0) return(empty)

  if (is.null(entity_patterns)) {
    entity_patterns <- rhtp_read_patterns("legal_entity_patterns.csv")
  }
  if (is.null(program_patterns)) {
    program_patterns <- rhtp_read_patterns("program_name_patterns.csv")
  }
  if (is.null(agency_patterns)) {
    agency_patterns <- rhtp_read_patterns("state_agency_patterns.csv")
  }

  # Condition 4, computed once: every sourceDocument.id already claimed by an
  # /awards record. Those documents were parsed successfully -- mining them
  # would re-surface awards the pipeline already holds.
  parsed_doc_ids <- records %>%
    dplyr::filter(source_endpoint == "awards", !is.na(source_doc_id)) %>%
    dplyr::pull(source_doc_id) %>%
    unique()

  pool <- records %>%
    dplyr::filter(
      source_endpoint == "documents",
      !is.na(source_doc_category),
      source_doc_category %in% c("AWARD_ANNOUNCEMENT", "REFERENCE"),
      qa_status != "QUARANTINED",
      !record_id %in% parsed_doc_ids
    )

  if (nrow(pool) == 0) return(empty)

  mined <- pool %>%
    dplyr::mutate(
      money_in_title = purrr::map_lgl(source_doc_title, rhtp_has_money),
      money_in_description = purrr::map_lgl(program_description,
                                            rhtp_has_money),
      # An amount RCJ did publish on the document also satisfies condition 3.
      has_money = money_in_title | money_in_description |
        !is.na(amount_announced),

      .orgs = purrr::map2(
        source_doc_title, program_description,
        function(title, description) {
          spans <- c(rhtp_extract_org_candidates(title),
                     rhtp_extract_org_candidates(description))
          spans <- unique(spans)
          if (length(spans) == 0) return(character())

          # Both gates, in §6.1's own order. The named-recipient test is what
          # keeps "Delaware Department of Health and Social Services" and
          # "Mobile Health Hubs Grantee Pool" out of the candidate set.
          keep <- purrr::map_lgl(spans, function(span) {
            if (!rhtp_legal_entity_test(span, entity_patterns)) return(FALSE)
            nrt <- rhtp_named_recipient_test(
              span, NA_character_, program_patterns, agency_patterns,
              entity_patterns
            )
            identical(nrt$result, "PASS")
          })

          spans[keep]
        }
      ),
      n_orgs = purrr::map_int(.orgs, length)
    ) %>%
    dplyr::filter(has_money, n_orgs > 0)

  if (nrow(mined) == 0) return(empty)

  mined %>%
    dplyr::transmute(
      record_id,
      state,
      state_name,
      source_doc_id,
      source_doc_title,
      source_doc_category,
      # The longest span: the most specific name the finder produced.
      mined_org_name = purrr::map_chr(.orgs, ~ .x[1]),
      mined_org_candidates = purrr::map_chr(.orgs, ~ paste(.x, collapse = " | ")),
      amount_announced,
      money_in_title,
      money_in_description,
      rcj_document_url,
      state_source_url,
      mining_basis = paste0(
        "§6.4: category ", source_doc_category, "; ",
        n_orgs, " organisation name(s) passing the §6.1 legal-entity and ",
        "named-recipient tests; a dollar figure present; no /awards record ",
        "shares this sourceDocument.id. UNASSIGNED candidate only — never ",
        "promoted to SUBAWARD (§6.4, §13.18)."
      )
    ) %>%
    dplyr::arrange(state, source_doc_title)
}


#' Per-state mined candidate counts — the second dimension of the §11 Coverage sheet
#'
#' A state with zero parsed `/awards` records and a non-zero candidate count is
#' "data exists, RCJ failed to extract it" — a materially different message
#' than "no data", and the reason the Coverage sheet reports two dimensions
#' rather than one (§4.1, §11).
rhtp_mining_coverage <- function(records, candidates, valid_states = NULL) {
  if (is.null(valid_states)) valid_states <- rhtp_cms_states()$state

  parsed <- records %>%
    dplyr::filter(source_endpoint == "awards", state %in% valid_states) %>%
    dplyr::count(state, name = "n_awards_parsed")

  clean_tier3 <- records %>%
    dplyr::filter(source_endpoint == "awards", state %in% valid_states,
                  award_tier == "SUBAWARD", qa_status == "PASS") %>%
    dplyr::count(state, name = "n_tier3_clean")

  mined <- candidates %>%
    dplyr::filter(state %in% valid_states) %>%
    dplyr::count(state, name = "n_mined_candidates")

  tibble::tibble(state = sort(valid_states)) %>%
    dplyr::left_join(parsed, by = "state") %>%
    dplyr::left_join(clean_tier3, by = "state") %>%
    dplyr::left_join(mined, by = "state") %>%
    dplyr::mutate(
      dplyr::across(c(n_awards_parsed, n_tier3_clean, n_mined_candidates),
                    ~ tidyr::replace_na(.x, 0L)),
      coverage_status = dplyr::case_when(
        n_awards_parsed > 0 & n_mined_candidates > 0 ~ "PARSED_PLUS_CANDIDATES",
        n_awards_parsed > 0                          ~ "PARSED",
        n_mined_candidates > 0 ~ "UNPARSED_DATA_EXISTS",
        # NOT "NO_DATA" (§6.4). This says RCJ surfaced nothing award-shaped for
        # the state -- neither a parsed /awards row nor a minable /documents
        # record. It says nothing whatever about whether the state has awarded
        # money, and a reader who takes it that way has been misled by the
        # label. Every one of these states has a $147M-$281M CMS allotment.
        TRUE                                         ~ "NO_RCJ_DATA"
      )
    ) %>%
    dplyr::arrange(dplyr::desc(n_mined_candidates), state)
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
#' @param run_type §5.2. "PRODUCTION" for the run whose output is committed as the
#'   build of record; "DEV" for an intermediate iteration. Recorded on every
#'   manifest row so a throwaway run can never be read as the real one.
rhtp_normalize_pull <- function(pull_date = Sys.Date(),
                                prior_path = NULL,
                                write = TRUE,
                                run_type = "PRODUCTION") {
  run_type <- rhtp_check_run_type(run_type, RHTP_NORMALIZE_RUN_TYPES)
  cfg <- rhtp_config()
  pull_date <- as.character(pull_date)
  run_time <- Sys.time()

  message("-- Stage 2 normalization: ", pull_date, " --")

  allotments <- rhtp_load_allotments()
  allotment_anchor_available <- nrow(allotments) > 0

  if (!allotment_anchor_available) {
    message(
      "  NOTE: no CMS FY2026 allotment anchor at ",
      rhtp_path("cms_allotments"), ".\n",
      "        §6.1 tier rule 3 (allotment match -> STATE_ALLOTMENT) and the ",
      "§6.2 allotment\n",
      "        ceiling are INACTIVE this run. Recorded in the manifest; not a pass.\n",
      "        Build it with: Rscript R/03_state_registry.R --allotments"
    )
  } else {
    message("  CMS FY2026 allotment anchor: ", nrow(allotments),
            " states, $",
            format(sum(allotments$fy2026_allotment), big.mark = ",",
                   scientific = FALSE),
            ". §6.1 rule 3 and the §6.2 ceiling are ACTIVE.")
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

  # -- §6.4 Tier 3 candidate mining from /documents -----------------------
  # Runs after the junk filters, so a quarantined record cannot be mined, and
  # before hashing, so the flag is part of the record's identity for change
  # detection. The mined rows stay UNASSIGNED: the flag routes them to review,
  # it does not reassign a tier (§6.4, §13.18).
  mining_candidates <- rhtp_mine_document_candidates(records)

  records <- records %>%
    dplyr::mutate(
      flag_reason = purrr::map2_chr(
        flag_reason, record_id,
        function(fr, id) {
          if (!id %in% mining_candidates$record_id) return(fr)
          rhtp_collapse_flags(c(rhtp_flag_vector(fr),
                                "UNPARSED_AWARD_CANDIDATE"))
        }
      ),
      flag_count = purrr::map_int(flag_reason, ~ length(rhtp_flag_vector(.x))),
      qa_status  = rhtp_qa_status(flag_reason)
    )

  mining_coverage <- rhtp_mining_coverage(records, mining_candidates,
                                          valid_states)

  # -- §6.2 multi-recipient awardeeName fields ----------------------------
  # Same discipline as §6.4: flag and route to review, never reassign a tier
  # and never divide an amount. The parent record keeps its single row.
  multi_recipient <- rhtp_multi_recipient_candidates(records)

  records <- records %>%
    dplyr::mutate(
      flag_reason = purrr::map2_chr(
        flag_reason, record_id,
        function(fr, id) {
          if (!id %in% multi_recipient$record_id) return(fr)
          rhtp_collapse_flags(c(rhtp_flag_vector(fr), "MULTI_RECIPIENT_FIELD"))
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

  reclassified <- attr(record_table, "reclassified")
  if (is.null(reclassified)) reclassified <- record_table[0, ]

  live <- record_table %>% dplyr::filter(is.na(superseded_by))
  change_set <- live %>% dplyr::filter(change_status %in% c("NEW", "CHANGED"))

  collisions <- live %>%
    dplyr::filter(stringr::str_detect(
      dplyr::coalesce(flag_reason, ""), "CONTENT_DUPLICATE|REOPENED_SOLICITATION"
    )) %>%
    dplyr::arrange(dedup_key, solicitation_number)

  # -- §0.2a Tier 1 corroboration -----------------------------------------
  # Published Tier 1 figures come from cms_fy2026_allotments.csv, never from
  # these records. This is the check that keeps the distinction honest.
  tier1_corroboration <- rhtp_corroborate_state_allotments(live, allotments)
  tier1_state_summary <- rhtp_tier1_state_summary(tier1_corroboration,
                                                  valid_states)

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
  message("  reclassified    : ", nrow(reclassified),
          " (unchanged data, new tier under rules ", cfg$rules_version, ")")

  if (nrow(reclassified) > 0) {
    message("\n-- Tier reassignments from a rules or reference-data change --")
    print(
      as.data.frame(
        reclassified %>%
          dplyr::count(state, prior_award_tier, award_tier, name = "n") %>%
          dplyr::arrange(dplyr::desc(n), state)
      ),
      row.names = FALSE
    )
  }

  # -- §6.4 mining report --------------------------------------------------
  unparsed_states <- mining_coverage %>%
    dplyr::filter(coverage_status == "UNPARSED_DATA_EXISTS")

  message("\n-- §6.4 /documents mining: Tier 3 candidates RCJ failed to parse --")
  message("  candidates      : ", nrow(mining_candidates), " across ",
          dplyr::n_distinct(mining_candidates$state), " states")
  message("  states with 0 parsed /awards records but candidates present: ",
          nrow(unparsed_states),
          if (nrow(unparsed_states) > 0) {
            paste0(" (", paste(unparsed_states$state, collapse = " "), ")")
          } else "")
  message("  NONE promoted to SUBAWARD (§6.4). All carry ",
          "UNPARSED_AWARD_CANDIDATE and stay UNASSIGNED for review.")

  # -- §6.2 multi-recipient report ----------------------------------------
  message("\n-- §6.2 multi-recipient awardeeName fields --")
  message("  parent records  : ",
          dplyr::n_distinct(multi_recipient$record_id))
  message("  recipients named: ", nrow(multi_recipient))
  if (nrow(multi_recipient) > 0) {
    message("  the amount is NEVER divided: each fragment carries the field ",
            "total, labelled as the field total.")
    print(
      as.data.frame(
        multi_recipient %>%
          dplyr::distinct(record_id, .keep_all = TRUE) %>%
          dplyr::select(state, delimiter, n_recipients,
                        amount_announced_field_total)
      ),
      row.names = FALSE
    )
  }

  # -- §0.2a Tier 1 corroboration report ----------------------------------
  message("\n-- §0.2a Tier 1: RCJ records vs the CMS anchor --")
  message("  published Tier 1 figures come from cms_fy2026_allotments.csv ",
          "(50 rows), NOT from these records.")

  agreement_counts <- tier1_corroboration %>%
    dplyr::count(tier1_agreement, name = "n") %>%
    dplyr::arrange(dplyr::desc(n))
  print(as.data.frame(agreement_counts), row.names = FALSE)

  rounded_only <- tier1_state_summary %>%
    dplyr::filter(rcj_tier1_status == "ROUNDED_ONLY")
  no_tier1 <- tier1_state_summary %>%
    dplyr::filter(rcj_tier1_status == "NO_RCJ_TIER1_RECORD")
  needs_review <- tier1_corroboration %>%
    dplyr::filter(tier1_agreement %in% c("DISAGREES", "NO_AMOUNT"))

  message("\n  states where NO RCJ record restates the CMS figure exactly: ",
          nrow(rounded_only))
  if (nrow(rounded_only) > 0) {
    message("    ", paste(rounded_only$state, collapse = " "))
  }
  message("  states with no RCJ Tier 1 record at all: ", nrow(no_tier1),
          if (nrow(no_tier1) > 0) {
            paste0(" (", paste(no_tier1$state, collapse = " "), ")")
          } else "")

  if (nrow(needs_review) > 0) {
    message("\n  ", nrow(needs_review), " record(s) reached Tier 1 outside ",
            "rule 3's tolerance -- this is a rule-3 defect, not a finding:")
    print(as.data.frame(needs_review), row.names = FALSE)
  }

  if (nrow(mining_candidates) > 0) {
    message("\n  mined candidates by state:")
    print(
      as.data.frame(
        mining_coverage %>% dplyr::filter(n_mined_candidates > 0)
      ),
      row.names = FALSE
    )
  }

  # -- Write ---------------------------------------------------------------
  if (isTRUE(write)) {
    interim <- rhtp_path("interim", create = TRUE)

    saveRDS(record_table, file.path(interim, "stage2_record_table.rds"))
    saveRDS(change_set,   file.path(interim, "stage2_change_set.rds"))
    saveRDS(collisions,   file.path(interim, "stage2_dedup_collisions.rds"))
    saveRDS(state_sources, file.path(interim, "stage2_state_sources.rds"))
    saveRDS(rcj_state_summary,
            file.path(interim, "stage2_rcj_state_summary.rds"))
    saveRDS(mining_candidates,
            file.path(interim, "stage2_mining_candidates.rds"))
    saveRDS(mining_coverage,
            file.path(interim, "stage2_mining_coverage.rds"))
    saveRDS(reclassified,
            file.path(interim, "stage2_reclassified.rds"))
    saveRDS(multi_recipient,
            file.path(interim, "stage2_multi_recipient_candidates.rds"))
    saveRDS(tier1_corroboration,
            file.path(interim, "stage2_tier1_corroboration.rds"))
    saveRDS(tier1_state_summary,
            file.path(interim, "stage2_tier1_state_summary.rds"))

    readr::write_csv(multi_recipient,
                     file.path(interim, "stage2_multi_recipient_candidates.csv"))
    readr::write_csv(tier1_corroboration,
                     file.path(interim, "stage2_tier1_corroboration.csv"))
    readr::write_csv(tier1_state_summary,
                     file.path(interim, "stage2_tier1_state_summary.csv"))

    # CSV as well as RDS: the mining candidates and the two-dimension coverage
    # table are both read by a person before Stage 4 exists to consume them,
    # and the coverage table becomes the §11 Coverage sheet.
    readr::write_csv(mining_candidates,
                     file.path(interim, "stage2_mining_candidates.csv"))
    readr::write_csv(mining_coverage,
                     file.path(interim, "stage2_mining_coverage.csv"))

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
          n_mined_candidates = sum(mining_candidates$record_id %in% ep_rows$record_id),
          n_multi_recipient_candidates = sum(
            multi_recipient$record_id %in% ep_rows$record_id
          ),
          n_new              = sum(ep_rows$change_status == "NEW"),
          n_changed          = sum(ep_rows$change_status == "CHANGED"),
          n_unchanged        = sum(ep_rows$change_status == "UNCHANGED"),
          allotment_anchor_available = allotment_anchor_available,
          run_type           = run_type,
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
    mining_candidates = mining_candidates,
    mining_coverage = mining_coverage,
    multi_recipient = multi_recipient,
    tier1_corroboration = tier1_corroboration,
    tier1_state_summary = tier1_state_summary,
    reclassified = reclassified,
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
#   Rscript R/02_normalize.R --run --dev           # an iteration, logged DEV
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

    rhtp_normalize_pull(
      pull_date = pull_date,
      # §5.2: an intermediate iteration must be able to say so, or the manifest
      # cannot tell a throwaway run from the build of record.
      run_type = if ("--dev" %in% cli_args) "DEV" else "PRODUCTION"
    )
  }
}

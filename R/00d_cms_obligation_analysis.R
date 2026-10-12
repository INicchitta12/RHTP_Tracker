#!/usr/bin/env Rscript
# 00d_cms_obligation_analysis.R -----------------------------------------------
#
# WHAT CMS'S OBLIGATION REPORT SAYS ABOUT OUR FILES (session 97). Reads the
# tables R/00c parsed and writes three REPORT files. It codes nothing, adds no
# award row, and moves no dollar into any hospital bucket.
#
#   1. cms_obligation_name_matches.csv -- one row per (state, organisation)
#      named in a bullet: MATCHED_EXACT / CANDIDATE_FUZZY / NEW against our
#      state award files (STATE_FILES in tests/testthat/test_state_union.R),
#      the amount comparison where it is meaningful, and the screen against
#      CMS's Hospital and FQHC Enrollment files. A fuzzy match is a CANDIDATE
#      and never resolves (§2).
#   2. cms_obligation_hospital_purpose.csv -- bullets that DESIGNATE hospitals
#      but name no recipient (California's $35M for strategically located
#      hospitals, Illinois's $14M). A LEAD layer: eligibility is not receipt
#      (§0.3), and a setting is not a recipient (§0.3a). Never in a bucket.
#   3. cms_obligation_gap_by_state.csv -- CMS obligated against our published
#      Tier 3 total, largest gap first: the roster-hunting list. The two
#      figures are DIFFERENT KINDS of number (obligation by activity, self-
#      reported, vs. state-published awards) and the gap is a ranking device,
#      never a dollar finding.
#
# Usage:
#   Rscript R/00d_cms_obligation_analysis.R --build
#   Rscript R/00d_cms_obligation_analysis.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr); library(tidyr)
})
source(here::here("R", "utils_config.R"))

OBLA_LINES   <- here::here("data", "reference", "cms_obligations_bp1_lines.csv")
OBLA_STATE   <- here::here("data", "reference", "cms_obligations_bp1_state.csv")
OBLA_MATCH   <- here::here("data", "reference", "cms_obligation_name_matches.csv")
OBLA_PURPOSE <- here::here("data", "reference", "cms_obligation_hospital_purpose.csv")
OBLA_GAP     <- here::here("data", "reference", "cms_obligation_gap_by_state.csv")

# Names that read as hospitals, for the decision lists only. The CMS
# enrolment screen is the record; this is what puts a line in front of a
# human, and every line it selects was read (session 97 doc).
OBLA_HOSPITAL_NAME <- paste0(
  "\\b(Hospital|Hospitals|Medical Center|Health System|CHI Health|Guthrie Clinic|",
  "Mayo Clinic|Regional West|Bryan Medical|Faith Regional)\\b")
OBLA_HOSPITAL_ASSOC <- "\\b(Hospital Association|Hospital Association of)\\b"
OBLA_STATE_AGENCY <- paste0(
  "^(Ohio Department|Ohio Board|Maine Department|Rhode Island Department|RIDOH|RIDE|",
  "EOHHS|Executive Office|BHDDH|Behavioral Healthcare, Developmental|DLT|",
  "Department of Labor|Office of the Health Insurance|OHIC|Department of State Health|",
  "Health and Human Services Commission|Tennessee Department|TDH|TennCare|",
  "NC Department|Oklahoma Health Care Authority|Virginia DMAS|Division of Medicaid)")

#' The award files the project publishes, read from the union test's own list
obla_state_files <- function() {
  src <- readLines(here::here("tests", "testthat", "test_state_union.R"), warn = FALSE)
  a <- grep("^STATE_FILES <- c\\(", src)
  b <- a - 1L + which(src[a:length(src)] == ")")[1]
  files <- eval(parse(text = paste(src[a:b], collapse = "\n")))
  dplyr::bind_rows(lapply(names(files), function(k) {
    readr::read_csv(here::here(files[[k]]), show_col_types = FALSE, progress = FALSE,
                    col_types = readr::cols(.default = "c")) %>%
      dplyr::transmute(state, file_key = k, awardee, amount = suppressWarnings(as.numeric(amount)),
                       distributed_to_hospital,
                       hospital_attribution = if ("hospital_attribution" %in% names(.)) hospital_attribution else NA_character_)
  }))
}

#' A comparison key for an organisation name
obla_norm <- function(x) {
  x %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("\\([^)]*\\)", " ") %>%
    stringr::str_replace_all("&", " and ") %>%
    stringr::str_replace_all("\\bst\\.?\\s", "saint ") %>%
    stringr::str_replace_all("\\bdept\\b\\.?", "department") %>%
    stringr::str_replace_all("[^a-z0-9 ]", " ") %>%
    stringr::str_replace_all("\\b(the|inc|incorporated|llc|llp|corp|corporation|co|payments?)\\b", " ") %>%
    stringr::str_squish()
}

#' Expand an acronym to the full name the same state's lines define it as
#'
#' Rhode Island writes "Hospital Association of Rhode Island (HARI)" once and
#' "HARI" thereafter; Pennsylvania "Wellspan Waynesboro Hospital (WWH)".
obla_alias_map <- function(orgs) {
  m <- stringr::str_match(orgs$org, "^(.+?)\\s*\\(([A-Z][A-Za-z-]*[A-Z])\\)(.*)$")
  tibble::tibble(state = orgs$state, acronym = m[, 3],
                 full = stringr::str_squish(paste0(m[, 2], m[, 4]))) %>%
    dplyr::filter(!is.na(acronym)) %>%
    dplyr::distinct(state, acronym, .keep_all = TRUE)
}

#' Organisations named per bullet, one row each
obla_orgs <- function(lines = readr::read_csv(OBLA_LINES, show_col_types = FALSE)) {
  o <- lines %>%
    dplyr::filter(!is.na(named_orgs)) %>%
    dplyr::mutate(n_named = stringr::str_count(named_orgs, "; ") + 1L) %>%
    tidyr::separate_rows(named_orgs, sep = "; ") %>%
    dplyr::rename(org = named_orgs)
  al <- obla_alias_map(o)
  o %>%
    dplyr::left_join(al, by = c("state", "org" = "acronym")) %>%
    dplyr::mutate(org_full = stringr::str_squish(stringr::str_remove(dplyr::coalesce(full, org),
                                                                     "\\s*\\([A-Z][A-Za-z-]*[A-Z]\\)")),
                  org_key = obla_norm(org_full),
                  # A line naming one organisation and no "N other
                  # organizations" is the only kind whose amount belongs to
                  # one recipient. Hawaii's amounts are not usable at all.
                  # n_unnamed_others = -1 means "others, count not printed".
                  single_recipient = n_named == 1L & n_unnamed_others == 0L,
                  amount_attributable = dplyr::if_else(single_recipient & amount_usable, amount, NA_real_)) %>%
    dplyr::select(-full)
}

obla_read_enrolment <- function(kind, st) {
  hits <- sort(list.files(here::here("data", "evidence"),
                          pattern = paste0("cms_", kind, "_enrollments_", st, "\\.json$"),
                          recursive = TRUE, full.names = TRUE))
  if (!length(hits)) return(NULL)
  f <- hits[length(hits)]
  j <- jsonlite::fromJSON(f)
  if (!length(j)) return(NULL)
  tibble::tibble(org_name = j[["ORGANIZATION NAME"]], dba = j[["DOING BUSINESS AS NAME"]],
                 ccn = j[["CCN"]], provider_type = j[["PROVIDER TYPE TEXT"]],
                 file = sub(paste0(here::here(), "/"), "", f, fixed = TRUE)) %>%
    dplyr::mutate(kind = kind)
}

#' Screen an organisation against CMS Hospital and FQHC enrolment
obla_enrolment_screen <- function(orgs) {
  states <- unique(orgs$state)
  enr <- dplyr::bind_rows(lapply(states, function(st) {
    dplyr::bind_rows(obla_read_enrolment("hosp", st), obla_read_enrolment("fqhc", st)) %>%
      dplyr::mutate(state = st)
  }))
  have <- enr %>% dplyr::distinct(state, kind)
  enr <- enr %>% dplyr::mutate(k_org = obla_norm(org_name), k_dba = obla_norm(dba))
  res <- lapply(seq_len(nrow(orgs)), function(i) {
    st <- orgs$state[i]; k <- obla_norm(orgs$org_full[i])
    e <- enr[enr$state == st, , drop = FALSE]
    hit <- e[e$k_org == k | (nzchar(e$k_dba) & e$k_dba == k), , drop = FALSE]
    basis <- if (nrow(hit)) dplyr::if_else(any(hit$k_org == k), "EXACT_LEGAL_NAME", "EXACT_DBA") else NA_character_
    if (!nrow(hit) && nchar(k) >= 12) {
      cand <- e[stringr::str_detect(e$k_org, stringr::fixed(k)) |
                  (nzchar(e$k_dba) & stringr::str_detect(e$k_dba, stringr::fixed(k))), , drop = FALSE]
      if (nrow(cand)) { hit <- cand; basis <- "CANDIDATE_CONTAINS" }
    }
    screened <- paste(sort(unique(have$kind[have$state == st])), collapse = "+")
    if (!nrow(hit)) {
      return(tibble::tibble(enrolment_match = if (nzchar(screened)) "NONE" else "NOT_SCREENED_NO_FILE",
                            enrolment_kind = NA_character_, enrolment_name = NA_character_,
                            enrolment_ccn = NA_character_, enrolment_screened = screened,
                            enrolment_file = NA_character_))
    }
    hit <- hit %>% dplyr::arrange(kind != "hosp", ccn)
    tibble::tibble(enrolment_match = basis,
                   enrolment_kind = paste(unique(hit$kind), collapse = "+"),
                   enrolment_name = paste(unique(paste0(hit$org_name, dplyr::if_else(nzchar(hit$dba), paste0(" dba ", hit$dba), ""))), collapse = " | "),
                   enrolment_ccn = paste(unique(hit$ccn[nzchar(hit$ccn)]), collapse = " | "),
                   enrolment_screened = screened,
                   enrolment_file = paste(unique(hit$file), collapse = " | "))
  })
  dplyr::bind_cols(orgs, dplyr::bind_rows(res))
}

#' Task 4: every named organisation against our files and CMS enrolment
obla_name_matches <- function(orgs = obla_orgs(), files = obla_state_files()) {
  f <- files %>% dplyr::mutate(k = obla_norm(awardee)) %>% dplyr::filter(nzchar(k))
  per_org <- orgs %>%
    dplyr::group_by(state, org_key) %>%
    dplyr::summarise(
      org_full = dplyr::first(org_full),
      printed_as = paste(unique(org), collapse = " | "),
      line_ids = paste(line_id, collapse = " "),
      n_lines = dplyr::n(),
      n_single_recipient_lines = sum(single_recipient),
      cms_amount_single_recipient = sum(amount_attributable, na.rm = TRUE),
      cms_amount_on_multi_recipient_lines = sum(dplyr::if_else(!single_recipient & amount_usable, amount, 0)),
      .groups = "drop") %>%
    dplyr::mutate(k = org_key)

  ours <- lapply(seq_len(nrow(per_org)), function(i) {
    st <- per_org$state[i]; k <- per_org$k[i]
    fs <- f[f$state == st, , drop = FALSE]
    ex <- fs[fs$k == k, , drop = FALSE]
    status <- "NEW"; m <- ex
    if (nrow(ex)) status <- "MATCHED_EXACT" else if (nchar(k) >= 10) {
      cand <- fs[(stringr::str_detect(fs$k, stringr::fixed(k)) | stringr::str_detect(k, stringr::fixed(fs$k))) &
                   nchar(fs$k) >= 10, , drop = FALSE]
      if (nrow(cand)) { status <- "CANDIDATE_FUZZY"; m <- cand }
    }
    tibble::tibble(file_match = status,
                   our_files = if (nrow(m)) paste(unique(m$file_key), collapse = " | ") else NA_character_,
                   our_awardee = if (nrow(m)) paste(unique(m$awardee), collapse = " | ") else NA_character_,
                   our_rows = nrow(m),
                   our_amount = if (nrow(m) && any(!is.na(m$amount))) sum(m$amount, na.rm = TRUE) else NA_real_,
                   our_hospital_attribution = if (nrow(m)) paste(unique(stats::na.omit(m$hospital_attribution)), collapse = " | ") else NA_character_)
  })
  out <- dplyr::bind_cols(per_org, dplyr::bind_rows(ours))
  out <- obla_enrolment_screen(out %>% dplyr::rename(org = printed_as) %>% dplyr::mutate(org_full = org_full)) %>%
    dplyr::rename(printed_as = org)
  out %>%
    dplyr::mutate(
      amount_status = dplyr::case_when(
        file_match != "MATCHED_EXACT" ~ "NOT_COMPARED",
        state == "HI" ~ "NOT_COMPARED_HI_BULLETS_UNUSABLE",
        n_single_recipient_lines == 0L ~ "NOT_COMPARABLE_MULTI_RECIPIENT_ONLY",
        is.na(our_amount) ~ "OUR_FILE_UNPRICED",
        abs(cms_amount_single_recipient - our_amount) < 1 ~ "AGREES",
        TRUE ~ "AMOUNT_DISAGREES"),
      amount_diff_cms_minus_ours = dplyr::if_else(amount_status == "AMOUNT_DISAGREES",
                                                  round(cms_amount_single_recipient - our_amount, 2), NA_real_),
      name_reads_hospital = stringr::str_detect(org_full, OBLA_HOSPITAL_NAME) &
        !stringr::str_detect(org_full, "Foundation$|^University|^Region [0-9]"),
      reads_state_agency = stringr::str_detect(org_full, OBLA_STATE_AGENCY),
      name_reads_hospital_association = stringr::str_detect(org_full, OBLA_HOSPITAL_ASSOC),
      hospital_signal = dplyr::case_when(
        # A state agency that holds a hospital enrolment (Texas DSHS and
        # HHSC run the state hospitals) is the agency, not a hospital
        # recipient: §10.2's enrolled-operator rule is about the AWARDEE.
        reads_state_agency ~ NA_character_,
        # A university is a hospital only on an EXACT enrolment of its legal
        # name (§10.2); "contains" is never enough (UW, Creighton).
        stringr::str_detect(org_full, "University") & !enrolment_match %in% c("EXACT_LEGAL_NAME", "EXACT_DBA") ~ NA_character_,
        enrolment_match %in% c("EXACT_LEGAL_NAME", "EXACT_DBA") & stringr::str_detect(dplyr::coalesce(enrolment_kind, ""), "hosp") ~ "CMS_HOSPITAL_ENROLMENT_EXACT",
        name_reads_hospital_association ~ "HOSPITAL_ASSOCIATION_BY_NAME",
        enrolment_match == "CANDIDATE_CONTAINS" & stringr::str_detect(dplyr::coalesce(enrolment_kind, ""), "hosp") ~ "CMS_HOSPITAL_ENROLMENT_CANDIDATE",
        name_reads_hospital ~ "NAME_ONLY",
        TRUE ~ NA_character_),
      tier = "SUBAWARD_OBLIGATION_NOT_AN_AWARD_ROW",
      as_of = as.Date("2026-07-31")) %>%
    dplyr::select(state, org_full, org_key, printed_as, line_ids, n_lines, n_single_recipient_lines,
                  cms_amount_single_recipient, cms_amount_on_multi_recipient_lines,
                  file_match, our_files, our_awardee, our_rows, our_amount, amount_status,
                  amount_diff_cms_minus_ours, our_hospital_attribution, enrolment_match,
                  enrolment_kind, enrolment_name, enrolment_ccn, enrolment_screened,
                  enrolment_file, hospital_signal, reads_state_agency, tier, as_of) %>%
    dplyr::arrange(state, org_full)
}

#' The two decision lists (a) and (b), line by line, with dollars
obla_decision_lists <- function(orgs = obla_orgs(), matches = obla_name_matches(orgs)) {
  sig <- matches %>% dplyr::select(state, org_key, hospital_signal, file_match, our_awardee,
                                   our_amount, enrolment_ccn, enrolment_name)
  o <- orgs %>% dplyr::left_join(sig, by = c("state", "org_key")) %>%
    dplyr::filter(!is.na(hospital_signal))
  a <- o %>% dplyr::filter(single_recipient) %>%
    dplyr::transmute(list = "A_SINGLE_RECIPIENT", line_id, state, org = org_full, amount,
                     hospital_signal, enrolment_ccn, file_match, our_awardee, our_amount,
                     description_clean)
  b_lines <- unique(o$line_id[!o$single_recipient])
  b <- orgs %>% dplyr::filter(line_id %in% b_lines) %>%
    dplyr::left_join(sig %>% dplyr::select(state, org_key, hospital_signal), by = c("state", "org_key")) %>%
    dplyr::group_by(line_id, state, amount, description_clean, n_unnamed_others) %>%
    dplyr::summarise(orgs = paste(org_full, collapse = "; "),
                     hospitals = paste(org_full[!is.na(hospital_signal)], collapse = "; "),
                     .groups = "drop") %>%
    dplyr::transmute(list = "B_MULTI_RECIPIENT_UNSPLITTABLE", line_id, state, org = orgs,
                     hospitals, n_unnamed_others, amount, description_clean)
  list(a = a, b = b)
}

# -- Task 5: the hospital-purpose layer ---------------------------------------
#
# A bullet that names NO recipient but DESIGNATES hospitals as where the
# money goes. "DESIGNATES" is a phrase test, not a judgement: hospitals are the
# object of the money ("for hospitals to", "payments for ... hospitals",
# "grants to ... hospitals", "hospital equipment"). A bullet that only
# MENTIONS hospitals ("partnering with rural hospitals and health centers") is
# kept at the weaker label so a reader can see the whole lead set.
OBLA_DESIGNATES <- paste0(
  "(\\bfor (rural |small rural |critical access |strategically located |participating |",
  "independent |eligible |anchor |local |community |safety net )*(hospitals?|CAHs?)\\b|",
  "\\bto (rural |small rural |critical access |participating |eligible |anchor )*(hospitals?|CAHs?)\\b|",
  "\\b(hospitals?|CAHs?) (to|for) [a-z]|",
  "Strategically Located Hospitals|Critical Access Hospital|\\bCAH\\b|",
  "\\bacross (rural )?hospitals\\b|\\bat a (rural )?[a-z ]{0,30}hospital\\b|\\b[0-9]+ hospitals\\b|",
  "\\bhospital (equipment|infrastructure|capital|grants?|payments?|stabili[sz]ation|",
  "partners?|participation|incentives?|transformation)\\b|robotic|",
  "(payments?|grants?|awards?|stabili[sz]ation|incentives?|funding) (to|for) [^.]{0,60}hospitals?\\b)")
OBLA_MENTIONS <- "\\b(hospitals?|CAHs?|Critical Access|REH|Rural Emergency Hospital)\\b"

# Lines whose PROGRAMME designates hospitals although the bullet text does not
# say so. Each is tied to a document this repository already holds.
OBLA_PURPOSE_BY_PROGRAMME <- tibble::tribble(
  ~state, ~initiative_pattern, ~category_pattern, ~description_pattern, ~reason,
  "IA", "^Initiative 1: Hometown", "^(Appropriate Care Availability|Capital Expenditures)", ".",
  "Iowa's Best and Brightest Medical Equipment RFPs (PHTHORC26009, PHTHORC26011): 80 award actions, 78 of them named hospitals in ia_year1_awardees.csv, no per-recipient amount",
  "WA", "^Initiative 1", "^Innovative Care", "critical technology infrastructure",
  "WA Initiative 1's $41,993,047 technology line sits beside WSHA's $42M in wa_year1_awardees.csv (WA_WSHA_FLOW, Unclear)"
)

obla_hospital_purpose <- function(lines = readr::read_csv(OBLA_LINES, show_col_types = FALSE)) {
  prog <- rep(NA_character_, nrow(lines))
  for (k in seq_len(nrow(OBLA_PURPOSE_BY_PROGRAMME))) {
    r <- OBLA_PURPOSE_BY_PROGRAMME[k, ]
    hit <- lines$state == r$state & stringr::str_detect(dplyr::coalesce(lines$initiative, ""), r$initiative_pattern) &
      stringr::str_detect(dplyr::coalesce(lines$category, ""), r$category_pattern) &
      stringr::str_detect(lines$description_clean, r$description_pattern)
    prog[hit] <- r$reason
  }
  lines$programme_basis <- prog
  lines %>%
    dplyr::filter(is.na(named_orgs),
                  stringr::str_detect(description_clean, stringr::regex(OBLA_MENTIONS, ignore_case = TRUE)) |
                    !is.na(programme_basis)) %>%
    dplyr::mutate(
      designation = dplyr::case_when(
        stringr::str_detect(description_clean, stringr::regex(OBLA_DESIGNATES, ignore_case = TRUE)) ~ "DESIGNATES_HOSPITALS",
        !is.na(programme_basis) ~ "DESIGNATES_HOSPITALS_BY_PROGRAMME",
        TRUE ~ "MENTIONS_HOSPITALS"),
      matched_phrase = stringr::str_extract(description_clean, stringr::regex(OBLA_DESIGNATES, ignore_case = TRUE)),
      amount_for_reading = dplyr::if_else(amount_usable, amount, NA_real_),
      layer = "LEAD_ONLY_NEVER_IN_A_BUCKET") %>%
    dplyr::select(line_id, state, initiative, category, category_total, amount = amount_for_reading,
                  amount_usable, designation, matched_phrase, programme_basis, description_clean, layer, as_of) %>%
    dplyr::arrange(designation, dplyr::desc(amount))
}

# -- Task 6: CMS obligated against our published Tier 3 total -----------------
obla_gap <- function(files = obla_state_files(),
                     st = readr::read_csv(OBLA_STATE, show_col_types = FALSE),
                     lines = readr::read_csv(OBLA_LINES, show_col_types = FALSE)) {
  ours <- files %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(our_files = paste(unique(file_key), collapse = " | "),
                     our_rows = dplyr::n(),
                     our_priced_rows = sum(!is.na(amount)),
                     our_tier3_sum_amount = sum(amount, na.rm = TRUE),
                     our_named_hospital_amount = sum(amount[hospital_attribution %in% "NAMED_HOSPITAL"], na.rm = TRUE),
                     .groups = "drop")
  named <- lines %>% dplyr::group_by(state) %>%
    dplyr::summarise(cms_lines = dplyr::n(),
                     cms_lines_naming_recipient = sum(!is.na(named_orgs)),
                     cms_amount_on_named_lines = sum(amount[!is.na(named_orgs) & amount_usable]),
                     .groups = "drop")
  completion <- readr::read_csv(here::here("data", "reference", "year1_completion_status.csv"),
                                show_col_types = FALSE, col_types = readr::cols(.default = "c"))
  comp <- completion %>%
    dplyr::transmute(state, year1_completion = year1_status,
                     our_published_incl_pool_level = as.numeric(published_incl_pool_level))
  st %>%
    dplyr::select(state, bp1_award, funds_put_to_work, share_put_to_work) %>%
    dplyr::left_join(ours, by = "state") %>%
    dplyr::left_join(named, by = "state") %>%
    dplyr::left_join(comp, by = "state") %>%
    dplyr::mutate(our_tier3_sum_amount = dplyr::coalesce(our_tier3_sum_amount, 0),
                  our_rows = dplyr::coalesce(our_rows, 0L),
                  # Georgia, Oregon, Nevada, South Dakota hold pools at pool
                  # level (round_amount), which sum(amount) misses; the
                  # completion table carries them. The larger of the two is
                  # what this project has published for the state.
                  our_published_tier3 = pmax(our_tier3_sum_amount,
                                             dplyr::coalesce(our_published_incl_pool_level, 0)),
                  our_published_basis = dplyr::if_else(our_published_tier3 > our_tier3_sum_amount,
                                                       "year1_completion_status.published_incl_pool_level",
                                                       "sum(amount) over STATE_FILES"),
                  gap_cms_obligated_minus_ours = round(funds_put_to_work - our_published_tier3, 2),
                  comparability = "DIFFERENT_KINDS: CMS = state-reported obligation by activity as of 2026-07-31 (all tiers below the allotment); ours = state-published Tier 3 awards, any date. A ranking device, never a dollar finding.") %>%
    dplyr::arrange(dplyr::desc(gap_cms_obligated_minus_ours)) %>%
    dplyr::mutate(hunt_rank = dplyr::row_number()) %>%
    dplyr::relocate(hunt_rank)
}

obla_build <- function() {
  orgs <- obla_orgs()
  m <- obla_name_matches(orgs)
  readr::write_csv(m, OBLA_MATCH, na = "")
  readr::write_csv(obla_hospital_purpose(), OBLA_PURPOSE, na = "")
  readr::write_csv(obla_gap(), OBLA_GAP, na = "")
  dl <- obla_decision_lists(orgs, m)
  readr::write_csv(dplyr::bind_rows(dl$a, dl$b),
                   here::here("data", "reference", "cms_obligation_hospital_decision_lists.csv"), na = "")
  message("[CMS obligations] wrote name matches (", nrow(m), "), hospital purpose, gap, decision lists")
}

obla_report <- function() {
  m <- readr::read_csv(OBLA_MATCH, show_col_types = FALSE)
  print(m %>% dplyr::count(file_match, amount_status), n = Inf)
  print(m %>% dplyr::count(hospital_signal), n = Inf)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) obla_build()
  if ("--report" %in% args) obla_report()
  if (!length(args)) message("Usage: --build | --report")
}

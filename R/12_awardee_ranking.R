# 12_awardee_ranking.R ---------------------------------------------------------
# Session 125. THE AWARDEE RANKING: EVERY YEAR 1 AWARDEE BY TOTAL AWARD DOLLARS,
# AN AWARDEE'S AWARDS IN SEVERAL STATES SUMMED INTO ONE LINE (owner direction,
# 2026-11-24). CLAUDE.md §7, "Awardee identity and the ranking".
#
# IDENTITY IS THE WHOLE JOB. A first pass on 11-23 data that matched on
# normalised names found 30 "multi-state" names, and many were different
# organisations sharing a name (Memorial Health System KS/MS, Community Memorial
# Hospital NY/SD, Memorial Medical Center IL/TX, County of Clay IL/TX, Family
# Health Centers CA/SC, Wayne Memorial Hospital GA/PA). It also missed real
# matches written differently ("Comagine" vs "COMAGINE HEALTH"). A NAME IS
# NEVER ENOUGH TO JOIN TWO STATES' AWARDS.
#
# THE JOIN RULE. Every Year 1 award row gets an awardee_entity_id. Rows join into
# one entity only on, in order:
#   UEI            the same SAM UEI: a new FSRS row's fsrs_uei, or the UEI of the
#                  row's OWN paired subaward (fsrs_match EXACT / DIFFERS /
#                  PRICED_FROM_FSRS). Sibling and pool-member pointers
#                  (FSRS_PRICED_ON_ROW_n, FSRS_POOL_MEMBER_NOT_PRICED) are never
#                  read as the row's own identifier.
#   EIN            the same EIN (a row's `ein`, Wyoming only so far).
#   CCN            the same CMS CCN (`ccn`, or the CCN recorded in
#                  `cms_enrolment_record`). The same CCN is the same hospital.
#   HAND_REVIEWED  an entry in config/awardee_entities.csv with its basis
#                  quoted (the entity's own site or a federal record showing one
#                  legal entity in both states).
#   SAME_STATE_EXACT_NAME  the same normalised name WITHIN ONE STATE, and never
#                  across states; refused where the two sides carry different
#                  UEIs or different CCNs (different CCNs are different
#                  hospitals: Texas's two "Memorial Hospital" rows).
# No fuzzy match is ever applied. Cross-state name collisions that are not one
# entity are recorded in config/awardee_entities_distinct.csv with the reason.
#
# WHAT IS RANKED. Award amounts only (amount type award; intents included and
# shown separately), Year 1, from STATE_FILES. A CMS obligation-report line is an
# OBLIGATION and sits in its own column, never in the award total; a contract
# file's maximum or obligation (data/reference/contracts/) likewise. NM Accenture
# (ADMINISTRATOR_PASS_THROUGH_UNRESOLVED) is held out, as from every total. A row
# naming several organisations with no split is never divided: it goes to the
# Unattributed pools tab. A pass-through intermediary that received the money
# itself (ICAHN, WSHA, NHVN) ranks as the awardee, flagged PASS_THROUGH.
# Unpriced rows are counted, never ranked on.
#
# SESSION 125b (owner audit of the team copy, 2026-11-25):
#   DELAWARE IS NOT CONFIDENTIAL (owner ruling 2026-11-25). Delaware rows appear in
#     every tab and total; the team copy is the same workbook. A row citing the
#     owner-supplied DE Verify.xlsx is flagged owner_supplied_source (none does).
#   SECOND TIER. An intermediary's own subgrants that are also priced rows are
#     SECOND_TIER_OF its first-tier row (config/second_tier_rows.csv, R/08): role
#     SECOND_TIER, never ranked, never in the ranking total or its reconciliation,
#     listed on the "Second-tier recipients" tab. The intermediary ranks at its
#     first-tier amount.
#   NAMES. The within-state name key reads "A DBA B" and "B DBA A" as one name and
#     lets either half of a DBA string match the same half printed alone (still
#     refused where UEIs or CCNs differ). Same-state hand joins (one legal body,
#     several hospitals) are SAME_STATE_LEGAL_BODY entries. Lines that share a
#     printed name but are different entities carry a display_name label (UEI legal
#     name and city, or the CCN's facility and city).
#   READER COLUMNS. organisation_type (a plain label; "Organisation (form not
#     stated)" wherever the form is the RECIPIENT_TYPE_INFERRED fallback, never
#     "Nonprofit"), and a "Read first" tab.
#
# Usage:
#   Rscript R/12_awardee_ranking.R --build [YYYY-MM-DD]  # data/reference/awardee_*.csv and
#                                                       # output/awardee_ranking_<date>{,_team}.xlsx
#   Rscript R/12_awardee_ranking.R --validate           # identity rules + reconciliation, writes nothing
#   Rscript R/12_awardee_ranking.R --candidates         # cross-state review candidates (prints)

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "08_year1_summary.R"))

AW_ENTITIES    <- "config/awardee_entities.csv"
AW_DISTINCT    <- "config/awardee_entities_distinct.csv"
AW_UNATTRIB    <- "config/awardee_unattributed_rows.csv"
AW_NOT_OWN_UEI <- "config/awardee_uei_not_own.csv"   # rows whose paired subaward is filed to another legal entity
AW_PARENTS     <- "config/awardee_parent_systems.csv"
AW_FSRS_REC    <- "data/reference/fsrs_subaward_records.csv"
AW_CONTRACTS   <- "data/reference/contracts"
AW_OUT_ROWS    <- "data/reference/awardee_entity_rows.csv"
AW_OUT_RANK    <- function(date) file.path("data", "reference", paste0("awardee_ranking_", date, ".csv"))
AW_OUT_XLSX    <- function(date, team = FALSE) file.path("output", paste0("awardee_ranking_", date,
                                                                          if (team) "_team" else "", ".xlsx"))
AW_BASES <- c("UEI", "EIN", "CCN", "HAND_REVIEWED", "SAME_STATE_EXACT_NAME", "SINGLE_ROW")
AW_OWN_FSRS_MATCH <- c("EXACT", "DIFFERS", "PRICED_FROM_FSRS")
AW_PT_FLOWS <- c("PASS_THROUGH_DESIGNATED", "PASS_THROUGH_UNRESOLVED")

# The legal-form tokens dropped from the END of a name before the within-state
# comparison (a closed list; nothing else is dropped).
AW_LEGAL_SUFFIX <- c("INC", "INCORPORATED", "LLC", "L L C", "LLP", "CORP", "CORPORATION", "CO", "LTD", "PC",
                     "PLLC", "PA", "LP", "NPC")

aw_norm_part <- function(x) {
  x <- stringr::str_squish(x)
  x <- sub("^THE ", "", x)
  pat <- paste0(" (", paste(AW_LEGAL_SUFFIX, collapse = "|"), ")$")
  for (i in 1:3) x <- sub(pat, "", x)
  stringr::str_squish(x)
}

#' The normalised name: upper case, '&' as AND, punctuation (hyphens included)
#' and parenthesised text removed, a leading THE and trailing legal-form tokens
#' dropped. SESSION 125b: a "DBA" string (dba, d/b/a, d.b.a.) is split into its
#' halves, each normalised, and the halves sorted, so "A DBA B" and "B DBA A" are
#' one name (VT's Five-Town Health Alliance / Mountain Community Health).
aw_norm <- function(x) {
  x <- toupper(dplyr::coalesce(x, ""))
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("\\(.*?\\)", " ", x)
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- stringr::str_squish(x)
  x <- gsub("\\bD B A\\b", "DBA", x)
  vapply(strsplit(x, " DBA ", fixed = TRUE), function(p) {
    p <- aw_norm_part(p); p <- p[p != "" & p != "DBA"]
    paste(sort(unique(p)), collapse = " DBA ")
  }, character(1), USE.NAMES = FALSE)
}

#' The within-state name keys of a normalised name: the whole name and, for a
#' DBA string, each half (so "AHS Hospital Corp DBA X" also meets "AHS Hospital
#' Corp"); every join is still refused where UEIs or CCNs differ
aw_name_keys <- function(norm) {
  lapply(norm, function(z) {
    if (is.na(z) || z == "") return(character(0))
    parts <- strsplit(z, " DBA ", fixed = TRUE)[[1]]
    unique(c(z, if (length(parts) > 1) parts))
  })
}

aw_ccn_norm <- function(x) {
  x <- toupper(stringr::str_squish(dplyr::coalesce(x, "")))
  dplyr::if_else(grepl("^[0-9]{2}[0-9A-Z]{4}$", x), x, NA_character_)
}

# -- 1. the rows ---------------------------------------------------------------------

#' Every Year 1 award row in STATE_FILES with the columns the ranking reads
aw_rows <- function(files = sc_state_files()) {
  rec <- readr::read_csv(here::here(AW_FSRS_REC), col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         progress = FALSE) %>% dplyr::select(fsrs_id, uei)
  out <- dplyr::bind_rows(lapply(names(files), function(k) {
    d <- readr::read_csv(here::here(files[[k]]), col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         progress = FALSE)
    d <- rhtp_year1_only(d, k)
    col <- function(c) if (c %in% names(d)) d[[c]] else rep(NA_character_, nrow(d))
    tibble::tibble(
      file_key = k, file = files[[k]], row_index = seq_len(nrow(d)), row_no = col("row_no"),
      state = d$state, awardee = stringr::str_squish(d$awardee),
      amount = suppressWarnings(as.numeric(d$amount)),
      recipient_type = col("recipient_type"), flow_type = col("flow_type"),
      hospital_attribution = col("hospital_attribution"), distributed_to_hospital = col("distributed_to_hospital"),
      intermediary_name = col("intermediary_name"), flag_reason = col("flag_reason"),
      validation_source_type = col("validation_source_type"),
      contract_number = col("contract_number"), ccn_raw = col("ccn"), cms_enrolment_record = col("cms_enrolment_record"), ein = col("ein"),
      fsrs_uei = col("fsrs_uei"), fsrs_match = col("fsrs_match"), fsrs_subaward_ids = col("fsrs_subaward_ids"),
      summary_hospital_call = col("summary_hospital_call"), spend_category = col("spend_category"),
      vendor_verified = col("vendor_verified"), out_of_state = col("out_of_state"),
      use_group_primary = col("use_group_primary"), recipient_subtype = col("recipient_subtype"),
      determination_confidence = col("determination_confidence"),
      owner_supplied_hit = ys_owner_supplied_hit(d))
  }))
  # UEI of the row's OWN paired subaward(s)
  own <- out %>% dplyr::mutate(.i = dplyr::row_number()) %>%
    dplyr::filter(fsrs_match %in% AW_OWN_FSRS_MATCH, !is.na(fsrs_subaward_ids)) %>%
    dplyr::select(.i, fsrs_subaward_ids) %>%
    tidyr::separate_rows(fsrs_subaward_ids, sep = ";") %>%
    dplyr::left_join(rec, by = c("fsrs_subaward_ids" = "fsrs_id")) %>%
    dplyr::filter(!is.na(uei), uei != "") %>%
    dplyr::group_by(.i) %>% dplyr::summarise(paired_uei = paste(sort(unique(uei)), collapse = ";"), .groups = "drop")
  out <- out %>% dplyr::mutate(.i = dplyr::row_number()) %>% dplyr::left_join(own, by = ".i") %>%
    dplyr::select(-.i)
  # a paired subaward filed to a DIFFERENT legal entity (a pass-through) is not
  # the row's own identifier (OK Findhelp / OHCA; independent check)
  no <- aw_read_cfg(AW_NOT_OWN_UEI, c("file_key", "awardee", "reason"))
  out$paired_uei[paste(out$file_key, out$awardee) %in% paste(no$file_key, no$awardee)] <- NA_character_
  # South Dakota's register prints the state's contract number, which is the
  # subaward number on SD's own FSRS filing: the UEI of that filing is the
  # row's own (a federal record for the same agreement; independent check:
  # Sanford Health Network and Avera McKennan rows had gone unpaired)
  sdr <- readr::read_csv(here::here(AW_FSRS_REC), col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         progress = FALSE) %>% dplyr::filter(st == "SD", !is.na(uei)) %>%
    dplyr::group_by(subaward_number) %>% dplyr::filter(dplyr::n_distinct(uei) == 1) %>%
    dplyr::summarise(sd_uei = dplyr::first(uei), .groups = "drop")
  cn <- if ("contract_number" %in% names(out)) out$contract_number else NA_character_
  out$sd_uei <- dplyr::if_else(out$file_key == "SD_CONTRACTS", sdr$sd_uei[match(cn, sdr$subaward_number)], NA_character_)
  out$paired_uei <- dplyr::coalesce(out$paired_uei, out$sd_uei)
  ccn_enrol <- stringr::str_match(dplyr::coalesce(out$cms_enrolment_record, ""), "CCN[ :]*([0-9]{2}[0-9A-Z]{4})")[, 2]
  out %>% dplyr::mutate(
    uei = dplyr::coalesce(dplyr::na_if(fsrs_uei, ""), paired_uei),
    ccn = dplyr::coalesce(aw_ccn_norm(ccn_raw), aw_ccn_norm(ccn_enrol)),
    ein = dplyr::if_else(grepl("^[0-9]{2}-?[0-9]{7}$", dplyr::coalesce(ein, "")), gsub("-", "", ein), NA_character_),
    norm_name = aw_norm(awardee),
    amount_type = dplyr::case_when(
      validation_source_type %in% "CMS_OBLIGATION_REPORT" ~ "obligation",
      validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD" ~ "intent",
      TRUE ~ "award"),
    owner_supplied_source = owner_supplied_hit,
    second_tier_of = ys_second_tier_of(file_key, awardee),
    row_id = paste0(file_key, "#", row_index))
}

#' Which rows are ranked, held out or unattributed
aw_roles <- function(rows, unattrib = aw_unattributed_config()) {
  hand_un <- paste(unattrib$file_key, unattrib$awardee)
  rows %>% dplyr::mutate(role = dplyr::case_when(
    ys_has(flag_reason, YS_EXCLUDED_FLAG) ~ "HELD_OUT_ADMINISTRATOR",
    !is.na(second_tier_of) ~ "SECOND_TIER",
    ys_has(flag_reason, "MULTI_RECIPIENT_FIELD") ~ "UNATTRIBUTED_POOL",
    recipient_type %in% "NOT_YET_NAMED" ~ "UNATTRIBUTED_POOL",
    paste(file_key, awardee) %in% hand_un ~ "UNATTRIBUTED_POOL",
    TRUE ~ "RANKED"))
}

aw_read_cfg <- function(path, need) {
  if (!file.exists(here::here(path))) stop("[awardee] missing ", path, call. = FALSE)
  x <- readr::read_csv(here::here(path), col_types = readr::cols(.default = "c"), na = c("", "NA"), progress = FALSE)
  miss <- setdiff(need, names(x))
  if (length(miss)) stop("[awardee] ", path, " lacks: ", paste(miss, collapse = ", "), call. = FALSE)
  x
}
aw_unattributed_config <- function() aw_read_cfg(AW_UNATTRIB, c("file_key", "awardee", "reason"))
aw_hand_config <- function() {
  x <- aw_read_cfg(AW_ENTITIES, c("entity_key", "state", "awardee", "evidence_class", "basis", "source", "reviewer"))
  if (any(is.na(x$basis) | is.na(x$source) | is.na(x$reviewer))) {
    stop("[awardee] every hand-reviewed join needs a quoted basis, a source and a reviewer.", call. = FALSE)
  }
  x
}
aw_distinct_config <- function() aw_read_cfg(AW_DISTINCT, c("norm_name", "states", "reason_type", "reason", "reviewer"))

# -- 2. identity ---------------------------------------------------------------------

#' Union-find over the rows. Returns rows with awardee_entity_id and
#' entity_match_basis.
aw_entities <- function(rows, hand = aw_hand_config()) {
  n <- nrow(rows)
  parent <- seq_len(n)
  find <- function(i) { while (parent[i] != i) { parent[i] <<- parent[parent[i]]; i <- parent[i] }; i }
  basis <- rep(NA_character_, n)
  uei_sets <- lapply(strsplit(dplyr::coalesce(rows$uei, ""), ";", fixed = TRUE), function(z) z[z != ""])
  ccn_sets <- lapply(rows$ccn, function(z) if (is.na(z)) character(0) else z)
  comp_uei <- uei_sets; comp_ccn <- ccn_sets
  merge <- function(i, j, b, check = FALSE) {
    a <- find(i); c <- find(j)
    if (a == c) { if (is.na(basis[i])) basis[i] <<- b; if (is.na(basis[j])) basis[j] <<- b; return(TRUE) }
    if (check) {
      ua <- comp_uei[[a]]; uc <- comp_uei[[c]]; ca <- comp_ccn[[a]]; cc <- comp_ccn[[c]]
      if (length(ua) && length(uc) && !length(intersect(ua, uc))) return(FALSE)
      if (length(ca) && length(cc) && !length(intersect(ca, cc)) && !(length(ua) && length(uc))) return(FALSE)
    }
    parent[c] <<- a
    comp_uei[[a]] <<- union(comp_uei[[a]], comp_uei[[c]])
    comp_ccn[[a]] <<- union(comp_ccn[[a]], comp_ccn[[c]])
    if (is.na(basis[i])) basis[i] <<- b
    if (is.na(basis[j])) basis[j] <<- b
    TRUE
  }
  link_groups <- function(key_list, b, check = FALSE) {
    df <- tibble::tibble(i = rep(seq_len(n), lengths(key_list)), k = unlist(key_list))
    if (!nrow(df)) return(invisible())
    for (g in split(df$i, df$k)) if (length(g) > 1) for (j in g[-1]) merge(g[1], j, b, check)
  }
  link_groups(uei_sets, "UEI")
  link_groups(lapply(rows$ein, function(z) if (is.na(z)) character(0) else z), "EIN")
  # SESSION 125b (independent check): a CCN join is refused where the two rows
  # carry DIFFERENT UEIs AND DIFFERENT normalised names. A row's CCN can rest on
  # an address match to an enrolled hospital (ND Griggs County Nursing Home on
  # Cooperstown's 351306; WV East Mountain Health Physicians on War Memorial's
  # 511309), and two disagreeing federal identifiers on two different names
  # outrank it. One legal name filed under several site UEIs (OSF HEALTHCARE
  # SYSTEM, IL) still joins on its CCN. A hand review can join any pair.
  ccn_df <- tibble::tibble(i = rep(seq_len(n), lengths(ccn_sets)), k = unlist(ccn_sets))
  refused_ccn <- list()
  for (g in split(ccn_df$i, ccn_df$k)) if (length(g) > 1) for (j in g[-1]) {
    ui <- uei_sets[[g[1]]]; uj <- uei_sets[[j]]
    conflict <- length(ui) && length(uj) && !length(intersect(ui, uj)) && rows$norm_name[g[1]] != rows$norm_name[j]
    if (conflict) {
      # try any already-linked member of the group with the same name or UEI first
      alt <- g[g != j & (rows$norm_name[g] == rows$norm_name[j] | vapply(g, function(z) length(intersect(uei_sets[[z]], uj)) > 0, logical(1)))]
      if (length(alt)) merge(alt[1], j, "CCN") else refused_ccn[[length(refused_ccn) + 1]] <- c(rows$row_id[g[1]], rows$row_id[j])
    } else merge(g[1], j, "CCN")
  }
  # hand-reviewed joins, keyed on (state, awardee as printed)
  hk <- paste(hand$state, hand$awardee)
  rk <- paste(rows$state, rows$awardee)
  miss <- hand[!hk %in% rk, ]
  if (nrow(miss)) stop("[awardee] hand-reviewed members not found among Year 1 rows: ",
                       paste(miss$state, miss$awardee, sep = " / ", collapse = "; "), call. = FALSE)
  hand_keys <- lapply(rk, function(z) unique(hand$entity_key[hk == z]))
  k <- table(unlist(hand_keys))
  if (length(hand$entity_key) && any(k < 2 | !unique(hand$entity_key) %in% names(k))) {
    stop("[awardee] a hand-reviewed entity must reach two or more Year 1 rows: ",
         paste(setdiff(unique(hand$entity_key), names(k)[k >= 2]), collapse = ", "), call. = FALSE)
  }
  link_groups(hand_keys, "HAND_REVIEWED")
  # same-state exact normalised name, with the conflict check
  nk <- aw_name_keys(rows$norm_name)
  name_keys <- lapply(seq_len(n), function(i) if (length(nk[[i]])) paste(rows$state[i], nk[[i]]) else character(0))
  refused <- list()
  df <- tibble::tibble(i = rep(seq_len(n), lengths(name_keys)), k = unlist(name_keys))
  for (g in split(df$i, df$k)) if (length(g) > 1) for (j in g[-1]) {
    ok <- merge(g[1], j, "SAME_STATE_EXACT_NAME", check = TRUE)
    if (!ok) refused[[length(refused) + 1]] <- c(rows$row_id[g[1]], rows$row_id[j])
  }
  root <- vapply(seq_len(n), find, integer(1))
  basis[is.na(basis)] <- "SINGLE_ROW"
  rows$root <- root
  rows$entity_match_basis <- basis
  # entity id: UEI, then CCN, then hand key, then state + name
  ids <- rows %>% dplyr::group_by(root) %>% dplyr::summarise(
    u = { z <- sort(unique(unlist(strsplit(dplyr::coalesce(uei, ""), ";")))); z <- z[z != ""]; if (length(z)) z[1] else NA_character_ },
    c = { z <- sort(unique(stats::na.omit(ccn))); if (length(z)) z[1] else NA_character_ },
    h = { z <- sort(unique(unlist(hand_keys[cur_group_rows()]))); if (length(z)) z[1] else NA_character_ },
    nm = paste0(dplyr::first(state[order(-dplyr::coalesce(amount, 0))]), "-",
                dplyr::first(norm_name[order(-dplyr::coalesce(amount, 0))])),
    .groups = "drop") %>%
    dplyr::mutate(awardee_entity_id = dplyr::case_when(
      !is.na(u) ~ paste0("UEI-", u),
      !is.na(c) ~ paste0("CCN-", c),
      !is.na(h) ~ paste0("HAND-", h),
      TRUE ~ paste0("NAME-", gsub(" ", "_", substr(nm, 1, 60)))))
  if (anyDuplicated(ids$awardee_entity_id)) {
    d <- ids$awardee_entity_id[duplicated(ids$awardee_entity_id)]
    ids <- ids %>% dplyr::group_by(awardee_entity_id) %>%
      dplyr::mutate(awardee_entity_id = if (dplyr::n() > 1) paste0(awardee_entity_id, "~", dplyr::row_number()) else awardee_entity_id) %>%
      dplyr::ungroup()
  }
  rows <- rows %>% dplyr::left_join(ids %>% dplyr::select(root, awardee_entity_id), by = "root") %>% dplyr::select(-root)
  attr(rows, "refused_name_joins") <- refused
  attr(rows, "refused_ccn_joins") <- refused_ccn
  rows
}

# -- 3. the ranking --------------------------------------------------------------------

# SESSION 125b (owner audit): a reader-facing organisation type. The internal
# coding is unchanged. NONPROFIT_CBO carrying RECIPIENT_TYPE_INFERRED is the
# standing fallback for an UNSTATED form, so it prints "Organisation (form not
# stated)", never "Nonprofit". Academic health centres (recipient_subtype) and
# hospital associations/networks (config/spend_category_entities.csv,
# hospital_affiliate TRUE) are marked.
AW_ORG_LABELS <- c(
  HOSPITAL_OR_SYSTEM = "Hospital or health system",
  HOSPITAL_AFFILIATED_ENTITY = "Hospital-affiliated organisation",
  FQHC_OR_RHC = "FQHC or rural health clinic",
  EMS_OR_PSAP = "EMS agency or 911 centre",
  UNIVERSITY_OR_AHC = "University",
  AHEC = "Area Health Education Center",
  SCHOOL_OR_DISTRICT = "School or school district",
  LOCAL_GOVT_OR_PUBLIC_HEALTH = "Local government or public health department",
  TRIBAL_ORG = "Tribal nation or tribal organisation",
  STATE_AGENCY = "State agency",
  VENDOR_OR_CONTRACTOR = "Vendor or contractor",
  NONPROFIT_CBO = "Nonprofit or community organisation",
  PHYSICIAN_PRACTICE = "Physician practice",
  MANAGED_CARE_ORGANIZATION = "Managed care organisation",
  OTHER = "Other (form stated in the source)",
  NOT_YET_NAMED = "Not yet named")
AW_FORM_NOT_STATED <- "Organisation (form not stated)"

#' One plain label per row. NONPROFIT_CBO prints "Organisation (form not
#' stated)" where the form is the fallback (RECIPIENT_TYPE_INFERRED), where the
#' typing is LOW confidence, or where the printed name carries a for-profit legal
#' form (LLC, LLP, PLLC, PC, Corp): the code has been used for nursing-home LLCs
#' and similar whose nonprofit status no source states (session 125b measurement:
#' 421 NONPROFIT_CBO award rows without the flag, 192 of them LOW).
AW_FORPROFIT_FORM <- "\\b(LLC|L\\.L\\.C\\.|LLP|PLLC|P\\.C\\.|PC|CORP|CORPORATION|LP)\\b"
aw_org_type <- function(recipient_type, flag_reason, recipient_subtype, awardee, confidence = NA_character_,
                        ent = rhtp_spend_entities()) {
  lab <- unname(AW_ORG_LABELS[dplyr::coalesce(recipient_type, "")])
  lab[is.na(lab)] <- "Not coded"
  inferred <- ys_has(flag_reason, "RECIPIENT_TYPE_INFERRED") | confidence %in% "LOW" |
    grepl(AW_FORPROFIT_FORM, toupper(dplyr::coalesce(awardee, "")))
  lab[inferred & recipient_type %in% c("NONPROFIT_CBO", NA)] <- AW_FORM_NOT_STATED
  ahc <- recipient_subtype %in% "ACADEMIC_HEALTH_CENTER"
  lab[ahc] <- paste0(lab[ahc], " (academic health centre)")
  eidx <- rhtp_spend_entity_match(awardee, ent)
  assoc <- !is.na(eidx) & ent$hospital_affiliate[pmax(eidx, 1L)] == "TRUE" & !recipient_type %in% "HOSPITAL_OR_SYSTEM"
  lab[assoc] <- "Hospital association or network"
  lab
}

aw_money <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

#' One line per entity (RANKED rows only)
aw_rank <- function(er, parents = aw_parent_map(er)) {
  r <- er %>% dplyr::filter(role == "RANKED") %>% dplyr::mutate(amt = dplyr::coalesce(amount, 0),
                                                                is_award = amount_type %in% c("award", "intent"))
  if (!"org_type" %in% names(r)) r$org_type <- aw_org_type(r$recipient_type, r$flag_reason, r$recipient_subtype, r$awardee,
                                                           r$determination_confidence)
  st <- r %>% dplyr::filter(is_award) %>% dplyr::group_by(awardee_entity_id, state) %>%
    dplyr::summarise(usd = sum(amt), .groups = "drop") %>% dplyr::arrange(awardee_entity_id, dplyr::desc(usd), state) %>%
    dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(dollars_by_state = paste0(state, " $", aw_money(usd), collapse = "; "), .groups = "drop")
  top_of <- function(v, w) { if (!length(v)) return(NA_character_); t <- tapply(w, v, sum); names(t)[which.max(t)] }
  ent <- r %>% dplyr::group_by(awardee_entity_id) %>% dplyr::summarise(
    canonical_name = { a <- tapply(amt, awardee, sum); names(a)[order(-a, names(a))][1] },
    name_variants = paste(sort(unique(awardee)), collapse = " | "),
    n_name_variants = dplyr::n_distinct(awardee),
    entity_match_basis = paste(intersect(AW_BASES, unique(entity_match_basis)), collapse = ";"),
    states = paste(sort(unique(state[is_award])), collapse = ";"),
    state_count = dplyr::n_distinct(state[is_award]),
    obligation_states = paste(sort(unique(state[amount_type == "obligation"])), collapse = ";"),
    total_award_usd = round(sum(amt[is_award]), 2),
    intent_usd = round(sum(amt[amount_type == "intent"]), 2),
    obligation_usd = round(sum(amt[amount_type == "obligation"]), 2),
    awards_priced = sum(is_award & !is.na(amount)),
    awards_no_published_amount = sum(is.na(amount)),
    rows_total = dplyr::n(),
    recipient_type = { t <- unique(stats::na.omit(recipient_type)); if (length(t) > 1) paste(t, collapse = ";") else dplyr::coalesce(t[1], NA_character_) },
    organisation_type = { t <- unique(org_type[order(-amt)]); paste(t, collapse = "; ") },
    ccns = paste(sort(unique(stats::na.omit(ccn))), collapse = ";"),
    ueis = { z <- sort(unique(unlist(strsplit(stats::na.omit(uei), ";")))); paste(z[z != ""], collapse = ";") },
    summary_call = dplyr::case_when(all(summary_hospital_call %in% "HOSPITAL") ~ "HOSPITAL",
                                    !any(summary_hospital_call %in% "HOSPITAL") ~ "NOT_HOSPITAL",
                                    TRUE ~ "MIXED"),
    hospital_call_usd = round(sum(amt[is_award & summary_hospital_call %in% "HOSPITAL"]), 2),
    spend_category = paste(sort(unique(stats::na.omit(spend_category))), collapse = ";"),
    verified_vendor = any(vendor_verified %in% c("TRUE", "True", "true")),
    out_of_state = dplyr::case_when(any(out_of_state %in% "TRUE") ~ "TRUE",
                                    any(out_of_state %in% "NOT_SHOWN") ~ "NOT_SHOWN", TRUE ~ ""),
    pass_through = any(flow_type %in% AW_PT_FLOWS),
    intermediary_role = { z <- unique(paste(flow_type, hospital_attribution, sep = " / ")[flow_type %in% AW_PT_FLOWS]); paste(z, collapse = "; ") },
    top_use_group = top_of(use_group_primary[is_award & amt > 0 & !is.na(use_group_primary)],
                           amt[is_award & amt > 0 & !is.na(use_group_primary)]),
    owner_supplied_source = any(owner_supplied_source),
    .groups = "drop") %>%
    dplyr::left_join(st, by = "awardee_entity_id")
  use_share <- r %>% dplyr::filter(is_award, amt > 0) %>%
    dplyr::left_join(ent %>% dplyr::select(awardee_entity_id, top_use_group), by = "awardee_entity_id") %>%
    dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(top_use_group_share = round(sum(amt[use_group_primary %in% top_use_group]) / sum(amt), 4), .groups = "drop")
  ent %>% dplyr::left_join(use_share, by = "awardee_entity_id") %>%
    dplyr::mutate(intent_share = dplyr::if_else(total_award_usd > 0, round(intent_usd / total_award_usd, 4), NA_real_),
                  multi_state = state_count >= 2) %>%
    dplyr::left_join(parents, by = "awardee_entity_id") %>%
    dplyr::arrange(dplyr::desc(total_award_usd), canonical_name) %>%
    dplyr::mutate(rank = dplyr::if_else(total_award_usd > 0, dplyr::row_number(), NA_integer_))
}

# -- 4. parent systems (verified only) ---------------------------------------------------

#' CCN -> CMS ORGANIZATION NAME, from every archived CMS hospital enrollment file
aw_cms_orgs <- function() {
  fs <- c(list.files(here::here("data/evidence/federal_records"), "^cms_hosp_enrollments_[A-Z]{2}\\.json$",
                     recursive = TRUE, full.names = TRUE),
          list.files(here::here("data/evidence"), "^cms_hosp_enrollments_[A-Z]{2}\\.json$", recursive = TRUE,
                     full.names = TRUE))
  fs <- unique(fs)
  dplyr::bind_rows(lapply(fs, function(f) {
    j <- jsonlite::fromJSON(f)
    if (!is.data.frame(j)) j <- as.data.frame(j[[1]])
    if (!all(c("CCN", "ORGANIZATION NAME") %in% names(j))) return(NULL)
    col <- function(c) if (c %in% names(j)) stringr::str_squish(toupper(as.character(j[[c]]))) else NA_character_
    cc <- as.character(j$CCN)
    cc <- ifelse(grepl("^[0-9]{5}$", cc), paste0("0", cc), cc)   # session 125b: CO's file drops the leading zero
    tibble::tibble(ccn = cc, cms_org = stringr::str_squish(toupper(j$`ORGANIZATION NAME`)),
                   cms_dba = col("DOING BUSINESS AS NAME"), cms_city = col("CITY"),
                   cms_file = sub(paste0(here::here(), "/"), "", f))
  })) %>% dplyr::filter(grepl("^[0-9]{6}$", ccn)) %>% dplyr::distinct(ccn, cms_org, .keep_all = TRUE)
}

# SESSION 125b: labels a reader needs.
#' display_name (a label where two ranked lines share a printed name but are
#' different entities: the UEI's FSRS legal name and city, else the CCN's CMS
#' facility and city) and facilities (every CCN of a multi-hospital entity)
aw_labels <- function(rank, er, cms = aw_cms_orgs()) {
  rec <- readr::read_csv(here::here(AW_FSRS_REC), col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         progress = FALSE) %>% dplyr::filter(!is.na(uei)) %>% dplyr::distinct(uei, .keep_all = TRUE)
  t <- function(x) {
    x <- stringr::str_to_title(dplyr::coalesce(x, ""))
    gsub("\\b(Llp|Llc|Pllc|Lp|Pc|Ii|Iii)\\b", "\\U\\1", x, perl = TRUE)
  }
  cms1 <- cms %>% dplyr::distinct(ccn, .keep_all = TRUE)
  fac <- function(ccns) {
    z <- strsplit(ccns, ";")[[1]]; z <- z[z != ""]
    if (!length(z)) return("")
    m <- cms1[match(z, cms1$ccn), ]
    nm <- ifelse(!is.na(m$cms_dba) & m$cms_dba != "", m$cms_dba, m$cms_org)
    paste0("CCN ", z, ifelse(is.na(nm), "", paste0(": ", t(nm), ", ", t(m$cms_city))), collapse = "; ")
  }
  rank$facilities <- vapply(rank$ccns, function(z) if (length(strsplit(z, ";")[[1]]) > 1) fac(z) else "", "")
  key <- aw_norm(rank$canonical_name)
  dup <- key %in% key[duplicated(key)] & key != ""
  lab <- vapply(seq_len(nrow(rank)), function(i) {
    if (!dup[i]) return(rank$canonical_name[i])
    u <- strsplit(dplyr::coalesce(rank$ueis[i], ""), ";")[[1]]; u <- u[u != ""]
    c1 <- strsplit(dplyr::coalesce(rank$ccns[i], ""), ";")[[1]]; c1 <- c1[c1 != ""]
    id <- if (length(c1) == 1) fac(c1) else if (length(c1) > 1) paste0(length(c1), " hospitals: ", fac(paste(c1, collapse = ";"))) else if (length(u)) {
      m <- rec[match(u[1], rec$uei), ]
      paste0("UEI ", u[1], ": ", t(m$name), ", ", t(m$city))
    } else "state roster name; no federal identifier on the row"
    st <- if (nzchar(dplyr::coalesce(rank$states[i], ""))) rank$states[i] else rank$obligation_states[i]
    paste0(rank$canonical_name[i], " [", st, "; ", id, "]")
  }, "")
  rank$display_name <- lab
  rank$relabelled <- dup
  rank
}

#' The Second-tier recipients tab: every SECOND_TIER row with its first-tier
#' intermediary; never ranked. Also writes the count and dollars onto the
#' intermediary's ranked line.
aw_second_tier <- function(er, rank) {
  er %>% dplyr::filter(role == "SECOND_TIER") %>%
    dplyr::transmute(first_tier = sub("^SECOND_TIER_OF ", "", second_tier_of), state, file_key, awardee,
                     organisation_type = org_type, amount, amount_type, summary_hospital_call, hospital_attribution,
                     recipient_type, awardee_entity_id) %>%
    dplyr::arrange(first_tier, dplyr::desc(dplyr::coalesce(amount, 0)))
}
aw_second_tier_cols <- function(rank, er) {
  st <- er %>% dplyr::filter(role == "SECOND_TIER") %>%
    dplyr::mutate(ft = sub(" \\(.*$", "", sub("^SECOND_TIER_OF ", "", second_tier_of)),
                  ft_file = sub(":.*$", "", ft), ft_awardee = sub("^[^:]*: ", "", ft)) %>%
    dplyr::group_by(ft_file, ft_awardee) %>%
    dplyr::summarise(second_tier_recipients = dplyr::n(), second_tier_usd = round(sum(amount, na.rm = TRUE), 2), .groups = "drop")
  ids <- er %>% dplyr::filter(role == "RANKED") %>% dplyr::distinct(file_key, awardee, awardee_entity_id)
  st <- st %>% dplyr::inner_join(ids, by = c("ft_file" = "file_key", "ft_awardee" = "awardee")) %>%
    dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(second_tier_recipients = sum(second_tier_recipients), second_tier_usd = sum(second_tier_usd), .groups = "drop")
  rank %>% dplyr::select(-dplyr::any_of(c("second_tier_recipients", "second_tier_usd"))) %>%
    dplyr::left_join(st, by = "awardee_entity_id") %>%
    dplyr::mutate(second_tier_recipients = dplyr::coalesce(second_tier_recipients, 0L),
                  second_tier_usd = dplyr::coalesce(second_tier_usd, 0),
                  pass_through = pass_through | second_tier_recipients > 0)
}

#' entity -> verified parent system. Two sources, in this order:
#'   1. config/awardee_parent_systems.csv (the standing system-parent rulings):
#'      match_kind ENTITY (an awardee_entity_id), AWARDEE (state + awardee as
#'      printed) or CMS_ORG (state + CMS ORGANIZATION NAME of the entity's CCN).
#'      Every entry carries its basis.
#'   2. AUTOMATIC CMS-ORGANISATION ROLLUPS: two or more entities in ONE state
#'      whose CCNs are enrolled under the same CMS ORGANIZATION NAME (one
#'      enrolled legal entity operating several hospitals: a federal record).
#'      Never across states: an organisation name repeated in two states is two
#'      bodies (COUNTY OF CLAY, TX and IL).
aw_parent_map <- function(er, cfg = aw_read_cfg(AW_PARENTS, c("parent_system", "match_kind", "match_value",
                                                              "state", "basis", "source"))) {
  orgs <- aw_cms_orgs()
  e_ccn <- er %>% dplyr::filter(role == "RANKED", !is.na(ccn)) %>% dplyr::distinct(awardee_entity_id, state, ccn) %>%
    dplyr::inner_join(orgs %>% dplyr::distinct(ccn, cms_org), by = "ccn")
  a <- cfg %>% dplyr::filter(match_kind == "CMS_ORG") %>%
    dplyr::inner_join(e_ccn, by = c("state", "match_value" = "cms_org")) %>%
    dplyr::transmute(awardee_entity_id, parent_system, parent_basis = paste0(basis, " [CMS ORGANIZATION NAME '", match_value, "' in ", state, ", CCN ", ccn, "]"))
  b <- cfg %>% dplyr::filter(match_kind == "AWARDEE") %>%
    dplyr::inner_join(er %>% dplyr::distinct(state, awardee, awardee_entity_id), by = c("state", "match_value" = "awardee")) %>%
    dplyr::transmute(awardee_entity_id, parent_system, parent_basis = basis)
  c <- cfg %>% dplyr::filter(match_kind == "ENTITY") %>%
    dplyr::inner_join(er %>% dplyr::distinct(awardee_entity_id), by = c("match_value" = "awardee_entity_id")) %>%
    dplyr::transmute(awardee_entity_id = match_value, parent_system, parent_basis = basis)
  miss <- dplyr::bind_rows(
    cfg %>% dplyr::filter(match_kind == "AWARDEE") %>%
      dplyr::anti_join(er %>% dplyr::distinct(state, awardee), by = c("state", "match_value" = "awardee")),
    cfg %>% dplyr::filter(match_kind == "ENTITY", !match_value %in% er$awardee_entity_id),
    cfg %>% dplyr::filter(match_kind == "CMS_ORG") %>% dplyr::anti_join(e_ccn, by = c("state", "match_value" = "cms_org")))
  if (nrow(miss)) stop("[awardee] parent entries matching no Year 1 entity: ",
                       paste(miss$match_kind, miss$state, miss$match_value, collapse = "; "), call. = FALSE)
  hand <- dplyr::bind_rows(a, b, c)
  auto <- e_ccn %>% dplyr::filter(!awardee_entity_id %in% hand$awardee_entity_id) %>%
    dplyr::group_by(state, cms_org) %>% dplyr::filter(dplyr::n_distinct(awardee_entity_id) >= 2) %>%
    dplyr::mutate(ccns = paste(sort(unique(ccn)), collapse = ", ")) %>% dplyr::ungroup() %>%
    dplyr::distinct(state, cms_org, awardee_entity_id, ccns) %>%
    dplyr::transmute(awardee_entity_id, parent_system = paste0(stringr::str_to_title(cms_org), " (", state, ")"),
                     parent_basis = paste0("CMS_ENROLMENT_ORGANIZATION: CCNs ", ccns, " are enrolled under one ORGANIZATION NAME, '",
                                           cms_org, "', in ", state, " (archived CMS Hospital Enrollments)"))
  out <- dplyr::bind_rows(hand, auto) %>% dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(n_par = dplyr::n_distinct(parent_system), parent_system = dplyr::first(parent_system),
                     parent_basis = paste(unique(parent_basis), collapse = " | "), .groups = "drop")
  two <- out %>% dplyr::filter(n_par > 1)
  if (nrow(two)) stop("[awardee] an entity rolls up to two parent systems: ", paste(two$awardee_entity_id, collapse = ", "),
                      call. = FALSE)
  out %>% dplyr::select(-n_par)
}

aw_parent_view <- function(rank) {
  rank %>% dplyr::filter(!is.na(parent_system)) %>% dplyr::group_by(parent_system) %>%
    dplyr::summarise(member_entities = dplyr::n(),
                     members = paste(canonical_name[order(-total_award_usd)], collapse = " | "),
                     states = paste(sort(unique(unlist(strsplit(states, ";")))), collapse = ";"),
                     state_count = length(unique(unlist(strsplit(states, ";")))),
                     total_award_usd = round(sum(total_award_usd), 2),
                     intent_usd = round(sum(intent_usd), 2),
                     hospital_call_usd = round(sum(hospital_call_usd), 2),
                     awards_no_published_amount = sum(awards_no_published_amount),
                     parent_basis = paste(unique(parent_basis), collapse = " | "), .groups = "drop") %>%
    dplyr::mutate(rollup = "PARENT_ROLLUP (verified parent only; never replaces the entity view)") %>%
    dplyr::arrange(dplyr::desc(total_award_usd))
}

# -- 5. contracts, pools, reconciliation ---------------------------------------------------

#' Contract-file amounts (never awards), attached to an entity only on the same
#' state and the same normalised name (or a hand-reviewed member string)
aw_contract_columns <- function(er) {
  fs <- list.files(here::here(AW_CONTRACTS), "\\.csv$", full.names = TRUE)
  ct <- dplyr::bind_rows(lapply(fs, function(f) readr::read_csv(f, col_types = readr::cols(.default = "c"),
                                                              na = c("", "NA"), progress = FALSE))) %>%
    dplyr::filter(budget_period %in% c("1", NA)) %>%
    dplyr::transmute(state, awardee = stringr::str_squish(awardee), norm_name = aw_norm(awardee),
                     amount = suppressWarnings(as.numeric(amount)), amount_type)
  key <- er %>% dplyr::filter(role == "RANKED") %>% dplyr::distinct(state, norm_name, awardee_entity_id) %>%
    dplyr::group_by(state, norm_name) %>% dplyr::filter(dplyr::n_distinct(awardee_entity_id) == 1) %>% dplyr::ungroup()
  m <- ct %>% dplyr::left_join(key, by = c("state", "norm_name"))
  attr_un <- m %>% dplyr::filter(is.na(awardee_entity_id))
  cols <- m %>% dplyr::filter(!is.na(awardee_entity_id)) %>% dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(contract_maximum_usd = round(sum(amount[amount_type == "contract maximum"], na.rm = TRUE), 2),
                     contract_obligation_usd = round(sum(amount[amount_type == "obligation"], na.rm = TRUE), 2),
                     contract_other_usd = round(sum(amount[!amount_type %in% c("contract maximum", "obligation")], na.rm = TRUE), 2),
                     .groups = "drop")
  attr(cols, "unmatched") <- attr_un
  cols
}

aw_unattributed <- function(er) {
  er %>% dplyr::filter(role == "UNATTRIBUTED_POOL") %>%
    dplyr::transmute(state, file_key, awardee, amount, amount_type, recipient_type, flow_type, hospital_attribution,
                     summary_hospital_call, flag_reason, owner_supplied_source,
                     why = dplyr::case_when(ys_has(flag_reason, "MULTI_RECIPIENT_FIELD") ~ "MULTI_RECIPIENT_FIELD: several organisations, no split (never divided)",
                                            recipient_type %in% "NOT_YET_NAMED" ~ "NOT_YET_NAMED: recipients unnamed",
                                            TRUE ~ "hand list (config/awardee_unattributed_rows.csv): several organisations, no split")) %>%
    dplyr::arrange(dplyr::desc(dplyr::coalesce(amount, 0)))
}

#' The reconciliation: ranked + unattributed + held out = every priced Year 1 row,
#' and that total equals R/08's published priced awards plus its excluded column
aw_reconcile <- function(er, rank, ys = NULL) {
  if (is.null(ys)) ys <- ys_build(subset = FALSE)
  us <- ys[ys$state == "US", ]
  tot <- function(f) round(sum(er$amount[f], na.rm = TRUE), 2)
  ranked_award <- round(sum(rank$total_award_usd), 2)
  ranked_obl <- round(sum(rank$obligation_usd), 2)
  unattr <- tot(er$role == "UNATTRIBUTED_POOL")
  held <- tot(er$role == "HELD_OUT_ADMINISTRATOR")
  second <- tot(er$role == "SECOND_TIER")
  if (abs(round(second - us$second_tier_usd, 2)) > 0.05) {
    stop("[awardee] second-tier dollars differ from R/08's second_tier_usd", call. = FALSE)
  }
  lines <- tibble::tribble(
    ~line, ~usd,
    "Ranked awardees: award + intent dollars (the ranking)", ranked_award,
    "Ranked awardees: CMS obligation-report lines (amount type obligation, its own column, never in the ranking total)", ranked_obl,
    "Unattributed pools: priced rows naming several organisations or none (never divided)", unattr,
    "Held out: NM Accenture LLP, ADMINISTRATOR_PASS_THROUGH_UNRESOLVED (out of every total)", held,
    "SUM of the four lines", round(ranked_award + ranked_obl + unattr + held, 2),
    "R/08 awards published, priced rows (published_priced_usd)", round(us$published_priced_usd, 2),
    "R/08 excluded_award_usd (the held-out administrator)", round(us$excluded_award_usd, 2),
    "R/08 priced + excluded", round(us$published_priced_usd + us$excluded_award_usd, 2),
    "Pool-level amounts with no per-recipient split (listed separately, not in any line above)", round(us$pool_level_usd, 2),
    "R/08 awards published incl. pool level (award_total_usd)", round(us$award_total_usd, 2),
    "Second-tier recipients: an intermediary's own subgrants, counted ONCE at the first tier (excluded from every line above; Second-tier recipients tab)", second,
    "R/08 second_tier_usd (excluded from awards published)", round(us$second_tier_usd, 2))
  diff <- round(ranked_award + ranked_obl + unattr + held - (us$published_priced_usd + us$excluded_award_usd), 2)
  if (abs(diff) > 0.05) stop("[awardee] the ranking does not reconcile to awards published: off by $", diff, call. = FALSE)
  if (abs(round(ranked_award + ranked_obl + unattr - us$published_priced_usd, 2)) > 0.05) {
    stop("[awardee] ranked + obligation + unattributed != published_priced_usd", call. = FALSE)
  }
  lines
}

# -- 6. checks -------------------------------------------------------------------------

#' No entity joins two states except on UEI, EIN, CCN or a hand review; the
#' recorded collisions stay distinct; no amount types mixed
aw_check <- function(er, rank, distinct = aw_distinct_config()) {
  ms <- er %>% dplyr::group_by(awardee_entity_id) %>% dplyr::filter(dplyr::n_distinct(state) > 1) %>% dplyr::ungroup()
  # every multi-state entity must hold a strong identifier shared across its states
  bad <- ms %>% dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(strong = any(entity_match_basis %in% c("UEI", "EIN", "CCN", "HAND_REVIEWED")), .groups = "drop") %>%
    dplyr::filter(!strong)
  if (nrow(bad)) stop("[awardee] multi-state entity without a UEI/EIN/CCN/hand join: ", paste(bad$awardee_entity_id, collapse = ", "),
                      call. = FALSE)
  # name edges alone never span two states: group rows by (state, norm_name)
  # name-join keys and confirm each key sits in one state (by construction)
  # recorded collisions stay distinct
  for (i in seq_len(nrow(distinct))) {
    sts <- strsplit(distinct$states[i], ";")[[1]]
    ids <- er %>% dplyr::filter(norm_name == distinct$norm_name[i], state %in% sts) %>%
      dplyr::group_by(state) %>% dplyr::summarise(id = paste(sort(unique(awardee_entity_id)), collapse = ","), .groups = "drop")
    if (nrow(ids) < length(sts)) stop("[awardee] distinct collision '", distinct$norm_name[i], "' not found in ",
                                      distinct$states[i], call. = FALSE)
    if (dplyr::n_distinct(ids$id) < nrow(ids)) stop("[awardee] distinct collision joined: ", distinct$norm_name[i], call. = FALSE)
  }
  # amount types never mixed in the ranking total
  chk <- er %>% dplyr::filter(role == "RANKED") %>% dplyr::group_by(awardee_entity_id) %>%
    dplyr::summarise(a = round(sum(amount[amount_type %in% c("award", "intent")], na.rm = TRUE), 2), .groups = "drop") %>%
    dplyr::inner_join(rank %>% dplyr::select(awardee_entity_id, total_award_usd), by = "awardee_entity_id")
  if (any(abs(chk$a - chk$total_award_usd) > 0.005)) stop("[awardee] ranking total mixes amount types", call. = FALSE)
  invisible(TRUE)
}

#' Cross-state names that look alike and were not joined: review candidates only
aw_candidates <- function(er) {
  e <- er %>% dplyr::filter(role == "RANKED") %>% dplyr::distinct(awardee_entity_id, state, norm_name)
  core <- function(x) { t <- strsplit(x, " ")[[1]]; t <- t[!t %in% c("HEALTH", "SERVICES", "OF", "AND", "THE", "CENTER", "GROUP", "SYSTEM")]; paste(t, collapse = " ") }
  e$core <- vapply(e$norm_name, core, character(1))
  same <- e %>% dplyr::group_by(norm_name) %>% dplyr::filter(dplyr::n_distinct(state) > 1, dplyr::n_distinct(awardee_entity_id) > 1) %>%
    dplyr::summarise(states = paste(sort(unique(state)), collapse = ";"), ids = dplyr::n_distinct(awardee_entity_id), .groups = "drop")
  same
}

# -- 7. build ----------------------------------------------------------------------------

aw_build <- function(date = format(Sys.Date(), "%Y-%m-%d"), write = TRUE, xlsx = TRUE) {
  rows <- aw_roles(aw_rows())
  er <- aw_entities(rows)
  er$org_type <- aw_org_type(er$recipient_type, er$flag_reason, er$recipient_subtype, er$awardee, er$determination_confidence)
  rank <- aw_rank(er)
  rank <- aw_labels(rank, er)
  rank <- aw_second_tier_cols(rank, er)
  st_chk <- rank %>% dplyr::filter(second_tier_usd > total_award_usd + 0.005)
  if (nrow(st_chk)) stop("[awardee] second-tier dollars exceed the intermediary's first-tier award: ",
                         paste(st_chk$canonical_name, collapse = ", "), call. = FALSE)
  ct <- aw_contract_columns(er)
  rank <- rank %>% dplyr::left_join(ct, by = "awardee_entity_id") %>%
    dplyr::mutate(dplyr::across(c(contract_maximum_usd, contract_obligation_usd, contract_other_usd), ~ dplyr::coalesce(.x, 0)))
  ys <- ys_build(subset = FALSE)
  rec <- aw_reconcile(er, rank, ys)
  aw_check(er, rank)
  out <- list(rows = er, rank = rank, parents = aw_parent_view(rank), unattributed = aw_unattributed(er),
              second_tier = aw_second_tier(er, rank),
              reconciliation = rec, distinct = aw_distinct_config(), contracts_unmatched = attr(ct, "unmatched"),
              refused = attr(er, "refused_name_joins"), ys = ys)
  if (write) {
    readr::write_csv(er %>% dplyr::select(row_id, file_key, state, awardee, amount, amount_type, role, awardee_entity_id,
                                          entity_match_basis, uei, ccn, ein, norm_name, organisation_type = org_type,
                                          second_tier_of, owner_supplied_source),
                     here::here(AW_OUT_ROWS), na = "")
    readr::write_csv(aw_rank_columns(rank), here::here(AW_OUT_RANK(date)), na = "")
    message("[awardee] wrote ", AW_OUT_ROWS, " and ", AW_OUT_RANK(date))
  }
  if (xlsx) {
    # SESSION 125b: Delaware is not confidential (owner ruling 2026-11-25); the
    # team copy is the same workbook, kept as a file colleagues expect.
    aw_workbook(out, date, team = FALSE)
    aw_workbook(out, date, team = TRUE)
  }
  invisible(out)
}

aw_rank_columns <- function(rank) {
  rank %>% dplyr::transmute(
    rank, awardee = display_name, organisation_type, pass_through, second_tier_recipients, second_tier_usd,
    printed_name = canonical_name, name_variants, facilities, awardee_entity_id, entity_match_basis,
    state_count, multi_state, states, dollars_by_state, total_award_usd, intent_usd, intent_share,
    awards_priced, awards_no_published_amount, obligation_usd, obligation_states, contract_maximum_usd, contract_obligation_usd,
    recipient_type, summary_call, hospital_call_usd, spend_category, verified_vendor, out_of_state,
    intermediary_role, top_use_group, top_use_group_share, parent_system, parent_basis,
    owner_supplied_source)
}

# -- 8. workbook ---------------------------------------------------------------------------

#' The Read first tab (session 125b, owner audit): plain words for a reader who
#' opens nothing else
aw_read_first <- function(out, date) {
  us <- out$ys[out$ys$state == "US", ]
  f <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))
  held <- out$rows %>% dplyr::filter(role == "HELD_OUT_ADMINISTRATOR")
  rk <- out$rank %>% dplyr::filter(!is.na(rank))
  top10 <- sum(utils::head(rk$total_award_usd, 10))
  pt_top25 <- sum(utils::head(rk$pass_through, 25))
  c(
    paste0("WHAT THIS IS. A ranking of every organisation that received a Year 1 Rural Health Transformation Program award, by its total Year 1 award dollars, ",
           "summed across states where the same legal entity was awarded in more than one. Built ", date, " from the state award files (R/12_awardee_ranking.R)."),
    paste0("WHAT IS RANKED. Year 1 award dollars. Notices of intent to award are included and shown in their own column (intent_usd), because a state's intent is not yet an executed award. ",
           "CMS obligation-report lines and state contract maximums are in separate columns and never added to the ranked total."),
    paste0("INTERMEDIARIES PASS MONEY ON. Many of the largest lines are intermediaries: hospital associations, foundations, collaboratives, universities and state agencies that receive an award and pass much of it on to others. ",
           "They are flagged in the pass_through column (", pt_top25, " of the top 25). Their rank measures the money that went THROUGH them, not money they kept."),
    paste0("COUNTED ONCE. Where an intermediary's own subgrants are also published (Virginia Health Care Foundation's ", sum(out$rows$role == "SECOND_TIER"),
           " RHT subgrants, ", f(sum(out$rows$amount[out$rows$role == "SECOND_TIER"], na.rm = TRUE)), "), the money is counted once, at the intermediary's award from the state. ",
           "The subgrantees are listed on the Second-tier recipients tab and are not ranked beside it (the intermediary line shows second_tier_recipients and second_tier_usd)."),
    paste0("CONCENTRATION, NOT THE HOSPITAL SHARE. Hospitals receive many smaller awards, so few appear near the top. The ranking shows how concentrated the money is (the top 10 lines hold ",
           f(top10), " of ", f(sum(rk$total_award_usd)), " ranked). For the hospital share, use the Year 1 summary: hospital best estimate ", f(us$hospital_summary_usd),
           ", ", formatC(us$hospital_share_of_awards_pct, format = "f", digits = 1), "% of awards published (", f(us$award_total_usd), ")."),
    paste0("ORGANISATION TYPE. A plain label for each line. 'Organisation (form not stated)' means the state's award document did not say what kind of organisation the recipient is; it is not a claim that the recipient is a nonprofit. ",
           "Academic health centres and hospital associations or networks are marked."),
    paste0("HELD OUT: ", paste0(held$awardee, " (", held$state, ", ", f(held$amount), ")", collapse = "; "),
           ". Its administration fee and the programme money it pays on are not split on any state source, so it is out of every total."),
    paste0("LISTED SEPARATELY, NOT RANKED: pools with no per-recipient split (a row naming several organisations, or none) on the Unattributed pools tab; ",
           "second-tier recipients on their tab; awards with no published amount (counted in awards_no_published_amount, never ranked)."),
    "SAME NAME, DIFFERENT ENTITY. Where two lines share a printed name but are different organisations (for example two Oklahoma State University campuses with different federal UEIs), the awardee column adds the federal legal name and city or the hospital's CMS facility name in brackets.",
    "DELAWARE. Delaware rows appear like every other state's (owner ruling 2026-11-25; Delaware is no longer confidential).",
    "See Notes and method for the identity rules and the Reconciliation tab for how the totals tie to the Year 1 summary."
  )
}

aw_notes <- function(out, team) {
  rank <- out$rank
  ms <- rank %>% dplyr::filter(multi_state)
  held <- out$rows %>% dplyr::filter(role == "HELD_OUT_ADMINISTRATOR")
  c(
    "HOW TO READ THIS. One line per awardee ENTITY (a legal entity), ranked by its Year 1 award dollars (award + intent) summed across every state. An entity's awards in several states are summed only where the rows are joined by a UEI, an EIN, a CMS CCN or a hand review with its basis quoted; a name alone never joins two states.",
    paste0("JOIN BASIS. entity_match_basis lists how the entity's rows were joined: UEI (the same SAM UEI, from FSRS), EIN, CCN (the same CMS CCN; different CCNs are different hospitals), HAND_REVIEWED (config/awardee_entities.csv, each with its basis; SAME_STATE_LEGAL_BODY entries join one legal body's several hospitals, listed in facilities), SAME_STATE_EXACT_NAME (the same normalised name within ONE state only; 'A DBA B' and 'B DBA A' are one name, and either half of a DBA string meets the same half printed alone), SINGLE_ROW."),
    paste0("MULTI-STATE: ", nrow(ms), " entities hold awards in two or more states, each on a confirmed identifier. Cross-state names that are not one entity are on the Distinct name collisions tab with the reason; ",
           nrow(out$distinct), " are recorded."),
    "WHAT IS COUNTED. Award amounts only (Year 1, STATE_FILES), intents included and shown separately (intent_usd, intent_share). CMS obligation-report lines (obligation_usd) and contract-file maximums and obligations (contract_maximum_usd, contract_obligation_usd) are in their own columns and NEVER added to the award total.",
    paste0("HELD OUT: ", paste0(held$awardee, " (", held$state, ") $", aw_money(held$amount), collapse = "; "),
           ". ADMINISTRATOR_PASS_THROUGH_UNRESOLVED: its fee and pass-through share are unsplit, so it is out of every total, as in the Year 1 summary."),
    "UNATTRIBUTED POOLS. A row naming several organisations with no split (Ohio's 22 hospitals, WA's 28, the CT/VA/OK pairs) or naming none is never divided and is not ranked; it is on the Unattributed pools tab. A pass-through intermediary that received the money itself (ICAHN, WSHA, NHVN, NRHP) ranks as the awardee, flagged pass_through with its intermediary role.",
    paste0("SECOND TIER (session 125b, owner ruling 2026-11-25). Money is counted once, at the first tier: the state's award to the intermediary. Virginia Health Care Foundation ranks on its two FSRS subawards from the state (RHT26-007 Provider Productivity $9,891,550; RHT26-008 Provider Interoperability $16,073,769); its own ",
           sum(out$rows$role == "SECOND_TIER"), " subgrants ($", aw_money(sum(out$rows$amount[out$rows$role == "SECOND_TIER"], na.rm = TRUE)),
           ") are SECOND_TIER_OF it (config/second_tier_rows.csv), listed on the Second-tier recipients tab, never ranked, and excluded from awards published; a named hospital subgrantee stays in every hospital figure. Every other intermediary was swept: none has priced subrecipient rows of its own (docs/session125b_ranking_audit_fixes.md)."),
    "UNPRICED ROWS. A named award with no published amount is counted in awards_no_published_amount and never ranked on; an entity with only unpriced rows has no rank.",
    "SUMMARY CALL. HOSPITAL / NOT_HOSPITAL from the summary-call layer (R/07); MIXED where an entity's rows carry both calls (hospital_call_usd shows the HOSPITAL-called dollars).",
    "ORGANISATION TYPE. A reader label for recipient_type (unchanged internally). NONPROFIT_CBO with flag RECIPIENT_TYPE_INFERRED is the standing fallback for an unstated form and prints 'Organisation (form not stated)'.",
    "PARENT SYSTEMS. The Parent systems tab rolls entities up to a parent ONLY where the parent is verified (config/awardee_parent_systems.csv: the standing system-parent rulings and the CMS enrolment's ORGANIZATION NAME). It never replaces the entity view and is never added to it.",
    "DELAWARE. Not confidential (owner ruling 2026-11-25): Delaware rows are in every tab and total. owner_supplied_source flags any row citing the owner-supplied DE Verify.xlsx (no award row does). The _team copy is the same workbook.",
    "RECONCILIATION (tab): ranked award dollars + CMS obligation lines + unattributed pools + the held-out administrator equal every priced Year 1 row except second-tier rows, which equals the Year 1 summary's published priced awards plus its excluded column; second-tier and pool-level amounts are listed separately.",
    "SOURCES: the state award files in data/reference (STATE_FILES), the FSRS archive under data/raw/usaspending/, CMS hospital enrollment files under data/evidence/federal_records/. Built by R/12_awardee_ranking.R."
  )
}

aw_workbook <- function(out, date, team = FALSE) {
  rank <- out$rank
  er <- out$rows
  un <- aw_unattributed(er)
  par <- aw_parent_view(rank)
  r <- aw_rank_columns(rank)
  wb <- openxlsx::createWorkbook()
  hs <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#DDEBF7", wrapText = TRUE, valign = "top")
  usd <- openxlsx::createStyle(numFmt = "$#,##0")
  pct <- openxlsx::createStyle(numFmt = "0.0%")
  flag <- openxlsx::createStyle(fgFill = "#FCE4D6")
  wrap <- openxlsx::createStyle(wrapText = TRUE, valign = "top")
  text_sheet <- function(name, lines) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, tibble::tibble(!!name := lines), headerStyle = hs)
    openxlsx::setColWidths(wb, name, cols = 1, widths = 160)
    openxlsx::addStyle(wb, name, wrap, rows = 2:(length(lines) + 1), cols = 1, gridExpand = TRUE)
  }
  sheet <- function(name, d, usd_cols = grep("_usd$", names(d), value = TRUE), pct_cols = grep("_share$", names(d), value = TRUE)) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, d, headerStyle = hs)
    if (nrow(d)) {
      for (cn in intersect(usd_cols, names(d))) openxlsx::addStyle(wb, name, usd, rows = 2:(nrow(d) + 1), cols = which(names(d) == cn), gridExpand = TRUE)
      for (cn in intersect(pct_cols, names(d))) openxlsx::addStyle(wb, name, pct, rows = 2:(nrow(d) + 1), cols = which(names(d) == cn), gridExpand = TRUE)
      if ("owner_supplied_source" %in% names(d)) {
        cr <- which(d$owner_supplied_source %in% TRUE) + 1
        if (length(cr)) openxlsx::addStyle(wb, name, flag, rows = cr, cols = 1:ncol(d), gridExpand = TRUE, stack = TRUE)
      }
    }
    openxlsx::freezePane(wb, name, firstRow = TRUE, firstCol = TRUE)
    openxlsx::setColWidths(wb, name, cols = seq_len(ncol(d)), widths = pmin(60, pmax(10, nchar(names(d)) + 2)))
  }
  text_sheet("Read first", aw_read_first(out, date))
  sheet("All awardees", r)
  sheet("Multi-state awardees", r %>% dplyr::filter(multi_state))
  sheet("Hospitals", r %>% dplyr::filter(summary_call %in% c("HOSPITAL", "MIXED")))
  sheet("Non-hospital", r %>% dplyr::filter(summary_call == "NOT_HOSPITAL"))
  sheet("Verified vendors", r %>% dplyr::filter(verified_vendor))
  sheet("Parent systems", par)
  sheet("Second-tier recipients", out$second_tier)
  sheet("Unattributed pools", un)
  sheet("Joins and relabels", aw_join_report(out))
  sheet("Distinct name collisions", out$distinct)
  sheet("Reconciliation", out$reconciliation)
  text_sheet("Notes and method", aw_notes(out, team))
  path <- here::here(AW_OUT_XLSX(date, team))
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  rhtp_xlsx_strip_dangling_rels(path)
  message("[awardee] wrote ", AW_OUT_XLSX(date, team))
  invisible(path)
}

#' Every same-state join that rests on more than one printed string or a hand
#' review, and every relabelled line (session 125b, Task 3)
aw_join_report <- function(out) {
  er <- out$rows %>% dplyr::filter(role %in% c("RANKED", "SECOND_TIER"))
  j <- er %>% dplyr::group_by(awardee_entity_id) %>%
    dplyr::filter(dplyr::n_distinct(awardee) > 1 | any(entity_match_basis == "HAND_REVIEWED") | dplyr::n_distinct(ccn, na.rm = TRUE) > 1) %>%
    dplyr::summarise(what = "JOINED", states = paste(sort(unique(state)), collapse = ";"),
                     printed_names = paste(sort(unique(awardee)), collapse = " | "),
                     basis = paste(intersect(AW_BASES, unique(entity_match_basis)), collapse = ";"),
                     usd = round(sum(amount[role == "RANKED"], na.rm = TRUE), 2), .groups = "drop")
  rl <- out$rank %>% dplyr::filter(relabelled) %>%
    dplyr::transmute(awardee_entity_id, what = "RELABELLED", states, printed_names = canonical_name, basis = display_name,
                     usd = total_award_usd)
  dplyr::bind_rows(j, rl) %>% dplyr::arrange(what, dplyr::desc(usd))
}

#' The top-25 table and the multi-state count for R/08's Overview notes
aw_overview_lines <- function(date) {
  p <- here::here(AW_OUT_RANK(date))
  if (!file.exists(p)) return(character(0))
  r <- readr::read_csv(p, show_col_types = FALSE, progress = FALSE)
  top <- r %>% dplyr::filter(!is.na(rank)) %>% dplyr::arrange(rank) %>% utils::head(25)
  c(paste0("AWARDEE RANKING (R/12, output/awardee_ranking_", date, ".xlsx): ", sum(r$multi_state), " awardee entities hold Year 1 awards in two or more states, each joined on a UEI, EIN, CCN or a hand review, never on a name alone. Top 25 by Year 1 award dollars (award + intent; obligations and contract maximums excluded):"),
    paste0("  ", top$rank, ". ", top$awardee, " -- $", aw_money(top$total_award_usd), " (", top$states, "; ",
           top$organisation_type, "; ", top$summary_call, ")"))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  d <- args[grepl("^\\d{4}-\\d{2}-\\d{2}$", args)]
  d <- if (length(d)) d[1] else format(Sys.Date(), "%Y-%m-%d")
  if ("--build" %in% args) aw_build(d)
  if ("--validate" %in% args) { o <- aw_build(d, write = FALSE, xlsx = FALSE); print(o$reconciliation, n = Inf) }
  if ("--candidates" %in% args) {
    rows <- aw_roles(aw_rows()); er <- aw_entities(rows); print(aw_candidates(er), n = Inf)
  }
}

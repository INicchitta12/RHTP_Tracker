# 09_vendor_flags.R ------------------------------------------------------------
# Session 116b: vendor / consultant / insurer / out-of-state DETECTION layer.
#
# PURPOSE. Internal-only examples, for AHA colleagues, of RHTP money going to
# large consulting firms, technology and EHR vendors, insurers and MCOs, and
# non-hospital organisations headquartered outside the awarding state. Every
# row cites its source. A lead (RCJ) is labelled as a lead and never totalled.
#
# THIS LAYER ONLY READS. It changes no award row, no summary call, no bucket
# and no hospital figure. It writes three files of its own and nothing else:
#   data/reference/vendor_flags.csv
#   data/reference/vendor_unnamed_contractor_by_state.csv
#   output/vendor_flags_<date>.xlsx
#
# THE HOSPITAL EXCLUSION. Hospitals and health systems are never flagged, in
# any state. An award-file row whose summary call is HOSPITAL, or whose
# recipient_type is HOSPITAL_OR_SYSTEM, is excluded from every class and tab
# BEFORE any pattern is read. A USAspending row whose business type says
# HOSPITAL, or whose name reads as a hospital, is excluded the same way, and
# every out-of-state USAspending row that is not in the dictionary must be in
# VF_FSRS_REVIEWED_EXCLUSIONS with its reason, or the build stops.
#
# MATCHING. Only `config/vendor_entity_dictionary.csv` (hand-reviewed) decides
# who a recipient is. Patterns are case-insensitive regular expressions; there
# is no fuzzy matching. A recipient string matching two dictionary entries with
# different canonical names stops the build.
#
# AMOUNT TYPES are never added together: award, intent, obligation, contract
# maximum, plan, unpriced. A multi-recipient field is never divided (§6.2): its
# row is kept at amount NA ("unpriced") with the joint figure in `notes`.
#
# CLI
#   Rscript R/09_vendor_flags.R --validate   # source-quote checks on the hand rows
#   Rscript R/09_vendor_flags.R --build      # vendor_flags.csv + unnamed-contractor table
#   Rscript R/09_vendor_flags.R --xlsx       # output/vendor_flags_<date>.xlsx
#   Rscript R/09_vendor_flags.R --report

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
  library(purrr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "09a_usaspending_rhtp.R"))

VF_AS_OF <- "2026-11-09"
VF_DICT <- "config/vendor_entity_dictionary.csv"
VF_FLAGS_CSV <- "data/reference/vendor_flags.csv"
VF_UNNAMED_CSV <- "data/reference/vendor_unnamed_contractor_by_state.csv"
VF_XLSX <- function(as_of = VF_AS_OF) here::here("output", paste0("vendor_flags_", as_of, ".xlsx"))
VF_CMS_LINES <- "data/reference/cms_obligations_bp1_lines_20261014.csv"
VF_CMS_PDF <- "data/raw/cms/obligations/2026-07-31/RHTP-Obligated-Funds-20261014.pdf"
VF_CMS_URL <- "https://www.medicaid.gov/resources-for-states/rural-health/rhtp-resources/RHTP-Obligated-Funds-20261014.pdf"
VF_TOP_FLOOR <- 1e6

VF_DICT_COLUMNS <- c("pattern", "canonical_name", "parent_company", "entity_class",
                     "hq_state", "basis", "notes")
VF_CLASSES <- c("CONSULTING_BIG", "CONSULTING_OTHER", "TECH_VENDOR", "INSURER_MCO",
                "OUT_OF_STATE_ORG")
VF_AMOUNT_TYPES <- c("award", "intent", "obligation", "contract maximum", "plan", "unpriced")
VF_ROLES <- c("ADMINISTERS_PROGRAM", "DELIVERS_TO_PROVIDERS", "MIXED", "UNKNOWN")
VF_SOURCE_TYPES <- c("STATE_AWARD_FILE", "STATE_CONTRACT_REGISTER", "USASPENDING_FSRS",
                     "CMS_OBLIGATION_REPORT", "STATE_ANNUAL_REPORT", "BUDGET_NARRATIVE",
                     "RCJ_LEAD")
VF_FLAG_COLUMNS <- c("flag_id", "state", "recipient", "canonical_name", "parent_company",
                     "entity_class", "hq_state", "amount", "amount_type", "budget_period",
                     "role", "purpose_quote", "source_type", "source_url", "archive_path",
                     "confidence", "notes", "out_of_state", "hq_basis", "is_lead",
                     "also_cited_in")

# A name that reads as a hospital or health system. Used as a SECOND guard (the
# first is the award files' own coding) and on USAspending rows, which carry no
# summary call.
VF_HOSPITAL_NAME <- regex(paste0(
  "HOSPITAL|MEDICAL CENTER|HEALTH ?SYSTEM|HEALTHCARE SYSTEM|",
  "\\bSANFORD\\b|\\bAVERA\\b|GUNDERSEN|MAYO CLINIC|GOOD SAMARITAN SOCIETY|",
  "HEALTH FOUNDATION$|BANNER HEALTH"), ignore_case = TRUE)

# Every out-of-state USAspending subrecipient that is NOT in the dictionary,
# read by hand on 2026-11-09, with the reason it is not flagged. The build stops
# on any out-of-state, non-dictionary row missing from this list, so a refresh
# that adds one is read before it is published.
VF_FSRS_REVIEWED_EXCLUSIONS <- tibble::tribble(
  ~subawardee_name, ~reason,
  "MARY HITCHCOCK MEMORIAL HOSPITAL", "hospital (Dartmouth Health), excluded",
  "BANNER HEALTH FOUNDATION", "a hospital system's foundation (§7: HOSPITAL_OR_SYSTEM), excluded",
  "SANFORD HEALTH NETWORK", "health system, excluded",
  "SANFORD MEDICAL CENTER", "hospital, excluded",
  "SANFORD HEALTH", "health system, excluded",
  "AVERA MCKENNAN", "hospital, excluded",
  "GUNDERSEN CLINIC, LTD.", "health system (Emplify/Gundersen), excluded",
  "SAINT ELIZABETH MEDICAL CENTER, INC", "hospital, excluded",
  "SEATTLE CHILDREN'S HOSPITAL", "hospital, excluded",
  "MAT-SU VALLEY MEDICAL CENTER LLC", "hospital (FSRS address is its operator's Franklin TN office), excluded",
  "THE EVANGELICAL LUTHERAN GOOD SAMARITAN SOCIETY", "senior-care subsidiary of Sanford Health (a health system), excluded on the health-system rule",
  "VERMONT ALLIANCE FOR RECOVERY RESIDENCES, INC", "FSRS address Georgetown TX contradicts the organisation's Vermont name and Vermont work; the address is doubted, so the row is NOT flagged out of state (listed in the session doc as unsure)"
)

# Multi-recipient fields (§6.2): the amount is joint and is never divided.
VF_MULTI_RECIPIENT <- c("Alano Club, Comagine Health, Tabor North")

# Same contract seen in two sources at DIFFERENT amounts, paired by hand.
# The first source (keep) survives; the second is cited in also_cited_in.
VF_DEDUPE_PAIRS <- tibble::tribble(
  ~state, ~canonical_name, ~keep_source, ~keep_amount, ~drop_source, ~drop_amount, ~drop_purpose, ~why,
  "UT", "Comagine Health", "USASPENDING_FSRS", 6000000, "STATE_AWARD_FILE", 2000000, "^FAST 4\\.1",
  "Utah's FSRS report 'RHTP AGREEMENT WITH COMAGINE HEALTH FOR FAST 4-1 INITIATIVE' ($6,000,000 executed) is the agreement whose $2,000,000 intent DHHS announced as 'FAST 4.1: Value Based Care'; the executed agreement survives"
)

# -- the dictionary --------------------------------------------------------------

vf_dictionary <- function(path = here::here(VF_DICT)) {
  d <- readr::read_csv(path, col_types = readr::cols(.default = "c"), progress = FALSE,
                       na = character())
  if (!identical(names(d), VF_DICT_COLUMNS)) {
    stop("[vendor] dictionary columns must be exactly: ",
         paste(VF_DICT_COLUMNS, collapse = ", "), call. = FALSE)
  }
  bad <- setdiff(unique(d$entity_class), VF_CLASSES)
  if (length(bad)) stop("[vendor] dictionary class outside the list: ",
                        paste(bad, collapse = ", "), call. = FALSE)
  if (any(d$pattern == "" | d$canonical_name == "" | d$parent_company == "" |
          d$hq_state == "" | d$basis == "")) {
    stop("[vendor] a dictionary entry has an empty required field", call. = FALSE)
  }
  for (p in d$pattern) stringr::str_detect("x", stringr::regex(p, ignore_case = TRUE))
  d
}

#' Match recipient strings to the dictionary. Returns one row per input with the
#' dictionary columns (NA where nothing matched). Stops on an ambiguous match.
vf_match <- function(names, dict = vf_dictionary()) {
  hits <- lapply(seq_len(nrow(dict)), function(i) {
    stringr::str_detect(dplyr::coalesce(names, ""),
                        stringr::regex(dict$pattern[i], ignore_case = TRUE))
  })
  m <- do.call(cbind, hits)
  if (is.null(dim(m))) m <- matrix(m, ncol = nrow(dict))
  idx <- vapply(seq_along(names), function(j) {
    w <- which(m[j, ])
    if (length(w) == 0) return(NA_integer_)
    canon <- unique(dict$canonical_name[w])
    if (length(canon) > 1) {
      stop("[vendor] '", names[j], "' matches more than one dictionary entry: ",
           paste(canon, collapse = " | "), call. = FALSE)
    }
    w[1]
  }, integer(1))
  out <- dict[idx, , drop = FALSE]
  out$matched <- !is.na(idx)
  out
}

# -- role coding ------------------------------------------------------------------

VF_ROLE_ADMIN <- regex(paste0(
  "grant(s)? (management|administration|administrator|assistance)|third[- ]party administrator|",
  "fiscal agent|program (management|administration|design)|project management|",
  "implementation support|technical assistance|evaluat|assessment|consult(ant|ants|ing)\\b|",
  "facilitat|stakeholder|strategic plan|rate (analysis|methodology)|payment (model|readiness)|",
  "data model|performance monitoring|vendor management|staffing|reporting|compliance|",
  "oversight|operate the center|administrative|action plan"), ignore_case = TRUE)
VF_ROLE_DELIVER <- regex(paste0(
  "hospital|provider|patient|clinic|telehealth|remote (patient )?monitoring|equipment|",
  "\\bEHR\\b|facilit(y|ies) upgrade|students|youth|residents|behavioral health services|",
  "recovery residence|mentoring|closed[- ]loop|referral|pharmac|crisis intervention|",
  "obstetric|perinatal|naloxone|dementia|brain injury|GME|medical school|cybersecurity"),
  ignore_case = TRUE)

vf_role_from_text <- function(text) {
  t <- dplyr::coalesce(text, "")
  a <- stringr::str_detect(t, VF_ROLE_ADMIN)
  d <- stringr::str_detect(t, VF_ROLE_DELIVER)
  dplyr::case_when(a & d ~ "MIXED", a ~ "ADMINISTERS_PROGRAM",
                   d ~ "DELIVERS_TO_PROVIDERS", TRUE ~ "UNKNOWN")
}

# Hand overrides, read against the quoted purpose text, keyed on
# state + canonical + source_type + amount. Each carries its reason.
VF_ROLE_OVERRIDES <- tibble::tribble(
  ~state, ~canonical_name, ~source_type, ~amount, ~role, ~why,
  "ID", "Public Consulting Group LLC", "STATE_AWARD_FILE", 14520000, "ADMINISTERS_PROGRAM",
  "'Third Party Administrator for Ladder Payment Program': PCG administers payments that reach providers; it does not deliver care",
  "NM", "Guidehouse Inc.", "USASPENDING_FSRS", 20100772.81, "MIXED",
  "establish and operate the CRHSI 'as the implementation and technical assistance' centre: programme operation plus TA delivered to rural providers",
  "UT", "HK Consulting", "STATE_AWARD_FILE", 11000000, "ADMINISTERS_PROGRAM",
  "'LINCS 7.3-7.4: Semantic Data Model and Applications': state data infrastructure",
  "VT", "McKinsey & Company", "STATE_AWARD_FILE", 5100000, "UNKNOWN",
  "Vermont prints only the pool label 'Regionalization'; nothing on the row says what McKinsey does",
  "CT", "Mathematica Inc.", "STATE_AWARD_FILE", 3980000, "UNKNOWN",
  "Connecticut prints only the pool 'Rural Hospital Right-Sizing and Infrastructure'; the work (an assessment, by the budget narrative's shape) is not stated on the row"
)

# -- the award files ---------------------------------------------------------------

vf_state_files <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"))
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 + which(grepl("^\\)", tf[(i0 + 1):length(tf)]))[1]
  eval(parse(text = tf[i0:i1]))
  STATE_FILES
}

VF_PURPOSE_COLUMNS <- c("description", "project_title", "project", "sub_initiative",
                        "award_pool", "initiative", "activity_type_raw", "list_section")

vf_award_union <- function() {
  sf <- vf_state_files()
  purrr::map_dfr(names(sf), function(k) {
    d <- readr::read_csv(here::here(sf[[k]]), col_types = readr::cols(.default = "c"),
                         progress = FALSE)
    d <- rhtp_year1_only(d, sf[[k]])
    opt <- function(col) if (col %in% names(d)) d[[col]] else rep(NA_character_, nrow(d))
    purpose <- rep(NA_character_, nrow(d))
    purpose_col <- rep(NA_character_, nrow(d))
    for (pc in VF_PURPOSE_COLUMNS) {
      v <- opt(pc)
      take <- is.na(purpose) & !is.na(v) & v != "" & !grepl("^RFP \\(Linked\\)", v)
      purpose[take] <- v[take]; purpose_col[take] <- pc
    }
    tibble::tibble(
      file_key = k, file = sf[[k]], row_no = opt("row_no"),
      state = d$state, recipient = d$awardee,
      amount = suppressWarnings(as.numeric(d$amount)),
      recipient_type = d$recipient_type,
      summary_hospital_call = opt("summary_hospital_call"),
      validation_source_type = d$validation_source_type,
      budget_period = opt("budget_period"),
      state_source_url = d$state_source_url,
      source_archive_path = opt("source_archive_path"),
      vendor_city = opt("vendor_city"), vendor_state = opt("vendor_state"),
      purpose = purpose, purpose_col = purpose_col
    )
  })
}

# Award files that carry no source_archive_path column: where their source is
# archived in this repository.
VF_ARCHIVE_FALLBACK <- c(
  FL = "data/evidence/recheck/2026-08-29/FL/FL_governor_188m_release.html; data/raw/owner_uploads/FL_year1_awardees_original.xlsx (the owner's transcription of the Governor's PDF, R/03e)",
  IN = "data/evidence/IN/2026-08-31_idoa_award_recommendations.html (and the RFP zips beside it)",
  OR = "data/evidence/OR/2026-08-28_oha_RHTP-Awards-Data.xlsx; data/evidence/OR/2026-08-28_oha_rhtp_awards_page.html"
)

vf_is_hospital_row <- function(u) {
  u$summary_hospital_call %in% "HOSPITAL" | u$recipient_type %in% "HOSPITAL_OR_SYSTEM"
}

vf_amount_type_award_file <- function(u) {
  dplyr::case_when(
    is.na(u$amount) ~ "unpriced",
    u$validation_source_type %in% "CMS_OBLIGATION_REPORT" ~ "obligation",
    u$file_key == "SD_CONTRACTS" ~ "contract maximum",
    u$validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD" ~ "intent",
    TRUE ~ "award")
}

vf_from_award_files <- function(dict = vf_dictionary()) {
  u <- vf_award_union()
  u <- u[!vf_is_hospital_row(u), , drop = FALSE]
  m <- vf_match(u$recipient, dict)
  u <- dplyr::bind_cols(u, m %>% dplyr::select(-pattern))
  u <- u[u$matched, , drop = FALSE]
  multi <- u$recipient %in% VF_MULTI_RECIPIENT
  joint <- u$amount
  u$amount[multi] <- NA_real_
  src_type <- dplyr::case_when(
    u$validation_source_type %in% "CMS_OBLIGATION_REPORT" ~ "CMS_OBLIGATION_REPORT",
    u$file_key == "SD_CONTRACTS" ~ "STATE_CONTRACT_REGISTER",
    TRUE ~ "STATE_AWARD_FILE")
  row_addr <- !is.na(u$vendor_state) & u$vendor_state != ""
  tibble::tibble(
    state = u$state, recipient = u$recipient,
    canonical_name = u$canonical_name, parent_company = u$parent_company,
    entity_class = u$entity_class,
    hq_state = dplyr::if_else(row_addr, u$vendor_state, u$hq_state),
    hq_basis = dplyr::if_else(row_addr,
                              paste0("SOURCE_ADDRESS: the source's own vendor address, ",
                                     u$vendor_city, " ", u$vendor_state),
                              u$basis),
    amount = u$amount,
    amount_type = dplyr::if_else(multi, "unpriced", vf_amount_type_award_file(u)),
    budget_period = as.integer(u$budget_period),
    purpose_quote = u$purpose,
    source_type = src_type,
    source_url = u$state_source_url,
    archive_path = dplyr::coalesce(dplyr::na_if(u$source_archive_path, ""),
                                   unname(VF_ARCHIVE_FALLBACK[u$file_key])),
    validation_source_type = u$validation_source_type,
    notes = paste0(
      "Award file ", u$file, " row ", u$row_no,
      dplyr::if_else(is.na(u$purpose_col), "", paste0("; purpose from `", u$purpose_col, "`")),
      dplyr::if_else(multi, paste0("; MULTI-RECIPIENT FIELD, joint amount $",
                                   format(joint, big.mark = ",", nsmall = 2),
                                   " never divided (§6.2)"), ""))
  )
}

# -- USAspending FSRS ---------------------------------------------------------------

vf_from_fsrs <- function(dict = vf_dictionary(), as_of = USA_AS_OF) {
  s <- usa_subawards(as_of)
  hosp <- grepl("HOSPITAL", s$subawardee_business_types, ignore.case = TRUE) |
    stringr::str_detect(s$subawardee_name, VF_HOSPITAL_NAME)
  m <- vf_match(s$subawardee_name, dict)
  oos <- s$subawardee_state_code != s$prime_state
  unreviewed <- oos & !m$matched & !hosp &
    !(s$subawardee_name %in% VF_FSRS_REVIEWED_EXCLUSIONS$subawardee_name)
  if (any(unreviewed)) {
    stop("[vendor] out-of-state USAspending subrecipients nobody has read: ",
         paste(unique(paste0(s$prime_state[unreviewed], ": ", s$subawardee_name[unreviewed],
                             " (", s$subawardee_city_name[unreviewed], " ",
                             s$subawardee_state_code[unreviewed], ")")), collapse = "; "),
         ". Add each to config/vendor_entity_dictionary.csv or to ",
         "VF_FSRS_REVIEWED_EXCLUSIONS with its reason.", call. = FALSE)
  }
  keep <- m$matched & !hosp
  s <- s[keep, , drop = FALSE]; m <- m[keep, , drop = FALSE]
  tibble::tibble(
    state = s$prime_state, recipient = s$subawardee_name,
    canonical_name = m$canonical_name, parent_company = m$parent_company,
    entity_class = m$entity_class,
    hq_state = s$subawardee_state_code,
    hq_basis = paste0("SOURCE_ADDRESS: FSRS subawardee address, ", s$subawardee_city_name,
                      " ", s$subawardee_state_code),
    amount = s$subaward_amount, amount_type = "award", budget_period = 1L,
    purpose_quote = s$subaward_description,
    source_type = "USASPENDING_FSRS",
    source_url = s$usaspending_permalink,
    archive_path = file.path("data/raw/usaspending", as_of, USA_ZIP),
    validation_source_type = NA_character_,
    notes = paste0("FFATA first-tier subaward ", s$subaward_number, " under ",
                   s$prime_award_fain, ", action date ", s$subaward_action_date,
                   ", SAM report modified ", substr(s$subaward_sam_report_last_modified_date, 1, 10))
  )
}

# -- CMS obligation report (10-14 edition) ----------------------------------------------

vf_cms_lines <- function() {
  readr::read_csv(here::here(VF_CMS_LINES), col_types = readr::cols(.default = "c"),
                  progress = FALSE)
}

vf_from_cms_named <- function(dict = vf_dictionary()) {
  l <- vf_cms_lines() %>% dplyr::filter(!is.na(named_orgs), named_orgs != "")
  l <- l %>% tidyr::separate_rows(named_orgs, sep = ";\\s*")
  m <- vf_match(l$named_orgs, dict)
  multi <- as.integer(dplyr::coalesce(l$n_unnamed_others, "0")) > 0 |
    duplicated(l$line_id) | duplicated(l$line_id, fromLast = TRUE)
  keep <- m$matched
  l <- l[keep, ]; m <- m[keep, ]; multi <- multi[keep]
  amt <- as.numeric(l$amount)
  tibble::tibble(
    state = l$state, recipient = l$named_orgs,
    canonical_name = m$canonical_name, parent_company = m$parent_company,
    entity_class = m$entity_class, hq_state = m$hq_state, hq_basis = m$basis,
    amount = dplyr::if_else(multi, NA_real_, amt),
    amount_type = dplyr::if_else(multi, "unpriced", "obligation"),
    budget_period = as.integer(l$budget_period),
    purpose_quote = l$description_clean,
    source_type = "CMS_OBLIGATION_REPORT",
    source_url = VF_CMS_URL, archive_path = VF_CMS_PDF,
    validation_source_type = NA_character_,
    notes = paste0("CMS RHTP Obligated Funds Report (10-14 edition, as of ", l$as_of,
                   "), line ", l$line_id, ", tier ", l$tier,
                   "; an obligation to a first-tier entity, not a confirmed subaward",
                   dplyr::if_else(multi, "; MULTI-RECIPIENT LINE, never divided (§6.2)", ""))
  )
}

VF_UNNAMED_RX <- regex(paste0(
  "contractual (agreement|agreements|support|services)|\\bcontractors?\\b|consultants?\\b|",
  "consulting|administrative vendor|\\b(a|the|procured|selected|grant management) vendor\\b|",
  "third[- ]party|grant (management|administrat)|fiscal agent|professional services"),
  ignore_case = TRUE)
VF_UNNAMED_NOT_RX <- regex("psychiatric|e-consult|tele-consult|consultation|evaluate vendors", ignore_case = TRUE)

#' Unnamed contractor money in the CMS lines, by state. CONTEXT ONLY: never
#' attributed to a firm, never added to a flag figure.
vf_unnamed_contractor <- function(flags = NULL) {
  l <- vf_cms_lines() %>%
    dplyr::filter(is.na(named_orgs) | named_orgs == "") %>%
    dplyr::mutate(amount = as.numeric(amount)) %>%
    dplyr::filter(stringr::str_detect(description_clean, VF_UNNAMED_RX),
                  !stringr::str_detect(description_clean, VF_UNNAMED_NOT_RX),
                  amount > 0)
  named_elsewhere <- character(0)
  if (!is.null(flags)) {
    hit <- l %>% dplyr::inner_join(
      flags %>% dplyr::filter(!is_lead, !is.na(amount)) %>%
        dplyr::select(state, f_amount = amount, flag_id, canonical_name),
      by = "state", relationship = "many-to-many") %>%
      dplyr::filter(abs(amount - f_amount) < 0.01 |
                      (canonical_name == "HealthTech Solutions, LLC" & line_id == "CO-006-09-14"))
    named_elsewhere <- hit$line_id
    l$named_in_flag_file <- vapply(l$line_id, function(i) {
      h <- hit[hit$line_id == i, ]
      if (nrow(h) == 0) "" else paste0(h$canonical_name, " (", h$flag_id, ")", collapse = "; ")
    }, character(1))
  } else {
    l$named_in_flag_file <- ""
  }
  l %>%
    dplyr::group_by(state) %>%
    dplyr::arrange(dplyr::desc(amount), .by_group = TRUE) %>%
    dplyr::summarise(
      n_lines = dplyr::n(),
      unnamed_contractor_obligated = round(sum(amount), 2),
      largest_line_amount = amount[1],
      largest_line_id = line_id[1],
      largest_line_text = description_clean[1],
      line_ids = paste(line_id, collapse = "; "),
      lines_also_named_elsewhere = paste(named_in_flag_file[named_in_flag_file != ""],
                                         collapse = " | "),
      .groups = "drop") %>%
    dplyr::mutate(source = paste0("CMS RHTP Obligated Funds Report, 10-14 edition (",
                                  VF_CMS_URL, "); archive ", VF_CMS_PDF),
                  context_only = TRUE) %>%
    dplyr::arrange(dplyr::desc(unnamed_contractor_obligated))
}

# -- hand rows: budget narratives and the CO annual report -------------------------------

VF_KS_BN <- "data/evidence/budget_narratives/KS/2026-07_ks_rht_plan_budget_narrative_revision_2.pdf"
VF_KS_BN_URL <- "https://www.kdhe.ks.gov/DocumentCenter/View/60171"
VF_CT_BN <- "data/evidence/CT/2026-09-02_ct_dss_rht_budget_narrative_20260407.pdf"
VF_CT_BN_URL <- "https://portal.ct.gov/dss/-/media/departments-and-agencies/dss/health-and-home-care/rural-health-transformation-program/ct-rhtp-budget-narrative-updated-472026.pdf"
VF_CO_AR <- "data/evidence/vendor_flags/2026-11-09/CO/2026-11-09_co_hcpf_annual_report_as_of_6.31.26.xlsx"
VF_CO_AR_URL <- "https://hcpf.colorado.gov/sites/hcpf/files/Colorado%20Annual%20Report%20as%20of%206.31.26.xlsx"

# `check` is a string that must appear (whitespace-squished) in the archived
# document's text; --validate asserts it, so a transcription error fails.
VF_HAND_ROWS <- tibble::tribble(
  ~state, ~recipient, ~amount, ~amount_type, ~role, ~purpose_quote, ~source_type, ~source_url, ~archive_path, ~check, ~notes,
  "KS", "Boston Consulting Group", 4750000, "plan", "ADMINISTERS_PROGRAM",
  "KDHE will contract with BCG to provide rapid response implementation support for the Kansas RHTP, which will support in-depth state-level infrastructure development and improvement.",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "Boston Consulting Group Consulting Services $4,750,000.00",
  "KS Year 1 budget narrative (revision 2), Table 4 Administrative Contracts. A PLAN line, not an award (§0.3).",
  "KS", "BDO Government Services", 2329929, "plan", "ADMINISTERS_PROGRAM",
  "BDO Government Services -- Fiscal Agent. KDHE will contract with a fiscal agent for the RHT",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "BDO Government Services Fiscal Agent $2,329,929.00",
  "KS Year 1 budget narrative, Table 4 Administrative Contracts. A PLAN line.",
  "KS", "BioIntelliSense", 7014500, "plan", "DELIVERS_TO_PROVIDERS",
  "KDHE will sub-award CCA to contract with BioIntelliSense to implement with AHAP's support a centralized continuous remote patient monitoring program for inpatient and post-discharge patients",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "BioIntelliSense Remote Inpatient/Post- $7,014,500.00",
  "KS budget narrative Table 13.E.5 Year 1 Third-Party Contracts, line 'BioIntelliSense Remote Inpatient/Post-acute Monitoring at anchor hospitals'. A PLAN line, contracted by CCA (UKHS Care Collaborative Association, KDHE's subrecipient): second tier.",
  "KS", "BioIntelliSense", 2500000, "plan", "DELIVERS_TO_PROVIDERS",
  "The Year 1 budget also includes $2.5M for CCA to contract with BioIntelliSense to implement and maintain remote monitoring services at non-anchor rural Kansas hospitals",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "BioIntelliSense Remote Monitoring at $2,500,000.00",
  "KS budget narrative Table 13.E.5, line 'BioIntelliSense Remote Monitoring at non-anchor hospitals'. A PLAN line, contracted by CCA: second tier.",
  "KS", "Oracle Clinical AI Agent", 5964000, "plan", "DELIVERS_TO_PROVIDERS",
  "KDHE has budgeted $5,964,000 to sub-award CCA to contract with and provide those Kansas rural clinics utilizing the Oracle Community Works ... with access to Oracle's Clinical AI Agent.",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "Oracle Clinical AI Agent $5,964,000.00",
  "KS budget narrative Table 13.E.5 and Program 4. A PLAN line, contracted by CCA: second tier. Licences for rural clinics at $1.50 per note.",
  "KS", "BioSTL Consulting Services", 750000, "plan", "MIXED",
  "The State has budgeted $600,000 in Year 1 for BioSTL's consulting services ... The State also has budgeted $150,000 for registration fees to permit information technology professionals working for Kansas rural providers to participate in BioSTL's quarterly Innovation Sharing events and annual Innovation Summit.",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "BioSTL Consulting Services $750,000.00",
  "KS budget narrative Table 13.E.5. A PLAN line ($600,000 consulting + $150,000 provider registration fees), contracted by CCA: second tier.",
  "KS", "PYA, PC", 1500000, "plan", "ADMINISTERS_PROGRAM",
  "CCA will contract with PYA, PC, a national healthcare consultancy, to perform a statewide rural provider commercial rate analysis.",
  "BUDGET_NARRATIVE", VF_KS_BN_URL, VF_KS_BN, "The State has budgeted $1.5 million in Year 1 for the commercial rate analysis based on the proposal received from PYA",
  "KS budget narrative, Program 3A. A PLAN line, contracted by CCA: second tier.",
  "CT", "Carelon Behavioral Health, Inc.", 3800000, "plan", "DELIVERS_TO_PROVIDERS",
  "Proposal: ACCESS ASD & SB Mental Health. Provide psychiatric consultation and clinical guidance to SBHC personnel.",
  "BUDGET_NARRATIVE", VF_CT_BN_URL, VF_CT_BN, "Carelon Behavioral Health, Inc.",
  "CT budget narrative (updated 2026-04-07), Contractor 1 column, Totals $3,800,000. A PLAN line.",
  "CT", "Carelon Behavioral Health, Inc. (shared Contractor 1 column)", NA, "unpriced", "UNKNOWN",
  "Contractor 1 Names: Community Health Network of Connecticut, Inc. (CHNCT), Carelon Behavioral Health, Inc., Dental Benefit Management, Inc. d/b/a BeneCare Dental Plans, Myers and Stauffer LLC, and Similar",
  "BUDGET_NARRATIVE", VF_CT_BN_URL, VF_CT_BN, "Myers and Stauffer LLC, and Similar",
  "CT budget narrative: a Contractor 1 column whose total ($18,556,000) is shared by four named firms 'and Similar'; never divided (§6.2).",
  "CT", "Myers and Stauffer LLC", NA, "unpriced", "UNKNOWN",
  "Contractor 1 Names: Community Health Network of Connecticut, Inc. (CHNCT), Carelon Behavioral Health, Inc., Dental Benefit Management, Inc. d/b/a BeneCare Dental Plans, Myers and Stauffer LLC, and Similar",
  "BUDGET_NARRATIVE", VF_CT_BN_URL, VF_CT_BN, "Myers and Stauffer LLC, and Similar",
  "CT budget narrative: shared Contractor 1 column ($18,556,000, four firms 'and Similar'); never divided (§6.2).",
  "CT", "Community Health Network of Connecticut, Inc. (CHNCT)", NA, "unpriced", "UNKNOWN",
  "Contractor 1 Names: Community Health Network of Connecticut, Inc. (CHNCT), Carelon Behavioral Health, Inc., Dental Benefit Management, Inc. d/b/a BeneCare Dental Plans, Myers and Stauffer LLC, and Similar",
  "BUDGET_NARRATIVE", VF_CT_BN_URL, VF_CT_BN, "Community Health Network of Connecticut, Inc. (CHNCT)",
  "CT budget narrative: shared Contractor 1 column; never divided (§6.2).",
  "CT", "Dental Benefit Management, Inc. d/b/a BeneCare Dental Plans", NA, "unpriced", "UNKNOWN",
  "Contractor 1 Names: Community Health Network of Connecticut, Inc. (CHNCT), Carelon Behavioral Health, Inc., Dental Benefit Management, Inc. d/b/a BeneCare Dental Plans, Myers and Stauffer LLC, and Similar",
  "BUDGET_NARRATIVE", VF_CT_BN_URL, VF_CT_BN, "BeneCare Dental Plans",
  "CT budget narrative: shared Contractor 1 column; never divided (§6.2).",
  "CO", "HealthTech Solutions, LLC", 1880900, "obligation", "ADMINISTERS_PROGRAM",
  "Facilitation and Administrative Vendor (Contract); Stakeholder/Advisory Committee Engagement (Contract)",
  "STATE_ANNUAL_REPORT", VF_CO_AR_URL, VF_CO_AR, "HealthTech Solutions, LLC",
  "Colorado Annual Report as of 6.31.26, First-Tier Entities: entity type 'Other Consulting', obligated $1,880,900, disbursed $186,310 (Use of Funds CO13 $50,100 + CO14 $1,830,800). CMS line CO-006-09-14 ($1,830,800, 'facilitation and administrative vendor', unnamed) is the same contract."
)

vf_from_hand_rows <- function(dict = vf_dictionary()) {
  h <- VF_HAND_ROWS
  m <- vf_match(h$recipient, dict)
  if (!all(m$matched)) stop("[vendor] a hand row matches no dictionary entry: ",
                            paste(h$recipient[!m$matched], collapse = "; "), call. = FALSE)
  tibble::tibble(
    state = h$state, recipient = h$recipient,
    canonical_name = m$canonical_name, parent_company = m$parent_company,
    entity_class = m$entity_class, hq_state = m$hq_state, hq_basis = m$basis,
    amount = as.numeric(h$amount), amount_type = h$amount_type, budget_period = 1L,
    purpose_quote = h$purpose_quote, source_type = h$source_type,
    source_url = h$source_url, archive_path = h$archive_path,
    validation_source_type = NA_character_, notes = h$notes,
    role_hand = h$role
  )
}

vf_pdf_text <- function(path) {
  if (!nzchar(Sys.which("pdftotext"))) return(NA_character_)
  out <- system2("pdftotext", c("-layout", shQuote(here::here(path)), "-"), stdout = TRUE)
  stringr::str_squish(paste(out, collapse = " "))
}

vf_validate_hand_rows <- function() {
  texts <- list()
  for (p in unique(VF_HAND_ROWS$archive_path)) {
    if (!file.exists(here::here(p))) stop("[vendor] missing archive: ", p, call. = FALSE)
    texts[[p]] <- if (grepl("\\.pdf$", p)) vf_pdf_text(p) else {
      sh <- readxl::excel_sheets(here::here(p))
      stringr::str_squish(paste(unlist(lapply(sh, function(s) {
        x <- suppressMessages(readxl::read_excel(here::here(p), sheet = s, col_names = FALSE,
                                                 col_types = "text"))
        unlist(x)
      })), collapse = " "))
    }
  }
  for (i in seq_len(nrow(VF_HAND_ROWS))) {
    t <- texts[[VF_HAND_ROWS$archive_path[i]]]
    if (is.na(t)) { message("[vendor] pdftotext absent; skipped ", VF_HAND_ROWS$recipient[i]); next }
    chk <- stringr::str_squish(VF_HAND_ROWS$check[i])
    if (!grepl(chk, t, fixed = TRUE)) {
      stop("[vendor] hand row '", VF_HAND_ROWS$recipient[i], "': '", chk,
           "' not found in ", VF_HAND_ROWS$archive_path[i], call. = FALSE)
    }
  }
  # Colorado's figures, read from the workbook itself.
  fte <- suppressMessages(readxl::read_excel(here::here(VF_CO_AR), sheet = "First-Tier Entities",
                                             col_names = FALSE, col_types = "text"))
  r <- which(fte[[2]] == "HealthTech Solutions, LLC")
  stopifnot(length(r) == 1, fte[[3]][r] == "Other Consulting",
            as.numeric(fte[[4]][r]) == 1880900, as.numeric(fte[[6]][r]) == 186310)
  message("[vendor] hand rows: every check string found in its archive.")
  invisible(TRUE)
}

# -- RCJ leads ------------------------------------------------------------------------

# RCJ leads are read against this repository's own RCJ dispositions
# (data/reference/<st> RCJ disposition tables). EXCLUDE = the disposition
# says the money is not RHTP; LEAD = kept as a labelled lead, with the
# disposition quoted in notes.
VF_RCJ_DISPOSITIONS <- tibble::tribble(
  ~state, ~canonical_name, ~action, ~disposition,
  "TX", "Molina Healthcare", "EXCLUDE", "TX RCJ disposition table: NOT_RHTP_MEDICAID (ATLIS incentive payments to Medicaid MCOs; 'not RHTP, and not to hospitals')",
  "TX", "UnitedHealth Group / Optum", "EXCLUDE", "TX RCJ disposition table: NOT_RHTP_MEDICAID (ATLIS incentive payments to Medicaid MCOs)",
  "CO", "Deloitte Consulting LLP", "EXCLUDE", "CO RCJ disposition table: NOT_RHTP_MEDICAID (a Medicaid work-requirements Advance Planning Document, 'Not RHTP')",
  "CO", "Ernst & Young LLP", "EXCLUDE", "CO RCJ disposition table: NOT_RHTP_MEDICAID (the same work-requirements APD)",
  "TX", "Deloitte Consulting LLP", "LEAD", "TX RCJ disposition table: RHTP_BUT_NOT_A_SUBAWARD ('Deloitte grants-management support at $1,750,000', a budget-narrative line)",
  "AR", "BDO USA / BDO Government Services LLC", "LEAD", "AR RCJ disposition table: RHTP_BUT_NOT_A_SUBAWARD (the Year 1 Revised Budget Narrative's 'Contracted Administrative Costs' line)",
  "NH", "NORC at the University of Chicago", "LEAD", "NH RCJ disposition table: RHTP_ADMINISTRATOR_NO_PRIMARY_AMOUNT (a named GO-NORTH evaluator with no amount this project can source)",
  "NV", "Health Management Associates, Inc.", "LEAD", "NV RCJ disposition table: AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED (NVHA's contractor; the state deck carries none of RCJ's names or figures in its text layer)",
  "NV", "Manatt Health Strategies LLC", "LEAD", "NV RCJ disposition table: AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED (as HMA)",
  "MA", "Deloitte Consulting LLP", "LEAD", "MA RCJ disposition table: RHTP_BUT_NOT_A_SUBAWARD (a project-management RFQ with Deloitte at a $1 placeholder; award UNKNOWN)",
  "IN", "Myers and Stauffer LC", "LEAD", "IN RCJ disposition table covers Indiana's IDOA procurement rows; Myers and Stauffer is not on Indiana's award file"
)

vf_from_rcj <- function(dict = vf_dictionary()) {
  r <- readRDS(here::here("data/interim/stage2_record_table.rds"))
  r <- r %>% dplyr::filter(award_tier == "SUBAWARD")
  nm <- dplyr::coalesce(r$awardee_name_clean, r$awardee_name_raw)
  hosp <- stringr::str_detect(dplyr::coalesce(nm, ""), VF_HOSPITAL_NAME)
  m <- vf_match(nm, dict)
  keep <- m$matched & !hosp & !grepl("PROVENANCE", dplyr::coalesce(r$flag_reason, ""))
  r <- r[keep, ]; m <- m[keep, ]; nm <- nm[keep]
  amt <- suppressWarnings(as.numeric(dplyr::coalesce(r$amount_obligated, r$amount_announced)))
  amt[!is.na(amt) & amt <= 1] <- NA_real_   # RCJ's $1 placeholders are not amounts
  disp <- VF_RCJ_DISPOSITIONS[match(paste(r$state, m$canonical_name),
                                    paste(VF_RCJ_DISPOSITIONS$state, VF_RCJ_DISPOSITIONS$canonical_name)), ]
  out <- tibble::tibble(
    state = r$state, recipient = nm,
    canonical_name = m$canonical_name, parent_company = m$parent_company,
    entity_class = m$entity_class, hq_state = m$hq_state, hq_basis = m$basis,
    amount = amt, amount_type = dplyr::if_else(is.na(amt), "unpriced", "award"),
    budget_period = 1L,
    purpose_quote = NA_character_,
    source_type = "RCJ_LEAD",
    source_url = dplyr::coalesce(r$state_source_url, r$rcj_document_url),
    archive_path = paste0("data/raw/rcj/ (record ", r$record_id, ", pull ", r$pull_date, ")"),
    validation_source_type = NA_character_,
    notes = paste0("LEAD ONLY (RCJ, an aggregator; §0.1): record ", r$record_id,
                   ", document '", stringr::str_trunc(dplyr::coalesce(r$source_doc_title, ""), 80),
                   "'. RCJ's amount field mixes tiers; unverified against a state source.",
                   dplyr::if_else(is.na(disp$disposition), "",
                                  paste0(" This repository's disposition: ", disp$disposition)))
  )
  out[!(disp$action %in% "EXCLUDE"), , drop = FALSE]
}

# -- assembly ---------------------------------------------------------------------------

vf_confidence <- function(f) {
  base <- dplyr::case_when(
    f$source_type == "RCJ_LEAD" ~ "LOW",
    f$source_type %in% c("USASPENDING_FSRS", "STATE_CONTRACT_REGISTER") ~ "HIGH",
    f$source_type == "STATE_AWARD_FILE" &
      f$validation_source_type %in% c("NOTICE_OF_AWARD", "PROCUREMENT_PORTAL_POSTING") ~ "HIGH",
    TRUE ~ "MEDIUM")
  oos_gk <- f$entity_class == "OUT_OF_STATE_ORG" & grepl("^GENERAL_KNOWLEDGE", f$hq_basis)
  dplyr::if_else(oos_gk & base == "HIGH", "MEDIUM", base)
}

VF_SOURCE_PRECEDENCE <- c("STATE_AWARD_FILE", "STATE_CONTRACT_REGISTER", "STATE_ANNUAL_REPORT",
                          "USASPENDING_FSRS", "CMS_OBLIGATION_REPORT", "BUDGET_NARRATIVE",
                          "RCJ_LEAD")

vf_cite <- function(f) {
  paste0(f$source_type, ": ", dplyr::coalesce(f$source_url, ""),
         dplyr::if_else(is.na(f$amount), "", paste0(" ($", format(f$amount, big.mark = ",",
                                                                   nsmall = 2, trim = TRUE), ")")))
}

#' De-duplicate: the same contract seen in two sources keeps ONE row (the
#' higher-precedence source) and both citations. Automatic only on an exact
#' state + canonical + amount match; different amounts are paired by hand.
vf_dedupe <- function(f) {
  f$also_cited_in <- ""
  f$.prec <- match(f$source_type, VF_SOURCE_PRECEDENCE)
  f$.key <- ifelse(is.na(f$amount), NA_character_,
                   paste(f$state, f$canonical_name, sprintf("%.2f", f$amount)))
  f <- f[order(f$.prec), ]
  drop <- rep(FALSE, nrow(f))
  for (k in unique(stats::na.omit(f$.key))) {
    w <- which(f$.key %in% k)
    if (length(w) < 2) next
    first <- w[1]
    for (j in w[-1]) {
      if (f$.origin[j] == f$.origin[first]) next   # two lines of one source, not two sources
      f$also_cited_in[first] <- paste(c(f$also_cited_in[first][f$also_cited_in[first] != ""],
                                        vf_cite(f[j, ])), collapse = " | ")
      drop[j] <- TRUE
    }
  }
  for (i in seq_len(nrow(VF_DEDUPE_PAIRS))) {
    p <- VF_DEDUPE_PAIRS[i, ]
    k <- which(!drop & f$state == p$state & f$canonical_name == p$canonical_name &
                 f$source_type == p$keep_source & abs(dplyr::coalesce(f$amount, -1) - p$keep_amount) < 0.01)
    d <- which(!drop & f$state == p$state & f$canonical_name == p$canonical_name &
                 f$source_type == p$drop_source & abs(dplyr::coalesce(f$amount, -1) - p$drop_amount) < 0.01 &
                 grepl(p$drop_purpose, dplyr::coalesce(f$purpose_quote, "")))
    if (length(k) != 1 || length(d) != 1) {
      stop("[vendor] hand dedupe pair not found exactly once: ", p$state, " ",
           p$canonical_name, call. = FALSE)
    }
    f$also_cited_in[k] <- paste(c(f$also_cited_in[k][f$also_cited_in[k] != ""],
                                  paste0(vf_cite(f[d, ]), " [", f$amount_type[d], "; ", p$why, "]")),
                                collapse = " | ")
    drop[d] <- TRUE
  }
  # A lead already confirmed by any state-sourced row for the same firm and state
  # adds nothing.
  confirmed <- unique(paste(f$state[f$source_type != "RCJ_LEAD" & !drop],
                            f$canonical_name[f$source_type != "RCJ_LEAD" & !drop]))
  drop <- drop | (f$source_type == "RCJ_LEAD" & paste(f$state, f$canonical_name) %in% confirmed)
  f[!drop, setdiff(names(f), c(".prec", ".key", ".origin")), drop = FALSE]
}

vf_build_flags <- function() {
  dict <- vf_dictionary()
  parts <- list(award_file = vf_from_award_files(dict), fsrs = vf_from_fsrs(dict),
                cms_line = vf_from_cms_named(dict), hand = vf_from_hand_rows(dict),
                rcj = vf_from_rcj(dict))
  f <- dplyr::bind_rows(parts, .id = ".origin")
  f$out_of_state <- dplyr::if_else(f$hq_state %in% c("UNKNOWN", ""), NA, f$hq_state != f$state)
  # OUT_OF_STATE_ORG is a class only where the recipient IS out of state.
  f <- f[!(f$entity_class == "OUT_OF_STATE_ORG" & !(f$out_of_state %in% TRUE)), , drop = FALSE]
  f$is_lead <- f$source_type == "RCJ_LEAD"
  f$confidence <- vf_confidence(f)
  f <- vf_dedupe(f)
  # Role: hand role where given, else the hand override table, else the text rule.
  role <- vf_role_from_text(f$purpose_quote)
  if ("role_hand" %in% names(f)) role <- dplyr::coalesce(f$role_hand, role)
  for (i in seq_len(nrow(VF_ROLE_OVERRIDES))) {
    o <- VF_ROLE_OVERRIDES[i, ]
    w <- which(f$state == o$state & f$canonical_name == o$canonical_name &
                 f$source_type == o$source_type & abs(dplyr::coalesce(f$amount, -1) - o$amount) < 0.01)
    if (length(w) != 1) stop("[vendor] role override not found exactly once: ", o$state,
                             " ", o$canonical_name, " ", o$amount, call. = FALSE)
    role[w] <- o$role
    f$notes[w] <- paste0(f$notes[w], "; role by hand: ", o$why)
  }
  f$role <- role
  f <- f %>%
    dplyr::arrange(state, entity_class, canonical_name, dplyr::desc(amount)) %>%
    dplyr::mutate(flag_id = sprintf("VF%04d", dplyr::row_number()))
  f[, VF_FLAG_COLUMNS]
}

vf_assert_flags <- function(f) {
  stopifnot(
    identical(names(f), VF_FLAG_COLUMNS),
    all(f$entity_class %in% VF_CLASSES),
    all(f$amount_type %in% VF_AMOUNT_TYPES),
    all(f$role %in% VF_ROLES),
    all(f$source_type %in% VF_SOURCE_TYPES),
    all(f$confidence %in% c("HIGH", "MEDIUM", "LOW")),
    all(f$budget_period %in% 1L),
    !any(is.na(f$amount) & f$amount_type != "unpriced"),
    !any(!is.na(f$amount) & f$amount_type == "unpriced"),
    all(!is.na(f$source_url) & f$source_url != ""),
    all(f$confidence[f$is_lead] == "LOW"),
    !any(stringr::str_detect(f$canonical_name, VF_HOSPITAL_NAME)),
    !anyDuplicated(f$flag_id)
  )
  invisible(TRUE)
}

# -- tabs -------------------------------------------------------------------------------

#' "Top cases": a CASE is one firm's flagged lines in one state from one source
#' at one amount type (Rhode Island's 26 Alvarez & Marsal obligation lines are
#' one case). Cases of $1M or more, ranked by amount. Leads are labelled.
vf_top_cases <- function(f, floor = VF_TOP_FLOOR) {
  f %>%
    dplyr::filter(!is.na(amount)) %>%
    dplyr::group_by(state, canonical_name, parent_company, entity_class, hq_state,
                    out_of_state, amount_type, source_type, is_lead) %>%
    dplyr::summarise(
      amount = round(sum(amount), 2), n_lines = dplyr::n(),
      recipient = paste(unique(recipient), collapse = " / "),
      role = if (dplyr::n_distinct(role) == 1) role[1] else "MIXED",
      purpose_quote = stringr::str_trunc(purpose_quote[which.max(amount)], 300),
      source_url = source_url[which.max(amount)],
      archive_path = archive_path[which.max(amount)],
      confidence = confidence[which.max(amount)],
      flag_ids = paste(flag_id, collapse = "; "),
      also_cited_in = paste(also_cited_in[also_cited_in != ""], collapse = " | "),
      .groups = "drop") %>%
    dplyr::filter(amount >= floor) %>%
    dplyr::mutate(label = dplyr::if_else(is_lead, "LEAD (RCJ, unverified; not ranked)", "")) %>%
    dplyr::arrange(is_lead, dplyr::desc(amount)) %>%
    dplyr::mutate(rank = dplyr::if_else(is_lead, NA_integer_, cumsum(!is_lead))) %>%
    dplyr::select(rank, label, state, recipient, canonical_name, parent_company, entity_class,
                  hq_state, out_of_state, amount, amount_type, n_lines, role, purpose_quote,
                  source_type, source_url, archive_path, confidence, also_cited_in, flag_ids)
}

#' "By firm": per parent company, split by amount type and role. Never a total
#' across amount types. Leads are counted, not totalled.
vf_by_firm <- function(f) {
  nl <- f %>% dplyr::filter(!is_lead)
  nl %>%
    dplyr::group_by(parent_company, entity_class, amount_type, role) %>%
    dplyr::summarise(amount = if (all(is.na(amount))) NA_real_ else round(sum(amount, na.rm = TRUE), 2),
                     rows = dplyr::n(), unpriced_rows = sum(is.na(amount)),
                     states = paste(sort(unique(state)), collapse = " "),
                     .groups = "drop") %>%
    dplyr::left_join(f %>% dplyr::filter(is_lead) %>% dplyr::count(parent_company, name = "lead_rows_not_totalled"),
                     by = "parent_company") %>%
    dplyr::mutate(lead_rows_not_totalled = dplyr::coalesce(lead_rows_not_totalled, 0L)) %>%
    dplyr::group_by(parent_company) %>%
    dplyr::mutate(.firm_max = max(dplyr::coalesce(amount, 0))) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(dplyr::desc(.firm_max), parent_company, amount_type, role) %>%
    dplyr::select(-.firm_max)
}

vf_by_class <- function(f) {
  f %>% dplyr::filter(!is_lead) %>%
    dplyr::group_by(entity_class, amount_type) %>%
    dplyr::summarise(amount = if (all(is.na(amount))) NA_real_ else round(sum(amount, na.rm = TRUE), 2),
                     rows = dplyr::n(),
                     firms = dplyr::n_distinct(parent_company),
                     out_of_state_rows = sum(out_of_state %in% TRUE), .groups = "drop") %>%
    dplyr::arrange(factor(entity_class, VF_CLASSES), factor(amount_type, VF_AMOUNT_TYPES))
}

VF_NOTES <- c(
  "INTERNAL ONLY. For AHA colleagues. Not for publication, distribution or citation outside AHA.",
  "",
  "WHAT THIS IS. Examples of Rural Health Transformation Program (RHTP, Assistance Listing 93.798) money flagged to large consulting firms, technology/EHR vendors, insurers/MCOs, and non-hospital organisations headquartered outside the awarding state. Every row cites a source and an archived copy. It is a set of documented examples, not a census and not an estimate of total vendor spending.",
  "",
  "HOSPITAL EXCLUSION. Hospitals and health systems are never flagged, in any state. Any recipient whose summary call is HOSPITAL, or whose recipient type is HOSPITAL_OR_SYSTEM, is excluded from every class and every tab. USAspending rows with a hospital business type or a hospital/health-system name are excluded the same way; out-of-state USAspending hospitals (Dartmouth's Mary Hitchcock, Sanford, Avera, Gundersen, Banner Health Foundation, Seattle Children's, Saint Elizabeth, Mat-Su Valley) and Sanford's Good Samaritan Society are listed in R/09_vendor_flags.R with the reason.",
  "",
  "COVERAGE LIMITS. (1) The state award files skew to SUBAWARDS (grants to providers and community organisations); states' own administrative CONTRACTS with consultants are usually not published on the award pages this project reads. (2) USAspending/FFATA subaward reports cover first-tier subawards of $30,000 or more and, under 2 CFR 170, NOT procurement contracts, so the largest consulting contracts generally do not appear there; 19 of 50 states had filed no RHTP subaward at all on 2026-11-09 (AL AR CA CO FL GA LA MA MD MI MO MS NH NJ NY PA SC WI WY). (3) The CMS obligation report names a recipient on only some lines; unnamed contractor money is shown by state as context and is never attributed to a firm. (4) Budget-narrative lines are PLANS, not awards. (5) RCJ rows are leads only. (6) Second-tier contracts (a subrecipient's own vendors, e.g. Kansas's CCA contracting BioIntelliSense) are visible only where a plan or report names them.",
  "",
  "AMOUNT TYPES (never added together): award = an executed award or FFATA-reported subaward amount; intent = a notice of intent / recommended amount not yet executed; obligation = an amount the state reported as obligated to the entity (CMS obligation report, state annual report); contract maximum = a contract register's not-to-exceed value (South Dakota open.sd.gov); plan = a budget-narrative line; unpriced = named with no per-recipient amount (including multi-recipient fields, never divided).",
  "",
  "ROLE RULE. Coded from the source's own purpose text, quoted in purpose_quote: ADMINISTERS_PROGRAM = runs, manages, plans, studies or evaluates the programme for the state (grant management, fiscal agent, TPA, TA, evaluation, assessments, data infrastructure); DELIVERS_TO_PROVIDERS = delivers goods or services to providers, patients or communities (devices, software for clinics, clinical services, training); MIXED = both appear; UNKNOWN = the source gives only a programme label or a generic sentence. A small number of large rows were coded by hand; each reason is in notes.",
  "",
  "OUT OF STATE. Rests on a source address (USAspending FSRS subawardee address; South Dakota's contract register vendor address) where one exists, otherwise on the firm's headquarters from general knowledge, marked GENERAL_KNOWLEDGE in hq_basis. hq_state UNKNOWN means neither was established. An office address (e.g. Deloitte's Lake Mary FL) can differ from headquarters; either is outside the awarding state where flagged.",
  "",
  "CONFIDENCE (of the flag, not of a hospital determination): HIGH = the firm and the amount appear on a primary filing (notice of award, contract register, FFATA report); MEDIUM = intent, press release, obligation report, plan line, or an out-of-state call resting on general knowledge; LOW = RCJ lead.",
  "",
  "DE-DUPLICATION. The same contract seen in two sources is one row, with the other citation in also_cited_in. Automatic only on an exact state + firm + amount match; Utah's Comagine FAST 4.1 agreement ($2.0M intent vs $6.0M FFATA-reported) is paired by hand.",
  "",
  "DELAWARE. Delaware's confidential hand-verified source (DE Verify.xlsx) is NOT used. Delaware rows come from USAspending only.",
  "",
  "SOURCES. USAspending.gov custom award download for 93.798 (fetched 2026-11-09, data/raw/usaspending/2026-11-09/); the committed Year 1 state award files (budget_period == 1); CMS RHTP Obligated Funds Report, 10-14 edition (data as of 2026-07-31); South Dakota open.sd.gov contract register; Kansas and Connecticut budget narratives; Colorado's Annual Report as of 6.31.26 (archived 2026-11-09); RCJ (leads only). Texas's BP1 first-tier report, Oklahoma's legislative quarterly reports and Indiana's IDOA award letters were read: Texas names only hospital districts, Oklahoma names agencies and LifeCare, and Indiana's vendors are already in the award file.",
  "",
  "This layer changes no award row, summary call, hospital bucket or hospital figure.")

vf_write_xlsx <- function(f, unnamed, as_of = VF_AS_OF) {
  wb <- openxlsx::createWorkbook()
  hs <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#DDE3EA", wrapText = TRUE)
  money <- openxlsx::createStyle(numFmt = "$#,##0")
  add <- function(name, df, money_cols = character(0), widths = NULL) {
    openxlsx::addWorksheet(wb, name)
    openxlsx::writeData(wb, name, df, headerStyle = hs)
    openxlsx::freezePane(wb, name, firstRow = TRUE)
    for (mc in intersect(money_cols, names(df))) {
      openxlsx::addStyle(wb, name, money, rows = 2:(nrow(df) + 1),
                         cols = which(names(df) == mc), gridExpand = TRUE)
    }
    openxlsx::setColWidths(wb, name, cols = seq_along(df), widths = widths %||% "auto")
  }
  top <- vf_top_cases(f)
  add("Top cases", top, c("amount"),
      widths = pmin(pmax(nchar(names(top)) + 2, 10), 45))
  add("By firm", vf_by_firm(f), c("amount"))
  add("Unnamed contractor money", unnamed,
      c("unnamed_contractor_obligated", "largest_line_amount"),
      widths = c(7, 9, 16, 14, 14, 60, 40, 40, 40, 12))
  add("All flags", f, c("amount"),
      widths = pmin(pmax(nchar(names(f)) + 2, 10), 40))
  openxlsx::addWorksheet(wb, "Notes")
  openxlsx::writeData(wb, "Notes", data.frame(Notes = VF_NOTES), colNames = FALSE)
  openxlsx::setColWidths(wb, "Notes", cols = 1, widths = 160)
  openxlsx::addStyle(wb, "Notes", openxlsx::createStyle(wrapText = TRUE),
                     rows = seq_along(VF_NOTES), cols = 1)
  openxlsx::saveWorkbook(wb, VF_XLSX(as_of), overwrite = TRUE)
  message("[vendor] wrote ", VF_XLSX(as_of))
}

vf_read_flags <- function() {
  readr::read_csv(here::here(VF_FLAGS_CSV), progress = FALSE,
                  col_types = readr::cols(amount = "d", budget_period = "i",
                                          out_of_state = "l", is_lead = "l",
                                          .default = "c"),
                  na = c("", "NA"))
}

vf_build <- function() {
  f <- vf_build_flags()
  vf_assert_flags(f)
  readr::write_csv(f, here::here(VF_FLAGS_CSV), na = "")
  un <- vf_unnamed_contractor(f)
  readr::write_csv(un, here::here(VF_UNNAMED_CSV), na = "")
  message("[vendor] wrote ", VF_FLAGS_CSV, " (", nrow(f), " rows) and ", VF_UNNAMED_CSV)
  invisible(f)
}

vf_report <- function(f = vf_read_flags()) {
  fmt <- function(x) paste0("$", format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE))
  cat("Vendor flags:", nrow(f), "rows,", sum(f$is_lead), "leads\n\n")
  cat("Top 15 cases (>= $1M):\n")
  t <- vf_top_cases(f)
  for (i in seq_len(min(15, nrow(t)))) {
    cat(sprintf("%2d. %s %s | %s %s | %s | %s | %s\n", t$rank[i], t$state[i], t$canonical_name[i],
                fmt(t$amount[i]), t$amount_type[i], t$role[i],
                stringr::str_trunc(t$purpose_quote[i], 70), t$source_type[i]))
  }
  cat("\nBy class (non-lead):\n"); print(as.data.frame(vf_by_class(f)))
  cat("\nLargest firms (sum of priced non-lead rows, BY AMOUNT TYPE -- never across):\n")
  bf <- f %>% dplyr::filter(!is_lead, !is.na(amount)) %>%
    dplyr::group_by(parent_company, amount_type) %>%
    dplyr::summarise(amount = sum(amount), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(amount))
  print(as.data.frame(head(bf, 25)))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) vf_validate_hand_rows()
  if ("--build" %in% args) vf_build()
  if ("--xlsx" %in% args) {
    f <- vf_read_flags()
    vf_write_xlsx(f, readr::read_csv(here::here(VF_UNNAMED_CSV), show_col_types = FALSE,
                                     progress = FALSE))
  }
  if ("--report" %in% args) vf_report()
}

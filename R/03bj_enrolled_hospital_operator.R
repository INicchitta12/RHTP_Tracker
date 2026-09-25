# 03bj_enrolled_hospital_operator.R --------------------------------------------
# Session 71. Two corrections applied as ONE overlay, after session 49's:
#
#   1. §10.2 "Academic health centers and enrolled hospital operators" (the
#      AHC_ENROLLED_HOSPITAL_OPERATOR decision). Where CMS enrols the awardee's
#      LEGAL ENTITY as a hospital, the recipient is HOSPITAL_OR_SYSTEM and the
#      CCN goes on the row. The enrolment is a primary federal source; keeping
#      an awardee at UNIVERSITY_OR_AHC because its name reads "university" is
#      recognition overriding a federal record, which §0.4 forbids. The
#      activity does not decide it (§0.3a). Rows re-typed as academic health
#      centres carry recipient_subtype = ACADEMIC_HEALTH_CENTER so a hospital
#      figure can be reported with them separately or subtracted.
#
#   2. Session 49's OTHER rows that state no form. Session 49's check required
#      only ten characters of basis, so a basis that said "could not identify"
#      or "names no organization" passed. OTHER means a DETERMINED form (§8);
#      those five rows go back to §8's standing fallback.
#
# HOW THE MATCHING WORKS, AND WHY IT IS NOT FUZZY.
#   The machine sweep (`eh_sweep()`) finds only EXACT matches: the awardee's
#   entity half (the whole string, the part before a comma/parenthesis/dash, or
#   the part after " at ") equals an enrolment's ORGANIZATION NAME, or equals
#   its DBA, after case/punctuation/corporate-suffix normalisation. A PREFIX is
#   never matched by machine: "University of Alabama" is a prefix of
#   "University of Alabama at Birmingham" and is a different legal body (§2).
#   The three hand-read bridges (UNC, Iowa, Washoe Barton) are listed by name
#   in EH_APPLY with the reason each is one body, at LOW.
#
#   Every sweep hit must carry a hand-read verdict in EH_APPLY or EH_HOLD, and
#   the build refuses an unread one -- the §0.1 mode-6 sweep's design
#   (SWEEP_VERDICTS): a sweep FLAGS and a human READS.
#
# WHERE THE AWARDING STATE STATES A DIFFERENT FORM, THE STATE'S FORM STANDS.
#   Alaska's own Organization Type column ("Tribal Health Organization", "State
#   Agency") and Oregon's Rural Health Clinic table are the awarding state's own
#   award documents. Session 71 queued the disagreement
#   (ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM); session 72 resolved it at
#   option (a) on the owner's instruction and patched §10.2 with the precedence
#   rule: the state's stated form stands, and the CMS enrolment is RECORDED on
#   the row (cms_enrolment_record) without re-typing it. cms_enrolment_match
#   stays empty on those rows, because it means "re-typed on the enrolment".
#
# REBUILD ORDER. builder -> session 49's vq_overlay() -> (state's own post-steps,
# e.g. ar_resolve_narhc) -> s71_overlay(). `--apply` patches the committed
# files as raw strings, which round-trips all 38 state files byte-identically
# when nothing changes (checked session 71), so it moves no untouched cell.
#
# Usage:
#   Rscript R/03bj_enrolled_hospital_operator.R --report   # sweep + verdicts
#   Rscript R/03bj_enrolled_hospital_operator.R --apply    # patch state files
#   Rscript R/03bj_enrolled_hospital_operator.R --totals   # partition by state

suppressPackageStartupMessages({
  source(here::here("R", "utils_config.R"))
  source(here::here("R", "utils_recipient_classification.R"))
})

`%>%` <- magrittr::`%>%`

EH_TAG <- "RECIPIENT TYPE FROM CMS HOSPITAL ENROLMENT (session 71)"
EH_WD_TAG <- "OTHER WITHDRAWN (session 71)"
EH_HOLD_TAG <- "STATE-STATED FORM STANDS OVER CMS ENROLMENT (session 72)"
EH_NEW_COLS <- c("recipient_subtype", "cms_enrolment_match",
                 "cms_enrolment_record")

# -- the enrolment files --------------------------------------------------------

#' Every archived CMS Hospital Enrollments extract, one per state
eh_enrolment_files <- function() {
  f <- c(Sys.glob(here::here("data/evidence/federal_records/*/cms_hosp_enrollments_*.json")),
         Sys.glob(here::here("data/evidence/SD/federal_records/*/cms_hosp_enrollments_*.json")))
  stats::setNames(f, sub("^cms_hosp_enrollments_([A-Z]{2})\\.json$", "\\1",
                         basename(f)))
}

#' CMS prints a CCN as a number, so 040016 arrives as "40016". Pad the
#' all-digit five-character form back to six; leave alphanumeric unit CCNs.
eh_ccn6 <- function(x) {
  ifelse(grepl("^[0-9]{5}$", x), paste0("0", x), x)
}

eh_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- gsub("\\b(THE|INC|LLC|LTD|CORP|CORPORATION|INCORPORATED)\\b", " ", x)
  stringr::str_squish(x)
}

eh_enrolments <- function(files = eh_enrolment_files()) {
  purrr::imap_dfr(files, function(p, st) {
    j <- jsonlite::fromJSON(p)
    tibble::tibble(
      enrol_state = st,
      ccn  = eh_ccn6(j[["CCN"]]),
      org  = j[["ORGANIZATION NAME"]],
      dba  = j[["DOING BUSINESS AS NAME"]],
      loc  = j[["PRACTICE LOCATION TYPE"]],
      ptype = j[["PROVIDER TYPE TEXT"]],
      enrol_file = sub(paste0("^", here::here(), "/"), "", p)
    )
  })
}

# -- hand-read verdicts ---------------------------------------------------------

#' Rows RE-TYPED. Keyed on (file, awardee) EXACT string; `n` is the number of
#' rows carrying that string that the rule re-types, asserted every run.
#' match: EXACT_LEGAL_NAME (MEDIUM, ORG_WEBSITE) or a hand-read bridge,
#' LEGAL_NAME_TRUNCATED / DBA_OF_LEGAL_ENTITY (LOW, GENERAL_KNOWLEDGE).
EH_APPLY <- tibble::tribble(
  ~file, ~awardee, ~n, ~ccn, ~cms_org, ~match, ~ahc, ~why,
  # --- academic health centres -------------------------------------------------
  "ar_year1_awardees.csv", "University of Arkansas for Medical Sciences", 2L,
    "040016", "UNIVERSITY OF ARKANSAS FOR MEDICAL SCIENCES (dba UAMS MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "ar_year1_round2_awardees.csv", "University of Arkansas for Medical Sciences", 2L,
    "040016", "UNIVERSITY OF ARKANSAS FOR MEDICAL SCIENCES (dba UAMS MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "al_year1_awardees.csv", "The University of Alabama at Birmingham", 3L,
    "010033", "UNIVERSITY OF ALABAMA AT BIRMINGHAM (dba UNIVERSITY OF ALABAMA HOSPITAL)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "al_year1_awardees.csv", "University of South Alabama", 1L,
    "010087", "UNIVERSITY OF SOUTH ALABAMA (main hospital location, Mobile; also CCN 013301)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "al_year1_awardees.csv", "The University of South Alabama", 1L,
    "010087", "UNIVERSITY OF SOUTH ALABAMA (main hospital location, Mobile; also CCN 013301)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "or_year1_awardees.csv", "Oregon Health & Science University, Northwest Native American Center of Excellence (NNACoE)", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "or_year1_awardees.csv", "Oregon Health & Science University, Oregon Health & Science University - Department of Neurology", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "OHA's own Organization Type for this row includes 'Hospital or Hospital System'. ",
  "or_year1_awardees.csv", "Oregon Health & Science University, Oregon Health & Science University - Section of Addiction Medicine", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "OHA's own Organization Type for this row includes 'Hospital or Hospital System'. ",
  "or_year1_awardees.csv", "Oregon Health & Science University, Oregon Perinatal Collaborative", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "or_year1_awardees.csv", "Oregon Health & Science University, University Center for Excellence on Development and Disability", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "OHA's own Organization Type for this row includes 'Hospital or Hospital System'. ",
  "or_year1_awardees.csv", "Oregon Office of Rural Health at Oregon Health & Science University", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "The unit is named 'at' the legal entity (§0.3a's awardee-field corollary: code the half that is the recipient). OHA's own Organization Type for this row includes 'Hospital or Hospital System'. ",
  "or_year1_awardees.csv", "Oregon Health & Science University (OHSU)", 1L,
    "380009", "OREGON HEALTH & SCIENCE UNIVERSITY (dba OHSU HOSPITALS AND CLINICS)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "wa_year1_awardees.csv", "University of Washington (WWAMI Family Medicine Residency Network)", 1L,
    "500008", "UNIVERSITY OF WASHINGTON (dba UNIVERSITY OF WASHINGTON MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "wa_year1_awardees.csv", "University of Washington (School of Medicine, Project ECHO)", 1L,
    "500008", "UNIVERSITY OF WASHINGTON (dba UNIVERSITY OF WASHINGTON MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "wy_year1_awardees.csv", "University of Utah", 1L,
    "460009", "UNIVERSITY OF UTAH (dba UNIVERSITY OF UTAH HOSPITALS AND CLINICS), Salt Lake City",
    "EXACT_LEGAL_NAME", TRUE, "An OUT-OF-STATE hospital operator funded by Wyoming (Vermont's Mary Hitchcock precedent): the row stays in Wyoming's file and partition. ",
  "mi_year1_awardees.csv", "Regents of the University of Michigan - Overdose Prevention Engagement Network (OPEN)", 1L,
    "230046", "REGENTS OF THE UNIVERSITY OF MICHIGAN (dba UNIVERSITY OF MICHIGAN HEALTH)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "mi_year1_awardees.csv", "Regents of the University of Michigan - Ready to Respond: Rural Nursing Home Emergency Preparedness", 1L,
    "230046", "REGENTS OF THE UNIVERSITY OF MICHIGAN (dba UNIVERSITY OF MICHIGAN HEALTH)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "ga_great_health_awards.csv", "Emory University", 1L,
    "110010", "EMORY UNIVERSITY (dba EMORY UNIVERSITY HOSPITAL)",
    "EXACT_LEGAL_NAME", TRUE, "",
  "nc_year1_awardees.csv", "University of North Carolina Hospitals", 1L,
    "340061", "UNIVERSITY OF NORTH CAROLINA HOSPITALS AT CHAPEL HILL (dba UNC HOSPITALS)",
    "LEGAL_NAME_TRUNCATED", TRUE, "HAND-READ BRIDGE: the awardee string is the enrolled legal name without its place qualifier 'at Chapel Hill', and NCDHHS's own Hub Leads page calls it 'a public academic medical center providing patient care'. ",
  "ia_year1_awardees.csv", "University of Iowa Health Care", 1L,
    "160058", "STATE UNIVERSITY OF IOWA (dba UNIVERSITY OF IOWA HEALTH CARE MEDICAL CENTER)",
    "DBA_OF_LEGAL_ENTITY", TRUE, "HAND-READ BRIDGE: 'University of Iowa Health Care' is the trading name the State University of Iowa enrols its hospital under; it is not the university's legal name, so it is a bridge, not an exact match. ",
  "ia_year1_awardees.csv", "University of Iowa Healthcare", 1L,
    "160058", "STATE UNIVERSITY OF IOWA (dba UNIVERSITY OF IOWA HEALTH CARE MEDICAL CENTER)",
    "DBA_OF_LEGAL_ENTITY", TRUE, "HAND-READ BRIDGE: Iowa's second spelling ('Healthcare' for 'Health Care') of the same trading name; not merged with the first (§2), each typed on its own reading. ",
  # --- enrolled hospital operators that are not academic health centres ---------
  "al_year1_awardees.csv", "AltaPointe Health Systems Inc.", 1L,
    "014014", "ALTAPOINTE HEALTH SYSTEMS INC (dba BAYPOINTE BEHAVIORAL HEALTH; also EASTPOINTE HOSPITAL, 014017)",
    "EXACT_LEGAL_NAME", FALSE, "Session 12's curated override held this row back because 'the release does not state which entity received the grant'. CMS answers that: the entity the release names, AltaPointe Health Systems Inc, is itself the enrolled psychiatric hospital operator. OWNER-ACCEPTED (session 72): the governor's release states no form for AltaPointe, so no state source contradicts the enrolment and §10.2's precedence rule leaves CMS to decide; the grant is to the legal entity that holds the enrolment, whichever of its programmes the project funds (§0.3a). ",
  "al_year1_awardees.csv", "AltaPointe Health Systems", 2L,
    "014014", "ALTAPOINTE HEALTH SYSTEMS INC (dba BAYPOINTE BEHAVIORAL HEALTH; also EASTPOINTE HOSPITAL, 014017)",
    "EXACT_LEGAL_NAME", FALSE, "Session 12's curated override held this row back because 'the release does not state which entity received the grant'. CMS answers that: the entity the release names, AltaPointe Health Systems Inc, is itself the enrolled psychiatric hospital operator. OWNER-ACCEPTED (session 72): the governor's release states no form for AltaPointe, so no state source contradicts the enrolment and §10.2's precedence rule leaves CMS to decide; the grant is to the legal entity that holds the enrolment, whichever of its programmes the project funds (§0.3a). ",
  "ak_year1_awardees.csv", "Providence Health & Services- Washington", 1L,
    "020001", "PROVIDENCE HEALTH & SERVICES WASHINGTON (dba PROVIDENCE ALASKA MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", FALSE, "Alaska's own Organization Type on this project names only a service line ('Family medicine or primary care'), so the row sat on §8's fallback; five other rows for the same string are already HOSPITAL_OR_SYSTEM on Alaska's 'Hospital (all types)'. ",
  "la_year1_awardees.csv", "Ochsner Clinic Foundation", 1L,
    "190036", "OCHSNER CLINIC FOUNDATION (dba OCHSNER MEDICAL CENTER)",
    "EXACT_LEGAL_NAME", FALSE, "LDH states no form; the row sat on §8's fallback. ",
  "ok_year1_awardees.csv", "Choctaw Nation of Oklahoma", 1L,
    "370172", "CHOCTAW NATION OF OKLAHOMA (tribal hospital enrolment, Stigler)",
    "EXACT_LEGAL_NAME", FALSE, "OSDH states no form; TRIBAL_ORG was a curated override on the name (session 25), which is recognition and does not outrank the enrolment. ",
  "nv_year1_awardees.csv", "Carson Valley Health", 1L,
    "291306", "WASHOE BARTON MEDICAL CLINIC A NEVADA NONPROFIT CORPORATION (dba CARSON VALLEY HEALTH)",
    "DBA_OF_LEGAL_ENTITY", FALSE, "HAND-READ BRIDGE: the awardee is the enrolled hospital's exact DBA, and rows 41 and 71 of this file carry the identical string as HOSPITAL_OR_SYSTEM already (session 49). ",
  "nv_year1_awardees.csv", "Washoe Barton Medical Clinic", 1L,
    "291306", "WASHOE BARTON MEDICAL CLINIC A NEVADA NONPROFIT CORPORATION (dba CARSON VALLEY HEALTH)",
    "LEGAL_NAME_TRUNCATED", FALSE, "HAND-READ BRIDGE: the enrolled legal name less 'a Nevada nonprofit corporation', which is a statement of form, not a different body; rows 23 and 24 carry the long form as HOSPITAL_OR_SYSTEM already. "
)

#' Sweep hits HELD: the awarding state's own document states a different form.
#' Session 72 (owner): the state's form stands (§10.2 precedence rule); the
#' enrolment is recorded on the row, NOT used to re-type it. `ccn` is the
#' enrolment the sweep found; its record is read from the archived file and
#' written into cms_enrolment_record only (never into `ccn`, which Stage 5 will
#' read as a hospital match).
EH_HOLD <- tibble::tribble(
  ~file, ~awardee, ~ccn, ~reason,
  "ak_year1_awardees.csv", "Bristol Bay Area Health Corporation", "021309",
    "Alaska's own Organization Type on this project states 'Tribe and/or Tribal Health Organization'; two other BBAHC projects are typed HOSPITAL_OR_SYSTEM on Alaska's 'Hospital' token. Session 12 kept Alaska's per-project value and harmonised in neither direction (RECIPIENT_TYPE_VARIES_IN_SOURCE). CMS: CCN 021309, Kanakanak Hospital (CAH).",
  "ak_year1_awardees.csv", "Alaska Native Tribal Health Consortium", "020026",
    "Alaska's own Organization Type on this project states 'Tribal Health Organization'; three other ANTHC projects are HOSPITAL_OR_SYSTEM on Alaska's 'Hospital (all types)'. Session 12's per-project rule. CMS: CCN 020026, Alaska Native Medical Center.",
  "ak_year1_awardees.csv", "Arctic Slope Native Association", "021312",
    "Alaska's own Organization Type states 'Tribal Health Organization'. CMS: ARCTIC SLOPE NATIVE ASSOCIATION LTD, CCN 021312, Samuel Simmonds Memorial Hospital (CAH).",
  "ak_year1_awardees.csv", "Alaska Psychiatric Institute, Department of Family & Community Services", "024002",
    "Alaska's own Organization Type states 'State Agency', and the awardee names a state department. CMS enrols API as a DBA of the STATE OF ALASKA DEPARTMENT OF ADMINISTRATION (CCN 024002), a different department: a DBA match, not the legal entity the award names.",
  "or_year1_awardees.csv", "Lake Health District", "381309",
    "OHA pays this award from its Rural Health Clinic pool under its own Organization Type 'Rural Health Clinic' (session 17 recorded the 23 hospital-owned RHCs and did not re-code them). CMS: CCN 381309, Lake District Hospital (CAH).",
  "or_year1_awardees.csv", "Providence Hood River Memorial Hospital", "381318",
    "OHA's Rural Health Clinic table, Organization Type 'Rural Health Clinic'. CMS carries the string as a DBA of PROVIDENCE HEALTH & SERVICES OREGON (CCN 381318), not as a legal name.",
  "or_year1_awardees.csv", "Providence Seaside Hospital - Providence Cannon Beach Clinic", "381303",
    "OHA's Rural Health Clinic table; the awardee is a clinic SITE of Providence Seaside Hospital (a DBA of Providence Health & Services Oregon, CCN 381303).",
  "or_year1_awardees.csv", "Providence Seaside Hospital - Providence Seaside Clinic", "381303",
    "OHA's Rural Health Clinic table; the awardee is a clinic SITE of Providence Seaside Hospital (a DBA of Providence Health & Services Oregon, CCN 381303).",
  "or_year1_awardees.csv", "Providence Seaside Hospital - Providence Warrenton Clinic", "381303",
    "OHA's Rural Health Clinic table; the awardee is a clinic SITE of Providence Seaside Hospital (a DBA of Providence Health & Services Oregon, CCN 381303).",
  "or_year1_awardees.csv", "Saint Alphonsus Medical Center - Baker City", "381315",
    "OHA's Rural Health Clinic table, Organization Type 'Rural Health Clinic'. CMS enrols SAINT ALPHONSUS MEDICAL CENTER - BAKER CITY INC (CCN 381315, a CAH) -- a legal-name match, held for the same reason as Lake Health District."
)

#' Session 49 OTHER rows whose basis states no organisational form. Back to §8's
#' standing fallback: NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED.
EH_OTHER_WITHDRAWN <- tibble::tribble(
  ~file, ~awardee, ~why,
  "ga_great_health_awards.csv", "Behavioral Pediatric Resource Center",
    "session 49's basis reads 'Could not identify an organization by this exact name' -- no form",
  "mi_year1_awardees.csv", "Rudyard Area School Wellness Center",
    "session 49's basis names a school-based SITE and says 'the operating organization (health system, FQHC or health department) was not confirmed' -- no form for the recipient",
  "ok_year1_awardees.csv", "Empowerment Solutions",
    "session 49's basis reads 'Could not identify the organization' and infers a clinical provider from what the microgrant buys -- an activity, not a form (§0.3a)",
  "or_year1_awardees.csv", "Regional Partners",
    "session 49's basis reads 'OHA names no organization ... Nothing to classify until partners are named' -- no recipient, so no form",
  "or_year1_awardees.csv", "School-Based Health Center Planning Grants",
    "session 49's basis reads 'OHA names no organization ... Nothing to classify until grantees are named' -- no recipient, so no form"
)

# -- the machine sweep ------------------------------------------------------------

#' The entity halves of an awardee string: the whole string, the part before a
#' comma / parenthesis / spaced dash / colon, and the part after " at ".
eh_entity_forms <- function(a) {
  a <- dplyr::coalesce(a, "")
  head_part <- stringr::str_split_fixed(a, "\\s[-\u2013]\\s|\\(|,|:", 2)[, 1]
  tail_part <- stringr::str_match(a, " at (.+)$")[, 2]
  unique(stats::na.omit(c(a, head_part, tail_part)))
}

#' Every non-hospital row whose entity half EXACTLY names an enrolled hospital's
#' legal name or DBA. Rows already re-typed by this overlay are included (so
#' the verdict list cannot go stale unnoticed).
eh_sweep <- function(tables, enrol = eh_enrolments()) {
  keys <- dplyr::bind_rows(
    enrol %>% dplyr::transmute(key = eh_norm(org), grade = "LEGAL", ccn, org, dba, enrol_state),
    enrol %>% dplyr::filter(!is.na(dba), nzchar(dba)) %>%
      dplyr::transmute(key = eh_norm(dba), grade = "DBA", ccn, org, dba, enrol_state)
  ) %>% dplyr::filter(nzchar(key))
  purrr::imap_dfr(tables, function(d, f) {
    already <- if ("cms_enrolment_match" %in% names(d))
      !is.na(d$cms_enrolment_match) & nzchar(d$cms_enrolment_match) else FALSE
    cand <- which(d$recipient_type != "HOSPITAL_OR_SYSTEM" | already)
    purrr::map_dfr(cand, function(i) {
      forms <- eh_norm(eh_entity_forms(d$awardee[i]))
      forms <- forms[lengths(strsplit(forms, " ")) >= 2]
      hit <- keys %>% dplyr::filter(.data$key %in% forms)
      if (!nrow(hit)) return(NULL)
      hit <- hit %>% dplyr::arrange(.data$grade != "LEGAL") %>% dplyr::slice(1)
      tibble::tibble(file = f, row = i, awardee = d$awardee[i],
                     recipient_type = d$recipient_type[i],
                     grade = hit$grade, ccn = hit$ccn, cms_org = hit$org)
    })
  })
}

#' Every sweep hit must be hand-read, and every EXACT verdict must still hit
eh_assert_read <- function(sweep) {
  read <- dplyr::bind_rows(EH_APPLY %>% dplyr::select(file, awardee),
                           EH_HOLD %>% dplyr::select(file, awardee))
  unread <- sweep %>% dplyr::anti_join(read, by = c("file", "awardee"))
  if (nrow(unread)) {
    stop("[03bj] ", nrow(unread), " enrolment match(es) carry no hand-read ",
         "verdict: ", paste0(unread$file, ": ", unread$awardee, collapse = "; "),
         ". Read each and add it to EH_APPLY or EH_HOLD.", call. = FALSE)
  }
  # A held row records the enrolment the sweep found, so its CCN must be it.
  held <- EH_HOLD %>% dplyr::inner_join(sweep %>% dplyr::distinct(file, awardee, sweep_ccn = ccn),
                                        by = c("file", "awardee"))
  if (nrow(held) != nrow(EH_HOLD) || any(held$ccn != held$sweep_ccn)) {
    stop("[03bj] EH_HOLD CCN(s) disagree with the sweep, or a held row is no ",
         "longer swept: ", paste(setdiff(EH_HOLD$awardee,
                                         held$awardee[held$ccn == held$sweep_ccn]),
                                 collapse = "; "), call. = FALSE)
  }
  exact <- EH_APPLY %>% dplyr::filter(.data$match == "EXACT_LEGAL_NAME") %>%
    dplyr::select(file, awardee)
  stale <- exact %>% dplyr::anti_join(sweep, by = c("file", "awardee"))
  if (nrow(stale)) {
    stop("[03bj] EXACT verdict(s) no longer matched by the sweep: ",
         paste(stale$awardee, collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

# -- the overlay ------------------------------------------------------------------

eh_conf_col <- function(d) {
  if ("determination_confidence" %in% names(d)) "determination_confidence"
  else "recipient_type_confidence"
}

eh_blank <- function(x) is.na(x) | !nzchar(x) | x == "NA"

eh_flags <- function(fr, add = NULL, drop = NULL, empty = NA_character_) {
  f <- if (eh_blank(fr)) character(0) else strsplit(fr, ";", fixed = TRUE)[[1]]
  f <- union(setdiff(f, drop), add)
  if (length(f)) paste(f, collapse = ";") else empty
}

#' Session 71's overlay on one state table (built or committed)
#'
#' `empty` is the file's own spelling of an empty cell ("" or "NA") when
#' patching raw strings; NA_character_ for a built tibble.
s71_overlay <- function(d, file, empty = NA_character_) {
  ap <- EH_APPLY %>% dplyr::filter(.data$file == !!file)
  wd <- EH_OTHER_WITHDRAWN %>% dplyr::filter(.data$file == !!file)
  ho <- EH_HOLD %>% dplyr::filter(.data$file == !!file)
  if (!nrow(ap) && !nrow(wd) && !nrow(ho)) return(d)
  cf <- eh_conf_col(d)
  has <- function(x) x %in% names(d)
  for (cc in c("basis_type", EH_NEW_COLS)) {
    if (cc %in% EH_NEW_COLS && !nrow(ap) && !nrow(ho)) next
    if (!has(cc)) d[[cc]] <- if (is.na(empty)) NA_character_ else empty
  }
  if (has("ccn")) d$ccn <- as.character(d$ccn)
  # The mandatory basis (§7). Oklahoma's file carries no determination_basis
  # column; its per-row prose lives in `note`, so the basis goes there.
  bcol <- if (has("determination_basis")) "determination_basis" else "note"

  # 1. session 49 OTHER rows that state no form -> §8's standing fallback
  for (i in seq_len(nrow(wd))) {
    k <- which(d$awardee == wd$awardee[i])
    if (length(k) != 1L) stop("[03bj] ", file, ": expected one '", wd$awardee[i],
                              "' row, found ", length(k), call. = FALSE)
    if (!d$recipient_type[k] %in% c("OTHER", "NONPROFIT_CBO"))
      stop("[03bj] ", file, " '", wd$awardee[i], "' is ", d$recipient_type[k],
           "; expected session 49's OTHER", call. = FALSE)
    d$recipient_type[k] <- "NONPROFIT_CBO"
    d[[cf]][k] <- "LOW"
    d$basis_type[k] <- empty
    if (has("flag_reason"))
      d$flag_reason[k] <- eh_flags(d$flag_reason[k], add = "RECIPIENT_TYPE_INFERRED",
                                   empty = empty)
    if (!grepl(EH_WD_TAG, d[[bcol]][k], fixed = TRUE)) {
      prior <- d[[bcol]][k]
      d[[bcol]][k] <- paste0(
        EH_WD_TAG, ": NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED, §8's ",
        "standing fallback. OTHER requires a determined form (§8), and ", wd$why[i],
        ". Session 49's answer stays in verified_basis as the audit trail. ",
        "distributed_to_hospital was No and stays No; $0 moved.",
        if (!eh_blank(prior)) paste0(" PRIOR BASIS: ", prior) else "")
    }
  }

  # 2. legal entity enrolled as a hospital -> HOSPITAL_OR_SYSTEM + CCN
  for (i in seq_len(nrow(ap))) {
    # Only rows the rule re-types: an identical string already typed
    # HOSPITAL_OR_SYSTEM on its own source (Alaska's per-project 'Hospital'
    # token, session 49's verification) is left exactly as it is.
    tagged <- !eh_blank(d$cms_enrolment_match)
    k <- which(d$awardee == ap$awardee[i] &
                 (d$recipient_type != "HOSPITAL_OR_SYSTEM" | tagged))
    if (length(k) != ap$n[i]) stop("[03bj] ", file, ": expected ", ap$n[i], " '",
                                   ap$awardee[i], "' row(s), found ", length(k),
                                   call. = FALSE)
    exact <- ap$match[i] == "EXACT_LEGAL_NAME"
    fl <- rhtp_classify_flow("HOSPITAL_OR_SYSTEM", "")
    for (r in k) {
      # Read BEFORE re-typing; on an already-overlaid row the tag is present
      # and the basis below is not rewritten, so this is never misreported.
      prior_type <- d$recipient_type[r]
      d$recipient_type[r] <- "HOSPITAL_OR_SYSTEM"
      d$ccn[r] <- ap$ccn[i]
      d[[cf]][r] <- if (exact) "MEDIUM" else "LOW"
      d$basis_type[r] <- if (exact) "ORG_WEBSITE" else "GENERAL_KNOWLEDGE"
      d$recipient_subtype[r] <- if (ap$ahc[i]) "ACADEMIC_HEALTH_CENTER" else empty
      d$cms_enrolment_match[r] <- ap$match[i]
      rec <- EH_ENROL_RECORD[[ap$ccn[i]]]
      d$cms_enrolment_record[r] <- paste0("CMS Hospital Enrollments: ", ap$cms_org[i],
                                          ", CCN ", ap$ccn[i], "; ", rec)
      if (has("flow_type")) d$flow_type[r] <- fl$flow_type
      d$distributed_to_hospital[r] <- fl$distributed_to_hospital
      if (has("hospital_benefiting")) d$hospital_benefiting[r] <- "Yes"
      if (has("hospital_attribution")) d$hospital_attribution[r] <- "NAMED_HOSPITAL"
      if (has("is_hospital_or_system")) d$is_hospital_or_system[r] <- "Yes"
      if (has("flag_reason"))
        d$flag_reason[r] <- eh_flags(d$flag_reason[r],
                                     drop = c("RECIPIENT_TYPE_INFERRED",
                                              "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED"),
                                     empty = empty)
      # An extractor's own `note` that states the opposite coding is marked
      # superseded (Emory's reads "NON_HOSPITAL because Emory University is
      # the recipient"), never deleted (§2.1: a correction shows what moved).
      if (bcol != "note" && has("note") && !eh_blank(d$note[r]) &&
          grepl("NON_HOSPITAL|not a hospital|UNIVERSITY_OR_AHC", d$note[r]) &&
          !startsWith(d$note[r], "[SUPERSEDED session 71")) {
        d$note[r] <- paste0("[SUPERSEDED session 71: re-typed HOSPITAL_OR_SYSTEM ",
                            "on its CMS hospital enrolment, CCN ", ap$ccn[i],
                            "; see determination_basis.] ", d$note[r])
      }
      if (!grepl(EH_TAG, d[[bcol]][r], fixed = TRUE)) {
        prior <- d[[bcol]][r]
        d[[bcol]][r] <- paste0(
          EH_TAG, ": HOSPITAL_OR_SYSTEM", if (ap$ahc[i]) " (ACADEMIC_HEALTH_CENTER)" else "",
          ", was ", prior_type, ". ", ap$match[i], ": the awardee's legal entity is ",
          "enrolled with CMS as a hospital -- ", ap$cms_org[i], ", CCN ", ap$ccn[i],
          ". ", ap$why[i], "§10.2 'Academic health centers and enrolled hospital ",
          "operators': the enrolment is a primary federal source and the name does not ",
          "override it (§0.4); the activity does not decide it (§0.3a). ",
          "§10.2 DIRECT: recipient identity -- the named recipient is a ",
          "hospital operator, so its flow is DIRECT. Confidence ", if (exact) "MEDIUM (ORG_WEBSITE: a federal record states the form)" else "LOW (a hand-read bridge)",
          "; HIGH waits on Stage 5's CCN match.",
          if (!eh_blank(prior)) paste0(" PRIOR BASIS: ", prior) else "")
      }
    }
  }

  # 3. the awarding state states another form -> the state's form stands and
  #    the enrolment is RECORDED, not applied (§10.2 precedence rule, session
  #    72). recipient_type, flow, confidence, flags and `ccn` are untouched;
  #    cms_enrolment_match stays empty because it means "re-typed on it".
  for (i in seq_len(nrow(ho))) {
    # Only the rows whose state-stated form is NOT a hospital: the same string
    # on another project that the state itself types 'Hospital' (Alaska's
    # per-project rule, session 12) is already HOSPITAL_OR_SYSTEM and untouched.
    k <- which(d$awardee == ho$awardee[i] & d$recipient_type != "HOSPITAL_OR_SYSTEM")
    if (!length(k)) stop("[03bj] ", file, ": no non-hospital '", ho$awardee[i],
                         "' row to record the enrolment on", call. = FALSE)
    rec <- EH_ENROL_RECORD[[ho$ccn[i]]]
    for (r in k) {
      d$cms_enrolment_record[r] <- paste0(
        "CMS Hospital Enrollments: ", rec, ". RECORDED, NOT APPLIED: the awarding ",
        "state's own award document states another form, and under §10.2's ",
        "precedence rule that form stands (session 72).")
      if (!grepl(EH_HOLD_TAG, d[[bcol]][r], fixed = TRUE)) {
        prior <- d[[bcol]][r]
        d[[bcol]][r] <- paste0(
          if (!eh_blank(prior)) paste0(prior, " ") else "",
          EH_HOLD_TAG, ": ", d$recipient_type[r], " stands on the state's own ",
          "document. ", ho$reason[i], " §10.2 'Academic health centers and ",
          "enrolled hospital operators': where the awarding state's award document ",
          "states the recipient's form, that form stands and the CMS enrolment is ",
          "recorded in cms_enrolment_record without re-typing the row. ",
          "Owner decision, ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM option (a).")
      }
    }
  }
  d
}

#' Where each CCN's record is archived (filled at source time from the files).
#' Held CCNs also carry the enrolled name, read from the file, because their
#' rows record the enrolment without a hand-typed cms_org.
EH_ENROL_RECORD <- local({
  e <- tryCatch(eh_enrolments(), error = function(err) NULL)
  if (is.null(e)) list() else {
    rec <- function(cc, named) {
      r <- e[e$ccn == cc, ][1, ]
      if (!nrow(r) || is.na(r$org)) return("record not found in the archived extracts")
      where <- paste0(r$enrol_file, " (", r$ptype, ")")
      if (!named) return(where)
      paste0(r$org, if (!is.na(r$dba) && nzchar(r$dba)) paste0(" (dba ", r$dba, ")") else "",
             ", CCN ", cc, "; ", where)
    }
    a <- unique(EH_APPLY$ccn)
    h <- setdiff(unique(EH_HOLD$ccn), a)
    c(stats::setNames(lapply(a, rec, named = FALSE), a),
      stats::setNames(lapply(h, rec, named = TRUE), h))
  }
})

# -- committed files ---------------------------------------------------------------

EH_FILES <- function() unique(c(EH_APPLY$file, EH_OTHER_WITHDRAWN$file, EH_HOLD$file))

eh_read_raw <- function(f) {
  readr::read_csv(here::here("data/reference", f),
                  col_types = readr::cols(.default = "c"), na = character(),
                  progress = FALSE, show_col_types = FALSE, trim_ws = FALSE)
}

#' The file's own spelling of an empty cell
eh_empty_token <- function(d) {
  v <- unlist(d, use.names = FALSE)
  if (sum(v == "NA") > sum(v == "")) "NA" else ""
}

eh_read_committed <- function(files = EH_FILES()) {
  stats::setNames(lapply(files, function(f) {
    suppressMessages(readr::read_csv(here::here("data/reference", f),
                                     col_types = readr::cols(.default = "c"),
                                     progress = FALSE))
  }), files)
}

eh_apply <- function() {
  tabs <- eh_read_committed(unname(VQ_ALL_STATE_CSVS()))
  eh_assert_read(eh_sweep(tabs))
  for (f in EH_FILES()) {
    d <- eh_read_raw(f)
    out <- s71_overlay(d, f, empty = eh_empty_token(d))
    readr::write_csv(out, here::here("data/reference", f), na = "")
  }
  # the sweep must still be fully read after the overlay
  tabs <- eh_read_committed(unname(VQ_ALL_STATE_CSVS()))
  sw <- eh_sweep(tabs)
  eh_assert_read(sw)
  sw <- sw %>% dplyr::left_join(
    dplyr::bind_rows(
      EH_APPLY %>% dplyr::transmute(file, awardee, verdict = paste0("APPLIED: ", match)),
      EH_HOLD %>% dplyr::transmute(file, awardee, verdict = paste0("HELD: ", reason))),
    by = c("file", "awardee"))
  readr::write_csv(sw, here::here("data/reference/enrolled_hospital_operator_sweep.csv"),
                   na = "")
  rev <- other_form_review(tabs)
  other_assert_forms(rev)
  readr::write_csv(rev, here::here("data/reference/other_type_form_review.csv"), na = "")
  invisible(EH_FILES())
}

#' Every state award file the union test combines, as basenames
VQ_ALL_STATE_CSVS <- function() {
  tf <- readLines(here::here("tests/testthat/test_state_union.R"), warn = FALSE)
  i0 <- grep("^STATE_FILES <- c\\(", tf)
  i1 <- i0 - 1L + which(trimws(tf[i0:length(tf)]) == ")")[1]
  sf <- eval(parse(text = paste(tf[i0:i1], collapse = "\n")))
  stats::setNames(basename(sf), names(sf))
}

#' Rows and dollars this overlay moves, per state (read from committed files)
eh_effect <- function(tabs = eh_read_committed()) {
  purrr::imap_dfr(tabs, function(d, f) {
    if (!"cms_enrolment_match" %in% names(d)) return(NULL)
    k <- !is.na(d$cms_enrolment_match)
    tibble::tibble(file = f, state = d$state[k], awardee = d$awardee[k],
                   ccn = d$ccn[k], match = d$cms_enrolment_match[k],
                   subtype = d$recipient_subtype[k],
                   amount = suppressWarnings(as.numeric(d$amount[k])))
  })
}

# -- Task 2: every OTHER row must state its determined form --------------------
#
# Session 49's test required ten characters of basis, and a bare name passed
# (North Arkansas Rural Health Consortium, session 70). This replaces it with
# an explicit FORM per row:
#   * session 49's rows: EH_OTHER_FORMS below, hand-read from each verified
#     basis, session 71;
#   * session 50's rows: the `determined_form` column of
#     unstated_form_typing_decisions.csv;
#   * sessions 52-59's rows: the "Determined form:" / "DETERMINED FORM" /
#     "-- <FORM>:" clause their bases already carry.
# A row with no form from any of these fails the build, and so does a form
# that merely repeats the awardee's name.

EH_OTHER_FORMS <- tibble::tribble(
  ~awardee, ~determined_form,
  "TTC LLC DBA BHG Cullman Treatment Center", "for-profit opioid treatment programme",
  "Touchstone Residential Services DBA Touchstone Transport", "non-emergency medical transportation provider",
  "Compass Therapy", "private therapy clinic",
  "Optical Aleutians", "optical / eye-care provider",
  "Whale Tail Pharmacy", "retail pharmacy (Alaska's own type: Pharmacy)",
  "White's Incorporated", "pharmacy business (Alaska's own type: Pharmacy)",
  "Program of All-Inclusive Care for the Elderly (PACE) Central Michigan", "PACE organisation",
  "Program of All-Inclusive Care for the Elderly (PACE) Northeast Michigan", "PACE organisation",
  "Oregon Northwest Workforce Investment Board (DBA Northwest Oregon Works)", "regional workforce investment board",
  "Outback Strong LLC", "private behavioural health practice (OHA's type: Behavioral Health Clinic)",
  "Ravenseed AZN, LLC (DBA Acadia Northwest)", "private behavioural health practice (OHA's type: Behavioral Health Clinic)",
  "Seniors at Home LLC", "home care company",
  "Grace Team", "senior living management company (long-term care operator)",
  "Talbot Hospice Foundation Inc", "a hospice's foundation (parent is a hospice)",
  "The Well", "Certified Community Behavioral Health Center",
  "Northside Behavioral Health", "mental health clinic",
  "RxConnect CaringWire - Madison", "health technology company",
  "RxConnect Caring Wire -North Platte", "health technology company",
  "Pediatric Dental Specialists of Greater Nebraska", "pediatric dental practice",
  "TheraWest LLC", "physical therapy practice",
  "Sooner Mobile X-Ray, Inc.", "mobile diagnostic imaging company",
  "Good Neighbor Society", "nursing home / senior living",
  "Iowa Family Counseling", "mental health clinic",
  "Morning Glory Birth & Wellness", "birth centre / midwifery practice",
  "R & R Counseling Solutions", "private counselling practice",
  "Wells Bros Pharmacy Services LLC", "pharmacy services company",
  "Aspire Health & Wellness", "medically supervised weight-loss clinic",
  "Instaclinic LLC", "telehealth and remote patient monitoring company"
)

#' Bases that disclaim a form. A row carrying one of these as its only basis
#' has no determined form, whatever its recipient_type says.
EH_NO_FORM_PATTERN <- paste0("could not identify|not confirmed|names no organi[sz]ation|",
                             "nothing to classify")

#' One row per OTHER row in the committed state files, with its stated form
other_form_review <- function(tabs = eh_read_committed(unname(VQ_ALL_STATE_CSVS()))) {
  uf <- suppressMessages(readr::read_csv(
    here::here("data/reference/unstated_form_typing_decisions.csv"),
    col_types = readr::cols(.default = "c"), progress = FALSE)) %>%
    dplyr::distinct(state, awardee, determined_form) %>%
    dplyr::rename(uf_form = determined_form)
  purrr::imap_dfr(tabs, function(d, f) {
    k <- which(d$recipient_type == "OTHER")
    if (!length(k)) return(NULL)
    col <- function(x) if (x %in% names(d)) d[[x]][k] else rep(NA_character_, length(k))
    tibble::tibble(file = f, row = k, state = d$state[k], awardee = d$awardee[k],
                   amount = col("amount"), verified_by = col("verified_by"),
                   basis = dplyr::coalesce(col("determination_basis"), col("note")),
                   rts = col("recipient_type_source"), vb = col("verified_basis"))
  }) %>%
    dplyr::left_join(EH_OTHER_FORMS %>% dplyr::rename(s49_form = determined_form),
                     by = "awardee") %>%
    dplyr::left_join(uf, by = c("state", "awardee")) %>%
    dplyr::mutate(
      clause = dplyr::coalesce(
        stringr::str_match(.data$basis, "(?i)determined form:\\s*([^.;]+)")[, 2],
        stringr::str_match(.data$rts, "(?i)determined form:\\s*([^.;]+)")[, 2],
        stringr::str_match(.data$rts, "^TYPED \\(session \\d+\\):\\s*([^.;]+)")[, 2],
        stringr::str_match(.data$basis, "OTHER \\[[A-Z_]+\\] -- ([^:]+):")[, 2],
        stringr::str_match(.data$vb, "DETERMINED FORM \\(session \\d+\\):\\s*([^,.;]+)")[, 2]),
      determined_form = dplyr::coalesce(.data$s49_form, .data$uf_form, .data$clause),
      form_source = dplyr::case_when(
        !is.na(.data$s49_form) ~ "session 49 verified basis, form read session 71",
        !is.na(.data$uf_form) ~ "unstated_form_typing_decisions.csv (session 50)",
        !is.na(.data$clause) ~ "the row's own determined-form clause",
        TRUE ~ NA_character_),
      disclaims_form = grepl(EH_NO_FORM_PATTERN, dplyr::coalesce(.data$vb, ""),
                             ignore.case = TRUE) & is.na(.data$s49_form)) %>%
    dplyr::select(file, row, state, awardee, amount, determined_form, form_source,
                  disclaims_form)
}

#' The check session 49 should have had
other_assert_forms <- function(rev = other_form_review()) {
  bad <- rev %>% dplyr::filter(
    is.na(.data$determined_form) | nchar(.data$determined_form) < 5 |
      tolower(stringr::str_squish(.data$determined_form)) ==
      tolower(stringr::str_squish(.data$awardee)) | .data$disclaims_form)
  if (nrow(bad)) {
    stop("[03bj] ", nrow(bad), " OTHER row(s) state no determined form: ",
         paste0(bad$file, " ", bad$row, " '", bad$awardee, "'", collapse = "; "),
         ". OTHER requires one (§8); use §8's standing fallback instead.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- CLI -----------------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--report" %in% args) {
    s <- eh_sweep(eh_read_committed(unname(VQ_ALL_STATE_CSVS())))
    print(s, n = Inf, width = 200)
    eh_assert_read(s)
    cat("\nAll", nrow(s), "sweep hits carry a hand-read verdict.\n")
  }
  if ("--apply" %in% args) {
    f <- eh_apply()
    cat("Patched:", paste(f, collapse = ", "), "\n")
  }
  if ("--totals" %in% args) {
    e <- eh_effect()
    print(e %>% dplyr::group_by(state, subtype) %>%
            dplyr::summarise(rows = dplyr::n(), dollars = sum(amount, na.rm = TRUE),
                             .groups = "drop"), n = Inf)
  }
}

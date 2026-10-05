#!/usr/bin/env Rscript
# 03bx_va_vhcf_awardees.R ----------------------------------------------------
#
# VIRGINIA -- VHCF'S PROVIDER INTEROPERABILITY ROUND: 25 PRICED AWARDS,
# $14,390,000, TYPED ON CMS'S VIRGINIA ENROLMENT FILES. Session 92.
#
# The Virginia Health Care Foundation's 2026-10-02 release ("Virginia Takes
# Another Step in Transforming Rural Health Care Through Major Technology
# Investments") says "VHCF announced 25 awards totaling $14.39 million through
# Virginia's Rural Health Transformation Program" and "These are VHCF's first
# awards under the program". It prints 25 lines of the shape
# "<recipient> (<region>): $<amount> to <purpose>" under four category
# headings. The 25 amounts sum to exactly $14,390,000 (asserted below).
#
# WHY VHCF'S DOCUMENT IS ADMISSIBLE (§7). DMAS is Virginia's primary recipient;
# "VHCF is a subrecipient of DMAS" administering the Provider Interoperability
# and Provider Productivity initiatives (R/03bb; va_year1_awardees.csv lists
# VHCF among the eleven first-tier partners). VHCF is a designated
# pass-through administrator, Illinois/ICAHN's route, and its release names
# both the recipient and the award. validation_source_type is
# AGENCY_PRESS_RELEASE, the source_doc_type nearest a designated
# administrator's own announcement.
#
# TIERS (§0.2). THE CMS FOOTER IS NOT THE ROUND TOTAL. The release's footer
# reads "a financial assistance award totaling $189,544,888.14 with 100
# percent funded by CMS/HHS" -- Virginia's whole ALLOTMENT (§7.1 anchor
# $189,544,888), and the publication is its grammatical subject. It is Tier 1
# and is asserted as STATE_ALLOTMENT through the shared rule in both
# directions. The round total is the release's own "$14.39 million", which the
# 25 lines reproduce to the dollar. The rows themselves are Tier 3: VHCF's
# awards to named sub-subrecipients.
#
# GRAIN. One row per printed LINE. Buchanan General Hospital and Valley Health
# System each carry two lines in different categories, priced separately;
# they are not merged (§6.1 mode 4). The parenthetical is the recipient's
# REGION, kept in `site`, never part of the name.
#
# TYPING IS ON CMS'S OWN VIRGINIA ENROLMENT FILES, NOT THE NAME. Three files:
# VA Hospital Enrollments (data/evidence/federal_records/2026-09-25/, 169
# records, 18 of them CRITICAL ACCESS HOSPITAL) and VA FQHC and RHC
# Enrollments (fetched this session to 2026-10-05/). A line whose recipient
# string -- or either half of a string split on its en dash -- equals an
# ORGANIZATION NAME or DBA there, after case, punctuation and a trailing
# INC/LLC/INCORPORATED are set aside, is typed from that record at MEDIUM. A
# HOSPITAL record outranks the same entity's provider-based RHC records.
#
# HIGHLAND MEDICAL CENTER IS NOT A HOSPITAL, AND THE OWNER ASKED FOR THE CHECK.
# Neither the VA Hospital file nor its 18 CAH records carries "HIGHLAND" in any
# ORGANIZATION NAME or DBA. The VA FQHC file carries HIGHLAND MEDICAL CENTER
# INC at CCN 491858 (Monterey) and again at 491903 (dba HIGHLAND MEDICAL CENTER
# SCHOOL BASED HEALTH CARE). "Medical Center" is a name, not an enrolment: the
# row is FQHC_OR_RHC, NON_HOSPITAL, and its $288,000 is not hospital money.
# hva_assert_highland() fails if any of those three facts moves.
#
# THE SYSTEM PARENTS. Valley Health System (2 lines), Ballad Health and Sentara
# Health are not ORGANIZATION NAMEs or DBAs on any VA enrolment file. Their
# hospitals enrol under other legal bodies, recorded per row: WINCHESTER
# MEDICAL CENTER, WARREN MEMORIAL HOSPITAL, SHENANDOAH MEMORIAL HOSPITAL and
# PAGE MEMORIAL HOSPITAL (whose RHCs trade as "VALLEY HEALTH ..."); MOUNTAIN
# STATES HEALTH ALLIANCE and WELLMONT HEALTH SYSTEM dba LONESOME PINE HOSPITAL
# (Ballad's); SENTARA HOSPITALS and six other Sentara legal bodies. They are
# typed on SD_SYSTEM_PARENTS_FORM_NOT_STATED's settled footing (owner, session
# 87: Sanford Health and Avera Health): HOSPITAL_OR_SYSTEM, LOW, basis_type
# GENERAL_KNOWLEDGE, NO CCN. They are SUBTRACTABLE, and hva_report() prints the
# hospital figure with and without them.
#
# THE TWO UVA HEALTH SUB-UNIT STRINGS. "UVA Health Comprehensive Epilepsy
# Program" ($84,000) and "UVA Health–Fortify Children's Health" ($800,000)
# name a programme of the enrolled legal entity, RECTOR & VISITORS OF THE
# UNIVERSITY OF VIRGINIA dba UVA HEALTH SCIENCES CENTER (CCN 490009), without
# naming the entity. That is AHC_STRING_NAMES_NO_ENROLLED_ENTITY's shape
# exactly (UAB Montgomery, OHSU Casey Eye, Michigan MEDIC): UNIVERSITY_OR_AHC,
# NON_HOSPITAL, and queued there, $884,000 ONE-DIRECTIONAL.
#
# §6.2: announced 2026-10-02, after Virginia's 2025-12-29 NOA; RHTP provenance
# is stated in the release's own words. THE TRAP is VHCF's 2026-07-10 "$2.7
# million in grants to 19 organizations": its regular grant programme, no RHT
# or CMS language, and it names Tri-Area Community Health and The Health
# Wagon, both also on THIS roster. It is registered as VA-VHCF-REGULAR-GRANTS
# in non_rhtp_state_programs.csv and is never extracted.
#
# THE WATCH. R/03bb's Routine reads VHCF's news index (added session 92): a
# post VHCF publishes that the archive does not carry trips it, because the
# roster above arrived through that channel while R/03bb watched /rural-health/.
#
# Usage:
#   Rscript R/03bx_va_vhcf_awardees.R --fetch     # archive the three VHCF pages
#   Rscript R/03bx_va_vhcf_awardees.R --validate  # assertions, offline
#   Rscript R/03bx_va_vhcf_awardees.R --build     # write the award file
#   Rscript R/03bx_va_vhcf_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

HVA_STATE      <- "VA"
HVA_ALLOTMENT  <- 189544888              # cms_fy2026_allotments.csv (§7.1)
HVA_FOOTER     <- 189544888.14
HVA_NOA_DATE   <- as.Date("2025-12-29")
HVA_ANNOUNCED  <- as.Date("2026-10-02")
HVA_LINES      <- 25L
HVA_TOTAL      <- 14390000
HVA_DIR        <- file.path("data", "evidence", "VA", "vhcf")
HVA_CSV        <- here::here("data", "reference", "va_year1_vhcf_awardees.csv")
HVA_AGENT      <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                         "+https://www.aha.org)")
HVA_URL <- paste0("https://www.vhcf.org/2026/10/02/virginia-takes-another-step-",
                  "in-transforming-rural-health-care-through-major-technology-",
                  "investments/")
HVA_TRAP_URL <- paste0("https://www.vhcf.org/2026/07/10/virginia-health-care-",
                       "foundation-awards-more-than-2-7-million-in-grants-to-",
                       "expand-access-to-health-care-across-virginia/")
HVA_SOURCES <- tibble::tribble(
  ~key, ~url, ~file,
  "release", HVA_URL,
  file.path(HVA_DIR, "2026-10-05_vhcf_release_2026-10-02_rht_interoperability_awards.html"),
  "trap", HVA_TRAP_URL,
  file.path(HVA_DIR, "2026-10-05_vhcf_release_2026-07-10_regular_grants_NOT_RHT.html"),
  "news", "https://www.vhcf.org/news/",
  file.path(HVA_DIR, "2026-10-05_vhcf_news_index.html"))
HVA_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-09-25", "cms_hosp_enrollments_VA.json"),
  FQHC     = file.path("data", "evidence", "federal_records", "2026-10-05", "cms_fqhc_enrollments_VA.json"),
  RHC      = file.path("data", "evidence", "federal_records", "2026-10-05", "cms_rhc_enrollments_VA.json"))
HVA_TITLE <- paste0("VHCF, 'Virginia Takes Another Step in Transforming Rural ",
                    "Health Care Through Major Technology Investments' (2026-10-02)")
HVA_POOL  <- "VHCF Provider Interoperability, first award round (Virginia RHTP)"

HVA_CATEGORIES <- c("Improving Network Capacity",
                    "Modernizing Electronic Health Records",
                    "Strengthening Cybersecurity",
                    "Electronic Health Data Exchange")

# -- the roster ----------------------------------------------------------------

hva_text <- function(src = here::here(HVA_SOURCES$file[1])) {
  h <- xml2::read_html(src)
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript|//nav|//header|//footer"))
  t <- rvest::html_text2(h)
  t <- stringr::str_replace_all(t, " ", " ")
  t <- stringr::str_replace_all(t, "[‘’]", "'")
  l <- stringr::str_squish(strsplit(t, "\n", fixed = TRUE)[[1]])
  l[nzchar(l)]
}

#' The 25 lines, each under the category heading that precedes it
hva_parse <- function(l = hva_text()) {
  start <- which(l == HVA_CATEGORIES[1])
  stop_at <- grep("^VHCF anticipates announcing", l)
  if (length(start) != 1L || length(stop_at) != 1L) {
    stop("[VA VHCF] the roster block is not where it was: re-read the release (§0.4).",
         call. = FALSE)
  }
  blk <- l[start:(stop_at - 1L)]
  cat_i <- cumsum(sub(":$", "", blk) %in% HVA_CATEGORIES)
  is_cat <- sub(":$", "", blk) %in% HVA_CATEGORIES
  rows <- blk[!is_cat]
  m <- stringr::str_match(rows, "^(.+?) \\(([^)]+)\\): \\$([0-9,]+) to (.+)$")
  if (anyNA(m[, 1])) {
    stop("[VA VHCF] lines not of the shape '<name> (<region>): $<amount> to <purpose>': ",
         paste(rows[is.na(m[, 1])], collapse = " | "), call. = FALSE)
  }
  tibble::tibble(
    category = HVA_CATEGORIES[cat_i[!is_cat]],
    awardee = m[, 2], site = m[, 3],
    amount = as.numeric(gsub(",", "", m[, 4])), purpose = m[, 5])
}

hva_assert_roster <- function(d = hva_parse(), l = hva_text()) {
  if (nrow(d) != HVA_LINES) stop("[VA VHCF] ", nrow(d), " lines, not 25.", call. = FALSE)
  if (sum(d$amount) != HVA_TOTAL) {
    stop("[VA VHCF] the lines sum to $", format(sum(d$amount), big.mark = ","),
         ", not $14,390,000.", call. = FALSE)
  }
  t <- paste(l, collapse = " ")
  for (p in c(
    "Today, the Virginia Health Care Foundation (VHCF) announced 25 awards totaling $14.39 million through Virginia's Rural Health Transformation Program.",
    "These are VHCF's first awards under the program.",
    "VHCF administering two initiatives focused on Provider Interoperability and Provider Productivity",
    "VHCF anticipates announcing the first round of Provider Productivity awards in October 2026")) {
    if (!grepl(p, t, fixed = TRUE)) {
      stop("[VA VHCF] the release no longer carries: ", p, call. = FALSE)
    }
  }
  # §0.2: the footer is the ALLOTMENT and is refused as a pool.
  ft <- "as part of a financial assistance award totaling $189,544,888.14 with 100 percent funded by CMS/HHS"
  if (!grepl(ft, t, fixed = TRUE)) stop("[VA VHCF] the CMS footer moved.", call. = FALSE)
  rhtp_assert_footer_not_allotment(HVA_FOOTER, HVA_STATE, "STATE_ALLOTMENT",
                                   label = "VA VHCF release footer")
  refused <- tryCatch({
    rhtp_assert_footer_not_allotment(HVA_FOOTER, HVA_STATE, "SOLICITATION",
                                     label = "VA VHCF footer read as the round total")
    FALSE
  }, error = function(e) TRUE)
  if (!refused) {
    stop("[VA VHCF] the §0.2 rule no longer refuses the allotment footer as a ",
         "round total.", call. = FALSE)
  }
  if (!(HVA_ANNOUNCED > HVA_NOA_DATE)) stop("[VA VHCF] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}

#' The 07-10 release is VHCF's regular programme: no RHT, no CMS, 19 orgs
hva_assert_trap <- function() {
  t <- paste(hva_text(here::here(HVA_SOURCES$file[2])), collapse = " ")
  if (!grepl("has awarded more than $2.7 million in grants to 19 organizations", t, fixed = TRUE)) {
    stop("[VA VHCF] the 07-10 trap release no longer reads as archived.", call. = FALSE)
  }
  for (p in c("Rural Health Transformation", "RHT", "Centers for Medicare", "CMS")) {
    if (grepl(p, t, fixed = TRUE)) {
      stop("[VA VHCF] the 07-10 release now mentions '", p, "'. Re-read it before ",
           "keeping VA-VHCF-REGULAR-GRANTS as non-RHT.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

# -- typing --------------------------------------------------------------------

hva_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("[.,'’/&()–-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC)$", "", x)
}

hva_halves <- function(a) unique(hva_norm(c(a, strsplit(a, "–", fixed = TRUE)[[1]])))

hva_federal <- function() {
  dplyr::bind_rows(lapply(names(HVA_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(HVA_FED[[k]]))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = if ("PROVIDER TYPE TEXT" %in% names(j)) j$`PROVIDER TYPE TEXT` else NA_character_)
  }))
}

hva_match <- function(a, f) {
  h <- hva_halves(a)
  f[hva_norm(f$org) %in% h | hva_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
}

#' The owner's check on Highland Medical Center, against the hospital (incl.
#' CAH) file and the FQHC file. Fails if any of the facts the typing rests on moves.
hva_assert_highland <- function(f = hva_federal()) {
  hosp <- f[f$kind == "HOSPITAL", ]
  if (sum(hosp$ptype == "PART A PROVIDER - CRITICAL ACCESS HOSPITAL") != 18L) {
    stop("[VA VHCF] the VA Hospital file no longer carries 18 CAH records.", call. = FALSE)
  }
  if (any(grepl("HIGHLAND", paste(hosp$org, hosp$dba)))) {
    stop("[VA VHCF] 'HIGHLAND' now appears on the VA Hospital/CAH file. Re-type ",
         "Highland Medical Center from that record.", call. = FALSE)
  }
  fq <- f[f$kind == "FQHC" & hva_norm(f$org) == "HIGHLAND MEDICAL CENTER", ]
  if (!setequal(fq$ccn, c("491858", "491903")) || any(fq$city != "MONTEREY")) {
    stop("[VA VHCF] Highland Medical Center's FQHC enrolment moved: ",
         paste(fq$ccn, fq$city, collapse = "; "), call. = FALSE)
  }
  invisible(fq)
}

HVA_PARENT_NOTE <- paste0(
  " SYSTEM PARENT, typed on SD_SYSTEM_PARENTS_FORM_NOT_STATED's settled footing ",
  "(owner, session 87): HOSPITAL_OR_SYSTEM, LOW, GENERAL_KNOWLEDGE, no CCN, ",
  "subtractable. The string is no ORGANIZATION NAME or DBA on any CMS VA ",
  "enrolment file; its hospitals enrol under other legal bodies: ")

# Hand-read decisions. Everything else is an exact federal record, or §8's fallback.
HVA_OVERRIDES <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~why,
  "Valley Health System", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "WINCHESTER MEDICAL CENTER (490005), WARREN MEMORIAL HOSPITAL, INC. (490033), SHENANDOAH MEMORIAL HOSPITAL, INC. (CAH 491305) and PAGE MEMORIAL HOSPITAL INC (CAH 491307), whose RHC records trade as 'VALLEY HEALTH ...'. Both lines fund its Epic EHR."),
  "Ballad Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "MOUNTAIN STATES HEALTH ALLIANCE (490002 dba RUSSELL COUNTY HOSPITAL; CAH 491309 dba LEE COUNTY COMMUNITY HOSPITAL) and WELLMONT HEALTH SYSTEM (490114 dba LONESOME PINE HOSPITAL). The release itself says the award connects 'Norton Community, Lee County, and Lonesome Pine hospitals with its regional command center'."),
  "Sentara Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW",
  paste0(HVA_PARENT_NOTE, "SENTARA HOSPITALS (490007, 490044, 490046, 490057, 490066, 490093), SENTARA RMH MEDICAL CENTER (490004), SENTARA PRINCESS ANNE HOSPITAL (490119) and others. The award extends its platforms 'to approximately 38 rural practices': the recipient is the system, whatever the activity (§0.3a)."),
  "UVA Health Comprehensive Epilepsy Program", "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "LOW",
  "AHC_STRING_NAMES_NO_ENROLLED_ENTITY (queued): a programme of the University of Virginia's health system. The enrolled legal entity is RECTOR & VISITORS OF THE UNIVERSITY OF VIRGINIA dba UVA HEALTH SCIENCES CENTER (CCN 490009); the awardee string does not name it, so no bridge is made (§2, §0.4). One-directional if bridged.",
  "UVA Health–Fortify Children's Health", "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "LOW",
  "AHC_STRING_NAMES_NO_ENROLLED_ENTITY (queued): a UVA Health children's-health programme string. The enrolled legal entity is RECTOR & VISITORS OF THE UNIVERSITY OF VIRGINIA dba UVA HEALTH SCIENCES CENTER (CCN 490009); the awardee string does not name it, so no bridge is made (§2, §0.4). One-directional if bridged.",
  "Monroe County Health Center", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW",
  "HAND-READ BRIDGE: CMS VA FQHC Enrollment carries MONROE COUNTY HEALTH CENTER BOARD OF TRUSTEES dba CRAIG COUNTY HEALTH CENTER (491881, New Castle) and dba CRAIG COUNTY WELLNESS CENTER (491952). The release names 'its Craig Health Center in New Castle'. The string drops 'Board of Trustees', so LOW.",
  "Western Tidewater Community Services Board", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A Virginia community services board, the local public behavioral-health authority; the form is in the string and the release lists 'community services boards' among the recipient kinds.",
  "Pulaski County Office of Prevention and Recovery", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "STATE_SOURCE", "MEDIUM",
  "A county government office; the form is in the string and the release lists 'local agencies' among the recipient kinds.",
  "Northern Neck-Middlesex Free Health Clinic", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "A free clinic (stated in the string), not on the VA FQHC or RHC file; Cherry Hill Free Clinic (NJ) and Edisto Indian Free Clinic (SC) are typed NONPROFIT_CBO.",
  "Virginia Pharmacy Association", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "A trade association of pharmacies (stated in the string); its award helps 'rural pharmacies adopt electronic health record systems'. Not a hospital association, so §10.2's association row is not reached.",
  "Virginia Association of Free and Charitable Clinics", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "An association of free clinics (stated in the string), Florida's FAFCC precedent. Its award supports '13 rural free clinics'; no hospital.",
  "Virginia Community Healthcare Association", "NONPROFIT_CBO", "STATE_SOURCE", "MEDIUM",
  "The association of community health centers; the award expands a shared system 'to rural community health centers'. No hospital."
)

hva_awardees <- function(d = hva_parse(), f = hva_federal()) {
  hva_assert_highland(f)
  cls <- rhtp_classify_recipient_type(d$awardee, HVA_STATE)
  out <- vector("list", nrow(d))
  for (i in seq_len(nrow(d))) {
    a <- d$awardee[i]
    ccn_i <- NA_character_
    ov <- HVA_OVERRIDES[HVA_OVERRIDES$awardee == a, ]
    hit <- hva_match(a, f)
    if (nrow(ov)) {
      rt <- ov$recipient_type; bt <- ov$basis_type; cf <- ov$confidence
      why <- ov$why; how <- "HAND-READ"
    } else if (nrow(hit)) {
      k <- if ("HOSPITAL" %in% hit$kind) "HOSPITAL" else if ("FQHC" %in% hit$kind) "FQHC" else "RHC"
      hk <- hit[hit$kind == k, ]
      rt <- if (k == "HOSPITAL") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC"
      bt <- "ORG_WEBSITE"; cf <- "MEDIUM"; how <- "FEDERAL RECORD"
      six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
      one <- k == "HOSPITAL" && length(six) == 1L
      if (one) ccn_i <- six
      why <- paste0("EXACT federal record: CMS VA ",
                    c(HOSPITAL = "Hospital", FQHC = "FQHC", RHC = "RHC")[[k]],
                    " Enrollment carries this string as an ORGANIZATION NAME or DBA (",
                    paste(unique(hk$org), collapse = "; "), ") at CCN",
                    if (length(six) > 1L) "s " else " ", paste(six, collapse = "/"),
                    if (k == "HOSPITAL") paste0(", ", unique(hk$ptype[hk$ccn %in% six])[1]) else "",
                    if (k == "HOSPITAL" && any(hit$kind != "HOSPITAL"))
                      "; its RHC records are the same legal entity's" else "", ".")
    } else if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[VA VHCF] the classifier calls '", a, "' a hospital and no federal ",
           "record or hand-read decision covers it. Read it.", call. = FALSE)
    } else {
      rt <- "NONPROFIT_CBO"; bt <- NA_character_; cf <- "LOW"; how <- "FALLBACK"
      why <- "The release states no form and no CMS VA Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
    }
    out[[i]] <- tibble::tibble(recipient_type = rt, basis_type = bt,
                               determination_confidence = cf, typing = how,
                               why = why, ccn = ccn_i,
                               classifier = paste0(cls$recipient_type[i], "/",
                                                   rhtp_confidence_ceiling(cls$determination_confidence[i])))
  }
  t <- dplyr::bind_rows(out)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  tibble::tibble(
    state = HVA_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0("VHCF Provider Interoperability award, announced 2026-10-02 (",
                  d$category, "): ", d$purpose, " REGION (not the recipient): ", d$site, "."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = HVA_TITLE,
    state_source_url = HVA_URL,
    validation_source_type = "AGENCY_PRESS_RELEASE",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03bx_va_vhcf_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    award_pool = HVA_POOL,
    category = d$category,
    site = d$site,
    recipient_type_source = paste0("TYPED (session 92, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence),
    flag_reason = ifelse(t$typing == "FALLBACK", "RECIPIENT_TYPE_INFERRED", NA_character_),
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", "")),
    amount_basis = paste0("The line's own amount in VHCF's release, exact. The 25 lines sum ",
                          "to $14,390,000, the release's '$14.39 million'. The release's CMS ",
                          "footer ($189,544,888.14) is Virginia's ALLOTMENT, Tier 1, and is ",
                          "not this round's total (§0.2)."),
    basis_type = t$basis_type,
    round_amount = HVA_TOTAL,
    announcement_date = HVA_ANNOUNCED,
    source_archive_path = HVA_SOURCES$file[1])
}

hva_assert_typing <- function(a = hva_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[VA VHCF] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[VA VHCF] HIGH without Stage 5 (§7).", call. = FALSE)
  hl <- a[a$awardee == "Highland Medical Center", ]
  if (nrow(hl) != 1L || hl$recipient_type != "FQHC_OR_RHC" || hl$distributed_to_hospital != "No") {
    stop("[VA VHCF] Highland Medical Center must be the FQHC its enrolment says.", call. = FALSE)
  }
  uva <- a[grepl("^UVA Health", a$awardee), ]
  if (nrow(uva) != 2L || sum(uva$amount) != 884000 || any(uva$distributed_to_hospital != "No")) {
    stop("[VA VHCF] the two UVA Health strings ($884,000) must stay NON_HOSPITAL ",
         "until AHC_STRING_NAMES_NO_ENROLLED_ENTITY is resolved.", call. = FALSE)
  }
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[VA VHCF] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (!all(a$validation_source_type %in% rhtp_vocabulary("source_doc_type"))) {
    stop("[VA VHCF] validation_source_type outside §8.", call. = FALSE)
  }
  invisible(TRUE)
}

hva_fetch <- function() {
  for (i in seq_len(nrow(HVA_SOURCES))) {
    rhtp_watch_archive(HVA_SOURCES$url[i], HVA_SOURCES$file[i], HVA_AGENT)
  }
  message("[VA VHCF] archived ", nrow(HVA_SOURCES), " pages under ", HVA_DIR)
}

hva_validate <- function() {
  l <- hva_text()
  d <- hva_parse(l)
  hva_assert_roster(d, l)
  hva_assert_trap()
  a <- hva_awardees(d)
  hva_assert_typing(a)
  message("[VA VHCF] all assertions pass.")
  invisible(a)
}

hva_build <- function() {
  a <- hva_validate()
  readr::write_csv(a, HVA_CSV, na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[VA VHCF] wrote %d award lines, $%s; %d named-hospital lines, $%s.",
                  nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
                  format(sum(h$amount), big.mark = ",")))
}

hva_report <- function() {
  a <- hva_awardees()
  print(a %>% dplyr::select(awardee, amount, recipient_type, determination_confidence,
                            basis_type, ccn), n = 30)
  h <- a[a$distributed_to_hospital == "Yes", ]
  gk <- h$basis_type %in% "GENERAL_KNOWLEDGE"
  cat(sprintf(paste0("\n%d lines, $%s. NAMED_HOSPITAL %d lines, $%s (%.1f%%).\n",
                     "  enrolment-typed (exact record, MEDIUM): %d lines, $%s\n",
                     "  system parents (GENERAL_KNOWLEDGE, LOW, subtractable): %d lines, $%s\n"),
              nrow(a), format(sum(a$amount), big.mark = ","), nrow(h),
              format(sum(h$amount), big.mark = ","), 100 * sum(h$amount) / sum(a$amount),
              sum(!gk), format(sum(h$amount[!gk]), big.mark = ","),
              sum(gk), format(sum(h$amount[gk]), big.mark = ",")))
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) hva_fetch()
  if ("--validate" %in% args) hva_validate()
  if ("--build" %in% args) hva_build()
  if ("--report" %in% args) hva_report()
  if (!length(args)) message("Usage: --fetch | --validate | --build | --report")
}

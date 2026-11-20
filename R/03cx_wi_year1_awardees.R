#!/usr/bin/env Rscript
# 03cx_wi_year1_awardees.R ----------------------------------------------------
#
# WISCONSIN'S FIRST AWARD TABLES -> data/reference/wi_year1_awardees.csv.
# Session 121, OWNER RULING (Task 2): extract as INTENTS, the Missouri Smart
# Growth precedent (R/03cq, session 114).
#
# THE SOURCE. DHS's RHTP pages, each "Last revised November 18, 2026", read on
# 2026-11-19 (session 120) and archived under data/evidence/recheck/2026-11-19/WI/
# (held) and, byte-identical, data/evidence/WI/2026-11-19_dhs_rhtp_<page>.html
# (session 121, the copies this script and R/03y's probe read). Six tables on
# four pages, one row per table row, 138 rows / $149,331,289.71 (session 120 wrote $149,330,290.71, a $999 slip):
#   implementation   "Total Budget Year 1 funds awarded to implementation
#                     partners": 16 rows; prose "DHS awarded $79,373,358.70"
#                     (the rows sum to $79,373,358.71 -- a ONE-CENT gap in
#                     DHS's own prose, recorded, never adjusted)
#   workforce t1     Community Health Worker grants, "$19,942,572 to 49
#                     organizations"
#   workforce t2     CHW training provider grants, "$274,714 ... to two
#                     organizations"
#   technology t1    Rural Technology Transformation funds, "$39,740,002 in
#                     funding to 33 healthcare organizations"
#   technology t2    Rural Dental Efficiency and Access, "$9,500,722 in grants
#                     to 37 organizations"
#   coordinated t1   Sources of Strength, "$499,921 ... to (CESA) 6"
# The five competitive tables sum to $69,957,931, DHS's "$69.9 million in
# grants for Budget Year 1". Every printed figure is asserted below.
#
# WHY INTENTS. DHS, on the implementation page and on every initiative page:
# "Please note that all dollar amounts are the obligated awards and are subject
# to Centers for Medicare & Medicaid Services (CMS) review." Missouri's
# contingent roster ("have to be approved by ... CMS before a final award can be
# made") was extracted as NOTICE_OF_INTENT_TO_AWARD + AMOUNT_PRELIMINARY, and
# the owner ruled Wisconsin the same. Nothing here is an executed award until
# DHS says so; "This program is reimbursement based" (same paragraph).
#
# WHAT IS NOT IN THE FILE. DHS-led lines with no recipient table: the Epic
# digital collaborative ($29,000,000, "Lead agencies: DHS, Epic"), the mental
# health website ($9,398,000), DCTS's PPS ($3,708,794.62), the behavioural
# health study ($150,000) and others; the 11 Tribal Nations' $500,000 set
# allocations (no table); the Coordinating Care planning grants ("DHS will
# announce awards"). The implementation partners' own sub-rounds (DWD's rural
# workforce grants, DPI's 21 school districts, UWSA's campuses, WTCS's 16
# colleges) are SECOND-TIER and named nowhere here; each partner's row is its
# first-tier award, never divided (§6.2).
#
# TYPING (§8, §10.2). DHS states no form. Typed, in this order, on CMS's WI
# Hospital / FQHC / RHC Enrollments (archived 2026-11-20 under
# data/evidence/federal_records/2026-11-20/):
#   * WI_OVERRIDES (hand-read, each with its reason): system parents (LOW,
#     GENERAL_KNOWLEDGE, no CCN -- the SD/VT precedent), the Door County
#     Memorial Hospital Foundation (§7 foundation of a NAMED hospital, LOW),
#     The Richland Hospital (a DBA bridge, LOW), Fond du Lac County (the county
#     legal entity is enrolled as a hospital -- §7's enrolled-operator row and
#     session 120's Murray County ruling, LOW), the four Tribal Nations, the
#     state agencies and the UW / WTCS / technical-college bodies.
#   * an exact legal name (printed name before " DBA ", "(", ":" or " aka ",
#     normalised as R/09b normalises) on the HOSPITAL file: HOSPITAL_OR_SYSTEM,
#     MEDIUM, CCN on the row; on the FQHC file: FQHC_OR_RHC, MEDIUM.
#   * a name form evident in the printed name (county or city health
#     department, a technical college, an AHEC, a CESA, a DDS practice).
#   * otherwise §8's standing fallback (NONPROFIT_CBO, LOW,
#     RECIPIENT_TYPE_INFERRED).
# STATE AGENCIES are STATE_AGENCY -- never vendors, never hospitals (owner).
# cms_enrolment_match is present and EMPTY on every row (the CCN and the
# enrolment are in ccn and cms_enrolment_record), so R/03bj does not claim them.
#
# Usage:
#   Rscript R/03cx_wi_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

WIA_STATE   <- "WI"
WIA_CSV     <- file.path("data", "reference", "wi_year1_awardees.csv")
WIA_EVID    <- file.path("data", "evidence", "WI")
WIA_FED_DIR <- file.path("data", "evidence", "federal_records", "2026-11-20")
WIA_READ    <- as.Date("2026-11-19")
WIA_REVISED <- "Last revised November 18, 2026"
WIA_NOA     <- as.Date("2025-12-29")
WIA_ALLOTMENT <- 203670005.21
WIA_URL <- function(p) paste0("https://www.dhs.wisconsin.gov/rhtp/", p, ".htm")
WIA_FILE <- function(p) file.path(WIA_EVID, paste0("2026-11-19_dhs_rhtp_", p, ".htm", "l"))
WIA_CMS_REVIEW <- paste("Please note that all dollar amounts are the obligated awards and are",
                        "subject to Centers for Medicare & Medicaid Services (CMS) review.")

# The six tables as DHS prints them: page, table index on the page, pool name,
# the printed total and count (NA where DHS prints none), and the sentence.
WIA_TABLES <- tibble::tribble(
  ~page,              ~table_no, ~pool,                                                ~n,  ~printed_total, ~sentence,
  "implementation",   1L, "Implementation partners (Budget Year 1)",                   16L, 79373358.70,   "DHS awarded $79,373,358.70 to its implementation partners for Budget Year 1.",
  "workforce",        1L, "Community Health Worker grants",                            49L, 19942572,      "DHS awarded $19,942,572 to 49 organizations for the first year of funding.",
  "workforce",        2L, "Community Health Worker training provider grants",          2L,  274714,        "DHS awarded $274,714 for the first year of funding to two organizations",
  "technology",       1L, "Rural Technology Transformation funds",                     33L, 39740002,      "DHS awarded $39,740,002 in funding to 33 healthcare organizations",
  "technology",       2L, "Rural Dental Efficiency and Access grants",                 37L, 9500722,       "awarded $9,500,722 in grants to 37 organizations",
  "coordinated-care", 1L, "Sources of Strength Project",                               1L,  499921,        "DHS awarded $499,921 in the first year of funding to Cooperative Education Service Agency (CESA) 6")
WIA_COMPETITIVE_TOTAL <- 69957931
WIA_COMPETITIVE_SENTENCE <- "DHS awarded $69.9 million in grants for Budget Year 1"
WIA_TOTAL <- 149331289.71  # session 120 wrote "$149,330,290.71": a $999 slip; the six printed totals sum to this
WIA_ROWS  <- 138L
# One cent, DHS's own prose: the implementation table sums to $79,373,358.71.
WIA_IMPL_CENT_GAP <- 0.01

# Hand-read typings, each with its reason. key = the printed recipient.
#   kind: PARENT | FOUNDATION | HOSP_BRIDGE | HOSP_OPERATOR | TRIBAL | STATE_AGENCY |
#         UNIVERSITY | OTHER
WIA_OVERRIDES <- tibble::tribble(
  ~awardee, ~kind, ~ccn, ~why,
  "Ascension Wisconsin Inc.: Maternal Health", "PARENT", NA,
    "Ascension Wisconsin, the parent of Ascension's Wisconsin hospitals, which enrol under their own legal entities (e.g. ASCENSION NE WISCONSIN, INC; COLUMBIA ST MARYS HOSPITAL MILWAUKEE INC). CMS prints 'ASCENSION WISCONSIN' only as the DBA of MIDWEST ORTHOPEDIC SPECIALTY HOSPITAL, LLC (Franklin), a DIFFERENT legal body, so that DBA is NOT a match. ':' Maternal Health is DHS's project label, not part of the name. No site CCN is cited: a parent is no one site.",
  "Ascension Wisconsin Inc.: Community Care Navigation", "PARENT", NA,
    "Ascension Wisconsin, the parent of Ascension's Wisconsin hospitals (see the Maternal Health row; Midwest Orthopedic Specialty Hospital's DBA is not a match). ':' Community Care Navigation is DHS's project label.",
  "Ascension Wisconsin Inc.", "PARENT", NA,
    "Ascension Wisconsin, the parent of Ascension's Wisconsin hospitals, which enrol under their own legal entities; CMS's 'ASCENSION WISCONSIN' DBA on MIDWEST ORTHOPEDIC SPECIALTY HOSPITAL, LLC (Franklin) is a different legal body and NOT a match.",
  "Children's Hospital and Health System Inc.", "PARENT", NA,
    "Children's Hospital and Health System, the parent of Children's Wisconsin, whose hospitals enrol as CHILDRENS HOSPITAL OF WISCONSIN INC (Milwaukee and Neenah); the parent itself is not on CMS's WI Hospital Enrollments.",
  "Marshfield Clinic Health System Inc.", "PARENT", NA,
    "Marshfield Clinic Health System, the parent of the Marshfield Medical Center hospitals, which enrol under their own legal entities (MCHS HOSPITALS INC; FLAMBEAU HOSPITAL, INC.; BEAVER DAM COMMUNITY HOSPITALS INC.); the parent is not itself enrolled.",
  "Mayo Clinic Health System", "PARENT", NA,
    "Mayo Clinic Health System, whose Wisconsin hospitals enrol under the regional legal entities MAYO CLINIC HEALTH SYSTEM-NORTHWEST WISCONSIN REGION INC and -SOUTHWEST WISCONSIN REGION INC; the printed string names neither region, so it is typed as the system parent, not bridged.",
  "Bellin Gundersen Health System Inc. (Emplify Health)", "PARENT", NA,
    "Bellin Gundersen Health System (Emplify Health), the parent of BELLIN MEMORIAL HOSPITAL INC and GUNDERSEN LUTHERAN MEDICAL CENTER INC among others; the parent is not itself enrolled.",
  "ThedaCare Inc.", "PARENT", NA,
    "ThedaCare, the parent of the THEDACARE MEDICAL CENTER / REGIONAL MEDICAL CENTER entities (e.g. THEDACARE REGIONAL MEDICAL CENTER - APPLETON, INC); 'ThedaCare Inc.' is not itself enrolled.",
  "Door County Memorial Hospital Foundation Inc.", "FOUNDATION", NA,
    "§7 FOUNDATION ROW: the foundation of a NAMED hospital whose name it carries -- DOOR COUNTY MEMORIAL HOSPITAL, dba DOOR COUNTY MEDICAL CENTER, a critical access hospital (CCN 521358, Sturgeon Bay). The parent tie is a reading, so LOW (TN Cookeville, WV Cabell Huntington). The CCN is the parent's and stays off the row.",
  "The Richland Hospital Inc.", "HOSP_BRIDGE", "521341",
    "HAND-READ BRIDGE: CMS prints the legal name RICHLAND HOSPITAL with DBA THE RICHLAND HOSPITAL INC (CAH 521341, Richland Center); DHS prints the DBA. LOW (the exact-DBA grade, Missouri's).",
  "Fond du Lac County", "HOSP_OPERATOR", "524025",
    "§7 ENROLLED-HOSPITAL OPERATOR: CMS's WI Hospital Enrollments carry the legal entity FOND DU LAC COUNTY itself as a hospital (PART A PROVIDER - HOSPITAL, CCN 524025, Fond du Lac: a 4000-series psychiatric hospital number). DHS states no form, so the enrolment decides (session 72 precedence), and session 120's ruling on the County of Murray (a county enrolled as its CAH) is the precedent. LOW, not MEDIUM: the award is a CHW grant to the county, and a reader may prefer the City of Ketchikan reading (owner ruling, session 111: a local government that owns a hospital is not one). Reversible by CCN.",
  "Ho-Chunk Nation", "TRIBAL", NA,
    "a federally recognised Tribal Nation (DHS: 'All 11 federally recognized Tribal Nations in the state'); CMS enrols HO CHUNK NATION as an FQHC (dba HO-CHUNK HEALTH CARE CENTER, Black River Falls), which is a clinic the Nation operates, not a hospital.",
  "Red Cliff Band of Lake Superior Chippewa Indians", "TRIBAL", NA,
    "a federally recognised Tribal Nation.",
  "Bad River Band of Lake Superior Tribe of Chippewa Indians", "TRIBAL", NA,
    "a federally recognised Tribal Nation.",
  "Lac du Flambeau Band of Lake Superior Chippewa Indians", "TRIBAL", NA,
    "a federally recognised Tribal Nation.",
  "Department of Agriculture, Trade, and Consumer Protection", "STATE_AGENCY", NA,
    "a Wisconsin state agency (DATCP), an implementation partner named in the state's CMS application.",
  "Department of Public Instruction", "STATE_AGENCY", NA,
    "a Wisconsin state agency (DPI), an implementation partner; it re-awards to 21 school districts (second tier, not named here).",
  "Department of Veterans Affairs", "STATE_AGENCY", NA,
    "a Wisconsin state agency (WDVA), an implementation partner.",
  "Department of Workforce Development", "STATE_AGENCY", NA,
    "a Wisconsin state agency (DWD), an implementation partner; it administers the Rural Workforce Grants (second tier, not named here).",
  "Office of the Commissioner of Insurance", "STATE_AGENCY", NA,
    "a Wisconsin state agency (OCI), an implementation partner.",
  "Universities of Wisconsin", "UNIVERSITY", NA,
    "the Universities of Wisconsin System Administration (UWSA), the public university system; it re-awards to UW campuses (second tier).",
  "The Board of Regents of the University of Wisconsin System", "UNIVERSITY", NA,
    "the Board of Regents of the University of Wisconsin System, the public university system's legal entity.",
  "University of Wisconsin Population Health Institute – County Health Rankings & Roadmaps", "UNIVERSITY", NA,
    "an institute of the University of Wisconsin-Madison.",
  "University of Wisconsin Population Health Institute – Envision", "UNIVERSITY", NA,
    "an institute of the University of Wisconsin-Madison.",
  "Wisconsin Technical College System", "UNIVERSITY", NA,
    "the Wisconsin Technical College System, the public technical college system (Alaska's technical college precedent: UNIVERSITY_OR_AHC); it allocates to 16 colleges (second tier).",
  "Wisconsin Office of Rural Health", "UNIVERSITY", NA,
    "Wisconsin's State Office of Rural Health, housed at the University of Wisconsin-Madison School of Medicine and Public Health (general knowledge; DHS does not state it).",
  "Marquette University School of Dentistry", "UNIVERSITY", NA,
    "a school of Marquette University (private university).",
  "Medical College of Wisconsin", "UNIVERSITY", NA,
    "a private medical school; not on CMS's WI Hospital Enrollments.",
  "Dentistry.One of Wisconsin (MouthWatch Inc.)", "OTHER", NA,
    "a teledentistry company: the printed name carries MouthWatch Inc., a for-profit corporation. Not a hospital.")

# Names whose form is in the printed name (no enrolment needed).
wia_name_form <- function(x) {
  dplyr::case_when(
    stringr::str_detect(x, "Area Health Education Cent") ~ "AHEC",
    stringr::str_detect(x, "Cooperative Educational Service Agency") ~ "SCHOOL_OR_DISTRICT",
    stringr::str_detect(x, "Technical College") ~ "UNIVERSITY_OR_AHC",
    stringr::str_detect(x, "County Health Department|City-County Health Department|County Public Health|County Health and Human Services|^Marinette County$") ~ "LOCAL_GOVT_OR_PUBLIC_HEALTH",
    stringr::str_detect(x, "\\bDDS\\b|Orthodontics LLC|Dental LLC") ~ "OTHER",
    TRUE ~ NA_character_)
}

wia_norm <- function(x) {
  x <- toupper(dplyr::coalesce(x, ""))
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("\\(.*?\\)", " ", x)
  x <- gsub("[^A-Z0-9 ]", " ", x)
  x <- gsub("\\b(INC|LLC|THE|CORP|CORPORATION|CO|LTD|PLLC|PC|PA|INCORPORATED|DBA)\\b", " ", x)
  stringr::str_squish(x)
}
# The legal-name part of a printed recipient: before " DBA ", "(", ":" or " aka ".
wia_legal_part <- function(x) stringr::str_squish(sub(" DBA .*| \\(.*|:.*| aka .*", "", x))

wia_text <- function(f) {
  doc <- xml2::read_html(here::here(f))
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(gsub(" ", " ", xml2::xml_text(doc)))
}

#' Every recipient table on one page, as printed. `h` is a path or raw bytes.
wia_parse_page <- function(h, page) {
  doc <- if (is.raw(h)) xml2::read_html(h) else xml2::read_html(here::here(h))
  tabs <- xml2::xml_find_all(doc, "//table")
  dplyr::bind_rows(lapply(seq_along(tabs), function(k) {
    rows <- xml2::xml_find_all(tabs[[k]], ".//tr")
    cells <- lapply(rows, function(r) stringr::str_squish(gsub(" ", " ",
      xml2::xml_text(xml2::xml_find_all(r, "./td|./th")))))
    if (!identical(cells[[1]], c("Organization", "Amount"))) {
      stop("[WI] ", page, " table ", k, ": the header is no longer 'Organization | Amount': ",
           paste(cells[[1]], collapse = " | "), ". Read what the column now IS.", call. = FALSE)
    }
    body <- cells[-1]
    if (any(lengths(body) != 2L)) stop("[WI] ", page, " table ", k, ": a row is not two cells.", call. = FALSE)
    tibble::tibble(page = page, table_no = k,
                   awardee = vapply(body, `[`, "", 1),
                   amount_text = vapply(body, `[`, "", 2))
  })) %>%
    dplyr::mutate(amount = as.numeric(gsub("[$,]", "", amount_text)))
}

wia_parse <- function(files = NULL) {
  pages <- unique(WIA_TABLES$page)
  out <- dplyr::bind_rows(lapply(pages, function(p) {
    f <- if (is.null(files)) WIA_FILE(p) else files[[p]]
    wia_parse_page(f, p)
  }))
  if (!all(grepl("^\\$[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?$", out$amount_text))) {
    stop("[WI] an amount is not printed as dollars.", call. = FALSE)
  }
  out
}

#' Every printed total and count, asserted against the rows.
wia_assert_tables <- function(p, texts = NULL) {
  for (i in seq_len(nrow(WIA_TABLES))) {
    t <- WIA_TABLES[i, ]
    r <- p[p$page == t$page & p$table_no == t$table_no, ]
    if (nrow(r) != t$n) stop("[WI] ", t$pool, ": ", nrow(r), " rows, DHS says ", t$n, ".", call. = FALSE)
    gap <- abs(sum(r$amount) - t$printed_total)
    allowed <- if (t$page == "implementation") WIA_IMPL_CENT_GAP + 0.001 else 0.005
    if (gap > allowed) stop("[WI] ", t$pool, ": rows sum to $", format(sum(r$amount), nsmall = 2, big.mark = ","),
                            ", DHS prints $", format(t$printed_total, nsmall = 2, big.mark = ","), ".", call. = FALSE)
    txt <- if (is.null(texts)) wia_text(WIA_FILE(t$page)) else texts[[t$page]]
    if (!grepl(t$sentence, txt, fixed = TRUE)) stop("[WI] ", t$page, " no longer says '", t$sentence, "'.", call. = FALSE)
  }
  if (length(unique(paste(p$page, p$table_no))) != nrow(WIA_TABLES)) {
    stop("[WI] the pages carry ", length(unique(paste(p$page, p$table_no))), " tables, expected ",
         nrow(WIA_TABLES), ". A new table is a new pool: read it.", call. = FALSE)
  }
  comp <- p[p$page != "implementation", ]
  if (abs(sum(comp$amount) - WIA_COMPETITIVE_TOTAL) >= 0.005) stop("[WI] the competitive tables no longer sum to $69,957,931.", call. = FALSE)
  if (nrow(p) != WIA_ROWS || abs(sum(p$amount) - WIA_TOTAL) >= 0.005) {
    stop("[WI] expected ", WIA_ROWS, " rows / $149,331,289.71, have ", nrow(p), " / $",
         format(sum(p$amount), nsmall = 2, big.mark = ","), ".", call. = FALSE)
  }
  impl <- if (is.null(texts)) wia_text(WIA_FILE("implementation")) else texts[["implementation"]]
  for (w in c(WIA_COMPETITIVE_SENTENCE, WIA_CMS_REVIEW, WIA_REVISED)) {
    if (!grepl(w, impl, fixed = TRUE)) stop("[WI] the implementation page no longer says '", w, "'.", call. = FALSE)
  }
  invisible(TRUE)
}

#' THE PROBE'S QUESTION (R/03y --probe): do the live tables still equal the
#' extracted rows? A new row, a re-pricing, a removed row, a renamed recipient
#' or a new table all trip, so the file is REWRITTEN, not patched.
wia_assert_live <- function(bodies) {
  p <- wia_parse(files = bodies)
  a <- wia_parse()
  key <- function(d) paste(d$page, d$table_no, d$awardee, d$amount_text, sep = " | ")
  added <- setdiff(key(p), key(a)); gone <- setdiff(key(a), key(p))
  if (length(added) || length(gone) || nrow(p) != nrow(a)) {
    stop("[WI] the award tables moved: ", nrow(p), " rows / $",
         formatC(sum(p$amount), format = "f", digits = 2, big.mark = ","),
         if (length(added)) paste0("; NEW: ", paste(utils::head(added, 8), collapse = "; ")) else "",
         if (length(gone)) paste0("; GONE: ", paste(utils::head(gone, 8), collapse = "; ")) else "",
         ". Re-archive the pages, rewrite R/03cx's pins and rebuild.", call. = FALSE)
  }
  invisible(TRUE)
}

wia_enrolment <- function() {
  rd <- function(k) {
    j <- jsonlite::fromJSON(here::here(WIA_FED_DIR, paste0("cms_", k, "_enrollments_WI.json")))
    tibble::tibble(kind = k, org = j$`ORGANIZATION NAME`,
                   dba = dplyr::coalesce(j$`DOING BUSINESS AS NAME`, ""),
                   ccn = if (!is.null(j$CCN)) as.character(j$CCN) else NA_character_,
                   city = j$CITY, type = j$`PROVIDER TYPE TEXT`)
  }
  dplyr::bind_rows(rd("hosp"), rd("fqhc"), rd("rhc")) %>%
    dplyr::mutate(no = wia_norm(org), nd = wia_norm(dba))
}

#' One typing per distinct printed recipient.
wia_type <- function(awardees, enr = wia_enrolment()) {
  u <- unique(awardees)
  dplyr::bind_rows(lapply(u, function(a) {
    ov <- WIA_OVERRIDES[WIA_OVERRIDES$awardee == a, ]
    if (nrow(ov)) {
      rt <- switch(ov$kind, PARENT = , FOUNDATION = , HOSP_BRIDGE = , HOSP_OPERATOR = "HOSPITAL_OR_SYSTEM",
                   TRIBAL = "TRIBAL_ORG", STATE_AGENCY = "STATE_AGENCY", UNIVERSITY = "UNIVERSITY_OR_AHC",
                   OTHER = "OTHER")
      gk <- ov$kind %in% c("PARENT") || a %in% c("Wisconsin Office of Rural Health", "Dentistry.One of Wisconsin (MouthWatch Inc.)")
      rec <- if (!is.na(ov$ccn)) {
        e <- enr[enr$kind == "hosp" & enr$ccn == ov$ccn, ]
        if (nrow(e) != 1L) stop("[WI] override CCN ", ov$ccn, " is not exactly one enrolment.", call. = FALSE)
        paste0("CMS Hospital Enrollments: ", e$org, if (nzchar(e$dba)) paste0(" dba ", e$dba) else "",
               ", CCN ", e$ccn, ", ", e$type, " (", WIA_FED_DIR, ")")
      } else NA_character_
      return(tibble::tibble(awardee = a, kind = ov$kind, recipient_type = rt,
                            conf = if (ov$kind %in% c("STATE_AGENCY", "UNIVERSITY", "TRIBAL") && !gk) "MEDIUM" else "LOW",
                            ccn = ov$ccn, basis_type = if (gk) "GENERAL_KNOWLEDGE" else "STATE_SOURCE",
                            why = ov$why, enrol = rec))
    }
    n <- wia_norm(wia_legal_part(a))
    hit <- enr %>% dplyr::filter(no == n, !is.na(ccn))
    for (k in c("hosp", "fqhc")) {
      h <- hit[hit$kind == k, ]
      if (!nrow(h)) next
      six <- h[grepl("^[0-9]{6}$", h$ccn), ]
      cc <- sort(unique(six$ccn))
      main <- if (k == "hosp") cc[1] else NA_character_
      rec <- paste0("CMS ", if (k == "hosp") "Hospital" else "FQHC", " Enrollments: ", h$org[1],
                    ", CCN(s) ", paste(cc, collapse = "/"), " (", WIA_FED_DIR, ")")
      why <- paste0("the exact legal name ", h$org[1], " (", if (k == "hosp") h$type[h$ccn == main][1] else
                      "PART A PROVIDER - FEDERALLY QUALIFIED HEALTH CENTER (FQHC)",
                    if (k == "hosp") paste0(", CCN ", main) else "", ", ", h$city[1],
                    if (length(cc) > 1) paste0("; ", length(cc), " enrolled CCNs under this legal name: ",
                                               paste(cc, collapse = ", "), ", the lowest on the row") else "",
                    ").")
      return(tibble::tibble(awardee = a, kind = if (k == "hosp") "HOSP" else "FQHC",
                            recipient_type = if (k == "hosp") "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC",
                            conf = "MEDIUM", ccn = main, basis_type = "STATE_SOURCE", why = why, enrol = rec))
    }
    f <- wia_name_form(a)
    if (!is.na(f)) {
      why <- switch(f,
        AHEC = "an Area Health Education Center, by its printed name.",
        SCHOOL_OR_DISTRICT = "a Cooperative Educational Service Agency (a Wisconsin regional school-service agency), by its printed name.",
        UNIVERSITY_OR_AHC = "a Wisconsin technical college district, by its printed name (Alaska's technical college precedent).",
        LOCAL_GOVT_OR_PUBLIC_HEALTH = "a county or city-county government or health department, by its printed name. Where the county is itself enrolled as a hospital under ANOTHER string (County of Wood, CCN 524019), a department named without the legal entity is not bridged (§7, 'what it does not reach').",
        OTHER = "a dental practice (a DDS professional entity or dental LLC), by its printed name: a determined form outside §8's list, not a hospital.")
      return(tibble::tibble(awardee = a, kind = "NAME_FORM", recipient_type = f, conf = "MEDIUM",
                            ccn = NA_character_, basis_type = "STATE_SOURCE", why = why, enrol = NA_character_))
    }
    tibble::tibble(awardee = a, kind = "FALLBACK", recipient_type = "NONPROFIT_CBO", conf = "LOW",
                   ccn = NA_character_, basis_type = NA_character_,
                   why = "no CMS hospital, FQHC or RHC enrolment in Wisconsin carries the name, and DHS states no form.",
                   enrol = NA_character_)
  }))
}

wia_rows <- function() {
  p <- wia_parse()
  wia_assert_tables(p)
  if (!(WIA_READ > WIA_NOA)) stop("[WI] §6.2 date test.", call. = FALSE)
  if (any(abs(p$amount - WIA_ALLOTMENT) < RHTP_FOOTER_ALLOTMENT_MARGIN)) stop("[WI] a line equals the allotment (§0.2).", call. = FALSE)
  stale <- setdiff(WIA_OVERRIDES$awardee, p$awardee)
  if (length(stale)) stop("[WI] overrides for awardees not on the pages: ", paste(stale, collapse = "; "), call. = FALSE)
  ty <- wia_type(p$awardee)
  p <- p %>%
    dplyr::left_join(WIA_TABLES %>% dplyr::select(page, table_no, pool), by = c("page", "table_no")) %>%
    dplyr::left_join(ty, by = "awardee")
  hosp <- p$recipient_type == "HOSPITAL_OR_SYSTEM"
  fb <- p$kind == "FALLBACK"
  cls <- rhtp_classify_recipient_type(p$awardee, WIA_STATE)
  flag <- ifelse(fb, "RECIPIENT_TYPE_INFERRED;AMOUNT_PRELIMINARY", "AMOUNT_PRELIMINARY")
  impl <- p$page == "implementation"
  tibble::tibble(
    state = WIA_STATE,
    row_no = seq_len(nrow(p)),
    awardee = p$awardee,
    amount = p$amount,
    recipient_type = p$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(p$pool, ", DHS (", WIA_REVISED, ", read 2026-11-19). As printed: '", p$awardee, " | ",
                  p$amount_text, "'. ", if_else(impl,
                    "An implementation partner's first-tier Budget Year 1 award; any sub-round it runs is second tier and named nowhere here.",
                    "A competitive grant."),
                  " DHS: 'all dollar amounts are the obligated awards and are subject to Centers for Medicare & Medicaid Services (CMS) review.' An INTENT, not an executed award (owner ruling, session 121; Missouri's contingent-roster coding)."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = paste0("DHS Rural Health Transformation Program: ",
                                   tools::toTitleCase(gsub("-", " ", p$page)), " (", p$pool, ")"),
    state_source_url = WIA_URL(p$page),
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cx_wi_year1_awardees.R",
    ccn = ifelse(hosp, p$ccn, NA_character_),
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    dhs_page = p$page,
    dhs_table_no = p$table_no,
    cms_review = "SUBJECT_TO_CMS_REVIEW",
    recipient_type_source = paste0("TYPED (session 121, owner ruling; ",
                                   dplyr::case_when(p$kind %in% c("HOSP", "FQHC") ~ "exact legal name on CMS WI enrolment",
                                                    p$kind == "FALLBACK" ~ "no enrolment, §8 fallback",
                                                    p$kind == "NAME_FORM" ~ "form evident in the printed name",
                                                    TRUE ~ "HAND-READ"),
                                   "): ", p$why, " Classifier said ", cls$recipient_type, "/",
                                   rhtp_confidence_ceiling(cls$determination_confidence), "."),
    determination_confidence = p$conf,
    flag_reason = flag,
    award_pool = p$pool,
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "No"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = dplyr::case_when(
      p$kind == "PARENT" ~ paste0("§10.2 DIRECT, a health-system PARENT typed HOSPITAL_OR_SYSTEM on GENERAL KNOWLEDGE, LOW, no CCN (SD Sanford/Avera, VT UVM Health precedent): ", p$why, " §0.3a: the recipient, not the project, is coded."),
      p$kind == "FOUNDATION" ~ paste0("§10.2 DIRECT via §7's hospital-foundation row: ", p$why),
      hosp ~ paste0("§10.2 DIRECT: DHS names this recipient with its own amount; it is ", p$why, " §0.3a: the recipient is a hospital whatever the project."),
      p$recipient_type == "STATE_AGENCY" ~ paste0("§10.2 NON_HOSPITAL: ", p$why, " A state agency is never a vendor and never a hospital (owner, session 121)."),
      p$recipient_type == "OTHER" ~ paste0("§10.2 NON_HOSPITAL. Determined form: ",
                                           ifelse(grepl("MouthWatch", p$awardee), "a for-profit teledentistry company",
                                                  "a dental practice"),
                                           ". ", p$why),
      fb ~ paste0("§8 standing fallback (form unstated by DHS): ", p$why),
      TRUE ~ paste0("§10.2 NON_HOSPITAL: ", p$why)),
    amount_basis = "PRELIMINARY: printed exactly by DHS as 'the obligated awards ... subject to Centers for Medicare & Medicaid Services (CMS) review' (AMOUNT_PRELIMINARY).",
    basis_type = p$basis_type,
    recipient_subtype = NA_character_,
    cms_enrolment_match = NA_character_,
    round_amount = NA_real_,
    announcement_date = WIA_READ,
    source_archive_path = WIA_FILE(p$page),
    cms_enrolment_record = p$enrol)
}

WIA_EXPECT <- list(hosp_rows = 39L, hosp_usd = 32216238, state_agency_rows = 5L, state_agency_usd = 21083727.35)

wia_assert_rows <- function(a) {
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "flag_reason", "hospital_benefiting")) {
    vals <- unlist(strsplit(stats::na.omit(as.character(a[[col]])), ";", fixed = TRUE))
    bad <- setdiff(unique(vals), rhtp_vocabulary(col))
    if (length(bad)) stop("[WI] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (any(a$determination_confidence == "HIGH")) stop("[WI] HIGH (§7).", call. = FALSE)
  if (any(a$validation_source_type != "NOTICE_OF_INTENT_TO_AWARD")) stop("[WI] every row is an intent.", call. = FALSE)
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (nrow(h) != WIA_EXPECT$hosp_rows || abs(sum(h$amount) - WIA_EXPECT$hosp_usd) >= 0.005) {
    stop("[WI] expected ", WIA_EXPECT$hosp_rows, " hospital rows / $", format(WIA_EXPECT$hosp_usd, big.mark = ","),
         ", have ", nrow(h), " / $", format(sum(h$amount), nsmall = 2, big.mark = ","), ".", call. = FALSE)
  }
  s <- a[a$recipient_type == "STATE_AGENCY", ]
  if (nrow(s) != WIA_EXPECT$state_agency_rows || abs(sum(s$amount) - WIA_EXPECT$state_agency_usd) >= 0.005 ||
      any(s$distributed_to_hospital != "No")) stop("[WI] the state-agency rows moved.", call. = FALSE)
  # A hospital row either carries a CCN or is a hand-typed parent/foundation (GENERAL_KNOWLEDGE or LOW).
  if (any(h$determination_confidence == "MEDIUM" & is.na(h$ccn))) stop("[WI] a MEDIUM hospital row has no CCN.", call. = FALSE)
  invisible(TRUE)
}

wia_build <- function() {
  a <- wia_rows()
  wia_assert_rows(a)
  num <- function(x) ifelse(is.na(x), NA_character_,
                            vapply(x, function(v) format(v, scientific = FALSE, digits = 15), character(1)))
  out <- dplyr::mutate(a, dplyr::across(dplyr::where(is.numeric), num),
                       dplyr::across(dplyr::everything(), as.character))
  readr::write_csv(out, here::here(WIA_CSV), na = "")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[WI] %d rows / $%s; %d hospital rows / $%s; every row an intent.", nrow(a),
                  format(sum(a$amount), big.mark = ",", nsmall = 2), nrow(h),
                  format(sum(h$amount), big.mark = ",", nsmall = 2)))
  invisible(a)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { wia_assert_rows(wia_rows()); message("[WI] all assertions pass.") }
  if ("--build" %in% args) wia_build()
  if ("--report" %in% args) {
    a <- wia_rows()
    print(as.data.frame(a[, c("awardee", "amount", "award_pool", "recipient_type", "distributed_to_hospital",
                              "determination_confidence", "basis_type", "ccn")]), row.names = FALSE)
  }
  if (!length(args)) message("Usage: --validate | --build | --report")
}

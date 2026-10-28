#!/usr/bin/env Rscript
# 03cl_ca_bp1_awardees.R --------------------------------------------------------
#
# CALIFORNIA -- HCAI'S "RECOMMENDED SUBRECIPIENTS FOR CalRHT BUDGET PERIOD 1",
# 108 ROWS, $138,464,043.97 AS PRINTED, TYPED ON CMS'S CALIFORNIA ENROLMENT FILES.
# Session 109 (owner-approved; HELD in session 108).
#
# WHAT THE ROWS ARE: INTENTS. HCAI's own words, on the page that lists them:
#   "The awards listed on this page are tentative."
#   "Funding amounts shown reflect the amounts offered to potential
#    subrecipients and may differ from the final amounts disbursed."
#   "Inclusion on this list does not constitute a final grant award."
#   "Funding will not be finalized until HCAI and the selected organization
#    have fully executed a subrecipient agreement."
# So validation_source_type = NOTICE_OF_INTENT_TO_AWARD, amount_confirmed = No,
# flag AMOUNT_PRELIMINARY on every row (Texas's and Arkansas's intent coding).
#
# THE TOTAL IS NOT RECONCILED, AND IS NOT FORCED (owner instruction).
#   Rows as printed (five tables)            108 / $138,464,043.97
#   HCAI's prose: "$166.72 million in ... funding for 108 organizations"
#   Gap                                      $28,255,956.03
# By initiative, the row COUNTS equal HCAI's stated grant counts and the
# dollars do not:
#   Transformative Care Model  34 rows  $74,335,649.15  vs "Approximately $87.51 million supporting 34 recommended grants"
#   Workforce Development      65 rows  $54,169,999.00  vs "Approximately $67.56 million supporting 65 recommended grants"
#   Technology and Tools        9 rows   $9,958,395.82  vs "Approximately $11.65 million supporting 9 recommended grants"
# HCAI itself says the list "does not yet represent all Budget Period 1
# investments included in the initiative totals above", and the TCM sentence
# adds "along with milestone-based hospital investments and clinical training
# partnerships". Neither explains the Workforce gap on its face. The gap is
# recorded on every row's amount_basis and in ca_year1_status.csv; NOTHING is
# imputed to any recipient. HCAI also says "One applicant that was recommended
# to receive an award has subsequently withdrawn their application" WITHOUT
# naming it, so one of these rows may be withdrawn: the list is carried as
# printed.
#
# FOOTER (§0.2): "$233,639,308.46 with 100 percent funded by CMS/HHS" is the
# ALLOTMENT (anchor $233,639,308; within RHTP_FOOTER_ALLOTMENT_MARGIN), Tier 1,
# never a pool. §6.2: the list post-dates California's NOA (budget period from
# 2025-12-29) and sits on the CalRHT programme's own page.
#
# TYPING (owner instruction: "type every row on CMS CA enrolment"), in order:
#   1. CA_HAND below, each with its sentence.
#   2. EXACT: the string equals an ORGANIZATION NAME or DBA on CMS's CA Hospital,
#      FQHC or RHC Enrollment (2026-10-28) after case, punctuation, "&"/"and"
#      and a trailing INC/LLC/LP are set aside. MEDIUM. Where the match is on a
#      DBA, the CCN is the DBA's own record (Dignity Health enrols many
#      hospitals under one legal name). An RHC/FQHC DBA whose legal entity is
#      also enrolled as a hospital types the recipient a hospital (§10.2's
#      enrolled-operator row).
#   3. The classifier on the name, or §8's standing fallback. A classifier
#      "hospital" with no record and no hand read STOPS the build.
# System parents and hospital foundations are LOW, GENERAL_KNOWLEDGE, no CCN,
# and subtractable by basis_type (owner instruction).
#
# Usage:
#   Rscript R/03cl_ca_bp1_awardees.R --validate   assertions, offline
#   Rscript R/03cl_ca_bp1_awardees.R --build      write ca_year1_awardees.csv
#   Rscript R/03cl_ca_bp1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

CAR_STATE <- "CA"
CAR_FILE  <- file.path("data", "evidence", "CA",
                       "2026-10-28_ca_hcai_calrht_program_updates_RECOMMENDED_SUBRECIPIENTS.html")
CAR_PRIOR <- file.path("data", "evidence", "CA",
                       "2026-10-26_ca_hcai_calrht_program_updates_RECOMMENDED_SUBRECIPIENTS.html")
CAR_URL   <- "https://hcai.ca.gov/rural-health/calrht/calrht-program-updates/"
CAR_TITLE <- paste0("HCAI, 'Recommended Subrecipients for CalRHT Budget Period 1 Announced' ",
                    "(October 21, 2026), CalRHT Program Updates")
CAR_DATE  <- as.Date("2026-10-21")
CAR_OUT   <- "data/reference/ca_year1_awardees.csv"
CAR_ROWS  <- 108L
CAR_TOTAL <- 138464043.97
CAR_PROSE <- 166720000
CAR_GRANTS <- tibble::tribble(
  ~table, ~award_pool, ~initiative, ~rows, ~subtotal,
  1L, "Accelerator Partner Program", "Transformative Care Model", 19L, 37606550.15,
  2L, "FM-OB Fellowship Program", "Transformative Care Model", 4L, 1729103.00,
  3L, "Transformative Payments", "Transformative Care Model", 11L, 34999996.00,
  4L, "Workforce Development Recruitment and Retention Program (WDRR)", "Workforce Development", 65L, 54169999.00,
  5L, "Electronic Health Record Modernization (EHR)", "Technology and Tools", 9L, 9958395.82)
CAR_PROSE_BY_INIT <- c(`Transformative Care Model` = 87510000, `Workforce Development` = 67560000,
                       `Technology and Tools` = 11650000)
CAR_TENTATIVE <- c(
  "The awards listed on this page are tentative.",
  "Inclusion on this list does not constitute a final grant award.",
  "Funding amounts shown reflect the amounts offered to potential subrecipients and may differ from the final amounts disbursed.",
  "distributing $166.72 million in California Rural Health Transformation Program funding for 108 organizations",
  "does not yet represent all Budget Period 1 investments included in the initiative totals above",
  "One applicant that was recommended to receive an award has subsequently withdrawn their application.")
CAR_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-10-28", "cms_hosp_enrollments_CA.json"),
  FQHC     = file.path("data", "evidence", "federal_records", "2026-10-28", "cms_fqhc_enrollments_CA.json"),
  RHC      = file.path("data", "evidence", "federal_records", "2026-10-28", "cms_rhc_enrollments_CA.json"))

car_html <- function(path) {
  raw <- readBin(here::here(path), "raw", file.size(here::here(path)))
  xml2::read_html(rawToChar(raw[raw != as.raw(0)]))
}

car_read <- function(path = CAR_FILE) {
  h  <- car_html(path)
  tb <- rvest::html_table(rvest::html_elements(h, "table"))
  if (length(tb) != nrow(CAR_GRANTS) ||
      !all(vapply(tb, function(t) identical(names(t), c("Awarded Entity", "Counties Served", "Recommended Funding")), logical(1)))) {
    stop("[CA roster] the page no longer carries the five recorded tables: re-read it (§0.4).", call. = FALSE)
  }
  # The tables follow their grant headings in this order on the page.
  txt <- stringr::str_squish(rvest::html_text2(h))
  pos <- vapply(c("Accelerator Partner Program", "FM-OB Fellowship Program", "Transformative Payments",
                  "Workforce Development Recruitment and Retention Program (WDRR)",
                  "Electronic Health Record Modernization (EHR)"),
                function(x) regexpr(x, txt, fixed = TRUE)[1], numeric(1))
  if (any(pos < 0) || is.unsorted(pos)) stop("[CA roster] the grant headings moved.", call. = FALSE)
  d <- dplyr::bind_rows(lapply(seq_along(tb), function(i) tibble::tibble(
    table = i, roster_line = seq_len(nrow(tb[[i]])),
    awardee = stringr::str_squish(tb[[i]][[1]]),
    counties_served = stringr::str_squish(tb[[i]][[2]]),
    amount_printed = stringr::str_squish(tb[[i]][[3]]),
    amount = round(as.numeric(gsub("[^0-9.]", "", tb[[i]][[3]])), 2))))
  dplyr::left_join(d, CAR_GRANTS[, c("table", "award_pool", "initiative")], by = "table")
}

car_assert_roster <- function(d = car_read()) {
  if (nrow(d) != CAR_ROWS || anyNA(d$amount) || any(!nzchar(d$awardee))) {
    stop("[CA roster] ", nrow(d), " rows, not 108, or a row has no name or amount.", call. = FALSE)
  }
  if (abs(sum(d$amount) - CAR_TOTAL) > 0.005) {
    stop("[CA roster] the rows sum to $", formatC(sum(d$amount), format = "f", digits = 2, big.mark = ","),
         ", not $138,464,043.97.", call. = FALSE)
  }
  by <- d %>% dplyr::group_by(table) %>% dplyr::summarise(n = dplyr::n(), s = sum(amount))
  if (!identical(by$n, CAR_GRANTS$rows) || any(abs(by$s - CAR_GRANTS$subtotal) > 0.005)) {
    stop("[CA roster] a grant table's row count or subtotal moved.", call. = FALSE)
  }
  txt <- stringr::str_squish(rvest::html_text2(car_html(CAR_FILE)))
  miss <- CAR_TENTATIVE[!vapply(CAR_TENTATIVE, grepl, logical(1), x = txt, fixed = TRUE)]
  if (length(miss)) {
    stop("[CA roster] the page no longer says: ", paste(sQuote(miss), collapse = "; "),
         ". The INTENT coding and the unreconciled-gap record rest on these sentences.", call. = FALSE)
  }
  # The 10-26 copy session 108 read carries the same rows to the cent.
  p <- car_read(CAR_PRIOR)
  if (!identical(p[, c("awardee", "amount")], d[, c("awardee", "amount")])) {
    stop("[CA roster] the 10-28 rows differ from the 10-26 rows session 108 read.", call. = FALSE)
  }
  invisible(TRUE)
}

# -- typing ---------------------------------------------------------------------

car_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("['’]", "", x)
  x <- gsub("&", " AND ", x, fixed = TRUE)
  x <- gsub("[.,/()–-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC|PA|LP|LTD)$", "", x)
}

car_federal <- function() {
  dplyr::bind_rows(lapply(names(CAR_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(CAR_FED[[k]]))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = if ("PROVIDER TYPE TEXT" %in% names(j)) j$`PROVIDER TYPE TEXT` else NA_character_)
  }))
}

CAR_PARENT <- function(who, kids) paste0(
  "SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, Guthrie, ",
  "Ballad/Sentara/Valley, St. Luke's): ", who, " is the parent of ", kids,
  ". CMS CA enrols none of its hospitals under this string, so no CCN. Subtractable by basis_type.")
CAR_FOUNDATION <- function(parent) paste0(
  "A FOUNDATION OR AFFILIATED ARM OF A NAMED HOSPITAL OR HEALTH SYSTEM (§10.2's foundation row; the ",
  "test is the PARENT, named in the string): ", parent, ". HOSPITAL_OR_SYSTEM, LOW, GENERAL_KNOWLEDGE, ",
  "no CCN (a separate legal body from the enrolled hospital). Subtractable by basis_type.")
CAR_BRIDGE <- function(rec) paste0("HAND-READ BRIDGE, LOW: CMS CA Hospital Enrollment carries ", rec, ".")

CA_HAND <- tibble::tribble(
  ~pattern, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~flow, ~why,
  "^Adventist Health System/West$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT",
  CAR_PARENT("Adventist Health System/West (Adventist Health's California parent corporation)",
             "the Adventist Health hospitals CMS enrols under their own legal names (WILLITS HOSPITAL INC 051310, SONORA COMMUNITY HOSPITAL 050335, UKIAH ADVENTIST HOSPITAL 050301, ADVENTIST HEALTH MEDICAL CENTER TEHACHAPI 051301, among others); the row's counties (Calaveras, Fresno, Lake, Mendocino, Napa, Tehama, Tulare, Tuolumne) are its hospitals'"),
  "^NorthBay Healthcare Corporation$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT",
  CAR_PARENT("NorthBay Healthcare Corporation", "NorthBay Medical Center (CMS: NORTHBAY PHYSICIANS SURGERY CENTER, LLC dba NORTHBAY MEDICAL CENTER, 050367, Fairfield)"),
  "^Banner Health Foundation$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT",
  CAR_FOUNDATION("Banner Health, a hospital system; the row serves Lassen County, whose hospital is BANNER LASSEN MEDICAL CENTER (CAH 051320)"),
  "^Providence Medical Foundation$", "PHYSICIAN_PRACTICE", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL",
  paste("OWNER RULING, SESSION 110 (CA_PROVIDENCE_MEDICAL_FOUNDATION_FORM): NOT A HOSPITAL ROW. A California 'medical",
        "foundation' is a clinic-operating affiliate under HSC 1206(l) that contracts physician groups to deliver",
        "outpatient care; §10.2's foundation row covers a hospital's FUNDRAISING foundation only. Typed",
        "PHYSICIAN_PRACTICE (the form it operates), LOW, GENERAL_KNOWLEDGE. Its parent, Providence, is a hospital",
        "system (Humboldt County: Providence St. Joseph Hospital Eureka, Providence Redwood Memorial); that does not",
        "make a clinic operator a hospital. -$450,000 from NAMED_HOSPITAL."),
  "^Sierra Nevada Memorial Hospital Foundation$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT",
  CAR_FOUNDATION("Sierra Nevada Memorial Hospital (CMS: SIERRA NEVADA MEMORIAL-MINERS HOSPITAL dba SIERRA NEVADA MEMORIAL HOSPITAL, 050150, Grass Valley)"),
  "^Jerod Phelps Community Hospital, Southern Humboldt Community Clinic$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "051309", "DIRECT",
  paste(CAR_BRIDGE("SOUTHERN HUMBOLDT COMMUNITY HEALTHCARE DISTRICT dba JEROLD PHELPS COMMUNITY HOSPITAL (CAH 051309, Garberville) and, as an RHC DBA of the same legal entity, SOUTHERN HUMBOLDT COMMUNITY CLINIC (553991)"),
        "The string welds TWO DBAs OF ONE LEGAL ENTITY (§0.3a's corollary: split the field and code the half that received the money; both halves are the district), and misspells 'Jerold'."),
  "^Kaweah Health$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050057", "DIRECT",
  CAR_BRIDGE("KAWEAH DELTA HEALTH CARE DISTRICT dba KAWEAH HEALTH MEDICAL CENTER (050057, Visalia); 'Kaweah Health' is the district's trading name, a prefix of the DBA"),
  "^Mee Memorial Healthcare System$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "051336", "DIRECT",
  CAR_BRIDGE("SOUTHERN MONTEREY COUNTY MEMORIAL HOSPITAL dba GEORGE L. MEE MEMORIAL HOSPITAL (CAH 051336, King City); the string is its trading name"),
  "^Mercy Medical Center – Northern California Maternity Collaborative$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", NA, "DIRECT",
  paste("HAND-READ, LOW, NO CCN: the recipient half of the string is 'Mercy Medical Center', a DBA CMS carries under DIGNITY HEALTH three times (MERCY MEDICAL CENTER, Merced 050444; MERCY MEDICAL CENTER REDDING 050280; MERCY MEDICAL CENTER MT SHASTA 051319).",
        "The row serves Shasta, Siskiyou, Tehama, Lassen and Modoc, which holds Redding and Mt Shasta, so which one is not determinable. Every candidate is an enrolled Dignity Health hospital, so the recipient is a hospital either way."),
  "^Salinas Valley Memorial Hospital$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050334", "DIRECT",
  CAR_BRIDGE("SALINAS VALLEY MEMORIAL HEALTHCARE SYSTEM dba SALINAS VALLEY HEALTH MEDICAL CENTER (050334, Salinas); the string is the hospital's former name"),
  "^San Benito Healthcare District/Hazel Hawkins Memorial Hospital$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "051337", "DIRECT",
  CAR_BRIDGE("HAZEL HAWKINS MEMORIAL HOSPITAL dba SAN BENITO HOSPITAL DISTRICT (CAH 051337, Hollister); the string welds the district's current name and the hospital's"),
  "^San Bernardino County, Arrowhead Regional Medical Center$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050245", "DIRECT",
  paste(CAR_BRIDGE("COUNTY OF SAN BERNARDINO dba ARROWHEAD REGIONAL MEDICAL CENTER (050245, Colton)"),
        "The string welds the legal entity and the DBA; the county is CMS-enrolled as the hospital's operator (§10.2's enrolled-operator row), and the string names the hospital, not the county's FQHCs."),
  "^CommuniCare\\+OLE$", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, "NON_HOSPITAL",
  "HAND-READ BRIDGE: CMS CA FQHC Enrollment carries OLE HEALTH (Napa, Fairfield, Davis, Woodland and others); 'CommuniCare+OLE' is the trading name of the merged CommuniCare Health Centers and OLE Health. An FQHC. LOW.",
  "^Shasta Cascade Health Centers$", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, "NON_HOSPITAL",
  "HAND-READ BRIDGE: CMS CA FQHC Enrollment carries MCCLOUD HEALTHCARE CLINIC, INC. dba SHASTA CASCADE HEALTH CENTERS- MT SHASTA (921872). An FQHC. LOW.",
  "^Good Samaritan Hospital, LP$", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "050257", "DIRECT",
  paste("HAND-READ, EXACT DBA: the string is, verbatim, the DBA CMS CA Hospital Enrollment carries for GOOD SAMARITAN",
        "HOSPITAL CA LTD PTP (050257, Bakersfield). Normalised, it ALSO equals the legal name GOOD SAMARITAN HOSPITAL, L.P.",
        "(050380, San Jose), a different legal entity; the row serves Kern County, which is Bakersfield's. MEDIUM."),
  "^Inland Empire Health Plan$", "MANAGED_CARE_ORGANIZATION", "GENERAL_KNOWLEDGE", "LOW", NA, "NON_HOSPITAL",
  "A Medi-Cal managed care plan (general knowledge; 'Health Plan' is in the string; the list states no form). Never a hospital type.",
  "^UC San Diego Health$", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, "DIRECT",
  paste("OWNER RULING, SESSION 110 (CA_UCSD_STRINGS_NO_ENROLLED_ENTITY, AHC_STRING_NAMES_NO_ENROLLED_ENTITY): A ROW",
        "NAMING THE HEALTH SYSTEM IS A HOSPITAL ROW. 'UC San Diego Health' is the trading name of the health system",
        "CMS enrols under REGENTS OF THE UNIVERSITY OF CALIFORNIA (050025, San Diego; 05S025 dba UCSD MEDICAL CENTER).",
        "HOSPITAL_OR_SYSTEM, recipient_subtype ACADEMIC_HEALTH_CENTER, LOW, GENERAL_KNOWLEDGE, no CCN on the row (the",
        "string does not print the enrolled legal entity). Subtractable by subtype and by basis_type."),
  "^Southern California Rural Health Collaborative – University of California, San Diego$",
  "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, "NON_HOSPITAL",
  paste("OWNER RULING, SESSION 110 (CA_UCSD_STRINGS_NO_ENROLLED_ENTITY): A ROW NAMING A SCHOOL, DEPARTMENT OR",
        "PROGRAMME IS NOT A HOSPITAL ROW. The string names a collaborative and the University of California, San",
        "Diego (the campus), not its health system; CMS enrols the hospitals under REGENTS OF THE UNIVERSITY OF",
        "CALIFORNIA (050025), which the string does not name. UNIVERSITY_OR_AHC, NON_HOSPITAL."),
  "^Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics$", "NONPROFIT_CBO", NA, "LOW", NA, "NON_HOSPITAL",
  paste("THE ROW NAMES A FELLOWSHIP PROGRAMME, NOT AN ORGANISATION. No CMS record carries it, and the sponsoring",
        "institution is not stated, so §8's standing fallback, RECIPIENT_TYPE_INFERRED. Not inferred to a Fresno",
        "hospital (§0.4). QUEUED: CA_FM_OB_FRESNO_SPONSOR_NOT_NAMED."))

# Session 110 (owner ruling a): an academic health system named as itself is a
# hospital row, flagged so it subtracts.
CA_AHC_SUBTYPE <- c("UC San Diego Health")

car_type <- function(d, f = car_federal()) {
  cls <- rhtp_classify_recipient_type(d$awardee, CAR_STATE)
  hosp_orgs <- unique(f$org[f$kind == "HOSPITAL"])
  out <- lapply(seq_len(nrow(d)), function(i) {
    a <- d$awardee[i]
    hd <- CA_HAND[vapply(CA_HAND$pattern, grepl, logical(1), x = a), ][1, ]
    if (!is.na(hd$pattern)) {
      return(tibble::tibble(recipient_type = hd$recipient_type, basis_type = hd$basis_type,
                            determination_confidence = hd$confidence, typing = "HAND-READ",
                            why = hd$why, ccn = hd$ccn, flow = hd$flow))
    }
    by_org <- car_norm(f$org) %in% car_norm(a)
    by_dba <- car_norm(dplyr::coalesce(f$dba, "")) %in% car_norm(a)
    hit <- f[by_org | by_dba, ]
    if (nrow(hit)) {
      ent <- unique(hit$org)
      is_hosp <- any(hit$kind == "HOSPITAL") || any(ent %in% hosp_orgs)
      # A DBA match keeps its own records: one legal entity (Dignity Health)
      # can hold many hospitals.
      recs <- if (is_hosp && any(by_dba[by_org | by_dba] & hit$kind == "HOSPITAL")) {
        hit[hit$kind == "HOSPITAL", ]
      } else if (is_hosp) f[f$kind == "HOSPITAL" & f$org %in% ent, ] else hit
      six <- sort(unique(recs$ccn[grepl("^[0-9]{6}$", recs$ccn)]))
      if (is_hosp && !length(six)) {
        # A DBA held only by a sub-unit record (Sonora's 05U335): read the
        # legal entity's own hospital record.
        recs <- f[f$kind == "HOSPITAL" & f$org %in% ent, ]
        six  <- sort(unique(recs$ccn[grepl("^[0-9]{6}$", recs$ccn)]))
      }
      if (is_hosp && length(unique(f$org[f$kind == "HOSPITAL" & f$org %in% ent])) > 1L) {
        stop("[CA roster] '", a, "' matches more than one enrolled hospital legal entity (",
             paste(unique(ent), collapse = "; "), "). Read it and hand-code it.", call. = FALSE)
      }
      via <- if (is_hosp && !any(hit$kind == "HOSPITAL"))
        paste0(" The string is the ", paste(unique(hit$kind), collapse = "/"), " DBA of ",
               paste(ent, collapse = "; "), ", WHICH CMS ALSO ENROLS AS A HOSPITAL: a hospital on ",
               "its enrolment (§10.2's enrolled-operator row).") else ""
      dbas <- unique(recs$dba[nzchar(dplyr::coalesce(recs$dba, ""))])
      rec <- paste0(paste(unique(recs$org), collapse = "; "),
                    if (length(dbas)) paste0(" dba ", paste(dbas, collapse = " / ")) else "",
                    " (", paste(six, collapse = "/"), ")")
      return(tibble::tibble(
        recipient_type = if (is_hosp) "HOSPITAL_OR_SYSTEM" else "FQHC_OR_RHC",
        basis_type = "ORG_WEBSITE", determination_confidence = "MEDIUM", typing = "EXACT",
        why = paste0("EXACT federal record: CMS CA ", paste(unique(hit$kind), collapse = "/"),
                     " Enrollment carries this string as an ORGANIZATION NAME or DBA: ", rec,
                     if (is_hosp) paste0(", ", unique(recs$ptype)[1]) else "", ".", via),
        ccn = if (is_hosp && length(six) == 1L) six else NA_character_,
        flow = if (is_hosp) "DIRECT" else "NON_HOSPITAL"))
    }
    if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[CA roster] the classifier calls '", a, "' a hospital and no federal record or ",
           "hand-read decision covers it. Read it.", call. = FALSE)
    }
    fb <- cls$rule[i] == "FALLBACK"
    tibble::tibble(
      recipient_type = cls$recipient_type[i],
      basis_type = if (fb) NA_character_ else "STATE_SOURCE",
      determination_confidence = if (fb) "LOW" else rhtp_confidence_ceiling(cls$determination_confidence[i]),
      typing = if (fb) "FALLBACK" else "CLASSIFIER",
      why = if (fb) "The list states no form and no CMS CA Hospital, FQHC or RHC enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
            else paste0("No CMS CA enrolment carries the string; the form is read from the string itself (",
                        cls$recipient_type_basis[i], ")."),
      ccn = NA_character_, flow = "NON_HOSPITAL")
  })
  t <- dplyr::bind_rows(out)
  t$classifier <- paste0(cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence))
  t
}

car_amount_basis <- function(d) {
  gap <- CAR_PROSE - CAR_TOTAL
  init <- d %>% dplyr::group_by(initiative) %>% dplyr::summarise(s = sum(amount), .groups = "drop")
  igap <- stats::setNames(CAR_PROSE_BY_INIT[init$initiative] - init$s, init$initiative)
  paste0("The row's own 'Recommended Funding', exact as printed: the amount OFFERED, which HCAI says 'may differ ",
         "from the final amounts disbursed'. UNRECONCILED, NOT FORCED: the 108 rows sum to $138,464,043.97 ",
         "against HCAI's prose '$166.72 million ... for 108 organizations' (gap $",
         formatC(gap, format = "f", digits = 2, big.mark = ","), "). This row's initiative (", d$initiative,
         ") prints 'Approximately $", formatC(CAR_PROSE_BY_INIT[d$initiative] / 1e6, format = "f", digits = 2),
         " million' against rows summing to $", formatC(init$s[match(d$initiative, init$initiative)], format = "f",
         digits = 2, big.mark = ","), " (gap $", formatC(igap[d$initiative], format = "f", digits = 2, big.mark = ","),
         "). Nothing is imputed to any recipient.")
}

#' The award file: all 108 rows, as INTENTS.
ca_bp1_awardees <- function(d = car_read(), f = car_federal()) {
  t <- car_type(d, f)
  hosp  <- t$recipient_type == "HOSPITAL_OR_SYSTEM" & t$flow == "DIRECT"
  dist  <- ifelse(hosp, "Yes", "No")
  flag  <- ifelse(t$typing == "FALLBACK" | is.na(t$basis_type), "AMOUNT_PRELIMINARY;RECIPIENT_TYPE_INFERRED", "AMOUNT_PRELIMINARY")
  tibble::tibble(
    state = CAR_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = dist,
    note = paste0(d$award_pool, " (", d$initiative, ") line ", d$roster_line, " on HCAI's Recommended ",
                  "Subrecipients for CalRHT Budget Period 1; Counties Served: ", d$counties_served, ".",
                  ifelse(d$award_pool == "Transformative Payments",
                         " HCAI: 'conditional, milestone-based investments to support hospital participation in feasible components of the TCM'.", ""),
                  ifelse(d$award_pool == "FM-OB Fellowship Program",
                         " Printed under Transformative Care Model; HCAI describes the programme as 'under Expand and Support Rural Workforce Capacity'.", "")),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = CAR_TITLE,
    state_source_url = CAR_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cl_ca_bp1_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    roster_line = d$roster_line,
    roster_type = d$initiative,
    counties_served = d$counties_served,
    recipient_type_source = paste0("TYPED (session 109, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence, t$ccn),
    flag_reason = flag,
    award_pool = d$award_pool,
    budget_period = "Budget Period 1",
    flow_type = t$flow,
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", t$flow, ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", ""),
                                 " AN INTENT, NOT AN AWARD: HCAI calls the list 'tentative' and says inclusion 'does not ",
                                 "constitute a final grant award' until a subrecipient agreement is executed."),
    amount_basis = car_amount_basis(d),
    basis_type = t$basis_type,
    recipient_subtype = ifelse(d$awardee %in% CA_AHC_SUBTYPE, "ACADEMIC_HEALTH_CENTER", NA_character_),
    round_amount = NA_real_,
    announcement_date = CAR_DATE,
    source_archive_path = CAR_FILE)
}

car_assert_typing <- function(a = ca_bp1_awardees()) {
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[CA roster] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  if (any(a$distributed_to_hospital == "Unclear")) stop("[CA roster] an Unclear row appeared: read it.", call. = FALSE)
  unused <- CA_HAND$pattern[!vapply(CA_HAND$pattern, function(p) any(grepl(p, a$awardee)), logical(1))]
  if (length(unused)) stop("[CA roster] hand reads match no line: ", paste(unused, collapse = "; "), call. = FALSE)
  if (length(setdiff(a$validation_source_type, rhtp_vocabulary("source_doc_type")))) stop("[CA roster] validation_source_type outside §8.", call. = FALSE)
  if (!all(grepl("AMOUNT_PRELIMINARY", a$flag_reason))) stop("[CA roster] an intent row lost AMOUNT_PRELIMINARY.", call. = FALSE)
  rhtp_assert_high_has_ccn(a, "CA roster")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[CA roster] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[CA roster] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

car_validate <- function() {
  d <- car_read()
  car_assert_roster(d)
  a <- ca_bp1_awardees(d)
  car_assert_typing(a)
  invisible(a)
}

car_build <- function() {
  a <- car_validate()
  readr::write_csv(a, here::here(CAR_OUT), na = "")
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  message("[CA roster] wrote ", CAR_OUT, ": ", nrow(a), " rows, $",
          formatC(sum(a$amount), format = "f", digits = 2, big.mark = ","), "; NAMED_HOSPITAL ",
          nrow(h), " / $", formatC(sum(h$amount), format = "f", digits = 2, big.mark = ","), ".")
  invisible(a)
}

car_report <- function(a = car_validate()) {
  h <- a[a$hospital_attribution == "NAMED_HOSPITAL", ]
  lowgk <- h[h$determination_confidence == "LOW", ]
  cat("\nCALIFORNIA -- HCAI Recommended Subrecipients, Budget Period 1 (INTENTS)\n")
  cat(sprintf("  rows %d  $%s (prose $166.72M; gap $%s, unreconciled)\n", nrow(a),
              formatC(sum(a$amount), format = "f", digits = 2, big.mark = ","),
              formatC(CAR_PROSE - sum(a$amount), format = "f", digits = 2, big.mark = ",")))
  cat(sprintf("  NAMED_HOSPITAL %d / $%s; LOW %d / $%s; GENERAL_KNOWLEDGE %d / $%s\n", nrow(h),
              formatC(sum(h$amount), format = "f", digits = 2, big.mark = ","), nrow(lowgk),
              formatC(sum(lowgk$amount), format = "f", digits = 2, big.mark = ","),
              sum(h$basis_type %in% "GENERAL_KNOWLEDGE"),
              formatC(sum(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"]), format = "f", digits = 2, big.mark = ",")))
  print(as.data.frame(a %>% dplyr::group_by(award_pool, hospital_attribution) %>%
                        dplyr::summarise(rows = dplyr::n(), amount = sum(amount), .groups = "drop")))
  invisible(a)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) { car_validate(); message("[CA roster] all assertions pass.") }
  if ("--build" %in% args)    car_build()
  if ("--report" %in% args)   car_report()
  if (!length(intersect(args, c("--validate", "--build", "--report")))) {
    message("usage: Rscript R/03cl_ca_bp1_awardees.R [--validate] [--build] [--report]")
  }
}

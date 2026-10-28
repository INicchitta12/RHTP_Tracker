#!/usr/bin/env Rscript
# 03cl_ca_bp1_recommended_awardees.R -------------------------------------------
#
# CALIFORNIA -- HCAI'S "RECOMMENDED SUBRECIPIENTS FOR CalRHT BUDGET PERIOD 1",
# 108 ROWS, $138,464,043.97 AS PRINTED, EXTRACTED AS INTENTS AND TYPED ON CMS'S
# CALIFORNIA ENROLMENT FILES. Session 109 (owner-approved; held in session 108).
#
# THE PAGE. hcai.ca.gov/rural-health/calrht/calrht-program-updates/, posted
# 2026-10-21, archived by R/03ab 2026-10-26 (re-read live 2026-10-28: the five
# tables are byte-for-byte the same rows and figures). Five tables, each
# "Awarded Entity | Counties Served | Recommended Funding":
#   Accelerator Partner Program        19   $37,606,550.15   (Transformative Care Model)
#   FM-OB Fellowship Program            4    $1,729,103.00   (Transformative Care Model)
#   Transformative Payments            11   $34,999,996.00   (Transformative Care Model)
#   WDRR                               65   $54,169,999.00   (Workforce Development)
#   EHR Modernization                   9    $9,958,395.82   (Technology and Tools)
# The tables are read in page order and asserted against those counts.
#
# THEY ARE INTENTS, IN HCAI'S OWN WORDS. "The awards listed on this page are
# tentative"; "Inclusion on this list does not constitute a final grant award";
# "Funding amounts shown reflect the amounts offered to potential subrecipients
# and may differ from the final amounts disbursed"; "Funding will not be
# finalized until HCAI and the selected organization have fully executed a
# subrecipient agreement". So validation_source_type NOTICE_OF_INTENT_TO_AWARD,
# amount_confirmed No and AMOUNT_PRELIMINARY on every row: Texas's posture for
# the Rural Texas Strong Intent to Award list (R/03ce).
#
# THE PROSE FIGURE IS NOT THE ROW TOTAL, AND THE GAP IS RECORDED, NOT FORCED.
# The page says "$166.72 million ... for 108 organizations across 45 counties",
# by initiative "Approximately $87.51 million supporting 34 recommended grants,
# along with milestone-based hospital investments and clinical training
# partnerships" (TCM), "$67.56 million supporting 65 recommended grants"
# (Workforce) and "$11.65 million supporting 9 recommended grants" (Technology).
# THE GRANT COUNTS RECONCILE (34 = 19 + 4 + 11; 65; 9), THE DOLLARS DO NOT:
#   TCM         $87.51M vs $74,335,649.15 printed   gap ~$13.17M
#   Workforce   $67.56M vs $54,169,999.00 printed   gap ~$13.39M
#   Technology  $11.65M vs  $9,958,395.82 printed   gap  ~$1.69M
#   Total      $166.72M vs $138,464,043.97 printed  gap ~$28.26M
# HCAI says why in general terms only: the list "does not yet represent all
# Budget Period 1 investments included in the initiative totals above.
# Additional recommendations will be added as they are ready for publication",
# and "One applicant that was recommended to receive an award has subsequently
# withdrawn their application." No row is invented for the gap, and the prose
# figure is never used as a total (ca_bp1_gap()).
#
# THE TRANSFORMATIVE PAYMENTS ARE HOSPITAL MONEY BY THEIR OWN DEFINITION, AND
# STILL CODED ROW BY ROW. "Transformative Payments are investments in a select
# group of rural hospitals ... conditional, milestone-based investments". All
# eleven recipients are CMS-enrolled hospitals; each is typed on its own record
# like every other row (§0.3a), never off the table heading.
#
# TIERS (§0.2). The footer ("The CalRHT program is supported by ... a financial
# assistance award totaling $233,639,308.46 with 100 percent funded by
# CMS/HHS") is the ALLOTMENT, Tier 1, asserted through the shared parse. The
# $166.72M, $87.51M, $67.56M and $11.65M are initiative figures (Tier 2 context,
# text only). The $56.51M contract support and $10.41M HCAI programme support
# are not subawards and are not rows. The rows are Tier 3.
#
# TYPING (owner instruction, session 109: "Type every row on CMS CA enrolment;
# system parents LOW, GENERAL_KNOWLEDGE, subtractable"). In order:
#   1. A hand-read decision below (CA_HAND), each with its sentence.
#   2. EXACT: the string, or a half split at " - ", "/", ", " or "d.b.a.",
#      equals an ORGANIZATION NAME or DBA on CMS's CA Hospital, FQHC or RHC
#      Enrollment (data/evidence/federal_records/2026-10-28/, fetched this
#      session). MEDIUM. Where one legal entity enrols several hospitals, the
#      record whose DBA the string names is taken.
#   3. The classifier on the name, or §8's standing fallback.
#
# WHAT IS NOT A HOSPITAL ROW, AND WHY (each one-directional; see CA_HAND):
#   * "UC San Diego Health" ($498,854) and "Southern California Rural Health
#     Collaborative - University of California, San Diego" ($6,213,882): CMS
#     enrols UCSD's hospitals under REGENTS OF THE UNIVERSITY OF CALIFORNIA;
#     neither string names that legal entity, so §10.2's enrolled-operator row
#     does not reach them (an abbreviation or sub-unit named without the legal
#     entity). UNIVERSITY_OR_AHC, added to AHC_STRING_NAMES_NO_ENROLLED_ENTITY.
#   * Providence Medical Foundation ($450,000): a California medical foundation
#     (H&S Code §1206(l)), a clinic operator, not a fundraising arm. OTHER,
#     queued (CA_PROVIDENCE_MEDICAL_FOUNDATION).
#   * Inland Empire Health Plan ($2,472,952.56): a Medi-Cal managed care plan.
#     MANAGED_CARE_ORGANIZATION, LOW, GENERAL_KNOWLEDGE.
#
# §6.2: posted 2026-10-21, after California's NOA (budget period start
# 2025-12-29); CalRHT is RHTP in HCAI's own words (R/03ab's provenance test).
#
# Usage:
#   Rscript R/03cl_ca_bp1_recommended_awardees.R --validate | --build | --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

CA1_STATE     <- "CA"
CA1_NOA_DATE  <- as.Date("2025-12-29")
CA1_POSTED    <- as.Date("2026-10-21")
CA1_TOTAL     <- 138464043.97
CA1_N         <- 108L
CA1_URL  <- "https://hcai.ca.gov/rural-health/calrht/calrht-program-updates/"
CA1_FILE <- file.path("data", "evidence", "CA",
                      "2026-10-26_ca_hcai_calrht_program_updates_RECOMMENDED_SUBRECIPIENTS.html")
CA1_CSV  <- here::here("data", "reference", "ca_year1_awardees.csv")
CA1_TITLE <- paste0("HCAI, Recommended Subrecipients for CalRHT Budget Period 1 ",
                    "Announced (2026-10-21)")
CA1_FED_DIR <- file.path("data", "evidence", "federal_records", "2026-10-28")
CA1_FED <- c(HOSPITAL = "hosp", FQHC = "fqhc", RHC = "rhc")

# The five tables, in page order (the page's own headings).
CA1_POOLS <- tibble::tribble(
  ~table, ~pool, ~initiative, ~n, ~total,
  1L, "Accelerator Partner Program", "Transformative Care Model", 19L, 37606550.15,
  2L, "FM-OB Fellowship Program", "Transformative Care Model", 4L, 1729103.00,
  3L, "Transformative Payments", "Transformative Care Model", 11L, 34999996.00,
  4L, "Workforce Development Recruitment and Retention Program (WDRR)", "Workforce Development", 65L, 54169999.00,
  5L, "Electronic Health Record Modernization (EHR)", "Technology and Tools", 9L, 9958395.82)

# The page's prose figures, by initiative. TEXT ONLY: never a total (§0.4).
CA1_PROSE <- tibble::tribble(
  ~initiative, ~prose_amount, ~prose_grants, ~sentence,
  "Transformative Care Model", 87.51e6, 34L,
  "Approximately $87.51 million supporting 34 recommended grants, along with milestone-based hospital investments and clinical training partnerships",
  "Workforce Development", 67.56e6, 65L,
  "Approximately $67.56 million supporting 65 recommended grants",
  "Technology and Tools", 11.65e6, 9L,
  "Approximately $11.65 million supporting 9 recommended grants")
CA1_SENTENCES <- c(
  "distributing $166.72 million in California Rural Health Transformation Program funding for 108 organizations across 45 counties",
  "The awards listed on this page are tentative",
  "Inclusion on this list does not constitute a final grant award",
  "Funding amounts shown reflect the amounts offered to potential subrecipients and may differ from the final amounts disbursed",
  "does not yet represent all Budget Period 1 investments included in the initiative totals above",
  "One applicant that was recommended to receive an award has subsequently withdrawn their application",
  "Transformative Payments are investments in a select group of rural hospitals")

ca1_html <- function(path = here::here(CA1_FILE)) {
  raw <- readBin(path, "raw", file.size(path))
  xml2::read_html(rawToChar(raw[raw != as.raw(0)]))
}

ca1_text <- function(h = ca1_html()) {
  h <- xml2::read_html(as.character(h))
  xml2::xml_remove(xml2::xml_find_all(h, "//script|//style|//noscript"))
  t <- rvest::html_text2(h)
  t <- gsub("[   ]", " ", t)
  t <- gsub("[‘’]", "'", t)
  stringr::str_squish(t)
}

ca1_parse <- function(h = ca1_html()) {
  tb <- rvest::html_table(rvest::html_elements(h, "table"))
  hdr <- c("Awarded Entity", "Counties Served", "Recommended Funding")
  keep <- vapply(tb, function(t) identical(names(t), hdr), logical(1))
  if (sum(keep) != nrow(CA1_POOLS) || !all(keep)) {
    stop("[CA] the page carries ", length(tb), " tables, ", sum(keep), " of them roster ",
         "tables; five were read. Re-read it (§0.4).", call. = FALSE)
  }
  dplyr::bind_rows(lapply(seq_along(tb), function(i) {
    amt <- tb[[i]][[3]]
    if (any(!grepl("^\\$[0-9,]+(\\.[0-9]{1,2})?$", stringr::str_squish(amt)))) {
      stop("[CA] a Recommended Funding cell in table ", i, " is not a single dollar ",
           "figure; REFUSED, not dropped.", call. = FALSE)
    }
    tibble::tibble(table = i, row_in_pool = seq_len(nrow(tb[[i]])),
                   awardee = stringr::str_squish(tb[[i]][[1]]),
                   counties = stringr::str_squish(tb[[i]][[2]]),
                   amount = as.numeric(gsub("[^0-9.]", "", amt)))
  })) %>%
    dplyr::left_join(CA1_POOLS[, c("table", "pool", "initiative")], by = "table")
}

ca1_gap <- function(d = ca1_parse()) {
  d %>%
    dplyr::group_by(initiative) %>%
    dplyr::summarise(rows = dplyr::n(), printed = sum(amount), .groups = "drop") %>%
    dplyr::left_join(CA1_PROSE[, c("initiative", "prose_amount", "prose_grants")], by = "initiative") %>%
    dplyr::mutate(gap = prose_amount - printed)
}

ca1_assert_roster <- function(d = ca1_parse(), t = ca1_text()) {
  if (nrow(d) != CA1_N) stop("[CA] ", nrow(d), " rows, not 108.", call. = FALSE)
  if (abs(sum(d$amount) - CA1_TOTAL) > 0.005) {
    stop("[CA] the 108 rows sum to $", format(sum(d$amount), nsmall = 2, big.mark = ","),
         ", not $138,464,043.97.", call. = FALSE)
  }
  per <- d %>% dplyr::count(table, wt = NULL) %>% dplyr::pull(n)
  if (!identical(as.integer(per), CA1_POOLS$n)) {
    stop("[CA] per-table counts moved: ", paste(per, collapse = "/"), call. = FALSE)
  }
  sums <- tapply(d$amount, d$table, sum)
  if (any(abs(sums - CA1_POOLS$total) > 0.005)) {
    stop("[CA] a table's sum moved: ", paste(round(sums, 2), collapse = "/"), call. = FALSE)
  }
  for (p in c(CA1_SENTENCES, CA1_PROSE$sentence)) {
    if (!grepl(p, t, fixed = TRUE)) stop("[CA] the page no longer carries: ", p, call. = FALSE)
  }
  # The grant counts reconcile; the dollars do not, and are not made to.
  g <- ca1_gap(d)
  if (!identical(as.integer(g$rows), as.integer(g$prose_grants))) {
    stop("[CA] the per-initiative grant counts no longer reconcile to the prose.", call. = FALSE)
  }
  if (!all(g$gap > 0)) stop("[CA] a printed initiative now exceeds its prose figure: re-read.", call. = FALSE)
  # §0.2: the footer is the allotment.
  rhtp_assert_footer_text_tier(t, CA1_STATE, "STATE_ALLOTMENT", label = "CA updates page footer")
  if (!(CA1_POSTED > CA1_NOA_DATE)) stop("[CA] §6.2 date test.", call. = FALSE)
  invisible(TRUE)
}


# -- typing ---------------------------------------------------------------------

ca1_norm <- function(x) {
  x <- toupper(x)
  x <- gsub("['’]", "", x)
  x <- gsub("[.,/&()–-]", " ", x)
  x <- stringr::str_squish(gsub("[^A-Z0-9 ]", "", x))
  x <- sub("^THE ", "", x)
  sub(" (INC|INCORPORATED|LLC|PLLC|PC|PA|LP|LTD)$", "", x)
}
ca1_halves <- function(a) {
  unique(ca1_norm(c(a, strsplit(a, " d\\.?/?b\\.?/?a\\.? |/| DBA | – | - |, ", perl = TRUE)[[1]])))
}

ca1_federal <- function() {
  dplyr::bind_rows(lapply(names(CA1_FED), function(k) {
    j <- jsonlite::fromJSON(here::here(CA1_FED_DIR, sprintf("cms_%s_enrollments_CA.json", CA1_FED[[k]])))
    tibble::tibble(kind = k, ccn = as.character(j$CCN), org = j$`ORGANIZATION NAME`,
                   dba = j$`DOING BUSINESS AS NAME`, city = j$CITY,
                   ptype = j$`PROVIDER TYPE TEXT`)
  }))
}

CA1_PARENT_NOTE <- paste0(
  "SYSTEM PARENT, LOW, GENERAL_KNOWLEDGE (owner rulings: Vandalia, Sanford/Avera, ",
  "Guthrie, Ballad/Sentara/Valley, Memorial Health System): the parent system of ")
CA1_HAND <- tibble::tribble(
  ~awardee, ~recipient_type, ~basis_type, ~confidence, ~ccn, ~subtype, ~why,
  "Mee Memorial Healthcare System", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "051336", NA,
  paste0("HAND-READ BRIDGE: CMS CA Hospital Enrollment carries SOUTHERN MONTEREY COUNTY MEMORIAL ",
         "HOSPITAL dba GEORGE L. MEE MEMORIAL HOSPITAL (CAH 051336, King City); its RHCs trade as ",
         "'Mee Memorial'. The string is the district's trading name, not on the file. LOW."),
  "Salinas Valley Memorial Hospital", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050334", NA,
  paste0("HAND-READ BRIDGE: CMS CA Hospital Enrollment carries SALINAS VALLEY MEMORIAL HEALTHCARE ",
         "SYSTEM dba SALINAS VALLEY HEALTH MEDICAL CENTER (050334, Salinas); the string says ",
         "'Hospital' where the legal name says 'Healthcare System'. One enrolled hospital. LOW."),
  "Kaweah Health", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050057", NA,
  paste0("HAND-READ BRIDGE: 'Kaweah Health' is the trading name of KAWEAH DELTA HEALTH CARE ",
         "DISTRICT, which CMS enrols as KAWEAH HEALTH MEDICAL CENTER (050057, Visalia) and under ",
         "'Kaweah Health' DBAs for its clinics. LOW."),
  "Sierra Nevada Memorial Hospital Foundation", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "050150", NA,
  paste0("A NAMED HOSPITAL'S OWN FOUNDATION (§10.2's foundation row): the hospital it names is ",
         "SIERRA NEVADA MEMORIAL HOSPITAL, the DBA of SIERRA NEVADA MEMORIAL-MINERS HOSPITAL (050150, ",
         "Grass Valley). The foundation is not itself enrolled; the CCN is the parent hospital's. LOW."),
  "Jerod Phelps Community Hospital, Southern Humboldt Community Clinic", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "LOW", "051309", NA,
  paste0("HAND-READ BRIDGE: both facilities are one legal entity, SOUTHERN HUMBOLDT COMMUNITY ",
         "HEALTHCARE DISTRICT, enrolled as JEROLD PHELPS COMMUNITY HOSPITAL (CAH 051309, ",
         "Garberville) and SOUTHERN HUMBOLDT COMMUNITY CLINIC (RHC 553991). The page spells ",
         "'Jerod' for 'Jerold'. One recipient, a hospital operator, so not MULTI_RECIPIENT_FIELD. LOW."),
  "Good Samaritan Hospital, LP", "HOSPITAL_OR_SYSTEM", "ORG_WEBSITE", "MEDIUM", "050257", NA,
  paste0("EXACT DBA, CHOSEN BY COUNTY: two enrolled legal entities normalise to this string -- ",
         "GOOD SAMARITAN HOSPITAL, L.P. (050380, San Jose) and GOOD SAMARITAN HOSPITAL CA LTD PTP ",
         "dba 'GOOD SAMARITAN HOSPITAL, LP' (050257, Bakersfield, with an RHC in Wasco). The page's ",
         "string is the second entity's DBA LITERALLY, and its Counties Served is Kern, where that ",
         "entity sits. MEDIUM."),
  "Adventist Health System/West", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0(CA1_PARENT_NOTE, "the Adventist Health hospitals CMS enrols under their own legal names ",
         "(e.g. WILLITS HOSPITAL INC dba ADVENTIST HEALTH HOWARD MEMORIAL, 051310; UKIAH ADVENTIST ",
         "HOSPITAL, 050301), four of which are on this page's Transformative Payments table. Not ",
         "itself enrolled in CA under this string, so no CCN. Subtractable by basis_type."),
  "NorthBay Healthcare Corporation", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0(CA1_PARENT_NOTE, "NORTHBAY MEDICAL CENTER (050367, Fairfield), which CMS enrols under ",
         "another legal name; the corporation is not itself on the CA files, so no CCN. ",
         "Subtractable by basis_type."),
  "Banner Health Foundation", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0("A NAMED HEALTH SYSTEM'S OWN FOUNDATION (§10.2's foundation row; the parent is Banner ",
         "Health, a health system). The page's county is Lassen, where Banner operates BANNER LASSEN ",
         "MEDICAL CENTER (CAH 051320, Susanville). That the money reaches that hospital is not ",
         "stated, so no CCN; LOW, GENERAL_KNOWLEDGE, subtractable."),
  "UC San Diego Health", "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0("NOT BRIDGED (AHC_STRING_NAMES_NO_ENROLLED_ENTITY): CMS enrols UC San Diego's hospital under ",
         "REGENTS OF THE UNIVERSITY OF CALIFORNIA (050025, San Diego); the string is a trading name ",
         "and does not name that legal entity, so §10.2's enrolled-operator row does not reach it. ",
         "One-directional ($498,854)."),
  "Southern California Rural Health Collaborative – University of California, San Diego", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "MEDIUM", NA, NA,
  paste0("NOT BRIDGED (AHC_STRING_NAMES_NO_ENROLLED_ENTITY): the recipient half is 'University of ",
         "California, San Diego', a university; the collaborative is what it leads (§0.3a, the ",
         "awardee field's corollary). CMS enrols UCSD's hospital under REGENTS OF THE UNIVERSITY OF ",
         "CALIFORNIA (050025), which the string does not name. One-directional ($6,213,882)."),
  "Providence Medical Foundation", "OTHER", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0("DETERMINED FORM: a California MEDICAL FOUNDATION (Health and Safety Code §1206(l)), the ",
         "Providence-affiliated clinic organisation that contracts physicians; a care-delivery ",
         "entity, not a hospital's fundraising arm, so §10.2's foundation row does not reach it. Not ",
         "on the CA hospital, FQHC or RHC files. Queued (CA_PROVIDENCE_MEDICAL_FOUNDATION); ",
         "one-directional ($450,000)."),
  "Inland Empire Health Plan", "MANAGED_CARE_ORGANIZATION", "GENERAL_KNOWLEDGE", "LOW", NA, NA,
  paste0("DETERMINED FORM: a Medi-Cal managed care health plan (a public joint powers entity of San ",
         "Bernardino and Riverside counties). An MCO contracts hospitals; it is not one."),
  "Maternal Child Health Fellowship: Fresno Family Medicine Obstetrics", "NONPROFIT_CBO", NA, "LOW", NA, NA,
  paste0("THE STRING NAMES A FELLOWSHIP PROGRAMME, NOT AN ORGANISATION: the sponsoring institution ",
         "is not stated (§8's standing fallback, RECIPIENT_TYPE_INFERRED). Not a hospital row."),
  "Legacy MD Medical Group, Inc.", "PHYSICIAN_PRACTICE", "STATE_SOURCE", "MEDIUM", NA, NA,
  "A medical group: the form is in the string. Not on the CA FQHC or RHC files. Not a hospital.",
  "Shasta Cascade Health Centers", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, NA,
  paste0("HAND-READ BRIDGE: CMS CA FQHC Enrollment carries MCCLOUD HEALTHCARE CLINIC, INC. dba ",
         "SHASTA CASCADE HEALTH CENTERS- MT SHASTA (921872). An FQHC, not a hospital. LOW."),
  "CommuniCare+OLE", "FQHC_OR_RHC", "ORG_WEBSITE", "LOW", NA, NA,
  paste0("HAND-READ BRIDGE: CMS CA FQHC Enrollment carries OLE HEALTH dba OLE HEALTH ",
         "(COMMUNICARE+OLE TRAVIS) (A11028). An FQHC, not a hospital. LOW."))

ca1_type <- function(d = ca1_parse(), f = ca1_federal()) {
  cls <- rhtp_classify_recipient_type(d$awardee, CA1_STATE)
  kinds <- c(HOSPITAL = "HOSPITAL_OR_SYSTEM", FQHC = "FQHC_OR_RHC", RHC = "FQHC_OR_RHC")
  out <- lapply(seq_len(nrow(d)), function(i) {
    a <- d$awardee[i]
    hd <- CA1_HAND[CA1_HAND$awardee == a, ]
    if (nrow(hd)) {
      return(tibble::tibble(recipient_type = hd$recipient_type, basis_type = hd$basis_type,
                            determination_confidence = hd$confidence, typing = "HAND-READ",
                            why = hd$why, ccn = hd$ccn, subtype = hd$subtype))
    }
    h <- ca1_halves(a)
    hit <- f[ca1_norm(f$org) %in% h | ca1_norm(dplyr::coalesce(f$dba, "")) %in% h, ]
    if (nrow(hit)) {
      k <- names(kinds)[names(kinds) %in% hit$kind][1]
      hk <- hit[hit$kind == k, ]
      # A DBA that names one record of a multi-hospital entity: take that one.
      dba_hit <- hk[ca1_norm(dplyr::coalesce(hk$dba, "")) %in% h, ]
      if (k == "HOSPITAL" && nrow(dba_hit) && length(unique(dba_hit$org)) == 1L) hk <- dba_hit
      if (k == "HOSPITAL" && length(unique(hk$org)) > 1L) {
        stop("[CA] '", a, "' matches ", length(unique(hk$org)), " enrolled hospital legal ",
             "entities; a hand read must choose (§2).", call. = FALSE)
      }
      six <- sort(unique(hk$ccn[grepl("^[0-9]{6}$", hk$ccn)]))
      rec <- paste0(paste(unique(hk$org), collapse = "; "),
                    if (any(nzchar(dplyr::coalesce(hk$dba, ""))))
                      paste0(" dba ", paste(unique(hk$dba[nzchar(dplyr::coalesce(hk$dba, ""))]), collapse = " / ")) else "",
                    " (", paste(sort(unique(hk$ccn)), collapse = "/"), ")")
      return(tibble::tibble(
        recipient_type = kinds[[k]], basis_type = "ORG_WEBSITE", determination_confidence = "MEDIUM",
        typing = "EXACT",
        why = paste0("EXACT federal record: CMS CA ", k, " Enrollment carries this string (or ",
                     "its recipient half) as an ORGANIZATION NAME or DBA: ", rec,
                     if (k == "HOSPITAL") paste0(", ", unique(hk$ptype)[1]) else "", "."),
        ccn = if (k == "HOSPITAL" && length(six) == 1L) six else NA_character_, subtype = NA_character_))
    }
    if (cls$recipient_type[i] == "HOSPITAL_OR_SYSTEM") {
      stop("[CA] the classifier calls '", a, "' a hospital and no federal record or ",
           "hand-read decision covers it. Read it.", call. = FALSE)
    }
    fb <- cls$rule[i] == "FALLBACK"
    tibble::tibble(
      recipient_type = cls$recipient_type[i],
      basis_type = if (fb) NA_character_ else "STATE_SOURCE",
      determination_confidence = if (fb) "LOW" else rhtp_confidence_ceiling(cls$determination_confidence[i]),
      typing = if (fb) "FALLBACK" else "CLASSIFIER",
      why = if (fb) "HCAI states no form and no CMS CA enrolment carries the string (§8's standing fallback, RECIPIENT_TYPE_INFERRED)."
            else paste0("No CMS CA enrolment carries the string; the form is read from the string itself (",
                        cls$recipient_type_basis[i], ")."),
      ccn = NA_character_, subtype = NA_character_)
  })
  t <- dplyr::bind_rows(out)
  t$classifier <- paste0(cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence))
  t
}

ca1_awardees <- function(d = ca1_parse(), f = ca1_federal()) {
  t <- ca1_type(d, f)
  hosp <- t$recipient_type == "HOSPITAL_OR_SYSTEM"
  inferred <- t$typing == "FALLBACK" |
    (t$typing == "HAND-READ" & is.na(t$basis_type))
  tibble::tibble(
    state = CA1_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = t$recipient_type,
    distributed_to_hospital = ifelse(hosp, "Yes", "No"),
    note = paste0(d$pool, " [", d$counties, "]"),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = CA1_TITLE,
    state_source_url = CA1_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cl_ca_bp1_recommended_awardees.R",
    ccn = t$ccn,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_subtype = t$subtype,
    cms_enrolment_match = NA_character_,
    county = d$counties,
    initiative = d$initiative,
    award_pool = d$pool,
    row_in_pool = d$row_in_pool,
    awardee_as_published = d$awardee,
    recipient_type_source = paste0("TYPED (session 109, ", t$typing, "): ", t$why,
                                   " Classifier said ", t$classifier, "."),
    determination_confidence = rhtp_confidence_ceiling(t$determination_confidence, t$ccn),
    flag_reason = ifelse(inferred, "AMOUNT_PRELIMINARY;RECIPIENT_TYPE_INFERRED", "AMOUNT_PRELIMINARY"),
    budget_period = "Budget Period 1",
    flow_type = ifelse(hosp, "DIRECT", "NON_HOSPITAL"),
    hospital_benefiting = ifelse(hosp, "Yes", "Unclear"),
    hospital_attribution = ifelse(hosp, "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 ", ifelse(hosp, "DIRECT", "NON_HOSPITAL"), ": ", t$why,
                                 ifelse(hosp, " §0.3a: the recipient is a hospital or health system whatever the activity.", ""),
                                 " AN INTENT, not an award: 'The awards listed on this page are tentative'."),
    amount_basis = paste0("EXACT as printed, per recipient, but PRELIMINARY: 'amounts offered to potential ",
                          "subrecipients and may differ from the final amounts disbursed'. The 108 rows sum to ",
                          "$138,464,043.97; HCAI's prose '$166.72 million' is NOT reconciled to them (~$28.26M ",
                          "gap, recorded, never used as a total). The footer ($233,639,308.46) is the ALLOTMENT, ",
                          "Tier 1 (§0.2)."),
    round_amount = CA1_POOLS$total[match(d$table, CA1_POOLS$table)],
    announcement_date = CA1_POSTED,
    source_archive_path = CA1_FILE,
    basis_type = t$basis_type)
}

ca1_assert_typing <- function(a = ca1_awardees()) {
  tp <- a[a$award_pool == "Transformative Payments", ]
  if (any(tp$distributed_to_hospital != "Yes")) {
    stop("[CA] a Transformative Payments row is not a hospital row: ",
         paste(tp$awardee[tp$distributed_to_hospital != "Yes"], collapse = "; "), call. = FALSE)
  }
  h <- a[a$distributed_to_hospital == "Yes", ]
  if (any(h$recipient_type != "HOSPITAL_OR_SYSTEM") || any(h$flow_type != "DIRECT")) {
    stop("[CA] a Yes row is not a DIRECT hospital row.", call. = FALSE)
  }
  unused <- setdiff(CA1_HAND$awardee, a$awardee)
  if (length(unused)) stop("[CA] hand reads match no row: ", paste(unused, collapse = "; "), call. = FALSE)
  rhtp_assert_high_has_ccn(a, "CA")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "recipient_subtype",
                "determination_confidence", "hospital_attribution", "basis_type")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[CA] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (length(setdiff(a$validation_source_type, rhtp_vocabulary("source_doc_type")))) {
    stop("[CA] validation_source_type outside §8's source_doc_type.", call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[CA] flag_reason outside §8.", call. = FALSE)
  if (any(a$recipient_type == "OTHER" & !grepl("DETERMINED FORM", a$determination_basis))) {
    stop("[CA] an OTHER row does not state its determined form.", call. = FALSE)
  }
  invisible(TRUE)
}

ca1_validate <- function() {
  h <- ca1_html()
  d <- ca1_parse(h)
  ca1_assert_roster(d, ca1_text(h))
  a <- ca1_awardees(d)
  ca1_assert_typing(a)
  message("[CA] all assertions pass.")
  invisible(a)
}

ca1_build <- function() {
  a <- ca1_validate()
  readr::write_csv(a, CA1_CSV, na = "NA")
  h <- a[a$distributed_to_hospital == "Yes", ]
  message(sprintf("[CA] wrote %d intents, $%s; %d NAMED_HOSPITAL rows, $%s.",
                  nrow(a), formatC(sum(a$amount), format = "f", digits = 2, big.mark = ","),
                  nrow(h), formatC(sum(h$amount), format = "f", digits = 2, big.mark = ",")))
}

ca1_report <- function(a = ca1_awardees()) {
  m <- function(x) paste0("$", formatC(sum(x), format = "f", digits = 2, big.mark = ","))
  h <- a[a$distributed_to_hospital == "Yes", ]
  cat(sprintf("%d intents, %s. NAMED_HOSPITAL %d / %s; LOW %d / %s; GENERAL_KNOWLEDGE %s.\n",
              nrow(a), m(a$amount), nrow(h), m(h$amount), sum(h$determination_confidence == "LOW"),
              m(h$amount[h$determination_confidence == "LOW"]),
              m(h$amount[h$basis_type %in% "GENERAL_KNOWLEDGE"])))
  print(a %>% dplyr::group_by(award_pool) %>%
          dplyr::summarise(rows = dplyr::n(), dollars = sum(amount),
                           hosp_rows = sum(distributed_to_hospital == "Yes"),
                           hosp_dollars = sum(amount[distributed_to_hospital == "Yes"])))
  print(ca1_gap())
  print(a %>% dplyr::select(awardee, amount, recipient_type, determination_confidence, ccn), n = 108)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) ca1_validate()
  if ("--build" %in% args) ca1_build()
  if ("--report" %in% args) ca1_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}

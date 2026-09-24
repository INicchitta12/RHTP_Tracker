#!/usr/bin/env Rscript
# 03be_va_year1_awardees.R ---------------------------------------------------
#
# VIRGINIA -- THE FIRST-TIER LIST, EXTRACTED (session 60). ELEVEN NAMED
# IMPLEMENTATION PARTNERS, `amount` EMPTY ON EVERY ROW, AND NO HOSPITAL.
#
# The Governor's release of 2026-08-28, "Virginia Invests $122 Million in
# Rural Health", archived by session 55:
#
#   "This initial investment of $122 million is the first step in a
#    multi-pronged process, with funding going to key partners that will then
#    issue smaller, competitive grants ... The Commonwealth of Virginia is
#    working with the following partners to issue grants to community-based
#    organizations:" -- and eleven bullets.
#
# Nevada's and Delaware's shape: a named first tier, NO per-partner figure.
# "More than $122 million" is a round-level figure across all eleven and is
# NOT put in `round_amount` (it would repeat on eleven rows -- Georgia's trap --
# and "more than" is not a total). It lives in va_year1_status.csv, with the
# RFA Navigator's one Tier 2 pool figure (RPM, "Total year 1 funding available
# $14.3M").
#
# THE HOSPITAL-ASSOCIATION FOUNDATION IS THE ROW TO READ. The shared
# classifier types "Virginia Hospital Research and Education Foundation (d/b/a
# VHHA Foundation)" HOSPITAL_OR_SYSTEM/HIGH on the word "Hospital", and the
# flow classifier reads its own page's sentence ("will administer grant
# funding to help rural hospitals and providers") as PASS_THROUGH_DESIGNATED /
# Yes. Both are overridden. It is an ASSOCIATION's foundation (§10.2 -- New
# Hampshire's FHC, not a hospital's own foundation), and its eligible class is
# hospitals AMONG OTHERS: the RPM opportunity "May include participation from
# health systems, hospitals, free clinics, Federally Qualified Health Centers,
# Rural Health Clinics, independent rural providers, and federally recognized
# Tribes", and Food is Medicine is a community programme. §0.3: Unclear. The
# one hospitals-only piece is GME ("Target Audience: Health systems", "47
# awardees for residency slots"), which has named nobody. With no amount the
# row is $0 either way; the coding decides the day an amount appears.
#
# EVERY OTHER PARTNER IS EITHER NON_HOSPITAL ON ITS STATED CLASS OR UNCLEAR ON
# A CLASS THAT INCLUDES HOSPITALS AMONG OTHERS, taken from the RFA Navigator's
# target-audience table (the source, not the classifier).
#
# ONE DISAGREEMENT BETWEEN TWO STATE DOCUMENTS, RECORDED NOT RESOLVED: the
# release names the NORTHERN SHENANDOAH VALLEY REGIONAL COMMISSION for "mobile
# and hybrid care ... in the Shenandoah Valley"; the RHT site's Ways to Apply
# table gives Mobile & Hybrid Care's Key Implementation Partner as
# "Commonwealth of VA".
#
# §0.2: the release's CMS footer prints $189,544,888.14, the ALLOTMENT.
# R/03bb still watches VHCF's and the VHHA Foundation's award dates (9/30,
# 10/14, 10/30); this file holds the first tier.
#
# Usage: Rscript R/03be_va_year1_awardees.R --validate | --build | --report

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

VAA_STATE <- "VA"
VAA_DIR <- file.path("data", "evidence", "recheck", "2026-09-23", "VA")
VAA_RELEASE <- file.path(VAA_DIR, "gov_release_2026-08-28_122M.pdf")
VAA_NAVIGATOR <- file.path(VAA_DIR, "rht_rfa_navigator.pdf")
VAA_WAYS <- file.path(VAA_DIR, "rhtva_ways_to_apply.html")
VAA_VHHA <- file.path(VAA_DIR, "vhha_foundation_rht.html")
VAA_RELEASE_URL <- paste0("https://www.ruralhealthtransformationva.virginia.gov/",
                          "news-updates/")
VAA_RELEASE_DATE <- as.Date("2026-08-28")
VAA_NOA_DATE <- as.Date("2025-12-29")
VAA_AWARD_CSV <- file.path("data", "reference", "va_year1_awardees.csv")
VAA_STATUS_CSV <- file.path("data", "reference", "va_year1_status.csv")

vaa_squish <- function(x) {
  x <- stringr::str_replace_all(x, "[‘’]", "'")
  x <- stringr::str_replace_all(x, "–|—", "-")
  stringr::str_squish(x)
}
vaa_pdf <- function(p) vaa_squish(paste(rhtp_pdf_text(here::here(p)), collapse = " "))
vaa_html <- function(p) {
  t <- paste(readLines(here::here(p), warn = FALSE, encoding = "UTF-8"), collapse = " ")
  t <- stringr::str_remove_all(t, stringr::regex(
    "<(script|style|noscript)[^>]*>.*?</\\1>", dotall = TRUE, ignore_case = TRUE))
  t <- stringr::str_replace_all(t, "<[^>]+>", " ")
  t <- stringr::str_replace_all(t, "&nbsp;|&#160;", " ")
  t <- stringr::str_replace_all(t, "&amp;", "&")
  vaa_squish(t)
}

# `bullet` is the release's own opening words for the partner, asserted present.
VAA_ROWS <- tibble::tribble(
  ~awardee, ~bullet, ~sub_initiatives, ~recipient_type, ~flow_type, ~dist,
  ~benefit, ~flags, ~why, ~basis_type,
  "Virginia Hospital Research and Education Foundation (d/b/a VHHA Foundation)",
  "VA Hospital and Healthcare Association Foundation to support local organizations",
  "Remote Patient Monitoring; Attract and Retain Physicians (GME); Food is Medicine",
  "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT",
  paste("The state hospital ASSOCIATION's foundation ('The Virginia Hospital",
        "Research and Education Foundation (d/b/a VHHA Foundation) is proud to",
        "serve as a subrecipient partner'). Not a hospital: the classifier's",
        "HOSPITAL_OR_SYSTEM/HIGH on the name is overridden. Eligible class is",
        "hospitals AMONG OTHERS (RPM 'May include participation from health",
        "systems, hospitals, free clinics, Federally Qualified Health Centers,",
        "Rural Health Clinics ...'); §0.3, New Hampshire's FHC, not Illinois's",
        "ICAHN. The flow classifier's PASS_THROUGH_DESIGNATED/Yes is overridden."),
  "STATE_SOURCE",
  "Virginia Health Care Foundation",
  "VA Healthcare Foundation to support organizations advancing rural provider productivity and interoperability",
  "Provider Productivity Fund; Provider Interoperability Fund",
  "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT;RECIPIENT_TYPE_INFERRED",
  paste("Navigator target audience: 'independent practices, federally",
        "recognized Tribes, free clinics, FQHCs, RHCs, and hospitals/health",
        "systems' -- hospitals among others (§0.3)."),
  "STATE_SOURCE",
  "Virginia Foundation for Community College Education",
  "VA Foundation for Community College Education to grow the health workforce",
  "Allied Health Degrees",
  "NONPROFIT_CBO", "NON_HOSPITAL", "No", "No", "RECIPIENT_TYPE_INFERRED",
  paste("A foundation, not a college: the classifier's UNIVERSITY_OR_AHC on",
        "'College' is overridden to the §8 fallback. Navigator places Allied",
        "Health Degrees under 'Educational Institutions' only."),
  "STATE_SOURCE",
  "Virginia Innovation Partnership Corporation",
  "VA Innovation Partnership Corporation to establish a technology innovation fund",
  "Tech Innovation Fund",
  "NONPROFIT_CBO", "NON_HOSPITAL", "No", "No", "RECIPIENT_TYPE_INFERRED",
  paste("Navigator: 'Virginia-based companies or companies operating in or",
        "providing direct services to rural Virginia communities' -- health",
        "technology companies. Form not stated."),
  "STATE_SOURCE",
  "Virginia Works",
  "VA Works to expand Earn to Learn programs",
  "Earn to Learn",
  "STATE_AGENCY", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT",
  paste("Virginia's state workforce agency (general knowledge; the release",
        "does not state the form). Navigator lists Earn to Learn for health",
        "systems and hospitals, RHCs/FQHCs and educational institutions --",
        "hospitals among others."),
  "GENERAL_KNOWLEDGE",
  "Virginia Department of Education",
  "VA Department of Education to create a workforce pipeline",
  "Build Career Pipelines",
  "STATE_AGENCY", "NON_HOSPITAL", "No", "No", "",
  paste("A state department by name; the classifier's SCHOOL_OR_DISTRICT is",
        "overridden. Navigator: Educational Institutions only."),
  "STATE_SOURCE",
  "Virginia Department of Health",
  "VA Department of Health to invest in maternal care and community paramedicine",
  "Community Paramedicine; Innovative Maternal Care",
  "STATE_AGENCY", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT",
  paste("Navigator lists both sub-initiatives for health systems and",
        "hospitals among RHCs, FQHCs, CBOs, technology companies and local",
        "government (§0.3)."),
  "STATE_SOURCE",
  "Virginia Foundation for Healthy Youth",
  "VA Foundation for Healthy Youth to support organizations promoting active kids and consumer tech",
  "Active Kids; Consumer Technology",
  "NONPROFIT_CBO", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT;RECIPIENT_TYPE_INFERRED",
  paste("Consumer Technology is listed for health systems and hospitals among",
        "others (§0.3); Active Kids for schools and CBOs. Form not stated."),
  "STATE_SOURCE",
  "Virginia Department for Aging and Rehabilitative Services",
  "VA Department for Aging and Rehabilitative Services to better integrate care",
  "Integrated Care for Duals",
  "STATE_AGENCY", "NON_HOSPITAL", "No", "No", "",
  paste("A state department by name. Navigator: CBOs and non-profits, local",
        "government agencies -- no hospital."),
  "STATE_SOURCE",
  "Northern Shenandoah Valley Regional Commission",
  "Northern Shenandoah Valley Regional Commission to invest in organizations advancing",
  "Mobile and Hybrid Care",
  "LOCAL_GOVT_OR_PUBLIC_HEALTH", "PASS_THROUGH_UNRESOLVED", "Unclear", "Unclear",
  "ELIGIBILITY_NOT_RECEIPT",
  paste("A regional planning commission (local government). Navigator lists",
        "Mobile and Hybrid Care for every audience including health systems",
        "and hospitals (§0.3). NB the Ways to Apply table names the KIP",
        "'Commonwealth of VA', not this commission -- recorded, not resolved."),
  "GENERAL_KNOWLEDGE",
  "Virginia Center for Health Innovation",
  "VA Center for Health Innovation to evaluate and monitor the program",
  "Program evaluation",
  "VENDOR_OR_CONTRACTOR", "NON_HOSPITAL", "No", "No", "",
  paste("The release: 'to evaluate and monitor the program' -- a service to",
        "the state (§8 VENDOR_OR_CONTRACTOR), not a re-granter."),
  "STATE_SOURCE"
)

VAA_STATUS <- tibble::tribble(
  ~item, ~figure_in_source, ~stage, ~note,
  "Round total across the eleven partners", 122000000, "ANNOUNCED_NO_SPLIT",
  "'more than $122 million' -- a lower bound across eleven partners; no per-partner figure anywhere.",
  "Remote Patient Monitoring (VHHA Foundation)", 14300000, "RFA_CLOSED_NO_AWARDS",
  "Navigator: 'Total year 1 funding available $14.3M. 2-3 awards estimated.' Target: health systems. TIER 2.",
  "Attract and Retain Physicians (VHHA Foundation)", NA_real_, "RFA_CLOSED_NO_AWARDS",
  "Navigator: 'Target Audience: Health systems', '47 awardees for residency slots'. HOSPITALS ONLY, nobody named.",
  "Provider Interoperability (VHCF)", NA_real_, "RFA_CLOSED_AWARD_DATE_PUBLISHED",
  "Closed 2026-08-31; R/03bb watches VHCF's Notice of Awards date (by 2026-09-30).",
  "Tech Innovation Fund (VIPC)", NA_real_, "NOT_YET_OPEN",
  "Navigator: 'Award range: $250,000-$999,999', '15-20 subrecipients'. TIER 2."
)

vaa_assert_sources <- function(release = vaa_pdf(VAA_RELEASE),
                               navigator = vaa_pdf(VAA_NAVIGATOR),
                               ways = vaa_html(VAA_WAYS),
                               vhha = vaa_html(VAA_VHHA)) {
  want <- c(VAA_ROWS$bullet,
            "The Commonwealth of Virginia is working with the following partners to issue grants",
            "This initial investment of $122 million is the first step")
  miss <- want[!vapply(want, function(w) grepl(w, release, fixed = TRUE), TRUE)]
  if (length(miss)) stop("[VA] the release no longer says: ",
                         paste(sQuote(miss), collapse = "; "), call. = FALSE)
  # Exactly eleven bullets: a twelfth partner means the file is short.
  n <- stringr::str_count(release, stringr::fixed("•"))
  if (n != 11L) stop("[VA] the release has ", n, " bullets, not 11.", call. = FALSE)
  # No per-partner amount: the release's only currency figures are the $122M,
  # the $189M and the footer's allotment.
  figs <- unique(tolower(stringr::str_extract_all(
    release, stringr::regex("\\$[0-9][0-9,.]*( million)?", ignore_case = TRUE))[[1]]))
  extra <- setdiff(figs, c("$122 million", "$189 million", "$189,544,888.14"))
  if (length(extra)) stop("[VA] the release now carries a figure this file ",
                          "does not: ", paste(extra, collapse = ", "),
                          ". A per-partner amount means REWRITE, not patch.",
                          call. = FALSE)
  if (!grepl("May include participation from health systems, hospitals, free clinics",
             vhha, fixed = TRUE)) {
    stop("[VA] VHHA Foundation's mixed eligible class is no longer stated; the ",
         "Unclear coding rests on it.", call. = FALSE)
  }
  if (!grepl("Total year 1 funding available $14.3M", navigator, fixed = TRUE)) {
    stop("[VA] navigator's RPM pool sentence moved.", call. = FALSE)
  }
  if (!grepl("Mobile & Hybrid Care Commonwealth of VA", ways, fixed = TRUE)) {
    stop("[VA] Ways to Apply no longer names 'Commonwealth of VA' for Mobile & ",
         "Hybrid Care; revisit the NSVRC note.", call. = FALSE)
  }
  rhtp_assert_footer_text_tier(release, VAA_STATE, "STATE_ALLOTMENT",
                               label = "VA Governor release footer")
  if (VAA_RELEASE_DATE <= VAA_NOA_DATE) stop("[VA] date test.", call. = FALSE)
  invisible(TRUE)
}

va_year1_awardees <- function() {
  a <- VAA_ROWS
  cls <- rhtp_classify_recipient_type(a$awardee, VAA_STATE)
  tibble::tibble(
    state = VAA_STATE,
    row_no = seq_len(nrow(a)),
    awardee = a$awardee,
    amount = NA_real_,
    recipient_type = a$recipient_type,
    distributed_to_hospital = a$dist,
    note = paste0("Key implementation partner named in the Governor's ",
                  "2026-08-28 release; no per-partner amount published."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "Virginia Invests $122 Million in Rural Health (Governor's release, 2026-08-28)",
    state_source_url = VAA_RELEASE_URL,
    validation_source_type = "GOVERNOR_PRESS_RELEASE",
    extraction_method = "PDF_TEXT",
    validator = "R/03be_va_year1_awardees.R",
    ccn = NA_character_, aha_id = NA_character_,
    rural_designation = NA_character_, reviewer = NA_character_,
    initiative = a$sub_initiatives,
    recipient_type_source = paste0("TYPED (session 60): ", a$why,
                                   " Classifier said ", cls$recipient_type,
                                   "/", cls$determination_confidence, "."),
    determination_confidence = ifelse(a$basis_type == "GENERAL_KNOWLEDGE" |
                                        grepl("RECIPIENT_TYPE_INFERRED", a$flags),
                                      "LOW", "MEDIUM"),
    flag_reason = ifelse(nzchar(a$flags), a$flags, NA_character_),
    award_pool = a$sub_initiatives,
    budget_period = "Budget Period 1",
    flow_type = a$flow_type,
    hospital_benefiting = a$benefit,
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = ifelse(a$flow_type == "PASS_THROUGH_UNRESOLVED",
                               a$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", a$flow_type, ": ", a$why),
    amount_basis = "NO PER-PARTNER FIGURE PUBLISHED; the release's 'more than $122 million' is a round-level lower bound and is in va_year1_status.csv.",
    basis_type = a$basis_type,
    round_amount = NA_real_,
    announcement_date = VAA_RELEASE_DATE,
    source_archive_path = VAA_RELEASE
  )
}

va_year1_status <- function() {
  VAA_STATUS %>% mutate(state = VAA_STATE, as_of = "2026-09-23") %>%
    select(state, everything())
}

va_validate <- function() {
  vaa_assert_sources()
  d <- va_year1_awardees()
  stopifnot(nrow(d) == 11L, all(is.na(d$amount)),
            !any(d$distributed_to_hospital == "Yes"),
            !"amount" %in% names(va_year1_status()))
  message("[VA] all assertions pass.")
  invisible(TRUE)
}

va_build <- function() {
  va_validate()
  readr::write_csv(va_year1_awardees(), here::here(VAA_AWARD_CSV), na = "")
  readr::write_csv(va_year1_status(), here::here(VAA_STATUS_CSV), na = "")
  message("[VA] wrote 11 award rows and ", nrow(VAA_STATUS), " status rows.")
}

va_report <- function() {
  d <- va_year1_awardees()
  print(as.data.frame(d[, c("awardee", "recipient_type", "flow_type",
                            "distributed_to_hospital")]), row.names = FALSE)
}

if (!interactive() && identical(sys.nframe(), 0L)) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) va_validate()
  if ("--build" %in% args) va_build()
  if ("--report" %in% args) va_report()
  if (!length(args)) message("Usage: --validate | --build | --report")
}

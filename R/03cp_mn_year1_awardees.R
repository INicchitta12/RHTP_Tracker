#!/usr/bin/env Rscript
# 03cp_mn_year1_awardees.R ------------------------------------------------------
#
# MINNESOTA -- MDH'S "RHTP SUB-RECIPIENT AWARDEES" (session 112). Found by
# R/03bn's watch, which logged a TRIPWIRE on 2026-10-30 on the grants page
# (https://www.health.state.mn.us/facilities/ruralhealth/ruraltrans/grants.html,
# "Last Updated: 10/27/2026"). The page now says, under "Grants & Contracts
# Resources":
#
#   "The Minnesota Department of Health has awarded $12.5 million in Rural
#    Health Transformation Program funding to the following sole-source and
#    competitive grant program recipients. Grants made to rural Critical
#    Access Hospitals, Federally Qualified Health Centers, Tribal Nations,
#    Certified Community Behavioral Health Centers and Community Mental Health
#    Centers through direct allocation grant will be announced in the coming
#    days."
#
# and links NINE one-page PDFs under "RHTP Sub-Recipient Awardees", each
# headed "Rural Health Transformation Program Funding", a programme title, and
# an Organization | City | Amount | Purpose table, dated 09/17/2026 and carrying
# the CMS footer. ELEVEN PRICED LINES, TEN ORGANISATIONS, $12,453,451:
#
#   * Two PDFs carry more than one line. 'Project ECHO for Maternal and
#     Behavioral Health' prices TWO organisations (Minnesota Perinatal
#     Organization $165,000; Minnesota Medical Association $165,007), and
#     'Rural Ambulance Treatment in Place' prices TWO COMPONENTS of one award
#     to the Minnesota Office of EMS ("$281,000: OEMS Staff Time"; "$9,218,109:
#     Grant Funds to EMS Agencies"). Each is its own row, as printed; the PDF
#     prints no total for OEMS and none is made here.
#   * THE ELEVEN RECONCILE TO MDH'S "$12.5 million": $12,453,451 rounds to it.
#     The nine first lines alone (one per PDF, leaving out MMA and OEMS's
#     grant-funds line) are $3,070,335 -- that figure is NOT the page's and is
#     not the file's; it is what a reader gets by taking one line per PDF.
#
# WHAT THE ROWS ARE: AWARDS. "has awarded" is the agency's own past tense, and
# each PDF names the recipient and the amount, so validation_source_type =
# NOTICE_OF_AWARD and amount_confirmed = Yes on every row (the agency-roster
# footing of Idaho's DHW list and Oklahoma's Funding Recipients roster). The
# PDFs are award SUMMARIES, not signed agreements: say so if the distinction is
# ever load-bearing.
#
# §0.2: the PDFs' footer ("financial assistance award totaling $193,090,618.14
# with 100 percent funded by CMS/HHS") is Minnesota's ALLOTMENT (anchor
# $193,090,618, to the cent of rounding), Tier 1, asserted by machine below.
# It is in no numeric column.
#
# NOT YEAR 1 COMPLETE. The page says the direct-allocation grants -- the 70%
# hospital share of the allotment, 94 eligible hospitals (§0.3: ELIGIBLE,
# never awarded until named) -- "will be announced in the coming days". This
# file holds NO hospital row and NO hospital dollar; Minnesota's hospital
# money is that announcement, which R/03bn watches.
#
# TYPING (hand-read, every row in MN_AWARDS with its sentence; none is
# hospital-shaped, so no CMS MN enrolment file was needed):
#   * STATE AGENCIES: Minnesota Office of EMS (both lines), Minnesota
#     Management and Budget -- STATE_AGENCY, NON_HOSPITAL. OEMS's $9,218,109 is
#     a pool it will "provide ... to rural ambulance services that opt into the
#     project": second-tier recipients unnamed (Utah's fiscal-agent footing,
#     R/03cn). NOTE the Idaho/Vermont precedent (owner, session 54): inter-agency
#     MOA/MOU lines are kept OUT of an award file. MDH labels these two
#     "Sub-Recipient Awardees", not memoranda, so they are in; if the owner
#     applies that rule, $9,775,054 leaves the file.
#   * VENDORS (the PDF says they supply MDH): Technology Management Corporation
#     ("technical advisory services to MDH"), Freya + Co (facilitating MDH's
#     MOUD council), AscendRural/Sourcewell (a framework "for Minnesota
#     Department of Health").
#   * NONPROFITS / ASSOCIATIONS: Stratis Health, Minnesota Perinatal
#     Organization, Minnesota Medical Association -- the PDFs state no form:
#     §8's standing fallback (RECIPIENT_TYPE_INFERRED), LOW.
#   * TWO UNCLEAR ROWS, §0.3: Minnesota Community Health Worker Alliance and
#     HealthForce MN each pass grant funds to "rural health care employers such
#     as clinics, hospitals, Tribal health ..." -- hospitals AMONG the eligible,
#     none named: PASS_THROUGH_UNRESOLVED, Unclear, no bucket (Utah's UHIN).
#
# Usage:
#   Rscript R/03cp_mn_year1_awardees.R --fetch      archive page + 9 PDFs (writes data/evidence/MN/)
#   Rscript R/03cp_mn_year1_awardees.R --validate   assertions against the ARCHIVE, offline
#   Rscript R/03cp_mn_year1_awardees.R --build      write mn_year1_awardees.csv
#   Rscript R/03cp_mn_year1_awardees.R --report

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(tibble); library(readr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

MNA_STATE <- "MN"
MNA_AGENT <- paste0("Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; ",
                    "+https://www.aha.org)")
MNA_DIR   <- file.path("data", "evidence", "MN")
MNA_FETCH_DATE <- "2026-11-02"
MNA_PAGE_URL <- "https://www.health.state.mn.us/facilities/ruralhealth/ruraltrans/grants.html"
MNA_PAGE  <- file.path(MNA_DIR, "2026-11-02_mdh_rhtp_grants.html")
MNA_PDF_BASE <- "https://www.health.state.mn.us/facilities/ruralhealth/ruraltrans/docs/awardees/"
MNA_OUT   <- "data/reference/mn_year1_awardees.csv"
MNA_DOC_DATE <- as.Date("2026-09-17")
MNA_TOTAL <- 12453451.00
MNA_ROWS  <- 11L
MNA_ONE_PER_PDF_TOTAL <- 3070335.00
MNA_FOOTER <- 193090618.14

MNA_AWARDED_SENTENCE <- paste0("The Minnesota Department of Health has awarded $12.5 million in Rural ",
                               "Health Transformation Program funding to the following sole-source and ",
                               "competitive grant program recipients.")
MNA_COMING_SENTENCE <- paste0("through direct allocation grant will be announced in the coming days")

mna_pdf_path <- function(key) file.path(MNA_DIR, paste0(MNA_FETCH_DATE, "_mdh_rhtp_awardee_", key, ".pdf"))

# The nine PDFs: key = the file's own name on MDH's server; link = the page's
# link text; heading = the programme title printed in the PDF (squished).
MNA_PDFS <- tibble::tribble(
  ~key,      ~link,                                                                       ~heading,
  "stratis", "Technical Assistance for Healthcare Providers on Health Information Technology", "TECHNICAL ASSISTANCE FOR HEALTHCARE PROVIDERS ON HEALTH INFORMATION TECHNOLOGY",
  "mnems",   "Rural Ambulance Treatment in Place",                                          "RURAL AMBULANCE TREATMENT IN PLACE",
  "chwa",    "Earn and Train Pathways",                                                     "EARN & TRAIN PATHWAYS",
  "tmc",     "Health Information Technology Advisory Services",                             "HEALTH INFORMATION TECHNOLOGY ADVISORY SERVICES",
  "ars",     "Identifying Performance Measures for RHTP Information Technology Investments", "IDENTIFYING PERFORMANCE MEASURES FOR RHTP INFORMATION TECHNOLOGY INVESTMENTS",
  "freya",   "Medication for Opioid Use Disorder Education Development Council",            "MEDICATION FOR OPIOID USE DISORDER EDUCATION DEVELOPMENT COUNCIL",
  "perimed", "Project Echo for Maternal and Behavioral Health",                             "PROJECT ECHO FOR MATERNAL AND BEHAVIORAL HEALTH",
  "hfmn",    "K-12 Healthcare Career Exposure and Earn & Train Pathways",                   "K-12 HEALTHCARE CAREER EXPOSURE AND EARN & TRAIN PATHWAYS",
  "mmb",     "RHTP Evaluation",                                                             "RHTP EVALUATION")

MNA_STATE_AGENCY <- paste0(
  "A STATE AGENCY (the form is in the string). The recipient is the agency; any second-tier recipient ",
  "of its funds is unnamed and would be a row for that agency's own roster, never this one (Utah's ",
  "fiscal-agent footing, R/03cn). Inter-agency: if the owner applies the Idaho/Vermont MOA/MOU rule ",
  "(session 54), this row leaves the file; MDH lists it as a 'Sub-Recipient Awardee', not a memorandum.")
MNA_FALLBACK <- paste0("The PDF states no form and the name carries no hospital marker (§8's standing fallback, ",
                       "RECIPIENT_TYPE_INFERRED). Not a hospital.")
MNA_EMPLOYERS <- paste0(
  "§0.3: HOSPITALS AMONG OTHERS. The recipient passes grant funds to 'rural health care employers such as ",
  "clinics, hospitals, Tribal health ...' -- a class that includes hospitals, none named. ",
  "PASS_THROUGH_UNRESOLVED, Unclear, no bucket (Utah's UHIN). Never divided (§6.2).")

# One row per priced line, in page order. `printed` is the amount as the PDF
# prints it; `component` is the PDF's own label where it carries one.
MN_AWARDS <- tibble::tribble(
  ~key, ~awardee, ~city, ~printed, ~amount, ~component, ~recipient_type, ~basis_type, ~confidence, ~flow, ~dist, ~flag, ~purpose, ~why,
  "stratis", "Stratis Health", "Bloomington", "$883,371", 883371, NA,
  "NONPROFIT_CBO", NA, "LOW", "NON_HOSPITAL", "No", "RECIPIENT_TYPE_INFERRED",
  "Provide technical assistance services for Health Care Providers on Health Information Technology",
  paste0(MNA_FALLBACK, " The award buys technical-assistance SERVICES for providers; no sentence sends money to a hospital."),
  "mnems", "Minnesota Office of EMS", "Saint Paul", "$281,000", 281000, "OEMS Staff Time",
  "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "Pilot test an ambulance service treatment in place project",
  paste0(MNA_STATE_AGENCY, " This line is the agency's own staff time ('OEMS Staff Time')."),
  "mnems", "Minnesota Office of EMS", "Saint Paul", "$9,218,109", 9218109, "Grant Funds to EMS Agencies",
  "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "provide funds to rural ambulance services that opt into the project",
  paste0(MNA_STATE_AGENCY, " This line is a POOL the agency will 'provide ... to rural ambulance services that ",
         "opt into the project' -- ambulance services, none named. A hospital-operated ambulance service could be ",
         "among them (§0.3); that would be a second-tier row on OEMS's own roster."),
  "chwa", "Minnesota Community Health Worker Alliance", "Saint Paul", "$386,146", 386146, NA,
  "NONPROFIT_CBO", NA, "LOW", "PASS_THROUGH_UNRESOLVED", "Unclear", "RECIPIENT_TYPE_INFERRED",
  "Work with rural health care employers to support career growth opportunities for rural workers to become community health workers",
  paste0(MNA_EMPLOYERS, " The PDF: 'Employers will receive support from MNCHWA's grant funds to cover the costs of ",
         "time for classes and studying' and the employers are 'clinics, hospitals, Tribal health facilities, FQHCs, ",
         "local public health, and community-based organizations'. ", MNA_FALLBACK),
  "tmc", "Technology Management Corporation", "Shorewood", "$330,100", 330100, NA,
  "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "Provide technical advisory services to MDH on Health Information Technology purchases",
  "A supplier to the state: 'Provide technical advisory services to MDH' (a corporation, by its name). Not a hospital.",
  "ars", "AscendRural/Sourcewell", "Staples", "$25,000", 25000, NA,
  "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "Design and develop a performance measurement framework for Minnesota Department of Health",
  paste0("A supplier to the state: it designs 'a performance measurement framework for Minnesota Department of ",
         "Health'. One string naming AscendRural and Sourcewell (Sourcewell is a Minnesota service cooperative; ",
         "AscendRural is its rural initiative -- general knowledge, not stated), never divided. Not a hospital."),
  "freya", "Freya + Co", "Minnetonka", "$69,000", 69000, NA,
  "VENDOR_OR_CONTRACTOR", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "designing and facilitating structured meetings of the Minnesota Medications for Opioid Use Disorder (MOUD) Education Development Council",
  "A supplier to the state: it facilitates MDH's MOUD Education Development Council. Not a hospital.",
  "perimed", "Minnesota Perinatal Organization", "Savage", "$165,000", 165000, NA,
  "NONPROFIT_CBO", NA, "LOW", "NON_HOSPITAL", "No", "RECIPIENT_TYPE_INFERRED",
  "Provide Project Extension for Community Healthcare Outcomes (ECHO) series on topics including maternal health",
  paste0(MNA_FALLBACK, " It delivers an ECHO learning series; no sentence sends money onward."),
  "perimed", "Minnesota Medical Association", "Minneapolis", "$165,007", 165007, NA,
  "NONPROFIT_CBO", NA, "LOW", "NON_HOSPITAL", "No", "RECIPIENT_TYPE_INFERRED",
  "Provide Project Extension for Community Healthcare Outcomes (ECHO) series on mental/behavioral health services",
  paste0(MNA_FALLBACK, " A physicians' association delivering an ECHO learning series; no sentence sends money onward."),
  "hfmn", "HealthForce MN", "Winona", "$654,773", 654773, NA,
  "NONPROFIT_CBO", NA, "LOW", "PASS_THROUGH_UNRESOLVED", "Unclear", "RECIPIENT_TYPE_INFERRED",
  "Introduce K-12 student to heath care careers through Scrubs Camps and HOSA future health professional chapters",
  paste0(MNA_EMPLOYERS, " The PDF: 'employers will use grant funds to cover the costs of time for classes and ",
         "studying, tuition, and other related costs', the employers being 'clinics, hospitals, Tribal health, and ",
         "FQHCs'. ", MNA_FALLBACK),
  "mmb", "Minnesota Management and Budget", "Saint Paul", "$275,945", 275945, NA,
  "STATE_AGENCY", "STATE_SOURCE", "MEDIUM", "NON_HOSPITAL", "No", NA,
  "MMB will provide expert evaluation services",
  paste0(MNA_STATE_AGENCY, " It provides 'expert evaluation services' for the programme."))

# -- fetch (WRITES data/evidence/MN/) ---------------------------------------------

mna_fetch <- function(force = FALSE) {
  if (force || !file.exists(here::here(MNA_PAGE))) {
    rhtp_watch_archive(MNA_PAGE_URL, MNA_PAGE, MNA_AGENT)
  }
  manifest <- here::here(MNA_DIR, "MANIFEST.txt")
  for (k in MNA_PDFS$key) {
    dest <- here::here(mna_pdf_path(k))
    if (file.exists(dest) && !force) next
    Sys.sleep(3)
    url <- paste0(MNA_PDF_BASE, k, ".pdf")
    resp <- httr::GET(url, httr::user_agent(MNA_AGENT), httr::timeout(60))
    if (httr::status_code(resp) != 200L) stop("[MN awardees] ", url, " answered ", httr::status_code(resp), call. = FALSE)
    raw <- httr::content(resp, as = "raw")
    if (!identical(rawToChar(raw[1:5]), "%PDF-")) stop("[MN awardees] ", url, " is not a PDF.", call. = FALSE)
    writeBin(raw, dest)
    cat(paste(digest::digest(raw, algo = "sha256", serialize = FALSE), basename(dest), url,
              format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  "), "\n",
        file = manifest, append = TRUE, sep = "")
  }
  message("[MN awardees] archived the grants page and ", nrow(MNA_PDFS), " awardee PDFs to ", MNA_DIR, ".")
}

# -- reading ------------------------------------------------------------------------

mna_manifest_sha <- function(file) {
  m <- readr::read_lines(here::here(MNA_DIR, "MANIFEST.txt"))
  hit <- m[grepl(paste0("  ", file, "  "), m, fixed = TRUE)]
  if (length(hit) != 1L) stop("[MN awardees] MANIFEST carries ", length(hit), " lines for ", file, ".", call. = FALSE)
  sub("  .*$", "", hit)
}

mna_pdf_text <- function(key) {
  stringr::str_squish(paste(rhtp_pdf_text(here::here(mna_pdf_path(key))), collapse = " "))
}

mna_page_text <- function() rhtp_watch_reduce(here::here(MNA_PAGE))

mna_amounts_in <- function(txt) {
  a <- stringr::str_extract_all(txt, "\\$[0-9][0-9,]*(\\.[0-9]{2})?")[[1]]
  round(as.numeric(gsub("[$,]", "", a)), 2)
}

mna_assert_archive <- function() {
  for (k in MNA_PDFS$key) {
    f <- mna_pdf_path(k)
    got <- digest::digest(file = here::here(f), algo = "sha256")
    if (!identical(got, mna_manifest_sha(basename(f)))) stop("[MN awardees] ", f, " is not the manifest's bytes.", call. = FALSE)
  }
  pg <- mna_page_text()
  for (s in c(MNA_AWARDED_SENTENCE, MNA_COMING_SENTENCE, "RHTP Sub-Recipient Awardees")) {
    if (!grepl(s, pg, fixed = TRUE)) stop("[MN awardees] the page no longer says '", s, "'.", call. = FALSE)
  }
  for (l in MNA_PDFS$link) {
    if (!grepl(l, pg, fixed = TRUE)) stop("[MN awardees] the page no longer links '", l, "'.", call. = FALSE)
  }
  # Every awardee PDF the page links is one of the nine.
  links <- xml2::xml_attr(xml2::xml_find_all(xml2::read_html(here::here(MNA_PAGE)), "//a[@href]"), "href")
  aw <- unique(sub("\\.pdf$", "", basename(links[grepl("/docs/awardees/[^/]+\\.pdf$", links)])))
  if (!setequal(aw, MNA_PDFS$key)) {
    stop("[MN awardees] the page links awardee PDFs {", paste(sort(aw), collapse = ", "), "}, not the nine read.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every amount in every PDF, to the cent, against MN_AWARDS; the awardee
#' string, the heading, the date and the footer present.
mna_assert_pdfs <- function() {
  for (k in MNA_PDFS$key) {
    txt <- mna_pdf_text(k)
    want <- MN_AWARDS[MN_AWARDS$key == k, ]
    hd <- MNA_PDFS$heading[MNA_PDFS$key == k]
    if (!grepl(hd, txt, fixed = TRUE)) stop("[MN awardees] ", k, ".pdf lost its heading '", hd, "'.", call. = FALSE)
    if (!grepl("09/17/2026", txt, fixed = TRUE)) stop("[MN awardees] ", k, ".pdf is not dated 09/17/2026.", call. = FALSE)
    if (!grepl("financial assistance award totaling $193,090,618.14 with 100 percent funded by CMS/HHS", txt, fixed = TRUE)) {
      stop("[MN awardees] ", k, ".pdf's CMS footer moved (§0.2: read the percentage).", call. = FALSE)
    }
    got <- mna_amounts_in(txt)
    got <- got[abs(got - MNA_FOOTER) > 0.005]
    if (!isTRUE(all.equal(sort(got), sort(want$amount), tolerance = 0)) ) {
      stop("[MN awardees] ", k, ".pdf prints {", paste(got, collapse = ", "), "}, not {",
           paste(want$amount, collapse = ", "), "}.", call. = FALSE)
    }
    for (a in unique(want$awardee)) {
      if (!grepl(a, txt, fixed = TRUE)) stop("[MN awardees] ", k, ".pdf does not name '", a, "'.", call. = FALSE)
    }
    for (p in want$purpose) {
      if (!grepl(p, txt, fixed = TRUE)) stop("[MN awardees] ", k, ".pdf no longer says '", p, "'.", call. = FALSE)
    }
    for (cmp in stats::na.omit(want$component)) {
      if (!grepl(cmp, txt, fixed = TRUE)) stop("[MN awardees] ", k, ".pdf lost the component '", cmp, "'.", call. = FALSE)
    }
  }
  if (nrow(MN_AWARDS) != MNA_ROWS || abs(sum(MN_AWARDS$amount) - MNA_TOTAL) > 0.005) {
    stop("[MN awardees] the lines are not 11 / $12,453,451.", call. = FALSE)
  }
  if (round(MNA_TOTAL / 1e6, 1) != 12.5) stop("[MN awardees] the lines no longer round to MDH's $12.5 million.", call. = FALSE)
  first <- MN_AWARDS[!duplicated(MN_AWARDS$key), ]
  if (abs(sum(first$amount) - MNA_ONE_PER_PDF_TOTAL) > 0.005) stop("[MN awardees] one-line-per-PDF total moved.", call. = FALSE)
  # §0.2: the footer is Tier 1, Minnesota's allotment.
  rhtp_assert_footer_not_allotment(MNA_FOOTER, MNA_STATE, "STATE_ALLOTMENT",
                                   label = "MN awardee PDFs' CMS footer")
  invisible(TRUE)
}

# -- the award file -------------------------------------------------------------------

mn_year1_awardees <- function(d = MN_AWARDS) {
  cls <- rhtp_classify_recipient_type(d$awardee, MNA_STATE)
  title <- paste0("Minnesota Department of Health, 'Rural Health Transformation Program Funding: ",
                  MNA_PDFS$link[match(d$key, MNA_PDFS$key)], "' (PDF dated 09/17/2026, linked under 'RHTP ",
                  "Sub-Recipient Awardees' on ", MNA_PAGE_URL, ", Last Updated 10/27/2026)")
  tibble::tibble(
    state = MNA_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = d$recipient_type,
    distributed_to_hospital = d$dist,
    note = paste0("MDH 'RHTP Sub-Recipient Awardees': ", MNA_PDFS$link[match(d$key, MNA_PDFS$key)],
                  ifelse(is.na(d$component), "", paste0(" -- the PDF's component '", d$component, "'")),
                  " (", d$city, ")."),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = title,
    state_source_url = paste0(MNA_PDF_BASE, d$key, ".pdf"),
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cp_mn_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    roster_line = d$key,
    roster_type = MNA_PDFS$link[match(d$key, MNA_PDFS$key)],
    recipient_type_source = paste0("TYPED (session 112, HAND-READ): ", d$why, " Classifier said ",
                                   cls$recipient_type, "/", rhtp_confidence_ceiling(cls$determination_confidence), "."),
    determination_confidence = rhtp_confidence_ceiling(d$confidence),
    flag_reason = d$flag,
    award_pool = MNA_PDFS$link[match(d$key, MNA_PDFS$key)],
    budget_period = "Budget Period 1",
    flow_type = d$flow,
    hospital_benefiting = "Unclear",
    hospital_attribution = "NOT_HOSPITAL",
    intermediary_name = ifelse(grepl("^PASS_THROUGH", d$flow), d$awardee, NA_character_),
    determination_basis = paste0("§10.2 ", d$flow, ": ", d$why, " MDH: 'has awarded $12.5 million ... to the ",
                                 "following sole-source and competitive grant program recipients.'"),
    amount_basis = paste0("The PDF's own Amount cell, '", d$printed, "'",
                          ifelse(is.na(d$component), "", paste0(" ('", d$component, "')")),
                          ", exact as printed. MDH prints no total; the eleven lines sum to $12,453,451, which rounds ",
                          "to the page's '$12.5 million'."),
    basis_type = d$basis_type,
    recipient_subtype = NA_character_,
    round_amount = NA_real_,
    announcement_date = MNA_DOC_DATE,
    source_archive_path = mna_pdf_path(d$key),
    fiscal_agent_tag = FALSE,
    project_scope = d$purpose)
}

mna_assert_typing <- function(a = mn_year1_awardees()) {
  if (any(a$distributed_to_hospital == "Yes") || any(a$hospital_attribution != "NOT_HOSPITAL")) {
    stop("[MN awardees] a row is in a hospital bucket: none of the eleven is a hospital.", call. = FALSE)
  }
  un <- a[a$distributed_to_hospital == "Unclear", ]
  if (!setequal(un$awardee, c("Minnesota Community Health Worker Alliance", "HealthForce MN")) ||
      !all(un$flow_type == "PASS_THROUGH_UNRESOLVED")) {
    stop("[MN awardees] the Unclear rows are not MNCHWA and HealthForce MN.", call. = FALSE)
  }
  if (any(grepl("hospital|medical center|health system", a$awardee, ignore.case = TRUE))) {
    stop("[MN awardees] a hospital-shaped awardee appeared: type it on CMS MN enrolment.", call. = FALSE)
  }
  rhtp_assert_high_has_ccn(a, "MN awardees")
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital", "determination_confidence",
                "hospital_attribution", "basis_type", "recipient_confirmed",
                "amount_confirmed", "hospital_benefiting", "extraction_method")) {
    bad <- setdiff(stats::na.omit(unique(a[[col]])), rhtp_vocabulary(col))
    if (length(bad)) stop("[MN awardees] ", col, " outside §8: ", paste(bad, collapse = ", "), call. = FALSE)
  }
  if (length(setdiff(a$validation_source_type, rhtp_vocabulary("source_doc_type")))) {
    stop("[MN awardees] validation_source_type outside §8.", call. = FALSE)
  }
  fl <- unlist(strsplit(stats::na.omit(a$flag_reason), ";"))
  if (length(setdiff(fl, rhtp_vocabulary("flag_reason")))) stop("[MN awardees] flag_reason outside §8.", call. = FALSE)
  invisible(TRUE)
}

mna_validate <- function() {
  mna_assert_archive()
  mna_assert_pdfs()
  a <- mn_year1_awardees()
  mna_assert_typing(a)
  invisible(a)
}

mna_fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

mna_build <- function() {
  a <- mna_validate()
  readr::write_csv(a, here::here(MNA_OUT), na = "")
  message("[MN awardees] wrote ", MNA_OUT, ": ", nrow(a), " rows, $", mna_fmt(sum(a$amount)),
          "; NAMED_HOSPITAL 0.")
  invisible(a)
}

mna_report <- function(a = mna_validate()) {
  cat("\nMINNESOTA -- MDH RHTP Sub-Recipient Awardees (AWARDS, PDFs dated 09/17/2026)\n")
  cat(sprintf("  rows %d  $%s (one line per PDF: $%s)\n", nrow(a), mna_fmt(sum(a$amount)), mna_fmt(MNA_ONE_PER_PDF_TOTAL)))
  print(as.data.frame(a[, c("awardee", "amount", "recipient_type", "flow_type", "distributed_to_hospital")]))
  invisible(a)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    mna_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) { mna_validate(); message("[MN awardees] all assertions pass.") }
  if ("--build" %in% args)    mna_build()
  if ("--report" %in% args)   mna_report()
  if (!length(intersect(args, c("--fetch", "--validate", "--build", "--report")))) {
    message("usage: Rscript R/03cp_mn_year1_awardees.R [--fetch [--force]] [--validate] [--build] [--report]")
  }
}

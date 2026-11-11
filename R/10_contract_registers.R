# 10_contract_registers.R -------------------------------------------------------
# Session 116f, Task 3: CONTRACT FILES. Vendor money sits mostly in state
# procurement contracts, which FFATA/FSRS excludes (2 CFR 170). Every
# executed-contract register or first-tier list this repository archives
# becomes a CONTRACT FILE under data/reference/contracts/, one per register:
#
#   ky_contracts.csv       Kentucky's Executed Contracts tracker (2026-09-08),
#                          CONTRACT MAXIMUM per contract
#   tx_contracts.csv       Texas's CMS Budget Period 1 annual report, First-Tier
#                          Entities tab: OBLIGATION per first-tier entity
#   co_contracts.csv       Colorado's CMS annual report ("as of 6.31.26"),
#                          First-Tier Entities tab: OBLIGATION
#   ok_contracts.csv       Oklahoma's Q3 Legislative Quarterly Report (10-16):
#                          the Funded Entity table's named non-agency entities,
#                          OBLIGATION ("Current Obligated")
#   ms_contracts.csv       Mississippi DFA Notice of Intent to Award, RFQ
#                          3120003272 (BDO): INTENT, no amount printed
#   cms_obl_contracts.csv  CMS Obligated Funds Report lines naming a dictionary
#                          consultant or technology vendor that no award file
#                          carries (Redi Health Analytics, NE): OBLIGATION
#
# AND THREE REGISTERS ARE ALREADY AWARD FILES, so they get no second file: the
# South Dakota open.sd.gov RHT contracts (sd_rht_contracts.csv), Vermont's
# executed agreements and contracts (vt_year1_awardees.csv) and Idaho's
# awardee list, contractor rows included (id_year1_awardees.csv). A second copy
# would count every one of their vendor dollars twice. config/contract_registers.csv
# lists every register, the file it lands in and the probe that watches it.
#
# A CONTRACT ROW NEVER COUNTS TOWARD PUBLISHED AWARDS OR THE HOSPITAL SHARE.
# Contract files are never in STATE_FILES. Their amounts carry their own
# amount_type (contract maximum, obligation, intent) and are never summed with
# an award or with each other across types. `also_in_award_file` marks a row
# whose recipient and amount an award file already carries.
#
# Every row: budget_period 1, validation_source_type STATE_CONTRACT (the CMS
# lines keep CMS_OBLIGATION_REPORT). The spend-category columns are written by
# R/07 --apply (rhtp_spend_apply), like every award file.
#
# CLI
#   Rscript R/10_contract_registers.R --build     # write the six contract files
#   Rscript R/10_contract_registers.R --validate  # rebuild in memory, compare
#   Rscript R/10_contract_registers.R --report

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_spend_category.R"))

CR_REGISTRY <- "config/contract_registers.csv"
CR_COLUMNS <- c("state", "row_no", "awardee", "amount", "amount_type", "recipient_type",
                "recipient_type_source", "validation_source_type", "budget_period",
                "contract_start", "contract_end", "initiative", "contract_number", "purpose",
                "source_document_title", "source_url", "source_archive_path", "also_in_award_file",
                "note")

CR_KY_PDF <- "data/evidence/recheck/2026-11-02/KY/2026-11-02_KyRHT_Executed_Contract_Tracker_2026.09.08.pdf"
CR_KY_URL <- "https://ruralhealthplan.ky.gov/Documents/KyRHT_Executed_Contract_Tracker_2026.09.08.pdf"
CR_KY_PRINTED_TOTAL <- 129140844
CR_KY_ROWS <- 218L
CR_KY_ROW_SUM <- 127182976.26
CR_TX_XLSX <- "data/evidence/recheck/2026-10-01/TX/2026-10-01_hhsc_bdgt_prd_1_ann_rpt.xlsx"
CR_TX_URL <- "https://pfd.hhs.texas.gov/sites/default/files/documents/rural-hlth-prgm/bdgt-prd-1-ann-rpt.xlsx"
CR_CO_XLSX <- "data/evidence/vendor_flags/2026-11-09/CO/2026-11-09_co_hcpf_annual_report_as_of_6.31.26.xlsx"
CR_CO_URL <- "https://hcpf.colorado.gov/sites/hcpf/files/Colorado%20Annual%20Report%20as%20of%206.31.26.xlsx"
CR_OK_PDF <- "data/evidence/OK/legislative_reports/2026-10-16_ok_rhtp_legislative_quarterly_report_q3.pdf"
CR_OK_URL <- "https://oklahoma.gov/content/dam/ok/en/rhtp/documents/legislative-reports/10-16-26%20RHTP%20Legislative%20Quarterly%20Report_Q3.pdf"
CR_MS_PDF <- "data/evidence/vendor_verified/2026-11-10/MS/dfa_rfx3120003272_notice_of_intent_to_award_rht.pdf"
CR_MS_URL <- "https://www.dfa.ms.gov/sites/default/files/Procurement%20Contracts%20Home/Active%20Procurements/DFA%20Active%20Procurements/RFx%23%203120003272/Notice%20of%20Intent%20to%20Award%20RHT%20Program.pdf"

cr_pdf_lines <- function(path) system2("pdftotext", c("-layout", shQuote(here::here(path)), "-"), stdout = TRUE)

# -- Kentucky: the executed-contract tracker ------------------------------------------

CR_KY_ADDS <- c("Statewide", "Purchase", "Pennyrile", "Green River", "Barren River", "Lincoln Trail", "KIPDA",
                "Northern Kentucky", "Buffalo Trace", "FIVCO", "Big Sandy", "Kentucky River", "Cumberland Valley",
                "Lake Cumberland", "Bluegrass", "Gateway")

#' Parse the tracker's layout text: one row per line that opens with a start
#' and end date. A wrapped recipient name sits one line above and below its
#' row; it is the row's when the row's own line prints no name, or when no
#' other row is within two lines. Notes go to the NEAREST row (ties to none).
cr_ky_parse <- function(txt) {
  ini <- "(RHTP Admin|All|CTC|PoWER|RCH|RIH|RRR)"
  anchor_rx <- paste0("^\\s*(\\d{1,2}/\\d{1,2}/\\d{2,4})\\s+(\\d{1,2}/\\d{1,2}/\\d{2,4})\\s+", ini,
                      "\\s+(.*?)\\$\\s*([0-9,]+\\.[0-9]{2})\\s+(BP\\d)\\s*(.*)$")
  hdr <- grep("Subrecipient/Contractor", txt)
  anchors <- grep(anchor_rx, txt, perl = TRUE)
  rows <- list()
  for (i in anchors) {
    h <- max(hdr[hdr < i])
    ns <- regexpr("Subrecipient/Contractor", txt[h]); cs <- regexpr("County", txt[h]); nt <- regexpr("Notes", txt[h])
    m <- regmatches(txt[i], regexec(anchor_rx, txt[i], perl = TRUE))[[1]]
    rest <- strsplit(trimws(m[5]), "\\s{2,}")[[1]]
    if (!any(rest %in% CR_KY_ADDS)) {
      j <- which(grepl(paste0("^\\S+ (", paste(CR_KY_ADDS, collapse = "|"), ")$"), rest))[1]
      if (!is.na(j)) rest <- append(rest[-j], c(sub(" .*$", "", rest[j]), sub("^\\S+ ", "", rest[j])), after = j - 1)
    }
    ai <- which(rest %in% CR_KY_ADDS)[1]
    if (is.na(ai) || ai < 2) stop("[contracts] KY tracker: no county/ADD on line ", i, call. = FALSE)
    anchor_name <- paste(rest[seq_len(ai - 2)], collapse = " ")
    county <- rest[ai - 1]
    if (!nzchar(anchor_name) && grepl(" ", county)) {
      anchor_name <- sub(" \\S+$", "", county); county <- sub("^.* ", "", county)
    }
    piece <- function(l, from, to) trimws(substr(txt[l], from, to))
    others <- setdiff(anchors, i)
    take <- function(l) l >= 1 && l <= length(txt) && !(l %in% anchors) && l > h &&
      (!nzchar(anchor_name) || !any(abs(others - l) <= 2))
    above <- if (take(i - 1)) piece(i - 1, ns - 2, cs - 2) else ""
    below <- if (take(i + 1)) piece(i + 1, ns - 2, cs - 2) else ""
    parts <- c(above, anchor_name, below)
    name <- stringr::str_squish(paste(parts[nzchar(parts)], collapse = " "))
    nl <- setdiff(max(h + 1, i - 4):min(length(txt), i + 4), anchors)
    nl <- nl[vapply(nl, function(l) min(abs(others - l), Inf) > abs(i - l), logical(1))]
    notes <- stringr::str_squish(paste(vapply(sort(c(nl, i)), function(l)
      if (l == i) m[8] else piece(l, nt - 1, 10000L), ""), collapse = " "))
    rows[[length(rows) + 1]] <- tibble::tibble(
      contract_start = m[2], contract_end = m[3], initiative = m[4], awardee = name,
      county = county, area_development_district = rest[ai],
      contract_number = stringr::str_squish(paste(rest[-seq_len(ai)], collapse = " ")),
      amount = as.numeric(gsub(",", "", m[6])), budget_period_text = m[7], purpose = notes)
  }
  dplyr::bind_rows(rows)
}

cr_ky_type <- function(nm) {
  dplyr::case_when(
    grepl("^Department of|Cabinet for|Kentucky Board of|Office of|Kentucky Department", nm) ~ "STATE_AGENCY",
    grepl("Health Department|Health District|District Health", nm, ignore.case = TRUE) ~ "LOCAL_GOVT_OR_PUBLIC_HEALTH",
    grepl("University|Research Foundation|Community and Technical College|KCTCS", nm, ignore.case = TRUE) ~ "UNIVERSITY_OR_AHC",
    stringr::str_detect(nm, VF_HOSPITAL_NAME) ~ "HOSPITAL_OR_SYSTEM",
    TRUE ~ NA_character_)
}

cr_ky <- function() {
  x <- cr_ky_parse(cr_pdf_lines(CR_KY_PDF))
  if (nrow(x) != CR_KY_ROWS || abs(sum(x$amount) - CR_KY_ROW_SUM) > 0.005) {
    stop("[contracts] KY tracker parse: ", nrow(x), " rows, $", format(sum(x$amount), nsmall = 2),
         "; pinned ", CR_KY_ROWS, " rows, $", format(CR_KY_ROW_SUM, nsmall = 2), call. = FALSE)
  }
  if (any(!nzchar(x$awardee))) stop("[contracts] KY tracker: a row with no recipient name", call. = FALSE)
  if (any(x$budget_period_text != "BP1")) stop("[contracts] KY tracker: a row not marked BP1", call. = FALSE)
  rt <- cr_ky_type(x$awardee)
  tibble::tibble(
    state = "KY", awardee = x$awardee, amount = x$amount, amount_type = "contract maximum",
    recipient_type = rt,
    recipient_type_source = ifelse(is.na(rt), "not typed (contract register; the tracker states no form)",
                                   "name rule, R/10 cr_ky_type() (contract rows only; never a hospital determination)"),
    contract_start = x$contract_start, contract_end = x$contract_end, initiative = x$initiative,
    contract_number = x$contract_number, purpose = x$purpose,
    source_document_title = "Kentucky Rural Health Transformation Executed Contracts by Contract Start Date (tracker dated 2026-09-08)",
    source_url = CR_KY_URL, source_archive_path = CR_KY_PDF,
    note = paste0("'Contract Amount' (a contract maximum), Budget Period column 'BP1', county ", x$county,
                  ". The tracker's printed total is $129,140,844; its 218 rows sum to $127,182,976.26 ",
                  "(gap $1,957,867.74, UNRECONCILED, recorded, never imputed)."))
}

# -- Texas and Colorado: the CMS annual-report First-Tier Entities tab ---------------

cr_first_tier <- function(path) {
  d <- suppressMessages(readxl::read_excel(here::here(path), "First-Tier Entities", col_names = FALSE,
                                           col_types = "text"))
  d <- d[!is.na(d[[1]]) & grepl("^[0-9]+$", d[[1]]), , drop = FALSE]
  tibble::tibble(entity_id = d[[1]], entity = stringr::str_squish(d[[2]]), entity_type = d[[3]],
                 obligated = as.numeric(d[[4]]), disbursed = as.numeric(d[[6]]))
}

cr_first_tier_type <- function(et, nm) {
  dplyr::case_when(
    grepl("State .*Agency|Other State Agency", et) ~ "STATE_AGENCY",
    grepl("Local Government", et) & grepl("Hospital|Medical District|Healthcare System", nm) ~ "HOSPITAL_OR_SYSTEM",
    grepl("Local Government", et) ~ "LOCAL_GOVT_OR_PUBLIC_HEALTH",
    grepl("Consult|Technical Assistance", et) ~ "VENDOR_OR_CONTRACTOR",
    TRUE ~ NA_character_)
}

cr_annual <- function(state, path, url, title) {
  x <- cr_first_tier(path)
  if (!nrow(x)) stop("[contracts] ", state, ": no First-Tier Entities rows", call. = FALSE)
  rt <- cr_first_tier_type(x$entity_type, x$entity)
  tibble::tibble(
    state = state, awardee = x$entity, amount = x$obligated, amount_type = "obligation",
    recipient_type = rt,
    recipient_type_source = paste0("the report's own Entity Type: '", x$entity_type, "'"),
    contract_start = NA_character_, contract_end = NA_character_, initiative = NA_character_,
    contract_number = paste0("First-Tier Entity ID ", x$entity_id),
    purpose = paste0("First-Tier Entity, type '", x$entity_type, "'"),
    source_document_title = title, source_url = url, source_archive_path = path,
    note = paste0("'Obligated Funds' $", format(x$obligated, big.mark = ",", nsmall = 2), ", disbursed $",
                  format(x$disbursed, big.mark = ",", nsmall = 2),
                  ". An obligation to a first-tier entity (session 97's rule), never an award."))
}

# -- Oklahoma: the Q3 Legislative Quarterly Report's Funded Entity table -------------

# Every named entity that is not a state agency, as printed, with the
# "Current Obligated" figure. Each amount is asserted against the PDF text.
# State agencies (OHCA, OSDH, OSDE, CareerTech, HWTC) are left out: an
# agency's own budget line is not a contract with anybody.
CR_OK_ROWS <- tibble::tribble(
  ~awardee, ~funded_entity_as_printed, ~initiative, ~obligated, ~recipient_type, ~status,
  "Southwestern Oklahoma Development Authority (SWODA)", "SWODA", "Transportation Expansion", "$2,651,000.00",
  "LOCAL_GOVT_OR_PUBLIC_HEALTH", "Mileage reimbursement program in full implementation.",
  "University of Oklahoma Health Sciences Center (OUHSC)", "OSDH: OUHSC", "Telestroke Expansion", "$499,555.00",
  "UNIVERSITY_OR_AHC", "11 sites live and four contracts for additional sites have been",
  "OUHSC / Oklahoma State University (joint)", "OSDH: OUHSC/OSU", "MFM Telehealth Expansion", "$5,861,233.79",
  "UNIVERSITY_OR_AHC", "Finalizing contract for MFM sites in Shawnee, McAlester and Dunca",
  "Oklahoma State University (OSU)", "OSDH: OSU", "Community Paramedicine Program", "$2,264,105.46",
  "UNIVERSITY_OR_AHC", "Developed curriculum, ordered a fully equipped training vehicle,",
  "Foundation for a Healthy Oklahoma (OHA)", "Foundation for a Healthy / Oklahoma (OHA)", "Lung Cancer Screening Program", "$2,371,360.66",
  "NONPROFIT_CBO", "Eight hospitals subcontracted with OHA; five have hired lung navi",
  "Foundation for a Healthy Oklahoma (OHA)", "Foundation for a Healthy / Oklahoma (OHA)", "CHW Expansion", "$4,460,162.93",
  "NONPROFIT_CBO", "30 hospital and 18 FQHC CHW sites under contract",
  "LifeCare Alliance LLC", "OSDH: LifeCare", "Provider Collaborative", "$33,862,084.00",
  "NONPROFIT_CBO", "LifeCare finalizing subcontracts; working on outreach for their first",
  "Pulsara", "OSDH: Pulsara", "EMS Centralization", "$3,790,000.00",
  "VENDOR_OR_CONTRACTOR", "174 Pulsara sites signed up; 86 sites had patient activity in the last",
  "OUHSC / Oklahoma State University (joint)", "OSDH: OUHSC/OSU", "Rural Residency Programs", "$22,069,267.00",
  "UNIVERSITY_OR_AHC", "feasibility assessments underway with four rural hosp")

cr_ok <- function() {
  txt <- stringr::str_squish(paste(cr_pdf_lines(CR_OK_PDF), collapse = " "))
  for (i in seq_len(nrow(CR_OK_ROWS))) {
    r <- CR_OK_ROWS[i, ]
    # " / " separates the two printed lines of a wrapped Funded Entity cell
    for (s in c(strsplit(r$funded_entity_as_printed, " / ", fixed = TRUE)[[1]], r$obligated,
                r$initiative, r$status)) {
      if (!grepl(stringr::str_squish(s), txt, fixed = TRUE)) {
        stop("[contracts] OK Q3 report: '", s, "' is not printed in ", CR_OK_PDF, call. = FALSE)
      }
    }
  }
  tibble::tibble(
    state = "OK", awardee = CR_OK_ROWS$awardee,
    amount = as.numeric(gsub("[$,]", "", CR_OK_ROWS$obligated)), amount_type = "obligation",
    recipient_type = CR_OK_ROWS$recipient_type,
    recipient_type_source = "hand typing of the report's Funded Entity (session 116f; contract rows only)",
    contract_start = NA_character_, contract_end = NA_character_, initiative = CR_OK_ROWS$initiative,
    contract_number = NA_character_, purpose = CR_OK_ROWS$status,
    source_document_title = "Oklahoma RHTP Legislative Quarterly Report, Q3 (10-16-26), Funded Entity table",
    source_url = CR_OK_URL, source_archive_path = CR_OK_PDF,
    note = paste0("Funded Entity printed '", CR_OK_ROWS$funded_entity_as_printed, "'; 'Current Obligated' ",
                  CR_OK_ROWS$obligated, " ('Obligation: Formally committing to spend funds through a contract ",
                  "or other signed agreement'). An obligation, never an award; a joint OUHSC/OSU line is never divided."))
}

# -- Mississippi: DFA's notice of intent to award (BDO) ----------------------------------

cr_ms <- function() {
  txt <- stringr::str_squish(paste(cr_pdf_lines(CR_MS_PDF), collapse = " "))
  q <- "announces our intent to award to the contract to BDO as the highest scoring, qualified respondent"
  if (!grepl(q, txt, fixed = TRUE)) stop("[contracts] MS NOI: the award sentence is not printed", call. = FALSE)
  tibble::tibble(
    state = "MS", awardee = "BDO Government Services", amount = NA_real_, amount_type = "intent",
    recipient_type = "VENDOR_OR_CONTRACTOR",
    recipient_type_source = "the notice: an RFQ 'for the purpose of hiring a contractor'",
    contract_start = "2026-01-09", contract_end = NA_character_, initiative = NA_character_,
    contract_number = "RFQ 3120003272",
    purpose = "hiring a contractor to assist in fulfilling the State's legal obligations regarding all Rural Health Transformation (RHT) Program funds received by the State of Mississippi",
    source_document_title = "Mississippi DFA, Notice of Intent to Award, RFQ 3120003272 (Rural Health Transformation Program), posted 2026-01-09",
    source_url = CR_MS_URL, source_archive_path = CR_MS_PDF,
    note = paste0("DFA ", q, ". NO AMOUNT is printed, so the row is unpriced and fails V3 (session 116e drop)."))
}

# -- CMS obligation lines naming a dictionary vendor no award file carries -------------

cr_cms_obl <- function(award_rows) {
  x <- vf_from_cms_named() %>%
    dplyr::filter(!is.na(amount), entity_class %in% c("CONSULTING_BIG", "CONSULTING_OTHER", "TECH_VENDOR"))
  inaward <- purrr::map2_lgl(x$state, x$amount, function(st, a)
    any(award_rows$state == st & !is.na(award_rows$amount) & abs(award_rows$amount - a) < 0.01))
  x <- x[!inaward, , drop = FALSE]
  tibble::tibble(
    state = x$state, awardee = x$recipient, amount = x$amount, amount_type = "obligation",
    recipient_type = "VENDOR_OR_CONTRACTOR",
    recipient_type_source = paste0("config/vendor_entity_dictionary.csv: ", x$canonical_name, " (", x$entity_class, ")"),
    contract_start = NA_character_, contract_end = NA_character_, initiative = NA_character_,
    contract_number = NA_character_, purpose = x$purpose_quote,
    source_document_title = "CMS, RHTP Obligated Funds Report (10-14 edition; obligations as of 2026-07-31)",
    source_url = x$source_url, source_archive_path = x$archive_path,
    note = "A CMS obligation line naming one firm, carried by no award file. An obligation, never an award.") %>%
    dplyr::mutate(validation_source_type = "CMS_OBLIGATION_REPORT")
}

# -- assemble ---------------------------------------------------------------------------

cr_award_rows <- function() {
  sf <- vf_state_files()
  purrr::map_dfr(sf, function(p) {
    d <- readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"), progress = FALSE)
    fa <- if ("fsrs_amount" %in% names(d)) as.numeric(d$fsrs_amount) else NA_real_
    tibble::tibble(state = d$state, key = rhtp_spend_norm(d$awardee), amount = as.numeric(d$amount),
                   fsrs_amount = fa, file = p)
  })
}

cr_finish <- function(d, award) {
  key <- rhtp_spend_norm(d$awardee)
  also <- vapply(seq_len(nrow(d)), function(i) {
    if (is.na(d$amount[i])) return("")
    L <- min(12L, nchar(key[i]))
    h <- award[award$state == d$state[i] & substr(award$key, 1, L) == substr(key[i], 1, L) &
                 ((!is.na(award$amount) & abs(award$amount - d$amount[i]) < 0.01) |
                    (!is.na(award$fsrs_amount) & abs(award$fsrs_amount - d$amount[i]) < 0.01)), ]
    if (nrow(h)) paste(unique(h$file), collapse = "; ") else ""
  }, character(1))
  if (!"validation_source_type" %in% names(d)) d$validation_source_type <- "STATE_CONTRACT"
  d %>% dplyr::mutate(row_no = as.character(dplyr::row_number()), budget_period = "1",
                      also_in_award_file = also,
                      amount = ifelse(is.na(amount), NA_character_, format(amount, scientific = FALSE, trim = TRUE, nsmall = 2))) %>%
    dplyr::select(dplyr::all_of(CR_COLUMNS))
}

cr_build_all <- function() {
  award <- cr_award_rows()
  list(
    KY = cr_finish(cr_ky(), award),
    TX = cr_finish(cr_annual("TX", CR_TX_XLSX, CR_TX_URL,
                             "Texas HHSC, CMS RHTP Budget Period 1 Annual Report (First-Tier Entities tab)"), award),
    CO = cr_finish(cr_annual("CO", CR_CO_XLSX, CR_CO_URL,
                             "Colorado HCPF, CMS RHTP Annual Report as of 6.31.26 (First-Tier Entities tab)"), award),
    OK = cr_finish(cr_ok(), award),
    MS = cr_finish(cr_ms(), award),
    CMS_OBL = cr_finish(cr_cms_obl(award), award))
}

cr_path <- function(k) file.path(RHTP_CONTRACT_DIR, paste0(tolower(k), "_contracts.csv"))

#' Write the contract files. The spend-category columns already committed on a
#' file are carried over only when the rows did not change; otherwise run
#' R/07 --apply after this (it is the LAST overlay, and it writes them).
cr_build <- function() {
  dir.create(here::here(RHTP_CONTRACT_DIR), showWarnings = FALSE, recursive = TRUE)
  for (k in names(b <- cr_build_all())) {
    readr::write_csv(b[[k]], here::here(cr_path(k)), na = "")
    message("[contracts] ", cr_path(k), ": ", nrow(b[[k]]), " rows")
  }
  message("[contracts] now run Rscript R/07_summary_calls.R --apply (writes the spend-category columns).")
  invisible(b)
}

#' The committed contract files equal a fresh build (spend columns aside)
cr_validate <- function() {
  b <- cr_build_all()
  for (k in names(b)) {
    p <- here::here(cr_path(k))
    if (!file.exists(p)) stop("[contracts] missing ", cr_path(k), call. = FALSE)
    d <- readr::read_csv(p, col_types = readr::cols(.default = "c"), na = character(), progress = FALSE)
    d <- d[, CR_COLUMNS]
    want <- b[[k]] %>% dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::coalesce(.x, "")))
    if (!identical(as.data.frame(d), as.data.frame(want))) {
      stop("[contracts] ", cr_path(k), " differs from a fresh build. Re-run --build, then R/07 --apply.", call. = FALSE)
    }
  }
  reg <- readr::read_csv(here::here(CR_REGISTRY), col_types = readr::cols(.default = "c"), progress = FALSE)
  stopifnot(all(file.exists(here::here(reg$lands_in))))
  invisible(b)
}

cr_report <- function() {
  for (k in names(b <- cr_build_all())) {
    a <- suppressWarnings(as.numeric(b[[k]]$amount))
    message(sprintf("%-8s %4d rows  %-17s $%s", k, nrow(b[[k]]), paste(unique(b[[k]]$amount_type), collapse = "/"),
                    format(sum(a, na.rm = TRUE), big.mark = ",", nsmall = 2)))
  }
}

# -- the probe hooks (Task 3: "add each register to its state probe") -----------------

#' Fetch a register's live bytes; a non-200 is an HTTP error (logged ERROR)
cr_get <- function(url, agent, label) {
  resp <- httr::GET(url, httr::user_agent(agent), httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[contracts] ", label, ": HTTP ", httr::status_code(resp), " from ", url, call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

#' Live text of a register, for a state probe: PDF via pdftotext, xlsx via the
#' First-Tier tab. Returns list(text, rows).
cr_register_live <- function(kind, bytes) {
  f <- tempfile(fileext = if (kind == "xlsx") ".xlsx" else ".pdf")
  on.exit(unlink(f), add = TRUE)
  writeBin(bytes, f)
  if (kind == "xlsx") {
    x <- cr_first_tier(f)
    list(text = paste(x$entity, x$obligated, collapse = "\n"),
         rows = tibble::tibble(awardee = x$entity, amount = x$obligated))
  } else {
    txt <- system2("pdftotext", c("-layout", shQuote(f), "-"), stdout = TRUE)
    list(text = stringr::str_squish(paste(txt, collapse = " ")), rows = NULL, lines = txt)
  }
}

#' Check one register inside a state's probe: CHANGED if its content moved,
#' TRIPWIRE for every contract the live copy lists that the contract file does
#' not. `fetch` returns the live bytes (through the state's own agent).
cr_probe_register <- function(state, page, fetch, kind, archived, contract_key) {
  live_bytes <- rhtp_probe_get(page, fetch, archived)
  live <- cr_register_live(kind, live_bytes)
  arch <- cr_register_live(kind, readBin(here::here(archived), "raw", file.size(here::here(archived))))
  committed <- readr::read_csv(here::here(cr_path(contract_key)), col_types = readr::cols(.default = "c"),
                               progress = FALSE)
  live_rows <- live$rows
  if (contract_key == "KY") live_rows <- cr_ky_parse(live$lines) %>% dplyr::select(awardee, amount)
  rhtp_contract_register_check(state, page, live$text, arch$text,
                               live_rows = live_rows,
                               committed_rows = if (is.null(live_rows)) NULL else committed %>% dplyr::select(awardee, amount))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) cr_build()
  if ("--validate" %in% args) { cr_validate(); message("[contracts] contract files validate.") }
  if ("--report" %in% args) cr_report()
  if (!length(intersect(args, c("--build", "--validate", "--report")))) {
    message("usage: Rscript R/10_contract_registers.R [--build] [--validate] [--report]")
  }
}

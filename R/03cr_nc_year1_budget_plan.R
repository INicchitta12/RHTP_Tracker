# 03cr_nc_year1_budget_plan.R ---------------------------------------------------
#
# NORTH CAROLINA'S "LIST OF PROJECTS, YEAR 1": 134 BUDGET LINES, $213,008,356.47,
# AND NOT ONE OF THEM AN AWARD (session 116, owner ruling on session 115's hold).
#
# WHAT IT IS. NCDHHS's "Transforming Rural Health in North Carolina: Our
# Progress" page links a CSV, "List of projects - Year 1", with the columns
# Workstream, Contract Title, Program Title, Recipient, Description, Counties
# Served, Budgeted Amount. Its 134 lines sum to $213,008,356.47 -- North
# Carolina's FY2026 allotment TO THE CENT (§7.1 anchor $213,008,356; the page's
# own CMS footer prints $213,008,356.47). The page heads the list:
#
#   "List of Projects, Year 1 Budget amounts shown are subject to change based
#    on program progress and needs."
#
# OWNER RULING (session 116): A PLAN, NOT AWARDS. The column is a "Budgeted
# Amount", the page says it is "subject to change", and the list allocates the
# WHOLE allotment -- state agencies (NCDIT, DHB, OSHR, DOA), vendors (Accenture,
# Marsh, CAI) and the administrative budget included. A list that sums to the
# allotment is an allocation of the budget, and §0.3 / the standing rule says a
# plan or budget line is never an award. So this is a NON-AWARD file, the shape
# of `ks_ebp_participants.csv`: never in STATE_FILES, no `amount` column (the
# figure is carried as the TEXT the state printed, in `budgeted_amount_text`),
# every row award_made = No, and nothing here enters any total.
#
# TYPING IS FOR REFERENCE ONLY. Each line carries a `reference_recipient_type`
# read on CMS NC enrolment (hospital, FQHC, RHC files archived under
# federal_records/) and, where no enrolment carries the name, on the §8
# classifier or a hand note. Nothing is a determination; nothing is in a
# bucket. Hospital-shaped lines: UNC Health 9 / $21,528,215.99, Cumberland
# County Hospital System, Inc. 1 / $300,000 (exact legal name, CCN 340028),
# FirstHealth of the Carolinas 1 / $250,000 (legal name less "Inc", CCNs
# 340115 + 341303) = $22,078,215.99, as printed and as budgeted.
#
# UNC HEALTH'S HUB LEAD LINES ARE A PASS-THROUGH QUESTION, NOT A HOSPITAL
# FIGURE. Eight of UNC Health's nine lines are "ROOTS Hub Lead (UNC Health)",
# including "ROOTS Hub Lead Core Functions (UNC Health)" ($12.5M). A Hub Lead
# administers regional money onward (§7, §10.2); the owner has noted the core
# line for a pass-through ruling WHEN IT IS AWARDED. `pass_through_note`
# records that on each Hub Lead line. Until then it is a budget line.
#
# WHAT RE-OPENS IT. A page or roster that says a line has been AWARDED or a
# contract EXECUTED makes that line an award source; extract it then, into an
# award file, under the ordinary rules. A re-dated CSV is a new plan to read.
#
# CLI:
#   Rscript R/03cr_nc_year1_budget_plan.R --validate
#   Rscript R/03cr_nc_year1_budget_plan.R --build
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))
source(here::here("R", "utils_recipient_classification.R"))

NCP_DIR <- file.path("data", "evidence", "recheck", "2026-11-09", "NC")
NCP_CSV_SRC <- file.path(NCP_DIR, "2026-11-09_nc_list_of_projects_year1.csv")
NCP_PAGE <- file.path(NCP_DIR, "2026-11-09_nc_our_progress_page.html")
NCP_SHA <- c(
  csv  = "04fedd4eb3ecf465b0aabb04877baaacbdf83e566bc8dd2a2d6c329aa81c76c9",
  page = "8db1fb0144b5a10847ac684350592499a10cb357f8a5a9c0fa8f007fd8fc1c90")
NCP_URL <- "https://www.ncdhhs.gov/nc-locator/list-of-projects-year-1/csv"
NCP_PAGE_URL <- paste0("https://www.ncdhhs.gov/about/department-initiatives/",
                       "rural-health-transformation-program/",
                       "transforming-rural-health-north-carolina-our-progress")
NCP_OUT <- here::here("data", "reference", "nc_year1_budget_plan.csv")
NCP_N <- 134L
NCP_TOTAL_CENTS <- 21300835647      # $213,008,356.47
NCP_ALLOTMENT <- 213008356          # cms_fy2026_allotments.csv (§7.1)
NCP_TITLE <- "List of projects - Year 1 (NCDHHS, read 2026-11-09)"
NCP_SENTENCES <- c(
  subject_to_change = "List of Projects, Year 1 Budget amounts shown are subject to change based on program progress and needs.",
  spend_by = "Projects have until September 2027 to spend their budget allocation for Year 1.",
  footer = "as part of a financial assistance award totaling $213,008,356.47 with 100% funded by CMS/HHS.")
NCP_FED <- c(
  HOSPITAL = file.path("data", "evidence", "federal_records", "2026-09-25", "cms_hosp_enrollments_NC.json"),
  FQHC = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_fqhc_enrollments_NC.json"),
  RHC = file.path("data", "evidence", "federal_records", "2026-10-01", "cms_rhc_enrollments_NC.json"))

# Hand-read reference typings, where neither an exact CMS enrolment nor the §8
# name rules answer. REFERENCE ONLY: none is a determination.
NCP_HAND <- tibble::tribble(
  ~recipient, ~recipient_type, ~basis_type, ~why,
  "UNC Health", "HOSPITAL_OR_SYSTEM", "GENERAL_KNOWLEDGE",
  "An academic health SYSTEM string (session 110 ruling (a), the UC San Diego Health / UVA Health precedent): subtype ACADEMIC_HEALTH_CENTER, LOW. No NC enrolment carries 'UNC Health' as a legal name; UNIVERSITY OF NORTH CAROLINA HOSPITALS AT CHAPEL HILL (CCN 340061) is the enrolled hospital and is not named.",
  "Trillium Health Resources", "MANAGED_CARE_ORGANIZATION", "STATE_SOURCE",
  "NCDHHS states the form: 'an NC Medicaid Tailored Plan and Managed Care Organization (MCO)' (session 39).",
  "Vaya Health", "MANAGED_CARE_ORGANIZATION", "STATE_SOURCE",
  "NCDHHS states the form: 'a public NC Medicaid Managed Care Organization (MCO)' (session 39).",
  "Alliance Health", "MANAGED_CARE_ORGANIZATION", "GENERAL_KNOWLEDGE",
  "An NC LME/MCO (Tailored Plan); not stated on this page.",
  "Partners Health Management", "MANAGED_CARE_ORGANIZATION", "GENERAL_KNOWLEDGE",
  "An NC LME/MCO (Tailored Plan); not stated on this page.",
  "Accenture", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "A consulting firm.",
  "Marsh", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "A risk and insurance broker.",
  "CAI", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "An IT services firm.",
  "Neimand Collaborative", "VENDOR_OR_CONTRACTOR", "GENERAL_KNOWLEDGE", "A communications firm.",
  "North Carolina Office of State Human Resources", "STATE_AGENCY", "STATE_SOURCE", "A state office; the form is in the string.",
  "UNC School of Social Work", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "A university school; not the enrolled hospital.",
  "UNC Office of Sponsored Programs", "UNIVERSITY_OR_AHC", "STATE_SOURCE", "A university office; not the enrolled hospital.",
  "Duke-Margolis Institute for Health Policy", "UNIVERSITY_OR_AHC", "GENERAL_KNOWLEDGE", "A Duke University policy institute.",
  "Granville Vance Public Health", "LOCAL_GOVT_OR_PUBLIC_HEALTH", "GENERAL_KNOWLEDGE", "A district health department."
)

ncp_sha <- function(p) digest::digest(file = here::here(p), algo = "sha256")

ncp_read <- function() {
  if (!identical(ncp_sha(NCP_CSV_SRC), NCP_SHA[["csv"]])) {
    stop("[NC plan] the archived CSV's SHA-256 does not match MANIFEST.txt.", call. = FALSE)
  }
  d <- readr::read_csv(here::here(NCP_CSV_SRC), show_col_types = FALSE,
                       col_types = readr::cols(.default = "c"))
  want <- c("Workstream", "Contract Title", "Program Title", "Recipient",
            "Description", "Counties Served", "Budgeted Amount")
  if (!identical(names(d), want)) {
    stop("[NC plan] the CSV's columns moved: ", paste(names(d), collapse = " | "),
         call. = FALSE)
  }
  d
}

ncp_cents <- function(x) {
  if (any(!grepl("^\\$[0-9,]+\\.[0-9]{2}$", x))) {
    stop("[NC plan] a Budgeted Amount is not printed as $n.nn.", call. = FALSE)
  }
  as.numeric(gsub("[$,.]", "", x))
}

ncp_federal <- function() {
  purrr::imap_dfr(NCP_FED, function(f, k) {
    j <- jsonlite::fromJSON(here::here(f))
    tibble::tibble(kind = k, ccn = as.character(j$CCN),
                   org = j$`ORGANIZATION NAME`, dba = j$`DOING BUSINESS AS NAME`)
  })
}

#' Legal-name key: upper case, punctuation dropped, a trailing corporate
#' suffix dropped. Exact on that key only -- a prefix is never a match (§2).
ncp_key <- function(x) {
  k <- toupper(gsub("[[:punct:]]", " ", x))
  k <- stringr::str_squish(k)
  stringr::str_squish(sub(" (INC|INCORPORATED|LLC|LLLP|CORP|CORPORATION)$", "", k))
}

ncp_assert <- function() {
  d <- ncp_read()
  if (nrow(d) != NCP_N) stop("[NC plan] expected ", NCP_N, " lines, read ", nrow(d), ".", call. = FALSE)
  if (sum(ncp_cents(d$`Budgeted Amount`)) != NCP_TOTAL_CENTS) {
    stop("[NC plan] the lines no longer sum to $213,008,356.47.", call. = FALSE)
  }
  if (round(NCP_TOTAL_CENTS / 100) != NCP_ALLOTMENT) {
    stop("[NC plan] the total no longer equals the allotment.", call. = FALSE)
  }
  if (!identical(ncp_sha(NCP_PAGE), NCP_SHA[["page"]])) {
    stop("[NC plan] the archived page's SHA-256 does not match MANIFEST.txt.", call. = FALSE)
  }
  t <- rhtp_watch_reduce(here::here(NCP_PAGE))
  for (k in names(NCP_SENTENCES)) {
    if (!grepl(NCP_SENTENCES[[k]], t, fixed = TRUE)) {
      stop("[NC plan] the '", k, "' sentence is gone from the archived page.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ncp_build <- function() {
  ncp_assert()
  d <- ncp_read()
  fed <- ncp_federal() %>% dplyr::filter(grepl("^[0-9]{6}$", ccn)) %>%
    dplyr::mutate(key = ncp_key(org))
  u <- unique(d$Recipient)
  cls <- rhtp_classify_recipient_type(u, "NC") %>% dplyr::mutate(recipient = u)
  typ <- purrr::map_dfr(u, function(r) {
    hit <- fed[fed$key == ncp_key(r), ]
    kinds <- unique(hit$kind)
    h <- NCP_HAND[NCP_HAND$recipient == r, ]
    c0 <- cls[cls$recipient == r, ]
    if (nrow(h)) {
      ty <- h$recipient_type; bt <- h$basis_type; why <- h$why
    } else if ("HOSPITAL" %in% kinds) {
      ty <- "HOSPITAL_OR_SYSTEM"; bt <- "ORG_WEBSITE"
      why <- "CMS NC Hospital Enrollment carries the legal name (corporate suffix aside)."
    } else if ("FQHC" %in% kinds) {
      ty <- "FQHC_OR_RHC"; bt <- "ORG_WEBSITE"
      why <- "CMS NC FQHC Enrollment carries the legal name (corporate suffix aside)."
    } else {
      ty <- c0$recipient_type; bt <- "STATE_SOURCE"
      if (identical(c0$rule, "FALLBACK")) bt <- "GENERAL_KNOWLEDGE"
      why <- c0$recipient_type_basis
    }
    k1 <- if ("HOSPITAL" %in% kinds) "HOSPITAL" else if (length(kinds)) kinds[1] else NA_character_
    hk <- hit[hit$kind == k1, ]
    tibble::tibble(
      Recipient = r,
      reference_recipient_type = ty,
      reference_recipient_subtype = if (r == "UNC Health") "ACADEMIC_HEALTH_CENTER" else NA_character_,
      reference_basis_type = bt,
      reference_confidence = rhtp_confidence_ceiling(
        if (bt == "GENERAL_KNOWLEDGE") "LOW" else "MEDIUM"),
      cms_enrolment_kind = k1,
      cms_enrolment_org = if (nrow(hk)) hk$org[1] else NA_character_,
      cms_enrolment_ccns = if (nrow(hk)) paste(sort(unique(hk$ccn)), collapse = ";") else NA_character_,
      reference_typing_note = why)
  })
  out <- d %>%
    dplyr::mutate(row_no = dplyr::row_number()) %>%
    dplyr::left_join(typ, by = "Recipient") %>%
    dplyr::transmute(
      state = "NC",
      row_no,
      organization = Recipient,
      workstream = Workstream,
      contract_title = `Contract Title`,
      program_title = `Program Title`,
      description = Description,
      counties_served = `Counties Served`,
      budgeted_amount_text = `Budgeted Amount`,
      plan_list = NCP_TITLE,
      award_made = "No",
      amount_published = "BUDGETED_NOT_AWARDED",
      reference_recipient_type, reference_recipient_subtype, reference_basis_type,
      reference_confidence, cms_enrolment_kind, cms_enrolment_org, cms_enrolment_ccns,
      reference_typing_note,
      pass_through_note = dplyr::if_else(
        grepl("^ROOTS Hub Lead \\(", `Contract Title`),
        paste0(
          "ROOTS Hub Lead line: a Hub Lead administers regional money onward. ",
          if_else(grepl("Core Functions", `Program Title`),
                  "OWNER NOTE (session 116): the core-funding line is held for a §10.2 pass-through ruling WHEN AWARDED. ",
                  ""),
          "Not a hospital figure as budgeted."),
        NA_character_),
      note = paste(
        "NOT AN AWARD (owner ruling, session 116): a 'Budgeted Amount' on a list",
        "that sums to the allotment to the cent and is 'subject to change based on",
        "program progress and needs'. Reference typing only; never in STATE_FILES;",
        "never in any total."),
      budget_period = 1L,
      source_document_title = NCP_TITLE,
      source_url = NCP_URL,
      source_page_url = NCP_PAGE_URL,
      source_archive_path = NCP_CSV_SRC,
      basis_type = "STATE_SOURCE")
  stopifnot(nrow(out) == NCP_N, !any(c("amount", "round_amount") %in% names(out)),
            !any(is.na(out$reference_recipient_type)))
  readr::write_csv(out, NCP_OUT, na = "")
  message("[NC plan] wrote ", nrow(out), " BUDGET lines (NOT awards) to ", basename(NCP_OUT))
  invisible(out)
}

#' Hospital-shaped reference lines, as budgeted -- a REPORT, never a figure.
ncp_report <- function(x = readr::read_csv(NCP_OUT, show_col_types = FALSE)) {
  h <- x[x$reference_recipient_type == "HOSPITAL_OR_SYSTEM", ]
  cents <- ncp_cents(h$budgeted_amount_text)
  s <- tapply(cents, h$organization, sum) / 100
  for (n in names(s)) message(sprintf("  %-45s $%s (budgeted)", n,
                                      formatC(s[[n]], format = "f", digits = 2, big.mark = ",")))
  invisible(s)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) {
    ncp_assert(); message("[NC plan] all assertions pass.")
  } else if ("--build" %in% args) {
    ncp_build(); ncp_report()
  } else if ("--report" %in% args) {
    ncp_report()
  } else {
    message("Usage: Rscript R/03cr_nc_year1_budget_plan.R [--validate | --build | --report]")
  }
}

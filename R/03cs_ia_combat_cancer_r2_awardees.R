# 03cs_ia_combat_cancer_r2_awardees.R ------------------------------------------
#
# IOWA'S COMBAT CANCER HEALTH HUBS ROUND 2: FOUR NAMED HOSPITALS, NO AMOUNTS,
# INTENTS (session 116, owner ruling on session 115's hold).
#
# SOURCE. Iowa HHS, "Notice of Intent to Award", RFP COMPADM26008 "Combat
# Cancer Health Hubs Round 2", dated August 12, 2026 (media 19192; archived
# under recheck/2026-11-09/IA/ by session 115). It names four "apparent
# successful bidder(s)" and prints ONE dollar figure, in its CMS footer:
# "approximately $209,040,063.71" -- Iowa's ALLOTMENT (Tier 1; §0.2's second
# worked example, the same sentence Round 1's notice carries). So the footer
# is PROVENANCE, never a round total, and nothing is attributed to a row.
#
# WHY A SEPARATE FILE. R/03z's eleven-notice model carries its notice count in
# prose, tests and the footer table (ia_notice_footers.csv); this twelfth
# notice is its own file so none of those invariants moves. It is a Year 1
# (Budget Period 1) action: dated 2026-08-12, after the NOA (§6.2 date test),
# before the BP1 end (2026-10-30).
#
# TYPING. Each bidder is printed "<legal name> DBA <trading name>", and each
# legal name is on CMS IA Hospital Enrollments (federal_records/2026-09-25),
# punctuation aside: HOSPITAL_OR_SYSTEM, DIRECT, NAMED_HOSPITAL at $0, MEDIUM,
# ORG_WEBSITE, the CCN in the basis and not on the row (Stage 5 owns `ccn`).
# The awardee is the DBA name as Iowa prints it; the legal name is kept.
#
# INTENT, IN THE NOTICE'S OWN WORDS: "this Notice does NOT constitute the
# formation of a contract between the Agency and the apparent successful
# bidder." AMOUNT_MISSING; amount_confirmed = No.
#
# CLI:
#   Rscript R/03cs_ia_combat_cancer_r2_awardees.R --validate
#   Rscript R/03cs_ia_combat_cancer_r2_awardees.R --build
#   (then R/07_summary_calls.R --apply, which is LAST)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

IAR2_PDF <- file.path("data", "evidence", "recheck", "2026-11-09", "IA",
                      "2026-11-09_ia_noia_compadm26008_combat_cancer_round2.pdf")
IAR2_SHA <- "739816baf3461883b394ba742fba2161398eb08823eca382e2406d31934e550c"
IAR2_URL <- "https://hhs.iowa.gov/media/19192/download?inline"
IAR2_RFP <- "COMPADM26008"
IAR2_DATE <- as.Date("2026-08-12")
IAR2_NOA <- as.Date("2025-12-29")
IAR2_BP1_END <- as.Date("2026-10-30")
IAR2_FOOTER <- 209040063.71
IAR2_OUT <- here::here("data", "reference", "ia_combat_cancer_r2_awardees.csv")
IAR2_FED <- file.path("data", "evidence", "federal_records", "2026-09-25",
                      "cms_hosp_enrollments_IA.json")

IAR2_BIDDERS <- tibble::tribble(
  ~printed, ~legal, ~dba, ~ccn, ~city,
  "Jennie Edmundson Memorial Hospital DBA Methodist Jennie Edmundson",
  "JENNIE EDMUNDSON MEMORIAL HOSPITAL", "Methodist Jennie Edmundson", "160047", "COUNCIL BLUFFS",
  "Mercy Health Services - Iowa Corp DBA MercyOne North Iowa Medical Center",
  "MERCY HEALTH SERVICES-IOWA CORP", "MercyOne North Iowa Medical Center", "160064", "MASON CITY",
  "Central Iowa Hospital Corporation DBA UnityPoint Health - Des Moines",
  "CENTRAL IOWA HOSPITAL CORPORATION", "UnityPoint Health - Des Moines", "160082", "DES MOINES",
  "Catholic Health Initiatives - Iowa Corp DBA MercyOne Des Moines Medical Center",
  "CATHOLIC HEALTH INITIATIVES-IOWA CORP", "MercyOne Des Moines Medical Center", "160083", "DES MOINES"
)

IAR2_SENTENCES <- c(
  title = "Request for Proposal Title: Combat Cancer Health Hubs Round 2",
  rfp = "Request for Proposal Number: COMPADM26008",
  date = "DATE: August 12, 2026",
  intent = "announces its intent to award to the apparent successful bidder(s):",
  not_contract = "this Notice does NOT constitute the formation of a contract",
  footer = "as part of a financial assistance award totaling approximately $209,040,063.71 with 100 percent funded by CMS/HHS")

iar2_text <- function() {
  if (!identical(digest::digest(file = here::here(IAR2_PDF), algo = "sha256"), IAR2_SHA)) {
    stop("[IA R2] the archived notice's SHA-256 does not match MANIFEST.txt.", call. = FALSE)
  }
  stringr::str_squish(paste(rhtp_pdf_lines(here::here(IAR2_PDF))$text, collapse = " "))
}

iar2_key <- function(x) stringr::str_squish(toupper(gsub("[[:punct:]]", " ", x)))

iar2_assert <- function(t = iar2_text()) {
  for (k in names(IAR2_SENTENCES)) {
    if (!grepl(IAR2_SENTENCES[[k]], t, fixed = TRUE)) {
      stop("[IA R2] the '", k, "' sentence is not in the archived notice.", call. = FALSE)
    }
  }
  # The four bidders, as printed (the PDF wraps the fourth across a line).
  for (p in IAR2_BIDDERS$printed) {
    if (!grepl(p, t, fixed = TRUE)) stop("[IA R2] bidder not printed: ", p, call. = FALSE)
  }
  n_bullets <- lengths(regmatches(t, gregexpr("•", t)))
  bullets_before_footer <- lengths(regmatches(
    sub("This Combat Cancer Health Hub Program.*$", "", t), gregexpr("•", sub("This Combat Cancer Health Hub Program.*$", "", t))))
  if (bullets_before_footer != nrow(IAR2_BIDDERS)) {
    stop("[IA R2] the notice lists ", bullets_before_footer, " bidders, not ",
         nrow(IAR2_BIDDERS), ". Re-read it.", call. = FALSE)
  }
  # The only currency figure is the footer, and it is the ALLOTMENT (Tier 1).
  cur <- unique(stringr::str_extract_all(t, "\\$[0-9][0-9,.]*")[[1]])
  if (!identical(cur, "$209,040,063.71")) {
    stop("[IA R2] a currency figure besides the footer: ", paste(cur, collapse = ", "),
         " -- a per-recipient amount? Then REWRITE this file.", call. = FALSE)
  }
  if (!isTRUE(rhtp_assert_footer_not_allotment(IAR2_FOOTER, "IA", "STATE_ALLOTMENT",
                                               label = "IA COMPADM26008 footer"))) {
    stop("[IA R2] the footer no longer collides with the allotment.", call. = FALSE)
  }
  if (!(IAR2_DATE > IAR2_NOA && IAR2_DATE <= IAR2_BP1_END)) {
    stop("[IA R2] the notice is not dated inside Budget Period 1.", call. = FALSE)
  }
  # Every legal name is on the archived CMS IA hospital enrolment, with its CCN.
  j <- jsonlite::fromJSON(here::here(IAR2_FED))
  fed <- tibble::tibble(ccn = as.character(j$CCN), key = iar2_key(j$`ORGANIZATION NAME`))
  for (i in seq_len(nrow(IAR2_BIDDERS))) {
    hit <- fed[fed$key == iar2_key(IAR2_BIDDERS$legal[i]) & fed$ccn == IAR2_BIDDERS$ccn[i], ]
    if (!nrow(hit)) stop("[IA R2] CMS IA enrolment no longer carries ",
                         IAR2_BIDDERS$legal[i], " / CCN ", IAR2_BIDDERS$ccn[i], ".", call. = FALSE)
    if (!startsWith(iar2_key(IAR2_BIDDERS$printed[i]), iar2_key(IAR2_BIDDERS$legal[i]))) {
      stop("[IA R2] the printed legal name differs from the enrolment's: ",
           IAR2_BIDDERS$printed[i], call. = FALSE)
    }
  }
  invisible(TRUE)
}

iar2_build <- function() {
  iar2_assert()
  b <- IAR2_BIDDERS
  typed <- paste0(
    "TYPED (session 116): CMS Hospital Enrollments (", IAR2_FED, "): ", b$legal,
    " dba ", toupper(b$dba), ", CCN ", b$ccn, " (", b$city,
    ") -- the legal name Iowa prints before 'DBA', punctuation aside.")
  out <- tibble::tibble(
    state = "IA",
    row_no = seq_len(nrow(b)),
    awardee = b$dba,
    amount = NA_real_,
    recipient_type = "HOSPITAL_OR_SYSTEM",
    distributed_to_hospital = "Yes",
    note = paste0(
      "Printed as '", b$printed, "'. Iowa HHS Notice of Intent to Award, RFP ",
      IAR2_RFP, " Combat Cancer Health Hubs Round 2, dated 2026-08-12. THE NOTICE ",
      "PUBLISHES NO AMOUNT: its only dollar figure is the CMS footer, $209,040,063.71, ",
      "which is Iowa's ALLOTMENT (§0.2), so nothing is attributed to this row. It is ",
      "an INTENT: 'this Notice does NOT constitute the formation of a contract'."),
    recipient_confirmed = "Yes",
    amount_confirmed = "No",
    fiscal_year = "2026",
    source_document_title = paste0("Iowa HHS Notice of Intent to Award, RFP #", IAR2_RFP,
                                   " Combat Cancer Health Hubs Round 2"),
    state_source_url = IAR2_URL,
    validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
    extraction_method = "DIRECT_TEXT",
    validator = "R/03cs_ia_combat_cancer_r2_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    recipient_type_source = typed,
    determination_confidence = rhtp_confidence_ceiling("MEDIUM"),
    flag_reason = "AMOUNT_MISSING",
    award_pool = IAR2_RFP,
    budget_period = 1L,
    budget_period_text = "BP1 (12/29/2025 - 10/30/2026)",
    flow_type = "DIRECT",
    hospital_benefiting = "Yes",
    hospital_attribution = "NAMED_HOSPITAL",
    intermediary_name = NA_character_,
    determination_basis = paste0("§10.2 DIRECT: ", typed,
                                 " Named on a Notice of Intent to Award; no amount published."),
    amount_basis = paste(
      "Iowa publishes NO per-recipient amount. The notice's only dollar figure is its",
      "CMS footer, Iowa's allotment ($209,040,063.71, Tier 1), never attached to a",
      "recipient (§0.2, §6.2)."),
    round_name = "Combat Cancer Health Hubs Round 2",
    notice_date = as.character(IAR2_DATE),
    source_archive_path = IAR2_PDF,
    row_in_pool = seq_len(nrow(b)),
    basis_type = "ORG_WEBSITE",
    awardee_legal_name = b$legal,
    recipient_subtype = NA_character_,
    cms_enrolment_match = NA_character_,
    cms_enrolment_record = NA_character_)
  rhtp_assert_high_has_ccn(out, "IA R2")
  readr::write_csv(out, IAR2_OUT, na = "")
  message("[IA R2] wrote ", nrow(out), " intent rows at $0 to ", basename(IAR2_OUT),
          ". Now run R/07_summary_calls.R --apply.")
  invisible(out)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) {
    iar2_assert(); message("[IA R2] all assertions pass.")
  } else if ("--build" %in% args) {
    iar2_build()
  } else {
    message("Usage: Rscript R/03cs_ia_combat_cancer_r2_awardees.R [--validate | --build]")
  }
}

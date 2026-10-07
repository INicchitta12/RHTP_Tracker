# 03bz_ks_ebp_participants.R ---------------------------------------------------
#
# KANSAS'S EVIDENCE-BASED PRACTICE (EBP) PROGRAM: 94 NAMED PARTICIPATING
# HOSPITALS, AND NOT ONE OF THEM AN AWARD YET (session 95).
#
# WHAT THE PROGRAMME IS. KDHE's Year 1 budget narrative (Revision 2, archived
# under data/evidence/budget_narratives/KS/) says "KDHE will sub-award CCA to
# administer a $22M Infrastructure Assistance Fund" and budgets $11,000,000 of
# "Evidence-Based Practice Provider Incentive Payments" (Table 12.E.4). Both
# are TIER 2 plan lines; R/03o's disposition already carries them as budget
# lines, and neither is in any award file. CCA is the UKHS Care Collaborative
# Association, which runs the programme from ruralhealthkansas.com.
#
# WHAT IT PUBLISHES. The Care Collaborative's EBP page says "A complete list of
# hte rual hospitals participating in the EBP Program is available here" and
# links an xlsx, "EBP Program Participating Hospitals (9/18/2026)": 94 names.
# (A clinic list of 212 is linked beside it; this file carries hospitals only.)
#
# WHY THE LIST IS NOT AN AWARD LIST -- §10.2's pass-through test, applied:
#   1. An intermediary receives the funds: YES. CCA, on KDHE's sub-award.
#   2. The source names hospital subrecipients, or restricts the class to
#      hospitals: YES. The hospital stream is its own agreement, its own list,
#      and its own eligibility rule (KDHE-licensed rural hospitals, CAHs and
#      REHs; admin FAQ, 09-18).
#   3. AND THE AWARD HAS BEEN MADE: NOT SHOWN. A participant has signed an
#      agreement whose payments are CONDITIONAL. "Care Collaborative shall pay
#      Hospital One Hundred Thousand Dollars ($100,000) UPON Hospital's
#      submission of the signed and completed Attestation Form" (Agreement §2;
#      the attestation may arrive as late as 2027-10-01), and $50,000 "by
#      November 30, 2026, following confirmation of" Q3 2026 reporting (§3).
#      Every payment "is fully contingent on Care Collaborative's receipt of
#      RHT Program funds from the State" (§6). And the administrator itself
#      draws the line this file draws: "The Care Collaborative will post on its
#      website a list of providers that have RECEIVED infrastructure payments
#      and incentive payments" (admin FAQ). That list does not exist yet.
#
# So participation is ENROLMENT, the Maine and Missouri shape (§6.1 mode 3),
# and this file is a NON-AWARD file: never in STATE_FILES, no amount column,
# every row award_made = No. The formula ($100,000 + $50,000 per hospital) is
# carried as TEXT. 94 x $150,000 = $14,100,000 is a CEILING on the Year 1
# hospital stream if every participant qualifies, not a figure of anything
# paid, and it is written nowhere as a number.
#
# A CORRECTION TO THE BRIEF. Year 1's incentive is ONE payment of $50,000 for
# ONE quarter (July-September 2026), not "up to $50,000 per quarter". Later
# years are undefined: "the structure and operations of the EBP Program will
# change from year to year" (Agreement §5).
#
# THE LIST'S TITLE IS NOT A TYPING. "Ascension Medical Group via Christi, PA
# Wichita - Wellington" is on the hospital list and reads as a physician group.
# No row is typed here; Stage 5 owns that, against CMS enrolment.
#
# THE WATCH. R/03o's --probe (the KS Routine) reads this page live and trips
# when it links a document that is not a participant list, a FAQ or an
# agreement -- the payment list's arrival -- or says providers have "received"
# payments. When it trips, the payment list is the award source: extract it
# as an award file, one row per paid hospital, §10.2 PASS_THROUGH_DESIGNATED
# with intermediary_name = the Care Collaborative.
#
# CLI:
#   Rscript R/03bz_ks_ebp_participants.R --fetch [--force]
#   Rscript R/03bz_ks_ebp_participants.R --validate
#   Rscript R/03bz_ks_ebp_participants.R --build
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_page_watch.R"))
source(here::here("R", "utils_pdf_text.R"))

KSE_DIR <- file.path("data", "evidence", "KS", "ebp")
KSE_CSV <- here::here("data", "reference", "ks_ebp_participants.csv")
KSE_USER_AGENT <- paste("RHTP-Tracker/0.1 (AHA Data & Policy research;",
                        "+https://www.aha.org)")
KSE_PAGE_URL <- "https://ruralhealthkansas.com/evidence-based-practice-program/"
KSE_UP <- "https://ruralhealthkansas.com/wp-content/uploads/"
KSE_INTERMEDIARY <- "UKHS Care Collaborative Association"
KSE_N_HOSPITALS <- 94L
KSE_LIST_TITLE <- "EBP Program Participating Hospitals (9/18/2026)"

KSE_SOURCES <- tibble::tribble(
  ~key,          ~url,                                                              ~file,
  "page",        KSE_PAGE_URL,                                                      "2026-10-07_rhk_ebp_program_page.html",
  "hospitals",   paste0(KSE_UP, "2026/09/EBP-Program-Participating-Hospitals-9.18.2026.xlsx"), "2026-10-07_ebp_participating_hospitals_2026-09-18.xlsx",
  "clinics",     paste0(KSE_UP, "2026/09/EBP-Program-Participating-Clinics-9.18.2026.xlsx"),   "2026-10-07_ebp_participating_clinics_2026-09-18.xlsx",
  "admin_faq",   paste0(KSE_UP, "2026/09/09.18.2026-EBP-Administrative-FAQs.docx"),            "2026-10-07_ebp_administrative_faqs_2026-09-18.docx",
  "agreement",   paste0(KSE_UP, "2026/08/04.23.2026-Hospital-KS-EBP-Program-Participation-Agreement.docx"), "2026-10-07_ebp_hospital_participation_agreement_2026-04-23.docx",
  "faq_0601",    paste0(KSE_UP, "2026/06/06.01.2026-EBP-Program-FAQs.pdf"),                    "2026-10-07_ebp_program_faqs_2026-06-01.pdf"
)

# The sentences this file's conclusion rests on, each asserted verbatim in
# the archived document it comes from. Curly apostrophes are the documents'.
KSE_SENTENCES <- list(
  page = c(
    complete_list = "A complete list of hte rual hospitals participating in the EBP Program is available here",
    formula = "In Year 1, rural Kansas hospitals will receive $100,000, and rural Kansas clinics will receive $50,000 as infrastructure payments.",
    incentive = "rural hospitals will receive an additional $50,000 and rural clinics will receive an additional $25,000"),
  agreement = c(
    infrastructure = "Care Collaborative shall pay Hospital One Hundred Thousand Dollars ($100,000) upon Hospital’s submission of the signed and completed Attestation Form",
    incentive = "Care Collaborative shall pay Hospital Fifty Thousand Dollars ($50,000) by November 30, 2026, following confirmation of",
    contingent = "fully contingent on Care Collaborative’s receipt of RHT Program funds from the State",
    provenance = "under the federal Rural Health Transformation Program (“RHT Program”)"),
  admin_faq = c(
    paid_list = "The Care Collaborative will post on its website a list of providers that have received infrastructure payments and incentive payments.",
    eligible = "The following facilities are eligible to participate in the EBP Program as hospitals")
)

# Links the EBP page may carry without meaning anything has been paid. A NEW
# uploaded document matching none of these is the payment list's arrival.
KSE_ROUTINE_LINK <- paste0(
  "Participating-(Hospitals|Clinics)|FAQ|Participation-Agreement|",
  "favicon|\\.(png|jpe?g|svg|webp)$")
KSE_PAID_PHRASE <- paste0(
  "\\b(have|has) received (infrastructure|incentive|EBP|their)|",
  "\\bpayments? (have|has) been (made|issued|distributed)|",
  "\\b(list|roster) of (providers|hospitals)[^.]{0,40}\\bpaid\\b")

kse_source <- function(key, field) {
  row <- KSE_SOURCES[KSE_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[KS-EBP] unknown source key: ", key, call. = FALSE)
  row[[field]]
}
kse_path <- function(key) here::here(KSE_DIR, kse_source(key, "file"))


# -- archive ------------------------------------------------------------------

#' Archive the six sources. The page goes through rhtp_watch_archive() (its
#' Divi theme carries a rotating `et_frontend_nonce` inside a script, which the
#' reduction drops); the five documents are written verbatim. Every line goes
#' in one MANIFEST, digest first.
kse_fetch <- function(force = FALSE) {
  dir.create(here::here(KSE_DIR), recursive = TRUE, showWarnings = FALSE)
  man <- here::here(KSE_DIR, "MANIFEST.txt")
  for (i in seq_len(nrow(KSE_SOURCES))) {
    k <- KSE_SOURCES$key[i]; u <- KSE_SOURCES$url[i]
    dest <- file.path(KSE_DIR, KSE_SOURCES$file[i])
    if (file.exists(here::here(dest)) && !force) {
      message("[KS-EBP] cached, not re-fetched: ", basename(dest)); next
    }
    if (i > 1L) Sys.sleep(2)
    if (identical(k, "page")) {
      rhtp_watch_archive(u, dest, KSE_USER_AGENT, manifest = man)
      next
    }
    raw <- rhtp_watch_fetch(u, KSE_USER_AGENT)
    writeBin(raw, here::here(dest))
    cat(paste(digest::digest(raw, algo = "sha256", serialize = FALSE),
              basename(dest), u,
              format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sep = "  "),
        "\n", file = man, append = TRUE, sep = "")
    message("[KS-EBP] archived ", basename(dest), " (", length(raw), " bytes)")
  }
  invisible(TRUE)
}


# -- reading ------------------------------------------------------------------

kse_docx_text <- function(path) {
  tmp <- tempfile(); on.exit(unlink(tmp, recursive = TRUE))
  utils::unzip(path, files = "word/document.xml", exdir = tmp)
  x <- xml2::read_xml(file.path(tmp, "word", "document.xml"))
  paras <- xml2::xml_find_all(x, "//*[local-name()='p']")
  txt <- vapply(paras, function(p) {
    paste(xml2::xml_text(xml2::xml_find_all(p, ".//*[local-name()='t']")),
          collapse = "")
  }, "")
  stringr::str_squish(paste(txt[nzchar(txt)], collapse = "\n"))
}

kse_text <- function(key) {
  switch(key,
    page = rhtp_watch_reduce(kse_path("page")),
    agreement = kse_docx_text(kse_path("agreement")),
    admin_faq = kse_docx_text(kse_path("admin_faq")),
    stop("[KS-EBP] no text reader for ", key, call. = FALSE))
}

#' The 94 hospitals, as printed. Refuses a list whose title or count moved.
kse_hospitals <- function(path = kse_path("hospitals")) {
  x <- readxl::read_excel(path, col_names = FALSE, .name_repair = "minimal")
  v <- stringr::str_squish(as.character(x[[1]]))
  v <- v[!is.na(v) & nzchar(v)]
  if (!identical(v[1], KSE_LIST_TITLE)) {
    stop("[KS-EBP] the hospital list's title is ", sQuote(v[1]), ", not ",
         sQuote(KSE_LIST_TITLE), ". A new list: re-read it before building.",
         call. = FALSE)
  }
  v[-1]
}

kse_page_links <- function(raw) {
  doc <- xml2::read_html(raw)
  href <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  unique(href[grepl("/wp-content/uploads/", href, fixed = TRUE)])
}


# -- assertions ---------------------------------------------------------------

kse_assert <- function() {
  for (k in names(KSE_SENTENCES)) {
    t <- kse_text(k)
    for (nm in names(KSE_SENTENCES[[k]])) {
      if (!grepl(KSE_SENTENCES[[k]][[nm]], t, fixed = TRUE)) {
        stop("[KS-EBP] '", k, "' no longer carries '", nm, "': ",
             KSE_SENTENCES[[k]][[nm]], ". This file's conclusion rests on it; ",
             "re-read the document.", call. = FALSE)
      }
    }
  }
  h <- kse_hospitals()
  if (length(h) != KSE_N_HOSPITALS || anyDuplicated(h)) {
    stop("[KS-EBP] expected ", KSE_N_HOSPITALS, " distinct hospitals, read ",
         length(h), ".", call. = FALSE)
  }
  # The archived page links both lists it says are complete.
  links <- kse_page_links(kse_path("page"))
  for (k in c("hospitals", "clinics")) {
    if (!kse_source(k, "url") %in% links) {
      stop("[KS-EBP] the archived page does not link the ", k, " list.",
           call. = FALSE)
    }
  }
  # No payment list yet -- the condition the whole file rests on.
  kse_assert_no_payment_list(links, kse_text("page"), "archive")
  invisible(TRUE)
}

#' The tripwire, shared by the archive check and R/03o's live probe.
kse_assert_no_payment_list <- function(links, text, side = "live") {
  odd <- links[!grepl(KSE_ROUTINE_LINK, links, ignore.case = TRUE)]
  said <- regmatches(text, regexpr(KSE_PAID_PHRASE, text, ignore.case = TRUE,
                                   perl = TRUE))
  if (length(odd) || length(said)) {
    stop("[KS] the EBP page (", side, ") ",
         if (length(odd)) paste0("links a document that is not a participant ",
                                 "list, FAQ or agreement: ",
                                 paste(odd, collapse = " | "), ". ") else "",
         if (length(said)) paste0("says '", said, "'. ") else "",
         "The Care Collaborative said it would post 'a list of providers that ",
         "have received infrastructure payments and incentive payments'. If ",
         "this is that list, it is the EBP AWARD SOURCE: extract it as an award ",
         "file (§10.2 PASS_THROUGH_DESIGNATED via the Care Collaborative). ",
         "THAT IS THE SIGNAL, NOT A DEFECT.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- build --------------------------------------------------------------------

kse_build <- function() {
  kse_assert()
  h <- kse_hospitals()
  out <- tibble::tibble(
    state = "KS",
    row_no = seq_along(h),
    organization = h,
    participant_list = KSE_LIST_TITLE,
    programme = "Evidence-Based Practice (EBP) Program, Kansas RHT Plan Initiative 4, Program 1",
    intermediary_name = KSE_INTERMEDIARY,
    award_made = "No",
    payment_confirmed = "No",
    amount_published = "No",
    program_terms_text = paste(
      "Formula, not an award: $100,000 infrastructure payment 'upon' a signed",
      "Attestation Form (deadline as late as 2027-10-01) plus a $50,000",
      "incentive 'by November 30, 2026' for July-September 2026 reporting",
      "(Hospital Participation Agreement §§2-3); every payment 'fully",
      "contingent' on the Care Collaborative receiving RHT funds (§6)."),
    flow_test = paste(
      "§10.2 PASS_THROUGH_DESIGNATED NOT MET (session 95): intermediary YES",
      "(KDHE sub-award to the Care Collaborative); hospitals named YES; award",
      "made NOT SHOWN -- this is an ENROLMENT list, and the administrator will",
      "post a separate list of providers that 'have received' payments."),
    note = paste(
      "NOT AN AWARD (§0.3, §6.1 mode 3). Listed under the administrator's",
      "hospital heading; not typed here (Stage 5). Never in STATE_FILES."),
    source_document_title = KSE_LIST_TITLE,
    source_url = kse_source("hospitals", "url"),
    source_archive_path = file.path(KSE_DIR, kse_source("hospitals", "file")),
    basis_type = "ORG_WEBSITE"
  )
  stopifnot(!"amount" %in% names(out), nrow(out) == KSE_N_HOSPITALS)
  readr::write_csv(out, KSE_CSV, na = "")
  message("[KS-EBP] wrote ", nrow(out), " participating hospitals (NOT awards) to ",
          basename(KSE_CSV))
  invisible(out)
}


if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) {
    kse_fetch(force = "--force" %in% args)
  } else if ("--validate" %in% args) {
    kse_assert(); message("[KS-EBP] all assertions pass.")
  } else if ("--build" %in% args) {
    kse_build()
  } else {
    message("Usage: Rscript R/03bz_ks_ebp_participants.R ",
            "[--fetch [--force] | --validate | --build]")
  }
}

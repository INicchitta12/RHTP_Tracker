# 03r_ne_year1_awardees.R -----------------------------------------------------
# Nebraska Year 1 -> data/reference/ne_year1_awardees.csv
#
# WHY NEBRASKA. It led `state_trigger_queue.csv` after Maryland was worked out
# -- 39 Tier 3 candidates, 35 distinct awardees, a $218,529,075 allotment, no
# CMS press release, and no session had ever looked at it.
#
# WHAT NEBRASKA PUBLISHES. THREE signed "Public Notice of Award" PDFs, linked
# from DHHS's own Rural Health Transformation page:
#
#   Initiative 3.3  Rural Health Care Workforce Incentive & Sustainability
#                                          9 awards   $ 1,852,376.73
#   Initiative 4.4a Chronic Disease Navigation and Education
#                                         24 awards   $ 6,594,460.94
#   Initiative 4.4b Remote Patient Monitoring in Facilities and at Home
#                                         24 awards   $27,690,777.23
#   ------------------------------------------------------------------
#                                         57 awards   $36,137,614.90
#
# These are AWARDS, not offers and not intents. Each PDF says "The following
# have been selected for award for the Request for Application which closed
# <date>", which is §7's `NOTICE_OF_AWARD` on its own terms -- the strongest
# source type in the vocabulary, and the first state since Georgia's signed
# notices to reach it.
#
# THE TEXAS CHECK (§6.2), RUN FIRST AND PASSED -- AND NEBRASKA IS THE STATE
# WHERE IT NEARLY MATTERED. DHHS's Office of Procurement and Grants publishes
# "Intent to Award" notices for MANY grant series, RHTP and otherwise, in one
# document library and one page. Two of them were read directly to establish
# that the series is mixed rather than assuming it:
#
#   RFA 5965  SNAP Employment and Training -- intents to award running from
#             January 2025 to June 2026, i.e. STRADDLING the NOA date. This is
#             the dangerous one, because RHTP Initiative 3.3 is ITSELF a SNAP
#             E&T start-up programme, so the two series share a subject.
#   RFA R6251 2026 Non-Embryonic Stem Cell Research Grants -- nothing to do
#             with rural health at all.
#
# So "DHHS published an Intent to Award" is not evidence of RHTP, and the file
# does not treat it as such. What IS evidence is on every one of the three
# award PDFs and on the programme page: the CMS financial-assistance footer,
# naming the awarding agency and the exact award --
#
#   "supported by ... the Centers for Medicare & Medicaid Services (CMS) ...
#    as part of a financial assistance award totaling $218,529,075.01 with 100
#    percent funded by CMS/US HHS"
#
# -- which matches `cms_fy2026_allotments.csv` to the dollar.
# `ne_assert_rhtp_funded()` requires it on all four documents, every run.
#
# AND THE DATES. Every RFA behind these awards closed AFTER Nebraska's CMS
# Notice of Award (2025-12-29, `cms_state_noa_dates.csv`): 2026-03-27, -04-01,
# -04-24, -05-01, -06-01 and -07-10, read out of the archived PDFs rather than
# typed here. `ne_assert_after_noa()` requires it. The negative control is
# archived beside them: RFA 4533 NHAP Legal Services, which says in its own
# words that DHHS is "awarding state funds" and closed 2025-05-21, SEVEN MONTHS
# before Nebraska had the RHTP money. That is Texas's HHS0015180 in Nebraska,
# and `ne_assert_non_rhtp_control()` pins both halves -- state funds, pre-NOA.
#
# THE POSITIVE CONTROL, WHICH IS WHAT MAKES THE REST OF THE ANSWER MEAN
# ANYTHING. Nebraska is running NINETEEN initiative rows on its RFA timeline
# table and has published awardees for THREE. On its own "we found no other
# roster" is indistinguishable from "we looked for the wrong string", so the
# check is not that strings are absent: the table's last column carries an
# "Awardees" LINK exactly where a roster exists, and `ne_assert_award_index()`
# asserts all three links present and pointing at the PDFs this file parses.
# It is a tripwire in BOTH directions -- it fails if a known link disappears
# (a redesign that renamed them would otherwise turn every future run silently
# green) and fails if a FOURTH appears, because at that point Nebraska has
# published a pool this file does not carry. The link list was corroborated
# independently by probing the thirteen other initiative slots at the same URL
# shape: all thirteen 404, all three known ones 200.
#
# §0.1 -- WHAT RCJ GOT WRONG, AND IT IS THE OPPOSITE OF TEXAS. RCJ holds 39
# Nebraska Tier 3 candidates. They decompose EXACTLY, and `ne_assert_rcj_
# disposition()` requires the arithmetic to close to the cent:
#
#   24 rows  $6,594,460.94  Initiative 4.4a's AWARD list -- but filed by RCJ
#                           under the document title "Organizations Submitted
#                           Applications for RHTP RFA Closing March 27, 2026".
#    9 rows  $1,852,376.73  Initiative 3.3's award list. Correctly titled.
#    5 rows  $         5    Initiative 3.3 intent-to-award rows, $1 placeholders,
#                           duplicating five of the nine awards above.
#    1 row   $         1    Nebraska Lawyers Foundation -- NOT RHTP. See below.
#   --------------------------------------------------------------------------
#   39 rows  $8,446,843.67  = `rcj_state_survey.csv`'s own figure for Nebraska.
#
# The 24 are the finding. Nebraska's 4.4a notice carries the award list on page
# 1 and, on pages 2-3, a separate roster headed "The following organizations
# submitted applications for the aforementioned Request for Application" --
# about 115 names, most of which were NOT awarded. RCJ captured the AMOUNTS
# from page 1 and the TITLE from page 2. That is the page-text-as-title defect
# §0.1 names, and here it cuts the way no previous state's did: read at face
# value it would have caused a DEFLATION, not an inflation -- twenty-four real
# hospital and clinic awards discarded as mere applications. The opposite
# mistake is available in the same document and is worse: treating pages 2-3 as
# recipients would invent ~115 awards out of an applicant list, which is §0.3
# exactly. `ne_assert_applicants_not_awarded()` holds both edges -- the
# applicant section must still be present, and no applicant-only name may enter
# the award rows.
#
# And RCJ holds NOT ONE of Initiative 4.4b's 24 awards -- $27,690,777.23, more
# than three quarters of everything Nebraska has published, including the
# single largest award in the state. That is Kansas's lesson again (read the
# programme page's LINK LIST, not its prose), and it is why the positive
# control above is the load-bearing part of this file.
#
# THE NEBRASKA LAWYERS FOUNDATION ROW, AND WHY IT IS DISPOSED OF RATHER THAN
# EXTRACTED. It is on none of the three award notices. Its RCJ source document
# is titled bare "Intent to Award" with no RHTP identifier, and the programme
# it belongs to is NHAP -- the Nebraska Homeless Assistance Program -- whose
# own solicitation, RFA 4533, is archived here and says DHHS is "awarding state
# funds". State money, and a solicitation that closed before the state had the
# federal money. `ne_rcj_candidate_disposition.csv` records it with the
# disqualifying sentence, following Texas's precedent.
#
# THE NEBRASKA HIGH VALUE NETWORK, AND THE ONE ROW THAT NEEDED A NEW CODE.
# Initiative 4.4b's largest award is $18,156,856.12 to the Nebraska High Value
# Network, which the notice marks with a dagger and explains: "Nebraska High
# Value Network is a collaborative network. The list of individual hospitals
# receiving funding as of the time of this notice follows." Twenty-one hospitals
# are then named. §10.2's `PASS_THROUGH_DESIGNATED` test is met on both clauses
# -- the award is MADE, and the source NAMES hospital subrecipients -- so
# `distributed_to_hospital = Yes` with `intermediary_name` populated.
#
# But the existing `hospital_attribution` vocabulary could not describe it
# honestly. `NAMED_HOSPITAL` is false: DHHS publishes no per-hospital split, so
# nobody can say what any one of the twenty-one received, and §6.2 forbids
# dividing. `POOL_UNNAMED_HOSPITALS` -- Illinois/ICAHN's code -- is also false,
# and in the more damaging direction: it asserts no hospital is named when
# twenty-one are, on the record, in the award document. So
# `POOL_NAMED_HOSPITALS` was added to §8 deliberately, with full notes in
# `vocabularies.csv`, as the fourth such addition this project has made. It is
# a THIRD bucket in `rhtp_hospital_dollar_partition()` and it is never added to
# either of the other two.
#
# The twenty-one hospitals are carried as their own rows with an EMPTY `amount`
# -- Georgia's device for its seven un-priced AHEAD hospitals, and §6.2's rule
# that a figure is never divided. No sum over `amount` can double-count them.
# Their `recipient_type` is the one place in this file where organisational
# form is STATED rather than derived, because DHHS's own sentence calls them
# "individual hospitals". Jefferson Community Health and Life is on that roster
# AND holds its own $446,741.33 direct 4.4b award; the notice says so itself,
# in a parenthesis -- "will not be awarded over the maximum allowable amount,
# as they were awarded individually" -- so the state has already told us not to
# add the two, and `ne_assert_nhvn()` pins the overlap rather than silently
# de-duplicating it.
#
# WHERE THE HOSPITAL FIGURE IS SOFT, STATED WHERE IT CANNOT BE MISSED. This is
# Kansas's and Maryland's shape a third time: DHHS publishes a recipient and an
# amount and NOTHING about the recipient's organisational form -- no column of
# the kind Oregon and Alaska both have. So outside the twenty-one NHVN rows,
# every `recipient_type` is derived from the recipient's own NAME, and 31 of
# the 57 award rows fall to §8's standing fallback. Several of those read as
# hospitals to anyone who knows Nebraska -- the four CHI Health entities, Mary
# Lanning Healthcare, Methodist Fremont Health, Faith Health -- and several
# plainly are not. NOTHING WAS PROMOTED (§0.4), because promoting on this
# pipeline's own knowledge is the failure the project exists to avoid, and
# because §2 forbids letting a fuzzy hospital match auto-resolve: the 4.4b
# roster names "Jefferson Community Health and Life" where the award table says
# "Jefferson Community Health & Life", and "Memorial Health Care Systems" where
# 4.4a says "Memorial Health Care System". Those are one-character differences
# across two documents, which is exactly the match a human is supposed to make.
# The question is queued as `NE_RECIPIENT_FORM_NOT_STATED` in
# `classification_review_queue.csv`, with the 4.4b roster named in it as the
# evidence a reviewer should start from, and `ne_assert_form_not_stated_queued()`
# asserts the row, its dollars and its options every run.
#
# THE NEBRASKA HOSPITAL ASSOCIATION DOES NOT APPEAR, AND THAT IS A FINDING.
# NHA is named as a subrecipient in Nebraska's CMS project abstract and sits in
# `abstract_named_organizations.csv` as `CANDIDATE_ONLY` (§4.1). It is on NONE
# of the three notices of award, so §10.2's hospital-association branch does
# not fire on any Nebraska row and no association dollar enters any total.
# `ne_assert_nha_absent()` holds that, and will fail the day DHHS awards NHA --
# at which point the §10.2 rule and its `IN_KIND_BENEFIT` carve-out are what
# decide the row, on what the document says the money DOES.
#
# §0.3a FIRES TWICE ON THE TIMELINE AND NEITHER IS AN AWARD ROW. Initiative 1.1
# School Kitchen Modernization and 1.3 Farm-to-School are both released through
# "Interagency agreement with the Department of Education", which is §10.2's
# own worked `NON_HOSPITAL` example -- judge the recipient, not the activity.
# Neither has published an awardee list, so neither is in this file at all.
#
# Usage:
#   Rscript R/03r_ne_year1_awardees.R --fetch     # archive 6 sources + SHA-256
#   Rscript R/03r_ne_year1_awardees.R --validate  # assertions, offline
#   Rscript R/03r_ne_year1_awardees.R --build     # writes CSV + xlsx
#   Rscript R/03r_ne_year1_awardees.R --report    # the pools, and the soft edge

suppressPackageStartupMessages({
  library(dplyr)
  library(openxlsx)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
# For rhtp_load_allotments() -- the §7.1 CMS anchor, read through the same
# reader Stage 2 uses so the two cannot disagree about Nebraska's allotment.
source(here::here("R", "02_normalize.R"))
source(here::here("R", "utils_recipient_classification.R"))

NE_STATE        <- "NE"
NE_EVIDENCE_DIR <- here::here("data", "evidence", "NE")
NE_CSV          <- "data/reference/ne_year1_awardees.csv"
NE_DISPOSITION_CSV <- "data/reference/ne_rcj_candidate_disposition.csv"
NE_XLSX         <- "NE_year1_awardees.xlsx"
NE_HOST_THROTTLE_S <- 3
NE_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

NE_BASE      <- "https://dhhs.ne.gov"
NE_DOC_BASE  <- paste0(NE_BASE, "/Documents/")
NE_GRANT_DOC_BASE <- paste0(NE_BASE, "/Grants%20and%20Contract%20Opportunity%20Docs/")

NE_SOURCES <- tibble::tribble(
  ~key,           ~url,                                                              ~file,                                       ~doc_title,
  "program_page", paste0(NE_BASE, "/Pages/Rural-Health-Transformation.aspx"),        "2026-08-31_ne_dhhs_rhtp_program_page.html", "Rural Health Transformation | Nebraska Department of Health and Human Services",
  "grant_opps",   paste0(NE_BASE, "/Pages/Grant-Opportunities.aspx"),                "2026-08-31_ne_dhhs_grant_opportunities.html", "Grant Opportunities | Nebraska Department of Health and Human Services",
  "noa_3_3",      paste0(NE_DOC_BASE, "RHTP-Public-Notice-of-Award-3.3.pdf"),        "2026-08-31_ne_dhhs_public_notice_of_award_3.3.pdf",  "RHTP Initiative 3.3 Awards -- Rural Health Care Workforce Incentive and Sustainability Model",
  "noa_4_4a",     paste0(NE_DOC_BASE, "RHTP-Public-Notice-of-Award-4.4a.pdf"),       "2026-08-31_ne_dhhs_public_notice_of_award_4.4a.pdf", "RHTP Initiative 4.4a Awards -- Chronic Disease Navigation and Education",
  "noa_4_4b",     paste0(NE_DOC_BASE, "RHTP-Public-Notice-of-Award-4.4b.pdf"),       "2026-08-31_ne_dhhs_public_notice_of_award_4.4b.pdf", "RHTP Initiative 4.4b Awards -- Remote Patient Monitoring in Facilities and at Home",
  # The §6.2 NEGATIVE CONTROL. Not an RHTP document and archived precisely
  # because it is not: it is what a DHHS Office of Procurement and Grants
  # solicitation looks like when the money is the STATE's.
  "rfa_4533",     paste0(NE_GRANT_DOC_BASE, "RFA%204533%20%20NHAP%20Legal%20Services%20RFA%20FINAL.pdf"), "2025-04-22_ne_dhhs_rfa_4533_nhap_legal_services.pdf", "Request for Applications 4533 -- NHAP Legal Services (NOT RHTP; state funds)"
)

# Every figure below is quoted from a source archived under data/evidence/NE/
# and every one is asserted against the parse. They are the reconciliation and
# they are the tripwire: if DHHS republishes with a different count, the assert
# fails here rather than a wrong number reaching a workbook.
NE_STATED <- list(
  n_3_3   = 9L,   total_3_3  = 1852376.73,
  n_4_4a  = 24L,  total_4_4a = 6594460.94,
  n_4_4b  = 24L,  total_4_4b = 27690777.23,
  n_all   = 57L,  total_all  = 36137614.90,
  # The CMS financial-assistance footer, on all three notices and the
  # programme page. §7.1 has Nebraska at $218,529,075; DHHS prints the cents.
  cms_award_stated = "$218,529,075.01",
  cms_allotment    = 218529075,
  noa_date         = as.Date("2025-12-29"),
  # The Nebraska High Value Network, and the twenty-one hospitals it names.
  nhvn_amount      = 18156856.12,
  nhvn_members     = 21L,
  # RCJ, for §0.1 corroboration only. Never a published figure.
  rcj_candidates   = 39L,
  rcj_amount_sum   = 8446843.67,
  rcj_4_4a_rows    = 24L,
  rcj_3_3_rows     = 9L,
  rcj_placeholder_rows = 5L,
  rcj_non_rhtp_rows    = 1L,
  # The named-hospital floor and the uncertainty beside it. DHHS publishes no
  # organisation-type column, so every recipient_type outside the 21 NHVN
  # member rows is derived from the recipient's own NAME.
  #
  # The fallback count is scoped to rows whose form is BOTH unstated AND still
  # open. Thirty-one rows carry §8's fallback; the thirty-first is the Nebraska
  # High Value Network itself, and its dollars are NOT open in the same sense --
  # they are already attributed to hospitals under POOL_NAMED_HOSPITALS by
  # §10.2, on DHHS's own sentence, whatever NHVN's own corporate form turns out
  # to be. Folding its $18,156,856.12 into the "unresolved" figure would treble
  # the stated uncertainty by counting money the source has already placed.
  form_not_stated_n     = 30L,
  form_not_stated_total = 9411695.59,
  named_hospital_rows   = 41L,
  named_hospital_floor  = 6990996.01,
  pool_named_hospitals  = 18156856.12
)

# The RFA close dates DHHS prints on the three notices. Read out of the
# archived PDFs by ne_assert_after_noa(); listed here as what must be found,
# so a silently-changed document fails rather than passing with fewer.
NE_RFA_CLOSE_DATES <- as.Date(c(
  "2026-03-27",  # 4.4a
  "2026-04-01",  # 3.3, round 1
  "2026-04-24",  # 4.4b
  "2026-05-01",  # 3.3, round 2
  "2026-06-01",  # 3.3, round 3
  "2026-07-10"   # 3.3, community colleges
))

# The three award links that must be on the programme page, and the shape a
# fourth would take. See the header: this is the positive control.
NE_AWARD_LINK_FILES <- c(
  noa_3_3  = "RHTP-Public-Notice-of-Award-3.3.pdf",
  noa_4_4a = "RHTP-Public-Notice-of-Award-4.4a.pdf",
  noa_4_4b = "RHTP-Public-Notice-of-Award-4.4b.pdf"
)
NE_AWARD_LINK_SHAPE <- "(?i)notice[- ]of[- ]award|awardee|award recipients"

# The sentence that ties Nebraska's subawards to CMS RHTP money, printed by
# DHHS on every award notice. §6.2's first question, answered by the awarding
# agency on the award document itself.
NE_CMS_SENTENCE <- paste(
  "as part of a financial assistance award totaling \\$218,529,075.01",
  "with 100 percent funded by CMS"
)

# The §6.2 negative control's two halves, quoted from RFA 4533.
NE_NON_RHTP_SENTENCE   <- "awarding state funds"
NE_NON_RHTP_CLOSE_DATE <- as.Date("2025-05-21")

# The open classification question, in data/reference/classification_review_queue.csv.
NE_FORM_NOT_STATED_QUESTION <- "NE_RECIPIENT_FORM_NOT_STATED"

# The intermediary in §10.2's pass-through branch, and DHHS's own sentence
# about it. Quoted, not paraphrased -- it is what makes the row Yes.
NE_NHVN_NAME <- "Nebraska High Value Network"
NE_NHVN_SENTENCE <- paste(
  "Nebraska High Value Network is a collaborative network. The list of",
  "individual hospitals receiving funding as of the time of this notice follows."
)

NE_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch --------------------------------------------------------------------

ne_source <- function(key, field) {
  row <- NE_SOURCES[NE_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NE] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

ne_path <- function(key) file.path(NE_EVIDENCE_DIR, ne_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
ne_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(NE_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, NE_CREDENTIAL_SHAPES[[nm]])) {
      stop("[NE] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Archive the six Nebraska sources verbatim, with a SHA-256 manifest
ne_fetch <- function(force = FALSE) {
  dir.create(NE_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(NE_SOURCES)), function(i) {
    src  <- NE_SOURCES[i, ]
    dest <- file.path(NE_EVIDENCE_DIR, src$file)

    if (file.exists(dest) && !force) {
      # §9.5: a re-run must never re-fetch an unchanged document.
      message("[NE] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(NE_HOST_THROTTLE_S)
      message("[NE] fetching ", src$url)
      resp <- httr::GET(src$url, httr::user_agent(NE_USER_AGENT),
                        httr::timeout(180))
      if (httr::status_code(resp) != 200L) {
        stop("[NE] HTTP ", httr::status_code(resp), " for ", src$url,
             call. = FALSE)
      }
      served <- httr::content(resp, as = "raw")
      ne_assert_credential_free(served, src$file)
      writeBin(served, dest)
    }

    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      fetched_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
    )
  })

  ne_write_manifest(entries)
  entries
}

ne_write_manifest <- function(entries) {
  path <- file.path(NE_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Nebraska DHHS -- RHTP Year 1 notices of award, and one negative control",
    "Archived by R/03r_ne_year1_awardees.R --fetch",
    paste0("User-agent: ", NE_USER_AGENT),
    "",
    "All six files are the body the server sent, BYTE FOR BYTE. None carries a",
    "third-party credential; the guard that caught CMS's Mapbox token,",
    "Illinois's and Oregon's, and Kansas's Google Maps key runs on every fetch",
    "here and finds nothing, so there is no reduction to explain. Files are",
    "written with writeBin(), so re-hashing a file on disk reproduces its",
    "digest below.",
    "",
    "RFA 4533 (NHAP Legal Services) IS NOT AN RHTP DOCUMENT. It is archived",
    "deliberately, as the §6.2 negative control: DHHS's Office of Procurement",
    "and Grants publishes Intent to Award notices for many grant series, and",
    "this one says in its own words that the department is 'awarding state",
    "funds'. Its applications closed 2025-05-21, seven months before Nebraska's",
    "CMS Notice of Award. It is why an 'Intent to Award' from this office is",
    "not, by itself, evidence of RHTP.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes)  <- ", entries$url)
  ), path)
  invisible(path)
}


# -- the positive control, and §6.2 -------------------------------------------

ne_program_doc <- function(path = ne_path("program_page")) {
  if (!file.exists(path)) {
    stop("[NE] the programme page is not archived. Run --fetch.", call. = FALSE)
  }
  xml2::read_html(path)
}

ne_program_text <- function() {
  doc <- ne_program_doc()
  xml2::xml_remove(xml2::xml_find_all(doc, "//script|//style"))
  stringr::str_squish(xml2::xml_text(doc))
}

ne_pdf_text <- function(key) rhtp_pdf_text(ne_path(key))

#' THE POSITIVE CONTROL. Exactly three "Awardees" links, pointing at the three
#' PDFs this file parses -- no more and no fewer.
#'
#' Without this, "Nebraska has published no other roster" is indistinguishable
#' from "we searched for the wrong string". DHHS's RFA timeline table carries an
#' Awardees LINK in its last column exactly where a roster exists; the sixteen
#' other initiative rows carry a release date and no link, and each says why in
#' the same table (still open, "Early May", "Jun-26", an interagency agreement).
#' The assertion fails in BOTH directions, which is the half that matters: a
#' site redesign that renamed the links would otherwise turn every future run
#' silently green, and a FOURTH link means Nebraska has published a pool this
#' file does not carry.
#' @param path the archived programme page. An argument only so the tests can
#'   feed it a page with a link removed or a fourth added -- a control nobody
#'   can exercise is not a control.
ne_assert_award_index <- function(path = ne_path("program_page")) {
  doc <- ne_program_doc(path)
  hrefs <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  hrefs <- hrefs[!is.na(hrefs)]

  noa <- unique(hrefs[stringr::str_detect(
    hrefs, stringr::fixed("RHTP-Public-Notice-of-Award"))])

  expected <- unname(NE_AWARD_LINK_FILES)
  found <- vapply(expected, function(f) any(stringr::str_detect(
    noa, stringr::fixed(f))), logical(1))
  if (!all(found)) {
    stop("[NE] the programme page no longer links ",
         paste(expected[!found], collapse = ", "),
         ". The positive control is broken: either DHHS moved the roster, or ",
         "this file is now looking for the wrong thing. Re-read the page ",
         "before trusting any figure here.", call. = FALSE)
  }
  if (length(noa) != length(expected)) {
    stop("[NE] the programme page links ", length(noa),
         " notice-of-award PDFs, not ", length(expected),
         ". Nebraska has published a pool this file does not carry: ",
         paste(setdiff(basename(noa), expected), collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2's first question, answered by the awarding agency on the award document.
ne_assert_rhtp_funded <- function() {
  for (key in c("noa_3_3", "noa_4_4a", "noa_4_4b")) {
    txt <- stringr::str_squish(paste(ne_pdf_text(key), collapse = " "))
    if (!stringr::str_detect(txt, NE_CMS_SENTENCE)) {
      stop("[NE] ", key, " does not carry the CMS financial-assistance ",
           "footer naming ", NE_STATED$cms_award_stated,
           ". §6.2 is not satisfied and nothing here may be treated as RHTP ",
           "money.", call. = FALSE)
    }
  }
  page <- ne_program_text()
  if (!stringr::str_detect(page, NE_CMS_SENTENCE)) {
    stop("[NE] the programme page no longer carries the CMS ",
         "financial-assistance footer.", call. = FALSE)
  }
  # §7.1: DHHS prints cents, the CMS anchor does not. They must still agree.
  allotments <- rhtp_load_allotments()
  allot <- allotments$fy2026_allotment[allotments$state == NE_STATE]
  if (length(allot) != 1L || round(allot) != NE_STATED$cms_allotment) {
    stop("[NE] the §7.1 allotment anchor does not agree with DHHS's own ",
         "stated award.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every RFA behind these awards closed AFTER Nebraska's CMS Notice of Award.
#'
#' Read out of the archived PDFs rather than taken from this file's constants,
#' so a republished notice with a different date fails here.
ne_assert_after_noa <- function() {
  txt <- stringr::str_squish(paste(
    unlist(lapply(c("noa_3_3", "noa_4_4a", "noa_4_4b"), ne_pdf_text)),
    collapse = " "))
  # DHHS does not word this identically on every round: five of the six read
  # "selected for award for the Request for Application which closed <date>",
  # and Initiative 3.3's community-college round reads "selected for award
  # which closed <date>". Anchoring on the longer phrasing silently lost that
  # round's date -- and a date test that quietly tests five of six is worse
  # than none, so the anchor is the clause both share.
  found <- stringr::str_match_all(
    txt, "which closed\\s+([A-Z][a-z]+ \\d{1,2}, \\d{4})"
  )[[1]][, 2]
  found <- sort(unique(as.Date(found, format = "%B %d, %Y")))
  if (!length(found)) {
    stop("[NE] no RFA close date could be read from the three notices. The ",
         "§6.2 date test cannot be run, so it is not silently skipped.",
         call. = FALSE)
  }
  if (!setequal(found, NE_RFA_CLOSE_DATES)) {
    stop("[NE] the RFA close dates on the notices have changed: ",
         paste(format(found), collapse = ", "), call. = FALSE)
  }
  if (any(found <= NE_STATED$noa_date)) {
    stop("[NE] an RFA behind these awards closed on or before Nebraska's CMS ",
         "Notice of Award (", format(NE_STATED$noa_date), "). Nebraska did ",
         "not yet have the money, so the award cannot be RHTP (§6.2, ",
         "PROVENANCE_PREDATES_NOA).", call. = FALSE)
  }
  invisible(TRUE)
}

#' The §6.2 NEGATIVE control, which is what gives the positive one meaning.
#'
#' DHHS's Office of Procurement and Grants publishes Intent to Award notices
#' for many grant series. RFA 4533 is one of them and is NOT RHTP: state funds,
#' and closed seven months before Nebraska had the federal money. If this ever
#' stops being true the file's whole disposition of the Nebraska Lawyers
#' Foundation row is wrong, and it should fail rather than quietly stand.
ne_assert_non_rhtp_control <- function() {
  txt <- stringr::str_squish(paste(ne_pdf_text("rfa_4533"), collapse = " "))
  if (!stringr::str_detect(txt, stringr::fixed(NE_NON_RHTP_SENTENCE))) {
    stop("[NE] RFA 4533 no longer says DHHS is \"", NE_NON_RHTP_SENTENCE,
         "\". The negative control this file rests on is gone.", call. = FALSE)
  }
  if (stringr::str_detect(txt, "(?i)rural health transformation|RHTP")) {
    stop("[NE] RFA 4533 now mentions RHTP. It was archived as a NON-RHTP ",
         "control and can no longer play that role.", call. = FALSE)
  }
  closed <- stringr::str_match(
    txt, "closes on\\s+([A-Z][a-z]+ \\d{1,2}, \\d{4})")[, 2]
  closed <- as.Date(closed, format = "%B %d, %Y")
  if (is.na(closed) || closed != NE_NON_RHTP_CLOSE_DATE) {
    stop("[NE] RFA 4533's close date is not ",
         format(NE_NON_RHTP_CLOSE_DATE), call. = FALSE)
  }
  if (closed >= NE_STATED$noa_date) {
    stop("[NE] RFA 4533 no longer predates the CMS Notice of Award.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- the parse ----------------------------------------------------------------

#' One award line: a name, then a dollar amount, on the same text line.
#'
#' DHHS's notices are plain two-column tables and the reader returns them as
#' "<name>  $ <amount>". The anchor is deliberately the END of the line, so a
#' name containing a figure cannot be truncated at the first dollar sign.
ne_parse_award_lines <- function(key) {
  lines <- ne_pdf_text(key)
  m <- stringr::str_match(
    lines, "^\\s*(\\S.*?)\\s+\\$\\s*([0-9,]+\\.[0-9]{2})\\s*$")
  ok <- !is.na(m[, 1])
  tibble::tibble(
    awardee = stringr::str_squish(m[ok, 2]),
    amount  = as.numeric(gsub(",", "", m[ok, 3]))
  )
}

#' Initiative 4.4a's applicant roster -- pages 2-3, and NOT awards (§0.3).
#'
#' Returned so it can be asserted against, never so it can be extracted. This
#' is the list RCJ read the document's TITLE from.
ne_applicant_roster <- function() {
  lines <- ne_pdf_text("noa_4_4a")
  start <- grep("organizations submitted applications", lines,
                ignore.case = TRUE)
  if (length(start) != 1L) {
    stop("[NE] Initiative 4.4a's applicant section is not where it was. It is ",
         "the section RCJ mistook for the whole document, so its disappearance ",
         "is a change worth failing on, not a convenience.", call. = FALSE)
  }
  names <- lines[seq(start + 1L, length(lines))]
  names <- names[!stringr::str_detect(names, "^\\|?\\s*pg\\.|^\\s*$")]
  stringr::str_squish(names)
}

#' The Nebraska High Value Network's twenty-one member hospitals.
#'
#' Each printed "Name — City". Two entries wrap and one carries DHHS's own
#' parenthetical about Jefferson's separate individual award; both are rejoined
#' rather than dropped, because dropping a name is the failure mode that
#' silently shrinks a roster (§0.3, session 13).
ne_nhvn_roster <- function() {
  lines <- ne_pdf_text("noa_4_4b")
  start <- grep("list of individual hospitals receiving funding", lines,
                ignore.case = TRUE)
  if (length(start) != 1L) {
    stop("[NE] the 4.4b notice no longer carries the NHVN hospital roster. ",
         "$", format(NE_STATED$nhvn_amount, big.mark = ","), " would become ",
         "un-attributable, so this fails rather than quietly reporting a pool.",
         call. = FALSE)
  }
  tail_lines <- stringr::str_squish(lines[seq(start + 1L, length(lines))])
  tail_lines <- tail_lines[nzchar(tail_lines)]

  # DHHS's parenthetical about Jefferson is prose, not a roster entry. It is
  # kept as a NOTE on Jefferson's row rather than discarded.
  is_paren <- stringr::str_detect(tail_lines, "^\\(|^amount, as they were")
  paren <- paste(tail_lines[is_paren], collapse = " ")
  tail_lines <- tail_lines[!is_paren]

  # Rejoin a name whose city wrapped to the next line ("... —" / "Broken Bow").
  joined <- character(0)
  i <- 1L
  while (i <= length(tail_lines)) {
    line <- tail_lines[i]
    if (stringr::str_detect(line, "—\\s*$") && i < length(tail_lines)) {
      line <- paste(line, tail_lines[i + 1L])
      i <- i + 1L
    }
    joined <- c(joined, stringr::str_squish(line))
    i <- i + 1L
  }

  parts <- stringr::str_match(joined, "^(.+?)\\s*—\\s*(.+)$")
  if (anyNA(parts[, 1])) {
    stop("[NE] ", sum(is.na(parts[, 1])), " NHVN roster line(s) are not ",
         "\"Name — City\": ",
         paste(joined[is.na(parts[, 1])], collapse = " / "), call. = FALSE)
  }

  tibble::tibble(
    awardee = stringr::str_squish(parts[, 2]),
    city    = stringr::str_squish(parts[, 3]),
    note    = dplyr::if_else(
      stringr::str_detect(parts[, 2], "^Jefferson Community Health"),
      paste("Named on the Nebraska High Value Network roster AND holds a",
            "separate individual 4.4b award. DHHS's own note:", paren),
      NA_character_)
  )
}


# -- assertions on the parse --------------------------------------------------

ne_awards <- function() {
  pools <- tibble::tribble(
    ~key,       ~award_pool,
    "noa_3_3",  "Initiative 3.3 Rural Health Care Workforce Incentive and Sustainability Model",
    "noa_4_4a", "Initiative 4.4a Chronic Disease Navigation and Education",
    "noa_4_4b", "Initiative 4.4b Remote Patient Monitoring in Facilities and at Home"
  )
  purrr::map_dfr(seq_len(nrow(pools)), function(i) {
    ne_parse_award_lines(pools$key[i]) %>%
      dplyr::mutate(source_key = pools$key[i], award_pool = pools$award_pool[i])
  })
}

ne_assert_pools <- function(awards) {
  spec <- list(
    noa_3_3  = list(n = NE_STATED$n_3_3,  total = NE_STATED$total_3_3),
    noa_4_4a = list(n = NE_STATED$n_4_4a, total = NE_STATED$total_4_4a),
    noa_4_4b = list(n = NE_STATED$n_4_4b, total = NE_STATED$total_4_4b)
  )
  for (key in names(spec)) {
    got <- awards %>% dplyr::filter(.data$source_key == key)
    if (nrow(got) != spec[[key]]$n) {
      stop("[NE] ", key, " parsed ", nrow(got), " awards, expected ",
           spec[[key]]$n, call. = FALSE)
    }
    if (abs(sum(got$amount) - spec[[key]]$total) > 0.005) {
      stop("[NE] ", key, " sums to ", sprintf("%.2f", sum(got$amount)),
           ", expected ", sprintf("%.2f", spec[[key]]$total), call. = FALSE)
    }
  }
  if (nrow(awards) != NE_STATED$n_all) {
    stop("[NE] ", nrow(awards), " award actions, expected ", NE_STATED$n_all,
         call. = FALSE)
  }
  if (abs(sum(awards$amount) - NE_STATED$total_all) > 0.005) {
    stop("[NE] awards sum to ", sprintf("%.2f", sum(awards$amount)),
         ", expected ", sprintf("%.2f", NE_STATED$total_all), call. = FALSE)
  }
  # §6.2's allotment ceiling, on the state's own published total.
  if (sum(awards$amount) > NE_STATED$cms_allotment) {
    stop("[NE] Nebraska's published awards exceed its CMS allotment.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.3 IN BOTH DIRECTIONS, on one document.
#'
#' Initiative 4.4a's notice carries an award list AND an applicant list. RCJ
#' took the title from the second and the amounts from the first. Two things
#' must hold: the applicant section is still there (it is the evidence for the
#' §0.1 finding, and its disappearance would make this file's account of RCJ
#' unverifiable), and no name that appears ONLY in it may reach an award row.
ne_assert_applicants_not_awarded <- function(awards) {
  applicants <- ne_applicant_roster()
  if (length(applicants) < 80L) {
    stop("[NE] Initiative 4.4a's applicant roster reads as only ",
         length(applicants), " names. It is ~115 in the archived notice; a ",
         "short read here would understate the §0.1 finding.", call. = FALSE)
  }
  awarded_4_4a <- awards$awardee[awards$source_key == "noa_4_4a"]
  bled <- intersect(rhtp_ne_norm(applicants), rhtp_ne_norm(awarded_4_4a))
  # An awarded organisation is of course also an applicant, so overlap is
  # expected. What must NOT happen is an award row whose ONLY appearance in the
  # document is in the applicant section -- i.e. more award rows than the
  # notice's award table has.
  if (length(awarded_4_4a) != NE_STATED$n_4_4a) {
    stop("[NE] the 4.4a award table parsed ", length(awarded_4_4a),
         " rows; the applicant roster must never contribute one.",
         call. = FALSE)
  }
  invisible(length(bled))
}

#' Normalise a name for comparison ONLY. Never used to resolve a hospital
#' match: §2 forbids letting a fuzzy match auto-resolve, and this deliberately
#' does not collapse "System"/"Systems" or "&"/"and" (see the header).
rhtp_ne_norm <- function(x) {
  trimws(gsub("\\s+", " ", gsub("[^a-z0-9]+", " ", tolower(x))))
}

ne_assert_nhvn <- function(awards, roster) {
  nhvn <- awards %>%
    dplyr::filter(stringr::str_detect(.data$awardee,
                                      stringr::fixed(NE_NHVN_NAME)))
  if (nrow(nhvn) != 1L) {
    stop("[NE] expected exactly one Nebraska High Value Network award row, ",
         "got ", nrow(nhvn), call. = FALSE)
  }
  if (abs(nhvn$amount - NE_STATED$nhvn_amount) > 0.005) {
    stop("[NE] the NHVN award is ", sprintf("%.2f", nhvn$amount), ", expected ",
         sprintf("%.2f", NE_STATED$nhvn_amount), call. = FALSE)
  }
  if (nrow(roster) != NE_STATED$nhvn_members) {
    stop("[NE] the NHVN roster names ", nrow(roster), " hospitals, expected ",
         NE_STATED$nhvn_members, call. = FALSE)
  }
  txt <- stringr::str_squish(paste(ne_pdf_text("noa_4_4b"), collapse = " "))
  if (!stringr::str_detect(txt, stringr::fixed(
    "list of individual hospitals receiving funding"))) {
    stop("[NE] the sentence that makes the NHVN row a PASS_THROUGH_DESIGNATED ",
         "is gone from the notice.", call. = FALSE)
  }
  # DHHS's own instruction not to add Jefferson's two awards together. It is a
  # fact about the source and it is asserted, not silently de-duplicated.
  jefferson_direct <- awards %>%
    dplyr::filter(.data$source_key == "noa_4_4b",
                  stringr::str_detect(.data$awardee, "^Jefferson Community"))
  jefferson_member <- roster %>%
    dplyr::filter(stringr::str_detect(.data$awardee, "^Jefferson Community"))
  if (nrow(jefferson_direct) != 1L || nrow(jefferson_member) != 1L) {
    stop("[NE] Jefferson Community Health & Life no longer appears both as a ",
         "direct 4.4b awardee and on the NHVN roster. That overlap is the ",
         "double-count DHHS itself warned about; if it is gone, re-read the ",
         "notice.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The Nebraska Hospital Association is a CMS-abstract CANDIDATE_ONLY and has
#' NOT been awarded. §10.2's association branch therefore never fires here.
ne_assert_nha_absent <- function(recs) {
  hit <- recs %>%
    dplyr::filter(stringr::str_detect(.data$awardee,
                                      "(?i)nebraska hospital association"))
  if (nrow(hit) > 0L) {
    stop("[NE] the Nebraska Hospital Association now appears on a notice of ",
         "award (", nrow(hit), " row(s)). This file asserts its ABSENCE, so ",
         "the row has never been coded. Apply §10.2's hospital-association ",
         "branch and its IN_KIND_BENEFIT carve-out by hand: the test is what ",
         "the document says the money DOES, not what the organisation is.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.1. RCJ's 39 Nebraska candidates, accounted for to the cent.
ne_assert_rcj_disposition <- function(awards) {
  path <- here::here("data", "interim", "stage2_record_table.rds")
  if (!file.exists(path)) {
    message("[NE] stage2_record_table.rds absent; RCJ reconciliation skipped.")
    return(invisible(NULL))
  }
  rt <- readRDS(path)
  ne <- rt %>%
    dplyr::filter(.data$state == NE_STATE, .data$award_tier == "SUBAWARD",
                  is.na(.data$superseded_by))

  if (nrow(ne) != NE_STATED$rcj_candidates) {
    stop("[NE] RCJ now holds ", nrow(ne), " Tier 3 candidates, not ",
         NE_STATED$rcj_candidates, ". The disposition table no longer covers ",
         "the candidate set.", call. = FALSE)
  }
  if (abs(sum(ne$amount_announced, na.rm = TRUE) -
          NE_STATED$rcj_amount_sum) > 0.005) {
    stop("[NE] RCJ's Nebraska amount sum has moved.", call. = FALSE)
  }

  grp <- dplyr::case_when(
    stringr::str_detect(ne$source_doc_title,
                        "Organizations Submitted Applications") ~ "mislabelled_4_4a",
    stringr::str_detect(ne$source_doc_title,
                        stringr::fixed("RHTP Initiative 3.3 Awards")) ~ "awards_3_3",
    stringr::str_detect(ne$source_doc_title, "Initiative 3\\.3") ~ "placeholder_3_3",
    TRUE ~ "non_rhtp"
  )
  counts <- c(mislabelled_4_4a = NE_STATED$rcj_4_4a_rows,
              awards_3_3       = NE_STATED$rcj_3_3_rows,
              placeholder_3_3  = NE_STATED$rcj_placeholder_rows,
              non_rhtp         = NE_STATED$rcj_non_rhtp_rows)
  for (nm in names(counts)) {
    if (sum(grp == nm) != counts[[nm]]) {
      stop("[NE] RCJ disposition group ", nm, " holds ", sum(grp == nm),
           " rows, expected ", counts[[nm]], call. = FALSE)
    }
  }

  # The two award lists RCJ DID capture must reconcile to the cent against the
  # notices this file parses -- which is what proves the 24 are 4.4a's AWARDS
  # and not the applicant list RCJ titled them from.
  for (pair in list(c("mislabelled_4_4a", "noa_4_4a"),
                    c("awards_3_3", "noa_3_3"))) {
    rcj_sum <- sum(ne$amount_announced[grp == pair[1]], na.rm = TRUE)
    ours <- sum(awards$amount[awards$source_key == pair[2]])
    if (abs(rcj_sum - ours) > 0.5) {
      stop("[NE] RCJ's ", pair[1], " rows sum to ", sprintf("%.2f", rcj_sum),
           " against this file's ", sprintf("%.2f", ours), call. = FALSE)
    }
  }

  # And RCJ holds NONE of 4.4b. Stated as an identity rather than a search:
  # the four groups above exhaust all 39 rows, so there is no room for one.
  if (sum(grp == "non_rhtp") + sum(grp == "placeholder_3_3") +
      NE_STATED$rcj_4_4a_rows + NE_STATED$rcj_3_3_rows !=
      NE_STATED$rcj_candidates) {
    stop("[NE] RCJ's candidate groups no longer exhaust the candidate set.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- records ------------------------------------------------------------------

ne_records <- function() {
  awards <- ne_awards()
  ne_assert_pools(awards)
  ne_assert_applicants_not_awarded(awards)
  roster <- ne_nhvn_roster()
  ne_assert_nhvn(awards, roster)

  classified <- rhtp_classify_records(
    awards %>% dplyr::mutate(desc = .data$award_pool),
    state = NE_STATE, description_col = "desc")

  titles <- vapply(classified$source_key, function(k) ne_source(k, "doc_title"),
                   character(1), USE.NAMES = FALSE)
  urls   <- vapply(classified$source_key, function(k) ne_source(k, "url"),
                   character(1), USE.NAMES = FALSE)
  files  <- vapply(classified$source_key, function(k) ne_source(k, "file"),
                   character(1), USE.NAMES = FALSE)

  is_nhvn <- stringr::str_detect(classified$awardee,
                                 stringr::fixed(NE_NHVN_NAME))

  direct <- classified %>%
    dplyr::mutate(
      state = NE_STATE,
      note = .data$award_pool,
      # §10.2's pass-through branch, on the one row that meets both clauses:
      # the award IS made, and the source NAMES hospital subrecipients.
      flow_type = dplyr::if_else(is_nhvn, "PASS_THROUGH_DESIGNATED",
                                 .data$flow_type),
      distributed_to_hospital = dplyr::if_else(is_nhvn, "Yes",
                                               .data$distributed_to_hospital),
      hospital_benefiting = dplyr::if_else(is_nhvn, "Yes",
                                           .data$hospital_benefiting),
      determination_basis = dplyr::if_else(
        is_nhvn,
        paste("§10.2 PASS_THROUGH_DESIGNATED. DHHS's own note on the award:",
              NE_NHVN_SENTENCE,
              "Twenty-one hospitals are then named. The award is made and the",
              "subrecipients are named, so both clauses are met. No",
              "per-hospital split is published and none is invented (§6.2)."),
        .data$determination_basis),
      intermediary_name = dplyr::if_else(is_nhvn, NE_NHVN_NAME, NA_character_),
      # NHVN's dollars are attributable to hospitals DHHS has NAMED, but to no
      # ONE of them. Neither existing bucket says that; see the header.
      hospital_attribution_explicit = dplyr::if_else(
        is_nhvn, "POOL_NAMED_HOSPITALS", NA_character_),
      recipient_type_source = "DERIVED_FROM_NAME",
      nhvn_member_of = NA_character_,
      city = NA_character_
    )

  # The twenty-one NHVN hospitals, as their own rows with an EMPTY amount.
  # Georgia's device: the class and the names are confirmed, the per-recipient
  # figure is not published, and nothing is divided (§6.2).
  members <- roster %>%
    dplyr::transmute(
      awardee = .data$awardee,
      amount = NA_real_,
      source_key = "noa_4_4b",
      award_pool = "Initiative 4.4b Remote Patient Monitoring -- Nebraska High Value Network member hospitals",
      desc = .data$award_pool,
      state = NE_STATE,
      note = dplyr::coalesce(
        .data$note,
        paste0("Named by DHHS on the 4.4b notice of award as one of the ",
               "individual hospitals receiving funding through the Nebraska ",
               "High Value Network. City: ", .data$city, ".")),
      # THE ONE PLACE IN THIS FILE WHERE FORM IS STATED, NOT DERIVED. DHHS's
      # own sentence calls these organisations "individual hospitals".
      recipient_type = "HOSPITAL_OR_SYSTEM",
      # §7 reserves HIGH for a CCN match, which this project cannot yet do
      # (open blocker 5). The recipient is named and its form is stated by the
      # state, so MEDIUM -- not HIGH, and not LOW.
      determination_confidence = "MEDIUM",
      flow_type = "DIRECT",
      distributed_to_hospital = "Yes",
      hospital_benefiting = "Yes",
      classification_rule = "STATED_IN_SOURCE",
      determination_basis = paste(
        "Named on Nebraska DHHS's Initiative 4.4b notice of award under its",
        "own sentence:", NE_NHVN_SENTENCE,
        "The amount is deliberately EMPTY: DHHS publishes the network's",
        "$18,156,856.12 as one figure and no per-hospital split, and §6.2",
        "forbids dividing it."),
      flag_reason = "AMOUNT_MISSING",
      intermediary_name = NE_NHVN_NAME,
      hospital_attribution_explicit = "NAMED_HOSPITAL",
      recipient_type_source = "STATED_IN_SOURCE",
      nhvn_member_of = NE_NHVN_NAME,
      city = .data$city
    )

  all_rows <- dplyr::bind_rows(direct, members)

  titles <- vapply(all_rows$source_key, function(k) ne_source(k, "doc_title"),
                   character(1), USE.NAMES = FALSE)
  urls   <- vapply(all_rows$source_key, function(k) ne_source(k, "url"),
                   character(1), USE.NAMES = FALSE)
  files  <- vapply(all_rows$source_key, function(k) ne_source(k, "file"),
                   character(1), USE.NAMES = FALSE)

  all_rows %>%
    dplyr::mutate(
      row_no = dplyr::row_number(),
      # DHHS's own words: "The following have been selected for award".
      recipient_confirmed = "Yes",
      amount_confirmed = dplyr::if_else(is.na(.data$amount), "No", "Yes"),
      fiscal_year = "FY2026",
      source_document_title = titles,
      state_source_url = urls,
      validation_source_type = "NOTICE_OF_AWARD",
      extraction_method = "DIRECT_TEXT",
      validator = "AUTO",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      source_archive_path = file.path("data/evidence/NE", files),
      budget_period = "BP1",
      hospital_attribution = rhtp_hospital_attribution(
        .data$flow_type, .data$distributed_to_hospital, .data$recipient_type,
        .data$hospital_attribution_explicit)
    ) %>%
    dplyr::select(
      "state", "row_no", "awardee", "amount", "recipient_type",
      "distributed_to_hospital", "note", "recipient_confirmed",
      "amount_confirmed", "fiscal_year", "source_document_title",
      "state_source_url", "validation_source_type", "extraction_method",
      "validator", "ccn", "aha_id", "rural_designation", "reviewer",
      "recipient_type_source", "determination_confidence", "flag_reason",
      "award_pool", "budget_period", "flow_type", "hospital_benefiting",
      "hospital_attribution", "intermediary_name", "nhvn_member_of", "city",
      "determination_basis", "classification_rule", "source_archive_path"
    )
}


# -- validate -----------------------------------------------------------------

ne_validate <- function() {
  ne_assert_award_index()
  ne_assert_rhtp_funded()
  ne_assert_after_noa()
  ne_assert_non_rhtp_control()
  recs <- ne_records()
  ne_assert_nha_absent(recs)
  ne_assert_rcj_disposition(ne_awards())

  governed <- c(
    recipient_type           = "recipient_type",
    distributed_to_hospital  = "distributed_to_hospital",
    flow_type                = "flow_type",
    determination_confidence = "determination_confidence",
    validation_source_type   = "source_doc_type",
    extraction_method        = "extraction_method",
    validator                = "validator",
    recipient_confirmed      = "recipient_confirmed",
    amount_confirmed         = "amount_confirmed",
    hospital_benefiting      = "hospital_benefiting",
    hospital_attribution     = "hospital_attribution"
  )
  for (col in names(governed)) {
    allowed <- rhtp_vocabulary(governed[[col]])
    bad <- setdiff(stats::na.omit(unique(recs[[col]])), allowed)
    if (length(bad)) {
      stop("[NE] ", col, " outside §8 (", governed[[col]], "): ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  flags <- stats::na.omit(unique(recs$flag_reason))
  bad <- setdiff(flags, rhtp_vocabulary("flag_reason"))
  if (length(bad)) {
    stop("[NE] flag_reason outside §8: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }

  stopifnot(nrow(recs) == NE_STATED$n_all + NE_STATED$nhvn_members)
  priced <- recs %>% dplyr::filter(!is.na(.data$amount))
  stopifnot(nrow(priced) == NE_STATED$n_all, all(priced$amount > 0))
  if (abs(sum(priced$amount) - NE_STATED$total_all) > 0.005) {
    stop("[NE] priced rows sum to ", sprintf("%.2f", sum(priced$amount)),
         call. = FALSE)
  }
  # The twenty-one member rows must stay un-priced, or the $18.2M is counted
  # twice: once on NHVN's row and again across its members.
  members <- recs %>% dplyr::filter(!is.na(.data$nhvn_member_of))
  if (nrow(members) != NE_STATED$nhvn_members || !all(is.na(members$amount))) {
    stop("[NE] the NHVN member rows must carry NO amount (§6.2). Priced, they ",
         "would double-count the network's $",
         format(NE_STATED$nhvn_amount, big.mark = ","), ".", call. = FALSE)
  }
  ne_assert_form_not_stated_queued(recs)
  message("[NE] all assertions pass.")
  invisible(recs)
}

#' THE FIGURE IS A FLOOR AND THE UNCERTAINTY IS DISCLOSED WHERE SOMEONE WILL
#' FIND IT. Kansas's device, a third time.
#'
#' DHHS publishes no organisation-type column, so 31 of the 57 award rows take
#' §8's standing fallback. Nothing is promoted on this pipeline's own knowledge
#' (§0.4) and nothing is auto-resolved by name (§2). A caveat in a workbook
#' nobody opens is not a disclosure, so the question goes in
#' data/reference/classification_review_queue.csv and its presence is asserted
#' every run.
ne_assert_form_not_stated_queued <- function(recs) {
  # Scoped to the rows that are BOTH unstated and still open -- see NE_STATED.
  inferred <- recs %>%
    dplyr::filter(.data$determination_confidence == "LOW",
                  .data$flag_reason == "RECIPIENT_TYPE_INFERRED",
                  is.na(.data$intermediary_name))
  if (nrow(inferred) != NE_STATED$form_not_stated_n) {
    stop("[NE] ", nrow(inferred), " rows carry §8's recipient-form fallback; ",
         "expected ", NE_STATED$form_not_stated_n, call. = FALSE)
  }
  if (abs(sum(inferred$amount) - NE_STATED$form_not_stated_total) > 0.005) {
    stop("[NE] the unstated-form dollars are ",
         sprintf("%.2f", sum(inferred$amount)), ", expected ",
         sprintf("%.2f", NE_STATED$form_not_stated_total), call. = FALSE)
  }

  part <- rhtp_hospital_dollar_partition(recs)
  named <- part$dollars[part$bucket == "NAMED_HOSPITAL"]
  if (length(named) != 1L ||
      abs(named - NE_STATED$named_hospital_floor) > 0.005) {
    stop("[NE] the named-hospital floor has moved from ",
         format(NE_STATED$named_hospital_floor, big.mark = ","), ".",
         call. = FALSE)
  }
  # THE UNCERTAINTY IS LARGER THAN THE FIGURE, as in Kansas and Maryland. If
  # that ever stops being true the sentence this repository publishes about
  # Nebraska has to change.
  if (NE_STATED$form_not_stated_total <= NE_STATED$named_hospital_floor) {
    stop("[NE] the unstated-form dollars no longer exceed the named-hospital ",
         "floor. Re-word the finding before publishing it.", call. = FALSE)
  }
  queue_path <- here::here("data", "reference",
                           "classification_review_queue.csv")
  if (!file.exists(queue_path)) {
    stop("[NE] the classification review queue is missing.", call. = FALSE)
  }
  queue <- readr::read_csv(queue_path, show_col_types = FALSE,
                           progress = FALSE)
  row <- queue %>%
    dplyr::filter(.data$question_id == NE_FORM_NOT_STATED_QUESTION)
  if (nrow(row) != 1L || !identical(row$queue_status[[1]], "OPEN")) {
    stop("[NE] ", NE_FORM_NOT_STATED_QUESTION, " is not an OPEN row in ",
         "classification_review_queue.csv. A disclosure nobody can find is ",
         "not a disclosure.", call. = FALSE)
  }
  if (!grepl(format(NE_STATED$form_not_stated_total, big.mark = ",",
                    nsmall = 2),
             row$dollar_effect[[1]], fixed = TRUE)) {
    stop("[NE] the queued dollar effect does not state ",
         format(NE_STATED$form_not_stated_total, big.mark = ",", nsmall = 2),
         "; the queue and the data disagree.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- build / report -----------------------------------------------------------

ne_bucket <- function(part, bucket) {
  hit <- part[part$bucket == bucket, , drop = FALSE]
  if (nrow(hit) == 0L) 0 else sum(hit$dollars)
}

ne_build <- function() {
  recs <- ne_validate()
  readr::write_csv(recs, here::here(NE_CSV), na = "")
  message("[NE] wrote ", NE_CSV, " (", nrow(recs), " rows)")

  ne_write_disposition()

  part <- rhtp_hospital_dollar_partition(recs)

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "READ ME FIRST")
  openxlsx::writeData(wb, "READ ME FIRST", tibble::tibble(note = c(
    "NEBRASKA RHTP YEAR 1 -- NOTICES OF AWARD.",
    "",
    "These are AWARDS. Each of DHHS's three notices says \"The following have",
    "been selected for award for the Request for Application which closed",
    "<date>\", so every priced row is NOTICE_OF_AWARD with",
    "amount_confirmed = Yes. That is a stronger footing than Oregon's,",
    "Alaska's or Maryland's, all of which publish intents or offers.",
    "",
    "THREE POOLS, IN THREE DOCUMENTS. Read `award_pool` before using a figure.",
    paste0("  Initiative 3.3  Workforce Incentive     9 awards   $",
           format(NE_STATED$total_3_3, big.mark = ",", nsmall = 2)),
    paste0("  Initiative 4.4a Chronic Disease        24 awards   $",
           format(NE_STATED$total_4_4a, big.mark = ",", nsmall = 2)),
    paste0("  Initiative 4.4b Remote Monitoring      24 awards   $",
           format(NE_STATED$total_4_4b, big.mark = ",", nsmall = 2)),
    paste0("                                         57 awards   $",
           format(NE_STATED$total_all, big.mark = ",", nsmall = 2)),
    "",
    "SUMMING `amount` GIVES THE STATE'S PUBLISHED TOTAL, AND THE 21 EXTRA ROWS",
    "DO NOT DISTURB IT. The Nebraska High Value Network's $18,156,856.12 is",
    "ONE award to a collaborative network, and DHHS names the 21 individual",
    "hospitals receiving funding through it but publishes NO per-hospital",
    "split. Those 21 are carried as their own rows with an EMPTY amount, so",
    "they can be counted as hospitals without double-counting a dollar (§6.2).",
    "Jefferson Community Health & Life is on that roster AND holds its own",
    "$446,741.33 award; DHHS says in the notice not to add the two.",
    "",
    "DHHS PUBLISHES NO ORGANISATION TYPE. Outside the 21 rows above -- where",
    "DHHS's own sentence calls the organisations \"individual hospitals\" --",
    "every recipient_type is derived from the recipient's own NAME, and 31 of",
    "the 57 award rows take §8's standing fallback. Several of those read as",
    "hospitals to anyone who knows Nebraska (the CHI Health entities, Mary",
    "Lanning, Methodist Fremont, Faith Health). NOTHING WAS PROMOTED (§0.4).",
    "The question is queued as NE_RECIPIENT_FORM_NOT_STATED.",
    "",
    "THE NEBRASKA HOSPITAL ASSOCIATION IS NOT HERE. It is named in Nebraska's",
    "CMS project abstract as a subrecipient and is CANDIDATE_ONLY (§4.1); it",
    "is on none of the three notices of award, so no association dollar enters",
    "any total and §10.2's association branch never fires.",
    "",
    "NEBRASKA HAS SIXTEEN MORE INITIATIVE ROWS WITH NO PUBLISHED ROSTER. That",
    "absence is real, not unlooked-for: DHHS's RFA timeline table carries an",
    "\"Awardees\" link wherever a roster exists, and this file's positive",
    "control asserts all three present and refuses a fourth."
  )))

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", recs)
  openxlsx::freezePane(wb, "Awards", firstRow = TRUE)

  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", tibble::tibble(
    item = c("Initiative 3.3 -- awards",
             "Initiative 4.4a -- awards",
             "Initiative 4.4b -- awards",
             "All published awards",
             "CMS FY2026 allotment (§7.1)",
             "Published share of the allotment (%)",
             "Nebraska High Value Network (one award, 21 named hospitals)",
             "Hospital dollars -- NAMED_HOSPITAL",
             "Hospital dollars -- POOL_NAMED_HOSPITALS",
             "Hospital dollars -- POOL_UNNAMED_HOSPITALS",
             "Recipient form NOT STATED by DHHS (§8 fallback rows)",
             "RCJ Tier 3 candidates (§0.1, never a figure)"),
    value = c(NE_STATED$total_3_3, NE_STATED$total_4_4a, NE_STATED$total_4_4b,
              NE_STATED$total_all, NE_STATED$cms_allotment,
              round(100 * NE_STATED$total_all / NE_STATED$cms_allotment, 2),
              NE_STATED$nhvn_amount,
              ne_bucket(part, "NAMED_HOSPITAL"),
              ne_bucket(part, "POOL_NAMED_HOSPITALS"),
              ne_bucket(part, "POOL_UNNAMED_HOSPITALS"),
              NE_STATED$form_not_stated_total,
              NE_STATED$rcj_candidates)
  ))

  openxlsx::saveWorkbook(wb, here::here(NE_XLSX), overwrite = TRUE)
  message("[NE] wrote ", NE_XLSX)
  invisible(recs)
}

#' Why each of RCJ's 39 Nebraska candidates is, or is not, an RHTP award row.
#' Texas's precedent: the disposition is a committed table, not a comment.
ne_write_disposition <- function() {
  disp <- tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount, ~disposition, ~basis, ~state_document,
    "Initiative 4.4a awards, filed by RCJ under the applicant section's heading",
    NE_STATED$rcj_4_4a_rows, NE_STATED$total_4_4a, "RHTP_SUBAWARD_EXTRACTED",
    paste("The names and amounts are Initiative 4.4a's AWARD table, page 1 of",
          "the notice. RCJ took the document TITLE from pages 2-3, which are a",
          "separate roster of ~115 organisations that SUBMITTED APPLICATIONS.",
          "Read at face value the title would have discarded 24 real awards as",
          "applications (a deflation); read the other way round it would have",
          "invented ~115 awards from an applicant list (§0.3)."),
    "2026-08-31_ne_dhhs_public_notice_of_award_4.4a.pdf",

    "Initiative 3.3 awards", NE_STATED$rcj_3_3_rows, NE_STATED$total_3_3,
    "RHTP_SUBAWARD_EXTRACTED",
    "Correctly titled and correctly amounted by RCJ; reconciles to the cent.",
    "2026-08-31_ne_dhhs_public_notice_of_award_3.3.pdf",

    "Initiative 3.3 intent-to-award placeholders", NE_STATED$rcj_placeholder_rows, 5,
    "DUPLICATE_OF_EXTRACTED_AWARD",
    paste("Five rows carrying an amount of $1 each, duplicating five of the",
          "nine Initiative 3.3 awards above. They are the intent-to-award",
          "precursor of the same awards, not additional ones, and RCJ flags",
          "them AMOUNT_IMPLAUSIBLE_LOW itself."),
    "2026-08-31_ne_dhhs_public_notice_of_award_3.3.pdf",

    "Nebraska Lawyers Foundation", NE_STATED$rcj_non_rhtp_rows, 1,
    "NOT_RHTP_STATE_PROGRAM",
    paste("On none of the three RHTP notices of award. Its RCJ source document",
          "is titled bare \"Intent to Award\" with no RHTP identifier. The",
          "programme is NHAP -- the Nebraska Homeless Assistance Program --",
          "whose solicitation RFA 4533 says DHHS is \"awarding state funds\"",
          "and closed 2025-05-21, seven months before Nebraska's CMS Notice of",
          "Award of 2025-12-29. State money, and a solicitation that closed",
          "before the state had the federal money (§6.2)."),
    "2025-04-22_ne_dhhs_rfa_4533_nhap_legal_services.pdf"
  )
  readr::write_csv(disp, here::here(NE_DISPOSITION_CSV), na = "")
  message("[NE] wrote ", NE_DISPOSITION_CSV, " (", nrow(disp), " rows)")
  invisible(disp)
}

ne_report <- function() {
  recs <- ne_records()
  part <- rhtp_hospital_dollar_partition(recs)
  priced <- recs %>% dplyr::filter(!is.na(.data$amount))

  cat("\nNEBRASKA -- RHTP Year 1 notices of award\n")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(
    priced %>% dplyr::group_by(.data$award_pool) %>%
      dplyr::summarise(awards = dplyr::n(), dollars = sum(.data$amount),
                       .groups = "drop")), row.names = FALSE)
  cat("\nTotal: ", nrow(priced), " awards, $",
      format(sum(priced$amount), big.mark = ",", nsmall = 2), " -- ",
      round(100 * sum(priced$amount) / NE_STATED$cms_allotment, 1),
      "% of the CMS allotment\n", sep = "")

  cat("\nHospital dollars, PARTITIONED and never added (§10.2):\n")
  cat("  NAMED_HOSPITAL        : ",
      format(ne_bucket(part, "NAMED_HOSPITAL"), big.mark = ","),
      "  -- the row's own awardee is a named hospital\n")
  cat("  POOL_NAMED_HOSPITALS  : ",
      format(ne_bucket(part, "POOL_NAMED_HOSPITALS"), big.mark = ","),
      "  -- NHVN: 21 hospitals named, no per-hospital split published\n")
  cat("  POOL_UNNAMED_HOSPITALS: ",
      format(ne_bucket(part, "POOL_UNNAMED_HOSPITALS"), big.mark = ","), "\n")

  # Scoped exactly as ne_assert_form_not_stated_queued() and the review queue
  # scope it: rows whose form is unstated AND still open. The Nebraska High
  # Value Network also carries §8's fallback, but its dollars are already
  # attributed above and reporting them here would treble the figure by
  # counting money the source has placed.
  soft <- recs %>%
    dplyr::filter(.data$determination_confidence == "LOW",
                  .data$flag_reason == "RECIPIENT_TYPE_INFERRED",
                  is.na(.data$intermediary_name))
  cat("\nRECIPIENT FORM NOT STATED BY DHHS: ", nrow(soft), " rows, $",
      format(sum(soft$amount), big.mark = ",", nsmall = 2), "\n", sep = "")
  cat("  §8's standing fallback, and LARGER than the named-hospital floor\n")
  cat("  beside it -- Kansas's and Maryland's shape a third time. It runs\n")
  cat("  mainly UPWARD: the four CHI Health entities, Mary Lanning, Methodist\n")
  cat("  Fremont and Faith Health are $3,069,507.40 of it and read as\n")
  cat("  hospitals. Nothing promoted (§0.4), and nothing auto-matched by name\n")
  cat("  against the 4.4b roster (§2). The CCN match (blocker 5) resolves it.\n")
  cat("\nThe Nebraska Hospital Association is NOT on any notice of award.\n")
  invisible(recs)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(ne_fetch(force = "--force" %in% args))
  if ("--validate" %in% args) ne_validate()
  if ("--build" %in% args) ne_build()
  if ("--report" %in% args) ne_report()
  if (!any(c("--fetch", "--validate", "--build", "--report") %in% args)) {
    cat("Usage: Rscript R/03r_ne_year1_awardees.R [--fetch|--validate|--build|--report]\n")
  }
}

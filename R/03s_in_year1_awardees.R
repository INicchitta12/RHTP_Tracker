# 03s_in_year1_awardees.R -----------------------------------------------------
# Indiana Year 1 -> data/reference/in_year1_awardees.csv
#
# WHY INDIANA. It led `state_trigger_queue.csv` after Nebraska was worked out --
# queue rank 1, 37 Tier 3 candidates, 28 distinct awardees, a $206,927,897
# allotment, and no CMS press release, so no session had ever looked at it.
#
# WHAT INDIANA PUBLISHES, AND WHERE. Indiana brands RHTP as **GROW** (Growing
# Rural Opportunities for Well-being in Health) and runs it out of a dedicated
# site, `in.gov/grow-rural-health`, across ELEVEN initiatives. `in.gov/health`
# publishes no award list of its own -- IDOH's own front page links out to the
# GROW site for RHTP, which is the whole of its answer.
#
# But the GROW site NAMES ALMOST NOBODY. Its recipient-level awards are made
# through the Indiana Department of Administration's ordinary state procurement
# channel, and they are published on IDOA's "Solicitation Award Recommendations"
# page as one zipped PDF per solicitation. The GROW initiative pages are the
# INDEX into that channel: each carries a status table whose last column links
# either "View posting" (a solicitation) or "View award" (an award), which is
# Nebraska's award-index control in Indiana's own form.
#
#   RFP 26-87448  RHTP MOCC (Medical Operations Coordination Center)
#                   Patient Flow Innovations, Collaborative Fusion Inc,
#                   Communicare Technology                     3 recipients
#   RFP 26-87449  RHTP07 Teleconsult and Telehealth Landscape Assessment
#                   Laurel Health Advisors LLC          $860,088 (5-YEAR value)
#   RFP 26-87450  RHTP Program Evaluator
#                   Public Policy Associates LLC                1 recipient
#   RFP 26-87556  Preceptor Registry
#                   Concourse Tech Inc                          1 recipient
#   RFP 26-87667  ACO / Medicaid Alternate Payment Model Feasibility Study
#                   Deloitte Consulting LLP                     1 recipient
#   ---------------------------------------------------------------------------
#                   7 award actions, 7 distinct recipients, $860,088 published
#
# NOT ONE OF THE SEVEN IS A HOSPITAL, AND THAT IS THE HEADLINE FINDING FOR
# INDIANA. Every one is a consultancy or a technology company selected through a
# competitive RFP. Indiana's hospital money is NOT in this file, because Indiana
# has not awarded it yet -- see the GROW Regional Grants section below.
#
# THEY ARE "PRELIMINARY NOTICE - AWARD RECOMMENDATION" DOCUMENTS, WHICH IS
# WEAKER THAN EVERY OTHER STATE IN THIS REPOSITORY. Each says the State "will
# begin contract negotiations", that the recommendation "is conditioned upon
# successful finalization of contracts", that the State "may choose to withdraw
# this award recommendation", that "[o]nce contracts are finalized the State
# will issue a final Notice of Award", and it quotes I.C. 4-13-1-19: "[a] bidder
# or an offeror does not gain a property interest in the award of a contract by
# the department unless the bidder or offeror is awarded the contract, and the
# contract is completely executed." So every row is
# `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No`, which is Oregon's and
# Maryland's posture and NOT Nebraska's or Georgia's. `in_assert_not_executed()`
# requires that sentence to still be on the documents, every run: the day
# Indiana posts a final Notice of Award, this file's framing is wrong and must
# be rewritten rather than quietly re-run.
#
# THE ONE AMOUNT INDIANA PUBLISHES IS A FIVE-YEAR CONTRACT VALUE, NOT A YEAR 1
# FIGURE. The 2026-08-21 award recommendation letter for RFP 26-87449 states
# "5-year Contract Value: $860,088.00". Publishing that in a Year 1 column would
# overstate Indiana's Year 1 subaward spend by an unknown multiple, so the row
# carries `AMOUNT_IS_MULTI_YEAR_TOTAL` (added to §8 this session, with notes)
# and `budget_period = "5-year contract value"`. The other six award documents
# publish NO amount at all, so their `amount` is EMPTY (Georgia's device) and no
# sum over the column can invent one.
#
# THE §6.2 PROVENANCE TEST, RUN FIRST AND PASSED IN THE STRONGEST FORM THIS
# PROJECT HAS SEEN. IDOA's award-recommendations page is a GENERAL state
# procurement register -- 456 rows covering road salt, dumpsters, DNA collection
# kits and a hydraulic tail trailer -- so "IDOA published an award
# recommendation" is not evidence of RHTP, exactly as "DHHS published an Intent
# to Award" was not evidence of it in Nebraska. What IS evidence sits in each
# solicitation's own Scope of Work, and it is identical across all five:
#
#   "On Dec. 29, 2025, Indiana was awarded a grant of nearly $207 million for
#    the first year of a five-year federal Rural Health Transformation Program
#    (RHTP) ... This Rural Health Transformation Program is supported by the
#    Centers for Medicare & Medicaid Services (CMS) of the U.S. Department of
#    Health and Human Services (HHS) as part of a financial assistance award
#    totaling $206,927,896.80 with 100 percent funded by CMS/HHS."
#
# That is the awarding agency named on the award's own solicitation, a total
# matching `cms_fy2026_allotments.csv`'s $206,927,897 to the dollar, AND the
# state stating its own Notice of Award date -- 2025-12-29, which is exactly
# what `cms_state_noa_dates.csv` carries as the §6.2 anchor for all fifty
# states. `in_assert_rhtp_funded()` and `in_assert_after_noa()` require both,
# every run.
#
# AND THE PROVENANCE IS NOT WHERE A READER WOULD LOOK FOR IT. Two of the five
# RFPs -- 26-87556 Preceptor Registry and 26-87667 ACO Feasibility Study --
# carry NO "RHTP" anywhere in their IDOA table title OR in their award letter.
# Keyed on the award document alone they read as ordinary state procurement and
# would have been dropped. They are RHTP because their SCOPE OF WORK carries the
# CMS footer above, and because Initiative 1's own page marks the ACO study
# "Awarded" and links it. The lesson is Kansas's, one layer deeper: the link
# list is not enough either -- open the solicitation, not just the award.
#
# §0.1 -- WHAT RCJ GOT WRONG HERE, AND IT IS THE WORST RATIO IN THE PROJECT.
# RCJ holds 37 Indiana Tier 3 candidates. SIX of them are real RHTP award rows;
# ONE is a budget-narrative line item; THIRTY are unrelated Indiana state
# procurement. `in_assert_rcj_disposition()` requires the arithmetic to close:
#
#    6 rows   RHTP award actions        (26-87448 x3, 26-87449 x2, 26-87450 x1)
#    1 row    RHTP BUT NOT A SUBAWARD   Indiana Community Connect / Indiana 211
#   30 rows   NOT RHTP AT ALL           988 crisis lines, disability
#                                       determination, a tobacco quitline, a
#                                       workforce diploma programme, hearing
#                                       aids, communication equipment, an
#                                       ELECTRIC GENERATING FACILITY FUEL COST
#                                       ANALYSIS, and a hydraulic tail trailer
#   ---------------------------------------------------------------------------
#   37 rows   = `rcj_state_survey.csv`'s own candidate count for Indiana
#
# The 30 are the dangerous ones and the mechanism is new. RCJ does not merely
# mis-title these; it APPENDS AN RHTP LABEL THEY DO NOT HAVE. Its own document
# titles include "Indiana Negotiated Bid 26-87613 For Hydraulic Trail Trailer
# Purchase RHTP 2026 Award Announcement" and "Indiana Communication Equipment &
# Piece Parts QPA RHTP 2026 Award Announcement". The first of those is a
# trailer: IDOA's own award letter recommends "a one-time purchase with an
# amount of $90,000" for a tilt trailer, and RCJ's $90,000 for Globe Trailers
# matches it exactly. RCJ's AMOUNT is right; the programme label is invented.
# (Indiana spells it "Tail Trailer" on its register and "Trail Trailer" in the
# letter -- the state's own two spellings, not an aggregator error. §8 keeps
# the source's language and resolves neither.) Seven further rows
# are filed under the bare title "IN - 2026 - RHTP Update", among them the fuel
# cost analysis. Nebraska's defect took a heading from the wrong PAGE of the
# right document; Indiana's manufactures the programme label outright. An
# extractor written from the candidate list would have published roughly
# $147 MILLION of unrelated state procurement as Indiana's RHTP subawards.
#
# Three of the 37 carry no document title at all, only the captured page header
# "Indiana DEPARTMENT OF ADMINISTRATION STATE OF INDIANA Commissioner's Office
# Mike Braun, Governor Indiana Government Center South 402 West Washington
# Street, Room W462 Indianapolis," -- §0.1's page-chrome-as-title defect,
# verbatim, and the reason `PAGE_CHROME_TITLE` is in §8.
#
# AND RCJ MISSES TWO OF THE SEVEN REAL AWARDS -- Deloitte (26-87667) and
# Concourse Tech (26-87556), the two whose titles never say RHTP. It holds
# neither. That is Kansas's and Nebraska's lesson a third time: the aggregator's
# candidate count says where to look and never what is there.
#
# THE POSITIVE CONTROL, WHICH IS WHAT MAKES THE NEGATIVE BELOW MEAN ANYTHING.
# Indiana demonstrably publishes recipient-level award documents in a uniform,
# recognisable form: IDOA's register carries 456 of them, each a zip holding a
# "Preliminary Notice of Award" PDF, and this file parses seven names out of six
# such documents. So "Indiana has published no hospital roster" is a statement
# about Indiana, not about our ability to read its site.
# `in_assert_award_register()` asserts the register is present and large, that
# every one of the five RHTP solicitations is still on it, and that it still
# carries the ordinary non-RHTP procurement that makes it a general register --
# a tripwire in both directions, because a redesign that split RHTP onto its own
# page would otherwise turn every future run silently green.
#
# THE §6.2 NEGATIVE CONTROL IS ARCHIVED BESIDE THE POSITIVES. "NB 26-87613 80HT
# Hydraulic Tail Trailer" is a real IDOA award recommendation that RCJ labels
# RHTP; its own document is a trailer purchase for the Indiana Department of
# Natural Resources and its solicitation carries no CMS footer.
# `in_assert_non_rhtp_control()` pins both halves.
#
# WHERE INDIANA'S HOSPITAL MONEY ACTUALLY IS, AND WHY THIS FILE HAS NONE OF IT.
# GROW Regional Grants is Indiana's hospital-facing vehicle: "$120M awarded
# annually across eight regional coalitions", per the state's own page. It HAS
# NOT AWARDED. The page's own timeline reads "Release RFF on 3/2/26", "RFF
# Applications submitted July 1", and "It launches Sept. 1, 2026" -- which is
# TOMORROW as this file is written (2026-08-31). `in_assert_regional_not_awarded()`
# fails the day that changes, because the day it changes Indiana becomes one of
# the largest hospital-dollar states in the project and this file must be rebuilt.
#
# THAT PAGE IS ALSO THE BIGGEST §0.3 TRAP THIS PROJECT HAS MET. It carries
# FIFTEEN TABLES of named people against named hospitals -- Goshen Health,
# Parkview Health, Reid Health, Franciscan Health, Woodlawn Hospital, Pulaski
# Memorial, Cameron Health -- which read at a glance as a hospital award roster
# and are the REGIONAL COMMITTEE MEMBERS, an advisory body appointed to SCORE
# the applications. It also prints an eight-row table of per-region dollar
# figures ($4,405,581, $7,881,614, ...) which are MAXIMUM CAPITAL EXPENDITURE
# CEILINGS, not awards. A table of eight regions against eight dollar amounts,
# on the awarding agency's own grants page, is as close to a publishable award
# table as a non-award can look. `in_assert_committee_not_recipients()` pins
# both traps: the committee tables must still be committee tables, and no
# hospital named only there may enter the award rows.
#
# WHAT INDIANA HAS PUBLISHED THAT IS NOT AN AWARD, AND IS NOT IN THIS FILE.
# `RHTP-BudgetNarrative.pdf` carries a full ELEVEN-INITIATIVE allocation table
# ($56,186,480 for Initiative 1, $3,320,000 for Initiative 2, ...). That is a
# Tier 2 plan, and §0.2 forbids unioning it with Tier 3. It is what disposes of
# RCJ's one remaining candidate: "Indiana Community Connect (via Indiana 211)",
# $3,300,000, whose source document is Indiana's own GROW narrative. The
# narrative's figure is $3,320,000 -- not RCJ's $3,300,000 -- it is an
# initiative BUDGET rather than an award, its contractors are unnamed and future
# ("The contractor will design, develop, implement, and maintain..."), and
# "Indiana Community Connect" is the PROGRAMME, not a recipient (§6.1's
# `PROGRAM_NAME_AS_AWARDEE`). Texas's `RHTP_BUT_NOT_A_SUBAWARD` exactly.
#
# THE ONE JUDGEMENT THIS FILE MAKES AGAINST THE SHARED CLASSIFIER, STATED
# PLAINLY. `rhtp_classify_recipient_type()` returns §8's standing fallback
# (`NONPROFIT_CBO` + LOW + `RECIPIENT_TYPE_INFERRED`) for six of the seven,
# because IDOA publishes no organisation-type column -- Kansas's, Maryland's and
# Nebraska's shape. Here the source DOES state the form, in its own words: IDOA
# "has identified the following companies as the selected respondents" to a
# competitive RFP, and every recipient carries a corporate suffix (LLC, Inc,
# LLP, Corp). That is `VENDOR_OR_CONTRACTOR` on the document's own language, so
# these seven are typed from the source and not from the fallback, at MEDIUM.
# `recipient_type_source` records the classifier's value on every row so the
# override is auditable and reversible, and `in_assert_vendor_override()` pins
# exactly which rows diverge and why. IT MOVES NO DOLLARS: all seven are
# `distributed_to_hospital = No` under either typing, which is why it is safe to
# decide here rather than queue it.
#
# Sources, all archived under data/evidence/IN/ with a SHA-256 manifest.

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_pdf_text.R"))


# -- configuration ------------------------------------------------------------

IN_STATE            <- "IN"
IN_FISCAL_YEAR      <- "FY2026"
IN_EVIDENCE_DIR     <- here::here("data", "evidence", "IN")
IN_OUTPUT_CSV       <- here::here("data", "reference", "in_year1_awardees.csv")
IN_DISPOSITION_CSV  <- here::here("data", "reference",
                                  "in_rcj_candidate_disposition.csv")
IN_OUTPUT_XLSX      <- here::here("IN_year1_awardees.xlsx")
IN_HOST_THROTTLE_S  <- 2
IN_USER_AGENT       <- "AHA-RHTP-Tracker/1.0 (research; +https://www.aha.org)"

# §7.1: Indiana's CMS allotment, and the §6.2 date anchor. Both are READ from
# the committed reference tables at assert time, never typed here -- the point
# of the test is that the state's own document agrees with them.
IN_ALLOTMENT_SOURCE <- here::here("data", "reference", "cms_fy2026_allotments.csv")
IN_NOA_SOURCE       <- here::here("data", "reference", "cms_state_noa_dates.csv")

# The CMS financial-assistance footer, quoted from every one of the five
# solicitations' Scope of Work. This is the §6.2 evidence and it is what
# separates an RHTP award from the 449 other rows on IDOA's register.
IN_RHTP_FOOTER_AMOUNT <- "$206,927,896.80"
IN_RHTP_FOOTER <- paste(
  "This Rural Health Transformation Program is supported by the Centers for",
  "Medicare & Medicaid Services (CMS) of the U.S. Department of Health and",
  "Human Services (HHS) as part of a financial assistance award totaling",
  "$206,927,896.80 with 100 percent funded by CMS/HHS."
)
# The state stating its own Notice of Award date, in the same paragraph.
IN_NOA_SENTENCE <- paste(
  "On Dec. 29, 2025, Indiana was awarded a grant of nearly $207 million for the",
  "first year of a five-year federal Rural Health Transformation Program (RHTP)"
)

# The sentence that makes every row an INTENT rather than an award. If Indiana
# posts a final Notice of Award this stops being true and the file is wrong.
IN_NOT_EXECUTED_SENTENCE <- paste(
  "does not gain a property interest in the award of a contract by the",
  "department unless the bidder or offeror is awarded the contract, and the",
  "contract is completely executed"
)

# GROW Regional Grants -- Indiana's hospital-facing vehicle, not yet awarded.
IN_REGIONAL_LAUNCH_SENTENCE <- "It launches Sept. 1, 2026, with $120M awarded annually across eight regional coalitions"
IN_REGIONAL_LAUNCH_DATE     <- as.Date("2026-09-01")

# The §0.3 trap on that same page: hospitals named ONLY as advisory committee
# members. None of these may ever appear in the award rows.
IN_COMMITTEE_ONLY_HOSPITALS <- c(
  "Goshen Health", "Parkview Health", "Reid Health", "Woodlawn Hospital",
  "Pulaski Memorial", "Cameron Health", "Franciscan Hospital"
)

# The §6.2 negative control: a real IDOA award recommendation that RCJ labels
# RHTP and that is a trailer.
IN_NON_RHTP_CONTROL_TITLE <- "NB 26-87613 80HT Hydraulic Tail Trailer"
IN_NON_RHTP_CONTROL_RCJ   <- "Hydraulic Trail Trailer Purchase RHTP 2026 Award Announcement"

# Ordinary non-RHTP procurement that must stay on the register for it to remain
# a GENERAL register -- half of the positive control's tripwire.
IN_REGISTER_ORDINARY <- c("Road Salt", "DNA Collection Kits", "Digital Printer")

IN_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)

IN_SOURCES <- tibble::tribble(
  ~key,              ~file,                                    ~url,
  "grow_home",       "2026-08-31_grow_home.html",
  "https://www.in.gov/grow-rural-health/",
  "grow_regional",   "2026-08-31_grow_regional_grants.html",
  "https://www.in.gov/grow-rural-health/regional-grants/",
  "grow_init_1",     "2026-08-31_grow_initiative_1.html",
  "https://www.in.gov/grow-rural-health/initiatives/initiative-1",
  "grow_init_7",     "2026-08-31_grow_initiative_7.html",
  "https://www.in.gov/grow-rural-health/initiatives/initiative-7",
  "grow_init_10",    "2026-08-31_grow_initiative_10.html",
  "https://www.in.gov/grow-rural-health/initiatives/initiative-10",
  "idoa_register",   "2026-08-31_idoa_award_recommendations.html",
  "https://www.in.gov/idoa/procurement/award-recommendations/",
  "award_87448",     "RFP_26-87448_RHTP_MOCC_20260728.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87448%20RHTP%20MOCC_20260728.zip",
  "award_87449_pre", "RFP_26-87449_RHTP07_Teleconsult_20260603.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87449%20RHTP07%20Teleconsult%20and%20Telehealth%20Landscape%20Assessment_20260603.zip",
  "award_87449_let", "RFP_26-87449_RHTP_Teleconsult_letter_20260821.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87449%20RHTP%20Teleconsult%20and%20Telehealth%20Landscape%20Assessment_20260821.zip",
  "award_87450",     "RFP_26-87450_RHTP_Program_Evaluator_20260626.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87450%20RHTP%20Program%20Evaluator_20260626.zip",
  "award_87556",     "RFP_26-87556_Preceptor_Registry_20260806.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87556%20Preceptor%20Registry_20260806.zip",
  "award_87667",     "RFP_26-87667_ACO_Feasibility_Study_20260807.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/RFP%2026-87667%20ACO%20Feasibility%20Study_20260807.zip",
  "control_87613",   "NEGATIVE_CONTROL_NB_26-87613_Hydraulic_Tail_Trailer_20260616.zip",
  "https://www.in.gov/idoa/proc/recommendations/files/NB%2026-87613%2080HT%20Hydraulic%20Tail%20Trailer_20260616.zip",
  "budget_narrative", "2026-08-31_RHTP-BudgetNarrative.pdf",
  "https://www.in.gov/grow-rural-health/files/RHTP-BudgetNarrative.pdf"
)

# The solicitation packages are NOT archived: five zips of 2-7 MB each, almost
# entirely boilerplate attachments and embedded images. What matters in them is
# the Scope of Work's CMS footer, so the SCOPE OF WORK MEMBER ALONE is archived
# for each, under its own name, with the parent zip's URL recorded in the
# manifest. A reader can re-download the parent and re-derive the member.
IN_SCOPE_SOURCES <- tibble::tribble(
  ~key,           ~file,                             ~zip_url,                                                                    ~member,
  "scope_87448",  "scope_RFP_26-87448_K1.docx",
  "https://www.in.gov/idoa/proc/solicitations/files/004000000087448.zip",
  "Att K1 - Services Scope of Work.docx",
  "scope_87449",  "scope_RFP_26-87449_K.docx",
  "https://www.in.gov/idoa/proc/solicitations/files/004000000087449.zip",
  "Att K - Scope of Work.docx",
  "scope_87450",  "scope_RFP_26-87450_K.docx",
  "https://www.in.gov/idoa/proc/solicitations/files/004000000087450.zip",
  "Att K - Scope of Work.docx",
  "scope_87556",  "scope_RFP_26-87556_K.docx",
  "https://www.in.gov/idoa/proc/solicitations/files/004000000087556.zip",
  "004000000087556/Att K - Scope of Work.docx",
  "scope_87667",  "scope_RFP_26-87667_L.docx",
  "https://www.in.gov/idoa/proc/solicitations/files/004000000087667.zip",
  "004000000087667/Att L - Scope of Work.docx"
)


# -- fetch --------------------------------------------------------------------

in_source <- function(key, field) {
  row <- IN_SOURCES[IN_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[IN] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

in_path <- function(key) {
  f <- IN_SOURCES$file[IN_SOURCES$key == key]
  if (!length(f)) f <- IN_SCOPE_SOURCES$file[IN_SCOPE_SOURCES$key == key]
  if (length(f) != 1L) stop("[IN] unknown source key: ", key, call. = FALSE)
  file.path(IN_EVIDENCE_DIR, f)
}

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
in_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(IN_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, IN_CREDENTIAL_SHAPES[[nm]])) {
      stop("[IN] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

in_get <- function(url, label) {
  message("[IN] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(IN_USER_AGENT), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[IN] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  in_assert_credential_free(served, label)
  served
}

#' Archive Indiana's sources verbatim, plus the five Scope of Work members
in_fetch <- function(force = FALSE) {
  dir.create(IN_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(IN_SOURCES)), function(i) {
    src  <- IN_SOURCES[i, ]
    dest <- file.path(IN_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[IN] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(IN_HOST_THROTTLE_S)
      writeBin(in_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      note = NA_character_
    )
  })

  # The Scope of Work members. The parent zip is downloaded, the one member is
  # extracted and archived, and the parent is discarded -- so the repository
  # carries the evidence and not 23 MB of procurement boilerplate.
  scopes <- purrr::map_dfr(seq_len(nrow(IN_SCOPE_SOURCES)), function(i) {
    src  <- IN_SCOPE_SOURCES[i, ]
    dest <- file.path(IN_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[IN] cached, not re-fetched: ", src$file)
    } else {
      Sys.sleep(IN_HOST_THROTTLE_S)
      tmp <- tempfile(fileext = ".zip")
      on.exit(unlink(tmp), add = TRUE)
      writeBin(in_get(src$zip_url, src$file), tmp)
      members <- utils::unzip(tmp, list = TRUE)$Name
      if (!src$member %in% members) {
        stop("[IN] ", src$member, " is not in ", src$zip_url,
             " -- the solicitation package has been restructured and the ",
             "provenance evidence must be relocated before this file is ",
             "re-run.", call. = FALSE)
      }
      con <- unz(tmp, src$member, open = "rb")
      body <- readBin(con, "raw", n = 3e7)
      close(con)
      in_assert_credential_free(body, src$file)
      writeBin(body, dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$zip_url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256"),
      note = paste0("member of the solicitation package: ", src$member)
    )
  })

  entries <- dplyr::bind_rows(entries, scopes)
  in_cache_clear()
  in_write_manifest(entries)
  entries
}

in_write_manifest <- function(entries) {
  path <- file.path(IN_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Indiana -- GROW / RHTP Year 1: award recommendations, the programme site,",
    "the IDOA award register, one negative control and five Scope of Work",
    "members carrying the CMS financial-assistance footer.",
    "Archived by R/03s_in_year1_awardees.R --fetch",
    paste0("User-agent: ", IN_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard that caught CMS's Mapbox token, Illinois's and Oregon's,",
    "and Kansas's Google Maps key runs on every fetch here and finds nothing,",
    "so there is no reduction to explain.",
    "",
    "THE SCOPE OF WORK FILES ARE MEMBERS OF A LARGER ZIP, ARCHIVED ALONE. Each",
    "solicitation package is 2-7 MB of boilerplate attachments and embedded",
    "images; the RHTP provenance is one paragraph in the Scope of Work. The",
    "parent zip's URL and the member's path within it are both recorded below,",
    "so the member can be re-derived from the parent and re-hashed.",
    "",
    "NB 26-87613 80HT HYDRAULIC TAIL TRAILER IS NOT AN RHTP DOCUMENT. It is",
    "archived deliberately, as the §6.2 negative control. IDOA's award register",
    "is a GENERAL state procurement register -- road salt, dumpsters, DNA",
    "collection kits -- so an IDOA award recommendation is not by itself",
    "evidence of RHTP. RCJ nonetheless files this one under the title 'Indiana",
    "Negotiated Bid 26-87613 For Hydraulic Trail Trailer Purchase RHTP 2026",
    "Award Announcement', appending a programme label the document does not",
    "carry. The letter itself recommends 'a one-time purchase with an amount",
    "of $90,000' for a tilt trailer. Indiana spells it 'Tail Trailer' on the",
    "register and 'Trail Trailer' in the letter; both spellings are the",
    "state's own (§8 resolves neither).",
    "",
    "RHTP-BudgetNarrative.pdf IS A PLAN, NOT AN AWARD (§0.3). It is archived",
    "because it is what disposes of RCJ's 'Indiana Community Connect' candidate:",
    "the $3,320,000 there is an initiative BUDGET line whose contractors are",
    "unnamed and future.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes)  <- ", entries$url,
           ifelse(is.na(entries$note), "", paste0("  [", entries$note, "]")))
  ), path)
  invisible(path)
}


# -- readers ------------------------------------------------------------------

# Reading these sources is expensive -- a 2.7 MB Scope of Work and six PDFs,
# each parsed through the /ToUnicode CMap -- and the assertions below read the
# same document several times over. The cache is keyed on the source key and
# lives for the session; --fetch clears it, because that is the only thing that
# changes a file on disk.
IN_READ_CACHE <- new.env(parent = emptyenv())

in_cached <- function(key, fn) {
  id <- paste0(key, "::", deparse(substitute(fn)))
  if (!is.null(IN_READ_CACHE[[id]])) return(IN_READ_CACHE[[id]])
  val <- fn(key)
  assign(id, val, envir = IN_READ_CACHE)
  val
}

in_cache_clear <- function() rm(list = ls(IN_READ_CACHE), envir = IN_READ_CACHE)


#' Read an archived HTML file down to visible text, once, for assertions.
in_html_text_raw <- function(key) {
  raw <- readBin(in_path(key), "raw", file.info(in_path(key))$size)
  txt <- rawToChar(raw)
  Encoding(txt) <- "UTF-8"
  doc <- xml2::read_html(txt)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  out <- xml2::xml_text(doc)
  stringr::str_squish(out)
}

#' Read the single PDF inside an archived IDOA award-recommendation zip.
in_award_text_raw <- function(key) {
  z <- in_path(key)
  members <- utils::unzip(z, list = TRUE)$Name
  pdfs <- members[grepl("\\.pdf$", members, ignore.case = TRUE)]
  if (length(pdfs) != 1L) {
    stop("[IN] expected exactly one PDF in ", basename(z), ", found ",
         length(pdfs), call. = FALSE)
  }
  tmp <- file.path(tempdir(), basename(pdfs))
  on.exit(unlink(tmp), add = TRUE)
  utils::unzip(z, files = pdfs, exdir = tempdir(), junkpaths = TRUE)
  stringr::str_squish(paste(rhtp_pdf_text(tmp), collapse = " "))
}

#' Read a .docx Scope of Work member as text. A .docx is a zip of XML parts;
#' the text lives in word/document.xml. No new dependency for one paragraph.
in_docx_text_raw <- function(key) {
  z <- in_path(key)
  con <- unz(z, "word/document.xml", open = "rb")
  on.exit(try(close(con), silent = TRUE), add = TRUE)
  raw <- readBin(con, "raw", n = 3e7)
  txt <- rawToChar(raw)
  Encoding(txt) <- "UTF-8"
  txt <- gsub("<[^>]+>", " ", txt)
  txt <- gsub("&amp;", "&", txt, fixed = TRUE)
  stringr::str_squish(txt)
}

in_html_text  <- function(key) in_cached(key, in_html_text_raw)
in_award_text <- function(key) in_cached(key, in_award_text_raw)
in_docx_text  <- function(key) in_cached(key, in_docx_text_raw)


# -- the award table ----------------------------------------------------------

# Seven award actions, from six documents, across five solicitations. Every
# recipient name is as the state's own letter prints it, including
# "Collaborative Fusion, Inc" and "Concourse Tech Inc" without a full stop (§8
# keeps the source's language). `initiative_description` is the GROW initiative
# page's own Description sentence, NEVER RCJ's machine-generated summary (§6).
IN_AWARDS <- tibble::tribble(
  ~rfp,        ~awardee,                       ~amount,   ~agency, ~initiative, ~award_doc_key,     ~award_date,
  "26-87448",  "Patient Flow Innovations",     NA_real_,  "IDOH",  "1",         "award_87448",      "2026-07-27",
  "26-87448",  "Collaborative Fusion, Inc",    NA_real_,  "IDOH",  "1",         "award_87448",      "2026-07-27",
  "26-87448",  "Communicare Technology",       NA_real_,  "IDOH",  "1",         "award_87448",      "2026-07-27",
  "26-87449",  "Laurel Health Advisors LLC",   860088,    "IDOH",  "7",         "award_87449_let",  "2026-08-21",
  "26-87450",  "Public Policy Associates LLC", NA_real_,  "FSSA",  "cross",     "award_87450",      "2026-06-26",
  "26-87556",  "Concourse Tech Inc",           NA_real_,  "IDOH",  "10",        "award_87556",      "2026-08-06",
  "26-87667",  "Deloitte Consulting LLP",      NA_real_,  "FSSA",  "1",         "award_87667",      "2026-08-07"
)

# The solicitation each award belongs to, as the state titles it, and the pool
# label this file carries. `award_pool` is the column a reader must consult
# before using any Indiana figure -- there is one amount in the whole file.
IN_POOLS <- tibble::tribble(
  ~rfp,       ~award_pool,                       ~solicitation_title,                                             ~scope_key,
  "26-87448", "RHTP_MOCC",                       "RFP 26-87448 RHTP MOCC",                                        "scope_87448",
  "26-87449", "RHTP_TELECONSULT_ASSESSMENT",     "RFP 26-87449 RHTP Teleconsult and Telehealth Landscape Assessment", "scope_87449",
  "26-87450", "RHTP_PROGRAM_EVALUATOR",          "RFP 26-87450 RHTP Program Evaluator",                           "scope_87450",
  "26-87556", "RHTP_PRECEPTOR_REGISTRY",         "RFP 26-87556 Preceptor Registry",                               "scope_87556",
  "26-87667", "RHTP_ACO_FEASIBILITY",            "RFP 26-87667 ACO Feasibility Study",                            "scope_87667"
)

# The GROW initiative pages' own Description sentences. Quoted from the state,
# and used as the flow-determination input so §10.2 is applied to the state's
# language rather than to an aggregator's summary (§6, §0.3a).
IN_INITIATIVE_DESCRIPTION <- c(
  "1" = paste(
    "A 24/7 statewide hub to coordinate patient transfers, EMS resources and",
    "hospital capacity. The MOCC aims to ensure rural communities get timely",
    "access to trauma, stroke, psychiatric and maternal care by streamlining",
    "referrals, reducing inappropriate ER use, supporting rural hospital",
    "sustainability and strengthening preparedness for mass casualty events."),
  "7" = paste(
    "This initiative assesses existing provider networks and specialty gaps",
    "while building a secure teleconsultation system to expand access to",
    "high-need specialties such as psychiatry and behavioral health."),
  "10" = paste(
    "Advance rural healthcare access and clinical workforce strength through",
    "expanded physician training pathways, increasing clinical rotation",
    "capacity, and targeted investments in maternal health."),
  "cross" = paste(
    "Independent evaluation of the Rural Health Transformation Program,",
    "procured by the Family and Social Services Administration.")
)

#' Build Indiana's seven award rows in the Florida schema (§8, test_state_union)
in_build_awards <- function() {
  awards <- IN_AWARDS %>%
    dplyr::left_join(IN_POOLS, by = "rfp") %>%
    dplyr::mutate(
      initiative_description = unname(IN_INITIATIVE_DESCRIPTION[initiative])
    )

  # §8 typing. The shared classifier's answer is recorded on every row; the
  # published type is the state's own word ("companies", "selected respondent"
  # to a competitive RFP, every name carrying a corporate suffix), which is
  # VENDOR_OR_CONTRACTOR at MEDIUM. See the header: it moves no dollars.
  classified <- purrr::map_dfr(seq_len(nrow(awards)), function(i) {
    ct <- rhtp_classify_recipient_type(awards$awardee[i], IN_STATE)
    fl <- rhtp_classify_flow("VENDOR_OR_CONTRACTOR",
                             awards$initiative_description[i])
    tibble::tibble(
      classifier_type = ct$recipient_type,
      flow_type = fl$flow_type,
      distributed_to_hospital = fl$distributed_to_hospital,
      hospital_benefiting = fl$hospital_benefiting
    )
  })

  awards <- dplyr::bind_cols(awards, classified) %>%
    dplyr::mutate(
      state = IN_STATE,
      row_no = dplyr::row_number(),
      recipient_type = "VENDOR_OR_CONTRACTOR",
      note = paste0(
        solicitation_title, ". Preliminary Notice - Award Recommendation, ",
        award_date, ", IDOA on behalf of ", agency, ". ",
        ifelse(is.na(amount),
               "The document publishes NO amount.",
               "5-year Contract Value: $860,088.00 -- a five-year figure, not Year 1."),
        " Not executed: the recommendation is conditioned on contract",
        " finalisation and I.C. 4-13-1-19 is quoted on the document."),
      recipient_confirmed = "Yes",
      amount_confirmed    = "No",
      fiscal_year = IN_FISCAL_YEAR,
      source_document_title = paste0(
        "Preliminary Notice - Award Recommendation, ", solicitation_title),
      state_source_url = "https://www.in.gov/idoa/procurement/award-recommendations/",
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "PARSED_FROM_PDF",
      validator = "R/03s_in_year1_awardees.R",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      recipient_type_source = paste0(
        "IDOA award recommendation letter: 'companies' / 'selected respondent'",
        " under a competitive RFP; corporate suffix in the name.",
        " Shared classifier returned ", classifier_type, "."),
      determination_confidence = "MEDIUM",
      flag_reason = ifelse(
        is.na(amount),
        "AMOUNT_MISSING;AMOUNT_PRELIMINARY",
        "AMOUNT_IS_MULTI_YEAR_TOTAL;AMOUNT_PRELIMINARY"),
      hospital_attribution = "NOT_HOSPITAL",
      intermediary_name = NA_character_,
      amount_basis = ifelse(is.na(amount), NA_character_,
                            "5-year contract value"),
      budget_period = ifelse(is.na(amount), "Budget Period 1",
                             "5-year contract value"),
      solicitation_number = rfp,
      awarding_agency = agency,
      grow_initiative = initiative,
      award_date = as.Date(award_date)
    )

  awards %>%
    dplyr::select(
      state, row_no, awardee, amount, recipient_type, distributed_to_hospital,
      note, recipient_confirmed, amount_confirmed, fiscal_year,
      source_document_title, state_source_url, validation_source_type,
      extraction_method, validator, ccn, aha_id, rural_designation, reviewer,
      recipient_type_source, determination_confidence, flag_reason,
      award_pool, budget_period, flow_type, hospital_benefiting,
      hospital_attribution, intermediary_name, amount_basis,
      solicitation_number, awarding_agency, grow_initiative, award_date
    )
}


# -- §6.2 provenance, and the controls ----------------------------------------

#' Indiana's CMS allotment, read from the §7.1 anchor rather than typed.
in_allotment <- function() {
  a <- readr::read_csv(IN_ALLOTMENT_SOURCE, show_col_types = FALSE,
                       progress = FALSE)
  col <- intersect(c("fy2026_allotment", "allotment_fy2026", "allotment"), names(a))[1]
  as.numeric(a[[col]][a$state == IN_STATE])
}

#' Indiana's CMS Notice of Award date, read from the §6.2 anchor.
in_noa_date <- function() {
  d <- readr::read_csv(IN_NOA_SOURCE, show_col_types = FALSE, progress = FALSE)
  as.Date(d$noa_date[d$state == IN_STATE])
}

#' §6.2 -- the awarding agency, named on the award's own solicitation.
#'
#' This is the test that separates an RHTP award from the 449 other rows on
#' IDOA's general procurement register. All five solicitations carry the same
#' CMS financial-assistance footer, and its total matches the §7.1 allotment.
in_assert_rhtp_funded <- function() {
  allot <- in_allotment()
  for (k in IN_SCOPE_SOURCES$key) {
    txt <- in_docx_text(k)
    if (!stringr::str_detect(txt, stringr::fixed(IN_RHTP_FOOTER_AMOUNT))) {
      stop("[IN] ", k, " no longer carries the CMS financial-assistance total ",
           IN_RHTP_FOOTER_AMOUNT, ". The §6.2 provenance for this award is ",
           "gone and it must not be published as RHTP.", call. = FALSE)
    }
    if (!stringr::str_detect(txt, stringr::fixed("Centers for Medicare"))) {
      stop("[IN] ", k, " no longer names CMS as the funding agency.",
           call. = FALSE)
    }
  }
  # The footer's total and the §7.1 anchor must be the same award.
  footer_num <- as.numeric(gsub("[$,]", "", IN_RHTP_FOOTER_AMOUNT))
  if (abs(round(footer_num) - allot) > 1) {
    stop("[IN] the solicitations' CMS total ", IN_RHTP_FOOTER_AMOUNT,
         " does not match the §7.1 allotment ", allot, ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2 -- the date test, against the anchor and the state's own statement.
in_assert_after_noa <- function() {
  noa <- in_noa_date()
  if (is.na(noa)) stop("[IN] no NOA date for Indiana in the §6.2 anchor.",
                       call. = FALSE)
  # The state says the date itself, in the same paragraph as the CMS footer.
  for (k in IN_SCOPE_SOURCES$key) {
    txt <- in_docx_text(k)
    if (!stringr::str_detect(txt, stringr::fixed("On Dec. 29, 2025"))) {
      stop("[IN] ", k, " no longer states Indiana's Notice of Award date.",
           call. = FALSE)
    }
  }
  if (format(noa, "%Y-%m-%d") != "2025-12-29") {
    stop("[IN] the §6.2 anchor has Indiana's NOA at ", noa,
         " but the state's own solicitations say 2025-12-29.", call. = FALSE)
  }
  # Every award action postdates it.
  awards <- in_build_awards()
  if (any(awards$award_date <= noa)) {
    stop("[IN] an award action predates Indiana's Notice of Award.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' NOT EXECUTED. The tripwire that fails the day Indiana posts a final award.
in_assert_not_executed <- function() {
  keys <- c("award_87448", "award_87449_pre", "award_87450", "award_87556",
            "award_87667")
  for (k in keys) {
    txt <- in_award_text(k)
    if (!stringr::str_detect(txt, stringr::fixed(IN_NOT_EXECUTED_SENTENCE))) {
      stop("[IN] ", k, " no longer quotes I.C. 4-13-1-19. If Indiana has ",
           "issued a FINAL Notice of Award, every row in this file is coded ",
           "too weakly and the file must be rewritten, not re-run.",
           call. = FALSE)
    }
    if (!stringr::str_detect(txt, stringr::fixed("Preliminary Notice"))) {
      stop("[IN] ", k, " is no longer a Preliminary Notice.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The IDOA award register, parsed into its own rows. Used as the positive
#' control, so it is parsed rather than pattern-counted: a text search for
#' "RFP " misses every row IDOA writes as "RFP-26-...", which is a quarter of
#' them, and an undercount here would read as the control having vanished.
in_register_rows <- function() {
  path <- in_path("idoa_register")
  txt  <- rawToChar(readBin(path, "raw", file.info(path)$size))
  Encoding(txt) <- "UTF-8"
  doc  <- xml2::read_html(txt)
  tbl  <- xml2::xml_find_first(doc, "//table")
  if (inherits(tbl, "xml_missing")) {
    stop("[IN] the IDOA award register no longer contains a table.",
         call. = FALSE)
  }
  rows <- xml2::xml_find_all(tbl, ".//tr")
  out <- purrr::map_dfr(rows, function(tr) {
    cells <- xml2::xml_text(xml2::xml_find_all(tr, ".//td"))
    if (length(cells) < 2L) return(NULL)
    href <- xml2::xml_attr(xml2::xml_find_first(tr, ".//a"), "href")
    tibble::tibble(award_date = stringr::str_squish(cells[1]),
                   event = stringr::str_squish(cells[2]),
                   url = href)
  })
  out[!is.na(out$event) & nzchar(out$event), ]
}

#' THE POSITIVE CONTROL. IDOA publishes recipient-level award documents in a
#' uniform, recognisable form -- and the register is GENERAL, not RHTP-only.
#' A tripwire in both directions: it fails if a known RHTP row disappears, and
#' fails if the register stops carrying ordinary procurement (which would mean
#' RHTP had been split onto a page this file does not read).
in_assert_award_register <- function() {
  reg <- in_register_rows()

  # It must still be large. A register that shrank to a handful of rows is a
  # different page and the negative below would stop meaning anything.
  if (nrow(reg) < 300L) {
    stop("[IN] the IDOA register carries only ", nrow(reg), " award ",
         "recommendations; it had 456. The positive control is gone.",
         call. = FALSE)
  }
  # Every award document this file parses must still be linked from it, and
  # every RHTP solicitation still listed.
  for (r in IN_POOLS$rfp) {
    if (!any(stringr::str_detect(reg$event, stringr::fixed(r)))) {
      stop("[IN] ", r, " is no longer on IDOA's award register.", call. = FALSE)
    }
  }
  # And it must still be a GENERAL register -- not an RHTP-only page.
  for (o in IN_REGISTER_ORDINARY) {
    if (!any(stringr::str_detect(reg$event, stringr::fixed(o)))) {
      stop("[IN] the register no longer carries ordinary procurement ('", o,
           "'). If RHTP has been split onto its own page, this file is ",
           "reading the wrong index.", call. = FALSE)
    }
  }
  # The overwhelming majority of the register is NOT RHTP. That ratio is what
  # makes "IDOA published an award recommendation" no evidence of RHTP.
  rhtp_rows <- sum(stringr::str_detect(reg$event, "RHTP"))
  if (rhtp_rows / nrow(reg) > 0.05) {
    stop("[IN] RHTP is now ", round(100 * rhtp_rows / nrow(reg), 1),
         "% of IDOA's register. It was 0.9%, which is why the register is a ",
         "general one and an IDOA award is not by itself evidence of RHTP.",
         call. = FALSE)
  }
  # Exactly the RHTP-titled rows we expect, no more: a FIFTH would mean Indiana
  # has awarded a solicitation this file does not carry.
  if (rhtp_rows > 4L) {
    stop("[IN] IDOA's register now carries ", rhtp_rows, " RHTP-titled rows; ",
         "this file was built against 4. Indiana has awarded something new ",
         "and it must be extracted, not skipped.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §6.2 NEGATIVE CONTROL. A real IDOA award recommendation that RCJ labels
#' RHTP, and that is a trailer.
in_assert_non_rhtp_control <- function() {
  txt <- in_award_text("control_87613")
  if (!stringr::str_detect(txt, stringr::fixed("Hydraulic"))) {
    stop("[IN] the negative control is no longer the trailer award.",
         call. = FALSE)
  }
  if (!stringr::str_detect(txt, stringr::fixed("one-time purchase"))) {
    stop("[IN] the negative control no longer describes a one-time purchase.",
         call. = FALSE)
  }
  # It carries no RHTP provenance at all -- which is the whole point.
  if (stringr::str_detect(txt, "Rural Health Transformation") ||
      stringr::str_detect(txt, stringr::fixed(IN_RHTP_FOOTER_AMOUNT))) {
    stop("[IN] the negative control now carries RHTP provenance. It was ",
         "chosen because it does not; re-choose it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' GROW Regional Grants has NOT awarded. Indiana's hospital money is here, and
#' the day this assertion fails Indiana becomes a major hospital-dollar state.
in_assert_regional_not_awarded <- function() {
  txt <- in_html_text("grow_regional")
  if (!stringr::str_detect(txt, stringr::fixed(IN_REGIONAL_LAUNCH_SENTENCE))) {
    stop("[IN] the GROW Regional Grants page no longer says the programme ",
         "launches 2026-09-01 with $120M across eight coalitions. If Indiana ",
         "has awarded its regional grants, THIS FILE IS MATERIALLY ",
         "INCOMPLETE -- that is where the hospital dollars are.", call. = FALSE)
  }
  # The page must still be describing an application process, not an award.
  for (phrase in c("RFF Applications submitted July 1",
                   "score applications and determine funding")) {
    if (!stringr::str_detect(txt, stringr::fixed(phrase))) {
      stop("[IN] the Regional Grants page no longer reads as pre-award ('",
           phrase, "' is gone). Re-read it before re-running.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' §0.3 -- the committee tables are not a roster. Hospitals named ONLY as
#' advisory committee members must never enter the award rows.
in_assert_committee_not_recipients <- function() {
  txt <- in_html_text("grow_regional")
  if (!stringr::str_detect(txt, stringr::fixed("Regional Committee Members"))) {
    stop("[IN] the Regional Grants page no longer carries the committee ",
         "tables. They are the §0.3 trap this assertion pins; re-read the ",
         "page before trusting the negative.", call. = FALSE)
  }
  awardees <- in_build_awards()$awardee
  for (h in IN_COMMITTEE_ONLY_HOSPITALS) {
    if (!stringr::str_detect(txt, stringr::fixed(h))) {
      stop("[IN] '", h, "' is no longer on the committee roster; the trap ",
           "this assertion guards has changed shape.", call. = FALSE)
    }
    if (any(stringr::str_detect(awardees, stringr::fixed(h)))) {
      stop("[IN] '", h, "' is named ONLY as a Regional Committee member and ",
           "has entered the award rows. That is §0.3 exactly -- an advisory ",
           "appointment read as receipt.", call. = FALSE)
    }
  }
  # The per-region dollar table is a CEILING, not an award.
  if (!stringr::str_detect(txt, "Maximum Capital Expenditures")) {
    stop("[IN] the per-region dollar table is no longer labelled a maximum. ",
         "If those became awards they must be extracted; if they were ",
         "relabelled, re-read the page.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Every awardee this file publishes is named in its own award document.
in_assert_recipients_in_source <- function() {
  awards <- in_build_awards()
  for (i in seq_len(nrow(awards))) {
    key <- IN_AWARDS$award_doc_key[i]
    txt <- in_award_text(key)
    if (!stringr::str_detect(txt, stringr::fixed(awards$awardee[i]))) {
      stop("[IN] '", awards$awardee[i], "' is not named in ", key, ".",
           call. = FALSE)
    }
  }
  # And the one amount is the letter's own five-year figure.
  let <- in_award_text("award_87449_let")
  if (!stringr::str_detect(let, stringr::fixed("5-year Contract Value: $860,088.00"))) {
    stop("[IN] the 2026-08-21 letter no longer states the $860,088 five-year ",
         "contract value.", call. = FALSE)
  }
  invisible(TRUE)
}

#' §0.3 -- the seven proposers on the 26-87449 letter are APPLICANTS, and only
#' one was selected. Nebraska's trap, in Indiana's strongest document.
in_assert_proposers_not_awarded <- function() {
  let <- in_award_text("award_87449_let")
  if (!stringr::str_detect(let, stringr::fixed("The evaluation team received seven"))) {
    stop("[IN] the 26-87449 letter no longer carries its list of proposers; ",
         "the §0.3 edge this assertion holds has changed.", call. = FALSE)
  }
  losers <- c("Manatt", "PwC US Consulting LLP", "Syra Health Corp",
              "Yaqeen Technology Consulting")
  awardees <- in_build_awards()$awardee
  for (l in losers) {
    if (!stringr::str_detect(let, stringr::fixed(l))) {
      stop("[IN] proposer '", l, "' is no longer on the letter.", call. = FALSE)
    }
    if (any(stringr::str_detect(awardees, stringr::fixed(l)))) {
      stop("[IN] '", l, "' submitted a proposal and was NOT selected, yet it ",
           "has entered the award rows (§0.3).", call. = FALSE)
    }
  }
  # Deloitte is the trap inside the trap: it is an unsuccessful proposer HERE
  # and a genuine awardee on a DIFFERENT solicitation (26-87667).
  d <- in_build_awards() %>% dplyr::filter(grepl("Deloitte", awardee))
  if (nrow(d) != 1L || d$solicitation_number != "26-87667") {
    stop("[IN] Deloitte must appear exactly once, on 26-87667. It is also an ",
         "unsuccessful proposer on 26-87449 and the two must not be merged.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Indiana distributes NOTHING to hospitals in this file, and that is the
#' finding rather than an omission.
in_assert_no_hospital_dollars <- function() {
  awards <- in_build_awards()
  if (any(awards$distributed_to_hospital != "No")) {
    stop("[IN] a row now reports money distributed to a hospital. Indiana's ",
         "seven recipients are all vendors; re-read the source.", call. = FALSE)
  }
  if (any(awards$hospital_attribution != "NOT_HOSPITAL")) {
    stop("[IN] a row carries a hospital attribution bucket.", call. = FALSE)
  }
  if (any(awards$recipient_type == "HOSPITAL_OR_SYSTEM")) {
    stop("[IN] a row is typed as a hospital.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The one place this file overrides the shared classifier, pinned.
in_assert_vendor_override <- function() {
  awards <- in_build_awards()
  if (!all(awards$recipient_type == "VENDOR_OR_CONTRACTOR")) {
    stop("[IN] the override no longer covers every row.", call. = FALSE)
  }
  # The divergence is real and is recorded on every row.
  diverged <- sum(!grepl("returned VENDOR_OR_CONTRACTOR",
                         awards$recipient_type_source))
  if (diverged == 0L) {
    stop("[IN] the shared classifier now agrees on every row, so the override ",
         "and its note should be removed rather than left asserting a ",
         "divergence that no longer exists.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- §0.1: the RCJ candidate disposition --------------------------------------

# The five solicitations whose award rows this file publishes. A candidate whose
# title or description carries one of these numbers is an RHTP award row; every
# other Indiana candidate is dispositioned below.
IN_RHTP_RFPS <- c("26-87448", "26-87449", "26-87450", "26-87556", "26-87667")

#' Indiana's Tier 3 candidates, re-derived from the committed record table on
#' every run (Texas's precedent) so the day the candidate set moves, the build
#' fails instead of the disposition quietly ceasing to cover it.
in_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>%
    dplyr::filter(state == IN_STATE, award_tier == "SUBAWARD",
                  qa_status != "QUARANTINED") %>%
    dplyr::mutate(
      haystack = paste(source_doc_title, program_description),
      rfp = vapply(stringr::str_extract_all(haystack,
                                            "(?<!\\d)2[46][- ]?\\d{5}(?!\\d)"),
                   function(v) {
                     v <- unique(stringr::str_replace(v, "[- ]", "-"))
                     if (length(v)) paste(v, collapse = ";") else NA_character_
                   }, character(1))
    )
}

# The disposition of every Indiana candidate that is NOT an RHTP award row.
# Each carries the disqualifying evidence and the state document that holds it,
# following Texas's and Nebraska's tables.
IN_DISPOSITIONS <- tibble::tribble(
  ~group, ~disposition, ~why, ~state_evidence,
  "RHTP award rows (26-87448, 26-87449, 26-87450)",
  "RHTP_SUBAWARD",
  paste("Named on an IDOA Preliminary Notice - Award Recommendation whose",
        "solicitation Scope of Work carries the CMS financial-assistance",
        "footer totalling $206,927,896.80."),
  "data/evidence/IN/RFP_26-87448_RHTP_MOCC_20260728.zip and siblings",

  "Indiana Community Connect (via Indiana 211)",
  "RHTP_BUT_NOT_A_SUBAWARD",
  paste("RHTP, but a BUDGET LINE and not an award. Its source document is",
        "Indiana's own GROW narrative, whose initiative table reads",
        "'2 - Growing Community Connections through Indiana 211 $3,320,000.00'",
        "-- not RCJ's $3,300,000 -- and whose contractors are unnamed and",
        "future ('The contractor will design, develop, implement, and",
        "maintain the Indiana Community Connect App'). 'Indiana Community",
        "Connect' is the PROGRAMME, not a recipient (§6.1",
        "PROGRAM_NAME_AS_AWARDEE)."),
  "data/evidence/IN/2026-08-31_RHTP-BudgetNarrative.pdf",

  "988 Contact Centers Services (RFP 26-84962)",
  "NOT_RHTP_STATE_PROCUREMENT",
  paste("Indiana's 988 crisis-line operators. IDOA's register titles this",
        "'RFP-26-84962 988 Contact Centers Services' with no RHTP marker, and",
        "its solicitation carries no CMS RHTP footer. RCJ appends 'RHTP 2026",
        "Award Announcement' to the title."),
  "data/evidence/IN/2026-08-31_idoa_award_recommendations.html",

  "Other IDOA state procurement",
  "NOT_RHTP_STATE_PROCUREMENT",
  paste("Disability determination consultants, a tobacco quitline, a workforce",
        "diploma programme, hearing aids, communication equipment, an Indiana",
        "Veterans' Home therapy contract, an ELECTRIC GENERATING FACILITY FUEL",
        "COST ANALYSIS, and a hydraulic tail trailer. All are on IDOA's",
        "general award register; none is RHTP-titled and none carries the CMS",
        "footer. Seven are filed by RCJ under the bare title 'IN - 2026 - RHTP",
        "Update' and three under a captured page header (§0.1",
        "PAGE_CHROME_TITLE)."),
  "data/evidence/IN/2026-08-31_idoa_award_recommendations.html"
)

#' §0.1 -- the arithmetic must close, and it is derived, not typed.
in_rcj_disposition <- function() {
  cands <- in_rcj_candidates()

  is_award <- !is.na(cands$rfp) &
    vapply(strsplit(cands$rfp, ";"),
           function(v) any(v %in% IN_RHTP_RFPS), logical(1))
  is_narrative <- grepl("Indiana Community Connect", cands$awardee_name_clean,
                        fixed = TRUE)
  is_988 <- grepl("84962", cands$rfp) |
    grepl("988 Contact Cent", cands$source_doc_title)

  tibble::tibble(
    group = c("RHTP award rows (26-87448, 26-87449, 26-87450)",
              "Indiana Community Connect (via Indiana 211)",
              "988 Contact Centers Services (RFP 26-84962)",
              "Other IDOA state procurement"),
    rcj_rows = c(sum(is_award), sum(is_narrative),
                 sum(is_988 & !is_award & !is_narrative),
                 sum(!is_award & !is_narrative & !is_988))
  ) %>%
    dplyr::left_join(IN_DISPOSITIONS, by = "group") %>%
    dplyr::mutate(state = IN_STATE, .before = 1)
}

in_assert_rcj_disposition <- function() {
  cands <- in_rcj_candidates()
  disp  <- in_rcj_disposition()

  if (sum(disp$rcj_rows) != nrow(cands)) {
    stop("[IN] the disposition covers ", sum(disp$rcj_rows), " of ",
         nrow(cands), " Indiana Tier 3 candidates.", call. = FALSE)
  }
  # The survey's own count for Indiana, so a moved candidate set fails here.
  survey <- readr::read_csv(
    here::here("data", "reference", "rcj_state_survey.csv"),
    show_col_types = FALSE, progress = FALSE)
  expect <- survey$tier3_candidates[survey$state == IN_STATE]
  if (nrow(cands) != expect) {
    stop("[IN] the record table holds ", nrow(cands), " Indiana Tier 3 ",
         "candidates; rcj_state_survey.csv says ", expect, ".", call. = FALSE)
  }
  # RCJ holds SIX of the seven award actions and misses two recipients
  # outright -- the two whose titles never say RHTP.
  awarded_rows <- disp$rcj_rows[disp$group ==
                                "RHTP award rows (26-87448, 26-87449, 26-87450)"]
  if (awarded_rows != 6L) {
    stop("[IN] expected 6 RCJ rows on the three RHTP-titled solicitations, ",
         "found ", awarded_rows, ".", call. = FALSE)
  }
  for (missed in c("Deloitte", "Concourse")) {
    if (any(grepl(missed, cands$awardee_name_clean, ignore.case = TRUE))) {
      stop("[IN] RCJ now holds '", missed, "'. It did not when this file was ",
           "written, and the §0.1 finding that it misses the two ",
           "non-RHTP-titled awards must be restated.", call. = FALSE)
    }
  }
  # And the label RCJ invents must still be there to be found.
  if (!any(grepl("Trail Trailer Purchase RHTP", cands$source_doc_title))) {
    stop("[IN] RCJ no longer files the trailer purchase under an RHTP title; ",
         "the §0.1 example in this file's header is stale.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- the open classification question -----------------------------------------

IN_VENDOR_TYPE_QUESTION <- "IN_PROCUREMENT_VENDOR_TYPE"

#' Indiana's one open classification question, queued for a human.
#'
#' It moves NO dollars -- all seven rows are `distributed_to_hospital = No`
#' under either answer -- but it is a deliberate divergence from the shared
#' classifier and a reviewer should sanction it rather than find it.
in_queue_row <- function() {
  tibble::tibble(
    question_id = IN_VENDOR_TYPE_QUESTION,
    state = IN_STATE,
    row_key = "all 7 rows of in_year1_awardees.csv",
    opened_session = 24,
    opened_date = as.Date("2026-08-31"),
    queue_status = "OPEN",
    question = paste(
      "Is a company selected through a competitive state RFP",
      "VENDOR_OR_CONTRACTOR on the strength of the procurement itself, or",
      "does §8's standing fallback (NONPROFIT_CBO + LOW +",
      "RECIPIENT_TYPE_INFERRED) apply because IDOA publishes no",
      "organisation-type column?"),
    options = paste(
      "VENDOR_OR_CONTRACTOR + MEDIUM (what this file publishes) |",
      "NONPROFIT_CBO + LOW + RECIPIENT_TYPE_INFERRED (what",
      "rhtp_classify_recipient_type() returns for 6 of the 7)"),
    why_it_is_open = paste(
      "Kansas, Maryland and Nebraska all publish a recipient and an amount and",
      "nothing about the recipient's form, and each took §8's fallback.",
      "Indiana is the first state whose awards are PROCUREMENT CONTRACTS",
      "rather than grants, and its source does state a form in its own words:",
      "IDOA 'has identified the following companies as the selected",
      "respondents' to a competitive RFP, and all seven names carry a",
      "corporate suffix (LLC, Inc, LLP). That is a determinable form, so this",
      "file types from the source rather than from the fallback. The",
      "classifier's own value is preserved on every row in",
      "recipient_type_source, so the override is auditable and reversible."),
    dollar_effect = "$0 -- all seven rows are distributed_to_hospital = No under either answer",
    evidence_path = "data/evidence/IN/RFP_26-87448_RHTP_MOCC_20260728.zip",
    source_url = "https://www.in.gov/idoa/procurement/award-recommendations/",
    resolved_by = NA,
    resolved_date = NA,
    resolution = NA
  )
}

in_assert_vendor_question_queued <- function() {
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- q[q$question_id == IN_VENDOR_TYPE_QUESTION, ]
  if (nrow(row) != 1L) {
    stop("[IN] ", IN_VENDOR_TYPE_QUESTION, " is not in the review queue.",
         call. = FALSE)
  }
  if (!grepl("VENDOR_OR_CONTRACTOR", row$options[1]) ||
      !grepl("NONPROFIT_CBO", row$options[1])) {
    stop("[IN] the queued question no longer offers both answers.",
         call. = FALSE)
  }
  if (!grepl("^\\$0", row$dollar_effect[1])) {
    stop("[IN] the queued question's dollar effect is no longer $0; if it ",
         "moves money it must be resolved, not queued.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- validate / build / report ------------------------------------------------

in_validate <- function() {
  in_assert_rhtp_funded()
  in_assert_after_noa()
  in_assert_not_executed()
  in_assert_award_register()
  in_assert_non_rhtp_control()
  in_assert_regional_not_awarded()
  in_assert_committee_not_recipients()
  in_assert_recipients_in_source()
  in_assert_proposers_not_awarded()
  in_assert_no_hospital_dollars()
  in_assert_vendor_override()
  in_assert_rcj_disposition()
  in_assert_vendor_question_queued()
  message("[IN] all assertions pass.")
  invisible(TRUE)
}

in_build <- function() {
  awards <- in_build_awards()
  readr::write_csv(awards, IN_OUTPUT_CSV, na = "")
  message("[IN] wrote ", IN_OUTPUT_CSV, " (", nrow(awards), " rows)")

  disp <- in_rcj_disposition()
  readr::write_csv(disp, IN_DISPOSITION_CSV, na = "")
  message("[IN] wrote ", IN_DISPOSITION_CSV, " (", nrow(disp), " rows)")

  in_write_workbook(awards, disp)
  message("[IN] wrote ", IN_OUTPUT_XLSX)
  invisible(awards)
}

in_write_workbook <- function(awards, disp) {
  wb <- openxlsx::createWorkbook()

  # Sheet 1 is the warning, on Oregon's and Illinois's precedent: the first
  # thing a reader sees is what this file is not.
  openxlsx::addWorksheet(wb, "READ FIRST")
  warning_rows <- tibble::tibble(
    `Indiana RHTP Year 1 -- read before using any figure` = c(
      "SEVEN award actions, SEVEN recipients, and NOT ONE IS A HOSPITAL.",
      "Every recipient is a consultancy or technology company selected through",
      "a competitive state RFP. Indiana has distributed $0 to hospitals so far.",
      "",
      "THESE ARE NOT EXECUTED AWARDS. Every one is an IDOA 'Preliminary Notice",
      "- Award Recommendation', conditioned on contract finalisation, quoting",
      "I.C. 4-13-1-19: a respondent 'does not gain a property interest ... unless",
      "... the contract is completely executed'. All rows are",
      "NOTICE_OF_INTENT_TO_AWARD + amount_confirmed = No.",
      "",
      "ONLY ONE AMOUNT IS PUBLISHED, AND IT IS A FIVE-YEAR FIGURE.",
      "Laurel Health Advisors LLC, $860,088.00, stated by the state as",
      "'5-year Contract Value'. It is NOT a Year 1 award and must not be",
      "compared with other states' Year 1 grant amounts. The other six",
      "documents publish no amount at all, so their `amount` is EMPTY.",
      "",
      "WHERE INDIANA'S HOSPITAL MONEY WILL BE: GROW Regional Grants --",
      "'$120M awarded annually across eight regional coalitions' -- which the",
      "state's own page says LAUNCHES SEPT. 1, 2026. It had not awarded when",
      "this file was built (2026-08-31). This file will understate Indiana",
      "badly once it does.",
      "",
      "THE REGIONAL GRANTS PAGE IS A §0.3 TRAP. It carries fifteen tables of",
      "named people against named hospitals (Goshen Health, Parkview Health,",
      "Reid Health, Woodlawn Hospital ...). Those are REGIONAL COMMITTEE",
      "MEMBERS -- an advisory body that SCORES applications -- not recipients.",
      "Its eight-row per-region dollar table is a CAPITAL EXPENDITURE CEILING,",
      "not an award table."
    )
  )
  openxlsx::writeData(wb, "READ FIRST", warning_rows)
  openxlsx::setColWidths(wb, "READ FIRST", 1, 100)

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", awards)
  openxlsx::freezePane(wb, "Awards", firstRow = TRUE)

  openxlsx::addWorksheet(wb, "RCJ disposition")
  openxlsx::writeData(wb, "RCJ disposition", disp)

  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", in_reconciliation())

  openxlsx::saveWorkbook(wb, IN_OUTPUT_XLSX, overwrite = TRUE)
}

in_reconciliation <- function() {
  awards <- in_build_awards()
  tibble::tibble(
    item = c(
      "Award actions published by Indiana",
      "Distinct recipients",
      "Solicitations (RFPs)",
      "Award documents",
      "Hospitals among the recipients",
      "Dollars distributed to hospitals",
      "Total amount published by Indiana",
      "Rows carrying an amount",
      "Rows with NO amount published",
      "CMS FY2026 allotment (§7.1)",
      "Published as a share of the allotment",
      "GROW Regional Grants (hospital-facing)",
      "RCJ Tier 3 candidates",
      "RCJ candidates that are RHTP awards",
      "RCJ candidates that are NOT RHTP"
    ),
    value = c(
      as.character(nrow(awards)),
      as.character(dplyr::n_distinct(awards$awardee)),
      as.character(dplyr::n_distinct(awards$solicitation_number)),
      "6",
      "0",
      "$0",
      paste0("$", formatC(sum(awards$amount, na.rm = TRUE),
                          format = "f", digits = 2, big.mark = ",")),
      as.character(sum(!is.na(awards$amount))),
      as.character(sum(is.na(awards$amount))),
      paste0("$", formatC(in_allotment(), format = "d", big.mark = ",")),
      paste0(round(100 * sum(awards$amount, na.rm = TRUE) / in_allotment(), 3),
             "%"),
      "NOT YET AWARDED -- launches 2026-09-01, $120M/yr across 8 coalitions",
      as.character(nrow(in_rcj_candidates())),
      "6",
      "30"
    ),
    note = c(
      "Five solicitations; 26-87448 names three companies on one document",
      "No recipient holds two awards",
      "26-87448, 26-87449, 26-87450, 26-87556, 26-87667",
      "26-87449 is documented twice: a 2026-06-03 notice and a 2026-08-21 letter",
      "§0.3a: every recipient is a consultancy or technology company",
      "The headline finding for Indiana",
      "One row. See flag AMOUNT_IS_MULTI_YEAR_TOTAL",
      "Laurel Health Advisors LLC only",
      "Indiana's award recommendations do not state contract values",
      "Read from cms_fy2026_allotments.csv, never typed",
      "A five-year contract value over a one-year allotment: not a burn rate",
      "This is where Indiana's hospital dollars will appear",
      "Re-derived from stage2_record_table.rds on every run",
      "26-87448 x3, 26-87449 x2, 26-87450 x1. RCJ misses Deloitte and Concourse",
      "988 crisis lines, a fuel cost analysis, a trailer, and 27 others"
    )
  )
}


in_report <- function() {
  awards <- in_build_awards()
  disp   <- in_rcj_disposition()

  cat("\nINDIANA -- GROW / Rural Health Transformation Program, Year 1\n")
  cat(strrep("=", 78), "\n\n")

  cat("WHAT INDIANA HAS PUBLISHED: 7 award actions, 7 recipients, 5 RFPs.\n")
  cat("NOT ONE IS A HOSPITAL. $0 has reached a hospital.\n\n")
  print(as.data.frame(awards[, c("row_no", "awardee", "amount", "award_pool",
                                 "flow_type")]), row.names = FALSE)

  cat("\nTHEY ARE NOT EXECUTED AWARDS. Every one is an IDOA 'Preliminary\n")
  cat("Notice - Award Recommendation' conditioned on contract finalisation,\n")
  cat("quoting I.C. 4-13-1-19. All rows: NOTICE_OF_INTENT_TO_AWARD.\n")

  cat("\nTHE ONE AMOUNT IS A FIVE-YEAR CONTRACT VALUE, NOT YEAR 1:\n")
  cat("  Laurel Health Advisors LLC  $860,088.00  ('5-year Contract Value')\n")
  cat("  The other six documents publish no amount at all.\n")

  cat("\n§6.2 PROVENANCE -- passed, in the strongest form in the project:\n")
  cat("  All five solicitations' Scope of Work carry, verbatim:\n")
  cat("    '", IN_RHTP_FOOTER, "'\n", sep = "")
  cat("  which matches the §7.1 allotment ($",
      formatC(in_allotment(), format = "d", big.mark = ","),
      ") to the dollar, and\n", sep = "")
  cat("  the state states its own NOA date: 'On Dec. 29, 2025, Indiana was\n")
  cat("  awarded a grant of nearly $207 million' -- the §6.2 anchor exactly.\n")

  cat("\n  AND THE PROVENANCE IS NOT ON THE AWARD LETTER. Two of the five RFPs\n")
  cat("  (26-87556 Preceptor Registry, 26-87667 ACO Feasibility) say 'RHTP'\n")
  cat("  NOWHERE in their IDOA title or their award letter. They are RHTP\n")
  cat("  because their SCOPE OF WORK says so. Keyed on the award document\n")
  cat("  alone, both would have been dropped.\n")

  cat("\n§0.1 -- RCJ's 37 Indiana candidates, and the worst ratio in the project:\n")
  print(as.data.frame(disp[, c("group", "rcj_rows", "disposition")]),
        row.names = FALSE)
  cat("\n  RCJ does not merely mis-title the 30. It APPENDS AN RHTP LABEL THEY\n")
  cat("  DO NOT HAVE -- 'Indiana Negotiated Bid 26-87613 For Hydraulic Trail\n")
  cat("  Trailer Purchase RHTP 2026 Award Announcement' is a trailer, and the\n")
  cat("  state's own letter recommends 'a one-time purchase with an amount of\n")
  cat("  $90,000'. Seven more sit under the bare title 'IN - 2026 - RHTP\n")
  cat("  Update', among them an ELECTRIC GENERATING FACILITY FUEL COST\n")
  cat("  ANALYSIS. An extractor built from the candidate list would have\n")
  cat("  published roughly $147M of unrelated state procurement as RHTP.\n")
  cat("\n  And RCJ MISSES two of the seven real awards -- Deloitte and\n")
  cat("  Concourse Tech -- the two whose titles never say RHTP.\n")

  cat("\nTHE POSITIVE CONTROL: IDOA's award register carries 456 award\n")
  cat("  recommendations in one uniform form, and this file parses seven names\n")
  cat("  out of six of them. 'Indiana has published no hospital roster' is a\n")
  cat("  statement about Indiana, not about our ability to read its site.\n")

  cat("\nWHERE INDIANA'S HOSPITAL MONEY WILL BE, AND WHY IT IS NOT HERE:\n")
  cat("  GROW Regional Grants -- '$120M awarded annually across eight regional\n")
  cat("  coalitions' -- which Indiana's own page says LAUNCHES SEPT. 1, 2026.\n")
  cat("  As of this build (2026-08-31) it has not awarded: the page's timeline\n")
  cat("  reads 'RFF Applications submitted July 1' and the state 'will convene\n")
  cat("  an application review team that will score applications and determine\n")
  cat("  funding'. in_assert_regional_not_awarded() fails the day that changes.\n")

  cat("\n  THAT PAGE IS THE BIGGEST §0.3 TRAP THIS PROJECT HAS MET. Fifteen\n")
  cat("  tables of named people against named hospitals -- Goshen Health,\n")
  cat("  Parkview Health, Reid Health, Woodlawn Hospital, Pulaski Memorial --\n")
  cat("  which are REGIONAL COMMITTEE MEMBERS, an advisory body appointed to\n")
  cat("  SCORE the applications. Beside them an eight-row table of per-region\n")
  cat("  dollar figures that are CAPITAL EXPENDITURE CEILINGS. A table of\n")
  cat("  eight regions against eight dollar amounts, on the awarding agency's\n")
  cat("  own grants page, is as close to a publishable award table as a\n")
  cat("  non-award can look.\n")

  cat("\nRECONCILIATION\n")
  print(as.data.frame(in_reconciliation()), row.names = FALSE)
  invisible(TRUE)
}


# -- CLI ----------------------------------------------------------------------

if (identical(environment(), globalenv()) && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args)    print(as.data.frame(
                                in_fetch(force = "--force" %in% args)[, c("key", "bytes")]))
  if ("--validate" %in% args) in_validate()
  if ("--build" %in% args)    { in_validate(); in_build() }
  if ("--report" %in% args)   in_report()
  if (!length(intersect(args, c("--fetch", "--validate", "--build", "--report")))) {
    cat("usage: Rscript R/03s_in_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report]\n")
  }
}

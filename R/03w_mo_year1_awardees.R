# 03w_mo_year1_awardees.R -----------------------------------------------------
# Missouri Year 1 -> data/reference/mo_year1_awardees.csv
#                    data/reference/mo_hub_anchors.csv
#                    data/reference/mo_rcj_candidate_disposition.csv
#
# WHY MISSOURI. It led `state_trigger_queue.csv` once Michigan was extracted --
# 29 Tier 3 candidates, 29 distinct awardees, a $216,276,818 allotment, no CMS
# press release, and never investigated.
#
# WHAT MISSOURI HAS PUBLISHED, AND IT IS THE SHAPE THIS PROJECT HAS NOT MET.
# DSS publishes a NAMED, RECIPIENT-LEVEL, TWENTY-SEVEN-ROW ROSTER -- one
# organisation per ToRCH Care Hub, fourteen of them hospitals or health systems
# by name (and eleven more whose form DSS never states) -- and NOT ONE OF THOSE
# TWENTY-SEVEN IS AN AWARD. They are Hub
# ANCHORS: organisations selected to CONVENE a hub, chosen competitively from
# 41 applications, announced 2026-07-17. DSS attaches no dollar figure to any
# of them anywhere, and its own FAQ answers the question directly:
#
#   Q36. Will Hub Anchors receive funding or compensation?
#   "Hub Anchors will NOT ACT AS THE FISCAL AGENT. ... The State will fund
#    additional staff to support implementation via the Healthier Communities
#    Together entity."
#
# and the release adds that "formal participation ... as a Hub Anchor is
# subject to execution of a Hub Anchor Participation Agreement" -- an agreement
# that has not been executed. So the roster is a selection to a governance
# role, and coding it as receipt would be §0.3's exact failure at the scale of
# a whole state: fourteen named hospitals, `distributed_to_hospital = Yes`, and
# NO MONEY BEHIND ANY OF THEM.
#
# It is kept -- in its OWN FILE, `mo_hub_anchors.csv`, which has NO `amount`
# COLUMN AT ALL and an assertion refusing one (Texas's device). The roster is
# a real and quotable finding about which organisations lead Missouri's RHTP;
# it is not a hospital dollar and it must never be unioned with an award file.
#
# WHAT MISSOURI HAS ACTUALLY AWARDED: TWO NAMED PARTNERSHIPS, $7,232,660.43.
#
#   Missouri Doula Association          $732,660.43   awarded, exact, 2026-07-20
#   Missouri EMS Association (MEMSA)  ~$6,500,000     "around $6.5M through
#                                                     July 31, 2027", 2026-07-24
#
# Both are pass-through administrators and NEITHER reaches a hospital. MDA
# trains doulas and perinatal community health workers; MEMSA re-grants to
# rural EMS agencies at up to $250,000 (agency) or $500,000 (regional system)
# and has named none of them. Missouri's named-hospital dollars are $0.
#
# THE TEXAS CHECK, RUN FIRST AND PASSED -- WITH THE FOOTER DOWNGRADED, WHICH IS
# SESSION 27'S AUDIT APPLIED TO A NEW STATE. Every DSS release and the FAQ
# carry a CMS financial-assistance footer, and it is the WEAK form: its subject
# is "The Rural Health Transformation Program INFORMATION PROVIDED BY the
# Missouri Department of Social Services", i.e. the publication. Nevada is why
# that is not enough on its own (session 26). So the footer is used here to
# corroborate the AMOUNT -- $216,276,817.66 against the §7.1 anchor's
# $216,276,818 -- and three PROGRAMME-SCOPED sentences carry the provenance:
#
#   1. "$732,660.43 was awarded to the MDA ... The investment IS PART OF THE
#      RHTP" -- the award action itself, said to be RHTP.
#   2. "DSS, THROUGH THE RURAL HEALTH TRANSFORMATION PROGRAM (RHTP), has
#      announced a partnership ... Administered by DSS on behalf of CMS".
#   3. "DSS has selected Hub Anchor organizations to help lead implementation
#      of MISSOURI'S RURAL HEALTH TRANSFORMATION PROGRAM (RHTP)".
#
# And the date test: every one of these documents is dated July 2026, seven
# months after Missouri's 2025-12-29 Notice of Award.
#
# THE POSITIVE CONTROL, IN TWO PARTS, BECAUSE MISSOURI HAS TWO AWARD CHANNELS.
#   - DSS demonstrably publishes an award roster in a recognisable form when it
#     has one: the Hub Anchor PDF hangs off a "View Organizations" link on the
#     programme page. There is exactly ONE such roster link and a second would
#     mean Missouri has published a pool this file does not carry.
#   - Indiana's sixth question: IS THE AWARD CHANNEL PROCUREMENT? For Missouri
#     it explicitly is -- DSS's own RHTP timeline reads "Aug - Sept 2026
#     Announce select procurement awardees" -- so `dss.mo.gov/bids` is archived
#     too. It carries a bid table with real, current solicitations (IFB
#     DSS26015-02 closing 2026-09-01) and NO awards, which is what makes "no
#     procurement award list" a finding rather than a failed search.
#
# WHAT RCJ GOT WRONG, AND IT IS A MECHANISM THIS PROJECT HAS NOT RECORDED.
# RCJ's 29 Missouri Tier 3 candidates are: the 27 Hub Anchors, each carrying an
# amount of $1, plus MEMSA and MDA. So 27 of 29 -- 93% -- are a GOVERNANCE-ROLE
# SELECTION PRESENTED AS AWARDS, complete with hospital names. Texas's defect
# was the wrong PROGRAMME, Oregon's the wrong RECIPIENT CLASS, Indiana's an
# INVENTED label, Oklahoma's the wrong TIER, Michigan's one row per
# ORGANISATION -- Missouri's is the wrong KIND OF ACTION, and it is the one an
# amount check cannot see, because RCJ publishes $1 rather than a wrong figure.
# It also understates the one exact award it holds: $732,000 against DSS's
# $732,660.43.
#
# ONE HOST IS UNREACHABLE AND IS RECORDED AS UNREACHABLE, NOT AS A NEGATIVE.
# `memsa.org/rht-funding/` -- where MEMSA's own sub-awardee list would be --
# answers HTTP 202 with a `sgcaptcha` redirect to every client tried. So this
# file cannot say whether MEMSA has named its EMS sub-awardees; it says it does
# not know, which is a different claim (§0.4).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "02_normalize.R"))
source(here::here("R", "utils_recipient_classification.R"))

MO_EVIDENCE_DIR <- here::here("data", "evidence", "MO")
MO_CSV          <- "data/reference/mo_year1_awardees.csv"
MO_HUB_CSV      <- "data/reference/mo_hub_anchors.csv"
MO_DISPO_CSV    <- "data/reference/mo_rcj_candidate_disposition.csv"
MO_XLSX         <- "MO_year1_awardees.xlsx"
MO_HOST_THROTTLE_S <- 3
MO_USER_AGENT <- paste(
  "RHTP-Tracker/0.1 (AHA Data & Policy research;",
  "+https://www.aha.org)"
)

MO_PROGRAM_PAGE <- "https://dss.mo.gov/mhd/rural-health"

MO_SOURCES <- tibble::tribble(
  ~key,           ~file,                                       ~url,
  "program_page", "2026-09-01_dss_rural_health.html",
  MO_PROGRAM_PAGE,
  "hub_roster",   "2026-07-17_rhtp_hub_anchors.pdf",
  "https://dss.mo.gov/sites/mydss/files/media/pdf/2026/07/RHTP-Hub-Anchors-07-17-2026.pdf",
  "pr_hub",       "2026-07-17_dss_hub_anchors_release.html",
  "https://content.govdelivery.com/accounts/MODSS/bulletins/420acc4",
  "pr_doula",     "2026-07-20_dss_maternal_partnership_release.html",
  "https://content.govdelivery.com/accounts/MODSS/bulletins/420f3bd",
  "pr_memsa",     "2026-07-24_dss_mih_cp_release.html",
  "https://content.govdelivery.com/accounts/MODSS/bulletins/421d56d",
  "torch_faq",    "2026-07-02_torch_care_faqs.pdf",
  "https://dss.mo.gov/sites/mydss/files/media/pdf/2026/07/20260702_ToRCH%20Care%20FAQs.pdf",
  "bids",         "2026-09-01_dss_bid_proposals.html",
  "https://dss.mo.gov/bids/",
  "ctf",          "2026-09-01_ctf_funding_opportunities.html",
  "https://ctf4kids.org/ctf-funding-opportunities/"
)

# Every figure below is quoted from a source archived under data/evidence/MO/
# and every one is asserted against the parse.
MO_STATED <- list(
  hub_anchors_n     = 27L,
  hub_applications  = 41L,
  hub_announced     = "2026-07-17",
  # 14 of the 27 classify as hospitals or health systems on the recipient's own
  # NAME. Eleven more carry §8's standing fallback -- the unstated-form question
  # a SEVENTH time -- and several of those read as hospitals to anyone who knows
  # Missouri (Ozarks Healthcare, Golden Valley Memorial Healthcare, Bothwell
  # Regional Health Center, Hannibal Regional Health Center, Parkland Health
  # Center). NOTHING IS PROMOTED (§0.4). It is worth $0 in either direction,
  # because DSS attaches no money to the role at all -- the question moves a
  # COUNT, which is Nevada's shape, and the CCN match resolves it.
  anchor_hospitals_named = 14L,
  anchor_form_not_stated = 11L,
  mda_amount        = 732660.43,
  memsa_amount      = 6500000,
  awards_n          = 2L,
  awards_total      = 7232660.43,
  # DSS's own footer figure, and CMS's table. They agree once rounded.
  cms_award_stated  = 216276817.66,
  cms_allotment     = 216276818,
  noa_date          = "2025-12-29",
  # RCJ's figure for the one exact award it holds. It is short by $660.43.
  rcj_mda_amount    = 732000
)

# THE PROVENANCE, PROGRAMME-SCOPED. Session 27's audit, applied at the point of
# extraction rather than afterwards: the footer's subject is the publication,
# so it corroborates the amount and nothing else. Each string below has the
# AWARD ACTION or THE PROGRAMME as its grammatical subject.
MO_PROVENANCE <- list(
  doula_award = paste(
    "$732,660.43 was awarded to the MDA to strengthen rural doula training and",
    "certification infrastructure across the state"),
  doula_is_rhtp = "The investment is part of the RHTP",
  memsa_through_rhtp = paste(
    "Missouri Department of Social Services (DSS), through the Rural Health",
    "Transformation Program (RHTP), has announced a partnership"),
  hub_is_rhtp = paste(
    "selected Hub Anchor organizations to help lead implementation of",
    "Missouri’s Rural Health Transformation Program (RHTP)"),
  # The WEAK form, asserted PRESENT so its weakness stays visible rather than
  # being quietly forgotten. Subject: "information provided by".
  weak_footer = paste(
    "The Rural Health Transformation Program information provided by the",
    "Missouri Department of Social Services is supported by the Centers for",
    "Medicare & Medicaid Services (CMS)")
)

# WHY THE 27 ARE NOT AWARDS, IN DSS'S OWN WORDS. Both sentences are asserted
# every run; either one going is a change in what Missouri is claiming, and
# `mo_assert_anchors_not_awarded()` is DESIGNED TO FAIL on it.
MO_NOT_AN_AWARD <- c(
  fiscal_agent = "Hub Anchors will not act as the fiscal agent",
  unexecuted   = paste(
    "Formal participation in the Rural Health Transformation Program as a Hub",
    "Anchor is subject to execution of a Hub Anchor Participation Agreement")
)

# The procurement channel's own words, from DSS's RHTP timeline. Missouri says
# outright that its awards are coming through procurement, which is Indiana's
# sixth question answered by the state rather than inferred.
# Regex, not a fixed string: DSS renders this as a table and the archived
# text runs the date cell straight into the event cell with no separator.
MO_PROCUREMENT_PENDING <- "Aug\\s*-\\s*Sept 2026\\s*Announce select procurement awardees"
MO_OPEN_SOLICITATION   <- "IFB # DSS26015-02"

# The one roster link. A second means Missouri has published a pool this file
# does not carry -- the tripwire, in both directions.
MO_ROSTER_LINK  <- "rural-health-transformation-hub-anchors-announced-july-2026"
# A roster on this site is a DOCUMENT off DSS's own media library whose link
# text names recipients. The exclusions are not convenience: DSS publishes the
# Hub Anchor APPLICATION and the invitation-to-apply RELEASE under link text
# that also says "Hub Anchor", and a control that fired on those would have to
# be widened every time -- which is how a tripwire becomes decoration.
MO_ROSTER_DOC_HREF <- "/media/(pdf|file)/|/sites/mydss/files/media/"
MO_ROSTER_SHAPE    <- paste0(
  "(?i)(hub anchors|award winners|awardees|award recipients|",
  "selected organizations|funded (projects|organizations)|subrecipients)")
MO_ROSTER_NOT      <- "(?i)(application|apply|packet|invit|boundar|job description|manual|faq)"

MO_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9_-]{10,}",
  google_api_key = "AIza[A-Za-z0-9_-]{30,}",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)


# -- fetch -------------------------------------------------------------------

mo_path <- function(key) {
  row <- MO_SOURCES[MO_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[MO] unknown source key: ", key, call. = FALSE)
  file.path(MO_EVIDENCE_DIR, row$file)
}

mo_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt   <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(MO_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, MO_CREDENTIAL_SHAPES[[nm]])) {
      stop("[MO] refusing to archive ", label, ": it carries what looks like ",
           "a ", nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

mo_get <- function(url, label) {
  message("[MO] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(MO_USER_AGENT), httr::timeout(240))
  if (httr::status_code(resp) != 200L) {
    stop("[MO] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  mo_assert_credential_free(served, label)
  served
}

mo_fetch <- function(force = FALSE) {
  dir.create(MO_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)

  entries <- purrr::map_dfr(seq_len(nrow(MO_SOURCES)), function(i) {
    src  <- MO_SOURCES[i, ]
    dest <- file.path(MO_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[MO] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(MO_HOST_THROTTLE_S)
      writeBin(mo_get(src$url, src$file), dest)
    }
    tibble::tibble(
      file   = src$file,
      url    = src$url,
      bytes  = file.size(dest),
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })

  mo_write_manifest(entries)
  invisible(entries)
}

mo_write_manifest <- function(entries) {
  path <- file.path(MO_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Missouri -- DSS Rural Health Transformation Program / ToRCH Care.",
    "Archived by R/03w_mo_year1_awardees.R --fetch",
    paste0("User-agent: ", MO_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below.",
    "The credential guard that caught CMS's Mapbox token, Illinois's and",
    "Oregon's, and Kansas's Google Maps key runs on every fetch here and finds",
    "nothing, so there is no reduction to explain.",
    "",
    "RHTP-Hub-Anchors-07-17-2026.pdf IS A ROSTER AND IS NOT AN AWARD LIST.",
    "It names 27 organisations, one per ToRCH Care Hub, and carries no dollar",
    "figure of any kind. DSS's own FAQ (20260702_ToRCH Care FAQs.pdf, Q36)",
    "says 'Hub Anchors will not act as the fiscal agent', and the 2026-07-17",
    "release says participation is 'subject to execution of a Hub Anchor",
    "Participation Agreement'. Fourteen of the 27 are hospitals or health",
    "systems by name, and RCJ files all 27 as Tier 3 awards at $1 each. Reading this",
    "file as an award list is the §0.3 failure at the scale of a state.",
    "",
    "2026-09-01_dss_bid_proposals.html IS THE PROCUREMENT-CHANNEL CONTROL.",
    "DSS's own RHTP timeline says 'Aug - Sept 2026 Announce select procurement",
    "awardees', so Missouri's awards are coming through procurement (Indiana's",
    "sixth question, answered by the state rather than inferred). The bid table",
    "carries live solicitations -- IFB DSS26015-02 closed 2026-09-01 -- and no",
    "awards, which is what makes the absence a finding.",
    "",
    "2026-09-01_ctf_funding_opportunities.html IS THE PASS-THROUGH CONTROL.",
    "The Children's Trust Fund administers $588,000/yr of RHTP home-visiting",
    "money; its funding page reads 'Stay tuned for future' and names nobody.",
    "",
    "NOT ARCHIVED, AND RECORDED AS UNREACHABLE RATHER THAN NEGATIVE:",
    "https://memsa.org/rht-funding/ answers HTTP 202 with an sgcaptcha",
    "redirect to every client tried, so whether MEMSA has named its EMS",
    "sub-awardees is UNKNOWN, not answered.",
    "",
    "MANIFEST.txt is deliberately absent from this listing: a manifest cannot",
    "record its own digest (session 15).",
    "",
    paste0(entries$sha256, "  ", entries$file, "  (", entries$bytes,
           " bytes)  <- ", entries$url)
  ), path)
  invisible(path)
}


# -- read --------------------------------------------------------------------

mo_html_text <- function(key) {
  path <- mo_path(key)
  if (!file.exists(path)) {
    stop("[MO] ", basename(path), " is not archived. Run --fetch.",
         call. = FALSE)
  }
  doc <- xml2::read_html(path)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

mo_links <- function(key = "program_page") {
  doc <- xml2::read_html(mo_path(key))
  tibble::tibble(
    href = xml2::xml_attr(xml2::xml_find_all(doc, "//a"), "href"),
    text = stringr::str_squish(xml2::xml_text(xml2::xml_find_all(doc, "//a")))
  ) %>%
    dplyr::filter(!is.na(href))
}

mo_pdf_lines <- function(key) {
  path <- mo_path(key)
  if (!file.exists(path)) {
    stop("[MO] ", basename(path), " is not archived. Run --fetch.",
         call. = FALSE)
  }
  rhtp_pdf_text(path)
}

mo_pdf_text <- function(key) {
  stringr::str_squish(paste(mo_pdf_lines(key), collapse = " "))
}


# -- provenance --------------------------------------------------------------

#' The §6.2 check, with the CMS footer downgraded to programme-scoped evidence
#'
#' Three sentences whose subject is the award action or the programme, one per
#' document; the footer afterwards, corroborating the AMOUNT only.
mo_assert_rhtp_provenance <- function() {
  doula <- mo_html_text("pr_doula")
  memsa <- mo_html_text("pr_memsa")
  hub   <- mo_html_text("pr_hub")

  checks <- list(
    doula_award        = list(MO_PROVENANCE$doula_award, doula),
    doula_is_rhtp      = list(MO_PROVENANCE$doula_is_rhtp, doula),
    memsa_through_rhtp = list(MO_PROVENANCE$memsa_through_rhtp, memsa),
    hub_is_rhtp        = list(MO_PROVENANCE$hub_is_rhtp, hub)
  )
  for (nm in names(checks)) {
    if (!stringr::str_detect(checks[[nm]][[2]],
                             stringr::fixed(checks[[nm]][[1]]))) {
      stop("[MO] the programme-scoped provenance sentence '", nm,
           "' is gone:\n  ", checks[[nm]][[1]], "\n",
           "The CMS footer on these releases is the WEAK form -- its subject ",
           "is 'the RHTP information provided by DSS', i.e. the publication ",
           "(session 26, Nevada; session 27's audit). It cannot stand in for ",
           "this. Re-read the release.", call. = FALSE)
    }
  }

  # The footer, corroborating the AMOUNT. Present on every DSS document here.
  stated <- NA_real_
  for (k in c("pr_doula", "pr_memsa", "pr_hub")) {
    one <- mo_html_text(k)
    if (!stringr::str_detect(one, stringr::fixed(MO_PROVENANCE$weak_footer))) {
      stop("[MO] ", k, " no longer carries the CMS financial-assistance ",
           "footer. It is corroborating rather than load-bearing, but its ",
           "disappearance is still a change worth reading.", call. = FALSE)
    }
    got <- stringr::str_match(
      one, "financial assistance award totaling \\$([0-9][0-9,]*\\.[0-9]{2})")[, 2]
    got <- as.numeric(gsub(",", "", got))
    if (is.na(stated)) stated <- got
    if (!identical(stated, got)) {
      stop("[MO] DSS states two different award totals across its own ",
           "releases: ", stated, " and ", got, ".", call. = FALSE)
    }
  }
  invisible(stated)
}

#' The date test. Every Missouri document here postdates the NOA by 7 months.
mo_assert_after_noa <- function() {
  noa <- rhtp_read_noa_dates()
  anchor <- as.character(noa$noa_date[noa$state == "MO"])
  if (!identical(anchor, MO_STATED$noa_date)) {
    stop("[MO] cms_state_noa_dates.csv says ", anchor, call. = FALSE)
  }
  hub <- mo_html_text("pr_hub")
  if (!stringr::str_detect(hub, stringr::fixed("July 17, 2026"))) {
    stop("[MO] the Hub Anchor release no longer carries its own date.",
         call. = FALSE)
  }
  if (!stringr::str_detect(mo_html_text("pr_doula"),
                           stringr::fixed("July 20, 2026"))) {
    stop("[MO] the maternal partnership release no longer carries its date.",
         call. = FALSE)
  }
  if (as.Date("2026-07-17") <= as.Date(anchor)) {
    stop("[MO] the award actions do not postdate the Notice of Award.",
         call. = FALSE)
  }
  invisible(anchor)
}


# -- the controls ------------------------------------------------------------

#' THE ONE THAT DECIDES THE WHOLE FILE: the 27 are a selection, not an award
#'
#' Both of DSS's own disqualifying sentences, asserted every run, plus the fact
#' that the roster PDF carries no currency at all. Designed to FAIL the day
#' Missouri attaches money to the Hub Anchor role -- at which point these are
#' award rows and this file must be rewritten rather than patched.
mo_assert_anchors_not_awarded <- function(roster = NULL, faq = NULL,
                                         hub = NULL) {
  if (is.null(faq)) faq <- mo_pdf_text("torch_faq")
  if (is.null(hub)) hub <- mo_html_text("pr_hub")
  if (is.null(roster)) roster <- mo_pdf_text("hub_roster")

  if (!stringr::str_detect(faq,
                           stringr::fixed(MO_NOT_AN_AWARD[["fiscal_agent"]]))) {
    stop("[MO] the ToRCH Care FAQ no longer says 'Hub Anchors will not act as ",
         "the fiscal agent'. THAT SENTENCE IS WHY THIS FILE CARRIES 27 NAMED ",
         "ORGANISATIONS AND $0. Re-read Q36 before changing anything.",
         call. = FALSE)
  }
  if (!stringr::str_detect(hub,
                           stringr::fixed(MO_NOT_AN_AWARD[["unexecuted"]]))) {
    stop("[MO] the Hub Anchor release no longer says participation is subject ",
         "to execution of a Participation Agreement.", call. = FALSE)
  }

  if (stringr::str_detect(roster, "\\$\\s?[0-9]")) {
    stop("[MO] THE HUB ANCHOR ROSTER NOW CARRIES A DOLLAR FIGURE.\n",
         "This file's entire design rests on its absence: 27 named ",
         "organisations, 17 of them hospitals, and no money. If Missouri has ",
         "attached amounts to the Hub Anchor role these are award rows and ",
         "mo_hub_anchors.csv must be rebuilt as one -- rewritten, not patched.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The roster control: DSS publishes a roster in a recognisable form
mo_assert_roster_index <- function(links = NULL) {
  if (is.null(links)) links <- mo_links("program_page")

  if (!any(stringr::str_detect(links$href,
                               stringr::fixed(MO_ROSTER_LINK)))) {
    stop("[MO] the programme page no longer links the Hub Anchor roster. ",
         "That link is this file's POSITIVE CONTROL.", call. = FALSE)
  }
  shaped <- links %>%
    dplyr::filter(stringr::str_detect(href, MO_ROSTER_DOC_HREF),
                  stringr::str_detect(text, MO_ROSTER_SHAPE),
                  !stringr::str_detect(text, MO_ROSTER_NOT),
                  !stringr::str_detect(href, stringr::fixed(MO_ROSTER_LINK)))
  if (nrow(shaped) > 0) {
    stop("[MO] the programme page links a roster this file does not carry:\n",
         paste0("  ", shaped$text, " -> ", shaped$href, collapse = "\n"),
         "\nExtract it; do not widen this assertion.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Indiana's sixth question, answered by Missouri itself: the channel is
#' PROCUREMENT, and it has published no awards through it yet
mo_assert_procurement_pending <- function() {
  page <- mo_html_text("program_page")
  if (!stringr::str_detect(page, MO_PROCUREMENT_PENDING)) {
    stop("[MO] DSS's RHTP timeline no longer says procurement awardees are ",
         "still to be announced. THIS IS THE ONE DESIGNED TO FAIL: Missouri's ",
         "hospital money is in the ToRCH Care Smart Growth IFB (~$40M) and ",
         "will surface as procurement awards. Re-read dss.mo.gov/bids.",
         call. = FALSE)
  }
  bids <- mo_html_text("bids")
  if (!stringr::str_detect(bids, stringr::fixed(MO_OPEN_SOLICITATION))) {
    stop("[MO] the DSS bid table no longer carries IFB DSS26015-02, the live ",
         "ToRCH Care solicitation that makes the absence of awards a finding.",
         call. = FALSE)
  }
  if (stringr::str_detect(bids, "(?i)award(ed)? (contracts? )?to\\b")) {
    stop("[MO] the DSS bid page now names an awardee.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The pass-through control: the Children's Trust Fund has named nobody
mo_assert_ctf_unnamed <- function() {
  ctf <- mo_html_text("ctf")
  if (!stringr::str_detect(ctf, stringr::fixed("CTF Funding Opportunities"))) {
    stop("[MO] the CTF funding page did not archive as expected.",
         call. = FALSE)
  }
  if (stringr::str_detect(ctf, "(?i)home visiting.{0,400}(awarded to|recipients are|selected)")) {
    stop("[MO] the Children's Trust Fund has named RHTP home-visiting ",
         "awardees. Extract them: $588,000/yr, and this file says nobody is ",
         "named.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- parse -------------------------------------------------------------------

#' The 27 Hub Anchors, parsed from DSS's own PDF
#'
#' Every line is "<hub number> <organisation>". The hub numbers are the parse's
#' own control: they must be 1..27 with no gap, which is what refuses a
#' truncated read of a roster that is otherwise just a list of names.
mo_parse_hub_anchors <- function(lines = NULL) {
  if (is.null(lines)) lines <- mo_pdf_lines("hub_roster")

  m <- stringr::str_match(lines, "^\\s*([0-9]{1,2})\\s+(\\S.*\\S)\\s*$")
  keep <- !is.na(m[, 1])
  out <- tibble::tibble(
    hub_number   = as.integer(m[keep, 2]),
    organization = stringr::str_squish(m[keep, 3])
  ) %>%
    dplyr::arrange(hub_number)

  if (!identical(out$hub_number, seq_len(MO_STATED$hub_anchors_n))) {
    stop("[MO] the Hub Anchor roster did not parse as hubs 1..",
         MO_STATED$hub_anchors_n, "; got ", nrow(out), " rows. A gap or a ",
         "duplicate means the read is short or the PDF has changed.",
         call. = FALSE)
  }
  out
}

#' The Hub Anchor roster in its own schema. THERE IS DELIBERATELY NO `amount`.
rhtp_mo_hub_anchors <- function() {
  anchors <- mo_parse_hub_anchors()

  typed <- rhtp_classify_recipient_type(anchors$organization, "MO")

  anchors %>%
    dplyr::mutate(
      state              = "MO",
      recipient_type     = typed$recipient_type,
      recipient_type_confidence = typed$determination_confidence,
      is_hospital_or_system = recipient_type == "HOSPITAL_OR_SYSTEM",
      selection_date     = MO_STATED$hub_announced,
      award_made         = "No",
      amount_published   = "No",
      agreement_executed = "No",
      role               = paste(
        "Convener of the ToRCH Care Hub. DSS: 'Hub Anchors will not act as the",
        "fiscal agent' (ToRCH Care FAQ Q36); participation is 'subject to",
        "execution of a Hub Anchor Participation Agreement'."),
      note = paste(
        "SELECTION TO A GOVERNANCE ROLE, NOT AN AWARD (§0.3). DSS attaches no",
        "dollar figure to the Hub Anchor role anywhere. Every Hub Anchor is",
        "'allocated a program coordinator' funded by the State (FAQ Q37),",
        "which is a staffing benefit and not a subaward. RCJ carries all 27 of",
        "these as Tier 3 awards at $1 each."),
      source_document_title = "Rural Health Transformation Hub Anchors - Announced July 2026",
      state_source_url      = MO_PROGRAM_PAGE,
      source_archive_path   = file.path(
        "data/evidence/MO", MO_SOURCES$file[MO_SOURCES$key == "hub_roster"])
    ) %>%
    dplyr::select(
      state, hub_number, organization, recipient_type,
      recipient_type_confidence, is_hospital_or_system, selection_date,
      award_made, amount_published, agreement_executed, role, note,
      source_document_title, state_source_url, source_archive_path
    )
}

#' Missouri's TWO award actions, in the §8 union schema
rhtp_mo_year1_awardees <- function() {
  awards <- tibble::tribble(
    ~awardee, ~amount, ~award_pool, ~description, ~source_key, ~award_date,
    "Missouri Doula Association",
    MO_STATED$mda_amount,
    "MATERNAL_WORKFORCE",
    paste("DSS, through its RHTP, announced a partnership between DHSS Office",
          "on Women's Health and the Missouri Doula Association to expand the",
          "rural maternal health workforce. MDA will train, credential and",
          "integrate community-based doulas and perinatal community health",
          "workers into rural health care teams, building partnerships with",
          "rural FQHCs, critical access and community hospitals and",
          "community-based organizations."),
    "pr_doula", "2026-07-20",

    "Missouri Emergency Medical Services Association",
    MO_STATED$memsa_amount,
    "MIH_CP",
    paste("DSS, through the RHTP, announced a partnership connecting the DHSS",
          "Office of Rural Health and Primary Care with MEMSA to expand Mobile",
          "Integrated Healthcare and Community Paramedicine. MEMSA will",
          "administer the initiative by recruiting participating local EMS",
          "organizations, overseeing site expansions and providing technical",
          "assistance, with a goal of 14 operational sites; individual",
          "programs may be approved for up to $250,000 and regional systems up",
          "to $500,000."),
    "pr_memsa", "2026-07-24"
  )

  out <- awards %>% dplyr::mutate(state = "MO")
  out <- rhtp_classify_records(out, state = "MO",
                               description_col = "description")

  out %>%
    dplyr::mutate(
      row_no = dplyr::row_number(),
      # BOTH ARE PASS-THROUGH ADMINISTRATORS AND NEITHER REACHES A HOSPITAL.
      # MDA trains doulas and PCHWs; hospitals appear as PARTNERS the workforce
      # is integrated into, which is §10.2's in-kind test and not receipt.
      # MEMSA re-grants to rural EMS AGENCIES and has named none of them. The
      # classifier reads the RECIPIENT and not the activity (§0.3a) and returns
      # EMS_OR_PSAP + NON_HOSPITAL, which is right: unlike Illinois's ICAHN
      # pool, the eligible class here is stated and it is not hospitals, so
      # there is nothing unresolved about where these dollars go. Whether
      # MEMSA has NAMED its EMS sub-awardees is unknown -- memsa.org is behind
      # a captcha (see the header) -- but that would not move a hospital
      # figure in any case.
      intermediary_name = awardee,
      note = paste0("Missouri RHTP ", award_pool, " partnership. ",
                    determination_basis),
      recipient_confirmed = "Yes",
      # MDA's figure is exact and stated as awarded. MEMSA's is "around $6.5M
      # THROUGH JULY 31, 2027" -- rounded AND spanning past Budget Period 1,
      # which ends 2026-10-30. Indiana's precedent: the figure is kept, because
      # it is one of only two Missouri has published, and both caveats are
      # flagged so a reader who sums the column can see what they summed.
      amount_confirmed = dplyr::if_else(
        awardee == "Missouri Doula Association", "Yes", "No"),
      amount_basis = dplyr::if_else(
        awardee == "Missouri Doula Association", NA_character_,
        "approximate; runs through 2027-07-31, past Budget Period 1"),
      flag_reason = dplyr::if_else(
        awardee == "Missouri Doula Association", NA_character_,
        "AMOUNT_ROUNDED_IN_SOURCE;AMOUNT_IS_MULTI_YEAR_TOTAL"),
      fiscal_year = "FY2026",
      state_source_url = MO_PROGRAM_PAGE,
      validation_source_type = "AGENCY_PRESS_RELEASE",
      extraction_method = "DIRECT_TEXT",
      validator = "AUTO",
      ccn = NA_character_,
      aha_id = NA_character_,
      rural_designation = NA_character_,
      reviewer = NA_character_,
      source_document_title = dplyr::if_else(
        awardee == "Missouri Doula Association",
        "Rural Health Transformation Program Announces Partnership to Expand Rural Maternal Healthcare",
        "Bringing Healthcare Home: State Initiative Aims to Significantly Expand Mobile Medical Services in Rural Missouri"),
      source_archive_path = file.path(
        "data/evidence/MO",
        purrr::map_chr(source_key,
                       ~ MO_SOURCES$file[MO_SOURCES$key == .x])),
      hospital_attribution = rhtp_hospital_attribution(
        flow_type, distributed_to_hospital, recipient_type)
    ) %>%
    dplyr::select(
      state, row_no, awardee, amount, recipient_type,
      distributed_to_hospital, note, recipient_confirmed, amount_confirmed,
      fiscal_year, source_document_title, state_source_url,
      validation_source_type, extraction_method, validator, ccn, aha_id,
      rural_designation, reviewer,
      award_pool, award_date, flow_type, hospital_benefiting,
      hospital_attribution, intermediary_name, determination_confidence,
      determination_basis, classification_rule, flag_reason, amount_basis,
      source_archive_path
    )
}


# -- RCJ disposition ---------------------------------------------------------

mo_rcj_candidates <- function() {
  rt <- readRDS(here::here("data", "interim", "stage2_record_table.rds"))
  rt %>%
    dplyr::filter(state == "MO", is.na(superseded_by),
                  award_tier == "SUBAWARD")
}

#' Why each of RCJ's 29 Missouri Tier 3 candidates is, or is not, an award
#'
#' The counts are RE-DERIVED from the record table on every run, so the day
#' Missouri's candidate set moves this fails instead of quietly ceasing to
#' cover it (Texas's rule).
rhtp_mo_rcj_disposition <- function(cands = NULL) {
  if (is.null(cands)) cands <- mo_rcj_candidates()
  anchors <- rhtp_mo_hub_anchors()

  is_anchor <- cands$awardee_name_clean %in% anchors$organization
  is_memsa  <- stringr::str_detect(cands$awardee_name_clean,
                                   "Missouri Emergency Medical Services")
  is_mda    <- stringr::str_detect(cands$awardee_name_clean,
                                   "Missouri Doula Association")

  tibble::tribble(
    ~group, ~rows, ~disposition, ~why,
    "Hub Anchor selections carried as awards at $1",
    sum(is_anchor),
    "NOT_AN_AWARD_GOVERNANCE_ROLE",
    paste("RCJ files all 27 ToRCH Care Hub Anchors as Tier 3 award records,",
          "each with an amount of $1. They are organisations SELECTED TO",
          "CONVENE a hub. DSS's own FAQ: 'Hub Anchors will not act as the",
          "fiscal agent' (Q36); its release: participation is 'subject to",
          "execution of a Hub Anchor Participation Agreement'. No dollar",
          "figure is attached to the role anywhere. 14 of the 27 are hospitals",
          "or health systems on the name rule and 11 more carry §8's standing",
          "fallback, so believed at face value this publishes at least 14",
          "named hospitals as RHTP recipients with no money behind any."),

    "Missouri EMS Association -- a real partnership, amount approximate",
    sum(is_memsa),
    "RHTP_AWARD_PASS_THROUGH",
    paste("RCJ's $6,500,000 matches DSS's 'around $6.5M'. It is in this",
          "file, as a PASS_THROUGH_UNRESOLVED to rural EMS agencies MEMSA has",
          "not named -- not a hospital dollar."),

    "Missouri Doula Association -- a real award, RCJ's amount short",
    sum(is_mda),
    "RHTP_AWARD_AMOUNT_UNDERSTATED",
    paste0("RCJ carries $", format(MO_STATED$rcj_mda_amount, big.mark = ","),
           " against DSS's own $",
           format(MO_STATED$mda_amount, big.mark = ",", nsmall = 2),
           " -- short by $",
           format(MO_STATED$mda_amount - MO_STATED$rcj_mda_amount,
                  nsmall = 2),
           ". The award is real and is in this file at the state's figure.")
  ) %>%
    dplyr::mutate(state = "MO", .before = 1)
}


# -- reconciliation ----------------------------------------------------------

rhtp_mo_reconcile <- function(awards = NULL, anchors = NULL) {
  if (is.null(awards))  awards  <- rhtp_mo_year1_awardees()
  if (is.null(anchors)) anchors <- rhtp_mo_hub_anchors()

  allotments <- rhtp_load_allotments()
  mo_allot <- allotments$fy2026_allotment[allotments$state == "MO"]

  list(
    awards_n        = nrow(awards),
    awards_total    = sum(awards$amount),
    anchors_n       = nrow(anchors),
    anchor_hospitals = sum(anchors$is_hospital_or_system),
    anchor_dollars  = 0,
    cms_award_stated = MO_STATED$cms_award_stated,
    cms_allotment   = mo_allot,
    publisher_gap   = mo_allot - MO_STATED$cms_award_stated,
    share_of_allotment = sum(awards$amount) / mo_allot
  )
}


# -- assertions --------------------------------------------------------------

rhtp_mo_assert <- function(awards = NULL, anchors = NULL) {
  if (is.null(awards))  awards  <- rhtp_mo_year1_awardees()
  if (is.null(anchors)) anchors <- rhtp_mo_hub_anchors()

  # 1. The Texas check, programme-scoped, with the footer downgraded.
  stated <- mo_assert_rhtp_provenance()
  stopifnot(identical(stated, MO_STATED$cms_award_stated))
  mo_assert_after_noa()

  # 2. THE ONE THAT DECIDES THE FILE.
  mo_assert_anchors_not_awarded()

  # 3. The controls.
  mo_assert_roster_index()
  mo_assert_procurement_pending()
  mo_assert_ctf_unnamed()

  # 4. Counts and totals.
  rec <- rhtp_mo_reconcile(awards, anchors)
  stopifnot(rec$anchors_n == MO_STATED$hub_anchors_n)
  stopifnot(rec$awards_n  == MO_STATED$awards_n)
  stopifnot(abs(rec$awards_total - MO_STATED$awards_total) < 0.005)
  stopifnot(abs(rec$publisher_gap - 0.34) < 0.005)

  hub <- mo_html_text("pr_hub")
  stopifnot(stringr::str_detect(
    hub, stringr::fixed("received 41 Hub Anchor applications")))

  # 5. NO ANCHOR ROW MAY CARRY MONEY -- Texas's device, in the schema itself.
  if ("amount" %in% names(anchors) || "round_amount" %in% names(anchors)) {
    stop("[MO] mo_hub_anchors.csv has grown an amount column. It must not: ",
         "the 27 are a selection, and a column named `amount` invites a sum ",
         "over a quantity Missouri has never published.", call. = FALSE)
  }
  stopifnot(all(anchors$award_made == "No"))
  stopifnot(all(anchors$agreement_executed == "No"))

  # 6. MISSOURI'S NAMED-HOSPITAL DOLLARS ARE $0, AND SO IS EVERY OTHER BUCKET.
  #    Both awards are pass-throughs whose subrecipient class is not hospitals.
  part <- rhtp_hospital_dollar_partition(awards)
  stopifnot(nrow(part) == 0L || sum(part$dollars) == 0)
  stopifnot(all(awards$distributed_to_hospital != "Yes") ||
              all(part$bucket != "NAMED_HOSPITAL"))

  # 7. THE ROSTER'S HOSPITALS ARE COUNTED, SO THE $0 CANNOT BE READ AS
  #    "NO HOSPITALS". Nevada's lesson: the row count is the load-bearing
  #    quantity when the dollar column is empty. 14 of the 27 anchors are
  #    hospitals or health systems on the name rule, and 11 more carry §8's
  #    standing fallback -- uncounted, not absent.
  stopifnot(rec$anchor_hospitals == MO_STATED$anchor_hospitals_named)
  stopifnot(sum(anchors$recipient_type == "NONPROFIT_CBO") ==
              MO_STATED$anchor_form_not_stated)

  # 8. Vocabulary.
  vocab <- rhtp_vocabulary()
  for (col in c("recipient_type", "flow_type", "distributed_to_hospital",
                "recipient_confirmed", "amount_confirmed",
                "determination_confidence", "validation_source_type",
                "hospital_attribution")) {
    vals <- unique(stats::na.omit(awards[[col]]))
    key  <- if (col == "validation_source_type") "source_doc_type" else col
    allowed <- vocab$allowed_value[vocab$column_name == key]
    bad <- setdiff(vals, allowed)
    if (length(bad)) {
      stop("[MO] ", col, " outside the vocabulary: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  flags <- unlist(strsplit(stats::na.omit(awards$flag_reason), ";"))
  bad <- setdiff(flags, vocab$allowed_value[vocab$column_name == "flag_reason"])
  if (length(bad)) {
    stop("[MO] flag_reason outside the vocabulary: ",
         paste(bad, collapse = ", "), call. = FALSE)
  }

  # 9. The RCJ disposition covers every candidate, re-derived.
  cands <- mo_rcj_candidates()
  dispo <- rhtp_mo_rcj_disposition(cands)
  stopifnot(sum(dispo$rows) == nrow(cands))

  message("[MO] all assertions pass.")
  invisible(TRUE)
}


# -- build -------------------------------------------------------------------

rhtp_mo_build <- function() {
  awards  <- rhtp_mo_year1_awardees()
  anchors <- rhtp_mo_hub_anchors()
  dispo   <- rhtp_mo_rcj_disposition()
  rhtp_mo_assert(awards, anchors)

  readr::write_csv(awards,  here::here(MO_CSV), na = "")
  readr::write_csv(anchors, here::here(MO_HUB_CSV), na = "")
  readr::write_csv(dispo,   here::here(MO_DISPO_CSV), na = "")

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "READ FIRST")
  openxlsx::writeData(wb, "READ FIRST", tibble::tibble(
    Warning = c(
      "MISSOURI HAS PUBLISHED A 27-ORGANISATION ROSTER AND TWO AWARDS. THEY ARE NOT THE SAME THING.",
      "The 27 ToRCH Care Hub Anchors (sheet 'Hub anchors') are organisations SELECTED TO CONVENE a hub.",
      "DSS attaches NO dollar figure to the role anywhere, its FAQ Q36 says 'Hub Anchors will not act as",
      "the fiscal agent', and participation is 'subject to execution of a Hub Anchor Participation",
      "Agreement'. Fourteen of them are hospitals or health systems by name, and eleven more carry",
      "spec 8's standing fallback. NONE of them is an award (spec 0.3),",
      "and that sheet deliberately has no amount column.",
      "",
      "Missouri's award actions are the TWO on sheet 'Awards': the Missouri Doula Association",
      "($732,660.43, exact) and the Missouri EMS Association (around $6.5M, running through 2027-07-31).",
      "Both are pass-through administrators; neither reaches a hospital. MISSOURI'S NAMED-HOSPITAL",
      "DOLLARS ARE $0, and that is a statement about what DSS has published, not about Missouri.",
      "",
      "The hospital money is coming through PROCUREMENT: the ToRCH Care Smart Growth IFB anticipates",
      "nearly $40M with individual awards up to $5M, open to hospitals, and DSS's own timeline says",
      "'Aug - Sept 2026 Announce select procurement awardees'. None had been announced when this was built.")
  ), colNames = FALSE)
  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", awards)
  openxlsx::addWorksheet(wb, "Hub anchors")
  openxlsx::writeData(wb, "Hub anchors", anchors)
  openxlsx::addWorksheet(wb, "RCJ disposition")
  openxlsx::writeData(wb, "RCJ disposition", dispo)
  openxlsx::saveWorkbook(wb, here::here(MO_XLSX), overwrite = TRUE)

  message("[MO] wrote ", MO_CSV, " (", nrow(awards), " rows), ",
          MO_HUB_CSV, " (", nrow(anchors), " rows), ", MO_DISPO_CSV)
  invisible(list(awards = awards, anchors = anchors, dispo = dispo))
}


# -- report ------------------------------------------------------------------

rhtp_mo_report <- function() {
  awards  <- rhtp_mo_year1_awardees()
  anchors <- rhtp_mo_hub_anchors()
  rec     <- rhtp_mo_reconcile(awards, anchors)

  message("=== Missouri Year 1 ===")
  message("Allotment: $", format(rec$cms_allotment, big.mark = ","),
          "   DSS's own footer: $",
          format(rec$cms_award_stated, big.mark = ",", nsmall = 2),
          "   (gap $", format(rec$publisher_gap, nsmall = 2), ")")
  message("")
  message("AWARD ACTIONS: ", rec$awards_n, ", $",
          format(rec$awards_total, big.mark = ",", nsmall = 2),
          "  (", round(100 * rec$share_of_allotment, 2),
          "% of the allotment)")
  print(as.data.frame(awards[, c("awardee", "amount", "recipient_type",
                                 "flow_type", "distributed_to_hospital")]),
        row.names = FALSE)
  message("")
  message("HUB ANCHORS: ", rec$anchors_n, " named organisations, ",
          rec$anchor_hospitals, " of them hospitals or health systems, ",
          "and $", rec$anchor_dollars, ".")
  message("  They are SELECTED TO CONVENE a hub, not funded. DSS FAQ Q36:")
  message("  'Hub Anchors will not act as the fiscal agent.'")
  message("  RCJ carries all ", rec$anchors_n, " as Tier 3 awards at $1 each.")
  message("")
  message("Named-hospital dollars:")
  print(rhtp_hospital_dollar_partition(awards))
  message("")
  message("Still to come, and where the hospital money is:")
  message("  ToRCH Care Smart Growth IFB DSS26015 -- nearly $40M anticipated,")
  message("  awards up to $5M, open to hospitals. DSS's timeline: 'Aug - Sept")
  message("  2026 Announce select procurement awardees'. Not yet announced.")
  invisible(rec)
}


# -- CLI ---------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  if ("--fetch" %in% args)    mo_fetch(force = force)
  if ("--validate" %in% args) rhtp_mo_assert()
  if ("--build" %in% args)    rhtp_mo_build()
  if ("--report" %in% args)   rhtp_mo_report()
  if (!length(intersect(args, c("--fetch", "--validate", "--build",
                                "--report")))) {
    message("usage: Rscript R/03w_mo_year1_awardees.R ",
            "[--fetch [--force]] [--validate] [--build] [--report]")
  }
}

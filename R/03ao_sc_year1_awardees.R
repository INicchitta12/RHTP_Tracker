#!/usr/bin/env Rscript
# 03ao_sc_year1_awardees.R -----------------------------------------------------
#
# SOUTH CAROLINA -- 228 PRICED AWARDS, $167,299,900.69, AND THE FIRST STATE TO
# LEAVE `INVESTIGATED_NO_PROBE`.
#
# Session 39 worked South Carolina and found a shape this project had not met:
# SCDHHS hit its own published "Anticipated Notice of Award -- July 31, 2026"
# EXACTLY, announced it in Medicaid bulletin MB# 26-026, and told the
# recipients BY EMAIL -- "Applicants should check their email" -- publishing a
# count of 712 APPLICATIONS and nothing else. No roster, no amounts, not even a
# count of awards. Session 43 declined to call that `INVESTIGATED_NO_LIST`,
# because that code promises a re-checkable negative -- an evidence archive AND
# a probe -- and South Carolina had neither; it also declined to call it a
# negative at all, because the state HAD awarded. `INVESTIGATED_NO_PROBE` was
# added for exactly that condition, and its own note says the finding goes
# stale by construction and that the intended next action is to WRITE THE
# PROBE.
#
# SOUTH CAROLINA PUBLISHED THE ROSTER BEFORE ANYONE WROTE THAT PROBE. On
# 2026-09-15 SCDHHS posted "SC RHTP Year 1 Award List" to its grants page, an
# eight-page PDF carrying 228 named, priced awards. So the state moves
# `INVESTIGATED_NO_PROBE` -> `EXTRACTED` without ever passing through
# `INVESTIGATED_NO_LIST`, and the weaker code did the one job it was given:
# it said what this repository had and had not done, and it did not claim a
# tripwire that did not exist.
#
# ============================================================================
# WHAT THE DOCUMENT IS, AND THE THREE COUNTS THAT ARE NOT EACH OTHER
# ============================================================================
#
#   228 AWARD ACTIONS  -- the rows the list prices, and this file's row count.
#   130 AWARDEE STRINGS -- distinct spellings in the Organization Name column.
#     8 PROJECTS        -- the grain the list numbers, restarting at 1 each.
#     4 INITIATIVES     -- the grain SCDHHS names on its programme page.
#
# ORGANISATIONS REPEAT, HEAVILY, AND ACROSS PROJECTS. Newberry County Memorial
# Hospital holds TWELVE awards across FOUR projects; Self Regional Healthcare
# (Lakelands Region) holds ELEVEN across FIVE; Hampton Regional Medical Center
# TEN across FOUR. So a row is an AWARD ACTION and never an organisation --
# Michigan's lesson (session 27), where RCJ carried one row per organisation
# against MDHHS's one per award and understated the state by $7,833,333.
#
# AND 130 IS AN UPPER BOUND ON ORGANISATIONS, NOT A COUNT OF THEM. The list
# spells one body several ways: "Allendale County Hospital" and "Allendale
# County Hospital (ACH)"; "Carolina Health Centers, Inc." and "... (CHC)";
# "Low Country Health Care System" and "... (LCHCS)"; "Tandem Health SC" and
# "... (THSC)". §2 forbids a machine merging those, so they are recorded as
# published and the count is reported as a count of STRINGS.
#
# ============================================================================
# THE TWO MISSISSIPPI DEFECTS, LOOKED FOR DELIBERATELY -- AND BOTH HAVE A
# SOUTH CAROLINA ANALOGUE, ONE OF WHICH NO TOTAL CAN SEE
# ============================================================================
#
# Session 46 found two odd-shape rows in Mississippi's release: a MISSING SPACE
# that dropped a $2,500,000 row (the total caught it), and an ORGANISATION
# WHOSE LEGAL NAME CONTAINS " - ", which misassigned a name and a county while
# every total still reconciled to the cent. Both were looked for here.
#
# (1) THE MISSING-CHARACTER DEFECT IS PRESENT AND IT IS IN THE ROW NUMBER.
#     Healthcare Workforce row 2 is printed "I2", not "2" -- a capital letter I
#     where a digit belongs, and the run is painted at x=79.56 where every
#     other one-digit number sits at 82.68 and every two-digit one at 76.26.
#     A parser keying rows on `^[0-9]+$` in the number column DROPS Rebound
#     Behavioral Health and its $120,000: 227 rows, and the total is short.
#     THE TOTAL WOULD CATCH IT -- which is precisely why this file does NOT
#     key on the number column at all. Rows are anchored on the AMOUNT column,
#     and the numbers are used only as a COMPLETENESS CHECK: each project must
#     number 1..n with no gap, which is a far stronger statement than a total
#     (a total catches a dropped row only if you already know the total).
#     `sc_assert_row_numbering()` therefore has to accommodate "I2" explicitly,
#     and it is recorded rather than corrected (§8).
#
# (2) THE HYPHEN DEFECT IS PRESENT, IS THE INVERSE OF MISSISSIPPI'S, AND
#     COSTS A NAME RATHER THAN A DOLLAR.
#
#     Mississippi's hazard was a " - " INSIDE a legal name breaking a
#     delimiter split. South Carolina's is a hyphen with NO SPACES AROUND IT,
#     painted as THREE SEPARATE RUNS:
#
#         x= 99.90  "Prisma Health"
#         x=173.40  "-"
#         x=177.48  "Upstate (Oconee, Lee, and Laurens)"
#
#     There is no delimiter split here to break, so no dollar moves. What
#     breaks is the NAME, in both directions, depending on how the runs are
#     joined. Pasting them with a separator invents "Prisma Health - Upstate";
#     pasting a DIFFERENT row's runs without one loses a space, because on
#     page 7 "Self Regional" and "Healthcare (Lakelands Region)" are also two
#     runs and there the space is real.
#
#     SO NEITHER CONSTANT SEPARATOR IS CORRECT, AND THE ANSWER WAS MEASURED
#     RATHER THAN CHOSEN. The document's own /Widths array gives Aptos a space
#     of 203/1000 em and a hyphen of 340/1000; the observed hyphen advance is
#     4.08pt, so the size is 12pt and a space is 2.436pt. Against that:
#
#       "Prisma Health" width 73.464, gap to the hyphen 73.500  -> +0.036  NO SPACE
#       "Self Regional" width 67.284, gap to the next run 69.720 -> +2.436  ONE SPACE
#       "(Anderson"     width 53.328, gap 53.280                 -> -0.048  NO SPACE
#
#     Every boundary lands within 0.05pt of either zero or exactly one space,
#     and NOTHING lands in between. So South Carolina's own spelling is
#     "Prisma Health-Upstate (Oconee, Lee, and Laurens)", unspaced.
#
#     AND THE READER WAS ALREADY RIGHT, WHICH IS THE PART WORTH KEEPING.
#     `rhtp_pdf_run_table()` returns the producer's space runs as runs of their
#     own -- there IS a run of a single space between "Self Regional" and
#     "Healthcare", and there is NOT one between "Prisma Health" and "-" -- so
#     pasting a line's runs with `collapse = ""` reproduces the rendered text
#     exactly. Session 32 warned that a run boundary can be pen POSITIONING
#     rather than a space glyph and that the fix would be glyph widths; on this
#     producer it is a glyph, and the widths are used here to PROVE that rather
#     than to repair anything. `sc_assert_no_positioning_space()` re-derives
#     the whole measurement from the archived PDF on every run, so the day a
#     re-post changes producer the proof fails instead of quietly going stale.
#
#     WHAT THE MEASUREMENT FOUND THAT NOTHING ELSE WOULD HAVE: SOUTH CAROLINA
#     SPELLS ONE ORGANISATION TWO WAYS, ONE SPACE APART. Seventeen rows read
#     "Prisma Health-Upstate ..." and ONE reads "Prisma Health- Upstate
#     (Anderson)" -- the state painted a space after the hyphen on that row and
#     on no other. The same thing happens again with a hyphen and a space
#     swapped: "(Aiken Barnwell Mental Health Center)" on one row and
#     "(Aiken-Barnwell Mental Health Center)" on another. Both pairs are
#     recorded, NEITHER is merged (§2), and `sc_assert_two_spellings()` pins
#     them so a future re-post that tidies them shows up as a failure.
#
# (3) A THIRD SHAPE, WHICH IS NOT A DEFECT AND IS THE ONE THAT WOULD HAVE
#     BROKEN A LINE-MODEL READ. Twenty-three rows WRAP their name over two
#     visual lines, and the producer paints the number and the amount at the
#     MIDPOINT of the two, with the line ids interleaved -- on page 8 the
#     name's first line is line 22, the number is line 21, the name's second
#     line is 23 and the amount is 24. `rhtp_pdf_lines()` therefore cannot
#     assemble these rows at all, and a reader that grouped by line id would
#     emit a row with no name and a name with no row. Rows are assembled by
#     Y-BAND instead, and `sc_assert_line_model_cannot_read_this()` drives the
#     failure so the reason is visible rather than remembered.
#
# ============================================================================
# §6.2 PROVENANCE -- AND THERE IS NO CMS FOOTER ANYWHERE, ON EITHER DOCUMENT
# ============================================================================
#
# MEASURED, not assumed: the award list contains "Centers for Medicare" ZERO
# times, "financial assistance" ZERO, "funded by CMS" ZERO and even "CMS"
# ZERO. Arkansas's shape (session 40), where the award list carried no footer
# either -- so the footer could not have carried this state's provenance even
# in its strong form.
#
# AND THE FOOTER HAS GONE FROM THE PROGRAMME PAGE TOO, WHICH IS NEW. Session
# 39 read `scdhhs.gov/RHTP` and recorded the STRONG, programme-scoped form
# there -- "The RHTP is supported by ... a financial assistance award totaling
# $200,030,252.32". That path now 301s to `/resources/grants`, and the live
# page carries "financial assistance" ZERO times, "200,030" ZERO and
# "100 percent" ZERO. This is recorded as an observation about the SOURCE and
# not as a finding about the programme (§0.4): a publisher dropping a footer
# says nothing about where the money came from.
#
# WHAT CARRIES THE PROVENANCE INSTEAD, all of it programme-scoped:
#
#   - THE DOCUMENT'S OWN RUNNING HEADER, on all eight pages: "South Carolina
#     Rural Health Transformation Program | Year 1 Awards".
#   - THE PROGRAMME PAGE NAMES THE DOCUMENT BY NAME, under its RHTP heading:
#     "Award List -- SC RHTP Year 1 Award List (Posted: Sept. 15, 2026)",
#     beside "South Carolina's RHTP is administered by the South Carolina
#     Department of Health and Human Services" and "This federal initiative is
#     led by the Centers for Medicare & Medicaid Services (CMS)".
#   - THE INITIATIVE SET CLOSES, WHICH IS THE STRUCTURAL TIE AND IS UNUSUALLY
#     GOOD. The award list's four Initiative headings are EXACTLY the four the
#     programme page names as South Carolina's RHTP initiatives open for
#     application -- Connections to Care, Leveling Up, Wellness Within Reach,
#     Shoring Up to Sustainability -- and the FIFTH that page names, the Tech
#     Catalyst Fund, is absent from the list, which is what the page says to
#     expect. A document whose section headings are the state's own RHTP
#     initiative set, complete and with the one exception the state itself
#     flags, is tied to the programme by its structure and not by a sentence.
#   - A SECOND PUBLISHER STATES THE COUNT. CMS's 2026-09-17 release says the
#     RHTP funding "will support 228 grants" for South Carolina and heads
#     itself "$167 Million". That is 228 against 228 parsed, and $167 million
#     against $167,299,900.69 summed, from a publisher who did not write the
#     list. Nothing was arranged.
#   - THE DATE TEST PASSES WITH ROOM. Posting 2026-04-02, applications due
#     2026-06-01, Anticipated Notice of Award 2026-07-31, list posted
#     2026-09-15 -- every one after the 2025-12-29 Notice of Award.
#
# ============================================================================
# THE CONTROLS, AND BOTH NEGATIVES ARE ON THE PROGRAMME PAGE ITSELF
# ============================================================================
#
# THE POSITIVE CONTROL IS THE AWARD-LIST LINK. SCDHHS publishes a roster in a
# recognisable form when it has one -- an "Award List" heading with one named
# document under it -- so "the Tech Catalyst Fund has no roster" is a statement
# about South Carolina and not about our reading. `sc_assert_award_index()`
# fails in BOTH directions: if that link disappears, and if a SECOND appears.
#
# THE TWO NEGATIVE CONTROLS SIT ON THE SAME PAGE AS THE POSITIVE ONE, AND THE
# SECOND IS THE SHARPEST §0.1 TRAP THIS STATE HAS.
#
#   - "SCDHHS Awards $48.2 Million in Healthcare Infrastructure Funds to
#      Improve Access to Quality Medical Services in RURAL and Medically
#      Underserved Areas" -- a real, named, linked roster, on the RHTP page,
#      with "rural" in its title. Awarded 2024-02-02.
#   - "SCDHHS Awards Behavioral Health Crisis Stabilization Grants to 13 SOUTH
#      CAROLINA HOSPITALS" -- ~$35,000,000, a real named roster OF HOSPITALS,
#      on the same page. Awarded 2023-06-23.
#
# A hunt scanning SCDHHS for "awards" + "rural" + a large figure takes the
# first every time, and a hunt scanning for hospital money takes the second.
# California's SRHRP trap (session 34) in duplicate -- and §6.2's date test
# disposes of both on its own, 18 and 30 months before the Notice of Award, so
# the disqualification is by machine and not by reading. `sc_assert_controls()`
# asserts both are still what they are; losing either costs this file the only
# evidence that its negative is South Carolina's rather than ours.
#
# ============================================================================
# THE YEAR IS PARTIAL, AND SOUTH CAROLINA SAYS SO ITSELF
# ============================================================================
#
# $167,299,900.69 against a $200,030,252 allotment (§7.1) is 83.6%. The
# remaining $32,730,351 is not unaccounted for: the programme page says
# "Funding opportunities for the fifth of South Carolina's RHTP initiatives,
# the Tech Catalyst Fund, will be announced through a future stage of SCDHHS'
# RHTP implementation", and that it is administered through the South Carolina
# Research Authority -- §7's designated pass-through route (Illinois/ICAHN's
# precedent), which has named nobody. So this file is four initiatives of five
# BY CONSTRUCTION, and `sc_assert_tech_catalyst_pending()` is designed to fail
# the day the fifth publishes.
#
# ============================================================================
# THE HOSPITAL FIGURE IS A FLOOR, THE UNCERTAINTY IS LARGER THAN IT, AND
# NOTHING WAS PROMOTED
# ============================================================================
#
# The award list has THREE COLUMNS -- number, Organization Name, Total Funding
# Amount. No organisation type, no county, no project description, nothing
# about the recipient's form. So every `recipient_type` is derived from the
# recipient's own NAME, and the unstated-form question arrives for a
# THIRTEENTH time and is the second largest in dollars this project has met.
#
# IT IS ONE-DIRECTIONAL: every row on §8's standing fallback is already
# `distributed_to_hospital = No`, so resolving one can only RAISE South
# Carolina's hospital figure. The named-hospital total is a genuine FLOOR and
# floor + fallback a genuine CEILING.
#
# AND THE FALLBACK RUNS STRONGLY UPWARD, WHICH IS WHY NOTHING WAS PROMOTED
# (§0.4). Self Regional Healthcare's eleven rows ($17,663,869), McLeod Health's
# ($7,863,454 across its two spellings), AnMed's seven ($4,147,850), every
# Prisma Health row, Tidelands Health and Spartanburg Regional's behavioural
# arm all read as hospital systems to anyone who knows South Carolina, and NOT
# ONE is typed by the document. Promoting them on this pipeline's own knowledge
# is the §0.4 failure this project exists to avoid; they are queued as
# `SC_RECIPIENT_FORM_NOT_STATED` and the CCN match (blocker 5) resolves them.
#
# THE SAME REFUSAL RUNS DOWNWARD TOO, AND THAT IS THE HALF USUALLY LEFT OUT.
# "SCDBHDD Office of Mental Health ..." is the South Carolina Department of
# Behavioral Health and Developmental Disabilities -- a STATE AGENCY on this
# pipeline's own knowledge, and §8's name rule does not reach the acronym, so
# its nineteen rows take the fallback too. They are `No` either way, so $0
# moves, and they are NOT re-typed on recognition for the same reason the
# hospital systems are not.
#
# ONE PAIR OF SPELLINGS CLASSIFIES DIFFERENTLY AND IT MOVES A DOLLAR, WHICH IS
# NORTH CAROLINA'S UNC FINDING (session 38) IN A STATE THAT PRICES ITS ROWS.
# "Medical University Hospital Authority" (4 rows, $3,454,290) is
# `HOSPITAL_OR_SYSTEM` -> `DIRECT` -> `Yes`, while "Medical University of
# South Carolina" (3 rows, $3,345,533) is `UNIVERSITY_OR_AHC` -> `NON_HOSPITAL`
# -> `No`. Two spellings, one publisher, one document, opposite codings,
# $3,345,533 apart. Here BOTH machine answers are kept, because unlike North
# Carolina's UNC these are arguably two different legal bodies -- the hospital
# authority and the university -- and no source in hand says otherwise.
# `sc_assert_musc_two_spellings()` ASSERTS THE DIVERGENCE RATHER THAN
# REPAIRING IT.
#
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(readr)
  library(digest)
  library(httr)
  library(here)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))
source(here::here("R", "utils_recipient_classification.R"))

SC_STATE          <- "SC"
SC_EVIDENCE_DIR   <- rhtp_path("evidence", "SC")
SC_AWARDEES_CSV   <- rhtp_path("reference", "sc_year1_awardees.csv")
SC_STATUS_CSV     <- rhtp_path("reference", "sc_year1_status.csv")
SC_DISPO_CSV      <- rhtp_path("reference", "sc_rcj_candidate_disposition.csv")
SC_USER_AGENT     <- rhtp_config()$api$user_agent

# The list's posting date, in SCDHHS's own words on the programme page.
SC_LIST_POSTED    <- "2026-09-15"
# CMS's release, the second publisher.
SC_CMS_DATE       <- "2026-09-17"
# CMS's own count of South Carolina's grants, quoted from that release.
SC_CMS_GRANTS     <- 228L
# South Carolina's CMS Notice of Award (§6.2 anchor), and the milestones the
# programme page prints for itself.
SC_NOA_DATE       <- as.Date("2025-12-29")
SC_APPLICATION_DUE      <- as.Date("2026-06-01")
SC_ANTICIPATED_NOA_DATE <- as.Date("2026-07-31")

# The 228 rows sum to this, to the cent. It is NOT stated by the document --
# the list carries no Total row and no subtotals at all -- so it is a
# reconciliation target derived from the rows and corroborated from OUTSIDE:
# CMS heads its release "$167 Million" and states 228 grants.
SC_AWARD_TOTAL    <- 167299900.69
SC_AWARD_ROWS     <- 228L
SC_AWARDEE_STRINGS <- 130L

# The §7.1 anchor figure, READ from cms_fy2026_allotments.csv rather than
# transcribed -- that file is parsed from CMS's own table and is the
# reconciliation anchor for every §13 assertion, so a figure typed beside it
# is a second source of truth waiting to drift.
SC_ALLOTMENT_EXPECTED <- 200030252

sc_allotment <- function() {
  a <- readr::read_csv(rhtp_path("reference", "cms_fy2026_allotments.csv"),
                       show_col_types = FALSE, progress = FALSE)
  v <- a$fy2026_allotment[a$state == SC_STATE]
  if (length(v) != 1L) {
    stop("[SC] the §7.1 allotment anchor has ", length(v), " rows for SC.",
         call. = FALSE)
  }
  if (v != SC_ALLOTMENT_EXPECTED) {
    stop("[SC] the §7.1 anchor now gives South Carolina $",
         format(v, big.mark = ","), " against the $",
         format(SC_ALLOTMENT_EXPECTED, big.mark = ","),
         " this file's partial-year arithmetic was written against. Re-read ",
         "the report before publishing either figure.", call. = FALSE)
  }
  v
}

SC_SOURCES <- tibble::tribble(
  ~key, ~url, ~file, ~note,

  "award_list",
  "https://www.scdhhs.gov/sites/dhhs/files/SC%20RHTP%20Year%201%20Award%20List%20to%20CMS.pdf",
  "2026-09-21_sc_rhtp_year1_award_list_THE_ROSTER.pdf",
  paste("THE ROSTER. Eight pages, 228 priced rows, 4 Initiative headings and",
        "8 Project headings. Three columns and NO organisation type, no",
        "county and no description -- which is why every recipient_type here",
        "is derived from the NAME and why the unstated-form queue row is the",
        "second largest in this repository. It carries NO CMS FOOTER AT ALL",
        "(Arkansas's shape) and no Total row of any kind."),

  "programme",
  "https://www.scdhhs.gov/resources/grants",
  "2026-09-21_scdhhs_grants_rhtp_programme.html",
  paste("THE PROVENANCE AND BOTH NEGATIVE CONTROLS, ON ONE PAGE. Names the",
        "award list by name and by posting date; names the four initiatives",
        "the list is sectioned by and the FIFTH (Tech Catalyst Fund) that is",
        "deliberately absent; prints the Grant Applicant Deadlines table whose",
        "Anticipated Notice of Award is 2026-07-31. Also carries the $48.2M",
        "Rural & Medically Underserved Area roster (2024-02-02) and the ~$35M",
        "Behavioral Health Crisis Stabilization roster TO 13 HOSPITALS",
        "(2023-06-23), both real, both named, NEITHER RHTP. NOTE: session 39",
        "recorded a CMS financial-assistance footer on scdhhs.gov/RHTP; that",
        "path now 301s here and the footer is GONE. Recorded, not read as a",
        "finding about the programme (§0.4)."),

  "cms_release",
  "https://www.cms.gov/newsroom/press-releases/trump-administration-announces-167-million-build-rural-care-sites-upgrade-health-technology",
  "2026-09-21_cms_2026-09-17_sc_228_grants.html",
  paste("THE SECOND PUBLISHER, and it states the COUNT: 'The RHTP funding",
        "will support 228 grants'. 228 against 228 parsed, and a $167 million",
        "headline against $167,299,900.69 summed. REDUCED to <main> + the",
        "schema.org JSON-LD: CMS's page chrome carries a third-party Mapbox",
        "token which is CMS's to publish and not ours to redistribute (§7.1,",
        "session 11). Full page as served:",
        "acec2a68b3e6ef80e0519ba78091638f518059d8a8c2ab53b9947e63a6a62f07."),

  "rmua_control",
  "https://www.scdhhs.gov/communications/scdhhs-awards-482-million-healthcare-infrastructure-funds-improve-access-quality",
  "2026-09-21_scdhhs_rural_mua_grant_NEGATIVE_CONTROL.html",
  paste("§0.1 NEGATIVE CONTROL. A real, named, priced SCDHHS roster with",
        "'RURAL' IN ITS TITLE, awarded 2024-02-02 -- twenty-three months",
        "before South Carolina's Notice of Award, so §6.2's date test",
        "disqualifies it without anyone reading it."),

  "bhcs_control",
  "https://www.scdhhs.gov/communications/scdhhs-awards-behavioral-health-crisis-stabilization-grants-13-south-carolina",
  "2026-09-21_scdhhs_bh_crisis_13_hospitals_NEGATIVE_CONTROL.html",
  paste("THE SHARPEST §0.1 TRAP THIS STATE HAS: a real named roster OF",
        "HOSPITALS -- 'Behavioral Health Crisis Stabilization Grants to 13",
        "South Carolina Hospitals', ~$35,000,000 -- linked from the RHTP page",
        "itself and awarded 2023-06-23, THIRTY MONTHS before the NOA.",
        "California's SRHRP trap, and the hospital-money one.")
)

sc_source <- function(key, field) {
  row <- SC_SOURCES[SC_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[SC] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

sc_path <- function(key) file.path(SC_EVIDENCE_DIR, sc_source(key, "file"))

sc_have_archive <- function() {
  all(file.exists(vapply(SC_SOURCES$key, sc_path, character(1))))
}


# -- retrieval ---------------------------------------------------------------

sc_get <- function(url, label) {
  resp <- httr::GET(url, httr::user_agent(SC_USER_AGENT),
                    httr::config(followlocation = TRUE), httr::timeout(120))
  if (httr::status_code(resp) != 200L) {
    stop("[SC] ", label, ": HTTP ", httr::status_code(resp), " from ", url,
         call. = FALSE)
  }
  httr::content(resp, as = "raw")
}

#' Refuse to archive a third-party credential
#'
#' CMS's newsroom chrome carries a Mapbox token (§7.1, session 11), so the CMS
#' release is reduced before it is written; this is the belt that catches the
#' day a reduction stops working, or a state host acquires one.
sc_assert_no_credentials <- function(raw, label) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "bytes"
  for (p in c("[ps]k\\.ey[A-Za-z0-9._-]{10,}", "AIza[0-9A-Za-z_-]{30,}")) {
    if (grepl(p, txt, useBytes = TRUE, perl = TRUE)) {
      stop("[SC] ", label, " carries a credential-shaped string (", p,
           "); it was NOT written.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

sc_fetch <- function(force = FALSE) {
  dir.create(SC_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(SC_SOURCES)), function(i) {
    src  <- SC_SOURCES[i, ]
    dest <- file.path(SC_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && !force) {
      message("[SC] have ", src$file)
    } else {
      raw <- sc_get(src$url, src$key)
      if (src$key == "cms_release") {
        # The reduction is not optional and is not ours to skip: see §7.1.
        source(here::here("R", "00_cms_press_monitor.R"), local = TRUE)
        raw <- charToRaw(cms_newsroom_reduce_release(raw))
      }
      sc_assert_no_credentials(raw, src$key)
      writeBin(raw, dest)
      message("[SC] wrote ", src$file, " (", length(raw), " bytes)")
      Sys.sleep(3)
    }
    tibble::tibble(file = src$file, bytes = file.size(dest),
                   sha256 = digest::digest(file = dest, algo = "sha256"))
  })
  sc_write_manifest(entries)
  invisible(entries)
}

sc_write_manifest <- function(entries) {
  path <- file.path(SC_EVIDENCE_DIR, "MANIFEST.txt")
  entries <- entries[entries$file != "MANIFEST.txt", ]
  writeLines(c(
    "SOUTH CAROLINA -- RHTP evidence archive",
    "",
    "Fetched 2026-09-21 by R/03ao_sc_year1_awardees.R --fetch.",
    "Bodies are written with writeBin(), so re-hashing a file on disk",
    "reproduces its digest below.",
    "",
    "THE HOST'S DIGESTS HOLD, WHICH IS RARE HERE AND IS MEASURED RATHER THAN",
    "ASSUMED. Three fetches of the programme page inside one minute returned",
    "156,103 bytes and the SAME SHA-256 every time, and two fetches of the",
    "award list PDF likewise. Only MAINE's digests have previously held.",
    "",
    "THAT IS NOT A CLAIM THAT THEY ALWAYS WILL. Session 34 established that a",
    "back-to-back pair is not a stability test -- California's cache variant",
    "is GUARANTEED to pass one -- so --probe compares a CONTENT digest anyway.",
    "It costs nothing and it is the only form that survives a host acquiring a",
    "rotating token later.",
    "",
    "THE CMS RELEASE IS REDUCED, the other four are archived as served.",
    "CMS's page chrome carries a third-party Mapbox token in its Drupal",
    "settings JSON, which is CMS's to publish and not ours to redistribute",
    "(§7.1, session 11), so only <main> and the schema.org JSON-LD are kept.",
    "The full page as served hashes to",
    "acec2a68b3e6ef80e0519ba78091638f518059d8a8c2ab53b9947e63a6a62f07,",
    "so provenance still closes.",
    "",
    "file  bytes  sha256",
    paste(entries$file, entries$bytes, entries$sha256, sep = "  ")
  ), path)
  invisible(path)
}


# -- reduction ---------------------------------------------------------------

sc_reduce_html <- function(raw) {
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt <- stringr::str_remove_all(
    txt, stringr::regex("<(script|style|noscript)[^>]*>.*?</\\1>",
                        dotall = TRUE, ignore_case = TRUE))
  txt <- stringr::str_replace_all(txt, "<[^>]+>", " ")
  txt <- stringr::str_replace_all(txt, "&nbsp;|&#160;", " ")
  txt <- stringr::str_replace_all(txt, "&amp;", "&")
  txt <- stringr::str_replace_all(txt, "&#8217;|&#39;|&rsquo;|\u2019", "'")
  txt <- stringr::str_replace_all(txt, "&#8211;|&ndash;|&#8212;|&mdash;", "-")
  txt <- stringr::str_replace_all(txt, "[\u2010-\u2015\u2212]", "-")
  txt <- stringr::str_replace_all(txt, "&quot;|&ldquo;|&rdquo;", "\"")
  txt <- stringr::str_replace_all(txt, "[ \t\u00a0]+", " ")
  txt <- stringr::str_replace_all(txt, "\\s*\n\\s*", "\n")
  stringr::str_trim(txt)
}

sc_html_text <- function(key, body = NULL) {
  p <- sc_path(key)
  raw <- if (is.null(body)) readBin(p, "raw", file.size(p)) else body
  sc_reduce_html(raw)
}

sc_content_digest <- function(key, body = NULL) {
  digest::digest(sc_html_text(key, body), algo = "sha256", serialize = FALSE)
}


# ============================================================================
# THE PARSE
# ============================================================================

# The producer's column bands, in points. The number column is centred, so a
# one-digit number sits at 82.68 and a two-digit one at 76.26; the amount
# column is RIGHT-aligned, so its x varies with the figure's width. Both are
# read as bands rather than as positions for exactly that reason.
SC_NUM_X   <- c(76, 96)
SC_NAME_X  <- c(96, 450)
SC_AMT_X   <- 450

# Text that sits inside a band and is not data.
SC_NOT_DATA <- c("#", "Organization Name", "Total Funding Amount")

sc_runs <- function(path = sc_path("award_list")) {
  r <- rhtp_pdf_run_table(path)
  r$t <- trimws(r$text)
  r
}

#' The Initiative and Project headings, in document order
sc_headings <- function(runs = sc_runs()) {
  h <- runs[grepl("^(Initiative|Project):", runs$t), c("page", "y", "t")]
  h[order(h$page, -h$y), , drop = FALSE]
}

#' Assemble the 228 award rows
#'
#' ROWS ARE ANCHORED ON THE AMOUNT COLUMN, NOT ON THE ROW NUMBER, and that is
#' a deliberate choice rather than a convenience: South Carolina prints one row
#' number as "I2" (see the header), so a parser keying on `^[0-9]+$` drops a
#' real $120,000 award. The number is then used as the COMPLETENESS CHECK --
#' every project must number 1..n with no gap -- which is strictly stronger
#' than a total, because a total only catches a dropped row if the total is
#' known independently, and this document publishes none.
#'
#' NAMES ARE GATHERED BY Y-BAND, NOT BY LINE ID. Twenty-three rows wrap their
#' name over two visual lines and the producer paints the number and the amount
#' at the MIDPOINT of the two, interleaving the line ids -- so the line model
#' cannot assemble these rows at all (see
#' `sc_assert_line_model_cannot_read_this()`). A row's band runs to the
#' midpoint between its amount and the amounts above and below it.
#'
#' A LINE'S RUNS ARE PASTED WITH `collapse = ""`, which is what
#' `rhtp_pdf_compose_lines()` does and is correct on this producer: it paints
#' its spaces as runs of their own. That is PROVED, not assumed, by
#' `sc_assert_no_positioning_space()`.
sc_parse_award_list <- function(runs = sc_runs()) {
  heads <- sc_headings(runs)

  amt <- runs[runs$x > SC_AMT_X &
              grepl("^\\$[0-9,]+\\.[0-9]{2}$", runs$t), c("page", "y", "t")]
  amt <- amt[order(amt$page, -amt$y), , drop = FALSE]
  if (!nrow(amt)) stop("[SC] no amount runs found in the award list.",
                       call. = FALSE)

  name_ok <- runs$x >= SC_NAME_X[1] & runs$x < SC_NAME_X[2] &
    !grepl("^(Initiative|Project):", runs$t) & !(runs$t %in% SC_NOT_DATA)
  num_ok <- runs$x >= SC_NUM_X[1] & runs$x < SC_NUM_X[2] &
    !grepl("^(Initiative|Project):", runs$t) & !(runs$t %in% SC_NOT_DATA) &
    !grepl("^South Carolina Rural Health Transformation", runs$t)

  out <- purrr::map_dfr(seq_len(nrow(amt)), function(i) {
    pg <- amt$page[i]; ay <- amt$y[i]

    same_pg_above <- i > 1L && amt$page[i - 1L] == pg
    same_pg_below <- i < nrow(amt) && amt$page[i + 1L] == pg
    hi <- if (same_pg_above) (amt$y[i - 1L] + ay) / 2 else ay + 12
    lo <- if (same_pg_below) (amt$y[i + 1L] + ay) / 2 else ay - 12

    nb <- runs[num_ok & runs$page == pg & abs(runs$y - ay) < 1.0 &
               nzchar(runs$t), , drop = FALSE]
    nm <- runs[name_ok & runs$page == pg & runs$y > lo & runs$y < hi, ,
               drop = FALSE]

    # One composed string per visual line, top line first.
    by_line <- split(nm, sprintf("%.2f", nm$y))
    by_line <- by_line[order(as.numeric(names(by_line)), decreasing = TRUE)]
    parts <- vapply(by_line, function(d) {
      d <- d[order(d$x), , drop = FALSE]
      paste(d$text, collapse = "")
    }, character(1))
    # A line may be nothing but the producer's own padding space. It is kept in
    # the paste -- dropping a run is how a separator goes missing -- but it is
    # NOT counted as a line of the name.
    content_lines <- sum(nzchar(trimws(parts)))

    hp  <- heads[heads$page < pg | (heads$page == pg & heads$y > ay), ,
                 drop = FALSE]
    ini <- tail(hp$t[grepl("^Initiative:", hp$t)], 1L)
    prj <- tail(hp$t[grepl("^Project:", hp$t)], 1L)
    if (!length(ini) || !length(prj)) {
      stop("[SC] an award row on page ", pg, " sits above the first ",
           "Initiative or Project heading; the section mapping is wrong.",
           call. = FALSE)
    }

    tibble::tibble(
      page        = pg,
      y           = ay,
      initiative  = sub("^Initiative:\\s*", "", ini),
      project     = sub("^Project:\\s*", "", prj),
      row_label   = if (nrow(nb)) paste(nb$t, collapse = "") else NA_character_,
      name_lines  = content_lines,
      awardee     = trimws(paste(parts, collapse = "")),
      amount      = as.numeric(gsub("[$,]", "", amt$t[i]))
    )
  })

  if (any(!nzchar(out$awardee))) {
    stop("[SC] ", sum(!nzchar(out$awardee)), " award row(s) came out with an ",
         "EMPTY organisation name. That is the shape a wrapped row takes when ",
         "the y-band is wrong, and it must never be written.", call. = FALSE)
  }
  out
}


# ============================================================================
# THE PARSE ASSERTIONS
# ============================================================================

# South Carolina's own row-number defect, recorded and not corrected (§8).
SC_MALFORMED_ROW_LABEL <- "I2"
SC_MALFORMED_ROW_PROJECT <- "Healthcare Workforce"
SC_MALFORMED_ROW_AWARDEE <- "Rebound Behavioral Health"
SC_MALFORMED_ROW_AMOUNT  <- 120000

# Rows whose organisation name wraps over two (or three) visual lines. The
# producer paints their number and amount at the MIDPOINT of the name lines,
# with interleaved line ids, so the line model cannot assemble them.
SC_WRAPPED_ROWS <- 33L

#' Every project numbers 1..n with no gap -- the completeness check
#'
#' THIS IS THE CHECK THAT WOULD CATCH A DROPPED ROW, and it is stronger than a
#' total, because the award list publishes NO total of any kind: not a grand
#' total, not a subtotal, not a Total row. $167,299,900.69 is the SUM of the
#' rows, so reconciling the rows to it proves nothing about completeness on its
#' own -- it is the CMS release's independent "228 grants" and this per-project
#' sequence that do.
#'
#' AND SOUTH CAROLINA PRINTS ONE ROW NUMBER WRONG. Healthcare Workforce row 2
#' reads "I2" -- a capital I where a digit belongs -- so a check keyed on
#' `^[0-9]+$` reports a gap at 2 and a parser keyed on it drops the row
#' entirely, losing Rebound Behavioral Health and $120,000. It is accommodated
#' by name here rather than repaired by a loose regex, so the day South
#' Carolina re-posts a corrected list this assertion says so.
sc_assert_row_numbering <- function(d = sc_parse_award_list()) {
  seen_malformed <- FALSE
  for (pr in unique(d$project)) {
    s <- d[d$project == pr, , drop = FALSE]
    lab <- s$row_label
    if (any(is.na(lab))) {
      stop("[SC] project '", pr, "' has ", sum(is.na(lab)), " row(s) with no ",
           "row number at all; the number band is wrong.", call. = FALSE)
    }
    norm <- lab
    hit <- lab == SC_MALFORMED_ROW_LABEL
    if (any(hit)) {
      seen_malformed <- TRUE
      if (pr != SC_MALFORMED_ROW_PROJECT) {
        stop("[SC] the malformed row label '", SC_MALFORMED_ROW_LABEL,
             "' has moved: it is recorded under '", SC_MALFORMED_ROW_PROJECT,
             "' and appeared under '", pr, "'. Re-read the document.",
             call. = FALSE)
      }
      norm[hit] <- "2"
    }
    if (!all(grepl("^[0-9]+$", norm))) {
      stop("[SC] project '", pr, "' carries row label(s) that are neither a ",
           "number nor the one recorded defect: ",
           paste(unique(norm[!grepl("^[0-9]+$", norm)]), collapse = ", "),
           ". A new malformed label is a DOCUMENT TO RE-READ, never a regex ",
           "to loosen -- loosening it is how a real row gets silently ",
           "renumbered.", call. = FALSE)
    }
    if (!identical(as.integer(norm), seq_len(nrow(s)))) {
      stop("[SC] project '", pr, "' does not number 1..", nrow(s),
           " in order; the parse has dropped, duplicated or reordered a row. ",
           "Got: ", paste(norm, collapse = ","), call. = FALSE)
    }
  }
  if (!seen_malformed) {
    stop("[SC] the recorded row-number defect '", SC_MALFORMED_ROW_LABEL,
         "' is GONE from the award list. That is South Carolina correcting ",
         "its own document, which is good news and still a re-read: confirm ",
         "the row count and the total before relaxing this.", call. = FALSE)
  }
  # And the row the defect sits on is the one recorded, with its money intact.
  bad <- d[d$row_label == SC_MALFORMED_ROW_LABEL, , drop = FALSE]
  if (nrow(bad) != 1L || bad$awardee != SC_MALFORMED_ROW_AWARDEE ||
      !isTRUE(all.equal(bad$amount, SC_MALFORMED_ROW_AMOUNT))) {
    stop("[SC] the 'I2' row is no longer ", SC_MALFORMED_ROW_AWARDEE, " at $",
         format(SC_MALFORMED_ROW_AMOUNT, big.mark = ","), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' The line model CANNOT read this document, and the failure is driven
#'
#' Twenty-three rows wrap their organisation name over two visual lines, and
#' the producer paints the number and the amount at the MIDPOINT of the two --
#' interleaving the line ids, so on page 8 the name's first line is line 22,
#' the number line 21, the name's second line 23 and the amount line 24.
#' `rhtp_pdf_lines()` groups by line id, so it emits a name with no amount and
#' an amount with no name for every one of them.
#'
#' Arkansas asserted that the line model still MERGES its columns (session 40)
#' and Wyoming that it still SPLITS a name into a separate run (session 42).
#' South Carolina is the third shape: the line model INTERLEAVES, so it cannot
#' even tell which name belongs to which amount. Asserting it here is what
#' stops a future session "simplifying" this parse back onto lines.
sc_assert_line_model_cannot_read_this <- function(
    path = sc_path("award_list"), d = sc_parse_award_list()) {
  wrapped <- d[d$name_lines > 1L, , drop = FALSE]
  if (nrow(wrapped) != SC_WRAPPED_ROWS) {
    stop("[SC] ", nrow(wrapped), " rows wrap their organisation name over ",
         "more than one line; ", SC_WRAPPED_ROWS, " were measured. The y-band ",
         "assembly is tuned to this document, so a change here is a document ",
         "to re-read.", call. = FALSE)
  }
  lines <- rhtp_pdf_lines(path)
  has_amt <- grepl("\\$[0-9,]+\\.[0-9]{2}", lines$text)
  # For EVERY wrapped row, no single line of the line model carries both the
  # assembled name and a money figure -- which is the line model failing to
  # assemble the row at all, not merely formatting it differently.
  for (i in seq_len(nrow(wrapped))) {
    nm <- wrapped$awardee[i]
    if (any(has_amt & grepl(nm, lines$text, fixed = TRUE))) {
      stop("[SC] the line model reads the wrapped row '", nm, "' as a single ",
           "line carrying its amount. That contradicts the interleaving this ",
           "parse is built on -- the producer paints a wrapped row's number ",
           "and amount at the MIDPOINT of the two name lines, giving them ",
           "their own line ids -- so re-read the document before trusting ",
           "either reader.", call. = FALSE)
    }
  }
  # And the line model must still assemble the ORDINARY rows, or this says
  # nothing about wrapping: it would just mean the reader is broken.
  plain <- d[d$name_lines == 1L, , drop = FALSE]
  readable <- vapply(utils::head(plain$awardee, 20L), function(nm) {
    any(has_amt & grepl(nm, lines$text, fixed = TRUE))
  }, logical(1))
  if (!all(readable)) {
    stop("[SC] the line model cannot read ", sum(!readable), " of 20 ",
         "UNWRAPPED rows either, so its failure on the wrapped ones is not ",
         "evidence about wrapping. Re-read the document.", call. = FALSE)
  }
  invisible(tibble::tibble(wrapped_rows_unreadable_by_line_model =
                             nrow(wrapped)))
}


#' PROVE that no space was lost at a run boundary, from the PDF's own /Widths
#'
#' SESSION 32 LEFT THIS OPEN AND SOUTH CAROLINA IS WHERE IT GETS ANSWERED.
#' Two runs on one line can be separated by a painted SPACE GLYPH or by pen
#' POSITIONING, and the run table cannot tell them apart by itself -- Iowa cost
#' one name to exactly that, and CLAUDE.md records that "if a later state meets
#' this at scale, the fix is glyph widths in the reader".
#'
#' South Carolina meets it at scale: 23 rows, 47 within-line run boundaries,
#' and organisation names on both sides of them. So the question is settled by
#' measurement rather than by a convention:
#'
#'   scale   = min over all boundaries of gap / width(previous run), which is
#'             a boundary with NO space in it (a gap cannot be negative), and
#'             comes out at 0.012 pt per 1000 em-units, i.e. 12pt type.
#'   extra_i = gap_i / scale - width(previous run), in em-units.
#'
#' Every boundary must land within tolerance of 0 (no space) or of the font's
#' own space width, 203 units. ANYTHING IN BETWEEN IS REFUSED rather than
#' rounded, because a boundary this test cannot classify is a boundary whose
#' name this project cannot spell.
#'
#' THE RESULT IS THAT THE READER NEEDS NO FIX ON THIS PRODUCER: every space is
#' a painted run, so pasting with `collapse = ""` is exact. This function's job
#' is to keep that true, not to repair anything.
sc_font_widths <- function(path = sc_path("award_list"),
                           base = "PFOKMJ\\+Aptos") {
  bytes <- readBin(path, "raw", file.info(path)$size)
  objs  <- rhtp_pdf_objstm_expand(rhtp_pdf_objects(bytes))
  out <- NULL
  for (k in names(objs)) {
    body <- objs[[k]]
    txt <- rhtp_pdf_chr(body[seq_len(min(length(body), 20000L))])
    # useBytes on every one of these: a PDF object dictionary can carry binary
    # that is not valid UTF-8, and without it R warns on each and -- as
    # session 24 found the hard way -- a signed document kills the reader
    # outright. `rhtp_pdf_text.R`'s own scanners carry the same flag.
    if (!grepl(paste0("/BaseFont\\s*/", base, "[^-A-Za-z]"), txt,
               perl = TRUE, useBytes = TRUE)) next
    if (!grepl("/Widths", txt, fixed = TRUE, useBytes = TRUE)) next
    fc <- regmatches(txt, regexec("/FirstChar\\s+(\\d+)", txt, useBytes = TRUE))[[1]]
    wm <- regmatches(txt, regexec("/Widths\\s*\\[([^]]*)\\]", txt, useBytes = TRUE))[[1]]
    if (length(fc) < 2L || length(wm) < 2L) next
    out <- list(first = as.integer(fc[2]),
                w = suppressWarnings(
                  as.numeric(strsplit(trimws(wm[2]), "[[:space:]]+")[[1]])))
  }
  if (is.null(out)) {
    stop("[SC] the award list carries no /Widths array for ", base,
         "; the spacing proof cannot run, so the organisation names are ",
         "UNVERIFIED. Read the document before trusting them.", call. = FALSE)
  }
  out
}

# The decision band, in the font's own em-units. A space is 203 units; the
# widths-only model's residual is bounded WELL below that (see below), so a
# boundary is classified by which side of the midpoint it falls, and the
# assertion is that NOTHING SITS NEAR THE MIDPOINT.
SC_SPACE_CLEARANCE_UNITS <- 50

sc_assert_no_positioning_space <- function(runs = sc_runs(),
                                           path = sc_path("award_list")) {
  fw <- sc_font_widths(path)
  space_units <- fw$w[32L - fw$first + 1L]
  if (!isTRUE(space_units > 0)) {
    stop("[SC] the font's space glyph has no width; the spacing proof is ",
         "meaningless.", call. = FALSE)
  }

  nm <- runs[runs$x >= SC_NAME_X[1] & runs$x < SC_NAME_X[2] &
             !grepl("^(Initiative|Project):", runs$t) &
             !(runs$t %in% SC_NOT_DATA) & nzchar(runs$t), , drop = FALSE]

  width_units <- function(s) {
    cp <- utf8ToInt(s)
    i <- cp - fw$first + 1L
    if (any(is.na(i) | i < 1L | i > length(fw$w))) return(NA_real_)
    ww <- fw$w[i]
    if (any(ww == 0)) return(NA_real_)
    sum(ww)
  }

  key <- paste(nm$page, sprintf("%.2f", nm$y))
  rows <- list()
  for (k in unique(key)) {
    g <- nm[key == k, , drop = FALSE]
    g <- g[order(g$x), , drop = FALSE]
    if (nrow(g) < 2L) next
    for (i in seq_len(nrow(g) - 1L)) {
      rows[[length(rows) + 1L]] <- tibble::tibble(
        page = g$page[i], y = g$y[i], left = g$t[i], right = g$t[i + 1L],
        gap = g$x[i + 1L] - g$x[i], units = width_units(g$t[i]))
    }
  }
  b <- dplyr::bind_rows(rows)
  if (nrow(b) < 40L) {
    stop("[SC] only ", nrow(b), " within-line run boundaries found; 45 were ",
         "measured. The spacing proof has nothing to prove.", call. = FALSE)
  }
  if (any(is.na(b$units))) {
    stop("[SC] ", sum(is.na(b$units)), " run(s) contain a character the ",
         "font's /Widths array does not cover, so their spacing CANNOT be ",
         "verified: ", paste(utils::head(b$left[is.na(b$units)], 3),
                             collapse = " | "), call. = FALSE)
  }

  # THE SCALE IS A LOWER BOUND AND IS DELIBERATELY NOT FITTED. The smallest
  # gap-to-width ratio in the document must be a boundary carrying NO space (a
  # gap cannot be negative), so it is the tightest honest estimate of points
  # per 1000 em-units available without reading the content stream's Tf
  # operator. It comes out at 0.011986, i.e. 12pt type to four figures.
  scale <- min(b$gap / b$units)
  b$extra <- b$gap / scale - b$units

  # THE RESIDUAL IS KERNING, NOT ERROR, AND THAT IS WHY A FIXED TOLERANCE WAS
  # THE WRONG SHAPE. A /Widths array gives each glyph's own advance and says
  # nothing about the pair adjustments the producer writes into its TJ arrays,
  # so a long run's measured advance falls SHORT of the sum of its widths by a
  # few hundredths of a point per kerned pair. Measured here: the unspaced
  # boundaries run from 0 to 37 units (0 to 0.44pt) and rise with the length of
  # the run, exactly as accumulated kerning would.
  #
  # IT DOES NOT MATTER, BECAUSE THE SIGNAL IS FIVE TIMES THE NOISE. A space is
  # 203 units; the worst unspaced residual is 37. So the two populations are
  # separated by a clear band, and THAT SEPARATION is what is asserted -- a
  # claim the document can falsify -- rather than a tolerance chosen to make
  # today's numbers pass.
  midpoint <- space_units / 2
  spaced   <- b$extra > midpoint
  ambiguous <- abs(b$extra - midpoint) < SC_SPACE_CLEARANCE_UNITS
  if (any(ambiguous)) {
    bad <- b[ambiguous, , drop = FALSE]
    stop("[SC] ", nrow(bad), " run boundary/boundaries sit within ",
         SC_SPACE_CLEARANCE_UNITS, " em-units of the decision midpoint, so ",
         "whether South Carolina printed a space there CANNOT BE READ. A ",
         "boundary this test cannot classify is a NAME THIS PROJECT CANNOT ",
         "SPELL, so nothing is rounded: re-read the document. First: '",
         bad$left[1], "' | '", bad$right[1], "' extra = ",
         round(bad$extra[1], 1), " units against a space of ", space_units,
         ".", call. = FALSE)
  }

  # And BOTH populations must occur, or the test is not discriminating: a
  # document in which every boundary came out the same way would pass a
  # separation check while proving nothing.
  if (!any(spaced) || !any(!spaced)) {
    stop("[SC] the spacing measurement found only one population (",
         sum(!spaced), " unspaced, ", sum(spaced), " spaced) and is ",
         "therefore not separating the two cases.", call. = FALSE)
  }

  # NOTE the names: `tibble()` evaluates its arguments in order and lets a
  # later one see an earlier one, so a column called `spaced` would mask the
  # logical vector of the same name and silently subset by the COUNT instead.
  invisible(tibble::tibble(
    boundaries = nrow(b), scale = scale, space_units = space_units,
    n_unspaced = sum(!spaced), n_spaced = sum(spaced),
    worst_unspaced = max(b$extra[!spaced]),
    closest_spaced = min(b$extra[spaced])))
}


# THREE SPELLINGS OF ONE ORGANISATION'S NAME, IN ONE DOCUMENT, FROM ONE
# PUBLISHER. Nineteen rows name a Prisma Health entity and the prefix is
# printed three different ways. NONE IS MERGED (§2 forbids a machine resolving
# a fuzzy name match).
SC_PRISMA_HYPHEN_NO_SPACE <- 17L   # "Prisma Health-Upstate (Laurens)"
SC_PRISMA_HYPHEN_SPACE    <- 1L    # "Prisma Health- Upstate (Anderson)"
SC_PRISMA_NO_HYPHEN       <- 1L    # "Prisma Health (Oconee)"
SC_PRISMA_ROWS            <- 19L

SC_AIKEN_SPACED <- "SCDBHDD Office of Mental Health & Envoy Portfolio (Aiken Barnwell Mental Health Center)"
SC_AIKEN_HYPHEN <- "SCDBHDD Office of Mental Health & Envoy Portfolio (Aiken-Barnwell Mental Health Center)"

#' South Carolina spells one organisation three ways, and two of the three
#' differ by a single space
#'
#' THIS IS MISSISSIPPI'S LIFECORE ROW IN A STATE THAT PUBLISHES NO COUNTY, AND
#' THAT IS WHY IT IS ASSERTED RATHER THAN NOTED. Mississippi's hyphenated legal
#' name misassigned a name and a county while every total still reconciled to
#' the cent -- invisible to the row count and invisible to the money. South
#' Carolina's costs even less: no delimiter split depends on it, so not a
#' dollar and not a row moves. What it does do is turn one organisation into
#' three awardee strings, which is exactly the quantity a reader uses to say
#' "228 awards went to 130 organisations".
#'
#'   17 rows  "Prisma Health-Upstate (Laurens)"     hyphen, no spaces
#'    1 row   "Prisma Health- Upstate (Anderson)"   hyphen, then a space
#'    1 row   "Prisma Health (Oconee)"              a space, no hyphen
#'
#' The same thing happens once more in the SCDBHDD block, with the hyphen and
#' the space swapped: "(Aiken Barnwell Mental Health Center)" on one row and
#' "(Aiken-Barnwell Mental Health Center)" on another.
#'
#' AND THE FIRST TWO ARE ONLY DISTINGUISHABLE BECAUSE THE SPACING WAS MEASURED.
#' Both are painted as three runs -- name, hyphen, remainder -- and the
#' difference between them is whether the producer painted a space run after
#' the hyphen. A reader that pasted runs with a separator would print all
#' eighteen as "Prisma Health - Upstate ...", and one that stripped whitespace
#' before pasting would print all eighteen unspaced; either way the divergence
#' disappears and 130 becomes 129 for a reason no one could see.
#' `sc_assert_no_positioning_space()` is what makes this readable at all.
sc_assert_two_spellings <- function(d = sc_parse_award_list()) {
  p <- d$awardee[grepl("^Prisma Health", d$awardee)]
  if (length(p) != SC_PRISMA_ROWS) {
    stop("[SC] expected ", SC_PRISMA_ROWS, " Prisma Health rows and found ",
         length(p), "; re-read the document.", call. = FALSE)
  }
  counts <- c(
    hyphen_no_space = sum(grepl("^Prisma Health-[A-Z]", p)),
    hyphen_space    = sum(grepl("^Prisma Health- [A-Z]", p)),
    no_hyphen       = sum(grepl("^Prisma Health [A-Z(]", p)))
  expected <- c(hyphen_no_space = SC_PRISMA_HYPHEN_NO_SPACE,
                hyphen_space    = SC_PRISMA_HYPHEN_SPACE,
                no_hyphen       = SC_PRISMA_NO_HYPHEN)
  if (!identical(as.integer(counts), as.integer(expected))) {
    stop("[SC] the Prisma Health spellings have moved: ",
         paste(names(counts), counts, sep = "=", collapse = ", "),
         " against ", paste(names(expected), expected, sep = "=",
                            collapse = ", "),
         ". If South Carolina has tidied its list, re-read it and re-count. ",
         "DO NOT merge the forms here (§2).", call. = FALSE)
  }
  if (sum(counts) != SC_PRISMA_ROWS) {
    stop("[SC] ", SC_PRISMA_ROWS - sum(counts), " Prisma Health row(s) match ",
         "none of the three recorded spellings, so a FOURTH form has ",
         "appeared. Re-read the document.", call. = FALSE)
  }
  if (!SC_AIKEN_SPACED %in% d$awardee || !SC_AIKEN_HYPHEN %in% d$awardee) {
    stop("[SC] the two Aiken Barnwell spellings are no longer both present. ",
         "Same rule: re-read, do not merge.", call. = FALSE)
  }
  invisible(tibble::tibble(form = names(counts), rows = as.integer(counts)))
}


# ============================================================================
# RECONCILIATION
# ============================================================================

#' The eight projects and the four initiatives, with their totals
sc_reconcile <- function(d = sc_parse_award_list()) {
  d %>%
    dplyr::group_by(.data$initiative, .data$project) %>%
    dplyr::summarise(rows = dplyr::n(), total = sum(.data$amount),
                     .groups = "drop") %>%
    dplyr::arrange(.data$initiative, .data$project)
}

#' The list reconciles -- and what it reconciles TO is the point
#'
#' THIS DOCUMENT PUBLISHES NO TOTAL. Not a grand total, not a per-project
#' subtotal, not a Total row of the kind Arkansas's and Mississippi's lists
#' carry. So $167,299,900.69 is the SUM OF THE ROWS and reconciling the rows to
#' it would be circular on its own.
#'
#' WHAT MAKES IT A RECONCILIATION IS THAT TWO OTHER FACTS COME FROM OUTSIDE THE
#' ARITHMETIC:
#'
#'   - CMS says "The RHTP funding will support 228 GRANTS" -- a count, from a
#'     publisher who did not write the list, matching the 228 rows parsed.
#'   - CMS heads its release "$167 Million", which the sum rounds to.
#'   - Each project numbers 1..n with no gap (`sc_assert_row_numbering()`),
#'     which is the completeness check a total cannot give here.
#'
#' Three independent statements about the same roster, and none of them was
#' arranged.
sc_assert_reconciles <- function(d = sc_parse_award_list()) {
  if (nrow(d) != SC_AWARD_ROWS) {
    stop("[SC] parsed ", nrow(d), " award rows against the ", SC_AWARD_ROWS,
         " measured, and against CMS's own stated count of ", SC_CMS_GRANTS,
         ".", call. = FALSE)
  }
  if (!isTRUE(all.equal(sum(d$amount), SC_AWARD_TOTAL, tolerance = 1e-8))) {
    stop("[SC] the 228 rows sum to $",
         formatC(sum(d$amount), format = "f", digits = 2, big.mark = ","),
         " against the $", formatC(SC_AWARD_TOTAL, format = "f", digits = 2,
                                   big.mark = ","), " measured.",
         call. = FALSE)
  }
  if (SC_AWARD_ROWS != SC_CMS_GRANTS) {
    stop("[SC] this file's row count and CMS's stated grant count have been ",
         "allowed to diverge in the constants; they are the corroboration.",
         call. = FALSE)
  }
  r <- sc_reconcile(d)
  if (nrow(r) != 8L || dplyr::n_distinct(r$initiative) != 4L) {
    stop("[SC] expected 8 projects across 4 initiatives and found ", nrow(r),
         " across ", dplyr::n_distinct(r$initiative), ".", call. = FALSE)
  }
  if (!isTRUE(all.equal(sum(r$total), SC_AWARD_TOTAL, tolerance = 1e-8))) {
    stop("[SC] the eight project totals do not sum to the round.",
         call. = FALSE)
  }
  # 228 ACTIONS, NOT 228 ORGANISATIONS. Michigan's lesson, and here the margin
  # is large enough that nobody should be able to miss it.
  if (dplyr::n_distinct(d$awardee) != SC_AWARDEE_STRINGS) {
    stop("[SC] ", dplyr::n_distinct(d$awardee), " distinct awardee strings ",
         "against the ", SC_AWARDEE_STRINGS, " measured. That figure is an ",
         "UPPER BOUND on organisations (the list spells several bodies more ",
         "than one way), so it moving is a document to re-read.",
         call. = FALSE)
  }
  invisible(r)
}

#' Rows are not organisations, and the margin is large
#'
#' Newberry County Memorial Hospital holds TWELVE awards across FOUR projects,
#' Self Regional Healthcare (Lakelands Region) ELEVEN across FIVE, Hampton
#' Regional Medical Center TEN across FOUR. A reader who took 228 as an
#' organisation count would be wrong by a factor of nearly two, and a reader
#' who de-duplicated the rows would lose $80m of real awards.
sc_assert_rows_are_not_organisations <- function(d = sc_parse_award_list()) {
  rep <- d %>%
    dplyr::count(.data$awardee, name = "rows") %>%
    dplyr::filter(.data$rows > 1L)
  if (nrow(rep) < 30L) {
    stop("[SC] only ", nrow(rep), " awardee strings hold more than one award; ",
         "the repetition that makes rows != organisations has gone.",
         call. = FALSE)
  }
  top <- d %>%
    dplyr::group_by(.data$awardee) %>%
    dplyr::summarise(rows = dplyr::n(),
                     projects = dplyr::n_distinct(.data$project),
                     .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(.data$rows))
  if (top$awardee[1] != "Newberry County Memorial Hospital" ||
      top$rows[1] != 12L || top$projects[1] != 4L) {
    stop("[SC] the most-repeated awardee is no longer Newberry County ",
         "Memorial Hospital at 12 rows across 4 projects; it is '",
         top$awardee[1], "' at ", top$rows[1], " rows across ",
         top$projects[1], ".", call. = FALSE)
  }
  invisible(top)
}


# ============================================================================
# §6.2 PROVENANCE, AND THE CONTROLS
# ============================================================================

# SCDHHS's own four RHTP initiative names, from its programme page. These are
# EXACTLY the four Initiative headings the award list is sectioned by, which
# is the structural tie that carries this state's provenance.
SC_INITIATIVES <- c("Connections to Care", "Leveling Up",
                    "Wellness Within Reach", "Shoring Up to Sustainability")
# The fifth, which the page says is still to come and which is therefore
# ABSENT from the award list.
SC_FIFTH_INITIATIVE <- "Tech Catalyst Fund"

#' THE AWARD LIST CARRIES NO CMS FOOTER AT ALL -- measured, not assumed
#'
#' Arkansas's shape (session 40): a state's own award list with the programme
#' nowhere in it. Here it is even barer -- "Centers for Medicare",
#' "financial assistance", "funded by CMS" and even the bare token "CMS" occur
#' ZERO times in eight pages.
#'
#' AND THE FOOTER HAS GONE FROM THE PROGRAMME PAGE TOO, WHICH IS NEW HERE.
#' Session 39 read `scdhhs.gov/RHTP` and recorded the STRONG, programme-scoped
#' form -- "The RHTP is supported by ... a financial assistance award totaling
#' $200,030,252.32". That path now 301s to `/resources/grants` and the live
#' page carries no such sentence.
#'
#' THIS IS RECORDED AS AN OBSERVATION ABOUT THE SOURCE, NOT A FINDING ABOUT THE
#' PROGRAMME (§0.4). A publisher dropping a footer says nothing about where the
#' money came from, and session 27's audit is the reason it costs nothing here:
#' the footer was never this state's provenance, and three programme-scoped
#' facts are.
sc_assert_no_cms_footer <- function(
    path = sc_path("award_list"), body = NULL) {
  txt <- paste(rhtp_pdf_text(path), collapse = " ")
  for (tok in c("Centers for Medicare", "financial assistance",
                "funded by CMS", "CMS")) {
    if (grepl(tok, txt, fixed = TRUE)) {
      stop("[SC] the award list now contains '", tok, "'. It carried NO CMS ",
           "footer at all when this file was written, which is why the ",
           "provenance rests on the programme page and CMS's own release. A ",
           "footer appearing is good news and still a re-read -- and if it ",
           "carries a FIGURE, check its tier before using it (§0.2).",
           call. = FALSE)
    }
  }
  page <- sc_html_text("programme", body)
  if (grepl("financial assistance award totaling", page, fixed = TRUE)) {
    stop("[SC] the programme page has REGAINED the CMS financial-assistance ",
         "footer session 39 recorded and session 45's redirect lost. Read it ",
         "and check its figure against the §7.1 anchor before using it: on ",
         "this state the footer's figure was the ALLOTMENT (§0.2), not a pool ",
         "and not an award.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The provenance that IS there, and it is structural rather than a sentence
sc_assert_provenance <- function(body = NULL) {
  page <- sc_html_text("programme", body)

  # 1. The programme page names the document, by name and by posting date.
  if (!grepl("SC RHTP Year 1 Award List", page, fixed = TRUE)) {
    stop("[SC] the programme page no longer names 'SC RHTP Year 1 Award ",
         "List'. That sentence is what ties the archived PDF to the RHTP ",
         "programme; without it this file's roster has no published parent.",
         call. = FALSE)
  }
  if (!grepl("Award List", page, fixed = TRUE)) {
    stop("[SC] the 'Award List' heading has gone from the programme page.",
         call. = FALSE)
  }

  # 2. It says whose programme it is, and that it is CMS's.
  for (sentence in c(
    "South Carolina's RHTP is administered by the South Carolina Department of Health and Human Services",
    "This federal initiative is led by the Centers for Medicare & Medicaid Services (CMS)")) {
    if (!grepl(sentence, page, fixed = TRUE)) {
      stop("[SC] the programme page no longer carries: '", sentence, "'.",
           call. = FALSE)
    }
  }

  # 3. THE INITIATIVE SET CLOSES. The award list's four Initiative headings are
  #    EXACTLY the four the page names, and the fifth the page names is exactly
  #    the one the list does not carry. A document whose section headings are
  #    the state's own RHTP initiative set -- complete, and with the one
  #    exception the state itself flags -- is tied to the programme by its
  #    STRUCTURE, which no re-wording can quietly break.
  d <- sc_parse_award_list()
  got <- sort(unique(d$initiative))
  if (!identical(got, sort(SC_INITIATIVES))) {
    stop("[SC] the award list's initiatives are ", paste(got, collapse = " | "),
         " against SCDHHS's stated four: ",
         paste(sort(SC_INITIATIVES), collapse = " | "), call. = FALSE)
  }
  for (ini in SC_INITIATIVES) {
    # The page prints "Leveling up" in one place and "Leveling Up" in another,
    # so the match is case-insensitive -- deliberately, and only here.
    if (!grepl(ini, page, ignore.case = TRUE, fixed = FALSE)) {
      stop("[SC] the programme page no longer names the initiative '", ini,
           "', so the structural tie between the list's sections and the ",
           "state's RHTP is broken.", call. = FALSE)
    }
  }
  if (any(grepl(SC_FIFTH_INITIATIVE, d$initiative, fixed = TRUE))) {
    stop("[SC] the award list now carries a ", SC_FIFTH_INITIATIVE,
         " section. That is South Carolina's FIFTH initiative arriving, so ",
         "this file is no longer four-of-five and the partial-year statement ",
         "in its report is wrong.", call. = FALSE)
  }

  # 4. The date test, re-derived rather than typed.
  if (!(SC_APPLICATION_DUE > SC_NOA_DATE &&
        SC_ANTICIPATED_NOA_DATE > SC_NOA_DATE &&
        as.Date(SC_LIST_POSTED) > SC_ANTICIPATED_NOA_DATE)) {
    stop("[SC] the date test no longer holds: applications due ",
         SC_APPLICATION_DUE, ", anticipated NOA ", SC_ANTICIPATED_NOA_DATE,
         ", list posted ", SC_LIST_POSTED, ", CMS Notice of Award ",
         SC_NOA_DATE, ".", call. = FALSE)
  }
  if (!grepl("Anticipated Notice of Award", page, fixed = TRUE)) {
    stop("[SC] the Grant Applicant Deadlines table has gone from the ",
         "programme page; the date test's source with it.", call. = FALSE)
  }

  # 5. The second publisher states the COUNT, not just the money.
  cms <- sc_html_text("cms_release")
  if (!grepl("will support 228 grants", cms, fixed = TRUE)) {
    stop("[SC] CMS's release no longer states 'will support 228 grants'. ",
         "That sentence is the only count of South Carolina's awards ",
         "published by anyone other than SCDHHS.", call. = FALSE)
  }
  if (!grepl("$167 Million", cms, fixed = TRUE) &&
      !grepl("$167 million", cms, fixed = TRUE)) {
    stop("[SC] CMS's release no longer carries its $167 million headline.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The positive control, and it fails in BOTH directions
#'
#' SCDHHS publishes a roster in a recognisable form when it has one: an
#' "Award List" heading with one named document under it. That is what makes
#' "the Tech Catalyst Fund has published no roster" a statement about South
#' Carolina rather than about our reading. A SECOND award-list link appearing
#' is the fifth initiative landing, and must fail here rather than be absorbed.
sc_assert_award_index <- function(body = NULL) {
  page <- sc_html_text("programme", body)
  n <- lengths(regmatches(page, gregexpr("SC RHTP Year [0-9]+ Award List",
                                         page)))
  if (n < 1L) {
    stop("[SC] the award-list link has gone from the programme page.",
         call. = FALSE)
  }
  if (n > 1L) {
    stop("[SC] the programme page now carries ", n, " RHTP award lists. A ",
         "SECOND list is either the Tech Catalyst Fund awarding or Year 2 ",
         "opening, and either way this file covers one of them. REWRITE IT, ",
         "do not patch it.", call. = FALSE)
  }
  invisible(TRUE)
}

#' The Tech Catalyst Fund has not awarded, so the year is four of five
sc_assert_tech_catalyst_pending <- function(body = NULL) {
  page <- sc_html_text("programme", body)
  claim <- paste("Funding opportunities for the fifth of South Carolina's",
                 "RHTP initiatives, the Tech Catalyst Fund, will be",
                 "announced through a future stage")
  if (!grepl(claim, page, fixed = TRUE)) {
    stop("[SC] SCDHHS no longer says the Tech Catalyst Fund is still to come. ",
         "That sentence is what makes $167,299,900.69 a PARTIAL year rather ",
         "than South Carolina's whole Year 1, and the difference is ",
         "$32,730,351. Re-read the page.", call. = FALSE)
  }
  # §7's designated pass-through route, named by the state and not yet awarded.
  if (!grepl("South Carolina Research Authority", page, fixed = TRUE)) {
    stop("[SC] the programme page no longer names the South Carolina Research ",
         "Authority as the Tech Catalyst Fund's administrator. That is §7's ",
         "designated pass-through route (Illinois/ICAHN's precedent) and is ",
         "where the remaining money will surface.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Both §0.1 negative controls, and the second is the hospital-money one
#'
#' They are on the RHTP page itself, which is what makes them dangerous and
#' what makes them good controls. §6.2's date test disposes of both by machine:
#' 2024-02-02 and 2023-06-23 against a 2025-12-29 Notice of Award.
SC_RMUA_AWARD_DATE <- as.Date("2024-02-02")
SC_BHCS_AWARD_DATE <- as.Date("2023-06-23")

sc_assert_controls <- function(bodies = NULL) {
  page <- sc_html_text("programme", if (is.null(bodies)) NULL else bodies$programme)

  # Control 1: a real named roster with "rural" in its title, and NOT RHTP.
  if (!grepl("SCDHHS has issued $48.2 million in total funds", page,
             fixed = TRUE)) {
    stop("[SC] the Rural & Medically Underserved Area control has changed on ",
         "the programme page. It is the §0.1 trap a hunt for 'awards' + ",
         "'rural' + a large figure takes first.", call. = FALSE)
  }
  if (!grepl("View the list of the awardees below", page, fixed = TRUE)) {
    stop("[SC] the RMUA roster link text has gone; the control no longer ",
         "shows that SCDHHS publishes named rosters when it has them.",
         call. = FALSE)
  }
  rmua <- sc_html_text("rmua_control",
                       if (is.null(bodies)) NULL else bodies$rmua_control)
  if (!grepl("SCDHHS Awards $48.2 Million", rmua, fixed = TRUE)) {
    stop("[SC] the RMUA release is no longer what it was.", call. = FALSE)
  }

  # Control 2: a real named roster OF HOSPITALS, and NOT RHTP. This is the one
  # that would put ~$35,000,000 of hospital money into a South Carolina RHTP
  # figure if anyone read the RHTP page carelessly.
  bhcs <- sc_html_text("bhcs_control",
                       if (is.null(bodies)) NULL else bodies$bhcs_control)
  if (!grepl("Behavioral Health Crisis Stabilization Grants to 13 South Carolina Hospitals",
             bhcs, fixed = TRUE)) {
    stop("[SC] the Behavioral Health Crisis Stabilization control is no ",
         "longer a named roster of 13 HOSPITALS. It is the sharpest §0.1 ",
         "trap this state has and the only one carrying hospital money.",
         call. = FALSE)
  }
  # And the date test disqualifies both WITHOUT anyone reading them.
  if (!(SC_RMUA_AWARD_DATE < SC_NOA_DATE && SC_BHCS_AWARD_DATE < SC_NOA_DATE)) {
    stop("[SC] the two control programmes no longer predate the Notice of ",
         "Award, so §6.2's date test no longer disposes of them on its own.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# ============================================================================
# §8 / §10.2 -- THE AWARD FILE
# ============================================================================

# The two spellings of one publisher's academic/hospital body, which classify
# OPPOSITE ways and are worth $3,345,533. Neither machine answer is overridden.
SC_MUSC_HOSPITAL_AUTHORITY <- "Medical University Hospital Authority"
SC_MUSC_UNIVERSITY         <- "Medical University of South Carolina"

#' Build the 228-row award file
#'
#' EVERY `recipient_type` IS DERIVED FROM THE RECIPIENT'S OWN NAME, because the
#' award list has three columns -- number, Organization Name, Total Funding
#' Amount -- and states nothing about anyone's organisational form, county or
#' project. There is no description to feed §10.2 either, so `flow` is decided
#' on recipient identity alone, which is what §0.3a asks for: judge the
#' RECIPIENT, never the activity.
#'
#' THE PROJECT NAME IS DELIBERATELY NOT USED AS A DESCRIPTION. "Facility
#' Enhancements" or "Mobile Crisis Response" describes what the money DOES, and
#' feeding it to `rhtp_classify_flow()` would let an ACTIVITY decide a
#' RECIPIENT's coding -- Arkansas's precedent (session 40), where the
#' Governor's project blurbs moved eleven rows between flow codes and not one
#' dollar. `sc_assert_typed_from_the_name()` requires every `recipient_type` to
#' be reproducible from the name alone.
#'
#' THE AWARDS ARE MADE, NOT INTENDED. SCDHHS published its "Anticipated Notice
#' of Award -- July 31, 2026" milestone, issued the Notices of Award
#' Determination on that date (bulletin MB# 26-026) and posted this list six
#' weeks later headed "Year 1 Awards". So `recipient_confirmed` and
#' `amount_confirmed` are both Yes -- stronger than Arkansas's or Wyoming's
#' intents, and stronger than Maryland's offers.
sc_year1_awardees <- function(d = sc_parse_award_list()) {
  cls   <- rhtp_classify_recipient_type(d$awardee, SC_STATE)
  rtype <- cls$recipient_type
  conf  <- cls$determination_confidence

  # No description exists, and none is invented. §10.2 decides on recipient
  # identity, with award_made = TRUE because these ARE awards.
  flow <- rhtp_classify_flow(rtype, rep("", nrow(d)), award_made = TRUE)

  fallback <- rtype == "NONPROFIT_CBO" & conf == "LOW"

  tibble::tibble(
    state = SC_STATE,
    row_no = seq_len(nrow(d)),
    awardee = d$awardee,
    amount = d$amount,
    recipient_type = rtype,
    distributed_to_hospital = flow$distributed_to_hospital,
    note = paste0(d$initiative, " / ", d$project),
    recipient_confirmed = "Yes",
    amount_confirmed = "Yes",
    fiscal_year = "FY2026 (Year 1)",
    source_document_title = "SC RHTP Year 1 Award List",
    state_source_url = sc_source("award_list", "url"),
    validation_source_type = "NOTICE_OF_AWARD",
    extraction_method = "PDF_TEXT",
    validator = "R/03ao_sc_year1_awardees.R",
    ccn = NA_character_,
    aha_id = NA_character_,
    rural_designation = NA_character_,
    reviewer = NA_character_,
    initiative = d$initiative,
    award_pool = d$project,
    row_in_pool = d$row_label,
    awardee_as_published = d$awardee,
    recipient_type_source = dplyr::if_else(
      fallback,
      paste("§8's STANDING FALLBACK. The award list publishes a recipient and",
            "an amount and NOTHING about the recipient's organisational form",
            "-- no type column, no county, no project description -- so",
            "Kansas's, Maryland's, Nebraska's, Oklahoma's, Nevada's,",
            "Michigan's, Missouri's, Iowa's, North Carolina's, Arkansas's,",
            "Wyoming's and Mississippi's shape a THIRTEENTH time. NOTHING WAS",
            "PROMOTED (§0.4), and the refusal runs BOTH ways: Self Regional",
            "Healthcare, McLeod Health, AnMed, Prisma Health and Tidelands",
            "Health read as hospital systems to anyone who knows South",
            "Carolina and are NOT promoted, while the nineteen SCDBHDD rows",
            "are the state's own behavioral health department and are NOT",
            "demoted to STATE_AGENCY. Both would be this pipeline asserting a",
            "form the document has not."),
      "DERIVED FROM THE RECIPIENT'S OWN NAME by rhtp_classify_recipient_type()."),
    determination_confidence = conf,
    flag_reason = dplyr::if_else(fallback, "RECIPIENT_TYPE_INFERRED",
                                 NA_character_),
    budget_period = "Budget Period 1",
    flow_type = flow$flow_type,
    hospital_benefiting = flow$hospital_benefiting,
    hospital_attribution = dplyr::if_else(
      flow$distributed_to_hospital == "Yes", "NAMED_HOSPITAL", "NOT_HOSPITAL"),
    intermediary_name = NA_character_,
    determination_basis = dplyr::if_else(
      flow$distributed_to_hospital == "Yes",
      paste("§10.2 DIRECT -- the named recipient is itself a hospital or",
            "health system, so recipient identity IS the flow test and no",
            "description decides it (§0.3a). The award is MADE: SCDHHS issued",
            "Notices of Award Determination on its own published date of",
            "2026-07-31 (MB# 26-026) and posted this list, headed 'Year 1",
            "Awards', on 2026-09-15."),
      paste("§10.2 -- the named recipient is not a hospital on the only",
            "evidence the document offers, which is its name. Where",
            "recipient_type is §8's standing fallback this is the",
            "CONSERVATIVE answer and the row is queued as",
            "SC_RECIPIENT_FORM_NOT_STATED: resolving it could only RAISE",
            "South Carolina's hospital figure, never lower it.")),
    amount_basis = paste(
      "EXACT and per-recipient, published by SCDHHS for every one of the 228",
      "rows. The document carries NO total of any kind, so the",
      "$167,299,900.69 this file reports is the SUM OF THE ROWS, corroborated",
      "from outside by CMS's own '228 grants' and '$167 Million' (2026-09-17)",
      "and by each project numbering 1..n with no gap."),
    round_amount = NA_real_,
    announcement_date = SC_LIST_POSTED,
    source_archive_path = file.path("data", "evidence", "SC",
                                    sc_source("award_list", "file")))
}

#' THE AWARDS ARE MADE, NOT INTENDED -- and that is measured, not assumed
#'
#' `validation_source_type = NOTICE_OF_AWARD` is §8's STRONGEST source type and
#' `amount_confirmed = Yes` is a stronger claim than this project usually gets
#' to make: Arkansas's and Wyoming's rows are intents, Maryland's are offers,
#' Oregon's and Alaska's are notices of intent. So the claim is checked against
#' the document rather than inferred from its title.
#'
#' The award list contains "intent" ZERO times, "anticipated" ZERO, "pending"
#' ZERO, "contingent" ZERO and "subject to" ZERO. It says "Awards" and nothing
#' conditional anywhere in eight pages. Behind it, SCDHHS published an
#' "Anticipated Notice of Award -- July 31, 2026" milestone, HIT THAT DATE
#' EXACTLY with bulletin MB# 26-026 ("SCDHHS issued Notices of Award
#' Determination"), and posted this list six weeks later.
#'
#' If any of that hedging language appears, the rows are intents and both
#' `validation_source_type` and `amount_confirmed` have to change.
sc_assert_awards_are_made <- function(path = sc_path("award_list")) {
  txt <- paste(rhtp_pdf_text(path), collapse = " ")
  for (tok in c("intent", "Intent", "anticipated", "Anticipated", "pending",
                "contingent", "subject to")) {
    if (grepl(tok, txt, fixed = TRUE)) {
      stop("[SC] the award list now contains '", tok, "'. These rows are ",
           "recorded as NOTICE_OF_AWARD with amount_confirmed = Yes -- §8's ",
           "strongest source type -- precisely because it carried NO ",
           "conditional language. Re-read it: if these are intents, they ",
           "code like Arkansas's and Wyoming's, not like Nebraska's.",
           call. = FALSE)
    }
  }
  if (!grepl("Year 1 Awards", txt, fixed = TRUE)) {
    stop("[SC] the award list no longer heads itself 'Year 1 Awards'.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Every recipient_type is reproducible from the NAME alone
#'
#' Arkansas's rule (session 40) and §0.3a's: a description describes an
#' ACTIVITY and §0.3a judges the RECIPIENT. South Carolina publishes no
#' description at all, so the only thing that could leak in is the PROJECT
#' name, and this asserts that it has not.
sc_assert_typed_from_the_name <- function(d = sc_parse_award_list(),
                                          aw = sc_year1_awardees(d)) {
  again <- rhtp_classify_recipient_type(aw$awardee, SC_STATE)
  if (!identical(again$recipient_type, aw$recipient_type)) {
    stop("[SC] a recipient_type in the award file is NOT reproducible from ",
         "the awardee name alone, so something other than the recipient has ",
         "decided it (§0.3a).", call. = FALSE)
  }
  # And the project name must not have reached the flow classifier either.
  bare <- rhtp_classify_flow(aw$recipient_type, rep("", nrow(aw)),
                             award_made = TRUE)
  if (!identical(bare$distributed_to_hospital, aw$distributed_to_hospital)) {
    stop("[SC] the flow coding is not reproducible from recipient identity ",
         "alone; an activity has decided a recipient's coding.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' NOTHING WAS PROMOTED, AND THE UNCERTAINTY RUNS ONE WAY ONLY
sc_assert_nothing_promoted <- function(aw = sc_year1_awardees()) {
  fb <- aw %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  if (!nrow(fb)) {
    stop("[SC] no row carries §8's standing fallback, which cannot be right ",
         "for a document that states no recipient form anywhere.",
         call. = FALSE)
  }
  if (any(fb$distributed_to_hospital != "No")) {
    stop("[SC] ", sum(fb$distributed_to_hospital != "No"), " row(s) on §8's ",
         "standing fallback are NOT 'No', so the uncertainty is no longer ",
         "one-directional and the report may not state a ceiling.",
         call. = FALSE)
  }
  # The names this file deliberately did not promote. If any of them stops
  # taking the fallback, the classifier has changed and the floor has moved.
  for (nm in c("Self Regional Healthcare (Lakelands Region)", "McLeod Health",
               "AnMed", "Tidelands Health", "Prisma Health-Upstate")) {
    hit <- aw[aw$awardee == nm, , drop = FALSE]
    if (!nrow(hit)) {
      stop("[SC] '", nm, "' is no longer in the award file.", call. = FALSE)
    }
    if (any(hit$flag_reason != "RECIPIENT_TYPE_INFERRED", na.rm = TRUE) ||
        any(is.na(hit$flag_reason))) {
      stop("[SC] '", nm, "' has stopped taking §8's standing fallback. If a ",
           "SOURCE now states its form, that is a promotion to make ",
           "deliberately; if the CLASSIFIER changed, South Carolina's floor ",
           "moved and the report must be re-read.", call. = FALSE)
    }
  }
  # And the refusal downward: SCDBHDD is the state's own department and is not
  # re-typed on this pipeline's recognition either.
  scdbhdd <- aw[grepl("^SCDBHDD", aw$awardee), , drop = FALSE]
  if (nrow(scdbhdd) != 19L ||
      any(scdbhdd$flag_reason != "RECIPIENT_TYPE_INFERRED")) {
    stop("[SC] the 19 SCDBHDD rows are no longer all on §8's standing ",
         "fallback. They are 'No' either way, so nothing moves -- but ",
         "re-typing them on recognition is the same §0.4 failure as ",
         "promoting a hospital on recognition, in the other direction.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The two MUSC spellings classify OPPOSITE ways, and that is asserted, not fixed
#'
#' North Carolina's UNC finding (session 38) in a state that PRICES its rows.
#' There the two spellings of one Hub Lead moved a coding at $0; here they move
#' $3,345,533.
#'
#' BOTH MACHINE ANSWERS ARE KEPT, and the reason is that unlike UNC these are
#' arguably two different legal bodies -- the hospital authority that operates
#' MUSC Health, and the university -- and no source in hand says otherwise.
#' Merging them either way would be this pipeline deciding a question of South
#' Carolina corporate structure on a name match, which is §2's prohibition and
#' §0.4's failure at once.
sc_assert_musc_two_spellings <- function(aw = sc_year1_awardees()) {
  auth <- aw[startsWith(aw$awardee, SC_MUSC_HOSPITAL_AUTHORITY), , drop = FALSE]
  uni  <- aw[aw$awardee == SC_MUSC_UNIVERSITY, , drop = FALSE]
  if (!nrow(auth) || !nrow(uni)) {
    stop("[SC] one of the two MUSC spellings has gone from the award list.",
         call. = FALSE)
  }
  if (!all(auth$recipient_type == "HOSPITAL_OR_SYSTEM") ||
      !all(auth$distributed_to_hospital == "Yes")) {
    stop("[SC] '", SC_MUSC_HOSPITAL_AUTHORITY, "' no longer classifies as a ",
         "hospital; South Carolina's floor has moved.", call. = FALSE)
  }
  if (!all(uni$recipient_type == "UNIVERSITY_OR_AHC") ||
      !all(uni$distributed_to_hospital == "No")) {
    stop("[SC] '", SC_MUSC_UNIVERSITY, "' no longer classifies as a ",
         "university; South Carolina's floor has moved.", call. = FALSE)
  }
  invisible(tibble::tibble(
    spelling = c(SC_MUSC_HOSPITAL_AUTHORITY, SC_MUSC_UNIVERSITY),
    rows = c(nrow(auth), nrow(uni)),
    dollars = c(sum(auth$amount), sum(uni$amount)),
    distributed_to_hospital = c("Yes", "No")))
}


# ============================================================================
# THE UNSTATED-FORM QUESTION -- FLAGGED IN SOUTH CAROLINA'S OWN FILES ONLY
# ============================================================================

SC_FORM_NOT_STATED_QUESTION <- "SC_RECIPIENT_FORM_NOT_STATED"

#' The unstated-form rows are flagged HERE, and deliberately not queued yet
#'
#' Every other state that met this condition appended a row to
#' `data/reference/classification_review_queue.csv` in the same session. South
#' Carolina does NOT, by instruction: a verification pass is in progress in a
#' separate workbook, and adding rows to the shared queue underneath it would
#' put two hands on one file. So the question is recorded where it belongs
#' anyway -- on the rows themselves, in `flag_reason`, and as a line of
#' `sc_year1_status.csv` carrying its size -- and a later session moves it into
#' the queue.
#'
#' THIS ASSERTION IS WHAT STOPS THAT DEFERRAL BECOMING A LOSS. It requires the
#' flag to be present on the rows, the count and the dollars to be recorded in
#' South Carolina's own status table, and the uncertainty to still exceed the
#' floor -- which is the sentence the report publishes about this state.
sc_assert_form_not_stated_flagged <- function(aw = sc_year1_awardees(),
                                              st = sc_status_table()) {
  fb <- aw %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  if (!nrow(fb)) {
    stop("[SC] no row carries the unstated-form flag.", call. = FALSE)
  }
  row <- st[st$channel == SC_FORM_NOT_STATED_QUESTION, , drop = FALSE]
  if (nrow(row) != 1L) {
    stop("[SC] the unstated-form question is not recorded in ",
         "sc_year1_status.csv. It is deliberately NOT in the shared review ",
         "queue this session, so this row is the only place it exists -- ",
         "losing it loses the largest open question about this state.",
         call. = FALSE)
  }
  if (!grepl(format(nrow(fb), big.mark = ","), row$note[[1]], fixed = TRUE)) {
    stop("[SC] sc_year1_status.csv records a different count of ",
         "unstated-form rows than the award file carries (", nrow(fb), ").",
         call. = FALSE)
  }
  named <- sum(aw$amount[aw$distributed_to_hospital == "Yes"])
  if (sum(fb$amount) <= named) {
    stop("[SC] the unstated-form dollars ($",
         formatC(sum(fb$amount), format = "f", digits = 2, big.mark = ","),
         ") no longer exceed the named-hospital floor ($",
         formatC(named, format = "f", digits = 2, big.mark = ","),
         "). Re-word the finding before publishing it.", call. = FALSE)
  }
  invisible(TRUE)
}


# ============================================================================
# STATUS AND DISPOSITION
# ============================================================================

#' What each South Carolina RHTP channel publishes
#'
#' IT HAS NO `amount` COLUMN, AND AN ASSERTION IN `sc_build()` REFUSES ONE.
#' The per-recipient money lives in `sc_year1_awardees.csv`; a status table
#' that acquired an amount column would be two files claiming one figure
#' (Texas's device, session 19).
sc_status_table <- function() {
  fb_rows <- sum(sc_year1_awardees()$flag_reason == "RECIPIENT_TYPE_INFERRED",
                 na.rm = TRUE)
  fb_dollars <- sum(sc_year1_awardees()$amount[
    which(sc_year1_awardees()$flag_reason == "RECIPIENT_TYPE_INFERRED")])

  tibble::tribble(
    ~channel, ~stage, ~publishes_roster, ~named_recipients, ~note,

    "Connections to Care", "AWARDED_ROSTER_PUBLISHED", "Yes", 62L,
    paste("Two projects -- Expand Remote Patient Monitoring (RPM) &",
          "Assistive Technology (21) and Modernize Health IT Infrastructure",
          "(41). Named and priced per row in the SC RHTP Year 1 Award List."),

    "Leveling Up", "AWARDED_ROSTER_PUBLISHED", "Yes", 8L,
    "One project -- Chronic Disease Program Expansion (8).",

    "Wellness Within Reach", "AWARDED_ROSTER_PUBLISHED", "Yes", 54L,
    paste("Two projects -- Expanding Community Care Sites (36) and Mobile",
          "Crisis Response (18)."),

    "Shoring Up to Sustainability", "AWARDED_ROSTER_PUBLISHED", "Yes", 104L,
    paste("Three projects -- Facility Enhancements (90), Healthcare Workforce",
          "(12) and Masterclass Training Series (2). The largest of the four",
          "initiatives and where most of the hospital money is."),

    "Tech Catalyst Fund", "NOT_YET_OPENED", "No", 0L,
    paste("THE FIFTH INITIATIVE, AND THE REASON THIS YEAR IS PARTIAL. SCDHHS:",
          "'Funding opportunities for the fifth of South Carolina's RHTP",
          "initiatives, the Tech Catalyst Fund, will be announced through a",
          "future stage of SCDHHS' RHTP implementation.' Administered through",
          "the South Carolina Research Authority -- §7's designated",
          "pass-through route (Illinois/ICAHN's precedent) -- which has named",
          "nobody. $32,730,351 of the allotment is in no public roster."),

    "MB# 26-026 (Notices of Award Determination)", "SUPERSEDED", "No", 0L,
    paste("THE SHAPE SOUTH CAROLINA WAS FAMOUS FOR HERE, AND IT IS OVER.",
          "SCDHHS hit its own published 'Anticipated Notice of Award --",
          "July 31, 2026' exactly and told recipients BY EMAIL:",
          "'Applicants should check their email'. It published a count of 712",
          "APPLICATIONS and nothing else -- not a roster, not amounts, not",
          "even a count of awards -- which is why session 43 recorded South",
          "Carolina as INVESTIGATED_NO_PROBE rather than as a negative. The",
          "award list of 2026-09-15 supersedes it."),

    "Rural & Medically Underserved Area Grant", "AWARDED_BUT_NOT_RHTP", "Yes -- FOR A DIFFERENT PROGRAMME", 0L,
    paste("§0.1 NEGATIVE CONTROL, on the RHTP page itself. $48.2 million,",
          "awarded 2024-02-02, roster linked -- and TWENTY-THREE MONTHS",
          "before South Carolina's Notice of Award, so §6.2's date test",
          "disqualifies it without anyone reading it. It also serves as the",
          "POSITIVE control: SCDHHS demonstrably publishes named rosters when",
          "it has them."),

    "Behavioral Health Crisis Stabilization Services Grant", "AWARDED_BUT_NOT_RHTP", "Yes -- FOR A DIFFERENT PROGRAMME", 0L,
    paste("THE SHARPEST §0.1 TRAP THIS STATE HAS, and the only one carrying",
          "hospital money: ~$35,000,000 'to hospitals across the state',",
          "a named roster of THIRTEEN SOUTH CAROLINA HOSPITALS, linked from",
          "the RHTP page. Awarded 2023-06-23, THIRTY MONTHS before the Notice",
          "of Award. California's SRHRP trap (session 34) in duplicate."),

    SC_FORM_NOT_STATED_QUESTION, "OPEN_QUESTION", "n/a", 0L,
    paste0("THE UNSTATED-FORM QUESTION A THIRTEENTH TIME AND THE SECOND ",
           "LARGEST IN DOLLARS. ", format(fb_rows, big.mark = ","),
           " of 228 rows -- $",
           formatC(fb_dollars, format = "f", digits = 2, big.mark = ","),
           " -- carry §8's standing fallback, because the award list has ",
           "three columns and states no recipient's organisational form. ",
           "ONE-DIRECTIONAL: every one is already distributed_to_hospital = ",
           "No, so resolving any can only RAISE South Carolina's hospital ",
           "figure. NOTHING WAS PROMOTED (§0.4): Self Regional Healthcare, ",
           "McLeod Health, AnMed, Prisma Health and Tidelands Health read as ",
           "hospital systems to anyone who knows South Carolina and are not ",
           "promoted; the nineteen SCDBHDD rows are the state's own ",
           "behavioral health department and are not demoted. DELIBERATELY ",
           "NOT IN data/reference/classification_review_queue.csv THIS ",
           "SESSION -- a verification pass is in progress in a separate ",
           "workbook and a later session moves it there. || SESSION 50 TYPED ",
           "147 OF THE 150 DIRECTLY (R/03aq_unstated_form_typing.R), under ",
           "session 49's three policies and with basis_type on every row: 58 ",
           "rows / $59,253,577.18 moved INTO NAMED_HOSPITAL and none moved ",
           "out, taking South Carolina from 55 rows / $56,587,137.77 to 113 / ",
           "$115,840,714.95. THIS SENTENCE AND THE COUNTS ABOVE DESCRIBE THE ",
           "BUILDER'S OUTPUT, WHICH IS WHAT THE AWARD LIST ALONE SUPPORTS; ",
           "the typing is an OVERLAY applied after the build, so the ",
           "committed sc_year1_awardees.csv carries 3 flagged rows and not ",
           "150. The three that remain are Community Initiatives Inc. (2 ",
           "rows) and Graceful Health Solutions, LLC (1), $749,320 between ",
           "them, whose form no reachable source states.")
  )
}

#' Why each of RCJ's South Carolina Tier 3 candidates is, or is not, an award
sc_disposition <- function() {
  n <- sc_rcj_candidate_count()
  tibble::tibble(
    state = SC_STATE,
    disposition = "NO_RCJ_TIER3_CANDIDATES",
    rcj_candidates = n,
    note = paste0(
      "South Carolina carries ", n, " RCJ Tier 3 candidates -- against 33 RCJ ",
      "records in total, all SOLICITATION, STATE_ALLOTMENT or UNASSIGNED -- ",
      "while publishing 228 named, priced award actions worth ",
      "$167,299,900.69. A ZERO HERE IS A FACT ABOUT THE DISCOVERY LAYER AND ",
      "NEVER ABOUT THE STATE (§0.1). Florida, North Carolina, Arkansas and ",
      "Wyoming are the standing proofs and South Carolina is the fifth, at ",
      "$167.3M the third largest of the five in dollars after Florida's ",
      "$188.2M and Wyoming's $173.9M. IT IS NOT QUITE THEIR SHAPE, THOUGH, ",
      "AND THE DIFFERENCE IS WORTH KEEPING: those four were invisible to ",
      "BOTH discovery layers (trigger_source = NEITHER), while South Carolina ",
      "is invisible to RCJ alone and reached the trigger list through CMS's ",
      "newsroom on 2026-09-17 -- two days AFTER SCDHHS had already posted the ",
      "roster, so the trigger followed the publication rather than finding ",
      "it."),
    source_url = sc_source("award_list", "url"))
}

#' The candidate count, re-derived from the committed record table every run
sc_rcj_candidate_count <- function() {
  path <- rhtp_path("interim", "stage2_record_table.rds")
  if (!file.exists(path)) {
    stop("[SC] the committed record table is missing, so the RCJ candidate ",
         "count cannot be DERIVED. It is never typed: a zero that was ",
         "asserted rather than measured is exactly the §0.1 claim this ",
         "disposition exists to avoid.", call. = FALSE)
  }
  rec <- readRDS(path)
  for (col in c("state", "award_tier")) {
    if (!col %in% names(rec)) {
      stop("[SC] the record table has no '", col, "' column, so the ",
           "candidate count cannot be derived. A missing column must NOT ",
           "return 0 -- that reads as 'RCJ carries nothing for South ",
           "Carolina' when it means 'we did not look'.", call. = FALSE)
    }
  }
  sum(rec$state == SC_STATE & rec$award_tier == "SUBAWARD", na.rm = TRUE)
}


# ============================================================================
# PROBE / VALIDATE / BUILD / REPORT
# ============================================================================

#' A probe READS (§2.2)
#'
#' It fetches into memory, compares a CONTENT digest, and runs the tripwires
#' against the LIVE bytes -- never the archive, which is session 25's Indiana
#' lesson and session 46's Texas one. It writes nothing, and
#' `rhtp_probe_run()` enforces that.
#'
#' WHAT IT IS WATCHING FOR, IN ORDER OF LIKELIHOOD:
#'   - THE TECH CATALYST FUND, South Carolina's fifth initiative and
#'     $32,730,351 of unawarded allotment, administered through the South
#'     Carolina Research Authority. A second award list is the signal.
#'   - A CORRECTED award list. South Carolina prints one row number as "I2"
#'     and spells one organisation three ways; a re-post that tidies either
#'     fails `sc_assert_row_numbering()` or `sc_assert_two_spellings()` on
#'     purpose, and the file is then re-read rather than patched.
#'   - THE CONTROLS MOVING. Both negatives live on the RHTP page, so a page
#'     rewrite that dropped them would leave this state's negative resting on
#'     nothing.
sc_probe <- function() {
  keys <- c("programme", "rmua_control", "bhcs_control")
  live <- purrr::map(keys, function(k) {
    r <- sc_get(sc_source(k, "url"), k); Sys.sleep(3); r
  })
  names(live) <- keys

  cmp <- purrr::map_dfr(keys, function(k) {
    tibble::tibble(
      key = k,
      archived_content = sc_content_digest(k),
      live_content = sc_content_digest(k, live[[k]]),
      archived_file = digest::digest(file = sc_path(k), algo = "sha256"),
      live_file = digest::digest(live[[k]], algo = "sha256",
                                 serialize = FALSE))
  }) %>%
    dplyr::mutate(
      content_changed = .data$archived_content != .data$live_content,
      file_changed = .data$archived_file != .data$live_file)

  # The award list itself is checked by DIGEST rather than re-parsed: a probe
  # must not write, and parsing a live PDF would mean holding 194KB of it in
  # memory to answer a question the digest answers.
  live_pdf <- sc_get(sc_source("award_list", "url"), "award_list")
  pdf_changed <- digest::digest(live_pdf, algo = "sha256", serialize = FALSE) !=
    digest::digest(file = sc_path("award_list"), algo = "sha256")
  cmp <- dplyr::bind_rows(cmp, tibble::tibble(
    key = "award_list", archived_content = NA_character_,
    live_content = NA_character_, archived_file = NA_character_,
    live_file = NA_character_, content_changed = pdf_changed,
    file_changed = pdf_changed))

  # The tripwires, against the LIVE bytes.
  sc_assert_award_index(body = live$programme)
  sc_assert_tech_catalyst_pending(body = live$programme)
  sc_assert_controls(bodies = live)

  # THE NAME TRIPWIRE (§2.3, session 48). The phrase assertions above ask HOW
  # this page is worded; this asks WHOM it names, against the committed
  # archive. New Mexico is why it exists: HCA named six Regional Hubs and not
  # one of its ten award phrases matched. Subject pages only -- a control or a
  # press index moves for reasons that are not this state awarding.
  nm_keys <- c("programme")
  rhtp_assert_no_new_organisations_across(
    live = stats::setNames(
      purrr::map(nm_keys, function(k) sc_html_text(k, live[[k]])), nm_keys),
    archived = stats::setNames(purrr::map(nm_keys, sc_html_text), nm_keys),
    state = "SC")

  message("[SC] live probe ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " UTC")
  purrr::walk(seq_len(nrow(cmp)), function(i) {
    r <- cmp[i, ]
    message(sprintf("  %-14s content %s   file %s", r$key,
                    if (isTRUE(r$content_changed)) "CHANGED" else "unchanged",
                    if (isTRUE(r$file_changed)) "differs" else "unchanged"))
  })
  if (any(cmp$content_changed)) {
    message("[SC] CHANGED on: ",
            paste(cmp$key[cmp$content_changed], collapse = ", "),
            ". Re-fetch and READ. If the award list itself moved, re-run ",
            "--validate before trusting any figure: South Carolina's row ",
            "numbering and its three spellings of Prisma Health are both ",
            "asserted, and both are things a re-post might tidy.")
  } else {
    message("[SC] UNCHANGED. Four initiatives of five, the Tech Catalyst Fund ",
            "still to come, and $32,730,351 still in no public roster.")
  }
  invisible(cmp)
}

sc_validate <- function() {
  if (!sc_have_archive()) {
    stop("[SC] the evidence archive is incomplete; run --fetch first.",
         call. = FALSE)
  }
  runs <- sc_runs()
  d <- sc_parse_award_list(runs)

  # The parse, and the two defect shapes looked for deliberately.
  sc_assert_row_numbering(d)
  sc_assert_no_positioning_space(runs)
  sc_assert_two_spellings(d)
  sc_assert_line_model_cannot_read_this(d = d)
  sc_assert_reconciles(d)
  sc_assert_rows_are_not_organisations(d)
  sc_assert_awards_are_made()

  # §6.2 and the controls.
  sc_assert_no_cms_footer()
  sc_assert_provenance()
  sc_assert_award_index()
  sc_assert_tech_catalyst_pending()
  sc_assert_controls()

  # §8 / §10.2.
  aw <- sc_year1_awardees(d)
  sc_assert_typed_from_the_name(d, aw)
  sc_assert_nothing_promoted(aw)
  sc_assert_musc_two_spellings(aw)
  sc_assert_form_not_stated_flagged(aw)

  message("[SC] all assertions pass.")
  invisible(TRUE)
}

sc_build <- function() {
  runs <- sc_runs()
  d <- sc_parse_award_list(runs)
  sc_assert_row_numbering(d)
  sc_assert_no_positioning_space(runs)
  sc_assert_two_spellings(d)
  sc_assert_reconciles(d)

  aw <- sc_year1_awardees(d)
  sc_assert_typed_from_the_name(d, aw)
  sc_assert_nothing_promoted(aw)
  readr::write_csv(aw, SC_AWARDEES_CSV)
  message("[SC] wrote ", SC_AWARDEES_CSV, " (", nrow(aw),
          " award actions, $",
          formatC(sum(aw$amount), format = "f", digits = 2, big.mark = ","),
          ")")

  st <- sc_status_table()
  if ("amount" %in% names(st)) {
    stop("[SC] sc_year1_status.csv must have NO amount column. The ",
         "per-recipient money lives in sc_year1_awardees.csv; a status table ",
         "that acquires an amount column is two files claiming one figure ",
         "(Texas's device).", call. = FALSE)
  }
  readr::write_csv(st, SC_STATUS_CSV)
  message("[SC] wrote ", SC_STATUS_CSV, " (", nrow(st), " rows)")

  dp <- sc_disposition()
  readr::write_csv(dp, SC_DISPO_CSV)
  message("[SC] wrote ", SC_DISPO_CSV, " (", nrow(dp), " rows)")

  sc_assert_form_not_stated_flagged(aw, st)
  invisible(list(awards = aw, status = st, disposition = dp))
}

sc_report <- function() {
  d    <- sc_year1_awardees()
  part <- rhtp_hospital_dollar_partition(d)
  fb   <- d %>% dplyr::filter(.data$flag_reason == "RECIPIENT_TYPE_INFERRED")
  floor_rows <- sum(d$distributed_to_hospital == "Yes")
  floor_d    <- sum(d$amount[d$distributed_to_hospital == "Yes"])
  ceil_rows  <- floor_rows + nrow(fb)
  ceil_d     <- floor_d + sum(fb$amount)
  allot <- sc_allotment()

  cat("\nSOUTH CAROLINA -- 228 AWARDS, NAMED AND PRICED\n")
  cat(strrep("=", 72), "\n\n")
  cat("Allotment (§7.1)          : $", format(allot, big.mark = ","), "\n",
      sep = "")
  cat("Awarded, 4 of 5 initiatives: $",
      formatC(sum(d$amount), format = "f", digits = 2, big.mark = ","),
      "  (", round(100 * sum(d$amount) / allot, 1), "% of allotment)\n",
      sep = "")
  cat("Award actions             : ", nrow(d),
      "   <- CMS independently states 228 grants\n", sep = "")
  cat("Distinct awardee strings  : ", dplyr::n_distinct(d$awardee),
      "   <- an UPPER BOUND on organisations, not a count of them\n", sep = "")
  cat("\n")
  print(as.data.frame(sc_reconcile()), row.names = FALSE)

  cat("\nROWS ARE NOT ORGANISATIONS, AND THE MARGIN IS LARGE:\n")
  print(utils::head(as.data.frame(sc_assert_rows_are_not_organisations()), 5),
        row.names = FALSE)

  cat("\nTHE TWO DEFECT SHAPES, LOOKED FOR DELIBERATELY:\n")
  cat("  (1) ROW NUMBER 'I2' -- Healthcare Workforce row 2 is printed with a\n")
  cat("      capital I. A parser keying on ^[0-9]+$ DROPS Rebound Behavioral\n")
  cat("      Health and $120,000. This file anchors rows on the AMOUNT\n")
  cat("      column, so it never depended on the number; the numbers are the\n")
  cat("      completeness check (1..n per project) instead.\n")
  cat("  (2) A HYPHEN WITH NO SPACES, painted as three runs. South Carolina\n")
  cat("      spells one organisation THREE ways -- 17 'Prisma Health-X',\n")
  cat("      1 'Prisma Health- Upstate (Anderson)', 1 'Prisma Health (Oconee)'\n")
  cat("      -- and the difference is a single space run. Mississippi's\n")
  cat("      LIFECORE row in a state with no county column: no dollar moves\n")
  cat("      and NO TOTAL NOTICES. Nothing is merged (§2).\n")
  cat("  (3) 33 ROWS WRAP their name over two lines with the number and the\n")
  cat("      amount painted at the MIDPOINT, so rhtp_pdf_lines() cannot\n")
  cat("      assemble them at all. Rows are built by Y-BAND.\n")

  cat("\nHOSPITAL DOLLARS\n")
  print(as.data.frame(part), row.names = FALSE)
  cat("\n  FLOOR    ", floor_rows, " rows / $",
      formatC(floor_d, format = "f", digits = 2, big.mark = ","),
      "  (", round(100 * floor_rows / nrow(d), 1), "% of rows, ",
      round(100 * floor_d / sum(d$amount), 1), "% of dollars)\n", sep = "")
  cat("  QUEUED   ", nrow(fb), " rows / $",
      formatC(sum(fb$amount), format = "f", digits = 2, big.mark = ","),
      "  on §8's standing fallback\n", sep = "")
  cat("  CEILING  ", ceil_rows, " rows / $",
      formatC(ceil_d, format = "f", digits = 2, big.mark = ","),
      "  (", round(100 * ceil_rows / nrow(d), 1), "% of rows, ",
      round(100 * ceil_d / sum(d$amount), 1), "% of dollars)\n", sep = "")
  cat("  The uncertainty is ONE-DIRECTIONAL -- every fallback row is already\n")
  cat("  No -- so the floor is genuine and so is the ceiling.\n")
  cat("  NOTHING WAS PROMOTED (§0.4). The CCN match resolves it.\n")

  cat("\nTHE YEAR IS PARTIAL, AND SOUTH CAROLINA SAYS SO:\n")
  cat("  The Tech Catalyst Fund is the fifth of five initiatives and has not\n")
  cat("  opened. $", formatC(allot - sum(d$amount), format = "f", digits = 0,
                             big.mark = ","),
      " of the allotment is in no public roster.\n", sep = "")
  cat("\n")
  print(as.data.frame(sc_status_table()[, c("channel", "stage",
                                            "named_recipients")]),
        row.names = FALSE)
  invisible(list(awards = d, partition = part,
                 floor = c(rows = floor_rows, dollars = floor_d),
                 ceiling = c(rows = ceil_rows, dollars = ceil_d)))
}


if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) sc_fetch(force = "--force" %in% args)
  if ("--validate" %in% args) sc_validate()
  if ("--build" %in% args) sc_build()
  if ("--probe" %in% args) rhtp_probe_run("SC", sc_probe())
  if ("--report" %in% args) sc_report()
  if (!length(args)) {
    message("Usage: --fetch [--force] | --validate | --build | --probe | --report")
  }
}

# 03u_nv_year1_awardees.R -----------------------------------------------------
# Nevada Year 1 -> data/reference/nv_year1_awardees.csv
#
# WHY NEVADA. It led `state_trigger_queue.csv` once Oklahoma was worked out --
# queue rank 1, 34 Tier 3 candidates on the 2026-08-27 pull (42 on 09-24), 34 distinct awardees, a $179,931,608
# allotment, no CMS press release.
#
# SESSION 64 -- RE-EXTRACTED FROM THE 2026-09-24 PAGE, AND GIVEN A PROBE.
# NVHA's Funded Projects page grew from 3 sections / 72 award actions
# (2026-08-31) to SEVEN sections / 155 (2026-09-24): Flex 25 -> 39, WRRAP
# Recruitment and Retention 27 -> 26, Apprenticeship and Training 20, Medical
# Residency 0 -> 4 NAMED, and three new rosters -- RHIT 24, RHOAP 36, Tribal 6.
# STILL NO AMOUNT ANYWHERE, so everything below about `amount` holds.
# The file is 156 rows: rows 1..72 are the 2026-08-31 page's rows IN THAT
# ORDER (session 49's overlay is keyed on row index -- see
# nv_ordered_awards()), row 48 ("93 X 95 NV") is on the old page and not the
# new one and is KEPT as Unclear, and rows 73..156 are the 84 new ones. The
# Rural Medical Residency AGGREGATE row ("Recipients not named by NVHA") is
# GONE: its claim was that nobody was named, and four now are. RHIT, RHOAP,
# Tribal and the 14 new Flex rows carry NO round total (NVHA has published
# none). Counts in the older prose below (73 rows, 20/23 hospitals, 23 on the
# fallback) describe the 2026-08-31 file and are kept as its history (§2.1).
#
# NEVADA IS A SHAPE THIS PROJECT HAS NOT MET: A COMPLETE, NAMED,
# RECIPIENT-LEVEL ROSTER WITH NO AMOUNTS ON IT AT ALL.
# The Nevada Health Authority publishes `RHTP/rht-funded-projects---bp1/`, a
# page headed "Transformational Investments Across Rural Nevada / Funded
# Projects by RHT Initiative", carrying three tables whose columns are
# Subrecipient, Project and County-Service Area. Seventy-two award actions,
# every recipient named, and NOT ONE DOLLAR FIGURE ANYWHERE ON THE PAGE.
#
# Every prior state in this repository sits somewhere on one axis: Kansas,
# Maryland, Nebraska and Oklahoma publish a recipient AND an amount and
# withhold the recipient's organisational FORM; South Dakota publishes an
# amount and a count and withholds the RECIPIENTS. Nevada withholds the
# AMOUNTS and publishes everything else. So:
#
#   * `amount` is EMPTY ON ALL 73 ROWS and `sum(amount)` is 0. That is not a
#     parse failure and it is not a claim that Nevada awarded nothing -- it is
#     the honest total of what Nevada has published PER RECIPIENT, which is
#     nothing. The pool totals live in `round_amount` (see below).
#   * NEVADA HAS 23 NAMED-HOSPITAL AWARD ACTIONS AND $0 OF NAMED-HOSPITAL
#     DOLLARS, and those two facts are both true at once.
#     `rhtp_hospital_dollar_partition()` sums with na.rm = TRUE, so it reports
#     Nevada as `NAMED_HOSPITAL rows = 23, dollars = 0`. READ THE ROW COUNT.
#     A reader who takes the 0 and not the 23 will conclude Nevada gave its
#     rural hospitals nothing, which is the exact opposite of what NVHA has
#     published, and it is the single most dangerous misreading this file can
#     produce. `nv_assert_zero_dollars_is_not_zero_hospitals()` exists to make
#     that impossible to do quietly.
#
# WHAT NEVADA PUBLISHES, AND WHERE.
#
#   POOL                                        ROWS   ROUND TOTAL   ROSTER
#   Rural Health System Flex Fund                 25   $36,000,000   published
#   WRRAP - Recruitment and Retention Fund        27   $32,300,000   published
#   WRRAP - Apprenticeship and Training Fund      20   $14,300,000   published
#   WRRAP - Rural Medical Residency                1   $ 4,800,000   NAMES NOBODY
#                                                 --   -----------
#                                                  73   $87,400,000
#
# The Flex Fund total is NVHA's 2026-06-09 press release ("announced $36
# million in Rural Health Transformation funding awards"), which links to the
# roster page by name -- "Review all RHT Funded Projects here" -- so the round
# total and the 25 names are tied together by the state itself rather than by
# this file. The three WRRAP figures are NVHA's 2026-07-29 press release. The
# Rural Medical Residency row is ONE AGGREGATE ROW: NVHA states "$4.8 million
# in rural medical residency investments" and describes four projects while
# NAMING NO RECIPIENT, so it carries an empty `amount`, its total in
# `round_amount`, `NOT_YET_NAMED` and `RECIPIENT_NOT_NAMED` -- South Dakota's
# device (§0.3: a description is not a list).
#
# `round_amount` REPEATS THE POOL TOTAL ON EVERY ROW OF ITS POOL, which is
# Georgia's `initiative_amount` device and carries Georgia's trap with it:
# summing `round_amount` down the column gives $2,062,900,000 for a state that
# announced $87,400,000. `nv_reconcile()` sums DISTINCT (award_pool,
# round_amount) pairs, an assertion hard-fails the wrong total, and a test pins
# the trap open.
#
# TWO OF NVHA'S OWN DOCUMENTS DISAGREE ABOUT WHICH WRRAP FUND GOT WHICH TOTAL,
# AND IT IS NOT RESOLVED HERE. The 2026-06-09 fiscal deck prints "$14,394,529
# available" against Recruitment and Retention and "$32,387,689 available"
# against Apprenticeship and Training; the 2026-07-29 press release announces
# $32.3M for recruitment and retention and $14.3M for apprenticeship and
# training. THE PAIRING IN THE DECK WAS CHECKED AGAINST THE PDF's OWN GLYPH
# POSITIONS rather than the reader's line order -- each pool's label sits
# 45-50pt right of its own bullet block across all four columns -- so this is
# the source disagreeing with itself and not a parse artifact.
#
# The two most likely readings both exist and neither is published as a
# finding: NVHA may have REALLOCATED between the two sub-funds while
# "negotiating final awards" (the deck's own words), which the totals support
# almost exactly -- $46,782,218 available against $46.6M awarded -- or one
# document may have swapped its labels. `round_amount` takes the PRESS
# RELEASE's figure, because §8's source-strength ordering makes an award
# announcement the better authority on what was AWARDED than a pre-award
# planning deck is; both rosters carry
# `POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES` so no reader meets one figure without
# the other. THE COMBINED WRRAP FIGURE IS STABLE UNDER THE CONFLICT
# ($46.6M either way), and that is what `nv_report()` leads with.
#
# THE §6.2 PROVENANCE TEST PASSES IN THE STRONGEST FORM THIS PROJECT HAS SEEN,
# BECAUSE NEVADA PUBLISHES THE FEDERAL NOTICE OF AWARD ITSELF. Oklahoma's
# footer was the awarding agency's figure quoted on the roster; Nevada's is the
# award document. `noa_rhtcms332074-01-02.pdf` is CMS's own Notice of Award
# form: recipient "Nevada Health Authority", award number RHTCMS332074-01-02,
# Assistance Listing 93.798 "Rural Health Transformation Program", budget
# period 12/29/2025 - 10/30/2026, $179,931,608.42, and the remark "This Notice
# of Award approves the revised budget and lifting of restriction in the amount
# of $179,931,608.42 per your request dated 1/29/2026." That figure rounds to
# `cms_fy2026_allotments.csv`'s $179,931,608 to the dollar and its date is
# `cms_state_noa_dates.csv`'s 2025-12-29 anchor exactly. NVHA restates both
# independently on its own pages -- "December 29, 2025: Received Notice of
# Award ($179,931,608)". The DATE test passes on every pool: the four awarded
# RFAs closed 4/30/26 and 5/15/26 and 6/26/26, all four to six months AFTER
# the state had the money.
#
# AND THE FOOTER IS NOT ENOUGH ON ITS OWN -- NEVADA IS WHERE THAT BREAKS.
# See NV_GME_* below. This is the session's §6.2 lesson and it is new.
#
# §0.1 -- RCJ'S 34 CANDIDATES CONTAIN $15,755,068 OF STATE GENERAL FUND MONEY
# UNDER AN RHTP HEADING, AND THE STATE SAYS SO IN A COMPARISON TABLE.
# See NV_GME_* and `nv_rcj_candidate_disposition.csv`.
#
# THE POSITIVE CONTROL. "Nevada has published no roster for its other
# initiatives" is a finding only because NVHA demonstrably publishes rosters in
# a recognisable form: one accordion section per awarded pool on the Funded
# Projects page, each with a Subrecipient/Project/Service-Area table. NVHA is
# running TEN funding opportunities and has published rosters for THREE.
# `nv_assert_award_index()` asserts exactly those three sections present and
# REFUSES A FOURTH; `nv_assert_pending_not_awarded()` names the six closed
# opportunities with no roster and IS DESIGNED TO FAIL the day one appears.
#
# THE HOSPITAL FIGURE IS A COUNT, NOT A FLOOR, AND ITS UNCERTAINTY IS THE SAME
# SHAPE AS THE LAST FOUR STATES'. NVHA publishes no organisation-type column,
# so all 73 rows are typed from the recipient's own NAME: 23 award actions
# resolve to hospitals and 23 more carry §8's standing fallback
# (`NONPROFIT_CBO` + LOW + RECIPIENT_TYPE_INFERRED). Renown Health, Carson
# Valley Health, Washoe Barton Medical Clinic DBA Carson Valley Health and
# Intermountain Health are all inside that 23 and all uncounted. NOTHING WAS
# PROMOTED (§0.4); queued as `NV_RECIPIENT_FORM_NOT_STATED`. Because no row
# carries an amount, the queue row is worth $0 in either direction -- it moves
# a COUNT, which is the only hospital quantity Nevada supports.
#
# NEVADA IS THE FIRST STATE TO COMMIT A ROW CARRYING
# `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`. Session 19 added that code for the
# branch its flow fix opened and recorded that zero committed rows carried it.
# Incline Village Community Hospital Foundation is one: a hospital's own
# foundation, awarded to recruit providers, with the source silent on whether
# the money reaches the hospital. Coding it `No` would deflate on this
# pipeline's authority and coding it `Yes` is the short-circuit session 19
# removed, so it is `PASS_THROUGH_UNRESOLVED` + `Unclear` and enters NEITHER
# bucket of the partition.
#
# WHAT THIS FILE DELIBERATELY DOES NOT CONTAIN.
#   * The nine GME Grant Round VIII awards. They are STATE GENERAL FUND money
#     (see NV_GME_* below) and unioning them here is what §6.2 exists to stop.
#   * Nevada's initiative percentages (RHOAP 15%, Flex 20%, WRRAP 40%, RHIT
#     15%). They are Tier 2 and, being percentages of an annual award rather
#     than dollars, are a §7A artifact and not an award figure.
#   * Any per-recipient amount. NVHA has published none and this file invents
#     none (§6.2: the round total is never divided).

suppressPackageStartupMessages({
  library(dplyr)
  library(rlang)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))
source(here::here("R", "utils_page_watch.R"))

NV_STATE <- "NV"
NV_EVIDENCE_DIR <- here::here("data", "evidence", "NV")
NV_OUT_CSV <- here::here("data", "reference", "nv_year1_awardees.csv")
NV_DISPOSITION_CSV <- here::here("data", "reference",
                                 "nv_rcj_candidate_disposition.csv")
NV_XLSX <- here::here("NV_year1_awardees.xlsx")

NV_USER_AGENT <- paste(
  "RHTP-Tracker/1.0 (AHA Data & Policy research;",
  "+https://www.aha.org)")
NV_HOST_THROTTLE_S <- 2

# §7.1 / sessions 14, 16, 17, 20: never archive a third party's credential.
NV_CREDENTIAL_SHAPES <- c(
  mapbox_token   = "[ps]k\\.ey[A-Za-z0-9._-]{20,}",
  google_api_key = "AIza[0-9A-Za-z_-]{30,}",
  generic_apikey = "(?i)api[_-]?key\\s*[:=]\\s*[\"'][A-Za-z0-9._-]{16,}[\"']",
  bearer_token   = "(?i)bearer\\s+[A-Za-z0-9._-]{25,}",
  aws_key        = "AKIA[A-Z0-9]{12,}"
)

# -- what the STATE states, so a change in the source fails rather than passes -

# CMS's own Notice of Award, and NVHA's restatement of it. Compared to the §7.1
# anchor rather than typed as a claim about CMS.
NV_CMS_AWARD_AMOUNT <- 179931608.42
NV_CMS_AWARD_NUMBER <- "RHTCMS332074-01-02"
NV_ASSISTANCE_LISTING <- "93.798"
NV_NOA_DATE <- as.Date("2025-12-29")

# The SEVEN pools on NVHA's Funded Projects page as archived 2026-09-24, in
# page order, with the section heading the page prints for each, the round
# total NVHA has PUBLISHED for it (NA where it has published none) and the
# number of award actions the 2026-09-24 page lists under it.
#
# SESSION 64 RE-EXTRACTED NEVADA. The 2026-08-31 page carried three sections
# and 72 award actions; the 2026-09-24 page carries SEVEN sections and 155,
# still with NO AMOUNT against anybody. RHIT and RHOAP (decisions due 8/10 and
# 8/14) and the Tribal RFA have published rosters, the Medical Residency pool
# now NAMES its four recipients, the Flex Fund grew 25 -> 39, and ONE
# Recruitment and Retention row ("93 X 95 NV") is no longer on the page.
# NVHA has published NO round total for RHIT, RHOAP, Tribal, or for the 14
# Flex rows first listed after 2026-08-31, so those carry `round_amount = NA`
# -- a figure nobody published is not filled in, and a Tier 2 "available" or
# "cap" figure is not an award total (§0.2).
NV_POOLS <- tibble::tribble(
  ~award_pool,                      ~round_id,  ~section,                                                                          ~round_name,                                                                                    ~round_amount, ~round_awards, ~roster, ~amount_source,
  "FLEX_FUND",                      "FLEX",     "Rural Health System Flex Fund",                                                   "Rural Health System Flex Fund",                                                                36000000,  39L, TRUE, "press_flex",
  "WRRAP_RECRUITMENT_RETENTION",    "WRRAP-RR", "Workforce Recruitment and Rural Access Program - Recruitment and Retention Fund", "Workforce Recruitment and Rural Access Program - Recruitment and Retention Fund",            32300000,  26L, TRUE, "press_wrrap",
  "WRRAP_APPRENTICESHIP_TRAINING",  "WRRAP-AT", "Workforce Recruitment and Rural Access Program - Apprenticeship and Training Fund", "Workforce Recruitment and Rural Access Program - Apprenticeship and Training Fund",       14300000,  20L, TRUE, "press_wrrap",
  "WRRAP_RURAL_MEDICAL_RESIDENCY",  "WRRAP-RES","Workforce Recruitment and Rural Access Program - Medical Residency Program",       "Workforce Recruitment and Rural Access Program - Rural Medical Residency",                      4800000,   4L, TRUE, "press_wrrap",
  "RHIT",                           "RHIT",     "Rural Health Innovation and Technology Fund",                                     "Nevada Rural Health Innovation and Technology (RHIT) Initiative",                              NA_real_, 24L, TRUE, NA_character_,
  "RHOAP",                          "RHOAP",    "Rural Health Outcomes Accelerator Program",                                       "Nevada Rural Health Outcomes Accelerator Program (RHOAP)",                                     NA_real_, 36L, TRUE, NA_character_,
  "TRIBAL",                         "TRIBAL",   "Tribal",                                                                          "Nevada Rural Tribal Health System Transformation Program",                                     NA_real_,  6L, TRUE, NA_character_
)

# The Flex Fund's $36 million is NVHA's 2026-06-09 "First Round" release. The
# 25 Flex rows on the 2026-08-31 page are that round; the 14 first listed on
# the 2026-09-24 page carry NO published round total, so they get their own
# round id and an NA `round_amount` rather than a figure they may not be in.
NV_FLEX_ADDED_ROUND <- list(
  round_id = "FLEX-ADDED",
  round_name = paste0("Rural Health System Flex Fund -- rows first listed on ",
                      "NVHA's page after 2026-08-31 (no round total published)"))

NV_STATED <- list(
  flex_round_total      = 36000000,      # 2026-06-09 release: "$36 million"
  wrrap_rr_awarded      = 32300000,      # 2026-07-29 release
  wrrap_at_awarded      = 14300000,      # 2026-07-29 release
  wrrap_residency       = 4800000,       # 2026-07-29 release
  announced_total       = 87400000,      # the four PUBLISHED round totals, over DISTINCT rounds
  # Award actions on the 2026-09-24 page, per section.
  flex_rows             = 39L,
  flex_rows_first_round = 25L,           # the 2026-08-31 page's Flex rows
  wrrap_rr_rows         = 26L,
  wrrap_at_rows         = 20L,
  residency_rows        = 4L,
  rhit_rows             = 24L,
  rhoap_rows            = 36L,
  tribal_rows           = 6L,
  roster_rows           = 155L,          # named award actions on the current page
  prior_roster_rows     = 72L,           # ... and on the 2026-08-31 page
  withdrawn_rows        = 1L,            # on 08-31, not on 09-24: "93 X 95 NV"
  total_rows            = 156L,          # 155 current + 1 withdrawn, KEPT
  # The 2026-06-09 fiscal deck's "available" figures. Kept because they are the
  # other half of the conflict this file refuses to resolve.
  deck_flex_available   = 35986322,
  deck_rr_available     = 14394529,
  deck_at_available     = 32387689,
  deck_tribal_available = 8096922,
  deck_rr_requested     = 33621591,
  deck_at_requested     = 44305961,
  press_rr_requested    = 41900000,      # "with $41.9 million requested"
  # RCJ, pinned against the record table on every run. 34 / 34 on the
  # 2026-08-27 pull; the 2026-09-24 pull adds eight (session 63).
  rcj_candidates        = 42L,
  rcj_distinct_awardees = 42L
)

# The one row the 2026-08-31 page carried and the 2026-09-24 page does not. It
# is KEPT (row 48 of the file, in its original place), because the state
# published it and a disappearance is a fact to record rather than a row to
# delete (§0.4); the session-49 verification of it returned UNKNOWN and is
# queued as NV_UNIDENTIFIED_RECIPIENT.
NV_WITHDRAWN_AWARDEES <- c("93 X 95 NV")

# THE COMBINED WRRAP FIGURE IS STABLE UNDER THE CONFLICT, and this is the
# arithmetic that says so.
NV_WRRAP_COMBINED_PRESS <- NV_STATED$wrrap_rr_awarded + NV_STATED$wrrap_at_awarded
NV_WRRAP_COMBINED_DECK  <- NV_STATED$deck_rr_available + NV_STATED$deck_at_available

# -- the GME negative control -------------------------------------------------
#
# NEVADA'S §6.2 LESSON, AND IT IS NEW: THE CMS FOOTER COVERS THE PUBLICATION,
# NOT EVERY PROGRAMME DESCRIBED IN IT.
#
# `nvha-healthcare-workforce-programs-remediated-doc-2-1.pdf` ("Working
# Together to Power Nevada's Health Workforce", April 2026) carries the CMS
# financial-assistance footer -- "$179,931,608.42 with 100% funded by CMS/HHS"
# -- on EVERY PAGE, because NVHA produced the publication with RHTP money. The
# publication then describes THREE SEPARATE WORKFORCE PROGRAMMES SIDE BY SIDE,
# in a table whose own column is headed "Funding", and says in that table which
# money each one runs on:
#
#   GME Program    "Source: State General Fund"   $15.8M available in SFY26
#                  Governance: NRS 223.631-639, SB262 & SB494 (2025)
#   WRRAP          "Source: Centers for Medicare & Medicaid Services (CMS)
#                   Rural Health Transformation (RHT) Grant #RHTCMS332074-01-02"
#   SHARP          "Source: SB5 one-time bill appropriation"   $60M, from 7/1/26
#
# ONLY WRRAP IS RHTP. A provenance check keyed on "does this document carry the
# CMS financial-assistance footer" answers YES for all three and is wrong for
# two of them. Oklahoma's footer was on a roster and covered what was on it;
# Nevada's is on a comparison document and covers only the publishing.
#
# The consequence is measured, not hypothetical. NVHA announced GME Grant Round
# VIII on 2026-07-22 -- "Nevada Invests Nearly $16 Million to Train the Next
# Generation of Physicians", nine programmes, "$15,755,068.00", the Director's
# own words "these new state investments", no CMS or RHTP mention anywhere in
# it -- and SEVENTEEN of RCJ's 34 Nevada Tier 3 candidates are those nine
# awards. Seven days later NVHA announced $4.8M of RHTP **Rural Medical
# Residency** money under WRRAP. Two residency-shaped announcements, one
# agency, eight days apart, one federal and one state.
NV_GME_ROUND <- "GME Grant Program Round VIII"
NV_GME_TOTAL <- 15755068.00
NV_GME_PROGRAMMES <- 9L
NV_GME_ANNOUNCED <- as.Date("2026-07-22")
NV_GME_SOURCE_QUOTE <- "Source: State General Fund"
NV_GME_STATE_QUOTE <- "these new state investments"
NV_GME_GOVERNANCE <- c("NRS 223.631-639", "SB262 & SB494")
# The nine, exactly as NVHA publishes them, with the amounts from its own
# release. They are here to be EXCLUDED and asserted absent -- never extracted.
NV_GME_AWARDS <- tibble::tribble(
  ~awardee,                                                                  ~amount,
  "Carson-Tahoe Health - Family Medicine",                                   2707094,
  "Dignity Health - Internal Medicine",                                      1722415,
  "Dignity Health - Pulmonary & Critical Care Medicine",                     1279352,
  "University Medical Center of Southern Nevada - Diagnostic Radiology",     2100000,
  "University of Nevada, Las Vegas SOM - Ophthalmology",                     2995890,
  "University of Nevada, Las Vegas SOM - Otolaryngology",                     401397,
  "University of Nevada, Reno SOM - General Surgery",                        1672444,
  "University of Nevada, Reno SOM - Obstetrics & Gynecology",                1957173,
  "University of Nevada, Reno SOM - Pulmonary Disease and Critical Care Medicine", 919303
)

# The closed opportunities with NO published roster. Each is a tripwire.
# SESSION 64: THREE OF SESSION 26's SIX HAVE AWARDED -- RHIT, RHOAP and the
# Rural Tribal Health RFA now have sections on the Funded Projects page -- and
# are recorded in NV_AWARDED_SINCE_0831 rather than deleted, so the history of
# what was pending stays readable. These three are still pending: none has a
# section on the 2026-09-24 page.
NV_PENDING_OPPORTUNITIES <- c(
  "Rural Presidential Fitness Test Implementation",
  "Rural Correctional Health Transformation",
  "Rural Veterans Health Transformation"
)
# The page-section pattern each pending opportunity would carry if awarded.
# NOT a bare "correction": the RHIT roster names the Nevada Department of
# Corrections as a subrecipient, and that is a recipient, not a section.
NV_PENDING_SECTION_PATTERN <- "(?i)presidential fitness|correctional health|veterans? health"

# Pending on 2026-08-31 (session 26), awarded by 2026-09-24: the NOFO page's
# name for each, and the Funded Projects section that now carries its roster.
NV_AWARDED_SINCE_0831 <- tibble::tribble(
  ~opportunity,                                                          ~section,
  "Nevada Rural Health Innovation and Technology (RHIT) Initiative",     "Rural Health Innovation and Technology Fund",
  "Nevada's Rural Health Outcome Accelerator Program (RHOAP)",           "Rural Health Outcomes Accelerator Program",
  "Nevada Rural Tribal Health System Transformation Program",            "Tribal"
)

# The SEVEN roster sections NVHA publishes, in page order. An EIGHTH means
# Nevada has awarded something this file does not carry.
NV_ROSTER_SECTIONS <- NV_POOLS$section

# The three sections the 2026-08-31 page carried -- what rows 1..72 of the file
# were parsed from, and what session 49's row-indexed overlay is keyed on.
NV_PRIOR_ROSTER_SECTIONS <- NV_POOLS$section[1:3]


# -- sources ------------------------------------------------------------------

NV_BASE <- "https://www.nvha.nv.gov"

NV_SOURCES <- tibble::tribble(
  ~key, ~file, ~url,
  # THE ROSTER, AS OF 2026-09-24. Seven tables, 155 named subrecipients, no
  # amounts. First archived by session 63 into data/evidence/recheck/ (curl,
  # one read-only fetch) and copied here byte for byte by session 64, which
  # made it the extraction source and the probe's baseline.
  "roster", "2026-09-24_nv_rht_funded_projects_bp1.html",
  paste0(NV_BASE, "/RHTP/rht-funded-projects---bp1/"),
  # THE PRIOR SNAPSHOT of the same URL: three tables, 72 subrecipients. KEPT,
  # because rows 1..72 of the award file were parsed from it, session 49's
  # overlay is keyed on that order, and it is the only evidence that NVHA once
  # listed "93 X 95 NV". FROZEN: `--fetch --force` never overwrites it.
  "roster_prior", "2026-08-31_nv_rht_funded_projects_bp1.html",
  paste0(NV_BASE, "/RHTP/rht-funded-projects---bp1/"),
  # SESSION 101: the same page as served 2026-10-15, now linking the BP1
  # Subrecipient Report and otherwise content-identical. The probe's
  # baseline; extraction still reads the 2026-09-24 copy (the tables match).
  "roster_bp1link", "2026-10-15_nv_rht_funded_projects_bp1.html",
  paste0(NV_BASE, "/RHTP/rht-funded-projects---bp1/"),
  # SESSION 101: NVHA's "RHTP Subrecipient Report for BP1", priced, PROVISIONAL.
  "bp1_report", "2026-10-13_nv_rhtp_subrecipient_report_bp1.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/rht-funded-projects---bp1/",
         "rhtp-subrecipient-report-for-bp1_ms.pdf"),
  # The positive control: ten funding opportunities, rosters for three.
  "nofos", "2026-08-31_nv_rht_nofos.html",
  paste0(NV_BASE, "/RHTP/rht-nofos/"),
  # NVHA's own statement of the CMS award date and amount.
  "about", "2026-08-31_nv_rhtp_about.html",
  paste0(NV_BASE, "/RHTP/rhtp-about"),
  # The programme milestones, including "December 29, 2025: Received Notice of
  # Award ($179,931,608)".
  "rhtsc", "2026-08-31_nv_rht_steering_committee.html",
  paste0(NV_BASE, "/RHTP/rhtsc"),
  # The initiative structure, published as PERCENTAGES of the annual award.
  "initiatives", "2026-08-31_nv_rhtp_initiatives.html",
  paste0(NV_BASE, "/RHTP/rhtp-initiatives"),
  # CMS'S OWN NOTICE OF AWARD. The strongest §6.2 document in this repository:
  # not a footer quoting the award, the award.
  "noa", "2026-02-19_nv_cms_notice_of_award_rhtcms332074-01-02.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/noa_rhtcms332074-01-02.pdf"),
  # The Flex Fund round: "$36 million", and the sentence that ties the round to
  # the roster -- "Review all RHT Funded Projects here".
  "press_flex", "2026-06-09_nv_press_release_first_round_flex_fund.pdf",
  paste0(NV_BASE, "/siteassets/content/home/press-release-first-round-of-rht-funded-projects-june-2026_final.pdf"),
  # The WRRAP rounds: $32.3M, $14.3M and $4.8M.
  "press_wrrap", "2026-07-29_nv_press_release_wrrap_awards.pdf",
  paste0(NV_BASE, "/siteassets/content/home/rhtp-funding-press-release.pdf"),
  # THE NEGATIVE CONTROL. GME Grant Round VIII: $15,755,068 of STATE money to
  # nine residency programmes, seven days before NVHA announced $4.8M of RHTP
  # residency money. Seventeen of RCJ's 34 candidates are these nine awards.
  "press_gme", "2026-07-22_nv_press_release_gme_grant_round_viii.pdf",
  paste0(NV_BASE, "/siteassets/content/home/grant-round-viii-announcement.pdf"),
  # The three-programme comparison that states each one's funding SOURCE, and
  # the document whose CMS footer covers all three while only one is RHTP.
  "workforce", "2026-04_nv_workforce_programs_working_together.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/rht_nofos/nvha-healthcare-workforce-programs-remediated-doc-2-1.pdf"),
  # The 2026-06-09 fiscal deck: the pool "available" figures that conflict with
  # the press release, and the Flex funded-projects slides that corroborate the
  # roster with no amounts on them either.
  "fiscal", "2026-06-09_nv_rhtsc_program_fiscal_update.pdf",
  paste0(NV_BASE, "/siteassets/content/community/rhtp/rhtsc/meeting-6.9.26/rhtsc-program-fiscal-update-june26.pdf")
)


# -- fetch --------------------------------------------------------------------

# Snapshots that are evidence of what a page SAID ON A DATE. A forced re-fetch
# must never overwrite them with today's bytes (§2.2's lesson about re-dating
# an archive, applied to --fetch itself).
NV_FROZEN_KEYS <- c("roster_prior")

nv_source <- function(key, field) {
  row <- NV_SOURCES[NV_SOURCES$key == key, ]
  if (nrow(row) != 1L) stop("[NV] unknown source key: ", key, call. = FALSE)
  row[[field]]
}

nv_path <- function(key) file.path(NV_EVIDENCE_DIR, nv_source(key, "file"))

#' Refuse to archive anything carrying a credential (§7.1, sessions 14/16/17/20)
nv_assert_credential_free <- function(body, label) {
  chunk <- body[seq_len(min(length(body), 4e6))]
  txt <- rawToChar(chunk[chunk != as.raw(0)])
  Encoding(txt) <- "latin1"
  for (nm in names(NV_CREDENTIAL_SHAPES)) {
    if (stringr::str_detect(txt, NV_CREDENTIAL_SHAPES[[nm]])) {
      stop("[NV] refusing to archive ", label, ": it carries what looks like a ",
           nm, ".", call. = FALSE)
    }
  }
  invisible(TRUE)
}

nv_get <- function(url, label) {
  message("[NV] fetching ", url)
  resp <- httr::GET(url, httr::user_agent(NV_USER_AGENT), httr::timeout(300))
  if (httr::status_code(resp) != 200L) {
    stop("[NV] HTTP ", httr::status_code(resp), " for ", url, call. = FALSE)
  }
  served <- httr::content(resp, as = "raw")
  nv_assert_credential_free(served, label)
  served
}

nv_fetch <- function(force = FALSE) {
  dir.create(NV_EVIDENCE_DIR, recursive = TRUE, showWarnings = FALSE)
  entries <- purrr::map_dfr(seq_len(nrow(NV_SOURCES)), function(i) {
    src <- NV_SOURCES[i, ]
    dest <- file.path(NV_EVIDENCE_DIR, src$file)
    if (file.exists(dest) && (!force || src$key %in% NV_FROZEN_KEYS)) {
      message("[NV] cached, not re-fetched: ", src$file)
    } else {
      if (i > 1L) Sys.sleep(NV_HOST_THROTTLE_S)
      writeBin(nv_get(src$url, src$file), dest)
    }
    tibble::tibble(
      key = src$key, file = src$file, url = src$url,
      bytes = file.info(dest)$size,
      sha256 = digest::digest(file = dest, algo = "sha256")
    )
  })
  nv_write_manifest(entries)
  entries
}

nv_write_manifest <- function(entries) {
  path <- file.path(NV_EVIDENCE_DIR, "MANIFEST.txt")
  writeLines(c(
    "Nevada -- RHTP Year 1: the NVHA Funded Projects roster, the funding-",
    "opportunities page that is its positive control, the two award press",
    "releases that carry the pool totals, CMS's own Notice of Award, and the",
    "GME release + workforce comparison that are the §6.2 NEGATIVE CONTROL.",
    "Archived by R/03u_nv_year1_awardees.R --fetch",
    paste0("User-agent: ", NV_USER_AGENT),
    "",
    "Every file is the body the server sent, BYTE FOR BYTE, written with",
    "writeBin(), so re-hashing a file on disk reproduces its digest below. The",
    "credential guard that caught CMS's Mapbox token, Illinois's and Oregon's,",
    "and Kansas's Google Maps key runs on every fetch here and finds nothing,",
    "so there is no reduction to explain and the pages are whole.",
    "",
    "THE ROSTER IS `2026-09-24_nv_rht_funded_projects_bp1.html` (session 64).",
    "SEVEN accordion sections, one per awarded pool, each a Subrecipient/",
    "Project/Service-Area table: Flex 39, WRRAP Recruitment and Retention 26,",
    "Apprenticeship and Training 20, Medical Residency 4, Rural Health",
    "Innovation and Technology 24, Rural Health Outcomes Accelerator 36,",
    "Tribal 6 = 155 named award actions AND NO AMOUNT ANYWHERE ON THE PAGE.",
    "It was fetched READ-ONLY by session 63 with curl (user-agent",
    "'RHTP-Tracker/0.1 (AHA Data & Policy research; +https://www.aha.org)')",
    "into data/evidence/recheck/2026-09-24/NV/, and copied here byte for byte;",
    "its digest below equals the digest recorded there. A live in-memory read",
    "on 2026-09-24 reduced to identical text, so it is the probe's baseline.",
    "",
    "`2026-08-31_nv_rht_funded_projects_bp1.html` IS THE PRIOR SNAPSHOT OF THE",
    "SAME URL and is FROZEN: three sections, 25 + 27 + 20 = 72 award actions.",
    "Rows 1..72 of nv_year1_awardees.csv are parsed from it, in its order, and",
    "it is the only evidence that NVHA once listed '93 X 95 NV' (Recruitment",
    "and Retention), which the 2026-09-24 page no longer carries.",
    "",
    "The absence of amounts is the finding, not a fetch failure, and it is",
    "corroborated by `..._rhtsc_program_fiscal_update.pdf`, whose own",
    "'Flex Funds - Funded Projects' slides list the same recipients under the",
    "same three column headings and also carry no amounts.",
    "",
    "THE ROSTER PAGE\'S WHOLE-FILE DIGEST IS NOT STABLE AND MUST NOT BE USED",
    "AS A CHANGE TEST. Its footer carries a rotating \"state symbol\" widget --",
    "two fetches minutes apart served the Lahontan Cutthroat Trout and the",
    "Vivid Dancer Damselfly -- so the page digest differs on EVERY fetch while",
    "nothing about the awards has moved. The roster TABLES are stable and",
    "hash identically across those same fetches, so `nv_roster_digest()` is",
    "what a completeness re-check compares. This is the South Dakota",
    "ServiceNow-token problem in a new costume: a reader verifying the page",
    "digest gets a mismatch that means nothing.",
    "",
    "`..._cms_notice_of_award_rhtcms332074-01-02.pdf` IS THE FEDERAL AWARD",
    "DOCUMENT. Recipient 'Nevada Health Authority', Assistance Listing 93.798",
    "'Rural Health Transformation Program', budget period 12/29/2025 -",
    "10/30/2026, $179,931,608.42. No other state file in this repository holds",
    "the NOA itself. Nevada also publishes the original restricted award at",
    "noa_rhtcms332074-01-00.pdf; the revised one archived here is the operative",
    "document and carries the full amount.",
    "",
    "THE TWO GME FILES ARE THE NEGATIVE CONTROL AND ARE NOT EXTRACTED FROM.",
    "`..._gme_grant_round_viii.pdf` announces $15,755,068 to nine residency",
    "programmes and says 'these new state investments'; ",
    "`..._workforce_programs_working_together.pdf` prints GME, WRRAP and SHARP",
    "side by side and gives each one's funding source -- 'State General Fund',",
    "the CMS RHT grant, and an SB5 appropriation respectively. THAT SECOND",
    "DOCUMENT CARRIES THE CMS FINANCIAL-ASSISTANCE FOOTER ON EVERY PAGE while",
    "two of the three programmes it describes are state-funded, which is why",
    "the footer alone is not a provenance test.",
    "",
    paste0("Manifest written: ", Sys.Date(), ". Each file's fetch date is the ",
           "date in its name; nothing was re-fetched to write this."),
    "",
    sprintf("%-62s %10s  %s", "file", "bytes", "sha256"),
    strrep("-", 62 + 12 + 64)
  ), path)
  cat(sprintf("%-62s %10d  %s", entries$file, entries$bytes, entries$sha256),
      file = path, sep = "\n", append = TRUE)
  cat("\n\nSource URLs\n", file = path, append = TRUE)
  cat(sprintf("  %-14s %s", entries$key, entries$url),
      file = path, sep = "\n", append = TRUE)
  invisible(path)
}


# -- reading the archive ------------------------------------------------------

nv_read_text <- function(key) {
  path <- nv_path(key)
  if (!file.exists(path)) {
    stop("[NV] missing archive: ", path,
         "\n  Run: Rscript R/03u_nv_year1_awardees.R --fetch", call. = FALSE)
  }
  raw <- readBin(path, "raw", file.info(path)$size)
  txt <- rawToChar(raw[raw != as.raw(0)])
  Encoding(txt) <- "UTF-8"
  txt
}

nv_html_doc <- function(key) xml2::read_html(nv_read_text(key))

#' A page's RENDERED text, squished.
#'
#' Assertions read this and never the raw HTML. NVHA writes its milestone
#' sentences with markup and `&nbsp;` inside them -- "December 29, 2025:&nbsp;
#' Received <a title=\"Notice of Award\" href=...>" -- so a `str_detect` on the
#' source bytes fails on a sentence that is plainly on the page.
nv_html_text <- function(key, raw = NULL) {
  doc <- if (is.null(raw)) nv_html_doc(key) else xml2::read_html(raw)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  stringr::str_squish(xml2::xml_text(doc))
}

#' PDF text through the repo's own reader (§ utils_pdf_text), memoised per run.
nv_pdf_cache <- new.env(parent = emptyenv())
nv_pdf_text <- function(key) {
  if (!exists(key, envir = nv_pdf_cache)) {
    source(here::here("R", "utils_pdf_text.R"), local = FALSE)
    assign(key, rhtp_pdf_text(nv_path(key)), envir = nv_pdf_cache)
  }
  get(key, envir = nv_pdf_cache)
}

nv_pdf_flat <- function(key) stringr::str_squish(paste(nv_pdf_text(key), collapse = " "))

#' The roster tables, in page order, each named by its section heading.
#'
#' The page ships them server-rendered inside accordion sections; the "Show"
#' toggles are presentation. Nothing here depends on JavaScript running.
#'
#' Each table is named by the accordion heading it sits under, read off the
#' page rather than assumed from table order: the nearest preceding heading
#' whose text (less the trailing "Show" toggle) is one of the sections this
#' file knows, or the raw heading text if it is not -- so an eighth section
#' arrives with its own name on it.
#'
#' @param key The archive key ("roster" or "roster_prior").
#' @param raw Optional raw bytes of a LIVE page (the probe), read instead.
nv_roster_tables <- function(key = "roster", raw = NULL) {
  doc <- if (is.null(raw)) nv_html_doc(key) else xml2::read_html(raw)
  xml2::xml_remove(xml2::xml_find_all(doc, "//script | //style"))
  nodes <- xml2::xml_find_all(doc, "//table")
  heads <- vapply(nodes, nv_table_section, character(1))
  tabs <- lapply(rvest::html_table(nodes, trim = TRUE), nv_promote_header)
  stats::setNames(tabs, heads)
}

#' The accordion heading a roster table sits under.
nv_table_section <- function(node) {
  prev <- xml2::xml_find_all(node,
    "preceding::*[self::button or self::h2 or self::h3 or self::h4]")
  txt <- stringr::str_squish(xml2::xml_text(prev))
  txt <- stringr::str_squish(sub("\\s*Show$", "", txt))
  txt <- txt[nzchar(txt) & txt != "Show All Sections"]
  known <- txt[txt %in% c(NV_ROSTER_SECTIONS, NV_PRIOR_ROSTER_SECTIONS)]
  if (length(known)) return(utils::tail(known, 1L))
  if (length(txt)) utils::tail(txt, 1L) else NA_character_
}

#' Promote a first data row to the header when the source marked it up with
#' `<td>` instead of `<th>`.
#'
#' SESSION 10'S DEFECT, MET AGAIN AND IN THE SAME SHAPE. NVHA marks the Flex
#' Fund table's header row with `<td>`, so `html_table()` names its columns
#' X1..X3 and keeps "Subrecipient"/"Project"/"County-Service Area" as row 1 --
#' while the two WRRAP tables in the SAME PAGE use `<th>` and resolve normally.
#' A positional read would have taken the header as an award and reported 26
#' Flex Fund awards with a subrecipient called "Subrecipient".
#'
#' The promotion is CONDITIONAL, on session 10's own rule: it happens only when
#' the promoted row resolves STRICTLY MORE of the columns we need than the
#' current header does, so it can never make a working parse worse.
nv_promote_header <- function(tb) {
  wanted <- c("subrecipient|applicant|recipient", "project", "area|county")
  resolves <- function(nms) {
    sum(vapply(wanted, function(p) any(stringr::str_detect(tolower(nms), p)),
               logical(1)))
  }
  if (nrow(tb) < 2L) return(tb)
  candidate <- as.character(unlist(tb[1, ], use.names = FALSE))
  if (resolves(candidate) <= resolves(names(tb))) return(tb)
  out <- tb[-1, , drop = FALSE]
  names(out) <- candidate
  out
}

#' The digest a completeness re-check compares, INSTEAD of the page digest.
#' See the manifest: the page's footer widget rotates on every fetch.
nv_roster_digest <- function() {
  tabs <- nv_roster_tables()
  digest::digest(lapply(tabs, function(t) as.data.frame(lapply(t, as.character))),
                 algo = "sha256")
}

#' The award actions a roster page publishes, one row per table row.
#'
#' Nothing is de-duplicated: Washoe Barton Medical Clinic DBA Carson Valley
#' Health holds TWO Flex Fund rows (a chiller replacement and sterile
#' processing equipment) which are two projects and not a duplicate, Nevada
#' Health Centers holds FIVE RHIT rows, and several recipients appear in more
#' than one pool.
#'
#' @param tables Optional pre-read tables (named by section), so a test can
#'   feed the parser a modified page and require a refusal without mocking the
#'   reader.
#' @param sections The sections the page is expected to carry, in order.
nv_roster_awards <- function(tables = NULL, sections = NV_ROSTER_SECTIONS) {
  tabs <- if (is.null(tables)) nv_roster_tables() else tables
  if (length(tabs) != length(sections)) {
    stop("[NV] the Funded Projects page now carries ", length(tabs),
         " tables, not ", length(sections),
         ". Nevada has published a roster this file does not carry -- re-read ",
         "it before trusting any figure here.", call. = FALSE)
  }
  got <- names(tabs)
  if (!is.null(got) && !identical(unname(got), unname(sections))) {
    stop("[NV] the Funded Projects page's sections are now: ",
         paste(got, collapse = " | "), " -- not the ", length(sections),
         " this file extracts. Nevada has re-arranged or added a roster; ",
         "re-read the page.", call. = FALSE)
  }

  out <- purrr::map_dfr(seq_along(tabs), function(i) {
    tb <- tabs[[i]]
    nms <- tolower(names(tb))
    # Resolve by synonym rather than by position: the third column is headed
    # "County-Service Area" on the Flex table and "Service Area" on the others,
    # which is exactly the kind of drift that silently shifts a positional read
    # by one column.
    col_recipient <- which(stringr::str_detect(nms, "subrecipient|applicant|recipient"))
    col_project   <- which(stringr::str_detect(nms, "project"))
    col_area      <- which(stringr::str_detect(nms, "area|county"))
    if (length(col_recipient) != 1L || length(col_project) != 1L ||
        length(col_area) != 1L) {
      stop("[NV] roster table ", i, " does not resolve to exactly one ",
           "recipient, project and service-area column. Headings were: ",
           paste(names(tb), collapse = " | "), call. = FALSE)
    }
    tibble::tibble(
      award_pool = NV_POOLS$award_pool[match(sections[i], NV_POOLS$section)],
      section = sections[i],
      row_in_pool = seq_len(nrow(tb)),
      awardee = stringr::str_squish(tb[[col_recipient]]),
      project_description = stringr::str_squish(tb[[col_project]]),
      service_area = stringr::str_squish(tb[[col_area]])
    )
  })

  # A blank recipient is a table-shape read that has drifted off its content.
  # Oklahoma's six "No Awardee" counties are the precedent for checking the
  # CONTENT of a row and not just its shape.
  blank <- out$awardee == "" | is.na(out$awardee)
  if (any(blank)) {
    stop("[NV] ", sum(blank), " roster row(s) carry no recipient name. ",
         "The page's table shape has changed -- re-read it.", call. = FALSE)
  }
  # NVHA publishes no amounts. If one ever appears, this file's whole design
  # (empty `amount`, pool totals in `round_amount`) is wrong and must be
  # rewritten rather than quietly kept.
  money <- stringr::str_detect(
    paste(out$awardee, out$project_description, out$service_area),
    "\\$[0-9]")
  if (any(money)) {
    stop("[NV] the roster now carries a dollar figure. Nevada has started ",
         "publishing per-recipient amounts and this file must be rewritten: ",
         "`amount` is empty on every row by design.", call. = FALSE)
  }
  out
}

#' The award file's rows, IN FILE ORDER, and where each came from.
#'
#' SESSION 49's VERIFICATION OVERLAY IS KEYED ON (file, ROW INDEX), so the
#' order is load-bearing. Rows 1..72 are the 2026-08-31 page's rows in that
#' page's order, whatever order NVHA prints them in today; every later row is
#' a row the 2026-09-24 page adds, in that page's order. A 2026-08-31 row is
#' matched to today's page on (section, subrecipient, project, service area)
#' AND its occurrence number, so a recipient listed twice cannot be matched
#' twice. A prior row with no match today is KEPT and marked withdrawn.
#'
#' @param current,prior Parsed award rows (nv_roster_awards output).
nv_ordered_awards <- function(current = nv_roster_awards(),
                              prior = nv_roster_awards(
                                nv_roster_tables("roster_prior"),
                                NV_PRIOR_ROSTER_SECTIONS)) {
  keyed <- function(d) {
    d %>%
      dplyr::mutate(.key = paste(.data$section, .data$awardee,
                                 .data$project_description,
                                 .data$service_area, sep = " || ")) %>%
      dplyr::group_by(.data$.key) %>%
      dplyr::mutate(.occ = dplyr::row_number()) %>%
      dplyr::ungroup()
  }
  cur <- keyed(current)
  pri <- keyed(prior)

  kept <- pri %>%
    dplyr::select(".key", ".occ", "award_pool", "section", "awardee",
                  "project_description", "service_area",
                  prior_row_in_pool = "row_in_pool") %>%
    dplyr::left_join(cur %>% dplyr::select(".key", ".occ", "row_in_pool"),
                     by = c(".key", ".occ")) %>%
    dplyr::mutate(on_current_page = !is.na(.data$row_in_pool),
                  listed_from = "2026-08-31")
  added <- cur %>%
    dplyr::anti_join(pri %>% dplyr::select(".key", ".occ"),
                     by = c(".key", ".occ")) %>%
    dplyr::mutate(on_current_page = TRUE, listed_from = "2026-09-24",
                  prior_row_in_pool = NA_integer_)

  out <- dplyr::bind_rows(kept, added) %>%
    dplyr::select(-".key", -".occ")

  gone <- out$awardee[!out$on_current_page]
  if (!setequal(gone, NV_WITHDRAWN_AWARDEES) ||
      length(gone) != NV_STATED$withdrawn_rows) {
    stop("[NV] the rows on the 2026-08-31 page that the current page no ",
         "longer carries are: ", paste(gone, collapse = "; "),
         " -- not the recorded ", paste(NV_WITHDRAWN_AWARDEES, collapse = "; "),
         ". Read both snapshots before trusting row order.", call. = FALSE)
  }
  out
}


# -- §6.2 provenance ----------------------------------------------------------

#' The federal Notice of Award itself, checked against BOTH anchors.
#'
#' This is the strongest form of the §6.2 test available anywhere in this
#' repository. Oklahoma's was the awarding agency's figure quoted in a footer on
#' the roster; Nevada's is CMS's own award form.
nv_assert_cms_notice_of_award <- function() {
  noa <- nv_pdf_flat("noa")

  # The award document's own identifiers.
  for (needle in c(NV_CMS_AWARD_NUMBER, NV_ASSISTANCE_LISTING,
                   "Rural Health Transformation Program", "Nevada Health Authority")) {
    if (!stringr::str_detect(noa, stringr::fixed(needle))) {
      stop("[NV] the archived Notice of Award no longer carries '", needle,
           "'. Re-read it before trusting this file's provenance.", call. = FALSE)
    }
  }

  # The amount, as CMS wrote it, against the §7.1 anchor.
  published <- format(NV_CMS_AWARD_AMOUNT, big.mark = ",", nsmall = 2,
                      scientific = FALSE)
  if (!stringr::str_detect(noa, stringr::fixed(paste0("$", published)))) {
    stop("[NV] the Notice of Award no longer states $", published, ".",
         call. = FALSE)
  }
  allot <- rhtp_nv_allotment()
  if (round(NV_CMS_AWARD_AMOUNT) != allot) {
    stop("[NV] CMS's Notice of Award says $", published,
         " and cms_fy2026_allotments.csv says $", format(allot, big.mark = ","),
         ". Two CMS figures for one state must agree (§0.2a).", call. = FALSE)
  }

  # The DATE test: the state's own restatement, against cms_state_noa_dates.csv.
  about <- nv_html_text("about")
  rhtsc <- nv_html_text("rhtsc")
  if (!stringr::str_detect(rhtsc,
        "December 29, 2025: ?Received Notice of Award \\(\\$179,931,608\\)")) {
    stop("[NV] the RHT Steering Committee page no longer states Nevada's own ",
         "Notice of Award date and amount.", call. = FALSE)
  }
  if (!stringr::str_detect(about,
        "On December 29, 2025 the Centers for Medicare and Medicaid Services")) {
    stop("[NV] the About page no longer states the CMS award date.", call. = FALSE)
  }
  anchor_date <- rhtp_nv_noa_date()
  if (anchor_date != NV_NOA_DATE) {
    stop("[NV] cms_state_noa_dates.csv gives Nevada ", anchor_date,
         " and this file assumes ", NV_NOA_DATE, ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' Nevada's allotment out of the §7.1 anchor -- read, never typed.
rhtp_nv_allotment <- function() {
  tbl <- readr::read_csv(
    here::here("data", "reference", "cms_fy2026_allotments.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- tbl[tbl$state == NV_STATE, ]
  if (nrow(row) != 1L) stop("[NV] no §7.1 allotment row for NV.", call. = FALSE)
  row$fy2026_allotment
}

rhtp_nv_noa_date <- function() {
  tbl <- readr::read_csv(
    here::here("data", "reference", "cms_state_noa_dates.csv"),
    show_col_types = FALSE, progress = FALSE)
  as.Date(tbl$noa_date[tbl$state == NV_STATE])
}

#' THE FOOTER IS NOT A PROVENANCE TEST, AND THIS IS THE PROOF.
#'
#' The workforce publication carries the CMS financial-assistance footer on
#' every page AND describes three programmes, two of which are state-funded.
#' Both halves are asserted: if the footer disappears the negative control is
#' weaker, and if the "State General Fund" line disappears this file has lost
#' the sentence that disqualifies seventeen RCJ candidates.
nv_assert_footer_is_not_provenance <- function() {
  wf <- nv_pdf_flat("workforce")
  if (!stringr::str_detect(wf, stringr::fixed(
        "financial assistance award totaling $179,931,608.42"))) {
    stop("[NV] the workforce publication no longer carries the CMS ",
         "financial-assistance footer.", call. = FALSE)
  }
  # The three funding sources, side by side in one table.
  if (!stringr::str_detect(wf, stringr::fixed(NV_GME_SOURCE_QUOTE))) {
    stop("[NV] the workforce publication no longer states '",
         NV_GME_SOURCE_QUOTE, "' for the GME programme. That sentence is what ",
         "disqualifies 17 of RCJ's 34 Nevada candidates.", call. = FALSE)
  }
  if (!stringr::str_detect(wf, stringr::fixed("SB5 one-time bill appropriation"))) {
    stop("[NV] the workforce publication no longer states SHARP's funding ",
         "source.", call. = FALSE)
  }
  # The publication hyphen-WRAPS the grant number across a line break
  # ("#RHTCMS332074-01-" / "02"), so the stable stem is what is matched here.
  # The full number is asserted intact on the Notice of Award itself, above.
  if (!stringr::str_detect(wf, stringr::fixed("RHTCMS332074"))) {
    stop("[NV] the workforce publication no longer ties WRRAP to the CMS RHT ",
         "grant number.", call. = FALSE)
  }
  for (g in NV_GME_GOVERNANCE) {
    if (!stringr::str_detect(wf, stringr::fixed(g))) {
      stop("[NV] the workforce publication no longer cites ", g,
           " as GME's governance.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The GME release is STATE money, and none of it is in this file.
nv_assert_gme_is_state_money <- function(records = NULL) {
  gme <- nv_pdf_flat("press_gme")

  if (!stringr::str_detect(gme, stringr::fixed(NV_GME_STATE_QUOTE))) {
    stop("[NV] the GME release no longer calls these '", NV_GME_STATE_QUOTE,
         "'.", call. = FALSE)
  }
  # It must NOT claim RHTP or CMS. If it ever does, the disposition changes.
  if (stringr::str_detect(gme, "(?i)rural health transformation|CMS/HHS|Medicaid Services")) {
    stop("[NV] the GME release now mentions RHTP or CMS. It was dispositioned ",
         "as state general fund money on the strength of it NOT doing so -- ",
         "re-read it.", call. = FALSE)
  }
  stated <- format(NV_GME_TOTAL, big.mark = ",", nsmall = 2, scientific = FALSE)
  if (!stringr::str_detect(gme, stringr::fixed(paste0("$", stated)))) {
    stop("[NV] the GME release no longer states $", stated, ".", call. = FALSE)
  }
  # Its own nine amounts must sum to its own stated total. If they do not, the
  # nine rows this file excludes are not the nine the release announced.
  amounts <- as.numeric(gsub(",", "", stringr::str_match_all(
    gme, "\\(\\$([0-9,]+)\\.00\\)")[[1]][, 2]))
  if (length(amounts) != NV_GME_PROGRAMMES) {
    stop("[NV] the GME release now lists ", length(amounts), " awards, not ",
         NV_GME_PROGRAMMES, ".", call. = FALSE)
  }
  if (abs(sum(amounts) - NV_GME_TOTAL) > 0.005) {
    stop("[NV] the GME release's nine amounts sum to $",
         format(sum(amounts), big.mark = ","), " against its own stated $",
         stated, ".", call. = FALSE)
  }
  if (!isTRUE(all.equal(sort(amounts), sort(NV_GME_AWARDS$amount)))) {
    stop("[NV] the GME release's amounts no longer match the nine recorded ",
         "in NV_GME_AWARDS.", call. = FALSE)
  }

  # And NOT ONE of them may be in the Nevada award file.
  if (!is.null(records)) {
    leaked <- intersect(tolower(records$awardee), tolower(NV_GME_AWARDS$awardee))
    if (length(leaked)) {
      stop("[NV] GME (STATE GENERAL FUND) recipients have leaked into the RHTP ",
           "award file: ", paste(leaked, collapse = "; "), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The date test, on Nevada's own RFA calendar.
nv_assert_rfas_postdate_noa <- function() {
  deck <- nv_pdf_flat("fiscal")
  # The four awarded pools closed on these dates, printed on the deck's RFA
  # timeline. Every one is months AFTER 2025-12-29 -- Texas's HHS0015180 closed
  # 2025-04-24, eight months BEFORE its state had the money.
  closes <- c("4/30/26", "5/15/26", "6/26/26", "5/29/26")
  for (d in closes) {
    if (!stringr::str_detect(deck, stringr::fixed(d))) {
      stop("[NV] the fiscal deck no longer carries the RFA close date ", d, ".",
           call. = FALSE)
    }
  }
  # Parsed rather than asserted as a string: every close date must be later
  # than the NOA.
  parsed <- as.Date(closes, format = "%m/%d/%y")
  if (any(is.na(parsed)) || any(parsed <= NV_NOA_DATE)) {
    stop("[NV] an RFA close date is not strictly after Nevada's ",
         NV_NOA_DATE, " Notice of Award.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- positive controls --------------------------------------------------------

#' NVHA publishes rosters in a recognisable form -- and for exactly seven pools.
#'
#' Without this, "Nevada has published no roster for its other initiatives" is
#' indistinguishable from "we looked in the wrong place". The Funded Projects
#' page carries one accordion section per awarded pool, each with a
#' Subrecipient/Project/Service-Area table. On 2026-08-31 there were three; on
#' 2026-09-24 there are SEVEN, and the four new ones are the rosters session
#' 26 recorded as pending. An EIGHTH means Nevada has awarded something this
#' file does not carry, and a changed ROW COUNT in any section means it has
#' added to (or taken from) a roster it already published -- both fail.
#'
#' @param tables Optional parsed tables (the probe hands in the LIVE page's).
#' @param text Optional rendered text to read the section headings from.
nv_assert_award_index <- function(tables = NULL, text = NULL) {
  txt <- if (is.null(text)) nv_html_text("roster") else text
  for (section in NV_ROSTER_SECTIONS) {
    if (!stringr::str_detect(txt, stringr::fixed(section))) {
      stop("[NV] the Funded Projects page no longer carries the section '",
           section, "'. A roster this file extracts has disappeared.",
           call. = FALSE)
    }
  }
  tabs <- if (is.null(tables)) nv_roster_tables() else tables
  if (length(tabs) != length(NV_ROSTER_SECTIONS)) {
    stop("[NV] the Funded Projects page carries ", length(tabs),
         " roster tables, not ", length(NV_ROSTER_SECTIONS),
         ". Nevada has published a roster this file does not carry.",
         call. = FALSE)
  }
  a <- nv_roster_awards(tabs)
  counts <- as.integer(table(factor(a$award_pool, levels = NV_POOLS$award_pool)))
  moved <- counts != NV_POOLS$round_awards
  if (any(moved)) {
    stop("[NV] the Funded Projects page's section counts have moved: ",
         paste0(NV_POOLS$section[moved], " ", NV_POOLS$round_awards[moved],
                " -> ", counts[moved], collapse = "; "),
         ". NVHA has added to or removed from a published roster -- read the ",
         "page and re-extract.", call. = FALSE)
  }
  invisible(TRUE)
}

#' What was pending on 2026-08-31, what has since awarded, and what still has
#' not. DESIGNED TO FAIL.
#'
#' Session 26 recorded six closed opportunities with no roster. By 2026-09-24
#' THREE HAVE AWARDED -- RHIT, RHOAP and the Rural Tribal Health RFA each have
#' a section on the Funded Projects page -- and this asserts BOTH halves: the
#' three that awarded must still have their sections (else a roster this file
#' extracts has gone), and the three still pending must still have none (else
#' Nevada has awarded something this file does not carry). The day either half
#' breaks, the failure is the signal.
#'
#' @param text,nofos_text Optional rendered texts (the probe hands in LIVE
#'   ones); default to the archive.
nv_assert_pending_not_awarded <- function(text = NULL, nofos_text = NULL,
                                          sections = NULL) {
  roster <- if (is.null(text)) nv_html_text("roster") else text
  nofos <- if (is.null(nofos_text)) nv_html_text("nofos") else nofos_text
  # The SECTION headings, read off the tables themselves -- not a text search,
  # because "Tribal" is also inside recipients' names on this page.
  if (is.null(sections)) sections <- names(nv_roster_tables())

  for (sec in NV_AWARDED_SINCE_0831$section) {
    if (!sec %in% sections) {
      stop("[NV] '", sec, "' -- recorded as AWARDED since 2026-08-31 -- is no ",
           "longer a section of the Funded Projects page.", call. = FALSE)
    }
  }
  # None of the three still-pending opportunities may appear on the page. The
  # page names programmes in its section headings only, so a mention is a
  # section (and nv_assert_award_index() separately refuses an eighth table).
  hit <- stringr::str_extract(roster, NV_PENDING_SECTION_PATTERN)
  if (!is.na(hit)) {
    stop("[NV] '", hit, "' now appears on the Funded Projects page. Nevada ",
         "has awarded an opportunity this file records as pending (",
         paste(NV_PENDING_OPPORTUNITIES, collapse = "; "), ") -- re-extract ",
         "before using any figure here.", call. = FALSE)
  }
  # And the funding-opportunities page must still list all three, or the
  # control itself has gone.
  if (!stringr::str_detect(nofos, stringr::fixed("Requests for Applications"))) {
    stop("[NV] the funding-opportunities page no longer lists Requests for ",
         "Applications; the positive control is gone.", call. = FALSE)
  }
  for (opp in NV_PENDING_OPPORTUNITIES) {
    if (!stringr::str_detect(nofos, stringr::fixed(opp))) {
      stop("[NV] the funding-opportunities page no longer lists '", opp,
           "', which this file records as closed and unawarded.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' The Flex Fund round total is tied to THIS roster by NVHA, not by this file.
nv_assert_flex_round <- function() {
  pr <- nv_pdf_flat("press_flex")
  if (!stringr::str_detect(pr, stringr::fixed("$36 million in Rural Health Transformation funding awards"))) {
    stop("[NV] the 2026-06-09 release no longer states the $36 million Flex ",
         "Fund round.", call. = FALSE)
  }
  # The sentence that makes the roster this round's award list.
  if (!stringr::str_detect(pr, stringr::fixed("Review all RHT Funded Projects here"))) {
    stop("[NV] the 2026-06-09 release no longer points at the Funded Projects ",
         "page. Without that sentence the $36,000,000 and the 25 names are two ",
         "documents nobody has joined (§0.3).", call. = FALSE)
  }
  if (!stringr::str_detect(pr, stringr::fixed("Rural Health Flex Fund"))) {
    stop("[NV] the 2026-06-09 release no longer names the Flex Fund.",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The three WRRAP round totals, and the conflict this file refuses to resolve.
#'
#' BOTH SIDES ARE ASSERTED. If the press release's figures move, `round_amount`
#' is wrong; if the deck's figures move, the conflict this file reports has
#' changed and the note on 27 + 20 rows is stale.
nv_assert_wrrap_rounds <- function() {
  pr <- nv_pdf_flat("press_wrrap")
  for (needle in c("$32.3 million awarded",
                   "$14.3 million in apprenticeship and training investments",
                   "$4.8 million in rural medical residency investments",
                   "$41.9 million requested")) {
    if (!stringr::str_detect(pr, stringr::fixed(needle))) {
      stop("[NV] the 2026-07-29 release no longer states '", needle, "'.",
           call. = FALSE)
    }
  }
  deck <- nv_pdf_flat("fiscal")
  for (amt in c(NV_STATED$deck_rr_available, NV_STATED$deck_at_available,
                NV_STATED$deck_flex_available, NV_STATED$deck_tribal_available)) {
    needle <- paste0("$", format(amt, big.mark = ",", scientific = FALSE))
    if (!stringr::str_detect(deck, stringr::fixed(needle))) {
      stop("[NV] the 2026-06-09 fiscal deck no longer states ", needle,
           ". The pool-total conflict this file reports has changed.",
           call. = FALSE)
    }
  }
  # THE ARITHMETIC THAT SURVIVES THE CONFLICT. Whatever the right mapping is,
  # the two WRRAP workforce sub-funds together are ~$46.6-46.8M, and that is
  # the figure `nv_report()` leads with.
  if (abs(NV_WRRAP_COMBINED_DECK - NV_WRRAP_COMBINED_PRESS) > 200000) {
    stop("[NV] the combined WRRAP figure is no longer stable across the two ",
         "sources ($", format(NV_WRRAP_COMBINED_DECK, big.mark = ","), " vs $",
         format(NV_WRRAP_COMBINED_PRESS, big.mark = ","),
         "). The conflict is now larger than a reallocation can explain and ",
         "must be re-read.", call. = FALSE)
  }
  invisible(TRUE)
}

#' NVHA'S OWN SLIDES CORROBORATE THE ROSTER AND CARRY NO AMOUNTS EITHER.
#'
#' The absence of per-recipient amounts is this file's central design premise,
#' so it is checked against a SECOND, independently produced document: the
#' fiscal deck's "Flex Funds - Funded Projects" slides list the same recipients
#' under the same three column headings (Applicant / County-Service Area / Type
#' of Project) and print no figure against any of them.
nv_assert_no_per_recipient_amounts <- function() {
  deck <- nv_pdf_flat("fiscal")
  if (!stringr::str_detect(deck, stringr::fixed("Flex Funds - Funded Projects"))) {
    stop("[NV] the fiscal deck no longer carries its Flex funded-projects ",
         "slides, which are the corroboration that Nevada publishes no ",
         "per-recipient amount.", call. = FALSE)
  }
  # A sample of recipients that must appear on BOTH the roster and the deck.
  awards <- nv_roster_awards()
  flex <- awards$awardee[awards$award_pool == "FLEX_FUND"]
  seen <- vapply(flex, function(a) stringr::str_detect(deck, stringr::fixed(a)),
                 logical(1))
  if (sum(seen) < 20L) {
    stop("[NV] only ", sum(seen), " of ", length(flex), " Flex Fund recipients ",
         "appear in the fiscal deck. The two documents no longer corroborate ",
         "each other.", call. = FALSE)
  }
  invisible(TRUE)
}


# -- records ------------------------------------------------------------------

# -- Nevada-local typing corrections (session 64) -----------------------------
#
# The 2026-09-24 page added 84 rows, and the shared classifier misreads two
# groups of them. Both corrections keep dollars OUT of the hospital total or
# move none (Nevada prices nobody), and each is PROPOSED for the shared
# override table in R/utils_recipient_classification.R, which this session
# was not scoped to edit. Until it is moved there, it lives here.
#
#   * "Nevada Rural Hospital Partners" (RHOAP). The hospital NAME rule reaches
#     the word "Hospital" and returns HOSPITAL_OR_SYSTEM/DIRECT -- the MHA
#     trap (session 27) a third time. The shared override table already types
#     its Foundation HOSPITAL_AFFILIATED_ENTITY as "the charitable foundation of
#     Nevada Rural Hospital Partners, the state's rural hospital association";
#     the association itself takes the same code, and §10.2 then reads its
#     project ("Support rural hospitals to build capacity to participate in
#     multi-payer alternative payment strategies") as IN_KIND_BENEFIT -- no
#     money moves to a hospital.
#   * Twelve "NSHE ..." rows (RHOAP). NSHE is the Nevada System of Higher
#     Education, and the page's own Medical Residency section writes
#     "Board of Regents, NSHE, obo University of Nevada, Reno". The classifier
#     returned §8's fallback on most of them, STATE_AGENCY on "NSHE, UNLV
#     Department of Gynecologic Surgery and Obstetrics" (the word
#     "Department") and TRIBAL_ORG AT HIGH on "NSHE, UNR Reno Extension Tribal
#     Program" -- the word "Tribal" in a university extension PROGRAMME's name,
#     which is §0.3a exactly: the name of the activity, not the recipient.
#     The recipient string states the form, so UNIVERSITY_OR_AHC at MEDIUM.
NV_LOCAL_TYPE_OVERRIDES <- tibble::tribble(
  ~pattern,                               ~recipient_type,              ~confidence, ~why,
  "^Nevada Rural Hospital Partners$",     "HOSPITAL_AFFILIATED_ENTITY", "MEDIUM",
  "Nevada Rural Hospital Partners is the state's rural hospital association (the shared override table's own description of it, on its Foundation's row) -- an association, not a hospital; the hospital name rule reads the word 'Hospital' in its name (§10.2, the MHA trap)",
  "^NSHE\\b",                             "UNIVERSITY_OR_AHC",          "MEDIUM",
  "the recipient string names NSHE, the Nevada System of Higher Education, and a UNR or UNLV unit -- the page's own Medical Residency section writes 'Board of Regents, NSHE, obo University of Nevada, Reno'; a university unit, whatever its programme is called (§0.3a)"
)

#' The shared classifier, with Nevada's two local corrections applied first.
nv_classify_recipient <- function(name) {
  hit <- which(vapply(NV_LOCAL_TYPE_OVERRIDES$pattern,
                      function(p) grepl(p, name, perl = TRUE), logical(1)))
  if (length(hit) > 1L) {
    stop("[NV] '", name, "' matches ", length(hit), " local overrides.",
         call. = FALSE)
  }
  if (length(hit) == 1L) {
    o <- NV_LOCAL_TYPE_OVERRIDES[hit, ]
    return(list(recipient_type = o$recipient_type,
                determination_confidence = o$confidence,
                recipient_type_basis = paste0("Nevada override (session 64): ",
                                              o$why, "."),
                rule = "OVERRIDE"))
  }
  rhtp_classify_recipient_type(name, NV_STATE)
}

#' Nevada's rows in the Florida schema (§8, test_state_union).
#'
#' 156 rows: the 155 award actions on NVHA's 2026-09-24 page, plus the ONE row
#' the 2026-08-31 page carried and today's does not ("93 X 95 NV"), kept in
#' its original place. Rows 1..72 are in the 2026-08-31 page's order and every
#' later row is appended in the 2026-09-24 page's order -- see
#' nv_ordered_awards() for why the order is load-bearing.
#'
#' SESSION 64 REMOVED THE RURAL MEDICAL RESIDENCY AGGREGATE ROW (formerly row
#' 73, "Recipients not named by NVHA"). Its whole claim was that NVHA had named
#' nobody for the $4.8 million, and the 2026-09-24 page names four; the four
#' named rows carry the pool's round total in `round_amount` instead. It was
#' the LAST row of the file, so removing it moves no row index session 49's
#' overlay is keyed on, and no overlay row pointed at it.
nv_records <- function() {
  awards <- nv_ordered_awards()

  classified <- purrr::map_dfr(seq_len(nrow(awards)), function(i) {
    ct <- nv_classify_recipient(awards$awardee[i])
    fl <- rhtp_classify_flow(ct$recipient_type, awards$project_description[i])
    tibble::tibble(
      recipient_type = ct$recipient_type,
      determination_confidence = ct$determination_confidence,
      classifier_basis = ct$recipient_type_basis,
      classifier_rule = ct$rule,
      flow_type = fl$flow_type,
      distributed_to_hospital = fl$distributed_to_hospital,
      hospital_benefiting = fl$hospital_benefiting,
      flow_basis = fl$flow_basis,
      flow_flag = fl$flow_flag
    )
  })

  pools <- NV_POOLS %>% dplyr::select(-"section")
  roster <- dplyr::bind_cols(awards, classified) %>%
    dplyr::left_join(pools, by = "award_pool") %>%
    dplyr::mutate(
      # The Flex Fund's $36M is the June first round. A Flex row first listed
      # after 2026-08-31 carries NO published round total, so it gets its own
      # round id and an NA -- never a figure it may not be inside.
      flex_added = .data$award_pool == "FLEX_FUND" &
        .data$listed_from == "2026-09-24",
      round_id = dplyr::if_else(.data$flex_added, NV_FLEX_ADDED_ROUND$round_id,
                                .data$round_id),
      round_name = dplyr::if_else(.data$flex_added,
                                  NV_FLEX_ADDED_ROUND$round_name,
                                  .data$round_name),
      round_amount = dplyr::if_else(.data$flex_added, NA_real_,
                                    .data$round_amount),
      withdrawn = !.data$on_current_page,
      row_in_pool = dplyr::if_else(.data$withdrawn,
                                   .data$prior_row_in_pool,
                                   .data$row_in_pool),
      roster_key = dplyr::if_else(.data$withdrawn, "roster_prior", "roster"),
      state = NV_STATE,
      note = paste0(
        .data$project_description, " Service area: ", .data$service_area, ".",
        " Published by the Nevada Health Authority on its RHT Funded Projects -",
        " Budget Period 1 page, which names every subrecipient and PUBLISHES NO",
        " AMOUNT FOR ANY OF THEM.",
        dplyr::case_when(
          .data$withdrawn ~ paste0(
            " LISTED ON THE 2026-08-31 PAGE AND ABSENT FROM THE 2026-09-24 ",
            "PAGE: NVHA has removed this row and said nothing about why. It is ",
            "KEPT, from the frozen prior snapshot, because NVHA published it; ",
            "whether the award stands is not known (recipient_confirmed = ",
            "Unclear)."),
          .data$flex_added ~ paste0(
            " First listed on the 2026-09-24 page. NVHA's $36 million Flex ",
            "figure is its 2026-06-09 FIRST-ROUND release, and no document ",
            "says whether this row is inside it, so this row carries no round ",
            "total."),
          is.na(.data$round_amount) ~ paste0(
            " NVHA has published NO round total for this pool, so ",
            "`round_amount` is empty."),
          TRUE ~ paste0(" The pool's own round total is in `round_amount`; it ",
                        "is NEVER divided across recipients (§6.2).")),
        " Source snapshot: ", .data$listed_from, "."),
      # THE RECIPIENT IS CONFIRMED AND THE AMOUNT DOES NOT EXIST. §9.3 splits
      # these two questions precisely so a missing figure cannot drag a
      # confirmed recipient down with it. A row NVHA has since removed is
      # neither confirmed nor refuted.
      recipient_confirmed = dplyr::if_else(.data$withdrawn, "Unclear", "Yes"),
      amount_confirmed = "No",
      amount = NA_real_,
      fiscal_year = 2026L,
      budget_period = "BP1 (12/29/2025 - 10/30/2026)",
      source_document_title = paste0(
        "Nevada RHT Funded Projects - Budget Period 1: ", .data$section),
      state_source_url = nv_source("roster", "url"),
      # NVHA calls the page "RHT Funded Projects" and its releases say
      # "awarded". Its own June process slide nonetheless puts a Letter of
      # Intent, CMS approval and final budget negotiation between selection and
      # subaward, and says "All RHT subawards for BP1 to be finalized by
      # October 1, 2026". Oregon's and Maryland's posture: the recipient is
      # announced, the agreement is not yet executed.
      validation_source_type = "NOTICE_OF_INTENT_TO_AWARD",
      extraction_method = "PARSED_HTML_TABLE",
      validator = "R/03u_nv_year1_awardees.R",
      ccn = NA_character_, aha_id = NA_character_,
      rural_designation = NA_character_, reviewer = NA_character_,
      recipient_type_source = .data$classifier_basis,
      amount_basis = dplyr::if_else(
        is.na(.data$round_amount),
        "NVHA publishes NO per-recipient amount and NO round total for this row's pool",
        "NVHA publishes NO per-recipient amount; the pool round total is in round_amount"),
      county = .data$service_area,
      initiative = dplyr::case_when(
        .data$award_pool == "FLEX_FUND" ~ "Rural Health System Flex Fund",
        .data$award_pool == "RHIT" ~ "Rural Health Innovation and Technology (RHIT)",
        .data$award_pool == "RHOAP" ~ "Rural Health Outcomes Accelerator Program (RHOAP)",
        .data$award_pool == "TRIBAL" ~ "Rural Tribal Health System Transformation",
        TRUE ~ "Workforce Recruitment and Rural Access Program (WRRAP)"),
      initiative_fund_use = .data$round_name,
      intermediary_name = NA_character_,
      source_archive_path = file.path(
        "data/evidence/NV",
        vapply(.data$roster_key, nv_source, character(1), field = "file"))
    )

  recs <- roster %>%
    dplyr::mutate(
      hospital_attribution = dplyr::case_when(
        .data$distributed_to_hospital == "Yes" &
          .data$recipient_type %in% c("HOSPITAL_OR_SYSTEM",
                                      "HOSPITAL_AFFILIATED_ENTITY") ~ "NAMED_HOSPITAL",
        .data$distributed_to_hospital == "Yes" ~ "POOL_NAMED_HOSPITALS",
        TRUE ~ "NOT_HOSPITAL"),
      flag_reason = nv_flags(.data$recipient_type, .data$classifier_rule,
                             .data$flow_flag, .data$award_pool,
                             .data$recipient_confirmed),

      # \u00a77 MAKES THIS FIELD MANDATORY AND NEVADA DID NOT CARRY IT AT ALL.
      # Both halves were already computed -- `classifier_basis` from the
      # recipient's name and `flow_basis` from \u00a710.2 -- and only the first
      # was surfaced, as `recipient_type_source`; the flow half was dropped on
      # the floor. The session 30 eligibility sweep found the two pass-through
      # rows with no stated basis at all, which is the field's whole purpose
      # failing on exactly the rows a reviewer will come back to: the Incline
      # Village Community Hospital Foundation (the project's first
      # FLOW_UNRESOLVED_HOSPITAL_AFFILIATED row) and the unnamed $4.8M
      # residency aggregate.
      #
      # The composition is `rhtp_classify_recipients()`'s own -- recipient
      # basis, then flow basis -- so a Nevada row now reads the same way a row
      # from any other state does. Session 31; nothing was re-coded and no
      # dollar moved, because both sentences already existed and described the
      # codings the file already carried.
      determination_basis = paste(.data$classifier_basis, .data$flow_basis),

      row_no = dplyr::row_number()
    )

  nv_assert_vocabulary(recs)
  recs
}

#' The flag set per row, `;`-joined (Oregon's convention).
nv_flags <- function(recipient_type, classifier_rule, flow_flag, award_pool,
                     recipient_confirmed) {
  vapply(seq_along(recipient_type), function(i) {
    f <- character(0)
    # §8's standing fallback: a named recipient whose FORM NVHA never states.
    if (identical(classifier_rule[i], "FALLBACK")) {
      f <- c(f, "RECIPIENT_TYPE_INFERRED")
    }
    # EVERY row. Nevada publishes no per-recipient amount at all.
    f <- c(f, "AMOUNT_MISSING")
    if (identical(recipient_confirmed[i], "No")) {
      f <- c(f, "RECIPIENT_NOT_NAMED")
    }
    if (!is.na(flow_flag[i])) f <- c(f, flow_flag[i])
    # The two WRRAP workforce pools, whose round totals two NVHA documents
    # disagree about. The Flex Fund and the residency pool are not in dispute.
    if (award_pool[i] %in% c("WRRAP_RECRUITMENT_RETENTION",
                             "WRRAP_APPRENTICESHIP_TRAINING")) {
      f <- c(f, "POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES")
    }
    paste(unique(f), collapse = ";")
  }, character(1))
}

#' Every categorical value against `vocabularies.csv` (§5).
nv_assert_vocabulary <- function(recs) {
  checks <- list(
    recipient_type = "recipient_type",
    distributed_to_hospital = "distributed_to_hospital",
    recipient_confirmed = "recipient_confirmed",
    amount_confirmed = "amount_confirmed",
    determination_confidence = "determination_confidence",
    flow_type = "flow_type",
    hospital_attribution = "hospital_attribution",
    validation_source_type = "source_doc_type"
  )
  for (col in names(checks)) {
    allowed <- rhtp_vocabulary(checks[[col]])
    bad <- setdiff(as.character(stats::na.omit(unique(recs[[col]]))), allowed)
    if (length(bad)) {
      stop("[NV] value(s) outside §8 in `", col, "`: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  allowed_flags <- rhtp_vocabulary("flag_reason")
  used <- unique(unlist(strsplit(stats::na.omit(recs$flag_reason), ";")))
  used <- used[nzchar(used)]
  bad <- setdiff(used, allowed_flags)
  if (length(bad)) {
    stop("[NV] flag_reason value(s) outside §8: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- reconciliation -----------------------------------------------------------

#' Nevada's published total, summed over DISTINCT rounds.
#'
#' GEORGIA'S TRAP, IN A NEW STATE. `round_amount` repeats its round's total on
#' every row of that round, so summing the column gives $2,077,300,000 for a
#' state that announced $87,400,000. Nothing may sum `round_amount` down the
#' column; this is the function that does it correctly.
#'
#' SESSION 64: FOUR ROUNDS HAVE A PUBLISHED TOTAL AND FOUR DO NOT (RHIT,
#' RHOAP, Tribal, and the Flex rows first listed after 2026-08-31). The
#' announced total is the sum of the four published ones, unchanged at
#' $87,400,000; the other four are reported beside it, never imputed.
nv_reconcile <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  pools <- recs %>%
    dplyr::distinct(.data$award_pool, .data$round_id, .data$round_name,
                    .data$round_amount) %>%
    dplyr::arrange(dplyr::desc(.data$round_amount))
  if (nrow(pools) != nrow(NV_POOLS) + 1L) {
    stop("[NV] reconciliation found ", nrow(pools), " distinct rounds, not ",
         nrow(NV_POOLS) + 1L, " (seven pools, the Flex Fund in two rounds).",
         call. = FALSE)
  }
  if (anyDuplicated(pools$round_id)) {
    stop("[NV] a round carries two different round totals.", call. = FALSE)
  }
  total <- sum(pools$round_amount, na.rm = TRUE)
  if (total != NV_STATED$announced_total) {
    stop("[NV] the published round totals sum to $", format(total, big.mark = ","),
         " against Nevada's announced $",
         format(NV_STATED$announced_total, big.mark = ","), ".", call. = FALSE)
  }
  # And the wrong sum must stay visibly wrong, so the trap cannot quietly close.
  naive <- sum(recs$round_amount, na.rm = TRUE)
  if (naive <= total) {
    stop("[NV] summing `round_amount` down the column no longer overstates ",
         "the total. The repeat-per-row design has changed and every ",
         "assertion keyed on it needs re-reading.", call. = FALSE)
  }
  list(pools = pools, total = total, naive_column_sum = naive,
       unpriced_rounds = pools$round_id[is.na(pools$round_amount)],
       pct_of_allotment = 100 * total / rhtp_nv_allotment())
}

#' THE MISREADING GUARD.
#'
#' `rhtp_hospital_dollar_partition()` sums with `na.rm = TRUE`, so Nevada comes
#' back as `NAMED_HOSPITAL rows = 20, dollars = 0`. Both halves are true and
#' only one of them is a number, which is why a reader who takes the 0 and not
#' the 20 concludes Nevada's rural hospitals got nothing -- the exact opposite
#' of what NVHA has published. This asserts the pairing so it cannot drift, and
#' it is the assertion to read before quoting any Nevada hospital figure.
nv_assert_zero_dollars_is_not_zero_hospitals <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  part <- rhtp_hospital_dollar_partition(recs)
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  if (nrow(named) != 1L) {
    stop("[NV] the partition no longer returns exactly one NAMED_HOSPITAL row.",
         call. = FALSE)
  }
  if (named$dollars != 0) {
    stop("[NV] NAMED_HOSPITAL dollars are $", format(named$dollars, big.mark = ","),
         ", not $0. Nevada has started publishing per-recipient amounts and ",
         "this file's design premise is gone -- rewrite it rather than ",
         "updating this number.", call. = FALSE)
  }
  if (named$rows < 1L) {
    stop("[NV] the partition reports 0 named-hospital ROWS. Nevada names ",
         "hospitals on its roster; a zero here is a parse failure, not a ",
         "finding.", call. = FALSE)
  }
  invisible(list(rows = named$rows, dollars = named$dollars))
}

#' Same-entity name variants across pools -- RECORDED, NEVER RESOLVED.
#'
#' NVHA writes several recipients differently in different pools: "Desert View
#' Hospital" and "DVH Hospital Alliance LLN dba Desert View Hospital",
#' "Grover C. Dils Medical Center" and "Lincoln County Hospital District dba
#' Grover C. Dils Medical Center", "Carson Valley Health" and "Washoe Barton
#' Medical Clinic DBA Carson Valley Health". And it publishes BOTH "Northern
#' Nevada Regional Hospital" (Flex, "Elko - Battle Mountain and Owyhee") and
#' "Northeastern Nevada Regional Hospital" (Recruitment and Retention, "Elko,
#' Eureka, Humboldt, Lander, and White Pine") -- two names four characters
#' apart, in one state, both in Elko.
#'
#' §2 FORBIDS A MACHINE AUTO-RESOLVING A FUZZY HOSPITAL MATCH, so none of these
#' is merged. The consequence is that "distinct hospitals" is a count of NAMES
#' and is an upper bound on the count of ORGANISATIONS. The CCN match (blocker
#' 5) is what settles it.
NV_NAME_VARIANT_PAIRS <- list(
  c("Desert View Hospital", "DVH Hospital Alliance LLN dba Desert View Hospital"),
  c("Grover C. Dils Medical Center",
    "Lincoln County Hospital District dba Grover C. Dils Medical Center"),
  c("Carson Valley Health", "Washoe Barton Medical Clinic DBA Carson Valley Health"),
  c("Northern Nevada Regional Hospital", "Northeastern Nevada Regional Hospital")
)

nv_assert_name_variants_unresolved <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  for (pair in NV_NAME_VARIANT_PAIRS) {
    present <- pair %in% recs$awardee
    if (!all(present)) {
      stop("[NV] the name-variant pair '", paste(pair, collapse = "' / '"),
           "' is no longer both present in the file. Either NVHA has ",
           "normalised its own roster or something has merged them here -- ",
           "§2 forbids the latter.", call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- §0.1: what RCJ's Nevada candidates actually are (34 on 08-27, 42 on 09-24) --

#' The committed Tier 3 candidate set for Nevada, re-derived on every run.
#'
#' Never typed. The day Nevada's candidate set moves, the disposition build
#' fails rather than quietly ceasing to cover it (Texas's, Nebraska's,
#' Indiana's and Oklahoma's convention).
nv_rcj_candidates <- function() {
  path <- here::here("data", "interim", "stage2_record_table.rds")
  if (!file.exists(path)) {
    stop("[NV] stage2_record_table.rds is missing; run Stage 2 first.",
         call. = FALSE)
  }
  rhtp_record_table_live(path = path) %>%
    dplyr::filter(.data$state == NV_STATE, .data$award_tier == "SUBAWARD",
                  is.na(.data$superseded_by))
}

#' Which candidate is which, keyed on the source document RCJ took it from.
nv_classify_candidates <- function(cand = NULL) {
  if (is.null(cand)) cand <- nv_rcj_candidates()
  gme_names <- tolower(NV_GME_AWARDS$awardee)
  cand %>%
    dplyr::mutate(
      disposition = dplyr::case_when(
        # ORDER MATTERS, AND THIS BRANCH MUST COME FIRST. NVHA's own pool is
        # called "Rural Medical Residency", so a specialty regex written for
        # the GME awards below matches the POOL TOTAL too -- which would file
        # $9.6M of Tier 2 RHTP money as state money and get both wrong at once.
        # The pool names, and RCJ's "... Recipients (NV)" variants of them, are
        # §6.1's PROGRAM_NAME_AS_AWARDEE and §0.3's class-not-a-recipient.
        stringr::str_detect(.data$awardee_name_clean,
          "(?i)^(provider recruitment and retention|apprenticeship and training|rural medical residency)") ~
          "RHTP_BUT_NOT_A_SUBAWARD",
        # A line item out of the RFA's budget-narrative TEMPLATE.
        stringr::str_detect(.data$source_doc_title,
                            "(?i)attachment c: budget narrative") ~
          "RHTP_BUT_NOT_A_SUBAWARD",
        # Session 63 (the 2026-09-24 pull): INITIATIVE funding lines out of
        # the state's own plan documents -- the Nevada RHT Budget Narrative
        # and the February 2026 stakeholder deck, whose figures carry
        # "*Pending approval of revised budget". Tier 2 (§0.2).
        stringr::str_detect(.data$source_doc_title,
                            "(?i)nevada rht budget narrative|rht-stakeholder-meetings") ~
          "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD",
        # Session 63: five named contractors RCJ mined from NVHA's CMS
        # programmatic annual-report walkthrough. Their amounts are on an
        # image-only slide this reader cannot read -- UNRESOLVED, not a finding.
        stringr::str_detect(.data$source_doc_title,
                            "(?i)CMS Programmatic Annual Report") ~
          "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED",
        # The nine GME programmes, under either of the two titles RCJ files
        # them beneath. Matched on the AMOUNT and on the name: RCJ publishes
        # UNLV Ophthalmology at $2,995,893 under one title and $2,995,890 --
        # the state's own figure -- under the other, so neither key alone
        # reaches all seventeen rows.
        round(.data$amount_announced) %in% round(NV_GME_AWARDS$amount) |
          tolower(.data$awardee_name_clean) %in% gme_names |
          stringr::str_detect(.data$awardee_name_clean,
            "(?i)residency|fellowship|ophthalmolog|otolaryngolog|radiolog|gynecolog|pulmonary|family medicine|internal medicine|general surgery") ~
          "NOT_RHTP_STATE_PROGRAM",
        TRUE ~ "RHTP_SUBAWARD_IN_FILE"),
      .after = "awardee_name_clean")
}

#' The disposition table: one row per group, with the disqualifying evidence.
nv_disposition_table <- function() {
  cand <- nv_classify_candidates()
  recs <- nv_records()

  t2 <- cand$disposition == "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD"
  ven <- cand$disposition == "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED"
  live <- nv_live_roster_sections()
  n_of <- function(d) sum(cand$disposition == d)
  amt_of <- function(d) sum(cand$amount_announced[cand$disposition == d],
                            na.rm = TRUE)

  # The rows RCJ DOES hold that are real Nevada awards must actually be in the
  # file, matched on name. If one is not, either the roster parse or this
  # disposition is wrong.
  in_file <- cand$awardee_name_clean[cand$disposition == "RHTP_SUBAWARD_IN_FILE"]
  missing <- setdiff(tolower(in_file), tolower(recs$awardee))
  if (length(missing)) {
    stop("[NV] RCJ holds candidate(s) dispositioned as real Nevada awards that ",
         "are NOT in nv_year1_awardees.csv: ", paste(missing, collapse = "; "),
         call. = FALSE)
  }

  tibble::tribble(
    ~group, ~rcj_rows, ~rcj_amount_sum, ~disposition, ~why, ~disqualifying_evidence, ~state_source_url, ~source_archive_path,

    "GME Grant Program Round VIII -- nine residency and fellowship programmes",
    n_of("NOT_RHTP_STATE_PROGRAM"), amt_of("NOT_RHTP_STATE_PROGRAM"),
    "NOT_RHTP_STATE_PROGRAM",
    paste0(
      "Nevada's Graduate Medical Education grant programme is STATE GENERAL ",
      "FUND money, not RHTP. NVHA's own workforce publication prints GME, ",
      "WRRAP and SHARP side by side under a column headed 'Funding' and gives ",
      "GME's source as 'State General Fund' with governance NRS 223.631-639 ",
      "and SB262 & SB494 (2025); only WRRAP is sourced to the CMS RHT grant. ",
      "The 2026-07-22 release announcing these nine awards calls them 'these ",
      "new state investments' and mentions neither CMS nor RHTP. RCJ files ",
      "them under RHTP-titled documents anyway. THE CMS FINANCIAL-ASSISTANCE ",
      "FOOTER IS ON THE WORKFORCE PUBLICATION AND DOES NOT REACH THE ",
      "PROGRAMMES IT DESCRIBES -- which is why a footer check alone passes ",
      "all seventeen of these rows."),
    paste0("\"Source: State General Fund\" / \"", NV_GME_STATE_QUOTE,
           "\" / total $15,755,068.00 to nine programmes"),
    "https://www.nvha.nv.gov/working-together/be-informed/",
    "data/evidence/NV/2026-07-22_nv_press_release_gme_grant_round_viii.pdf",

    "The three WRRAP pool totals, and a budget-narrative line item",
    n_of("RHTP_BUT_NOT_A_SUBAWARD"), amt_of("RHTP_BUT_NOT_A_SUBAWARD"),
    "RHTP_BUT_NOT_A_SUBAWARD",
    paste0(
      "Genuinely RHTP and one tier too high (§0.2). 'Provider Recruitment and ",
      "Retention' ($32,300,000), 'Apprenticeship and Training Investments' ",
      "($14,300,000) and 'Rural Medical Residency Investments' ($4,800,000) ",
      "are NVHA's POOL names carrying NVHA's POOL totals -- §6.1's ",
      "PROGRAM_NAME_AS_AWARDEE, and the same figures this file carries in ",
      "`round_amount`. RCJ additionally publishes each under a '... ",
      "Recipients (NV)' variant, which is a CLASS and not a recipient (§0.3, ",
      "North Dakota's '15 selected CAHs'). 'IT Technician At Your Service' ",
      "($40,000) is a line out of Attachment C, the RFA's budget narrative ",
      "TEMPLATE."),
    "the pool totals restated as awardees; a budget-template line item",
    "https://www.nvha.nv.gov/RHTP/rht-nofos/",
    "data/evidence/NV/2026-07-29_nv_press_release_wrrap_awards.pdf",

    "Ten Flex Fund awardees RCJ captured from a STEERING COMMITTEE AGENDA",
    n_of("RHTP_SUBAWARD_IN_FILE"), amt_of("RHTP_SUBAWARD_IN_FILE"),
    "RHTP_SUBAWARD_IN_FILE",
    paste0(
      "Real Nevada RHTP awards, and all ten are in nv_year1_awardees.csv -- ",
      "asserted by name, not assumed. They are the ONLY genuine subawards in ",
      "the candidate set: RCJ holds ", n_of("RHTP_SUBAWARD_IN_FILE"), " of the ",
      sum(live$awards), " named award actions on NVHA's Funded Projects page ",
      "as archived 2026-09-24, which carries ", nrow(live), " sections (",
      paste0(live$section, " ", live$awards, collapse = "; "), ") -- still ",
      "with NO amount anywhere. Session 64 extracted all of them: RHIT and ",
      "RHOAP, whose decisions were due in August, the Tribal RFA, and the ",
      "Medical Residency pool (which now names its four recipients) have ",
      "published rosters since 2026-08-31, and the Flex Fund grew 25 -> 39. ",
      "RCJ's pull predates all of it. ",
      "EVERY ONE of RCJ's ten CARRIES AN AMOUNT OF $1. They were mined out of the ",
      "2026-06-09 RHT Steering Committee fiscal deck, whose 'Flex Funds - ",
      "Funded Projects' slides list recipients with NO amounts, so the $1 is ",
      "a placeholder for a figure that does not exist -- and RCJ's title for ",
      "them, 'Agenda Nevada RHT Program Activity', is the text of the deck's ",
      "AGENDA SLIDE, not the document's title (Nebraska's defect: the title ",
      "came off the wrong page)."),
    "amount_announced = $1 on all ten; the title is the agenda slide's text",
    "https://www.nvha.nv.gov/RHTP/rht-meetings/",
    "data/evidence/NV/2026-06-09_nv_rhtsc_program_fiscal_update.pdf",

    "Initiative funding lines from the RHT Budget Narrative and the 02.26 stakeholder deck",
    n_of("TIER_2_BUDGET_LINE_NOT_A_SUBAWARD"), amt_of("TIER_2_BUDGET_LINE_NOT_A_SUBAWARD"),
    "TIER_2_BUDGET_LINE_NOT_A_SUBAWARD",
    paste0(
      "New on the 2026-09-24 pull, and not awards: ",
      paste0("'", cand$awardee_name_clean[t2], "' ($",
             formatC(cand$amount_announced[t2], format = "f", digits = 0,
                     big.mark = ","), ")",
             collapse = "; "),
      ". Each 'awardee' is an INITIATIVE or a State Policy Action, not an ",
      "organisation (§6.1 PROGRAM_NAME_AS_AWARDEE). NVHA's February 2026 ",
      "stakeholder deck prints 'Rural Health Innovation and Technology ",
      "Funding: $26,989,741*' and 'Presidential Fitness Test $1,298,985*' ",
      "under '*Pending approval of revised budget' -- a plan (§0.3), Tier 2 ",
      "(§0.2). $26,989,741 is also exactly NVHA's 15% 'Provider Payments ",
      "(Category B)' spending CAP in its annual-report walkthrough, and the ",
      "Presidential Fitness Test is a CMS State Policy Action ('NVHA ",
      "anticipates activity towards this SPA in BP2'). The Flex Fund row is a ",
      "line of the RHT Budget Narrative (not archived here). Flex's and ",
      "RHIT's AWARDS are named rosters with no amounts on NVHA's live page -- ",
      "see the Flex row -- and never these figures."),
    "'Funding: $26,989,741*' / '$1,298,985* Presidential Fitness Test' / '*Pending approval of revised budget'",
    "https://www.nvha.nv.gov/siteassets/content/community/rhtp/rht-stakeholder-meetings-02.26.pdf",
    "data/evidence/recheck/2026-09-24/NV/2026-02_nv_rht_stakeholder_meetings_02.26.pdf",

    "Five contractors from NVHA's CMS annual-report walkthrough",
    n_of("AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED"),
    amt_of("AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED"),
    "AGGREGATOR_PLACEHOLDER_OR_UNRESOLVED",
    paste0(
      "UNRESOLVED. RCJ files ", paste(cand$awardee_name_clean[ven], collapse = "; "),
      " under 'NV - 2025 - CMS Programmatic Annual Report' at ",
      paste0("$", formatC(cand$amount_announced[ven], format = "f", digits = 2,
                          big.mark = ","), collapse = ", "),
      ". The state document at that title (NVHA's 2026-09-08 walkthrough deck, ",
      "archived) carries NONE of these names or figures in its text layer; ",
      "its 'Downstream Reporting Tab' slide is an image this reader cannot ",
      "read. RCJ's own descriptions (machine-generated, non-quotable, §6) ",
      "call them technical assistance, 1115-waiver support and contract ",
      "staff for NVHA -- the ADMINISTRATOR's contractors, not subrecipients on ",
      "NVHA's Funded Projects roster, and none is in nv_year1_awardees.csv. ",
      "Whether they are RHTP administrative contracts (South Dakota's R/03i ",
      "shape) needs the report itself; nothing here promotes them (§0.1)."),
    "no name or figure in the archived deck's text layer; slide 11 is image-only",
    "https://www.nvha.nv.gov/siteassets/content/community/rhtp/rht-workshops/rhtsc---programmatic-annual-report.pdf",
    "data/evidence/recheck/2026-09-24/NV/2026-09-08_nv_rhtsc_programmatic_annual_report_walkthrough.pdf"
  ) %>%
    rhtp_assert_disposition_prose(NV_STATE)
}

#' NVHA's Funded Projects page as archived 2026-09-24: award actions per
#' accordion section, read through the same parser the award file uses.
nv_live_roster_sections <- function() {
  nv_roster_awards() %>%
    dplyr::count(.data$section, name = "awards") %>%
    dplyr::arrange(match(.data$section, NV_ROSTER_SECTIONS))
}


#' The candidate set's own arithmetic, re-derived and asserted every run.
nv_assert_candidate_disposition <- function() {
  cand <- nv_classify_candidates()
  if (nrow(cand) != NV_STATED$rcj_candidates) {
    stop("[NV] the committed record table now holds ", nrow(cand),
         " Nevada Tier 3 candidates, not ", NV_STATED$rcj_candidates,
         ". nv_rcj_candidate_disposition.csv no longer covers the set it ",
         "claims to.", call. = FALSE)
  }
  d <- nv_disposition_table()
  if (sum(d$rcj_rows) != nrow(cand)) {
    stop("[NV] the disposition table accounts for ", sum(d$rcj_rows),
         " candidates of ", nrow(cand), ".", call. = FALSE)
  }
  # NOT ONE candidate may be missing a disposition.
  if (any(is.na(cand$disposition))) {
    stop("[NV] ", sum(is.na(cand$disposition)),
         " Nevada candidates have no disposition.", call. = FALSE)
  }
  # The state-money group must cover the nine GME programmes and nothing else:
  # every distinct amount in it is one the GME release published.
  gme <- cand[cand$disposition == "NOT_RHTP_STATE_PROGRAM", ]
  stray <- setdiff(round(unique(gme$amount_announced)),
                   round(c(NV_GME_AWARDS$amount, 2995893)))
  if (length(stray)) {
    stop("[NV] the NOT_RHTP_STATE_PROGRAM group carries amount(s) the GME ",
         "release does not publish: ", paste(stray, collapse = ", "),
         call. = FALSE)
  }
  # And the RHTP pool group must be exactly the three pool totals plus the
  # budget-template line.
  pool <- cand[cand$disposition == "RHTP_BUT_NOT_A_SUBAWARD", ]
  expect_pool <- c(NV_STATED$wrrap_rr_awarded, NV_STATED$wrrap_at_awarded,
                   NV_STATED$wrrap_residency, 40000)
  stray2 <- setdiff(round(unique(pool$amount_announced)), round(expect_pool))
  if (length(stray2)) {
    stop("[NV] the RHTP_BUT_NOT_A_SUBAWARD group carries unexpected amount(s): ",
         paste(stray2, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

#' The §0.1 headline: what an extractor built from the candidate list would
#' have published, and how much of it is state money.
nv_candidate_inflation <- function() {
  cand <- nv_classify_candidates()
  list(
    candidates = nrow(cand),
    face_value = sum(cand$amount_announced, na.rm = TRUE),
    state_money = sum(cand$amount_announced[
      cand$disposition == "NOT_RHTP_STATE_PROGRAM"], na.rm = TRUE),
    tier2 = sum(cand$amount_announced[
      cand$disposition == "RHTP_BUT_NOT_A_SUBAWARD"], na.rm = TRUE),
    real_awards = sum(cand$disposition == "RHTP_SUBAWARD_IN_FILE"),
    real_award_amount = sum(cand$amount_announced[
      cand$disposition == "RHTP_SUBAWARD_IN_FILE"], na.rm = TRUE),
    gme_distinct_total = NV_GME_TOTAL,
    published_awards = NV_STATED$roster_rows,
    rcj_coverage_pct = 100 * sum(cand$disposition == "RHTP_SUBAWARD_IN_FILE") /
      NV_STATED$roster_rows
  )
}


# -- validate / build / report ------------------------------------------------

#' Session 49's verification overlay names a row INDEX and a recipient NAME
#' for every row it re-types in this file. Both must still agree.
#'
#' `vq_overlay()` writes by index and never checks the name, so a re-extraction
#' that shifted one row would silently move a verified hospital type onto the
#' wrong recipient. That is why rows 1..72 keep the 2026-08-31 order and every
#' new row is appended; this is the assertion that the order held.
nv_assert_overlay_rows_aligned <- function(recs) {
  path <- here::here("data", "reference", "verification_queue_2_changes.csv")
  if (!file.exists(path)) return(invisible(TRUE))
  ch <- suppressMessages(readr::read_csv(path,
          col_types = readr::cols(.default = "c"), progress = FALSE))
  ch <- ch[ch$file == "nv_year1_awardees.csv", ]
  idx <- as.integer(ch$row)
  bad <- idx > nrow(recs) | recs$awardee[pmin(idx, nrow(recs))] != ch$name
  if (any(bad)) {
    stop("[NV] session 49's overlay names row(s) ",
         paste0(idx[bad], " = '", ch$name[bad], "'", collapse = "; "),
         " and the file now carries something else there. Row order has ",
         "shifted; the overlay would re-type the wrong recipient.",
         call. = FALSE)
  }
  invisible(TRUE)
}

nv_validate <- function() {
  recs <- nv_records()

  if (nrow(recs) != NV_STATED$total_rows) {
    stop("[NV] ", nrow(recs), " rows, not ", NV_STATED$total_rows, ".",
         call. = FALSE)
  }
  by_pool <- table(recs$award_pool[!recs$withdrawn])
  expect <- stats::setNames(NV_POOLS$round_awards, NV_POOLS$award_pool)
  for (p in names(expect)) {
    if (!identical(as.integer(by_pool[[p]]), as.integer(expect[[p]]))) {
      stop("[NV] pool ", p, " has ", by_pool[[p]], " current rows, not ",
           expect[[p]], ".", call. = FALSE)
    }
  }
  if (sum(!recs$withdrawn) != NV_STATED$roster_rows ||
      sum(recs$withdrawn) != NV_STATED$withdrawn_rows) {
    stop("[NV] ", sum(!recs$withdrawn), " current and ", sum(recs$withdrawn),
         " withdrawn rows, not ", NV_STATED$roster_rows, " and ",
         NV_STATED$withdrawn_rows, ".", call. = FALSE)
  }
  if (sum(recs$award_pool == "FLEX_FUND" & recs$listed_from == "2026-08-31") !=
      NV_STATED$flex_rows_first_round) {
    stop("[NV] the Flex Fund's first-round rows no longer number ",
         NV_STATED$flex_rows_first_round, ".", call. = FALSE)
  }
  # SESSION 49's OVERLAY IS KEYED ON ROW INDEX. Every index it names must still
  # hold the recipient it names, or the overlay writes one organisation's
  # verified type onto another's row.
  nv_assert_overlay_rows_aligned(recs)

  # THE CENTRAL INVARIANT. Nevada publishes no per-recipient amount, so the
  # column is empty on every row and sums to zero. A non-empty `amount` here
  # means either the source changed or something invented a figure.
  if (!all(is.na(recs$amount))) {
    stop("[NV] ", sum(!is.na(recs$amount)), " row(s) carry an `amount`. ",
         "NVHA publishes none, and §6.2 forbids dividing a round total.",
         call. = FALSE)
  }

  nv_assert_cms_notice_of_award()
  nv_assert_footer_is_not_provenance()
  nv_assert_gme_is_state_money(recs)
  nv_assert_rfas_postdate_noa()
  nv_assert_award_index()
  nv_assert_pending_not_awarded()
  nv_assert_flex_round()
  nv_assert_wrrap_rounds()
  nv_assert_no_per_recipient_amounts()
  nv_assert_zero_dollars_is_not_zero_hospitals(recs)
  nv_assert_name_variants_unresolved(recs)
  nv_assert_candidate_disposition()
  nv_assert_form_not_stated_queued(recs)
  rec <- nv_reconcile(recs)

  message("[NV] OK -- ", nrow(recs), " rows across ", nrow(rec$pools),
          " rounds; $", format(rec$total, big.mark = ","), " announced (",
          round(rec$pct_of_allotment, 1), "% of allotment); ",
          "sum(amount) = 0 by design.")
  invisible(recs)
}

#' The §8 leading-19 schema, then Nevada's own appended fields.
NV_COLUMN_ORDER <- c(
  "state", "row_no", "awardee", "amount", "recipient_type",
  "distributed_to_hospital", "note", "recipient_confirmed", "amount_confirmed",
  "fiscal_year", "source_document_title", "state_source_url",
  "validation_source_type", "extraction_method", "validator", "ccn", "aha_id",
  "rural_designation", "reviewer", "recipient_type_source",
  "determination_confidence", "flag_reason", "award_pool", "budget_period",
  "flow_type", "hospital_benefiting", "hospital_attribution",
  "intermediary_name", "determination_basis", "amount_basis", "county",
  "project_description",
  "round_id", "round_name", "round_awards", "round_amount", "initiative",
  "initiative_fund_use", "source_archive_path", "service_area", "row_in_pool",
  # Session 64: which accordion section of NVHA's page the row sits under, and
  # which snapshot first listed it (2026-08-31 or 2026-09-24).
  "section", "listed_from"
)

#' The builder's output WITH session 49's verification overlay applied.
#'
#' The overlay is keyed on (file, row index), so it is applied here, to this
#' one file, by `vq_overlay()` -- never by a bare `R/03ap --apply`, which
#' re-derives its plan from already-overlaid files (session 52). The overlay's
#' own index/name pairing is asserted first (nv_assert_overlay_rows_aligned).
nv_with_overlay <- function(recs = nv_records()) {
  vq <- new.env()
  suppressMessages(source(here::here("R", "03ap_verification_queue_2.R"),
                          local = vq))
  nv_assert_overlay_rows_aligned(recs)
  out <- recs %>%
    dplyr::select(dplyr::all_of(NV_COLUMN_ORDER)) %>%
    dplyr::arrange(.data$row_no)
  out <- vq$vq_overlay(out, "nv_year1_awardees.csv")
  # SESSION 71: §10.2's enrolled-hospital-operator rule (Carson Valley Health /
  # Washoe Barton Medical Clinic, CCN 291306), after session 49's overlay.
  s71 <- new.env()
  suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                          local = s71))
  s71$s71_overlay(out, "nv_year1_awardees.csv")
}

nv_build <- function() {
  recs <- nv_validate()
  out <- nv_with_overlay(recs)
  # SESSION 101: the BP1 report prices the file and adds eleven lines.
  out <- nv_apply_bp1(out)
  # SESSION 102: the owner's NV_BP1_FOLLOWUPS rulings.
  out <- nv_apply_s102_rulings(out)
  readr::write_csv(out, NV_OUT_CSV, na = "")
  message("[NV] wrote ", NV_OUT_CSV, " (", nrow(out), " rows)")

  disp <- nv_disposition_table()
  readr::write_csv(disp, NV_DISPOSITION_CSV, na = "")
  message("[NV] wrote ", NV_DISPOSITION_CSV, " (", nrow(disp), " rows)")

  nv_write_workbook(out, disp)
  invisible(out)
}


#' The review-queue row, its rows and its $0 dollar effect -- asserted, not
#' merely written once (Maryland's, Nebraska's and Oklahoma's convention).
nv_assert_form_not_stated_queued <- function(recs = NULL) {
  if (is.null(recs)) recs <- nv_records()
  q <- readr::read_csv(
    here::here("data", "reference", "classification_review_queue.csv"),
    show_col_types = FALSE, progress = FALSE)
  row <- q[q$question_id == "NV_RECIPIENT_FORM_NOT_STATED", ]
  if (nrow(row) != 1L) {
    stop("[NV] NV_RECIPIENT_FORM_NOT_STATED is not in ",
         "classification_review_queue.csv exactly once.", call. = FALSE)
  }
  # The queue row was written about the 2026-08-31 file, so it is checked
  # against the rows that file carried. The 2026-09-24 rows on the fallback are
  # a NEW question (session 64 proposes it; this session could not write the
  # queue) and are counted by nv_report(), not here.
  soft <- recs[stringr::str_detect(recs$flag_reason, "RECIPIENT_TYPE_INFERRED") &
                 recs$listed_from == "2026-08-31", ]
  if (!stringr::str_detect(row$row_key, paste0("^", nrow(soft), " rows"))) {
    stop("[NV] the queue row says '", row$row_key, "' but the file carries ",
         nrow(soft), " rows on §8's fallback.", call. = FALSE)
  }
  # THE ONE-DIRECTIONAL PART OF OKLAHOMA'S ROW HAS NO ANALOGUE HERE, AND THAT
  # IS THE POINT: with no amounts published, the question is worth $0 whichever
  # way it goes. If any fallback row ever acquires an amount, the queue row's
  # stated dollar effect becomes false.
  if (!all(is.na(soft$amount))) {
    stop("[NV] a §8-fallback row now carries an amount, so the queue row's ",
         "'$0 in either direction' is no longer true.", call. = FALSE)
  }
  if (!stringr::str_detect(row$dollar_effect, stringr::fixed("$0 in either direction"))) {
    stop("[NV] the queue row no longer states the $0 dollar effect.",
         call. = FALSE)
  }
  invisible(TRUE)
}


# -- workbook -----------------------------------------------------------------

nv_write_workbook <- function(out, disp) {
  wb <- openxlsx::createWorkbook()

  hosp <- sum(out$hospital_attribution == "NAMED_HOSPITAL")
  soft <- sum(grepl("RECIPIENT_TYPE_INFERRED", out$flag_reason))
  warning_sheet <- tibble::tibble(
    `READ THIS FIRST` = c(
      "NEVADA PUBLISHES A COMPLETE, NAMED RECIPIENT ROSTER WITH NO AMOUNTS ON IT.",
      "",
      paste0("The `amount` column is EMPTY ON ALL ", nrow(out),
             " ROWS and sums to $0. That is not a"),
      "parse failure and it is NOT a claim that Nevada awarded nothing. It is the",
      "honest total of what the Nevada Health Authority has published PER",
      "RECIPIENT, which is nothing at all.",
      "",
      paste0("NEVADA HAS ", hosp, " NAMED-HOSPITAL AWARD ACTIONS AND $0 OF ",
             "NAMED-HOSPITAL DOLLARS."),
      "Both are true. READ THE ROW COUNT -- taking the 0 and not the count gives",
      "the exact opposite of what NVHA has published.",
      "",
      "SESSION 64: NVHA's page (2026-09-24) carries SEVEN sections and 155 award",
      "actions: Flex 39, WRRAP Recruitment and Retention 26, Apprenticeship and",
      "Training 20, Medical Residency 4, RHIT 24, RHOAP 36, Tribal 6. Rows 1-72",
      "are the 2026-08-31 page's rows in its order (session 49's overlay is keyed",
      "on that order); later rows are new. '93 X 95 NV' (row 48) was on the",
      "2026-08-31 page and is NOT on the 2026-09-24 page; it is kept, Unclear.",
      "",
      "ROUND TOTALS NVHA HAS PUBLISHED (never per recipient):",
      "  Rural Health System Flex Fund, first round   $36,000,000  (25 rows)",
      "  WRRAP - Recruitment and Retention Fund       $32,300,000",
      "  WRRAP - Apprenticeship and Training Fund     $14,300,000",
      "  WRRAP - Rural Medical Residency              $ 4,800,000",
      "                                               -----------",
      "                                               $87,400,000",
      "NO ROUND TOTAL is published for RHIT, RHOAP, Tribal, or the 14 Flex rows",
      "first listed after 2026-08-31; their `round_amount` is empty.",
      "",
      "`round_amount` REPEATS ITS ROUND'S TOTAL ON EVERY ROW OF THAT ROUND.",
      "Summing the column overstates Nevada ~24-fold. Sum DISTINCT rounds",
      "instead -- nv_reconcile() does it correctly.",
      "",
      "TWO NVHA DOCUMENTS DISAGREE ABOUT WHICH WRRAP FUND GOT $32.3M AND WHICH",
      "GOT $14.3M; both WRRAP rosters carry POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES.",
      "THE COMBINED WRRAP WORKFORCE FIGURE IS ~$46.6M EITHER WAY.",
      "",
      "THE NINE GME AWARDS ARE NOT IN THIS FILE AND MUST NOT BE ADDED TO IT.",
      "They are STATE GENERAL FUND money ($15,755,068, 2026-07-22).",
      "",
      paste0(soft, " rows carry §8's standing fallback (NONPROFIT_CBO + LOW):"),
      "NVHA states no recipient's organisational form. Nothing was promoted (§0.4)."))

  openxlsx::addWorksheet(wb, "READ THIS FIRST")
  openxlsx::writeData(wb, "READ THIS FIRST", warning_sheet)
  openxlsx::setColWidths(wb, "READ THIS FIRST", 1, 96)

  openxlsx::addWorksheet(wb, "Awards")
  openxlsx::writeData(wb, "Awards", out)

  rec <- nv_reconcile(nv_records())
  openxlsx::addWorksheet(wb, "Reconciliation")
  openxlsx::writeData(wb, "Reconciliation", rec$pools)

  openxlsx::addWorksheet(wb, "RCJ disposition")
  openxlsx::writeData(wb, "RCJ disposition", disp)

  openxlsx::saveWorkbook(wb, NV_XLSX, overwrite = TRUE)
  message("[NV] wrote ", NV_XLSX)
  invisible(NV_XLSX)
}


# -- report -------------------------------------------------------------------

nv_report <- function() {
  recs <- nv_records()
  rec <- nv_reconcile(recs)
  part <- rhtp_hospital_dollar_partition(recs)
  inf <- nv_candidate_inflation()
  named <- part[part$bucket == "NAMED_HOSPITAL", ]
  soft <- recs[stringr::str_detect(recs$flag_reason, "RECIPIENT_TYPE_INFERRED"), ]

  cat("\nNEVADA -- RHTP Year 1\n"); cat(strrep("=", 74), "\n")
  # SESSIONS 101-102: the BP1 report prices the file. PUBLISHED figures leave
  # the SOURCE_SUSPECT rows out (owner ruling, session 102); the with-suspect
  # figure is INTERNAL and printed only beside it.
  bp <- nv_bp1_partition()   # the committed, priced file
  fmt_part <- function(p) paste0(p$bucket, " ", p$rows, " / $",
                                 formatC(p$dollars, format = "f", digits = 2,
                                         big.mark = ","), collapse = "; ")
  cat("PRICED FROM NVHA's BP1 SUBRECIPIENT REPORT (2026-10-13), AMOUNT_PRELIMINARY.\n")
  cat("  PUBLISHED (no SOURCE_SUSPECT rows): ", fmt_part(bp$without), "\n", sep = "")
  cat("  INTERNAL  (with ", nrow(bp$suspect_rows), " SOURCE_SUSPECT rows): ",
      fmt_part(bp$with), "\n", sep = "")
  cat("  The narrative below predates the BP1 report (session 64).\n\n")
  cat("A COMPLETE, NAMED RECIPIENT ROSTER WITH NO AMOUNTS ON IT.\n\n")

  cat("Announced by pool (NEVER per recipient):\n")
  print(as.data.frame(rec$pools[, c("round_name", "round_amount")]),
        row.names = FALSE, right = FALSE)
  cat("\n  Total announced: $", format(rec$total, big.mark = ","),
      "  (", round(rec$pct_of_allotment, 1), "% of the $",
      format(rhtp_nv_allotment(), big.mark = ","), " allotment)\n", sep = "")
  cat("  Summing `round_amount` down the column instead gives $",
      format(rec$naive_column_sum, big.mark = ","),
      " -- Georgia's trap.\n", sep = "")

  cat("\nsum(amount) = $", format(sum(recs$amount, na.rm = TRUE)),
      "  ON ALL ", nrow(recs), " ROWS, BY DESIGN.\n", sep = "")
  cat("  NVHA publishes no per-recipient figure and §6.2 forbids dividing a\n")
  cat("  round total, so the column is empty rather than invented.\n")

  cat("\nHOSPITALS -- A COUNT, NOT A DOLLAR FIGURE\n")
  cat(strrep("-", 74), "\n")
  cat("  NAMED_HOSPITAL: ", named$rows, " award actions   $",
      format(named$dollars), "\n", sep = "")
  cat("  ", dplyr::n_distinct(recs$awardee[recs$hospital_attribution ==
        "NAMED_HOSPITAL"]), " distinct hospital NAMES (an upper bound on\n",
      "  organisations: NVHA publishes 'Desert View Hospital' and 'DVH\n",
      "  Hospital Alliance LLN dba Desert View Hospital' as separate rows,\n",
      "  and §2 forbids a machine merging them).\n", sep = "")
  cat("\n  READ THE ROW COUNT, NOT THE ZERO. Nevada named ", named$rows,
      " hospital award\n", sep = "")
  cat("  actions and published a dollar figure for none of them. A reader who\n")
  cat("  quotes the $0 reports the opposite of what NVHA has published.\n")

  cat("\nRECIPIENT FORM NOT STATED BY NVHA: ", nrow(soft), " rows\n", sep = "")
  cat("  Kansas's, Maryland's, Nebraska's and Oklahoma's shape a FIFTH time --\n")
  cat("  and the first worth $0 in either direction, because there are no\n")
  cat("  amounts for it to move. Renown Health, Carson Valley Health and\n")
  cat("  Intermountain Health are inside it. Nothing promoted (§0.4);\n")
  cat("  queued as NV_RECIPIENT_FORM_NOT_STATED.\n")

  cat("\n§6.2 PROVENANCE -- THE STRONGEST FORM IN THIS REPOSITORY\n")
  cat(strrep("-", 74), "\n")
  cat("  Nevada publishes CMS's own Notice of Award. Not a footer quoting the\n")
  cat("  award -- the award: recipient 'Nevada Health Authority', award\n")
  cat("  ", NV_CMS_AWARD_NUMBER, ", Assistance Listing ", NV_ASSISTANCE_LISTING,
      " 'Rural Health\n", sep = "")
  cat("  Transformation Program', 12/29/2025 - 10/30/2026, $",
      format(NV_CMS_AWARD_AMOUNT, big.mark = ",", nsmall = 2), ".\n", sep = "")
  cat("  That rounds to the §7.1 anchor's $",
      format(rhtp_nv_allotment(), big.mark = ","),
      " exactly, and its date is\n  the 2025-12-29 anchor exactly.\n", sep = "")

  cat("\nAND THE FOOTER ALONE IS NOT A PROVENANCE TEST -- NEVADA IS WHERE\n")
  cat("THAT BREAKS.\n")
  cat("  NVHA's workforce publication carries the CMS financial-assistance\n")
  cat("  footer ON EVERY PAGE and describes THREE programmes side by side:\n")
  cat("    GME    -> 'Source: State General Fund'          NOT RHTP\n")
  cat("    WRRAP  -> CMS RHT Grant ", NV_CMS_AWARD_NUMBER, "   RHTP\n", sep = "")
  cat("    SHARP  -> 'SB5 one-time bill appropriation'     NOT RHTP\n")
  cat("  A check keyed on 'does this document carry the CMS footer' answers\n")
  cat("  YES for all three and is wrong for two. Oklahoma's footer was on a\n")
  cat("  ROSTER and covered what was on it; Nevada's is on a COMPARISON\n")
  cat("  DOCUMENT and covers only the publishing.\n")

  cat("\n§0.1 -- WHAT RCJ'S ", inf$candidates, " NEVADA CANDIDATES ACTUALLY ARE\n", sep = "")
  cat(strrep("-", 74), "\n")
  print(as.data.frame(nv_disposition_table()[, c("rcj_rows", "rcj_amount_sum",
                                                 "disposition")]),
        row.names = FALSE, right = FALSE)
  cat("\n  At face value the candidate list publishes $",
      format(inf$face_value, big.mark = ","), " as Nevada's\n", sep = "")
  cat("  Tier 3 subawards. Of that, $", format(inf$state_money, big.mark = ","),
      " is STATE GENERAL FUND money --\n", sep = "")
  cat("  the nine GME residency awards ($",
      format(inf$gme_distinct_total, big.mark = ",", nsmall = 2),
      " distinct, carried twice by\n", sep = "")
  cat("  RCJ under two titles) -- and $", format(inf$tier2, big.mark = ","),
      " is Tier 2 pool totals.\n", sep = "")
  cat("\n  RCJ HOLDS ", inf$real_awards, " OF NEVADA'S ", inf$published_awards,
      " PUBLISHED AWARD ACTIONS (",
      round(inf$rcj_coverage_pct, 1), "%), EVERY\n", sep = "")
  cat("  ONE AT AN AMOUNT OF $1, mined out of a steering-committee deck whose\n")
  cat("  AGENDA SLIDE it captured as the document title (Nebraska's defect).\n")

  cat("\n  Texas's defect was the wrong PROGRAMME; Oregon's the wrong RECIPIENT\n")
  cat("  CLASS; Indiana's an INVENTED label; Oklahoma's the wrong TIER.\n")
  cat("  NEVADA'S IS ALL THREE OF THE OTHERS AT ONCE, IN ONE CANDIDATE SET --\n")
  cat("  17 rows of the wrong programme, 7 of the wrong tier, and 10 real\n")
  cat("  awards whose amounts are placeholders.\n")

  cat("\nTHE WRRAP POOL CONFLICT, UNRESOLVED\n")
  cat(strrep("-", 74), "\n")
  cat("  2026-06-09 fiscal deck:  R&R $",
      format(NV_STATED$deck_rr_available, big.mark = ","), " available   A&T $",
      format(NV_STATED$deck_at_available, big.mark = ","), " available\n", sep = "")
  cat("  2026-07-29 press release: R&R $",
      format(NV_STATED$wrrap_rr_awarded, big.mark = ","), " awarded     A&T $",
      format(NV_STATED$wrrap_at_awarded, big.mark = ","), " awarded\n", sep = "")
  cat("  The pairing in the deck was checked against the PDF's own GLYPH\n")
  cat("  POSITIONS, so it is the source and not the parse.\n")
  cat("  COMBINED, THE TWO ARE STABLE: $",
      format(NV_WRRAP_COMBINED_DECK, big.mark = ","), " available vs $",
      format(NV_WRRAP_COMBINED_PRESS, big.mark = ","), " awarded --\n", sep = "")
  cat("  a reallocation between the sub-funds would explain it exactly, and\n")
  cat("  THAT INFERENCE IS NOT PUBLISHED AS A FINDING (§0.4).\n")

  invisible(recs)
}


# -- the BP1 Subrecipient Report (session 101) ----------------------------------
#
# NEVADA HAS PRICED ITS ROSTER. NVHA's "RHTP Subrecipient Report for BP1"
# (24 pp., PDF created 2026-10-12, Last-Modified 2026-10-13, linked from the
# Funded Projects page as "Subrecipient Report for BP1") gives every
# subrecipient a "Funding Requested" and a "BP1 Amount Awarded" figure, in TEN
# sections that each end in a printed TOTALS row. It is PROVISIONAL, in NVHA's
# own words: "Note: The following list of subaward amounts may not be final as
# project budgets continue to be refined for CMS approval at the time of this
# writing (early October 2026)." Every priced row carries AMOUNT_PRELIMINARY
# (session 101 coded it PROVISIONAL_SOURCE; collapsed in session 102, see
# NV_S102 below).
#
# HOW IT IS READ. The report is one Word table per section with wrapped cells.
# This project's own run reader gives the right x for the FIRST run of a line
# and not for the runs after it on this producer (Adobe PDF Library 26), so
# the columns cannot be told apart from it. The table was therefore parsed ONCE
# from poppler's `pdftotext -bbox` word boxes (`nv_bp1_parse_bbox()`, CLI
# `--parse-bp1`) into `nv_bp1_subrecipient_report.csv`, which is COMMITTED.
# Every cell is assigned to its row by a contiguous partition that keeps each
# cell centred on its own dollar line (Word centres them). The parse checks
# itself: every one of the ten sections' line items sums to that section's
# printed TOTALS row, in both columns, to the cent. `nv_assert_bp1()` then
# re-checks the committed CSV against the PDF with THIS project's reader, so
# nothing downstream (no test, no Routine) needs poppler.
#
# TWO SOURCE DEFECTS ARE CARRIED AS PUBLISHED AND FLAGGED SOURCE_SUSPECT.
# Nothing is corrected (owner, session 101):
#   FLEX  Washoe Barton Medical Clinic, NEMT van: requested $245,800.00,
#         awarded $2,458,060.00 -- ten times the request, the shape of a
#         shifted decimal. NVHA's own FLEX TOTALS row ($58,231,228.10)
#         INCLUDES the $2,458,060.00, so the total carries it too.
#   FLEX  Northeastern Nevada Regional Hospital: requested $103,725,086.00,
#         awarded $997,361.00. The request is larger than the whole FLEX
#         pool ($35.9M published); NVHA's requested TOTALS row includes it.
NV_BP1_KEY <- "bp1_report"
NV_BP1_CSV <- here::here("data", "reference", "nv_bp1_subrecipient_report.csv")
NV_BP1_SHA256 <- "34c74ae656de8f2de21208532d2c0d20603d95deae29b150950b793fc2de7b1c"
NV_BP1_PROVISIONAL <- paste(
  "Note: The following list of subaward amounts may not be final as project",
  "budgets continue to be refined for CMS approval at the time of this",
  "writing (early October 2026).")
NV_BP1_SECTIONS <- tibble::tribble(
  ~bp1_section,  ~award_pool,                       ~heading,                                                  ~tot_requested,  ~tot_awarded, ~lines,
  "RHOAP",       "RHOAP",                           "Rural Health Outcome Accelerator Program (RHOAP)",        25316892.89,  25140201.68, 37L,
  "FLEX",        "FLEX_FUND",                       "Nevada Rural Health System Flex Fund (FLEX)",             162240429.06, 58231228.10, 40L,
  "WRRAP_RR",    "WRRAP_RECRUITMENT_RETENTION",     "WRRAP: Provider Recruitment and Retention (R+R)",         25371642.89,  37332720.00, 20L,
  "WRRAP_AT",    "WRRAP_APPRENTICESHIP_TRAINING",   "WRRAP: Provider Apprenticeship and Training Program (A+T)", 14429707.29, 13567720.49, 20L,
  "WRRAP_RWP",   "WRRAP_RURAL_MEDICAL_RESIDENCY",   "WRRAP: Rural Workforce Projects (RWP)",                   4840570.00,   4657320.16,  4L,
  "RHIT",        "RHIT",                            "Rural Health Innovation and Technology (RHIT)",           24511364.00,  24594701.62, 26L,
  "TRIBAL",      "TRIBAL",                          "Rural Tribal Health Transformation",                      11853377.00,  8095961.77,  6L,
  "VETERANS",    "VETERANS",                        "Rural Veterans Health Transformation",                    2382927.00,   1271512.04,  1L,
  "CORRECTIONS", "CORRECTIONS",                     "Rural Corrections Health Transformation",                 976255.00,    976255.00,   1L,
  "PFT",         "PRESIDENTIAL_FITNESS_TEST",       "Presidential Fitness Test Implementation",                1364228.00,   1377413.00,  2L
)
NV_BP1_TOTAL_AWARDED <- 175245033.86
NV_BP1_LINES <- 157L
# The two defects, by line id. The partition is reported with and without them.
NV_BP1_SOURCE_SUSPECT <- tibble::tribble(
  ~bp1_line_id, ~why,
  "FLEX-28", paste("SOURCE_SUSPECT: requested $103,725,086.00 against $997,361.00",
                   "awarded; the request exceeds the whole FLEX pool ($35.9M",
                   "published). Carried as published; nothing corrected."),
  "FLEX-36", paste("SOURCE_SUSPECT: requested $245,800.00, awarded $2,458,060.00,",
                   "ten times the request (a shifted decimal is the likely",
                   "shape). NVHA's FLEX TOTALS row includes the $2,458,060.00.",
                   "Carried as published; nothing corrected.")
)

#' Parse the report from poppler word boxes. ONE-TIME; writes NV_BP1_CSV.
#'
#' Needs `pdftotext` (poppler) on the PATH and refuses without it. Nothing
#' else in this file calls it: the committed CSV is the extraction source.
nv_bp1_parse_bbox <- function(pdf = nv_path(NV_BP1_KEY), write = TRUE) {
  if (!nzchar(Sys.which("pdftotext"))) {
    stop("[NV] --parse-bp1 needs poppler's pdftotext; the committed ",
         "nv_bp1_subrecipient_report.csv is the extraction source otherwise.",
         call. = FALSE)
  }
  html <- tempfile(fileext = ".html")
  on.exit(unlink(html), add = TRUE)
  rc <- system2("pdftotext", c("-bbox", shQuote(pdf), shQuote(html)))
  if (!identical(as.integer(rc), 0L)) stop("[NV] pdftotext failed.", call. = FALSE)
  doc <- xml2::read_html(html)
  words <- purrr::imap_dfr(xml2::xml_find_all(doc, "//page"), function(p, i) {
    w <- xml2::xml_find_all(p, ".//word")
    tibble::tibble(page = i,
                   x0 = as.numeric(xml2::xml_attr(w, "xmin")),
                   y0 = as.numeric(xml2::xml_attr(w, "ymin")),
                   x1 = as.numeric(xml2::xml_attr(w, "xmax")),
                   y1 = as.numeric(xml2::xml_attr(w, "ymax")),
                   text = xml2::xml_text(w))
  }) %>%
    dplyr::mutate(yc = (.data$y0 + .data$y1) / 2) %>%
    dplyr::filter(.data$y0 < 740)            # the letterhead footer
  money <- "^\\$[0-9]{1,3}(,[0-9]{3})*\\.[0-9]{2}$"

  # Lines of one column inside one table region.
  col_lines <- function(w) {
    if (!nrow(w)) return(tibble::tibble(y0 = numeric(0), y1 = numeric(0),
                                        yc = numeric(0), text = character(0)))
    w %>% dplyr::arrange(.data$yc) %>%
      dplyr::mutate(lg = cumsum(c(1, diff(.data$yc) > 2))) %>%
      dplyr::group_by(.data$lg) %>%
      dplyr::summarise(y0 = min(.data$y0), y1 = max(.data$y1),
                       yc = mean(.data$yc),
                       text = paste(.data$text[order(.data$x0)], collapse = " "),
                       .groups = "drop") %>%
      dplyr::arrange(.data$yc)
  }
  # CONTIGUOUS PARTITION of a column's lines into one group per anchor,
  # minimising each group's squared distance from its anchor (cells are
  # vertically centred). `allow_empty` lets a column skip a row.
  partition <- function(lines, ay, allow_empty = FALSE) {
    n <- nrow(lines); m <- length(ay)
    if (!n) return(rep(NA_character_, m))
    if (!allow_empty && n < m) stop("[NV] fewer cell lines than rows.", call. = FALSE)
    ctr <- function(k, l) (min(lines$y0[k:l]) + max(lines$y1[k:l])) / 2
    INF <- 1e18
    D <- matrix(INF, n + 1, m + 1); B <- matrix(NA_integer_, n + 1, m + 1)
    D[1, 1] <- 0
    for (j in seq_len(m)) for (l in 0:n) {
      if (allow_empty && D[l + 1, j] < D[l + 1, j + 1]) {
        D[l + 1, j + 1] <- D[l + 1, j]; B[l + 1, j + 1] <- l + 1L
      }
      if (l >= 1) for (k in 1:l) {
        v <- D[k, j] + (ctr(k, l) - ay[j])^2
        if (v < D[l + 1, j + 1]) { D[l + 1, j + 1] <- v; B[l + 1, j + 1] <- k }
      }
    }
    out <- rep(NA_character_, m); l <- n
    for (j in m:1) {
      k <- B[l + 1, j + 1]
      if (k <= l) out[j] <- paste(lines$text[k:l], collapse = " ")
      l <- k - 1L
    }
    if (l != 0L) stop("[NV] the partition left lines unassigned.", call. = FALSE)
    out
  }

  out <- list(); sec_i <- 1L; in_table <- FALSE
  for (pg in sort(unique(words$page))) {
    w <- words[words$page == pg, ]
    hdr <- w[w$text %in% c("Request", "Requested"), ]
    tot <- w[w$text == "TOTALS", ]
    d <- w[stringr::str_detect(w$text, money), ] %>% dplyr::arrange(.data$yc)
    if (!nrow(d)) next
    d$grp <- cumsum(c(1, diff(d$yc) > 2))
    multi <- as.integer(names(which(table(d$grp) >= 2)))
    if (!length(multi)) next
    anchors <- d[d$grp %in% multi, ] %>% dplyr::group_by(.data$grp) %>%
      dplyr::summarise(yc = mean(.data$yc), req_x = min(.data$x0),
                       awd_x1 = max(.data$x1),
                       req = .data$text[order(.data$x0)][1],
                       awd = .data$text[order(.data$x0)][2], .groups = "drop")
    events <- dplyr::bind_rows(
      tibble::tibble(y = hdr$y0, kind = rep("H", nrow(hdr))),
      tibble::tibble(y = tot$yc, kind = rep("T", nrow(tot)))) %>%
      dplyr::arrange(.data$y)
    regions <- list(); start <- if (in_table) 0 else NA_real_
    for (k in seq_len(nrow(events))) {
      if (events$kind[k] == "H") {
        # The header is three lines; its last ends ~14pt below "Request(ed)".
        start <- max(if (is.na(start)) -Inf else start, events$y[k] + 14)
        in_table <- TRUE
      } else {
        regions[[length(regions) + 1L]] <- list(top = start,
                                                bot = events$y[k] + 3,
                                                closed = TRUE)
        start <- NA_real_; in_table <- FALSE
      }
    }
    if (in_table && !is.na(start)) {
      regions[[length(regions) + 1L]] <- list(top = start, bot = 740,
                                              closed = FALSE)
    }
    for (rg in regions) {
      a <- anchors[anchors$yc >= rg$top - 3 & anchors$yc <= rg$bot, ]
      if (!nrow(a)) next
      a$is_total <- rg$closed & abs(a$yc - (rg$bot - 3)) < 1
      reqx <- min(a$req_x)
      # THE APPLICANT COLUMN ONLY. Service area and project description are
      # not parsed: Word centres each header over its column, so a header's x
      # is not the column's edge, and a wrong cut would commit wrong text.
      inreg <- w[w$yc >= rg$top - 2 & w$yc <= rg$bot + 0.5 &
                   w$text != "TOTALS" & w$x1 < reqx - 2, ]
      ia <- which(!a$is_total)
      a$applicant <- NA_character_
      a$applicant[ia] <- partition(col_lines(inreg), a$yc[ia])
      a$page <- pg
      a$bp1_section <- NV_BP1_SECTIONS$bp1_section[sec_i]
      out[[length(out) + 1L]] <- a
      if (rg$closed) sec_i <- sec_i + 1L
    }
  }
  num <- function(x) as.numeric(gsub("[$,]", "", x))
  res <- dplyr::bind_rows(out) %>%
    dplyr::transmute(
      bp1_section = .data$bp1_section, page = .data$page,
      applicant = dplyr::if_else(.data$is_total, "TOTALS", .data$applicant),
      funding_requested = num(.data$req), bp1_amount_awarded = num(.data$awd),
      is_total = .data$is_total) %>%
    dplyr::group_by(.data$bp1_section) %>%
    dplyr::mutate(bp1_line_id = dplyr::if_else(
      .data$is_total, paste0(.data$bp1_section, "-TOTALS"),
      sprintf("%s-%02d", .data$bp1_section, cumsum(!.data$is_total)))) %>%
    dplyr::ungroup() %>%
    dplyr::relocate("bp1_line_id")
  nv_assert_bp1_table(res)
  if (write) {
    readr::write_csv(res, NV_BP1_CSV, na = "")
    message("[NV] wrote ", NV_BP1_CSV, " (", sum(!res$is_total), " lines + ",
            sum(res$is_total), " TOTALS rows)")
  }
  invisible(res)
}

#' The committed report table.
nv_bp1_table <- function() {
  readr::read_csv(NV_BP1_CSV, show_col_types = FALSE, progress = FALSE,
                  col_types = readr::cols(.default = "c")) %>%
    dplyr::mutate(page = as.integer(.data$page),
                  funding_requested = as.numeric(.data$funding_requested),
                  bp1_amount_awarded = as.numeric(.data$bp1_amount_awarded),
                  is_total = as.logical(.data$is_total))
}

#' The table's own arithmetic: each section's lines against its TOTALS row,
#' and both against the figures recorded in NV_BP1_SECTIONS.
nv_assert_bp1_table <- function(t = nv_bp1_table()) {
  for (i in seq_len(nrow(NV_BP1_SECTIONS))) {
    s <- NV_BP1_SECTIONS[i, ]
    x <- t[t$bp1_section == s$bp1_section, ]
    lines <- x[!x$is_total, ]; tot <- x[x$is_total, ]
    if (nrow(tot) != 1L || nrow(lines) != s$lines) {
      stop("[NV] BP1 section ", s$bp1_section, ": ", nrow(lines), " lines and ",
           nrow(tot), " TOTALS rows, not ", s$lines, " and 1.", call. = FALSE)
    }
    for (col in c("funding_requested", "bp1_amount_awarded")) {
      want <- if (col == "funding_requested") s$tot_requested else s$tot_awarded
      if (abs(sum(lines[[col]]) - tot[[col]]) >= 0.005 ||
          abs(tot[[col]] - want) >= 0.005) {
        stop("[NV] BP1 section ", s$bp1_section, " ", col, ": lines sum to ",
             format(sum(lines[[col]]), nsmall = 2), ", TOTALS prints ",
             format(tot[[col]], nsmall = 2), ", recorded ", want, ".",
             call. = FALSE)
      }
    }
    if (anyNA(lines$applicant) || any(!nzchar(lines$applicant))) {
      stop("[NV] BP1 section ", s$bp1_section, " has a line with no applicant.",
           call. = FALSE)
    }
  }
  if (sum(!t$is_total) != NV_BP1_LINES ||
      abs(sum(t$bp1_amount_awarded[!t$is_total]) - NV_BP1_TOTAL_AWARDED) >= 0.005) {
    stop("[NV] the BP1 report is no longer ", NV_BP1_LINES, " lines / $",
         format(NV_BP1_TOTAL_AWARDED, big.mark = ",", nsmall = 2), ".",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' The committed CSV against the ARCHIVED PDF, with this project's own reader.
nv_assert_bp1 <- function(t = nv_bp1_table()) {
  pdf <- nv_path(NV_BP1_KEY)
  if (!identical(digest::digest(file = pdf, algo = "sha256"), NV_BP1_SHA256)) {
    stop("[NV] the archived BP1 report is not the 2026-10-13 file (sha256 ",
         substr(NV_BP1_SHA256, 1, 12), ").", call. = FALSE)
  }
  nv_assert_bp1_table(t)
  flat <- nv_pdf_flat(NV_BP1_KEY)
  if (!grepl(NV_BP1_PROVISIONAL, flat, fixed = TRUE)) {
    stop("[NV] the BP1 report no longer carries NVHA's 'may not be final' ",
         "note; AMOUNT_PRELIMINARY would be unsupported.", call. = FALSE)
  }
  fmt <- function(x) paste0("$", formatC(x, format = "f", digits = 2,
                                         big.mark = ","))
  figs <- unique(c(fmt(t$funding_requested), fmt(t$bp1_amount_awarded)))
  miss <- figs[!vapply(figs, grepl, logical(1), x = flat, fixed = TRUE)]
  if (length(miss)) {
    stop("[NV] figures in nv_bp1_subrecipient_report.csv that the PDF does ",
         "not print: ", paste(miss, collapse = ", "), call. = FALSE)
  }
  # Every applicant's words, in order, are in the PDF's text.
  for (a in unique(t$applicant[!t$is_total])) {
    toks <- strsplit(a, "\\s+")[[1]]
    if (!all(vapply(toks, grepl, logical(1), x = flat, fixed = TRUE))) {
      stop("[NV] BP1 applicant not found in the PDF text: ", a, call. = FALSE)
    }
  }
  invisible(TRUE)
}


# THE CROSSWALK, BP1 line -> award-file row, READ BY HAND (session 101).
#
# The report and the Funded Projects page are two grains of one award set:
# 157 report lines against 156 page rows. 146 lines are one page row each;
# duplicate names (Nevada Health Centers x5, Great Basin College x5, UNR x6,
# Mt. Grant x3, ...) were paired on the report's own project text, never on
# order. ONE report line covers TWO page rows: WRRAP_RR-15, Nevada Rural
# Hospital Partners Foundation, is the single subaward behind page rows 26 and
# 45 (both its R+R projects); the amount sits on row 26 and row 45 says so.
# Eleven lines have no page row (NV_BP1_NEW). Nine page rows have no line --
# Tonopah Dental Center's two (21, 33), "93 X 95 NV" (48, already withdrawn),
# and SIX R+R HOSPITAL rows (28, 30, 36, 41, 47, 49) whose hospitals all sit
# in NRHPF's own line. Each entry carries the award file's awardee string, so
# a row-order shift fails here rather than pricing the wrong recipient.
NV_BP1_CROSSWALK <- tibble::tribble(
  ~bp1_line_id, ~row_no, ~nv_awardee,
  "RHOAP-01", 116L, "Aspire Behavioral Health",
  "RHOAP-02", 126L, "Big Brothers Big Sisters of Northern NV",
  "RHOAP-03", 128L, "Carson Valley Health",
  "RHOAP-04", 148L, "Cartwheel Health Services",
  "RHOAP-05", 119L, "Central Nevada Health District",
  "RHOAP-06", 124L, "Comagine Health",
  "RHOAP-07", 123L, "Desert View Hospital",
  "RHOAP-08", 150L, "Division of Child and Family services",
  "RHOAP-09", 141L, "DPBH, Chronic Disease Prevention and Health Promotion",
  "RHOAP-10", 138L, "Falllon Paiute-Shoshone Tribe",
  "RHOAP-12", 127L, "Healthy Communities Coalition of Lyon and Storey County",
  "RHOAP-13", 130L, "High Sierra Area Health Education Center",
  "RHOAP-14", 118L, "Humboldt County School District",
  "RHOAP-15", 120L, "Humboldt General Hospital",
  "RHOAP-16", 142L, "Neighbor Network of Northern NV",
  "RHOAP-17", 145L, "Nevada Primary Care Association",
  "RHOAP-18", 143L, "Nevada Rural Hospital Partners",
  "RHOAP-19", 122L, "Northern Nevada Public Health",
  "RHOAP-20", 139L, "NSHE UNLV School of Dental Medicine",
  "RHOAP-21", 121L, "NSHE UNR School of Medicine Office of Statewide Initiatives",
  "RHOAP-22", 115L, "NSHE UNR State Lab",
  "RHOAP-23", 137L, "NSHE, UNLV Department of Gynecologic Surgery and Obstetrics",
  "RHOAP-24", 131L, "NSHE, UNLV School of Nursing",
  "RHOAP-25", 135L, "NSHE, UNLV School of Nursing",
  "RHOAP-26", 132L, "NSHE, UNR Center for Excellence in Disabilities",
  "RHOAP-27", 129L, "NSHE, UNR Extension Office",
  "RHOAP-28", 133L, "NSHE, UNR Extension Office",
  "RHOAP-29", 134L, "NSHE, UNR Extension Office",
  "RHOAP-30", 136L, "NSHE, UNR Reno Extension Tribal Program",
  "RHOAP-31", 125L, "NSHE, UNR Sanford Center for Aging",
  "RHOAP-32", 146L, "Pacific Behavioral Health",
  "RHOAP-33", 140L, "Pershing General Hospital",
  "RHOAP-34", 147L, "The Family Support Center",
  "RHOAP-35", 117L, "The Life is Worth it Organization",
  "RHOAP-36", 144L, "Vitality Unlimited",
  "RHOAP-37", 149L, "Washoe Tribe of Nevada & CA",
  "FLEX-01", 1L, "Banner Churchill Community Hospital",
  "FLEX-02", 2L, "Boulder City Hospital",
  "FLEX-03", 3L, "Carlin Volunteer Fire Dept.",
  "FLEX-04", 4L, "City of Ely Fire Department",
  "FLEX-05", 5L, "City of West Wendover",
  "FLEX-06", 6L, "Convergence Health",
  "FLEX-07", 7L, "DVH Hospital Alliance LLN dba Desert View Hospital",
  "FLEX-08", 75L, "East Fork Fire Protection District",
  "FLEX-09", 73L, "Ely Shoshone Tribe",
  "FLEX-10", 74L, "Ely Shoshone Tribe",
  "FLEX-11", 78L, "Esmeralda County Board of Commissioners",
  "FLEX-12", 8L, "Esmeralda County Clinics",
  "FLEX-13", 9L, "Fallon Paiute-Shoshone Tribe",
  "FLEX-14", 83L, "Great Basin College",
  "FLEX-15", 10L, "Healthy Communities Coalition of Lyon and Storey Counties",
  "FLEX-16", 11L, "Hope Christian Health Center",
  "FLEX-17", 12L, "Humboldt General Hospital",
  "FLEX-18", 81L, "Incline Village Hospital",
  "FLEX-19", 85L, "Lander County EMS",
  "FLEX-20", 13L, "Lincoln County Hospital District dba Grover C. Dils Medical Center",
  "FLEX-21", 77L, "Lyon County",
  "FLEX-22", 14L, "Mesa View Regional Hospital",
  "FLEX-23", 79L, "Mineral County",
  "FLEX-24", 15L, "Mt. Grant General Hospital",
  "FLEX-26", 80L, "Mt. Grant General Hospital",
  "FLEX-27", 82L, "N. Nye Hospital District",
  "FLEX-28", 16L, "Northern Nevada Regional Hospital",
  "FLEX-29", 17L, "Northern Nye County Hospital District Clinic",
  "FLEX-30", 86L, "Nevada Medicaid",
  "FLEX-31", 18L, "Pershing General Hospital",
  "FLEX-32", 84L, "Safe Harbor",
  "FLEX-33", 19L, "Silver Springs Stagecoach Hospital District",
  "FLEX-34", 20L, "South Lyon Co Hospital District",
  "FLEX-35", 22L, "Vitality Unlimited",
  "FLEX-36", 76L, "Washoe Barton Medical Clinic",
  "FLEX-37", 23L, "Washoe Barton Medical Clinic DBA Carson Valley Health",
  "FLEX-38", 24L, "Washoe Barton Medical Clinic DBA Carson Valley Health",
  "FLEX-40", 25L, "William Bee Ririe Hospital and Clinics",
  "WRRAP_RR-01", 39L, "Banner Churchill Community Hospital",
  "WRRAP_RR-02", 42L, "Beatty Health and Welfare",
  "WRRAP_RR-03", 50L, "University of Nevada, Reno",
  "WRRAP_RR-04", 51L, "University of Nevada, Reno",
  "WRRAP_RR-05", 37L, "Convergence Health",
  "WRRAP_RR-07", 52L, "Desert View Hospital",
  "WRRAP_RR-08", 27L, "Ely Shoshone Tribe – Newe Medical Clinic",
  "WRRAP_RR-09", 34L, "Fallon Paiute-Shoshone Tribe",
  "WRRAP_RR-10", 29L, "Humboldt General Hospital",
  "WRRAP_RR-11", 31L, "Intermountain Health",
  "WRRAP_RR-12", 46L, "Lander County EMS",
  "WRRAP_RR-13", 38L, "Nevada Health Centers",
  "WRRAP_RR-14", 32L, "Nevada Primary Care Association",
  "WRRAP_RR-15", 26L, "Nevada Rural Hospital Partners Foundation",
  "WRRAP_RR-17", 43L, "Touro University Nevada",
  "WRRAP_RR-18", 44L, "Truckee Meadows Community College",
  "WRRAP_RR-19", 35L, "Vitality Unlimited",
  "WRRAP_RR-20", 40L, "Washoe Tribe of Nevada & California",
  "WRRAP_AT-01", 58L, "University of Nevada, Las Vegas",
  "WRRAP_AT-02", 59L, "University of Nevada, Reno – Orvis School of Nursing",
  "WRRAP_AT-03", 53L, "Great Basin College",
  "WRRAP_AT-04", 54L, "Great Basin College",
  "WRRAP_AT-05", 55L, "Great Basin College",
  "WRRAP_AT-06", 56L, "Great Basin College",
  "WRRAP_AT-07", 57L, "Great Basin College",
  "WRRAP_AT-08", 63L, "Nevada AHEC",
  "WRRAP_AT-09", 64L, "University of Nevada, Reno School of Public Health",
  "WRRAP_AT-10", 60L, "University of Nevada, Reno – Sanford Center for Aging",
  "WRRAP_AT-11", 61L, "University of Nevada, Reno School of Medicine",
  "WRRAP_AT-12", 62L, "University of Nevada, Reno School of Medicine",
  "WRRAP_AT-13", 65L, "University of Nevada, Reno",
  "WRRAP_AT-14", 66L, "Douglas County Community Health",
  "WRRAP_AT-15", 67L, "East Fork Fire Protection District",
  "WRRAP_AT-16", 68L, "NAMI Western Nevada",
  "WRRAP_AT-17", 69L, "Nevada Department of Education",
  "WRRAP_AT-18", 70L, "Renown Health",
  "WRRAP_AT-19", 71L, "Carson Valley Health",
  "WRRAP_AT-20", 72L, "Western Nevada College",
  "WRRAP_RWP-01", 87L, "Board of Regents, NSHE, obo University of Nevada, Reno",
  "WRRAP_RWP-02", 88L, "Board of Regents, NSHE, obo University of Nevada, Reno Office of Rural Health",
  "WRRAP_RWP-03", 90L, "University of Nevada, Reno School of Medicine",
  "WRRAP_RWP-04", 89L, "Board of Regents, NSHE, obo University of Nevada, Reno Orvis School of Nursing",
  "RHIT-01", 104L, "Banner Churchill",
  "RHIT-02", 111L, "Center for Behavioral Health",
  "RHIT-03", 113L, "Clear Sighted Mental Health",
  "RHIT-05", 110L, "Desert View Hospital",
  "RHIT-06", 97L, "Fallon Paiute Shoshone Tribe",
  "RHIT-07", 93L, "Humboldt General Hospital",
  "RHIT-08", 105L, "Intermountain Health",
  "RHIT-09", 107L, "Grover c. Dils Medical Center",
  "RHIT-11", 103L, "Mesa View Hospital",
  "RHIT-12", 92L, "Mt. Grant General Hospital",
  "RHIT-13", 114L, "Nevada Department of Corrections",
  "RHIT-14", 96L, "Nevada Health Centers",
  "RHIT-15", 98L, "Nevada Health Centers",
  "RHIT-16", 99L, "Nevada Health Centers",
  "RHIT-17", 100L, "Nevada Health Centers",
  "RHIT-18", 101L, "Nevada Health Centers",
  "RHIT-19", 109L, "Nevada Rural Hospital Partners Foundation",
  "RHIT-20", 94L, "Northeastern Nevada Regional Hospital",
  "RHIT-21", 108L, "Pershing General Hospital",
  "RHIT-22", 112L, "Renown Health Foundation",
  "RHIT-23", 102L, "South Lyon Medical Center",
  "RHIT-24", 106L, "Vitality Unlimited",
  "RHIT-25", 95L, "Washoe Tribal Health Center",
  "RHIT-26", 91L, "William Bee Ririe Hospital",
  "TRIBAL-01", 156L, "Duck Valley Shoshone-Paiute Tribes",
  "TRIBAL-02", 153L, "Fallon Paiute-Shoshone Tribe",
  "TRIBAL-03", 154L, "Las Vegas Paiute Tribe",
  "TRIBAL-04", 152L, "Pyramid Lake Paiute Tribe",
  "TRIBAL-05", 151L, "Walker River Paiute Tribal Health Clinic",
  "TRIBAL-06", 155L, "Washoe Tribe of Nevada and California",
  "WRRAP_RR-15", 45L, "Nevada Rural Hospital Partners Foundation"
)

# Lines with no page row. `type_from_row` copies an existing row's typing for
# the same organisation (its form is already determined, or already on §8's
# fallback with a queued question); NA classifies the name afresh.
NV_BP1_NEW <- tibble::tribble(
  ~bp1_line_id,     ~type_from_row,
  "RHOAP-11",       127L,   # Healthy/"Health" Communities Coalition: RISHN
  "FLEX-25",        15L,    # Mt. Grant General Hospital: Transportation
  "FLEX-39",        NA,     # West Wendover Ambulance: Defibrillators
  "WRRAP_RR-06",    37L,    # Convergence Health: new primary care practice
  "WRRAP_RR-16",    86L,    # NV Medicaid: children's behavioral health
  "RHIT-04",        150L,   # Division of Child and Family Services
  "RHIT-10",        86L,    # Medicaid
  "VETERANS-01",    NA,     # Nevada Department of Veterans Services
  "CORRECTIONS-01", 114L,   # Nevada Department of Corrections
  "PFT-01",         NA,     # State Public Charter School Authority
  "PFT-02",         69L     # Nevada Department of Education
)

# OWNER RULING (session 101): NRHPF's $20,278,054.31 R+R subaward. The flow
# follows the ICAHN and hospital-association rulings (§10.2), POOL_NAMED
# because the report's service-area cell NAMES ALL FOURTEEN: "All Rural
# Hospitals: Banner Churchill Community Hospital, Battle Mountain General
# Hospital, Boulder City Hospital, Carson Valley Health, Desert View Hospital,
# Grover C. Dils Medical Center, Humboldt General Hospital, Incline Village
# Community Hospital, Mesa View Regional Hospital, Mount Grant General
# Hospital, Northeastern Nevada Regional Hospital, Pershing General Hospital,
# South Lyon Medical Center, William Bee Ririe Hospital". The class is
# hospitals only. THE VERB IS THE VULNERABILITY: "NRHP will organize the RHT
# recruitment, retention and training projects of all 14 rural hospitals" --
# "organize" does not say the money is paid to them, which is why this was
# IN_KIND_BENEFIT until the ruling, and why the row is LOW.
NV_NRHPF_ROWS <- c(26L, 45L)
NV_NRHPF_LINE <- "WRRAP_RR-15"
NV_NRHPF_HOSPITALS <- c(
  "Banner Churchill Community Hospital", "Battle Mountain General Hospital",
  "Boulder City Hospital", "Carson Valley Health", "Desert View Hospital",
  "Grover C. Dils Medical Center", "Humboldt General Hospital",
  "Incline Village Community Hospital", "Mesa View Regional Hospital",
  "Mount Grant General Hospital", "Northeastern Nevada Regional Hospital",
  "Pershing General Hospital", "South Lyon Medical Center",
  "William Bee Ririe Hospital")

nv_bp1_flags <- function(f, add = character(0), drop = character(0)) {
  vapply(f, function(x) {
    v <- if (is.na(x) || !nzchar(x)) character(0) else strsplit(x, ";")[[1]]
    v <- unique(c(setdiff(v, drop), add))
    if (length(v)) paste(v, collapse = ";") else NA_character_
  }, character(1), USE.NAMES = FALSE)
}

#' Price the award file from the BP1 report, and add its eleven new lines.
#'
#' Runs AFTER session 49's and session 71's overlays (they are keyed on the
#' page rows 1..156, which this neither reorders nor removes). New rows are
#' appended from 157.
nv_apply_bp1 <- function(out) {
  t <- nv_bp1_table()
  nv_assert_bp1(t)
  lines <- t[!t$is_total, ]
  xw <- NV_BP1_CROSSWALK
  # Every line is placed exactly once (row 45 aside), every row once.
  placed <- c(unique(xw$bp1_line_id), NV_BP1_NEW$bp1_line_id)
  if (anyDuplicated(placed) || !setequal(placed, lines$bp1_line_id)) {
    stop("[NV] the BP1 crosswalk does not place every report line exactly ",
         "once.", call. = FALSE)
  }
  if (anyDuplicated(xw$row_no)) stop("[NV] a page row is crosswalked twice.",
                                     call. = FALSE)
  got <- out$awardee[match(xw$row_no, out$row_no)]
  if (!identical(got, xw$nv_awardee)) {
    bad <- which(got != xw$nv_awardee | is.na(got))
    stop("[NV] the BP1 crosswalk names row(s) ",
         paste0(xw$row_no[bad], " = '", xw$nv_awardee[bad], "'", collapse = "; "),
         " and the file now carries something else there.", call. = FALSE)
  }
  out$bp1_line_id <- NA_character_
  out$bp1_applicant <- NA_character_
  out$bp1_funding_requested <- NA_real_
  url <- nv_source(NV_BP1_KEY, "url")
  arch <- file.path("data/evidence/NV", nv_source(NV_BP1_KEY, "file"))

  for (i in seq_len(nrow(xw))) {
    r <- which(out$row_no == xw$row_no[i])
    l <- lines[lines$bp1_line_id == xw$bp1_line_id[i], ]
    carries <- !(xw$bp1_line_id[i] == NV_NRHPF_LINE && xw$row_no[i] != 26L)
    out$bp1_line_id[r] <- l$bp1_line_id
    out$bp1_applicant[r] <- l$applicant
    out$bp1_funding_requested[r] <- l$funding_requested
    if (carries) {
      out$amount[r] <- l$bp1_amount_awarded
      suspect <- l$bp1_line_id %in% NV_BP1_SOURCE_SUSPECT$bp1_line_id
      out$flag_reason[r] <- nv_bp1_flags(
        out$flag_reason[r], drop = "AMOUNT_MISSING",
        add = c("AMOUNT_PRELIMINARY", if (suspect) "SOURCE_SUSPECT"))
      out$amount_basis[r] <- paste0(
        "NVHA's RHTP Subrecipient Report for BP1 (2026-10-13), line ",
        l$bp1_line_id, " ('", l$applicant, "'): BP1 Amount Awarded $",
        formatC(l$bp1_amount_awarded, format = "f", digits = 2, big.mark = ","),
        " (Funding Requested $",
        formatC(l$funding_requested, format = "f", digits = 2, big.mark = ","),
        "). PROVISIONAL in NVHA's words: 'may not be final as project budgets ",
        "continue to be refined for CMS approval'. ",
        if (suspect) paste0(NV_BP1_SOURCE_SUSPECT$why[NV_BP1_SOURCE_SUSPECT$bp1_line_id ==
                                                      l$bp1_line_id], " ") else "",
        "Archived: ", arch, ".")
    } else {
      out$amount_basis[r] <- paste0(
        "NVHA's BP1 report carries ONE line for this subaward (", l$bp1_line_id,
        ", $", formatC(l$bp1_amount_awarded, format = "f", digits = 2,
                       big.mark = ","), "); the Funded Projects page lists it ",
        "as two projects, and the amount is on row 26. Not repeated here.")
    }
    out$amount_confirmed[r] <- "No"
  }

  # Page rows the report gives no line of their own.
  none <- setdiff(out$row_no, xw$row_no)
  for (r in which(out$row_no %in% none)) {
    out$amount_basis[r] <- paste0(
      out$amount_basis[r], ". NO LINE IN NVHA's BP1 SUBRECIPIENT REPORT ",
      "(2026-10-13): the report prices 157 lines and none is this project.",
      if (out$award_pool[r] == "WRRAP_RECRUITMENT_RETENTION" &&
          out$hospital_attribution[r] == "NAMED_HOSPITAL")
        paste0(" This hospital is one of the fourteen named in Nevada Rural ",
               "Hospital Partners Foundation's R+R line (", NV_NRHPF_LINE,
               "), which 'will organize the RHT recruitment, retention and ",
               "training projects of all 14 rural hospitals'; its share of ",
               "that line is not published and is not imputed (§6.2).") else "")
  }

  # The owner's NRHPF ruling.
  for (r in which(out$row_no %in% NV_NRHPF_ROWS)) {
    out$flow_type[r] <- "PASS_THROUGH_DESIGNATED"
    out$distributed_to_hospital[r] <- "Yes"
    out$hospital_benefiting[r] <- "Yes"
    out$hospital_attribution[r] <- "POOL_NAMED_HOSPITALS"
    out$intermediary_name[r] <- "Nevada Rural Hospital Partners Foundation, Inc."
    out$determination_confidence[r] <- "LOW"
    out$flag_reason[r] <- nv_bp1_flags(out$flag_reason[r],
      drop = c("FLOW_UNRESOLVED_HOSPITAL_AFFILIATED", "AMOUNT_MISSING"))
    out$determination_basis[r] <- paste0(
      "OWNER RULING (session 101), per the ICAHN and hospital-association ",
      "rulings (§10.2): PASS_THROUGH_DESIGNATED, Yes, POOL_NAMED_HOSPITALS. ",
      "NVHA's BP1 report line ", NV_NRHPF_LINE, " ($20,278,054.31 awarded ",
      "against $2,263,499.00 requested) names its service area as 'All Rural ",
      "Hospitals' and lists all fourteen: ",
      paste(NV_NRHPF_HOSPITALS, collapse = ", "),
      ". The eligible class is hospitals only. LOW because the report's verb ",
      "is 'organize' ('NRHP will organize the RHT recruitment, retention and ",
      "training projects of all 14 rural hospitals'), which does not by ",
      "itself show money paid to the hospitals; no per-hospital split is ",
      "published and none is imputed (§6.2). PRIOR CODING: IN_KIND_BENEFIT. ",
      "PRIOR BASIS: ", out$determination_basis[r])
  }

  # The eleven lines with no page row.
  first <- max(out$row_no) + 1L
  new <- purrr::map_dfr(seq_len(nrow(NV_BP1_NEW)), function(i) {
    l <- lines[lines$bp1_line_id == NV_BP1_NEW$bp1_line_id[i], ]
    sec <- NV_BP1_SECTIONS[NV_BP1_SECTIONS$bp1_section == l$bp1_section, ]
    src <- NV_BP1_NEW$type_from_row[i]
    row <- out[0, ]
    row[1, ] <- NA
    if (!is.na(src)) {
      tpl <- out[out$row_no == src, ]
      for (cc in c("recipient_type", "distributed_to_hospital",
                   "determination_confidence", "recipient_type_source",
                   "flow_type", "hospital_benefiting", "hospital_attribution",
                   "intermediary_name", "determination_basis", "basis_type",
                   "verified_by", "verified_basis", "recipient_subtype",
                   "cms_enrolment_match", "cms_enrolment_record", "ccn",
                   "flag_reason")) {
        if (cc %in% names(out)) row[[cc]] <- tpl[[cc]]
      }
      row$determination_basis <- paste0(
        "Typed as row ", src, " (", tpl$awardee, "), the same organisation's ",
        "page row (session 101). ", tpl$determination_basis)
    } else {
      ct <- nv_classify_recipient(l$applicant)
      fl <- rhtp_classify_flow(ct$recipient_type, "")
      row$recipient_type <- ct$recipient_type
      row$determination_confidence <- ct$determination_confidence
      row$recipient_type_source <- ct$recipient_type_basis
      row$flow_type <- fl$flow_type
      row$distributed_to_hospital <- fl$distributed_to_hospital
      row$hospital_benefiting <- fl$hospital_benefiting
      row$hospital_attribution <- if (identical(fl$distributed_to_hospital, "Yes"))
        "NAMED_HOSPITAL" else "NOT_HOSPITAL"
      row$determination_basis <- paste(ct$recipient_type_basis, fl$flow_basis)
      row$flag_reason <- if (identical(ct$rule, "FALLBACK"))
        "RECIPIENT_TYPE_INFERRED" else NA_character_
    }
    row$determination_confidence <- rhtp_confidence_ceiling(
      row$determination_confidence, row$ccn)
    suspect <- l$bp1_line_id %in% NV_BP1_SOURCE_SUSPECT$bp1_line_id
    # The WRRAP pool-conflict flag belongs to the two WRRAP pools only, so a
    # template row's copy of it does not travel to another pool's line.
    wrrap <- sec$award_pool %in% c("WRRAP_RECRUITMENT_RETENTION",
                                   "WRRAP_APPRENTICESHIP_TRAINING")
    row$flag_reason <- nv_bp1_flags(row$flag_reason,
      drop = c("AMOUNT_MISSING",
               if (!wrrap) "POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES"),
      add = c("AMOUNT_PRELIMINARY", if (suspect) "SOURCE_SUSPECT"))
    row$state <- NV_STATE
    row$row_no <- first + i - 1L
    row$awardee <- l$applicant
    row$amount <- l$bp1_amount_awarded
    row$note <- paste0(
      "First listed in NVHA's RHTP Subrecipient Report for BP1 (2026-10-13), ",
      sec$heading, ", line ", l$bp1_line_id, "; the Funded Projects page ",
      "carries no row for it.")
    row$recipient_confirmed <- "Yes"
    row$amount_confirmed <- "No"
    row$fiscal_year <- 2026L
    row$source_document_title <- paste0("NVHA RHTP Subrecipient Report for BP1: ",
                                        sec$heading)
    row$state_source_url <- url
    row$validation_source_type <- "NOTICE_OF_INTENT_TO_AWARD"
    row$extraction_method <- "PARSED_PDF_TABLE"
    row$validator <- "R/03u_nv_year1_awardees.R"
    row$award_pool <- sec$award_pool
    row$budget_period <- "BP1 (12/29/2025 - 10/30/2026)"
    row$amount_basis <- paste0(
      "NVHA's RHTP Subrecipient Report for BP1 (2026-10-13), line ",
      l$bp1_line_id, ": BP1 Amount Awarded $",
      formatC(l$bp1_amount_awarded, format = "f", digits = 2, big.mark = ","),
      " (Funding Requested $",
      formatC(l$funding_requested, format = "f", digits = 2, big.mark = ","),
      "). PROVISIONAL: 'may not be final'. Archived: ", arch, ".")
    row$section <- sec$heading
    row$listed_from <- "2026-10-13 (BP1 report)"
    row$source_archive_path <- arch
    row$bp1_line_id <- l$bp1_line_id
    row$bp1_applicant <- l$applicant
    row$bp1_funding_requested <- l$funding_requested
    row
  })
  out <- dplyr::bind_rows(out, new)
  nv_assert_vocabulary(out)
  out
}

# -- the owner's NV_BP1_FOLLOWUPS rulings (session 102) ------------------------
#
# Five questions session 101 queued as NV_BP1_FOLLOWUPS, all answered by the
# owner on 2026-10-16. Applied AFTER nv_apply_bp1() so every row already
# carries its BP1 price; keyed on page row numbers and asserted against the
# awardee string at each, so a re-ordered page fails here rather than moving a
# ruling onto the wrong row.
#
# (a) NRHP's other two lines take the NRHPF ruling: POOL_NAMED_HOSPITALS, LOW.
#     THE RULING RESTS ON WEAKER TEXT THAN NRHPF'S, AND THE ROWS SAY SO.
#     NRHPF's R+R line names all fourteen hospitals in its own service-area
#     cell. These two do not:
#       RHOAP-18 (row 143, "Nevada Rural Hospital Partners", $3,772,261.00):
#         service area "All rural hospitals"; project "Support rural hospitals
#         to build capacity to participate in multi-payer alternative payment
#         strategies." No hospital is named on the line; the class is the
#         fourteen NRHPF's line enumerates.
#       RHIT-19 (row 109, NRHP Foundation, $398,000.00): service area
#         "Lincoln, Lyon, Mineral, Humboldt Counties"; project "Cybersecurity
#         for four rural hospitals through a shared CIO model and a pilot
#         program with Grover C. Dils for endpoint protection and email
#         security." ONE hospital is named (Grover C. Dils); the other three
#         are identifiable only by county, which is a reading, not a naming.
#     Both describe a service NRHP delivers (a shared CIO; capacity-building),
#     which is the shape §10.2's AHHA negative calls IN_KIND_BENEFIT. That is
#     why both were IN_KIND until this ruling, and why they are LOW.
# (b) Intermountain and Renown are hospital/system rows as SYSTEM PARENTS: LOW,
#     GENERAL_KNOWLEDGE, no CCN, subtractable by basis_type (the SD, VA and WV
#     system-parent rulings). Rows 31 and 70 were already HOSPITAL_OR_SYSTEM
#     on session 49's general-knowledge answer; rows 105 and 112 move.
#     Neither legal name has a Nevada CMS enrolment (session 101).
# (c) WRRAP_RWP-03 (row 90): coded to the recipient NVHA lists, the Board of
#     Regents, NSHE, for UNR. "+ Banner Churchill Health" is recorded as a
#     CO-APPLICANT in `co_applicant`, with NO dollars attributed: a hospital
#     in the partnership is not a recipient (§7, New York's RCHI rule). Not a
#     §6.2 MULTI_RECIPIENT_FIELD, on the owner's instruction.
# (d) Published figures exclude SOURCE_SUSPECT rows by default:
#     rhtp_hospital_dollar_partition(include_source_suspect = FALSE). The
#     with-suspect figure is internal and is what nv_bp1_partition()$with
#     returns.
# (e) PROVISIONAL_SOURCE is collapsed into AMOUNT_PRELIMINARY. The two
#     definitions state the same condition -- the publisher says the amount is
#     not final; amount_confirmed = No; the figure is never dropped or
#     replaced. The one difference session 101 recorded (a document-level note
#     against a column header) is where the caveat is PRINTED, not what it
#     says about the amount, and AMOUNT_PRELIMINARY already carries a
#     document-level case (Indiana's recommendation letter).
NV_S102_NRHP <- tibble::tribble(
  ~row_no, ~awardee,                                     ~bp1_line_id, ~intermediary,
  143L,    "Nevada Rural Hospital Partners",            "RHOAP-18",   "Nevada Rural Hospital Partners",
  109L,    "Nevada Rural Hospital Partners Foundation", "RHIT-19",    "Nevada Rural Hospital Partners Foundation, Inc."
)
NV_S102_NRHP_WHY <- c(
  "RHOAP-18" = paste(
    "The line's service area is 'All rural hospitals' and its project is",
    "'Support rural hospitals to build capacity to participate in multi-payer",
    "alternative payment strategies.' NO HOSPITAL IS NAMED ON THIS LINE: the",
    "named class is the fourteen NRHPF's R+R line (WRRAP_RR-15) enumerates."),
  "RHIT-19" = paste(
    "The line's service area is 'Lincoln, Lyon, Mineral, Humboldt Counties' and",
    "its project is 'Cybersecurity for four rural hospitals through a shared CIO",
    "model and a pilot program with Grover C. Dils for endpoint protection and",
    "email security.' ONE hospital is named (Grover C. Dils Medical Center); the",
    "other three are identifiable only by county, which is a reading, not a",
    "naming."))
NV_S102_SYSTEM <- tibble::tribble(
  ~row_no, ~awardee,                   ~bp1_line_id,  ~system,
  31L,     "Intermountain Health",     "WRRAP_RR-11", "Intermountain Health (IHC Health Services, Inc.)",
  105L,    "Intermountain Health",     "RHIT-08",     "Intermountain Health (IHC Health Services, Inc.)",
  70L,     "Renown Health",            "WRRAP_AT-18", "Renown Health",
  112L,    "Renown Health Foundation", "RHIT-22",     "Renown Health"
)
NV_S102_RWP03 <- list(row_no = 90L,
                      awardee = "University of Nevada, Reno School of Medicine",
                      bp1_line_id = "WRRAP_RWP-03",
                      co_applicant = "Banner Churchill Health")

nv_s102_check_row <- function(out, row_no, awardee, bp1_line_id) {
  r <- which(out$row_no == row_no)
  if (length(r) != 1L || !identical(out$awardee[r], awardee) ||
      !identical(out$bp1_line_id[r], bp1_line_id)) {
    stop("[NV] session 102's ruling expects row ", row_no, " = '", awardee,
         "' on BP1 line ", bp1_line_id, "; the file carries something else.",
         call. = FALSE)
  }
  r
}

nv_apply_s102_rulings <- function(out) {
  # (a)
  for (i in seq_len(nrow(NV_S102_NRHP))) {
    x <- NV_S102_NRHP[i, ]
    r <- nv_s102_check_row(out, x$row_no, x$awardee, x$bp1_line_id)
    prior <- paste0(out$flow_type[r], "; ", out$determination_basis[r])
    out$flow_type[r] <- "PASS_THROUGH_DESIGNATED"
    out$distributed_to_hospital[r] <- "Yes"
    out$hospital_benefiting[r] <- "Yes"
    out$hospital_attribution[r] <- "POOL_NAMED_HOSPITALS"
    out$intermediary_name[r] <- x$intermediary
    out$determination_confidence[r] <- "LOW"
    out$flag_reason[r] <- nv_bp1_flags(out$flag_reason[r],
      drop = "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED")
    out$determination_basis[r] <- paste0(
      "OWNER RULING (session 102, NV_BP1_FOLLOWUPS (1)): takes the NRHPF ",
      "ruling of session 101 -- PASS_THROUGH_DESIGNATED, Yes, ",
      "POOL_NAMED_HOSPITALS, LOW, intermediary ", x$intermediary, ". ",
      NV_S102_NRHP_WHY[[x$bp1_line_id]], " The project describes a service ",
      "NRHP delivers, the shape §10.2's AHHA negative codes IN_KIND_BENEFIT; ",
      "no per-hospital split is published and none is imputed (§6.2). ",
      "PRIOR CODING: ", prior)
  }
  # (b)
  for (i in seq_len(nrow(NV_S102_SYSTEM))) {
    x <- NV_S102_SYSTEM[i, ]
    r <- nv_s102_check_row(out, x$row_no, x$awardee, x$bp1_line_id)
    prior <- paste0(out$recipient_type[r], " / ", out$flow_type[r], "; ",
                    out$determination_basis[r])
    out$recipient_type[r] <- "HOSPITAL_OR_SYSTEM"
    out$flow_type[r] <- "DIRECT"
    out$distributed_to_hospital[r] <- "Yes"
    out$hospital_benefiting[r] <- "Yes"
    out$hospital_attribution[r] <- "NAMED_HOSPITAL"
    out$determination_confidence[r] <- "LOW"
    out$basis_type[r] <- "GENERAL_KNOWLEDGE"
    out$ccn[r] <- NA
    out$flag_reason[r] <- nv_bp1_flags(out$flag_reason[r],
      drop = "RECIPIENT_TYPE_INFERRED")
    out$recipient_type_source[r] <- paste0(
      "Owner ruling (session 102): ", x$system, " is a hospital system, typed ",
      "as a SYSTEM PARENT on general knowledge (the SD, VA and WV ",
      "system-parent rulings). No Nevada CMS enrolment carries this legal ",
      "name (session 101), so there is no CCN.")
    out$determination_basis[r] <- paste0(
      "OWNER RULING (session 102, NV_BP1_FOLLOWUPS (2)): HOSPITAL_OR_SYSTEM as ",
      "a system parent, DIRECT, NAMED_HOSPITAL, LOW, GENERAL_KNOWLEDGE, no ",
      "CCN; subtractable by basis_type. BP1 applicant: '", out$bp1_applicant[r],
      "'. PRIOR CODING: ", prior)
  }
  # (c)
  x <- NV_S102_RWP03
  r <- nv_s102_check_row(out, x$row_no, x$awardee, x$bp1_line_id)
  out$co_applicant <- NA_character_
  out$co_applicant[r] <- x$co_applicant
  out$determination_basis[r] <- paste0(
    "OWNER RULING (session 102, NV_BP1_FOLLOWUPS (3)): coded to the recipient ",
    "NVHA lists, '", out$bp1_applicant[r], "' -- the Board of Regents, NSHE, ",
    "for the University of Nevada, Reno. '", x$co_applicant, "' is recorded in ",
    "co_applicant with NO dollars attributed: a hospital in the partnership is ",
    "not a recipient (§7, New York's RCHI rule; participation is not receipt). ",
    "Not a §6.2 multi-recipient field. ", out$determination_basis[r])
  nv_assert_vocabulary(out)
  out
}

#' NV's hospital buckets, with and without the SOURCE_SUSPECT rows.
nv_bp1_partition <- function(out = readr::read_csv(NV_OUT_CSV,
                               show_col_types = FALSE, progress = FALSE)) {
  susp <- !is.na(out$flag_reason) & grepl("SOURCE_SUSPECT", out$flag_reason)
  # SESSION 102: the published figure is `without` (the partition's default);
  # `with` is the internal figure.
  list(with = rhtp_hospital_dollar_partition(out, include_source_suspect = TRUE),
       without = rhtp_hospital_dollar_partition(out),
       suspect_rows = out[susp, c("row_no", "awardee", "amount",
                                  "hospital_attribution")])
}


# -- the watch (session 64) ----------------------------------------------------
#
# NEVADA HAD NO PROBE UNTIL SESSION 64, which is how a roster that grew from 72
# award actions to 155 -- four new sections -- sat on NVHA's page unread until
# session 63 happened to look. This is it: READ-ONLY (§2.2), through
# rhtp_probe_run() and the shared page watch, never writing to data/evidence/.
#
# THE BASELINE IS THE 2026-09-24 ARCHIVE, the page the award file is now
# extracted from, so a probe against the live page reports UNCHANGED until
# NVHA changes something -- and fails when it does. Three tripwires, then the
# name tripwire:
#   1. The roster must still carry exactly the SEVEN sections, each with the
#      row count the file extracted (nv_assert_award_index), and NO dollar
#      figure (nv_roster_awards refuses one -- the file would need rewriting).
#   2. The three still-pending opportunities (Presidential Fitness Test,
#      Correctional, Veterans) must have no section, the three that awarded
#      since 2026-08-31 must still have theirs, and the NOFO page must still
#      list the pending three (nv_assert_pending_not_awarded).
#   3. The name tripwire (§2.3) on both pages: an organisation neither archive
#      names is the signal, whatever words NVHA uses to add it.
# The footer's rotating state-symbol widget (session 26) sits OUTSIDE <main>,
# so rhtp_watch_reduce() never reads it and it cannot move the content digest.
NV_PROBE_PAGES <- tibble::tribble(
  ~key, ~url, ~file, ~name_diff,
  # Re-based in session 101 to the 2026-10-15 copy, which differs from
  # 2026-09-24 only by the "Subrecipient Report for BP1" link (read).
  "roster", paste0(NV_BASE, "/RHTP/rht-funded-projects---bp1/"),
  "data/evidence/NV/2026-10-15_nv_rht_funded_projects_bp1.html", TRUE,
  "nofos", paste0(NV_BASE, "/RHTP/rht-nofos/"),
  "data/evidence/NV/2026-08-31_nv_rht_nofos.html", TRUE
)

nv_probe <- function() {
  w <- rhtp_watch_pages(NV_PROBE_PAGES, NV_USER_AGENT)
  live_tabs <- nv_roster_tables(raw = w$raw$roster)
  nv_assert_award_index(tables = live_tabs,
                        text = nv_html_text(raw = w$raw$roster))
  nv_assert_pending_not_awarded(text = nv_html_text(raw = w$raw$roster),
                                nofos_text = nv_html_text(raw = w$raw$nofos),
                                sections = names(live_tabs))
  rhtp_assert_no_new_organisations_across(live = w$live, archived = w$arch,
                                          state = NV_STATE)
  # SESSION 101: the BP1 Subrecipient Report, by DIGEST. NVHA says its amounts
  # "may not be final"; a revised file is the signal to re-parse it.
  bp1 <- rhtp_probe_get(NV_BP1_KEY, function()
    nv_get(nv_source(NV_BP1_KEY, "url"), "probe:bp1_report"), nv_path(NV_BP1_KEY))
  w$changed <- dplyr::bind_rows(w$changed, tibble::tibble(
    key = NV_BP1_KEY,
    changed = !identical(digest::digest(bp1, algo = "sha256", serialize = FALSE),
                         NV_BP1_SHA256)))
  message("[NV] ", paste0(w$changed$key, ": ",
                          ifelse(w$changed$changed, "CHANGED", "UNCHANGED"),
                          collapse = "; "),
          " -- seven sections, ", sum(NV_POOLS$round_awards),
          " award actions on the page, no new organisation; the BP1 report ",
          "is the priced source (session 101).")
  invisible(w$changed)
}


# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--fetch" %in% args) print(as.data.frame(nv_fetch(force = "--force" %in% args)))
  if ("--validate" %in% args) nv_validate()
  if ("--build" %in% args) nv_build()
  if ("--report" %in% args) nv_report()
  if ("--probe" %in% args) rhtp_probe_run("NV", nv_probe())
  if (!any(c("--fetch", "--validate", "--build", "--report", "--probe") %in% args)) {
    cat("Usage: Rscript R/03u_nv_year1_awardees.R",
        "[--fetch [--force]] [--validate] [--build] [--report] [--probe]\n")
  }
}

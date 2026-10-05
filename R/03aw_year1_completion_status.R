# R/03aw_year1_completion_status.R
#
# HAS EACH EXTRACTED STATE FINISHED YEAR 1 AWARDING? (session 56)
#
# For each of the 31 EXTRACTED states this compares what the committed award
# file publishes against the state's FY2026 allotment (§7.1 anchor), records
# whether the state or CMS has SAID the Year 1 round is complete, and whether
# any initiative is known to remain unawarded. It then assigns
#
#   year1_status = COMPLETE | PARTIAL | UNKNOWN
#
#   COMPLETE -- a state or CMS source says in its own words that Year 1
#               awarding is complete, AND no initiative is recorded as
#               unawarded. The percentage of allotment is never enough: a
#               state at 90% may have one initiative left, and a state at 45%
#               may have finished (the rest is admin, or unobligated).
#   PARTIAL  -- a state or CMS source says more awards are coming, OR the
#               repository records an initiative with no published award.
#   UNKNOWN  -- neither: no completeness statement and no recorded
#               unawarded initiative.
#
# THE STATUS IS A READING OF A SOURCE, NOT A THRESHOLD. Every row carries the
# sentence (or the recorded finding) it rests on and the archived file it came
# from. Nothing here is typed from memory: the dollar figures are recomputed
# from the committed award files on every build, and the status rows are
# refused if a state is missing, duplicated, or carries an unknown code.
#
# §0.2: the allotment is Tier 1 and the published figures are Tier 3. The
# percentage divides one by the other as a COVERAGE signal; it is never a sum
# across tiers and nothing here adds a Tier 1 or Tier 2 figure to a Tier 3 one.
#
# The hospital share is reported ONLY for COMPLETE states, because only there
# is the denominator the state's whole Year 1 round. It is still bounded, not
# point-estimated, wherever a state published a pool with named hospitals and
# no per-hospital split (Georgia).
#
# Usage:
#   Rscript R/03aw_year1_completion_status.R --build    # writes both CSVs
#   Rscript R/03aw_year1_completion_status.R --report   # prints both tables

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

Y1_OUT_STATUS <- here::here("data", "reference", "year1_completion_status.csv")
Y1_OUT_SHARE  <- here::here("data", "reference", "year1_complete_hospital_share.csv")

Y1_STATUS_CODES <- c("COMPLETE", "PARTIAL", "UNKNOWN")

# The committed award files, one or more per state. The same list
# test_state_union.R combines; Missouri's Hub Anchors and Maine's invited
# cohort are NOT award files and are not here (§0.3).
Y1_AWARD_FILES <- c(
  FL = "fl_year1_awardees.csv",  GA = "ga_great_health_awards.csv",
  PA = "pa_year1_awardees.csv",  AL = "al_year1_awardees.csv",
  AL = "al_year1_round2_awardees.csv",
  AK = "ak_year1_awardees.csv",  SD = "sd_rht_contracts.csv",
  SD = "sd_year1_awardees.csv",  IL = "il_year1_awardees.csv",
  MI = "mi_year1_awardees.csv",  OR = "or_year1_awardees.csv",
  MS = "ms_year1_awardees.csv",  KS = "ks_year1_awardees.csv",
  MD = "md_year1_awardees.csv",  NE = "ne_year1_awardees.csv",
  IN = "in_year1_awardees.csv",  OK = "ok_year1_awardees.csv",
  OK = "ok_year1_doulas_awardees.csv",
  OK = "ok_year1_rrr_awardees.csv",  OK = "ok_year1_cdm_awardees.csv",
  NV = "nv_year1_awardees.csv",  MO = "mo_year1_awardees.csv",
  NH = "nh_year1_awardees.csv",  IA = "ia_year1_awardees.csv",
  ME = "me_year1_awardees.csv",  NC = "nc_year1_awardees.csv",
  NC = "nc_year1_sbhc_awardees.csv",
  AR = "ar_year1_awardees.csv",  AR = "ar_year1_round2_awardees.csv",
  WY = "wy_year1_awardees.csv",
  DE = "de_year1_awardees.csv",  DE = "de_year1_fqhc_awardees.csv",
  ID = "id_year1_awardees.csv",
  OH = "oh_year1_awardees.csv",  SC = "sc_year1_awardees.csv",
  NY = "ny_year1_awardees.csv",  VT = "vt_year1_awardees.csv",
  CT = "ct_year1_awardees.csv",  WV = "wv_year1_awardees.csv",
  TN = "tn_year1_awardees.csv",
  VA = "va_year1_awardees.csv",  WA = "wa_year1_awardees.csv",
  NJ = "nj_year1_awardees.csv",
  LA = "la_year1_awardees.csv",
  CO = "co_year1_awardees.csv", MT = "mt_year1_awardees.csv"
)

# Round-level figures that are NOT awards and must not be counted as
# published subawards even though they sit in `round_amount` on an unpriced
# row. New Hampshire's CDFA figure is "up to $40 million a year" -- a
# programme CEILING, not an award (session 29).
Y1_POOL_EXCLUDED <- c("NH")


# -- 1. What each state file publishes -----------------------------------------

y1_read <- function(f) {
  readr::read_csv(here::here("data", "reference", f),
                  show_col_types = FALSE, progress = FALSE)
}

#' Priced subawards, and priced + round-level figures, for one award file.
#'
#' `published_priced` is sum(amount): what the state prices to a recipient.
#' `pool_level_unpriced` adds Tier 3 round totals the state announced against
#' recipients (named or as a class) without a per-recipient split -- summed
#' ONCE per distinct pool, never down the column (Georgia's trap, Nevada's
#' device). Georgia publishes EVERY figure per initiative, so its whole
#' published total is the distinct (phase, initiative) pools.
y1_file_figures <- function(st, f) {
  d <- y1_read(f)
  amt <- suppressWarnings(as.numeric(d$amount))
  priced <- sum(amt, na.rm = TRUE)
  pool <- 0

  if (st == "GA") {
    pools <- d %>%
      dplyr::distinct(phase, initiative, initiative_amount)
    pool <- sum(pools$initiative_amount, na.rm = TRUE) - priced
  } else {
    if ("round_amount" %in% names(d) && !(st %in% Y1_POOL_EXCLUDED)) {
      r <- suppressWarnings(as.numeric(d$round_amount))
      k <- is.na(amt) & !is.na(r)
      pool_key <- if ("award_pool" %in% names(d)) d$award_pool else
        d$source_document_title
      pool <- pool + sum(dplyr::distinct(
        tibble::tibble(p = pool_key[k], r = r[k]))$r)
    }
    if ("pool_amount" %in% names(d)) {
      pa <- suppressWarnings(as.numeric(d$pool_amount))
      k <- is.na(amt) & !is.na(pa)
      pool <- pool + sum(dplyr::distinct(
        tibble::tibble(p = d$award_pool[k], r = pa[k]))$r)
    }
  }
  # SESSION 70: how much of what is published is still a NOTICE OF INTENT.
  # Read off each row's own `validation_source_type`, never a state-level
  # assumption: Arkansas's 80 rows all say NOTICE_OF_INTENT_TO_AWARD ("the
  # details of each grant will not be finalized until DFA signs an official
  # agreement"), Florida's and Georgia's say none do.
  # SESSION 86: PRICED ROWS THAT SIT INSIDE A POOL COUNTED ELSEWHERE. South
  # Dakota's open.sd.gov contracts carry round_id RS (inside the $31.5M Rural
  # Strong round) or UNPLACED (round not stated; may be inside the $90M round).
  # sd_year1_awardees.csv carries both rounds WHOLE in round_amount, so adding
  # those contracts on top would count the same money twice. They are netted
  # out of the pool-inclusive figure, never out of published_priced.
  inside <- 0
  if (st == "SD" && "round_id" %in% names(d)) {
    inside <- sum(amt[d$round_id %in% c("RS", "UNPLACED")], na.rm = TRUE)
  }
  vst <- if ("validation_source_type" %in% names(d))
    d$validation_source_type else rep(NA_character_, nrow(d))
  intent <- !is.na(vst) & vst == "NOTICE_OF_INTENT_TO_AWARD"
  tibble::tibble(state = st, rows = nrow(d), priced_rows = sum(!is.na(amt)),
                 published_priced = priced, pool_level_unpriced = pool,
                 priced_inside_pool = inside,
                 intent_rows = sum(intent),
                 priced_usd_on_intent = sum(amt[intent], na.rm = TRUE))
}

y1_figures <- function() {
  purrr::imap_dfr(Y1_AWARD_FILES, function(f, st) y1_file_figures(st, f)) %>%
    dplyr::group_by(state) %>%
    dplyr::summarise(dplyr::across(dplyr::everything(), sum), .groups = "drop")
}


# -- 2. What each state (or CMS) has SAID ----------------------------------------
#
# One row per state. `source_calls_complete` is Yes only where a publisher
# says, in words, that Year 1 awarding is complete or that the full scope has
# been awarded. `remaining_unawarded` is Yes where the repository records an
# initiative with no published award or a source says more awards are coming.
# The quoted sentence is the source's; the recorded finding is this
# repository's own (with the session that recorded it).

Y1_STATUS <- tibble::tribble(
  ~state, ~year1_status, ~source_calls_complete, ~remaining_unawarded, ~evidence_date, ~evidence, ~evidence_path,

  "FL", "COMPLETE", "Yes", "No",
  "2026-08-11",
  "Governor's release: 'With this latest round of awards, AHCA has awarded the full scope of Florida's RHTP funding to qualified organizations.' AHCA's programme page: 'Year 1 RHTP Sub-awardees have been awarded.' The 81 published awards are the Governor's own list to the cent (session 21). The ~$21.7M gap to the allotment is earlier monitoring/support procurements the release says were awarded 'earlier this year' with no published recipient list -- awarded, not outstanding.",
  "data/evidence/recheck/2026-08-29/FL/FL_governor_188m_release.html; data/evidence/recheck/2026-08-29/FL/FL_ahca_rhtp_program_page.html",

  "GA", "COMPLETE", "Yes", "No",
  "2026-08-27",
  "DCH: 'has awarded the final phase of Year 1 funding' and Phase 4 'complete[s] the initial Year 1 award cycle for the GREAT Health Program'. CMS's release the same day, independently: 'completes Georgia's initial Year 1 award cycle'. DCH states <10% of Year 1 is administrative, which is the 9.92% residual. One in-kind step is pending but is not an unawarded initiative: DCH 'completed the procurement process for Type 2 ambulances that select rural hospitals will be eligible to apply for soon'.",
  "data/evidence/GA/2026-08-27_great_health_phase4_awards.html; data/raw/cms/2026-08-28/newsroom/releases/trump-administration-announces-93-3-million-expand-telehealth-services-advance-surgical-robotics.html",

  "PA", "PARTIAL", "No", "Yes",
  "2026-08-29",
  "DHS's RHTP funding-opportunities page lists 'Upcoming Opportunities' -- four further payment programmes (Rapid Response Stabilization Rounds 1 and 2, an FQHC EHR/HIO programme and one more), about $86.8M, naming nobody (session 21). The 66 selected projects are one tranche.",
  "data/evidence/recheck/2026-08-29/PA/PA_dhs_rhtp_funding_opportunities.html",

  "AL", "COMPLETE", "Yes", "No",
  "2026-10-01",
  "Governor Ivey, 2026-10-01: 'The grants announced today round out year one of funding for the program'; CMS's release adds that it 'completes Alabama's initial Year 1 award cycle'. Rounds 1 and 2 fund TEN of ARHTP's eleven initiatives. Session 83 held the ELEVENTH, Community Medicine, as a remainder on the revised Project Narrative's 'Estimated required funding $5M for 3 years; $7.3M for year 1' (Table XIV-J1, Revised 4.10.2026). Session 84 SETTLED IT FROM TWO LATER ADECA DOCUMENTS: the Program Manual (proposed final, 2026-09-08), section 10.10, 'Estimated funding $5M over 4 years (begins program Year 2 / 2027; no Year 1 funding)', and the June 2026 roadshow deck, 'The Community Medicine Initiative is not budgeted in Year 1 of Program'. alabamarhtp.com lists ten closed Year 1 NOFOs and none for Community Medicine. It is not a Year 1 remainder, and for Year 2 it is a SUBAWARD round, not a state procurement: Table XIX-10 reports 'Number of mobile wellness units procured' as 'Quarterly reporting from subawardees', so the units are bought by awardees, and the narrative gives 'Priority consideration ... to applicants'. Published: $198,539,348 of $203,404,327 (97.6%); the $4,864,979 residual is not attributed to any initiative by any source read.",
  "data/evidence/recheck/2026-10-01/AL/al_governor_2026-10-01_round2_34_grants.html; data/evidence/AL/2026-10-02_adeca_arhtp_program_manual_proposed_final_2026-09-08.pdf; data/evidence/AL/2026-10-02_adeca_arhtp_intro_presentation_2026-06.pdf; data/evidence/AL/2026-10-01_adeca_arhtp_project_narrative_revised_2026-04-10.pdf",

  "AK", "PARTIAL", "No", "Yes",
  "2026-09-21",
  "Alaska announces awards 'on a rolling weekly basis' (Funding Cycle Update; 185 -> 244 actions between snapshots, session 46). CMS's Alaska release: 'Additional awards are coming.'",
  "data/evidence/AK/2026-09-21_alaska_rhtp_year1_funding_cycle_update.pdf; data/raw/cms/2026-08-28/state_press_releases/AK_cms_press_release_main.html",

  "SD", "UNKNOWN", "No", "Unknown",
  "2026-10-02",
  "Two announced rounds ($31.5M, $90M; 110 grants) name NO recipient. OpenSD's RHT series holds 41 contracts / $26,836,144 as of 2026-10-02 (session 86): 14 of the 28 Rural Strong grants ($15,967,960, INSIDE the $31.5M), 8 named awards whose round the register does not state ($3,175,112, capped at and never added to the $90M round), and 19 administrative contracts ($7,693,072). published_incl_pool_level is therefore administrative + the two rounds, never the contracts on top. Neither release says Year 1 is complete; both speak only of 'future funding cycles'. No evidence either way.",
  "data/evidence/SD/announcements/KB0046839.html; data/evidence/SD/announcements/KB0047023.html",

  "IL", "PARTIAL", "No", "Yes",
  "2026-08-29",
  "Only ICAHN's three agreements are published. HFS's Hospital Planning Grant ($28,191,393 across 97 eligible hospitals) and the other AmpliFund solicitations name no recipient (sessions 16, 21).",
  "data/evidence/recheck/2026-08-29/IL/IL_rhtp_hospital_planning_grant_methodology.pdf; data/evidence/IL/2026-08-28_hfs_rhtp.html",

  "MI", "PARTIAL", "No", "Yes",
  "2026-09-01",
  "MDHHS's 'all RHTP Subrecipients' is a claim that the ROSTER is complete, not the ROUND: the same programme page carries 'Upcoming Funding Opportunities -- To receive updates when additional RHTP GFOs are released, please sign up for the listserv.' 40.4% of the allotment is published.",
  "data/evidence/MI/2026-09-01_mi_rhtp_program_page.html",

  "OR", "PARTIAL", "No", "Yes",
  "2026-07-07",
  "OHA: 'Oregon has SO FAR awarded about $175.3 million'. Immediate Impact Wave 2 names 21 of its stated 33 projects, and the Tribal ($21.7M) and LPHA ($5M) pools name nobody (session 17).",
  "data/evidence/OR/2026-07-07_oha_news_release.html; data/evidence/OR/2026-08-28_oha_rhtp_awards_page.html",

  "MS", "PARTIAL", "No", "Yes",
  "2026-09-14",
  "Governor's release: the Workforce Expansion Initiative and Psychiatric Emergency Services (EmPATH) 'are currently being reviewed and will be announced in the next 30 to 45 days'; two further opportunities launch in October (session 46).",
  "data/evidence/MS/2026-09-14_ms_governor_167_awards_ROSTER.html",

  "LA", "PARTIAL", "No", "Yes",
  "2026-09-21",
  "One of seven Budget Year 1 solicitations has a published award (the Rural Clinician Credit Bank, 53 awards as of 8/28, session 64). The other six had Notices of Intent to Contract dated 2026-10-02, sent to applicants privately, with denials 'by October 16, 2026'; nothing names a selectee (session 88).",
  "data/evidence/LA/2026-10-05_la_ldh_rhtp_programme_NOTICES_DATED_OCT_2.html",

  "KS", "PARTIAL", "No", "Yes",
  "2026-09-22",
  "KDHE's programme page: 'Open RHTP Funding Opportunities -- More funding opportunities coming soon.' Interfacility Transport (RFA webinar 2026-07-08), Evidence-Based Practice and KHA Healthworks have published no award.",
  "data/evidence/KS/2026-09-22_kdhe_rhtp_program_page.html",

  "MD", "PARTIAL", "No", "Yes",
  "2026-08-29",
  "MDH runs ten Budget Period 1 opportunities and links award offers for two (session 21).",
  "data/evidence/MD/2026-08-29_mdh_rhtp_program_page.html",

  "NE", "PARTIAL", "No", "Yes",
  "2026-08-31",
  "DHHS's RFA timeline carries nineteen initiative rows and an 'Awardees' link on three (session 23).",
  "data/evidence/NE/2026-08-31_ne_dhhs_rhtp_program_page.html",

  "IN", "PARTIAL", "No", "Yes",
  "2026-09-03",
  "GROW Regional Grants ($120M across eight regional coalitions) had not awarded at the last live check: all three pre-award sentences on the page (session 42).",
  "data/evidence/IN/2026-08-31_grow_regional_grants.html",

  "OK", "PARTIAL", "No", "Yes",
  "2026-10-02",
  "OSDH's Funding Recipients page now carries FIVE rosters: Doulas (ok_year1_doulas_awardees.csv, 4 rows, $647,967.83, session 85), Rural Regional Reorientation (ok_year1_rrr_awardees.csv, 20, $39,578,523) and Chronic Disease Management (ok_year1_cdm_awardees.csv, 15, $15,608,845.22), the last two extracted in session 86 on the owner's approval. EMS & Community Paramedicine Vehicles and Behavioral Health Integration still have no roster, and the Lung Cancer Screening Program's 11 selected hospitals are unnamed (session 25).",
  "data/evidence/OK/new_rosters/2026-10-02_ok_rhtp_funding_recipients.html; data/evidence/OK/2026-08-31_ok_rhtp_funding.html",

  "NV", "PARTIAL", "No", "Yes",
  "2026-09-24",
  "RHIT, RHOAP and a Tribal section have since awarded (155 named actions, session 64), but the Presidential Fitness Test, Correctional and Veterans opportunities still have no section, and NVHA: 'All RHT subawards for BP1 to be finalized by October 1, 2026' (session 26).",
  "data/evidence/NV/2026-09-24_nv_rht_funded_projects_bp1.html; data/evidence/NV/2026-06-09_nv_rhtsc_program_fiscal_update.pdf",

  "MO", "PARTIAL", "No", "Yes",
  "2026-09-23",
  "DSS: the ToRCH Care Smart Growth IFB is 'part of a multi-phase funding strategy' spanning Program Years 1 and 2, and its timeline reads 'Aug - Sept 2026 Announce select procurement awardees'. The 20 SMRP hospital awards are named but unpriced.",
  "data/evidence/MO/2026-09-23_dss_rural_health.html; data/evidence/MO/2026-09-23_dss_smrp_awardees.html",

  "NH", "PARTIAL", "No", "Yes",
  "2026-09-01",
  "FHC's Critical Access Hospital and Acute Care Hospital opportunity reads 'Coming Soon' and Primary Care's first cohort is notified 'Late October' (session 29). CDFA's 'up to $40 million a year' is a ceiling and is NOT counted as published.",
  "data/evidence/NH/2026-09-01_fhc_go_north_rhtp.html",

  "IA", "PARTIAL", "No", "Yes",
  "2026-06-18",
  "Iowa HHS: 'As we continue awarding funds through Healthy Hometowns...' (2026-06-18, the latest Iowa statement archived). Iowa prices no recipient, so no percentage of allotment can be computed.",
  "data/evidence/IA/2026-06-18_ia_hhs_gme_approval_new_healthy_hometowns_awardees.html",

  "ME", "PARTIAL", "No", "Yes",
  "2026-09-02",
  "EMR Modernization and APM Transition closed unawarded; the Rural Hospital Efficiency Fund cohort is INVITED, not awarded; Maine DOE's award date passed with no roster (session 33).",
  "data/evidence/ME/2026-09-02_me_dhhs_rhtp_programme.html; data/evidence/ME/2026-08-05_me_rhtp_advisory_updates.pdf",

  "NC", "PARTIAL", "No", "Yes",
  "2026-09-30",
  "School Health Centers AWARDED 2026-09-14 (five named, $1.25M, no split; nc_year1_sbhc_awardees.csv, session 83), but Minority Diabetes Prevention closed with no roster, the ROOTS second tier names nobody (session 38), and the Rural Health Innovation Fund LAUNCHED 2026-09-30 ('$20 million per year for up to five years', applications due 2026-11-16, awards 'January 2027') -- a Tier 2 pool not yet awarded.",
  "data/evidence/NC/2026-09-02_nc_ncrhtp_grant_opportunities.html; data/evidence/recheck/2026-10-01/NC/nc_ncdhhs_2026-09-14_sbhc_five_organisations.html; data/evidence/recheck/2026-10-01/NC/nc_ncdhhs_2026-09-30_rural_health_innovation_fund.html",

  "AR", "COMPLETE", "Yes", "No",
  "2026-09-24",
  "Governor Sanders, 2026-09-24: 'Combined with the previous round of funding through the Telehealth, Health-Monitoring, and Response Innovation for Vital Expansion (THRIVE) and the Promoting Access Coordination and Transformation (PACT) priority, this round of funding completes the distribution of the $208 million awarded to Arkansas this year.' All four initiatives have a published DF&A list (round 1 2026-08-27, round 2 2026-09-24; session 69). The $4,916,708.71 left of the allotment is $4,680,988 of PLANNED administration in the Year 1 Revised Budget Narrative plus $235,720.73 UNEXPLAINED (allocation less award, net), not an unawarded initiative: ar_year1_allotment_gap.csv. Every award is an INTENT: 'the details of each grant will not be finalized until DFA signs an official agreement with each grantee'.",
  "data/evidence/recheck/2026-09-25/AR/2026-09-24_governor_sanders_54_6_million_awarded.html; data/evidence/recheck/2026-09-25/AR/2026-09-24_ar_dfa_year1_rise_heart_award_list.pdf; data/evidence/AR/2026-05_ar_year1_revised_budget_narrative.pdf",

  "WY", "PARTIAL", "No", "Yes",
  "2026-08-11",
  "The Advisory Committee approved every budget line, but $30,877,990 is approved at POOL level naming nobody, including three competitive RFPs; every row is an approval pending execution (session 42).",
  "data/evidence/WY/2026-09-03_wy_advisory_committee_award_approvals_2026-08-11.pdf",

  "DE", "PARTIAL", "No", "Yes",
  "2026-10-02",
  "Two of fifteen Year 1 initiatives have published awards: School-Based Health Centers (four named, unpriced, session 44) and Value-based care transformation (three FQHCs, ~$22.69M rounded, 2026-09-24, de_year1_fqhc_awardees.csv, session 86; the DHSS line is $24,322,042.48). Thirteen have no roster.",
  "data/evidence/DE/2026-09-03_de_dhss_rhtp_programme.html; data/evidence/DE/2026-10-02_de_fqhc_award_release.html",

  "ID", "PARTIAL", "No", "Yes",
  "2026-09-03",
  "One named awardee; eleven opportunities open or just posted and four closed with no awardee (session 44).",
  "data/evidence/ID/2026-09-03_id_rhtp_funding_opportunities.html",

  "OH", "PARTIAL", "No", "Yes",
  "2026-07-01",
  "Governor DeWine's release: 'Additional contracts will be awarded in the coming months.'",
  "data/evidence/OH/2026-09-03_oh_ohio_university_award_release.html",

  "SC", "PARTIAL", "No", "Yes",
  "2026-09-15",
  "Four of five initiatives awarded; the Tech Catalyst Fund ($32,730,351, via SCRA) 'will be announced through a future stage' (session 47).",
  "data/evidence/SC/2026-09-21_scdhhs_grants_rhtp_programme.html",

  "NY", "PARTIAL", "No", "Yes",
  "2026-09-04",
  "RCHI ($76.2M) is awarded; Enhanced Primary Care and Rural Roots have no solicitation and Initiative 4 (cybersecurity) is at interest-form stage (session 37/52).",
  "data/evidence/NY/2026-09-22_ny_governor_rchi_awards_release.html",

  "VT", "PARTIAL", "No", "Yes",
  "2026-09-25",
  "AHS: the list 'does not represent the full Year 1 awards or funding decisions ... procurement and award processes remain underway for some activities.'",
  "data/evidence/recheck/2026-09-28/VT/vt_year1_awards.html",

  "CT", "PARTIAL", "No", "Yes",
  "2026-09-16",
  "Four executed agreements ($49.98M) against DSS's $154.2M across 30 projects; the Governor's release points readers to 'updates on hospital projects and future phases of work' (session 54).",
  "data/evidence/recheck/2026-09-23/CT/ct_governor_rhtp_50m_release.html",

  "WV", "PARTIAL", "No", "Yes",
  "2026-09-30",
  "The Governor calls them 'the first implementation awards'; CMS's WV release: 'Additional funding opportunities will also expand access...' (sessions 54-55). The 2026-09-30 CCWV release repeats it: 'Additional awards will be announced' (session 85).",
  "data/evidence/recheck/2026-09-23/WV/wv_art_first-rural-health-transformation-progra.html; data/evidence/WV/2026-10-02_wv_art_ccwv_rhtp_awards.html; data/raw/cms/2026-09-21/newsroom/releases/trump-administration-announces-4-8-million-strengthen-west-virginias-rural-healthcare-workforce.html",

  "TN", "PARTIAL", "No", "Yes",
  "2026-09-03",
  "TDH names 53 HART awards as 'the initial recipients of funding through the Rural Health Transformation Program', one priority of several, and prices none of them (session 59).",
  "data/evidence/recheck/2026-09-23/TN/tn_doh_2026-09-03_first_recipients.html; data/evidence/recheck/2026-09-23/TN/tn_2026_RHTP_HART_Grant_Awards_FINAL.xlsx",
  "VA", "PARTIAL", "No", "Yes",
  "2026-08-28",
  "The Governor: 'This initial investment of $122 million is the first step in a multi-pronged process' -- eleven first-tier partners, no per-partner figure, sub-grants still at RFA stage (session 60).",
  "data/evidence/recheck/2026-09-23/VA/gov_release_2026-08-28_122M.pdf; data/evidence/recheck/2026-09-23/VA/rhtva_ways_to_apply.html",
  "WA", "PARTIAL", "No", "Yes",
  "2026-09-16",
  "HCA's deck prices first-tier lines but its competitive pools (incl. 1.4, $10.71M for rural hospitals) name no winners, and 6.4 is 'RFA posted' (session 60).",
  "data/evidence/recheck/2026-09-23/WA/hca_rhtp_webinar_2026-09-16.pdf",
  "NJ", "PARTIAL", "No", "Yes",
  "2026-07-31",
  "The Governor: 'the first round of grant awards ... investing $83 million', against 'the Department of Health administering approximately $95 million in competitive grant funding' (session 61).",
  "data/evidence/recheck/2026-09-24/NJ/governor_release_2026-07-31_first_round_awards.html",
  "CO", "PARTIAL", "No", "Yes",
  "2026-09-28",
  "CMS: 'Today's announcement is one part of the larger overall funding amount awarded to Colorado for fiscal year 2026.' The round is $169.6M of a $200,105,604 allotment, and HCPF's own total ($169,587,181) does not reconcile to its roster ($170,210,575.26) (session 82).",
  "data/evidence/CO/2026-10-01_cms_release_co_2026-09-28.html; data/evidence/CO/2026-10-01_hcpf_release_2026-09-28.html",

  "MT", "PARTIAL", "No", "Yes",
  "2026-09-29",
  "DPHHS: 'This is the first round of funding for EMS modernization through Montana's RHTP.' The $8.7M EMS Equipment Grant is one channel of a $233,509,359 allotment; the CIH pilot grant and five RFPs on DPHHS's pages name no award (session 88).",
  "data/evidence/MT/2026-10-05_mt_dphhs_rural_ems_award_release.html; data/evidence/MT/2026-10-05_mt_rhtp_grants.html"
)


# -- 3. Build and assert ---------------------------------------------------------

y1_assert_status <- function(s = Y1_STATUS) {
  survey <- readr::read_csv(here::here("data", "reference",
                                       "rcj_state_survey.csv"),
                            show_col_types = FALSE)
  extracted <- sort(survey$state[survey$extraction_status == "EXTRACTED"])
  if (!identical(sort(s$state), extracted)) {
    stop("[Y1] the status rows do not match the EXTRACTED states. Missing: ",
         paste(setdiff(extracted, s$state), collapse = ", "), "; extra: ",
         paste(setdiff(s$state, extracted), collapse = ", "), call. = FALSE)
  }
  if (!identical(sort(unique(names(Y1_AWARD_FILES))), extracted)) {
    stop("[Y1] Y1_AWARD_FILES does not cover the EXTRACTED states.",
         call. = FALSE)
  }
  if (!all(s$year1_status %in% Y1_STATUS_CODES)) {
    stop("[Y1] unknown year1_status code.", call. = FALSE)
  }
  # COMPLETE rests on a statement and on no known remainder -- both, always.
  bad <- s %>% dplyr::filter(year1_status == "COMPLETE",
                             source_calls_complete != "Yes" |
                               remaining_unawarded != "No")
  if (nrow(bad)) stop("[Y1] COMPLETE without a completeness statement, or ",
                      "with a recorded remainder: ",
                      paste(bad$state, collapse = ", "), call. = FALSE)
  bad <- s %>% dplyr::filter(year1_status == "PARTIAL",
                             remaining_unawarded != "Yes")
  if (nrow(bad)) stop("[Y1] PARTIAL without a recorded remainder: ",
                      paste(bad$state, collapse = ", "), call. = FALSE)
  bad <- s %>% dplyr::filter(year1_status == "UNKNOWN",
                             source_calls_complete == "Yes" |
                               remaining_unawarded == "Yes")
  if (nrow(bad)) stop("[Y1] UNKNOWN where the evidence decides it: ",
                      paste(bad$state, collapse = ", "), call. = FALSE)
  for (p in unlist(strsplit(s$evidence_path, ";\\s*"))) {
    if (!file.exists(here::here(p))) {
      stop("[Y1] cited evidence is not in the archive: ", p, call. = FALSE)
    }
  }
  invisible(TRUE)
}

y1_build_status <- function() {
  y1_assert_status()
  allot <- readr::read_csv(here::here("data", "reference",
                                      "cms_fy2026_allotments.csv"),
                           show_col_types = FALSE) %>%
    dplyr::select(state, state_name, fy2026_allotment)
  y1_figures() %>%
    dplyr::left_join(allot, by = "state") %>%
    dplyr::mutate(
      published_incl_pool_level = published_priced + pool_level_unpriced -
        priced_inside_pool,
      pct_priced = round(100 * published_priced / fy2026_allotment, 1),
      pct_incl_pool_level =
        round(100 * published_incl_pool_level / fy2026_allotment, 1),
      pct_priced_on_intent = ifelse(published_priced > 0,
        round(100 * priced_usd_on_intent / published_priced, 1), NA_real_)
    ) %>%
    dplyr::left_join(Y1_STATUS, by = "state") %>%
    dplyr::select(state, state_name, fy2026_allotment, rows, priced_rows,
                  published_priced, pct_priced, pool_level_unpriced,
                  published_incl_pool_level, pct_incl_pool_level,
                  intent_rows, priced_usd_on_intent, pct_priced_on_intent,
                  year1_status, source_calls_complete, remaining_unawarded,
                  evidence_date, evidence, evidence_path) %>%
    dplyr::arrange(factor(year1_status, Y1_STATUS_CODES),
                   dplyr::desc(pct_incl_pool_level))
}


# -- 4. Hospital share, COMPLETE states only -------------------------------------
#
# share_floor   = NAMED_HOSPITAL dollars / everything the state published.
# share_ceiling = adds (a) priced rows coded Unclear and (b) any pool that
#                 contains a named hospital with no per-hospital amount,
#                 counted WHOLE -- which is an upper bound, not an estimate,
#                 because such a pool may also hold a non-hospital recipient.
#                 Georgia's two do (ga_mixed_pool_split_search.csv): each holds
#                 a positive, unpublished non-hospital award, so GA's true share
#                 is STRICTLY below its ceiling. Florida's ceiling equals its
#                 floor since session 58 settled its five Unclear rows.
# Pool buckets (POOL_NAMED / POOL_UNNAMED) are reported beside, never added.

# SESSION 70. COMPLETE is a statement about the ROUND; this is a statement
# about the AWARD ACTIONS inside it, and the three COMPLETE states differ.
# Free text, not a §8 code (no code is invented mid-session): it says what the
# state's own documents call the actions. The numeric twin is
# `pct_priced_on_intent`, derived from the rows.
Y1_AWARD_STAGE <- c(
  FL = paste("AWARDED: AHCA 'has awarded the full scope' and 'Year 1 RHTP",
             "Sub-awardees have been awarded'; every row amount_confirmed = Yes.",
             "The rows rest on the Governor's release (AGENCY_PRESS_RELEASE);",
             "no executed agreement is published, so 'awarded' is AHCA's word."),
  GA = paste("AWARDED: DCH 'has awarded the final phase of Year 1 funding'; 21",
             "rows rest on two SIGNED Notices of Award, the rest on DCH's award",
             "announcements. Its 56 unpriced rows are amount_confirmed = No",
             "because DCH publishes those figures per initiative pool, not per",
             "recipient -- not because an award is pending."),
  AR = paste("NOTICE OF INTENT, ALL 80 ROWS: 'the details of each grant will not",
             "be finalized until DFA signs an official agreement with each",
             "grantee'. No agreement is published; CMS's obligation deadline is",
             "2026-10-30. COMPLETE here means the ROUND is fully announced, not",
             "that any award is executed."),
  AL = paste("AWARDED (GOVERNOR'S WORD), ALL 172 ROWS -- NOT A NOTICE OF INTENT:",
             "'were awarded more than $144 million through 138 grants' and 'The",
             "second round of grant funding was awarded'. Both rest on the",
             "Governor's releases (GOVERNOR_PRESS_RELEASE). No notice of intent,",
             "award letter or executed agreement is published; ADECA's Program",
             "Manual refers only to 'the applicable subaward agreement' (session",
             "85 searched both releases, the manual, the narrative and the three",
             "ADECA/ARHTP pages for intent language and found none). Arkansas is",
             "the COMPLETE state whose rows are intents; Alabama's are not, and",
             "neither has an executed agreement on the record. 55 amounts are",
             "rounded in the source (AMOUNT_ROUNDED_IN_SOURCE).")
)

y1_hospital_share <- function(status = y1_build_status()) {
  done <- status$state[status$year1_status == "COMPLETE"]
  if (length(setdiff(done, names(Y1_AWARD_STAGE)))) {
    stop("[Y1] a COMPLETE state has no award_action_stage: ",
         paste(setdiff(done, names(Y1_AWARD_STAGE)), collapse = ", "),
         call. = FALSE)
  }
  purrr::map_dfr(done, function(st) {
    fs <- Y1_AWARD_FILES[names(Y1_AWARD_FILES) == st]
    d <- dplyr::bind_rows(lapply(fs, y1_read))
    if (!"flow_type" %in% names(d)) d$flow_type <- NA_character_
    p <- rhtp_hospital_dollar_partition(d)
    amt <- suppressWarnings(as.numeric(d$amount))
    unclear_priced <- sum(amt[d$distributed_to_hospital == "Unclear"],
                          na.rm = TRUE)
    unclear_unpriced_rows <- sum(d$distributed_to_hospital == "Unclear" &
                                   is.na(amt))
    unpriced_hosp_pools <- 0
    if (st == "GA") {
      unpriced_hosp_pools <- d %>%
        dplyr::mutate(a = amt) %>%
        dplyr::group_by(phase, initiative) %>%
        dplyr::filter(any(distributed_to_hospital == "Yes" & is.na(a))) %>%
        dplyr::summarise(rest = dplyr::first(initiative_amount) -
                           sum(a, na.rm = TRUE), .groups = "drop") %>%
        dplyr::pull(rest) %>% sum()
    }
    row <- status[status$state == st, ]
    named <- sum(p$dollars[p$bucket == "NAMED_HOSPITAL"])
    denom <- row$published_incl_pool_level
    # SESSION 85: THE TWO SUBTRACTABLE SLICES OF NAMED_HOSPITAL, per row and
    # by the partition's own bucket rule. CLAUDE.md's partition block says
    # both can be subtracted; this is where a COMPLETE state's reader does it.
    #   * ACADEMIC_HEALTH_CENTER subtype -- re-typed a hospital on its CMS
    #     enrolment (§10.2's enrolled-operator row, session 71).
    #   * basis_type = GENERAL_KNOWLEDGE -- the FORM rests on a verifier's own
    #     knowledge (§0.4, session 49), always LOW.
    # A row in both is counted ONCE in the combined figure.
    col <- function(x) if (x %in% names(d)) d[[x]] else rep(NA_character_, nrow(d))
    bucket <- rhtp_hospital_attribution(col("flow_type"), d$distributed_to_hospital,
                                        col("recipient_type"), col("hospital_attribution"))
    in_named <- bucket == "NAMED_HOSPITAL"
    is_ahc <- in_named & col("recipient_subtype") %in% "ACADEMIC_HEALTH_CENTER"
    is_gk  <- in_named & col("basis_type") %in% "GENERAL_KNOWLEDGE"
    ahc_usd <- sum(amt[is_ahc], na.rm = TRUE)
    gk_usd  <- sum(amt[is_gk], na.rm = TRUE)
    either_usd <- sum(amt[is_ahc | is_gk], na.rm = TRUE)
    if (abs(sum(amt[in_named], na.rm = TRUE) - named) > 0.005) {
      stop("[Y1] ", st, ": the per-row NAMED_HOSPITAL sum does not reproduce the ",
           "partition's.", call. = FALSE)
    }
    tibble::tibble(
      state = st,
      published_incl_pool_level = denom,
      fy2026_allotment = row$fy2026_allotment,
      named_hospital_rows = sum(p$rows[p$bucket == "NAMED_HOSPITAL"]),
      named_hospital_usd = named,
      pool_named_hospitals_usd = sum(p$dollars[p$bucket == "POOL_NAMED_HOSPITALS"]),
      pool_unnamed_hospitals_usd = sum(p$dollars[p$bucket == "POOL_UNNAMED_HOSPITALS"]),
      unclear_priced_usd = unclear_priced,
      unclear_unpriced_rows = unclear_unpriced_rows,
      mixed_pools_with_unpriced_named_hospitals_usd = unpriced_hosp_pools,
      share_floor_pct = round(100 * named / denom, 1),
      share_ceiling_pct = round(100 * (named + unclear_priced +
                                         unpriced_hosp_pools) / denom, 1),
      share_of_allotment_floor_pct = round(100 * named / row$fy2026_allotment, 1),
      ahc_subtype_rows = sum(is_ahc),
      ahc_subtype_usd = ahc_usd,
      general_knowledge_rows = sum(is_gk),
      general_knowledge_usd = gk_usd,
      named_hospital_usd_excl_ahc_and_gk = named - either_usd,
      share_floor_excl_ahc_and_gk_pct = round(100 * (named - either_usd) / denom, 1),
      intent_rows = row$intent_rows,
      pct_priced_on_intent = row$pct_priced_on_intent,
      award_action_stage = Y1_AWARD_STAGE[[st]]
    )
  })
}


if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  status <- y1_build_status()
  share <- y1_hospital_share(status)
  if ("--build" %in% args) {
    readr::write_csv(status, Y1_OUT_STATUS, na = "")
    readr::write_csv(share, Y1_OUT_SHARE, na = "")
    message("[Y1] wrote ", Y1_OUT_STATUS, " and ", Y1_OUT_SHARE)
  }
  if ("--report" %in% args || !length(args)) {
    options(width = 200)
    print(as.data.frame(status %>% dplyr::select(
      state, fy2026_allotment, published_priced, pct_priced,
      published_incl_pool_level, pct_incl_pool_level, pct_priced_on_intent,
      year1_status, source_calls_complete, remaining_unawarded)))
    print(as.data.frame(share))
  }
}

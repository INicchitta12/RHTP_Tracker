# 03bh_rcj_candidate_dispositions.R --------------------------------------------
# RCJ candidate dispositions for the twenty-three states that had none
#   -> data/reference/<st>_rcj_candidate_disposition.csv, one per state
#
# WHY THIS FILE EXISTS. Every extracted or probed state carries a disposition
# table saying, group by group, why each RCJ Tier 3 candidate is or is not an
# RHTP subaward (§0.1: nothing RCJ says is a finding). Twenty-three states
# holding live candidates on the 2026-09-24 pull had no such table -- most of
# them the states extracted FIRST (FL GA PA AL AK OR KS MD), before the
# disposition habit existed, plus the queued and no-probe states. Session 62
# re-ran Stage 2 on the 09-24 pull and the live Tier 3 set went 1,372 -> 2,447;
# Alaska was re-keyed, Florida stopped being invisible, Kansas and South Dakota
# gained new ids. None of that had anywhere to be written down.
#
# HOW IT WORKS: AN EXACT ENGINE FIRST, A HAND-READ TABLE FOR THE REST.
#
#   1. For a state with an award file, every live candidate is matched to the
#      file on a NORMALISED NAME -- lower case, curly quotes straightened, every
#      non-alphanumeric character a space, whitespace squeezed -- and nothing
#      else. NEVER a fuzzy match (§2): "Charles County Health Department" and
#      "Charles County Department of Health" are the same body and the engine
#      does not say so; a human does, in the hand-read table, with the reason.
#   2. A name match with the amount equal to the dollar is IN_FILE; each file
#      row is consumed once, so a SECOND RCJ record of an award already matched
#      is CARRIED_TWICE -- the grain defect (§6.1 mode 4) RCJ commits whenever
#      it ingests one award from two documents. Which record counts as the
#      first is decided by DISPO_PRIMARY_DOC, the state's own award document,
#      so the duplicate is the aggregator's re-publication and not the reverse.
#   3. A name match against a file row with NO amount is IN_FILE_UNPRICED --
#      the state published the award and no figure, so RCJ's figure is not a
#      state figure.
#   4. Everything else -- a name the file does not carry, or a name it does
#      carry at a different figure -- goes to DISPO_HAND_READ, which must place
#      it. A candidate no rule places FAILS THE BUILD; so does a rule that
#      places nothing (a stale verdict is as bad as a missing one, R/02c's
#      rule).
#
# WHAT THE TABLES CLAIM AND WHAT THEY DO NOT. A disposition says what the
# aggregator carries and why, with the STATE document as evidence. It does not
# extract. Where a hand read found a real award that a committed award file does
# not carry, the row says so and nothing is added to that file -- that is a
# finding to report, and an extraction is its own session. Every number in the
# prose is derived from the rows (DISPO_TOKENS), never typed, and every table
# passes rhtp_assert_disposition_prose() before it is written.
#
# EVIDENCE READ FOR THIS FILE, NEW, READ-ONLY, archived with a manifest under
# data/evidence/rcj_dispositions/2026-09-24/:
#   GA  DCH's Grant Announcements page and three Dual Track RFGAs (FY24, FY26,
#       RCCS26). The Dual Track series is the State Office of Rural Health's
#       own grant, first solicited 2023-11-15, "subject to the availability of
#       appropriated funds", and all three RFGAs contain "Rural Health
#       Transformation", "RHTP", "GREAT Health" and "Centers for Medicare" ZERO
#       times each.
#   SD  open.sd.gov's RHT contract series, re-read in memory with R/03i's own
#       search (no probe log line). It now holds 26 contracts against the 13 in
#       sd_rht_contracts.csv (2026-08-28), and 8 of the new ones read
#       "Implementation of a Rural Strong Grant as a part of the federal Rural
#       Health Transformation Program" -- the Rural Strong contracts the July
#       release promised to OpenSD, five of the eight to hospitals by name.
#
# Usage:
#   Rscript R/03bh_rcj_candidate_dispositions.R --validate  # build in memory, assert
#   Rscript R/03bh_rcj_candidate_dispositions.R --build     # write the 23 CSVs
#   Rscript R/03bh_rcj_candidate_dispositions.R --report    # per-state summary

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))


# -- Constants -----------------------------------------------------------------

DISPO_STATES <- c("OR", "AK", "AL", "GA", "KS", "FL", "PA", "MD", "SD", "VT",
                  "CO", "WV", "MN", "WA", "AZ", "HI", "MT", "UT", "MA", "NC",
                  "ND", "RI", "VA")

# The pull every "new" count is measured against.
DISPO_PRIOR_PULL <- as.Date("2026-08-27")

# The committed award files the engine matches against. South Dakota has two
# (the portal contracts and the two announced rounds). A state absent here has
# no award file, and every one of its candidates is hand-read.
DISPO_AWARD_FILES <- list(
  FL = "fl_year1_awardees.csv",
  GA = "ga_great_health_awards.csv",
  PA = "pa_year1_awardees.csv",
  AL = "al_year1_awardees.csv",
  AK = "ak_year1_awardees.csv",
  OR = "or_year1_awardees.csv",
  KS = "ks_year1_awardees.csv",
  MD = "md_year1_awardees.csv",
  VT = "vt_year1_awardees.csv",
  WA = "wa_year1_awardees.csv",
  WV = "wv_year1_awardees.csv",
  NC = "nc_year1_awardees.csv",
  VA = "va_year1_awardees.csv",
  SD = c("sd_rht_contracts.csv", "sd_year1_awardees.csv")
)

# The archived state document each award file was built from -- the evidence
# an IN_FILE group cites.
DISPO_FILE_EVIDENCE <- c(
  FL = "data/evidence/recheck/2026-08-29/FL/FL_year1_awardees_governor_list.pdf",
  GA = "data/evidence/GA/ (four DCH announcements, the AHEAD roster, two signed notices of award)",
  PA = "data/evidence/PA/2026-08-28_dhs_rural_health_selected_projects.html",
  AL = "data/evidence/AL/2026-08-24_governor_ivey_first_arhtp_grants.html",
  AK = "data/evidence/AK/2026-09-21_ak_rhtp_awardsnotice_2026.xlsx",
  OR = "data/evidence/OR/ (2026-05-07 Transformation bulletin, 2026-07-07 release, Catalyst xlsx, awards page)",
  KS = "data/evidence/KS/ (REH CAP + RPGP winners, CHW+AFIM descriptions, Emerging Technology winners)",
  MD = "data/evidence/MD/ (the two Pillar 2 award-offer PDFs)",
  VT = "data/evidence/recheck/2026-09-23/VT/vt_year1_awards.html",
  WA = "data/evidence/recheck/2026-09-23/WA/hca_rhtp_webinar_2026-09-16.pdf",
  WV = "data/evidence/recheck/2026-09-23/WV/ (five Governor's releases)",
  NC = "data/evidence/NC/ (MIH and ROOTS releases)",
  VA = "data/evidence/recheck/2026-09-23/VA/gov_release_2026-08-28_122M.pdf",
  SD = "data/evidence/SD/2026-08-28_open_sd_contract_search_RHT.html"
)

# Which document an IN_FILE match should be credited to when RCJ carries one
# award twice. The state's own award document wins; the other record is the
# aggregator's re-publication.
DISPO_PRIMARY_DOC <- c(
  OR = "Catalyst Awards|Funding for Rural Hospitals and Rural Health Clinics",
  KS = "Awardees|Award Recipients|Awarded Project Descriptions"
)

DISPO_NEW_EVIDENCE <- "data/evidence/rcj_dispositions/2026-09-24"


# -- Hand-read verdicts --------------------------------------------------------
#
# One row per rule. `doc`, `name` and `desc` are regular expressions over
# source_doc_title, awardee_name_clean and program_description; an empty
# string matches anything. A rule applies only to candidates the engine did not
# place. Rules sharing a `group` aggregate into one disposition row.
#
# Tokens in `evidence`, filled from the group's own rows so no count is typed:
#   {rows} candidates in the group    {amount} their RCJ amount sum
#   {new}  of them first seen after the 2026-08-27 pull

DISPO_HAND_READ <- tibble::tribble(
  ~state, ~doc, ~name, ~desc, ~group, ~disposition, ~evidence,

  # ---- Oregon ---------------------------------------------------------------
  "OR", "Healthy Homes Grant Program", "", "",
  "OHA Healthy Homes Grant Program release", "NOT_RHTP_ANOTHER_PROGRAMME_NAMED_IN_TITLE",
  "{rows} row(s), {amount}. The source document's own title names OHA's Healthy Homes Grant Program, a different OHA programme; the recipient appears in none of OHA's four RHTP award documents archived under data/evidence/OR/, and or_year1_awardees.csv does not carry it. {new} first seen after 08-27.",

  "OR", "What is the RHTP\\?|^OR - 2026 - Oregon RHTP$", "", "",
  "Pool and class rows from OHA's programme pages", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. Each 'awardee' is a CLASS or a POOL, not a recipient: '35 Rural Hospitals in Oregon' at $35M (OHA's Transformation hospital table totals $34,998,000), '33 Local Public Health Authorities' at $5M (an unnamed pool, one aggregate row in the file), '[the tribal set-aside]' at $20M (the file's Tribal Initiative pool is $21.7M and names nobody), and ONE ROW WELDING NINETY-NINE RURAL HEALTH CLINICS INTO A SINGLE AWARDEE at $10M -- §6.2's multi-recipient field at its largest. Every named RHC is already a $100,000 row in the file. Evidence: data/evidence/OR/2026-05-07_oha_transformation_fund_bulletin.html. {new} first seen after 08-27.",

  "OR", "Funding for Rural Hospitals and Rural Health Clinics", "^Grand Total$|^Oregon Health Authority Announces", "",
  "Transformation bulletin: its total row and its own title read as awardees", "NOT_A_RECIPIENT_PARSE_ARTIFACT",
  "{rows} row(s), {amount}. Session 17's two defects, still live: RCJ ingests the bulletin's 'Grand Total' row ($34,998,000, OHA's own hospital-table total) and the bulletin's title paragraph ($963,000, the small-hospital tier figure) as awardees. Neither is a recipient. Evidence: data/evidence/OR/2026-05-07_oha_transformation_fund_bulletin.html. {new} first seen after 08-27.",

  "OR", "Funding for Rural Hospitals and Rural Health Clinics", "R HC$|P C$|M innville|a t Scappoose|o f Pendleton|C are N W", "",
  "Transformation RHCs under names RCJ's text layer broke", "RHTP_SUBAWARD_IN_FILE_UNDER_A_CORRUPTED_NAME",
  "{rows} row(s), {amount}. Real $100,000 Rural Health Clinic awards that ARE in or_year1_awardees.csv; RCJ's text layer splits words ('Mc M innville Internal Medicine', 'O HSU Family Medicine a t Scappoose', 'Urgent C are N W - Astoria'), so no exact name match is possible and none is attempted by machine (§2). Each was read against the file by hand: Good Shepherd Medical Group RHC, Madras Medical Group PC, McMinnville Internal Medicine, OHSU Family Medicine at Scappoose, Pediatric Specialists of Pendleton, UrgentCare NW - Astoria, all at $100,000. Evidence: data/evidence/OR/2026-05-07_oha_transformation_fund_bulletin.html. {new} first seen after 08-27.",

  "OR", "every Oregon county", "^End of worksheet$|^OHA$|^System of Care Advisory Council", "",
  "Immediate Impact rows at $0 and a worksheet footer", "NOT_A_PRICED_AWARD",
  "{rows} row(s), {amount}. 'End of worksheet' is the xlsx's own footer read as an awardee. 'OHA' and 'System of Care Advisory Council (SOCAC)' are the release's projects that print NO amount and no outside recipient; or_year1_awardees.csv carries them as 'System of Care Transformation Regional Convenings' and two 'Not identified in the source' rows, amount empty. RCJ's $0 is not a state figure. Evidence: data/evidence/OR/2026-07-07_oha_news_release.html. {new} first seen after 08-27.",

  "OR", "every Oregon county|Awards & Investments", "^(Comagine Health|Lines for Life|OHSU|ORPRN, ORCHWA|Oasis Clinic|Oregon AHEC|Oregon Community Food System Network|Oregon Washington health Network|Siskiyou Community Health Center|Oregon Rural Practice-based Research Network)", "",
  "Immediate Impact awards the file names differently", "RHTP_SUBAWARD_IN_FILE_UNDER_ANOTHER_NAME",
  "{rows} row(s), {amount}. Real Immediate Impact awards that ARE in or_year1_awardees.csv at the same amount to the dollar, where the release prints the PROJECT or a short form and the file keeps OHA's wording: Comagine Health ($288,104 'Comagine'; $254,334 'PRIME+ Training and Support for Peer Support Specialists'), Lines for Life ($80,765, 'Custody to Counseling Pipeline'), OHSU ($398,000), the ORPRN/ORCHWA/Familias/OWN partnership ($363,000, a §6.2 multi-recipient field), Oasis Clinic ($320,281), Oregon AHEC ($1,012,479), Oregon Community Food System Network ($358,171, 'Veggie Rx Expansion'), Oregon Washington Network ($79,615), and Siskiyou Community Health Center ($138,902, the EFDA dental workforce project). Matched by hand, because a machine may not (§2). Evidence: data/evidence/OR/2026-07-07_oha_news_release.html. {new} first seen after 08-27.",

  "OR", "Harney District Hospital Secures", "", "",
  "Harney District Hospital's Catalyst award, re-published and rounded", "RHTP_SUBAWARD_IN_FILE_ROUNDED_ELSEWHERE",
  "{rows} row(s), {amount}. The Catalyst award to Harney County Health District (DBA Harney District Hospital), $2,409,781.20 in OHA's own Catalyst data file and in or_year1_awardees.csv, re-published by a second outlet as '$2.4 Million'. Counting it would count one award twice. The '2025' in RCJ's title is aggregator metadata, not a date (§2). Evidence: data/evidence/OR/2026-08-28_oha_RHTP-Awards-Data.xlsx. {new} first seen after 08-27.",

  # ---- Alaska ---------------------------------------------------------------
  "AK", "Recent Updates", "^32 projects", "",
  "A week's count carried as an awardee", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. '32 projects (community organizations selected via RHTP)' is Alaska's Week 5 line from its Year 1 funding-cycle update -- a count of award actions, each already a named row in ak_year1_awardees.csv. Evidence: data/evidence/AK/2026-09-21_alaska_rhtp_year1_funding_cycle_update.pdf. {new} first seen after 08-27.",

  # ---- Alabama --------------------------------------------------------------
  "AL", "", "^St\\. Clair Community Health Clinic", "",
  "St. Clair Community Health Clinic, whose 'St.' the source dropped", "RHTP_SUBAWARD_IN_FILE_UNDER_THE_SOURCE_SPELLING",
  "{rows} row(s), {amount}. Three real awards that ARE in al_year1_awardees.csv at the same amounts. The Governor's release prints the name '<strong> Clair Community Health Clinic Inc.</strong>' with 'St.' absent, and the file keeps the source's language (§8); RCJ restores the 'St.'. Evidence: data/evidence/AL/2026-08-24_governor_ivey_first_arhtp_grants.html. {new} first seen after 08-27.",

  # ---- Georgia --------------------------------------------------------------
  "GA", "Initiative 5: Leveraging Technology for Healthcare Innovations", "", "",
  "'Rural Hospitals in Georgia' -- the surgical-robotics plan estimate", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. A class, not a recipient, at the application's own multi-year estimate: Georgia's Initiative 5 page gives Surgical Robotics 'Estimated Funding $20,000,000 total / $2,000,000 in Budget Period 1'. The awards are the thirteen $2,000,000 robots on DCH's signed notice, all in ga_great_health_awards.csv. Evidence: data/evidence/recheck/2026-09-23/GA/ga_application_initiative_five.html. {new} first seen after 08-27.",

  "GA", "Opportunities for Hospitals Project", "", "",
  "GREAT Health 'Opportunities for Hospitals' guidance: partners at $1", "RHTP_BUT_NOT_A_SUBAWARD",
  "{rows} row(s), {amount}. RCJ classes its own source GUIDANCE, not an award announcement; it describes programmes 'directly funded through RHTP with no cost to hospitals', and its 'awardees' here (Augusta University Cyber Innovation & Training Center, GTRI, Sellers Dorsey, UGA Institute of Disaster Management) are partners and vendors named in it, each at a $1 placeholder (§6.1 mode 3), on no DCH notice archived here. The same document's fifth name, Alzheimer's Association, is a real Phase 1/2 recipient and sits in the engine's no-state-amount group. No state copy of the guidance is archived. {new} first seen after 08-27.",

  "GA", "Dual Track", "", "",
  "DCH's Dual Track Rural Hospital Support and Remote Critical Care grants", "NOT_RHTP_STATE_PROGRAM",
  "{rows} row(s), {amount}. The wrong PROGRAMME (§6.1 mode 1). Dual Track is the State Office of Rural Health's own grant series, first solicited 2023-11-15, with FY25 notices of award in 2025 and an FY26 round, each RFGA 'subject to the availability of appropriated funds'; the FY26 RFGA and the RCCS26 RFGA contain 'Rural Health Transformation', 'RHTP', 'GREAT Health' and 'Centers for Medicare' ZERO times each, and GREAT Health's own funding-opportunities page lists none of it. Named hospitals, real awards, state money. Evidence: " %>% paste0(DISPO_NEW_EVIDENCE, "/GA/ (the three RFGAs and DCH's Grant Announcements page); data/evidence/recheck/2026-09-23/GA/ga_find_funding_opportunities_2026-09-23.html. {new} first seen after 08-27."),

  "GA", "Point-of-Care Telepods", "\\(second award\\)$", "",
  "Miller County Hospital's second telepod award, annotated by RCJ", "RHTP_SUBAWARD_IN_FILE_UNDER_AN_ANNOTATED_NAME",
  "{rows} row(s), {amount}. Real: Miller County Hospital holds two telepod awards on DCH's signed notice (applications GREAT-001222 and GREAT-001350, $356,465 each), both in ga_great_health_awards.csv. RCJ appends '(second award)' to the name. Evidence: data/evidence/GA/ga_noa_point_of_care_telepods_signed.pdf. {new} first seen after 08-27.",

  # ---- Kansas ---------------------------------------------------------------
  "KS", "Year 2 Budget Narrative", "", "",
  "Year 2 budget-narrative lines", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. The wrong TIER (§6.1 mode 2): contractor and subrecipient lines in Kansas's Year 2 (FY2026-27) budget narrative, a plan for the NEXT budget period, including two rows whose 'awardee' is 'Implementing Healthcare Organizations selected in Year 1/Year 2' -- a class. Not awards. No state copy of the Year 2 narrative is archived here. {new} first seen after 08-27.",

  "KS", "Year 1 Budget Narrative Revision", "", "",
  "Year 1 budget-narrative contractor lines, carried once per revision", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. Tier 2 (§6.1 mode 2): contractor lines in the Year 1 budget narrative (BDO, Boston Consulting Group, Fort Hays State's Docking Institute, Sunflower Foundation, UKHS Care Collaborative Association). RCJ prices Revision 1 and Revision 2 as separate awards, so the same line appears twice at two figures (BCG $3,000,000 and $4,750,000) -- Connecticut's revision double-count. Session 28 found the plan's pool budgets deliberately do not reconcile to the awards (§0.3). Evidence: data/evidence/KS/2026-08-29_kdhe_rhtp_program_page.html (the narrative is registered as `budget_rev2` in R/03o). {new} first seen after 08-27.",

  "KS", "Emerging Technology Committee Meeting", "", "",
  "An allocation minuted by the Emerging Technology Committee", "RHTP_BUT_NOT_A_SUBAWARD",
  "{rows} row(s), {amount}. The committee summary says '$6 million was allocated for ambient AI at Oracle-based rural sites with Great Plains Health Alliance as the initial partner' -- an allocation, not an award. Great Plains Health Alliance's actual RHTP award is its RPGP grant, $5,000,000, in ks_year1_awardees.csv. Evidence: data/evidence/KS/2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf. {new} first seen after 08-27.",

  "KS", "KRHIA Meeting", "^Stormont Vail Health$", "",
  "KRHIA deck: Stormont Vail at a figure no KDHE document prints", "AMOUNT_MATCHES_NO_STATE_FIGURE",
  "{rows} row(s), {amount}. UNRESOLVED. Stormont Vail Health's only Kansas award here is its RPGP grant, $5,465,969; the KRHIA deck's $2,180,000 matches no KDHE figure, rounded or otherwise, and the deck is not archived. Not a second award on this evidence (§0.4). {new} first seen after 08-27.",

  "KS", "KRHIA Meeting", "", "",
  "KRHIA deck: the REH/CAP awards re-published rounded to $10,000", "RHTP_SUBAWARD_IN_FILE_ROUNDED_ELSEWHERE",
  "{rows} row(s), {amount}. Real REH/CAP awards that ARE in ks_year1_awardees.csv, re-published in the KRHIA meeting deck rounded to the nearest $10,000 (Clara Barton $2,933,500 -> $2,930,000; Compass Behavioral Health $165,000 -> $170,000). The four whose award was already round carry exactly and sit in the CARRIED_TWICE group. Counting these would count each award twice. The '2025' in RCJ's title is aggregator metadata (§2). Evidence: data/evidence/KS/2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf. {new} first seen after 08-27.",

  # ---- Maryland -------------------------------------------------------------
  "MD", "", "^Maryland Health Care Commission", "",
  "The MHCC pool", "RHTP_BUT_NOT_A_SUBAWARD",
  "{rows} row(s), {amount}. Session 21's finding, unchanged: the Maryland Health Care Commission's RFA budget, Tier 2, not an award; its eight award offers are in md_year1_awardees.csv. Evidence: data/evidence/MD/2026-08-29_mdh_pillar2_expand_primary_care_bp1_award_offers.pdf. {new} first seen after 08-27.",

  "MD", "", "^Charles County Health Department$", "",
  "Charles County's health department under a second spelling", "RHTP_SUBAWARD_IN_FILE_UNDER_ANOTHER_NAME",
  "{rows} row(s), {amount}. Real: MDH's offer to 'Charles County Department of Health', $511,347, is in md_year1_awardees.csv; RCJ spells it 'Charles County Health Department'. Matched by hand (§2). Evidence: data/evidence/MD/2026-08-29_mdh_pillar2_transformation_fund_bp1_award_offers.pdf. {new} first seen after 08-27.",

  # ---- Vermont --------------------------------------------------------------
  "VT", "Green Mountain Care Board Approves FY27 Hospital Budgets", "", "",
  "GMCB hospital budget approvals", "NOT_RHTP_HOSPITAL_BUDGET_REGULATION",
  "{rows} row(s), {amount}. The wrong KIND of action (§6.1 mode 3): the Green Mountain Care Board's regulatory approval of FY27 hospital budgets ($30.8M and $74.7M are Grace Cottage's and Mt. Ascutney's approved budgets), not money awarded to anyone. RCJ carries each twice, once per copy of the release ('2026' and '2027' in its titles). Grace Cottage's real RHTP award is its $169,528.40 AI-scribe grant, in vt_year1_awardees.csv. Evidence: data/evidence/recheck/2026-09-23/VT/vt_year1_awards.html. {new} first seen after 08-27.",

  "VT", "Bid #73741", "", "",
  "AHS grant-management system procurement", "RHTP_ADMINISTRATIVE_CONTRACT_NOT_IN_FILE",
  "{rows} row(s), {amount}. An RHTP administrative procurement (Agate Software, the AHS RHT grants-management system, awarded by sealed bid) -- a vendor contract, not a subaward to a provider. It is not on the healthcarereform.vermont.gov executed-agreements roster archived at data/evidence/recheck/2026-09-23/VT/vt_year1_awards.html, and no state copy of the bid award page is archived here. {new} first seen after 08-27.",

  "VT", "first batch of \\$195 million", "Springfield Center|St\\. Johnsbury Center|Brattleboro Development|Vermont Student Assistance", "",
  "Real awards the roster names by legal name or prices exactly", "RHTP_SUBAWARD_IN_FILE_UNDER_ANOTHER_NAME",
  "{rows} row(s), {amount}. Real awards that ARE in vt_year1_awardees.csv: Springfield and St. Johnsbury Centers for Living and Rehabilitation are the DBAs of '105 Chester Road Opco LLC' ($286,600) and '1248 Hospital Drive Opco LLC' ($531,750); 'Brattleboro Development Credit Corporation' is the roster's '... Corp' ($150,389.70); VSAC's '$9 million' is the release's rounding of the roster's $9,059,785. Matched by hand (§2). Evidence: data/evidence/recheck/2026-09-23/VT/vt_year1_awards.html, vt_vdh_release.html. {new} first seen after 08-27.",

  "VT", "first batch of \\$195 million", "Community Colleges of Vermont|The Pines at Rutland", "",
  "Announced awards the executed-agreements roster does not carry, at $1", "RHTP_SUBAWARD_NOT_IN_FILE_AT_A_PLACEHOLDER",
  "{rows} row(s), {amount}. REAL AND NOT IN THE FILE. DAIL's release says The Pines at Rutland Center for Nursing and Rehabilitation and Community Colleges of Vermont 'have been awarded funding', with no amount; RCJ carries each at $1 (§6.1 mode 3's placeholder). Neither is on Vermont's executed-agreements roster, which the state calls partial -- so vt_year1_awardees.csv is incomplete by these two, and it is REPORTED, not extracted. Evidence: data/evidence/recheck/2026-09-23/VT/vt_dail_release.html. {new} first seen after 08-27.",

  # ---- Washington -----------------------------------------------------------
  "WA", "big picture", "", "",
  "First-tier allocations the file carries under HCA's names", "RHTP_SUBAWARD_IN_FILE_UNDER_ANOTHER_NAME",
  "{rows} row(s), {amount}. Real first-tier allocations that ARE in wa_year1_awardees.csv at the same amounts, under HCA's own spellings: WSHA $42,000,000 (Unclear in the file, queued WA_WSHA_FLOW), The Rural Collaborative $5,430,000, University of Washington (WWAMI) $5,460,000, Washington State University $2,570,000. Matched by hand (§2). Evidence: data/evidence/recheck/2026-09-23/WA/hca_rhtp_webinar_2026-09-16.pdf. {new} first seen after 08-27.",

  "WA", "Tribal RHT|^WA - 2025 - Washington RHTP$", "", "",
  "The tribal set-aside, twice, as a class", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. A class, not a recipient: 'Washington Tribes and Indian Health Care Providers' at $30.2M (10% of the award, a multi-year share) and 'All 29 Federally-Recognized Tribes' at $18.1M. HCA's webinar prices the Year 1 tribal line at $19.41M and names no Tribe; the file carries it as one row, amount empty. Evidence: data/evidence/recheck/2026-09-23/WA/hca_rhtp_webinar_2026-09-16.pdf. {new} first seen after 08-27.",

  # ---- West Virginia --------------------------------------------------------
  "WV", "Mountain State Care Force", "", "",
  "The Mountain State Care Force application guidance", "RHTP_BUT_NOT_A_SUBAWARD",
  "{rows} row(s), {amount}. A solicitation's pool with the PROGRAMME as awardee (§6.1): 'Application Guidance and Instructions' for a single $1.5M grant; no grantee is named in any WV release archived here. Evidence: data/evidence/recheck/2026-09-23/WV/wv_grants.html. {new} first seen after 08-27.",

  "WV", "TYBS CRHD|CSSD EPS|WVSILC RYPAS|WVU Cancer Institute \\(BCCSP\\)", "", "",
  "Four ordinary state grant documents titled by file name", "NOT_ESTABLISHED_AS_RHTP",
  "{rows} row(s), {amount}. Session 43's warning, still true. The 'titles' are file names (a budget justification, a direct award for the immunization registry WVSIIS, a Statewide Independent Living Council grant agreement, the Breast and Cervical Cancer Screening Program), their own descriptions name other programmes, and none is among the seven awards in West Virginia's five RHTP releases or on its RHTP pages. Not coded RHTP on this evidence (§0.4). Evidence: data/evidence/WV/2026-09-23_wv_rhtp_programme.html, data/evidence/recheck/2026-09-23/WV/. {new} first seen after 08-27.",

  "WV", "\\$855,400 Award", "^West Virginia Health Information Network$", "",
  "WVHIN's Connected Care Grid award under a shorter name", "RHTP_SUBAWARD_IN_FILE_UNDER_ANOTHER_NAME",
  "{rows} row(s), {amount}. Real: 'West Virginia Health Information Network (WVHIN)', $855,400, is in wv_year1_awardees.csv; RCJ drops the acronym. Evidence: data/evidence/recheck/2026-09-23/WV/wv_art_855400-award-strengthen-statewide-health.html. {new} first seen after 08-27.",

  # ---- North Carolina -------------------------------------------------------
  "NC", "Advisory Committee Meeting", "", "",
  "YMCA of Southeastern North Carolina -- a lead, not in the file", "RHTP_SUBAWARD_LEAD_UNVERIFIED",
  "{rows} row(s), {amount}. RCJ reads an NCDHHS advisory-committee item as reporting an award of 'over $195,000' to YMCA of Southeastern North Carolina for minority diabetes prevention -- the NC Minority Diabetes Prevention opportunity that had closed with no roster. nc_year1_awardees.csv holds the MIH and ROOTS rosters only, so if real this is an award the file does not carry. No state copy is archived here and it is NOT verified (§0.4). {new} first seen after 08-27.",

  # ---- Virginia -------------------------------------------------------------
  "VA", "May Releases", "", "",
  "Virginia Highlands Community College -- real, and not in the file", "RHTP_SUBAWARD_NOT_IN_FILE",
  "{rows} row(s), {amount}. REAL AND NOT IN THE FILE. The Governor's 2026-05-21 release names VHCC's $127,500 LPN expansion as Virginia's first RHTP sub-award, matching RCJ exactly (session 15). va_year1_awardees.csv holds the eleven first-tier partners of 2026-08-28 and omits it; a community college, so NON_HOSPITAL either way. Reported, not extracted. Evidence: data/evidence/VA/2026-05-21_governor_vhcc_first_rhtp_grant.pdf. {new} first seen after 08-27.",

  # ---- South Dakota ---------------------------------------------------------
  "SD", "First Awards for RHT Grant Program Management", "", "",
  "Program-management consultants from DOH's release, priced by the release", "RHTP_ADMINISTRATIVE_CONTRACT_PRICED_ELSEWHERE",
  "{rows} row(s), {amount}. The same consultants the portal carries (session 14): Black Hills Special Services Cooperative at a $1 placeholder, and Business Concepts & Applications at the release's $500,000 against the portal contract's $250,000 -- two figures, neither corrected (§8). Evidence: data/evidence/SD/2026-08-28_open_sd_contract_search_RHT.html. {new} first seen after 08-27.",

  "SD", "Technology and Data Grants", "", "",
  "The Rural Strong round as one awardee, under the wrong release", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. 'South Dakota Rural Strong Grants' at $31.5M is a ROUND, not a recipient -- 28 grants that the July release named nobody for -- and RCJ files it under the August Technology and Data release, which is the OTHER round ($90M, 82 grants). sd_year1_awardees.csv carries both rounds as unnamed aggregate rows with `amount` empty. Evidence: data/evidence/SD/announcements/KB0046839.html. {new} first seen after 08-27.",

  # ---- Colorado -------------------------------------------------------------
  "CO", "Work Requirements Implementation APD", "", "",
  "Medicaid work-requirements APD vendors", "NOT_RHTP_MEDICAID",
  "{rows} row(s), {amount}. The wrong PROGRAMME (§6.1 mode 1): a Medicaid Advance Planning Document for implementing H.R.1's work requirements -- the same statute as RHTP, a different programme -- pricing eligibility-system vendors (Deloitte, Ernst & Young, Health Tech Solutions, North Highland, Contexture, Prime Health). Not RHTP. No state copy is archived; HCPF's RHTP page (data/evidence/recheck/2026-09-23/CO/co_hcpf_rhtp.html) names none of them. {new} first seen after 08-27.",

  "CO", "Budget_Narrative", "", "",
  "Budget-narrative lines", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. Tier 2: lines in Colorado's RHTP budget narrative (Colorado Rural Health Center technical assistance, the Office of eHealth Innovation). HCPF 'anticipates making our award announcements by the end of September 2026'. Evidence: data/evidence/recheck/2026-09-23/CO/co_hcpf_rhtp.html. {new} first seen after 08-27.",

  "CO", "eHealth Solutions Challenge", "", "",
  "OeHI eHealth Solutions Challenge winners", "NOT_ESTABLISHED_AS_RHTP",
  "{rows} row(s), {amount}. Three pilot prizes from the Office of eHealth Innovation's challenge with the Colorado Smart Cities Alliance; the release as RCJ carries it does not tie the money to RHTP and HCPF's RHTP pages name no award. One pilot runs at a critical access hospital (Weisbrod). Not coded RHTP on this evidence (§0.4). Evidence: data/evidence/recheck/2026-09-23/CO/co_hcpf_rhtp.html. {new} first seen after 08-27.",

  "CO", "Sole Source", "", "",
  "A PROPOSED sole-source contract to the Colorado Rural Health Center", "NOT_A_SUBAWARD_PROPOSED_SOLE_SOURCE",
  "{rows} row(s), {amount}. A Notice of Proposed Sole Source, not an award, running to June 2031 -- a multi-year ceiling, not a Year 1 figure. HCPF's RHTP page does say it 'has awarded a contract to the Colorado Rural Health Center to provide training and technical assistance' to applicants, with no amount; whether this notice is that contract is not established. Evidence: data/evidence/recheck/2026-09-23/CO/co_hcpf_rhtp.html. {new} first seen after 08-27.",

  # ---- Minnesota ------------------------------------------------------------
  "MN", "Rural Tribal Nations", "", "",
  "Estimated MAXIMUM tribal awards from the notice of grant opportunity", "TIER_2_ESTIMATED_MAXIMUM",
  "{rows} row(s), {amount}. The wrong TIER: MDH's tribal notice of grant opportunity prints 'Tribal Nation Estimated Maximum Award in Budget Period 1' for each of ten Tribal Nations -- ceilings each 'may request up to', not awards. RCJ's amounts equal the table's to the dollar. Evidence: data/evidence/recheck/2026-09-24/MN/tribal_nogo_ESTIMATED_MAXIMUM_awards_table.pdf. {new} first seen after 08-27.",

  # ---- Arizona --------------------------------------------------------------
  "AZ", "Application Overview Public Webinar", "", "",
  "Application-webinar budget lines against AHCCCS itself", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. Tier 2 and pre-award: budget lines from AHCCCS's application webinar of 2025-11-13, before CMS awarded Arizona anything, with the administering agency as 'awardee'. Session 20's sweep quarantines them PROVENANCE_PREDATES_NOA. Evidence: data/evidence/recheck/2026-09-23/AZ/az_ahcccs_rhtp.html. {new} first seen after 08-27.",

  "AZ", "ADHS Highlights", "", "",
  "A programme name as awardee", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. 'Chronic Disease Prevention & Management' is an ADHS programme line, not an organisation (§6.1). Evidence: data/evidence/recheck/2026-09-23/AZ/az_ahcccs_rhtp.html. {new} first seen after 08-27.",

  # ---- Hawaii ---------------------------------------------------------------
  "HI", "\\$58M in federal investment", "", "",
  "JABSOM's lead-agency allocation", "RHTP_ALLOCATION_TO_AN_ADMINISTERING_UNIT",
  "{rows} row(s), {amount}. The Governor: '$45 million for the University of Hawaii John A. Burns School of Medicine to administer workforce development programs through ... HOME RUN' -- an allocation to a state university unit that will re-grant (Virginia's first-tier shape), not a provider subaward; a university, so never a hospital dollar. Hawaii has no award file. Evidence: data/evidence/HI/2026-09-03_hi_governor_release_58m_2026-09-01.html. {new} first seen after 08-27.",

  "HI", "Federally Qualified Health Center", "", "",
  "HPCA's FQHC award, priced only by RCJ", "RHTP_SUBAWARD_AMOUNT_UNVERIFIED",
  "{rows} row(s), {amount}. The award is real -- SHPDA's page reads '(Notice of Award on 8/28 to Hawaii Primary Care Association)' -- but its amount lives only in HANDS, which is 403 to this environment, so RCJ's figure is unverified (§0.4). An FQHC association, not a hospital. Evidence: data/evidence/HI/2026-09-03_hi_shpda_rhtp_programme.html. {new} first seen after 08-27.",

  # ---- Montana --------------------------------------------------------------
  "MT", "RHTPBudgetNarrative", "", "",
  "A budget-narrative line", "TIER_2_BUDGET_LINE",
  "{rows} row(s), {amount}. Tier 2: StationMD's IDD telehealth pilot as priced in Montana's budget narrative. Not an award. Evidence: data/evidence/recheck/2026-09-23/MT/dphhs_rhtp_programme.html. {new} first seen after 08-27.",

  "MT", "Stakeholder Advisory Committee", "", "",
  "Big Sky Care Connect, from an advisory-committee deck", "NOT_ESTABLISHED_AS_AN_AWARD",
  "{rows} row(s), {amount}. Montana's HIE, priced in an advisory-committee deck that speaks of 'awarded vendor contracts for ... HIT'. No state award notice naming it is archived here and DPHHS's RHTP pages name no award to it; the state's Jaggaer channel is unreadable. UNRESOLVED (§0.4). Evidence: data/evidence/recheck/2026-09-23/MT/dphhs_rhtp_rfps.html. {new} first seen after 08-27.",

  # ---- Utah -----------------------------------------------------------------
  "UT", "Utah Health Information Network|Without Engaging In A Standard Procurement", "", "",
  "UHIN's sole-source award, carried once per document", "RHTP_SUBAWARD_CARRIED_TWICE_AMOUNT_DISAGREES",
  "{rows} row(s), {amount}. ONE award under two documents (the notice of intent to award without standard procurement, and Bonfire KR27-4) -- Connecticut's revision double-count. DHHS's own status dashboard lists 'LINCS 7.1-7.2 ... Sole Source: UHIN ... Contracted ... Up to $1,000,000.00' for Year 1, so RCJ's $3,000,000 disagrees with the state (§8: recorded, not resolved). Utah has no award file. Evidence: data/evidence/recheck/2026-09-23/UT/ut_dhhs_rhtp_status_dashboard.html, ut_bonfire_past_opportunities.json. {new} first seen after 08-27.",

  # ---- Massachusetts --------------------------------------------------------
  "MA", "RHTP Project Management Service", "", "",
  "A project-management RFQ at $1", "RHTP_BUT_NOT_A_SUBAWARD",
  "{rows} row(s), {amount}. An RFQ for RHTP project-management services (26EHSKWRHTPRFQ) with Deloitte at a $1 placeholder. Whether it was awarded is UNKNOWN, not no: COMMBUYS returns no bid detail and every mass.gov path is 403 (§0.4). An administrative vendor, never a hospital. Evidence: data/evidence/recheck/2026-09-24/MA/commbuys_bidDetail_26EHSKWRHTPRFQ_not_found.html. {new} first seen after 08-27.",

  # ---- North Dakota ---------------------------------------------------------
  "ND", "Rightsizing", "", "",
  "'15 selected CAHs' -- a class", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. A class, not a recipient (session 11): critical access hospitals that 'may receive an additional $42,000' for Eide Bailly's analytics tool, 15 x $42,000. ND HHS lists the Rightsizing opportunity 'Closed (41 Applicants)' and names nobody; Eide Bailly is the state's preferred TA vendor. Evidence: data/evidence/recheck/2026-09-23/ND/hhs_rhtp_funding.html. {new} first seen after 08-27.",

  # ---- Rhode Island ---------------------------------------------------------
  "RI", "85 Rhode Island primary care practices", "", "",
  "'85 primary care practices' -- a class, provenance unread", "RHTP_BUT_A_CLASS_NOT_A_RECIPIENT",
  "{rows} row(s), {amount}. A class, not a recipient. Whether it is RHTP money at all is not established: RCJ's own record dates the announcement June 2025, six months before the 2025-12-29 NOA, and the state page (eohhs.ri.gov/Primary-Care-Grants) is behind a Cloudflare challenge, 403 to this environment, so the state's own words are UNREAD (§0.4). Evidence: data/evidence/recheck/2026-09-23/RI/ri_eohhs_rhtp_page_CLOUDFLARE_403.html. {new} first seen after 08-27."
)


# -- Engine --------------------------------------------------------------------

#' The exact name key. Punctuation and case only -- never a fuzzy match (§2).
dispo_name_key <- function(x) {
  x <- tolower(dplyr::coalesce(as.character(x), ""))
  x <- gsub("[‘’‚‛]", "'", x)
  x <- gsub("[“”]", "\"", x)
  x <- gsub("[^a-z0-9 ]", " ", x)
  stringr::str_squish(x)
}

#' A state's live RCJ Tier 3 candidates
dispo_candidates <- function(state, rt = NULL) {
  if (is.null(rt)) rt <- rhtp_record_table_live()
  x <- rt[rt$award_tier %in% "SUBAWARD" & rt$state %in% state, , drop = FALSE]
  tibble::as_tibble(x) %>%
    dplyr::mutate(
      k = dispo_name_key(.data$awardee_name_clean),
      a = round(as.numeric(.data$amount_announced)),
      first_seen_date = as.Date(substr(as.character(.data$first_seen), 1, 10)),
      is_new = .data$first_seen_date > DISPO_PRIOR_PULL
    )
}

#' A state's committed award file(s), keyed
dispo_award_file <- function(state) {
  files <- DISPO_AWARD_FILES[[state]]
  if (is.null(files)) return(NULL)
  purrr::map_dfr(files, function(f) {
    readr::read_csv(rhtp_path("reference", f), show_col_types = FALSE,
                    col_types = readr::cols(.default = "c"),
                    progress = FALSE) %>%
      dplyr::transmute(file = f, awardee = .data$awardee,
                       amount = suppressWarnings(as.numeric(.data$amount)))
  }) %>%
    dplyr::mutate(k = dispo_name_key(.data$awardee), a = round(.data$amount))
}

#' Classify every candidate against the award file
#'
#' @return candidates with `engine_class` and, for the file, a count of rows
#'   no candidate matched (attribute `file_uncarried`)
dispo_engine <- function(cands, file) {
  cands$engine_class <- NA_character_
  if (is.null(file)) {
    cands$engine_class <- "NAME_NOT_IN_FILE"
    return(cands)
  }
  st <- unique(cands$state)
  pref <- DISPO_PRIMARY_DOC[st]
  primary <- if (length(st) == 1L && !is.na(pref)) {
    stringr::str_detect(dplyr::coalesce(cands$source_doc_title, ""), pref)
  } else rep(FALSE, nrow(cands))
  ord <- order(!primary, cands$source_doc_title, cands$record_id)
  used <- rep(FALSE, nrow(file))
  for (i in ord) {
    hit <- which(file$k == cands$k[i] & !is.na(file$a) &
                   abs(file$a - cands$a[i]) <= 1 & !used)
    if (length(hit)) {
      used[hit[1]] <- TRUE
      cands$engine_class[i] <- "IN_FILE_AMOUNT_MATCHES"
    }
  }
  for (i in which(is.na(cands$engine_class))) {
    same <- file$k == cands$k[i]
    cands$engine_class[i] <-
      if (!any(same)) "NAME_NOT_IN_FILE"
      else if (any(same & !is.na(file$a) & abs(file$a - cands$a[i]) <= 1)) "IN_FILE_CARRIED_TWICE"
      else if (all(is.na(file$a[same]))) "IN_FILE_UNPRICED"
      else "IN_FILE_AMOUNT_DIFFERS"
  }
  attr(cands, "file_uncarried") <- file[!used, , drop = FALSE]
  cands
}

#' Place every candidate the engine did not, from DISPO_HAND_READ
#'
#' Refuses a candidate no rule places, one two rules place, and a rule that
#' places nothing.
dispo_hand_place <- function(cands, state) {
  rules <- DISPO_HAND_READ[DISPO_HAND_READ$state == state, , drop = FALSE]
  open <- which(cands$engine_class %in% c("NAME_NOT_IN_FILE", "IN_FILE_AMOUNT_DIFFERS"))
  cands$rule <- NA_integer_
  hits_per_rule <- integer(nrow(rules))
  rx <- function(p, x) if (!nzchar(p)) rep(TRUE, length(x)) else
    stringr::str_detect(dplyr::coalesce(x, ""), p)
  for (i in open) {
    m <- which(vapply(seq_len(nrow(rules)), function(r) {
      rx(rules$doc[r], cands$source_doc_title[i]) &&
        rx(rules$name[r], cands$awardee_name_clean[i]) &&
        rx(rules$desc[r], cands$program_description[i])
    }, logical(1)))
    # First matching rule wins, so a narrow rule listed before a broad one
    # (Stormont Vail before the rest of the KRHIA deck) takes its row.
    if (length(m)) {
      cands$rule[i] <- m[1]
      hits_per_rule[m[1]] <- hits_per_rule[m[1]] + 1L
    }
  }
  unplaced <- open[is.na(cands$rule[open])]
  if (length(unplaced)) {
    stop("[", state, "] ", length(unplaced), " live RCJ Tier 3 candidate(s) ",
         "that no disposition covers -- read them and add a verdict:\n  ",
         paste(sprintf("%s | %s | %s", cands$awardee_name_clean[unplaced],
                       format(cands$amount_announced[unplaced], big.mark = ","),
                       cands$source_doc_title[unplaced]), collapse = "\n  "),
         call. = FALSE)
  }
  stale <- which(hits_per_rule == 0L)
  if (length(stale)) {
    stop("[", state, "] hand-read verdict(s) that place no live candidate -- ",
         "the candidate set moved; re-read: ",
         paste(rules$group[stale], collapse = " | "), call. = FALSE)
  }
  cands$group <- NA_character_
  cands$disposition <- NA_character_
  cands$evidence_template <- NA_character_
  h <- !is.na(cands$rule)
  cands$group[h] <- rules$group[cands$rule[h]]
  cands$disposition[h] <- rules$disposition[cands$rule[h]]
  cands$evidence_template[h] <- rules$evidence[cands$rule[h]]
  cands
}

dispo_money <- function(x) paste0("$", format(round(x, 2), big.mark = ",",
                                             nsmall = 0, scientific = FALSE,
                                             trim = TRUE))

dispo_fill <- function(template, rows, amount, new) {
  template %>%
    stringr::str_replace_all(stringr::fixed("{rows}"), as.character(rows)) %>%
    stringr::str_replace_all(stringr::fixed("{amount}"), dispo_money(amount)) %>%
    stringr::str_replace_all(stringr::fixed("{new}"), as.character(new))
}

#' Build one state's disposition table
dispo_build_state <- function(state, rt = NULL) {
  cands <- dispo_candidates(state, rt)
  if (!nrow(cands)) stop("[", state, "] holds no live Tier 3 candidate.", call. = FALSE)
  file <- dispo_award_file(state)
  cands <- dispo_engine(cands, file)
  uncarried <- attr(cands, "file_uncarried")
  cands <- dispo_hand_place(cands, state)

  fname <- paste(DISPO_AWARD_FILES[[state]], collapse = " + ")
  fev <- DISPO_FILE_EVIDENCE[state]
  eng <- tibble::tribble(
    ~engine_class, ~label, ~disposition, ~text,
    "IN_FILE_AMOUNT_MATCHES", "In the award file, name and amount exact", "RHTP_SUBAWARD_IN_FILE",
    "{rows} row(s), {amount}. Each matches a row of %s on the normalised name and the amount to the dollar -- a real award this repository extracted from the state's own document, not from RCJ. {new} first seen after 08-27. Evidence: %s.",
    "IN_FILE_CARRIED_TWICE", "A second RCJ record of an award already matched", "DUPLICATE_OF_EXTRACTED_AWARD",
    "{rows} row(s), {amount}. The same name and amount as an award in %s that another RCJ record has already matched: RCJ ingests one award from two documents, or twice from one (§6.1 mode 4, wrong grain). Counting these counts each award twice. {new} first seen after 08-27. Evidence: %s.",
    "IN_FILE_UNPRICED", "In the award file, which prints no amount for it", "RHTP_SUBAWARD_IN_FILE_NO_STATE_AMOUNT",
    "{rows} row(s), {amount}. The recipient is in %s, where the state published the award and NO amount; RCJ's figure (a $0 or $1 placeholder, or its own) is not a state figure. {new} first seen after 08-27. Evidence: %s."
  )

  placed <- cands %>% dplyr::filter(!is.na(.data$group))
  out_hand <- placed %>%
    dplyr::group_by(.data$group, .data$disposition, .data$evidence_template) %>%
    dplyr::summarise(rcj_rows = dplyr::n(),
                     rcj_amount_sum = sum(.data$amount_announced, na.rm = TRUE),
                     new = sum(.data$is_new), .groups = "drop") %>%
    dplyr::mutate(evidence = purrr::pmap_chr(
      list(.data$evidence_template, .data$rcj_rows, .data$rcj_amount_sum,
           .data$new), dispo_fill)) %>%
    dplyr::select("group", "rcj_rows", "rcj_amount_sum", "disposition", "evidence")

  out_eng <- cands %>%
    dplyr::filter(is.na(.data$group)) %>%
    dplyr::select(-"disposition") %>%
    dplyr::inner_join(eng, by = "engine_class") %>%
    dplyr::mutate(doc = stringr::str_squish(dplyr::coalesce(.data$source_doc_title, "(no title)"))) %>%
    dplyr::group_by(.data$engine_class, .data$label, .data$disposition,
                    .data$text, .data$doc) %>%
    dplyr::summarise(rcj_rows = dplyr::n(),
                     rcj_amount_sum = sum(.data$amount_announced, na.rm = TRUE),
                     new = sum(.data$is_new), .groups = "drop") %>%
    dplyr::mutate(
      group = paste0(.data$label, " -- ", .data$doc),
      evidence = purrr::pmap_chr(
        list(sprintf(.data$text, fname, fev), .data$rcj_rows,
             .data$rcj_amount_sum, .data$new), dispo_fill)) %>%
    dplyr::arrange(match(.data$engine_class, eng$engine_class), .data$doc) %>%
    dplyr::select("group", "rcj_rows", "rcj_amount_sum", "disposition", "evidence")

  out <- dplyr::bind_rows(out_eng, out_hand)

  if (!is.null(uncarried) && nrow(uncarried)) {
    eg <- head(unique(uncarried$awardee), 6)
    out <- dplyr::bind_rows(out, tibble::tibble(
      group = "Award-file rows no RCJ candidate matches",
      rcj_rows = 0L, rcj_amount_sum = 0,
      disposition = "FILE_ROWS_RCJ_DOES_NOT_CARRY_EXACTLY",
      evidence = paste0(
        nrow(uncarried), " of ", nrow(dispo_award_file(state)), " row(s) of ",
        fname, " are matched by no live candidate on name and amount, ",
        sum(!is.na(uncarried$amount)), " of them priced (",
        dispo_money(sum(uncarried$amount, na.rm = TRUE)), "). Some are ",
        "carried under another name or figure (the hand-read groups above); ",
        "the rest RCJ does not carry, or the row is an unnamed pool or a ",
        "name the file keeps from the source. E.g.: ",
        paste(eg, collapse = "; "), ".")))
  }

  out <- out %>%
    dplyr::mutate(state = state, rcj_rows = as.integer(.data$rcj_rows),
                  rcj_amount_sum = round(.data$rcj_amount_sum, 2)) %>%
    dplyr::select("state", "group", "rcj_rows", "rcj_amount_sum",
                  "disposition", "evidence")

  # Coverage: the groups must account for every live candidate, exactly.
  if (sum(out$rcj_rows) != nrow(cands)) {
    stop("[", state, "] disposition covers ", sum(out$rcj_rows), " rows; ",
         nrow(cands), " live candidates.", call. = FALSE)
  }
  attr(out, "candidates") <- cands
  out
}

#' Build all twenty-three
dispo_build_all <- function(states = DISPO_STATES) {
  rt <- rhtp_record_table_live()
  purrr::set_names(purrr::map(states, dispo_build_state, rt = rt), states)
}

dispo_csv_path <- function(state) {
  rhtp_path("reference", paste0(tolower(state), "_rcj_candidate_disposition.csv"))
}

#' Assert every table, then write
dispo_write <- function(tables = dispo_build_all()) {
  for (st in names(tables)) {
    d <- tables[[st]]
    rhtp_assert_disposition_prose(d, st)
    readr::write_csv(d, dispo_csv_path(st), na = "")
  }
  invisible(tables)
}

dispo_validate <- function(tables = dispo_build_all()) {
  for (st in names(tables)) rhtp_assert_disposition_prose(tables[[st]], st)
  message("[03bh] ", length(tables), " states, ",
          sum(vapply(tables, function(d) sum(d$rcj_rows), integer(1))),
          " live Tier 3 candidates, every one placed; prose agrees with counts.")
  invisible(tables)
}

dispo_report <- function(tables = dispo_build_all()) {
  for (st in names(tables)) {
    d <- tables[[st]]; cands <- attr(d, "candidates")
    message(sprintf("\n%s  live %d  new since 08-27 %d", st, nrow(cands),
                    sum(cands$is_new)))
    for (i in seq_len(nrow(d))) {
      message(sprintf("  %4d  %-40s  %s", d$rcj_rows[i], d$disposition[i],
                      substr(d$group[i], 1, 90)))
    }
  }
  invisible(tables)
}


# -- CLI -----------------------------------------------------------------------

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) dispo_validate()
  if ("--build" %in% args)    dispo_write()
  if ("--report" %in% args)   dispo_report()
  if (!length(intersect(args, c("--validate", "--build", "--report")))) {
    message("usage: Rscript R/03bh_rcj_candidate_dispositions.R ",
            "[--validate] [--build] [--report]")
  }
}

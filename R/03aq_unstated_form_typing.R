# 03aq_unstated_form_typing.R --------------------------------------------------
# Session 50. THE TWO STATES THAT WERE NOT IN verification_queue_2.xlsx ARE
# TYPED DIRECTLY, UNDER SESSION 49'S THREE POLICIES.
#
# `MS_RECIPIENT_FORM_NOT_STATED` (96 rows / $56,022,017.62) and
# `SC_RECIPIENT_FORM_NOT_STATED` (150 rows / $92,759,791.23) are the two largest
# open form questions left in this repository, and they are open for one reason:
# Mississippi is not in the returned workbook at all, and South Carolina's rows
# were deliberately flagged in its own files only (session 47) because a
# verification pass was running elsewhere. Nobody verified either.
#
# THIS FILE ANSWERS BOTH, ONE ORGANISATION AT A TIME, WITH THE EVIDENCE CLASS ON
# EVERY ROW. It is session 49's policy 3 applied to a state rather than to a
# queue: general knowledge is admissible for the TYPING question, `basis_type`
# records which kind of answer each one is, and `GENERAL_KNOWLEDGE` keeps
# `determination_confidence = LOW` so a reader can subtract every row that rests
# on nothing citable.
#
# WHAT IS NEW HERE, AND WHY IT IS BETTER THAN THE QUEUE PASS WAS. 306 of session
# 49's 399 answers were `GENERAL_KNOWLEDGE`, because a verifier answering by
# hand has only their own knowledge and the organisation's website. Here the
# bulk of the work is done by THREE FEDERAL ENROLMENT FILES, which are a second
# publisher in the §0.4 sense and are machine-readable:
#
#   * CMS Hospital Enrollments        -- legal ORGANIZATION NAME *and* the DBA,
#                                        with the CCN. This is what identifies
#                                        `Winston County Medical Foundation` and
#                                        `Magee Benevolent Association` as
#                                        hospitals: their own corporate names
#                                        appear in it, against a CCN.
#   * CMS FQHC Enrollments            -- every FQHC site, by operator.
#   * CMS Rural Health Clinic Enrollments
#
# An exact match of the state's published awardee string to an ORGANIZATION NAME
# or DBA in one of those files is `ORG_WEBSITE` -> `MEDIUM`. Where the state's
# spelling and the federal record's differ and the identification is this
# project's own reading -- `Ochsner MS`, `Webster Healthcare Services, Inc.`,
# `Southwest Mississippi Regional Center` -- it is `GENERAL_KNOWLEDGE` -> `LOW`,
# because the bridge is a judgement and not a record. §2 forbids a MACHINE
# resolving a fuzzy hospital match; every one of those bridges is hand-read and
# visible in `UF_TYPES$why`, which is the shape Arkansas's `AR_RELEASE_SPELLINGS`
# already established.
#
# WHAT IS DELIBERATELY NOT ANSWERED. `UF_REFUSALS` holds the organisations whose
# form this session could not determine from any source in hand. They KEEP §8's
# standing fallback and they keep `RECIPIENT_TYPE_INFERRED`, because that flag's
# own note says it means the form is undetermined and on those rows it still is.
# The two queue rows shrink rather than close, and they say so.
#
# §0.3a GOVERNS EVERY LINE OF THIS FILE. The type is read off the RECIPIENT and
# never off the award's description: Mississippi publishes a description of the
# WORK on all 167 rows and South Carolina publishes a project name on all 228,
# and neither is used here. A test requires every `new_type` to be reproducible
# from the awardee string plus the cited source alone.
#
# Conventions (CLAUDE.md §3): tidyverse, %>% only -- never |>. No setwd(); all
# paths through here::here(). Contains no network calls.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_recipient_classification.R"))

UF_CHANGES_CSV <- "data/reference/unstated_form_typing_changes.csv"
UF_DECISIONS_CSV <- "data/reference/unstated_form_typing_decisions.csv"

UF_FILES <- c(MS = "ms_year1_awardees.csv", SC = "sc_year1_awardees.csv")

# The three federal enrolment files, cited per row rather than re-fetched. They
# are a SECOND PUBLISHER and not the state award source, so a match to one of
# them is `ORG_WEBSITE` under session 49's rule -- the state's own award
# document says nothing about any recipient's form, which is why these rows were
# in the queue at all.
UF_SOURCES <- c(
  CMS_HOSP = "https://data.cms.gov/provider-data/dataset/xubh-q36u (Hospital Enrollments, 2026-07-31)",
  CMS_FQHC = "https://data.cms.gov/data-api/v1/dataset/4bcae866-3411-439a-b762-90a6187c194b/data (FQHC Enrollments, 2026-07-17)",
  CMS_RHC  = "https://data.cms.gov/data-api/v1/dataset/3b7e7659-067e-41ea-8e36-f9ee2036e1f6/data (RHC Enrollments, 2026-07-17)",
  IRS_990  = "https://projects.propublica.org/nonprofits/ (IRS Business Master File / Form 990)",
  KNOWN    = "no citable source for the FORM; the answer is this project's own knowledge (§0.4, session 49 policy 3)",
  # Added session 51 for two of the four organisations this file had refused.
  # Both are ARCHIVED under data/evidence/federal_records/2026-09-22/, which is
  # the difference from the four above: those were cited and not committed.
  NPPES_IRS = "https://npiregistry.cms.hhs.gov/ (NPPES NPI Registry) + https://www.irs.gov/pub/irs-soi/eo_sc.csv (IRS EO Business Master File), archived data/evidence/federal_records/2026-09-22/",
  NPPES    = "https://npiregistry.cms.hhs.gov/ (NPPES NPI Registry), archived data/evidence/federal_records/2026-09-22/"
)

# -- the decision table -------------------------------------------------------
#
# ONE ROW PER ORGANISATION, HAND-READ, WITH ITS EVIDENCE IN THE ROW. A pattern
# is deliberately not used: `\bclinic\b` matches an FQHC, an RHC, a physician
# practice, a free clinic and an opioid treatment programme in these two states
# alone, and the whole point of the pass is that those are five different codes.
#
# `determined_form` is what §8's `OTHER` requires and what every other code
# benefits from: the form somebody determined, in words, on the row. A row
# carrying `OTHER` with nothing behind it is the fallback wearing a different
# name, which is the one use that code does not have.
UF_TYPES <- tibble::tribble(
  ~state, ~awardee, ~new_type, ~determined_form, ~basis_type, ~source_key, ~why,
  "MS", "Winston County Medical Foundation",
    "HOSPITAL_OR_SYSTEM",
    "acute care hospital (Winston Medical Center, CCN 250027)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'WINSTON COUNTY MEDICAL FOUNDATION', Louisville MS, against CCN 250027 -- the state's published awardee string IS the hospital's legal name. The IRS Business Master File gives the same body as 'Winston County Medical Foundation Dba Winston Medical Center' and its Form 990 checks 'operated one or more hospital facilities' (Schedule H). Two federal publishers, nothing arranged. This is NOT §10.2's hospital-foundation row -- the foundation IS the hospital, it is not an arm of one -- which is why the queued MS_FOUNDATION_PARENT_NOT_STATED question resolves rather than needing the rule.",
  "MS", "Magee Benevolent Association",
    "HOSPITAL_OR_SYSTEM",
    "acute care hospital (Magee General Hospital, CCN 250124)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'MAGEE BENEVOLENT ASSOCIATION', Magee MS (Simpson County), against CCN 250124. The awardee string is the hospital's own legal name and the award's county matches.",
  "MS", "Merit Health River Region",
    "HOSPITAL_OR_SYSTEM",
    "acute care hospital (CCN 250031)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries DOING BUSINESS AS NAME 'MERIT HEALTH RIVER REGION', Vicksburg MS (Warren County), against CCN 250031; the legal name is Vicksburg Healthcare LLC. Award county matches.",
  "MS", "Independent Healthcare Management Inc",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital operator (CCN 251300, Forest MS)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'INDEPENDENT HEALTHCARE MANAGEMENT INC', Forest MS (Scott County), against CCN 251300, plus an RHC enrolment at the same address. Award county is Scott.",
  "MS", "Independent Healthcare Management, Inc.",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital operator (CCN 251300, Forest MS)",
    "ORG_WEBSITE", "CMS_HOSP",
    "The same body as the row above under Mississippi's second spelling (a comma and a full stop apart). BOTH SPELLINGS ARE KEPT (§2): they are two award actions, not one, and nothing is merged.",
  "MS", "Progressive Health of Houston",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital operator (CCN 250785, Houston MS)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PROGRESSIVE HEALTH OF HOUSTON LLC', Houston MS (Chickasaw County), against CCN 250785, plus three RHC enrolments. Award county is Chickasaw.",
  "MS", "Simpson Community Healthcare, Inc.",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital (CCN 251317, Mendenhall MS)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SIMPSON COMMUNITY HEALTHCARE, INC.', Mendenhall MS, against CCN 251317. Award county is Simpson.",
  "MS", "Webster Healthcare Services, Inc.",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital operator (Webster General Hospital, Eupora MS, CCN 250020)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A HAND-READ BRIDGE AND NOT A RECORD MATCH, SO IT IS LOW. CMS Hospital Enrollments carries 'WEBSTER HEALTH SERVICES INC' dba 'WEBSTER GENERAL HOSPITAL' in Eupora, Webster County, CCN 250020; Mississippi publishes 'Webster HealthCARE Services, Inc.', ONE WORD DIFFERENT. The award's county is Webster and CMS lists no other hospital operator in it, which is what carries the identification -- but the bridge is this project's reading, not either publisher's statement, so §2's ban on a machine resolving a fuzzy hospital match is honoured by making it visible here and pricing it at LOW.",
  "MS", "Ochsner MS",
    "HOSPITAL_OR_SYSTEM",
    "health system operating Mississippi hospitals (Ochsner Rush Medical Center, Meridian, CCN 250069)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A HAND-READ BRIDGE. 'Ochsner MS' is a shorthand no federal record carries. CMS Hospital Enrollments lists OCHSNER RUSH MEDICAL CENTER (Meridian, Lauderdale County, CCN 250069, legal name Rush Medical Foundation) and the award's county is Lauderdale; Ochsner's other Mississippi hospitals (Scott Regional, Stennis) are in other counties. The identification is this project's, so LOW.",
  "MS", "Southwest Mississippi Regional Center",
    "HOSPITAL_OR_SYSTEM",
    "acute care hospital (Southwest Mississippi Regional Medical Center, McComb, CCN 250097)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A HAND-READ BRIDGE WITH A REAL RIVAL, AND THE COUNTY IS WHAT DECIDES IT. Two Mississippi organisations answer to something like this name: Southwest Mississippi Regional MEDICAL CENTER, McComb, PIKE County (CCN 250097), and the Department of Mental Health's Southwest Mississippi Regional CENTER, Brookhaven, LINCOLN County. The award's county is PIKE. The state drops the word MEDICAL, so the bridge is this project's reading and is priced at LOW.",
  "MS", "Aaron E Henry Community Health Services Center, INC",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries this operator against four Mississippi FQHC CCNs (251030 Coldwater, 251134 and 251832 Clarksdale, 251838 Tunica).",
  "MS", "Access Family Health Services, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'ACCESS FAMILY HEALTH SERVICES, INC.' against multiple Mississippi FQHC CCNs (251049, 251074, 251075, 251076).",
  "MS", "Amite County Medical Services, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'AMITE COUNTY MEDICAL SERVICES INC' against CCNs 251032 and 251826.",
  "MS", "Central Mississippi Civic Improvement Association Inc",
    "FQHC_OR_RHC",
    "federally qualified health center (Jackson-Hinds Comprehensive Health Center)",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries this operator against many Mississippi FQHC CCNs, with DBAs reading 'JACKSON HINDS COMPREHENSIVE HEALTH CENTER'.",
  "MS", "Coastal Family Health Center, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'COASTAL FAMILY HEALTH CENTER, INC' against CCNs 251002, 251006, 251053, 251054 and others.",
  "MS", "Delta Health Center",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'DELTA HEALTH CENTER, INC.' against CCNs 251008, 251020, 251022, 251033. Mississippi publishes this awardee both with and without the 'Inc.'; both spellings are kept (§2).",
  "MS", "Delta Health Center, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "The same operator as the row above under Mississippi's second spelling. Both kept (§2).",
  "MS", "East Central Mississippi Health Care, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'EAST CENTRAL MISSISSIPPI HEALTH CARE INC' against CCNs 251031, 251829, 251841, 251851.",
  "MS", "Family Health Center, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'FAMILY HEALTH CENTER, INC' against CCNs 251067 (Waynesboro), 251835 (Laurel), 251899 (Sandersville). Award county is Jones.",
  "MS", "GA Carmichael Family Health Center, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'GA CARMICHAEL FAMILY HEALTH CENTER INC' against CCN 251061.",
  "MS", "Jefferson Comprehensive Health Center, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'JEFFERSON COMPREHENSIVE HEALTH CENTER, INC.' against CCNs 251007, 251041, 251813, 251875.",
  "MS", "Mantachie Rural Health Care Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'MANTACHIE RURAL HEALTH CARE, INC' against CCNs 251043, 251163, 251178, 251852.",
  "MS", "Mantachie Rural Health Center",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "Mississippi's SECOND spelling for the same Itawamba County operator ('Health Center' for 'Health Care Inc.'). No federal record carries this exact string, so the bridge is this project's reading and is priced LOW. NOT MERGED with the row above (§2): two award actions, two rows.",
  "MS", "Outreach Health Services",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'OUTREACH HEALTH SERVICES,INC.' against CCNs 251831 (Shubuta) and 251839 (Heidelberg).",
  "MS", "Southeast Mississippi Rural Health Initiative, Inc",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'SOUTHEAST MISSISSIPPI RURAL HEALTH INITIATIVE, INC.' against many Mississippi FQHC CCNs.",
  "MS", "Fast Pace Mississippi, PLLC",
    "FQHC_OR_RHC",
    "rural health clinic",
    "ORG_WEBSITE", "CMS_RHC",
    "CMS RHC Enrollments carries 'FAST PACE MISSISSIPPI PLLC' against a long series of Mississippi RHC CCNs (A53805 Carthage, A53806 Clarksdale, A53807 Columbia, A53808 Corinth and others).",
  "MS", "Internal Medicine Clinic of Columbia, PA",
    "FQHC_OR_RHC",
    "rural health clinic",
    "ORG_WEBSITE", "CMS_RHC",
    "CMS RHC Enrollments carries 'INTERNAL MEDICINE CLINIC OF COLUMBIA, P.A.' against CCN 258902, Columbia MS (Marion County). Award county matches.",
  "MS", "PSP Medical Clinic",
    "FQHC_OR_RHC",
    "rural health clinic",
    "ORG_WEBSITE", "CMS_RHC",
    "CMS RHC Enrollments carries 'PSP MEDICAL CLINIC LLC' against CCNs 253855 (Yazoo City) and 258999 (Canton). Award county is Madison, which is Canton's county.",
  "MS", "Hattiesburg Clinic, P.A.",
    "PHYSICIAN_PRACTICE",
    "multispecialty physician group (professional association)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A physician-owned multispecialty group practice; the 'P.A.' in the awardee string is Mississippi's professional-association form for a physician practice.",
  "MS", "Lampton Medical Associates, P. A.",
    "PHYSICIAN_PRACTICE",
    "physician practice (professional association)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A physician practice; 'Medical Associates ... P. A.' is the professional-association form.",
  "MS", "Medical Associates of Vicksburg",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A physician group practice in Vicksburg; no federal facility enrolment carries it, which is consistent with an office-based practice.",
  "MS", "Metabolic Medicine of Mississippi",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A single-specialty clinical practice.",
  "MS", "Mission Primary Care Clinic PLLC",
    "PHYSICIAN_PRACTICE",
    "physician practice (PLLC)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A primary-care practice organised as a professional limited liability company.",
  "MS", "P & S Clinic OB-GYN, PLLC",
    "PHYSICIAN_PRACTICE",
    "physician practice (PLLC)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An obstetrics and gynaecology practice organised as a PLLC.",
  "MS", "Endocrine Diabetes & Thyroid Center PLLC",
    "PHYSICIAN_PRACTICE",
    "physician practice (PLLC)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A single-specialty endocrinology practice organised as a PLLC.",
  "MS", "McComb Children’s Clinic",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A paediatric practice.",
  "MS", "The Greenville Clinic, PA",
    "PHYSICIAN_PRACTICE",
    "physician practice (professional association)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A physician practice organised as a professional association.",
  "MS", "Quinn Healthcare, PLLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (PLLC)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A clinician-owned practice organised as a PLLC.",
  "MS", "Medplus Urgent Clinic, LLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (urgent care)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An urgent-care clinic operator.",
  "MS", "Preventive Care MD",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A primary-care practice operating rural sites on the Gulf Coast.",
  "MS", "TrustCare Health, LLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (urgent and primary care)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A Mississippi urgent-care and primary-care clinic operator.",
  "MS", "Sai Sanjeevani Medical Group",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A physician group practice.",
  "MS", "Harmony House Calls LLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (house-call primary care)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A house-call clinical practice.",
  "MS", "NP Care Anywhere, LLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (nurse-practitioner-led)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A nurse-practitioner-led clinical practice. §8 carries PHYSICIAN_PRACTICE for a clinician-owned outpatient practice and has no narrower code; the determined form is stated here rather than in the code.",
  "MS", "Northtown Pharmacy LLC",
    "OTHER",
    "retail pharmacy",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A retail pharmacy -- the same determined form session 49 admitted OTHER for.",
  "MS", "Dental Solutions, PLLC",
    "OTHER",
    "dental practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A dental practice organised as a PLLC.",
  "MS", "Downs Family Dentistry",
    "OTHER",
    "dental practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A dental practice.",
  "MS", "Daniel B. Story II, DMD",
    "OTHER",
    "dental practice (a named dentist)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A dental practice; the awardee string is a dentist's name and post-nominal.",
  "MS", "Gulf Coast Outpatient Surgery Center",
    "OTHER",
    "ambulatory surgery centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An ambulatory surgery centre. An ASC is a Medicare provider type distinct from a hospital and §8 carries no code for it.",
  "MS", "Laurel Surgery & Endoscopy Center",
    "OTHER",
    "ambulatory surgery centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An ambulatory surgery and endoscopy centre.",
  "MS", "Countrywood Manor Assisted Living, Inc.",
    "OTHER",
    "assisted living facility",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An assisted living facility operator.",
  "MS", "Jefferson County Nursing Home",
    "OTHER",
    "nursing home",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A nursing home -- the determined form session 49 admitted OTHER for.",
  "MS", "Lafayette LTC, Inc.",
    "OTHER",
    "long-term care facility",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A long-term care facility; 'LTC' in the awardee string is the form.",
  "MS", "George Regional Health and Rehab",
    "OTHER",
    "skilled nursing and rehabilitation facility",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A skilled nursing and rehabilitation facility. IT IS NOT GEORGE REGIONAL HOSPITAL, which is a separate body and is not an awardee here; typing this row a hospital on the shared 'George Regional' stem is the fuzzy match §2 forbids.",
  "MS", "JWM Therapy Services, LLC",
    "OTHER",
    "outpatient therapy practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient paediatric physical, occupational and speech therapy practice.",
  "MS", "Spann Senses, LLC",
    "OTHER",
    "speech-language pathology practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A speech-language services practice.",
  "MS", "Kinder Mind",
    "OTHER",
    "outpatient behavioural health practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient behavioural health practice.",
  "MS", "Positive Pathways LLC",
    "OTHER",
    "outpatient behavioural health practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient behavioural health practice.",
  "MS", "Resilience Counseling & Recovery Center, LLC",
    "OTHER",
    "counselling and substance-use recovery practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient counselling and substance-use recovery practice.",
  "MS", "USDR Behavioral Specialists",
    "OTHER",
    "applied behaviour analysis practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An applied behaviour analysis and behavioural health practice.",
  "MS", "Region 8 Mental Health",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "One of Mississippi's regional community mental health centres, established as a regional commission of its member counties. §8 carries no code for a CMHC; it is not a hospital, and it is not the awarding agency, so STATE_AGENCY would misdescribe it.",
  "MS", "Region IV Mental Health Services",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "One of Mississippi's regional community mental health centres.",
  "MS", "Singing River Services",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "THE REGION 14 COMMUNITY MENTAL HEALTH CENTRE, NOT SINGING RIVER HEALTH SYSTEM. The hospital system of that name is in Jackson County; this awardee is in George County and is the regional CMHC. The shared stem is exactly the trap §2 exists for.",
  "MS", "North Mississippi Commission on Mental Illness/Mental Retardation d.b.a. Communicare",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A regional community mental health commission trading as Communicare.",
  "MS", "Northeast Mental Health - Mental Retardation Commission d.b.a. LIFECORE Health Group",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A regional community mental health commission trading as LIFECORE Health Group. Mississippi publishes this body under TWO spellings and they are NOT merged (§2).",
  "MS", "Northeast Mental Health d.b.a. LIFECORE Health Group",
    "OTHER",
    "Mississippi regional community mental health centre",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "The same commission under Mississippi's second, shorter spelling. Kept separate (§2).",
  "MS", "AIDS Services Coalition",
    "NONPROFIT_CBO",
    "community-based nonprofit",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A community-based nonprofit providing HIV services and housing. The CODE is the same string §8's fallback uses, but it is now a DETERMINED answer with a basis rather than a statement that the form is unknown, so RECIPIENT_TYPE_INFERRED comes off.",
  "MS", "Mississippi Children's Home Society dba Canopy Children's Solutions",
    "NONPROFIT_CBO",
    "community-based nonprofit (children's behavioural health and welfare)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A statewide children's nonprofit trading as Canopy Children's Solutions. Determined, not inferred.",
  "MS", "Plan A Health, Inc.",
    "NONPROFIT_CBO",
    "nonprofit community clinic operator",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Plan A Health Inc as a 501(c)(3) with NTEE E32 (community clinic). Determined as a nonprofit clinic operator, not a hospital.",
  "SC", "Community Initiatives Inc.",
    "NONPROFIT_CBO",
    "501(c)(3) human-services nonprofit (IRS EIN 31-1741660, NTEE P20), Greenwood SC",
    "ORG_WEBSITE", "NPPES_IRS",
    "SESSION 51, AND IT WAS REFUSED IN SESSION 50. Two federal publishers carry the state's awardee string exactly and put it in ONE city: the IRS Exempt Organizations Business Master File has 'COMMUNITY INITIATIVES INC', Greenwood SC, a 501(c)(3) with NTEE code P20 (human service organisations), and it is the ONLY organisation of that name in the South Carolina file; NPPES has 'COMMUNITY INITIATIVES, INC.', Greenwood SC, NPI 1235502808, taxonomy 'Voluntary or Charitable'. Neither is a CMS provider enrolment and neither is a hospital. The form is therefore DETERMINED, and it is the one §8's fallback happened to name -- so the type does not move, but the row stops asserting the form is unknown. $0 either way. Both SC rows keep the state's own spelling.",
  "SC", "Graceful Health Solutions, LLC",
    "OTHER",
    "for-profit community health clinic operated as a limited liability company (NPPES taxonomy 'Clinic/Center, Community Health'), Spartanburg SC -- NOT an enrolled FQHC or RHC",
    "ORG_WEBSITE", "NPPES",
    "SESSION 51, AND IT WAS REFUSED IN SESSION 50. NPPES carries 'GRACEFUL HEALTH SOLUTIONS LLC', Spartanburg SC, NPI 1841015161, enumerated 2024-11-21, taxonomy 261QC1500X 'Clinic/Center, Community Health' -- the only organisation of that name in South Carolina. It appears in NONE of CMS's FQHC, RHC, hospital, home health, hospice or SNF enrolment files for South Carolina, so FQHC_OR_RHC would assert a federal designation the federal record does not carry. An LLC clinic is not a nonprofit CBO and not a physician practice on any source in hand, so it is §8's OTHER with the determined form stated. Not a hospital: $0 either way.",
  "SC", "AnMed",
    "HOSPITAL_OR_SYSTEM",
    "health system (AnMed Health, CCN 420027)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'ANMED', Anderson SC, against CCN 420027.",
  "SC", "Edgefield County Healthcare",
    "HOSPITAL_OR_SYSTEM",
    "critical access hospital (CCN 421304)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries 'EDGEFIELD COUNTY HEALTHCARE AN AFFILIATE OF SELF REGIONAL HEALTHCARE', Edgefield SC, against CCN 421304.",
  "SC", "Lexington Health",
    "HOSPITAL_OR_SYSTEM",
    "health system (Lexington Medical Center, CCN 420073)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'LEXINGTON HEALTH INC', West Columbia SC, against CCN 420073, plus RHC enrolments.",
  "SC", "McLeod Health",
    "HOSPITAL_OR_SYSTEM",
    "health system (McLeod Health, CCNs 420107, 420109 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries McLeod Health hospitals (Cheraw 420107, Clarendon 420109, Dillon 420005) under that name.",
  "SC", "McLeod Health on behalf of McLeod Health Dillon (MHD)",
    "HOSPITAL_OR_SYSTEM",
    "acute care hospital (McLeod Medical Center-Dillon, CCN 420005)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries 'MCLEOD MEDICAL CENTER - DILLON' against CCN 420005. South Carolina's awardee string names the system and the hospital; both are hospitals.",
  "SC", "Tidelands Health",
    "HOSPITAL_OR_SYSTEM",
    "health system (Tidelands Health)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments and RHC Enrollments both carry Tidelands Health facilities in Georgetown and Horry counties.",
  "SC", "Rebound Behavioral Health",
    "HOSPITAL_OR_SYSTEM",
    "psychiatric hospital (CCN 424014)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries 'REBOUND BEHAVIORAL HEALTH LLC', Lancaster SC, against CCN 424014, SUBGROUP - PSYCHIATRIC = Y. A Medicare-certified psychiatric hospital is a hospital.",
  "SC", "The Carolina Center for Behavioral Health",
    "HOSPITAL_OR_SYSTEM",
    "psychiatric hospital (CCN 424010)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries DBA 'CAROLINA CENTER FOR BEHAVIORAL HEALTH', Greer SC, against CCN 424010, SUBGROUP - PSYCHIATRIC = Y; the legal name is UHS of Greenville, LLC.",
  "SC", "Acadia Healthcare Co.",
    "HOSPITAL_OR_SYSTEM",
    "behavioural health system operating psychiatric hospitals",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "THE LARGEST SINGLE JUDGEMENT IN THIS PASS AND IT IS QUEUED AS WELL AS TYPED. Acadia Healthcare Company is a hospital operator: its South Carolina estate includes Lighthouse Behavioral Health Hospital, Conway (CCN 424002, legal name HHC South Carolina Inc, SUBGROUP - PSYCHIATRIC = Y). But the awardee is the CORPORATE PARENT, whose South Carolina estate ALSO includes two outpatient comprehensive treatment centres that are not hospitals, and no source says how the award divides. §0.3a codes the RECIPIENT and the recipient is a hospital company, so it is typed HOSPITAL_OR_SYSTEM at LOW and queued as SC_ACADIA_PARENT_SCOPE so a reader can subtract it.",
  "SC", "Beaufort Jasper Hampton Comprehensive Health Services, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries this operator against many South Carolina FQHC CCNs (421012, 421013, 421014, 421016 and others).",
  "SC", "Care Net of Lancaster",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'CARE-NET OF LANCASTER' against CCNs 421951 (Kershaw) and 421967 (Lancaster).",
  "SC", "Careteam Plus, Inc",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'CARETEAM PLUS INC' against CCNs 421057, 421095, 421113.",
  "SC", "Carolina Health Centers, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'CAROLINA HEALTH CENTERS INC' against CCNs 421042, 421094, 421105, 421107 and others.",
  "SC", "Carolina Health Centers, Inc. (CHC)",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "The same operator as the row above under South Carolina's second spelling (the acronym appended). Both kept (§2).",
  "SC", "Cherokee Community Care",
    "FQHC_OR_RHC",
    "rural health clinic",
    "ORG_WEBSITE", "CMS_RHC",
    "CMS RHC Enrollments carries 'CHEROKEE COMMUNITY CARE, LLC' against CCN 428948, Gaffney SC.",
  "SC", "Fairfield Medical Associates",
    "FQHC_OR_RHC",
    "rural health clinic",
    "ORG_WEBSITE", "CMS_RHC",
    "CMS RHC Enrollments carries 'FAIRFIELD MEDICAL ASSOCIATES, PA.' against CCN 423840, Winnsboro SC.",
  "SC", "Family Health Centers, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'FAMILY HEALTH CENTERS, INC.' against CCNs 421007, 421026, 421804, 421805 and others.",
  "SC", "Fetter Health Care Network",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'FETTER HEALTH CARE NETWORK INC' against CCNs 421044, 421051, 421053, 421087 and others.",
  "SC", "Foothills Community Health Care",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'FOOTHILLS COMMUNITY HEALTH CARE' against CCNs 421048, 421075, 421975.",
  "SC", "Health Care Partners of South Carolina, Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries this operator against CCNs 421038, 421069, 421088, 421092 and others.",
  "SC", "HopeHealth Inc.",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'HOPEHEALTH, INC.' against CCNs 421000, 421001, 421008, 421028 and others.",
  "SC", "Low Country Health Care System",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'LOW COUNTRY HEALTH CARE SYSTEM INC' against CCNs 421040, 421043, 421054, 421056 and others.",
  "SC", "Low Country Health Care System (LCHCS)",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "The same operator under South Carolina's second spelling. Both kept (§2).",
  "SC", "ReGenesis Health Care",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'REGENESIS HEALTH CARE INC' against CCNs 421099 and 421878.",
  "SC", "St. James Health and Wellness",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'ST JAMES HEALTH AND WELLNESS INC' against CCNs 421010, 421022, 421082, 421838.",
  "SC", "Tandem Health SC",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "CMS FQHC Enrollments carries 'TANDEM HEALTH SC' against CCNs 421009, 421058, 421102, 421106.",
  "SC", "Tandem Health SC (THSC)",
    "FQHC_OR_RHC",
    "federally qualified health center",
    "ORG_WEBSITE", "CMS_FQHC",
    "The same operator under South Carolina's second spelling. Both kept (§2).",
  "SC", "Barnwell County",
    "LOCAL_GOVT_OR_PUBLIC_HEALTH",
    "county government",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A county government. The awardee string is a county and nothing else.",
  "SC", "Aiken Endocrinology",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A single-specialty endocrinology practice.",
  "SC", "Bamberg Family Practice",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A family medicine practice.",
  "SC", "Ehrhardt Medical Practice, LLC",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A medical practice; the awardee string states the form.",
  "SC", "Infinity Family Healthcare",
    "PHYSICIAN_PRACTICE",
    "clinician practice (primary care)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A primary-care practice.",
  "SC", "Midlands Neurology and Pain Associates",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A single-specialty neurology and pain practice.",
  "SC", "Morphis Pediatric Group",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A paediatric group practice.",
  "SC", "New Beginnings Family Healthcare, LLC",
    "PHYSICIAN_PRACTICE",
    "clinician practice (primary care)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A primary-care practice.",
  "SC", "Pinner Clinic",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A clinic practice.",
  "SC", "Smith Medical Clinic, LLC",
    "PHYSICIAN_PRACTICE",
    "physician practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A medical clinic practice.",
  "SC", "The Center for Women's Health",
    "PHYSICIAN_PRACTICE",
    "physician practice (obstetrics and gynaecology)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An obstetrics and gynaecology practice.",
  "SC", "Alpha Behavioral Health Center",
    "OTHER",
    "outpatient behavioural health practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient behavioural health practice.",
  "SC", "At Your Place Healthcare, LLC",
    "OTHER",
    "in-home care provider",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An in-home care provider.",
  "SC", "Bishopville Dental, LLC",
    "OTHER",
    "dental practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A dental practice.",
  "SC", "Due West Pharmacy and Wellness, LLC",
    "OTHER",
    "retail pharmacy",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A retail pharmacy -- session 49's precedent for OTHER.",
  "SC", "Iva Drug Store, Inc.",
    "OTHER",
    "retail pharmacy",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A retail pharmacy.",
  "SC", "Pugh Drug Inc.",
    "OTHER",
    "retail pharmacy",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A retail pharmacy.",
  "SC", "Hand of Hope Children's Therapy Center, LLC",
    "OTHER",
    "outpatient paediatric therapy practice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient paediatric therapy practice.",
  "SC", "Healistic Woundcare Management Group",
    "OTHER",
    "mobile wound-care services provider",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A wound-care services provider.",
  "SC", "Hospice & Palliative Care of Piedmont",
    "OTHER",
    "hospice",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A hospice -- session 49 typed a hospice's foundation OTHER on the same reasoning, and a hospice is not a hospital.",
  "SC", "Oh the Blood Mobile Phlebotomy, LLC",
    "OTHER",
    "mobile phlebotomy company",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A mobile phlebotomy company.",
  "SC", "Pee Dee Regional Transportation Authority",
    "OTHER",
    "regional public transportation authority",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A regional public transportation authority. Session 49 typed a non-emergency medical transport company OTHER; this is the public form of the same thing.",
  "SC", "Ridgeland Comprehensive Treatment Center",
    "OTHER",
    "opioid treatment programme (outpatient)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient comprehensive treatment centre -- an opioid treatment programme, not a hospital.",
  "SC", "South Carolina Comprehensive Treatment Center (CTC), LLC",
    "OTHER",
    "opioid treatment programme (outpatient)",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "An outpatient comprehensive treatment centre.",
  "SC", "Healthy Smiles of Spartanburg, Inc.",
    "OTHER",
    "nonprofit dental clinic",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Healthy Smiles Of Spartanburg Inc as a 501(c)(3) with NTEE E32 (community clinic); it is a dental clinic.",
  "SC", "Able South Carolina",
    "NONPROFIT_CBO",
    "community-based nonprofit (centre for independent living)",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Able South Carolina, Columbia SC, as a 501(c)(3). A centre for independent living, not a provider.",
  "SC", "Bluffton Jasper County Volunteers in Medicine",
    "NONPROFIT_CBO",
    "charitable free clinic",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A volunteer-staffed charitable free clinic.",
  "SC", "Community Medical Clinic of Kershaw County",
    "NONPROFIT_CBO",
    "charitable free clinic",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A charitable free clinic. NOT KERSHAW MEDICAL CENTER, the MUSC hospital in the same county -- a different body with a similar county stem (§2).",
  "SC", "Edisto Indian Free Clinic",
    "NONPROFIT_CBO",
    "charitable free clinic",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Edisto Indian Free Clinic, Ridgeville SC, as a 501(c)(3) with NTEE E32 (community clinic).",
  "SC", "Foothills Area YMCA",
    "NONPROFIT_CBO",
    "community-based nonprofit",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A YMCA association.",
  "SC", "Good Samaritan Clinic",
    "NONPROFIT_CBO",
    "charitable free clinic",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A charitable free clinic.",
  "SC", "Joseph H. Neal Health Collaborative",
    "NONPROFIT_CBO",
    "community-based health nonprofit",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Joseph H Neal Health Collaborative, Cayce SC, as a 501(c)(3). Its NTEE code reads E24; the organisation is a community health nonprofit and NOT a hospital, and an NTEE code alone is not read as a hospital determination here.",
  "SC", "Palmetto Care Connections",
    "NONPROFIT_CBO",
    "telehealth nonprofit",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A South Carolina telehealth nonprofit.",
  "SC", "Servants for Sight",
    "NONPROFIT_CBO",
    "charitable vision-care nonprofit",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries Servants For Sight, Greenville SC, as a 501(c)(3) with NTEE G41.",
  "SC", "The Free Medical Clinic",
    "NONPROFIT_CBO",
    "charitable free clinic",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "A charitable free clinic.",
  "SC", "The Palmetto Palace",
    "NONPROFIT_CBO",
    "community-based health nonprofit (mobile health unit)",
    "ORG_WEBSITE", "IRS_990",
    "The IRS Business Master File carries The Palmetto Palace, Johns Island SC, as a 501(c)(3) with NTEE E99.",
  "SC", "Prisma Health (Oconee)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health- Upstate (Anderson)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Midlands (Orangeburg, Aiken, Oconee)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Bishopville)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Laurens)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Oconee)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Oconee, Laurens)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Oconee, Lee, and Laurens)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "Prisma Health-Upstate (Winnsboro)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Prisma Health, CCNs 420009, 420015, 420018, 420033 and others)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'PRISMA HEALTH-UPSTATE', 'PRISMA HEALTH-MIDLANDS' and 'PRISMA HEALTH OCONEE MEMORIAL HOSPITAL' against South Carolina CCNs. South Carolina spells this system TEN different ways across its award list and NONE is merged (§2) -- session 47 measured the three that differ by a single space run.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Aiken Barnwell Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Aiken-Barnwell Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Anderson-Oconee-Pickens Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Berkeley Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Catawba Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Charleston Dorchester Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Coastal Empire Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Columbia Area Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Greater Greenville Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Lexington County Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Orangeburg Area Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Pee Dee Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Santee Wateree Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Spartanburg Area Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Tri-County Community Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health & Envoy Portfolio (Waccamaw Center for Mental Health)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health (Beckman Center for Mental Health Services)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health (Beckman Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "SCDBHDD Office of Mental Health (Spartanburg Area Mental Health Center)",
    "STATE_AGENCY",
    "a South Carolina state agency (Department of Behavioral Health and Developmental Disabilities) and its state-operated community mental health centres",
    "GENERAL_KNOWLEDGE", "KNOWN",
    "SCDBHDD is the South Carolina Department of Behavioral Health and Developmental Disabilities -- a STATE AGENCY -- and the centre named in the parenthesis is one of its own state-operated community mental health centres, not an independent grantee. Session 47 deliberately left these nineteen rows on §8's fallback because §8's NAME rule does not reach an acronym; typing them directly is what this pass is for, and it moves $0 because they were already distributed_to_hospital = No.",
  "SC", "Self Regional Healthcare (Abbeville)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Imaging Center, Greenwood)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Lakelands Region)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Laurens)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Montgomery Center, Greenwood)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Newberry)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Optimum Life Rehabilitation Center, Greenwood)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2).",
  "SC", "Self Regional Healthcare (Saluda)",
    "HOSPITAL_OR_SYSTEM",
    "health system (Self Regional Healthcare, CCN 420071)",
    "ORG_WEBSITE", "CMS_HOSP",
    "CMS Hospital Enrollments carries ORGANIZATION NAME 'SELF REGIONAL HEALTHCARE', Greenwood SC, against CCN 420071, plus four RHC enrolments. South Carolina spells it EIGHT ways, each with a different site in parentheses; none is merged (§2)."
)

# THE ORGANISATIONS THIS PASS COULD NOT DETERMINE, AND THEY KEEP §8's STANDING
# FALLBACK AND ITS FLAG. `RECIPIENT_TYPE_INFERRED`'s own note says it means the
# form is UNDETERMINED, and on these it still is. Session 51 settled the two
# South Carolina ones from archived federal records; the two left are both
# Mississippi, and UF_FORM_NOT_DETERMINABLE shrinks to cover exactly them.
UF_REFUSALS <- tibble::tribble(
  ~state, ~awardee, ~why_not,
  "MS", "CAMHP Foundation",
    "no reachable source names this organisation's form. The IRS Business Master File's only 'Camhp Foundation' is an Ohio body with an unrelated NTEE code, and nothing ties it to the Franklin County award. Session 51 re-searched the six CMS enrolment files, NPPES and the Mississippi EO BMF (archived, data/evidence/federal_records/2026-09-22/) and found nothing. Typing it on the word 'Foundation' alone would be §10.2's hospital-foundation row applied with no parent -- the exact refusal session 49 recorded for Winston County before a source was found for that one.",
  "MS", "Delta Health Transformation Council, Inc.",
    "THE LARGEST SINGLE REFUSAL IN THIS PASS AT $3,000,000, AND SESSION 51 RE-SEARCHED IT AND STILL REFUSES IT. No record carries it in any of SIX CMS enrolment files for Mississippi (hospital, FQHC, RHC, home health, hospice, SNF), in NPPES, or in the IRS EO Business Master File -- all archived under data/evidence/federal_records/2026-09-22/, which is what makes this a measured negative rather than a remembered one. The only Delta Health bodies those files do carry are Delta Health System (CCN 250082, the Greenville hospital) and Delta Health Center, Inc. (the FQHC), the two a stem match would have to choose between; typing it as either would be a determination by resemblance (§2). The award's own words ('robotic-assisted surgery ... [Washington County]') point at the Greenville hospital, and that is exactly why they are not used: a description describes the ACTIVITY and §0.3a judges the RECIPIENT. It keeps §8's fallback."
)


# -- reading the two committed files ------------------------------------------

#' Read a committed state table WITHOUT losing its own spelling of "empty"
#'
#' `na = character()` BECAUSE MISSISSIPPI AND SOUTH CAROLINA WRITE THE LITERAL
#' STRING "NA". readr treats that string as a missing value on READ whatever
#' `col_types` says, so a plain read-then-write silently rewrites every "NA"
#' cell as an empty one -- 167 and 228 rows of cosmetic churn in six columns
#' this pass never planned to touch, which is the diff sessions 23-25 kept
#' catching. Reading it as text keeps the file's own convention, and
#' `UF_EMPTY` is what the overlay writes when it needs to clear a cell.
UF_EMPTY <- "NA"

uf_read <- function(file) {
  suppressMessages(readr::read_csv(here::here("data/reference", file),
                                   col_types = readr::cols(.default = "c"),
                                   na = character(), trim_ws = FALSE,
                                   progress = FALSE))
}

#' The rows this pass is entitled to touch
#'
#' EXACTLY the rows carrying §8's standing fallback flag. A row whose form some
#' earlier session determined is not re-opened here, and a test drives that.
uf_open_rows <- function(d) {
  which(!is.na(d$flag_reason) & d$flag_reason != UF_EMPTY &
          stringr::str_detect(d$flag_reason, "RECIPIENT_TYPE_INFERRED"))
}


#' THE PRE-OVERLAY TABLES, BUILT FROM THE ARCHIVES -- NOT THE COMMITTED CSVs
#'
#' THE PLAN MUST BE COMPUTED FROM THE BUILDER'S OUTPUT AND NOT FROM THE
#' COMMITTED FILE, AND THE REASON IS THE WHOLE POINT OF THE OVERLAY. Once
#' `--apply` has run, the committed CSV no longer carries the fallback flag on
#' the rows this pass typed, so a plan derived from it would find nothing open
#' and quietly produce an EMPTY plan -- which reads exactly like "there was
#' never anything to do". Reading the builder instead makes the claim the
#' overlay rests on checkable in both directions: the committed CSV is the
#' builder's output WITH this overlay applied, and both halves are on disk.
#'
#' It costs one parse of Mississippi's roster and South Carolina's award-list
#' PDF (about six seconds together) and it needs `data/evidence/MS` and
#' `data/evidence/SC`, so the tests that use it skip without the archive.
uf_built <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages(sys.source(here::here("R", "03ak_ms_year1_awardees.R"), e))
  suppressMessages(sys.source(here::here("R", "03ao_sc_year1_awardees.R"), e))
  list(MS = e$ms_year1_awardees(), SC = e$sc_year1_awardees())
}


#' Confidence an answer supports (session 49's rule, unchanged)
#'
#' §7 reserves HIGH for a CCN match and nothing here has one ON THE AWARD ROW --
#' the CCNs cited below identify the ORGANISATION in a federal enrolment file,
#' which is not the same as matching this award's recipient to a provider
#' record in the AHA/POS extracts (blocker 5). So a federal-record answer is
#' MEDIUM and a general-knowledge answer is LOW, and a reader can subtract.
uf_confidence <- function(basis_type) {
  dplyr::if_else(basis_type == "GENERAL_KNOWLEDGE", "LOW", "MEDIUM")
}


#' Build the row-level plan. WRITES NOTHING.
uf_plan <- function(types = UF_TYPES, built = uf_built()) {
  purrr::map_dfr(names(UF_FILES), function(st) {
    file <- UF_FILES[[st]]
    d <- built[[st]]
    open <- uf_open_rows(d)
    tt <- types %>% dplyr::filter(state == st)

    purrr::map_dfr(seq_len(nrow(tt)), function(i) {
      a <- tt[i, ]
      idx <- open[d$awardee[open] == a$awardee]
      if (!length(idx)) {
        stop("UF_TYPES names a recipient no open ", st, " row carries: ",
             a$awardee, call. = FALSE)
      }
      purrr::map_dfr(idx, function(r) {
        old_type <- d$recipient_type[r]
        old_flow <- d$flow_type[r]
        old_dth  <- d$distributed_to_hospital[r]
        old_attr <- d$hospital_attribution[r]

        # SESSION 49'S RULE, UNCHANGED: §10.2's DIRECT row is the one branch
        # keyed on recipient IDENTITY, so the flow test is re-run exactly where
        # a row crosses the HOSPITAL_OR_SYSTEM boundary and left alone
        # everywhere else. Re-running it elsewhere could only overwrite a state
        # extractor's reading of its own source with the same answer or a worse
        # one.
        crosses <- xor(identical(old_type, "HOSPITAL_OR_SYSTEM"),
                       identical(a$new_type, "HOSPITAL_OR_SYSTEM"))
        new_flow <- old_flow; new_dth <- old_dth; new_attr <- old_attr
        flow_note <- "flow unchanged: the re-type does not cross §10.2's DIRECT test"
        if (crosses) {
          fl <- rhtp_classify_flow(a$new_type, "", award_made = FALSE)
          new_flow <- fl$flow_type
          new_dth  <- fl$distributed_to_hospital
          new_attr <- rhtp_hospital_attribution(new_flow, new_dth,
                                                a$new_type, NA_character_)
          flow_note <- "flow re-run: §10.2 re-applied because the re-type crosses the DIRECT test"
        }

        tibble::tibble(
          file = file, row = r, state = st, awardee = a$awardee,
          amount = suppressWarnings(as.numeric(d$amount[r])),
          old_type = old_type, new_type = a$new_type,
          old_conf = d$determination_confidence[r],
          new_conf = uf_confidence(a$basis_type),
          basis_type = a$basis_type,
          determined_form = a$determined_form,
          source = unname(UF_SOURCES[[a$source_key]]),
          why = a$why,
          old_flow = old_flow, new_flow = new_flow,
          old_dth = old_dth, new_dth = new_dth,
          old_attr = old_attr, new_attr = new_attr,
          flow_note = flow_note
        )
      })
    })
  }) %>%
    dplyr::mutate(
      type_changed = old_type != new_type,
      bucket_before = old_attr,
      bucket_after  = new_attr
    ) %>%
    dplyr::arrange(state, row)
}


#' What the plan leaves behind
uf_residual <- function(refusals = UF_REFUSALS, built = uf_built()) {
  purrr::map_dfr(seq_len(nrow(refusals)), function(i) {
    a <- refusals[i, ]
    d <- built[[a$state]]
    open <- uf_open_rows(d)
    idx <- open[d$awardee[open] == a$awardee]
    if (!length(idx)) {
      stop("UF_REFUSALS names a recipient no open row carries: ", a$awardee,
           call. = FALSE)
    }
    tibble::tibble(state = a$state, awardee = a$awardee, rows = length(idx),
                   dollars = sum(suppressWarnings(as.numeric(d$amount[idx]))),
                   why_not = a$why_not)
  })
}


#' Every open row is either typed or refused -- nothing falls between
uf_assert_complete <- function(plan = NULL, residual = NULL,
                               built = uf_built()) {
  if (is.null(plan)) plan <- uf_plan(built = built)
  if (is.null(residual)) residual <- uf_residual(built = built)
  for (st in names(UF_FILES)) {
    d <- built[[st]]
    open <- uf_open_rows(d)
    covered <- c(plan$row[plan$state == st],
                 unlist(lapply(residual$awardee[residual$state == st],
                               function(n) open[d$awardee[open] == n])))
    missing <- setdiff(open, covered)
    if (length(missing)) {
      stop(st, ": ", length(missing), " open row(s) are neither typed nor ",
           "refused -- ", paste(unique(d$awardee[missing]), collapse = "; "),
           ". A row that is silently left out is the failure this assertion ",
           "exists to prevent (§0.4).", call. = FALSE)
    }
  }
  invisible(TRUE)
}


# -- writing it back ----------------------------------------------------------

#' Apply the typing overlay to ONE state table
#'
#' Session 49's device, for the same reason: every state extractor rebuilds its
#' CSV from its archived source, so a determination written straight onto the
#' CSV is wiped by the next `--build` and nothing says so. The overlay is a
#' committed file derived from a committed decision table, applied after the
#' build, and it is IDEMPOTENT.
uf_overlay <- function(built, file, plan = uf_changes()) {
  pf <- plan %>% dplyr::filter(.data$file == !!file)
  if (!nrow(pf)) return(built)
  d <- built
  has <- function(x) x %in% names(d)
  if (!"basis_type" %in% names(d)) d$basis_type <- UF_EMPTY
  if (!"verified_by" %in% names(d)) d$verified_by <- UF_EMPTY
  if (!"verified_basis" %in% names(d)) d$verified_basis <- UF_EMPTY

  for (i in seq_len(nrow(pf))) {
    r <- as.integer(pf$row[i])
    d$recipient_type[r] <- pf$new_type[i]
    d$determination_confidence[r] <- pf$new_conf[i]
    d$basis_type[r] <- pf$basis_type[i]
    d$verified_by[r] <- "session 50 unstated-form typing"
    d$verified_basis[r] <- paste0(pf$determined_form[i], ". ", pf$why[i],
                                  " Source: ", pf$source[i])

    if (has("flow_type") && !is.na(pf$new_flow[i])) d$flow_type[r] <- pf$new_flow[i]
    if (has("distributed_to_hospital") && !is.na(pf$new_dth[i]))
      d$distributed_to_hospital[r] <- pf$new_dth[i]
    if (has("hospital_benefiting") && identical(pf$new_dth[i], "Yes"))
      d$hospital_benefiting[r] <- "Yes"
    if (has("hospital_attribution") && !is.na(pf$new_attr[i]))
      d$hospital_attribution[r] <- pf$new_attr[i]

    # §8's standing fallback flag is a claim that the form is UNDETERMINED. It
    # is now determined, so the flag comes off -- its own note in
    # vocabularies.csv forbids leaving it on a recipient whose form is stated.
    if (has("flag_reason") && !is.na(d$flag_reason[r])) {
      fr <- paste(setdiff(stringr::str_split(d$flag_reason[r], ";")[[1]],
                          "RECIPIENT_TYPE_INFERRED"), collapse = ";")
      d$flag_reason[r] <- if (nzchar(fr)) fr else UF_EMPTY
    }
    if (has("determination_basis")) {
      prior <- d$determination_basis[r]
      if (!is.na(prior) &&
          startsWith(prior, "RECIPIENT TYPE DETERMINED (session 50)")) next
      d$determination_basis[r] <- paste0(
        "RECIPIENT TYPE DETERMINED (session 50): ", pf$new_type[i],
        " -- ", pf$determined_form[i], ". Basis (", pf$basis_type[i], "): ",
        pf$why[i], " Source: ", pf$source[i], ". ", pf$flow_note[i], ".",
        if (!is.na(prior) && nzchar(prior))
          paste0(" PRIOR BASIS, kept because §2.1 says a correction shows what ",
                 "moved: ", prior) else "")
    }
  }
  d
}

uf_changes <- function() {
  suppressMessages(readr::read_csv(here::here(UF_CHANGES_CSV),
                                   col_types = readr::cols(.default = "c"),
                                   progress = FALSE))
}

#' Rebuild both states and write the builder's output WITH the overlay on it
#'
#' Writing the build rather than patching the committed file is what makes the
#' invariant true by construction rather than by luck: whatever is committed is
#' exactly what `--build` produces plus this overlay, and a later session can
#' check that by running both halves.
uf_apply <- function(built = uf_built()) {
  plan <- uf_plan(built = built)
  uf_assert_complete(plan, built = built)
  readr::write_csv(plan, here::here(UF_CHANGES_CSV), na = "")
  readr::write_csv(
    plan %>% dplyr::distinct(state, awardee, new_type, determined_form,
                             basis_type, source, why),
    here::here(UF_DECISIONS_CSV), na = "")
  pl <- plan %>% dplyr::mutate(row = as.character(row))
  for (st in names(UF_FILES)) {
    f <- UF_FILES[[st]]
    # NOT coerced to character. `as.character()` on a double renders 3000000
    # as "3e+06", which would rewrite the amount column on 28 rows this pass
    # never touches -- the same class of silent churn as the "NA" question
    # above. readr::write_csv formats the numeric column exactly as the
    # builder's own --build does.
    d <- built[[st]]
    readr::write_csv(uf_overlay(d, f, pl),
                     here::here("data/reference", f), na = UF_EMPTY)
  }
  unname(UF_FILES)
}


# -- South Carolina against the agency benchmark ------------------------------

#' Re-run session 47's §8 comparison now that the 150 rows are typed
#'
#' The benchmark, from the SC Medicaid agency, is **~240 awards, ~$170M, about
#' half of awards to hospitals, about 60% of dollars to hospitals**. Session 47
#' could only place it between a floor (24.1% of awards, 33.8% of dollars) and a
#' ceiling (89.9% / 89.3%) and said so. With the 150 rows typed the comparison
#' is a POINT against a POINT, and the two halves do not behave the same way.
#'
#' NOTHING IS ADJUSTED TOWARD THE BENCHMARK AND NO ROW WAS TYPED TO REACH IT.
#' The benchmark is not committed to any data file; it lives here and in the
#' session document, exactly as session 47 left it. What follows is a
#' consistency check on the typing, in the direction the typing was done first.
SC_BENCHMARK <- list(awards_pct = 50, dollars_pct = 60,
                     awards = 240, dollars = 170e6)

uf_sc_benchmark <- function() {
  d <- uf_read("sc_year1_awardees.csv")
  amt <- suppressWarnings(as.numeric(d$amount))
  hosp <- d$hospital_attribution == "NAMED_HOSPITAL"
  acadia <- d$awardee == "Acadia Healthcare Co."
  tibble::tibble(
    measure = c("% of awards", "% of dollars"),
    floor_session47 = c(55 / nrow(d) * 100, 56587137.77 / sum(amt) * 100),
    typed_now = c(sum(hosp) / nrow(d) * 100, sum(amt[hosp]) / sum(amt) * 100),
    typed_less_acadia = c(sum(hosp & !acadia) / nrow(d) * 100,
                          sum(amt[hosp & !acadia]) / sum(amt) * 100),
    benchmark = c(SC_BENCHMARK$awards_pct, SC_BENCHMARK$dollars_pct),
    ceiling_session47 = c(205 / nrow(d) * 100, 149346929.00 / sum(amt) * 100)
  )
}


# -- the report ---------------------------------------------------------------

uf_fmt <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")

uf_report <- function(built = uf_built()) {
  plan <- uf_plan(built = built)
  res <- uf_residual(built = built)
  uf_assert_complete(plan, res, built = built)
  moved_in <- plan %>% dplyr::filter(bucket_before == "NOT_HOSPITAL",
                                     bucket_after  != "NOT_HOSPITAL")
  moved_out <- plan %>% dplyr::filter(bucket_before != "NOT_HOSPITAL",
                                      bucket_after  == "NOT_HOSPITAL")

  cat("\n======= THE UNSTATED-FORM QUESTION, TYPED (MS + SC) =======\n")
  cat("organisations typed : ", nrow(UF_TYPES), "\n", sep = "")
  cat("award rows in plan  : ", nrow(plan), "  (recipient_type changed on ",
      sum(plan$type_changed), ")\n", sep = "")

  cat("\n-- INTO a hospital bucket --------------------------------------\n")
  cat("rows: ", nrow(moved_in), "   dollars: ",
      uf_fmt(sum(moved_in$amount, na.rm = TRUE)), "\n", sep = "")
  print(as.data.frame(moved_in %>% dplyr::group_by(state) %>%
    dplyr::summarise(rows = dplyr::n(), dollars = sum(amount, na.rm = TRUE),
                     .groups = "drop")), row.names = FALSE)

  cat("\n-- OUT of a hospital bucket ------------------------------------\n")
  cat("rows: ", nrow(moved_out), "   dollars: ",
      uf_fmt(sum(moved_out$amount, na.rm = TRUE)),
      "  (one-directional by construction: every open row was `No`)\n", sep = "")

  cat("\n-- BY basis_type (what a reader can subtract) ------------------\n")
  print(as.data.frame(moved_in %>% dplyr::group_by(basis_type) %>%
    dplyr::summarise(rows = dplyr::n(), dollars = sum(amount, na.rm = TRUE),
                     .groups = "drop")), row.names = FALSE)

  cat("\n-- new types assigned ------------------------------------------\n")
  print(as.data.frame(plan %>% dplyr::count(state, new_type)), row.names = FALSE)

  cat("\n-- NOT DETERMINED: stays on §8's fallback ----------------------\n")
  print(as.data.frame(res %>% dplyr::select(state, awardee, rows, dollars)),
        row.names = FALSE)

  cat("\n-- SOUTH CAROLINA AGAINST THE AGENCY BENCHMARK -----------------\n")
  print(as.data.frame(uf_sc_benchmark()), row.names = FALSE)
  invisible(plan)
}


if (identical(environment(), globalenv()) &&
    !is.null(args <- commandArgs(trailingOnly = TRUE)) && length(args)) {
  if ("--report" %in% args) uf_report()
  if ("--apply"  %in% args) cat("applied to: ",
                               paste(uf_apply(), collapse = ", "), "\n")
  if ("--benchmark" %in% args) print(as.data.frame(uf_sc_benchmark()),
                                     row.names = FALSE)
}

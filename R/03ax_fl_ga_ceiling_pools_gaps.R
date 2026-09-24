# R/03ax_fl_ga_ceiling_pools_gaps.R
#
# THE TWO COMPLETE STATES, TIGHTENED (session 57). A REPORT, EXCEPT FOR
# `--apply` (session 58), which re-codes exactly five Florida rows. Three
# questions, one output each:
#
#   1. FLORIDA'S CEILING. Five rows ($6,331,219.97) sat between the
#      named-hospital floor ($49,345,213.46, 26.2%) and the ceiling (29.6%)
#      because they carried distributed_to_hospital = Unclear. Each is checked
#      against the archived CMS enrolment files, NPPES and the IRS EO BMF --
#      Winston County Medical Foundation's route (session 50, CCN 250027).
#      Session 57 wrote the result as a PROPOSAL. SESSION 58 APPLIED ALL THREE
#      ON THE OWNER'S INSTRUCTION (`--apply`), Nuvita Health on the owner's own
#      identification (Nuvita Cellular Health) at GENERAL_KNOWLEDGE / LOW.
#      Florida's ceiling now equals its floor. SESSION 59 re-typed Nuvita
#      VENDOR_OR_CONTRACTOR -> OTHER on the owner's instruction: a company
#      receiving a grant is not a supplier to the state (session 49's `OTHER`).
#      distributed_to_hospital stays No, so no figure moves.
#   2. GEORGIA'S POOLS. Two pools name hospitals with no per-hospital split.
#      This records what was searched, that no split exists, and the
#      non-hospital member each pool contains. Nothing is apportioned (§6.2).
#   3. THE ALLOTMENT GAPS. Florida's and Georgia's awards against their FY2026
#      award, decomposed into the lines each state's own budget documents give,
#      with anything left over reported as UNEXPLAINED.
#
# §0.2: every gap figure subtracts a Tier 3 total from a Tier 1 figure and then
# lays PLAN (Tier 2) lines against the difference. The plan lines explain the
# gap's composition; they are never added to an award total.
#
# Usage:
#   Rscript R/03ax_fl_ga_ceiling_pools_gaps.R --apply    # overlays the 3 FL codings
#   Rscript R/03ax_fl_ga_ceiling_pools_gaps.R --build    # writes the 3 CSVs
#   Rscript R/03ax_fl_ga_ceiling_pools_gaps.R --report   # prints them
#
# `--apply` IS AN OVERLAY ON fl_year1_awardees.csv, keyed on row_no and
# idempotent. It must run AFTER session 49's (`R/03ap ... vq_overlay`), which
# sets these same five rows' recipient_type: rebuild order is R/03e --ingest,
# then the 03ap overlay for Florida, then this --apply.

suppressPackageStartupMessages({
  library(dplyr)
})
source(here::here("R", "utils_config.R"))
source(here::here("R", "utils_pdf_text.R"))

AX_FED <- here::here("data", "evidence", "federal_records", "2026-09-23")
AX_RC  <- here::here("data", "evidence", "recheck", "2026-09-23")
AX_OUT_FL   <- here::here("data", "reference", "fl_ceiling_resolution.csv")
AX_OUT_GA   <- here::here("data", "reference", "ga_mixed_pool_split_search.csv")
AX_OUT_GAPS <- here::here("data", "reference", "fl_ga_allotment_gap_components.csv")

AX_FL_LIST <- "data/evidence/recheck/2026-08-29/FL/FL_year1_awardees_governor_list.pdf"
AX_FL_BUDGET <- "data/evidence/recheck/2026-09-23/FL/fl_ahca_revised_budget_narrative_2026-02-10.pdf"
AX_GA_NOA <- "data/evidence/recheck/2026-09-23/GA/ga_cms_noa_revision_budget_2026-02-10.pdf"


# -- readers --------------------------------------------------------------------

ax_cms <- function(kind, st = "FL") {
  f <- file.path(AX_FED, sprintf("cms_%s_enrollments_%s.json", kind, st))
  x <- jsonlite::fromJSON(f)
  tibble::tibble(kind = kind, ccn = x$CCN, npi = x$NPI,
                 org = toupper(x$`ORGANIZATION NAME`),
                 dba = toupper(x$`DOING BUSINESS AS NAME`),
                 city = toupper(x$CITY))
}

ax_cms_all <- function(st = "FL") {
  purrr::map_dfr(c("hosp", "fqhc", "rhc", "snf", "hha", "hospice"), ax_cms, st = st)
}

ax_nppes <- function(f) {
  x <- jsonlite::fromJSON(file.path(AX_FED, f), simplifyVector = FALSE)
  purrr::map_dfr(if (is.null(x$results)) list() else x$results, function(r) {
    loc <- purrr::keep(r$addresses, ~ .x$address_purpose == "LOCATION")[[1]]
    tibble::tibble(npi = r$number, org = r$basic$organization_name,
                   city = loc$city, state = loc$state,
                   taxonomies = paste(purrr::map_chr(r$taxonomies, "desc"),
                                      collapse = "; "))
  })
}

ax_irs <- function() {
  readr::read_csv(file.path(AX_FED, "irs_eo_bmf_FL_extract.csv"),
                  col_types = readr::cols(.default = "c"))
}

ax_fl <- function() {
  readr::read_csv(here::here("data", "reference", "fl_year1_awardees.csv"),
                  show_col_types = FALSE)
}

ax_ga <- function() {
  readr::read_csv(here::here("data", "reference", "ga_great_health_awards.csv"),
                  show_col_types = FALSE)
}

ax_money <- function(x) as.numeric(gsub("[$,[:space:]]", "", x))


# -- 1. Florida -----------------------------------------------------------------

#' What the Governor's list says about each row: name, amount, region. It says
#' nothing about any recipient's organisational form, which is the whole
#' reason the five rows are Unclear.
ax_fl_list_rows <- function() {
  ln <- rhtp_pdf_lines(here::here(AX_FL_LIST))
  body <- ln[grepl("^\\d{1,2}\\D.*\\$[0-9,]+\\.\\d\\d\\s*$", ln$text), ]
  body$row_no <- as.integer(sub("^(\\d{1,2}).*", "\\1", body$text))
  body$amount_in_source <- ax_money(sub(".*(\\$[0-9,]+\\.\\d\\d)\\s*$", "\\1", body$text))
  body <- body[order(body$row_no), ]
  if (nrow(body) != 81L || anyDuplicated(body$row_no))
    stop("[AX] the Governor's list no longer parses to 81 numbered rows")
  # The region is NOT read off the page layout: its labels are painted beside
  # blocks, not above them, and a nearest-label rule misfiles rows. It is read
  # off the RELEASE, which states each region's awardee count in list order --
  # and the per-region totals the release also states are the check.
  counts <- c("Northeast Region" = 14L, "Southeast Region" = 11L,
              "Southwest Region" = 21L, "Northwest Region" = 35L)
  body$region <- rep(names(counts), counts)
  stated <- c("Northeast Region" = 51, "Southeast Region" = 12,
              "Southwest Region" = 45, "Northwest Region" = 81)
  got <- tapply(body$amount_in_source, body$region, sum)[names(stated)] / 1e6
  if (any(abs(got - stated) > 0.6))
    stop("[AX] region blocks no longer reproduce the release's regional totals")
  body[, c("row_no", "amount_in_source", "region")]
}

# The five rows, by the Governor's own row number, and what they carried
# BEFORE session 58 applied the codings (session 49's overlay; the owner's
# workbook had UNCLASSIFIED / Unclear on all five).
AX_FL_ROWS <- tibble::tribble(
  ~row_no, ~awardee, ~prior_recipient_type, ~prior_distributed_to_hospital,
  9L,  "Nuvita Health",                   "VENDOR_OR_CONTRACTOR", "Unclear",
  16L, "Empowerq Health Care",            "PHYSICIAN_PRACTICE",   "Unclear",
  18L, "Nuvita Health",                   "VENDOR_OR_CONTRACTOR", "Unclear",
  33L, "Nuvita Health",                   "VENDOR_OR_CONTRACTOR", "Unclear",
  71L, "North Florida Rural Health Corp", "NONPROFIT_CBO",        "Unclear")

# One entry per ORGANISATION. `stem` is what the CMS/NPPES/IRS searches
# looked for; evidence_class says whether a federal record carries the state's
# own string (EXACT), a hand-read bridge to one (BRIDGE), or nothing
# (NEGATIVE). `decided_by` says who settled the coding that was APPLIED.
AX_FL_ORGS <- tibble::tribble(
  ~awardee, ~stem, ~evidence_class, ~applied_recipient_type, ~applied_basis_type, ~applied_confidence, ~decided_by, ~determination,
  "North Florida Rural Health Corp", "NORTH FLORIDA RURAL HEALTH",
  "EXACT_FEDERAL_RECORD", "NONPROFIT_CBO", "ORG_WEBSITE", "MEDIUM",
  "Federal record (IRS EO BMF); applied on owner instruction, session 58",
  "The state's own string is the IRS EO BMF NAME exactly: EIN 85-2728333, 680 Maple St, Chattahoochee FL, subsection 03 (501(c)(3)), NTEE E30 (ambulatory and primary health care). NPPES carries it twice under the same name and city (1912641341, clinic taxonomies incl. a self-reported FQHC code; 1720849540, pharmacy). It is in NO CMS enrolment file -- not an enrolled FQHC or RHC, and not a hospital. The only CMS-enrolled hospital in Chattahoochee is Florida State Hospital (Florida Department of Children and Families, CCNs 104000/100298), a different body. A 501(c)(3) community clinic: not a hospital.",
  "Empowerq Health Care", "EMPOWERQ",
  "BRIDGE_FEDERAL_RECORD", "NONPROFIT_CBO", "GENERAL_KNOWLEDGE", "LOW",
  "Hand-read bridge to a federal record; applied on owner instruction, session 58",
  "No federal record carries 'Empowerq' (NPPES 0 results, IRS 0 rows, all six CMS files 0). The verifier's own cited site (empowerhealthcare4all.org) is Empower Healthcare, Inc., a primary-care clinic serving Palm Beach County, which IRS carries as EMPOWER HEALTHCARE, EIN 85-2591676, Pahokee FL, 501(c)(3), NTEE E32 (community clinics), and NPPES as EMPOWER HEALTHCARE, INC 1770170367, Pahokee, taxonomies incl. 'Clinic/Center, Rural Health'. The Governor's list places row 16 in the SOUTHEAST region, which is where Pahokee is. That identification is a HAND-READ BRIDGE (one letter of the state's spelling), hence LOW on the MATCH. The hospital answer does not depend on it: no CMS-enrolled Florida hospital's name or DBA contains EMPOWER, so it is not a hospital either way.",
  "Nuvita Health", "NUVITA",
  "NEGATIVE_ONLY", "OTHER", "GENERAL_KNOWLEDGE", "LOW",
  "OWNER-CONFIRMED identification (Nuvita Cellular Health), session 58; typed OTHER on owner instruction, session 59",
  "OWNER-CONFIRMED (session 58): 'Nuvita Health' is Nuvita Cellular Health, a cellular preventive medicine and biomarker testing platform -- not a hospital. DETERMINED FORM (session 59): a private health-technology company RECEIVING A GRANT, so §8 OTHER on session 49's footing -- not VENDOR_OR_CONTRACTOR, which says the recipient supplies the state, and nothing in the Governor's list says Nuvita sells anything to AHCA. That identification is the owner's own knowledge with no citable source for the form, hence GENERAL_KNOWLEDGE / LOW. It agrees with the federal records, which carry NO positive record: 'Nuvita Health' is in none of the six CMS enrolment files, not in the IRS EO BMF, and not in NPPES; NPPES's only Florida 'Nuvita' organisations are a chiropractor (Tampa) and a multi-specialty clinic enumerated 2025-07-09 (Jacksonville), neither named Nuvita Health and neither a hospital, and no Medicare-enrolled Florida hospital carries the name."
)

ax_fl_federal_checks <- function(orgs = AX_FL_ORGS) {
  cms <- ax_cms_all("FL")
  irs <- ax_irs()
  np  <- dplyr::bind_rows(
    ax_nppes("nppes_nuvita_FL.json"), ax_nppes("nppes_empowerq_FL.json"),
    ax_nppes("nppes_empower_health_FL.json"),
    ax_nppes("nppes_north_florida_rural_health_FL.json"))
  purrr::pmap_dfr(orgs, function(awardee, stem, ...) {
    hit <- function(x) grepl(stem, toupper(x), fixed = TRUE)
    tibble::tibble(
      awardee = awardee,
      cms_hospital_hits = sum(hit(cms$org[cms$kind == "hosp"]) |
                                hit(cms$dba[cms$kind == "hosp"])),
      cms_any_file_hits = sum(hit(cms$org) | hit(cms$dba)),
      irs_hits = paste(irs$EIN[hit(irs$NAME)], collapse = ";"),
      nppes_hits = paste(np$npi[hit(np$org)], collapse = ";"))
  })
}

ax_fl_resolution <- function() {
  fl <- ax_fl()
  lst <- ax_fl_list_rows()
  u <- fl %>% dplyr::filter(row_no %in% AX_FL_ROWS$row_no)
  stopifnot(nrow(u) == 5L, abs(sum(u$amount) - 6331219.97) < 0.01,
            identical(u$awardee[order(u$row_no)], AX_FL_ROWS$awardee))
  chk <- ax_fl_federal_checks()
  out <- u %>%
    dplyr::select(row_no, awardee, amount,
                  committed_recipient_type = recipient_type,
                  committed_distributed_to_hospital = distributed_to_hospital,
                  committed_confidence = determination_confidence,
                  committed_basis_type = basis_type) %>%
    dplyr::left_join(AX_FL_ROWS, by = c("row_no", "awardee")) %>%
    dplyr::left_join(lst, by = "row_no") %>%
    dplyr::left_join(AX_FL_ORGS %>% dplyr::select(-stem), by = "awardee") %>%
    dplyr::left_join(chk, by = "awardee") %>%
    dplyr::mutate(
      source_says = paste0("Governor's Year 1 list, row ", row_no, ": '",
                           awardee, "' ", format(amount_in_source, big.mark = ",",
                                                  nsmall = 2), ", ", region,
                           ". Name, amount and region only -- no form, no project text."),
      why_ambiguous = paste0("Florida publishes no organisation form; the owner's workbook ",
                             "coded it UNCLASSIFIED/Unclear and session 49 re-typed it (",
                             prior_recipient_type, ") without settling the hospital column."),
      applied_distributed_to_hospital = "No",
      resolves = dplyr::case_when(
        evidence_class == "EXACT_FEDERAL_RECORD" ~ "YES",
        evidence_class == "BRIDGE_FEDERAL_RECORD" ~ "YES_ON_A_BRIDGE",
        TRUE ~ "NO_POSITIVE_RECORD"),
      status = ifelse(committed_recipient_type == applied_recipient_type &
                        committed_distributed_to_hospital == applied_distributed_to_hospital &
                        committed_confidence %in% applied_confidence &
                        committed_basis_type %in% applied_basis_type,
                      "APPLIED", "PENDING")) %>%
    dplyr::select(row_no, awardee, amount, amount_in_source, region,
                  prior_recipient_type, prior_distributed_to_hospital,
                  source_says, why_ambiguous, cms_hospital_hits, cms_any_file_hits,
                  irs_hits, nppes_hits, evidence_class, resolves,
                  applied_recipient_type, applied_distributed_to_hospital,
                  applied_basis_type, applied_confidence, decided_by, status,
                  determination)
  ax_assert_fl(out)
  out
}

#' Session 58's overlay: write the three codings onto the five rows. Keyed on
#' row_no, checked against the awardee name, idempotent. recipient_type_source
#' (the owner's original UNCLASSIFIED) is deliberately not touched -- see
#' vq_overlay() in R/03ap for why.
ax_fl_overlay <- function(d, res = NULL) {
  if (is.null(res)) res <- ax_fl_resolution()
  for (i in seq_len(nrow(res))) {
    r <- which(as.integer(d$row_no) == res$row_no[i])
    if (length(r) != 1L || d$awardee[r] != res$awardee[i])
      stop("[AX] Florida row ", res$row_no[i], " is not ", res$awardee[i])
    if (!d$distributed_to_hospital[r] %in% c("Unclear", "No"))
      stop("[AX] Florida row ", res$row_no[i], " is ", d$distributed_to_hospital[r],
           " -- this overlay only settles Unclear rows")
    d$recipient_type[r] <- res$applied_recipient_type[i]
    d$distributed_to_hospital[r] <- res$applied_distributed_to_hospital[i]
    d$determination_confidence[r] <- res$applied_confidence[i]
    d$basis_type[r] <- res$applied_basis_type[i]
    d$verified_by[r] <- res$decided_by[i]
    d$verified_basis[r] <- res$determination[i]
  }
  d
}

ax_fl_apply <- function() {
  f <- here::here("data", "reference", "fl_year1_awardees.csv")
  # read as character with "" kept as "", which round-trips the committed file
  # byte for byte (no NA literals, no 3e+06).
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"), na = character())
  res <- ax_fl_resolution()
  d2 <- ax_fl_overlay(d, res)
  readr::write_csv(d2, f, na = "")
  message("[AX] applied ", nrow(res), " Florida codings to ", f)
  invisible(d2)
}

ax_assert_fl <- function(out) {
  if (any(abs(out$amount - out$amount_in_source) > 0.01))
    stop("[AX] a Florida Unclear amount no longer matches the Governor's list")
  if (any(out$cms_hospital_hits != 0))
    stop("[AX] an Unclear Florida recipient now matches a CMS hospital -- re-read it")
  if (any(out$applied_basis_type == "GENERAL_KNOWLEDGE" & out$applied_confidence != "LOW"))
    stop("[AX] a GENERAL_KNOWLEDGE coding must be LOW (§0.4)")
  if (!all(grepl("OWNER-CONFIRMED", out$determination[out$awardee == "Nuvita Health"])))
    stop("[AX] Nuvita Health's basis must say it is owner-confirmed")
  nfrhc <- out[out$awardee == "North Florida Rural Health Corp", ]
  if (nfrhc$irs_hits[1] != "852728333")
    stop("[AX] North Florida Rural Health Corp is no longer the IRS record it was settled on")
  if (any(out$irs_hits[out$awardee == "Nuvita Health"] != "") ||
      any(out$cms_any_file_hits[out$awardee == "Nuvita Health"] != 0))
    stop("[AX] Nuvita Health now has a federal record -- its NEGATIVE_ONLY class is stale")
  if (any(out$region[out$awardee == "Empowerq Health Care"] != "Southeast Region"))
    stop("[AX] the Empowerq bridge rests on row 16 being in the Southeast region")
  invisible(TRUE)
}

#' Florida's floor and ceiling, before and under each reading, and as the
#' committed file now stands. The floor cannot move: nothing resolved TO a
#' hospital.
ax_fl_bounds <- function(res = ax_fl_resolution()) {
  fl <- ax_fl()
  denom <- sum(fl$amount)
  floor <- sum(fl$amount[fl$distributed_to_hospital == "Yes"])
  un <- function(keep) sum(res$amount[res$resolves %in% keep])
  tibble::tribble(
    ~reading, ~unclear_left_usd,
    "BEFORE (session 56)", sum(res$amount),
    "Remove EXACT federal records only", un(c("YES_ON_A_BRIDGE", "NO_POSITIVE_RECORD")),
    "Also remove the hand-read bridge", un("NO_POSITIVE_RECORD"),
    "Also remove the measured negative", 0,
    "AS COMMITTED (fl_year1_awardees.csv)", sum(fl$amount[fl$distributed_to_hospital == "Unclear"])
  ) %>%
    dplyr::mutate(floor_usd = floor, ceiling_usd = floor + unclear_left_usd,
                  floor_pct = round(100 * floor / denom, 1),
                  ceiling_pct = round(100 * ceiling_usd / denom, 1),
                  published_denominator = denom)
}


# -- 2. Georgia -----------------------------------------------------------------

AX_GA_SEARCHED <- paste(
  "data/evidence/GA/2026-07-16_great_health_phase2_awards.html;",
  "data/evidence/GA/2026-08-27_great_health_phase4_awards.html;",
  "data/evidence/GA/2026-07-23_great_health_phase3_awards.html;",
  "data/evidence/GA/2026-08-28_value_based_care_hospital_list.html;",
  "data/evidence/GA/ga_noa_point_of_care_telepods_signed.pdf;",
  "data/evidence/GA/ga_noa_workforce_retention_technology_signed.pdf;",
  "data/evidence/recheck/2026-08-29/GA/ (funding page, home, news, 2 NITAs, 2 NOAs);",
  "data/evidence/recheck/2026-09-23/GA/ (live 2026-09-23: funding page, news, value-based care, all five application initiative pages, CMS's own NOA x2, SORH RHS participants)")

ax_ga_pools <- function() {
  ga <- ax_ga()
  p <- ga %>%
    dplyr::group_by(phase, initiative) %>%
    dplyr::filter(any(distributed_to_hospital == "Yes" & is.na(amount))) %>%
    dplyr::summarise(
      pool_usd = dplyr::first(initiative_amount),
      priced_usd = sum(amount, na.rm = TRUE),
      named_hospitals = sum(distributed_to_hospital == "Yes"),
      non_hospital_members = paste(awardee[distributed_to_hospital != "Yes"],
                                   collapse = "; "),
      .groups = "drop")
  stopifnot(nrow(p) == 2L, sum(p$pool_usd) == 22135000, all(p$priced_usd == 0))
  # The ceiling session 56 reports counts both pools WHOLE. Recomputed here
  # from the committed award file so this table and year1_complete_hospital_
  # share.csv cannot drift apart silently (a test holds them equal).
  denom <- sum(dplyr::distinct(ga, phase, initiative, initiative_amount)$initiative_amount)
  named <- sum(ga$amount[ga$distributed_to_hospital == "Yes"], na.rm = TRUE)
  ceil_pct <- round(100 * (named + sum(p$pool_usd - p$priced_usd)) / denom, 1)
  p %>% dplyr::mutate(
    ga_share_ceiling_pct = ceil_pct,
    ga_true_share_vs_ceiling = "STRICTLY_BELOW",
    ga_true_share_bound = sprintf(paste0(
      "Georgia's true hospital share is STRICTLY BELOW %.1f%%. That ceiling counts ",
      "both mixed pools whole ($22,135,000), and each pool contains one known ",
      "NON-hospital recipient that DCH says it funded -- DBHDD's award for a mobile ",
      "dental clinic (Phase 2) and the assessments of all 87 hospitals (Phase 4) -- ",
      "whose amount is unpublished but positive. So the ceiling is never attained. ",
      "How far below it is NOT KNOWN and no figure is imputed (§6.2)."), ceil_pct),
    dch_words = dplyr::case_when(
      phase == 2 ~ "'Connecting to Care ... (Initiative 3) - $6.5 million ... These awards include 17 Rural Stabilization Grant awards to rural hospitals across Georgia and a separate award to DBHDD.' ... 'The award to DBHDD will support deployment of a mobile dental clinic.'",
      phase == 4 ~ "'Transforming for a Sustainable Health System ... (Initiative 1) - $15,635,000: Awards in this initiative provide seven additional rural hospitals with pre-implementation funding ... Additionally, DCH funded personalized assessments of all 87 hospitals to evaluate readiness'"),
    non_hospital_member_named = dplyr::case_when(
      phase == 2 ~ "Georgia Department of Behavioral Health and Developmental Disabilities (DBHDD) -- a STATE AGENCY",
      phase == 4 ~ "the provider of the 87 AHEAD readiness assessments -- NOT NAMED anywhere reachable"),
    non_hospital_member_amount = "NOT PUBLISHED",
    per_hospital_split_published = "No",
    sources_searched = AX_GA_SEARCHED,
    why_no_dollar_tightening = dplyr::case_when(
      phase == 2 ~ "DCH names the non-hospital member but not its amount, so the ceiling cannot be lowered by any published figure. The application's Rural Stabilization Grants line ($9,540,817, Budget Period 1) is a PLAN and is larger than the pool; SORH's Rural Hospital Stabilization participant list is the STATE programme (Phases 1-7) and is not this split.",
      phase == 4 ~ "Phase 3 priced its 80 AHEAD hospitals at $750,000 each; DCH never restates a per-hospital figure for Phase 4's seven, so 7 x $750,000 = $5,250,000 (and a $10,385,000 assessment remainder) is ARITHMETIC NOBODY PUBLISHED and is refused (§6.2)."))
}


# -- 3. Allotment gaps ----------------------------------------------------------

ax_fl_budget_lines <- function() {
  t <- paste(rhtp_pdf_text(here::here(AX_FL_BUDGET)), collapse = "\n")
  grab <- function(re) {
    m <- regmatches(t, regexpr(re, t, perl = TRUE))
    if (!length(m)) stop("[AX] Florida budget narrative: pattern not found: ", re)
    ax_money(stringr::str_extract(m, "(?<=\\$)\\s*[0-9][0-9,]*(\\.[0-9]+)?"))
  }
  inits <- regmatches(t, gregexpr("F\\.\\d+\\. Initiative \\d+:[^\\n]*\\nAnnual Total:\\s*\\$\\s*[0-9,]+", t, perl = TRUE))[[1]]
  stopifnot(length(inits) == 15L)
  list(
    year1_total   = grab("\\$209,938,194\\.50 Year 1 budget"),
    state_direct  = grab("State PMO Direct \\(A\\+B\\+C\\+E\\): \\$[0-9,.]+"),
    state_indirect = grab("State Indirect \\(J\\): \\$[0-9,.]+"),
    admin_contract_attested = grab("Admin Contractor \\(F\\.16 Admin-A\\+ F\\.16 Admin-B\\): \\$[0-9,.]+"),
    admin_a = grab("Admin-A: State PMO Contracts\\nAnnual Total: \\$[0-9,.]+"),
    admin_b = grab("Admin-B: Administrative Costs by Super Region\\nAnnual Total:\\s*\\$[0-9,.]+"),
    total_admin_attested = grab("Total Annual Admin: \\$[0-9,.]+"),
    initiatives = sum(ax_money(sub(".*\\$", "", inits))))
}

# CMS's revised NOA for Georgia (Revision (Budget), 02/10/2026) is IMAGE-ONLY:
# it has no text layer, so section 33 cannot be parsed and is transcribed here
# from the rendered page. The transcription is held to two independent checks:
# the lines must sum to the NOA's own Total Approved Budget, and that total
# must be the figure DCH prints in its own CMS footer.
AX_GA_NOA_BUDGET <- tibble::tribble(
  ~line, ~usd,
  "a. Salaries and Wages", 1465461.00,
  "b. Fringe Benefits", 990857.00,
  "d. Equipment", 0,
  "e. Supplies", 102940.00,
  "f. Travel", 46215.80,
  "g. Construction", 0,
  "h. Other", 0,
  "i. Contractual", 216256695.83,
  "k. Indirect Costs", 0)
AX_GA_NOA_TOTAL <- 218862169.63

ax_assert_ga_noa <- function() {
  if (abs(sum(AX_GA_NOA_BUDGET$usd) - AX_GA_NOA_TOTAL) > 0.005)
    stop("[AX] Georgia NOA transcription does not sum to its own total")
  ph2 <- paste(readLines(here::here("data/evidence/GA/2026-07-16_great_health_phase2_awards.html"),
                         warn = FALSE), collapse = " ")
  if (!grepl("$218,862,169.63", ph2, fixed = TRUE))
    stop("[AX] DCH's footer no longer carries the NOA total")
  b <- readBin(here::here(AX_GA_NOA), "raw", file.size(here::here(AX_GA_NOA)))
  if (length(grepRaw("/Subtype/Image", b, all = TRUE)) != 3L)
    stop("[AX] the Georgia NOA is no longer the 3-page image-only file transcribed")
  invisible(TRUE)
}

ax_gaps <- function() {
  fl <- ax_fl(); ga <- ax_ga()
  fl_awarded <- sum(fl$amount)
  ga_awarded <- sum(dplyr::distinct(ga, phase, initiative, initiative_amount)$initiative_amount)
  b <- ax_fl_budget_lines()
  stopifnot(abs(b$state_direct + b$state_indirect + b$admin_contract_attested -
                  b$total_admin_attested) < 0.01,
            abs(b$initiatives + b$total_admin_attested - b$year1_total) < 0.01)
  ax_assert_ga_noa()
  n <- function(l) AX_GA_NOA_BUDGET$usd[AX_GA_NOA_BUDGET$line == l]
  FLB <- AX_FL_BUDGET; GAN <- AX_GA_NOA
  fl_gap <- b$year1_total - fl_awarded
  ga_gap <- AX_GA_NOA_TOTAL - ga_awarded
  rows <- tibble::tribble(
    ~state, ~component, ~usd, ~basis, ~source, ~note,
    "FL", "GAP: FY2026 award minus the 81 published awards", fl_gap, "ARITHMETIC", FLB, "Year 1 budget $209,938,194.50 (the narrative's own total, = CMS's award to the dollar) minus $188,201,256.11.",
    "FL", "State PMO direct (A Personnel + B Fringe + C Travel + E Supplies)", b$state_direct, "PLAN", FLB, "AHCA's own staff costs; never a subaward.",
    "FL", "State indirect (J, per NICRA)", b$state_indirect, "PLAN", FLB, "",
    "FL", "Admin contracts (F.16 Admin-A + Admin-B), AS ATTESTED", b$admin_contract_attested, "PLAN", FLB, paste0("The line items are Admin-A $", format(b$admin_a, big.mark = ","), " (State PMO contracts incl. a Grant Management System) + Admin-B $", format(b$admin_b, big.mark = ","), " (3% to each super-region's awardees) = $", format(b$admin_a + b$admin_b, big.mark = ","), ", which is $", format(b$admin_a + b$admin_b - b$admin_contract_attested, big.mark = ","), " MORE than the attestation -- exactly the indirect line. The narrative is internally inconsistent by that amount; the attested figure is the one that closes to its own $209,938,194.50 total. The release's 'procurements earlier this year to ... monitor program outcomes, track expenditures and deliverables, and provide support to subawardees' is the award-side statement of Admin-A; it publishes no recipient or amount."),
    "FL", "UNEXPLAINED REMAINDER", fl_gap - b$total_admin_attested, "UNEXPLAINED", FLB, paste0("= the plan's 15 initiatives ($", format(b$initiatives, big.mark = ","), ") minus the published awards. No source says whether this is unawarded, rescaled, or sits inside Admin-B (the narrative says Admin-B is paid 'upon award' to each applicant, and the published awards may or may not include it). Reported, not closed."),
    "GA", "GAP: FY2026 award minus the 12 published award pools", ga_gap, "ARITHMETIC", GAN, "CMS NOA total $218,862,169.63 minus $197,148,327 (distinct phase x initiative pools).",
    "GA", "State personnel (a Salaries + b Fringe)", n("a. Salaries and Wages") + n("b. Fringe Benefits"), "NOA_APPROVED_BUDGET", GAN, "DCH/SORH/GBHCW staff; the application's governance page names 14 DCH hires plus SORH and GBHCW positions.",
    "GA", "State supplies (e)", n("e. Supplies"), "NOA_APPROVED_BUDGET", GAN, "",
    "GA", "State travel (f)", n("f. Travel"), "NOA_APPROVED_BUDGET", GAN, "",
    "GA", "Indirect (k)", n("k. Indirect Costs"), "NOA_APPROVED_BUDGET", GAN, "Georgia claims no indirect cost.",
    "GA", "UNEXPLAINED REMAINDER: contractual budget in no published pool", n("i. Contractual") - ga_awarded, "UNEXPLAINED", GAN, "Contractual $216,256,695.83 minus the $197,148,327 of published pools. DCH says 'less than 10% of Year 1's funding is dedicated to administrative costs' (Phase 4 release) and names RSM as its 'grants management vendor' (funding page), and the application's Initiative 5 page puts one assessment 'through administrative contract' -- but no source publishes an amount or a recipient list for any of it. Consistent with administration; its composition is not sourced."
  )
  stopifnot(abs(sum(rows$usd[rows$state == "FL" & rows$basis != "ARITHMETIC"]) - fl_gap) < 0.01,
            abs(sum(rows$usd[rows$state == "GA" & rows$basis != "ARITHMETIC"]) - ga_gap) < 0.01)
  rows %>% dplyr::mutate(usd = round(usd, 2))
}


if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--apply" %in% args) ax_fl_apply()
  fl <- ax_fl_resolution(); ga <- ax_ga_pools(); gaps <- ax_gaps()
  if ("--build" %in% args) {
    readr::write_csv(fl, AX_OUT_FL, na = "")
    readr::write_csv(ga, AX_OUT_GA, na = "")
    readr::write_csv(gaps, AX_OUT_GAPS, na = "")
    message("[AX] wrote ", AX_OUT_FL, ", ", AX_OUT_GA, ", ", AX_OUT_GAPS)
  }
  if ("--report" %in% args || !length(args)) {
    options(width = 200)
    print(as.data.frame(fl[, c("row_no", "awardee", "amount", "region",
                               "cms_hospital_hits", "irs_hits", "nppes_hits",
                               "evidence_class", "resolves", "status")]))
    print(as.data.frame(ax_fl_bounds(fl)))
    print(as.data.frame(ga[, c("phase", "pool_usd", "named_hospitals",
                               "non_hospital_member_named", "per_hospital_split_published")]))
    print(as.data.frame(gaps[, c("state", "component", "usd", "basis")]))
  }
}

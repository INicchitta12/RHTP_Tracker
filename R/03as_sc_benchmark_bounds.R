#!/usr/bin/env Rscript
# 03as_sc_benchmark_bounds.R ---------------------------------------------------
#
# SOUTH CAROLINA AGAINST THE AGENCY BENCHMARK: EACH EXPLANATION, COMPUTED.
# A REPORT. IT CHANGES NO CLASSIFICATION AND WRITES NO STATE FILE.
#
# The benchmark is SC Medicaid's own statement as recorded in session 47 (it is
# in no committed data file): about 240 awards, about $170M, about half of
# awards to hospitals, about 60% of dollars to hospitals. Session 50's typing
# lands the COUNT half almost exactly (113 / 228 = 49.6%) and OVERSHOOTS the
# DOLLAR half (69.2%). Session 50 named three readings and adopted none. This
# file TESTS each against the committed rows instead of reasoning about it:
#
#   1. RURAL-ONLY COUNTING. Restrict the numerator to rows a SOURCE designates
#      rural (data/reference/rural_cut_rows.csv, session 51's rule: the state's
#      document, or CMS enrolment as CAH/REH by the row's cited CCN). And state
#      the coverage gap -- the share of hospital dollars whose rural status no
#      source records either way.
#   2. PSYCHIATRIC AND BEHAVIOURAL HOSPITALS EXCLUDED. Identified by the CCN
#      each row cites in the ARCHIVED CMS enrolment file (a 4xxx psychiatric
#      CCN), never by name.
#   3. MULTI-SITE SYSTEMS. Prisma Health and Self Regional Healthcare are 19
#      and 20 rows here. Collapsing them to organisations must move COUNTS and
#      not DOLLARS -- asserted, not assumed. The one variant that can move
#      dollars is treating a system's named non-hospital SITE as a non-hospital
#      award, which this file already does for exactly one Self Regional row.
#
# NONE IS ADOPTED. The point is to BOUND the explanation. A test fails if any
# SC classification moves as a side effect.
#
# Usage:
#   Rscript R/03as_sc_benchmark_bounds.R --build    # writes the bounds CSV
#   Rscript R/03as_sc_benchmark_bounds.R --report

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(stringr); library(tibble)
  library(jsonlite); library(here)
})

SC_FILE      <- here::here("data", "reference", "sc_year1_awardees.csv")
SC_RURAL_CUT <- here::here("data", "reference", "rural_cut_rows.csv")
SC_CMS_HOSP  <- here::here("data", "evidence", "federal_records", "2026-09-22",
                           "cms_hosp_enrollments_SC.json")
SC_BOUNDS_CSV <- here::here("data", "reference", "sc_benchmark_bounds.csv")

SC_BENCHMARK <- list(awards = 240, dollars = 170e6,
                     award_share = 0.50, dollar_share = 0.60)

# Self Regional rows whose own awardee string names a NON-HOSPITAL SITE. The
# file codes ONE such row (Greenwood Pediatrics) as a physician practice and
# three that read the same way as the hospital system -- an inconsistency in
# this repository, recorded here and NOT corrected (this task changes no
# classification). The strings are matched exactly.
SC_SELF_SITE_ROWS <- c(
  "Self Regional Healthcare (Imaging Center, Greenwood)",
  "Self Regional Healthcare (Montgomery Center, Greenwood)",
  "Self Regional Healthcare (Optimum Life Rehabilitation Center, Greenwood)")

sc_rows <- function() {
  d <- readr::read_csv(SC_FILE, col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  d$amount <- as.numeric(d$amount)
  d$row_index <- seq_len(nrow(d))
  d$ccn <- NULL   # empty in the state file; the cited CCN is the rural cut's
  rc <- readr::read_csv(SC_RURAL_CUT, col_types = readr::cols(.default = "c"),
                        progress = FALSE) %>%
    dplyr::filter(.data$state == "SC") %>%
    dplyr::transmute(row_index = as.integer(.data$row_index),
                     rural_class = .data$rural_class,
                     counts_as_rural = .data$counts_as_rural == "TRUE",
                     ccn = .data$ccn)
  enr <- jsonlite::fromJSON(SC_CMS_HOSP)
  enr <- enr[!duplicated(enr$CCN), c("CCN", "PROVIDER TYPE TEXT",
                                     "SUBGROUP - PSYCHIATRIC")]
  names(enr) <- c("ccn", "cms_provider_type", "cms_psych_subgroup")
  d %>%
    dplyr::left_join(rc, by = "row_index") %>%
    dplyr::left_join(enr, by = "ccn") %>%
    dplyr::mutate(
      hospital = .data$distributed_to_hospital == "Yes",
      # A psychiatric hospital CCN is 4000-4499 in the state's 42 prefix.
      psych = .data$hospital & !is.na(.data$ccn) &
        grepl("^424[0-4][0-9]{2}$", .data$ccn),
      system = dplyr::case_when(
        grepl("^Prisma Health", .data$awardee) ~ "Prisma Health",
        grepl("^Self Regional Healthcare", .data$awardee) ~ "Self Regional Healthcare",
        TRUE ~ NA_character_),
      # A LIST OF SITES. Only Prisma prints one ("Upstate (Oconee, Lee, and
      # Laurens)"); Self Regional's commas separate a site from its CITY
      # ("(Imaging Center, Greenwood)") and are not lists.
      site_list = grepl("\\([^)]*,[^)]*\\)", .data$awardee) &
        .data$system %in% "Prisma Health")
}

sc_share <- function(num, den) round(100 * num / den, 1)

sc_bounds <- function(d = sc_rows()) {
  tot_n <- nrow(d); tot_d <- sum(d$amount)
  h <- d[d$hospital, ]
  h_d <- sum(h$amount)
  row <- function(reading, variant, n_hosp, n_all, d_hosp, d_all, note) {
    tibble::tibble(reading = reading, variant = variant,
                   hospital_awards = n_hosp, all_awards = n_all,
                   award_share_pct = sc_share(n_hosp, n_all),
                   hospital_dollars = round(d_hosp, 2),
                   all_dollars = round(d_all, 2),
                   dollar_share_pct = sc_share(d_hosp, d_all),
                   gap_to_60_pts = round(sc_share(d_hosp, d_all) - 60, 1),
                   note = note)
  }

  rural <- h[h$counts_as_rural %in% TRUE, ]
  ccn_ord <- h[h$rural_class %in% "FEDERAL_RECORD_CCN" & !(h$counts_as_rural %in% TRUE), ]
  unrec <- h[h$rural_class %in% "NOT_RECORDED", ]
  need <- SC_BENCHMARK$dollar_share * tot_d

  psy <- h[h$psych, ]
  acadia <- h[grepl("^Acadia", h$awardee), ]
  two_psy <- psy[!grepl("^Acadia", psy$awardee), ]

  sys <- d[!is.na(d$system), ]
  org_key <- ifelse(is.na(d$system), d$awardee, d$system)
  org <- tibble::tibble(org = org_key, hospital = d$hospital, amount = d$amount) %>%
    dplyr::group_by(.data$org) %>%
    dplyr::summarise(
      # Dollars stay classified ROW BY ROW: collapsing the grain must not
      # re-classify the money. (Computed BEFORE `hospital` is reassigned.)
      hosp_amount = sum(.data$amount[.data$hospital]),
      hospital = any(.data$hospital),
      amount = sum(.data$amount), .groups = "drop")
  split_extra <- sum(vapply(d$awardee[d$site_list], function(a) {
    inside <- stringr::str_match(a, "\\(([^)]*)\\)")[, 2]
    length(stringr::str_split(inside, ",| and ")[[1]] %>%
             stringr::str_squish() %>% .[nzchar(.)]) - 1L
  }, integer(1)))
  site <- h[h$awardee %in% SC_SELF_SITE_ROWS, ]

  out <- dplyr::bind_rows(
    row("0 as typed", "session 50's typing", nrow(h), tot_n, h_d, tot_d,
        "113 of 228 rows; $115,840,714.95 of $167,299,900.69."),
    row("0 as typed", "on the benchmark's own denominators", nrow(h),
        SC_BENCHMARK$awards, h_d, SC_BENCHMARK$dollars,
        "~240 awards / ~$170M: the agency counts 12 more awards and ~$2.7M more than the roster prints."),
    row("1 rural-only", "source-backed rural rows only", nrow(rural), tot_n,
        sum(rural$amount), tot_d,
        paste0("Only ", nrow(rural), " rows carry a source-backed rural designation (CMS CAH enrolment by cited CCN; ",
               "all Edgefield). Far BELOW 60%: rural-only counting on the evidence in hand does not land near the benchmark.")),
    row("1 rural-only", "coverage: CMS ordinary hospital by CCN (rural status not recorded)",
        nrow(ccn_ord), nrow(h), sum(ccn_ord$amount), h_d,
        "SHARE OF HOSPITAL DOLLARS, not of all dollars. An enrolled acute hospital is not evidence of urban either."),
    row("1 rural-only", "coverage: NOT_RECORDED (no source either way)",
        nrow(unrec), nrow(h), sum(unrec$amount), h_d,
        "SHARE OF HOSPITAL DOLLARS. Together with the line above, rural status is unknown for this much of the hospital money."),
    row("1 rural-only", "what 60% would require",
        NA_integer_, NA_integer_, need, h_d,
        paste0("The rural subset would have to hold $", format(round(need), big.mark = ","),
               " -- this share of SC's hospital dollars. Untestable here, and so NOT excluded.")),
    row("2 psychiatric excluded", "the two psychiatric hospitals (not Acadia)",
        nrow(h) - nrow(two_psy), tot_n, h_d - sum(two_psy$amount), tot_d,
        paste0(paste(two_psy$awardee, collapse = " + "), " = $",
               format(sum(two_psy$amount), big.mark = ","), "; CMS psychiatric CCNs.")),
    row("2 psychiatric excluded", "Acadia Healthcare Co. alone",
        nrow(h) - nrow(acadia), tot_n, h_d - sum(acadia$amount), tot_d,
        "$5,565,253; CMS CCN 424002 (Lighthouse Behavioral Health Hospital)."),
    row("2 psychiatric excluded", "all three psychiatric/behavioural rows",
        nrow(h) - nrow(psy), tot_n, h_d - sum(psy$amount), tot_d,
        paste0("$", format(sum(psy$amount), big.mark = ","), " out. Lands at ~65%, NOT at 60%.")),
    row("3 multi-site", "Prisma and Self Regional collapsed to one organisation each",
        sum(org$hospital), nrow(org), sum(org$hosp_amount), sum(org$amount),
        paste0("COUNTS MOVE, DOLLARS DO NOT (asserted): ", nrow(sys), " system rows become 2. ",
               "The agency's own '~240 awards' is ABOVE our 228 rows, so it does not count at organisation grain.")),
    row("3 multi-site", "...and the organisation then coded WHOLESALE (any hospital row makes it all hospital)",
        sum(org$hospital), nrow(org), sum(org$amount[org$hospital]), sum(org$amount),
        paste0("The only way the grain moves dollars: Self Regional's Greenwood Pediatrics practice row ($145,000) ",
               "is swept in. Upward, and by 0.1 point.")),
    row("3 multi-site", "multi-site rows split into one award per named site",
        nrow(h) + split_extra, tot_n + split_extra, h_d, tot_d,
        paste0(split_extra, " extra awards from ", sum(d$site_list),
               " rows naming a list of sites; dollars unchanged because no per-site split is published.")),
    row("3 multi-site", "Self Regional's three named non-hospital-site rows treated as its Greenwood Pediatrics row is",
        nrow(h) - nrow(site), tot_n, h_d - sum(site$amount), tot_d,
        paste0("$", format(sum(site$amount), big.mark = ","),
               " (Imaging Center, Montgomery Center, Optimum Life Rehabilitation Center). The ONLY site variant that moves dollars.")),
    row("2+3 combined", "psychiatric excluded AND the three site rows treated as non-hospital",
        nrow(h) - nrow(psy) - nrow(site), tot_n,
        h_d - sum(psy$amount) - sum(site$amount), tot_d,
        "The most the two testable readings can do together. Still above 60%.")
  )
  # A coverage line is a share of HOSPITAL dollars, so a distance from the
  # benchmark's 60% of ALL dollars would be a different quantity wearing the
  # same column.
  cov <- grepl("^coverage|^what 60%", out$variant)
  out$gap_to_60_pts[cov] <- NA_real_
  out
}

sc_assert_bounds <- function(b = sc_bounds(), d = sc_rows()) {
  base <- b[b$variant == "session 50's typing", ]
  org  <- b[grepl("collapsed", b$variant), ]
  # The grain cannot move dollars: the same money summed by organisation.
  stopifnot(isTRUE(all.equal(org$hospital_dollars, base$hospital_dollars)),
            isTRUE(all.equal(org$all_dollars, base$all_dollars)))
  stopifnot(nrow(d) == 228L, sum(d$hospital) == 113L,
            isTRUE(all.equal(sum(d$amount), 167299900.69)))
  invisible(TRUE)
}

sc_build <- function() {
  b <- sc_bounds()
  sc_assert_bounds(b)
  readr::write_csv(b, SC_BOUNDS_CSV, na = "")
  message("[SC] wrote ", SC_BOUNDS_CSV, " (", nrow(b), " rows)")
  invisible(b)
}

sc_report <- function() {
  b <- sc_bounds()
  options(width = 160)
  print(as.data.frame(b[, c("reading", "variant", "award_share_pct",
                            "dollar_share_pct", "gap_to_60_pts")]),
        row.names = FALSE)
  invisible(b)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--build" %in% args) sc_build()
  if ("--report" %in% args) sc_report()
  if (!length(args)) message("Usage: --build | --report")
}

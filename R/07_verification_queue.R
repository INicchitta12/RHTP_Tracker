# =============================================================================
# R/07_verification_queue.R -- THE CONSOLIDATED VERIFICATION QUEUE
#
# Every open verification question in this repository, in one workbook, at one
# grain: ONE ROW PER (queue_code, state, recipient organisation).
#
# THIS FILE IS READ-ONLY WITH RESPECT TO EVERY STATE FILE. It opens the
# committed reference CSVs, reads them, and writes exactly one artifact --
# output/verification_queue.xlsx. It re-codes nothing, promotes nothing and
# resolves nothing (spec 0.4). The four verification columns it emits
# (verified_type, verified_by, verified_date, basis) are EMPTY by design: they
# are for a human, and this file has no opinion to put in them.
#
# TWO ORIGINS, AND THE COLUMN `queue_source` SEPARATES THEM -- read it before
# quoting any total:
#
#   COMMITTED_QUEUE          the question has a committed row in
#                            data/reference/classification_review_queue.csv.
#                            19 such questions exist.
#
#   DERIVED_FROM_STATE_FILE  the STATE FILE carries rows on spec 8's standing
#                            fallback (NONPROFIT_CBO + LOW +
#                            RECIPIENT_TYPE_INFERRED) or on
#                            FLOW_UNRESOLVED_HOSPITAL_AFFILIATED, and NOBODY
#                            EVER WROTE A QUEUE ROW FOR IT. Iowa is the largest
#                            -- 102 rows, documented in CLAUDE.md as "the
#                            eighth" instance of the unstated-form question and
#                            never queued. These are the same open question by
#                            construction; they are marked DERIVED so a reader
#                            can always tell the committed queue from this
#                            sweep, and so this file is never mistaken for an
#                            edit to the committed queue.
#
# EVERY SELECTION IS CHECKED AGAINST THE FIGURE THE COMMITTED QUEUE ROW STATES
# FOR IT (vq_assert_committed_figures()). A selection that stops reproducing
# its queue row's own count or dollars is a build failure, not a discrepancy to
# reconcile in a report.
#
# Usage:
#   Rscript R/07_verification_queue.R --build     # writes the workbook
#   Rscript R/07_verification_queue.R --validate  # assertions only, no writes
#   Rscript R/07_verification_queue.R --report    # the totals, to stdout
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(tibble)
  library(readr)
})

VQ_REF   <- function(f) here::here("data", "reference", f)
VQ_XLSX  <- here::here("output", "verification_queue.xlsx")
VQ_QUEUE <- "classification_review_queue.csv"

# -- readers ------------------------------------------------------------------

vq_read <- function(file) {
  readr::read_csv(VQ_REF(file), col_types = readr::cols(.default = readr::col_character()),
                  progress = FALSE)
}

vq_num <- function(x) {
  n <- suppressWarnings(as.numeric(stringr::str_remove_all(x %||% "", "[$,]")))
  ifelse(is.na(n), 0, n)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

vq_col <- function(df, name) {
  if (name %in% names(df)) as.character(df[[name]]) else rep(NA_character_, nrow(df))
}

# -- predicates ---------------------------------------------------------------

# Spec 8's standing fallback: a named recipient whose organisational form the
# source does not state. This is the condition, not a spelling of it -- the
# flag is what the extractors write and what every queue row keys on.
vq_is_fallback <- function(df) {
  stringr::str_detect(vq_col(df, "flag_reason") %>% tidyr::replace_na(""),
                      "RECIPIENT_TYPE_INFERRED")
}

vq_is_flow_unresolved <- function(df) {
  stringr::str_detect(vq_col(df, "flag_reason") %>% tidyr::replace_na(""),
                      "FLOW_UNRESOLVED_HOSPITAL_AFFILIATED")
}

# =============================================================================
# THE SPEC. One entry per open question.
#
# `direction` says what answering it can do to the named-hospital figure:
#   UP        every row is distributed_to_hospital = No or Unclear today, so
#             resolving one can only RAISE the figure
#   DOWN      the row is counted as a hospital TODAY and could come out
#   ROWS_ONLY the state publishes no per-recipient amount, so the answer moves
#             a ROW COUNT and never a dollar (Nevada's rule)
#   NONE      $0 and 0 rows either way -- decide it on the spec, not the total
# =============================================================================

VQ_SPEC <- list(

  # ---- COMMITTED QUEUE ------------------------------------------------------

  list(code = "GHA_RECIPIENT_TYPE", state = "GA", src = "COMMITTED_QUEUE",
       file = "ga_great_health_awards.csv", name_col = "awardee",
       direction = "NONE", contingent = 0,
       pick = function(d) d$awardee == "Georgia Hospital Association",
       says = paste0("DCH names the recipient and states what the money does: GHA ",
                     "\"received a grant ... to provide obstetrical emergency carts\". ",
                     "The source states the ACTIVITY, not the organisational FORM.")),

  list(code = "KS_RECIPIENT_FORM_NOT_STATED", state = "KS", src = "COMMITTED_QUEUE",
       file = "ks_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 23L, expect_dollars = 40182073,
       pick = vq_is_fallback,
       says = "source states no form -- KDHE publishes a recipient and an amount and no organisation-type column"),

  list(code = "MD_RECIPIENT_FORM_NOT_STATED", state = "MD", src = "COMMITTED_QUEUE",
       file = "md_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 24L, expect_dollars = 36558089,
       pick = vq_is_fallback,
       says = "source states no form -- MDH publishes a recipient, an amount, a project summary and the counties served, and no organisation-type column"),

  # The same MD question, its other half: two rows typed HOSPITAL_OR_SYSTEM from
  # their NAMES that read as FQHCs. They are counted as hospitals today, so this
  # is the only DOWN direction in the file.
  list(code = "MD_RECIPIENT_FORM_NOT_STATED", state = "MD", src = "COMMITTED_QUEUE",
       file = "md_year1_awardees.csv", name_col = "awardee",
       direction = "DOWN", contingent = 0,
       pick = function(d) d$awardee %in% c("Choptank Community Health System Inc",
                                           "Mountain Laurel Medical Center"),
       says = "source states no form -- typed HOSPITAL_OR_SYSTEM from the NAME alone, and both read as FQHCs on the ordinary reading"),

  list(code = "NE_RECIPIENT_FORM_NOT_STATED", state = "NE", src = "COMMITTED_QUEUE",
       file = "ne_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 29L, expect_dollars = 9215948.66,
       pick = function(d) vq_is_fallback(d) &
         (vq_col(d, "intermediary_name") %>% tidyr::replace_na("")) == "",
       says = "source states no form -- DHHS publishes no organisation-type column. BUT its own 4.4b notice calls twenty-one organisations \"individual hospitals\", and four of these thirty appear on that roster under a near-identical name"),

  list(code = "IN_PROCUREMENT_VENDOR_TYPE", state = "IN", src = "COMMITTED_QUEUE",
       file = "in_year1_awardees.csv", name_col = "awardee",
       direction = "NONE", contingent = 0, expect_rows = 7L,
       pick = function(d) rep(TRUE, nrow(d)),
       says = "IDOA states a form in its own words -- \"has identified the following companies as the selected respondents\" under a competitive RFP -- which is NOT what spec 8's fallback describes"),

  list(code = "OK_RECIPIENT_FORM_NOT_STATED", state = "OK", src = "COMMITTED_QUEUE",
       file = "ok_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 31L, expect_dollars = 1575304.25,
       pick = vq_is_fallback,
       says = "source states no form -- OSDH publishes a county, a recipient, an amount and a project sentence, and no organisation-type column"),

  list(code = "NV_RECIPIENT_FORM_NOT_STATED", state = "NV", src = "COMMITTED_QUEUE",
       file = "nv_year1_awardees.csv", name_col = "awardee",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 23L, expect_dollars = 0,
       pick = vq_is_fallback,
       says = "source states no form -- NVHA publishes a subrecipient, a project and a service area, and NO AMOUNT AT ALL"),

  list(code = "MI_RECIPIENT_FORM_NOT_STATED", state = "MI", src = "COMMITTED_QUEUE",
       file = "mi_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 84L, expect_dollars = 39836422,
       pick = vq_is_fallback,
       says = "source states no form -- the MDHHS roster publishes three columns (Subrecipient Organization, Award Amount*, Fund) and nothing about form or project"),

  list(code = "MI_MHA_FLOW", state = "MI", src = "COMMITTED_QUEUE",
       file = "mi_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 2L, expect_dollars = 8625000,
       pick = vq_is_flow_unresolved,
       says = "MDHHS publishes NO project description. MHA's own page says only that it \"supports innovative solutions that help rural hospitals\" -- which is not a statement that money moves"),

  list(code = "MO_ANCHOR_FORM_NOT_STATED", state = "MO", src = "COMMITTED_QUEUE",
       file = "mo_hub_anchors.csv", name_col = "organization",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 11L,
       pick = function(d) d$recipient_type == "NONPROFIT_CBO",
       says = "source states no form -- DSS publishes one organisation per hub and NO dollar figure anywhere"),

  list(code = "MO_ANCHOR_IS_NOT_AN_AWARD", state = "MO", src = "COMMITTED_QUEUE",
       file = "mo_hub_anchors.csv", name_col = "organization",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 27L,
       overlaps = "MO_ANCHOR_FORM_NOT_STATED",
       pick = function(d) rep(TRUE, nrow(d)),
       says = "DSS ToRCH Care FAQ Q36: \"Hub Anchors will not act as the fiscal agent\", and participation is \"subject to execution of a Hub Anchor Participation Agreement\""),

  list(code = "ME_RHEF_COHORT_IS_NOT_AN_AWARD", state = "ME", src = "COMMITTED_QUEUE",
       file = "me_rhef_cohort.csv", name_col = "organization",
       direction = "ROWS_ONLY", contingent = 30000000, expect_rows = 11L,
       pick = function(d) rep(TRUE, nrow(d)),
       says = "DHHS \"has identified and INVITED 11 rural hospitals to participate\"; its own 2026-08-05 Advisory Committee deck says \"Award amount and approved budget will be confirmed after start of participation\""),

  list(code = "ME_UNE_HOSPITAL_TO_HOME_FLOW", state = "ME", src = "COMMITTED_QUEUE",
       file = "me_year1_awardees.csv", name_col = "awardee",
       direction = "NONE", contingent = 0, expect_rows = 1L,
       pick = function(d) rep(TRUE, nrow(d)),
       says = "UNE \"will provide this support by establishing subrecipient agreements with organizations in Maine's Public Health Districts and with each Tribal Health Center\" -- a class that is STATED and contains no hospital"),

  list(code = "NC_MIH_FORM_NOT_STATED", state = "NC", src = "COMMITTED_QUEUE",
       file = "nc_year1_awardees.csv", name_col = "awardee",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 2L,
       pick = function(d) d$awardee %in% c("Cape Fear Valley Mobile Integrated Health (MIH)",
                                           "Clay County"),
       says = "NCDHHS's own class sentence covers all 39: \"it will provide $10 million to 39 local EMS agencies\". These two are the only names that carry no EMS token"),

  list(code = "NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY", state = "NC", src = "COMMITTED_QUEUE",
       file = "nc_year1_awardees.csv", name_col = "awardee",
       direction = "NONE", contingent = 0, expect_rows = 1L,
       pick = function(d) d$awardee == "Access East, Inc.",
       says = "NCDHHS STATES a form spec 8 does not carry: \"a comprehensive care management provider and participant in North Carolina's Healthy Opportunities Pilot (HOP) program\""),

  list(code = "AR_RECIPIENT_FORM_NOT_STATED", state = "AR", src = "COMMITTED_QUEUE",
       file = "ar_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 21L, expect_dollars = 100723693.49,
       pick = vq_is_fallback,
       says = "source states no form -- DF&A publishes a recipient, an amount and NOTHING ELSE. No project description either"),

  list(code = "AR_ARHP_CONSORTIUM_FLOW", state = "AR", src = "COMMITTED_QUEUE",
       file = "ar_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 2L, expect_dollars = 18833521,
       overlaps = "AR_RECIPIENT_FORM_NOT_STATED",
       pick = vq_is_flow_unresolved,
       says = "the award list says NEITHER of spec 10.2's two things -- not that funds are administered to member hospitals, and not that ARHP delivers goods or services with them"),

  list(code = "WY_TECH_FORM_NOT_STATED", state = "WY", src = "COMMITTED_QUEUE",
       file = "wy_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 4L, expect_dollars = 1535722,
       pick = function(d) vq_is_fallback(d) & d$award_pool == "3.1 Technology Adoption Challenge",
       says = "source states no form -- and, uniquely among the six tables in this document, Initiative 3.1 publishes NO EIN COLUMN either, so the key that carries Wyoming's stated hospital form from 1.1 cannot reach it"),

  list(code = "WY_EMS_LEAD_AGENCY_FORM", state = "WY", src = "COMMITTED_QUEUE",
       file = "wy_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 1L, expect_dollars = 1700000,
       pick = function(d) d$awardee == "Campbell County Health (CCH) Emergency Medical Servic",
       says = "the producer TRUNCATES the cell at its column edge, so the name is INCOMPLETE in Wyoming's own document, and its EIN (83-0234097) is not in the 1.1 hospital table"),

  # ---- DERIVED FROM THE STATE FILES ----------------------------------------
  # Same condition, no committed queue row. The state's own extractor wrote the
  # flag; nobody ever opened the question.

  list(code = "IA_RECIPIENT_FORM_NOT_STATED", state = "IA", src = "DERIVED_FROM_STATE_FILE",
       file = "ia_year1_awardees.csv", name_col = "awardee",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 102L, expect_dollars = 0,
       pick = vq_is_fallback,
       says = "source states no form -- Iowa's Notices of Intent to Award publish a named roster and NO PER-RECIPIENT AMOUNT ANYWHERE"),

  list(code = "OR_RECIPIENT_FORM_NOT_STATED", state = "OR", src = "DERIVED_FROM_STATE_FILE",
       file = "or_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = function(d) vq_is_fallback(d) & d$recipient_type == "NONPROFIT_CBO",
       says = "source states no form -- OHA publishes an Organization Type column for most pools and these rows fall outside it"),

  list(code = "AK_RECIPIENT_FORM_NOT_STATED", state = "AK", src = "DERIVED_FROM_STATE_FILE",
       file = "ak_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = vq_is_fallback,
       says = "source states no form -- Alaska publishes an Organization Type per PROJECT and these rows fall outside its vocabulary"),

  list(code = "AL_RECIPIENT_FORM_NOT_STATED", state = "AL", src = "DERIVED_FROM_STATE_FILE",
       file = "al_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = vq_is_fallback,
       says = "source states no form -- the Governor's release is prose naming a recipient and an amount"),

  list(code = "FL_RECIPIENT_FORM_NOT_STATED", state = "FL", src = "DERIVED_FROM_STATE_FILE",
       file = "fl_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = vq_is_fallback,
       says = "source states no form -- the five rows the owner's workbook left UNCLASSIFIED, back-fitted to spec 8's fallback in session 10"),

  list(code = "GA_RECIPIENT_FORM_NOT_STATED", state = "GA", src = "DERIVED_FROM_STATE_FILE",
       file = "ga_great_health_awards.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = vq_is_fallback,
       says = "source states no form -- DCH names the awardee and publishes an amount per INITIATIVE, not per recipient"),

  list(code = "ID_RECIPIENT_FORM_NOT_STATED", state = "ID", src = "DERIVED_FROM_STATE_FILE",
       file = "id_year1_awardees.csv", name_col = "awardee",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 1L,
       pick = vq_is_fallback,
       says = "source states no form -- DHW publishes one \"Awardee:\" line and NO amount. This is Delaware's CONTROL: the same classifier answer, and here it is the RIGHT one"),

  list(code = "IL_RECIPIENT_FORM_NOT_STATED", state = "IL", src = "DERIVED_FROM_STATE_FILE",
       file = "il_year1_awardees.csv", name_col = "awardee",
       direction = "NONE", contingent = 0, expect_rows = 1L,
       pick = vq_is_fallback,
       says = "ICAHN's NONPROFIT_CBO is spec 10.2's PRESCRIBED coding for a hospital association, not a defaulted one. GOVERNED BY GHA_RECIPIENT_TYPE, which decides this class. Already distributed_to_hospital = Yes (POOL_UNNAMED_HOSPITALS), so no retyping moves a dollar"),

  list(code = "NH_RECIPIENT_FORM_NOT_STATED", state = "NH", src = "DERIVED_FROM_STATE_FILE",
       file = "nh_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, expect_rows = 2L,
       flow_settled = TRUE,
       pick = vq_is_fallback,
       says = "source states no form. THE FLOW IS SEPARATELY SETTLED AND IS NOT THIS QUESTION: FHC is PASS_THROUGH_UNRESOLVED + Unclear because its eligible class is hospitals AMONG OTHERS (spec 0.3), and no retyping changes that"),

  list(code = "WY_CARE_COORDINATION_FORM_NOT_STATED", state = "WY", src = "DERIVED_FROM_STATE_FILE",
       file = "wy_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0,
       pick = function(d) vq_is_fallback(d) &
         d$award_pool == "4.2 Clinically-Integrated Care Coordination",
       says = "source states no form -- Initiative 4.2's table publishes an approved amount per allocation and nothing about the recipient"),

  list(code = "WY_FISCAL_AGENT_FORM_NOT_STATED", state = "WY", src = "DERIVED_FROM_STATE_FILE",
       file = "wy_year1_awardees.csv", name_col = "awardee",
       direction = "UP", contingent = 0, flow_settled = TRUE,
       pick = function(d) vq_is_fallback(d) &
         stringr::str_detect(d$awardee, "Wyoming Innovation Partnership"),
       says = "source states no form. THE FLOW IS SEPARATELY SETTLED AND IS NOT THIS QUESTION: WIP is the sole-source MASTER FISCAL AGENT, PASS_THROUGH_UNRESOLVED + Unclear on New Hampshire's FHC footing, because its class is individuals AND institutions (spec 0.3)"),

  list(code = "NV_INCLINE_VILLAGE_FOUNDATION_FLOW", state = "NV", src = "DERIVED_FROM_STATE_FILE",
       file = "nv_year1_awardees.csv", name_col = "awardee",
       direction = "ROWS_ONLY", contingent = 0, expect_rows = 1L,
       pick = vq_is_flow_unresolved,
       says = "a hospital's OWN foundation awarded to recruit providers, with NVHA silent on whether the money reaches the hospital. The first row in this repository to carry FLOW_UNRESOLVED_HOSPITAL_AFFILIATED (session 26)")
)

# -- assembly -----------------------------------------------------------------

vq_explode <- function(entry) {
  d <- vq_read(entry$file)
  keep <- entry$pick(d)
  idx <- which(keep)
  d <- d[keep, , drop = FALSE]
  if (nrow(d) == 0) {
    stop("[VQ] selection is EMPTY for ", entry$code, " / ", entry$state,
         " -- the state file no longer carries the rows this question is about")
  }
  says_file <- vq_col(d, "recipient_type_source") %>% tidyr::replace_na("")
  # A recipient_type_source that merely echoes a code, or says DERIVED_FROM_NAME,
  # is the file saying the form came from the NAME -- i.e. the source stated none.
  says_file <- ifelse(stringr::str_detect(says_file, "^[A-Z_]+$") | says_file == "", "", says_file)

  tibble::tibble(
    source_row_id      = paste0(entry$file, ":", idx),
    state              = entry$state,
    queue_code         = entry$code,
    queue_source       = entry$src,
    recipient_name     = vq_col(d, entry$name_col),
    award_pool         = vq_col(d, "award_pool"),
    amount             = vq_num(vq_col(d, "amount")),
    classifier_type    = vq_col(d, "recipient_type"),
    classifier_conf    = dplyr::coalesce(vq_col(d, "determination_confidence"),
                                         vq_col(d, "recipient_type_confidence")),
    current_flow       = vq_col(d, "flow_type"),
    current_dth        = vq_col(d, "distributed_to_hospital"),
    source_url         = vq_col(d, "state_source_url"),
    archive_path       = vq_col(d, "source_archive_path"),
    says_row           = says_file,
    source_file        = entry$file,
    direction          = entry$direction,
    contingent_dollars = entry$contingent %||% 0,
    flow_settled       = isTRUE(entry$flow_settled),
    overlaps_with      = entry$overlaps %||% NA_character_,
    says_question      = entry$says
  )
}

vq_rows <- function() {
  purrr::map_dfr(VQ_SPEC, vq_explode)
}

# One row per (queue_code, state, recipient organisation). A reviewer answers
# "what form is Baxter Health?" ONCE, not once per award row -- but the award
# row count is kept beside it so nothing is lost.
vq_build <- function() {
  raw <- vq_rows()

  out <- raw %>%
    dplyr::group_by(state, queue_code, queue_source, recipient_name) %>%
    dplyr::summarise(
      award_amount       = sum(amount),
      award_rows         = dplyr::n(),
      award_pools        = paste(sort(unique(award_pool[!is.na(award_pool) & award_pool != ""])),
                                 collapse = " | "),
      classifier_assigned = paste(sort(unique(paste0(classifier_type, " / ",
                                                     classifier_conf))), collapse = " | "),
      current_coding     = paste(sort(unique(paste0(current_flow, " / distributed_to_hospital = ",
                                                    current_dth))), collapse = " | "),
      what_the_source_says = {
        rs <- unique(says_row[says_row != ""])
        q  <- unique(says_question)[1]
        if (length(rs) > 0 && any(!stringr::str_detect(rs, "does not state its organisational form"))) {
          paste0(q, "  [row: ", paste(rs, collapse = " ; "), "]")
        } else q
      },
      source_url         = dplyr::first(source_url),
      archive_path       = dplyr::first(archive_path),
      source_file        = dplyr::first(source_file),
      direction          = dplyr::first(direction),
      contingent_dollars = dplyr::first(contingent_dollars),
      flow_settled       = dplyr::first(flow_settled),
      overlaps_with      = dplyr::first(overlaps_with),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      # `dollars_at_stake` is what ANSWERING THIS QUESTION can move into or out
      # of the named-hospital figure -- NOT the size of the award. A NONE-
      # direction question moves nothing whatever the answer (Illinois's ICAHN
      # is already distributed_to_hospital = Yes; Maine's University of New
      # England is No under both codings), and a ROWS_ONLY state publishes no
      # per-recipient amount at all. `award_amount` keeps the published figure
      # beside it so nothing is lost.
      dollars_at_stake = ifelse(direction %in% c("UP", "DOWN"), award_amount, 0),
      verified_type = NA_character_,
      verified_by   = NA_character_,
      verified_date = NA_character_,
      basis         = NA_character_
    ) %>%
    dplyr::arrange(dplyr::desc(dollars_at_stake), dplyr::desc(award_amount),
                   state, queue_code, recipient_name) %>%
    dplyr::mutate(queue_row = dplyr::row_number()) %>%
    dplyr::select(queue_row, state, recipient_name, dollars_at_stake, award_amount, award_rows,
                  queue_code, queue_source, direction, what_the_source_says,
                  classifier_assigned, current_coding, award_pools,
                  source_url, archive_path, source_file,
                  contingent_dollars, flow_settled, overlaps_with,
                  verified_type, verified_by, verified_date, basis)

  out
}

# =============================================================================
# THE CURRENT FLOOR -- read from the repository, never typed
#
# The same twenty-six files test_state_union.R combines, put through the
# repository's OWN partition function. This file does not re-implement the
# hospital rule; if rhtp_hospital_dollar_partition() ever changes, the bounds
# below change with it, which is the point.
# =============================================================================

VQ_UNION_FILES <- c(
  "ak_year1_awardees.csv", "al_year1_awardees.csv", "ar_year1_awardees.csv",
  "de_year1_awardees.csv", "fl_year1_awardees.csv", "ga_great_health_awards.csv",
  "ia_year1_awardees.csv", "id_year1_awardees.csv", "il_year1_awardees.csv",
  "in_year1_awardees.csv", "ks_year1_awardees.csv", "md_year1_awardees.csv",
  "me_year1_awardees.csv", "mi_year1_awardees.csv", "mo_year1_awardees.csv",
  "nc_year1_awardees.csv", "ne_year1_awardees.csv", "nh_year1_awardees.csv",
  "nv_year1_awardees.csv", "oh_year1_awardees.csv", "ok_year1_awardees.csv",
  "or_year1_awardees.csv", "pa_year1_awardees.csv", "sd_rht_contracts.csv",
  "sd_year1_awardees.csv", "wy_year1_awardees.csv"
)

vq_union <- function() {
  purrr::map_dfr(VQ_UNION_FILES, function(f) {
    d <- vq_read(f)
    tibble::tibble(
      state                   = vq_col(d, "state"),
      awardee                 = dplyr::coalesce(vq_col(d, "awardee"),
                                                vq_col(d, "organization")),
      amount                  = vq_col(d, "amount"),
      recipient_type          = vq_col(d, "recipient_type"),
      determination_confidence = dplyr::coalesce(vq_col(d, "determination_confidence"),
                                                 vq_col(d, "recipient_type_confidence")),
      distributed_to_hospital = vq_col(d, "distributed_to_hospital"),
      flow_type               = vq_col(d, "flow_type"),
      hospital_attribution    = vq_col(d, "hospital_attribution"),
      flag_reason             = vq_col(d, "flag_reason") %>% tidyr::replace_na(""),
      source_file             = f
    )
  })
}

vq_floor <- function() {
  source(here::here("R", "utils_recipient_classification.R"), local = TRUE)
  parts <- rhtp_hospital_dollar_partition(vq_union())
  named <- parts %>% dplyr::filter(bucket == "NAMED_HOSPITAL")
  list(
    rows    = sum(named$rows),
    dollars = sum(named$dollars),
    states  = dplyr::n_distinct(named$state),
    parts   = parts
  )
}

# =============================================================================
# TASK 2 -- RECURRING ENTITIES
#
# THIS FLAGS AND A HUMAN READS. Spec 2 forbids a fuzzy hospital match
# AUTO-RESOLVING, and nothing here resolves anything: every match is a prompt
# with both raw spellings printed side by side, so the reader judges. Three
# tiers, strongest first, and the tier is on the row:
#
#   EXACT   the normalised names are IDENTICAL. Wyoming's "Bighorn Valley
#           Health Center, Inc. dba One Health" is the identical STRING in
#           Initiatives 3.1 and 4.1 and classifies differently in the two.
#   PREFIX  one normalised name is a word-boundary prefix of the other.
#           "Powell Valley Health Care" against Wyoming's own "Powell Valley
#           Health Care Inc".
#   BRAND   a shared distinctive FIRST TOKEN only. The weakest tier and the
#           one most likely to be wrong -- Arkansas's "Baptist Health" and
#           Oklahoma's "Baptist Healthcare" are different organisations in
#           different states. It is here because a reader can dismiss a bad
#           BRAND match in one glance and cannot find a missing one at all.
#
# A match is only reported where ONE SIDE IS RESOLVED and the other is open:
# that is what makes it a free answer rather than a coincidence.
# =============================================================================

VQ_GENERIC <- c("health", "healthcare", "community", "regional", "rural", "county",
                "medical", "center", "centre", "care", "family", "valley", "memorial",
                "north", "south", "east", "west", "new", "first", "the", "of", "and",
                "services", "service", "system", "systems", "hospital", "clinic",
                "district", "association", "foundation", "inc", "llc", "corp", "group",
                # a leading STATE NAME is the least distinctive token there is,
                # and it is what made this tier unusable before it was excluded:
                # "Wyoming Innovation Partnership" against "Wyoming Medical
                # Center" is a shared geography, not a shared organisation.
                "alabama", "alaska", "arizona", "arkansas", "california",
                "colorado", "connecticut", "delaware", "florida", "georgia",
                "hawaii", "idaho", "illinois", "indiana", "iowa", "kansas",
                "kentucky", "louisiana", "maine", "maryland", "massachusetts",
                "michigan", "minnesota", "mississippi", "missouri", "montana",
                "nebraska", "nevada", "hampshire", "jersey", "mexico", "york",
                "carolina", "dakota", "ohio", "oklahoma", "oregon",
                "pennsylvania", "rhode", "tennessee", "texas", "utah",
                "vermont", "virginia", "washington", "wisconsin", "wyoming",
                "greater", "cornerstone", "children", "childrens", "special",
                "national", "statewide", "central", "northern",
                "southern", "eastern", "western", "mid", "tri", "upper", "lower")

VQ_SUFFIX <- c("inc", "incorporated", "llc", "llp", "lp", "corp", "corporation",
               "co", "ltd", "pc", "plc", "pa", "pllc")

vq_normalise <- function(x) {
  y <- x %>%
    stringr::str_replace_all("[‘’ʼ]", "'") %>%
    stringr::str_replace_all("[–—−]", "-") %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("[^a-z0-9]+", " ") %>%
    stringr::str_squish()
  # strip trailing corporate suffixes, repeatedly
  for (i in 1:3) {
    y <- stringr::str_remove(y, paste0("\\s+(", paste(VQ_SUFFIX, collapse = "|"), ")$"))
  }
  stringr::str_squish(y)
}

vq_first_token <- function(n) stringr::str_extract(n, "^[a-z0-9]+")

vq_recurring <- function(queue, raw = vq_rows()) {
  union <- vq_union() %>%
    dplyr::group_by(source_file) %>%
    dplyr::mutate(source_row_id = paste0(source_file, ":", dplyr::row_number())) %>%
    dplyr::ungroup() %>%
    dplyr::filter(!is.na(awardee), awardee != "",
                  !is.na(recipient_type), recipient_type != "")

  # A ROW IS NEVER ITS OWN FREE ANSWER. Six of the questions here are not about
  # spec 8's fallback at all (Georgia's GHA, Indiana's seven vendors, Maine's
  # UNE, Michigan's MHA, Nevada's Incline Village foundation), so those rows sit
  # in the queue while carrying a determinate type -- and would match
  # themselves. Excluded by ROW IDENTITY, not by name.
  resolved <- union %>%
    dplyr::filter(!source_row_id %in% raw$source_row_id) %>%
    dplyr::filter(!stringr::str_detect(flag_reason, "RECIPIENT_TYPE_INFERRED"),
                  recipient_type != "NOT_YET_NAMED") %>%
    dplyr::transmute(
      resolved_state = state,
      resolved_name  = awardee,
      resolved_type  = recipient_type,
      resolved_conf  = determination_confidence,
      resolved_dth   = distributed_to_hospital,
      resolved_file  = source_file,
      norm           = vq_normalise(awardee)
    ) %>%
    dplyr::distinct(resolved_state, resolved_name, resolved_type, resolved_conf,
                    resolved_dth, resolved_file, norm)

  open <- queue %>%
    dplyr::transmute(
      queue_row, open_state = state, open_name = recipient_name,
      open_code = queue_code, open_dollars = dollars_at_stake, open_award = award_amount,
      open_type = classifier_assigned,
      norm = vq_normalise(recipient_name)
    )

  # -- EXACT
  exact <- open %>%
    dplyr::inner_join(resolved, by = "norm", relationship = "many-to-many") %>%
    dplyr::mutate(match_tier = "EXACT")

  # -- PREFIX (word-boundary, both sides substantial)
  cand <- tidyr::expand_grid(
    open %>% dplyr::filter(stringr::str_count(norm, "\\S+") >= 2, nchar(norm) >= 12),
    resolved %>% dplyr::filter(stringr::str_count(norm, "\\S+") >= 2, nchar(norm) >= 12) %>%
      dplyr::rename(rnorm = norm)
  )
  prefix <- cand %>%
    dplyr::filter(norm != rnorm,
                  stringr::str_starts(rnorm, stringr::fixed(paste0(norm, " "))) |
                    stringr::str_starts(norm, stringr::fixed(paste0(rnorm, " ")))) %>%
    dplyr::select(-rnorm) %>%
    dplyr::mutate(match_tier = "PREFIX")

  # -- BRAND (shared distinctive first token only)
  brand <- tidyr::expand_grid(
    open %>% dplyr::mutate(tok = vq_first_token(norm)),
    resolved %>% dplyr::mutate(rtok = vq_first_token(norm)) %>% dplyr::rename(rnorm = norm)
  ) %>%
    # BRAND IS THE WEAK TIER AND IS DELIBERATELY NARROWED TO FREE ANSWERS. A
    # shared brand token pointing at another organisation that is ALSO
    # unresolved answers nothing, and 329 such pairs drowned the ten that
    # matter. The resolved side must already be a hospital dollar.
    dplyr::filter(!is.na(tok), tok == rtok, nchar(tok) >= 5,
                  !tok %in% VQ_GENERIC, norm != rnorm, resolved_dth == "Yes",
                  !stringr::str_starts(rnorm, stringr::fixed(paste0(norm, " "))),
                  !stringr::str_starts(norm, stringr::fixed(paste0(rnorm, " ")))) %>%
    dplyr::select(-rnorm, -tok, -rtok) %>%
    dplyr::mutate(match_tier = "BRAND")

  dplyr::bind_rows(exact, prefix, brand) %>%
    dplyr::mutate(
      scope = ifelse(open_state == resolved_state, "SAME_STATE", "CROSS_STATE"),
      free_answer = ifelse(match_tier == "EXACT" & resolved_dth == "Yes",
                           "YES -- the same organisation is already coded a hospital elsewhere",
                           ifelse(match_tier == "EXACT",
                                  "YES -- the same organisation is already TYPED elsewhere",
                                  "READ IT -- a near name, not an identity"))
    ) %>%
    dplyr::arrange(factor(match_tier, levels = c("EXACT", "PREFIX", "BRAND")),
                   dplyr::desc(open_dollars), open_state, open_name) %>%
    dplyr::select(match_tier, scope, free_answer,
                  open_state, open_name, open_code, open_dollars, open_award, open_type,
                  resolved_state, resolved_name, resolved_type, resolved_conf,
                  resolved_dth, resolved_file, queue_row)
}

# =============================================================================
# ASSERTIONS
# =============================================================================

vq_assert_committed_figures <- function(raw) {
  for (entry in VQ_SPEC) {
    if (is.null(entry$expect_rows) && is.null(entry$expect_dollars)) next
    got <- raw %>% dplyr::filter(queue_code == entry$code, state == entry$state,
                                 direction == entry$direction)
    if (!is.null(entry$expect_rows) && nrow(got) != entry$expect_rows) {
      stop("[VQ] ", entry$code, " selects ", nrow(got), " award rows; the ",
           "committed queue row states ", entry$expect_rows,
           ". The selection and the queue have drifted apart -- re-read the ",
           "state file, do not adjust the expectation.", call. = FALSE)
    }
    if (!is.null(entry$expect_dollars)) {
      d <- sum(got$amount)
      if (abs(d - entry$expect_dollars) > 0.01) {
        stop("[VQ] ", entry$code, " selects $", format(d, big.mark = ","),
             "; the committed queue row states $",
             format(entry$expect_dollars, big.mark = ","), ".", call. = FALSE)
      }
    }
  }
  invisible(TRUE)
}

# Every OPEN row in the committed queue must appear in this workbook. A
# consolidation that silently drops a question is worse than no consolidation.
vq_assert_queue_covered <- function(queue) {
  q <- vq_read(VQ_QUEUE) %>% dplyr::filter(queue_status == "OPEN")
  missing <- setdiff(unique(q$question_id), unique(queue$queue_code))
  if (length(missing) > 0) {
    stop("[VQ] ", length(missing), " OPEN question(s) in ", VQ_QUEUE,
         " are NOT in the workbook: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  n_open <- nrow(q)
  n_have <- dplyr::n_distinct(queue$queue_code[queue$queue_source == "COMMITTED_QUEUE"])
  if (n_have != n_open) {
    stop("[VQ] the committed queue has ", n_open, " OPEN rows; the workbook ",
         "carries ", n_have, " committed codes.", call. = FALSE)
  }
  invisible(TRUE)
}

# The sweep must not miss a fallback row. Every RECIPIENT_TYPE_INFERRED and
# every FLOW_UNRESOLVED_HOSPITAL_AFFILIATED row in every union file is either
# in this workbook or named here as a deliberate exclusion.
vq_assert_sweep_complete <- function(raw) {
  swept <- purrr::map_dfr(VQ_UNION_FILES, function(f) {
    d <- vq_read(f)
    fl <- vq_col(d, "flag_reason") %>% tidyr::replace_na("")
    rt <- vq_col(d, "recipient_type") %>% tidyr::replace_na("")
    hit <- stringr::str_detect(
      fl, "RECIPIENT_TYPE_INFERRED|FLOW_UNRESOLVED_HOSPITAL_AFFILIATED") &
      rt != "NOT_YET_NAMED"
    tibble::tibble(source_row_id = paste0(f, ":", which(hit)),
                   awardee = dplyr::coalesce(vq_col(d, "awardee"),
                                             vq_col(d, "organization"))[which(hit)])
  })

  # THE ONE DELIBERATE EXCLUSION, and it is the committed queue's own: Nebraska
  # has THIRTY fallback rows and its queue row covers TWENTY-NINE. The
  # thirtieth carries an `intermediary_name` -- it is a Nebraska High Value
  # Network roster row, whose form DHHS DOES state on the notice ("individual
  # hospitals"), so it is not the unstated-form question at all.
  excluded <- swept %>%
    dplyr::filter(stringr::str_starts(source_row_id, "ne_year1_awardees.csv")) %>%
    dplyr::anti_join(raw, by = "source_row_id")
  if (nrow(excluded) != 1) {
    stop("[VQ] expected exactly ONE deliberately excluded Nebraska row ",
         "(the NHVN roster row carrying an intermediary_name); found ",
         nrow(excluded), ".", call. = FALSE)
  }

  missing <- swept %>%
    dplyr::anti_join(raw, by = "source_row_id") %>%
    dplyr::anti_join(excluded, by = "source_row_id")
  if (nrow(missing) > 0) {
    stop("[VQ] ", nrow(missing), " flagged row(s) in the state files are in NO ",
         "queue code -- the sweep would silently drop them:\n",
         paste(utils::capture.output(print(as.data.frame(missing))), collapse = "\n"),
         call. = FALSE)
  }

  # And nothing may be in the workbook on a flag the state file does not carry,
  # except the questions that are not about the fallback at all.
  not_flag_based <- c("GHA_RECIPIENT_TYPE", "IN_PROCUREMENT_VENDOR_TYPE",
                      "MO_ANCHOR_FORM_NOT_STATED", "MO_ANCHOR_IS_NOT_AN_AWARD",
                      "ME_RHEF_COHORT_IS_NOT_AN_AWARD", "ME_UNE_HOSPITAL_TO_HOME_FLOW")
  extra <- raw %>%
    dplyr::filter(!queue_code %in% not_flag_based,
                  !(queue_code == "MD_RECIPIENT_FORM_NOT_STATED" & direction == "DOWN")) %>%
    dplyr::anti_join(swept, by = "source_row_id")
  if (nrow(extra) > 0) {
    stop("[VQ] ", nrow(extra), " workbook row(s) rest on a flag the state file ",
         "does not carry: ", paste(unique(extra$recipient_name), collapse = "; "),
         call. = FALSE)
  }
  invisible(TRUE)
}

# Overlapping dollars must be declared, never double-counted. Arkansas Rural
# Health Partnership raises TWO questions on the SAME two award rows -- spec 8's
# typing and spec 10.2's flow -- and its $18,833,521 is inside the AR ceiling
# ONCE, not twice. The committed queue row says so in its own words.
vq_assert_overlap_declared <- function(raw, queue) {
  shared <- raw %>%
    dplyr::distinct(source_row_id, queue_code, state, recipient_name, amount) %>%
    dplyr::group_by(source_row_id) %>%
    dplyr::filter(dplyr::n() > 1) %>%
    dplyr::ungroup()
  if (nrow(shared) == 0) return(invisible(TRUE))

  declared_codes <- queue %>%
    dplyr::filter(!is.na(overlaps_with)) %>%
    dplyr::distinct(queue_code, overlaps_with)
  bad <- shared %>%
    dplyr::group_by(source_row_id) %>%
    dplyr::summarise(codes = paste(sort(unique(queue_code)), collapse = " + "),
                     who = dplyr::first(recipient_name), .groups = "drop") %>%
    dplyr::filter(!purrr::map_lgl(codes, function(cc) {
      parts <- stringr::str_split(cc, " \\+ ")[[1]]
      any(declared_codes$queue_code %in% parts & declared_codes$overlaps_with %in% parts)
    }))
  if (nrow(bad) > 0) {
    stop("[VQ] ", nrow(bad), " award row(s) carry more than one queue code with ",
         "NO `overlaps` declared on the spec, so their dollars would be counted ",
         "twice: ", paste(unique(bad$who), collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

# Spec 0.4: a determination without a captured, archived source is not a
# determination -- so a queue row pointing at an archive that is not there
# sends a reviewer to nothing. Every path this workbook names must exist.
vq_assert_archives_exist <- function(queue) {
  paths <- unique(queue$archive_path)
  paths <- paths[!is.na(paths) & paths != ""]
  missing <- paths[!file.exists(here::here(paths))]
  if (length(missing) > 0) {
    stop("[VQ] ", length(missing), " archive path(s) named by this queue do not ",
         "exist on disk: ", paste(missing, collapse = "; "), call. = FALSE)
  }
  invisible(length(paths))
}

vq_validate <- function() {
  raw <- vq_rows()
  queue <- vq_build()
  vq_assert_committed_figures(raw)
  vq_assert_queue_covered(queue)
  vq_assert_sweep_complete(raw)
  vq_assert_overlap_declared(raw, queue)
  vq_assert_archives_exist(queue)
  message("[VQ] all assertions pass -- ", nrow(queue), " queue rows, ",
          dplyr::n_distinct(queue$queue_code), " codes, ",
          dplyr::n_distinct(queue$state), " states")
  invisible(TRUE)
}

# =============================================================================
# TASK 3 -- THE TOTALS
# =============================================================================

vq_totals <- function(queue = vq_build(), raw = vq_rows()) {
  fl <- vq_floor()

  # AN AWARD ROW'S DOLLARS ARE COUNTED ONCE, even where two codes ask two
  # questions about it -- Arkansas Rural Health Partnership's two rows carry
  # both spec 8's typing question and spec 10.2's flow question, and its
  # $18,833,521 is inside the ceiling once. De-duplication is on the SOURCE
  # ROW, never on the name: Wyoming's Instaclinic LLC holds awards under two
  # different initiatives and those are different dollars.
  dedup <- raw %>%
    dplyr::group_by(source_row_id) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(state, recipient_name, queue_code, queue_source, direction,
                    flow_settled) %>%
    dplyr::summarise(award_amount = sum(amount), award_rows = dplyr::n(),
                     .groups = "drop") %>%
    dplyr::mutate(dollars_at_stake = ifelse(direction %in% c("UP", "DOWN"),
                                            award_amount, 0))

  up   <- dedup %>% dplyr::filter(direction == "UP")
  down <- dedup %>% dplyr::filter(direction == "DOWN")

  up_committed <- up %>% dplyr::filter(queue_source == "COMMITTED_QUEUE")
  up_derived   <- up %>% dplyr::filter(queue_source == "DERIVED_FROM_STATE_FILE")
  up_settled   <- up %>% dplyr::filter(flow_settled)

  list(
    floor_rows      = fl$rows,
    floor_dollars   = fl$dollars,
    floor_states    = fl$states,
    queue_rows      = nrow(queue),
    award_rows      = sum(queue$award_rows),
    codes           = dplyr::n_distinct(queue$queue_code),
    states          = dplyr::n_distinct(queue$state),
    distinct_orgs   = dplyr::n_distinct(vq_normalise(queue$recipient_name)),
    dollars_total   = sum(dedup$dollars_at_stake),
    dollars_up      = sum(up$dollars_at_stake),
    dollars_down    = sum(down$dollars_at_stake),
    dollars_up_committed = sum(up_committed$dollars_at_stake),
    dollars_up_derived   = sum(up_derived$dollars_at_stake),
    dollars_up_settled   = sum(up_settled$dollars_at_stake),
    rows_only       = sum(dedup$direction == "ROWS_ONLY"),
    rows_only_rows  = sum(dedup$award_rows[dedup$direction == "ROWS_ONLY"]),
    none            = sum(dedup$direction == "NONE"),
    contingent      = sum(unique(queue$contingent_dollars[queue$contingent_dollars > 0])),
    ceiling         = fl$dollars + sum(up$dollars_at_stake),
    floor_if_none   = fl$dollars - sum(down$dollars_at_stake),
    by_state = queue %>%
      dplyr::group_by(state) %>%
      dplyr::summarise(queue_rows = dplyr::n(),
                       award_rows = sum(award_rows),
                       dollars_at_stake = sum(dollars_at_stake),
                       award_amount = sum(award_amount), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(dollars_at_stake), dplyr::desc(award_amount)),
    by_code = queue %>%
      dplyr::group_by(queue_code, queue_source, direction) %>%
      dplyr::summarise(queue_rows = dplyr::n(),
                       award_rows = sum(award_rows),
                       dollars_at_stake = sum(dollars_at_stake),
                       award_amount = sum(award_amount), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(dollars_at_stake), dplyr::desc(award_amount))
  )
}

vq_money <- function(x) paste0("$", formatC(x, format = "f", digits = 0, big.mark = ","))

vq_report <- function() {
  queue <- vq_build()
  raw <- vq_rows()
  t <- vq_totals(queue, raw)
  rec <- vq_recurring(queue, raw)

  cat("\n=========================================================================\n")
  cat("CONSOLIDATED VERIFICATION QUEUE\n")
  cat("=========================================================================\n\n")
  cat("  queue rows (state x recipient x question) :", t$queue_rows, "\n")
  cat("  underlying award rows                     :", t$award_rows, "\n")
  cat("  distinct organisations (normalised)       :", t$distinct_orgs, "\n")
  cat("  questions (queue codes)                   :", t$codes, "\n")
  cat("  states                                    :", t$states, "\n")
  cat("  dollars at stake (de-duplicated)          :", vq_money(t$dollars_total), "\n\n")

  cat("THE BOUNDED RANGE\n")
  cat("  named-hospital floor TODAY   :", vq_money(t$floor_dollars),
      "  (", t$floor_rows, "rows,", t$floor_states, "states )\n")
  cat("  if EVERY open row resolves to a hospital :", vq_money(t$ceiling), "\n")
  cat("  if NO open row does                      :", vq_money(t$floor_if_none), "\n")
  cat("  => the verification pass closes a range of",
      vq_money(t$ceiling - t$floor_if_none), "\n\n")

  cat("  of the upward movement:\n")
  cat("    from the COMMITTED queue      :", vq_money(t$dollars_up_committed), "\n")
  cat("    from the DERIVED sweep        :", vq_money(t$dollars_up_derived), "\n")
  cat("    of which FLOW ALREADY SETTLED :", vq_money(t$dollars_up_settled),
      " <- NOT a plausible outcome; see below\n")
  cat("  downward exposure (counted as hospital TODAY) :", vq_money(t$dollars_down), "\n\n")

  cat("  ", t$rows_only, " queue rows move a ROW COUNT and never a dollar (",
      t$rows_only_rows, " award rows). ", t$none, " move neither.\n", sep = "")
  cat("  contingent, outside the range above:", vq_money(t$contingent),
      "(Maine's invited cohort, if it is ever an award)\n\n")

  no_archive <- queue %>% dplyr::filter(is.na(archive_path) | archive_path == "")
  if (nrow(no_archive) > 0) {
    cat("EVIDENCE GAP -- ", nrow(no_archive), " queue rows carry NO archive path, ",
        "because their state file predates the column (",
        paste(sort(unique(no_archive$state)), collapse = ", "),
        "). A reviewer has the source_url and no local copy (spec 0.4).\n\n", sep = "")
  }

  cat("BY STATE\n")
  print(as.data.frame(t$by_state), row.names = FALSE)
  cat("\nBY QUESTION\n")
  print(as.data.frame(t$by_code), row.names = FALSE)

  cat("\nRECURRING ENTITIES --", nrow(rec), "matches,",
      sum(rec$match_tier == "EXACT"), "EXACT\n")
  print(as.data.frame(rec %>% dplyr::filter(match_tier == "EXACT") %>%
    dplyr::select(scope, open_state, open_name, open_dollars, open_award,
                  resolved_state, resolved_name, resolved_type, resolved_dth)),
    row.names = FALSE)
  cat("\n")
  invisible(t)
}

# =============================================================================
# WORKBOOK
# =============================================================================

vq_write_workbook <- function() {
  queue <- vq_build()
  t   <- vq_totals(queue)
  rec <- vq_recurring(queue, vq_rows())
  qcsv <- vq_read(VQ_QUEUE) %>% dplyr::filter(queue_status == "OPEN")

  wb <- openxlsx::createWorkbook()

  warning_sheet <- tibble::tibble(`READ THIS FIRST` = c(
    "THE CONSOLIDATED VERIFICATION QUEUE -- EVERY OPEN QUESTION, ONE STANDARD.",
    "",
    paste0("One row per (state, recipient organisation, question): ", t$queue_rows,
           " rows over ", t$award_rows, " underlying award rows, ",
           t$distinct_orgs, " distinct organisations, ", t$codes,
           " questions, ", t$states, " states."),
    "",
    "READ `queue_source` BEFORE QUOTING ANY TOTAL. It has two values:",
    "  COMMITTED_QUEUE          the question has a committed row in",
    "                           data/reference/classification_review_queue.csv.",
    "  DERIVED_FROM_STATE_FILE  the STATE FILE carries the flag and NOBODY EVER",
    "                           WROTE A QUEUE ROW. Iowa is the largest -- 102",
    "                           award rows, named in CLAUDE.md as the eighth",
    "                           instance of the unstated-form question and never",
    "                           queued. Same question, different provenance.",
    "",
    "THE BOUNDED RANGE THIS PASS CLOSES:",
    paste0("  named-hospital floor today               ", vq_money(t$floor_dollars),
           "   (", t$floor_rows, " rows, ", t$floor_states, " states)"),
    paste0("  if EVERY open row resolves to a hospital  ", vq_money(t$ceiling)),
    paste0("  if NO open row does                       ", vq_money(t$floor_if_none)),
    paste0("  the range is                              ",
           vq_money(t$ceiling - t$floor_if_none)),
    "",
    "THE CEILING IS A MECHANICAL UPPER BOUND, NOT A PLAUSIBLE OUTCOME. It is",
    "what the figure becomes if every recipient whose form its state never",
    "stated turns out to be a hospital. Several plainly are not.",
    paste0("  ", vq_money(t$dollars_up_settled), " of it sits on rows whose FLOW is",
           " separately SETTLED"),
    "  (New Hampshire's Foundation for Healthy Communities, Wyoming's Innovation",
    "  Partnership). Those are pass-throughs whose eligible class is hospitals",
    "  AMONG OTHERS -- spec 0.3 -- and no retyping moves them into the hospital",
    "  total. The column `flow_settled` marks them. Do not roll them in blindly.",
    "",
    paste0(t$rows_only, " queue rows move a ROW COUNT and NEVER A DOLLAR (",
           t$rows_only_rows, " award rows)."),
    "Iowa, Nevada, North Carolina, Missouri and Delaware publish named",
    "recipients and no per-recipient amount. For an unpriced state the row",
    "count is the only hospital quantity there is (Nevada's rule). A reviewer",
    "who works only the top of this sheet by dollars will never reach them.",
    "",
    paste0(t$none, " rows move neither dollars nor rows -- decide those on the spec."),
    "",
    paste0("MAINE'S ELEVEN INVITED HOSPITALS ARE ", vq_money(t$contingent),
           " AND ARE OUTSIDE THE RANGE."),
    "They are not an award today (DHHS invited them; its own advisory deck says",
    "the award amount 'will be confirmed after start of participation'), so",
    "their dollars_at_stake is $0 and the $30,000,000 sits in",
    "`contingent_dollars`. It is the single largest one-decision effect here.",
    "",
    "ARKANSAS RURAL HEALTH PARTNERSHIP APPEARS TWICE, UNDER TWO CODES, ON THE",
    "SAME TWO AWARD ROWS -- spec 8's typing and spec 10.2's flow. Its",
    "$18,833,521 is counted ONCE in every total above; `overlaps_with` says so.",
    "",
    paste0("EVIDENCE GAP: ", sum(is.na(queue$archive_path) | queue$archive_path == ""),
           " rows carry a source_url and NO LOCAL ARCHIVE, because their state"),
    "file predates the source_archive_path column (Florida, Indiana, Oregon).",
    "Every other path this workbook names was checked to exist on disk.",
    "",
    "THIS WORKBOOK WROTE NOTHING BACK. No state file was touched, nothing was",
    "re-coded, nothing was promoted (spec 0.4). verified_type, verified_by,",
    "verified_date and basis are EMPTY BY DESIGN -- they are yours.",
    "",
    "AND THE RECURRING-ENTITY SHEET FLAGS, IT DOES NOT RESOLVE. Spec 2 forbids",
    "a fuzzy hospital match auto-resolving. Every match prints both raw",
    "spellings side by side and carries a `match_tier`: EXACT, PREFIX, BRAND.",
    paste0("There are ", sum(rec$match_tier == "EXACT"), " EXACT matches. ",
           "TidalHealth is open in Maryland at $4,911,052 and is ALREADY CODED"),
    "a hospital in Delaware. Nebraska's Boone County Health Center and",
    "Gothenburg Health, and Wyoming's Powell Valley Health Care and Bighorn",
    "Valley Health Center, are the same shape INSIDE ONE STATE FILE. Those are",
    "free answers -- and they are still a human's to make, not a machine's."))

  openxlsx::addWorksheet(wb, "READ THIS FIRST")
  openxlsx::writeData(wb, "READ THIS FIRST", warning_sheet)
  openxlsx::setColWidths(wb, "READ THIS FIRST", 1, 100)

  openxlsx::addWorksheet(wb, "Verification queue")
  openxlsx::writeData(wb, "Verification queue", queue)
  openxlsx::freezePane(wb, "Verification queue", firstActiveRow = 2, firstActiveCol = 4)
  openxlsx::setColWidths(wb, "Verification queue", cols = 1:ncol(queue),
                         widths = c(9, 6, 46, 15, 15, 11, 34, 24, 11, 70, 30, 44, 30,
                                    46, 46, 28, 17, 13, 30, 16, 14, 14, 40))
  openxlsx::addStyle(wb, "Verification queue",
                     openxlsx::createStyle(textDecoration = "bold", wrapText = TRUE),
                     rows = 1, cols = 1:ncol(queue), gridExpand = TRUE)
  openxlsx::addStyle(wb, "Verification queue",
                     openxlsx::createStyle(numFmt = "#,##0"),
                     rows = 2:(nrow(queue) + 1), cols = c(4, 5, 17), gridExpand = TRUE)
  # the four empty columns a reviewer fills
  openxlsx::addStyle(wb, "Verification queue",
                     openxlsx::createStyle(fgFill = "#FFF4CE", border = "TopBottomLeftRight",
                                           borderColour = "#BBBBBB"),
                     rows = 2:(nrow(queue) + 1), cols = 20:23, gridExpand = TRUE)

  openxlsx::addWorksheet(wb, "Recurring entities")
  openxlsx::writeData(wb, "Recurring entities", rec)
  openxlsx::freezePane(wb, "Recurring entities", firstActiveRow = 2)
  openxlsx::setColWidths(wb, "Recurring entities", cols = 1:ncol(rec),
                         widths = c(11, 12, 58, 6, 46, 34, 15, 15, 30, 9, 46, 22, 8, 6, 28, 9))
  openxlsx::addStyle(wb, "Recurring entities",
                     openxlsx::createStyle(textDecoration = "bold", wrapText = TRUE),
                     rows = 1, cols = 1:ncol(rec), gridExpand = TRUE)

  totals <- tibble::tibble(
    measure = c("queue rows", "underlying award rows", "distinct organisations",
                "questions (queue codes)", "states",
                "dollars at stake (de-duplicated)",
                "named-hospital floor today (dollars)",
                "named-hospital floor today (rows)",
                "named-hospital floor today (states)",
                "CEILING -- every open row resolves to a hospital",
                "FLOOR -- no open row does",
                "the range this pass closes",
                "  upward, from the COMMITTED queue",
                "  upward, from the DERIVED sweep",
                "  upward, of which FLOW ALREADY SETTLED",
                "  downward exposure (hospital today, may come out)",
                "queue rows that move a ROW COUNT only",
                "  their underlying award rows",
                "queue rows that move neither",
                "contingent, OUTSIDE the range (Maine's invited cohort)"),
    value = c(t$queue_rows, t$award_rows, t$distinct_orgs, t$codes, t$states,
              t$dollars_total, t$floor_dollars, t$floor_rows, t$floor_states,
              t$ceiling, t$floor_if_none, t$ceiling - t$floor_if_none,
              t$dollars_up_committed, t$dollars_up_derived, t$dollars_up_settled,
              t$dollars_down, t$rows_only, t$rows_only_rows, t$none, t$contingent))

  openxlsx::addWorksheet(wb, "Totals")
  openxlsx::writeData(wb, "Totals", totals)
  openxlsx::setColWidths(wb, "Totals", cols = 1:2, widths = c(56, 20))
  openxlsx::addStyle(wb, "Totals", openxlsx::createStyle(numFmt = "#,##0"),
                     rows = 2:(nrow(totals) + 1), cols = 2, gridExpand = TRUE)

  openxlsx::addWorksheet(wb, "By state")
  openxlsx::writeData(wb, "By state", t$by_state)
  openxlsx::setColWidths(wb, "By state", cols = 1:5, widths = c(8, 12, 12, 18, 18))

  openxlsx::addWorksheet(wb, "By question")
  openxlsx::writeData(wb, "By question", t$by_code)
  openxlsx::setColWidths(wb, "By question", cols = 1:7, widths = c(40, 26, 12, 12, 12, 18, 18))

  openxlsx::addWorksheet(wb, "Committed queue (source)")
  openxlsx::writeData(wb, "Committed queue (source)", qcsv)
  openxlsx::setColWidths(wb, "Committed queue (source)", cols = 1:ncol(qcsv), widths = 30)

  dir.create(dirname(VQ_XLSX), showWarnings = FALSE, recursive = TRUE)
  openxlsx::saveWorkbook(wb, VQ_XLSX, overwrite = TRUE)
  message("[VQ] wrote ", VQ_XLSX, " -- ", nrow(queue), " queue rows, ",
          nrow(rec), " recurring-entity matches")
  invisible(VQ_XLSX)
}

# -- CLI ----------------------------------------------------------------------

# `sys.nframe() == 0L` is the repo's CLI guard: it is FALSE when the file is
# sourced by a test or another stage, so nothing here runs then.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--validate" %in% args) {
    vq_validate()
  } else if ("--report" %in% args) {
    vq_validate(); vq_report()
  } else if ("--build" %in% args) {
    vq_validate(); vq_write_workbook(); vq_report()
  } else {
    cat("usage: Rscript R/07_verification_queue.R [--build|--validate|--report]\n")
  }
}

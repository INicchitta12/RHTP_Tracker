# R/utils_spend_category.R -- the spend-category layer (session 116f)
#
# OWNER DIRECTION (session 116f). Consultants, data/tech vendors, programme
# administrators, non-provider intermediaries and out-of-state contractors are
# a STANDING spending category tracked beside hospital spending. Every award
# row (STATE_FILES) and every contract row (data/reference/contracts/) carries:
#
#   spend_category        HOSPITAL | CONSULTANT | DATA_TECH_VENDOR | ADMINISTRATOR
#                         | NON_PROVIDER_INTERMEDIARY | PROVIDER_PASS_THROUGH | OTHER
#   spend_category_basis  which rule decided it, in words
#   vendor_role           ADMINISTERS_PROGRAM | DELIVERS_TO_PROVIDERS | MIXED |
#                         UNKNOWN, from the source's own purpose text (vendor
#                         categories and PROVIDER_PASS_THROUGH only; else empty)
#   out_of_state          TRUE | FALSE on every non-hospital row; empty on a
#                         HOSPITAL row. The V6 registered-address rule: TRUE only
#                         where an FSRS record linked to the row (same UEI, same
#                         subaward number, or an equal normalised name in the
#                         same prime state) carries a state code that is not the
#                         awarding state, and no V9 ruling says the money funds
#                         the recipient's own in-state operations. FALSE means
#                         "not shown out of state", never "shown in state".
#   vendor_public         TRUE where the recipient is a public body (the NC ROOTS
#                         hub leads Trillium and Vaya, owner ruling)
#   vendor_verified       TRUE only where the row carries a session-116e case
#                         that passed V1-V9 AND its category is a vendor
#                         category. Only verified dollars enter vendor totals;
#                         every other vendor-category row is a LEAD.
#   vendor_verified_usd   the verified dollars on the row (the sum of its cases;
#                         a row that aggregates several FSRS subawards may carry
#                         less than its amount)
#   vendor_case_id        the 116e case(s) on the row, ";"-joined
#
# HOSPITAL IS DECIDED BY THE EXISTING LOGIC AND NOTHING ELSE. An award row is
# HOSPITAL exactly where R/07 calls it HOSPITAL (every strict bucket row is
# called HOSPITAL; the test proves it). This layer never writes
# recipient_type, flow_type, distributed_to_hospital, confidence,
# hospital_attribution or a summary call, so no hospital figure can move.
#
# HOSPITAL AND VENDOR CATEGORIES ARE MUTUALLY EXCLUSIVE, and the guard runs
# before any vendor rule: a row typed HOSPITAL_OR_SYSTEM or
# HOSPITAL_AFFILIATED_ENTITY, an academic health centre, or a hospital
# association / network / system parent (config/spend_category_entities.csv,
# hospital_affiliate = TRUE) is never a vendor category, whatever the
# dictionary says. Such a row that R/07 does not call HOSPITAL is
# PROVIDER_PASS_THROUGH where it passes money on and OTHER where it does not.
#
# PRECEDENCE (first rule that answers wins):
#   1 HOSPITAL        summary_hospital_call == HOSPITAL (award rows); a contract
#                     row typed HOSPITAL_OR_SYSTEM
#   2 hospital guard  -> PROVIDER_PASS_THROUGH or OTHER
#   3 116e case       config/spend_category_cases.csv (hand calls, each quoted)
#   4 V9 ruling       -> OTHER, out_of_state FALSE (Kinney, Spirit, Fond of You,
#                     Jefferson)
#   5 entity config   config/spend_category_entities.csv
#   6 dictionary      config/vendor_entity_dictionary.csv: CONSULTING_* ->
#                     CONSULTANT, TECH_VENDOR -> DATA_TECH_VENDOR; INSURER_MCO
#                     and OUT_OF_STATE_ORG are providers or plans -> OTHER
#   7 STATE_AGENCY    -> OTHER (V7: a state agency is never a vendor)
#   8 everything else -> OTHER
# No fuzzy matching anywhere: regex patterns a person wrote, and 116e cases
# matched on state + name + amount.

source(here::here("R", "09_vendor_flags.R"))

RHTP_SPEND_CATEGORIES <- c("HOSPITAL", "CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR",
                           "NON_PROVIDER_INTERMEDIARY", "PROVIDER_PASS_THROUGH", "OTHER")
RHTP_VENDOR_CATEGORIES <- c("CONSULTANT", "DATA_TECH_VENDOR", "ADMINISTRATOR",
                            "NON_PROVIDER_INTERMEDIARY")
RHTP_VENDOR_ROLES <- c("ADMINISTERS_PROGRAM", "DELIVERS_TO_PROVIDERS", "MIXED", "UNKNOWN")
RHTP_SPEND_COLUMNS <- c("spend_category", "spend_category_basis", "vendor_role", "out_of_state",
                        "vendor_public", "vendor_verified", "vendor_verified_usd", "vendor_case_id")
RHTP_SPEND_CASES <- "config/spend_category_cases.csv"
RHTP_SPEND_ENTITIES <- "config/spend_category_entities.csv"
RHTP_CONTRACT_DIR <- "data/reference/contracts"
RHTP_SPEND_AMOUNT_TYPES <- c("award", "intent", "contract maximum", "obligation", "unpriced")
RHTP_VV_LIST <- "data/reference/verified_vendor_list.csv"
RHTP_VV_PASS <- "data/reference/verified_vendor_pass_through.csv"
RHTP_HOSPITAL_TYPES <- c("HOSPITAL_OR_SYSTEM", "HOSPITAL_AFFILIATED_ENTITY")
RHTP_PASS_FLOWS <- c("PASS_THROUGH_DESIGNATED", "PASS_THROUGH_UNRESOLVED")

# The 116e dictionary classes, mapped once.
RHTP_DICT_TO_SPEND <- c(CONSULTING_BIG = "CONSULTANT", CONSULTING_OTHER = "CONSULTANT",
                        TECH_VENDOR = "DATA_TECH_VENDOR", INSURER_MCO = "OTHER",
                        OUT_OF_STATE_ORG = "OTHER")

rhtp_spend_norm <- function(x) toupper(gsub("[^A-Za-z0-9]", "", dplyr::coalesce(x, "")))

rhtp_spend_cases <- function() {
  m <- readr::read_csv(here::here(RHTP_SPEND_CASES), col_types = readr::cols(.default = "c"),
                       progress = FALSE, na = "")
  stopifnot(!anyDuplicated(m$case_id), all(m$spend_category %in% RHTP_SPEND_CATEGORIES),
            all(m$vendor_role %in% RHTP_VENDOR_ROLES), all(m$vendor_public %in% c("TRUE", "FALSE")),
            all(nzchar(m$role_basis)))
  rd <- function(p, tab) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                         progress = FALSE, na = "") %>%
    dplyr::transmute(case_id, state, recipient_as_printed, amount = as.numeric(amount), amount_type,
                     categories, tab = tab)
  v <- dplyr::bind_rows(rd(RHTP_VV_LIST, "main"), rd(RHTP_VV_PASS, "pass_through"))
  miss <- setdiff(v$case_id, m$case_id)
  if (length(miss)) stop("[spend] verified 116e cases with no call in ", RHTP_SPEND_CASES, ": ",
                         paste(miss, collapse = ", "), call. = FALSE)
  extra <- setdiff(m$case_id, v$case_id)
  if (length(extra)) stop("[spend] calls for cases that are not on a verified 116e tab: ",
                          paste(extra, collapse = ", "), call. = FALSE)
  v %>% dplyr::inner_join(m, by = "case_id") %>%
    dplyr::mutate(case_out_of_state = grepl("OUT_OF_STATE_VENDOR", categories, fixed = TRUE))
}

rhtp_spend_entities <- function() {
  e <- readr::read_csv(here::here(RHTP_SPEND_ENTITIES), col_types = readr::cols(.default = "c"),
                       progress = FALSE, na = "")
  stopifnot(all(e$spend_category %in% RHTP_SPEND_CATEGORIES), all(e$hospital_affiliate %in% c("TRUE", "FALSE")),
            all(nzchar(e$basis)), !any(e$spend_category[e$hospital_affiliate == "TRUE"] %in% RHTP_VENDOR_CATEGORIES))
  for (p in e$pattern) stringr::str_detect("x", stringr::regex(p, ignore_case = TRUE))
  e
}

#' The first entity-config row each name matches (NA where none)
rhtp_spend_entity_match <- function(names, ent = rhtp_spend_entities()) {
  idx <- rep(NA_integer_, length(names))
  for (i in rev(seq_len(nrow(ent)))) {
    hit <- stringr::str_detect(dplyr::coalesce(names, ""), stringr::regex(ent$pattern[i], ignore_case = TRUE))
    idx[hit] <- i
  }
  idx
}

# V9 rulings (session 116e): an out-of-state organisation whose source says
# the money funds its own in-state operations. Never a vendor, never out of state.
RHTP_V9_RX <- "Kinney Drugs|KPH Healthcare|Spirit Medical Transport|Fond of You|Thomas Jefferson University"
# FSRS addresses session 116b doubted (VF_FSRS_REVIEWED_EXCLUSIONS): never out of state.
RHTP_ADDRESS_DOUBTED <- "VERMONT ALLIANCE FOR RECOVERY RESIDENCES"

#' The FSRS subawards, one row per record, for the V6 link
rhtp_spend_fsrs <- function() {
  s <- usa_read("sub")
  tibble::tibble(
    prime_state = dplyr::if_else(s$prime_awardee_state_code == "",
                                 s$prime_award_primary_place_of_performance_state_code,
                                 s$prime_awardee_state_code),
    subaward_number = s$subaward_number, uei = s$subawardee_uei,
    key = rhtp_spend_norm(s$subawardee_name), sub_state = s$subawardee_state_code)
}

#' V6: is each row's recipient registered outside the awarding state?
rhtp_spend_out_of_state <- function(state, awardee, fsrs_uei, fsrs_subaward_number, fsrs) {
  key <- rhtp_spend_norm(awardee)
  vapply(seq_along(state), function(i) {
    f <- fsrs[fsrs$prime_state == state[i], , drop = FALSE]
    u <- dplyr::coalesce(fsrs_uei[i], "")
    sn <- dplyr::coalesce(fsrs_subaward_number[i], "")
    hit <- f[(nzchar(u) & f$uei == u) |
               (nzchar(sn) & f$subaward_number %in% trimws(strsplit(sn, ";", fixed = TRUE)[[1]])) |
               (nzchar(key[i]) & f$key == key[i]), , drop = FALSE]
    st <- unique(hit$sub_state[nzchar(hit$sub_state)])
    length(st) > 0 && !state[i] %in% st
  }, logical(1))
}

#' Assign each verified 116e case to exactly one row. Returns a tibble
#' (row index, case_id) and the cases that reach no row.
#'
#' A case matches a row of the same state whose normalised name shares the
#' case's first twelve characters (all of them where the case's is shorter), at the same amount (or the same FSRS amount).
#' Where none matches at the amount, the one row of that state and name whose
#' amount exceeds the case's carries it (an award file that sums several FSRS
#' subawards to one recipient: Trillium, VHCF, VHHA Foundation).
rhtp_spend_assign_cases <- function(rows, cases) {
  key <- rhtp_spend_norm(rows$awardee)
  taken <- rep(FALSE, nrow(rows))
  out <- list(); none <- character(0)
  for (i in seq_len(nrow(cases))) {
    c <- cases[i, ]; ck <- rhtp_spend_norm(c$recipient_as_printed)
    L <- min(12L, nchar(ck))
    want_kind <- if (c$amount_type == "contract maximum") "contract" else "award"
    same <- which(rows$state == c$state & substr(key, 1, L) == substr(ck, 1, L))
    at <- same[(!is.na(rows$amount[same]) & abs(rows$amount[same] - c$amount) < 0.01) |
                 (!is.na(rows$fsrs_amount[same]) & abs(rows$fsrs_amount[same] - c$amount) < 0.01)]
    if (length(at) > 1) {
      # one case to one row: the source's own kind first, then a row no case
      # has taken yet (Utah's two $2,000,000 Comagine intents are two rows)
      at <- at[order(rows$kind[at] != want_kind, taken[at])][1]
    }
    if (length(at) == 0) {
      big <- same[!is.na(rows$amount[same]) & rows$amount[same] > c$amount]
      if (length(big) == 1) at <- big
    }
    if (length(at) == 1) {
      taken[at] <- TRUE
      out[[length(out) + 1]] <- tibble::tibble(i = at, case_id = c$case_id)
    } else {
      none <- c(none, c$case_id)
    }
  }
  list(assigned = dplyr::bind_rows(out), unassigned = none)
}

#' THE ONE FUNCTION. Classify a set of rows.
#'
#' @param rows tibble with columns: state, awardee, amount (numeric),
#'   recipient_type, flow_type, summary_hospital_call (NA for contract rows),
#'   recipient_subtype, purpose, fsrs_uei, fsrs_subaward_number, fsrs_amount,
#'   kind ("award" | "contract").
#' @return the rows with the eight RHTP_SPEND_COLUMNS added (character/logical
#'   values as they will be written), and attr "unassigned_cases".
rhtp_spend_category <- function(rows, cases = rhtp_spend_cases(), ent = rhtp_spend_entities(),
                                dict = vf_dictionary(), fsrs = rhtp_spend_fsrs()) {
  n <- nrow(rows)
  cat_ <- rep(NA_character_, n); basis <- rep(NA_character_, n)
  role <- rep(NA_character_, n); public <- rep(FALSE, n)
  case_id <- rep(NA_character_, n); ver_usd <- rep(0, n)
  set <- function(w, c, b) {
    w <- w & is.na(cat_)
    if (length(c) == n && n > 1) c <- c[w]
    if (length(b) == n && n > 1) b <- b[w]
    cat_[w] <<- c; basis[w] <<- b
    w
  }

  # 1 HOSPITAL
  hosp <- (rows$kind == "award" & rows$summary_hospital_call %in% "HOSPITAL") |
    (rows$kind == "contract" & rows$recipient_type %in% "HOSPITAL_OR_SYSTEM")
  set(hosp, "HOSPITAL", ifelse(rows$kind == "award",
                               "R/07 summary call HOSPITAL (the existing hospital logic, unchanged)",
                               "contract row typed HOSPITAL_OR_SYSTEM; a contract row never counts toward the hospital share"))

  # 2 hospital guard
  eidx <- rhtp_spend_entity_match(rows$awardee, ent)
  affiliate <- !is.na(eidx) & ent$hospital_affiliate[pmax(eidx, 1L)] == "TRUE"
  hosp_typed <- rows$recipient_type %in% RHTP_HOSPITAL_TYPES |
    rows$recipient_subtype %in% "ACADEMIC_HEALTH_CENTER" | affiliate
  passes <- rows$flow_type %in% RHTP_PASS_FLOWS | (is.na(rows$flow_type) & affiliate)
  set(hosp_typed & passes, "PROVIDER_PASS_THROUGH",
      paste0("Hospital ruling: a hospital-typed recipient, academic health centre, or hospital association/network ",
             "that R/07 does not call HOSPITAL and that passes money on; never a vendor category. ",
             ifelse(affiliate, ent$basis[pmax(eidx, 1L)], "")))
  set(hosp_typed & !passes, "OTHER",
      paste0("Hospital ruling: a hospital-typed recipient, academic health centre, or hospital association/network ",
             "that R/07 does not call HOSPITAL and whose row passes nothing on (in-kind or own costs); never a vendor category. ",
             ifelse(affiliate, ent$basis[pmax(eidx, 1L)], "")))
  guarded <- hosp | hosp_typed

  # 3 the 116e cases (assignment runs on every row, so a guarded or hospital
  # row records its case id without taking a vendor category)
  a <- rhtp_spend_assign_cases(rows, cases)
  if (nrow(a$assigned)) {
    for (j in seq_len(nrow(a$assigned))) {
      i <- a$assigned$i[j]; c <- cases[cases$case_id == a$assigned$case_id[j], ]
      case_id[i] <- if (is.na(case_id[i])) c$case_id else paste(case_id[i], c$case_id, sep = ";")
      if (!guarded[i]) {
        if (c$spend_category == "HOSPITAL") {
          stop("[spend] case ", c$case_id, " is called HOSPITAL but its row is not: ", rows$state[i], " ",
               rows$awardee[i], call. = FALSE)
        }
        if (is.na(cat_[i])) {
          cat_[i] <- c$spend_category
          basis[i] <- paste0("Session 116e case ", c$case_id, " (", c$tab, " tab, passed V1-V9): ", c$role_basis)
          role[i] <- c$vendor_role
        } else if (cat_[i] != c$spend_category) {
          stop("[spend] one row carries 116e cases of different categories: ", rows$state[i], " ",
               rows$awardee[i], call. = FALSE)
        }
        public[i] <- public[i] | c$vendor_public == "TRUE"
        if (c$spend_category %in% RHTP_VENDOR_CATEGORIES) ver_usd[i] <- ver_usd[i] + c$amount
      } else if (c$spend_category %in% RHTP_VENDOR_CATEGORIES) {
        stop("[spend] case ", c$case_id, " is a vendor category on a hospital-coded row: ",
             rows$state[i], " ", rows$awardee[i], call. = FALSE)
      } else if (is.na(role[i])) {
        role[i] <- c$vendor_role
      }
    }
  }

  # 4 V9
  v9 <- grepl(RHTP_V9_RX, rows$awardee, ignore.case = TRUE)
  set(v9, "OTHER", "Session 116e V9 ruling: the money funds the organisation's own in-state operations; not a vendor, not out of state")

  # 5 entity config (non-affiliate rows)
  ew <- !is.na(eidx) & !affiliate
  set(ew, ifelse(ew, ent$spend_category[pmax(eidx, 1L)], NA_character_),
      paste0("config/spend_category_entities.csv: ", ifelse(ew, ent$basis[pmax(eidx, 1L)], "")))

  # 6 the dictionary
  m <- vf_match(rows$awardee, dict)
  dw <- m$matched
  set(dw, ifelse(dw, RHTP_DICT_TO_SPEND[m$entity_class], NA_character_),
      paste0("config/vendor_entity_dictionary.csv: ", m$canonical_name, " (", m$entity_class, ")"))

  # 7, 8
  set(rows$recipient_type %in% "STATE_AGENCY", "OTHER", "A state agency of the awarding state (V7): never a vendor")
  set(rep(TRUE, n), "OTHER", "No hospital call, no 116e case, no dictionary or entity-config entry")

  # vendor_role for vendor categories and pass-through rows with no case role
  needs_role <- cat_ %in% c(RHTP_VENDOR_CATEGORIES, "PROVIDER_PASS_THROUGH") & is.na(role)
  role[needs_role] <- vf_role_from_text(rows$purpose[needs_role])
  role[!cat_ %in% c(RHTP_VENDOR_CATEGORIES, "PROVIDER_PASS_THROUGH")] <- NA_character_

  # out_of_state (V6) on non-hospital rows
  oos <- rhtp_spend_out_of_state(rows$state, rows$awardee, rows$fsrs_uei, rows$fsrs_subaward_number, fsrs)
  case_oos <- vapply(case_id, function(x) {
    if (is.na(x)) return(NA)
    any(cases$case_out_of_state[cases$case_id %in% strsplit(x, ";", fixed = TRUE)[[1]]])
  }, logical(1))
  oos <- ifelse(is.na(case_oos), oos, case_oos | oos)
  oos[v9 | grepl(RHTP_ADDRESS_DOUBTED, rows$awardee, ignore.case = TRUE)] <- FALSE
  oos_out <- ifelse(cat_ == "HOSPITAL", NA, oos)

  verified <- cat_ %in% RHTP_VENDOR_CATEGORIES & ver_usd > 0
  ver_usd[!verified] <- 0

  out <- rows
  out$spend_category <- cat_
  out$spend_category_basis <- basis
  out$vendor_role <- role
  out$out_of_state <- oos_out
  out$vendor_public <- public
  out$vendor_verified <- verified
  out$vendor_verified_usd <- ver_usd
  out$vendor_case_id <- case_id
  attr(out, "unassigned_cases") <- a$unassigned
  out
}

# -- reading and writing the award and contract files ---------------------------

rhtp_spend_col <- function(d, col) if (col %in% names(d)) as.character(d[[col]]) else rep(NA_character_, nrow(d))

RHTP_SPEND_PURPOSE_COLUMNS <- c("description", "purpose", "project_title", "project", "sub_initiative",
                                "award_pool", "initiative", "activity_type_raw", "list_section", "note")

#' The classifier's input columns from one file (all character, na = "")
rhtp_spend_input <- function(d, kind) {
  na <- function(x) dplyr::na_if(x, "")
  purpose <- rep(NA_character_, nrow(d))
  for (pc in RHTP_SPEND_PURPOSE_COLUMNS) {
    v <- na(rhtp_spend_col(d, pc))
    purpose[is.na(purpose)] <- v[is.na(purpose)]
  }
  tibble::tibble(
    state = d$state, awardee = d$awardee,
    amount = suppressWarnings(as.numeric(na(rhtp_spend_col(d, "amount")))),
    recipient_type = na(rhtp_spend_col(d, "recipient_type")),
    flow_type = na(rhtp_spend_col(d, "flow_type")),
    summary_hospital_call = na(rhtp_spend_col(d, "summary_hospital_call")),
    recipient_subtype = na(rhtp_spend_col(d, "recipient_subtype")),
    purpose = purpose,
    fsrs_uei = na(rhtp_spend_col(d, "fsrs_uei")),
    fsrs_subaward_number = na(dplyr::coalesce(na(rhtp_spend_col(d, "fsrs_subaward_number")),
                                              na(rhtp_spend_col(d, "fsrs_subaward_ids")))),
    fsrs_amount = suppressWarnings(as.numeric(na(rhtp_spend_col(d, "fsrs_amount")))),
    kind = kind)
}

#' The contract files (Task 3): every CSV in data/reference/contracts/
rhtp_contract_files <- function() {
  f <- list.files(here::here(RHTP_CONTRACT_DIR), "\\.csv$")
  stats::setNames(file.path(RHTP_CONTRACT_DIR, f), toupper(sub("_contracts\\.csv$", "", f)))
}

rhtp_spend_fmt <- function(out) {
  tibble::tibble(
    spend_category = out$spend_category,
    spend_category_basis = out$spend_category_basis,
    vendor_role = dplyr::coalesce(out$vendor_role, ""),
    out_of_state = ifelse(is.na(out$out_of_state), "", ifelse(out$out_of_state, "TRUE", "FALSE")),
    vendor_public = ifelse(out$vendor_public, "TRUE", "FALSE"),
    vendor_verified = ifelse(out$vendor_verified, "TRUE", "FALSE"),
    vendor_verified_usd = ifelse(out$vendor_verified_usd > 0, format(out$vendor_verified_usd, scientific = FALSE, trim = TRUE, nsmall = 2), "0"),
    vendor_case_id = dplyr::coalesce(out$vendor_case_id, ""))
}

#' Compute the columns for every award file and every contract file at once
#' (a 116e case must land on exactly one row ACROSS all of them).
rhtp_spend_compute <- function(award_files, contract_files = rhtp_contract_files()) {
  read <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                      na = character(), progress = FALSE, trim_ws = FALSE)
  files <- c(award_files, contract_files)
  kinds <- c(rep("award", length(award_files)), rep("contract", length(contract_files)))
  ds <- lapply(files, read)
  inp <- dplyr::bind_rows(lapply(seq_along(ds), function(i) {
    x <- rhtp_spend_input(ds[[i]], kinds[i]); x$file <- unname(files[i]); x$row <- seq_len(nrow(x)); x
  }))
  out <- rhtp_spend_category(inp)
  f <- rhtp_spend_fmt(out)
  list(files = files, data = ds, cols = split(f, factor(inp$file, levels = unname(files))),
       rows = dplyr::bind_cols(inp, out[, RHTP_SPEND_COLUMNS] %>% dplyr::rename_with(~ paste0(.x, "_v"))),
       unassigned = attr(out, "unassigned_cases"))
}

#' Write the columns (R/07 --apply runs this LAST, after the summary calls)
rhtp_spend_apply <- function(award_files) {
  r <- rhtp_spend_compute(award_files)
  for (i in seq_along(r$files)) {
    d <- r$data[[i]]; cl <- r$cols[[i]]
    if (nrow(d) != nrow(cl)) stop("[spend] row count changed: ", r$files[i], call. = FALSE)
    for (col in RHTP_SPEND_COLUMNS) d[[col]] <- cl[[col]]
    readr::write_csv(d, here::here(r$files[i]), na = "")
  }
  message("[spend] wrote ", length(RHTP_SPEND_COLUMNS), " columns to ", length(r$files), " files; ",
          sum(r$rows$vendor_verified_v), " verified vendor rows; unassigned 116e cases: ",
          if (length(r$unassigned)) paste(r$unassigned, collapse = ", ") else "none")
  invisible(r)
}

#' Refuse a file whose committed columns differ from the computed ones
rhtp_spend_validate <- function(award_files) {
  r <- rhtp_spend_compute(award_files)
  for (i in seq_along(r$files)) {
    d <- r$data[[i]]; cl <- r$cols[[i]]
    for (col in RHTP_SPEND_COLUMNS) {
      if (!col %in% names(d) || !identical(d[[col]], cl[[col]])) {
        stop("[spend] ", r$files[i], ": committed ", col, " differs from the computed layer. ",
             "Re-run Rscript R/07_summary_calls.R --apply.", call. = FALSE)
      }
    }
  }
  invisible(r)
}

#' Every committed row, award and contract, with the layer's columns (for R/08
#' and R/09c). Reads the committed files; computes nothing.
rhtp_spend_rows <- function(award_files) {
  read <- function(p) readr::read_csv(here::here(p), col_types = readr::cols(.default = "c"),
                                      progress = FALSE, na = c("", "NA"))
  one <- function(p, k, kind) {
    d <- read(p)
    if (!all(RHTP_SPEND_COLUMNS %in% names(d))) {
      stop("[spend] ", p, " has no spend-category columns. Re-run Rscript R/07_summary_calls.R --apply.",
           call. = FALSE)
    }
    if (kind == "award") d <- rhtp_year1_only(d, p)
    o <- function(c) rhtp_spend_col(d, c)
    tibble::tibble(file_key = k, file = p, kind = kind, state = d$state, awardee = d$awardee,
                   amount = suppressWarnings(as.numeric(d$amount)),
                   amount_type = o("amount_type"),
                   validation_source_type = o("validation_source_type"),
                   summary_hospital_call = o("summary_hospital_call"),
                   purpose = o("purpose"), source_url = dplyr::coalesce(o("state_source_url"), o("source_url")),
                   source_archive_path = o("source_archive_path"),
                   also_in_award_file = o("also_in_award_file"),
                   spend_category = d$spend_category, spend_category_basis = d$spend_category_basis,
                   vendor_role = d$vendor_role, out_of_state = d$out_of_state == "TRUE",
                   vendor_public = d$vendor_public == "TRUE", vendor_verified = d$vendor_verified == "TRUE",
                   vendor_verified_usd = as.numeric(d$vendor_verified_usd), vendor_case_id = d$vendor_case_id)
  }
  cf <- rhtp_contract_files()
  dplyr::bind_rows(
    purrr::map_dfr(names(award_files), function(k) one(award_files[[k]], k, "award")),
    purrr::map_dfr(names(cf), function(k) one(cf[[k]], k, "contract"))) %>%
    dplyr::mutate(amount_type = dplyr::case_when(
      kind == "contract" ~ amount_type,
      is.na(amount) ~ "unpriced",
      validation_source_type %in% "CMS_OBLIGATION_REPORT" ~ "obligation",
      file_key == "SD_CONTRACTS" ~ "contract maximum",
      validation_source_type %in% "NOTICE_OF_INTENT_TO_AWARD" ~ "intent",
      TRUE ~ "award"))
}

# -- CMS's unnamed contractor lines (session 116f, Task 4) -------------------------
#
# A CMS obligation line that says money went to "contractors", "consultants", a
# "grant management vendor" or a "fiscal agent" without naming one is CONTEXT,
# never vendor dollars (no firm, so no V5). It is split in two:
#   CONTRACTOR_ONLY  the line funds contractors alone
#   MIXED            the line also covers state staff, state agencies or the
#                    state's own administrative infrastructure (NH's
#                    "staffing, financial management ... administrative
#                    infrastructure"; KS's "state agencies, contractors, and
#                    consultants"), or contractors are a secondary clause after
#                    a first sentence about something else (MO's pharmacy line)
# AUTOMATIC ON A NEW EDITION: the lines are read from the NEWEST parsed edition,
# data/reference/cms_obligations_bp1_lines_<yyyymmdd>.csv (R/00c / R/00e write
# it). The day a new edition is parsed, R/08 --build re-splits it with no edit.
RHTP_MIXED_RX <- stringr::regex(paste0(
  "state agenc|(?<!consultant )staffing|\\bstaff\\b|personnel|salar|\\bFTEs?\\b|",
  "deputy director|financial management|administrative infrastructure|state employees"),
  ignore_case = TRUE)

rhtp_cms_lines_editions <- function() {
  f <- list.files(here::here("data", "reference"), "^cms_obligations_bp1_lines_[0-9]{8}\\.csv$")
  f[order(sub("^cms_obligations_bp1_lines_([0-9]{8})\\.csv$", "\\1", f))]
}

#' The unnamed contractor lines of one edition (default: the newest), split
rhtp_unnamed_contractor_lines <- function(edition_file = utils::tail(rhtp_cms_lines_editions(), 1)) {
  if (!length(edition_file)) stop("[spend] no parsed CMS obligation edition", call. = FALSE)
  l <- readr::read_csv(here::here("data", "reference", edition_file), col_types = readr::cols(.default = "c"),
                       progress = FALSE)
  l <- l %>% dplyr::filter(is.na(named_orgs) | named_orgs == "") %>%
    dplyr::mutate(amount = as.numeric(amount)) %>%
    dplyr::filter(stringr::str_detect(description_clean, VF_UNNAMED_RX),
                  !stringr::str_detect(description_clean, VF_UNNAMED_NOT_RX), amount > 0)
  first <- sub("^(.*?\\.)(\\s|$).*$", "\\1", l$description_clean, perl = TRUE)
  mixed_why <- dplyr::case_when(
    stringr::str_detect(l$description_clean, RHTP_MIXED_RX) ~ "also covers state staff, agencies or administrative infrastructure",
    !stringr::str_detect(first, VF_UNNAMED_RX) ~ "contractors are a secondary clause after a first sentence about other spending",
    TRUE ~ NA_character_)
  l %>% dplyr::transmute(
    edition = sub("^cms_obligations_bp1_lines_([0-9]{8})\\.csv$", "\\1", edition_file),
    state, line_id, amount_obligated = amount,
    split = ifelse(is.na(mixed_why), "CONTRACTOR_ONLY", "MIXED"),
    split_basis = dplyr::coalesce(mixed_why, "the line funds contractors only"),
    quote = description_clean, initiative, as_of) %>%
    dplyr::arrange(state, dplyr::desc(amount_obligated))
}

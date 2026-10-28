# R/utils_summary_calls.R -- the summary-call layer (session 110)
#
# THE YEAR 1 SUMMARY TABLE MAY CARRY NO UNKNOWN OR UNCLEAR HOSPITAL STATUS
# (owner instruction, session 110). Every award row therefore gets a
# two-valued call, HOSPITAL or NOT_HOSPITAL, in three columns appended to its
# award file:
#
#   summary_hospital_call    HOSPITAL | NOT_HOSPITAL, nothing else
#   summary_call_basis       CODED | BEST_JUDGMENT
#   summary_call_rationale   one sentence; required when BEST_JUDGMENT
#
# THE STRICT CODING IS NOT CHANGED, AND THAT IS THE POINT OF A SEPARATE LAYER.
# recipient_type, flow_type, distributed_to_hospital, determination_confidence
# and hospital_attribution are never touched here, so
# rhtp_hospital_dollar_partition() returns exactly what it returned before.
# A BEST_JUDGMENT call is a reading a reviewer can disagree with, and the
# summary table reports it as its own column so it can be subtracted whole.
#
# CODED means the row's existing determination carries over: Yes -> HOSPITAL,
# No -> NOT_HOSPITAL. BEST_JUDGMENT is required wherever that determination is
# not settled: an Unclear or missing distributed_to_hospital, a
# PASS_THROUGH_UNRESOLVED flow, an unnamed recipient (NOT_YET_NAMED), a form
# the source never states (RECIPIENT_TYPE_INFERRED), a joint or shared award
# (one amount, several recipients), or a row an OPEN review-queue question
# names. A shared award is called on its lead or majority recipient and its
# dollars are never split.
#
# Every function here is pure apart from rhtp_summary_write(), which appends or
# replaces the three columns and leaves every other byte of the file as it was
# (all 58 award files round-trip byte-identically through the read it uses;
# session 110 checked each).

RHTP_SUMMARY_CALL_VALUES  <- c("HOSPITAL", "NOT_HOSPITAL")
RHTP_SUMMARY_BASIS_VALUES <- c("CODED", "BEST_JUDGMENT")
RHTP_SUMMARY_COLUMNS <- c("summary_hospital_call", "summary_call_basis",
                          "summary_call_rationale")

#' Hospital-shaped words in a recipient string. A row on §8's standing
#' fallback whose name carries one of these is never called by the default
#' rule: it needs a written judgment.
RHTP_SUMMARY_HOSPITAL_MARKER <- paste0(
  "hospital|medical cent(er|re)|health ?care system|health system|",
  "regional medical|memorial|health services district|health cent(er|re)")

rhtp_summary_col <- function(d, col) {
  if (col %in% names(d)) as.character(d[[col]]) else rep(NA_character_, nrow(d))
}

#' Why a row cannot carry its strict determination over (";"-joined), or "".
#'
#' @param open_rows logical vector, TRUE where an OPEN review-queue question
#'   names the row (computed by the caller from the queue).
rhtp_summary_reasons <- function(d, open_rows = rep(FALSE, nrow(d))) {
  dth  <- rhtp_summary_col(d, "distributed_to_hospital")
  flow <- rhtp_summary_col(d, "flow_type")
  rt   <- rhtp_summary_col(d, "recipient_type")
  fl   <- rhtp_summary_col(d, "flag_reason")
  att  <- rhtp_summary_col(d, "hospital_attribution")
  has_flag <- function(code) !is.na(fl) & grepl(paste0("(^|;)", code, "(;|$)"), fl)
  parts <- cbind(
    UNCLEAR = is.na(dth) | !dth %in% c("Yes", "No"),
    PASS_THROUGH_UNRESOLVED = !is.na(flow) & flow == "PASS_THROUGH_UNRESOLVED",
    NOT_YET_NAMED = !is.na(rt) & rt == "NOT_YET_NAMED",
    FORM_INFERRED = has_flag("RECIPIENT_TYPE_INFERRED"),
    SHARED_AWARD = has_flag("MULTI_RECIPIENT_FIELD") |
      (!is.na(att) & att == "POOL_NAMED_HOSPITALS"),
    OPEN_QUEUE = open_rows)
  apply(parts, 1, function(r) paste(colnames(parts)[r], collapse = ";"))
}

#' The calls for one award file
#'
#' @param d the award file, all columns character.
#' @param judgments rows of the written judgment table for THIS file: columns
#'   `awardee` (exact), `row_no` (NA = every row with that awardee), `call`,
#'   `rationale`.
#' @param open_rows see rhtp_summary_reasons().
#' @param default_rationale function(awardee) giving the sentence for a row
#'   whose ONLY reason is FORM_INFERRED, whose name carries no hospital marker
#'   and which the caller has checked against the state's CMS hospital
#'   enrolment; NULL disables the default (every judged row then needs a
#'   written judgment).
#' @return a tibble with the three summary columns plus `reasons` and
#'   `judgment_source` (WRITTEN, DEFAULT_FORM_INFERRED or NA for CODED).
rhtp_summary_calls <- function(d, judgments, open_rows = rep(FALSE, nrow(d)),
                               default_rationale = NULL, label = "") {
  dth <- rhtp_summary_col(d, "distributed_to_hospital")
  reasons <- rhtp_summary_reasons(d, open_rows)
  call <- rep(NA_character_, nrow(d)); basis <- call; why <- call; src <- call
  row_no <- rhtp_summary_col(d, "row_no")
  for (i in seq_len(nrow(d))) {
    if (!nzchar(reasons[i])) {
      call[i] <- if (dth[i] == "Yes") "HOSPITAL" else "NOT_HOSPITAL"
      basis[i] <- "CODED"
      next
    }
    j <- judgments[judgments$awardee == d$awardee[i] &
                     (is.na(judgments$row_no) | judgments$row_no == row_no[i]), ]
    if (nrow(j) > 1L) {
      stop("[summary calls] ", label, " row ", row_no[i], " ('", d$awardee[i],
           "') matches ", nrow(j), " written judgments.", call. = FALSE)
    }
    if (nrow(j) == 1L) {
      call[i] <- j$call; why[i] <- j$rationale; src[i] <- "WRITTEN"
    } else if (identical(reasons[i], "FORM_INFERRED") && dth[i] == "No" &&
               !is.null(default_rationale) &&
               !grepl(RHTP_SUMMARY_HOSPITAL_MARKER, d$awardee[i], ignore.case = TRUE)) {
      call[i] <- "NOT_HOSPITAL"; why[i] <- default_rationale(d$awardee[i])
      src[i] <- "DEFAULT_FORM_INFERRED"
    } else {
      stop("[summary calls] ", label, " row ", row_no[i], " ('", d$awardee[i],
           "') needs a written judgment (", reasons[i], ").", call. = FALSE)
    }
    basis[i] <- "BEST_JUDGMENT"
  }
  out <- tibble::tibble(summary_hospital_call = call, summary_call_basis = basis,
                        summary_call_rationale = why, reasons = reasons,
                        judgment_source = src)
  rhtp_assert_summary_calls(dplyr::bind_cols(d[, setdiff(names(d), names(out)), drop = FALSE],
                                             out[, RHTP_SUMMARY_COLUMNS]), label)
  out
}

#' The invariants every award file's summary columns must hold
rhtp_assert_summary_calls <- function(d, label = "") {
  miss <- setdiff(RHTP_SUMMARY_COLUMNS, names(d))
  if (length(miss)) {
    stop("[summary calls] ", label, " lacks ", paste(miss, collapse = ", "),
         ". Re-run Rscript R/07_summary_calls.R --apply after any --build.", call. = FALSE)
  }
  call <- as.character(d$summary_hospital_call)
  basis <- as.character(d$summary_call_basis)
  why <- as.character(d$summary_call_rationale)
  if (any(is.na(call) | !call %in% RHTP_SUMMARY_CALL_VALUES)) {
    stop("[summary calls] ", label, ": summary_hospital_call must be HOSPITAL or ",
         "NOT_HOSPITAL on every row.", call. = FALSE)
  }
  if (any(is.na(basis) | !basis %in% RHTP_SUMMARY_BASIS_VALUES)) {
    stop("[summary calls] ", label, ": summary_call_basis must be CODED or ",
         "BEST_JUDGMENT on every row.", call. = FALSE)
  }
  bj <- basis == "BEST_JUDGMENT"
  if (any(bj & (is.na(why) | !nzchar(trimws(why))))) {
    stop("[summary calls] ", label, ": a BEST_JUDGMENT row has no rationale.", call. = FALSE)
  }
  dth <- as.character(d$distributed_to_hospital)
  coded <- basis == "CODED"
  if (any(coded & !dth %in% c("Yes", "No"))) {
    stop("[summary calls] ", label, ": a CODED row has no settled determination.", call. = FALSE)
  }
  if (any(coded & ((dth == "Yes") != (call == "HOSPITAL")))) {
    stop("[summary calls] ", label, ": a CODED call disagrees with the strict ",
         "determination.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Read an award file exactly as written (every column character, nothing
#' turned into NA), so a write-back leaves its other bytes untouched.
rhtp_summary_read <- function(path) {
  readr::read_csv(path, col_types = readr::cols(.default = "c"), na = character(),
                  progress = FALSE, trim_ws = FALSE)
}

#' Append (or replace) the three columns and write the file back.
rhtp_summary_write <- function(path, calls) {
  d <- rhtp_summary_read(path)
  if (nrow(d) != nrow(calls)) stop("[summary calls] row count changed: ", path, call. = FALSE)
  for (col in RHTP_SUMMARY_COLUMNS) {
    v <- calls[[col]]
    d[[col]] <- ifelse(is.na(v), "", v)
  }
  readr::write_csv(d, path, na = "")
  invisible(d)
}

#' An award file without the summary columns, for tests that compare a
#' committed file with what its extractor builds.
rhtp_strip_summary_calls <- function(d) {
  d[, setdiff(names(d), RHTP_SUMMARY_COLUMNS), drop = FALSE]
}

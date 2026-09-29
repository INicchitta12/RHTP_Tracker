# R/routine_prompts_worktree.R -- the v4 Routine prompts: every firing works
# in a SEPARATE git worktree, never in the runner's primary checkout.
#
# Why (session 78, docs/session78_*.md s3; confirmed or refuted by the
# 2026-09-30 NY/MO firings, docs/session79_*.md): a runner's cold resume
# re-loads CLAUDE.md, ~330k tokens, whenever the primary checkout's copy
# differs from the one its conversation already holds. The v3 prompt's own
# step 1 (`git checkout -B main origin/main` in the primary checkout) is what
# changed it. Under v4 the primary checkout is never touched, so its CLAUDE.md
# is frozen at the copy the runner loaded on its first turn.
#
# Source of record: config/routine_prompts/v3/<ST>.txt, the prompts exactly as
# list_triggers returned them on 2026-09-29. This script derives
# config/routine_prompts/v4/<ST>.txt from them by FIVE edits, each asserted to
# apply the expected number of times, so a v3 prompt that has drifted fails
# here instead of producing a half-edited v4:
#   1. a SEPARATE WORKING COPY block before step 1;
#   2. step 1 replaced (state write set, or CMS's);
#   3. `git checkout -B main origin/main` after step 1 -> `--detach`;
#   4. "Read CLAUDE.md sections ..." points at the working copy;
#   5. a moved runner's session id replaced (config/routine_prompts/runner_moves.csv).
# Everything else -- gates, notes, write sets, publish rules -- is byte-identical.
#
#   Rscript R/routine_prompts_worktree.R --write   # (re)write v4/*.txt
#   Rscript R/routine_prompts_worktree.R --check   # v4 on disk == derived

RP_DIR      <- here::here("config", "routine_prompts")
RP_WORKTREE <- "/root/rhtp_work"
RP_PRIMARY  <- "/home/user/RHTP_Tracker"

rp_read <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

rp_moves <- function() {
  f <- file.path(RP_DIR, "runner_moves.csv")
  if (!file.exists(f)) {
    return(tibble::tibble(state = character(), old_runner = character(),
                          new_runner = character()))
  }
  m <- readr::read_csv(f, col_types = readr::cols(.default = "c"))
  m <- dplyr::filter(m, !is.na(new_runner) & nzchar(new_runner))
  stopifnot(!anyDuplicated(m$state),
            all(stringr::str_detect(m$new_runner, "^session_\\w+$")))
  m
}

rp_sub_once <- function(x, pattern, replacement, n_expected, what, st) {
  n <- stringr::str_count(x, stringr::fixed(pattern))
  if (n != n_expected) {
    stop("[prompts] ", st, ": expected ", n_expected, " x ", what,
         ", found ", n, ". The v3 prompt has drifted; read it.", call. = FALSE)
  }
  stringr::str_replace_all(x, stringr::fixed(pattern), replacement)
}

RP_RETRY <- paste0(
  "   A 5xx from GitHub or its credential service (e.g. \"503\", \"credential\", ",
  "\"Service Unavailable\", \"Internal Server Error\") is TRANSIENT, not a stop ",
  "condition: retry git fetch up to 5 more times, waiting 30, 60, 120, 240 and ",
  "480 seconds. Only if all six attempts fail, report the last error text ",
  "verbatim in one line and STOP -- the coverage check will name the missed ",
  "firing, which is the intended backstop, not a substitute for retrying.")

rp_working_copy_block <- function() {
  paste0(
    "SEPARATE WORKING COPY (session 79). This session's PRIMARY checkout is ",
    RP_PRIMARY, " (the directory it started in, containing R/utils_config.R). ",
    "NEVER modify it: no checkout, switch, pull, merge, rebase, reset, clean, ",
    "stash, commit or file edit there, ever. Claude Code re-reads its CLAUDE.md ",
    "whenever this runner resumes, and a copy that differs from the one this ",
    "conversation already holds is loaded again on top of it (~330k tokens per ",
    "resume; session 78). All of this run's work happens in a separate git ",
    "worktree, ", RP_WORKTREE, ". The shell's working directory is reset to the ",
    "primary checkout between tool calls, so START EVERY SHELL COMMAND IN EVERY ",
    "STEP BELOW WITH: cd ", RP_WORKTREE, " && (a bare cd in an earlier call does ",
    "not carry over). The only exceptions are step 1's fetch and worktree ",
    "commands, which start with cd ", RP_PRIMARY, " && and change nothing but ",
    "git's refs and worktree list. The worktree is on a DETACHED HEAD by ",
    "design; commit there and push with git push origin HEAD:main exactly as ",
    "below.")
}

rp_step1 <- function(kind) {
  residue <- if (kind == "CMS") {
    paste0(
      "   b. Residue of THIS Routine (session 75: a dirty tree left by the ",
      "2026-09-24 declined run halted the 2026-09-28 firing). If ", RP_WORKTREE,
      " exists, run: cd ", RP_WORKTREE, " && { git rebase --abort 2>/dev/null; ",
      "git merge --abort 2>/dev/null; true; } && git status --porcelain, and ",
      "classify every path it lists. If EVERY path is inside this run's own ",
      "write set (under data/raw/cms/ or logs/, or exactly ",
      "data/reference/cms_state_announcements.csv or ",
      "data/reference/cms_newsroom_topic_index.csv), it is residue of an ",
      "earlier run of THIS Routine that declined to commit and is re-fetched by ",
      "step 2: name the paths in your report and continue (c discards them). If ",
      "ANY path is outside that set, discard nothing, leave ", RP_WORKTREE,
      " in place, report the files and STOP.")
  } else {
    paste0(
      "   b. Residue of THIS Routine (session 76: this runner is a persistent ",
      "session, so a declined run's files survive into the next firing). If ",
      RP_WORKTREE, " exists, run: cd ", RP_WORKTREE, " && { git rebase --abort ",
      "2>/dev/null; git merge --abort 2>/dev/null; true; } && git status ",
      "--porcelain, and classify every path it lists. This Routine's write set ",
      "is exactly one path, logs/probe_results.csv (modified, or untracked). If ",
      "EVERY listed path is that path, it is residue of an earlier run of THIS ",
      "Routine that did not publish: name it in your report and continue (c ",
      "discards it). If ANY listed path is outside that set, discard nothing, ",
      "leave ", RP_WORKTREE, " in place, report every path verbatim and STOP. ",
      "Step 3 restores the write set whenever a run declines to publish, so a ",
      "path outside it means something other than this Routine's own logging ",
      "changed the tree, and a human must read it (the coverage check will ",
      "name the missed firing).")
  }
  paste0(
    "1. Clean, current working copy.\n",
    "   a. cd ", RP_PRIMARY, " && git fetch origin main\n",
    RP_RETRY, "\n",
    residue, "\n",
    "   c. Recreate the working copy from current main: cd ", RP_PRIMARY,
    " && { git worktree remove --force ", RP_WORKTREE, " 2>/dev/null; rm -rf ",
    RP_WORKTREE, "; git worktree prune; } && git worktree add --detach ",
    RP_WORKTREE, " origin/main\n",
    "   d. Check: cd ", RP_WORKTREE, " && test -f R/utils_config.R && test -z ",
    "\"$(git status --porcelain)\" && test \"$(git rev-parse HEAD)\" = ",
    "\"$(git rev-parse origin/main)\" && echo WORKTREE_OK. If it does not print ",
    "WORKTREE_OK, report what failed and STOP.")
}

rp_derive <- function(st, v3, moves = rp_moves()) {
  kind <- if (st == "CMS") "CMS" else "STATE"
  x <- v3

  # 5. moved runner
  mv <- dplyr::filter(moves, state == st)
  if (nrow(mv) == 1) {
    n <- stringr::str_count(x, stringr::fixed(mv$old_runner))
    if (n < 2) stop("[prompts] ", st, ": old runner id found ", n, " times.",
                    call. = FALSE)
    x <- stringr::str_replace_all(x, stringr::fixed(mv$old_runner),
                                  mv$new_runner)
  }

  # 2. step 1
  i1 <- stringr::str_locate(x, stringr::fixed("\n\n1. Clean, current checkout."))
  i2 <- stringr::str_locate(x, stringr::fixed("\n\n2. "))
  if (anyNA(i1) || anyNA(i2) || i2[1] < i1[1]) {
    stop("[prompts] ", st, ": step 1 not found.", call. = FALSE)
  }
  old1 <- substr(x, i1[1] + 2, i2[1] - 1)
  if (!grepl("git checkout -B main origin/main", old1, fixed = TRUE)) {
    stop("[prompts] ", st, ": v3 step 1 lacks its checkout.", call. = FALSE)
  }
  head <- substr(x, 1, i1[1] - 1)
  tail <- substr(x, i2[1], nchar(x))

  # 3. later checkouts
  tail <- rp_sub_once(tail, "git checkout -B main origin/main",
                      "git checkout --detach origin/main",
                      if (kind == "CMS") 0 else 1, "post-step-1 checkout", st)

  # 4. CLAUDE.md pointer
  m <- stringr::str_match(head, "Read CLAUDE\\.md sections (.+?) before acting\\.")
  if (is.na(m[1, 1])) stop("[prompts] ", st, ": no CLAUDE.md pointer.",
                           call. = FALSE)
  head <- rp_sub_once(head, m[1, 1], paste0(
    "After step 1, read CLAUDE.md sections ", m[1, 2], " from the working copy (",
    RP_WORKTREE, "/CLAUDE.md), those sections only: locate them with grep -n ",
    "and print the range with sed -n. Never open the primary checkout's ",
    "CLAUDE.md."), 1, "CLAUDE.md pointer", st)

  # 1. the working-copy block
  paste0(head, "\n\n", rp_working_copy_block(), "\n\n", rp_step1(kind), tail)
}

rp_all <- function() {
  sts <- sub("\\.txt$", "", list.files(file.path(RP_DIR, "v3"), "\\.txt$"))
  r <- readr::read_csv(here::here("config", "routines.csv"),
                       col_types = readr::cols(.default = "c"))
  if (!setequal(sts, r$state)) {
    stop("[prompts] v3/ and config/routines.csv name different states.",
         call. = FALSE)
  }
  moves <- rp_moves()
  stats::setNames(lapply(sts, function(st) {
    rp_derive(st, rp_read(file.path(RP_DIR, "v3", paste0(st, ".txt"))), moves)
  }), sts)
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  p <- rp_all()
  out <- file.path(RP_DIR, "v4")
  if ("--write" %in% args) {
    dir.create(out, showWarnings = FALSE)
    for (st in names(p)) writeLines(p[[st]], file.path(out, paste0(st, ".txt")),
                                    sep = "", useBytes = TRUE)
    cat("[prompts] wrote", length(p), "v4 prompts to", out, "\n")
  } else if ("--check" %in% args) {
    bad <- names(p)[!vapply(names(p), function(st) {
      f <- file.path(out, paste0(st, ".txt"))
      file.exists(f) && identical(rp_read(f), p[[st]])
    }, logical(1))]
    if (length(bad)) stop("[prompts] v4 differs from derived: ",
                          paste(bad, collapse = ", "), call. = FALSE)
    cat("[prompts] v4 matches derived for", length(p), "states\n")
  } else {
    cat("usage: --write | --check\n")
  }
}

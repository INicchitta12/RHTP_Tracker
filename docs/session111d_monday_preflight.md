# Session 111d — Monday 11-02 preflight (2026-10-30)

Read-only preflight for Session 112. No award row, summary call or figure moved.

## 1. Branches

- 111b (`claude/cool-hawking-u6syex`) and 111c (`claude/nifty-shannon-3nfizn`): fully on `main`.
- Session 111 (`claude/tender-tesla-8po353`): its first three commits merged as PR #115; its last two
  (`17f8d98`, the SD/WA/VA `old_deleted` record; `e70da18`, the 14:40Z check-in write-up) were NOT on
  `main`. Merged onto this branch (docs and `config/routines.csv` only).
- Other branches with commits not on `main`: `claude/s108-old-routines-deleted` (just `17f8d98`, now
  covered); `claude/festive-cori-sm3p3c` (session 109's original commits, superseded by main's session 109
  commits; not checked commit by commit); ten branches from sessions 7–77 (08-27 to 10-01).

## 2. Suite on `main` (9b89219)

`Rscript tests/run_tests.R`: 0 failures, 1 skip (CMS first-run branch), 2 warnings (`test_03bj` line 478,
uninitialised `cms_enrolment_match` column; pre-existing). 33m17s. A first attempt was killed by the
30-minute background limit at `03u`, not by a failure.

## 3. R/08 dry run (discarded)

Built in a throwaway worktree, output deleted. Every `test_08` pin matched; the 10-30 CSV is identical
to the committed 10-29 CSV. Award total $4,171,734,402.31; hospital best estimate $2,005,223,415.77
(CODED $1,780,528,970.90 + BEST_JUDGMENT $224,694,444.87); strict NAMED $1,731,421,723.08; 48.1% of
awards, 20.1% of allotment. `US_GE50`: awards $3,362,841,950.78, hospital $1,557,146,269.69.

## 4. Routines

- Coverage since 10-26: 41 firings due, 40 logged; the miss is CMS 10-26 13:00Z, already explained.
  `--check`: 289 due, all logged except 7 explained.
- Runners above 600k (`get_session`, `used_tokens`): NY 640,952 only. Next: CA 594,869, DE 579,543,
  KS 565,489, NC 561,110.
- No pending one-shot check-in existed. Scheduled `trig_01CC8FCXRQWXpRaAaQYPqT8Q`, Wed 11-04 14:30Z, into
  this session: delete each old id (MS `trig_01Ugf2k1…`, NM `trig_01EeEQZD…`, KY `trig_01Jk2igf…`, NE
  `trig_01WDA8s6…`, ND `trig_016DwLq1…`, OH `trig_01VEe1KQ…`) once its successor has a line on `main`, and
  record it in `old_deleted`. MS and KY successors have already logged (10-30 09:41Z, 10-29 19:40Z).
- Monday 11-02 firings 12:00–21:00Z (from `config/routines.csv` cron): CMS 13:00, AK 14:00, CT 15:40,
  NEWSROOM 16:50, HI 18:30, KY 19:30. Never merge CMS-monitor output during 13:00–14:00Z.

## 5. Blockers for Session 112

None found. Unread tripwires to triage Monday (none changes the run order): TX's new 10-29 Rural Texas
Strong list (`R/03ce` list path); WV runner reports two awards (Williamson Health $250K, WVU Cancer
Institute $1.3M); SD register rows (27RHT00055, ~$37.33M); OK Funding Recipients anchors empty; MS
funding; IN GROW; KY funding; CO programme; WA programme.

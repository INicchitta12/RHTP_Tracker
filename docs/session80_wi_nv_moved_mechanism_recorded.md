# Session 80: WI and NV moved, the reload mechanism recorded, the suite re-run

2026-10-01. Zero RCJ quota. No live fetch. Nothing was written to `logs/probe_results.csv`.

This session restarted the session 79 task. Session 79's branch (`claude/youthful-planck-78zi72`) had done
most of it and had not reached `main`. This branch merges it and finishes the rest.

## 1. The two readings (Task 1)

Re-read from `get_session` today. Neither runner has resumed since its 09-30 firing.

| Runner | Session | Before (09-29) | After (09-30 firing) | Change | Predicted | Falsifier |
|---|---|---:|---:|---:|---:|---:|
| NY | `session_01NfXAHPAh7kopwE41JsxHco` | 384,866 | **723,788** | +338,922 | ~715k | ~385k |
| MO | `session_01J5YCDdt9saEJVxmsATnLLD` | 368,982 | **687,835** | +318,853 | ~700k | ~370k |

Both rose by more than 300k, so the gate for Task 2 was met. Session 79 recorded the same figures on 09-30.

## 2. What session 79 had done, and what it had not (Task 2)

**Done.**
- All 38 Routines were recreated on the v4 worktree prompt, California first, at 15:27Z, 93 minutes before
  its firing.
- Nine runners were moved: CA, CMS, AR, KY, NEWSROOM, CT, CO, MS and VA.
- The 38 v3 originals were disabled.
- CA and NH then published under their v4 ids, and the 38 v3 originals were deleted after that.
- `config/routines.csv` chains every v3 id.

**Not done.**
1. **WI and NV were left on their old runners.** The instruction named eleven runners, and session 79
   moved nine. Both runners are at ~700k (698,839 and 708,018) and hold the trimmed `CLAUDE.md` in a tree
   that differs from their conversation's copy. Their next resume (Fri 10-02) was predicted at 870–900k.
2. **The branch was never merged to `main`.** `main`'s `routines.csv` still lists the deleted v3 ids, so
   `R/probe_coverage.R` on `main` reads the v4 lines as unregistered and the v3 firings as missed. **The
   CMS runner's 10-01 13:00Z firing declined to publish for that reason.** Its suite failed on three
   errors: the CA 09-30 17:00Z and NH 09-30 18:10Z coverage gaps, and an Indiana GROW date test (§4). It
   committed nothing, restored its tree, and reported new CMS announcements for CO, MT and TX. These were
   not collected and will be re-fetched at the next firing (Mon 10-05 13:00Z).
   - That CMS runner sat at ~140k after the firing. It is the new v4 runner (`session_01V643Un4ty7ybFRiJrtHUTN`).

**Done in this session (14:52Z–14:54Z).**

| State | New runner | New trigger | Old trigger (disabled) | Cron (UTC) | Old runner |
|---|---|---|---|---|---|
| WI | `session_015MmuoqyL2kEm71ossQjGBE` | `trig_01BDpiJbCKRQWwZcLh1x8PsS` | `trig_013N9mnDM86QEpQgzKwGFtp4` | `0 14 * * 2,5` | `session_01MautT3SfaKPnu7JJz2BCpK` |
| NV | `session_017bmcm9iniGkBq6siH8SXGL` | `trig_013u9wiLjrzkXJJ6PCax6LVm` | `trig_014c3kseN8WpCL5cMVcdaaYi` | `10 15 * * 2,5` | `session_0194azxMDRmebsaQ9YtDZBVC` |

- The new runners were set up the same way as session 79's: environment `env_01RnpqJ1D6wFAaRMvFu43oV3`,
  `claude-sonnet-5`, auto mode, the repository on `main` as source, `main` as outcome, no seed prompt.
- `runner_moves.csv` gained the two rows. `Rscript R/routine_prompts_worktree.R --write` regenerated the 38
  v4 prompts, and only WI and NV changed. Each changed in exactly the four places where the runner id
  appears.
- The names and crons are unchanged. A fresh `list_triggers` showed both stored prompts **byte-identical**
  to `config/routine_prompts/v4/{WI,NV}.txt`.
- It also showed 40 enabled recurring Routines before the disables and no runner with more than one. The
  old runners were still bound to the old ids, so each runner's step 2 still finds exactly one Routine.
- The two old v4 ids were disabled, not deleted. Under the rule, they are deleted only after both new
  Routines have put a line on `main`.
- `config/routines.csv`: each old v4 id is appended to the row's `old_trigger_id` chain, with its own
  `logging_since` appended to `old_logging_since`. The new `logging_since` is each trigger's `created_at`.

## 3. The mechanism, recorded (Task 3)

A block now sits in CLAUDE.md §2.2a, beside the manual re-fire note. It records:
- the reload trigger;
- why the trim did not help on the next firing;
- why NY and SC stayed flat;
- the 10/10 and 2/2 evidence;
- the prediction test and its result;
- the rule that follows.

The §10 Runner context lines and Next session were brought up to date.

## 4. The suite (Task 4)

**First run:** the merged branch before this session's fix, 18m40s. One failure and one skip.
- The skip is the standing first-run branch of `test_00_cms_press_monitor.R`.
- The failure is `test_03bi_in_grow_regional_awardees.R:40`:
  `[IN-GROW] date test: releases dated Sept. 3, 2026 ×8 against NOA 2025-12-29`.

**Root cause: a date-dependent parse, not Indiana.** `ig_assert_releases()` parsed with
`as.Date(x, format = "Sept. %d, %Y")`. That format has no month field, so R supplies the **current**
month. The assertion read 2026-09-03 every day in September and 2026-10-03 from 10-01, and then failed
its `dates == IG_ANNOUNCED` check. It is the same Indiana failure the CMS runner hit at 13:00Z. A suite
run on any day in September could not have caught it.
- **The fix** maps the month from the text: `"Sept. 3, 2026"` becomes `2026-09-03`. Any other month spelling
  now becomes `NA` and fails the assertion, as it should.
- A grep of `R/` and `tests/` for any `format =` containing `%d` but no month field found this one line
  and no other.

**Final run:** see §5.

## 5. Final suite result

`Rscript tests/run_tests.R` on this branch's final tree, 2026-10-01: **0 failures**, 1 skip (the standing
first-run branch of `test_00_cms_press_monitor.R:188`), 18m44s. `R/probe_coverage.R --check`: 54 due firings,
all logged except 3 explained.

**This is green on this branch only.** `main` still fails, on the coverage gaps and the Indiana date test,
until this branch is merged. The next CMS firing that runs the suite is Mon 10-05 13:00Z.

## 6. Check-in, 2026-10-02 15:45Z: the old WI and NV ids deleted

- **Both new Routines published to `main`.**
  - WI, `trig_01BDpiJbCKRQWwZcLh1x8PsS`: logged at 14:10:52Z, commit `8481d1e`.
  - NV, `trig_013u9wiLjrzkXJJ6PCax6LVm`: logged at 15:12:50Z, commit `594c990`. `roster` and `nofos` were
    both UNCHANGED.
- **This branch reached `main`** before either firing. Commit `bbe35ee` is an ancestor of `origin/main`.
- **The old ids were deleted.** `get_trigger` first confirmed `enabled: false` on both
  `trig_013N9mnDM86QEpQgzKwGFtp4` (WI) and `trig_014c3kseN8WpCL5cMVcdaaYi` (NV), and `delete_trigger` then
  succeeded on each. Both stay in their rows' `old_trigger_id` chains in `config/routines.csv`.
- **Context on the new runners** after their first v4 firing:

  | Runner | `used_tokens` | Old runner's reading |
  |---|---:|---:|
  | WI | 130,012 | 698,839 |
  | NV | 132,140 | 708,018 |

  This matches CA's new runner, at 127,507. All eleven heavy runners are now on new sessions.
- **WI's firing was a TRIPWIRE.**
  - `dhs_solicit` names one string the archive does not: *"Intoxicated Driver Program Supplemental Funding
    Request for Application"*.
  - On its face this is a DHS solicitation title, not an RHTP recipient.
  - Nothing was added to `known` or `furniture`. Under §2.3, a human reads the page first.

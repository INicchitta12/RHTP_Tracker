# Session 76: every Routine gets the CMS reset logic, four probes scheduled, runner context measured

2026-09-28. Four tasks. Nothing was back-filled into `logs/probe_results.csv`.

## 1. Four probes on Routines

Each has its own new runner session: repository source, outcome branch `main`,
`claude-sonnet-5`, auto mode, created with **no seed prompt** (see §3 for why).

| State | Trigger | Runner | Cron (UTC) | First firing | Why |
|---|---|---|---|---|---|
| MT | `trig_019e4wVjfnazAh7AvYcr1yUN` | `session_01GGJ61Ux7s4Zp1nGwTpRJLD` | `40 17 * * 2,5` | Tue 09-29 | EMS Equipment Grant decisions "in September": the window closes 09-30 |
| NH | `trig_013kuBUJ39zAwF7SM7RYfwvk` | `session_019SBzVqWVoWMmfsGEj57hwo` | `10 18 * * 3` | Wed 09-30 | CAH/Acute Care RFA still "Coming Soon" past its own late-August date |
| OK | `trig_01MT1CVgVd1LZQbMpRoRMRGD` | `session_01KCqoLtaJ3X9yGJG3XSvT2e` | `10 18 * * 4` | Thu 10-01 | No published date |
| MN | `trig_01TkZG5yB5a1LnuBMv67tPEj` | `session_01YMHRbw9ToET8yfpwSqg5bu` | `10 18 * * 5` | Fri 10-02 | No published date |

All four slots are clear of the other 34 Routines' start minutes. Every prompt uses the new
template (§2) and is registered in `config/routines.csv` with `logging_since` equal to
the trigger's creation time.

## 2. The CMS reset logic, applied to the other 33 Routines

The CLAUDE.md count of "32" leaves out the NEWSROOM sweep. There are 33 non-CMS
Routines, and all 33 were recreated.

**The defect.** Each state prompt's step 1 cleared a dirty tree only if its sole
entry was `logs/probe_results.csv`. Nothing ever restored the tree when a run
declined to publish. On a persistent runner, one declined run therefore stalled every
later firing, and the platform still reported SUCCEEDED. That is what happened to
CMS on 09-28.

**The new prompt, per state.** It is the existing prompt with four edits and nothing
else: gates, notes and state wording are unchanged.

1. **Step 1:** abort any interrupted rebase or merge. Classify every dirty path. If
   every path is in the Routine's write set (exactly `logs/probe_results.csv`,
   modified or untracked), discard it, name it, and continue. If any path is outside
   that set, discard nothing, report every path and stop. This is CMS's step 1 with
   the state write set.
2. **Step 3a:** if something besides the log moved, commit nothing, report, **then
   restore the write set**. This is CMS's step 3. Out-of-set paths are left for a
   human.
3. **Step 3e/3f:** after a final push failure, drop the unpublished commit
   (`git checkout -B main origin/main`). Before ending, confirm
   `git status --porcelain` is empty or lists only the paths reported.
4. **`list_triggers`:** limit 100 on every prompt. NE and NV had 50, and 72
   Routines exist during this overlap, so 50 would have missed their own.

**One behaviour is deliberately kept from CMS.** A path outside the write set still
halts the runner until a human reads it. This version restores its own residue, so
such a path means something other than this Routine's logging wrote to the tree
(for example, a probe that tripped the evidence guard). The coverage check names
every firing lost that way, so the halt is visible, not silent.

**How it was done.**
- 33 new triggers were created on the same runners with the same crons, then each
  original was disabled.
- The stored prompts were read back with `list_triggers` and compared to the source
  file **byte for byte**: 37 of 37 match (33 plus the four in §1).
- Each runner has exactly one enabled Routine, 38 in total with CMS.
- `config/routines.csv` appends each original to the `;` chain in `old_trigger_id` /
  `old_logging_since`.
- `probe_coverage.R --check` passes.
- `connectors` could not be passed ("not available for this organization"), so it
  was omitted; `mcp_connections` is `[]`, as on the originals.

**Originals: disabled, not deleted.** A check-in is scheduled for 2026-09-29 11:15Z
(`trig_01RXSUQ5owgHi9XzF5e2ixvS`). It looks for log lines on `main` carrying the new
MS id (09:40Z) and VA id (10:20Z), with VT (11:30Z) as a fallback. If two have
published, it deletes the 33 originals. Those are the last element of each non-CMS
`old_trigger_id` chain.

**Deadline.** This branch should reach `main` before **Tue 09-29 09:40Z**.
- Until it does, `main`'s `routines.csv` still expects the old ids. From the first
  new-id firing onward, the coverage check reports those firings as missed, in
  every runner's step 4.
- The CMS runner runs the full suite at **Thu 10-01 13:00Z**. If the branch is still
  unmerged then, that run declines. It now restores cleanly, but the firing is lost.

## 3. Runner context: what the numbers show, and what they do not

Measured with `get_session` on all 34 existing runners on 2026-09-28 ~20:10Z.
`max_tokens` is 1,000,000 everywhere. `list_events` is not available in this
environment, so there are no per-turn figures and no compaction evidence.

**Fixed cost per resume.**
- Every runner that has had one turn sits at **354k–389k**, however little the turn
  did. NM's only turn was a setup check with 263 output tokens and is at 353,789.
- `CLAUDE.md` is **754 KB, roughly 190k tokens**. It is loaded as project
  instructions. Tool definitions and the system prompt make up most of the rest.
- The probe work itself adds about 15–35k.

**The second resume roughly doubles it.** Seven runners sit at **681k–713k**: CMS
713,059, AR 703,052, KY 698,651, NEWSROOM 695,803, CT 693,786, CO 686,366 and
CA 681,366.
- Each is at `worker_epoch` 3 and describes two firings.
- One-turn runners are at epoch 2 and ~370k.
- Cache writes follow the same split: about 335k for one-turn runners, 1.0–1.6M for
  the seven.
- The pattern fits each cold resume re-loading the ~330k startup context into a
  conversation that already holds the previous copy.

**It is not uniform.** NY (384,866) and SC (383,422) are also at epoch 3 with two
firings. I cannot tell whether they were compacted, ran both firings in one worker,
or loaded a smaller context.

**What happens at 1M.** This part is not observed; it is my understanding of the
product.
- Claude Code compacts automatically as context nears the window. It summarises
  earlier turns and continues.
- Each firing's prompt is self-contained: fetch, reset, probe, publish. A runner
  needs nothing from its earlier turns, so a compacted runner should still run
  correctly.
- If a further ~330k load lands on a 700k conversation, the next firing of those
  seven either compacts first or fails.
  - **Compacts first:** slower and costlier, no loss.
  - **Fails:** the platform's `last_run` would still read SUCCEEDED. Delivery is all
    it records (§2.2a). The coverage check would name the missed firing.
- I found no evidence either way. The seven next fire from Wed 09-30 to Thu 10-01:
  CA Wed 17:00Z first, then CO 09:10Z, CMS 13:00Z, CT 15:40Z, NEWSROOM 16:50Z,
  KY 19:30Z and AR 20:20Z on Thursday. Thursday 10-01 is the day to read their
  `get_session` summaries and the coverage check.

**Degrade, or fail?** The instructions do not degrade, because they are re-sent in
full each firing. What can degrade is the cost per firing, and the risk is an
outright failed turn if compaction cannot bring the context under the window.

**What recycling a runner costs.** Nothing was recycled; this is a report.

`update_trigger` cannot change a trigger's session binding. The prompt also names the
runner's session id in steps 2 and 3. So a new runner means:
- **One new session.** `create_session` with the repo, outcome `main`, sonnet, auto
  mode and no seed prompt. A seed turn is another ~355k load, which is why §1's
  runners have none.
- **One new trigger** with the new session id in its prompt, then disable the old
  one.
- **One more link** on the `routines.csv` chain.
- **One cold first firing:** clone, R package check, about 355k context.

It loses no data: the tree is disposable, and the new prompt resets it anyway. Doing
it well away from a scheduled firing avoids a gap. Per runner, the dollar cost of the
first turn at the observed rates is about $1.3–2.5 (runner `cost_usd`).

**The cheaper lever is `CLAUDE.md` itself.** At ~190k tokens it is over half of every
runner's floor. Nearly all of it is the "Current state" history, which no probe
needs.
- Moving that history into `docs/` would cut every runner's per-resume load and every
  interactive session's.
- It would also slow the fill that makes recycling necessary.
- It is a §2.1 patch-only edit to a governed document. It is proposed here, not done.

## 4. Minnesota moves to INVESTIGATED_NO_LIST

`R/03k`'s constants moved MN from `INVESTIGATED_NO_PROBE` to
`INVESTIGATED_NO_LIST`: it now has an archive, a probe with tripwires (R/03bn) and a
Routine. Both tables were rebuilt, not hand-edited.
- The split is **36 / 8 / 2 / 4**.
- HI and MA remain `INVESTIGATED_NO_PROBE`, and neither is an ordinary negative.
- The rebuild also picked up two changes CMS's Routine had recorded but the
  committed survey had not: Missouri's CMS source is now `BOTH`, and Delaware's
  2026-09-24 release.
- Montana now meets the same test (archive, probe, Routine). It was left `QUEUED`
  because only Minnesota was asked for.

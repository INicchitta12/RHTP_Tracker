# Session 79: v4 Routine prompts (separate worktree), gated on Wednesday's falsifier

Started 2026-09-29 16:03Z. Zero RCJ quota. No Routine was created, changed or deleted on 09-29.

## 1. What was asked

1. Recreate all 38 Routines so each firing works in its own checkout. Move nine runners to new sessions:
   CMS, AR, KY, NEWSROOM, CT, CO, CA, MS, VA. Do California first, since it fires Wed 17:00Z.
2. Before relying on session 78's mechanism, test it. NY after Wed 11:10Z should be ~715k and MO after
   15:00Z ~700k. If either stays near 385k, report that and do not recreate anything that depends on it.

Every v4 prompt depends on the mechanism, so **nothing is recreated until both readings are in**. Both
fall before CA's 17:00Z firing.

## 2. The gate

| Runner | Session | Baseline 09-29 | Epoch | Firing | Predicted | Observed |
|---|---|---:|---:|---|---:|---:|
| NY | `session_01NfXAHPAh7kopwE41JsxHco` | 384,866 | 3 | Wed 11:10Z | ~715k | **723,788** (epoch 4, +338,922) |
| MO | `session_01J5YCDdt9saEJVxmsATnLLD` | 368,982 | 2 | Wed 15:00Z | ~700k | _pending_ |

**NY, read 2026-09-30 11:36Z: CONSISTENT.** `used_tokens` 723,788 at `worker_epoch` 4 (`updated_at` 11:13:01Z), up 338,922 from yesterday's 384,866, against a ~715k prediction. The firing published: `fa03ce5` carries four NY lines from `trig_013JEYxw1aScGLtMM5U4jQGw` at 11:12:27Z (programme and roster UNCHANGED, press_index and scr CHANGED). No Routine was created or deleted. MO decides the gate.

Check-ins (this session, `send_later`): `trig_013WrHD3nHpXv2FFvFabApvC` at 11:35Z (NY) and
`trig_01AxS6G8pDFwMyjSTff44cTz` at 15:25Z (MO, then CA if the mechanism holds).

## 3. The v4 prompt

`R/routine_prompts_worktree.R` derives `config/routine_prompts/v4/<ST>.txt` from
`config/routine_prompts/v3/<ST>.txt`. The v3 files are the 38 stored prompts, exactly as `list_triggers`
returned them on 09-29 (crons checked against `routines.csv`, 38 of 38). It makes five edits. Each is
asserted to apply the expected number of times, so a drifted v3 prompt fails instead of being half-edited.

1. **A SEPARATE WORKING COPY block.** Never modify `/home/user/RHTP_Tracker`. All work happens in
   `/root/rhtp_work`, a detached-HEAD `git worktree`. Every shell command starts `cd /root/rhtp_work &&`,
   because the shell's cwd resets to the primary checkout between tool calls. This session observed that
   reset.
2. **Step 1 replaced.**
   - a. Fetch in the primary: this changes refs only.
   - b. Classify residue in the old worktree with the same write-set rule as v3. A path outside the write
     set still stops the run, and the worktree is left for a human.
   - c. `worktree remove` / `rm -rf` / `prune` / `worktree add --detach … origin/main`.
   - d. Print `WORKTREE_OK` or stop.
   - The CMS variant keeps CMS's write set.
3. **The post-step-1 `git checkout -B main origin/main` becomes `git checkout --detach origin/main`.** This
   is state step 3e; CMS has none.
4. **"Read CLAUDE.md sections …" points at the worktree copy**, and only those sections.
5. **A moved runner's session id is replaced** from `config/routine_prompts/runner_moves.csv`. The nine old
   ids are filled in; the new ids stay empty until the sessions exist.

Everything else is byte-identical: gates, notes, write sets and publish rules.

**Tested here, not on a runner.**
- `here::here()` resolves inside a worktree.
- A live `R/03am --probe` (`interactive`) ran in the worktree. It wrote only the worktree's log, and the
  primary tree was unchanged. Its line was never committed.
- A commit on a detached HEAD, `pull --rebase origin main` and `push --dry-run origin HEAD:<branch>` all
  worked.
- Step 1 was run verbatim twice, clean and with residue: `WORKTREE_OK`, then a clean tree.
- `tests/testthat/test_routine_prompts_worktree.R` checks four things:
  - the committed v4 equals the derived prompts;
  - no v4 prompt moves the primary checkout;
  - each v4 prompt still names its script;
  - a drifted v3 prompt is refused.

## 4. What v4 does not fix

The re-load happens at resume, before any prompt runs.
- **The 29 runners kept in place:** each still re-loads once, at its first resume where the primary tree
  differs from its conversation's copy. After that the tree is frozen.
- **WI and NV** were not in the nine. They hold the trimmed file and are predicted to reach ~870–900k at
  their next resume (Fri 10-02, 14:00Z and 15:10Z), then stop growing under v4.

# Session 78: trig_011p deleted, the status table asserted, why NY and SC stayed small

2026-09-29. Zero RCJ quota. No live fetch. Nothing was written to `logs/probe_results.csv`.

## 1. `trig_011pUVRNkSnjCNvZfQ89kPbM` deleted

- `get_trigger` first: the CMS Routine, session 66's id, `enabled: false`. It was bound to the CMS runner
  `session_01VcVUvS86exr36LWfje45ak`. Its last run was 2026-09-28T13:02Z, the dirty-tree halt.
- `delete_trigger` succeeded. `list_triggers` now returns 38 registered Routines and one unregistered
  entry: `trig_01HfFcNkhtmWSJ7CkHJEU7Ye`, which has no cron. That is session 77's one-shot Thursday check-in.
- **Nothing in the repository changed.** The id stays in `config/routines.csv` as a link in CMS's
  `old_trigger_id` chain. `R/probe_coverage.R` reads that chain to check the firings between
  2026-09-24T19:09Z and 09-28T14:39Z against `logs/probe_results.csv`. It never queries the platform, so a
  deleted trigger does not change the check. The id's explained miss in `config/probe_gaps_explained.csv`
  also stays. `--check` still reports 34 due firings, all logged except 3 explained.

## 2. The Deliverable 1 table is now asserted

`tests/testthat/test_claude_md_status_table.R` parses two blocks in CLAUDE.md §10 and checks them against
the committed state files:
- the "Deliverable 1: state award files" table;
- the "Hospital partition" block.

**The file set.** The test does not keep its own list of files. It parses `STATE_FILES` out of
`test_state_union.R`. If a new file is added there and not to the table, the test fails. That is the kind
of omission session 77 found: NJ, NY, WA, VA and IN GROW were missing.

**Per row it checks:**
- `Rows`: must equal `nrow`.
- `Priced`: must equal the count of non-NA `amount` values.
- `sum(amount)`: the first dollar figure, rounded to the dollar. An em dash must mean no row is priced.
- `Hospital`: must match `rhtp_hospital_dollar_partition()` bucket by bucket.
  - An unprefixed `N / $X` is `NAMED_HOSPITAL`.
  - `POOL_NAMED` and `POOL_UNNAMED` are parsed as their own buckets.
  - Every bucket the file has rows in must appear in the cell.
  - Parenthetical prose (MHA's $8.625M, WSHA's $42M, "published $175.3M") is dropped before any figure is
    read.

**The partition block.** Each bucket's rows, dollars to the cent and state count must match the union.
The set of buckets must also match.

**It was checked against the drift it exists to catch.** CLAUDE.md was edited in a scratch copy to restore
three of session 77's stale cells: KS to $52.2M, GA to 108 rows, and the NJ row deleted. The test failed on
all three, naming each one:

```
files committed but MISSING from the CLAUDE.md table: NJ
KS Hospital NAMED_HOSPITAL: CLAUDE.md says 37 / $52,200,000, file says 37 / $62,416,473
GA Hospital NAMED_HOSPITAL: CLAUDE.md says 108 / $90,277,580, file says 126 / $90,277,580
```

CLAUDE.md was restored with `git checkout` and the test passes against the committed table (20
expectations).

**Routine safety (§2.2a).** The test reads only `data/reference/<st>_*` award files and CLAUDE.md. No
Routine writes either: the 37 state prompts write `logs/probe_results.csv` only, and CMS writes
`data/raw/cms/`, `logs/` and its two `cms_*` CSVs. So it cannot fail a runner's suite on tomorrow's data. It
fails only when an interactive session changes a state file and does not update the table. That is the
behaviour it was written for.

## 3. Why NY and SC stayed near 380k

### The finding

**A cold resume re-adds ~330k only when `CLAUDE.md` in the runner's working tree differs from the copy
its conversation already holds.** NY and SC were the only two-turn runners where it did not differ.

- **Their first turn came 27 minutes after creation.** Session 54 test-fired them at 14:07Z and 14:09Z on
  09-23. No commit touched `CLAUDE.md` on `main` between their creation (13:40Z, 13:42Z) and those turns.
  So step 1's `git checkout -B main origin/main` left the file byte-identical (blob `e5a95cd`) to the copy
  they loaded at creation.
- **At their second resume, the tree still matched the conversation's copy**, and nothing was re-added.
- **Every runner that doubled had changed `CLAUDE.md` in its first turn's checkout.** Every one of their
  first firings came a day or more after creation, and by then several `CLAUDE.md` commits had reached
  `main`.

### The evidence

Each runner's `get_session` was read today. For each one, the table compares the `CLAUDE.md` blob on
`main` at its creation with the blob its first firing checked out. The firing times come from
`logs/probe_results.csv` lines carrying a `trig_` origin. The blobs come from `git rev-list --first-parent
--before`.

| Runner | used_tokens | Blob at creation | Blob at 1st firing | Changed? |
|---|---:|---|---|---|
| NY | 384,866 | e5a95cd | e5a95cd | **no** |
| SC | 383,422 | e5a95cd | e5a95cd | **no** |
| NV | 708,018 | 2b51b6c | 1fa7fb2 | yes |
| AR | 703,052 | e5a95cd | 890055e | yes |
| MS | 701,874 | e5a95cd | 154e25b | yes |
| VA | 701,001 | 6ce5392 | 154e25b | yes |
| WI | 698,839 | e5a95cd | 154e25b | yes |
| KY | 698,651 | e5a95cd | 890055e | yes |
| NEWSROOM | 695,803 | dc56799 | de73a2c | yes |
| CT | 693,786 | e5a95cd | de73a2c | yes |
| CO | 686,366 | 6ce5392 | f7ec115 | yes |
| CA | 681,366 | e5a95cd | 58a6f11 | yes |

- **The split is exact: 10 of 10 changed runners doubled, and 2 of 2 unchanged runners did not.** No row
  contradicts it.
- CMS, the twelfth heavy runner, logs its firings through the stage 00 commit rather than a
  `trig_`-origin probe line, so it is not in the table. It is at 713,059 and fits the pattern.
- **Nothing else separates NY and SC from AR.** SC and AR have the same `origin`
  (`claude_code_mcp_seed`), the same parent session, the same CLI version (2.1.280), model, tags and
  `worker_epoch` (3). Their cache writes are also nearly identical: 1,305,123 and 1,303,474.
- **The gap between turns does not explain it.** SC's two turns were 18 hours apart and NY's 3.9 days.
  AR's were 3.0 days and CA's 3.0 days.

### A natural experiment from today

The trim merged at 14:12Z (`70f012c`). WI fired at 15:02Z and NV at 15:13Z, both after the merge. **Both
still doubled**, to 698,839 and 708,018. Their resume happened before step 1's fetch, so what they
re-loaded was the pre-trim file their previous firing had left in the tree.

That settles session 77's open caveat. **A runner loads `CLAUDE.md` from its own persistent tree, not from
`main`.** The trim therefore saves nothing on each runner's first firing after the merge. It saves only
from the firing after that.

### What is inferred, not observed

- `list_events` is not available here. No runner transcript was read.
- The trigger (a changed `CLAUDE.md` in the tree) is a correlation over 12 runners with no counterexample.
  The mechanism is inferred.
- **The increment (~330k) is larger than `CLAUDE.md` alone (~190k at 754 KB).** So the re-load is more
  than the memory file. I cannot say what the other ~140k is.

### Predictions that test it this week

| Runner | Firing | Prediction | Why |
|---|---|---|---|
| NY | Wed 09-30 11:10Z | ~715k | Its 09-27 checkout moved the tree to `53a2378` (pre-trim), unlike what it holds |
| MO | Wed 09-30 15:00Z | ~700k | Its only turn moved `e5a95cd` → `51e70c1` |
| SC | Thu 10-01 08:30Z | ~715k | Its 09-24 checkout moved the tree to `f7ec115` |
| WI, NV | next firing | ~870–900k | The tree now holds the trimmed file (`1d7f730`), so the re-load is smaller |

**If NY is still near 385k after Wednesday, the finding is wrong.** That is the falsifier.

### What it means for recycling

**The growth is caused by the runner's own checkout, so a prompt change stops it for good.** Step 1
currently runs `git checkout -B main origin/main` in the session's primary checkout, which is where Claude
Code reads `CLAUDE.md`. If each firing instead did its work in a separate clone, the primary checkout's
`CLAUDE.md` would never change. For example, the firing could run `git clone` or `git worktree add` into a
scratch directory such as `$HOME/rhtp_work` and work from there. Each resume would then add only the
firing's own work, ~15–35k. That is roughly 20 or more firings of headroom instead of one or two.

**It does not rescue the runners whose trees already hold a pre-trim file that differs from their
conversation's copy.** The re-load happens at resume, before any prompt runs. Those runners are:

- **At ~700k: CMS, AR, KY, NEWSROOM, CT, CO, CA, MS, VA.** Their next resume adds ~330k, to ~1.03M. That is
  over the 1M window, so it forces a compaction or a failed turn (session 76, §3). Recycle these nine.
- **At ~700k with the trimmed file in the tree: WI, NV.** They reach ~870–900k next. They can take one
  more firing, but only with the prompt fix in place before the one after. Recycle them too, or accept
  one compaction.
- **At ~370k: every one-turn runner, plus NY and SC.** They double once more whatever happens, to
  ~700k, and then stop growing if the prompt fix is in.

**Recommended.** Recreate all 38 Routines once, with step 1 working in a separate clone. That is the
session 66 / 76 procedure: same cron, old id chained in `routines.csv`. Put the eleven runners at ~700k on
new runner sessions in the same pass. New runners start at ~196k with the trimmed file, and with the
separate clone they stay near there.

Two caveats:
- `update_trigger` refuses a prompt change from outside a runner's own conversation, so recreating the
  Routines is the only route.
- This is proposed, not done. It changes every Routine and 11 runner bindings, which is the owner's call.

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
| MO | `session_01J5YCDdt9saEJVxmsATnLLD` | 368,982 | 2 | Wed 15:00Z | ~700k | **687,835** (epoch 3, +318,853) |

**NY, read 2026-09-30 11:36Z: CONSISTENT.** `used_tokens` 723,788 at `worker_epoch` 4 (`updated_at` 11:13:01Z), up 338,922 from yesterday's 384,866, against a ~715k prediction. The firing published: `fa03ce5` carries four NY lines from `trig_013JEYxw1aScGLtMM5U4jQGw` at 11:12:27Z (programme and roster UNCHANGED, press_index and scr CHANGED). No Routine was created or deleted. MO decides the gate.

**MO, read 2026-09-30 15:26Z: CONSISTENT.** `used_tokens` 687,835 at `worker_epoch` 3 (`updated_at` 15:12:16Z), up 318,853 from 368,982. Its 15:11:26Z lines from `trig_018NyhrQ6HzsiggtoU32yJFm` are on `main`. **Both predictions held, so the mechanism stands and Task 1 went ahead.**

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

## 5. Executed 2026-09-30 15:26Z–15:40Z

- **California first:** new runner `session_01NGLsj2qtvSvBFse6LoZUTV` (sonnet, auto, repo source, outcome
  `main`, no seed prompt), trigger `trig_01JEYQK9ZNMVpe27H19DFjzX` at 15:27:08Z, the old one disabled
  immediately. That was 93 minutes before its 17:00Z firing.
- **The other eight runners** were created at 15:28Z. Five agents created the remaining 37 triggers from
  `config/routine_prompts/v4/*.txt`. Nine creates hit the platform's trigger-creation rate limit once, and
  each succeeded on its single retry.
- **Verification.** `list_triggers` (77 entries) was compared by machine, and all 38 of 38 passed:
  - each v4 prompt matches exactly one stored prompt **byte for byte**;
  - that trigger has the manifest cron and runner and is enabled;
  - its runner has no other new trigger, so the retries made no duplicates.
- **The 37 v3 originals: disabling in progress** (confirmation by re-listing recorded below when done).
- **`config/routines.csv`:** each v3 id is appended to its `old_trigger_id` chain, with the trigger's
  creation time as its `old_logging_since`. `logging_since` is each v4 trigger's `created_at`. After
  merging `origin/main`, `R/probe_coverage.R --check` passed: 45 due firings, all logged except 3 explained.
- **The originals are disabled, not deleted.** Check-in `trig_01ExN2u669bFQTxBXuh31d13` at 18:35Z deletes
  them if CA (17:00Z) and NH (18:10Z) both publish under their v4 ids.

| State | v4 trigger | v3 (disabled) | Cron (UTC) | Runner |
|---|---|---|---|---|
| AK | `trig_015gBufPkXhff7pa6igt2GSU` | `trig_01PQEPAQpU3oSTEKHJPnLZXU` | `0 14 * * 1` | `session_01339T1YnhTUYCvAsEPBVHcU` |
| MO | `trig_0183VrPsZUMmc3dMneainqXm` | `trig_018NyhrQ6HzsiggtoU32yJFm` | `0 15 * * 3` | `session_01J5YCDdt9saEJVxmsATnLLD` |
| WI | `trig_013N9mnDM86QEpQgzKwGFtp4` | `trig_01MRogMki6iXgggGqz1dPEqs` | `0 14 * * 2,5` | `session_01MautT3SfaKPnu7JJz2BCpK` |
| ME | `trig_01RyrB4uNLd6rdjaD8d9tWBk` | `trig_017q25g4K3M46M7P2LUwga7j` | `20 16 * * 2,5` | `session_01CdiK6BmRbiiVASCXa8W22a` |
| CA | `trig_01JEYQK9ZNMVpe27H19DFjzX` | `trig_01X8JShUQ6MBmHaRux3FKUrC` | `0 17 * * 3,6` | `session_01NGLsj2qtvSvBFse6LoZUTV (NEW)` |
| CT | `trig_01MkoE5FCTVpcbi3MrzbS3NE` | `trig_01FYbLAnFEXUKYPERQ5NqEhy` | `40 15 * * 1,4` | `session_0113Gzz6mRbmHG65ChNCenSc (NEW)` |
| NM | `trig_01EeEQZDPeG4xW4GBA7p8WcZ` | `trig_01S7926YNffi3h6MMbRaVv5s` | `40 18 * * 2` | `session_011DdQ5LzBuCDYEXE7wCb2HY` |
| LA | `trig_016GDtAW1DvWCexnRSm4LxK8` | `trig_01XN2PYmcGf7naq3yBZPZmUf` | `50 12 * * 3,6` | `session_01MeyuQ1oRmSY1DFeRrQuTdM` |
| KY | `trig_01Jk2igfuAsju6aaCnT3bP28` | `trig_01YDoRNWzHxHCYzu4JNbndBF` | `30 19 * * 1,4` | `session_01XNp8CUjdh5nRaCYtk4LwgH (NEW)` |
| NY | `trig_014kvDg8x3JDqdWySvHxrREU` | `trig_013JEYxw1aScGLtMM5U4jQGw` | `10 11 * * 0,3` | `session_01NfXAHPAh7kopwE41JsxHco` |
| NC | `trig_018AHiDwHQLWm9DHxr96c9qB` | `trig_01LTqpYYhTxDkGGT2Wh9HfiB` | `50 10 * * 6` | `session_013QiZrvQ1aRnr3XasnXup6P` |
| AR | `trig_01DLRYTSBPvrst5LqGBv1M9M` | `trig_019oYYGcFgyhdjAK31gpgLHz` | `20 20 * * 0,4` | `session_01BM7Ytfp28iUZPtU7qt7fNg (NEW)` |
| WY | `trig_01F98Jr5do6PXbUzNLBGjzGE` | `trig_01TLrCKYYEtbJDFpTVP5wqgR` | `10 21 * * 2,5` | `session_018FWp2ecu3Zh4x3hVz8Zn7L` |
| MS | `trig_01Ugf2k1rcJiQVTtMhpnb4V3` | `trig_01PqAXjy7Qzn6RvDs1BcRQmh` | `40 9 * * 2,5` | `session_01U8L2MMXiXMRPWcEKS7iApG (NEW)` |
| SC | `trig_01R1pZjkPkQZWD3vctiAJQ44` | `trig_012GA6iXGN7w73vBDzBi5ZNF` | `30 8 * * 4` | `session_016YHpdTXtXghUFHx9Ec6oGt` |
| KS | `trig_01HYYurhCCUFATgTUuTqqjpn` | `trig_017s7QYQVFLWt1izwANpnwVP` | `10 8 * * 1` | `session_01EjF6i4tFDhf5RrU7to77tG` |
| WV | `trig_01SfWj74rQ4kdeHcdNckS4Yn` | `trig_011Mxg1TLki6YtL6fPxPV7EW` | `30 11 * * 5` | `session_018rTSHkoFHVzcdAFrFXrGQ1` |
| VT | `trig_01G7gMgmaRvkzdWq49YjZQdq` | `trig_01VyUei9ch5p8Sk4jfsoytyf` | `30 11 * * 2` | `session_01Wd4SYZ78GbLz7J8GfzyC7S` |
| CMS | `trig_01LUqkDnDGErLj9N8SJUDb1C` | `trig_01HnkrFiSq439YVXPUW8d4a7` | `0 13 * * 1,4` | `session_01V643Un4ty7ybFRiJrtHUTN (NEW)` |
| CO | `trig_012SyFT6QNtKsZK6veV5KznF` | `trig_01A89toGBkACsjzT3UWiXHEw` | `10 9 * * 1,4` | `session_011k27mZ4P3Bj7xWsDsGUhrn (NEW)` |
| VA | `trig_017UtAGMofDhy3h8kpVmmiEx` | `trig_01FDjCh4V5P1M8LFDXJQByoF` | `20 10 * * 2,5` | `session_01WPX6i174WWZnXNG3apRjW3 (NEW)` |
| ND | `trig_016DwLq1AKfmgKrFZtwPuPuK` | `trig_01J7goj6JA2gJjNL6ymtSnAX` | `20 9 * * 3` | `session_012ZNdeAk4RSvJkZBSk7rnRN` |
| WA | `trig_01Ya2pEVp2p89TYntNPhjpX1` | `trig_01MKPSWduxnZxzMTWMyJyUP9` | `10 10 * * 4` | `session_01D79su1xyoLgUT5Uvpf6A6G` |
| TN | `trig_01Bky7YZTFgaT2dZddvfNL4g` | `trig_01NFSkGzjLiGXe1LZYVzK2ba` | `30 9 * * 6` | `session_01KW4ksJMDj846hb5Py2uFyY` |
| DE | `trig_013VNzWcrr3sZKAgTgUTuEvL` | `trig_01Mv9EYfjVcswCuZLN2Pv86A` | `40 11 * * 1` | `session_018HApZfEPxtnu1hSndHkwQy` |
| ID | `trig_01HkxVsw4KoGkHpDwBCfve31` | `trig_01XSJj5cZuHWTUJhtSKkmQqq` | `40 12 * * 2` | `session_0192egjzDKcmEV11Xxp8W7tN` |
| OH | `trig_01VEe1KQEsuJRncwuoR8rQzJ` | `trig_01Q6q6ks4Fsr9LHyFteWuUyB` | `40 13 * * 3` | `session_01QsYgWjK2FTRqDanFhREpym` |
| SD | `trig_01PozmJvhJnKHVQf7GBHkbvY` | `trig_01A72yaSscmEqqToW4WpHziJ` | `20 12 * * 4` | `session_01Pk7gQk4SPRfFNY6u1VsNXn` |
| TX | `trig_017U35M4eGiGcnhPMeoKGzFy` | `trig_01GSsa3J1ibGjhCa7kgqwvYw` | `20 13 * * 5` | `session_01Su3qXCR46X98eD5JLV8Y5t` |
| NJ | `trig_012B9ZAHznUciD2roxYqkzbK` | `trig_01FepX1zDnUcEh3NZbHwbV9J` | `10 12 * * 6` | `session_01CjFShTEC5Ej7teMHGaXooL` |
| NEWSROOM | `trig_016FmK98AUDVtzPBGtE5VVh2` | `trig_01EKi4iGVgrgLfqk4cLNgLW1` | `50 16 * * 1,4` | `session_013BNYQ8xrdYo5a2GdgXt1Nw (NEW)` |
| IN | `trig_01UZ5QWh8No7uiRBz9S8T23C` | `trig_01FsVCDzD7N8pSMs6dzTnzSQ` | `50 9 * * 5` | `session_013ysrxChnfh9xCbAEQ7UyiG` |
| NE | `trig_01WDA8s6uzUSaCDF7DapUzX1` | `trig_01WL3yTThf5vXHqP8vkCfdNF` | `30 10 * * 3` | `session_01DmBcpgMaCLLDLCNcshwaFk` |
| NV | `trig_014c3kseN8WpCL5cMVcdaaYi` | `trig_01UHYF2PAcBJCBpJFtdocviC` | `10 15 * * 2,5` | `session_0194azxMDRmebsaQ9YtDZBVC` |
| MT | `trig_01YJFwwSQ1pEQEScfUfGzgSD` | `trig_019e4wVjfnazAh7AvYcr1yUN` | `40 17 * * 2,5` | `session_01GGJ61Ux7s4Zp1nGwTpRJLD` |
| NH | `trig_01D5rZ2KjtjmyXcRuVjNxQr4` | `trig_013kuBUJ39zAwF7SM7RYfwvk` | `10 18 * * 3` | `session_019SBzVqWVoWMmfsGEj57hwo` |
| OK | `trig_0195epZAcyF5L1WbYJYMQ5Za` | `trig_01MT1CVgVd1LZQbMpRoRMRGD` | `10 18 * * 4` | `session_01KCqoLtaJ3X9yGJG3XSvT2e` |
| MN | `trig_018tLxX82fNyKgxw5JkRw5PV` | `trig_01TkZG5yB5a1LnuBMv67tPEj` | `10 18 * * 5` | `session_01YMHRbw9ToET8yfpwSqg5bu` |

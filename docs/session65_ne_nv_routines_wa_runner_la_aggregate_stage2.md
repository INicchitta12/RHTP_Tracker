# Session 65 — NE and NV on Routines, the Washington runner, Louisiana's unnamed hospital count, Stage 2

Date: 2026-09-24. Zero RCJ quota. No state host fetched.

## 1. Nebraska and Nevada are on Routines

| State | Trigger | Runner session | Cron (UTC) | First firing | Why this cadence |
|---|---|---|---|---|---|
| NE | `trig_019qmwzbTMo9k83etPqjJV7z` | `session_01DmBcpgMaCLLDLCNcshwaFk` | `30 10 * * 3` (Wed) | 2026-09-30 | Weekly. DHHS has published no date for converting the 13 Initiative 5.3 intents or for a fourth notice. |
| NV | `trig_012WYj2vrKgD7oxuURp3ygCb` | `session_0194azxMDRmebsaQ9YtDZBVC` | `10 15 * * 2,5` (Tue/Fri) | 2026-09-25 | Twice-weekly. NVHA dates it: all BP1 subawards "finalized by October 1, 2026" and uploaded. Nevada went 72 → 155 named actions between two extractions. |

Both runners were created the way sessions 54–64 created theirs: repository source, outcome branch `main`, `claude-sonnet-5`, auto mode. Both are registered in `config/routines.csv` with `logging_since` equal to the trigger's creation time. Both prompts carry one change the other 33 do not have (section 2): **a GitHub or credential-service 5xx is retried** (6 attempts, backoff to 480 s) before the runner gives up.

## 2. Washington: the runner is not stuck. The 503 was transient, and neither recovery attempt could have reached main

**The 10:10Z firing.** Runner `session_01D79su1xyoLgUT5Uvpf6A6G` woke on schedule. Step 1 is `git fetch origin main`, which failed on a GitHub credential-service 503. The prompt had no retry path, so the runner followed its STOP instruction and wrote nothing (post-turn summary: *"GitHub credential service 503; cannot fetch; stopping"*). Other runners pushed before and after that time (SC 08:34Z, CO 09:12Z, CT 15:41Z, NEWSROOM 16:52Z), so the outage was short. The runner session is healthy, and its next scheduled firing (2026-10-01) will reach it.

**The re-fires are what failed.** `fire_trigger` on a Routine bound to a persistent session does **not** wake that session. It creates a **fresh** session (`origin = force_run_trigger`) whose `session_context` has no repository source and no push outcome. The 17:59Z re-fire I ran returned `session_017v5x7Yaf4GtQShmVNJJxjq` with exactly that shape. It went idle at 18:01Z with no commit on main. The WA runner's own `updated_at` did not move after the 17:32Z re-fire either. So a manual re-fire is the session-52 defect again (a Routine with nowhere to push). **It cannot recover a missed firing and should not be used for that.**

**What makes a 503 recoverable rather than silent:**
1. *Retry inside the run.* A 5xx is transient by definition. The NE and NV prompts retry fetch and push with backoff. WA's prompt could not be patched: `update_trigger` refuses a prompt change from any conversation except the Routine's own. It needs either that edit or a delete-and-recreate. A recreate changes the trigger id and needs a new `config/routines.csv` row.
2. *A backstop that names the miss.* `R/probe_coverage.R` did its job and named WA 10:10Z. The miss was never silent. It was unrecoverable, because the 6-hour grace window closed before anyone could re-run it through a session that can push.
3. *A way to close the red without forging a line.* `config/probe_gaps_explained.csv` (new) holds one row per diagnosed miss, with cause and evidence. The coverage assertion stops failing on that firing, but `--report` still shows it as **not logged**. A row with no evidence is refused, as is a row naming a firing that did log. Nothing was back-filled.

**One more miss is coming at 19:00Z today, and it is the CMS Routine's.** Its 13:10Z run fetched, then ran the full suite as its prompt requires, got "2 findings", and correctly committed nothing. The two failures are not in its summary. A re-run of the suite at main's 13:10Z head (`57d4ad6`) is reported in the commit that carries this doc. This one is **not** entered in the explained-gaps file. Its cause is a test failure, not infrastructure, and the failures have to be named before the gap can be called explained.

## 3. Louisiana: a count of hospital awards with no names enters no bucket

LDH's deck (as of 8/28/26) splits all 53 Rural Clinician Credit Bank awards by **funded facility type**: 20 "Hospital settings" awards, $6,285,515. That is 8 small rural hospitals ($3,291,553), 11 CAHs ($2,948,962) and 1 REH ($45,000). It names none of the 20.

**Decision: option (a), made a rule.** The figure is Tier 3 (these are awards made, not an eligibility list), so §0.3 is not what excludes it. It fails on three other grounds:

- **No bucket describes it.** `NAMED_HOSPITAL` needs a name to CCN-match and de-duplicate. `POOL_NAMED_HOSPITALS` needs named subrecipients. `POOL_UNNAMED_HOSPITALS` means an award to a pass-through **intermediary** whose class is restricted to hospitals (ICAHN). LDH's 20 are direct awards with no intermediary. Widening that code would put two different claims under one bucket figure, the error session 51 ruled out for tiers.
- **It cannot be carved out without double counting.** LDH never states a facility type for any of the five named awardees. So the 20 overlap the named rows by between 0 and 5 awards and between $0 and $1,965,788. If Ochsner Clinic Foundation ($1,500,000) were later typed a hospital, those dollars would sit in two buckets. The only overlap-free number is a derived floor on the 48 unnamed awards: 15 awards / $4,319,727. That is arithmetic across two tables, not a published figure.
- **Facility type is not recipient type (§0.3a).** The deck labels the *funded facility*, and the award ceiling applies per multi-entity system. A system can hold an award for a hospital site.

The figure is reported beside the partition as a state-reported aggregate and never summed into it. All awards are pre-agreement: CEAs were due 9/15/26. The same rule covers Missouri's "20 rural hospital projects", Connecticut's "four rural hospital systems" before their rosters landed, and Oklahoma's 11 lung-screening hospitals. It reopens only if LDH names the 20 or types the five. The queue row is `RESOLVED`, and a test in `test_03ae` pins the decision and the overlap arithmetic.

## 4. Stage 2 on the 2026-09-24 pull, after session 64's registry

Stage 2 last ran at 15:51Z. `non_rhtp_state_programs.csv` gained seven programmes at 17:25Z. Stage 2 was re-run at 18:06Z (`--run --date=2026-09-24`, 2 m 22 s):

- **87 records moved to `QUARANTINED`** (54 from PASS, 31 from FLAGGED, 2 already quarantined gained the flag). All are in the five states the new registry rows cover: **GA 42, TX 25, CA 8, DE 7, MI 5**. By tier, SUBAWARD quarantine goes 73 → 118 (+45), which is exactly the 45 Tier 3 rows the §6.2 sweep already listed. `provenance_sweep_flagged_rows.csv` now shows those 45 as `QUARANTINED` rather than PASS/FLAGGED. Row count is unchanged.
- Mining drops Georgia's ten Dual Track candidates. Clean Tier 3: GA 109 → 102, CA 4 → 0, TX 23 → 9.
- **Side effect, recorded:** re-running Stage 2 against the same pull resets `change_status`, so every record now reads UNCHANGED/WITHDRAWN and `stage2_change_set.rds` is empty. The 08-27 → 09-24 delta is not lost. `first_seen` is preserved (records first seen 2026-09-24 are the NEW set), and the delta as computed is at commit `b612701`. Consumers read only WITHDRAWN (280, unchanged).
- `R/02c` rebuilt byte-identical and `R/02b` moved only its status column. Full-suite results are in the commit message.

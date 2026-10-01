# Session 77: CLAUDE.md trimmed, the 09-29 check-in, Montana out of the queue

2026-09-29. Zero RCJ quota. The only live fetch was `R/03bl --probe`, which is
read-only and logged `interactive`. Nothing was back-filled into
`logs/probe_results.csv`.

## 1. CLAUDE.md trim

**What moved.** All of §10 "Current state" as it stood at `f9347ee` moved
**verbatim** to `docs/claude_md_history_sessions_01_76.md`.
- `cmp` of the moved text against the old §10 returns identical.
- The moved text covers the 40 KB "Last updated" paragraph, the session 5–29
  narratives, the reference-table essays, the Deliverable 1 prose and the
  1,115-line "Next session" list.
- The full CLI list also went to `docs/rerun_commands.md`.

**What did not move.** §1–§9 are byte-identical apart from two insertions: a
pointer line in §2.2a and three new entries in the §4 `docs/` listing. The
parity and wording tests that read `CLAUDE.md` (§0.4, §5's `OTHER` list, §7's
flow table) read unchanged text.

**New §10.** It keeps only what a session or a runner acts on:
- **Standing operational rules.** Every imperative that lived only in the
  session history is restated here: the overlay re-apply order and the
  bare-`--apply` bans, the two Alaska file constants, the never-sum and
  never-add rules, non-award files, status tables with no amount column,
  CRLF and diff hygiene, probe and evidence rules, and name-tripwire handling.
  The fifteen questions to ask before extracting a state are condensed from
  the twenty the history accumulated.
- **Current status.** Stages, the survey disposition, the hospital partition
  and a Deliverable 1 table. All are re-derived today from the committed files
  with the partition function, not copied from prose.
- **Current work.** Routines, open blockers and a next-session list of items
  that are still open.

**The copied table was stale in five places, which is itself a reason for the
trim.** The old Deliverable 1 table disagreed with the committed files:

| State | Old table | Committed files |
|---|---|---|
| KS | $52.2M | 37 / $62,416,473 (session 52 added Emerging Technology) |
| MD | $23.7M | 9 / $27,681,260 |
| GA | 108 rows | 126 rows |
| SC | 113 rows | 114 rows |

The table also had no rows for NJ, NY, WA, VA or IN GROW. The partition total
matched: `NAMED_HOSPITAL` 1,202 / $1,041,393,346.27 / 30 states.

**Size.**

| | Bytes | Lines | Tokens (est.) |
|---|---:|---:|---:|
| Before | 755,857 | 7,570 | ~190,000 |
| After | 122,387 | 1,866 | ~31,000 |
| Change | −84% | −75% | **−~159,000** |

The token figures use session 76's ratio (755,857 bytes ≈ 190k tokens, 3.98
bytes/token). They are estimates, not a tokenizer count.

**Cold-resume cost.** Session 76 measured ~355k tokens loaded per cold resume
with the old file. Removing ~159k gives **~196k per resume, −45%**. The rest is
tool definitions and the system prompt, which this repository does not
control.

**The epoch-3 runners.** They hold ~680k–713k. One more old-size load puts them
at ~1.04–1.07M, over the 1M window. One trimmed load puts them at ~0.88–0.91M,
under it.

**Caveat, stated before it is observed.** A persistent runner keeps its working
tree between firings (session 75). If `CLAUDE.md` is read from that tree at
cold resume, a runner loads the trimmed file only after a firing has fetched
`main` into its tree. On that reading, each runner's first firing after the
merge still pays the old ~355k, and the saving starts from its second firing.
If resume re-clones from `main`, the saving is immediate. Thursday's numbers
will tell which (§4).

## 2. The 09-29 11:15Z check-in

**MS and VA published under their new ids.**
- `eba2def`: MS, 2026-09-29T09:42Z, origin `trig_01PqAXjy7Qzn6RvDs1BcRQmh`.
- `9f0bbb0`: VA, 10:22Z, origin `trig_01FDjCh4V5P1M8LFDXJQByoF`.
- Both ids are the session-76 replacements in `config/routines.csv`.
- VT (`5bddd97`) and ID (`c569da2`) have also published under new ids since.

**The 33 originals are deleted.** `list_triggers` at 13:25Z returns 39
Routines:
- All 38 ids registered in `config/routines.csv` are present and enabled.
- Exactly one other: `trig_011pUVRNkSnjCNvZfQ89kPbM`, session 66's CMS id,
  disabled since session 75. It is not one of the 33.
- None of the 66 `old_trigger_id` values exists except that one.
- Every runner session carries exactly one ENABLED Routine (`trig_011p` shares the CMS runner, disabled), so each runner's
  step-2 check holds.

**Who deleted them.** `git log` holds no record of the deletion, because it
touches no file. The list is the evidence.

**Open.** Deleting `trig_011p` is optional tidying. It is left for the owner.

## 3. Montana

Montana meets Minnesota's test (session 76). Session 76 did not move it only
because the prompt named Minnesota alone.
- **Archive:** `data/evidence/MT/`, four pages, session 75.
- **Probe:** `R/03bl`, with tripwires on award sentences and on the loss of
  DPHHS's "funding decisions will be shared in September" line.
- **Routine:** `trig_019e4wVjfnazAh7AvYcr1yUN`, Tue/Fri 17:40Z.

**Run live first.** `RHTP_PROBE_ORIGIN=interactive R/03bl --probe` at ~13:30Z
reported **UNCHANGED on all four pages**. Montana is still a pre-award
negative.

**What moved.**
- `SURVEY_INVESTIGATED_NO_LIST_STATES` gains MT.
- Both tables were rebuilt: `rcj_state_survey.csv` changes one row, and
  `state_trigger_queue.csv` moves MT and renumbers ranks.
- The disposition goes **36/8/2/4 → 36/9/2/3**. `QUEUED` is UT, AZ and RI: 4
  candidates, $518,902,453.
- `test_03k` and `test_00b` are updated with the arithmetic in comments.

This is never a claim that Montana has awarded nothing.

## 4. The seven high-context runners

**Baseline, measured today with `get_session`.** No firing since session 76.

| Runner | Session | used_tokens | Next firing |
|---|---|---:|---|
| CMS | session_01VcVUvS86exr36LWfje45ak | 713,059 | Thu 10-01 13:00Z (new id's first) |
| AR | session_01WrjnFZj94uMMPCw3ao47Wz | 703,052 | Thu 20:20Z |
| KY | session_01UupwyaxGfXHSohdaVUWz9Z | 698,651 | Thu 19:30Z |
| NEWSROOM | session_01ERt22Gum5dQhrBUnG2aFRj | 695,803 | Thu 16:50Z |
| CT | session_01LSL8XWjJ7q7jR6PTinx61Y | 693,786 | Thu 15:40Z |
| CO | session_01KbB6uHdvUYpSK7CJLWXagJ | 686,366 | Thu 09:10Z |
| CA | session_01W2kJHuBuNkmMo2nfjBHZAR | 681,366 | **Wed 09-30 17:00Z** |
| MS (new data point) | session_01Dh3C5ccjWG6CXCLqdYZMKQ | 701,874 | Fri 10-02 09:40Z |

**MS confirms the per-resume pattern.** Its second firing on 09-29 took it to
701,874 at epoch 3, the same step as the seven.

**CMS's runner still shows the 09-28 halt summary.** That is its dirty tree.
The new prompt clears it at step 1.

**CA fires Wednesday, not Thursday.** It is read in the same Thursday check.

**Thursday's results are not in this document.** A self check-in is scheduled
for Thu 2026-10-01 after 20:30Z to read all eight and
`R/probe_coverage.R --check`.

### Thursday result, read 2026-10-01 ~20:50Z

**The eight runners in the table above no longer host these Routines.** In
session 79 all eight moved to new runner sessions on the v4 worktree prompt.
The old sessions have had no turn since this baseline; every `updated_at` is
unchanged. Their numbers are therefore not a measure of the trim. The
replacements were read instead:

| Routine | New runner | Firing | Line on `main` (own id) | used_tokens | Epoch |
|---|---|---|---|---:|---:|
| CA | session_01NGLsj2qtvSvBFse6LoZUTV | Wed 09-30 17:04Z | `3d3e7da`, trig_01JEYQK9… | 127,507 | 2 |
| CO | session_011k27mZ4P3Bj7xWsDsGUhrn | Thu 09:12Z | `646a377`, trig_012SyFT6… (TRIPWIRE) | 128,792 | 2 |
| CMS | session_01V643Un4ty7ybFRiJrtHUTN | Thu 13:00Z | **none: declined** | 142,499 | 2 |
| CT | session_0113Gzz6mRbmHG65ChNCenSc | Thu 15:41Z | `1a70ac5`, trig_01MkoE5F… (TRIPWIRE, opm) | 130,647 | 2 |
| NEWSROOM | session_013BNYQ8xrdYo5a2GdgXt1Nw | Thu 16:52Z | `bb5771a`, trig_016FmK98… (TRIPWIRE, DE + TX) | 131,194 | 2 |
| KY | session_01XNp8CUjdh5nRaCYtk4LwgH | Thu 19:39Z | `a9678a7`, trig_01Jk2igf… | 130,284 | 2 |
| AR | session_01BM7Ytfp28iUZPtU7qt7fNg | Thu 20:22Z | `cf2a1c7`, trig_01DLRYTS… | 129,511 | 2 |
| MS | session_01U8L2MMXiXMRPWcEKS7iApG | none yet (Fri 10-02 09:40Z) | — | 0 | 1 |

**Did any firing degrade?** No firing failed, compacted or ran out of context.
- **CMS declined to publish.** Its suite ran against `dda96da`, before PRs
  #83/#84 merged. Session 82 explained this in
  `config/probe_gaps_explained.csv`; the session 82 doc has the detail.
- **`R/probe_coverage.R --check` on `cf2a1c7`:** 57 due firings, all logged
  except 4 explained misses.
- **Three firings were TRIPWIREs** (CO, CT, NEWSROOM). Those are findings about
  the states, not runner failures. They are read in sessions 81 and 82.

**Was the trimmed CLAUDE.md loaded?** Yes, on every new runner.
- **Did it reach main first?** Yes. The trim reached `main` at `533a00f`,
  2026-09-29 13:36Z, before every firing above.
- **What the readings show.** A first v4 turn carries the whole start-up load
  plus one probe, and it sits at **127k–142k**.
- **Against the old runners.** The old runners' first turns sat at ~354k–389k.
- **What that means.**
  - The start-up load is about **225k–250k lower** than with the 755 KB file.
  - That is more than this doc's ~159k estimate. The trimmed file is 122 KB
    (~31k tokens), so the rest of the old load was not all `CLAUDE.md`.
  - Session 78 explained it: the old runners re-loaded `CLAUDE.md` when their
    own checkout changed it.
  - v4's worktree prompt removes that re-load (§2.2a).

**Not yet measured:** whether a v4 runner stays flat on its second firing.
The first points are CA on Sat 10-03 and CO, CMS, CT and NEWSROOM on Mon
10-05, per the session 81 doc.

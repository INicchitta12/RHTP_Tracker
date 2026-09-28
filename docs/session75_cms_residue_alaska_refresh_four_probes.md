# Session 75: the CMS Routine's residue, Alaska's 2026-09-28 refresh, and four new probes

2026-09-28. Three tasks. Nothing was back-filled into `logs/probe_results.csv`.

## 1. The CMS Routine's 09-28 13:02Z miss

**The mechanism is different from the 09-24 miss, but both come from the same event.**

The runner (`session_01VcVUvS86exr36LWfje45ak`) is a persistent session, so its
working tree survives between firings. On 09-24 the run fetched CMS's
DE/AR/SD releases, rewrote files under `data/raw/cms/`, `logs/` and the two
CMS reference CSVs, then failed the suite. Session 65/66 diagnosed that as
tests pinning exact state sets. Per its prompt, the run committed nothing.
Nothing restored the tree either.

Session 66 fixed the tests but did not clear the residue. On 09-28, step 1
found `git status` non-empty and, per the old prompt ("report the files and
STOP"), stopped before running the monitor. The platform recorded SUCCEEDED
anyway, because the wake had been delivered.

Evidence is the runner's post-turn summary: "pre-flight check failed:
uncommitted 2026-09-24 CMS data + probe logs; halted per step 1". I did not
read the transcript itself.

Left alone, every later firing would have stopped at the same step. The CMS
prompt, unlike the 32 state-probe prompts, had no rule for discarding its own
residue.

**What was done**

- **Prompt fix.** `update_trigger` refuses prompt edits from outside the
  runner's own conversation. The Routine was therefore recreated on the same
  runner as `trig_01HnkrFiSq439YVXPUW8d4a7`, with the same cron
  (Mon/Thu 13:00Z). Two changes:
  - Step 1 discards a dirty tree that lies wholly inside the Routine's own
    write set, then continues.
  - Step 3 restores the tree after a suite failure.
  
  `trig_011pUVRNkSnjCNvZfQ89kPbM` is disabled, not deleted.
- **Registry.** `config/routines.csv`'s `old_trigger_id` / `old_logging_since`
  now take a `;`-separated chain (`R/probe_coverage.R`). With only one
  predecessor slot, the 0174 miss would have lost its owner, and the gap file
  would have refused its own row. A test drives the chain.
- **Gap file.** The miss is explained in `config/probe_gaps_explained.csv`.
  `--check` passes; the firing falls due at 19:00Z today.

**Deadline.** This branch must reach `main` before Thu 2026-10-01 13:00Z. The
new Routine's step 5 runs `probe_coverage.R --check` from `main`, and without
the chain change and the gap row that check fails.

## 2. Alaska refreshed: 244 → 249 actions, the first withdrawals

| | 2026-09-21 | 2026-09-28 |
|---|---:|---:|
| award actions | 244 | 249 |
| total (preliminary) | $239,186,195 | $242,620,741.15 |
| hospital rows / dollars | 44 / $66,955,876 | **45 / $69,370,639** |

Alaska's week 7 table accounts for the 7 additions exactly. The state's
cumulative line prints "$242M" for $242.62M: truncated, where the 08-31
update rounded ($181.87M printed as "$182M"). The cycle check now accepts
either display form and nothing looser. The PDF's own six initiative figures
sum to $242.6M.

**Hospital effect: +1 row, +$2,414,763.** Components, reconciled to the dollar:

- Mat-Su Regional Medical Center, new: **+$5,000,000**
- City of Ketchikan, new: **+$350,000**. It ticked all 14 of Alaska's
  organisation-type boxes, "Hospital (all types)" among them; queued as
  `AK_KETCHIKAN_ALL_TYPES_TICKED` and not re-coded.
- ANTHC BP1-IA-034, **withdrawn**: −$1,603,406
- ANTHC BP1-IA-038, revised from $4,808,670 to $3,134,278: −$1,674,392
- Alaska swapped the Organization Type strings of ANTHC BP1-IA-033
  ($295,994, now out) and BP1-IA-035 ($638,555, now in): +$342,561

**Alaska's first withdrawals.** BP1-IA-034 (ANTHC, "Capacity and Bed
Management", $1,603,406) and BP1-IA-057 (Arete Family Care, $62,625). Both
were published in every earlier snapshot, and neither notice says why. They
are hand-read into `AK_WITHDRAWN`. The assertion now refuses any disappearance
not on that list, and refuses a listed id that reappears.

**Three code defects surfaced by the refresh**

- The classifier refused a new token, "Alaska Native Regional Corporation".
  It is mapped to `TRIBAL_ORG` at MEDIUM: never a hospital type, and ISDEAA's
  definition of "Indian tribe" includes ANCs.
- Revision notes were measured only against the 08-28 anchor, so a row first
  published later could never show a revision (BP1-IA-038's revision was
  silent on its own row). The baseline is now each row's earliest committed
  snapshot.
- **Session 49's verification overlay is keyed on row index, and Alaska
  reorders its workbook every week** (row 63 became row 153). A plain
  re-apply would have written eight answers onto the wrong awards. The eight
  surviving rows were re-keyed by App ID; Arete's row went with its award.
  None of the nine moves a hospital dollar either way.

`R/03bj --apply` changed only Alaska's row indices in its two sidecar files.
Every other state file is byte-identical. `NAMED_HOSPITAL` is now
**1,202 / $1,041,393,346.27 / 30**.

`trig_018fYZk2Dd9sui3WqmDMefwS`, the old Alaska Routine, is deleted.

**What the refresh moved downstream**

- **Rural cut.** Re-stated against the new partition and unchanged at
  214 rows / $181,492,481. None of Alaska's movement carries a source-backed
  rural designation.
- **RCJ dispositions.** The 09-24 pull read the 09-21 notice, so 13 Alaska
  candidates stopped matching. Three hand-read groups now cover them:
  - Alaska re-spelled six state-agency awardees ("…, Department of Health"
    became "… (DOH)") with the same App IDs and amounts.
  - Three awards were revised.
  - ANTHC had two figures revised and one award withdrawn.
  - Arete's award was withdrawn.
- **Completeness re-check.** It now excludes `AK_WITHDRAWN` from its "new
  awards". Otherwise Alaska's two withdrawn awards, which sit on its older
  08-29 download, would have been reported as `ROSTER_HAS_GROWN`.

## 3. Four probes: MT, NH, OK, MN

All four ran live and report UNCHANGED. None is on a Routine yet.

| State | File | Watches | Dated anchor |
|---|---|---|---|
| MT | `R/03bl` | DPHHS Grants, RFPs, home, Communications | EMS Equipment Grant ($4M): "funding decisions will be shared in September". The CIH pilot grant closed 9/15 |
| NH | `R/03bm` | FHC's GO-NORTH page, CDFA statement (nh.gov still 403) | CAH/Acute Care RFA "Coming Soon", although its own "late August" date has passed; Primary Care "Notification of Award (initial cohort): Late October" |
| OK | `R/03t --probe` | Funding Recipients, funding, home | None published. The existing award-index, pending-opportunity and lung-screening assertions now run on live bytes |
| MN | `R/03bn` | MDH grants, programme | None. The 94-hospital / 70% formula table must still read as eligibility (§0.3) |

**Oklahoma's probe has its own baseline** (`data/evidence/OK/probe_baseline/`).
Re-fetching the 08-31 extraction archive under the same names would change
bytes an extraction cites.

The first live run tripped the name diff on the funding page. On reading, it
was OSDH moving OSDE's PRIMS Project 695 (a school grant) from Active to
Closed and rewording "health care" as "healthcare". No award was involved.

**The shared watch digest is now whitespace-blind.** `rhtp_watch_archive()`
re-serialises adjacent inline elements with a space between them, so
Oklahoma's home page read CHANGED seconds after its baseline was taken. Names
and phrases still read the spaced text.

## What is open

- Put MT (twice-weekly), NH, OK and MN (weekly) on Routines, each on its own
  pushing runner, and register them in `config/routines.csv`.
- Minnesota now has an archive and a probe, which is the stated route out of
  `INVESTIGATED_NO_PROBE`. The disposition tables were not rebuilt here.
- Decide `AK_KETCHIKAN_ALL_TYPES_TICKED`.
- The 32 state-probe prompts clear only `logs/probe_results.csv` from a dirty
  tree. Any other residue would stall them the way CMS stalled.
- The CMS runner session is at 713k of 1M context tokens.

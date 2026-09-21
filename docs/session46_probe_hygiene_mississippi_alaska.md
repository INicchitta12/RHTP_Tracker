# Session 46 — the probes stop writing, Mississippi is extracted, Alaska is refreshed

**Date:** 2026-09-21
**Quota:** zero RCJ calls. Network: `resources.hhs.texas.gov` (6), `ldh.la.gov` (5),
`www.hca.nm.gov` (6), `governorreeves.ms.gov` (3), `mississippirhtp.com` (2),
`medicaid.ms.gov` (2), `health.alaska.gov` (3), throttled per §9.5.

---

## 0. The shape of the session

Three tasks, and the first one turned out to be the one holding up the other two.
Texas's probe had been corrupting its own evidence archive on every Routine
firing since session 19; Mississippi's, Louisiana's and New Mexico's had all
stopped running entirely. Fixing the apparatus came first because a watch that
does not run is a watch that reports nothing, and two of the three halted states
had moved while nobody could see.

---

## 1. A PROBE READS. IT DOES NOT WRITE TO THE EVIDENCE ARCHIVE.

`tx_probe()` opened with `tx_fetch_sources(force = TRUE)`. From session 19 until
today, every firing of the Texas Routine re-downloaded all eleven Texas sources
**into `data/evidence/TX/`** and rewrote the manifest.

The damage is not untidiness. `tx_validate()` reads the archive, so after the
re-fetch **the probe was comparing the live site against bytes it had just
downloaded**. It could only ever report that Texas had not moved. Had HHSC added
an "Awarded Grant Information" section to a Rural Texas Strong page, the probe
would have archived it first and asserted against it second, and **the tripwire
designed to fail the build would have passed on the roster it was watching for.**

A secondary effect: the archive's file names still said `2026-08-29` while the
bytes underneath them were whatever HHSC served that morning. A fetch date that
means "when the Routine last fired" rather than "when this document was read and
its finding written down" is not provenance.

`tx_probe()` now fetches into memory, compares a content digest against the
committed bytes, and runs the award-section check against the **live** text
(session 25's Indiana lesson). It probes the two STATE-funded control pages as
well as the four subjects, and fails in **both** directions: a Rural Texas Strong
page GAINING the section means Texas has awarded, and a control page LOSING it
means HHSC has renamed the thing we look for and the check has stopped meaning
anything. Ran live: all six content-identical, no roster, both controls firing.

### The guard, so it cannot come back

`rhtp_probe_run()` (`R/utils_config.R`) wraps every `--probe` CLI branch. It
snapshots `data/evidence/` around the probe — path, size and **mtime**, because
`force = TRUE` rewrote files whose bytes had not changed and a digest-only
snapshot calls that clean — and refuses if anything moved, naming the files and
saying what `--fetch --force` is for.

Two tests read the source of every file in `R/` on every run: one requires that
any file offering `--probe` routes it through `rhtp_probe_run()`, the other that
no `*_probe` function body calls a `_fetch` writer. Nothing caught Texas for
twenty-seven sessions because nothing looked.

### logs/probe_results.csv

Every probe now appends `state, probed_at, verdict, page, note`, committed
(§0.5). A Routine's answer that lives only inside a fired session transcript
costs a human the work of opening that session to read it.

Four verdicts, and the third is the one most easily lost: `UNCHANGED`,
`CHANGED`, **`TRIPWIRE`** (an assertion fired, so the probe stopped — logged
**and then re-raised**, because the throw is the signal), and `ERROR` (a refused
host or a timeout: a statement about our access, never about the state, §0.4).

The nineteen probes return four different shapes, so `rhtp_probe_rows()`
normalises them centrally rather than nineteen bits of glue each able to stop
writing the log quietly. One defect found while testing: `isTRUE()` is **not
vectorised**, so a first draft reported every page of a multi-page probe as
UNCHANGED — the one wrong answer a watch log must never give, because it is
indistinguishable from a quiet week. Pinned by a test.

---

## 2. THE THREE HALTED CONTROLS, AND TWO OF THE THREE STATES HAD MOVED

All three failed on a **dated anchor that had gone stale**, which is the
apparatus working: a figure that fails a check is a document to re-read, never a
check to loosen.

### LOUISIANA — LDH re-dated all seven windows

`la_assert_windows_passed()` pinned two literal phrases and their counts —
`"Late July to mid August"` ×3 and `"Mid to late August"` ×4 — and found **0 and
0**. Re-read, LDH's "IMPORTANT DATES" block now says **"End of September" ×6 and
"Mid-September" ×1**. Still seven windows against seven solicitations, still
every application "Closed", still not one named recipient. **So the negative is
unchanged and only its clock moved: Louisiana did not award, it slipped, by 30 to
46 days.**

The control is re-established on what survives, not on the words. Windows are now
**parsed** out of the block and each one's latest date **derived**, so a further
slip re-dates the finding instead of halting the Routine — while a window
disappearing, a solicitation re-opening, or the seven ceasing to match the seven
still fails hard. The thing worth protecting was never the phrase
"Mid to late August"; it was that every opportunity carries a published
announcement date.

**Which windows have PASSED is derived against `Sys.Date()`, never asserted.** On
2026-09-21 that is **one of seven** (Rural Clinician Credit Bank). The previous
version asserted all seven had passed; that was true when written and is now
false — a claim about a state read off a constant rather than off the state's
page (§0.4). `la_year1_status.csv` reads its `stage` and `announcement_window`
off the page on every build for the same reason.

**The slip is measured from two committed archives.** The 2026-09-02 snapshot is
kept as `programme_prior` rather than overwritten, because it is the only
evidence LDH ever published the July/August windows.

### NEW MEXICO — six Regional Hubs are SELECTED and NAMED

The halt was `NM_STATED$rinm_due`: "Submissions due: September 4, 2026" had gone,
because that date passed and HCA moved the row to "Currently under evaluation".
Ordinary, and not an award.

**What was underneath it is not ordinary.** HCA's page now reads: *"HCA has
selected six Regional Hub Organizations to lead Healthy Horizons across New
Mexico, with more than $74 million in regional funding"*, and names all six —
**three of them New Mexico hospitals** (Cibola General, Gila Regional Medical
Center, Nor-Lea Hospital District).

**AND `nm_assert_no_award_roster()` DID NOT FIRE ON IT.** Every one of its ten
phrases was checked against that sentence and not one matched: "selected
organizations" is not "selected six Regional Hub Organizations", and "selected
for award" is not "has selected". The tripwire whose whole job was to fire the
day New Mexico named a recipient sat quiet while New Mexico named six. A marker
list built from the phrasings a state has ALREADY used cannot catch the one it
uses NEXT, so the verb is now matched with its object left open, and the six hubs
are additionally pinned **by name** — a name cannot drift.

**SELECTED IS NOT AWARDED** (§0.3, Missouri's Hub Anchors) — and New Mexico's
selection is a step stronger than Missouri's, because HCA attaches a pool to it
where DSS attached nothing. What New Mexico still does not publish is a per-hub
amount, an executed contract, or a subrecipient; HCA's own next sentence is
*"Opportunities to engage in with Regional Hubs are forthcoming"*. **NOT
EXTRACTED — reported first, Arkansas's and Wyoming's footing.**
`nm_assert_hubs_selected_not_awarded()` fails the day a per-hub amount appears.

**SIX REGIONS ARE FIVE ORGANISATIONS.** HCA's 2026-09-18 release says it *"has
selected five organizations"*; UNM holds Regions 2 **and** 3. North Carolina's
ROOTS arithmetic exactly, and neither count is the other. Both are pinned.

### MISSISSIPPI — it announced, and the control had two faults at once

`ms_assert_governor_channel_control()` counted "announce"-shaped headlines and
required at least three. The newsroom is a "Load More" page whose static HTML
carries only its first few items, and exactly **one** now matched — so it failed
on ordinary pagination, on a threshold that was never measuring what it meant to.
And underneath that, the one matching headline **was Mississippi's own RHTP award
announcement**, which the control's second half would have caught had the first
half not stopped first.

---

## 3. MISSISSIPPI: 167 AWARDS, $104,115,146.80, THREE PROGRAMMES

The Governor's 2026-09-14 release names and prices every one of 167 awards —
recipient, county, amount and a one-line description per row — across the three
programmes the funding page had said were complete: **RTG 97 / $47,406,374.18**,
**RCGC 43 / $43,334,338.62**, **TCE 27 / $13,374,434**.

**Mississippi is the first state to LEAVE `INVESTIGATED_NO_LIST`**, which is
what that code is for: a re-checkable negative with a probe and a Routine
watching the channel the state itself named, which re-opened the state the day it
published.

### The reconciliation, and the $0.80

The 167 sum to **$104,115,146.80** against a stated **$104,115,146**. The
difference is exactly **$0.80** and it is **truncation**: nine rows carry cents,
those cents sum to $3.80, and the headline drops the remainder rather than
rounding it (which would have given $104,115,147). Nothing is corrected (§8) —
both figures are the state's own and both are pinned.

### THE TWO ODD-SHAPE ROWS, AND ONLY ONE COSTS A DOLLAR

165 of the 167 honour `<n>. <org> - <county> - $<amount> - <description>` exactly.

- **RCGC row 23**, *"North Mississippi Medical Center, Inc. - Lee County-
  $2,500,000"*. **The space before the hyphen is missing**, so the row carries
  two `" - "` separators where its siblings carry three. A parse that splits on
  `" - "` finds no amount and **drops the row**: 166 awards, $101,615,146.80,
  short by $2,500,000 — and short by the largest award in the section.
  **The total catches this one.**

- **RCGC row 30**, *"Northeast Mental Health - Mental Retardation Commission
  d.b.a. LIFECORE Health Group - Monroe County - $27,600"*. **The
  organisation's own legal name contains `" - "`**, so a left-to-right split
  reads the awardee as "Northeast Mental Health" and the **county** as "Mental
  Retardation Commission d.b.a. LIFECORE Health Group". **The money is
  untouched.** The row count is still 167, every total still reconciles to the
  cent, and the file quietly contains an organisation that does not exist in a
  county that does not exist.

**So the row count and the total agree on a defective parse, and the second
defect is invisible to both.** The parse is anchored on the amount and on the
county's own suffix; each mistake is driven by a test in the order a reader makes
it.

A **third** shape exists and is not a defect: TCE row 9 prints **"Lafayette
Co."** where the other 166 print "County". An anchor requiring the full word
silently drops it — one row, $300,000.

**LIFECORE holds two awards under two spellings** ("...Mental Retardation
Commission d.b.a. LIFECORE Health Group", $27,600; "Northeast Mental Health
d.b.a. LIFECORE Health Group", $30,610). They are **not merged**: §2 forbids a
machine resolving a fuzzy name match.

### The hospital figure

**68 named-hospital award actions, $47,454,812.18** — the third largest
single-state contribution in this repository, behind Georgia and Wyoming.

**167 award actions are held by 103 distinct awardee strings**, and Memorial
Health System alone holds twelve. One row per AWARD ACTION, not per organisation:
Michigan's lesson (session 27) taken as the default rather than learned again.

**The unstated-form question a TWELFTH time, and one-directional.** 96 of 167
rows / **$56,022,017.62** — 53.8% of everything Mississippi has awarded — carry
§8's standing fallback. Every one is already `No`, so **$47,454,812.18 is a
genuine FLOOR and $103,476,829.80 a genuine CEILING**. Several read as FQHCs or
physician practices to anyone who knows Mississippi (Delta Health Center, Aaron E
Henry, GA Carmichael, Mantachie Rural Health Care, Hattiesburg Clinic P.A. with
six awards). **NOTHING WAS PROMOTED (§0.4)**; queued as
`MS_RECIPIENT_FORM_NOT_STATED`.

**The descriptions are not used for typing.** A description describes an ACTIVITY
and §0.3a judges the RECIPIENT (Arkansas's precedent). A test requires every
`recipient_type` to be reproducible from the NAME alone.

### §6.2, on the CMS share

The release ties the 167 to RHTP in one sentence, and carries the footer session
44 found: *"totaling $205,990,180, with 99.96% funded by CMS/HHS
($205,907,220)"*. **The CMS share is parsed, never the headline** — the headline
is the allotment plus an $82,960 match. Dated 2026-09-14, nine months after the
NOA.

### The year is PARTIAL and Mississippi dates the rest itself

The release says the workforce and psychiatric emergency services initiatives
*"are currently being reviewed and will be announced in the next 30 to 45 days"*
— **2026-10-14 to 2026-10-29** — and that two further opportunities launch in
October. **$101,792,073 of the allotment is in no public roster.**
`ms_assert_remaining_tranches()` watches for exactly that, and deliberately does
**not** re-fire on the 167 already recorded.

---

## 4. ALASKA: 185 → 244 AWARD ACTIONS, $239,186,195

+59 award actions, +$57,314,828, **0 revised, 0 withdrawn**. Hospital rows go
**32 → 43** and hospital dollars **$49,686,225 → $62,396,425**.

### Alaska's own weekly table accounts for it exactly

Week 5 (32 projects, $27.1M) + Week 6 (27, $30.1M) = **59** — the diff of two
archived workbooks, stated independently by the state. Cumulative **$239M / 244
Projects** matches the parse.

**The single-week form of that control failed, correctly.** It compared the
growth against ONE week's row, which held only because every previous refresh had
landed exactly one week after the last. This refresh spans three weeks of
Alaska's calendar. It now sums the trailing weeks: the **count** exactly, the
**money** within a tolerance **derived from Alaska's own document** (each week is
printed to $0.1M, and Alaska's six weeks sum to $238.7M against its own stated
$239M — a $0.3M gap in the publisher's arithmetic that no reading of ours can
close). Requiring more agreement than the source has with itself is not rigour.

### Three constants had been doing two jobs each

- **`AK_PRIOR_FILE`** answered both "what did Alaska publish LAST time?" (must
  roll) and "which snapshot did CMS describe when it said 142 projects?"
  (2026-08-28, permanently). Split into `AK_CMS_ANCHOR_FILE`. Rolling the
  conflated constant would have moved the 142-project reconciliation onto a file
  CMS never described.
- **The Planning count** was asserted UNCHANGED — a true observation turned into
  a rule. **Alaska has resumed Planning awards, 19 → 26.** Re-based onto the
  anchor: the anchor's 19 is what shows CMS's 142 counts Implementation only; the
  current file may grow and may not shrink. The BP1-PL prefix check still agrees
  row for row.
- **The revision note** diffed against the rolling prior and named the snapshot
  pair in a hard-coded string, so this refresh would have **dropped Southcentral
  Foundation's +$4,306,887 note** — session 22's finding, silently gone.
  Revisions are now measured against the earliest committed snapshot and the
  dates are derived.

### Two new organisation-type tokens, and the classifier refused rather than guess

- **"Health Care Providers"** (3 rows) and **"Health care provider"** (1 row,
  alone) are SERVICE tokens: they say the awardee delivers health care, not
  whether it is a hospital, a clinic, an FQHC or a practice. Reading either as
  `HOSPITAL_OR_SYSTEM` would add hospital dollars on this pipeline's authority
  where Alaska stated only a class.
- **"Education Organization (Not Public University)"** is Alaska **re-wording its
  own token** — it printed "Education organization (Not public university in
  Alaska)" through 2026-08-31. Both exact strings are listed, because the earlier
  snapshots are still committed and still parsed. Not a fuzzy match.

**Provably inert on every other state:** all twenty-six other extractors re-run
and every reference CSV byte-identical, except Arkansas's `days_since_close`
(recomputed against today) — and nineteen xlsx renders differing only in
`dcterms:created`, reverted.

### And the completeness re-check learned that it can be the stale one

`recheck_ak()` compared the committed CSV against its own 2026-08-29 download and
alleged that **Alaska had withdrawn 59 awards**. It had not: Alaska is refreshed
on a weekly Routine while the re-check is re-fetched occasionally, so the
committed file is now newer than the re-check's own input. The staleness is
detected and reported; the withdrawal check still fires when the snapshot is
current. A stale input is a statement about this file, never about the state
(§0.4).

---

## 5. What moved

| | before | after |
|---|---|---|
| `NAMED_HOSPITAL` | 613 rows / $482,781,258 / 16 states | **692 / $542,946,270 / 17** |
| Alaska | 185 actions / $181,871,366 / 32 hospital rows | **244 / $239,186,195 / 43** |
| Mississippi | no award file | **167 actions / $104,115,146.80 / 68 hospital rows** |
| disposition | 25 / 9 / 6 / 10 | **26 / 8 / 6 / 10** |

`POOL_NAMED_HOSPITALS` (1 row, $18,156,856) and `POOL_UNNAMED_HOSPITALS` (1 row,
$50,008,264) are unchanged.

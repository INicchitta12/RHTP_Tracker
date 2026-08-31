# Session 22 — Georgia's 21 hospitals named, Alaska on a schedule, Maryland's question queued

**Date:** 2026-08-31 · **RCJ quota spent:** 0 · **Network:** 2 fetches to
`greathealth.georgia.gov`, 3 to `health.alaska.gov` (one of them a probe that
archives nothing).

Session 21's completeness re-check found two states publishing more than this
repository carried and deliberately extracted neither, leaving them as the first
two items of its "Next session" list. This session closes both, and finishes
Maryland's disclosure. **No state's published total moved. What moved is
$30,277,580 from a pool to twenty-one named hospitals, and Alaska's snapshot
forward by one weekly release.**

| | before | after |
|---|---:|---:|
| GA award actions | 139 | **158** |
| GA named-hospital dollars | $60,000,000 | **$90,277,580** |
| GA state total | $197,148,327 | **$197,148,327** (unchanged, and asserted) |
| AK award actions | 161 | **185** |
| AK published total | $160,701,975 | **$181,871,366** |
| AK hospital rows / dollars | 26 / $43,379,541.04 | **32 / $49,686,225.25** |
| MD | extracted, question undisclosed | **queued, $36,558,089** |

---

## 1. Georgia — the two aggregate rows are 21 named hospitals

**The rows they replace said what DCH's press release said, and DCH's press
release names nobody.** Phase 4 counts "13 hospitals" for surgical robotics and
"eight hospitals" for telepods; the committed file carried each as one aggregate
row reading *"names not captured"*, `recipient_confirmed = No`, `amount` empty.
Both cohorts are named in full on **signed Notices of Award** linked from
`greathealth.georgia.gov/find-funding-opportunities` — a page no session before
21 had opened.

```
Initiative 5  Workforce Retention Technology (Surgical Robots)
              13 hospitals x $2,000,000                     $26,000,000
Initiative 3  Care to Consumer Point-of-Care Telepods
              8 award actions across 7 named hospitals      $ 4,277,580
              -------------------------------------------------------
              21 award actions                              $30,277,580
```

**This is not new money and the code proves it rather than asserting it.**
`rhtp_ga_reconcile()` totals Georgia by summing distinct `(phase, initiative)`
pools and never by summing `amount`, so both strategies were already counted at
pool level. `GA_YEAR1_AWARDED <- 197148327` is now pinned as a literal and
asserted, because *"the total is unchanged"* is the claim a reader most needs to
be able to check without recomputing it. The residual is 9.92% of the CMS award,
also unchanged.

**Source strength goes up.** Every other Georgia row rests on an
`AGENCY_PRESS_RELEASE`. These twenty-one rest on a `NOTICE_OF_AWARD` — DCH's own
words, *"has awarded a grant agreement to the successful applicants listed
below"* — which is §8's strongest source type. They carry their own
`validation_source_type`, url and archive path, overriding the phase defaults
every other row inherits. `validation_source_type` was never vocabulary-checked
before, because every Georgia row was the same value; it is now.

**Parsed, never transcribed, and the geometry is why.** `ga_noa_award_table()`
reads the committed PDF through this repository's own reader and rebuilds the
table from the page's own positions: an award row is anchored on its
`GREAT-######` application number, and the applicant name is whatever sits in
the name column within that row's vertical band. Two things defeat a reader
keyed on line order:

- DCH **wraps** long names across two lines — `Hospital Authority of Stephens` /
  `County`, `Piedmont Mountainside` / `Hospital, Inc.`
- on one telepod row it paints **both name lines at the same y as each other**
  and the amount at a *different* y, so reading in paint order attaches
  `(Berrien County)` to the wrong hospital.

Banding on the anchor's y survives both. The band is bounded **per page**,
because the last row of page 1 is followed in document order by the first row of
page 2, whose y is far higher.

**The application number became a real column.** `application_id` is DCH's own
row key and is now on the record table rather than buried in free text — it is
what the completeness re-check joins on. Joining a roster on a hospital *name*
is how a re-check starts reporting a state as short: DCH writes
*"Coffee Regional Medical Center"* on one notice and *"..., Inc."* on the other,
and **Miller County Hospital holds two telepod awards**, so the name is not even
unique within one document.

**Confidence is MEDIUM, and that differs from the 87 AHEAD rows on purpose.**
§7 reserves HIGH for a named hospital **with a CCN match**, which this repository
cannot do yet (open blocker 5). These twenty-one are "primary source, hospital
identity inferred from name without CCN match" — §7's MEDIUM exactly, and the
coding session 21 gave Maryland's six. The 87 AHEAD rows were hand-coded HIGH in
session 10, before that reading was settled; they are **left alone** rather than
re-coded as a side effect of this change (§2.1), and the divergence is reported
on the Reconciliation sheet.

**DCH also names seven unsuccessful applicants with its reasons** — five on the
robotics notice, two on telepods. Nothing codes them; they are not awards. Their
**count is asserted**, because getting it right requires the
successful/unsuccessful section split to be right, and that is what the
twenty-one depend on.

**And one of the "unsuccessful" is an awarded Georgia hospital.** Wellstar MCG
Health Medical Center is on the AHEAD roster at $750,000 and was turned down for
surgical robotics (*"non-HRSA designated rural county"*). A test that excluded
the name outright would have deleted a real award to make a point about a
different one. "Unsuccessful applicant" is a fact about **one strategy**, never
about the hospital.

**Provenance: fetched again, not copied.** The bytes were already in session
21's re-check archive, which says of itself that it is not an extraction source.
Copying them across would move a file and call it provenance. Instead they were
fetched fresh into `data/evidence/GA/` and the digest of what came back is
**asserted equal to the digest session 21 recorded on 2026-08-29**. Both match.
That closes two things at once: Georgia's archive is a primary fetch with its
own date, *and* the document is proved unchanged between the re-check that found
it and the extraction that reads it. A mismatch is a hard failure.

**One invariant weakened deliberately.** `R/03d` made no network call at all
until this session. The test that asserted so is replaced by a narrower one that
matters more: every http call must sit inside `rhtp_ga_noa_fetch()`, so
`--validate` and `--build` stay offline.

---

## 2. Alaska — the first state that needs a schedule, not an extraction

**Alaska's award file is stale by construction and nothing was wrong with the
extraction.** DOH serves every week from one url that is overwritten in place.
Session 12 extracted 161 award actions; the same url now serves 185.

```
2026-08-28   161 award actions   $160,701,975
2026-08-31   185 award actions   $181,871,366
-------------------------------------------------
+ 24 NEW award actions           $ 16,862,504
+ 1 EXISTING award REVISED UP    $  4,306,887   Southcentral Foundation,
                                                BP1-IA-308, 1,548,208 -> 5,855,095
  0 withdrawn
```

**A revised amount is not a new award**, and counting it as one would invent an
award Alaska never made. `rhtp_ak_growth()` separates them and the revised row
says so in its own `determination_basis`. **No new vocabulary code was invented
for it**: `AMOUNT_PRELIMINARY` already means *"this may move"*, and this is that
happening. Alaska's own update: *"subaward budget finalization is still in
progress ... minor adjustments to award amounts may occur."*

**Both snapshots are committed.** A rolling file's growth is only measurable
against the snapshot it grew from, so `AK_PRIOR_FILE` keeps 2026-08-28 and a
test asserts it is still on disk.

### Two assertions that would have broken, and why neither was "fixed" by moving a number

**`AK_CMS_STATED_PROJECTS = 142` was right about a snapshot and wrong as a
standing invariant.** Session 12 asserted CMS's stated 142 projects equal to
Alaska's own Implementation count, and it was — which is what resolved the
161-vs-142 gap. The current file holds **166** Implementation rows. Re-pointing
the constant at 166 would have made the assertion pass and **thrown session 12's
finding away**. Instead the finding is asserted **where it is true** — against
the committed 2026-08-28 archive, offline, every run — and the current file is
required only to be a **superset** of it, with nothing withdrawn and the Planning
count unmoved at 19.

**The §6.2 ceiling was keyed on the wrong number, and the growth exposed it.**
It compared the preliminary total against CMS's *"$160 million"*, which is a
point-in-time count of what had been **announced**, not an allotment. A rolling
file necessarily outruns that, and it fired on money Alaska plainly has. §6.2's
actual rule is the allotment, so the ceiling now reads Alaska's **$272,174,856**
out of the §7.1 anchor rather than a typed literal (§0.2a). 185 awards are 66.8%
of it.

### The positive control is Alaska's own

Without it, *"the file got bigger"* is indistinguishable from *"we fetched it
twice and something changed"*. Alaska's **Year 1 Funding Cycle Update** prints
weekly cumulative counts — *"Week 4 | Aug 28 ... $16.9M ... 24 Projects"*,
cumulative *"$182M ... 185 Projects"*. `rhtp_ak_assert_cycle_control()`
**derives** those figures from the parsed rows, rounds them the way Alaska
rounds, and requires the results to appear in Alaska's text. The closure runs in
the direction that matters: the state has to agree with what this file computed.
The control PDF is fetched in the same pass as the workbook, so it can never be
one week older than the file it corroborates.

### The schedule

`R/03h --probe` is new: live, archives nothing, prints `UNCHANGED` and exits when
the digest matches. It is wired to Routine **`trig_01U4RxGWMH8yg37UKupHqTki`**,
Mondays 14:00 UTC, first run 2026-09-07 — Mondays because every Alaska
notification date so far is a Friday. The routine's prompt names the three
conditions that are **findings rather than bugs** (an award disappearing, the
Planning count moving off 19, Alaska's two documents disagreeing) and says
explicitly not to re-point `AK_CMS_STATED_PROJECTS`.

---

## 3. Maryland — the question that moves dollars in both directions

Maryland's 41 award offers were extracted in session 21; what was missing was the
**disclosure**. `MD_RECIPIENT_FORM_NOT_STATED` is now in
`data/reference/classification_review_queue.csv`, and
`md_assert_form_not_stated_queued()` asserts its presence, its dollar figure and
its options every run — Kansas's device, because a caveat in a workbook nobody
opens is not a disclosure.

**MDH publishes no organisation-type column**, so every `recipient_type` is
derived from the recipient's own name and 24 of 41 rows take §8's standing
fallback. **$36,558,089, against a named-hospital floor of $14,678,864 — two and
a half times the figure it sits beside.**

**And unlike Kansas it runs both ways**, which is the part worth reading:

| direction | rows | dollars | |
|---|---:|---:|---|
| understated | TidalHealth, Meritus Health Center | $8,494,458 | inside the 24, **not counted today**; §0.3a names TidalHealth as a hospital |
| overstated | Choptank Community Health System, Mountain Laurel Medical Center | $3,034,792 | typed `HOSPITAL_OR_SYSTEM` from their names, **counted today**, and on the ordinary reading FQHCs |

**Nothing was promoted and nothing was demoted** (§0.4). The CCN match resolves
it. An assertion also fails the day the uncertainty stops exceeding the figure,
because the sentence this repository publishes about Maryland would then have to
change.

Maryland moved to `EXTRACTED` in `rcj_state_survey.csv` and
`state_trigger_queue.csv`. **Nebraska (39 candidates / 35 awardees) now leads the
queue.**

---

## 4. The completeness re-check had to learn to say "closed"

`R/03q` asserted that Georgia still carried its two aggregate rows and diffed
Alaska against a **named evidence file**. Both were right on the day and wrong
the moment this session acted on them: **left as they were, the re-check would
have failed on the very extraction it asked for**, and would have gone on
reporting a 24-award Alaska gap that no longer existed.

- Georgia's check **flips**: every name and amount on both notices must now be
  *in* the committed file, joined on the application number, with no aggregate
  row surviving.
- Alaska's check compares against **`ak_year1_awardees.csv`** rather than a path,
  because the reference CSV is the thing whose completeness is in question.
- `ROSTER_EXTRACTED` was added to the finding set, deliberately. It is **not**
  `NO_ADDITIONAL_ROSTER` — that would be a false claim about what Georgia and
  Alaska publish. It means: the state published more than was extracted, and the
  repository has since extracted it, verified row for row.

**A re-check that only knows how to find gaps stops being a check the moment one
is closed.**

---

## 5. Where the hospital dollars stand

```
NAMED_HOSPITAL        : 380,179,820   GA 90.3M · AL 66.1M · OR 50.2M · AK 49.7M ·
                                      FL 49.3M · KS 35.7M · PA 24.1M · MD 14.7M
POOL_UNNAMED_HOSPITALS:  50,008,264   IL
```

`rhtp_hospital_total()` still refuses to return a combined figure, and **none of
these lines is comparable to another without reading its rows**: Georgia's 21 are
executed awards and its 80 AHEAD rows are stated per-recipient; every Alaska,
Oregon and Maryland figure is a preliminary or offered amount on a notice of
*intent*; Pennsylvania's are authorized and undisbursed; 45 of Alabama's are
rounded in the source; Kansas's and Maryland's are floors with a larger
uncertainty beside them.

**Tests: 2,116 assertions, all passing** (was 2,004), 1 self-skip. Zero quota.

---

## What this session did not do

- **The 7 unsuccessful applicants Georgia names are not extracted.** They are not
  awards. Their count is asserted; their names and DCH's reasons are in the
  archived notices for a session that wants them.
- **Nothing was promoted out of Maryland's 24 or Kansas's 22.** Both wait on the
  CCN match.
- **Georgia's 87 AHEAD rows were not re-coded to MEDIUM.** The §7 reading that
  makes the new rows MEDIUM arguably applies to them too, but re-coding
  committed hand-coded rows as a side effect of a different change is how §2.1's
  regressions happen. It is a deliberate open divergence, reported on the
  Reconciliation sheet.
- **The completeness re-check was not extended to KS, SD, TX and MD.** It found
  something in two of the seven states it covered, and there is no reason to
  think the four it does not cover are different.

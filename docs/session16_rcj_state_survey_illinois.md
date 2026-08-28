# Session 16 — the trigger list was not a census, and Illinois proved it

**Date:** 2026-08-28 · **RCJ quota:** zero · **Network:** Full (first session
under the new policy); 6 calls to `hfs.illinois.gov`, 2 to `icahn.org`, plus
search.

---

## The finding, in one paragraph

Illinois executed three grant agreements with the Illinois Critical Access
Hospital Network on **2026-07-31 for $50,008,264** — a quarter of its
$193,418,216.21 FY2026 allotment, and the largest single pass-through award
this project has recorded. CMS issued **no press release**. Stage 00's trigger
list is built from CMS announcements, so Illinois never entered the queue, and
**every state hunt in sessions 9–15 ran against the same nine states**. The
defect was never in `R/00`; it was in treating `R/00`'s answer as the list of
states worth looking at.

---

## Task 1 — the 50-state RCJ survey (`R/03k_rcj_state_survey.R`)

`data/reference/rcj_state_survey.csv`, 50 rows, ranked by Tier 3 candidate
count. Reads the committed Stage 2 record table — the §6.1/§6.2 product of
`data/raw/rcj/` — and cross-checks it against `awards.json` itself.

| | states |
|---|---:|
| Hold RCJ Tier 3 candidates | **38** |
| In the CMS trigger list | 9 |
| **RCJ_ONLY — candidates, no CMS release, never investigated** | **29** |

Top of the flagged list: **Oregon 386 candidates / 258 distinct awardees**,
Texas 68/67, Kansas 54/50, Maryland 42/41, Indiana 37/28, Oklahoma 35/25,
Nevada 34/34. Oregon alone has more distinct awardees than any state this
project has extracted.

**§0.1 governs every number in that file.** `rcj_federal_amount_sum` is an
unvalidated aggregator field and is **not a dollar figure** — it exists only so
a state holding one $1 record can be told apart from a state holding $160M of
them. There is deliberately no national total in the file, and an assertion
forbids a column named like one.

### The one consequential design choice

**FLAGGED Tier 3 records count as candidates; only QUARANTINED are excluded.**
Alaska's 159 Tier 3 records are *all* FLAGGED — every one of them
`SOURCE_DOCUMENT_UNRESOLVED`, which means the `/awards` row carried no
`sourceDocument.id`. That is a provenance gap, not junk: session 12 extracted
all 161 from Alaska's own workbook and they are real. **A PASS-only survey
would report Alaska at zero** and hide the fourth-largest state in the file. A
test pins it.

### Two defects the survey exposed

1. **`pull_date` is NA on all 5,152 rows of the committed record table.**
   `rhtp_normalize_pull()` did `dplyr::mutate(pull_date = pull_date)`, and
   under dplyr data masking the right-hand side resolves to the skeleton's own
   empty **column**, not to the function argument — a self-assignment that
   reports success. Nothing downstream had read the column, so nothing failed.
   Fixed at the source with `.env$`; **Stage 2 was not re-run**, because
   rewriting committed artifacts to satisfy a survey is a change with its own
   blast radius. The survey falls back to `last_seen` and *says which column
   answered*.
2. **The same trap, two files apart.** `sha256 = digest(file = file)` inside a
   `tibble()` that had just defined `file = basename(file)` resolved to the
   basename and failed on a file that existed. Both are now commented as the
   same shape.

---

## Task 2 — Illinois

### Has Illinois published a recipient-level award list? **No.**

| Source | Result |
|---|---|
| `hfs.illinois.gov/info/fedresctr/ruralhealthtp.html` | **Names no recipient.** |
| HFS programme update, 2026-03-09, 29pp | Names **intended** sub-awardees (ICAHN, IPHCA, CBHA, Carle Health, OSF, SIHF, OMI, ICCB, U of I System) against **preliminary** amounts, stamped *"for discussion purposes only"*. A **plan** (§0.3) — nothing coded from it. |
| `il.amplifund.com` — 3 RHTP solicitations | Open, unawarded, name nobody. Hospital Transformation: **$28,191,393 across 97 hospitals, distributed equally**, floor $290,000. Tier 2. |

**RCJ holds exactly one Illinois Tier 3 candidate: `MyOwnDoctor, LLC` at $1**, a
2025 Medicaid preventive-care contract that is not RHTP at all. Neither
discovery layer saw the $50M.

### The ICAHN record — `IL_year1_awardees.xlsx`, one row

Sourced from **ICAHN's own release**, admissible under §7, which admits a
*designated pass-through administrator's* document. That designation is
corroborated by the state itself: HFS's own programme update names ICAHN the
sub-awardee for these three initiatives, and **HFS's RHTP programme director is
quoted by name in the release**. First time this project has taken a §7 source
that is not a state agency; the reason is on the row.

**Structural corroboration, unarranged:** HFS's March plan names ICAHN as
sub-awardee on **exactly three** initiatives, and the release reports **three**
executed agreements.

**An arithmetic closure that is deliberately NOT published.** The release
states two figures — $50,008,264 total and $31,008,264 for technology. HFS's
plan gives Year 1 preliminary figures of $14M (disease prevention) and $5M
(workforce), and **$19,000,000 is exactly what the stated figures leave over**.
That closes to the dollar. It is on the workbook's *Three agreements* sheet
marked **`DERIVED - DO NOT PUBLISH`**, because it combines a plan with an award
release and §0.3 is precisely the rule against a planned figure becoming an
awarded one because the arithmetic works. **The row stays one row at
$50,008,264.**

### The separability problem — and why it needed code, not a note

This is the **first `PASS_THROUGH_DESIGNATED` award in the project** and the one
shape that can silently inflate the headline number. §10.2's test is met on both
clauses — the award to ICAHN **is executed**, and eligibility is **restricted to
hospitals only** (*"Critical Access Hospitals and other eligible non-urban
Illinois hospitals located in federally designated rural ZIP codes"*), not
hospitals *among* other eligible entities, which is what would make it
`PASS_THROUGH_UNRESOLVED`. So `distributed_to_hospital = Yes`.

**But no hospital is named, and on ICAHN's own account none has been chosen
yet:** hospitals *"will apply"* after a digital readiness assessment of the 78
eligible, and further detail *"will be shared as it becomes available."*

Every other hospital dollar in this repository sits on a row whose own awardee
is a named hospital. So:

- the row carries **`hospital_attribution = POOL_UNNAMED_HOSPITALS`**;
- **`rhtp_hospital_dollar_partition()`** in `R/utils_recipient_classification.R`
  returns the two figures separately, and **`rhtp_hospital_total()` refuses to
  return their sum** — the device `rhtp_ga_reconcile()` uses to make Georgia's
  wrong total unobtainable.

```
NAMED_HOSPITAL        : 243,006,884   AL 66.1M · GA 60.0M · FL 49.3M · AK 43.4M · PA 24.1M
POOL_UNNAMED_HOSPITALS:  50,008,264   IL — restricted to hospitals, none named
```

**The union test was wrong, and Illinois is what proved it.** It asserted that
every `distributed_to_hospital = Yes` row carries a hospital `recipient_type`.
That held for six states by accident of what had been extracted — all of them
awarded directly — and it encodes an assumption §10.2 never made. ICAHN is
`NONPROFIT_CBO` and `Yes`, correctly. The rule is now stated properly: a `Yes`
row is either a hospital recipient **or** a designated pass-through that names
its intermediary and declares itself a pool.

**And the partition itself had a bug worth recording.** Its first version keyed
on `flow_type` alone. Florida's file predates that column, so **all 15 Florida
hospital rows — $49,345,213 — were silently dropped** from the named bucket and
the output looked fine. It now keys on `recipient_type` as well and **hard-fails
on a `Yes` row that fits no bucket**, because a total quietly missing a whole
state is worse than the merged total the function exists to prevent.

### Three hospital counts, three universes

ICAHN membership **60** (56 CAHs + 4 other rural) · Technology Transformation
eligible **78** · HFS planning-grant eligible **97**. Not reconciled — they are
different sets and the sources say so. The brief's "56 CAHs plus four other
rural hospitals" matches ICAHN's *membership*; the money reaches a **different,
larger** pool.

### Evidence

`data/evidence/IL/` — ICAHN release, HFS programme page, HFS March update, with
a SHA-256 manifest that excludes itself. All three digests verified against the
files on disk by a test.

**The HFS page had to be reduced, and the guard caught it before anything was
committed.** `hfs.illinois.gov` embeds a store-locator
`<map-details api-key="pk.ey…">` — a Mapbox token, the same shape as CMS's and
Illinois' to publish rather than ours. It sits *inside* `<main>`, so unlike CMS
this could not be solved by picking a container: the credential-bearing node is
removed by name and the result is **asserted credential-free before writing**.
The manifest carries both digests — the archived reduction and the full page as
served — so provenance still closes. The other two are verbatim.

---

## Task 3 — the second trigger (`R/00b_state_trigger_queue.R`)

`data/reference/state_trigger_queue.csv`, 50 rows. A companion stage, not an
edit to `R/00`: stage 00 runs live twice a week on a Routine and fetches two
hosts, while this touches no network and reads two committed CSVs, so it can be
re-run by anyone, offline, and cannot break the monitor it consumes.

| `trigger_source` | states |
|---|---:|
| BOTH | 9 |
| CMS_ONLY | 0 |
| **RCJ_ONLY** | **29** |
| NEITHER | 12 |

**The queue goes from 9 states to 38, with 32 queued for investigation.**
Assertions enforce that the union is a **superset of each source** and
**strictly wider than CMS alone** — if the second trigger ever stops
contributing, the build fails rather than quietly reverting.

### What the union actually does for Illinois, stated honestly

It **queues it — but not for the right reason.** Illinois enters as `RCJ_ONLY`
on that single $1 non-RHTP record, which ranks it near the *bottom* of the
queue. The union widens the net; it did **not** make the net fine enough to
catch this award on its merits. Overstating that would be the same error in the
other direction.

**Florida is the unmixed case:** no CMS release, no surviving RCJ Tier 3
candidate, **81 extracted awards already in this repo**. So `NEITHER` means
*"no discovery layer flagged this state"* and **never** *"this state has
awarded nothing"* — and an assertion requires at least one EXTRACTED state to
remain in that bucket, so the warning cannot rot into a claim of completeness.

---

## Tests

**1,375 assertions, all passing** (was 1,178), one self-skip. Three new files:
`test_03k_rcj_state_survey.R`, `test_03l_il_year1_awardees.R`,
`test_00b_state_trigger_queue.R`; `test_state_union.R` extended to eight state
files with the separability invariant.

## What this leaves for the next session

**29 RCJ_ONLY states are queued and none has been investigated.** Oregon is the
outlier by an order of magnitude — 386 candidates, 258 distinct awardees — and
is the obvious next state. **No extractor was built for any of them**, per the
instruction not to build for states not confirmed to have published lists.

Illinois' own next step is the **97-hospital, $28,191,393 planning-grant
solicitation** on `il.amplifund.com`: that is how Illinois hospitals get
*named*, and an award list there is a real extraction.

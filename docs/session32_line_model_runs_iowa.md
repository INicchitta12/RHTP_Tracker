# Session 32 — the line model carries runs, and Iowa is extracted

Zero RCJ quota. 14 fetches to `hhs.iowa.gov` and `governor.iowa.gov`, throttled
per §9.5.

Two tasks, in the order the second depends on the first: fix the PDF reader so a
table's columns survive, prove it moved no committed figure, and only then read
Iowa.

---

## 1. `rhtp_pdf_lines()` broke lines only on VERTICAL movement

Session 21 replaced "a line is a `Td`" with "a line is a text POSITION", which
is what made Maryland readable — its producer emits a `Td` per glyph, so the old
model returned one character per line. The replacement broke a line **only when
the position moved down**, and that is the half that was wrong: two table cells
painted at the same `y` in different columns merged into one string, and only
the first `x` survived.

On Iowa's notices that yields

```
Adair County Memorial Hospital Greenfield
Mercy Health Services-Iowa, Corp. Dubuque
```

— the county welded onto the organisation. **That is session 21's own failure
one column over** (*"Crisp Regional ospital"*), and §0.4 does not allow it in a
recipient field.

### The fix: the scanner emits RUNS and the line model is composed from them

```
rhtp_pdf_run_table()      the one reader -- every run, untrimmed, content order
rhtp_pdf_runs()           the run view, for a column that is a FIELD
rhtp_pdf_compose_lines()  runs -> lines, over any subset
rhtp_pdf_lines()          compose(run_table)
```

A **run** ends wherever the pen moves. A **line** still ends only where it moves
down. Each run carries a `line` id that advances on **exactly** the condition
that used to flush a line, so grouping runs by it reproduces the old output *by
construction* rather than by coincidence — and `rhtp_pdf_lines()` keeps its
signature, `page, x, y, text`, with a line taking the position of its first run.

**Nothing thresholds a gap and nothing reads a vocabulary of county names.**
Iowa's own producer paints `Adair County Memorial Hospital` at x=77.664 and
`Greenfield` at x=311.470; the split is where Iowa put it. That mattered:
18093's second column mixes counties with **cities** — Greenfield is the seat of
Adair County — so a county vocabulary could never have closed it.

### The text is NOT trimmed at run level, and that is measured

**199 of Iowa 18093's 328 runs end in a space and 150 are nothing but
whitespace.** Trim each run and then paste them and `"Notice of Intent to "` +
`"Award"` becomes `"Notice of Intent toAward"` — two words welded, the same
class of defect as the merged columns. So runs come back as painted, callers
paste first and trim after, and `rhtp_pdf_compose_lines()` does exactly that for
any subset. A test positive-controls the contract by requiring such a run to
exist.

### Verified twice over, before Iowa was touched

| Check | Result |
|---|---|
| all 41 committed PDFs, `rhtp_pdf_lines()` old vs new, row for row | **`page`/`x`/`y`/`text` IDENTICAL on all 41** |
| all nine PDF-reading states rebuilt — KS, MD, GA, NE, IN, OK, NV, MO, WI | **all 55 files under `data/reference/` BYTE-IDENTICAL** |
| the eight xlsx renders | differ **only** in `dcterms:created`; reverted, as in sessions 19, 21, 25, 26 |

**Maryland is why the merge was preserved rather than replaced.**
`md_read_primary_care()` reads a table *"whose columns are too close to
separate"* by splitting the pasted line on its own dollar figure. It wants the
line, not the runs. A reader that simply started breaking on `x` would have
taken all eight of its rows out.

---

## 2. Iowa — ELEVEN notices, 264 award actions, and NOT ONE PRICED

Iowa brands RHTP **Healthy Hometowns**. Its programme page carries a
**"Where to Find Funding Awardees"** section linking **eleven Notices of Intent
to Award across nine RFPs** — no other state in this repository publishes an
awardee index of that shape.

```
264 award actions · 10 operative notices · 151 distinct awardees
152 named-hospital award actions · $0 of named-hospital dollars
```

### It is NEVADA'S SHAPE and the largest instance of it

Every recipient is named; **not one notice carries a per-recipient amount**.
Each holds exactly ONE dollar figure and it is in the CMS financial-assistance
footer. So `amount` is empty on all 264 rows, `sum(amount)` is 0, and **152
named-hospital award actions and $0 of named-hospital dollars are both true at
once**. `ia_assert_zero_dollars_is_not_zero_hospitals()` makes it impossible to
report the 0 without the row count. **Read the row count**: down the dollar
column alone Iowa is invisible.

### §0.2 INSIDE ONE DOCUMENT SERIES, WHICH IS NEW

The footer's grammatical subject is the RFP or the programme — *"This Centers of
Excellence is supported by…"*, *"This RFP #PHTHORC26012 … is supported by…"* —
which is session 27's **strong** form. **Its amount is not one tier.**

| Footer amount | Notices | What it is |
|---:|---:|---|
| $50,000,000 · $66,002,161.80 (×2) · $15,128,000 · $12,600,000 · $6,000,000 ×3 | **8** Jan/Feb | the RFP's own **pool** (Tier 2) |
| **$209,040,063.71** | **3** June-18 | **Iowa's CMS state allotment** (Tier 1) |

Iowa's footer practice changed between February and June, in the same template,
with no other signal. **Summing the eleven gives $854,852,514.73 against a
$209,040,063.71 allotment.** Virginia's and New Hampshire's §0.2 lesson, for the
first time spread across a document *series* rather than sitting on one page.

*(Session 31 recorded this as "seven Jan/Feb / four June" and ≈$845.8M. The
counts are **8 and 3** and the sum is **$854,852,514.73** — corrected here from
the documents rather than carried forward.)*

**So no footer figure enters the award file at all** — not even `round_amount`,
where Nevada's and South Dakota's pool totals live. They are recorded document
by document, with the tier each carries, in **`ia_notice_footers.csv`**, and
`ia_assert_footers_not_summable()` pins the trap open. A pool figure this
project cannot attribute with confidence is not a figure to publish (§0.4).

### THE NOTICES NEVER NAME THE PROGRAMME

*"RHTP"*, *"Rural Health Transformation"* and *"Healthy Hometowns"* occur
**zero times** across all eleven — Kansas's problem, in a state whose documents
are otherwise the strongest source type available. Measured every run. The
provenance is carried by three **programme-scoped** sentences on Iowa's own
page, plus **two further publishers**: the Governor's 2026-01-30 release
(*"Iowa first in the nation to award Rural Health Transformation Program
funding"*) and Iowa HHS's 2026-06-18 release, **which re-publishes one whole
notice's roster**. Every notice is dated after the 2025-12-29 Notice of Award,
and each states its own date.

### Two independent readings say the parse is right

- **RCJ's ten Centers of Excellence names match this file's roster NAME FOR
  NAME, all ten** — a commercial aggregator that never saw this parser, reading
  the same PDF.
- **RCJ names `Cass County Memorial Hospital DBA Cass Health` in full**, and the
  notice sets it across **two lines**. That is an external check on the
  wrapped-cell join, which is the part of the parse most likely to be wrong.

Both are assertions, not observations.

### Two joins, and they are not the same join

Runs painted at one `y` concatenate with **nothing** — Iowa splits *"Veterans"*
into `"Ve"` and `"terans"`, and sets *"Iowa Specialty Hospital"*, `"-"` and
*"Clarion"* as three runs on one line. A cell that **wraps** joins with a
**space**, because Iowa wraps at word boundaries. It is deliberately not in the
shared reader: **Kansas wraps mid-word** (*"Citizens Foundat"* / *"ion:
$146,476"*), so a space at every break is right for Iowa and wrong for KDHE.

### ONE name this reader cannot read, and it is recorded rather than guessed

The 2026-02-27 re-issue of PHTHORC26009 sets *"St. Joseph's Mercy Hospital DBA
MercyOne Centerville Medical Center"* across a break between `MercyOne` and
`Centerville` that falls **inside one drawn line** — two runs at one `y`, no
space glyph. **The geometry cannot decide it, and that is measured**: `Ve` →
`terans` advances 14.8 points for two characters, `MercyOne` → `Centerville`
advances 4.9 for eight, which is impossible as a real advance, so the reader's
`x` is not tracking a pen movement there and no rule over `x` separates the two
without font metrics this reader does not have.

**What decides it is Iowa.** The same award, the same RFP, in the notice this
one re-issues, is set on a single line and reads *"MercyOne Centerville Medical
Center"*. Both strings are the State's; one is unambiguous; both documents are
archived. `IA_NAME_FROM_SUPERSEDED` is **one entry**, the row carries
`RECIPIENT_NAME_FROM_SUPERSEDED_NOTICE` and says so in its note, and
`ia_assert_supersession()` compares the two rosters **after** the repair — so a
second such name fails the build instead of being absorbed into the exception.

### Supersession: 18330 replaces 18093

Both are PHTHORC26009. The February re-issue is the January roster **plus
Marengo Memorial Hospital** — asserted, name for name. Counting both would
invent a roster Iowa never issued. Both stay archived: a re-issued roster's
growth is only measurable against the one it grew from.

### One name Iowa spells two ways, recorded and not resolved

The notice writes *"Mary Greeley Medical Center"*; the 2026-06-18 release writes
*"Mary Greely Medical Center"* — two of Iowa's own publications, one character
apart, on the same award. **Nothing is normalised** (§2 forbids a machine
resolving a near-identical name). The notice is the award document, so its
spelling is what the file carries; the divergence is a named entry, and an
assertion fails if a **second** appears **or if this one is corrected**.

### §0.1 — the names are right, the money is a placeholder, the coverage is 2 of 11

Of Iowa's 15 Tier 3 candidates, **10 are the Centers of Excellence roster at
$0 each** and **5 are Best and Brightest rows at $1 each**; all 15 carry
`AMOUNT_IMPLAUSIBLE_LOW`. Missouri's placeholder mechanism, on a state whose
names the aggregator gets **exactly right**. And **Iowa ranked FIRST on the
RCJ_ONLY queue with fifteen candidates and has published 264 award actions** —
Michigan's twelfth question again: a low candidate count is not evidence that a
state has published little.

### The unstated-form question, an EIGHTH time — and worth $0

Iowa publishes no organisation-type column, so every `recipient_type` is derived
from the recipient's own name and **102 of 264 rows carry §8's standing
fallback**. Like Nevada's it is worth **$0 in either direction**, because there
are no amounts at all: the question moves a **COUNT**, which is the only
hospital quantity Iowa supports. **Nothing was promoted (§0.4).**

### The positive control

Iowa demonstrably publishes rosters in a recognisable form — one Notice of
Intent to Award link per awarded RFP, under one heading — so
`ia_assert_award_index()` requires all eleven to be linked and **a twelfth is a
new roster to read**, not something to ignore. And
`ia_assert_no_per_recipient_amounts()` refuses the day a dollar figure appears
inside a roster: `ia_year1_awardees.csv` must then be **rewritten, not
patched**, because its empty `amount` column is only honest while that column
does not exist in the source.

---

## What did NOT change

No committed hospital figure, in either direction, for any state. The nine
PDF-reading states rebuilt byte-identical, and Iowa adds **152 named-hospital
rows and $0** to `NAMED_HOSPITAL` — so the dollar total is untouched and the
**row count is what moved**.

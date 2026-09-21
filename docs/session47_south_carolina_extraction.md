# Session 47 — South Carolina extracted: 228 awards, $167,299,900.69, and the first state to leave `INVESTIGATED_NO_PROBE`

**Date:** 2026-09-21
**Files:** `R/03ao_sc_year1_awardees.R`, `tests/testthat/test_03ao_sc_year1_awardees.R`,
`data/reference/sc_year1_awardees.csv` (228 rows), `sc_year1_status.csv` (9),
`sc_rcj_candidate_disposition.csv` (1), `data/evidence/SC/` (5 documents)
**Quota:** zero RCJ calls. Nine fetches across `www.scdhhs.gov` and `www.cms.gov`.

---

## 1. The headline

South Carolina holds **$200,030,252** (§7.1) and has awarded **$167,299,900.69**
— **83.6%** — across **228 named, priced award actions** in **8 projects** under
**4 initiatives**. The source is *"SC RHTP Year 1 Award List"*, an eight-page PDF
SCDHHS posted to its grants page on **2026-09-15**.

**It is the first state to leave `INVESTIGATED_NO_PROBE`, and it left the way
that code's own note said it would — by the state publishing rather than by
anyone writing the missing probe.** Session 43 put South Carolina there
deliberately: `INVESTIGATED_NO_LIST` would have promised a re-checkable negative
this repository did not have, *and* would have been false about the stage, since
SCDHHS had already issued Notices of Award Determination on 2026-07-31 (bulletin
MB# 26-026) and told the recipients **by email**. So when the roster appeared,
**nothing had to be retracted.** South Carolina went
`INVESTIGATED_NO_PROBE` → `EXTRACTED` without ever passing through
`INVESTIGATED_NO_LIST`.

The 50-state disposition moves **26 / 8 / 6 / 10 → 27 / 8 / 5 / 10**. Both tables
were **rebuilt** from `R/03k`'s constants, never hand-edited; the only
substantive change is South Carolina's row, and everything below it shifts one
rank.

---

## 2. The three counts, and they are not each other

| | |
|---:|---|
| **228** | award actions — the rows the list prices, and this file's row count |
| **130** | distinct awardee **strings** — an *upper bound* on organisations |
| **8** | projects — the grain the list numbers, restarting at 1 each time |
| **4** | initiatives — the grain SCDHHS names on its programme page |

**Organisations repeat heavily and across projects.** Newberry County Memorial
Hospital holds **twelve** awards across **four** projects; Self Regional
Healthcare (Lakelands Region) **eleven** across **five**; Hampton Regional
Medical Center **ten** across **four**. A reader taking 228 as an organisation
count is wrong by nearly a factor of two; a reader de-duplicating the rows loses
tens of millions of real awards. Michigan's lesson (session 27) as the default.

*(The task brief said Newberry appears three times. Measured, it is **twelve
rows across four projects** — the point holds a good deal harder than stated.)*

**And 130 is an upper bound, not a count.** The list spells several bodies more
than one way: *"Allendale County Hospital"* / *"… (ACH)"*, *"Carolina Health
Centers, Inc."* / *"… (CHC)"*, *"Low Country Health Care System"* / *"…
(LCHCS)"*, *"Tandem Health SC"* / *"… (THSC)"*. §2 forbids a machine merging
them, so they are recorded as published.

---

## 3. THE TWO MISSISSIPPI DEFECTS WERE LOOKED FOR, AND BOTH HAVE AN ANALOGUE

Session 46 found two odd-shape rows in Mississippi's release: a **missing space**
that dropped a $2,500,000 row (the total caught it), and an **organisation whose
legal name contains `" - "`**, which misassigned a name and a county while every
total still reconciled to the cent. Both shapes were searched for here.

### 3.1 The missing-character defect is present, and it is in the row number

**Healthcare Workforce row 2 is printed `I2`** — a capital letter I where a digit
belongs, painted at x=79.56 where every other one-digit number sits at 82.68.

A parser keying rows on `^[0-9]+$` in the number column **drops Rebound
Behavioral Health and its $120,000**: 227 rows, and the total short by that much.

**The total would catch it — which is exactly why this file does not rely on the
total.** Rows are anchored on the **amount** column, so the parse never depended
on the number at all; the numbers are used instead as the **completeness check**
— every project must number 1..n with no gap.

**And that distinction is load-bearing here in a way it has not been in any
other priced state, because THIS DOCUMENT PUBLISHES NO TOTAL OF ANY KIND.** No
grand total, no subtotal, no `Total:` row. Arkansas reconciled to its own
`Total:` row and Mississippi to the Governor's stated figure; South Carolina
states nothing, so `$167,299,900.69` **is** the sum of the rows and reconciling
to it proves nothing on its own. What makes it a reconciliation is that three
facts come from outside the arithmetic:

- **CMS independently states the count**: *"The RHTP funding will support **228
  grants**"* (2026-09-17), from a publisher who did not write the list.
- **CMS's headline is $167 Million**, which the sum rounds to.
- **Every project numbers 1..n with no gap**, which a total cannot tell you.

The `I2` row is **recorded, not corrected** (§8), and the assertion accommodates
it by name — so the day SCDHHS re-posts a corrected list, that is a re-read
rather than a silent pass.

### 3.2 The hyphen defect is present, is the INVERSE of Mississippi's, and costs a NAME rather than a dollar

South Carolina's hyphens are painted as **separate runs with no spaces around
them**:

```
x= 99.90  "Prisma Health"
x=173.40  "-"
x=177.48  "Upstate (Oconee, Lee, and Laurens)"
```

There is no delimiter split here to break, so **no dollar moves and no total
notices** — Mississippi's LIFECORE row in a state that publishes no county
column. What breaks instead is the **name**, in either direction depending on
how the runs are joined. Pasting with a separator invents *"Prisma Health -
Upstate"*; pasting another row's runs without one **loses a real space**, because
on page 7 *"Self Regional"* and *"Healthcare (Lakelands Region)"* are also two
runs and there the space belongs.

**So neither constant separator is correct, and the answer was measured rather
than chosen.** The PDF's own `/Widths` array gives Aptos a space of 203/1000 em
and a hyphen of 340/1000; the observed hyphen advance is 4.08pt, so the type is
12pt and a space is 2.436pt. Against that:

| run | width | gap to next run | residual | verdict |
|---|---:|---:|---:|---|
| `Prisma Health` | 73.464 | 73.500 | **+0.036** | no space |
| `Self Regional` | 67.284 | 69.720 | **+2.436** | exactly one space |
| `(Anderson` | 53.328 | 53.280 | **−0.048** | no space |

**45 within-line boundaries were measured. 43 carry no space (worst residual 37
em-units) and 2 carry exactly one (205.6 and 209.8 against a space of 203).** The
two populations are separated by more than five times the noise, and
`sc_assert_no_positioning_space()` asserts *that separation* — a claim the
document can falsify — rather than a tolerance chosen to make today's numbers
pass. Anything landing near the midpoint is **refused**, because a boundary this
test cannot read is a name this project cannot spell.

**THE RESIDUAL IS KERNING, NOT ERROR, AND THAT IS WORTH RECORDING.** A `/Widths`
array gives each glyph's own advance and says nothing about the pair adjustments
the producer writes into its TJ arrays, so a long run's measured advance falls
short of the sum of its widths by a few hundredths of a point per kerned pair —
and the residual rises with run length, exactly as accumulated kerning would. A
fixed tolerance was the wrong shape; a separation claim is the right one.

**AND THE READER WAS ALREADY RIGHT, WHICH IS THE PART TO KEEP.**
`rhtp_pdf_run_table()` returns the producer's **space runs as runs of their own**
— there *is* a run of a single space between *"Self Regional"* and
*"Healthcare"*, and there is *not* one between *"Prisma Health"* and *"-"* — so
pasting a line's runs with `collapse = ""` reproduces the rendered text exactly.
Session 32 warned that a run boundary can be pen positioning rather than a space
glyph and that the fix would be glyph widths; **on this producer it is a glyph,
and the widths are used to PROVE that rather than to repair anything.**

### 3.3 What the measurement found that nothing else would have: THREE spellings of one organisation

Nineteen rows name a Prisma Health entity, and the prefix is printed **three
different ways**:

| rows | spelling |
|---:|---|
| **17** | `Prisma Health-Upstate (Laurens)` — hyphen, no spaces |
| **1** | `Prisma Health- Upstate (Anderson)` — hyphen, then a space |
| **1** | `Prisma Health (Oconee)` — a space, no hyphen |

The same thing happens once more in the SCDBHDD block with the hyphen and the
space swapped: *"(Aiken Barnwell Mental Health Center)"* on one row and
*"(Aiken-Barnwell Mental Health Center)"* on another.

**The first two are only distinguishable because the spacing was measured.** Both
are painted as three runs, and the whole difference is whether SCDHHS painted a
space run after the hyphen. A reader pasting with a separator prints all
eighteen as *"Prisma Health - Upstate …"*; one stripping whitespace before
pasting prints all eighteen unspaced. **Either way the divergence disappears and
130 becomes 129 for a reason nobody could see.** Nothing is merged (§2).

### 3.4 A third shape, and it is the one that would have broken a line-model read

**33 rows wrap their organisation name over two visual lines, and the producer
paints the number and the amount at the MIDPOINT of the two**, interleaving the
line ids — on page 8 the name's first line is line 22, the number line 21, the
name's second line 23 and the amount line 24.

`rhtp_pdf_lines()` therefore **cannot assemble these rows at all**: it emits a
name with no amount and an amount with no name. Rows are built by **y-band**
instead, and `sc_assert_line_model_cannot_read_this()` drives the failure on all
33 while requiring the line model to still read 20 ordinary rows — otherwise its
failure would be evidence about the reader, not about wrapping.

Arkansas asserted that the line model still **merges** its columns (session 40);
Wyoming that it still **splits** a name into a separate run (session 42);
**South Carolina is the third shape — it INTERLEAVES**, so the line model cannot
even tell which name belongs to which amount.

---

## 4. §6.2 — and there is no CMS footer anywhere, on either document

**Measured, not assumed:** the award list contains *"Centers for Medicare"* ZERO
times, *"financial assistance"* ZERO, *"funded by CMS"* ZERO and even the bare
token *"CMS"* **ZERO**. Arkansas's shape (session 40), where the award list
carried no footer either.

**AND THE FOOTER HAS GONE FROM THE PROGRAMME PAGE TOO, WHICH IS NEW.** Session 39
read `scdhhs.gov/RHTP` and recorded the **strong**, programme-scoped form there —
*"The RHTP is supported by … a financial assistance award totaling
$200,030,252.32"*. That path now **301s** to `/resources/grants`, and the live
page carries *"financial assistance"* zero times, *"200,030"* zero and
*"100 percent"* zero. **Recorded as an observation about the SOURCE, not a
finding about the programme (§0.4)**: a publisher dropping a footer says nothing
about where the money came from. Session 27's audit is why it costs nothing — the
footer was never this state's provenance.

**What carries the provenance instead, all of it programme-scoped:**

1. **The document's own running header**, on all eight pages: *"South Carolina
   Rural Health Transformation Program | Year 1 Awards"*.
2. **The programme page names the document by name and date** — *"Award List —
   SC RHTP Year 1 Award List (Posted: Sept. 15, 2026)"* — beside *"South
   Carolina's RHTP is administered by the South Carolina Department of Health
   and Human Services"* and *"This federal initiative is led by the Centers for
   Medicare & Medicaid Services (CMS)"*.
3. **THE INITIATIVE SET CLOSES, AND THIS IS THE STRUCTURAL TIE.** The award
   list's four Initiative headings are **exactly** the four the programme page
   names as South Carolina's RHTP initiatives — Connections to Care, Leveling
   Up, Wellness Within Reach, Shoring Up to Sustainability — and the **fifth**
   that page names, the Tech Catalyst Fund, is **absent from the list, which is
   what the page says to expect**. A document whose section headings are the
   state's own RHTP initiative set, complete and with the one exception the
   state itself flags, is tied to the programme by its **structure** and not by
   a sentence that a re-wording could quietly break.
4. **A second publisher states the count**: CMS's 2026-09-17 release,
   *"228 grants"* and *"$167 Million"*.
5. **The date test passes with room**: posting 2026-04-02, applications due
   2026-06-01, Anticipated Notice of Award 2026-07-31, list posted 2026-09-15 —
   every one after the **2025-12-29** CMS Notice of Award.

---

## 5. The controls, and both negatives sit on the programme page itself

**The positive control is the award-list link.** SCDHHS publishes a roster in a
recognisable form when it has one — an *"Award List"* heading with one named
document under it — so *"the Tech Catalyst Fund has published no roster"* is a
statement about South Carolina and not about our reading.
`sc_assert_award_index()` fails in **both** directions: if that link disappears,
and if a **second** appears (which would be the fifth initiative landing).

**The two negative controls are on the same page as the positive one, and the
second is the sharpest §0.1 trap this state has:**

- ***"SCDHHS Awards $48.2 Million in Healthcare Infrastructure Funds … in RURAL
  and Medically Underserved Areas"*** — a real, named, linked roster, on the RHTP
  page, with *rural* in its title. Awarded **2024-02-02**.
- ***"SCDHHS Awards Behavioral Health Crisis Stabilization Grants to 13 SOUTH
  CAROLINA HOSPITALS"*** — ~**$35,000,000**, a real named roster **of
  hospitals**, linked from the same page. Awarded **2023-06-23**.

A hunt scanning SCDHHS for *"awards" + "rural" + a large figure* takes the first
every time; a hunt scanning for hospital money takes the second. California's
SRHRP trap (session 34) in duplicate — **and §6.2's date test disposes of both on
its own**, 23 and 30 months before the Notice of Award, so the disqualification
is by machine and not by reading.

---

## 6. The year is partial, and South Carolina says so itself

$167,299,900.69 against $200,030,252 leaves **$32,730,351 in no public roster**,
and it is not unaccounted for. The programme page says *"Funding opportunities
for the fifth of South Carolina's RHTP initiatives, the **Tech Catalyst Fund**,
will be announced through a future stage of SCDHHS' RHTP implementation"*, and
that it is administered through the **South Carolina Research Authority** — §7's
designated pass-through route (Illinois/ICAHN's precedent), which has named
nobody. `sc_assert_tech_catalyst_pending()` is designed to fail the day it
publishes.

---

## 7. The hospital figure is a FLOOR, the uncertainty is larger than it, and nothing was promoted

The award list has **three columns** — number, Organization Name, Total Funding
Amount. **No organisation type, no county, no project description.** So every
`recipient_type` is derived from the recipient's own **name**, and the
unstated-form question arrives for a **thirteenth** time and is the **second
largest in dollars** this project has met (after Arkansas's $100.7M).

```
                          ROWS            DOLLARS      % rows   % dollars
FLOOR   (named hospital)    55     $56,587,137.77       24.1%       33.8%
QUEUED  (§8 fallback)      150     $92,759,791.23
CEILING (floor + queued)   205    $149,346,929.00       89.9%       89.3%
```

**It is one-directional** — every fallback row is already
`distributed_to_hospital = No` — so the floor is genuine and so is the ceiling.

**NOTHING WAS PROMOTED (§0.4), AND THE REFUSAL RUNS BOTH WAYS.** Upward: **Self
Regional Healthcare (Lakelands Region) $17,663,869**, **McLeod Health $7,863,454**
across its two spellings, **AnMed $4,147,850**, every **Prisma Health** row,
**Tidelands Health**, **Edgefield County Healthcare $6,874,537** — all read as
hospital systems to anyone who knows South Carolina, and **not one is typed by
the document**. Downward: the **nineteen SCDBHDD rows** are the South Carolina
Department of Behavioral Health and Developmental Disabilities — a state agency
on this pipeline's own knowledge, whose acronym §8's name rule does not reach —
and they are **not demoted to `STATE_AGENCY`** either. They are `No` either way,
so $0 moves, but re-typing them on recognition is the same §0.4 failure in the
other direction.

**Flagged in South Carolina's own files only, by instruction.** A verification
pass is in progress in a separate workbook, so `SC_RECIPIENT_FORM_NOT_STATED`
is **deliberately not appended to `data/reference/classification_review_queue.csv`
this session**. It lives on the rows (`flag_reason = RECIPIENT_TYPE_INFERRED`)
and as a row of `sc_year1_status.csv` carrying its size, and
`sc_assert_form_not_stated_flagged()` fails if either goes — which is what stops
the deferral becoming a loss. A test asserts SC is absent from the shared queue.

### The two MUSC spellings classify opposite ways, and it moves $3,345,533

North Carolina's UNC finding (session 38) in a state that **prices** its rows.
There, two spellings of one Hub Lead moved a coding at $0.

| spelling | rows | dollars | coding |
|---|---:|---:|---|
| `Medical University Hospital Authority` (+ its MUSC Health variants) | 15 | $15,207,815 | `HOSPITAL_OR_SYSTEM` → `Yes` |
| `Medical University of South Carolina` | 3 | $3,345,533 | `UNIVERSITY_OR_AHC` → `No` |

**Both machine answers are kept**, because unlike UNC these are arguably two
different legal bodies — the hospital authority that operates MUSC Health, and
the university — and no source in hand says otherwise. Merging them either way
would be this pipeline deciding a question of South Carolina corporate structure
on a name match. `sc_assert_musc_two_spellings()` **asserts the divergence rather
than repairing it.**

### The project names move nothing, and that is measured

Arkansas's project descriptions moved eleven rows between flow codes and **not
one dollar** (session 40). South Carolina's eight project names —
*"Facility Enhancements"*, *"Mobile Crisis Response"* — are so generic that
feeding them to the flow classifier moves **nothing at all, not even a flow
code**: not one of the eight carries a hospital token. So keeping them out is
§0.3a applied as a **rule**, not as a repair, and a test records which of the two
it is.

---

## 8. The external benchmark — reported, not closed

**The benchmark is recorded here only. It is NOT committed to any repository
data file, and no classification was adjusted toward it.**

Benchmark, from the SC Medicaid agency: **~240 awards, ~$170M, about half of
awards to hospitals, about 60% of dollars to hospitals.**

### 8.1 Award count and dollars

| | extracted | benchmark | gap |
|---|---:|---:|---:|
| awards | **228** | ~240 | **−12** |
| dollars | **$167,299,900.69** | ~$170M | **−$2.7M** |

**What explains the gap: the benchmark is almost certainly rounded, and the
extraction is exact and corroborated.** Three things point that way and none of
them is an adjustment:

- **CMS independently states 228**, not ~240 — *"The RHTP funding will support
  228 grants"* — from a publisher who did not write the list.
- **Every project numbers 1..n with no gap**, so nothing was dropped in the
  parse. The only malformed row number (`I2`) is accounted for and its $120,000
  is in the file.
- The benchmark's figures are given as *~240* and *~$170M*; 228 and
  $167,299,900.69 round to those at the precision offered.

**A residual reading worth stating rather than resolving:** if the benchmark is
*not* rounded, the 12 awards and $2.7M would have to be outside the published
list — and the obvious candidate is the **Tech Catalyst Fund**, which is
unawarded and worth $32.7M, far too much. Nothing in the reachable sources
supports a 240-row roster, so the rounding reading is the one the evidence
carries. **No row was added, removed or re-priced.**

### 8.2 Hospital share against floor and ceiling

| | floor | benchmark | ceiling | benchmark inside range? |
|---|---:|---:|---:|:--:|
| **% of awards** | **24.1%** (55/228) | ~50% | **89.9%** (205/228) | **Yes** |
| **% of dollars** | **33.8%** ($56.6M) | ~60% | **89.3%** ($149.3M) | **Yes** |

**Both benchmark figures fall between floor and ceiling, and comfortably.**
Reaching ~50% of awards would require **59 of the 150** fallback rows to resolve
as hospitals; reaching ~60% of dollars would require **$43.8M of the $92.8M**
fallback. Given that Self Regional Healthcare alone is $17.7M of it, and McLeod,
AnMed, Prisma and Tidelands another ~$19M, **the benchmark is well within what
the unresolved rows could account for.**

**That is a consistency check, not a correction.** The benchmark's agreement with
the range is evidence that the extraction is sound and that the floor is a floor
— it is **not** a reason to promote any row, and none was promoted. The gap
between 33.8% and ~60% is the size of the unstated-form question, which is what
`SC_RECIPIENT_FORM_NOT_STATED` exists to record and what the CCN match
(blocker 5) resolves.

---

## 9. §0.1 — South Carolina carries ZERO RCJ Tier 3 candidates

Derived from the committed record table, never typed: South Carolina holds **33
RCJ records** — 10 `SOLICITATION`, 4 `STATE_ALLOTMENT`, 19 `UNASSIGNED` — and
**zero Tier 3 candidates**, while publishing 228 priced award actions.

**A zero here is a fact about the discovery layer and never about the state
(§0.1).** Florida, North Carolina, Arkansas and Wyoming are the standing proofs
and South Carolina is the **fifth**, at $167.3M the **third largest of the five
in dollars** after Florida's $188.2M and Wyoming's $173.9M.

**It is not quite their shape, though, and the difference is worth keeping.**
Those four were invisible to **both** discovery layers (`trigger_source =
NEITHER`). South Carolina is invisible to RCJ alone and reached the trigger list
through CMS's newsroom on **2026-09-17 — two days AFTER SCDHHS had already posted
the roster**, so the trigger *followed* the publication rather than finding it.

---

## 10. What moved

- **`NAMED_HOSPITAL`: 692 rows / $542,946,270 / 17 states → 747 / $599,533,409 /
  18.** South Carolina adds **55 rows and $56,587,137.77**, the fifth largest
  single-state contribution after Georgia, Wyoming, Alabama and Alaska.
- **Disposition: 26 / 8 / 6 / 10 → 27 / 8 / 5 / 10.**
- Both survey tables **rebuilt** from `R/03k`'s constants.
- **The shared review queue is untouched** (20 rows, no SC), by instruction.
- `verification_queue.xlsx` was **not created, read or modified**.

## 11. Next

- **The Tech Catalyst Fund** is the one thing left in South Carolina's Year 1:
  $32,730,351, administered through the South Carolina Research Authority,
  which has named nobody. `R/03ao --probe` watches for it and ran live this
  session reporting UNCHANGED on all four sources. **It is not on a Routine** —
  that was not asked for, and it is a one-line `create_trigger` when it is.
- **Move `SC_RECIPIENT_FORM_NOT_STATED` into the shared queue** once the
  verification pass in the separate workbook is done. 150 rows, $92,759,791.23,
  one-directional.
- **`scdhhs.gov` digests held** across three fetches inside one minute — only the
  second host here after Maine. Session 34's rule still applies (a back-to-back
  pair is not a stability test), so `--probe` compares a content digest anyway.

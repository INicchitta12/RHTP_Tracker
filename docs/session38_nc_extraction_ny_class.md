# Session 38 — North Carolina extracted, three states on schedules, and §10.2's third eligible class

**Date:** 2026-09-02. Zero RCJ quota; 5 live fetches to `www.ncdhhs.gov` and
`trilliumhealthresources.org` (the probe), nothing else.

---

## 1. Three Routines, offset from the nine already running

| State | Routine | Cadence (UTC) | Why that cadence |
|---|---|---|---|
| **New York** | `trig_01G2ZijwemE2YgbAuiBirKs2` | **Sundays and Wednesdays 11:10** | The tightest clock in the project. RCHI's contracts were to **begin 2026-09-01** — the day before this ran — and every RHTP contract must be **executed by 2026-10-30**. Twice-weekly, and on the two days nothing else runs (Sunday was empty entirely). |
| **Kentucky** | `trig_01FqfAJvnMzz811goNzNZYqi` | **Mondays and Thursdays 19:30** | Two award-notification dates published by the state itself, **both passed** (2026-07-10, 2026-08-26). That is Wisconsin's and Connecticut's footing — the state named a date — so it gets their twice-weekly cadence rather than Missouri's weekly one. |
| **North Carolina** | `trig_01SepuwJWXSkqpNQ9WgJkxMb` | **Saturdays 10:50** | Weekly, and the reason is stated: NC is the only one of the three that has **published no date at all** for what is being watched. The second tier has no announced window, which is Missouri's and New Mexico's footing. |

**Every slot is offset from all nine existing Routines.** The occupied times
were 12:50, 13:00, 14:00 (×2), 15:00, 15:40, 16:20, 17:00 and 18:40; the three
new ones are **10:50, 11:10 and 19:30**, outside that range at both ends. New
York additionally takes **Sunday**, which carried no Routine at all.

Each prompt refuses to act if its probe function is absent from `main`, which
is what stops a Routine silently doing something else while this branch is
unmerged.

**`nc_probe()` had to be written first** — North Carolina had no `--probe`.
It follows Missouri's and Wisconsin's pattern: fetch the five watched pages
live, compare a **content** digest, and run the tripwires **against the live
bytes** rather than the committed archive (session 25's Indiana lesson —
`--validate` reads the archive and passes trivially). It ran live and reports
**UNCHANGED on all five pages**, with all tripwires passing: 39 MIH recipients,
5 ROOTS Hub Leads, no per-recipient amount, no third roster, and the second
tier still naming nobody.

---

## 2. North Carolina extracted — 44 named recipients, `amount` empty on all 44

`nc_year1_awardees.csv`, 44 rows, from two NCDHHS press releases:

| Pool | Rows | Published figure | Named-hospital rows | Named-hospital dollars |
|---|---:|---|---:|---:|
| Mobile Integrated Health | 39 | **$10,000,000 — a POOL figure** | 0 | $0 |
| NC ROOTS Hub Leads | 5 | **none published at all** | 0 | $0 |

Both rosters are clean `<ul>` lists bounded by the document's own sentences, so
they are parsed as **lists, not prose** — session 13's South Dakota rule (a
prose matcher allowed to span a full stop undercounts a roster) does not arise.
The bound matters for a second reason: a fixed-width window run past the last
name reaches the Stevens Amendment footer, whose **$213,008,356.47 is the
ALLOTMENT**.

### 2.1 The row-count/dollar pairing, INVERTED

Nevada and Iowa publish named **hospitals** with no amounts, so their danger is
quoting the $0 without the row count — `rows = 20, dollars = 0` and
`rows = 152, dollars = 0` are both true at once.

**North Carolina's 44 named recipients are 39 EMS agencies and 5 regional
pass-through leads, so it contributes 0 rows and $0 to EVERY bucket.** That is
Maine's and Missouri's shape rather than Nevada's — and it is a **third**
distinct way a state reaches $0, which is why the three must never be
summarised together:

- Nevada, Iowa — named hospitals, no amounts (**rows, no dollars**).
- Maine, Missouri — named hospitals kept **outside the award file**.
- **North Carolina — a complete award file containing no hospital at all.**

`nc_assert_row_count_is_the_finding()` asserts all three halves at once, as
Maine's does: 44 rows exist, `amount` is NA on every one, and the partition
returns **no bucket**. Its two tests drive the mistake in the order it is
actually made — first somebody divides the $10,000,000 over 39 rows, then
somebody promotes Cape Fear Valley — and both are required to throw.

### 2.2 Session 37's "38 of 39" is really 37, and the extraction is what found it

The header said thirty-eight of the thirty-nine are county EMS agencies. Read
against §8's name rule the figure is **thirty-seven**: **two** names carry no
EMS token, not one.

- **"Cape Fear Valley Mobile Integrated Health (MIH)"** — the one name that
  does not read as a county EMS agency at all.
- **"Clay County"** — printed **without** the "EMS" its thirty-eight siblings
  carry, which is the source's own inconsistency and is kept as published (§8).

**Neither was promoted and neither was demoted (§0.4).** Session 37 called Cape
Fear Valley "the one hospital-affiliated recipient", and that is this
pipeline's own knowledge rather than the document's: the archive says nothing
about the recipient beyond its name, while NCDHHS's own sentence calls all
thirty-nine *"local EMS agencies"* and its release describes *"EMS-led Mobile
Integrated Health programs"*. Both rows take §8's standing fallback and the
question is **queued** — worth **$0 either way**, because nothing here is
priced, and what it moves is the state's named-hospital **ROW COUNT**, which is
the only hospital quantity North Carolina supports.

### 2.2a The unstated-form question is the ninth, and by far the smallest

Kansas, Maryland, Nebraska, Oklahoma, Nevada, Michigan, Missouri and Iowa carry
**22 to 102 rows** on §8's standing fallback, because their publishers give a
name and no form. **North Carolina carries 5 of 44**, and the reason is that
its recipients mostly state their own form in their names: 37 of the 39 read
*"<County> County EMS"*, which §8's name rule takes at `HIGH` and which agrees
with NCDHHS's own class sentence — **two independent readings**. That agreement
is what makes the two exceptions visible rather than two of thirty-nine
unknowns. The remaining three are Hub Leads, and they are on the file's own
different footing (§2.4 below).

### 2.3 The two spellings of one Hub Lead CLASSIFY DIFFERENTLY

NCDHHS prints the Region 4 lead as **"University of North Carolina Hospitals"**
on its 2026-05-01 release and as **"UNC Health"** on its standing Hub Leads
page. One recipient, two documents, one agency. §2 forbids a machine resolving
the match, and this is the case that shows why it is not merely a **counting**
problem:

| Spelling | §8 name rule | Flow | Bucket |
|---|---|---|---|
| University of North Carolina Hospitals | `HOSPITAL_OR_SYSTEM`, HIGH | `DIRECT`, **`Yes`** | **NAMED_HOSPITAL** |
| UNC Health | §8's standing fallback, LOW | `NON_HOSPITAL`, `No` | NOT_HOSPITAL |

**Neither machine answer is used.** NCDHHS's own page states the form — *"a
public academic medical center providing patient care ... With more than 1,000
beds"* — and §8's code for an academic health centre is `UNIVERSITY_OR_AHC`,
Oregon's OHSU precedent (session 17), which can only keep dollars **out** of a
hospital total. The source outranks both spellings (Alaska's rule, session 12).
`nc_assert_unc_two_spellings()` **asserts the divergence rather than repairing
it**, so the reason the names must not be merged survives the day somebody
tidies them.

### 2.4 A condition this project had not recorded: the source states a form §8 does not carry

NCDHHS's standing page describes each Hub Lead in the state's own words. For
**two** that settles the §8 type. For the other **three** the state states a
form §8 has no code for:

- Trillium Health Resources — *"an NC Medicaid Tailored Plan and Managed Care
  Organization (MCO)"*
- Vaya Health — *"a public NC Medicaid Managed Care Organization (MCO)"*
- Access East, Inc. — *"a comprehensive care management provider"*

**That is NOT the unstated-form question Kansas, Maryland, Nebraska, Oklahoma,
Nevada, Michigan, Missouri and Iowa all raise.** There the publisher says
nothing; here the publisher says something and §8 has no code for the answer.
**No code was invented (§2).** The three keep §8's standing fallback, the
state's own sentence is preserved in `recipient_type_source`, and the question
is queued as `NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY` — **worth $0**, because all
five Hub Lead rows sit in neither bucket regardless of type and none of the
candidate codes is a hospital type.

The two whose stated form §8 **does** carry were typed from the source: Impact
Health *"an independent 501(c)3"* → `NONPROFIT_CBO`, and UNC Health as above.

### 2.5 The Hub Leads are pass-through recipients, and they are `Unclear`

**They are not Missouri's Hub Anchors, and one word decides it.** NCDHHS
selected them *"to serve as both the programmatic and **fiduciary** leads for
their regions"*, where Missouri's ToRCH FAQ says its Anchors *"will not act as
the fiscal agent"*. So these **are** recipients, and the coding question is
real rather than foreclosed.

**All five are `PASS_THROUGH_UNRESOLVED` + `Unclear`, in neither bucket.**
§10.2's `PASS_THROUGH_DESIGNATED` needs the source to name hospital
subrecipients or restrict eligibility to hospitals **and** the award to have
been made. NCDHHS does neither: the leads *"will establish local networks of
partner organizations"*, and the only published description of such a network —
Access East's — reads *"primary-care practices, Federally Qualified Health
Centers (FQHCs), community health centers, local health departments, safety-net
and social service organizations **and hospitals**"*. Hospitals **among
others**: New Hampshire's FHC class, not Illinois's ICAHN class.

### 2.6 §0.2 written into the data

**The ROOTS rows' `round_amount` is `NA`.** NCDHHS publishes no per-hub figure
and no ROOTS pool figure, and the only currency on either ROOTS document is the
**$213,008,356.47 STATE ALLOTMENT**. An extractor that filled the empty column
with the only number available would publish the whole of North Carolina's
five-year federal award as five hub awards. A test fills it with the allotment
and requires the assertion to throw.

And the MIH pool carries **Georgia's trap**: $10,000,000 repeated on each of 39
rows, so summing `round_amount` down the column gives **$390,000,000**.
`nc_reconcile()` sums distinct `(award_pool, round_amount)` pairs and a test
pins the trap open.

### 2.7 The second tier is where North Carolina's hospital money will be

Each Hub Lead runs its own regional funding opportunities. Trillium's Region 2
page names **nobody**, and `nc_assert_positive_control()` is designed to fail
the day one does. Two further opportunities are closed with no roster and both
application dates have passed (2026-07-17, 2026-08-12), and the $20M-a-year
Rural Health Innovation Fund *"will launch this fall"*.

North Carolina moves to **`EXTRACTED`** in `rcj_state_survey.csv` and
`state_trigger_queue.csv`, both **rebuilt** from the constants in `R/03k`
rather than hand-edited.

---

## 3. §10.2 gains a third eligible class, and it is New York's

Illinois and New Hampshire are the same shape and code opposite ways, and the
**eligible class** is the whole reason. ICAHN is `Yes` — eligibility restricted
to **hospitals only**. FHC is `Unclear` — hospitals **among others**, §0.3.

**New York's RCHI is neither.** Its guidance says *"A **hospital must be
included** as either the lead applicant or the partner Organization"* — a
hospital is **mandatory in every award** and **need not be the recipient**.

- **Not ICAHN's `Yes`**, because ICAHN's `Yes` rests on the recipient
  necessarily being a hospital. New York guarantees only that a hospital is in
  the partnership; the dollar may go to a non-hospital lead.
- **Not `Unclear` for FHC's reason**, and that is the half most easily lost.
  FHC is `Unclear` because a hospital *might* be among the eventual recipients.
  New York's rule is stronger than "might" — a hospital is present in every
  awarded partnership, by rule, knowable in advance. The FHC sentence *"we
  cannot say a hospital is involved"* is simply **false** here. What remains
  unknown is narrower: **whether any dollar reaches the hospital that had to be
  in the room.**

**So a required partner is not a recipient — participation is not receipt,
exactly as eligibility is not receipt (§0.3) — and the coding is read off the
AWARD, one award at a time, never off the eligibility rule.** The block gives
all three codings (lead is the hospital → `DIRECT`; partner hospital named and
funds shown flowing to it → `PASS_THROUGH_DESIGNATED` + `POOL_NAMED_HOSPITALS`
where no split is published; only the lead named → `PASS_THROUGH_UNRESOLVED`).

**This is the most seductive class the project has met**, which is why it is
written down **before** New York awards anything: *"a hospital must be
included"* reads like a guarantee that every dollar reaches a hospital, and it
guarantees that a hospital is in the room. Taking the eligibility sentence as
the coding would publish New York's **$76,190,022** RCHI pool as hospital-bound
money, against 91 applications DOH was still reviewing.

Patched **insert-only** into `rhtp-tracker-build-spec.md`, `CLAUDE.md` and
`reviewer-coding-instructions.md` — 47 lines added to each, nothing deleted
(§2.1) — and `test_flow_table_parity.R` now asserts **byte parity** on this
block as well as on the session-18 association block.

---

## 4. Tests

**44 files, 4,422 assertions, all passing and 1 self-skipping** (was 4,314).
No new test file — the additions are in three existing ones:

- `test_03ah_nc_year1_sources.R` gains the extraction, weighted towards the
  three ways it could be wrong: a **divided pool** and a **promoted Cape Fear
  Valley** are each fed to the pairing assertion and required to throw; the
  ROOTS rows are filled with the **allotment** and required to throw; a
  **fortieth** MIH recipient and a **dollar figure inside a roster** are each
  required to stop the build; and the two spellings of the Region 4 Hub Lead
  are classified side by side and required to **differ**.
- `test_state_union.R` combines a **twenty-first** file. North Carolina is the
  first whose complete named roster contributes to **no bucket at all**, which
  is exactly the kind of thing that unions fine until someone sums a column.
- `test_flow_table_parity.R` asserts byte parity on a **second** §10.2 block.

**One test failed for the right reason while being written**: the
forty-recipient tripwire replaced the document's *first* `</ul>`, which is a
navigation menu, so the roster was untouched and no error was raised. It now
inserts inside the roster's own `<ul>` and asserts the fixture actually
changed.

---

## 5. What did not move

- **No hospital dollar anywhere.** North Carolina contributes 0 rows and $0 to
  all three buckets; every other state's figures are untouched.
- **No new vocabulary code.** Three Hub Leads raise a form §8 does not carry
  and it was queued, not invented (§2).
- **No promotion.** Two MIH rows sit at §8's standing fallback with the
  question open (§0.4).
- **The CRLF trap did not land a sixth time.** The two review-queue rows were
  appended byte-wise in Python; `git diff --numstat` reports **2 insertions, 0
  deletions**.

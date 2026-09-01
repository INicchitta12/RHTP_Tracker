# Session 31 — the pass-through marker becomes a money test; Wisconsin goes on a schedule; Iowa publishes eleven notices

**Date:** 2026-09-01 · **RCJ quota:** zero · ~30 requests across
`www.dhs.wisconsin.gov`, `hhs.iowa.gov` and `governor.iowa.gov`, throttled per §9.5.

Three pieces of work, and the first two are closed. The third is an
investigation that found a real state and stops short of an extractor, for a
reason stated plainly in §3.4.

---

## 1. The pass-through marker is now a MONEY-MOVEMENT test

Session 30's Finding 1, applied. `RHTP_PASS_THROUGH_MARKERS` carried two
**positional** patterns:

```
"at (four|five|...|\d+) [a-z ]*hospitals"
"to (rural )?(partner |member |participating )?hospitals"
```

Those match where a **service** lands, not where a **dollar** goes.

**The positive control is the spec's own worked negative, and it is now a
test.** Georgia's committed note on the Georgia Hospital Association reads
*"GHA receives the grant and supplies obstetrical emergency carts **to
hospitals**. Equipment reaches hospitals, dollars do not"* — §10.2's textbook
`IN_KIND_BENEFIT`, the case the association branch exists to exclude — and the
old marker fired on it. Alaska's AHHA assessments *"**for** three … Critical
Access Hospitals"* correctly fell through. **The old rule separated the spec's
two worked negatives by their PREPOSITION.**

### What replaced it, and why it is one definition rather than two

Session 18 built §10.2's **association** branch around money movement
explicitly. That list is now hoisted into `RHTP_MONEY_TO_HOSPITALS_MARKERS` and
**both branches read it**: `RHTP_ASSOCIATION_ADMINISTERED_MARKERS` is an alias,
and `RHTP_PASS_THROUGH_MARKERS` is that definition plus the structural
mechanisms (`subaward`, `subrecipient`, `pass-through`) and session 18's
unchanged `hospitals will (be able to) apply|receive` clause.

So a phrasing added for one branch can no longer be missing from the other.
What still separates them is §10.2's **second clause** — `award_made` — and the
code each returns, which is the distinction the spec actually draws. A test
asserts the two constants are identical and that one contains the other.

The retained clause is retained deliberately: a hospital applying for or
receiving the money **is** the money reaching the hospital, and it is what
codes Georgia's Type 2 ambulances (*"select rural hospitals will be eligible to
apply for soon"*) as §0.3 eligibility-not-receipt rather than as silence.

### Blast radius: EXACTLY TWO ROWS, AND NO HOSPITAL DOLLAR MOVED

Every extractor was re-run. **51 of 53 reference CSVs came back
byte-identical.** The two that changed changed by one row each:

| Row | The source's own sentence | Was | Now |
|---|---|---|---|
| **AL — Cahaba Medical Care Foundation, $430,304** | *"will establish rural obstetric training capacity **at four Alabama hospitals**"* | `PASS_THROUGH_UNRESOLVED` / `Unclear` | `IN_KIND_BENEFIT` / `No` |
| **KS — Salina Regional Health Center, $932,310** | *"a shared services organization providing … infrastructure **to rural hospitals** across Kansas"* | `PASS_THROUGH_UNRESOLVED` / `Unclear` | `IN_KIND_BENEFIT` / `No` |

In both the recipient **keeps the money and delivers a service**. Both codings
keep the dollars out of every bucket — `Unclear` and `No` alike — so
`rhtp_hospital_dollar_partition()` is **identical before and after on every
changed file**, asserted rather than eyeballed:

```
AL  NAMED_HOSPITAL  60 rows  $66,133,019   before == after
KS  NAMED_HOSPITAL  21 rows  $35,721,277   before == after
OR  NAMED_HOSPITAL  49 rows  $50,188,531   before == after
NV  NAMED_HOSPITAL  20 rows  $0            before == after
```

What the correction buys is that `PASS_THROUGH_UNRESOLVED` — the bucket a later
session revisits **to promote to `Yes`** once subrecipients are named — no
longer holds two rows through which no money will ever pass. §10.2 also gives
`IN_KIND_BENEFIT` as `No` + `hospital_benefiting = Yes`; these rows carried
`Unclear` + `hospital_benefiting = Yes`, a combination §10.2 does not define.

### ONE CONSEQUENCE THAT IS NOT COSMETIC, AND IT IS A DISCLOSURE THAT GREW

Kansas's `KS_RECIPIENT_FORM_NOT_STATED` goes **22 rows / $39,249,763 → 23 /
$40,182,073**, and the 23rd row is Salina Regional Health Center ($932,310).

A row carries one flag slot. Salina's was spent on `ELIGIBILITY_NOT_RECEIPT`,
so the question KDHE's silence actually raises — *what organisational form is
Salina Regional Health Center?* — **could not surface behind it**. A name that
reads like a hospital to anyone who knows Kansas was absent from the queue that
exists to ask exactly that. The named-hospital floor is unchanged at 21 rows /
$35,721,277; the row was `No` for hospital dollars before and after.

The queue row **says why it grew**, and a test requires it to, so the next
reader cannot fail to reconcile it against session 20's figure.

---

## 2. The mandatory `determination_basis`, repaired

Session 30's Finding 2. §7 makes the field mandatory; eight rows in two files
did not honour it, and **no determination was wrong — the audit trail was.**

### Oregon: six rows arguing for the coding an override had replaced

`rhtp_classify_recipients()` writes the basis from the recipient's **name**;
the §6.2 multi-recipient and §0.3 unnamed-pool overrides then re-set
`flow_type` and `distributed_to_hospital` underneath it without touching the
sentence. Verbatim, on the committed file:

> awardee: *"Northwest Regional ESD, Clatsop Community College, **Providence
> Seaside Hospital**, Seaside School District"* · flow_type:
> `PASS_THROUGH_UNRESOLVED` · determination_basis: *"**§10.2 DIRECT: the named
> recipient is a hospital or hospital system** and the state's award document
> names both the recipient and the amount."*

The coding is right — it is the §6.2 catch that keeps $186,000 out of the
named-hospital total — and **a reader auditing the row found the file arguing
for the number it had declined to publish.**

The override's own reason now leads. The treatment of the superseded sentence
differs between the two cases, deliberately:

- **The four `MULTI_RECIPIENT_FIELD` rows KEEP it**, labelled
  `[Superseded machine basis, kept for audit: …]`. The name rules made a real
  determination on real names, and how the machine read the field is worth
  having.
- **The two aggregate rows DISCARD it.** *"Recipient is named but the source
  does not state its organisational form"* against an awardee of *"Not
  identified in the source"* is not a superseded determination; it is an
  artefact of running a name rule on a row that has no name. The new basis says
  so in a clause, rather than quoting a false sentence and hoping the label
  carries.

### Nevada: two rows with no basis, because the file had no such column

Nevada computed **both halves** — `classifier_basis` from the recipient's name
and `flow_basis` from §10.2 — surfaced only the first as
`recipient_type_source`, and dropped the flow half on the floor.
`determination_basis` is now composed exactly as
`rhtp_classify_recipients()` composes it, so a Nevada row reads the way a row
from any other state does. **All 73 rows carry it; nothing was re-coded**,
because both sentences already existed and described the codings the file
already had.

### And the invariant is now asserted across every state at once

`test_state_union.R` walks every state file and fails on any `PASS_THROUGH` row
with an empty basis, with no basis column, or with a basis **leading** with
§10.2's `DIRECT` row. Leading, not containing — a basis may legitimately quote a
superseded machine determination behind its own reason, and that is an audit
trail rather than a contradiction. 17 pass-through rows across 8 files, 0
problems.

---

## 3. Wisconsin is on a schedule, and the appointment has already begun

`R/03y_wi_year1_probe.R --probe`, Routine `trig_01PEixRDWkHzpet4krJtye3b`,
**Tuesdays and Fridays 14:00 UTC**, first fire 2026-09-04.

**Twice-weekly rather than weekly, and that is the point.** Alaska is stale
**by construction** (DOH overwrites one url weekly). Missouri is stale **by
appointment** (DSS's own *"Aug - Sept 2026 Announce select procurement
awardees"*). Wisconsin is stale by appointment **with the appointment already
begun**: DHS's 2026-07-23 council deck prints *"Award announcements:
September"* against three of its four closed opportunities, session 30 ran on
2026-09-01, and the window opened that day.

**It ran live this session and reports UNCHANGED.** All four opportunities
still say *"application period now closed"*, all four still state their award
in the future tense, the solicitations index still calls itself unawarded, and
the deck still says September.

### The third mechanism for one failure, and they are three different things

`www.dhs.wisconsin.gov` is fronted by Akamai and injects a **Boomerang RUM
beacon** carrying a per-request nonce into every HTML response — `ak.rid`,
`ak.t`, a fresh `ak.ak` signature, an edge hostname, the client port. Measured:
two fetches of the RHTP page two seconds apart are **169,310 and 169,311
bytes** and differ on **eighteen wrapped lines, all inside that one
`<script>`** — while the reduced-text digest is **identical**.

| | What rotates | Where |
|---|---|---|
| **NV** (s26) | a state-symbol widget | the page's own **content** |
| **MO** (s29) | an Incapsula cache-buster | a script **src attribute**, host-wide |
| **WI** (s31) | an Akamai RUM beacon | a script **body** |

A file digest is not a change detector on a modern state host. The council deck
is a static PDF whose file digest **is** stable, and it is digested as text
anyway — one rule, no exceptions to remember.

`wi_reduce_html()` was split out of `wi_html_text()` so the probe and the
assertions read **the same reduction**: Missouri's rule, that a probe which
reduces differently from the tripwires it feeds drifts away from them silently,
and the drift shows up as a tripwire that has quietly stopped firing. A test
drives the beacon case directly, synthesising two nonces and requiring the file
digests to differ and the content digests not to.

### The tripwires run against the live bytes, and all four are driven under control

Session 25's Indiana lesson as code. Each of `wi_assert_no_award_roster()`,
`wi_assert_tech_eligibility_pre_identified()` and
`wi_assert_award_announcements_pending()` already took a body override; the
probe hands each what the server just served, and a test requires each to
**fail** on a body where Wisconsin has moved.

### The 403 path is REPORTED, never asserted, and a 200 is a finding

`.../contracts/rural-technology-transformation-fund-**allocations**-…`
re-tested this session: **still 403**, unchanged. It is a per-path refusal —
the RHTP programme page answers 200 from the same host on the same agent, and
`robots.txt` is 200 and does not disallow `/contracts/` — so what it holds is
**UNKNOWN to this repository, never absent** (§0.4). Its slug is the one most
likely to carry a Rural Technology Transformation roster, so the probe re-tests
it every run for one request and prints its status. **A 200 is a new source to
read, not a build failure**, and a test asserts the function cannot throw.

---

## 4. Iowa — the queue leader publishes ELEVEN notices of intent to award

`/api/v1/activity` found the route for the **fifth** time (Oregon, Oklahoma,
Nevada, Missouri, now Iowa). `state_source_url` is NA on all 15 Iowa Tier 3
records; `stage2_state_sources.rds` held **ten real Iowa urls**, among them the
programme page and the two `hhs.iowa.gov/media/` documents.

### Iowa brands RHTP as HEALTHY HOMETOWNS, and its programme page has an awardee section

`hhs.iowa.gov/initiatives/healthy-hometowns-iowas-rural-health-transformation-plan`
carries a heading **"Where to Find Funding Awardees"** linking **eleven Notices
of Intent to Award** across **nine RFPs**. No other state in this repository
publishes an awardee index of that shape.

| Media id | RFP | Date | Recipients |
|---|---|---|---|
| 18093 | PHTHORC26009 Best and Brightest – Medical Equipment | 2026-01-30 | a two-column table, ~36 orgs |
| 18094 | PHTHORC26010 Best and Brightest – Workforce Recruitment | 2026-01-30 | a three-column table, ~90 rows |
| 18135 | COMPADM26001 Combat Cancer Technical Assistance | 2026-02-05 | University of Iowa Health Care |
| 18136 | PHTHOCC26755 Combat Cancer Prevention and Screening | 2026-02-05 | Marion County Board of Health |
| 18137 | PHTHORC26008 Centers of Excellence | 2026-02-05 | **10 named hospitals** |
| 18138 | COMPADM26003 Communities of Care Technical Assistance | 2026-02-05 | Iowa Primary Care Association |
| 18139 | COMPADM26002 Health Hub Technical Assistance | 2026-02-05 | University of Iowa Healthcare |
| 18330 | PHTHORC26009 (RE-ISSUED) | 2026-02-27 | the 18093 roster **plus Marengo Memorial** |
| 18884 | PHTHOCC26756 Combat Cancer Health Hub | 2026-06-18 | 5 named hospitals |
| 18885 | PHTHORC26011 Best and Brightest – Medical Equipment | 2026-06-18 | ~28 named providers |
| 18886 | PHTHORC26012 Best and Brightest – Workforce Recruitment | 2026-06-18 | a two-column table, ~30+ rows |

They are **intents**, in the documents' own words: *"this Notice does NOT
constitute the formation of a contract … The bidder shall not acquire any legal
or equitable rights relative to the contract services until a contract is
executed."* Oregon's and Maryland's posture.

### NOT ONE OF THE ELEVEN CARRIES A PER-RECIPIENT AMOUNT — NEVADA'S SHAPE

Each notice holds **exactly one dollar figure**, and it is in the CMS
financial-assistance footer.

### §0.2 INSIDE ONE DOCUMENT SERIES, WHICH IS NEW

The footer's grammatical subject is the **RFP or the programme** — *"This
Centers of Excellence is supported by…"*, *"This RFP #PHTHORC26012 … is
supported by…"* — which is session 27's **strong** form. **Its amount is not
one tier.**

| Footer amount | Documents | What it is |
|---:|---|---|
| $50,000,000 · $66,002,161.80 · $15,128,000 · $12,600,000 · $6,000,000 ×3 | the seven Jan/Feb notices | the **RFP's own pool** (Tier 2) |
| **$209,040,063.71** | all four June-18 notices | **Iowa's CMS state allotment** (Tier 1), matching the §7.1 anchor's $209,040,064 |

Iowa's footer practice **changed between February and June**, in the same
template, with no other signal. **Summing the eleven footer figures gives
≈$845,770,387 against a $209M allotment** — Virginia's and New Hampshire's
§0.2 lesson, for the first time spread across a document *series* rather than
sitting on one page.

So the footer is **non-strict** here on a second ground beyond session 27's:
its subject is programme-scoped, and its amount cannot be read without knowing
which tier that document chose.

### The provenance is programme-scoped, and it has to be: RHTP APPEARS NOWHERE IN THE NOTICES

*"RHTP"*, *"Rural Health Transformation"* and *"Healthy Hometowns"* all occur
**zero times** in the notices sampled. Read alone, an Iowa notice never names
the programme its awards belong to — Kansas's problem, in a state whose
documents are otherwise the strongest source type available.

Three programme-scoped sentences carry it:

1. *"**Healthy Hometowns is Iowa's submission to the Rural Health
   Transformation Program**, a federal funding initiative managed by the
   Centers for Medicare and Medicaid Services (CMS)."* — the HHS programme page.
2. *"In the first year, Iowa was award $209 million."* (the typo is Iowa's) —
   the same page, matching the §7.1 anchor.
3. The page's **"Where to Find Funding Awardees"** section, which is what links
   these eleven notices and is therefore Iowa's own statement that they are
   Healthy Hometowns awardee documents.

The Governor's 2026-01-30 release — *"Iowa first in the nation to award Rural
Health Transformation Program funding"* — is a **second publisher** of the same
claim from a different host.

**The date test passes on every notice**: 2026-01-30, -02-05, -02-27 and
-06-18, all after the 2025-12-29 Notice of Award.

### §0.1 — RCJ's Iowa NAMES ARE RIGHT, ITS COVERAGE IS 2 OF 11, AND EVERY AMOUNT IS A PLACEHOLDER

Of Iowa's 15 Tier 3 candidates:

- **10** are PHTHORC26008 Centers of Excellence, and they match Iowa's own
  roster **name for name, all ten**. Every one is priced at **$0**.
- **5** are from *"Best and Brightest – Rural Healthcare Workforce
  Recruitment"*, which names roughly ninety rows. Every one is priced at **$1**.

Every Iowa candidate carries `AMOUNT_IMPLAUSIBLE_LOW`. So the aggregator holds
**two of eleven documents**, a small fraction of one of them, and **no money at
all** — Missouri's placeholder mechanism, on a state whose names it gets
exactly right. A low candidate count is again not evidence that a state has
published little (Michigan's twelfth question).

### WHY NO EXTRACTOR WAS BUILT, STATED PLAINLY

`rhtp_pdf_lines()` breaks a line only when the text position moves
**vertically** (`at_y()`), so two table cells painted at the same `y` in
different columns are **merged into one line** and only the first `x` is kept.
On Iowa's two- and three-column notices that yields recipient names like:

```
  Adair County Memorial Hospital Greenfield
  Mercy Health Services-Iowa, Corp. Dubuque
```

— the county welded onto the organisation. A wrapped cell *does* surface its
column separately (`x=311.5`), which is how the geometry is visible at all, but
an unwrapped one does not.

**That is a mangled recipient name, and session 21 already settled that this is
not acceptable in a recipient field** — it is *"Crisp Regional ospital"* again,
one column over. Publishing it, or guessing the split with a heuristic over
Iowa's county names (18093's second column mixes counties with **cities** —
"Greenfield" is the seat of Adair County), would be a §0.4 failure in the one
field the whole file is about.

**The fix is to extend the line model to carry per-run `x`**, the same class of
change as session 21's *"a line is a text POSITION, not a `Td`"*. Its blast
radius is every state that reads a PDF — KS, MD, GA, NE, IN, OK, NV, MO, WI —
each of which must re-run byte-identical, which is the verification session 21,
24 and 27 each did in turn. It is the first item on the next session's list,
and Iowa is the extraction waiting behind it.

Nothing about Iowa was written to `data/reference/`, and
`ia_year1_awardees.csv` deliberately does not exist. The eleven media ids above
make the re-fetch deterministic.

---

## What did NOT change

No state's hospital figure, in either direction. `NAMED_HOSPITAL`,
`POOL_NAMED_HOSPITALS` and `POOL_UNNAMED_HOSPITALS` are untouched; the two rows
that moved were outside all three before and after. Iowa is still
`NOT_EXTRACTED` / `RCJ_ONLY` in `rcj_state_survey.csv` and
`state_trigger_queue.csv`, correctly — it has been *looked at*, and looking is
not extracting.

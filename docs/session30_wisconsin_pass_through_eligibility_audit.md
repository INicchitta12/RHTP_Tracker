# Session 30 — Wisconsin is at solicitation stage; the pass-through eligibility audit; Missouri's first scheduled fire

**Date:** 2026-09-01 · **RCJ quota:** zero · ~30 requests across
`www.dhs.wisconsin.gov`, `dwd.wisconsin.gov`, `dpi.wi.gov`, `worh.org`,
`mywtcs.wtcsystem.edu` and `dss.mo.gov`, throttled per §9.5.

---

## 1. Wisconsin — the queue leader, and a negative with a date on it

Wisconsin led the queue once New Hampshire was extracted: **19 Tier 3
candidates, 19 distinct awardees, a $203,670,005 allotment, no CMS press
release, never investigated.**

**It has published no recipient-level RHTP award list.** Four DHS grant
opportunities are all *"application period now closed"* and **not one names a
recipient**; all four state their awards in the **future tense**; and the DHS
solicitations index calls itself *"the list of current solicitations
(**unawarded**) by DHS"*. So there is no `wi_year1_awardees.csv`, and a test
asserts its absence. `wi_year1_status.csv` has **no `amount` column** and an
assertion refuses one (Texas's device).

**AND WISCONSIN DATES THE THING THAT HAS NOT HAPPENED, WHICH IS MISSOURI'S
FOURTEENTH QUESTION ANSWERED IN THREE WORDS.** DHS's own advisory-council deck
of 2026-07-23 prints **"Award announcements: September"** against three of the
four opportunities. This session ran on **2026-09-01** and the DHS page was
last revised **2026-08-24**. Wisconsin is a negative by a margin of **days**,
not months — the only `INVESTIGATED_NO_LIST` state in this repository whose
window is open now.

### The structure, and why the awards will not be on the RHTP site

The Wisconsin Office of Rural Health — the programme's **own external
evaluator** — describes the model in its April update: *"16 state agencies and
over 29 projects … Some of the funding flows to other state agencies, like
staging areas based on that agency's expertise … Some of those agency
implementation partners will fund community recipients directly, others will
post requests for proposals from community members."*

So Wisconsin is **Indiana's sixth question answered by the state rather than
inferred**: the rosters, when they come, will be on DWD, DPI and WTCS pages as
well as the DHS one. `wi_year1_status.csv` carries one row per channel.

### §6.2 — footer non-strict, programme-scoped evidence required

DHS's footer opens ***"This program** is supported by CMS"* — session 27's
**weak** form. And on this host it is demonstrably not programme-specific: the
identical footer appears on DPI's and DWD's pages, which describe **other
agencies' work**. So it corroborates the **amount** — $203,670,005.21 against
the §7.1 anchor's $203,670,005 — and nothing else.
`wi_assert_footer_corroborates()` returns **NA with a message** when called
non-strictly (Kansas's demotion, session 28), and a test drives **both**
directions so the demotion stays a choice at the call site rather than a
weakening of the check.

Two **programme-scoped** sentences carry the provenance, each asserted every
run: *"**The Rural Health Transformation Program** is a federal funding
opportunity provided to states through CMS"* and *"**The Wisconsin Department
of Health Services (DHS) received a first-year award from CMS for
$203,670,005.21**"*. The date test passes on the deck's own `Launched:` dates
(June 15 and July 1, 2026), read out of the archive rather than typed.

### §0.1 — RCJ prices 16 rows against a document whose text carries none of them

All 16 of RCJ's priced Wisconsin "awards" are filed under one source document,
**"WI - 2026 - RHTP Advisory Council July 23, 2026"**. That deck is archived
here. Its decoded text carries **exactly four dollar figures** —
$203,670,005.21 twice, $300,000, $10 and $1 — and **not one of the 16
amounts**, while the same decoder reads $203,670,005.21 out of it correctly, so
the absence is a fact about the document and not about the reader.

**Stated honestly (§0.4):** one slide (page 26 of 43) is **image-only** and sits
between *"RHT Grant Update — Dani Cook, Director-Healthcare"* and *"Rurality
Designations"*, which is exactly where such a table would be. So the assertion
says the amounts are **not in the text layer** and does **not** claim they are
absent from the document altogether.

**And the deck says what those 16 figures are.** The slide immediately after the
image reads: *"Fund Allocation — Base amount: **$300,000** — Remaining funds
distributed by county: 60% Rural / 40% Semi-rural — Funding split based upon
**county funding formula that is used for AEFLA and WTCS Board purposes**."*
That is a **formula-driven sub-allocation**, not a competitive award, and the
deck's next slides are *"Measurable Objectives"* in the future tense and
*"Pre-proposal Concepts"*.

**THE 16 NAMES ARE THE 16 WTCS DISTRICTS, AND THAT IS SOURCED.** RCJ carries
them stripped to bare region names — *"Northwood"*, *"Chippewa Valley"*,
*"Blackhawk"* — which read as places, not organisations. WTCS's own college
roster is archived here as a control, and **all 16 map one-to-one onto it, with
no extras and no omissions**. They are **technical colleges**, so Wisconsin's
hospital dollars are **$0** even read as awards.

The other 3 candidates are **initiative budget lines from Wisconsin's own CMS
application** whose "awardee" is the initiative name (§6.1
`PROGRAM_NAME_AS_AWARDEE`) — Oklahoma's wrong-TIER defect in a state whose
documents are all genuinely RHTP. The arithmetic closes exactly and is
asserted: **16 rows / $22,139,403 + 3 rows / $78,000,000 = $100,139,403**,
which is `rcj_state_survey.csv`'s own figure for Wisconsin. **RHTP subawards
among the 19: zero.**

### The negative control is linked from an RHTP-funded page — Texas's shape

DWD's WIG: HEART page carries the RHTP CMS footer **and links a document titled
"Successful WIG Healthcare Awards"**. It is a real, executed, recipient-level
health-workforce award list. It is the **Governor's 2021 Workforce Innovation
Grant programme**, which *"used funding from the **American Rescue Plan Act** to
award **$128 million to 27 projects**"*, and it mentions RHTP **zero times**.
An extractor that read "an award list on an RHTP page" as evidence would have
published $128M of ARPA money as Wisconsin's RHTP subawards.
`wi_assert_wig_is_not_rhtp()` fails the day that count stops being zero.

### §0.3 twice, and the second one is worth $61 million

**DPI publishes 213 NAMED rural school districts** under the heading *"Eligible
Districts List"*, against a $5M/5yr pool of which *"**Twenty** Wisconsin
secondary schools **will receive** competitive grants"*. **213 names, 20 future
awards, no awardee list** — Illinois's 97 eligible hospitals in a second
setting, and the largest eligibility list by head count this project has met.
LEAs are school districts, so it is $0 of hospital money whatever it awards.

**And the one that would cost real money.** DHS's Rural Technology
Transformation pool — *"DHS **will award up to $61 million** in the first round
of funding"* — states that *"Eligible organizations have been **pre-identified
based on the rural health facility information provided to CMS** as part of
Wisconsin's RHTP application. **Only organizations named in the application are
eligible.**"* That is a **closed, hospital-weighted eligible class worth
$61M**, and §0.3 is the whole answer: eligibility is not receipt, the
application's facility list is not published on that page, and no recipient is
named. It is in the status table, which has no amount column to sum.

### One path is unreadable, and it is recorded as UNKNOWN (§0.4)

`.../contracts/rural-technology-transformation-fund-**allocations**-improve-health-services-rural-wisconsin`
— the slug that would most plausibly carry a roster, recorded by RCJ's
`/activity` on 2026-07-02 — answers **403 on all four agents** (project honest,
RFC convention, bare `Mozilla/5.0`, full Chrome).

**But this is NOT New Hampshire's or Michigan's finding, and the difference is
measured.** `www.dhs.wisconsin.gov/rhtp/index.htm` answers **200 on the same
four agents from the same host**, and `robots.txt` is **200** and does not
disallow `/contracts/`. So it is a **per-path refusal by the origin** — not a
bot block, and no crawler policy is being declined. What it holds is **UNKNOWN
to this repository**, and the status row says `UNKNOWN`, never "no roster".

---

## 2. The pass-through eligibility audit — every row re-checked, NOTHING CHANGED

New Hampshire showed that two structurally identical pass-through awards code
oppositely on the **stated eligible class**. This is the sweep of every
`PASS_THROUGH_DESIGNATED` and `PASS_THROUGH_UNRESOLVED` row in the repository:
**19 rows across 10 files**, against 402 `DIRECT`, 832 `NON_HOSPITAL` and 32
`IN_KIND_BENEFIT`.

**No coding was changed and no dollar moved.** This section is the report.

### The two rows that carry dollars into a bucket — both hold

| | Eligible class, in the source's own words | Award made? | Coding |
|---|---|---|---|
| **IL — ICAHN, $50,008,264** | *"Critical Access Hospitals and other eligible non-urban Illinois hospitals"* — **hospitals only** | Yes, 3 agreements executed 2026-07-31 | `PASS_THROUGH_DESIGNATED` / **Yes** / `POOL_UNNAMED_HOSPITALS` ✅ |
| **NE — Nebraska High Value Network, $18,156,856.12** | Not an eligibility question — DHHS **names** 21 hospital subrecipients on the notice | Yes | `PASS_THROUGH_DESIGNATED` / **Yes** / `POOL_NAMED_HOSPITALS` ✅ |

Both hold on §10.2's two clauses. All 3,242 test assertions pass, which is the
mechanical half: every asserted eligibility sentence is still present, verbatim,
in the committed evidence.

### The `Unclear` rows — all 17 hold as `Unclear`, and none should be promoted

- **NH — FHC, $66,547,394.** *"primary care, critical access hospitals, EMS,
  behavioral health, oral health, and community-based organizations"* —
  hospitals **among others**. §0.3. Holds.
- **MI — MHA ×2, $8,625,000.** MDHHS publishes **no project description at
  all**. Silence, hospital-affiliated recipient, so neither direction is
  evidenced. Holds.
- **NV — Incline Village Community Hospital Foundation** (no amount) and the
  **$4.8M unnamed residency aggregate**. Hold.
- **SD ×2 — $31.5M and $90M.** *The closest call in the repository, and it
  holds.* The July release says the grants *"support projects **across 20
  health systems**"*, which reads as an eligible class of hospitals — but it is
  a description of **where funded projects sit**, not a restriction: the same
  release says 85 **organizations** applied, 79 were eligible, and directs the
  unsuccessful to *"collaborate with funded **providers**"*. Reading "20 health
  systems" as the eligible class would move **$31.5M** into
  `POOL_UNNAMED_HOSPITALS` on this pipeline's authority. The committed
  `determination_basis` already says exactly this. Holds.
- **GA ×2.** The Type 2 ambulances are *"select rural hospitals will be
  eligible to apply for soon"* — a **hospitals-only class with no award made**,
  so §10.2's second clause fails and it is `Unclear`. This is the useful
  contrast with ICAHN: same class, different clause. Holds.
- **OR ×6.** Four are §6.2 **multi-recipient** overrides (an unresolved
  *recipient list*, not a pass-through) and two are unnamed-pool aggregates.
  Hold in effect.

### FINDING 1 — the pass-through marker is not a money-movement test, and two rows are mis-labelled by it

Session 18 built §10.2's **association** branch around money movement
explicitly — `administered … funds … hospitals`, `subaward`, `reimbursed`. The
**generic** pass-through branch that runs *before* it does not:

```
RHTP_PASS_THROUGH_MARKERS includes  "to (rural )?(partner |member |participating )?hospitals"
                                    "at (four|five|…|\d+) [a-z ]*hospitals"
```

Those match **where a service lands**, not where a dollar goes. Two committed
rows reach `PASS_THROUGH_UNRESOLVED` through it, and on their own sources'
words both are §10.2 **`IN_KIND_BENEFIT`**:

| Row | Source's own sentence | Marker that fired |
|---|---|---|
| **AL — Cahaba Medical Care Foundation, $430,304** | *"will **establish rural obstetric training capacity at four Alabama hospitals**"* | `at four alabama hospitals` |
| **KS — Salina Regional Health Center, $932,310** | *"Five founding providers will form AstraHealth Kansas, a shared services organization **providing … infrastructure to rural hospitals** across Kansas"* | `to rural hospitals` |

In both, the recipient **keeps the money and delivers a service** — which is
precisely the Alaska AHHA case the spec already records as `IN_KIND_BENEFIT`
(*"assessments … for three independent Critical Access Hospitals"* — names three
hospitals, administers nothing to them).

**The positive control is devastating and it is the spec's own worked
negative.** Run the *Georgia Hospital Association* obstetrical-carts
description — §10.2's textbook `IN_KIND_BENEFIT`, the case the association
branch exists to exclude — through the marker and it fires on **`to
hospitals`**. Georgia's file is hand-coded, so nothing moved; had GHA gone
through the shared classifier it would have come out `PASS_THROUGH_UNRESOLVED`.
Meanwhile Alaska's AHHA correctly falls through — **only because its phrasing is
*"for three … Hospitals"* rather than *"to … hospitals"***.

**So the marker separates the spec's two worked negatives by their PREPOSITION,
not by whether money moves.**

**Dollar effect today: $0.** Both codings keep the money out of both buckets
(`Unclear` and `No` alike). Why it still matters:

1. `PASS_THROUGH_UNRESOLVED` is the bucket a future session revisits **to
   promote to `Yes`** when subrecipients are named. These two never will be —
   no money passes through — so the label invites an inflation that the
   correct code forecloses.
2. §10.2 gives `IN_KIND_BENEFIT` as `No` + `hospital_benefiting = Yes`. These
   rows carry `Unclear` + `hospital_benefiting = Yes`, a combination §10.2
   does not define.
3. The rows' own `determination_basis` asserts *"the source states that funds
   reach hospitals it does not name"* — and **neither source says that**. §7
   makes that field mandatory precisely so the row answers the question in six
   months; here it answers it wrongly.

**Blast radius if the marker were made a money-movement test: exactly 2 rows,
$1,362,614, both moving `Unclear → No`, no hospital total affected.** Nothing
was changed, per the instruction to report first.

### FINDING 2 — six rows carry a `determination_basis` that contradicts their own coding

Oregon's §6.2 multi-recipient and unnamed-pool overrides set `flow_type` and
`distributed_to_hospital` **after** the classifier has written `flow_basis`, so
the mandatory field was never re-written. The worst case reads:

> awardee: *"Northwest Regional ESD, Clatsop Community College, **Providence
> Seaside Hospital**, Seaside School District"* · flow_type:
> `PASS_THROUGH_UNRESOLVED` · determination_basis: *"**§10.2 DIRECT: the named
> recipient is a hospital or hospital system** and the state's award document
> names both the recipient and the amount."*

The **coding is right** (this is the §6.2 catch session 17 was proud of — it
keeps $186,000 out of the named-hospital total). The **stated reason is the
opposite of the coding**, and a reader auditing the row would find the file
arguing for the number it declined to publish. Two Oregon aggregate rows
compound it by reading *"Recipient is named but the source does not state its
organisational form"* where the awardee is literally *"Not identified in the
source"*.

Separately, **Nevada's two pass-through rows carry an EMPTY
`determination_basis`**, which §7 makes mandatory.

**Dollar effect: $0.** No coding is wrong; the audit trail is.

### What the sweep did NOT find

No row's eligible class was mis-read in the direction that moves money. **The
`Yes`/`Unclear` boundary is correctly drawn on every one of the 19 rows**, and
the New Hampshire lesson — find the sentence stating the eligible class, and
assert it — is already carried by the two states where it decides $68.2M.

---

## 3. Missouri — the first scheduled fire, and it reports UNCHANGED

Routine `trig_01RyGxdGNv6rrF8t6bT5fQdK` was set in session 29 for Wednesdays
15:00 UTC. `R/03w --probe` was run here on **2026-09-01** and all three probed
sources are **content-identical** to the committed archive:

```
bids          content-sha 14eee06a260c
program_page  content-sha 4198bd8ea5e4
hub_roster    content-sha c9fa6ccbc0f7
```

**IFB # DSS26015-02 is still open with no awardee named**, and the Hub Anchor
roster still carries **no dollar figure**, so `mo_assert_anchors_not_awarded()`
and `mo_assert_procurement_pending()` both hold against the **live bytes**.

**One timing detail worth recording rather than inferring:** the bid page gives
the opening as *"September 1, 2026 at 2pm"* — 19:00 UTC — and this probe ran at
**15:49 UTC**, about three hours **before** it. So "UNCHANGED" is a true
statement about a solicitation whose bid opening had not yet occurred, not
about one that opened and named nobody. **The 2026-09-02 Routine fire is the
first one that can see past it.**

The content-digest design earned its keep on the first real run: the file
SHA-256 moved on every fetch (Incapsula's rotating cache-buster) while all
three content digests held.

---

## 4. What changed

- `R/03y_wi_year1_probe.R` — new. Fetch, 11 assertions, status table,
  disposition, report.
- `data/reference/wi_year1_status.csv` — 8 rows, **no `amount` column**.
- `data/reference/wi_rcj_candidate_disposition.csv` — 2 rows, counts
  re-derived from `stage2_record_table.rds` every run.
- `data/evidence/WI/` — 9 sources + manifest, two of them named as controls.
- `R/03k` — Wisconsin added to `SURVEY_INVESTIGATED_NO_LIST_STATES`; both
  survey and queue **rebuilt from the constant, never hand-edited**. Wisconsin
  goes rank 1 → 50; **Iowa now leads at 15/15**.
- `tests/testthat/test_03y_wi_year1_probe.R` — new, 91 assertions.
- **Tests: 3,242 assertions across 34 files, all pass, 1 self-skip** (was
  3,151 across 33).
- **No determination, in any state, was changed by the §2 audit.**

# Session 40 — Arkansas extracted: two publishers, two grains, reconciling to the cent

**Date:** 2026-09-03
**Files:** `R/03ai_ar_year1_awardees.R`, `tests/testthat/test_03ai_ar_year1_awardees.R`
**Quota:** zero RCJ calls. 14 fetches to `arkansasrhtp.com` and
`governor.arkansas.gov`, plus 4 live probe fetches, throttled at **10 s** —
the host's own `Crawl-delay`.

---

## 1. What Arkansas has published

Arkansas runs its programme from **`arkansasrhtp.com`**, a dedicated RHTP
domain — the second in this project after Kentucky's `ruralhealthplan.ky.gov`
and **the first that has awarded**. It was invisible to both discovery layers:
**zero RCJ Tier 3 candidates** and no CMS state release, `trigger_source =
NEITHER`, which is **Florida's shape** (session 36's existence proof) a third
time after North Carolina — and the largest of the three in dollars.

| | Grain | Publisher | Count | Total |
|---|---|---|---:|---:|
| `roster` | organisation × initiative | DF&A | 31 orgs / **37 priced cells** | **$149,177,618.45** |
| `governor` | project | the Governor | **50 project awards** | **$149,177,618.45** |

**$149,177,618.45 is 71.5% of the $208,779,396 allotment**, and it is a
**partial year by construction**: two of four initiatives have not awarded.

### Three counts, and none of them is the others

```
31  organisations   -- DF&A's award list rows
37  award actions   -- organisation x initiative, the grain Arkansas PRICES
50  project awards  -- the Governor's own count, the grain Arkansas DESCRIBES
```

Six organisations hold an award under **both** initiatives, which is why 31
organisations are 37 award actions. The gap from 37 to 50 is projects, and
Arkansas publishes **no organisation→project map** — so the three counts are
three different claims and `--report` prints all three.

`ar_year1_awardees.csv` is the **37-row** file, at the grain Arkansas prices.
It is not one row per organisation, and the reason is **Michigan's lesson**:
RCJ carried one row per organisation where MDHHS published one per award and
understated the state by $7,833,333.

---

## 2. TWO PUBLISHERS AT TWO GRAINS, RECONCILING TO THE CENT

This is the strongest corroboration in this repository outside Florida's, and
nothing about it was arranged — DF&A published an organisation table and the
Governor published a project list.

```
award list `Total:` row     $55,713,829.20 / $93,463,789.25 / $149,177,618.45
the Governor's 50 projects  $55,713,829.20 / $93,463,789.25 / $149,177,618.45
```

It closes at **three levels at once**, and `ar_assert_projects_reconcile()`
runs all three every build:

1. the whole round, to the cent;
2. each initiative's total, to the cent;
3. **each organisation × initiative pair** — 37 of them, to the cent.

The Governor's release also **rounds** the two column totals independently in
prose: *"$55.7 million through the … THRIVE initiative and $93.6 million
through the … PACT priority"*, under a headline of *"$149.3 million in
awards"*.

---

## 3. THE RUN MODEL IS WHAT MAKES THE AWARD LIST READABLE

The award list paints its three amount columns at **one y**, so the line model
welds them:

```
rhtp_pdf_lines()  ->  "$2,571,095.00$0.00$2,571,095.00"
rhtp_pdf_runs()   ->  "$2,571,095.00" | "$0.00" | "$2,571,095.00"
```

That is Iowa's *"Adair County Memorial Hospital Greenfield"* one column over,
and it is **worse than Iowa's**, because a welded amount string is not merely
a mangled name — it is unparseable, so a session that read this PDF with the
line model would extract **nothing** and report an empty state.

**`ar_assert_line_model_merges()` asserts that the line model STILL merges.**
Session 35's lesson as code: a header claiming the columns need runs is worth
nothing if nobody can reproduce the merge, and a comment that says the
opposite of the code it heads is §2.1's hazard.

Nothing here thresholds a gap or reads an x against a column boundary. The
three amounts of a row are the three **runs** of its line, in painted order —
and a test pins why an x threshold could not work: the body amount runs sit
between x=297 and x=359 while the *header* runs sit at 292, 372 and 451, so no
single boundary separates the body columns and the header at once.

### The `Total:` row is painted like an award row

It carries the full $149,177,618.45 in the same shape as a recipient row.
Read as one it gives **32 organisations and double the money**, and the figure
still looks like a total because it is one. `ar_roster_parts()` splits it off
as the reconciliation target and refuses if it is not exactly one row and last;
a test **drives the mistake** and shows the $298,355,236.90 it produces.

---

## 4. WHICH COLUMN IS THRIVE AND WHICH IS PACT — established three ways

$55.7M and $93.6M are both plausible Arkansas figures, and the row identity
`THRIVE + PACT = Total` **survives an inversion** because addition commutes.
So the assignment is established three independent ways, all asserted:

1. the header runs' own left-to-right x order (`Organization` < `THRIVE` <
   `PACT` < `YR1 PACT/THRIVE Total`);
2. every body row's three runs painted left to right;
3. **the column totals** — swapping them fails the reconciliation, which is
   the only check that can tell them apart;
4. and independently, the Governor naming each initiative's total in prose.

### Arkansas's own header carries the trap

The total column is labelled **"YR1 PACT/THRIVE Total"** — naming **PACT
first** — while the columns beside it run THRIVE then PACT. A reader taking
the total column's *label* as the column order inverts the two.

---

## 5. §6.2 — THE FOOTER IS DEMOTED ON BOTH GROUNDS THIS PROJECT KNOWS

The CMS financial-assistance footer is on every page of the estate and on the
Governor's release, and it fails **twice**:

- **Session 27's axis:** its subject is *"**This project** is supported by"* —
  the WEAK form, a claim about the paper.
- **Session 37's rule:** it prints **$208,779,396.02**, which **is the
  allotment**. It is Tier 1 wearing a project's grammar, declared
  `STATE_ALLOTMENT` and checked by `rhtp_assert_footer_not_allotment()`. A
  test drives the other half: declared `SOLICITATION` it is **refused**.

**And session 26's Nevada lesson is measured on Arkansas's own estate rather
than cited.** The same footer sits unchanged on the **RISE and HEART** pages,
which describe initiatives that have awarded **nothing at all**. A check keyed
on *"does this page carry the CMS footer"* answers **yes** for both.

**The award list itself carries no CMS footer at all** — "Centers for
Medicare", "RHTP" and "Rural Health Transformation" occur **zero times** in it
(Maine's shape). So the footer could not have carried this state's provenance
even if it were the strong form, and `ar_assert_roster_has_no_footer()` fails
the day a provenance sentence appears *on* the award document — which would be
a **stronger** source and should be wired in, not ignored.

### What does carry the provenance — three programme-scoped sources

1. **Each NOFO's own header**: *"Funding Opportunity Number: THRIVE YR
   1-2026"*, *"Issuing Agency: Arkansas Department of Finance and
   Administration (DF&A)"*, *"Program Authority: CMS Rural Health
   Transformation (RHT) Program"*. This ties the exact two initiatives that
   **are** the award list's column headers to RHTP, by name and by agency.
2. **The Governor's release**: *"recipients of the first round of Rural Health
   Transformation Program (RHTP) grants"*, quoting the CMS Administrator.
3. **Arkansas's Year 1 Revised Budget Narrative**, which places all four
   initiatives inside the plan — Kansas's second source (session 28), and it
   carries no CMS footer because the document *is* the plan.

**The date test passes with room.** The earliest NOFO opened **2026-05-11**,
four and a half months after the **2025-12-29** Notice of Award; the awards
were announced **2026-08-27**. Every date is read off the NOFOs themselves.

---

## 6. SEVEN SPELLINGS, AN EIGHTH SYSTEMATIC DIFFERENCE, AND ONE THAT MOVES A DOLLAR

The two publishers spell **nine** organisation names differently, and there is
a tenth difference that is systematic: **the award list prints U+0027 and the
release prints U+2019**, so the join fails on every apostrophe-bearing name
for a reason invisible in either document (session 34's curly-apostrophe
finding, load-bearing this time).

`AR_RELEASE_SPELLINGS` is a **fixed, hand-read map**, keyed release-spelling →
award-list-spelling, every entry visible in the file. §2 forbids a machine
auto-resolving a hospital name, and `ar_assert_release_spellings()` requires
that after applying it the two documents name the **same 31 organisations** —
so a new divergence fails the build instead of quietly dropping a row from the
reconciliation. A test also asserts every recorded entry still *occurs*: a map
entry that matches nothing has stopped being true.

### And one pair CLASSIFIES DIFFERENTLY — worth $301,400

| Spelling | Source | §8 answer | Flow |
|---|---|---|---|
| **Arkansas Children's Hospital** | the award list | `HOSPITAL_OR_SYSTEM`, HIGH | `DIRECT`, **`Yes`** |
| **Arkansas Children's** | the release | §8's standing fallback, LOW | `NON_HOSPITAL`, `No` |

North Carolina's two spellings of UNC moved a **coding** at $0 (session 38).
**Arkansas's move a dollar.** The award rows carry the **award list's**
spelling, because it is the primary source (§8);
`ar_assert_two_spellings_classify_differently()` asserts the divergence rather
than repairing it, and `ar_year1_projects.csv` records **both** machine answers
side by side so neither is silently lost.

---

## 7. ONE OF THE FIFTY AMOUNTS IS PAINTED AS TWO NODES

Forty-nine of the fifty project amounts are one node — `– $3,000,000.00`. One
is **`$`** and **`1,455,689.00`** in two separate nodes. A pattern requiring
the digits immediately after the dollar sign therefore finds **49 of 50** and
drops Arkansas Rural Health Partnership's **$1,455,689.00 in silence**: the
sums simply miss by that much and nothing points at the row.

`ar_assert_split_amount_node()` asserts **both** patterns — that the naive one
still finds 49, and that the parser recovers the fiftieth — so the defect stays
visible rather than being quietly absorbed.

---

## 8. THE HOSPITAL FIGURE, AND THE LARGEST UNSTATED-FORM QUESTION IN THE PROJECT

```
NAMED_HOSPITAL           rows =   9   dollars = $21,792,687.96
```

No pooled bucket: Arkansas awards no pass-through this file can resolve.

**The unstated-form question is the NINTH instance and by far the largest in
dollars: 16 organisations / 21 award rows / $100,723,693.49 — 67.5% of the
round.** DF&A publishes a recipient and an amount and **nothing** about the
recipient's organisational form, and no project description either, so nothing
in the primary source can move a row off what §8's name rule says.

It is **one-directional**, as Oklahoma's and Michigan's are — every one of the
21 rows is already `distributed_to_hospital = No` — so **$21,792,687.96 is a
genuine floor and $122,516,381.45 a genuine ceiling**. That spread is the
largest single classification uncertainty in this repository.

**It runs strongly upward, and four of the six largest awards in the state are
inside it:**

| | |
|---|---:|
| Baxter Health | $19,738,729.91 |
| Mercy Health Fort Smith Communities | $19,056,249.00 |
| Arkansas Rural Health Partnership | $18,833,521.00 |
| Baptist Health | $16,926,432.00 |
| St. Bernards Development Foundation | $14,551,090.00 |

**NOTHING WAS PROMOTED (§0.4).** Every one reads as a hospital or a hospital
body to anyone who knows Arkansas, and **not one is typed by the source**.
A test drives the counterfactual: promoting the five would move
**$89,106,021.91**. Queued as `AR_RECIPIENT_FORM_NOT_STATED`.

### Arkansas Rural Health Partnership is a SECOND and different question

ARHP is a hospital **consortium** — on this pipeline's own knowledge, and not
on the document's. That is not §8's typing question; it is **§10.2's flow
question**, and it is worth **$18,833,521.00**, 12.6% of everything Arkansas
has awarded. §10.2 turns on what the source says the money **does** —
administered to member hospitals (`PASS_THROUGH_DESIGNATED`, `Yes`) or spent
on goods and services for them (`IN_KIND_BENEFIT`, `No`) — and the award list
says **neither**.

Both rows carry `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED` and sit in **neither
bucket**. Queued separately as `AR_ARHP_CONSORTIUM_FLOW`, on Michigan's
`MI_MHA_FLOW` footing.

### The descriptions were read, and they move no dollar — measured

The Governor's release describes every project, and feeding those descriptions
to the classifier moves **11 of the 50 rows** from `NON_HOSPITAL` to
`IN_KIND_BENEFIT` and **not one dollar** into or out of the hospital total
($21,491,287.96 both ways at project grain). §10.2 keeps `IN_KIND_BENEFIT`
dollars out of a hospital total by construction, so the reading is recorded in
`ar_year1_projects.csv` — where a row is one project with one description —
and deliberately **not** folded into the 37-row file, where a row may span
three projects with three different descriptions and there is no honest way to
pick one.

**A description describes an ACTIVITY, and §0.3a judges the RECIPIENT.** That
is why option (c) of the queue row — typing the 16 from the project blurbs —
is refused rather than left open.

---

## 9. TWO OF FOUR INITIATIVES ARE STILL TO COME

| Initiative | NOFO opened | closed | Stage |
|---|---|---|---|
| THRIVE | 2026-05-11 | 2026-06-12 | **AWARDED**, $55,713,829.20 |
| PACT | 2026-06-08 | 2026-07-10 | **AWARDED**, $93,463,789.25 |
| RISE AR | 2026-06-22 | **2026-07-24** | closed, **no award date published** |
| HEART | 2026-06-29 | **2026-08-07** | closed, **no award date published** |

The Governor states it: *"Two additional initiatives of grant funding will be
announced at a later date for the Recruitment Innovation Skills and Education
for Arkansas (RISE AR) and Healthy Eating, Active Recreation, and
Transformation (HEART) initiatives"*, against *"the $209 million the state
expects to award by this fall"*.

**Arkansas publishes no award date for either** — Missouri's and North
Carolina's footing. What dates the wait is **CMS's own deadline, which both
NOFOs print themselves**: *"all funds must be obligated by October 30,
2026"*. Both windows have closed, ~$59.6M is unawarded, and that is eight
weeks out.

### THE INITIATIVE PAGES CANNOT TELL AWARDED FROM UNAWARDED

All four carry the **identical** sentence:

> *"What is next? Upcoming announcements will provide detailed information
> regarding eligibility criteria and award frameworks via Notices of Funding
> Opportunities (NOFOs)."*

Including THRIVE and PACT, which have awarded **$149,177,618.45** between
them. `ar_assert_initiative_pages_cannot_tell()` asserts that equality rather
than glossing it, **and if the pages ever start to differ the probe gains a
signal and should be rewritten to use it.**

**The signal is the home page's award-list link**, in Arkansas's own words —
*"Download the List of Organization and Award amounts"*. It exists for
THRIVE/PACT and for neither of the other two, so it is the positive control:
without it, "RISE and HEART have published nothing" is indistinguishable from
"we are reading the wrong page". `ar_assert_award_index()` fails in **both**
directions — if the link disappears, and if a **second** appears — and both
branches are driven by tests that inject into the archived page.

### The eligible class is recorded BEFORE RISE and HEART award

The THRIVE NOFO's own words: *"rural hospitals, clinics, EMS providers,
behavioral health providers, CINs, and no[nprofits]"* — **hospitals AMONG
OTHERS**, which is New Hampshire's FHC class and **not** Illinois's ICAHN
class. So §0.3 governs any Arkansas pass-through, and that is asserted now
rather than argued later.

---

## 10. THE EIGHTH ROTATING-DIGEST MECHANISM, AND THE FAILING PAIR WAS IN HAND

`arkansasrhtp.com` stamps a **`wp_block_styles_on_demand_placeholder:<13
hex>`** token into an inline `<style>` body. It is WordPress's, and it is
derived from the **render timestamp** — `6a9972a092db4` → `6a99758555064`,
whose leading eight hex digits are Unix times thirty minutes apart.

**This is the mechanism that most sharply repeats session 34's California
lesson, and this time the failing pair was measured rather than reasoned
about:**

| | bytes | file digest |
|---|---:|---|
| fetch A | 223,149 | `8f2144e4…` |
| fetch B, **10 s later** | 223,149 | `47988f60…` |
| fetch C, 10 s after B | 223,149 | `47988f60…` — **identical to B** |

B and C are byte-identical; A, taken half an hour earlier, differs — **at
exactly the same byte length**, because the token is a fixed 13 hex characters.
So a back-to-back pair is **guaranteed** to report the digest stable, and a
byte-count check passes it too.

`ar_reduce_html()` discards `<style>` bodies, so the **content digest** is the
change test and it is identical across all three (6,572 chars every time). A
test synthesises a re-rolled token offline and requires that the file digest
moves and the content digest does not.

**The live probe demonstrated it:** all four watched pages reported
`UNCHANGED` on content while the **file digest MOVED on every one**.

The eight mechanisms so far, and only Maine's digests have actually held:

| | Host | Mechanism | Where |
|---|---|---|---|
| 1 | Nevada | rotating state-symbol widget | page **content** |
| 2 | Missouri | Incapsula cache-buster | script **src attribute** |
| 3 | Wisconsin | Akamai Boomerang nonce | script **body** |
| 4 | California | cache variant + `antispambot()` | page + entities |
| 5 | Connecticut | per-node `?v=` build stamp | **attribute** |
| 6 | New Mexico | Complianz random post URL | script body, **variable length** |
| 7 | Louisiana | Cloudflare email obfuscation | attribute, constant length |
| **8** | **Arkansas** | **WordPress render-timestamp token** | **`<style>` body, constant length, cache-window-stable** |

---

## 11. §0.1 — the aggregator holds nothing, and that is about the aggregator

Arkansas carries **zero** RCJ Tier 3 candidates and no CMS state release —
`trigger_source = NEITHER` on **both** discovery layers, which is why nobody
had looked. It had meanwhile published 31 organisations, 37 priced award
actions and $149,177,618.45 on a dedicated domain, plus a 50-project roster
from the Governor.

**A zero here is a fact about the discovery layer and never about the state
(§0.1).** Kentucky and New York are also zero and are genuine negatives;
Florida, North Carolina and now Arkansas are zero and had rosters. **Three of
the thirteen no-signal states checked so far had published one**, so the group
is worth working in full rather than opportunistically.

Both survey tables were **rebuilt** from `R/03k`'s constants rather than
hand-edited, so Arkansas reads `EXTRACTED` in both and the only content change
is its own status line.

---

## 12. The host, and the throttle

`arkansasrhtp.com` answers **200** to the project's honest agent, so neither
session 10's medicaid.gov question nor session 27's michigan.gov inversion
arises. `robots.txt` is **200**, allows everything outside `/wp-admin/`, and
sets **`Crawl-delay: 10`** — so the throttle here is **ten seconds**, not the
two this project usually uses. The crawler policy is on offer and it is being
honoured (§3).

The `page-sitemap.xml` lists **twelve** pages and there is no separate awards
page, so the home page's linked PDF is the whole of Arkansas's award
publishing — a complete-estate check rather than an assumption.

---

## 13. What was NOT done, and why

- **No new vocabulary code was invented (§2).** The flag for a figure the
  state says is not final is §8's existing **`AMOUNT_PRELIMINARY`** —
  *"the source states the amount is PRELIMINARY or not yet final …
  recipient_confirmed stays Yes and amount_confirmed is No"*, which is
  Arkansas's posture word for word. A first draft used an invented
  `AMOUNT_NOT_FINAL`; the vocabulary test caught it.
- **Nothing was promoted** (§0.4). Five names invite it and all five are
  queued.
- **The county map PDF is archived and not parsed.** Its per-county project
  counts are a different quantity again — projects span counties, so they sum
  to far more than 50 — and nothing in this file needs them.
- **`ar_year1_projects.csv` is not in `test_state_union.R`.** It is the same
  $149,177,618.45 at a finer grain, so adding it would **double the state**.
  Missouri's Hub Anchors and Maine's cohort are out of that union because they
  are not awards; Arkansas's projects file is out because it is the same money
  twice, which is the sharper hazard.

---

## 14. Figures

| | |
|---|---:|
| organisations | **31** |
| award actions (rows) | **37** |
| project awards (the Governor's count) | **50** |
| awarded | **$149,177,618.45** |
| THRIVE | $55,713,829.20 |
| PACT | $93,463,789.25 |
| allotment (§7.1 anchor) | $208,779,396 |
| share awarded | **71.5%** |
| named-hospital rows / dollars | **9 / $21,792,687.96** |
| unstated form (orgs / rows / dollars) | **16 / 21 / $100,723,693.49** |
| one-directional ceiling | **$122,516,381.45** |
| ARHP consortium question | **$18,833,521.00** |

## The watch — RISE AR and HEART, on a Routine

`R/03ai_ar_year1_awardees.R --probe` runs as Routine
**`trig_01Sw1CDPqYQKXFq4WEVRHH2a`**, **Sundays and Thursdays 20:20 UTC**,
first fire 2026-09-03. The slot is offset from all twelve Routines already
running, which occupy 10:50 through 19:30 UTC; 20:20 sits outside that range.

**Twice-weekly rather than weekly, and the reason is stated.** Missouri, New
Mexico and North Carolina are weekly because their states have published no
date for what is being watched. Arkansas has published no award date for RISE AR
or HEART either — but both NOFOs print CMS's own obligation deadline,
*"all funds must be obligated by October 30, 2026"*, and the Governor's release
says the state *"expects to award by this fall"*. A federal deadline eight weeks
out, printed on the state's own solicitations, is a date, and it is Wisconsin's
and Connecticut's footing rather than Missouri's.

**What it watches.** Four pages live — the home page, the resources index, the
RISE AR page and the HEART page — compared on a CONTENT digest through
`ar_reduce_html()`, because the file digest moves on every render (the eighth
mechanism, §"The eighth rotating-digest mechanism" above). The signal is the
home page's award-list link count: one today, and `ar_assert_award_index()`
refuses both zero and two. The initiative pages are deliberately NOT the
signal, because all four carry the same forward-looking sentence.

**Check the Routine is running against `main`.** Its prompt refuses to act if
`ar_probe` is absent from `R/03ai`, so until this branch merges it reports that
and stops, which is intended.

**A note on how this was recorded.** A first draft of this session's CLAUDE.md
carried a Routine id that had never been created — the id was written before
the call was made, and the call was not made. `list_triggers` showed twelve
Routines and no Arkansas entry. The Routine above was created after that
listing, and its id is the one the listing will show. The lesson is the same
one this repository keeps meeting: a claim that something is scheduled is worth
checking against the schedule.

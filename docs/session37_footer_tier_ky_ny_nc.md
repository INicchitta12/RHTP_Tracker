# Session 37 — the footer's tier is not in its grammar, and the no-signal states begin

**Date:** 2026-09-02
**Quota:** zero RCJ calls. ~45 requests across `ruralhealthplan.ky.gov`,
`chfs.ky.gov`, `healthy-ky.org`, `health.ny.gov`, `nyscr.ny.gov`,
`ncdhhs.gov` and `trilliumhealthresources.org`, throttled per §9.5.

---

## 1. Iowa's Tier 2 note said "four" and the answer is three

`ia_notice_footers.csv` carried, on all eight Tier 2 rows:

> *"NEVER ADD IT TO ANOTHER ROW: **four** of the eleven notices carry the state
> allotment in the same slot…"*

There are **three**. Session 31 read Iowa's split as seven/four from a first
pass; session 32 corrected it to **eight/three** from the documents and moved
every assertion in `R/03z` with it — `ia_assert_footer_amounts()` says "The
three June footers", the disposition line says "all three June ones". The one
place the number was **prose inside a `paste()`** was missed, and the prose is
what a reader of the CSV actually meets.

**Fixed by deriving it.** `ia_footer_tier1_words()` and
`ia_footer_count_words()` compute the counts from `IA_NOTICES`, and the sum and
the allotment in the same sentence are now formatted from the table rather than
transcribed. Both render byte-identical to the previous literals, so the only
change in the CSV is `four` → `three` on eight rows.

**A second, related staleness surfaced in the rebuild and was not looked for.**
`ia_rcj_candidate_disposition.csv` said *"including all **four** June ones"*
while its own source line in `R/03z` already said **three** — session 32
corrected the code and did not rebuild that CSV, so a committed reference table
had been sitting out of step with the code that generates it. The rebuild
corrected it. `ia_year1_awardees.csv` is byte-identical; the rebuild is
idempotent.

Two tests pin it, including a positive control that removes a June notice and
requires the sentence to read "two of the ten".

---

## 2. §0.2 — the footer's tier is not recoverable from its grammar

### The finding

Session 27's footer audit sorted CMS financial-assistance footers by their
grammatical **subject**: *"This publication is supported by"* (weak — a claim
about the paper) against *"This **&lt;programme&gt;** is supported by"* (strong
— a claim about the programme). That axis answers whether a footer establishes
**provenance**.

**It does not answer what tier its number is.** Iowa's three footers, verbatim
from the archived notices:

| Footer sentence | Amount | Tier |
|---|---:|---|
| "This **Best and Brightest- Medical Equipment Procurement** is supported by … a financial assistance award totaling approximately …" | $66,002,161.80 | **2** |
| "This **Centers of Excellence** is supported by … a financial assistance award totaling approximately …" | $50,000,000.00 | **2** |
| "This **Combat Cancer Health Hub Program** is supported by … a financial assistance award totaling approximately …" | $209,040,063.71 | **1** |

The three sentences are **word for word identical apart from the programme name
and the number**. All three are the strong, programme-scoped form. All three
name a genuine Iowa RHTP programme — "Combat Cancer Health Hub Program" is a
real RFP, not a stand-in for the State. Nothing in the grammar separates them,
and neither does the subject.

**Tier 1 is knowable only by collision with the §7.1 anchor.**
$209,040,063.71 is Tier 1 because `cms_fy2026_allotments.csv` has Iowa at
$209,040,064 and for no other reason available on the page. That is a
coincidence of *value*, not a statement by the publisher — the most fragile way
this project knows anything — and it is the only signal the document offers.

### The assertion

`rhtp_assert_footer_not_allotment()` and `rhtp_assert_footer_tiers()`, in
`R/utils_config.R` so every state file can reach them without sourcing Stage 2.
The default is **refusal**:

- a figure declared `SOLICITATION` that falls **within** the margin of that
  state's allotment → **stop**
- a figure declared `STATE_ALLOTMENT` that falls **outside** it → **stop**

The second half matters as much as the first: a Tier 1 declaration rests
entirely on that collision, so losing it means either the publisher changed the
figure or the anchor moved, and both are findings.

`RHTP_FOOTER_ALLOTMENT_MARGIN` is **$10,000** — the measured width of publisher
rounding: Iowa restates to the dollar, New Hampshire to the cent
($204,016,550.20), Kansas transposes two digits ($221,890,007.82 against the
anchor's $221,898,008, an $8,000.18 gap that is still unmistakably the
allotment). It sits **six hundredfold** below the smallest genuine Tier 2
footer in the repository ($6,000,000), so it cannot swallow a real pool. A
figure that fails the check is a document to re-read, never a margin to widen.

A missing anchor returns **NA with a message**, never TRUE (§0.4): the check has
not passed, it has not run.

### What it caught, the same session

Not hypothetical. Three of the four states touched this session carry the
exposure live:

- **Kentucky attaches CMS's own Notice of Award to all nine of its RFAs**, as
  "Attachment B"/"Attachment C". Each solicitation therefore ships a document
  whose only headline figure is the whole state allotment — against a stated
  **maximum award of $800,000** on the CHW RFA. Read as that RFA's pool it
  publishes $212,905,590.56, **266× the actual ceiling**.
- **North Carolina's ROOTS Hub Leads page names five awardees and contains
  exactly one currency figure**: $213,008,356.47, in the footer. An extractor
  attaching the only available number to the only available recipients
  publishes the entire allotment as five hub awards.
- **New York's programme page** carries one figure, "$212,058,207.80 in Budget
  Period 1", on a page whose only solicitation is a **$76,190,022** pool — 2.8×
  overstatement.

Iowa's eleven footers are wired in and pass. New Hampshire's two hand-coded
footers (session 29) were checked against the machine rule and **agree**.

§0.2 is patched in the spec (30 lines inserted, 0 deleted) and mirrored into
`CLAUDE.md` (37 lines, 0 deleted). `reviewer-coding-instructions.md` does not
carry §0.2, so there is no parity obligation there.

---

## 3. The twelve no-signal states — the phase session 36 named

Session 36 recorded that **twelve states carry no RCJ Tier 3 signal at all and
hold $2.36 billion of allotment**, eleven of them with no CMS release either,
and that **Florida is the proof**: invisible to both discovery layers and
holding 81 extracted awards worth $188,201,256 the whole time.

The three largest were worked this session. **`/api/v1/activity` found the
route a sixth time** — `state_source_url` is sparse on all three states'
records, and the activity-derived source table held the real hosts, including
Kentucky's dedicated `ruralhealthplan.ky.gov` domain and New York's Contract
Reporter.

**All three carry RCJ records and zero Tier 3 candidates** — 64, 53 and 21
records respectively, all `SOLICITATION`, `STATE_ALLOTMENT` or `UNASSIGNED`. In
these three cases the aggregator is *right*, which is unusual: two of the
states have awarded nobody publicly, so there is nothing to get wrong.

### 3a. Kentucky — a negative that names its own award date twice, both passed

`R/03af_ky_year1_probe.R`. **`INVESTIGATED_NO_LIST`.**

`ruralhealthplan.ky.gov` is a **dedicated RHTP domain, which no other state in
this repository has**, and carries **nine RFAs** under five initiative brands.
Not one names a recipient: *awarded*, *awardee*, *recipients*, *selected* and
*Notice of Intent* occur **zero times each**.

**The state names the notification step and the day, twice:**

| RFA | Its own words | Status |
|---|---|---|
| CMHC Support | "July 10, 2026: **Notification of Award to Grantees**" | **PASSED** |
| CHW Certificate | "August 26, 2026 Anticipated **Notification of Award to Recipients**" | **PASSED** |

Connecticut was the first negative here whose award date had gone by (one
solicitation); Louisiana had seven announcement windows; **Kentucky names the
recipient-notification step itself**, and both dates are re-derived against
`Sys.Date()` on every run rather than typed.

**§6.2 passes in its strongest form: Kentucky publishes CMS's own Notice of
Award**, the fourth state after Nevada, California and Connecticut. Award#
RHT332079, FAIN RHT4158, AL 93.798, recipient "Kentucky Cabinet for Health
Services", $212,905,590.56, budget period 12/29/2025 – 10/30/2026.

**And it is the first published state NOA that is not a revision, which
corroborates session 36 directly.** Nevada's, California's and Connecticut's
are all Action Type **"Revision (Budget)"** with a Federal Award Date *later*
than the budget period start (+52, +92, +206 days) — which is why session 36
pinned the §6.2 date test to the **budget period**. Kentucky's carries Action
Type **"New"** and Federal Award Date **12/29/2025**, equal to its budget period
start and to the committed anchor. **The first direct observation that the two
fields agree when there has been no revision** — the proposition session 36
argued from three revised documents and could not observe.

**A false positive was caught while writing that assertion, and it is worth
recording.** The NOA's terms and conditions instruct the recipient to *"utilize
Revision (Budget) amendment type"* for future changes — boilerplate present on
**every** NOA including an original one. A whole-document search for "Revision
(Budget)" therefore reports every NOA as a revision, which is the opposite of
the finding. The check is scoped to the header block, and a test asserts the
phrase **does** occur later in the document, so the scoping cannot be
"simplified" away.

**The obvious search is poisoned.** *"Notice of Award"* occurs **ten times**
across Kentucky's two funding pages and **not one is a state award to a
recipient** — every one is CMS's award to Kentucky, shipped as an attachment.
It is deliberately excluded from the award-language tripwire (it would fire on
every run and be switched off by whoever met it first) and a separate assertion
requires every occurrence to be the CMS attachment.

**The designated pass-through names nobody either.** The Foundation for a
Healthy Kentucky is "a primary partner" for the Rural Community Hubs initiative
and publishes its own RHTP page; §7 admits a designated pass-through
administrator's document (Illinois/ICAHN), so it was read. It describes the Hub
Lead **role** and names no Hub Lead.

**The eighth digest mechanism, and it is two at once.** SharePoint re-rolls a
fresh GUID in every `<link id="CssLink-…">` *and* a fresh ASP.NET
`__VIEWSTATE` on each render: three fetches, **three distinct SHA-256s**. Both
are attribute-borne, so the tag-stripping reduction absorbs them (reduced text
identical at 7,412 chars). Unlike California's and Louisiana's constant-length
re-rolls, Kentucky's byte **count** does move (83,997 vs 84,004) — a fact about
viewstate, not a general rule.

**A parse defect, and it is session 36's Louisiana finding on a new producer.**
Kentucky's SharePoint editor paints headings with stray spacing *inside* words
— "R ural Community Hubs", "Ro oted in Health", "Fr om Crisis to Care" — so a
fixed-string match on a brand name fails on text a reader sees as ordinary.
Louisiana's producer split "Food isMedicine" the other way. Matching normalises
to **letters only**, as Louisiana's does.

### 3b. New York — the contract start passed the day before this ran

`R/03ag_ny_year1_probe.R`. **`INVESTIGATED_NO_LIST`.**

DOH's Rural Community Health Integration (RCHI) opportunity allocates
**$76,190,022 for Budget Period 1** — 35.9% of the allotment — and its guidance
gives the whole timeline:

> *"Contracts for funded grantees will begin on **September 1, 2026** and end on
> June 30, 2027"* · *"All contracts must be executed by October 30, 2026"*

**This ran 2026-09-02.** Connecticut's passed date was an *announcement*;
Louisiana's were *announcement windows*; Kentucky's are *notification* steps.
**New York's is a contract START** — one step further down the process than any
of them. The state is past announcing and into performing, and names nobody.

**And DOH says where it has got to, in its own deck** (2026-08-12):

> *"Applications Due: July 14, 2026"* · *"**91 Applications, $156,000,000 total
> request**"* · *"**Reviews and Funding Recommendation In Progress**"*

§0.3 in the state's own numbers, **oversubscribed two to one**: 91 applications
and $156M of requests against $76.2M available, not one award named. (The
deck's July 14 and the guidance's July 9 are both the state's own and neither is
resolved — §8 keeps the source's language. An addendum dated 2026-07-02 is the
likely reason and is *not* published as a finding.)

**The eligible class is new to this repository and it is the strongest yet.**
Every pass-through question so far has been Illinois/ICAHN (**hospitals only** →
`Yes`) or New Hampshire/FHC (**hospitals among others** → `Unclear`). RCHI is
neither:

> *"A **hospital must be included** as either the lead applicant or the partner
> Organization"* · *"**At least one hospital** located in the counties listed in
> Attachment 1 is included in the [partnership]"*

**A hospital is mandatory in every award and need not be the recipient** — the
lead applicant may be *"a registered not-for-profit 501(c)(3) organization or
municipal hospital"*. So a hospital is guaranteed to be *in* each partnership
and is not guaranteed to *receive* anything. §0.3 with the trap one step closer.
When RCHI awards, `distributed_to_hospital` must be read off the award, never
off the eligibility rule. Recorded now, before there is a roster to be hasty
with, and an assertion fails if either half of that sentence leaves the page.

**The positive control is a channel and it is unusually clean.** DOH's 2026
press index carries **fifteen award announcements** naming programmes and
amounts — "$10 Million to Expand Access to Dental Care for Children",
"$74 Million to Make Local Water Infrastructure Projects Affordable" — so the
department demonstrably publishes awards in a recognisable form on a readable
channel. On that same index **"Rural Health Transformation" occurs exactly
once**, and it is a *funding opportunity* announcement. California's HCAI
newsroom control with the ratio stated.

**One channel is unreadable and reads UNKNOWN (§0.4).** New York routes
contracting to the NYS Contract Reporter (`nyscr.ny.gov`), a stateful search
application behind a free account — Maine's CGI Advantage, Connecticut's
CTsource and Louisiana's rhtla.net in a fourth costume.

**The digest that did not misbehave.** Three fetches of the programme page
returned the same SHA-256 and the same 28,125 bytes; only Maine's has held like
that before. It is **recorded and not relied on** — session 34's California
lesson is that a stable-looking pair proves nothing — so the probe compares a
content digest like every other.

### 3c. North Carolina — NOT a negative. Two rosters, deliberately not extracted

`R/03ah_nc_year1_sources.R`. **Stays `NOT_EXTRACTED`, which is true.**

North Carolina is the **second Florida**: invisible to both discovery layers,
largest allotment in the group ($213,008,356), and it has published **two named
rosters**. The task was to report before extracting, so this file archives the
evidence and **refuses to create an award file**.

**1. Thirty-nine named Mobile Integrated Health recipients, $10,000,000**
(2026-06-08). *"it will provide $10 million to 39 local EMS agencies through
the NC Rural Health Transformation Program"*, then the roster under *"The
Mobile Integrated Health grant recipients include:"*.

- **No per-recipient amount.** $10M is a **pool** figure — Nevada's and Iowa's
  shape. An extraction must leave `amount` empty on all 39 rows with the total
  in `round_amount`.
- **38 of 39 are county EMS agencies** (`EMS_OR_PSAP` → `NON_HOSPITAL`). The
  exception is **Cape Fear Valley Mobile Integrated Health**, a health system's
  MIH programme — the one §8/§10.2 judgement in the set and the only
  hospital-facing dollar. One further row reads "Clay County" without "EMS",
  which is the source's own inconsistency and stays as published (§8).

**2. Five named NC ROOTS Hub Leads** (2026-05-01): *"The NC ROOTS Hub Lead
**awardees** include:"* — Impact Health (R1), Trillium Health Resources (R2 **and**
R5), Vaya Health (R3), **University of North Carolina Hospitals** (R4), Access
East (R6). **Five organisations, six regions** — a row count is not an
organisation count.

- **They are not Missouri's Hub Anchors, and the difference is one word.**
  Missouri's ToRCH Anchors are a governance roster whose own FAQ says they
  *"will not act as the fiscal agent"*, which is why they live in a file with no
  amount column and contribute nothing. NCDHHS says these five serve *"as both
  the programmatic and **fiduciary** leads for their regions"* — so they are
  pass-through recipients and the coding question is live. An assertion fails
  if that phrase leaves the page.
- **No per-hub amount exists anywhere**, and the ROOTS page's only currency
  figure is the **allotment** (§0.2 above).
- **One lead is a hospital system, under two spellings**: "University of North
  Carolina Hospitals" on the release, "UNC Health" on the standing page — one
  recipient, two documents, one agency. The fuzzy match §2 forbids a machine
  resolving. Recorded, not merged.
- **Contracts were to be finalised by 2026-06-01**, which has passed with no
  published confirmation, so every Hub Lead row is `amount_confirmed = No` at
  best.

**The positive control is two-sided.** NCDHHS demonstrably publishes rosters
(39 names, then 5, plus a standing Hub Leads page), so where it is silent the
silence is North Carolina's. **Two opportunities are closed with no roster and
both dates have passed**: NC Minority Diabetes Prevention (due 2026-07-17) and
Expanding School Health Centers to Rural Areas (due 2026-08-12, up to $1,250,000
for up to five sites — and §0.3a governs its coding, since the setting is
schools and the recipients are health-centre operators).

**The second tier is not published either**, and that is where the hospital
money will be: each Hub Lead runs its own regional opportunities, and Trillium's
Region 2 page — the one RCJ actually points at — names no subrecipient.

**The ninth digest mechanism, and the first time this project has caught the
pair-invisible case with the failing pair in hand.** `ncdhhs.gov` injects a
**Dynatrace** RUM beacon (`ruxitagentjs`) whose `data-dtconfig` attribute
carries a per-request `rpid`. Four fetches: 207,707 / 207,707 / 207,707 /
207,708 bytes, **three distinct SHA-256s, and fetches 1 and 2 identical**. A
back-to-back pair would have reported this host stable — session 34's California
lesson confirmed a fourth time by a fourth mechanism. Wisconsin's Akamai
Boomerang put its nonce in a script **body**; Dynatrace puts it in a script tag
**attribute**, so the reduction absorbs it free.

**A defect caught while writing, and it is §0.2 biting its own author.** The
"no dollar figure inside the roster" check used a fixed-width window, which ran
past the last name into the Stevens Amendment footer — so it tripped on
**$213,008,356.47, the allotment**, the very figure §0.2 says must never be read
as that round's money, and it would have tripped on every run. The window is now
bounded by the roster's own end, with a test pinning both halves.

---

## 4. What this session did not do

- **No extraction of North Carolina.** Reported, archived, and explicitly
  deferred; `nc_year1_awardees.csv` is asserted absent.
- **Nine of the twelve no-signal states are still unopened**: AR, HI, MA, MN,
  NJ, SC, TN, WY, and FL is already extracted. Together with NC they are where
  the remaining money is.
- **No schedule for Kentucky or New York yet.** Both have passed dates and both
  `--probe` cleanly; New York's is the more urgent (a contract start, one day
  past) and North Carolina's second tier is the one most likely to move.

## 5. Numbers

| | |
|---|---|
| Tests | **41 → 44 files, 4,139 → 4,314 assertions**, all passing, 1 self-skipping |
| New R files | `03af_ky_year1_probe.R`, `03ag_ny_year1_probe.R`, `03ah_nc_year1_sources.R` |
| New reference tables | `ky_year1_status.csv` (11), `ky_rcj_candidate_disposition.csv` (1), `ny_year1_status.csv` (6), `ny_rcj_candidate_disposition.csv` (1), `nc_year1_status.csv` (6) |
| Evidence archived | KY 7 sources, NY 5, NC 7 — each with a SHA-256 manifest |
| `INVESTIGATED_NO_LIST` | 6 states → **8** (adds KY, NY) |
| Hospital dollars moved | **$0.** None of the three states contributes a row or a dollar to any bucket. |

# Session 43 — Wyoming on a watch, the fourteen-state low-candidate queue read,
# and a status code for a finding nobody can re-check

**Date:** 2026-09-03
**Quota:** zero RCJ calls. Live fetches to state estates across all fourteen
queued states plus two news hosts, throttled per §9.5. `taggs.hhs.gov` was
**observed in the aggregator's own URLs and NOT fetched** — see §2.5.

---

## 1. Wyoming is on a twice-weekly watch

`R/03aj_wy_year1_awardees.R --probe` ran **live** before anything was
scheduled and reports **UNCHANGED** on all four watched pages — the programme
page, the public notice, the applications-opened release and the Submittable
portal — with no award language on any of them and the portal still reading
*"There are presently no open calls for submissions"*.

Routine **`trig_016y7C12cyxy7GmGNJDxoAbW`**, **TUESDAYS AND FRIDAYS 21:10
UTC**, first firing 2026-09-04.

**The offset was chosen against the thirteen already running**, which occupy a
continuous band from **10:50 to 20:20 UTC**; 21:10 sits fifty minutes clear of
the latest of them (Arkansas, 20:20). Tuesday/Friday are the two lightest days
in the existing spread (three Routines and two) and give even 3-day/4-day
spacing.

**Twice-weekly rather than weekly, and the reason is a date the state
published itself.** Wyoming's obligation deadline is **end of October 2026**
(the Advisory Committee minutes) or **2026-10-01** (WDH's own timeline), and
the committee's next meeting is **4 or 5 November 2026**, with the CMS federal
site visit. **The deadline therefore falls BEFORE the next meeting**, so the
window in which all 75 committee approvals become executed agreements — or do
not — is open now and closes without another public meeting in it. That is
Wisconsin's and Connecticut's footing (a state-published date), not Missouri's
weekly one.

---

## 2. The fourteen-state RCJ low-candidate queue, in allotment order

**$2,668,093,442 of allotment across fourteen states, 34 Tier 3 candidates
between them.** **Thirteen of the fourteen had never been investigated**;
Virginia is the exception, worked in sessions 14–15 and re-checked live here.
Worked to the point of a report and **deliberately not extracted**, on
Arkansas's and Wyoming's footing.

`/api/v1/activity` supplied the route for a **ninth** time: `state_source_url`
is NA on almost every one of these states' records and
`stage2_state_sources.rds` held **609** real state URLs across them.

### 2.1 The disposition

| # | State | Allotment | What it publishes today |
|---|---|---:|---|
| 1 | **MT** | $233.5M | Negative **with a date**: EMS Equipment Grant closed 8/15/26, $4M pool, *"funding decisions will be shared in **September**"* |
| 2 | **MS** | $205.9M | **SELECTION COMPLETE, ANNOUNCEMENT PROMISED** — see §2.2 |
| 3 | **OH** | $202.0M | ONE named award (Ohio University, $10M). Solicitation table is **UNREADABLE** |
| 4 | **CO** | $200.1M | Negative **with a date**: *"anticipates making our award announcements by the **end of September 2026**"* |
| 5 | **WV** | $199.5M | No roster. Four candidates are **state grant documents**, see §2.4 |
| 6 | **ND** | $198.9M | Negative. Two closed opportunities, **23 and 45 applicants**, no awards |
| 7 | **UT** | $195.7M | Negative. **TWELVE closed solicitations**, two open, no roster |
| 8 | **VT** | $195.1M | Negative, unusually crisp: *"All Year 1 RFP and NOFO opportunities have closed"* |
| 9 | **VA** | $189.5M | Negative, **re-checked live**: *"Virginia has not yet opened formal Requests for Applications for RHT funding"*, 16 sub-initiatives all **RFA Status: TBD** |
| 10 | **ID** | $186.0M | **ONE NAMED AWARDEE** (Comagine Health), no amount; **11 open** opportunities |
| 11 | **WA** | $181.3M | Negative. Nothing on the HCA programme page or its bids page |
| 12 | **AZ** | $167.0M | Negative. **8 opportunities priced at Tier 2**, none awarded |
| 13 | **DE** | $157.4M | **FOUR NAMED AWARD ACTIONS, THREE ORGANISATIONS, TWO OF THEM HOSPITALS** — see §2.3 |
| 14 | **RI** | $156.2M | Negative. 13 initiatives, no roster; its 3 candidates are opioid settlement money already swept in session 20 |

**Three of the fourteen are not negatives**: Mississippi, Delaware and Idaho.
Ohio is a fourth partial — one named award and nothing else.

### 2.2 MISSISSIPPI IS THE MOST IMMINENT STATE IN THIS REPOSITORY

`mississippirhtp.com` is a **DEDICATED RHTP DOMAIN — the third after
Kentucky's and Arkansas's**, and Arkansas's was the one that had awarded
$149M. Mississippi runs five named initiatives (CRIS, WEI, HTAM, TAPS,
BRIDGE) and its funding page says, in the state's own words:

> *"The selection process is complete for the Rural Capital Care Gap Closure
> (RCGC), Rural Technology Grant (RTG), and Telehealth Hub Connectivity,
> Equipment, and Education (TCE) grant programs."*
>
> *"Governor Tate Reeves will formally announce details regarding all executed
> sub-awards in the coming weeks."*

**It is South Carolina's email shape with a public announcement attached.**
Selected applicants are contacted by email, exactly as SCDHHS did — but where
South Carolina published nothing further, Mississippi has **promised a named
announcement**. That is the strongest forward signal in this queue.

**And §0.3 is already visible in the state's own numbers**: reporting on
2026-08-06 gives **700+ applications**, **~$82 million available in round
one**, and **$676 million sought** — oversubscribed better than eight to one,
with *"The first awards are expected by the end of the month"*. **That date
has passed.**

**MISSISSIPPI'S CMS FOOTER IS THE FIRST IN THIS REPOSITORY THAT IS NOT 100%
FEDERAL, AND IT BREAKS THE FOOTER TIER CHECK IN A NEW WAY.** **215 occurrences across 76 committed
files** in `data/evidence/` and `data/raw/` say *"100 percent funded by CMS"*
(154) or *"100% funded by CMS"* (61), and **not one committed source anywhere
carries any other percentage**. Mississippi's says:

> *"...as part of a financial assistance award totaling **$205,990,180.16**,
> with **99.96% funded by CMS/HHS ($205,907,220.16)** and **0.04% funded by
> non-government sources ($82,960)**."*

The **CMS share matches the §7.1 anchor to the dollar** ($205,907,220); the
**headline exceeds it by $82,960.16**, which is **eight times** the
`RHTP_FOOTER_ALLOTMENT_MARGIN` of $10,000. **This was driven, not reasoned
about.** Feeding both figures to `rhtp_assert_footer_not_allotment()`:

```
headline $205,990,180.16 declared STATE_ALLOTMENT -> REFUSED (differs by $82,960.16)
headline $205,990,180.16 declared SOLICITATION    -> ACCEPTED
CMS share $205,907,220.16 declared STATE_ALLOTMENT -> ACCEPTED
```

So a session reading Mississippi's headline footer would have it **accepted as
a Tier 2 pool**, which is wrong — it is Tier 1 plus a non-federal match. **The
answer is to parse the CMS share, never the headline, and NOT to widen the
margin** (§0.2's rule: a figure that fails the check is a document to re-read,
never a margin to widen). Widening to $82,960 would also be arbitrary — it is
one state's match amount, and the next state's will differ.

### 2.3 DELAWARE HAS AWARDED, NAMES TWO HOSPITALS, AND PRICES NOBODY

DHSS announced on **2026-07-29** *"awards to establish four new school-based
health centers in Sussex County through the state's Rural Health
Transformation Program (RHTP)"*, naming:

- **Beebe Healthcare** — Sussex Central Middle School
- **Beebe Healthcare** — Georgetown Middle School
- **Nemours Children's Health** — Seaford Middle School
- **TidalHealth** — Selbyville Middle School

**Four award actions, three organisations, and NO PER-RECIPIENT AMOUNT** —
Nevada's, Iowa's and North Carolina's shape, at the smallest scale yet.

**IT IS THE SPEC'S OWN §0.3a WORKED EXAMPLE, ARRIVING AS A REAL AWARD.**
§10.2's `NON_HOSPITAL` row exists because a school-based health centre is an
**activity**, and the recipients here are **hospitals**: Beebe Healthcare and
TidalHealth are exactly the two entities §0.3a names, and the coding is
`DIRECT` / `distributed_to_hospital = Yes`, not `NON_HOSPITAL`. The defect
that `9fdc156` fixed and `219d803` reverted (§2.1) now has live data behind it.

**RCJ carries all four, correctly named, at $1 each** — Missouri's and Maine's
placeholder, so the aggregator will not tell you this is an award. Its other
two Delaware candidates are the **Delaware State Housing Authority**
($11,500,000, from the Executive Budget Summary — Tier 2) and **La Red Health
Center** ($250,000, from an **HRSA fact sheet** — the original §6.2 federal
provenance finding from Stage 0).

**Delaware's footer figure is the ALLOTMENT** — *"a financial assistance award
totaling $157,394,963.86"* against the anchor's $157,394,964 — so it is Tier 1
wearing the weak *"This project"* grammar (session 37's Iowa rule) and must be
declared `STATE_ALLOTMENT`.

**AND THE OWNER'S OWN HAND VERIFICATION ALREADY SAID SO, MONTHS AGO,
INDEPENDENTLY.** `DE Verify.xlsx` — the §9.11 premise test, open blocker 2 —
carries these **same four rows under the same document title**, and its `notes`
column reads **"Cannot determine award amount"** on all four. A hand
verification done before this queue existed and a live read of the state's
release in session 43 agree that Delaware names recipients and prices none of
them. Nothing was arranged.

**AND RE-COUNTING THAT WORKBOOK CORRECTS A FOUNDATIONAL SPEC CLAIM: §0.3a'S
DEFECT IS SEVEN OF ELEVEN ROWS, NOT FOUR.** The spec says *"including four
awards to Beebe Healthcare, TidalHealth, and Nemours Children's Health"*. The
committed workbook names a Delaware hospital or health system in `awardee` on
**seven** rows — the four school-based health centres, plus **Beebe Medical
Center** (row 8), **TidalHealth** (row 9), and *"University of Delaware,
**Beebe Healthcare**, Deloitte Consulting LLP"* (row 11, a §6.2
multi-recipient field) — and every one carries `rhtp_award_yn = yes` and
`hospital_yn = no`.

**Rows 8 and 9 are the sharper half, because §0.3a's own explanation does not
reach them.** The four school rows were coded by **activity**, which is the
error that section names. Rows 8 and 9 are **bare hospital names with no
activity attached at all** — there was nothing to be misled by. So the rule
has a second half worth stating: judging the recipient is not only refusing to
read an activity, it is **reading the recipient at all**. Patched into the spec
insert-only; **nothing was re-coded**, because blocker 2 and Stage 5 own it.

**Nothing was extracted.** Delaware is a four-row file whose `amount` column
would be empty on every row, and it needs its own tripwire before it is
written — and the extraction should start from **seven** flagged rows rather
than re-deriving four.

### 2.4 The four states whose candidates need reading before anyone trusts them

- **WEST VIRGINIA** is the one to be careful with. Its four Tier 3 candidates
  carry **file names as document titles** — `TYBS CRHD FY 2027 Budget
  Justification_6.2.26 (003).docx`, `CSSD EPS2600000001_Direct Award
  Documents.pdf`, `WVSILC RYPAS GRANT AGREEMENT FOR FY 2027.pdf`, `2026-2027
  WVU Cancer Institute (BCCSP) AFA.docx` — and BCCSP is West Virginia's
  **Breast and Cervical Cancer Screening Program**. These are ordinary state
  grant agreements, and whether any is RHTP is **not established here**;
  Indiana's appended-label defect is the shape to test for. WV's own RHTP page
  names no recipient, and its footer adds *"**Pending Approval of Revised
  Budget**"*.
- **ARIZONA**'s four are budget lines from an **application webinar held
  before the state was awarded anything**, three of them against AHCCCS itself
  and one against *"Chronic Disease Prevention & Management"*, a programme name
  (§6.1). Oklahoma's tier defect. Session 20's sweep already flagged three.
- **WASHINGTON**'s two are **`[Contractor Name]`** — a literal template
  placeholder — and *"Washington Tribes and Indian Health Care Providers"* at
  $30,200,000, a class and not a recipient (North Dakota's *"15 selected
  CAHs"*).
- **IDAHO**'s single candidate is **`Co-Imagine Health` at $1**, with no
  source document at all. No organisation of that name exists, and
  **Comagine Health** is the one awardee Idaho's own funding page names — so
  it is evidently the same body under a corrupted name. **That match is this
  session's reading and not the source's**, so it is recorded and not relied
  on (§0.4); an Idaho extraction must take the name from the state page.
- **UTAH**'s two are **one award carried twice**: the Utah Health Information
  Network's $3,000,000 sole-source Notice of Intent to Award, under two
  document revisions. Connecticut's revision double-count.
- **VIRGINIA** was re-checked live rather than carried forward from sessions
  14–15, and the state's own implementation page now settles it in one
  sentence: *"Please note: Virginia has not yet opened formal Requests for
  Applications for RHT funding."* All sixteen sub-initiatives across CareIQ,
  Homegrown Health Heroes, Connected Care and Live Well Together read **RFA
  Status: TBD**. Its single candidate — Virginia Highlands Community College,
  $127,500 — remains corroborated by the Governor's own release and remains
  `NON_HOSPITAL`.
- **MONTANA**'s *Directory* is a **§0.3 trap worth naming**: 100+ organisations
  on a state page, self-reported, which DPHHS explicitly says is a networking
  list — *"Submission does not guarantee a partnership, subcontracting
  opportunity, or contract award"*.

### 2.5 Two things worth carrying forward

**`hcpf.colorado.gov` needs the RFC crawler agent, and that is session 10's
answer and not session 27's.** Measured on four agents: the project's own
honest agent **403**, bare `Mozilla/5.0` **403**, the RFC convention
*"Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +https://www.aha.org)"*
**200**, full Chrome **200**; `robots.txt` is itself **403**. The form that
works **carries our name and contact URL**, so identifying honestly is the
fix — Louisiana's finding on a new host. **No michigan.gov-style exception is
needed and none was taken.**

**`taggs.hhs.gov` is an independent federal record of every state's RHTP award
and this project has never used it.** It surfaced in three states' `/activity`
URLs with per-state award numbers (`RHTCMS332047` Vermont, `RHTCMS332053`
Delaware, `RHTCMS332087` Ohio). It is a **potential §7.1 corroboration source
that is neither RCJ nor the state**, and it is worth a session of its own —
not used here, because nothing in this report depends on it.

**Two hosts are UNREADABLE and are recorded as UNKNOWN, never as negatives
(§0.4):** Ohio's solicitation table (*"Please utilize the table and search
functionality provided below"* — the rows are not in the HTML) and Idaho's
Laserfiche `publicdocuments.dhw.idaho.gov` WebLink repository.

**And Ohio's own programme page is stale in a way worth noting**: it still
reads *"the State of Ohio **will submit** an application. **If awarded**, it
will manage the funds"* on the same page that links the Governor's award
announcement.

---

## 3. The state-attribution sweep, re-run

`R/02c_state_attribution_sweep.R --build` was re-run before any extraction
work, as instructed. **It rebuilds `rcj_state_attribution_sweep.csv`
BYTE-IDENTICAL**: 23 flagged, 10 misfiled across five states (WY←UT 5, ND←AR
2, MO←MI, UT←OK, WA←FL), **none of them Tier 3**, and all eight Tier 3 flags
still false positives with legible causes.

**AND THAT IS A REPRODUCTION, NOT A RE-MEASUREMENT, WHICH IS THE HONEST WAY TO
REPORT IT.** There is exactly one pull on disk — `data/raw/rcj/2026-08-27/` —
so the sweep re-read the same 5,056 records and could only return the same
answer. Its clean Tier 3 result remains a property of the **2026-08-27 corpus**
and nothing observed here extends it. **The genuine re-measurement is due at
the next national pull, and it must run before the next state is extracted.**

Nothing was extracted this session, so the guard had nothing to guard.

---

## 4. `INVESTIGATED_NO_PROBE` — a status for a finding nobody can re-check

Six states — **HI, MA, MN, NJ, SC, TN** — had been worked in sessions 39 and 41
and sat at `NOT_EXTRACTED`, **which says nobody has looked**. That is how a
completed investigation gets repeated from scratch, which is the exact failure
`INVESTIGATED_NO_LIST` was created for in session 19.

**But `INVESTIGATED_NO_LIST` would have been a false claim for every one of
them, and for two different reasons.**

**First, the code promises something they do not have.** It means a
*re-checkable* negative: a committed evidence archive **AND** a probe carrying
a tripwire that re-opens the state the day it publishes. All eight states
holding it have both. Of these six, **only Hawaii has an evidence archive at
all** (`data/evidence/HI/`, 7 files) — for MA, MN, NJ, SC and TN the finding
lives in `docs/session39_*` and `docs/session41_*` **prose alone** — and **not
one of the six has a probe**.

**Second, two of the six are not negatives.**

- **SOUTH CAROLINA HAS AWARDED.** Bulletin MB# 26-026 says SCDHHS *"issued
  Notices of Award Determination for the **712 applications** received ...
  Applicants should check their email"*, hitting its own published
  *"Anticipated Notice of Award — July 31, 2026"* exactly. No roster, no
  amounts, not even a count of awards — so "publishes no recipient-level list"
  is true of the **list** and false about the **stage**.
- **MASSACHUSETTS IS UNREADABLE, NOT SILENT.** Every `mass.gov` path is
  Akamai-403 on four agents, `robots.txt` included. Asserting it publishes no
  list would be a statement about the state made from a fact about our access
  — New Hampshire's rule, §0.4.
- **HAWAII** names **one** award (SHPDA's *"Notice of Award on 8/28 to Hawaii
  Primary Care Association"*) whose amount lives only in HANDS, which is 403.
  One named recipient is not a roster and is not nothing either.

So `extraction_status` and `queue_status` gain **`INVESTIGATED_NO_PROBE`**,
written into `vocabularies.csv` with full notes on session 10's
`PHYSICIAN_PRACTICE` footing. It says **what this repository did**, not what
the state published — the axis §0.4 keeps drawing — and its note states
plainly that it is **deliberately weaker** than `INVESTIGATED_NO_LIST`, that
the finding **goes stale by construction**, and that **the intended next action
is to write the probe**.

Both tables were **rebuilt** from the constants in `R/03k`, never hand-edited.
`rcj_state_survey.csv` moves six rows and `state_trigger_queue.csv` moves the
same six plus the renumbering they cause; no other column changes.

**What each probe would watch, so the next session does not re-derive it:**

| State | The one thing to watch |
|---|---|
| **SC** | A roster appearing against the 712 award determinations; SCRA's Tech Catalyst Fund, a §7 designated pass-through that has not awarded |
| **MN** | The **94 pre-identified eligible entities** and the **70%-to-hospitals formula** — the largest §0.3 trap in the project, and MDH has published neither the 94 nor any award |
| **HI** | SHPDA's initiative page, which annotates each item in a parenthesis (*"(Notice of Award on 8/28 to …)"*); the hospital money is the RVBI item still at RFI stage |
| **TN** | The Caspio RHTP Partner Portal, currently *"You need to enable JavaScript to run this app"* — UNREADABLE |
| **NJ** | The SORH page, last reviewed 2026-08-06, which still says the state *"applied for"* the funding |
| **MA** | Re-test the estate first; if `web.archive.org` ever answers, the 2026-08-06 snapshot the availability API reports is the first thing to read |

**`first_queued` now carries 2026-09-03 for MA, MN, NJ, SC and TN**, because
the existing rule assigns a date to anything that is not `NOT_TRIGGERED`.
Kentucky and New York set that precedent in session 37 on identical facts, so
this is consistent rather than new; the column's name is looser than its
docstring and was left alone rather than changed under five states at once.

---

## 4a. Why the fourteen states of §2 stay `QUEUED` and are NOT given the new code

They were worked this session, so on the face of it `INVESTIGATED_NO_PROBE`
fits them as well as it fits the six. **It does not, and the distinction is
the one `INVESTIGATED_NO_LIST`'s own note already draws: a state leaves the
QUEUED bucket when there is no further work available on it today.**

For the six, there is none — they were investigated to a conclusion and what
is missing is a **probe**, an artifact that watches, not an extraction.

For four of the fourteen there is work, and it is the most valuable work in
this repository right now: **Mississippi** is about to publish a named roster,
**Delaware** is a four-row extraction sitting there today, and **Idaho** and
**Ohio** each name an awardee already. Coding those `INVESTIGATED_NO_PROBE`
would move them out of the queue on the strength of a session that
deliberately did not extract them — which is how the finding "three of the
fourteen are not negatives" would quietly become "the fourteen are done".

The other ten are negatives, and they could take the code honestly. **They are
left QUEUED too, because splitting the fourteen across two statuses on the
strength of one reporting pass would make the queue harder to read than
leaving it alone**, and because §2 of this document is where their disposition
lives until somebody acts on it. A session that works any of them properly —
archive, tripwire, probe — should move it straight to `INVESTIGATED_NO_LIST`
or `EXTRACTED` and skip the weaker code entirely.

**So the rule is: `INVESTIGATED_NO_PROBE` is for a finished investigation
missing only its watch, never for a state still holding work.**

---

## 5. What did NOT move

**No hospital dollar moved anywhere.** No state was extracted, no award file
was written or touched, and `rhtp_hospital_dollar_partition()` returns exactly
what it returned at the end of session 42: `NAMED_HOSPITAL` 609 rows /
$482,781,258 / 15 states, `POOL_NAMED_HOSPITALS` 1 / $18,156,856,
`POOL_UNNAMED_HOSPITALS` 1 / $50,008,264.

Nothing was promoted (§0.4). Delaware's two named hospitals, Idaho's Comagine
Health and Ohio's Ohio University are **reported and not coded**, because
reporting before extracting is what this session was asked to do.

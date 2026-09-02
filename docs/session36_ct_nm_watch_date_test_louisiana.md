# Session 36 — Connecticut and New Mexico on watches, the date test pinned, and Louisiana's seven closed windows

**Date:** 2026-09-02. Zero RCJ quota; ~25 requests across `ldh.la.gov`,
`rhtla.net`, `www.opportunitylouisiana.gov`, `portal.ct.gov` and
`www.hca.nm.gov`, throttled per §9.5.

---

## 1. Connecticut and New Mexico are on schedules

Both probes were run **live first** and both report UNCHANGED on every watched
page, which is this project's precedent before a Routine is created.

| | Routine | Cadence (UTC) | First fire |
|---|---|---|---|
| **Connecticut** | `trig_01DRHN1x1WfzPjC3dpgay8s2` | **Mondays and Thursdays 15:40** | 2026-09-03 |
| **New Mexico** | `trig_01DbiFhMJhaZXzYB4gi5JpwX` | **Tuesdays 18:40** | 2026-09-08 |

**Connecticut is twice-weekly because its award date has passed.** OPM's own
timeline gives *"Grant Awards Announced ... **August 17, 2026**"* for NOFO
#26OHS001, sixteen days before session 35 ran, with no roster anywhere
reachable.

**New Mexico is weekly, and the reason is stated rather than assumed.**
Wisconsin and Connecticut earned twice-weekly because their states published an
award **date**; Missouri earned weekly on a month-wide window. New Mexico
publishes **no award date at all** — four procurements read *"Currently under
evaluation"* and one reads *"Submissions due: TBD"*. Rooted in New Mexico closed
to submissions **2026-09-04**, and a submission deadline is the start of an
evaluation, not an award. Weekly is Missouri's footing and is what the evidence
supports.

**The cadence is offset so nothing stacks.** The week now reads:

```
Mon  13:00 CMS   14:00 AK    15:40 CT
Tue  14:00 WI    16:20 ME    18:40 NM
Wed  12:50 LA    15:00 MO    17:00 CA
Thu  13:00 CMS   15:40 CT
Fri  14:00 WI    16:20 ME
Sat  12:50 LA    17:00 CA
```

Each prompt carries what a future session would otherwise re-derive — for
Connecticut the per-node `?v=` digest mechanism, the two-dates trap and the
hospitals-among-others eligible class; for New Mexico the RHCDF's state
funding, the navigation-menu-only programme mentions, the $1 placeholder and the
Complianz re-roll. Both refuse to act if their probe function is absent from the
branch the fired session clones.

---

## 2. The §6.2 date test reads the budget period, and now says so

**The anchor was already correct.** `data/reference/cms_state_noa_dates.csv`
carries **2025-12-29** for all 50 states, parsed from the schema.org
`datePublished` on CMS's own award announcement and cross-checked against the
newsroom index. **`R/02b_provenance_sweep.R` opens no state Notice of Award PDF
at all**, so the "Federal Award Date" field on those forms has never reached it.

**What was missing is the reason.** `rhtp_build_noa_dates()`'s docstring said
*"a state that later proves to have a different date is a data correction and
not a code change"* — which invites exactly the wrong correction, because three
states now publish CMS's own NOA and that PDF is plainly better evidence than a
press release.

### Three of three carry a later Federal Award Date

| state | award # | budget period start | "Federal Award Date" | gap |
|---|---|---|---|---:|
| NV | RHTCMS332074-01-02 | 12/29/2025 | 02/19/2026 | +52d |
| CA | RHTCMS332078-01-02 | 12/29/2025 | 03/31/2026 | +92d |
| CT | RHTCMS332073-01-03 | 12/29/2025 | **07/23/2026** | **+206d** |

All three carry Award Action Type **"Revision (Budget)"**. The field is the date
of the **latest revision**: CMS re-issues the whole form each time it approves a
revised budget, and the budget period start does not move. **Connecticut's award
number ends `-01-03` where the other two end `-01-02`** — it is on its second
revision, which is why its gap is the widest.

**So the error grows with every revision**, and fastest for the states managing
their awards most actively. Any state NOA this project reads in future will
carry a wider gap than these. That is the argument for keeping the CMS
announcement as the source: its date agrees with all three budget-period starts,
from a different publisher in a different medium.

### The counterfactual, measured

Keying the anchor on the later date stops Connecticut's own build in two places,
and **the first failure reads as a finding about Connecticut rather than a
defect in the anchor**:

```
ct_assert_after_noa()         -> STOPS: "NOFO #26OHS001 no longer postdates
                                 Connecticut's Notice of Award."
ct_assert_noa_is_cms_award()  -> STOPS: "the Federal Award Date no longer
                                 postdates the NOA anchor."
```

And two dated Connecticut candidates (2026-04-07, $1,500,000 and $3,800,000)
quarantine as `PROVENANCE_PREDATES_NOA` for being seven months "early" against
their own state's genuine award.

**Four tests read all three archived NOAs and drive the counterfactual**,
including one asserting the gap is *not* a fixed offset so nobody "fixes" it
with a constant. **Positive-controlled**: moving the committed anchor to
2026-07-23 fails 19 tests in that file, and the CSV was restored byte-identical
afterwards. Both changes are insert-only (§2.1); **no data moved**.

---

## 3. The queue, and what it now says about RCJ

**RCJ's usefulness as a discovery signal is close to exhausted, and the numbers
say so plainly.**

| | states | candidates |
|---|---:|---:|
| Worked (EXTRACTED or INVESTIGATED_NO_LIST) | 25 | 1,332 |
| **Open, with candidates** | **14** | **34** |
| **Zero RCJ signal** | **12** | **0** |

After Louisiana, the open queue leads **Delaware 5, Arizona 4, Colorado 4, West
Virginia 4, Mississippi 3, Rhode Island 3** — then eight states at 2 or 1. The
largest remaining candidate set in the country is **five rows**.

**And twelve states carry no RCJ signal at all, holding $2.36 BILLION of
allotment between them**: NC ($213.0M), KY ($212.9M), NY ($212.1M), FL, AR, TN,
WY, SC, MN, HI, MA, NJ. Eleven are `NOT_EXTRACTED` and none has a CMS release —
`trigger_source = NEITHER` on both discovery layers.

**Florida is the twelfth, and it is the proof.** No CMS release, no RCJ
candidate, and **81 extracted awards worth $188,201,256** already in this
repository, reconciled exactly against the Governor's own awardee PDF. A state
invisible to both discovery layers published a complete Year 1 roster.

So the next phase is not "work the queue down". It is **states with no signal at
all**, and Florida is the existence proof that they can still have published.

---

## 4. Louisiana — a negative, and its seven announcement windows have all closed

Louisiana led the queue at 6 candidates / 6 distinct awardees / $53,910,000, no
CMS release, $208,374,448 allotment. **It has published no recipient-level RHTP
award list.**

### What it has published is seven solicitations and seven announcement dates

LDH's programme page carries an **"IMPORTANT DATES - BUDGET YEAR 1"** block
giving every Budget Year 1 opportunity both an application deadline and a
**"Notice of Intent to Contract Announcements"** window:

- *Late July to mid August* **x3** — Rural Clinician Credit Bank, Telehealth, Capital Improvement
- *Mid to late August* **x4** — Collaborative Provider, APM, Care Conveners, Food is Medicine

3 + 4 = 7, matching the funding page's seven *"Strategic Funding Opportunity
Title"* headings exactly, and **all seven windows closed before this ran on
2026-09-02**. Connecticut was the first negative here whose award date had
passed, with ONE solicitation; **Louisiana has seven, and the state published
the dates itself.**

### The Advisory Council deck is sharper, and it is RCJ's source

Slide 18 of the 2026-08-20 deck, headed **"RHTP Funding Cycle Budget Year 1"**,
columns **Activity | # Applications Received | Projected BY 1 Funding |
Anticipated Announcement**:

| Activity | Apps | Projected BY1 | Announcement |
|---|---:|---:|---|
| Rural Clinician Credit Bank | 136 | $10,000,000 | Mid August |
| **Capital Improvement Program** | **160** | **$41,600,000** | **Late August** |
| Telehealth | 79 | $4,710,000 | Late August |
| Collaborative Provider Model | 37 | $3,000,000 | Early September |
| Alternative Payment Model | 31 | $30,000,000 | Early September |
| Care conveners / navigation network | 25 | $3,500,000 | Mid September |
| Food is Medicine | 37 | $2,700,000 | Mid September |
| | **505** | **$95,510,000** | |

**505 applications received, not one award named.** §0.3 in the state's own
table.

### §0.1 — Oklahoma's tier defect, with the state's own heading refuting it

**All six RCJ candidates are rows of that one table.** The "awardee" is the
**ACTIVITY** column — *Alternative Payment Model*, *Care conveners / navigation
network*, *Food is Medicine*, *Telehealth*, *Rural Clinician Credit Bank*,
*Collaborative Provider Model* — which are **fund uses, not organisations**, so
this is §6.1's `PROGRAM_NAME_AS_AWARDEE` on **six of six**, and
`named_recipient_test` reads **PASS** on every one. The amount is the
**"Projected BY 1 Funding"** column times a million.

Oklahoma's Legislative Quarterly Reports had to be read to their glossary to
establish the same thing. **Louisiana says PROJECTED in the column heading.**

**And RCJ drops the largest row.** Capital Improvement — 160 applications, the
most of the seven; $41.60 million, the largest pool; awards of
$100,000–$10,000,000 for facility renovation, medical equipment and technology
infrastructure — **is not among the six**. So the six sum to $53,910,000 against
the deck's seven at $95,510,000: **the aggregator understates the table it mined
by $41,600,000, and the row it drops is the capital one, the likeliest to reach
a hospital.** Michigan deflated by carrying one row per organisation; Louisiana
deflates by dropping a row.

**Not one candidate is a named Louisiana organisation of any kind**, so unlike
California and New Mexico there is no named-hospital exposure here at all.

### The eligible class, before anyone codes a pass-through

The Capital NOFO's applicants must be *"licensed by LDH ... as a: Rural Health
Clinics (RHCs), Federally Qualified Health Centers (FQHCs) or look-alikes,
**Critical Access Hospitals (CAHs), Rural hospitals**, Rural EMS providers,
Rural behavioral health or substance use providers, Independent rural
practices"* — **hospitals among others**. New Hampshire's FHC class, not
Illinois's ICAHN class, so §0.3 governs it either way.

### §6.2 — three publishers, and the footer demoted

LDH's footer is the **weak** form (*"This **project** is supported by ...
$208,374,447.57"*), so per session 27's audit it corroborates the **amount**
against the §7.1 anchor and three programme-scoped sentences carry the
provenance — LDH's own opening sentence, the Governor's 2026-04-07 release
(*"supported by more than $208 million in federal funding"*), and **LED's Rural
Tech Catalyst Fund release**, which is the only one published by an agency other
than LDH (*"Supported through the Rural Health Transformation Program, a more
than $1 billion federal investment over five years"*). The deck states the award
itself: *"Louisiana awarded $208,374,448 for Budget Period 1"*.

### The controls

**The positive control is unusually cheap and unusually strong: Louisiana names
the FORM its announcement will take and the WINDOW it will take it in.** So "no
roster" is measured against the state's own stated intention rather than against
our guess at its format.

**And even what Louisiana has promised is not a roster.** The deck's next-steps
slide says the *"Next Advisory Council meeting agenda [is] to include a complete
list of obligated funds **by entity type**"* — by type, not by recipient.

**The §0.3 control is `rhtla.net/api/facilities`**: 3,576 named Louisiana
facilities — **305 hospitals** (170 acute care, 135 specialty), 859 RHCs, 78
FQHCs — with addresses, services and coordinates, on the RHTP programme's own
second domain, and *"award"*, *"amount"*, *"$"*, *"RHTP"* and *"fund"* occurring
**zero times each**. It is the dataset behind the *"Is my location rural?"*
eligibility tool. **California's 102 SRHRP eligible hospitals in
machine-readable form, three times the size.**

### One host is unreadable, and is recorded as unreadable (§0.4)

`rhtla.net` — the "Rural Health Atlas", Louisiana's second RHTP site — serves an
**unrendered Vue application**: its mustache templates arrive as literal
`{{ copy.brand }}` text. Maine's CGI Advantage portal and Connecticut's CTsource
in a new costume. Whether the Atlas surfaces award data behind its parish
profiles is **UNKNOWN**, a statement about our access and never about Louisiana.

### The host wants a Mozilla prefix, and that is NOT Michigan's exception

| agent | ldh.la.gov |
|---|---|
| the project's own `AHA-RHTP-Tracker/0.1 (+url…)` | **403** |
| RFC crawler convention `Mozilla/5.0 (compatible; AHA-RHTP-Tracker/0.1; +url)` | **200** |
| bare `Mozilla/5.0` | **403** |
| full Chrome | 200 |

**The form that works carries our name and our contact URL**, so this is session
10's medicaid.gov answer — *identifying honestly is the fix* — and **not**
session 27's michigan.gov exception, where the identifying tokens are precisely
what get refused and a bare agent was the only thing that worked. `robots.txt`
here is **404, genuinely absent**, where Michigan's is 403: no crawler policy
exists and none is being declined. `la_agent_for()` refuses any agent lacking
both tokens, on any host, with a test driving it.

### The seventh digest mechanism, and the second that is attribute-borne

`ldh.la.gov` runs **Cloudflare Email Address Obfuscation**, which XOR-encodes a
mailto with a **random one-byte key on every render** into an `href` and a
`data-cfemail` **attribute**. Three fetches gave **three distinct file digests
at exactly 169,500 bytes each**.

It is **California's `antispambot()` finding on a different platform**, and
**constant-length like California's**, so a byte-count check passes it. Because
it lives in attributes rather than a script body it is **Connecticut's `?v=`
stamp structurally**, and the tag-stripping reduction absorbs it for free:
reduced text identical across all three at **21,249 characters**. `--probe`
compares a CONTENT digest, never a file digest, and a test synthesises the
re-roll offline to prove both halves.

### One parse defect found and fixed

`la_deck_funding_cycle()`'s first regex started the segment at *"Anticipated
Announcement"*, and because the column headings and the first data row are
painted contiguously the lazy name capture **swallowed the heading into row 1's
activity** (*"Anticipated Announcement Rural Clinici…"*). Fixed with a
lookbehind, and a test asserts no activity contains *"Anticipated"*.

**And the name comparison cannot depend on the deck's word spacing.** Its
producer paints *"Food isMedicine"* and *"Rural Clinician CreditBank"* — two
runs on one line separated by pen positioning rather than a space glyph, which
session 32 measured and which the reader cannot recover without font metrics. So
the candidate-to-activity match normalises to **letters only**.

### Louisiana is on a schedule

`R/03ae_la_year1_probe.R --probe`, Routine `trig_01BqyRZ4d8S8EvKdtCN9nmX5`,
**Wednesdays and Saturdays 12:50 UTC**, first fire 2026-09-05. Twice-weekly, and
on the tightest clock in the project: seven windows, all already past. It ran
live and reports **UNCHANGED** on all three watched surfaces.

**Louisiana contributes no row and no dollar to any hospital bucket.**

---

## 5. Tests

**4,095 assertions across 40 files, all passing and 1 self-skipping** (was
3,917 across 39). Two new files:

- `test_02b_provenance_sweep.R` gains four tests for the two-dates trap, which
  read all three archived NOAs and drive the counterfactual.
- `test_03ae_la_year1_probe.R` — 151 assertions, weighted towards the tripwires
  (every award phrase fed to every watched surface and required to throw, plus
  a check that no surface already carries one), the tier defect's three
  simultaneous proofs, and the dropped capital row.

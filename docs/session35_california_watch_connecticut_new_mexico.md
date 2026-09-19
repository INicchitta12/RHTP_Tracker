# Session 35 — California on a watch; Connecticut's award date has passed; New Mexico stacks three defects

**Date:** 2026-09-02
**Quota:** zero RCJ calls. ~30 requests to `portal.ct.gov`, ~20 to `www.hca.nm.gov`,
3 to `hcai.ca.gov` (the California probe), throttled per §9.5.

---

## 0. What this session did

1. **California is on a schedule.** Routine `trig_013vujTBLopT2gSmNwWJ94ig`,
   **Wednesdays and Saturdays 17:00 UTC**, running `R/03ab_ca_year1_probe.R --probe`.
   The probe ran live first and reports **UNCHANGED** on all three watched pages
   with the tripwires passing.
2. **Connecticut extracted as a NEGATIVE** — `R/03ac_ct_year1_probe.R`, 6 status
   rows, 3 disposition rows, 10 archived sources, **no award file**.
3. **New Mexico extracted as a NEGATIVE** — `R/03ad_nm_year1_probe.R`, 8 status
   rows, 1 disposition row, 9 archived sources, **no award file**.

Both states read `INVESTIGATED_NO_LIST` in `rcj_state_survey.csv` and
`state_trigger_queue.csv`, both **rebuilt** from the constants in `R/03k`
rather than hand-edited (session 32's rule).

**Neither state contributes a row or a dollar to any bucket of
`rhtp_hospital_dollar_partition()`.**

---

## 1. California: the watch

The probe was run live before the Routine was created, because a schedule
around a probe nobody has run is a schedule around an assumption:

```
[CA] LIVE probe, 2026-09-02 13:06:51 UTC
  funding    UNCHANGED  6d93caeb423c4c7b
  calrht     UNCHANGED  f915e16f61fb294a
  newsroom   UNCHANGED  480d4518dcbc1213
[CA] the award tripwires pass against the LIVE bytes.
```

**Wednesdays and Saturdays** rather than Wisconsin's and Maine's Tuesdays and
Fridays, so the four watches spread across the week rather than colliding.
17:00 UTC keeps it clear of Missouri's Wednesday 15:00.

The Routine's prompt carries the three things a future session most needs and
would otherwise have to re-derive: that the file digest is **known useless** on
`hcai.ca.gov` and must not be "simplified" back (the cache variant and the
`antispambot()` re-roll), that every CalRHT pool's eligible class is **hospitals
among others** and therefore §0.3, and that the **SRHRP must not be let back
in** — eleven named California hospitals, $5,475,000, cigarette-tax seismic
money.

### One correction to `R/03ab`'s header

The file header still claimed `hcai.ca.gov`'s "page digests are STABLE ... So a
FILE digest is the change test here", which is the wrong claim session 34 made
and then caught — `ca_probe()`'s own docstring already carried the correction.
A header that says the opposite of the code it heads is exactly the hazard §2.1
exists for, so the paragraph was replaced with what was measured. **No code
changed and `ca_year1_status.csv` rebuilds byte-identical.**

---

## 2. Connecticut — the first negative whose award date has ALREADY PASSED

### The route in was `/api/v1/activity`, a sixth time

`state_source_url` is NA on all 7 Connecticut Tier 3 records.
`stage2_state_sources.rds` held **seven real `portal.ct.gov` URLs**, including
the DSS RHTP programme page, its Documents page, DSS's press room, OHS's NOFO
release and OPM's RFP index. Oregon's, Oklahoma's, Nevada's, Missouri's and
Maine's lesson, working again.

### What Connecticut has published

DSS is the lead agency for a **$154,249,105.53** Budget Period 1 award,
"partnering with other state agencies to implement **30 projects**" across four
initiatives. Its RHTP **Documents page carries eight documents** — the
application, the Governor's endorsement letter, CMS's Notice of Award, the
project narrative, the budget narrative, project summaries, overview slides and
two webinars — and **not one is an award roster**.

**One recipient-level solicitation has run, and its award date has gone by.**
OHS's **NOFO #26OHS001** (Health Care Coordination and Remote Patient
Monitoring Using AI) offers **$1.8 million** in Year 1, **up to 5 awards** of
**$100,000–$1,000,000**. OPM publishes its full timeline:

| Milestone | Date |
|---|---|
| NOFO Announced | May 22, 2026 |
| Applications Due | **July 7, 2026, 2:00 PM ET** |
| Contract Negotiation Period | July 27 – August 14, 2026 |
| **Grant Awards Announced** | **August 17, 2026** |
| Period of Performance (Year 1) | September 10, 2026 – August 30, 2027 |

**This session ran 2026-09-02 — sixteen days after that date — and no roster
exists on any reachable Connecticut host.** Wisconsin's negative was dated to a
month in the future; California's to the fortnight it ran in; **Connecticut's
date has gone by**, and `ct_assert_award_date_passed()` asserts that ordering
rather than narrating it.

**And the state says in its own words that nobody has been chosen:** *"Parties
interested in being subrecipients of RHTP funding are encouraged to check back
here on this webpage regularly for updates, as well as the state procurement
website/portal and other standard channels for potential funding
opportunities."*

### §6.2 in its strongest form — the third state to publish CMS's own NOA

Not a footer quoting an award: the award. `noa_rhtcms332073-01-03.pdf` is CMS's
own form — recipient **DEPARTMENT OF SOCIAL SERVICES CONNECTICUT**, Assistance
Listing **93.798** Rural Health Transformation Program, Award#
**RHTCMS332073-01-03**, budget period **12/29/2025 – 10/30/2026**,
**$154,249,105.53**, statutory authority *"Big Beautiful Bill Act of 2025,
Section 71401"*. Nevada was first (session 26), California second (session 34).

**And California's two-dates trap, a second time and wider.** The NOA's Federal
Award Date is **07/23/2026** and its Award Action Type is **"Revision
(Budget)"**, while the budget period still starts **12/29/2025**. California's
revision was three months after the award; **Connecticut's is seven**. A date
test keyed on "Federal Award Date" would read Connecticut's award as seven
months late and quarantine every genuine Connecticut row as
`PROVENANCE_PREDATES_NOA`. Both are asserted together, deliberately.

**One closure, unarranged.** The NOA names *"Mr. Daniel Mize Sinclair,
Director, Rural Health Transformation Program"* and *"Julie Vigil, Deputy
Director"*; DSS's own press release of 2026-04-10 names Daniel Sinclair as
Project Director and Julie Vigil as Deputy Director of Operations. One federal
publisher, one state publisher, nothing arranged — and a test asserts both.

### The footer is the WEAK form and is demoted anyway

Connecticut's reads *"This **project** is supported by … $154,249,105.53 in
Budget Period 1"* — session 27's weak form, a claim about the paper. It is used
for the **amount** only, where it matches the §7.1 anchor ($154,249,106) to the
cent, and `strict = FALSE` is the switch Kansas, New Hampshire, Wisconsin and
California already carry. Two programme-scoped sentences carry the provenance.

### §0.1 — Oklahoma's defect, and a mechanism this project had not recorded

All seven Connecticut Tier 3 candidates come from **one document in two
revisions** — Connecticut's RHT Budget Narrative — and their "awardees" are the
implementing agencies and named budget columns:

| Group | Rows | RCJ amount | What it actually is |
|---|---:|---:|---|
| State agencies named as implementing subrecipients | 4 | $40,754,129 | DPH $21,714,915, OHS $7,689,978, DMHAS **twice** at $5,749,236 and $5,600,000 |
| One planned contractor, carried twice | 2 | $7,600,000 | Carelon Behavioral Health, Inc., **$3,800,000 counted twice** |
| A proposal name read as an awardee | 1 | $1,500,000 | "Area Health Education Center (AHEC)" |
| | **7** | **$49,854,129** | **RHTP subawards: 0** |

The $49,854,129 is `rcj_state_survey.csv`'s own figure for Connecticut, and the
disposition **asserts** that reconciliation rather than noting it.

The narrative's section heading for each agency is *"&lt;agency&gt; — Required
reporting information for **subrecipient**"* — the pass-through structure
**inside state government**, one tier above any provider. Carelon is printed as
*"Contractor 1 Carelon Behavioral Health, Inc."* in an itemised budget
justification. AHEC is *"Proposal: W03-Area Health Education Center (AHEC)
Expansion"* with *"Contractor 1 AHEC"* as a **budget column heading**, under
UCHC's own *"UCHC Contracts: $1,500,000"* section — §6.1's
`PROGRAM_NAME_AS_AWARDEE`.

**And the new mechanism is the double-counting: RCJ PRICES DOCUMENT REVISIONS
AS SEPARATE AWARDS.** Connecticut published the narrative twice; RCJ carries
Carelon's single $3,800,000 line from **both** revisions as two candidates, and
carries DMHAS's adult mental health line at **two different amounts** —
$5,749,236 from one revision and $5,600,000 from the other. New Hampshire's
CDFA appeared under three spellings at three prices (session 29); this is the
same failure caused by **revision** rather than by spelling, and it is the
cleaner case because the underlying document is provably one line item.

**The narrative says in its own words that it is a plan:** *"Personnel salaries
will be updated **once awarded**."* Its contractor lists end *"and Similar"*;
one names *"Rural Community Mental Health Services Provider(s) **TBD**"*; its
summary table is headed *"Proposal"*.

**NOT ONE Connecticut candidate is a named hospital** — unlike California's
eleven of eleven and New Mexico's two of seven — so its $0 is not at risk from
a name-keyed read. A test pins that.

### The controls

**POSITIVE (the channel).** OHS demonstrably publishes named, recipient-level
decisions in a recognisable form: *"Office of Health Strategy Approves UCONN
Health Affiliate's Acquisition of Waterbury Hospital"*, *"Approves Hartford
HealthCare Subsidiary's Acquisition of Eastern Connecticut Hospital"*. So
"Connecticut has published no RHTP roster" is a statement about the programme
and not about our reading. Its **four** RHTP items are all pre-award: the NOFO,
its legal notice, and two rounds of Q&A.

**NEGATIVE (governance).** DSS's **only** RHTP press release announces a
**LEADERSHIP TEAM** — *"naming four experienced public health professionals to
guide the initiative"* (2026-04-10). It names **people**, not organisations,
and attaches no money. Missouri's Hub Anchors were a governance roster of 27
**organisations** that RCJ priced at $1 each; Connecticut's is one tier further
from money still.

**UNREADABLE (§0.4).** The state directs subrecipients to the **CTsource
Contracting Portal**. `portal.ct.gov/das/ctsource/bidboard` answers 200 but is
a landing page onto an external stateful application this environment cannot
search — Maine's CGI Advantage portal on a different vendor — and
`biznet.ct.gov` answers **403**. Whether an RHTP contract has been executed
inside CTsource is a statement about **our access**, never about Connecticut.
The row reads `publishes_roster = UNKNOWN`.

### The fifth digest mechanism, and the first that is PER-NODE

`portal.ct.gov` stamps a cache-busting **`?v=<yyyymmddHHMMSS>`** on seven
static asset URLs, and the value is the **serving node's asset build time**.
Six fetches of the OPM page:

```
      bytes   file digest
  1   80531   eed8d13d74cf4c20
  2   80531   84896bbdce07c3b5
  3   80531   b5d6bb3b806593d6
  4   80531   35a17ed6d21143e0
  5   80531   b5d6bb3b806593d6     <- repeats fetch 3
  6   80531   19f0b2040d38a727
```

**Same length every time, five distinct digests, one repeating** — so it is a
small finite set of values, one per node, not a per-request nonce. Distinct
from all four on record: Nevada rotates page **content**, Missouri an Incapsula
cache-buster in a script **SRC**, Wisconsin an Akamai Boomerang nonce in a
script **body**, California a cache **variant** of differing length.

**And it sharpens California's lesson rather than repeating it.** A
back-to-back pair run against **two pages of this one host** gave **SAME** on
the DSS programme page and **DIFFER** on the OPM page **in the same minute**:
whether the pair catches it depends on which node answers, so a "SAME" result
is not evidence of stability **even for the page it was run on**.

`ct_reduce_html()` absorbs it for free — the `?v=` lives in `href`/`src`
**attributes**, and replacing every tag with a space discards attributes
entirely. The reduced text was **identical across all six fetches at 8,983
characters**, and it is the same reduction the assertions read (Missouri's
rule).

`--probe` ran live: **all five watched pages UNCHANGED**, tripwires pass.

---

## 3. New Mexico — three recorded defects in one candidate set

### What New Mexico has published

HCA runs RHTP and has opened **six procurements**. Every one is pre-award, in
HCA's own words:

| Procurement | Stated | Stage, in HCA's words |
|---|---|---|
| Healthy Horizons | $76.2M, six regional hubs | "Currently under evaluation" (applications due 2026-07-02) |
| Rural Health Innovation Fund | $47M | "Currently under evaluation" (proposals due 2026-07-27) |
| Administrative Services Organization RFP | — | "Currently under evaluation" |
| Center for Rural Health Sustainability & Innovation | — | "Currently under evaluation" |
| Rooted in New Mexico | — | **"Submissions due: September 4, 2026"** — two days after this ran |
| Rural Health Data Hub | — | "Submissions due: TBD"; RFP "Coming Soon" |

**Not one named recipient anywhere.**

§6.2 with the footer demoted: HCA's is the weak form (*"This **project** is
supported by … $211,484,740.89"*), matching the §7.1 anchor ($211,484,741) to
the cent, and two programme-scoped sentences carry the provenance — *"Authorized
under H.R. 1, Public Law 119-21, the RHT Program is a national investment"* and
the Innovation Fund release's *"The Rural Health Innovation Fund **is part of**
New Mexico's Rural Health Transformation Program"*.

### §0.1 — three defects, and the third is what makes the other two invisible

All seven candidates come from the **Rural Health Care Delivery Fund (RHCDF)**.

**1. The wrong PROGRAMME** (Texas's, California's). The Governor's own release
says it in one sentence: *"41 rural health care providers and facilities will
receive a combined **$50 million in state funding** from the Rural Health Care
Delivery Fund"*. The fund was *"originally established in **2023**"* and
*"received an additional $50 million during the **October 2025 special
session** at the governor's request"* — a state appropriation made **before**
the 2025-12-29 CMS Notice of Award. HCA's own RFA webinar deck calls it *"a $50
million **state** investment"* and contains **"RHTP", "Rural Health
Transformation", "CMS" and "federal" ZERO TIMES EACH** — and that deck is the
document RCJ sourced the rows from.

**HCA's own site architecture agrees.** The RHCDF sits under the Primary Care
Council; the RHT Program is a sibling menu item. The RHCDF page mentions "Rural
Health Transformation" **three times and all three are the navigation menu** —
its prose never names the programme — and it carries **no CMS footer at all**.
Its one mention of CMS is New Mexico's **Turquoise Care 1115 Medicaid waiver**,
*"approved by the Centers for Medicare & Medicaid Services on July 25, 2024"* —
seventeen months before the RHTP award.

**2. The wrong SECTION** (Nebraska's, session 23). Every row is filed under
*"NM - 2026 - RHCDF Announces Stabilization Fund: $50 Million Rural Health
Funding Opportunity for **FY27-29**"* — a **future** opportunity whose
applications opened 2026-03-16. But the seven **names** are not applicants to
it. They are **FY26-27 funding recipients**, a **past** award roster printed
further down the same page. RCJ took its title from one section and its rows
from another.

**And the capture is partial in its own telling way.** The FY26-27 roster's
first eight names in document order are Cañoncito, Cibola General, Duke City,
First Nations, **Gallup Community Health**, Las Cumbres, New Mexico Premier
Health and Alta Vista. RCJ carries seven of those eight and **drops Gallup** —
Texas's 32-of-33 (session 19) and Kansas's Greeley County (session 20) a third
time. Asserted, in both directions.

**3. The $1 PLACEHOLDER** (Missouri's, session 28; Maine's, session 33). Every
row is priced at **$1**, so New Mexico's whole `rcj_federal_amount_sum` is
**$7**. **And here that is what hides the other two**, because a row priced at
$1 reads as missing data rather than as the wrong programme.

**Two of the seven are named New Mexico hospitals** — Alta Vista Regional
Hospital and Cibola General Hospital — so the shape is California's SRHRP
again: real, executed, named, recipient-level **state** awards to rural
hospitals, published by **the same agency that administers RHTP**. What keeps
the dollar cost at $0 here rather than California's $5,475,000 is **only** that
RCJ priced them at $1. `nm_assert_placeholder_amounts()` fails the day that
changes.

### The controls, and they sit one click apart

**POSITIVE.** HCA demonstrably publishes award announcements with named
organisations on its own news feed — *"New Mexico awards $50 million to 41
rural healthcare organizations"*, *"New Mexico awards $24.5 million under
behavioral health reform law"* — and publishes recipient-level rosters per
RHCDF cycle (*"FY26-27 — Total Funding Recipients: 30"*). So the RHT
programme's silence is the programme's.

**AND THE POSITIVE CONTROL AND THE §0.1 NEGATIVE ARE ONE CLICK APART ON ONE
FEED, WHICH IS THE TRANSFERABLE WARNING.** *"New Mexico awards $50 million to
41 rural healthcare organizations"* (2026-08-04, **state** money, awarded,
named — including Socorro General Hospital, Sierra Vista Hospital and Clinics,
Holy Cross Medical Center, Cibola General Hospital) sits **four items** from
*"NM opens $47 million fund for rural health projects"* (2026-07-07, **RHTP**,
open, unnamed). A hunt that scans a state news index for "awards" + "rural" + a
large figure takes the state one every time. Both headlines are asserted on the
same archived index, deliberately.

### Where New Mexico's hospital money will be

**Healthy Horizons, $76.2 million**, six regional hubs. HCA *"will select six
organizations to manage hub regions"*; each *"must use at least 90% of its
award to support local projects"*; and hubs *"are not expected to provide all
services directly. Instead, they will coordinate local efforts and **direct
funding to** providers, Tribal health programs, community organizations, public
health groups and other partners"*.

That is **Missouri's ToRCH hub shape**, and its downstream class is providers
**among others** — New Hampshire's FHC answer (`PASS_THROUGH_UNRESOLVED` +
`Unclear`, in **neither** bucket), not Illinois's ICAHN answer. It is a
pass-through question when it lands, not a direct award.

### The sixth digest mechanism

`hca.nm.gov` runs the WordPress **Complianz** cookie-consent plugin, which
writes a `privacy-statement-children` URL into a JSON config inside a script
body — and **draws that URL from the site's own posts at random on each
render**. Twenty minutes apart it served `/snapchanges/` and a 2021
suicide-prevention press release, moving the page from **199,369 to 199,464
bytes**.

It is California's `antispambot()` finding one plugin over, with one difference
that matters: **California's re-roll was constant-length and this one is not**,
so a byte-count check passes California's and fails this. And **three fetches
seconds apart here were byte-identical** while the copy taken twenty minutes
earlier was not — California's lesson confirmed a **third** time, by a third
mechanism.

Stripping script bodies absorbs it: the reduced text is identical across all
four copies at **6,978 characters**.

`--probe` ran live: **all three watched pages UNCHANGED**, tripwires pass.

---

## 4. What did not change

- **No award file was written for either state**, and a test asserts the
  absence of both `ct_year1_awardees.csv` and `nm_year1_awardees.csv`.
- **Neither status table has an `amount` column**, and an assertion refuses one
  (Texas's device).
- **No hospital figure moved anywhere in the repository.** Neither state
  contributes a row or a dollar to any bucket of
  `rhtp_hospital_dollar_partition()`.
- **The §6.2 sweep is untouched.** Neither state's candidates are caught by it,
  and that is a statement about the registry's coverage rather than about the
  states — Nebraska's lesson (session 23). Both are now disposed of by hand
  with their evidence archived, which is what the registry is for.

---

## 5. What to watch, and when

**CONNECTICUT is the most overdue negative in the project.** Its own award date
was **2026-08-17**. `ct_assert_no_award_roster()` watches three surfaces and
`ct_assert_award_date_passed()` fails if OPM's NOFO comes down — which would
itself mean Connecticut had awarded. Its pool is small ($1.8M, up to 5 awards)
but its **eligible class leads with hospitals**, so the first named recipient
could be a Connecticut hospital.

**NEW MEXICO's Rooted in New Mexico closed 2026-09-04**, two days after this
ran, and four procurements are "currently under evaluation". **Healthy Horizons
at $76.2M is the one that matters** and it is a hub model, so when it lands it
is a `PASS_THROUGH_*` question and §0.3 governs it.

Neither is on a Routine yet. Both `--probe` entry points exist, both ran live
this session, and both are one `create_trigger` call from a schedule.

---

## 6. The watch's fourth firing, 2026-09-12 — ALL FIVE PAGES CHANGED, AND NONE OF IT IS AN AWARD

The Wed/Sat Routine (`trig_013vujTBLopT2gSmNwWJ94ig`) fired at 17:06 UTC and
reported **CHANGED on every one of the five watched pages at once**. It is not
an award, and the shape of the answer is what makes it worth writing down.

### 6.1 Five pages moving together is a statement about the HOST, not the state

Two of the five — both RHPC pages — were archived **three days earlier**. Five
independent content edits across one estate inside 72 hours is implausible; one
change to something every page carries is not. The reduced text says which:

| page | reduced chars, archived -> live | bytes served |
|---|---|---|
| funding | 12,071 -> 12,083 | 167,530 -> 167,462 |
| calrht | 11,212 -> 11,224 | 158,290 -> 158,222 |
| newsroom | 9,906 -> 9,918 | 150,605 -> 150,629 |
| rhpc | 8,457 -> 8,469 | 148,620 -> 148,552 |
| rhpc_members | 24,944 -> 24,977 | 166,723 -> 179,610 |
| srhrp (control, not probed) | 19,067 -> 19,079 | 182,650 -> 182,674 |

**Exactly +12 characters on five of the six.** A word-level diff names it in one
line: HCAI renamed a label in its **site-wide navigation menu**, from
*"Reproductive Health Care Access Initiative"* to *"Reproductive Health and
Gender Affirming Care Programs"* — 42 characters to 54. Nothing to do with RHTP,
on every page of the estate.

### 6.2 THE THIRD DIGEST MECHANISM ON THIS HOST, AND THE FIRST THAT CANNOT BE ABSORBED

`hcai.ca.gov` has now produced three:

1. **A cache variant** (session 34) — the ~15 KB ElasticPress autosuggest block
   present or absent. Per-render. The reduction absorbs it.
2. **`antispambot()` re-rolling email entities** (session 34) — same length,
   different bytes, identical rendered text. Per-render. Absorbed.
3. **A global navigation rename** (this firing) — and it is **different in
   kind**. The first two are noise the same page emits twice; this is a **real,
   persistent content change** that happens to sit on every page. There is
   nothing to absorb, only a baseline to refresh.

It is also the fourth time the project has met a mechanism that a back-to-back
fetch pair cannot see, and the first where the invisibility is not the point:
the change is real and permanent, so *any* interval exposes it.

### 6.3 THE NAVIGATION IS DELIBERATELY NOT REDUCED AWAY

The obvious fix is to discard the global menu in `ca_reduce_html()`, which would
retire this class of false positive for good. **It is refused**, and the reason
is the probe's whole purpose: a new *"CalRHT Awardees"* item in that menu is the
**first place an award page would be linked from**. Silencing the nav to stop it
crying wolf would silence the one signal most likely to arrive. So the cost is
paid on the noise side — refresh the baseline, write the mechanism down — which
is Missouri's Incapsula rule (session 29) applied to a change that is real
rather than spurious. A test plants *"CalRHT Awardees have been awarded"* in the
menu and requires the tripwire to fire on it.

### 6.4 THE MEMBERS PAGE MOVED 33 CHARACTERS, AND THE OTHER 21 ARE THREE BIOGRAPHY EDITS

`rhpc_members` is the one page that moved by more than the nav, and all three
extra edits are copy fixes inside **existing** biographies:

- *"Joy Dockter, Attorney,"* -> *"Attorney at"* (+2) — a title correction.
- *"**He** has practiced across communities…"* -> *"**James F. Schlund** has
  practiced…"* (+14) — a pronoun replaced by the member's own name.
- *"**She** is currently a board member for Mercy Housing California"* ->
  *"**Dr. Soni** is currently…"* (+5) — likewise.

12 + 2 + 14 + 5 = **33**, which closes on the measurement exactly. **No member
was added or removed** (29 heading markers before and after), the three currency
figures on the page are unchanged ($300, $38, $96 — none of them an award), and
the single occurrence of *"awarded"* is the **same pre-existing sentence** about
a scholarship fund that *"has awarded 245 scholarships to date"*. That sentence
is why `CA_RHPC_AWARD_POSTED` was kept deliberately narrow in session 45, and it
still does not fire. Both pinned hospitals — **Community Memorial Hospital-Ojai**
and **Plumas District Hospital** — are still present, so the compounding trap
§6.1 of this document records is unchanged.

The page's byte jump of **+12,887** is the session-34 cache variant on top of
the content change; the reduction absorbs that half and reports the other.

### 6.5 What moved in the repository, and what did not

- **All six HTML sources re-fetched and re-baselined.** Every one moved in
  CONTENT this time, so — unlike session 45, where three files moved in bytes
  only and were reverted — **there was nothing to revert**. The six PDFs (the
  NOA, the budget narrative, the four grant guides) are byte-identical.
- **`ca_year1_status.csv` and `ca_rcj_candidate_disposition.csv` rebuild
  BYTE-IDENTICAL.** No dollar and no row moved anywhere, in any state.
- **All five pages now report UNCHANGED** and the tripwires pass against the
  live bytes.
- **Three typed values in `ca_write_manifest()` became derived.** Session 45
  caught this manifest still carrying session 34's *retracted* claim that the
  file digest was the change test, because the generator was corrected and
  `--fetch` was never re-run. Two more had gone the same way since: a
  present-tense character count (*"11,162 characters"*, by then 11,224) and a
  single archive date (*"taken 2026-09-02"*, for files last refreshed
  2026-09-12). Both are read off the archive now. **And the governance block
  said *"ADDED SESSION 36"* when session 45 added it** — a third stale typed
  value in the same generated artifact, corrected with a test pinning all of
  them.

### 6.6 THE OPERATIONAL FINDING: SESSION 45's CODE IS NOT ON `main`

`main` is at **session 44** (`1213f0d`, PR #45, which carries session 44's
work). Session 45's California branch — `claude/ca-ct-nm-watch-8hfcho` at
`b892894` — **has never been merged**, and the consequence is live rather than
cosmetic:

- `main`'s `CA_PROBE_KEYS` is the session-34 **three**-page set. The two RHPC
  pages are not watched there at all.
- `main` carries neither `ca_assert_rhpc_is_governance()` nor the two
  `*_GOVERNANCE.html` archives, and its `ca_year1_status.csv` is 6 rows.
- The Routine's own prompt says to work on `main`, and its guard — `grep -c
  "ca_probe"` — returns **4** there, so the guard passes and the probe runs.
  **The guard checks that a probe exists, not that it is the current one.**

So the watch has been running a version three pages narrow since 09-09, and its
own staleness check could not see that. The remedy is to merge the branch; the
lesson is that a guard keyed on a function's *existence* does not detect a
*stale* implementation, and the next probe prompt should pin something that
moves when the file does.

---

## 7. The watch's fifth firing, 2026-09-16 — CMS REVISED CALIFORNIA'S NOTICE OF AWARD, AND IT IS PAPERWORK

All five pages reported CHANGED again. Two separate things, and only one of
them matters.

### 7.1 The global menu moved a second time, so §6.2's mechanism RECURS

A Data Resources item went from *"Financial Health of California Hospitals"* to
*"Inpatient Hospital Costs by Region"* — **−6 characters on every one of the six
archived HTML sources**, the same shape as the 09-12 nav rename (+12). So HCAI
edits its global navigation often enough that this is a **recurring** false
positive rather than a one-off, and the decision in §6.3 above — *do not reduce
the navigation away, because a new "CalRHT Awardees" item is the first place an
award page would be linked from* — is re-taken rather than re-argued each time
it fires. A test now pins both edits.

### 7.2 AND ONE CHANGE ON THE CALRHT PAGE ALONE: THE NOA LABEL

`calrht` moved −5 where every other page moved −6, and the extra character is
the finding. HCAI's own Additional Resources list relabelled one document:

> CalRHT Notice of Award **(March 31, 2026)** → CalRHT Notice of Award
> **(August 28, 2026)**

The link is a stable landing path (`/document/calrht-notice-of-award/`) that
serves the PDF directly, so **the document behind an unchanged URL had been
replaced**. It is archived as a new source, `cms_noa_r04`, and **`-01-02` is
kept** — Alaska's rule (a rolling document's movement is only measurable
against the snapshot it moved from) and Iowa's (18093 is superseded by 18330
and both stay). Re-fetched from its own dated upload URL, `-01-02` comes back
**byte-identical**, which is what makes holding both honest.

| | `-01-02` (archived) | `-01-04` (new) |
|---|---|---|
| Award # | RHTCMS332078-01-02 | **RHTCMS332078-01-04** |
| Federal Award Date | 03/31/2026 (**+92 days**) | **08/28/2026 (+242 days)** |
| Award Action Type | Revision (Budget) | **Revision (NoA Other)** |
| Budget period | 12/29/2025 – 10/30/2026 | 12/29/2025 – 10/30/2026 |
| Total | $233,639,308.47 | $233,639,308.47 |

**IT MOVES NO MONEY AND NO DATE THAT MATTERS, AND ITS OWN REMARKS FIELD SAYS
SO**: *"This notice of award approves the key personnel change per the
recipient requests. Michael Valle is now listed as the Authorized
Organizational Representative (AOR). All other terms and conditions remain in
effect."* The amount agrees **to the cent** and the budget period **to the
day**. Nothing about California's award changed; an official was renamed.

### 7.3 WHICH MAKES SESSION 36's DATE PIN MEASURED RATHER THAN ARGUED

Session 36 pinned the project's NOA anchor to the **budget period start** and
not to the field labelled *"Federal Award Date"*, reasoning from **three
states'** revised documents that the latter is the date of the **latest
revision** and that *"the error grows with every revision"*. That was an
inference across states. **California is now the same award, twice:**

```
anchor (budget period start)   2025-12-29   -- has NOT moved
-01-02  Federal Award Date     03/31/2026   +92 days
-01-04  Federal Award Date     08/28/2026   +242 days
```

**+242 days is the widest gap in this repository**, past Connecticut's +206 —
and it was produced by a revision that renamed an officer. A date test keyed on
those three words would now read California's award as **eight months late** and
quarantine every genuine California row. `ca_assert_noa_revisions()` asserts the
gaps are strictly increasing and prints them, so the drift is recorded rather
than overwritten.

### 7.4 "Revision (NoA Other)" IS A THIRD ACTION TYPE, AND IT BREAKS A PINNED STRING

Every NOA this project holds reads **"New"** (Kentucky, the only original) or
**"Revision (Budget)"** (NV, CA, CT, WY). `-01-04` reads **"Revision (NoA
Other)"**.

The old `ca_assert_noa_is_cms_award()` pinned the literal `"Revision (Budget)"`
as *"the word that keeps its 03/31/2026 Federal Award Date from being read as
the award date"* — which was pinning **one revision's wording** to carry a
general point. Against the live document that string is simply absent. The
invariant is now stated as what it always was: **the document is a revision of
this FAIN whose budget period and amount have not moved**, and *which kind* of
revision it is lives in `CA_NOA_REVISIONS` as data, one row per document.
`CA_NOA_MARKERS` is retired into `CA_NOA_INVARIANT` (shared) plus that table
(per-revision).

### 7.5 THE WATCH DID NOT CATCH THIS BY DESIGN — IT CAUGHT IT BY LUCK

`cms_noa` is **not** in `CA_PROBE_KEYS`, and could not be: a PDF has no
`ca_reduce_html()` reduction, so nothing in the probe watched CMS's own award
document at all. What surfaced the change was the programme page's own dated
label, inside a reduced-text diff **nobody was required to read** — the probe
would have reported `calrht CHANGED` either way, and a reader who refreshed the
baseline without diffing would have archived the new label and never opened the
document.

So the tripwire is now explicit and cheap. `ca_assert_noa_label_current()`
parses HCAI's own *"CalRHT Notice of Award (<date>)"* label off a page the probe
already fetches and **fails unless it names a revision this repository holds**.
It runs against the LIVE bytes in `ca_probe()` (session 25's Indiana lesson) and
fires the day CMS issues revision 05. Losing the label is also a failure rather
than a pass, because the label is the only thing watching that document.

### 7.6 One §0.3 note from the new document's budget table

`-01-04`'s approved budget puts **$223,227,780.00 — 95.5% of the award — in
CONTRACTUAL**, against $3,830,262.47 of personnel, $349,233 of supplies and
$57,550 of travel; direct costs $227,464,825.47 plus $6,174,483 indirect close
on $233,639,308.47 exactly. **That is a budget line and it names nobody.** It is
where every California subaward will come from, and it is not a pool anyone has
been awarded. The earlier revision is worth reading beside it: `-01-02` lifted a
**$50,000,000 restriction** on contractual funds and requires *"a complete
description and cost breakdown ... for each consultant, subrecipient, or
contract upon selection"* — a CMS reporting obligation that may be what
eventually produces California's roster.

### 7.7 What moved

- **`cms_noa_r04` archived; `-01-02` kept and byte-identical.** Six HTML
  baselines refreshed for the menu swap and the label.
- **Both CA CSVs rebuild BYTE-IDENTICAL.** No dollar, no row, no bucket moved,
  in California or anywhere else.
- All five watched pages report UNCHANGED after the refresh; tripwires pass.
- `main` is **still at session 44** — see §6.6, unchanged and now four firings old.

---

## §8 — Session 48: the council grew, and the trap it carries is no longer
## bounded by the aggregator

The Wed/Sat Routine (`trig_013vujTBLopT2gSmNwWJ94ig`) fired **2026-09-19 17:05
UTC** and reported **CHANGED on all five watched pages for the third run
running**. Two separate things again, and this time the second one is a
finding about the estate rather than about a document.

### 8.1 The nav moved a THIRD time, and the measurement names it in one line

**Four of the five watched pages moved by exactly −69 characters of reduced
text, and so did the SRHRP control** — six sources, one delta:

| source | bytes | reduced chars |
|---|---:|---:|
| `funding` | 167,450 → 167,300 | 12,077 → 12,008 (**−69**) |
| `calrht` | 158,207 → 158,149 | 11,219 → 11,150 (**−69**) |
| `newsroom` | 150,607 → 150,467 | 9,912 → 9,843 (**−69**) |
| `rhpc` | 148,540 → 148,390 | 8,463 → 8,394 (**−69**) |
| `srhrp` (control) | — | 19,073 → 19,004 (**−69**) |
| `rhpc_members` | 179,598 → 184,676 | 24,971 → 27,153 (**+2,182**) |

The cause is HCAI re-populating the **Featured Visualizations** list in its
site-wide Data Resources menu — five items out, five in:

> *Inpatient Hospital Costs by Region · California Postoperative Sepsis
> Outcomes … · Patient Flow in California's Hospitals … · Inpatient Mortality
> Indicators · Healthcare Payments Data (HPD) Inpatient Stay and Outpatient
> Visits Report*

→

> *Prescription Drugs Introduced to Market · Wholesale Acquisition Cost (WAC)
> Increase Report Data - Cumulative · WAC Increase Report Data - Current Year ·
> Post Coronary Artery Bypass Graft (CABG) Readmissions and Complications ·
> Inpatient Hospital Costs by Region*

**That is the third nav edit in three firings** — session 46's label rename
(+12), session 47's single-item swap (−6), and now a whole-list replacement
(−69). The mechanism is confirmed recurring for a third time, and the standing
decision **not to reduce the navigation away is re-taken rather than
re-argued**: a new *"CalRHT Awardees"* menu item is the first place an award
page would be linked from, so discarding the menu would silence the probe
exactly when it mattered. The cost is paid on the noise side.

**And the SRHRP control moved by the same −69 and by nothing else**, which is
what says the nav is the whole story on that page: its awarded-grants block is
**byte-identical** and its eligible table is still **102 rows**.

### 8.2 `rhpc_members` moved +2,182, and −69 of that is the nav

So **+2,251 characters of real council content**. The Rural Health Policy
Council went from **seventeen members to NINETEEN**, nobody was removed, and
**both new members are hospital executives**:

- **Dr. Raul Ayala**, Ambulatory Medical Officer and Designated Institutional
  Official, **Adventist Health**
- **Martin Entwistle**, M.B., Ch.B., FRCSEd, **CEO (Interim), Marshall Medical
  Center**

The rest of the page's movement is five title edits and nothing else: Garzon
gains *"Dr."*, Link *"MSN, CNM"*, Rodriguez *"MSW, MPH"*, Witz *"Director of
SCA Consulting,"*, and Soni loses the initial *"S."*. **No existing biography
changed and no award language appeared anywhere** — every tripwire passes
against the live bytes, `CA_RHPC_AWARD_POSTED` included.

**California has still published nothing.** A council member is not a
recipient (Missouri's 27 Hub Anchors, Connecticut's four-person leadership
team), and this is governance.

### 8.3 THE FINDING: the compounding trap now reaches past RCJ entirely

Session 45 recorded the trap as: two of seventeen members are hospital
executives, and **both their hospitals are in RCJ's eleven California Tier 3
candidates** — so a session cross-referencing *"hospitals named on the CalRHT
estate"* against the RCJ candidate list matches on two hospitals, from two
independent wrong reasons, and the match reads as corroboration.

**The two new members break the boundary that description assumed.** Neither
Adventist Health nor Marshall Medical Center is among RCJ's eleven. Both are
on HCAI's own SRHRP page anyway — and one of them is an **award**:

| member | employer | in RCJ's 11 | on the SRHRP page |
|---|---|---|---|
| Haady Lashkari | Community Memorial Hospital-Ojai | **yes** | eligible table |
| Lori Link | Plumas District Hospital | **yes** | eligible table |
| **Dr. Raul Ayala** | **Adventist Health** | no | **AWARDED AND PRICED** — Reedley, **$1,325,000** |
| **Martin Entwistle** | **Marshall Medical Center** | no | eligible table |

HCAI names and prices **five** SRHRP awards on that page, and Adventist Health
Reedley (Sierra Kings Health Care District) is one of them — **an award RCJ
does not carry at all**. RCJ's eight distinct candidates and HCAI's five named
awards overlap on only three, so neither source is a complete list of the 29
grants.

**So a session that avoided the aggregator entirely and went to the state's
own page — the more careful thing to do — would still match, and would match
on an award the aggregator never knew about.** The trap was never a property
of RCJ's coverage; it is a property of HCAI publishing a real seismic award
programme and a rural-health advisory council on the same estate.

**The two matches are now two DIFFERENT failure modes, side by side:**

- **AWARDED_AND_PRICED** is §0.1's wrong programme — real, executed,
  recipient-level state cigarette-tax money for Alquist Act seismic
  compliance, on a page mentioning RHTP zero times.
- **ELIGIBLE_TABLE_ONLY** is §0.3's eligibility-is-not-receipt — the 102-name
  table this repository already calls the largest §0.3 table in the project.

### 8.4 What changed in the code, and why each change is the session's own
### lesson recurring

**(a) The pinned set became a table, and the position is CHECKED.**
`CA_RHPC_HOSPITAL_MEMBERS` (two names) retires into
`CA_RHPC_HOSPITAL_EMPLOYERS` (four rows: `member`, `employer`, `srhrp_name`,
`srhrp_page`, `in_rcj_candidates`, `since_session`).
`ca_assert_rhpc_is_governance()` now checks each employer is still on the
roster **and that its position on the SRHRP page is what the table says**, via
a new `ca_srhrp_position()` that separates the awarded block (*"have been
awarded, including grants for:"* … *"Acronyms"*) from the eligible table.
**An employer moving from the eligible table into the awarded block stops the
build**, because that changes which trap the note describes; a test drives the
promotion offline and requires the throw.

`srhrp_name` is a separate column from `employer` because the two publishers
spell them differently — the roster writes *"Community Memorial
Hospital-Ojai"* and the SRHRP page *"Community Memorial Hospital - Ojai"* —
and §2 forbids a fuzzy match resolving that silently.

**(b) The member count is DERIVED, and that is sessions 45 and 46's lesson
arriving in the function those sessions wrote.** *"Seventeen"* was typed into
the status row, the manifest and the docstrings, and **all of them were wrong
at once the morning the council gained two members**, with nothing pointing at
it. `ca_rhpc_member_count()` counts HCAI's own `<h3 class="wp-block-heading">`
markers on the raw bytes — one per member, nothing else on the page uses that
class — and refuses to return a number below the pinned employer count. The
status row now reads *"19 named individuals"* and the manifest *"19 NAMED
PEOPLE"*, both computed. A test requires that no surviving *"seventeen"* is a
live count: it may appear in a comment, or in a string that says the count
**moved**, and nowhere else.

**(c) "Added session 36" → "session 45", in the two places session 46 missed.**
Session 46 corrected that string in `ca_write_manifest()` and the same wrong
session number was still in `ca_assert_rhpc_is_governance()`'s docstring and
in the status table's own text — so the generated CSV carried it. `b892894`
is the commit that added the function and it is session 45's. §2.1's hazard in
the smallest possible form, and a test pins both halves.

### 8.5 What moved, and what did not

- **All six HTML sources moved in content**, so — as in session 46 and unlike
  session 45 — there was **nothing to revert**: every file moved for a real
  reason, even if the reason on five of them is a menu.
- **The six PDFs are byte-identical**, both Notice of Award revisions
  included, and `ca_assert_noa_label_current()` passed against the live
  programme page: HCAI still labels its NOA *"(August 28, 2026)"*, so there is
  no revision 05. **That check was added last firing precisely so a replaced
  PDF would be caught by design rather than by luck, and this is the first run
  where it did its job silently.**
- **`ca_rcj_candidate_disposition.csv` rebuilds BYTE-IDENTICAL.**
- **`ca_year1_status.csv` changes on EXACTLY ONE ROW** — the RHPC row, and only
  its derived text. `git diff --numstat` reports 1 insertion, 1 deletion.
- **No dollar, no row and no bucket moved, in California or anywhere else.**
  California still contributes nothing to any bucket and
  `ca_year1_awardees.csv` is still asserted absent.
- All five watched pages report **UNCHANGED** after the refresh.
- Tests: **5,386 assertions across 52 files, 0 fail, 1 self-skip** (+88; +87 of
  them in `test_03ab_ca_year1_probe.R`, 221 → 308).

### 8.6 Still outstanding

`main` is **still at session 44** (`1213f0d`, PR #45). The branch
`claude/ca-ct-nm-watch-8hfcho` now carries four commits and has never been
merged, so the Routine keeps running `main`'s **three-page** session-34 probe:
no RHPC pages, no NOA-label tripwire, and none of this session's work. The
Routine's own guard — `grep -c "ca_probe"` — returns 4 on `main`, so it
**checks that a probe exists, never that it is the current one**, which is
recorded here for a fifth firing running.

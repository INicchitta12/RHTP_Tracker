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

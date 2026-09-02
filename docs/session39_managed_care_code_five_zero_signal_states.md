# Session 39 — §8 gains `MANAGED_CARE_ORGANIZATION`, and the zero-signal
# states produce ARKANSAS: a $149M priced roster nobody had looked for

**Date:** 2026-09-02. Zero RCJ quota. ~40 fetches across five states' hosts,
throttled per §9.5. **Nothing was extracted — this is the report Task 2 asked
for before an extractor is written.**

---

## 1. `MANAGED_CARE_ORGANIZATION` — the first code added because THE SOURCE
## STATES A FORM §8 DOES NOT CARRY

Session 38 opened `NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY` for a condition this
project had not recorded. Eight states — Kansas, Maryland, Nebraska, Oklahoma,
Nevada, Michigan, Missouri and Iowa — publish a recipient and say **nothing**
about its form, and §8's standing answer for that is `NONPROFIT_CBO` + `LOW` +
`RECIPIENT_TYPE_INFERRED`. North Carolina **states** the form and §8 had no
code for the answer. Leaving those rows on the fallback asserts the form is
*undetermined* where the state has stated it outright, which is the one thing
`RECIPIENT_TYPE_INFERRED`'s own note forbids.

The code was added on **session 10's `PHYSICIAN_PRACTICE` footing** — an
explicit decision, written into `vocabularies.csv` with full notes and mirrored
into `rhtp-tracker-build-spec.md`, `CLAUDE.md` and
`reviewer-coding-instructions.md` by **patch, insert-only** (§2.1).

### The task said three rows. It is two, and the third is the point.

The queue row opened with three recipients, and only **two** of them state the
form the new code names:

| Hub Lead | NCDHHS's own sentence | Session 39 |
|---|---|---|
| Trillium Health Resources | *"an NC Medicaid Tailored Plan and **Managed Care Organization (MCO)**"* | `MANAGED_CARE_ORGANIZATION`, MEDIUM |
| Vaya Health | *"a public NC Medicaid **Managed Care Organization (MCO)**"* | `MANAGED_CARE_ORGANIZATION`, MEDIUM |
| Access East, Inc. | *"a **comprehensive care management provider**"* | **UNCHANGED** — §8's standing fallback, still queued |

**A comprehensive care management provider is not a Managed Care Organization
in North Carolina's own Medicaid vocabulary**, which distinguishes the two.
Widening a code on the day it is added, to a form its source does not state, is
§0.4's failure in miniature — so the code was **not** widened, and the queue row
went from **three recipients to one, not to zero**. A test reads the archive and
requires that NCDHHS still does *not* call Access East an MCO, and that
*"Managed Care Organization (MCO)"* occurs on that page exactly **twice**.

### Why it is not any of the codes §8 already had

- **Not `VENDOR_OR_CONTRACTOR`** — an MCO receiving a subaward is not a
  supplier to the state.
- **Not `STATE_AGENCY`, even where the state's own word is *"public"*** (Vaya) —
  a public MCO is a local political subdivision managing a benefit, not the
  awarding agency, and `STATE_AGENCY` would make a recipient look like the
  grantor.
- **Never a hospital type.** An MCO contracts hospitals; it is not one. So the
  code can only keep dollars **out** of the hospital total, which is what makes
  it safe to add.

### It moved no dollar and no row count, and that is asserted

All five ROOTS Hub Leads remain `PASS_THROUGH_UNRESOLVED` + `Unclear` in
**neither** bucket, `amount` is empty on all 44 North Carolina rows, and
`rhtp_hospital_dollar_partition()` still returns **no bucket at all** for the
state. `nc_year1_awardees.csv` changed on exactly **two rows**
(`2 insertions, 2 deletions`).

---

## 2. The five largest zero-RCJ-signal states

Session 36 found twelve states carrying **no RCJ Tier 3 signal at all**, holding
$2.36bn of allotment between them, and Florida — invisible to both discovery
layers with 81 extracted awards already in this repository — is the standing
proof that `NEITHER` never meant "this state awarded nothing". North Carolina
(session 37/38) was the second. **This pass makes it three of thirteen, and the
third is the largest yet.**

All five hold RCJ records and **zero Tier 3 candidates**, confirmed from the
committed pull:

| | Allotment | RCJ records (SOL / TIER1 / UNASSIGNED) | Tier 3 |
|---|---:|---|---:|
| AR | $208,779,396 | 20 / 3 / 15 | **0** |
| TN | $206,888,882 | 55 / 1 / 26 | **0** |
| SC | $200,030,252 | 10 / 4 / 19 | **0** |
| MN | $193,090,618 | 57 / 8 / 38 | **0** |
| NJ | $147,250,806 | 10 / 1 / 6 | **0** |

**`/api/v1/activity` found the route a SEVENTH time** (Oregon, Oklahoma,
Nevada, Missouri, Iowa, Wisconsin, and now all five of these). `state_source_url`
is NA on every one of these states' records; `stage2_state_sources.rds` held
**49 real state URLs** across the five — including `arkansasrhtp.com`,
`scdhhs.gov/RHTP` and Minnesota's grants page.

---

### ARKANSAS — **A COMPLETE, NAMED, PRICED ROSTER: 31 ORGANISATIONS,
### $149,177,618.45, 71.5% OF THE ALLOTMENT**

The single largest find since Oregon, and it was invisible to both discovery
layers.

- **`arkansasrhtp.com` is a dedicated RHTP domain** — the second in this
  project after Kentucky's `ruralhealthplan.ky.gov`, and unlike Kentucky's it
  **has awarded**.
- The roster is a PDF uploaded **2026-08-27**, linked from the home page under
  Arkansas's own words: ***"Download the List of Organization and Award
  amounts"***. Two initiatives: **THRIVE $55,713,829.20** and **PACT
  $93,463,789.25**.
- **IT RECONCILES TO THE CENT.** 31 organisation rows sum to the PDF's own
  `Total:` row exactly, on all three columns, and every row's THRIVE + PACT
  equals its own total.
- **A SECOND PUBLISHER CARRIES THE SAME ROUND, WITH MORE DETAIL.** The
  Governor's 2026-08-27 release announces *"$149.3 million in awards"* and
  ***"The 50 project awards"*** — project-level names, descriptions and
  counties — so 31 organisations hold 50 projects. The two figures differ only
  by the governor's rounding ($149.2M vs $149.3M); §8 says pin both, resolve
  neither.
- **TWO OF FOUR INITIATIVES ARE STILL TO COME**: RISE and HEART *"will be
  announced at a later date"*, against *"the $209 million the state expects to
  award **by this fall**"*.
- **THE RUNS MODEL READS IT DIRECTLY.** Session 32's `rhtp_pdf_run_table()`
  separates the three amount columns cleanly; the line model alone merges them
  into `"$2,571,095.00$0.00$2,571,095.00"`. This is the first state to need
  that work and get it for free.

**Sized, not extracted.** The §8 name rule finds **9 named hospitals /
$21,792,688** — and **16 rows / $100,723,693, 67.5% of the round**, carry §8's
standing fallback because the PDF publishes a name and an amount and no
organisational form. That is Kansas's shape a **ninth** time and **by far the
largest in absolute dollars**, and it runs **strongly upward**: Baxter Health
($19.7M), Mercy Health Fort Smith ($19.1M), Baptist Health ($16.9M) and
St. Bernards Development Foundation ($14.6M) are all uncounted, and **Arkansas
Rural Health Partnership ($18.8M) is a hospital consortium**, which is §10.2's
association row and needs the source read, not the name. **Nothing was
promoted (§0.4)** and nothing was written.

---

### SOUTH CAROLINA — **IT HAS AWARDED, AND IT TOLD THE RECIPIENTS BY EMAIL.
### A SHAPE THIS PROJECT HAD NOT MET**

- SCDHHS's RHTP page publishes a **Grant Applicant Deadlines** table giving
  ***"Anticipated Notice of Award — July 31, 2026"***.
- **It hit that date exactly.** Medicaid bulletin **MB# 26-026**, 2026-07-31:
  *"Today, SCDHHS issued Notices of Award Determination for the **712
  applications** received under the four funding opportunities. **Applicants
  should check their email** for notice detailing: whether funding was awarded;
  if funding was awarded, the funding amount and next steps..."*
- **NO ROSTER, NO AMOUNTS, NOT EVEN A COUNT OF AWARDS.** South Dakota published
  a count and a total with no names; **South Carolina publishes only a count of
  APPLICATIONS.** The awards were communicated privately.
- **The CMS footer is the STRONG, programme-scoped form** — *"The RHTP is
  supported by ... a financial assistance award totaling **$200,030,252.32**"* —
  and per §0.2 / session 37 that figure is the **ALLOTMENT**, matching the §7.1
  anchor to the cent. It is provenance, not a Tier 3 amount.
- **THE POSITIVE CONTROL AND THE §0.1 TRAP ARE ON THE SAME PAGE, TWICE OVER.**
  The RHTP page also carries the **Rural & Medically Underserved Area Grant**
  (*"SCDHHS has issued **$48.2 million** ... **View the list of the awardees
  below**"*, awarded **2024-02-02**) and the **Behavioral Health Crisis
  Stabilization Services Grant** (*"approximately **$35,000,000** ... **to
  hospitals** across the state"*, awarded **2023-06-23**). Both are real, named,
  linked rosters — **and both predate the 2025-12-29 Notice of Award by 18–30
  months**, so §6.2's date test disposes of them on its own. California's SRHRP
  trap, on the state's own RHTP page, in duplicate — and the hospital-money one
  is the $35M.
- **The §7 pass-through route exists and has not awarded**: SCRA states
  *"SCDHHS has contracted with SCRA to manage and administer the Tech Catalyst
  Fund"* (Illinois/ICAHN's precedent) and its NOFO is open. `scorh.net` mentions
  RHTP **zero** times.
- Eligible class: *"healthcare providers, community-based organizations,
  non-profit organizations, local government and public health entities and
  other entities"* — providers **among others**, New Hampshire's FHC class.

---

### MINNESOTA — **A NEGATIVE, AND THE MOST HOSPITAL-WEIGHTED ALLOCATION IN THE
### PROJECT: 70% TO 94 NAMED-IN-ADVANCE HOSPITALS**

- MDH publishes an **Entity Type / Allocated Amount / Number of Eligible
  Entities** table: **Hospitals 70% of MN's RHTP Award, 94 eligible**; FQHCs 5%
  (5); CCBHCs/CMHCs 2% (16); Tribal Nations 2% (10).
- These are ***"formula-based, non-competitive grants"*** with a **Notice of
  Grant Opportunity per entity type** — not a competition. 70% of $193,090,618
  is **~$135.2M**, the largest hospital-directed share this project has seen.
- **AND THAT IS §0.3 AT ITS MOST TEMPTING.** A formula allocation to a
  pre-identified class reads as though the eligible list *is* the award list.
  MDH has published **neither the 94 nor any award**, and *"allocated"* is not
  *"awarded"*. Wisconsin's pre-identified class (session 30) with a far larger
  hospital weight.
- The direct-allocation deadline was **extended to 2026-05-26** and has passed
  with no roster. Nine competitive RFPs sit beside it, all future-tense
  (*"The selected vendor will..."*), one still open (**2026-09-14**).

---

### TENNESSEE — **A NEGATIVE AT SOLICITATION STAGE, AND ITS AWARD CHANNEL IS
### UNREADABLE**

- TDH's rural page is FAQ and plan material. Its CMS footer is the **strong**
  form and again carries the **allotment** — *"$206,888,882.11"*, the §7.1
  anchor (§0.2).
- **The newsroom is a clean positive control** (New York's shape): TDH publishes
  named awards in a recognisable form — *"has **awarded** grant funding to five
  community-based projects"*, 2026-06-15, a chronic-disease programme that is
  not RHTP — while **all three of its RHTP items are funding opportunities**,
  the first released **2026-05-15**. The governor's newsroom carries **zero**
  RHTP items.
- **The RHTP Partner Portal is UNREADABLE** (§0.4). `tndeptofhealth.caspio.app`
  returns *"You need to enable JavaScript to run this app."* — Maine's CGI
  Advantage, Connecticut's CTsource and Louisiana's rhtla.net a fourth time. What
  it holds is a statement about **our access**, never about Tennessee.
- The Tennessee Hospital Association's own RHTP page names nobody.
- Eligible class: *"Local hospitals, health systems, non-profits, federally
  qualified health centers, community groups, and other organizations"* —
  hospitals **among others**.

---

### NEW JERSEY — **THE THINNEST RHTP PRESENCE IN THE PROJECT, AND ITS OWN PAGE
### HAS NOT ACKNOWLEDGED THE AWARD**

- NJDOH's Office of Rural Health page, **last reviewed 2026-08-06**, still says
  *"New Jersey **applied for** major federal funding through the new Rural
  Health Transformation Program"* and links an **application excerpt**. It does
  not mention the $147,250,806 the state was awarded on 2025-12-29.
- **The positive control is unusually clean.** NJDOH publishes a full
  **Directory of Grant Programs** for FY2026–2027 — every NOFA and RFA it
  intends to run, with due dates — and *"rural"* occurs in it **zero** times.
  New Jersey has not solicited.
- The governor's newsroom carries **zero** RHTP items.

---

## 3. What this pass says about the remaining eight

Two of the thirteen no-signal states checked before this pass had published
rosters (Florida, North Carolina). **This pass makes it three of five** — and
Arkansas's is priced, complete and reconciles to the cent, while South Carolina
has awarded and simply not published. **The zero-signal group is where the
unworked money is, and a candidate count of zero is a fact about the discovery
layers and never about the state (§0.1).**

Eight remain: **HI, MA, WY** and the five smaller ones behind them. Use the
channels this pass proved, in this order: **`/api/v1/activity` first** (it
supplied the route in all five), then the **governor's newsroom** (which is
where Arkansas's roster is corroborated and where Florida's was found), then the
agency's **grants directory or bulletin channel** (South Carolina's award notice
is a Medicaid bulletin, not a press release, and is invisible from the
programme page).

### Award dates already published and already passed

| | What the state published | Date | Status on 2026-09-02 |
|---|---|---|---|
| **SC** | *"Anticipated Notice of Award"* | **2026-07-31** | **MET** — awarded, no roster published |
| **AR** | first-round awards | **2026-08-27** | **MET** — roster published, reconciles |
| **AR** | RISE and HEART, *"$209M by this fall"* | fall 2026 | pending |
| **MN** | direct-allocation applications closed | **2026-05-26** | passed, no roster |
| **MN** | Rural TA / telehealth RFP closes | **2026-09-14** | open |
| **TN** | first competitive opportunity released | 2026-05-15 | no award date published |
| **NJ** | — | — | nothing solicited |

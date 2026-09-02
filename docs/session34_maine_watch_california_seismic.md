# Session 34 — Maine on a schedule, and California's eleven hospitals are a seismic programme

**Date:** 2026-09-02. Zero RCJ quota; ~25 requests to `hcai.ca.gov`, throttled
per §9.5.

---

## 1. Maine is the fourth state on a schedule, and the first put there before
   its file went stale

Session 33 extracted Maine and left it unwatched, with three award dates inside
eight weeks and one of them already passed. `R/03aa_me_year1_awardees.R
--probe` already existed and already ran live; what it lacked was a Routine.

**`trig_01ALmis3jAgiLXVb6ZDLCj8Y`, Tuesdays and Fridays 16:20 UTC**, first fire
2026-09-04. **Wisconsin's cadence, not Alaska's**, and the reason is the same
one Wisconsin has: Maine is stale *by appointment* and the appointment has
begun.

| | Cadence | Why |
|---|---|---|
| Alaska | Mondays | stale **by construction** — DOH overwrites one url weekly |
| Missouri | Wednesdays | stale **by appointment** — Aug–Sept procurement awards |
| Wisconsin | Tue + Fri | appointment **already begun** — "Award announcements: September" |
| **Maine** | **Tue + Fri** | **appointment already begun, and one date has PASSED** |

Maine's three dates:

- **Maine DOE's Healthcare Careers Exploration awards.** Its own RFA page
  prints *"Award Announcement: **August 31, 2026**"*. Session 33 ran
  2026-09-02 with no roster. **Already overdue.**
- **The Rural Hospital Efficiency Fund cohort begins SEPTEMBER**, funding
  approved **Fall/Winter**. This is the $30,000,000 and the eleven named
  hospitals.
- **EMR provider contracts execute in the FALL** — ~70 eligible ownership
  organisations across ~330 sites, with Critical Access Hospitals and general
  hospitals with a dedicated ED the first eligible class named. **This is where
  Maine's hospital money actually is.**

The Routine's prompt carries the four standing Maine rules and, above them, the
one that decides everything: **Maine's danger runs the opposite way from
Nevada's and Iowa's.** Those two publish named hospitals with no amounts, so
the danger is reporting $0 without the row count. Maine's danger is **counting
the eleven** — $30,000,000 and 15.8% of its allotment, added to the headline by
one bad reading. It refuses to act if `me_probe` is absent from `main`.

---

## 2. California led the RCJ_ONLY queue and is a NEGATIVE — and its candidate
   set is the most dangerous this project has met

California ranked 19th overall and **first among states nobody had looked at**:
11 Tier 3 candidates, 8 distinct awardees, a **$233,639,308** allotment, no CMS
press release.

**HCAI has published no recipient-level RHTP award list.** California brands
RHTP as **CalRHT**, run by the Department of Health Care Access and Information.
It has opened **four** grant opportunities and **all four are headed
"(Closed)" with no roster**:

| Pool | BP1 amount | Stage |
|---|---:|---|
| Accelerator Partners (Transformative Care Model) | $39,010,000 | Closed, unawarded |
| Workforce Development Recruitment and Retention (WDRR) | $54,170,000 | Closed, unawarded |
| EHR Modernization | $11,650,000 | Closed, unawarded |
| FM-OB Fellowship Subaward | $6,500,000 | Closed, unawarded |
| | **$111,330,000** | **47.7% of the allotment** |

**And the window is open NOW, by days.** Three of the four grant guides put
award notification in **August / September 2026** and grant agreements in
**September / October 2026**; the EHR guide's next milestone is *"Notify
Subrecipients September 2026"*; and **WDRR's application window closed August
31, 2026 — two days before this ran.**

That is Wisconsin's shape with a tighter date, so California joins Texas and
Wisconsin as `INVESTIGATED_NO_LIST` rather than being left `NOT_EXTRACTED` to
rank near the top of the queue again.

---

## 3. §0.1 — Texas's defect with Maine's ratio

**All eleven California Tier 3 candidates come from one document**, `CA - 2026 -
Small and Rural Hospital Relief Program (SRHRP) - HCAI`, and **every one is a
named California hospital carrying a real dollar amount on a real executed HCAI
award**: Community Memorial Hospital Ojai, George L Mee Memorial Hospital
(twice), Hazel Hawkins Memorial Hospital, Kern Valley Healthcare District, Mad
River Community Hospital (twice), Mountains Community Hospital, Oak Valley
Hospital District, Plumas District Hospital (twice). $5,475,000 between them.

**The SRHRP is a California STATE programme**, and HCAI says so on its own page:

- *"**Ten percent of the funds from the California Electronic Cigarette Excise
  Tax** will be allocated to the Department of Health Care Access and
  Information (HCAI) to operate the SRHRP (HSC Section 130075)"*
- created under *"The **Alfred E. Alquist Hospital Facilities Seismic Safety
  Act** (Health and Safety Code (HSC) Section 129675)"*, for *"funding seismic
  safety compliance projects"*
- and the page mentions **"RHTP" zero times, "Rural Health Transformation" zero
  times, and "federal" zero times.**

**Texas's defect (session 19) with Maine's ratio.** Texas's 53 disqualified rows
were 78% of its candidate set. California's are **eleven of eleven** — every one
a named hospital, every one priced, every one a genuine award document **from
the same agency that administers CalRHT**. An extractor built from the candidate
list would have published **$5,475,000 of state cigarette-tax money as
California's RHTP hospital dollars**, with 8 named hospitals, and every row
would have traced to a real award.

**The descriptions gave it away in the aggregator itself and nobody read them.**
RCJ's own text for these rows is *"MTCAP, MTCAR, NPC 5 Evaluation of campus, and
an SPC-4D Evaluation of the Hospital Building"* — Material Testing and Condition
Assessment Plans, Structural Performance Category evaluations. **Seismic
engineering deliverables, not health care.** A programme check catches this; a
plausibility check on the amount does not, and neither does reading the awardee
names, which are impeccable.

**And RCJ carries components rather than grants**, so even the row count is
wrong: George L Mee appears twice at $500,000 and $280,000, which is HCAI's own
published **$780,000** grant split into its line items.

`CA-SRHRP-SEISMIC` is now in `non_rhtp_state_programs.csv`, keyed on the
programme name. **The sweep goes 90 rows in 8 states → 101 rows in 9 states**,
and it catches **all eleven with zero false positives — by two independent
filters at once**: the registry, and the date test, because the registry row
supplies HCAI's own 2025-02-19 SRHRP webinar date for rows RCJ carries **no
date for at all**. New Hampshire's pattern (two §6.2 filters, one row) at the
scale of a whole state's candidate set.

---

## 4. One page, three failure modes — which is why it is archived as BOTH controls

The SRHRP page is the single richest control this project has found, because it
carries all three of this repository's standing traps at once:

1. **THE POSITIVE CONTROL.** HCAI demonstrably publishes recipient-level awards
   in a recognisable form — *"29 grants (totaling $17.2 million) have been
   awarded"*, five of them named with amounts. So **"CalRHT has published no
   roster" is a statement about CalRHT, not about our reading.**
2. **THE §0.1 NEGATIVE.** Those same awards are not RHTP.
3. **THE §0.3 TRAP, AND IT IS THE LARGEST NAMED-HOSPITAL TABLE THIS PROJECT HAS
   MET.** The same page carries **"SRHRP Eligible Hospitals": 102 named
   California hospitals** in a machine-readable table with county, rurality
   designation and bed count. It is an **eligibility** list. Wisconsin's 213 DPI
   districts and Maine's eleven invited hospitals, on one page — and one tier
   worse than either, because here the eligibility table sits **directly beneath
   real awards**.

**HCAI's newsroom is the second positive control, and it is about the CHANNEL**
(Indiana's sixth question). It carries award announcements in a recognisable
form — *"California Certifies 5,000 Wellness Coaches and Awards Scholarships to
613 Students Statewide"* — and mentions CalRHT and RHTP **zero times**. So the
absence of a CalRHT announcement is HCAI's, not our channel's. **And the EHR
grant guide says where the first naming may actually land**: subrecipients must
submit press releases to HCAI two weeks in advance and may publish only after
*"HCAI, CalHHS, or the Governor's Office issues a statement"*.

---

## 5. §6.2 in its strongest form — and a new position on session 27's axis

**California publishes CMS's own Notice of Award**, not a footer quoting one.
`NOA_Rural-Health-Transformation-2026-Revised-1.pdf` is CMS's own form:
recipient **CALIFORNIA DEPARTMENT OF HEALTH CARE ACCESS AND INFORMATION**,
Assistance Listing **93.798 Rural Health Transformation Program**, Award#
**RHTCMS332078-01-02**, budget period **12/29/2025 – 10/30/2026**,
**$233,639,308.47**. Nevada was the first state to publish the NOA; California
is the second.

**And California's CMS footer is the STRONG form and is demoted anyway, which is
new.** Session 27's audit split the footer on its grammatical **subject**:
*"This publication is supported by"* (weak, Kansas) versus a subject that names
the programme. California's reads ***"The CalRHT program is supported by … 
$233,639,308.46"*** — it names the programme, so it is the strong form. It is
used here for the **amount** only, because the NOA is better evidence than any
footer, and two programme-scoped sentences carry the provenance. **Every
previous demotion in this repository was of a weak footer; this one is demoted
because something better exists.**

**Two dates on one document, and only the scope separates them (§0.2's lesson on
a new axis).** The NOA's **Federal Award Date is 03/31/2026** and its Award
Action Type is **"Revision (Budget)"** — CMS approving a revised budget and
lifting a $50,000,000 restriction *"per your request dated 3/27/2026"*. The
**budget period still starts 12/29/2025**, which is the project's own anchor in
`cms_state_noa_dates.csv`. **A date test keyed on the words "Federal Award Date"
would read California's award as three months later than every other state's**
and quarantine work that predates the revision. An assertion pins the word
"Revision".

**The one-cent disagreement is pinned and not corrected (§8, Kansas's rule).**
CMS's NOA says **$233,639,308.47**. Five HCAI publications say **.46**. One HCAI
grant guide — the FM-OB one — says **.47**, agreeing with CMS. So HCAI's own
estate disagrees with itself by one cent and the outlier is the document that
agrees with the federal record. All three are asserted.

---

## 6. The eligible class is hospitals AMONG OTHERS — New Hampshire's answer

Session 29's fifteenth question decides whether a future California
pass-through dollar is a hospital dollar, and California answers it the same way
New Hampshire did. Every CalRHT pool that reaches hospitals reaches them
alongside FQHCs and Look-Alikes, RHCs, Tribal clinics, other comprehensive
community health clinics, health care districts, regional collaboratives and
academic medical centres. Accelerator Partners is *"support for **hospitals or
other organizations** in rural regions"*.

**So when California awards, no pool here is Illinois's hospitals-only class**,
and any intermediary is §0.3. `ca_assert_eligible_class_not_hospitals_only()`
fails the build if a pool's class narrows, because that would be a different
coding and must be read deliberately rather than inherited.

---

## 7. Two parsing findings, both about characters nobody can see

**A ZERO-WIDTH SPACE (U+200B).** HCAI's markup puts one between "Retention" and
"(Closed)" in the WDRR heading. It is invisible in every rendering, every diff
and every error message, so a literal assertion written from a rendered copy of
the page fails with **nothing to point at**. `ca_reduce_html()` strips
zero-width characters; a test asserts the raw bytes carry one and the reduction
does not.

**A CURLY APOSTROPHE (U+2019), literal rather than an entity.** The programme
page reads *"California's approach"* with U+2019, and the first run of
`ca_assert_programme_provenance()` failed on it. The reduction now folds
typographic quotes and dashes to ASCII **for matching only** — the archived
bytes are untouched.

**And a third, which is this file's own lesson one tier down.** The SRHRP
eligible-hospital table has **105 `<tr>` rows**: one header and **two entirely
blank spacer rows**, at positions 51 and 100. A first count reported **104
hospitals**; there are **102**. The reader now requires each kept row to open
with HCAI's own facility id, so the blanks fall out **for lack of identity
rather than by a threshold**. A row count is not a hospital count — which is
exactly what the eleven RCJ candidates are about.

---

## 8. The host — and a wrong claim this session made and then caught

`hcai.ca.gov` answers the project's honest agent with **HTTP 200** on every path
used here, so §3's michigan.gov exception is not reached. `robots.txt` is
**404**, so no crawler policy is on offer and none is being declined.

**And its file digests are NOT a change test, which this session got wrong
first.** Two fetches of each probed page **three seconds apart returned the same
SHA-256**, so the host carries no per-request nonce — and an early version of
`R/03ab` concluded from exactly that measurement that a file digest would do,
and said so in its header, its manifest and its probe. **The first live probe
reported two of three pages CHANGED thirty minutes later with nothing changed.**

There are two mechanisms, and neither is one this project had met:

- **A CACHE VARIANT.** The CalRHT page is served with or without a ~15 KB
  **ElasticPress autosuggest** stylesheet and script block — **142,605 bytes or
  157,732 bytes**, the same page either way. Two fetches seconds apart agree
  because they hit the same cache node; two fetches half an hour apart need not.
- **RANDOMISED EMAIL OBFUSCATION.** The newsroom re-rolls WordPress's
  `antispambot()` entities on every render: `H&#067;AIPre&#115;s&#064;…` one
  fetch, `&#072;&#067;A&#073;&#080;ress&#064;…` the next. **Same length,
  different bytes, identical rendered text** — so even a byte-count check passes
  it.

`ca_reduce_html()` absorbs both, and that is **measured**: the reduced text is
identical across the archived and live copies of both pages, **11,162 characters
either way**. The probe now compares a **content** digest, via the same
reduction the assertions read (Missouri's rule, session 29), and reports
UNCHANGED on all three.

**The transferable lesson is not the workaround, it is the measurement.** *Two
fetches seconds apart is not a stability test.* Every previous host in this
project failed a file digest through a **per-request** nonce, which a
back-to-back pair exposes immediately; California fails it through a **cache
variant**, which a back-to-back pair is guaranteed to miss. The archived bytes
are kept exactly as served — the variant we hold is one of two legitimate
responses, not the canonical one.

**That makes four mechanisms across five hosts, and only one host has held:**

| State | Mechanism | Exposed by two fetches seconds apart? | Change test |
|---|---|---|---|
| Nevada (s26) | rotating state-symbol widget in page CONTENT | yes | content digest |
| Missouri (s29) | Incapsula cache-buster in a script SRC, host-wide | yes | content digest |
| Wisconsin (s31) | Akamai Boomerang RUM nonce in a script BODY | yes | content digest |
| Maine (s33) | none | n/a | **file digest** |
| **California (s34)** | **cache variant + antispambot() re-roll** | **NO** | **content digest** |

## 9. What is in the repository

- `R/03ab_ca_year1_probe.R` — `--fetch` / `--validate` / `--build` / `--probe`
  / `--report`.
- `data/reference/ca_year1_status.csv` — **6 rows, NO `amount` column**, with an
  assertion refusing one (Texas's device). `ca_year1_awardees.csv` **does not
  exist** and a test asserts its absence.
- `data/reference/ca_rcj_candidate_disposition.csv` — 1 row, counts re-derived
  from `stage2_record_table.rds` on every run.
- `data/reference/non_rhtp_state_programs.csv` — **9 rows**, `CA-SRHRP-SEISMIC`
  added. Appended byte-wise in Python; `git diff --numstat` reports **1
  insertion, 0 deletions** (the CRLF trap, met a sixth time and not landed).
- `data/evidence/CA/` — 10 sources + SHA-256 manifest, including the NOA, the
  budget narrative, all four grant guides, and both control pages.
- `data/reference/rcj_state_survey.csv` and `state_trigger_queue.csv` — both
  **rebuilt** from `R/03k`'s constants, never hand-edited. California reads
  `INVESTIGATED_NO_LIST`; **Connecticut and New Mexico now lead the RCJ_ONLY
  queue at 7 candidates each.**

**California's named-hospital rows are 0 and its named-hospital dollars are $0**,
and both are statements about what HCAI has published, never about what
California has spent.

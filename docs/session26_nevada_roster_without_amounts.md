# Session 26 — Nevada publishes a named roster with no amounts, and the CMS footer stops being a provenance test

**Date:** 2026-08-31
**Quota:** zero RCJ calls. ~45 requests to `www.nvha.nv.gov` including path and
extension probes that 404'd; **11 sources archived**, throttled per §9.5.
**Files:** `R/03u_nv_year1_awardees.R`, `data/reference/nv_year1_awardees.csv`,
`data/reference/nv_rcj_candidate_disposition.csv`, `data/evidence/NV/`,
`tests/testthat/test_03u_nv_year1_awardees.R`.

---

## 1. Nevada led the queue and publishes a shape this project had not met

Nevada ranked 1 on `state_trigger_queue.csv` once Oklahoma was worked out — 34
Tier 3 candidates, 34 distinct awardees, a $179,931,608 allotment, no CMS press
release.

The Nevada Health Authority publishes `RHTP/rht-funded-projects---bp1/`:
**three tables, 72 named subrecipients, and not one dollar figure anywhere on
the page.** Its columns are Subrecipient, Project, and County-Service Area.

Every prior state sits somewhere on one axis. Kansas, Maryland, Nebraska and
Oklahoma publish a recipient **and** an amount and withhold the recipient's
**form**. South Dakota publishes an amount and a count and withholds the
**recipients**. **Nevada withholds the AMOUNTS and publishes everything else.**

| Pool | Rows | Round total | Roster |
|---|---:|---:|---|
| Rural Health System Flex Fund | 25 | $36,000,000 | published |
| WRRAP — Recruitment and Retention Fund | 27 | $32,300,000 | published |
| WRRAP — Apprenticeship and Training Fund | 20 | $14,300,000 | published |
| WRRAP — Rural Medical Residency | 1 (aggregate) | $4,800,000 | **names nobody** |
| | **73** | **$87,400,000** | 48.6% of the allotment |

`amount` is **empty on all 73 rows** and `sum(amount)` is **0**. That is not a
parse failure and not a claim that Nevada awarded nothing — it is the honest
total of what NVHA has published **per recipient**, which is nothing.

**The route in was `/api/v1/activity`, not `/awards`** — Oregon's and
Oklahoma's lesson a third time. `state_source_url` is NA on all 34 Nevada Tier
3 records; `stage2_state_sources.rds` held ten real `nvha.nv.gov` URLs, one of
them the funded-projects page itself.

---

## 2. NEVADA HAS 20 NAMED-HOSPITAL AWARD ACTIONS AND $0 OF NAMED-HOSPITAL DOLLARS

Both are true at once, and only one of them is a number.
`rhtp_hospital_dollar_partition()` sums with `na.rm = TRUE`, so Nevada comes
back as **`NAMED_HOSPITAL rows = 20, dollars = 0`**.

**A reader who takes the 0 and not the 20 concludes Nevada gave its rural
hospitals nothing, which is the exact opposite of what NVHA has published.**
That is the single most dangerous misreading this file can produce, and
`nv_assert_zero_dollars_is_not_zero_hospitals()` exists so it cannot happen
quietly: it requires the dollars to be 0 **and** the rows to be non-zero, and
fails loudly if either changes.

The 20 rows cover **16 distinct hospital names**, which is an **upper bound on
organisations, not a count of them**. NVHA writes several recipients
differently in different pools — `Desert View Hospital` / `DVH Hospital
Alliance LLN dba Desert View Hospital`, `Grover C. Dils Medical Center` /
`Lincoln County Hospital District dba Grover C. Dils Medical Center`,
`Carson Valley Health` / `Washoe Barton Medical Clinic DBA Carson Valley
Health` — and publishes both **`Northern Nevada Regional Hospital`** (Flex,
"Elko – Battle Mountain and Owyhee") and **`Northeastern Nevada Regional
Hospital`** (Recruitment and Retention, "Elko, Eureka, Humboldt, Lander and
White Pine"): two names four characters apart, one state, both in Elko. **§2
forbids a machine auto-resolving that**, so none is merged;
`nv_assert_name_variants_unresolved()` records the pairs and the CCN match
(blocker 5) settles them.

---

## 3. §6.2 passes in its strongest form yet — Nevada publishes the federal Notice of Award itself

Oklahoma's footer was the awarding agency's figure quoted **on** the roster.
Nevada's is **the award document**. `noa_rhtcms332074-01-02.pdf` is CMS's own
Notice of Award form:

- recipient **Nevada Health Authority**
- award **RHTCMS332074-01-02**, Assistance Listing **93.798 Rural Health
  Transformation Program**
- budget period **12/29/2025 – 10/30/2026**, **$179,931,608.42**
- *"This Notice of Award approves the revised budget and lifting of restriction
  in the amount of $179,931,608.42 per your request dated 1/29/2026."*

That rounds to `cms_fy2026_allotments.csv`'s **$179,931,608** to the dollar and
its date is `cms_state_noa_dates.csv`'s **2025-12-29** anchor exactly. NVHA
restates both independently — *"December 29, 2025: Received Notice of Award
($179,931,608)"* — and cites **Public Law 119-21, Section 71401**. Every awarded
RFA closed 4/30/26, 5/15/26, 5/29/26 or 6/26/26, four to six months after the
state had the money.

**No other state file in this repository holds the NOA itself.**

---

## 4. THE SESSION'S LESSON: THE CMS FOOTER COVERS THE PUBLICATION, NOT THE PROGRAMMES IN IT

`nvha-healthcare-workforce-programs-remediated-doc-2-1.pdf` ("Working Together
to Power Nevada's Health Workforce", April 2026) carries the CMS
financial-assistance footer — *"$179,931,608.42 with 100% funded by CMS/HHS"* —
**on every page**, because NVHA produced the publication with RHTP money. It
then prints **three workforce programmes side by side**, in a table whose own
column is headed **Funding**, and gives each one's source:

| Programme | Source, in NVHA's own words | RHTP? |
|---|---|---|
| **GME** | **"Source: State General Fund"** — NRS 223.631-639, SB262 & SB494 (2025) | **No** |
| **WRRAP** | "Centers for Medicare & Medicaid Services (CMS) Rural Health Transformation (RHT) Grant #RHTCMS332074-01-02" | **Yes** |
| **SHARP** | **"Source: SB5 one-time bill appropriation"** — $60M, available 7/1/26 | **No** |

**A provenance check keyed on "does this document carry the CMS
financial-assistance footer" answers YES for all three and is wrong for two.**

Oklahoma's footer sat on a **roster** and covered what was on it. Nevada's sits
on a **comparison document** and covers only the publishing. Session 25 recorded
the footer-on-the-roster as the strongest form of the test; session 26 is where
the footer **alone** stops being a test at all.
`nv_assert_footer_is_not_provenance()` asserts both halves — the footer's
presence **and** the "State General Fund" line — so if either disappears the
control is gone rather than silently weaker.

---

## 5. §0.1 — RCJ's 34 candidates are three separate defects at once

| Group | Rows | RCJ amount | Disposition |
|---|---:|---:|---|
| GME Grant Round VIII — nine residency/fellowship programmes | 17 | $28,803,045 | `NOT_RHTP_STATE_PROGRAM` |
| The three WRRAP pool totals + a budget-narrative line item | 7 | $102,840,000 | `RHTP_BUT_NOT_A_SUBAWARD` |
| Ten Flex Fund awardees, every one at **$1** | 10 | $10 | `RHTP_SUBAWARD_IN_FILE` |
| | **34** | **$131,643,055** | |

**Seventeen candidates are Nevada STATE GENERAL FUND money.** NVHA announced
GME Grant Round VIII on **2026-07-22** — *"Nevada Invests Nearly $16 Million to
Train the Next Generation of Physicians"*, nine programmes, **$15,755,068.00**,
the Director's own words **"these new state investments"**, and no mention of
CMS or RHTP anywhere in it. RCJ files them under RHTP-titled documents. The
nine amounts sum to the release's own stated total to the cent, which is what
ties the candidate rows to the state document.

**And the trap is eight days wide.** On **2026-07-29** NVHA announced
**$4.8M of RHTP Rural Medical Residency** money under WRRAP. Two
residency-shaped announcements, one agency, eight days apart, one federal and
one state. `NV_STATED$wrrap_residency` and `NV_GME_TOTAL` are different
programmes and the file asserts they never mix.

**Seven are the pool totals themselves** — `Provider Recruitment and Retention`
$32,300,000, `Apprenticeship and Training Investments` $14,300,000,
`Rural Medical Residency Investments` $4,800,000, each also under a
`... Recipients (NV)` variant, which is a **class and not a recipient** (§0.3,
North Dakota's "15 selected CAHs"), plus `IT Technician At Your Service`
$40,000 out of Attachment C, the RFA's **budget narrative template**.

**RCJ holds 10 of Nevada's 72 published award actions — 13.9% — and every one
of them carries an amount of $1.** They were mined out of the 2026-06-09
steering-committee fiscal deck, whose "Flex Funds – Funded Projects" slides
list recipients with **no amounts**, so the $1 is a placeholder for a figure
that does not exist. RCJ's title for them, *"Agenda Nevada RHT Program
Activity"*, is the text of the deck's **agenda slide** — Nebraska's defect: the
title came off the wrong page.

> **Texas's defect was the wrong PROGRAMME; Oregon's the wrong RECIPIENT CLASS;
> Indiana's an INVENTED label; Oklahoma's the wrong TIER. Nevada's candidate
> set is three of those at once.**

### What the automated sweep now catches, measured

`non_rhtp_state_programs.csv` gains **`NV-GME-ROUNDVIII`**, and the §6.2 sweep
goes from **73 rows in 6 states to 82 in 7**. It catches **9 of the 17**, with
**zero false positives** — every caught row is one the extractor independently
dispositions as state money, and `rhtp_match_state_program()` filters the
registry by state before matching, so nothing outside Nevada can be reached.

The other 8 are filed by RCJ under *"Nevada Home Working Together RHTP 2026
Award Announcement"* — the workforce publication, which **is** a genuine RHTP
document — so **no source-title-keyed rule can honestly reach them.** That is
the same lesson as §4, measured: they are disposed of by hand.

**The regex is deliberately not the bare phrase "Graduate Medical Education".**
That matches three real **Georgia** rural hospital awards of $500,000 each
whose Dual Track grant titles contain it (harmless here only because the
matcher is state-scoped) and — the reason that matters — it would match NVHA's
own RHTP release, which funds *"a new statewide Rural Graduate Medical
Education Consortium"* with WRRAP money.

---

## 6. Two NVHA documents disagree about which WRRAP fund got which total

| Source | Recruitment & Retention | Apprenticeship & Training |
|---|---:|---:|
| 2026-06-09 fiscal deck | **$14,394,529** available | **$32,387,689** available |
| 2026-07-29 press release | **$32.3M** awarded | **$14.3M** awarded |

**The pairing in the deck was checked against the PDF's own glyph positions,
not the reader's line order** — each pool's label sits 45–50pt right of its own
bullet block, consistently across all four columns — so this is the source
disagreeing with itself and **not a parse artifact**.

Two readings exist and **neither is published as a finding.** NVHA may have
**reallocated** between the sub-funds while *"negotiating final awards"* (the
deck's own words), which the totals support almost exactly — **$46,782,218
available against $46,600,000 awarded** — or one document swapped its labels.

`round_amount` takes the **press release's** figure, because §8's
source-strength ordering makes an award announcement the better authority on
what was *awarded* than a pre-award planning deck is. Both WRRAP rosters carry
the new flag **`POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES`** (added to
`vocabularies.csv` with full notes) so no reader meets one figure without the
other. **The combined WRRAP workforce figure is ~$46.6M either way**, and that
is what `nv_report()` leads with.

The Flex Fund's $36,000,000 is **not** in dispute: the release says *"$36
million"* and the deck says *"$35,986,322 available"*, which is the same figure
rounded.

---

## 7. The positive controls

**NVHA publishes rosters in a recognisable form**: one accordion section per
awarded pool on the Funded Projects page, each with a
Subrecipient/Project/Service-Area table. There are **three**.
`nv_assert_award_index()` asserts all three present and **refuses a fourth**.

**NVHA is running ten Budget Period 1 opportunities and has published rosters
for three.** `nv_assert_pending_not_awarded()` names the six closed ones with
no roster — RHIT, RHOAP, Presidential Fitness Test, Correctional Health,
Veterans Health, Tribal Health — and **is designed to fail** the day one
appears on the Funded Projects page.

**The absence of amounts is corroborated by a second, independently produced
document.** The fiscal deck's own "Flex Funds – Funded Projects" slides list the
same recipients under the same three column headings and print **no figure
against any of them**. `nv_assert_no_per_recipient_amounts()` requires at least
20 of the 25 Flex recipients to appear in both.

**And the Flex round total is tied to this roster by NVHA, not by this file.**
The 2026-06-09 release ends *"Review all RHT Funded Projects here: RHT Funded
Projects - BP1"*. Without that sentence the $36,000,000 and the 25 names would
be two documents nobody had joined (§0.3).

---

## 8. Two parse defects, both of which fail plausibly rather than loudly

**Session 10's `<td>` header defect, met again.** NVHA marks the **Flex Fund**
table's header row up with `<td>`, not `<th>`, so `html_table()` names its
columns `X1..X3` and keeps *Subrecipient / Project / County-Service Area* as
row 1 — **while the two WRRAP tables on the same page use `<th>` and resolve
normally.** Unpromoted, Nevada reports **26** Flex awards, one of them to an
organisation called *"Subrecipient"*. `nv_promote_header()` promotes such a row
**only when it resolves strictly more of the needed columns**, which is session
10's own rule and means it can never make a working parse worse. Both branches
are tested.

**The third column is headed differently between tables** — *County-Service
Area* on Flex, *Service Area* on both WRRAP tables — so columns are resolved by
**synonym, not position**, and the parser refuses if any table fails to resolve
exactly one recipient, project and area column.

**The roster page's whole-file digest is not stable and must not be used as a
change test.** Its footer carries a rotating "state symbol" widget: two fetches
minutes apart served the Lahontan Cutthroat Trout and the Vivid Dancer
Damselfly. The three roster **tables** hash identically across those same
fetches, so `nv_roster_digest()` is what a completeness re-check compares. This
is South Dakota's ServiceNow-token problem in a new costume — a reader
verifying the page digest gets a mismatch that means nothing.

---

## 9. Two §10.2 foundations, and the project's first `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED` row

**Nevada Rural Hospital Partners Foundation** (2 rows) and **Incline Village
Community Hospital Foundation** (1 row) both carry *"Hospital"* in their
published names and the §8 name rule reaches both — which would have typed them
`HOSPITAL_OR_SYSTEM` → `DIRECT` → `Yes` and put them in `NAMED_HOSPITAL`.
Neither is a hospital: one is a rural hospital **association's** charitable
foundation, the other a single hospital's **fundraising** arm. This is §10.2's
inflation trap in the direction session 12 warned about from the other side —
*"Calhoun Liberty Hospital Association"* **is** a hospital, so a name-keyed rule
cannot be trusted either way.

Both are typed `HOSPITAL_AFFILIATED_ENTITY` in the shared override table. That
**does not** resolve the open `GHA_RECIPIENT_TYPE` question, which asks which
code a hospital **trade association** takes and is worth $0 either way. What
matters is that since session 19 `HOSPITAL_AFFILIATED_ENTITY` no longer
short-circuits to `DIRECT`/`Yes`, so §10.2 gets applied instead of the names
pre-deciding the flow:

- **NRHP Foundation** → *"Clinician well-being and retention program supporting
  workforce stability across Nevada's rural hospital network"* →
  `IN_KIND_BENEFIT` / `No` / `hospital_benefiting = Yes`. Alaska's AHHA answer:
  the foundation runs the programme, no money moves to hospitals.
- **Incline Village CH Foundation** → *"Recruitment of primary care, pediatric,
  and care coordination providers"* → `PASS_THROUGH_UNRESOLVED` / `Unclear` +
  **`FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`**.

**Session 19 added that code and recorded that zero committed rows carried it.
Nevada is the first.** The source is silent on whether the money reaches the
hospital; coding `No` would deflate on this pipeline's authority and coding
`Yes` is the short-circuit session 19 removed, so the row enters **neither**
bucket of the partition.

---

## 10. The hospital figure's uncertainty — Kansas's shape a fifth time, and the first worth $0

NVHA publishes **no organisation-type column**, so all 73 rows are typed from
the recipient's own **name**: 20 award actions resolve to hospitals and **23
carry §8's standing fallback** (`NONPROFIT_CBO` + `LOW` +
`RECIPIENT_TYPE_INFERRED`). **Renown Health** (northern Nevada's largest health
system), **Carson Valley Health**, **Washoe Barton Medical Clinic DBA Carson
Valley Health** and **Intermountain Health** are all inside it and all
uncounted.

**Nothing was promoted (§0.4).** Queued as `NV_RECIPIENT_FORM_NOT_STATED`, and
it is **the first such row worth $0 in either direction** — with no amounts
published, the question moves a **count**, which is the only hospital quantity
Nevada supports. `nv_assert_form_not_stated_queued()` asserts the row, its 23
rows and that $0 effect every run, and fails if any fallback row ever acquires
an amount.

---

## 11. §0.1b patched — the initiative-level share is a proxy with measured error

Separately from Nevada, §0.1b of the spec and Part B of
`reviewer-coding-instructions.md` are patched (insert-only, §2.1: 69 and 46
lines added, nothing deleted) to record what session 25 measured.

**Oklahoma's Community-Led Wellness Hub microgrants are coded
`has_hospital_recipient = No`** in the committed initiative table, on the
narrative's own eligible-recipient language, stored verbatim in the row:
*"Local health departments in 59 rural counties and community-based entities."*
Nothing about that reading is careless.

**OSDH then published the roster: 20 of the 68 microgrant awards went to named
hospitals — $1,079,506.22 of $3,572,120.71, or 30.2% of the pool.** The coding
was not imprecise; it was wrong, and wrong in the **conservative** direction.

So `has_hospital_recipient` is recorded as what it is: **a reading of a PLAN, a
floor on hospital involvement, a discovery signal — never evidence about where
money went.** One measured case is explicitly **not** an error bar, and the
patch forbids applying a correction factor: inflating every `No` by 30% would
be a worse invention than the original coding.

**And the denominator moves too.** Oklahoma allocates that same fund use at
**$2,800,000** (Initiative Funding Summary, 2026-03-10) and **$7,750,000**
(Legislative Quarterly Report, 2026-07-10) — four months apart, both Oklahoma's
own, a **2.8× spread** — then awarded **$3,572,120.71**, matching neither.
Delaware makes the same point from the extraction side: **15.7% → 14.6%** once
initiatives 13–15 were added, with no row re-coded.

**§0.1b's headline finding is untouched.** The OK/DE spread is real, structural,
and must still never be averaged. What changed is what the percentage may be
*called*.

---

## 12. What this session deliberately did NOT do

- **No per-recipient amount was invented.** §6.2 forbids dividing a round
  total, and NVHA has published none.
- **The WRRAP pool conflict was not resolved.** The reallocation reading is
  plausible and is not published as a finding (§0.4).
- **The nine GME awards were not extracted**, and `nv_assert_gme_is_state_money()`
  refuses the file if one ever leaks in — positive-controlled by faking a leak.
- **No name variant was merged** (§2), and no fallback row was promoted (§0.4).
- **Nevada's initiative percentages** (RHOAP 15%, Flex 20%, WRRAP 40%, RHIT
  15%) are Tier 2 and, being percentages of an annual award rather than
  dollars, are a §7A artifact rather than an award figure. They are not in the
  file.

---

## 13. Next

1. **Michigan now leads the queue** at 31 candidates / 31 distinct awardees,
   then MO 29/29, NH 23/15, WI 19/19, IA 15/15.
2. **Nevada's six pending opportunities are the live tripwire.** RHIT closed
   7/6/26 with decisions due 8/10/26 and RHOAP closed 6/26/26 with decisions
   due 8/14/26 — **both decision dates have passed**, so Nevada is the state
   most likely to publish a fourth roster next. `--validate` fails the day it
   does.
3. **Nevada's amounts may yet appear.** NVHA's own process slide says *"All RHT
   subawards for BP1 to be finalized by October 1, 2026"* and that it *"will
   upload all RHT subaward information, subject to CMS review and approval"*.
   The roster parser **refuses** the day a dollar figure appears on the page,
   because this file's whole design rests on their absence.
4. **The CCN match (blocker 5)** is what turns Nevada's 16 hospital names into
   a count of organisations, and what resolves the 23 unstated forms.

---

## 14. Ninth question for the remaining states

Sessions 19–25 accumulated eight. Nevada adds a ninth, and it is the one that
survives every check the others added:

> **DOES THE DOCUMENT'S CMS FOOTER COVER THE PROGRAMME THE ROW BELONGS TO, OR
> ONLY THE PUBLISHING OF THE DOCUMENT?**

A state publication produced with RHTP money carries the CMS
financial-assistance footer on every page **whatever it describes**. NVHA's
workforce document carries it and describes three programmes, two of them
state-funded, worth $15.8M and $60M. Provenance is a property of the
**programme**, not of the paper it is printed on — so find the funding-source
line, and if the document does not have one, the footer has told you nothing.

And a tenth, cheaper one that Nevada answers immediately:

> **IS THERE A ROSTER WITH NO AMOUNTS ON IT?**

Every state hunt so far has asked "has this state published a recipient-level
list?" and treated yes as the end of the question. Nevada says yes and still
supports no dollar figure at all. **Ask what the roster's COLUMNS are before
planning what the file will hold.**

# Session 27 — the footer audit, and Michigan's complete roster

Zero RCJ quota. Seven Michigan sources archived; ~15 requests to
`www.michigan.gov`, 1 to `www.mha.org`, 1 to `www.cms.gov`, throttled per §9.5.

Three tasks: correct the Nevada PR body against the committed data, audit the
CMS financial-assistance footer everywhere it has been used as a §6.2 check,
and extract the queue leader. The audit is
`docs/session27_cms_footer_provenance_audit.md`; this document is the rest.

---

## 1. The Nevada PR body — three corrections

PR #27's body was rewritten against the committed files rather than the
session notes. Three claims were wrong:

| It said | The committed data says |
|---|---|
| the review-queue row is "20 hospital rows inferred from name" | `NV_RECIPIENT_FORM_NOT_STATED` is **23 rows** carrying §8's fallback (`NONPROFIT_CBO` + `LOW` + `RECIPIENT_TYPE_INFERRED`), **disjoint from** the 20 named-hospital award actions — verified, zero overlap |
| GME Round VIII is "$28.8M of Nevada state general fund money" | Nevada published **$15,755,068 across nine residency and fellowship programmes**. $28,803,045 is RCJ's own unvalidated sum over the 17 rows it files under RHTP-titled documents, and §0.1 says that is not a dollar figure |
| "The CMS Notice of Award footer appears on the document that states this exclusion" | the finding is the opposite: the footer appears on a publication that describes **two state-funded programmes** — GME (*"Source: State General Fund"*) and SHARP (an SB5 appropriation) — beside WRRAP, which is **why it is not a provenance test** |

---

## 2. The footer audit — one state was load-bearing

Full report: `docs/session27_cms_footer_provenance_audit.md`. The short form.

The axis the audit turns on is the footer's **grammatical subject**, which no
session note had recorded. *"This publication / presentation is supported
by…"* is a statement about the paper; *"This Rural Health Transformation
Program is supported by…"* is a statement about the programme. **Nevada's
disproof lands on the first form only.**

Five extractors reference the footer: KS, NE, IN, OK, NV. **Kansas is the one
where it is load-bearing**, and it uses the weak form:

- `2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf` contains **zero**
  occurrences of "RHTP" and **zero** of "Rural Health Transformation". Its
  first line is *"This **presentation** is supported by…"*.
- `ks_assert_rhtp_funded()` reads that string and nothing else — and its own
  doc comment says so.
- **39 rows, $79,013,347 — 98.7% of Kansas's published dollars and 98.4% of
  its named-hospital floor.**

**An independent check exists twice and neither is wired**, both already in the
committed archive: KDHE's programme page announces *"the recipients of the
RPGP and REH/CAP grants **through the Kansas Rural Health Transformation
Program (RHTP)**… $79.1 million… 39 organizations"*, and the Kansas RHT Plan
budget narrative places both pools inside the plan's initiative structure. The
narrative is **registered as source `budget_rev2` in `R/03o` and never read**.
So no Kansas dollar is in doubt; the code does not read the evidence.

NE, IN, OK and NV all pass on programme-scoped evidence in the same archived
sources. Nothing was re-coded — the task was to report.

---

## 3. Michigan — 139 awards, $69,883,392, and one named hospital

Michigan led the queue at 31 candidates / 31 distinct awardees.

```
award actions        139        distinct recipients  122
published            $69,883,392
CMS allotment        $173,128,201        share published  40.4%
named-hospital rows  1          named-hospital dollars  $76,924
```

### 3.1 The first roster whose publisher calls it COMPLETE

MDHHS's programme page: *"MDHHS maintains a dedicated webpage featuring **all**
RHTP Subrecipients."* No other state in this repository says that. Kansas,
Nebraska, Oklahoma and Nevada each publish a roster for some pools and are
silent about the rest, so every one of those figures is a floor by
construction. Michigan's $69,883,392 is a **total** — for as long as that
sentence is on the page, which `mi_assert_completeness_claim()` checks every
run. **The day it goes, every Michigan figure here becomes a floor and the
finding has to be rewritten.**

### 3.2 The amounts are not final, and MDHHS says so

Every column is headed *"Award Amount\*"*, and the asterisk resolves to
*"Award amount is contingent upon review by Centers for Medicare & Medicaid
Services (CMS) for final approval as a requirement of this grant."* So all 139
rows are `amount_confirmed = No` — Oregon's and Maryland's posture, except that
here the contingency is **federal review of a state award** rather than a state
negotiation with the recipient.

### 3.3 §6.2, with the footer downgraded — session 27's own audit, applied

Michigan's roster carries the **weak** footer: *"This **project** is supported
by … a financial assistance award totaling $173,128,201.02"*. It is used here
to corroborate the **amount** (it rounds to the §7.1 anchor to the dollar) and
never as the evidence that these awards are RHTP. Three **programme-scoped**
sentences are, and each is asserted separately:

1. the roster's own body — *"This page highlights the organizations that have
   received **RHTP funding**"*;
2. the programme page — *"MDHHS **was awarded $173,128,201 for Budget Period 1**
   (BP1; December 31, 2025-October 30, 2026) by CMS under the RHT Program"*;
3. the 2025-12-30 release — *"MDHHS was awarded $173,128,201 for FY 2026 by CMS
   **under the Rural Health Transformation Program**"*.

**The date half.** Michigan's NOA is 2025-12-29; MDHHS announced it **the next
day**. The Workforce for Wellness solicitations issued 2026-07-08 and the
award notices are *"as of July 10, 2026"* — the opposite of Texas's
`HHS0015180`, which closed eight months before its state had the money.

**The negative control is one of RCJ's own candidates.** MDHHS's 2026-06-24
release awards *"nearly $3.75 million to 12 organizations"* for youth
substance-use prevention, and its own sub-headline states the funding source:
***"New opioid settlement-funded grants support 12 organizations."*** The words
"Rural Health Transformation", "RHTP" and **"rural"** appear **zero** times in
it. RCJ files eight of the twelve as Michigan RHTP Tier 3 candidates.

### 3.4 §0.1 — and this one DEFLATES

Every §0.1 defect this project has met inflated, except Nebraska's mis-titled
document. Michigan's is a new mechanism and it deflates:

| Group | Rows | Disposition |
|---|---:|---|
| Real awards — but **one RCJ row per ORGANISATION** where MDHHS publishes one per **AWARD** | 14 | `RHTP_SUBAWARD_IN_FILE` |
| "State Of Michigan RHTP Budget Narrative" line items | 9 | `RHTP_BUT_NOT_A_SUBAWARD` |
| Youth substance-use prevention — **opioid settlement money** | 8 | `NOT_RHTP_STATE_PROGRAM` |
| | **31** | RCJ holds **14 of Michigan's 139** award actions |

Four organisations hold more than one MDHHS award and RCJ kept one of each:
its 14 rows carry **$19,484,032** against the **$27,317,365** those same
organisations actually hold — **it understates by $7,833,333**. The largest
single loss is the **Michigan Center for Rural Health**: RCJ $3,000,000, MDHHS
**five awards totalling $7,275,000**. This is Kansas's Greeley County defect —
RCJ keeping one of a recipient's two awards — at four times the scale, in a
state where the roster is the only place the other awards exist.

An extractor built from the candidate list would have published **$19,484,032**
as Michigan's RHTP subawards — 28% of the real figure — with **$2,214,846 of
opioid settlement money mixed into it**.

`MI-SUD-PREVENTION-2026` is now in `non_rhtp_state_programs.csv` and **catches
all eight with zero false positives**; the sweep goes **82 rows in 7 states →
90 in 8**. It catches them on RCJ's *headline*, because the funding source is
in the sub-headline, which RCJ does not carry — so the second alternative
("opioid settlement") matches nothing today and is registered anyway, on
Nebraska's RFA 4533 precedent.

### 3.5 One named hospital, and where Michigan's hospital money actually is

139 priced awards and **one** named-hospital award action of **$76,924**. That
is not a parse failure, and it is **not Nevada's zero**: Nevada publishes a
named roster with *no amounts*, so its 20 hospital rows carry $0; Michigan
publishes an amount on every row and almost none of it reaches a named
hospital. **The two zeros mean opposite things and must never be summarised
together.**

Michigan's recipients are local health departments, community action agencies,
FQHCs, Area Agencies on Aging, universities and tribal governments. Its
hospital-facing money runs through the **Michigan Health & Hospital
Association** — $6,000,000 (Rural Health Care Delivery Hub and Spoke Model) +
$2,625,000 (Collaborative Care Integration and Sustainability Fund) =
**$8,625,000**.

**MHA IS THE LARGEST CLASSIFICATION TRAP IN THE FILE.** The §8 name rule sees
"Hospital" in *"Michigan Health and Hospital Association (MHA)"* and returns
`HOSPITAL_OR_SYSTEM`, which short-circuits to `DIRECT` / `Yes` — publishing
**12.3% of Michigan's total as direct hospital dollars on a name match**. It is
Nevada's foundation trap a third time, and larger than both. MHA is typed
`HOSPITAL_AFFILIATED_ENTITY`, which since session 19 must read the source; the
source says nothing (MDHHS's roster has three columns and no project
description at all), so the two rows land on the terminal branch —
`PASS_THROUGH_UNRESOLVED` + `Unclear` + `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`
— and enter **neither** bucket of `rhtp_hospital_dollar_partition()`. Queued as
`MI_MHA_FLOW`, worth **$8,625,000**.

**One closure, unarranged.** MHA's own RHTP page carries its own footer:
*"a financial assistance award totaling **$8.625 million**"* — MDHHS's two rows
to the dollar. Two publishers, one figure.

### 3.6 The unstated-form question, sixth time and by far the largest

MDHHS publishes no organisation-type column, so outside the Tribal Government
section every `recipient_type` comes from the recipient's own **name**:
**84 of 139 rows / $39,836,422**, 57% of everything Michigan has published.

It is **one-directional**, as Oklahoma's is — every one of the 84 is already
`distributed_to_hospital = No`, so resolving any can only *raise* the figure.
Floor $76,924, ceiling $39,913,346. **Nothing was promoted (§0.4).**

Two groups inside it need different evidence and the queue row says so: the
**health systems** (MyMichigan Health ×2) and the **FQHCs**, which are most of
the 84 by row count — Alcona, Cherry Health, Covered Bridge, East Jordan,
Grace Health, Great Lakes Bay, Intercare, Isabella Citizens, Sterling Area,
Thunder Bay, Traverse Health and Upper Great Lakes all sit in one fund at
$76,923 or $83,333. **Resolving those DOWN costs nothing** and would halve the
question without moving a dollar.

### 3.7 Three parsing findings

**Session 10's `<td>` header defect, five tables at once.** MDHHS marks *every*
roster header row up with `<td>`. Unpromoted, Michigan reports 144 awards, five
of them to an organisation called *"Subrecipient Organization"* for an amount
of *"Award Amount\*"*. `mi_promote_header()` promotes only when the candidate
row resolves **strictly more** columns — session 10's own rule.

**The section mapping is read from DOCUMENT ORDER, and had to be.** A first
version located each table's first cell in the page text; that is wrong,
because **two sections share a first awardee** — *"Benzie-Leelanau District
Health Department"* opens both the Partnerships and the Workforce tables — so
the lookup finds the earlier table and silently relabels 19 rows. The nodes are
now walked in document order.

**Michigan's `Fund` column is an organisation-type column for exactly one
section.** The thirteen rows under *Tribal Government* carry "Tribal
Government" in the Fund column too, which is MDHHS stating the recipient's
**form**. Those thirteen are `TRIBAL_ORG` on the state's word (Alaska's and
Oregon's rule). It matters: **the §8 name rule reaches only nine of the
thirteen** — Bay Mills, Hannahville, Keweenaw Bay and Little Traverse Bay would
otherwise take §8's fallback while the state has plainly said what they are.

### 3.8 §0.3a in a parenthesis

MDHHS annotates two rows with the **project**, not the form —
*"MyMichigan Health (EMS - Chronic Disease)"* — and the §8 activity token then
types the **recipient** `EMS_OR_PSAP`. That is §0.3a's error: judge the
recipient, never the activity. Overridden to §8's fallback, which is where an
undetermined form belongs; **nothing was promoted** — `EMS_OR_PSAP` and the
fallback are both `distributed_to_hospital = No`, so $0 moves either way.

---

## 4. The host: a documented departure from session 10's rule

`www.michigan.gov` is fronted by Akamai and **refuses every identifying
user-agent**. Probed, not assumed:

| User-Agent | |
|---|---|
| `AHA-RHTP-Tracker/1.0 (research; +https://www.aha.org)` | **403** |
| `Mozilla/5.0 (compatible; AHA-RHTP-Tracker/1.0; +https://www.aha.org)` | **403** |
| a full Chrome UA with `AHA-RHTP-Tracker/1.0` appended | **403** |
| `Mozilla/5.0` | **200** |
| `https://www.michigan.gov/robots.txt` | **403** |

It is a **denylist on identifying tokens**, not an allowlist on browsers, and
because `robots.txt` is itself refused there is no crawler policy on offer and
none is being declined.

Session 10 settled the same question for `medicaid.gov` the other way — there
the `+url` form was what got through, and the note reads *"identifying honestly
is the fix, not a workaround"*. **Michigan inverts it: no honest identifier
works.** The owner was asked and chose to proceed with the anonymous agent,
documented. It is used for michigan.gov **only**; `mi_agent_for()` refuses it
on any other host and refuses the honest agent on michigan.gov, and a test
drives both refusals. `mha.org` and `cms.gov` take the honest agent.

`web.archive.org` was re-tested (blocker 7) and is **unchanged** — the TLS
handshake is still reset by the peer with no policy denial logged. But the apex
`archive.org` **now answers 200**, where session 12 logged it as
`connect_rejected` 403. Its `/wayback/available` API works; there is simply no
snapshot of the Michigan roster.

---

## 5. One shared-classifier change, and the one row it moved

Michigan awards **eleven multi-county health departments**, and the session-21
county rule reached none of them: *"Berrien County Health Department"* came out
`LOCAL_GOVT_OR_PUBLIC_HEALTH`, *"Benzie-Leelanau District Health Department"*
and *"District Health Department #10"* fell to §8's fallback, and *"Health
Department of Northwest Michigan"* matched `department of` and came out
`STATE_AGENCY`. **Maryland's session-21 defect one administrative tier down and
eleven rows wide.** The rule now reaches any health department or
`Public Health <place>` body, with `\bstate\b` excluded so a state health
department cannot fall into it; an alliance or association of health
departments still does not (both are tested).

**All fifteen existing extractors were re-run. Fourteen reference CSVs came
back byte-identical.** One row moved, in Nebraska: **Southeast District Health
Department, $195,746.93**, from §8's fallback to
`LOCAL_GOVT_OR_PUBLIC_HEALTH`. It was `distributed_to_hospital = No` before and
after, so **Nebraska's named-hospital floor is unchanged**; what shrank is a
false uncertainty. `NE_RECIPIENT_FORM_NOT_STATED` goes 30 rows / $9,411,695.59
→ **29 rows / $9,215,948.66**, and the queue row, the assertion and the test
all say so.

---

## 6. What Michigan adds to the state-hunt questions

**An eleventh: does the publisher say the roster is COMPLETE?** Every state
before Michigan published a partial roster and was silent about the rest, so
every figure in this repository is a floor by default. Michigan says
otherwise in one sentence on its programme page — and that sentence is the
difference between reporting a total and reporting a floor. **Look for it, and
assert it, because it can be withdrawn.**

**A twelfth: is the aggregator carrying one row per ORGANISATION or one per
AWARD?** Michigan is the first state where that distinction costs $7.8M, and
it costs it *downward*. Kansas showed it at one row; Michigan shows it at four
organisations and 125 missing awards. A candidate count that looks low against a
state's roster is not necessarily a state that has published little.

---

## 7. Tests

**2,889 assertions across 31 files; 2,888 pass and 1 self-skips** (the stage 00
first-run branch, as before). Was 2,712 across 30.
`tests/testthat/test_03v_mi_year1_awardees.R` is new — 170 assertions — and
`test_state_union.R` now combines **sixteen** state files.

Three existing tests were updated rather than deleted, each because a real
figure moved:

- `test_02b_provenance_sweep.R` — the sweep goes 82 rows in 7 states to 90 in
  8, all eight Michigan's opioid-settlement rows.
- `test_03r_ne_year1_awardees.R` — the unstated-form question goes 30 rows /
  $9,411,695.59 to 29 / $9,215,948.66, and now asserts that Southeast District
  Health Department is `LOCAL_GOVT_OR_PUBLIC_HEALTH`.
- `test_state_union.R` — sixteen files, and Michigan in the state list.

**Two Michigan tests are positive-controlled by construction**: the negative
control is fed a prevention release that *does* mention RHTP and required to
refuse, and the completeness claim is removed from the programme page and the
assertion required to fail. A negative nobody re-checks decays into an
assumption; these two are the ones that would decay first.

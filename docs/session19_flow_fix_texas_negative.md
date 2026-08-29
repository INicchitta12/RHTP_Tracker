# Session 19 — the flow short-circuit, and Texas turns out not to be Texas

**Date:** 2026-08-29
**Quota:** zero RCJ calls. 11 fetches to `pfd.hhs.texas.gov`,
`resources.hhs.texas.gov` and `www.hhs.texas.gov`, throttled per §9.5.
**Tests:** 1,645 assertions, all passing (was 1,586).

---

## 1. `rhtp_classify_flow()` — recipient type no longer pre-decides flow

`HOSPITAL_AFFILIATED_ENTITY` returned `DIRECT` + `distributed_to_hospital =
Yes` before a word of the project description was read. §10.2's `DIRECT` row
tests recipient **identity** — *"named recipient matches a hospital in
AHA/POS"* — and an affiliated entity (a hospital association, a foundation, a
hospital-owned nonprofit) is by construction **not that hospital**. The
short-circuit skipped the §10.2 flow test for the exact class of recipient the
test exists for.

Session 18 found the trap, recorded it in an assertion, and deliberately did
not fix it. It also named the case that shows what it cost: the Georgia
Hospital Association *"received a grant … to provide obstetrical emergency
carts"*. Carts reach hospitals, dollars stop at GHA, and Georgia hand-codes it
`IN_KIND_BENEFIT` + `No`. The shared function returned `DIRECT` + `Yes` for
that same `recipient_type` **whatever the source said**, and the only thing
between that and an inflated hospital total was the accident that
`R/03d_ga_great_health.R` does not call it.

**`HOSPITAL_OR_SYSTEM` keeps the short-circuit, and that is correct.** Where
the recipient *is* a hospital, recipient identity is the flow test and a
description has nothing left to decide.

### The terminal branch is the part worth arguing about

An affiliated entity now runs the same description chain as every other
non-hospital type — association-administered markers, pass-through markers,
hospital mention — but it does **not** share the chain's terminal.

For a school district or a vendor, a source silent about hospitals is evidence:
`NON_HOSPITAL`, `No`. For a hospital-governed recipient it is not. The money
may well reach hospitals and the document has simply not said. Coding that `No`
deflates on this pipeline's authority; coding it `Yes` is the short-circuit
just removed. §0.3 and §0.4 point at the same answer, so it is
`PASS_THROUGH_UNRESOLVED` + `Unclear` +
**`FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`** — a row that enters *neither* bucket
of `rhtp_hospital_dollar_partition()` and goes to a human with the source in
hand. §10.2's `NON_HOSPITAL` carve-out is about a source that *shows* the money
stays; it does not reach a source that says nothing.

The flag is in `vocabularies.csv` with full notes. **Zero committed rows carry
it.**

### The association branch now admits both types

§10.2's row prescribes `NONPROFIT_CBO`; Georgia types the same kind of entity
`HOSPITAL_AFFILIATED_ENTITY`. Until that is settled, admitting only one would
give one organisation two different flows depending on which state's extractor
typed it — which is the inconsistency the shared file exists to prevent. It
stays opt-in via `award_made`, so a second admitted type cannot move a row on
its own.

### The change moves no data, proved rather than inspected

All nine extractors re-run; **all nine reference CSVs come back byte-identical**
(sha256 against a pre-change snapshot). Their eight `.xlsx` renders differ
**only** in `dcterms:created` — every sheet part is byte-identical — so the
renders were reverted rather than committed as timestamp churn. That is a
second, independent confirmation: the rendered content did not move either.

Only **one** `HOSPITAL_AFFILIATED_ENTITY` row exists in the whole repository —
Georgia's GHA — and it is hand-coded.

### Georgia's row is not re-typed

The flow half of session 18's divergence is now resolved: the shared function
and Georgia **agree** that GHA is `IN_KIND_BENEFIT` + `No`. What is left is
purely the §8 typing question — is a hospital trade association
`NONPROFIT_CBO` (§10.2's row, and what AK and IL use) or
`HOSPITAL_AFFILIATED_ENTITY` (Georgia)? That is a human's call, and re-coding a
committed hand-coded row to satisfy a rule changed the same day is how §2.1's
regressions happen.

It goes to **`data/reference/classification_review_queue.csv`** as
`GHA_RECIPIENT_TYPE`, with the dollar effect stated: **$0 under either type**
(the row carries no amount, and it is `distributed_to_hospital = No` either
way), so it is to be decided on the spec, not on the total. The divergence
assertion stays, restructured to pin what the row says today so the queue entry
cannot go stale.

---

## 2. Texas — the negative, and 53 rows that are a different programme

Texas led the remaining queue on every measure `state_trigger_queue.csv`
carries: **rank 1, 68 RCJ Tier 3 candidates across 67 distinct awardees, and
the largest FY2026 allotment in the country at $281,319,361.** No CMS press
release, so `RCJ_ONLY`, and no session before this one had looked at it.

Two negatives came out of looking. **The second one is the finding.**

### 2.1 HHSC has published no recipient-level RHTP award list

Texas is at solicitation and negotiation stage. Its programme page prints a
timeline whose Notice-of-Award dates have **passed** and publishes no roster
against any of them:

| Initiative | NOA distribution | Contracts routed |
|---|---|---|
| 1 Part 1 — Make Rural Texans Healthy Again | 2026-06-19 | 2026-07-15 |
| 1 Part 2 | 2026-07-15 | 2026-08-31 |
| 4 Round 1 — Small Town Doctor and Team | 2026-07-17 | 2026-07-30 |
| 4 Round 2 | 2026-09-10 | 2026-09-21 |
| 6 Part 1 — Infrastructure and Capital | 2026-07-21 | 2026-08-14 |

Initiative 4 Round 2 (`HHS0017618`) was **still open** on the day this ran,
closing 2026-08-26. Texas's fiscal year begins September 1 and every
initiative's programme period starts in or after September 2026.

**The check is not a guess about HHSC's format.** HHSC publishes a roster by
adding an **"Awarded Grant Information"** section to the RFA detail page. Four
Rural Texas Strong solicitations were archived and **none** has one. Two 2025
solicitations on the same site were archived as a **positive control** and
**both do**. Without that control, "no such section" would be
indistinguishable from "we are looking for the wrong string", and the negative
would be an assumption wearing an assertion's clothes.

The Rural Texas Strong RFAs are also **not on the RFA index at all** — 81 RFAs
are listed across six pages and not one is Rural Texas Strong — so the index's
own *"Awarded Grant Opportunities"* table would not show them either. Their
detail pages resolve at direct URLs.

### 2.2 Not one of RCJ's 68 Tier 3 candidates is an RHTP award

This is §0.1's warned-of defect — *"non-RHTP records in the RHTP feed"* — at a
scale nothing in this project has met before.

| Group | Rows | Disposition |
|---|---:|---|
| `HHS0015180` Rural Hospital Debt Reduction | 21 | `NOT_RHTP_STATE_APPROPRIATION` |
| `HHS0015677` Rural Hospital Improvement | 32 | `NOT_RHTP_STATE_APPROPRIATION` |
| ATLIS incentive payments to Medicaid MCOs | 5 | `NOT_RHTP_MEDICAID` |
| Suggested Intergovernmental Transfers | 4 | `NOT_RHTP_MEDICAID` |
| Budget Period 1 narrative line items | 5 | `RHTP_BUT_NOT_A_SUBAWARD` |
| "80 Rural Hospital Districts" pool | 1 | `RHTP_BUT_A_CLASS_NOT_A_RECIPIENT` |
| | **68** | **RHTP subawards: 0** |

**The 53 are the dangerous ones.** They are real, executed, recipient-level
HHSC award lists naming rural Texas hospitals — 21 at **$250,000** each and 33
at **$350,000** each — published by the right agency, in the right format, as
Notices of Award. They are simply **a different programme**, and nothing on the
RCJ record says so.

HHSC says so, on its own Rural Hospital Financial Assistance page, under the
heading *"88th Texas Legislature, Regular Session, 2023"*:

> The 88th Texas Legislature appropriated **$50 million** to HHSC for the
> 2024-2025 biennium to establish grant programs for rural hospitals. … House
> Bill 1 … **Article II Rider 88** appropriated the grant funding.

The `HHS0015180` RFA says it twice more — *"Article II, Rider 88 (Rural
Hospital Grant Program) of the Texas General Appropriations Act, Acts of the
88th Legislature, Regular Session (2023)"* and *"the total amount of **state**
funding available … is $6,250,000"*.

**And the dates close it independently.** Both RFAs were **released in March
2025** and closed in April 2025 — before OBBBA created RHTP, and **nine months
before CMS issued Texas its RHTP Notice of Award on 2025-12-29.** Money the
state did not have cannot have funded a grant it had already closed
applications for.

An extractor written from the candidate list alone would have produced a clean,
plausible, fully sourced `TX_year1_awardees.xlsx` carrying **$16,800,000 of
state money as RHTP** — the single most defensible-*looking* wrong answer this
project could publish. It is §0.1's whole argument in one state: the aggregator
was right that Texas has hospital-level award documents and wrong about what
they fund, and **only the state source can tell the difference.**

A second, smaller defect sits inside the first: RCJ captured **32 of the 33**
rows in the `HHS0015677` Notice of Award.

The remaining 15 are Medicaid managed care (ATLIS, IGT), Budget Period 1
narrative line items (two DSHS AMBUS interagency contracts at $20,000,000, two
DSHS BRFSS oversampling contracts at $115,875, Deloitte grants-management
support at $1,750,000), and one row whose awardee is *"80 Rural Hospital
Districts with a publicly owned and operated hospital"* at **$250,000,000** —
whose own description reads *"Estimated 80 direct awards averaging $3,125,000
each"*. A **class** and an **estimate**, not a recipient and not an award:
North Dakota's *"15 selected CAHs"* (session 11) at a thousand times the size.

### 2.3 What was built, and what deliberately was not

**No `TX_year1_awardees.xlsx`**, because there is nothing to put in it.
Virginia's session 15 is the precedent: the host was opened, the question was
answered *no*, and no extractor was built. A test asserts the file's absence,
so a future session cannot mistake `tx_year1_status.csv` for an award file.

`R/03n_tx_year1_probe.R` archives eleven state sources with a SHA-256 manifest
(which excludes itself — session 15), writes `tx_year1_status.csv` (four
solicitations, **no `amount` column at all**, asserted absent so no sum can
ever produce a Texas hospital dollar) and `tx_rcj_candidate_disposition.csv`
(one row per group, with the disqualifying sentence and the archived document
that carries it).

**It carries a tripwire, on session 13's rule** — a negative nobody re-checks
decays into a stale assumption. Three branches, each positive-controlled in the
tests by reproducing the condition:

1. a Rural Texas Strong page gains an "Awarded Grant Information" section;
2. **the two control pages lose theirs** — without this, a site redesign that
   renamed the section would silently turn every future run green;
3. the programme page starts naming recipients.

The candidate count is **derived from `stage2_record_table.rds` on every run**,
not typed. The day a re-pull changes Texas's candidate set, the build fails and
someone reads the new rows rather than trusting a constant that still says 68.

The recipient scan splits on sentences before matching (session 13), and the
abbreviation list is the whole difficulty: splitting naively on `". "` cuts
*"St. Mary's Hospital"* in half and makes a **real** roster entry invisible,
which in a tripwire is the failure that costs something.

### 2.4 A queue status for a finished negative

`extraction_status` had two values and needed a third. Left `NOT_EXTRACTED`,
Texas would rank **1** again on the next survey and be re-investigated from
scratch — which is how a project eventually gets a completed negative wrong.

**`INVESTIGATED_NO_LIST`** (and the matching `queue_status`) is added to
`vocabularies.csv` with full notes. It is *not* `EXTRACTED` — no award file
exists — and *not* `QUEUED` — looking again today returns the same negative.
Its probe re-opens it. **It is never a statement that the state awarded
nothing** (§0.1, §0.3).

Texas drops from rank 1 to rank 50. **Kansas now leads the queue** (54
candidates / 50 distinct awardees), then MD 42/41, NE 39/35, IN 37/28, OK
35/25.

---

## What the next session should take from this

**Check what the candidate documents FUND before building an extractor, not
just whether they name recipients.** Every state hunt in sessions 9–18 asked
"has the state published a recipient-level list?" Texas answers **yes** — twice
over, with dollar figures and hospital names — and the honest answer to the
project's question is still **no**. The extra question is one page of the state
site away and it is the difference between a finding and $16.8M of the wrong
money.

Oregon's lesson still holds alongside it: check `/activity` `siteUrl` for a
state's real source URLs before concluding it has published nothing. For Texas
that is what surfaced `pfd.hhs.texas.gov/rural-health-transformation-program`
and `resources.hhs.texas.gov/rfa` — neither of which appears in
`state_source_url` on a single one of the 68 Tier 3 records.

# Session 18 — the §10.2 hospital-association row, and an audit that moved nothing

**Date:** 2026-08-28. Zero RCJ quota, zero network calls. Everything below was
read out of committed archives and committed reference CSVs.

---

## What was added

§10.2 gains a row and a worked-example block covering **hospital trade
associations and hospital-governed entities**:

> An award to a hospital association, hospital-owned nonprofit, or association
> foundation is `recipient_type = NONPROFIT_CBO`, `flow_type =
> PASS_THROUGH_DESIGNATED`, `distributed_to_hospital = Yes` — **provided the
> source shows the funds are administered to or on behalf of member hospitals**.
> Record the entity in `intermediary_name`.
>
> This does not extend to an association's own operating, advocacy, or
> membership costs where the source shows no flow to hospitals. That is
> `NON_HOSPITAL`. **The test is what the document says the money does, not what
> the organization is.**

Patched into all three documents that carry the flow rules —
`rhtp-tracker-build-spec.md` §10.2, `CLAUDE.md` §7,
`reviewer-coding-instructions.md` — by patch, never by upload (§2.1). Nothing
was deleted from any of them.

**A second carve-out was added on the evidence below**, because the first one
alone does not cover the cases that actually occur: an association that
**keeps the money and buys goods or services with it** is `IN_KIND_BENEFIT`,
not `PASS_THROUGH_DESIGNATED`. Both of the rule's positive examples move
**money** to hospitals — ICAHN *"will administer the funds to"* them, Oklahoma's
hospitals are *"reimbursed"*. That, and not the organisation's name, is what
separates them from every negative in the audit.

### `reviewer-coding-instructions.md` did not previously restate the flow table

The task assumed all three files carry it. Two do. The reviewer instructions
carry the *rule* — Part A step 4 on intermediaries, and the §10.2 quote block at
the top — but never the table. The new block is inserted there in full,
immediately after step 4, and `test_flow_table_parity.R` now asserts the three
copies are **byte-identical**, which is a cheaper guard against §2.1's failure
mode than reading three files and hoping.

### One figure in the task did not match its source, and the source won

The task gave the Oklahoma worked example as *"Oklahoma Hospital Association,
$6.6M — 'implementation will be conducted by hospitals reimbursed for CHW
hiring.'"* That quoted sentence is the committed evidence on
`OK_initiative_table.xlsx` → *CHW Expansion in Hospitals*, which is
**$4,300,000**. The state's $6,600,000 line is *MFM Telehealth Expansion*, led by
the University of Oklahoma, coded `PASS_THROUGH_UNRESOLVED` / `Unclear` — a
different row, a different lead, and not an association award at all.

**$4,300,000 is what went into the spec**, because §0.4 does not allow a figure
the quoted source does not support. A test re-reads both quotes out of the
committed files on every run, so the spec's worked examples cannot drift from
the data they came from.

---

## The audit — every extracted state, and the answer is zero

All nine state files and both initiative tables were searched for hospital
associations, hospital-owned nonprofits and association foundations, and every
hit was read back against its archived source.

| State | Entity | Amount | Coding | Changes? |
|---|---|---:|---|---|
| **AK** | Alaska Hospital & Healthcare Association — 4 awards | **$1,093,458.27** | 3 × `IN_KIND_BENEFIT`, 1 × `NON_HOSPITAL` | **No** |
| **AK** | The Greater Fairbanks Community Hospital Foundation | $16,009,453.33 | `HOSPITAL_OR_SYSTEM` / `DIRECT` / `Yes` | **No** |
| **GA** | Georgia Hospital Association | not published (pool $10,378,639) | `IN_KIND_BENEFIT` | **No** |
| **GA** | Georgia Health Care Association | not published (pool $6,209,688) | `NON_HOSPITAL` | **No** |
| **IL** | Illinois Critical Access Hospital Network | $50,008,264 | `PASS_THROUGH_DESIGNATED` / `Yes` | **No** |
| **OK** | Oklahoma Hospital Association — CHW Expansion | $4,300,000 | `PASS_THROUGH_DESIGNATED` / `Yes` | **No** |
| **OK** | Oklahoma Hospital Association — Lung Cancer Screening | $2,300,000 | `PASS_THROUGH_DESIGNATED` / `Yes` | **No** |
| **OK** | Rural Health Collaborative Nonprofit (hospital-owned) | $43,100,000 | `PASS_THROUGH_DESIGNATED` / `Yes` | **No** |
| **OR** | Sky Lakes Foundation (DBA Healthy Klamath) | $469,987.33 | `NON_HOSPITAL` | **No** |
| **FL** | Calhoun Liberty Hospital Association | $650,000 | `HOSPITAL_OR_SYSTEM` / `Yes` | **No** |
| **PA**, **AL**, **DE**, **SD** | — none — | — | — | — |

**Rows changed: 0. Dollar effect, every state: $0.** The partition is
unmoved:

```
NAMED_HOSPITAL        : 293,195,415   AL 66.1M · GA 60.0M · OR 50.2M · FL 49.3M · AK 43.4M · PA 24.1M
POOL_UNNAMED_HOSPITALS:  50,008,264   IL
```

Proof rather than inspection: with the new rule in the classifier, **all nine
state extractors were re-run end to end and every committed reference CSV came
back byte-identical.**

### Alaska is the case the rule was expected to move, and it does not

The prompt flagged the Alaska Hospital & Healthcare Association as *"3 awards,
$735,258 — currently not coded hospital"*. It is **four** awards totalling
**$1,093,458.27**; the three excluding the largest sum to **$735,186.40**.
Read against Alaska's own award notice, none of the four meets the proviso:

| App ID | Amount | What the source says AHHA does with the money | Code |
|---|---:|---|---|
| `BP1-IA-021` | $358,271.87 | *"establishing a mobile itinerant clinical training program and distributing localized simulation kits … across rural healthcare facilities"* | `IN_KIND_BENEFIT` |
| `BP1-IA-022` | $236,031.00 | *"Find Your Fit", a career platform and recruitment campaign, "developed in partnership with Alaska's 24 hospitals"* | `IN_KIND_BENEFIT` |
| `BP1-PL-003` | $249,197.00 | *"Strategic, Financial, and Operational Assessments (SFOAs) for three independent Critical Access Hospitals — Petersburg Medical Center, Cordova Community Medical Center, and South Peninsula Hospital"* | `IN_KIND_BENEFIT` |
| `BP1-PL-002` | $249,958.40 | *"incubate the Alaska Nursing Workforce Center … nursing workforce data, research, and strategic planning"* | `NON_HOSPITAL` |

`BP1-PL-003` is the hard one and the most instructive: it **names three
hospitals**, which is the surface form of §10.2's original
`PASS_THROUGH_DESIGNATED` test. But a subrecipient is an entity that receives a
subaward, and these three receive an assessment AHHA performs. No money moves.
Coding it `Yes` would put $249,197 into the hospital total on this pipeline's
authority rather than Alaska's — and all four rows are **notices of intent to
award with preliminary amounts**, so the second clause ("the award has been
made") fails as well.

`BP1-PL-002` is the first carve-out almost verbatim: an association building its
own institution, with no hospital named anywhere in the funded work.

### Georgia is the second carve-out almost verbatim

DCH: *"The Georgia Hospital Association received a grant to support Strengthening
Perinatal Systems of Care to **provide obstetrical emergency carts** and support
evidence-based patient safety practices."* Carts reach hospitals; dollars stop
at GHA. `IN_KIND_BENEFIT`, `hospital_benefiting = Yes`.

The **Georgia Health Care Association** is a red herring the name test would
have caught wrongly in the other direction: it is Georgia's *long-term care*
trade association, awarded for nursing-home transportation. `NON_HOSPITAL`.

### Oregon's one hospital-governed candidate stays out

**Sky Lakes Foundation (DBA Healthy Klamath)**, $469,987.33, is the foundation
arm of Sky Lakes Medical Center — the shape the rule's "association foundation"
clause is written for. OHA's own Organization Type field calls it *"Coalition,
Social Service or Community-Based Organization"*, the award is a Catalyst
*Healthy Communities & Prevention* project, and nothing in the source moves
money to a hospital. `NON_HOSPITAL`. (Sky Lakes Medical Center itself is a
separate row, $1,394,000, `DIRECT`.)

### Florida's "Hospital Association" is a hospital

**Calhoun Liberty Hospital Association**, $650,000, is the legal name of
Calhoun–Liberty Hospital, not a trade body. Already `HOSPITAL_OR_SYSTEM` /
`Yes`; the new row does not touch it. It is the reason a name-keyed rule was
rejected in both directions.

---

## Making the rule operative

A rule that lives only in prose is not applied by the next state's extractor, so
`rhtp_classify_flow()` in `R/utils_recipient_classification.R` gains the branch.
Two things keep it from becoming the inflation §0.3 exists to prevent:

**It is keyed on money movement, not on the organisation.**
`RHTP_ASSOCIATION_ADMINISTERED_MARKERS` matches *administered … funds …
hospitals*, *subaward/subgrant … hospitals*, *payments/grants/funding to
hospitals*, *hospitals … reimbursed*, *distributed … hospitals* — and, per
session 13's rule, **never across a full stop**, because a pattern allowed to
span sentences joins an award verb in one to *"hospitals"* in the next.
Undermatching leaves a row where it is, which is the safe direction for the only
branch in the file that can move dollars *into* the hospital total.

**It is opt-in.** §10.2's second clause — has the award actually been made? — is
a property of the document, not of the description, so it is a new `award_made`
argument defaulting to `FALSE`. Every committed extractor calls the
two-argument form, which is why nothing moved. A state whose awards are executed
passes `TRUE` per row.

Both directions are tested. The two spec examples fire only with
`award_made = TRUE`; the four negatives above are fed to it **with
`award_made = TRUE`** — the hostile setting — and all four decline.

---

## One trap found and deliberately not closed

`rhtp_classify_flow()` returns `DIRECT` / `Yes` for **any**
`HOSPITAL_AFFILIATED_ENTITY`, before any description is read. Georgia hand-codes
the Georgia Hospital Association as `HOSPITAL_AFFILIATED_ENTITY` +
`IN_KIND_BENEFIT` + `No`. **The two disagree**, and nothing reconciles them today
only because the Georgia extractor does not call the shared function.

It matters for the next state: a hospital association typed
`HOSPITAL_AFFILIATED_ENTITY` and run through the classifier lands in the hospital
total automatically, with the §10.2 proviso never tested. The association branch
does **not** guard this — it is reachable only from `NONPROFIT_CBO`.

Nothing was changed, because the fix is a judgement about §8 rather than about
§10.2, and re-typing a committed hand-coded row to satisfy a rule added the same
day is how §2.1's regressions happen. The divergence is pinned by an assertion
in `test_utils_recipient_classification.R` instead, so it fails loudly the moment
anyone assumes it is guarded.

**The open decision for the owner:** should a hospital trade association be
`recipient_type = NONPROFIT_CBO` (what the new §10.2 row prescribes) or
`HOSPITAL_AFFILIATED_ENTITY` (what Georgia wrote)? Alaska and Illinois already
use `NONPROFIT_CBO`, so Georgia is the outlier of three. Changing it moves **no
dollars** — GHA has no published `amount` and stays `distributed_to_hospital =
No` either way — but it removes the trap above at its source.

---

## Tests

**1,586 assertions, all passing** (was 1,536), one self-skip unchanged.

- `test_flow_table_parity.R` — new, 32 assertions. The block exists in all three
  documents; the three copies are byte-identical; it states the proviso, both
  carve-outs and `intermediary_name`; the table row sits inside the flow table
  in both files that have one; and both quoted worked examples still match the
  committed sources they were read from.
- `test_utils_recipient_classification.R` — 5 new tests. Default-off, both
  positives, all four negatives under `award_made = TRUE`, the no-crossing-a-
  full-stop guard, and the `HOSPITAL_AFFILIATED_ENTITY` divergence.

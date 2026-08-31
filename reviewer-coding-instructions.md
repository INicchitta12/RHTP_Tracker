# RHTP Tracker — Reviewer Coding Instructions

**Read this before coding any record.** It exists because the first eleven
records were coded wrong in a way that would have reported Delaware's hospital
total as zero.

Two kinds of coding happen in this project and the rules differ. **Part A** is
for award records — an RCJ record or a state award notice naming a recipient.
**Part B** is for initiatives read out of a state budget narrative. The one rule
below governs both.

---

## The one rule

# Code the RECIPIENT, not the ACTIVITY.

The question is **who received the money**, never **what the money was spent
on**.

A hospital that receives RHTP funds to run a clinic inside a middle school is
still a hospital receiving RHTP funds. Where the clinic sits is irrelevant to the
coding.

> **The setting is not the code.** Spec §10.2 now says this outright: Nebraska's
> school kitchen modernization awarded to the Department of Education is
> `NON_HOSPITAL`; Delaware's school-based health center awarded to Beebe
> Healthcare is `DIRECT`. Same setting, different recipients, different codes.
> If an example list ever seems to code an activity, the recipient wins.

---

## What this project delivers — and what it does not

Two separate deliverables, from two separate sources. **They do not substitute
for each other and must never be merged** (§0.1a, §7A.5a).

| | Deliverable 1 — *which* hospitals | Deliverable 2 — *how much* flows |
|---|---|---|
| Source | Award notices, procurement postings | State budget narratives |
| Unit | One named recipient | One initiative |
| Coded in | **Part A** | **Part B** |
| Gives you | Recipient names, state, initiative | Initiative dollars + hospital-directed flag |

**No state publishes a per-hospital dollar figure, so this project does not
report one.** Delaware and Oklahoma both publish initiative-level dollars and
neither publishes recipient-level amounts. If a task seems to require splitting
an initiative budget across recipients, the task is wrong — stop and ask.

---

# Part A — Coding an award record

## Worked examples — all real, all from the Delaware premise test (§9.11)

| Awardee | Activity | `hospital` | Why |
|---|---|---|---|
| Beebe Healthcare | School-based health center | **Yes** | Beebe is a hospital system. It got the money. |
| TidalHealth | School-based health center | **Yes** | Hospital system. |
| Nemours Children's Health | School-based health center | **Yes** | Pediatric hospital system. |
| Beebe Medical Center | Diabetes wellness pilot | **Yes** | Hospital. |
| Thomas Jefferson University | Medical school partnership | No | University, not a hospital. |
| Delaware Health Information Network | Statewide HIE infrastructure | No | Vendor. Hospitals benefit; hospitals receive nothing. |
| Delaware State Housing Authority | Housing-linked initiative | No | Real recipient, not a hospital. |
| "Not identified" | VBC readiness | **Unclear** | State confirms an award, names nobody. |

Four of the first four rows were originally coded `no` because the activity
happened in schools. All four are hospitals.

## How to decide

**1. Who is named as the recipient?** Read the name, ignore the program
description.

**2. Is that named entity a hospital or health system?** Look for: Hospital,
Medical Center, Health System, Healthcare, Regional Health, or a known system
name. When unsure, search the name — do not guess from the activity.

**3. If no recipient is named** → `Unclear`. Never infer one from the activity or
from who is eligible.

**4. If the recipient is an intermediary** (a foundation, a state agency, a
hospital association) → flag it and note who the money passes to, if the document
says. If it doesn't say → `Unclear`.

## Hospital trade associations and hospital-governed entities

An award to a **hospital association, hospital-owned nonprofit, or association
foundation** is `recipient_type = NONPROFIT_CBO`, `flow_type =
PASS_THROUGH_DESIGNATED`, `distributed_to_hospital = Yes` — **provided the
source shows the funds are administered to or on behalf of member hospitals**.
Record the entity in `intermediary_name`.

**Worked examples.** *Illinois Critical Access Hospital Network,
$50,008,264* — the source states ICAHN *"will administer the funds to Critical
Access Hospitals and other eligible non-urban Illinois hospitals."* *Oklahoma
Hospital Association, CHW Expansion in Hospitals, $4,300,000* — *"implementation
will be conducted by hospitals reimbursed for CHW hiring, training, and
monitoring."*

**This does not extend to an association's own operating, advocacy, or
membership costs where the source shows no flow to hospitals. That is
`NON_HOSPITAL`. The test is what the document says the money does, not what the
organization is.**

**And it does not reach an association that keeps the money and delivers goods
or services with it.** That is `IN_KIND_BENEFIT`, and the two worked negatives
are the reason this row cannot be applied from the organisation's name alone.
The *Georgia Hospital Association* "received a grant … to provide obstetrical
emergency carts": carts reach hospitals, dollars do not. The *Alaska Hospital &
Healthcare Association* proposes "Strategic, Financial, and Operational
Assessments … for three independent Critical Access Hospitals" — it **names**
three hospitals and still administers nothing to them, because AHHA performs the
assessments. Both of the positive examples above move **money** to hospitals
("administer the funds to", "reimbursed"); neither negative does.

## Two claims, coded separately

Never merge these into one column (§9.3).

**`recipient_confirmed`** — does a state source name this recipient?
`Yes` / `No` / `Unclear`

**`amount_confirmed`** — does a state source give a dollar figure **for this
specific recipient**? `Yes` / `No` / `Unclear`

**`amount_confirmed = No` is the normal answer.** It was the answer for all
eleven Delaware records. Most states publish dollars only at initiative level.
That is not a failure and not something to work around. A row that is
`recipient_confirmed = Yes` and `amount_confirmed = No` is a real finding — do
not downgrade it to `Unclear`.

**An initiative budget is not a recipient amount.** If a document says "$950,000
for the Diabetes Wellness Program" and names Beebe and TidalHealth as
participants, that is **not** $950,000 to Beebe and **not** $475,000 each. Record
the initiative figure in the initiative table; leave the recipient amount blank.

**Never split an initiative budget across recipients.** Not evenly, not
proportionally, not at all.

## Evidence — required for any `Yes`

| Field | Requirement |
|---|---|
| `state_source_url` | A **URL**, starting `http`. Not a page title. "Contract Details HSS26063 - DE Bids Contracts" is a title and will be rejected on read-back. |
| `archive_path` | A saved copy of the page or PDF. Browser "Print to PDF" is fine. State pages move. |
| `confirming_text` | The actual sentence establishing the award, pasted in. |

No archive, no `Yes`.

## What counts as a state source

**Strong** — Notice of Award, Notice of Intent to Award, procurement portal
posting, state RHTP budget narrative, official state agency or governor release
naming the recipient.

**Not sufficient on its own** — news articles, trade press, RCJ's own record or
description, a vendor's press release.

Third-party news can never support a `Yes`. It can point you toward the state
source; find that instead.

---

# Part B — Coding an initiative from a budget narrative

The unit here is the **initiative**, not the recipient. Most initiatives name no
recipient at all — Delaware names one for only 4 of its 15 initiatives — and
that is expected, not a gap to fill (§7A.5).

You are setting one flag: **`has_hospital_recipient`** ∈ `Yes` / `No` /
`Unclear`. The initiative's dollar figure travels with that flag. **The flag, not
a per-hospital split, is what the deliverable reports.**

## The flow language decides

Read the sentence describing where the money goes, and store it verbatim in
`evidence_from_document` so the call can be checked without reopening the PDF.

| Ask | Code |
|---|---|
| Does the document say funds are **paid, reimbursed, or subawarded to** hospitals or health systems? | `Yes` |
| Does it say hospitals **may be eligible**, or are one of several possible recipients? | `Unclear` — eligibility is not receipt (§0.3) |
| Do hospitals **use, host, or benefit from** something bought for them by someone else? | `No`, and set the in-kind flag |
| Is the recipient class clearly something else — schools, libraries, universities, housing, vendors? | `No` |

**A named hospital is not required for `Yes`.** Oklahoma names no individual
hospital anywhere and still has six hospital-directed fund uses, because the
narrative says money goes *to* hospitals as a class. This is the opposite of Part
A, where a name is the whole question. Do not import Part A's naming test here —
it would code nearly every state at zero.

**Equally, a Part B `Yes` is not a receipt claim about any particular hospital.**
It never becomes a Deliverable 1 row. Recipient identity emerges later, through
procurement (§7A.5a).

## Worked examples — from the two reference states

| State | Initiative | Flow language | Flag |
|---|---|---|---|
| OK | CHW Expansion in Hospitals, $4.3M | "conducted by hospitals reimbursed for CHW hiring" | **`Yes`** — hospitals are the reimbursed party |
| OK | Provider Collaborative Network, $43.1M | nonprofit "composed of and owned by rural hospitals" | **`Yes`** — hospital-owned entity is the recipient |
| OK | Maternal Health VBP Support, $1.3M | "incentive payments for birthing hospitals" | **`Yes`** — explicit hospital payments |
| OK | Telestroke, $500K | certification fees for rural hospitals; hospitals named as beneficiaries, not individually | **`Unclear`** |
| OK | Chronic Disease Management, $12.8M | "funded organizations" unspecified; hospitals may be eligible | **`Unclear`** — eligibility only |
| OK | MFM Telehealth, $6.6M | equipment deployed at rural sites incl. hospitals | **`Unclear`** — deployment is not receipt |
| OK | School-Based Health Services Support | NOFO for schools and education departments | **`No`** — schools receive it |
| DE | School-Based Health Centers Expansion, $195K | "Vendor TBD" | **`Unclear`** — the narrative predates the award |
| DE | Delaware Medical School, $42.5M | medical school | **`No`** — largest single line in the state, and not a hospital |

**Note the last two.** Delaware's SBHC *awards* to Beebe, TidalHealth, and
Nemours are Part A `Yes` rows (verified from a governor's announcement), while
the same program's *initiative* row is Part B `Unclear`, because the narrative was
written before the vendor was chosen. Both are correct. They are different claims
from different documents.

And note the OK/DE school-based pair: Oklahoma's is `No` and Delaware's awards
are `Yes`, same activity, because the recipients differ. That is the one rule
doing its work.

## Never divide

Never divide an initiative budget across its recipients, participants, or
counties. States don't publish the split, and inventing one would be the most
damaging thing this project could do.

## Expect wide variance and never average it

Hospital-directed share is 48.7% in Oklahoma and 15.7% in Delaware — a threefold
spread driven by program design, not by coding. **The variance is the finding.**
Report state by state. There is no defensible national percentage, so do not
compute one.

*(Delaware's figure is **14.6%** once initiatives 13–15 are included; 15.7% is
the twelve-initiative number. See below — the denominator moves.)*

## Your flag is a PROXY, and one state has now measured its error

This is the most important thing in Part B and it was learned after the rules
above were written.

**Oklahoma's Community-Led Wellness Hub microgrants are coded `No`** in the
committed initiative table, on the flow language the narrative actually uses:
*"Local health departments in 59 rural counties and community-based entities."*
Read against the table above that is the correct call — it is the document's own
statement of the recipient class, and "community-based entities" is not a
hospital.

**OSDH then published the roster: 20 of the 68 microgrant awards went to named
hospitals — $1,079,506.22 of $3,572,120.71, or 30.2% of the pool.**

So a coding that follows these rules exactly can still be wrong, and here it was
wrong in the direction that under-reports hospitals. That is not a reason to
start guessing upward — inflating a `No` because Oklahoma's turned out to be 30%
would be a worse invention than the original call, and one state is not an error
bar. It is a reason to say plainly what the flag is:

> **`has_hospital_recipient` is a reading of a PLAN.** It says where to look. It
> is a **floor** on hospital involvement, never an estimate of it, and never
> evidence about where money actually went. Only a recipient-level roster
> (Part A) answers that.

**Keep coding exactly as the table above says.** Do not adjust for this. Your job
is to record what the document says, and §0.4 means the correction comes from a
published roster, not from a reviewer's expectation.

## And check the date on the narrative — states revise these

The share is a ratio and **both halves come from documents states rewrite.**
Oklahoma allocates that same microgrant fund use at **$2,800,000** in its
Initiative Funding Summary (2026-03-10) and **$7,750,000** in its Legislative
Quarterly Report (2026-07-10) — four months apart, both Oklahoma's own, a 2.8×
spread — and then awarded **$3,572,120.71**, matching neither.

Always fill `source_document` and its date. Never compare a share computed from
one vintage of a narrative against a share computed from another, and never
update a single line from a newer document while leaving its neighbours on the
old one — that produces a total no state ever published.

---

## One field naming several recipients

Some `awardeeName` fields name more than one organization. New Hampshire returned
three managed care organizations in one row; one Oregon row names 102 clinics;
Delaware returned `University of Delaware, Beebe Healthcare, Deloitte Consulting
LLP`.

The pipeline splits these and flags the group **`MULTI_RECIPIENT_FIELD`**,
emitting one candidate row per fragment. Two things to know:

**The split is a guess about the state's formatting, not a fact.** Check the
fragment list against the state source before coding any of them. Some splits are
wrong — `University of Nevada, Reno General Surgery Residency Program` comes
through as two — and some fragments are junk. Dismiss those; the flag exists so a
hospital buried in the middle of a string doesn't disappear.

**The amount belongs to the field, not to any fragment.** Every candidate row
carries `amount_announced_field_total` — the whole figure, on every fragment,
labelled as the field's total. It is not that recipient's award. This is the same
rule as an initiative budget: **never split it across recipients.**

---

## The other flags you will see, and what each one asks of you

| Flag | What it means | What to do |
|---|---|---|
| `UNPARSED_AWARD_CANDIDATE` | A document looks award-shaped but RCJ produced no award record. **It carries no tier claim.** | Open the source. If it is a real subaward, code it; if not, dismiss. |
| `AMOUNT_EXCEEDS_STATE_ALLOTMENT` | The amount is larger than the state's whole CMS allotment. | Almost always a multi-recipient or multi-year field. Find the real figure or leave the amount blank. |
| `PROGRAM_NAME_AS_AWARDEE` / `STATE_AGENCY_AS_AWARDEE` | The awardee field holds a program or an agency, not a recipient. | No recipient is named → `Unclear`. Do not promote the agency to recipient. |
| `PAGE_CHROME_TITLE` / `EVENT_SCHEDULE_BLEED` | Extraction defect — navigation text or an unrelated page captured as content. | Dismiss unless a real award is visible underneath. |
| `NON_RHTP_SELF_DECLARED` / `PROVENANCE_MISMATCH` | The record may not be RHTP money at all. | Confirm the program in the state source before coding anything. HRSA, USDA, Flex and FCC money is not RHTP money. |
| `SOURCE_IS_PLAN_NOT_AWARD` / `REOPENED_SOLICITATION` / `WITHDRAWN` | A plan, projection, or an award that didn't happen. | `Unclear`, or `No` where the source shows it cancelled or unawarded. |
| `DUPLICATE_RECORD_ID` / `CONTENT_DUPLICATE` | Two records may be the same award. | Code one. Never let the same dollars enter the table twice. |
| `RECIPIENT_TYPE_INFERRED` | The recipient is **named and confirmed**; only its organisational form was not determinable, so `recipient_type` reads `NONPROFIT_CBO` as a placeholder at `LOW` confidence. | If the source or a quick lookup settles the form, set the real value and clear the flag. If it does not, leave it. **Never read the `NONPROFIT_CBO` as a finding** — it is a placeholder, not a determination that the recipient is a nonprofit. |
| `RECIPIENT_NAMES_NOT_CAPTURED` | The source names a **class** of recipient and a count — "13 hospitals" — but no individual names. | Look for a published roster; states often post one separately. If you find it, the row expands into named rows. If not, leave it as one aggregate row. **Never invent the names, and never divide the amount across the count.** |
| `PHASE_ATTRIBUTION_INFERRED` | The recipient is confirmed, but **which announcement awarded it** was inferred rather than stated — so a per-recipient figure stated in one announcement cannot be attributed to this row. | Leave the amount blank unless you find a source that states it for this recipient. What is uncertain is the attribution, never that the recipient was awarded. |
| `ELIGIBILITY_NOT_RECEIPT` | The source says the entity is **eligible to apply**, not that it received anything. | `Unclear`. This is §0.3 and it is the single most attackable error in the file. Never upgrade it to `Yes` without an award document. |

---

## When you cannot tell what kind of organization the recipient is

This has one answer, and it is not free text. **Code `recipient_type` as
`NONPROFIT_CBO`, set `determination_confidence` to `LOW`, and set
`flag_reason` to `RECIPIENT_TYPE_INFERRED`.** Then move on.

Three things about that:

- **It is a placeholder, not a finding.** Nobody downstream may read
  `NONPROFIT_CBO` on a flagged row as "this recipient is a nonprofit". The flag
  is what carries that. If you drop the flag, you have made a claim.
- **It applies only when the form is genuinely undetermined.** A pediatrics
  group, a fetal medicine practice and a primary care clinic are all
  determinable — they are `PHYSICIAN_PRACTICE`, which is a real §8 value. Do not
  reach for the placeholder to avoid a judgement you can actually make.
- **The recipient itself is still confirmed.** This says nothing about whether
  the award happened or who got it. Only about what kind of organization they
  are.

Florida and Georgia had answered this differently — Florida wrote
`UNCLASSIFIED`, which is not a §8 value at all, and Georgia used the convention
above. Florida was back-fitted to Georgia's in session 10, and the original
value is preserved in `recipient_type_source` on every row. Two answers to one
question would have split Stage 5's hospital determination, which is the
decision the whole file exists to support.

---

## When to stop and ask

- The recipient name is ambiguous (**not** merely that you can't tell what kind of organization it is — that case has an answer, above)
- The amount conflicts between two state sources
- The document is both a plan and an award list and you can't tell which applies
- The award appears to duplicate one you've already coded
- Anything that seems to require inventing a per-recipient dollar figure
- Anything that feels like it needs a judgment call the rules above don't cover

Put it in the review queue with a note. **An honest `Unclear` is always better
than a confident guess.** Every `Yes` in this file has to survive someone trying
to knock it down.

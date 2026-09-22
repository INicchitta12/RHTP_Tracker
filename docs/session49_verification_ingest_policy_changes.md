# Session 49 — the returned verification queue, and the three policy changes

**Date:** 2026-09-22 · **Quota:** zero RCJ calls · **Network:** none.

`data/reference/verification_queue_2.xlsx` came back with all **399** rows
answered — `verified_type`, `verified_by`, `verified_date` and `basis` on every
one, over **500** committed award rows, **382** organisations, **31** questions
and **21** states. This session ingests it, applies three policy changes that
came back with it, and re-derives the three hospital buckets.

**The workbook is read-only.** Nothing here writes to it and a test pins its
SHA-256 (`3479966e…`). It was moved from the repository root to
`data/reference/`, where the task says it lives and where every other reference
file lives; the bytes are unchanged.

---

## 0. The headline

```
                        ROWS        DOLLARS   STATES
NAMED_HOSPITAL   747 ->  865   599,533,409 -> 706,793,190   18 -> 19
POOL_NAMED_HOSPITALS       1    18,156,856  (NE, unchanged)
POOL_UNNAMED_HOSPITALS     1    50,008,264  (IL, unchanged)
```

**+118 rows and +$107,259,781.21 net** — 120 rows in at $110,294,573.21, two
out at $3,034,792. **Neither pool bucket moved**, because nothing in this pass
touched a pass-through award: every `_FLOW` question is still open.

**ARKANSAS IS NOW THE LARGEST NAMED-HOSPITAL STATE IN THIS REPOSITORY**,
ahead of Georgia for the first time — 9 rows / $21,792,688 → 18 /
$92,405,914. **And NORTH CAROLINA ENTERS THE PARTITION AT ALL**, for one row
and $0, which is why the state count moves 18 → 19.

| | rows before → after | dollars before → after |
|---|---|---:|
| **AR** | 9 → 18 | $21,792,688 → **$92,405,914** |
| **KS** | 21 → 30 | $35,721,277 → $52,239,500 |
| **MD** | 6 → 8 | $14,678,864 → $23,661,116 |
| **NE** | 41 → 54 | $6,990,996 → $12,606,594 |
| **WY** | 31 → 34 | $72,661,324 → $75,113,626 |
| **AL** | 60 → 62 | $66,133,019 → $68,323,619 |
| **OR** | 49 → 50 | $50,188,531 → $50,658,518 |
| **OK** | 20 → 26 | $1,079,506 → $1,314,903 |
| **MI** | 1 → 2 | $76,924 → $259,121 |
| **IA** | 152 → **216** | $0 → $0 |
| **NV** | 20 → **27** | $0 → $0 |
| **NC** | 0 → **1** | $0 → $0 |

**SEVENTY-TWO OF THE 120 ROWS THAT MOVED CARRY NO AMOUNT AT ALL.** Iowa (64),
Nevada (7) and North Carolina (1) publish named recipients and no
per-recipient dollar, so for them the ROW COUNT is the only hospital quantity
there is (Nevada's rule, session 26). A reader working down the dollar column
sees none of it: **Iowa alone gains 64 named-hospital award actions and
$0.**

---

## 1. What the answers rest on, and why that needed a policy change

| `basis_type` | rows | what it means |
|---|---:|---|
| `GENERAL_KNOWLEDGE` | **306** | a verifier's own knowledge; no citable source for the FORM |
| `ORG_WEBSITE` | 80 | the organisation's own site, filings or directory |
| `STATE_SOURCE` | 13 | the state's own award document states the form |

**NOT ONE OF THE 111 HOSPITAL ANSWERS RESTS ON A STATE SOURCE.** That is not a
weakness in the answers — it is the shape of the question. A state's award
document names a recipient and an amount; what KIND of organisation that
recipient is, is precisely what it does not say, which is why these rows sat on
§8's standing fallback for thirty sessions. Read against an unamended §0.4,
**306 of the 399 answers are violations**, and the eight-state form question
stays open forever.

**THE AWARD'S OWN URL DOES NOT MAKE AN ANSWER `STATE_SOURCE`, AND THAT IS THE
DESIGN.** 238 of the 399 bases carry a URL whose host IS the row's state
source. On nearly every one that URL locates the AWARD and says nothing about
the FORM. Calling those `STATE_SOURCE` would assert the state stated something
it never did — §0.4's failure, in the column added to prevent it. **The
workbook says so itself on 143 rows**: *"[Org type from general knowledge; URL
is the award source.]"*

**THE EVIDENCE CLASS IS CARRIED IN THE CONFIDENCE, NOT HIDDEN BY IT.**
`GENERAL_KNOWLEDGE` → `determination_confidence = LOW`; the other two →
`MEDIUM`. `HIGH` still requires a CCN match, so **nothing in this pass reaches
it** and Stage 5 remains what raises any of them. **A reader can therefore
subtract**: of the $110,294,573 that moved in, **$83,692,269 rests on
`ORG_WEBSITE` and $26,602,304 on `GENERAL_KNOWLEDGE`.**

### By verifier

| | rows | dollars |
|---|---:|---:|
| IN | 9 | $57,718,475 |
| MPB | 10 | $22,731,028 |
| policy 2 (§10.2's new row) | 10 | $17,853,500 |
| Claude, run by IN | 93 | $8,956,778 |

**The two human verifiers answered 62 rows between them and those 62 carry
$80.4M of the $110.3M.** They took the large, dollar-bearing names — Baxter
Health, Baptist Health, Mercy Fort Smith, Stormont Vail, TidalHealth, Meritus —
and 30 of MPB's 31 answers are `ORG_WEBSITE`. The 337 machine-assisted rows
are mostly the unpriced long tail: 66 of the 93 that moved carry no amount.

---

## 2. Policy 1 — §8 gains `OTHER`

Thirty-five answers name a form §8 does not carry and that is not a hospital: a
retail pharmacy, a PACE organisation, a non-emergency medical transport
company, a regional workforce investment board, a nursing home, a midwifery and
birth centre, a hospice's foundation, a mobile diagnostic-imaging company, an
opioid treatment programme, several for-profit behavioural health and therapy
LLCs.

**It is session 39's `MANAGED_CARE_ORGANIZATION` condition exactly — the source
states a form §8 does not carry — and it is answered the same way**, by adding
a code with its own note rather than widening an existing one. **It is not the
standing fallback**, which says the form is *undetermined*; using the fallback
for a form somebody determined asserts an ignorance the record no longer has,
which is the one thing `RECIPIENT_TYPE_INFERRED`'s own note forbids. **And it
is never a hospital type**, so like the MCO code it can only keep dollars OUT
of the hospital total — which is what makes it safe to add.

**A row carrying it must state the determined form in `determination_basis`.**
`OTHER` with nothing behind it is the fallback wearing a different name, and a
test drives that on every row.

---

## 3. Policy 2 — §10.2 gains the hospital-foundation row

**A foundation or affiliated arm of a *named* hospital or health system is
`HOSPITAL_OR_SYSTEM`**, and its flow is then §10.2's ordinary `DIRECT` row.
Applied **across every committed state file, not only the queue**, because a
foundation nobody queued is the same organisation as one somebody did.

**Seven organisations, ten award rows, $17,853,500.**

| state | organisation | parent | rows | $ |
|---|---|---|---:|---:|
| AR | St. Bernards Development Foundation | St. Bernards Medical Center | 2 | 14,551,090 |
| KS | Citizen's Foundation (Citizens Health) | Citizens Medical Center, Colby | 1 | 2,832,423 |
| OR | Sky Lakes Foundation (DBA Healthy Klamath) | Sky Lakes Medical Center | 1 | 469,987 |
| IA | MercyOne Genesis Foundation | MercyOne Genesis | 1 | — |
| IA | MercyOne North Iowa Foundation | MercyOne North Iowa | 3 | — |
| IA | MercyOneNorth Iowa Foundation | *(same, no space)* | 1 | — |
| NV | Incline Village Community Hospital Foundation | Incline Village CH | 1 | — |

**THE LOAD-BEARING WORD IS *NAMED*, AND IT IS WHAT STOPS THIS ROW SWALLOWING
THE ONE ABOVE IT.** `\bfoundation\b` matches **57 rows across the committed
files and only ten of them are the arm of a named hospital.** The refusals are
recorded in `VQ_FOUNDATION_REFUSALS` with a reason each:

- **New Hampshire's Foundation for Healthy Communities** is the state HOSPITAL
  ASSOCIATION's foundation, whose eligible class is hospitals **among others**
  (§0.3). It is §10.2's association row and its flow is settled. Reading it as
  a hospital's foundation would move **$66,547,394** on nothing at all. A test
  drives that counterfactual.
- **Nevada Rural Hospital Partners Foundation** is the same shape.
- **Talbot Hospice Foundation** (a hospice), **Cahaba Medical Care Foundation**
  (an FQHC), **Superior Health Foundation** (a conversion grantmaker),
  **William H. and Carrie Gottsche Foundation**, **MPhA Foundation**,
  **Pharmacy Foundation of Oregon**, **SD Foundation for Medical Care**,
  **Wolfe Street**, **Works Wonderfully** — the parent fails the test before
  the word *foundation* is read.

**TWO REFUSALS ARE WORTH READING BECAUSE THE RULE COULD HAVE REACHED THEM.**

- **Kansas publishes TWO Citizens spellings and they now classify
  differently.** *Citizen's Foundation (Citizens Health)* NAMES its parent and
  is `HOSPITAL_OR_SYSTEM`; *Citizens Foundation* does not, and the verifier
  said so — *"MOST LIKELY the foundation of Citizens Health (Colby) ... NOT
  CONFIRMED"* — so it stays `NONPROFIT_CBO`, **$146,476** apart. That is North
  Carolina's two spellings of UNC (session 38) in a state that PRICES its rows,
  and §2 forbids a machine resolving it. Queued as
  `KS_CITIZENS_FOUNDATION_TWO_SPELLINGS`.
- **Mississippi's Winston County Medical Foundation** — 4 rows, **$3,785,455**
  — is the one foundation-shaped name the rule could plausibly reach and did
  not. **Mississippi is not in the workbook**, nobody verified it, its name
  states a COUNTY rather than a hospital, and promoting it on this pipeline's
  own knowledge is the §0.4 failure. Queued as
  `MS_FOUNDATION_PARENT_NOT_STATED`.

---

## 4. Policy 3 — `basis_type`, and the §0.4 patch

`basis_type` is written to every re-typed row in every touched state file,
alongside `verified_by` and `verified_basis`, and to
`data/reference/verification_queue_2_answers.csv` for all 399 answers. It is in
`vocabularies.csv` with the full note. §0.4 is patched in all three governing
documents, insert-only, and the reviewer instructions gain a section telling a
reviewer when to use each class and that pasting the award's URL does not buy
`STATE_SOURCE`.

**`RECIPIENT_TYPE_INFERRED` comes off every row this pass determined**, because
its own note forbids it on a recipient whose form is stated.

---

## 5. The guardrails, and what each one cost

**MISSOURI'S HUB ANCHORS AND MAINE'S INVITED COHORT DID NOT ENTER ANY BUCKET,
AND STRUCTURALLY COULD NOT.** Both files were re-typed — the question asked WAS
their form, and Missouri's roster goes **14 → 19 hospitals of 27** — but
`mo_hub_anchors.csv` and `me_rhef_cohort.csv` carry **no `amount`, no
`flow_type` and no `distributed_to_hospital`**, are not in `STATE_FILES`, and
cannot reach `rhtp_hospital_dollar_partition()` at all. A test drives all three
absences rather than trusting them.

**ANSWERING A `_FLOW` ROW DID NOT SETTLE ITS FLOW.** Four queue rows ask a
§10.2 flow question and all four were answered with a TYPE:

| row | answer | flow after | $ |
|---|---|---|---:|
| `MI_MHA_FLOW` | NONPROFIT_CBO | `PASS_THROUGH_UNRESOLVED` / Unclear, unchanged | 8,625,000 |
| `AR_ARHP_CONSORTIUM_FLOW` | NONPROFIT_CBO | `NON_HOSPITAL` + `FLOW_UNRESOLVED_HOSPITAL_AFFILIATED`, unchanged | 18,833,521 |
| `ME_UNE_HOSPITAL_TO_HOME_FLOW` | UNIVERSITY_OR_AHC | unchanged | 0 |
| `NV_INCLINE_VILLAGE_FOUNDATION_FLOW` | NONPROFIT_CBO | see below | 0 |

Incline Village is the one exception and it is not an exception to this rule:
**policy 2, not the answer, re-typed it**, and a re-type to
`HOSPITAL_OR_SYSTEM` crosses §10.2's DIRECT test by construction. Nevada
publishes no amount, so it moves a row and $0.

**THE FLOW TEST WAS RE-RUN ON EVERY RE-TYPED ROW — AND ONLY WHERE THE RE-TYPE
CAN CHANGE ITS ANSWER.** §10.2's `DIRECT` row is the one branch keyed on
recipient identity; every other branch reads the description, which this pass
did not touch. So flow is re-derived exactly where a row crosses the
`HOSPITAL_OR_SYSTEM` boundary — 122 rows — and left alone elsewhere.

### The one held row, and the three that look identical to it

**FOUR RE-TYPED ROWS CARRIED `IN_KIND_BENEFIT` AND ALL FOUR HAVE THE SAME
GENERATED `determination_basis`:** *"the recipient is not a hospital and keeps
the funds, and the source names hospitals among the parties the funded work
serves."*

**THE FIRST HALF OF THAT SENTENCE IS EXACTLY WHAT THE VERIFICATION
OVERTURNS.** On three of them the in-kind coding is a CONSEQUENCE of the wrong
type rather than a reading of the source, so the flow test was re-run:

- KS **Stormont Vail Health** $5,465,969 → `DIRECT`
- KS **Greeley County Health Services** $1,541,906 → `DIRECT`
- MD **Meritus Health Center** $3,583,406 → `DIRECT`

**SALINA REGIONAL HEALTH CENTER IS THE FOURTH AND WAS HELD**, $932,310, because
session 31 read it INDIVIDUALLY: tightening `RHTP_PASS_THROUGH_MARKERS` into a
money-movement test moved exactly two committed rows in the whole repository
and Salina — KDHE's *"infrastructure to rural hospitals"* — was one of them.
That is a deliberate, recorded judgement about where the DOLLAR goes, not a
fallback.

**THE DISTINCTION IS REAL AND IT IS ALSO THIN, AND SAYING SO IS THE POINT.**
Four rows share one basis sentence and now have two different answers. It is
queued as **`VQ_INKIND_AFTER_RETYPE`, $10,591,281 against $932,310 held**, with
all three options priced, rather than buried in a commit.

---

## 6. IOWA: SIOUX CENTER HEALTH IS A HOSPITAL, AND THE CENTERS OF EXCELLENCE
POOL IS NOW HOSPITAL-ONLY

`PHTHORC26008` holds **ten** award actions. Eight were already
`HOSPITAL_OR_SYSTEM`; two carried §8's standing fallback and **both verify as
hospitals**:

- **Sioux Center Health** — *"nonprofit critical access hospital and health
  system"* (3 rows, across PHTHORC26008, 26010 and 26011)
- **Manning Regional Health Care Center** — *"critical access hospital"*

**So all ten Centers of Excellence recipients are hospitals.**

**WHAT THAT IS AND IS NOT.** It makes the pool's recipient set hospital-only,
which is a statement about **WHO**. **It attaches no dollar to anybody.** Iowa
publishes no per-recipient amount, and the **$50,000,000 is a TIER 2 figure**
from that notice's CMS footer, recorded in `ia_notice_footers.csv`. Dividing it
ten ways gives $5,000,000, which is nobody's published figure (§6.2); adding it
to a Tier 3 total is §0.2. **The finding is a row count and a class**, and a
test pins that `amount` is still empty on all 264 Iowa rows and that the
$50,000,000 is still `SOLICITATION`.

---

## 7. The one row nobody could answer

**`93 X 95 NV`** — an NVHA subrecipient string. Its `verified_type` came back
`UNKNOWN`, which is not a §8 value, and its basis reads *"Could not identify an
organization by this name."* **Nothing was written to it.** The row keeps §8's
standing fallback and its `RECIPIENT_TYPE_INFERRED` flag, `UNKNOWN` is recorded
in the answers CSV rather than in a state file, and it is queued as
`NV_UNIDENTIFIED_RECIPIENT`. $0 either way; it moves Nevada's named-hospital
count, which today is 27 of 73.

---

## 8. The review queue: 20 rows → 24, thirteen resolved

**RESOLVED (13):** `GHA_RECIPIENT_TYPE` (NONPROFIT_CBO — Georgia stops being
the outlier of three, $0 moved), `KS_`, `MD_`, `NE_`, `OK_`, `NV_`, `MI_`,
`AR_`, `MO_ANCHOR_FORM_NOT_STATED`, `NC_MIH_FORM_NOT_STATED`,
`IN_PROCUREMENT_VENDOR_TYPE`, `WY_TECH_FORM_NOT_STATED`,
`WY_EMS_LEAD_AGENCY_FORM`.

**Three of those resolved to the exact figure they predicted**: Maryland's
`$3,034,792` downward exposure came out as exactly those two FQHC rows;
Wyoming's `$752,302` and `$1,700,000` both landed on option (b).

**STILL OPEN (7 + 4 new):** the four `_FLOW` questions, the two
"is-it-an-award" questions (Missouri's anchors, Maine's cohort),
`NC_HUB_LEAD_FORM_NOT_IN_VOCABULARY` (Access East — answered with the fallback,
so unresolved, though `OTHER` is now an available option), and
`MS_RECIPIENT_FORM_NOT_STATED`, **now the largest open form question in the
repository at 96 rows / $56,022,017.62** now that Arkansas's is answered.

**NEW (4):** `VQ_INKIND_AFTER_RETYPE`, `MS_FOUNDATION_PARENT_NOT_STATED`,
`KS_CITIZENS_FOUNDATION_TWO_SPELLINGS`, `NV_UNIDENTIFIED_RECIPIENT`.

---

## 9. Re-running it

```
Rscript R/03ap_verification_queue_2.R --report   # what moves, before writing
Rscript R/03ap_verification_queue_2.R --apply    # writes the answers + the plan + the state files
Rscript R/03ap_verification_queue_2.R --totals   # the three buckets
```

`--apply` is idempotent: the plan is keyed on the CLASSIFIER's answer
(`name + recipient_type + determination_confidence`), so a second run matches
nothing and writes nothing.

---

## 10. What this pass cost the rest of the repository, and what it caught

**THE COMMITTED CSVs ARE STILL REPRODUCIBLE, BUT THE CLAIM CHANGED SHAPE.** Ten
tests assert that a state's committed CSV equals what its extractor builds from
the archive, and that invariant is what makes every figure here checkable. A
verification written straight onto the CSV breaks it silently: the next
`--build` would wipe 305 answers and nothing would say so.

So the verification is an **OVERLAY**. `vq_overlay()` applies
`verification_queue_2_changes.csv` — itself derived from a committed,
SHA-256-pinned workbook — on top of a freshly built table, and `vq_apply()`
calls it so the two cannot drift. The ten tests now assert **"the builder's
output WITH the committed overlay"**, which is still a complete reproduction
from committed inputs and is now an *explicit* dependency. The overlay is
idempotent.

**FOUR ASSERTIONS INSIDE STATE EXTRACTORS HAD TO CHANGE, AND ONLY IN ONE
DIRECTION.** Maryland, Nebraska, Oklahoma and Michigan each refuse to build
unless their review-queue row is `OPEN` — *"a disclosure nobody can find is not
a disclosure"*. The questions are now answered, so the guard accepts `OPEN` **or
`RESOLVED` with a non-empty resolution**. A `RESOLVED` row with nothing in it is
still refused, which is the invariant those guards were always about.

**FLORIDA'S ASSERT HAD TO BE SPLIT IN TWO, AND THE SPLIT IS THE INTERESTING
PART.** `rhtp_fl_assert()` encoded session 10's back-fit as a permanent rule:
exactly five rows differ from the owner's code, all of them `NONPROFIT_CBO`, all
flagged. The verification answered those same five recipients — three Nuvita
Health rows are `VENDOR_OR_CONTRACTOR`, Empowerq Health Care is
`PHYSICIAN_PRACTICE` — and the old rule read that as *"a row moved to a value
the back-fit table does not name"*, which was true and no longer a defect. A
moved row must now be **either** verified (it carries a `basis_type`) **or** a
session-10 back-fit row with its flag intact. A row that is neither is still
refused. **The five are still the five**; what changed is that they are also
answered.

**TWO DEFECTS THIS SESSION INTRODUCED AND ITS OWN CHECKS CAUGHT.**

1. **The first draft wrote this session's prose into `recipient_type_source`**,
   which on Florida holds the OWNER'S ORIGINAL §8 CODE — session 10 preserved
   *"UNCLASSIFIED"* there precisely so the back-fit stays auditable, and a test
   reads it as a bare code. `rhtp_fl_assert()` failed and the column is now left
   alone entirely: the verification's provenance lives in `basis_type`,
   `verified_by` and `verified_basis`, which are this session's columns.
2. **`readr::read_csv` trims whitespace on READ**, so writing the same table
   back silently rewrote every cell with a trailing space — **49 Wyoming `note`
   cells**, on rows this pass never planned to touch. Caught by diffing the
   committed files row by row against `HEAD` rather than by reading the output;
   fixed with `trim_ws = FALSE`. **After the fix: 22 files touched, and the
   ONLY rows whose original columns changed are the 487 in the plan.** That is
   sessions 23–25's CRLF lesson in a new costume, and it was caught the same
   way — by reading the diff.

**Tests: 5,827 assertions across 56 files, all passing and 1 self-skipping**
(was 5,577 across 55). `test_03ap_verification_queue_2.R` is new — 212
assertions, weighted towards the counterfactuals rather than the arithmetic.


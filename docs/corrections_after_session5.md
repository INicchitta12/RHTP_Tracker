# Corrections after Session 5 — §0.2a, §6.2, §6.4, §5.2

**2026-08-27 · zero RCJ quota consumed · no network calls**

Four corrections applied before Stage 2.5, plus the answer to the open question
about the missing allotment opportunity. Stage 2.5 was **not** started: the
registry worksheet has not come back verified, and the session prompt gates it
on that.

> **The spec was stale when this work started and landed on `main` part-way
> through.** The first pass was built from the session prompt's descriptions;
> commit `27b8e0c` then brought §0.2a, §0.3a, §7A and the revised
> §5.2/§6.2/§6.4/§11/§13 into the repo, and the work was **reconciled against
> the real text**. Three things changed as a result, all recorded below:
> `run_type` is `PRODUCTION`, not `PROD`; ` and ` and ` & ` are delimiters;
> and the entity patterns were extended so the §0.3a hospitals stop failing the
> §6.1 test.

---

## 1. §0.2a — Tier 1 published figures come from CMS, not RCJ

### The rule

`data/reference/cms_fy2026_allotments.csv` — 50 rows — is the **only** source of
a published Tier 1 figure. The 274 RCJ `STATE_ALLOTMENT` records are records
*about* the allotments; tiering them correctly is what keeps them out of Tier 3,
and it was never a claim that any of them carries a publishable number.

`rhtp_corroborate_state_allotments()` compares every Tier 1 record to the CMS
figure for its state and classifies the agreement:

| `tier1_agreement` | Test | Count |
|---|---|---:|
| `EXACT` | RCJ restates the CMS figure to the dollar | **35** |
| `ROUNDED` | Inside rule 3's 0.5% tolerance but not equal | **239** |
| `DISAGREES` | Outside rule 3's tolerance — a rule-3 defect, not a finding | **0** |
| `NO_AMOUNT` | Tier 1 with no amount — also impossible via rule 3 | **0** |

`DISAGREES` and `NO_AMOUNT` are reported, never dropped. Both would mean a
record reached Tier 1 by a route rule 3 did not sanction, and zero of them is
the check confirming rule 3 behaved.

### What it found, and why the rule exists

**Only 35 of 274 RCJ records restate the CMS figure exactly. 33 of 50 states
have no exact restatement anywhere in RCJ.**

```
AL AR CT DE HI IA IN KS KY MA MD MN MO MS MT NC ND NJ NM NY
OH OK OR PA RI SD TN TX VA WA WI WV WY
```

Publishing Tier 1 from the record table would give a wrong figure for
two-thirds of the country. The largest gap is Florida at **-$938,195** on four
separate records ($209,000,000 against $209,938,195) — small as a percentage,
and $938,195 is still most of a rural hospital's annual margin.

Per-state roll-up (`rhtp_tier1_state_summary()`), all 50 states:

| `rcj_tier1_status` | States |
|---|---:|
| `CMS_FIGURE_RESTATED` | 17 |
| `ROUNDED_ONLY` | 33 |
| `NO_RCJ_TIER1_RECORD` | 0 |
| `REVIEW_RULE_3` | 0 |

The roll-up keeps states with **no** Tier 1 record rather than dropping them —
see Nebraska in §5 below for why that row has to exist even when it is currently
empty.

Written to `data/interim/stage2_tier1_corroboration.{rds,csv}` and
`stage2_tier1_state_summary.{rds,csv}`, and reported on every Stage 2 run.

---

## 2. §6.2 — multi-recipient `awardeeName` fields

### The rule

One `awardeeName` field can name several recipients. `rhtp_split_recipient_field()`
splits it, and `rhtp_multi_recipient_candidates()` emits **one candidate per
fragment**, flagged `MULTI_RECIPIENT_FIELD` and routed to review.

**The amount is never divided.** RCJ publishes one figure for the field and says
nothing about how it splits. Apportioning it evenly would invent per-recipient
awards that no source states — the §0.1 failure this project exists to avoid. So
the candidate table has **no per-fragment amount column at all**; it carries
`amount_announced_field_total` and an `amount_note` saying what that is. There is
nothing there for a downstream sum to get wrong.

The parent record keeps its tier and its single row. §6.2 flags and routes to
review; it does not reassign — the same discipline as `SOURCE_IS_PLAN_NOT_AWARD`
and `UNPARSED_AWARD_CANDIDATE`.

### Delimiters — all four, per §6.2

§6.2 names `;`, `,`, ` and ` and ` & `, and gives the reason recall beats
precision here: *"a hospital buried inside a three-name string will not
exact-match the AHA Annual Survey and vanishes from the recipient list. Beebe is
the worked example."* Deliverable 1 is the named-hospital sheet. A false
positive costs a reviewer ten seconds; a false negative loses a hospital from
the primary product.

**The first pass got this wrong.** Built before the spec landed, it excluded
conjunctions and required two fragments to pass the §6.1 legal-entity test.
That second rule would have rejected `Beebe Healthcare, TidalHealth` outright —
neither name carries a corporate suffix — which is precisely the failure §0.3a
names. Both are fixed.

Four guards survive, each pinned to a live row, and none can hide a hospital:

| Guard | Rejects | Why it cannot lose a recipient |
|---|---|---|
| Delimiters inside parentheses do not split | `16 Strategically Located Rural Hospitals (unnamed, subrecipient group)` | The fragments it would create are junk, not names |
| A fragment opening with a **corporate suffix**, a **US state name alone or followed by a suffix/alias**, or an **alias marker** rejoins its predecessor | `Hospital District No. 1 of Dickinson County, Kansas, DBA Memorial Health System`; `St. Luke's Hospital of Bethlehem, Pennsylvania dba …, formerly Blue Mountain Hospital` | Removes fabricated fragments — "Kansas", "Inc." — never real ones |
| A fragment contained in another is one recipient named more fully (non-semicolon only) | `Oregon Health & Science University, Oregon Health & Science University - Department of Neurology` | Same institution twice |
| A **conjunction-only** split needs two fragments that pass the §6.1 legal-entity test **and name somebody** | `Oregon Health & Science University`; `Memorial Community Hospital and Health System`; `Alaska Hospital & Healthcare Association` | Applies only to conjunctions, never to `;` or `,` — so Beebe survives |

Two further refinements the corpus forced:

- **A conjunction is a delimiter only when no `;` or `,` is present.** If the
  author enumerated with punctuation, that *is* the enumeration, and splitting
  the conjunction as well shreds `Oregon Health & Science University` into
  "Oregon Health" and "Science University".
- **"Names somebody"** means the fragment contains at least one token that is
  not a generic organisation-type word. `Health System` and
  `Healthcare Association` are the tails of single organisation names, not
  second recipients.

### The entity patterns had to grow first

`Beebe Healthcare`, `TidalHealth` and `Nemours Children's Health` — the three
hospitals §0.3a names as having been coded away — **all failed the §6.1
legal-entity test.** None carries a corporate suffix or the token `hospital`.
Any guard keyed on that test would have dropped them silently.

§6.1's own instruction settles the fix: *"Extend rule 1 before ever extending
rule 2: a generalizable marker beats another special case."* Two markers added
to `legal_entity_patterns.csv`:

- `\bhealthcare\b|\bhealth care\b|\b\w+health\b` — catches `Beebe
  Healthcare` and `TidalHealth`, and deliberately **not** a bare `Health`, so
  `Oregon Health` still fails and the ` & ` in `Oregon Health & Science
  University` is not read as a delimiter.
- `\bchildren'?s?\s+(health|healthcare|hospital)` — `Nemours Children's
  Health`, `Children's Healthcare of Atlanta`, `Children's Health Dallas`. A
  large class of hospitals with no `hospital` token in the name.

This also lifted §6.4 mining from **38 candidates to 43 across 21 states** — the
same blindness was costing us mined hospitals too.

### Result: 199 candidates from 41 parent records, 8 states

| Delimiter | Parents |
|---|---:|
| `COMMA` | 36 |
| `SEMICOLON` | 3 |
| `CONJUNCTION` | 2 |

The rows that matter most:

- **The NH $1,898,965,390 row** — the one the §6.2 allotment ceiling caught at
  9.3× the state's entire allotment — is three managed care organisations
  sharing a field. Now three reviewable candidates. (The same three appear
  twice, once at $38.8M and once at $1.9B; which figure is right is a review
  question, and neither is publishable.)
- **The Oregon $10,000,000 row** names **102 clinics**. One unusable record
  becomes 102 reviewable candidates, with the $10M attached undivided to every
  one.

97 of the 199 fragments pass the §6.1 legal-entity test on their own;
`passes_legal_entity_test` is recorded per fragment so a reviewer can sort by
it. It is **not** a filter — that is the whole lesson of the first pass.

Not every split is right, and §6.2 says so outright: *"the split is a guess
about the state's formatting, not a fact."* `University of Nevada, Reno General
Surgery Residency Program` splits into two, and a reviewer will dismiss it in
seconds. That is the intended trade.

### Effect on the record table

41 records gained `MULTI_RECIPIENT_FIELD`, so clean Tier 3 moves
**1,016 → 995 records** and the clean announced total from **$2,027,946,582 →
$1,762,042,744**. That $265.9M did not disappear — it moved from "clean" to
"flagged for review", which is where a figure whose recipient list is
unresolved belongs. It is also $265.9M that would have been reported against
recipient lists nobody had read.

---

## 3. §6.4 — `NO_DATA` is now `NO_RCJ_DATA`

The old label read as a claim about the state. It is a claim about RCJ's
coverage. The seven states it applies to — **AR, KY, MA, MN, NY, SC, WY** — each
hold a CMS allotment between $147M and $281M. "No data" would have been read off
a Coverage sheet as "this state has awarded nothing", which is false and
unsupported.

`NO_RCJ_DATA` says what is actually known: RCJ surfaced nothing award-shaped —
no parsed `/awards` row and no minable `/documents` record.

FL, NC, NJ and TN keep `UNPARSED_DATA_EXISTS`, which they already had.

`coverage_status` was also missing from `vocabularies.csv` entirely — an
omission from Session 5, when the column was introduced. All four values are now
in the vocabulary, so §13.6 covers it.

---

## 4. §5.2 — `run_type` on both manifests

A manifest that cannot tell a real pull from a development iteration invites
someone to read a throwaway run as the build of record. `run_type` is now in both
pinned schemas (§13.20):

- `PRODUCTION` — the run whose output was committed as the build of record.
- `DEV` — an intermediate iteration, superseded by a later run.

§5.2 also makes the manifest **append-only**: development runs are filtered,
never deleted.

**Backfill.** `logs/pull_manifest.csv`: all 67 rows `PRODUCTION` — the Session 3
national pull was the real thing. `logs/normalize_manifest.csv`: Session 4's
3 rows `PRODUCTION`; **Session 5's four runs (12 rows) `DEV`**, as instructed. That
labelling is now accurate rather than merely instructed: this session's run
supersedes all four and is the `PRODUCTION` build on disk.

An unknown value is refused — and so is an abbreviation. `match.arg()` does
partial matching, so it would have silently accepted `PROD` as `PRODUCTION` and
written the misspelling into an audit log; `rhtp_check_run_type()` refuses
anything not spelled exactly.

Threaded through both stages rather than hardcoded — `Rscript R/02_normalize.R
--run --dev` logs an iteration as `DEV`, and `rhtp_run_national_pull(run_type =)`
does the same for Stage 1. Stage 1 carries it in run state, because manifest rows
are written deep inside `rhtp_perform()`, which has no business knowing why the
run was started. An unknown value is refused, not written.

`n_multi_recipient_candidates` was added to the normalize manifest at the same
time. The historical rows carry `NA`, not `0`: the §6.2 split did not exist for
those runs, so no count was computed, and `0` would claim a measured absence.

---

## 5. The state missing from the 49 `/opportunities` allotment rows

**Nebraska. The record exists, is correctly titled, and carries the wrong
number.**

```
id        d4588011-bf5b-4f9a-ab2f-a4febbfb74eb
title     Nebraska Federal RHTP Award (FY2026-FY2030)
type      AWARD
status    CLOSED
issuing   Centers for Medicare & Medicaid Services (CMS)
summary   Federal RHTP state award baseline derived from CMS 50-state spotlights.
budgetMin NULL
budgetMax 100000
sourceUrl https://www.cms.gov/files/document/rural-health-transformation-50-state-spotlights.pdf
```

Same title pattern as the other 49, same type, same CMS source document. It is
not Tier 1 because **RCJ published `budgetMax: 100000`** — $100,000 — against
Nebraska's actual CMS allotment of **$218,529,075**. RCJ's figure is short by a
factor of about 2,185.

So §6.1 rule 3 could not match it, and rule 4 tiered it `SOLICITATION` on the
strength of carrying an amount at all. That is the rules working: a record whose
amount does not match the state's allotment is not evidence of the state's
allotment.

**This is the §0.2a case in a single row.** Had Tier 1 been published from RCJ
records, Nebraska would have appeared as a $100,000 state — an error of
$218,429,075, and the kind that ends an analysis's credibility in one screenshot.
It is also why `rhtp_tier1_state_summary()` keeps a row for every state including
those with no Tier 1 record: a roll-up over Tier 1 records alone would have shown
Nebraska as absent rather than as wrong.

Nebraska still has Tier 1 records from `/documents`, so its
`rcj_tier1_status` is `ROUNDED_ONLY`, not `NO_RCJ_TIER1_RECORD`. The gap is
specific to the `/opportunities` allotment row.

---

## 6. Tests

`Rscript tests/run_tests.R` — **390 assertions, all passing, zero quota**
(44 + 276 + 70), up from 316.

74 new assertions:

- **§0.2a** — each `tier1_agreement` value from a fixture; only Tier 1 records
  corroborated; an absent anchor returns empty rather than a pass; the roll-up
  keeps states with no Tier 1 record; and a check against the live table that no
  record sits outside rule 3's tolerance.
- **§6.2** — the NH row and the Delaware row from §6.2 itself; `Beebe Healthcare
  and TidalHealth` splitting on a conjunction; punctuation beating a conjunction
  when both are present; each guard pinned to the live row that motivated it;
  the semicolon/containment asymmetry pinned to Oregon's Evergreen clinics; the
  amount carried whole with no per-fragment column to sum; the parent's tier
  unchanged.
- **§0.3a** — `Beebe Healthcare`, `TidalHealth` and `Nemours Children's Health`
  asserted to pass the §6.1 legal-entity test, and `Oregon Health` asserted to
  fail it. If the first three ever regress, every §6.2 split and §6.4 mining
  pass that would surface them is rejected before a human sees them.
- **§6.4** — `NO_RCJ_DATA` asserted, `NO_DATA` asserted absent.
- **§5.2** — `run_type` pinned in both schemas, the two vocabularies asserted
  equal so the duplication cannot drift, an unknown value refused, an
  abbreviation refused, and every row of both committed manifests validated.

## 7. Files changed

**Code**
- `R/01_retrieve_rcj.R` — `run_type` in the pinned schema, in run state, and on
  the orchestrator.
- `R/02_normalize.R` — §0.2a corroboration, §6.2 splitter and candidates, §6.4
  recode, §5.2 `run_type`, and the reporting for all of it.

**Reference**
- `data/reference/vocabularies.csv` — `MULTI_RECIPIENT_FIELD`, `tier1_agreement`,
  `rcj_tier1_status`, `run_type`, `delimiter`, the §8-listed `UNPARSED_DATA_EXISTS`
  and `NO_RCJ_DATA`, and the four `coverage_status` values that should have been
  added in Session 5.
- `data/reference/legal_entity_patterns.csv` — the two §0.3a provider markers.

**Root**
- `reviewer-coding-instructions.md` — one section appended (see §9). The
  document is the owner's, already in the repo at `f8a3ab8`.

**Interim (committed)**
- `stage2_multi_recipient_candidates.{rds,csv}` — 117 rows
- `stage2_tier1_corroboration.{rds,csv}` — 274 rows
- `stage2_tier1_state_summary.{rds,csv}` — 50 rows
- `stage2_record_table.rds`, `stage2_mining_coverage.{rds,csv}` — re-run

**Logs**
- `logs/pull_manifest.csv`, `logs/normalize_manifest.csv` — `run_type` added and
  backfilled.

---

## 8. What is still open

1. **The registry is not verified**, so Stage 2.5 (§7A) did not start. 151
   candidates, all 50 states, still `UNVERIFIED`. §7A.2 also wants the budget
   narrative URL captured while a verifier is on each state's pages.
2. **The §9.11 findings are not committed.** Sequencing item 5 records the test
   as complete and says it drove the §0.1 inversion and the §9.3 split; §0.3a
   quotes its result. The findings document itself is not in the repo, so the
   eleven verified Delaware records cannot be re-read here.
3. **QA assertions §13.24–28 are specified but `qa_assertions.R` is not built.**
   Three of them are already satisfied by this work and only need asserting:
   §13.25 is `rhtp_corroborate_state_allotments()`, §13.27 is the
   change-detection fix from Session 5, and §13.24 is a Stage 6 concern.
   §13.26 (no `MULTI_RECIPIENT_FIELD` row carries an auto-resolved hospital
   match) lands in Stage 5.

---

## 9. `reviewer-coding-instructions.md` — one section appended

**Sequencing item 6 was already done.** `reviewer-coding-instructions.md` has
been in the repo since `f8a3ab8`, written by the owner, with the real Delaware
worked examples this session could not have produced — Beebe Medical Center's
diabetes pilot, Thomas Jefferson University, Delaware Health Information
Network, and the `"Not identified"` VBC row. It also carries the
`recipient_confirmed` / `amount_confirmed` split and the §9.12 URL rule.

*This session briefly overwrote it before noticing. The original is restored
verbatim; nothing of it was changed.*

One section was **appended**, because this session's code emits a flag that did
not exist when the document was written: **"One field naming several
recipients."** It tells a reviewer that `MULTI_RECIPIENT_FIELD` rows carry one
candidate per fragment, that the split is a guess about the state's formatting
rather than a fact and must be checked against the source, and that
`amount_announced_field_total` is the field's figure and never that recipient's
award — the same rule the document already states for initiative budgets.

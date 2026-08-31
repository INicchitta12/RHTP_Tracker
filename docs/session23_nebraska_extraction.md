# Session 23 — Nebraska: three notices of award, and RCJ's title read off the wrong page

**Date:** 2026-08-31
**Quota:** zero RCJ calls. 21 fetches to `dhhs.ne.gov`, throttled per §9.5.
**Deliverable:** `data/reference/ne_year1_awardees.csv` (78 rows),
`NE_year1_awardees.xlsx`, `data/reference/ne_rcj_candidate_disposition.csv`,
`R/03r_ne_year1_awardees.R`, `tests/testthat/test_03r_ne_year1_awardees.R`.

---

## 1. What Nebraska publishes

Nebraska led `state_trigger_queue.csv` after Maryland was worked out: 39 RCJ
Tier 3 candidates, 35 distinct awardees, a **$218,529,075** allotment, no CMS
press release, and no session had ever looked at it.

DHHS publishes **three signed "Public Notice of Award" PDFs**, linked from its
own Rural Health Transformation page:

| Initiative | Notice dated | Awards | Total |
|---|---|---:|---:|
| 3.3 Rural Health Care Workforce Incentive & Sustainability | 2026-07-15 | 9 | $1,852,376.73 |
| 4.4a Chronic Disease Navigation and Education | 2026-05-06 | 24 | $6,594,460.94 |
| 4.4b Remote Patient Monitoring in Facilities and at Home | 2026-06-10 | 24 | $27,690,777.23 |
| | | **57** | **$36,137,614.90** |

16.5% of the allotment.

**These are AWARDS, not offers and not intents**, and that is a stronger footing
than any state extracted since Georgia. Each notice says *"The following have
been selected for award for the Request for Application which closed
<date>"* — §7's `NOTICE_OF_AWARD` on its own terms. Oregon publishes intents,
Alaska publishes intents, Maryland publishes offers. Nebraska publishes awards.

---

## 2. The §6.2 provenance test, which Nebraska nearly failed in a new way

Nebraska was flagged in the task as a state that runs its own rural health
programmes, and it does — but the hazard turned out to be sharper than that.
**DHHS's Office of Procurement and Grants publishes "Intent to Award" notices
for many grant series, RHTP and otherwise, in one document library and off one
page.** Two were read directly rather than assumed about:

- **RFA 5965 — SNAP Employment and Training.** Intents to award running
  **January 2025 through June 2026**, i.e. straddling the NOA date. This is the
  dangerous one, because **RHTP Initiative 3.3 is itself a SNAP E&T start-up
  programme** (its RFA is literally `RHTP-3.3 SNAP ET RFA.pdf`). Two series,
  one subject, one publisher, overlapping dates.
- **RFA R6251 — 2026 Non-Embryonic Stem Cell Research Grants.** Nothing to do
  with rural health at all.

So *"DHHS published an Intent to Award"* is not evidence of RHTP. What **is**
evidence sits on all three award notices and on the programme page: the CMS
financial-assistance footer, naming the awarding agency and the exact award —

> supported by … the Centers for Medicare & Medicaid Services (CMS) … as part
> of a financial assistance award totaling **$218,529,075.01** with 100 percent
> funded by CMS/US HHS

— which matches `cms_fy2026_allotments.csv` to the dollar. `ne_assert_rhtp_funded()`
requires it on all four documents every run.

**And the dates.** Every RFA behind these awards closed *after* the 2025-12-29
Notice of Award: 2026-03-27, -04-01, -04-24, -05-01, -06-01 and -07-10, read out
of the archived PDFs rather than typed. Texas's `HHS0015180` closed 2025-04-24,
eight months before its state had the money; Nebraska is the opposite.

**The negative control is archived beside the positives.** `RFA 4533 NHAP Legal
Services` — the Nebraska Homeless Assistance Program's legal-services
solicitation — says in its own words that DHHS is *"awarding **state funds** to
an eligible and qualified agency"*, and closed **2025-05-21**, seven months
before Nebraska had the federal money. That is Texas's failure mode in
Nebraska, and it is what disposes of RCJ's Nebraska Lawyers Foundation row.
`ne_assert_non_rhtp_control()` pins both halves and fails if the document ever
starts mentioning RHTP.

### 2a. The automated sweep caught zero Nebraska rows, and it was right to

`provenance_sweep_by_state.csv` reports Nebraska: **39 candidates, 0 caught**.
One of those 39 is nonetheless not RHTP.

This is not a defect in the sweep so much as a measured limit on it, and it is
worth stating plainly because the clean line is easy to over-read. The sweep's
provenance text is the **source-document title plus the solicitation number**.
RCJ's title for that row is the bare string `"Intent to Award"` — no programme
name, no identifier — and the solicitation number is empty. There is nothing for
a source-scoped registry to match. The date test cannot run either: RCJ carries
no date for it, and **15 of Nebraska's 39 candidates are undatable**.

The row was found by hand, by checking the name against the state's three
notices of award and finding it on none of them. `NE-RFA4533` is now in
`non_rhtp_state_programs.csv` anyway — it matches nothing today, and the entry
says so and says why, so that the *next* Nebraska candidate whose title does
name NHAP is caught by machine rather than by luck.

**Nebraska's clean sweep line was a statement about the registry's coverage,
not about Nebraska.** That is the same sentence `trigger_source = NEITHER`
needed in session 16, in a different file.

---

## 3. §0.1 — RCJ read the document title off the wrong page

RCJ's 39 Nebraska candidates decompose **exactly**, and
`ne_assert_rcj_disposition()` requires the arithmetic to close to the cent:

| Rows | Amount | What it is |
|---:|---:|---|
| 24 | $6,594,460.94 | Initiative **4.4a's award list** — titled by RCJ *"Organizations Submitted Applications for RHTP RFA Closing March 27, 2026"* |
| 9 | $1,852,376.73 | Initiative 3.3's award list. Correctly titled. |
| 5 | $5 | 3.3 intent-to-award rows, $1 placeholders, duplicating five of the nine above |
| 1 | $1 | Nebraska Lawyers Foundation — **not RHTP** (§2) |
| **39** | **$8,446,843.67** | = `rcj_state_survey.csv`'s own figure |

**The 24 are the finding.** Nebraska's 4.4a notice carries the award table on
page 1 and, on pages 2–3, a *separate* roster headed *"The following
organizations submitted applications for the aforementioned Request for
Application"* — about 115 names, most of which were **not** awarded. RCJ took
the **amounts from page 1** and the **title from page 2**. That is the
page-text-as-title defect §0.1 names, and here it cuts in a direction no
previous state's did:

- **Believed, RCJ's title causes a DEFLATION** — twenty-four real hospital and
  clinic awards, $6.6M, discarded as mere applications. Every §0.1 defect this
  project has met so far inflated.
- **The opposite mistake is available in the same document and is worse** —
  treating pages 2–3 as recipients invents ~115 awards out of an applicant
  list, which is §0.3 exactly.

`ne_assert_applicants_not_awarded()` holds both edges: the applicant section
must still be present (it is the evidence for this finding), and no
applicant-only name may reach a 4.4a award row. Three organisations a reader
would plausibly expect to see — **Bryan Health, Nebraska Medicine, Cherry County
Hospital** — are on the applicant roster and on no award table, and are pinned
out of the priced rows by name.

### 3a. And RCJ holds none of Initiative 4.4b

**$27,690,777.23 — more than three quarters of everything Nebraska has
published, including the single largest award in the state — is absent from the
aggregator entirely.** Two 4.4b awardees share a *name* with an RCJ row, but
those RCJ rows are 4.4a awards and the amounts differ; no `(name, amount)` pair
matches.

That is Kansas's lesson again — **read the programme page's link list, not its
prose** — and it is why the positive control below is the load-bearing part of
the extractor rather than a formality.

---

## 4. The positive control

Nebraska is running **nineteen initiative rows** on its RFA timeline table and
has published awardees for **three**. On its own *"we found no other roster"* is
indistinguishable from *"we looked for the wrong string"*, so the check is not
that strings are absent: the table's last column carries an **"Awardees" link**
exactly where a roster exists, and `ne_assert_award_index()` asserts all three
present and pointing at the PDFs this file parses.

It is a tripwire in **both** directions — it fails if a known link disappears
(a redesign that renamed them would otherwise turn every future run silently
green) and fails if a **fourth** appears, because at that point Nebraska has
published a pool the file does not carry. Both branches are tested by feeding
the assertion a modified page and requiring failure.

The link list was corroborated independently by probing the thirteen other
initiative slots at the same URL shape (`RHTP-Public-Notice-of-Award-<n>.pdf`):
**all thirteen 404, all three known ones 200.**

---

## 5. The Nebraska High Value Network, and the one row that needed a new code

Initiative 4.4b's largest award is **$18,156,856.12 to the Nebraska High Value
Network**, which the notice marks with a dagger and explains:

> Nebraska High Value Network is a collaborative network. The list of individual
> hospitals receiving funding as of the time of this notice follows.

**Twenty-one hospitals are then named.** §10.2's `PASS_THROUGH_DESIGNATED` test
is met on both clauses — the award **is** made, and the source **names**
hospital subrecipients — so `distributed_to_hospital = Yes` with
`intermediary_name` populated.

**But the existing `hospital_attribution` vocabulary could not describe it
honestly**, and this is the session's one deliberate addition to §8:

- `NAMED_HOSPITAL` is **false**: DHHS publishes no per-hospital split, so nobody
  can say what any one of the twenty-one received, and §6.2 forbids dividing.
- `POOL_UNNAMED_HOSPITALS` — Illinois/ICAHN's code — is **also false, and in the
  more damaging direction**: it asserts that no hospital is named when
  twenty-one are, on the record, in the award document.

So **`POOL_NAMED_HOSPITALS`** was added to `vocabularies.csv` with full notes,
the fifth such deliberate addition this project has made. It is a **third
bucket** in `rhtp_hospital_dollar_partition()` and is never added to either
other. `rhtp_hospital_total()` now also **refuses to run at all** if the
partition ever returns a bucket it does not name — because a new attribution
code silently missing from the one summary a reader sees is precisely the
failure that function exists to prevent.

**The twenty-one hospitals are carried as their own rows with an empty
`amount`** — Georgia's device for its seven un-priced AHEAD hospitals. They can
be counted as hospitals without double-counting a dollar, and a test asserts
they stay un-priced: if one ever gains an amount, Nebraska inflates by up to
$18.2M.

**Jefferson Community Health and Life is on that roster *and* holds its own
$446,741.33 direct 4.4b award**, and DHHS says so itself, in a parenthesis:
*"will not be awarded over the maximum allowable amount, as they were awarded
individually"*. The state has already told us not to add the two.
`ne_assert_nhvn()` pins the overlap rather than silently de-duplicating it, and
DHHS's warning is carried on the row.

---

## 6. Where the hospital figure is soft — Kansas's shape, a third time

```
NAMED_HOSPITAL        :  6,990,996.01   41 rows (20 priced awards + 21 NHVN members)
POOL_NAMED_HOSPITALS  : 18,156,856.12    1 row  (NHVN; 21 hospitals named, no split)
POOL_UNNAMED_HOSPITALS:          0
```

**DHHS publishes no organisation-type column** — nothing of the kind Oregon and
Alaska both have. Outside the twenty-one NHVN member rows, every
`recipient_type` is derived from the recipient's own **name**, and **30 of the
57 award rows, $9,411,695.59, take §8's standing fallback** — larger than the
$6,990,996.01 named-hospital floor beside it, exactly as in Kansas and Maryland.

It runs **mainly upward**. These read as hospitals to anyone who knows Nebraska
and are **uncounted today**: CHI St. Mary's ($908,475.54), CHI Health Schuyler
($711,629.63), Faith Health ($578,673.70), Mary Lanning Healthcare
($460,239.40), Jefferson Community Health & Life ($446,741.33), CHI Good
Samaritan/CHI St. Francis ($430,601.57), CHI Health Plainview ($355,311.03),
Methodist Fremont Health ($334,176.13), Memorial Health Care System
($339,999.92), Boone County Health Center ($340,000.00), Gothenburg Health
($309,749.28), Syracuse Area Health ($200,000.00).

**Nothing was promoted (§0.4)**, and this time there was a live temptation to.

### 6a. The one place form is STATED, and why it was not extended

The 4.4b footnote is the only organisational-type statement Nebraska publishes:
DHHS's own sentence calls those twenty-one organisations *"individual
hospitals"*. On **those rows**, in **that document**, the typing is
source-stated, not derived — so they carry `recipient_type_source =
STATED_IN_SOURCE` and `HOSPITAL_OR_SYSTEM` at `MEDIUM` (§7 reserves `HIGH` for a
CCN match, which this project still cannot do).

It was **not** extended to the direct-award rows, and the reason is §2's
standing instruction rather than a judgement call: *never let a fuzzy hospital
match auto-resolve.* Four of the thirty appear on the roster under a
near-identical name, and two of the four differ by **one character across two
documents**:

| Award table | 4.4b roster |
|---|---|
| Boone County Health Center | Boone County Health Center |
| Gothenburg Health | Gothenburg Health |
| Jefferson Community Health **&** Life | Jefferson Community Health **and** Life |
| Memorial Health Care **System** | Memorial Health Care **Systems** |

That is precisely the match a human is supposed to make. `rhtp_ne_norm()`
deliberately does **not** collapse `&`/`and` or `System`/`Systems`, and a test
asserts all four names stay un-promoted.

The question is queued as **`NE_RECIPIENT_FORM_NOT_STATED`** in
`classification_review_queue.csv`, **with the 4.4b roster named in it as the
evidence a reviewer should start from** — the point being to surface the
evidence without auto-resolving it.
`ne_assert_form_not_stated_queued()` asserts the row, its dollars and its
options every run, and fails if the uncertainty ever stops exceeding the figure
beside it.

**Deliberately excluded from that $9.4M** is NHVN's own row: it also carries
§8's fallback for its corporate form, but its dollars are already attributed to
hospitals under `POOL_NAMED_HOSPITALS` on DHHS's own sentence, whichever way its
form is settled. Folding it in would have trebled the stated uncertainty by
counting money the source has already placed.

---

## 7. The Nebraska Hospital Association does not appear, and that is a finding

NHA is named as a subrecipient in Nebraska's CMS project abstract and sits in
`abstract_named_organizations.csv` as `CANDIDATE_ONLY` (§4.1). **It is on none
of the three notices of award**, so §10.2's hospital-association branch and its
`IN_KIND_BENEFIT` carve-out never fire on any Nebraska row, and no association
dollar enters any total.

`ne_assert_nha_absent()` holds that and **fails the day DHHS awards NHA**, with
an error that says what to do: apply §10.2 by hand, and decide it on what the
document says the money *does*, not on what the organisation *is*. The assertion
is positive-controlled by feeding it a faked NHA row and requiring failure.

**§0.3a also fires twice on the timeline table and neither is an award row.**
Initiative 1.1 School Kitchen Modernization and 1.3 Farm-to-School are both
released through *"Interagency agreement with the Department of Education"* —
§10.2's own worked `NON_HOSPITAL` example, judge the recipient not the activity.
Neither has published an awardee list, so neither is in the file at all.

---

## 8. Housekeeping

- **`vocabularies.csv` gained `POOL_NAMED_HOSPITALS`** (§5 above). The file is
  CRLF; a first edit wrote it back as LF and turned a one-line addition into a
  166-line rewrite. Caught before commit and restored — §2.1's failure mode
  wearing a different hat, and the reason the diff is checked and not just the
  content.
- **`rcj_state_survey.csv` and `state_trigger_queue.csv` were rebuilt**, not
  hand-edited: `SURVEY_EXTRACTED_STATES` in `R/03k` gained `"NE"` and both
  tables were regenerated. **Indiana now leads the queue** (37 candidates / 28
  distinct awardees), then OK 35/25, NV 34/34, MI 31/31, MO 29/29.
- **`test_state_union.R` now combines twelve state files.** Two of its
  invariants had to be widened, both because they encoded assumptions Nebraska
  is the first state to break: the expected state list, and the rule that a
  pass-through `Yes` must be `POOL_UNNAMED_HOSPITALS`. The real invariant is
  that a pass-through `Yes` lands in a **pool** bucket and never in
  `NAMED_HOSPITAL`; that is now what it says, plus a check that the three
  buckets stay disjoint.
- **Tests: 2,292 assertions, all passing** (was 2,117), 1 self-skip.

---

## 9. What is left open

1. **`NE_RECIPIENT_FORM_NOT_STATED`** — 30 rows, $9,411,695.59, resolved by the
   CCN match (open blocker 5). Nebraska adds **41 hospital rows** to that
   queue, 21 of them with addresses (the NHVN roster prints a city per
   hospital), which makes them unusually matchable.
2. **Sixteen more Nebraska initiative rows have no published roster.** The
   timeline table gives a reason for each — still open, "Early May", "Jun-26",
   an interagency agreement — and the positive control fails the day a fourth
   Awardees link appears. Nebraska is a **rolling publisher** in the same sense
   Alaska is, though not on Alaska's weekly overwrite; Initiative 2.5 (CAH→REH
   conversion) and 4.2b (HAI prevention in hospitals and LTC) are the two
   unawarded pools most likely to move hospital dollars when they land.
3. **The §6.2 sweep's undatable half.** 15 of Nebraska's 39 candidates carry no
   date anybody asserted, and 1,228 of 1,366 nationally. §2a above is what that
   costs in practice, on a real row, for the first time.

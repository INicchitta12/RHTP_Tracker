# Session 17 — Oregon: four documents, seven pools, and the block that was not hospitals

**Date:** 2026-08-28 · **RCJ quota:** zero · **Network:** Full (§9.5 conduct applied)
**Calls:** 8 to `www.oregon.gov`, 1 to `content.govdelivery.com`, all throttled
to one request per host every 4 seconds under an AHA-identifying user agent.

---

## What Oregon publishes

More than any state in this project so far, and through four documents rather
than one, because OHA runs **seven award pools** and publishes each differently.

| Pool | Year 1 | Recipients | Where OHA publishes it |
|---|---:|---|---|
| Catalyst Awards | $80,114,365 | 103 projects / 85 orgs | **machine-readable xlsx** |
| Transformation — hospitals | $34,998,000 | **35 named hospitals** | GovDelivery bulletin |
| Transformation — RHCs | $9,900,000 | 99 named clinics | GovDelivery bulletin |
| Immediate Impact Wave 1 | $5,192,000 | 12 projects | awards page prose |
| Immediate Impact Wave 2 | $11,294,644 | **21 of 33** projects | awards page prose |
| Tribal Initiative | $21,700,000 | 9 Tribes, **unnamed** | news release only |
| Transformation — LPHAs | $5,000,000 | 33 authorities, **unnamed** | news release only |

**278 award actions.** `data/reference/or_year1_awardees.csv` is the source of
record; `OR_year1_awardees.xlsx` is a render whose first sheet is the warning.

---

## The correction: those 99 × $100,000 are clinics, not hospitals

The RCJ survey shows **99 awards of exactly $100,000 to 99 distinct
organisations**, which reads as a large, clean, uniform hospital block. It is
not one, and OHA's own bulletin is what says so — in two separate tables in one
document:

- **Rural Health Clinics (RHCs):** 99 rows, a standardised **$100,000** each,
  against a stated **$10M** pool. The names are clinics — *Aumsville Medical
  Clinic*, *Dunes Family Health Care*, *Good Shepherd Medical Group RHC*.
- **Rural Hospitals:** a **different** table, tiered by bed count — **32** at
  **$963,000** (≤50 beds) and **3** at **$1,394,000** (>50 beds), OHA's own
  **Grand Total $34,998,000**.

So Oregon's hospital block is real, clean and large — **35 hospitals,
$34,998,000** — and it is not the block the aggregator pointed at. §0.1 in one
paragraph: RCJ told us where to look and got the class wrong.

**Two RCJ defects sit in the same 136 records**, both of the kind §0.1 lists:
the bulletin's own title (*"Oregon Health Authority Announces Funding for Rural
Hospitals"*) is captured as an **awardee at $963,000**, and its **"Grand Total"**
row is captured as an **awardee at $34,998,000**. Neither is a recipient.
Nothing in the Oregon file comes from RCJ, and four assertions plus a test now
hold the correction so it survives a re-run by someone who has not read §0.1.

---

## Three closures, none of them arranged

1. **The seven pools total $175,312,365.** OHA's 2026-07-07 release states
   Oregon *"has so far awarded about $175.3 million"*. The seven figures come
   from **three different documents** and nobody arranged them to agree.
2. **The hospital table sums to its own Grand Total exactly**, and the bed-count
   rule the bulletin *states* (≤50 → $963,000) agrees with the amounts it
   *prints* on all 35 rows. Two independent checks on one table.
3. **The RHC pool is short by exactly one clinic.** OHA's April release says
   *"Oregon currently has 100 certified rural health clinics"*; the bulletin
   lists 99 and closes *"Additional clinics may receive their RHC certificate
   from CMS and become eligible for Transformation Awards."* $100,000 unfilled,
   and nothing was filled in for the 100th.

Against the CMS allotment of **$197,271,578**, the residual is **$21,959,213
(11.13%)**.

---

## Not one Oregon award in this file is executed

Every pool says so, in its own words, and this is the caveat that must not be
dropped from any summary:

- Immediate Impact: amounts come from recipients' **Notice of Intent to Award**
  and are *"tentative, subject to budget negotiations, and contingent upon final
  agreement execution."*
- Catalyst: amounts *"will be finalized after OHA completes award negotiations."*
- Transformation: the tables are headed **"Organizations Offered Funds"** and the
  column is **"Eligible Award Total."**

Every row is `NOTICE_OF_INTENT_TO_AWARD` and `amount_confirmed = No` — Alaska's
shape, state-wide. The 2026-07-07 release *does* say the $35M is money Oregon
*"has made to date"*, which is what carries `recipient_confirmed = Yes` and
`distributed_to_hospital = Yes` on the 35; the offer language is what keeps
`amount_confirmed = No` beside it. §9.3 splits those two questions precisely so
a preliminary figure does not drag a confirmed recipient down with it.

**Hospital dollars: 49 rows, $50,188,531** — 35 Transformation hospitals
($34,998,000) plus 14 Catalyst hospital rows ($15,190,531). All
`NAMED_HOSPITAL`; Oregon adds nothing to the pooled bucket.

---

## Wave 2 is short, and that is the source

OHA's 2026-07-07 release states **33 projects and $17M**. The awards page names
**21, at $11,294,644**. The page never claims to be complete — its own framing
is *"pleased to share a list of organizations selected"* — and it prints no
count and no total.

South Dakota's lesson in partial form: **a count is not a list**. The 12 unnamed
projects and the $5.7M are recorded on the Reconciliation sheet and were **not
reconstructed**. An assertion pins the 21, so the day OHA publishes the rest the
build fails rather than shipping a stale extraction.

---

## Four judgements worth reading before using the file

**1. `University` outranks `Hospital or Hospital System` in the org-type table.**
OHA types four rows *"Hospital or Hospital System, ... University"* and every one
is an **OHSU entity** (the 24/7 obstetric advice line, the Casey Eye Institute,
the Office of Rural Health). `UNIVERSITY_OR_AHC` is what §8 has for an academic
health centre, and it is the conservative direction — it can only keep dollars
**out** of the hospital total.

**2. Oregon's tokens sit ABOVE Alaska's `Local Government`, and that prevents a
deflation.** Oregon's rural hospitals are organised as **health districts**, so
Curry Health District (DBA Curry Health Network) is typed *"Behavioral Health
Clinic, Hospital or Hospital System, Local Government, …"*. Appended at the end
of the shared table instead, Alaska's `Local Government` row would fire first and
code an **operating rural hospital** `LOCAL_GOVT_OR_PUBLIC_HEALTH`, dropping it
out of the total. Alaska is unaffected: no Alaska row contains an Oregon token.

**3. §6.2 caught a real inflation.** *Medical Assistant Workforce Pathway* is
published as **"Northwest Regional ESD, Clatsop Community College, Providence
Seaside Hospital, Seaside School District"** against **one** figure of $186,000.
The name rules see *"Hospital"*; without the override the whole $186,000 lands in
the hospital total as a Providence award — which is not what OHA published and
not what any of the four received. Multi-recipient rows are `Unclear` and enter
neither bucket. **The delimiter is the comma and only the comma**: session 6
already decided not to split on a bare `&` so *Oregon Health & Science
University* would survive it, and that precedent is followed rather than
re-decided.

**4. 23 hospital-owned RHCs, $2,300,000, are recorded and not recoded.** Grande
Ronde Hospital's five clinics, Columbia Memorial's three, Providence Seaside's
three, and two entries whose names *are* hospitals. Recoding them
`HOSPITAL_AFFILIATED_ENTITY` would move up to $2.3M into the hospital total on
this pipeline's authority; **OHA put every one of them in the RHC table and paid
them from the $10M RHC pool.** `hospital_affiliation_signal` marks them, the
Reconciliation sheet reports the dollars, and a human decides. Alaska's
unresolved judgement in Oregon's clothing.

---

## The provenance defect, and which check found it

A hand grep before the first fetch reported all five sources credential-free.
**It was wrong.** `rhtp-awards.aspx` loads Google Maps for the Catalyst
distribution map and carries the key **inside the script URL**:

```
<script src="https://maps.googleapis.com/maps/api/js?region=US&key=AIzaSy…">
```

A pattern anchored on `api_key=` or `apiKey:` — which is what was run by hand —
walks straight past that form. The **automated guard, running on every fetch,
caught it**; the human check that ran once did not. That is the lesson worth
keeping, more than the key itself.

The page is now archived with **every `<script>` element removed** (the key lives
only in a script `src`; nothing this repo parses lives in a script), the
reduction is asserted credential-free **after** reducing, and the **full page's
digest as served** is in the manifest, so provenance closes — §7.1's posture, as
applied to CMS's Mapbox token and Illinois'. Every figure in this document is
identical before and after the reduction. The other four sources are archived
**byte for byte**.

One smaller fix: the guard now strips NUL bytes before scanning, because an xlsx
is a zip and `rawToChar()` refuses it. A guard that throws on the one binary
source is a guard that gets an exception written around it.

---

## Two other things the parsers refuse to guess at

- **A range is not an amount.** Wave 1 prints *"$403,000 – $778,000"* and
  *"$102,000 – $194,000"*. `amount` is **empty** on both rows and the bounds are
  in `amount_low`/`amount_high` — picking the low bound, the high bound or the
  midpoint would all publish a per-recipient figure OHA has not. New flag
  `AMOUNT_RANGE_IN_SOURCE`, written into `vocabularies.csv` with full notes
  (§2's "do not invent codes mid-session", taken as a deliberate decision the way
  session 12 took its three).
- **A project with no amount is kept, not dropped.** *System of Care
  Transformation Regional Convenings* has an initiative and a full description
  and no figure. Dropping it loses a project OHA named; refusing on it would have
  lost the other 20 with it. `AMOUNT_MISSING`, and the parser still refuses a
  block with neither an amount nor a description.

And where OHA **did** split a figure per recipient — *"Wallowa Current Award
Estimate Year 1 - $965,661"* under a header naming three organisations — that is
the state doing the §6.2 split itself, so the row carries **Wallowa Valley Center
for Wellness**, not the three-name list.

---

## What is now on disk

- `R/03m_or_year1_awardees.R` — `--fetch` / `--validate` / `--build`
- `data/reference/or_year1_awardees.csv` — 278 rows, the source of record
- `OR_year1_awardees.xlsx` — README / Awards / Reconciliation
- `data/evidence/OR/` — 5 documents, SHA-256 manifest, one reduction recorded
- `R/utils_recipient_classification.R` — Oregon's 16 org-type tokens, ordered
  deliberately; `rhtp_classify_records()` gains `org_type_delimiter`
- `tests/testthat/test_03m_or_year1_awardees.R` — 154 assertions
- `tests/testthat/test_state_union.R` — Oregon added; **nine** state files union
- `rcj_state_survey.csv` / `state_trigger_queue.csv` — Oregon `EXTRACTED`;
  **Texas is now the top of the queue** (68 candidates / 67 awardees)

**Tests: 1,536 assertions, all passing** (was 1,375).

---

## Next

1. **Texas, then KS 54, MD 42, NE 39, IN 37, OK 35.** 31 states still queued.
2. **`il.amplifund.com`** — Illinois' 97-hospital planning-grant solicitation is
   still how Illinois hospitals get named ($28.2M pooled → named).
3. **Verify the §7.3 registry** — still the hard gate (§13.12), untouched by any
   of this. Florida first.
4. **The AHA Annual Survey / CMS Provider of Services extracts** (blocker 5).
   Oregon adds **49 hospital rows** to the ~200 already waiting on a CCN match,
   and Oregon's are unusually matchable: the bulletin publishes a **bed count**
   per hospital.

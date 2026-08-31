# Session 24 — Indiana: the awards are in the procurement channel, and RCJ
# invented the programme label

**Date:** 2026-08-31
**Quota:** zero RCJ calls. 40 fetches across `www.in.gov` (GROW, IDOA, IDOH),
throttled per §9.5.
**Files:** `R/03s_in_year1_awardees.R`, `tests/testthat/test_03s_in_year1_awardees.R`,
`data/reference/in_year1_awardees.csv`, `data/reference/in_rcj_candidate_disposition.csv`,
`IN_year1_awardees.xlsx`, `data/evidence/IN/` (19 files).

---

## The headline

**Indiana has published seven RHTP award actions and not one of them is a
hospital.** Every recipient is a consultancy or a technology company selected
through a competitive state RFP. Indiana's hospital money has not moved yet.

| RFP | Recipient | Amount | Agency | Initiative |
|---|---|---:|---|---|
| 26-87448 RHTP MOCC | Patient Flow Innovations | — | IDOH | 1 |
| 26-87448 RHTP MOCC | Collaborative Fusion, Inc | — | IDOH | 1 |
| 26-87448 RHTP MOCC | Communicare Technology | — | IDOH | 1 |
| 26-87449 RHTP07 Teleconsult Assessment | Laurel Health Advisors LLC | **$860,088** | IDOH | 7 |
| 26-87450 RHTP Program Evaluator | Public Policy Associates LLC | — | FSSA | — |
| 26-87556 Preceptor Registry | Concourse Tech Inc | — | IDOH | 10 |
| 26-87667 ACO Feasibility Study | Deloitte Consulting LLP | — | FSSA | 1 |

**Seven award actions, seven recipients, five solicitations, six documents,
$860,088 — which is 0.4% of Indiana's $206,927,897 allotment.**

## Two qualifications that must travel with every figure

**They are not executed awards.** Every one is an IDOA *"Preliminary Notice —
Award Recommendation"*, which is weaker than any other state in this repository.
Each says the State *"will begin contract negotiations"*, that the
recommendation *"is conditioned upon successful finalization of contracts"*,
that the State *"may choose to withdraw"* it, that *"[o]nce contracts are
finalized the State will issue a final Notice of Award"* — and each quotes
I.C. 4-13-1-19: *"[a] bidder or an offeror does not gain a property interest in
the award of a contract by the department unless the bidder or offeror is
awarded the contract, and the contract is completely executed."* All seven rows
are `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No` — Oregon's and
Maryland's posture, not Nebraska's or Georgia's. `in_assert_not_executed()`
fails the day Indiana posts a final notice, because on that day the file's
framing is wrong and must be rewritten rather than re-run.

**The one amount is a five-year contract value.** The 2026-08-21 award
recommendation letter states *"5-year Contract Value: $860,088.00"*. Publishing
that in a Year 1 column would overstate Indiana by an unknown multiple, so the
row carries `AMOUNT_IS_MULTI_YEAR_TOTAL` — added to §8 this session with full
notes — plus `amount_basis` and `budget_period`. The other six documents publish
**no amount at all**, so their `amount` is empty (Georgia's device) and no sum
over the column can invent one.

---

## Where Indiana publishes, and why it took two hops to find

Indiana brands RHTP as **GROW** (Growing Rural Opportunities for Well-being in
Health) at `in.gov/grow-rural-health`, across eleven initiatives.
**`in.gov/health` publishes no award list of its own** — IDOH's front page links
out to the GROW site for RHTP, and that is the whole of its answer.

**But the GROW site names almost nobody.** Its recipient-level awards are made
through the Indiana Department of Administration's ordinary state procurement
channel and published on IDOA's *Solicitation Award Recommendations* page as one
zipped PDF per solicitation. The GROW initiative pages are the **index** into
that channel: each carries a status table whose last column links either
*"View posting"* (a solicitation) or *"View award"* (an award). That is
Nebraska's award-index control in Indiana's own form.

What the GROW site says on its own is a count, not a list. Initiative 9:
*"Awarded three organizations to implement the Community Health Worker
Sustainability and Integration Activities"* — three organisations, no names, no
amounts, no link. South Dakota's lesson exactly. Initiative 10: *"$5 million for
existing rural GME programs, funds to be awarded in July"* and *"Vendor selected
for strategic plan"* — no name either.

### The provenance is not on the award document

**Two of the five solicitations — 26-87556 Preceptor Registry and 26-87667 ACO
Feasibility Study — carry "RHTP" nowhere in their IDOA table title or in their
award letter.** Read from the award document alone they are ordinary state
procurement and would have been dropped. They are RHTP because their **Scope of
Work** carries it, and the footer is identical across all five:

> On Dec. 29, 2025, Indiana was awarded a grant of nearly $207 million for the
> first year of a five-year federal Rural Health Transformation Program (RHTP)
> … This Rural Health Transformation Program is supported by the Centers for
> Medicare & Medicaid Services (CMS) of the U.S. Department of Health and Human
> Services (HHS) **as part of a financial assistance award totaling
> $206,927,896.80 with 100 percent funded by CMS/HHS.**

That is the §6.2 test passing in the strongest form this project has seen: the
awarding agency named on the award's own solicitation, a total matching
`cms_fy2026_allotments.csv`'s **$206,927,897** to the dollar, **and the state
stating its own Notice of Award date** — 2025-12-29, exactly what
`cms_state_noa_dates.csv` carries as the anchor for all fifty states.

**Kansas said read the programme page's link list. Indiana says open the
solicitation, not just the award.**

---

## §0.1 — the worst ratio in the project, and a new mechanism

RCJ holds **37** Indiana Tier 3 candidates. The disposition is re-derived from
`stage2_record_table.rds` on every run and closes exactly:

| Group | Rows | Disposition |
|---|---:|---|
| RHTP award rows (26-87448 ×3, 26-87449 ×2, 26-87450 ×1) | **6** | `RHTP_SUBAWARD` |
| Indiana Community Connect (via Indiana 211) | 1 | `RHTP_BUT_NOT_A_SUBAWARD` |
| 988 Contact Centers Services (RFP 26-84962) | 7 | `NOT_RHTP_STATE_PROCUREMENT` |
| Other IDOA state procurement | 23 | `NOT_RHTP_STATE_PROCUREMENT` |
| | **37** | RHTP subawards: **6** |

**The mechanism is new and it is worse than mis-titling. RCJ appends an RHTP
label the documents do not carry.** Its own document titles include *"Indiana
Negotiated Bid 26-87613 For Hydraulic Trail Trailer Purchase **RHTP 2026 Award
Announcement**"* and *"Indiana Communication Equipment & Piece Parts QPA **RHTP
2026 Award Announcement**"*. The first is a trailer: IDOA's own letter
recommends *"a one-time purchase with an amount of $90,000"*, and RCJ's $90,000
for Globe Trailers matches it exactly. **RCJ's amount is right; the programme
label is invented.**

Seven further rows sit under the bare title *"IN - 2026 - RHTP Update"*, among
them an **Electric Generating Facility Fuel Cost Analysis** ($813,000, a utility
rate consultancy), a **tobacco quitline**, a **workforce diploma programme** and
an **Indiana Veterans' Home therapy contract**. Three more carry no document
title at all, only a captured page header — *"Indiana DEPARTMENT OF
ADMINISTRATION STATE OF INDIANA Commissioner's Office Mike Braun, Governor
Indiana Government Center South 402 West Washington Street, Room W462
Indianapolis,"* — which is §0.1's page-chrome-as-title defect verbatim, and the
reason `PAGE_CHROME_TITLE` is in §8.

**An extractor written from the candidate list would have published roughly
$147 million of unrelated Indiana state procurement as RHTP subawards**, with
real recipients, real amounts and real primary sources behind every row. Texas
was $16.8M of the wrong programme; Indiana is nearly nine times that.

**And RCJ misses two of the seven real awards** — Deloitte (26-87667) and
Concourse Tech (26-87556), precisely the two whose titles never say RHTP. That
is Kansas's and Nebraska's lesson a third time: the candidate count says where
to look and never what is there.

### The one candidate that is RHTP and still is not an award

*"Indiana Community Connect (via Indiana 211)"*, **$3,300,000**, sourced to
Indiana's own GROW narrative. The narrative's initiative table reads
**$3,320,000.00** — not RCJ's figure — it is an initiative **budget**, its
contractors are unnamed and future (*"The contractor will design, develop,
implement, and maintain the Indiana Community Connect App"*), and *"Indiana
Community Connect"* is the **programme**, not a recipient (§6.1
`PROGRAM_NAME_AS_AWARDEE`). Texas's `RHTP_BUT_NOT_A_SUBAWARD`, exactly.

---

## The positive control, and its ratio

Indiana demonstrably publishes recipient-level award documents in a uniform,
recognisable form: **IDOA's register carries 456 award recommendations**, each a
zip holding a *"Preliminary Notice of Award"* PDF, and this file parses seven
names out of six of them. So *"Indiana has published no hospital roster"* is a
statement about Indiana, not about our ability to read its site.

**The ratio is the load-bearing part. Four of the 456 are RHTP — 0.9%.** The
rest is road salt, dumpsters, DNA collection kits and a digital printer. That is
why *"IDOA published an award recommendation"* is no evidence of RHTP, exactly
as *"DHHS published an Intent to Award"* was no evidence of it in Nebraska.
`in_assert_award_register()` is a tripwire in **both** directions: it fails if
the register shrinks or stops carrying ordinary procurement (a redesign that
split RHTP onto its own page would otherwise turn every future run silently
green), and it fails if a **fifth** RHTP row appears, because at that point
Indiana has awarded something this file does not carry.

The **negative control** is archived beside the positives: `NB 26-87613 80HT
Hydraulic Tail Trailer`, a real IDOA award recommendation that RCJ labels RHTP
and that carries no CMS footer at all. *(Indiana spells it "Tail Trailer" on the
register and "Trail Trailer" in the letter. Both are the state's own; §8 keeps
the source's language and resolves neither — RCJ did not mistranscribe it.)*

---

## Where Indiana's hospital money actually is

**GROW Regional Grants** is Indiana's hospital-facing vehicle: *"$120M awarded
annually across eight regional coalitions"*, per the state's own page. **It has
not awarded.** The page's timeline reads *"Release RFF on 3/2/26"*, *"RFF
Applications submitted July 1"*, and *"It launches Sept. 1, 2026"* — **tomorrow,
as this file was built.** The State *"will convene an application review team
that will score applications and determine funding"*.

`in_assert_regional_not_awarded()` fails the day that changes, because on that
day Indiana becomes one of the largest hospital-dollar states in the project and
this file is materially incomplete.

### That page is the biggest §0.3 trap this project has met

It carries **fifteen tables of named people against named hospitals** — Goshen
Health, Parkview Health, Reid Health, Franciscan Health, Woodlawn Hospital,
Pulaski Memorial, Cameron Health — which read at a glance as a hospital award
roster and are the **Regional Committee Members**: an advisory body appointed to
**score the applications**.

Beside them it prints an eight-row table of per-region dollar figures
($4,405,581, $7,881,614, $3,960,275, …) which are **Maximum Capital Expenditure
ceilings**, not awards. *A table of eight regions against eight dollar amounts,
on the awarding agency's own grants page, is as close to a publishable award
table as a non-award can look.* `in_assert_committee_not_recipients()` pins both
halves: the committee tables must still be committee tables, no hospital named
only there may enter the award rows, and the dollar table must still be labelled
a maximum.

**A third trap sits inside the one document that names an amount.** The
2026-08-21 letter lists **seven proposers** and selects one — Deloitte, Laurel,
Manatt, PwC, Sargad, Syra Health, Yaqeen. Nebraska's applicant-roster trap
again. And Deloitte is the trap inside the trap: an **unsuccessful proposer
here** and a **genuine awardee on a different solicitation** (26-87667). The two
must never merge, and `in_assert_proposers_not_awarded()` requires exactly that.

---

## One judgement against the shared classifier, stated plainly

`rhtp_classify_recipient_type()` returns §8's standing fallback
(`NONPROFIT_CBO` + LOW + `RECIPIENT_TYPE_INFERRED`) for six of the seven,
because IDOA publishes no organisation-type column — Kansas's, Maryland's and
Nebraska's shape. Here the source **does** state the form in its own words: IDOA
*"has identified the following companies as the selected respondents"* to a
competitive RFP, and every name carries a corporate suffix (LLC, Inc, LLP). That
is `VENDOR_OR_CONTRACTOR` on the document's own language, so the seven are typed
from the source at MEDIUM rather than from the fallback.

`recipient_type_source` records the classifier's value on **every** row, so the
override is auditable and reversible, and it is queued as
`IN_PROCUREMENT_VENDOR_TYPE` for a human. **It moves no dollars** — all seven
are `distributed_to_hospital = No` under either answer — which is why it was
decided here rather than left open.

Three of the seven come out `IN_KIND_BENEFIT` rather than `NON_HOSPITAL`: the
MOCC is *"a 24/7 statewide hub to coordinate patient transfers, EMS resources
and hospital capacity"*, which is §10.2's in-kind test met on its own terms —
hospitals use the hub and do not receive the money. `hospital_benefiting = Yes`
keeps those dollars visible to AHA's narrative without entering any total.

---

## Two things fixed in the shared PDF reader

### A crash on a signed PDF

`R/utils_pdf_text.R` **crashed** on Indiana's negative control —
`input string 1 is invalid in this locale` — because nine `regexec`/`gregexpr`
calls over PDF dictionary bytes lacked `useBytes = TRUE` while their sibling
`ref_body()` already had it. The trailer award is a **signed** PDF carrying
binary inside an object dictionary, which is enough to make R refuse the string.

Session 21's lesson was that an empty answer is the worst shape; a crash is at
least loud, but it still means an unreadable state document. All nine now use
`useBytes = TRUE`, which is what PDF internals want anyway — the patterns are
pure ASCII PDF syntax.

### A quadratic that made one document take SIX MINUTES — and it was not where it looked

Indiana's 2026-08-21 award letter took **370 seconds** to parse. Three rounds of
plausible-looking optimisation barely moved it, which is the lesson: **the
profile found it in seconds and reasoning had not.**

```
                         self.time self.pct total.time total.pct
"c"                         362.46    97.87     362.46     97.87
"rhtp_pdf_tounicode"          1.82     0.49     368.00     99.36
"rhtp_pdf_content_lines"      0.18     0.05     369.98     99.90
```

**97.9% of the entire run was `c()`, inside the CMap parser** — not the content
scanner everything pointed at. `rhtp_pdf_tounicode()` expanded a `beginbfrange`
one code at a time:

```r
for (k in lo:hi) {
  codes <- c(codes, as.character(k))
  vals  <- c(vals, intToUtf8(dst + k - lo))
}
```

A single `bfrange` routinely spans thousands of codes in a subsetted font, and
each `c()` copies the whole vector. Ranges are now expanded whole and the chunks
flattened once — same codes, same values, same order.

**370 s → 3.4 s.** The document's text is identical.

Two smaller quadratics found on the way were kept, because both are real and
both were verified:

- `flush()` grew `lines`, `xs` and `ys` with `c()` per emitted line.
- `at_y()` called `isTRUE(all.equal(y, y_at))` **once per positioning operator**
  — a generic dispatch per glyph on a `Td`-per-glyph Word export (Maryland's
  producer behaviour, session 21). Replaced by `rhtp_pdf_near()`.

The tolerance detail there is worth keeping: a first version of `rhtp_pdf_near()`
used a literal `1.5e-8`, which is *not* R's default
(`sqrt(.Machine$double.eps)` = 1.4901161e-08). It disagreed with `all.equal` on
7 of 174,300 comparisons — all at magnitudes no PDF coordinate reaches, which is
exactly the kind of "it can't happen here" that should not be load-bearing in a
shared reader. With the real default, **0 of 174,300 disagree.**

A CMap hash (`rhtp_pdf_cmap_env()`) replaced the per-glyph name scan in
`rhtp_pdf_decode()` as well; it was worth ~0 here once the real cause was fixed,
but it is correct and verified equivalent over 400 random CMaps, so it stayed.

**Verified rather than assumed: Kansas, Maryland and Georgia were rebuilt after
each change and all three reference CSVs came back byte-identical**, and
`test_utils_pdf_text.R` passes unchanged (51 assertions). The three workbooks
differ only in `dcterms:created` and were reverted, which is the second,
independent confirmation (sessions 19 and 21's precedent).

---

## The vocabulary guard caught this session's own invented code

`extraction_method` was first written as **`PARSED_FROM_PDF`** — a value that
reads correctly, describes what happened accurately, and **is not in §8**. The
Indiana test's own vocabulary check failed on it, and `vocabularies.csv` already
had the right answer: `DIRECT_TEXT`, which is what Kansas, Maryland, Nebraska and
Oregon all use for exactly this. Changed, and no other column moved.

That is §2's *"do not invent codes mid-session"* working as designed, on the
session that wrote the rule's newest exception (`AMOUNT_IS_MULTI_YEAR_TOTAL`,
added deliberately and documented). The difference between the two is the whole
point: one described a condition no existing code covered, the other was a
synonym for one that already existed.

## One near-miss, and it is session 23's again

Appending the review-queue row with `readr::write_csv` rewrote the committed
**CRLF** file as **LF**, turning a one-row addition into a five-line rewrite.
Caught by reading the diff rather than the content, reverted, and re-appended
byte-wise so the existing bytes are untouched and the diff is `1 insertion(+)`.
The same care was taken with `vocabularies.csv`. Session 23 met this exact
failure and recorded it; meeting it again one session later is the argument for
checking the *diff*, not the file.

---

## Tests

**2,405 assertions across 27 files, all passing** (was 2,292 across 26); the one
skip is the stage 00 first-run branch that has self-skipped since its CSV
existed. `test_03s_in_year1_awardees.R` is new at 107 assertions, and
`test_state_union.R` now combines **thirteen** state files — Indiana is the
first with no hospital row at all, which is exactly the kind of thing that
unions fine until an invariant assumed one.

## What Indiana adds to the standing questions

Every state so far has added one question to ask the next. Indiana adds two.

**Sixth: is the state's award channel its PROCUREMENT system rather than a
grants page?** Indiana's RHTP awards are not on the RHTP site at all — they are
IDOA RFP awards, indexed from the GROW initiative pages by a "View award" link
and published on a register that is 99% not-RHTP. A state hunt that reads only
the health agency's programme pages finds a count and no names.

**Seventh: does the AWARD document carry the provenance, or only the
SOLICITATION?** Two of Indiana's five say RHTP nowhere on the award. Keyed on
the award alone, 2 of 7 recipients vanish — and they are the two RCJ also
misses, so nothing else would have caught them.


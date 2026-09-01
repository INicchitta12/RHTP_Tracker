# Session 27 — auditing the CMS financial-assistance footer as a provenance test

**Task:** session 26 found that the CMS financial-assistance footer covers the
*publication*, not the programmes described in it. The footer has been used as
a §6.2 provenance check in several states. This is the audit that asks, for
each of them: **was the footer load-bearing — was there any other evidence
establishing RHTP status — and does an independent check exist?**

**Nothing was re-coded.** No extractor, classifier, reference CSV or committed
figure was touched. This document reports; a later session decides what to
wire.

---

## 0. Method

Three questions per state, answered from the **committed archive**, never from
the session notes:

1. **Does the extractor rely on the footer?** `grep` for
   `financial assistance award totaling` across `R/`. Five state files carry
   it: `03o` (KS), `03r` (NE), `03s` (IN), `03t` (OK), `03u` (NV). No other
   extractor references it at all, so the audit's universe is those five plus
   Maryland, which uses a different CMS sentence and is included as a control.

2. **What is the footer's grammatical SUBJECT?** This turned out to be the axis
   the whole audit runs on, and it is not something the session notes record.
   The boilerplate comes in two forms, and only one of them is a statement
   about the programme:

   | Form | Subject | What it asserts |
   |---|---|---|
   | *"This **publication / presentation** is supported by …"* | the paper | that CMS money paid to produce this document |
   | *"**This Rural Health Transformation Program** is supported by …"* / *"**The Rural Health Transformation Program** is supported by …"* | the programme | that CMS money funds the programme the document is about |

   **Nevada's disproof lands on the first form only.** NVHA's workforce
   publication carries *"This publication is supported by…"* and then describes
   GME (State General Fund) and SHARP (an SB5 appropriation) beside WRRAP. The
   footer was true and reached nothing.

3. **Is there programme-scoped evidence in the same source, and is it
   asserted in code?** A programme-scoped statement names RHTP as what the
   money funds or what the work *is* — a document heading, a scope-of-work
   background, a body sentence. It is what the footer's second form claims to
   be and its first form does not.

---

## 1. The answer in one table

| State | Footer used | Footer subject | Programme-scoped evidence in the source? | Asserted? | **Load-bearing?** |
|---|---|---|---|---|---|
| **KS** — REH CAP + RPGP | `ks_assert_rhtp_funded()`, the only "what funds it" test | *"This **presentation** …"* | **NO — the award PDF contains zero occurrences of "RHTP" and zero of "Rural Health Transformation"** | — | **YES** |
| KS — CHW + AFIM | none (that PDF carries no footer) | — | Yes: the document's own title, *"Kansas Rural Health Transformation Program … Awarded Project Descriptions"* | no | No |
| **NE** | `ne_assert_rhtp_funded()`, described in the file as what the evidence *is* | *"**The Rural Health Transformation Program** …"* | Yes: each notice is headed **"RHTP Initiative 3.3 / 4.4a / 4.4b Awards"** | heading no; the index link yes | No |
| **IN** | `in_assert_rhtp_funded()`, described as "what separates an RHTP award from the 449 other rows" | *"**This Rural Health Transformation Program** …"* | Yes, and heavily: scope-of-work background, the RFP's own title *"IDOH **RHTP** Registry and Incentive Management System RFP"*, *"FSSA is undertaking comprehensive initiatives through the RHTP"*, *"Per federal guidance on the RHTP grant …"* | the NOA sentence yes; the scope language no | No |
| **OK** | `ok_assert_rhtp_funded()`, the only "what funds it" test | *"This **publication** …"* | Yes: the roster page's own body — *"Through the Rural Health Transformation Program (RHTP), funding is awarded to eligible organizations …"* | no | No |
| **NV** | only as a **negative** control, `nv_assert_footer_is_not_provenance()` | *"This **publication** …"* | positive provenance is **CMS's own Notice of Award** | yes | No |
| MD (control) | no footer | — | *"All partners and subawardees of Maryland's RHTP **cooperative agreement with CMS**…"*, and both PDFs headed *"Maryland Rural Health Transformation Program … Budget Period 1"* | yes | No |
| FL · GA · PA · AL · AK · SD×2 · IL · OR · TX | never referenced | — | state RHTP programme announcements naming the programme | — | No |

**One state fails: Kansas.** And it fails in the exact grammatical form Nevada
disproved.

---

## 2. Kansas, in detail

### 2.1 What the award document actually says

`data/evidence/KS/2026-08-29_kdhe_reh_cap_and_rpgp_award_winners.pdf`, read
through `rhtp_pdf_text()`:

```
"Rural Health Transformation"  : 0 occurrences
"RHTP"                         : 0 occurrences
"financial assistance award totaling $221,890,007.82"  : 1 occurrence
```

Its first line is:

> **"This presentation is supported by the Centers for Medicare & Medicaid
> Services (CMS) … as part of a financial assistance award totaling
> $221,890,007.82 with 100 percent funded by CMS/HHS."**

That is the publication-scoped form. **The document never names the programme
at all**, and the footer is the only string in it that ties these awards to
RHTP. `ks_assert_rhtp_funded()` reads that string and nothing else, and its own
doc comment says so plainly: *"If it ever stops doing so, this file has lost
the evidence that Kansas's awards are RHTP at all."* That comment is correct as
the code stands.

### 2.2 What is at stake

| Kansas pool | Rows | Dollars | Hospital rows | Hospital dollars |
|---|---:|---:|---:|---:|
| REH CAP | 17 | $29,097,937 | 12 | $21,963,499 |
| RPGP | 22 | $49,915,410 | 5 | $13,197,062 |
| **footer-only subtotal** | **39** | **$79,013,347** | **17** | **$35,160,561** |
| CHW + AFIM (independently titled) | 7 | $1,007,152 | 4 | $560,716 |
| **Kansas total** | **46** | **$80,020,499** | **21** | **$35,721,277** |

**98.7% of Kansas's published dollars and 98.4% of its named-hospital floor
rest on a footer whose subject is "this presentation".**

### 2.3 An independent check exists — twice — and neither is wired

Both are already in the committed archive. Neither is read by any assertion.

**(a) KDHE's own announcement, on the RHTP programme page**
`data/evidence/KS/2026-08-29_kdhe_rhtp_program_page.html`:

> *"KDHE today announced the recipients of the Regional Partnerships Grant
> Program (RPGP) and Rural Emergency Hospital Conversion/Transformative Capital
> Investment Program (REH/CAP) grants **through the Kansas Rural Health
> Transformation Program (RHTP)**. In total, $79.1 million is being awarded to
> 39 organizations across the state…"*

This is programme-scoped and it names **both pools by name**. It is strictly
stronger than the footer: the footer says CMS paid for the slide deck; this
says the grants are RHTP grants.

**(b) Kansas's own RHT Plan budget narrative**
`data/evidence/budget_narratives/KS/2026-07_ks_rht_plan_budget_narrative_revision_2.pdf`,
whose running header is *"Kansas RHT Plan Year 1 Budget Narrative Revision 2:
July 2026"*, places all three pools inside the plan's initiative structure:

- *"Program 2: REH Conversion/Transformative Capital Investment Grant Program
  (REH-CAP Program). KDHE will sub-award…"*
- *"Program 1: Regional Partnership Grant Program (RPGP). KDHE will sub-award
  competitive grant applicants…"* (under Initiative 2)
- *"Program 1: Accountable Food Is Medicine and Community Health Worker (CHW)
  Deployment Program (A-FIM)."* (under Initiative 1)

This file is **already registered as a Kansas source** in `R/03o`
(`budget_rev2`, line 106) and archived — and it is **never read**. `grep` finds
exactly one reference to it in the whole repository: the row that declares it.

### 2.4 Two arithmetic observations, reported and not resolved (§0.4)

- KDHE's announcement says **"$79.1 million"**; the 39 parsed rows sum to
  **$79,013,347**, which rounds to $79.0M. An $86,653 difference between the
  state's own headline and the state's own table.
- KDHE says **"39 organizations"**; there are 39 award **actions** across **38
  distinct awardees**, because Greeley County Health Services holds one award
  in each pool. The repository already knows this (it is why the pool split is
  positional), and it means the state's own count is of rows, not organisations.

Neither is a defect in the extraction and neither is fixed here.

---

## 3. The four states that pass, and what each passes on

**Nebraska.** The footer is the programme-scoped form, and beyond it each
notice is *headed* **"RHTP Initiative 3.3 Awards"** / **"4.4a"** / **"4.4b"** —
DHHS's own document title, naming the programme and the initiative the awards
belong to. Independently, the roster is reachable only through the "Awardees"
column of the RFA timeline table on the state's Rural Health Transformation
page, and `ne_assert_award_index()` already asserts all three links present and
pointing at the PDFs this file parses. The document heading is the one piece
not asserted; it is one `str_detect` away.

**Indiana.** The strongest of the five, and the repository under-credits it.
The file describes the footer as "what separates an RHTP award from the 449
other rows on IDOA's register", but the Scope of Work carries a full
programme-scoped background *around* that footer:

- 26-87556's RFP is titled **"IDOH RHTP Registry and Incentive Management
  System RFP"**, and its background reads *"One of the State's initiatives
  approved by CMS, the Clinical Training and Readiness initiative…"*.
- 26-87667's scope reads *"FSSA is undertaking comprehensive initiatives
  through the Rural Health Transformation Program (RHTP)…"*, *"Per federal
  guidance on the RHTP grant, the Contract resulting from this RFP will have a
  five-year contract term, but the Contract only has funding for the initial
  budget period (Budget Period 1)"*, and requires alignment with *"the RHTP's
  five (5) strategic goals"*.

These are statements about **the work**, not about the paper. Session 24's
framing — that the two untitled solicitations "are RHTP because their Scope of
Work carries **it**" — is right about the location and wrong about which
sentence does the work. `in_assert_rhtp_funded()` already asserts the NOA
background sentence alongside the footer, so Indiana is not exposed; but the
sentence it asserts is the generic *"Indiana was awarded a grant"* background,
not the scoping language above.

**One thing the audit did find in Indiana, and it is a correction to the
session-24 note.** CLAUDE.md says the awards are "reachable only through a
'View award' link on the initiative pages". Checked against the archive: the
GROW **Initiative 1** page does carry the solicitation numbers and a *View
award* link (`004000000087667`, marked *Awarded*, and `…87448`), but the
**Initiative 7 and Initiative 10 pages carry neither** — Initiative 10's only
mention of the preceptor work is an FAQ sentence about *"a preceptorship
program"*, with no solicitation number and no award link. So RFP 26-87556
(Concourse Tech) is **not** indexed from Indiana's own initiative pages, and
its provenance rests entirely on its Scope of Work — which, as above, is
programme-scoped and sufficient.

**Oklahoma.** The footer is the publication-scoped form and is the only test in
code, but the roster page carries its own body sentence — *"Through the Rural
Health Transformation Program (RHTP), funding is awarded to eligible
organizations whose projects align with program goals"* — and the page itself
is titled *RHTP Funding Recipients* and nested under the RHTP programme
section. Independent evidence exists in the same archived file that
`ok_assert_rhtp_funded()` already opens.

**Nevada.** Uses the footer only as a negative control. Positive provenance is
CMS's own Notice of Award. Not exposed.

---

## 4. What this changes about the ninth question

Session 26 added: *does the document's CMS footer cover the programme the row
belongs to, or only the publishing of the document?* This audit makes it
cheaper to answer, because the footer **says which one it is, in its own first
three words**:

> **Read the footer's subject.** *"This publication…"* / *"This presentation…"*
> is a statement about the paper and establishes nothing about the money.
> *"This Rural Health Transformation Program is supported by…"* is a statement
> about the programme. Neither is sufficient on its own, but only the first is
> actively misleading, and it is the form Kansas relies on.

And the general rule underneath it: **provenance wants a sentence about the
money or the work, not a sentence about the document.** A document heading
("RHTP Initiative 4.4b Awards"), a scope-of-work background ("undertaking
comprehensive initiatives through the RHTP"), or an announcement naming the
pools ("grants through the Kansas Rural Health Transformation Program") each
does what no footer can.

---

## 5. Recommended follow-up — for a session that is allowed to change code

Nothing here is urgent in the sense that a figure is wrong. **No Kansas dollar
is in doubt**: two independent, programme-scoped sources in the committed
archive say the REH CAP and RPGP grants are RHTP grants. What is missing is
that the *code* does not read either of them, so a KDHE re-post that dropped
the slide-deck footer would hard-fail Kansas for no reason, and — the direction
that matters — a future state whose only evidence is a "this publication"
footer would pass the same test that Kansas passes today.

1. **Wire Kansas's two independent checks.** Extend `ks_assert_rhtp_funded()`
   to require the programme page's *"grants through the Kansas Rural Health
   Transformation Program (RHTP)"* sentence naming both pools, and to read
   `budget_rev2` for REH-CAP and RPGP as RHT Plan programmes. Keep the footer
   check; add to it rather than replacing it.
2. **Assert Kansas's date test.** The 6 March 2026 RPGP/REH-CAP webinar is on
   the archived programme page and is a comment in `R/03o`, not an assertion.
   KS is the only one of the five with no `*_assert_after_noa()`.
3. **Add the footer-subject distinction to the shared vocabulary of checks**,
   so a future state's `*_assert_rhtp_funded()` can record which form it found.
4. **Correct CLAUDE.md's Indiana line** about "View award" links on the
   initiative pages, per §3 above.

None of these was done in this session, because the task was to report.

# Session 21 — the completeness re-check, and Maryland

**Date:** 2026-08-29
**Quota:** zero RCJ calls. 24 fetches to seven state hosts for the re-check, 5 to
`health.maryland.gov`, all throttled to one request per host every 3 seconds
with a contact-bearing user agent (§9.5).

Two tasks, and they turned out to be the same task twice. Kansas's lesson —
*the roster you found may be a fraction of the roster the state published, in
plain sight* — was applied backwards to seven states that had already been
extracted, and forwards to a state that had never been looked at.

---

## 1. The completeness re-check — two of seven states have more

`R/03q_state_completeness_recheck.R`, `data/reference/state_completeness_recheck.csv`.
Evidence under `data/evidence/recheck/2026-08-29/<ST>/`, 24 files with per-state
SHA-256 manifests. **Nothing was extracted.**

| | Committed | Finding | Additional | |
|---|---:|---|---:|---|
| **GA** | 139 rows | **ADDITIONAL_ROSTER_FOUND** | **21 award actions, $30,277,580** | two signed Notices of Award on a page no session had read |
| **AK** | 161 rows | **ROSTER_HAS_GROWN** | **24 award actions, $16,862,504** | the rolling notice grew; total $160.7M → $181.9M |
| FL | 81 rows | NO_ADDITIONAL_ROSTER | — | reconciles **exactly** with the Governor's own roster |
| PA | 66 rows | NO_ADDITIONAL_ROSTER | — | roster byte-identical; 4 further pools name nobody |
| AL | 138 rows | NO_ADDITIONAL_ROSTER | — | release byte-identical; site still solicitation-only |
| OR | 278 rows | NO_ADDITIONAL_ROSTER | — | 11 unread bulletins; none is a roster |
| IL | 1 row | NO_ADDITIONAL_ROSTER | — | 97 hospitals with CCNs, and it is **eligibility** |

### Georgia — $30,277,580 of named hospitals, sitting behind two links

Sessions 9 and 10 extracted Georgia from `dch.georgia.gov`'s four announcements
and the value-based-care roster. **`greathealth.georgia.gov/find-funding-opportunities`
has never been read**, and DCH publishes its award documents there:

| Strategy | Document | Named | Amount |
|---|---|---:|---:|
| Initiative 5 — Workforce Retention Technology (surgical robots) | Notice of Intent to Award 2026-07-31; **signed Notice of Award 2026-08-12** | 13 hospitals | $26,000,000 |
| Initiative 3 — Care to Consumer: Point-of-Care Telepods | Notice of Intent to Award 2026-07-24; **signed Notice of Award 2026-08-03** | 8 award actions / 7 named hospitals | $4,277,580 |

The committed file carries these as **two aggregate rows**:

```
"13 hospitals (Workforce Retention Technology, surgical robotics) - names not captured"  recipient_count 13  amount NA
"8 hospitals (Care to Consumer Point-of-Care Telepods, 12 telepods) - names not captured" recipient_count  8  amount NA
```

**This is not new money.** The dollars are already inside Georgia's
$197,148,327 at *pool* level (`initiative_amount` $37,500,000 and $10,378,639).
What changes is that **$30,277,580 moves from "pool, names not captured" to
NAMED HOSPITALS** — which is the figure AHA is actually asked for. Georgia's
named-hospital total would go from **$60,000,000 to $90,277,580**.

The signed notice names everyone the intent named — 13 and 13, 8 and 8, the
same amounts — so there is no partial-execution gap to report. The robots
notice also names **5 unsuccessful applicants with DCH's reasons**, which is
worth having: two Southeast Georgia Health System campuses, East Georgia
Regional Medical Center, Wellstar MCG and Bacon County Health Services.

**The positive control** is the page itself. DCH publishes an award document as
a link reading "Notice of Award" or "Notice of Intent to Award"; the
**Telehealth Enhancements** strategy on the same page has its guidelines and
**no award document**. So four award links and a fifth strategy without one is
a real absence, and `recheck_ga()` fails if either the four or the control
strategy disappears.

### Alaska — the snapshot was never wrong; it is now stale

`ak_rhtp_awardsnotice_2026.xlsx` is the same URL and a different file.

```
161 -> 185 award actions        Implementation 142 -> 166; Planning 19, unchanged
$160,701,975 -> $181,871,366    of which $16,862,504 is 24 NEW awards
```

The remaining **$4,306,887** is one committed award **revised upward**:
`BP1-IA-308`, Southcentral Foundation, $1,548,208 → $5,855,095. No award
disappeared, and one organisation name was shortened (`Catholic Social Services
Early Learning` → `CSS Early Learning`).

**Alaska's own document corroborates it, which is what makes this a state fact
rather than a diff of two downloads.** The *Year 1 Funding Cycle Update* prints
the weekly cumulative counts — Week 4 | Aug 28, `$16.9M`, `24 Projects`;
cumulative `$182M`, `185 Projects` — and says outright that *"Project awards are
being announced on a rolling weekly basis."* The check asserts the update's
count equals the notice's row count, so the two Alaska documents cannot drift
apart unnoticed.

**86 `Organization Type` values also "changed" and none of them did**: Alaska
re-saved the file with `";"` where it had `"; "`. Worth recording because a
naive diff reports 86 changes in the column that decides Alaska's hospital
dollars.

### Florida — the first state file checked end to end against its source

Florida's 81 rows came from the owner's workbook. The workbook came from the
Governor's 2026-08-11 release, which links a **full awardee PDF**, and that PDF
reconciles with the committed CSV **exactly**:

```
PDF: 81 awardees   $188,201,256.11
CSV: 81 rows       $188,201,256.11
```

Regional totals in the release (14 + 11 + 21 + 35 = **81**) agree. The PDF's own
numbering runs 1–82 and **skips 66** — a gap in the Governor's office's
numbering, not the parse's, and it is asserted so nobody later "fixes" the
count.

One gap is left open and is not extractable: the release says this round
*"follows funding awarded through procurements earlier this year to establish
the infrastructure necessary to monitor program outcomes"*. Florida's allotment
is $209.9M and the published awards are $188.2M; the ~$21.7M of monitoring and
support procurements has no published recipient list.

### Pennsylvania — the roster is unchanged and there are four more pools

`rural-health-eligible-projects` is **byte-identical** to the committed archive
(66 projects). But `rhtp-funding-opportunities`, a child page never read, lists
**four further payment programmes worth about $86,800,000** — Rapid Response
Stabilization Round 1 ($25M) and Round 2 ($35M), an FQHC EHR/HIO programme
($1.8M) and an interoperability programme ($25M) — and **names no recipient for
any of them**. §0.3: nothing to extract, and a real thing to record, because
PA's committed $42.2M is now a small share of what Pennsylvania has committed.

### Oregon — eleven unread bulletins, and none of them is a roster

Session 17 found Oregon's hospital and clinic lists in a **GovDelivery
bulletin** that no oregon.gov page linked. The RHTP home page links **twelve**
such bulletins and session 17 read one. All twelve were read here. The eleven
others are webinar invitations, deadline extensions, RFGP addenda and the two
December award announcements already archived — the roster bulletin
(`4164e4f`) carries 4 tables and 137 dollar figures; the next richest carries
2 tables and 12. The awards page and the Catalyst xlsx are unchanged (the xlsx
byte-identical), and Wave 2 is still 21 of OHA's stated 33.

### Illinois — 97 hospitals, with CCNs, and it is eligibility

HFS still publishes no recipient-level award list, and `il.amplifund.com` is
behind a Microsoft sign-in. The one recipient-level document is the **Hospital
Planning Grant Methodology**, linked from the RHTP page: **97 eligible hospitals
with their CCNs**, city and county, against a **$28,191,393** pool, stating
*"**If all 97 eligible hospitals apply**, this will result in an award amount of
approximately $290,000 per hospital."*

That conditional is the whole of §0.3 in one sentence and the check asserts it
is still there. **Nothing was coded from this document.** The CCN list is
nonetheless the most useful thing found in Illinois: it is 97 hospitals already
matched to CCNs, against open blocker 5.

### Alabama — byte-identical, and still a solicitation site

The governor's release is byte-identical to the committed archive, so the 138
grants stand. `alabamarhtp.com` publishes ten closed NOFOs and no award file in
any format; its own home page says *"Year 1 initiative application periods are
now closed."*

---

## 2. Maryland — 41 award offers, $78,625,071

`R/03p_md_year1_awardees.R`, `data/reference/md_year1_awardees.csv`,
`MD_year1_awardees.xlsx`. Evidence: 5 files under `data/evidence/MD/`, archived
whole with a SHA-256 manifest — none carries a credential.

| Pool | Offers | Amount | MDH's stated pool |
|---|---:|---:|---:|
| Pillar 2 — Transformation Funds | 33 | $72,412,038 | $73M |
| Pillar 2 — Expand Primary Care Access | 8 | $6,213,033 | $6.3M |
| | **41** | **$78,625,071** | of $163.7M BP1 subawards |

46.8% of Maryland's $168,180,838 allotment.

**They are OFFERS.** Maryland's own word is "Award Offers" and its programme
table pairs each pool with an *Anticipated Project Period Start Date*. All 41
rows are `NOTICE_OF_INTENT_TO_AWARD` + `amount_confirmed = No`, which is
Oregon's posture for the same reason.

### The Texas check, run first and passed

1. **What funds it.** MDH's own procurement page: *"All partners and
   subawardees of Maryland's RHTP **cooperative agreement with the Centers for
   Medicare and Medicaid Services (CMS)** must agree to and comply with RHTP
   terms and conditions."* The programme page adds that MDH *"will award a
   series of subawards totaling $163.7 million in Budget Period 1"*, and MDH's
   2025-12-31 release states the $168M award. Asserted on every run.
2. **When.** Both solicitations were **posted after** the 2025-12-29 Notice of
   Award — 2026-04-21 and 2026-05-04 — read out of the archived page, not typed.
   Texas's `HHS0015180` closed 2025-04-24, eight months *before* its state had
   the money.

### The positive control

Maryland is running **ten** Budget Period 1 funding opportunities and has
published award offers for **two**. Its funding table carries an "Award Offers"
link exactly where a roster exists; the other eight say *"Competitive bid
process"* or are still open. `md_assert_award_index()` asserts both links
present **and refuses a third** — a tripwire in both directions.

### §0.1 — RCJ's 42nd Maryland candidate is the pool

RCJ holds 42 Maryland Tier 3 candidates against these 41 award offers. The 42nd
is **Maryland Health Care Commission, $6,300,000** — which is the MHCC Request
for Applications' own budget, i.e. the Primary Care **pool**, and is Tier 2. The
arithmetic closes exactly and is asserted:

```
41 offers + 1 pool          = 42   RCJ's candidate count
$78,625,071 + $6,300,000    = $84,925,071   RCJ's amount sum
```

An extractor that took RCJ's list at face value would have added $6.3M of Tier 2
money to a Tier 3 total. That is §0.2 in a single row.

### The hospital figure, and where it is soft

```
NAMED_HOSPITAL        : $14,678,864   6 rows
POOL_UNNAMED_HOSPITALS: $0
```

**MDH publishes no organisation-type column** — no equivalent of Oregon's or
Alaska's. Every `recipient_type` is derived from the recipient's own name, and
**24 rows, $36,558,089, fall to §8's standing fallback** (`NONPROFIT_CBO` +
`LOW` + `RECIPIENT_TYPE_INFERRED`) because MDH nowhere states their form. That
is Kansas's shape again: the uncertainty is larger than the figure.

**Nothing was promoted on this pipeline's own knowledge (§0.4)**, and the
specific rows a reviewer should look at first are named here rather than coded:

- **TidalHealth, $4,911,052** and **Meritus Health Center, $3,583,406** carry no
  hospital token in their names and so fall to the fallback. §0.3a names
  TidalHealth explicitly as a hospital this project must not code away. **$8,494,458.**
- **MedStar St. Mary's Inc, $2,522,586** — same shape.
- **Choptank Community Health System Inc, $1,976,042** and **Mountain Laurel
  Medical Center, $1,058,750** are typed `HOSPITAL_OR_SYSTEM` from `health
  system` / `medical center` and are, on the ordinary reading, FQHCs. **$3,034,792**
  in the *other* direction.
- **Children's Hospital, $1,100,000** — the name as MDH prints it.

All of them are `determination_confidence` `LOW` or `MEDIUM`, which is exactly
§7's "hospital identity inferred from name without CCN match". **The CCN match
(open blocker 5) is what resolves them.** A
`MD_RECIPIENT_FORM_NOT_STATED` row belongs in
`data/reference/classification_review_queue.csv`; it was **not added this
session**, because the session was instructed not to modify committed reference
CSVs.

---

## 3. Two shared files changed, and both were proved inert on committed data

### `R/utils_pdf_text.R` — it returned nothing on Maryland, and that is the worst failure shape

Maryland's award PDFs put every page object inside a **compressed object
stream** (`/Type/ObjStm`) and every page's drawing inside a **form XObject**
with its own fonts. The reader found `/Type/Page` nowhere, walked zero pages and
returned `character(0)` — **not an error, an empty answer**, which a caller
would read as "the state published nothing" about a $73M award list.

Four changes:

1. **Object streams are inflated** and their objects merged in; a top-level
   definition of the same number wins, because an incremental update writes the
   newer object at the top level.
2. **`Do` is followed into `/Subtype /Form` XObjects**, each decoded through its
   own fonts, in the order the operators appear; depth-capped and visit-marked.
3. **Page order comes from the document's own page tree** (`/Kids`), with
   object-number order only as a fallback.
4. **A line is a text position, not a `Td`.** Maryland's producer emits a `Td`
   per glyph and a `BT…ET` per word, so the old model returned one character per
   line. The scanner now tracks the vertical component of the text position
   (the CTM's translation, `Tm`'s f, and the accumulated `Td` ty) and breaks
   only when it changes. `rhtp_pdf_lines()` returns `page, x, y, text`;
   `rhtp_pdf_text()` is the character wrapper every existing caller uses.

And one correctness fix the re-check forced: **a `/ToUnicode` CMap can be
incomplete, and a missing entry must not delete a character.** Georgia's DCH
notices ship a single-byte font whose CMap omits `H`, `q`, `v`, `y`, `b`, `z`,
`k`, `C` and `m`. Dropping unmapped codes turned *"Crisp Regional Hospital"*
into *"Crisp Regional ospital"* and *"Colquitt"* into *"Coluitt"* — readable,
plausible, and **wrong in a recipient name**. An unmapped single-byte code now
falls back to the code itself where that is printable ASCII. The fallback is
deliberately **not** extended to Identity-H fonts, where the code is a glyph id
and guessing would produce confident nonsense instead of a gap.

**The line grouping Kansas sees did change** — KDHE wraps mid-word, so the
reader now joins *"Citizens Foundat"* / *"ion: $146,476"* into one line and
`R/03o`'s own re-join finds nothing to do. **`ks_year1_awardees.csv` rebuilds
byte-identical** — 46 rows, $80,020,499 — which is the assertion that matters,
and it is the one the tests pin.

### `R/utils_recipient_classification.R` — a county health department is local public health

Maryland awards **eight** county health departments, and the classifier gave the
two spellings of one body two different answers: *"Allegany County Health
Department"* fell through every pattern to §8's `NONPROFIT_CBO` fallback, while
*"Charles County Department of Health"* matched `department of` and came out
`STATE_AGENCY`. Neither is right. A rule for county/city public-health bodies
now precedes the government block and returns `LOCAL_GOVT_OR_PUBLIC_HEALTH` at
`HIGH` — which is the value §8 has for them and the value Oregon's own
Organization Type column gives its equivalents.

**Proof rather than inspection:** all eleven state extractors were re-run and
**every committed reference CSV came back byte-identical**; the ten workbooks
differ only in `dcterms:created` and were reverted. Oregon's three county health
departments are typed from OHA's own column, not from the name, so they do not
move either.

---

## 4. What this session did not do

- **Nothing was extracted for Georgia or Alaska.** Both belong to their own
  extractors (`R/03d`, `R/03h`) in a session that decides to move them, and a
  test asserts `ga_great_health_awards.csv` is still 139 rows and
  `ak_year1_awardees.csv` still 161.
- **No committed reference CSV was modified**, as instructed. The two new files
  (`md_year1_awardees.csv`, `state_completeness_recheck.csv`) are new.
- **`classification_review_queue.csv` was not touched**, so Maryland's
  `MD_RECIPIENT_FORM_NOT_STATED` question is recorded here and in the workbook
  rather than in the queue.

## 5. Next

1. **Extract Georgia's 21 named hospitals into `R/03d`.** It is the single
   largest improvement available: $30,277,580 from pooled to named, plus DCH's
   five named unsuccessful applicants. Both notices are already archived.
2. **Re-run `R/03h` against Alaska's grown notice** — and note that it will be
   stale again next week. Alaska is the first state that needs a *scheduled*
   re-check rather than a one-off extraction.
3. **Add `MD_RECIPIENT_FORM_NOT_STATED`** ($36,558,089, 24 rows) to
   `classification_review_queue.csv`.
4. **The queue moves on.** With Maryland extracted, `state_trigger_queue.csv`
   next ranks NE 39/35, IN 37/28, OK 35/25, NV 34/34, MI 31/31.
5. **Run the completeness re-check again** once Georgia and Alaska are folded
   in, and extend it to KS, SD, TX and MD. It found something in two of the
   seven states it covered; there is no reason to think the other four are
   different.

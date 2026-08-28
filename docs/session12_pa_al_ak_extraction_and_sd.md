# Session 12 — Pennsylvania, Alabama and Alaska extracted; South Dakota located

Zero RCJ quota. Network calls: 2 to `www.pa.gov`, 1 to `governor.alabama.gov`,
1 to `health.alaska.gov`, and ~20 to `doh.sd.gov` / `open.sd.gov` (the portal
probes and 13 detail pages). Everything else read committed archives.

---

## 0. What changed

| | Rows | Total published | Hospital rows | Hospital dollars |
|---|---:|---:|---:|---:|
| **PA** | 66 | $42,198,310 | 27 | **$24,149,111** |
| **AL** | 138 | $143,745,821 | 60 | **$66,133,019** |
| **AK** | 161 | $160,701,975 | 26 | **$43,379,541** (preliminary) |
| **SD** | 13 | $5,618,367 | 0 | $0 |

Deliverable 1 goes from two states to six. FL, GA, PA, AL, AK and SD union on
the leading 19 columns, with zero values outside §8, and `test_state_union.R`
asserts it every run.

**None of the four hospital figures is comparable to another without reading its
row.** PA's are authorized-but-undisbursed, AK's are preliminary intents to
award, AL's are 45%-rounded, SD's is zero because South Dakota's actual awards
are not published. Those distinctions are in the columns, not in a footnote.

---

## 1. Pennsylvania — the cleanest list, and a §0.3 trap in its own heading

**66 projects, 66 distinct awardees, $42,198,309.80** against DHS's stated
**$42,198,309**. Eighty cents of rounding and the count matching exactly. Up to
$1M per project, and no row exceeds it.

**Two documents, neither sufficient alone.** This is Georgia's AHEAD-roster
shape (session 10) exactly:

- the **announcement** (2026-07-23) supplies the award language — *"the first
  qualified projects to **receive** $42 million"*, *"sixty-six projects were
  **authorized**"* — and names no recipient;
- the **program page** supplies the 66 names and amounts, and its own heading
  reads ***"List of Eligible Projects"***. Read alone that is an eligibility
  list and §0.3 forbids coding it as receipt.

The announcement links to that page as the list of what it just authorized. Every
row cites both; `recipient_names_source_url` records which document supplied the
names.

**These are authorizations, not disbursements.** DHS: *"Distribution is pending
approval of selected projects."* Rows carry
`validation_source_type = NOTICE_OF_INTENT_TO_AWARD` and
`disbursement_status = PENDING_APPROVAL`.

$42.2M is **21.8% of Pennsylvania's $193,294,053.98** Year 1 award. Nothing is
inferred about the other 78%.

---

## 2. Alabama — 138 grants in prose, and two silent ways to get it wrong

Governor Ivey's 2026-08-24 release prints every recipient, amount, initiative and
county. **138 award actions, 95 distinct awardees, 5 initiatives** — the count
agreeing with both the governor's and CMS's own statements.

**The list has two shapes and one of them names no recipient.** Under each
initiative is a `<ul>` of `<strong>NAME</strong> – $AMOUNT to do the thing
(counties)`. Where a recipient won twice under one initiative, the second grant
is a bare `<p>` that follows:

```
<li><strong>Andalusia Health</strong> – This hospital has received two grants
    under this initiative, including $625,257 to ...</li>
<p>A second grant for $176,980 will purchase ...</p>
```

Reading only the `<li>` elements loses **14 award actions and $8.1M**. Reading
every block as an award invents 14 nameless recipients. Both fail silently, so
the parser walks the section in document order, carries the preceding recipient
forward, records `award_sequence = SECOND`, and refuses if a continuation appears
with no list item before it. An assertion then requires every second grant to sit
against a first grant *for the same recipient under the same initiative* — the
check that the carry-forward attached to the right one.

**45 of the 138 amounts are published rounded** (`$6.38 million`, `$1.4 million`).
They are stored as published, flagged `AMOUNT_ROUNDED_IN_SOURCE`, and never
reconstructed. The consequence stays visible:

```
the release's own figures    $143,745,821
the release's own headline   more than $144,000,000
gap                             $254,179   <- the rounding
```

Reported on the Reconciliation sheet, not closed. **ADECA publishes the
underlying award file and would settle it; `adeca.alabama.gov` and
`alabamarhtp.com` are both still refused at CONNECT.**

**The release publishes one recipient name truncated.** Its own markup reads
`<strong> Clair Community Health Clinic Inc.</strong>` — the `St.` is absent
from the *source*, not lost in the parse, and the award text places the recipient
in St. Clair County. §8 says keep the state's own language, so the name is stored
as published and the observation lives in the override table and the manifest.

$143.7M is **70.7% of Alabama's $203,404,326.54** Year 1 award.

**One row is `Unclear`:** obstetric training capacity *"at four Alabama
hospitals"* the release does not name. §10.2 `PASS_THROUGH_UNRESOLVED`, §0.3,
not imputed.

---

## 3. Alaska — the 161-vs-142 gap, closed at the source

Session 11 recorded 161 RCJ rows against CMS's stated *"142 projects"* and left
it open with a hypothesis: one line per activity type, some projects spanning
several. **That hypothesis was wrong.** The answer is Alaska's own column:

```
Project Type
  Implementation   142   <- what CMS counts
  Planning          19
  -----------------------
  total            161
```

Corroborated independently by the file's own App ID prefix — `BP1-PL` appears on
exactly 19 rows. Both figures are right and they count different things. **Nothing
was dropped and no average was taken.** An assertion pins `Implementation == 142`
and a second requires the prefix and the column to agree on every row, so a later
rolling release that breaks either makes the reconciliation a live question rather
than passing silently.

**These are notices of intent to award and Alaska says the amounts are
preliminary** — in its own sheet name (`Notice of Intent to Award`) and its own
column header (`Award Amount (Preliminary)`). `recipient_confirmed = Yes`,
`amount_confirmed = No`; §9.3 splits those two questions precisely so a
preliminary figure does not drag a confirmed recipient down with it. Rows carry
`AMOUNT_PRELIMINARY`.

**This is a snapshot of a rolling file.** Three notification dates are present
(2026-08-07, -14, -21) and DOH is releasing weekly. `notification_date` is on
every row and the manifest carries the fetch date and digest, so a later pull is
diffed rather than swapped in blind.

### 3.1 Alaska classifies its own awardees, and that outranks the name

The `Organization Type` column is semicolon-delimited and mixes organisational
form (`Hospital (all types)`) with service line (`Maternal health`), so only the
form tokens decide and an unrecognised token hard-fails. **The precedence earns
its keep immediately:** *"Alaska Hospital & Healthcare Association"* reads as a
hospital from its name alone, and it is the state hospital association.

### 3.2 But the field is set per project, not per organisation

**Seven awardees arrive with two different forms across their own rows.** The
Alaska Native Tribal Health Consortium is `Hospital (all types)` on one project
and `Tribal Health Organization` on another; Providence Health & Services-
Washington is a hospital on one row and a service line only on another.

The per-row value is kept faithful to the source and is **not harmonised in
either direction**:

- harmonising **upward** would move **$20,371,936.73** into the hospital total on
  this pipeline's authority rather than the state's;
- harmonising **downward** would discard the state's own word.

26 rows carry the new `RECIPIENT_TYPE_VARIES_IN_SOURCE` flag, the dollars at
stake are on the Reconciliation sheet, and a reviewer resolves it. **This is the
largest single open judgement in the four states extracted this session.**

---

## 4. South Dakota — the portal is the right route and the awards are not on it

South Dakota has announced two recipient-level rounds:

- **$31,500,000 to 28 projects across 20 health systems** (2026-07-23)
- **$90,000,000 to 82 rural healthcare organizations** (2026-08-19)

`open.sd.gov` was reachable this session and was searched exhaustively.
**Neither round is on it.**

### 4.1 The shape, since that was the question

`https://open.sd.gov/contracts.aspx` is an **ASP.NET WebForms search** — a POST
echoing `__VIEWSTATE` and `__EVENTVALIDATION`, with a department dropdown, three
*contains* boxes (vendor, description, contract/grant number) and an
All / Contracts-only / Grants-only filter.

Results come back as **one unpaged HTML table**: Contract/Grant Number,
Description **truncated to ~75 characters**, Vendor Name, Agency, Begin Date,
Amount. A 463-row result arrived in a single response — there is no paging to
walk.

Each row's number links to a **stable GET url**,
`contractsDocShow.aspx?DocID=<number>`, and the detail page carries the **full**
description, the vendor's city and state, and then **one of two things**:

| shape | carries | ends with |
|---|---|---|
| **contract** | `Solicitation Type` (e.g. *RFP (Linked)*, *Sole Source Services*) | *"\* If an image..."* footer |
| **grant** | *no* solicitation type | a **CFDA** block — `93.798`, which is RHTP itself |

So the search finds the series and the detail pages are what you quote. Both are
archived.

### 4.2 The four probes, and what they found

`Rscript R/03i_sd_rht_contracts.R --probe` re-runs these:

| probe | rows | total | largest |
|---|---:|---:|---:|
| `RHT` number series, all agencies | **13** | **$5,618,367** | $1,462,802 |
| `"Rural Strong"` in the description | **0** | — | — |
| `"Rural Health Transformation"` | 5 | $1,436,166 | $567,350 |
| DOH grants, no filter at all | 463 | $39,411,509 | **$2,600,000** |

An 82-organisation, $90M round is not hiding in a 463-row list whose largest
single entry is $2.6M and is not RHTP.

### 4.3 What was extracted, and how it is prevented from being misread

The 13 `RHT` contracts **are** real, executed, recipient-level RHTP award actions
on a primary source (§8 `PROCUREMENT_PORTAL_POSTING`) and they belong in the
record. They are also **administrative spend** — programme management,
consulting, evaluation, workforce training — and **zero dollars reach a
hospital**.

Four guards keep the small number attached to its explanation:

1. `rhtp_sd_reconcile()` names **both unpublished rounds and their recipient
   counts in its own output**, alongside a `-- NOT EXTRACTED, BECAUSE NOT
   PUBLISHED --` divider.
2. Every row's `determination_basis` states it is not part of the announced
   rounds, and an assertion **requires** that sentence — because once a row is
   separated from this file, the sentence in the row is all there is.
3. The workbook carries an **"Announced not published"** sheet.
4. An assertion **hard-fails if the series ever totals more than $20M**: at that
   point the framing is wrong and must be rewritten rather than quietly reporting
   a large figure it describes as small.

**The two announcements themselves could not be archived.** They are on
`news.sd.gov`, still refused at CONNECT (403). Only `doh.sd.gov` and
`open.sd.gov` opened.

---

## 5. The §8/§10.2 rules now live in one file

`R/utils_recipient_classification.R`. Sessions 9–11 coded Georgia and Florida one
state at a time and the §8 `recipient_type` question had to be settled twice.
Four more states arriving at once would have given it a fifth answer.

**Rules match the recipient NAME only** (§0.3a — judge the recipient, never the
activity), **whole string, DBA half included**. That is the rule that moves
money:

| would code as | actually is |
|---|---|
| The City of York Health Care Authority DBA Hill **Hospital** of Sumter County | a city → **a hospital** |
| Wilcox **Hospital** Board DBA J. Paul Jones Rural Emergency **Hospital** | a board → **a hospital** |
| **UAB** St. Vincent's Blount | a university → **a hospital** (curated override) |

**Names the ordered patterns get wrong go in an override table with a stated
reason each**, scoped by state. Names nothing resolves fall back to
`NONPROFIT_CBO` + `LOW` + `RECIPIENT_TYPE_INFERRED` — the convention session 10
settled on Georgia's answer.

**Two overrides exist specifically to stop inflation.** `AltaPointe Health
Systems` and `CarePath Behavioral Health` would read as hospital systems from the
`Health Systems` token; AltaPointe *does* operate psychiatric hospitals, and
**whether the entity that received these grants is that operator is exactly what
the release does not say**. Both take the fallback and a `LOW` confidence. This
is §0.3 — the single most attackable error — met head on.

### 5.1 The in-kind rule was under-firing and was rewritten

It was a list of specific phrasings. On real data the Alaska Stroke Coalition's
*"statewide AI imaging network across 21 acute care hospitals"* and AHHA's
assessments for **three named critical access hospitals** both came out
`NON_HOSPITAL` — which says the source is *silent* about hospitals when it is the
opposite.

Now: any hospital mention by a non-hospital recipient is `IN_KIND_BENEFIT` unless
the narrower pass-through test fires first. **No distributed total moves either
way** (§10.2 in-kind is `No`). What changes is that those dollars stay visible,
which is why §10.2 has the code at all.

---

## 6. Three `flag_reason` codes added, deliberately

§2 says do not invent codes mid-session; session 10 took one documented
exception. These are three, each for a condition no existing code covers, each
written into `vocabularies.csv` with full notes, and **every state assert now
validates `flag_reason` against the vocabulary** — so a fourth invented code
fails at the state that invents it.

| code | for |
|---|---|
| `AMOUNT_ROUNDED_IN_SOURCE` | the source published the amount rounded (AL, 45 rows). Distinct from `AMOUNT_MISSING` and from `AMOUNT_PRELIMINARY` — this figure is final, just rounded. |
| `AMOUNT_PRELIMINARY` | the source says the amount is not final (AK, all rows) |
| `RECIPIENT_TYPE_VARIES_IN_SOURCE` | one named recipient carries different forms on different rows of one document (AK, 26 rows) |

---

## 7. One provenance defect fixed, and one left alone

The manifests digest the body the server sent; `writeLines()` **appends a
trailing newline**, so the archived file was one byte longer than what was
hashed. A reader verifying an archive would get a mismatch.

PA, AL, AK and SD now `writeBin()` the exact bytes, and a test in each **re-hashes
the file on disk** and compares.

**The same off-by-one is present in the GA and CMS archives committed in earlier
sessions.** They are not re-fetched here: re-fetching to fix a digest could
quietly pick up changed page content, which is a worse problem than the one being
fixed. Worth doing deliberately, with a diff, in a session that can check what
came back.

---

## 8. Hosts

**Opened this session:** `www.pa.gov`, `governor.alabama.gov`,
`health.alaska.gov`, `doh.sd.gov`, `open.sd.gov`.

**Still refused at CONNECT (403):** `news.sd.gov` (holds both South Dakota award
announcements), `adeca.alabama.gov` and `alabamarhtp.com` (ADECA's award file,
which would give Alabama's 45 rounded amounts to the dollar),
`ruralhealthtransformation.sd.gov`.

**`web.archive.org` re-tested and still unreachable, with the failure unchanged
from session 11.** The CONNECT tunnel is negotiated, the Client Hello goes out,
and the peer resets before any certificate:

```
* Establish HTTP proxy tunnel to web.archive.org:443
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* Recv failure: Connection reset by peer
```

The proxy logs **no policy denial** for it — which is still what separates this
from a blocked host. The apex `archive.org` is still a policy denial
(`connect_rejected`, gateway answered 403 to CONNECT), logged three times this
session. So the position is exactly where session 11 left it: permitted but
unreachable, and dying upstream of the policy. Georgia's 80/7 split stays an
inference and `PHASE_ATTRIBUTION_INFERRED` stays on the seven appended rows.

### The ask, ranked

1. **`news.sd.gov`** — 110 named recipients and $121.5M behind two pages.
2. **`adeca.alabama.gov`** / **`alabamarhtp.com`** — turns 45 rounded Alabama
   amounts into exact ones and closes the $254,179 gap.
3. **`web.archive.org`** + apex **`archive.org`** — still the only route to
   Georgia's July roster snapshot.

---

## 9. What this leaves open

- **Alaska's 7 varying-form awardees, $20.4M.** A reviewer decision, flagged and
  quantified, not a code change.
- **Alabama's 45 rounded amounts**, worth $254,179 in aggregate.
- **South Dakota's 110 recipients**, announced and unpublished.
- **Pennsylvania's remaining 78%** of Year 1, not yet awarded.
- **19 Alabama and 7 Pennsylvania recipients** still on the §8 `LOW` fallback —
  named, confirmed, form undetermined from the source.
- The **AHA Annual Survey / CMS Provider of Services extracts** are now the
  binding constraint they were becoming. **113 hospital rows** across PA, AL and
  AK are ready for a CCN match, on top of Georgia's 87. Until those extracts
  land, every `determination_confidence` is capped at `MEDIUM` (§7: `HIGH`
  requires a CCN match).

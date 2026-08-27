# Stage 3 run — CMS FY2026 allotments, `/documents` mining, and the registry worksheet

**Session 5 · 2026-08-27 · zero RCJ quota consumed (one call to `cms.gov`)**

Three deliverables, in the order the session prompt set them:

1. `data/reference/cms_fy2026_allotments.csv` — the §7.1 anchor, parsed from CMS.
2. The §6.4 `/documents` mining pass, with per-state candidate counts.
3. `data/reference/state_source_registry_worksheet.csv` — the §7.2 candidates
   laid out for offline verification.

Stage 4 was not started. §9.11 is still an unresolved premise test.

---

## 1. §7.1 — the CMS FY2026 allotment anchor

### What was built

`R/03_state_registry.R` fetches the CMS December 2025 press release, archives it
verbatim, parses the one table it carries, asserts §13.17 **before** writing, and
emits the anchor file.

```
Rscript R/03_state_registry.R --allotments
```

| Artefact | Contents |
|---|---|
| `data/raw/cms/2026-08-27/cms_fy2026_allotment_table.html` | The allotment `<table>` verbatim, 8,033 bytes, committed |
| `data/reference/cms_fy2026_allotments.csv` | 50 rows: `state`, `state_name`, `fy2026_allotment`, `fy2026_allotment_published`, `source_url`, `source_fetched` |

### The figures

| | |
|---|---|
| States | **50**, exactly matching `cms_states.csv` |
| Total | **$10,000,000,003** — $10B plus CMS's own $3 of rounding across 50 states |
| Minimum | **NJ $147,250,806** |
| Maximum | **TX $281,319,361** |
| Mean | $200,000,000 |

Every §7.1 expectation holds on the nose. No state name failed the join to the
CMS state vocabulary, and no amount failed to parse.

### Why it is parsed rather than typed

§7.1 forbids transcription because this file is the reconciliation anchor for
§13.3, §13.4 and §13.17 — a typo in it corrupts every figure downstream. So the
parse is defensive in three places:

- **The page carries exactly one `<table>`**, asserted against config rather
  than assumed. A CMS redesign that adds a second table fails loudly instead of
  silently parsing the wrong one.
- **The header row is dropped by matching it**, not by `slice(-1)`. If rvest
  ever consumes a `<thead>` first, a positional drop would eat Alabama.
- **State codes come from `cms_states.csv` by name join.** The press release
  publishes names only; minting a name→code map here would create a second,
  divergent state vocabulary, which is the thing §7.1 exists to prevent.

The archive is committed, so the parse is reproducible offline in a later
session even if CMS edits the page. The tests parse the archive, never the
network.

**What is archived is the `<table>`, not the page.** The page is 66 KB of CMS
site chrome around a 5 KB table, and its Drupal settings blob carries a
third-party Mapbox token — CMS's to publish, not ours to redistribute, and
GitHub push protection rejects it, correctly. The archive header records the
source URL, the fetch time, the HTTP status, the full response size and its
**SHA-256** (`59febe38444d…`), so the provenance chain still closes: re-fetch
the page and compare the digest. The "exactly one table" assertion runs at
**fetch** time against the live response, so the archived table is never one
picked arbitrarily out of several.

`fy2026_allotment_published` keeps the verbatim `"$281,319,361"` string beside
the parsed number, so a disputed figure can be checked without re-reading HTML.

### One config gotcha, fixed

R's YAML reader silently coerces a bare `10000000000` to `NA` — it overflows a
32-bit integer. `qa$allotment_total_usd` is therefore written `1.0e10`, and every
QA bound is coerced through a `qa_num()` helper that fails with an actionable
message rather than crashing on an `NA` comparison.

---

## 2. What the anchor moved

Re-running Stage 2 with the anchor live switched on **§6.1 tier rule 3** and the
**§6.2 allotment ceiling**, both of which had been inactive since Session 4.

### `STATE_ALLOTMENT`: 0 rows → 274 rows, all 50 states

| Movement | Rows |
|---|---:|
| `/documents` `UNASSIGNED` → `STATE_ALLOTMENT` | 225 |
| `/opportunities` `SOLICITATION` → `STATE_ALLOTMENT` | 49 |
| **Total reclassified** | **274** |

Nothing left Tier 3. Rule 2 precedes rule 3, so a named recipient always wins —
a subaward that happens to equal its state's allotment stays a subaward. Tier 3
is byte-identical to Session 4: **1,016 clean records, $2,027,946,582 announced**,
still RCJ's unvalidated claim (§0.1).

Full tier table after the re-run:

| Tier | PASS | FLAGGED | QUARANTINED |
|---|---:|---:|---:|
| `STATE_ALLOTMENT` | 257 | 15 | 2 |
| `SOLICITATION` | 1,377 | 143 | 7 |
| `SUBAWARD` | 1,016 | 347 | 6 |
| `UNASSIGNED` | 1,679 | 195 | 108 |

The 49 `/opportunities` rows are the clearest win. They are literally titled
*"&lt;State&gt; Federal RHTP Award (FY2026-FY2030)"* with RCJ type `AWARD`, and
had been sitting in Tier 2 as solicitations. They are the CMS→state allotments —
Tier 1 by definition (§0.2). Missouri's $216,000,000 hub announcement, named in
Session 4's blocker 1, is now Tier 1 across five documents.

**274 Tier 1 records is not a contradiction of §13.3's "50 rows".** The Tier 1
*reference table* is `cms_fy2026_allotments.csv` — 50 rows, CMS-anchored, and
what the §11 workbook's State Allotments sheet is built from. The 274 record-table
rows are RCJ records *about* those allotments. Tiering them correctly is what
keeps them out of Tier 3; it does not make them 274 separate allotments.

### The allotment ceiling caught one record immediately

| State | Amount | Allotment | Awardee |
|---|---:|---:|---|
| NH | $1,898,965,390 | $204,016,550 | `AmeriHealth Caritas New Hampshire Inc.; Boston Medical Center Health Plan, Inc. d/b/a WellSense Health Plan; Granite State Health Plan Inc. d/b/a New Hampshire Healthy Families` |

Three managed care organisations in one `awardeeName`, carrying 9.3× the state's
entire five-year allotment. Flagged `AMOUNT_EXCEEDS_STATE_ALLOTMENT`, routed to
review. This is exactly the check §6.2 wanted and it could not fire before today.

### A defect the anchor exposed: unchanged rows froze their classification

Landing the anchor should have moved 274 rows. On the first re-run it moved
**zero**, and the record table still carried Session 4's tiers.

`rhtp_apply_change_detection()` was keeping the prior row verbatim for any record
whose `rcj_record_hash` was unchanged, refreshing only `last_seen`. The hash
covers RCJ payload fields only — correct, and deliberately so (§6.3), since a
derived field must not make a record read as changed. But the stored row also
carries **this pipeline's** derived columns: `award_tier`, `tier_basis`,
`flag_reason`, `qa_status`, `rules_version`. Those are a build output, not a fact
about the record.

Consequences if left:

- A reference table landing, or any rules change, would be invisible.
- §13.10 — *"`rules_version` is identical across all rows in a build"* — would
  fail silently on a table quietly mixing rule generations.

**Fix.** A live `UNCHANGED` row is now replaced by this run's classification of
the same payload, carrying `first_seen` forward. `superseded_by` is *not* set:
superseding tracks changes in the **data** (§6.3), and re-deriving a column from
unchanged input is not one. Superseded historical rows are untouched — they keep
the classification they were published with.

The run now reports what moved, so a rules change is announced rather than
discovered:

```
  reclassified    : 274 (unchanged data, new tier under rules 0.1.0-preflight)
```

The set is written to `data/interim/stage2_reclassified.rds` with each row's
prior and current tier and `rules_version`.

---

## 3. §6.4 — mining `/documents` for awards RCJ failed to parse

### The rule as built

All four §6.4 conditions must hold:

1. `source_doc_category` is `AWARD_ANNOUNCEMENT` or `REFERENCE`
2. a named organisation appears in the title or description, passing **both**
   the §6.1 legal-entity test and the full named-recipient test
3. a dollar figure is present
4. **no `/awards` record shares that `sourceDocument.id`**

Quarantined records are excluded before mining: a HRSA fact sheet or a junk state
code is not made minable by containing a hospital's name.

**Finders find, rules decide** (the §9.1 discipline, applied early). Two regex
shapes locate *candidate* organisation spans; neither decides anything. Every
span is then put through the §6.1 tests, which are the arbiters. The §6.1 rule 1
override was factored out as `rhtp_legal_entity_test()` rather than
reimplemented, so both callers move together when the pattern table grows.

The finder needed two shapes, not one. American health care writes both:

| Shape | Example |
|---|---|
| Marker **trails** the name | `Parrish Medical Center`, `Grady Memorial Hospital` |
| Marker **leads** the name | `University of Nevada, Reno`, `Foundation for Healthy Communities` |

A trailing-only finder misses every academic medical centre and every
pass-through foundation — including New Hampshire's, which is a §7.3
pass-through administrator. Adding the leading shape found 2 more candidates.

Recall is favoured over precision here by design: a false positive is a review
queue row a human dismisses in seconds, while a false negative is an award RCJ
failed to parse that we then also fail to surface — which is the whole point.

### Result: 38 candidates across 19 states

The spec's known live example is caught:

> `FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants to
> Promote Rural Health Workforce Development in First Year of Florida's Rural
> Health Transformation Program`
> → mined org `Parrish Medical Center`, category `REFERENCE`

Note it carries **no dollar sign at all**. The money detector handles both
`$52,000,000` and a bare `52 Million`, and cannot match a bare four-digit year.

### Per-state candidate counts

| State | `/awards` parsed | Tier 3 clean | Mined candidates | Coverage status |
|---|---:|---:|---:|---|
| GA | 115 | 109 | 14 | `PARSED_PLUS_CANDIDATES` |
| NH | 27 | 13 | 5 | `PARSED_PLUS_CANDIDATES` |
| HI | 1 | 0 | 2 | `PARSED_PLUS_CANDIDATES` |
| TX | 72 | 64 | 2 | `PARSED_PLUS_CANDIDATES` |
| **FL** | **0** | **0** | **1** | **`UNPARSED_DATA_EXISTS`** |
| **NC** | **0** | **0** | **1** | **`UNPARSED_DATA_EXISTS`** |
| **NJ** | **0** | **0** | **1** | **`UNPARSED_DATA_EXISTS`** |
| **TN** | **0** | **0** | **1** | **`UNPARSED_DATA_EXISTS`** |
| CA, CO, IA, KS, MI, MO, MT, ND, NE, OR, VA | ≥1 | varies | 1 each | `PARSED_PLUS_CANDIDATES` |

The full 50-row table is `data/interim/stage2_mining_coverage.csv`, which is the
§11 Coverage sheet's two dimensions in the shape Stage 6 needs.

### The eleven zero-award states, resolved into two groups

§4.1 named eleven states where `/awards` returns nothing. Mining splits them:

| Group | States | Meaning |
|---|---|---|
| `UNPARSED_DATA_EXISTS` | **FL, NC, NJ, TN** | Award-shaped data is in `/documents` and RCJ failed to extract it |
| `NO_DATA` | AR, KY, MA, MN, NY, SC, WY | Nothing award-shaped surfaced from RCJ at all |

This is the §11 distinction working: *"data exists, source failed to extract"* is
a materially different message than *"no data"*, and only the first four are
resolvable by looking harder at what RCJ already holds.

Across all 50 states: 24 `PARSED`, 15 `PARSED_PLUS_CANDIDATES`,
4 `UNPARSED_DATA_EXISTS`, 7 `NO_DATA`.

### Nothing was promoted

All 38 candidates carry `flag_reason = UNPARSED_AWARD_CANDIDATE` and keep the
tier the pipeline gave them. 34 sit on `UNASSIGNED` records. The other 4 sit on
records that rule 3 tiered `STATE_ALLOTMENT` because their amount matches their
state's CMS allotment — including `NH - 2026 - Foundation for Healthy
Communities (FHC).pdf`, the §7.3 pass-through administrator. The flag is a review
signal, never a tier claim, the same discipline §6.2 applies to
`SOURCE_IS_PLAN_NOT_AWARD`.

**No candidate becomes a `SUBAWARD` without a human or §9.3 resolution**
(§13.18). The premise of §6.4 is that RCJ's extraction of this text failed; a
second automated extraction of the same text has earned no more trust.

### Known noise

`NJ - 2026 - NJ RHT Resource Directory` yields the span
`Babyscripts Yes Barr Campbell Family Yes Foundation` — a directory table read as
running prose. It is a false positive of the finder, it is one review-queue row,
and it is the shape of noise to expect from a resource directory. The other three
`UNPARSED_DATA_EXISTS` candidates are clean: `Parrish Medical Center` (FL),
`University of North Carolina Hospitals` (NC), `Tennessee Hospital Association`
(TN).

---

## 4. §7.2 — the registry verification worksheet

```
Rscript R/03_state_registry.R --worksheet
```

| Artefact | Contents |
|---|---|
| `data/reference/state_source_registry_worksheet.csv` | 151 rows, committed |
| `output/state_source_registry_worksheet_2026-08-27.xlsx` | Same, formatted for the browser work |

**151 candidate hosts across all 50 states. No state has zero candidates.**

| Candidates per state | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---:|---:|---:|---:|---:|---:|
| States | 9 | 10 | 10 | 15 | 4 | 2 |

### Columns

The left block is machine-generated context; the right block is empty and
belongs to the verifier.

| Column | Source |
|---|---|
| `state`, `candidate_rank`, `url_host`, `example_url` | `/activity.siteUrl`, ranked by how often the host appears |
| `sample_source_title` | The most-repeated source document title among records resolving to that host — 107 of 151 rows have one |
| `n_activity_references`, `n_document_urls`, `last_seen_activity` | Evidence of how live the host is |
| `verification_status` | `UNVERIFIED` on every row, by construction |
| `lead_agency`, `program_page_url`, **`award_posting_url`**, **`pass_through_admin`**, `pass_through_admin_url`, **`last_verified`**, `verified_by`, `verification_note` | **Empty. Yours.** |
| `instruction` | What to do with this row |

`sample_source_title` exists so a verifier can tell a procurement portal from a
press-release archive without opening every one. It is RCJ's text — a search aid,
never quotable (§0.1, CLAUDE.md §6).

**Every verification column is emitted empty and this is tested.** §7.2: *"the
generated candidates are a starting point, never the final registry. Every row
still needs `last_verified` set by a person who loaded the URL."* Pre-filling
`award_posting_url` from the candidate host would manufacture precisely the
unverified registry §7.2 exists to prevent, and §13.12 makes registry
completeness a deliverable gate.

The workbook freezes the header, autofilters, tints the eight verification
columns, and sets column widths explicitly so a URL can be typed into them.

### The seed is doing real work

Virginia's six candidates come back ranked with **`vhhafoundation.org` first** —
the VHHA Foundation, the §7.3 pass-through administrator whose award postings
live off the state domain entirely, ahead of `dmas.virginia.gov`. Nobody
compiling 50 URLs by hand would have known to look for it.

### What the verifier does next

Collapse 151 candidates to 50 confirmed rows in
`data/reference/state_source_registry.csv`. `rhtp_validate_state_registry()` is
built and tested against that file: it checks the §7.3 schema, rejects any state
code outside the CMS 50 (§13.14), and reports states with no verified
`award_posting_url` as **deliverable gaps, never silent skips** (§13.12). Passing
`require_complete = TRUE` turns the gap into the hard stop Stage 4 needs.

**Compile Florida by hand first.** Its Tier 3 data runs through AHCA's numbered
RFAs on a procurement portal, and the single mined candidate confirms the data
exists — but no amount of RCJ work will produce it.

`fy2026_allotment` is deliberately **not** a registry column. It comes from
`cms_fy2026_allotments.csv` by join. Two files carrying the same 50 figures is
two files that can disagree, and one of them is the reconciliation anchor.

---

## 5. Tests

`Rscript tests/run_tests.R` — **316 assertions, all passing, zero quota.**

| File | Assertions | Added this session |
|---|---:|---|
| `test_01_retrieve_rcj.R` | 44 | — |
| `test_02_normalize.R` | 202 | §6.4 mining, the money and organisation finders, the standalone legal-entity test, tier rule 3 against the live anchor, and change-detection re-derivation |
| `test_03_state_registry.R` | 70 | **New.** The CMS parse against the committed archive, every §13.17 failure mode, the worksheet, and §7.3 registry validation |

The CMS tests parse the **committed archive**, never the network, so they run
offline at zero quota and pin the exact figures — `NJ 147250806`,
`TX 281319361`, `MO 216276818`, total `10000000003`.

Every §13.17 failure mode is tested to fail: 49 rows, an `NA` amount, a
duplicated state, a state code outside the CMS 50, a factor-of-ten transcription
error, and a bound drifting out of range. The bound tests perturb by $10M —
enough to break the 2% bound, small enough to stay inside the 1% total tolerance,
so it is genuinely the bound check firing rather than the total check catching it
first.

---

## 6. Files written

**Reference (committed)**
- `data/reference/cms_fy2026_allotments.csv` — **new**, the §7.1 anchor
- `data/reference/state_source_registry_worksheet.csv` — **new**, 151 rows
- `data/reference/vocabularies.csv` — `UNPARSED_AWARD_CANDIDATE` added

**Raw (committed, §0.5)**
- `data/raw/cms/2026-08-27/cms_fy2026_allotment_table.html` — **new**, the table verbatim plus a provenance header carrying the full page's SHA-256

**Interim (committed)**
- `data/interim/stage2_mining_candidates.{rds,csv}` — **new**, 38 rows
- `data/interim/stage2_mining_coverage.{rds,csv}` — **new**, 50 rows
- `data/interim/stage2_reclassified.rds` — **new**
- `data/interim/stage2_record_table.rds` — re-run with Tier 1 live

**Output**
- `output/state_source_registry_worksheet_2026-08-27.xlsx` — **new**

**Logs**
- `logs/normalize_manifest.csv` — `n_mined_candidates` added to the pinned
  schema. The three historical rows carry `NA`, not `0`: the mining pass did not
  exist for those runs, so no count was computed, and writing `0` would claim a
  measured absence of candidates.

---

## 7. What this unblocks, and what it does not

**Closed.** Session 4's blocker 1. `STATE_ALLOTMENT` is populated across all 50
states, §6.1 rule 3 and the §6.2 allotment ceiling are both live and have both
already fired, and §13.3/§13.4/§13.17 now have an anchor to reconcile against.

**Open.** The registry itself. 151 candidates is not 50 verified rows, and
§13.12 makes that a deliverable gate: **a state with no verified
`award_posting_url` cannot be validated in Stage 4 at all.** With
`state_source_url` present on only 13% of `/awards` and 6% of `/documents`
records, the registry — not RCJ — is how Stage 4 finds anything.

**Still untested.** §9.11. Whether state documents name subrecipients at all is
the premise the entire §9.3 corroboration design rests on, and it needs a person,
a browser and an hour before any Stage 4 code is written.

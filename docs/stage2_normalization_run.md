# Stage 2 — Normalization: build and first run

**Session 4, 2026-08-27.** Build spec §6. Input:
`data/raw/rcj/2026-08-27/` (the Session 3 national pull). **Zero API quota
consumed** — every function in this stage reads from disk.

Code: `R/02_normalize.R`. Tests: `tests/testthat/test_02_normalize.R`
(136 assertions, all passing; run with `Rscript tests/run_tests.R` alongside
Stage 1's 44).

---

## 1. Reporting task — the 11 states absent from `/awards`

Eleven of the 50 CMS states have **zero** records in the national `/awards`
pull. **Florida is one of them.**

| State | `/awards` | `/documents` | `/opportunities` | `/activity` | RCJ `/states.awardeeCount` |
|---|---:|---:|---:|---:|---:|
| AR | 0 | 33 | 5 | 15 | 0 |
| **FL** | **0** | **29** | **12** | **55** | **0** |
| KY | 0 | 43 | 10 | 13 | 0 |
| MA | 0 | 6 | 1 | 7 | 0 |
| MN | 0 | 84 | 19 | 28 | 0 |
| NJ | 0 | 11 | 6 | 10 | 0 |
| NY | 0 | 18 | 3 | 29 | 0 |
| NC | 0 | 54 | 10 | 19 | 0 |
| SC | 0 | 25 | 8 | 22 | 0 |
| TN | 0 | 61 | 21 | 74 | 0 |
| WY | 0 | 22 | 7 | 8 | *absent from `/states`* |

These eleven states hold **768 records on the other three endpoints**, so they
are not missing from RCJ — only from its awardee-level data.

### Florida: the site display was right, and the data agrees with it

The question was whether RCJ's site display was wrong or its data was. It is
neither: they agree. `/states` reports Florida with `awardeeCount: 0` and
`awardTotal: 0`, which is exactly what `/awards` returns. The same holds for
all ten other states. **RCJ is internally consistent here — it genuinely has
no awardee-level extraction for these states.** The pilot design note in §14
("RCJ shows 11 opportunities and 0 awardees") still stands; the opportunity
count has since moved to 12 and the awardee count has not moved at all.

**The gap is RCJ's extraction, not Florida's disclosure.** Florida has
published awardee-level information that RCJ holds but never turned into an
award record. Its `/documents` feed carries:

> `FL - 2026 - Parrish Medical Center Awarded More Than 52 Million in Grants to Provide…`

— a named hospital and a named amount, filed under category `REFERENCE` and
never extracted into `/awards`. Florida runs RHTP through AHCA on numbered
RFAs (`AHCA RFA 036-25/26 RHTP Rural Satellite Clinics`,
`AHCA RFA 038-25/26 RHTP Health and Lifestyle`), i.e. a procurement portal
rather than a program page — precisely the §7.3 case where `award_posting_url`
differs from `program_page_url`.

This is the §14 pilot question for Florida, answered before the pilot starts:
**Florida's Tier 3 data has to come from AHCA directly. RCJ will not supply
it.** Budget the Stage 3 registry work accordingly.

### What is recoverable in the other ten

Across all eleven states there are 14 `AWARD_ANNOUNCEMENT` documents, and
almost every one is **Tier 1, not Tier 3** — the CMS-to-state allotment:

- `MN - 2026 - Minnesota awarded $193 million for first year of RHTP`
- `NC - 2026 - CMS awards North Carolina $213 million through RHTP`
- `SC - 2026 - South Carolina Awarded $200 Million in RHTP Funding`

So the eleven states are not merely missing from `/awards`; they have close to
**no Tier 3 candidates anywhere in RCJ**. Completeness for them is bounded by
the §7 state registry, exactly as §0.1 predicts.

One extraction defect found while checking this, worth a Stage 3 fixture:

> `WY - 2025 - **Utah** RHTP Cooperative Agreement Award: $195.7 million for Year 1`

— a Utah document filed under the Wyoming state code. Wyoming is the state
that `/states` omits entirely (open blocker 1), so its records get the least
validation of any state's.

---

## 2. What Stage 2 produces

| Output | Contents |
|---|---|
| `data/interim/stage2_record_table.rds` | The effective-dated record table — every version ever seen, nothing overwritten |
| `data/interim/stage2_change_set.rds` | `NEW` + `CHANGED` rows, the Stage 4 queue input |
| `data/interim/stage2_dedup_collisions.rds` | §6.3 content and re-opened-solicitation collisions |
| `data/interim/stage2_state_sources.rds` | State URLs recovered from `/activity` |
| `data/interim/stage2_rcj_state_summary.rds` | RCJ's `/states` figures — **cross-check only, never authoritative** |
| `data/reference/state_source_registry_candidates.csv` | §7.2 machine-generated Stage 3 seed |
| `logs/normalize_manifest.csv` | Per-endpoint run record, schema-pinned |

### Tier assignment, first run

| Tier | PASS | FLAGGED | QUARANTINED | Total |
|---|---:|---:|---:|---:|
| `SOLICITATION` | 1,426 | 143 | 7 | 1,576 |
| `SUBAWARD` | 1,016 | 347 | 6 | 1,369 |
| `UNASSIGNED` | 1,924 | 173 | 110 | 2,207 |
| **Total** | | | | **5,152** |

`STATE_ALLOTMENT` is **0 rows, and that is a known gap, not a result** — see
§4 below.

**Tier 3, clean: 1,016 records across 38 states, $2.03B announced.** Every one
of those dollars is RCJ's unvalidated claim (§0.1) and none of it is a finding
until Stage 4 ties it to a state primary source.

### Flags raised

| Flag | n | Disposition |
|---|---:|---|
| `SOURCE_DOCUMENT_UNRESOLVED` | 253 | FLAGGED |
| `EVENT_SCHEDULE_BLEED` | 136 | FLAGGED |
| `AMOUNT_IMPLAUSIBLE_LOW` | 108 | FLAGGED |
| `JUNK_STATE_CODE` | 96 | **QUARANTINED** |
| `REOPENED_SOLICITATION` | 70 | FLAGGED |
| `STATE_AGENCY_AS_AWARDEE` | 31 | FLAGGED |
| `PROGRAM_NAME_AS_AWARDEE` | 28 | FLAGGED |
| `SOURCE_IS_PLAN_NOT_AWARD` | 28 | FLAGGED |
| `PROVENANCE_MISMATCH` | 27 | **QUARANTINED** |
| `AMOUNT_IMPLAUSIBLE_HIGH` | 21 | FLAGGED |
| `CONTENT_DUPLICATE` | 15 | FLAGGED |
| `PAGE_CHROME_TITLE` | 12 | FLAGGED |
| `DUPLICATE_RECORD_ID` | 4 | FLAGGED |
| `NON_RHTP_SELF_DECLARED` | 2 | **QUARANTINED** |

Nothing is dropped. Every filtered record keeps its row, its reason, and its
original values.

### The four CLAUDE.md §10 findings, resolved

- **`RC` is a junk state code** — 54 `/documents` records, quarantined
  `JUNK_STATE_CODE`. `US` adds another 42 (40 documents, 2 opportunities);
  96 total. Validated against `data/reference/cms_states.csv`, never mapped.
- **`/awards` covers 39 of 50 states** — reported in §1 above.
- **`/activity` carries `siteUrl` on all 1,787 records** — turned into the
  §7.2 registry seed. 151 candidate hosts, and **all 50 states have at least
  one**, which is a better starting position than §7.2 assumed. Virginia's
  seed surfaces `vhhafoundation.org` alongside the state domain, i.e. the
  pass-through administrator §7.3 flags, without anyone knowing to look.
- **Delaware's Stage 0 defects** — all four are pinned test fixtures. The
  HRSA fact-sheet rows quarantine, `federalAmount: 1` flags, tier mixing
  splits correctly, and the Governor Meyer event bleed is caught.

---

## 3. Five places the spec's rules did not survive contact with 50 states

Each of these was written from Delaware's 15 records and broke on the national
pull. All five are documented in the code at the point of the deviation.

### 3.1 A uniform grant programme is not a content duplicate

§6.3 specifies dedup on `(state, federalAmount, activity_type)`. At national
scale that produced **927 collisions**, and the largest were not duplicates at
all: Oregon awarded exactly **$100,000 to 99 separately named providers** and
Georgia **$750,000 to 80**. A state running a standard-amount grant programme
collides with itself on every row.

The discriminator added: a group of N rows with N distinct awardees that all
pass the §6.1 named-recipient test is a programme, not a duplication. Anything
else — a repeated awardee, or awardees that are pools and programmes — still
collides. Delaware's three $10M `POPULATION_HEALTH` rows have three distinct
awardees that all *fail* the test, so they still collide, which is the case
§6.3 was written for.

`source_endpoint` was also added to the key. Without it a document *about* an
award collides with the award. Content dedup now runs on `/awards` only —
§6.3's subject is "the same award reported through two source documents", and
Tier 1 reconciles against CMS directly (§13.3).

**Content duplicates: 927 → 15.** The survivors include Delaware's $10M trio
and Alaska's genuinely repeated awardees. The collisions file holds 85 rows in
total: 15 content duplicates plus 70 re-opened solicitations, the latter
dominated by West Virginia's repeated `RHT-AFA-*` numbers — the §6.3 trap,
caught.

### 3.2 The §6.1 word list catches real institutions

`program` and `expansion` are two of the spec's programme-name patterns. They
are also how American health care names itself:

- `Rural Health Medical Program Inc.` — an Alabama FQHC
- `University of Nevada, Reno General Surgery Residency Program` — one of ten
  Nevada residency and fellowship awards
- `Dignity Health Dominican Hospital … Expansion Program`

All are named recipients, and §6.1's own "do not over-filter" instruction says
so. A **legal-entity override** now rescues them: a corporate suffix
(`Inc`, `LLC`, `Corp`, `Association`), a named academic institution, or a named
provider organisation beats a programme-name match.

The override is itself overridden by an explicit statement that the recipient
is unresolved, which beats everything in both directions:
`16 Strategically Located Rural Hospitals (unnamed, subrecipient group)`
contains `hospitals` and still names nobody; `Various Rural Health Clinics`
contains `clinics` and still names nobody. Patterns:
`data/reference/legal_entity_patterns.csv`.

The state-agency test also now runs **first**, so no entity override can
rescue the administering agency —
`Oklahoma Health Care Authority (OHCA) - EHR expansion` is still the agency.

### 3.3 The state-agency pattern was matching across a whole name

The first agency pattern allowed anything between the state name and the
agency word. That swept up
`Oregon Health & Science University … - Department of Neurology` and
`Missouri Emergency Medical Services Association (in partnership with Missouri
Department of Health…)` — both real, non-agency recipients. The agency word
must now follow the state name directly.

### 3.4 A plan-source rule, added and then twice narrowed

Delaware's `Rural Community Health Hubs (Mobile Health Units)` ($10M) passes
every §6.1 pattern and is still not a recipient — it is a line item in
`DE - 2026 - Delaware RHT Plan Application`. §9.2 already says a source that is
"a projection or plan rather than an award action" cannot support a
confirmation, and §0.3 says eligibility is not receipt, so
`SOURCE_IS_PLAN_NOT_AWARD` applies that at the source-document level.

**This is beyond the literal §6.1 list and is reversible** — delete
`rhtp_flag_plan_source()` and its call site. It needed narrowing twice:

- **Budget documents are not plans here.** §9.2 lists
  `STATE_BUDGET_NARRATIVE` among the source types that support a `Yes`, and
  Delaware's State Housing Authority award — the spec's own do-not-over-filter
  example — comes from an executive budget summary. Budget titles were removed
  from the pattern list.
- **A title can name a plan and still be an award list.** Pennsylvania's
  `Rural Health Selected Projects: Pa RHT Plan (RHTP) Authorized Project
  Awards` carries **66 named rural hospitals** — Armstrong County Memorial,
  Barnes-Kasson County, Bucktail Medical Center. Matching `RHT Plan` sent all
  66 to `UNASSIGNED`. Award-action language in the title now wins outright.

### 3.5 `award: 0` in `/documents` is RCJ's null, not a $0 award

534 of 3,092 documents carry `award: 0`, against 2,020 with no field at all and
538 with a real figure. Read literally, §6.2's under-$1,000 rule flags all 534
as implausible amounts, which drowns the flag. A document reporting $0 does not
exist; the zero is a sentinel, and it is read as "no amount published" with
`amount_basis` recording the coercion.

**`/awards` is deliberately not treated this way.** `federalAmount: 0` (21
records) and `federalAmount: 1` (86 records) are exactly the placeholder data
§6.2 exists to catch, and stay flagged.

---

## 4. Blockers and gaps carried forward

### 4.1 No CMS allotment anchor — two rules are inactive, not passing

`data/reference/state_source_registry.csv` does not exist yet, so
`fy2026_allotment` is unavailable and **two spec rules cannot fire**:

- **§6.1 tier rule 3** (amount matches the state's CMS allotment →
  `STATE_ALLOTMENT`). This is why the table shows **zero Tier 1 rows** despite
  documents that plainly carry state allotments — Missouri's $216,000,000 hub
  announcement sits in `UNASSIGNED` for want of a figure to match it against.
- **§6.2 allotment ceiling** (a Tier 3 amount above its state's allotment).

Both are implemented and unit-tested against a fixture, and both switch on by
themselves the moment the registry lands. The run message, the `tier_basis` on
every affected row, and `logs/normalize_manifest.csv`'s
`allotment_anchor_available` column all record the gap. **It is reported as a
coverage gap, never read as a pass.**

The figures must be compiled by hand from the CMS December 2025 announcement,
off-session, and never from RCJ (§0.1, §7.3).

### 4.2 `activity_type` is deliberately unmapped

§8 requires `activity_type` to map to the CMS allowable-use categories. That is
a crosswalk against a published CMS document and it is interpretation, which
§6 puts outside this stage. `activity_type_raw` is carried verbatim on every
row and `activity_type` is left `NA`.

Worth knowing before that crosswalk is built: **RCJ's `activityType` is two
different things in one field.** Some values are RCJ's own machine-generated
coding (`POPULATION_HEALTH`, `WORKFORCE`, `HEALTH_INFORMATION_TECHNOLOGY`) and
therefore non-quotable under CLAUDE.md §6; others are the state's own raw
language (`Rural hospital improvement award`, `Spark Technology and
Innovation`, `Healthy Beginnings`). 34 distinct values, mixed.

### 4.3 State source URLs are thin where they matter most

`state_source_url` — the only field that can point at a primary source before
the registry exists — is populated on:

| Endpoint | with a state URL |
|---|---|
| `/opportunities` | 631 / 631 (100%) |
| `/awards` | 180 / 1,429 (13%) |
| `/documents` | 191 / 3,092 (6%) |

**Tier 3 is the tier with the worst source coverage.** 87% of award records
have no state URL from any RCJ endpoint, which makes §7 registry completeness a
hard prerequisite for Stage 4 rather than a convenience — as §13.12 already
requires.

Two related defects: `/activity.documentId` is **null on all 1,787 records**
despite the field existing (document references live only inside `detail`), and
**253 `/awards` records point at a `sourceDocument.id` that is not in the
`/documents` pull at all** — flagged `SOURCE_DOCUMENT_UNRESOLVED`.

### 4.4 RCJ's own `/states.awardTotal` mixes tiers

The `/states` figures are stored as a cross-check and are never authoritative.
They are consistently far above the Tier 3 total this stage derives —
Oklahoma $359.8M against $131.6M, Delaware $92.8M against $11.8M — because
RCJ's headline sums across all three tiers. That is §0.2 in one column, and
it is the number an outside reader would otherwise reach for.

Pennsylvania was the extreme case in the other direction and is the reason
§3.4 was narrowed twice: RCJ claims 66 awardees, an early version of the
plan-source rule sent every one of them to `UNASSIGNED`, and all 66 now tier
correctly as `SUBAWARD`.

---

## 5. Change detection

Award records carry no timestamp and no endpoint supports `updated_since`
(§4.1), so hashing is the only Tier 3 change detection available. The hash
covers substantive RCJ fields only — never anything this stage derives — so
bumping `rules_version` does not make every record read as changed.

`rhtp_apply_change_detection()` never overwrites. A changed record keeps its
old row with `superseded_by` pointing at the successor, and the new row
inherits the original `first_seen`. A record that vanishes from the feed is
marked `WITHDRAWN` and kept, because RCJ dropping a record is itself a finding.

**Re-running the same pull is idempotent** — 5,152 rows in, 5,152 rows out, all
`UNCHANGED`, no second version written. Getting there needed a fix worth
recording: RCJ ships the same record id twice, so `record_id` is not a unique
join key and `row_uid` is not either without an occurrence index. The
change-detection joins fanned out many-to-many and the table grew on every
re-run. Both joins are now asserted `many-to-one` and `row_uid` uniqueness is
checked before and after.

---

## 6. Next session

Stage 3, the state source registry (`R/03_state_registry.R`), needs two things
that cannot be produced in a cloud session:

1. **CMS FY2026 state allotments, 50 rows**, from the CMS December 2025
   announcement. This unblocks §6.1 rule 3, the §6.2 allotment ceiling, and
   the §13.3 reconciliation.
2. **Verified `award_posting_url` per state.** Start from
   `data/reference/state_source_registry_candidates.csv` — 151 candidates,
   all 50 states covered — and set `last_verified` on each row by loading it.

Florida (§1) is the state to compile by hand first: AHCA's procurement portal
is the only route to its Tier 3 data, and no amount of RCJ work will produce it.

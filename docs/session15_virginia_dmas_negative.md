# Session 15 — Virginia's awards do not run through DMAS, and a manifest that listed itself

**Date:** 2026-08-28
**RCJ quota spent:** zero. Network calls went to `dmas.virginia.gov` (392),
`www.cms.gov` (16 listing pages, 0 releases — the topic index was already warm)
and `www.medicaid.gov` (1).

---

## 1. The ask, and the short answer

`dmas.virginia.gov` was allowlisted to settle one question: **has DMAS posted
awards under the `RFA-RHTP-2026-nn` series?**

**No — and it never will, because that series does not live on DMAS's site.**
The negative is stronger than "not yet": the string `RFA-RHTP`, in any spacing
or casing, occurs **zero times across 388 pages of `dmas.virginia.gov`**. No
extractor and no `va_year1_awardees.csv` were built.

### What was actually searched

Not a look around — an enumeration. Three passes, and the third is the one that
makes the negative worth committing:

1. a depth-2 crawl from the home page, the RHTP programme page, and all six
   pages of the press-release index (220 pages);
2. the agency's own **HTML sitemap** at `/sitemap/`, which lists **330**
   internal paths — every one not already fetched was then fetched (178 more);
3. a grep for `RFA[- ]?RHTP` and for `rural health (care )?transformation`
   across all 388.

`sitemap.xml`, `sitemap_index.xml` and `robots.txt` are all 404, so the HTML
sitemap is the site's only self-declared page list, which is why it was used as
the frame rather than the crawl alone.

**`rural health transformation` appears on five pages in total:** the programme
page, its parent, the press-release index (and its `?page=1` duplicate), and the
sitemap. Nothing else on the agency's site mentions the programme at all.

---

## 2. Why DMAS is the wrong host — a correction to Session 14

Session 14 wrote that *"Virginia's RFAs are numbered `RFA-RHTP-2026-nn` and run
by DMAS, which is where the awards will post."* The first half is right. **The
second half is wrong, and DMAS's own procurement page says so.**

`/about-us/procurement/` states that DMAS hosts no solicitations of its own: to
see any DMAS opportunity, vendors are directed to **eVA**, the Commonwealth's
central procurement portal. And the RFA application portals named in the
committed RCJ pull are not state hosts at all — they are **pass-through
administrators**:

| Portal in the RCJ pull | Who that is |
|---|---|
| `vhcf.org/rural-health/apply/...` | Virginia Health Care Foundation |
| `vhha.com/.../apply-rpm-gme`, `vhhafoundation.org/rhtp/apply/` | VHHA Foundation (the state hospital association's foundation) |
| `ruralhealthtransformationva.virginia.gov` | the programme's own site |

**Every one of those hosts is refused at CONNECT from this session**, as are
`eva.virginia.gov`, `vdh.virginia.gov` and `hhr.virginia.gov`. Only the *apex*
`dmas.virginia.gov` resolves — `www.dmas.virginia.gov` is refused too, which is
worth knowing before someone concludes the allowlist entry did not take.

So allowlisting DMAS answered the question asked of it and **did not open the
route to Virginia's awards, because that route does not run through DMAS.**
This is the fifth consecutive host ask to come back negative
(`ruralhealthtransformation.sd.gov`, `alabamarhtp.com`, and now DMAS), and the
pattern is no longer a coincidence worth ignoring — see §6.

---

## 3. The one RHTP award DMAS does publish, and why it changed nothing

DMAS's press-release index carries exactly one RHTP item: the Governor's
**2026-05-21** release, served as a PDF from the agency's own media library. It
names exactly one recipient:

> **Virginia Highlands Community College — $127,500**, *"a first-of-its-kind
> Rural Health Transformation grant"*, for LPN programme expansion, part of the
> **Homegrown Health Heroes** initiative.

**This is the first primary-source corroboration of the single Virginia row in
the committed RCJ `/awards` pull** — RCJ's `awardeeName` and its
`federalAmount: 127500` match the release body exactly. Under §0.1 that record
could now be validated rather than merely discovered.

**It was still not built into a dataset, deliberately.** The recipient is a
community college: `recipient_type` is not hospital and `flow_type` is
`NON_HOSPITAL` on any reading. A one-row Virginia file would add a state to
Deliverable 1 while adding exactly zero to the hospital total — which is the
judgement Session 14 already made, now made against a primary source instead of
against an aggregator.

DMAS's press-release index also stops at **05.22.2026**. The agency has
published nothing since May, so the 2026-08-28 CMS announcement of $122M has no
counterpart on the state agency's site at all.

---

## 4. §0.2 gets its worked example, and it got stronger on the way

The ask was to write Virginia's $122M/$189M discrepancy into the spec. What the
DMAS archive added is a **second, independent, state-side restatement** of the
Tier 1 figure, which turns a CMS-internal oddity into a two-publisher case.

| Figure | Where | Tier |
|---|---|---|
| **$122 million** | CMS newsroom headline, 2026-08-28 | an announced tranche — names **no recipient**, so not Tier 3 |
| **$189 million** | a quoted statement *in that same release* | Tier 1 |
| **$189,544,888** | `cms_fy2026_allotments.csv` | Tier 1, the anchor |
| **"$189.5 million in year-one funding"** | **the Governor's own release**, archived this session | Tier 1, restated by the Commonwealth |

The CMS release says outright that the announcement is *"just one part of the
larger overall funding amount being awarded to Virginia for fiscal year 2026"*,
which is the sentence that settles the tiering rather than leaving it inferred.

**Why this is the example to keep.** Both numbers survive a plausibility check.
Each is the right order of magnitude, each traces to an official page, each is
genuinely "Virginia, FY2026". Nothing about either looks wrong in isolation —
what separates them is only the tier, which is precisely why `award_tier` is
assigned before any other processing rather than inferred later from context.

Added to `rhtp-tracker-build-spec.md` §0.2 **as a patch** (§2.1 — 16 lines
inserted, nothing deleted, nothing overwritten).

### A near-miss the example explicitly distinguishes

The same Governor's release announces the award as **$127,000** in its sub-deck
and **$127,500** in its body. That is *not* a tier problem — it is one figure
published twice with a typo, and its rule is the opposite one: keep the
source's own language (§8), record the discrepancy, resolve nothing. The spec
now says so, because a reader who has just learned the tier lesson is exactly
the reader who will misapply it to the next two numbers they meet on a page.

---

## 5. The monitor: no new states since Aug 28 — and two defects it was hiding

**`Rscript R/00_cms_press_monitor.R --run`, live. Nine states, unchanged:
AK · AL · GA · ND · OH · PA · SD · VA · WV. No state has announced since
2026-08-28.** `cms_state_announcements.csv` is untouched.

**The medicaid.gov lag cannot be sized yet, and that is the honest answer.**
CLAUDE.md left this open — `source` moves `CMS_NEWSROOM` → `BOTH` on the run
where the secondary catches up. medicaid.gov was re-fetched live and **still
carries eight states and no Virginia**; its announcement table is byte-for-byte
identical in content to the committed archive. But Virginia was announced
**today**, so the observed lag is still under one day. The question needs a
later session, not a better probe.

### 5.1 The steady-state run was warning on every pass

Two `Unknown or uninitialised column: is_rural` warnings on every run.
`purrr::map_dfr` over zero rows returns a **zero-column** tibble, so when the
topic index is warm and nothing new needs learning, `learned$is_rural` is
`NULL`. `sum(NULL)` is `0`, so the printed counts were **right by luck** — which
is the part worth fixing, because the next reader of that column gets `NULL`
rather than an error.

This is the repo's usual lesson inverted. It is normally *the path that runs
least often* that breaks (Session 14's `--parse`). Here it was the path that
runs **most** often: a warm index is the steady state, so the twice-weekly
Routine hit this on every single run. The index's empty shape is now one named
definition, `cms_newsroom_index_schema()`, used both for a first run and for a
run that learns nothing.

### 5.2 The manifest listed itself, and the test passed on absence

Re-running the monitor on an archive date that already had a `MANIFEST.txt`
**failed the digest-verification test**. The cause: the manifest's file listing
came from `list.files(archive_dir, recursive = TRUE)` — which includes
`MANIFEST.txt` once one exists. A manifest cannot record its own digest; the
value is stale the instant the file is written.

**It had always been wrong. The test had simply never been in a position to
notice.** On a first run the manifest does not exist when the listing is taken,
so there was nothing to be wrong about, and the check passed on *absence*
rather than on correctness. Any second `--run` in one day — which the
twice-weekly Routine reaches whenever it fires twice — exposes it.

`MANIFEST.txt` is now excluded from its own listing, and a new test pins two
things:

- the manifest does not list itself;
- the listed set and the on-disk set are **equal**. That second half matters as
  much: the existing digest test guards each entry with
  `if (file.exists(path))`, so a file that silently stops being listed is
  indistinguishable from a file that verified.

The new test was positive-controlled — the defect was reintroduced into the
manifest and the test failed as intended, then the manifest was restored and
re-verified by digest.

**Tests: 1,178 assertions, all passing** (was 1,176 + 1 self-skip).

### 5.3 A note for whoever reads the run log

`logs/cms_press_manifest.csv` gained **four** rows this session, not one: the
production run, two verification re-runs after the fixes in §5.1 and §5.2, and
one `--parse`. All four report the same result (9 states, 0 new), and all four
are logged `PRODUCTION`. Strictly, the two verification re-runs were iterations
and §5.2 would have had them logged `DEV` with `--dev`. They were live runs
against the live page producing the production result, so the rows are not
wrong — but the log is append-only by design and nothing here was rewritten to
tidy it. Recorded so the repetition reads as deliberate rather than as four
scheduled fires.

---

## 6. Five negative host asks in a row is itself a finding

`ruralhealthtransformation.sd.gov`, `alabamarhtp.com`, `dmas.virginia.gov` —
plus SD's `doh.sd.gov` / `open.sd.gov` re-probes — have now all come back
without a recipient-level award list. Session 14 noted "four of the last four";
this is the fifth.

The reading is not that the allowlist requests were badly chosen. It is that
**the remaining unextracted states have mostly not published recipient-level
awards yet**, and the four states that had (FL, GA, PA, AL, AK) were extracted
in Sessions 10–12 as soon as their hosts opened. Virginia is at RFA stage; Ohio
and North Dakota published no list at all; South Dakota published counts without
names. Host access has stopped being the binding constraint on Deliverable 1.

**What is binding instead:** the §7.3 registry (blocker 1, still the §13.12 hard
gate ahead of Stage 4) and the AHA Annual Survey / CMS Provider of Services
extracts (blocker 5 — 200 hospital recipients are waiting on a CCN match, and
until they land every `determination_confidence` in the project is capped at
`MEDIUM`). Neither needs a single new host.

---

## 7. What was committed

- `data/evidence/VA/` — four artifacts and a manifest recording the negative:
  the RHTP programme page, the press-release index, the procurement page (all
  reduced to `<main>`), and the Governor's release PDF verbatim.
- **The reduction is the §7.1 / Session 14 posture.** DMAS's page chrome
  carries a **Weglot** translation `api_key` of the shape `wg_<32 hex>`, which
  is DMAS's to publish and not ours to redistribute. Every reduced file was
  asserted free of that token **shape** — not its literal value, so a rotated
  key is caught too — before it was written, and the committed archive was
  re-swept for it afterwards. Both digests are recorded per file, the
  reduction's and the full page's as served, so provenance still closes.
- `rhtp-tracker-build-spec.md` §0.2 — the Virginia worked example, patched in.
- `R/00_cms_press_monitor.R` — the two defects in §5, plus one new test.

**No `R/03k_va_*.R`. No `va_year1_awardees.csv`. No new row in Deliverable 1.**

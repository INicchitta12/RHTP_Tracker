# CLAUDE.md — RHTP Hospital Funding Tracker

Project context for Claude Code. Read at session start. Keep it current: the
"Current state" section at the bottom is updated at the end of **every**
session.

**Owner:** Isaac, AHA Data & Policy
**Objective:** Identify and quantify Rural Health Transformation Program (RHTP)
funds being distributed to hospitals, by state, with every figure traceable to a
primary state source.
**Stack:** R (tidyverse), `%>%` pipe only. Excel deliverable via `openxlsx`.
**Build environment:** Claude Code on the web (cloud sessions).
**Full specification:** `rhtp-tracker-build-spec.docx` (§ references below point into it).

---

## 1. The five governing principles (spec §0)

These govern every design decision. **If a later instruction seems to conflict
with one of these, the principle wins.**

### 0.1 Rural Care Journey (RCJ) is a discovery layer, not a source of record

RCJ is a commercial aggregator operated by AME Mobile. Its own site states it is
not affiliated with CMS/HHS/HRSA, that data is aggregated from public sources,
and that accuracy is not guaranteed. Observed extraction defects include:
non-RHTP records in the RHTP feed, page navigation text captured as document
titles, unrelated state press releases bleeding into event-schedule fields, and
awardee-level coverage that is complete in some states and empty in others.

RCJ's job in this system is to tell us where to look and when something changed.
The authoritative record for every published figure is the state notice of award
or equivalent primary document. **No RCJ field may appear in an AHA-published
number without independent state-source validation.**

### 0.2 The three-tier rule

RHTP money moves CMS → state → subrecipient. RCJ mixes all three tiers in a
single amount field. Every record must carry an `award_tier` before any other
processing:

| Tier | Code | What it is | Example |
|---|---|---|---|
| 1 | `STATE_ALLOTMENT` | CMS award to a state | Missouri FY2026, $216.0M |
| 2 | `SOLICITATION` | State-announced funding pool / NOFO budget | Ohio Rural CIN & Innovation Hubs, $61.7M |
| 3 | `SUBAWARD` | Executed or intended award to a named recipient | GA GREAT Health Workforce Retention Technology, $2,000,000 each to 13 named hospitals on DCH's signed Notice of Award |

Only Tier 3 answers the project question. Tiers 1 and 2 live in separate
reference tables, on separate Excel sheets, and are **never** unioned with Tier
3. Aggregation functions must **hard-fail** if passed mixed tiers.

**The worked example lives in spec §0.2 — Virginia, two tiers on one page.**
CMS's 2026-08-28 release headlines **$122M** and quotes **$189M** in the same
document; the Governor's own release calls it *"$189.5 million in year-one
funding"*, which rounds the **$189,544,888** allotment exactly. Both figures
are official, both are "Virginia FY2026", and only the tier separates them.
Read it before coding any state whose sources disagree about its total.

**AND IOWA IS THE SECOND WORKED EXAMPLE, WHICH GOVERNS MACHINE READING (§0.2,
session 37).** Virginia is two tiers on one page in prose a reader can weigh.
Iowa is **two tiers in the same sentence of the same boilerplate**, from one
agency, distinguishable by nothing visible. Its Notices of Intent to Award each
carry exactly one dollar figure, in the CMS footer, and the sentences are word
for word identical apart from the programme name and the number:

- *"This **Best and Brightest- Medical Equipment Procurement** is supported by
  … a financial assistance award totaling approximately **$66,002,161.80**"* —
  **Tier 2**, that RFP's pool.
- *"This **Combat Cancer Health Hub Program** is supported by … a financial
  assistance award totaling approximately **$209,040,063.71**"* — **Tier 1**,
  Iowa's whole allotment.

**BOTH ARE SESSION 27'S "STRONG", PROGRAMME-SCOPED FORM, AND BOTH NAME A REAL
IOWA RHTP PROGRAMME.** The audit's axis — the footer's grammatical SUBJECT —
answers whether a footer is **provenance**; it does not answer what **tier** its
number is, and these two questions are independent. **TIER 1 IS KNOWABLE HERE
ONLY BY COLLISION WITH THE §7.1 ANCHOR**: $209,040,063.71 is Tier 1 because
`cms_fy2026_allotments.csv` has Iowa at $209,040,064, and for no other reason
available on the page. That is a coincidence of VALUE, not a statement by the
publisher — the most fragile way this project knows anything — so **the default
for a footer figure is REFUSAL, not acceptance**, and the check runs by machine
on every figure a state file records.

`rhtp_assert_footer_not_allotment()` / `rhtp_assert_footer_tiers()`
(`R/utils_config.R`) refuse any footer declared `SOLICITATION` within
`RHTP_FOOTER_ALLOTMENT_MARGIN` ($10,000) of that state's allotment, **and refuse
any declared `STATE_ALLOTMENT` that stops colliding** — the second half matters
as much, because a Tier 1 declaration rests entirely on that collision. The
margin is measured publisher rounding (Iowa to the dollar, NH to the cent
$204,016,550.20, Kansas's $8,000.18 transposition) and sits far below the
smallest genuine Tier 2 footer here, $6,000,000. **A figure that fails it is a
document to re-read, never a margin to widen.** Iowa's eleven are wired in and
pass; New Hampshire's two hand-coded footers were checked against the rule and
agree. **Answer provenance and tier separately, in that order.**

> **AND SESSION 43 FOUND THE FIRST FOOTER THAT DEFEATS THE CHECK WITHOUT BEING
> WRONG: MISSISSIPPI'S IS NOT 100% FEDERAL.** All **215** CMS
> financial-assistance footer occurrences across **76 committed files** in this
> repository say *"100 percent funded by CMS"* (154) or *"100% funded by CMS"*
> (61), and **no committed source carries any other percentage at all**.
> `mississippirhtp.com` says *"...as part of a financial assistance award
> totaling **$205,990,180.16**, with **99.96% funded by CMS/HHS
> ($205,907,220.16)** and **0.04% funded by non-government sources
> ($82,960)**."*
>
> **So the footer carries TWO figures and only the smaller one is the
> allotment.** The CMS share matches the §7.1 anchor ($205,907,220) to the
> dollar; the headline exceeds it by **$82,960.16**, which is **eight times**
> `RHTP_FOOTER_ALLOTMENT_MARGIN`. Driven rather than reasoned about, the
> headline is **REFUSED** as `STATE_ALLOTMENT` — correctly, it is not the
> allotment — and **ACCEPTED as a `SOLICITATION` pool, which is wrong**: it is
> Tier 1 plus a non-federal match, and there is no Tier 2 pool there at all.
>
> **PARSE THE CMS SHARE, NEVER THE HEADLINE, AND DO NOT WIDEN THE MARGIN.**
> $82,960 is one state's match amount; the next state's will differ, so
> widening buys nothing and costs the check. This is the rule above applied to
> itself — a figure that fails it is a document to re-read — and the thing to
> re-read is the percentage, which is the field this project had never had to
> look at because it had always been 100.

> **AND SESSION 51 FOUND THE SAME ERROR INSIDE THIS REPOSITORY: A BUCKET MUST
> NOT MIX TIERS.** Session 50 put Iowa's $50,000,000 Centers of Excellence
> footer, a Tier 2 pool, into `POOL_NAMED_HOSPITALS` beside Nebraska's Tier 3
> award, and labelled it carefully. The labelling did not help, because a
> bucket's figure is the sum of its rows. The row is gone. The figure lives as
> context in `ia_notice_footers.csv`, and `rhtp_hospital_dollar_partition()`
> now refuses any priced `AMOUNT_IS_POOL_NOT_AWARD` row in every state. Spec
> §0.2, third worked example.

### 0.3a Code the recipient, not the activity

**The single most consequential coding rule, and the one that has already gone
wrong.** All eleven verified Delaware records were coded `hospital = no`,
including awards to Beebe Healthcare, TidalHealth and Nemours Children's
Health — all hospitals and health systems. The coding followed what the money
*does* (school-based health centers, a diabetes pilot) rather than who
*receives* it. Applied nationally, that would have reported Delaware's hospital
total as zero, the exact opposite of the truth.

> **THE DEFECT IS SEVEN OF ELEVEN ROWS, NOT FOUR** (re-counted session 43,
> re-read session 44). `DE Verify.xlsx` names a Delaware hospital or health
> system in its `awardee` field on rows 1–4 (the four school-based health
> centres), row 8 (**Beebe Medical Center**), row 9 (**TidalHealth**) and row 11
> (*"University of Delaware, **Beebe Healthcare**, Deloitte Consulting LLP"*, a
> §6.2 multi-recipient field). Every one carries `rhtp_award_yn = yes` and
> `hospital_yn = no`.
>
> **ROWS 8 AND 9 ARE THE SHARPER HALF, BECAUSE THE EXPLANATION ABOVE DOES NOT
> REACH THEM — AND SESSION 44 CORRECTED WHY.** Session 43 wrote that they are
> *"bare hospital names with no activity attached at all"*, and the workbook
> says otherwise: both carry `activity_type = "Rural Delaware Diabetes Wellness
> Pilot Program"` and a full `program_description`. **The distinction is not
> whether an activity is attached; it is WHERE the activity sits.** On rows 1–4
> the setting is welded INTO the `awardee` cell — *"Beebe Healthcare –
> Georgetown Middle School"*, *"TidalHealth – Selbyville Middle School"* — so
> the recipient field itself reads as a school, and a reviewer coding off that
> column alone is looking at an activity while believing they are looking at a
> recipient. On rows 8 and 9 the `awardee` cell is **nothing but a hospital
> name**, and the activity beside it is a **diabetes pilot** — clinical care,
> with no school, housing authority or other non-hospital setting anywhere in it
> to be misled by. Neither column offered a wrong answer, and both rows were
> still coded `no`.
>
> **SO THE RULE HAS A SECOND HALF.** Judging the recipient is not only about
> refusing to read an activity — that is what rows 1–4 needed. It is about
> **reading the recipient at all**, which is what rows 8 and 9 needed, and no
> amount of care about activities would have supplied it. A reviewer can apply
> the first half perfectly and still return `hospital = no` on a row whose
> `awardee` says *"Beebe Medical Center"* and nothing else.
>
> **AND THE FIRST HALF GAINS A COROLLARY ROWS 1–4 MAKE CONCRETE: the `awardee`
> field is not always only the awardee.** Where a publisher packs a recipient
> and a site into one string, split it and code the half that received the
> money — §6.2's multi-recipient rule is the same instinct applied to a
> different kind of crowding, and row 11 (*three* organisations in one field,
> one of them a hospital) is the shape §6.2 already names. That is why the count
> is seven and not six.
>
> Nothing was re-coded (blocker 2 and Stage 5 own it). The count is recorded so
> the Delaware extraction starts from seven rather than re-deriving four.

Beebe Healthcare receiving RHTP funds to operate a school-based health center is
`recipient_type = HOSPITAL_OR_SYSTEM`, `flow_type = DIRECT`,
`distributed_to_hospital = Yes`. Beebe is a hospital. Beebe received the money.
Where the clinic sits does not change either fact.

Every human reviewer reads `reviewer-coding-instructions.md` before touching a
record. Every automated classifier keys off recipient identity, never activity
type.

### 0.3 Eligibility is not receipt

A solicitation listing hospitals among eligible entities is **not** evidence that
a hospital received money. This is the single most likely source of an inflated,
attackable number. Unresolved pass-through pools code as `Unclear`, never as
`Yes`.

### 0.4 Evidence-first

A determination without a captured, archived, quotable source is not a
determination. Any row with `distributed_to_hospital = Yes` must have a
validation URL, a local archived copy, and the confirming sentence stored in the
row. QA enforces this.

> **§0.4 IS ABOUT THE AWARD, AND `basis_type` IS WHAT KEEPS THE TYPING
QUESTION SEPARATE FROM IT (session 49).** The rule above was written about
RECEIPT — did this recipient get this money — and every word of it still holds
there: a `distributed_to_hospital = Yes` row still needs a validation URL, a
local archive and the confirming sentence, and no answer about a recipient's
FORM may be used to establish that a recipient exists, that an award was made,
or what it was worth. > > **What a state's award document very often does not
say is what KIND of organisation the recipient is**, and it was never going
to. That is the question eight states' worth of rows have carried on §8's
standing fallback since session 20, and answering it needs a different kind of
evidence. **A general-knowledge answer is admissible for the typing
question**, and `basis_type` records per row which kind each answer is:
`STATE_SOURCE` (the state's own document states the form), `ORG_WEBSITE` (a
second publisher does), `GENERAL_KNOWLEDGE` (a verifier's own knowledge, with
no citable source for the form). > > **THE AWARD'S URL APPEARING IN A BASIS
DOES NOT MAKE IT `STATE_SOURCE`.** 238 of the 399 returned bases carry a URL
whose host is the row's own state source, and on nearly every one that URL
locates the AWARD and says nothing about the FORM — which is why the row was
in the queue at all. The workbook says so itself on 143 rows: *"[Org type from
general knowledge; URL is the award source.]"* > > **THE EVIDENCE CLASS IS
CARRIED IN THE CONFIDENCE, NOT HIDDEN BY IT.** A `GENERAL_KNOWLEDGE` answer
sets `determination_confidence = LOW`; `STATE_SOURCE` and `ORG_WEBSITE` set
`MEDIUM`. `HIGH` still requires a CCN match and nothing in this pass has one,
so Stage 5 remains what raises any of them. **A reader can therefore
subtract**: every hospital figure this project publishes can be re-derived
with the general-knowledge rows removed, which is the honest form of admitting
them.

### 0.5 Committed or gone

This project runs in cloud sessions. Each session gets a fresh VM with the
repository cloned; anything not committed to git disappears when the session
ends. The raw landing zone, the evidence archive, and the review queue are all
persistence-critical, so all three are **committed rather than gitignored**. Any
code that writes a file the next session needs must be followed by a commit.
This inverts the normal convention of gitignoring data directories — see §1.

> **0.5 matters most for day-to-day behavior.** Commit persistent output before
> the session ends. Every stage that writes persistent output ends with a commit.

---

## 2. Standing instructions

- **Never** write code that sums across `award_tier` values.
- **Never** read RCJ's source-document title year (`PA - 2025 - ...`) as a
  date. It is aggregator metadata: Pennsylvania's entire committed Year 1 file
  sits behind a 2025 prefix (§6.2, session 20).
- **Never** print, log, or echo the value of `RCJ_API_KEY`.
- **Never** add `data/raw/`, `data/evidence/`, or the review queue to `.gitignore`.
- **Commit persistent output before the session ends.**
- **A `--probe` READS. It never writes to `data/evidence/`.** Fetch into memory,
  compare a content digest, and run the tripwires against the LIVE bytes.
  `rhtp_probe_run()` enforces this and every `--probe` CLI branch goes through
  it; re-dating the archive is what `--fetch --force` is for, and it is a
  deliberate act a human takes after READING what changed (§2.2).
- **A probe watching for a roster runs the NAME tripwire as well as its phrase
  list.** A marker list is built from phrasings a state has already used and
  cannot contain the one it uses next — New Mexico named six Regional Hubs and
  not one of ten phrases matched (§2.3). Never widen the suffix list, and never
  add a name to a `known` list, to make a fired tripwire quiet.
- Never let a fuzzy hospital match auto-resolve — it goes to the review queue (§10.1).
- Never default an unassignable record to `SUBAWARD` — it goes to `UNASSIGNED` (§6.1).
- Never quote an RCJ machine-generated summary field as fact (see §6 below).
- Every human reviewer reads `reviewer-coding-instructions.md` before touching a
  record, and every automated classifier keys off recipient identity, never
  activity type (§0.3a).
- **The spec is edited in the repo. Patches only — never a wholesale file
  upload.** This applies to `rhtp-tracker-build-spec.md`, `CLAUDE.md` and
  `reviewer-coding-instructions.md` alike. See §2.1.

### 2.1 The spec is edited in-repo, by patch

`rhtp-tracker-build-spec.md`, `CLAUDE.md` and `reviewer-coding-instructions.md`
are **source files under version control, not documents that live on a laptop
and get uploaded.** Change them here, in a commit whose diff shows exactly what
moved. **Do not replace them by uploading a local copy**, however small the edit
looks.

The reason is that it has already destroyed committed work twice, in the same
way both times — a stale local copy overwriting a section it was never aware of:

- **`0a51145`** replaced `reviewer-coding-instructions.md` with a local copy
  predating `34d8fee`, silently deleting the committed `MULTI_RECIPIENT_FIELD`
  section (§6.2). Found and restored a session later, by accident.
- **`219d803`** replaced `rhtp-tracker-build-spec.md` with a copy that did not
  contain `9fdc156`, reverting the §10.2 `NON_HOSPITAL` correction — the row
  that stops a reviewer coding Beebe Healthcare's school-based health center as
  a non-hospital, which is the single error §0.3a exists to prevent. Session 7
  found the spec still carrying the defective row and re-applied the commit.

Neither deletion appeared as a deletion. Both looked like an upload of the
current file. A patch cannot do this: git refuses a conflicting edit and shows
the difference instead of resolving it silently in favour of whichever copy was
uploaded last.

Two consequences worth stating plainly:

- **An upload is a full-file overwrite even when the intent is a one-line
  change.** Everything committed since that local copy was taken is discarded,
  and nothing in the commit says so.
- **A merged PR is not enough.** `9fdc156` was pushed to a branch *after* PR #7
  merged its parent, so it never reached `main` at all, and the next spec upload
  cemented that. Check that a correction is on `main` before relying on it, and
  say so in the commit that depends on it.

### 2.2 A probe reads; the archive is written by hand

From session 19 until session 46, `tx_probe()` opened with
`tx_fetch_sources(force = TRUE)`. Every firing of the Texas Routine
re-downloaded all eleven Texas sources **into `data/evidence/TX/`** and rewrote
the manifest.

The damage is not untidiness. `tx_validate()` reads the archive, so after the
re-fetch **the probe was comparing the live site against bytes it had just
downloaded** — it could only ever report that Texas had not moved. Had HHSC
added an *"Awarded Grant Information"* section to a Rural Texas Strong page, the
probe would have archived it first and asserted against it second, and **the
tripwire designed to fail the build would have passed on the roster it was
watching for.** Separately, the file names still said `2026-08-29` while the
bytes under them were whatever HHSC served that morning, so the fetch dates
stopped meaning "when this document was read".

**`rhtp_probe_run()` (`R/utils_config.R`) is the rule made enforceable.** Every
`--probe` CLI branch goes through it; it snapshots `data/evidence/` around the
probe — path, size and **mtime**, because `force = TRUE` rewrote files whose
bytes had not changed and a digest-only snapshot calls that clean — and refuses
if anything moved. Two tests read the source of every file in `R/`: one requires
any file offering `--probe` to route it through the guard, the other that no
`*_probe` body calls a `_fetch` writer.

**And every probe appends its verdict to `logs/probe_results.csv`** (committed,
§0.5): `state, probed_at, verdict, page, note`, with verdicts `UNCHANGED` |
`CHANGED` | `TRIPWIRE` | `ERROR`. A fired tripwire is logged **and then
re-raised** — the throw is the signal, and without the log the run that mattered
would be the only one leaving no trace. `ERROR` is kept apart from `TRIPWIRE`
deliberately: one is a statement about the state, the other about our access
(§0.4). A Routine's answer that lives only inside a fired session transcript
costs a human the work of opening that session to read it.

### 2.2a A Routine's SUCCEEDED is not a verdict (session 52)

**No Routine verdict has ever reached `main`.** The fresh-session triggers are
created with `sources: []` / `outcomes: []`; the probe appends its line in a
container that is then reclaimed. `R/probe_coverage.R` checks every registered
firing (`config/routines.csv`) for a line carrying **that Routine's own
`origin`** — an interactive run never covers one — and the suite runs it up to
the log's newest line. **Until the Routines are re-bound to a session that can
push, their silence is not evidence.** Never back-fill a line a Routine did not
write.

**A MISSED FIRING IS RE-RUN ONLY BY ITS OWN RUNNER, AND A DIAGNOSED ONE IS
EXPLAINED, NOT FILLED (session 65).** `fire_trigger` on a session-bound Routine
does NOT wake the runner: it mints a fresh session with no repository and no
push outcome, which cannot reach `main` (Washington, 2026-09-24, twice). A
diagnosed miss goes in `config/probe_gaps_explained.csv` with cause and
evidence; the coverage check then stops failing on it and `--report` still
shows it unlogged. Runner prompts should retry a GitHub 5xx before stopping
(NE and NV do; the older 33 do not, and only the Routine's own conversation
can change a prompt).

> **READ THIS BEFORE ATTEMPTING TO RECOVER A MISSED RUN: A MANUAL RE-FIRE
> CANNOT RECOVER ONE (session 66).** `fire_trigger` on a runner-bound Routine
> does not deliver into the runner. It lands in a **fresh session with no
> repository source and no push outcome**, which can run nothing in this repo
> and push nothing to `main`. Its `last_run` still reads SUCCEEDED. This has
> been **proven three times: once on Kansas and twice on Washington**
> (2026-09-24 17:32Z and 17:59Z; the second returned
> `session_017v5x7Yaf4GtQShmVNJJxjq`, origin `force_run_trigger`, empty
> sources and outcomes, idle with no commit). **The only recoveries are:**
> wait for the runner's next scheduled firing, or run the probe interactively
> (`RHTP_PROBE_ORIGIN=interactive`), which covers no Routine firing by design.
> **Then explain the miss in `config/probe_gaps_explained.csv`. Never
> back-fill a line.**

> **A PERSISTENT RUNNER RELOADS `CLAUDE.md` ONLY WHEN ITS OWN CHECKOUT HAS
> CHANGED THE FILE (sessions 78–80).** At a cold resume Claude Code reads
> `CLAUDE.md` from the runner's primary working tree. If that copy differs
> from the one the conversation already holds, it is loaded again on top,
> adding ~330k tokens. The runner reads its tree, not `main`, and before v4
> the only thing that changed its tree was the prompt's own step-1
> `git checkout -B main origin/main`.
> - **Why the trim did not help on the next firing.** WI and NV fired at
>   15:02Z and 15:13Z on 09-29, after the trim merged at 14:12Z, and still
>   doubled (to 698,839 and 708,018). Their resume reloaded the pre-trim
>   file that their previous firing's checkout had left in the tree. A
>   `CLAUDE.md` change on `main` reaches a runner one firing late, and costs
>   it a reload when it does.
> - **Why NY and SC stayed flat.** They were test-fired 27 minutes after
>   creation, before any `CLAUDE.md` commit reached `main`. Their first
>   checkout therefore left the file byte-identical (blob `e5a95cd`) to
>   the copy they loaded at creation, and their second resume added
>   nothing: 384,866 and 383,422.
> - **The evidence.** Across 12 two-turn runners the split was exact: 10
>   of 10 whose first checkout changed `CLAUDE.md` doubled, and 2 of 2
>   whose checkout did not stayed flat. Nothing else separated them:
>   origin, parent, CLI version, model and gap between turns were all
>   checked (`docs/session78_*` §3).
> - **The prediction test, set before the readings and passed.** NY's
>   09-27 checkout and MO's only turn had both moved the file, so each was
>   predicted to double at its 09-30 firing, with "stays near 385k" as the
>   falsifier. **NY: 384,866 → 723,788 (+338,922). MO: 368,982 → 687,835
>   (+318,853).** Both were read from `get_session` (`used_tokens`).
> - **The rule that follows.** A Routine prompt never checks out, pulls or
>   edits in the runner's primary checkout. Every firing works in a
>   detached worktree at `/root/rhtp_work` (v4, `R/routine_prompts_worktree.R`).
>   That freezes the runner's `CLAUDE.md` at the copy its first turn
>   loaded. A runner already holding a stale tree reloads once more at its
>   next resume, because the reload happens before any prompt runs. A
>   runner near 700k is therefore moved to a new session, never left for
>   that one firing. CA's new runner sat at 127,507 after its first v4
>   firing.

> **SESSION 66 RECREATED THE 32 RUNNER ROUTINES WITHOUT THE RETRY** (the
> "33" above double-counted Washington), in one batch, on their SAME runner
> sessions, with the same cron and prompt. Three things changed in each
> prompt: NE's 5xx retry on `git fetch`, the same retry on the push (30-480s
> backoff), and `list_triggers (limit 100)`, because 66 Routines existed
> during the overlap. `config/routines.csv` gained `old_trigger_id` /
> `old_logging_since`. `R/probe_coverage.R` checks the old id for firings in
> `[old_logging_since, logging_since)` and the new id from `logging_since`,
> so a cut-over does not orphan the firings before it. **Each runner step 2
> requires exactly ONE ENABLED Routine per runner session**, so an old
> Routine left enabled beside its replacement stops both.

> **A PERSISTENT RUNNER KEEPS ITS DIRTY TREE (session 75).** A run that
> declines to commit leaves its files behind, and the next firing inherits
> them. The CMS prompt stopped on any dirty tree, so one declined run stalled
> every firing after it (09-28, SUCCEEDED, no line). Its prompt now clears a
> tree wholly inside its own write set and restores after a suite failure.
> The 32 state prompts clear only `logs/probe_results.csv`. A prompt can be
> changed only from the runner's own conversation; otherwise recreate the
> Routine and chain the old id in `routines.csv` (`;`-separated).

> **SESSION 76 RECREATED ALL 33 NON-CMS ROUTINES WITH THE CMS RESET LOGIC**
> (the "32" above left out NEWSROOM). Step 1 now discards residue wholly
> inside the write set (`logs/probe_results.csv`) and stops on anything else;
> step 3 restores the write set whenever a run declines to publish, and drops
> an unpushed commit after a final push failure. Same runners, same crons;
> each original is chained in `routines.csv` and disabled. The originals are
> deleted only after two new ids publish (check-in 2026-09-29 11:15Z). Runners
> load ~355k context per cold resume (CLAUDE.md alone is ~190k tokens), and
> seven sit near 700k of 1M: `docs/session76_*`.
> Session 77 moved §10's session history to
> `docs/claude_md_history_sessions_01_76.md`, taking this file from 755 KB to
> about 123 KB: `docs/session77_*`.

> **AND A TEST MUST NOT PIN A FILE THE ROUTINE ITSELF REWRITES (session 66).**
> The CMS Routine's 2026-09-24 13:10Z run fetched three new CMS releases
> (DE $23M, AR, SD; published 12:00Z) and rewrote
> `cms_state_announcements.csv`. Four expectations in
> `test_00_cms_press_monitor.R` pinned that file's EXACT state set, so the
> suite failed and the runner, correctly, committed nothing. **The monitor
> that detects new states could not record a new state.** Those tests now
> assert floors, the §7.1 vocabulary and a 21-day recency window. The
> committed-queue test in `test_00b` accepts a one-flag CMS lag. Any test on
> `data/reference/cms_*` or `logs/` must hold on tomorrow's data.

### 2.3 A tripwire asks WHOM a page names, not only HOW it is worded

**Session 46 watched New Mexico name six Regional Hubs and said nothing.**
HCA's sentence is *"HCA has **selected six Regional Hub Organizations** to lead
Healthy Horizons"*, and it names Cibola General Hospital, the Regents of the
University of New Mexico, Eastern Plains Council of Governments, **Gila
Regional Medical Center** and **Nor-Lea Hospital District**. Every one of
`NM_AWARD_POSTED`'s ten phrases was checked against that sentence and **not one
matched** — *"selected organizations"* is not *"selected six Regional Hub
Organizations"* — so the tripwire whose whole job was to fire the day New
Mexico named a recipient sat quiet while New Mexico named six.

**The defect is not that the list was too short.** A marker list is built from
the phrasings a state has **already** used, so it can never contain the one it
uses **next**; lengthening it buys one more past tense and leaves the future
exactly as uncovered. Session 46 pinned the verb with its object left open,
which helps and is the same kind of fix.

**So `rhtp_assert_no_new_organisations()` (`R/utils_config.R`) asks a different
question: does the page NAME AN ORGANISATION IT DID NOT NAME BEFORE?** That is
phrasing-independent, because a roster announced in any words at all adds
names. It is a **SECOND SIGNAL beside the phrase lists, never a replacement**:
the phrase lists are what catch a state that says *"awards have been made"*
while naming nobody — South Dakota's shape, and South Carolina's email
notices — which no name diff can see.

**THE BASELINE IS THE COMMITTED ARCHIVE, NOT A CONSTANT, and that is what makes
it maintain itself.** A page's chrome, its navigation and its agency's own name
are in **both** copies, so they cancel — which is why the pattern can afford to
be broad where South Dakota's had to be narrow: South Dakota counts
organisation-shaped names against a **threshold**, so every false positive
spends part of its budget, while a diff has no budget to spend. Re-basing it is
`--fetch --force`, which is a deliberate act a human takes after READING what
changed (§2.2).

**It runs on the same reduced text the content digest is taken over**, so the
eleven rotating-token mechanisms this project has measured are already stripped
before a name is looked for. **Hand it raw HTML and it will report script
bodies as organisations** — it takes TEXT.

> **AND IT REFUSES TO PASS ON AN EMPTY BASELINE, which is the check that keeps
> this one honest.** If the archived copy yields no organisation-shaped names
> at all, the extractor has failed, and a diff against nothing either fires on
> everything or — if the live side is empty too — **passes silently forever**
> while wearing a green verdict. That is a statement about our reading reported
> as one about the state (§0.4), and it is exactly the shape of failure this
> function exists to end. **Missouri found it on the first run**: `hub_roster`
> is a PDF, and handed to an HTML reader it yields 450 characters of PDF
> header. The archived side now goes through Missouri's own PDF reader and the
> roster yields 30 names, so a **twenty-eighth Hub Anchor** would fire.

**Two defects in the reader were found by its own tests, and both were
false-positive generators.** A **trailing full stop** was kept for comparison
(to preserve *"Inc."*), so the LAST name on a page carried a period its
mid-sentence form did not and read as new the moment a page gained a sentence
after it. And a **zero-width character** inside a name is not in the name-token
class, so the run BREAKS there — *"Gila​Regional Medical Center"* comes out
as *"Regional Medical Center"*, a different string, which then reads as new;
session 34 met that same character in HCAI's WDRR heading, where it broke an
assertion with nothing to point at. Zero-width characters are now stripped
**before extraction**, not only before comparison, because by comparison time
the first word is already gone.

**A DATE IS NOT A NAME, AND LOUISIANA IS THE MEASUREMENT.** Its programme page
prints an announcement window in the cell beside each programme's name, and the
reduction flattens that cell boundary to a space. LDH re-dated all seven
windows between 2026-09-02 and 2026-09-21 **without naming anybody**, and
against the committed prior snapshot that produced three "new organisations"
whose only new words were the month. Breaking a run on a calendar token drops
all three; the two archived snapshots are what says so, rather than a guess.

**THREE TOOLS FOR PAGE FURNITURE, AND WHICH IS WHICH (session 52).** `known`
records RECIPIENTS and matches by containment. `furniture` records strings a
human READ and judged NOT a recipient, and matches EXACTLY, so it can never
swallow a longer name that contains it. `rhtp_name_scope()` cuts a page to its
content region between two anchors, on both copies, when a region ROTATES (a
news feed, a mega-menu) and no list could keep up; it refuses a missing
anchor. Every furniture entry carries its justifying sentence in the state
file, and a test proves each retuned page still fires on a real recipient.

**Wired into EIGHTEEN probes, on SUBJECT pages only** — a control or a press
index moves for reasons that are not the state awarding, and a tripwire that
halts on those is session 46's stale dated anchor in a new costume. **Alaska
and South Dakota are the two recorded exemptions**: Alaska's rolling xlsx
roster is diffed by the extraction itself, and South Dakota's portal already
carries its own organisation-name tripwire (§13, session 13). A test reads the
source of every file in `R/` and requires any file offering `--probe` to run
the name tripwire, so a twenty-first state file cannot quietly ship with only a
phrase list.

---

## 3. Coding conventions

- **tidyverse** throughout.
- **`%>%` exclusively — never the native `|>` pipe.** This is not a style
  preference; it is a hard rule for this repo.
- `snake_case` for all objects, columns, and file names.
- Explicit `dplyr::` / `tidyr::` / `stringr::` namespacing in package-style
  functions (anything in `R/utils_*.R` or exported helpers).
- **No `setwd()`.** Use `here::here()` for every path.
- No `arrow`/parquet — interim layer is `saveRDS()` / `readRDS()` (§3.4).
- No `pagedown` / `chromote` — evidence capture happens outside the cloud
  session (§9.0).
- **Identify honestly to every state host — with one recorded exception, and it
  is recorded rather than generalised.** Session 10 settled this for
  `medicaid.gov`: Akamai refuses a user agent carrying no contact URL, the
  `+url` form is the well-behaved-crawler convention, and *identifying honestly
  is the fix, not a workaround*. **`www.michigan.gov` inverts it** (session 27).
  Its Akamai config is a **denylist on identifying tokens**: the project's own
  agent 403, the RFC `Mozilla/5.0 (compatible; …; +url)` convention 403, a full
  Chrome UA with the tracker token appended 403, bare `Mozilla/5.0` 200 — and
  `robots.txt` is **itself 403**, so there is no crawler policy on offer and
  none is being declined. `R/03v` therefore uses a bare agent **for
  michigan.gov only**, as a decision taken with the owner. `mi_agent_for()`
  refuses that agent on any other host *and* refuses the honest agent on
  michigan.gov, and a test drives both refusals — which is what stops a
  one-host exception becoming a default.
- Read the API key with `Sys.getenv("RCJ_API_KEY")` only. Never write it to a
  file, never commit it, never echo it. The same call works unchanged against a
  local `.Renviron`, so no code changes are needed to move between cloud and
  laptop.
- All normalization and downstream stages read from `data/raw/`, never from live
  API calls. Development and re-runs cost zero quota (§5).

---

## 4. Repository layout

```
CLAUDE.md                      # this file
R/
  00_cms_press_monitor.R       # Stage 00 — CMS trigger list: newsroom + medicaid.gov (BUILT)
  00b_state_trigger_queue.R    # Stage 00b — the UNION of CMS + RCJ triggers (BUILT)
  01_retrieve_rcj.R            # Stage 1 — retrieval (BUILT)
  02_normalize.R               # Stage 2 — normalization + §6.4 mining (BUILT)
  02b_provenance_sweep.R       # §6.2 extended to STATE money + the date test (BUILT)
  03_state_registry.R          # Stage 3 — CMS allotments + registry (BUILT)
  03b_budget_narratives.R      # Stage 2.5 — §7A initiative table + §7A.4 gate (BUILT)
  03c_cms_abstracts.R          # CMS project abstracts — §4.1 candidate list (BUILT)
  03d_ga_great_health.R        # Georgia Year 1 — 158 actions incl. 21 named on NOAs (BUILT)
  03e_fl_year1_awardees.R      # Florida Year 1 + the §8 recipient_type back-fit (BUILT)
  03f_pa_year1_awardees.R      # Pennsylvania Year 1 — 66 authorized projects (BUILT)
  03g_al_year1_awardees.R      # Alabama Year 1 — 138 grants, parsed from prose (BUILT)
  03h_ak_year1_awardees.R      # Alaska Year 1 — 185 intents; ROLLING, --probe weekly (BUILT)
  03i_sd_rht_contracts.R       # South Dakota — the transparency-portal search (BUILT)
  03j_sd_year1_announcements.R # South Dakota — the two announced rounds; they name NOBODY (BUILT)
  03k_rcj_state_survey.R       # 50-state RCJ coverage survey — the second trigger's input (BUILT)
  03l_il_year1_awardees.R      # Illinois — ICAHN, the first PASS_THROUGH_DESIGNATED (BUILT)
  03m_or_year1_awardees.R      # Oregon — 7 pools, 4 documents, 278 award actions (BUILT)
  03n_tx_year1_probe.R         # Texas — the NEGATIVE, and 53 RCJ rows that are state money (BUILT)
  03o_ks_year1_awardees.R      # Kansas — 46 awards in 3 pools, parsed from KDHE PDFs (BUILT)
  03p_md_year1_awardees.R      # Maryland — 41 Budget Period 1 award OFFERS, 2 pools (BUILT)
  03q_state_completeness_recheck.R # the 7 extracted states, re-read for rosters (BUILT)
  03r_ne_year1_awardees.R      # Nebraska — 3 NOTICES OF AWARD; RCJ mistitled one (BUILT)
  03s_in_year1_awardees.R      # Indiana — 7 awards, 0 hospitals; RCJ INVENTED the label (BUILT)
  03t_ok_year1_awardees.R      # Oklahoma — 68 microgrants; RCJ holds NONE of them (BUILT)
  03u_nv_year1_awardees.R      # Nevada — 72 named awards, NO AMOUNTS ANYWHERE (BUILT)
  03v_mi_year1_awardees.R      # Michigan — 139 awards, a roster its state calls COMPLETE (BUILT)
  03w_mo_year1_awardees.R      # Missouri — 2 awards; a 27-org roster that is NOT AN AWARD LIST (BUILT)
  03x_nh_year1_awardees.R      # New Hampshire — GO-NORTH; 2 administrators, NO ROSTER (BUILT)
  03y_wi_year1_probe.R         # Wisconsin — the NEGATIVE; awards due SEPTEMBER (BUILT)
  03z_ia_year1_awardees.R      # Iowa — 264 award actions, NOT ONE PRICED (BUILT)
  03aa_me_year1_awardees.R     # Maine — 11 NAMED HOSPITALS, NONE OF THEM AWARDED (BUILT)
  03ab_ca_year1_probe.R        # California — the NEGATIVE; 11 candidates, 11 SEISMIC (BUILT)
  03ac_ct_year1_probe.R        # Connecticut — the NEGATIVE whose AWARD DATE HAS PASSED (BUILT)
  03ad_nm_year1_probe.R        # New Mexico — the NEGATIVE; a STATE fund, 3 defects at once (BUILT)
  03ae_la_year1_probe.R        # Louisiana — the NEGATIVE; SEVEN windows, ALL PASSED (BUILT)
  03af_ky_year1_probe.R        # Kentucky — the NEGATIVE; it names its OWN award dates, BOTH PASSED (BUILT)
  03ag_ny_year1_probe.R        # New York — the NEGATIVE whose CONTRACT START passed (BUILT)
  03ah_nc_year1_sources.R      # North Carolina — 44 NAMED across TWO ROSTERS, $0 (BUILT)
  03ai_ar_year1_awardees.R     # Arkansas — round 1 31 orgs / 37 actions / $149.2M; round 2 38 / 43 / $54.7M; COMPLETE (BUILT)
  03aj_wy_year1_awardees.R     # Wyoming — 75 actions from SIX tables in ONE document (BUILT)
  03ak_ms_year1_awardees.R     # Mississippi — 167 AWARDS, $104,115,146, three sections (BUILT)
  03al_de_year1_awardees.R     # Delaware — 4 awards, 3 orgs, NO amounts; §0.3a as DATA (BUILT)
  03am_id_year1_awardees.R     # Idaho — ONE named awardee, no amount, no hospital (BUILT)
  03an_oh_year1_awardees.R     # Ohio — ONE priced award; a footer that is the SUBAWARD (BUILT)
  03ao_sc_year1_awardees.R     # South Carolina — 228 awards, NO TOTAL IN THE DOCUMENT (BUILT)
  03ap_verification_queue_2.R  # the RETURNED verification queue + 3 policies (BUILT)
  03aq_unstated_form_typing.R  # MS + SC's unstated-form rows, TYPED (BUILT)
  03ar_rural_cut_report.R      # the RURAL CUT of NAMED_HOSPITAL -- a report, never a re-coding (BUILT)
  03as_sc_benchmark_bounds.R   # SC vs the agency benchmark, each reading COMPUTED (BUILT)
  03at_vt_year1_awardees.R     # Vermont — 111 EXECUTED agreements, typed on CMS enrolment files (BUILT)
  03au_ct_year1_awardees.R     # Connecticut — $50M, 4 agreements, ONE UNSPLIT hospital pair (BUILT)
  03av_wv_year1_awardees.R     # West Virginia — 7 named awards in 5 Governor's releases (BUILT)
  03aw_year1_completion_status.R # which extracted states FINISHED Year 1: 2 COMPLETE (FL, GA) (BUILT)
  03ax_fl_ga_ceiling_pools_gaps.R # FL's ceiling, GA's pools, both allotment gaps -- a REPORT (BUILT)
  03ay_tn_year1_awardees.R     # Tennessee — 53 HART awards, NO amounts, 2 hospital rows (BUILT)
  03az_co_year1_probe.R        # Colorado — a WATCH; awards dated "end of September 2026" (BUILT)
  03ba_nd_year1_probe.R        # North Dakota — a WATCH; trips on a 2nd "– Awarded" heading (BUILT)
  03bb_va_year1_probe.R        # Virginia — a WATCH on VHCF/VHHA Foundation award dates (BUILT)
  03bc_wa_year1_probe.R        # Washington — a WATCH on ~$58.1M of unnamed hospital money (BUILT)
  03bd_wa_year1_awardees.R     # Washington — 8 first-tier lines, $67.0M named, WSHA's $42M Unclear (BUILT)
  03be_va_year1_awardees.R     # Virginia — 11 named first-tier partners, NO amounts, no hospital (BUILT)
  03bf_nj_year1_awardees.R     # New Jersey — 103 priced awards, $83.06M, 35 hospital rows on CMS records (BUILT)
  03bg_newsroom_sweep.R        # the 18 no-release states' NEWSROOMS, one probe, one Routine (BUILT)
  03bh_rcj_candidate_dispositions.R # RCJ dispositions for the 23 states that had none (BUILT)
  03bj_enrolled_hospital_operator.R # §10.2 enrolled-hospital operators (AHCs) + OTHER-form check (BUILT)
  03bi_in_grow_regional_awardees.R  # Indiana GROW regions — 186 recipients, NO amounts; --probe (BUILT)
  03bl_mt_year1_probe.R        # Montana — a ROSTER WATCH since session 88 (names for the 75; a new round) (BUILT)
  03bm_nh_year1_probe.R        # New Hampshire — a WATCH on FHC; CAH RFA "Coming Soon" (BUILT)
  03bn_mn_year1_probe.R        # Minnesota — a WATCH; 94 eligible hospitals are NOT awards (BUILT)
  03bo_co_year1_awardees.R     # Colorado — 92 lines, $170.2M vs HCPF's $169.6M, typed on CMS enrolment (BUILT)
  03bp_tx_bp1_floor.R          # Texas — 33 of 68 districts in the BP1 report; a FLOOR, codes nothing (BUILT)
  03bq_al_round2_awardees.R    # Alabama round 2 — 34 grants, $54.8M, typed on CMS AL enrolment (BUILT)
  03br_nc_sbhc_awardees.R      # North Carolina SBHC — 5 named, $1.25M pool, NO split (BUILT)
  03bs_al_year2_probe.R        # Alabama — a WATCH on Community Medicine, a YEAR 2 subaward round (BUILT)
  03bt_ok_new_rosters.R        # Oklahoma — Doulas, RRR and CDM, each its own file; typed on CMS enrolment (BUILT)
  03bu_de_fqhc_awardees.R      # Delaware — 3 FQHCs, $22.69M ROUNDED, no hospital (BUILT)
  03bv_mt_year1_awardees.R     # Montana — 4 ambulance grants ~$340k ROUNDED + 1 unnamed pool of 75 (BUILT)
  03bw_sd_ccbhc_awardees.R     # South Dakota CCBHC — 13 named cohort, 12 grants, >$13M, NO amounts (BUILT)
  03bx_va_vhcf_awardees.R      # Virginia VHCF Interoperability — 25 awards, $14.39M, typed on CMS VA enrolment (BUILT)
  01b_rcj_pull_diff.R          # two RCJ pulls diffed + the EXPOSED SET (states on no Routine) (BUILT)
  utils_page_watch.R           # the shared READ-ONLY fetch/reduce/digest for probes (BUILT)
  probe_coverage.R             # a Routine firing with no log line FAILS, by name (BUILT)
  02c_state_attribution_sweep.R # §0.1 mode 6 — the record filed under the WRONG STATE (BUILT)
  04_validate.R                # Stage 4 — queue manager + rule engine (NOT YET BUILT)
  05_hospital_determination.R  # Stage 5 (NOT YET BUILT)
  06_build_workbook.R          # Stage 6 (NOT YET BUILT)
  qa_assertions.R              # (NOT YET BUILT)
  utils_config.R               # config, paths, credentials, state vocabulary (BUILT)
  utils_pdf_text.R             # PDF text via each font's own /ToUnicode CMap (BUILT)
  utils_recipient_classification.R  # the §8/§10.2 rules, shared by every state (BUILT)
data/
  raw/                         # IMMUTABLE — COMMITTED
    rcj/<pull_date>/*.json     #   the RCJ landing zone
    cms/<fetch_date>/*.html    #   the §7.1 allotment table, verbatim + digest
    cms/<fetch_date>/*.pdf     #   the CMS project abstracts, verbatim + SHA-256
    owner_uploads/*.xlsx       #   owner files as supplied — R/03e's ingest source
  interim/                     # normalized .rds/.csv; review_queue.rds — COMMITTED
  reference/                   # allotment anchor, registry, controlled vocabs
  evidence/                    # <state>/<record_id>_<date>.pdf — COMMITTED
    budget_narratives/DE/      #   §7A.2 — DE narrative + SHA-256 manifest; 49 to go
    GA/                        #   4 DCH announcements, the 87-hospital roster, and
                               #   the 2 SIGNED NOTICES OF AWARD (session 22)
    PA/                        #   DHS announcement + the 66-project list
    AL/                        #   the governor's 138-grant release
    AK/                        #   TWO snapshots of the rolling award notice
                               #   (2026-08-28, -31) + the funding-cycle control
    SD/                        #   the open.sd.gov search + 13 contract detail pages
    SD/announcements/          #   the two news.sd.gov releases, article element only
    IL/                        #   the ICAHN award release + the two HFS negatives
    OR/                        #   4 OHA documents + the Catalyst xlsx; awards page script-stripped
    VA/                        #   the DMAS negative: 3 reduced pages + the governor's PDF
    MD/                        #   MDH programme + procurement + newsroom + 2 award-offer PDFs
    IN/                        #   GROW site + IDOA's 456-row register, 6 award docs, 5
                               #   Scope of Work members (the CMS footer) + the trailer control
    NE/                        #   DHHS programme + grants pages, the 3 SIGNED NOTICES OF
                               #   AWARD, and RFA 4533 — the §6.2 NEGATIVE control
    OK/                        #   the OSDH Funding Recipients roster, the funding page that
                               #   is its positive control, and the 4 RHTP PDFs carrying the
                               #   CMS financial-assistance footer
    NV/                        #   the NVHA Funded Projects roster, CMS's OWN NOTICE OF
                               #   AWARD, the two award releases, and the GME release +
                               #   workforce comparison that are the §6.2 NEGATIVE CONTROL
    MI/                       #   the MDHHS RHTP Subrecipients roster, the programme page
                               #   carrying its COMPLETENESS CLAIM, the 2025-12-30 award
                               #   release, a post-NOA solicitation, MHA's own RHTP page,
                               #   and the OPIOID-SETTLEMENT release that is the NEGATIVE
                               #   CONTROL. TWO USER-AGENTS — see §3
    MO/                        #   the DSS RHTP programme page, the 27-organisation HUB
                               #   ANCHOR ROSTER (a selection, not awards), 3 DSS releases,
                               #   the ToRCH Care FAQ whose Q36 says Hub Anchors "will not
                               #   act as the fiscal agent", the DSS bid table (the
                               #   PROCUREMENT-CHANNEL control) and the CTF funding page
    NH/                        #   FHC's own GO-NORTH award page and CDFA's statement of
                               #   the SAME 2026-03-16 Council action. NEITHER IS A STATE
                               #   HOST: every nh.gov host is Akamai-403 to this
                               #   environment on FOUR agents, so §7's designated
                               #   pass-through administrator route (Illinois/ICAHN) is
                               #   what makes New Hampshire readable at all
    WI/                        #   the DHS programme + advisory-council pages, the 2026-07-23
                               #   council deck, the solicitations index, DWD's WIG:HEART page,
                               #   DPI's 213-district ELIGIBILITY list, WORH's updates, and TWO
                               #   CONTROLS: DWD's ARPA-funded WIG award report (the NEGATIVE
                               #   CONTROL — a real award list on an RHTP page that is not RHTP)
                               #   and the WTCS college roster (which makes the 16-name mapping
                               #   SOURCED). ONE PATH IS 403 PER-PATH — recorded as UNKNOWN
    IA/                        #   the ELEVEN Notices of Intent to Award that Iowa's
                               #   own "Where to Find Funding Awardees" section links,
                               #   the Healthy Hometowns programme page that carries the
                               #   PROVENANCE the notices do not, and TWO further
                               #   publishers — the Governor's 2026-01-30 release and
                               #   HHS's 2026-06-18 one, which RE-PUBLISHES a whole
                               #   notice's roster. 18093 is SUPERSEDED by 18330 and both
                               #   stay
    ME/                        #   the DHHS programme page, the THREE RHTP
                               #   announcements (TWO on the news index, ONE on
                               #   the BLOG — Maine's only priced award is on
                               #   the blog), the Maine DOE opportunity, the TWO
                               #   RHTP Advisory Committee decks (the 2026-08-05
                               #   one is what says the cohort has no award
                               #   amount), MCD Global Health's partner page,
                               #   the Governor's 2025-12-29 statement, the two
                               #   DHHS indexes, and the PROCUREMENT ARCHIVE
                               #   that is BOTH the positive control (1,362
                               #   named awarded vendors, none RHTP) and the
                               #   negative control (HRSA's SHIP, awarded, DHHS,
                               #   "Rural Hospital" in its title)
    CA/                        #   the CalRHT programme + funding pages, CMS's OWN
                               #   NOTICE OF AWARD, the budget narrative and all
                               #   FOUR grant guides — and ONE PAGE THAT IS BOTH
                               #   CONTROLS: HCAI's SRHRP, whose 29 named awards
                               #   are the POSITIVE control, whose cigarette-tax
                               #   funding makes it the §0.1 NEGATIVE, and whose
                               #   102 named ELIGIBLE hospitals are the §0.3 trap.
                               #   Plus the HCAI newsroom, the CHANNEL control
    CT/                        #   the DSS RHTP programme + Documents pages, CMS's OWN
                               #   NOTICE OF AWARD, the budget narrative (all 7 RCJ
                               #   candidates are line items in it), OHS's NOFO release,
                               #   OPM's RFP index carrying the AWARD DATE THAT HAS
                               #   PASSED, the DSS leadership release (the GOVERNANCE
                               #   negative control), OHS's press index (the POSITIVE
                               #   control) and the CTsource landing page (UNREADABLE)
    NM/                        #   the HCA RHT programme page (6 procurements, none
                               #   awarded), the RHCDF page that is BOTH CONTROLS, HCA's
                               #   own RHCDF deck saying "$50 million STATE investment",
                               #   the Governor's 41-organisation STATE award release,
                               #   the Healthy Horizons and Innovation Fund releases, and
                               #   the news index carrying the POSITIVE CONTROL AND THE
                               #   §0.1 TRAP FOUR ITEMS APART
    LA/                        #   the LDH programme page carrying SEVEN "Notice of
                               #   Intent to Contract" windows THAT HAVE ALL CLOSED,
                               #   the funding page's seven solicitations, the
                               #   Governor's EO release, the 2026-08-20 Advisory
                               #   Council deck (slide 18 = RCJ's whole candidate
                               #   set, headed PROJECTED), the Capital NOFO (the row
                               #   RCJ DROPS), LED's Catalyst release (the only
                               #   non-LDH provenance sentence), and the rhtla.net
                               #   Atlas — UNREADABLE — plus its /api/facilities:
                               #   3,576 facilities, 305 HOSPITALS, NO MONEY (§0.3)
    KY/                        #   the ruralhealthplan.ky.gov programme + NINE-RFA funding
                               #   pages, the CHFS grants channel (the POSITIVE
                               #   CONTROL, which states absence PER AGENCY), the two
                               #   RFAs carrying Kentucky's OWN award-notification dates,
                               #   CMS'S OWN NOTICE OF AWARD (the 4th state, and the
                               #   FIRST that is an ORIGINAL rather than a revision), and
                               #   the Foundation for a Healthy Kentucky's pass-through
                               #   page. TWO DIGEST MECHANISMS AT ONCE — see §3
    NY/                        #   DOH's programme page, the RCHI funding guidance (whose
                               #   CONTRACT START of 2026-09-01 had passed), the
                               #   2026-08-12 update deck saying "Reviews and Funding
                               #   Recommendation In Progress" against 91 applications,
                               #   the 2026 press index (the CHANNEL control: FIFTEEN
                               #   named award announcements, ONE RHTP item and it is an
                               #   OPPORTUNITY), and the Contract Reporter — UNREADABLE
    NC/                        #   the NCRHTP programme + opportunities pages, the
                               #   standing ROOTS Hub Leads page, and THREE press
                               #   releases — including the TWO ROSTERS (39 Mobile
                               #   Integrated Health recipients; 5 NC ROOTS Hub Leads) —
                               #   plus a Hub Lead's own regional page, the SECOND TIER,
                               #   which names NOBODY
    AR/                        #   DF&A's own "List of Organization and Award
                               #   amounts" (31 orgs x 2 initiatives, $149.2M,
                               #   NO CMS FOOTER ON IT AT ALL), the county map,
                               #   the Governor's 2026-08-27 release — which
                               #   prices ALL 50 PROJECTS individually and is
                               #   the SECOND GRAIN — the home page carrying the
                               #   award-list link (the POSITIVE CONTROL), all
                               #   FOUR initiative pages (identical
                               #   forward-looking text on the two that HAVE
                               #   awarded and the two that have not), the
                               #   resources index, all FOUR NOFOs and the Year 1
                               #   Revised Budget Narrative. THROTTLED AT 10s —
                               #   the host's own Crawl-delay
    HI/                        #   the plan (engage.hawaii.gov), SHPDA's initiative page
                               #   naming the ONE award (HPCA, 8/28) and the two hospital
                               #   RFIs, both rhtp.hawaii.gov pages, the Governor's $58M
                               #   release and the steering deck. HANDS is UNREADABLE
    MS/                        #   the RHTP funding page (selection COMPLETE, the
                               #   99.96%/0.04% footer) + home, the GOVERNOR'S
                               #   NEWSROOM (the positive control and the channel
                               #   the state named), and DOM's Completed
                               #   Procurements — BOTH CONTROLS AT ONCE: ten
                               #   uniform intent-to-award notices AND the
                               #   HORNE LLP RHTP consultant award of 2025-08-13,
                               #   138 DAYS BEFORE THE NOA
    DE/                        #   the 2026-07-29 award release (four named,
                               #   none priced, and the ONE currency figure is the
                               #   ALLOTMENT), the DHSS programme page carrying all
                               #   FIFTEEN Year 1 budgets and Delaware's own
                               #   definition of "awarded", and the 2026-02-09
                               #   initial-RFP release (the same channel at
                               #   SOLICITATION stage)
    ID/                        #   DHW's funding-opportunities page — ONE
                               #   "Awardee:" line, eleven open opportunities, and
                               #   the weakest footer subject met so far ("This
                               #   website is supported by") — plus the programme
                               #   page that carries the provenance it does not
    SC/                        #   THE ROSTER ("SC RHTP Year 1 Award List", 8
                               #   pages, 228 priced rows, NO TOTAL AND NO CMS
                               #   FOOTER), the SCDHHS grants page that names it
                               #   and carries BOTH §0.1 NEGATIVE CONTROLS, CMS's
                               #   2026-09-17 release stating "228 grants"
                               #   independently (REDUCED, §7.1 Mapbox token),
                               #   and the two control releases themselves — the
                               #   $48.2M Rural & MUA roster and the ~$35M
                               #   Behavioral Health Crisis Stabilization roster
                               #   TO 13 HOSPITALS, both predating the NOA
    OH/                        #   the Governor's Ohio University award release
                               #   (whose CMS footer prints the SUBAWARD), ODH's
                               #   STALE programme page naming nobody, and the
                               #   2025-12-29 ALLOTMENT release archived as the
                               #   TIER CONTRAST — §0.2 across two documents from
                               #   one publisher
    WY/                        #   EXTRACTED session 42. the DRIVE-FOLDER documents the state links from
                               #   health.wyo.gov: CMS's OWN NOA (05/14/2026, Revision),
                               #   the revised budget narrative, and the Advisory
                               #   Committee's 2026-08-11 AWARD APPROVALS, minutes and
                               #   agenda — a named, priced roster NOT YET EXTRACTED —
                               #   plus the programme page, public notice, the
                               #   applications-opened release and the Submittable portal
    TN/                        #   probe BASELINES (script-stripped): the RHTP
                               #   programme page, the TDH news index and RAMP
                               #   -- the STATE-money §0.1 control. The award
                               #   sources are under recheck/2026-09-23/TN/
    recheck/<date>/<ST>/       #   the completeness re-check: award pages AND their children
                               #   (2026-09-22/: NY's RCHI roster and KS's Emerging
                               #   Technology winners, found by session 51, UNEXTRACTED)
    federal_records/<date>/    #   CMS enrolment (MS, SC), NPPES and IRS EO BMF
                               #   extracts, as served, with a SHA-256 manifest
output/
  rhtp_hospital_tracker_<date>.xlsx
  review_queue_<date>.xlsx
  state_source_registry_worksheet_<date>.xlsx   # §7.2, for offline verification
logs/
  pull_manifest.csv            # COMMITTED
  probe_results.csv            # COMMITTED — EVERY --probe's verdict, appended:
                               #   state, timestamp, CHANGED/UNCHANGED/TRIPWIRE
                               #   /ERROR, and which page. A Routine's answer
                               #   that lives only inside a fired session
                               #   transcript costs a human the work of opening
                               #   that session to read it (§0.5)
  normalize_manifest.csv       # COMMITTED, schema-pinned (§13.20)
config/
  config.yml                   # base URL, paths, cadence, quota budget, CMS source
  routines.csv                 # EVERY Routine: state, trigger id, cron, script, logging_since
  routine_prompt_template.md   # the prompt a Routine runs (session 52)
docs/
  claude_md_history_sessions_01_76.md # CLAUDE.md §10 as of session 76, VERBATIM (session 77)
  rerun_commands.md            # every CLI entry point (moved from §10, session 77)
  session77_claude_md_trim_checkin_montana.md # the trim, the 09-29 check-in, MT
  session78_status_table_assertion_runner_context.md # Deliverable 1 asserted; why runners double
  stage0_preflight_findings.md # Stage 0 API reconnaissance (authoritative)
  stage3_allotments_and_registry.md  # §7.1 anchor, §6.4 mining, §7.2 worksheet
  stage2.5_budget_narratives.md      # §7A parser, the §7A.4 gate, gaps left open
  session10_roster_live_monitor_recipient_type.md  # GA roster, live stage 00, §8
  session11_six_state_award_list_hunt.md  # AK/AL/ND/OH/PA/SD award-list locators
  session12_pa_al_ak_extraction_and_sd.md # PA/AL/AK extracted; the SD portal's shape
  session13_sd_announcements_adeca_and_monitor.md # SD names nobody; ADECA has no file
  session14_cms_newsroom_trigger_virginia.md # newsroom primary; VA is at RFA stage
  session15_virginia_dmas_negative.md # DMAS hosts no RFA series; the §0.2 worked example
  session16_rcj_state_survey_illinois.md # the trigger list was never a census
  session17_oregon_extraction.md     # Oregon: 7 pools; the 99 x $100k are CLINICS
  session18_hospital_association_flow_rule.md # §10.2 associations; 0 rows moved
  session19_flow_fix_texas_negative.md # the flow short-circuit; TX is state money
  session20_provenance_sweep_kansas.md # state money in the §6.2 filter; KS is 3 pools
  session21_completeness_recheck_maryland.md # GA and AK have more; MD is 41 offers
  session22_georgia_alaska_maryland.md # GA's 21 named; AK needs a SCHEDULE; MD queued
  session24_indiana_procurement_channel.md # IN: awards are in PROCUREMENT; RCJ invented RHTP
  session25_indiana_recheck_oklahoma.md    # IN unchanged; OK's 68 microgrants vs the 48.7%
  session26_nevada_roster_without_amounts.md # NV: a named roster with NO amounts; the CMS
                                           # footer covers the PUBLICATION, not the programme
  session27_cms_footer_provenance_audit.md # the footer audit: KANSAS is the one load-bearing
                                           # case, and its independent check is already here
  session27_footer_audit_michigan.md       # MI: 139 awards, ONE named hospital; RCJ DEFLATES
  session30_wisconsin_pass_through_eligibility_audit.md # WI is SOLICITATION stage, awards due
                                           # SEPTEMBER; the 19-row pass-through eligibility sweep
  session32_line_model_runs_iowa.md  # the reader carries RUNS; IOWA extracted, 264
                                     # actions, 152 named hospitals, $0
  session31_marker_fix_wisconsin_watch_iowa.md # the marker becomes a MONEY test (2 rows, $0);
                                           # WI on a twice-weekly probe; IOWA's ELEVEN notices
  session33_maine_invited_cohort.md  # MAINE: 11 NAMED HOSPITALS, INVITED not awarded;
                                     # the row-count/dollar pairing INVERTED
  session74_vermont_update_three_trips_maryland_newsroom.md # VT +34
                                     # agreements, +15 hospital rows; MS/VA/NJ
                                     # trips read; MD newsroom opened
  session71_ahc_enrolled_hospitals_other_forms.md # AHCs are hospitals on
                                     # their CMS enrolment; 33 rows / $63.2M;
                                     # 5 OTHER rows withdrawn; 21 enrolment files
  session64_dual_track_registry_five_reextractions.md # Dual Track out of
                                     # the spec; 7 state programmes registered;
                                     # NV NE MI LA SD re-extracted; IN on a Routine
  session63_dispositions_prose_rule_indiana_grow.md # every disposition
                                     # re-read; the prose rule; 23 new
                                     # dispositions; Indiana GROW extracted
  session61_nj_extraction_indiana_regions_routines_newsroom_sweep.md # NJ
                                     # EXTRACTED; Indiana's 8 regions AWARDED
                                     # (read); 7 Routines; the newsroom sweep
  session60_exposed_set_rcj_refresh_va_wa.md # NJ's 103-row roster found (55 days
                                     # old); 27 states on no Routine; RCJ
                                     # re-pulled (86 calls); VA + WA extracted
  session59_tennessee_wa_footer_five_routines_nuvita.md # TENNESSEE EXTRACTED
                                     # (53, $0, 2 hospital rows); WA's
                                     # SUBAWARD_OF footer parsed; CO VA ND WA TN
                                     # on Routines; Nuvita -> OTHER
  session54_routine_cutover_vt_ct_wv_mo_extraction.md # Routines re-bound;
                                     # VT, CT, WV and MO's 20 SMRP hospitals
                                     # EXTRACTED; LA probe scoped past the menu
  session51_tier_bucket_refusals_rural_cut_live_probes.md # A BUCKET MUST NOT
                                     # MIX TIERS; 2 of 4 refusals settled; the
                                     # rural cut; NY and KS rosters found live
  session48_name_tripwire_sc_routine.md # the tripwire that reads NAMES, not
                                     # phrasings; SOUTH CAROLINA on a weekly
                                     # Routine; the totals re-derived
  session42_wyoming_extraction_wrong_state_defect.md # WYOMING EXTRACTED — 75
                                     # actions, 31 named hospitals, $72.7M; the
                                     # RUN MODEL loses $5,156,000 without it;
                                     # §0.1 gains FAILURE MODE 6, the WRONG STATE
  session40_arkansas_extraction.md   # ARKANSAS EXTRACTED — 31 orgs, 37 award
                                     # actions, $149,177,618.45, and TWO
                                     # PUBLISHERS AT TWO GRAINS reconciling to
                                     # the cent; the 8th digest mechanism
  session39_managed_care_code_five_zero_signal_states.md # §8 gains
                                     # MANAGED_CARE_ORGANIZATION (2 of 3 rows);
                                     # ARKANSAS has a $149M PRICED ROSTER; SC
                                     # AWARDED BY EMAIL; MN/TN/NJ negatives
  session38_nc_extraction_ny_class.md # NORTH CAROLINA EXTRACTED — 44 named, $0,
                                     # NO bucket; NY/KY/NC on Routines; §10.2's
                                     # THIRD eligible class
  session37_footer_tier_ky_ny_nc.md  # the footer's TIER is not in its GRAMMAR;
                                     # KY and NY are NEGATIVES with PASSED dates;
                                     # NORTH CAROLINA has TWO ROSTERS, 44 NAMED
  session36_ct_nm_watch_date_test_louisiana.md # CT and NM on watches; the NOA
                                     # anchor PINNED to the budget period; LOUISIANA
                                     # is a NEGATIVE with SEVEN windows ALL PASSED
  session35_california_watch_connecticut_new_mexico.md # CALIFORNIA on a WED/SAT
                                     # watch; CONNECTICUT's award date PASSED
                                     # 16 days ago; NEW MEXICO stacks THREE defects
  session34_maine_watch_california_seismic.md # MAINE on a TWICE-WEEKLY schedule;
                                     # CALIFORNIA is a NEGATIVE and its ELEVEN
                                     # candidates are a SEISMIC programme
```

**Persistence rules differ from normal practice.** `data/raw/`,
`data/evidence/`, `data/interim/review_queue.*`, `logs/probe_results.csv`
and `logs/pull_manifest.csv`
are all committed. `.gitignore` excludes **only** `.Rhistory`, `.RData`,
`.Rproj.user/`, and `.Renviron`.

Monitor `data/evidence/` as archived PDFs accumulate; if the repo approaches a
few hundred MB, move the archive to shared storage and keep the file paths
recorded in the workbook rather than the files themselves.

---

## 5. Controlled vocabularies (spec §8)

Stored as `data/reference/vocabularies.csv`. **Validate every categorical column
against it. No free-text categories anywhere. Do not invent codes mid-session.**

**`award_tier`**
`STATE_ALLOTMENT` | `SOLICITATION` | `SUBAWARD` | `UNASSIGNED`

**`source_doc_type`**
`NOTICE_OF_AWARD` | `NOTICE_OF_INTENT_TO_AWARD` | `PROCUREMENT_PORTAL_POSTING` |
`STATE_BUDGET_NARRATIVE` | `AGENCY_PRESS_RELEASE` | `GOVERNOR_PRESS_RELEASE` |
`THIRD_PARTY_NEWS` | `OTHER`
*Strength ordering matters: the first three are primary; press releases are
secondary; third-party news alone can never support a `Yes`.*

**`rhtp_award_confirmed`**
`Yes` | `No` | `Unclear`

**`recipient_type`**
`HOSPITAL_OR_SYSTEM` | `HOSPITAL_AFFILIATED_ENTITY` | `FQHC_OR_RHC` |
`EMS_OR_PSAP` | `UNIVERSITY_OR_AHC` | `AHEC` | `SCHOOL_OR_DISTRICT` |
`LOCAL_GOVT_OR_PUBLIC_HEALTH` | `TRIBAL_ORG` | `STATE_AGENCY` |
`VENDOR_OR_CONTRACTOR` | `NONPROFIT_CBO` | `PHYSICIAN_PRACTICE` |
`MANAGED_CARE_ORGANIZATION` | `OTHER` | `NOT_YET_NAMED`
*A named recipient whose form the source does not state is `NONPROFIT_CBO` +
`determination_confidence = LOW` + `flag_reason = RECIPIENT_TYPE_INFERRED`
(settled session 10; Florida's `UNCLASSIFIED` was back-fitted to it).
`PHYSICIAN_PRACTICE` is a determinable form, not that fallback.*

> **`MANAGED_CARE_ORGANIZATION` was added in session 39, and the reason it was
> added is a condition distinct from every code before it: THE SOURCE STATES A
> FORM §8 DOES NOT CARRY.** Kansas, Maryland, Nebraska, Oklahoma, Nevada,
> Michigan, Missouri and Iowa all publish a recipient and say **nothing** about
> its form, and the standing answer for that is `NONPROFIT_CBO` + `LOW` +
> `RECIPIENT_TYPE_INFERRED`. North Carolina states the form and §8 had no code
> for the answer — NCDHHS calls Trillium Health Resources *"an NC Medicaid
> Tailored Plan and **Managed Care Organization (MCO)**"* and Vaya Health *"a
> public NC Medicaid **Managed Care Organization (MCO)**"*. Using the standing
> fallback there asserts the form is **undetermined** when the state has stated
> it outright, which is the one thing `RECIPIENT_TYPE_INFERRED`'s own note
> forbids.
>
> **It is not `VENDOR_OR_CONTRACTOR`** — an MCO receiving a subaward is not a
> supplier to the state. **It is not `STATE_AGENCY` even where the state's own
> word is *"public"*** (Vaya): a public MCO is a local political subdivision
> managing a benefit, not the awarding agency, and `STATE_AGENCY` would make a
> recipient look like the grantor. **And it is never a hospital type** — an MCO
> contracts hospitals, it is not one — so the code can only keep dollars **out**
> of the hospital total, which is what makes it safe to add.
>
> **It deliberately does NOT reach a care management provider.** Access East,
> Inc. is the third NC Hub Lead whose form NCDHHS states, and that stated form
> is *"a **comprehensive care management provider**"* — a different thing from
> an MCO in North Carolina's own Medicaid vocabulary. **The code was not widened
> to swallow it (§0.4)**: Access East keeps §8's standing fallback and stays in
> the review queue, which is now one row rather than three.

> **`OTHER` WAS ADDED IN SESSION 49, ON THE FOOTING `PHYSICIAN_PRACTICE` AND
`MANAGED_CARE_ORGANIZATION` ESTABLISHED: a named recipient whose
organisational form IS determined, is not in this list, and is not a
hospital.** Thirty-five verified answers are in it — a retail pharmacy, a PACE
organisation, a non-emergency medical transport company, a regional workforce
investment board, a nursing home, a midwifery practice, a hospice's
foundation, a mobile diagnostic-imaging company. > > **It is NOT the standing
fallback**, which says the form is *undetermined*: using the fallback for a
form somebody has determined asserts an ignorance the record no longer has,
which is the error `MANAGED_CARE_ORGANIZATION` was added to avoid. **It is not
`VENDOR_OR_CONTRACTOR`**, which says the recipient supplies the state. **And
it is never a hospital type**, so like the MCO code it can only keep dollars
OUT of the hospital total, which is what makes it safe to add. > > **A row
carrying it must state the determined form in `determination_basis`.** `OTHER`
with nothing behind it is the fallback wearing a different name, and that is
the one use this code does not have.

**`recipient_subtype` and `cms_enrolment_match` were added in session 71**, on the
14 files §10.2's enrolled-hospital-operator rule touched. `ACADEMIC_HEALTH_CENTER`
is a SUBTYPE of `HOSPITAL_OR_SYSTEM`, never a type: it marks an academic health
centre typed a hospital on its CMS enrolment, so any figure can be reported with
those rows shown separately or subtracted. `cms_enrolment_match` is
`EXACT_LEGAL_NAME` (MEDIUM) or a hand-read bridge, `LEGAL_NAME_TRUNCATED` or
`DBA_OF_LEGAL_ENTITY` (LOW).

**`flag_reason`** — three codes added in session 12, each for a condition no
existing code covered, each written into `vocabularies.csv` with full notes:
`AMOUNT_ROUNDED_IN_SOURCE` (the source published the amount rounded — Alabama,
45 of 138 rows), `AMOUNT_PRELIMINARY` (the source says the amount is not final —
Alaska, every row), `RECIPIENT_TYPE_VARIES_IN_SOURCE` (one named recipient
carries different forms on different rows of one document — Alaska, 26 rows).
Every state assert now validates `flag_reason` against the vocabulary, so a
fourth invented code fails at the state that invents it.

**A fourth was added in session 17**, on the same deliberate footing:
`AMOUNT_RANGE_IN_SOURCE` — the source publishes a **range** where a
per-recipient amount would go (Oregon's Immediate Impact Wave 1 prints
"$403,000 – $778,000"). `amount` is left **empty** and the bounds go in
`amount_low` / `amount_high`, because picking the low bound, the high bound or
the midpoint would all publish a figure the state has not.

**A fifth was added in session 19**, for the branch the flow fix opened:
`FLOW_UNRESOLVED_HOSPITAL_AFFILIATED` — the recipient is hospital-affiliated
(an association, a foundation, a hospital-owned nonprofit) and the source says
nothing about where the money goes. Silence is evidence for a school district;
it is not evidence here, so the row is `PASS_THROUGH_UNRESOLVED` + `Unclear`
and enters **neither** bucket of `rhtp_hospital_dollar_partition()`.
**Session 26 committed the first row to carry it**: Nevada's Incline Village
Community Hospital Foundation, a hospital's own foundation awarded to recruit
providers, with the source silent on whether the money reaches the hospital.

**A sixth was added in session 26**, for a condition no existing code covers:
`POOL_AMOUNT_CONFLICTS_ACROSS_SOURCES` — **two of the state's own documents
attach different totals to the same award pool.** Nevada's 2026-06-09 fiscal
deck prints *"$14,394,529 available"* against WRRAP Recruitment and Retention
and *"$32,387,689 available"* against Apprenticeship and Training; its
2026-07-29 press release announces **$32.3M awarded** for recruitment and
retention and **$14.3M** for apprenticeship and training. The deck's pairing was
checked against the PDF's own **glyph positions**, not the reader's line order,
so it is the source and not the parse. Two readings survive — a reallocation
between the sub-funds while *"negotiating final awards"*, which the totals
support almost exactly ($46,782,218 available vs $46,600,000 awarded), or a
swapped label — and **neither is published as a finding (§0.4)**.
`round_amount` takes the award announcement's figure, because §8's
source-strength ordering makes an award announcement the better authority on
what was *awarded* than a pre-award planning deck is; the flag is what tells a
reader the other figure exists. It is a **POOL-level** flag: no per-recipient
amount is in dispute, because Nevada publishes none at all.

**A seventh was added in session 50**, for Iowa's Centers of Excellence pool
row and for a condition no existing code covers: `AMOUNT_IS_POOL_NOT_AWARD` —
**the only figure available is the RFP's advertised pool, the source calls it
approximate, and it is not an award total.** It is not `AMOUNT_PRELIMINARY`,
which says a per-recipient figure is not final; here there never was one. It is
not `AMOUNT_RANGE_IN_SOURCE`, which has bounds, nor `AMOUNT_ROUNDED_IN_SOURCE`,
which is a rounded award. **A row carrying it must also carry a pool
attribution** — a pool figure sitting in `NAMED_HOSPITAL` reads as named
recipients' awards — **and its `amount_basis` must state the TIER the figure
carries**, because Iowa's is Tier 2 while every other dollar in the hospital
partition is Tier 3.

> **Session 51: no row carries it now.** The Iowa pool row was removed (a
> bucket must not mix tiers, §0.2), and the partition refuses any priced row
> carrying this code. It stays in the vocabulary so the audit trail closes.

**`extraction_status` gained `INVESTIGATED_NO_LIST` in session 19** (and
`queue_status` the same code): the state has been worked against its own
sources and publishes no recipient-level list. **Not `NOT_EXTRACTED`, which
means nobody has looked** — left as that, Texas would have ranked 1 on every
future survey and been re-investigated from scratch. It is never a claim that
the state awarded nothing.

**AND IT GAINED `INVESTIGATED_NO_PROBE` IN SESSION 43, FOR A CONDITION THAT
CODE PROMISES MORE THAN.** `INVESTIGATED_NO_LIST` means a **re-checkable**
negative: a committed evidence archive **AND** a probe carrying a tripwire that
re-opens the state the day it publishes. Six states — **HI, MA, MN, NJ, SC,
TN** — had been worked in sessions 39 and 41 and had **neither**: only Hawaii
has an evidence archive at all, for the other five the finding lives in session
documents in **prose alone**, and **not one of the six has a probe**. Left at
`NOT_EXTRACTED` they read as *nobody has looked*; called
`INVESTIGATED_NO_LIST` they would claim a tripwire that does not exist.

**AND TWO OF THE SIX ARE NOT NEGATIVES, WHICH IS THE SECOND REASON.** **SOUTH
CAROLINA HAS AWARDED** — bulletin MB# 26-026, *"Notices of Award Determination
for the 712 applications received ... Applicants should check their email"* —
so "publishes no recipient-level list" is true of the **list** and false about
the **stage**. **MASSACHUSETTS IS UNREADABLE, NOT SILENT**: every `mass.gov`
path is Akamai-403 on four agents, so asserting it publishes no list would be a
statement about the state made from a fact about our access (§0.4, New
Hampshire's rule). **HAWAII names ONE award** whose amount lives only in HANDS,
which is 403.

**The code says what THIS REPOSITORY DID, never what the state published**, and
its note states that it is deliberately weaker, that the finding **goes stale
by construction**, and that **the intended next action is to write the
probe** — after which the state moves to `INVESTIGATED_NO_LIST` or
`EXTRACTED`.

**Two more were added in session 20**, both §6.2 provenance and both
QUARANTINE, on the same footing as the federal `PROVENANCE_MISMATCH`:
`PROVENANCE_STATE_PROGRAM` (the source ties to a state-funded or
state-administered programme that is not RHTP — a legislative appropriation,
opioid or tobacco settlement money, Medicaid managed care, an intergovernmental
transfer) and `PROVENANCE_PREDATES_NOA` (the source dates the award action
before that state's CMS Notice of Award, so the state did not yet have the
money). **Appropriation language is not an available marker and that is
measured, not assumed** — across all 1,366 committed Tier 3 candidates
`Rider \d+` matches 0 rows, `House Bill` 0, `General Revenue` 0, `biennium` 0,
and `appropriat` exactly 1, a Pennsylvania row that is genuine RHTP. What RCJ
carries is the state's RFA number, not its funding source, which is why the
state half is a hand-verified registry keyed on that identifier.

**`flow_type`**
`DIRECT` | `PASS_THROUGH_DESIGNATED` | `PASS_THROUGH_UNRESOLVED` |
`IN_KIND_BENEFIT` | `NON_HOSPITAL`

> **`DIRECT` is reachable only from `HOSPITAL_OR_SYSTEM`** (session 19).
> `HOSPITAL_AFFILIATED_ENTITY` used to short-circuit to it before any
> description was read, which let `recipient_type` pre-decide flow; an
> affiliated entity is by construction not the hospital §10.2's `DIRECT` row
> tests for, so it now reads the source like every other type.

**`hospital_attribution`** (added session 16; a third bucket added session 23)
`NAMED_HOSPITAL` | `POOL_NAMED_HOSPITALS` | `POOL_UNNAMED_HOSPITALS` |
`NOT_HOSPITAL`
*The column that keeps a `PASS_THROUGH_DESIGNATED` dollar separable from a
named-hospital dollar. All are `distributed_to_hospital = Yes` and they must
**never** be added. `rhtp_hospital_dollar_partition()` returns the figures;
`rhtp_hospital_total()` exists only to refuse.*

> **`POOL_NAMED_HOSPITALS` was added deliberately in session 23**, for a
> condition neither existing code could describe honestly. Nebraska's
> **$18,156,856.12** award to the **Nebraska High Value Network** is a
> `PASS_THROUGH_DESIGNATED` whose subrecipients DHHS **names** — twenty-one
> hospitals, on the notice — while publishing **no per-hospital split**.
> `NAMED_HOSPITAL` is false, because nobody can say what any one of them
> received and §6.2 forbids dividing; `POOL_UNNAMED_HOSPITALS` is false in the
> more damaging direction, because it asserts no hospital is named when
> twenty-one are. `rhtp_hospital_total()` now **refuses to run at all** if the
> partition returns a bucket it does not name — a new code missing from the one
> summary a reader sees is exactly what that function exists to prevent.

**`survey_status`** / **`extraction_status`** / **`trigger_source`** /
**`queue_status`** (added session 16) — the coverage-survey and trigger-queue
codes. See `vocabularies.csv`; `trigger_source = NEITHER` is a statement about
the discovery layers, never about the state.

**`distributed_to_hospital`**
`Yes` | `No` | `Unclear`

**`determination_confidence`**
`HIGH` | `MEDIUM` | `LOW`

**`activity_type`**
Map to the CMS RHTP allowable-use categories (the CMS category guidance series —
e.g. Category E covers workforce). Retain the state's own raw activity language
in a parallel `activity_type_raw` field; **never discard it.**

---

## 6. RCJ machine-generated fields — search aids only

RCJ's record descriptions read as LLM-generated, and the platform offers opt-in
AI answer synthesis. **Nothing synthesized may be quoted as fact in an AHA
product.** Quotable text comes from the source document via §9.

Fields confirmed machine-generated in Stage 0 and therefore **non-quotable**:
`programDescription`, `programHighlights`, `highlights`, `progressSummary`,
`strategicGoals`, `transformationStrategy`, `summary`, `milestones`,
`performanceTargets`, `completenessScore`, `implementationPhase`,
`activityType` (RCJ's own coding), and any `aiAnswer` from `POST /api/v1/search`.

---

### 6.1 The SIX ways an RCJ record can be wrong about an award (spec §0.1)

Numbered because they are **independent** — a candidate can pass five and fail
the sixth. Read a candidate against all six before building an extractor.

| # | Failure mode | Worked case |
|---|---|---|
| 1 | **Wrong programme** | Texas's 53 Rider 88 awards ($16.8M); California's eleven cigarette-tax seismic awards ($5,475,000) |
| 2 | **Wrong tier** | Oklahoma's 35 budget lines ($231,614,376, more than the allotment); Louisiana's six *projected* rows |
| 3 | **Wrong kind of action** | Missouri's 27 Hub Anchors at $1; Maine's eleven *invited* hospitals at $1 |
| 4 | **Wrong grain** | Michigan, one row per ORGANISATION against one per AWARD, −$7,833,333; California's two rows for one $780,000 grant |
| 5 | **Wrong section** | Nebraska's 24 awards under the APPLICANT roster's heading |
| 6 | **Wrong state** | **Wyoming — five of 29 records are UTAH's, including Utah's own $195.7M allotment as an `UNASSIGNED` Wyoming row** |

> **Mode 6 was added in session 42 and it is different in kind.** Modes 1–5 are
> defects *in* a record. Mode 6 is a defect in **which state the record is**, so
> every state-scoped check this project runs — the §6.2 registry, the date test,
> the allotment ceiling, the §8 name rules — is applied to the wrong state's
> data and passes.
>
> `R/02c_state_attribution_sweep.R` measures it across all 5,056 committed
> records. **TEN records are another state's, in FIVE states** — WY←UT (5),
> ND←AR (2), MO←MI, UT←OK, WA←FL — so Wyoming is the largest and not the only
> one, and **Utah is its mirror**. **AND NOT ONE OF THE TEN IS TIER 3**, the
> only tier an extractor reads, so the defect has **not reached a single award
> file here**. That is a measurement of the corpus as pulled 2026-08-27, never
> a property of the aggregator — re-run it, do not assume it.
>
> **The sweep FLAGS and a human READS.** All EIGHT of its Tier 3 flags are
> false positives with legible causes: a state name inside the recipient's own
> legal name (*Providence Health & Services–Washington*, a real ALASKA
> awardee), a bare county in a county list (Alabama's *"(Clarke, Washington)"*),
> a street address (*905 Washington Street*). Widening the exclusion list until
> the output is empty would suppress the ten real ones with the eight false, so
> the verdicts are hand-read and visible in `SWEEP_VERDICTS`.

## 7. Confirmation decision rules (spec §9.2)

Apply these **mechanically**. The `Unclear` bucket becomes a dumping ground
unless these rules are explicit and applied consistently. Reviewer consistency is
what makes the file defensible.

**`Yes`** — a state agency or designated pass-through administrator document
names **both the recipient and the award**. `validation_source_type` must be
`NOTICE_OF_AWARD`, `NOTICE_OF_INTENT_TO_AWARD`, `PROCUREMENT_PORTAL_POSTING`,
`STATE_BUDGET_NARRATIVE`, or an official agency/governor press release that names
the recipient.

**`No`** — the state source contradicts RCJ, or shows the solicitation
cancelled, withdrawn, unawarded, or re-opened without award.

**`Unclear`** — any of: the only available source is third-party news; amounts
conflict across sources; the page exists but names no recipients; the record is a
pass-through pool with unresolved subrecipients; the source is a projection or
plan rather than an award action.

### Flow determination (spec §10.2)

| `flow_type` | Test | `distributed_to_hospital` |
|---|---|---|
| `DIRECT` | Named recipient matches a hospital in AHA/POS | `Yes` |
| `PASS_THROUGH_DESIGNATED` | Intermediary receives funds, but the source document names hospital subrecipients or restricts eligibility to hospitals **and the award has been made** | `Yes`, with `intermediary_name` populated |
| `PASS_THROUGH_UNRESOLVED` | Intermediary administers a pool where hospitals are among eligible entities, recipients not yet named | `Unclear` — **do not impute** |
| `IN_KIND_BENEFIT` | Funds go to a vendor or state system that hospitals use but do not receive | `No`, but set `hospital_benefiting = Yes` |
| `NON_HOSPITAL` | Recipient is clearly not a hospital — a school district, a university, an EMS agency, a vendor. **Judge the recipient, never the activity (§0.3a):** Nebraska's school kitchen modernization awarded to the Department of Education is `NON_HOSPITAL`; Delaware's school-based health center awarded to Beebe Healthcare is `DIRECT`. Same setting, different recipients, different codes. | `No` |
| `PASS_THROUGH_DESIGNATED` — hospital trade associations and hospital-governed entities | An award to a hospital association, hospital-owned nonprofit, or association foundation, **provided the source shows the funds are administered to or on behalf of member hospitals**. Record the entity in `intermediary_name`. See the worked examples below the table. | `Yes`, with `intermediary_name` populated |
| `DIRECT` — a hospital's own foundation or affiliated arm | A foundation or affiliated arm of a **named** hospital or health system is `recipient_type = HOSPITAL_OR_SYSTEM` and takes the `DIRECT` row above. The test is the PARENT: a foundation of an ASSOCIATION of hospitals is the row above this one, and a foundation whose parent is not a hospital is not reached at all. See the worked examples below the table. | `Yes` |
| `DIRECT` — an academic health center or other enrolled hospital operator | The awardee's legal entity is enrolled with CMS as a hospital (UAMS, CCN 040016). `recipient_type = HOSPITAL_OR_SYSTEM`, CCN on the row, `recipient_subtype = ACADEMIC_HEALTH_CENTER` where it is one. The name reading "university" does not override the enrolment (§0.4), and the activity does not decide it (§0.3a). See the worked examples below the table. | `Yes` |

`IN_KIND_BENEFIT` gets its own flag rather than being discarded: it matters to
AHA's narrative even though those dollars must **never** enter a "funds
distributed to hospitals" total.

`determination_confidence`: `HIGH` (primary source, named hospital recipient, CCN
matched) / `MEDIUM` (primary source, hospital identity inferred from name without
CCN match) / `LOW` (secondary source or unresolved pass-through).

`determination_basis` is **free text and mandatory**. When someone asks in six
months why a $12M award was coded hospital-bound, the answer must be in the row.

#### Hospital trade associations and hospital-governed entities

An award to a **hospital association, hospital-owned nonprofit, or association
foundation** is `recipient_type = NONPROFIT_CBO`, `flow_type =
PASS_THROUGH_DESIGNATED`, `distributed_to_hospital = Yes` — **provided the
source shows the funds are administered to or on behalf of member hospitals**.
Record the entity in `intermediary_name`.

**Worked examples.** *Illinois Critical Access Hospital Network,
$50,008,264* — the source states ICAHN *"will administer the funds to Critical
Access Hospitals and other eligible non-urban Illinois hospitals."* *Oklahoma
Hospital Association, CHW Expansion in Hospitals, $4,300,000* — *"implementation
will be conducted by hospitals reimbursed for CHW hiring, training, and
monitoring."*

**This does not extend to an association's own operating, advocacy, or
membership costs where the source shows no flow to hospitals. That is
`NON_HOSPITAL`. The test is what the document says the money does, not what the
organization is.**

**And it does not reach an association that keeps the money and delivers goods
or services with it.** That is `IN_KIND_BENEFIT`, and the two worked negatives
are the reason this row cannot be applied from the organisation's name alone.
The *Georgia Hospital Association* "received a grant … to provide obstetrical
emergency carts": carts reach hospitals, dollars do not. The *Alaska Hospital &
Healthcare Association* proposes "Strategic, Financial, and Operational
Assessments … for three independent Critical Access Hospitals" — it **names**
three hospitals and still administers nothing to them, because AHHA performs the
assessments. Both of the positive examples above move **money** to hospitals
("administer the funds to", "reimbursed"); neither negative does.

#### A count of hospital awards with no names enters no bucket (session 65)

A state-published **count and total of hospital awards that names none of
them** (Louisiana RCCB: "Hospital settings 20 awards · $6,285,515") is Tier 3
and is still in **no** hospital bucket: no bucket describes a direct award to
unnamed hospitals (`POOL_UNNAMED_HOSPITALS` is a pass-through intermediary),
it overlaps the named rows by an amount the source does not resolve, and a
facility type is a setting, not a recipient (§0.3a). Report it beside the
partition, never inside it. It reopens only when the state names the awards.

#### Hospital foundations and affiliated arms

**A foundation or affiliated arm of a *named* hospital or health system is
`recipient_type = HOSPITAL_OR_SYSTEM`.** Its flow is then §10.2's ordinary
`DIRECT` row — the recipient-identity test — and its dollars are
`NAMED_HOSPITAL`, not a pool. A hospital's fundraising arm is the hospital's,
and the money it receives is the hospital's money.

**The load-bearing word is *named*, and it is what stops this row swallowing
the one above it.** The rule reaches an entity whose own name, or whose source,
identifies the single hospital or health system it belongs to: *Sky Lakes
Foundation* (Sky Lakes Medical Center), *MercyOne North Iowa Foundation*,
*Incline Village Community Hospital Foundation*, *St. Bernards Development
Foundation*, *Citizen's Foundation (Citizens Health)*.

**It does not reach the foundation of an ASSOCIATION of hospitals.** New
Hampshire's Foundation for Healthy Communities is the state hospital
association's foundation and its eligible class is *"primary care, critical
access hospitals, EMS, behavioral health, oral health, and community-based
organizations"* — hospitals among others, which is §0.3 — so it stays
`PASS_THROUGH_UNRESOLVED` + `Unclear`. Nevada Rural Hospital Partners
Foundation is the same shape. Reading those two as hospital foundations would
move **$66,547,394** into the hospital total on this pipeline's authority.

**And it does not reach a foundation whose parent is not a hospital.** Talbot
Hospice Foundation's parent is a hospice; Cahaba Medical Care Foundation is an
FQHC incorporated as a foundation; Superior Health Foundation is a conversion
grantmaker with no parent at all. The test is the PARENT, and it is applied
before the word *foundation* is read.

**Where the parent is not stated, the row is NOT promoted (§0.4).** Kansas
publishes two spellings — *Citizen's Foundation (Citizens Health)*, which names
its parent, and *Citizens Foundation*, which does not — and they classify
differently, **$146,476** apart, because §2 forbids a machine resolving the
difference. That divergence is the rule working, not a defect in it.

#### Academic health centers and enrolled hospital operators

**Where CMS enrolls the awardee's legal entity as a hospital, the recipient is
`recipient_type = HOSPITAL_OR_SYSTEM`, and the CCN goes on the row.** Its flow
is §10.2's ordinary `DIRECT` row, and its dollars are `NAMED_HOSPITAL`. An
academic health center that holds the hospital's enrolment is a hospital. The
University of Arkansas for Medical Sciences is the worked case. CMS Hospital
Enrollments carries ORGANIZATION NAME *"UNIVERSITY OF ARKANSAS FOR MEDICAL
SCIENCES"*, DBA *"UAMS MEDICAL CENTER"*, CCN 040016. That is the awardee's own
legal name, and it names one legal body that is both a university and a
hospital operator.

**The CMS enrolment is a primary federal source. The name is not a source.**
Keeping such a recipient at `UNIVERSITY_OR_AHC` because its name reads
"university" overrides a federal record with this pipeline's recognition of the
name, and §0.4 forbids that. Sessions 17 and 38 did this for OHSU and UNC.
Session 50 did the opposite for Winston County Medical Foundation, promoting it
because CMS carries its exact string as a hospital's ORGANIZATION NAME. This
row settles the conflict in Winston County's favour.

**The activity does not decide it (§0.3a).** Telehealth networks, residency and
nursing training, stroke education, mobile outreach and food-is-medicine are
hospital operations when a hospital runs them. The test is the recipient's
legal identity, not what the award buys.

**The rows stay separable.** Every row this rule re-types as an academic health
center carries `recipient_subtype = ACADEMIC_HEALTH_CENTER`, so any hospital
figure can be reported with those rows shown separately, or subtracted, without
re-coding anything. `cms_enrolment_match` records how the legal entity was
matched:
- `EXACT_LEGAL_NAME` sets `MEDIUM`.
- A hand-read bridge sets `LOW`. `LEGAL_NAME_TRUNCATED`: *"University of North
  Carolina Hospitals"* for *"... AT CHAPEL HILL"*. `DBA_OF_LEGAL_ENTITY`:
  *"University of Iowa Health Care"*, the trading name of the State University
  of Iowa's enrolled hospital.

`HIGH` still requires the CCN to be confirmed through Stage 5's full match.

**What it does not reach.**
- **A different legal body with a similar name.** *"University of Alabama"*
  (Tuscaloosa) is not the University of Alabama at Birmingham. *"University of
  Arkansas"* is not UAMS. *"Johns Hopkins University"* is not The Johns Hopkins
  Hospital, and *"Medical University of South Carolina"* is not the Medical
  University Hospital Authority. A name that is only a prefix of an enrolled
  name is never matched by machine (§2).
- **An abbreviation or a sub-unit named without the legal entity.** Examples:
  *"UAB Montgomery"*, *"OHSU Casey Eye Institute"*, *"University of Michigan:
  MEDIC"*. The enrolled legal entity is the Regents of the University of
  Michigan, and the awardee string does not name it.
- **A row whose awarding state states a different form.** Examples: Alaska's
  own Organization Type column saying *"Tribal Health Organization"*, or Oregon
  paying a hospital-owned clinic from its Rural Health Clinic pool under the
  type *"Rural Health Clinic"*. There two primary sources disagree, and the
  precedence rule below decides it.

**Precedence when the state and CMS disagree (session 72).** Where the
awarding state's own award document states the recipient's form, **that form
stands**. The CMS enrolment is recorded on the row, in `cms_enrolment_record`
(legal name, DBA, CCN, archived file), and does not re-type it.
`cms_enrolment_match` and `ccn` stay empty, because both mean the row was
re-typed on the enrolment. The CMS enrolment decides only where the state
states no form, as for AltaPointe Health Systems (CCN 014014), whose
governor's release names the entity and says nothing of its form. The reason
is that the award document is the source of record for what the state awarded
and to whom (§0.1). Its statement of the form is part of the award; an
enrolment says what else the legal entity operates. This settled
`ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM` at option (a): ten Alaska and
Oregon rows keep their state-stated coding, and $0 moved.

#### The eligible class of a pass-through, and when a hospital is required

**The eligible class is what decides a pass-through, and there are now three
answers rather than two.** Illinois and New Hampshire are the same shape — an
executed award to a designated pass-through administrator with no hospital
named — and they code opposite ways. ICAHN is `Yes` because Illinois restricted
eligibility to **hospitals only**, so every possible recipient of the money is a
hospital. FHC is `Unclear` because its class is *"primary care, critical access
hospitals, EMS, behavioral health, oral health, and community-based
organizations"* — hospitals **among others**, which is §0.3 exactly, so nobody
can say a hospital received anything.

**New York's RCHI is the third, and it is neither.** Its own funding guidance
says *"A **hospital must be included** as either the lead applicant or the
partner Organization"* — a hospital is **mandatory in every single award** and
**need not be the recipient**, because the lead applicant may be a 501(c)(3).

**It is not ICAHN's `Yes`.** ICAHN's `Yes` rests on the recipient necessarily
being a hospital; New York's rule guarantees only that a hospital is *in the
partnership*, and the dollar may be awarded to the non-hospital lead.

**And it is not `Unclear` for FHC's reason, which is the part that matters.**
FHC is `Unclear` because a hospital *might* be among the eventual recipients and
might equally not be. New York's rule is stronger than "might": a hospital is
present in every awarded partnership, by rule, and that is knowable in advance.
The FHC sentence — *we cannot say a hospital is involved* — is simply false
here. What is still unknown is different and narrower: **whether any dollar
reaches the hospital that had to be in the room.**

**So the rule is: a required partner is not a recipient — participation is not
receipt, exactly as eligibility is not receipt (§0.3) — and the coding is read
off the AWARD, one award at a time, never off the eligibility rule.**

| What the award document shows | Coding |
|---|---|
| The lead applicant is itself the hospital | `DIRECT`, `distributed_to_hospital = Yes` — ordinary §10.2, and the partnership rule adds nothing |
| The lead is a non-hospital, the partner hospital is **named**, and the source shows funds administered to or on behalf of it | `PASS_THROUGH_DESIGNATED`, `Yes`, `intermediary_name` = the lead. Where no per-hospital split is published this is `hospital_attribution = POOL_NAMED_HOSPITALS` (§8, Nebraska's code) |
| The lead is a non-hospital and the roster names **only the lead** | `PASS_THROUGH_UNRESOLVED`, `Unclear`. The hospital's presence is a fact about the **application**, not about where a dollar went |

**This class is the most seductive one this project has met, and that is why it
is written down before New York awards anything.** *"A hospital must be
included"* reads like a guarantee that every dollar reaches a hospital. It
guarantees that a hospital is in the room. A session that took the eligibility
sentence as the coding would publish New York's **$76,190,022** RCHI pool as
hospital-bound money on this pipeline's authority, against 91 applications DOH
was still reviewing.

---

## 8. Retrieval strategy — global pagination CONFIRMED (spec §5.1)

**Tested 2026-08-27 (Session 2). Result: Branch A. Pull nationally at max
`limit`, partition by state locally.** Full evidence:
`docs/stage1_pagination_test.md`.

`/awards`, `/documents`, and `/opportunities` all paginate **without** a `state`
filter. Unfiltered totals are genuinely national (1,429 awards / 3,092 documents
/ 631 opportunities; page 1 alone spans 21–32 states, and unfiltered `/awards`
at 1,429 dwarfs `state=GA` at 115). Page 1 and page 2 id sets are disjoint, and
the last page of each endpoint returns exactly the arithmetic remainder — so
deep pages are reachable and complete, with no cap.

### Implied monthly call volume

Per full national pull: `/awards` 3 + `/documents` 31 + `/opportunities` 7 +
`/activity` ~5 = **~46 calls**.

| Branch | Cadence | Calls/month | % of 2,000 |
|---|---|---:|---:|
| **A — global (confirmed)** | Weekly | ~199 | 10% |
| **A — global (confirmed)** | Twice-weekly | ~399 | 20% |
| B — per-state fallback (not needed) | Weekly only | ~800–900 | 40–45% |

**Twice-weekly is affordable** and is the recommended cadence through the
Year 1 → Year 2 transition, leaving ~1,600 calls/month of headroom.

Spec §5.1 projected 100–150/month for weekly; measured is **~199**, because
`/documents` alone is 31 of the 46 calls per pull against a hard 100/page cap.
Budget ~200, not ~125. Every additional 100 documents adds 1 call/pull, so
`/documents` is the line item to watch as the corpus grows.

### `limit` is silently capped — client requirement

`/documents?limit=500` returns **HTTP 200** while serving 100 rows and echoing
`pagination.limit: 100`. Over-max limits are neither honoured nor rejected —
they are quietly downgraded.

**Always compute the page count from the response's `pagination.limit` and
`pagination.total`, never from the requested limit.** A client trusting its own
`limit=500` on `/documents` would walk 7 pages, read 700 of 3,092 records, and
report success. That is the silent short-read failure mode in spec §5.2.

Confirmed maxima: `/awards` 500, `/documents` 100, `/opportunities` 100.

### 8.1 Redistribution rights — resolved, no longer blocking

**Superseded by revised spec §4.1.** RCJ still publishes no terms of service
(`/terms`, `/terms-of-service`, `/tos`, `/legal`, `/api-terms` all 404; the only
legal document is `/privacy-policy`, which covers account data and is silent on
reuse). The site footer says only: *"Not affiliated with HRSA, CMS, or HHS ·
Data aggregated from public state and federal sources · For research and
informational purposes only · Not intended as official program guidance."*

What changed is the project's scope, not the finding: **this project is
internal-use only and produces no published product**, so redistribution is not
a live question and is **not a blocker**.

If that scope ever changes, resolve permitted use with AME Mobile
(`info@amemobile.net` / `admin@amemobile.net`) **and AHA counsel before anything
leaves the building.** Principle §0.1 remains the primary mitigation either way:
no RCJ field enters a published number — every figure traces to a state primary
source that AHA retrieved and archived independently.

---

## 9. RCJ API quick reference

Full detail: `docs/stage0_preflight_findings.md`. Read it before writing any
retrieval code.

- **Base URL:** `https://www.ruralcarejourney.com` (`rhtp.amemobile.net` also
  supported). All endpoints under `/api/v1/`.
- **Auth:** `Authorization: Bearer <key>` or `X-Api-Key: <key>`.
- **Plan on our key: Pro — 2,000 requests/month, 60 requests/min, 250 AI
  answers/month.** Not the 10,000/month plan. Budget accordingly.
- **Quota headers (confirmed live):** `x-ratelimit-monthly-limit`,
  `x-ratelimit-monthly-remaining`, `x-ai-search-monthly-limit`,
  `x-ai-search-monthly-remaining`. No per-minute headers exist — the 60/min limit
  must be respected by client-side throttling.
- **Two envelope shapes.** `{data, pagination:{page,limit,total,pages}}` for
  `/states`, `/awards`, `/documents`, `/opportunities`, `/events`;
  `{data, count, page, hasMore}` for `/activity`. `POST /search` returns
  `{documents, count, hasMore, aiAnswer}`.
- **There is no `updated_since` filter on `/awards`, `/documents`, or
  `/opportunities`.** Only `/activity` supports `since`. Spec §5's delta-pull
  design must be reworked — see the findings doc.
- **`sourceDocument.url` is an RCJ-hosted proxy, not the state URL.** The
  original state source URL appears **only** in `/api/v1/activity` (`siteUrl`,
  `detail.updatedDocuments[].sourceUrl`).

---

## 10. Current state

**Last updated:** 2026-10-05 (Session 93). Session 93 closed two session-92 items on the owner's instruction: Valley Health, Ballad and Sentara accepted as system parents (`VA_VHCF_SYSTEM_PARENTS` RESOLVED; $0 moved, VA VHCF stays 9 / $6,390,000), and KY's Accredited Dental Hygiene conflict recorded on its status row with the RFA archived (stage unchanged). Detail: `docs/session93_va_parents_ky_dental_hygiene.md`. Session 92: Session 92 extracted VHCF's Provider Interoperability round (`R/03bx`, 25 awards, $14,390,000, typed on CMS VA enrolment: 9 hospital lines / $6,390,000, of which $5,700,000 is three system parents at LOW; Highland Medical Center is an FQHC; the two UVA Health strings, $884,000, joined `AHC_STRING_NAMES_NO_ENROLLED_ENTITY`), put VHCF's news index on `R/03bb`'s probe, registered VHCF's 07-10 grants as `VA-VHCF-REGULAR-GRANTS`, re-staged KY Community Paramedicine and EMS Training Equipment to `AWARDED_PRIVATELY_NO_PUBLIC_ROSTER` (three more RFA award dates watched; SharePoint's hidden admin zone and zero-width residue dropped from KY's digest), and recorded CT DEEP's $7,165,955 as a state-agency allocation and DMHAS's REST RFP on `R/03ac`'s probe. NAMED_HOSPITAL is 1,299 / $1,203,760,515.42 / 32 states. Detail: `docs/session92_va_vhcf_ky_private_awards_ct_deep_rest.md`. Session 90 extracted SD's CCBHC round (`R/03bw`, 13 named cohort members for 12 grants, "more than $13 million", no amounts, every row `recipient_confirmed = Unclear`; Avera Behavioral Health has no exact CMS SD enrolment, so it is not a hospital row), registered DOH's Regional Services Designation Grant Fund as state money (`SD-DOH-RSD-GRANT-FUND`), and moved SD to Year 1 PARTIAL. Detail: `docs/session90_sd_ccbhc_rsd_registry_main_suite.md`. Session 89: Session 89 closed `MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR` as
NON_HOSPITAL (owner: a shared county does not show the hospital district operates the ambulance service; $0
moved), read SD's $7.2M EMS round (no roster), and merged the session-84 check-in branch. Detail:
`docs/session89_sd_ems_round_mt_prairie_checkin.md`. Session 88 did five owner tasks:
- **Confidence (§7).** 1,113 rows carried `determination_confidence = HIGH` with no CCN (495 NAMED_HOSPITAL /
  $385,879,914; 618 others). All are MEDIUM now; no typing changed. The shared classifier caps every name and
  type-field rule at MEDIUM (`rhtp_confidence_ceiling()`), GA's and MI's hand-coded HIGHs are lowered at output,
  and `test_state_union.R` fails any state file with a HIGH and no CCN. SD's 6 HIGH rows carry a CCN and stay.
- **CMS verdict.** `rhtp_cms_press_verdict()` now reports CHANGED for a new release in a state already listed
  (the 10-05 run logged UNCHANGED while writing SD's $7.2M release) and uses `rhtp_probe_verdict()`.
- **Montana EXTRACTED** (`R/03bv`): 4 ambulance grants at "approximately $340,000 each" (rounded) and one
  NOT_YET_NAMED pool of 75 equipment awards, no amount. No hospital. `R/03bl` is now its roster watch.
- **Probes.** LA's parser reads exact dates, "Completed" and the re-anchored labels (10-05 snapshot archived);
  NC gains one furniture entry; AK compares the award table, not the xlsx bytes; TN NJ NY CA ME re-based
  (probe pages only; award sources restored).
- **Private notifications.** CA's four CalRHT pools (HCAI FAQ, 09-29) and LA's six programmes (Notices dated
  2026-10-02) have notified applicants privately and publish no roster. Status tables now say so.

Detail: `docs/session88_confidence_cms_verdict_montana_probes_private_notices.md`. Session 87 applied the owner's answers to session 86's three queue questions:
Sanford Health and Avera Health (SD) are `HOSPITAL_OR_SYSTEM`, LOW, `GENERAL_KNOWLEDGE`, no CCN, as system parents
(`R/03i` `SD_SYSTEM_PARENTS`; +2 rows / +$7,007,000, inside the $31.5M round). SWOSU stays `UNIVERSITY_OR_AHC`
($0). Choctaw Nation stays `HOSPITAL_OR_SYSTEM` on CCN 370172 ($0). `sd_rht_contracts.csv` gained `basis_type`.
NAMED_HOSPITAL is now 1,290 / $1,197,370,515.42 / 31 states. Detail: `docs/session87_owner_queue_resolutions_sd_ok.md`.
Session 86 extracted session 85's four held rosters on the owner's approval:
- **OK RRR + CDM** (`R/03bt`, own files): +16 hospital rows / +$30,297,461.15. 7 rows / $13,380,488.41 are LOW
  (Mercy, Fairview, Lindsay, Ascension Jane Phillips, Cimarron). Choctaw Nation is on its CMS hospital enrolment.
  Central Oklahoma Family Medical Center is an FQHC on CMS's file.
- **DE FQHCs** (`R/03bu`): 3 rows, $22,690,000 rounded, no hospital.
- **SD:** the register now holds 41 / $26,836,144, so 15 contracts are new (not 13). 6 Rural Strong grants sit inside
  the $31.5M. 8 have no stated round, are capped at the $90M round and are never added (`SD_PLACEMENT`). SD is
  +7 hospital rows / +$8,919,452. Sanford and Avera system parents ($7,007,000) were queued (typed session 87).
- **Stale figures fixed:** `R/03aw` no longer adds SD's in-round contracts on top of the round totals. The 03bj
  verdicts, the 03bj and rural-cut partition pins and the 03bh WV disposition that session 85 left stale are caught
  up. Rural cut: 256 rows / $263,299,771.23 (+16 CAH rows by CCN).
- **NAMED_HOSPITAL** is now 1,288 / $1,190,363,515.42 / 31 states.

Detail: `docs/session86_held_rosters_ok_de_sd.md`. Session 85 read the six unread trips:
- **WV:** +7 rows. Minnie Hamilton is typed a CAH on its CMS enrolment.
- **OK:** the Doulas roster is extracted (`R/03bt`). RRR ($39.6M) and CDM ($15.6M) are held over the $10M line.
- **DE:** the $22.69M to three FQHCs is held. It has no hospital row.
- **SD:** 13 new contracts (+$16.6M) are held.
- **Probe verdicts:** `rhtp_probe_run()` no longer reads "Connecticut" or "https" as access errors.
- **ME:** the probe now compares a content digest.
- **COMPLETE-state share table:** now carries the AHC and GENERAL_KNOWLEDGE slices. Alabama is AWARDED and is not
  a notice of intent.

Detail: `docs/session85_six_trips_wv_ok_doulas_al_complete_share.md`. Session 84 moved Alabama to Year 1 COMPLETE: ADECA's Program Manual
(09-08) gives Community Medicine "no Year 1 funding" (begins Year 2 / 2027), and its June deck says "not budgeted in
Year 1". It is a SUBAWARD round (metrics reported "from subawardees"), now watched by `R/03bs` on a weekly Routine.
Detail: `docs/session84_al_complete_probe_log_review_ms_window.md`. Session 83 re-typed National Jewish Health (MI, $435,000) on its CMS
enrolment, extracted Alabama round 2 (`R/03bq`, 34 grants, $54,793,527, 21 hospital rows / $20,886,572) and NC's
SBHC roster (`R/03br`, 5 rows, $0, FirstHealth), and kept AL PARTIAL: the release says it rounds out Year 1, but
Community Medicine, the 11th initiative, has $7.3M of Year 1 plan and no award. Detail:
`docs/session83_mi_njh_al_round2_nc_sbhc_completion.md`. Session 82 extracted Colorado (92 lines, $170,210,575.26, roster and
HCPF's $169,587,181 NOT reconciled), recorded Texas's BP1 report as a 33-of-68 floor (`R/03bp`, coded nothing),
read AL's and NC's new releases, and moved NY LA WY ME MO SC to new runners. Detail:
`docs/session82_colorado_texas_floor_al_nc_six_runners.md`. Session 80 moved WI and NV to new runners, which session 79 had left
in place, and recorded the reload mechanism in §2.2a. Detail: `docs/session80_wi_nv_moved_mechanism_recorded.md`.
Session 79 confirmed session 78's runner-growth mechanism (NY 723,788,
MO 687,835, both as predicted) and recreated all 38 Routines on the v4 worktree prompt, nine on new runners.
Detail: `docs/session79_worktree_prompts_falsifier_gate.md`. Session 78 deleted `trig_011p…` and added
`tests/testthat/test_claude_md_status_table.R`, which fails when Deliverable 1 or the partition block drifts
from the committed files. It also found why runners double at resume (see Runner context). Detail:
`docs/session78_status_table_assertion_runner_context.md`. Session 77 moved sessions 1–76's history to
`docs/claude_md_history_sessions_01_76.md` and Montana to `INVESTIGATED_NO_LIST` (survey **36/9/2/3**).

**This section is kept short on purpose.** Every Routine runner loads this file on each cold resume. Keep the
session narrative in `docs/session<NN>_*.md`, and add a line here only when it changes a rule, a figure or an
open item. A rule found in a session goes in "Standing operational rules" below, not in a session paragraph.
Sessions 1–76's narrative is in the history file, unedited. Every rule it carried is restated below.

### Standing operational rules (restated from sessions 1–76; each is still in force)

**Overlays: a rebuild silently wipes them.** State extractors rebuild their CSV from the archived source. Hand
determinations are OVERLAYS on top of that rebuild and must be re-applied:
- **Session 49** (`R/03ap --apply`, 22 files). After a PARTIAL rebuild, re-apply per file with
  `vq_apply(vq_changes()` filtered to the file`)`. **Never run a bare `--apply`**: it re-derives its plan from
  already-overlaid files, and in session 52 it shrank the plan from 487 rows to 31.
  **Never on Arkansas either**: it would re-write NARHC's `OTHER`. `R/03ai --build` re-applies
  `ar_resolve_narhc()` after it.
- **Session 50** (`R/03aq --apply`): after any `--build` on MS or SC.
- **Session 58** (`R/03ax --apply`) for Florida. Order: `R/03e --ingest`, then the 03ap overlay, then
  `R/03ax --apply`.
- **Session 71** (`R/03bj --apply`): after any rebuild of a touched state (AL AK OR WY MI GA NC IA OK). The AR,
  NV, LA and WA builders chain it.
- **Session 49's overlay is keyed on ROW INDEX.** Never re-apply it to a rolling file (Alaska) without
  re-keying it first. Session 75 re-keyed Alaska by App ID.
- `R/03r`, `R/03u` re-apply 49's overlay inside `--build`. `R/03s`, `R/03t`, `R/03aj`, `R/03v` do not.

**Alaska is rolling.** Roll `AK_PRIOR_FILE` on every refresh. **Leave `AK_CMS_ANCHOR_FILE` alone**: it is the
2026-08-28 file CMS described as 142 projects. A withdrawn award leaves the file; list it in `AK_WITHDRAWN`.

**Confidence (session 88).** `determination_confidence = HIGH` needs a CCN on the row (§7). No name rule,
state type field or hand coding may emit it; pass any value through `rhtp_confidence_ceiling()`.
`test_state_union.R` fails a file that breaks this.

**Figures are never combined without their meaning.**
- The three hospital buckets are never added. `rhtp_hospital_total()` refuses to add them.
- A state with named hospitals and no amounts (NV, IA, DE, NC, TN, MO, IN GROW) contributes ROWS and $0.
  **Read the row count.**
- **Never sum `round_amount` down a column.** It repeats a pool on every row (GA, NV, NC, WY). Nor
  `organisation_award_total` (AR). Sum the distinct pools.
- No state's hospital figure is comparable to another's without reading its rows. They are intents, offers,
  executed agreements, rounded or partial-year figures.
- A pool figure is never divided (§6.2). A plan or budget line is never an award (§0.3).
- A count of hospital awards that names none enters no bucket (§7).

**Some files are non-award files and stay that way.**
- `mo_hub_anchors.csv`, `me_rhef_cohort.csv` and `ar_year1_projects.csv` are never in `STATE_FILES`. The first
  two are not awards. The third is the same money as `ar_year1_awardees.csv` at a finer grain.
- Every `<st>_year1_status.csv` has **no `amount` column**, and an assertion refuses one.
- When a watched state awards, **rewrite** its probe as an award extractor. Never patch the status table.

**Hand edits: read the diff.**
- `classification_review_queue.csv` and `vocabularies.csv` are CRLF. Append to them byte-wise and check
  `git diff --numstat`. `readr::write_csv` rewrites every line.
- Round-trip reads turn `NA` strings into empties and `3000000` into `3e+06`.
- An xlsx render that differs only in `dcterms:created` is reverted, not committed.
- A shared-classifier change is proved inert by re-running every extractor. Every reference CSV must come back
  byte-identical, or each moved row is named.

**Probes and evidence.**
- Compare a CONTENT digest over the reduced text, never a file digest. Eleven hosts rotate tokens.
- Two fetches seconds apart is not a stability test.
- Archive a page only after asserting it is credential-free. Strip Mapbox and Google Maps keys and CSRF tokens
  by name, and record both digests.
- "Unreadable" (403, JavaScript app, captcha) is recorded as UNKNOWN. Never record it as NO (§0.4).
- Test several user agents before calling a host blocked. `michigan.gov` is the only agent exception (§3).
- `nh.gov` and `mass.gov` are 403 on four agents. `web.archive.org` resets at TLS. `archive.org`'s
  availability API answers.
- Read `logs/probe_results.csv` before opening any fired session. `TRIPWIRE` is a finding about the state;
  `ERROR` is about our access.
- **A name-tripwire firing is read, not silenced.** Extract what it found. Otherwise add the string to `known`
  (recipients, containment) or `furniture` (judged non-recipients, exact match), with the sentence that
  justifies it. A date welded to a name gets a break token. Never widen `RHTP_ORG_SUFFIX_TOKENS`.
- A `Check the Routine is running against main` refusal before a branch merges is intended.

**Before extracting a state, ask these questions.** A candidate count ranks nothing. Iowa led on 15 candidates
and had 264 awards; FL, NC, AR and WY had zero candidates and published rosters.
1. Check `/api/v1/activity` (`stage2_state_sources.rds`) for real state URLs. `state_source_url` is usually NA.
2. Read the programme page's LINK list, not its prose.
3. Is the award channel procurement (Indiana), a pass-through administrator's site (§7: ICAHN, FHC, SCRA), a
   Drive folder (Wyoming), the governor's newsroom, or a Medicaid bulletin (South Carolina)?
4. What does the candidate document FUND?
   - Is it state money, like Texas Rider 88, NV GME, CA SRHRP, NM RHCDF or opioid settlements?
   - Run the §6.2 date test against 2025-12-29.
   - Read RCJ's own description (California's seismic deliverables).
5. What does the document say the number IS: an allocation, a projection, a pool, a ceiling, a multi-year value?
6. Which tier does the footer carry? Parse the **CMS share**, never the headline (§0.2).
7. What is the roster a roster OF? Selected to convene (MO), invited (ME), eligible (MN, IN committee tables),
   applicants (NE pages 2–3, WY)?
8. Is the aggregator's grain one row per organisation (MI) or per award?
9. Does it hold the POOL as a row (MD)? A $1 placeholder (MO, ME, NM)? Revisions priced twice (CT)? The wrong
   state (§6.1 mode 6)?
10. Does the publisher claim COMPLETENESS (Michigan)? Otherwise the figure is a floor.
11. Does the state publish its own award date, and has it passed? That dates the negative.
12. What is the eligible CLASS of any pass-through?
    - Hospitals only → ICAHN, `Yes`.
    - Hospitals among others → FHC, `Unclear`.
    - A hospital required in the partnership → New York; code off the award.
13. What are the roster's COLUMNS? Nevada has names and no amounts.
14. Does the footer's grammatical subject cover the PROGRAMME or only the publication (Nevada)?
15. Does the award document carry the provenance, or only the solicitation (Indiana)?

### Stages built

| Stage | File | Status |
|---|---|---|
| Config, vocab | `R/utils_config.R`, `data/reference/vocabularies.csv` | Built |
| 00 CMS trigger list | `R/00_cms_press_monitor.R` | Built; on Routine (Mon/Thu 13:00Z). Newsroom primary, medicaid.gov secondary |
| 00b trigger union | `R/00b_state_trigger_queue.R` | Built |
| 1 retrieval | `R/01_retrieve_rcj.R`, `R/01b_rcj_pull_diff.R` | Built; latest pull 2026-09-24 |
| 2 normalization | `R/02_normalize.R` | Built; re-run 2026-09-24 pull (session 65) |
| §6.2 provenance sweep | `R/02b_provenance_sweep.R` | Built; registry `non_rhtp_state_programs.csv` |
| §0.1 mode-6 sweep | `R/02c_state_attribution_sweep.R` | Built; re-run after every national pull, then each failing disposition |
| 3 allotments + registry worksheet | `R/03_state_registry.R` | Built; §7.3 registry NOT compiled (blocker 1) |
| 2.5 budget narratives | `R/03b_budget_narratives.R` | Built; OK, DE only |
| CMS abstracts | `R/03c_cms_abstracts.R` | Built, 50 states |
| State extractors | `R/03d`–`R/03bo`, `R/03bq`, `R/03br`, `R/03bt`–`R/03bx` | 38 states EXTRACTED; see Deliverable 1. `R/03bp` is TX's floor, not an extractor |
| State watches (probes) | `R/03y`, `03ab`–`03ag`, `03az`–`03bc`, `03bg`, `03bl`–`03bn`, `03bs` | Built; each on a Routine (`config/routines.csv`) |
| Overlays / reports | `R/03ap`, `03aq`, `03ar`, `03as`, `03aw`, `03ax`, `03bh`, `03bj` | Built; see overlay rules above |
| PDF reader | `R/utils_pdf_text.R` | Built; runs model (`rhtp_pdf_runs()`) and line model |
| §8/§10.2 classifier | `R/utils_recipient_classification.R` | Built |
| Probe guard + log | `rhtp_probe_run()`, `R/probe_coverage.R`, `logs/probe_results.csv` | Built |
| 4 validation | `R/04_validate.R` | **Not started — gated on the §7.3 registry** |
| 5 hospital determination | `R/05_hospital_determination.R` | Not started |
| 6 workbook | `R/06_build_workbook.R` | Not started |
| QA assertions | `R/qa_assertions.R` | Not started |
| Tests | `tests/testthat/` | `Rscript tests/run_tests.R`, zero quota |

No state has been through Stage 4. Pilot set (spec §14): GA, VA, NE, FL, TX.

### Survey disposition (rebuilt from `R/03k`'s constants; never hand-edited)

`EXTRACTED` 38 · `INVESTIGATED_NO_LIST` 7 (CA KY MN ND NM TX WI) · `INVESTIGATED_NO_PROBE` 2 (HI MA) ·
`QUEUED` 3 (UT AZ RI; 4 candidates, $518,902,453). A state leaves `QUEUED` or `INVESTIGATED_NO_PROBE` only
through the work: an award file, or an archive plus a probe plus a Routine.

### Hospital partition (re-derived 2026-10-05, session 92, from `STATE_FILES` in `tests/testthat/test_state_union.R`)

```
NAMED_HOSPITAL          1,299 rows   $1,203,760,515.42   32 states
POOL_NAMED_HOSPITALS        2 rows      $30,806,856.12   NE (NHVN $18,156,856.12) + CT (Hartford HealthCare pair $12,650,000)
POOL_UNNAMED_HOSPITALS      1 row       $50,008,264.00   IL (ICAHN)
```

Never add these. `ACADEMIC_HEALTH_CENTER` subtype rows (session 71) can be subtracted. `GENERAL_KNOWLEDGE`
rows (`basis_type`, LOW) can be subtracted. Rural cut: `R/03ar`. Complete states and their hospital shares:
`year1_completion_status.csv` (FL, GA, AR, AL).

### Deliverable 1: state award files

`sum(amount)` is shown and is **not** always the state's published total. GA and OR hold pools in
`round_amount`. Hospital is `NAMED_HOSPITAL` rows/dollars unless a pool bucket is named.
**`test_claude_md_status_table.R` asserts every cell, and the partition block above, against the files.**
Change a state file and you must update this table in the same commit. Never loosen the test.

| File | Rows | Priced | sum(amount) | Hospital |
|---|---:|---:|---:|---|
| AK | 249 | 249 | $242,620,741 | 45 / $69,370,639 (intents; rolling; 2 withdrawn) |
| FL | 81 | 81 | $188,201,256 | 15 / $49,345,213 (Year 1 COMPLETE) |
| WY | 77 | 75 | $173,859,752 | 35 / $84,369,024 (committee approvals) |
| CO | 92 | 92 | $170,210,575 (release says $169,587,181) | 36 / $86,693,159 (typed on CMS enrolment) |
| SC | 228 | 228 | $167,299,901 | 114 / $115,985,715 (partial year) |
| AR r1 | 37 | 37 | $149,177,618 | 20 / $104,397,118 (intents) |
| AL r1 | 138 | 138 | $143,745,821 | 70 / $83,548,287 |
| OR | 278 | 272 | $140,994,009 (published $175.3M) | 57 / $54,520,575 (intents) |
| VT | 145 | 145 | $106,660,194 | 42 / $35,285,416 (executed; partial) |
| MS | 167 | 167 | $104,115,147 | 84 / $68,898,205 (partial year) |
| MI | 145 | 145 | $101,318,437 | 5 / $2,694,121 (a TOTAL; MHA $8.625M in no bucket) |
| KS | 60 | 60 | $96,027,147 | 37 / $62,416,473 |
| GA | 158 | 102 | $90,765,080 (published $197,148,327) | 126 / $90,277,580 (Year 1 COMPLETE) |
| NJ | 103 | 103 | $83,060,837 | 35 / $35,275,076 |
| MD | 41 | 41 | $78,625,071 | 9 / $27,681,260 (offers) |
| NY | 56 | 56 | $76,190,022 | 35 / $47,358,791 |
| WA | 8 | 7 | $67,020,000 | 2 / $9,740,000 (WSHA $42M Unclear) |
| NH | 2 | 1 | $66,547,394 | 0 (FHC Unclear) |
| AL r2 | 34 | 34 | $54,793,527 | 21 / $20,886,572 (AHC $6.69M; Greene $3.91M LOW, general knowledge, no CCN) |
| AR r2 | 43 | 43 | $54,685,069 | 14 / $23,939,844 (AR Year 1 COMPLETE) |
| IL | 1 | 1 | $50,008,264 | POOL_UNNAMED 1 / $50,008,264 |
| CT | 4 | 4 | $49,980,000 | 2 / $33,350,000 + POOL_NAMED 1 / $12,650,000 |
| PA | 66 | 66 | $42,198,310 | 27 / $24,149,111 (authorized, undisbursed) |
| NE | 91 | 70 | $41,687,307 | 60 / $14,431,596 + POOL_NAMED 1 / $18,156,856 |
| OK RRR | 20 | 20 | $39,578,523 | 10 / $21,099,804 (LOW $8,272,013: 3 enrolment bridges $4,333,575; Mercy $3,938,438 general knowledge, no CCN) |
| SD contracts | 41 | 41 | $26,836,144 | 14 / $16,643,252 (Sanford + Avera parents $7,007,000 LOW, GENERAL_KNOWLEDGE; 14 Rural Strong inside $31.5M; 8 unplaced, never on top of $90M) |
| DE FQHC | 3 | 3 | $22,690,000 | 0 (3 FQHCs; amounts rounded in source) |
| OK CDM | 15 | 15 | $15,608,845 | 6 / $9,197,657 (Choctaw Nation on its CMS hospital enrolment) |
| ME | 1 | 1 | $12,000,000 | 0 (11 invited hospitals in `me_rhef_cohort.csv`, not awards) |
| OH | 1 | 1 | $10,000,000 | 0 (a university; partial year) |
| WV | 14 | 12 | $9,248,417 | 5 / $2,924,000 (Minnie Hamilton CAH on CMS enrolment; 2 rows unpriced) |
| MO | 22 | 2 | $7,232,660 | 20 / $0 (27 hub anchors are NOT awards) |
| OK | 69 | 68 | $3,572,121 | 27 / $1,353,503 |
| LA | 6 | 5 | $1,965,788 | 1 / $1,500,000 ("20 hospital-setting awards" in no bucket) |
| MT | 5 | 4 | $1,360,000 | 0 (4 ambulance grants, rounded; 75 equipment awards unnamed, one pool row) |
| IN | 7 | 1 | $860,088 | 0 (vendors) |
| OK Doulas | 4 | 4 | $647,968 | 1 / $38,525 |
| IN GROW | 186 | 0 | — | 44 / $0 |
| IA | 264 | 0 | — | 218 / $0 |
| NV | 156 | 0 | — (pools $87.4M) | 44 / $0 |
| NC | 44 | 0 | — | 2 / $0 |
| NC SBHC | 5 | 0 | — (pool $1.25M) | 1 / $0 (FirstHealth) |
| TN | 53 | 0 | — | 2 / $0 |
| DE | 4 | 0 | — | 4 / $0 |
| VA | 11 | 0 | — | 0 |
| VA VHCF | 25 | 25 | $14,390,000 | 9 / $6,390,000 (system parents $5,700,000 LOW, GENERAL_KNOWLEDGE; UVA strings $884k queued; Highland is an FQHC) |
| ID | 1 | 0 | — | 0 |
| SD rounds | 2 | 0 | — ($121.5M, names nobody) | 0 |
| SD CCBHC | 13 | 0 | — (pool "more than $13 million") | 0 (13-member cohort, 12 grants; every row Unclear) |

Each file's caveats are in its own `R/` header and in the history file. Reference tables: `data/reference/`.
Every `<st>_year1_*.csv` has a matching `<st>_rcj_candidate_disposition.csv`, rebuilt by its own script and
refusing a candidate it does not cover. Open human questions: `classification_review_queue.csv`. It is not
Stage 4's `data/interim/review_queue.rds`, which does not exist yet.

### Routines

Every Routine is in `config/routines.csv`. There are 39 (AL added session 84), each on its own persistent runner session. Prompts:
`config/routine_prompts/v4/<ST>.txt`, derived from the stored v3 prompts by `R/routine_prompts_worktree.R`
(`--write`, `--check`); runner moves in `config/routine_prompts/runner_moves.csv`. Coverage: `Rscript R/probe_coverage.R --check`. Explained misses:
`config/probe_gaps_explained.csv`.

**Session 78:** `trig_011pUVRNkSnjCNvZfQ89kPbM` is deleted. It stays in CMS's `old_trigger_id` chain,
which `R/probe_coverage.R` reads from the log, not the platform. Every listed Routine is now registered,
apart from the one-shot check-in.

**Runner context (session 78).**
- **What causes the growth.** A cold resume re-adds ~330k only when `CLAUDE.md` in the runner's own tree
  differs from the copy its conversation holds. The runner's own step-1 `git checkout` is what changes it.
- **NY and SC stayed near 384k** because their first turn came 27 minutes after creation, before any
  `CLAUDE.md` commit reached `main`.
- **The split is exact.** Ten of ten runners whose first checkout changed the file doubled; two of two that
  did not change it stayed flat.
- **A runner reads its tree, not `main`.** WI and NV fired after the trim merged and still doubled.
- **Eleven runners are at ~700k:** CMS AR KY NEWSROOM CT CO CA MS VA WI NV. The first nine hold a pre-trim
  file and would pass 1M at their next resume.
- **Confirmed session 79:** NY rose 384,866 → 723,788 and MO 368,982 → 687,835 at their 09-30 firings.
- **The fix, done session 79 (v4):** every firing works in a detached worktree at `/root/rhtp_work` and never
  touches `/home/user/RHTP_Tracker`, so the runner's `CLAUDE.md` is frozen. **Never write a Routine prompt
  that checks out, pulls or edits in the primary checkout.** CA CMS AR KY NEWSROOM CT CO MS VA moved to new
  runners. WI and NV followed in session 80 (`trig_01BDpi…`, `trig_013u9w…`), so all eleven are on new runners.
- **Session 82 moved the six in-place runners near 700k** (NY 723,788, SC 713,680, LA 709,869, WY 708,216,
  ME 703,973, MO 687,835) to new sessions, same names and crons; `runner_moves.csv` and `routines.csv` chain
  the old ids, which are disabled, not deleted.
- **A prompt change is a recreate** (`update_trigger` refuses a prompt from outside the runner): edit the
  generator, `--write`, create, byte-compare with `list_triggers`, disable the old id, chain it here.

### Open blockers

1. **The §7.3 state source registry is not compiled.** This is the hard gate for Stage 4 (§13.12). Work
   `state_source_registry_worksheet.csv` down to 50 verified rows, Florida first, and check with
   `R/03_state_registry.R --validate`.
2. **`DE Verify.xlsx` is not ingested.** It holds 11 hand-verified Delaware rows, and 7 are mis-coded hospital
   rows (§0.3a). Ingest it to `data/reference/` the way `R/03e` did for Florida, and let Stage 5 own the
   re-coding.
3. **There are no AHA Annual Survey or CMS Provider of Services extracts.** Without them nothing reaches `HIGH`
   (§7), and several hundred rows wait on a CCN match. Only CMS enrolment files are archived
   (`data/evidence/federal_records/`).
4. **`qa_assertions.R` is unbuilt.**
5. **The delta-pull strategy is undecided.** `/activity` supports `since=`; the other endpoints do not (§9).
6. **`web.archive.org` resets at TLS.** The `archive.org` API answers but snapshots cannot be fetched. This keeps
   Georgia's 80/7 phase split an inference.

Network is Full; the old allowlist blockers are superseded.
**Quota: 1,914 of 2,000** after the 2026-09-24 pull (86 calls).

### Next session

- **Session 93 (read first).** KY Accredited Dental Hygiene: the conflict is RECORDED, not resolved. The RFA (archived) gives deadline 05-29 and award 06-26; the CHFS channel's "August 1, 2026" deadline is the RFA's funding-period start. The row stays CLOSED_UNAWARDED until a human decides which source governs. Valley Health / Ballad / Sentara are settled.
- **Session 92.** Settled in session 93: VA system parents, and the KY Dental Hygiene record (see above). VHCF Provider Productivity is due "October 2026": R/03bb trips on the post. CT REST: contract start 9/1/2026 passed, no outcome. Detail: `docs/session92_va_vhcf_ky_private_awards_ct_deep_rest.md`.
- **Session 91.** `SD_CCBHC_AVERA_BH_ENROLMENT_BRIDGE` closed at (a), no bridge ($0). Re-checks found, UNEXTRACTED pending owner: VHCF's 10-02 roster (25 awards, $14,390,000, 9 hospital-shaped rows / $6.64M; no probe watches VHCF news); KY recipients self-announcing Community Paramedicine / EMS Training awards that `ky_year1_status.csv` calls CLOSED_UNAWARDED; CT's DEEP $7.17M agency line and the unawarded DMHAS REST RFP. TX BP1 unchanged (33). Detail: `docs/session91_sd_avera_close_va_ky_ct_tx_rechecks.md`.
- **Session 90.** One SD owner question is open: `SD_CCBHC_COHORT_13_VS_12_GRANTS` ($0). The CCBHC release says "The next round of funding is anticipated later this fall"; when it names grantees, rewrite `R/03bw`, don't patch it. The 10-08 check-in report (`trig_011DDK…`, 15:50Z) fires into session 89's session, not session 90's.
- **Session 89.** SD's $7.2M EMS round (CMS 10-02; Governor 10-03, "Enhancing Sustainable
  Emergency Medical Services", RFP 26-09RHT-023) is READ and NAMES NOBODY: no roster on DOH, and the open.sd.gov
  RHT series is unchanged at 41 / $26,836,144. Do not extract. **Trap:** DOH's "Regional Services Designation
  Grant Fund Distribution" page is a named, priced EMS roster ($1,668,809.91 + $5,839,975.00) that is STATE
  money (EMS Interim Committee; page dated 2025-08-04, before the NOA; no RHT mention). SD's $13M CCBHC round
  (09-24) names a 13-member cohort, 12 grants, no amounts: unread for extraction. The session-84 check-in
  branch is merged into this branch. A rebuild of any state whose notes quote "Classifier said X/HIGH" will
  now say "/MEDIUM": text only. Detail: `docs/session89_sd_ems_round_mt_prairie_checkin.md`.

**Merge session 82's branch to `main` before Fri 10-02 16:20Z** (ME's first firing on its new runner). Until
`routines.csv` on `main` carries the six new ids, their lines read as unregistered. Sessions 79 and 80 are on
`main` (PRs #83, #84).

- **Session 86 wrote all four held rosters** (OK RRR, OK CDM, DE FQHCs, SD). The OK probe and NEWSROOM DE are
  re-based and quiet. Its three owner questions were resolved in session 87 (see Last updated).
- **The OK and WV builders now chain R/03bj's overlay** (`R/03bt --build`, `R/03av --build`). Any extractor that
  sets `cms_enrolment_match` needs an EH_APPLY verdict, or `test_03bj` fails.
- **ME's and CT's fixes are on this branch only.** Until it merges, a Routine running from `main` will still log
  ME `doe` and CT `programme`/`opm` trips. Those trips are read; see `docs/session85_*`.
- Session-84 check-ins (`trig_01PGFH…` 10-02 21:45Z, `trig_01MWZ2…` 10-04 11:45Z, `trig_01DpSc…` 10-08 15:15Z)
  delete each old id below once its successor has logged.
- **Delete the six session-82 old ids once each new Routine has put a line on `main`:** NY
  ~~`trig_014kvDg8x3JDqdWySvHxrREU`~~ (deleted 10-04), ~~LA `trig_016GDtAW1DvWCexnRSm4LxK8`~~ (deleted 10-04), ~~WY `trig_01F98Jr5do6PXbUzNLBGjzGE`~~ (deleted 10-02),
  ~~ME `trig_01RyrB4uNLd6rdjaD8d9tWBk`~~ (deleted 10-02), MO `trig_0183VrPsZUMmc3dMneainqXm`, SC `trig_01R1pZjkPkQZWD3vctiAJQ44`.
- **Alabama is Year 1 COMPLETE (session 84).** Community Medicine has no Year 1 money (ADECA Program Manual
  10.10; June deck). Its Year 2 round is watched by `R/03bs` (`trig_01NtbC312pu2u8d7uePQXEty`, Thu 14:40Z, runner
  `session_01C6egjruxEZH2yc6kbffHaf`). **Merge this branch before Thu 10-08 14:40Z** or AL's line reads unregistered.
  AL hospital share (rounds 1+2): 91 rows / $104,434,859 = 52.6% of published; AHC rows $18,308,866 and the LOW
  Greene County typing $3,913,694 are subtractable. Greene County is typed on GENERAL KNOWLEDGE, not on an
  enrolment bridge: no CMS file carries its name, and it has no CCN (session 88 wording fix).
- **North Carolina:** the Rural Health Innovation Fund (launched 09-30, Tier 2, applications due 11-16, awards
  "January 2027") is the next NC roster.
- **Texas floor:** `tx_bp1_first_tier_floor.csv` is not an award file. R/03n's probe trips when the BP1 report
  names other than 33 districts. Enrolment screen: 28 exact, 4 near (hand bridge), Hardeman none.

- **The 38 v3 originals are deleted** (09-30, after CA and NH published under v4 ids). NH's 09-30 TRIPWIRE
  (FHC's T-TAC sentence, no subrecipient named) still needs a human read.
- **Read runner context after the v4 firings:** a new runner should sit near its first-turn floor and stay
  there; an in-place runner may re-load once more, then stop.
- **WI's 10-02 TRIPWIRE was read in session 85.** `dhs_solicit` gained "Intoxicated Driver Program
  Supplemental Funding Request for Application". It is a state OWI appropriation (Wis. Stat. § 20.435(5)(hy))
  with no RHTP mention, and is now in `WI_NAME_FURNITURE`.
- **Open review-queue decisions** (`classification_review_queue.csv`):
  - `VT_S74_LOW_HOSPITAL_TYPINGS` ($3,525,809.47)
  - `AHC_STRING_NAMES_NO_ENROLLED_ENTITY` (UAB Montgomery, OHSU Casey Eye, MEDIC, ORPRN strings, UMMS)
  - `AK_KETCHIKAN_ALL_TYPES_TICKED`
  - `AR_R2_QUEUED_FORM` (CARTI, NARHC)
  - `AR_R2_RECIPIENT_FORM_NOT_STATED`
  - `SC_ACADIA_PARENT_SCOPE`
  - `UF_FORM_NOT_DETERMINABLE`
  - `NJ_VIRTUA_PARENT_BRIDGE`
  - `NJ_RECIPIENT_FORM_NOT_STATED`
  - `WA_WSHA_FLOW`
  - `MI_MHA_FLOW`
  - `CO_ROSTER_VS_RELEASE_TOTAL`, `CO_HOSPITAL_DISTRICT_NO_HOSPITAL_ENROLMENT`, `CO_RECIPIENT_FORM_NOT_STATED`
  - `TX_BP1_DISTRICT_ENROLMENT`
  - `AL_R2_GREENE_COUNTY_HEALTH_SYSTEM_BRIDGE` ($3,913,694, LOW), `AL_R2_RECIPIENT_FORM_NOT_STATED`
  - The NE, NV and LA form rows from session 64
- **Dated watches:**
  - Colorado: AWARDED 09-28, extracted session 82; R/03az's Routine now runs R/03bo's roster watch.
  - Wisconsin: "Award announcements: September"; nothing posted as of 09-28.
  - Montana: EXTRACTED session 88 (`R/03bv`). `R/03bl` watches for names for the 75 equipment awards and a new
    round. The state's 78 agencies against CMS's 79 (4 + 75) is unresolved.
  - Mississippi: second tranche, 2026-10-14 .. 10-29.
  - Louisiana: six Notices of Intent to Contract dated 2026-10-02, sent to applicants privately; denials "by
    October 16, 2026". Nothing published (session 88).
  - California: notices sent privately via Submittable (HCAI FAQ 09-29); the rest "by late October 2026".
  - New Hampshire: CAH RFA "Coming Soon".
  - Wyoming: obligation end of October; committee meets 11-04/05.
  - All states: CMS obligation deadline 2026-10-30.
- **Vermont's list is partial and grows weekly.** When it moves, key the diff on initiative + activity + amount,
  not the name.
- **Unextracted rows:**
  - VT, VA, FL, AK and NC each have single missing rows.
  - SD 27SC091800 ($150,000).
  - Hawaii HPCA's award; its amount is only in HANDS (403).
- **Re-run order after the next national pull:** Stage 2, then `R/02c`, then each failing disposition builder.

Sessions 1–76's next-session lists, including items still open, are in the history file under
"Next session".

### Re-running what exists

The full list is in `docs/rerun_commands.md`. The pattern is:

```
Rscript tests/run_tests.R                     # all tests, zero quota
Rscript R/<script>.R --fetch [--force]        # archive sources + SHA-256 (writes data/evidence/)
Rscript R/<script>.R --validate               # assertions against the ARCHIVE, offline
Rscript R/<script>.R --build                  # write data/reference/ CSVs (then re-apply overlays!)
Rscript R/<script>.R --report                 # human summary
RHTP_PROBE_ORIGIN=interactive Rscript R/<script>.R --probe   # LIVE, READ-ONLY; logs a verdict
Rscript R/03k_rcj_state_survey.R --build && Rscript R/00b_state_trigger_queue.R --build
Rscript R/probe_coverage.R --check
```

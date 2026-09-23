# Session 55 — the v2 Routines confirmed, CMS moved to a runner, WV and VT watched, eight states read

2026-09-23. Zero RCJ quota (the /api/v1/activity check used the committed
`stage2_state_sources.rds`, never a live call).

## 1. The v2 Routines publish, and the old sixteen are gone

- **Missouri** (`trig_01KM9QKdZGyMxXVy2QChoiTo`, 15:00Z) fired at 15:04 and
  pushed `3d740ff` to `main`: four page lines, every one carrying its own
  trigger id in `origin`. This is the first *scheduled* v2 firing to reach
  `main` by schedule rather than by a manual fire.
- **California** (`trig_01XHdPsHkNQFsQET1NnWQ3oX`, 17:00Z): see §1a, filled in
  when it has fired.
- The sixteen v1 Routines are deleted once both land (§1a lists them). The v1
  Routines fired into containers with no repository, so no verdict of theirs
  ever reached `main` (§2.2a); deleting them loses nothing but duplicate runs.
- Session 54 had left two one-shot reminders firing into its own session to do
  this same step. They were **deleted** so two sessions did not race to delete
  Routines and open PRs.

### 1a. California and the deletion

*(Recorded at the 17:20Z check — see the commit that adds this section.)*

## 2. The CMS trigger list now runs in a session that can push

The stage 00 Routine (`trig_01EozMStALcrUp75s32qFnJ3`) was a fresh-session
trigger with `sources: []`: every firing ran the monitor in a container with no
repository and its archives, CSV and manifest were lost — the same defect
session 52 found in the state probes. It is **deleted**, replaced by
`trig_0174R4VLbhacyCKCKds8qYxM` (Mon/Thu 13:00Z, unchanged cadence) bound to
runner `session_01VcVUvS86exr36LWfje45ak`, which is created against the repo
with `outcome_branch = main`.

**What it may push is narrower than the old prompt allowed.** The old prompt
told the run to fix the parser when a page redesign tripped a refusal. An
unattended run that edits code on `main` is exactly what §2.2 exists to stop,
so the new prompt allows only `data/raw/cms/`, the two CMS reference CSVs and
`logs/`, with a guard before every push. A refusal is now REPORTED.

**The run is visible to the coverage check.** `R/00 --run` now logs a verdict
through `rhtp_cms_press_verdict()` — `CHANGED` on a new state or a changed
amount/date, `UNCHANGED` otherwise, `TRIPWIRE` on a parser refusal, `ERROR` on a
refused host (the same split `rhtp_probe_run()` makes). Only a PRODUCTION run
of both sources logs. `config/routines.csv` gains a `CMS` row, and
`rhtp_assert_routines_registry()` accepts `rhtp_probe_log(` for that row only,
because `--run` writes the raw landing zone and is deliberately not a probe.

**Until this PR merges**, the CMS Routine runs the pre-session-55 code and
leaves no probe-log line; its prompt says so. If it merges after Thursday
2026-09-24 13:00Z, move the CMS row's `logging_since` to the merge time.

## 3. West Virginia and Vermont on Routines

| State | Routine | Cron (UTC) | Runner session |
|---|---|---|---|
| WV | `trig_016jUYvhEgJEvMpEoZChp8AK` | Fri 11:30 | `session_018rTSHkoFHVzcdAFrFXrGQ1` |
| VT | `trig_011gjpEvcXAi5XnXgzo6STJy` | Tue 11:30 | `session_01Wd4SYZ78GbLz7J8GfzyC7S` |

**Weekly, by the project's own rule**: twice-weekly is earned by a published
award date and neither state has one — both say only that more awards will
follow. 11:30 sits outside every existing slot.

**West Virginia had no probe; it has one now.** `wv_probe()` reads three pages
LIVE and writes nothing to `data/evidence/`:

- the **DoH news index**, which carried all five award releases. It trips on
  any article whose headline or slug says "award" and is not one of the five
  recorded. **Measured on the archive**: of 30 articles, "award" matches
  exactly the five, and no funding-OPPORTUNITY release says it. The index is
  **not** name-diffed — it is a press index and WIC and flood notices move it
  weekly (§2.3, subject pages only).
- the **RHTP programme page** and **grant opportunities page**, name-diffed
  against the new baseline in `data/evidence/WV/` (14 and 7 names).

**The first live run found a reader defect and the guard caught it.** The only
link per news item reads "Full Story"; the headline is in its `title`
attribute. The reader returned zero articles and `wv_assert_no_new_award_
release()` refused — "the reader, not West Virginia, has changed". Fixed; the
live probe then read 30 articles and reported UNCHANGED on all three pages.
**The one TRIPWIRE line that defective run wrote was removed from
`logs/probe_results.csv`**: it was an interactive line reporting our reader as
if it were the state, written and corrected within a minute, and no Routine's
coverage depends on it. It is recorded here instead.

The WV Routine's prompt **gates on `wv_probe` being on `main`** and stops
writing nothing until then. If this PR merges after Friday 2026-09-25 11:30Z,
move WV's `logging_since` to the merge time. Vermont's probe is already on
`main` and its Routine will log from its first firing (Tue 2026-09-29).

## 4. The eight untouched states — REPORT ONLY, NOTHING EXTRACTED

Checked three ways each: the state's own programme and award pages (live, the
honest agent), the committed `/api/v1/activity` source URLs, and a search for
governor or agency announcements. Evidence under
`data/evidence/recheck/2026-09-23/<ST>/`; `SOURCES.txt` and `MANIFEST.txt`
there are updated.

| State | Verdict | What it publishes today | Next date |
|---|---|---|---|
| **AZ** | NEGATIVE | 8 AHCCCS/ADHS RFGAs, **all closed**, none naming an awardee. Its own *"All awards will be finalized by Summer 2026"* **has passed**. A third-party post says ADHS signed formula IGAs with 10 county health departments; ADOA procurement is 403, so that is UNKNOWN (§0.4) | OEO awards "by October 23"; obligation 10/30 |
| **CO** | NEGATIVE | *"anticipates making our award announcements by the end of September 2026"*; $160M RFA closed 2026-08-03 | **2026-09-30**; advisory committee 9/28 |
| **MT** | NEGATIVE | EMS Equipment Grant: *"funding decisions will be shared in September"* — nothing posted. A second publisher (MHA, 2026-08-14) says the state issued a Notice of Intent to Award to **Indelible** (CoE analytics vendor) and selected **MHA** to lead Initiative 2 — both procurement, no amounts, and the state's Jaggaer channel is UNREADABLE (JavaScript) | end of September |
| **ND** | NEGATIVE | **25 opportunities, 769 applicants**; 24 "Closed", ONE — *"Expand Rural Health Care Rotations – Awarded"* — naming nobody. Zero-Hour PE's own estimated award date (~early August) **has passed** | none published |
| **RI** | UNREADABLE (state hosts) / NEGATIVE (roster) | Every ri.gov HTML host is a Cloudflare challenge on three agents. CMS's 2026-09-04 release (already committed) says $5.48M is being committed to **14 LEAs and schools**, priced by project and naming no LEA — `NON_HOSPITAL` by class either way | obligation 10/1 |
| **UT** | NEGATIVE (roster) — **awards made, none named** | DHHS's status dashboard reports "Notice of Award Announced" on PATH 1.5 (3 awards, $2,202,532), RISE 2.1 GME (1, $1.6M), RISE 2.2 preceptors (75+, $156,000), and ~8 **"Awarded fiscal agent"** rows naming nobody. South Dakota's shape: counts and dollars, no names | none published |
| **VA** | NEGATIVE (subrecipient roster) | Session 43's "not yet opened RFAs" is **STALE**: `/ways-to-apply/` shows 5 closed, 4 open, 6 TBD. The Governor's $122M (2026-08-28) goes to **11 named first-tier partners with no per-partner amount**, none a hospital, who re-grant competitively | **VHCF Notice of Awards by 2026-09-30** (Interoperability), 10/14, VHHA Foundation 10/30 |
| **WA** | PARTIAL allocation, NEGATIVE roster | The 2026-09-16 webinar deck **prices first-tier sub-recipients**: WSHA $42M (tech & cyber, taking hospital applications), TRC $5.43M for "30 member hospitals" (unnamed), 29 Tribes $19.41M, and a **completed** $10.71M rural-hospital competitive bid with **no winners published** | none published |

**No state's disposition code was changed** (they stay `QUEUED` in
`R/03k`): nothing here is an award file, and none has a probe, so
`INVESTIGATED_NO_LIST` would promise a re-checkable negative that does not
exist (§5, session 43). The cheapest next probes are **CO and VA** (both dated
2026-09-30) and **ND** (a heading flipping to "Awarded" is a one-line tripwire).

### Findings worth carrying forward

1. **A SECOND NON-100%-FEDERAL CMS FOOTER, AND THE PARSER DOES NOT SEE IT.**
   Washington's RNEP item: *"supported by CMS/HHS through a subaward as part of
   a financial assistance award of $181,257,515.06 to the Washington State
   Health Care Authority with $3,500,000 and 80 percent funded by CMS/HHS and
   $914,538 and 20 percent funded by other source(s)"*. Driven here:
   `rhtp_footer_parse()` returns **zero rows** on it — not a wrong parse, no
   parse. It prints the allotment, a SUBAWARD and a match in one sentence (Ohio's
   position and Mississippi's percentage at once). Recorded, not patched: a
   Washington footer would today go unchecked rather than mis-tiered.
2. **Virginia publishes CMS's own Notice of Award** (RHTCMS332088-01-03,
   "Revision (Change of PI/PD)", Federal Award Date 04/08/2026, budget period
   still 12/29/2025): session 36's budget-period pin holds a sixth time, and the
   first revision here driven by personnel rather than budget.
3. **Washington's programme page moved** (`/value-based-purchasing/...` →
   `/programs-and-initiatives/...`, "Temporarily" per HCA).
4. **Utah SHIFT 3.1 water quality** is on the RHTP dashboard as *"Contracted
   (Legislative Appropriation): DEQ ... $4,200,000"* — a §6.2 provenance
   question, not resolved. RCJ's $3,000,000 UHIN row disagrees with the
   dashboard's "Up to $1,000,000" Year 1.
5. **Arizona's RHTP page carries a SAMHSA 988 grant** with an "Expected Award
   Date: 9/1/2026" directly under an RHTP RFGA; one aggregator already
   attributes that date to RHTP. §0.1's wrong-programme mode on the state's own
   page.

### Side finding: TENNESSEE HAS A NAMED ROSTER

Found by the RI/UT search and **verified here**: TDH, 2026-09-03, *"announced
the initial recipients of funding through the Rural Health Transformation
Program (RHTP), providing awards to 53 innovative projects"*, with
`2026-RHTP-HART-Grant-Awards-FINAL.xlsx` naming **53 recipients, counties and
projects, and NO AMOUNTS**. TDH's own split is *"County and municipal
governments account for 58 percent (31) ... community-based nonprofit
organizations comprise the remaining 42 percent (22)"* — **but two names read
hospital-linked: "Macon Hospital, Inc" and "Cookeville Regional Medical Center
Foundation"** (the latter is §10.2's hospital-foundation row if its parent is
confirmed). Tennessee is `INVESTIGATED_NO_PROBE` at "solicitation stage" in
this repository; that is now **stale**. Archived under
`data/evidence/recheck/2026-09-23/TN/`, **not extracted**.

## 5. What did not move

No state file, no hospital figure, no bucket. `NAMED_HOSPITAL` stays
1,033 / $902,386,742.75 / 24 states.

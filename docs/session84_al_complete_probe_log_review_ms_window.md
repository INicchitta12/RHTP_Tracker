# Session 84 — Alabama Year 1 COMPLETE; probe-log review since 09-28; Mississippi's window

2026-10-02. Three owner tasks.

## 1. Alabama's Community Medicine initiative — SETTLED

**Finding: Community Medicine has no Year 1 money, so it is not a Year 1 remainder. Alabama is Year 1
COMPLETE.** Session 83 kept AL PARTIAL on one line of ADECA's revised Project Narrative (Revised
4.10.2026, Table XIV-J1): "Estimated required funding $5M for 3 years; $7.3M for year 1". Two later ADECA
documents contradict that line:

| Document | Date | Sentence |
|---|---|---|
| ARHTP Program Manual (proposed final), §10.10 | file dated 2026-09-08; PDF 09-14 | "Estimated funding $5M over 4 years (begins program Year 2 / 2027; no Year 1 funding)" |
| ARHTP Intro Presentation (roadshow deck), footnote 3 and the initiative's own slide | PDF 2026-06-02 | "The Community Medicine Initiative is not budgeted in Year 1 of Program" |
| alabamarhtp.com/resources | live 10-02 | Ten closed Year 1 NOFOs, none for Community Medicine; "Applications will reopen for Year 2" |

The narrative line is also internally inconsistent: its Year 1 figure ($7.3M) exceeds its own 3-year
total ($5M). Both new PDFs are archived under `data/evidence/AL/` with a SHA-256 manifest
(`2026-10-02_adeca_community_medicine_year2.manifest.txt`).

**Procurement or subaward? A subaward round (Year 2).** "Procure mobile wellness units" (Table XVI-10,
Stage 1) does not make it a state procurement:
- The same verb opens initiatives ADECA then granted. EMS Treat-in-Place, Stage 1 is "Procure
  materials/equipment", and round 2 granted it. EHR's Stage 1 is "Procure infrastructure & service contracts".
- The narrative's metric table settles who buys the units. Table XIX-10 has "Number of mobile wellness
  units procured … Quarterly reporting **from subawardees**".
- The narrative says "Priority consideration will be given to applicants already offering these
  services". The manual says "Participating entities may include community organizations, healthcare
  providers, and local leaders".
- The eligible class is hospitals **among others** (§0.3). A Year 2 roster is coded one award at a time on
  the recipient.

**Effect (`R/03aw --build`).** AL moves from PARTIAL to COMPLETE (`source_calls_complete = Yes`,
`remaining_unawarded = No`). It now has an `award_action_stage`: Governor's word, no executed agreement
published. `year1_complete_hospital_share.csv` gains AL:

| | Value |
|---|---|
| Published (rounds 1+2) | $198,539,348 of $203,404,327 allotment (97.6%) |
| NAMED_HOSPITAL | 91 rows / $104,434,859 = **52.6%** of published, 51.3% of allotment |
| Of which ACADEMIC_HEALTH_CENTER subtype | $18,308,866 (UAB, USA) |
| Of which GENERAL_KNOWLEDGE / LOW | $3,913,694 (Greene County Health System bridge) |
| Residual not attributed by any source read | $4,864,979 |

COMPLETE states are now FL, GA, AR and AL. Nothing in the partition moved. This is a status change, not
a re-coding.

**The watch (`R/03bs_al_year2_probe.R`).** The brief said to extend "the Alabama probe". None existed, so
this session wrote one. Baselines were archived 10-02:
- `resources`: the NOFO list. It trips if "Year 1 initiative application periods are now closed." goes,
  or on a new Community Medicine / mobile-unit / award sentence.
- `home` and `adeca`: same new-sentence test.
- `governor`: the Governor's newsroom index, Alabama's award channel. It trips on any new ARHTP headline.
- The name tripwire runs on resources, home and adeca.
- `tests/testthat/test_03bs_al_year2_probe.R` drives each trip both ways (12 expectations).
- Interactive run 10-02: UNCHANGED on all four pages.

**The Routine.** `trig_01NtbC312pu2u8d7uePQXEty`, `40 14 * * 4` (Thu), on new runner
`session_01C6egjruxEZH2yc6kbffHaf`. Setup matches session 82: `env_01RnpqJ1D6wFAaRMvFu43oV3`,
`claude-sonnet-5`, auto, main as source and outcome.
- The v3 prompt is MT's with state, runner and script substituted. `--write` derived v4, and `--check`
  passes for 39 states.
- The stored prompt was compared with `v4/AL.txt` by reading it, not by a scripted byte-compare.
- **First firing Thu 10-08 14:40Z. This branch must be on `main` before then.**

## 2. `logs/probe_results.csv`, 2026-09-28 to 2026-10-02 13:26Z

233 lines: 142 UNCHANGED, 74 CHANGED, 14 TRIPWIRE, 2 ERROR.
`R/probe_coverage.R --check`: 62 due firings, all logged except 4 explained misses. **No scheduled
firing is missing a line.**

### TRIPWIRE / ERROR, by state

| State | When (origin) | What fired | Read? |
|---|---|---|---|
| CO | 10-01 09:12 (Routine), 17:19 (interactive) | "end of September 2026" anchor gone | **Read.** Awarded; extracted session 82 (`R/03bo`) |
| CT | 09-28 15:41, 10-01 15:41 (Routine) | **ERROR** wrapping a name trip: OPM page names 5 new orgs (DESPP, DOC, State Police, an OPM staffer) | **Not read.** Logged ERROR, not TRIPWIRE: the name-tripwire stop was classed as access. Likely OPM page furniture (non-RHTP state agencies); needs a human read, then `furniture` entries with their sentences |
| DE (NEWSROOM) | 09-28 16:52, 10-01 16:51 (Routine) | "Governor Meyer Awards Nearly $23 Million to FQHCs Through Rural Health Transformation Program" | **Not read in any session doc.** `de_year1_awardees.csv` holds only the 07-29 release's 4 rows. Fires every sweep until read and re-based |
| MT | 10-01 17:19 (interactive) | "September" anchor gone | **Read** session 81 (4 named ambulance recipients, 75 unnamed) |
| NC | 10-01 17:48, 17:49 (interactive) | names on `roots_page`, `opportunities` | **Read** session 82 (furniture added) |
| ND | 09-30 09:21 (Routine) | 4 opportunities newly headed "Awarded", incl. "Rightsizing … Rural FQHCs and **Critical Access Hospitals**" and "Mobile Mammography Unit Acquisition" | **Not read.** The CAH opportunity is the hospital-relevant one |
| NH | 09-30 18:12 (Routine) | FHC T-TAC sentence | **Not read in a doc** (CLAUDE.md lists it as needing a human read). No subrecipient named |
| OK | 09-28 14:54 (interactive) | names on `funding` (OSDE PRIMS etc.) | **Read** session 75 |
| OK | 10-01 18:12 (Routine) | "Expanding Care: Doulas Program" now on the Funding Recipients page | **Not read.** An award OK's file does not carry; extract |
| TX (NEWSROOM) | 09-28 16:52, 10-01 16:52 (Routine) | HHSC "$51 Million in First Round of Rural Texas Strong Awards" | **Read** session 82, which re-based the baselines. **But the 10-01 Routine run still tripped.** It ran at 16:52Z, so check whether the re-base had reached `main` by then; if not, the next sweep (Mon 10-05) should be quiet |
| WV | 10-02 11:41 (Routine) | Two new Governor's releases: "$1.1 Million … to Community Care of West Virginia" and "More Than $4 Million … to Minnie Hamilton Health Care Center" | **Not read.** Add to `WV_AWARDS`. Type both on CMS enrolment (Minnie Hamilton runs a CAH and an FQHC under related entities) |

### CHANGED with no recorded explanation

Most CHANGED lines are pages whose content digest moves every firing without a trip: MS home,
gov_newsroom and dom_completed; VA ways_to_apply; WI dhs_rhtp and dhs_solicit; KY funding and rch;
NEWSROOM FL/IA/NE/NV/UT governor; LA; CA; ME (4 pages); ID; NY press_index and scr; MO bids; WA bids;
SD (3 searches); AK. Each passed every phrase and name tripwire. None is explained in a session doc
beyond "no tripwire". The ones worth a human diff are:
- **AK 09-28 (all)**: rolling roster; read in session 75 (the 09-28 refresh).
- **SD 10-01**: all three portal searches CHANGED. The contract set may have grown, and the SD portal's
  own organisation tripwire did not fire. Diff the result count.
- **ME 09-29**: four pages at once, including `rhef`.
- **NEWSROOM 10-01** `AZ:governor`, `AZ:ahcccs`, `MT:dphhs`, `NJ:doh`, `MD:governor`: first CHANGED on
  these keys.

### The six session-82 runners

None has logged under its new id yet, **because none has had a scheduled firing since the cut-over**
(10-01 17:37Z). The originals are disabled, and deletion waits on a line on `main` (CLAUDE.md, Next
session). **Nothing was deleted.**

| State | New id | First firing | Old id (disabled) |
|---|---|---|---|
| ME | `trig_01D21P4pNZXJv9vN7Uv6jmdn` | Fri 10-02 16:20Z — **logged 16:21:51Z** | `trig_01RyrB4uNLd6rdjaD8d9tWBk` — **DELETED 10-02 21:46Z** |
| WY | `trig_01CLqQDvGoWCDoSMtS29FJbQ` | Fri 10-02 21:10Z — **logged 21:12:12Z** | `trig_01F98Jr5do6PXbUzNLBGjzGE` — **DELETED 10-02 21:46Z** |
| LA | `trig_01NRTUU1Vg3DoQPL1uK2gKBt` | Sat 10-03 12:50Z — **logged 12:52:17Z (ERROR, see below)** | `trig_016GDtAW1DvWCexnRSm4LxK8` — **DELETED 10-04 11:47Z** |
| NY | `trig_012g3adVBX9KEgDt9XiVi2tU` | Sun 10-04 11:10Z — **logged 11:12:39Z** | `trig_014kvDg8x3JDqdWySvHxrREU` — **DELETED 10-04 11:47Z** |
| MO | `trig_01EB2Xxyn1bSy3LcGBEcuZra` | Wed 10-07 15:00Z | `trig_0183VrPsZUMmc3dMneainqXm` |
| SC | `trig_01221XxhsPrg8ojwngYSAAFv` | Thu 10-08 08:30Z | `trig_01R1pZjkPkQZWD3vctiAJQ44` |

SC's old id fired on 10-01 08:31Z, before the cut-over, and logged, so the chain has no gap. This
session scheduled check-ins to delete each old id once its successor's line is on `main`. The WI and NV
pair is already covered by session 80's one-shot at 15:45Z today.

## 3. Mississippi's 10-14 window

- **Confirmed:** `trig_01Ugf2k1rcJiQVTtMhpnb4V3`, `40 9 * * 2,5` (Tue/Fri 09:40Z), enabled. It last fired
  and logged 10-02 09:43Z.
- **Firings across the window (10-14 .. 10-29):** Tue 10-13, Fri 10-16, Tue 10-20, Fri 10-23, Tue 10-27
  and Fri 10-30. The longest gap between an announcement and the next read is 4 days.
- **What trips on a second-tranche award:**
  - `ms_assert_remaining_tranches` trips on award language against Workforce or EmPATH.
  - `ms_assert_announcement_on_channel` covers the Governor's newsroom.
  - The name tripwire runs on `funding` and `home`.
- No change was needed.

**Check-in 10-02 21:45Z.** ME and WY each logged on `main` under the new id. Both old ids were read with
`get_trigger` first: each was `enabled:false` and bound to the OLD runner (`session_01CdiK…`, `session_018FWp…`),
not the new one. Both were then deleted. The new NV id also logged (15:12:50Z).

**Check-in 10-04 11:45Z.** LA and NY each logged on `main` under the new id. Both old ids were `enabled:false`
and bound to the OLD runner (`session_01Meyu…`, `session_01NfXA…`), and both were deleted. The new runner
is healthy, but **LA's line is an ERROR from the probe itself**: "7 announcement windows are published and
only 0 could be parsed ... LDH has used a date form this file has not seen." LDH has re-dated or re-worded
all seven windows (they read "End of September" before). That is a page to read, and `R/03ae`'s window
parser needs the new form. It is not a runner fault.

# Session 81: CO, MT and TX announcements read; WI/NV check-in pending; runner read

Read on 2026-10-01 between 17:18Z and 17:45Z. Nothing was extracted, and no
evidence was archived (§2.2: a probe reads, and `--fetch --force` is a
deliberate act). The probes ran `RHTP_PROBE_ORIGIN=interactive`, and their
lines are in `logs/probe_results.csv`.

## 1. The three CMS releases, and what each state publishes

The CMS Routine declined at 13:00Z, because the `routines.csv` on `main` did
not yet carry the v4 ids. As a result, `cms_state_announcements.csv` holds
none of these releases. They were read live from `cms.gov/newsroom`. Two
further RHTP releases are on the same listing and are not in the file
either: **AL**, 2026-10-01, "nearly $55 million", 34 grants; and **NC**,
2026-09-30, $20M, Rural Health Innovation Fund.

| State | CMS release | State roster | Verdict |
|---|---|---|---|
| CO | 2026-09-28, $169.6M, 91 grantees, ~250 projects | **YES.** `hcpf.colorado.gov/RHTP-awardees` lists 92 priced lines totalling **$170,210,575.26** | Extract |
| MT | 2026-09-29, $8.7M, 79 EMS agencies | **NO.** DPHHS names 4 ambulance recipients at "approximately $340,000 each", and 75 equipment awards are unnamed | Watch |
| TX | 2026-09-28, $51M, 68 hospital districts | **PARTIAL.** The Budget Period 1 annual report xlsx names 33 hospital districts and authorities at $750,000 each. Neither release names any | Decide |

### Colorado

- **The probe trips.** The `rhtp` page dropped its "end of September 2026"
  anchor. It now links "RHTP Awardees" and HCPF's 2026-09-28 release.
- **What the roster is.** Each line on `/RHTP-awardees` reads
  `Name - $amount`. The page has no CMS footer; the footer on the programme
  page is Tier 1 ($200,105,604.17, 100% CMS).
- **The total does not reconcile.** The roster sums to $170,210,575.26. CMS
  says $169.6M and HCPF says "nearly $170 million". That leaves ~$0.6M
  unexplained.
- **Grain.** There are 92 lines for CMS's "91 grantees". Banner Health
  Foundation appears twice, and Epifluence (×3), Paragon (×2), Salida
  Hospital District (×2) and Valley-Wide (×2) have split lines.
- **Hospital rows.** A crude name screen finds about 38 lines that look like
  hospitals (~$93.8M). This is **not a coding.** Hospital districts,
  foundations (Banner, Valley Citizens') and Children's Hospital Colorado
  each need the §10.2 rules.

### Montana

- **The probe trips.** The Grants page anchor is gone. The page now reads
  "Date Awarded: Sept. 29, 2026 · $8.7 million · The funds will support 78
  EMS agencies."
- **The count disagrees.** The state says 78 agencies; CMS says 79 (4
  ambulance + 75 equipment).
- **What is named.** The DPHHS release
  (`/News/2026/September/Investment-in-Rural-EMS`) names only the four
  ambulance recipients: Absarokee Rural Fire District, Avon Volunteer Fire
  and EMS, Blackfeet Tribal EMS and Prairie County Ambulance Service. It
  gives the 75 equipment awards only as a range, "$3,200 to $308,637", with
  no names.
- **Hospital content.** None is visible. These are all EMS recipients
  (`NON_HOSPITAL` unless an agency is hospital-operated).

### Texas

- **The probe is UNCHANGED.** No Rural Texas Strong RFA page carries an
  awarded section. The NEWSROOM sweep tripped at 16:52Z on HHSC's headline.
- **What the releases say.** HHSC and the Governor's office (2026-09-28)
  say that "68 rural hospital districts and authorities have been awarded
  $750,000 each", which is exactly $51M. That is Initiative 1 (Make Rural
  Texans Healthy Again), direct awards. Neither release names a recipient.
- **A new source.** The HHSC programme page now links
  `bdgt-prd-1-ann-rpt.xlsx`, Texas's CMS Budget Period 1 annual report
  (Last-Modified 2026-09-28T15:33Z). It was not linked from the 08-29
  archive. Its **First-Tier Entities** tab lists:
  - HHSC: obligated $6,149,649.67, disbursed $1,504,567.12.
  - DSHS: obligated $22,389,223, disbursed $20,304,083.
  - **33 hospital districts and authorities** at $750,000 obligated each
    ($24,750,000), $0 disbursed, all typed "Other Local Government".
- **Count conflict: 33 named against 68 announced.** The report is a
  reporting-period snapshot, so it is a floor, never the round.
- **Coding question.** A Texas hospital district is a local government that
  may or may not operate a hospital. These rows are not `HOSPITAL_OR_SYSTEM`
  on the name alone (§0.4). The CMS enrolment decides each one.
- **Tier question.** DSHS is a state agency first-tier entity. That is not
  a hospital subaward.

## 2. Wisconsin / Nevada deletion check-in

`trig_01J47A3rb59Z7hsZ7mKN4VPQ` ("Delete old WI/NV Routines if new ones
published") is enabled, has run_once_at **2026-10-02T15:45Z**, and has **not
fired**. The read was taken 2026-10-01 (Thursday). Both old ids still exist
and are disabled: `trig_013N9mnDM86QEpQgzKwGFtp4` (WI) and
`trig_014c3kseN8WpCL5cMVcdaaYi` (NV). Neither new runner has had a turn yet
(WI `session_015Mmuo…` and NV `session_017bmcm…` are at epoch 1 with 0
tokens). The new WI Routine fires Fri 14:00Z and the new NV Routine Fri
15:10Z.

## 3. Runner context, read 2026-10-01 ~17:35Z

v4 was created 2026-09-30 ~15:31Z. **Nine runners have had a v4 firing.**

| Runner | Kind | used_tokens | Reading |
|---|---|---:|---|
| CA | new | 127,507 | first turn (09-30) |
| CO | new | 128,792 | first turn |
| CT | new | 130,647 | first turn |
| NEWSROOM | new | 131,194 | first turn |
| CMS | new | 142,499 | first turn; declined to publish (suite) |
| SD | in place | 384,100 | epoch 2; no prior reading recorded |
| WA | in place | 391,480 | epoch 3; no prior reading recorded |
| NH | in place | 397,535 | first turn at all (09-30) |
| SC | in place | **713,680** | 383,422 → 713,680 (+330,258) |

- **SC's jump is the predicted one-time reload**, not v4 failing. Session
  78 predicted ~715k because its 09-24 checkout left a pre-trim tree.
- **There is no measured per-firing delta yet.** No runner has two v4
  firings with a reading on each side.
- **First measurable points:**
  - CA, Sat 10-03 17:00Z, from 127,507.
  - CO, CMS, CT and NEWSROOM, Mon 10-05.
  - NH, Wed 10-07.
  - SC, WA and SD, Thu 10-08.
- **Never run (0 tokens):** KY, AR, MS, VA, WI, NV, OK and MN.
- **Fired only under v3 since creation:** the rest.
- **In-place runners near 700k:** NY 723,788, SC 713,680, LA 709,869, WY
  708,216, ME 703,973 and MO 687,835. Per §2.2a these should move to new
  runners.
- **Another check is already scheduled.** `trig_01HfFcNkhtmWSJ7CkHJEU7Ye`
  ("Thursday runner context check") fires today at 20:45Z.

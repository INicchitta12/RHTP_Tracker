# Session 74 — Vermont's 2026-09-25 update, three trips read, Maryland's newsroom opened

Run 2026-09-28. Zero RCJ quota. Network: `healthcarereform.vermont.gov`,
`governorreeves.ms.gov`, `www.nj.gov`, `ruralhealthtransformationva.virginia.gov`,
`governor.maryland.gov`, `health.maryland.gov`, `www.dhs.wisconsin.gov`.

## 1. Vermont: +34 executed agreements, +15 hospital rows, +$12,643,596.75

AHS's list now reads *"Updated as of September 25, 2026"*. Counting data rows
(the GMCB MOU included, the total row excluded), it went **112 → 146**. The
printed total went **$87,175,011.33 → $109,295,193.50**, and the rows still sum
to it to the cent. The owner's count (114 → 148) includes the header and total
rows; the difference is the same 34.

**Every 2026-09-18 agreement is still on the page, and none was re-priced.**
Thirty-four existing agreements were re-printed under a different legal-name
string. Examples: *"Northeastern Vermont Regional Hospital"* became *"... Hospital
Inc"*, *"Health Care and Rehabilitation Services (HCRS)"* became the full legal
name, and *"Mary Hitchcock Memorial Hospital*"* became *"... Hospital \*"*. Each
kept the same initiative, activity and amount. So a name-keyed diff reports 68
rows as new; the true figure is **34 new agreements, $22,120,182.17**. A test
now asserts that every prior row is present when keyed on (initiative, activity,
amount).

The prior page stays archived at `recheck/2026-09-23/VT/`. The new page is
archived verbatim at `recheck/2026-09-28/VT/`.

### Standing decisions kept

- **Mary Hitchcock Memorial Hospital (NH)** counts under Vermont. It has three
  rows totalling $8,820,815.60, `facility_state = NH`, and gained no new rows.
- **The GMCB inter-agency MOU** ($2,635,000) stays out of the award file. The
  award rows plus the MOU equal the printed total.

### Hospital effect

| | Rows | Dollars |
|---|---:|---:|
| Before (2026-09-18) | 27 | $22,641,819.43 |
| After (2026-09-25) | **42** | **$35,285,416.18** |
| Change | +15 | **+$12,643,596.75** |
| of which LOW (general knowledge or bridge) | 3 | $3,525,809.47 |
| of which on an exact CMS enrolment | 12 | $9,117,787.28 |

The fifteen new hospital rows:

- **University of Vermont Medical Center** (470003): $2,226,478.52
- **Central Vermont Medical Center** (470001): 2 rows, $1,865,904.01
- **Brattleboro Memorial Hospital** (470011): 4 rows, $1,037,698.93
- **Rutland Regional Medical Center** (470005): $959,593.02
- **North Country Hospital** (471304, CAH): $1,469,700
- **Copley Hospital** (471305, CAH): $721,780
- **Porter Hospital** (471307, CAH): $631,185.30
- **Springfield Hospital** (471306, CAH): $205,447.50
- **Southwestern Vermont Health**: 2 rows, $2,517,797.35. Typed at LOW on
  general knowledge as the parent system of SVMC (470012), following the UVM
  Health Network precedent.
- **Gifford Medical**: $1,008,012.12. Typed at LOW as a hand-read bridge to
  GIFFORD MEDICAL CENTER INC (471301). It is a prefix match, so it was never
  made by machine.

The two LOW typings are queued as `VT_S74_LOW_HOSPITAL_TYPINGS`.

### Not hospital rows

- **Gifford Health Care, Inc**: FQHC 471852, again.
- **UVM - State Agricultural College**: the university's legal name, a
  different legal body from the enrolled hospital.
- **University of Vermont Cancer Center**: a sub-unit with no enrolment. This is
  the OHSU Casey Eye shape.
- **North Star Health dba Springfield Medical Care Systems**: an FQHC.
- **BAART ×2**: opioid treatment programmes (`OTHER`).
- **NEKCA**: a community action agency.
- **Rutland Mental Health Services and Howard Center**: designated agencies.
- **Richmond Family Medicine and the Hogenkamp PC**: practices.
- **Hope Grove and Vermont Dental Services**: stay on §8's fallback.

### Knock-on effects

- `NAMED_HOSPITAL` goes **1,186 / $1,026,334,986.52 → 1,201 / $1,038,978,583.27
  / 30 states**. No pool bucket moved.
- Rural cut: **209 / $177,456,356.11 → 214 / $181,492,481.03**. Five of the new
  rows are CMS-enrolled CAHs: North Country, Springfield, Copley, Porter and
  Gifford Medical. Gifford Medical is rural only through its bridged CCN.
- Vermont's published share goes 43.3% → 54.7% of the allotment. It is still
  PARTIAL in Vermont's own words.

## 2. The three unresolved trips

**Mississippi: the headline rolled off the index; the roster did not change.**

- The newsroom's first page now runs 2026-09-17 .. 2026-09-24, and the release
  is dated 2026-09-14.
- The release URL is live, and its content digest is identical to the archive:
  still 167 awards, $104,115,146, 97 / 43 / 27.
- `ms_assert_announcement_on_channel()` now accepts the release itself when the
  headline leaves the index. It still fails if both are gone.

**Virginia: nothing new.**

- The Ways-to-Apply table was already in the archive. What moved was **status
  cells**: *Closed (August 31st 2026)* → *Closed*, Mobile & Hybrid Care Open →
  Closed, Food is Medicine and Active Kids TBD → Open.
- Its partner column names ten bodies. Nine are first-tier partners already in
  `va_year1_awardees.csv`; the VHHA Foundation appears under its trade name. The
  tenth is *Commonwealth of VA*, which is the state itself.
- The flattened table re-welded into "new organisations" on every status change,
  so the page is now diffed on its **partner column as a set**. A new partner
  still fails.

**New Jersey: a footer change, not a transient.**

- The 2026-09-24 archive's footer reads *"Governor Mikie Sherrill Lt. Governor
  Dr. Dale G. Caldwell NJ Home Services A to Z Departments/Agencies"*.
- NJ.gov re-templated that footer twice. On 09-25 it had new link labels with
  Caldwell still present. From 09-26 the Lieutenant Governor line is gone, which
  is why 'Caldwell' did not reproduce.
- *Caldwell* is Lt. Governor Dale Caldwell, not a recipient.
- The name diff is now scoped to the content above the CMS disclaimer. A test
  shows it still fires on a recipient named in the content.

## 3. Maryland's newsroom, and the two baselines

**Maryland is readable now, and nothing was missed while it was blocked.**

- `governor.maryland.gov/news/press/` 301s to `/news/press-releases`. Pages 0–4
  were read, covering 2026-08-04 .. 2026-09-25.
- There is **one** RHTP item: *"Maryland Department of Health Announces $80
  Million in First Round of Rural Health Transformation Program Awards"*
  (2026-08-10). It covers "$80 million in grant funding across 41 grantees",
  which are the 41 award offers already in `md_year1_awardees.csv` ($78,625,071).
  The release says *awarded*; MDH's own documents say *Award Offers*. The rows
  stay offers, because they are sourced to MDH's own offer lists.
- The release is archived at `recheck/2026-09-28/MD/`.
- Maryland moves from `NW_UNREADABLE` to `NW_PAGES`. Its baseline is
  2026-09-28, and the justification is written beside the row.
- MDH's own newsroom answers 200 but renders its list in script, so the reader
  finds 8 links and no headlines. It is not watched.

**Wisconsin: the new furniture string is not RHTP.**

- The furniture entry is *"Increasing Tenant and Homeowner Environmental Health
  Literacy Mini–Grant Request for Application"*.
- It is the Site Evaluation Program's mini-grant for Tribal health departments:
  up to $30,000 each, 2–3 awards, posted 2026-09-23.
- Its detail page names RHTP, Rural Health Transformation and CMS zero times.
  The justifying sentence is written beside the entry.
- The same run's `dhs_rhtp` content change is navigation only: *American Rescue
  Plan Act Funding for Wisconsin* was dropped from the menu.
- **Wisconsin has still announced no awards against its "September" date.**

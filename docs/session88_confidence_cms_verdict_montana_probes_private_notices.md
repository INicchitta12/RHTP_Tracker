# Session 88 — confidence labels, the CMS verdict, Montana, probe fixes, private notifications

2026-10-05. Five owner tasks.

## 1. Confidence labels (§7)

§7 reserves `determination_confidence = HIGH` for a primary source + named hospital + **CCN match**. 1,113 rows
across 23 state files carried HIGH with no CCN: **495 NAMED_HOSPITAL rows, $385,879,914**, plus 618 rows
outside the hospital buckets. All 1,113 are now MEDIUM. **No typing changed**: the diff of every file touches
exactly one field on exactly those rows (`git diff --word-diff`: HIGH -> MEDIUM, nothing else).

| State | Rows re-labelled | of which NAMED_HOSPITAL | NAMED_HOSPITAL $ | Other rows |
|---|---:|---:|---:|---:|
| AK | 225 | 44 | $64,811,188 | 181 |
| OR | 193 | 49 | $50,188,531 | 144 |
| GA | 110 | 87 | $60,000,000 | 23 |
| NV | 78 | 35 | $0 | 43 |
| AL | 60 | 33 | $28,105,916 | 27 |
| MS | 57 | 55 | $31,521,840 | 2 |
| SC | 57 | 50 | $52,073,176 | 7 |
| MI | 50 | 1 | $76,924 | 49 |
| NC | 37 | 0 | $0 | 37 |
| VT | 37 | 36 | $29,056,371 | 1 |
| IN | 36 | 0 | $0 | 36 |
| OK | 34 | 19 | $1,054,506 | 15 |
| PA | 29 | 26 | $23,150,824 | 3 |
| NE | 24 | 18 | $6,236,690 | 6 |
| KS | 21 | 19 | $31,221,277 | 2 |
| MO | 18 | 17 | $0 | 1 |
| SD | 13 | 3 | $1,651,849 | 10 |
| MD | 12 | 3 | $6,730,822 | 9 |
| NJ | 8 | 0 | $0 | 8 |
| WY | 8 | 0 | $0 | 8 |
| AR | 3 | 0 | $0 | 3 |
| CO | 2 | 0 | $0 | 2 |
| OH | 1 | 0 | $0 | 1 |
| **Total** | **1,113** | **495** | **$385,879,914** | **618** |

($0 hospital rows are states with named hospitals and no amounts: NV, MO.)

**Why it happened.** The shared classifier's tables carry a `confidence` that is the strength of the TYPE
reading ("... Hospital" states the form outright). `rhtp_classify_recipient_type()` and
`rhtp_recipient_type_from_org_type()` copied it straight into `determination_confidence`. GA's tribble and
MI's tribal section hand-coded HIGH.

**The fix.**
- `rhtp_confidence_ceiling()` (`R/utils_recipient_classification.R`) lowers HIGH to MEDIUM wherever the row has no
  CCN, and never raises anything. All three classifier emitters (override, name pattern, state type field) pass
  through it, so no name rule can assign HIGH.
- `R/03d` (GA) and `R/03v` (MI) lower their hand-coded HIGHs at output.
- `rhtp_assert_high_has_ccn()`, run on every file in `STATE_FILES` by `test_state_union.R`, fails any rebuild
  that reintroduces one.
- **Left alone:** SD's 6 HIGH rows carry a CCN. They meet §7's letter; whether they meet Stage 5's "full
  match" is Stage 5's question.
- **Text drift on rebuild.** Several extractors write "Classifier said X/HIGH." into a basis note. The committed
  notes keep what the classifier said when they were built; a rebuild will say "/MEDIUM". LA's rebuild this
  session shows it (one note).

## 2. The CMS verdict

`rhtp_cms_press_verdict()` counted `new_states` and `changed_rows` only. A second release for a state already in
`cms_state_announcements.csv` sits in `delta$new_rows` and was invisible. It mattered this morning: the 10-05
13:28Z Routine wrote **SD 2026-10-02, $7,200,000 ("Ambulance-Based Telemedicine")** and logged UNCHANGED. The 10-01
run's note likewise omitted AL's and NC's second releases. The verdict now counts listed-state releases
("new releases in listed states: N (ST ...)"), and its error test is `rhtp_probe_verdict()` (session 85's
bounded test) instead of the unanchored `HTTP|refused|timed out|timeout|resolve|connect`. **The SD $7.2M
release is unread.**

## 3. Montana extracted (`R/03bv`), and `R/03bl` rewritten as its roster watch

Source: Governor/DPHHS release of 2026-09-29 (archived `data/evidence/MT/2026-10-05_mt_dphhs_rural_ems_award_release.html`)
and the Grants page ("Date Awarded: Sept. 29, 2026 · Amount: $8.7 million · ... 78 EMS agencies").

| Row | Awardee | amount | Coding |
|---|---|---:|---|
| 1-4 | Absarokee Rural Fire District; Avon Volunteer Fire and EMS; Blackfeet Tribal EMS; Prairie County Ambulance Service | $340,000 each | EMS_OR_PSAP (state says "EMS agencies"), STATE_SOURCE, MEDIUM, AMOUNT_ROUNDED_IN_SOURCE |
| 5 | 75 EMS agencies (equipment awards), unnamed | empty | NOT_YET_NAMED, Unclear, RECIPIENT_NAMES_NOT_CAPTURED, n_recipients 75 |

- `round_amount` = $8,700,000 on every row; never summed down the column.
- **No subtotal is derived for the 75.** $8.7M less 4 × "approximately $340,000" is two rounded inputs and a
  figure DPHHS never published (§6.2). Range per award: $3,200–$308,637.
- **Count conflict recorded, not resolved:** the state says 78 agencies; 4 + 75 = 79 (CMS also says 79).
- **Footer** $233,509,358.76 = Montana's allotment (Tier 1), asserted, never an amount.
- **Hospital:** none. CMS MT Hospital Enrollments (archived `federal_records/2026-10-05/`) carry PRAIRIE COUNTY
  HOSPITAL DISTRICT (Terry, CAH, CCN 271309). "Prairie County Ambulance Service" does not name that entity, so it
  is not matched by machine; queued as `MT_PRAIRIE_COUNTY_AMBULANCE_OPERATOR` ($340,000).
- Survey: MT moves INVESTIGATED_NO_LIST -> EXTRACTED (38 / 7 / 2 / 3).
- **`R/03bl`** now watches the release (name-diffed: names for the 75), the Grants page (the award block must
  stay; a new award sentence trips), RFPs, home and communications. Baselines re-dated 2026-10-05; the 09-28
  files stay. Same script name, so MT's Routine needs no change.

## 4. Probe fixes

- **Louisiana.** LDH's 10-03 page replaced the windows with "October 2, 2026" (six) and "Completed" (RCCB), and
  dropped the "Application Submission Deadline" label the parser cut names from. The parser now reads exact dates
  and "Completed", anchors each entry on the Notice-of-Intent label, and reads the deadline clause only where it
  is still printed. The refusal message no longer says "REFUSED" -- that word made the 10-03 Routine log an
  ERROR instead of a TRIPWIRE. The 10 leftover name-tripwire strings (programme names glued to "Notice of
  Intent", "Submit Your Rural Success Story Here", NOFO-list fragments) were read: none is a recipient. They
  are absorbed by archiving the 10-05 page as the new `programme` baseline; 09-21 is now `programme_prior`,
  09-02 `programme_prior_0902`. The live probe is quiet.
- **North Carolina.** "The North Carolina School Health Centers" is the opening of the SBHC opportunity's own
  description ("... (SHC) Program is administered through ... NCDHHS"). Added to `NC_NAME_FURNITURE$opportunities`.
- **Alaska.** The notice is an xlsx whose bytes move on every re-save. The probe now compares the parsed award
  table (`rhtp_ak_content_digest()`). Today's 14:07Z CHANGED was a re-save: the table is identical.
- **Re-based: TN, NJ, NY, CA, ME** -- probe pages only. Every tripwire passed live first, and the reduced-text
  diffs were read: footers, navigation, news headlines. ME's `doe` trip was Maine DOE site navigation. The
  `--force` fetches also rewrote award sources (ME's three DHHS award releases and two indexes and two
  procurement pages, NY's RCHI awards release, CA's SRHRP control); **those were restored from git and their
  manifest lines restored**, so no award source was re-dated.
- Substantive items seen in the diffs: CA links a grant-notifications FAQ (below); ME's Advisory Committee meets
  2026-10-07.

## 5. Private notifications

- **California.** HCAI's "Frequently Asked Questions: Grant Notifications" (2026-09-29; archived
  `data/evidence/CA/2026-10-05_ca_hcai_calrht_faq_grant_notifications_PRIVATE_NOTICES.pdf`): applicants receive
  conditional selections, Notices of Intent to Award and non-selections through Submittable; the public
  announcement "does not confirm the outcome of an individual application"; applications still under
  consideration hear "by late October 2026". The four CalRHT pools' stage is now
  `NOTICES_SENT_PRIVATELY_NO_PUBLIC_ROSTER`, asserted off the FAQ.
- **Louisiana.** Six programmes' Notices of Intent to Contract are dated 2026-10-02 and no LDH surface names a
  selectee; denials follow "by October 16, 2026". Stage `SELECTIONS_NOTIFIED_PRIVATELY_NO_PUBLIC_ROSTER`, derived
  from the page.
- Neither state contributes a row or a dollar: nothing is published to extract.
- **CLAUDE.md wording.** Greene County ($3,913,694) and Mercy ($3,938,438) are LOW because they are typed on
  general knowledge; neither has an enrolment match or a CCN. OK RRR's enrolment bridges are three (Jane
  Phillips, Fairview, Lindsay; $4,333,575).

## Figures

The hospital partition is unchanged: NAMED_HOSPITAL 1,290 / $1,197,370,515.42 / 31 states. What changed is how
much of it is MEDIUM: none of it is HIGH any more, which is what §7 always said.

# Session 94 — Vermont's 10-02 roster, Kentucky's first Hub Lead, North Dakota, five probe fixes, Mississippi's dates

Run 2026-10-07. Zero RCJ quota. Network: `healthcarereform.vermont.gov`,
`healthy-ky.org`, `www.lcdhd.org`, `www.hhs.nd.gov`, `news.delaware.gov`,
`dhss.delaware.gov`, `www.maine.gov`, `dhhs.nebraska.gov`, `www.hca.nm.gov`,
`www.dhs.wisconsin.gov`, `portal.ct.gov`, `mississippirhtp.com`.

## 1. Vermont: 166 rows, $127,419,853.91

`R/03at --fetch --force` archived AHS's list ("Updated as of October 2, 2026")
at `recheck/2026-10-07/VT/`. The 09-25 copy stays at `recheck/2026-09-28/VT/`
as the prior. The rows still sum to the printed total to the cent.

**There are 20 new agreements ($18,124,660.41), not 21.** A diff keyed on
(initiative, activity, amount) reports 21 added and 1 removed. The pair is
Northern Counties Health Care's $226,194.70. It was printed under
Regionalization / "Transformation, innovation, and regionalization support
grants" on 09-25 and under Primary Care / "Expanding access to FQHC primary
care services" on 10-02. Same recipient, same cents, and no other row carries
that amount, so it is read as one agreement re-filed (`VT_NCHC_MOVE`; status row
`AGREEMENT_REFILED_SAME_AMOUNT`). NCHC is an FQHC, so no hospital figure moves.

**The amount-only key also mis-pairs the $2,000,000 rows.** The 10-02 page
carries four $2M facility-upgrade rows where 09-25 had two. Keyed on amount,
the "new" pair reads as CHC of the Rutland Region and Grace Cottage. Keyed on
the name first, the two new ones are **Grace Cottage** and **Northwestern
Medical Center**. CHCRR's row is the 09-25 agreement re-spelled ("...Rutland
Regional").

Eleven more 09-25 agreements were re-spelled (Copley/Porter/CVMC/BMH gained
", Inc."; "Rutland Hospital, Inc." dba RRMC; "Springfield Center for Living
and Rehabilitation" now in the legal-name column; and so on). Each carries its
prior typing. The only typing change on a carried row is CHCRR's misspelling,
which drops from MEDIUM to LOW. It is not a hospital either way.

### Hospital effect: +9 rows, +$9,581,283.08

| Row | CMS record | $ | Confidence |
|---|---|---:|---|
| Northeastern Vermont Regional Hospital (NVRH) | 471303 CAH: legal name less Inc + enrolment DBA "NVRH" | 1,554,711.80 | MEDIUM |
| Grace Cottage | 471300 CAH: enrolment DBA "GRACE COTTAGE INC" less Inc | 2,000,000.00 | MEDIUM |
| Northwestern Medical Center | 470024 | 2,000,000.00 | MEDIUM |
| Brattleboro Memorial Hospital ×2 | 470011, exact legal name | 1,343,058.80 | MEDIUM |
| Rutland Regional Medical Center | 470005, exact DBA | 191,753.70 | MEDIUM |
| Gifford Medical Center | 471301 CAH: legal name less Inc | 172,500.00 | MEDIUM |
| UVM - Health Network | system parent, no CCN (general knowledge) | 1,972,160.00 | LOW |
| Grace Cottage Family Health and Hospital | no enrolment carries the string; bridge to 471300 | 347,098.80 | LOW |

VT: 42 / $35,285,416.18 → **51 / $44,866,699.26**. LOW slice $6,000,494.29 →
$8,319,753.09. Mary Hitchcock (NH) is unchanged at three rows, $8,820,815.60.

**On "should match exactly":** byte-exact matches are BMH (legal name) and
RRMC (DBA). NVRH, Grace Cottage and Gifford Medical Center match their
enrolment record less a corporate suffix, or legal name plus the record's own
DBA. That is the convention this file already used for CVMC and UVMMC
(MEDIUM). The two Grace Cottage strings differ: "Grace Cottage" matches;
"Grace Cottage Family Health and Hospital" matches nothing and is a queued LOW
bridge (`VT_S94_GRACE_COTTAGE_FAMILY_HEALTH_BRIDGE`).

**Gifford's new facility-upgrade agreement is the FQHC.** "Gifford Health
Care", $633,201.40, is GIFFORD HEALTH CARE INC (FQHC 471852), not the hospital,
on the same record that decided session 54's trap. Gifford's hospital money in
this update is the $172,500 mentorship row only.

Not hospitals among the new rows: Kinney Drugs (pharmacy, `OTHER`), Bennington
and Bristol Rescue Squads (`EMS_OR_PSAP`), Bi-State Primary Care, VPQHC,
Behavioral Health Network of Vermont (`NONPROFIT_CBO`, general knowledge), Real
Time Medical Systems (`OTHER`, health-IT company), CHC of Burlington (FQHC).
HealthHUB and Marble Valley Healthworks stay on §8's fallback.

National `NAMED_HOSPITAL`: 1,299 / $1,203,760,515.42 → **1,308 /
$1,213,341,798.50 / 32**. The pools are unmoved. The rural cut goes 256 /
$263,299,771.23 → 260 / $267,374,081.84 (NVRH, Grace Cottage ×2 and Gifford
Medical Center cite CAH CCNs).

## 2. Kentucky: Lake Cumberland District Health Department, RCH Hub Lead

LCDHD's own 2026-10-05 release: "has been selected to lead the Rural Community
Hub for the Lake Cumberland region ... through a competitive application
process". FHKY's RCH page (the convening partner, watched by `R/03af`) links it
under Program News. Neither is a state agency and neither prints an award, so
the row is `amount` empty, `amount_confirmed = No`, `validation_source_type =
OTHER`. The form is `LOCAL_GOVT_OR_PUBLIC_HEALTH`, MEDIUM (`ORG_WEBSITE`), and
the row is NON_HOSPITAL.

**"Up to $10 million" is not this award.** The sentence is "Throughout the
grant period, the Lake Cumberland **region** will be eligible to receive up to
$10 million". It is a maximum, attached to a region, over FY2026–FY2030. It is
held as text in `amount_ceiling_text` and `amount_basis`, and in no numeric
column. The release's other figures are the $212.9M CMS footer (Tier 1) and
the $6.1B diabetes cost.

**The probe had not tripped yet, but would have.** The phrase list misses
"Selected to Lead". The name tripwire fires on "Lake Cumberland District
Health Department Selected". FHKY's page is re-based (2026-10-07 copy); the
09-02 copy stays. Big Sandy's or Purchase's Hub Lead fires next.

Kentucky moves `INVESTIGATED_NO_LIST` → `EXTRACTED`. Survey: **39 / 6 / 2 /
3**. `R/03af` keeps watching the RFAs and the other two Hubs.

## 3. North Dakota

The 10-07 09:22Z TRIPWIRE: "Workforce Retention Funding for Critical Access
Hospitals and Their Owned and Operated Clinics – Awarded | 36 Applicants". It
was read live and names nobody and prints no amount. It was added to
`ND_KNOWN_AWARDED`, and to a new `ND_HOSPITAL_ONLY_ROUNDS`, which records that
the eligible class is CAHs and their owned clinics. When names appear, every
recipient is hospital money. The extractor still types each row on CMS
enrolment.

## 4. Probe fixes

- **Delaware's firewall page.** `rhtp_fetch_past_firewall()` in
  `R/utils_config.R` detects the 246-byte F5 "Request Rejected" page (size and
  wording together). It retries after 15s and 45s, then stops with "FIREWALL
  REJECTION", which `rhtp_probe_verdict()` files as ERROR. It is wired into
  `rhtp_watch_fetch()` (every watch-page probe, including the newsroom sweep)
  and `R/03al`'s `de_get()`. The sweep's own error/tripwire count now uses
  `rhtp_probe_verdict()`. Measured 10-07: the project's agent and bare
  `Mozilla/5.0` are rejected; curl and a full Chrome UA get 130 KB. Persistent
  from here, so the retry will log ERROR. An agent exception is the owner's
  call (§3).
- **ME, NE, NM scoped.** `ME_NAME_SCOPE` covers rhef, programme (breadcrumb →
  footer) and doe (content heading → "Back to top"). `NE_NAME_SCOPE` runs from
  "What you need to know Page Content" to the Medicaid side nav.
  `NM_NAME_SCOPE` covers the programme heading and the newsroom after the
  sidebar's last link, as a lookbehind, because keeping the link text welded
  it onto the newest headline. Each was checked against the live page (quiet)
  and an injected recipient (fires). ME's programme page also gained a "Y2
  Project Narrative" document link, which is now furniture.
- **WI.** "Overdose Prevention Supplies Program Request for Application" is now
  furniture. Its detail page funds the work from SAMHSA State Opioid Response
  and state opioid-settlement money, and mentions RHTP zero times.
- **CT re-based.** `opm` gained only the State Police RFP (read in session 85),
  and its RHTP NOFO block is unchanged. `documents` gained a "Connecticut PACE
  FAQ - 8/2026" link. Both baselines are now 2026-10-07 copies, and the 09-02
  copies stay.

## 5. Mississippi

The Innovative Pilot Program NOFO (posted 10-06, archived) gives "Application
Opens 10/14/2026", "Application Deadline 11/16/2026" and "Anticipated Award
Announcement January 2027". Awards are capped at $2M per entity (a ceiling).
The status table's "October opportunities" row is split: the Pilot
(`SOLICITATION_OPENS_AWARD_DATE_PUBLISHED`, 2027-01) and EHR modernization
(still unsolicited). **WEI and EmPATH keep 10-14 .. 10-29.** That window comes
from the 09-14 Governor's release ("next 30 to 45 days"), a separate source
that nothing has contradicted.

# Session 53 — Self Regional §0.3a fix; MO and CT rosters found; VT, WV, RI read; every probe run live

2026-09-23. Zero RCJ quota. Nothing extracted: every roster found this session is archived under
`data/evidence/recheck/2026-09-23/` and reported first.

## 1. Self Regional Healthcare — the task's premise was inverted

The request described three pediatrics rows, $2.7M, coded as a practice. The file held **one**
pediatrics row coded as a practice — *Self Regional Healthcare (Greenwood Pediatrics)*, $145,000,
`PHYSICIAN_PRACTICE`/`No` — and **three** named non-hospital-site rows (Imaging Center, Montgomery
Center, Optimum Life Rehabilitation Center), $2,735,000, already `HOSPITAL_OR_SYSTEM`/`Yes`.

The fix is to move the pediatrics row up, not the $2.7M down. The cause is §0.3a in a parenthesis:
§8's `pediatrics` token read the SITE and typed the RECIPIENT. The recipient is Self Regional Healthcare
in all nine spellings, and the eight siblings are typed on CMS Hospital Enrollment (CCN 420071).
Demoting the three would break §0.3a (Beebe's school-based health centre is `DIRECT`).

- `R/03ao`: `SC_RECIPIENT_TYPE_OVERRIDES`, one named row. This is Michigan's precedent, and it returns §8's
  fallback rather than a hospital type.
- `R/03aq`: a ninth Self Regional `UF_TYPES` entry, with the same federal record as its siblings.
- **Effect: +1 row, +$145,000.** `NAMED_HOSPITAL` goes from 981 / $845,025,923.32 to **982 / $845,170,923.32**.
  SC goes from 113 / $115,840,714.95 to **114 / $115,985,714.95**.
- **SC benchmark: awards 49.6% → 50.0%; dollars 69.24% → 69.33%.** The dollar overshoot of ~60% is
  essentially unchanged. The "psychiatric excluded + four site rows" reading stays at 63.1%.
- Six guard pins re-based (`03ao`, `03aq`, `03ar`, `03as` tests; `rc_assert`; `sc_assert_bounds`).

## 2. Missouri and Connecticut have published their hospital rosters

- **MO**: `dss.mo.gov/rhtp-strategic-minor-renovations-program` (Last-Modified 2026-09-22 20:11 GMT).
  It reads "has awarded approximately $35 million … awarding grants to 20 projects … A full list of
  awardees is below". There are 20 names, all hospitals, and **no per-recipient amount**. That is Nevada's
  and Iowa's shape: 20 rows and $0. The CMS release quotes Rep. Smith as saying Salem Memorial received
  $1.7M; that is a quote, not a state figure. The programme is "Strategic Minor Renovations Program";
  no page ties it to IFB DSS26015. The `R/03w` probe's name tripwire FIRED on this.
- **CT**: Governor's release of 2026-09-16, the day BEFORE CMS's. It says DSS "has finalized $50 million in …
  grant agreements" and names Day Kimball $20.23M, Sharon $13.12M, and Hartford HealthCare's Windham +
  Charlotte Hungerford $12.65M **with no split** (a POOL_NAMED_HOSPITALS question). Mathematica, the TA
  vendor, gets $3.98M. The figures are rounded in the source (`AMOUNT_ROUNDED_IN_SOURCE`). DSS's own
  pages still name nobody, and the CT probe did not fire because it watches DSS, not the governor.

## 3. Vermont, West Virginia, Rhode Island

- **VT — extract next.** "RHT Year 1 Awards and Contracts — Updated as of September 18, 2026":
  112 priced **executed agreements**, $87,175,011.33, equal to the page's own total. The page is
  self-described as "partial and ongoing". About 28 rows name a hospital, roughly $23.2M by name
  only. Two decisions are needed first: Mary Hitchcock Memorial Hospital (NH; three rows, $8.82M, funding
  "specific to … Vermont patients") and the GMCB inter-agency MOU ($2,635,000).
- **WV — small extract.** Five Governor releases name 7 awards, $6,442,803:
  - Spotted Owl $1,174,000
  - **CAMC/Vandalia Health $612,000**
  - **Cabell Huntington Foundation $612,000** (§10.2 foundation row)
  - Ascend WV (WVU) $2.4M
  - WVHIN $855,400
  - WVU Medicine Center for Nursing Education $291,403 (form to decide)
  - CHANGE, Inc. (FQHC) $500,000

  The 2026-08-20 CMS $4.2M is two **opportunities** (Tier 2). None of RCJ's four WV
  candidates is one of these awards.
- **RI — watch; unreadable.** Every RI HTML host serves a Cloudflare challenge (403 on three agents).
  CMS says 14 LEAs/schools: §0.3a `NON_HOSPITAL`, so there is no hospital exposure.

## 4. Live CMS monitor, 21 probes, coverage check

- CMS monitor: no change. 24 announcements, 23 states. medicaid.gov lags on MO only.
- Probes: 19 exited cleanly. Two TRIPWIREs:
  - **MO** fired on a real roster (§2).
  - **LA** fired on LDH's navigation mega-menu (Office of Public Health programme list). That is page furniture;
    `R/03ae` has no `furniture`/`rhtp_name_scope()` yet and needs one before its next Routine firing.
- `probe_coverage.R --check`, run before and after the live probes: **one due firing unlogged,
  WY 2026-09-22 21:10Z**. Its Routine reports SUCCEEDED, and its session ran about 70 s. Also silent:
  **NY 2026-09-23 11:18Z and LA 12:50Z** (both SUCCEEDED, no line). These fall inside the six-hour grace
  window and will fail the check once it passes. Interactive lines do not cover them. This is session
  52's open decision: re-bind the Routines to a session that can push.

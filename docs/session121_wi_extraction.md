# Session 121, Task 2: Wisconsin's first award tables, extracted as intents

**Owner ruling:** extract DHS's award tables as INTENTS, the Missouri Smart Growth precedent (R/03cq).
Type every row on CMS WI enrolment; state agencies are state agencies.

## Source and totals

DHS RHTP pages `implementation`, `workforce`, `technology`, `coordinated-care` ("Last revised November 18, 2026"),
read 2026-11-19 (session 120, `data/evidence/recheck/2026-11-19/WI/`) and copied byte-identical to
`data/evidence/WI/2026-11-19_dhs_rhtp_*.html`. Six tables, **138 rows / $149,331,289.71**.

| Table | Rows | Sum | DHS's printed figure |
|---|---:|---:|---|
| Implementation partners | 16 | $79,373,358.71 | "$79,373,358.70" (one-cent gap in DHS's prose, recorded) |
| Community Health Worker grants | 49 | $19,942,572 | "$19,942,572 to 49 organizations" |
| CHW training provider grants | 2 | $274,714 | "$274,714 ... to two organizations" |
| Rural Technology Transformation funds | 33 | $39,740,002 | "$39,740,002 ... to 33 healthcare organizations" |
| Rural Dental Efficiency and Access | 37 | $9,500,722 | "$9,500,722 in grants to 37 organizations" |
| Sources of Strength | 1 | $499,921 | "$499,921 ... (CESA) 6" |

The five competitive tables sum to $69,957,931 ("$69.9 million in grants for Budget Year 1").
**Session 120 wrote the total as $149,330,290.71; that was a $999 slip.** The rows and the six printed totals
give $149,331,289.71.

Every row: `NOTICE_OF_INTENT_TO_AWARD`, `AMOUNT_PRELIMINARY`, `amount_confirmed = No`, `cms_review =
SUBJECT_TO_CMS_REVIEW` ("all dollar amounts are the obligated awards and are subject to Centers for Medicare &
Medicaid Services (CMS) review").

## Typing (CMS WI Hospital/FQHC/RHC Enrollments, `federal_records/2026-11-20/`)

- **Hospital: 39 rows / $32,216,238** (NAMED_HOSPITAL). MEDIUM 26 / $23,048,571 (exact legal name, CCN on the
  row). LOW 13 / $9,167,667: nine system-parent rows on GENERAL_KNOWLEDGE ($6,424,244: Ascension Wisconsin ×3,
  Children's Hospital and Health System, Marshfield Clinic Health System ×2, Mayo Clinic Health System, Bellin
  Gundersen, ThedaCare), Door County Memorial Hospital Foundation ×2 ($1,613,398, §7 foundation row), The Richland
  Hospital (DBA bridge, CAH 521341, $1,011,111) and Fond du Lac County (CCN 524025, $118,914).
- **State agencies: 5 rows / $21,083,727.35** (DATCP, DPI, WDVA, DWD, OCI): STATE_AGENCY, never vendors or
  hospitals. UWSA, the UW Board of Regents, UW PHI ×2, WTCS, two technical colleges, Marquette, MCW and the Office
  of Rural Health are UNIVERSITY_OR_AHC.
- FQHC 24, local government 8, tribal 4, AHEC 2, CESA 1, dental practices and MouthWatch OTHER 6, §8 fallback 39.

## Judgment calls

1. **Ascension Wisconsin Inc.** (3 rows, $963,997) is a system parent, not a bridge to CMS's only
   "ASCENSION WISCONSIN" string, which is the DBA of Midwest Orthopedic Specialty Hospital, LLC (a different legal body).
2. **Fond du Lac County** ($118,914, CHW grant) is a hospital row (LOW): the county legal entity is itself enrolled
   as a hospital (CCN 524025, a psychiatric number), and session 120's Murray County ruling is the precedent. The
   counter-reading is Ketchikan's (a local government is not a hospital). Reversible by CCN.
3. **Wood County Health Department** is not bridged to COUNTY OF WOOD (Norwood Health Center, 524019): a department
   named without its legal entity (§7, "what it does not reach").
4. **Mayo Clinic Health System** is a parent, not bridged to either regional enrolled entity (the string names
   neither region).
5. Multi-CCN legal names (Mercy Health System Corporation, SSM Health Care of Wisconsin) carry the lowest six-digit
   CCN on the row; all CCNs are in `cms_enrolment_record`.
6. WTCS and the technical colleges are UNIVERSITY_OR_AHC (Alaska's precedent); the Office of Rural Health is
   UNIVERSITY_OR_AHC on general knowledge (housed at UW-Madison).
7. Not in the file: DHS-led lines with no recipient table (Epic $29M, the website $9.4M, PPS $3.7M), the 11 Tribal
   Nations' $500,000 set allocations, and the Coordinating Care planning grants (not yet announced). Partner
   sub-rounds (DWD, DPI, UWSA, WTCS) are second tier and named nowhere.

## Probe (R/03y)

R/03y is now the watch: probe keys are the 11-19 index, the four award pages (a table watch,
`wia_assert_live()`, trips on any new, removed, renamed or re-priced row or a new table), the solicitations index
and the 07-23 deck. `dhs_solicit` re-based to a 2026-11-20 copy after reading the diff (two new SUPTRS Block Grant
RFAs, not RHTP). The pre-award assertions still run in `--validate` on the 10-26 archive.
`wi_assert_no_award_file()` is replaced by `wi_assert_award_file()`. Live probe 2026-11-20 16:28Z: **UNCHANGED**
on all seven sources (logged, `interactive`). Status table: dental, technology and CHW channels now
`AWARDED_PUBLISHED_INTENTS`. Survey: WI `INVESTIGATED_NO_LIST` → `EXTRACTED`.

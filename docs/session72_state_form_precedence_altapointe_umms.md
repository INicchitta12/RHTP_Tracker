# Session 72: the state's stated form stands; AltaPointe accepted; UMMS checked

2026-09-25. Zero RCJ quota. No network fetch: every check used files already
archived under `data/evidence/federal_records/2026-09-25/`.

## Task 1: AltaPointe accepted, and the state-versus-CMS precedence rule

### AltaPointe Health Systems: 3 rows, $3,602,968, owner-accepted

Session 71 re-typed AltaPointe to `HOSPITAL_OR_SYSTEM` on CMS enrolment CCN
014014, an exact legal-name match. That reversed session 12's curated override,
which had held AltaPointe at `NONPROFIT_CBO` because "the release does not state
which entity received the grant". It was the only session-71 re-type that
overrode a curated override rather than §8's fallback. The owner has now
accepted it, for these reasons:

- The governor's release names AltaPointe Health Systems and states no form for
  it. No state source contradicts the enrolment, so under the precedence rule
  below the federal record decides.
- CMS enrols ALTAPOINTE HEALTH SYSTEMS INC itself as a psychiatric hospital
  (CCN 014014, dba BayPointe Behavioral Health; EastPointe Hospital is CCN
  014017). Session 12's worry was about the recipient, and the enrolment answers
  it: the grant goes to the legal entity that holds the enrolment.
- The funded programme (EHR/IT, rural practice, mental health) does not decide
  the recipient (§0.3a).

The reasoning is now in each row's `determination_basis` ("OWNER-ACCEPTED
(session 72)") and in `R/03bj`'s `EH_APPLY`. It is also recorded as a RESOLVED
queue row, `ALTAPOINTE_ENROLLED_OPERATOR`. Confidence stays MEDIUM; HIGH waits
on Stage 5. **No figure moved**: the rows have been in `NAMED_HOSPITAL` since
session 71.

### `ENROLLED_HOSPITAL_STATE_STATED_OTHER_FORM`: resolved at option (a)

Where the awarding state's own award document states the recipient's form,
that form stands. The CMS enrolment is recorded on the row and does not re-type
it. Spec §10.2 "Academic health centers and enrolled hospital operators" is
patched with this precedence rule. The patch is byte-identical in CLAUDE.md and
`reviewer-coding-instructions.md`, and `test_flow_table_parity.R` checks it.

| State | Awardee | Stated form stands | CMS enrolment recorded |
|---|---|---|---|
| AK | Bristol Bay Area Health Corporation | TRIBAL_ORG | 021309 (legal name) |
| AK | Alaska Native Tribal Health Consortium | TRIBAL_ORG | 020026 (legal name) |
| AK | Arctic Slope Native Association | TRIBAL_ORG | 021312 (legal name) |
| AK | Alaska Psychiatric Institute | STATE_AGENCY | 024002 (DBA of a different department) |
| OR | Lake Health District | FQHC_OR_RHC | 381309 (legal name) |
| OR | Saint Alphonsus Medical Center - Baker City | FQHC_OR_RHC | 381315 (legal name) |
| OR | Providence Hood River Memorial Hospital | FQHC_OR_RHC | 381318 (DBA) |
| OR | Providence Seaside Hospital, 3 clinic sites | FQHC_OR_RHC | 381303 (DBA) |

What changed on each row:
- `cms_enrolment_record` now carries the enrolled legal name, DBA, CCN and
  archived file, followed by "RECORDED, NOT APPLIED".
- `determination_basis` gains the tag "STATE-STATED FORM STANDS OVER CMS
  ENROLMENT (session 72)".

What did not change:
- `recipient_type`, flow, confidence, flags and `distributed_to_hospital` (all
  `No`).
- `cms_enrolment_match` and `ccn` stay empty. Both mean "re-typed on the
  enrolment", and Stage 5 will read a `ccn` as a hospital match.

The Alaska projects that Alaska itself types "Hospital" (BBAHC, ANTHC) are
untouched. **$0 moved.** The $2,088,858 that option (c) would have moved stays
out of `NAMED_HOSPITAL`.

**Why the state's form wins.** The award document is the source of record for
what the state awarded and to whom (§0.1), and its statement of the form is part
of that award. An enrolment records what else the legal entity operates. So the
enrolment decides only where the state states no form: AltaPointe, and every
session-71 row.

`R/03bj` enforces this in two ways:
- `s71_overlay()` step 3 refuses a held awardee that has no non-hospital row.
- `eh_assert_read()` refuses an `EH_HOLD` CCN that disagrees with the sweep.

The enrolled names come from the archived file, not from hand-typed text.

## Task 2: UMMS does not match a CMS enrolment on its own legal name

The archived CMS Maryland Hospital Enrollments file holds 57 records. It is the
complete state, pulled at `size=5000`. It carries "University of Maryland
Medical System" as no ORGANIZATION NAME and no DBA, and so does every other
archived federal record. Eight UMMS hospitals are enrolled, each as its own
legal body:

| Legal body | CCN |
|---|---|
| University of Maryland Medical Center, LLC | 210002 |
| University of Maryland St Joseph Medical Center LLC | 210063 |
| Baltimore Washington Medical Center Inc. | 210043 |
| Upper Chesapeake Medical Center Inc | 210049 |
| Maryland General Hospital Inc | 210038 |
| James Lawrence Kernan Hospital, Inc. | 210058 |
| Dimensions Health Corporation | 210003 |
| Chester River Hospital Center | 210030 |

The awardee is the system parent, not an enrolled legal entity, so the §10.2
rule does not reach it. UMMS ($4,020,144) stays `UNIVERSITY_OR_AHC` and stays in
`AHC_STRING_NAMES_NO_ENROLLED_ENTITY`, alongside UAB Montgomery, OHSU Casey Eye
Institute and Michigan MEDIC, all left queued as instructed. The finding is
appended to that queue row.

**Open for the owner:** the queue row's option (c) still stands. UMMS is a
hospital system, not a university, so `UNIVERSITY_OR_AHC` is itself doubtful.
Typing it `HOSPITAL_OR_SYSTEM` would need a source that states its form, not an
enrolment match.

## Totals

- `NAMED_HOSPITAL` is unchanged: 1,185 rows / $1,022,314,842.52 / 30 states.
- Pool buckets are unchanged.

## Tests

`test_03bj` gains four tests:
- Held rows record the enrolment and are not re-typed.
- A held CCN that disagrees with the sweep fails the build.
- AltaPointe is owner-accepted.
- UMMS has no enrolment match.

The queue-status pin moves to RESOLVED. The parity test checks the new sentence.

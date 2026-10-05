# Session 93 — VA system parents accepted; KY Dental Hygiene conflict recorded

Two owner tasks, both left open by session 92.

## 1. Valley Health, Ballad and Sentara: accepted as system parents

- **Owner decision.** Valley Health System (2 lines), Ballad Health and Sentara Health are accepted as
  `HOSPITAL_OR_SYSTEM`, LOW, `basis_type = GENERAL_KNOWLEDGE`, no CCN. This matches the precedent set for
  Sanford and Avera (SD), UVM Health Network (VT) and Virtua (NJ).
- **Recorded as** `VA_VHCF_SYSTEM_PARENTS` in `classification_review_queue.csv`, which was opened and
  resolved in the same row. The row was appended byte-wise as CRLF, and `git diff --numstat` reads 1/0.
- **R/03bx:** the header and `HVA_PARENT_NOTE` now cite the acceptance. `--build` changed only the
  `determination_basis` text on the four parent rows (4/4 numstat).
- **Figures:** nothing moved. VA VHCF has 25 lines / $14,390,000, and 9 hospital lines / $6,390,000.
  Of that, $5,700,000 is subtractable (GENERAL_KNOWLEDGE). Subtracting it leaves 5 rows / $690,000.

## 2. Kentucky Accredited Dental Hygiene Programs: conflict recorded, stage unchanged

- **Archived** `data/evidence/KY/2026-10-05_ky_rfa_accredited_dental_hygiene_programs.pdf` (109,989 bytes,
  SHA-256 `0f3b328e…`, PDF created 2026-04-29). It is a new `KY_SOURCES` key, `rfa_adh`. `--fetch` without
  `--force` wrote only this file, and the manifest gained one line.
- **The RFA's own timeline (§IV):** "May 29, 2026 – Deadline for Receipt of Applications"; "June 26, 2026 –
  Notification of Award to Grantees"; "August 1, 2026 – Funding Period Begins". The pool is "$9.9m"
  available from 2026-08-01. The CMS footer reads "100% funded".
- **The CHFS channel** (archived 2026-09-02) prints "Deadline for Receipt of Application – August 1, 2026".
  That date is the RFA's funding-period **start**, not its deadline. The status row's "Closed 2026-08-01"
  comes from the channel.
- **What the status row says now.** The row keeps `CLOSED_UNAWARDED` / `award_date_published = NA`. Its
  note records both readings:
  - If the RFA governs, the award date passed on 06-26 and the row would be `CLOSED_AWARD_DATE_PASSED`.
  - If the channel reflects a re-opened round, `CLOSED_UNAWARDED` stands.
- **Not added to `KY_AWARD_DATES`.** Doing so would move the probe's dated-negative finding, and the owner
  asked for the stage to stay unchanged.
- **The weak point.** Neither source is a later CHFS statement. Until CHFS says whether the round was
  re-opened, the conflict cannot be resolved from the archive.

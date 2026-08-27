# RHTP Tracker — Reviewer Coding Instructions

**Read this before coding any record.** One page. It exists because the first eleven records were coded wrong in a way that would have reported Delaware's hospital total as zero.

---

## The one rule

# Code the RECIPIENT, not the ACTIVITY.

The question is **who received the money**, never **what the money was spent on**.

A hospital that receives RHTP funds to run a clinic inside a middle school is still a hospital receiving RHTP funds. Where the clinic sits is irrelevant to the coding.

---

## Worked examples — all real, all from Delaware

| Awardee | Activity | `hospital` | Why |
|---|---|---|---|
| Beebe Healthcare | School-based health center | **Yes** | Beebe is a hospital system. It got the money. |
| TidalHealth | School-based health center | **Yes** | Hospital system. |
| Nemours Children's Health | School-based health center | **Yes** | Pediatric hospital system. |
| Beebe Medical Center | Diabetes wellness pilot | **Yes** | Hospital. |
| Thomas Jefferson University | Medical school partnership | No | University, not a hospital. |
| Delaware Health Information Network | Statewide HIE infrastructure | No | Vendor. Hospitals benefit; hospitals receive nothing. |
| Delaware State Housing Authority | Housing-linked initiative | No | Real recipient, not a hospital. |
| "Not identified" | VBC readiness | **Unclear** | State confirms an award, names nobody. |

Four of the first four rows were originally coded `no` because the activity happened in schools. All four are hospitals.

---

## How to decide

**1. Who is named as the recipient?** Read the name, ignore the program description.

**2. Is that named entity a hospital or health system?** Look for: Hospital, Medical Center, Health System, Healthcare, Regional Health, or a known system name. When unsure, search the name — do not guess from the activity.

**3. If no recipient is named** → `Unclear`. Never infer one from the activity or from who is eligible.

**4. If the recipient is an intermediary** (a foundation, a state agency, a hospital association) → flag it and note who the money passes to, if the document says. If it doesn't say → `Unclear`.

---

## Two claims, coded separately

Never merge these into one column.

**`recipient_confirmed`** — does a state source name this recipient?
`Yes` / `No` / `Unclear`

**`amount_confirmed`** — does a state source give a dollar figure **for this specific recipient**?
`Yes` / `No` / `Unclear`

**`amount_confirmed = No` is the normal answer.** Most states publish dollars only at initiative level. That is not a failure and not something to work around.

**An initiative budget is not a recipient amount.** If a document says "$950,000 for the Diabetes Wellness Program" and names Beebe and TidalHealth as participants, that is **not** $950,000 to Beebe and **not** $475,000 each. Record the initiative figure in the initiative table; leave the recipient amount blank.

**Never split an initiative budget across recipients.** Not evenly, not proportionally, not at all.

---

## Evidence — required for any `Yes`

| Field | Requirement |
|---|---|
| `state_source_url` | A **URL**, starting `http`. Not a page title. "Contract Details HSS26063 - DE Bids Contracts" is a title and will be rejected. |
| `archive_path` | A saved copy of the page or PDF. Browser "Print to PDF" is fine. State pages move. |
| `confirming_text` | The actual sentence establishing the award, pasted in. |

No archive, no `Yes`.

---

## What counts as a state source

**Strong** — Notice of Award, Notice of Intent to Award, procurement portal posting, state RHTP budget narrative, official state agency or governor release naming the recipient.

**Not sufficient on its own** — news articles, trade press, RCJ's own record or description, a vendor's press release.

Third-party news can never support a `Yes`. It can point you toward the state source; find that instead.

---

## When to stop and ask

- The recipient name is ambiguous or you can't tell what kind of organization it is
- The amount conflicts between two state sources
- The document is both a plan and an award list and you can't tell which applies
- The award appears to duplicate one you've already coded
- Anything feels like it needs a judgment call the rules above don't cover

Put it in the review queue with a note. **An honest `Unclear` is always better than a confident guess.** Every `Yes` in this file has to survive someone trying to knock it down.

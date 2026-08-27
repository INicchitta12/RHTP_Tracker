# API documentation capture — 2026-08-27

Archived copies of Rural Care Journey pages as they stood at Stage 0 preflight.
Kept under `data/raw/` because they are immutable evidence: the API docs will
change, and every schema decision in this pipeline is justified against this
snapshot.

| File | Source URL | HTTP |
|---|---|---|
| `api-docs.html` / `.txt` | https://www.ruralcarejourney.com/api-docs | 200 |
| `privacy-policy.txt` | https://www.ruralcarejourney.com/privacy-policy | 200 |
| `membership-api.txt` | https://www.ruralcarejourney.com/membership/api | 200 |

## Terms-of-service probe (all 404)

No terms of service, API terms, or redistribution licence exists on the site.
Probed and confirmed absent on 2026-08-27:

    /terms             404
    /terms-of-service  404
    /tos               404
    /legal             404
    /privacy-policy    200  (account data only — no data-reuse terms)
    /api-terms         404

Every link on `/api-docs` was enumerated; the only legal document linked
anywhere is `/privacy-policy`. See CLAUDE.md §8.

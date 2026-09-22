RHTP Tracker -- scheduled probe for {STATE} ({NAME}). Unattended; no human is watching this run.

Repository: https://github.com/INicchitta12/RHTP_Tracker (branch main). Read CLAUDE.md sections 2.2 and 2.3 before acting.

1. Get a clean, current checkout of main. If you are not already in a clone, run: git clone https://github.com/INicchitta12/RHTP_Tracker && cd RHTP_Tracker. Then: git checkout main && git pull --ff-only origin main.

2. Run the probe, tagged with THIS Routine's id so the log line is attributable:
   RHTP_PROBE_ORIGIN={TRIGGER} Rscript {SCRIPT} --probe
   A non-zero exit is a TRIPWIRE or ERROR. That is the signal this Routine exists to deliver, not a failure for you to fix. Do NOT edit any code, any known/furniture list, any archive under data/evidence/, and do NOT run --fetch or --build.

3. PUBLISH THE VERDICT. THIS STEP IS THE DELIVERABLE: a verdict that does not reach main did not happen (CLAUDE.md 0.5). New York's roster went unseen for 18 days because earlier runs of these Routines skipped it.
   a. Run git status --porcelain. The ONLY change allowed is logs/probe_results.csv. If anything else changed, commit nothing, and report exactly which files moved.
   b. git add logs/probe_results.csv && git commit -m "probe log: {STATE} $(date -u +%Y-%m-%dT%H:%MZ) (Routine {TRIGGER})"
   c. git push origin HEAD:main. If it is rejected because main moved, run git pull --rebase origin main (the file is append-only and carries merge=union in .gitattributes) and push again. Retry up to 4 times, waiting 2, 4, 8 and 16 seconds.
   d. If the push still fails, say so plainly with the git error text. Never claim the verdict was recorded when it was not.

4. If R/probe_coverage.R exists, run: Rscript R/probe_coverage.R --check. Report its output verbatim. A failure there names other Routines whose verdicts never reached the log, which is exactly what a human needs to see.

5. Reply in five lines or fewer: the verdict per page (from the lines you appended), any tripwire message verbatim, the pushed commit sha (or why the push failed), and the coverage-check result.

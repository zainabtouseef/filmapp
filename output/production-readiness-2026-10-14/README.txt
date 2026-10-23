CINECONNECT PRODUCTION READINESS AUDIT - 2026-10-14

Verdict: NO-GO for unrestricted public production.
28 findings: 1 Critical, 13 High, 13 Medium, 1 Low.

Fresh JSON evidence is in this directory. report.json and findings.json contain the detailed register.
The final 28-page PDF is supplied separately and contains 13 embedded evidence files.

The isolated-probes.py script runs only in a temporary local SQLite database using synthetic identities. Run from the filmapp repository root with its existing Python environment. It reports issue_reproduced=true when a finding is reproduced; process success is not a readiness pass.
The runtime-readonly-probe.py script reads deployed configuration, routes, aggregate data and verifies source seed defaults against password hashes. It outputs counts only and must only be run with authorized host access.

Retained-validation/ contains recent full test/build evidence for unchanged commit 59c4791e67aa9609c72d1f5bcff5ea696f10bfcd. These full suites were not rerun in the fresh audit.

Excluded: plaintext credentials, password hashes, private keys, personal customer records, full third-party advisory descriptions, and unrelated shared-host inventory.
Production data and services were not changed by this audit.

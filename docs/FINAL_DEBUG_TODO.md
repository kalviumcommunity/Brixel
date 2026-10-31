# Final debug TODO

1. [x] Preserve work: dedicated fix/final-debug-submit branch; tracked patch and untracked archive in /tmp.
2. [x] Attempt fetch; compare local origin/main. Fetch blocked by GitHub timeout.
3. [x] Reproduce reported registration state with user on RMX3762: waiting for approval.
4. [x] Trace layer: pending authorization after successful account/profile creation.
5. [x] Repair auth/profile lifecycle, account-switch isolation and partial signup recovery.
6. [x] Verify role/access/site routing with deterministic tests; managers follow PRD F2.
7. [x] Review protected navigation, logout and site context; add empty-site logout.
8. [x] Review real attendance, material and incident persistence and safe failure behavior.
9. [x] Review Firebase configuration and local rules; no deployment.
10. [x] Preserve warm theme; test 320/360/390/412 widths. Mock screenshot comparison blocked: no image attachments supplied.
11. [x] Add regression tests; full suite 208 passing; analysis clean.
12. [x] Run format, web, universal debug/release attempts and ARM64 debug build. Universal APKs blocked by artifact download timeouts; ARM64 debug succeeds.
13. [ ] Complete physical authorized-account smoke, invalid credentials, logout/restart, offline and evidence upload. Pending administrator approval/test account.
14. [ ] Execute rules in emulator/live backend. Emulator setup/CLI absent; live administrative access not available.
15. [x] Review auth/navigation and rule diffs; git diff --check clean. No commit, push, merge or rule deployment.

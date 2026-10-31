# Final debug review

## Preservation and comparison

Work continues on `fix/final-debug-submit`, preserving the initial uncommitted work.
Recovery files: `/tmp/brixel-before-final-debug.patch` (tracked patch) and
`/tmp/brixel-before-final-debug-untracked.tar.gz` (initial untracked source).
`git fetch origin` was attempted with network permission but timed out connecting
to GitHub. Comparison uses the existing local `origin/main` at `2d6a4dc`;
it is not asserted to be current upstream.

## Classification of inherited changes

- Keep: guarded named routes, isolated protected navigator, assignment-based site
  query batching, real attendance/material persistence, safe errors, finite-number
  validation, current-user incident identity, non-retried incident creation,
  evidence validation, site report history, cream/orange theme, responsive cards,
  server timestamps, and associated regression coverage. Verified by code review
  and deterministic tests, not by a live-backend claim.
- Repair: unstable gate subscriptions; account-switch profile snapshot isolation;
  ambiguous partial registration recovery; inability to log out from an empty site
  list; restriction of managers to assigned sites contrary to PRD F2; missing
  release Internet permission; server-side attendance-update validation and
  material non-finite quantity validation.
- Revert because incorrect: no wholesale reverts. Removed the inherited trailing
  whitespace in Architecture.md; its intended textual content is retained.
- Investigate externally: deployed Auth provider, deployed rules, existing account
  profiles, Storage provisioning and end-to-end phone behavior. No console access
  or rule deployment is inferred from local configuration.
- Investigate visually: the sole supplied attachment is text. The repository
  wireframe README explicitly says it contains no exported mock screenshots.
  Theme consistency and width tests do not establish screenshot parity.

## Physical registration finding

The app was built for ARM64, installed and launched on RMX3762, Android 15.
USB authorization was intermittent and required user intervention. The user
reported that Create account led to “Your account is waiting for approval”.
This confirms the assisted registration attempt reached the pending-access
boundary: account creation/profile loading succeeded for that attempt. The
reported inability to create an account was pending authorization, not evidence
that Firebase rejected account creation. An administrator must approve the
intended role and site assignments; self-elevation is deliberately blocked.
Authorized-site features and invalid credentials still need physical validation.

## Confirmed defects and limits of root-cause evidence

The main Android manifest lacked INTERNET permission. Debug/profile manifests
provide it, so the defect affects release variants. The originally installed
phone package was inspected and already had INTERNET permission: this defect
must not be presented as the proven cause of that installed app's login symptom.

AuthStateGate previously constructed streams in build. Streams are now cached
for a session; changing UID constructs a keyed profile boundary. Regression tests
cover subscription stability, account switching, role failures, logout, routes,
registration partial failure, duplicate login and safe failure loading reset.

A profile-write timeout is an unconfirmed write, not proof of rollback. The Auth
account remains signed in behind the gate. The UI explicitly tells the user not
to register again and to contact an administrator; a delayed successful profile
write can still update the gate. No account or password is deleted or logged.

## Feature and rule review

Attendance and material forms await real repository writes before success and
retain safe failure states. Site/user fields override caller-supplied identities.
Quantities/hours reject non-finite values. Site context is passed through all tabs.
Incident creation is not blindly retried. Evidence uses a generated incident ID,
site-scoped path, MIME metadata and real download URL; upload failure prevents
report success. A successful upload followed by a failed report write can leave
unreferenced immutable evidence; no destructive cleanup is attempted.

The seeding helper is uncalled sample code; demo constants there and preview/test
fixtures are not production route fallbacks. The app uses the existing Firebase
project `brixel-93861`, Android package `com.example.brixel`, matching Android app
ID and `brixel-93861.firebasestorage.app` bucket. No generated Firebase identifiers
were changed.

Local rules preserve default denial, safe pending registration, author/site
integrity and immutable audit fields. Manager all-site access follows PRD F2;
supervisors remain assigned-site scoped. Storage permits only authorized image
creates at scoped evidence paths, capped at 10 MB, and disallows replacement.
Rules were reviewed statically. Existing Dart rule tests inspect strings or
simulate logic; they do not execute Firebase rules. Firebase CLI/emulator setup
is absent; no emulator or deployed-rule verification is claimed. Nothing deployed.

Release currently uses the repository's existing debug signing configuration.
Even a successful release build would not constitute production signing approval.

## Physical smoke checklist

On the connected phone, enter credentials directly (never in this document):
1. Cold launch: splash then login or restored-session access result.
2. Invalid login: safe error, enabled retry; repeated submit sends one request.
3. Valid login: profile loading then pending, unavailable, or authorized destination.
4. Authorized role: permitted sites, selected-site dashboard and all four tabs.
5. Submit test reports only with an agreed test account/site; inspect history.
6. More → logout; Back must never show protected content; reopen signed out.
7. Sign in and restart without logout to check persistence.
8. Offline errors, keyboard, narrow layout, image selection/upload when available.

Missing profile: administrator checks Authentication user and matching users/UID
in the same Firebase project, then repairs profile with intended role/assignments.
Provider disabled, rules deployment or Storage setup must only be reported as an
actual blocker when confirmed by live evidence; none is assumed from this review.

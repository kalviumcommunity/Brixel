# Brixel: project explanation and presenter guide

Open `presentation.html` beside the deployed web app to present the project. Its Open app link leads to the normal Flutter entry point.

## 01. The problem: Site activity moves faster than paperwork.

Attendance, material consumption and safety observations often arrive late or in disconnected records. Brixel brings these reports into one site-specific workflow so supervisors can record events and managers can review them.

## 02. People & permissions: The right access for each person.

New accounts start pending. An administrator approves a supervisor or manager role. Supervisors work with assigned sites; managers can review all sites under the current local implementation and rules. Authentication proves identity; the Firestore profile determines access.

## 03. Daily reporting: Three focused workflows.

Attendance captures worker or crew, trade, presence and valid hours. Materials captures material name, unit, quantity used and notes. Safety captures location, incident type, severity, description and optional photo evidence. Every production submission carries its selected site and authenticated author.

## 04. Architecture: One interface. Connected services.

Flutter supplies the mobile and web interface. Firebase Authentication manages accounts and sessions. Cloud Firestore stores profiles, sites and reports, with streams updating the interface as records change. Firebase Storage holds evidence images. Security rules enforce backend access independently of the interface.

## 05. A report’s journey: Validate → save → confirm → review.

A form validates input and blocks duplicate submission while saving. Its repository builds the site-scoped payload with the current author and server timestamps. Firestore acknowledges persistence before the interface reports success. History streams then expose the saved record for review. Failures remain visible and do not become fake successes.

## 06. Safety evidence: Keep the image with its incident.

The app allocates an incident ID, uploads supported image bytes under a site/incident evidence path, retrieves the real download URL and saves the incident with that association. Upload failure prevents success. An upload followed by a failed document write can leave unreferenced evidence; this is a known recovery limitation.

## 07. Session lifecycle: Access remains behind a single gate.

Startup initializes Firebase, then the splash screen hands control to AuthStateGate. Signed-out users see login. Signed-in users load their profile and see pending, unavailable or authorized access. Protected navigation is disposed when the session or access changes. Logout returns the user to the signed-out boundary.

## 08. Verification: Evidence before claims.

The last full verification passed 208 tests and Flutter analysis. Web and ARM64 debug builds passed. Universal Android builds encountered dependency-download timeouts. A physical Android registration reached pending approval. Approved-account feature writes, Storage uploads, complete device smoke testing and deployed-rule behavior still require live verification.

## Data model and source locations

- `users/{uid}`: identity display information, role, assignedSiteIds and timestamps. Auth credentials remain managed by Firebase Authentication.
- `sites/{siteId}`: site name, location, status and assignment metadata.
- `attendance/{id}`: siteId, workerName, trade, status, hoursWorked, date, recordedBy and timestamps.
- `material_transactions/{id}`: material identity/name, unit, type, quantity, siteId, recordedBy and timestamp.
- `incidents/{id}`: siteId, incidentType, severity, description, reportedBy, status, photoUrl and resolution metadata.
- Storage: `sites/{siteId}/safety/{incidentId}/evidence/{fileName}`.

The feature-first `lib/features/` tree groups authentication, sites, navigation, attendance, materials, reporting and safety. `lib/core/` holds shared database access, theme and utilities. `lib/shared/widgets/` supplies reusable controls. Models map Firestore records into Dart objects; repositories isolate persistence from screen rendering. Dependency injection enables tests to substitute fake services without contacting Firebase.

## Why login and approval are separate

An account can be correctly signed in while lacking permission to enter site features. Registration creates a safe pending profile; it does not make the registrant a supervisor. AuthStateGate watches identity and profile streams. A missing profile or an unsupported role never grants access. The approved role determines the next screen. The backend rules must agree with these client decisions: hiding a button alone is not security.

## How to explain reliability

Forms validate required fields and numeric ranges. NaN and Infinity are rejected. Loading disables repeated submission. Success follows an awaited repository operation, and finally blocks clear loading. Generated-ID creation is not blindly retried, since an uncertain first result could otherwise create duplicate records. Firestore streams are listeners, not periodic manual refreshes. They update history when matching documents change; connectivity can affect when server changes arrive.

## Demo preparation

1. Open the showcase page and rehearse its six-minute story.
2. Use an approved test account; do not attempt first-time approval during the demo.
3. Confirm a real permitted test site exists and its document ID matches assignments.
4. Rehearse one attendance submission, one material submission, and history reads.
5. Rehearse safety evidence only if Storage works in the deployed project.
6. Show logout and verify Back does not reveal protected content.
7. Keep the explanation page available if network access fails; never present static cards as saved live records.

## Suggested opening

“Brixel reduces the delay between construction-site activity and the information available to managers. A supervisor selects a permitted site and records attendance, material usage or safety incidents. Firebase stores these reports and updates connected screens. Role-based access keeps reporting tied to the right people and sites.”

## Questions to prepare for

**Why Flutter?** One existing Dart codebase serves Android and web with reusable widgets and feature modules.

**Why Firebase?** Authentication, document streams and file storage cover the MVP without a separate custom backend service.

**Does it work fully offline?** Do not claim a complete offline workflow. Connectivity failures are handled, but offline persistence and reconciliation have not been fully verified on the target device.

**Is this inventory or payroll software?** No. The presentation scope is attendance reporting, material consumption and safety; it does not add payroll, procurement or accounting.

**Is it production ready?** Automated checks and selected builds passed, but approved-account device flows, deployed rules and Storage need live verification. Release signing also remains the existing debug-signing setup.

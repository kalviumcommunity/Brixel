# Product Requirements Document: Brixel

**Sprint 2, Mobile App Development (Flutter + Firebase)**
**Team:** Team 05 | **Members:** Kriday Achraj Shanker, Nimra Mittal, Tavish Modi | **Project Admin:** [name]
**Status:** Draft v1 for mentor review

---

## 1. Overview

Brixel is a cross-platform mobile app that lets construction site supervisors record labor attendance, material usage and safety incidents on the spot, and lets project managers see the combined, live picture across all sites.

## 2. Problem Statement

A construction company runs several project sites at once. Supervisors capture labor attendance, material usage and safety incidents only in notebooks, which are reviewed during head-office visits. Project managers therefore schedule work and order materials using information that is days behind real site conditions.

**Consequences of the gap**
- Labor shortages and overstaffing are noticed late, so schedules slip or wages are wasted.
- Material shortages are discovered after work has stalled; over-ordering ties up money.
- Safety incidents are reported days later, delaying response and follow-up.

## 3. Goals and Non-Goals

**Goals**
1. Reduce the delay between an event on site and its visibility to managers from days to minutes.
2. Make data entry fast enough that supervisors actually use it (target: daily attendance in under 2 minutes).
3. Give managers one live view of attendance, stock and incidents across sites.
4. Raise high-severity safety incidents immediately, not at the next visit.

**Non-goals (this sprint)**
- Payroll, wage calculation or billing
- Procurement ordering and vendor management
- Project scheduling (Gantt charts, task dependencies)
- Biometric or GPS-verified attendance
- iOS-specific polish (target Android first; Flutter keeps iOS possible)

## 4. Users

| User | Context | Needs |
|---|---|---|
| **Site Supervisor** | On site all day, phone in hand, often poor connectivity, limited time | Very fast entry, simple forms, works with weak network, sees only their assigned sites |
| **Project Manager** | Oversees multiple sites, mostly at head office or in transit | Live cross-site summary, drill down into a site, alerts for stock and safety issues |

*Optional third role, only if time allows:* **Safety Officer** (read-only view of all incidents with follow-up status).

## 5. User Stories

**Authentication and roles**
- As a user, I can sign up and log in so my data is tied to me.
- As a user, I stay logged in between app launches.
- As a manager, I can assign supervisors to sites.

**Attendance**
- As a supervisor, I can record today's attendance for my site (worker or crew, trade, present or absent, hours).
- As a supervisor, I can edit or correct an entry I made today.
- As a manager, I can see today's headcount per site versus expected headcount.

**Materials**
- As a supervisor, I can log material received and material used, with quantity and unit.
- As a supervisor, I can see remaining stock for each material on my site.
- As a manager, I can see which materials are below their reorder threshold, per site.

**Safety incidents**
- As a supervisor, I can report an incident with type, severity, description and a photo.
- As a manager, I see new high-severity incidents as soon as they are reported.
- As a manager, I can mark an incident as acknowledged or resolved.

**Dashboard and search**
- As a manager, I can see all sites in one list with key indicators (attendance, low stock, open incidents).
- As a manager, I can filter by site, date range and incident severity.

## 6. Functional Requirements

### Must-have (MVP)
| ID | Requirement |
|---|---|
| F1 | Email/password authentication with persistent login |
| F2 | Role-based access: supervisor (own sites only) and manager (all sites) |
| F3 | Site list and site detail screens |
| F4 | Create, read, update, delete for daily attendance records |
| F5 | Material catalogue per site with received/used transactions and computed remaining stock |
| F6 | Incident report form with photo upload to Firebase Storage |
| F7 | Manager dashboard with live (real-time) updates across sites |
| F8 | Filtering by site, date and severity |
| F9 | Firestore Security Rules enforcing role and site access |
| F10 | Loading, empty and error states on every screen |

### Should-have
| ID | Requirement |
|---|---|
| F11 | Low-stock indicator based on a per-material reorder threshold |
| F12 | Incident status workflow (reported, acknowledged, resolved) |
| F13 | Offline entry with automatic sync (Firestore offline persistence) |

### Stretch (only if ahead of schedule)
- Push notifications for high-severity incidents
- Trend charts (attendance over time, material burn rate)
- Export a site's daily report to PDF

## 7. Screens and Flow

**Shared:** Splash, Login, Sign up
**Supervisor:** Home (my sites) → Site detail → Attendance list / add / edit · Materials list / log received or used · Incidents list / report new
**Manager:** Dashboard (all sites) → Site detail (read view of attendance, stock, incidents) → Incident detail (acknowledge or resolve) · Filters · Supervisor assignment
**Shared:** Profile and logout

```
Login → (role check) → Supervisor Home → Site → [Attendance | Materials | Incidents]
                     ↘ Manager Dashboard → Site → [Attendance | Materials | Incidents]
```

## 8. Data Model (high level, detailed in System Design)

- `users/{uid}`: name, role, assignedSiteIds
- `sites/{siteId}`: name, location, status
- `sites/{siteId}/attendance/{recordId}`: date, worker or crew, trade, status, hours, recordedBy
- `sites/{siteId}/materials/{materialId}`: name, unit, reorderThreshold, currentStock
- `sites/{siteId}/materials/{materialId}/transactions/{txId}`: type (received or used), quantity, date, recordedBy
- `sites/{siteId}/incidents/{incidentId}`: type, severity, description, photoUrl, status, reportedBy, timestamp

*Open design point:* cross-site manager queries will use collection-group queries or a summary document per site. To be decided in System Design.

## 9. Tech Stack

- **Dart and Flutter:** UI and app logic
- **Firebase Auth:** identity and sessions
- **Cloud Firestore:** real-time database
- **Firebase Storage:** incident photos
- **Tested on:** Android emulator and at least one physical device

## 10. Non-Functional Requirements

- **Usability:** core entry flows completable in a few taps; readable outdoors (high contrast, large touch targets).
- **Reliability:** no data loss if the network drops mid-entry (F13).
- **Security:** users can only read and write data their role and sites allow; enforced by Security Rules, not only by the UI.
- **Performance:** dashboard updates within a few seconds of a submission on a normal connection; photos compressed before upload.

## 11. Success Metrics

- A supervisor can log a full day's attendance in under 2 minutes.
- A submitted incident appears on the manager dashboard in under 10 seconds (online).
- A manager can identify low-stock materials across all sites without opening more than two screens.
- Zero unauthorized reads or writes in Security Rules testing.

## 12. Assumptions, Risks and Open Questions

**Assumptions**
- Supervisors have Android phones; the company can provide devices if not.
- Attendance is recorded by the supervisor for a crew or worker list, not self-service by workers.

**Risks**
| Risk | Mitigation |
|---|---|
| Poor connectivity on site | Firestore offline persistence; test in airplane mode |
| Wrong data model discovered late | Get System Design approved before building screens |
| Supervisors find entry too slow | Sensible defaults, recent-value shortcuts, minimal required fields |
| Uneven contribution across the team | Named owner per milestone; daily standups |

**Open questions (for mentor and team)**
1. How much offline support is realistic to promise in 3 weeks?
2. Do managers and supervisors share one app with role-based views (current plan) or need separate experiences?
3. Should a worker be a tracked entity (own profile) or just a name on an attendance record?
4. What defines "expected headcount" for a site: a manager-set number per day, or a fixed roster?

## 13. Milestones

| Milestone | Scope |
|---|---|
| M1 | App shell, navigation, theme, Firebase connected |
| M2 | Auth, roles, site assignment |
| M3 | Sites and attendance CRUD |
| M4 | Materials and stock |
| M5 | Incidents with photos |
| M6 | Manager dashboard, real-time updates, filtering |
| M7 | Security Rules, offline behavior, polish |
| Final week | Feature freeze, device testing, README, showcase rehearsal |

## 14. Concept Mapping

- Foundations: Concepts 1-14
- Firebase config, auth, persistent login: Concepts 18-23, 37
- Firestore CRUD: Concepts 24-31
- Real-time updates: Concept 32
- Storage and image upload: Concepts 35-36
- Search and filtering: Concept 40

*Final concept selection to be confirmed with the mentor after PRD approval.*

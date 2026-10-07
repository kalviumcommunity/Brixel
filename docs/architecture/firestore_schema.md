# Cloud Firestore Database Architecture & Schema Specification

**Application:** Brixel (Cross-Platform Mobile Application)  
**Sprint:** Sprint 2 — Mobile App Development (Flutter + Firebase)  
**Track:** Kalvium Simulated Work  
**Concept Assignment:** 3.33 Firestore Database Structure  
**Document Status:** Approved Architecture Reference  

---

## 1. Architectural Overview & Design Philosophy

Brixel manages daily site operations (labor attendance, material tracking, and safety incidents) across multiple construction sites. 

In Cloud Firestore, data is organized into **Collections $\rightarrow$ Documents $\rightarrow$ Fields**. Firestore has no rigid schema enforcement by default; therefore, strict structural consistency, camelCase naming conventions, and disciplined data grouping are enforced in the application code via strongly-typed Dart models and Firestore Security Rules.

### Key Design Tenets
1. **Consistency Across Documents:** Every document within a collection shares the exact same field keys, casing, and data types to prevent fragile conditional parsing logic on Flutter screens.
2. **Read-Optimized Grouping:** Structure reflects screen queries. Data required for real-time dashboards (such as incident severities and attendance counts) are stored with root-level query keys (`siteId`, `date`, `severity`) to enable direct indexed queries without complex multi-document joins.
3. **Auditability & Ordering:** Every document includes `createdAt` and `updatedAt` server timestamps for precise chronological ordering on mobile feeds.
4. **Normalized Identifiers:** Standardized `camelCase` naming conventions are used throughout (e.g., `workerName`, `hoursWorked`, `recordedBy`, `siteId`), avoiding abbreviations (`cn`, `cust`, `desc_txt`).

---

## 2. Collection Hierarchy & Logical Grouping

```
Cloud Firestore Root
├── users/ (Collection)
│   └── {uid} (Document)
│
├── sites/ (Collection)
│   └── {siteId} (Document)
│
├── attendance/ (Collection)
│   └── {recordId} (Document)
│
├── materials/ (Collection)
│   └── {materialId} (Document)
│
├── material_transactions/ (Collection)
│   └── {txId} (Document)
│
└── incidents/ (Collection)
    └── {incidentId} (Document)
```

> **Design Choice: Root Collections with Foreign Key References (`siteId`)**  
> We adopted root-level collections linked via `siteId` (rather than deeply nested subcollections like `sites/{siteId}/attendance/{recordId}`) because:
> 1. Project Managers need cross-site visibility (e.g., "all critical incidents across all sites today" or "low-stock materials across all active projects"). Top-level collections allow single, indexed composite queries without requiring collection-group queries.
> 2. Supervisors only query data where `siteId in assignedSiteIds`, which is directly supported by Firestore indexed queries.

---

## 3. Data Dictionary & Document Schemas

### 3.1 Collection: `users`
Stores user profile information, authentication mapping, and assigned sites.

* **Document ID:** Firebase Auth UID (`auth.uid`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `uid` | `string` | Yes | Matching Firebase Auth UID |
  | `email` | `string` | Yes | User email address |
  | `displayName` | `string` | Yes | Full name of supervisor or project manager |
  | `role` | `string` | Yes | Enum: `'supervisor'` \| `'manager'` \| `'admin'` |
  | `assignedSiteIds` | `array<string>` | Yes | List of `siteId` strings assigned to this user |
  | `createdAt` | `timestamp` | Yes | Account creation timestamp |
  | `updatedAt` | `timestamp` | Yes | Last profile update timestamp |

**Sample Document (`users/usr_sup_101`):**
```json
{
  "uid": "usr_sup_101",
  "email": "meera.s@brixel.app",
  "displayName": "Meera Sundaram",
  "role": "supervisor",
  "assignedSiteIds": ["site_metro_line1", "site_tower_b"],
  "createdAt": "2026-10-07T08:00:00.000Z",
  "updatedAt": "2026-10-07T08:00:00.000Z"
}
```

---

### 3.2 Collection: `sites`
Stores construction project site metadata, expected headcount, and supervisor assignments.

* **Document ID:** Auto-generated or slug (`siteId`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `name` | `string` | Yes | Project site name |
  | `location` | `string` | Yes | Physical site location / address |
  | `status` | `string` | Yes | Enum: `'active'` \| `'on_hold'` \| `'completed'` |
  | `expectedHeadcount` | `number (integer)` | Yes | Target daily labor headcount for variance calculation |
  | `assignedSupervisorIds` | `array<string>` | Yes | Array of supervisor UIDs managing the site |
  | `createdAt` | `timestamp` | Yes | Site creation date |
  | `updatedAt` | `timestamp` | Yes | Last site update date |

**Sample Document (`sites/site_metro_line1`):**
```json
{
  "name": "Metro Line 1 - Station Pier 4",
  "location": "Madhapur, Hyderabad",
  "status": "active",
  "expectedHeadcount": 45,
  "assignedSupervisorIds": ["usr_sup_101"],
  "createdAt": "2026-10-01T04:30:00.000Z",
  "updatedAt": "2026-10-07T06:00:00.000Z"
}
```

---

### 3.3 Collection: `attendance`
Stores daily labor attendance records per worker/crew.

* **Document ID:** Auto-generated ID (`recordId`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `siteId` | `string` | Yes | Associated project site ID |
  | `workerName` | `string` | Yes | Worker name or crew identifier |
  | `trade` | `string` | Yes | Trade classification (e.g. Mason, Carpenter, Electrician) |
  | `status` | `string` | Yes | Enum: `'present'` \| `'absent'` \| `'half_day'` |
  | `hoursWorked` | `number (double)` | Yes | Number of hours logged (e.g., 8.0, 4.5) |
  | `date` | `string` | Yes | ISO format date string (`YYYY-MM-DD`) for indexed daily queries |
  | `recordedBy` | `string` | Yes | UID of supervisor who recorded attendance |
  | `createdAt` | `timestamp` | Yes | Exact time record was saved |
  | `updatedAt` | `timestamp` | Yes | Last modification timestamp |

**Sample Document (`attendance/att_20261007_001`):**
```json
{
  "siteId": "site_metro_line1",
  "workerName": "Ramesh Kumar (Mason Crew Alpha)",
  "trade": "Mason",
  "status": "present",
  "hoursWorked": 8.5,
  "date": "2026-10-07",
  "recordedBy": "usr_sup_101",
  "createdAt": "2026-10-07T06:15:00.000Z",
  "updatedAt": "2026-10-07T06:15:00.000Z"
}
```

---

### 3.4 Collection: `materials`
Maintains current stock levels and threshold alerts for on-site construction materials.

* **Document ID:** Auto-generated ID (`materialId`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `siteId` | `string` | Yes | Associated project site ID |
  | `materialName` | `string` | Yes | Name of material (e.g. OPC 53 Grade Cement, 12mm Rebar) |
  | `unit` | `string` | Yes | Unit of measurement (`'bags'`, `'metric_tons'`, `'meters'`) |
  | `currentStock` | `number (double)` | Yes | Real-time quantity on site |
  | `reorderThreshold` | `number (double)` | Yes | Minimum quantity before raising a low-stock alert |
  | `updatedAt` | `timestamp` | Yes | Last time stock was incremented/decremented |

**Sample Document (`materials/mat_cement_53`):**
```json
{
  "siteId": "site_metro_line1",
  "materialName": "OPC 53 Grade Cement",
  "unit": "bags",
  "currentStock": 85.0,
  "reorderThreshold": 100.0,
  "updatedAt": "2026-10-07T07:20:00.000Z"
}
```

---

### 3.5 Collection: `material_transactions`
Auditable transaction log capturing incoming delivery receipts and daily usage consumption.

* **Document ID:** Auto-generated ID (`txId`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `materialId` | `string` | Yes | Reference to document in `materials` collection |
  | `siteId` | `string` | Yes | Associated project site ID |
  | `type` | `string` | Yes | Enum: `'received'` \| `'used'` |
  | `quantity` | `number (double)` | Yes | Quantity added or deducted |
  | `notes` | `string` | No | Description of usage or supplier invoice number |
  | `recordedBy` | `string` | Yes | UID of supervisor recording the entry |
  | `timestamp` | `timestamp` | Yes | Time transaction occurred |

**Sample Document (`material_transactions/tx_20261007_01`):**
```json
{
  "materialId": "mat_cement_53",
  "siteId": "site_metro_line1",
  "type": "used",
  "quantity": 25.0,
  "notes": "Pier footing concrete pour phase 2",
  "recordedBy": "usr_sup_101",
  "timestamp": "2026-10-07T07:20:00.000Z"
}
```

---

### 3.6 Collection: `incidents`
Stores safety incident reports, severity ratings, attached photos, and resolution workflows.

* **Document ID:** Auto-generated ID (`incidentId`)
* **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `siteId` | `string` | Yes | Associated project site ID |
  | `incidentType` | `string` | Yes | Enum: `'injury'` \| `'near_miss'` \| `'equipment_failure'` \| `'hazard'` |
  | `severity` | `string` | Yes | Enum: `'low'` \| `'medium'` \| `'high'` \| `'critical'` |
  | `description` | `string` | Yes | Detailed description of the incident |
  | `photoUrl` | `string` | No | Cloud Storage download URL for incident photograph |
  | `status` | `string` | Yes | Enum: `'reported'` \| `'acknowledged'` \| `'resolved'` |
  | `reportedBy` | `string` | Yes | UID of supervisor submitting report |
  | `resolvedBy` | `string` | No | UID of manager who verified resolution |
  | `createdAt` | `timestamp` | Yes | Submission timestamp |
  | `resolvedAt` | `timestamp` | No | Timestamp when marked resolved |

**Sample Document (`incidents/inc_20261007_001`):**
```json
{
  "siteId": "site_metro_line1",
  "incidentType": "equipment_failure",
  "severity": "high",
  "description": "Hydraulic oil leakage detected on Crane #2 hydraulic arm.",
  "photoUrl": "https://firebasestorage.googleapis.com/v0/b/brixel-app.appspot.com/o/incidents%2Fcrane_leak.jpg",
  "status": "reported",
  "reportedBy": "usr_sup_101",
  "resolvedBy": null,
  "createdAt": "2026-10-07T07:45:00.000Z",
  "resolvedAt": null
}
```

---

## 4. Query Mapping: How Data Structure Directly Drives App Screens

| Screen / Feature | User Role | Query Definition | Supported by Structure |
| :--- | :---: | :--- | :--- |
| **Supervisor Home** | Supervisor | `sites.where('assignedSupervisorIds', arrayContains: uid)` | `assignedSupervisorIds` array indexed |
| **Daily Attendance Sheet** | Supervisor | `attendance.where('siteId', isEqualTo: siteId).where('date', isEqualTo: today)` | Composite index on `siteId` + `date` |
| **Headcount vs Expected** | Manager | Read site's `expectedHeadcount`, count docs where `date == today` & `status == 'present'` | Consistent integer and date fields |
| **Low-Stock Alert Feed** | Manager | `materials.where('siteId', isEqualTo: siteId)` filtered where `currentStock <= reorderThreshold` | Numeric fields with consistent units |
| **Urgent Incidents Feed** | Manager | `incidents.where('severity', in: ['high', 'critical']).where('status', isEqualTo: 'reported')` | Single collection indexed on severity & status |

---

## 5. Summary of Best Practices Applied

1. **Strict Type Safety:** Ensured integers vs doubles are appropriately typed (`hoursWorked`, `currentStock` use `double` / `num`).
2. **Server Timestamps:** Writes utilize `FieldValue.serverTimestamp()` to ensure phone clocks do not corrupt ordering.
3. **No Redundant Nesting:** Denormalized only essential site identifiers (`siteId`) to keep individual reads lightweight and writes independent.

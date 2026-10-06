# Wireframe Checklist

This folder is a planning guide for the mock UX. These are design/export tasks only. No fake screenshots are included here.

## Core Wireframes

### 1. Sign-In
Brief description:
- email or identifier field
- password field
- sign-in button
- loading state while verifying credentials
- authentication error state with retry option

### 2. Site Selection
Brief description:
- list of permitted or assigned sites
- clearly indicates the current site context
- loading state while site access is resolved
- empty state when the user has no approved site access
- error state when site permissions cannot load

### 3. Supervisor Dashboard
Brief description:
- selected site shown prominently
- navigation entries for Attendance, Material Usage, Safety Reporting, and Report History
- summary information relevant to the current site

### 4. Attendance Report
Brief description:
- reporting date
- expected workers
- present workers
- absent workers derived or displayed appropriately
- selected site visible throughout the form
- validation feedback before submission

### 5. Material Usage
Brief description:
- material name
- quantity used
- unit
- reporting date
- site context
- clearly framed as consumption, not stock or inventory

### 6. Safety Report
Brief description:
- description of issue or observation
- location within site
- occurrence date/time
- severity
- optional future photo support placeholder if the team wants to include it in a later UX revision

### 7. Report History
Brief description:
- report type
- site
- reporting date/time
- status or freshness information
- loading, empty, and error states

### 8. Manager Overview
Brief description:
- site name and project context
- categories shown for attendance, material, and safety
- date/time represented by each item
- record freshness and status such as current, loading, pending, missing, or failed
- explicit visual distinction between missing data and “no incidents reported”

## State Wireframes

### Loading
Brief description:
- skeleton or spinner pattern
- message such as “Loading attendance reports...”
- useful for site access, history, or report submission states

### Empty
Brief description:
- empty list or no-data panel
- message indicating no report exists for the current selection
- examples: no attendance for a date, no safety records, no assigned sites

### Error
Brief description:
- error panel or banner
- message explaining that the data could not be loaded or saved
- recovery action such as retry

### Pending
Brief description:
- in-progress state while waiting for a submit or refresh to complete
- message such as “Submitting report...”
- explicit difference from success and failure states

### Success / Content
Brief description:
- confirmation banner or saved record summary
- message such as “Attendance report submitted.”
- content view showing valid data available for review by the manager

## Recommended Export Notes

- Design each wireframe as a single screen in a consistent mobile layout.
- Keep the active site visible on all supervisor screens.
- Use strong status labels for freshness, loading, pending, and failed states.
- Do not include screenshots or mocked production data as if they were final implementation artifacts.
- Keep these layouts ready for later handoff to Flutter screen planning and validation work.

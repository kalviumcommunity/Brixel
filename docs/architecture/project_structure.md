# Brixel Flutter Project Structure

## Purpose

Brixel uses a feature-first Flutter project structure so that code belonging to the same product feature stays together.

This structure is intended to make the application easier for multiple teammates to understand, extend, review, and maintain as attendance reporting, material usage, safety reporting, authentication, and other approved functionality are implemented.

This document describes the initial folder boundaries only. It does not define all future implementation layers or database structures.

## Current Structure

```text
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── attendance/
│   ├── materials/
│   └── safety/
└── shared/
    └── widgets/
```

## `main.dart`

`main.dart` is the entry point of the Flutter application.

Its responsibility is to start the application and connect the top-level application configuration.

Feature-specific business logic should not be placed directly in `main.dart`.

## `features/`

The `features` directory contains code that belongs to a specific product capability.

### `features/auth/`

Contains authentication-related code when authentication implementation begins.

Examples may later include sign-in screens, authentication models, and authentication services, depending on the approved system design.

### `features/attendance/`

Contains code related to construction-site attendance reporting.

Attendance-specific screens, models, validation, services, or repositories should remain within this feature unless a component is genuinely shared by multiple features.

### `features/materials/`

Contains code related to recording material usage at construction sites.

This module represents material consumption reporting and should not be expanded into inventory or procurement functionality without an approved product requirement.

### `features/safety/`

Contains code related to safety incident or unsafe-condition reporting.

Future safety screens, models, and data-access code should remain inside this feature unless an approved architecture decision establishes otherwise.

## `core/`

The `core` directory contains application-wide technical code that is not owned by one particular product feature.

### `core/constants/`

For constants that are genuinely application-wide.

Feature-specific constants should remain inside their respective features.

### `core/theme/`

For shared Flutter theme configuration such as application-wide colors, typography, and theme definitions.

### `core/utils/`

For generic utility functions used across multiple parts of the application.

Utilities that only serve one feature should stay inside that feature.

## `shared/`

The `shared` directory contains reusable application components that are genuinely used by multiple features.

### `shared/widgets/`

For reusable Flutter widgets shared across multiple features.

A widget should not be moved here simply because it might become reusable in the future. Feature-specific widgets should stay inside their own feature until there is a real shared use case.

## Boundary Rules

1. Feature-specific code stays inside its feature.
2. `core` is reserved for application-wide technical concerns.
3. `shared` is reserved for components that are actually reused.
4. Feature folders should not depend directly on unrelated feature implementation details.
5. New architectural layers such as repositories, services, models, or state-management folders should be added when required by an approved task or system-design decision.
6. Firebase collection structures, security rules, and role permissions are not defined by this folder structure.
7. The folder structure may evolve through reviewed team decisions as the application grows.

## Why Feature-First?

A type-first project might place every screen in one `screens` folder, every model in one `models` folder, and every service in one `services` folder.

As Brixel grows, that would scatter the files for one feature across many unrelated directories.

With feature-first organization, attendance-related code can remain together:

```text
features/
└── attendance/
    ├── screens/
    ├── models/
    ├── services/
    └── repositories/
```

These subdirectories are examples of how the feature may evolve. They should be created only when their corresponding implementation work begins.

This keeps ownership and code relationships clearer while avoiding unnecessary empty architecture.
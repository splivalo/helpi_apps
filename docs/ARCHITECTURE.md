# Helpi App - Architecture

> Last updated: 2026-04-24

## Overview

Single Flutter app serving both Customer (Senior) and Student roles with role-based navigation after authentication.

## Tech Stack

- Flutter + Dart
- Dio for REST communication
- FlutterSecureStorage for JWT/session persistence
- Riverpod for state management
- SignalR for real-time events
- `AppStrings` for localization

## Core Structure

```text
lib/
  app/
    app.dart
    senior_shell.dart
    student_shell.dart
    theme.dart
  core/
    constants/
    l10n/
    models/
    network/
    providers/
    services/
    utils/
    widgets/
  features/
    auth/
    chat/
    notifications/
    orders/
    profile/
    ratings/
    schedule/
```

## Key Design Decisions

- API-first data model with controlled local fallback for resilience.
- Role-based shell separation with shared core services.
- Real-time update orchestration through provider-based sync handlers.
- Suspension handling centralized through API interceptor + dedicated screen.
- Keep backend as source of truth for assignment, payment, and schedule logic.

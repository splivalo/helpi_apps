# Helpi App - Progress

> Last updated: 2026-05-13

## Current Status

- App type: Unified Customer + Student app
- Scope: Backend-connected, API-first with fallback cache where needed
- Files: 64 Dart files
- Quality: `flutter analyze` clean
- State management: Riverpod
- Real-time: SignalR

## Implemented Modules

- Authentication and role-based shell routing
- Customer order flow and order details
- Student schedule and job details
- Profile management for both roles
- Reviews and rating flow
- Notifications screen with backend data
- Chat integration with backend and unread count
- Localization support (HR/EN)

## 2026-05-13 - Student Availability Refresh

- ✅ **Availability not syncing from admin**: `ProfileAvailabilityScreen` now calls `_refreshFromBackend()` in `initState` to fetch fresh availability from backend (`GET /api/student-availability-slots/student/{id}`) — ensures admin changes are immediately visible without app restart
- ✅ **LinearProgressIndicator** added during refresh for user feedback
- ✅ **0 errors → 0 errors maintained**

## 2026-04-24 Update

- Lat/Lng profile edit bug fixed in both customer and student profile flows.
- Address edit now uses address picker pattern and sends coordinates to backend update API.
- Registration coordinate validation corrected.

## Remaining Work (Cross-Repo)

- External provider credentials and production wiring (Stripe, Firebase, Mailgun, MailerLite, Minimax)
- Push-notification production setup (depends on Firebase credentials)

Source of truth for pending work: [../../admin/helpi_admin/docs/ROADMAP.md](../../admin/helpi_admin/docs/ROADMAP.md)

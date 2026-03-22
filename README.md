# Helpi App — Unified Customer & Student Flutter App

Merged Flutter app (Customer [Senior] + Student) — 64 .dart files, 0 errors.

## 📖 Za Sidney-a — Što čitati (sva 3 repoa)

| GitHub repo (splivalo/) | Fajl                      | Sadržaj                                          |
| ----------------------- | ------------------------- | ------------------------------------------------ |
| **helpi_administrator** | **docs/ROADMAP.md**       | **Svi preostali TODO-ovi (START HERE)**          |
| helpi_administrator     | docs/PROGRESS.md          | Admin app status (98% frontend done)             |
| helpi_administrator     | docs/ARCHITECTURE.md      | Admin tech stack, folder structure, UI standardi |
| helpi_administrator     | docs/PROJECT_HISTORY.md   | Kronologija odluka (Feb→Mart 2026)               |
| helpi_backend_v2        | docs/PROGRESS.md          | Backend task tracking (16 taskova ✅)            |
| helpi_backend_v2        | README.md                 | DB schema, use case flows, 19 LINQ queries       |
| helpi_backend_v2        | seeds/README.md           | Test data, login credentials, promo codes        |
| **helpi_apps**          | **README.md (ovaj fajl)** | App tech stack, Riverpod/SignalR info            |
| helpi_apps              | docs/ARCHITECTURE.md      | Folder structure, 64 fajlova, providers          |

---

## Tech Stack

- Flutter 3.x, Dio 5.x, JWT (FlutterSecureStorage)
- State: **Riverpod** (flutter_riverpod ^2.6.1)
- Real-time: **SignalR** (signalr_netcore ^1.4.4) → `/hubs/notifications`
- i18n: AppStrings (HR/EN, Gemini Hybrid pattern)
- Assets: SVG (flutter_svg)

## Quick Start

```bash
flutter pub get
flutter run
```

## Key Architecture

- **Role-based routing:** Login detects `userType` from JWT → SeniorShell or StudentShell
- **4 Riverpod providers:** auth, signalr, realtime_sync, jobs (under `lib/core/providers/`)
- **SignalR auto-connect:** Connects on login, disconnects on logout, exponential backoff reconnect
- **Suspension handling:** ApiClient 403 interceptor → suspended_screen.dart

## Backend

- ASP.NET Core 8, PostgreSQL 18 + PostGIS
- Local: `localhost:5142`, Swagger: `http://localhost:5142/swagger`
- SignalR hub: `/hubs/notifications` (JWT auth required)

## Documentation

- [docs/PROGRESS.md](docs/PROGRESS.md) — Status & checklist (64/64 files done)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Tech stack & folder structure
- [docs/PROJECT_HISTORY.md](docs/PROJECT_HISTORY.md) — Key decisions & changelog

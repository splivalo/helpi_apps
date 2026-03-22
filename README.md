# Helpi App — Unified Customer & Student Flutter App

Merged Flutter app (Customer [Senior] + Student) — 64 .dart files, 0 errors.

## 📖 Za Sidney-a — Što čitati (sva 3 repoa)

| Repo            | Fajl                      | Sadržaj                                          |
| --------------- | ------------------------- | ------------------------------------------------ |
| **helpi_admin** | **docs/ROADMAP.md**       | **Svi preostali TODO-ovi (START HERE)**          |
| helpi_admin     | docs/PROGRESS.md          | Admin app status (98% frontend done)             |
| helpi_admin     | docs/ARCHITECTURE.md      | Admin tech stack, folder structure, UI standardi |
| helpi_admin     | docs/PROJECT_HISTORY.md   | Kronologija odluka (Feb→Mart 2026)               |
| helpi_backend   | PROGRESS.md               | Backend task tracking (16 taskova ✅)            |
| helpi_backend   | README.md                 | DB schema, use case flows, 19 LINQ queries       |
| helpi_backend   | seeds/README.md           | Test data, login credentials, promo codes        |
| **helpi_app**   | **README.md (ovaj fajl)** | App tech stack, Riverpod/SignalR info            |
| helpi_app       | ARCHITECTURE.md           | Folder structure, 64 fajlova, providers          |

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

- [PROGRESS.md](PROGRESS.md) — Status & checklist (64/64 files done)
- [ARCHITECTURE.md](ARCHITECTURE.md) — Tech stack & folder structure
- [PROJECT_HISTORY.md](PROJECT_HISTORY.md) — Key decisions & changelog

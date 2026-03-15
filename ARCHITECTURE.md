# Helpi App — Arhitektura

> Unified Flutter app za **Customer (Senior)** i **Student** ulogu.  
> Zamjenjuje prethodne `helpi_senior` i `helpi_student` aplikacije.

## Zašto 1 app?

- Isti UI identity (boje, tipografija, kartice, gumbi)
- Isti backend (ASP.NET Core, isti auth endpoint)
- Login automatski prepoznaje ulogu po emailu (`userType` u JWT)
- Registracija koristi role picker ("Tražim pomoć" / "Želim pomagati")
- Smanjuje maintenance — 1 codebase umjesto 2

## Tech Stack

| Sloj      | Tehnologija                               |
| --------- | ----------------------------------------- |
| Framework | Flutter 3.x                               |
| HTTP      | Dio 5.x                                   |
| Auth      | JWT (FlutterSecureStorage)                |
| State     | ValueNotifier / setState                  |
| i18n      | AppStrings (HR/EN, Gemini Hybrid pattern) |
| Assets    | SVG (flutter_svg)                         |

## Direktorij Struktura

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # Root widget, role-based routing
│   ├── theme.dart                     # HelpiTheme (Material 3)
│   ├── senior_shell.dart              # Customer: 4 taba (Naruči, Narudžbe, Poruke, Profil)
│   └── student_shell.dart             # Student: 4 taba (Raspored, Poruke, Statistika, Profil)
├── core/
│   ├── constants/
│   │   ├── colors.dart                # AppColors (coral, teal, neutrals)
│   │   └── pricing.dart               # AppPricing (hourlyRate, sundayRate)
│   ├── l10n/
│   │   ├── app_strings.dart           # i18n (HR+EN, ~1000+ ključeva)
│   │   └── locale_notifier.dart       # ValueNotifier<Locale>
│   ├── network/
│   │   ├── api_client.dart            # Dio wrapper s JWT interceptorom
│   │   ├── api_endpoints.dart         # Svi API putevi
│   │   └── token_storage.dart         # FlutterSecureStorage (token, userId, userType)
│   ├── services/
│   │   └── auth_service.dart          # Login, logout, register, forgot/reset password
│   └── utils/
│       ├── formatters.dart            # AppFormatters (datum formatiranje)
│       └── snackbar_helper.dart       # showHelpiSnackBar
├── features/
│   ├── auth/presentation/
│   │   └── login_screen.dart          # Zajednički login + registracija s role pickerom
│   ├── booking/                       # === CUSTOMER ONLY ===
│   │   ├── data/
│   │   │   └── order_model.dart       # OrderModel, OrdersNotifier, JobModel, ReviewModel
│   │   └── presentation/
│   │       ├── order_screen.dart       # Nova narudžba
│   │       ├── order_flow_screen.dart  # Kreiranje narudžbe (multi-step)
│   │       ├── orders_screen.dart      # Lista narudžbi (3 taba)
│   │       └── order_detail_screen.dart # Detalji narudžbe + recenzije
│   ├── schedule/                      # === STUDENT ONLY ===
│   │   ├── data/
│   │   │   ├── job_model.dart          # Job, JobStatus, ServiceType, MockJobs
│   │   │   ├── review_model.dart       # ReviewModel (student verzija)
│   │   │   └── availability_model.dart # DayAvailability, AvailabilityNotifier
│   │   ├── presentation/
│   │   │   ├── schedule_screen.dart    # Tjedni raspored
│   │   │   └── job_detail_screen.dart  # Detalji posla + review/decline
│   │   ├── widgets/
│   │   │   ├── availability_day_row.dart
│   │   │   ├── faculty_picker.dart
│   │   │   ├── helpi_card.dart
│   │   │   ├── job_status_badge.dart
│   │   │   ├── review_card.dart
│   │   │   ├── star_rating.dart
│   │   │   └── time_slot_picker.dart
│   │   └── utils/
│   │       ├── job_helpers.dart
│   │       ├── formatters.dart
│   │       └── availability_helpers.dart
│   ├── chat/presentation/
│   │   ├── senior_chat_list_screen.dart # Customer chat
│   │   └── student_chat_screen.dart     # Student chat
│   ├── profile/presentation/
│   │   ├── senior_profile_screen.dart   # Customer profil
│   │   └── student_profile_screen.dart  # Student profil (+ dostupnost)
│   ├── statistics/presentation/
│   │   └── statistics_screen.dart       # Student statistika (weekly/monthly)
│   └── onboarding/presentation/
│       ├── registration_data_screen.dart # Student registracija (osobni podaci)
│       └── onboarding_screen.dart        # Student onboarding (dostupnost)
└── shared/
    ├── models/
    │   └── faculty.dart                  # 31 fakultet (Sveučilište u Zagrebu)
    └── widgets/                          # Zajednički widgeti za obje uloge
        ├── helpi_form_fields.dart
        ├── helpi_switch.dart
        ├── info_card.dart
        ├── selectable_chip.dart
        ├── service_chips_wrap.dart
        ├── star_rating.dart
        ├── summary_row.dart
        ├── review_inline_card.dart
        ├── tab_bar_selector.dart
        ├── job_status_badge.dart
        └── status_chip.dart
```

## Auth Flow

```
                    ┌──────────────┐
                    │  LoginScreen │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │ Login      │ Register   │
              ▼            ▼            │
        POST /api/auth/login    Role Picker
              │            ┌─────┴─────┐
              │            │           │
              ▼            ▼           ▼
        userType?    "Tražim pomoć"  "Želim pomagati"
        ┌───┴───┐      │              │
        │       │      ▼              ▼
    Customer  Student  Profil forma   RegistrationData
        │       │      │              │
        ▼       ▼      ▼              ▼
   SeniorShell  │   SeniorShell   OnboardingScreen
                │                     │
                ▼                     ▼
           StudentShell          StudentShell
```

## Backend API (relevant endpoints)

| Endpoint                           | Opis                                |
| ---------------------------------- | ----------------------------------- |
| `POST /api/auth/login`             | Vraća `{ token, userId, userType }` |
| `POST /api/auth/register/customer` | Registrira naručitelja              |
| `POST /api/auth/register/student`  | Registrira studenta                 |
| `POST /api/auth/forgot-password`   | Šalje reset kod                     |
| `POST /api/auth/reset-password`    | Resetira lozinku                    |
| `POST /api/auth/change-password`   | Mijenja lozinku (autorizirano)      |
| `GET /api/orders?status=`          | Lista narudžbi (Customer)           |

## Napomene o Class Naming

- **Senior app's** `JobStatus` enum živi u `features/booking/data/order_model.dart`
- **Student app's** `JobStatus` enum živi u `features/schedule/data/job_model.dart`
- Isti naziv, različiti fajlovi — NEMA konflikta jer nijedan fajl ne importa oba
- Ako ikad treba oba u istom fajlu, koristi Dart import prefix: `import '...' as senior;`

## 55 Dart fajlova | 0 analyze errora

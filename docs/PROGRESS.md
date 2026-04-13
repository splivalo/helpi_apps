# Helpi App — Progress

> Merged Flutter app (Customer + Student) — zamjenjuje `helpi_senior` + `helpi_student`

## Status: Backend-Connected App (API-first + fallback cache)

**Datum:** 12.04.2026.  
**Analyze:** 0 errors, 0 warnings  
**Fajlovi:** 64 .dart files  
**State mgmt:** Riverpod (flutter_riverpod ^2.6.1)  
**Real-time:** SignalR (signalr_netcore ^1.4.4)  
**API pokrivanje:** ~98% real API (auth, orders, sessions, reviews, pricing, dashboard, notifications, availability, chat)  
**Izuzeci:** Stripe (dummy kartice — čeka integraciju), push notifikacije (čeka Firebase setup)

---

## ⚠️ For developer — Firebase / Push notifications

When implementing Firebase Messaging (`firebase_messaging` + `flutter_local_notifications`):

- **Review notification** (type `reviewRequest`, arrives 10 min after session completion):
  - Tap should navigate to `OrderDetailScreen` (senior) or `JobDetailScreen` (student)
  - The coral "Rate" button is already there — **NO separate modal needed**
  - Payload must contain `orderId` / `jobInstanceId` for navigation
- **TODO comments** in code: `main.dart`, `notifications_screen.dart` — grep for `TODO(firebase)`

---

## Checklist

### Core Layer (10/10) — 100%

- [x] colors.dart — AppColors (coral, teal, neutrals)
- [x] pricing.dart — AppPricing (hourlyRate, sundayRate)
- [x] theme.dart — HelpiTheme (Material 3 + color aliases)
- [x] token_storage.dart — FlutterSecureStorage (JWT, userId, userType)
- [x] api_endpoints.dart — svi API putevi (merged)
- [x] api_client.dart — Dio wrapper s JWT interceptorom
- [x] auth_service.dart — login, logout, register, forgot/reset password
- [x] app_strings.dart — i18n HR+EN (~1000+ ključeva, merged)
- [x] locale_notifier.dart — ValueNotifier<Locale>
- [x] formatters.dart — AppFormatters

### Shared Widgets (11/11) — 100%

- [x] helpi_form_fields.dart
- [x] helpi_switch.dart
- [x] info_card.dart
- [x] selectable_chip.dart
- [x] service_chips_wrap.dart
- [x] star_rating.dart
- [x] summary_row.dart
- [x] review_inline_card.dart
- [x] tab_bar_selector.dart
- [x] job_status_badge.dart
- [x] status_chip.dart

### Data Models (5/5) — 100%

- [x] order_model.dart — OrderModel, OrdersNotifier, JobModel, ReviewModel (Customer)
- [x] job_model.dart — Job, JobStatus, ServiceType, JobsCache (Student)
- [x] review_model.dart — ReviewModel (Student)
- [x] availability_model.dart — DayAvailability, AvailabilityNotifier
- [x] faculty.dart — 31 fakultetа (Zagreb)

### Feature Screens (14/14) — 100%

- [x] login_screen.dart — zajednički login + registracija s role pickerom
- [x] order_screen.dart — nova narudžba (Customer)
- [x] order_flow_screen.dart — kreiranje narudžbe (Customer)
- [x] orders_screen.dart — lista narudžbi, 3 taba (Customer)
- [x] order_detail_screen.dart — detalji narudžbe + recenzije (Customer)
- [x] schedule_screen.dart — tjedni raspored (Student)
- [x] job_detail_screen.dart — detalji posla + review/decline (Student)
- [x] senior_chat_list_screen.dart — chat (Customer) — DirectChatScreen wrapper, real API
- [x] student_chat_screen.dart — chat (Student) — DirectChatScreen wrapper, real API
- [x] senior_profile_screen.dart — profil (Customer)
- [x] student_profile_screen.dart — profil + dostupnost (Student)
- [x] statistics_screen.dart — statistika (Student)
- [x] registration_data_screen.dart — registracija podataka (Student)
- [x] onboarding_screen.dart — postavljanje dostupnosti (Student)

### Navigation & App Shell (4/4) — 100%

- [x] app.dart — root widget, role-based routing (**ConsumerStatefulWidget**, Riverpod)
- [x] senior_shell.dart — 4 taba (Naruči, Narudžbe, Poruke, Profil) — ConsumerStatefulWidget, unread badge
- [x] student_shell.dart — 4 taba (Raspored, Poruke, Statistika, Profil) — ConsumerStatefulWidget, unread badge
- [x] main.dart — entry point (**ProviderScope** wrapper)

### Student-Specific Widgets (7/7) — 100%

- [x] availability_day_row.dart
- [x] faculty_picker.dart
- [x] helpi_card.dart
- [x] job_status_badge.dart (student verzija)
- [x] review_card.dart
- [x] star_rating.dart (student verzija)
- [x] time_slot_picker.dart

### Student Utils (3/3) — 100%

- [x] job_helpers.dart
- [x] formatters.dart (student verzija)
- [x] availability_helpers.dart

### Riverpod Providers (4/4) — 100% (dodano 2026-03-22)

- [x] auth_provider.dart — AuthState + AuthNotifier (StateNotifier), zamjenjuje sve setState iz app.dart
- [x] signalr_provider.dart — SignalRService, WebSocket na `/hubs/notifications`, JWT auth, auto-reconnect
- [x] realtime_sync_provider.dart — Bridža SignalR evente na data refresh (orders/jobs)
- [x] jobs_provider.dart — JobsState + JobsNotifier (StateNotifier) za student raspored + statistiku

### Suspension (1/1) — 100% (dodano 2026-03-22)

- [x] suspended_screen.dart — Ekran za suspendirane korisnike (razlog + kontakt + delete account)

### Additional Services (2/2) — 100%

- [x] data_loader.dart — Data loading service
- [x] app_api_service.dart — App API service

### Additional Shared (2/2) — 100%

- [x] mc_address_field.dart — Address field widget
- [x] selected_address_info.dart — Address info model

---

## Ukupno: 64/64 fajlova — 100% frontend UI + real-time

### Verzija (2026-03-22)

- [x] App version → 2.0.0 (pubspec.yaml: 2.0.0+1)
- [x] AppStrings `appVersion` → "Helpi v2.0.0" (HR + EN)

---

## API Integration Status (ažurirano 2026-04-04)

### Chat (NEW 2026-04-12) — real API

- [x] direct_chat_screen.dart — DirectChatScreen (no room list, opens Helpi convo directly)
- [x] chat_models.dart — ChatRoom, ChatMessage models (fromJson, isMine, timeFormatted)
- [x] chat_api_service.dart — ChatApiService (getRooms, getMessages, sendMessage, markAsRead, getUnreadCount)
- [x] chat_provider.dart — chatRoomsProvider, chatMessagesProvider, chatUnreadCountProvider
- [x] Unread badge na bottom nav (oba shell-a)
- [x] Badge se čisti odmah na tab tap
- [x] Sender name ("Helpi") prikazan na primljenim porukama
- [x] WhatsApp-style shrink-wrap bubbles (Row+Flexible)

### Spojeno na backend ✅

- [x] Auth (login, register, forgot/reset password) → pravi API
- [x] Customer orders (CRUD, cancel) → pravi API
- [x] Session cancel iz order_detail_screen → pravi API (popravljeno 2026-04-04)
- [x] Student sessions (load, cancel) → pravi API
- [x] Reviews (bidirectional, pending) → pravi API
- [x] Notifications (SignalR real-time + REST) → pravi API
- [x] Pricing configuration (backend-driven) → pravi API
- [x] Dashboard tiles → pravi API
- [x] Student availability → pravi API
- [x] Student profile → pravi API
- [x] Senior profile → pravi API
- [x] Onboarding/registration → pravi API
- [x] Service categories → pravi API (s fallback)
- [x] Cities → pravi API
- [x] SignalR real-time sync → pravi API
- [x] DataLoader → API-first s cache fallback (MockJobs → JobsCache rename)

### Čeka backend implementaciju ❌

- [ ] Push notifikacije (Firebase FCM — backend ima endpoint, nema setup)
- [ ] Stripe plaćanje (dummy kartice dok se ne integrira pravi Stripe)

### Očišćeno 2026-04-04

- [x] `MockJobs` preimenovan u `JobsCache` (nije bio mock, nego API cache)
- [x] Svi stale "mock" komentari uklonjeni iz koda
- [x] `order_detail_screen.dart` session cancel sada poziva backend API

---

## 2026-04-01 — Realtime refresh refinement

- [x] `realtime_sync_provider.dart` više ne refresha slijepo na svaku SignalR notifikaciju
- [x] Dodano tolerantno parsiranje `ReceiveNotification` payloada za `String` i `Map`
- [x] Refresh ostaje aktivan za state-changing tipove poput `jobRescheduled`, `jobCancelled`, `orderCancelled`, `reassignmentStarted` i `reassignmentCompleted`
- [x] `SystemNotification` i dalje radi full fallback refresh
- [x] Verifikacija: `flutter analyze` = 0 issues

## 2026-04-01 — Order flow lokalni fallback za kartice

- [x] `order_flow_screen.dart` sada pokaže 2 lokalne fallback kartice kad backend vrati praznu listu ili ne uspije dohvat payment methods
- [x] Gumb `Dodaj karticu` u order flowu prvo pokušava spremiti dummy karticu preko postojećeg backend `payment-methods` endpointa, a tek na backend grešci pada na lokalnu fallback karticu
- [x] `senior_profile_screen.dart` sada koristi backend `createPaymentMethod` i `deletePaymentMethod` za dummy test kartice, bez Stripe paywall flowa
- [x] Slanje narudžbe i dalje ne šalje `paymentMethodId` za fallback ili backend-persisted test kartice bez `processorToken`, pa testni flow ne glumi stvarni Stripe charge
- [x] `order_flow_screen.dart` sada pokušava razriješiti service ID-jeve preko backend `service-categories` endpointa, uz fallback na postojeće lokalne ID mappinge ako backend ne vrati podatke
- [x] Verifikacija: `flutter analyze` = 0 issues

## 2026-04-01 — Notifications UI wiring

- [x] Dodan backend-driven `NotificationsScreen` s tabovima `Nepročitane` i `Sve`, pull-to-refresh i `Označi sve pročitanim`
- [x] Notifications screen je dostupan iz customer i student profile app bara
- [x] Verifikacija: `flutter analyze` = 0 issues

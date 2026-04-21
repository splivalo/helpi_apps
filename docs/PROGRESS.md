# Helpi App — Progress

> Merged Flutter app (Customer + Student) — zamjenjuje `helpi_senior` + `helpi_student`

## Status: Backend-Connected App (API-first + fallback cache)

**Datum:** 15.04.2026.  
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

---

## 2026-04-13 — Terms of Use screen (native HTML)

- [x] `terms_screen.dart` — renderira HTML s helpi.social koristeći `flutter_widget_from_html_core` (ne WebView)
- [x] Custom styles: teal linkovi, smanjen font za tablice/headinge, bez rednih brojeva u listama
- [x] Teal cursor boja u light i dark temi (`textSelectionTheme`)
- [x] Chat screen keyboard dismiss (`GestureDetector` wrapper)

---

## 2026-04-14 — Live session status chips + disabled buttons

- [x] `shared/widgets/job_status_badge.dart` — REWRITE: `StatefulWidget` s `Timer`, auto-transition Predstojeći→Aktivan→Završen po vremenu
- [x] `features/schedule/widgets/job_status_badge.dart` — isto za student raspored badge
- [x] Oba badgea koriste `WidgetsBindingObserver` — kad app dođe u foreground, re-evaluira status (fix za Android Timer sleep bug)
- [x] `order_detail_screen.dart` — cancel gumb disabled kad je sesija aktivna (onPressed: null)
- [x] `schedule/utils/job_helpers.dart` — dodan `activeLabel` getter

---

## 2026-04-15 — Bulletproof review flow (ensure-completed)

### Problem

Kad Hangfire još nije markirao sesiju kao completed (ali vrijeme je prošlo), frontend nije mogao pronaći pending review → "Pošalji ocjenu" nije radio.

### Rješenje — 3-step fallback

1. **Local cache** — check `_pendingReviews` lista
2. **Re-fetch** — pozovi `getPendingReviewsBySenior` ponovo (Hangfire možda već odradio)
3. **Ensure-completed** — pozovi `POST /api/sessions/{id}/ensure-completed` → backend kreira sesiju + reviews → re-fetch

### Backend

- `EnsureCompletedAsync(int jobInstanceId)` u `JobInstanceService.cs` — idempotent endpoint
- Ako session već completed ali reviews ne postoje (obrisani/missing) → ponovo ih kreira
- Guards: validira `now > endUtc`, status mora biti Upcoming/InProgress (ili Completed za re-create), mora imati assignment

### Frontend

- `_resolvePendingReviewId(int? jobInstanceId)` — 3-step fallback metoda
- `_isSessionDone(job)` — true ako backend kaže completed ILI ako je vrijeme prošlo (time-based)
- `effectivelyCompleted` zamjenjuje `isCompleted` u UI-ju (pokazuje review gumb i na time-based Done)
- Review submit: direktna mutacija `job.review = submittedReview` + `Navigator.pop` + `setState` → instant UI update
- `ensureSessionCompleted(int sessionId)` API metoda + endpoint u `api_endpoints.dart`

### i18n

- `jobActive` (HR: "Aktivan", EN: "Active")
- `reviewNotReady` (HR: "Termin se još obrađuje, pokušajte za minutu.", EN: "Session is still being processed...")
- `reviewTitle` (HR: "Recenzija", EN: "Review")
- `jobSectionSingular` (HR: "Termin", EN: "Session")

---

## 2026-04-15 — Review UX polish

- [x] Review gumb promijenjen iz coral `ElevatedButton` u teal `OutlinedButton` (visina 30, desno poravnanje sa Spacer)
- [x] `ReviewInlineCard` — tap otvara `AlertDialog` s punim komentarom (za dugačke reviewove koji su skraćeni s ellipsis)

---

## 2026-04-15 — Jednokratne narudžbe unificirane s ponavljajućim

### Prije

- Jednokratne completed narudžbe imale posebnu karticu `_studentReviewCard` (student + review)
- Ponavljajuće koristile `_jobsSection` s popisom termina

### Poslije

- `_studentReviewCard` **OBRISAN** — dead code
- Sve narudžbe (jednokratne i ponavljajuće) koriste `_jobsSection`
- Jednokratne: naslov "Termin" (singular), po defaultu **expandirane** (`_jobsExpanded = widget.order.isOneTime`)
- Ponavljajuće: naslov "Termini" (plural), po defaultu collapsed

---

## 2026-04-18 — PromoCode→Coupon sustav ujedinjenje

### Problem

Backend imao **dva odvojena** sustava popusta: PromoCode (% ili fiksni, per-order) i Coupon (sat-based s balanceom, per-assignment). Redundantno i zbunjujuće.

### Rješenje — jedan Coupon sustav

**Backend:**

- Obrisano 8 PromoCode fajlova (entity, DTO, service, repo, controller, interface)
- `Order.PromoCodeId` → `Order.CouponId` + `Order.Coupon` nav property
- `CouponType` enum proširen: MonthlyHours, WeeklyHours, OneTimeHours, **Percentage**, **FixedPerSession**
- Novi endpointi: `POST /api/coupons/validate` + `POST /api/coupons/apply`
- DB migracija: `20260418073312_RemovePromoCodeSystem` (dropane PromoCodes+PromoCodeUsages tablice)
- `dotnet build` = 0 errors

**Admin frontend (helpi_admin):**

- API endpointi: promo-codes/_ → coupons/_
- `OrderModel.promoCode` → `couponCode`
- AppStrings: promo stringovi uklonjeni (postojeći coupon stringovi dovoljni)
- `flutter analyze` = 0 issues

**Mobile app (helpi_app):**

- `OrderModel.promoCode` → `couponCode`
- `_promoCodeController` → `_couponCodeController`, `_promoValidating` → `_couponValidating`, `_promoError` → `_couponError`
- AppStrings: `promoCode*` → `couponCode*` (HR+EN map + getteri)
- API endpointi već bili na `/api/coupons/redeem` — nema promjene
- `flutter analyze` = 0 issues

---

## 2026-04-19 — Student assignment acceptance + cancel/availability toggles

### Nove admin postavke

**Backend (PricingConfiguration):**

- `StudentCancelEnabled` (bool, default true) — ON/OFF za studentsko otkazivanje sesija
- `AvailabilityChangeEnabled` (bool, default true) — ON/OFF za promjenu dostupnosti
- `AvailabilityChangeCutoffHours` (int, default 24) — koliko sati prije sesije student može promijeniti dostupnost
- DB migracija: `20260418210332_AddStudentSettingsAndPendingAcceptance`
- `dotnet build` = 0 errors, 0 warnings

**Admin (settings_screen.dart):**

- 2 nove sekcije: "Otkazivanje sesije" (toggle + cutoff sati) i "Promjena dostupnosti" (toggle + cutoff sati)
- `_toggleRow` widget helper (Switch.adaptive)
- `flutter analyze` = 0 issues

### Student mora prihvatiti narudžbu (force overlay)

**Backend (ScheduleAssignmentService):**

- `AssignmentStatus.PendingAcceptance` — novi enum (assignment čeka odgovor studenta)
- `AdminDirectAssignAsync` sada kreira assignment kao `PendingAcceptance` (ne `Accepted`)
- JobInstances se NE generiraju dok student ne prihvati
- Ako admin reassigna drugog studenta → prethodni dobije `AssignmentRevoked` SignalR notifikaciju
- Novi endpointi: `POST /{id}/accept`, `POST /{id}/decline`, `GET /pending` (Student role)
- `AcceptAssignmentAsync` — prihvaća, generira JobInstances, notificira admine
- `DeclineAssignmentAsync` — odbija, notificira admine
- `NotificationType`: dodano `AssignmentPending(33)`, `AssignmentAccepted(34)`, `AssignmentDeclined(35)`, `AssignmentRevoked(36)`

**App (helpi_app):**

- `pending_assignments_provider.dart` — PendingAssignment model + PendingAssignmentsNotifier (load/accept/decline)
- `pending_assignment_overlay.dart` — fullscreen force dialog (barrierDismissible: false) s detaljima narudžbe + Accept/Decline gumbi
- `student_shell.dart` — na otvaranju app učitava pending assignments, prikazuje overlay, nakon accept/decline prikazuje sljedeći pending
- `realtime_sync_provider.dart` — SignalR listener za `AssignmentPending` (type 33) i `AssignmentRevoked` (type 36) → auto-reload pending liste
- 18 novih AppStrings (HR + EN)

### Cancel/Availability enforcement na app strani

- `pricing.dart` — dodano `studentCancelEnabled`, `availabilityChangeEnabled`, `availabilityChangeCutoffHours` (učitavaju se iz API)
- `job_model.dart` — `canDecline` sada prvo provjerava `AppPricing.studentCancelEnabled`
- `profile_availability_screen.dart` — `_save()` provjerava `AppPricing.availabilityChangeEnabled` prije spremanja
- 2 nova AppStrings: `cancelDisabled`, `availabilityChangeDisabled` (HR + EN)
- `flutter analyze` = 0 issues

---

## 2026-04-20 — Student settings permissions, PendingAcceptance potvrda posla, canCancel, session filtering, UI polish, dead code cleanup, SignalR instant refresh

### Student settings — dozvole iz PricingConfiguration

- `AppPricing.studentCancelEnabled` — boolean loaded iz backendbendi; ako `false`, student ne može otkazati nijedan termin
- `AppPricing.availabilityChangeEnabled` — boolean; ako `false`, student ne može mijenjati raspored dostupnosti
- `AppPricing.availabilityChangeCutoffHours` — cutoff u satima; student ne smije mijenjati dostupnost unutar tog roka
- `pricing.dart` — `updateFromConfig()` parsira oba nova boolean polja iz `GET /api/PricingConfiguration`
- `profile_availability_screen.dart` — provjerava `AppPricing.availabilityChangeEnabled` i cutoff prije dozvole promjene; prikazuje locked banner ako nije omogućeno
- `job_model.dart` — `canCancelByStudent()` preferira backend-computed `canCancel` polje nad lokalnom logikom; lokalna logika pada nazad na `AppPricing.studentCancelEnabled`
- `app_api_service.dart` — parsira `canCancel: bool?` iz SessionDto JSON-a

### Student — PendingAcceptance potvrda posla (višestruki modali)

- `AssignmentStatus.PendingAcceptance` — novi backend status: dodjela čeka potvrdu studenta
- `PendingAssignment` model + `PendingAssignmentsNotifier` (`StateNotifier`) — prati popis dodjela na čekanju
- `pending_assignments_provider.dart` — `load()` poziva `GET /api/schedule-assignments/pending`, parsira assignmentId + orderId + seniorName + address + scheduleItems (raspored po danima)
- `student_shell.dart` — u `initState` poziva `_loadPendingAssignments()`; sluša promjenu providera i prikazuje modal za svaku PendingAssignment jednu po jednu (niz modala ako ima više posla)
- `pending_assignment_overlay.dart` — fullscreen modal kartice s detaljima posla (senior, adresa, raspored dana), gumbi Prihvati / Odbij; po potvrdi/odbijanju briše dodjelu iz statea i prikazuje sljedeći modal ako postoji
- Rezultat: student po loginu (ili kad dobije novi posao via SignalR) vidi kartice za svaki posao koji mora potvrditi, jednu po jednu

### Backend — date range filter za sesije

- `GET /api/sessions/order/{orderId}?from=&to=` — opcionalni date range filter
- Implementirano kroz sve slojeve: IJobInstanceRepository → JobInstanceRepository → IJobInstanceService → JobInstanceService → SessionsController
- Recurring orderi prikazuju samo tekući mjesec sesija (performance + UX)

### Backend — auto-complete / auto-cancel order kad nema nadolazećih sesija

- `OrderStatusUpdater.Update()` — nova logika:
  - **One-time order** (IsRecurring=false): ako admin otkaže jedinu sesiju → order automatski postaje **Cancelled**
  - **Recurring order** (IsRecurring=true): ako su sve sesije otkazane ali nijedna completed → order **OSTAJE Active** (novi termini mogu doći kad student produži ugovor)
  - Ako je bar jedna sesija completed → order postaje **Completed**
- Ova logika se okida i kad admin otkaže termine, ne samo senior

### helpi_app — UI polish

- `order_detail_screen.dart`:
  - Sesije uvijek expandirane (`_jobsExpanded = true`)
  - Per-session "Otkaži" gumb **sakriven za one-time ordere** (senior koristi samo "Otkaži narudžbu")
  - Date range filtering: recurring orderi šalju `from`/`to` za tekući mjesec, one-time ne šalju
  - Razmaci smanjeni: scroll bottom padding 32→4, gap nakon sesija 24→4

### helpi_app — Dead code cleanup

- Obrisano `senior_profile_screen.dart` — stari ProfileScreen, nikad importan, zamijenjen s ProfileMenuScreen
- Obrisano `review_card.dart` — stari ReviewCard, nikad importan, zamijenjen s ReviewInlineCard

### Admin — instant SignalR refresh za sesije

- `data_providers.dart` — novi `sessionsVersionProvider` (StateProvider<int>)
- `signalr_notification_service.dart` — `_onEntityChanged()` ispravlja parsiranje Map formata (`{entityType: "Sessions", timestamp: ...}`); bumpa `sessionsVersionProvider` za Sessions/Orders/JobInstances
- `order_detail_screen.dart` (admin) — sluša `sessionsVersionProvider`, auto re-fetcha sesije bez izlaska iz ekrana
- Rezultat: kad senior otkaže termin u app-u, admin odmah vidi promjenu u real-time

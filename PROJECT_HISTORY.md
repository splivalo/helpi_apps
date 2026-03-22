# Helpi App — Project History

> Kronologija ključnih odluka za unified Flutter app.

---

## 2026-03-14 — Odluka: Merge 2 appa u 1

**Problem:** helpi_senior (32 fajla) i helpi_student (31 fajl) su odvojene Flutter aplikacije s identičnim UI identitetom (boje, tipografija, widgeti). Duplicirali smo ~60% koda.

**Odluka:** Napraviti `helpi_app` — jedan unified app s role-based routingom.

**Razlozi:**

- Isti UI identity (AppColors, HelpiTheme, shared widgets)
- Isti backend (isti auth endpoint, backend vraća userType)
- Manje maintenance (1 codebase, 1 pubspec, 1 CI/CD)
- Login automatski prepoznaje ulogu — ne treba 2 appa

---

## 2026-03-14 — Arhitektonske odluke

1. **Senior's ApiClient pattern** (constructor injection) odabran nad studentovim
2. **Instance-based TokenStorage** (ne singleton)
3. **Student model klase zadržale originalna imena** (Job, JobStatus, ReviewModel) — nema konflikta jer žive u odvojenim fajlovima
4. **Bulk copy + PowerShell sed** za migraciju importa umjesto ručnog prepisivanja
5. **HelpiTheme color aliases** dodani (teal, coral, textSecondary...) da student ekrani rade bez ikakvih izmjena

---

## 2026-03-15 — Role Picker na registraciji

**Problem:** Login ekran bio kopiran iz senior appa — registracija nije podržavala studente.

**Odluka:** Dodan role picker step ("Tko ste vi?") s 2 kartice:

- "Tražim pomoć" (coral ❤️) → Customer profil forma → SeniorShell
- "Želim pomagati" (teal 🎓) → RegistrationDataScreen → OnboardingScreen → StudentShell

**Ključno:** Login ne treba role picker — backend automatski vraća userType po emailu.

---

## 2026-03-15 — Back navigacija na svim koracima

**Problem:** Customer registracija imala back strelicu, student nije.

**Odluka:** Dodani `onBack` callbackovi na RegistrationDataScreen i OnboardingScreen. Svi koraci imaju konzistentnu back navigaciju:

- Role picker → nazad na email/pass
- Customer profil → nazad na role picker
- Student RegistrationData → nazad na login (role picker)
- Student Onboarding → nazad na RegistrationData

---

## 2026-03-22 — Suspension ekran + 403 handler

**Problem:** Suspendirani korisnici mogli su i dalje koristiti app normalno.

**Odluka:**

1. `suspended_screen.dart` — dedicirani ekran s razlogom suspenzije, kontakt info, i delete account
2. `ApiClient` Dio interceptor hvata HTTP 403 → trigera `onSuspended` callback → app prikazuje suspension ekran
3. Backend `SuspensionCheckMiddleware.cs` vraća 403 za sve rute (osim auth/suspensions endpointova)
4. Backend `OrdersService.CreateOrderAsync()` provjerava `IsSuspended` na Senior→Customer→User lancu

**Commit:** helpi_app `5ca6a13`, backend `a652bff`

---

## 2026-03-22 — Riverpod + SignalR real-time arhitektura

**Problem:** App koristio setState/ValueNotifier — nema reaktivnosti, nema real-time refresha. Admin promijeni nešto u backendu, user mora ručno refreshat.

**Odluka:** Migracija na Riverpod + SignalR:

1. **flutter_riverpod ^2.6.1** — `ProviderScope` u main.dart, `ConsumerStatefulWidget` na key ekranima
2. **signalr_netcore ^1.4.4** — WebSocket konekcija na `/hubs/notifications` s JWT auth
3. **4 providera** u `lib/core/providers/`:
   - `auth_provider.dart` — AuthState + AuthNotifier (StateNotifier), zamjenjuje sve lokalne setState iz app.dart
   - `signalr_provider.dart` — SignalRService, auto-connect na login, auto-disconnect na logout, exponential backoff reconnect
   - `realtime_sync_provider.dart` — Sluša `ReceiveNotification` + `SystemNotification` SignalR evente, auto-refresh orders (senior) ili jobs (student)
   - `jobs_provider.dart` — JobsState + JobsNotifier za reaktivni student raspored i statistiku
4. **Konvertirani ekrani:** `app.dart`, `schedule_screen.dart`, `statistics_screen.dart` → ConsumerStatefulWidget
5. **Backward compat:** OrdersNotifier (ChangeNotifier) ostaje, RealTimeSyncService poziva `replaceAll()` → `notifyListeners()` → OrdersScreen/OrderDetailScreen se auto-rebuilda

**Ključno:** Sidney-ev app koristi GoRouter + Freezed + Retrofit — mi NE koristimo nijednu od tih libova. Migracija je rađena "naš way" sa postojećim Dio/FlutterSecureStorage/Navigator.

**Commit:** `213fd5e` (10 fajlova, 674 insertions, 225 deletions)

---

## Statistika

| Metrika                       | Vrijednost              |
| ----------------------------- | ----------------------- |
| Ukupno .dart fajlova          | 64                      |
| Analyze errori                | 0                       |
| i18n ključeva                 | ~1000+ (HR+EN)          |
| Shared widgets                | 12                      |
| Feature screens               | 15 (+ suspended_screen) |
| Riverpod providers            | 4                       |
| Backend endpointi (korišteni) | 6                       |
| State management              | Riverpod ^2.6.1         |
| Real-time                     | SignalR ^1.4.4          |

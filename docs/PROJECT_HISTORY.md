# Helpi App — Project History

> Kronologija ključnih odluka za unified Flutter app.

---

## 2026-04-18 — CouponType simplifikacija

- **Percentage + FixedPerSession uklonjeni** — Uklonjeni `case 3` i `case 4` iz `_couponDescription` i `_calculateCouponDiscount` u `order_flow_screen.dart`, te `_couponLabel` u `order_detail_screen.dart`. Uklonjeni `couponPercentOff` i `couponFixedOff` stringovi iz `app_strings.dart` (HR/EN + getteri).
- CouponType sada ima samo 3 sat-based tipa: MonthlyHours(0), WeeklyHours(1), OneTimeHours(2).
- `flutter analyze` = 0 issues.

---

## 2026-04-01 — Realtime refresh sužen na relevantne notifikacije

**Problem:** Unified app je radio refresh orders/jobs na svaku SignalR notifikaciju, što je bilo sigurno ali pregrubo i nepotrebno bučno.

**Odluka:** `RealTimeSyncService` sada prvo parsira `ReceiveNotification` payload i refresha samo na known state-changing tipove. `SystemNotification` ostaje fallback koji i dalje radi puni refresh.

**Rezultat:** Manje nepotrebnih API refresh poziva, ali bez gubitka sigurnosti za reschedule/reassignment tokove.

---

## 2026-04-01 — Lokalni fallback za payment kartice u order flowu

**Problem:** Testiranje kreiranja narudžbe na pravom uređaju je blokirano kad backend nema spremljene payment metode, a pravi Stripe add-card flow još nije spreman za v2.

**Odluka:** `order_flow_screen.dart` i `senior_profile_screen.dart` koriste postojeći backend `payment-methods` endpoint za spremanje dummy test kartica bez `processorToken`. Ako backend nije dostupan, order flow i dalje pada na lokalni fallback kako checkout ne bi bio blokiran.

**Granica rješenja:** Ovo nije Stripe integracija. Dummy kartice služe za razvoj i testiranje, a create-order ih i dalje tretira kao test kartice pa ne šalje `paymentMethodId` ako kartica nema pravi `processorToken`.

**Rezultat:** Profil sada stvarno sprema i briše test kartice kroz backend, order flow može dodati karticu bez izlaska iz checkouta, a testiranje ostaje moguće bez diranja live Stripe v1 konfiguracije.

**Dodatno:** `order_flow_screen.dart` više ne ovisi samo o fiksnim service ID brojevima. App sada pokušava dohvatiti `service-categories` i iz backend DTO-a razriješiti odgovarajuće service ID-jeve, uz postojeći fallback ako backend odgovor nije dostupan.

---

## 2026-04-01 — Notifications više nisu samo servisni TODO

**Problem:** Unified app je već imao backend metode za notifications, ali korisnik nije imao gotov ekran koji te podatke stvarno koristi.

**Odluka:** Dodan je `NotificationsScreen` kao backend-driven ekran s unread/all prikazom i mark-as-read akcijama, bez diranja postojećeg home UI-ja mobilne aplikacije.

**Rezultat:** Notifications više nisu samo “servis postoji”, nego su stvarno vidljive i dostupne korisniku bez razbijanja postojećeg UX-a.

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

## 2026-03-23 — Login Error Handling & Registration Server Check

- **Login error distinction** — `AuthResult.isConnectionError` flag razlikuje server nedostupan (narančasta, cloud_off ikona) od krivih credentialsa (crvena poruka). DioException type checking: connectionTimeout, connectionError, receiveTimeout, null response.
- **Registration server check** — `checkEmailExists` sada vraća `bool?` (true=postoji, false=ne postoji, null=server nedostupan). Registracija step 1 prikazuje narančastu "Server nedostupan" poruku ako je null.
- **Forgot password text alignment** — Dodan `crossAxisAlignment: CrossAxisAlignment.start` na Column u `_ForgotPasswordDialog`
- **AppStrings HR lokalizacija** — Dodani ključevi: `serverUnavailableTitle`, `serverUnavailableMessage`, `serverUnavailableRetrying`, `serverUnavailableRetry`
- **Rezultat**: 0 errors → 0 errors (flutter analyze)

---

## Statistika

| Metrika                       | Vrijednost              |
| ----------------------------- | ----------------------- |
| Ukupno .dart fajlova          | 64                      |
| Analyze errori                | 0                       |
| i18n ključeva                 | ~1100+ (HR+EN)          |
| Shared widgets                | 12                      |
| Feature screens               | 15 (+ suspended_screen) |
| Riverpod providers            | 4                       |
| Backend endpointi (korišteni) | 8                       |
| State management              | Riverpod ^2.6.1         |
| Real-time                     | SignalR ^1.4.4          |

---

## 2026-04-13 — Terms of Use s native HTML renderiranjem

**Problem:** WebView za Terms of Use nije radio na svim platformama i bio spor.

**Odluka:** `flutter_widget_from_html_core` renderira HTML direkt u Flutter widgete. Custom styles (teal linkovi, smanjen font, bez list numbering).

---

## 2026-04-14 — Timer-based live session status + WidgetsBindingObserver fix

**Problem:** Session badge je statički prikazivao backend status. Ako je backend kašnjao s Hangfire completionom, badge je ostao "Predstojeći" i nakon završetka posla.

**Odluka:** Badge widget postao `StatefulWidget` s `Timer`. Izračuna exactan `Duration` do sljedeće tranzicije (start/end time) i postavi jedan Timer. Kad Timer fired → `setState` → nova tranzicija.

**Android sleep bug:** `Timer` u Dartu ne fired kad je app u backgroundu. Dodali `WidgetsBindingObserver` — na `AppLifecycleState.resumed`, cancela stari Timer i re-evaluira na temelju `DateTime.now()`.

**Rezultat:** Badge automatski prelazi Predstojeći→Aktivan→Završen u realnom vremenu, čak i kad se app vrati iz backgrounda.

---

## 2026-04-15 — Bulletproof review flow (EnsureCompleted pattern)

**Problem:** Senior pokušava ostaviti recenziju, ali backend Hangfire job još nije markirao sesiju kao completed → pending review ne postoji → "Pošalji ocjenu" ne radi.

**Odluka:** 3-step fallback pattern na frontendu:

1. Check lokalni cache
2. Re-fetch s backenda (Hangfire možda upravo završio)
3. Pozovi `POST /api/sessions/{id}/ensure-completed` — backend idempotentno završava sesiju i kreira pending reviews

**Backend `EnsureCompletedAsync`:**

- Idempotent: ako session već completed → provjeri reviewe, ako fale → ponovo ih kreira
- Samo dopušta completion ako je `now > endTime` i status je scheduled/inProgress
- Kreira 2 pending reviews (SeniorToStudent + StudentToSenior)

**Frontend instant update:** Nakon submit-a, `job.review` se direktno mutira na lokalnom objektu → `Navigator.pop` → `setState` → UI se odmah updatea bez reload-a.

---

## 2026-04-15 — Jednokratne narudžbe unificirane s ponavljajućim

**Problem:** Jednokratne completed narudžbe imale posebnu `_studentReviewCard` karticu koja je prikazivala studenta i review u custom layoutu. Ponavljajuće koristile `_jobsSection` s popisom job kartica. Dvostruki kod za istu stvar.

**Odluka:** Obrisana `_studentReviewCard`. Sve narudžbe (one-time + recurring) sada koriste `_jobsSection`:

- Jednokratne: naslov "Termin" (singular), default expanded
- Ponavljajuće: naslov "Termini" (plural), default collapsed
- Isti job card layout za obje: datum, vrijeme, cijena, student, status badge, review/cancel gumbi

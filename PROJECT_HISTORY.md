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

## Statistika

| Metrika                       | Vrijednost     |
| ----------------------------- | -------------- |
| Ukupno .dart fajlova          | 55             |
| Analyze errori                | 0              |
| i18n ključeva                 | ~1000+ (HR+EN) |
| Shared widgets                | 11             |
| Feature screens               | 14             |
| Backend endpointi (korišteni) | 6              |

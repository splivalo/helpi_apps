/// Gemini Hybrid i18n — centralizirani stringovi za Helpi app (Senior + Student).
///
/// Svaki tekst koji se prikazuje korisniku MORA ići kroz ovu klasu.
/// Backend šalje labelKey/placeholderKey, Flutter mapira na AppStrings getters.
class AppStrings {
  AppStrings._();

  // ─── Trenutni jezik ─────────────────────────────────────────────
  static String _currentLocale = 'hr';

  static String get currentLocale => _currentLocale;

  static void setLocale(String locale) {
    if (_localizedValues.containsKey(locale)) {
      _currentLocale = locale;
    }
  }

  // ─── Lokalizirane vrijednosti ───────────────────────────────────
  static final Map<String, Map<String, String>> _localizedValues = {
    'hr': {
      // ── App ───────────────────────────────────
      'appName': 'Helpi',
      'appTagline': 'Pomoć na dlanu',
      'quickActionsTitle': 'Što vam treba?',
      'topBadge': 'Top',

      // ── Navigacija ────────────────────────────
      'navHome': 'Pomoć',
      'navOrder': 'Naruči',
      'navStudents': 'Studenti',
      'navOrders': 'Narudžbe',
      'navMessages': 'Poruke',
      'navProfile': 'Profil',
      'navSchedule': 'Raspored',
      'navStatistics': 'Statistika',

      // ── Naruči ekran ─────────────────────────
      'orderTitle': 'Naruči pomoć',
      'orderSubtitle':
          'Odaberite što vam treba i mi ćemo vam poslati najboljeg pomoćnika.',

      // ── Order flow ─────────────────────────────
      'newOrder': 'Nova narudžba',
      'orderFlowStep1': 'Kada?',
      'orderFlowStep2': 'Što vam treba?',
      'orderFlowStep3': 'Pregled',
      'stepIndicator': 'Korak {current} od {total}',
      'frequency': 'Učestalost',
      'addDay': 'Dodaj još jedan dan',
      'selectDay': 'Odaberite dan',
      'fromTime': 'Od',
      'hourLabel': 'Sati',
      'minuteLabel': 'Minute',
      'durationChoice': 'Trajanje',
      'hour1': '1 sat',
      'hour2': '2 sata',
      'hour3': '3 sata',
      'hour4': '4 sata',
      'selectDate': 'Odaberite datum',
      'selectStartDate': 'Početak usluge',
      'firstServiceDate': 'Prva usluga: {date}',
      'dayNotInRange': '{day} ne pada u odabrani period',
      'dayMonFull': 'Ponedjeljak',
      'dayTueFull': 'Utorak',
      'dayWedFull': 'Srijeda',
      'dayThuFull': 'Četvrtak',
      'dayFriFull': 'Petak',
      'daySatFull': 'Subota',
      'daySunFull': 'Nedjelja',
      'serviceNoteHint':
          'Opišite što vam treba (npr. "Trebam pomoć s dostavom iz trgovine i ljekarne.")',
      'escortInfo':
          'Pratnja može potrajati dulje od odabranog trajanja (npr. čekanje kod liječnika). Ako usluga traje dulje, razlika se naplaćuje dodatno.',
      'overtimeDisclaimer':
          'Naplata se vrši 30 minuta prije početka usluge. Ako usluga traje dulje od odabranog trajanja, dodatno vrijeme se naplaćuje prema dogovoru.',
      'orderSummaryFrequency': 'Učestalost',
      'orderSummaryDays': 'Odabrani dani',
      'orderSummaryServices': 'Odabrane usluge',
      'orderSummaryNotes': 'Napomena',
      'studentName': 'Ime studenta',
      'orderSummaryDate': 'Datum',
      'orderSummaryTime': 'Vrijeme',
      'orderSummaryDuration': 'Trajanje',
      'orderSummaryStartDate': 'Početak',
      'orderSummaryEndDate': 'Kraj',
      'orderSummaryPrice': 'Cijena',
      'orderSummaryTotal': 'Ukupno',
      'orderSummaryWeeklyTotal': 'Tjedno ukupno',
      'noNotes': 'Nema napomene',
      'orderMessage': 'Poruka (neobavezno)',
      'orderMessageHint': 'Napišite poruku ili dodatne informacije...',

      // ── Općenito ──────────────────────────────
      'loading': 'Učitavanje...',
      'error': 'Greška',
      'orderCreateError': 'Greška pri kreiranju narudžbe',
      'retry': 'Pokušaj ponovo',
      'cancel': 'Odustani',
      'confirm': 'Potvrdi',
      'selectTime': 'Odaberite vrijeme',
      'save': 'Spremi',
      'back': 'Natrag',
      'next': 'Dalje',
      'close': 'Zatvori',
      'search': 'Pretraži',
      'noResults': 'Nema rezultata',
      'ok': 'U redu',

      // ── Auth ──────────────────────────────────
      'login': 'Prijava',
      'register': 'Registracija',
      'email': 'E-mail adresa',
      'password': 'Lozinka',
      'forgotPassword': 'Zaboravljena lozinka?',
      'loggingIn': 'Prijava u tijeku...',
      'loginError': 'Greška pri prijavi',
      'registrationError': 'Greška pri registraciji',
      'emailAlreadyExists': 'Korisnik s ovom e-mail adresom već postoji',
      'registrationSuccess': 'Registracija uspješna! Možete se prijaviti.',
      'fillAllFields': 'Molimo ispunite sva obavezna polja',
      'registering': 'Registracija u tijeku...',
      'invalidCredentials': 'Neispravni podaci za prijavu',
      'forgotPasswordTitle': 'Zaboravljena lozinka',
      'forgotPasswordSubtitle': 'Unesite email adresu za slanje koda',
      'sendResetCode': 'Pošalji kod',
      'resetCode': 'Kod za resetiranje',
      'currentPassword': 'Trenutna lozinka',
      'newPassword': 'Nova lozinka',
      'confirmNewPassword': 'Potvrdi novu lozinku',
      'passwordsMismatch': 'Lozinke se ne podudaraju',
      'resetPasswordButton': 'Resetiraj lozinku',
      'resetPasswordSuccess': 'Lozinka uspješno promijenjena',
      'codeSent': 'Kod poslan na email',
      'backToLogin': 'Povratak na prijavu',
      'loginButton': 'Prijavi se',
      'registerButton': 'Registriraj se',
      'noAccount': 'Nemate račun?',
      'hasAccount': 'Već imate račun?',
      'chooseRoleTitle': 'Tko ste vi?',
      'chooseRoleSubtitle': 'Odaberite kako želite koristiti Helpi',
      'roleCustomerTitle': 'Tražim pomoć',
      'roleCustomerDesc': 'Želim naručiti uslugu za sebe ili bližnje',
      'roleStudentTitle': 'Želim pomagati',
      'roleStudentDesc': 'Student/ica sam i želim pružati usluge',
      'firstName': 'Ime',
      'lastName': 'Prezime',
      'phone': 'Broj telefona',
      'address': 'Adresa',
      'addressHint': 'Počnite tipkati adresu za pretragu',
      'regProfileTitle': 'Popunite profil',
      'regProfileSubtitle': 'Trebamo vaše podatke za nastavak',
      'completeRegistration': 'Završi registraciju',
      'orderingForOther': 'Naručujem za drugog',

      // ── Marketplace ───────────────────────────
      'marketplace': 'Studenti',
      'filterTitle': 'Filtriraj',
      'filterService': 'Vrsta usluge',
      'filterDate': 'Datum',
      'filterDay': 'Dostupnost',
      'filterAnyDay': 'Bilo koji dan',
      'filterApply': 'Primijeni filtre',
      'filterClear': 'Očisti filtre',
      'perHour': '/sat',
      'reviews': 'Recenzija',
      'available': 'Dostupan',
      'unavailable': 'Nedostupan',

      // ── Vrste usluga ─────────────────────────
      'serviceActivities': 'Aktivnosti',
      'serviceShopping': 'Kupovina',
      'serviceHousehold': 'Kućanstvo',
      'serviceCompanionship': 'Pratnja',
      'serviceTechHelp': 'Tehnologija',
      'servicePets': 'Ljubimci',

      // ── Time picker ──────────────────────────
      'availableWindow': 'Dostupan: {start} – {end}',
      'startTimeLabel': 'Početak',
      'durationLabel': 'Trajanje',
      'hourSingular': 'sat',
      'hourPlural': 'sata',
      'aboutStudent': 'O studentu',

      // ── Ponavljanje ──────────────────────────
      'oneTime': 'Jednom',
      'recurring': 'Ponavljajuće',
      'continuous': 'Stalno',
      'untilDate': 'Do datuma',
      'hasEndDate': 'Do određenog datuma',
      'selectEndDate': 'Odaberite zadnji termin',
      'recurringNoEnd': 'Ponavljajuće',
      'recurringWithEnd': 'Do {date}',
      'lastSessionLabel': 'Zadnji termin',
      'recurringUntilDateInfo':
          'Rezervacija traje do {date}. '
          'Nakon tog datuma automatski prestaje.',
      'noEndDate': 'Bez kraja',
      'everyWeek': 'Svaki',
      'dayMon': 'Pon',
      'dayTue': 'Uto',
      'dayWed': 'Sri',
      'dayThu': 'Čet',
      'dayFri': 'Pet',
      'daySat': 'Sub',
      'daySun': 'Ned',
      'dayMonShort': 'Po',
      'dayTueShort': 'Ut',
      'dayWedShort': 'Sr',
      'dayThuShort': 'Če',
      'dayFriShort': 'Pe',
      'daySatShort': 'Su',
      'daySunShort': 'Ne',
      'perSession': '/termin',
      'recurringLabel': '{days} — {end}',
      'configureAllDays': 'Odaberite vrijeme za sve dane',
      'notConfigured': 'Nije postavljeno',

      // ── Booking ───────────────────────────────
      'availability': 'Dostupnost',
      'booking': 'Narudžba',
      'selectSlot': 'Odaberi termin',
      'orderSummary': 'Pregled narudžbe',
      'placeOrder': 'Naruči',
      'orderConfirmed': 'Narudžba potvrđena!',
      'orderNotes': 'Dodatne napomene',
      'totalPrice': 'Ukupna cijena',
      'bookingServiceHeader': 'Što vam treba?',
      'bookingChipShopping': 'Kupovina',
      'bookingChipCleaning': 'Pomoć u kući',
      'bookingChipCompanionship': 'Društvo',
      'bookingChipWalk': 'Šetnja',
      'bookingChipEscort': 'Pratnja',
      'bookingChipOther': 'Ostalo',
      'bookingDisclaimer': 'Studenti ne pružaju medicinsku njegu.',
      'bookingNotesHint': 'Npr. "Mlijeko i kruh iz Konzuma"',
      'bookNow': 'Rezerviraj',

      // ── Payment ───────────────────────────────
      'payment': 'Plaćanje',
      'paymentMethod': 'Način plaćanja',
      'payNow': 'Plati sada',
      'paymentSuccess': 'Plaćanje uspješno!',
      'paymentFailed': 'Plaćanje neuspješno',

      // ── Chat ──────────────────────────────────
      'chat': 'Poruke',
      'chatHelpiSupport': 'Helpi podrška',
      'chatWelcome': 'Dobrodošli! Ovdje možete razgovarati s Helpi timom.',
      'chatHelpOffer':
          'Ako imate pitanja o narudžbama ili trebate pomoć, slobodno nam pišite.',
      'typeMessage': 'Upiši poruku...',
      'sendMessage': 'Pošalji',
      'noMessages': 'Nema poruka',

      // ── Profil ────────────────────────────────
      'profile': 'Moj profil',
      'editProfile': 'Uredi profil',
      'myOrders': 'Moje narudžbe',
      'noOrders': 'Još nemate narudžbi',
      'noOrdersSubtitle': 'Kada naručite uslugu, pojavit će se ovdje.',
      'ordersProcessing': 'U obradi',
      'ordersActive': 'Aktivne',
      'ordersCompleted': 'Završene',
      'ordersCancelled': 'Otkazane',
      'ordersInactive': 'Neaktivne',
      'orderProcessing': 'U obradi',
      'orderActive': 'Aktivna',
      'orderCompleted': 'Završena',
      'orderCancelled': 'Otkazana',
      'orderArchived': 'Arhivirana',
      'cancelOrder': 'Otkaži narudžbu',
      'repeatOrder': 'Ponovi narudžbu',
      'orderPlaced': 'Narudžba zaprimljena!',
      'noOrdersInCategory': 'Nema narudžbi u ovoj kategoriji',
      'orderNumber': 'Narudžba #{number}',
      'showMore': 'Prikaži više',
      'showLess': 'Prikaži manje',
      'orderDetails': 'Detalji narudžbe',
      'studentsSection': 'Studenti',
      'jobsSection': 'Termini',
      'jobsMonthlySubtitle': 'Prikazani termini za tekući mjesec.',
      'jobCompleted': 'Završen',
      'jobUpcoming': 'Predstojeći',
      'jobCancelled': 'Otkazan',
      'cancelJobLabel': 'Otkaži',
      'cancelJobConfirm': 'Jeste li sigurni da želite otkazati ovaj termin?',
      'jobStudent': 'Student',
      'assignedSince': 'Dolazi od',
      'rateStudent': 'Ocijeni',
      'sendReview': 'Pošalji ocjenu',
      'reviewHint': 'Komentar (opcionalno)',
      'yourReviews': 'Vaše ocjene',
      'noStudentsYet': 'Još nema dodijeljenih studenata',
      'logout': 'Odjava',
      'deleteAccount': 'Izbriši račun',
      'deleteAccountConfirmTitle': 'Izbriši račun',
      'deleteAccountConfirmContent':
          'Jeste li sigurni da želite izbrisati svoj račun? Ova akcija se ne može poništiti.',
      'deleteAccountNo': 'Ne',
      'deleteAccountYes': 'Da',
      'deleteAccountSuccess': 'Račun je uspješno izbrisan.',
      'deleteAccountError': 'Greška pri brisanju računa.',
      'loginTitle': 'Dobrodošli u Helpi',
      'loginSubtitle': 'Prijavite se ili kreirajte račun',
      'loginEmail': 'Email adresa',
      'loginPassword': 'Lozinka',
      'settings': 'Postavke',
      'language': 'Jezik',
      'accessData': 'Pristupni podaci',
      'changePassword': 'Promijeni lozinku',
      'ordererData': 'Podaci o naručitelju',
      'seniorData': 'Podaci o korisniku',
      'gender': 'Spol',
      'genderMale': 'Muško',
      'genderFemale': 'Žensko',
      'dateOfBirth': 'Datum rođenja',
      'dobPlaceholder': 'DD.MM.GGGG.',
      'langHr': 'Hrvatski',
      'langEn': 'English',
      'langHrvatski': 'Hrvatski',
      'langEnglish': 'English',
      'appVersion': 'Helpi v2.0.0',
      'creditCards': 'Kreditne kartice',
      'noCards': 'Nemate spremljenih kartica',
      'addCard': 'Dodaj karticu',
      'promoCode': 'Promo kod',
      'promoCodeHint': 'Unesite promo kod',
      'promoCodeApply': 'Primijeni',
      'promoCodeInvalid': 'Nevažeći promo kod',
      'promoCodeValidating': 'Provjera...',
      'promoCodeDiscount': 'Popust: {amount}',
      'promoCodeApplied': 'Promo kod primijenjen',
      'agreeToTerms': 'Slažem se s ',
      'termsOfUse': 'uvjetima',
      'byClickingRegister': 'Klikom na "Završi registraciju" prihvaćate ',
      'termsOfUseLink': 'uvjete korištenja',
      'cardEndingIn': 'Kartica završava na {digits}',

      // ── Raspored (student) ────────────────────
      'scheduleTitle': 'Raspored',
      'scheduleToday': 'Danas',
      'scheduleTomorrow': 'Sutra',
      'scheduleNoJobs': 'Nemate zakazanih poslova za ovaj dan.',
      'scheduleNoJobsSubtitle': 'Uživajte u slobodnom danu!',
      'jobDetailTitle': 'Detalji posla',
      'jobSenior': 'Korisnik',
      'jobAddress': 'Adresa',
      'jobTime': 'Vrijeme',
      'jobService': 'Usluga',
      'jobNotes': 'Napomene',
      'jobStatusScheduled': 'Dodijeljeno',
      'jobStatusCompleted': 'Završeno',
      'jobStatusCancelled': 'Otkazano',
      'jobDecline': 'Ne mogu',
      'jobDeclineTitle': 'Otkažite posao',
      'jobDeclineHint': 'Napišite razlog otkazivanja...',
      'jobDeclineConfirm': 'Pošalji',
      'jobDeclineTooLate': 'Nije moguće otkazati manje od 24h prije početka.',
      'jobDeclineSuccess': 'Posao je otkazan.',
      'rateSenior': 'Ocijeni',
      'yourReview': 'Vaša ocjena',
      'reviewSent': 'Ocjena je poslana.',
      'serviceShopping2': 'Kupovina',
      'serviceHouseHelp2': 'Pomoć u kući',
      'serviceCompanionship2': 'Društvo',
      'serviceWalking2': 'Šetnja',
      'serviceEscort2': 'Pratnja',
      'serviceOther2': 'Ostalo',

      // ── Statistika ───────────────────────────
      'statsTitle': 'Statistika',
      'statsTotalJobs': 'Ukupno poslova',
      'statsTotalHours': 'Odrađeno sati',
      'statsAvgRating': 'Prosječna ocjena',
      'statsRecentReviews': 'Posljednje ocjene',
      'statsNoReviews': 'Još nema ocjena.',
      'statsWeeklyReview': 'Tjedni pregled',
      'statsMonthlyReview': 'Mjesečni pregled',
      'statsTotalHoursValue': '{hours} odrađenih sati ukupno',
      'statsCompareMore': '{percent}% više sati nego prošli {period}.',
      'statsCompareLess': '{percent}% manje sati nego prošli {period}.',
      'statsCompareSame': 'Jednako sati kao prošli {period}.',
      'statsPeriodWeek': 'tjedan',
      'statsPeriodMonth': 'mjesec',
      'statsShowAllReviews': 'Prikaži sve ocjene',
      'statsAllReviews': 'Sve ocjene',
      'statsDayMon': 'P',
      'statsDayTue': 'U',
      'statsDayWed': 'S',
      'statsDayThu': 'Č',
      'statsDayFri': 'P',
      'statsDaySat': 'S',
      'statsDaySun': 'N',

      // ── Dostupnost (student) ──────────────────
      'availabilitySection': 'Dostupnost',
      'availabilityDescription':
          'Odaberite dane i vrijeme kada ste dostupni za pomoć.',
      'toTime': 'Do',
      'notSet': 'Nije postavljeno',
      'studentData': 'Osobni podaci',
      'faculty': 'Fakultet',
      'facultyHint': 'Odaberite fakultet',
      'facultyPickerTitle': 'Odaberite fakultet',
      'facultySearchHint': 'Pretraži po akronimu ili nazivu',
      'facultyNoResults': 'Nema rezultata',
      'studentIdCard': 'Broj studentske iskaznice',
      'studentIdCardHint': 'Npr. 0036512345',
      'registrationDataTitle': 'Vaši podaci',
      'registrationDataSubtitle':
          'Ispunite svoje podatke kako bismo mogli kreirati vaš profil.',
      'registrationDataNext': 'Dalje',
      'onboardingTitle': 'Kada ste slobodni?',
      'onboardingSubtitle':
          'Postavite svoju dostupnost kako bismo vam mogli slati odgovarajuće narudžbe.',
      'onboardingFinish': 'Završi',
      'onboardingMinDay': 'Odaberite barem 1 dan s postavljenim vremenom.',

      // ── Parametrizirani ───────────────────────
      'deleteConfirm': 'Obriši {item}?',
      'distanceKm': '{km} km',
      'pricePerHour': '{price} €/sat',
      'sundayRate': 'Nedjelja (viša cijena)',
      'ratingCount': '{count} recenzija',
      'welcomeUser': 'Dobrodošli, {name}!',
      'orderForStudent': 'Narudžba za {student}',
      'slotTime': '{start} - {end}',

      // ── Kalendar ───────────────────────────
      'month1': 'Siječanj',
      'month2': 'Veljača',
      'month3': 'Ožujak',
      'month4': 'Travanj',
      'month5': 'Svibanj',
      'month6': 'Lipanj',
      'month7': 'Srpanj',
      'month8': 'Kolovoz',
      'month9': 'Rujan',
      'month10': 'Listopad',
      'month11': 'Studeni',
      'month12': 'Prosinac',
      'calendarFree': 'Slobodno',
      'calendarPartial': 'Djelomično',
      'calendarBooked': 'Zauzeto',
      'selectDatePrompt': 'Odaberite datum za rezervaciju',
      'freeHoursCount': '{free} od {total} sati slobodno',
      'allHoursFree': 'Svi termini slobodni',
      'recurringConfirmed': 'Potvrđeno: {count}',
      'recurringSkipped': 'Preskočeno: {count}',
      'sessionsLabel': 'Termini',
      'recurringFree': 'Slobodno',
      'recurringOccupied': 'Zauzeto',
      'recurringPartial': '{start}-{end} slobodno',
      'recurringTotalPrice': 'Ukupno ({count} termina)',
      'recurringPerVisitPrice': '{price} €/termin',
      'recurringBillingInfo': 'Naplata karticom 30 min prije svakog dolaska.',
      'recurringMonthTitle': 'Svaki {day} u mjesecu {month}',
      'recurringDaysLabel': 'Dani',
      'recurringOutsideWindow': 'Izvan termina',
      'recurringAutoRenew':
          'Ova rezervacija vrijedi do kraja mjeseca {month}. '
          'Automatski se obnavlja sljedeći mjesec ako student '
          'produži dostupnost. Možete otkazati bilo kada.',

      // ── Suspenzija ────────────────────────────────────
      'suspendedTitle': 'Račun suspendiran',
      'suspendedMessage': 'Vaš račun je privremeno suspendiran.',
      'suspendedReason': 'Razlog: {reason}',
      'suspendedContact': 'Za više informacija obratite se podršci:',
      'suspendedEmail': 'podrska@helpi.hr',
      'suspendedLogout': 'Odjavi se',
    },
    'en': {
      // ── App ───────────────────────────────────
      'appName': 'Helpi',
      'appTagline': 'Help at your fingertips',
      'quickActionsTitle': 'What do you need?',
      'topBadge': 'Top',

      // ── Navigacija ────────────────────────────
      'navHome': 'Help',
      'navOrder': 'Order',
      'navStudents': 'Students',
      'navOrders': 'Orders',
      'navMessages': 'Messages',
      'navProfile': 'Profile',
      'navSchedule': 'Schedule',
      'navStatistics': 'Statistics',

      // ── Order screen ─────────────────────────
      'orderTitle': 'Order help',
      'orderSubtitle':
          'Choose what you need and we will send you the best helper.',

      // ── Order flow ─────────────────────────────
      'newOrder': 'New order',
      'orderFlowStep1': 'When?',
      'orderFlowStep2': 'What do you need?',
      'orderFlowStep3': 'Summary',
      'stepIndicator': 'Step {current} of {total}',
      'frequency': 'Frequency',
      'addDay': 'Add another day',
      'selectDay': 'Select a day',
      'fromTime': 'From',
      'hourLabel': 'Hours',
      'minuteLabel': 'Minutes',
      'durationChoice': 'Duration',
      'hour1': '1 hour',
      'hour2': '2 hours',
      'hour3': '3 hours',
      'hour4': '4 hours',
      'selectDate': 'Select date',
      'selectStartDate': 'Service start date',
      'firstServiceDate': 'First service: {date}',
      'dayNotInRange': '{day} does not fall within the selected period',
      'dayMonFull': 'Monday',
      'dayTueFull': 'Tuesday',
      'dayWedFull': 'Wednesday',
      'dayThuFull': 'Thursday',
      'dayFriFull': 'Friday',
      'daySatFull': 'Saturday',
      'daySunFull': 'Sunday',
      'serviceNoteHint':
          'Describe what you need (e.g. "I need help with shopping and prescription pickups.")',
      'escortInfo':
          'Escort services may take longer than the selected duration (e.g. waiting at the doctor). If the service takes longer, the difference is charged additionally.',
      'overtimeDisclaimer':
          'Payment is charged 30 minutes before the service starts. If the service takes longer than the selected duration, additional time is charged by agreement.',
      'orderSummaryFrequency': 'Frequency',
      'orderSummaryDays': 'Selected days',
      'orderSummaryServices': 'Selected services',
      'orderSummaryNotes': 'Note',
      'studentName': 'Student name',
      'orderSummaryDate': 'Date',
      'orderSummaryTime': 'Time',
      'orderSummaryDuration': 'Duration',
      'orderSummaryStartDate': 'Start',
      'orderSummaryEndDate': 'End',
      'orderSummaryPrice': 'Price',
      'orderSummaryTotal': 'Total',
      'orderSummaryWeeklyTotal': 'Weekly total',
      'noNotes': 'No notes',
      'orderMessage': 'Message (optional)',
      'orderMessageHint': 'Write a message or additional information...',

      // ── Općenito ──────────────────────────────
      'loading': 'Loading...',
      'error': 'Error',
      'orderCreateError': 'Error creating order',
      'retry': 'Try again',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'selectTime': 'Select time',
      'save': 'Save',
      'back': 'Back',
      'next': 'Next',
      'close': 'Close',
      'search': 'Search',
      'noResults': 'No results',
      'ok': 'OK',

      // ── Auth ──────────────────────────────────
      'login': 'Login',
      'register': 'Register',
      'email': 'Email address',
      'password': 'Password',
      'forgotPassword': 'Forgot password?',
      'loggingIn': 'Signing in...',
      'loginError': 'Login error',
      'registrationError': 'Registration error',
      'emailAlreadyExists': 'A user with this email address already exists',
      'registrationSuccess': 'Registration successful! You can now sign in.',
      'fillAllFields': 'Please fill in all required fields',
      'registering': 'Registering...',
      'invalidCredentials': 'Invalid credentials',
      'forgotPasswordTitle': 'Forgot password',
      'forgotPasswordSubtitle': 'Enter your email to receive a reset code',
      'sendResetCode': 'Send code',
      'resetCode': 'Reset code',
      'currentPassword': 'Current password',
      'newPassword': 'New password',
      'confirmNewPassword': 'Confirm new password',
      'passwordsMismatch': 'Passwords do not match',
      'resetPasswordButton': 'Reset password',
      'resetPasswordSuccess': 'Password changed successfully',
      'codeSent': 'Code sent to email',
      'backToLogin': 'Back to login',
      'loginButton': 'Sign in',
      'registerButton': 'Sign up',
      'noAccount': "Don't have an account?",
      'hasAccount': 'Already have an account?',
      'chooseRoleTitle': 'Who are you?',
      'chooseRoleSubtitle': 'Choose how you want to use Helpi',
      'roleCustomerTitle': 'I need help',
      'roleCustomerDesc': 'I want to order a service for myself or loved ones',
      'roleStudentTitle': 'I want to help',
      'roleStudentDesc': 'I am a student and want to provide services',
      'firstName': 'First name',
      'lastName': 'Last name',
      'phone': 'Phone number',
      'address': 'Address',
      'addressHint': 'Start typing an address to search',
      'regProfileTitle': 'Complete your profile',
      'regProfileSubtitle': 'We need your details to continue',
      'completeRegistration': 'Complete registration',
      'orderingForOther': 'Ordering for someone else',

      // ── Marketplace ───────────────────────────
      'marketplace': 'Students',
      'filterTitle': 'Filter',
      'filterService': 'Service type',
      'filterDate': 'Date',
      'filterDay': 'Availability',
      'filterAnyDay': 'Any day',
      'filterApply': 'Apply filters',
      'filterClear': 'Clear filters',
      'perHour': '/hour',
      'reviews': 'Reviews',
      'available': 'Available',
      'unavailable': 'Unavailable',

      // ── Vrste usluga ─────────────────────────
      'serviceActivities': 'Activities',
      'serviceShopping': 'Shopping',
      'serviceHousehold': 'Household',
      'serviceCompanionship': 'Companionship',
      'serviceTechHelp': 'Technology',
      'servicePets': 'Pets',

      // ── Time picker ──────────────────────────
      'availableWindow': 'Available: {start} – {end}',
      'startTimeLabel': 'Start time',
      'durationLabel': 'Duration',
      'hourSingular': 'hour',
      'hourPlural': 'hours',
      'aboutStudent': 'About student',

      // ── Ponavljanje ──────────────────────────
      'oneTime': 'Once',
      'recurring': 'Recurring',
      'continuous': 'Weekly',
      'untilDate': 'Until date',
      'hasEndDate': 'Until a specific date',
      'selectEndDate': 'Select last session',
      'recurringNoEnd': 'Recurring',
      'recurringWithEnd': 'Until {date}',
      'lastSessionLabel': 'Last session',
      'recurringUntilDateInfo':
          'Booking runs until {date}. '
          'It stops automatically after that date.',
      'noEndDate': 'No end date',
      'everyWeek': 'Every',
      'dayMon': 'Mon',
      'dayTue': 'Tue',
      'dayWed': 'Wed',
      'dayThu': 'Thu',
      'dayFri': 'Fri',
      'daySat': 'Sat',
      'daySun': 'Sun',
      'dayMonShort': 'Mo',
      'dayTueShort': 'Tu',
      'dayWedShort': 'We',
      'dayThuShort': 'Th',
      'dayFriShort': 'Fr',
      'daySatShort': 'Sa',
      'daySunShort': 'Su',
      'perSession': '/session',
      'recurringLabel': '{days} — {end}',
      'configureAllDays': 'Select time for all days',
      'notConfigured': 'Not configured',

      // ── Booking ───────────────────────────────
      'availability': 'Availability',
      'booking': 'Booking',
      'selectSlot': 'Select time slot',
      'orderSummary': 'Order summary',
      'placeOrder': 'Place order',
      'orderConfirmed': 'Order confirmed!',
      'orderNotes': 'Additional notes',
      'totalPrice': 'Total price',
      'bookingServiceHeader': 'What do you need?',
      'bookingChipShopping': 'Errands',
      'bookingChipCleaning': 'Home help',
      'bookingChipCompanionship': 'Company',
      'bookingChipWalk': 'Walk',
      'bookingChipEscort': 'Escort',
      'bookingChipOther': 'Other',
      'bookingDisclaimer': 'Students do not provide medical care.',
      'bookingNotesHint': 'E.g. "Milk and bread from the store"',
      'bookNow': 'Book now',

      // ── Payment ───────────────────────────────
      'payment': 'Payment',
      'paymentMethod': 'Payment method',
      'payNow': 'Pay now',
      'paymentSuccess': 'Payment successful!',
      'paymentFailed': 'Payment failed',

      // ── Chat ──────────────────────────────────
      'chat': 'Messages',
      'chatHelpiSupport': 'Helpi Support',
      'chatWelcome': 'Welcome! You can chat with the Helpi team here.',
      'chatHelpOffer':
          'If you have questions about orders or need help, feel free to write to us.',
      'typeMessage': 'Type a message...',
      'sendMessage': 'Send',
      'noMessages': 'No messages',

      // ── Profil ────────────────────────────────
      'profile': 'My profile',
      'editProfile': 'Edit profile',
      'myOrders': 'My orders',
      'noOrders': 'No orders yet',
      'noOrdersSubtitle': 'When you order a service, it will appear here.',
      'ordersProcessing': 'Processing',
      'ordersActive': 'Active',
      'ordersCompleted': 'Completed',
      'ordersCancelled': 'Cancelled',
      'ordersInactive': 'Inactive',
      'orderProcessing': 'Processing',
      'orderActive': 'Active',
      'orderCompleted': 'Completed',
      'orderCancelled': 'Cancelled',
      'orderArchived': 'Archived',
      'cancelOrder': 'Cancel order',
      'repeatOrder': 'Repeat order',
      'orderPlaced': 'Order placed!',
      'noOrdersInCategory': 'No orders in this category',
      'orderNumber': 'Order #{number}',
      'showMore': 'Show more',
      'showLess': 'Show less',
      'orderDetails': 'Order details',
      'studentsSection': 'Students',
      'jobsSection': 'Sessions',
      'jobsMonthlySubtitle': 'Showing sessions for the current month.',
      'jobCompleted': 'Completed',
      'jobUpcoming': 'Upcoming',
      'jobCancelled': 'Cancelled',
      'cancelJobLabel': 'Cancel',
      'cancelJobConfirm': 'Are you sure you want to cancel this session?',
      'jobStudent': 'Student',
      'assignedSince': 'Assigned since',
      'rateStudent': 'Rate',
      'sendReview': 'Send review',
      'reviewHint': 'Comment (optional)',
      'yourReviews': 'Your reviews',
      'noStudentsYet': 'No students assigned yet',
      'logout': 'Log out',
      'deleteAccount': 'Delete Account',
      'deleteAccountConfirmTitle': 'Delete Account',
      'deleteAccountConfirmContent':
          'Are you sure you want to delete your account? This action cannot be undone.',
      'deleteAccountNo': 'No',
      'deleteAccountYes': 'Yes',
      'deleteAccountSuccess': 'Account successfully deleted.',
      'deleteAccountError': 'Error deleting account.',
      'loginTitle': 'Welcome to Helpi',
      'loginSubtitle': 'Sign in or create an account',
      'loginEmail': 'Email address',
      'loginPassword': 'Password',
      'settings': 'Settings',
      'language': 'Language',
      'accessData': 'Account details',
      'changePassword': 'Change password',
      'ordererData': 'Orderer details',
      'seniorData': 'Senior details',
      'gender': 'Gender',
      'genderMale': 'Male',
      'genderFemale': 'Female',
      'dateOfBirth': 'Date of birth',
      'dobPlaceholder': 'DD.MM.YYYY.',
      'langHr': 'Hrvatski',
      'langEn': 'English',
      'langHrvatski': 'Hrvatski',
      'langEnglish': 'English',
      'appVersion': 'Helpi v2.0.0',
      'creditCards': 'Credit cards',
      'noCards': 'No saved cards',
      'addCard': 'Add card',
      'promoCode': 'Promo code',
      'promoCodeHint': 'Enter promo code',
      'promoCodeApply': 'Apply',
      'promoCodeInvalid': 'Invalid promo code',
      'promoCodeValidating': 'Validating...',
      'promoCodeDiscount': 'Discount: {amount}',
      'promoCodeApplied': 'Promo code applied',
      'agreeToTerms': 'I agree to the ',
      'termsOfUse': 'terms',
      'byClickingRegister':
          'By clicking "Complete registration" you accept the ',
      'termsOfUseLink': 'terms of use',
      'cardEndingIn': 'Card ending in {digits}',

      // ── Schedule (student) ────────────────────
      'scheduleTitle': 'Schedule',
      'scheduleToday': 'Today',
      'scheduleTomorrow': 'Tomorrow',
      'scheduleNoJobs': 'No jobs scheduled for this day.',
      'scheduleNoJobsSubtitle': 'Enjoy your free time!',
      'jobDetailTitle': 'Job details',
      'jobSenior': 'Client',
      'jobAddress': 'Address',
      'jobTime': 'Time',
      'jobService': 'Service',
      'jobNotes': 'Notes',
      'jobStatusScheduled': 'Scheduled',
      'jobStatusCompleted': 'Completed',
      'jobStatusCancelled': 'Cancelled',
      'jobDecline': "Can't do it",
      'jobDeclineTitle': 'Cancel job',
      'jobDeclineHint': 'Write the reason for cancellation...',
      'jobDeclineConfirm': 'Submit',
      'jobDeclineTooLate': 'Cannot cancel less than 24h before the start.',
      'jobDeclineSuccess': 'Job cancelled.',
      'rateSenior': 'Rate',
      'yourReview': 'Your review',
      'reviewSent': 'Review sent.',
      'serviceShopping2': 'Shopping',
      'serviceHouseHelp2': 'House help',
      'serviceCompanionship2': 'Companionship',
      'serviceWalking2': 'Walking',
      'serviceEscort2': 'Escort',
      'serviceOther2': 'Other',

      // ── Statistics ────────────────────────────
      'statsTitle': 'Statistics',
      'statsTotalJobs': 'Total jobs',
      'statsTotalHours': 'Hours worked',
      'statsAvgRating': 'Average rating',
      'statsRecentReviews': 'Recent reviews',
      'statsNoReviews': 'No reviews yet.',
      'statsWeeklyReview': 'Weekly review',
      'statsMonthlyReview': 'Monthly review',
      'statsTotalHoursValue': '{hours} hours worked total',
      'statsCompareMore':
          'Your hours worked are {percent}% higher compared to the previous {period}.',
      'statsCompareLess':
          'Your hours worked are {percent}% lower compared to the previous {period}.',
      'statsCompareSame': 'Same hours as the previous {period}.',
      'statsPeriodWeek': 'week',
      'statsPeriodMonth': 'month',
      'statsShowAllReviews': 'Show all reviews',
      'statsAllReviews': 'All reviews',
      'statsDayMon': 'M',
      'statsDayTue': 'T',
      'statsDayWed': 'W',
      'statsDayThu': 'T',
      'statsDayFri': 'F',
      'statsDaySat': 'S',
      'statsDaySun': 'S',

      // ── Availability (student) ────────────────
      'availabilitySection': 'Availability',
      'availabilityDescription':
          'Select the days and times when you are available to help.',
      'toTime': 'To',
      'notSet': 'Not set',
      'studentData': 'Personal info',
      'faculty': 'Faculty',
      'facultyHint': 'Select faculty',
      'facultyPickerTitle': 'Select faculty',
      'facultySearchHint': 'Search by acronym or name',
      'facultyNoResults': 'No results',
      'studentIdCard': 'Student ID card number',
      'studentIdCardHint': 'E.g. 0036512345',
      'registrationDataTitle': 'Your details',
      'registrationDataSubtitle':
          'Fill in your details so we can create your profile.',
      'registrationDataNext': 'Next',
      'onboardingTitle': 'When are you available?',
      'onboardingSubtitle':
          'Set your availability so we can send you relevant orders.',
      'onboardingFinish': 'Finish',
      'onboardingMinDay': 'Select at least 1 day with a time range.',

      // ── Parametrizirani ───────────────────────
      'deleteConfirm': 'Delete {item}?',
      'distanceKm': '{km} km',
      'pricePerHour': '€{price}/hour',
      'sundayRate': 'Sunday (higher rate)',
      'ratingCount': '{count} Reviews',
      'welcomeUser': 'Welcome, {name}!',
      'orderForStudent': 'Order for {student}',
      'slotTime': '{start} - {end}',

      // ── Calendar ───────────────────────────
      'month1': 'January',
      'month2': 'February',
      'month3': 'March',
      'month4': 'April',
      'month5': 'May',
      'month6': 'June',
      'month7': 'July',
      'month8': 'August',
      'month9': 'September',
      'month10': 'October',
      'month11': 'November',
      'month12': 'December',
      'calendarFree': 'Available',
      'calendarPartial': 'Partial',
      'calendarBooked': 'Booked',
      'selectDatePrompt': 'Select a date to book',
      'freeHoursCount': '{free} of {total} hours available',
      'allHoursFree': 'All hours available',
      'recurringConfirmed': 'Confirmed: {count}',
      'recurringSkipped': 'Skipped: {count}',
      'sessionsLabel': 'Sessions',
      'recurringFree': 'Available',
      'recurringOccupied': 'Booked',
      'recurringPartial': '{start}-{end} available',
      'recurringTotalPrice': 'Total ({count} sessions)',
      'recurringPerVisitPrice': '€{price}/session',
      'recurringBillingInfo': 'Charged to your card 30 min before each visit.',
      'recurringMonthTitle': 'Every {day} in {month}',
      'recurringDaysLabel': 'Days',
      'recurringOutsideWindow': 'Outside hours',
      'recurringAutoRenew':
          'This booking is valid until the end of {month}. '
          'It auto-renews next month if the student extends '
          'availability. You can cancel anytime.',

      // ── Suspension ────────────────────────────────────
      'suspendedTitle': 'Account Suspended',
      'suspendedMessage': 'Your account has been temporarily suspended.',
      'suspendedReason': 'Reason: {reason}',
      'suspendedContact': 'For more information, contact support:',
      'suspendedEmail': 'support@helpi.hr',
      'suspendedLogout': 'Log out',

      // ── Server Unavailable ────────────────────────
      'serverUnavailableTitle': 'Server Unavailable',
      'serverUnavailableMessage':
          'Unable to connect to server. Please check your internet connection and try again.',
      'serverUnavailableRetrying': 'Retrying...',
      'serverUnavailableRetry': 'Retry',
    },
  };

  // ─── Interni getter s parametrima ───────────────────────────────
  static String _t(String key, {Map<String, String>? params}) {
    String value = _localizedValues[_currentLocale]?[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATIC GETTERS — koriste se u UI-ju: AppStrings.appName
  // ═══════════════════════════════════════════════════════════════

  // ── App ───────────────────────────────────────
  static String get appName => _t('appName');
  static String get appTagline => _t('appTagline');

  // ── Suspenzija ──
  static String get suspendedTitle => _t('suspendedTitle');
  static String get suspendedMessage => _t('suspendedMessage');
  static String suspendedReason(String reason) =>
      _t('suspendedReason', params: {'reason': reason});
  static String get suspendedContact => _t('suspendedContact');
  static String get suspendedEmail => _t('suspendedEmail');
  static String get suspendedLogout => _t('suspendedLogout');
  static String get quickActionsTitle => _t('quickActionsTitle');
  static String get topBadge => _t('topBadge');

  // ── Navigacija ────────────────────────────────
  static String get navHome => _t('navHome');
  static String get navOrder => _t('navOrder');
  static String get navStudents => _t('navStudents');
  static String get navOrders => _t('navOrders');
  static String get navMessages => _t('navMessages');
  static String get navProfile => _t('navProfile');
  static String get navSchedule => _t('navSchedule');
  static String get navStatistics => _t('navStatistics');

  // ── Naruči ekran ──────────────────────────────
  static String get orderTitle => _t('orderTitle');
  static String get orderSubtitle => _t('orderSubtitle');

  // ── Order flow ────────────────────────────
  static String get newOrder => _t('newOrder');
  static String get orderFlowStep1 => _t('orderFlowStep1');
  static String get orderFlowStep2 => _t('orderFlowStep2');
  static String get orderFlowStep3 => _t('orderFlowStep3');
  static String stepIndicator(String current, String total) =>
      _t('stepIndicator', params: {'current': current, 'total': total});
  static String get frequency => _t('frequency');
  static String get addDay => _t('addDay');
  static String get selectDay => _t('selectDay');
  static String get fromTime => _t('fromTime');
  static String get hourLabel => _t('hourLabel');
  static String get minuteLabel => _t('minuteLabel');
  static String get durationChoice => _t('durationChoice');
  static String get hour1 => _t('hour1');
  static String get hour2 => _t('hour2');
  static String get hour3 => _t('hour3');
  static String get hour4 => _t('hour4');
  static String get selectDate => _t('selectDate');
  static String get dayMonFull => _t('dayMonFull');
  static String get dayTueFull => _t('dayTueFull');
  static String get dayWedFull => _t('dayWedFull');
  static String get dayThuFull => _t('dayThuFull');
  static String get dayFriFull => _t('dayFriFull');
  static String get daySatFull => _t('daySatFull');
  static String get daySunFull => _t('daySunFull');
  static String get hasEndDate => _t('hasEndDate');
  static String get recurringNoEnd => _t('recurringNoEnd');
  static String recurringWithEnd(String date) =>
      _t('recurringWithEnd', params: {'date': date});
  static String get serviceNoteHint => _t('serviceNoteHint');
  static String get selectStartDate => _t('selectStartDate');
  static String firstServiceDate(String date) =>
      _t('firstServiceDate', params: {'date': date});
  static String dayNotInRange(String day) =>
      _t('dayNotInRange', params: {'day': day});
  static String get escortInfo => _t('escortInfo');
  static String get overtimeDisclaimer => _t('overtimeDisclaimer');
  static String get orderSummaryFrequency => _t('orderSummaryFrequency');
  static String get orderSummaryDays => _t('orderSummaryDays');
  static String get orderSummaryServices => _t('orderSummaryServices');
  static String get orderSummaryNotes => _t('orderSummaryNotes');
  static String get studentName => _t('studentName');
  static String get orderSummaryDate => _t('orderSummaryDate');
  static String get orderSummaryTime => _t('orderSummaryTime');
  static String get orderSummaryDuration => _t('orderSummaryDuration');
  static String get orderSummaryStartDate => _t('orderSummaryStartDate');
  static String get orderSummaryPrice => _t('orderSummaryPrice');
  static String get orderSummaryTotal => _t('orderSummaryTotal');
  static String get orderSummaryWeeklyTotal => _t('orderSummaryWeeklyTotal');
  static String get orderSummaryEndDate => _t('orderSummaryEndDate');
  static String get noNotes => _t('noNotes');
  static String get orderMessage => _t('orderMessage');
  static String get orderMessageHint => _t('orderMessageHint');

  // ── Općenito ──────────────────────────────────
  static String get loading => _t('loading');
  static String get error => _t('error');
  static String get orderCreateError => _t('orderCreateError');
  static String get retry => _t('retry');
  static String get cancel => _t('cancel');
  static String get confirm => _t('confirm');
  static String get selectTime => _t('selectTime');
  static String get save => _t('save');
  static String get back => _t('back');
  static String get next => _t('next');
  static String get close => _t('close');
  static String get search => _t('search');
  static String get noResults => _t('noResults');
  static String get ok => _t('ok');

  // ── Auth ──────────────────────────────────────
  static String get login => _t('login');
  static String get register => _t('register');
  static String get email => _t('email');
  static String get password => _t('password');
  static String get forgotPassword => _t('forgotPassword');
  static String get loggingIn => _t('loggingIn');
  static String get loginError => _t('loginError');
  static String get registrationError => _t('registrationError');
  static String get emailAlreadyExists => _t('emailAlreadyExists');
  static String get registrationSuccess => _t('registrationSuccess');
  static String get fillAllFields => _t('fillAllFields');
  static String get registering => _t('registering');
  static String get invalidCredentials => _t('invalidCredentials');
  static String get forgotPasswordTitle => _t('forgotPasswordTitle');
  static String get forgotPasswordSubtitle => _t('forgotPasswordSubtitle');
  static String get sendResetCode => _t('sendResetCode');
  static String get resetCode => _t('resetCode');
  static String get currentPassword => _t('currentPassword');
  static String get newPassword => _t('newPassword');
  static String get confirmNewPassword => _t('confirmNewPassword');
  static String get passwordsMismatch => _t('passwordsMismatch');
  static String get resetPasswordButton => _t('resetPasswordButton');
  static String get resetPasswordSuccess => _t('resetPasswordSuccess');
  static String get codeSent => _t('codeSent');
  static String get backToLogin => _t('backToLogin');
  static String get loginButton => _t('loginButton');
  static String get registerButton => _t('registerButton');
  static String get noAccount => _t('noAccount');
  static String get hasAccount => _t('hasAccount');
  static String get chooseRoleTitle => _t('chooseRoleTitle');
  static String get chooseRoleSubtitle => _t('chooseRoleSubtitle');
  static String get roleCustomerTitle => _t('roleCustomerTitle');
  static String get roleCustomerDesc => _t('roleCustomerDesc');
  static String get roleStudentTitle => _t('roleStudentTitle');
  static String get roleStudentDesc => _t('roleStudentDesc');
  static String get firstName => _t('firstName');
  static String get lastName => _t('lastName');
  static String get phone => _t('phone');
  static String get address => _t('address');
  static String get addressHint => _t('addressHint');
  static String get regProfileTitle => _t('regProfileTitle');
  static String get regProfileSubtitle => _t('regProfileSubtitle');
  static String get completeRegistration => _t('completeRegistration');
  static String get orderingForOther => _t('orderingForOther');

  // ── Marketplace ───────────────────────────────
  static String get marketplace => _t('marketplace');
  static String get filterTitle => _t('filterTitle');
  static String get filterService => _t('filterService');
  static String get filterDate => _t('filterDate');
  static String get filterDay => _t('filterDay');
  static String get filterAnyDay => _t('filterAnyDay');
  static String get filterApply => _t('filterApply');
  static String get filterClear => _t('filterClear');
  static String get perHour => _t('perHour');
  static String get reviews => _t('reviews');
  static String get available => _t('available');
  static String get unavailable => _t('unavailable');

  // ── Vrste usluga ─────────────────────────────
  static String get serviceActivities => _t('serviceActivities');
  static String get serviceShopping => _t('serviceShopping');
  static String get serviceHousehold => _t('serviceHousehold');
  static String get serviceCompanionship => _t('serviceCompanionship');
  static String get serviceTechHelp => _t('serviceTechHelp');
  static String get servicePets => _t('servicePets');

  // ── Time picker ──────────────────────────────
  static String availableWindow(String start, String end) =>
      _t('availableWindow', params: {'start': start, 'end': end});
  static String get startTimeLabel => _t('startTimeLabel');
  static String get durationLabel => _t('durationLabel');
  static String get hourSingular => _t('hourSingular');
  static String get hourPlural => _t('hourPlural');
  static String get aboutStudent => _t('aboutStudent');

  // ── Ponavljanje ──────────────────────────────
  static String get oneTime => _t('oneTime');
  static String get recurring => _t('recurring');
  static String get continuous => _t('continuous');
  static String get untilDateLabel => _t('untilDate');
  static String get selectEndDate => _t('selectEndDate');
  static String get lastSessionLabel => _t('lastSessionLabel');
  static String recurringUntilDateInfo(String date) =>
      _t('recurringUntilDateInfo', params: {'date': date});
  static String get noEndDate => _t('noEndDate');
  static String untilDate(String date) =>
      _t('untilDate', params: {'date': date});
  static String get everyWeek => _t('everyWeek');
  static String get dayMon => _t('dayMon');
  static String get dayTue => _t('dayTue');
  static String get dayWed => _t('dayWed');
  static String get dayThu => _t('dayThu');
  static String get dayFri => _t('dayFri');
  static String get daySat => _t('daySat');
  static String get daySun => _t('daySun');
  static String get dayMonShort => _t('dayMonShort');
  static String get dayTueShort => _t('dayTueShort');
  static String get dayWedShort => _t('dayWedShort');
  static String get dayThuShort => _t('dayThuShort');
  static String get dayFriShort => _t('dayFriShort');
  static String get daySatShort => _t('daySatShort');
  static String get daySunShort => _t('daySunShort');
  static String get perSession => _t('perSession');
  static String get configureAllDays => _t('configureAllDays');
  static String get notConfigured => _t('notConfigured');
  static String recurringLabel(String days, String end) =>
      _t('recurringLabel', params: {'days': end});

  // ── Booking ───────────────────────────────────
  static String get availability => _t('availability');
  static String get booking => _t('booking');
  static String get selectSlot => _t('selectSlot');
  static String get orderSummary => _t('orderSummary');
  static String get placeOrder => _t('placeOrder');
  static String get orderConfirmed => _t('orderConfirmed');
  static String get orderNotes => _t('orderNotes');
  static String get totalPrice => _t('totalPrice');
  static String get bookingServiceHeader => _t('bookingServiceHeader');
  static String get bookingChipShopping => _t('bookingChipShopping');
  static String get bookingChipCleaning => _t('bookingChipCleaning');
  static String get bookingChipCompanionship => _t('bookingChipCompanionship');
  static String get bookingChipWalk => _t('bookingChipWalk');
  static String get bookingChipEscort => _t('bookingChipEscort');
  static String get bookingChipOther => _t('bookingChipOther');
  static String get bookingDisclaimer => _t('bookingDisclaimer');
  static String get bookingNotesHint => _t('bookingNotesHint');
  static String get bookNow => _t('bookNow');

  // ── Payment ───────────────────────────────────
  static String get payment => _t('payment');
  static String get paymentMethod => _t('paymentMethod');
  static String get payNow => _t('payNow');
  static String get paymentSuccess => _t('paymentSuccess');
  static String get paymentFailed => _t('paymentFailed');

  // ── Chat ──────────────────────────────────────
  static String get chat => _t('chat');
  static String get chatHelpiSupport => _t('chatHelpiSupport');
  static String get chatWelcome => _t('chatWelcome');
  static String get chatHelpOffer => _t('chatHelpOffer');
  static String get typeMessage => _t('typeMessage');
  static String get sendMessage => _t('sendMessage');
  static String get noMessages => _t('noMessages');

  // ── Profil ────────────────────────────────────
  static String get profile => _t('profile');
  static String get editProfile => _t('editProfile');
  static String get myOrders => _t('myOrders');
  static String get noOrders => _t('noOrders');
  static String get noOrdersSubtitle => _t('noOrdersSubtitle');
  static String get ordersProcessing => _t('ordersProcessing');
  static String get ordersActive => _t('ordersActive');
  static String get ordersCompleted => _t('ordersCompleted');
  static String get ordersCancelled => _t('ordersCancelled');
  static String get ordersInactive => _t('ordersInactive');
  static String get orderProcessing => _t('orderProcessing');
  static String get orderActive => _t('orderActive');
  static String get orderCompleted => _t('orderCompleted');
  static String get orderCancelled => _t('orderCancelled');
  static String get orderArchived => _t('orderArchived');
  static String get cancelOrder => _t('cancelOrder');
  static String get repeatOrder => _t('repeatOrder');
  static String get orderPlaced => _t('orderPlaced');
  static String get noOrdersInCategory => _t('noOrdersInCategory');
  static String orderNumber(String number) =>
      _t('orderNumber', params: {'number': number});
  static String get showMore => _t('showMore');
  static String get showLess => _t('showLess');
  static String get orderDetails => _t('orderDetails');
  static String get studentsSection => _t('studentsSection');
  static String get jobsSection => _t('jobsSection');
  static String get jobsMonthlySubtitle => _t('jobsMonthlySubtitle');
  static String get jobCompleted => _t('jobCompleted');
  static String get jobUpcoming => _t('jobUpcoming');
  static String get jobCancelled => _t('jobCancelled');
  static String get cancelJobLabel => _t('cancelJobLabel');
  static String get cancelJobConfirm => _t('cancelJobConfirm');
  static String get jobStudent => _t('jobStudent');
  static String get assignedSince => _t('assignedSince');
  static String get rateStudent => _t('rateStudent');
  static String get sendReview => _t('sendReview');
  static String get reviewHint => _t('reviewHint');
  static String get yourReviews => _t('yourReviews');
  static String get noStudentsYet => _t('noStudentsYet');
  static String get logout => _t('logout');
  static String get deleteAccount => _t('deleteAccount');
  static String get deleteAccountConfirmTitle =>
      _t('deleteAccountConfirmTitle');
  static String get deleteAccountConfirmContent =>
      _t('deleteAccountConfirmContent');
  static String get deleteAccountNo => _t('deleteAccountNo');
  static String get deleteAccountYes => _t('deleteAccountYes');
  static String get deleteAccountSuccess => _t('deleteAccountSuccess');
  static String get deleteAccountError => _t('deleteAccountError');
  static String get loginTitle => _t('loginTitle');
  static String get loginSubtitle => _t('loginSubtitle');
  static String get loginEmail => _t('loginEmail');
  static String get loginPassword => _t('loginPassword');
  static String get settings => _t('settings');
  static String get language => _t('language');
  static String get accessData => _t('accessData');
  static String get changePassword => _t('changePassword');
  static String get ordererData => _t('ordererData');
  static String get seniorData => _t('seniorData');
  static String get gender => _t('gender');
  static String get genderMale => _t('genderMale');
  static String get genderFemale => _t('genderFemale');
  static String get dateOfBirth => _t('dateOfBirth');
  static String get dobPlaceholder => _t('dobPlaceholder');
  static String get langHr => _t('langHr');
  static String get langEn => _t('langEn');
  static String get langHrvatski => _t('langHrvatski');
  static String get langEnglish => _t('langEnglish');
  static String get appVersion => _t('appVersion');
  static String get creditCards => _t('creditCards');
  static String get noCards => _t('noCards');
  static String get addCard => _t('addCard');
  static String get promoCode => _t('promoCode');
  static String get promoCodeHint => _t('promoCodeHint');
  static String get promoCodeApply => _t('promoCodeApply');
  static String get promoCodeInvalid => _t('promoCodeInvalid');
  static String get promoCodeValidating => _t('promoCodeValidating');
  static String promoCodeDiscount(String amount) =>
      _t('promoCodeDiscount', params: {'amount': amount});
  static String get promoCodeApplied => _t('promoCodeApplied');
  static String get agreeToTerms => _t('agreeToTerms');
  static String get termsOfUse => _t('termsOfUse');
  static String get byClickingRegister => _t('byClickingRegister');
  static String get termsOfUseLink => _t('termsOfUseLink');
  static String cardEndingIn(String digits) =>
      _t('cardEndingIn', params: {'digits': digits});

  // ── Raspored (schedule) ───────────────────────
  static String get scheduleTitle => _t('scheduleTitle');
  static String get scheduleToday => _t('scheduleToday');
  static String get scheduleTomorrow => _t('scheduleTomorrow');
  static String get scheduleNoJobs => _t('scheduleNoJobs');
  static String get scheduleNoJobsSubtitle => _t('scheduleNoJobsSubtitle');
  static String get jobDetailTitle => _t('jobDetailTitle');
  static String get jobSenior => _t('jobSenior');
  static String get jobAddress => _t('jobAddress');
  static String get jobTime => _t('jobTime');
  static String get jobService => _t('jobService');
  static String get jobNotes => _t('jobNotes');
  static String get jobStatusScheduled => _t('jobStatusScheduled');
  static String get jobStatusCompleted => _t('jobStatusCompleted');
  static String get jobStatusCancelled => _t('jobStatusCancelled');
  static String get jobDecline => _t('jobDecline');
  static String get jobDeclineTitle => _t('jobDeclineTitle');
  static String get jobDeclineHint => _t('jobDeclineHint');
  static String get jobDeclineConfirm => _t('jobDeclineConfirm');
  static String get jobDeclineTooLate => _t('jobDeclineTooLate');
  static String get jobDeclineSuccess => _t('jobDeclineSuccess');
  static String get rateSenior => _t('rateSenior');
  static String get yourReview => _t('yourReview');
  static String get reviewSent => _t('reviewSent');
  static String get serviceShopping2 => _t('serviceShopping2');
  static String get serviceHouseHelp2 => _t('serviceHouseHelp2');
  static String get serviceCompanionship2 => _t('serviceCompanionship2');
  static String get serviceWalking2 => _t('serviceWalking2');
  static String get serviceEscort2 => _t('serviceEscort2');
  static String get serviceOther2 => _t('serviceOther2');

  // ── Statistika ────────────────────────────────
  static String get statsTitle => _t('statsTitle');
  static String get statsTotalJobs => _t('statsTotalJobs');
  static String get statsTotalHours => _t('statsTotalHours');
  static String get statsAvgRating => _t('statsAvgRating');
  static String get statsRecentReviews => _t('statsRecentReviews');
  static String get statsNoReviews => _t('statsNoReviews');
  static String get statsWeeklyReview => _t('statsWeeklyReview');
  static String get statsMonthlyReview => _t('statsMonthlyReview');
  static String statsTotalHoursValue(String hours) =>
      _t('statsTotalHoursValue', params: {'hours': hours});
  static String statsCompareMore(String percent, String period) =>
      _t('statsCompareMore', params: {'percent': percent, 'period': period});
  static String statsCompareLess(String percent, String period) =>
      _t('statsCompareLess', params: {'percent': percent, 'period': period});
  static String statsCompareSame(String period) =>
      _t('statsCompareSame', params: {'period': period});
  static String get statsPeriodWeek => _t('statsPeriodWeek');
  static String get statsPeriodMonth => _t('statsPeriodMonth');
  static String get statsShowAllReviews => _t('statsShowAllReviews');
  static String get statsAllReviews => _t('statsAllReviews');
  static String get statsDayMon => _t('statsDayMon');
  static String get statsDayTue => _t('statsDayTue');
  static String get statsDayWed => _t('statsDayWed');
  static String get statsDayThu => _t('statsDayThu');
  static String get statsDayFri => _t('statsDayFri');
  static String get statsDaySat => _t('statsDaySat');
  static String get statsDaySun => _t('statsDaySun');
  static List<String> get statsDayLabels => [
    statsDayMon,
    statsDayTue,
    statsDayWed,
    statsDayThu,
    statsDayFri,
    statsDaySat,
    statsDaySun,
  ];

  // ── Dostupnost (student) ──────────────────────
  static String get availabilitySection => _t('availabilitySection');
  static String get availabilityDescription => _t('availabilityDescription');
  static String get toTime => _t('toTime');
  static String get notSet => _t('notSet');
  static String get studentData => _t('studentData');
  static String get faculty => _t('faculty');
  static String get facultyHint => _t('facultyHint');
  static String get facultyPickerTitle => _t('facultyPickerTitle');
  static String get facultySearchHint => _t('facultySearchHint');
  static String get facultyNoResults => _t('facultyNoResults');
  static String get studentIdCard => _t('studentIdCard');
  static String get studentIdCardHint => _t('studentIdCardHint');
  static String get registrationDataTitle => _t('registrationDataTitle');
  static String get registrationDataSubtitle => _t('registrationDataSubtitle');
  static String get registrationDataNext => _t('registrationDataNext');
  static String get onboardingTitle => _t('onboardingTitle');
  static String get onboardingSubtitle => _t('onboardingSubtitle');
  static String get onboardingFinish => _t('onboardingFinish');
  static String get onboardingMinDay => _t('onboardingMinDay');

  // ── Parametrizirani stringovi ─────────────────
  static String deleteConfirm(String item) =>
      _t('deleteConfirm', params: {'item': item});
  static String distanceKm(String km) => _t('distanceKm', params: {'km': km});
  static String pricePerHour(String price) =>
      _t('pricePerHour', params: {'price': price});
  static String get sundayRate => _t('sundayRate');
  static String ratingCount(String count) =>
      _t('ratingCount', params: {'count': count});
  static String welcomeUser(String name) =>
      _t('welcomeUser', params: {'name': name});
  static String orderForStudent(String student) =>
      _t('orderForStudent', params: {'student': student});
  static String slotTime(String start, String end) =>
      _t('slotTime', params: {'start': start, 'end': end});

  // ── Kalendar ───────────────────────────
  static String monthName(int month) => _t('month$month');
  static String get calendarFree => _t('calendarFree');
  static String get calendarPartial => _t('calendarPartial');
  static String get calendarBooked => _t('calendarBooked');
  static String get selectDatePrompt => _t('selectDatePrompt');
  static String freeHoursCount(String free, String total) =>
      _t('freeHoursCount', params: {'free': free, 'total': total});
  static String get allHoursFree => _t('allHoursFree');
  static String recurringConfirmed(String count) =>
      _t('recurringConfirmed', params: {'count': count});
  static String recurringSkipped(String count) =>
      _t('recurringSkipped', params: {'count': count});
  static String get sessionsLabel => _t('sessionsLabel');
  static String get recurringFree => _t('recurringFree');
  static String get recurringOccupied => _t('recurringOccupied');
  static String recurringPartial(String start, String end) =>
      _t('recurringPartial', params: {'start': start, 'end': end});
  static String recurringTotalPrice(String count) =>
      _t('recurringTotalPrice', params: {'count': count});
  static String recurringPerVisitPrice(String price) =>
      _t('recurringPerVisitPrice', params: {'price': price});
  static String get recurringBillingInfo => _t('recurringBillingInfo');
  static String recurringMonthTitle(String day, String month) =>
      _t('recurringMonthTitle', params: {'day': day, 'month': month});
  static String get recurringDaysLabel => _t('recurringDaysLabel');
  static String get recurringOutsideWindow => _t('recurringOutsideWindow');
  static String recurringAutoRenew(String month) =>
      _t('recurringAutoRenew', params: {'month': month});

  // ── Server nedostupan ──
  static String get serverUnavailableTitle => _t('serverUnavailableTitle');
  static String get serverUnavailableMessage => _t('serverUnavailableMessage');
  static String get serverUnavailableRetrying =>
      _t('serverUnavailableRetrying');
  static String get serverUnavailableRetry => _t('serverUnavailableRetry');
}

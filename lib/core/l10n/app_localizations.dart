import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  static final Map<String, Map<String, String>> _strings = {
    // ── General ──────────────────────────────────────────────────────────
    'appName': {'en': 'Louage', 'fr': 'Louage', 'ar': 'لواج'},
    'cancel': {'en': 'Cancel', 'fr': 'Annuler', 'ar': 'إلغاء'},
    'confirm': {'en': 'Confirm', 'fr': 'Confirmer', 'ar': 'تأكيد'},
    'delete': {'en': 'Delete', 'fr': 'Supprimer', 'ar': 'حذف'},
    'retry': {'en': 'Retry', 'fr': 'Réessayer', 'ar': 'إعادة المحاولة'},
    'logout': {'en': 'Logout', 'fr': 'Se déconnecter', 'ar': 'تسجيل الخروج'},
    'save': {'en': 'Save', 'fr': 'Enregistrer', 'ar': 'حفظ'},
    'add': {'en': 'Add', 'fr': 'Ajouter', 'ar': 'إضافة'},
    'close': {'en': 'Close', 'fr': 'Fermer', 'ar': 'إغلاق'},
    'yes': {'en': 'Yes', 'fr': 'Oui', 'ar': 'نعم'},
    'no': {'en': 'No', 'fr': 'Non', 'ar': 'لا'},
    'ok': {'en': 'OK', 'fr': 'OK', 'ar': 'موافق'},
    'error': {'en': 'Error', 'fr': 'Erreur', 'ar': 'خطأ'},
    'success': {'en': 'Success', 'fr': 'Succès', 'ar': 'نجاح'},
    'loading': {'en': 'Loading...', 'fr': 'Chargement...', 'ar': 'جار التحميل...'},
    'language': {'en': 'Language', 'fr': 'Langue', 'ar': 'اللغة'},

    // ── Auth ─────────────────────────────────────────────────────────────
    'email': {'en': 'Email', 'fr': 'E-mail', 'ar': 'البريد الإلكتروني'},
    'password': {'en': 'Password', 'fr': 'Mot de passe', 'ar': 'كلمة المرور'},
    'firstName': {'en': 'First Name', 'fr': 'Prénom', 'ar': 'الاسم الأول'},
    'lastName': {'en': 'Last Name', 'fr': 'Nom', 'ar': 'اسم العائلة'},
    'phoneNumber': {'en': 'Phone Number', 'fr': 'Numéro de téléphone', 'ar': 'رقم الهاتف'},
    'login': {'en': 'Login', 'fr': 'Connexion', 'ar': 'تسجيل الدخول'},
    'signUp': {'en': 'Sign Up', 'fr': "S'inscrire", 'ar': 'إنشاء حساب'},
    'createAccount': {'en': 'Create Account', 'fr': 'Créer un compte', 'ar': 'إنشاء حساب'},
    'noAccount': {'en': "Don't have an account? Sign Up", 'fr': "Pas de compte ? S'inscrire", 'ar': 'ليس لديك حساب؟ سجل الآن'},
    'haveAccount': {'en': 'Already have an account? Log In', 'fr': 'Déjà un compte ? Se connecter', 'ar': 'لديك حساب بالفعل؟ تسجيل الدخول'},
    'loginFailed': {'en': 'Login failed.', 'fr': 'Échec de la connexion.', 'ar': 'فشل تسجيل الدخول.'},
    'enterEmail': {'en': 'Enter your email', 'fr': 'Entrez votre e-mail', 'ar': 'أدخل بريدك الإلكتروني'},
    'enterPassword': {'en': 'Enter your password', 'fr': 'Entrez votre mot de passe', 'ar': 'أدخل كلمة المرور'},
    'enterFirstName': {'en': 'Enter your first name', 'fr': 'Entrez votre prénom', 'ar': 'أدخل اسمك الأول'},
    'enterLastName': {'en': 'Enter your last name', 'fr': 'Entrez votre nom', 'ar': 'أدخل اسم عائلتك'},
    'enterPhone': {'en': 'Enter your phone number', 'fr': 'Entrez votre numéro de téléphone', 'ar': 'أدخل رقم هاتفك'},
    'passwordMin': {'en': 'Password must be at least 6 characters', 'fr': 'Le mot de passe doit contenir au moins 6 caractères', 'ar': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل'},
    'passenger': {'en': 'Passenger', 'fr': 'Passager', 'ar': 'راكب'},
    'driver': {'en': 'Driver', 'fr': 'Chauffeur', 'ar': 'سائق'},
    'registerAsDriver': {'en': 'Register as Driver', 'fr': 'S\'inscrire comme chauffeur', 'ar': 'التسجيل كسائق'},
    'signUpAsPassenger': {'en': 'Sign Up as Passenger', 'fr': 'S\'inscrire comme passager', 'ar': 'التسجيل كراكب'},
    'driverNotice': {'en': 'Driver accounts require Admin verification and vehicle assignment before starting work.', 'fr': 'Les comptes chauffeur nécessitent une vérification admin avant de commencer.', 'ar': 'تتطلب حسابات السائقين التحقق من قِبَل المسؤول وتعيين مركبة قبل البدء في العمل.'},
    'licenseNumber': {'en': 'Driver License Number', 'fr': 'Numéro de permis de conduire', 'ar': 'رقم رخصة القيادة'},
    'vehicleInfo': {'en': 'Vehicle Information', 'fr': 'Informations sur le véhicule', 'ar': 'معلومات المركبة'},
    'vehiclePlate': {'en': 'Vehicle Plate (e.g. 123 TUN 4567)', 'fr': 'Plaque du véhicule (ex: 123 TUN 4567)', 'ar': 'لوحة المركبة (مثال: 123 TUN 4567)'},
    'seatingCapacity': {'en': 'Seating Capacity', 'fr': 'Capacité de sièges', 'ar': 'عدد المقاعد'},
    'destinations': {'en': 'Destinations (Min 2 required)', 'fr': 'Destinations (2 min requises)', 'ar': 'الوجهات (مطلوب 2 على الأقل)'},
    'enterLicense': {'en': 'Enter your license number', 'fr': 'Entrez votre numéro de permis', 'ar': 'أدخل رقم رخصتك'},
    'enterPlate': {'en': 'Enter vehicle plate number', 'fr': 'Entrez la plaque du véhicule', 'ar': 'أدخل رقم لوحة المركبة'},
    'capacityMin': {'en': 'Capacity must be at least 2 seats', 'fr': 'La capacité doit être d\'au moins 2 places', 'ar': 'يجب أن تكون السعة مقعدَين على الأقل'},
    'selectMin2Stations': {'en': 'Please select at least 2 stations your louage goes to', 'fr': 'Sélectionnez au moins 2 stations desservies', 'ar': 'يرجى تحديد محطتين على الأقل'},
    'validPhone': {'en': 'Please enter a valid phone number (at least 8 digits)', 'fr': 'Entrez un numéro de téléphone valide (8 chiffres min)', 'ar': 'يرجى إدخال رقم هاتف صحيح (8 أرقام على الأقل)'},
    'registrationFailed': {'en': 'Registration failed.', 'fr': 'Échec de l\'inscription.', 'ar': 'فشل التسجيل.'},
    'provideLicenseAndPlate': {'en': 'Please provide both driver license and vehicle plate', 'fr': 'Veuillez fournir le permis et la plaque', 'ar': 'يرجى تقديم رخصة القيادة ولوحة المركبة'},

    // ── Logout dialog ────────────────────────────────────────────────────
    'logoutConfirmTitle': {'en': 'Logout', 'fr': 'Se déconnecter', 'ar': 'تسجيل الخروج'},
    'logoutConfirmMsg': {'en': 'Are you sure you want to log out?', 'fr': 'Voulez-vous vraiment vous déconnecter ?', 'ar': 'هل أنت متأكد أنك تريد تسجيل الخروج؟'},

    // ── Navigation ───────────────────────────────────────────────────────
    'trips': {'en': 'Trips', 'fr': 'Trajets', 'ar': 'الرحلات'},
    'myTickets': {'en': 'My Tickets', 'fr': 'Mes billets', 'ar': 'تذاكري'},
    'findTrips': {'en': 'Find Trips', 'fr': 'Trouver des trajets', 'ar': 'ابحث عن رحلات'},
    'home': {'en': 'Home', 'fr': 'Accueil', 'ar': 'الرئيسية'},

    // ── Trip Search ──────────────────────────────────────────────────────
    'findYourLouage': {'en': 'Find Your Louage Trip', 'fr': 'Trouvez votre trajet Louage', 'ar': 'ابحث عن رحلة لواجك'},
    'departureCity': {'en': 'Departure City', 'fr': 'Ville de départ', 'ar': 'مدينة الانطلاق'},
    'departureStation': {'en': 'Departure Station', 'fr': 'Gare de départ', 'ar': 'محطة الانطلاق'},
    'destinationCity': {'en': 'Destination City', 'fr': 'Ville de destination', 'ar': 'مدينة الوصول'},
    'destinationStation': {'en': 'Destination Station', 'fr': 'Gare de destination', 'ar': 'محطة الوصول'},
    'anyCity': {'en': 'Any City', 'fr': 'N\'importe quelle ville', 'ar': 'أي مدينة'},
    'anyStation': {'en': 'Any Station', 'fr': 'N\'importe quelle gare', 'ar': 'أي محطة'},
    'selectDate': {'en': 'Select Date (Optional)', 'fr': 'Sélectionner une date (optionnel)', 'ar': 'اختر التاريخ (اختياري)'},
    'searchTrips': {'en': 'Search Trips', 'fr': 'Rechercher des trajets', 'ar': 'البحث عن رحلات'},
    'clear': {'en': 'Clear', 'fr': 'Effacer', 'ar': 'مسح'},
    'searchPrompt': {'en': 'Select your departure and destination,\nthen tap Search.', 'fr': 'Sélectionnez votre départ et destination,\npuis appuyez sur Rechercher.', 'ar': 'حدد نقطة الانطلاق والوجهة،\nثم اضغط على بحث.'},
    'noTripsFound': {'en': 'No trips found.\nTry different stations or date.', 'fr': 'Aucun trajet trouvé.\nEssayez d\'autres gares ou une autre date.', 'ar': 'لم يتم العثور على رحلات.\nجرب محطات أو تاريخًا مختلفًا.'},
    'book': {'en': 'Book', 'fr': 'Réserver', 'ar': 'حجز'},
    'booked': {'en': 'Booked', 'fr': 'Réservé', 'ar': 'محجوز'},
    'confirmBooking': {'en': 'Confirm Booking', 'fr': 'Confirmer la réservation', 'ar': 'تأكيد الحجز'},
    'confirmAndBook': {'en': 'Confirm & Book', 'fr': 'Confirmer et réserver', 'ar': 'تأكيد والحجز'},
    'from': {'en': 'From', 'fr': 'De', 'ar': 'من'},
    'to': {'en': 'To', 'fr': 'À', 'ar': 'إلى'},
    'departure': {'en': 'Departure', 'fr': 'Départ', 'ar': 'مغادرة'},
    'price': {'en': 'Price', 'fr': 'Prix', 'ar': 'السعر'},
    'officialTariff': {'en': 'Official tariff (A/C louage, Dec 2022)', 'fr': 'Tarif officiel (louage climatisé, déc. 2022)', 'ar': 'التعريفة الرسمية (لواج مكيف، ديسمبر 2022)'},
    'ticketBooked': {'en': 'Ticket booked successfully! Check My Tickets.', 'fr': 'Billet réservé avec succès ! Voir Mes billets.', 'ar': 'تم حجز التذكرة بنجاح! تحقق من تذاكري.'},
    'failedToBook': {'en': 'Failed to book ticket.', 'fr': 'Échec de la réservation.', 'ar': 'فشل حجز التذكرة.'},
    'loginAgain': {'en': 'Please log in again.', 'fr': 'Veuillez vous reconnecter.', 'ar': 'يرجى تسجيل الدخول مرة أخرى.'},

    // ── Tickets ──────────────────────────────────────────────────────────
    'noTickets': {'en': 'You have no tickets yet.', 'fr': 'Vous n\'avez pas encore de billets.', 'ar': 'ليس لديك تذاكر بعد.'},
    'ticket': {'en': 'Ticket', 'fr': 'Billet', 'ar': 'تذكرة'},
    'refund': {'en': 'Refund', 'fr': 'Remboursement', 'ar': 'استرداد'},
    'refundTicket': {'en': 'Refund Ticket', 'fr': 'Rembourser le billet', 'ar': 'استرداد التذكرة'},
    'pricePaid': {'en': 'Price paid', 'fr': 'Prix payé', 'ar': 'السعر المدفوع'},
    'refundConfirmMsg': {'en': 'Are you sure you want to refund this ticket? This cannot be undone.', 'fr': 'Voulez-vous vraiment rembourser ce billet ? Cette action est irréversible.', 'ar': 'هل أنت متأكد من استرداد هذه التذكرة؟ لا يمكن التراجع عن هذا الإجراء.'},
    'confirmRefund': {'en': 'Confirm Refund', 'fr': 'Confirmer le remboursement', 'ar': 'تأكيد الاسترداد'},
    'ticketRefunded': {'en': 'Ticket refunded successfully.', 'fr': 'Billet remboursé avec succès.', 'ar': 'تم استرداد التذكرة بنجاح.'},
    'refundFailed': {'en': 'Refund failed.', 'fr': 'Échec du remboursement.', 'ar': 'فشل الاسترداد.'},
    'date': {'en': 'Date', 'fr': 'Date', 'ar': 'التاريخ'},
    'time': {'en': 'Time', 'fr': 'Heure', 'ar': 'الوقت'},
    'statusActive': {'en': 'ACTIVE', 'fr': 'ACTIF', 'ar': 'نشط'},
    'statusRefunded': {'en': 'REFUNDED', 'fr': 'REMBOURSÉ', 'ar': 'مُسترد'},
    'statusUsed': {'en': 'USED', 'fr': 'UTILISÉ', 'ar': 'مستخدم'},
    'statusCancelled': {'en': 'CANCELLED', 'fr': 'ANNULÉ', 'ar': 'ملغى'},

    // ── Admin ────────────────────────────────────────────────────────────
    'adminDashboard': {'en': 'Admin Dashboard', 'fr': 'Tableau de bord Admin', 'ar': 'لوحة تحكم المسؤول'},
    'users': {'en': 'Users', 'fr': 'Utilisateurs', 'ar': 'المستخدمون'},
    'approvals': {'en': 'Approvals', 'fr': 'Approbations', 'ar': 'الموافقات'},
    'stations': {'en': 'Stations', 'fr': 'Gares', 'ar': 'المحطات'},
    'vehicles': {'en': 'Vehicles', 'fr': 'Véhicules', 'ar': 'المركبات'},
    'pendingDrivers': {'en': 'Pending Drivers', 'fr': 'Chauffeurs en attente', 'ar': 'السائقون المعلقون'},
    'approve': {'en': 'Approve', 'fr': 'Approuver', 'ar': 'موافقة'},
    'decline': {'en': 'Decline', 'fr': 'Refuser', 'ar': 'رفض'},
    'createAdmin': {'en': 'Create Admin', 'fr': 'Créer un administrateur', 'ar': 'إنشاء مسؤول'},
    'createDriver': {'en': 'Create Driver', 'fr': 'Créer un chauffeur', 'ar': 'إنشاء سائق'},
    'createStation': {'en': 'Create Station', 'fr': 'Créer une gare', 'ar': 'إنشاء محطة'},
    'createVehicle': {'en': 'Create Vehicle', 'fr': 'Créer un véhicule', 'ar': 'إنشاء مركبة'},
    'createTrip': {'en': 'Create Trip', 'fr': 'Créer un trajet', 'ar': 'إنشاء رحلة'},
    'deleteUser': {'en': 'Delete User', 'fr': 'Supprimer l\'utilisateur', 'ar': 'حذف المستخدم'},
    'deleteUserConfirm': {'en': 'Are you sure you want to delete this user?', 'fr': 'Voulez-vous vraiment supprimer cet utilisateur ?', 'ar': 'هل أنت متأكد من حذف هذا المستخدم؟'},
    'noUsers': {'en': 'No users found.', 'fr': 'Aucun utilisateur trouvé.', 'ar': 'لا يوجد مستخدمون.'},
    'noPendingDrivers': {'en': 'No pending drivers.', 'fr': 'Aucun chauffeur en attente.', 'ar': 'لا يوجد سائقون معلقون.'},
    'noStations': {'en': 'No stations found.', 'fr': 'Aucune gare trouvée.', 'ar': 'لا توجد محطات.'},
    'noVehicles': {'en': 'No vehicles found.', 'fr': 'Aucun véhicule trouvé.', 'ar': 'لا توجد مركبات.'},
    'noTrips': {'en': 'No trips found.', 'fr': 'Aucun trajet trouvé.', 'ar': 'لا توجد رحلات.'},
    'stationName': {'en': 'Station Name', 'fr': 'Nom de la gare', 'ar': 'اسم المحطة'},
    'city': {'en': 'City', 'fr': 'Ville', 'ar': 'المدينة'},
    'plate': {'en': 'Plate', 'fr': 'Plaque', 'ar': 'اللوحة'},
    'capacity': {'en': 'Capacity', 'fr': 'Capacité', 'ar': 'السعة'},
    'assignDriver': {'en': 'Assign Driver', 'fr': 'Assigner un chauffeur', 'ar': 'تعيين سائق'},
    'departureTime': {'en': 'Departure Time', 'fr': 'Heure de départ', 'ar': 'وقت المغادرة'},
    'startStation': {'en': 'Start Station', 'fr': 'Gare de départ', 'ar': 'محطة البداية'},
    'endStation': {'en': 'End Station', 'fr': 'Gare d\'arrivée', 'ar': 'محطة النهاية'},
    'status': {'en': 'Status', 'fr': 'Statut', 'ar': 'الحالة'},
    'bookOfflineTicket': {'en': 'Book Offline Ticket', 'fr': 'Réserver un billet hors ligne', 'ar': 'حجز تذكرة بدون اتصال'},
    'passengerName': {'en': 'Passenger Name', 'fr': 'Nom du passager', 'ar': 'اسم الراكب'},
    'userType': {'en': 'Type', 'fr': 'Type', 'ar': 'النوع'},
    'failedDeleteUser': {'en': 'Failed to delete user', 'fr': 'Échec de la suppression', 'ar': 'فشل حذف المستخدم'},

    // ── Driver ───────────────────────────────────────────────────────────
    'driverDashboard': {'en': 'Driver Dashboard', 'fr': 'Tableau de bord Chauffeur', 'ar': 'لوحة تحكم السائق'},
    'myTrips': {'en': 'My Trips', 'fr': 'Mes trajets', 'ar': 'رحلاتي'},
    'currentStation': {'en': 'Current Station', 'fr': 'Gare actuelle', 'ar': 'المحطة الحالية'},
    'pendingApproval': {'en': 'Pending Approval', 'fr': 'En attente d\'approbation', 'ar': 'في انتظار الموافقة'},
    'pendingApprovalMsg': {'en': 'Your account is pending admin approval. Please wait.', 'fr': 'Votre compte est en attente d\'approbation. Veuillez patienter.', 'ar': 'حسابك في انتظار موافقة المسؤول. يرجى الانتظار.'},
    'passengers': {'en': 'Passengers', 'fr': 'Passagers', 'ar': 'الركاب'},
    'noPassengers': {'en': 'No passengers yet.', 'fr': 'Aucun passager pour le moment.', 'ar': 'لا يوجد ركاب حتى الآن.'},
    'updateStatus': {'en': 'Update Status', 'fr': 'Mettre à jour le statut', 'ar': 'تحديث الحالة'},
    'setCurrentStation': {'en': 'Set Current Station', 'fr': 'Définir la gare actuelle', 'ar': 'تعيين المحطة الحالية'},
  };

  String _get(String key) {
    final langCode = locale.languageCode;
    return _strings[key]?[langCode] ?? _strings[key]?['en'] ?? key;
  }

  // ── Getters ─────────────────────────────────────────────────────────
  String get appName => _get('appName');
  String get cancel => _get('cancel');
  String get confirm => _get('confirm');
  String get delete => _get('delete');
  String get retry => _get('retry');
  String get logout => _get('logout');
  String get save => _get('save');
  String get add => _get('add');
  String get close => _get('close');
  String get yes => _get('yes');
  String get no => _get('no');
  String get ok => _get('ok');
  String get error => _get('error');
  String get success => _get('success');
  String get loading => _get('loading');
  String get language => _get('language');

  String get email => _get('email');
  String get password => _get('password');
  String get firstName => _get('firstName');
  String get lastName => _get('lastName');
  String get phoneNumber => _get('phoneNumber');
  String get login => _get('login');
  String get signUp => _get('signUp');
  String get createAccount => _get('createAccount');
  String get noAccount => _get('noAccount');
  String get haveAccount => _get('haveAccount');
  String get loginFailed => _get('loginFailed');
  String get enterEmail => _get('enterEmail');
  String get enterPassword => _get('enterPassword');
  String get enterFirstName => _get('enterFirstName');
  String get enterLastName => _get('enterLastName');
  String get enterPhone => _get('enterPhone');
  String get passwordMin => _get('passwordMin');
  String get passenger => _get('passenger');
  String get driver => _get('driver');
  String get registerAsDriver => _get('registerAsDriver');
  String get signUpAsPassenger => _get('signUpAsPassenger');
  String get driverNotice => _get('driverNotice');
  String get licenseNumber => _get('licenseNumber');
  String get vehicleInfo => _get('vehicleInfo');
  String get vehiclePlate => _get('vehiclePlate');
  String get seatingCapacity => _get('seatingCapacity');
  String get destinations => _get('destinations');
  String get enterLicense => _get('enterLicense');
  String get enterPlate => _get('enterPlate');
  String get capacityMin => _get('capacityMin');
  String get selectMin2Stations => _get('selectMin2Stations');
  String get validPhone => _get('validPhone');
  String get registrationFailed => _get('registrationFailed');
  String get provideLicenseAndPlate => _get('provideLicenseAndPlate');

  String get logoutConfirmTitle => _get('logoutConfirmTitle');
  String get logoutConfirmMsg => _get('logoutConfirmMsg');

  String get trips => _get('trips');
  String get myTickets => _get('myTickets');
  String get findTrips => _get('findTrips');
  String get home => _get('home');

  String get findYourLouage => _get('findYourLouage');
  String get departureCity => _get('departureCity');
  String get departureStation => _get('departureStation');
  String get destinationCity => _get('destinationCity');
  String get destinationStation => _get('destinationStation');
  String get anyCity => _get('anyCity');
  String get anyStation => _get('anyStation');
  String get selectDate => _get('selectDate');
  String get searchTrips => _get('searchTrips');
  String get clear => _get('clear');
  String get searchPrompt => _get('searchPrompt');
  String get noTripsFound => _get('noTripsFound');
  String get book => _get('book');
  String get booked => _get('booked');
  String get confirmBooking => _get('confirmBooking');
  String get confirmAndBook => _get('confirmAndBook');
  String get from => _get('from');
  String get to => _get('to');
  String get departure => _get('departure');
  String get price => _get('price');
  String get officialTariff => _get('officialTariff');
  String get ticketBooked => _get('ticketBooked');
  String get failedToBook => _get('failedToBook');
  String get loginAgain => _get('loginAgain');

  String get noTickets => _get('noTickets');
  String get ticket => _get('ticket');
  String get refund => _get('refund');
  String get refundTicket => _get('refundTicket');
  String get pricePaid => _get('pricePaid');
  String get refundConfirmMsg => _get('refundConfirmMsg');
  String get confirmRefund => _get('confirmRefund');
  String get ticketRefunded => _get('ticketRefunded');
  String get refundFailed => _get('refundFailed');
  String get date => _get('date');
  String get time => _get('time');
  String get statusActive => _get('statusActive');
  String get statusRefunded => _get('statusRefunded');
  String get statusUsed => _get('statusUsed');
  String get statusCancelled => _get('statusCancelled');

  String get adminDashboard => _get('adminDashboard');
  String get users => _get('users');
  String get approvals => _get('approvals');
  String get stations => _get('stations');
  String get vehicles => _get('vehicles');
  String get pendingDrivers => _get('pendingDrivers');
  String get approve => _get('approve');
  String get decline => _get('decline');
  String get createAdmin => _get('createAdmin');
  String get createDriver => _get('createDriver');
  String get createStation => _get('createStation');
  String get createVehicle => _get('createVehicle');
  String get createTrip => _get('createTrip');
  String get deleteUser => _get('deleteUser');
  String get deleteUserConfirm => _get('deleteUserConfirm');
  String get noUsers => _get('noUsers');
  String get noPendingDrivers => _get('noPendingDrivers');
  String get noStations => _get('noStations');
  String get noVehicles => _get('noVehicles');
  String get noTrips => _get('noTrips');
  String get stationName => _get('stationName');
  String get city => _get('city');
  String get plate => _get('plate');
  String get capacity => _get('capacity');
  String get assignDriver => _get('assignDriver');
  String get departureTime => _get('departureTime');
  String get startStation => _get('startStation');
  String get endStation => _get('endStation');
  String get status => _get('status');
  String get bookOfflineTicket => _get('bookOfflineTicket');
  String get passengerName => _get('passengerName');
  String get userType => _get('userType');
  String get failedDeleteUser => _get('failedDeleteUser');

  String get driverDashboard => _get('driverDashboard');
  String get myTrips => _get('myTrips');
  String get currentStation => _get('currentStation');
  String get pendingApproval => _get('pendingApproval');
  String get pendingApprovalMsg => _get('pendingApprovalMsg');
  String get passengers => _get('passengers');
  String get noPassengers => _get('noPassengers');
  String get updateStatus => _get('updateStatus');
  String get setCurrentStation => _get('setCurrentStation');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

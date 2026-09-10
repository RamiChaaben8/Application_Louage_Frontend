import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  final _storage = const FlutterSecureStorage();

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  Future<void> loadSavedLocale() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _storage.write(key: _key, value: locale.languageCode);
    notifyListeners();
  }

  String get languageLabel {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  static const List<LanguageOption> options = [
    LanguageOption(locale: Locale('en'), label: 'English', flag: '🇬🇧'),
    LanguageOption(locale: Locale('fr'), label: 'Français', flag: '🇫🇷'),
    LanguageOption(locale: Locale('ar'), label: 'العربية', flag: '🇹🇳'),
  ];
}

class LanguageOption {
  final Locale locale;
  final String label;
  final String flag;
  const LanguageOption({required this.locale, required this.label, required this.flag});
}

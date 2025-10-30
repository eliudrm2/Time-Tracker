import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'locale';
  static const List<Locale> supportedLocales = [
    Locale('es', 'ES'),
    Locale('en', 'US'),
  ];

  Locale _currentLocale = supportedLocales.first;

  LocaleProvider() {
    final stored = StorageService.getSetting(_storageKey, defaultValue: 'es');
    _currentLocale = _fromCode(stored as String);
  }

  Locale get locale => _currentLocale;

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    await StorageService.saveSetting(_storageKey, locale.languageCode);
    notifyListeners();
  }

  static Locale _fromCode(String code) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => supportedLocales.first,
    );
  }
}

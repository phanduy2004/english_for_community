import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ngôn ngữ giao diện (EN/VI), độc lập với trường `language` học tập trên user profile.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController();

  static const _prefKey = 'app_ui_locale_code';

  static const supportedCodes = {'en', 'vi'};

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefKey);
    if (code != null && supportedCodes.contains(code)) {
      _locale = Locale(code);
    } else {
      _locale = const Locale('en');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    final code = value.languageCode;
    if (!supportedCodes.contains(code)) return;
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefKey, code);
  }
}

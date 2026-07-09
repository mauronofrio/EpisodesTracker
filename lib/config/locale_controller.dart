import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current UI language and persists it to this device's
/// local storage (not per Google account - this app runs on a shared
/// device used by 2-3 people, so the language is a device-wide setting,
/// not a per-user one).
class LocaleController extends ValueNotifier<Locale> {
  static const _prefsKey = 'locale';
  final SharedPreferences _prefs;

  LocaleController._(this._prefs, super.initial);

  /// Resolves the starting locale: whatever was explicitly saved before,
  /// or - on first launch, when nothing is saved yet - Italian if the
  /// device's own language is Italian, English otherwise (the app's
  /// default). The first-launch resolution is persisted immediately so a
  /// later device-language change doesn't retroactively change it.
  static Future<LocaleController> load({
    required SharedPreferences prefs,
    required Locale deviceLocale,
  }) async {
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      return LocaleController._(prefs, Locale(saved));
    }
    final resolved = deviceLocale.languageCode == 'it'
        ? const Locale('it')
        : const Locale('en');
    await prefs.setString(_prefsKey, resolved.languageCode);
    return LocaleController._(prefs, resolved);
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    await _prefs.setString(_prefsKey, locale.languageCode);
  }
}

/// Exposes an ambient [LocaleController] to descendants (e.g. the account
/// drawer's language switch) without threading it through every screen's
/// constructor - the same pattern `UpdateBanner.of` uses for release info.
class LocaleControllerScope extends InheritedWidget {
  final LocaleController controller;

  const LocaleControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(scope != null, 'No LocaleControllerScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(LocaleControllerScope oldWidget) =>
      oldWidget.controller != controller;
}

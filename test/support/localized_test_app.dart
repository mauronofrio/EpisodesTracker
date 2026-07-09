// test/support/localized_test_app.dart
import 'package:episodes_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wraps [home] in a MaterialApp with the app's localization delegates
/// registered, so widgets calling `AppLocalizations.of(context)!` don't
/// throw in tests. Defaults to Italian since every pre-existing string
/// assertion in this test suite was written against the Italian text;
/// pass `locale: const Locale('en')` explicitly to verify English output.
Widget localizedTestApp({
  required Widget home,
  Locale locale = const Locale('it'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

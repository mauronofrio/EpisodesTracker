// test/config/locale_controller_test.dart
import 'package:episodes_tracker/config/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleController.load', () {
    test(
      'uses Italian on first launch when the device locale is Italian',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          deviceLocale: const Locale('it'),
        );

        expect(controller.value, const Locale('it'));
      },
    );

    test(
      'uses English on first launch for any non-Italian device locale',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          deviceLocale: const Locale('fr'),
        );

        expect(controller.value, const Locale('en'));
      },
    );

    test('persists the first-launch resolution immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );

      expect(prefs.getString('locale'), 'it');
    });

    test(
      'reuses a previously saved locale instead of re-resolving from the '
      'device',
      () async {
        SharedPreferences.setMockInitialValues({'locale': 'en'});
        final prefs = await SharedPreferences.getInstance();

        final controller = await LocaleController.load(
          prefs: prefs,
          // Device is Italian, but a saved preference (from an earlier
          // explicit choice) must win.
          deviceLocale: const Locale('it'),
        );

        expect(controller.value, const Locale('en'));
      },
    );
  });

  group('LocaleController.setLocale', () {
    test('updates the value and persists the new locale', () async {
      SharedPreferences.setMockInitialValues({'locale': 'it'});
      final prefs = await SharedPreferences.getInstance();
      final controller = await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );

      await controller.setLocale(const Locale('en'));

      expect(controller.value, const Locale('en'));
      expect(prefs.getString('locale'), 'en');
    });

    test('notifies listeners when the locale changes', () async {
      SharedPreferences.setMockInitialValues({'locale': 'it'});
      final prefs = await SharedPreferences.getInstance();
      final controller = await LocaleController.load(
        prefs: prefs,
        deviceLocale: const Locale('it'),
      );
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.setLocale(const Locale('en'));

      expect(notified, isTrue);
    });
  });
}

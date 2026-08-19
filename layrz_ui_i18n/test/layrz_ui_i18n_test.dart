import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui_i18n/layrz_ui_i18n.dart';

void main() {
  group('LayrzUiI18n', () {
    test('can be instantiated with a LayrzI18n engine', () {
      final mockEngine = LayrzI18n(
        languages: [],
        currentLocale: const Locale('en'),
      );
      final adapter = LayrzUiI18n(i18n: mockEngine);
      expect(adapter, isNotNull);
      expect(adapter.i18n, equals(mockEngine));
    });

    test('delegate extends LayrzUiL10nDelegate', () {
      final mockEngine = LayrzI18n(
        languages: [],
        currentLocale: const Locale('en'),
      );
      final delegate = LayrzUiI18nDelegate(mockEngine);
      expect(delegate, isA<LayrzUiL10nDelegate>());
    });

    test('delegate is supported for all locales', () {
      final mockEngine = LayrzI18n(
        languages: [],
        currentLocale: const Locale('en'),
      );
      final delegate = LayrzUiI18nDelegate(mockEngine);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('es')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isTrue);
    });

    test('delegate load returns LayrzUiI18n instance', () async {
      final mockEngine = LayrzI18n(
        languages: [],
        currentLocale: const Locale('en'),
      );
      final delegate = LayrzUiI18nDelegate(mockEngine);
      final localization = await delegate.load(const Locale('en'));
      expect(localization, isA<LayrzUiI18n>());
      expect(localization, isA<LayrzUiL10n>());
    });
  });
}

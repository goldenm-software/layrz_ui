import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A minimal, distinctly-worded [LayrzUiL10n] subclass used to prove that
/// [DateTime.format] resolves l10n from the supplied [BuildContext] rather
/// than always falling back to the English default.
class _TestL10n extends LayrzUiL10n {
  const _TestL10n();

  @override
  String get monthSeptember => 'TEST_SEPTEMBER';

  @override
  String get dateWednesday => 'TEST_WEDNESDAY';
}

/// A [LocalizationsDelegate] that always resolves to [_TestL10n], used to
/// inject it into a widget tree via [Localizations].
class _TestL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  const _TestL10nDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) => SynchronousFuture<LayrzUiL10n>(const _TestL10n());

  @override
  bool shouldReload(_TestL10nDelegate old) => false;
}

void main() {
  // 2026-09-16 is a Wednesday, day-of-year 259.
  final reference = DateTime(2026, 9, 16, 14, 5, 9);

  group('LayrzDateTimeExtensions.format — null context (English default)', () {
    test('renders locale-independent tokens', () {
      expect(reference.format(null, '%Y-%m-%d %H:%M:%S'), '2026-09-16 14:05:09');
    });

    test('renders %y %m %d %I %M %S %j %%', () {
      expect(reference.format(null, '%y-%m-%d %I:%M:%S %j %%'), '26-09-16 02:05:09 259 %');
    });

    test('renders a pattern mixing literal text and directives', () {
      expect(reference.format(null, 'Today is %A, %B %d, %Y'), 'Today is Wednesday, September 16, 2026');
    });

    test('falls back to English for %B (full month name)', () {
      expect(reference.format(null, '%d %B %Y'), '16 September 2026');
    });

    test('falls back to English for %A (full weekday name)', () {
      expect(reference.format(null, '%A'), 'Wednesday');
    });

    test('falls back to English for %a (abbreviated weekday name)', () {
      expect(reference.format(null, '%a'), 'Wed');
    });

    test('falls back to English for %b (abbreviated month name)', () {
      expect(reference.format(null, '%b'), 'Sep');
    });

    test('falls back to English for %p (meridiem marker)', () {
      expect(DateTime(2026, 1, 1, 9).format(null, '%p'), 'AM');
      expect(DateTime(2026, 1, 1, 21).format(null, '%p'), 'PM');
    });
  });

  group('LayrzDateTimeExtensions.format — with BuildContext', () {
    testWidgets('resolves l10n via LayrzUiL10n.of(context) under the default delegate', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late String result;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            LayrzUiL10nDelegate(),
          ],
          child: Builder(
            builder: (context) {
              result = reference.format(context, '%d %B %Y');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, '16 September 2026');
    });

    testWidgets('a custom LayrzUiL10n supplied via context wins over the English default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late String monthResult;
      late String weekdayResult;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            _TestL10nDelegate(),
          ],
          child: Builder(
            builder: (context) {
              monthResult = reference.format(context, '%B');
              weekdayResult = reference.format(context, '%A');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(monthResult, 'TEST_SEPTEMBER');
      expect(weekdayResult, 'TEST_WEDNESDAY');
    });
  });
}

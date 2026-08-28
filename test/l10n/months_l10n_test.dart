import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nMonthsMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('all 12 month getters return their English defaults', () {
      expect(localizations.monthJanuary, 'January');
      expect(localizations.monthFebruary, 'February');
      expect(localizations.monthMarch, 'March');
      expect(localizations.monthApril, 'April');
      expect(localizations.monthMay, 'May');
      expect(localizations.monthJune, 'June');
      expect(localizations.monthJuly, 'July');
      expect(localizations.monthAugust, 'August');
      expect(localizations.monthSeptember, 'September');
      expect(localizations.monthOctober, 'October');
      expect(localizations.monthNovember, 'November');
      expect(localizations.monthDecember, 'December');
    });

    test('both meridiem markers return their English defaults', () {
      expect(localizations.timeMeridiemAm, 'AM');
      expect(localizations.timeMeridiemPm, 'PM');
    });

    test('subclass can override a month getter independently of the others', () {
      final custom = _CustomMonthsLocalizations();
      expect(custom.monthJanuary, 'CUSTOM_JANUARY');
      // Every other month getter keeps its English default — overriding one
      // key must not couple to, or short-circuit, the rest of the mixin.
      expect(custom.monthFebruary, 'February');
      expect(custom.monthDecember, 'December');
    });

    test('subclass can override a meridiem marker independently of the other', () {
      final custom = _CustomMeridiemLocalizations();
      expect(custom.timeMeridiemAm, 'CUSTOM_AM');
      expect(custom.timeMeridiemPm, 'PM');
    });
  });

  group('LayrzUiL10nMonthsMixin reachability through LayrzUiL10n.of', () {
    // This proves the namespace is actually wired into the aggregate contract
    // via BOTH the import and the `with` clause in `l10n.dart` — a namespace
    // that only compiles (mixin defined, never added to `with`) would fail
    // here with a NoSuchMethodError, not merely return the wrong string.
    testWidgets('resolves monthAugust through the widget tree', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late String resolved;
      await tester.pumpWidget(
        LayrzApp(
          home: Builder(
            builder: (context) {
              resolved = LayrzUiL10n.of(context).monthAugust;
              return const SizedBox.shrink();
            },
          ),
          theme: LayrzThemeData.light(),
        ),
      );

      expect(resolved, 'August');
    });

    testWidgets('resolves timeMeridiemPm via the context.l10n extension', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          home: Builder(
            builder: (context) => Text(context.l10n.timeMeridiemPm),
          ),
          theme: LayrzThemeData.light(),
        ),
      );

      expect(find.text('PM'), findsOneWidget);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [monthJanuary].
///
/// Verifies that a single month getter can be overridden independently of
/// the other eleven, confirming the mixin does not accidentally couple them.
class _CustomMonthsLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomMonthsLocalizations();

  @override
  String get monthJanuary => 'CUSTOM_JANUARY';
}

/// Minimal [LayrzUiL10n] subclass overriding only [timeMeridiemAm].
///
/// Verifies the two meridiem markers are independent keys, not aliases of
/// one another.
class _CustomMeridiemLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomMeridiemLocalizations();

  @override
  String get timeMeridiemAm => 'CUSTOM_AM';
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTimelineStyleSpec', () {
    final tokens = LayrzThemeData.light().tokens;

    test('resolve falls back to tokens.colors.fg3 when accentColor is null', () {
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: null, tokens: tokens);
      expect(spec.markerColor, tokens.colors.fg3);
    });

    test('resolve honours an explicit accentColor', () {
      const accent = Color(0xFF123456);
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: accent, tokens: tokens);
      expect(spec.markerColor, accent);
    });

    test('copyWith replaces only the given fields', () {
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: null, tokens: tokens);
      const replacement = Color(0xFFAABBCC);
      final copy = spec.copyWith(markerColor: replacement);

      expect(copy.markerColor, replacement);
      expect(copy.markerContentColor, spec.markerContentColor);
      expect(copy.cardBackgroundColor, spec.cardBackgroundColor);
      expect(copy.labelColor, spec.labelColor);
      expect(copy.descriptionColor, spec.descriptionColor);
      expect(copy.timestampColor, spec.timestampColor);
    });

    test('copyWith with no arguments returns an equal spec', () {
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: null, tokens: tokens);
      expect(spec.copyWith(), spec);
    });

    test('equality and hashCode are value-based', () {
      final a = LayrzTimelineStyleSpec.resolve(accentColor: const Color(0xFF000001), tokens: tokens);
      final b = LayrzTimelineStyleSpec.resolve(accentColor: const Color(0xFF000001), tokens: tokens);
      final c = LayrzTimelineStyleSpec.resolve(accentColor: const Color(0xFF000002), tokens: tokens);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('identical instances are equal', () {
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: null, tokens: tokens);
      expect(spec, same(spec));
    });

    test('is not equal to a different runtime type', () {
      final spec = LayrzTimelineStyleSpec.resolve(accentColor: null, tokens: tokens);
      // ignore: unrelated_type_equality_checks
      expect(spec == 'not a spec', isFalse);
    });
  });

  group('LayrzTimeline', () {
    final entries = const [
      LayrzTimelineEntry(labelText: 'First', descriptionText: 'First description', timestampText: 'Jan 1'),
      LayrzTimelineEntry(labelText: 'Second', descriptionText: 'Second description', timestampText: 'Jan 2'),
      LayrzTimelineEntry(labelText: 'Third', descriptionText: 'Third description', timestampText: 'Jan 3'),
    ];

    guardedTestWidgets('renders every entry label and description', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(width: 1400, child: LayrzTimeline(entries: entries)),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('First description'), findsOneWidget);
      expect(find.text('Jan 1'), findsOneWidget);
    });

    group('compact collapse — derived from viewport', () {
      guardedTestWidgets('wide viewport renders the two-sided surface, not the one-sided surface', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(width: 1400, child: LayrzTimeline(entries: entries)),
        );

        expect(find.byType(LayrzTimelineTwoSidedSurface), findsOneWidget);
        expect(find.byType(LayrzTimelineOneSidedSurface), findsNothing);
      });

      guardedTestWidgets('narrow (compact) viewport renders the one-sided surface, not the two-sided surface', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(width: 380, child: LayrzTimeline(entries: entries)),
        );

        expect(find.byType(LayrzTimelineOneSidedSurface), findsOneWidget);
        expect(find.byType(LayrzTimelineTwoSidedSurface), findsNothing);
      });
    });

    group('isCompactOverride — proves the override wins over the derived value', () {
      guardedTestWidgets('narrow viewport with isCompactOverride: false renders two-sided anyway', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(entries: entries, isCompactOverride: false),
          ),
        );

        expect(find.byType(LayrzTimelineTwoSidedSurface), findsOneWidget);
        expect(find.byType(LayrzTimelineOneSidedSurface), findsNothing);
      });

      guardedTestWidgets('wide viewport with isCompactOverride: true renders one-sided anyway', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(entries: entries, isCompactOverride: true),
          ),
        );

        expect(find.byType(LayrzTimelineOneSidedSurface), findsOneWidget);
        expect(find.byType(LayrzTimelineTwoSidedSurface), findsNothing);
      });
    });

    group('twoSided: false forces one-sided regardless of viewport width', () {
      guardedTestWidgets('wide viewport with twoSided: false renders one-sided', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(entries: entries, twoSided: false),
          ),
        );

        expect(find.byType(LayrzTimelineOneSidedSurface), findsOneWidget);
        expect(find.byType(LayrzTimelineTwoSidedSurface), findsNothing);
      });
    });

    guardedTestWidgets('renders an entry-supplied content widget', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          child: LayrzTimeline(
            entries: const [
              LayrzTimelineEntry(labelText: 'With content', content: Text('Attached content')),
            ],
          ),
        ),
      );

      expect(find.text('Attached content'), findsOneWidget);
    });

    guardedTestWidgets('renders an empty entry list without error', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const SizedBox(width: 1400, child: LayrzTimeline(entries: [])),
      );

      expect(find.byType(LayrzTimeline), findsOneWidget);
    });

    guardedTestWidgets('a single entry renders with no connector segments', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          child: LayrzTimeline(entries: const [LayrzTimelineEntry(labelText: 'Only entry')]),
        ),
      );

      expect(find.byType(LayrzTimelineConnector), findsNothing);
    });
  });
}

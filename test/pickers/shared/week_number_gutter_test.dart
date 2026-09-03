import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/week_number_gutter.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickersWeekNumberGutter — wide (non-compact) viewport', () {
    testWidgets('renders numeric ISO week labels', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersWeekNumberGutter(rowStartDates: [DateTime(2026, 8, 31)], rowHeight: 40.0),
      );

      // isoWeekNumberOf(2026-08-31) == 36.
      expect(find.text('36'), findsOneWidget);
    });

    testWidgets('renders one label per row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersWeekNumberGutter(
          rowStartDates: [DateTime(2026, 8, 31), DateTime(2026, 9, 7), DateTime(2026, 9, 14)],
          rowHeight: 40.0,
        ),
      );

      expect(find.text('36'), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
    });
  });

  group('LayrzPickersWeekNumberGutter — compact viewport', () {
    testWidgets('renders no numeric text, only a decorative strip', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersWeekNumberGutter(rowStartDates: [DateTime(2026, 8, 31)], rowHeight: 40.0),
      );

      expect(find.text('36'), findsNothing);
      expect(find.byType(LayrzPickersWeekNumberGutter), findsOneWidget);
    });
  });

  group('LayrzPickersWeekNumberGutter — visible flag', () {
    testWidgets('visible false renders an empty box with no week labels', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersWeekNumberGutter(rowStartDates: [DateTime(2026, 8, 31)], rowHeight: 40.0, visible: false),
      );

      expect(find.text('36'), findsNothing);
    });
  });

  group('LayrzPickersWeekNumberGutter — purely decorative', () {
    testWidgets('carries no tappable semantics', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickersWeekNumberGutter(rowStartDates: [DateTime(2026, 8, 31)], rowHeight: 40.0),
        );

        final gutterSemantics = tester.getSemantics(find.byType(LayrzPickersWeekNumberGutter));
        expect(gutterSemantics.getSemanticsData().flagsCollection.isButton, isFalse);
      } finally {
        handle.dispose();
      }
    });
  });
}

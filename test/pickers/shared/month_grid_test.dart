import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/month_grid.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickersMonthGrid — layout', () {
    guardedTestWidgets('renders all 12 full month names at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.text('January'), findsOneWidget);
      expect(find.text('September'), findsOneWidget);
      expect(find.text('December'), findsOneWidget);
      // No abbreviation anywhere.
      expect(find.text('Jan'), findsNothing);
      expect(find.text('Sep'), findsNothing);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.byType(LayrzPickersMonthGrid), findsOneWidget);
      // All 12 full names -- including the three longest ("September",
      // "November", "December") -- must still be present with no
      // overflow at 400px; `guardedTestWidgets` fails the test if a
      // RenderFlex overflow was reported during the pump above.
      expect(find.text('September'), findsOneWidget);
      expect(find.text('November'), findsOneWidget);
      expect(find.text('December'), findsOneWidget);
    });

    guardedTestWidgets('lays out 3 rows of 4 columns -- January through April on the first row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      double topOf(String label) => tester.getTopLeft(find.text(label)).dy;
      double leftOf(String label) => tester.getTopLeft(find.text(label)).dx;

      // Positive assertion of the new orientation: the first four months
      // share one row (same y, ascending x) -- a 4-rows-by-3-columns grid
      // would instead put January, May and September on that same row.
      final firstRowY = topOf('January');
      expect(topOf('February'), firstRowY);
      expect(topOf('March'), firstRowY);
      expect(topOf('April'), firstRowY);
      expect(leftOf('January') < leftOf('February'), isTrue);
      expect(leftOf('February') < leftOf('March'), isTrue);
      expect(leftOf('March') < leftOf('April'), isTrue);

      // May starts a second, lower row, and September a third -- three
      // rows deep, not four.
      expect(topOf('May'), greaterThan(firstRowY));
      expect(topOf('September'), greaterThan(topOf('May')));
      // December (row 3, col 4) is on the same row as September, not a
      // fourth row.
      expect(topOf('December'), topOf('September'));
    });

    guardedTestWidgets('renders the "Year YYYY" header', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.text('Year 2026'), findsOneWidget);
    });

    guardedTestWidgets('tapping a selectable month fires onMonthTap with the correct month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (d) => tapped = d,
        ),
      );

      await tester.tap(find.text('September'));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.month, 9);
      expect(tapped!.year, 2026);
    });

    guardedTestWidgets('a disabled month does not fire onMonthTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          minimum: DateTime(2026, 6),
          onMonthTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('January'));
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('tapping the "next year" chevron advances displayedYear via onYearChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? newYear;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (y) => newYear = y,
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();

      expect(newYear, 2027);
    });

    guardedTestWidgets('tapping the "previous year" chevron decrements displayedYear via onYearChanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? newYear;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (y) => newYear = y,
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(newYear, 2025);
    });
  });
}

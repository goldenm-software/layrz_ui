import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarWeekGutter', () {
    guardedTestWidgets('renders one week number per weekStarts entry, in order', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final weekStarts = [
        DateTime(2026, 1, 5), // ISO week 2
        DateTime(2026, 1, 12), // ISO week 3
        DateTime(2026, 1, 19), // ISO week 4
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 60,
          height: 600,
          child: LayrzCalendarWeekGutter(weekStarts: weekStarts),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Order: top-to-bottom placement must match weekStarts order.
      final topOf2 = tester.getTopLeft(find.text('2')).dy;
      final topOf3 = tester.getTopLeft(find.text('3')).dy;
      final topOf4 = tester.getTopLeft(find.text('4')).dy;
      expect(topOf2, lessThan(topOf3));
      expect(topOf3, lessThan(topOf4));
    });

    guardedTestWidgets('is sized to kLayrzCalendarWeekGutterWidth', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // `UnconstrainedBox` gives the gutter loose width constraints so its
      // own `SizedBox(width: kLayrzCalendarWeekGutterWidth)` actually governs
      // its rendered width -- a tight outer `SizedBox` (as `LayrzCalendarMonthSurface`
      // never supplies, since it wraps the gutter in a `Row`, not a fixed box)
      // would otherwise override it via `BoxConstraints.enforce`'s clamping.
      await pumpThemed(
        tester,
        UnconstrainedBox(
          child: SizedBox(
            height: 600,
            child: LayrzCalendarWeekGutter(weekStarts: [DateTime(2026, 8, 24)]),
          ),
        ),
      );

      final size = tester.getSize(find.byType(LayrzCalendarWeekGutter));
      expect(size.width, kLayrzCalendarWeekGutterWidth);
    });

    guardedTestWidgets('tapping a week number calls onWeekTap with that row\'s weekStart', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      final weekStarts = [DateTime(2026, 8, 3), DateTime(2026, 8, 10)];

      await pumpThemed(
        tester,
        SizedBox(
          width: 60,
          height: 600,
          child: LayrzCalendarWeekGutter(
            weekStarts: weekStarts,
            onWeekTap: (weekStart) => tapped = weekStart,
          ),
        ),
      );

      // ISO week of 2026-08-10 is 33.
      await tester.tap(find.text('33'));
      await tester.pump();

      expect(tapped, DateTime(2026, 8, 10));
    });

    guardedTestWidgets(
      'a week number renders inert -- no interactive semantics -- when onWeekTap is null',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            SizedBox(
              width: 60,
              height: 600,
              child: LayrzCalendarWeekGutter(weekStarts: [DateTime(2026, 8, 24)]),
            ),
          );

          // ISO week of 2026-08-24 is 35.
          final finder = find.text('35');
          expect(finder, findsOneWidget);
          expect(tester.getSemantics(finder), matchesSemantics(isButton: false));
          expect(find.byType(MouseRegion), findsNothing);
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets(
      'a week number announces a concrete action when onWeekTap is set',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            SizedBox(
              width: 60,
              height: 600,
              child: LayrzCalendarWeekGutter(
                weekStarts: [DateTime(2026, 8, 24)],
                onWeekTap: (_) {},
              ),
            ),
          );

          final semantics = tester.getSemantics(find.text('35'));
          expect(semantics.label, contains('Week 35'));
          expect(semantics.label, contains('week view'));
          expect(
            semantics,
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets('hovering an interactive week number changes its text color', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 60,
          height: 600,
          child: LayrzCalendarWeekGutter(
            weekStarts: [DateTime(2026, 8, 24)],
            onWeekTap: (_) {},
          ),
        ),
      );

      Color? colorOf() => tester
          .widget<AnimatedDefaultTextStyle>(
            find.ancestor(of: find.text('35'), matching: find.byType(AnimatedDefaultTextStyle)),
          )
          .style
          .color;
      final beforeHover = colorOf();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('35')));
      await tester.pump();

      final duringHover = colorOf();
      expect(duringHover, isNot(beforeHover));

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 200));
    });

    guardedTestWidgets('an interactive week number shows a click cursor', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 60,
          height: 600,
          child: LayrzCalendarWeekGutter(
            weekStarts: [DateTime(2026, 8, 24)],
            onWeekTap: (_) {},
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
      expect(mouseRegion.cursor, SystemMouseCursors.click);
    });
  });
}

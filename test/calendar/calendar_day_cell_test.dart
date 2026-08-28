import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarDayCell', () {
    guardedTestWidgets('renders the day-of-month number', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 120,
          height: 120,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: const [],
          ),
        ),
      );

      expect(find.text('28'), findsOneWidget);
    });

    guardedTestWidgets('renders up to the visible cap of event chips, collapsing the rest into an overflow chip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const maxVisibleSlots = 3;
      final entries = List.generate(
        maxVisibleSlots + 2,
        (i) => LayrzCalendarEntry(
          title: 'Event $i',
          start: DateTime(2026, 8, 28),
          end: DateTime(2026, 8, 28),
        ),
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: entries,
            maxVisibleSlots: maxVisibleSlots,
          ),
        ),
      );

      // maxVisibleSlots=3, 5 entries -> 2 chips + the overflow chip reserving
      // its own slot, hiding 3 events (indices 2, 3, 4).
      for (var i = 0; i < 2; i++) {
        expect(find.text('Event $i'), findsOneWidget);
      }
      expect(find.text('Event 2'), findsNothing);
      expect(find.text('+3'), findsOneWidget);
    });

    guardedTestWidgets('renders no overflow chip when entries fit within the cap', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [
              LayrzCalendarEntry(title: 'One', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
            ],
          ),
        ),
      );

      expect(find.textContaining('+'), findsNothing);
    });

    guardedTestWidgets('a disabled day with events still renders those events', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 29),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: true,
            entries: [
              LayrzCalendarEntry(title: 'Weekend shift', start: DateTime(2026, 8, 29), end: DateTime(2026, 8, 29)),
            ],
          ),
        ),
      );

      // Disabled and "no events" are distinct code paths (per the plan's
      // criterion): a disabled day with events still shows its events, it is
      // not forced empty just because it is disabled.
      expect(find.text('Weekend shift'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
    });

    guardedTestWidgets('an empty, non-disabled day renders no event content and is not styled as disabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 30),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: const [],
          ),
        ),
      );

      expect(find.text('30'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    guardedTestWidgets('reservedLaneIndices counts toward the visible-events cap alongside single-day chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 1 single-day entry + 2 reserved multi-day lanes = 3 total slots,
      // exactly the maxVisibleSlots cap of 3 -- everything fits, no overflow.
      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [
              LayrzCalendarEntry(title: 'Chip A', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
            ],
            reservedLaneIndices: const {0, 1},
            maxVisibleSlots: 3,
          ),
        ),
      );

      expect(find.text('Chip A'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    guardedTestWidgets(
      'reserved lanes consume budget too: two reserved lanes plus two chips over cap collapses all chips into the '
      'overflow chip',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // 2 single-day entries + 2 reserved multi-day lanes = 4 total slots
        // against a cap of 3. The 2 reserved lanes already consume 2 of the 3
        // slots, leaving only 1 -- not enough for both chips, so that last
        // slot becomes the overflow chip and neither single-day chip is
        // visible. This is the documented, real cost of a bar occupying a
        // higher lane: a day's own chips lose budget to reserved lanes.
        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: DateTime(2026, 8, 28),
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [
                LayrzCalendarEntry(title: 'Chip A', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
                LayrzCalendarEntry(title: 'Chip B', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
              ],
              reservedLaneIndices: const {0, 1},
              maxVisibleSlots: 3,
            ),
          ),
        );

        expect(find.text('Chip A'), findsNothing);
        expect(find.text('Chip B'), findsNothing);
        expect(find.text('+2'), findsOneWidget);
      },
    );

    guardedTestWidgets('an event chip renders filled: full-opacity accent background, contrast-color text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const accent = Color(0xFF9C27B0);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [
              LayrzCalendarEntry(
                title: 'Filled event',
                start: DateTime(2026, 8, 28),
                end: DateTime(2026, 8, 28),
                color: accent,
              ),
            ],
          ),
        ),
      );

      final chipContainer = tester.widget<Container>(
        find.ancestor(of: find.text('Filled event'), matching: find.byType(Container)).first,
      );
      final decoration = chipContainer.decoration as BoxDecoration;

      // Filled, not filledTonal -- the accent paints at full opacity, no
      // alpha blend, and the text uses the contrast color rather than the
      // accent itself.
      expect(decoration.color, accent);
      final textStyle = tester.widget<Text>(find.text('Filled event')).style;
      expect(textStyle?.color, accent.contrastColor);
    });

    guardedTestWidgets('totalEventCount overrides entries.length for the semantics announcement only', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: DateTime(2026, 8, 28),
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [
                LayrzCalendarEntry(title: 'Chip A', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
              ],
              reservedLaneIndices: const {0},
              totalEventCount: 2,
            ),
          ),
        );

        // The visible chip count reflects only `entries` (one chip rendered),
        // but the semantics label reports the full total including the
        // multi-day event the surface tracks separately.
        expect(find.text('Chip A'), findsOneWidget);
        final semantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
        expect(semantics.label, contains('2 events'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a cell with maxVisibleSlots of 0 renders exactly the overflow chip, never an empty cell', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [
              LayrzCalendarEntry(title: 'Chip A', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
              LayrzCalendarEntry(title: 'Chip B', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
            ],
            maxVisibleSlots: 0,
          ),
        ),
      );

      expect(find.text('Chip A'), findsNothing);
      expect(find.text('Chip B'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    guardedTestWidgets('the overflow chip reserves its own slot rather than overflowing past maxVisibleSlots', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const maxVisibleSlots = 3;
      final entries = List.generate(
        maxVisibleSlots + 1,
        (i) => LayrzCalendarEntry(title: 'Event $i', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
      );

      // Guarded so a RenderFlex overflow (the bug this test protects against
      // if the overflow chip were appended AFTER maxVisibleSlots chips
      // instead of reserving its own slot) fails the test loudly.
      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: entries,
            maxVisibleSlots: maxVisibleSlots,
          ),
        ),
      );

      expect(find.text('Event 0'), findsOneWidget);
      expect(find.text('Event 1'), findsOneWidget);
      expect(find.text('Event 2'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    guardedTestWidgets('tapping the overflow chip calls onOverflowTap with this cell\'s date', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tappedDate;
      final date = DateTime(2026, 8, 28);
      final entries = List.generate(
        4,
        (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date),
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: date,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: entries,
            maxVisibleSlots: 3,
            onOverflowTap: (d) => tappedDate = d,
          ),
        ),
      );

      await tester.tap(find.text('+2'));
      await tester.pump();

      expect(tappedDate, date);
    });

    guardedTestWidgets(
      'the overflow chip renders inert -- no interactive semantics -- when onOverflowTap is null',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final date = DateTime(2026, 8, 28);
          final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: entries,
                maxVisibleSlots: 3,
              ),
            ),
          );

          final overflowFinder = find.text('+2');
          expect(overflowFinder, findsOneWidget);
          expect(tester.getSemantics(overflowFinder), matchesSemantics(isButton: false));
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets(
      'the overflow chip announces a concrete action, not merely the count',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final date = DateTime(2026, 8, 28);
          final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: entries,
                maxVisibleSlots: 3,
                onOverflowTap: (_) {},
              ),
            ),
          );

          final semantics = tester.getSemantics(find.text('+2'));
          expect(semantics.label, contains('more'));
          expect(semantics.label, contains('day view'));
          expect(semantics.label, contains('August 28'));
          expect(
            semantics,
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    guardedTestWidgets('hovering the interactive overflow chip changes its text color', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final date = DateTime(2026, 8, 28);
      final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: date,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: entries,
            maxVisibleSlots: 3,
            onOverflowTap: (_) {},
          ),
        ),
      );

      Color? colorOf() => tester
          .widget<AnimatedDefaultTextStyle>(
            find.ancestor(of: find.text('+2'), matching: find.byType(AnimatedDefaultTextStyle)),
          )
          .style
          .color;
      final beforeHover = colorOf();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('+2')));
      await tester.pump();

      final duringHover = colorOf();
      expect(duringHover, isNot(beforeHover));

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 200));
    });

    guardedTestWidgets(
      'the overflow chip renders as a pill filled with the neutral sf3 surface token, not bare text',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);
        final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: entries,
              maxVisibleSlots: 3,
              onOverflowTap: (_) {},
            ),
          ),
        );

        final tokens = LayrzTheme.of(tester.element(find.text('+2'))).tokens;

        final pillContainer = tester.widget<Container>(
          find.ancestor(of: find.text('+2'), matching: find.byType(Container)).first,
        );
        final decoration = pillContainer.decoration as BoxDecoration;

        expect(decoration.color, tokens.colors.sf3);
        expect(decoration.borderRadius, BorderRadius.circular(tokens.radius.r1));

        final textStyle = tester
            .widget<AnimatedDefaultTextStyle>(
              find.ancestor(of: find.text('+2'), matching: find.byType(AnimatedDefaultTextStyle)),
            )
            .style;
        expect(textStyle.color, tokens.colors.fg2);
      },
    );

    guardedTestWidgets(
      'the overflow chip pill matches an event chip\'s geometry: same height and shape',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);
        final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: entries,
              maxVisibleSlots: 3,
              onOverflowTap: (_) {},
            ),
          ),
        );

        final eventChipContainer = tester.widget<Container>(
          find.ancestor(of: find.text('Event 0'), matching: find.byType(Container)).first,
        );
        final overflowContainer = tester.widget<Container>(
          find.ancestor(of: find.text('+2'), matching: find.byType(Container)).first,
        );

        final eventDecoration = eventChipContainer.decoration as BoxDecoration;
        final overflowDecoration = overflowContainer.decoration as BoxDecoration;

        expect(overflowDecoration.borderRadius, eventDecoration.borderRadius);
        expect(overflowContainer.margin, eventChipContainer.margin);
        expect(overflowContainer.padding, eventChipContainer.padding);

        // Both sit inside a `SizedBox` fixing them to the same slot height.
        final eventSizedBox = tester.widget<SizedBox>(
          find.ancestor(of: find.text('Event 0'), matching: find.byType(SizedBox)).first,
        );
        final overflowSizedBox = tester.widget<SizedBox>(
          find.ancestor(of: find.text('+2'), matching: find.byType(SizedBox)).first,
        );
        expect(overflowSizedBox.height, eventSizedBox.height);
        expect(overflowSizedBox.height, kLayrzCalendarEventSlotHeight);
      },
    );

    guardedTestWidgets(
      'the inert (non-interactive) overflow chip is also styled as a pill, not bare text',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);
        final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: entries,
              maxVisibleSlots: 3,
            ),
          ),
        );

        final tokens = LayrzTheme.of(tester.element(find.text('+2'))).tokens;

        final pillContainer = tester.widget<Container>(
          find.ancestor(of: find.text('+2'), matching: find.byType(Container)).first,
        );
        final decoration = pillContainer.decoration as BoxDecoration;

        expect(decoration.color, tokens.colors.sf3);
      },
    );

    guardedTestWidgets('the overflow chip semantics label uses the correct month name for every month', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        // December, to exercise the tail of the month-name switch that
        // August-only fixtures elsewhere in this file never reach.
        final date = DateTime(2026, 12, 15);
        final entries = List.generate(4, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: entries,
              maxVisibleSlots: 3,
              onOverflowTap: (_) {},
            ),
          ),
        );

        final semantics = tester.getSemantics(find.text('+2'));
        expect(semantics.label, contains('December 15'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('tapping the date number navigates when dayNumberOpensDayView is true, and is inert when '
        'false', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var dateNumberTapped = false;
      final date = DateTime(2026, 8, 28);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: date,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: const [],
            onDateNumberTap: (_) => dateNumberTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('28'));
      await tester.pump();

      expect(dateNumberTapped, isTrue);
    });

    guardedTestWidgets('tapping the date number does nothing when dayNumberOpensDayView is false, and the number '
        'renders no hover state or interactive semantics', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var dateNumberTapped = false;
      final date = DateTime(2026, 8, 28);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: const [],
              dayNumberOpensDayView: false,
              onDateNumberTap: (_) => dateNumberTapped = true,
            ),
          ),
        );

        await tester.tap(find.text('28'));
        await tester.pump();

        expect(dateNumberTapped, isFalse);
        expect(find.byType(MouseRegion), findsNothing);

        final semantics = tester.getSemantics(find.text('28'));
        expect(semantics, isNot(matchesSemantics(isButton: true)));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('tapping an individual event chip or the cell background still does nothing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var overflowTapped = false;
      var dateNumberTapped = false;
      final date = DateTime(2026, 8, 28);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: date,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [LayrzCalendarEntry(title: 'Solo', start: date, end: date)],
            onOverflowTap: (_) => overflowTapped = true,
            onDateNumberTap: (_) => dateNumberTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Solo'));
      await tester.pump();
      await tester.tapAt(tester.getBottomRight(find.byType(LayrzCalendarDayCell)) - const Offset(1, 1));
      await tester.pump();

      expect(overflowTapped, isFalse);
      expect(dateNumberTapped, isFalse);
    });

    guardedTestWidgets('hovering the interactive date number changes its text color', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final date = DateTime(2026, 8, 28);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: date,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: const [],
            onDateNumberTap: (_) {},
          ),
        ),
      );

      Color? colorOf() => tester
          .widget<AnimatedDefaultTextStyle>(
            find.ancestor(of: find.text('28'), matching: find.byType(AnimatedDefaultTextStyle)),
          )
          .style
          .color;
      final beforeHover = colorOf();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('28')));
      await tester.pump();

      final duringHover = colorOf();
      expect(duringHover, isNot(beforeHover));

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 200));
    });

    guardedTestWidgets('the interactive date number carries a live semantics node announcing the navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final date = DateTime(2026, 8, 28);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: const [],
              onDateNumberTap: (_) {},
            ),
          ),
        );

        final semantics = tester.getSemantics(find.text('28'));
        expect(semantics.label, contains('August 28'));
        expect(semantics.label, contains('opens day view'));
        expect(
          semantics,
          matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });

    group('date number typography', () {
      guardedTestWidgets(
        'the date number resolves to body size with title weight/family, not a literal, and not plain body',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 120,
              height: 120,
              child: LayrzCalendarDayCell(
                date: DateTime(2026, 8, 28),
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: const [],
              ),
            ),
          );

          final style = tester
              .widget<AnimatedDefaultTextStyle>(
                find.ancestor(of: find.text('28'), matching: find.byType(AnimatedDefaultTextStyle)),
              )
              .style;
          final tokens = LayrzTheme.of(tester.element(find.text('28'))).tokens;

          // Kenny's ruling: "titleStyle is too big for the days on month
          // mode, let's use the body style, but inherit the title weight
          // and features" -- body's SIZE, title's WEIGHT/family.
          expect(style.fontSize, tokens.typography.body.fontSize);
          expect(style.fontWeight, tokens.typography.title.fontWeight);
          expect(style.fontFamily, tokens.typography.title.fontFamily);
          expect(style.fontWeight, isNot(tokens.typography.body.fontWeight));
        },
      );

      guardedTestWidgets(
        'the date number\'s rendered box fully contains its own text -- no clipping (regression)',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 120,
              height: 120,
              child: LayrzCalendarDayCell(
                date: DateTime(2026, 8, 28),
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: const [],
              ),
            ),
          );

          // `Text`'s own laid-out box stretches to fill whatever ancestor
          // constrains it (verified directly: a `Text` inside a too-short
          // `SizedBox` reports `getSize`/`getRect` equal to the `SizedBox`,
          // NOT its glyph bounds), so comparing rendered-box rects against
          // each other is a tautology that would not catch real clipping.
          // `RenderParagraph.textSize` reports the paragraph's actual
          // intrinsic content size regardless of the box it was laid out
          // into, so this compares that real content height against the
          // box height the date row actually constrained it to.
          final paragraph = tester.renderObject<RenderParagraph>(find.text('28'));

          expect(
            paragraph.textSize.height,
            lessThanOrEqualTo(paragraph.size.height),
            reason:
                'the date number\'s intrinsic content height (${paragraph.textSize.height}) exceeds the box it '
                'was laid out into (${paragraph.size.height}) -- the text is being clipped',
          );
        },
      );

      guardedTestWidgets(
        'a disabled date number is rendered in a distinguishable color from an in-month, non-disabled one',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 120,
              height: 120,
              child: LayrzCalendarDayCell(
                date: DateTime(2026, 8, 10),
                isToday: false,
                isOutsideMonth: false,
                isDisabled: true,
                entries: const [],
              ),
            ),
          );

          // Applying `tokens.typography.title` in place of `label` changed the
          // date number's font size/weight only -- the disabled/outside-month
          // color resolution stays entirely in `LayrzCalendarDayCellStyleSpec`
          // (unmodified by this change), so this pumps the actual disabled
          // widget and compares its resolved color against the spec computed
          // independently for a normal, non-disabled, in-month day -- proving
          // the color distinction survives the typography change without
          // needing a second `pumpThemed` call in the same test body.
          final tokens = LayrzTheme.of(tester.element(find.text('10'))).tokens;
          final normalSpec = LayrzCalendarDayCellStyleSpec.resolve(
            tokens: tokens,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
          );
          final disabledColor = tester
              .widget<AnimatedDefaultTextStyle>(
                find.ancestor(of: find.text('10'), matching: find.byType(AnimatedDefaultTextStyle)),
              )
              .style
              .color;

          expect(disabledColor, isNot(normalSpec.dateColor));
        },
      );

      guardedTestWidgets(
        'an outside-month date number is rendered in a distinguishable color from an in-month, non-disabled one',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 120,
              height: 120,
              child: LayrzCalendarDayCell(
                date: DateTime(2026, 8, 12),
                isToday: false,
                isOutsideMonth: true,
                isDisabled: false,
                entries: const [],
              ),
            ),
          );

          final tokens = LayrzTheme.of(tester.element(find.text('12'))).tokens;
          final normalSpec = LayrzCalendarDayCellStyleSpec.resolve(
            tokens: tokens,
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
          );
          final outsideMonthColor = tester
              .widget<AnimatedDefaultTextStyle>(
                find.ancestor(of: find.text('12'), matching: find.byType(AnimatedDefaultTextStyle)),
              )
              .style
              .color;

          expect(outsideMonthColor, isNot(normalSpec.dateColor));
        },
      );

      guardedTestWidgets('the date number\'s tappable/hoverable region extends beyond the digits\' own bounds', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 150,
            height: 150,
            child: LayrzCalendarDayCell(
              date: DateTime(2026, 8, 28),
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: const [],
              onDateNumberTap: (_) {},
            ),
          ),
        );

        final textSize = tester.getSize(find.text('28'));
        final hitAreaSize = tester.getSize(
          find.descendant(of: find.byType(LayrzCalendarDayCell), matching: find.byType(MouseRegion)),
        );

        expect(
          hitAreaSize.width,
          greaterThan(textSize.width),
          reason:
              'the hoverable/tappable region should be wider than the bare digits so a pointer landing '
              'just beside the number still registers hover/tap',
        );
      });
    });

    group('four-region tap contract (LayrzCalendar.onTap / LayrzCalendarEntry.onTap)', () {
      guardedTestWidgets('tapping the cell body (region 4) fires onTap with this cell\'s date only', (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tappedDate;
        var entryTapped = false;
        final date = DateTime(2026, 8, 28);

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [LayrzCalendarEntry(title: 'Solo', start: date, end: date, onTap: () => entryTapped = true)],
              onTap: (d) => tappedDate = d,
            ),
          ),
        );

        // Bottom-right corner of the cell body -- empty space, not the date
        // number, not an event chip.
        await tester.tapAt(tester.getBottomRight(find.byType(LayrzCalendarDayCell)) - const Offset(4, 4));
        await tester.pump();

        expect(tappedDate, date);
        expect(entryTapped, isFalse);
      });

      guardedTestWidgets(
        'tapping an event chip (region 3) fires that entry\'s own onTap only, never the cell\'s onTap',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          DateTime? tappedDate;
          var entryTapped = false;
          final date = DateTime(2026, 8, 28);
          final entry = LayrzCalendarEntry(title: 'Solo', start: date, end: date, onTap: () => entryTapped = true);

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: [entry],
                onTap: (d) => tappedDate = d,
              ),
            ),
          );

          await tester.tap(find.text('Solo'));
          await tester.pump();

          expect(entryTapped, isTrue);
          expect(tappedDate, isNull);
        },
      );

      guardedTestWidgets(
        'tapping the date number (region 1) fires only onDateNumberTap, not the cell\'s onTap or an entry\'s onTap',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          DateTime? dateNumberTapped;
          DateTime? tappedDate;
          var entryTapped = false;
          final date = DateTime(2026, 8, 28);

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: [LayrzCalendarEntry(title: 'Solo', start: date, end: date, onTap: () => entryTapped = true)],
                onDateNumberTap: (d) => dateNumberTapped = d,
                onTap: (d) => tappedDate = d,
              ),
            ),
          );

          await tester.tap(find.text('28'));
          await tester.pump();

          expect(dateNumberTapped, date);
          expect(tappedDate, isNull);
          expect(entryTapped, isFalse);
        },
      );

      guardedTestWidgets(
        'tapping the +N overflow chip (region 2) fires only onOverflowTap, not the cell\'s onTap or an entry\'s onTap',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          DateTime? overflowTapped;
          DateTime? tappedDate;
          var entryTapped = false;
          final date = DateTime(2026, 8, 28);

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 120,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: [
                  for (var i = 0; i < 5; i++)
                    LayrzCalendarEntry(title: 'Event $i', start: date, end: date, onTap: () => entryTapped = true),
                ],
                maxVisibleSlots: 2,
                onOverflowTap: (d) => overflowTapped = d,
                onTap: (d) => tappedDate = d,
              ),
            ),
          );

          final overflowFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('+'));
          expect(overflowFinder, findsOneWidget);

          await tester.tap(overflowFinder);
          await tester.pump();

          expect(overflowTapped, date);
          expect(tappedDate, isNull);
          expect(entryTapped, isFalse);
        },
      );

      guardedTestWidgets(
        'with the cell\'s onTap null and no entry carrying its own onTap, the cell is exactly as display-only as '
        'before: no hover, no cursor, no detector swallowing input',
        (tester) async {
          tester.view.physicalSize = const Size(400, 400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final date = DateTime(2026, 8, 28);

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: [LayrzCalendarEntry(title: 'Solo', start: date, end: date)],
              ),
            ),
          );

          // Tapping the cell body and the event chip must not throw and
          // must not be swallowed by a hidden detector -- there is nothing
          // to assert a callback against, so this proves the absence of a
          // gesture arena conflict instead.
          await tester.tapAt(tester.getBottomRight(find.byType(LayrzCalendarDayCell)) - const Offset(4, 4));
          await tester.pump();
          await tester.tap(find.text('Solo'));
          await tester.pump();

          // No MouseRegion wraps the cell body itself when both callbacks
          // are null -- the only MouseRegions present belong to the date
          // number and (when shown) the overflow chip, neither of which is
          // wired here, so no MouseRegion should exist in the whole tree at
          // all.
          expect(find.byType(MouseRegion), findsNothing);
        },
      );

      guardedTestWidgets('hovering the cell body shows a click cursor when onTap is set', (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: const [],
              onTap: (_) {},
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(LayrzCalendarDayCell),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.click);
      });
    });

    group('isPreview rendering', () {
      guardedTestWidgets('a preview event chip renders a ghosted treatment, not the solid fill', (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [
                LayrzCalendarEntry(title: 'Preview', start: date, end: date, isPreview: true),
              ],
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.ancestor(of: find.text('Preview'), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        // Ghosted: a border is present (the solid-fill baseline chip has
        // none) and the fill is not opaque.
        expect(decoration.border, isNotNull);
        expect(decoration.color!.a, lessThan(1.0));
      });

      guardedTestWidgets('a committed (non-preview) event chip has no border and an opaque fill', (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final date = DateTime(2026, 8, 28);

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [
                LayrzCalendarEntry(title: 'Committed', start: date, end: date),
              ],
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.ancestor(of: find.text('Committed'), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.border, isNull);
        expect(decoration.color!.a, 1.0);
      });
    });
  });
}

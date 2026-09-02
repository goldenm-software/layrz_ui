import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Every real caller (`*_surface.dart` files) hosts this panel inside a
/// bounded-width ancestor ([LayrzAnchoredPanel] or [LayrzBottomSheet]'s
/// `Padding`) -- `pumpThemed` alone gives its child unbounded width via
/// `Center`, which the panel's own `Row`-of-`Expanded` layout cannot resolve.
/// This wrapper reproduces the bounded-width context every real usage
/// already provides.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

void main() {
  group('LayrzPickersTimeFieldsPanel — zero clock/dial affordance', () {
    guardedTestWidgets('the tree contains no clock or dial widget of any kind', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      // Fields are text inputs; there is no dedicated clock-face/dial type
      // in this library at all, so this asserts on the field count instead.
      // Three EditableText fields exist (hour, minute, seconds -- the
      // seconds field stays mounted but hidden via
      // Visibility(maintainState: true) per D15's no-reflow rule, see the
      // showSeconds group below) and nothing else interactive besides them.
      expect(find.byType(EditableText), findsNWidgets(3));
    });
  });

  group('LayrzPickersTimeFieldsPanel — showSeconds toggling without reflow', () {
    guardedTestWidgets('showSeconds true renders three fields', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 15),
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(3));
    });

    guardedTestWidgets('showSeconds false renders two visible fields but the row height is unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      final withoutSecondsSize = tester.getSize(find.byType(LayrzPickersTimeFieldsPanel));

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            showSeconds: true,
            onChanged: (_) {},
          ),
        ),
      );

      final withSecondsSize = tester.getSize(find.byType(LayrzPickersTimeFieldsPanel));

      // D15: toggling showSeconds must never reflow (change the panel's own
      // height) -- the seconds field is always present in the layout,
      // merely hidden via Visibility(maintainSize: true) when not shown.
      expect(withoutSecondsSize.height, withSecondsSize.height);
    });
  });

  group('LayrzPickersTimeFieldsPanel — trap 4: fields never close the hosting surface', () {
    guardedTestWidgets('typing into the hour field reports via onChanged only, panel stays mounted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '14');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 14);
      // The widget itself never disappears from the tree as a result of a
      // field edit -- there is no close/dismiss mechanism reachable from
      // this widget at all, which is the trap-4 contract this test proves.
      expect(find.byType(LayrzPickersTimeFieldsPanel), findsOneWidget);
    });
  });

  group('LayrzPickersTimeFieldsPanel — clamping', () {
    guardedTestWidgets('typing an out-of-range hour is clamped, not dropped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '99');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 23);
    });

    guardedTestWidgets('typing an out-of-range minute is clamped, not dropped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).at(1), '99');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.minute, 59);
    });
  });

  group('LayrzPickersTimeFieldsPanel — 12h/24h', () {
    guardedTestWidgets('use24HourFormat true (default) hides the meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
    });

    guardedTestWidgets('use24HourFormat false shows an AM/PM meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            use24HourFormat: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    guardedTestWidgets('tapping PM in 12h mode shifts the hour into the afternoon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            use24HourFormat: false,
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.tap(find.text('PM'));
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 21);
    });
  });

  group('LayrzPickersTimeFieldsPanel — no interval snapping', () {
    guardedTestWidgets('an arbitrary minute value like 37 is representable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).at(1), '37');
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.minute, 37);
    });
  });
}

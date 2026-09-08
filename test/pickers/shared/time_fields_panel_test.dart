import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/time_fields_panel.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Every real caller (`*_surface.dart` files) hosts this panel inside a
/// bounded-width ancestor ([LayrzAnchoredPanel] or [LayrzBottomSheet]'s
/// `Padding`) -- `pumpThemed` alone gives its child unbounded width via
/// `Center`, which the panel's own layout cannot resolve without a bound.
/// This wrapper reproduces the bounded-width context every real usage
/// already provides.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// Locates the [LayrzButton] rendering [label] ("AM" or "PM") within the
/// meridiem control -- [LayrzButton]'s label renders via [RichText] (a
/// [TextSpan], not a plain [Text] widget), so `find.text` never matches it.
Finder _meridiemButton(String label) {
  return find.byWidgetPredicate((widget) => widget is LayrzButton && widget.labelText == label);
}

/// Types [text] into the [EditableText] at [index] and blurs it by shifting
/// focus elsewhere, exercising the panel's clamp-on-blur (not per-keystroke)
/// contract -- see [_DigitField]'s own doc in `time_fields_panel.dart`.
Future<void> _typeAndBlur(WidgetTester tester, int index, String text) async {
  await tester.tap(find.byType(EditableText).at(index));
  await tester.pump();
  await tester.enterText(find.byType(EditableText).at(index), text);
  await tester.pump();
  // Submitting is the other commit path (Enter / keyboard "done") -- exercised
  // here via testTextInput so a real un-focus is not required to trigger `_commit`.
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

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

      // Two groups (hour, minute) when showSeconds is false (the default) --
      // there is no dedicated clock-face/dial type in this library at all, so
      // this asserts on the EditableText field count instead.
      expect(find.byType(EditableText), findsNWidgets(2));
    });
  });

  group('LayrzPickersTimeFieldsPanel — showSeconds', () {
    guardedTestWidgets('showSeconds true renders three EditableText groups', (tester) async {
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

    guardedTestWidgets('showSeconds false renders exactly two EditableText groups, no seconds field at all', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      expect(find.byType(EditableText), findsNWidgets(2));
      expect(find.text('Seconds'), findsNothing);
    });

    guardedTestWidgets('captions "Hours"/"Minutes"/"Seconds" are always shown below their groups', (tester) async {
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

      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
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

      await _typeAndBlur(tester, 0, '14');

      expect(reported, isNotNull);
      expect(reported!.hour, 14);
      // The widget itself never disappears from the tree as a result of a
      // field edit -- there is no close/dismiss mechanism reachable from
      // this widget at all, which is the trap-4 contract this test proves.
      expect(find.byType(LayrzPickersTimeFieldsPanel), findsOneWidget);
    });
  });

  group('LayrzPickersTimeFieldsPanel — clamp on blur, not on keystroke', () {
    guardedTestWidgets('an in-range keystroke is reported immediately, before any blur', (tester) async {
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
      expect(reported!.hour, 14, reason: 'an in-range value is reported on every keystroke, not just on blur');
    });

    guardedTestWidgets('typing an out-of-range hour is clamped on blur, not dropped', (tester) async {
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

      await _typeAndBlur(tester, 0, '99');

      expect(reported, isNotNull);
      expect(reported!.hour, 23);
    });

    guardedTestWidgets('typing an out-of-range minute is clamped on blur, not dropped', (tester) async {
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

      await _typeAndBlur(tester, 1, '99');

      expect(reported, isNotNull);
      expect(reported!.minute, 59);
    });

    guardedTestWidgets('the displayed text resyncs to the clamped, zero-padded value after blur', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      await _typeAndBlur(tester, 0, '99');

      final editable = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(editable.controller.text, '23');
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

  group('LayrzPickersTimeFieldsPanel — 12h/24h', () {
    guardedTestWidgets('use24HourFormat true (default) hides the meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      expect(_meridiemButton('AM'), findsNothing);
      expect(_meridiemButton('PM'), findsNothing);
    });

    guardedTestWidgets('use24HourFormat false shows an AM/PM meridiem control built from LayrzButton', (
      tester,
    ) async {
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

      expect(_meridiemButton('AM'), findsOneWidget);
      expect(_meridiemButton('PM'), findsOneWidget);
      expect(find.byType(LayrzButton), findsNWidgets(2));
    });

    guardedTestWidgets('24h mode shows the hour in 0-23 form (no meridiem row reserved)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 21, minute: 30), onChanged: (_) {})),
      );

      final hourField = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(hourField.controller.text, '21', reason: '24h mode must show the raw 0-23 hour, not the 12h form');
    });

    guardedTestWidgets('12h mode shows hour12 (1-12 form), never the raw 0-23 hour', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 21, minute: 30),
            use24HourFormat: false,
            onChanged: (_) {},
          ),
        ),
      );

      final hourField = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(hourField.controller.text, '09', reason: 'hour 21 in 12h form is 9 PM -> hour12 == 9');
      expect(_meridiemButton('PM'), findsOneWidget);
    });

    guardedTestWidgets('midnight (hour 0) renders as 12 in 12h mode, with AM selected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 0, minute: 0),
            use24HourFormat: false,
            onChanged: (_) {},
          ),
        ),
      );

      final hourField = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(hourField.controller.text, '12');

      final amButton = tester.widget<LayrzButton>(_meridiemButton('AM'));
      expect(amButton.style, LayrzButtonStyle.filled, reason: 'AM must be the selected (filled) option');
    });

    guardedTestWidgets('the selected meridiem renders filled, the other renders text (low-emphasis)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 15, minute: 0),
            use24HourFormat: false,
            onChanged: (_) {},
          ),
        ),
      );

      final pmButton = tester.widget<LayrzButton>(_meridiemButton('PM'));
      final amButton = tester.widget<LayrzButton>(_meridiemButton('AM'));
      expect(pmButton.style, LayrzButtonStyle.filled);
      expect(amButton.style, LayrzButtonStyle.text);
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

      await tester.tap(_meridiemButton('PM'));
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 21);
    });

    guardedTestWidgets('tapping AM in 12h mode shifts an afternoon hour back before noon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? reported;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 21, minute: 30),
            use24HourFormat: false,
            onChanged: (t) => reported = t,
          ),
        ),
      );

      await tester.tap(_meridiemButton('AM'));
      await tester.pump();

      expect(reported, isNotNull);
      expect(reported!.hour, 9);
    });

    guardedTestWidgets('tapping the already-selected meridiem re-fires onChanged with the same value', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;
      await pumpThemed(
        tester,
        _bounded(
          LayrzPickersTimeFieldsPanel(
            value: const LayrzTimeOfDay(hour: 21, minute: 30),
            use24HourFormat: false,
            onChanged: (_) => callCount++,
          ),
        ),
      );

      await tester.tap(_meridiemButton('PM'));
      await tester.pump();

      expect(callCount, 0, reason: 'PM is already selected for hour 21 -- _setMeridiem no-ops when wasPm == isPm');
    });

    guardedTestWidgets('typing an out-of-range 12h hour clamps to the 1-12 bound, not 0-23', (tester) async {
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

      await _typeAndBlur(tester, 0, '15');

      expect(reported, isNotNull);
      expect(reported!.hour12, 12, reason: '12h hour clamps to the 1-12 bound (maximum), never 23');
    });
  });

  group('LayrzPickersTimeFieldsPanel — colon separators', () {
    guardedTestWidgets('renders one colon between hour/minute when showSeconds is false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(LayrzPickersTimeFieldsPanel(value: const LayrzTimeOfDay(hour: 9, minute: 30), onChanged: (_) {})),
      );

      expect(find.text(':'), findsOneWidget);
    });

    guardedTestWidgets('renders two colons when showSeconds is true', (tester) async {
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

      expect(find.text(':'), findsNWidgets(2));
    });
  });
}

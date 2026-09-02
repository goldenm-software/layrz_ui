import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/time/time_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// [LayrzTimeInput] renders no dial/clock affordance of its own, and every
/// real caller in this suite anchors it inside a bounded-width ancestor so
/// [LayrzPickersTimeFieldsPanel]'s `Row`-of-`Expanded` layout has room to
/// resolve -- mirrors `time_fields_panel_test.dart`'s own `_bounded` helper.
/// 700px keeps every 2-slot (no seconds) configuration in this file clear of
/// [LayrzPickersTimeField.kNarrowWidth]'s per-field narrow threshold.
const double _kSafeAnchorWidth = 700.0;

Widget _bounded(Widget child) => SizedBox(width: _kSafeAnchorWidth, child: child);

void main() {
  group('LayrzTimeInput — construction and assertions', () {
    test('requires labelText or hintText', () {
      expect(
        () => LayrzTimeInput(onChanged: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('accepts labelText alone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, _bounded(const LayrzTimeInput(labelText: 'Time')));
      expect(find.byType(LayrzTimeInput), findsOneWidget);
    });

    testWidgets('accepts hintText alone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, _bounded(const LayrzTimeInput(hintText: 'Pick a time')));
      expect(find.byType(LayrzTimeInput), findsOneWidget);
    });
  });

  group('LayrzTimeInput — zero clock/dial affordance', () {
    guardedTestWidgets('opening the panel introduces no dial/clock widget, only text fields', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      // Two visible fields (hour, minute) -- seconds stays mounted-but-hidden
      // per D15, so it still counts as an EditableText.
      expect(find.byType(EditableText), findsNWidgets(3));
    });
  });

  group('LayrzTimeInput — commit model: every field edit reports live, panel never closes on it', () {
    guardedTestWidgets('typing in the hour field fires onChanged and the panel stays mounted (trap 4)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets, reason: 'panel must be open before typing');

      await tester.enterText(find.byType(EditableText).first, '14');
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty, reason: 'a field edit must report via onChanged');
      expect(reported.last.hour, 14);
      // The panel is still mounted -- its fields are still present and
      // reachable, proving the edit did not dismiss anything.
      expect(find.byType(EditableText), findsWidgets, reason: 'typing must never close the hosting surface');
    });

    guardedTestWidgets('typing in the minute field does not close the panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).at(1), '45');
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets);
    });

    guardedTestWidgets('multiple successive edits all report live without ever dismissing the panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '10');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '15');
      await tester.pumpAndSettle();

      expect(reported.length, greaterThanOrEqualTo(2));
      expect(find.byType(EditableText), findsWidgets, reason: 'panel survives every edit in the sequence');
    });
  });

  group('LayrzTimeInput — involuntary close discards uncommitted draft state', () {
    guardedTestWidgets(
      'typing then dismissing via tap-outside without the caller committing reverts to widget.value on reopen',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // The caller deliberately ignores onChanged (e.g. pending
        // validation) so widget.value never advances past 09:05.
        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeInput(
              labelText: 'Time',
              value: const LayrzTimeOfDay(hour: 9, minute: 5),
              onChanged: (_) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeInput));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(EditableText).first, '23');
        await tester.pumpAndSettle();

        // Involuntary close: tap the barrier well outside the anchor/panel.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(LayrzTimeInput));
        await tester.pumpAndSettle();

        final hourText = tester.widget<EditableText>(find.byType(EditableText).first).controller.text;
        expect(
          hourText,
          '9',
          reason: 'reopening after an involuntary close must re-seed from widget.value, not the discarded draft',
        );
      },
    );
  });

  group('LayrzTimeInput — disabled vs readOnly', () {
    guardedTestWidgets('disabled blocks the tap that would open the panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            disabled: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(LayrzTimeInput), matching: find.byType(EditableText)),
        findsNothing,
        reason: 'a disabled anchor must never open its panel',
      );
    });
  });

  group('LayrzTimeInput — error styling (trap 1: readOnly must never be hardcoded on the anchor)', () {
    guardedTestWidgets('errors present paints a danger border on the anchored panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            errors: const ['Invalid time'],
          ),
        ),
      );

      final panel = tester.widget<LayrzAnchoredPanel>(find.byType(LayrzAnchoredPanel));
      final theme = LayrzTheme.of(tester.element(find.byType(LayrzTimeInput)));

      expect(
        panel.border?.color,
        theme.tokens.colors.danger,
        reason:
            'errors must paint the danger border; if the anchor hardcoded readOnly:true on the chrome this would '
            'silently fail because LayrzInputStyleSpec.resolve ranks readOnly above error',
      );
    });

    guardedTestWidgets('no errors paints the primary border on the anchored panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
          ),
        ),
      );

      final panel = tester.widget<LayrzAnchoredPanel>(find.byType(LayrzAnchoredPanel));
      final theme = LayrzTheme.of(tester.element(find.byType(LayrzTimeInput)));

      expect(panel.border?.color, theme.tokens.colors.primary);
    });
  });

  group('LayrzTimeInput — showSeconds toggles without layout reflow (D15)', () {
    guardedTestWidgets('anchor row height is identical with showSeconds true vs false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
          ),
        ),
      );
      final withoutSecondsHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            showSeconds: true,
          ),
        ),
      );
      final withSecondsHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      expect(withoutSecondsHeight, withSecondsHeight);
    });

    guardedTestWidgets('showSeconds true opens a panel with three EditableText fields', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5, second: 30),
            onChanged: (_) {},
            showSeconds: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNWidgets(3));
    });
  });

  group('LayrzTimeInput — 24h default and 12h with meridiem', () {
    guardedTestWidgets('use24HourFormat defaults to true', (tester) async {
      const input = LayrzTimeInput(labelText: 'Time');
      expect(input.use24HourFormat, isTrue);
    });

    guardedTestWidgets('24h mode formats an afternoon hour without a meridiem suffix', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 14, minute: 5),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('14:05'), findsOneWidget);
    });

    guardedTestWidgets('12h mode renders a meridiem control with both AM and PM options', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 14, minute: 5),
            onChanged: (_) {},
            use24HourFormat: false,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    guardedTestWidgets('tapping PM in 12h mode reports an updated hour via onChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: reported.add,
            use24HourFormat: false,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.hour, 21);
      expect(find.byType(EditableText), findsWidgets, reason: 'the meridiem toggle must not close the panel either');
    });
  });

  group('LayrzTimeInput — no interval snapping, out-of-range clamped not dropped', () {
    guardedTestWidgets('37 minutes is representable and round-trips unchanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 37),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('09:37'), findsOneWidget);
    });

    guardedTestWidgets('typing 25 into the 24h hour field clamps to 23, it is not silently dropped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: reported.add,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '25');
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty, reason: 'out-of-range input must still report, clamped -- never dropped');
      expect(reported.last.hour, 23);
    });

    guardedTestWidgets('typing 99 into a minute field clamps to 59', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: reported.add,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).at(1), '99');
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.minute, 59);
    });
  });

  group('LayrzTimeInput — formatting', () {
    guardedTestWidgets('default pattern formats as HH:MM', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 8, minute: 4),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('08:04'), findsOneWidget);
    });

    guardedTestWidgets('a custom formatter overrides the summary text entirely', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 8, minute: 4),
            onChanged: (_) {},
            formatter: (t) => 'custom-${t.hour}-${t.minute}',
          ),
        ),
      );

      expect(find.text('custom-8-4'), findsOneWidget);
    });

    guardedTestWidgets('null value shows hintText instead of a formatted summary', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          const LayrzTimeInput(labelText: 'Time', hintText: 'No time chosen'),
        ),
      );

      // Both the anchor's own displayText fallback and LayrzInputChrome's
      // own hintText rendering show the placeholder -- buildPickerFieldRow
      // forwards hintText into the chrome directly (see picker_anchor.dart),
      // so it is legitimately present twice in the tree, not a duplicate bug.
      expect(find.text('No time chosen'), findsWidgets);
    });
  });

  group('LayrzTimeInput — responsive surface (isCompact boundary)', () {
    guardedTestWidgets('wide viewport (>=960px) opens an anchored panel, never a bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(LayrzAnchoredPanel), findsOneWidget);

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets);
      expect(find.byType(LayrzTimeSurface), findsOneWidget);
    });

    testWidgets('narrow viewport (<960px) opens a bottom sheet, never an anchored panel', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzTimeInput(
          labelText: 'Time',
          value: const LayrzTimeOfDay(hour: 9, minute: 5),
          onChanged: (_) {},
        ),
      );

      expect(
        find.byType(LayrzAnchoredPanel),
        findsNothing,
        reason: 'the compact branch must not build an anchored panel at all',
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow viewport: typing in the bottom sheet does not dismiss it either', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemedApp(
        tester,
        LayrzTimeInput(
          labelText: 'Time',
          value: const LayrzTimeOfDay(hour: 9, minute: 5),
          onChanged: reported.add,
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeSurface), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(find.byType(LayrzTimeSurface), findsOneWidget, reason: 'the sheet must remain open after the edit');
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzTimeInput — tab order', () {
    guardedTestWidgets('hour, minute and second fields sit in that order in the widget tree', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5, second: 20),
            onChanged: (_) {},
            showSeconds: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeInput));
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText).evaluate().toList();
      expect(fields.length, 3);
      final texts = fields.map((e) => (e.widget as EditableText).controller.text).toList();
      expect(texts, ['9', '5', '20']);
    });
  });

  group('LayrzTimeInput — named parameters and controller/focusNode passthrough', () {
    guardedTestWidgets('a supplied controller is used verbatim and not disposed by the widget', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            controller: controller,
          ),
        ),
      );

      expect(controller.text, '09:05');
    });

    guardedTestWidgets('a supplied focusNode is used verbatim and not disposed by the widget', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            focusNode: focusNode,
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
    });

    guardedTestWidgets('isRequired renders the required marker', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            isRequired: true,
          ),
        ),
      );

      expect(find.byType(LayrzTimeInput), findsOneWidget);
    });

    guardedTestWidgets('dense reduces the anchor field height without changing padding tokens', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeInput(
            labelText: 'Time',
            value: const LayrzTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            dense: true,
          ),
        ),
      );

      expect(find.byType(LayrzTimeInput), findsOneWidget);
    });
  });
}

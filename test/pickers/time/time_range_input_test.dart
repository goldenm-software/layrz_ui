import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/time/time_range_surface.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// A wide-enough anchor that two stacked [LayrzPickersTimeFieldsPanel]
/// clusters (Start / End) stay clear of `LayrzPickersTimeField.kNarrowWidth`
/// -- mirrors `time_input_test.dart`'s `_kSafeAnchorWidth`, reused verbatim
/// since each cluster individually needs the same per-field room as
/// `LayrzTimeInput`'s single cluster.
const double _kSafeAnchorWidth = 700.0;

Widget _bounded(Widget child) => SizedBox(width: _kSafeAnchorWidth, child: child);

void main() {
  group('LayrzTimeRangeInput — construction and assertions', () {
    test('requires labelText or hintText', () {
      expect(
        () => LayrzTimeRangeInput(onChanged: (_, _) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('accepts labelText alone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, _bounded(const LayrzTimeRangeInput(labelText: 'Business hours')));
      expect(find.byType(LayrzTimeRangeInput), findsOneWidget);
    });

    testWidgets('accepts hintText alone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, _bounded(const LayrzTimeRangeInput(hintText: 'Pick a range')));
      expect(find.byType(LayrzTimeRangeInput), findsOneWidget);
    });

    testWidgets('does not crash on the very first frame (initState must not read context.l10n)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('09:00 – 17:00'), findsOneWidget);
    });
  });

  group('LayrzTimeRangeInput — zero clock/dial affordance', () {
    guardedTestWidgets('opening the panel introduces no dial/clock widget, only text fields and buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      // Two clusters * (hour, minute, hidden-seconds) = 6 EditableText.
      expect(find.byType(EditableText), findsNWidgets(6));
      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzTimeRangeInput — commit model: Cancel/Save shown from the first frame (trap 4)', () {
    guardedTestWidgets('the panel shows Cancel and Save immediately on open, before any edit', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(findButtonLabel(const LayrzUiL10nDefault().actionCancel), findsOneWidget);
      expect(findButtonLabel(const LayrzUiL10nDefault().actionSave), findsOneWidget);
    });

    guardedTestWidgets('typing in a field fires no onChanged and keeps the panel open (trap 4, non-negotiable)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '30');
      await tester.pumpAndSettle();

      expect(callCount, 0, reason: 'a field edit alone must never invoke onChanged -- only Save does');
      expect(find.byType(EditableText), findsWidgets, reason: 'typing must never close the hosting surface');
      expect(findButtonLabel(const LayrzUiL10nDefault().actionSave), findsOneWidget);
    });

    guardedTestWidgets('Save commits the edited pair and closes the panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (start, end) => reported.add((start, end)),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '8');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(reported.single.$1.hour, 8);
      expect(find.byType(LayrzTimeRangeSurface), findsNothing, reason: 'Save must close the panel');
    });

    guardedTestWidgets('Cancel reverts the edit and closes the panel without calling onChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '8');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionCancel));
      await tester.pumpAndSettle();

      expect(callCount, 0, reason: 'Cancel must never report a value');
      expect(find.byType(LayrzTimeRangeSurface), findsNothing, reason: 'Cancel must close the panel');
      expect(find.text('09:00 – 17:00'), findsOneWidget, reason: 'the committed value must remain unchanged');
    });
  });

  group('LayrzTimeRangeInput — auto-swap on reversed selection', () {
    guardedTestWidgets('Save auto-swaps when the edited end precedes the edited start', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (start, end) => reported.add((start, end)),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      // Edit start to be after end (start cluster hour field is index 0).
      await tester.enterText(find.byType(EditableText).first, '20');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      final (start, end) = reported.single;
      expect(start <= end, isTrue, reason: 'reversed input must auto-swap, never be rejected or thrown');
      expect(start.hour, 17, reason: 'the smaller edited endpoint (17:00) must become start');
      expect(end.hour, 20, reason: 'the larger edited endpoint (20:00) must become end');
    });
  });

  group('LayrzTimeRangeInput — involuntary close discards the draft', () {
    guardedTestWidgets(
      'typing then dismissing via tap-outside without Save reverts to widget.value on reopen',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          _bounded(
            LayrzTimeRangeInput(
              labelText: 'Business hours',
              startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
              endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
              onChanged: (_, _) {},
            ),
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(EditableText).first, '23');
        await tester.pumpAndSettle();

        // Involuntary close: tap the barrier well outside the anchor/panel.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        final startHourText = tester.widget<EditableText>(find.byType(EditableText).first).controller.text;
        expect(
          startHourText,
          '9',
          reason:
              'reopening after an involuntary close must re-seed from widget.startValue, not the discarded '
              'draft',
        );
      },
    );

    guardedTestWidgets('Escape reverts a pending edit without committing it (Escape == Cancel)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '23');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(callCount, 0, reason: 'Escape must never commit a pending edit');
      expect(find.byType(LayrzTimeRangeSurface), findsNothing, reason: 'Escape must close the panel');
    });
  });

  group('LayrzTimeRangeInput — disabled vs readOnly', () {
    guardedTestWidgets('disabled blocks the tap that would open the panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            disabled: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(LayrzTimeRangeInput), matching: find.byType(EditableText)),
        findsNothing,
        reason: 'a disabled anchor must never open its panel',
      );
    });
  });

  group('LayrzTimeRangeInput — error styling (trap 1: readOnly must never be hardcoded on the anchor)', () {
    // DESIGN-49: this widget no longer opens LayrzAnchoredPanel on desktop
    // (it opens LayrzPickerDrawer, which paints no anchor-adjacent border at
    // all -- see LayrzPickerDrawer's own class doc), so the danger/primary
    // border assertion these two tests exercised no longer applies. The
    // trap-1 regression guard itself (chrome.readOnly stays false with
    // errors present) is preserved below.
    guardedTestWidgets('errors present does not hardcode readOnly on the anchor chrome', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            errors: const ['Range spans a break'],
          ),
        ),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse, reason: 'trap 1 regression guard: the anchor must never hardcode readOnly');
      expect(chrome.errors, contains('Range spans a break'));
    });
  });

  group('LayrzTimeRangeInput — showSeconds toggles without layout reflow (D15)', () {
    guardedTestWidgets('anchor row height is identical with showSeconds true vs false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );
      final withoutSecondsHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            showSeconds: true,
          ),
        ),
      );
      final withSecondsHeight = tester.getSize(find.byType(LayrzInputChrome).first).height;

      expect(withoutSecondsHeight, withSecondsHeight);
    });

    guardedTestWidgets('showSeconds true opens a panel with six EditableText fields (two clusters of three)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0, second: 15),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0, second: 45),
            onChanged: (_, _) {},
            showSeconds: true,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNWidgets(6));
    });
  });

  group('LayrzTimeRangeInput — 24h default and 12h with meridiem', () {
    guardedTestWidgets('use24HourFormat defaults to true', (tester) async {
      const input = LayrzTimeRangeInput(labelText: 'Business hours');
      expect(input.use24HourFormat, isTrue);
    });

    guardedTestWidgets('12h mode renders a meridiem control for both clusters', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            use24HourFormat: false,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(find.text('AM'), findsNWidgets(2));
      expect(find.text('PM'), findsNWidgets(2));
    });
  });

  group('LayrzTimeRangeInput — no interval snapping, out-of-range clamped not dropped', () {
    guardedTestWidgets('37 minutes is representable and round-trips unchanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 37),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(find.text('09:37 – 17:00'), findsOneWidget);
    });

    guardedTestWidgets('typing 25 into the 24h end-hour field clamps to 23, it is not silently dropped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (start, end) => reported.add((start, end)),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      // End cluster: hour(3), minute(4), seconds(5, hidden) -- see the
      // trap-4 test above for the same index layout. Editing the end field
      // (rather than start) keeps the pair in order (9:00 <= 23:00), so
      // this isolates the clamp behaviour from the auto-swap rule tested
      // separately above.
      await tester.enterText(find.byType(EditableText).at(3), '25');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(reported.single.$2.hour, 23, reason: 'out-of-range input must clamp, never be silently dropped');
    });
  });

  group('LayrzTimeRangeInput — formatting', () {
    guardedTestWidgets('default pattern formats each endpoint as HH:MM joined by the l10n range separator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 8, minute: 4),
            endValue: const LayrzTimeOfDay(hour: 16, minute: 30),
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(find.text('08:04 – 16:30'), findsOneWidget);
    });

    guardedTestWidgets('a custom formatter overrides the summary text entirely', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 8, minute: 4),
            endValue: const LayrzTimeOfDay(hour: 16, minute: 30),
            onChanged: (_, _) {},
            formatter: (start, end) => 'custom-${start.hour}-to-${end.hour}',
          ),
        ),
      );

      expect(find.text('custom-8-to-16'), findsOneWidget);
    });

    guardedTestWidgets('null startValue or endValue shows hintText instead of a formatted summary', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          const LayrzTimeRangeInput(labelText: 'Business hours', hintText: 'No range chosen'),
        ),
      );

      expect(find.text('No range chosen'), findsWidgets);
    });
  });

  group('LayrzTimeRangeInput — responsive surface (isCompact boundary)', () {
    // DESIGN-49: LayrzAnchoredPanel is no longer used by this widget at any
    // viewport -- desktop opens LayrzPickerDrawer, compact opens
    // LayrzBottomSheet. Both push a route rather than mounting inline, so
    // neither the drawer's surface nor the anchored panel is present before
    // the tap.
    guardedTestWidgets('wide viewport (>=960px) opens the fixed-width drawer, never an anchored panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      expect(find.byType(LayrzAnchoredPanel), findsNothing);

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsWidgets);
      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget);
      final surfaceWidth = tester.getSize(find.byType(LayrzTimeRangeSurface)).width;
      expect(surfaceWidth, lessThanOrEqualTo(420.0), reason: 'the drawer is fixed-width, not the anchor\'s width');
    });

    testWidgets('narrow viewport (<960px) opens a bottom sheet, never an anchored panel', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzTimeRangeInput(
          labelText: 'Business hours',
          startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
          endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
          onChanged: (_, _) {},
        ),
      );

      expect(
        find.byType(LayrzAnchoredPanel),
        findsNothing,
        reason: 'the compact branch must not build an anchored panel at all',
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow viewport: the bottom sheet carries a name identifying what is being picked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        );

        await tester.tap(find.byType(LayrzTimeRangeInput));
        await tester.pumpAndSettle();

        // ignore: deprecated_member_use
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
        final labels = <String>[];
        void walk(SemanticsNode node) {
          final label = node.getSemanticsData().label;
          if (label.isNotEmpty) labels.add(label);
          node.visitChildren((child) {
            walk(child);
            return true;
          });
        }

        walk(root);
        expect(labels.any((l) => l.contains('Business hours')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('narrow viewport: typing in the bottom sheet does not dismiss it, and Save still commits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        LayrzTimeRangeInput(
          labelText: 'Business hours',
          startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
          endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
          onChanged: (start, end) => reported.add((start, end)),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(reported, isEmpty, reason: 'typing alone must not report a value even in the mobile sheet');
      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget, reason: 'the sheet must remain open after the edit');

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzTimeRangeInput — Save gating (no silent 9:00-17:00 default)', () {
    guardedTestWidgets('opening with a null value and tapping Save without touching anything fires no onChanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemedApp(
        tester,
        _bounded(LayrzTimeRangeInput(labelText: 'Business hours', onChanged: (_, _) => callCount++)),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isTrue, reason: 'Save must be visibly disabled while both clusters are unset');

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(callCount, 0, reason: 'a null-seeded field must never report a silent 9:00-17:00 default');
    });

    guardedTestWidgets('setting only the start cluster keeps Save disabled and reports nothing', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;

      await pumpThemedApp(
        tester,
        _bounded(LayrzTimeRangeInput(labelText: 'Business hours', onChanged: (_, _) => callCount++)),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isTrue);

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();
      expect(callCount, 0);
    });

    guardedTestWidgets('setting both clusters enables Save and reports exactly what was typed', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(labelText: 'Business hours', onChanged: (start, end) => reported.add((start, end))),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '11'); // start hour
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '15'); // start minute
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(3), '18'); // end hour
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(4), '45'); // end minute
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isFalse);

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(reported, hasLength(1));
      expect(reported.single.$1, const LayrzTimeOfDay(hour: 11, minute: 15));
      expect(reported.single.$2, const LayrzTimeOfDay(hour: 18, minute: 45));
      expect(reported.single.$1, isNot(const LayrzTimeOfDay(hour: 9, minute: 0)), reason: 'never the removed default');
      expect(reported.single.$2, isNot(const LayrzTimeOfDay(hour: 17, minute: 0)), reason: 'never the removed default');
    });

    guardedTestWidgets('a non-null caller value seeds correctly and Save is enabled immediately', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isFalse, reason: 'a populated field must not regress to disabled');
    });

    // DESIGN-98 regression (see LayrzDateTimeInput's identical test for the
    // maintainer's report this guards against). The test immediately above
    // only checks `isDisabled` on the button's own widget -- it never
    // actually presses Save. This closes that gap: reopen on an
    // already-complete (startValue, endValue) pair and tap Save with zero
    // interaction, asserting onChanged actually fires with the seeded
    // values.
    guardedTestWidgets('Save is already enabled on open when value is already complete, with zero interaction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <(LayrzTimeOfDay, LayrzTimeOfDay)>[];

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (start, end) => reported.add((start, end)),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      final saveButton = findButtonLabel(const LayrzUiL10nDefault().actionSave);
      final saveWidget = tester.widget<LayrzButton>(
        find.ancestor(of: saveButton, matching: find.byType(LayrzButton)).first,
      );
      expect(saveWidget.onTap, isNotNull, reason: 'Save must already be enabled -- no edit has happened yet.');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(reported, [(const LayrzTimeOfDay(hour: 9, minute: 0), const LayrzTimeOfDay(hour: 17, minute: 0))]);
    });
  });

  group('LayrzTimeRangeInput — start/end groups are distinguishable', () {
    guardedTestWidgets('the panel shows the start and end labels distinctly', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(LayrzTimeRangeInput));
      await tester.pumpAndSettle();

      final l10n = const LayrzUiL10nDefault();
      expect(find.text(l10n.timePickerStart), findsOneWidget);
      expect(find.text(l10n.timePickerEnd), findsOneWidget);
    });
  });

  group('LayrzTimeRangeInput — named parameters and controller/focusNode passthrough', () {
    guardedTestWidgets('a supplied controller is used verbatim and not disposed by the widget', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            controller: controller,
          ),
        ),
      );

      expect(controller.text, '09:00 – 17:00');
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
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
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
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            isRequired: true,
          ),
        ),
      );

      expect(find.byType(LayrzTimeRangeInput), findsOneWidget);
    });

    guardedTestWidgets('dense reduces the anchor field height without changing padding tokens', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        _bounded(
          LayrzTimeRangeInput(
            labelText: 'Business hours',
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onChanged: (_, _) {},
            dense: true,
          ),
        ),
      );

      expect(find.byType(LayrzTimeRangeInput), findsOneWidget);
    });
  });
}

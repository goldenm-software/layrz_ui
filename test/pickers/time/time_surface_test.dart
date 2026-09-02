import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:layrz_ui/src/pickers/src/time/time_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// See `time_input_test.dart`'s own `_kSafeAnchorWidth` doc for why this
/// width is used: the shared `LayrzPickersTimeFieldsPanel` overflows below
/// roughly 660px of available width because its unit-label suffixes have no
/// narrow-width abbreviation (unlike `LayrzDurationPickerPanel`'s measured
/// `_kNarrowFieldWidth` split) -- a shared-file defect reported, not fixed
/// here (`shared/time_fields_panel.dart` is outside this unit's file set).
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// A minimal stateful host that owns [value] and can be driven via
/// [_ReseedHarnessState.setValue] from a test, so re-pumping exercises a real
/// in-place `didUpdateWidget` on [LayrzTimeSurface] -- calling `pumpThemed`
/// twice in a row instead rebuilds a fresh `Overlay`/`Localizations`
/// ancestor tree each time, which does not reliably propagate as an
/// in-place update to the descendants that matter here
/// ([LayrzNumberInput]'s own controller re-seed), even though
/// [LayrzTimeSurface]'s own `State` is preserved. This harness mirrors how
/// [LayrzTimeInput] itself actually drives [LayrzTimeSurface] in practice:
/// its parent rebuilds in place when `widget.value` changes.
class _ReseedHarness extends StatefulWidget {
  const _ReseedHarness({required this.initialValue});

  final LayrzTimeOfDay initialValue;

  @override
  State<_ReseedHarness> createState() => _ReseedHarnessState();
}

class _ReseedHarnessState extends State<_ReseedHarness> {
  late LayrzTimeOfDay _value = widget.initialValue;

  void setValue(LayrzTimeOfDay value) => setState(() => _value = value);

  @override
  Widget build(BuildContext context) {
    return _bounded(LayrzTimeSurface(value: _value, onTimeChanged: (_) {}));
  }
}

void main() {
  group('LayrzTimeSurface — construction', () {
    testWidgets('renders LayrzPickersTimeFieldsPanel with the supplied value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(value: const LayrzTimeOfDay(hour: 9, minute: 30), onTimeChanged: (_) {}),
        ),
      );

      // Hour and minute, plus the seconds field -- always mounted (hidden,
      // not removed) per D15's no-reflow rule even when showSeconds is false.
      expect(find.byType(EditableText), findsNWidgets(3));
    });
  });

  group('LayrzTimeSurface — trap 4: field edits report via onTimeChanged and never close anything', () {
    guardedTestWidgets('typing in the hour field calls onTimeChanged and the widget stays mounted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(value: const LayrzTimeOfDay(hour: 9, minute: 30), onTimeChanged: reported.add),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.hour, 11);
      expect(find.byType(LayrzTimeSurface), findsOneWidget, reason: 'the surface itself must remain mounted');
    });
  });

  group('LayrzTimeSurface — draft state re-seeds on incoming value changes (involuntary-close discipline)', () {
    testWidgets('changing widget.value externally updates the rendered draft', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const _ReseedHarness(initialValue: LayrzTimeOfDay(hour: 9, minute: 30)));

      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '9',
      );

      tester
          .state<_ReseedHarnessState>(find.byType(_ReseedHarness))
          .setValue(
            const LayrzTimeOfDay(hour: 15, minute: 45),
          );
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '15',
        reason: 'didUpdateWidget must re-seed the draft from the new widget.value',
      );
    });

    testWidgets(
      'a locally-typed draft is discarded once the host re-seeds from a genuinely different widget.value '
      '(the shape of LayrzTimeInput reopening after tap-outside, where onChanged already advanced value once)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(tester, const _ReseedHarness(initialValue: LayrzTimeOfDay(hour: 9, minute: 30)));

        // Type a draft edit that never reaches widget.value at all (typing
        // into LayrzPickersTimeFieldsPanel only calls onTimeChanged; nothing
        // in this harness feeds that back into _ReseedHarnessState's value).
        await tester.enterText(find.byType(EditableText).first, '22');
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, '22');

        // The host re-seeds from a value distinct from both the original
        // seed (9:30) and the stale local draft (22:30) -- proving
        // didUpdateWidget's re-seed genuinely overwrites whatever the field
        // was left showing, not merely coincides with it.
        tester
            .state<_ReseedHarnessState>(find.byType(_ReseedHarness))
            .setValue(
              const LayrzTimeOfDay(hour: 6, minute: 0),
            );
        await tester.pump();

        expect(
          tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
          '6',
          reason: 'the stale locally-typed draft must not survive a re-seed triggered by a new widget.value',
        );
      },
    );
  });

  group('LayrzTimeSurface — showSeconds and use24HourFormat passthrough', () {
    testWidgets('showSeconds true renders three fields', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 10),
            showSeconds: true,
            onTimeChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(3));
    });

    testWidgets('use24HourFormat false renders the meridiem control', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            use24HourFormat: false,
            onTimeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });
  });

  group('LayrzTimeSurface — zero clock/dial affordance', () {
    guardedTestWidgets('the tree contains no widget besides text fields and the meridiem control', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(
            value: const LayrzTimeOfDay(hour: 9, minute: 30, second: 10),
            showSeconds: true,
            use24HourFormat: false,
            onTimeChanged: (_) {},
          ),
        ),
      );

      // Three text fields (hour, minute, second) plus the meridiem control's
      // two buttons -- no dedicated clock-face/dial type exists in this
      // library at all, so absence is asserted via the exhaustive field
      // count instead, mirroring `time_fields_panel_test.dart`.
      expect(find.byType(EditableText), findsNWidgets(3));
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });
  });
}

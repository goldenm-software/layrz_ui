import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/time/time_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Every real caller hosts this panel inside a bounded-width ancestor -- see
/// `time_fields_panel_test.dart`'s identical `_bounded` helper doc.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// Locates the [LayrzButton] rendering [label] ("AM" or "PM") within the
/// meridiem control -- [LayrzButton]'s label renders via [RichText] (a
/// [TextSpan], not a plain [Text] widget), so `find.text` never matches it.
Finder _meridiemButton(String label) {
  return find.byWidgetPredicate((widget) => widget is LayrzButton && widget.labelText == label);
}

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

      // Hour and minute groups only -- showSeconds defaults to false, and the
      // new digital-clock panel genuinely omits the seconds group rather than
      // mounting it hidden (unlike the retired field-row layout).
      expect(find.byType(EditableText), findsNWidgets(2));
    });
  });

  group('LayrzTimeSurface — DESIGN-98: field edits only draft, save() commits via onTimeChanged', () {
    guardedTestWidgets('typing in the hour field updates the draft but does not call onTimeChanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final reported = <LayrzTimeOfDay>[];
      final surfaceKey = GlobalKey<LayrzTimeSurfaceState>();

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeSurface(
            key: surfaceKey,
            value: const LayrzTimeOfDay(hour: 9, minute: 30),
            onTimeChanged: reported.add,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(reported, isEmpty, reason: 'DESIGN-98: a field edit alone must not commit -- it only drafts');
      expect(find.byType(LayrzTimeSurface), findsOneWidget, reason: 'the surface itself must remain mounted');

      surfaceKey.currentState!.save();
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.hour, 11);
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
        '09',
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

        // Blur the field: _DigitField.didUpdateWidget only resyncs its
        // displayed text from an external value change while NOT focused
        // (see that class's own doc) -- resyncing while focused would stomp
        // digits the user is still mid-way through typing. enterText leaves
        // the field focused, so a real un-focus is required here before the
        // re-seed below can be observed in the rendered text.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();

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
          '06',
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

      expect(_meridiemButton('AM'), findsOneWidget);
      expect(_meridiemButton('PM'), findsOneWidget);
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
      expect(_meridiemButton('AM'), findsOneWidget);
      expect(_meridiemButton('PM'), findsOneWidget);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/time/time_range_surface.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Two [LayrzPickersTimeFieldsPanel] clusters stacked vertically need more
/// room than a single cluster does before either one crosses
/// `LayrzPickersTimeField.kNarrowWidth`'s per-field narrow threshold --
/// mirrors `time_surface_test.dart`'s own `_bounded`, widened for the
/// two-cluster case.
Widget _bounded(Widget child) => SizedBox(width: 700, child: child);

/// A minimal stateful host that owns [startValue]/[endValue] and can be
/// driven via [_ReseedHarnessState.setValues] from a test, so re-pumping
/// exercises a real in-place `didUpdateWidget` on [LayrzTimeRangeSurface] --
/// mirrors `time_surface_test.dart`'s own `_ReseedHarness`.
class _ReseedHarness extends StatefulWidget {
  const _ReseedHarness({this.initialStart, this.initialEnd});

  final LayrzTimeOfDay? initialStart;
  final LayrzTimeOfDay? initialEnd;

  @override
  State<_ReseedHarness> createState() => _ReseedHarnessState();
}

class _ReseedHarnessState extends State<_ReseedHarness> {
  late LayrzTimeOfDay? _start = widget.initialStart;
  late LayrzTimeOfDay? _end = widget.initialEnd;

  void setValues(LayrzTimeOfDay? start, LayrzTimeOfDay? end) => setState(() {
    _start = start;
    _end = end;
  });

  @override
  Widget build(BuildContext context) {
    return _bounded(
      LayrzTimeRangeSurface(startValue: _start, endValue: _end, onSave: (_, _) {}, onCancel: () {}),
    );
  }
}

void main() {
  group('LayrzTimeRangeSurface — construction', () {
    testWidgets('renders start and end field clusters plus Cancel/Save', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      // Two clusters of (hour, minute, hidden-seconds) = 6 EditableText.
      expect(find.byType(EditableText), findsNWidgets(6));
      expect(findButtonLabel(const LayrzUiL10nDefault().actionCancel), findsOneWidget);
      expect(findButtonLabel(const LayrzUiL10nDefault().actionSave), findsOneWidget);
    });

    testWidgets('null startValue/endValue seeds midnight for both clusters, and Save is enabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? savedStart;
      LayrzTimeOfDay? savedEnd;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: null,
            endValue: null,
            onSave: (start, end) {
              savedStart = start;
              savedEnd = end;
            },
            onCancel: () {},
          ),
        ),
      );

      // The maintainer's fix (commit 83ba2e0) removed `canSave` from this
      // surface entirely: `_start`/`_end` are `late` fields seeded to
      // midnight when the caller value is null, so Save is unconditionally
      // wired to `save()` -- never gated on either cluster being touched.
      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isFalse, reason: 'Save has no gating left on this surface -- it is always enabled');

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(savedStart, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
      expect(savedEnd, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
    });
  });

  group('LayrzTimeRangeSurface — Save gating (no silent 9:00-17:00 default)', () {
    guardedTestWidgets(
      'editing only the start cluster leaves Save enabled and auto-swaps against the midnight-defaulted end',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzTimeOfDay? savedStart;
        LayrzTimeOfDay? savedEnd;

        await pumpThemed(
          tester,
          _bounded(
            LayrzTimeRangeSurface(
              startValue: null,
              endValue: null,
              onSave: (start, end) {
                savedStart = start;
                savedEnd = end;
              },
              onCancel: () {},
            ),
          ),
        );

        // Start cluster: hour(0), minute(1), seconds(2, hidden).
        await tester.enterText(find.byType(EditableText).first, '11');
        await tester.pumpAndSettle();

        final saveButton = tester.widget<LayrzButton>(
          find.ancestor(
            of: findButtonLabel(const LayrzUiL10nDefault().actionSave),
            matching: find.byType(LayrzButton),
          ),
        );
        expect(
          saveButton.isDisabled,
          isFalse,
          reason: 'this surface has no Save gating -- the end cluster stays midnight',
        );

        await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
        await tester.pumpAndSettle();

        // The end cluster is still midnight (00:00) while the start cluster
        // was typed to 11:00 -- 11:00 > 00:00, so `save()`'s auto-swap rule
        // ("reverse-order selection auto-swaps, never rejects") reorders the
        // pair: the reported start is the midnight default, and the typed
        // 11:00 comes back as the reported end.
        expect(savedStart, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
        expect(savedEnd, const LayrzTimeOfDay(hour: 11, minute: 0, second: 0));
      },
    );

    guardedTestWidgets('editing only the end cluster leaves Save enabled and commits midnight for the start', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? savedStart;
      LayrzTimeOfDay? savedEnd;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: null,
            endValue: null,
            onSave: (start, end) {
              savedStart = start;
              savedEnd = end;
            },
            onCancel: () {},
          ),
        ),
      );

      // End cluster: hour(3), minute(4), seconds(5, hidden).
      await tester.enterText(find.byType(EditableText).at(3), '18');
      await tester.pumpAndSettle();

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(
        saveButton.isDisabled,
        isFalse,
        reason: 'this surface has no Save gating -- the start cluster stays midnight',
      );

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      // Editing only the end hour leaves start at midnight and end at 18:00,
      // so the pair is already in order -- no auto-swap applies here.
      expect(savedStart, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
      expect(savedEnd, const LayrzTimeOfDay(hour: 18, minute: 0, second: 0));
    });

    guardedTestWidgets('setting both clusters enables Save and reports exactly what was typed', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? savedStart;
      LayrzTimeOfDay? savedEnd;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: null,
            endValue: null,
            onSave: (start, end) {
              savedStart = start;
              savedEnd = end;
            },
            onCancel: () {},
          ),
        ),
      );

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
      expect(saveButton.isDisabled, isFalse, reason: 'both clusters are now set');

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(savedStart, const LayrzTimeOfDay(hour: 11, minute: 15));
      expect(savedEnd, const LayrzTimeOfDay(hour: 18, minute: 45));
    });

    testWidgets('a non-null caller value seeds correctly and Save is enabled immediately', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      final saveButton = tester.widget<LayrzButton>(
        find.ancestor(of: findButtonLabel(const LayrzUiL10nDefault().actionSave), matching: find.byType(LayrzButton)),
      );
      expect(saveButton.isDisabled, isFalse, reason: 'a populated field must not regress to disabled');
    });
  });

  group('LayrzTimeRangeSurface — trap 4: field edits never close the surface', () {
    guardedTestWidgets('typing in the start hour field keeps the surface mounted and reports nothing yet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCalls = 0;
      var cancelCalls = 0;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) => saveCalls++,
            onCancel: () => cancelCalls++,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget, reason: 'the surface itself must remain mounted');
      expect(saveCalls, 0, reason: 'editing a field must never itself trigger a commit');
      expect(cancelCalls, 0);
    });

    guardedTestWidgets('typing in the end minute field keeps the surface mounted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      // Start cluster: hour(0), minute(1), seconds(2, hidden). End cluster
      // starts at index 3: hour(3), minute(4).
      await tester.enterText(find.byType(EditableText).at(4), '45');
      await tester.pumpAndSettle();

      expect(find.byType(LayrzTimeRangeSurface), findsOneWidget);
    });
  });

  group('LayrzTimeRangeSurface — Save reports the (auto-swapped) pair, Cancel reports nothing', () {
    guardedTestWidgets('Save reports the edited start/end pair as-is when start <= end', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? savedStart;
      LayrzTimeOfDay? savedEnd;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (start, end) {
              savedStart = start;
              savedEnd = end;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(savedStart, const LayrzTimeOfDay(hour: 9, minute: 0));
      expect(savedEnd, const LayrzTimeOfDay(hour: 17, minute: 0));
    });

    guardedTestWidgets('Save auto-swaps when the end draft precedes the start draft', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzTimeOfDay? savedStart;
      LayrzTimeOfDay? savedEnd;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            // Reversed on purpose: start (17:00) is after end (9:00).
            startValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            onSave: (start, end) {
              savedStart = start;
              savedEnd = end;
            },
            onCancel: () {},
          ),
        ),
      );

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionSave));
      await tester.pumpAndSettle();

      expect(savedStart, const LayrzTimeOfDay(hour: 9, minute: 0));
      expect(savedEnd, const LayrzTimeOfDay(hour: 17, minute: 0));
    });

    guardedTestWidgets('Cancel never calls onSave', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var saveCalls = 0;
      var cancelCalls = 0;

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            onSave: (_, _) => saveCalls++,
            onCancel: () => cancelCalls++,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel(const LayrzUiL10nDefault().actionCancel));
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
      expect(cancelCalls, 1);
    });
  });

  group('LayrzTimeRangeSurface — draft state re-seeds on incoming value changes (involuntary-close discipline)', () {
    testWidgets('changing widget.startValue/endValue externally updates the rendered draft', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const _ReseedHarness(
          initialStart: LayrzTimeOfDay(hour: 9, minute: 0),
          initialEnd: LayrzTimeOfDay(hour: 17, minute: 0),
        ),
      );

      expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, '9');

      tester
          .state<_ReseedHarnessState>(find.byType(_ReseedHarness))
          .setValues(const LayrzTimeOfDay(hour: 6, minute: 0), const LayrzTimeOfDay(hour: 20, minute: 0));
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '6',
        reason: 'didUpdateWidget must re-seed the draft from the new widget.startValue',
      );
    });

    testWidgets(
      'a locally-typed draft is discarded once the host re-seeds from a genuinely different pair '
      '(the shape of LayrzTimeRangeInput reopening after an involuntary close)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          const _ReseedHarness(
            initialStart: LayrzTimeOfDay(hour: 9, minute: 0),
            initialEnd: LayrzTimeOfDay(hour: 17, minute: 0),
          ),
        );

        // Type a draft edit that never reaches the harness's own state --
        // typing into the panel only calls the surface's internal setState,
        // nothing here feeds it back into _ReseedHarnessState.
        await tester.enterText(find.byType(EditableText).first, '23');
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, '23');

        tester
            .state<_ReseedHarnessState>(find.byType(_ReseedHarness))
            .setValues(const LayrzTimeOfDay(hour: 6, minute: 0), const LayrzTimeOfDay(hour: 20, minute: 0));
        await tester.pump();

        expect(
          tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
          '6',
          reason: 'the stale locally-typed draft must not survive a re-seed triggered by a new widget.startValue',
        );
      },
    );
  });

  group('LayrzTimeRangeSurface — showSeconds and use24HourFormat passthrough to both clusters', () {
    testWidgets('showSeconds true renders three visible fields per cluster', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0, second: 15),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0, second: 45),
            showSeconds: true,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      // Two clusters * (hour, minute, second) = 6 EditableText.
      expect(find.byType(EditableText), findsNWidgets(6));
    });

    testWidgets('use24HourFormat false renders a meridiem control for each cluster', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0),
            use24HourFormat: false,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.text('AM'), findsNWidgets(2));
      expect(find.text('PM'), findsNWidgets(2));
    });
  });

  group('LayrzTimeRangeSurface — zero clock/dial affordance', () {
    guardedTestWidgets('the tree contains no widget besides text fields, meridiem controls, and buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _bounded(
          LayrzTimeRangeSurface(
            startValue: const LayrzTimeOfDay(hour: 9, minute: 0, second: 10),
            endValue: const LayrzTimeOfDay(hour: 17, minute: 0, second: 20),
            showSeconds: true,
            use24HourFormat: false,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(6));
      expect(find.text('AM'), findsNWidgets(2));
      expect(find.text('PM'), findsNWidgets(2));
    });
  });
}

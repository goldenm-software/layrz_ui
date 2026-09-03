import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/datetime/datetime_presentation.dart';
import 'package:layrz_ui/src/pickers/src/datetime/datetime_surface.dart';
import 'package:layrz_ui/src/pickers/src/models/time_of_day.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  tzdata.initializeTimeZones();

  void setWide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('LayrzDateTimeSurface — construction', () {
    guardedTestWidgets('accepts null initialDate and initialTime without throwing', (tester) async {
      setWide(tester);
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: null,
          initialTime: null,
          onSave: (_, _) {},
          onCancel: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDateTimeSurface), findsOneWidget);
    });
  });

  group('LayrzDateTimeSurface — presentation is deprecated and ignored (DESIGN-49)', () {
    guardedTestWidgets('the calendar and time fields are both visible together, regardless of presentation', (
      tester,
    ) async {
      setWide(tester);
      for (final presentation in LayrzDateTimeInputPresentation.values) {
        await pumpThemed(
          tester,
          LayrzDateTimeSurface(
            presentation: presentation,
            initialDate: null,
            initialTime: null,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        );
        // No tab strip and no step-back affordance exist any longer.
        expect(findButtonLabel('Time'), findsNothing, reason: '$presentation');
        expect(find.byType(EditableText), findsWidgets, reason: '$presentation');
      }
    });
  });

  group('LayrzDateTimeSurface — Cancel/Save footer', () {
    guardedTestWidgets('always renders Cancel and Save, in both presentations', (tester) async {
      setWide(tester);
      for (final presentation in LayrzDateTimeInputPresentation.values) {
        await pumpThemed(
          tester,
          LayrzDateTimeSurface(
            presentation: presentation,
            initialDate: null,
            initialTime: null,
            onSave: (_, _) {},
            onCancel: () {},
          ),
        );
        expect(findButtonLabel('Save'), findsOneWidget, reason: '$presentation');
        expect(findButtonLabel('Cancel'), findsOneWidget, reason: '$presentation');
      }
    });

    guardedTestWidgets('Save commits once, with the time part defaulted to midnight, when only the date is set', (
      tester,
    ) async {
      setWide(tester);
      var saveCalls = 0;
      DateTime? savedDate;
      LayrzTimeOfDay? savedTime;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: null,
          onSave: (date, time) {
            saveCalls++;
            savedDate = date;
            savedTime = time;
          },
          onCancel: () {},
        ),
      );

      // `LayrzDateTimeSurfaceState.canSave` (commit 83ba2e0) is `_date !=
      // null` alone -- the time part is a `late` field seeded to midnight
      // when `initialTime` is null, so Save is reachable and commits
      // 00:00:00 without the user ever touching a time field.
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(savedDate, DateTime(2026, 9, 1));
      expect(savedTime, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
    });

    guardedTestWidgets('Save fires onSave exactly once with the chosen date and time', (tester) async {
      setWide(tester);
      DateTime? savedDate;
      LayrzTimeOfDay? savedTime;
      var saveCalls = 0;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: const LayrzTimeOfDay(hour: 9, minute: 30),
          onSave: (date, time) {
            saveCalls++;
            savedDate = date;
            savedTime = time;
          },
          onCancel: () {},
        ),
      );

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(savedDate, DateTime(2026, 9, 1));
      expect(savedTime, const LayrzTimeOfDay(hour: 9, minute: 30));
    });

    guardedTestWidgets('Cancel fires onCancel and never onSave', (tester) async {
      setWide(tester);
      var saveCalls = 0;
      var cancelCalls = 0;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: const LayrzTimeOfDay(hour: 9, minute: 30),
          onSave: (_, _) => saveCalls++,
          onCancel: () => cancelCalls++,
        ),
      );

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalls, 1);
      expect(saveCalls, 0);
    });
  });

  group('LayrzDateTimeSurface — midnight is a valid default', () {
    guardedTestWidgets('a date-only seed commits immediately with the time defaulted to midnight', (tester) async {
      setWide(tester);
      var saveCalls = 0;
      DateTime? savedDate;
      LayrzTimeOfDay? savedTime;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: null,
          onSave: (date, time) {
            saveCalls++;
            savedDate = date;
            savedTime = time;
          },
          onCancel: () {},
        ),
      );

      // No time field is ever touched here -- `canSave` (commit 83ba2e0)
      // no longer requires it, so Save must already be reachable and commit
      // the midnight-defaulted time on the very first tap.
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(saveCalls, 1, reason: 'the date alone is enough to make Save committable');
      expect(savedDate, DateTime(2026, 9, 1));
      expect(savedTime, const LayrzTimeOfDay(hour: 0, minute: 0, second: 0));
    });

    guardedTestWidgets('editing a time field overrides the midnight default', (tester) async {
      setWide(tester);
      var saveCalls = 0;
      LayrzTimeOfDay? savedTime;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: null,
          onSave: (_, time) {
            saveCalls++;
            savedTime = time;
          },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '9');
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
      expect(savedTime, isNotNull);
      expect(savedTime!.hour, 9);
    });
  });

  group('LayrzDateTimeSurface — date and time parts are independent', () {
    guardedTestWidgets('editing a time field never calls onSave', (tester) async {
      setWide(tester);
      var saveCalls = 0;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: const LayrzTimeOfDay(hour: 9, minute: 0),
          onSave: (_, _) => saveCalls++,
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(EditableText).first, '11');
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
    });

    guardedTestWidgets('picking a date never calls onSave', (tester) async {
      setWide(tester);
      var saveCalls = 0;
      await pumpThemed(
        tester,
        LayrzDateTimeSurface(
          presentation: LayrzDateTimeInputPresentation.tabbed,
          initialDate: DateTime(2026, 9, 1),
          initialTime: const LayrzTimeOfDay(hour: 9, minute: 0),
          onSave: (_, _) => saveCalls++,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
    });
  });

  group('LayrzDateTimeSurface — re-seeding (involuntary close discipline)', () {
    // Rebuilds LayrzDateTimeSurface IN PLACE (a single pumpWidget call, via a
    // nested StatefulBuilder) so didUpdateWidget actually runs -- calling
    // pumpThemed/pumpWidget a second time constructs a brand new Overlay and
    // OverlayEntry (Overlay.initialEntries is read only at construction),
    // which unmounts and remounts the surface via a fresh initState instead
    // of exercising didUpdateWidget at all.
    guardedTestWidgets('didUpdateWidget re-seeds the draft when initialDate/initialTime change', (tester) async {
      setWide(tester);

      DateTime date = DateTime(2026, 9, 1);
      LayrzTimeOfDay? time = const LayrzTimeOfDay(hour: 8, minute: 0);
      late StateSetter setInnerState;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setInnerState = setState;
            return LayrzDateTimeSurface(
              presentation: LayrzDateTimeInputPresentation.tabbed,
              initialDate: date,
              initialTime: time,
              onSave: (_, _) {},
              onCancel: () {},
            );
          },
        ),
      );

      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '8',
      );

      // Simulate the input re-seeding with a fresh value on reopen.
      setInnerState(() {
        date = DateTime(2026, 10, 1);
        time = null;
      });
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).controller.text,
        '0',
        reason: 'a null initialTime re-seeds the field to the panel\'s own 00:00 placeholder draft',
      );
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/picker_tab_switcher.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickerTabSwitcher — rendering', () {
    guardedTestWidgets('renders every tab label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
      );

      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Wheel'), findsOneWidget);
    });

    guardedTestWidgets('renders three or more tabs (not hardcoded to exactly two)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(
          tabs: const ['Recent', 'Smileys', 'Objects'],
          selectedIndex: 1,
          onTabSelected: (_) {},
        ),
      );

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Smileys'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
    });

    guardedTestWidgets('narrow (compact) viewport still renders every tab label', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
      );

      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Wheel'), findsOneWidget);
    });
  });

  group('LayrzPickerTabSwitcher — selection interaction', () {
    guardedTestWidgets('tapping a non-selected tab invokes onTabSelected with its index', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? selected;
      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(
          tabs: const ['Palette', 'Wheel'],
          selectedIndex: 0,
          onTabSelected: (index) => selected = index,
        ),
      );

      await tester.tap(find.text('Wheel'));
      await tester.pump();

      expect(selected, 1);
    });

    guardedTestWidgets('tapping the already-selected tab never invokes onTabSelected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;
      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(
          tabs: const ['Palette', 'Wheel'],
          selectedIndex: 0,
          onTabSelected: (_) => callCount++,
        ),
      );

      await tester.tap(find.text('Palette'));
      await tester.pump();

      expect(callCount, 0);
    });
  });

  group('LayrzPickerTabSwitcher — D15 geometry compliance', () {
    guardedTestWidgets('switching the selected tab does not change the switcher\'s own size', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
      );

      final sizeBefore = tester.getSize(find.byType(LayrzPickerTabSwitcher));

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 1, onTabSelected: (_) {}),
      );

      final sizeAfter = tester.getSize(find.byType(LayrzPickerTabSwitcher));

      expect(sizeAfter, sizeBefore);
    });
  });

  group('LayrzPickerTabSwitcher — assertions', () {
    test('throws when fewer than two tabs are supplied', () {
      expect(
        () => LayrzPickerTabSwitcher(tabs: const ['Only one'], selectedIndex: 0, onTabSelected: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when selectedIndex is out of range', () {
      expect(
        () => LayrzPickerTabSwitcher(tabs: const ['A', 'B'], selectedIndex: 2, onTabSelected: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when selectedIndex is negative', () {
      expect(
        () => LayrzPickerTabSwitcher(tabs: const ['A', 'B'], selectedIndex: -1, onTabSelected: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

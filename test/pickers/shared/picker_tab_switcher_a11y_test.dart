import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/picker_tab_switcher.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickerTabSwitcher — Accessibility', () {
    guardedTestWidgets('the selected tab exposes button semantics marked selected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
        );

        expect(
          tester.getSemantics(find.text('Palette')),
          matchesSemantics(label: 'Palette', isButton: true, hasSelectedState: true, isSelected: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a non-selected tab exposes button semantics marked not selected, with a tap action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
        );

        expect(
          tester.getSemantics(find.text('Wheel')),
          matchesSemantics(
            label: 'Wheel',
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the selected tab exposes no tap action (nothing to activate)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
        );

        expect(
          tester.getSemantics(find.text('Palette')),
          matchesSemantics(
            label: 'Palette',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('keyboard focus can reach a tab and the underline responds to focus', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickerTabSwitcher(tabs: const ['Palette', 'Wheel'], selectedIndex: 0, onTabSelected: (_) {}),
      );

      final context = tester.element(find.text('Wheel'));
      Focus.of(context).requestFocus();
      await tester.pump();

      expect(Focus.of(context).hasFocus, isTrue);
    });
  });
}

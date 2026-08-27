import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSlider A11y', () {
    Finder sliderSemanticsFinder() => find
        .descendant(
          of: find.byType(LayrzSlider),
          matching: find.byType(Semantics),
        )
        .first;

    guardedTestWidgets('exposes slider semantics with value, min-derived range, and label', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            labelText: 'Volume',
            value: 40,
            min: 0,
            max: 100,
            onChanged: (_) {},
          ),
        ),
      );

      // One step is 1% of a [0, 100] range with no divisions -> 1.
      //
      // Actions `hasTapAction`/`hasFocusAction`/`hasScrollLeftAction`/
      // `hasScrollRightAction` are present because they are the GestureDetector's
      // own semantics contribution (tap-to-position and horizontal drag), not
      // something LayrzSlider adds explicitly -- asserted here so a reader
      // knows they are expected, not a leak.
      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          label: 'Volume',
          value: '40',
          increasedValue: '41',
          decreasedValue: '39',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('announces divisions-derived increasedValue/decreasedValue', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(
            value: 50,
            min: 0,
            max: 100,
            divisions: 4,
            onChanged: (_) {},
          ),
        ),
      );

      // 4 divisions over [0, 100] -> step of 25.
      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          value: '50',
          increasedValue: '75',
          decreasedValue: '25',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('the increase semantics action raises the announced value', (tester) async {
      final handle = tester.ensureSemantics();
      double current = 50;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: LayrzSlider(
              value: current,
              min: 0,
              max: 100,
              divisions: 4,
              onChanged: (v) => setState(() => current = v),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(sliderSemanticsFinder());
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.increase);
      await tester.pump();

      expect(current, 75);
      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          value: '75',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('the decrease semantics action lowers the announced value', (tester) async {
      final handle = tester.ensureSemantics();
      double current = 50;

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: LayrzSlider(
              value: current,
              min: 0,
              max: 100,
              divisions: 4,
              onChanged: (v) => setState(() => current = v),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(sliderSemanticsFinder());
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();

      expect(current, 25);
      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          value: '25',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasScrollLeftAction: true,
          hasScrollRightAction: true,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('a disabled slider reports isEnabled false and no increase/decrease actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzSlider(value: 50, onChanged: (_) {}, disabled: true),
        ),
      );

      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          value: '50',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
          hasIncreaseAction: false,
          hasDecreaseAction: false,
          hasTapAction: false,
          hasScrollLeftAction: false,
          hasScrollRightAction: false,
        ),
      );

      handle.dispose();
    });

    guardedTestWidgets('a null onChanged slider (no callback) reports isEnabled false', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        const SizedBox(
          width: 300,
          child: LayrzSlider(value: 50),
        ),
      );

      expect(
        tester.getSemantics(sliderSemanticsFinder()),
        matchesSemantics(
          value: '50',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: true,
          hasFocusAction: true,
          hasIncreaseAction: false,
          hasDecreaseAction: false,
          hasTapAction: false,
          hasScrollLeftAction: false,
          hasScrollRightAction: false,
        ),
      );

      handle.dispose();
    });

    group('keyboard interaction', () {
      guardedTestWidgets('ArrowRight increases the value by one step', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(current, 75);
      });

      guardedTestWidgets('ArrowLeft decreases the value by one step', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(current, 25);
      });

      guardedTestWidgets('ArrowUp increases and ArrowDown decreases, same as Right/Left', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(current, 75);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(current, 50);
      });

      guardedTestWidgets('Home jumps to min', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 10,
                max: 100,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();

        expect(current, 10);
      });

      guardedTestWidgets('End jumps to max', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 90,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();

        expect(current, 90);
      });

      guardedTestWidgets('ArrowRight at max does not overshoot the bound', (tester) async {
        double current = 100;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(current, 100);
      });

      guardedTestWidgets('ArrowLeft at min does not undershoot the bound', (tester) async {
        double current = 0;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: (v) => setState(() => current = v),
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(current, 0);
      });

      guardedTestWidgets('keyboard input is ignored when disabled', (tester) async {
        double current = 50;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 300,
              child: LayrzSlider(
                value: current,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => current = v),
                disabled: true,
                autofocus: true,
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(current, 50);
      });
    });
  });
}

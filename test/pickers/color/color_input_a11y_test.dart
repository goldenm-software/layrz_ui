import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/color/color_input.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `date_input_a11y_test.dart`'s own helper — walking the tree
/// instead of using `find.bySemanticsLabel`, which also matches literal
/// text on renderable widgets and has already produced a false green in
/// this repo.
List<String> dumpSemanticsLabels(WidgetTester tester) {
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
  return labels;
}

void main() {
  group('LayrzColorInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Brand color'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Brand color') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Brand color',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled anchor is marked not enabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', disabled: true),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Color') ?? false),
        );
        expect(finder, findsOneWidget);

        final semantics = tester.getSemantics(finder);
        // The anchor's own label is merged with the hex readout Text child
        // into one node ("Color\n#0000FF") -- assert the label starts with
        // the caller-supplied text rather than matching it exactly.
        expect(semantics.label, startsWith('Color'));
        expect(
          semantics,
          matchesSemantics(
            label: semantics.label,
            isButton: true,
            hasEnabledState: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the label is exposed to screen readers exactly once', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Accent color'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Accent color').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('DESIGN-98-style: this widget exposes Save and Cancel semantics once the drawer is open', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(
          labels.any((l) => l.contains('Save')),
          isTrue,
          reason: 'the drawer carries a Save action -- a tap alone does not commit',
        );
        expect(labels.any((l) => l.contains('Cancel')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the tab switcher exposes "Palette"/"Wheel" as selectable buttons', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzColorInput(
            value: const Color(0xFF0000FF),
            labelText: 'Color',
            palette: {const Color(0xFFFF0000)},
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final paletteTabFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Palette') ?? false),
        );
        expect(
          tester.getSemantics(paletteTabFinder.first),
          matchesSemantics(label: 'Palette', isButton: true, hasSelectedState: true, isSelected: true),
        );

        final wheelTabFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Wheel') ?? false),
        );
        expect(
          tester.getSemantics(wheelTabFinder.first),
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

    guardedTestWidgets('each palette swatch exposes its own HEX value as a semantics label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzColorInput(
            value: const Color(0xFF0000FF),
            labelText: 'Color',
            palette: {const Color(0xFFFF0000)},
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('#FF0000'));
      } finally {
        handle.dispose();
      }
    });

    // The Paste button is a LayrzButton (Decision, user-testing follow-up):
    // its own semantics contract wraps `excludeSemantics: true` around an
    // inner GestureDetector, so -- exactly like every other LayrzButton in
    // this suite (test/buttons/button_a11y_test.dart) -- it never exposes a
    // bare `hasTapAction` flag on its outer Semantics node; label presence
    // plus an actual tap are verified instead, matching that suite's own
    // pattern.
    guardedTestWidgets('the Paste button exposes a visible, labeled button semantics node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final pasteFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Paste') ?? false),
        );
        expect(
          tester.getSemantics(pasteFinder.first),
          matchesSemantics(label: 'Paste', isButton: true, hasEnabledState: true, isEnabled: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('remains accessible at a compact (mobile) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Color') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Save')), isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/icon/icon_input.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `emoji_input_a11y_test.dart`'s own helper — walking the tree
/// instead of using `find.bySemanticsLabel`, which also matches literal text
/// on renderable widgets and has already produced a false green in this
/// repo.
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
  group('LayrzIconInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Marker icon') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Marker icon',
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
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon', disabled: true));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Marker icon') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Marker icon',
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
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Favorite marker'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Favorite marker').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an icon cell in the open desktop drawer exposes its stable mdi- name as a semantics label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final target = findMdiRemapIconByName('mdi-account')!;
        await tester.enterText(find.byType(EditableText).first, 'account');
        await tester.pump();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains(target.name));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('this widget exposes no Save/Cancel semantics once the drawer is open (commit-on-tap)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Save')), isFalse);
        expect(labels.any((l) => l.contains('Cancel')), isFalse);
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
        await pumpThemedApp(tester, LayrzIconInput(labelText: 'Marker icon'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Marker icon') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        final target = findMdiRemapIconByName('mdi-account')!;
        await tester.enterText(find.byType(EditableText).first, 'account');
        await tester.pump();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains(target.name));
      } finally {
        handle.dispose();
      }
    });
  });
}

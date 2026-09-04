import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzAccordion A11y', () {
    testWidgets('title is exposed to screen readers via semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Billing details',
            expanded: false,
            onExpansionChanged: (_) {},
            body: const Text('body'),
          ),
        );

        expect(find.bySemanticsLabel('Billing details'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('collapsed panel announces expanded=false, button, enabled, focusable, tappable', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Collapsed panel',
            expanded: false,
            onExpansionChanged: (_) {},
            body: const Text('body'),
          ),
        );

        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzAccordion),
                matching: find.byType(Semantics),
              )
              .first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Collapsed panel',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('expanded panel announces expanded=true', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Expanded panel',
            expanded: true,
            onExpansionChanged: (_) {},
            body: const Text('body'),
          ),
        );
        await tester.pumpAndSettle();

        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzAccordion),
                matching: find.byType(Semantics),
              )
              .first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Expanded panel',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasExpandedState: true,
            isExpanded: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled panel (no onExpansionChanged) announces disabled and no tap action', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Disabled panel',
            expanded: false,
            body: const Text('body'),
          ),
        );

        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzAccordion),
                matching: find.byType(Semantics),
              )
              .first,
        );

        expect(
          semanticsNode,
          matchesSemantics(
            label: 'Disabled panel',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isFocusable: false,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('title text is not announced twice (label + descendant Text both readable would double it)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Unique title text',
            expanded: false,
            onExpansionChanged: (_) {},
            body: const Text('body'),
          ),
        );

        // Only one semantics node should carry this label -- the descendant
        // Text is excluded from the tree via ExcludeSemantics.
        expect(find.bySemanticsLabel('Unique title text'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('collapsed body content is absent from the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Panel',
            expanded: false,
            onExpansionChanged: (_) {},
            body: const Text('secret-body-text'),
          ),
        );

        expect(find.bySemanticsLabel('secret-body-text'), findsNothing);
        expect(find.text('secret-body-text'), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('expanded body content is present in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Panel',
            expanded: true,
            onExpansionChanged: (_) {},
            body: const Text('visible-body-text'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('visible-body-text'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keyboard toggling updates the announced expanded state', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        bool expanded = false;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => LayrzAccordion(
              titleText: 'Keyboard panel',
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              body: const Text('body'),
            ),
          ),
        );

        final semanticsFinder = find.descendant(
          of: find.byType(LayrzAccordion),
          matching: find.byType(Semantics),
        );

        expect(
          tester.getSemantics(semanticsFinder.first),
          matchesSemantics(
            label: 'Keyboard panel',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );

        await tester.tap(find.text('Keyboard panel'));
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(semanticsFinder.first),
          matchesSemantics(
            label: 'Keyboard panel',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasExpandedState: true,
            isExpanded: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}

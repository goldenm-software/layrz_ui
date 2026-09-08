import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('LayrzSearchable', () {
    testWidgets('walkSemantics finds its text label', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzSearchable(
            text: 'Custom-painted mango label',
            child: CustomPaint(
              size: const Size(200, 32),
              painter: _NoopPainter(),
            ),
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

        final matches = walkSemantics(root, 'mango');

        expect(matches.length, 1);
        expect(matches.first.label, 'Custom-painted mango label');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('exposes exactly one Semantics node carrying the label', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzSearchable(
            text: 'Revenue by quarter',
            child: CustomPaint(
              size: const Size(200, 32),
              painter: _NoopPainter(),
            ),
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byType(LayrzSearchable)),
          matchesSemantics(label: 'Revenue by quarter'),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('wraps child in ExcludeSemantics so child contributes no semantics of its own', (tester) async {
      setWideViewport(tester);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzSearchable(
            text: 'Wrapper label',
            child: Semantics(
              label: 'Should never surface',
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      final excludeSemanticsFinder = find.descendant(
        of: find.byType(LayrzSearchable),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludeSemanticsFinder, findsOneWidget);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

        // Only the wrapper's own label is findable — the excluded child's
        // label never reaches the semantics tree at all.
        expect(walkSemantics(root, 'never surface'), isEmpty);
        expect(walkSemantics(root, 'Wrapper label'), hasLength(1));
      } finally {
        handle.dispose();
      }
    });
  });
}

/// A no-op [CustomPainter] standing in for real chart-label painting — this
/// test only cares that [LayrzSearchable]'s own semantics wrapper makes the
/// subtree findable, not what is actually drawn.
class _NoopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

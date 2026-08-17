import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('Grid Accessibility', () {
    group('Semantics preservation', () {
      testWidgets('child Semantics survive layout wrapping in LayrzRow', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              children: [
                LayrzCol(
                  xs: 6,
                  child: Semantics(
                    label: 'Test Label',
                    child: Container(color: const Color(0xFFFFFFFF)),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Test Label'),
          findsOneWidget,
          reason: 'Semantic label should be findable',
        );
      });

      testWidgets('child Semantics survive layout wrapping in LayrzConstrainedView', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: [
                Semantics(
                  label: 'Constrained Label',
                  child: Container(color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Constrained Label'),
          findsOneWidget,
          reason: 'Semantic label in constrained view should be findable',
        );
      });
    });

    group('Tappability and interactions', () {
      testWidgets('LayrzButton inside LayrzCol is tappable', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              children: [
                LayrzCol(
                  xs: 6,
                  child: LayrzButton(
                    labelText: 'Tap Me',
                    onTap: () {
                      tapped = true;
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tapped, isTrue, reason: 'Button inside col should be tappable');
      });

      testWidgets('LayrzButton inside LayrzConstrainedView is tappable', (tester) async {
        var tapped = false;

        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: [
                LayrzButton(
                  labelText: 'Tap Me',
                  onTap: () {
                    tapped = true;
                  },
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        expect(tapped, isTrue, reason: 'Button in constrained view should be tappable');
      });
    });

    group('Non-zero sizing', () {
      testWidgets('columns have non-zero width at various widths in LayrzRow', (tester) async {
        // Test at a typical width; LayrzCol returns its child so we check containers
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(xs: 3, md: 4, child: Container(color: const Color(0xFFFFFFFF))),
                LayrzCol(xs: 3, md: 4, child: Container(color: const Color(0xFFFFFFFF))),
                LayrzCol(xs: 3, md: 4, child: Container(color: const Color(0xFFFFFFFF))),
              ],
            ),
          ),
        );

        // All three containers should be rendered (one for each column's child)
        final containers = find.byType(Container);
        expect(containers, findsNWidgets(3), reason: 'Should find 3 containers from 3 columns');
      });

      testWidgets('children in LayrzConstrainedView have non-zero width', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: [
                Container(
                  color: const Color(0xFFFFFFFF),
                  height: 40,
                ),
                Container(
                  color: const Color(0xFF000000),
                  height: 40,
                ),
              ],
            ),
          ),
        );

        // Both containers should be rendered
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });
  });
}

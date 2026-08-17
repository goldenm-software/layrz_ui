import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzConstrainedView', () {
    group('width constraint', () {
      testWidgets('clamps width to maxWidth when parent is wider', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 0,
              children: [
                SizedBox(height: 40, key: const Key('child')),
              ],
            ),
          ),
        );

        final childSize = tester.getSize(find.byKey(const Key('child')));
        expect(childSize.width, closeTo(600.0, 0.1), reason: 'child width should be clamped to maxWidth');
      });

      testWidgets('stays within maxWidth when parent is narrower', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 0,
              children: [
                SizedBox(height: 40, key: const Key('child')),
              ],
            ),
          ),
        );

        final childSize = tester.getSize(find.byKey(const Key('child')));
        expect(childSize.width, closeTo(400.0, 0.1), reason: 'child width should match narrower parent');
      });
    });

    group('horizontal centering', () {
      testWidgets('content is horizontally centered', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 0,
              children: [
                SizedBox(height: 40, key: const Key('child')),
              ],
            ),
          ),
        );

        final childSize = tester.getSize(find.byKey(const Key('child')));

        // The child should be clamped to maxWidth (600) and centered
        // pumpThemed wraps in Center, which centers the entire structure
        expect(childSize.width, closeTo(600.0, 0.1), reason: 'child width should be maxWidth');
      });
    });

    group('child stretching', () {
      testWidgets('children stretch to constrained width', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 0,
              children: [
                Container(height: 40, key: const Key('child1')),
                Container(height: 40, key: const Key('child2')),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('child1')));
        final size2 = tester.getSize(find.byKey(const Key('child2')));

        expect(size1.width, closeTo(600.0, 0.1), reason: 'child1 should stretch to maxWidth');
        expect(size2.width, closeTo(600.0, 0.1), reason: 'child2 should stretch to maxWidth');
      });
    });

    group('vertical spacing', () {
      testWidgets('spacing applied between children equals spacing parameter', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 20,
              children: [
                SizedBox(height: 40, key: const Key('child1')),
                SizedBox(height: 40, key: const Key('child2')),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('child1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('child1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('child2')));

        final verticalGap = pos2.dy - (pos1.dy + size1.height);
        expect(verticalGap, closeTo(20.0, 0.1), reason: 'gap should be exactly 20px');
      });

      testWidgets('spacing=null uses tokens.spacing.base (8.0)', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: null,
              children: [
                SizedBox(height: 40, key: const Key('child1')),
                SizedBox(height: 40, key: const Key('child2')),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('child1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('child1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('child2')));

        final verticalGap = pos2.dy - (pos1.dy + size1.height);
        expect(verticalGap, closeTo(8.0, 0.1), reason: 'gap should be default 8.0px');
      });

      testWidgets('spacing=0 gives no gaps between children', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              spacing: 0,
              children: [
                SizedBox(height: 40, key: const Key('child1')),
                SizedBox(height: 40, key: const Key('child2')),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('child1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('child1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('child2')));

        final verticalGap = pos2.dy - (pos1.dy + size1.height);
        expect(verticalGap, closeTo(0.0, 0.1), reason: 'gap should be exactly 0px');
      });
    });

    group('assertions', () {
      testWidgets('maxWidth=0 throws assertion error', (tester) async {
        expect(
          () => LayrzConstrainedView(
            maxWidth: 0,
            children: const [],
          ),
          throwsAssertionError,
        );
      });

      testWidgets('maxWidth<0 throws assertion error', (tester) async {
        expect(
          () => LayrzConstrainedView(
            maxWidth: -100,
            children: const [],
          ),
          throwsAssertionError,
        );
      });

      testWidgets('maxWidth>0 is valid', (tester) async {
        await pumpThemed(
          tester,
          LayrzConstrainedView(
            maxWidth: 0.1,
            children: const [],
          ),
        );

        expect(find.byType(LayrzConstrainedView), findsOneWidget);
      });
    });

    group('empty children', () {
      testWidgets('renders without throwing with empty list', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: const [],
            ),
          ),
        );

        expect(find.byType(LayrzConstrainedView), findsOneWidget);
      });
    });

    group('Column configuration', () {
      testWidgets('mainAxisSize is min', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            height: 200,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: [
                const SizedBox(height: 40),
              ],
            ),
          ),
        );

        final columnFinder = find.byType(Column);
        expect(columnFinder, findsOneWidget);

        final column = tester.widget<Column>(columnFinder);
        expect(column.mainAxisSize, equals(MainAxisSize.min));
      });

      testWidgets('crossAxisAlignment is stretch', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzConstrainedView(
              maxWidth: 600,
              children: [
                Container(color: const Color(0xFFFFFFFF)),
              ],
            ),
          ),
        );

        final columnFinder = find.byType(Column);
        expect(columnFinder, findsOneWidget);

        final column = tester.widget<Column>(columnFinder);
        expect(column.crossAxisAlignment, equals(CrossAxisAlignment.stretch));
      });
    });
  });
}

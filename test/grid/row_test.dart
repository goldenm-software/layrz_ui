import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/grid.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzRow', () {
    group('empty children', () {
      testWidgets('renders without throwing with empty list', (tester) async {
        await pumpThemed(
          tester,
          const LayrzRow(children: []),
        );
        expect(find.byType(SizedBox), findsWidgets);
      });
    });

    group('single child', () {
      testWidgets('renders a single column', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              children: [
                LayrzCol(xs: 6, child: Container(color: const Color(0xFFFFFF00))),
              ],
            ),
          ),
        );
        expect(find.byType(LayrzCol), findsOneWidget);
      });
    });

    group('exact fit', () {
      testWidgets('[4,4,4] stays on ONE visual row with equal widths', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(
                  xs: 4,
                  child: SizedBox(height: 40, key: const Key('col1')),
                ),
                LayrzCol(
                  xs: 4,
                  child: SizedBox(height: 40, key: const Key('col2')),
                ),
                LayrzCol(
                  xs: 4,
                  child: SizedBox(height: 40, key: const Key('col3')),
                ),
              ],
            ),
          ),
        );

        // All three columns should be on the same visual row (same y position)
        final col1 = tester.getTopLeft(find.byKey(const Key('col1')));
        final col2 = tester.getTopLeft(find.byKey(const Key('col2')));
        final col3 = tester.getTopLeft(find.byKey(const Key('col3')));

        expect(col1.dy, equals(col2.dy), reason: 'col2 should be on same row as col1');
        expect(col2.dy, equals(col3.dy), reason: 'col3 should be on same row as col2');

        // Each column should be 600 * 4 / 12 = 200px wide
        final col1Size = tester.getSize(find.byKey(const Key('col1')));
        expect(col1Size.width, closeTo(200.0, 0.1));
      });
    });

    group('wrapping', () {
      testWidgets('[7,7] wraps to two visual rows', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(
                  xs: 7,
                  child: SizedBox(height: 40, key: const Key('col1')),
                ),
                LayrzCol(
                  xs: 7,
                  child: SizedBox(height: 40, key: const Key('col2')),
                ),
              ],
            ),
          ),
        );

        final col1 = tester.getTopLeft(find.byKey(const Key('col1')));
        final col2 = tester.getTopLeft(find.byKey(const Key('col2')));

        expect(col2.dy, greaterThan(col1.dy), reason: 'col2 should wrap to next row');
      });

      testWidgets('[6,5,4,4,4] groups as [6,5] / [4,4,4]', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('a'))),
                LayrzCol(xs: 5, child: SizedBox(height: 40, key: const Key('b'))),
                LayrzCol(xs: 4, child: SizedBox(height: 40, key: const Key('c'))),
                LayrzCol(xs: 4, child: SizedBox(height: 40, key: const Key('d'))),
                LayrzCol(xs: 4, child: SizedBox(height: 40, key: const Key('e'))),
              ],
            ),
          ),
        );

        final posA = tester.getTopLeft(find.byKey(const Key('a'))).dy;
        final posB = tester.getTopLeft(find.byKey(const Key('b'))).dy;
        final posC = tester.getTopLeft(find.byKey(const Key('c'))).dy;
        final posD = tester.getTopLeft(find.byKey(const Key('d'))).dy;
        final posE = tester.getTopLeft(find.byKey(const Key('e'))).dy;

        expect(posB, equals(posA), reason: 'b on same row as a (6+5=11)');
        expect(posC, greaterThan(posA), reason: 'c wraps to next row');
        expect(posD, equals(posC), reason: 'd on same row as c (4+4+4=12)');
        expect(posE, equals(posC), reason: 'e on same row as c');
      });
    });

    group('pixel widths', () {
      testWidgets('600px with spacing=0, xs=6 yields 300px per col', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col1'))),
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col2'))),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('col1')));
        final size2 = tester.getSize(find.byKey(const Key('col2')));

        // 600px * (6/12) = 300px each
        expect(size1.width, closeTo(300.0, 0.1));
        expect(size2.width, closeTo(300.0, 0.1));
      });

      testWidgets('600px with spacing=12 yields 294px per col', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 12,
              children: [
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col1'))),
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col2'))),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('col1')));
        final size2 = tester.getSize(find.byKey(const Key('col2')));

        // (600 - 12) * (6/12) = 294px each
        expect(size1.width, closeTo(294.0, 0.1));
        expect(size2.width, closeTo(294.0, 0.1));

        // Gap should be 12.0
        final pos1 = tester.getTopLeft(find.byKey(const Key('col1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('col2')));
        final gap = pos2.dx - (pos1.dx + size1.width);
        expect(gap, closeTo(12.0, 0.1), reason: 'gap between cols should be 12px');
      });
    });

    group('spacing', () {
      testWidgets('spacing=null uses tokens.spacing.base (8.0)', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            child: LayrzRow(
              spacing: null,
              children: [
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col1'))),
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col2'))),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('col1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('col1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('col2')));

        final gap = pos2.dx - (pos1.dx + size1.width);
        expect(gap, closeTo(8.0, 0.1), reason: 'gap should be default 8.0px');
      });

      testWidgets('spacing=0 gives flush adjacent columns', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 0,
              children: [
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col1'))),
                LayrzCol(xs: 6, child: SizedBox(height: 40, key: const Key('col2'))),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('col1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('col1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('col2')));

        final gap = pos2.dx - (pos1.dx + size1.width);
        expect(gap, closeTo(0.0, 0.1), reason: 'gap should be exactly 0px');
      });

      testWidgets('vertical gap between wrapped rows equals spacing', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              spacing: 16,
              children: [
                LayrzCol(xs: 12, child: SizedBox(height: 40, key: const Key('row1'))),
                LayrzCol(xs: 12, child: SizedBox(height: 40, key: const Key('row2'))),
              ],
            ),
          ),
        );

        final size1 = tester.getSize(find.byKey(const Key('row1')));
        final pos1 = tester.getTopLeft(find.byKey(const Key('row1')));
        final pos2 = tester.getTopLeft(find.byKey(const Key('row2')));

        final verticalGap = pos2.dy - (pos1.dy + size1.height);
        expect(verticalGap, closeTo(16.0, 0.1), reason: 'vertical gap should be 16px');
      });
    });

    group('mainAxisAlignment', () {
      testWidgets('MainAxisAlignment.start left-aligns single col at 0', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 200,
            child: LayrzRow(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 0,
              children: [
                LayrzCol(
                  xs: 3,
                  child: SizedBox(height: 40, key: const Key('col')),
                ),
              ],
            ),
          ),
        );

        // Get row left edge to measure relative to row origin
        final rowLeft = tester.getTopLeft(find.byType(LayrzRow)).dx;
        final colPos = tester.getTopLeft(find.byKey(const Key('col'))).dx;
        final colSize = tester.getSize(find.byKey(const Key('col')));

        final colLeft = colPos - rowLeft;

        // Column: 600 * 3/12 = 150.0 wide, left-aligned at 0.0
        expect(colLeft, closeTo(0.0, 0.01), reason: 'column should be flush left');
        expect(colSize.width, closeTo(150.0, 0.01));
      });

      testWidgets('MainAxisAlignment.center centers single col at 225', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 200,
            child: LayrzRow(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 0,
              children: [
                LayrzCol(xs: 3, child: SizedBox(height: 40, key: const Key('col'))),
              ],
            ),
          ),
        );

        // Get row left edge to measure relative to row origin
        final rowLeft = tester.getTopLeft(find.byType(LayrzRow)).dx;
        final colPos = tester.getTopLeft(find.byKey(const Key('col'))).dx;
        final colSize = tester.getSize(find.byKey(const Key('col')));

        final colLeft = colPos - rowLeft;

        // Column: 600 * 3/12 = 150.0 wide
        // Centred in 600px: (600 - 150) / 2 = 225.0
        expect(colLeft, closeTo(225.0, 0.01), reason: 'column should be centered at 225px');
        expect(colSize.width, closeTo(150.0, 0.01));
      });

      testWidgets('MainAxisAlignment.spaceBetween spreads three cols evenly', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 200,
            child: LayrzRow(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 0,
              children: [
                LayrzCol(xs: 2, child: SizedBox(height: 40, key: const Key('col1'))),
                LayrzCol(xs: 2, child: SizedBox(height: 40, key: const Key('col2'))),
                LayrzCol(xs: 2, child: SizedBox(height: 40, key: const Key('col3'))),
              ],
            ),
          ),
        );

        // Get row left edge to measure relative to row origin
        final rowLeft = tester.getTopLeft(find.byType(LayrzRow)).dx;
        final pos1 = tester.getTopLeft(find.byKey(const Key('col1'))).dx;
        final pos2 = tester.getTopLeft(find.byKey(const Key('col2'))).dx;
        final pos3 = tester.getTopLeft(find.byKey(const Key('col3'))).dx;
        final size1 = tester.getSize(find.byKey(const Key('col1'))).width;

        final col1Left = pos1 - rowLeft;
        final col2Left = pos2 - rowLeft;
        final col3Left = pos3 - rowLeft;

        // Each column: 600 * 2/12 = 100.0 wide
        // Total columns: 300.0; remaining: 300.0 for two gaps of 150.0 each
        // Col1: 0.0, Col2: 100 + 150 = 250.0, Col3: 250 + 100 + 150 = 500.0
        expect(col1Left, closeTo(0.0, 0.01), reason: 'col1 left at 0.0');
        expect(col2Left, closeTo(250.0, 0.01), reason: 'col2 left at 250.0');
        expect(col3Left, closeTo(500.0, 0.01), reason: 'col3 left at 500.0');
        expect(size1, closeTo(100.0, 0.01), reason: 'each column 100.0 wide');
      });
    });

    group('band and pixel separation', () {
      testWidgets('narrow container on wide screen: viewport selects band, container divides pixels', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(size: Size(1920, 1080)),
            child: SizedBox(
              width: 400,
              child: LayrzRow(
                spacing: 0,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: SizedBox(height: 40, key: const Key('col')),
                  ),
                ],
              ),
            ),
          ),
        );

        // Viewport 1920px selects xl band, cascades xl → lg → md → 6
        // Container width 400px divides by span: 400 * 6 / 12 = 200.0px
        final colSize = tester.getSize(find.byKey(const Key('col')));
        expect(
          colSize.width,
          closeTo(200.0, 0.01),
          reason: '1920px viewport selects md span 6, dividing 400px = 200px',
        );
      });

      testWidgets('narrow container on narrow screen: viewport selects band, container divides pixels', (tester) async {
        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: SizedBox(
              width: 400,
              child: LayrzRow(
                spacing: 0,
                children: [
                  LayrzCol(
                    xs: 12,
                    md: 6,
                    child: SizedBox(height: 40, key: const Key('col')),
                  ),
                ],
              ),
            ),
          ),
        );

        // Viewport 400px selects xs band
        // Container width 400px divides by span: 400 * 12 / 12 = 400.0px
        final colSize = tester.getSize(find.byKey(const Key('col')));
        expect(
          colSize.width,
          closeTo(400.0, 0.01),
          reason: '400px viewport selects xs span 12, dividing 400px = 400px',
        );
      });
    });

    group('LayrzCol in tree', () {
      testWidgets('LayrzCol widget appears in widget tree', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              children: [
                LayrzCol(xs: 6, child: const SizedBox(height: 40)),
              ],
            ),
          ),
        );

        expect(find.byType(LayrzCol), findsOneWidget);
      });

      testWidgets('Key on LayrzCol is findable', (tester) async {
        const colKey = Key('my_col');
        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            child: LayrzRow(
              children: [
                LayrzCol(
                  key: colKey,
                  xs: 6,
                  child: const SizedBox(height: 40),
                ),
              ],
            ),
          ),
        );

        expect(find.byKey(colKey), findsOneWidget);
      });
    });
  });
}

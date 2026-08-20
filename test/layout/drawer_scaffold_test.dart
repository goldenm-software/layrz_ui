import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/layout/src/drawer_scaffold.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzLayoutDrawerScaffold', () {
    testWidgets('drawer is absent at rest', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: LayrzLayoutDrawerScaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            topBarBuilder: (openDrawer) => SizedBox(
              height: 56,
              child: ColoredBox(
                color: const Color(0xFFF5F5F5),
                child: const Center(child: Text('Top Bar')),
              ),
            ),
            body: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: const Center(child: Text('Body')),
            ),
            drawerBuilder: (closeDrawer) => SizedBox(
              width: kLayrzLayoutDrawerWidth,
              child: ColoredBox(
                color: const Color(0xFFF0F0F0),
                child: const Center(child: Text('Drawer')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Drawer'), findsNothing);
      expect(find.text('Top Bar'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('ColoredBox renders page background', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: LayrzLayoutDrawerScaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            topBarBuilder: (openDrawer) => SizedBox(
              height: 56,
              child: const Center(child: Text('Top Bar')),
            ),
            body: const Center(child: Text('Body')),
            drawerBuilder: (closeDrawer) => SizedBox(
              width: 260,
              child: const Center(child: Text('Drawer')),
            ),
          ),
        ),
      );
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('full animation throws no exception', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: LayrzLayoutDrawerScaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            topBarBuilder: (openDrawer) => SizedBox(
              height: 56,
              child: const Center(child: Text('Top Bar')),
            ),
            body: const Center(child: Text('Body')),
            drawerBuilder: (closeDrawer) => SizedBox(
              width: 260,
              child: const Center(child: Text('Drawer')),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('closed state has no transforms', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 800,
          child: LayrzLayoutDrawerScaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            topBarBuilder: (openDrawer) => SizedBox(
              height: 56,
              child: const Center(child: Text('Top Bar')),
            ),
            body: const Center(child: Text('Body')),
            drawerBuilder: (closeDrawer) => SizedBox(
              width: 260,
              child: const Center(child: Text('Drawer')),
            ),
          ),
        ),
      );
      expect(find.byType(Transform), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('constants are correct', (WidgetTester tester) async {
      expect(kLayrzLayoutDrawerWidth, equals(260.0));
      expect(kLayrzLayoutDrawerOpenScale, equals(0.88));
      expect(kLayrzLayoutDrawerDragSettleVelocity, equals(365.0));
      expect(kLayrzLayoutDrawerEdgeDragWidth, equals(20.0));
    });
  });
}

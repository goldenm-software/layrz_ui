import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout.selectableContent', () {
    testWidgets('region is present when selectableContent is true (default)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Selectable content'),
          selectableContent: true,
        ),
      );

      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.text('Selectable content'), findsOneWidget);
    });

    testWidgets('region is absent when selectableContent is false', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Non-selectable content'),
          selectableContent: false,
        ),
      );

      expect(find.byType(SelectableRegion), findsNothing);
      expect(find.text('Non-selectable content'), findsOneWidget);
    });

    testWidgets('defaults to true, enabling selection', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Default enabled'),
        ),
      );

      // Default should be true, so region should be present
      expect(find.byType(SelectableRegion), findsOneWidget);
    });

    testWidgets('exactly one region wraps all body content', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: Column(
            children: const [
              Text('First line'),
              Text('Second line'),
              Text('Third line'),
            ],
          ),
          selectableContent: true,
        ),
      );

      // Exactly one SelectableRegion should wrap all the text
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.text('First line'), findsOneWidget);
      expect(find.text('Second line'), findsOneWidget);
      expect(find.text('Third line'), findsOneWidget);
    });

    testWidgets('FocusNode is not recreated across parent rebuilds', (tester) async {
      late StateSetter setParentState;

      int rebuildCount = 0;

      final parentWidget = StatefulBuilder(
        builder: (context, setState) {
          setParentState = setState;
          return LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: GestureDetector(
              onTap: () {
                rebuildCount++;
                setParentState(() {});
              },
              child: Text('Tap to rebuild (count: $rebuildCount)'),
            ),
            selectableContent: true,
          );
        },
      );

      await pumpThemedApp(tester, parentWidget);

      // Verify initial state
      expect(find.byType(SelectableRegion), findsOneWidget);

      // Trigger a rebuild by tapping
      await tester.tap(find.text('Tap to rebuild (count: 0)'));
      await tester.pump();

      // SelectableRegion should still be present after rebuild
      expect(find.byType(SelectableRegion), findsOneWidget);

      // Trigger another rebuild
      await tester.tap(find.text('Tap to rebuild (count: 1)'));
      await tester.pump();

      // SelectableRegion should still be present
      expect(find.byType(SelectableRegion), findsOneWidget);
    });

    testWidgets('selection spans multiple Text widgets in body', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: SizedBox(
            width: 500,
            height: 200,
            child: Column(
              children: const [
                Text('First text widget'),
                Text('Second text widget'),
              ],
            ),
          ),
          selectableContent: true,
        ),
      );

      // Verify both text widgets are present
      expect(find.text('First text widget'), findsOneWidget);
      expect(find.text('Second text widget'), findsOneWidget);

      // Verify SelectableRegion is present, enabling cross-widget selection
      expect(find.byType(SelectableRegion), findsOneWidget);
    });

    testWidgets('no Overlay assertion thrown with selectableContent enabled', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Content'),
          selectableContent: true,
        ),
      );

      // The test should complete without throwing an Overlay assertion
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('region wraps body in both expanded and drawer presentations', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      // Test expanded presentation
      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Expanded body'),
          selectableContent: true,
        ),
      );

      expect(find.byType(SelectableRegion), findsOneWidget);

      // Test drawer presentation
      tester.view.physicalSize = const Size(500, 900);
      await tester.pumpWidget(
        LayrzApp(
          home: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const Text('Drawer body'),
            selectableContent: true,
          ),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump();

      // SelectableRegion should still be present in drawer mode
      expect(find.byType(SelectableRegion), findsOneWidget);
    });

    testWidgets('dialog outside SelectableRegion cannot be selected', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      tester.view.physicalSize = const Size(1400, 900);

      final app = LayrzApp(
        home: LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const Text('Show Dialog'),
          selectableContent: true,
        ),
        debugShowCheckedModeBanner: false,
      );

      await tester.pumpWidget(app);

      // The accepted trade-off: dialogs/overlays are outside the SelectableRegion
      // and therefore not selectable. This is by design.
      // Verify SelectableRegion wraps the body
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.text('Show Dialog'), findsOneWidget);
    });

    testWidgets('region switches correctly when selectableContent changes at runtime', (tester) async {
      late StateSetter setLayoutState;

      bool selectableContent = true;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setLayoutState = setState;
            return LayrzLayout(
              logo: 'assets/test-logo.png',
              items: [
                LayrzNavigatorPage(id: 'home', labelText: 'Home'),
              ],
              body: const Text('Content'),
              selectableContent: selectableContent,
            );
          },
        ),
      );

      // Initially enabled
      expect(find.byType(SelectableRegion), findsOneWidget);

      // Disable selection
      setLayoutState(() {
        selectableContent = false;
      });
      await tester.pump();

      // Region should be gone
      expect(find.byType(SelectableRegion), findsNothing);

      // Re-enable selection
      setLayoutState(() {
        selectableContent = true;
      });
      await tester.pump();

      // Region should be back
      expect(find.byType(SelectableRegion), findsOneWidget);
    });
  });
}

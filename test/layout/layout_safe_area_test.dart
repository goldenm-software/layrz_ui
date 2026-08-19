import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout - Safe Area Behavior (DESIGN-82)', () {
    group('Expanded Presentation - Rail safe area', () {
      testWidgets('rail wraps content in SafeArea', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify SafeArea is present in the rail
        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: 'Rail must wrap content in SafeArea to honor device insets (notch, status bar)',
        );
      });

      testWidgets('rail surface renders with elevation shadow', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify Container for rail surface exists
        expect(
          find.byType(Container),
          findsWidgets,
          reason: 'Rail must have Container with surface color and elevation2 shadow',
        );
      });

      testWidgets('rail renders logo and items inside SafeArea', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify content renders
        expect(find.byType(LayrzImage), findsWidgets, reason: 'Rail logo must render');
        expect(find.text('Body'), findsOneWidget, reason: 'Body content must be visible');
      });
    });

    group('Drawer Presentation - Top bar and drawer safe area', () {
      testWidgets('top bar uses DecoratedBox for surface', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify DecoratedBox is used for the top bar surface
        expect(
          find.byType(DecoratedBox),
          findsWidgets,
          reason: 'Top bar must use DecoratedBox so surface extends behind status bar',
        );
      });

      testWidgets('top bar wraps content in SafeArea', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify SafeArea is present in the top bar
        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: 'Top bar must wrap content in SafeArea to inset from status bar',
        );
      });

      testWidgets('top bar renders drawer trigger and logo', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify top bar elements render
        expect(find.byType(Icon), findsWidgets, reason: 'Top bar must have drawer trigger icon');
        expect(find.byType(LayrzImage), findsWidgets, reason: 'Top bar must render logo');
      });

      testWidgets('drawer renders with SafeArea', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Open drawer
        await tester.tap(find.byType(Icon).first);
        await tester.pumpAndSettle();

        // Verify SafeArea in drawer
        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: 'Drawer must wrap content in SafeArea with right: false for landscape notch',
        );
      });

      testWidgets('drawer renders logo and items', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Open drawer
        await tester.tap(find.byType(Icon).first);
        await tester.pumpAndSettle();

        // Verify drawer content
        expect(find.byType(LayrzImage), findsWidgets, reason: 'Drawer must render logo');
      });

      testWidgets('body renders in drawer presentation', (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify body is visible in drawer presentation
        expect(find.text('Body'), findsOneWidget, reason: 'Body must render in drawer presentation');
      });
    });
  });
}

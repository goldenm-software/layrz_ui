import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layout/src/user_chrome.dart';

import '../helpers/fake_selection_registrar.dart';
import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayoutRailItem selection boundary', () {
    testWidgets(
      'the nav label and count badge see a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        // pumpThemedApp already wraps `home` in a Center; wrap it further in
        // an enabled SelectionContainer standing in for a consumer SelectionArea.
        await tester.pumpWidget(
          LayrzApp(
            home: SelectionContainer(
              registrar: FakeSelectionRegistrar(),
              delegate: TestSelectionContainerDelegate(),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: 'home', labelText: 'Home', count: 3),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
            showDebugWatermark: false,
          ),
        );
        await tester.pump();

        final richTextFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Home'),
        );
        expect(richTextFinder, findsOneWidget);
        final labelContext = tester.element(richTextFinder);

        final badgeContext = tester.element(find.text('3'));

        expect(SelectionContainer.maybeOf(labelContext), isNull);
        expect(SelectionContainer.maybeOf(badgeContext), isNull);
      },
    );

    testWidgets(
      'structural: the nav label RichText has a SelectionContainer ancestor',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Structural'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final richTextFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Structural'),
        );

        expect(
          find.ancestor(of: richTextFinder, matching: find.byType(SelectionContainer)),
          findsWidgets,
        );
      },
    );
  });

  group('LayrzLayoutNavigatorPanel selection boundary', () {
    testWidgets(
      'the "No results" caption sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await tester.pumpWidget(
          LayrzApp(
            home: SelectionContainer(
              registrar: FakeSelectionRegistrar(),
              delegate: TestSelectionContainerDelegate(),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
                  LayrzNavigatorPage(id: '2', labelText: 'Devices'),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
            showDebugWatermark: false,
          ),
        );
        await tester.pump();

        final searchField = find.byType(EditableText);
        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'xyz');
        await tester.pumpAndSettle();

        final noResultsContext = tester.element(find.text('No results').first);

        expect(SelectionContainer.maybeOf(noResultsContext), isNull);
      },
    );

    testWidgets(
      'the section caption sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await tester.pumpWidget(
          LayrzApp(
            home: SelectionContainer(
              registrar: FakeSelectionRegistrar(),
              delegate: TestSelectionContainerDelegate(),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: [
                  LayrzNavigatorLabel('MAIN'),
                  LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
                ],
                body: const SizedBox(child: Text('Body')),
              ),
            ),
            showDebugWatermark: false,
          ),
        );
        await tester.pump();

        final captionContext = tester.element(find.text('MAIN'));

        expect(SelectionContainer.maybeOf(captionContext), isNull);
      },
    );

    testWidgets(
      'the "Notifications" label and count see a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await tester.pumpWidget(
          LayrzApp(
            home: SelectionContainer(
              registrar: FakeSelectionRegistrar(),
              delegate: TestSelectionContainerDelegate(),
              child: LayrzLayout(
                logo: 'assets/test-logo.png',
                items: const [],
                notifications: const [
                  LayrzNotificationItem(id: 'n1', title: 'New message', content: 'Hello'),
                ],
                onNotificationTap: (_) {},
                body: const SizedBox(child: Text('Body')),
              ),
            ),
            showDebugWatermark: false,
          ),
        );
        await tester.pump();

        final labelContext = tester.element(find.text('Notifications'));
        final countContext = tester.element(find.text('1'));

        expect(SelectionContainer.maybeOf(labelContext), isNull);
        expect(SelectionContainer.maybeOf(countContext), isNull);
      },
    );
  });

  group('LayrzLayoutUserChrome selection boundary', () {
    testWidgets(
      'the user name sees a disabled selection registrar, not the ancestor\'s own',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final themeData = LayrzThemeData.light();

        await pumpThemed(
          tester,
          theme: themeData,
          SelectionContainer(
            registrar: FakeSelectionRegistrar(),
            delegate: TestSelectionContainerDelegate(),
            child: LayrzLayoutUserChrome(
              tokens: themeData.tokens,
              userName: 'Jane Doe',
              userAvatar: null,
              userMenuItems: const [],
              getInitials: (name) => name?.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join() ?? '',
            ),
          ),
        );

        final nameContext = tester.element(find.text('Jane Doe'));

        expect(SelectionContainer.maybeOf(nameContext), isNull);
      },
    );

    testWidgets(
      'structural: the user name has a SelectionContainer ancestor',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final themeData = LayrzThemeData.light();

        await pumpThemed(
          tester,
          theme: themeData,
          LayrzLayoutUserChrome(
            tokens: themeData.tokens,
            userName: 'Structural User',
            userAvatar: null,
            userMenuItems: const [],
            getInitials: (name) => name?.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join() ?? '',
          ),
        );

        expect(
          find.ancestor(of: find.text('Structural User'), matching: find.byType(SelectionContainer)),
          findsOneWidget,
        );
      },
    );
  });
}

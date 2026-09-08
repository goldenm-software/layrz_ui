import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// Builds a fixed list of [LayrzTab]s with distinct labels and content, for
/// reuse across tests.
List<LayrzTab> _buildTabs() {
  return [
    LayrzTab(labelText: 'First', child: const Text('First content')),
    LayrzTab(labelText: 'Second', child: const Text('Second content')),
    LayrzTab(labelText: 'Third', child: const Text('Third content')),
  ];
}

void main() {
  group('LayrzTabView — assertions', () {
    test('throws when tabs is empty', () {
      expect(
        () => LayrzTabView(tabs: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('LayrzTabView — rendering', () {
    guardedTestWidgets('renders every tab label and only the active tab child (wide viewport)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);

      expect(find.text('First content'), findsOneWidget);
      expect(find.text('Second content'), findsNothing);
      expect(find.text('Third content'), findsNothing);
    });

    guardedTestWidgets('narrow (compact) viewport still renders every tab label', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    guardedTestWidgets('renders a leading widget slot', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(
              labelText: 'First',
              leading: const SizedBox(key: Key('leading-slot'), width: 10, height: 10),
              child: const Text('First content'),
            ),
            LayrzTab(labelText: 'Second', child: const Text('Second content')),
          ],
        ),
      );

      expect(find.byKey(const Key('leading-slot')), findsOneWidget);
    });

    guardedTestWidgets('renders a leadingIcon slot as an Icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final icon = IconData(0xe900);
      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(labelText: 'First', leadingIcon: icon, child: const Text('First content')),
            LayrzTab(labelText: 'Second', child: const Text('Second content')),
          ],
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, icon);
    });

    guardedTestWidgets('renders a trailing widget slot', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(
              labelText: 'First',
              trailing: const SizedBox(key: Key('trailing-slot'), width: 10, height: 10),
              child: const Text('First content'),
            ),
            LayrzTab(labelText: 'Second', child: const Text('Second content')),
          ],
        ),
      );

      expect(find.byKey(const Key('trailing-slot')), findsOneWidget);
    });

    guardedTestWidgets('renders a trailingIcon slot as an Icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final icon = IconData(0xe901);
      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(labelText: 'First', trailingIcon: icon, child: const Text('First content')),
            LayrzTab(labelText: 'Second', child: const Text('Second content')),
          ],
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, icon);
    });

    guardedTestWidgets('renders a custom label widget instead of labelText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(label: const Text('Custom label'), child: const Text('First content')),
            LayrzTab(labelText: 'Second', child: const Text('Second content')),
          ],
        ),
      );

      expect(find.text('Custom label'), findsOneWidget);
    });
  });

  group('LayrzTabView — selection interaction', () {
    guardedTestWidgets('tapping a non-selected tab switches the visible child', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      expect(find.text('First content'), findsOneWidget);
      expect(find.text('Second content'), findsNothing);

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(find.text('First content'), findsNothing);
      expect(find.text('Second content'), findsOneWidget);
    });

    guardedTestWidgets('onTabChanged fires on user tap with the new index', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? changedIndex;
      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: _buildTabs(),
          onTabChanged: (index) => changedIndex = index,
        ),
      );

      await tester.tap(find.text('Third'));
      await tester.pump();

      expect(changedIndex, 2);
    });

    guardedTestWidgets('onTabChanged does not fire on mount', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;
      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: _buildTabs(),
          onTabChanged: (_) => callCount++,
        ),
      );

      expect(callCount, 0);
    });

    guardedTestWidgets('onTabChanged does not fire when tapping the already-selected tab', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var callCount = 0;
      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: _buildTabs(),
          onTabChanged: (_) => callCount++,
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();

      expect(callCount, 0);
    });
  });

  group('LayrzTabView — initialIndex clamping', () {
    guardedTestWidgets('an initialIndex beyond the end is clamped to the last tab, without throwing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), initialIndex: 99));

      expect(tester.takeException(), isNull);
      expect(find.text('Third content'), findsOneWidget);
    });

    guardedTestWidgets('a negative initialIndex is clamped to the first tab, without throwing', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), initialIndex: -5));

      expect(tester.takeException(), isNull);
      expect(find.text('First content'), findsOneWidget);
    });

    guardedTestWidgets('a valid initialIndex selects that tab from the start', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), initialIndex: 1));

      expect(find.text('Second content'), findsOneWidget);
      expect(find.text('First content'), findsNothing);
    });
  });

  group('LayrzTabView — contentGap', () {
    guardedTestWidgets('defaults to tokens.spacing.sp3 between strip and content', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final gapBox = sizedBoxes.firstWhere((box) => box.height == tokens.spacing.sp3);

      expect(gapBox.height, tokens.spacing.sp3);
    });

    guardedTestWidgets('a value of 0 butts the content directly against the strip', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), contentGap: 0));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final gapBox = sizedBoxes.firstWhere((box) => box.height == 0);

      expect(gapBox.height, 0);
    });

    guardedTestWidgets('a custom value overrides the token default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), contentGap: 40));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final gapBox = sizedBoxes.firstWhere((box) => box.height == 40);

      expect(gapBox.height, 40);
    });
  });

  group('LayrzTabView — isScrollable modes', () {
    guardedTestWidgets('isScrollable: true (default) wraps the strip in a SingleChildScrollView', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Expanded), findsNothing);
    });

    guardedTestWidgets('isScrollable: true renders correctly when tabs overflow a narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(labelText: 'A very long first tab label', child: const Text('First content')),
            LayrzTab(labelText: 'A very long second tab label', child: const Text('Second content')),
            LayrzTab(labelText: 'A very long third tab label', child: const Text('Third content')),
          ],
        ),
      );

      // No overflow exception (guardedTestWidgets asserts this at teardown);
      // the scroll view exists to absorb the overflowing content width.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    guardedTestWidgets('isScrollable: false stretches cells to equal width via Expanded, no scroll view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs(), isScrollable: false));

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Expanded), findsNWidgets(3));
    });

    guardedTestWidgets('isScrollable: false gives every pill the same width', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTabView(
          tabs: [
            LayrzTab(labelText: 'A', child: const Text('First content')),
            LayrzTab(labelText: 'A much longer label', child: const Text('Second content')),
          ],
          isScrollable: false,
        ),
      );

      final firstWidth = tester.getSize(find.byType(Expanded).at(0)).width;
      final secondWidth = tester.getSize(find.byType(Expanded).at(1)).width;

      expect(firstWidth, secondWidth);
    });
  });

  group('LayrzTabView — D15 geometry compliance', () {
    guardedTestWidgets('switching the selected tab does not change the strip pill sizes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      final sizeBefore = tester.getSize(find.byType(LayrzTappable).first);

      await tester.tap(find.text('Second'));
      await tester.pump();

      final sizeAfter = tester.getSize(find.byType(LayrzTappable).first);

      expect(sizeAfter, sizeBefore);
    });

    guardedTestWidgets('the selected pill paints the theme primary color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      final tappable = tester.widget<LayrzTappable>(
        find.ancestor(of: find.text('First'), matching: find.byType(LayrzTappable)).first,
      );

      expect(tappable.color, tokens.colors.primary.shade500);
    });

    guardedTestWidgets('an unselected pill paints the background surface token, never transparent', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

      final tappable = tester.widget<LayrzTappable>(
        find.ancestor(of: find.text('Second'), matching: find.byType(LayrzTappable)).first,
      );

      expect(tappable.color, tokens.colors.sf1);
      expect(tappable.color!.a, 1.0, reason: 'an unselected pill must paint a solid color, never transparent');
    });
  });

  group('LayrzTabView — Accessibility', () {
    guardedTestWidgets('the selected tab exposes button semantics marked selected', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

        expect(
          tester.getSemantics(find.text('First')),
          matchesSemantics(label: 'First', isButton: true, hasSelectedState: true, isSelected: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a non-selected tab exposes button semantics marked not selected, with a tap action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

        expect(
          tester.getSemantics(find.text('Second')),
          matchesSemantics(
            label: 'Second',
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the selected flag flips between tabs after a tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

        expect(
          tester.getSemantics(find.text('First')),
          matchesSemantics(
            label: 'First',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: false,
          ),
        );
        expect(
          tester.getSemantics(find.text('Second')),
          matchesSemantics(
            label: 'Second',
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );

        await tester.tap(find.text('Second'));
        await tester.pump();

        expect(
          tester.getSemantics(find.text('First')),
          matchesSemantics(
            label: 'First',
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.text('Second')),
          matchesSemantics(
            label: 'Second',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the selected tab exposes no tap action (nothing to activate)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, LayrzTabView(tabs: _buildTabs()));

        expect(
          tester.getSemantics(find.text('First')),
          matchesSemantics(
            label: 'First',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}

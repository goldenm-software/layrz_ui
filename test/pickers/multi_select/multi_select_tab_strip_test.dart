import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_surface.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_tab_strip.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Pumps [surface] inside a fixed-height [SizedBox], mirroring
/// `multi_select_surface_test.dart`'s own `_pumpBoundedSurface` helper --
/// the surface's `Expanded(child: listOrEmptyState)` requires a bounded
/// ancestor.
Future<void> _pumpBoundedSurface(WidgetTester tester, Widget surface) {
  return pumpThemed(tester, SizedBox(height: 600, width: 700, child: surface));
}

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  group('LayrzMultiSelectTabStrip — standalone rendering', () {
    guardedTestWidgets('renders both segments with their own counts', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectTabStrip(
          activeTab: LayrzMultiSelectTab.all,
          allCount: 3,
          selectedCount: 1,
          onTabChanged: (_) {},
        ),
      );

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
    });

    guardedTestWidgets('tapping the inactive segment reports the tapped tab', (tester) async {
      LayrzMultiSelectTab? tapped;

      await pumpThemed(
        tester,
        LayrzMultiSelectTabStrip(
          activeTab: LayrzMultiSelectTab.all,
          allCount: 3,
          selectedCount: 1,
          onTabChanged: (tab) => tapped = tab,
        ),
      );

      await tester.tap(find.text('Selected (1)'));
      await tester.pumpAndSettle();

      expect(tapped, LayrzMultiSelectTab.selected);
    });

    guardedTestWidgets('accessibility -- each segment exposes button + selected semantics', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzMultiSelectTabStrip(
            activeTab: LayrzMultiSelectTab.all,
            allCount: 3,
            selectedCount: 1,
            onTabChanged: (_) {},
          ),
        );

        expect(
          find.bySemanticsLabel('All (3)'),
          findsOneWidget,
        );

        final allSemantics = tester.getSemantics(find.text('All (3)'));
        expect(
          allSemantics,
          matchesSemantics(
            label: 'All (3)',
            isButton: true,
            hasTapAction: true,
            isSelected: true,
            hasSelectedState: true,
          ),
        );

        final selectedSemantics = tester.getSemantics(find.text('Selected (1)'));
        expect(
          selectedSemantics,
          matchesSemantics(
            label: 'Selected (1)',
            isButton: true,
            hasTapAction: true,
            isSelected: false,
            hasSelectedState: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzMultiSelectInputSurface — All/Selected tabs (DESIGN-43)', () {
    guardedTestWidgets('defaults to the All tab, showing every item with the full count', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('switching to Selected shows only drafted items, All shows every item again', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('the Selected count updates live as rows are toggled', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Selected (0)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (1)'), findsOneWidget);

      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (2)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (1)'), findsOneWidget);
    });

    guardedTestWidgets('toggling a row while on the Selected tab removes it from view immediately', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsOneWidget);
    });

    guardedTestWidgets('search narrows both the All count and the visible rows within the active tab', (
      tester,
    ) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      // "an" matches Banana only.
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('search still filters within the Selected tab', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    guardedTestWidgets('the empty state renders on the Selected tab when the draft is empty', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No item found'), findsOneWidget);
    });

    guardedTestWidgets('keyboard navigation on the Selected tab only cycles through drafted rows', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['cherry'],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.tap(find.text('Selected (1)'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Only "cherry" is visible on the Selected tab -- arrow-down highlights
      // it, and space toggles it OFF (it was already in the draft).
      surfaceKey.currentState!.save();
      expect(committed, isEmpty);
    });

    guardedTestWidgets('save() still commits from the full items set regardless of the active tab', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['apple', 'banana']);
    });
  });
}

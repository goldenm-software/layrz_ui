import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/select/select_item.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  group('LayrzMultiSelectInputSurface — rendering', () {
    guardedTestWidgets('renders every item', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('seeds the draft from initialValues -- those rows render selected', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      expect(surfaceKey.currentState!.hasSelection, isTrue);
    });

    guardedTestWidgets('with no search field, all items still render (enableSearch: false)', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
    });

    guardedTestWidgets('empty items list shows the empty-state text', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: const [],
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('No item found'), findsOneWidget);
    });
  });

  group('LayrzMultiSelectInputSurfaceState — draft mutation surface', () {
    guardedTestWidgets('canSave is always true, even with an empty draft', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      expect(surfaceKey.currentState!.canSave, isTrue);
      expect(surfaceKey.currentState!.hasSelection, isFalse);
    });

    guardedTestWidgets('tapping a row toggles it on, then off, without calling onDraftCommitted', (tester) async {
      var draftChanges = 0;
      var committed = false;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftChanged: () => draftChanges++,
          onDraftCommitted: (_) => committed = true,
        ),
      );

      final beforeTap = draftChanges;

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(draftChanges, greaterThan(beforeTap));
      expect(committed, isFalse);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(committed, isFalse, reason: 'a second tap toggling the row back off must also not commit');
    });

    guardedTestWidgets('selectAll mutates the draft to every item, in order, without committing', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      surfaceKey.currentState!.selectAll();
      await tester.pumpAndSettle();

      expect(committed, isNull);
      expect(surfaceKey.currentState!.hasSelection, isTrue);

      surfaceKey.currentState!.save();
      expect(committed, ['apple', 'banana', 'cherry']);
    });

    guardedTestWidgets('unselectAll clears the draft without committing', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['apple', 'cherry'],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      surfaceKey.currentState!.unselectAll();
      await tester.pumpAndSettle();

      expect(committed, isNull);
      expect(surfaceKey.currentState!.hasSelection, isFalse);

      surfaceKey.currentState!.save();
      expect(committed, isEmpty);
    });

    guardedTestWidgets('save() reports the draft in items order, regardless of tap order', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      // Tap cherry, then apple -- reverse of items order.
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();

      expect(committed, ['apple', 'cherry'], reason: 'save() must report items in the surface\'s own item order');
    });
  });

  group('LayrzMultiSelectInputSurface — search', () {
    guardedTestWidgets('typing narrows the visible items', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('clearing the query restores the full list', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('a custom filter replaces the default matcher', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          filter: (query, item) => item.searchableStrings.any((s) => s.toLowerCase().contains('a')),
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('a selected row toggled while search-filtered still updates the draft', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 40,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['banana']);
    });
  });

  group('LayrzMultiSelectInputSurface — keyboard navigation', () {
    guardedTestWidgets('arrow down highlights, space toggles the highlighted row', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 40,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['apple']);
    });

    guardedTestWidgets('arrow down wraps to the first item at the end of the list', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      for (var i = 0; i < items.length + 1; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('arrow up wraps to the last item at the beginning of the list', (tester) async {
      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 40,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('enter with no highlight does nothing', (tester) async {
      var committed = false;

      await pumpThemed(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 40,
          onDraftCommitted: (_) => committed = true,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(committed, isFalse);
    });
  });
}

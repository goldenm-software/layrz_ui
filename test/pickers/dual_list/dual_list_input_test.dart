import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Finds the (icon-only, Fab-style) [LayrzButton] whose [LayrzButton.labelText]
/// equals [label] -- the move-all affordances render no visible text
/// ([find.text] cannot see them), only a [Semantics] label carrying it.
Finder _findButtonByLabel(String label) =>
    find.byWidgetPredicate((widget) => widget is LayrzButton && widget.labelText == label);

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  /// Sets a wide (desktop, `isCompact == false`) viewport.
  void setDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Sets a narrow (compact, `isCompact == true`) viewport.
  void setCompactViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('LayrzDualListInput — desktop two-panel surface', () {
    guardedTestWidgets('renders both panels with their own item partitions', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const ['banana'],
          itemExtent: 48,
        ),
      );

      expect(find.text('Available (2)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    guardedTestWidgets('tapping an Available row moves it to Selected and fires onChanged', (tester) async {
      setDesktopViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      expect(find.text('Available (3)'), findsOneWidget);
      expect(find.text('Selected (0)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(committed, ['apple']);
      expect(find.text('Available (2)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
    });

    guardedTestWidgets('tapping a Selected row moves it back to Available and fires onChanged', (tester) async {
      setDesktopViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const ['apple', 'banana'],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      expect(find.text('Available (1)'), findsOneWidget);
      expect(find.text('Selected (2)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(committed, ['banana']);
      expect(find.text('Available (2)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
    });

    guardedTestWidgets('onChanged reports values in items order regardless of transfer order', (tester) async {
      setDesktopViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(committed, ['apple', 'cherry'], reason: 'must follow items order, not tap order');
    });

    guardedTestWidgets('move-all-to-selected transfers every visible Available item at once', (tester) async {
      setDesktopViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(_findButtonByLabel('Toggle all to selected'));
      await tester.pumpAndSettle();

      expect(committed, ['apple', 'banana', 'cherry']);
      expect(find.text('Available (0)'), findsOneWidget);
      expect(find.text('Selected (3)'), findsOneWidget);
    });

    guardedTestWidgets('move-all-to-available transfers every visible Selected item at once', (tester) async {
      setDesktopViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const ['apple', 'banana', 'cherry'],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(_findButtonByLabel('Toggle all to available'));
      await tester.pumpAndSettle();

      expect(committed, isEmpty);
      expect(find.text('Available (3)'), findsOneWidget);
      expect(find.text('Selected (0)'), findsOneWidget);
    });

    guardedTestWidgets('search narrows only the Available panel, leaving Selected unaffected', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const ['banana'],
          itemExtent: 48,
        ),
      );

      // Both panels have search fields (their own EditableText each) -- the
      // first one belongs to Available.
      final searchFields = find.byType(EditableText);
      expect(searchFields, findsNWidgets(2));

      await tester.enterText(searchFields.first, 'cherry');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      // Selected panel (Banana) is untouched by Available's own search.
      expect(find.text('Banana'), findsOneWidget);
    });

    guardedTestWidgets('a disabled field does not respond to row taps', (tester) async {
      setDesktopViewport(tester);
      var committed = false;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          disabled: true,
          onChanged: (_) => committed = true,
        ),
      );

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(committed, isFalse);
    });

    guardedTestWidgets('errors render below the two-panel surface', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          errors: const ['This field is required'],
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });

    guardedTestWidgets('hideDetails suppresses the error block', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          errors: const ['This field is required'],
          hideDetails: true,
        ),
      );

      expect(find.text('This field is required'), findsNothing);
    });

    guardedTestWidgets('a caller-supplied value change reconciles the panels', (tester) async {
      setDesktopViewport(tester);
      final valueNotifier = ValueNotifier<List<String>>(const []);

      await pumpThemed(
        tester,
        ValueListenableBuilder<List<String>>(
          valueListenable: valueNotifier,
          builder: (context, value, _) {
            return LayrzDualListInput<String>(
              labelText: 'Fruits',
              items: items,
              value: value,
              itemExtent: 48,
            );
          },
        ),
      );

      expect(find.text('Selected (0)'), findsOneWidget);

      // Externally-driven value change (never through this widget's own
      // onChanged) -- proves didUpdateWidget's reconciliation.
      valueNotifier.value = ['apple'];
      await tester.pumpAndSettle();

      expect(find.text('Selected (1)'), findsOneWidget);
      valueNotifier.dispose();
    });

    guardedTestWidgets('empty items list shows the empty-state text in both panels', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: const <LayrzSelectItem<String>>[],
          value: const [],
          itemExtent: 48,
        ),
      );

      expect(find.text('No item found'), findsNWidgets(2));
    });

    guardedTestWidgets('a custom emptyListText overrides the localized default', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: const <LayrzSelectItem<String>>[],
          value: const [],
          itemExtent: 48,
          emptyListText: 'Nothing here',
        ),
      );

      expect(find.text('Nothing here'), findsNWidgets(2));
    });

    guardedTestWidgets('custom availableListName/selectedListName override the localized defaults', (tester) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          availableListName: 'Left',
          selectedListName: 'Right',
        ),
      );

      expect(find.text('Left (3)'), findsOneWidget);
      expect(find.text('Right (0)'), findsOneWidget);
    });

    guardedTestWidgets('enableAvailableSearch/enableSelectedSearch false removes each panel\'s search field', (
      tester,
    ) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          enableAvailableSearch: false,
          enableSelectedSearch: false,
        ),
      );

      expect(find.byType(EditableText), findsNothing);
    });
  });

  group('LayrzDualListInput — compact delegation (DESIGN-43)', () {
    guardedTestWidgets('at a WIDE viewport the two-panel desktop surface is shown, MultiSelect is absent', (
      tester,
    ) async {
      setDesktopViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
        ),
      );

      expect(find.text('Available (3)'), findsOneWidget);
      expect(find.byType(LayrzMultiSelectInput<String>), findsNothing);
    });

    guardedTestWidgets('at a NARROW viewport MultiSelect is shown, the two-panel desktop surface is absent', (
      tester,
    ) async {
      setCompactViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
        ),
      );

      expect(find.byType(LayrzMultiSelectInput<String>), findsOneWidget);
      expect(find.text('Available (3)'), findsNothing);
      expect(find.text('Selected (0)'), findsNothing);
    });

    guardedTestWidgets('the compact delegate forwards items/value/labelText/itemExtent', (tester) async {
      setCompactViewport(tester);

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const ['cherry'],
          itemExtent: 48,
        ),
      );

      final multiSelect = tester.widget<LayrzMultiSelectInput<String>>(find.byType(LayrzMultiSelectInput<String>));
      expect(multiSelect.items, items);
      expect(multiSelect.value, ['cherry']);
      expect(multiSelect.labelText, 'Fruits');
      expect(multiSelect.itemExtent, 48);
    });

    guardedTestWidgets('committing through the compact MultiSelect delegate fires onChanged', (tester) async {
      setCompactViewport(tester);
      List<String>? committed;

      await pumpThemed(
        tester,
        LayrzDualListInput<String>(
          labelText: 'Fruits',
          items: items,
          value: const [],
          itemExtent: 48,
          onChanged: (values) => committed = values,
        ),
      );

      final multiSelect = tester.widget<LayrzMultiSelectInput<String>>(find.byType(LayrzMultiSelectInput<String>));
      multiSelect.onChanged?.call(['apple']);

      expect(committed, ['apple']);
    });
  });
}

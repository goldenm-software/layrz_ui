import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/select/select_input_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput Accessibility - Semantics', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
      const LayrzSelectItem(value: 'c', child: Text('Option C'), searchableStrings: {'Option C'}),
    ];

    group('Anchor semantics', () {
      testWidgets('anchor exposes label and button state', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose an option',
            ),
          );

          // Scoped to `LayrzInputChrome`, not `LayrzSelectInput` itself
          // (DESIGN-145): `WidgetTester.getSemantics` walks from
          // `element.findRenderObject()`, and now that the field's `EditableText`
          // is always read-only, that walk can land in `EditableText`'s own
          // offstage text-selection-toolbar overlay branch (a `RenderObject`
          // descendant of `LayrzSelectInput` in element-tree terms, even though it
          // paints nowhere) before it reaches the field's own labeled node -- an
          // empty-label `RenderSemanticsAnnotations` there, not a missing label,
          // is what a bare `find.byType(LayrzSelectInput<String>)` was hitting.
          // `LayrzInputChrome` has no such duplicate in that offstage branch, so
          // walking up from it is unambiguous. The real, compiled semantics tree
          // (what assistive tech actually sees) has always carried this label
          // correctly; this is a test-scoping fix, not a behavior fix.
          final semantics = tester.getSemantics(find.byType(LayrzInputChrome));
          expect(semantics.label, contains('Choose an option'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor is enabled when not disabled', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              disabled: false,
            ),
          );

          final field = find.byType(LayrzInputChrome);
          expect(field, findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor is disabled when disabled flag is set', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Disabled Field',
              disabled: true,
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.text('Option A'), findsNothing);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor with required flag', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Required field',
              isRequired: true,
            ),
          );

          final chromeWidget = find.byType(LayrzInputChrome);
          final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
          expect(chrome.isRequired, isTrue);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor with hint and label', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Select',
              hintText: 'Choose from list',
            ),
          );

          // `labelText` is asserted on the SEMANTICS TREE, not on
          // `LayrzInputChrome`'s own constructor parameter: DESIGN-145
          // deliberately hoists the label out of the chrome (it is rendered by
          // the `Semantics(label: widget.labelText, ...)` node that wraps the
          // chrome's `Container` in `select_input.dart`, around line 477) so the
          // anchor's measured rect used for positioning the opened panel never
          // includes the label -- a label rendered *inside* the chrome would
          // extend that rect upward and misplace the panel by the label's own
          // height (measured before the fix: 24.0 logical pixels). The chrome
          // itself always receives `labelText: null` by design; asserting
          // `chrome.labelText` checks a parameter this component intentionally
          // never sets, not whether the label is actually exposed. See the
          // "anchor exposes label and button state" test above, which pins the
          // same scoping for the same reason.
          final semantics = tester.getSemantics(find.byType(LayrzInputChrome));
          expect(semantics.label, contains('Select'));

          // `hintText`, unlike `labelText`, IS passed straight into the chrome
          // and rendered there with no hoisting (select_input.dart:526) -- it
          // never sits inside the anchor's measured rect the way the label
          // would, since it paints only when no item is selected and never
          // changes the field's geometry. So this stays a direct parameter
          // assertion; it is checking the actual rendering path.
          final chromeWidget = find.byType(LayrzInputChrome);
          final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
          expect(chrome.hintText, equals('Choose from list'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor with error messages', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              errors: const ['Field is required'],
            ),
          );

          expect(find.text('Field is required'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor with help affordance', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              helpTitleText: 'Help',
              helpContentText: 'Select an option',
            ),
          );

          final chromeWidget = find.byType(LayrzInputChrome);
          final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
          expect(chrome.helpTitleText, equals('Help'));
          expect(chrome.helpContentText, equals('Select an option'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('anchor shows dropdown chevron', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
            ),
          );

          expect(find.byIcon(MdiIcons.chevronDown), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Surface items semantics', () {
      testWidgets('items in surface expose selectable semantics', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.text('Option A'), findsOneWidget);
          expect(find.text('Option B'), findsOneWidget);
          expect(find.text('Option C'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('selected item has selected state', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              value: 'b',
              labelText: 'Choose one',
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.byIcon(MdiIcons.check), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('items are tappable', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          var selectedValue = '';

          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              onChanged: (item) {
                selectedValue = item?.value ?? '';
              },
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Option A'));
          await tester.pumpAndSettle();

          expect(selectedValue, equals('a'));
        } finally {
          handle.dispose();
        }
      });
    });

    group('Search functionality', () {
      testWidgets('search field filters items', (tester) async {
        // REWRITE (DESIGN-145): the surface owns its own internal search field
        // again (see select_input_surface.dart) -- typing there filters live,
        // never on the closed field, which is always read-only.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
            ),
          );

          await tester.tap(find.byType(LayrzInputChrome).first);
          await tester.pumpAndSettle();

          final searchField = find.descendant(
            of: find.byType(LayrzSelectInputSurface<String>),
            matching: find.byType(EditableText),
          );
          await tester.enterText(searchField, 'B');
          await tester.pumpAndSettle();

          // Assert the narrowing: the right item remains, the wrong one is gone.
          expect(find.text('Option B'), findsOneWidget);
          expect(find.text('Option A'), findsNothing);
          expect(find.text('Option C'), findsNothing);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('empty search shows empty list message', (tester) async {
        // REWRITE (DESIGN-145): typed into the surface's own internal search
        // field, not the closed field itself.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
              emptyListText: 'No matches',
            ),
          );

          await tester.tap(find.byType(LayrzInputChrome).first);
          await tester.pumpAndSettle();

          final searchField = find.descendant(
            of: find.byType(LayrzSelectInputSurface<String>),
            matching: find.byType(EditableText),
          );
          await tester.enterText(searchField, 'XYZ');
          await tester.pumpAndSettle();

          expect(find.text('No matches'), findsOneWidget);
          expect(find.text('Option A'), findsNothing);
          expect(find.text('Option B'), findsNothing);
          expect(find.text('Option C'), findsNothing);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('search without search field enabled shows all items', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              enableSearch: false,
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.byType(LayrzTextInput), findsNothing);
          expect(find.text('Option A'), findsOneWidget);
          expect(find.text('Option B'), findsOneWidget);
          expect(find.text('Option C'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Desktop anchored panel', () {
      testWidgets('surface opens as anchored panel on desktop', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.text('Option A'), findsOneWidget);
          expect(find.text('Option B'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Multiple selections', () {
      testWidgets('all items are independently selectable', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final selections = <String>[];

          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              onChanged: (item) {
                selections.add(item?.value ?? '');
              },
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Option A'));
          await tester.pumpAndSettle();

          expect(selections.length, equals(1));
          expect(selections.first, equals('a'));

          await tester.tap(field);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Option C'));
          await tester.pumpAndSettle();

          expect(selections.length, equals(2));
          expect(selections.last, equals('c'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('can unselect with canUnselect true', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          var selectedValue = 'a';

          final itemsWithEmpty = <LayrzSelectItem<String>>[
            const LayrzSelectItem(value: '', child: Text('None'), searchableStrings: {'None'}),
            const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ];

          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: itemsWithEmpty,
              labelText: 'Choose',
              value: selectedValue,
              canUnselect: true,
              onChanged: (item) {
                selectedValue = item?.value ?? '';
              },
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          await tester.tap(find.text('None'));
          await tester.pumpAndSettle();

          expect(selectedValue, equals(''));
        } finally {
          handle.dispose();
        }
      });
    });

    group('Custom filter', () {
      testWidgets('custom filter function is applied', (tester) async {
        // REWRITE (DESIGN-145): typed into the surface's own internal search
        // field, not the closed field.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
              filter: (query, item) => item.searchableStrings.any((s) => s.toUpperCase().contains(query.toUpperCase())),
            ),
          );

          await tester.tap(find.byType(LayrzInputChrome).first);
          await tester.pumpAndSettle();

          final searchField = find.descendant(
            of: find.byType(LayrzSelectInputSurface<String>),
            matching: find.byType(EditableText),
          );
          await tester.enterText(searchField, 'B');
          await tester.pumpAndSettle();

          // The custom filter narrows to just Option B.
          expect(find.text('Option B'), findsOneWidget);
          expect(find.text('Option A'), findsNothing);
          expect(find.text('Option C'), findsNothing);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Field updates', () {
      testWidgets('selected value updates field display', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final state = _TestState();

          await pumpThemedApp(
            tester,
            StatefulBuilder(
              builder: (context, setState) {
                return LayrzSelectInput<String>(
                  itemExtent: 40,
                  items: items,
                  value: state.selectedValue,
                  labelText: 'Choose one',
                  onChanged: (item) {
                    setState(() {
                      state.selectedValue = item?.value;
                    });
                  },
                );
              },
            ),
          );

          final field = find.byType(LayrzInputChrome);
          await tester.tap(field);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Option B'));
          await tester.pumpAndSettle();

          await tester.tap(field);
          await tester.pumpAndSettle();

          expect(find.text('Option B'), findsWidgets);
        } finally {
          handle.dispose();
        }
      });
    });
  });
}

class _TestState {
  String? selectedValue;
}

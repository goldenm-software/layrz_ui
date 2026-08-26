import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput Accessibility - Semantics', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    group('Anchor semantics', () {
      testWidgets('anchor exposes label and button state', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              items: items,
              labelText: 'Choose an option',
            ),
          );

          final semantics = tester.getSemantics(find.byType(LayrzSelectInput<String>));
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
              items: items,
              labelText: 'Select',
              hintText: 'Choose from list',
            ),
          );

          final chromeWidget = find.byType(LayrzInputChrome);
          final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
          expect(chrome.labelText, equals('Select'));
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
        // REWRITE: the search box this test originally typed into lived inside
        // the panel and is gone. The field itself is the searcher now, which
        // only works with the surface open -- the desktop path.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
            ),
          );

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(EditableText), 'B');
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
        // REWRITE: typed into the field itself now, not a separate search box.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
              emptyListText: 'No matches',
            ),
          );

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(EditableText), 'XYZ');
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
            const LayrzSelectItem(labelText: 'None', value: ''),
            const LayrzSelectItem(labelText: 'Option A', value: 'a'),
          ];

          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
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
        // REWRITE: typed into the field itself now, not a separate search box.
        // Also fixes a pre-existing weak assertion -- the original filter,
        // `item.labelText.contains(query.toUpperCase())`, was case-sensitive
        // against "Option A" and a query of "OPTION" never actually matched
        // anything; the sole assertion checked only that the search box widget
        // still existed, not that filtering narrowed the list. Rewritten with a
        // genuinely case-insensitive filter and an assertion on the narrowing.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          await pumpThemedApp(
            tester,
            LayrzSelectInput<String>(
              items: items,
              labelText: 'Choose one',
              enableSearch: true,
              filter: (query, item) => item.labelText.toUpperCase().contains(query.toUpperCase()),
            ),
          );

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(EditableText), 'B');
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

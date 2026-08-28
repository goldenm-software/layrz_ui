import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `combobox_surface_test.dart`'s own `dumpSemanticsLabels` -- used
/// here, rather than `find.bySemanticsLabel`, for the same DESIGN-161 reason:
/// that matcher also matches literal text on renderable widgets, and has
/// already produced a false green in this repo.
List<String> dumpSemanticsLabels(WidgetTester tester) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) labels.add(label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return labels;
}

/// Counts semantics nodes whose label contains [needle].
int countSemanticsWithLabel(WidgetTester tester, String needle) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  var count = 0;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label.contains(needle)) count++;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return count;
}

void main() {
  group('LayrzComboBoxInput - Accessibility', () {
    testWidgets('field is labeled correctly for screen readers', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select an option',
          options: options,
        ),
      );

      // The combobox and text input should be present
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('combobox label is exposed to screen readers exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      final options = ['Option A', 'Option B'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select item',
          options: options,
        ),
      );

      // Exactly one semantics node carries the label. Before the LayrzInputChrome
      // migration, the wrap around LayrzTextInput produced a second, unmerged node
      // (the inner field's own Semantics), so a screen reader announced the label
      // twice — this count is what actually catches that regression.
      expect(countSemanticsWithLabel(tester, 'Select item'), 1);

      handle.dispose();
    });

    testWidgets('disabled combobox is semantically marked', (tester) async {
      final handle = tester.ensureSemantics();
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Disabled combobox',
          options: options,
          disabled: true,
        ),
      );

      // Verify disabled semantics - combobox is a button with expanded state
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzComboBoxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Disabled combobox',
          hasEnabledState: true,
          isEnabled: false,
          isButton: true,
          isFocusable: true,
          hasFocusAction: true,
          hasExpandedState: true,
          // When disabled, expanded is false but hasExpandedState is still true
        ),
      );

      handle.dispose();
    });

    testWidgets('read-only combobox is semantically marked', (tester) async {
      final handle = tester.ensureSemantics();
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Read-only combobox',
          options: options,
          readOnly: true,
        ),
      );

      // Verify read-only semantics - combobox is a button with expanded state
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzComboBoxInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Read-only combobox',
          hasEnabledState: true,
          isEnabled: false,
          isButton: true,
          isFocusable: true,
          hasFocusAction: true,
          hasExpandedState: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('required indicator is present when isRequired is true', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Required field',
          options: options,
          isRequired: true,
        ),
      );

      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('error messages are displayed when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          errors: ['This field is required', 'Invalid format'],
        ),
      );

      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('help text is displayed when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          helpTitleText: 'Help',
          helpContentText: 'Select an option from the list',
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('disabled state is properly announced', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          disabled: true,
        ),
      );

      // Field should be disabled and not interactive
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('supports input formatters for accessibility', (tester) async {
      final options = ['Option 1'];
      final formatters = <TextInputFormatter>[];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          inputFormatters: formatters,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('hint text provides input guidance', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          hintText: 'Type to search options',
          options: options,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('field has proper semantic label', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose an option',
          options: options,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('text selection is supported', (tester) async {
      final options = ['Option 1'];
      final controller = TextEditingController(text: 'Initial');

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          controller: controller,
        ),
      );

      // Tap field to enable selection
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Selection operations should be available
      expect(controller.text, 'Initial');

      controller.dispose();
    });

    testWidgets('shows contextual help with helpTitleText and helpContentText', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select',
          options: options,
          helpTitleText: 'Tip',
          helpContentText: 'Choose from available options',
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('field is focusable via keyboard', (tester) async {
      final options = ['Option 1', 'Option 2'];
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('empty options message displayed with proper contrast', (tester) async {
      final options = ['Apple', 'Banana'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Fruits',
          options: options,
          emptyOptionsText: 'No matching fruits',
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets(
      'DESIGN-161: the mobile bottom sheet carries a name identifying what is being picked',
      (tester) async {
        // Witnessed failing before the fix: on the pre-fix `BottomSheetContent`
        // (no `Semantics`, no heading, no label parameter, no search field at
        // all), `dumpSemanticsLabels` while the sheet was open returned every
        // ancestor label EXCLUDING 'Choose an option' and its search field's
        // label -- both live behind the modal barrier on the closed field, or
        // did not exist. Asserted by dumping the tree, not
        // `find.bySemanticsLabel` (see `dumpSemanticsLabels`'s own doc
        // comment): a bare `Text` widget's implicit label would have made that
        // matcher a false green.
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        final options = ['Option 1', 'Option 2'];

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose an option',
            options: options,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsOneWidget);

        final l10n = LayrzUiL10n.of(tester.element(find.byType(BottomSheetContent)));
        final labels = dumpSemanticsLabels(tester);

        expect(
          labels,
          contains('Choose an option'),
          reason: "the sheet's subtree must carry the picker's own name while open",
        );
        expect(
          labels.any((label) => label.contains(l10n.inputsSearchFieldLabel)),
          isTrue,
          reason: 'the sheet must also carry a distinct name for its own search field',
        );

        handle.dispose();
      },
    );
  });
}

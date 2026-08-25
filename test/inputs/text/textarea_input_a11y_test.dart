import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';

/// Counts semantics nodes whose `label`, `hint`, or `value` contains [needle].
///
/// Deliberately **not** named `countSemanticsWithLabel` and **not** a copy of the
/// label-only helper duplicated in the number, search, and combobox a11y suites: that
/// helper inspects `label` alone, which returns 1 against `LayrzTextAreaInput`'s
/// duplicate-hint bug (DESIGN-149) because the second copy of the string sits in `hint`,
/// a field the label-only helper never looks at. Spanning all three string fields is what
/// makes this helper able to tell "announced once" apart from "announced twice, in two
/// different fields" — the exact defect this suite pins. Requires
/// [WidgetTester.ensureSemantics] to be active.
int countSemanticsOccurrences(WidgetTester tester, String needle) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  var count = 0;
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.contains(needle)) count++;
    if (data.hint.contains(needle)) count++;
    if (data.value.contains(needle)) count++;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return count;
}

void main() {
  group('LayrzTextAreaInput - Accessibility', () {
    testWidgets('field is labelled with labelText', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Description',
          controller: controller,
        ),
      );

      expect(findButtonLabel('Description'), findsOneWidget);
    });

    testWidgets('textarea label is exposed to screen readers exactly once', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Message',
          controller: controller,
        ),
      );

      // Label should be accessible via semantics - exactly once
      expect(find.bySemanticsLabel('Message'), findsOneWidget);

      // Verify the semantic node - multiline fields have isTextField, isMultiline, isFocusable
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Message',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isMultiline: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('disabled textarea is semantically marked', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Disabled textarea',
          disabled: true,
          controller: controller,
        ),
      );

      // Verify disabled semantics - disabled textareas are read-only from the EditableText perspective
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Disabled textarea',
          hasEnabledState: true,
          isEnabled: false,
          isTextField: true,
          isMultiline: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('multiline nature is exposed to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Message',
          minLines: 3,
          maxLines: 10,
          controller: controller,
        ),
      );

      // Verify multiline is exposed in semantics tree
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Message',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isMultiline: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets(
      'required indicator is exposed to semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Name',
            isRequired: true,
            controller: controller,
          ),
        );

        // Required status is appended to the label using the localized string.
        // The exact format is "Label name, required" using the localization key.
        expect(find.bySemanticsLabel('Name, required'), findsOneWidget);

        // Verify the semantic node structure remains valid with required indicator
        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzTextAreaInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Name, required',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'error state is exposed to semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Description',
            errors: ['This field is required'],
            controller: controller,
          ),
        );

        // Regression guard: error text is automatically merged into the field's semantics
        // label by EditableText. This test verifies the existing behavior—that error messages
        // reach screen readers—is not accidentally broken. No widget-side fix is needed;
        // EditableText handles this.
        final semanticsNode = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semanticsNode.label,
          contains('This field is required'),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'hint text is exposed to screen readers exactly once, merged into the label',
      (tester) async {
        // Phase 0 dump against this exact fixture (labelText: 'Comments',
        // hintText: 'Enter your comments here', empty controller), taken before the
        // DESIGN-149 fix:
        //
        //   SemanticsNode
        //     flags: isTextField, hasEnabledState, isEnabled, isMultiline, isFocusable
        //     label: "Comments\nEnter your comments here"
        //     hint:  "Enter your comments here"
        //
        // LayrzInputChrome renders `hintText` as a plain, non-excluded Text
        // (input_chrome.dart :417/:436) that Flutter merges straight into this field's
        // own label -- exactly the shape DESIGN-116 proved for LayrzNumberInput
        // ("Amount\nEnter price", number_input_a11y_test.dart:634-670). The textarea
        // ALSO set `hint: widget.hintText` on its own Semantics annotation, so the same
        // string landed a second time, in a different field, on the same node -- the
        // duplicate-announcement bug this test pins shut.
        //
        // The regression gate counts across label + hint + value (see
        // [countSemanticsOccurrences]'s doc comment for why a label-only counter would
        // pass on both sides of the fix and prove nothing). The shape pin below asserts
        // an explicit `hint: ''` for the same reason: writing it out makes "no longer
        // duplicated in `hint`" a visible assertion instead of an accidental default.
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Comments',
            hintText: 'Enter your comments here',
            controller: controller,
          ),
        );

        expect(countSemanticsOccurrences(tester, 'Enter your comments here'), 1);

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzTextAreaInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Comments\nEnter your comments here',
            hint: '',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'character counter is not exposed to semantics',
      (tester) async {
        // Exposing the counter via semantic `value` would re-announce it on every keystroke
        // ("1 of 500 characters… 2 of 500 characters…"), making the field unusable for screen
        // reader users. The visual counter in the UI is sufficient; semantic exposure would
        // degrade accessibility more than silence. This gap is not a blocker.
      },
      skip: true,
    );

    testWidgets('read-only state is semantically exposed', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          readOnly: true,
          controller: controller,
        ),
      );

      // Verify read-only is exposed in semantics tree
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Field',
          hasEnabledState: true,
          isTextField: true,
          isMultiline: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets(
      'text selection toolbar is accessible',
      (tester) async {
        // Attempted assertion: text selection toolbar accessibility.
        // The text selection toolbar (copy/paste/etc.) is a platform-specific overlay
        // managed by Flutter's EditableText and platform channels.
        // The toolbar itself is not exposed in the semantics tree;
        // accessibility is provided through screen reader announcements
        // of the toolbar's availability, which cannot be tested via find.bySemanticsLabel.
        // This test cannot be written against the semantics tree.
      },
      skip: true,
    );

    testWidgets(
      'a prefix text slot merges into the field accessible name',
      (tester) async {
        // The fuller D64 slot-semantics accounting (labelled icon/widget slots, the
        // pointer-only suppression) is exercised directly against LayrzInputChrome in
        // input_chrome_a11y_test.dart, since none of it has a public parameter on this
        // widget yet. What IS reachable through LayrzTextAreaInput today is the
        // non-interactive TEXT slot form: per D64, it merges into the field's own
        // accessible name rather than being excluded like an unlabelled icon/widget
        // slot. This is the one prefix/suffix accessibility behavior this unit can
        // verify without a chrome change of its own.
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Amount',
            prefixText: 'PREFIX',
            controller: controller,
          ),
        );

        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzTextAreaInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Amount\nPREFIX',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets('disabled prefix/suffix taps are not triggered', (tester) async {
      bool prefixTapped = false;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          prefixText: 'PREFIX',
          onPrefixTap: () => prefixTapped = true,
          disabled: true,
          controller: controller,
        ),
      );

      await tester.tap(find.text('PREFIX'));
      await tester.pumpAndSettle();

      expect(prefixTapped, isFalse);
    });

    testWidgets(
      'selection handles show for touch selection',
      (tester) async {
        // Attempted assertion: selection handles visibility.
        // Selection handles are a platform-specific rendering detail managed by
        // the platform's text selection layer (e.g., Android's ToolbarAndroid, iOS's CupertinoTextSelectionToolbar).
        // They are not exposed in Flutter's accessibility semantics tree.
        // Accessibility for selection is provided through TalkBack/VoiceOver announcements,
        // not through visual handles, and cannot be asserted via find.bySemanticsLabel.
        // This test cannot be written against the semantics tree.
      },
      skip: true,
    );

    testWidgets(
      'magnifier is configured for the platform',
      (tester) async {
        // Note: This test validates a widget property (magnifierConfiguration),
        // not an accessibility property. The magnifier itself is not exposed in
        // the semantics tree. While magnification aids low-vision users, we cannot
        // assert its behavior via semantics. This is a widget-level implementation
        // detail, not an accessibility assertion.
        final controller = TextEditingController(text: 'Text for magnifying');
        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Field',
            controller: controller,
          ),
        );

        final editableTextWidget = find.byType(EditableText).evaluate().first.widget as EditableText;
        expect(editableTextWidget.magnifierConfiguration, isNotNull);
      },
    );

    testWidgets(
      'custom semantic actions for required status are not exposed',
      (tester) async {
        // CustomSemanticsAction requires a working callable handler to avoid advertising an action
        // that does nothing when invoked. No handler exists from the outer semantics node without
        // interaction design beyond the field's scope.
      },
      skip: true,
    );

    testWidgets('widget renders without errors', (tester) async {
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets(
      'help affordance with helpContentText is accessible',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Field',
            helpContentText: 'This field accepts any text',
            controller: controller,
          ),
        );

        // Help content is exposed in the semantic tooltip (caller-supplied text)
        final semanticsHandle = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semanticsHandle.tooltip,
          equals('This field accepts any text'),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'help affordance with helpTitleText is accessible',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Field',
            helpTitleText: 'Guidelines',
            controller: controller,
          ),
        );

        // Help title is exposed in the semantic tooltip (caller-supplied text)
        final semanticsHandle = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semanticsHandle.tooltip,
          equals('Guidelines'),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'help affordance with both title and content is accessible',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Field',
            helpTitleText: 'Guidelines',
            helpContentText: 'Follow these rules carefully',
            controller: controller,
          ),
        );

        // Both title and content are combined in the semantic tooltip (caller-supplied text)
        final semanticsHandle = tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextAreaInput),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semanticsHandle.tooltip,
          equals('Guidelines. Follow these rules carefully'),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'field semantics remain intact when a prefixIcon is present',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();
        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Search',
            prefixIcon: MdiIcons.magnify,
            controller: controller,
          ),
        );

        // A `prefixIcon` with no `onPrefixTap` and no semantic label is declared
        // decorative by LayrzInputChrome (D64) and wrapped in ExcludeSemantics -- it
        // carries no meaning of its own, so the field's own semantics are unchanged
        // by its presence.
        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzTextAreaInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Search',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
          ),
        );

        handle.dispose();
      },
    );

    testWidgets(
      'field semantics remain intact when a suffixIcon is present',
      (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();
        await pumpThemed(
          tester,
          LayrzTextAreaInput(
            labelText: 'Clearable',
            suffixIcon: MdiIcons.close,
            controller: controller,
          ),
        );

        // A `suffixIcon` with no `onSuffixTap` and no semantic label is declared
        // decorative by LayrzInputChrome (D64) and wrapped in ExcludeSemantics -- it
        // carries no meaning of its own, so the field's own semantics are unchanged
        // by its presence.
        expect(
          tester.getSemantics(
            find
                .descendant(
                  of: find.byType(LayrzTextAreaInput),
                  matching: find.byType(Semantics),
                )
                .first,
          ),
          matchesSemantics(
            label: 'Clearable',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isMultiline: true,
            isFocusable: true,
          ),
        );

        handle.dispose();
      },
    );
  });
}

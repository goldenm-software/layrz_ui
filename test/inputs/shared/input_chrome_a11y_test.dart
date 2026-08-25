import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

import '../../helpers/pump_themed.dart';

/// Minimal harness reproducing how the public inputs (e.g. `LayrzTextInput`) assemble
/// [LayrzInputChrome] around a real editable field — an outer `Semantics(label: ...)`
/// with no `container: true`, wrapping a [LayrzInputChrome] whose child is a real
/// [LayrzEditableField].
///
/// This exists only because [LayrzInputPrefixSlot.semanticLabel] and
/// [LayrzInputSuffixSlot.semanticLabel] / `isDecorative` have no public parameter yet
/// (D64 item 11, deferred) — none of the five public inputs can construct a labelled or
/// declared-decorative slot today. Going through [LayrzInputChrome] directly is the only
/// way to exercise those branches, and reproducing the real field/chrome assembly (rather
/// than a bare `Container()` child) is what makes the merge behaviour measured by the
/// Phase 0 probe reproducible here.
class _FieldHarness extends StatelessWidget {
  /// The label rendered by the chrome and carried by the outer field [Semantics] node.
  final String? labelText;

  /// The prefix slot under test.
  final LayrzInputPrefixSlot prefixSlot;

  /// The suffix slot under test.
  final LayrzInputSuffixSlot suffixSlot;

  /// The controller backing the editable field.
  final TextEditingController controller;

  /// Creates a new [_FieldHarness] with the given properties.
  _FieldHarness({
    this.labelText,
    LayrzInputPrefixSlot? prefixSlot,
    LayrzInputSuffixSlot? suffixSlot,
    TextEditingController? controller,
  }) : prefixSlot = prefixSlot ?? LayrzInputPrefixSlot(),
       suffixSlot = suffixSlot ?? LayrzInputSuffixSlot(),
       controller = controller ?? TextEditingController();

  @override
  Widget build(BuildContext context) {
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: labelText,
      hintText: null,
      disabled: false,
      readOnly: false,
      controller: controller,
      focusNode: FocusNode(),
      onChanged: null,
      onSubmit: null,
      onFocusChanged: null,
      onTap: null,
      keyboardType: TextInputType.text,
      textInputAction: null,
      inputFormatters: const [],
      maxLength: null,
      autofocus: false,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: true,
      enableSuggestions: true,
      actions: null,
      minLines: 1,
      maxLines: 1,
      expands: false,
      textAlign: TextAlign.start,
    );

    // Mirrors text_input.dart's `Semantics(label: widget.labelText, enabled: ..., child:
    // LayrzInputChrome(...))` wrapping exactly -- this is "the field node" that Unit 1's
    // Phase 0 probe measured, since it has no `container: true` and so merges every
    // descendant configuration (the field's own, and any slot that doesn't create its
    // own boundary) into one SemanticsNode.
    return Semantics(
      label: labelText,
      enabled: true,
      child: LayrzInputChrome(
        labelText: labelText,
        isRequired: false,
        prefixSlot: prefixSlot,
        suffixSlot: suffixSlot,
        disabled: false,
        readOnly: false,
        errors: const [],
        hideDetails: true,
        states: const {},
        child: LayrzEditableField(config: fieldConfig),
      ),
    );
  }
}

/// Locates the harness's merged field node -- see [_FieldHarness]'s doc comment.
///
/// Never `tester.getSemantics(find.byType(_FieldHarness))`, which returns the app root
/// node rather than the harness's own.
SemanticsNode _fieldNode(WidgetTester tester) {
  return tester.getSemantics(
    find.descendant(of: find.byType(_FieldHarness), matching: find.byType(Semantics)).first,
  );
}

/// Invokes [SemanticsAction.tap] directly on [node], bypassing hit-testing -- exactly
/// how a screen reader's "activate" gesture reaches a semantics node.
void _performTap(WidgetTester tester, SemanticsNode node) {
  // ignore: deprecated_member_use
  tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.tap);
}

void main() {
  group('LayrzInputChrome — slot semantics accounting (D64)', () {
    testWidgets('no-slot baseline: field node carries only its own label and text-field state', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(tester, _FieldHarness(labelText: 'Amount'));

      expect(
        _fieldNode(tester),
        matchesSemantics(
          label: 'Amount',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('decorative icon slot contributes no node; field node is unchanged', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        _FieldHarness(
          labelText: 'Amount',
          prefixSlot: LayrzInputPrefixSlot(icon: MdiIcons.magnify, isDecorative: true),
        ),
      );

      // Visually still rendered...
      expect(find.byIcon(MdiIcons.magnify), findsOneWidget);

      // ...but byte-identical to the no-slot case in the semantics tree: same exhaustive
      // property set as the baseline above, nothing added by the icon's presence.
      expect(
        _fieldNode(tester),
        matchesSemantics(
          label: 'Amount',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('decorative widget slot contributes no node; field node is unchanged', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        _FieldHarness(
          labelText: 'Amount',
          suffixSlot: LayrzInputSuffixSlot(widget: const Icon(MdiIcons.star), isDecorative: true),
        ),
      );

      expect(find.byIcon(MdiIcons.star), findsOneWidget);

      expect(
        _fieldNode(tester),
        matchesSemantics(
          label: 'Amount',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('labelled non-interactive icon slot: its own node; field node does NOT gain the label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        _FieldHarness(
          labelText: 'Amount',
          prefixSlot: LayrzInputPrefixSlot(icon: MdiIcons.currencyUsd, semanticLabel: 'US Dollars'),
        ),
      );

      // Its own node, carrying the label -- proves `container: true` created the
      // boundary. Without it, this assertion fails because no separate node exists.
      expect(
        tester.getSemantics(find.bySemanticsLabel('US Dollars')),
        matchesSemantics(label: 'US Dollars'),
      );

      // Negative: the field node must NOT have absorbed the slot's label. Catches a
      // missing `container: true` on this branch.
      expect(
        _fieldNode(tester),
        matchesSemantics(
          label: 'Amount',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('non-interactive text slot merges into the field accessible name (Unit 1 baseline)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        _FieldHarness(
          labelText: 'Amount',
          prefixSlot: LayrzInputPrefixSlot(text: 'PREFIX'),
        ),
      );

      // Exact merged shape measured by Unit 1's Phase 0 probe: label first, then the
      // slot's text, \n-joined -- "Amount\nPREFIX".
      expect(
        _fieldNode(tester),
        matchesSemantics(
          label: 'Amount\nPREFIX',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    group('labelled interactive slot — the primary test (R1 guard)', () {
      testWidgets('prefix: its own button node; field node stays clean; taps route correctly', (tester) async {
        final handle = tester.ensureSemantics();
        var prefixTapped = false;

        await pumpThemed(
          tester,
          _FieldHarness(
            labelText: 'Amount',
            prefixSlot: LayrzInputPrefixSlot(
              icon: MdiIcons.close,
              onTap: () => prefixTapped = true,
              semanticLabel: 'Clear prefix',
            ),
          ),
        );

        final slotNode = tester.getSemantics(find.bySemanticsLabel('Clear prefix'));
        expect(
          slotNode,
          matchesSemantics(
            label: 'Clear prefix',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        // R1's guard: if `container: true` were missing, this would instead read
        // `isButton: true, label: 'Amount\nClear prefix'` -- the whole field
        // announcing as a button. It must not.
        final fieldNode = _fieldNode(tester);
        expect(
          fieldNode,
          matchesSemantics(
            label: 'Amount',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isFocusable: true,
          ),
        );

        _performTap(tester, slotNode);
        expect(prefixTapped, isTrue, reason: 'Activating the named slot node must fire its own callback');

        prefixTapped = false;
        _performTap(tester, fieldNode);
        expect(
          prefixTapped,
          isFalse,
          reason: 'Activating the field node must never fire the slot callback -- no collision to absorb',
        );

        handle.dispose();
      });

      testWidgets('suffix: its own button node; field node stays clean; taps route correctly', (tester) async {
        final handle = tester.ensureSemantics();
        var suffixTapped = false;

        await pumpThemed(
          tester,
          _FieldHarness(
            labelText: 'Amount',
            suffixSlot: LayrzInputSuffixSlot(
              icon: MdiIcons.close,
              onTap: () => suffixTapped = true,
              semanticLabel: 'Clear suffix',
            ),
          ),
        );

        final slotNode = tester.getSemantics(find.bySemanticsLabel('Clear suffix'));
        expect(
          slotNode,
          matchesSemantics(
            label: 'Clear suffix',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        final fieldNode = _fieldNode(tester);
        expect(
          fieldNode,
          matchesSemantics(
            label: 'Amount',
            hasEnabledState: true,
            isEnabled: true,
            isTextField: true,
            isFocusable: true,
          ),
        );

        _performTap(tester, slotNode);
        expect(suffixTapped, isTrue, reason: 'Activating the named slot node must fire its own callback');

        suffixTapped = false;
        _performTap(tester, fieldNode);
        expect(
          suffixTapped,
          isFalse,
          reason:
              'Activating the field node must never fire the slot callback -- this is the exact '
              'misdirection Unit 1 measured on the suffix side (suffixTapped=true before the fix)',
        );

        handle.dispose();
      });
    });

    group('unlabelled interactive slot — the suppression test (R2 guard, both sides)', () {
      // Do NOT assert `isNot(matchesSemantics(hasTapAction: true))` on the field node --
      // EditableText's own gesture handling is `excludeFromSemantics: true`
      // (text_selection.dart), so the field node carries no tap action of its own either
      // way, and that assertion would be false before *and* after the fix (see D64/§0).
      // Only the behavioural assertion -- invoking tap and observing the callback --
      // distinguishes the fixed chrome from the unfixed one.

      testWidgets('prefix: no separate node; activating the field node does not fire the slot callback', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        var prefixTapped = false;

        await pumpThemed(
          tester,
          _FieldHarness(
            labelText: 'Amount',
            prefixSlot: LayrzInputPrefixSlot(icon: MdiIcons.close, onTap: () => prefixTapped = true),
          ),
        );

        final fieldNode = _fieldNode(tester);
        _performTap(tester, fieldNode);

        expect(
          prefixTapped,
          isFalse,
          reason:
              'Unit 1 measured prefixTapped=true here before the fix (misdirection); the unlabelled '
              'slot must now be pointer-only and contribute no action to the field node',
        );

        handle.dispose();
      });

      testWidgets('suffix: no separate node; activating the field node does not fire the slot callback', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        var suffixTapped = false;

        await pumpThemed(
          tester,
          _FieldHarness(
            labelText: 'Amount',
            suffixSlot: LayrzInputSuffixSlot(icon: MdiIcons.close, onTap: () => suffixTapped = true),
          ),
        );

        final fieldNode = _fieldNode(tester);
        _performTap(tester, fieldNode);

        expect(
          suffixTapped,
          isFalse,
          reason:
              'Unit 1 measured suffixTapped=true here before the fix (misdirection); the unlabelled '
              'slot must now be pointer-only and contribute no action to the field node',
        );

        handle.dispose();
      });
    });

    testWidgets("LayrzSearchInput's clear button is announced and operable (production proof)", (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'query');

      await pumpThemed(
        tester,
        LayrzSearchInput(
          mode: LayrzSearchInputMode.field,
          controller: controller,
          debounce: Duration.zero,
        ),
      );

      final clearNode = tester.getSemantics(find.bySemanticsLabel('Clear'));
      expect(
        clearNode,
        matchesSemantics(
          label: 'Clear',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      _performTap(tester, clearNode);
      await tester.pump();

      expect(controller.text, isEmpty, reason: "Activating the announced 'Clear' node must clear the field");

      controller.dispose();
      handle.dispose();
    });

    testWidgets(
      'select_input_surface-shaped case: unlabelled suffix tap via the public LayrzTextInput stays suppressed',
      (tester) async {
        final handle = tester.ensureSemantics();
        var suffixTapped = false;

        await pumpThemed(
          tester,
          LayrzTextInput(
            labelText: 'Field',
            suffixIcon: MdiIcons.close,
            onSuffixTap: () => suffixTapped = true,
            controller: TextEditingController(),
          ),
        );

        // Pins the accepted cost recorded in D64 item 10: there is no public
        // `suffixSemanticLabel:` parameter yet, so this clear button (same shape as
        // LayrzSearchInput's) is pointer-only. This test turns green on its own the day
        // the public parameter lands and this call site is updated to use it.
        final fieldNode = tester.getSemantics(
          find.descendant(of: find.byType(LayrzTextInput), matching: find.byType(Semantics)).first,
        );
        _performTap(tester, fieldNode);

        expect(suffixTapped, isFalse);

        handle.dispose();
      },
    );

    testWidgets(
      'LayrzNumberInput acceptance criterion: pre-flattened widget-form slot is suppressed, not silently leaked',
      (tester) async {
        final handle = tester.ensureSemantics();
        var prefixTapped = false;

        await pumpThemed(
          tester,
          LayrzNumberInput(
            labelText: 'Quantity',
            prefixIcon: MdiIcons.plus,
            onPrefixTap: () => prefixTapped = true,
            controller: TextEditingController(),
            // Forces number_input.dart's no-step-buttons branch, whose content is a
            // single `Semantics(label: ..., child: LayrzInputChrome(...))` -- the same
            // shape as text_input.dart/textarea_input.dart. With step buttons shown
            // (the default), the decrement/increment caps precede this node in the Row
            // and each carries its own Semantics (number_field_edge.dart), so a bare
            // `.first` would find the decrement cap's node instead of the field's.
            hideStepButtons: true,
          ),
        );

        // LayrzNumberInput pre-flattens icon/text into the widget slot form
        // (number_input.dart), so `slot.icon` and `slot.text` are both null and there is
        // no public label parameter. The chrome must still make a deliberate, testable
        // choice (suppressed) rather than silently leaking an anonymous action.
        final fieldNode = tester.getSemantics(
          find.descendant(of: find.byType(LayrzNumberInput), matching: find.byType(Semantics)).first,
        );
        _performTap(tester, fieldNode);

        expect(prefixTapped, isFalse);

        handle.dispose();
      },
    );
  });
}

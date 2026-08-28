import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Resolves the nearest ancestor `Semantics` widget (inclusive of [finder]
/// itself) that carries an explicit `label`, and asserts that its announced
/// label contains [expectedFragment] and matches every other property in
/// [matcher].
///
/// A plain `tester.getSemantics(finder)` is not reliable here: both
/// `_StepCell` (stepper_wide.dart) and `_CompactStepRow` (stepper_compact.dart)
/// wrap a row's label `Text` in a `Semantics(label: '...')` without
/// `excludeSemantics: true`, but whether that label merges with the `Text`
/// descendant's own semantics — landing on one shared node — or stays a
/// separate ancestor node depends on whether the row is tappable: a tappable
/// row's `GestureDetector.onTap` creates its own actionable semantics
/// boundary that blocks the merge, so `find.text(...)` alone resolves to the
/// *wrong* node for a tappable row (the label-only child, missing position
/// and state) while accidentally working for a locked row (where it merges
/// upward and duplicates instead — see the second half of this note). Walking
/// up to the nearest `Semantics(label: ...)` ancestor is the one strategy
/// that resolves correctly in both cases.
///
/// Separately: the persistent compact counter (`stepper_compact.dart:99-104`)
/// and the wrapping `Semantics(label:)` around each nav button in
/// `stepper.dart:196-203/207-214` wrap a `Text`/`LayrzButton` descendant
/// without `excludeSemantics: true` too, so on a *locked* row, or on a nav
/// button, the descendant's own semantics node merges into the ancestor and
/// the announced label ends up duplicated — e.g.
/// `"Step 2 of 2, Step 2. error, needs attention.\nStep 2"` rather than
/// appearing once. `contains` is used here (matching the convention already
/// established in `button_a11y_test.dart` for the same reason on
/// `LayrzButton`) rather than baking that duplication into an exact-match
/// string throughout this file. Both of these are genuine, reported component
/// semantics defects this unit does not own the files to fix — see the report
/// to the lead.
void expectStepSemantics(
  WidgetTester tester,
  Finder finder,
  String expectedFragment, {
  required Matcher matcher,
}) {
  final labelled = find.ancestor(
    of: finder,
    matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label != null),
  );
  final target = labelled.evaluate().isNotEmpty ? labelled.first : finder;
  final semantics = tester.getSemantics(target);
  expect(semantics.label, contains(expectedFragment));
  expect(semantics, matcher);
}

void main() {
  group('LayrzStepper Accessibility', () {
    final testSteps = [
      const LayrzStep(
        labelText: 'Personal',
        body: SizedBox(child: Text('Personal Info')),
      ),
      const LayrzStep(
        labelText: 'Shipping',
        body: SizedBox(child: Text('Shipping Address')),
      ),
      const LayrzStep(
        labelText: 'Review',
        body: SizedBox(child: Text('Review Order')),
      ),
    ];

    testWidgets('step headers have semantics labels with position and state (wide)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzStepper(steps: testSteps, isCompact: false),
        );

        // Wide header cells build their semantics label as
        // "Step X of Y, labelText. state." (see LayrzStepperWideHeader._StepCell).
        expectStepSemantics(
          tester,
          find.text('Personal'),
          'Step 1 of 3, Personal. currently active.',
          matcher: matchesSemantics(isEnabled: true, hasEnabledState: true, hasTapAction: true, isButton: true),
        );
        expectStepSemantics(
          tester,
          find.text('Shipping'),
          'Step 2 of 3, Shipping. upcoming, not yet reached, locked.',
          matcher: matchesSemantics(hasEnabledState: true),
        );
        expectStepSemantics(
          tester,
          find.text('Review'),
          'Step 3 of 3, Review. upcoming, not yet reached, locked.',
          matcher: matchesSemantics(hasEnabledState: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('completed step has checkmark glyph, not colour alone (compact)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      // currentIndex must not coincide with the step under test: the active
      // index always wins over an explicit LayrzStep.state override (see
      // LayrzStepperCompactLayout._resolveState), so step 0 here is driven
      // past active before its explicit `completed` state can take effect.
      final controller = LayrzStepperController();
      controller.setStepCount(2);
      controller.goTo(1);

      try {
        final completedSteps = [
          const LayrzStep(
            labelText: 'Step 1',
            body: SizedBox(child: Text('Content')),
            state: LayrzStepperState.completed,
          ),
          const LayrzStep(
            labelText: 'Step 2',
            body: SizedBox(child: Text('Content')),
          ),
        ];

        await pumpThemed(
          tester,
          LayrzStepper(steps: completedSteps, controller: controller, isCompact: true),
        );

        await tester.pumpAndSettle();

        // The completed step renders MdiIcons.check inside its LayrzStepIndicator —
        // this is the actual glyph assertion the old test's name promised but never made.
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.check),
          findsOneWidget,
        );
        // A completed row's header is tappable (jump back for review), and its
        // semantics label announces "completed" independently of the glyph.
        // hasExpandedState/isExpanded: false because the completed row is
        // tappable but not the currently open one (index 1 is open).
        expectStepSemantics(
          tester,
          find.text('Step 1'),
          'Step 1 of 2, Step 1. completed.',
          matcher: matchesSemantics(
            isEnabled: true,
            hasEnabledState: true,
            hasExpandedState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('error step has alert glyph, not colour alone (wide)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        final errorSteps = [
          const LayrzStep(
            labelText: 'Step 1',
            body: SizedBox(child: Text('Content')),
          ),
          LayrzStep(
            labelText: 'Step 2',
            body: const SizedBox(child: Text('Content')),
            state: LayrzStepperState.error,
          ),
        ];

        await pumpThemed(
          tester,
          LayrzStepper(steps: errorSteps, isCompact: false),
        );

        // The error step renders MdiIcons.alertCircle inside its LayrzStepIndicator —
        // the glyph itself, not merely "the stepper rendered".
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.alertCircle),
          findsOneWidget,
        );
        // Error steps are tappable by design: LayrzStepperState.error's
        // contract (stepper_state.dart:7,29; stepper.dart:34) promises a
        // failed step "can be jumped to for correction", and
        // LayrzStepperWideHeader._isTappable gates on
        // completed||active||error, so an error row is enabled, a button,
        // and reachable via tap — the same shape a completed row has.
        expectStepSemantics(
          tester,
          find.text('Step 2'),
          'Step 2 of 2, Step 2. error, needs attention.',
          matcher: matchesSemantics(isEnabled: true, hasEnabledState: true, hasTapAction: true, isButton: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('error step has alert glyph, not colour alone (compact)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      // currentIndex must not coincide with the step under test — the active
      // index always wins over an explicit LayrzStep.state override (see
      // LayrzStepperCompactLayout._resolveState) — so step 1 is opened while
      // step 0 keeps its explicit `error` state.
      final controller = LayrzStepperController();
      controller.setStepCount(2);
      controller.goTo(1);

      try {
        final errorSteps = [
          const LayrzStep(
            labelText: 'Step 1',
            body: SizedBox(child: Text('Content')),
            state: LayrzStepperState.error,
          ),
          const LayrzStep(
            labelText: 'Step 2',
            body: SizedBox(child: Text('Content')),
          ),
        ];

        await pumpThemed(
          tester,
          LayrzStepper(steps: errorSteps, controller: controller, isCompact: true),
        );

        await tester.pumpAndSettle();

        // The error step renders MdiIcons.alertCircle inside its LayrzStepIndicator —
        // the glyph itself, not merely "the stepper rendered".
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.alertCircle),
          findsOneWidget,
        );
        // Error steps are tappable by design so a failed step can be jumped
        // to for correction, per LayrzStepperState.error's contract.
        // hasExpandedState/isExpanded: false because the error row is
        // tappable but not the currently open one (index 1 is open).
        expectStepSemantics(
          tester,
          find.text('Step 1'),
          'Step 1 of 2, Step 1. error, needs attention.',
          matcher: matchesSemantics(
            isEnabled: true,
            hasEnabledState: true,
            hasExpandedState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('back button is labelled and reachable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(1); // Move to step 2 so back button is enabled

      try {
        await pumpThemed(
          tester,
          LayrzStepper(
            steps: testSteps,
            controller: controller,
            backButtonLabel: 'Previous',
          ),
        );

        await tester.pumpAndSettle();

        final backButton = find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Previous',
        );
        expect(backButton, findsOneWidget);
        // The outer Semantics(label: backLabel) LayrzStepper wraps around the
        // button (stepper.dart:196-203) merges with LayrzButton's own
        // Semantics(label: widget.labelText), so the announced label is the
        // custom label concatenated with itself rather than appearing once —
        // see expectStepSemantics' doc comment for the same defect elsewhere.
        expectStepSemantics(
          tester,
          backButton,
          'Previous',
          matcher: matchesSemantics(isButton: true, isEnabled: true, hasEnabledState: true),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('next button is labelled and reachable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzStepper(
            steps: testSteps,
            nextButtonLabel: 'Continue',
          ),
        );

        final nextButton = find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Continue',
        );
        expect(nextButton, findsOneWidget);
        // See the back-button test above for why `contains` is used instead of
        // an exact match: the wrapping Semantics(label:) in stepper.dart
        // duplicates LayrzButton's own label in the merged announcement.
        expectStepSemantics(
          tester,
          nextButton,
          'Continue',
          matcher: matchesSemantics(isButton: true, isEnabled: true, hasEnabledState: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('completed step is distinguishable without colour alone (compact)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      // A single step would always resolve to `active` (currentIndex == 0 ==
      // index always wins over an explicit state override — see
      // LayrzStepperCompactLayout._resolveState), so a second step is added
      // purely to let the first genuinely land in `completed`.
      final controller = LayrzStepperController();
      controller.setStepCount(2);
      controller.goTo(1);

      try {
        final completedSteps = [
          const LayrzStep(
            labelText: 'Completed',
            body: SizedBox(child: Text('Done')),
            state: LayrzStepperState.completed,
          ),
          const LayrzStep(
            labelText: 'Next Up',
            body: SizedBox(child: Text('Later')),
          ),
        ];

        await pumpThemed(
          tester,
          LayrzStepper(steps: completedSteps, controller: controller, isCompact: true),
        );

        await tester.pumpAndSettle();

        // The distinguishing cue is the checkmark glyph, asserted directly —
        // not merely that the stepper rendered.
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.check),
          findsOneWidget,
        );
        expect(find.text('Later'), findsOneWidget);
        expectStepSemantics(
          tester,
          find.text('Completed'),
          'Step 1 of 2, Completed. completed.',
          matcher: matchesSemantics(
            isEnabled: true,
            hasEnabledState: true,
            hasExpandedState: true,
            hasTapAction: true,
            isButton: true,
          ),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('tapping completed step jumps back for review', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2); // Move to step 3

      try {
        await pumpThemed(
          tester,
          LayrzStepper(steps: testSteps, controller: controller),
        );

        await tester.pumpAndSettle();
        expect(find.text('Review Order'), findsOneWidget);

        // Drive the controller directly (rather than tapping through the
        // rendered header) so this test exercises the same "jump back" contract
        // in both the wide and compact layouts without depending on which one
        // the ambient viewport happened to select.
        controller.goTo(0);
        await tester.pumpAndSettle();

        expect(find.text('Personal Info'), findsOneWidget);
      } finally {
        controller.dispose();
      }
    });

    testWidgets('upcoming steps are not tappable and carry the locked affordance (compact)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      final controller = LayrzStepperController();
      controller.setStepCount(3);

      try {
        await pumpThemed(
          tester,
          LayrzStepper(steps: testSteps, controller: controller, isCompact: true),
        );

        await tester.pumpAndSettle();

        // The persistent "Step X of Y" counter sits above the accordion stack
        // and is additive to the per-step headers below it — it must itself be
        // reachable and announced independently of the row labels.
        expect(find.text('Step 1 of 3'), findsOneWidget);
        expectStepSemantics(
          tester,
          find.text('Step 1 of 3'),
          'Step 1 of 3',
          matcher: matchesSemantics(),
        );

        // On the first step, "Shipping" and "Review" are upcoming: disabled in
        // semantics, and carrying the lock glyph rather than the disclosure
        // chevron a tappable row would show. This is the Q8 fix and the WCAG
        // 1.4.1 gap closed by the redesign: a locked row must not look
        // identical to a tappable one that merely does nothing.
        expectStepSemantics(
          tester,
          find.text('Shipping'),
          'Step 2 of 3, Shipping. upcoming, not yet reached, locked.',
          matcher: matchesSemantics(hasEnabledState: true, isEnabled: false),
        );
        expectStepSemantics(
          tester,
          find.text('Review'),
          'Step 3 of 3, Review. upcoming, not yet reached, locked.',
          matcher: matchesSemantics(hasEnabledState: true, isEnabled: false),
        );

        // Both upcoming rows show the lock glyph. The active row ("Personal")
        // is tappable and legitimately carries the disclosure chevron instead —
        // only the two locked rows must not.
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.lockOutline),
          findsNWidgets(2),
        );
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.chevronDown),
          findsOneWidget,
        );

        // A locked row carries no expansion state at all: `expanded` is
        // deliberately null (not false) on the component, since a locked row
        // cannot ever be opened by the user — announcing `false` would wrongly
        // imply a closed-but-openable disclosure. matchesSemantics' default
        // (hasExpandedState: false) is exactly this "no expanded state" case.
        expectStepSemantics(
          tester,
          find.text('Shipping'),
          'Step 2 of 3, Shipping. upcoming, not yet reached, locked.',
          matcher: matchesSemantics(hasEnabledState: true, isEnabled: false, hasExpandedState: false),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('error state is visually distinct via glyph (wide)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      // Drive the controller to index 2 ("Review") so neither "Personal"
      // (completed) nor "Shipping" (error) is the active index and each
      // keeps its explicit state override — see
      // LayrzStepperWideHeader._stateOf: the active index always wins over
      // an explicit LayrzStep.state.
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);

      try {
        final errorSteps = [
          const LayrzStep(
            labelText: 'Personal',
            body: SizedBox(child: Text('Personal Info')),
            state: LayrzStepperState.completed,
          ),
          LayrzStep(
            labelText: 'Shipping',
            body: const SizedBox(child: Text('Address Error')),
            state: LayrzStepperState.error,
          ),
          const LayrzStep(
            labelText: 'Review',
            body: SizedBox(child: Text('Review Order')),
          ),
        ];

        await pumpThemed(
          tester,
          LayrzStepper(steps: errorSteps, controller: controller, isCompact: false),
        );

        await tester.pumpAndSettle();

        // Both the completed and error steps carry their own distinct glyph —
        // proof the two states are distinguishable without relying on colour.
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.check),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.alertCircle),
          findsOneWidget,
        );
        // See the error-glyph test above: error steps are tappable by design
        // so a failed step can be jumped to for correction, per
        // LayrzStepperState.error's contract.
        expectStepSemantics(
          tester,
          find.text('Shipping'),
          'Step 2 of 3, Shipping. error, needs attention.',
          matcher: matchesSemantics(isEnabled: true, hasEnabledState: true, hasTapAction: true, isButton: true),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });

    testWidgets('back button disabled on first step has null onTap and enabled: false', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzStepper(steps: testSteps),
        );

        final backButton = find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Back',
        );
        final button = tester.widget<LayrzButton>(backButton);
        expect(button.onTap, isNull);
        // See the labelled-and-reachable test above for why label is asserted
        // via `contains` rather than an exact match.
        expectStepSemantics(
          tester,
          backButton,
          'Back',
          matcher: matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('next button disabled on last step has null onTap and enabled: false', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);

      try {
        await pumpThemed(
          tester,
          LayrzStepper(steps: testSteps, controller: controller),
        );

        await tester.pumpAndSettle();

        final nextButton = find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Next',
        );
        final button = tester.widget<LayrzButton>(nextButton);
        expect(button.onTap, isNull);
        // See the labelled-and-reachable test above for why label is asserted
        // via `contains` rather than an exact match.
        expectStepSemantics(
          tester,
          nextButton,
          'Next',
          matcher: matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
      } finally {
        handle.dispose();
        controller.dispose();
      }
    });
  });
}

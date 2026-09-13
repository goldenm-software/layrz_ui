import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'helpers/pump_messenger.dart';

/// Finds the visible close ([MdiIcons.close]) [LayrzButton] on the current
/// front card — the same finder the rest of this module's tests use to
/// drive the manual-close path via [WidgetTester.tap].
///
/// Only valid while exactly one toast is visible. With two or more entries
/// queued at once, each renders its own close button — even the peeking
/// (non-interactive) ones — so callers must use [_findCloseButtonNear]
/// instead to disambiguate by the card's own title text.
Finder _findCloseButton() => find.widgetWithIcon(LayrzButton, MdiIcons.close);

/// Finds the close ([MdiIcons.close]) [LayrzButton] belonging to the card
/// whose title is [titleText] — the disambiguated counterpart of
/// [_findCloseButton] for use once more than one toast is queued at once.
///
/// Scopes by the card's outer `Stack` (content + progress bar,
/// `LayrzSnackbarView.build`) rather than a `Column`, since the title text
/// sits in a `Column` nested inside a `Row` that is itself a sibling of the
/// close button — a `Column` ancestor of the title would not enclose it.
Finder _findCloseButtonNear(String titleText) {
  return find.descendant(
    of: find.ancestor(of: find.text(titleText), matching: find.byType(Stack)).first,
    matching: find.widgetWithIcon(LayrzButton, MdiIcons.close),
  );
}

/// Regression coverage for the manual-close stale-hover leak: dismissing a
/// toast via its close button while the pointer sits over it must never
/// leave [LayrzSnackbarMessengerState]'s internal hover flag stuck `true` —
/// which previously froze the *next* toast's drain (progress bar visible
/// but never advancing) until the pointer moved away and back.
///
/// Root cause: [MouseRegion.onExit] is not guaranteed to fire when the
/// hovered widget is removed from the tree out from under the pointer
/// (rather than the pointer actually leaving its bounds) — a documented
/// Flutter gotcha. The messenger's shared, stack-level `_isHovered` bool
/// then never gets reset by `_handleStackExit`, so a subsequently-shown
/// toast reads a stale `_isHovered == true` in `show()` and starts paused
/// forever.
void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Pumps past the entry slide+fade+scale animation (260ms, DESIGN-60
  /// §Motion) so a freshly-shown toast is fully settled before further
  /// interaction.
  Future<void> pumpPastEntry(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('LayrzSnackbarMessenger — manual-close stale-hover leak', () {
    testWidgets(
      'a toast shown after the only hovered toast is manually closed still drains',
      (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);
        final messenger = LayrzSnackbarMessenger.of(context);

        messenger.show(
          const LayrzSnackbar(
            titleText: 'First',
            descriptionText: 'The first toast.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);

        // Hover the card — pauseDrain() runs via _handleStackEnter, exactly
        // like a real user reading the toast before dismissing it.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('First')));
        await tester.pump();

        // Close it via its close button WITHOUT any hover-exit ever being
        // dispatched — `tester.tap` only synthesizes a down/up at the given
        // location, it does not move `mouse`'s tracked pointer, so from the
        // mouse tracker's perspective the pointer never left. This is
        // exactly the real-world gotcha: MouseRegion.onExit is not
        // guaranteed to fire when the hovered widget is torn down out from
        // under the pointer (removal, not genuine pointer departure), so
        // _handleStackExit never runs here and _isHovered leaks true.
        await tester.tap(_findCloseButton());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('First'), findsNothing, reason: 'the closed toast must be gone');

        // Now move the pointer fully away — as a user naturally would right
        // after dismissing a toast — before anything new is ever shown.
        // Because the stack is currently empty, this move triggers no
        // `_handleStackExit` (there is no `MouseRegion` hit to exit from,
        // the whole stack overlay collapses to `SizedBox.shrink()` when the
        // queue is empty) — so on pre-fix code `_isHovered` is still stuck
        // `true` at this point, with the pointer nowhere near where the
        // next toast will render.
        await mouse.moveTo(const Offset(-500, -500));
        await tester.pump();

        // Show a new toast far from the pointer's new resting place — any
        // pause it starts with cannot be a genuine hover.
        messenger.show(
          const LayrzSnackbar(
            titleText: 'Second',
            descriptionText: 'The second toast.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);
        expect(find.text('Second'), findsOneWidget);

        // Advance well past the 3s duration. On the pre-fix code, the new
        // entry's drainController was paused at construction (show() saw
        // the stale _isHovered == true) and NEVER resumed, since exit was
        // never re-triggered either — so the toast would still be present
        // here. Post-fix, the new entry must have drained and dismissed on
        // schedule.
        await tester.pump(const Duration(milliseconds: 3200));
        await tester.pump();

        expect(
          find.text('Second'),
          findsNothing,
          reason:
              'a toast shown after the stack was emptied by a manual close must drain and '
              'auto-dismiss normally — it must not inherit a stale paused-hover state',
        );
      },
    );

    testWidgets(
      'a genuinely-hovered multi-toast stack still pauses drain for the untouched toast',
      (tester) async {
        setWideViewport(tester);
        final context = await pumpMessenger(tester);
        final messenger = LayrzSnackbarMessenger.of(context);

        messenger.show(
          const LayrzSnackbar(
            titleText: 'First',
            descriptionText: 'The first toast.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);

        messenger.show(
          const LayrzSnackbar(
            titleText: 'Second',
            descriptionText: 'The second toast.',
            duration: Duration(seconds: 3),
          ),
        );
        await pumpPastEntry(tester);

        // Hover the (still-visible) stack — both visible entries pause.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Second')));
        await tester.pump();

        // Close only the front ("Second") toast while hovered — the queue
        // is NOT emptied by this (First is still queued), so this must NOT
        // clear _isHovered: First's drain must remain genuinely paused.
        await tester.tap(_findCloseButtonNear('Second'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Second'), findsNothing);
        expect(find.text('First'), findsOneWidget, reason: 'the untouched toast must still be queued');

        // Advance well past the 3s duration — First must still be paused,
        // since the pointer never left the stack and one card (First) is
        // still genuinely visible under it.
        await tester.pump(const Duration(seconds: 5));
        expect(
          find.text('First'),
          findsOneWidget,
          reason: 'closing one toast must not spuriously clear hover-pause for a still-visible sibling',
        );

        // Move away — drain resumes and First eventually dismisses,
        // confirming the pause was real (not stuck) and not merely masked.
        await mouse.moveTo(const Offset(-100, -100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pump();
        expect(find.text('First'), findsNothing, reason: 'drain must resume and complete after hover exit');
      },
    );
  });
}

import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// Pumps a widget with Navigator support for narrow layout sheet tests.
///
/// A compact-viewport shell presents its detail pane as a sheet pushed onto a
/// [Navigator], so any compact-size test that may actually open an item needs
/// this ancestor — without it, [LayrzScaffoldShell] asserts.
Future<void> _pumpThemedWithNavigator(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale("en"),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Navigator(
                onGenerateRoute: (settings) {
                  return PageRouteBuilder<void>(
                    pageBuilder: (context, animation, secondaryAnimation) => Center(child: child),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps a [LayrzScaffoldShell] at the given [size] with [items].
///
/// Set [withNavigator] for compact-viewport tests that may actually open an
/// item — the shell needs a real [Navigator] ancestor to present its sheet.
Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required Size size,
  bool withNavigator = false,
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final shell = SizedBox.expand(
    child: LayrzScaffoldShell<_TestItem>(
      controller: controller,
      items: items,
      onItemTap: (item) => controller.open(key: item.key, builder: (_) => Text("detail:${item.item.name}")),
      itemExtent: 56.0,
    ),
  );

  if (withNavigator) {
    await _pumpThemedWithNavigator(tester, shell);
  } else {
    await pumpThemed(tester, shell);
  }
  expect(tester.takeException(), isNull);
}

/// Builds a single-item list containing [actions].
List<LayrzScaffoldItem<_TestItem>> _itemsWithActions(List<LayrzButton> actions) {
  return [
    LayrzScaffoldItem<_TestItem>(
      key: const ValueKey("1"),
      item: const _TestItem("1", "Alpha"),
      tile: const SizedBox(child: Text("Alpha")),
      searchableStrings: const {"Alpha"},
      actions: actions,
    ),
  ];
}

const _kWideSize = Size(1500, 950);
const _kCompactSize = Size(400, 800);

void main() {
  group("LayrzScaffoldItem.actions — no regression when empty", () {
    testWidgets("wide viewport: empty actions renders exactly as a plain row (indicator + tile only)", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      expect(find.byType(LayrzTappable), findsOneWidget);
      expect(find.byType(LayrzButton), findsNothing);
      // No action-reveal machinery (Stack-based translation) is present for an
      // empty-actions row — MouseRegion count matches the shell's own baseline
      // usage, not an extra one added by the row.
      expect(find.text("Alpha"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("compact viewport: empty actions renders exactly as a plain row", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await _pumpShell(tester, items: items, controller: controller, size: _kCompactSize);

      expect(find.byType(LayrzTappable), findsOneWidget);
      expect(find.byType(LayrzButton), findsNothing);

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — desktop hover reveal (wide viewport)", () {
    testWidgets("actions are present in the tree but invisible (opacity 0) by default", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      expect(find.byType(LayrzButton), findsNWidgets(2));

      // At rest, the overlay is faded fully out — the action buttons are laid out
      // (present in the tree) but not visible.
      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
      expect(opacity.opacity, 0.0);

      controller.dispose();
    });

    testWidgets("hovering the row reveals the actions as an overlay WITHOUT translating the row body", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final hoveredRect = tester.getRect(rowFinder);

      // Geometry (size AND position) must not change on hover — no translation,
      // no resize (decision D15: hover may vary colour/opacity/shadow/cursor only).
      expect(hoveredRect, equals(restRect));

      // The overlay is now fully visible and the action buttons are present.
      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
      expect(opacity.opacity, 1.0);
      expect(find.byType(LayrzButton), findsNWidgets(2));

      controller.dispose();
    });

    testWidgets("moving the pointer away hides the actions again (opacity back to 0, still no translation)", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 1.0);
      expect(tester.getRect(rowFinder), equals(restRect));

      // Move away from the row entirely.
      await gesture.moveTo(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 0.0);
      // Still never translated, in either direction.
      expect(tester.getRect(rowFinder), equals(restRect));

      controller.dispose();
    });

    testWidgets("row body tap still opens the detail pane while actions are revealed", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(controller.isOpen, isFalse);

      await tester.tap(rowFinder);
      await tester.pump();

      expect(controller.openedKey, equals(const ValueKey("1")));

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — revealed strip stays inside the row's rounded surface", () {
    testWidgets("the reveal Stack is clipped with the same rounded radius as the row body", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      // The reveal must be clipped by a rounded rect — not a plain rectangular
      // ClipRect — and its radius must match the row body's own LayrzTappable
      // corners (tokens.radius.br2) so the strip never paints past the row's
      // rounded surface.
      expect(find.byType(ClipRRect), findsWidgets);
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      final tappable = tester.widget<LayrzTappable>(find.byType(LayrzTappable).first);
      expect(clip.borderRadius, equals(tappable.borderRadius));

      controller.dispose();
    });

    testWidgets("the revealed actions' right edge is inset from the row's right edge by the scrollbar gutter", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);

      // The row's own (stationary) bounds are the ClipRRect that wraps the
      // reveal Stack — unlike the LayrzTappable rect, this does not itself
      // translate during the hover reveal, so it is the correct fixed
      // reference for "the row's right edge".
      final stackRect = tester.getRect(find.byType(ClipRRect).first);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final deleteButtonRect = tester.getRect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Delete").first,
      );
      // LayrzThemeData.light()'s default LayrzSpacingTokens.sp2 (10.0) is the
      // strip's own trailing inset from the row's edge (see the Padding around
      // actionsStrip's Row in scaffold_row.dart) — assert at least that much
      // clearance, with a small tolerance for the FAB's own hit-test padding.
      const minimumTrailingInset = 9.0;
      expect(deleteButtonRect.right, lessThan(stackRect.right));
      expect(stackRect.right - deleteButtonRect.right, greaterThanOrEqualTo(minimumTrailingInset));

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — mobile swipe reveal (compact viewport)", () {
    testWidgets("a leftward horizontal swipe reveals the actions", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kCompactSize);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      await tester.drag(rowFinder, const Offset(-150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final revealedRect = tester.getRect(rowFinder);
      expect(revealedRect.size, restRect.size);
      expect(revealedRect.left, lessThan(restRect.left));

      controller.dispose();
    });

    testWidgets("a rightward swipe after reveal hides the actions again", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kCompactSize);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      await tester.drag(rowFinder, const Offset(-150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(rowFinder).left, lessThan(restRect.left));

      await tester.drag(rowFinder, const Offset(150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.getRect(rowFinder).left, closeTo(restRect.left, 0.5));

      controller.dispose();
    });

    testWidgets("row body tap while revealed hides the actions instead of opening (swipe-list convention)", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kCompactSize, withNavigator: true);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      await tester.drag(rowFinder, const Offset(-150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(rowFinder).left, lessThan(restRect.left));

      await tester.tap(rowFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // First tap only dismisses the reveal, it must not open the detail pane.
      expect(controller.isOpen, isFalse);
      expect(tester.getRect(rowFinder).left, closeTo(restRect.left, 0.5));

      // A second tap, now that actions are hidden, opens normally. Wait out
      // LayrzTappable's double-tap collapse cooldown first so this reads as a
      // fresh, independent tap rather than being swallowed as part of a double-tap.
      await tester.pump(kDoubleTapTimeout);
      await tester.tap(rowFinder);
      await tester.pump();
      expect(controller.openedKey, equals(const ValueKey("1")));

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — desktop overlay fits regardless of action count", () {
    /// Computes the mobile swipe's fully-revealed translation distance for [n]
    /// Fab actions from the same tokens the row itself reads: `n` square Fab
    /// buttons (`kLayrzButtonHeight` wide each) separated by `n - 1` `sp1`
    /// gaps, inside `sp2` padding on each side of the strip. Desktop no longer
    /// translates on hover (see FIX 62.1), so this extent now only governs the
    /// compact/mobile swipe path — kept here since both groups in this file
    /// share the same underlying `_revealExtentFor` computation in the row.
    double expectedRevealExtent(int n) {
      final spacing = LayrzThemeData.light().tokens.spacing;
      return n * kLayrzButtonHeight + (n - 1) * spacing.sp1 + 2 * spacing.sp2;
    }

    testWidgets("2 Fab actions: hover reveals the overlay without translating the row", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);
      final stackRect = tester.getRect(find.byType(ClipRRect).first);
      final restRect = tester.getRect(rowFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // No translation at all, regardless of action count.
      expect(tester.getRect(rowFinder), equals(restRect));

      // The fully-revealed rightmost action (Delete) must be entirely visible
      // inside the row's clipped bounds.
      final deleteRect = tester.getRect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Delete").first,
      );
      expect(deleteRect.right, lessThanOrEqualTo(stackRect.right + 0.5));
      expect(deleteRect.left, greaterThanOrEqualTo(stackRect.left - 0.5));

      controller.dispose();
    });

    testWidgets("3 Fab actions: hover reveals the overlay without translating the row", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.edit(labelText: "Duplicate", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      final rowFinder = find.byType(LayrzTappable);
      final stackRect = tester.getRect(find.byType(ClipRRect).first);
      final restRect = tester.getRect(rowFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // No translation at all, regardless of action count.
      expect(tester.getRect(rowFinder), equals(restRect));

      final deleteRect = tester.getRect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Delete").first,
      );
      expect(deleteRect.right, lessThanOrEqualTo(stackRect.right + 0.5));
      expect(deleteRect.left, greaterThanOrEqualTo(stackRect.left - 0.5));

      controller.dispose();
    });

    testWidgets("mobile swipe extent still scales with action count (2 actions)", (tester) async {
      final controller = LayrzScaffoldController();
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kCompactSize);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      await tester.drag(rowFinder, const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final revealedRect = tester.getRect(rowFinder);
      final translated = restRect.left - revealedRect.left;
      expect(translated, closeTo(expectedRevealExtent(2), 0.5));

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — selected row takes the plain no-reveal path", () {
    testWidgets("wide viewport: a selected row with actions does not reveal them on hover", (tester) async {
      final controller = LayrzScaffoldController(initialOpenedKey: const ValueKey("1"));
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
        LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
      ]);

      await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

      // Selected takes the plain _buildTappable path: no action-reveal machinery
      // (Stack/ClipRRect translation) and the action buttons are not in the tree.
      expect(find.byType(LayrzButton), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);

      final rowFinder = find.byType(LayrzTappable);
      final restRect = tester.getRect(rowFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(rowFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Hovering a selected row must not translate it — no reveal ever happens.
      expect(tester.getRect(rowFinder), equals(restRect));

      controller.dispose();
    });

    testWidgets("compact viewport: a selected row with actions renders the plain no-reveal structure", (
      tester,
    ) async {
      // A compact viewport with an item already opened at mount immediately schedules
      // the detail sheet, which needs a root Navigator (see scaffold_shell.dart) and
      // then occludes the underlying list row by design — so this asserts the row's
      // own (pre-sheet) structure takes the plain path, rather than attempting a
      // swipe gesture against a row a real sheet would already cover.
      //
      // `initialOpenedKey` alone leaves `openedBuilder` null, which the shell now
      // treats as "nothing to show" and closes on sight — so `open` is called with a
      // real builder up front, before the first pump, to keep the detail genuinely
      // open exactly as `initialOpenedKey` alone used to.
      final controller = LayrzScaffoldController(initialOpenedKey: const ValueKey("1"))
        ..open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      final items = _itemsWithActions([
        LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
      ]);

      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = _kCompactSize;

      await _pumpThemedWithNavigator(
        tester,
        SizedBox.expand(
          child: LayrzScaffoldShell<_TestItem>(
            controller: controller,
            items: items,
            itemExtent: 56.0,
          ),
        ),
      );

      // No action-reveal machinery (Fab buttons, translation ClipRRect) is present
      // for the selected row — it took the plain _buildTappable() no-reveal path.
      expect(find.byType(LayrzButton), findsNothing);

      controller.dispose();
    });
  });

  group("LayrzScaffoldItem.actions — accessibility", () {
    testWidgets("revealed action buttons expose real button semantics", (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = LayrzScaffoldController();
        final items = _itemsWithActions([
          LayrzButton.edit(labelText: "Edit", onTap: () {}, isFab: true),
          LayrzButton.delete(labelText: "Delete", onTap: () {}, isFab: true),
        ]);

        await _pumpShell(tester, items: items, controller: controller, size: _kWideSize);

        // Reveal the actions via hover — occluded (untranslated) actions are not
        // real tap targets, so semantics must be asserted only once genuinely reachable.
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: tester.getCenter(find.byType(LayrzTappable)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // LayrzButton's own Semantics node does not expose a `tap` action (it
        // relies on `excludeSemantics` over its internal GestureDetector without
        // forwarding an onTap to the Semantics widget itself — a pre-existing,
        // library-wide trait of every LayrzButton, not specific to this reveal),
        // so `isButton`/`isEnabled`/`label` are what a real, revealed action
        // button asserts here.
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Edit").first),
          matchesSemantics(
            label: "Edit",
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );
        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Delete").first),
          matchesSemantics(
            label: "Delete",
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );

        controller.dispose();
      } finally {
        handle.dispose();
      }
    });
  });
}

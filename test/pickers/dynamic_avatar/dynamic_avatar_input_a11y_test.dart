import 'package:emojis/emoji.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/pickers/src/dynamic_avatar/dynamic_avatar_tile.dart';
import 'package:layrz_ui/src/pickers/src/dynamic_avatar/dynamic_avatar_input.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `emoji_input_a11y_test.dart`'s own helper — walking the tree
/// instead of using `find.bySemanticsLabel`, which also matches literal
/// text on renderable widgets and has already produced a false green in
/// this repo.
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

void main() {
  group('LayrzDynamicAvatarInput — Accessibility', () {
    guardedTestWidgets('the anchor exposes the label as a button, enabled and focusable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Avatar') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Avatar',
            isButton: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled anchor is marked not enabled and reports no tap action', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', disabled: true));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Avatar') ?? false),
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Avatar',
            isButton: true,
            hasEnabledState: true,
            hasTapAction: false,
            hasFocusAction: false,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the label is exposed to screen readers exactly once', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Profile picture'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.where((l) => l == 'Profile picture').length, 1);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an emoji cell in the open desktop surface exposes its shortName as a semantics label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

        await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Emoji'));
        await tester.pumpAndSettle();

        final target = Emoji.byShortName('grinning')!;
        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains(target.shortName));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an icon cell in the open desktop surface exposes its stable name as a semantics label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

        await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Icon'));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.startsWith('mdi-')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the closed tile exposes its own clear badge as a button', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
        );

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Remove avatar',
        );
        expect(finder, findsOneWidget);

        expect(
          tester.getSemantics(finder),
          matchesSemantics(
            label: 'Remove avatar',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('the surface None/clear affordance is exposed as a button, alongside the tile\'s own badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(labelText: 'Avatar', value: const LayrzAvatarEmoji('😀')),
        );

        await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
        await tester.pumpAndSettle();

        // Two "Remove avatar" nodes are now present: the closed tile's own
        // clear badge (rendered underneath the open surface, its tap merged
        // into a descendant node since it wraps itself in
        // `Semantics(excludeSemantics: true)`) and the surface's own
        // None/clear affordance (whose own node directly carries the tap
        // action) -- both are independently valid buttons, so this asserts
        // on the pair rather than requiring exactly one.
        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Remove avatar',
        );
        expect(finder, findsNWidgets(2));

        final nodes = finder
            .evaluate()
            .map((e) => tester.getSemantics(find.byElementPredicate((x) => x == e)))
            .toList();
        for (final node in nodes) {
          final data = node.getSemanticsData();
          expect(data.label, 'Remove avatar');
          expect(data.flagsCollection.isButton, isTrue);
        }
        // At least the surface's own affordance carries a direct tap action.
        expect(nodes.any((n) => n.getSemanticsData().hasAction(SemanticsAction.tap)), isTrue);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('remains accessible at a compact (mobile) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar'));

        final finder = find.byWidgetPredicate(
          (widget) => widget is Semantics && (widget.properties.label?.contains('Avatar') ?? false),
        );
        expect(finder, findsWidgets);

        await tester.tap(find.byType(LayrzDynamicAvatarTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Emoji'));
        await tester.pumpAndSettle();

        final target = Emoji.byShortName('grinning')!;
        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains(target.shortName));
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzDynamicAvatarInput accessibility — keyboard reachability', () {
    guardedTestWidgets('the empty tile is reachable and activatable via a FocusableActionDetector', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // `pumpThemedApp`'s `LayrzApp` provides the `WidgetsApp`/`Shortcuts`
      // binding for the default Enter->ActivateIntent mapping
      // `FocusableActionDetector` relies on -- mirrors
      // `image_input_a11y_test.dart`'s identical setup for this same trap.
      await pumpThemedApp(tester, LayrzDynamicAvatarInput(labelText: 'Avatar', focusNode: focusNode));
      await tester.pump();

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // The Enter key opened the picker surface -- its tab labels are now on
      // screen, proving the FocusableActionDetector's ActivateIntent handler
      // fired.
      expect(find.text('URL'), findsOneWidget);
    });

    guardedTestWidgets('the clear badge is reachable and activatable via a FocusableActionDetector', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        LayrzAvatarSource? changed = const LayrzAvatarEmoji('😀');
        await pumpThemedApp(
          tester,
          LayrzDynamicAvatarInput(
            labelText: 'Avatar',
            value: const LayrzAvatarEmoji('😀'),
            onChanged: (c) => changed = c,
          ),
        );
        await tester.pump();

        final clearFocusable = tester.widget<FocusableActionDetector>(
          find.descendant(
            of: find.bySemanticsLabel('Remove avatar'),
            matching: find.byType(FocusableActionDetector),
          ),
        );
        final activate = clearFocusable.actions![ActivateIntent] as CallbackAction<ActivateIntent>;
        activate.invoke(const ActivateIntent());
        await tester.pump();

        expect(changed, isNull);
      } finally {
        handle.dispose();
      }
    });
  });
}

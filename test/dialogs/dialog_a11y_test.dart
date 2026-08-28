import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzDialog accessibility', () {
    testWidgets('the barrier label is announced from context.l10n, not hardcoded', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Body'));
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final l10nBarrierLabel = LayrzUiL10n.of(
        tester.element(find.text('Open')),
      ).dialogsBarrierLabel;
      expect(l10nBarrierLabel, isNotEmpty);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // RawDialogRoute (via ModalRoute.buildModalBarrier) inserts its own
      // ModalBarrier as a SEPARATE OverlayEntry beneath the route's own
      // page/transitionBuilder content -- it is not a widget _DialogRoute
      // constructs itself, so it must be found by walking the raw semantics
      // tree for its label, the same technique
      // test/sheets/bottom_sheet_a11y_test.dart uses for the sheet's own
      // semanticLabel. This proves barrierLabel actually reaches the
      // accessibility tree with the l10n string, not a hardcoded one.
      // ignore: deprecated_member_use
      final semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
      final rootNode = semanticsOwner?.rootSemanticsNode;

      SemanticsNode? targetNode;
      void findLabelNode(SemanticsNode node) {
        if (targetNode != null) return;
        if (node.label == l10nBarrierLabel) {
          targetNode = node;
          return;
        }
        node.visitChildren((child) {
          findLabelNode(child);
          return true;
        });
      }

      if (rootNode != null) {
        findLabelNode(rootNode);
      }

      expect(
        targetNode,
        isNotNull,
        reason: 'the barrier must expose context.l10n.dialogsBarrierLabel as its semantics label',
      );

      handle.dispose();
    });

    testWidgets('a supplied semanticLabel scopes and names the dialog route', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(
                    context,
                    content: const Text('Body'),
                    semanticLabel: 'Choose an option',
                  );
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final semanticsWidget = tester.widget<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Choose an option'),
      );
      expect(semanticsWidget.properties.scopesRoute, isTrue);
      expect(semanticsWidget.properties.namesRoute, isTrue);

      handle.dispose();
    });

    testWidgets('omitting semanticLabel adds no route-naming Semantics wrap', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Body'));
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final namedRouteSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.scopesRoute == true && widget.properties.namesRoute == true,
      );
      expect(
        namedRouteSemantics,
        findsNothing,
        reason: 'no semanticLabel means no dialog-specific route-naming Semantics wrap should exist',
      );
    });

    testWidgets('focus moves into the dialog on open', (tester) async {
      final invokerFocusNode = FocusNode(debugLabel: 'invoker');
      addTearDown(invokerFocusNode.dispose);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => Focus(
                focusNode: invokerFocusNode,
                child: GestureDetector(
                  onTap: () {
                    invokerFocusNode.requestFocus();
                    LayrzDialog.show<void>(context, content: const Text('Body'));
                  },
                  child: const SizedBox(width: 100, height: 100, child: Text('Open')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        invokerFocusNode.hasFocus,
        isFalse,
        reason: 'the invoker must lose focus once the dialog traps it',
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        equals('LayrzDialog'),
        reason: 'the dialog must claim focus with its own FocusNode when it opens',
      );
    });

    testWidgets('focus is restored to the invoker when the dialog closes', (tester) async {
      final invokerFocusNode = FocusNode(debugLabel: 'invoker');
      addTearDown(invokerFocusNode.dispose);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => Focus(
                focusNode: invokerFocusNode,
                child: GestureDetector(
                  onTap: () {
                    invokerFocusNode.requestFocus();
                    LayrzDialog.show<void>(context, content: const Text('Body'));
                  },
                  child: const SizedBox(width: 100, height: 100, child: Text('Open')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(invokerFocusNode.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        invokerFocusNode.hasFocus,
        isTrue,
        reason: 'closing the dialog must restore focus to whatever held it before the dialog opened',
      );
    });

    testWidgets('Escape dismisses the dialog', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Dismiss me'));
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss me'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Dismiss me'), findsNothing);
    });

    testWidgets('Escape does nothing once the dialog is already closed (no stray pop)', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  LayrzDialog.show<void>(context, content: const Text('Body'));
                },
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(find.text('Open'), findsOneWidget);

      // A second Escape after the dialog is already gone must not throw or
      // pop the page underneath -- there is nothing left for the dialog's
      // own Focus/onKeyEvent to intercept since it has been disposed.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}

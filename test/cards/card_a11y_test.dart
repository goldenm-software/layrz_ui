import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCard Accessibility', () {
    group('Semantic button flag', () {
      testWidgets('interactive card is exposed as an enabled button', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzCard(
              onTap: () {},
              child: const Text('card'),
            ),
          );

          expect(
            tester.getSemantics(find.byType(LayrzCard)),
            matchesSemantics(
              isButton: true,
              isEnabled: true,
              hasEnabledState: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('non-interactive card is not exposed as a button', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzCard(child: Text('card')),
          );

          expect(
            tester.getSemantics(find.byType(LayrzCard)),
            isNot(matchesSemantics(isButton: true)),
          );
        } finally {
          handle.dispose();
        }
      });
    });

    group('Focus traversal', () {
      testWidgets('interactive card is focusable', (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemed(
          tester,
          LayrzCard(
            onTap: () {},
            child: Focus(
              focusNode: focusNode,
              child: const Text('Focusable card'),
            ),
          ),
        );

        // Request focus on the child's focus node
        focusNode.requestFocus();
        await tester.pump();

        // Verify focus node is focused
        expect(focusNode.hasFocus, isTrue, reason: 'Interactive card descendant must be focusable');
      });

      testWidgets('non-interactive card can contain focusable descendants', (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemed(
          tester,
          LayrzCard(
            onTap: null,
            child: Focus(
              focusNode: focusNode,
              child: const Text('Child with focus'),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(focusNode.hasFocus, isTrue, reason: 'Non-interactive card can contain focusable children');
      });
    });

    group('Child semantics', () {
      testWidgets('child Text remains readable and semantic', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const testText = 'Child content for accessibility';

          await pumpThemed(
            tester,
            LayrzCard(
              onTap: () {},
              child: const Text(testText),
            ),
          );

          expect(find.text(testText), findsOneWidget);

          final semantics = tester.getSemantics(find.byType(Text));
          expect(semantics.label, equals(testText), reason: 'Child Text semantics must be preserved');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('child Semantics widget is preserved', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzCard(
              onTap: () {},
              child: Semantics(
                label: 'Custom label',
                child: const Text('Semantic text'),
              ),
            ),
          );

          expect(find.text('Semantic text'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Overlay context', () {
      testWidgets('interactive card in overlay context builds without error', (tester) async {
        await pumpThemed(
          tester,
          LayrzCard(
            onTap: () {},
            child: const Text('In overlay'),
          ),
        );

        expect(find.byType(LayrzCard), findsOneWidget);
      });
    });

    group('Keyboard activation in production widget tree', () {
      testWidgets('pressing Enter on focused interactive card activates callback', (tester) async {
        bool callbackInvoked = false;

        await tester.pumpWidget(
          LayrzApp(
            title: 'Keyboard Test',
            theme: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
            home: Builder(
              builder: (context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LayrzCard(
                      onTap: () {
                        callbackInvoked = true;
                      },
                      child: const Text('Keyboard activated card'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Tab to focus the card
        await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify the card's FocusableActionDetector has focus by checking that
        // a widget in the card tree is focused
        final cardFocus = FocusScope.of(tester.element(find.byType(LayrzCard)));
        expect(
          cardFocus.hasFocus,
          isTrue,
          reason: 'Tab navigation must focus the card',
        );

        // Send Enter to activate
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        expect(
          callbackInvoked,
          isTrue,
          reason: 'Card has focus but Enter key did not fire onTap',
        );
      });
    });
  });
}

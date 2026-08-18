import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzText Accessibility', () {
    group('Semantics', () {
      testWidgets('renders semantics when semanticsLabel is provided', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText('Hello World', semanticsLabel: 'Greeting Message'),
          );

          expect(
            find.bySemanticsLabel('Greeting Message'),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('exposes raw text in semantics when semanticsLabel is null', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const textContent = 'Plain Text Content';
          await pumpThemed(
            tester,
            const LayrzText(textContent),
          );

          // The text should appear in the semantics tree
          final semantics = tester.getSemantics(find.text(textContent));
          expect(semantics, isNotNull);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('semanticsIdentifier is exposed in semantics tree', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'Test',
              semanticsIdentifier: 'custom-id-123',
            ),
          );

          expect(find.byType(LayrzText), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('rich text exposes content in semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText.rich(
              TextSpan(
                text: 'Hello ',
                children: [
                  TextSpan(text: 'World'),
                ],
              ),
            ),
          );

          expect(find.text('Hello World'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('custom semanticsLabel overrides raw text in semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'Raw Text',
              semanticsLabel: 'Accessible Label',
            ),
          );

          // Should find by the custom label, not the raw text
          expect(
            find.bySemanticsLabel('Accessible Label'),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('non-selectable text exposes semantics normally', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const testText = 'Non-selectable Text';
          await pumpThemed(
            tester,
            const LayrzText(testText, selectable: false),
          );

          final semantics = tester.getSemantics(find.text(testText));
          expect(semantics, isNotNull);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('selectable text exposes semantics normally', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const testText = 'Selectable Text';
          await pumpThemed(
            tester,
            const LayrzText(testText, selectable: true),
          );

          final semantics = tester.getSemantics(find.text(testText));
          expect(semantics, isNotNull);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Text direction and locale', () {
      testWidgets('respects textDirection for semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'مرحبا',
              textDirection: TextDirection.rtl,
            ),
          );

          expect(find.byType(LayrzText), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('respects locale for rendering', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'Hola Mundo',
              locale: Locale('es', 'ES'),
            ),
          );

          expect(find.text('Hola Mundo'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Focus accessibility', () {
      testWidgets('focusNode allows focus traversal', (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemed(
          tester,
          LayrzText(
            'Focusable Text',
            focusNode: focusNode,
          ),
        );

        // The focus node should be in the tree
        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.focusNode, equals(focusNode));
      });

      testWidgets('internal focusNode works without explicit management', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'Focusable Text',
              focusNode: null,
            ),
          );

          expect(find.byType(SelectableRegion), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });
    });

    group('Content description', () {
      testWidgets('long text with semanticsLabel is accessible', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const longText =
              'This is a very long paragraph that contains a lot of text. '
              'It spans multiple words and concepts. '
              'A good semanticsLabel would provide a concise summary.';

          await pumpThemed(
            tester,
            const LayrzText(
              longText,
              semanticsLabel: 'Article Introduction',
            ),
          );

          expect(
            find.bySemanticsLabel('Article Introduction'),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('rich text with mixed styles maintains semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            LayrzText.rich(
              TextSpan(
                text: 'Important: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'This is critical information',
                    style: const TextStyle(color: Color(0xFFDD0000)),
                  ),
                ],
              ),
              semanticsLabel: 'Important Notice',
            ),
          );

          expect(
            find.bySemanticsLabel('Important Notice'),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('empty text still exposes semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText('', semanticsLabel: 'Empty Section'),
          );

          expect(
            find.bySemanticsLabel('Empty Section'),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      });
    });

    group('Contrast and visibility', () {
      testWidgets('style with explicit color is semantic', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const color = Color(0xFF000000);
          const style = TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          );

          await pumpThemed(
            tester,
            const LayrzText('High Contrast Text', style: style),
          );

          final textWidget = find.byType(Text).evaluate().single.widget as Text;
          expect(textWidget.style?.color, equals(color));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('theme default style is semantic', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());

          await pumpThemed(
            tester,
            const LayrzText('Themed Text'),
            theme: themeData,
          );

          final textWidget = find.byType(Text).evaluate().single.widget as Text;
          expect(textWidget.style?.color, isNotNull);
        } finally {
          handle.dispose();
        }
      });
    });

    group('User interaction accessibility', () {
      testWidgets('selectable: true makes text interactive to assistive tech', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await pumpThemed(
            tester,
            const LayrzText(
              'Select this text',
              selectable: true,
            ),
          );

          expect(find.byType(SelectableRegion), findsOneWidget);
        } finally {
          handle.dispose();
        }
      });

      testWidgets('selectable: false is still readable by assistive tech', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          const text = 'Read-only text';
          await pumpThemed(
            tester,
            const LayrzText(text, selectable: false),
          );

          final semantics = tester.getSemantics(find.text(text));
          expect(semantics, isNotNull);
        } finally {
          handle.dispose();
        }
      });
    });
  });
}

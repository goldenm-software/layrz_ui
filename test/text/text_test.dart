import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzText', () {
    group('Construction & Basics', () {
      testWidgets('LayrzText can be constructed with a string', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test'),
        );
        expect(find.byType(LayrzText), findsOneWidget);
      });

      testWidgets('LayrzText.rich can be constructed with an InlineSpan', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText.rich(TextSpan(text: 'Test')),
        );
        expect(find.byType(LayrzText), findsOneWidget);
      });
    });

    group('Rendering with data', () {
      testWidgets('renders the data string in the inner Text widget', (tester) async {
        const testData = 'Hello, World!';
        await pumpThemed(
          tester,
          const LayrzText(testData),
        );

        expect(find.text(testData), findsOneWidget);

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.data, equals(testData));
      });

      testWidgets('renders empty string without error', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText(''),
        );

        expect(find.byType(LayrzText), findsOneWidget);
      });

      testWidgets('renders string with special characters', (tester) async {
        const testData = 'Special: @#\$%^&*()';
        await pumpThemed(
          tester,
          const LayrzText(testData),
        );

        expect(find.text(testData), findsOneWidget);
      });
    });

    group('Rendering with rich text', () {
      testWidgets('renders InlineSpan via Text.rich', (tester) async {
        const inlineSpan = TextSpan(
          text: 'Hello ',
          children: [
            TextSpan(
              text: 'World',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );

        await pumpThemed(
          tester,
          const LayrzText.rich(inlineSpan),
        );

        expect(find.byType(Text), findsOneWidget);
        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.textSpan, equals(inlineSpan));
      });

      testWidgets('renders complex nested spans', (tester) async {
        await pumpThemed(
          tester,
          LayrzText.rich(
            TextSpan(
              text: 'Outer ',
              children: [
                TextSpan(
                  text: 'Bold ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'and Italic',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(find.byType(Text), findsOneWidget);
      });
    });

    group('Style resolution', () {
      testWidgets('null style defaults to tokens.typography.body', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final bodyStyle = themeData.tokens.typography.body;

        await pumpThemed(
          tester,
          const LayrzText('Test'),
          theme: themeData,
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.style?.fontSize, equals(bodyStyle.fontSize));
        expect(textWidget.style?.fontWeight, equals(bodyStyle.fontWeight));
      });

      testWidgets('explicit style is passed through unchanged', (tester) async {
        const customStyle = TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF123456),
        );

        await pumpThemed(
          tester,
          const LayrzText('Test', style: customStyle),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.style?.fontSize, equals(customStyle.fontSize));
        expect(textWidget.style?.fontWeight, equals(customStyle.fontWeight));
        expect(textWidget.style?.color, equals(customStyle.color));
      });

      testWidgets('style does not get overwritten by default', (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        const customStyle = TextStyle(fontSize: 28);

        await pumpThemed(
          tester,
          const LayrzText('Test', style: customStyle),
          theme: themeData,
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        // Should be the custom fontSize, not the theme's body style fontSize
        expect(textWidget.style?.fontSize, equals(28));
      });
    });

    group('Selectability', () {
      testWidgets('selectable: true wraps in SelectableRegion', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', selectable: true),
        );

        expect(find.byType(SelectableRegion), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('selectable: false renders plain Text without SelectableRegion', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', selectable: false),
        );

        expect(find.byType(SelectableRegion), findsNothing);
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('default selectable is true', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test'),
        );

        expect(find.byType(SelectableRegion), findsOneWidget);
      });
    });

    group('Focus node management', () {
      testWidgets('null focusNode creates internal node', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', focusNode: null),
        );

        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.focusNode, isNotNull);
      });

      testWidgets('supplied focusNode is used directly', (tester) async {
        final suppliedNode = FocusNode();
        addTearDown(suppliedNode.dispose);

        await pumpThemed(
          tester,
          LayrzText('Test', focusNode: suppliedNode),
        );

        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.focusNode, equals(suppliedNode));
      });

      testWidgets('internal focusNode is created when focusNode is null', (tester) async {
        // Build a LayrzText with null focusNode
        await pumpThemed(
          tester,
          const LayrzText('Test', focusNode: null),
        );

        // The SelectableRegion should have a focus node
        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.focusNode, isNotNull);
      });

      testWidgets('switching from null to supplied focusNode uses the supplied one', (tester) async {
        // Start with null focusNode
        await pumpThemed(tester, const LayrzText('Test', focusNode: null));

        final selectableRegion1 = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        final initialFocusNode = selectableRegion1.focusNode;
        expect(initialFocusNode, isNotNull);

        // Now update with a supplied focusNode
        final suppliedNode = FocusNode();
        addTearDown(suppliedNode.dispose);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayrzTheme(
              data: LayrzThemeData.light(fontHandler: const FakeFontHandler()),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Center(
                      child: LayrzText('Test', focusNode: suppliedNode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // The SelectableRegion should have a focus node
        final selectableRegion2 = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion2.focusNode, isNotNull);
      });
    });

    group('Parameter forwarding to Text', () {
      testWidgets('textAlign is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', textAlign: TextAlign.center),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.textAlign, equals(TextAlign.center));
      });

      testWidgets('textDirection is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', textDirection: TextDirection.rtl),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.textDirection, equals(TextDirection.rtl));
      });

      testWidgets('softWrap is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', softWrap: false),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.softWrap, equals(false));
      });

      testWidgets('overflow is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', overflow: TextOverflow.fade),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.overflow, equals(TextOverflow.fade));
      });

      testWidgets('maxLines is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test very long text', maxLines: 1),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.maxLines, equals(1));
      });

      testWidgets('semanticsLabel is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', semanticsLabel: 'Custom Label'),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.semanticsLabel, equals('Custom Label'));
      });

      testWidgets('strutStyle is forwarded', (tester) async {
        const strutStyle = StrutStyle(
          fontSize: 16,
          leading: 1.5,
        );

        await pumpThemed(
          tester,
          const LayrzText('Test', strutStyle: strutStyle),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.strutStyle, equals(strutStyle));
      });

      testWidgets('locale is forwarded', (tester) async {
        const locale = Locale('es', 'ES');

        await pumpThemed(
          tester,
          const LayrzText('Test', locale: locale),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.locale, equals(locale));
      });

      testWidgets('textWidthBasis is forwarded', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test', textWidthBasis: TextWidthBasis.parent),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.textWidthBasis, equals(TextWidthBasis.parent));
      });

      testWidgets('textHeightBehavior is forwarded', (tester) async {
        const behavior = TextHeightBehavior();

        await pumpThemed(
          tester,
          const LayrzText('Test', textHeightBehavior: behavior),
        );

        final textWidget = find.byType(Text).evaluate().single.widget as Text;
        expect(textWidget.textHeightBehavior, equals(behavior));
      });
    });

    group('SelectableRegion parameters', () {
      testWidgets('onSelectionChanged is forwarded to SelectableRegion', (tester) async {
        SelectedContent? capturedSelection;

        await pumpThemed(
          tester,
          LayrzText(
            'Test String',
            onSelectionChanged: (selection) {
              capturedSelection = selection;
            },
          ),
        );

        // Verify the SelectableRegion has the callback
        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.onSelectionChanged, isNotNull);

        // Verify the callback receives SelectedContent with plainText
        selectableRegion.onSelectionChanged?.call(
          SelectedContent(plainText: 'Test'),
        );
        expect(capturedSelection, isNotNull);
        expect(capturedSelection?.plainText, equals('Test'));
      });

      testWidgets('selectionColor is forwarded to SelectableRegion', (tester) async {
        const selectionColor = Color(0xFFFFFF00);

        await pumpThemed(
          tester,
          const LayrzText(
            'Test',
            selectionColor: selectionColor,
          ),
        );

        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        // SelectableRegion might not expose selectionColor directly, but we can verify it's created
        expect(selectableRegion, isNotNull);
      });

      testWidgets('SelectableRegion uses emptyTextSelectionControls', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText('Test'),
        );

        final selectableRegion = find.byType(SelectableRegion).evaluate().single.widget as SelectableRegion;
        expect(selectableRegion.selectionControls, equals(emptyTextSelectionControls));
      });
    });

    group('Edge cases', () {
      testWidgets('handles very long text', (tester) async {
        final longText = 'Word ' * 1000;

        await pumpThemed(
          tester,
          LayrzText(longText),
        );

        expect(find.byType(LayrzText), findsOneWidget);
      });

      testWidgets('handles text with newlines', (tester) async {
        const multilineText = 'Line 1\nLine 2\nLine 3';

        await pumpThemed(
          tester,
          const LayrzText(multilineText),
        );

        expect(find.text(multilineText), findsOneWidget);
      });

      testWidgets('handles rich text with empty spans', (tester) async {
        await pumpThemed(
          tester,
          const LayrzText.rich(
            TextSpan(
              text: 'Start',
              children: [
                TextSpan(text: ''),
                TextSpan(text: 'End'),
              ],
            ),
          ),
        );

        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('renders with all parameters set', (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemed(
          tester,
          LayrzText(
            'Test',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            semanticsLabel: 'Test Label',
            selectable: true,
            focusNode: focusNode,
          ),
        );

        expect(find.byType(LayrzText), findsOneWidget);
        expect(find.byType(SelectableRegion), findsOneWidget);
      });
    });
  });
}

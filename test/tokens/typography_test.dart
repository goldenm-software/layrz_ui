import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTextTheme', () {
    test('defaults factory applies textColor to all styles', () {
      const testColor = Color(0xFF123456);
      final theme = LayrzTextTheme.defaults(textColor: testColor);

      expect(theme.display.color, equals(testColor));
      expect(theme.headline.color, equals(testColor));
      expect(theme.title.color, equals(testColor));
      expect(theme.body.color, equals(testColor));
      expect(theme.label.color, equals(testColor));
    });

    test('defaults factory uses correct font sizes', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.fontSize, equals(30));
      expect(theme.headline.fontSize, equals(24));
      expect(theme.title.fontSize, equals(18));
      expect(theme.body.fontSize, equals(14));
      expect(theme.label.fontSize, equals(12));
    });

    test('defaults factory uses correct font weights', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.fontWeight, equals(FontWeight.w700));
      expect(theme.headline.fontWeight, equals(FontWeight.w600));
      expect(theme.title.fontWeight, equals(FontWeight.w600));
      expect(theme.body.fontWeight, equals(FontWeight.w400));
      expect(theme.label.fontWeight, equals(FontWeight.w400));
    });

    test('defaults factory with null font uses LayrzRobotoFont', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.fontFamily, equals('Roboto'));
      expect(theme.body.fontFamily, equals('Roboto'));
    });

    test('no style carries an overflow — text wraps by default', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.overflow, isNull);
      expect(theme.headline.overflow, isNull);
      expect(theme.title.overflow, isNull);
      expect(theme.body.overflow, isNull);
      expect(theme.label.overflow, isNull);
    });

    test('all styles have no text decoration', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.decoration, equals(TextDecoration.none));
      expect(theme.body.decoration, equals(TextDecoration.none));
      expect(theme.label.decoration, equals(TextDecoration.none));
    });

    test('copyWith creates new instance with replaced styles', () {
      final original = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final newBody = original.body.copyWith(fontSize: 20);
      final modified = original.copyWith(body: newBody);

      expect(modified.body.fontSize, equals(20));
      expect(modified.display, equals(original.display));
      expect(original.body.fontSize, equals(14)); // original unchanged
    });

    test('equality works for identical factories', () {
      final theme1 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final theme2 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      expect(theme1, equals(theme2));
    });

    test('equality works for copyWith with same values', () {
      final original = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different colors', () {
      final theme1 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final theme2 = LayrzTextTheme.defaults(textColor: const Color(0xFFFFFFFF));
      expect(theme1, isNot(equals(theme2)));
    });

    test('hashCode is stable for same values', () {
      final theme1 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final theme2 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('hashCode differs for different colors', () {
      final theme1 = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));
      final theme2 = LayrzTextTheme.defaults(textColor: const Color(0xFFFFFFFF));
      expect(theme1.hashCode, isNot(equals(theme2.hashCode)));
    });

    test('font sizes are monotonically increasing from label to display', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      final labelSize = theme.label.fontSize ?? 0;
      final bodySize = theme.body.fontSize ?? 0;
      final titleSize = theme.title.fontSize ?? 0;
      final headlineSize = theme.headline.fontSize ?? 0;
      final displaySize = theme.display.fontSize ?? 0;

      expect(labelSize, lessThan(bodySize));
      expect(bodySize, lessThan(titleSize));
      expect(titleSize, lessThan(headlineSize));
      expect(headlineSize, lessThanOrEqualTo(displaySize));
    });

    test('Roboto font provides correct weights for each role', () {
      final theme = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
        font: const LayrzRobotoFont(),
      );

      // Roboto has w700/w600/w600/w400/w400
      expect(theme.display.fontWeight, equals(FontWeight.w700));
      expect(theme.headline.fontWeight, equals(FontWeight.w600));
      expect(theme.title.fontWeight, equals(FontWeight.w600));
      expect(theme.body.fontWeight, equals(FontWeight.w400));
      expect(theme.label.fontWeight, equals(FontWeight.w400));
    });

    test('theme applies size and color over font style values', () {
      const testColor = Color(0xFF123456);
      final theme = LayrzTextTheme.defaults(
        textColor: testColor,
        font: const LayrzRobotoFont(),
      );

      // Verify that size and color are overridden from the font style
      expect(theme.display.color, equals(testColor));
      expect(theme.display.fontSize, equals(30));
      expect(theme.headline.color, equals(testColor));
      expect(theme.headline.fontSize, equals(24));
    });

    test('defaults factory triggers registerOnWeb on the provided font', () {
      final font = _SpyFont();
      LayrzTextTheme.defaults(textColor: const Color(0xFF000000), font: font);

      expect(font.registerOnWebCalled, isTrue);
    });

    test('defaults factory does not await registerOnWeb (fire-and-forget)', () {
      final font = _SlowSpyFont();

      // If this were awaited, the factory call itself would need to be inside an
      // async zone; since LayrzTextTheme.defaults is a synchronous factory, calling
      // it here at all proves registerOnWeb's Future is not awaited by the factory.
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000), font: font);

      expect(theme, isA<LayrzTextTheme>());
      expect(font.registerOnWebCalled, isTrue);
      expect(font.registerOnWebCompleted, isFalse);
    });

    test('LayrzRobotoFont (the null-font default) exposes a synchronous no-op registerOnWeb', () {
      // The null-font branch resolves to LayrzRobotoFont, whose inherited
      // registerOnWeb is the base no-op — calling defaults() with no font must not
      // throw or hang despite firing registerOnWeb unawaited.
      expect(
        () => LayrzTextTheme.defaults(textColor: const Color(0xFF000000)),
        returnsNormally,
      );
    });
  });

  group('Text wrapping and truncation', () {
    testWidgets('long text in unbounded width/height wraps to multiple lines', (tester) async {
      const shortText = 'Short';
      const longText =
          'This is a very long text that should wrap to multiple lines '
          'when placed in an unbounded width and height context because '
          'the text theme carries no overflow property anymore.';
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      // Render both short and long text in a single tree to measure baseline and wrapped height
      await pumpThemed(
        tester,
        SizedBox(
          width: 200,
          child: Column(
            children: [
              Text(
                shortText,
                style: theme.body,
              ),
              Text(
                longText,
                style: theme.body,
              ),
            ],
          ),
        ),
      );

      // Get the single-line height from short text
      final shortRenderBox = tester.renderObject<RenderBox>(find.text(shortText));
      final singleLineHeight = shortRenderBox.size.height;

      // Get the wrapped-text height from long text
      final longFinder = find.text(longText);
      expect(longFinder, findsOneWidget);
      final longRenderBox = tester.renderObject<RenderBox>(longFinder);
      final textHeight = longRenderBox.size.height;

      // Verify long text wrapped to multiple lines (height much greater than single line)
      expect(textHeight, greaterThan(singleLineHeight * 1.5));

      // Verify no exceptions in layout
      expect(tester.takeException(), isNull);
    });

    testWidgets('LayrzButton label truncates with ellipsis', (tester) async {
      await pumpThemed(
        tester,
        LayrzButton(
          labelText: 'This is a very long button label that should truncate',
          onTap: () {},
        ),
      );

      // Find the RichText that renders the button label content
      final richTextFinder = find.descendant(
        of: find.byType(LayrzButton),
        matching: find.byType(RichText),
      );
      expect(richTextFinder, findsWidgets);

      // Verify the RichText has ellipsis overflow to prevent text overflow
      final richTextWidget = tester.widget<RichText>(richTextFinder.first);
      expect(richTextWidget.overflow, equals(TextOverflow.ellipsis));
      expect(richTextWidget.maxLines, equals(1));
    });

    testWidgets('LayrzChip label truncates with ellipsis', (tester) async {
      const labelText = 'This is a very long chip label that should truncate';
      await pumpThemed(
        tester,
        LayrzChip(
          labelText: labelText,
        ),
      );

      // Find the Text widget inside the chip that displays the label
      final textFinder = find.descendant(
        of: find.byType(LayrzChip),
        matching: find.text(labelText),
      );
      expect(textFinder, findsOneWidget);

      // Verify the Text widget has maxLines: 1 and ellipsis overflow
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('LayrzAvatar initials render with maxLines and ellipsis', (tester) async {
      await pumpThemed(
        tester,
        const LayrzAvatar(
          nameText: 'Very Long Name With Many Characters',
          size: 48,
        ),
      );

      // Find the Text widget inside the avatar that renders the initials
      final textFinder = find.descendant(
        of: find.byType(LayrzAvatar),
        matching: find.byType(Text),
      );
      // Avatar renders one Text for the initials
      expect(textFinder, findsWidgets);

      // Get the text widget and verify it has maxLines: 1 and ellipsis overflow
      final textWidget = tester.widget<Text>(textFinder.first);
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });
}

/// A minimal [LayrzFont] that records whether [registerOnWeb] was invoked.
///
/// Used to prove [LayrzTextTheme.defaults] calls [LayrzFont.registerOnWeb] on the
/// font it is given, without depending on `package:web` or an actual browser DOM.
class _SpyFont extends LayrzFont {
  _SpyFont() : super(name: 'Spy');

  /// Whether [registerOnWeb] has been invoked on this instance.
  bool registerOnWebCalled = false;

  @override
  Future<void> load() async {}

  @override
  Future<void> registerOnWeb() async {
    registerOnWebCalled = true;
  }

  @override
  TextStyle get display => const TextStyle(fontFamily: 'Spy');

  @override
  TextStyle get headline => const TextStyle(fontFamily: 'Spy');

  @override
  TextStyle get title => const TextStyle(fontFamily: 'Spy');

  @override
  TextStyle get body => const TextStyle(fontFamily: 'Spy');

  @override
  TextStyle get label => const TextStyle(fontFamily: 'Spy');
}

/// A [LayrzFont] whose [registerOnWeb] starts running synchronously (recording that
/// it was called) but only completes on a later microtask.
///
/// Used to prove [LayrzTextTheme.defaults] does not await [LayrzFont.registerOnWeb]:
/// immediately after the factory returns, [registerOnWebCalled] is already true
/// (the call was made) while [registerOnWebCompleted] is still false (the factory
/// did not wait for it to finish).
class _SlowSpyFont extends LayrzFont {
  _SlowSpyFont() : super(name: 'SlowSpy');

  /// Whether [registerOnWeb] has been invoked on this instance.
  bool registerOnWebCalled = false;

  /// Whether the [Future] returned by [registerOnWeb] has completed.
  bool registerOnWebCompleted = false;

  @override
  Future<void> load() async {}

  @override
  Future<void> registerOnWeb() async {
    registerOnWebCalled = true;
    await Future<void>.delayed(Duration.zero);
    registerOnWebCompleted = true;
  }

  @override
  TextStyle get display => const TextStyle(fontFamily: 'SlowSpy');

  @override
  TextStyle get headline => const TextStyle(fontFamily: 'SlowSpy');

  @override
  TextStyle get title => const TextStyle(fontFamily: 'SlowSpy');

  @override
  TextStyle get body => const TextStyle(fontFamily: 'SlowSpy');

  @override
  TextStyle get label => const TextStyle(fontFamily: 'SlowSpy');
}

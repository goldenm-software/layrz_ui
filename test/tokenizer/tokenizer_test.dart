import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/tokens/tokens.dart';
import 'package:layrz_ui/tokenizer/tokenizer.dart';

void main() {
  group('LayrzTokenizer', () {
    test('constructor stores tokens', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.tokens, equals(tokens));
    });

    // ===== GROUP GETTERS =====

    test('colors group getter returns tokens.colors', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.colors, equals(tokens.colors));
    });

    test('typography group getter returns tokens.typography', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.typography, equals(tokens.typography));
    });

    test('spacingTokens group getter returns tokens.spacing', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.spacingTokens, equals(tokens.spacing));
    });

    test('radiusTokens group getter returns tokens.radius', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.radiusTokens, equals(tokens.radius));
    });

    test('shadow group getter returns tokens.shadow', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.shadowTokens, equals(tokens.shadow));
    });

    test('border group getter returns tokens.border', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.border, equals(tokens.border));
    });

    test('motion group getter returns tokens.motion', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.motion, equals(tokens.motion));
    });

    // ===== FLAT COLOR SHORTCUTS =====

    test('primary shortcut returns colors.primary', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.primary, equals(tokens.colors.primary));
      expect(tokenizer.primary, equals(kPrimaryColor));
    });

    test('success shortcut returns colors.success', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.success, equals(tokens.colors.success));
    });

    test('warning shortcut returns colors.warning', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.warning, equals(tokens.colors.warning));
    });

    test('danger shortcut returns colors.danger', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.danger, equals(tokens.colors.danger));
    });

    test('info shortcut returns colors.info', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.info, equals(tokens.colors.info));
    });

    test('contextual shortcut returns colors.contextual', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.contextual, equals(tokens.colors.contextual));
    });

    test('tonalOpacity shortcut returns colors.tonalOpacity', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.tonalOpacity, equals(tokens.colors.tonalOpacity));
      expect(tokenizer.tonalOpacity, equals(0.2));
    });

    // ===== FLAT SPACING SHORTCUTS =====

    test('spacing shortcut returns base spacing value', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.spacing, equals(tokens.spacing.base));
      expect(tokenizer.spacing, equals(8.0));
    });

    test('margin shortcut returns spacing.margin', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.margin, equals(tokens.spacing.margin));
      expect(tokenizer.margin, equals(EdgeInsets.all(8.0)));
    });

    test('reducedMargin shortcut returns spacing.reducedMargin', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.reducedMargin, equals(tokens.spacing.reducedMargin));
      expect(tokenizer.reducedMargin, equals(EdgeInsets.all(4.0)));
    });

    test('padding shortcut returns spacing.padding', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.padding, equals(tokens.spacing.padding));
      expect(tokenizer.padding, equals(EdgeInsets.all(8.0)));
    });

    test('sizedBox shortcut returns spacing.sizedBox', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.sizedBox, isA<Widget>());
    });

    // ===== FLAT RADIUS SHORTCUTS =====

    test('radius shortcut returns base radius value', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.radius, equals(tokens.radius.base));
      expect(tokenizer.radius, equals(8.0));
    });

    test('borderRadius shortcut returns radius.borderRadius', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.borderRadius, equals(tokens.radius.borderRadius));
      expect(tokenizer.borderRadius, equals(BorderRadius.circular(8.0)));
    });

    test('innerRadius shortcut delegates to tokens.radius.innerRadius', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      final result = tokenizer.innerRadius(outerRadius: 12.0, spacer: 4.0);
      final expected = tokens.radius.innerRadius(
        outerRadius: 12.0,
        spacer: 4.0,
      );

      expect(result, equals(expected));
      expect(result, equals(BorderRadius.circular(8.0)));
    });

    // ===== FLAT SHADOW SHORTCUTS =====

    test('shadow shortcut delegates to tokens.shadow.elevation', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      final result = tokenizer.shadow(elevation: 3);
      final expected = tokens.shadow.elevation(elevation: 3);

      expect(result.boxShadow, equals(expected.boxShadow));
      expect(result.borderRadius, equals(expected.borderRadius));
      expect(result.color, equals(expected.color));
    });

    // ===== FLAT BORDER SHORTCUTS =====

    test('borderWidth shortcut returns border.base', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      expect(tokenizer.borderWidth, equals(tokens.border.base));
      expect(tokenizer.borderWidth, equals(1.5));
    });

    // ===== EQUALITY =====

    test('equality works for identical tokenizers', () {
      final tokens = LayrzTokens.light();
      final tok1 = LayrzTokenizer(tokens);
      final tok2 = LayrzTokenizer(tokens);

      expect(tok1, equals(tok2));
    });

    test('hashCode is stable for same tokens', () {
      final tokens = LayrzTokens.light();
      final tok1 = LayrzTokenizer(tokens);
      final tok2 = LayrzTokenizer(tokens);

      expect(tok1.hashCode, equals(tok2.hashCode));
    });

    test('inequality works for different tokens', () {
      final tokens1 = LayrzTokens.light();
      final tokens2 = LayrzTokens.light(primaryColor: const Color(0xFF888888));
      final tok1 = LayrzTokenizer(tokens1);
      final tok2 = LayrzTokenizer(tokens2);

      expect(tok1, isNot(equals(tok2)));
    });

    // ===== INTEGRATION =====

    test('all shortcuts return values from tokens', () {
      final tokens = LayrzTokens.light();
      final tokenizer = LayrzTokenizer(tokens);

      // Color shortcuts
      expect(tokenizer.primary, equals(tokens.colors.primary));
      expect(tokenizer.success, equals(tokens.colors.success));
      expect(tokenizer.tonalOpacity, equals(tokens.colors.tonalOpacity));

      // Spacing shortcuts
      expect(tokenizer.spacing, equals(tokens.spacing.base));
      expect(tokenizer.margin, equals(tokens.spacing.margin));

      // Radius shortcuts
      expect(tokenizer.radius, equals(tokens.radius.base));
      expect(tokenizer.borderRadius, equals(tokens.radius.borderRadius));

      // Border shortcuts
      expect(tokenizer.borderWidth, equals(tokens.border.base));
    });
  });
}

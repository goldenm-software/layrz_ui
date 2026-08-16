import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/theme.dart';

import '../helpers/fake_font_handler.dart';

// ===== CONCRETE TEST EXTENSIONS =====

/// A concrete extension for testing basic registration and retrieval.
class _TestExtensionA extends LayrzThemeExtension<_TestExtensionA> {
  /// A simple string value.
  final String value;

  /// Creates a test extension with the given value.
  const _TestExtensionA({required this.value});

  @override
  _TestExtensionA copyWith({String? value}) {
    return _TestExtensionA(value: value ?? this.value);
  }

  @override
  _TestExtensionA lerp(covariant _TestExtensionA? other, double t) {
    if (other is! _TestExtensionA) {
      return this;
    }
    // For strings, just lerp towards the other value at t=1.0
    if (t < 0.5) {
      return this;
    } else {
      return other;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _TestExtensionA && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// A second concrete extension for testing multiple extensions.
class _TestExtensionB extends LayrzThemeExtension<_TestExtensionB> {
  /// A color value.
  final Color color;

  /// Creates a test extension with the given color.
  const _TestExtensionB({required this.color});

  @override
  _TestExtensionB copyWith({Color? color}) {
    return _TestExtensionB(color: color ?? this.color);
  }

  @override
  _TestExtensionB lerp(covariant _TestExtensionB? other, double t) {
    if (other is! _TestExtensionB) {
      return this;
    }
    return _TestExtensionB(
      color: Color.lerp(color, other.color, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _TestExtensionB && runtimeType == other.runtimeType && color == other.color;

  @override
  int get hashCode => Object.hash(runtimeType, color);
}

void main() {
  group('LayrzThemeExtension', () {
    group('Registration via LayrzThemeData.light()', () {
      test('accepts extensions iterable and registers them', () {
        final extA = _TestExtensionA(value: 'hello');
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        expect(theme.extensions, isNotEmpty);
        expect(theme.extensions.containsKey(_TestExtensionA), isTrue);
      });

      test('registers multiple extensions of different types', () {
        final extA = _TestExtensionA(value: 'test');
        final extB = _TestExtensionB(color: const Color(0xFF123456));
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA, extB],
        );

        expect(theme.extensions.length, equals(2));
        expect(theme.extensions.containsKey(_TestExtensionA), isTrue);
        expect(theme.extensions.containsKey(_TestExtensionB), isTrue);
      });

      test('defaults to empty extensions map when none provided', () {
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        );

        expect(theme.extensions, isEmpty);
      });
    });

    group('extension<T>() accessor', () {
      test('returns registered extension of correct type', () {
        final extA = _TestExtensionA(value: 'test');
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final retrieved = theme.extension<_TestExtensionA>();
        expect(retrieved, same(extA));
        expect(retrieved.value, equals('test'));
      });

      test('asserts with helpful message when extension not found', () {
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        );

        expect(
          () => theme.extension<_TestExtensionA>(),
          throwsAssertionError,
        );
      });

      test('retrieves correct extension when multiple are registered', () {
        final extA = _TestExtensionA(value: 'a');
        final extB = _TestExtensionB(color: const Color(0xFF111111));
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA, extB],
        );

        final retrievedA = theme.extension<_TestExtensionA>();
        final retrievedB = theme.extension<_TestExtensionB>();

        expect(retrievedA, same(extA));
        expect(retrievedB, same(extB));
      });
    });

    group('maybeExtension<T>() accessor', () {
      test('returns registered extension of correct type', () {
        final extA = _TestExtensionA(value: 'test');
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final retrieved = theme.maybeExtension<_TestExtensionA>();
        expect(retrieved, same(extA));
      });

      test('returns null when extension not found', () {
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        );

        final retrieved = theme.maybeExtension<_TestExtensionA>();
        expect(retrieved, isNull);
      });

      test('returns correct extension when multiple are registered', () {
        final extA = _TestExtensionA(value: 'a');
        final extB = _TestExtensionB(color: const Color(0xFF111111));
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA, extB],
        );

        final retrievedA = theme.maybeExtension<_TestExtensionA>();
        final retrievedB = theme.maybeExtension<_TestExtensionB>();

        expect(retrievedA, same(extA));
        expect(retrievedB, same(extB));
      });

      test('returns null for unregistered type when others exist', () {
        final extA = _TestExtensionA(value: 'a');
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final retrievedB = theme.maybeExtension<_TestExtensionB>();
        expect(retrievedB, isNull);
      });
    });

    group('copyWith() with extensions', () {
      test('replaces extensions when provided', () {
        final extA1 = _TestExtensionA(value: 'original');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA1],
        );

        final extA2 = _TestExtensionA(value: 'new');
        final theme2 = theme1.copyWith(extensions: [extA2]);

        expect(theme2.extension<_TestExtensionA>(), same(extA2));
        expect(theme2.extension<_TestExtensionA>().value, equals('new'));
      });

      test('preserves extensions when not provided to copyWith', () {
        final extA = _TestExtensionA(value: 'preserved');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final theme2 = theme1.copyWith();

        expect(theme2.extension<_TestExtensionA>(), same(extA));
      });

      test('clears extensions when empty iterable passed', () {
        final extA = _TestExtensionA(value: 'test');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final theme2 = theme1.copyWith(extensions: const []);

        expect(theme2.extensions, isEmpty);
        expect(() => theme2.extension<_TestExtensionA>(), throwsAssertionError);
      });

      test('replaces multiple extensions', () {
        final extA1 = _TestExtensionA(value: 'a1');
        final extB1 = _TestExtensionB(color: const Color(0xFF111111));
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA1, extB1],
        );

        final extA2 = _TestExtensionA(value: 'a2');
        final extB2 = _TestExtensionB(color: const Color(0xFF222222));
        final theme2 = theme1.copyWith(extensions: [extA2, extB2]);

        expect(theme2.extension<_TestExtensionA>(), same(extA2));
        expect(theme2.extension<_TestExtensionB>(), same(extB2));
      });

      test('preserves tokens and iconTheme when copyWith with extensions', () {
        final extA = _TestExtensionA(value: 'test');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        final theme2 = theme1.copyWith(extensions: const []);

        expect(theme2.tokens, same(theme1.tokens));
        expect(theme2.iconTheme, equals(theme1.iconTheme));
      });
    });

    group('Extension copyWith and lerp methods', () {
      test('extension.copyWith() returns new instance with replaced field', () {
        final ext1 = _TestExtensionA(value: 'original');
        final ext2 = ext1.copyWith(value: 'modified');

        expect(ext2.value, equals('modified'));
        expect(ext1.value, equals('original'));
      });

      test('extension.lerp() at t=0.0 returns this', () {
        final ext1 = _TestExtensionA(value: 'a');
        final ext2 = _TestExtensionA(value: 'b');

        final result = ext1.lerp(ext2, 0.0);

        expect(result.value, equals('a'));
      });

      test('extension.lerp() at t=1.0 returns other', () {
        final ext1 = _TestExtensionA(value: 'a');
        final ext2 = _TestExtensionA(value: 'b');

        final result = ext1.lerp(ext2, 1.0);

        expect(result.value, equals('b'));
      });

      test('extension.lerp() with null other returns this', () {
        final ext = _TestExtensionA(value: 'test');

        final result = ext.lerp(null, 0.5);

        expect(result, same(ext));
      });
    });

    group('Extensions map immutability', () {
      test('extensions map is unmodifiable', () {
        final extA = _TestExtensionA(value: 'test');
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        expect(
          () => theme.extensions[_TestExtensionB] = _TestExtensionB(color: const Color(0xFF111111)),
          throwsUnsupportedError,
        );
      });
    });

    group('Equality and hashCode with extensions', () {
      test('two themes with same extensions are equal', () {
        final extA = _TestExtensionA(value: 'test');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );
        final theme2 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        expect(theme1, equals(theme2));
      });

      test('two themes with different extensions are unequal', () {
        final extA1 = _TestExtensionA(value: 'a');
        final extA2 = _TestExtensionA(value: 'b');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA1],
        );
        final theme2 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA2],
        );

        expect(theme1, isNot(equals(theme2)));
      });

      test('equal extensions have equal hash codes', () {
        final extA = _TestExtensionA(value: 'test');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );
        final theme2 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );

        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('theme with extensions and theme without are unequal', () {
        final extA = _TestExtensionA(value: 'test');
        final theme1 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA],
        );
        final theme2 = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        );

        expect(theme1, isNot(equals(theme2)));
      });
    });

    group('LayrzTheme survives Overlay boundary with extensions', () {
      testWidgets(
        'extension is accessible inside Overlay via InheritedTheme.wrap()',
        (WidgetTester tester) async {
          final extA = _TestExtensionA(value: 'overlay-test');
          final themeData = LayrzThemeData.light(
            fontHandler: const FakeFontHandler(),
            extensions: [extA],
          );
          _TestExtensionA? resolvedInOverlay;

          final widget = LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                return Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (overlayContext) {
                        // Try to resolve the extension inside the overlay entry.
                        resolvedInOverlay = LayrzTheme.maybeOf(overlayContext)?.maybeExtension<_TestExtensionA>();
                        return const SizedBox();
                      },
                    ),
                  ],
                );
              },
            ),
          );

          await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: widget),
          );

          expect(
            resolvedInOverlay,
            isNotNull,
            reason: 'LayrzTheme extensions should survive Overlay boundary via InheritedTheme.wrap()',
          );
          expect(resolvedInOverlay, same(extA));
          expect(resolvedInOverlay!.value, equals('overlay-test'));
        },
      );
    });

    group('Context extension accessors', () {
      testWidgets(
        'context.themeExtension<T>() returns registered extension',
        (WidgetTester tester) async {
          final extA = _TestExtensionA(value: 'context-test');
          final themeData = LayrzThemeData.light(
            fontHandler: const FakeFontHandler(),
            extensions: [extA],
          );
          _TestExtensionA? resolved;

          final widget = LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.themeExtension<_TestExtensionA>();
                return const SizedBox.shrink();
              },
            ),
          );

          await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: widget),
          );

          expect(resolved, same(extA));
          expect(resolved!.value, equals('context-test'));
        },
      );

      testWidgets(
        'context.maybeThemeExtension<T>() returns null when not registered',
        (WidgetTester tester) async {
          final themeData = LayrzThemeData.light(
            fontHandler: const FakeFontHandler(),
          );
          _TestExtensionA? resolved;

          final widget = LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestExtensionA>();
                return const SizedBox.shrink();
              },
            ),
          );

          await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: widget),
          );

          expect(resolved, isNull);
        },
      );

      testWidgets(
        'context.maybeThemeExtension<T>() returns extension when registered',
        (WidgetTester tester) async {
          final extA = _TestExtensionA(value: 'maybe-test');
          final themeData = LayrzThemeData.light(
            fontHandler: const FakeFontHandler(),
            extensions: [extA],
          );
          _TestExtensionA? resolved;

          final widget = LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestExtensionA>();
                return const SizedBox.shrink();
              },
            ),
          );

          await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: widget),
          );

          expect(resolved, same(extA));
        },
      );

      testWidgets(
        'context.themeExtension<T>() works with multiple extensions',
        (WidgetTester tester) async {
          final extA = _TestExtensionA(value: 'a');
          final extB = _TestExtensionB(color: const Color(0xFF123456));
          final themeData = LayrzThemeData.light(
            fontHandler: const FakeFontHandler(),
            extensions: [extA, extB],
          );
          _TestExtensionA? resolvedA;
          _TestExtensionB? resolvedB;

          final widget = LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolvedA = context.themeExtension<_TestExtensionA>();
                resolvedB = context.themeExtension<_TestExtensionB>();
                return const SizedBox.shrink();
              },
            ),
          );

          await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: widget),
          );

          expect(resolvedA, same(extA));
          expect(resolvedB, same(extB));
        },
      );
    });

    group('Extension type key property', () {
      test('extension.type returns the runtime type', () {
        final extA = _TestExtensionA(value: 'test');
        final extB = _TestExtensionB(color: const Color(0xFF111111));

        expect(extA.type, equals(_TestExtensionA));
        expect(extB.type, equals(_TestExtensionB));
      });

      test('extensions map is keyed by type', () {
        final extA = _TestExtensionA(value: 'test');
        final extB = _TestExtensionB(color: const Color(0xFF111111));
        final theme = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [extA, extB],
        );

        expect(theme.extensions[extA.type], same(extA));
        expect(theme.extensions[extB.type], same(extB));
      });
    });
  });
}

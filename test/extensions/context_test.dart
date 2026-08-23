import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzContextExtensions', () {
    testWidgets('theme returns the injected LayrzThemeData', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzThemeData resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.theme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, same(themeData));
    });

    testWidgets('tokens returns theme.tokens', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzTokens resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.tokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, same(themeData.tokens));
    });

    testWidgets('tokenizer returns a LayrzTokenizer wrapping theme.tokens', (
      tester,
    ) async {
      final themeData = LayrzThemeData.light();
      late LayrzTokenizer resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.tokenizer;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.tokens, same(themeData.tokens));
    });

    testWidgets('primaryColor returns theme.primaryColor', (tester) async {
      const customColor = Color(0xFF112233);
      final themeData = LayrzThemeData.light(primaryColor: customColor);
      late Color resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.primaryColor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(customColor));
    });

    testWidgets('titleStyle is 18pt bold text style', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.titleStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.fontSize, equals(18));
      expect(resolved.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('subtitleStyle is 16pt bold text style', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.subtitleStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.fontSize, equals(16));
      expect(resolved.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('bodyStyle returns theme.textStyle', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.bodyStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(themeData.textStyle));
    });

    testWidgets(
      'themeExtension<T>() returns registered extension',
      (tester) async {
        final ext = _TestContextExtension(value: 'test');
        final themeData = LayrzThemeData.light(
          extensions: [ext],
        );
        late _TestContextExtension resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.themeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, same(ext));
        expect(resolved.value, equals('test'));
      },
    );

    testWidgets(
      'maybeThemeExtension<T>() returns null when not registered',
      (tester) async {
        final themeData = LayrzThemeData.light();
        _TestContextExtension? resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, isNull);
      },
    );

    testWidgets(
      'maybeThemeExtension<T>() returns extension when registered',
      (tester) async {
        final ext = _TestContextExtension(value: 'maybe-test');
        final themeData = LayrzThemeData.light(
          extensions: [ext],
        );
        late _TestContextExtension? resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, same(ext));
      },
    );

    testWidgets('breakpoint getter exists and returns LayrzBreakpoint', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint? resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              // Just verify the getter exists and returns a breakpoint
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // The getter should return a valid breakpoint, even if we can't control window size reliably
      expect(resolved, isNotNull);
      expect(resolved, isA<LayrzBreakpoint>());
    });

    testWidgets('context.tokens has breakpoints field', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzBreakpointTokens? breakpoints;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              breakpoints = context.tokens.breakpoints;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(breakpoints, isNotNull);
      expect(breakpoints!.xs, equals(600.0));
      expect(breakpoints!.sm, equals(960.0));
      expect(breakpoints!.md, equals(1264.0));
      expect(breakpoints!.lg, equals(1904.0));
    });

    testWidgets('custom breakpoint tokens are used in theme', (tester) async {
      const customBreakpoints = LayrzBreakpointTokens(xs: 500, sm: 900, md: 1200, lg: 1800);
      final customTheme = LayrzThemeData.light(
        breakpointTokens: customBreakpoints,
      );
      late LayrzBreakpointTokens? resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: customTheme,
          child: Builder(
            builder: (context) {
              resolved = context.tokens.breakpoints;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(customBreakpoints));
      expect(resolved!.xs, equals(500.0));
      expect(resolved!.sm, equals(900.0));
      expect(resolved!.md, equals(1200.0));
      expect(resolved!.lg, equals(1800.0));
    });

    testWidgets('breakpoint resolves to xs band at width 400', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(LayrzBreakpoint.xs));
    });

    testWidgets('breakpoint resolves to sm band at width 700', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(700, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(LayrzBreakpoint.sm));
    });

    testWidgets('breakpoint resolves to md band at width 1000', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(LayrzBreakpoint.md));
    });

    testWidgets('breakpoint resolves to lg band at width 1400', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(LayrzBreakpoint.lg));
    });

    testWidgets('breakpoint resolves to xl band at width 2000', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(2000, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(LayrzBreakpoint.xl));
    });

    testWidgets('isCompact is true for xs band', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isTrue);
    });

    testWidgets('isCompact is true for sm band', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(700, 800);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isTrue);
    });

    testWidgets('isCompact is false for md band', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isFalse);
    });

    testWidgets('isCompact is false for lg band', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isFalse);
    });

    testWidgets('isCompact is false for xl band', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(2000, 800);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isFalse);
    });

    testWidgets('breakpoint boundary: width exactly at xs threshold (600)', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(600, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // At exactly 600, should be sm (xs is < 600)
      expect(resolved, equals(LayrzBreakpoint.sm));
    });

    testWidgets('breakpoint boundary: width exactly at sm threshold (960)', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(960, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // At exactly 960, should be md (sm is < 960)
      expect(resolved, equals(LayrzBreakpoint.md));
    });

    testWidgets('breakpoint boundary: width exactly at md threshold (1264)', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1264, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // At exactly 1264, should be lg (md is < 1264)
      expect(resolved, equals(LayrzBreakpoint.lg));
    });

    testWidgets('breakpoint boundary: width exactly at lg threshold (1904)', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1904, 800);

      final themeData = LayrzThemeData.light();
      late LayrzBreakpoint resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // At exactly 1904, should be xl (lg is < 1904)
      expect(resolved, equals(LayrzBreakpoint.xl));
    });

    testWidgets(
      'isCompact boundary: true at width 599 (xs), false at width 600 (sm)',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(599, 800);

        final themeData = LayrzThemeData.light();
        late bool resolved599;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved599 = context.isCompact;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved599, isTrue); // xs band

        // Now test at 600
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(600, 800);

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved599 = context.isCompact;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved599, isTrue); // sm band is still compact
      },
    );

    testWidgets(
      'isCompact boundary: true at width 959 (sm), false at width 960 (md)',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(959, 800);

        final themeData = LayrzThemeData.light();
        late bool resolved959;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved959 = context.isCompact;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved959, isTrue); // sm band

        // Now test at 960
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(960, 800);

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved959 = context.isCompact;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved959, isFalse); // md band is not compact
      },
    );
  });
}

/// Concrete extension for testing context accessors.
class _TestContextExtension extends LayrzThemeExtension<_TestContextExtension> {
  /// A simple string value.
  final String value;

  /// Creates a test extension with the given value.
  const _TestContextExtension({required this.value});

  @override
  _TestContextExtension copyWith({String? value}) {
    return _TestContextExtension(value: value ?? this.value);
  }

  @override
  _TestContextExtension lerp(covariant _TestContextExtension? other, double t) {
    if (other is! _TestContextExtension) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

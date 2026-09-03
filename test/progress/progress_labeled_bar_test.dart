import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzLabeledProgressBar', () {
    testWidgets('composes the given bar with a label CustomPaint on top', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.5,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      expect(find.byType(LayrzLabeledProgressBar), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter), findsOneWidget);
    });

    testWidgets('formats the label text with the given value and decimals', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.6789,
            decimals: 2,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.value, 0.6789);
      expect(painter.text, '67.89%');
    });

    testWidgets('a tiny non-zero value formats as the smallest non-zero step rather than 0%', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.001,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.text, '1%');
    });

    testWidgets('a true zero value still formats as 0%', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.0,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.text, '0%');
    });

    testWidgets('a value just below 1.0 formats as the largest step below 100% rather than 100%', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.999,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.text, '99%');
    });

    testWidgets('derives the label contrast colors from the given style', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(
        type: LayrzProgressType.danger,
        color: null,
        tokens: theme.tokens,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.5,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.indicatorContrastColor, style.indicatorColor.contrastColor);
      expect(painter.trackContrastColor, style.trackColor.contrastColor);
    });

    testWidgets('passes tokens.spacing.sp1 as the label inset', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      final style = LayrzProgressStyleSpec.resolve(type: LayrzProgressType.info, color: null, tokens: theme.tokens);

      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          height: 16,
          child: LayrzLabeledProgressBar(
            bar: const ColoredBox(color: Color(0xFFCCCCCC)),
            value: 0.5,
            decimals: 0,
            style: style,
            tokens: theme.tokens,
          ),
        ),
        theme: theme,
      );

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzProgressLabelPainter),
                  )
                  .painter
              as LayrzProgressLabelPainter;

      expect(painter.inset, theme.tokens.spacing.sp1);
    });
  });
}

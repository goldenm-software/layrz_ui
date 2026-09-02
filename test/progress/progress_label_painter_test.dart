import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/progress/progress.dart';

/// Independently measures [text] under [style], mirroring the layout the
/// painter itself performs internally, so tests assert against a value
/// computed the same way the production code computes it rather than a
/// guessed constant.
double _measureWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  group('LayrzProgressLabelPainter', () {
    const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
    const indicatorContrastColor = Color(0xFFFFFFFF);
    const trackContrastColor = Color(0xFF000000);
    const inset = 6.0;
    const size = Size(300, 16);

    // `value` (the determinate fraction) is the painter's actual input —
    // it derives the fill boundary itself at paint time as
    // `size.width * value`, against the real, resolved paint Size, rather
    // than accepting a precomputed pixel offset from the caller. See the
    // class doc for why: CustomPaint.size is only a preferred-size hint, and
    // LayrzProgressBar's linear format hints Size(double.infinity, height)
    // since its true width is resolved by its parent's constraints.

    test('a wide bar (68%) right-aligns the label inside the bar, inset from the fill boundary', () {
      const text = '68%';
      final labelWidth = _measureWidth(text, style);
      final boundary = size.width * 0.68;

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 0.68,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          // Right-aligned against the boundary, inset, and wholly to the
          // left of it (inside the filled region).
          expect(offset.dx, closeTo(boundary - inset - labelWidth, 0.5));
          expect(offset.dx + labelWidth, lessThanOrEqualTo(boundary));
          return true;
        }),
      );
    });

    test('a narrow bar (5%) flips the label onto the track, inset past the fill boundary', () {
      const text = '5%';
      final labelWidth = _measureWidth(text, style);
      final boundary = size.width * 0.05;

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 0.05,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          // Flipped: starts just past the boundary (inset), wholly to the
          // right of it (on the unfilled track).
          expect(offset.dx, closeTo(boundary + inset, 0.5));
          expect(offset.dx, greaterThanOrEqualTo(boundary));
          return true;
        }),
      );
      expect(boundary - inset, lessThan(labelWidth), reason: 'sanity: bar must not have fit the label');
    });

    test('value 0.0 (zero-width bar) flips the label onto the track', () {
      const text = '0%';
      const boundary = 0.0;

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 0.0,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          // Flipped onto the track, starting right at the leading edge
          // (boundary 0) plus the inset.
          expect(offset.dx, closeTo(boundary + inset, 0.5));
          return true;
        }),
      );
    });

    test('value 1.0 (no track at all) keeps the label inside the bar', () {
      const text = '100%';
      final labelWidth = _measureWidth(text, style);
      final boundary = size.width; // 1.0 * totalWidth — no track remains.

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 1.0,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          expect(offset.dx, closeTo(boundary - inset - labelWidth, 0.5));
          // Wholly inside the bar: never past the right edge of the box.
          expect(offset.dx + labelWidth, lessThanOrEqualTo(size.width));
          return true;
        }),
      );
    });

    test('a very small non-zero value (1%) still flips to the track when the bar cannot hold the label', () {
      const text = '1%';
      final labelWidth = _measureWidth(text, style);
      final boundary = size.width * 0.01;

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 0.01,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(boundary - inset, lessThan(0), reason: 'sanity: the bar has no usable space at all at 1%');

      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          expect(offset.dx, closeTo(boundary + inset, 0.5));
          expect(offset.dx, greaterThanOrEqualTo(boundary));
          return true;
        }),
      );
      expect(labelWidth, greaterThan(0));
    });

    test('a value near 100% with an oversized label that fits neither region stays inside the bar, clamped', () {
      // A pathologically long label (simulating high decimals + a long
      // custom style) that does not fit in the tiny track remaining at 99%,
      // nor — by construction of this test's narrow total width — leaves
      // enough room to sit flush inside the bar either. The documented
      // tie-break is: fitting inside the bar is always tried first and wins
      // when it fits; the track is only chosen when the bar's own check
      // fails. Here neither fits, so the implementation clamps back inside
      // the bar rather than overflowing onto the near-zero track.
      const text = '99.999999%';
      const narrowSize = Size(60, 16);
      final labelWidth = _measureWidth(text, style);
      final boundary = narrowSize.width * 0.99;

      final painter = LayrzProgressLabelPainter(
        text: text,
        style: style,
        value: 0.99,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(boundary - inset, lessThan(labelWidth), reason: 'sanity: does not fit inside the bar');
      expect(
        narrowSize.width - boundary - inset,
        lessThan(labelWidth),
        reason: 'sanity: does not fit on the track either',
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, narrowSize),
        paints..something((symbol, arguments) {
          if (symbol != #drawParagraph) return false;
          final offset = arguments[1] as Offset;
          // Clamped to the box's left edge: the label itself (140px) is
          // wider than the entire box (60px), so there is no offset that
          // keeps it wholly on-screen — the implementation's contract is
          // only that it never paints at a negative x, not that an
          // oversized label is fully contained.
          expect(offset.dx, 0.0);
          return true;
        }),
      );
    });

    test('shouldRepaint returns true when value changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.2,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true when inset changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: 6.0,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: 10.0,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true when indicatorContrastColor changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: const Color(0xFFFFFFFF),
        trackContrastColor: trackContrastColor,
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: const Color(0xFF000000),
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true when trackContrastColor changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: const Color(0xFF000000),
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: const Color(0xFFFFFFFF),
        inset: inset,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true when text changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '20%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns true when style changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: const TextStyle(fontSize: 20, color: Color(0xFF000000)),
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final a = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );
      final b = LayrzProgressLabelPainter(
        text: '10%',
        style: style,
        value: 0.1,
        indicatorContrastColor: indicatorContrastColor,
        trackContrastColor: trackContrastColor,
        inset: inset,
      );

      expect(b.shouldRepaint(a), isFalse);
    });
  });
}

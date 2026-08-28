import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSliderBubbleLayoutDelegate', () {
    test('getSize keeps a finite height when the incoming constraint is unbounded', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      final size = delegate.getSize(const BoxConstraints(maxWidth: 300));
      expect(size.width, 300);
      expect(size.height.isFinite, isTrue);
    });

    test('getSize passes through a finite height constraint unchanged', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      final size = delegate.getSize(const BoxConstraints(maxWidth: 300, maxHeight: 44));
      expect(size.height, 44);
    });

    test('getConstraintsForChild loosens the incoming constraints', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      final constraints = delegate.getConstraintsForChild(const BoxConstraints(maxWidth: 300, maxHeight: 44));
      expect(constraints.minWidth, 0);
      expect(constraints.minHeight, 0);
      expect(constraints.maxWidth, 300);
    });

    test('getPositionForChild centres the child on the thumb at fraction 0.0 (track start)', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.0);
      final offset = delegate.getPositionForChild(const Size(300, 200), const Size(40, 24));
      // thumbX = 8 + (300 - 16) * 0.0 = 8; bubble left = 8 - 40/2 = -12.
      expect(offset.dx, -12);
      expect(offset.dy, 0);
    });

    test('getPositionForChild centres the child on the thumb at fraction 1.0 (track end)', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 1.0);
      final offset = delegate.getPositionForChild(const Size(300, 200), const Size(40, 24));
      // thumbX = 8 + (300 - 16) * 1.0 = 292; bubble left = 292 - 40/2 = 272.
      expect(offset.dx, 272);
    });

    test('getPositionForChild centres the child on the thumb at fraction 0.5 (track middle)', () {
      const delegate = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      final offset = delegate.getPositionForChild(const Size(300, 200), const Size(40, 24));
      // thumbX = 8 + (300 - 16) * 0.5 = 150; bubble left = 150 - 40/2 = 130.
      expect(offset.dx, 130);
    });

    test('shouldRelayout returns true when trackWidth changes', () {
      const a = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      const b = LayrzSliderBubbleLayoutDelegate(trackWidth: 250, thumbHalfSize: 8, fraction: 0.5);
      expect(a.shouldRelayout(b), isTrue);
    });

    test('shouldRelayout returns true when thumbHalfSize changes', () {
      const a = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      const b = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 10, fraction: 0.5);
      expect(a.shouldRelayout(b), isTrue);
    });

    test('shouldRelayout returns true when fraction changes', () {
      const a = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.2);
      const b = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.8);
      expect(a.shouldRelayout(b), isTrue);
    });

    test('shouldRelayout returns false when nothing changes', () {
      const a = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      const b = LayrzSliderBubbleLayoutDelegate(trackWidth: 300, thumbHalfSize: 8, fraction: 0.5);
      expect(a.shouldRelayout(b), isFalse);
    });
  });
}

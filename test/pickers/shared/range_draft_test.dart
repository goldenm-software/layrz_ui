import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/range_draft.dart';

void main() {
  group('LayrzRangeDraft', () {
    test('empty has no anchor, no end, and is not complete', () {
      const draft = LayrzRangeDraft<int>.empty();
      expect(draft.anchor, isNull);
      expect(draft.end, isNull);
      expect(draft.isComplete, isFalse);
      expect(draft.movableEndpoint, isNull);
    });

    test('anchored carries an anchor but is not complete', () {
      const draft = LayrzRangeDraft<int>.anchored(5);
      expect(draft.anchor, 5);
      expect(draft.end, isNull);
      expect(draft.isComplete, isFalse);
    });

    test('complete carries both endpoints and is complete', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5);
      expect(draft.anchor, 1);
      expect(draft.end, 5);
      expect(draft.isComplete, isTrue);
      expect(draft.movableEndpoint, isNull);
    });

    test('complete accepts an optional movableEndpoint', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5, movableEndpoint: LayrzRangeEndpoint.start);
      expect(draft.movableEndpoint, LayrzRangeEndpoint.start);
    });

    test('arbitrary is complete iff the selection is non-empty', () {
      final empty = LayrzRangeDraft<int>.arbitrary({});
      final nonEmpty = LayrzRangeDraft<int>.arbitrary({1, 2});
      expect(empty.isComplete, isFalse);
      expect(nonEmpty.isComplete, isTrue);
      expect(nonEmpty.arbitrarySelection, {1, 2});
    });

    test('copyWith replaces only given fields', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5);
      final copy = draft.copyWith(end: 10);
      expect(copy.anchor, 1);
      expect(copy.end, 10);
      expect(copy.isComplete, isTrue);
    });

    test('copyWith clearMovableEndpoint resets to null', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5, movableEndpoint: LayrzRangeEndpoint.end);
      final copy = draft.copyWith(clearMovableEndpoint: true);
      expect(copy.movableEndpoint, isNull);
    });

    test('copyWith without clearMovableEndpoint preserves the existing value', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5, movableEndpoint: LayrzRangeEndpoint.end);
      final copy = draft.copyWith(anchor: 2);
      expect(copy.movableEndpoint, LayrzRangeEndpoint.end);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzRangeDraft<int>.complete(anchor: 1, end: 5);
      const b = LayrzRangeDraft<int>.complete(anchor: 1, end: 5);
      const c = LayrzRangeDraft<int>.complete(anchor: 1, end: 6);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('equality for arbitrary drafts ignores set iteration order', () {
      final a = LayrzRangeDraft<int>.arbitrary({1, 2, 3});
      final b = LayrzRangeDraft<int>.arbitrary({3, 2, 1});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes anchor, end, and selection', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 1, end: 5);
      expect(draft.toString(), contains('1'));
      expect(draft.toString(), contains('5'));
    });
  });

  group('LayrzRangeEndpoint', () {
    test('has exactly start and end members', () {
      expect(LayrzRangeEndpoint.values, [LayrzRangeEndpoint.start, LayrzRangeEndpoint.end]);
    });
  });
}

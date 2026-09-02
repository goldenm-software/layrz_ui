import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/range_draft.dart';
import 'package:layrz_ui/src/pickers/src/shared/range_policy.dart';

void main() {
  group('LayrzContiguousRangePolicy — state machine', () {
    final policy = LayrzContiguousRangePolicy<int>(compare: (a, b) => a.compareTo(b));

    test('empty -> tap sets the anchor, half-open, nothing complete', () {
      const draft = LayrzRangeDraft<int>.empty();
      final next = policy.onTap(draft, 5);
      expect(next.anchor, 5);
      expect(next.end, isNull);
      expect(next.isComplete, isFalse);
    });

    test('half-open -> tap after the anchor completes the range in order', () {
      const draft = LayrzRangeDraft<int>.anchored(5);
      final next = policy.onTap(draft, 10);
      expect(next.isComplete, isTrue);
      expect(next.anchor, 5);
      expect(next.end, 10);
    });

    test('half-open -> tap before the anchor auto-swaps, never rejects', () {
      const draft = LayrzRangeDraft<int>.anchored(10);
      final next = policy.onTap(draft, 5);
      expect(next.isComplete, isTrue);
      expect(next.anchor, 5);
      expect(next.end, 10);
    });

    test('complete -> re-tapping the start endpoint picks it up as movable', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      final next = policy.onTap(draft, 5);
      expect(next.isComplete, isTrue);
      expect(next.anchor, 5);
      expect(next.end, 10);
      expect(next.movableEndpoint, LayrzRangeEndpoint.start);
    });

    test('complete -> re-tapping the end endpoint picks it up as movable', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      final next = policy.onTap(draft, 10);
      expect(next.movableEndpoint, LayrzRangeEndpoint.end);
    });

    test('complete, start movable -> next tap moves the start edge, end stays fixed', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10, movableEndpoint: LayrzRangeEndpoint.start);
      final next = policy.onTap(draft, 2);
      expect(next.anchor, 2);
      expect(next.end, 10);
    });

    test('complete, start movable -> moving past the fixed end edge auto-swaps', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10, movableEndpoint: LayrzRangeEndpoint.start);
      final next = policy.onTap(draft, 15);
      expect(next.anchor, 10);
      expect(next.end, 15);
    });

    test('complete, end movable -> next tap moves the end edge, start stays fixed', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10, movableEndpoint: LayrzRangeEndpoint.end);
      final next = policy.onTap(draft, 20);
      expect(next.anchor, 5);
      expect(next.end, 20);
    });

    test('complete, end movable -> moving before the fixed start edge auto-swaps', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10, movableEndpoint: LayrzRangeEndpoint.end);
      final next = policy.onTap(draft, 1);
      expect(next.anchor, 1);
      expect(next.end, 5);
    });

    test('complete, no endpoint movable -> interior tap is rejected, draft unchanged', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      final next = policy.onTap(draft, 7);
      expect(next, same(draft));
    });

    test('complete -> outside tap extends toward the tapped value', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      final before = policy.onTap(draft, 1);
      expect(before.anchor, 1);
      expect(before.end, 10);

      final after = policy.onTap(draft, 20);
      expect(after.anchor, 5);
      expect(after.end, 20);
    });

    test('the interior-lock model is not implemented — a completed range never permanently locks', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      // Re-tapping an endpoint picks it up rather than being rejected, which
      // would not be possible under the retired interior-lock model (where
      // only the first/last taps were ever deselectable).
      final next = policy.onTap(draft, 5);
      expect(next.movableEndpoint, isNotNull);
    });
  });

  group('LayrzContiguousRangePolicy — isRejected', () {
    final policy = LayrzContiguousRangePolicy<int>(compare: (a, b) => a.compareTo(b));

    test('an interior value of a complete range is rejected', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      expect(policy.isRejected(draft, 7), isTrue);
    });

    test('the endpoints themselves are never rejected', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      expect(policy.isRejected(draft, 5), isFalse);
      expect(policy.isRejected(draft, 10), isFalse);
    });

    test('a value outside the range is never rejected', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10);
      expect(policy.isRejected(draft, 1), isFalse);
      expect(policy.isRejected(draft, 20), isFalse);
    });

    test('nothing is rejected while the draft is empty or half-open', () {
      expect(policy.isRejected(const LayrzRangeDraft<int>.empty(), 5), isFalse);
      expect(policy.isRejected(const LayrzRangeDraft<int>.anchored(5), 7), isFalse);
    });

    test('nothing is rejected once an endpoint has been picked up as movable', () {
      const draft = LayrzRangeDraft<int>.complete(anchor: 5, end: 10, movableEndpoint: LayrzRangeEndpoint.start);
      expect(policy.isRejected(draft, 7), isFalse);
    });
  });

  group('LayrzContiguousRangePolicy — date domain, leap years and month boundaries', () {
    final policy = LayrzContiguousRangePolicy<DateTime>(compare: (a, b) => a.compareTo(b));

    test('a range spanning a leap-year Feb 29 completes correctly', () {
      const draft = LayrzRangeDraft<DateTime>.empty();
      final anchored = policy.onTap(draft, DateTime(2028, 2, 1));
      final completed = policy.onTap(anchored, DateTime(2028, 2, 29));
      expect(completed.anchor, DateTime(2028, 2, 1));
      expect(completed.end, DateTime(2028, 2, 29));
    });

    test('a range spanning a month boundary rejects an interior date correctly', () {
      final draft = LayrzRangeDraft<DateTime>.complete(anchor: DateTime(2026, 1, 30), end: DateTime(2026, 2, 2));
      expect(policy.isRejected(draft, DateTime(2026, 1, 31)), isTrue);
      expect(policy.isRejected(draft, DateTime(2026, 2, 1)), isTrue);
      expect(policy.isRejected(draft, DateTime(2026, 1, 30)), isFalse);
      expect(policy.isRejected(draft, DateTime(2026, 2, 2)), isFalse);
    });

    test('a range spanning a year boundary auto-swaps correctly', () {
      final draft = LayrzRangeDraft<DateTime>.anchored(DateTime(2027, 1, 5));
      final next = policy.onTap(draft, DateTime(2026, 12, 20));
      expect(next.anchor, DateTime(2026, 12, 20));
      expect(next.end, DateTime(2027, 1, 5));
    });
  });

  group('LayrzArbitraryRangePolicy — set-membership toggling', () {
    const policy = LayrzArbitraryRangePolicy<int>();

    test('tapping an unselected value adds it', () {
      final draft = LayrzRangeDraft<int>.arbitrary({});
      final next = policy.onTap(draft, 3);
      expect(next.arbitrarySelection, {3});
      expect(next.isComplete, isTrue);
    });

    test('tapping an already-selected value removes it', () {
      final draft = LayrzRangeDraft<int>.arbitrary({3, 5});
      final next = policy.onTap(draft, 3);
      expect(next.arbitrarySelection, {5});
    });

    test('removing the last selected value returns to not-complete', () {
      final draft = LayrzRangeDraft<int>.arbitrary({3});
      final next = policy.onTap(draft, 3);
      expect(next.arbitrarySelection, isEmpty);
      expect(next.isComplete, isFalse);
    });

    test('a discontinuous selection is reachable — no adjacency is enforced', () {
      final draft = LayrzRangeDraft<int>.arbitrary({});
      final withFirst = policy.onTap(draft, 1);
      final withGap = policy.onTap(withFirst, 5);
      expect(withGap.arbitrarySelection, {1, 5});
    });

    test('nothing is ever rejected under the arbitrary policy', () {
      final draft = LayrzRangeDraft<int>.arbitrary({1, 2, 3});
      expect(policy.isRejected(draft, 2), isFalse);
      expect(policy.isRejected(draft, 99), isFalse);
    });
  });
}

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Resolves the [SemanticsSortKey] carried by the nearest ancestor
/// `Semantics(sortKey: ...)` node above [finder] (inclusive).
///
/// See the identical helper in `timeline_two_sided_surface_test.dart` for why
/// `tester.getSemantics(finder).sortKey` alone is not reliable here: the
/// `Semantics(sortKey: ...)` row wrapper and the card's own
/// `Semantics(label: ...)` node do not merge, so the sort key must be read
/// from the nearest ancestor that actually declares one.
SemanticsSortKey? findAncestorSortKey(WidgetTester tester, Finder finder) {
  final element = finder.evaluate().first;
  SemanticsSortKey? found;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Semantics && widget.properties.sortKey != null) {
      found = widget.properties.sortKey;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  group('LayrzTimeline Accessibility', () {
    testWidgets('marker is excluded from semantics -- only the card announces', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(
              entries: const [
                LayrzTimelineEntry(labelText: 'Shipped', descriptionText: 'Left the warehouse'),
              ],
            ),
          ),
        );

        // The marker itself carries no semantics node of its own.
        final markerSemantics = tester.getSemantics(find.byType(LayrzTimelineMarker));
        expect(markerSemantics.label, isEmpty);

        // The card's Semantics node merges label + description into one
        // announcement.
        final cardSemantics = tester.getSemantics(find.text('Shipped'));
        expect(cardSemantics.label, contains('Shipped'));
        expect(cardSemantics.label, contains('Left the warehouse'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('entry card semantics label includes the timestamp when present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(
              entries: const [
                LayrzTimelineEntry(labelText: 'Delivered', timestampText: 'Aug 28, 2026'),
              ],
            ),
          ),
        );

        final semantics = tester.getSemantics(find.text('Delivered'));
        expect(semantics.label, contains('Delivered'));
        expect(semantics.label, contains('Aug 28, 2026'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an entry with no accent color still has a distinguishable marker fill', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(
              entries: const [LayrzTimelineEntry(labelText: 'Neutral entry')],
            ),
          ),
        );

        // The marker itself must not be the only carrier of the entry's
        // identity: the card's own semantics label (asserted above in other
        // tests) is what a screen reader relies on, independent of color.
        final marker = tester.widget<LayrzTimelineMarker>(find.byType(LayrzTimelineMarker));
        final tokens = LayrzTheme.of(tester.element(find.byType(LayrzTimelineMarker))).tokens;
        expect(marker.spec.markerColor, tokens.colors.sf4);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('two-sided layout preserves chronological semantics order at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            child: LayrzTimeline(
              entries: const [
                LayrzTimelineEntry(labelText: 'Event one'),
                LayrzTimelineEntry(labelText: 'Event two'),
                LayrzTimelineEntry(labelText: 'Event three'),
              ],
            ),
          ),
        );

        final first = findAncestorSortKey(tester, find.text('Event one'));
        final second = findAncestorSortKey(tester, find.text('Event two'));
        final third = findAncestorSortKey(tester, find.text('Event three'));

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(third, isNotNull);
        expect(first!.compareTo(second!), lessThan(0));
        expect(second.compareTo(third!), lessThan(0));
      } finally {
        handle.dispose();
      }
    });
  });
}

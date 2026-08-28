import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// Resolves the [SemanticsSortKey] carried by the nearest ancestor
/// `Semantics(sortKey: ...)` node above [finder] (inclusive).
///
/// The `Semantics(sortKey: ...)` wrapper `LayrzTimelineTwoSidedSurface` places
/// around each row does not merge into the same semantics node as the card's
/// own `Semantics(label: ...)` (the card composes its own node, with
/// `container: true`), so `tester.getSemantics(finder).sortKey` resolves to
/// the card's node -- which carries the label but not the sort key -- rather
/// than the row wrapper's. Walking up to the nearest ancestor `Semantics`
/// widget that actually declares a `sortKey` is the reliable way to read it
/// back in a test.
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
  group('LayrzTimelineTwoSidedSurface', () {
    Widget buildCard(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) {
      return Text(entry.labelText);
    }

    guardedTestWidgets('renders one card per entry', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'A'),
        LayrzTimelineEntry(labelText: 'B'),
        LayrzTimelineEntry(labelText: 'C'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.byType(LayrzTimelineMarker), findsNWidgets(3));
    });

    guardedTestWidgets('alternates sides automatically when no explicit side is set', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'Even index -> start'),
        LayrzTimelineEntry(labelText: 'Odd index -> end'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final firstCardCenter = tester.getCenter(find.text('Even index -> start'));
      final secondCardCenter = tester.getCenter(find.text('Odd index -> end'));

      // The first (even-index) entry lands on the start (left) side, and the
      // second (odd-index) entry on the end (right) side, so their x-centres
      // fall on opposite sides of the spine's horizontal midpoint.
      expect(firstCardCenter.dx, lessThan(secondCardCenter.dx));
    });

    guardedTestWidgets('an explicit side overrides the automatic alternation', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        // Index 0 would normally land on `start`; force it to `end` instead.
        LayrzTimelineEntry(labelText: 'Forced end', side: LayrzTimelineSide.end),
        // Index 1 would normally default to `end` (odd index); force it to
        // `start` instead, so the two entries land on opposite sides only
        // because of the explicit overrides, not the alternation default.
        LayrzTimelineEntry(labelText: 'Forced start', side: LayrzTimelineSide.start),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final endCenter = tester.getCenter(find.text('Forced end'));
      final startCenter = tester.getCenter(find.text('Forced start'));

      expect(endCenter.dx, greaterThan(startCenter.dx));
    });

    guardedTestWidgets('semantics traversal order follows entry list order, not visual side', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        const entries = [
          LayrzTimelineEntry(labelText: 'Chrono first', side: LayrzTimelineSide.end),
          LayrzTimelineEntry(labelText: 'Chrono second', side: LayrzTimelineSide.start),
        ];

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            child: LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: buildCard),
          ),
        );

        final firstSortKey = findAncestorSortKey(tester, find.text('Chrono first'));
        final secondSortKey = findAncestorSortKey(tester, find.text('Chrono second'));

        expect(firstSortKey, isNotNull);
        expect(secondSortKey, isNotNull);
        expect(firstSortKey!.compareTo(secondSortKey!), lessThan(0));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a single entry renders with no connector segments', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(
            entries: const [LayrzTimelineEntry(labelText: 'Only entry')],
            cardBuilder: buildCard,
          ),
        ),
      );

      expect(find.byType(LayrzTimelineConnector), findsNothing);
    });

    guardedTestWidgets('the spine is continuous: connectors meet the adjacent marker with no gap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Entries with real card content (label + description + timestamp) so
      // this reproduces the row heights the showroom screenshot showed --
      // a `labelText`-only entry collapses the row so tightly that the
      // inter-row gap this test guards against would not show up.
      const entries = [
        LayrzTimelineEntry(labelText: 'Order placed', descriptionText: 'Placed by customer', timestampText: 'Jan 1'),
        LayrzTimelineEntry(labelText: 'Payment failed', descriptionText: 'Card declined', timestampText: 'Jan 2'),
        LayrzTimelineEntry(labelText: 'Shipped', descriptionText: 'Left warehouse', timestampText: 'Jan 3'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final markers = find.byType(LayrzTimelineMarker);
      final connectors = find.descendant(
        of: find.byType(LayrzTimelineConnector),
        matching: find.byType(Container),
      );

      final markerRects = [for (var i = 0; i < 3; i++) tester.getRect(markers.at(i))];
      final connectorRects = [for (var i = 0; i < 4; i++) tester.getRect(connectors.at(i))];

      // Connector 0 is below marker 0, connector 1 is above marker 1: between
      // them lies the former inter-row gap. The spine is continuous only if
      // connector 0's bottom edge reaches all the way to connector 1's top
      // edge -- i.e. no unpainted band separates the two halves of the
      // segment joining marker 0 to marker 1.
      expect(connectorRects[0].bottom, equals(connectorRects[1].top));
      expect(connectorRects[2].bottom, equals(connectorRects[3].top));

      // Each connector segment must also directly abut the marker it is
      // adjacent to, with no gap on that side either.
      expect(connectorRects[0].top, equals(markerRects[0].bottom));
      expect(connectorRects[1].bottom, equals(markerRects[1].top));
      expect(connectorRects[2].top, equals(markerRects[1].bottom));
      expect(connectorRects[3].bottom, equals(markerRects[2].top));
    });

    guardedTestWidgets('renders no markers for an empty entry list', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          child: LayrzTimelineTwoSidedSurface(entries: const [], cardBuilder: buildCard),
        ),
      );

      expect(find.byType(LayrzTimelineMarker), findsNothing);
    });
  });
}

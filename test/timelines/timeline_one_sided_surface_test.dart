import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTimelineOneSidedSurface', () {
    Widget buildCard(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) {
      return Text(entry.labelText);
    }

    guardedTestWidgets('renders one card per entry, all in a single column', (tester) async {
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
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.byType(LayrzTimelineMarker), findsNWidgets(3));
    });

    guardedTestWidgets('first entry has no connector above, last entry has none below', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'A'),
        LayrzTimelineEntry(labelText: 'B'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      // Two entries -> two connector segments between them: the segment below
      // A's marker and the segment above B's marker, each rendered by its own
      // row half.
      expect(find.byType(LayrzTimelineConnector), findsNWidgets(2));
    });

    guardedTestWidgets(
      'a neutral entry paints a lighter marker fill and a darker, visible connector',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const entries = [
          LayrzTimelineEntry(labelText: 'A'),
          LayrzTimelineEntry(labelText: 'B'),
        ];

        await pumpThemed(
          tester,
          SizedBox(
            width: 800,
            child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
          ),
        );

        final tokens = LayrzTheme.of(tester.element(find.byType(LayrzTimelineMarker).first)).tokens;

        final marker = tester.widget<Container>(
          find.descendant(of: find.byType(LayrzTimelineMarker).first, matching: find.byType(Container)).first,
        );
        expect((marker.decoration as BoxDecoration).color, tokens.colors.sf4);

        final connector = tester.widget<LayrzTimelineConnector>(find.byType(LayrzTimelineConnector).first);
        expect(connector.color, tokens.colors.fg3);

        // The whole point of splitting the two tokens: the marker fill reads
        // lighter than the connector line, so a light neutral marker does not
        // also wash out the spine into invisibility.
        expect(tokens.colors.sf4.computeLuminance(), greaterThan(tokens.colors.fg3.computeLuminance()));
      },
    );

    guardedTestWidgets('renders no markers or cards for an empty entry list', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: const [], cardBuilder: buildCard),
        ),
      );

      expect(find.byType(LayrzTimelineMarker), findsNothing);
    });

    guardedTestWidgets('renders the icon-carrying marker for an entry with an icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'Has icon', icon: MdiIcons.truckOutline),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final marker = tester.widget<LayrzTimelineMarker>(find.byType(LayrzTimelineMarker));
      expect(marker.icon, MdiIcons.truckOutline);
      expect(
        find.descendant(of: find.byType(LayrzTimelineMarker), matching: find.byType(Icon)),
        findsOneWidget,
      );
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
          width: 600,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
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
      // segment joining marker 0 to marker 1. Before the fix, connector 0
      // stopped well short of marker 1 (a bare `Padding` gap in between).
      expect(connectorRects[0].bottom, equals(connectorRects[1].top));
      expect(connectorRects[2].bottom, equals(connectorRects[3].top));

      // Each connector segment must also directly abut the marker it is
      // adjacent to, with no gap on that side either.
      expect(connectorRects[0].top, equals(markerRects[0].bottom));
      expect(connectorRects[1].bottom, equals(markerRects[1].top));
      expect(connectorRects[2].top, equals(markerRects[1].bottom));
      expect(connectorRects[3].bottom, equals(markerRects[2].top));
    });

    guardedTestWidgets('renders a plain dot marker (no Icon) for an entry with no icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const entries = [
        LayrzTimelineEntry(labelText: 'No icon'),
      ];

      await pumpThemed(
        tester,
        SizedBox(
          width: 800,
          child: LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: buildCard),
        ),
      );

      final marker = tester.widget<LayrzTimelineMarker>(find.byType(LayrzTimelineMarker));
      expect(marker.icon, isNull);
      expect(
        find.descendant(of: find.byType(LayrzTimelineMarker), matching: find.byType(Icon)),
        findsNothing,
      );
    });
  });
}

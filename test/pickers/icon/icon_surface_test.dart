import 'package:flutter/widgets.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/icon/icon_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Pumps [surface] inside a fixed-height [SizedBox], matching how
/// [LayrzIconSurface] is actually hosted in production: both branches of
/// `LayrzResponsiveModal.show` (see `icon_input.dart`'s `_openPicker`) place
/// the surface's builder content inside their own bounded region — never in
/// `pumpThemed`'s unbounded `Center` alone. The surface's own grid section
/// relies on that bound (it wraps `LayrzGlyphGrid` in `Expanded` with
/// `shrinkWrap: false`), so every standalone test needs this same bounded
/// ancestor to reflect a real host rather than asserting against a layout no
/// real caller produces. Mirrors `emoji_surface_test.dart`'s identical
/// `_pumpBoundedSurface` helper.
Future<void> _pumpBoundedSurface(WidgetTester tester, LayrzIconSurface surface) {
  return pumpThemed(tester, SizedBox(height: 600.0, child: surface));
}

void main() {
  group('LayrzIconSurface — rendering', () {
    guardedTestWidgets('renders the search field and at least one icon cell with no crash', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      expect(find.byType(LayrzIconSurface), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      expect(find.byType(LayrzIconSurface), findsOneWidget);
    });

    guardedTestWidgets('renders the first registry icon by default (all icons, no search)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final first = allMdiRemapIcons().first;
      expect(find.byIcon(first.data), findsWidgets);
    });
  });

  group('LayrzIconSurface — search', () {
    guardedTestWidgets('typing a query filters the grid to matching icons only', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final target = findMdiRemapIconByName('mdi-account')!;
      // Something that does NOT match 'account' by name or tags, to prove
      // the grid actually narrowed rather than merely re-rendering
      // everything.
      final nonMatch = allMdiRemapIcons().firstWhere(
        (icon) =>
            !icon.name.toLowerCase().contains('account') && !icon.tags.any((t) => t.toLowerCase().contains('account')),
      );

      expect(find.byIcon(nonMatch.data), findsWidgets);

      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();

      expect(find.byIcon(target.data), findsWidgets);
      expect(find.byIcon(nonMatch.data), findsNothing);
    });

    guardedTestWidgets('search is case-insensitive', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final target = findMdiRemapIconByName('mdi-account')!;

      await tester.enterText(find.byType(EditableText).first, 'ACCOUNT');
      await tester.pump();

      expect(find.byIcon(target.data), findsWidgets);
    });

    guardedTestWidgets('matches by tag, not only name', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      // Pick an icon whose name does NOT contain one of its own tags, then
      // search by that tag -- proving the tag branch of the filter (not just
      // name) drives a match.
      final withTag = allMdiRemapIcons().firstWhere(
        (icon) => icon.tags.isNotEmpty && !icon.name.toLowerCase().contains(icon.tags.first.toLowerCase()),
      );

      await tester.enterText(find.byType(EditableText).first, withTag.tags.first);
      await tester.pump();

      expect(find.byIcon(withTag.data), findsWidgets);
    });

    guardedTestWidgets('an unmatched search shows the empty state', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      await tester.enterText(find.byType(EditableText).first, 'zzzznonexistentquery');
      await tester.pump();

      expect(find.text('No icon found'), findsOneWidget);
    });

    guardedTestWidgets('clearing the search restores the full registry view', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final first = allMdiRemapIcons().first;
      await tester.enterText(find.byType(EditableText).first, 'zzzznonexistentquery');
      await tester.pump();
      expect(find.text('No icon found'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '');
      await tester.pump();

      expect(find.text('No icon found'), findsNothing);
      expect(find.byIcon(first.data), findsWidgets);
    });
  });

  group('LayrzIconSurface — commit on tap', () {
    guardedTestWidgets('tapping an icon cell invokes onIconSelected with its stable mdi- name', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? selected;
      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (name) => selected = name));

      final target = findMdiRemapIconByName('mdi-account')!;
      await tester.enterText(find.byType(EditableText).first, 'account');
      await tester.pump();

      await tester.tap(find.byIcon(target.data).last);
      await tester.pump();

      expect(selected, target.name);
      expect(selected, startsWith('mdi-'));
    });
  });

  group('LayrzIconSurface — virtualization', () {
    // The registry backing this surface holds ~7,447 icons
    // (allMdiRemapIcons().length). If the grid built every cell eagerly
    // (shrinkWrap: true, or no virtualization at all), this test's fixed
    // 600px-tall bounded host would still end up with thousands of `Icon`
    // widgets in the tree. Asserting the built count stays a small fraction
    // of the full registry is the concrete proxy for "the grid is lazy",
    // not merely "the surface renders without crashing".
    guardedTestWidgets('does not build all ~7,447 icon cells at once in a bounded viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final totalRegistrySize = allMdiRemapIcons().length;
      expect(totalRegistrySize, greaterThan(7000));

      final builtIconCells = find.byType(Icon).evaluate().length;
      expect(
        builtIconCells,
        lessThan(200),
        reason:
            'A bounded 600px-tall viewport at 8 columns of ~44px cells should build on the order of a '
            'few dozen cells (plus GridView cacheExtent), never anywhere close to the full '
            '$totalRegistrySize-entry registry -- a much larger built count would mean the grid is '
            'laying out every item eagerly instead of virtualizing.',
      );
      expect(builtIconCells, greaterThan(0));
    });

    guardedTestWidgets('scrolling the grid changes which icon cells are built', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBoundedSurface(tester, LayrzIconSurface(onIconSelected: (_) {}));

      final allIcons = allMdiRemapIcons();
      final farIcon = allIcons[allIcons.length - 1];

      // Not yet built -- it is far past the initial viewport of a
      // ~7,447-item, 8-column grid.
      expect(find.byIcon(farIcon.data), findsNothing);

      await tester.drag(find.byType(GridView), const Offset(0, -1000000));
      await tester.pump();

      // After scrolling to the end, the last registry icon's cell must now
      // be built -- proving cells are constructed lazily as they scroll into
      // view, not all at once up front.
      expect(find.byIcon(farIcon.data), findsWidgets);
    });
  });
}

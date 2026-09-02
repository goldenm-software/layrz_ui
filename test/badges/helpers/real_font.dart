import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the real Roboto font under the family name [testFontFamily] for
/// the duration of the current test.
///
/// Widget tests render with Flutter's built-in fallback test font by
/// default — a font that gives every glyph a uniform, fixed-advance box with
/// no side bearing. That is sufficient for layout-box assertions, but it
/// structurally cannot reveal a defect where content paints correctly inside
/// its own layout box's bounds yet is misaligned *within* that box (for
/// example `TextAlign.start` painting glyphs flush-left inside a
/// `RenderParagraph` box that was itself widened past its intrinsic content
/// by an ambient `minWidth` constraint) — the fallback font's glyph ink
/// always exactly fills its layout box, so a "tight" ink-bounds measurement
/// against it is identical to a layout-box measurement and cannot
/// distinguish the two.
///
/// This loads the real Roboto-Regular.ttf bundled at
/// `test/badges/fixtures/Roboto-Regular.ttf` (Apache 2.0-licensed, the same
/// font this design system's default [LayrzRobotoFont] specifies) so glyph
/// ink bounds measured via [RenderParagraph.getBoxesForSelection] reflect
/// real advance widths and side bearings, not the fallback font's uniform
/// boxes.
///
/// Registers the bytes under the family name `'Roboto'` by default —
/// [LayrzThemeData.light]'s default [LayrzTextTheme] already requests that
/// exact family name via [LayrzRobotoFont], so a themed widget picks up the
/// real glyph metrics with no theme override needed at the call site.
///
/// Must be called inside [WidgetTester.runAsync] — [File.readAsBytes] is
/// real (non-fake) async I/O, which never resolves inside the fake-async
/// zone `testWidgets` normally runs its body in.
Future<void> loadRealRobotoFont(WidgetTester tester, {String family = 'Roboto'}) async {
  await tester.runAsync(() async {
    // `flutter test` (and CI) always runs with the package root as the
    // working directory, so this relative path is stable across machines
    // and does not depend on where the Flutter SDK itself is installed.
    final fontFile = File('${Directory.current.path}/test/badges/fixtures/Roboto-Regular.ttf');
    final bytes = await fontFile.readAsBytes();
    final fontLoader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  });
}

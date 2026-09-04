import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('registerWebFont (non-web target)', () {
    // `flutter test` runs on the VM, where `dart.library.js_interop` is unavailable,
    // so `register_web_font.dart`'s conditional export resolves to the native stub in
    // `register_web_font_stub.dart` — the real `package:web` implementation in
    // `register_web_font_web.dart` cannot execute here. This test exercises exactly
    // the stub: a genuine no-op that never touches the DOM.
    test('completes without error and requires no DOM', () async {
      await expectLater(
        registerWebFont(family: 'Some Font', url: 'https://example.com/font.ttf'),
        completes,
      );
    });

    test('is safe to call repeatedly with the same family', () async {
      await registerWebFont(family: 'Repeated Font', url: 'https://example.com/font.ttf');
      await expectLater(
        registerWebFont(family: 'Repeated Font', url: 'https://example.com/font.ttf'),
        completes,
      );
    });
  });

  group('registerWebFontFromBytes (non-web target)', () {
    // As above, `flutter test` on the VM resolves to `register_web_font_stub.dart`'s
    // no-op — the real `package:web` `FontFace`-from-bytes implementation in
    // `register_web_font_web.dart` requires a browser DOM and cannot execute here.
    // This test exercises exactly the stub, confirming the bundled-asset entry point
    // is a genuine no-op that never touches the DOM, mirroring the URL-based case
    // above.
    test('completes without error and requires no DOM', () async {
      final bytes = ByteData(4);
      await expectLater(
        registerWebFontFromBytes(family: 'Some Bundled Font', bytes: bytes),
        completes,
      );
    });

    test('is safe to call repeatedly with the same family', () async {
      final bytes = ByteData(4);
      await registerWebFontFromBytes(family: 'Repeated Bundled Font', bytes: bytes);
      await expectLater(
        registerWebFontFromBytes(family: 'Repeated Bundled Font', bytes: bytes),
        completes,
      );
    });
  });
}

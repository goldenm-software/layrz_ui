import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A minimal test implementation of [LayrzFontHandler] for testing the contract.
class _TestFontHandler extends LayrzFontHandler {
  /// Fallback families for testing.
  static const List<String> _testFallbacks = ['TestFont', 'Fallback'];

  const _TestFontHandler();

  @override
  Future<void> preload(LayrzFont font) async {
    // No-op implementation for testing.
  }

  @override
  String resolveFamily(LayrzFont font) {
    // Return the font name as-is for testing.
    return font.name;
  }

  @override
  List<String> get fallbacks => _testFallbacks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LayrzFontHandler contract', () {
    test('concrete subclass can be const-constructed', () {
      const handler = _TestFontHandler();
      expect(handler, isNotNull);
    });

    test('resolveFamily is reachable polymorphically', () {
      const LayrzFontHandler handler = _TestFontHandler();
      const font = LayrzFont(
        source: LayrzFontSource.local,
        name: 'TestFamily',
      );

      final resolved = handler.resolveFamily(font);
      expect(resolved, equals('TestFamily'));
    });

    test('preload is reachable polymorphically', () async {
      const LayrzFontHandler handler = _TestFontHandler();
      const font = LayrzFont(
        source: LayrzFontSource.local,
        name: 'TestFont',
      );

      await expectLater(handler.preload(font), completes);
    });

    test('fallbacks are reachable polymorphically', () {
      const LayrzFontHandler handler = _TestFontHandler();
      expect(handler.fallbacks, isNotEmpty);
      expect(handler.fallbacks, isA<List<String>>());
    });

    test('LayrzGoogleFontsHandler is a LayrzFontHandler', () {
      const handler = LayrzGoogleFontsHandler();
      expect(handler, isA<LayrzFontHandler>());
    });

    test('all required methods exist on concrete subclass', () {
      const LayrzFontHandler handler = _TestFontHandler();

      // Verify all methods are callable without error.
      expect(handler.resolveFamily, isNotNull);
      expect(handler.preload, isNotNull);
      expect(handler.fallbacks, isNotNull);
      expect(handler.resolveFamilyForWeight, isNotNull);
    });

    test('resolveFamilyForWeight default implementation delegates to resolveFamily', () {
      const handler = _TestFontHandler();
      const font = LayrzFont(
        source: LayrzFontSource.local,
        name: 'TestFamily',
      );

      // The default implementation should delegate to resolveFamily,
      // which in _TestFontHandler returns the font name.
      final resolved = handler.resolveFamilyForWeight(font, FontWeight.w700);
      expect(resolved, equals('TestFamily'));
    });
  });
}

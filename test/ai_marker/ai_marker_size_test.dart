import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzAiMarkerSize', () {
    test('exposes exactly two values: small and big', () {
      expect(LayrzAiMarkerSize.values, [LayrzAiMarkerSize.small, LayrzAiMarkerSize.big]);
    });
  });
}

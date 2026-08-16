import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants.dart';

void main() {
  group('Grid Breakpoints', () {
    test('kExtraSmallGrid is 600', () {
      expect(kExtraSmallGrid, equals(600));
    });

    test('kSmallGrid is 960', () {
      expect(kSmallGrid, equals(960));
    });

    test('kMediumGrid is 1264', () {
      expect(kMediumGrid, equals(1264));
    });

    test('kLargeGrid is 1904', () {
      expect(kLargeGrid, equals(1904));
    });

    test('breakpoints are strictly ascending', () {
      expect(kExtraSmallGrid < kSmallGrid, isTrue);
      expect(kSmallGrid < kMediumGrid, isTrue);
      expect(kMediumGrid < kLargeGrid, isTrue);
    });
  });
}

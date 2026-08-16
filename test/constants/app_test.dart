import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants.dart';

void main() {
  group('App Metadata', () {
    test('kAppTitle is Layrz', () {
      expect(kAppTitle, equals('Layrz'));
    });
  });
}

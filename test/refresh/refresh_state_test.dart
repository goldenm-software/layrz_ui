import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';

void main() {
  group('LayrzRefreshState', () {
    test('has exactly the four lifecycle states in order', () {
      expect(LayrzRefreshState.values, [
        LayrzRefreshState.idle,
        LayrzRefreshState.armed,
        LayrzRefreshState.refreshing,
        LayrzRefreshState.settling,
      ]);
    });

    test('each value is distinct', () {
      expect(LayrzRefreshState.values.toSet().length, LayrzRefreshState.values.length);
    });
  });
}

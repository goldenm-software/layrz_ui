import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayoEmotion', () {
    test('has exactly the ten currently-implemented values, in the documented order', () {
      expect(LayoEmotion.values, [
        LayoEmotion.mrLayo,
        LayoEmotion.question,
        LayoEmotion.sleep,
        LayoEmotion.dead,
        LayoEmotion.love,
        LayoEmotion.angry,
        LayoEmotion.alert,
        LayoEmotion.layo404,
        LayoEmotion.idea,
        LayoEmotion.comandante,
      ]);
    });

    test('mrLayo is the first (and default) value', () {
      expect(LayoEmotion.values.first, LayoEmotion.mrLayo);
    });
  });
}

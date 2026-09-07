import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayoEmotion', () {
    test('has exactly the twenty-four currently-implemented values, in the documented order', () {
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
        LayoEmotion.money,
        LayoEmotion.thinking,
        LayoEmotion.listening,
        LayoEmotion.sad,
        LayoEmotion.success,
        LayoEmotion.excited,
        LayoEmotion.searching,
        LayoEmotion.working,
        LayoEmotion.wink,
        LayoEmotion.mindBlown,
        LayoEmotion.smug,
        LayoEmotion.cool,
        LayoEmotion.christmas,
        LayoEmotion.party,
      ]);
    });

    test('mrLayo is the first (and default) value', () {
      expect(LayoEmotion.values.first, LayoEmotion.mrLayo);
    });
  });
}

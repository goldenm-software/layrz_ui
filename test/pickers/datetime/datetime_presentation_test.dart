import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzDateTimeInputPresentation', () {
    test('has exactly two values: tabbed and stepped', () {
      expect(LayrzDateTimeInputPresentation.values, hasLength(2));
      expect(LayrzDateTimeInputPresentation.values, contains(LayrzDateTimeInputPresentation.tabbed));
      expect(LayrzDateTimeInputPresentation.values, contains(LayrzDateTimeInputPresentation.stepped));
    });

    test('values compare equal to themselves and not to each other', () {
      expect(LayrzDateTimeInputPresentation.tabbed, LayrzDateTimeInputPresentation.tabbed);
      expect(LayrzDateTimeInputPresentation.stepped, LayrzDateTimeInputPresentation.stepped);
      expect(LayrzDateTimeInputPresentation.tabbed == LayrzDateTimeInputPresentation.stepped, isFalse);
    });

    test('name matches the declared enum value name', () {
      expect(LayrzDateTimeInputPresentation.tabbed.name, 'tabbed');
      expect(LayrzDateTimeInputPresentation.stepped.name, 'stepped');
    });
  });
}

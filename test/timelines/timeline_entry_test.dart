import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTimelineEntry', () {
    test('requires only labelText, leaving every other field null', () {
      const entry = LayrzTimelineEntry(labelText: 'Order placed');

      expect(entry.labelText, 'Order placed');
      expect(entry.descriptionText, isNull);
      expect(entry.timestampText, isNull);
      expect(entry.icon, isNull);
      expect(entry.accentColor, isNull);
      expect(entry.side, isNull);
      expect(entry.content, isNull);
    });

    test('accepts every optional field', () {
      const content = SizedBox(width: 10, height: 10);
      const entry = LayrzTimelineEntry(
        labelText: 'Order shipped',
        descriptionText: 'Package left the warehouse',
        timestampText: 'Aug 28, 2026',
        icon: MdiIcons.truckOutline,
        accentColor: Color(0xFF00FF00),
        side: LayrzTimelineSide.end,
        content: content,
      );

      expect(entry.labelText, 'Order shipped');
      expect(entry.descriptionText, 'Package left the warehouse');
      expect(entry.timestampText, 'Aug 28, 2026');
      expect(entry.icon, MdiIcons.truckOutline);
      expect(entry.accentColor, const Color(0xFF00FF00));
      expect(entry.side, LayrzTimelineSide.end);
      expect(entry.content, same(content));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzTimelineEntry(labelText: 'Original', descriptionText: 'Desc');
      final copy = original.copyWith(labelText: 'Updated');

      expect(copy.labelText, 'Updated');
      expect(copy.descriptionText, 'Desc');
    });

    test('copyWith with no arguments returns an equal entry', () {
      const original = LayrzTimelineEntry(labelText: 'Same', descriptionText: 'Desc', timestampText: 'Now');
      final copy = original.copyWith();

      expect(copy, original);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzTimelineEntry(labelText: 'A', descriptionText: 'X', timestampText: 'Y');
      const b = LayrzTimelineEntry(labelText: 'A', descriptionText: 'X', timestampText: 'Y');
      const c = LayrzTimelineEntry(labelText: 'A', descriptionText: 'Z');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('identical instances are equal', () {
      const entry = LayrzTimelineEntry(labelText: 'Same instance');
      expect(entry, same(entry));
      expect(entry == entry, isTrue);
    });

    test('is not equal to a different runtime type', () {
      const entry = LayrzTimelineEntry(labelText: 'Entry');
      // ignore: unrelated_type_equality_checks
      expect(entry == 'Entry', isFalse);
    });
  });
}

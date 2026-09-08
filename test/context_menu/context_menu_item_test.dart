import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzContextMenuEntry', () {
    test('defaults enabled to true and icon/color to null', () {
      const entry = LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop);
      expect(entry.labelText, 'Copy');
      expect(entry.enabled, isTrue);
      expect(entry.icon, isNull);
      expect(entry.color, isNull);
    });

    test('stores every explicit field', () {
      const icon = IconData(0xE000, fontFamily: 'test');
      const color = Color(0xFF00FF00);
      const entry = LayrzContextMenuEntry(
        labelText: 'Delete',
        onTap: _noop,
        icon: icon,
        enabled: false,
        color: color,
      );

      expect(entry.labelText, 'Delete');
      expect(entry.icon, icon);
      expect(entry.enabled, isFalse);
      expect(entry.color, color);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop);
      const b = LayrzContextMenuEntry(labelText: 'Copy', onTap: _noop);
      const c = LayrzContextMenuEntry(labelText: 'Paste', onTap: _noop);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });
  });

  group('LayrzContextMenuLabel', () {
    test('defaults color to null', () {
      const label = LayrzContextMenuLabel(labelText: 'Section');
      expect(label.labelText, 'Section');
      expect(label.color, isNull);
    });

    test('stores an explicit color', () {
      const color = Color(0xFF123456);
      const label = LayrzContextMenuLabel(labelText: 'Section', color: color);
      expect(label.color, color);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzContextMenuLabel(labelText: 'Section');
      const b = LayrzContextMenuLabel(labelText: 'Section');
      const c = LayrzContextMenuLabel(labelText: 'Other');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });
  });

  group('LayrzContextMenuDivider', () {
    test('is a value type with no fields', () {
      const a = LayrzContextMenuDivider();
      const b = LayrzContextMenuDivider();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LayrzContextMenuItem sealed hierarchy', () {
    test('a switch over LayrzContextMenuItem is exhaustive for all three subtypes', () {
      const items = <LayrzContextMenuItem>[
        LayrzContextMenuEntry(labelText: 'A', onTap: _noop),
        LayrzContextMenuLabel(labelText: 'B'),
        LayrzContextMenuDivider(),
      ];

      final kinds = items
          .map(
            (item) => switch (item) {
              LayrzContextMenuEntry() => 'entry',
              LayrzContextMenuLabel() => 'label',
              LayrzContextMenuDivider() => 'divider',
            },
          )
          .toList();

      expect(kinds, ['entry', 'label', 'divider']);
    });
  });
}

void _noop() {}

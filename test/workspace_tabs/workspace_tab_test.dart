import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzWorkspaceTab — construction', () {
    test('defaults closable to true, icon to null, and right to null', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox());

      expect(tab.id, 'a');
      expect(tab.label, 'A');
      expect(tab.icon, isNull);
      expect(tab.closable, isTrue);
      expect(tab.right, isNull);
      expect(tab.isSplit, isFalse);
    });

    test('carries every explicitly provided field', () {
      const left = SizedBox(width: 1);
      const right = SizedBox(width: 2);
      const tab = LayrzWorkspaceTab(
        id: 'b',
        label: 'B',
        icon: MdiIcons.file,
        closable: false,
        left: left,
        right: right,
      );

      expect(tab.id, 'b');
      expect(tab.label, 'B');
      expect(tab.icon, MdiIcons.file);
      expect(tab.closable, isFalse);
      expect(tab.left, left);
      expect(tab.right, right);
      expect(tab.isSplit, isTrue);
    });
  });

  group('LayrzWorkspaceTab — copyWith', () {
    test('replaces only the given fields', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', closable: false, left: SizedBox());
      final copy = tab.copyWith(label: 'Renamed');

      expect(copy.id, 'a');
      expect(copy.label, 'Renamed');
      expect(copy.closable, isFalse);
      expect(copy.left, tab.left);
    });

    test('with no arguments returns an equal copy', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file, closable: false, left: SizedBox());
      final copy = tab.copyWith();

      expect(copy, tab);
    });

    test('replaces left and right independently', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox());
      const newRight = SizedBox(width: 5);
      final copy = tab.copyWith(right: newRight);

      expect(copy.left, tab.left);
      expect(copy.right, newRight);
      expect(copy.isSplit, isTrue);
    });
  });

  group('LayrzWorkspaceTab — equality', () {
    test('two tabs with identical fields are equal and share a hashCode', () {
      const left = SizedBox();
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file, left: left);
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file, left: left);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different id makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'Same', left: SizedBox());
      const b = LayrzWorkspaceTab(id: 'b', label: 'Same', left: SizedBox());

      expect(a, isNot(b));
    });

    test('a different label makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox());
      const b = LayrzWorkspaceTab(id: 'a', label: 'B', left: SizedBox());

      expect(a, isNot(b));
    });

    test('a different closable value makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', closable: true, left: SizedBox());
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', closable: false, left: SizedBox());

      expect(a, isNot(b));
    });

    test('a different icon makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file, left: SizedBox());
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.folder, left: SizedBox());

      expect(a, isNot(b));
    });

    test('a different left makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox(width: 1));
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox(width: 2));

      expect(a, isNot(b));
    });

    test('a null right vs. a non-null right makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox());
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', left: SizedBox(), right: SizedBox());

      expect(a, isNot(b));
    });
  });
}

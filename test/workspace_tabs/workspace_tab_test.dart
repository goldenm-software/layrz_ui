import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzWorkspaceTab — construction', () {
    test('defaults closable to true and icon to null', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A');

      expect(tab.id, 'a');
      expect(tab.label, 'A');
      expect(tab.icon, isNull);
      expect(tab.closable, isTrue);
    });

    test('carries every explicitly provided field', () {
      const tab = LayrzWorkspaceTab(id: 'b', label: 'B', icon: MdiIcons.file, closable: false);

      expect(tab.id, 'b');
      expect(tab.label, 'B');
      expect(tab.icon, MdiIcons.file);
      expect(tab.closable, isFalse);
    });
  });

  group('LayrzWorkspaceTab — copyWith', () {
    test('replaces only the given fields', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', closable: false);
      final copy = tab.copyWith(label: 'Renamed');

      expect(copy.id, 'a');
      expect(copy.label, 'Renamed');
      expect(copy.closable, isFalse);
    });

    test('with no arguments returns an equal copy', () {
      const tab = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file, closable: false);
      final copy = tab.copyWith();

      expect(copy, tab);
    });
  });

  group('LayrzWorkspaceTab — equality', () {
    test('two tabs with identical fields are equal and share a hashCode', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file);
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different id makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'Same');
      const b = LayrzWorkspaceTab(id: 'b', label: 'Same');

      expect(a, isNot(b));
    });

    test('a different label makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A');
      const b = LayrzWorkspaceTab(id: 'a', label: 'B');

      expect(a, isNot(b));
    });

    test('a different closable value makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', closable: true);
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', closable: false);

      expect(a, isNot(b));
    });

    test('a different icon makes two otherwise-identical tabs unequal', () {
      const a = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.file);
      const b = LayrzWorkspaceTab(id: 'a', label: 'A', icon: MdiIcons.folder);

      expect(a, isNot(b));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSelectableAction', () {
    test('copy built-in action has correct type', () {
      expect(LayrzSelectableAction.copy.type, 'copy');
    });

    test('cut built-in action has correct type', () {
      expect(LayrzSelectableAction.cut.type, 'cut');
    });

    test('paste built-in action has correct type', () {
      expect(LayrzSelectableAction.paste.type, 'paste');
    });

    test('selectAll built-in action has correct type', () {
      expect(LayrzSelectableAction.selectAll.type, 'selectAll');
    });

    test('custom action has custom type', () {
      final action = LayrzSelectableAction(
        label: (l10n) => 'Test',
        onPressed: () {},
      );
      expect(action.type, 'custom');
    });

    test('equal built-in actions are equal', () {
      expect(LayrzSelectableAction.copy, LayrzSelectableAction.copy);
      expect(LayrzSelectableAction.copy == LayrzSelectableAction.copy, true);
    });

    test('different built-in actions are not equal', () {
      expect(LayrzSelectableAction.copy == LayrzSelectableAction.cut, false);
    });

    test('equal built-in actions have same hash', () {
      expect(
        LayrzSelectableAction.copy.hashCode,
        LayrzSelectableAction.copy.hashCode,
      );
    });

    test('built-in actions deduplicate in a Set', () {
      final copyAction = LayrzSelectableAction.copy;
      final actions = {copyAction, copyAction, LayrzSelectableAction.cut};
      expect(actions.length, 2);
      expect(actions.contains(LayrzSelectableAction.copy), true);
      expect(actions.contains(LayrzSelectableAction.cut), true);
    });

    test('defaults set contains all four built-ins', () {
      expect(LayrzSelectableAction.defaults.length, 4);
      expect(LayrzSelectableAction.defaults.contains(LayrzSelectableAction.copy), true);
      expect(LayrzSelectableAction.defaults.contains(LayrzSelectableAction.cut), true);
      expect(LayrzSelectableAction.defaults.contains(LayrzSelectableAction.paste), true);
      expect(LayrzSelectableAction.defaults.contains(LayrzSelectableAction.selectAll), true);
    });

    test('distinct custom actions coexist in a Set', () {
      final action1 = LayrzSelectableAction(
        label: (l10n) => 'Custom 1',
        onPressed: () {},
      );
      final action2 = LayrzSelectableAction(
        label: (l10n) => 'Custom 2',
        onPressed: () {},
      );
      // Custom actions deduplicate only by reference identity, not by type
      expect(action1 == action2, false);

      // In a set, both distinct custom actions survive
      final set = {action1, action2};
      expect(set.length, 2);
      expect(set.contains(action1), true);
      expect(set.contains(action2), true);
    });

    test('same custom action instance dedupes in a Set', () {
      final action = LayrzSelectableAction(
        label: (l10n) => 'Custom',
        onPressed: () {},
      );
      // Adding the same instance twice dedupes
      final set = {action, action};
      expect(set.length, 1);
    });

    test('custom action can have icon', () {
      final action = LayrzSelectableAction(
        label: (l10n) => 'Custom',
        onPressed: () {},
        icon: Icons.check,
      );
      expect(action.icon, Icons.check);
    });

    test('label function works', () {
      final l10n = LayrzUiL10nDefault();
      expect(LayrzSelectableAction.copy.label(l10n), isNotEmpty);
      expect(LayrzSelectableAction.cut.label(l10n), isNotEmpty);
      expect(LayrzSelectableAction.paste.label(l10n), isNotEmpty);
      expect(LayrzSelectableAction.selectAll.label(l10n), isNotEmpty);
    });
  });
}

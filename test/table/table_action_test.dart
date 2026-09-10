import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/table/src/table_action.dart';

void _onTap() {}
void _otherOnTap() {}

void main() {
  group('LayrzTableAction', () {
    test('constructor assigns every field and applies the disabled default', () {
      final action = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

      expect(action.icon, MockIcon.icon);
      expect(action.labelText, 'Edit');
      expect(action.onTap, _onTap);
      expect(action.style, isNull);
      expect(action.color, isNull);
      expect(action.disabled, isFalse);
    });

    test('constructor honors explicit style, color and disabled', () {
      final action = LayrzTableAction(
        icon: MockIcon.icon,
        labelText: 'Delete',
        onTap: _onTap,
        style: LayrzButtonStyle.outlined,
        color: const Color(0xFFFF0000),
        disabled: true,
      );

      expect(action.style, LayrzButtonStyle.outlined);
      expect(action.color, const Color(0xFFFF0000));
      expect(action.disabled, isTrue);
    });

    group('copyWith', () {
      test('replaces only the given fields', () {
        final original = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

        final copy = original.copyWith(labelText: 'Renamed', disabled: true);

        expect(copy.labelText, 'Renamed');
        expect(copy.disabled, isTrue);
        expect(copy.icon, original.icon);
        expect(copy.onTap, original.onTap);
        expect(copy.style, original.style);
        expect(copy.color, original.color);
      });

      test('with no arguments returns a field-equal copy', () {
        final original = LayrzTableAction(
          icon: MockIcon.icon,
          labelText: 'Edit',
          onTap: _onTap,
          style: LayrzButtonStyle.filled,
          color: const Color(0xFF00FF00),
          disabled: true,
        );

        final copy = original.copyWith();

        expect(copy, original);
        expect(identical(copy, original), isFalse);
      });

      test('replaces onTap, style and color independently', () {
        final original = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

        final copy = original.copyWith(
          onTap: _otherOnTap,
          style: LayrzButtonStyle.filledFab,
          color: const Color(0xFF0000FF),
        );

        expect(copy.onTap, _otherOnTap);
        expect(copy.style, LayrzButtonStyle.filledFab);
        expect(copy.color, const Color(0xFF0000FF));
        expect(copy.labelText, original.labelText);
        expect(copy.icon, original.icon);
      });
    });

    group('equality', () {
      test('two actions with identical field values are equal and share hashCode', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);
        final b = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('actions differing only in labelText are unequal', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);
        final b = LayrzTableAction(icon: MockIcon.icon, labelText: 'Delete', onTap: _onTap);

        expect(a == b, isFalse);
      });

      test('actions differing only in onTap identity are unequal', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);
        final b = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _otherOnTap);

        expect(a == b, isFalse);
      });

      test('actions differing only in disabled are unequal', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);
        final b = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap, disabled: true);

        expect(a == b, isFalse);
      });

      test('actions differing only in color are unequal', () {
        final a = LayrzTableAction(
          icon: MockIcon.icon,
          labelText: 'Edit',
          onTap: _onTap,
          color: const Color(0xFFFF0000),
        );
        final b = LayrzTableAction(
          icon: MockIcon.icon,
          labelText: 'Edit',
          onTap: _onTap,
          color: const Color(0xFF00FF00),
        );

        expect(a == b, isFalse);
      });

      test('an action is equal to itself (identical)', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

        expect(a == a, isTrue);
      });

      test('an action is not equal to an unrelated object', () {
        final a = LayrzTableAction(icon: MockIcon.icon, labelText: 'Edit', onTap: _onTap);

        // ignore: unrelated_type_equality_checks
        expect(a == 'not an action', isFalse);
      });
    });
  });
}

/// Minimal stand-in for a real `IconData` constant, since [LayrzTableAction]
/// only needs a valid `IconData` value and this module does not own an icon
/// font. Uses `IconData`'s own const constructor directly.
abstract final class MockIcon {
  static const IconData icon = IconData(0xE000);
}

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_type.dart';

void main() {
  group('LayrzSnackbar', () {
    group('two-way custom assertion', () {
      test('custom type without icon and color throws in debug mode', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            type: LayrzSnackbarType.custom,
          ),
          throwsAssertionError,
        );
      });

      test('custom type with only icon (no color) throws in debug mode', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            type: LayrzSnackbarType.custom,
            icon: MdiIcons.star,
          ),
          throwsAssertionError,
        );
      });

      test('custom type with only color (no icon) throws in debug mode', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            type: LayrzSnackbarType.custom,
            color: const Color(0xFF123456),
          ),
          throwsAssertionError,
        );
      });

      test('custom type with both icon and color does not throw', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            type: LayrzSnackbarType.custom,
            icon: MdiIcons.star,
            color: const Color(0xFF123456),
          ),
          returnsNormally,
        );
      });

      test('non-custom type with a non-null icon throws in debug mode', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            icon: MdiIcons.star,
          ),
          throwsAssertionError,
        );
      });

      test('non-custom type with a non-null color throws in debug mode', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            color: const Color(0xFF123456),
          ),
          throwsAssertionError,
        );
      });

      test('non-custom type with both icon and color null does not throw', () {
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            type: LayrzSnackbarType.danger,
          ),
          returnsNormally,
        );
      });
    });

    group('defaults', () {
      test('type defaults to success', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(snackbar.type, equals(LayrzSnackbarType.success));
      });

      test('duration defaults to a flat 10 seconds', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(snackbar.duration, equals(const Duration(seconds: 10)));
      });

      test('duration default is the same 10 seconds regardless of type', () {
        for (final type in LayrzSnackbarType.values) {
          final snackbar = type == LayrzSnackbarType.custom
              ? LayrzSnackbar(
                  titleText: 'Title',
                  descriptionText: 'Description',
                  type: type,
                  icon: MdiIcons.star,
                  color: const Color(0xFF123456),
                )
              : LayrzSnackbar(titleText: 'Title', descriptionText: 'Description', type: type);

          expect(snackbar.duration, equals(const Duration(seconds: 10)), reason: 'type: $type');
        }
      });

      test('onTap defaults to null', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(snackbar.onTap, isNull);
      });

      test('actions defaults to an empty list', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(snackbar.actions, isEmpty);
      });
    });

    group('isPersistent / isAutoDismiss', () {
      test('a null duration makes the snackbar persistent', () {
        const snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: null,
        );

        expect(snackbar.isPersistent, isTrue);
        expect(snackbar.isAutoDismiss, isFalse);
      });

      test('the default duration makes the snackbar auto-dismiss', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(snackbar.isPersistent, isFalse);
        expect(snackbar.isAutoDismiss, isTrue);
      });

      test('an explicit non-null duration makes the snackbar auto-dismiss', () {
        const snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: Duration(seconds: 30),
        );

        expect(snackbar.isPersistent, isFalse);
        expect(snackbar.isAutoDismiss, isTrue);
      });
    });

    group('actions', () {
      test('a list of LayrzButtons is stored as given', () {
        final action = LayrzButton(labelText: 'Manage rule', onTap: () {});
        final snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [action],
        );

        expect(snackbar.actions, equals([action]));
      });

      test('multiple LayrzButtons are all stored', () {
        final manageAction = LayrzButton(labelText: 'Manage rule', onTap: () {});
        final dismissAction = LayrzButton(labelText: 'Dismiss', onTap: () {});
        final snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [manageAction, dismissAction],
        );

        expect(snackbar.actions, equals([manageAction, dismissAction]));
        expect(snackbar.actions, hasLength(2));
      });

      test('copyWith replaces the actions list', () {
        final originalAction = LayrzButton(labelText: 'Original', onTap: () {});
        final replacementAction = LayrzButton(labelText: 'Replacement', onTap: () {});
        final snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [originalAction],
        );

        final copy = snackbar.copyWith(actions: [replacementAction]);

        expect(copy.actions, equals([replacementAction]));
      });

      test('copyWith preserves actions when not overridden', () {
        final action = LayrzButton(labelText: 'Manage rule', onTap: () {});
        final snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [action],
        );

        final copy = snackbar.copyWith(titleText: 'New title');

        expect(copy.actions, equals([action]));
      });
    });

    group('copyWith', () {
      test('replaces only the given fields', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final copy = snackbar.copyWith(titleText: 'New title');

        expect(copy.titleText, equals('New title'));
        expect(copy.descriptionText, equals(snackbar.descriptionText));
        expect(copy.type, equals(snackbar.type));
        expect(copy.duration, equals(snackbar.duration));
      });

      test('preserves unset fields identically', () {
        const snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: Duration(seconds: 5),
        );

        final copy = snackbar.copyWith(descriptionText: 'New description');

        expect(copy.duration, equals(const Duration(seconds: 5)));
        expect(copy.descriptionText, equals('New description'));
      });

      test('omitting duration keeps the current value', () {
        const snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: Duration(seconds: 20),
        );

        final copy = snackbar.copyWith(titleText: 'New title');

        expect(copy.duration, equals(const Duration(seconds: 20)));
      });

      test('passing a new duration replaces the current value', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final copy = snackbar.copyWith(duration: const Duration(seconds: 45));

        expect(copy.duration, equals(const Duration(seconds: 45)));
      });

      test('passing duration: null explicitly clears it to persistent', () {
        const snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: Duration(seconds: 20),
        );

        final copy = snackbar.copyWith(duration: null);

        expect(copy.duration, isNull);
        expect(copy.isPersistent, isTrue);
      });

      test('clearing duration to null via copyWith preserves other fields', () {
        final action = LayrzButton(labelText: 'Dismiss', onTap: () {});
        final snackbar = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          type: LayrzSnackbarType.warning,
          actions: [action],
        );

        final copy = snackbar.copyWith(duration: null);

        expect(copy.duration, isNull);
        expect(copy.titleText, equals('Title'));
        expect(copy.type, equals(LayrzSnackbarType.warning));
        expect(copy.actions, equals([action]));
      });
    });

    group('equality', () {
      test('two snackbars with identical fields are equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('snackbars differing by titleText are not equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(titleText: 'Other title', descriptionText: 'Description');

        expect(a, isNot(equals(b)));
      });

      test('snackbars differing by type are not equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          type: LayrzSnackbarType.danger,
        );

        expect(a, isNot(equals(b)));
      });

      test('snackbars differing by duration are not equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          duration: Duration(seconds: 30),
        );

        expect(a, isNot(equals(b)));
      });

      test('a persistent (null duration) snackbar is not equal to an auto-dismiss one', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description', duration: null);

        expect(a, isNot(equals(b)));
      });

      test('two persistent snackbars with identical fields are equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description', duration: null);
        const b = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description', duration: null);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('snackbars with the same empty actions list are equal', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('snackbars differing by actions are not equal', () {
        final action = LayrzButton(labelText: 'Manage rule', onTap: () {});
        final a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        final b = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [action],
        );

        expect(a, isNot(equals(b)));
      });

      test('snackbars with the same action instances (in the same order) are equal', () {
        final action = LayrzButton(labelText: 'Manage rule', onTap: () {});
        final a = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [action],
        );
        final b = LayrzSnackbar(
          titleText: 'Title',
          descriptionText: 'Description',
          actions: [action],
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}

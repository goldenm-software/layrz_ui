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
        // Genuine no-throw contract: paired with the three throwsAssertionError
        // cases above, this confirms the one valid `custom`-type combination
        // (both icon and color provided) does not trip the constructor assert.
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
        // Genuine no-throw contract: paired with the two throwsAssertionError
        // cases above, this confirms the valid non-custom combination (neither
        // icon nor color provided) does not trip the constructor assert.
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

    group('titleText / titleRich mutual exclusion', () {
      test('titleText alone (titleRich null) constructs normally', () {
        expect(
          () => const LayrzSnackbar(titleText: 'Title', descriptionText: 'Description'),
          returnsNormally,
        );
      });

      test('titleRich alone (titleText null) constructs normally', () {
        expect(
          () => const LayrzSnackbar(
            titleRich: TextSpan(text: 'Title'),
            descriptionText: 'Description',
          ),
          returnsNormally,
        );
      });

      test('supplying both titleText and titleRich throws in debug mode', () {
        // Not `const` here: a const expression that fails a constructor assert
        // is a compile-time error, not the runtime AssertionError this test
        // exercises — so this must be a plain (non-const) invocation.
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            titleRich: const TextSpan(text: 'Title'),
            descriptionText: 'Description',
          ),
          throwsAssertionError,
        );
      });

      test('supplying neither titleText nor titleRich throws in debug mode', () {
        expect(
          () => LayrzSnackbar(descriptionText: 'Description'),
          throwsAssertionError,
        );
      });
    });

    group('descriptionText / descriptionRich mutual exclusion', () {
      test('descriptionText alone (descriptionRich null) constructs normally', () {
        expect(
          () => const LayrzSnackbar(titleText: 'Title', descriptionText: 'Description'),
          returnsNormally,
        );
      });

      test('descriptionRich alone (descriptionText null) constructs normally', () {
        expect(
          () => const LayrzSnackbar(
            titleText: 'Title',
            descriptionRich: TextSpan(text: 'Description'),
          ),
          returnsNormally,
        );
      });

      test('supplying both descriptionText and descriptionRich throws in debug mode', () {
        // Not `const` here — see the matching titleText/titleRich case above.
        expect(
          () => LayrzSnackbar(
            titleText: 'Title',
            descriptionText: 'Description',
            descriptionRich: const TextSpan(text: 'Description'),
          ),
          throwsAssertionError,
        );
      });

      test('supplying neither descriptionText nor descriptionRich throws in debug mode', () {
        expect(
          () => LayrzSnackbar(titleText: 'Title'),
          throwsAssertionError,
        );
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

      test('omitting title/description params keeps the current text pair unchanged', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final copy = snackbar.copyWith(type: LayrzSnackbarType.danger);

        expect(copy.titleText, equals('Title'));
        expect(copy.titleRich, isNull);
        expect(copy.descriptionText, equals('Description'));
        expect(copy.descriptionRich, isNull);
      });

      test('passing titleRich switches the title to rich and drops titleText', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final copy = snackbar.copyWith(titleRich: const TextSpan(text: 'Rich title'));

        expect(copy.titleText, isNull);
        expect(copy.titleRich, equals(const TextSpan(text: 'Rich title')));
        expect(copy.descriptionText, equals('Description'));
      });

      test('passing titleText back switches the title from rich to plain and drops titleRich', () {
        const richSnackbar = LayrzSnackbar(
          titleRich: TextSpan(text: 'Rich title'),
          descriptionText: 'Description',
        );

        final copy = richSnackbar.copyWith(titleText: 'Plain title');

        expect(copy.titleRich, isNull);
        expect(copy.titleText, equals('Plain title'));
      });

      test('passing descriptionRich switches the description to rich and drops descriptionText', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final copy = snackbar.copyWith(descriptionRich: const TextSpan(text: 'Rich description'));

        expect(copy.descriptionText, isNull);
        expect(copy.descriptionRich, equals(const TextSpan(text: 'Rich description')));
        expect(copy.titleText, equals('Title'));
      });

      test(
        'passing descriptionText back switches the description from rich to plain and drops '
        'descriptionRich',
        () {
          const richSnackbar = LayrzSnackbar(
            titleText: 'Title',
            descriptionRich: TextSpan(text: 'Rich description'),
          );

          final copy = richSnackbar.copyWith(descriptionText: 'Plain description');

          expect(copy.descriptionRich, isNull);
          expect(copy.descriptionText, equals('Plain description'));
        },
      );

      test('flipping title to rich and back to text round-trips to the original plain value', () {
        const snackbar = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');

        final toRich = snackbar.copyWith(titleRich: const TextSpan(text: 'Rich'));
        final backToText = toRich.copyWith(titleText: 'Title');

        expect(backToText.titleText, equals('Title'));
        expect(backToText.titleRich, isNull);
        expect(backToText, equals(snackbar));
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

      test('two snackbars built from the same titleRich span are equal', () {
        const a = LayrzSnackbar(
          titleRich: TextSpan(text: 'Rich title'),
          descriptionText: 'Description',
        );
        const b = LayrzSnackbar(
          titleRich: TextSpan(text: 'Rich title'),
          descriptionText: 'Description',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('snackbars differing by titleRich content are not equal', () {
        const a = LayrzSnackbar(
          titleRich: TextSpan(text: 'Rich title A'),
          descriptionText: 'Description',
        );
        const b = LayrzSnackbar(
          titleRich: TextSpan(text: 'Rich title B'),
          descriptionText: 'Description',
        );

        expect(a, isNot(equals(b)));
      });

      test('a plain titleText snackbar is not equal to an equivalent titleRich one', () {
        const a = LayrzSnackbar(titleText: 'Title', descriptionText: 'Description');
        const b = LayrzSnackbar(
          titleRich: TextSpan(text: 'Title'),
          descriptionText: 'Description',
        );

        expect(a, isNot(equals(b)));
      });

      test('two snackbars built from the same descriptionRich span are equal', () {
        const a = LayrzSnackbar(
          titleText: 'Title',
          descriptionRich: TextSpan(text: 'Rich description'),
        );
        const b = LayrzSnackbar(
          titleText: 'Title',
          descriptionRich: TextSpan(text: 'Rich description'),
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('snackbars differing by descriptionRich content are not equal', () {
        const a = LayrzSnackbar(
          titleText: 'Title',
          descriptionRich: TextSpan(text: 'Rich description A'),
        );
        const b = LayrzSnackbar(
          titleText: 'Title',
          descriptionRich: TextSpan(text: 'Rich description B'),
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

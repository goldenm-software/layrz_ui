import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10n', () {
    group('LayrzUiL10nDefault', () {
      late LayrzUiL10n localizations;

      setUp(() {
        localizations = LayrzUiL10nDefault();
      });

      test('returns English default for each key', () {
        // Actions & Confirmations (12 keys)
        expect(localizations.actionCancel, 'Cancel');
        expect(localizations.actionSave, 'Save');
        expect(localizations.actionReset, 'Reset');
        expect(localizations.actionSearch, 'Search...');
        expect(localizations.actionLint, 'Lint');
        expect(localizations.actionRun, 'Run');
        expect(localizations.confirmationTitle, 'Are you sure that you want to delete this item?');
        expect(localizations.confirmationContent, 'Once deleted, you will not be able to recover it.');
        expect(localizations.confirmationConfirm, 'Do it!');
        expect(localizations.confirmationDismiss, 'Nevermind');
        expect(localizations.confirmationMultipleTitle, 'Are you sure that you want to delete these items?');
        expect(localizations.confirmationMultipleContent, 'Once deleted, you will not be able to recover them.');

        // About & Copyright (3 keys)
        expect(localizations.aboutSearch, 'Search package');
        expect(localizations.copyrightPoweredBy, 'Powered by Layrz');
        expect(localizations.copyrightPlatformOS, 'Platform');

        // Calendar Navigation (15 keys)
        expect(localizations.calendarYearBack, 'Previous year');
        expect(localizations.calendarYearNext, 'Next year');
        expect(localizations.calendarMonthBack, 'Previous month');
        expect(localizations.calendarMonthNext, 'Next month');
        expect(localizations.calendarWeekBack, 'Previous week');
        expect(localizations.calendarWeekNext, 'Next week');
        expect(localizations.calendarDayBack, 'Previous day');
        expect(localizations.calendarDayNext, 'Next day');
        expect(localizations.calendarToday, 'Today');
        expect(localizations.calendarViewYear, 'View as year');
        expect(localizations.calendarViewMonth, 'View as month');
        expect(localizations.calendarViewWeek, 'View as week');
        expect(localizations.calendarViewDay, 'View as day');
        expect(localizations.calendarViewAs, 'View as');
        expect(localizations.calendarPickMonth, 'Pick a month');

        // Date & Time Pickers (9 keys, with 1 parameterized)
        expect(localizations.dateTimePickerDate, 'Date');
        expect(localizations.dateTimePickerTime, 'Time');
        expect(localizations.timePickerHours, 'Hours');
        expect(localizations.timePickerMinutes, 'Minutes');
        expect(localizations.timePickerStart, 'Start time');
        expect(localizations.timePickerEnd, 'End time');
        expect(localizations.monthPickerYear(2024), 'Year 2024');
        expect(localizations.monthPickerBack, 'Previous year');
        expect(localizations.monthPickerNext, 'Next year');

        // Select Input (5 keys)
        expect(localizations.selectSearch, 'Search in the list');
        expect(localizations.selectEmpty, 'No item found');
        expect(localizations.selectSelectAll, 'Select all');
        expect(localizations.selectUnselectAll, 'Unselect all');
        expect(localizations.selectUnselect, 'Unselect');

        // Dual-List Input (5 keys, with 1 parameterized)
        expect(localizations.dualListSearch('Items'), 'Search in Items');
        expect(localizations.dualListToggleToSelected, 'Toggle all to selected');
        expect(localizations.dualListToggleToAvailable, 'Toggle all to available');
        expect(localizations.dualListAvailableListName, 'Available');
        expect(localizations.dualListSelectedListName, 'Selected');

        // Table Paginator (8 keys, with 2 parameterized)
        expect(localizations.tableRowsPerPage, 'Rows per page');
        expect(localizations.tablePaginatorStart, 'Start');
        expect(localizations.tablePaginatorPrevious, 'Previous');
        expect(localizations.tablePaginatorNext, 'Next');
        expect(localizations.tablePaginatorEnd, 'End');
        expect(localizations.tablePaginatorShowing(1, 10, 100), 'Showing 1 to 10 of 100');
        expect(localizations.tablePaginatorShowingVerySmall(10, 100), '10 of 100');
        expect(localizations.tablePaginatorAuto, 'Auto');

        // File Operations (2 keys)
        expect(localizations.filePick, 'Pick');
        expect(localizations.fileSave, 'Save');

        // Map Layer & Zoom (3 keys — blocked but reserved)
        expect(localizations.mapChangeLayer, 'Change layer');
        expect(localizations.mapZoomIn, 'Zoom in');
        expect(localizations.mapZoomOut, 'Zoom out');

        // Taskbar (5 keys)
        expect(localizations.taskbarAbout, 'About');
        expect(localizations.taskbarToggleTheme, 'Toggle theme');
        expect(localizations.taskbarSettings, 'Settings');
        expect(localizations.taskbarProfile, 'Edit profile');
        expect(localizations.taskbarSignOut, 'Logout');

        // Notifications (1 key)
        expect(localizations.notificationsEmpty, 'No notifications');

        // Scaffold (1 key)
        expect(localizations.scaffoldEmpty, 'No items');

        // Inputs (5 keys)
        expect(localizations.inputsRequiredIndicator, 'required');
        expect(localizations.inputsCharacterCountOf, 'of');
        expect(localizations.inputsCharacterCountCharacters, 'characters');
        expect(localizations.inputsNumberIncrement, 'Increase value');
        expect(localizations.inputsNumberDecrement, 'Decrease value');

        // Code Editor (2 keys — out of scope but reserved)
        expect(localizations.editorDocumentation, 'Documentation');
        expect(localizations.editorLintError, 'Lint error');

        // Password Requirements (5 keys)
        expect(localizations.passwordRequirementsLowercaseLetter, 'At least one lowercase letter');
        expect(localizations.passwordRequirementsUppercaseLetter, 'At least one uppercase letter');
        expect(localizations.passwordRequirementsDigit, 'At least one digit');
        expect(localizations.passwordRequirementsSpecialCharacter, 'At least one special character');
        expect(localizations.passwordStrengthLevel, 'Password Length');

        // Helpers — General (21 keys)
        expect(localizations.helperSearch, 'Search');
        expect(localizations.helperButtonsShow, 'Show');
        expect(localizations.helperButtonsEdit, 'Edit');
        expect(localizations.helperButtonsDelete, 'Delete');
        expect(localizations.helperMultipleSelectionTitle, 'Multiple items selected');
        expect(localizations.helperMultipleSelectionCaption, 'Descriptive text');
        expect(localizations.helperMultipleSelectionActionsCancel, 'Cancel');
        expect(localizations.helperMultipleSelectionActionsDelete, 'Delete');
        expect(localizations.helperCopiedToClipboard, 'Copied to clipboard');
        expect(localizations.helperCopyToClipboardPost, 'Copy to clipboard');
        expect(localizations.helperAnd, 'and');
        expect(localizations.helperTrue, 'true');
        expect(localizations.helperFalse, 'false');
        expect(localizations.helperYear, 'year');
        expect(localizations.helperMonth, 'month');
        expect(localizations.helperDays, 'days');
        expect(localizations.helperWeeks, 'weeks');
        expect(localizations.helperHours, 'hours');
        expect(localizations.helperMinutes, 'minutes');
        expect(localizations.helperSeconds, 'seconds');
        expect(localizations.helperMilliseconds, 'milliseconds');

        // Helpers — Durations (8 keys, pluralized)
        expect(localizations.helperDurationDays(1), 'day');
        expect(localizations.helperDurationDays(0), 'days');
        expect(localizations.helperDurationDays(2), 'days');
        expect(localizations.helperDurationHours(1), 'hour');
        expect(localizations.helperDurationHours(5), 'hours');
        expect(localizations.helperDurationMinutes(1), 'minute');
        expect(localizations.helperDurationMinutes(30), 'minutes');
        expect(localizations.helperDurationSeconds(1), 'second');
        expect(localizations.helperDurationSeconds(45), 'seconds');
        expect(localizations.helperDurationWeeks(1), 'week');
        expect(localizations.helperDurationWeeks(4), 'weeks');
        expect(localizations.helperDurationMonths(1), 'month');
        expect(localizations.helperDurationMonths(12), 'months');
        expect(localizations.helperDurationYears(1), 'year');
        expect(localizations.helperDurationYears(5), 'years');
        expect(localizations.helperDurationMilliseconds(1), 'millisecond');
        expect(localizations.helperDurationMilliseconds(100), 'milliseconds');

        // DateTime Helpers — Weekday Names (7 keys)
        expect(localizations.dateTimeMonday, 'Monday');
        expect(localizations.dateTuesday, 'Tuesday');
        expect(localizations.dateWednesday, 'Wednesday');
        expect(localizations.dateThursday, 'Thursday');
        expect(localizations.dateFriday, 'Friday');
        expect(localizations.dateSaturday, 'Saturday');
        expect(localizations.dateSunday, 'Sunday');

        // Dynamic Avatar Types (3 keys)
        expect(localizations.dynamicAvatarTypesBASE64, 'Base64');
        expect(localizations.dynamicAvatarTypesNONEHint, 'No avatar');
        expect(localizations.dynamicAvatarTypesURLUrl, 'URL');

        // Required Fields (19 keys — deferred but declared)
        expect(localizations.requiredFieldsAdd, 'Add');
        expect(localizations.requiredFieldsRemove, 'Remove');
        expect(localizations.requiredFieldsField, 'Field');
        expect(localizations.requiredFieldsType, 'Type');
        expect(localizations.requiredFieldsAction, 'Action');
        expect(localizations.requiredFieldsMinLength, 'Minimum length');
        expect(localizations.requiredFieldsMaxLength, 'Maximum length');
        expect(localizations.requiredFieldsMinValue, 'Minimum value');
        expect(localizations.requiredFieldsMaxValue, 'Maximum value');
        expect(localizations.requiredFieldsOnlyField, 'Only field');
        expect(localizations.requiredFieldsOnlyChoices, 'Only choices');
        expect(localizations.requiredFieldsChoices, 'Choices');
        expect(localizations.requiredFieldsChoicesFilter, 'Filter choices');
        expect(localizations.requiredFieldsChoicesAddOption, 'Add option');
        expect(localizations.requiredFieldsChoicesRemove, 'Remove');
        expect(localizations.requiredFieldsChoicesEdit, 'Edit');
        expect(localizations.requiredFieldsChoicesSave, 'Save');
        expect(localizations.requiredFieldsChoicesDiscard, 'Discard');
        expect(localizations.requiredFieldsSectionsValidators, 'Validators');
      });

      test('parameterized methods interpolate correctly', () {
        expect(localizations.monthPickerYear(2024), 'Year 2024');
        expect(localizations.monthPickerYear(2025), 'Year 2025');
        expect(localizations.dualListSearch('Available'), 'Search in Available');
        expect(localizations.dualListSearch('Custom'), 'Search in Custom');
        expect(localizations.tablePaginatorShowing(0, 0, 0), 'Showing 0 to 0 of 0');
        expect(
          localizations.tablePaginatorShowing(50, 100, 500),
          'Showing 50 to 100 of 500',
        );
        expect(localizations.tablePaginatorShowingVerySmall(1, 1), '1 of 1');
        expect(localizations.tablePaginatorShowingVerySmall(99, 999), '99 of 999');
      });

      test('plural methods return singular at count 1', () {
        expect(localizations.helperDurationDays(1), 'day');
        expect(localizations.helperDurationHours(1), 'hour');
        expect(localizations.helperDurationMinutes(1), 'minute');
        expect(localizations.helperDurationSeconds(1), 'second');
        expect(localizations.helperDurationWeeks(1), 'week');
        expect(localizations.helperDurationMonths(1), 'month');
        expect(localizations.helperDurationYears(1), 'year');
        expect(localizations.helperDurationMilliseconds(1), 'millisecond');
      });

      test('plural methods return plural at count 0', () {
        expect(localizations.helperDurationDays(0), 'days');
        expect(localizations.helperDurationHours(0), 'hours');
        expect(localizations.helperDurationMinutes(0), 'minutes');
        expect(localizations.helperDurationSeconds(0), 'seconds');
        expect(localizations.helperDurationWeeks(0), 'weeks');
        expect(localizations.helperDurationMonths(0), 'months');
        expect(localizations.helperDurationYears(0), 'years');
        expect(localizations.helperDurationMilliseconds(0), 'milliseconds');
      });

      test('plural methods return plural at count >= 2', () {
        expect(localizations.helperDurationDays(2), 'days');
        expect(localizations.helperDurationDays(100), 'days');
        expect(localizations.helperDurationHours(999), 'hours');
      });

      test('subclass can override a single getter from mixins', () {
        final customL10n = _SingleOverrideLocalizations();
        expect(customL10n.actionCancel, 'CUSTOM_CANCEL');
        // All other keys still return their English defaults
        expect(customL10n.actionSave, 'Save');
        expect(customL10n.actionReset, 'Reset');
      });
    });

    group('LayrzUiL10n.of', () {
      testWidgets('throws when not available', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                LayrzUiL10n.of(context);
                return Container();
              },
            ),
          ),
        );

        expect(tester.takeException(), isFlutterError);
      });
    });

    group('context.l10n extension', () {
      testWidgets('provides convenient access', (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            home: Builder(
              builder: (context) {
                final text = context.l10n.actionSave;
                return Text(text);
              },
            ),
            theme: LayrzThemeData.light(),
          ),
        );

        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('accesses different keys correctly', (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            home: Builder(
              builder: (context) {
                final cancel = context.l10n.actionCancel;
                final reset = context.l10n.actionReset;
                return Column(
                  children: [
                    Text(cancel),
                    Text(reset),
                  ],
                );
              },
            ),
            theme: LayrzThemeData.light(),
          ),
        );

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });
    });

    group('LayrzUiL10nDelegate', () {
      testWidgets('isSupported returns true for any locale', (tester) async {
        final delegate = const LayrzUiL10nDelegate();
        expect(delegate.isSupported(const Locale('en')), isTrue);
        expect(delegate.isSupported(const Locale('es')), isTrue);
        expect(delegate.isSupported(const Locale('fr')), isTrue);
        expect(delegate.isSupported(const Locale('ja')), isTrue);
      });

      testWidgets('load returns LayrzUiL10nDefault', (tester) async {
        final delegate = const LayrzUiL10nDelegate();
        final result = await delegate.load(const Locale('en'));
        expect(result, isA<LayrzUiL10nDefault>());
      });

      testWidgets('load returns same type for different locales', (tester) async {
        final delegate = const LayrzUiL10nDelegate();
        final resultEn = await delegate.load(const Locale('en'));
        final resultEs = await delegate.load(const Locale('es'));
        expect(resultEn.runtimeType, resultEs.runtimeType);
      });

      testWidgets('shouldReload returns false', (tester) async {
        final delegate1 = const LayrzUiL10nDelegate();
        final delegate2 = const LayrzUiL10nDelegate();
        expect(delegate1.shouldReload(delegate2), isFalse);
      });
    });

    group('LayrzApp integration', () {
      test('builds localizationsDelegates list correctly', () {
        // Verify that the _buildLocalizationsDelegates logic works as expected
        final defaultDelegate = const LayrzUiL10nDelegate();
        expect(defaultDelegate, isNotNull);
      });
    });

    group('buildLayrzUiL10nDelegates', () {
      test('passing null yields exactly one delegate (the default)', () {
        final result = buildLayrzUiL10nDelegates(null);
        expect(result.length, 1);
        expect(result[0], isA<LayrzUiL10nDelegate>());
      });

      test('passing empty list yields exactly one delegate (the default)', () {
        final result = buildLayrzUiL10nDelegates(const []);
        expect(result.length, 1);
        expect(result[0], isA<LayrzUiL10nDelegate>());
      });

      test('caller delegates come first, default appended last', () {
        final caller = _CustomDelegate();
        final result = buildLayrzUiL10nDelegates([caller]);
        expect(result.length, 2);
        expect(result[0], same(caller));
        expect(result[1], isA<LayrzUiL10nDelegate>());
      });

      test('existing LayrzUiL10nDelegate is not duplicated', () {
        final caller = _CustomDelegate();
        final existing = LayrzUiL10nDelegate();
        final result = buildLayrzUiL10nDelegates([caller, existing]);
        expect(result.length, 2);
        expect(result.whereType<LayrzUiL10nDelegate>().length, 1);
        expect(result[0], same(caller));
        expect(result[1], same(existing));
      });

      test('sole LayrzUiL10nDelegate is preserved (not duplicated)', () {
        final existing = LayrzUiL10nDelegate();
        final result = buildLayrzUiL10nDelegates([existing]);
        expect(result.length, 1);
        expect(result[0], same(existing));
      });

      test('does not mutate the caller-supplied iterable', () {
        final original = <LocalizationsDelegate<dynamic>>[_CustomDelegate()];
        final originalLength = original.length;
        buildLayrzUiL10nDelegates(original);
        expect(original.length, originalLength);
      });

      test('unrelated delegate types are preserved', () {
        final marker = _MarkerDelegate();
        final result = buildLayrzUiL10nDelegates([marker]);
        expect(result.length, 2);
        expect(result[0], same(marker));
        expect(result[1], isA<LayrzUiL10nDelegate>());
      });
    });

    group('Localization delegates widget integration', () {
      testWidgets('custom LayrzUiL10n subclass overrides default', (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            localizationsDelegates: const [_CustomDelegate()],
            home: Builder(
              builder: (context) => Text(context.l10n.actionCancel),
            ),
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
          ),
        );
        await tester.pump();

        expect(find.text('CUSTOM_CANCEL'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      });

      testWidgets('caller-supplied delegates take precedence over appended default', (tester) async {
        await tester.pumpWidget(
          LayrzApp(
            localizationsDelegates: const [
              _MarkerDelegate(),
              _CustomDelegate(),
            ],
            home: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    Localizations.of<_Marker>(context, _Marker)?.value ?? 'MISSING',
                  ),
                  Text(context.l10n.actionCancel),
                ],
              ),
            ),
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
          ),
        );
        await tester.pump();

        expect(find.text('present'), findsOneWidget);
        expect(find.text('CUSTOM_CANCEL'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      });

      testWidgets('delegate typed on subclass is NOT found; resolution falls back to default', (tester) async {
        // This is the common mistake: registering a delegate typed on a subclass.
        // LocalizationsDelegate.type becomes the subclass type, which does not match
        // LayrzUiL10n.of() lookup key, so the delegate is never used and resolution
        // silently falls back to the English default — with no error.
        await tester.pumpWidget(
          LayrzApp(
            localizationsDelegates: const [_SubclassTypedDelegate()],
            home: Builder(
              builder: (context) => Text(context.l10n.actionCancel),
            ),
            theme: LayrzThemeData.light(),
            debugShowCheckedModeBanner: false,
          ),
        );
        await tester.pump();

        // The subclass-typed delegate is ignored, so we get English default, not 'SUBCLASS_CANCEL'.
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('SUBCLASS_CANCEL'), findsNothing);
      });
    });
  });
}

/// Minimal [LayrzUiL10n] subclass for testing mixin override behavior.
///
/// Overrides only [actionCancel]; all other getters inherit from their mixins.
/// This verifies that custom subclasses can override individual keys without
/// needing to implement the full contract.
class _SingleOverrideLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _SingleOverrideLocalizations();

  @override
  String get actionCancel => 'CUSTOM_CANCEL';
}

/// Custom [LayrzUiL10n] subclass for testing.
///
/// Overrides [actionCancel] to return a sentinel value, allowing tests to verify
/// that custom subclasses can override the default implementation.
class _CustomLocalizations extends LayrzUiL10nDefault {
  /// Creates a custom localizations instance.
  _CustomLocalizations();

  @override
  String get actionCancel => 'CUSTOM_CANCEL';
}

/// Delegate for loading [_CustomLocalizations].
///
/// Used to test that custom [LayrzUiL10n] subclasses override the default,
/// and that caller-supplied delegates take precedence in the delegation chain.
class _CustomDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates a delegate for custom localizations.
  const _CustomDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) async => _CustomLocalizations();

  @override
  bool shouldReload(covariant LocalizationsDelegate<LayrzUiL10n> old) => false;
}

/// Delegate intentionally (incorrectly) typed on a subclass, for negative testing.
///
/// This demonstrates the common mistake: [LocalizationsDelegate.type] is set to the
/// subclass type, so [Localizations.of<LayrzUiL10n>] never finds it, and resolution
/// silently falls back to English. This is a trap because no error is thrown.
class _SubclassTypedDelegate extends LocalizationsDelegate<_SubclassL10n> {
  /// Creates a subclass-typed delegate.
  const _SubclassTypedDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_SubclassL10n> load(Locale locale) async => const _SubclassL10n();

  @override
  bool shouldReload(_SubclassTypedDelegate old) => false;
}

/// Subclass for use with [_SubclassTypedDelegate].
class _SubclassL10n extends LayrzUiL10n {
  /// Creates a subclass instance.
  const _SubclassL10n();

  @override
  String get actionCancel => 'SUBCLASS_CANCEL';
}

/// Marker class for testing unrelated delegate types.
///
/// Used to verify that non-[LayrzUiL10n] delegates are preserved
/// in the delegate list alongside the [LayrzUiL10n] delegate.
class _Marker {
  /// Creates a marker instance.
  const _Marker(this.value);

  /// A test value to verify the marker delegate was loaded.
  final String value;
}

/// Delegate for loading [_Marker] instances.
///
/// This delegate is unrelated to [LayrzUiL10n] and is used to verify
/// that caller-supplied delegates of other types are preserved alongside
/// the [LayrzUiL10n] delegate.
class _MarkerDelegate extends LocalizationsDelegate<_Marker> {
  /// Creates a delegate for marker test objects.
  const _MarkerDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_Marker> load(Locale locale) async => const _Marker('present');

  @override
  bool shouldReload(covariant LocalizationsDelegate<_Marker> old) => false;
}

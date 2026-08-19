import '../contract/actions.dart';

/// English default implementations for Actions & Confirmations namespace.
mixin LayrzDefaultActionsLocalizations implements LayrzActionsLocalizations {
  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionSearch => 'Search...';

  @override
  String get actionLint => 'Lint';

  @override
  String get actionRun => 'Run';

  @override
  String get confirmationTitle => 'Are you sure that you want to delete this item?';

  @override
  String get confirmationContent => 'Once deleted, you will not be able to recover it.';

  @override
  String get confirmationConfirm => 'Do it!';

  @override
  String get confirmationDismiss => 'Nevermind';

  @override
  String get confirmationMultipleTitle => 'Are you sure that you want to delete these items?';

  @override
  String get confirmationMultipleContent => 'Once deleted, you will not be able to recover them.';
}

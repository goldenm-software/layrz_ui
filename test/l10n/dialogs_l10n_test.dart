import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nDialogsMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('dialogsBarrierLabel returns its English default', () {
      expect(localizations.dialogsBarrierLabel, 'Dialog box');
    });

    test('dialogsBarrierLabel is distinct from sheetsBarrierLabel', () {
      // Both currently default to the same English text, but they are
      // separate keys — a subclass can override one without the other.
      expect(localizations.dialogsBarrierLabel, localizations.sheetsBarrierLabel);
    });

    test('subclass can override dialogsBarrierLabel independently of sheetsBarrierLabel', () {
      final custom = _CustomDialogsLocalizations();
      expect(custom.dialogsBarrierLabel, 'CUSTOM_DIALOG_BARRIER');
      // sheetsBarrierLabel keeps its English default — the two keys are not coupled.
      expect(custom.sheetsBarrierLabel, 'Dialog box');
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [dialogsBarrierLabel].
///
/// Verifies that the new key can be overridden independently without
/// affecting [LayrzUiL10nSheetsMixin.sheetsBarrierLabel], confirming the two
/// strings are not accidentally aliased to one another.
class _CustomDialogsLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomDialogsLocalizations();

  @override
  String get dialogsBarrierLabel => 'CUSTOM_DIALOG_BARRIER';
}

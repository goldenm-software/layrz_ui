import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Opens a confirmation dialog through [open] and records what it resolved to.
class _Harness {
  /// The value the dialog's future completed with, or `null` while pending.
  bool? result;

  /// Number of times the dialog's future completed.
  int completions = 0;
}

/// [LayrzUiL10n] overriding every confirmation string, so tests prove the
/// defaults come from `context.l10n` and not from hardcoded English.
class _CustomL10n extends LayrzUiL10n {
  /// Creates the custom localizations.
  const _CustomL10n();

  @override
  String get confirmationTitle => 'L10N_TITLE';

  @override
  String get confirmationContent => 'L10N_CONTENT';

  @override
  String get confirmationMultipleTitle => 'L10N_MULTI_TITLE';

  @override
  String get confirmationMultipleContent => 'L10N_MULTI_CONTENT';

  @override
  String get confirmationConfirm => 'L10N_CONFIRM';

  @override
  String get confirmationDismiss => 'L10N_DISMISS';
}

/// Delegate loading [_CustomL10n] for every locale.
class _CustomDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates the delegate.
  const _CustomDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) async => const _CustomL10n();

  @override
  bool shouldReload(covariant LocalizationsDelegate<LayrzUiL10n> old) => false;
}

/// Finds the dialog close ("X") button through its button semantics.
Finder _findCloseButton() => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == const LayrzUiL10nDefault().dialogsCloseButtonLabel,
  description: 'the LayrzDialog close button',
);

/// Pumps a wide [LayrzApp] whose "Open" target runs [open] and stores its result.
Future<_Harness> _pump(
  WidgetTester tester,
  Future<bool> Function(BuildContext context) open, {
  bool customL10n = false,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final harness = _Harness();
  await tester.pumpWidget(
    LayrzApp(
      theme: LayrzThemeData.light(),
      localizationsDelegates: customL10n ? const [_CustomDelegate()] : const [],
      home: Center(
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              harness.result = await open(context);
              harness.completions++;
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return harness;
}

/// Finds the [LayrzButton] labelled [label] (a plain text finder also matches the title).
Finder _buttonFinder(String label) =>
    find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == label, description: "LayrzButton \"$label\"");

/// Finds the [LayrzButton] whose label is [label].
LayrzButton _button(WidgetTester tester, String label) =>
    tester.widget<LayrzButton>(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == label));

void main() {
  group('LayrzConfirmationDialog.show', () {
    Future<bool> openGeneric(BuildContext context) => LayrzConfirmationDialog.show(
      context,
      title: 'Lock account?',
      description: 'The user will not be able to sign in.',
      confirmLabel: 'Lock',
      dismissLabel: 'Keep',
    );

    testWidgets('confirm button resolves true', (tester) async {
      final harness = await _pump(tester, openGeneric);
      expect(find.text('Lock account?'), findsOneWidget);
      expect(find.text('The user will not be able to sign in.'), findsOneWidget);

      await tester.tap(_buttonFinder('Lock'));
      await tester.pumpAndSettle();

      expect(harness.result, isTrue);
      expect(harness.completions, 1);
      expect(find.text('Lock account?'), findsNothing);
    });

    testWidgets('dismiss button resolves false', (tester) async {
      final harness = await _pump(tester, openGeneric);

      await tester.tap(_buttonFinder('Keep'));
      await tester.pumpAndSettle();

      expect(harness.result, isFalse);
      expect(find.text('Lock account?'), findsNothing);
    });

    testWidgets('barrier tap resolves false', (tester) async {
      final harness = await _pump(tester, openGeneric);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(harness.result, isFalse);
      expect(find.text('Lock account?'), findsNothing);
    });

    testWidgets('close icon resolves false', (tester) async {
      final harness = await _pump(tester, openGeneric);

      await tester.tap(_findCloseButton());
      await tester.pumpAndSettle();

      expect(harness.result, isFalse);
      expect(find.text('Lock account?'), findsNothing);
    });

    testWidgets('Escape resolves false', (tester) async {
      final harness = await _pump(tester, openGeneric);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(harness.result, isFalse);
      expect(find.text('Lock account?'), findsNothing);
    });

    testWidgets('canDismiss false keeps the dialog open on barrier tap and hides the X', (tester) async {
      final harness = await _pump(
        tester,
        (context) => LayrzConfirmationDialog.show(context, title: 'Sticky', canDismiss: false),
      );
      expect(_findCloseButton(), findsNothing);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Sticky'), findsOneWidget);
      expect(harness.completions, 0);
    });

    testWidgets('labels default to the l10n confirm and dismiss strings', (tester) async {
      await _pump(tester, (context) => LayrzConfirmationDialog.show(context, title: 'T'), customL10n: true);

      expect(_buttonFinder('L10N_CONFIRM'), findsOneWidget);
      expect(_buttonFinder('L10N_DISMISS'), findsOneWidget);
    });

    testWidgets('type, icon and content reach the confirm button and body', (tester) async {
      await _pump(
        tester,
        (context) => LayrzConfirmationDialog.show(
          context,
          title: 'T',
          confirmLabel: 'Go',
          dismissLabel: 'No',
          type: .warning,
          icon: MdiIcons.lock,
          content: const Text('Extra body'),
        ),
      );

      final confirm = _button(tester, 'Go');
      expect(confirm.type, LayrzButtonType.warning);
      expect(confirm.icon, MdiIcons.lock);
      expect(_button(tester, 'No').type, LayrzButtonType.success);
      expect(find.text('Extra body'), findsOneWidget);
    });

    testWidgets('a non-destructive confirm gets a danger dismiss button', (tester) async {
      await _pump(
        tester,
        (context) => LayrzConfirmationDialog.show(context, title: 'T', confirmLabel: 'Go', dismissLabel: 'No'),
      );

      expect(_button(tester, 'Go').type, LayrzButtonType.success);
      expect(_button(tester, 'No').type, LayrzButtonType.danger);
    });
  });

  group('LayrzConfirmationDialog.delete', () {
    testWidgets('single item uses the l10n single title, content and labels', (tester) async {
      final harness = await _pump(
        tester,
        (context) => LayrzConfirmationDialog.delete(context, items: const ['Alpha']),
        customL10n: true,
      );

      expect(find.text('L10N_TITLE'), findsOneWidget);
      expect(find.text('L10N_CONTENT'), findsOneWidget);
      expect(find.text('L10N_MULTI_TITLE'), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);

      final confirm = _button(tester, 'L10N_CONFIRM');
      expect(confirm.type, LayrzButtonType.danger);
      expect(confirm.icon, MdiIcons.trashCanOutline);
      expect(_button(tester, 'L10N_DISMISS').type, LayrzButtonType.success);

      await tester.tap(_buttonFinder('L10N_CONFIRM'));
      await tester.pumpAndSettle();
      expect(harness.result, isTrue);
    });

    testWidgets('no items uses the single variant and renders no item list', (tester) async {
      await _pump(tester, (context) => LayrzConfirmationDialog.delete(context), customL10n: true);

      expect(find.text('L10N_TITLE'), findsOneWidget);
      expect(find.text('L10N_CONTENT'), findsOneWidget);
    });

    testWidgets('several items use the multiple variant and list every name', (tester) async {
      final harness = await _pump(
        tester,
        (context) => LayrzConfirmationDialog.delete(context, items: const ['Alpha', 'Beta', 'Gamma']),
        customL10n: true,
      );

      expect(find.text('L10N_MULTI_TITLE'), findsOneWidget);
      expect(find.text('L10N_MULTI_CONTENT'), findsOneWidget);
      expect(find.text('L10N_TITLE'), findsNothing);
      expect(find.text('Alpha, Beta, Gamma'), findsOneWidget);

      await tester.tap(_buttonFinder('L10N_DISMISS'));
      await tester.pumpAndSettle();
      expect(harness.result, isFalse);
    });

    testWidgets('English defaults come from the default l10n', (tester) async {
      await _pump(tester, (context) => LayrzConfirmationDialog.delete(context, items: const ['A', 'B']));
      final l10n = LayrzUiL10n.of(tester.element(find.text('Open')));

      expect(find.text(l10n.confirmationMultipleTitle), findsOneWidget);
      expect(find.text(l10n.confirmationMultipleContent), findsOneWidget);
      expect(_buttonFinder(l10n.confirmationConfirm), findsOneWidget);
      expect(_buttonFinder(l10n.confirmationDismiss), findsOneWidget);
    });

    testWidgets('custom title, description and labels override the defaults', (tester) async {
      await _pump(
        tester,
        (context) => LayrzConfirmationDialog.delete(
          context,
          title: 'Delete Alpha?',
          description: 'Gone for good.',
          confirmLabel: 'Delete',
          dismissLabel: 'Back',
          items: const ['Alpha', 'Beta'],
        ),
        customL10n: true,
      );

      expect(find.text('Delete Alpha?'), findsOneWidget);
      expect(find.text('Gone for good.'), findsOneWidget);
      expect(_buttonFinder('Delete'), findsOneWidget);
      expect(_buttonFinder('Back'), findsOneWidget);
      expect(find.text('L10N_MULTI_TITLE'), findsNothing);
      expect(find.text('L10N_MULTI_CONTENT'), findsNothing);
      expect(_buttonFinder('L10N_CONFIRM'), findsNothing);
    });

    testWidgets('barrier tap resolves false', (tester) async {
      final harness = await _pump(tester, (context) => LayrzConfirmationDialog.delete(context));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(harness.result, isFalse);
    });

    testWidgets('renders on a compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          theme: LayrzThemeData.light(),
          home: Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () => LayrzConfirmationDialog.delete(context, items: List.generate(30, (i) => 'Item $i')),
                child: const SizedBox(width: 100, height: 100, child: Text('Open')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Item 29'), findsOneWidget);
    });
  });

  group('LayrzConfirmationDialog accessibility', () {
    testWidgets('title names the dialog route and both actions are buttons', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _pump(
          tester,
          (context) =>
              LayrzConfirmationDialog.show(context, title: 'Lock?', confirmLabel: 'Lock', dismissLabel: 'Keep'),
        );

        final scope = tester.getSemantics(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.scopesRoute == true && w.properties.label == 'Lock?',
          ),
        );
        expect(
          scope,
          matchesSemantics(label: 'Lock?', scopesRoute: true, namesRoute: true, hasEnabledState: true, isEnabled: true),
        );

        expect(
          tester.getSemantics(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Lock')),
          matchesSemantics(
            label: 'Lock',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}

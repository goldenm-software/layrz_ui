import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_style_spec.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_type.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_view.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';

void main() {
  /// Sets a wide desktop viewport so tests don't accidentally exercise the
  /// compact-only default 800×600 test surface (CLAUDE.md testing traps).
  void setWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  LayrzSnackbarStyleSpec resolveSpec(BuildContext context, LayrzSnackbarType type) {
    return LayrzSnackbarStyleSpec.resolve(type, context.tokens);
  }

  group('LayrzSnackbarView', () {
    group('Content rendering', () {
      testWidgets('renders title and description text', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Your changes were saved successfully.'), findsOneWidget);
      });

      testWidgets('renders the semantic icon for a non-custom type', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Failed',
          descriptionText: 'Something went wrong.',
          type: LayrzSnackbarType.danger,
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        expect(find.byType(Icon), findsWidgets);
      });
    });

    group('White-card surface', () {
      testWidgets('card decoration fills with surfaceColor, not the accent', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          type: LayrzSnackbarType.danger,
        );

        late LayrzSnackbarStyleSpec style;

        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              style = resolveSpec(context, snackbar.type);
              return LayrzSnackbarView(
                snackbar: snackbar,
                style: style,
                progress: 1.0,
              );
            },
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, style.surfaceColor);
        expect(decoration.color, isNot(style.accentColor));
      });

      testWidgets('card has a 1px border using borderColor', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        late LayrzSnackbarStyleSpec style;

        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              style = resolveSpec(context, snackbar.type);
              return LayrzSnackbarView(
                snackbar: snackbar,
                style: style,
                progress: 1.0,
              );
            },
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.border, Border.all(color: style.borderColor, width: 1));
      });
    });

    group('Accent + description colors', () {
      testWidgets('icon uses accentColor', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Failed',
          descriptionText: 'Something went wrong.',
          type: LayrzSnackbarType.danger,
        );

        late LayrzSnackbarStyleSpec style;

        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              style = resolveSpec(context, snackbar.type);
              return LayrzSnackbarView(
                snackbar: snackbar,
                style: style,
                progress: 1.0,
              );
            },
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon).first);
        expect(icon.color, style.accentColor);
        expect(icon.color, style.iconColor);
      });

      testWidgets('title text uses accentColor and description uses descriptionColor', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Failed',
          descriptionText: 'Something went wrong.',
          type: LayrzSnackbarType.danger,
        );

        late LayrzSnackbarStyleSpec style;

        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              style = resolveSpec(context, snackbar.type);
              return LayrzSnackbarView(
                snackbar: snackbar,
                style: style,
                progress: 1.0,
              );
            },
          ),
        );

        final title = tester.widget<Text>(find.text('Failed'));
        final description = tester.widget<Text>(find.text('Something went wrong.'));

        expect(title.style?.color, style.titleColor);
        expect(title.style?.color, style.accentColor);
        expect(description.style?.color, style.descriptionColor);
        expect(description.style?.color, isNot(style.accentColor));
      });
    });

    group('Progress bar', () {
      testWidgets('sits at the top edge of the card', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.top, 0);
        expect(positioned.bottom, isNull);
      });

      testWidgets('reflects the progress input at full width', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        final fractionallySizedBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
        expect(fractionallySizedBox.widthFactor, 1.0);
      });

      testWidgets('reflects the progress input at half width', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 0.5,
            ),
          ),
        );

        final fractionallySizedBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
        expect(fractionallySizedBox.widthFactor, 0.5);
      });

      testWidgets('reflects the progress input at zero width', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 0.0,
            ),
          ),
        );

        final fractionallySizedBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
        expect(fractionallySizedBox.widthFactor, 0.0);
      });

      testWidgets('is painted with style.progressColor', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          type: LayrzSnackbarType.warning,
        );

        late LayrzSnackbarStyleSpec style;

        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              style = resolveSpec(context, snackbar.type);
              return LayrzSnackbarView(
                snackbar: snackbar,
                style: style,
                progress: 1.0,
              );
            },
          ),
        );

        final bar = tester.widget<Container>(
          find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(Container)).first,
        );
        expect(bar.color, style.progressColor);
      });
    });

    group('Actions', () {
      testWidgets('renders provided LayrzButtons below the content in a trailing-aligned Row', (tester) async {
        setWideViewport(tester);
        final snackbar = LayrzSnackbar(
          titleText: 'Rule updated',
          descriptionText: 'A new alarm rule was triggered.',
          type: LayrzSnackbarType.warning,
          duration: null, // isolates the actions row from the close button.
          actions: [
            LayrzButton(labelText: 'Manage rule', onTap: () {}, type: LayrzButtonType.warning),
            LayrzButton(labelText: 'Dismiss', onTap: () {}),
          ],
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        expect(findButtonLabel('Manage rule'), findsOneWidget);
        expect(findButtonLabel('Dismiss'), findsOneWidget);
        expect(find.byType(LayrzButton), findsNWidgets(2));

        final actionsRow = tester
            .widgetList<Row>(find.byType(Row))
            .firstWhere(
              (row) => row.children.whereType<LayrzButton>().length == 2,
            );
        expect(actionsRow.mainAxisAlignment, MainAxisAlignment.end);
      });

      testWidgets('renders no actions row when actions is empty', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: null,
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        // Persistent (duration: null) means no close button either, so an
        // absent LayrzButton here proves the actions row itself is absent.
        expect(find.byType(LayrzButton), findsNothing);
      });

      testWidgets('tapping an action button fires its own onTap but not onCardTap', (tester) async {
        setWideViewport(tester);
        var actionFired = false;
        var cardTapFired = false;
        final snackbar = LayrzSnackbar(
          titleText: 'Rule updated',
          descriptionText: 'A new alarm rule was triggered.',
          duration: null, // isolates the action button from the close button.
          actions: [
            LayrzButton(labelText: 'Manage rule', onTap: () => actionFired = true),
          ],
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onCardTap: () => cardTapFired = true,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(actionFired, isTrue);
        expect(cardTapFired, isFalse);
      });
    });

    group('Whole-card tap', () {
      testWidgets('tapping the card body fires onCardTap', (tester) async {
        setWideViewport(tester);
        var cardTapFired = false;
        const snackbar = LayrzSnackbar(
          titleText: 'Deleted',
          descriptionText: 'The item was removed.',
          type: LayrzSnackbarType.context,
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onCardTap: () => cardTapFired = true,
            ),
          ),
        );

        await tester.tap(find.text('Deleted'));
        await tester.pump();

        expect(cardTapFired, isTrue);
      });

      testWidgets('card is not tappable when onCardTap is null', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
            ),
          ),
        );

        expect(
          find.ancestor(of: find.text('Saved'), matching: find.byType(GestureDetector)),
          findsNothing,
        );
      });
    });

    group('Close affordance', () {
      testWidgets('is a LayrzButton, present when the snackbar is auto-dismissing', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );
        expect(snackbar.isAutoDismiss, isTrue);

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onClose: () {},
            ),
          ),
        );

        expect(
          find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(LayrzButton)),
          findsOneWidget,
        );
      });

      testWidgets('is absent when the snackbar is persistent (duration: null)', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: null,
        );
        expect(snackbar.isPersistent, isTrue);

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onClose: () {},
            ),
          ),
        );

        expect(
          find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(LayrzButton)),
          findsNothing,
        );
      });

      testWidgets('is absent along with the progress bar when persistent', (tester) async {
        setWideViewport(tester);
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
          duration: null,
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onClose: () {},
            ),
          ),
        );

        expect(find.byType(LayrzButton), findsNothing);
        expect(find.byType(FractionallySizedBox), findsNothing);
        expect(find.byType(Positioned), findsNothing);
      });

      testWidgets('tapping the close button calls onClose', (tester) async {
        setWideViewport(tester);
        var closeTapped = false;
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onClose: () => closeTapped = true,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(closeTapped, isTrue);
      });

      testWidgets('tapping close does not also fire onCardTap', (tester) async {
        setWideViewport(tester);
        var closeTapped = false;
        var cardTapFired = false;
        const snackbar = LayrzSnackbar(
          titleText: 'Saved',
          descriptionText: 'Your changes were saved successfully.',
        );

        await pumpThemed(
          tester,
          Builder(
            builder: (context) => LayrzSnackbarView(
              snackbar: snackbar,
              style: resolveSpec(context, snackbar.type),
              progress: 1.0,
              onClose: () => closeTapped = true,
              onCardTap: () => cardTapFired = true,
            ),
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pump();

        expect(closeTapped, isTrue);
        expect(cardTapFired, isFalse);
      });
    });

    group('Semantics', () {
      testWidgets('live region announces title and description together', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          const snackbar = LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
          );

          await pumpThemed(
            tester,
            Builder(
              builder: (context) => LayrzSnackbarView(
                snackbar: snackbar,
                style: resolveSpec(context, snackbar.type),
                progress: 1.0,
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Semantics)).first,
          );

          expect(semanticsNode.label, contains('Saved'));
          expect(semanticsNode.label, contains('Your changes were saved successfully.'));
          expect(
            semanticsNode,
            matchesSemantics(
              isLiveRegion: true,
              label: semanticsNode.label,
              isButton: false,
              hasTapAction: false,
            ),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('card exposes button semantics when onCardTap is provided', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          const snackbar = LayrzSnackbar(
            titleText: 'Deleted',
            descriptionText: 'The item was removed.',
            type: LayrzSnackbarType.context,
          );

          await pumpThemed(
            tester,
            Builder(
              builder: (context) => LayrzSnackbarView(
                snackbar: snackbar,
                style: resolveSpec(context, snackbar.type),
                progress: 1.0,
                onCardTap: () {},
              ),
            ),
          );

          final semanticsNode = tester.getSemantics(
            find.descendant(of: find.byType(LayrzSnackbarView), matching: find.byType(Semantics)).first,
          );

          expect(
            semanticsNode,
            matchesSemantics(
              isLiveRegion: true,
              label: semanticsNode.label,
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('close affordance carries the dismiss l10n label', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          setWideViewport(tester);
          const snackbar = LayrzSnackbar(
            titleText: 'Saved',
            descriptionText: 'Your changes were saved successfully.',
          );

          await pumpThemed(
            tester,
            Builder(
              builder: (context) => LayrzSnackbarView(
                snackbar: snackbar,
                style: resolveSpec(context, snackbar.type),
                progress: 1.0,
                onClose: () {},
              ),
            ),
          );

          // LayrzButton's own Semantics node carries the label and isButton flag;
          // its tap handling lives on the excluded GestureDetector beneath it
          // (LayrzButton's contract), so no hasTapAction is expected here.
          final closeNode = tester.getSemantics(find.bySemanticsLabel('Dismiss notification'));
          expect(
            closeNode,
            matchesSemantics(
              label: 'Dismiss notification',
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
            ),
          );
        } finally {
          handle.dispose();
        }
      });
    });
  });
}

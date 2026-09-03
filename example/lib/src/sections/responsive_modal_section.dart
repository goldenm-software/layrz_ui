import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the dedicated showroom section for [LayrzResponsiveModal].
///
/// [LayrzResponsiveModal] previously only appeared as one showcase card
/// inside [DialogsSection]. Its whole point -- resolving once, at `show()`
/// time, to either a [LayrzDialog] on a wide viewport or a `LayrzBottomSheet`
/// on a compact one -- deserves a first-class demonstration of its own rather
/// than a brief mention alongside plain [LayrzDialog] demos (DESIGN-164).
///
/// This section demonstrates:
/// - The responsive switch itself, with `isCompact` override buttons so a
///   desktop tester can see the sheet form without resizing the window.
/// - The pinned `actions` row, shown on both presentations with enough
///   scrollable content that "pinned" (never scrolled away) is visible.
/// - [LayrzDialogConfig] (`maxWidth`/`maxHeight`) and
///   [LayrzBottomSheetConfig] (`snapSizes`, `initialSize`, `minSize`,
///   `maxSize`, `showDragHandle`, `scrollable`) variations, including a
///   snap-points sheet and a non-scrollable one.
class ResponsiveModalSection extends StatefulWidget {
  /// Creates a new [ResponsiveModalSection].
  const ResponsiveModalSection({super.key});

  @override
  State<ResponsiveModalSection> createState() => _ResponsiveModalSectionState();
}

class _ResponsiveModalSectionState extends State<ResponsiveModalSection> {
  /// The [LayrzModalPresentation] label the last modal opened from this
  /// section resolved to, or `null` if none has been opened yet.
  String? _lastPresentation;

  @override
  Widget build(BuildContext context) {
    return ShowroomSection(
      title: 'Responsive Modal',
      description:
          'LayrzResponsiveModal -- picks a dialog on wide viewports and a bottom '
          'sheet on compact ones, decided once when show() is called',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Dialog vs. bottom sheet',
            description:
                'The same show() call renders as a LayrzDialog at/above a 960px viewport '
                'width, or a bottom sheet below it. Use the override buttons to force either '
                'presentation regardless of the current window width -- useful for seeing the '
                'sheet form without resizing a desktop window. Presentation is resolved once, '
                'at the moment show() is called, and never re-evaluated if the window is '
                'resized while the modal is open.',
            child: _PresentationSwitchShowcase(
              lastPresentation: _lastPresentation,
              onPresentationResolved: (label) => setState(() => _lastPresentation = label),
            ),
          ),
          _SectionCard(
            title: 'Pinned actions row',
            description:
                'actions renders a button row pinned below the builder content on both '
                'branches -- it never scrolls away with the content above it, even when that '
                'content is long enough to scroll. Try both presentations and scroll the body.',
            child: _PinnedActionsShowcase(),
          ),
          _SectionCard(
            title: 'Dialog config: maxWidth / maxHeight',
            description:
                'LayrzDialogConfig controls the dialog branch\'s panel bounds. Ignored '
                'entirely on the sheet branch. Force the dialog presentation to see this '
                'take effect regardless of window width.',
            child: _DialogConfigShowcase(),
          ),
          _SectionCard(
            title: 'Sheet config: snap points',
            description:
                'LayrzBottomSheetConfig.snapSizes gives the sheet named heights to settle at '
                'while dragging, instead of the default [0.5, 0.95]. Ignored entirely on the '
                'dialog branch. Force the sheet presentation to try dragging between snap '
                'points.',
            child: _SnapSheetShowcase(),
          ),
          _SectionCard(
            title: 'Sheet config: non-scrollable content',
            description:
                'scrollable: false tells the sheet its content builder already returns its '
                'own scrollable (or does not need one), rather than wrapping it in one. Force '
                'the sheet presentation to see the fixed, non-scrolling body.',
            child: _NonScrollableSheetShowcase(),
          ),
        ],
      ),
    );
  }
}

/// A titled card wrapper for one showcase within [ResponsiveModalSection].
///
/// Mirrors `_DialogShowcaseCard` from `dialogs_section.dart` so the two
/// sections read as one visual family.
class _SectionCard extends StatelessWidget {
  /// The title of the showcase card.
  final String title;

  /// Explanatory text shown below the title, above [child].
  final String description;

  /// The content displayed inside the card -- typically one or more buttons
  /// that open a responsive modal.
  final Widget child;

  /// Creates a new [_SectionCard].
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tokens.typography.label),
          SizedBox(height: tokens.spacing.sp1),
          Text(
            description,
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Container(
            padding: EdgeInsets.all(tokens.spacing.sp3),
            decoration: BoxDecoration(
              color: tokens.colors.sf2,
              borderRadius: tokens.radius.br2,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Builds the freeform body content shared by this section's showcases: a
/// title line naming the presentation, an explanatory paragraph, and (when
/// [long] is true) enough filler paragraphs to force scrolling.
List<Widget> _bodyContent(LayrzTokens tokens, String presentationLabel, {bool long = false}) {
  return [
    Text('Presented as: $presentationLabel', style: tokens.typography.title),
    Text(
      'This surface was chosen once, when show() was called, from the viewport width at '
      'that moment (or the isCompact override, if one was passed).',
      style: tokens.typography.body,
    ),
    if (long)
      for (var i = 1; i <= 12; i++)
        Padding(
          padding: EdgeInsets.only(top: tokens.spacing.sp2),
          child: Text(
            'Scrollable content line $i -- keep scrolling to confirm the actions row below '
            'never moves.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ),
  ];
}

/// Showcase for the core responsive switch, teaching that presentation is
/// resolved once at `show()` time and offering `isCompact` overrides so a
/// wide desktop window can still preview the sheet form.
class _PresentationSwitchShowcase extends StatelessWidget {
  /// The [LayrzModalPresentation] label the most recent `show()` call
  /// resolved to, or `null` if the modal has not been opened yet.
  final String? lastPresentation;

  /// Called with a human-readable presentation label every time a modal is
  /// opened, so the parent can display which surface was actually chosen.
  final ValueChanged<String> onPresentationResolved;

  /// Creates a new [_PresentationSwitchShowcase].
  const _PresentationSwitchShowcase({
    required this.lastPresentation,
    required this.onPresentationResolved,
  });

  /// Opens the responsive modal, optionally forcing [isCompact] to override
  /// the viewport-based choice, and records which presentation was used.
  void _open(BuildContext context, {bool? isCompact}) async {
    final willBeCompact = isCompact ?? context.isCompact;
    final presentationLabel = willBeCompact ? 'bottom sheet (compact)' : 'dialog (wide)';

    await LayrzResponsiveModal.show<void>(
      context,
      isCompact: isCompact,
      semanticLabel: 'Responsive modal presentation demo',
      builder: (modalContext) {
        final tokens = modalContext.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.sp2,
          children: _bodyContent(tokens, presentationLabel),
        );
      },
      actions: [
        Builder(
          builder: (modalContext) => LayrzButton.cancel(
            labelText: 'Close',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
      ],
    );

    onPresentationResolved(presentationLabel);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final wouldBeCompact = context.isCompact;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.sp2,
          children: [
            Text(
              'Live viewport width: ${width.round()}px -- next unforced show() call would '
              'choose: ${wouldBeCompact ? 'bottom sheet (< 960px)' : 'dialog (>= 960px)'}',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            if (lastPresentation != null)
              Text(
                'Last opened as: $lastPresentation',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: tokens.spacing.sp2,
              children: [
                LayrzButton(
                  labelText: 'Open (auto)',
                  onTap: () => _open(context),
                ),
                LayrzButton(
                  labelText: 'Force sheet',
                  style: LayrzButtonStyle.outlined,
                  onTap: () => _open(context, isCompact: true),
                ),
                LayrzButton(
                  labelText: 'Force dialog',
                  style: LayrzButtonStyle.outlined,
                  onTap: () => _open(context, isCompact: false),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Showcase for the [LayrzResponsiveModal.show] `actions` slot: a pinned
/// button row that stays put while long content scrolls above it, on both
/// the dialog and the sheet branch.
class _PinnedActionsShowcase extends StatelessWidget {
  /// Opens the responsive modal with enough scrollable content that a
  /// pinned, never-scrolled actions row is visibly meaningful.
  void _open(BuildContext context, {bool? isCompact}) {
    final willBeCompact = isCompact ?? context.isCompact;
    final presentationLabel = willBeCompact ? 'bottom sheet (compact)' : 'dialog (wide)';

    LayrzResponsiveModal.show<void>(
      context,
      isCompact: isCompact,
      semanticLabel: 'Responsive modal pinned actions demo',
      builder: (modalContext) {
        final tokens = modalContext.tokens;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spacing.sp2,
            children: _bodyContent(tokens, presentationLabel, long: true),
          ),
        );
      },
      actions: [
        Builder(
          builder: (modalContext) => LayrzButton.cancel(
            labelText: 'Discard',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
        Builder(
          builder: (modalContext) => LayrzButton.save(
            labelText: 'Save',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: tokens.spacing.sp2,
      children: [
        LayrzButton(
          labelText: 'Open (auto)',
          onTap: () => _open(context),
        ),
        LayrzButton(
          labelText: 'Force sheet',
          style: LayrzButtonStyle.outlined,
          onTap: () => _open(context, isCompact: true),
        ),
        LayrzButton(
          labelText: 'Force dialog',
          style: LayrzButtonStyle.outlined,
          onTap: () => _open(context, isCompact: false),
        ),
      ],
    );
  }
}

/// Showcase for [LayrzDialogConfig]'s `maxWidth`/`maxHeight`, applied only
/// when the dialog branch is chosen.
class _DialogConfigShowcase extends StatelessWidget {
  void _open(BuildContext context) {
    LayrzResponsiveModal.show<void>(
      context,
      isCompact: false,
      semanticLabel: 'Responsive modal dialog config demo',
      dialog: const LayrzDialogConfig(maxWidth: 320, maxHeight: 260),
      builder: (modalContext) {
        final tokens = modalContext.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.sp2,
          children: [
            Text('maxWidth: 320, maxHeight: 260', style: tokens.typography.title),
            Text(
              'A narrower, shorter panel than the 480x640 default -- useful for a compact '
              'confirmation that should not stretch across a wide viewport.',
              style: tokens.typography.body,
            ),
          ],
        );
      },
      actions: [
        Builder(
          builder: (modalContext) => LayrzButton.save(
            labelText: 'Close',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayrzButton(
      labelText: 'Open small dialog (forced)',
      onTap: () => _open(context),
    );
  }
}

/// Showcase for [LayrzBottomSheetConfig.snapSizes], applied only when the
/// sheet branch is chosen.
class _SnapSheetShowcase extends StatelessWidget {
  void _open(BuildContext context) {
    LayrzResponsiveModal.show<void>(
      context,
      isCompact: true,
      semanticLabel: 'Responsive modal snap points demo',
      sheet: const LayrzBottomSheetConfig(
        snapSizes: [0.3, 0.6, 0.9],
        initialSize: 0.3,
      ),
      builder: (modalContext) {
        final tokens = modalContext.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.sp2,
          children: [
            Text('snapSizes: [0.3, 0.6, 0.9]', style: tokens.typography.title),
            Text(
              'Drag the handle -- the sheet settles at 30%, 60%, or 90% of the screen height '
              'instead of the default [0.5, 0.95].',
              style: tokens.typography.body,
            ),
          ],
        );
      },
      actions: [
        Builder(
          builder: (modalContext) => LayrzButton.cancel(
            labelText: 'Close',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayrzButton(
      labelText: 'Open snap-points sheet (forced)',
      onTap: () => _open(context),
    );
  }
}

/// Showcase for [LayrzBottomSheetConfig.scrollable] set to `false`, applied
/// only when the sheet branch is chosen.
class _NonScrollableSheetShowcase extends StatelessWidget {
  void _open(BuildContext context) {
    LayrzResponsiveModal.show<void>(
      context,
      isCompact: true,
      semanticLabel: 'Responsive modal non-scrollable sheet demo',
      sheet: const LayrzBottomSheetConfig(scrollable: false, initialSize: 0.35),
      builder: (modalContext) {
        final tokens = modalContext.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.sp2,
          children: [
            Text('scrollable: false', style: tokens.typography.title),
            Text(
              'The sheet no longer wraps this content in its own scroll view -- appropriate '
              'when the content is short and fixed, or already brings its own scrollable.',
              style: tokens.typography.body,
            ),
          ],
        );
      },
      actions: [
        Builder(
          builder: (modalContext) => LayrzButton.cancel(
            labelText: 'Close',
            onTap: () => Navigator.of(modalContext, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayrzButton(
      labelText: 'Open non-scrollable sheet (forced)',
      onTap: () => _open(context),
    );
  }
}

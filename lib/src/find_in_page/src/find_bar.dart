import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/progress/progress.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'find_in_page_controller.dart';

/// The default (and maximum) width, in logical pixels, of [LayrzFindBar]'s
/// query field.
///
/// The field sizes to this on a normal desktop viewport (matching a browser
/// find bar's compact query box), and only shrinks below it — down to
/// [kLayrzFindBarQueryFieldMinWidth] — when the bar's own available width
/// (from the incoming [BoxConstraints.maxWidth] seen in
/// [_LayrzFindBarState.build]'s [LayoutBuilder]) is too narrow for the full
/// row, which is how [LayrzFindInPageHostState._buildFindBarOverlay] keeps
/// the whole bar from overflowing a narrow/compact viewport while staying
/// pinned top-right.
const double kLayrzFindBarQueryFieldMaxWidth = 220.0;

/// The minimum width, in logical pixels, [LayrzFindBar] will ever shrink its
/// query field to — see [kLayrzFindBarQueryFieldMaxWidth]. Below this the
/// field would no longer be usably readable/tappable, so the bar accepts a
/// small, deliberate overflow on a viewport narrower than this floor plus
/// the counter/buttons/padding rather than shrinking the field further.
const double kLayrzFindBarQueryFieldMinWidth = 96.0;

/// The height, in logical pixels, of the thin indeterminate progress line
/// reserved at the bottom edge of [LayrzFindBar].
///
/// Always reserved as layout space — see [_LayrzFindBarState.build]'s use of
/// [Opacity] rather than conditionally including/excluding this slot — so the
/// bar's overall height never changes when a search starts or settles (the
/// interaction-state rule in `engineering/decisions.md`, D15: state changes
/// vary color/opacity, never geometry).
const double kLayrzFindBarSearchingIndicatorHeight = 2.0;

/// The floating, browser-style find bar for [LayrzFindInPageHost].
///
/// Rendered as the content of a root-[Overlay] [OverlayEntry] while
/// [LayrzFindInPageController.isOpen] is `true` — top-right, matching the
/// browser Ctrl+F convention this feature replaces (see the module doc on
/// `find_in_page_host.dart` for why the root overlay specifically).
///
/// Composes: a [LayrzTextInput] query field (not a raw [EditableText] — a raw
/// [EditableText] was proven to fail web text input during the DESIGN-109
/// spike work; [LayrzTextInput] is the widget proven to work there), a live
/// "current of total" counter, previous/next navigation buttons, and a close
/// button. Enter/Shift+Enter/Escape are handled **locally** to this bar (a
/// [Focus] wrapping just this widget, mirroring `LayrzDialog`'s own
/// `onKeyEvent` Escape handler in `dialogs/src/dialog.dart`) — they never
/// register as app-wide shortcuts, unlike Ctrl/Cmd+F itself (see
/// [LayrzFindInPageHost], which registers that one shortcut via
/// [LayrzShortcut]).
class LayrzFindBar extends StatefulWidget {
  /// The controller this bar reads state from and drives.
  final LayrzFindInPageController controller;

  /// Called when the bar's close button (or a local Escape) requests find be
  /// dismissed. The bar itself never calls [LayrzFindInPageController.close]
  /// directly, so [LayrzFindInPageHost] stays the single place deciding what
  /// "closing find" entails (e.g. also removing the bar's own overlay entry).
  final VoidCallback onClose;

  /// Creates a [LayrzFindBar].
  const LayrzFindBar({super.key, required this.controller, required this.onClose});

  @override
  State<LayrzFindBar> createState() => _LayrzFindBarState();
}

class _LayrzFindBarState extends State<LayrzFindBar> {
  /// Controls the query field's text, seeded from the controller's current
  /// [LayrzFindInPageController.query] so re-opening a bar that already has a
  /// query (see that controller's [LayrzFindInPageController.open] doc) shows
  /// the preserved text immediately rather than an empty field.
  late final TextEditingController _queryController = TextEditingController(text: widget.controller.query);

  /// Focus node for the query field — the bar requests focus for it on
  /// mount, mirroring a browser's find bar auto-focusing on open.
  final FocusNode _queryFocusNode = FocusNode();

  /// Focus node for the [Focus] wrapping this whole bar, which owns the
  /// local Enter/Shift+Enter/Escape handling — see [_handleKeyEvent].
  final FocusNode _barFocusNode = FocusNode(debugLabel: 'LayrzFindBar');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _queryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _queryController.dispose();
    _queryFocusNode.dispose();
    _barFocusNode.dispose();
    super.dispose();
  }

  /// Rebuilds on every controller change — the counter, and whether
  /// next/previous are enabled, both depend on live controller state
  /// ([LayrzFindInPageController.matches]/[LayrzFindInPageController.currentIndex]).
  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Handles every keystroke in the query field.
  void _handleQueryChanged(String value) {
    widget.controller.setQuery(value);
  }

  /// Handles the query field's own submit action (Enter fired via
  /// [LayrzTextInput.onSubmit]) — runs an immediate search rather than
  /// waiting for the debounce, matching the spike's "Walk & Highlight" button
  /// bypassing the debounce for a deliberate user action (see
  /// `find_spike.dart`'s `_handleWalkPressed` doc).
  void _handleSubmit(String value) {
    widget.controller.searchNow();
  }

  /// Local key handler for this bar only — Enter advances to the next match,
  /// Shift+Enter cycles to the previous one, and Escape closes find. Mirrors
  /// `LayrzDialog`'s own `onKeyEvent` Escape pattern (`dialogs/src/dialog.dart`):
  /// returns [KeyEventResult.ignored] for anything it doesn't act on, so
  /// unrelated key events keep propagating normally.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final isShiftHeld =
          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
      if (isShiftHeld) {
        widget.controller.previous();
      } else {
        widget.controller.next();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = widget.controller;
    final totalMatches = controller.matches.length;
    final currentOrdinal = controller.currentIndex >= 0 ? controller.currentIndex + 1 : 0;
    final hasMatches = totalMatches > 0;

    return Focus(
      focusNode: _barFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br3,
          boxShadow: tokens.shadow.elevation5,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A Row with `mainAxisSize: MainAxisSize.min` still lets a
            // Flexible/Expanded child consume the row's *entire* incoming
            // bound (that's how RenderFlex allocates free space,
            // independent of mainAxisSize) — which is exactly how the bar
            // previously stretched full-width whenever an ancestor (like
            // the host's own width clamp) handed it a bounded-but-large
            // constraint. So the query field's width is computed
            // explicitly here instead: as wide as
            // [kLayrzFindBarQueryFieldMaxWidth] normally, shrinking only
            // when the bar's own available width (from
            // constraints.maxWidth, set by
            // LayrzFindInPageHostState._buildFindBarOverlay) is narrower
            // than the rest of the row needs — keeping both the Row and
            // this whole Column (see below) a true shrink-to-fit,
            // no-flex-child layout, rather than expanding to fill.
            //
            // The three trailing buttons are Fab-style, whose width always
            // equals the resolved button height (square, icon-only — see
            // LayrzButton's own sizing doc); this mirrors `ScaffoldRow`'s
            // identical `n * kLayrzButtonHeight + (n - 1) * sp1`
            // computation in `scaffold/src/scaffold_row.dart` for the same
            // reason: that height is compactness-dependent, so it is read
            // from the same [BuildContext] rather than hardcoded.
            final buttonHeight = context.isCompact ? kLayrzButtonCompactHeight : kLayrzButtonHeight;
            final buttonsWidth = 3 * buttonHeight + 2 * tokens.spacing.sp1;
            // `constraints.maxWidth` here is the *whole bar's* outer width
            // (this LayoutBuilder sits outside the Padding below), so the
            // Row's own horizontal padding — applied once on each side —
            // must be subtracted too, alongside the counter/spacing/button
            // widths, to get the width actually available to the query
            // field inside that padding.
            final horizontalPadding = tokens.spacing.sp1;
            final reservedWidth = horizontalPadding + tokens.spacing.sp2 + 72 + tokens.spacing.sp1 + buttonsWidth;
            // Floored at 0 rather than at [kLayrzFindBarQueryFieldMinWidth]
            // — on a viewport tight enough that even the counter and three
            // buttons alone barely fit, giving the field a hard minimum
            // would force the very overflow this responsive sizing exists
            // to prevent. The field still degrades gracefully well before
            // that point: [kLayrzFindBarQueryFieldMinWidth] is the width it
            // aims to keep whenever the available space allows it.
            final queryFieldWidth = (constraints.maxWidth - reservedWidth).clamp(
              0.0,
              kLayrzFindBarQueryFieldMaxWidth,
            );
            // The row's total rendered width, padding included — handed to
            // the searching-indicator strip below instead of that
            // indicator requesting `width: double.infinity` itself (which
            // would otherwise win the Column's cross-axis sizing and
            // re-expand the whole bar to its incoming max width).
            final barContentWidth = queryFieldWidth + reservedWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(tokens.spacing.sp1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: queryFieldWidth,
                        child: LayrzTextInput(
                          controller: _queryController,
                          focusNode: _queryFocusNode,
                          hintText: 'Find in page',
                          hideDetails: true,
                          onChanged: _handleQueryChanged,
                          onSubmit: _handleSubmit,
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sp2),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '$currentOrdinal of $totalMatches',
                          textAlign: TextAlign.center,
                          style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sp1),
                      LayrzButton(
                        key: const ValueKey('layrz-find-bar-previous'),
                        labelText: 'Previous match',
                        icon: MdiIcons.chevronUp,
                        onTap: hasMatches ? controller.previous : null,
                        isDisabled: !hasMatches,
                        style: LayrzButtonStyle.textFab,
                      ),
                      LayrzButton(
                        key: const ValueKey('layrz-find-bar-next'),
                        labelText: 'Next match',
                        icon: MdiIcons.chevronDown,
                        onTap: hasMatches ? controller.next : null,
                        isDisabled: !hasMatches,
                        style: LayrzButtonStyle.textFab,
                      ),
                      LayrzButton(
                        key: const ValueKey('layrz-find-bar-close'),
                        labelText: 'Close find',
                        icon: MdiIcons.close,
                        onTap: widget.onClose,
                        style: LayrzButtonStyle.textFab,
                      ),
                    ],
                  ),
                ),
                _buildSearchingIndicator(
                  tokens: tokens,
                  isSearching: controller.isSearching,
                  width: barContentWidth,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the thin indeterminate progress line reserved at the bottom edge
  /// of the bar — see [kLayrzFindBarSearchingIndicatorHeight].
  ///
  /// The [SizedBox] slot is always present at a fixed height, so the bar's
  /// overall height never changes; only the child's opacity toggles between
  /// [isSearching] states, per D15's "vary opacity, never geometry" rule.
  /// The counter ("N of M") already conveys search state to assistive
  /// technology, so this decorative line is excluded from the semantics tree
  /// entirely rather than announced a second time.
  ///
  /// [width] is the exact width of the row above (see
  /// [_LayrzFindBarState.build]'s `barContentWidth`) rather than
  /// `double.infinity` — a `double.infinity` child here would win this
  /// Column's cross-axis sizing and re-expand the whole compact bar to
  /// whatever max width its ancestor offers, undoing the top-right compact
  /// layout entirely.
  Widget _buildSearchingIndicator({required LayrzTokens tokens, required bool isSearching, required double width}) {
    return ExcludeSemantics(
      child: SizedBox(
        height: kLayrzFindBarSearchingIndicatorHeight,
        width: width,
        child: Opacity(
          opacity: isSearching ? 1.0 : 0.0,
          child: LayrzProgressBar(
            value: null,
            height: kLayrzFindBarSearchingIndicatorHeight,
            borderRadius: 0,
            type: LayrzProgressType.custom,
            color: tokens.colors.selectionColor,
          ),
        ),
      ),
    );
  }
}

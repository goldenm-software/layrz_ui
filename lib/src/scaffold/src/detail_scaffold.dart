import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/scrollbar/scrollbar.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

/// A three-slot layout -- pinned title, scrollable body, pinned actions
/// footer -- meant to be returned directly from a [LayrzScaffoldShell] detail
/// builder, e.g. `controller.open(builder: (_) => LayrzDetailScaffold(...))`.
///
/// `DetailPane` (the widget that renders whatever the detail builder returns)
/// hands that builder either a bounded box -- in the wide/folded side-by-side
/// layout, where the pane sits inside an `Expanded` -- or an *unbounded* one,
/// because on narrow viewports the same builder output is instead shown
/// inside `LayrzBottomSheet`, which wraps it in a `SingleChildScrollView`
/// unless the caller opts out.
///
/// [LayrzDetailScaffold] resolves that difference by asking
/// [LayrzBottomSheetScope] whether it is currently inside a
/// [LayrzBottomSheet] at all -- it never needs to be told directly, and
/// neither does whatever wrapper widget a caller's detail builder happens to
/// return (e.g. `builder: (_) => CategoryForm(...)`, where `CategoryForm`
/// itself builds the `LayrzDetailScaffold` one or more levels down).
/// [LayrzBottomSheetScope.maybeOf] walks up the element tree regardless of
/// how many such wrappers sit in between, so detection works no matter how
/// this widget actually reaches the sheet's content:
///
/// - Outside a sheet (no [LayrzBottomSheetScope] ancestor -- the bounded
///   desktop/folded pane), the body slot is wrapped in an [Expanded] inside a
///   `Column(mainAxisSize: MainAxisSize.max)`, so the body fills all
///   remaining height and [actions] pins to the bottom of the pane instead of
///   floating up directly under a short body.
/// - Inside a [LayrzBottomSheet] (a [LayrzBottomSheetScope] ancestor is
///   found), the body slot is wrapped in a [Flexible] inside a
///   `Column(mainAxisSize: MainAxisSize.min)`, which shrink-wraps under the
///   sheet's unbounded height instead of throwing a "RenderFlex ...
///   unbounded height" error.
///
/// Either way, the body slot owns its own [LayrzScrollbar] +
/// [SingleChildScrollView], so the caller's [body] itself needs no
/// `Expanded`/`Flexible` of its own -- pass plain content (e.g. a `Column` of
/// fields) and let this widget own the scrolling.
///
/// The three-slot structure mirrors `LayrzDialog`'s own title/content/actions
/// slot layout (see `lib/src/dialogs/src/dialog.dart`), reusing the same
/// spacing tokens and typography treatment so a detail pane and a dialog read
/// as the same visual language.
///
/// This widget does NOT introduce its own [SelectableRegion]. `DetailPane`
/// already wraps whatever the detail builder returns -- this widget included
/// -- in exactly one [SelectableRegion] of its own (see
/// `lib/src/scaffold/src/detail_pane.dart`), so nesting a second one here
/// would create two overlapping selection regions over the same content,
/// which is a source of selection bugs rather than a feature.
class LayrzDetailScaffold extends StatefulWidget {
  /// The pinned header shown above [body]. Always rendered -- unlike
  /// [actions], there is no way to omit it -- and never scrolls with the
  /// rest of the content.
  final Widget title;

  /// The scrollable content region, shown below [title] and above [actions]
  /// (when present).
  ///
  /// This widget gives [body] a bounded height (via [Expanded] or [Flexible],
  /// depending on whether a [LayrzBottomSheetScope] ancestor is found) plus
  /// its own scroll view, so [body] never needs to wrap any part of itself in
  /// `Expanded`/`Flexible` to fill space -- pass plain content (e.g. a
  /// `Column` of form fields) and any overflow scrolls automatically.
  final Widget body;

  /// Optional pinned footer buttons, right-aligned below [body].
  ///
  /// When `null` or empty, no footer row is rendered at all -- not even an
  /// empty one -- so [body] reclaims that vertical space. Typed to
  /// [LayrzButton] specifically so only real buttons can be passed here,
  /// matching `LayrzDialog`'s own `actions` contract.
  final List<LayrzButton>? actions;

  /// Creates a new [LayrzDetailScaffold].
  ///
  /// - [title]: the pinned header shown above [body]. Required.
  /// - [body]: the scrollable content region. Required.
  /// - [actions]: optional pinned footer buttons, right-aligned. Defaults to
  ///   `null`, which renders no footer at all.
  const LayrzDetailScaffold({super.key, required this.title, required this.body, this.actions});

  @override
  State<LayrzDetailScaffold> createState() => _LayrzDetailScaffoldState();
}

class _LayrzDetailScaffoldState extends State<LayrzDetailScaffold> {
  /// Owns the scroll position of [LayrzDetailScaffold.body]'s scroll view.
  ///
  /// Created in [initState] and disposed in [dispose], mirroring how
  /// `LayrzDialog` owns its own `_scrollController` for its content slot.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Self-detected: true when this widget is rendered somewhere inside a
    // LayrzBottomSheet, however many wrapper widgets separate it from the
    // sheet's own content subtree -- see LayrzBottomSheetScope's own doc for
    // why an ancestor lookup, rather than a flag threaded through by the
    // caller or stamped on by LayrzScaffoldShell, is what makes this work
    // through an arbitrary caller-supplied wrapper.
    final inSheet = LayrzBottomSheetScope.maybeOf(context) != null;

    final bodyScrollView = LayrzScrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: DefaultTextStyle.merge(style: tokens.typography.body, child: widget.body),
      ),
    );

    return Padding(
      padding: tokens.spacing.pd2,
      child: Column(
        mainAxisSize: inSheet ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spacing.sp2,
        children: [
          DefaultTextStyle.merge(style: tokens.typography.headline, child: widget.title),

          inSheet ? Flexible(child: bodyScrollView) : Expanded(child: bodyScrollView),
          if (widget.actions?.isNotEmpty ?? false) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: tokens.spacing.sp2,
              children: widget.actions!.map((button) => button).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

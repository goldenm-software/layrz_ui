import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/refresh/refresh.dart';

/// The list panel's own footer-region refresh affordance.
///
/// [LayrzScaffoldShell] does not float a refresh button over the whole shell
/// (that was the reported problem: a fallback button positioned relative to
/// the entire two-pane shell lands over the detail pane too) and does not add
/// a header/toolbar button either — per Kenny's design call, the refresh
/// control lives beside whatever the consumer already put in
/// `LayrzScaffoldShell.footer`, inside the list panel's own footer region, so
/// it is always reachable regardless of platform.
///
/// This widget is deliberately just a small icon button wired to
/// [LayrzRefreshController.refresh]: [LayrzRefreshIndicator] itself has no way
/// to relocate its built-in fallback button to a caller-chosen position (it
/// always floats top-right over its `child`), so that indicator is used
/// elsewhere purely for the drag gesture and the pull visual, and this footer
/// affordance is the actual desktop/always-available entry point. Both drive
/// the exact same [LayrzRefreshController], so a drag-triggered refresh and a
/// footer-triggered refresh animate through the identical state machine and
/// this button's busy spinner reflects either one.
class ListPanelRefreshFooter extends StatefulWidget {
  /// Creates a new [ListPanelRefreshFooter].
  ///
  /// - [controller]: The refresh controller whose [LayrzRefreshController.refresh]
  ///   this affordance's tap calls, and whose [LayrzRefreshController.isRefreshing]
  ///   drives its busy/spinner state. Required.
  /// - [onRefresh]: The async callback invoked by a tap, forwarded verbatim to
  ///   [LayrzRefreshController.refresh]. Required.
  const ListPanelRefreshFooter({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  /// The refresh controller whose [LayrzRefreshController.refresh] this
  /// affordance's tap calls, and whose [LayrzRefreshController.isRefreshing]
  /// drives its busy/spinner state.
  final LayrzRefreshController controller;

  /// The async callback invoked by a tap, forwarded verbatim to
  /// [LayrzRefreshController.refresh].
  final Future<void> Function() onRefresh;

  @override
  State<ListPanelRefreshFooter> createState() => _ListPanelRefreshFooterState();
}

class _ListPanelRefreshFooterState extends State<ListPanelRefreshFooter> {
  /// Drives [LayrzButton]'s own busy/spinner rendering, kept in sync with
  /// [ListPanelRefreshFooter.controller] by [_onRefreshControllerChanged].
  ///
  /// A separate controller (rather than reading
  /// [LayrzRefreshController.isRefreshing] directly in `build`) is used
  /// because [LayrzButton] only knows how to render a loading spinner from a
  /// [LayrzButtonController] — mirroring how `_FallbackRefreshButton` inside
  /// `LayrzRefreshIndicator` itself swaps in a bare [LayrzRefreshVisual]
  /// rather than a [LayrzButtonController], which is not reusable here since
  /// this widget is a public, non-fallback affordance built from
  /// [LayrzButton] directly.
  late final LayrzButtonController _buttonController;

  @override
  void initState() {
    super.initState();
    _buttonController = LayrzButtonController();
    widget.controller.addListener(_onRefreshControllerChanged);
    _syncButtonController();
  }

  @override
  void didUpdateWidget(ListPanelRefreshFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onRefreshControllerChanged);
      widget.controller.addListener(_onRefreshControllerChanged);
      _syncButtonController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onRefreshControllerChanged);
    _buttonController.dispose();
    super.dispose();
  }

  /// Mirrors [LayrzRefreshController.isRefreshing] into [_buttonController]'s
  /// loading state whenever the refresh controller notifies.
  void _onRefreshControllerChanged() => _syncButtonController();

  /// Starts or stops [_buttonController]'s loading indicator to match
  /// [ListPanelRefreshFooter.controller]'s current [LayrzRefreshController.isRefreshing].
  void _syncButtonController() {
    if (widget.controller.isRefreshing) {
      _buttonController.startLoading();
    } else {
      _buttonController.stopLoading();
    }
  }

  /// Triggers a refresh by delegating to [LayrzRefreshController.refresh].
  ///
  /// [LayrzRefreshController.refresh] is already a no-op while a refresh is
  /// in flight, so this needs no re-entrancy guard of its own.
  void _handleTap() {
    widget.controller.refresh(widget.onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = context.l10n.scaffoldRefresh;

    return LayrzButton(
      key: const ValueKey('layrz-scaffold-list-panel-refresh-footer-button'),
      labelText: label,
      icon: MdiIcons.refresh,
      style: LayrzButtonStyle.textFab,
      controller: _buttonController,
      hintText: label,
      type: LayrzButtonType.custom,
      color: tokens.colors.fg2,
      onTap: _handleTap,
    );
  }
}

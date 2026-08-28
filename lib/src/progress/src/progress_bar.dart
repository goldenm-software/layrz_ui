import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'progress_painter.dart';
import 'progress_style_spec.dart';

/// The fraction of the track width covered by the indeterminate sweep.
///
/// Matches `LayrzButtonIndicator`'s `sweepWidthFraction` (`button_indicator.dart:170`)
/// so the two loading affordances read the same way, even though this widget
/// does not import or extract from that file.
const double _kSweepWidthFraction = 0.3;

/// A standardized progress bar with determinate and indeterminate modes.
///
/// **Determinate mode** (`value` non-null, in `[0.0, 1.0]`): renders a filled
/// bar that grows from the leading edge as `value` increases — `value: 1.0`
/// is a full bar. This is the opposite of `LayrzButtonIndicator`'s internal
/// determinate mode, which depletes from full to empty; that behaviour is
/// correct for a button countdown and would be wrong here, so it is not
/// replicated (see the component's plan, requirement R-3).
///
/// **Indeterminate mode** (`value == null`): renders a capsule that sweeps
/// back and forth across the track, looping for as long as the widget is
/// mounted. `null` always means indeterminate, never zero progress — a caller
/// that wants to show "no progress yet" should pass `0.0` explicitly.
///
/// Colors follow the `LayrzChipType` semantic convention (see [type] and
/// [LayrzProgressStyleSpec.resolve]) rather than inventing a second one.
///
/// This widget is display-only. It is not interactive — a draggable variant
/// is `LayrzSlider`'s responsibility, not this widget's. It also has no
/// circular/ring variant; a future `LayrzProgressRing` would be a separate
/// component.
class LayrzProgressBar extends StatefulWidget {
  /// The determinate progress fraction, in `[0.0, 1.0]`, where `1.0` renders a
  /// full bar.
  ///
  /// When `null`, the bar renders in indeterminate mode instead — an infinite
  /// sweep animation used to indicate an in-progress operation of unknown
  /// duration. `null` never means zero progress; pass `0.0` explicitly for
  /// that case.
  final double? value;

  /// The semantic color type applied to the indicator fill.
  ///
  /// Defaults to [LayrzProgressBarType.info]. When set to
  /// [LayrzProgressBarType.custom], [color] is honoured instead of a token
  /// color.
  final LayrzProgressBarType type;

  /// The explicit indicator color used when [type] is
  /// [LayrzProgressBarType.custom].
  ///
  /// Ignored for every other [type]. When [type] is custom and this is null,
  /// falls back to `tokens.colors.primary.shade500`.
  final Color? color;

  /// The height of the bar in logical pixels.
  ///
  /// Defaults to `8.0`, matching the design system's default compact control
  /// height for linear indicators.
  final double height;

  /// The border radius applied to the track and the indicator, in logical
  /// pixels.
  ///
  /// Defaults to `tokens.radius.full` (a pill shape) when null, matching the
  /// rounded-capsule convention used by `LayrzButtonIndicator`.
  final double? borderRadius;

  /// An accessibility label describing what this progress bar represents,
  /// e.g. `'Upload progress'`.
  ///
  /// When null, a generic label is announced instead (`'Progress'` for
  /// determinate mode, `'Loading'` for indeterminate mode). The percentage or
  /// busy state is always announced in addition to this label, never in place
  /// of it.
  final String? semanticLabel;

  /// Creates a new [LayrzProgressBar].
  const LayrzProgressBar({
    super.key,
    this.value,
    this.type = LayrzProgressBarType.info,
    this.color,
    this.height = 8.0,
    this.borderRadius,
    this.semanticLabel,
  }) : assert(
         value == null || (value >= 0.0 && value <= 1.0),
         'value must be null (indeterminate) or within [0.0, 1.0].',
       );

  @override
  State<LayrzProgressBar> createState() => _LayrzProgressBarState();
}

class _LayrzProgressBarState extends State<LayrzProgressBar> with SingleTickerProviderStateMixin {
  AnimationController? _sweepController;

  bool get _isIndeterminate => widget.value == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Token and MediaQuery lookups are only safe once dependencies are
    // established, which initState cannot guarantee — hence deferring the
    // sweep controller's (re)creation to here rather than initState.
    if (_isIndeterminate) {
      _startSweep();
    }
  }

  @override
  void didUpdateWidget(covariant LayrzProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasIndeterminate = oldWidget.value == null;
    if (_isIndeterminate && !wasIndeterminate) {
      _startSweep();
    } else if (!_isIndeterminate && wasIndeterminate) {
      _stopSweep();
    }
  }

  @override
  void dispose() {
    _stopSweep();
    super.dispose();
  }

  /// Starts (or restarts) the indeterminate sweep ticker.
  ///
  /// The controller is created lazily, only while indeterminate mode is
  /// active, so the ticker never stays alive once the bar becomes determinate
  /// or is removed from the tree. When reduce-motion is active, any
  /// previously-created controller is torn down instead of merely left
  /// unstarted — `build()`'s reduce-motion branch never reads it, so keeping
  /// it alive would only leak a ticker that repeats forever with nothing
  /// consuming its output. A later call (e.g. reduce-motion switching back
  /// off) recreates it via the `??=` above.
  void _startSweep() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _stopSweep();
      return;
    }
    final tokens = context.tokens;
    _sweepController ??= AnimationController(
      duration: tokens.motion.dDialog,
      vsync: this,
    );
    _sweepController!.repeat();
  }

  /// Stops and disposes the indeterminate sweep ticker.
  void _stopSweep() {
    _sweepController?.dispose();
    _sweepController = null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = LayrzProgressStyleSpec.resolve(type: widget.type, color: widget.color, tokens: tokens);
    final radius = widget.borderRadius ?? tokens.radius.full;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final value = widget.value;
    final Widget painted;
    if (value != null) {
      painted = CustomPaint(
        painter: LayrzProgressPainter(
          determinateValue: value,
          sweepPosition: 0.0,
          sweepWidthFraction: _kSweepWidthFraction,
          trackColor: style.trackColor,
          indicatorColor: style.indicatorColor,
          borderRadius: radius,
        ),
        size: Size(double.infinity, widget.height),
      );
    } else if (reduceMotion) {
      // Reduced motion: freeze the sweep at its start position rather than
      // looping, per MediaQuery.disableAnimationsOf's contract.
      painted = CustomPaint(
        painter: LayrzProgressPainter(
          determinateValue: null,
          sweepPosition: 0.0,
          sweepWidthFraction: _kSweepWidthFraction,
          trackColor: style.trackColor,
          indicatorColor: style.indicatorColor,
          borderRadius: radius,
        ),
        size: Size(double.infinity, widget.height),
      );
    } else {
      final controller = _sweepController;
      painted = AnimatedBuilder(
        animation: controller!,
        builder: (context, _) {
          return CustomPaint(
            painter: LayrzProgressPainter(
              determinateValue: null,
              sweepPosition: controller.value,
              sweepWidthFraction: _kSweepWidthFraction,
              trackColor: style.trackColor,
              indicatorColor: style.indicatorColor,
              borderRadius: radius,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? (value != null ? 'Progress' : 'Loading'),
      value: value != null ? '${(value * 100).round()}%' : null,
      liveRegion: true,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: painted,
      ),
    );
  }
}

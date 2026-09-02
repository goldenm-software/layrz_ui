import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'progress_format.dart';
import 'progress_label_painter.dart';
import 'progress_painter.dart';
import 'progress_style_spec.dart';
import 'progress_type.dart';

/// The fraction of the track width covered by the indeterminate sweep.
///
/// Matches `LayrzButtonIndicator`'s `sweepWidthFraction` (`button_indicator.dart:170`)
/// so the two loading affordances read the same way, even though this widget
/// does not import or extract from that file.
const double _kSweepWidthFraction = 0.3;

/// A standardized progress indicator with determinate and indeterminate
/// modes, in either a linear (bar) or circular (ring) format.
///
/// **Format** ([format]): [LayrzProgressFormat.linear] (the default) renders
/// a horizontal track; [LayrzProgressFormat.circular] renders a ring. Both
/// formats share the same determinate/indeterminate machinery, semantic color
/// resolution, motion timing, and reduced-motion handling — only the
/// geometry painted, and which sizing parameter applies, differs.
///
/// **Determinate mode** (`value` non-null, in `[0.0, 1.0]`): in linear format,
/// renders a filled bar that grows from the leading edge as `value`
/// increases — `value: 1.0` is a full bar. In circular format, renders an arc
/// that sweeps clockwise from 12 o'clock as `value` increases — `value: 1.0`
/// is a complete ring. Both are the opposite of `LayrzButtonIndicator`'s
/// internal determinate mode, which depletes from full to empty; that
/// behaviour is correct for a button countdown and would be wrong here, so it
/// is not replicated (see the component's plan, requirement R-3).
///
/// **Indeterminate mode** (`value == null`): in linear format, renders a
/// capsule that sweeps back and forth across the track; in circular format,
/// renders an arc that rotates continuously around the ring. Both loop for as
/// long as the widget is mounted. `null` always means indeterminate, never
/// zero progress — a caller that wants to show "no progress yet" should pass
/// `0.0` explicitly.
///
/// Colors follow the `LayrzChipType` semantic convention (see [type] and
/// [LayrzProgressStyleSpec.resolve]) rather than inventing a second one.
///
/// **Sizing parameters are format-specific.** [height] applies only to
/// [LayrzProgressFormat.linear]; [size] and [strokeWidth] apply only to
/// [LayrzProgressFormat.circular]. Setting a parameter that does not apply to
/// the current [format] is harmless — it is simply ignored rather than
/// asserted against, since a caller that flips [format] at runtime (e.g. via
/// a settings toggle) would otherwise need to also strip out the now-unused
/// parameter to avoid a crash. See each parameter's own doc for which format
/// it governs.
///
/// This widget is display-only. It is not interactive — a draggable variant
/// is `LayrzSlider`'s responsibility, not this widget's.
class LayrzProgressBar extends StatefulWidget {
  /// The determinate progress fraction, in `[0.0, 1.0]`, where `1.0` renders a
  /// full bar (linear) or a complete ring (circular).
  ///
  /// When `null`, the indicator renders in indeterminate mode instead — an
  /// infinite sweep/rotation animation used to indicate an in-progress
  /// operation of unknown duration. `null` never means zero progress; pass
  /// `0.0` explicitly for that case.
  final double? value;

  /// The rendering format: [LayrzProgressFormat.linear] (a horizontal bar) or
  /// [LayrzProgressFormat.circular] (a ring).
  ///
  /// Defaults to [LayrzProgressFormat.linear].
  final LayrzProgressFormat format;

  /// The semantic color type applied to the indicator fill.
  ///
  /// Defaults to [LayrzProgressType.info]. When set to
  /// [LayrzProgressType.custom], [color] is honoured instead of a token
  /// color. Applies identically regardless of [format] (shape).
  final LayrzProgressType type;

  /// The explicit indicator color used when [type] is
  /// [LayrzProgressType.custom].
  ///
  /// Ignored for every other [type]. When [type] is custom and this is null,
  /// falls back to `tokens.colors.primary.shade500`.
  final Color? color;

  /// The height of the bar in logical pixels. **Linear format only** —
  /// ignored when [format] is [LayrzProgressFormat.circular].
  ///
  /// Defaults to [kLayrzProgressBarHeight] (`16.0`), a substantial, modern bar
  /// thickness rather than a hairline.
  final double height;

  /// The border radius applied to the track and the indicator, in logical
  /// pixels. **Linear format only** — ignored when [format] is
  /// [LayrzProgressFormat.circular], which is always a full ring.
  ///
  /// Defaults to `tokens.radius.r1` (`6.0`) when null — a clearly rounded box
  /// rather than a pill, matching this design system's general preference for
  /// rounded rectangles over capsule shapes. At the default [height] of
  /// `16.0`, `r2` (`10.0`) reads close to a pill again, so `r1` is the
  /// smallest step that still looks deliberately rounded rather than sharp.
  final double? borderRadius;

  /// The diagonal size (width and height) of the ring, in logical pixels.
  /// **Circular format only** — ignored when [format] is
  /// [LayrzProgressFormat.linear].
  ///
  /// Defaults to [kLayrzProgressCircularSize] (`50.0`), producing a 50×50
  /// square ring.
  final double size;

  /// The stroke thickness of the ring, in logical pixels. **Circular format
  /// only** — ignored when [format] is [LayrzProgressFormat.linear].
  ///
  /// Defaults to [kLayrzProgressCircularStrokeWidth] (`4.0`).
  final double strokeWidth;

  /// An accessibility label describing what this progress indicator
  /// represents, e.g. `'Upload progress'`.
  ///
  /// When null, a generic label is announced instead (`'Progress'` for
  /// determinate mode, `'Loading'` for indeterminate mode). The percentage or
  /// busy state is always announced in addition to this label, never in place
  /// of it. Applies identically regardless of [format] (shape).
  final String? semanticLabel;

  /// Whether to paint the current value as a percentage label, centered
  /// inside the bar. **Linear, determinate mode only** — ignored (no label
  /// painted) when [format] is [LayrzProgressFormat.circular], or when this
  /// bar is indeterminate (`value == null`), since a percentage is
  /// meaningless while progress is unknown.
  ///
  /// Defaults to `false`. This widget shipped without an inside label, so
  /// defaulting it on would silently change the appearance of every existing
  /// caller; making it opt-in preserves current behaviour for callers that
  /// do not ask for it. The value is always exposed to assistive technology
  /// via `Semantics.value` regardless of this flag — turning the visible
  /// label off never removes the accessible announcement.
  final bool showLabel;

  /// The number of decimal places shown in the value label, when [showLabel]
  /// is true.
  ///
  /// Defaults to `0` (e.g. `'42%'`). Formatting uses `num.toStringAsFixed`
  /// rather than `package:intl`'s `NumberFormat` — `intl` is not a dependency
  /// of this package, and adding one solely for this is a decision for the
  /// package maintainer, not something to introduce unilaterally here.
  /// Ignored when [showLabel] is false.
  final int decimals;

  /// Creates a new [LayrzProgressBar].
  const LayrzProgressBar({
    super.key,
    this.value,
    this.format = LayrzProgressFormat.linear,
    this.type = LayrzProgressType.info,
    this.color,
    this.height = kLayrzProgressBarHeight,
    this.borderRadius,
    this.size = kLayrzProgressCircularSize,
    this.strokeWidth = kLayrzProgressCircularStrokeWidth,
    this.semanticLabel,
    this.showLabel = false,
    this.decimals = 0,
  }) : assert(
         value == null || (value >= 0.0 && value <= 1.0),
         'value must be null (indeterminate) or within [0.0, 1.0].',
       ),
       assert(decimals >= 0, 'decimals must be zero or a positive integer.');

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
      duration: tokens.motion.dIndeterminate,
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
    final isCircular = widget.format == LayrzProgressFormat.circular;
    final radius = widget.borderRadius ?? tokens.radius.r1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final boxSize = isCircular ? Size.square(widget.size) : Size(double.infinity, widget.height);

    final value = widget.value;
    // The circular format keeps its stroked arc isolated in its own
    // compositor layer via RepaintBoundary. An indeterminate ring repaints
    // every animation frame; without a boundary, that invalidates the
    // surrounding layer too and forces Impeller to re-rasterize more than the
    // ring on every tick, which reads as rougher edges under load. A
    // determinate ring still benefits: isolating it means a value change
    // never forces a sibling widget's layer to redraw either.
    final Widget painted;
    if (value != null) {
      final bar = CustomPaint(
        painter: LayrzProgressPainter(
          shape: widget.format,
          determinateValue: value,
          sweepPosition: 0.0,
          sweepWidthFraction: _kSweepWidthFraction,
          trackColor: style.trackColor,
          indicatorColor: style.indicatorColor,
          borderRadius: radius,
          strokeWidth: widget.strokeWidth,
        ),
        size: boxSize,
      );

      // The centered value label is a linear-only, determinate-only
      // affordance: circular mode has no straight run of pixels to center
      // text along, and an indeterminate bar has no percentage to show.
      final showLabel = widget.showLabel && !isCircular;
      painted = _wrapCircular(
        showLabel ? _buildLabeledBar(bar: bar, value: value, boxSize: boxSize, style: style, tokens: tokens) : bar,
      );
    } else if (reduceMotion) {
      // Reduced motion: freeze the sweep at its start position rather than
      // looping, per MediaQuery.disableAnimationsOf's contract.
      painted = _wrapCircular(
        CustomPaint(
          painter: LayrzProgressPainter(
            shape: widget.format,
            determinateValue: null,
            sweepPosition: 0.0,
            sweepWidthFraction: _kSweepWidthFraction,
            trackColor: style.trackColor,
            indicatorColor: style.indicatorColor,
            borderRadius: radius,
            strokeWidth: widget.strokeWidth,
          ),
          size: boxSize,
        ),
      );
    } else {
      final controller = _sweepController;
      painted = _wrapCircular(
        AnimatedBuilder(
          animation: controller!,
          builder: (context, _) {
            return CustomPaint(
              painter: LayrzProgressPainter(
                shape: widget.format,
                determinateValue: null,
                sweepPosition: controller.value,
                sweepWidthFraction: _kSweepWidthFraction,
                trackColor: style.trackColor,
                indicatorColor: style.indicatorColor,
                borderRadius: radius,
                strokeWidth: widget.strokeWidth,
              ),
              // This branch repaints every animation tick, so the raster
              // cache would never get to reuse a cached bitmap anyway —
              // telling the compositor not to bother caching it (rather than
              // leaving the decision to its own heuristics) avoids wasted
              // cache-population work on a layer that is about to be
              // invalidated regardless.
              willChange: true,
              size: boxSize,
            );
          },
        ),
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? (value != null ? 'Progress' : 'Loading'),
      value: value != null ? '${(value * 100).round()}%' : null,
      liveRegion: true,
      child: SizedBox(
        height: boxSize.height,
        width: boxSize.width,
        child: painted,
      ),
    );
  }

  /// Composes [bar] with a centered value-percentage label painted on top,
  /// via a [Stack] rather than folding text painting into
  /// [LayrzProgressPainter] itself — that painter's concern is track/fill
  /// geometry only, shared by both formats, and label painting is a
  /// linear-only, opt-in concern layered above it.
  ///
  /// The label is painted by [LayrzProgressLabelPainter], split at the
  /// fill/track boundary so it stays legible against both the filled
  /// (indicator) and unfilled (track) portions of the bar — see that
  /// painter's doc for why a single text color cannot serve both. Both
  /// contrast colors are derived from `Color.contrastColor`
  /// (`lib/src/extensions/src/color.dart`), the same primitive already used
  /// by `LayrzChip`, `LayrzAlert`, and `LayrzButton` to pick legible text
  /// against an arbitrary accent — not a one-off computation invented here.
  Widget _buildLabeledBar({
    required Widget bar,
    required double value,
    required Size boxSize,
    required LayrzProgressStyleSpec style,
    required LayrzTokens tokens,
  }) {
    final text = '${(value * 100).toStringAsFixed(widget.decimals)}%';
    final labelStyle = tokens.typography.label.copyWith(fontWeight: FontWeight.w600);

    return Stack(
      alignment: Alignment.center,
      children: [
        bar,
        Positioned.fill(
          child: CustomPaint(
            painter: LayrzProgressLabelPainter(
              text: text,
              style: labelStyle,
              fillBoundary: boxSize.width.isFinite ? boxSize.width * value.clamp(0.0, 1.0) : 0.0,
              indicatorContrastColor: style.indicatorColor.contrastColor,
              trackContrastColor: style.trackColor.contrastColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Wraps [child] in a [RepaintBoundary] when this bar is in
  /// [LayrzProgressFormat.circular] format, and returns it unchanged
  /// otherwise.
  ///
  /// The linear format's rounded-rect fills alias far less noticeably than a
  /// thin stroked circular arc, and the extra compositor layer is not free —
  /// so the boundary is scoped to the format that actually benefits from it.
  Widget _wrapCircular(Widget child) {
    if (widget.format != LayrzProgressFormat.circular) return child;
    return RepaintBoundary(child: child);
  }
}

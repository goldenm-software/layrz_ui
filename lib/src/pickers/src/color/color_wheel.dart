import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'color_wheel_painter.dart';

/// A from-scratch, Material-free HSV color wheel: a circular hue/saturation
/// disc (hue swept around the ring, saturation mapped to radius) plus a
/// separate value/brightness slider beneath it.
///
/// **Decision D-wheel**: the verbatim requirement (DESIGN-54) asks for "a
/// full HSV color wheel disc" — this widget is that disc, not the
/// alternative HSV-square-plus-hue-slider shape some color pickers use.
/// [LayrzColorWheelPainter] (`color_wheel_painter.dart`) owns the actual
/// paint routine; this widget owns the public contract, the value/
/// brightness slider, and all gesture hit-testing (hue = angle from
/// center, saturation = normalized radius).
///
/// **Uncontrolled from the outside beyond [value]/[onChanged].** This
/// widget keeps no draft state of its own distinct from what it reports —
/// every drag/tap immediately reports the resolved [Color] via [onChanged].
/// [LayrzColorSurface] (the caller) is what stages that into its own draft
/// and gates Save on it, matching every other staged-with-Save surface in
/// this module.
///
/// **Material-free.** No `ColorPicker`, no Material `Slider` for the
/// brightness control — the slider is a bespoke [GestureDetector] +
/// [CustomPaint]-free bar (a plain [Container] with a positioned thumb),
/// consistent with the rest of this design system.
class LayrzColorWheel extends StatefulWidget {
  /// The currently-selected color. The wheel derives its hue/saturation/
  /// value marker positions from this on every build, so an externally
  /// changed [value] (e.g. after a palette-tab pick, or a clipboard paste)
  /// repositions the marker and slider thumb without any extra plumbing.
  final Color value;

  /// Called with the newly-resolved color on every drag/tap on the disc, and
  /// on every drag on the value/brightness slider. Never called with a
  /// color identical to the last one reported for the same gesture instant
  /// (each callback reflects an actual position change), but may be called
  /// many times during a single drag — the caller (a staged draft) is
  /// expected to simply overwrite its own draft each time, not append.
  final ValueChanged<Color> onChanged;

  /// The side length, in logical pixels, of the square the wheel disc is
  /// painted within. Defaults to `220.0`, sized to comfortably fit inside
  /// the picker surface's tab body without forcing the surrounding drawer
  /// wider.
  final double size;

  /// Creates a new [LayrzColorWheel].
  const LayrzColorWheel({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 220.0,
  });

  @override
  State<LayrzColorWheel> createState() => _LayrzColorWheelState();
}

class _LayrzColorWheelState extends State<LayrzColorWheel> {
  /// Resolves [widget.value] into its HSV components on every build — this
  /// widget holds no independent hue/saturation/value state of its own, so a
  /// caller-driven [value] change (didUpdateWidget or a full rebuild) always
  /// wins without needing an explicit reconciliation method.
  HSVColor get _hsv => HSVColor.fromColor(widget.value);

  /// Converts a tap/drag position (local to the disc's own [size] x [size]
  /// box) into a hue/saturation pair and reports the resolved color.
  ///
  /// Hue is the angle from the box's center, in degrees `[0, 360)`,
  /// matching [LayrzColorWheelPainter]'s own angle convention exactly (hue
  /// 0 at the positive x-axis, increasing clockwise in Flutter's
  /// coordinate space) — painted hue and hit-tested hue must agree, or the
  /// marker drawn at "hue 90" would sit at a different physical angle than
  /// where a tap at that same angle resolves to.
  ///
  /// Saturation is the normalized distance from center, clamped to `[0,
  /// 1]` so a drag that overshoots the disc's outer edge still resolves to
  /// the disc's own rim color rather than an out-of-range value.
  void _handlePointer(Offset localPosition) {
    final radius = widget.size / 2;
    final center = Offset(radius, radius);
    final offset = localPosition - center;

    final distance = offset.distance;
    final saturation = (distance / radius).clamp(0.0, 1.0);

    var angle = math.atan2(offset.dy, offset.dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    final resolved = HSVColor.fromAHSV(1.0, angle, saturation, _hsv.value).toColor();
    widget.onChanged(resolved);
  }

  /// Reports a new color with only the value/brightness component changed,
  /// leaving the current hue/saturation untouched — used by the slider.
  void _handleValueChanged(double value) {
    widget.onChanged(HSVColor.fromAHSV(1.0, _hsv.hue, _hsv.saturation, value.clamp(0.0, 1.0)).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hsv = _hsv;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: context.l10n.colorPickerWheelTab,
          child: GestureDetector(
            onPanStart: (details) => _handlePointer(details.localPosition),
            onPanUpdate: (details) => _handlePointer(details.localPosition),
            onTapDown: (details) => _handlePointer(details.localPosition),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: LayrzColorWheelPainter(
                  hue: hsv.hue,
                  saturation: hsv.saturation,
                  value: hsv.value,
                  markerColor: widget.value,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sp3),
        _LayrzColorValueSlider(value: hsv.value, hue: hsv.hue, onChanged: _handleValueChanged),
      ],
    );
  }
}

/// The value/brightness slider composed beneath [LayrzColorWheel]'s disc —
/// a horizontal bar shaded from black (value 0) to the fully-bright hue
/// (value 1) at the currently-selected [hue], with a draggable thumb.
///
/// **Not a Material `Slider`.** Built from a plain [Container] gradient
/// track and a positioned circular thumb, gesture-driven via
/// [GestureDetector] — matching the rest of this design system's
/// Material-free slider-shaped controls (see `LayrzPickersRangeBar` for a
/// similarly bespoke bar-plus-thumb pattern in the pickers module).
///
/// **Interaction states vary only color/opacity per D15** — the track and
/// thumb geometry never change with drag state; only the thumb's border
/// color shifts to a stronger tone while dragging.
class _LayrzColorValueSlider extends StatefulWidget {
  /// The current value/brightness, in `[0, 1]`. Drives the thumb's
  /// horizontal position.
  final double value;

  /// The hue, in degrees `[0, 360)`, the track's gradient is rendered at
  /// (saturation fixed at `1.0` — this slider only ever varies brightness).
  final double hue;

  /// Called with the newly-selected value on every drag.
  final ValueChanged<double> onChanged;

  /// Creates a new value/brightness slider.
  const _LayrzColorValueSlider({required this.value, required this.hue, required this.onChanged});

  @override
  State<_LayrzColorValueSlider> createState() => _LayrzColorValueSliderState();
}

class _LayrzColorValueSliderState extends State<_LayrzColorValueSlider> {
  bool _isDragging = false;

  void _handleDrag(BoxConstraints constraints, Offset localPosition) {
    final fraction = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onChanged(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const trackHeight = 20.0;
    const thumbSize = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            setState(() => _isDragging = true);
            _handleDrag(constraints, details.localPosition);
          },
          onPanUpdate: (details) => _handleDrag(constraints, details.localPosition),
          onPanEnd: (_) => setState(() => _isDragging = false),
          onTapDown: (details) => _handleDrag(constraints, details.localPosition),
          child: SizedBox(
            height: thumbSize,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: tokens.radius.br2,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF000000),
                        HSVColor.fromAHSV(1.0, widget.hue, 1.0, 1.0).toColor(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (widget.value.clamp(0.0, 1.0) * (constraints.maxWidth - thumbSize)).clamp(
                    0.0,
                    constraints.maxWidth - thumbSize,
                  ),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1.0, widget.hue, 1.0, widget.value).toColor(),
                      border: Border.all(
                        color: _isDragging ? tokens.colors.fg1 : tokens.colors.fg2,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

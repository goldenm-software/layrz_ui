import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Holds the showcase's current [ColorblindMode]. Defaults to [ColorblindMode.normal]
/// so the app renders unmodified colors until the user opts into a simulation.
final colorblindModeProvider = StateProvider<ColorblindMode>((ref) => ColorblindMode.normal);

/// Holds the showcase's current colorblind simulation strength, from `0.0` (no
/// effect) to `1.0` (full simulation). Defaults to `1.0` so picking a
/// [ColorblindMode] other than [ColorblindMode.normal] is immediately visible
/// at full strength.
final colorblindStrengthProvider = StateProvider<double>((ref) => 1.0);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Holds the showcase's current [LayrzThemeMode]. Defaults to [LayrzThemeMode.system]
/// so the app follows the OS brightness until the user picks light or dark explicitly.
final themeModeProvider = StateProvider<LayrzThemeMode>((ref) => LayrzThemeMode.system);

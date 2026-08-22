import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Controller for managing the opened item state in [LayrzScaffoldShell].
///
/// This controller tracks selection by item key, not by item instance. This design
/// makes selection immune to instance replacement — when the list is rebuilt with
/// new instances (e.g., refetched from an API), the selection persists if the keys match.
///
/// It is a [ChangeNotifier], so listening widgets rebuild when the opened key changes.
///
/// **Ownership:** The consuming app creates and disposes the controller; the shell
/// listens and rebuilds. The shell does NOT dispose the controller it receives.
class LayrzScaffoldController extends ChangeNotifier {
  /// The key of the currently opened item, or null when the detail pane is closed.
  Key? _openedKey;

  /// Creates a new [LayrzScaffoldController] with an optional initial opened key.
  ///
  /// - [initialOpenedKey]: The key of the item to open on creation, or null to start closed.
  LayrzScaffoldController({
    Key? initialOpenedKey,
  }) : _openedKey = initialOpenedKey;

  /// The key of the currently opened item, or null when the detail pane is closed.
  Key? get openedKey => _openedKey;

  /// Whether the detail pane is currently open (i.e., [openedKey] is non-null).
  bool get isOpen => _openedKey != null;

  /// Opens the detail pane with the item at the given key.
  ///
  /// Sets [openedKey] to [key] and notifies listeners.
  /// If [key] is already opened, this is a no-op.
  ///
  /// - [key]: The key of the item to open.
  void open(Key key) {
    if (_openedKey == key) return;
    _openedKey = key;
    notifyListeners();
  }

  /// Closes the detail pane.
  ///
  /// Sets [openedKey] to null and notifies listeners.
  /// If already closed, this is a no-op.
  void close() {
    if (_openedKey == null) return;
    _openedKey = null;
    notifyListeners();
  }
}

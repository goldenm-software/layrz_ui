import 'package:flutter/foundation.dart';

/// Controller for managing the opened item state in [LayrzScaffoldShell].
///
/// This controller holds the currently opened item and provides methods to open/close
/// the detail pane. It is a [ChangeNotifier], so listening widgets rebuild when the
/// opened item changes.
///
/// **Ownership:** The consuming app creates and disposes the controller; the shell
/// listens and rebuilds. The shell does NOT dispose the controller it receives.
class LayrzScaffoldController<T> extends ChangeNotifier {
  /// The currently opened item, or null when the detail pane is closed.
  T? _opened;

  /// Creates a new [LayrzScaffoldController] with an optional initial opened item.
  ///
  /// - [initialOpened]: The item to open on creation, or null to start closed.
  LayrzScaffoldController({
    T? initialOpened,
  }) : _opened = initialOpened;

  /// The currently opened item, or null when the detail pane is closed.
  T? get opened => _opened;

  /// Whether the detail pane is currently open (i.e., [opened] is non-null).
  bool get isOpen => _opened != null;

  /// Opens the detail pane with the given item.
  ///
  /// Sets [opened] to [item] and notifies listeners.
  /// If [item] is already opened, this is a no-op.
  void open(T item) {
    if (identical(_opened, item)) return;
    _opened = item;
    notifyListeners();
  }

  /// Closes the detail pane.
  ///
  /// Sets [opened] to null and notifies listeners.
  /// If already closed, this is a no-op.
  void close() {
    if (_opened == null) return;
    _opened = null;
    notifyListeners();
  }
}

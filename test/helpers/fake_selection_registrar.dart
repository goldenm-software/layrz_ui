import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A minimal [SelectionRegistrar] used only to construct a real, enabled
/// [SelectionContainer] ancestor above a widget under test -- never expected
/// to actually receive a registration, since the widget's own
/// `SelectionContainer.disabled` boundary (DESIGN-135) shadows it for
/// everything beneath the widget's fixed chrome text.
///
/// Mirrors the fake registrar already used in `test/calendar/calendar_test.dart`,
/// pulled out here so every module's selection-boundary test can share it
/// instead of redefining it locally.
class FakeSelectionRegistrar extends SelectionRegistrar {
  @override
  void add(Selectable selectable) {}

  @override
  void remove(Selectable selectable) {}
}

/// A minimal, never-exercised [MultiSelectableSelectionContainerDelegate]
/// pairing with [FakeSelectionRegistrar] -- mirrors the Flutter framework's
/// own `TestContainerDelegate` test double (`selection_container_test.dart`).
/// Tests using this pair never drive selection through it; both overrides
/// simply throw if ever reached.
class TestSelectionContainerDelegate extends MultiSelectableSelectionContainerDelegate {
  @override
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    throw UnimplementedError();
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    throw UnimplementedError();
  }
}

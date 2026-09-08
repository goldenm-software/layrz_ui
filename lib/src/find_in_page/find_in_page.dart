/// Browser-style, in-page Ctrl/Cmd+F find — the production module built on
/// the reusable tools in `lib/src/search/` (see `search/search.dart`), and
/// proven end-to-end by the DESIGN-109 spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`).
///
/// Exports only the public surface: [LayrzFindInPageHost] (the app-wide host
/// [LayrzApp] installs automatically), [LayrzFindBar] (the floating find bar
/// it renders while open), [LayrzSearchable] (the escape hatch for
/// custom-painted, semantics-invisible text), and
/// [LayrzFindInPageController] (the state/lifecycle owner, reachable via
/// [LayrzFindInPageHost.of] for a caller that wants to drive find-in-page
/// programmatically).
library;

export 'src/find_bar.dart';
export 'src/find_in_page_controller.dart';
export 'src/find_in_page_host.dart';
export 'src/layrz_searchable.dart';

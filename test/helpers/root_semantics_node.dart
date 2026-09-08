import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns the root [SemanticsNode] of the single implicit view's semantics
/// tree, for use after [WidgetTester.ensureSemantics] has activated it.
///
/// Mirrors `_findSemanticsOwner` in `find_in_page_controller.dart`: walks
/// [RendererBinding.rootPipelineOwner]'s children (one [PipelineOwner] per
/// [View]; the single-implicit-view case these tests target has exactly one)
/// and returns the first exposing a non-null [PipelineOwner.semanticsOwner].
/// This is the non-deprecated equivalent of the now-deprecated
/// `tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!` accessor
/// — same single root node, reached without triggering
/// `deprecated_member_use`.
SemanticsNode rootSemanticsNode() {
  SemanticsOwner? owner;
  RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
    owner ??= child.semanticsOwner;
  });
  return owner!.rootSemanticsNode!;
}

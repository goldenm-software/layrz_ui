import 'package:flutter/rendering.dart';

/// Returns the root [RenderObject] of the single implicit view's render
/// tree.
///
/// Mirrors `_findRenderTreeRoot` in `find_in_page_controller.dart`: walks
/// [RendererBinding.rootPipelineOwner]'s children (one [PipelineOwner] per
/// [View]; the single-implicit-view case these tests target has exactly one)
/// and returns the first exposing a non-null [PipelineOwner.rootNode]. This
/// is the non-deprecated equivalent of the now-deprecated
/// `tester.binding.pipelineOwner.rootNode!` accessor — same single root
/// object, reached without triggering `deprecated_member_use`.
RenderObject rootRenderObject() {
  RenderObject? found;
  RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
    found ??= child.rootNode;
  });
  return found!;
}

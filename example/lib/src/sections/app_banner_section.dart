import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the app banner (debug watermark) section for the showroom.
///
/// [LayrzAppBanner] is app-level configuration read by `LayrzApp` itself, not
/// a widget a caller drops into a page, so there is no bare component to
/// render inline the way most other sections do. Instead this section nests
/// a second, independent [LayrzApp] inside a bounded box: `LayrzApp` builds on
/// [WidgetsApp], which nests like any other widget, so the nested instance
/// paints its own tiled diagonal watermark confined to that box, without
/// touching the showroom's own root `LayrzApp` or its `banner` configuration.
///
/// The watermark only ever paints in debug builds (`kDebugMode`), which is
/// exactly the build this example app runs under, so the preview below shows
/// the real painter output rather than a redrawn approximation of it.
class AppBannerSection extends StatelessWidget {
  /// Creates a new [AppBannerSection].
  const AppBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'App Banner',
      description:
          'A debug-only tiled diagonal watermark configured on LayrzApp itself, replacing '
          "the SDK's red DEBUG corner banner with a mark that survives any screen crop.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live preview -- nested LayrzApp with banner set', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            "This box embeds a second LayrzApp configured with banner: LayrzAppBanner("
            "labelText: 'STAGING'), so the tiled watermark below is the real painter, not a "
            'mock-up. It renders only because this example app is itself a debug build.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Container(
            width: 400,
            height: 300,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: tokens.radius.br2,
              border: Border.all(color: tokens.colors.divider),
            ),
            child: LayrzApp(
              theme: context.theme,
              debugShowCheckedModeBanner: false,
              banner: const LayrzAppBanner(labelText: 'STAGING'),
              home: _SamplePage(tokens: tokens),
            ),
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('How to enable it', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            "Pass a non-null banner to the app's own LayrzApp (or LayrzApp.router) "
            'constructor -- there is no separate widget to place inside a page:',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp2),
          _CodeSnippet(
            tokens: tokens,
            code:
                "LayrzApp(\n"
                "  banner: LayrzAppBanner(labelText: 'STAGING'),\n"
                '  // ...other LayrzApp parameters\n'
                ')',
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'The watermark only paints in debug builds -- release and profile builds never '
            'render it regardless of what is passed here. When banner is non-null, '
            "debugShowCheckedModeBanner is forced to false internally so the SDK's own "
            'checked-mode corner banner never stacks on top of the watermark. The optional '
            'color parameter overrides the muted default sourced from '
            'LayrzColorTokens.watermark.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}

/// The nested [LayrzApp.home] content shown behind the watermark preview --
/// stands in for a real app screen so the watermark has something to overlay.
class _SamplePage extends StatelessWidget {
  /// Creates a new [_SamplePage].
  const _SamplePage({required this.tokens});

  /// The design tokens used to style this sample page.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.colors.sf1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.applicationOutline, size: 40, color: tokens.colors.fg3),
            SizedBox(height: tokens.spacing.sp2),
            Text('Sample app content', style: tokens.typography.body.copyWith(color: tokens.colors.fg3)),
          ],
        ),
      ),
    );
  }
}

/// A minimal monospaced code block used to display the enabling snippet.
class _CodeSnippet extends StatelessWidget {
  /// Creates a new [_CodeSnippet].
  const _CodeSnippet({required this.tokens, required this.code});

  /// The design tokens used to style this code block.
  final LayrzTokens tokens;

  /// The source code text displayed inside the block.
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.sp3),
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        borderRadius: tokens.radius.br2,
        border: Border.all(color: tokens.colors.divider),
      ),
      child: Text(
        code,
        style: tokens.typography.body.copyWith(color: tokens.colors.fg2, fontFamily: 'monospace'),
      ),
    );
  }
}

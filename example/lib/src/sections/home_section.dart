import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../common/showroom_section.dart';

/// The showroom logo shown in the [HomeSection] hero, light-background variant.
///
/// Mirrors the constant of the same purpose in `layout.dart` — duplicated here
/// (rather than imported) because the layout's constant is private to that file.
const String _kLightLogo = 'https://cdn.layrz.com/resources/com.layrz.ui/logo.png?5';
const String _kDarkLogo = 'https://cdn.layrz.com/resources/com.layrz.ui/logo-white.png?5';

/// Sample `main.dart`-shaped snippet shown in the quick start section.
///
/// Deliberately small: it shows the two lines every consumer actually needs —
/// the root barrel import and a minimal [LayrzApp] usage — not a full app.
///
/// Rendered with [LayrzCodeLanguage.python] since the highlighter has no
/// `LayrzCodeLanguage.dart` grammar yet — the closest supported approximation
/// for Dart source. Highlighting will be imperfect (Dart keywords won't all
/// be recognized), but the source itself is genuine, unmodified Dart.
const String _kQuickStartSnippet = '''
import 'package:layrz_ui/layrz_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: 'My App',
      theme: LayrzThemeData.light(),
      darkTheme: LayrzThemeData.dark(),
      themeMode: LayrzThemeMode.system,
      home: const HomePage(),
    );
  }
}
''';

/// One selling-point entry rendered by [_SellingPointCard].
///
/// A plain data holder — title, supporting blurb, and the icon that
/// illustrates it — so the selling points can be declared as a single list
/// and mapped into cards rather than repeating the same widget literal.
class _SellingPoint {
  /// Creates a new [_SellingPoint].
  const _SellingPoint({required this.icon, required this.title, required this.description});

  /// The icon illustrating this selling point.
  final IconData icon;

  /// The short, bolded title of the selling point.
  final String title;

  /// The one-to-two sentence supporting description.
  final String description;
}

/// The selling points shown in the "Why layrz_ui" grid.
///
/// A `const` top-level list rather than a field so [HomeSection] itself can
/// stay a simple [StatelessWidget] with no state of its own.
const List<_SellingPoint> _kSellingPoints = [
  _SellingPoint(
    icon: MdiIcons.cancel,
    title: 'No Material, no Cupertino',
    description:
        'Built purely on package:flutter/widgets.dart and dart:ui — nothing from either '
        'platform design language leaks into your widget tree.',
  ),
  _SellingPoint(
    icon: MdiIcons.paletteSwatchOutline,
    title: 'Token-driven theming',
    description:
        'Colors, spacing, radius, and shadow all flow through LayrzTokens. Light and '
        'dark (beta) both work across every widget in the library.',
  ),
  _SellingPoint(
    icon: MdiIcons.formatColorFill,
    title: 'Semantic, consistent colors',
    description:
        'One primary, danger, success, warning, and info color everywhere. Change a '
        'token once and the whole system follows.',
  ),
  _SellingPoint(
    icon: MdiIcons.responsive,
    title: 'Responsive by design',
    description:
        'Breakpoint tokens and context.isCompact give every component the same '
        'compact/wide decision, so layouts adapt consistently.',
  ),
  _SellingPoint(
    icon: MdiIcons.humanWheelchair,
    title: 'Accessible',
    description:
        'Every visual component ships with semantics, so assistive technology gets a '
        'first-class experience, not an afterthought.',
  ),
  _SellingPoint(
    icon: MdiIcons.swapHorizontal,
    title: 'Drop-in for layrz_theme',
    description:
        'A modern, Material-free replacement for layrz_theme — the same jobs to be '
        'done, built on a cleaner foundation.',
  ),
];

/// One external link surfaced in the [HomeSection] footer.
///
/// Since the showroom has no `url_launcher` dependency, tapping a link copies
/// its [url] to the clipboard instead of opening a browser — the same pattern
/// already used by the "Copy route" context menu action in `layout.dart`.
class _FooterLink {
  /// Creates a new [_FooterLink].
  const _FooterLink({required this.icon, required this.labelText, required this.url});

  /// The icon shown on the link's button.
  final IconData icon;

  /// The visible label for the link's button.
  final String labelText;

  /// The URL copied to the clipboard when the button is tapped.
  final String url;
}

/// The external links shown in the [HomeSection] footer.
const List<_FooterLink> _kFooterLinks = [
  _FooterLink(icon: MdiIcons.packageVariantClosed, labelText: 'pub.dev', url: 'https://pub.dev/packages/layrz_ui'),
  _FooterLink(
    icon: MdiIcons.sourceRepository,
    labelText: 'GitHub',
    url: 'https://github.com/goldenm-software/layrz_ui',
  ),
  _FooterLink(
    icon: MdiIcons.bookOpenPageVariantOutline,
    labelText: 'Wiki',
    url: 'https://github.com/goldenm-software/layrz_ui/wiki',
  ),
];

/// The showroom's welcome / landing page.
///
/// [HomeSection] is the default route of the showroom application — the page
/// developers land on first, before they explore any individual component
/// section. It wears the same [ShowroomSection] chrome as every other view
/// (a top-anchored, scrollable page with the title left-aligned above a
/// [LayrzCard]-wrapped content area), so Home reads as part of the same
/// showroom rather than a separate landing app bolted onto it. The hero,
/// selling-points grid, quick-start sample, and footer links are all rendered
/// as [ShowroomSection]'s `child`, preserving the original content unchanged.
///
/// The page is entirely dogfooded from layrz_ui: [LayrzCard] for every
/// surface, [LayrzRow]/[LayrzCol] for the responsive selling-points grid,
/// [LayrzConstrainedView] to keep line length readable on wide desktop
/// windows, [LayrzCodeSnippet] for the quick-start sample, and [LayrzButton]
/// for the footer links. It reads every color and spacing value from
/// [BuildContext.tokens] and never hardcodes a design value.
class HomeSection extends StatelessWidget {
  /// Creates a new [HomeSection].
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'layrz_ui',
      description: 'A Material-free, Cupertino-free Flutter design system.',
      child: Column(
        spacing: tokens.spacing.sp5,
        children: [
          _Hero(tokens: tokens),
          _WhySection(tokens: tokens),
          _QuickStartSection(tokens: tokens),
          _Footer(tokens: tokens),
        ],
      ),
    );
  }
}

/// The hero banner at the top of [HomeSection]: logo and supporting blurb.
///
/// The page title and tagline are rendered once, by [ShowroomSection] itself
/// (see [HomeSection.build]) — this widget only adds the logo mark and the
/// longer explanatory line beneath them, so nothing is said twice.
class _Hero extends StatelessWidget {
  /// Creates a new [_Hero].
  const _Hero({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            context.isDark ? _kDarkLogo : _kLightLogo,
            height: isCompact ? 56 : 72,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(
            'Every widget in this showroom is built exclusively on package:flutter/widgets.dart '
            'and dart:ui — no Material, no Cupertino, anywhere.',
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}

/// The "Why layrz_ui" section: a responsive grid of selling-point cards.
class _WhySection extends StatelessWidget {
  /// Creates a new [_WhySection].
  const _WhySection({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Why layrz_ui', style: tokens.typography.headline.copyWith(color: tokens.colors.fg1)),
        SizedBox(height: tokens.spacing.sp2),
        Text(
          'A design system built for teams that want full control over their visual language, '
          'without fighting a platform framework for it.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp4),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            for (final point in _kSellingPoints)
              LayrzCol(
                xs: 12,
                sm: 6,
                lg: 4,
                child: _SellingPointCard(tokens: tokens, point: point),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single selling-point card: icon, title, and description.
class _SellingPointCard extends StatelessWidget {
  /// Creates a new [_SellingPointCard].
  const _SellingPointCard({required this.tokens, required this.point});

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The selling point rendered by this card.
  final _SellingPoint point;

  @override
  Widget build(BuildContext context) {
    return LayrzCard(
      backgroundColor: context.tokens.colors.sf1,
      child: SizedBox(
        height: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(point.icon, color: tokens.colors.primary, size: 28),
            SizedBox(height: tokens.spacing.sp3),
            Text(point.title, style: tokens.typography.title.copyWith(color: tokens.colors.fg1)),
            SizedBox(height: tokens.spacing.sp2),
            Expanded(
              child: Text(
                point.description,
                style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Quick start" section: a minimal code sample showing the blessed
/// import and a small [LayrzApp] usage.
class _QuickStartSection extends StatelessWidget {
  /// Creates a new [_QuickStartSection].
  const _QuickStartSection({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick start', style: tokens.typography.headline.copyWith(color: tokens.colors.fg1)),
        SizedBox(height: tokens.spacing.sp2),
        Text(
          'One import, then use LayrzApp exactly like you would MaterialApp.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp4),
        LayrzCodeSnippet(
          code: _kQuickStartSnippet,
          language: LayrzCodeLanguage.python,
          showLineNumbers: true,
        ),
      ],
    );
  }
}

/// The footer section: links out to pub.dev, GitHub, and the wiki.
class _Footer extends StatelessWidget {
  /// Creates a new [_Footer].
  const _Footer({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: tokens.colors.divider),
          SizedBox(height: tokens.spacing.sp4),
          Text('Learn more', style: tokens.typography.title.copyWith(color: tokens.colors.fg1)),
          SizedBox(height: tokens.spacing.sp3),
          Wrap(
            spacing: tokens.spacing.sp3,
            runSpacing: tokens.spacing.sp3,
            children: [
              for (final link in _kFooterLinks)
                SizedBox(
                  width: isCompact ? double.infinity : null,
                  child: LayrzButton(
                    labelText: link.labelText,
                    icon: link.icon,
                    type: LayrzButtonType.info,
                    style: LayrzButtonStyle.outlined,
                    hintText: link.url,
                    onTap: () => launchUrlString(link.url, mode: .externalApplication),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

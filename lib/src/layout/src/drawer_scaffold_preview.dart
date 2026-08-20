import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/preview/preview.dart';

import 'drawer_scaffold.dart';

/// Preview of [LayrzLayoutDrawerScaffold] with drawer open.
///
/// Demonstrates the drawer scaffold animation and layout with the drawer
/// expanded to full width, revealing the scaled and translated page layer.
@Preview(
  name: 'Open',
  size: Size(800, 600),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzLayoutDrawerScaffoldOpen() {
  return _DrawerScaffoldPreview(initiallyOpen: true);
}

/// Preview of [LayrzLayoutDrawerScaffold] with drawer closed.
///
/// Demonstrates the drawer scaffold at rest with the page layer at full scale
/// and the drawer hidden off-screen.
@Preview(
  name: 'Closed',
  size: Size(800, 600),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzLayoutDrawerScaffoldClosed() {
  return _DrawerScaffoldPreview(initiallyOpen: false);
}

/// Helper widget for drawer scaffold preview that manages animation state.
class _DrawerScaffoldPreview extends StatefulWidget {
  /// Whether to start with the drawer open.
  final bool initiallyOpen;

  /// Creates a drawer scaffold preview.
  const _DrawerScaffoldPreview({required this.initiallyOpen});

  @override
  State<_DrawerScaffoldPreview> createState() => _DrawerScaffoldPreviewState();
}

class _DrawerScaffoldPreviewState extends State<_DrawerScaffoldPreview> {
  @override
  Widget build(BuildContext context) {
    return LayrzLayoutDrawerScaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      topBarBuilder: (openDrawer) => Container(
        height: 56,
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: openDrawer,
                child: Icon(
                  MdiIcons.menu,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'App Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Main Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Drawer width: ${kLayrzLayoutDrawerWidth}px',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Placeholder\nContent',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawerBuilder: (closeDrawer) => Container(
        color: const Color(0xFFFFFFFF),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Drawer Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap: closeDrawer,
                      child: Text(
                        'Menu Item ${index + 1}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

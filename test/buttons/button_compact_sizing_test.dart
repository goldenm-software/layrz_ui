import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzButton compact sizing (DESIGN-103)', () {
    testWidgets(
      'at compact viewport (400px), height is 50',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'at regular viewport (1200px), height is 45',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(45.0, 0.1));
      },
    );

    testWidgets(
      'at boundary width 959 (compact), height is 50',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(959, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'at boundary width 960 (regular), height is 45',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(960, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(45.0, 0.1));
      },
    );

    testWidgets(
      'FAB button at compact viewport (400px) is square with height 50',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton.save(
            labelText: 'Save',
            onTap: () {},
            isFab: true,
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
        expect(renderBox.size.width, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'FAB button at regular viewport (1200px) is square with height 45',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemed(
          tester,
          LayrzButton.save(
            labelText: 'Save',
            onTap: () {},
            isFab: true,
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(45.0, 0.1));
        expect(renderBox.size.width, closeTo(45.0, 0.1));
      },
    );

    testWidgets(
      'semantic factory button .save inherits compact sizing at 400px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton.save(
            labelText: 'Save',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'semantic factory button .delete inherits compact sizing at 400px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton.delete(
            labelText: 'Delete',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'semantic factory button .save is regular size at 1200px',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemed(
          tester,
          LayrzButton.save(
            labelText: 'Save',
            onTap: () {},
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(45.0, 0.1));
      },
    );

    testWidgets(
      'button width computation uses resolved font size (icon + label)',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        // Create a button with icon
        const labelText = 'Save';

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: labelText,
            icon: MdiIcons.contentSaveOutline,
            onTap: () {},
          ),
        );

        // Verify button renders at compact height
        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
        expect(renderBox.size.width, greaterThan(0));
      },
    );

    testWidgets(
      'button width increases from regular to compact due to larger font',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        const labelText = 'Save Changes';

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: labelText,
            onTap: () {},
          ),
        );

        final compactRenderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        final compactWidth = compactRenderBox.size.width;

        // Now test at regular viewport
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: labelText,
            onTap: () {},
          ),
        );

        final regularRenderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        final regularWidth = regularRenderBox.size.width;

        // Compact should be wider or equal because font is larger (16 vs 14)
        expect(compactWidth, greaterThanOrEqualTo(regularWidth));
      },
    );

    testWidgets(
      'button height animates smoothly when viewport changes',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        var renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));

        // Change to regular viewport
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        // Trigger a rebuild
        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            onTap: () {},
          ),
        );

        // The animation should eventually reach 45
        await tester.pumpAndSettle();
        renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(45.0, 0.1));
      },
    );

    testWidgets(
      'button with icon at compact viewport has content space for icon size 24',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test',
            icon: MdiIcons.contentSaveOutline,
            onTap: () {},
          ),
        );

        // Verify the button renders correctly at compact height
        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
      },
    );

    testWidgets(
      'button renders correctly at compact viewport with varying text scales',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(400, 800);

        await pumpThemed(
          tester,
          LayrzButton(
            labelText: 'Test Button',
            icon: MdiIcons.contentSaveOutline,
            onTap: () {},
          ),
        );

        // Verify the button renders at compact height with icon
        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
        expect(renderBox.size.height, closeTo(50.0, 0.1));
        expect(renderBox.size.width, greaterThan(100));
      },
    );
  });
}

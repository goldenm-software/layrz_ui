import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("resolveFoldSplit", () {
    test("a vertical seam (Fold, portrait) splits left/right", () {
      // Shell fills the whole view (no rail inset): 904 wide, 1000 tall
      // (>= kLayrzFoldMinSplitHeight), seam at x 450, no thickness.
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(450, 0, 450, 1000),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      final split = resolveFoldSplit(features: features, shellRect: shellRect);

      expect(split, isNotNull);
      expect(split!.axis, LayrzFoldAxis.vertical);
      expect(split.leadingExtent, closeTo(450, 0.01));
      expect(split.trailingExtent, closeTo(454, 0.01));
      expect(split.gap, 0);
    });

    test("a horizontal seam (Flip, portrait) never splits -- rejected by design, not by geometry", () {
      // Tall enough to clear kLayrzFoldMinSplitHeight on its own -- the only
      // reason this must return null is the axis filter itself.
      const shellRect = Rect.fromLTWH(0, 0, 411.43, 905.9);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(0, 403.0, 411.43, 403.0),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("a cutout-only feature list returns null", () {
      // Measured Flip 3 camera cutout: LTRB(192, 0, 219, 36).
      const shellRect = Rect.fromLTWH(0, 0, 411.43, 1005.71);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(192, 0, 219, 36),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("a cutout alongside a genuine vertical fold ignores the cutout and splits on the fold", () {
      // Rotated to a vertical seam (unlike the portrait Flip case above) so
      // this exercises "cutout skipped, real seam used" independently of the
      // horizontal-axis rejection.
      const shellRect = Rect.fromLTWH(0, 0, 1005.71, 600);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(192, 0, 219, 36),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
        const DisplayFeature(
          bounds: Rect.fromLTRB(502.857, 0, 502.857, 600),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      final split = resolveFoldSplit(features: features, shellRect: shellRect);

      expect(split, isNotNull);
      expect(split!.axis, LayrzFoldAxis.vertical);
      expect(split.leadingExtent, closeTo(502.857, 0.01));
    });

    test("a cutout alongside a horizontal fold still returns null (both are rejected)", () {
      const shellRect = Rect.fromLTWH(0, 0, 411.43, 1005.71);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(192, 0, 219, 36),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
        const DisplayFeature(
          bounds: Rect.fromLTRB(0, 502.857, 411.43, 502.857),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("postureHalfOpened is accepted (Pixel 10 Pro Fold boots half-opened with a flat-identical viewport)", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(450, 0, 450, 1000),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];

      final split = resolveFoldSplit(features: features, shellRect: shellRect);

      expect(split, isNotNull);
      expect(split!.axis, LayrzFoldAxis.vertical);
      expect(split.leadingExtent, closeTo(450, 0.01));
    });

    test("postureFlat is accepted", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(450, 0, 450, 1000),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNotNull);
    });

    test("unknown posture is accepted (treated as usable)", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(450, 0, 450, 1000),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.unknown,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNotNull);
    });

    test("a seam that does not span the shell's full cross axis returns null", () {
      // Seam only reaches 3/4 of the shell's height -- clips a corner, not a genuine split.
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(450, 0, 450, 750),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("a seam sitting exactly on the shell's edge (not strictly inside) returns null", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(0, 0, 0, 1000),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("a seam leaving a pane under minPaneExtent returns null", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(50, 0, 50, 1000), // leading pane would be 50, under default 120 minimum
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
    });

    test("a custom minPaneExtent is honored", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(50, 0, 50, 1000),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      expect(
        resolveFoldSplit(features: features, shellRect: shellRect, minPaneExtent: 30),
        isNotNull,
      );
    });

    test(
      "seam offset by a rail inset maps correctly (measured Flip 3 landscape geometry, raised to clear minSplitHeight)",
      () {
        // Real measurement: shell inset by a 220dp rail, seam at view-x 502.9,
        // width 785.7. The real landscape-Flip shell is only 411.4dp tall --
        // under kLayrzFoldMinSplitHeight -- so this fixture is deliberately
        // raised to 731.9dp of height to isolate what it exists to test: the
        // x-axis mapping through the rail offset. Naive "shell's own midpoint"
        // would be 392.9 -- wrong by 110dp. The correct mapped leadingExtent
        // is 502.9 - 220 = 282.9.
        const shellRect = Rect.fromLTWH(220, 0, 785.7, 731.9);
        final features = [
          const DisplayFeature(
            bounds: Rect.fromLTRB(502.9, 0, 502.9, 731.9),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ];

        final split = resolveFoldSplit(features: features, shellRect: shellRect);

        expect(split, isNotNull);
        expect(split!.axis, LayrzFoldAxis.vertical);
        expect(split.leadingExtent, closeTo(282.9, 0.01));
        expect(split.leadingExtent, isNot(closeTo(392.9, 0.01)));
        expect(split.trailingExtent, closeTo(502.8, 0.01));
      },
    );

    test("a hinge with real thickness yields a nonzero gap", () {
      const shellRect = Rect.fromLTWH(0, 0, 1800, 1200);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(880, 0, 920, 1200),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      final split = resolveFoldSplit(features: features, shellRect: shellRect);

      expect(split, isNotNull);
      expect(split!.gap, closeTo(40, 0.01));
      expect(split.leadingExtent, closeTo(880, 0.01));
      expect(split.trailingExtent, closeTo(880, 0.01));
    });

    test("a zero-thickness vertical seam yields gap == 0 without dividing by zero", () {
      const shellRect = Rect.fromLTWH(0, 0, 1005.71, 600);
      final features = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(502.857, 0, 502.857, 600),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      final split = resolveFoldSplit(features: features, shellRect: shellRect);

      expect(split, isNotNull);
      expect(split!.gap, 0);
      expect(split.gap.isNaN, isFalse);
      expect(split.gap.isInfinite, isFalse);
    });

    test("an empty feature list returns null", () {
      const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
      expect(resolveFoldSplit(features: const [], shellRect: shellRect), isNull);
    });

    test(
      "when multiple qualifying seams exist, the one closest to kLayrzFoldPreferredListFraction wins "
      "(here it happens to also be the first one)",
      () {
        const shellRect = Rect.fromLTWH(0, 0, 904, 1000);
        // Target = 904/3 = 301.33. The x=300 seam (distance 1.33) is far
        // closer than the x=600 seam (distance 298.67).
        final features = [
          const DisplayFeature(
            bounds: Rect.fromLTRB(300, 0, 300, 1000),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
          const DisplayFeature(
            bounds: Rect.fromLTRB(600, 0, 600, 1000),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ];

        final split = resolveFoldSplit(features: features, shellRect: shellRect);

        expect(split, isNotNull);
        expect(split!.leadingExtent, closeTo(300, 0.01));
      },
    );

    group("multi-seam selection (Galaxy Z TriFold)", () {
      // Real-scale tri-fold fixture: inner screen ~822.9 x 603.4 logical,
      // two zero-thickness vertical seams splitting it into three ~274.3dp
      // panels (creases at x ~= 274.3 and x ~= 548.6).
      const triFoldShellHeight = 603.4;
      const triFoldShellRect = Rect.fromLTWH(0, 0, 822.9, triFoldShellHeight);
      const firstCreaseX = 274.3;
      const secondCreaseX = 548.6;

      DisplayFeature verticalSeamAt(double x, {double height = triFoldShellHeight}) => DisplayFeature(
        bounds: Rect.fromLTRB(x, 0, x, height),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      );

      test(
        "two vertical seams on a tri-fold-scale shell: the FIRST crease is chosen (closest to 1/3), not the second",
        () {
          final features = [
            verticalSeamAt(firstCreaseX),
            verticalSeamAt(secondCreaseX),
          ];

          final split = resolveFoldSplit(features: features, shellRect: triFoldShellRect);

          expect(split, isNotNull);
          expect(split!.leadingExtent, closeTo(firstCreaseX, 0.5));
          expect(split.leadingExtent, isNot(closeTo(secondCreaseX, 0.5)));
        },
      );

      test(
        "REGRESSION: the same two seams in REVERSED list order still yield the first crease -- "
        "this is what actually distinguishes selection from a firstWhere/first-match implementation",
        () {
          final features = [
            verticalSeamAt(secondCreaseX),
            verticalSeamAt(firstCreaseX),
          ];

          final split = resolveFoldSplit(features: features, shellRect: triFoldShellRect);

          expect(split, isNotNull);
          expect(split!.leadingExtent, closeTo(firstCreaseX, 0.5));
          expect(split.leadingExtent, isNot(closeTo(secondCreaseX, 0.5)));
        },
      );

      test("a tie between two equidistant seams is broken toward the leading-most candidate, deterministically", () {
        // Target = 900/3 = 300. Seams at x=250 (distance 50) and x=350
        // (distance 50) are exactly equidistant; the leading-most (250) must
        // win, and must win regardless of list order.
        const shellRect = Rect.fromLTWH(0, 0, 900, 600);

        final forwardOrder = [
          verticalSeamAt(250, height: 600),
          verticalSeamAt(350, height: 600),
        ];
        final reverseOrder = forwardOrder.reversed.toList();

        final forwardSplit = resolveFoldSplit(features: forwardOrder, shellRect: shellRect);
        final reverseSplit = resolveFoldSplit(features: reverseOrder, shellRect: shellRect);

        expect(forwardSplit, isNotNull);
        expect(forwardSplit!.leadingExtent, closeTo(250, 0.01));
        expect(reverseSplit, isNotNull);
        expect(reverseSplit!.leadingExtent, closeTo(250, 0.01));
      });

      test("a horizontal seam among the candidates is never selected -- only the vertical one is eligible", () {
        const shellRect = Rect.fromLTWH(0, 0, 900, 600);
        final features = [
          // Horizontal seam: would (if eligible) sit much closer to a
          // meaningless "target" computed against width, but it must never
          // be considered at all -- the axis gate excludes it before
          // selection even runs.
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 300, 900, 300),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
          const DisplayFeature(
            bounds: Rect.fromLTRB(600, 0, 600, 600),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ];

        final split = resolveFoldSplit(features: features, shellRect: shellRect);

        expect(split, isNotNull);
        expect(split!.axis, LayrzFoldAxis.vertical);
        expect(split.leadingExtent, closeTo(600, 0.01));
      });

      test(
        "when the better-proportioned seam fails minPaneExtent, the other qualifying seam is chosen "
        "instead of the whole thing returning null",
        () {
          const shellRect = Rect.fromLTWH(0, 0, 900, 600);
          // Target = 300. The x=50 seam is nearer the target's neighborhood
          // in absolute terms than a naive glance might suggest, but its
          // leadingExtent (50) is under the default 120 minPaneExtent, so it
          // is disqualified outright before selection ever compares
          // distances -- only the x=600 seam remains eligible.
          final features = [
            const DisplayFeature(
              bounds: Rect.fromLTRB(50, 0, 50, 600), // leadingExtent 50 < 120 minPaneExtent -> disqualified
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureFlat,
            ),
            const DisplayFeature(
              bounds: Rect.fromLTRB(600, 0, 600, 600), // leadingExtent 600, qualifies
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureFlat,
            ),
          ];

          final split = resolveFoldSplit(features: features, shellRect: shellRect);

          expect(split, isNotNull);
          expect(split!.leadingExtent, closeTo(600, 0.01));
        },
      );
    });

    group("minSplitHeight guard (kLayrzFoldMinSplitHeight)", () {
      // A vertical seam that would otherwise qualify comfortably (wide panes,
      // well inside the shell) at every height tested below -- isolates the
      // height guard from every other rule.
      List<DisplayFeature> verticalSeamAt(double shellWidth, double shellHeight) => [
        DisplayFeature(
          bounds: Rect.fromLTRB(shellWidth / 2, 0, shellWidth / 2, shellHeight),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];

      test("Fold portrait, keyboard down (852.0 x 731.9): splits", () {
        const shellRect = Rect.fromLTWH(0, 0, 852.0, 731.9);
        final split = resolveFoldSplit(
          features: verticalSeamAt(852.0, 731.9),
          shellRect: shellRect,
        );
        expect(split, isNotNull);
        expect(split!.axis, LayrzFoldAxis.vertical);
      });

      test("Fold portrait, keyboard UP (852.0 x 435.0): no split (height)", () {
        const shellRect = Rect.fromLTWH(0, 0, 852.0, 435.0);
        final split = resolveFoldSplit(
          features: verticalSeamAt(852.0, 435.0),
          shellRect: shellRect,
        );
        expect(split, isNull);
      });

      test("Flip landscape, keyboard down (785.7 x 411.4): no split (height)", () {
        const shellRect = Rect.fromLTWH(0, 0, 785.7, 411.4);
        final split = resolveFoldSplit(
          features: verticalSeamAt(785.7, 411.4),
          shellRect: shellRect,
        );
        expect(split, isNull);
      });

      test("Flip landscape, keyboard UP (785.7 x 83.4): no split (height)", () {
        const shellRect = Rect.fromLTWH(0, 0, 785.7, 83.4);
        final split = resolveFoldSplit(
          features: verticalSeamAt(785.7, 83.4),
          shellRect: shellRect,
        );
        expect(split, isNull);
      });

      test("boundary: 479.9 tall does not split", () {
        const shellRect = Rect.fromLTWH(0, 0, 900, 479.9);
        final split = resolveFoldSplit(
          features: verticalSeamAt(900, 479.9),
          shellRect: shellRect,
        );
        expect(split, isNull);
      });

      test("boundary: exactly 480.0 tall (kLayrzFoldMinSplitHeight) does split -- inclusive threshold", () {
        const shellRect = Rect.fromLTWH(0, 0, 900, 480.0);
        final split = resolveFoldSplit(
          features: verticalSeamAt(900, 480.0),
          shellRect: shellRect,
        );
        expect(split, isNotNull);
      });

      test("a custom minSplitHeight is honored", () {
        const shellRect = Rect.fromLTWH(0, 0, 900, 300);
        final split = resolveFoldSplit(
          features: verticalSeamAt(900, 300),
          shellRect: shellRect,
          minSplitHeight: 250,
        );
        expect(split, isNotNull);
      });

      test("a horizontal seam still returns null even on a tall-enough shell (axis rejection, not height)", () {
        // Guards against the height guard accidentally masking the axis
        // rejection in a way that would make the axis-only test above
        // insufficient once combined with the height guard.
        const shellRect = Rect.fromLTWH(0, 0, 411.43, 905.9);
        final features = [
          const DisplayFeature(
            bounds: Rect.fromLTRB(0, 403.0, 411.43, 403.0),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ];
        expect(shellRect.height, greaterThanOrEqualTo(kLayrzFoldMinSplitHeight));
        expect(resolveFoldSplit(features: features, shellRect: shellRect), isNull);
      });
    });
  });

  group("kLayrzFoldMinSplitHeight", () {
    test("is 480.0", () {
      expect(kLayrzFoldMinSplitHeight, 480.0);
    });
  });

  group("LayrzFoldSplit", () {
    test("== and hashCode compare by value", () {
      const a = LayrzFoldSplit(
        axis: LayrzFoldAxis.vertical,
        leadingExtent: 282.9,
        trailingExtent: 502.8,
        gap: 0,
      );
      const b = LayrzFoldSplit(
        axis: LayrzFoldAxis.vertical,
        leadingExtent: 282.9,
        trailingExtent: 502.8,
        gap: 0,
      );
      const c = LayrzFoldSplit(
        axis: LayrzFoldAxis.horizontal,
        leadingExtent: 282.9,
        trailingExtent: 502.8,
        gap: 0,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(Object())));
      expect(a, equals(a));
    });

    test("copyWith replaces only the given fields", () {
      const original = LayrzFoldSplit(
        axis: LayrzFoldAxis.vertical,
        leadingExtent: 282.9,
        trailingExtent: 502.8,
        gap: 0,
      );

      final copy = original.copyWith(gap: 40);

      expect(copy.axis, LayrzFoldAxis.vertical);
      expect(copy.leadingExtent, 282.9);
      expect(copy.trailingExtent, 502.8);
      expect(copy.gap, 40);

      final untouched = original.copyWith();
      expect(untouched, equals(original));
    });

    test("toString includes the resolved fields", () {
      const split = LayrzFoldSplit(
        axis: LayrzFoldAxis.horizontal,
        leadingExtent: 403.0,
        trailingExtent: 502.9,
        gap: 0,
      );

      expect(split.toString(), contains('horizontal'));
      expect(split.toString(), contains('403.0'));
    });
  });
}

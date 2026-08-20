import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSpacingTokens', () {
    test('default constructor uses correct values', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.sp1, equals(4.0));
      expect(tokens.sp2, equals(8.0));
      expect(tokens.sp3, equals(16.0));
      expect(tokens.sp4, equals(24.0));
      expect(tokens.sp5, equals(32.0));
    });

    test('padding getters return EdgeInsets.all with correct values', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.pd1, equals(EdgeInsets.all(4.0)));
      expect(tokens.pd2, equals(EdgeInsets.all(8.0)));
      expect(tokens.pd3, equals(EdgeInsets.all(16.0)));
      expect(tokens.pd4, equals(EdgeInsets.all(24.0)));
      expect(tokens.pd5, equals(EdgeInsets.all(32.0)));
    });

    test('margin getters return EdgeInsets.all with correct values', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.mg1, equals(EdgeInsets.all(4.0)));
      expect(tokens.mg2, equals(EdgeInsets.all(8.0)));
      expect(tokens.mg3, equals(EdgeInsets.all(16.0)));
      expect(tokens.mg4, equals(EdgeInsets.all(24.0)));
      expect(tokens.mg5, equals(EdgeInsets.all(32.0)));
    });

    test('padding and margin values are identical', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.pd1, equals(tokens.mg1));
      expect(tokens.pd2, equals(tokens.mg2));
      expect(tokens.pd3, equals(tokens.mg3));
      expect(tokens.pd4, equals(tokens.mg4));
      expect(tokens.pd5, equals(tokens.mg5));
    });

    test('copyWith creates new instance with replaced fields', () {
      const original = LayrzSpacingTokens();
      final modified = original.copyWith(sp1: 5.0, sp4: 25.0);

      expect(modified.sp1, equals(5.0));
      expect(modified.sp4, equals(25.0));
      expect(modified.sp2, equals(original.sp2));
      expect(modified.sp3, equals(original.sp3));
      expect(modified.sp5, equals(original.sp5));
      expect(original.sp1, equals(4.0)); // original unchanged
    });

    test('copyWith with no arguments returns equal instance', () {
      const original = LayrzSpacingTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzSpacingTokens();
      const tokens2 = LayrzSpacingTokens();
      expect(tokens1, equals(tokens2));
    });

    test('inequality works for different values', () {
      const tokens1 = LayrzSpacingTokens();
      final tokens2 = LayrzSpacingTokens(sp1: 5.0);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzSpacingTokens();
      const tokens2 = LayrzSpacingTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      const tokens1 = LayrzSpacingTokens();
      final tokens2 = LayrzSpacingTokens(sp1: 5.0);
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('custom spacing values propagate correctly', () {
      final tokens = LayrzSpacingTokens(
        sp1: 5.0,
        sp2: 10.0,
        sp3: 20.0,
        sp4: 30.0,
        sp5: 40.0,
      );

      expect(tokens.pd1, equals(EdgeInsets.all(5.0)));
      expect(tokens.pd2, equals(EdgeInsets.all(10.0)));
      expect(tokens.pd3, equals(EdgeInsets.all(20.0)));
      expect(tokens.pd4, equals(EdgeInsets.all(30.0)));
      expect(tokens.pd5, equals(EdgeInsets.all(40.0)));

      expect(tokens.mg1, equals(EdgeInsets.all(5.0)));
      expect(tokens.mg2, equals(EdgeInsets.all(10.0)));
      expect(tokens.mg3, equals(EdgeInsets.all(20.0)));
      expect(tokens.mg4, equals(EdgeInsets.all(30.0)));
      expect(tokens.mg5, equals(EdgeInsets.all(40.0)));
    });

    test('square sized-box getters return SizedBox with correct dimensions', () {
      const tokens = LayrzSpacingTokens();

      final sb1 = tokens.sb1 as SizedBox;
      final sb2 = tokens.sb2 as SizedBox;
      final sb3 = tokens.sb3 as SizedBox;
      final sb4 = tokens.sb4 as SizedBox;
      final sb5 = tokens.sb5 as SizedBox;

      expect(sb1.width, equals(4.0));
      expect(sb1.height, equals(4.0));

      expect(sb2.width, equals(8.0));
      expect(sb2.height, equals(8.0));

      expect(sb3.width, equals(16.0));
      expect(sb3.height, equals(16.0));

      expect(sb4.width, equals(24.0));
      expect(sb4.height, equals(24.0));

      expect(sb5.width, equals(32.0));
      expect(sb5.height, equals(32.0));
    });

    test('horizontal sized-box getters constrain width only', () {
      const tokens = LayrzSpacingTokens();

      final sb1h = tokens.sb1h as SizedBox;
      final sb2h = tokens.sb2h as SizedBox;
      final sb3h = tokens.sb3h as SizedBox;
      final sb4h = tokens.sb4h as SizedBox;
      final sb5h = tokens.sb5h as SizedBox;

      expect(sb1h.width, equals(4.0));
      expect(sb1h.height, isNull);

      expect(sb2h.width, equals(8.0));
      expect(sb2h.height, isNull);

      expect(sb3h.width, equals(16.0));
      expect(sb3h.height, isNull);

      expect(sb4h.width, equals(24.0));
      expect(sb4h.height, isNull);

      expect(sb5h.width, equals(32.0));
      expect(sb5h.height, isNull);
    });

    test('vertical sized-box getters constrain height only', () {
      const tokens = LayrzSpacingTokens();

      final sb1v = tokens.sb1v as SizedBox;
      final sb2v = tokens.sb2v as SizedBox;
      final sb3v = tokens.sb3v as SizedBox;
      final sb4v = tokens.sb4v as SizedBox;
      final sb5v = tokens.sb5v as SizedBox;

      expect(sb1v.width, isNull);
      expect(sb1v.height, equals(4.0));

      expect(sb2v.width, isNull);
      expect(sb2v.height, equals(8.0));

      expect(sb3v.width, isNull);
      expect(sb3v.height, equals(16.0));

      expect(sb4v.width, isNull);
      expect(sb4v.height, equals(24.0));

      expect(sb5v.width, isNull);
      expect(sb5v.height, equals(32.0));
    });

    test('sized-box getters derive from spacing fields via copyWith', () {
      const original = LayrzSpacingTokens();
      final modified = original.copyWith(sp3: 99.0);

      final originalSb3 = original.sb3 as SizedBox;
      final modifiedSb3 = modified.sb3 as SizedBox;

      expect(originalSb3.width, equals(16.0));
      expect(originalSb3.height, equals(16.0));

      expect(modifiedSb3.width, equals(99.0));
      expect(modifiedSb3.height, equals(99.0));

      final originalSb3h = original.sb3h as SizedBox;
      final modifiedSb3h = modified.sb3h as SizedBox;

      expect(originalSb3h.width, equals(16.0));
      expect(modifiedSb3h.width, equals(99.0));

      final originalSb3v = original.sb3v as SizedBox;
      final modifiedSb3v = modified.sb3v as SizedBox;

      expect(originalSb3v.height, equals(16.0));
      expect(modifiedSb3v.height, equals(99.0));
    });

    test('sized-box getters are absent from equality semantics', () {
      const tokens1 = LayrzSpacingTokens();
      const tokens2 = LayrzSpacingTokens();

      // Instances are equal despite being different objects
      expect(tokens1, equals(tokens2));

      // Verify they have identical spN fields
      expect(tokens1.sp1, equals(tokens2.sp1));
      expect(tokens1.sp2, equals(tokens2.sp2));
      expect(tokens1.sp3, equals(tokens2.sp3));
      expect(tokens1.sp4, equals(tokens2.sp4));
      expect(tokens1.sp5, equals(tokens2.sp5));

      // Getters should produce identical sized-boxes for identical tokens
      final sb1a = tokens1.sb1 as SizedBox;
      final sb1b = tokens2.sb1 as SizedBox;
      expect(sb1a.width, equals(sb1b.width));
      expect(sb1a.height, equals(sb1b.height));

      final sb1ha = tokens1.sb1h as SizedBox;
      final sb1hb = tokens2.sb1h as SizedBox;
      expect(sb1ha.width, equals(sb1hb.width));
      expect(sb1ha.height, equals(sb1hb.height));

      final sb1va = tokens1.sb1v as SizedBox;
      final sb1vb = tokens2.sb1v as SizedBox;
      expect(sb1va.width, equals(sb1vb.width));
      expect(sb1va.height, equals(sb1vb.height));
    });
  });
}

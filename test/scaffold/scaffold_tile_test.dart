import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

// Custom subclass with identity equality (no override)
final class _IdentityTile extends LayrzScaffoldTile {
  final String id;

  const _IdentityTile(this.id) : super();

  @override
  InlineSpan get titleRichText => TextSpan(text: id);

  @override
  InlineSpan? get subtitleRichText => null;

  @override
  List<LayrzDropdownItem> get actions => const [];
}

// Custom subclass with value equality
final class _IdBasedTile extends LayrzScaffoldTile {
  final String id;
  final String title;

  const _IdBasedTile({
    required this.id,
    required this.title,
  }) : super();

  @override
  InlineSpan get titleRichText => TextSpan(text: title);

  @override
  InlineSpan? get subtitleRichText => null;

  @override
  List<LayrzDropdownItem> get actions => const [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _IdBasedTile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('LayrzScaffoldValueTile', () {
    test('equality works correctly', () {
      const tile1 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
        subtitleRichText: TextSpan(text: 'Subtitle'),
      );
      const tile2 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
        subtitleRichText: TextSpan(text: 'Subtitle'),
      );
      expect(tile1, equals(tile2));
    });

    test('inequality works correctly', () {
      const tile1 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title 1'),
      );
      const tile2 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title 2'),
      );
      expect(tile1, isNot(equals(tile2)));
    });

    test('hashCode is consistent', () {
      const tile = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
      );
      expect(tile.hashCode, tile.hashCode);
    });

    test('copyWith replaces fields correctly', () {
      const tile1 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
        subtitleRichText: TextSpan(text: 'Subtitle'),
      );
      final tile2 = tile1.copyWith(
        subtitleRichText: TextSpan(text: 'New Subtitle'),
      );
      expect(tile2.titleRichText, tile1.titleRichText);
      expect(tile2.subtitleRichText, TextSpan(text: 'New Subtitle'));
    });

    test('default values are applied', () {
      const tile = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
      );
      expect(tile.subtitleRichText, isNull);
      expect(tile.actions, isEmpty);
    });

    test('two instances with equal actions lists compare equal', () {
      const tile1 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
        actions: [],
      );
      const tile2 = LayrzScaffoldValueTile(
        titleRichText: TextSpan(text: 'Title'),
        actions: [],
      );
      expect(tile1, equals(tile2));
    });
  });

  group('LayrzScaffoldTile subclassing', () {
    test('identity equality tile does not override ==', () {
      final tile1 = _IdentityTile('id1');
      final tile2 = _IdentityTile('id1');
      expect(tile1, isNot(equals(tile2)));
      expect(identical(tile1, tile2), isFalse);
    });

    test('value equality tile with id comparison', () {
      final tile1 = _IdBasedTile(id: 'id1', title: 'Title 1');
      final tile2 = _IdBasedTile(id: 'id1', title: 'Title 2');
      expect(tile1, equals(tile2));
    });

    test('value equality tile with different ids', () {
      final tile1 = _IdBasedTile(id: 'id1', title: 'Title');
      final tile2 = _IdBasedTile(id: 'id2', title: 'Title');
      expect(tile1, isNot(equals(tile2)));
    });
  });
}

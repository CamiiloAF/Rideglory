import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/events/presentation/form/utils/markdown_to_delta_converter.dart';

void main() {
  const converter = MarkdownToDeltaConverter();

  List<Map<String, dynamic>> ops(String markdown) {
    final delta = converter.convert(markdown);
    return (delta.toJson() as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic>? findOp(
    List<Map<String, dynamic>> opsList, {
    required bool Function(Map<String, dynamic>) where,
  }) {
    for (final op in opsList) {
      if (where(op)) return op;
    }
    return null;
  }

  group('MarkdownToDeltaConverter', () {
    group('AC1 — supported syntax conversion', () {
      test('plain text line is inserted as-is', () {
        final opsList = ops('Hola mundo');
        // Delta may merge adjacent inserts so check for contains
        final allInserts = opsList
            .map((op) => op['insert'] as String? ?? '')
            .join();
        expect(allInserts.contains('Hola mundo'), isTrue);
      });

      test('## H2 heading → newline op with header:2', () {
        final opsList = ops('## Descripción');
        final headerOp = findOp(
          opsList,
          where: (op) => op['attributes']?['header'] == 2,
        );
        expect(headerOp, isNotNull);
      });

      test('**bold** text → insert op with bold:true', () {
        final opsList = ops('**negrita**');
        final boldOp = findOp(
          opsList,
          where: (op) => op['attributes']?['bold'] == true,
        );
        expect(boldOp, isNotNull);
        expect(boldOp!['insert'], 'negrita');
      });

      test('*italic* text → insert op with italic:true', () {
        final opsList = ops('*cursiva*');
        final italicOp = findOp(
          opsList,
          where: (op) => op['attributes']?['italic'] == true,
        );
        expect(italicOp, isNotNull);
        expect(italicOp!['insert'], 'cursiva');
      });

      test('- bullet list → newline op with list:bullet', () {
        final opsList = ops('- elemento');
        final bulletOp = findOp(
          opsList,
          where: (op) => op['attributes']?['list'] == 'bullet',
        );
        expect(bulletOp, isNotNull);
      });

      test('multiline document produces multiple ops', () {
        final opsList = ops('## Título\nTexto plano\n- lista');
        expect(opsList.length, greaterThan(3));
      });
    });

    group('AC2 — unsupported syntax fallback without throw', () {
      test('unsupported syntax (> blockquote) is inserted as plain text', () {
        expect(
          () => converter.convert('> blockquote\n# H1\n```code```'),
          returnsNormally,
        );
        final opsList = ops('> blockquote');
        expect(opsList, isNotEmpty);
      });

      test('unclosed bold marker treated as plain text', () {
        expect(() => converter.convert('texto **sin cerrar'), returnsNormally);
        final opsList = ops('texto **sin cerrar');
        expect(opsList, isNotEmpty);
        expect(opsList.any((op) => op['attributes']?['bold'] == true), isFalse);
      });

      test('unclosed italic marker treated as plain text', () {
        expect(() => converter.convert('texto *sin cerrar'), returnsNormally);
        final opsList = ops('texto *sin cerrar');
        expect(opsList, isNotEmpty);
        expect(
          opsList.any((op) => op['attributes']?['italic'] == true),
          isFalse,
        );
      });
    });

    test('output always ends with newline op', () {
      final opsList = ops('Texto sin newline');
      final lastOp = opsList.last;
      expect((lastOp['insert'] as String?)?.endsWith('\n'), isTrue);
    });

    // CA8 — additional edge-case coverage
    test('bold+italic combo produces both bold:true and italic:true ops', () {
      final opsList = ops('**bold** y *italic*');
      final boldOp = findOp(
        opsList,
        where: (op) => op['attributes']?['bold'] == true,
      );
      final italicOp = findOp(
        opsList,
        where: (op) => op['attributes']?['italic'] == true,
      );
      expect(boldOp, isNotNull, reason: 'Expected a bold op');
      expect(italicOp, isNotNull, reason: 'Expected an italic op');
    });

    test(
      'empty input returns normally with at least one op (trailing newline)',
      () {
        expect(() => converter.convert(''), returnsNormally);
        final opsList = ops('');
        expect(
          opsList,
          isNotEmpty,
          reason:
              'Even empty input should produce at least the trailing newline',
        );
      },
    );
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextViewer extends StatelessWidget {
  final String content;

  const RichTextViewer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    quill.QuillController controller;
    try {
      // Intentar parsear como JSON
      final doc = quill.Document.fromJson(jsonDecode(content));
      controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      // Si falla, mostrar como texto plano
      final doc = quill.Document()..insert(0, content);
      controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }

    return quill.QuillEditor(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
    );
  }
}

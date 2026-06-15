import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichTextViewer extends StatelessWidget {
  final String content;
  final Color? textColor;
  final double fontSize;
  final double lineHeight;

  const RichTextViewer({
    super.key,
    required this.content,
    this.textColor,
    this.fontSize = 15,
    this.lineHeight = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    quill.QuillController controller;
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      final doc = quill.Document()..insert(0, content);
      controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }

    final resolvedColor = textColor ?? const Color(0xFFFFFFFF);
    return quill.QuillEditor(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      config: quill.QuillEditorConfig(
        padding: EdgeInsets.zero,
        customStyles: quill.DefaultStyles(
          paragraph: quill.DefaultTextBlockStyle(
            TextStyle(
              fontFamily: 'Space Grotesk',
              color: resolvedColor,
              fontSize: fontSize,
              height: lineHeight,
            ),
            const quill.HorizontalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
}

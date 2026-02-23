import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class AppRichTextEditor extends StatefulWidget {
  final String name;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? initialValue;
  final int minLines;
  final ValueChanged<String>? onChanged;

  const AppRichTextEditor({
    super.key,
    required this.name,
    this.labelText,
    this.hintText,
    this.helperText,
    this.isRequired = false,
    this.validator,
    this.initialValue,
    this.minLines = 5,
    this.onChanged,
  });

  @override
  State<AppRichTextEditor> createState() => _AppRichTextEditorState();
}

class _AppRichTextEditorState extends State<AppRichTextEditor> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = _initializeController();
    _controller.addListener(() {
      final jsonContent = _getJsonContent();
      widget.onChanged?.call(jsonContent);
    });
  }

  quill.QuillController _initializeController() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.initialValue!));
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Si falla el parsing, crear un documento con el texto plano
        final doc = quill.Document()..insert(0, widget.initialValue!);
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    return quill.QuillController.basic();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getJsonContent() {
    // Convertir el documento a JSON
    final delta = _controller.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,

      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null) ...[
              Text(
                widget.isRequired ? '${widget.labelText} *' : widget.labelText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Barra de herramientas
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          quill.QuillToolbarHistoryButton(
                            controller: _controller,
                            isUndo: true,
                          ),
                          quill.QuillToolbarHistoryButton(
                            controller: _controller,
                            isUndo: false,
                          ),
                          const SizedBox(width: 8),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.bold,
                            controller: _controller,
                          ),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.italic,
                            controller: _controller,
                          ),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.underline,
                            controller: _controller,
                          ),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.strikeThrough,
                            controller: _controller,
                          ),
                          const SizedBox(width: 8),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.ul,
                            controller: _controller,
                          ),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.ol,
                            controller: _controller,
                          ),
                          quill.QuillToolbarToggleStyleButton(
                            attribute: quill.Attribute.checked,
                            controller: _controller,
                          ),
                          const SizedBox(width: 8),
                          quill.QuillToolbarClearFormatButton(
                            controller: _controller,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Editor
                  Container(
                    constraints: BoxConstraints(
                      minHeight: widget.minLines * 24.0,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          // Guardar el contenido cuando se pierde el foco
                          field.didChange(_getJsonContent());
                        }
                      },
                      child: quill.QuillEditor(
                        controller: _controller,
                        focusNode: _focusNode,

                        scrollController: ScrollController(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.helperText != null || field.errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? widget.helperText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: field.hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

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

  /// When set, an "IA" toolbar button is shown for AI suggestions. Not implemented yet.
  final VoidCallback? onAiSuggest;

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
    this.onAiSuggest,
  });

  @override
  State<AppRichTextEditor> createState() => _AppRichTextEditorState();
}

class _AppRichTextEditorState extends State<AppRichTextEditor> {
  late QuillController _controller;
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

  QuillController _initializeController() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.initialValue!));
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Si falla el parsing, crear un documento con el texto plano
        final doc = Document()..insert(0, widget.initialValue!);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    return QuillController.basic();
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
    final colorScheme = theme.colorScheme;

    final toolbarToggleStyleButtonOptions =
        QuillToolbarToggleStyleButtonOptions(
          iconTheme: QuillIconTheme(
            iconButtonSelectedData: IconButtonData(
              color: colorScheme.onPrimary,
            ),
            iconButtonUnselectedData: IconButtonData(
              color: AppColors.darkTextSecondary,
            ),
          ),
        );

    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,

      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null) ...[
              TextFieldLabel(
                labelText: widget.labelText!,
                isRequired: widget.isRequired,
              ),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceHighest,
                border: Border.all(
                  color: field.hasError
                      ? colorScheme.error
                      : colorScheme.primary,
                  width: field.hasError ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
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
                          QuillToolbarHistoryButton(
                            controller: _controller,
                            isUndo: true,
                          ),
                          QuillToolbarHistoryButton(
                            controller: _controller,
                            isUndo: false,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.bold,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.italic,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.underline,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.strikeThrough,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.ul,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.ol,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.checked,
                            controller: _controller,
                            options: toolbarToggleStyleButtonOptions,
                          ),
                          const SizedBox(width: 8),
                          QuillToolbarClearFormatButton(
                            controller: _controller,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: widget.minLines * 24.0,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          widget.onAiSuggest != null ? 48 : 16,
                          16,
                        ),
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              field.didChange(_getJsonContent());
                            }
                          },
                          child: QuillEditor(
                            controller: _controller,
                            focusNode: _focusNode,
                            scrollController: ScrollController(),
                          ),
                        ),
                      ),
                      if (widget.onAiSuggest != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onAiSuggest,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'IA',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/design_system/design_system.dart';

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
  final VoidCallback? onAiSuggest;
  final QuillController? externalController;

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
    this.externalController,
  });

  @override
  State<AppRichTextEditor> createState() => _AppRichTextEditorState();
}

class _AppRichTextEditorState extends State<AppRichTextEditor> {
  late QuillController _controller;
  late bool _ownsController;
  final FocusNode _focusNode = FocusNode();
  FormFieldState<String>? _field;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.externalController == null;
    _controller = widget.externalController ?? _initializeController();
    _controller.addListener(() {
      final jsonContent = _getJsonContent();
      _field?.didChange(jsonContent);
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
      } catch (_) {
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
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getJsonContent() {
    final delta = _controller.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,
      builder: (field) {
        _field = field;

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
                color: AppColors.darkCard,
                border: Border.all(
                  color: field.hasError
                      ? colorScheme.error
                      : AppColors.darkBorderPrimary,
                  width: field.hasError ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área de texto
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: widget.minLines * 24.0,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          14,
                          widget.onAiSuggest != null ? 52 : 16,
                          14,
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 15,
                            height: 1.6,
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
                              config: QuillEditorConfig(
                                placeholder: widget.hintText ?? '',
                                autoFocus: false,
                                expands: false,
                                padding: EdgeInsets.zero,
                                customStyles: const DefaultStyles(
                                  placeHolder: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: AppColors.textOnDarkTertiary,
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                    HorizontalSpacing.zero,
                                    VerticalSpacing.zero,
                                    VerticalSpacing.zero,
                                    null,
                                  ),
                                  paragraph: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: AppColors.textOnDarkPrimary,
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                    HorizontalSpacing.zero,
                                    VerticalSpacing.zero,
                                    VerticalSpacing.zero,
                                    null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onAiSuggest != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: widget.onAiSuggest,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'IA',
                                    style: TextStyle(
                                      fontFamily: 'Space Grotesk',
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Separador
                  Container(height: 1, color: AppColors.darkBorderPrimary),

                  // Toolbar en la parte inferior
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ToolbarBtn(
                            attribute: Attribute.bold,
                            controller: _controller,
                            icon: Icons.format_bold,
                          ),
                          _ToolbarBtn(
                            attribute: Attribute.italic,
                            controller: _controller,
                            icon: Icons.format_italic,
                          ),
                          _ToolbarBtn(
                            attribute: Attribute.underline,
                            controller: _controller,
                            icon: Icons.format_underline,
                          ),
                          const _ToolbarDivider(),
                          _ToolbarBtn(
                            attribute: Attribute.ul,
                            controller: _controller,
                            icon: Icons.format_list_bulleted,
                          ),
                          _ToolbarBtn(
                            attribute: Attribute.ol,
                            controller: _controller,
                            icon: Icons.format_list_numbered,
                          ),
                          const _ToolbarDivider(),
                          QuillToolbarLinkStyleButton(
                            controller: _controller,
                            options: const QuillToolbarLinkStyleButtonOptions(
                              iconTheme: QuillIconTheme(
                                iconButtonSelectedData: IconButtonData(
                                  color: AppColors.textOnDarkPrimary,
                                ),
                                iconButtonUnselectedData: IconButtonData(
                                  color: AppColors.textOnDarkTertiary,
                                ),
                              ),
                              iconSize: 18,
                              iconButtonFactor: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.helperText != null || field.errorText != null) ...[
              AppSpacing.gapSm,
              Text(
                field.errorText ?? widget.helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: field.hasError
                      ? colorScheme.error
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.attribute,
    required this.controller,
    required this.icon,
  });

  final Attribute attribute;
  final QuillController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return QuillToolbarToggleStyleButton(
      attribute: attribute,
      controller: controller,
      options: QuillToolbarToggleStyleButtonOptions(
        iconData: icon,
        iconSize: 18,
        iconButtonFactor: 1.2,
        iconTheme: const QuillIconTheme(
          iconButtonSelectedData: IconButtonData(
            color: AppColors.textOnDarkPrimary,
          ),
          iconButtonUnselectedData: IconButtonData(
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.darkBorderPrimary,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

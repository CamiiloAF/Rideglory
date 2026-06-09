import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/utils/markdown_to_delta_converter.dart';

class AiInsertButton extends StatelessWidget {
  const AiInsertButton({
    super.key,
    required this.markdown,
    required this.quillController,
    this.onInserted,
  });

  final String markdown;
  final QuillController quillController;

  /// Called after the description has been inserted into the controller.
  final VoidCallback? onInserted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppButton(
        label: context.l10n.ai_insertButton,
        onPressed: () => _handleInsert(context),
        variant: AppButtonVariant.primary,
      ),
    );
  }

  Future<void> _handleInsert(BuildContext context) async {
    final hasContent = quillController.document.length > 1;

    if (hasContent) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: context.l10n.ai_confirmReplaceTitle,
        content: context.l10n.ai_confirmReplaceMessage,
      );
      if (confirmed != true) return;
    }

    _insertDelta(quillController, markdown);
    onInserted?.call();
  }

  void _insertDelta(QuillController controller, String markdownText) {
    const converter = MarkdownToDeltaConverter();
    final delta = converter.convert(markdownText);
    controller.document = Document.fromDelta(delta);
    controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }
}

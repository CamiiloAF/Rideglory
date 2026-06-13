import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/utils/markdown_to_delta_converter.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_bubble.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_empty_state.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_error_banner.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_input_row.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_loading_indicator.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_quota_exhausted_banner.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_quota_indicator.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_quota_info_sheet.dart';

class AiDescriptionChatPage extends StatelessWidget {
  const AiDescriptionChatPage({
    super.key,
    required this.quillController,
    required this.eventContext,
  });

  final QuillController quillController;
  final AiDescriptionRequest eventContext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: colorScheme.onSurface),
        title: Text(
          context.l10n.ai_chatTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          BlocBuilder<AiDescriptionChatCubit, AiDescriptionChatState>(
            buildWhen: (previous, current) =>
                previous.remainingQuota != current.remainingQuota ||
                previous.sendResult != current.sendResult,
            builder: (context, state) {
              final cubit = context.read<AiDescriptionChatCubit>();
              final quota = state.remainingQuota;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AiQuotaIndicator(
                  remainingQuota: quota,
                  isExhausted: cubit.isQuotaExhausted,
                  onTap: quota != null
                      ? () => AiQuotaInfoSheet.show(
                            context: context,
                            remainingQuota: quota,
                            isExhausted: cubit.isQuotaExhausted,
                          )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AiDescriptionChatCubit, AiDescriptionChatState>(
              builder: (context, state) {
                final isLoading = state.sendResult is Loading;
                final error = state.sendResult.whenOrNull(error: (err) => err);
                final hasError = error != null;

                if (state.history.isEmpty && !isLoading && !hasError) {
                  return const AiChatEmptyState();
                }

                return ListView.builder(
                  reverse: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: state.history.length +
                      (isLoading ? 1 : 0) +
                      (hasError ? 1 : 0),
                  itemBuilder: (context, index) {
                    var virtualIndex = index;

                    if (hasError) {
                      if (virtualIndex == 0) {
                        return AiChatErrorBanner(
                          error: error,
                          onRetry: error is AiQuotaExceededUserException
                              ? null
                              : () => _retryLastMessage(context),
                        );
                      }
                      virtualIndex--;
                    }

                    if (isLoading) {
                      if (virtualIndex == 0) {
                        return const AiChatLoadingIndicator();
                      }
                      virtualIndex--;
                    }

                    final bubbleIndex =
                        state.history.length - 1 - virtualIndex;
                    if (bubbleIndex >= 0 &&
                        bubbleIndex < state.history.length) {
                      final turn = state.history[bubbleIndex];
                      return AiChatBubble(
                        turn: turn,
                        onCopy: () => _copyMessage(context, turn.content),
                        onInsert: turn.isDescription
                            ? () => _insertMessage(context, turn.content)
                            : null,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          BlocBuilder<AiDescriptionChatCubit, AiDescriptionChatState>(
            buildWhen: (previous, current) =>
                previous.sendResult != current.sendResult ||
                previous.remainingQuota != current.remainingQuota,
            builder: (context, state) {
              final cubit = context.read<AiDescriptionChatCubit>();
              final isExhausted = cubit.isQuotaExhausted;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isExhausted) const AiQuotaExhaustedBanner(),
                  SafeArea(
                    top: false,
                    child: AiChatInputRow(
                  disabled: cubit.isQuotaExhausted ||
                      state.sendResult is Loading,
                  onSend: (message) => cubit.sendMessage(
                    userMessage: message,
                    title: eventContext.title,
                    eventType: eventContext.eventType,
                    difficulty: eventContext.difficulty,
                    startDate: eventContext.startDate,
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _retryLastMessage(BuildContext context) {
    context.read<AiDescriptionChatCubit>().retryLastMessage(
          title: eventContext.title,
          eventType: eventContext.eventType,
          difficulty: eventContext.difficulty,
          startDate: eventContext.startDate,
        );
  }

  void _copyMessage(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.ai_messageCopied),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _insertMessage(BuildContext context, String markdown) async {
    final navigator = Navigator.of(context);
    final hasContent = quillController.document.length > 1;

    if (hasContent) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: context.l10n.ai_confirmReplaceTitle,
        content: context.l10n.ai_confirmReplaceMessage,
      );
      if (confirmed != true) return;
    }

    const converter = MarkdownToDeltaConverter();
    final delta = converter.convert(markdown);
    quillController.document = Document.fromDelta(delta);
    quillController.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    navigator.pop();
  }
}

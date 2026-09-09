import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../auth_error_translator.dart';
import '../cubit/forgot_password_cubit.dart';

/// Recuperar contraseña: envía un enlace de `resetPasswordForEmail` al
/// correo del rider.
///
/// Pencil: CBfOH
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppPageHeader(title: context.l10n.auth_forgot_title),
            body: BlocConsumer<ForgotPasswordCubit, ResultState<Unit>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.auth_forgot_sent_body)),
                  ),
                  error: (error) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authErrorMessage(context, error))),
                  ),
                );
              },
              builder: (context, state) {
                final isLoading = state is Loading;
                final colors = Theme.of(context).extension<AppColors>()!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.auth_forgot_heading,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.auth_forgot_body,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: context.l10n.auth_email_field_label,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 260),
                      AppPrimaryButton(
                        label: context.l10n.auth_forgot_send_button,
                        onPressed: isLoading
                            ? null
                            : () => context
                                  .read<ForgotPasswordCubit>()
                                  .sendResetLink(
                                    email: _emailController.text.trim(),
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

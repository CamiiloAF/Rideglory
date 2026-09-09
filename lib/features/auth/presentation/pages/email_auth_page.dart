import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../core/exceptions/domain_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/go_router_extensions.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth_error_translator.dart';
import '../cubit/email_auth_cubit.dart';

/// Entrar o crear cuenta con correo. El `.pen` solo diseñó el login
/// (`ROAHx`/`xTYYm`); el registro reutiliza el mismo layout con un campo de
/// nombre adicional (decisión de F4, sin frame propio).
///
/// Pencil: ROAHx (login), xTYYm (error de inicio)
class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({this.isRegister = false, super.key});

  final bool isRegister;

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final cubit = context.read<EmailAuthCubit>();
    if (widget.isRegister) {
      cubit.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
    } else {
      cubit.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmailAuthCubit>(),
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).extension<AppColors>()!;
          return Scaffold(
            appBar: AppPageHeader(
              title: widget.isRegister
                  ? context.l10n.auth_register_title
                  : context.l10n.auth_email_login_title,
            ),
            body: BlocConsumer<EmailAuthCubit, ResultState<Unit>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) =>
                      context.goAndClearStack(AppRoutes.maintenancePath),
                );
              },
              builder: (context, state) {
                final DomainException? error = state is Error<Unit>
                    ? state.error
                    : null;
                final isLoading = state is Loading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        AppBanner(
                          icon: LucideIcons.alertTriangle,
                          title: context.l10n.auth_error_banner_title,
                          body: authErrorMessage(context, error),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (widget.isRegister) ...[
                        AppTextField(
                          label: context.l10n.auth_register_name_label,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 14),
                      ],
                      AppTextField(
                        label: context.l10n.auth_email_field_label,
                        controller: _emailController,
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.l10n.auth_password_field_label,
                        controller: _passwordController,
                        icon: LucideIcons.lock,
                        obscureText: _obscurePassword,
                        suffixText: _obscurePassword
                            ? context.l10n.auth_password_show_action
                            : context.l10n.auth_password_hide_action,
                        onSuffixTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        errorText: error != null
                            ? context.l10n.auth_password_error_helper
                            : null,
                      ),
                      if (!widget.isRegister) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: TextButton(
                              onPressed: () => context.pushNamed(
                                AppRoutes.authForgotPassword,
                              ),
                              child: Text(
                                context.l10n.auth_forgot_password_link,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        const SizedBox(height: 24),
                      const SizedBox(height: 40),
                      AppPrimaryButton(
                        label: widget.isRegister
                            ? context.l10n.auth_register_button
                            : context.l10n.auth_sign_in_button,
                        onPressed: isLoading ? null : () => _submit(context),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            if (widget.isRegister) {
                              Navigator.of(context).maybePop();
                            } else {
                              context.pushNamed(AppRoutes.authEmailRegister);
                            }
                          },
                          child: Text(
                            widget.isRegister
                                ? context.l10n.auth_have_account_link
                                : context.l10n.auth_create_account_link,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class SplashFooter extends StatelessWidget {
  final Animation<double> progressAnimation;
  final VoidCallback onRetry;

  const SplashFooter({
    super.key,
    required this.progressAnimation,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 80,
      right: 80,
      bottom: 60,
      child: BlocBuilder<SplashCubit, SplashState>(
        builder: (context, state) {
          final isError = state is SplashError;
          if (isError) {
            return Column(
              children: [
                Text(
                  '${context.l10n.splash_errorPrefix}${state.message}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    context.l10n.splash_retryLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            );
          }
          return AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, _) {
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

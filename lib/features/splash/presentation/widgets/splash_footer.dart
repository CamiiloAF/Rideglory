import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/splash/constants/splash_strings.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';

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
      left: 32,
      right: 32,
      bottom: 40,
      child: BlocBuilder<SplashCubit, SplashState>(
        builder: (context, state) {
          final isError = state is SplashError;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isError) ...[
                Text(
                  '${SplashStrings.errorPrefix}${state.message}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    SplashStrings.retryLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      SplashStrings.initializingLabel,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: progressAnimation,
                      builder: (context, _) {
                        return Text(
                          '${(progressAnimation.value * 100).toInt()}%',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: progressAnimation,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 20),
              Center(
                child: Text(
                  SplashStrings.versionLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.outlineVariant,
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

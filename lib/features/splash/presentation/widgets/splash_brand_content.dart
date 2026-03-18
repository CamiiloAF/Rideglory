import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class SplashBrandContent extends StatelessWidget {
  const SplashBrandContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.two_wheeler_rounded,
                size: 56,
                color: context.colorScheme.primary,
              ),
            ),
            SizedBox(height: 40),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: context.l10n.splash_appNameRide,
                    style: context.textTheme.displayLarge?.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: context.l10n.splash_appNameGlory,
                    style: context.textTheme.displayLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              context.l10n.splash_tagline,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onSurfaceVariant,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

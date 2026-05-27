import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Simple back-navigation app bar used when the event is not yet in progress
/// or the event id is missing.
class LiveMapSimpleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LiveMapSimpleAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.textOnDarkPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevation: 0,
    );
  }
}

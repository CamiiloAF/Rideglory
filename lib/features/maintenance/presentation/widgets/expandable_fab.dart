import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/fab_option.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({super.key});

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleOptionPressed(String message) {
    _toggleFab();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isFabExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: FabOption(
                          icon: Icons.build,
                          label: MaintenanceStrings.addMaintenance_,
                          onPressed: () async {
                            _toggleFab();
                            final result = await context.pushNamed<bool?>(
                              AppRoutes.createMaintenance,
                            );

                            if (result == true && context.mounted) {
                              context
                                  .read<MaintenancesCubit>()
                                  .fetchMaintenances();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: FabOption(
                          icon: Icons.history,
                          label: MaintenanceStrings.maintenanceHistory,
                          onPressed: () {
                            _handleOptionPressed(
                              MaintenanceStrings.maintenanceHistory,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: FabOption(
                          icon: Icons.notifications_active,
                          label: MaintenanceStrings.reminders,
                          onPressed: () {
                            _handleOptionPressed(MaintenanceStrings.reminders);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          onPressed: _toggleFab,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: _isFabExpanded ? 0.125 : 0,
            child: Icon(_isFabExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

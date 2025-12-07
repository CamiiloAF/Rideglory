import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/fab_option.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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
                          label: 'Agregar Mantenimiento',
                          onPressed: () {
                            _toggleFab();
                            context.pushNamed(AppRoutes.createMaintenance);
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
                          label: 'Ver Historial',
                          onPressed: () {
                            _handleOptionPressed('Ver Historial');
                            // TODO: Navegar a historial
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
                          label: 'Recordatorios',
                          onPressed: () {
                            _handleOptionPressed('Recordatorios');
                            // TODO: Navegar a recordatorios
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

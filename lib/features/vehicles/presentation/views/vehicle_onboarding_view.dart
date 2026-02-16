import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleOnboardingView extends StatefulWidget {
  const VehicleOnboardingView({super.key});

  @override
  State<VehicleOnboardingView> createState() => _VehicleOnboardingViewState();
}

class _VehicleOnboardingViewState extends State<VehicleOnboardingView> {
  final List<GlobalKey<FormBuilderState>> _formKeys = [];
  int _currentPage = 0;
  final _pageController = PageController();

  @override
  void initState() {
    _addVehicle();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addVehicle() {
    setState(() {
      _formKeys.add(GlobalKey<FormBuilderState>());
      _currentPage = _formKeys.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _removeVehicle(int index) {
    if (_formKeys.length > 1) {
      setState(() {
        _formKeys.removeAt(index);
        if (_currentPage >= _formKeys.length) {
          _currentPage = _formKeys.length - 1;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _saveVehicles(BuildContext context) async {
    bool allValid = true;
    for (int i = 0; i < _formKeys.length; i++) {
      final formKey = _formKeys[i];
      if (!(formKey.currentState?.saveAndValidate() ?? false)) {
        allValid = false;
      }
    }
    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    final vehicleFormCubit = context.read<VehicleFormCubit>();
    final vehiclesToAdd = _formKeys.map((formKey) {
      final formData = formKey.currentState!.value;
      return VehicleModel(
        name: formData['name'] as String,
        brand: (formData['brand'] as String?)?.isEmpty ?? true
            ? null
            : formData['brand'] as String?,
        model: (formData['model'] as String?)?.isEmpty ?? true
            ? null
            : formData['model'] as String?,
        year:
            formData['year'] != null && (formData['year'] as String).isNotEmpty
            ? int.tryParse(formData['year'] as String)
            : null,
        currentMileage: int.parse(formData['currentMileage'] as String),
        distanceUnit: formData['distanceUnit'] as DistanceUnit,
        licensePlate: (formData['licensePlate'] as String?)?.isEmpty ?? true
            ? null
            : formData['licensePlate'] as String?,
        vin: (formData['vin'] as String?)?.isEmpty ?? true
            ? null
            : formData['vin'] as String?,
      );
    }).toList();
    await vehicleFormCubit.addMultipleVehicles(vehiclesToAdd);
  }

  void _listener(BuildContext context, VehicleFormState state) {
    state.vehicleResult.whenOrNull(
      data: (data) async {
        final vehicleCubit = context.read<VehicleCubit>();

        if (vehicleCubit.currentVehicle == null) {
          await vehicleCubit.setCurrentVehicle(data);
        }

        if (!context.mounted) return;

        context.pushReplacementNamed(AppRoutes.maintenances);
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VehicleFormCubit>(),
      child: BlocConsumer<VehicleFormCubit, VehicleFormState>(
        listener: _listener,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido! 🎉',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega al menos un vehículo para comenzar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vehicle counter and add button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehículo ${_currentPage + 1} de ${_formKeys.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            if (_formKeys.length > 1)
                              IconButton(
                                onPressed: () => _removeVehicle(_currentPage),
                                icon: const Icon(Icons.remove_circle_outline),
                                color: const Color(0xFFEF4444),
                                tooltip: 'Eliminar vehículo',
                              ),
                            IconButton(
                              onPressed: _addVehicle,
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF6366F1),
                              tooltip: 'Agregar otro vehículo',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Page indicator
                  if (_formKeys.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _formKeys.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Vehicle forms
                  if (_formKeys.isNotEmpty)
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _formKeys.length,
                        itemBuilder: (context, index) {
                          final formKey = _formKeys[index];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: VehicleForm(
                              formKey: formKey,
                              isOnboarding: true,
                            ),
                          );
                        },
                      ),
                    ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        BlocBuilder<VehicleFormCubit, VehicleFormState>(
                          builder: (context, state) {
                            final isLoading = state.isLoading;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: .3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: isLoading
                                      ? null
                                      : () => _saveVehicles(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Completar configuración',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

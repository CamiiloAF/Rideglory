import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/onboarding/vehicle_onboarding_header.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/onboarding/vehicle_onboarding_counter.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/onboarding/vehicle_onboarding_page_indicator.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/onboarding/vehicle_onboarding_form_page.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

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
    _pageController.addListener(_onPageChanged);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    // Remove focus from all inputs when user swipes between pages
    FocusScope.of(context).unfocus();
  }

  void _showExitConfirmationDialog() {
    ConfirmationDialog.show(
      context: context,
      title: VehicleStrings.exitSetup,
      content: VehicleStrings.exitSetupMessage,
      cancelLabel: AppStrings.cancel,
      confirmLabel: AppStrings.exit,
      confirmType: DialogActionType.danger,
      dialogType: DialogType.warning,
      onConfirm: () {
        SystemNavigator.pop();
      },
    );
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
          content: Text(VehicleStrings.completeRequiredFields),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    final vehicleFormCubit = context.read<VehicleFormCubit>();
    final vehiclesToAdd = _formKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final formKey = entry.value;
      final formData = formKey.currentState!.value;
      final isFirstVehicle = index == 0;

      return VehicleModel(
        name: formData[VehicleFormFields.name] as String,
        brand: (formData[VehicleFormFields.brand] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.brand] as String?,
        model: (formData[VehicleFormFields.model] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.model] as String?,
        year:
            formData[VehicleFormFields.year] != null &&
                (formData[VehicleFormFields.year] as String).isNotEmpty
            ? int.tryParse(formData[VehicleFormFields.year] as String)
            : null,
        currentMileage: int.parse(
          formData[VehicleFormFields.currentMileage] as String,
        ),
        distanceUnit: formData[VehicleFormFields.distanceUnit] as DistanceUnit,
        licensePlate:
            (formData[VehicleFormFields.licensePlate] as String?)?.isEmpty ??
                true
            ? null
            : formData[VehicleFormFields.licensePlate] as String?,
        vin: (formData[VehicleFormFields.vin] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.vin] as String?,
        isMainVehicle: isFirstVehicle, // First vehicle is always main
      );
    }).toList();
    await vehicleFormCubit.addMultipleVehicles(vehiclesToAdd);
  }

  void _listener(BuildContext context, VehicleFormState state) {
    state.vehicleResult.whenOrNull(
      data: (data) async {
        final authCubit = context.read<AuthCubit>();
        final vehicleCubit = context.read<VehicleCubit>();

        // Sync vehicles from Firebase - this will load all vehicles
        // and automatically select the one with isMainVehicle = true
        await authCubit.syncAuthenticatedUserVehicles();

        // After sync, the currentVehicle should be the main one
        // Now save it to userMainVehicle collection in Firebase
        final mainVehicle = vehicleCubit.currentVehicle;
        if (mainVehicle?.id != null) {
          await vehicleCubit.setMainVehicle(mainVehicle!.id!);
        }

        if (context.mounted) {
          context.pushReplacementNamed(AppRoutes.maintenances);
        }
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
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              _showExitConfirmationDialog();
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    const VehicleOnboardingHeader(),

                    // Vehicle counter and add button
                    VehicleOnboardingCounter(
                      currentPage: _currentPage,
                      totalPages: _formKeys.length,
                      onAddVehicle: _addVehicle,
                      onRemoveVehicle: () => _removeVehicle(_currentPage),
                      canRemove: _formKeys.length > 1,
                    ),

                    // Page indicator
                    VehicleOnboardingPageIndicator(
                      totalPages: _formKeys.length,
                      currentPage: _currentPage,
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
                            return VehicleOnboardingFormPage(
                              formKey: formKey,
                              isFirstVehicle: index == 0,
                            );
                          },
                        ),
                      ),

                    // Bottom buttons
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: BlocBuilder<VehicleFormCubit, VehicleFormState>(
                        builder: (context, state) {
                          return AppButton(
                            label: VehicleStrings.completeSetup,
                            onPressed: () => _saveVehicles(context),
                            isLoading: state.isLoading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

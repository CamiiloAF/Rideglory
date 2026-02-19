import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form.dart';

/// Wrapper widget that keeps the form alive when navigating between pages
class VehicleOnboardingFormPage extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final bool isFirstVehicle;

  const VehicleOnboardingFormPage({
    super.key,
    required this.formKey,
    required this.isFirstVehicle,
  });

  @override
  State<VehicleOnboardingFormPage> createState() =>
      _VehicleOnboardingFormPageState();
}

class _VehicleOnboardingFormPageState extends State<VehicleOnboardingFormPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: VehicleForm(
        formKey: widget.formKey,
        isOnboarding: true,
        isFirstVehicleInOnboarding: widget.isFirstVehicle,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_entry_flow.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/empty_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// SOAT-specific empty state. Delegates layout to [DocumentEmptyState],
/// injecting SOAT-specific copy and the SOAT entry flow as CTA.
class SoatEmptyState extends StatelessWidget {
  const SoatEmptyState({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return DocumentEmptyState(
      icon: Icons.description_outlined,
      title: context.l10n.soat_status_no_soat,
      subtitle: context.l10n.soat_manual_note,
      ctaLabel: context.l10n.soat_renew_btn,
      onCta: () => SoatEntryFlow.start(
        context,
        vehicle: vehicle,
        onSaved: () {
          if (context.mounted) {
            context.read<SoatCubit>().load(vehicle.id ?? '');
          }
        },
      ),
    );
  }
}

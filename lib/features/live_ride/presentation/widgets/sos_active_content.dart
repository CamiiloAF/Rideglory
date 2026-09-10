import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/live_ride_cubit.dart';
import 'sos_active_status_header.dart';
import 'sos_coordinates_card.dart';
import 'sos_fallback_actions.dart';

/// Cuerpo de LV4a/LV4b: estado (pendiente/confirmado), coordenadas,
/// fallback de contacto/SMS/123 y el cierre. Lee `contacts` de
/// [LiveRideCubit] (D17: se cachearon al empezar la rodada, no se piden
/// aquí).
class SosActiveContent extends StatelessWidget {
  const SosActiveContent({
    required this.isConfirmed,
    required this.lat,
    required this.lng,
    required this.isBusy,
    required this.onClose,
    super.key,
    this.accuracyM,
  });

  final bool isConfirmed;
  final double lat;
  final double lng;
  final double? accuracyM;
  final bool isBusy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final contacts = context.watch<LiveRideCubit>().state.contacts;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SosActiveStatusHeader(isConfirmed: isConfirmed),
          const SizedBox(height: 18),
          SosCoordinatesCard(lat: lat, lng: lng, accuracyM: accuracyM),
          const SizedBox(height: 14),
          SosFallbackActions(lat: lat, lng: lng, contacts: contacts),
          const SizedBox(height: 14),
          Container(width: double.infinity, height: 1, color: colors.border),
          const SizedBox(height: 14),
          AppSecondaryButton(
            label: context.l10n.sos_close_cta,
            destructive: true,
            onPressed: isBusy ? null : onClose,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

const _kAvatarColors = [
  AppColors.primary,
  AppColors.info,
  AppColors.success,
  Color(0xFFEAB308),
  Color(0xFFEC4899),
];

/// Vista de participantes para usuarios normales (no owners).
/// Muestra: cabecera "Inscritos" + badge conteo + stack de avatares + subtexto.
/// Durante recargas silenciosas mantiene la lista anterior visible (sin flash vacío).
/// Diseño: Pencil node puO3f.
class EventDetailParticipantsSummary extends StatefulWidget {
  const EventDetailParticipantsSummary({super.key, required this.event});

  final EventModel event;

  @override
  State<EventDetailParticipantsSummary> createState() =>
      _EventDetailParticipantsSummaryState();
}

class _EventDetailParticipantsSummaryState
    extends State<EventDetailParticipantsSummary> {
  static const int _maxAvatars = 5;

  List<EventRegistrationModel> _lastVisible = const [];

  List<EventRegistrationModel> _applyFilters(
    List<EventRegistrationModel> regs,
  ) {
    final result = regs
        .where(
          (r) =>
              r.userId != widget.event.ownerId &&
              r.status != RegistrationStatus.cancelled,
        )
        .toList();
    _lastVisible = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailCubit, EventDetailState>(
      buildWhen: (prev, curr) => prev.attendeesResult != curr.attendeesResult,
      builder: (context, state) {
        final allVisible = state.attendeesResult.when(
          initial: () => const <EventRegistrationModel>[],
          // Durante recarga silenciosa se mantiene la lista anterior para
          // evitar el flash de lista vacía.
          loading: () => _lastVisible,
          data: _applyFilters,
          empty: () => const <EventRegistrationModel>[],
          error: (_) => _lastVisible,
        );

        final count = allVisible.length;
        final preview = allVisible.take(_maxAvatars).toList();
        final overflow = count - _maxAvatars;
        final avatarCount = preview.length + (overflow > 0 ? 1 : 0);

        final maxP = widget.event.maxParticipants ?? 0;
        final hasSlots = maxP > 0;
        final slots = hasSlots ? (maxP - count).clamp(0, maxP).toInt() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.event_registrationsTab,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.19),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ),
              ],
            ),
            if (count > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                width: avatarCount > 0 ? (avatarCount * 26.0 + 10.0) : 0,
                child: Stack(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Positioned(
                        left: i * 26.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kAvatarColors[i % _kAvatarColors.length],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.darkBgPrimary,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(preview[i].fullName),
                            style: const TextStyle(
                              color: AppColors.darkBgPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Space Grotesk',
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    if (overflow > 0)
                      Positioned(
                        left: preview.length * 26.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.darkBgPrimary,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$overflow',
                            style: const TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Space Grotesk',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              hasSlots
                  ? context.l10n.event_participantsSummary(count, slots)
                  : context.l10n.event_participantsSummaryNoSlots(count),
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        );
      },
    );
  }
}

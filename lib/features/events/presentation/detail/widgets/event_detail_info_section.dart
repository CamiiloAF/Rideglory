import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDetailInfoSection extends StatelessWidget {
  final EventModel event;
  const EventDetailInfoSection({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Route ──────────────────────────────────────────────
          _RouteRow(event: event),
          const SizedBox(height: 20),

          // ── Allowed brands ────────────────────────────────────
          if (!event.isMultiBrand && event.allowedBrands.isNotEmpty) ...[
            _SectionLabel(label: EventStrings.allowedBrands),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.allowedBrands
                  .map((b) => _BrandChip(label: b))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ] else ...[
            _BrandChip(label: EventStrings.allBrands),
            const SizedBox(height: 20),
          ],

          // ── Difficulty ────────────────────────────────────────
          _DifficultyCard(difficulty: event.difficulty),
          const SizedBox(height: 24),

          // ── Section title ─────────────────────────────────────
          Text(
            'Detalles del Evento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // ── Date / time card ──────────────────────────────────
          _DateTimeCard(event: event),
          const SizedBox(height: 12),

          // ── Description card ──────────────────────────────────
          _DescriptionCard(description: event.description),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final EventModel event;
  const _RouteRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.map_outlined, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trayecto',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              Text(
                '${event.meetingPoint} → ${event.destination}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String label;
  const _BrandChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final EventDifficulty difficulty;
  const _DifficultyCard({required this.difficulty});

  static String _label(EventDifficulty d) => switch (d) {
    EventDifficulty.one => 'Fácil',
    EventDifficulty.two => 'Moderado',
    EventDifficulty.three => 'Intermedio',
    EventDifficulty.four => 'Difícil',
    EventDifficulty.five => 'Muy difícil',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIVEL DE DIFICULTAD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(difficulty),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.local_fire_department,
                size: 26,
                color: i < difficulty.value
                    ? Colors.redAccent
                    : cs.onSurface.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final EventModel event;
  const _DateTimeCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat("d 'de' MMMM, yyyy", 'es');
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FECHA Y HORA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(event.startDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timeFmt.format(event.meetingTime)} · Punto de encuentro',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                ),
                if (event.endDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hasta: ${dateFmt.format(event.endDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_city, color: AppColors.primary, size: 28),
                const SizedBox(height: 4),
                Text(
                  event.city,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;
  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Descripción',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

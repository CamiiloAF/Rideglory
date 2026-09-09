import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../domain/consent_entry.dart';
import '../cubit/consent_log_cubit.dart';
import '../widgets/consent_entry_tile.dart';

/// "Mis consentimientos": lista de `consent_log` (evidencia legal de riesgo,
/// médico y términos).
class ConsentsPage extends StatelessWidget {
  const ConsentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConsentLogCubit>()..load(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppPageHeader(title: context.l10n.profile_consents_title),
            body: BlocBuilder<ConsentLogCubit, ResultState<List<ConsentEntry>>>(
              builder: (context, state) {
                return state.when(
                  initial: () => const SkeletonList(),
                  loading: () => const SkeletonList(),
                  empty: () => EmptyStateView(
                    icon: LucideIcons.checkCheck,
                    title: context.l10n.profile_consents_empty_title,
                    body: context.l10n.profile_consents_empty_body,
                  ),
                  error: (error) => ErrorStateView(
                    onRetry: () => context.read<ConsentLogCubit>().load(),
                  ),
                  data: (entries) => ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        ConsentEntryTile(entry: entries[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/brand_picker_cubit.dart';
import '../cubit/brand_picker_state.dart';
import '../widgets/brand_picker_list.dart';

/// SEL — Buscador y lista de marca.
///
/// Pencil: LHKHl
class BrandPickerPage extends StatelessWidget {
  const BrandPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BrandPickerCubit>(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<BrandPickerCubit>();
          return Scaffold(
            appBar: AppPageHeader(title: context.l10n.garage_brand_picker_title),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: context.l10n.garage_brand_search_label,
                      controller: cubit.searchController,
                      onChanged: cubit.search,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BlocBuilder<BrandPickerCubit, BrandPickerState>(
                        builder: (context, state) => BrandPickerList(
                          brands: state.results,
                          onSelected: (brand) => context.pop(brand),
                        ),
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

import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_type_card.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_type_header.dart';

class MaintenanceTypeSelection extends StatefulWidget {
  final MaintenanceType? initialType;
  final ValueChanged<MaintenanceType> onContinue;
  final VoidCallback onBack;

  const MaintenanceTypeSelection({
    super.key,
    this.initialType,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<MaintenanceTypeSelection> createState() =>
      _MaintenanceTypeSelectionState();
}

class _MaintenanceTypeSelectionState extends State<MaintenanceTypeSelection> {
  late MaintenanceType _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType ?? MaintenanceType.oilChange;
  }

  @override
  Widget build(BuildContext context) {
    const types = MaintenanceType.values;
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            MaintenanceTypeHeader(onBack: widget.onBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.darkBorderPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.maintenance_form_step_select,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    for (int row = 0; row < 4; row++) ...[
                      if (row > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MaintenanceTypeCard(
                              type: types[row * 2],
                              isSelected: _selected == types[row * 2],
                              onTap: () =>
                                  setState(() => _selected = types[row * 2]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MaintenanceTypeCard(
                              type: types[row * 2 + 1],
                              isSelected: _selected == types[row * 2 + 1],
                              onTap: () => setState(
                                () => _selected = types[row * 2 + 1],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              child: AppButton(
                label: context.l10n.maintenance_form_step_continue,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                onPressed: () => widget.onContinue(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

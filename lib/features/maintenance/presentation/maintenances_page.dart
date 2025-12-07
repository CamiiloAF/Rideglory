import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimientos')),
      body: const Text('Hola'),
      floatingActionButton: const ExpandableFab(),
    );
  }
}

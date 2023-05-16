import 'package:flutter/material.dart';
import 'package:rideglory/features/match_riders/presentation/pages/match_riders_page.dart';

import '../../../../shared/widgets/bottom_nav_bars/our_bottom_nav_bar.dart';
import '../../../routes/pages/map/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int activeIndex = 0;

  late final widgets = [
    const MapPage(),
    const MatchRidersPage(),
    const Center(
      child: Text('Perfil'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      bottomNavigationBar: OurButtonNavBar(
        onTap: (value) => setState(
          () => activeIndex = value,
        ),
      ),
      body: widgets[activeIndex],
    );
  }
}

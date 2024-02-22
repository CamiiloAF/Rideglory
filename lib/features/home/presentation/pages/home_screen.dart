import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/features/match_riders/presentation/pages/match_riders_page.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAEAEA),
      body: MatchRidersPage(),
    );
  }
}

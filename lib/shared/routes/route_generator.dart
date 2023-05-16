import 'package:flutter/material.dart';
import 'package:rideglory/features/match_riders/presentation/pages/match_riders_detail_page.dart';
import 'package:rideglory/features/match_riders/presentation/pages/match_riders_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map?;
    final availableRoutes = getAvailableRoutes(args);
    final page = availableRoutes[settings.name]!;

    return MaterialPageRoute(settings: settings, builder: page);
  }

  static Map<String, WidgetBuilder> getAvailableRoutes(Map? args) {
    return {
      AppRoutes.homePage: (_) => const HomePage(),
      AppRoutes.matchPage: (_) => const MatchRidersPage(),
      AppRoutes.matchDetailPage: (_) => const MatchRidersDetailPage(),

    };
  }
}

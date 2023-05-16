import 'package:flutter/material.dart';

import '../../../../shared/widgets/bottom_nav_bars/our_bottom_nav_bar.dart';
import '../widgets/match_card_swiper.dart';
import '../widgets/match_riders_header.dart';

class MatchRidersPage extends StatelessWidget {
  const MatchRidersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox  (
      height: size.height,
      child: Stack(
        children: const [
          MatchRidersHeader(),
          Positioned(
            top: 140,
            child: MatchCardSwiper(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/match_card_swiper.dart';
import '../widgets/match_riders_header.dart';

class MatchRidersPage extends StatelessWidget {
  const MatchRidersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height,
      child: const Stack(
        children: [
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

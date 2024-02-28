import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'match_card.dart';

class MatchCardSwiper extends StatefulWidget {
  const MatchCardSwiper({super.key});

  @override
  State<MatchCardSwiper> createState() => _MatchCardSwiperState();
}

class _MatchCardSwiperState extends State<MatchCardSwiper> {
  final CardSwiperController controller = CardSwiperController();

  final cards = List.generate(1, (final index) => '$index');

  @override
  Widget build(final BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        SizedBox(
          width: size.width,
          height: size.height * 0.6,
          child: CardSwiper(
            controller: controller,
            cardsCount: cards.length,
            numberOfCardsDisplayed: 1,
            allowedSwipeDirection:  AllowedSwipeDirection.symmetric(horizontal: true),

            padding: EdgeInsets.zero,
            isLoop: false,
            onSwipe: _onSwipe,
            onUndo: _onUndo,
            cardBuilder: (final _, final index, final __, final ___) => MatchCard(index: index),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              FloatingActionButton(
                heroTag: 'fab1',
                onPressed: controller.swipeLeft,
                child: const Icon(Icons.close),
              ),
              const SizedBox(width: 24),
              FloatingActionButton(
                heroTag: 'fab2',
                onPressed: controller.swipeRight,
                child: const Icon(Icons.motorcycle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _onSwipe(
    final int previousIndex,
    final int? currentIndex,
    final CardSwiperDirection direction,
  ) {
    return true;
  }

  bool _onUndo(
    final int? previousIndex,
    final int currentIndex,
    final CardSwiperDirection direction,
  ) {
    return true;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

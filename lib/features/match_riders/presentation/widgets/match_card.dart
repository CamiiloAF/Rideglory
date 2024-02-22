import 'package:flutter/material.dart';

import '../../../../shared/theme/app_dimens.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({Key? key, required this.index}) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: AppDimens.matchPageHorizontalMargin,
      child: GestureDetector(
        onTap: () {
          // Navigator.of(context).pushNamed(AppRoutes.matchDetailPage);
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.matchCardBorderRadius,
          ),
          child: SizedBox(
            height: screenHeight * 0.5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: AppDimens.matchCardBorderRadius,
                  child: Hero(
                    tag: 'dash',
                    child: Image(
                      image: const NetworkImage(
                        'https://img.freepik.com/foto-gratis/encantadora-chica-encuentra-calle_8353-5380.jpg?w=740&t=st=1682791623~exp=1682792223~hmac=10c6174245bfa1e5378e96efc7422214cd543b6f29d7872a6db735334c92abea',
                      ),
                      fit: BoxFit.fitWidth,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, left: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Miriam',
                          style:
                              textTheme.titleLarge!.copyWith(color: Colors.white),
                        ),
                        const Text(
                          'Santa Rosa de Cabal',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

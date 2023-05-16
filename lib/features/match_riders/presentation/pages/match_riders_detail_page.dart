import 'package:flutter/material.dart';

class MatchRidersDetailPage extends StatelessWidget {
  const MatchRidersDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: 'dash',
            child: Image(
              image: const NetworkImage(
                'https://img.freepik.com/foto-gratis/encantadora-chica-encuentra-calle_8353-5380.jpg?w=740&t=st=1682791623~exp=1682792223~hmac=10c6174245bfa1e5378e96efc7422214cd543b6f29d7872a6db735334c92abea',
              ),
              width: screenSize.width,
              height: screenSize.height * .55,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            bottom: -5,
            width: screenSize.width,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(48),
                  topLeft: Radius.circular(48),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Miriam',
                    style: textTheme.titleLarge,
                  ),
                  Text(
                    'Santa Rosa de Cabal',
                    style: textTheme.titleLarge,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

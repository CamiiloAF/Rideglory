import 'package:flutter/material.dart';

class OurButtonNavBar extends StatefulWidget {
  const OurButtonNavBar({Key? key, this.onTap}) : super(key: key);

  final ValueChanged<int>? onTap;

  @override
  State<OurButtonNavBar> createState() => _OurButtonNavBarState();
}

class _OurButtonNavBarState extends State<OurButtonNavBar> {
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    const mapIcon = Icon(Icons.map);
    const peopleIcon = Icon(Icons.emoji_people_rounded);
    const personIcon = Icon(Icons.person);

    return BottomNavigationBar(
      currentIndex: activeIndex,
      onTap: (value) {
        setState(
          () => activeIndex = value,
        );
        if (widget.onTap != null) {
          widget.onTap!(value);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: mapIcon,
          label: 'Rutas',
        ),
        BottomNavigationBarItem(
          icon: peopleIcon,
          label: 'Descubrir',
        ),
        BottomNavigationBarItem(
          icon: personIcon,
          label: 'Perfil',
        ),
      ],
    );
  }
}

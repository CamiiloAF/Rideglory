import 'package:flutter/material.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({
    required this.fileURL, required this.onDeleteImage, final Key? key,
  }) : super(key: key);

  final String fileURL;
  final Function(String fileURL) onDeleteImage;

  @override
  Widget build(final BuildContext context) {
    return Stack(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      children: [
        Positioned.fill(
          child: Image.network(
            fileURL,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            excludeFromSemantics: true,
            onLongPress: () {},
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
              ),
            ),
            onTap: () => onDeleteImage(fileURL),
          ),
        ),
      ],
    );
  }
}

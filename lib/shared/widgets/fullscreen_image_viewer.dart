import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/design_system/design_system.dart';

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) =>
            FullscreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;

  Offset? _lastTapPosition;
  static const double _zoomScale = 2.5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          if (_animation != null) {
            _transformController.value = _animation!.value;
          }
        });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTap(Offset position) {
    final isZoomed = _transformController.value.getMaxScaleOnAxis() > 1.05;
    if (isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final x = -position.dx * (_zoomScale - 1);
    final y = -position.dy * (_zoomScale - 1);
    final zoomed = Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..scaleByDouble(_zoomScale, _zoomScale, 1, 1);
    _animateTo(zoomed);
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(begin: _transformController.value, end: target)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionEnd: (_) {
                  if (_transformController.value.getMaxScaleOnAxis() < 1.0) {
                    _animateTo(Matrix4.identity());
                  }
                },
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, _) =>
                      const ColoredBox(color: Colors.black),
                  errorWidget: (context, url, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textOnDarkSecondary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // Capa transparente encima del Hero para capturar doble tap sin
          // bloquear el pinch/pan del InteractiveViewer.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: (d) => _lastTapPosition = d.localPosition,
              onDoubleTap: () {
                if (_lastTapPosition != null) _onDoubleTap(_lastTapPosition!);
              },
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

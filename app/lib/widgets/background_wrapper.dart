import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image - TILED PATTERN
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpg',
            repeat: ImageRepeat.repeat, // This tiles the image
            scale: 4.0, // Make the tiles smaller (adjust as needed)
            color: Colors.white.withOpacity(0.15), // Make it very subtle directly on the image
            colorBlendMode: BlendMode.modulate,
          ),
        ),
        // Dark Overlay for readability
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.65), // Lighter overlay (was 0.92)
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

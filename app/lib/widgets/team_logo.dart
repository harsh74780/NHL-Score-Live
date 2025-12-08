import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class TeamLogo extends StatelessWidget {
  final String teamAbbrev; // e.g. "TOR"
  final String logoUrl;    // Can be PNG URL or Base64 SVG
  final double size;

  const TeamLogo({
    super.key, 
    required this.teamAbbrev, 
    required this.logoUrl,
    this.size = 50
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return _buildFallback();
    }

    // Check if it's a Base64 SVG (starts with "data:image/svg+xml;base64,")
    if (logoUrl.startsWith("data:image/svg+xml;base64,")) {
      try {
        final base64String = logoUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return SvgPicture.memory(
          bytes,
          width: size,
          height: size,
          placeholderBuilder: (context) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildFallback(); // Fallback if decoding fails
      }
    }

    // Otherwise treat as PNG URL
    return Image.network(
      logoUrl,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium, // Better for downscaling
      errorBuilder: (context, error, stackTrace) {
         return _buildFallback();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size, 
      height: size,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24)
      ),
      child: Center(
        child: Text(
          teamAbbrev.isNotEmpty ? teamAbbrev.substring(0, 1) : "?",
          style: TextStyle(color: Colors.white, fontSize: size * 0.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
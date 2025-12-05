import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  final String teamAbbrev; // e.g. "TOR", "SJS", "LAK"
  final double size;

  const TeamLogo({super.key, required this.teamAbbrev, this.size = 50});

  @override
  Widget build(BuildContext context) {
    String cleanAbbrev = teamAbbrev.toLowerCase();

    // --- CORRECTION MAP ---
    // The NHL API gives 3 letters (SJS), but ESPN uses 2 letters (sj) for some teams.
    const Map<String, String> corrections = {
      'sjs': 'sj',  // San Jose
      'lak': 'la',  // Los Angeles
      'tbl': 'tb',  // Tampa Bay
      'njd': 'nj',  // New Jersey
      'uta': 'utah', // Utah
      'vgk': 'vgs', // Vegas (sometimes vgk, sometimes vgs on ESPN)
    };

    if (corrections.containsKey(cleanAbbrev)) {
      cleanAbbrev = corrections[cleanAbbrev]!;
    }

    // Construct URL
    final imageUrl = 'https://a.espncdn.com/i/teamlogos/nhl/500/$cleanAbbrev.png';

    return Image.network(
      imageUrl, 
      width: size, 
      height: size,
      // Cache logic is handled by browser automatically
      errorBuilder: (context, error, stackTrace) {
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
              teamAbbrev.substring(0, 1),
              style: TextStyle(color: Colors.white, fontSize: size * 0.5, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
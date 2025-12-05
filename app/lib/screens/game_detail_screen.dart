import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import '../models/game_model.dart';
import 'team_detail_screen.dart';
import '../widgets/team_logo.dart';
import '../widgets/background_wrapper.dart';

class GameDetailScreen extends StatelessWidget {
  final GameModel game;

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format Date & Time
    final dt = DateTime.parse(game.startTime).toLocal();
    final dateStr = DateFormat('EEEE, MMMM d, y').format(dt); // "Tuesday, December 2, 2025"
    final timeStr = DateFormat.jm().format(dt); // "7:00 PM"

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: BackgroundWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. MAIN SCOREBOARD CARD ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: game.status == 'Live' ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: game.status == 'Live' ? Border.all(color: Colors.redAccent) : null,
                      ),
                      child: Text(
                        game.status.toUpperCase(),
                        style: TextStyle(
                          color: game.status == 'Live' ? Colors.redAccent : Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Teams & Score Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HOME TEAM
                        Expanded(
                          child: _TeamColumn(
                            team: game.homeTeam, 
                            context: context, 
                            label: 'HOME'
                          ),
                        ),
                        
                        // CENTER SCORE
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Column(
                            children: [
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.grey, 
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${game.homeTeam.score} - ${game.awayTeam.score}',
                                style: const TextStyle(
                                  fontSize: 48, 
                                  fontWeight: FontWeight.w800, 
                                  color: Colors.white
                                ),
                              ),
                            ],
                          ),
                        ),

                        // AWAY TEAM
                        Expanded(
                          child: _TeamColumn(
                            team: game.awayTeam, 
                            context: context, 
                            label: 'AWAY'
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // --- 2. GAME INFO CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "GAME INFORMATION",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date
                    _InfoRow(icon: Icons.calendar_today, text: dateStr),
                    const Divider(color: Colors.white10, height: 30),
                    
                    // Time
                    _InfoRow(icon: Icons.access_time, text: timeStr),
                    const Divider(color: Colors.white10, height: 30),
                    
                    // Venue
                    _InfoRow(icon: Icons.stadium, text: game.venue),
                    
                    // Removed Broadcasts as requested
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "Tap a team logo above to see season history",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final TeamSummary team;
  final BuildContext context;
  final String label;

  const _TeamColumn({
    required this.team, 
    required this.context,
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(teamId: team.abbrev),
          ),
        );
      },
      child: Column(
        children: [
          Hero(
            tag: 'team_logo_${team.abbrev}', // Smooth animation tag
            child: TeamLogo(teamAbbrev: team.abbrev, size: 90),
          ),
          const SizedBox(height: 16),
          Text(
            team.name.isNotEmpty ? team.name : team.abbrev,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (team.record.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                team.record,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
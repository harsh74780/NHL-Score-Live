import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added this for date formatting
import '../models/team_model.dart';
import '../services/firestore_service.dart';
import '../widgets/team_logo.dart'; 
import '../widgets/background_wrapper.dart'; 

class TeamDetailScreen extends StatelessWidget {
  final String teamId; // e.g. "TOR"
  final FirestoreService _service = FirestoreService();

  TeamDetailScreen({Key? key, required this.teamId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(teamId.toUpperCase()),
      ),
      body: BackgroundWrapper(
        child: StreamBuilder<TeamModel>(
          stream: _service.getTeam(teamId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }
            
            if (!snapshot.hasData) {
               return const Center(child: Text("Team data not found.", style: TextStyle(color: Colors.white54)));
            }
  
            final team = snapshot.data!;
  
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // --- 1. TEAM HEADER ---
                  Hero(
                    tag: 'team_logo_${team.id}',
                    child: TeamLogo(teamAbbrev: team.id, size: 120),
                  ),
                  const SizedBox(height: 20),
                  
                  // Name
                  Text(
                    team.name.isEmpty ? team.id : team.name, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Record Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Text(
                      "Season Record: ${team.record}",
                      style: const TextStyle(
                        color: Colors.blueAccent, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- 2. RECENT GAMES LIST ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "LAST 5 GAMES",
                        style: TextStyle(
                          color: Colors.grey[500], 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                        ),
                      ),
                    ),
                  ),
  
                  if (team.last5Games.isEmpty)
                     Container(
                       margin: const EdgeInsets.symmetric(horizontal: 20),
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         color: Colors.white10,
                         borderRadius: BorderRadius.circular(12)
                       ),
                       child: const Center(
                         child: Text(
                           "No recent game history available.", 
                           style: TextStyle(color: Colors.white54)
                         )
                       ),
                     )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: team.last5Games.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final game = team.last5Games[index];
                        
                        // Determine Colors
                        Color outcomeColor = Colors.grey;
                        if (game.outcome == 'W') outcomeColor = Colors.green;
                        if (game.outcome == 'L') outcomeColor = Colors.redAccent;
                        
                        // Opponent Logo logic 
                        // We strip 'vs ' or '@ ' to get the pure abbrev like 'BOS'
                        String oppAbbrev = game.opponent.replaceAll('vs ', '').replaceAll('@ ', '');
  
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Date (Now formatted nicely like "Dec 2")
                              SizedBox(
                                width: 50,
                                child: Text(
                                  _formatDate(game.date),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              
                              // Opponent Logo
                              TeamLogo(teamAbbrev: oppAbbrev, size: 30),
                              const SizedBox(width: 12),
                              
                              // Opponent Text
                              Expanded(
                                child: Text(
                                  game.opponent, 
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                  ),
                                ),
                              ),
                              
                              // Score & Result
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: outcomeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: outcomeColor.withOpacity(0.5))
                                ),
                                child: Text(
                                  "${game.outcome} ${game.score}",
                                  style: TextStyle(
                                    color: outcomeColor, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // UPDATED Helper: Converts "2023-12-02" -> "Dec 2"
  String _formatDate(String isoDate) {
    try {
      if (isoDate.isEmpty) return "-";
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d').format(dt); // Uses 'intl' package
    } catch (e) {
      return "";
    }
  }
}

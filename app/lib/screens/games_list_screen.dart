import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/game_model.dart';
import 'game_detail_screen.dart';
import '../widgets/team_logo.dart';
import '../widgets/background_wrapper.dart';

class GamesListScreen extends StatelessWidget {
  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      initialIndex: 1, // Default to TODAY
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NHL Schedule'),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            tabs: [
              Tab(text: 'RESULTS'),
              Tab(text: 'TODAY'),
              Tab(text: 'UPCOMING'),
            ],
          ),
        ),
        body: BackgroundWrapper(
          child: StreamBuilder<List<GameModel>>(
            stream: _service.getGames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No games found.', style: TextStyle(color: Colors.white54)));
              }
  
              final allGames = snapshot.data!;
              final now = DateTime.now();
              final todayMidnight = DateTime(now.year, now.month, now.day);
  
              List<GameModel> todayGames = [];
              List<GameModel> upcomingGames = [];
              List<GameModel> pastGames = [];
  
              for (var game in allGames) {
                final gameDt = DateTime.parse(game.startTime).toLocal();
                final gameDate = DateTime(gameDt.year, gameDt.month, gameDt.day);
  
                if (gameDate.isAtSameMomentAs(todayMidnight)) {
                  todayGames.add(game);
                } else if (gameDate.isAfter(todayMidnight)) {
                  upcomingGames.add(game);
                } else {
                  pastGames.add(game);
                }
              }
  
              // Sorting
              todayGames.sort((a, b) => a.startTime.compareTo(b.startTime));
              upcomingGames.sort((a, b) => a.startTime.compareTo(b.startTime));
              pastGames.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first
  
              return TabBarView(
                children: [
                  _GameListTab(games: pastGames, emptyMsg: "No recent results.", groupDates: true),
                  _GameListTab(games: todayGames, emptyMsg: "No games scheduled today.", groupDates: false),
                  _GameListTab(games: upcomingGames, emptyMsg: "No upcoming games found.", groupDates: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameListTab extends StatelessWidget {
  final List<GameModel> games;
  final String emptyMsg;
  final bool groupDates;

  const _GameListTab({
    required this.games,
    required this.emptyMsg,
    required this.groupDates,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.white54)));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: _buildList(),
    );
  }

  List<Widget> _buildList() {
    List<Widget> widgets = [];
    String lastDate = '';

    for (var game in games) {
      if (groupDates) {
        final dt = DateTime.parse(game.startTime).toLocal();
        final dateHeader = DateFormat('EEE, MMM d').format(dt).toUpperCase();
        
        if (dateHeader != lastDate) {
          widgets.add(_DateHeader(text: dateHeader));
          lastDate = dateHeader;
        }
      } 
      widgets.add(GameCard(game: game));
    }
    return widgets;
  }
}

class _DateHeader extends StatelessWidget {
  final String text;
  const _DateHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final GameModel game;

  const GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(game.startTime).toLocal();
    final timeString = DateFormat.jm().format(dt).toLowerCase(); 

    String statusText = timeString;
    if (game.status == 'Final') statusText = "Final";
    if (game.status == 'Live') statusText = "Live";

    Color statusColor = Colors.grey;
    if (game.status == 'Live') statusColor = Colors.redAccent;
    if (game.status == 'Final') statusColor = Colors.white70;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // TOP ROW (Teams vs Status)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _TeamRowCompact(
                          abbrev: game.homeTeam.abbrev,
                          name: game.homeTeam.name.isNotEmpty ? game.homeTeam.name : game.homeTeam.abbrev,
                          record: game.homeTeam.record,
                          score: game.homeTeam.score,
                          isWinner: game.status == 'Final' && game.homeTeam.score > game.awayTeam.score,
                          gameStatus: game.status,
                        ),
                        const SizedBox(height: 12),
                        _TeamRowCompact(
                          abbrev: game.awayTeam.abbrev,
                          name: game.awayTeam.name.isNotEmpty ? game.awayTeam.name : game.awayTeam.abbrev,
                          record: game.awayTeam.record,
                          score: game.awayTeam.score,
                          isWinner: game.status == 'Final' && game.awayTeam.score > game.homeTeam.score,
                          gameStatus: game.status,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (game.status == 'Live')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent, width: 1),
                            ),
                            child: const Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // FOOTER ROW (Venue Only)
              if (game.venue.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white30),
                    const SizedBox(width: 4),
                    Text(
                      game.venue,
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRowCompact extends StatelessWidget {
  final String abbrev;
  final String name;
  final String record;
  final int score;
  final bool isWinner;
  final String gameStatus;

  const _TeamRowCompact({
    required this.abbrev,
    required this.name,
    required this.record, 
    required this.score,
    required this.isWinner,
    required this.gameStatus,
  });

  @override
  Widget build(BuildContext context) {
    bool showScore = gameStatus == 'Live' || gameStatus == 'Final';
    
    return Row(
      children: [
        TeamLogo(teamAbbrev: abbrev, size: 28), // Slightly larger logo
        const SizedBox(width: 12),
        
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 16, // Larger font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (record.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  record,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ]
            ],
          ),
        ),
        
        if (showScore)
          Text(
            score.toString(),
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.white54,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              fontSize: 18, // Larger score
            ),
          ),
      ],
    );
  }
}

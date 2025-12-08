import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String record;
  final String logo;
  final List<PastGame> last5Games;

  TeamModel({
    required this.id,
    required this.name,
    required this.record,
    required this.logo,
    required this.last5Games,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse the list of last 5 games
    var list = data['last5Games'] as List? ?? [];
    List<PastGame> gamesList = list.map((i) => PastGame.fromMap(i)).toList();

    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      record: data['record'] ?? '0-0-0',
      logo: data['logo'] ?? '',
      last5Games: gamesList,
    );
  }
}

class PastGame {
  final String opponent;
  final String opponentLogo;
  final String score;
  final String outcome; // "W", "L", "OT"
  final String date;

  PastGame({
    required this.opponent,
    required this.opponentLogo,
    required this.score,
    required this.outcome,
    required this.date,
  });

  factory PastGame.fromMap(Map<String, dynamic> data) {
    return PastGame(
      opponent: data['opponent'] ?? '',
      opponentLogo: data['opponentLogo'] ?? '',
      score: data['score'] ?? '',
      outcome: data['outcome'] ?? '-',
      date: data['date'] ?? '',
    );
  }
}

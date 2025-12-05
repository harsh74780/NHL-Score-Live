import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String startTime;
  final String status;
  final String venue;
  final TeamSummary homeTeam;
  final TeamSummary awayTeam;

  GameModel({
    required this.id,
    required this.startTime,
    required this.status,
    required this.venue,
    required this.homeTeam,
    required this.awayTeam,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // --- FORCE VENUE DISPLAY ---
    // If venue is missing or empty, use 'Venue TBA' so it shows up in UI
    String venueData = data['venue'] ?? '';
    if (venueData.isEmpty) venueData = 'Venue TBA';

    return GameModel(
      id: doc.id,
      startTime: data['startTime'] ?? '',
      status: data['status'] ?? 'Scheduled',
      venue: venueData,
      homeTeam: TeamSummary.fromMap(data['homeTeam']),
      awayTeam: TeamSummary.fromMap(data['awayTeam']),
    );
  }
}

class TeamSummary {
  final int id;
  final String abbrev;
  final String name;
  final int score;
  final String logo;
  final String record; 

  TeamSummary({
    required this.id,
    required this.abbrev,
    required this.name,
    required this.score,
    required this.logo,
    this.record = '', 
  });

  factory TeamSummary.fromMap(Map<String, dynamic> data) {
    return TeamSummary(
      id: data['id'] ?? 0,
      abbrev: data['abbrev'] ?? '',
      name: data['name'] ?? '',
      score: data['score'] ?? 0,
      logo: data['logo'] ?? '',
      record: data['record'] ?? '', 
    );
  }
}
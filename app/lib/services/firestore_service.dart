import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';
import '../models/team_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Get Today's Games (Real-time Stream)
  // This listens to the 'games' collection. If a score changes, the app updates instantly.
  Stream<List<GameModel>> getGames() {
    return _db.collection('games')
        .orderBy('startTime') // Show earliest games first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
    });
  }

  // 2. Get Specific Team Details
  // This fetches the 'teams' document for the "Team Screen".
  Stream<TeamModel> getTeam(String teamId) {
    return _db.collection('teams').doc(teamId).snapshots().map((doc) {
      return TeamModel.fromFirestore(doc);
    });
  }
}
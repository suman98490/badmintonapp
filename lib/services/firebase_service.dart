import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  // Add Player
  Future<void> addPlayer(String name) async {
    await database.child('players').push().set({
      'name': name,
      'createdAt': DateTime.now().toString(),
    });
  }

  // Add Team
  Future<void> addTeam(String teamName) async {
    await database.child('teams').push().set({
      'teamName': teamName,
      'createdAt': DateTime.now().toString(),
    });
  }

  // Start League
  Future<void> startLeague(String leagueName) async {
    await database.child('leagues').push().set({
      'leagueName': leagueName,
      'status': 'Active',
      'createdAt': DateTime.now().toString(),
    });
  }

  // Add Fund Transaction
  Future<void> addFund({
    required double collected,
    required double spent,
  }) async {
    await database.child('funds').push().set({
      'collected': collected,
      'spent': spent,
      'date': DateTime.now().toString(),
    });
  }
}
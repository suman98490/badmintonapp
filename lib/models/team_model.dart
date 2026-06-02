class TeamModel {
  final String id;
  final String teamName;
  final List<String> players;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.teamName,
    required this.players,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.createdAt,
  });

  // =========================
  // FROM JSON
  // =========================

  factory TeamModel.fromJson(
      String id,
      Map<dynamic, dynamic> json,
      ) {
    List<String> playersList = [];

    if (json["players"] != null) {
      playersList =
          List<dynamic>.from(json["players"])
              .map((e) => e.toString())
              .toList();
    }

    return TeamModel(
      id: id,

      teamName: json["teamName"] ?? "",

      players: playersList,

      matchesPlayed:
      int.tryParse(
        json["matchesPlayed"].toString(),
      ) ??
          0,

      wins:
      int.tryParse(
        json["wins"].toString(),
      ) ??
          0,

      losses:
      int.tryParse(
        json["losses"].toString(),
      ) ??
          0,

      createdAt:
      DateTime.tryParse(
        json["createdAt"] ?? "",
      ) ??
          DateTime.now(),
    );
  }

  // =========================
  // TO JSON
  // =========================

  Map<String, dynamic> toJson() {
    return {
      "teamName": teamName,
      "players": players,
      "matchesPlayed": matchesPlayed,
      "wins": wins,
      "losses": losses,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  // =========================
  // COPY WITH
  // =========================

  TeamModel copyWith({
    String? id,
    String? teamName,
    List<String>? players,
    int? matchesPlayed,
    int? wins,
    int? losses,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      players: players ?? this.players,
      matchesPlayed:
      matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
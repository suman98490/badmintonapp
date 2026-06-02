class LeagueModel {
  final String id;
  final String leagueName;
  final double entryFee;
  final String status;
  final DateTime createdAt;

  LeagueModel({
    required this.id,
    required this.leagueName,
    required this.entryFee,
    required this.status,
    required this.createdAt,
  });

  // =========================
  // FROM JSON
  // =========================

  factory LeagueModel.fromJson(
      String id,
      Map<dynamic, dynamic> json,
      ) {
    return LeagueModel(
      id: id,
      leagueName: json["leagueName"] ?? "",
      entryFee:
      double.tryParse(json["entryFee"].toString()) ?? 0,
      status: json["status"] ?? "Active",
      createdAt:
      DateTime.tryParse(json["createdAt"] ?? "") ??
          DateTime.now(),
    );
  }

  // =========================
  // TO JSON
  // =========================

  Map<String, dynamic> toJson() {
    return {
      "leagueName": leagueName,
      "entryFee": entryFee,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}
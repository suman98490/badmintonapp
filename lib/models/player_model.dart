class PlayerModel {
  final String id;
  final String name;
  final int wins;
  final int losses;
  final double pendingAmount;
  final double paidAmount;
  final DateTime createdAt;

  PlayerModel({
    required this.id,
    required this.name,
    required this.wins,
    required this.losses,
    required this.pendingAmount,
    required this.paidAmount,
    required this.createdAt,
  });

  // =========================
  // FROM JSON
  // =========================

  factory PlayerModel.fromJson(
      String id,
      Map<dynamic, dynamic> json,
      ) {
    return PlayerModel(
      id: id,
      name: json["name"] ?? "",

      wins: int.tryParse(
        json["wins"].toString(),
      ) ??
          0,

      losses: int.tryParse(
        json["losses"].toString(),
      ) ??
          0,

      pendingAmount:
      double.tryParse(
        json["pendingAmount"].toString(),
      ) ??
          0,

      paidAmount:
      double.tryParse(
        json["paidAmount"].toString(),
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
      "name": name,
      "wins": wins,
      "losses": losses,
      "pendingAmount": pendingAmount,
      "paidAmount": paidAmount,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  // =========================
  // COPY WITH
  // =========================

  PlayerModel copyWith({
    String? id,
    String? name,
    int? wins,
    int? losses,
    double? pendingAmount,
    double? paidAmount,
    DateTime? createdAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      pendingAmount:
      pendingAmount ?? this.pendingAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}